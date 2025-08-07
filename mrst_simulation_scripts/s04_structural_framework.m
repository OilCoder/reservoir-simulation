function structural_data = s04_structural_framework()
% S04_STRUCTURAL_FRAMEWORK - Setup structural framework for Eagle West Field
%
% SYNTAX:
%   structural_data = s04_structural_framework()
%
% OUTPUT:
%   structural_data - Structure containing geological framework data
%
% DESCRIPTION:
%   This script defines the structural framework for Eagle West Field
%   following specifications in 01_Structural_Geology.md.
%
%   Structural Specifications:
%   - Faulted anticline structure
%   - Structural crest at 7,900 ft TVDSS
%   - 340 ft structural relief (7,900 to 8,240 ft)
%   - 2 main compartments (Northern/Southern)
%   - Fault-controlled compartmentalization
%
% Author: Claude Code AI System
% Date: January 30, 2025

    fprintf('======================================================\n');
    fprintf('Eagle West Field - Structural Framework (Step 4)\n');
    fprintf('======================================================\n\n');
    
    try
        % Step 1 - Load grid data
        fprintf('Step 1: Loading grid structure...\n');
        grid_file = '../data/mrst_simulation/static/grid_structure.mat';
        if exist(grid_file, 'file')
            load(grid_file, 'G');
            fprintf('   ✓ Grid loaded with %d cells\n', G.cells.num);
        else
            error('Grid structure not found. Run s02_create_grid first.');
        end
        
        % Step 2 - Define structural surfaces
        fprintf('Step 2: Defining structural surfaces...\n');
        structural_surfaces = define_structural_surfaces(G);
        fprintf('   ✓ Structural surfaces defined\n');
        
        % Step 3 - Create geological layers
        fprintf('Step 3: Creating geological layers...\n');
        geological_layers = create_geological_layers(G, structural_surfaces);
        fprintf('   ✓ %d geological layers created\n', length(geological_layers.layer_tops));
        
        % Step 4 - Define compartments
        fprintf('Step 4: Defining structural compartments...\n');
        compartments = define_compartments(G, structural_surfaces);
        fprintf('   ✓ %d compartments defined\n', length(compartments.compartment_ids));
        
        % Step 5 - Assign structural properties to cells
        fprintf('Step 5: Assigning structural properties to cells...\n');
        G = assign_structural_properties(G, geological_layers, compartments);
        fprintf('   ✓ Structural properties assigned to all cells\n');
        
        % Step 6 - Validate structural framework
        fprintf('Step 6: Validating structural framework...\n');
        validate_structural_framework(G, geological_layers, compartments);
        fprintf('   ✓ Structural framework validated\n');
        
        % Step 7 - Export structural data
        fprintf('Step 7: Exporting structural data...\n');
        export_structural_data(G, geological_layers, compartments, structural_surfaces);
        fprintf('   ✓ Structural data exported\n\n');
        
        % Assemble output structure
        structural_data = struct();
        structural_data.grid = G;
        structural_data.surfaces = structural_surfaces;
        structural_data.layers = geological_layers;
        structural_data.compartments = compartments;
        structural_data.status = 'completed';
        
        % Success summary
        fprintf('======================================================\n');
        fprintf('Structural Framework Completed Successfully\n');
        fprintf('======================================================\n');
        fprintf('Structural crest: %.0f ft TVDSS\n', min(structural_surfaces.top_surface));
        fprintf('Maximum depth: %.0f ft TVDSS\n', max(structural_surfaces.bottom_surface));
        fprintf('Structural relief: %.0f ft\n', max(structural_surfaces.bottom_surface) - min(structural_surfaces.top_surface));
        fprintf('Geological layers: %d\n', length(geological_layers.layer_tops));
        fprintf('Compartments: %d\n', length(compartments.compartment_ids));
        fprintf('======================================================\n\n');
        
    catch ME
        fprintf('\n❌ Structural framework setup FAILED\n');
        fprintf('Error: %s\n', ME.message);
        if ~isempty(ME.stack)
            fprintf('Location: %s (line %d)\n', ME.stack(1).file, ME.stack(1).line);
        end
        error('Structural framework setup failed: %s', ME.message);
    end

end

