function G = s02_create_grid()
% S02_CREATE_GRID - Create reservoir grid for Eagle West Field simulation
%
% SYNTAX:
%   G = s02_create_grid()
%
% OUTPUT:
%   G - MRST grid structure with geometry and properties
%
% DESCRIPTION:
%   This script creates the 3D Cartesian grid structure for Eagle West Field
%   following specifications in 01_Structural_Geology.md and grid_config.yaml.
%   
%   Grid Specifications:
%   - Dimensions: 40×40×12 cells (19,200 total cells)
%   - Cell sizes: 82 ft × 74 ft × 8.3 ft (variable by layer)
%   - Field extent: 3,280 ft × 2,960 ft × 100 ft
%   - Top depth: 8,000 ft TVDSS
%
%   The grid represents the faulted anticline structure with proper
%   aspect ratios for numerical stability.
%
% Author: Claude Code AI System
% Date: January 30, 2025

    fprintf('======================================================\n');
    fprintf('Eagle West Field - Grid Construction (Step 2)\n');
    fprintf('======================================================\n\n');
    
    try
        % Step 1 - Load grid configuration
        fprintf('Step 1: Loading grid configuration...\n');
        grid_config = load_grid_config();
        grid_params = grid_config.grid;
        fprintf('   ✓ Configuration loaded from grid_config.yaml\n\n');
        
        % Step 2 - Validate grid parameters
        fprintf('Step 2: Validating grid parameters...\n');
        validate_grid_parameters(grid_params);
        fprintf('   ✓ Grid parameters validated\n\n');
        
        % Step 3 - Create Cartesian grid
        fprintf('Step 3: Creating Cartesian grid...\n');
        G = create_cartesian_grid(grid_params);
        fprintf('   ✓ Grid created: %d×%d×%d = %d cells\n\n', ...
                G.cartDims(1), G.cartDims(2), G.cartDims(3), G.cells.num);
        
        % Step 4 - Compute geometry
        fprintf('Step 4: Computing grid geometry...\n');
        G = computeGeometry(G);
        fprintf('   ✓ Geometry computed\n');
        fprintf('   ✓ Grid volume: %.2e ft³\n\n', sum(G.cells.volumes));
        
        % Step 5 - Validate grid quality
        fprintf('Step 5: Validating grid quality...\n');
        quality_metrics = validate_grid_quality(G, grid_params);
        fprintf('   ✓ Grid quality validated\n');
        print_quality_metrics(quality_metrics);
        
        % Step 6 - Add field-specific properties
        fprintf('Step 6: Adding field-specific properties...\n');
        G = add_field_properties(G, grid_params);
        fprintf('   ✓ Field properties added\n\n');
        
        % Step 7 - Export grid data
        fprintf('Step 7: Exporting grid data...\n');
        export_grid_data(G, grid_params);
        fprintf('   ✓ Grid data exported\n\n');
        
        % Success summary
        fprintf('======================================================\n');
        fprintf('Grid Construction Completed Successfully\n');
        fprintf('======================================================\n');
        fprintf('Grid Dimensions: %d × %d × %d\n', G.cartDims);
        fprintf('Total Cells: %d\n', G.cells.num);
        fprintf('Total Faces: %d\n', G.faces.num);
        fprintf('Total Nodes: %d\n', G.nodes.num);
        fprintf('Grid Volume: %.2e ft³\n', sum(G.cells.volumes));
        fprintf('Average Cell Volume: %.1f ft³\n', mean(G.cells.volumes));
        fprintf('======================================================\n\n');
        
    catch ME
        fprintf('\n❌ Grid construction FAILED\n');
        fprintf('Error: %s\n', ME.message);
        if ~isempty(ME.stack)
            fprintf('Location: %s (line %d)\n', ME.stack(1).file, ME.stack(1).line);
        end
        error('Grid construction failed: %s', ME.message);
    end

end

