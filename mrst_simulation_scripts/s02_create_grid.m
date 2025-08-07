function G = s02_create_grid()
% S02_CREATE_GRID - Create reservoir grid for Eagle West Field
% Requires: MRST
%
% OUTPUT:
%   G - MRST grid structure with geometry
%
% Author: Claude Code AI System  
% Date: January 30, 2025

    run('print_utils.m');
    print_step_header('S02', 'Create Reservoir Grid');
    
    total_start_time = tic;
    
    try
        % ----------------------------------------
        % Step 1 – Load Grid Configuration
        % ----------------------------------------
        step_start = tic;
        grid_params = step_1_load_config();
        print_step_result(1, 'Load Grid Configuration', 'success', toc(step_start));
        
        % ----------------------------------------
        % Step 2 – Create Cartesian Grid
        % ----------------------------------------
        step_start = tic;
        G = step_2_create_cartesian(grid_params);
        print_step_result(2, 'Create Cartesian Grid', 'success', toc(step_start));
        
        % ----------------------------------------
        % Step 3 – Compute Grid Geometry
        % ----------------------------------------
        step_start = tic;
        G = step_3_compute_geometry(G);
        print_step_result(3, 'Compute Grid Geometry', 'success', toc(step_start));
        
        % ---------------------------------------- 
        % Step 4 – Validate Grid Quality
        % ----------------------------------------
        step_start = tic;
        step_4_validate_quality(G, grid_params);
        print_step_result(4, 'Validate Grid Quality', 'success', toc(step_start));
        
        print_step_footer('S02', sprintf('Grid Ready: %dx%dx%d cells', G.cartDims), toc(total_start_time));
        
    catch ME
        print_error_step(0, 'Grid Construction', ME.message);
        error('Grid construction failed: %s', ME.message);
    end

end

function grid_params = step_1_load_config()
% Step 1 - Load and validate grid configuration

    % Substep 1.1 – Use simplified configuration __________________
    grid_config = create_default_grid_config();
    grid_params = grid_config.grid;
    
    % Substep 1.2 – Validate required parameters __________________
    validate_grid_parameters(grid_params);
    
end

function validate_grid_parameters(grid_params)
% Validate grid configuration parameters
    required_fields = {'nx', 'ny', 'nz', 'cell_size_x', 'cell_size_y', 'layer_thicknesses'};
    
    for i = 1:length(required_fields)
        if ~isfield(grid_params, required_fields{i})
            error('Required grid parameter missing: %s', required_fields{i});
        end
    end
    
    % ✅ Validate positive dimensions
    if grid_params.nx <= 0 || grid_params.ny <= 0 || grid_params.nz <= 0
        error('Grid dimensions must be positive');
    end
    
    % ✅ Validate cell sizes
    if grid_params.cell_size_x <= 0 || grid_params.cell_size_y <= 0
        error('Cell sizes must be positive');
    end
    
    % ✅ Validate layer thicknesses match nz
    if length(grid_params.layer_thicknesses) ~= grid_params.nz
        error('Layer thickness count must match nz');
    end
    
end

function G = step_2_create_cartesian(grid_params)
% Step 2 - Create Cartesian grid structure

    % Substep 2.1 – Extract grid dimensions _______________________
    grid_dims = [grid_params.nx, grid_params.ny, grid_params.nz];
    
    % Substep 2.2 – Calculate physical dimensions __________________
    dx = grid_params.cell_size_x * grid_params.nx;
    dy = grid_params.cell_size_y * grid_params.ny;  
    dz = sum(grid_params.layer_thicknesses);
    physical_dims = [dx, dy, dz];
    
    % ✅ Create MRST Cartesian grid
    G = cartGrid(grid_dims, physical_dims);
    
    % Substep 2.3 – Adjust variable layer thicknesses _____________
    G = adjust_layer_thicknesses(G, grid_params.layer_thicknesses);

end