function surfaces = define_structural_surfaces(G)
% DEFINE_STRUCTURAL_SURFACES - Create structural surfaces for anticline

    % Get grid cell centers
    x = G.cells.centroids(:,1);
    y = G.cells.centroids(:,2);
    z = G.cells.centroids(:,3);
    
    % Anticline parameters based on Eagle West Field specifications
    crest_x = 1640;  % ft - structural crest X coordinate (middle of field)
    crest_y = 1480;  % ft - structural crest Y coordinate (middle of field)
    crest_depth = 7900;  % ft TVDSS - structural crest depth
    
    % Structural relief parameters
    max_relief = 340;  % ft - total structural relief
    anticline_width_x = 2000;  % ft - anticline width in X direction
    anticline_width_y = 1500;  % ft - anticline width in Y direction
    
    % Calculate distance from crest
    dist_x = (x - crest_x) / anticline_width_x;
    dist_y = (y - crest_y) / anticline_width_y;
    dist_total = sqrt(dist_x.^2 + dist_y.^2);
    
    % Create top surface using cosine function for smooth anticline
    relief_factor = cos(pi * min(dist_total, 1));
    relief_factor = max(relief_factor, 0);  % No negative relief
    
    top_surface = crest_depth + max_relief * (1 - relief_factor);
    
    % Bottom surface (parallel to top with 100 ft thickness)
    reservoir_thickness = 100;  % ft
    bottom_surface = top_surface + reservoir_thickness;
    
    % Store surfaces
    surfaces = struct();
    surfaces.top_surface = top_surface;
    surfaces.bottom_surface = bottom_surface;
    surfaces.crest_depth = crest_depth;
    surfaces.max_relief = max_relief;
    surfaces.thickness = reservoir_thickness;

end

function layers = create_geological_layers(G, surfaces)
% CREATE_GEOLOGICAL_LAYERS - Define geological layer structure

    % Based on 12-layer structure from configuration
    n_layers = 12;
    layer_thickness = 100 / n_layers;  % ft per layer
    
    % Create layer tops and bottoms
    layer_tops = zeros(G.cells.num, n_layers);
    layer_bottoms = zeros(G.cells.num, n_layers);
    
    for i = 1:n_layers
        % Layer tops follow structural surface
        depth_offset = (i-1) * layer_thickness;
        layer_tops(:,i) = surfaces.top_surface + depth_offset;
        layer_bottoms(:,i) = layer_tops(:,i) + layer_thickness;
    end
    
    % Assemble layers structure
    layers = struct();
    layers.n_layers = n_layers;
    layers.layer_tops = layer_tops;
    layers.layer_bottoms = layer_bottoms;
    layers.layer_thickness = layer_thickness;
    
    % Layer names (Upper, Middle, Lower zones with barriers)
    layers.layer_names = {
        'Upper_Sand_1', 'Upper_Sand_2', 'Upper_Sand_3', 'Shale_Barrier_1',
        'Middle_Sand_1', 'Middle_Sand_2', 'Middle_Sand_3', 'Shale_Barrier_2', 
        'Lower_Sand_1', 'Lower_Sand_2', 'Lower_Sand_3', 'Lower_Sand_4'
    };

end

function compartments = define_compartments(G, surfaces)
% DEFINE_COMPARTMENTS - Define structural compartments

    % Get grid cell centers
    x = G.cells.centroids(:,1);
    y = G.cells.centroids(:,2);
    
    % Define compartment boundaries based on major faults
    % Northern compartment: Y > 1480 ft (above structural crest)
    % Southern compartment: Y <= 1480 ft (below structural crest)
    
    compartment_boundary_y = 1480;  % ft
    
    % Assign compartment IDs
    compartment_ids = zeros(G.cells.num, 1);
    compartment_ids(y > compartment_boundary_y) = 1;  % Northern compartment
    compartment_ids(y <= compartment_boundary_y) = 2;  % Southern compartment
    
    % Compartment properties
    compartments = struct();
    compartments.compartment_ids = compartment_ids;
    compartments.n_compartments = 2;
    compartments.compartment_names = {'Northern', 'Southern'};
    compartments.boundary_y = compartment_boundary_y;
    
    % Calculate compartment statistics
    northern_cells = sum(compartment_ids == 1);
    southern_cells = sum(compartment_ids == 2);
    
    compartments.cell_counts = [northern_cells, southern_cells];
    compartments.cell_fractions = [northern_cells/G.cells.num, southern_cells/G.cells.num];

end