function validate_grid_parameters(grid_params)
% VALIDATE_GRID_PARAMETERS - Validate configuration parameters
%
% INPUT:
%   grid_params - Grid parameters structure from YAML

    % Check required fields exist
    required_fields = {'nx', 'ny', 'nz', 'cell_size_x', 'cell_size_y', 'layer_thicknesses'};
    for i = 1:length(required_fields)
        field = required_fields{i};
        if ~isfield(grid_params, field)
            error('Required grid parameter missing: %s', field);
        end
    end
    
    % Validate dimensions
    if grid_params.nx <= 0 || grid_params.ny <= 0 || grid_params.nz <= 0
        error('Grid dimensions must be positive integers. Got nx=%d, ny=%d, nz=%d', ...
              grid_params.nx, grid_params.ny, grid_params.nz);
    end
    
    % Validate cell sizes
    if grid_params.cell_size_x <= 0 || grid_params.cell_size_y <= 0
        error('Cell sizes must be positive. Got cell_size_x=%.1f, cell_size_y=%.1f', ...
              grid_params.cell_size_x, grid_params.cell_size_y);
    end
    
    % Validate layer thicknesses
    if length(grid_params.layer_thicknesses) ~= grid_params.nz
        error('Layer thickness count (%d) must match nz (%d)', ...
              length(grid_params.layer_thicknesses), grid_params.nz);
    end
    
    if any(grid_params.layer_thicknesses <= 0)
        error('All layer thicknesses must be positive');
    end
    
    % Check aspect ratio for numerical stability (should be < 10:1)
    max_thickness = max(grid_params.layer_thicknesses);
    min_horizontal = min(grid_params.cell_size_x, grid_params.cell_size_y);
    aspect_ratio = min_horizontal / max_thickness;
    
    if aspect_ratio > 10
        warning('High aspect ratio detected (%.1f:1). May cause numerical issues.', aspect_ratio);
    end
    
    fprintf('     Grid dimensions: %d × %d × %d\n', grid_params.nx, grid_params.ny, grid_params.nz);
    fprintf('     Cell sizes: %.1f ft × %.1f ft\n', grid_params.cell_size_x, grid_params.cell_size_y);
    fprintf('     Layer thickness range: %.1f - %.1f ft\n', ...
            min(grid_params.layer_thicknesses), max(grid_params.layer_thicknesses));

end

function G = create_cartesian_grid(grid_params)
% CREATE_CARTESIAN_GRID - Create the basic Cartesian grid structure
%
% INPUT:
%   grid_params - Grid parameters from configuration
%
% OUTPUT:
%   G - MRST grid structure

    % Extract dimensions
    nx = grid_params.nx;
    ny = grid_params.ny;
    nz = grid_params.nz;
    
    % Calculate physical dimensions
    dx = grid_params.cell_size_x;
    dy = grid_params.cell_size_y;
    layer_thicknesses = grid_params.layer_thicknesses;
    
    % Total domain size
    Lx = nx * dx;  % Total X dimension
    Ly = ny * dy;  % Total Y dimension
    Lz = sum(layer_thicknesses);  % Total Z dimension
    
    fprintf('     Physical domain: %.1f ft × %.1f ft × %.1f ft\n', Lx, Ly, Lz);
    
    % Create basic Cartesian grid with MRST
    % Note: MRST uses [nx, ny, nz] for dimensions and [Lx, Ly, Lz] for physical size
    G = cartGrid([nx, ny, nz], [Lx, Ly, Lz]);
    
    % Adjust Z-coordinates for variable layer thicknesses
    if length(unique(layer_thicknesses)) > 1
        % Variable layer thicknesses - need to adjust Z coordinates
        G = adjust_layer_thicknesses(G, layer_thicknesses);
    end
    
    % Apply coordinate transforms for Eagle West Field location
    if isfield(grid_params, 'origin_x') && isfield(grid_params, 'origin_y') && isfield(grid_params, 'origin_z')
        G = apply_coordinate_transform(G, grid_params);
    end

end

function G = adjust_layer_thicknesses(G, layer_thicknesses)
% ADJUST_LAYER_THICKNESSES - Adjust Z-coordinates for variable layer thickness
%
% INPUT:
%   G - MRST grid structure
%   layer_thicknesses - Array of layer thicknesses
%
% OUTPUT:
%   G - Grid with adjusted Z-coordinates

    % Get grid dimensions
    nx = G.cartDims(1);
    ny = G.cartDims(2);
    nz = G.cartDims(3);
    
    % Calculate cumulative depths for layer interfaces
    layer_tops = [0, cumsum(layer_thicknesses(1:end-1))];
    layer_bottoms = cumsum(layer_thicknesses);
    
    % Adjust node coordinates
    total_nodes = (nx+1) * (ny+1) * (nz+1);
    
    for k = 1:nz+1
        % Find all nodes at this K level
        k_start = (k-1) * (nx+1) * (ny+1) + 1;
        k_end = k * (nx+1) * (ny+1);
        
        if k == 1
            % Top surface
            z_value = 0;
        else
            % Layer interface
            z_value = layer_bottoms(k-1);
        end
        
        % Update Z coordinates for all nodes at this level
        G.nodes.coords(k_start:k_end, 3) = z_value;
    end

