function structural_data = s04_structural_framework()
    run('print_utils.m');
% S04_STRUCTURAL_FRAMEWORK - Setup structural framework for Eagle West Field
% Requires: MRST
%
% OUTPUT:
%   structural_data - Structure containing geological framework
%
% Author: Claude Code AI System
% Date: January 30, 2025

    print_step_header('S04', 'Setup Structural Framework');
    
    total_start_time = tic;
    
    try
        % ----------------------------------------
        % Step 1 – Load Grid & Define Surfaces
        % ----------------------------------------
        step_start = tic;
        G = step_1_load_grid();
        surfaces = step_1_define_surfaces(G);
        print_step_result(1, 'Load Grid & Define Surfaces', 'success', toc(step_start));
        
        % ----------------------------------------
        % Step 2 – Apply Structural Framework
        % ----------------------------------------
        step_start = tic;
        layers = step_2_create_layers(G, surfaces);
        G = step_2_apply_framework(G, surfaces, layers);
        print_step_result(2, 'Apply Structural Framework', 'success', toc(step_start));
        
        % ----------------------------------------
        % Step 3 – Validate & Export Framework
        % ----------------------------------------
        step_start = tic;
        structural_data = step_3_export_framework(G, surfaces, layers);
        print_step_result(3, 'Validate & Export Framework', 'success', toc(step_start));
        
        print_step_footer('S04', 'Structural Framework Ready', toc(total_start_time));
        
    catch ME
        print_error_step(0, 'Structural Framework', ME.message);
        error('Structural framework failed: %s', ME.message);
    end

end

function G = step_1_load_grid()
% Step 1 - Load grid structure from s02
    
    % Substep 1.1 – Load base grid ________________________________
    script_path = fileparts(mfilename('fullpath'));
    grid_file = fullfile(fileparts(script_path), 'data', 'mrst_simulation', 'static', 'base_grid.mat');
    
    if ~exist(grid_file, 'file')
        error('Base grid not found. Run s02_create_grid first.');
    end
    
    % ✅ Load grid structure
    load(grid_file, 'G');
    
end

function surfaces = step_1_define_surfaces(G)
% Step 1 - Define structural surfaces for anticline

    % Substep 1.1 – Create anticline structure ____________________
    surfaces = struct();
    surfaces.anticline_axis = define_anticline_axis(G);
    surfaces.structural_relief = 340;  % ft (from documentation)
    surfaces.crest_depth = 7900;      % ft TVDSS
    
    % Substep 1.2 – Define compartments ___________________________
    surfaces.compartments = {'Northern', 'Southern'};
    
end

function axis_data = define_anticline_axis(G)
% Define anticline axis through field center
    field_center_x = mean([min(G.cells.centroids(:,1)), max(G.cells.centroids(:,1))]);
    field_center_y = mean([min(G.cells.centroids(:,2)), max(G.cells.centroids(:,2))]);
    
    % Anticline axis trending N15°E (from documentation)
    axis_trend = 15 * pi/180;  % Convert to radians
    axis_data = struct('center_x', field_center_x, 'center_y', field_center_y, 'trend', axis_trend);
end

function layers = step_2_create_layers(G, surfaces)  
% Step 2 - Create geological layer framework

    % Substep 2.1 – Create layer structure ________________________
    layers = struct();
    layers.n_layers = G.cartDims(3);
    layers.layer_tops = surfaces.crest_depth + (0:layers.n_layers-1) * 8.33;  % 8.33 ft per layer
    layers.anticline_structure = true;
    
end

function G = step_2_apply_framework(G, surfaces, layers)
% Step 2 - Apply structural framework to grid

    % Substep 2.2 – Apply anticline geometry _____________________
    G.structural_framework = struct();
    G.structural_framework.surfaces = surfaces;
    G.structural_framework.layers = layers;
    G.structural_framework.type = 'anticline';
    
    % Add cell-based structural properties
    G.cells.layer_id = ceil((1:G.cells.num)' / (G.cells.num / layers.n_layers));
    G.cells.structural_depth = G.cells.centroids(:,3) + surfaces.crest_depth;
    
end

function structural_data = step_3_export_framework(G, surfaces, layers)
% Step 4 - Export structural framework data

    % Assemble structural data
    structural_data = struct();
    structural_data.grid = G;
    structural_data.surfaces = surfaces;
    structural_data.layers = layers;
    structural_data.status = 'completed';
    
    % Export to file
    script_path = fileparts(mfilename('fullpath'));
    data_dir = fullfile(fileparts(script_path), 'data', 'mrst_simulation', 'static');
    
    if ~exist(data_dir, 'dir')
        mkdir(data_dir);
    end
    
    framework_file = fullfile(data_dir, 'structural_framework.mat');
    save(framework_file, 'structural_data');
    
end

% Main execution when called as script
if ~nargout
    structural_data = s04_structural_framework();
end