function G = adjust_layer_thicknesses(G, layer_thicknesses)
% Adjust Z-coordinates for variable layer thickness
    nz = G.cartDims(3);
    nx = G.cartDims(1);
    ny = G.cartDims(2);
    
    % Calculate cumulative layer depths
    layer_bottoms = cumsum(layer_thicknesses);
    
    % Adjust node Z-coordinates for each layer
    for k = 1:nz+1
        k_start = (k-1) * (nx+1) * (ny+1) + 1;
        k_end = k * (nx+1) * (ny+1);
        
        if k == 1
            z_value = 0;  % Top surface
        else
            z_value = layer_bottoms(k-1);  % Layer interface
        end
        
        G.nodes.coords(k_start:k_end, 3) = z_value;
    end
    
end

function G = step_3_compute_geometry(G)
% Step 3 - Compute grid geometry and properties

    % ✅ Compute MRST geometry 
    G = computeGeometry(G);
    
    % Substep 3.1 – Add layer indices ____________________________
    G = add_layer_indices(G);
    
end

function G = add_layer_indices(G)
% Add layer index to each cell
    nz = G.cartDims(3);
    cells_per_layer = G.cartDims(1) * G.cartDims(2);
    
    G.cells.layer_index = zeros(G.cells.num, 1);
    for layer = 1:nz
        start_cell = (layer - 1) * cells_per_layer + 1;
        end_cell = layer * cells_per_layer;
        G.cells.layer_index(start_cell:end_cell) = layer;
    end
end

function step_4_validate_quality(G, grid_params)
% Step 4 - Validate grid quality metrics

    % Substep 4.1 – Check cell aspect ratios _____________________
    validate_aspect_ratios(G);
    
    % Substep 4.2 – Export grid data _____________________________
    export_grid_data(G, grid_params);
    
end

function validate_aspect_ratios(G)
% Check grid cell aspect ratios for numerical stability
    min_volume = min(G.cells.volumes);
    max_volume = max(G.cells.volumes);
    volume_ratio = max_volume / min_volume;
    
    if volume_ratio > 1000
        error('Poor grid quality: volume ratio %.1f too high', volume_ratio);
    end
    
    if min_volume <= 0
        error('Degenerate cells detected (volume ≤ 0)');
    end
end

function export_grid_data(G, grid_params)
% Export grid data to files
    script_path = fileparts(mfilename('fullpath'));
    data_dir = fullfile(fileparts(script_path), 'data', 'mrst_simulation', 'static');
    
    if ~exist(data_dir, 'dir')
        mkdir(data_dir);
    end
    
    % Save base grid structure
    base_grid_file = fullfile(data_dir, 'base_grid.mat');
    save(base_grid_file, 'G', 'grid_params');
end

function grid_config = create_default_grid_config()
% Load grid configuration from YAML - NO HARDCODING POLICY
    
    try
        % Policy Compliance: Load ALL parameters from YAML config
        grid_config = read_yaml_config('config/grid_config.yaml');
        
        % Validate required fields exist
        required_fields = {'grid'};
        for i = 1:length(required_fields)
            if ~isfield(grid_config, required_fields{i})
                error('Missing required field in grid_config.yaml: %s', required_fields{i});
            end
        end
        
        % Validate grid sub-fields
        grid_required = {'nx', 'ny', 'nz', 'cell_size_x', 'cell_size_y', 'layer_thicknesses'};
        for i = 1:length(grid_required)
            if ~isfield(grid_config.grid, grid_required{i})
                error('Missing required grid parameter in YAML: %s', grid_required{i});
            end
        end
        
        fprintf('Grid configuration loaded from YAML: %dx%dx%d cells\n', ...
                grid_config.grid.nx, grid_config.grid.ny, grid_config.grid.nz);
                
    catch ME
        error('Failed to load grid configuration from YAML: %s\nPolicy violation: No hardcoding allowed', ME.message);
    end
    
end

% Main execution when called as script
if ~nargout
    G = s02_create_grid();
end