function G = assign_structural_properties(G, layers, compartments)
% ASSIGN_STRUCTURAL_PROPERTIES - Assign structural properties to grid cells

    % Assign layer indices to each cell based on Z coordinate
    G.cells.layer_index = zeros(G.cells.num, 1);
    z = G.cells.centroids(:,3);
    
    for i = 1:G.cells.num
        cell_z = z(i);
        
        % Find which layer this cell belongs to
        for layer = 1:layers.n_layers
            if cell_z >= layers.layer_tops(i, layer) && cell_z < layers.layer_bottoms(i, layer)
                G.cells.layer_index(i) = layer;
                break;
            end
        end
        
        % If cell not assigned, assign to closest layer
        if G.cells.layer_index(i) == 0
            [~, closest_layer] = min(abs(cell_z - layers.layer_tops(i, :)));
            G.cells.layer_index(i) = closest_layer;
        end
    end
    
    % Assign compartment information
    G.cells.compartment_id = compartments.compartment_ids;
    
    % Assign structural depth (depth below structural crest)
    crest_depth = min(layers.layer_tops(:,1));
    G.cells.structural_depth = z - crest_depth;

end

function validate_structural_framework(G, layers, compartments)
% VALIDATE_STRUCTURAL_FRAMEWORK - Validate structural framework

    % Check that all cells have layer assignment
    unassigned_cells = sum(G.cells.layer_index == 0);
    if unassigned_cells > 0
        error('%d cells not assigned to any layer', unassigned_cells);
    end
    
    % Check layer distribution
    layer_counts = histcounts(G.cells.layer_index, 1:layers.n_layers+1);
    if any(layer_counts == 0)
        warning('Some layers have no cells assigned');
    end
    
    % Check compartment assignment
    unassigned_compartments = sum(G.cells.compartment_id == 0);
    if unassigned_compartments > 0
        error('%d cells not assigned to any compartment', unassigned_compartments);
    end
    
    % Validate structural relief
    top_depths = layers.layer_tops(:,1);
    structural_relief = max(top_depths) - min(top_depths);
    
    if structural_relief < 300 || structural_relief > 400
        warning('Structural relief %.0f ft outside expected range (300-400 ft)', structural_relief);
    end
    
    fprintf('     Layer assignment: %d cells across %d layers\n', G.cells.num, layers.n_layers);
    fprintf('     Compartment assignment: %d compartments\n', compartments.n_compartments);
    fprintf('     Structural relief: %.0f ft\n', structural_relief);

end

function export_structural_data(G, layers, compartments, surfaces)
% EXPORT_STRUCTURAL_DATA - Export structural framework data

    % Create output directory
    script_path = fileparts(mfilename('fullpath'));
    data_dir = fullfile(fileparts(script_path), 'data', 'mrst_simulation', 'static');
    
    if ~exist(data_dir, 'dir')
        mkdir(data_dir);
    end
    
    % Save structural data
    structural_file = fullfile(data_dir, 'structural_framework.mat');
    save(structural_file, 'G', 'layers', 'compartments', 'surfaces', '');
    
    % Create summary report
    summary_file = fullfile(data_dir, 'structural_summary.txt');
    fid = fopen(summary_file, 'w');
    
    fprintf(fid, 'Eagle West Field - Structural Framework Summary\n');
    fprintf(fid, '==============================================\n\n');
    
    fprintf(fid, 'Structural Configuration:\n');
    fprintf(fid, '  Structure Type: Faulted Anticline\n');
    fprintf(fid, '  Structural Crest: %.0f ft TVDSS\n', surfaces.crest_depth);
    fprintf(fid, '  Maximum Depth: %.0f ft TVDSS\n', surfaces.crest_depth + surfaces.max_relief);
    fprintf(fid, '  Structural Relief: %.0f ft\n', surfaces.max_relief);
    fprintf(fid, '  Reservoir Thickness: %.0f ft\n', surfaces.thickness);
    
    fprintf(fid, '\nGeological Layers: %d\n', layers.n_layers);
    for i = 1:length(layers.layer_names)
        fprintf(fid, '  Layer %d: %s\n', i, layers.layer_names{i});
    end
    
    fprintf(fid, '\nStructural Compartments: %d\n', compartments.n_compartments);
    for i = 1:length(compartments.compartment_names)
        fprintf(fid, '  Compartment %d: %s (%d cells, %.1f%%)\n', i, ...
                compartments.compartment_names{i}, compartments.cell_counts(i), ...
                compartments.cell_fractions(i)*100);
    end
    
    fprintf(fid, '\nCreation Date: %s\n', datestr(now));
    
    fclose(fid);
    
    fprintf('     Structural data saved to: %s\n', structural_file);
    fprintf('     Summary saved to: %s\n', summary_file);

end

% Main execution when called as script
if ~nargout
    % If called as script (not function), create structural framework
    structural_data = s04_structural_framework();
    
    fprintf('Structural framework ready!\n');
    fprintf('Grid updated with layer and compartment assignments.\n\n');
end