end

function G = apply_coordinate_transform(G, grid_params)
% APPLY_COORDINATE_TRANSFORM - Apply field-specific coordinate transformation
%
% INPUT:
%   G - MRST grid structure
%   grid_params - Grid parameters including origin
%
% OUTPUT:
%   G - Grid with transformed coordinates

    % Get origin coordinates
    origin_x = grid_params.origin_x;
    origin_y = grid_params.origin_y; 
    origin_z = grid_params.origin_z;
    
    % Apply translation
    G.nodes.coords(:, 1) = G.nodes.coords(:, 1) + origin_x;
    G.nodes.coords(:, 2) = G.nodes.coords(:, 2) + origin_y;
    G.nodes.coords(:, 3) = G.nodes.coords(:, 3) + origin_z;
    
    fprintf('     Grid origin: (%.1f, %.1f, %.1f) ft\n', origin_x, origin_y, origin_z);

end

function quality_metrics = validate_grid_quality(G, grid_params)
% VALIDATE_GRID_QUALITY - Check grid quality metrics
%
% INPUT:
%   G - MRST grid structure
%   grid_params - Grid parameters
%
% OUTPUT:
%   quality_metrics - Structure with quality assessment

    quality_metrics = struct();
    
    % Check cell count consistency
    expected_cells = grid_params.nx * grid_params.ny * grid_params.nz;
    quality_metrics.cell_count_match = (G.cells.num == expected_cells);
    
    if ~quality_metrics.cell_count_match
        error('Cell count mismatch. Expected %d, got %d', expected_cells, G.cells.num);
    end
    
    % Check for degenerate cells (zero or negative volume)
    min_volume = min(G.cells.volumes);
    quality_metrics.min_volume = min_volume;
    quality_metrics.has_degenerate_cells = (min_volume <= 0);
    
    if quality_metrics.has_degenerate_cells
        error('Degenerate cells detected (volume ≤ 0). Minimum volume: %.2e', min_volume);
    end
    
    % Check volume distribution
    volume_std = std(G.cells.volumes);
    volume_mean = mean(G.cells.volumes);
    quality_metrics.volume_cv = volume_std / volume_mean;
    quality_metrics.volume_uniformity_ok = (quality_metrics.volume_cv < 0.5);
    
    if ~quality_metrics.volume_uniformity_ok
        warning('High volume variation detected (CV=%.3f). Grid may have quality issues.', ...
                quality_metrics.volume_cv);
    end
    
    % Check coordinate ranges
    x_range = max(G.cells.centroids(:,1)) - min(G.cells.centroids(:,1));
    y_range = max(G.cells.centroids(:,2)) - min(G.cells.centroids(:,2));
    z_range = max(G.cells.centroids(:,3)) - min(G.cells.centroids(:,3));
    
    quality_metrics.x_range = x_range;
    quality_metrics.y_range = y_range;
    quality_metrics.z_range = z_range;
    quality_metrics.coordinate_ranges_ok = (x_range > 0 && y_range > 0 && z_range > 0);
    
    if ~quality_metrics.coordinate_ranges_ok
        error('Invalid coordinate ranges. X: %.1f, Y: %.1f, Z: %.1f', x_range, y_range, z_range);
    end
    
    % Overall quality assessment
    quality_metrics.overall_quality = quality_metrics.cell_count_match && ...
                                     ~quality_metrics.has_degenerate_cells && ...
                                     quality_metrics.volume_uniformity_ok && ...
                                     quality_metrics.coordinate_ranges_ok;

end

function print_quality_metrics(quality_metrics)
% PRINT_QUALITY_METRICS - Display grid quality assessment
%
% INPUT:
%   quality_metrics - Quality metrics structure

    fprintf('     Cell count consistency: %s\n', bool_to_status(quality_metrics.cell_count_match));
    fprintf('     Minimum cell volume: %.2e ft³\n', quality_metrics.min_volume);
    fprintf('     Volume uniformity (CV): %.3f %s\n', quality_metrics.volume_cv, ...
            bool_to_status(quality_metrics.volume_uniformity_ok));
    fprintf('     Coordinate ranges: X=%.1f, Y=%.1f, Z=%.1f ft %s\n', ...
            quality_metrics.x_range, quality_metrics.y_range, quality_metrics.z_range, ...
            bool_to_status(quality_metrics.coordinate_ranges_ok));
    fprintf('     Overall quality: %s\n', bool_to_status(quality_metrics.overall_quality));

