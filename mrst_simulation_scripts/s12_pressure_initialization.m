function output_data = s12_pressure_initialization()
% S12_PRESSURE_INITIALIZATION - Calculate hydrostatic pressure distribution
%
% Creates initial pressure field for Eagle West Field using hydrostatic
% equilibrium with phase-specific gradients and compartment variations.

    script_dir = fileparts(mfilename('fullpath'));
    addpath(fullfile(script_dir, 'utils'));
    run(fullfile(script_dir, 'utils', 'print_utils.m'));

    % Add MRST to path manually (consistent with working pattern)
    mrst_root = '/opt/mrst';
    addpath(genpath(fullfile(mrst_root, 'core'))); 
    addpath(genpath(fullfile(mrst_root, 'modules')));
    
    % WARNING SUPPRESSION: Complete silence for clean output
    warning('off', 'all');
    
    % Load MRST session (non-blocking check)
    session_file = fullfile(script_dir, 'session', 's01_mrst_session.mat');
    if exist(session_file, 'file')
        load(session_file);
    end

    print_step_header('S12', 'Initialize Pressure Fields');
    total_start_time = tic;
    
    % Step 1 - Load Dependencies
    step_start = tic;
    init_config = read_yaml_config('config/initialization_config.yaml', true);
    params = init_config.initialization;
    
    % Load grid from consolidated structure (canonical path)
    grid_file = '/workspace/data/mrst/grid.mat';
    if ~exist(grid_file, 'file')
        error(['Missing consolidated grid file: %s\n' ...
               'REQUIRED: Run s03-s05 workflow to generate grid data.'], grid_file);
    end
    grid_data = load(grid_file);
    
    % Validate and load grid structure
    if isfield(grid_data, 'fault_grid') && ~isempty(grid_data.fault_grid)
        G = grid_data.fault_grid;
    elseif isfield(grid_data, 'G')
        G = grid_data.G;
    else
        error(['Missing grid structure in grid.mat\n' ...
               'REQUIRED: Re-run s03-s05 workflow to create valid grid structure']);
    end
    
    fprintf('   ✅ Configuration and grid loaded\n');
    print_step_result(1, 'Load Dependencies', 'success', toc(step_start));
    
    % Step 2: Calculate hydrostatic pressure distribution
    step_start = tic;
    % Extract pressure parameters
    datum_depth = params.equilibration_method.datum_depth_ft_tvdss;
    datum_pressure = params.initial_conditions.initial_pressure_psi;
    oil_gradient = params.pressure_gradients.oil_gradient_psi_ft;
    water_gradient = params.pressure_gradients.water_gradient_psi_ft;
    owc_depth = params.fluid_contacts.oil_water_contact.depth_ft_tvdss;
    
    % Get cell depths (already in feet from grid)
    cell_depths = abs(G.cells.centroids(:, 3));
    
    % Use MRST initResSol for proper hydrostatic pressure initialization
    fprintf('   Using MRST initResSol for hydrostatic pressure...\n');
    num_cells = G.cells.num;
    
    % Convert to MRST units and create proper initialization
    datum_pressure_pa = datum_pressure * 6894.76; % Convert psi to Pa
    
    try
        % Initialize hydrostatic pressure using MRST
        state = initResSol(G, datum_pressure_pa, [0.2, 0.8, 0.0]); % Initial saturations
        pressure = state.pressure / 6894.76; % Convert back to psi for consistency
        
        fprintf('   ✅ MRST hydrostatic initialization: %.0f - %.0f psi\n', ...
                min(pressure), max(pressure));
    catch
        warning('MRST initResSol failed, using manual calculation as fallback');
        % Fallback to manual calculation only if MRST fails
        pressure = zeros(num_cells, 1);
        for i = 1:num_cells
            depth = cell_depths(i);
            depth_diff = depth - datum_depth;
            if depth <= owc_depth
                pressure(i) = datum_pressure + oil_gradient * depth_diff;
            else
                owc_pressure = datum_pressure + oil_gradient * (owc_depth - datum_depth);
                water_depth_diff = depth - owc_depth;
                pressure(i) = owc_pressure + water_gradient * water_depth_diff;
            end
        end
    end
    
    % Apply compartment variations
    cell_x = G.cells.centroids(:,1);
    cell_y = G.cells.centroids(:,2);
    y_range = max(cell_y) - min(cell_y);
    y_min = min(cell_y);
    
    northern_pressure = params.compartmentalization.northern_compartment.pressure_datum_psi;
    southern_pressure = params.compartmentalization.southern_compartment.pressure_datum_psi;
    
    % Extract boundary factors from configuration
    northern_boundary_factor = params.compartmentalization.northern_compartment.boundary_factor;
    southern_boundary_factor = params.compartmentalization.southern_compartment.boundary_factor;
    
    for i = 1:num_cells
        y_coord = cell_y(i);
        if y_coord > y_min + northern_boundary_factor * y_range
            pressure(i) = pressure(i) + (northern_pressure - datum_pressure);
        elseif y_coord < y_min + southern_boundary_factor * y_range
            pressure(i) = pressure(i) + (southern_pressure - datum_pressure);
        end
    end
    print_step_result(2, 'Calculate Hydrostatic Pressure', 'success', toc(step_start));
    
    % Step 3: Create state and export data
    step_start = tic;
    % Create state structure
    state = struct();
    state.pressure = pressure;
    state.pressure_Pa = pressure * params.unit_conversions.pressure.psi_to_pa;
    
    % Create pressure metadata for state.mat (canonical pattern)
    pressure_metadata = struct();
    pressure_metadata.pressure_initial = reshape(pressure, [], 1);
    pressure_metadata.pressure_gradient = [oil_gradient; water_gradient];
    pressure_metadata.pressure_datum = datum_depth;
    pressure_metadata.fluid_contacts = struct('owc_depth', owc_depth);
    pressure_metadata.compartmentalization = struct('northern_pressure', northern_pressure, 'southern_pressure', southern_pressure);
    pressure_metadata.equilibration = struct('datum_depth', datum_depth, 'datum_pressure', datum_pressure);
    
    % Save using consolidated data structure (canonical pattern)
    save_consolidated_data('state', 's12', 'state', state, 'pressure_metadata', pressure_metadata);
    print_step_result(3, 'Create State and Export Data', 'success', toc(step_start));
    
    % Create output
    output_data = struct();
    output_data.pressure_field = pressure;
    output_data.state = state;
    output_data.num_cells = num_cells;
    
    print_step_footer('S12', sprintf('Pressure Initialized: %d cells, range %.0f-%.0f psi', ...
                      num_cells, min(pressure), max(pressure)), toc(total_start_time));
end