end

function status_str = bool_to_status(bool_val)
% BOOL_TO_STATUS - Convert boolean to status string
    if bool_val
        status_str = '✓';
    else
        status_str = '❌';
    end
end

function G = add_field_properties(G, grid_params)
% ADD_FIELD_PROPERTIES - Add Eagle West Field specific properties to grid
%
% INPUT:
%   G - MRST grid structure
%   grid_params - Grid configuration parameters
%
% OUTPUT:
%   G - Grid with added properties

    % Add field identification
    G.field_name = 'Eagle West Field';
    G.creation_date = datestr(now);
    
    % Add layer information
    nz = grid_params.nz;
    layer_thicknesses = grid_params.layer_thicknesses;
    
    % Assign layer indices to cells
    cells_per_layer = G.cells.num / nz;
    G.cells.layer_index = zeros(G.cells.num, 1);
    G.cells.layer_thickness = zeros(G.cells.num, 1);
    
    for k = 1:nz
        cell_start = (k-1) * cells_per_layer + 1;
        cell_end = k * cells_per_layer;
        
        G.cells.layer_index(cell_start:cell_end) = k;
        G.cells.layer_thickness(cell_start:cell_end) = layer_thicknesses(k);
    end
    
    % Add grid metrics
    G.metrics = struct();
    G.metrics.total_volume = sum(G.cells.volumes);
    G.metrics.average_cell_volume = mean(G.cells.volumes);
    G.metrics.aspect_ratio = min(grid_params.cell_size_x, grid_params.cell_size_y) / ...
                            max(layer_thicknesses);

end

function export_grid_data(G, grid_params)
% EXPORT_GRID_DATA - Export grid data to files
%
% INPUT:
%   G - MRST grid structure
%   grid_params - Grid configuration parameters

    % Create output directory
    script_path = fileparts(mfilename('fullpath'));
    data_dir = fullfile(fileparts(script_path), 'data', 'mrst_simulation', 'static');
    
    if ~exist(data_dir, 'dir')
        mkdir(data_dir);
    end
    
    % Save grid in MATLAB format
    grid_file = fullfile(data_dir, 'grid_structure.mat');
    save(grid_file, 'G', 'grid_params', '');
    
    % Export grid summary
    summary_file = fullfile(data_dir, 'grid_summary.txt');
    fid = fopen(summary_file, 'w');
    
    fprintf(fid, 'Eagle West Field - Grid Summary\n');
    fprintf(fid, '================================\n\n');
    fprintf(fid, 'Grid Dimensions: %d × %d × %d\n', G.cartDims);
    fprintf(fid, 'Total Cells: %d\n', G.cells.num);
    fprintf(fid, 'Total Faces: %d\n', G.faces.num);
    fprintf(fid, 'Total Nodes: %d\n', G.nodes.num);
    fprintf(fid, 'Grid Volume: %.2e ft³\n', sum(G.cells.volumes));
    fprintf(fid, 'Average Cell Volume: %.1f ft³\n', mean(G.cells.volumes));
    fprintf(fid, '\nCell Size: %.1f ft × %.1f ft\n', grid_params.cell_size_x, grid_params.cell_size_y);
    fprintf(fid, 'Layer Thicknesses: %.1f - %.1f ft\n', ...
            min(grid_params.layer_thicknesses), max(grid_params.layer_thicknesses));
    fprintf(fid, '\nCreation Date: %s\n', datestr(now));
    
    fclose(fid);
    
    fprintf('     Grid saved to: %s\n', grid_file);
    fprintf('     Summary saved to: %s\n', summary_file);

end

% Load grid configuration (calls read_yaml_config)
function grid_config = load_grid_config()
    % Load grid configuration using the YAML reader
    grid_config = read_yaml_config('config/grid_config.yaml');
end

% Main execution when called as script  
if ~nargout
    % If called as script (not function), create and display grid
    G = s02_create_grid();
    
    % Display basic grid info
    fprintf('Grid ready for simulation!\n');
    fprintf('Use "plotGrid(G)" to visualize the grid structure.\n\n');
end