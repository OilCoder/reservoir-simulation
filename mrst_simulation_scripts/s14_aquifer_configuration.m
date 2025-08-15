function output_data = s14_aquifer_configuration()
% S14_AQUIFER_CONFIGURATION - MRST aquifer configuration with Carter-Tracy model
%
% DESCRIPTION:
%   Implements analytical aquifer model (Carter-Tracy) for boundary pressure
%   support in Eagle West Field reservoir simulation. Configures aquifer
%   properties and boundary conditions for natural pressure maintenance.
%
% CANON REFERENCE: 
%   [[07_Initialization]] - Aquifer parameters section
%   - Analytical aquifer model: Carter-Tracy
%   - Aquifer strength: moderate support
%   - Bottom aquifer drive boundary conditions
%   - Aquifer properties: φ=23%, k=100mD, h=50ft
%   - Peripheral aquifer configuration
%
% WORKFLOW:
%   1. Load grid and initialization configuration
%   2. Configure Carter-Tracy analytical aquifer model
%   3. Set aquifer properties and geometry parameters
%   4. Define boundary conditions and connectivity
%   5. Calculate aquifer strength and influx potential
%   6. Export aquifer model for simulation
%
% RETURNS:
%   output_data - Structure with aquifer configuration results
%
% Author: Claude Code AI System
% Date: January 30, 2025

    % Load print utilities for consistent table format
    script_dir = fileparts(mfilename('fullpath'));
    addpath(fullfile(script_dir, 'utils')); 
    run(fullfile(script_dir, 'utils', 'print_utils.m'));

    % Add MRST session validation
    [success, message] = validate_mrst_session(script_dir);
    if ~success
        error('MRST validation failed: %s', message);
    end
    
    % Print module header
    print_step_header('S14', 'AQUIFER CONFIGURATION');
    
    % Start timer
    start_time = tic;
    output_data = struct();
    
    try
        %% 1. Load Configuration and Previous Results
        fprintf('📋 Loading configuration and previous results...\n');
        
        % Load YAML configurations
        addpath(fullfile(script_dir, 'utils'));
        init_config = read_yaml_config('config/initialization_config.yaml', true);
        
        % Load grid with pressure and saturations from s13
        data_dir = get_data_path('static');
        grid_file = fullfile(data_dir, 'grid_with_pressure_saturation.mat');
        if exist(grid_file, 'file')
            fprintf('   ✅ Loading grid with pressure and saturations from s13\n');
            load(grid_file, 'G_with_pressure_sat', 'state', 'rock', 'rock_types');
            G = G_with_pressure_sat;
        else
            error('Grid with pressure/saturations not found. Run s13_saturation_distribution.m first');
        end
        
        % Load fluid properties for aquifer
        addpath(fullfile(script_dir, 'utils')); 
        fluid_file = '/workspaces/claudeclean/data/simulation_data/static/fluid/complete_fluid_blackoil.mat';
        if exist(fluid_file, 'file')
            fprintf('   ✅ Loading fluid properties from s11\n');
            load(fluid_file, 'fluid_complete');
            fluid = fluid_complete;
        else
            error('Complete fluid properties not found. Run s11_pvt_tables.m first');
        end
        
        %% 2. Extract Aquifer Configuration Parameters
        fprintf('⚙️  Extracting aquifer configuration parameters...\n');
        
        % Extract aquifer properties from YAML configuration (FAIL_FAST_POLICY)
        if ~isfield(init_config.initialization, 'aquifer_configuration')
            error('Aquifer configuration missing from initialization_config.yaml. Add aquifer_configuration section.');
        end
        
        aquifer_config = init_config.initialization.aquifer_configuration;
        
        % Properties are now flattened in aquifer_config (YAML parser compatibility)
        aquifer_params = aquifer_config;
        
        aquifer_porosity = aquifer_params.aquifer_porosity;
        aquifer_permeability = aquifer_params.aquifer_permeability_md;
        aquifer_thickness = aquifer_params.aquifer_thickness_ft;
        aquifer_compressibility = aquifer_params.aquifer_compressibility_1_psi;
        
        % Aquifer geometry - calculate from grid if not specified
        if isfield(aquifer_params, 'reservoir_radius_ft')
            reservoir_radius = aquifer_params.reservoir_radius_ft;
        else
            % Calculate effective reservoir radius from grid
            max_x = max(G.nodes.coords(:,1));
            min_x = min(G.nodes.coords(:,1));
            max_y = max(G.nodes.coords(:,2));
            min_y = min(G.nodes.coords(:,2));
            % Convert to feet using CANON unit conversion factor
            if ~isfield(init_config.initialization, 'unit_conversions') || ~isfield(init_config.initialization.unit_conversions.length, 'm_to_ft')
                error(['CANON-FIRST ERROR: Missing m_to_ft conversion factor in initialization_config.yaml\n' ...
                       'UPDATE CANON: obsidian-vault/Planning/Initial_Conditions.md\n' ...
                       'Must define exact unit conversion factors for Eagle West Field.']);
            end
            m_to_ft = init_config.initialization.unit_conversions.length.m_to_ft;
            reservoir_radius = 0.5 * sqrt((max_x-min_x)^2 + (max_y-min_y)^2) * m_to_ft;
        end
        
        aquifer_radius = aquifer_params.aquifer_radius_ft;
        
        % Carter-Tracy model parameters
        aquifer_type = aquifer_config.aquifer_model;
        boundary_condition = aquifer_config.aquifer_type;
        
        % Load pressure initialization data to get actual datum values (needed for calculations)
        pressure_file = '/workspaces/claudeclean/data/by_type/static/pressure_initialization_s12.mat';
        if exist(pressure_file, 'file')
            load(pressure_file, 'init_config');
            datum_pressure = init_config.initialization.initial_conditions.initial_pressure_psi;
            datum_depth = init_config.initialization.equilibration_method.datum_depth_ft_tvdss;
            water_gradient = init_config.initialization.pressure_gradients.water_gradient_psi_ft;
        else
            error('Pressure initialization data not found. Run s12_pressure_initialization.m first');
        end
        
        % System properties for aquifer calculations from fluid model
        % Extract unit conversion factor from CANON configuration (CANON-FIRST)
        if ~isfield(init_config.initialization, 'unit_conversions') || ~isfield(init_config.initialization.unit_conversions.pressure, 'psi_to_pa')
            error(['CANON-FIRST ERROR: Missing psi_to_pa conversion factor in initialization_config.yaml\n' ...
                   'UPDATE CANON: obsidian-vault/Planning/Initial_Conditions.md\n' ...
                   'Must define exact pressure unit conversion factors for Eagle West Field.']);
        end
        psi_to_pa = init_config.initialization.unit_conversions.pressure.psi_to_pa;
        p_ref = datum_pressure * psi_to_pa;  % Convert psi to Pa using CANON factor
        
        % Extract water viscosity from YAML configuration (CANON-FIRST)
        addpath(fullfile(script_dir, 'utils'));
        fluid_config = read_yaml_config('config/fluid_properties_config.yaml', true);
        if ~isfield(fluid_config, 'fluid_properties') || ~isfield(fluid_config.fluid_properties, 'water_viscosity')
            error(['CANON-FIRST ERROR: Missing water_viscosity in fluid_properties_config.yaml\n' ...
                   'UPDATE CANON: obsidian-vault/Planning/Fluid_Properties.md\n' ...
                   'Must define exact water viscosity for Eagle West Field.']);
        end
        water_viscosity = fluid_config.fluid_properties.water_viscosity;  % cp from CANON YAML
        % Extract water compressibility from YAML (CANON-FIRST)
        if ~isfield(aquifer_params, 'aquifer_compressibility_1_psi')
            error(['CANON-FIRST ERROR: Missing aquifer_compressibility_1_psi in initialization_config.yaml\n' ...
                   'UPDATE CANON: obsidian-vault/Planning/Initial_Conditions.md\n' ...
                   'Must define exact aquifer compressibility for Eagle West Field.']);
        end
        water_compressibility = aquifer_params.aquifer_compressibility_1_psi; % /psi from CANON YAML
        
        fprintf('   📊 Aquifer type: %s\n', aquifer_type);
        fprintf('   📊 Boundary condition: %s\n', boundary_condition);
        fprintf('   📊 Aquifer properties: φ=%.1f%%, k=%.0f mD, h=%.0f ft\n', ...
                aquifer_porosity*100, aquifer_permeability, aquifer_thickness);
        fprintf('   📊 Geometry: R_res=%.0f ft, R_aq=%.0f ft\n', reservoir_radius, aquifer_radius);
        
        %% 3. Calculate Carter-Tracy Aquifer Parameters
        fprintf('⚙️  Calculating Carter-Tracy aquifer parameters...\n');
        
        % Convert units for calculations
        k_aq_darcy = aquifer_permeability / 1000;  % mD to Darcy
        k_aq_md = aquifer_permeability;            % Keep in mD for MRST
        phi_aq = aquifer_porosity;
        h_aq_ft = aquifer_thickness;
        ct_total = aquifer_compressibility + water_compressibility; % Total compressibility
        
        % Carter-Tracy model parameters
        radius_ratio = aquifer_radius / reservoir_radius;
        
        % Aquifer constant (for Carter-Tracy influx calculation)
        % W_e = B * sum(Q_D * ΔP) where B is the aquifer constant
        % Load Carter-Tracy constants from YAML (FAIL_FAST_POLICY, flattened)
        if ~isfield(aquifer_config, 'carter_tracy_constant')
            error('Carter-Tracy constants missing from YAML config. Add carter_tracy_constant and van_everdingen_hurst_constant.');
        end
        
        carter_tracy_constant = aquifer_config.carter_tracy_constant;
        vh_time_constant = aquifer_config.van_everdingen_hurst_constant;
        
        aquifer_constant_B = carter_tracy_constant * phi_aq * ct_total * h_aq_ft * (reservoir_radius^2);
        
        % Dimensionless parameters for Carter-Tracy model
        time_constant = vh_time_constant * k_aq_darcy / (phi_aq * water_viscosity * ct_total * (reservoir_radius^2));
        
        % Aquifer productivity index (for MRST boundary condition)
        % PI_aq = 2*π*k*h / (ln(r_e/r_w) * μ)
        geometric_factor = log(radius_ratio);
        if geometric_factor <= 0
            geometric_factor = log(2.0);  % Minimum value for numerical stability
        end
        
        aquifer_PI = 2 * pi * k_aq_md * h_aq_ft / (geometric_factor * water_viscosity);
        
        % Aquifer strength indicator
        aquifer_strength = 'moderate';
        if aquifer_constant_B > 1e6
            aquifer_strength = 'strong';
        elseif aquifer_constant_B < 1e4
            aquifer_strength = 'weak';
        end
        
        fprintf('   📊 Aquifer constant B: %.2e bbl/psi\n', aquifer_constant_B);
        fprintf('   📊 Time constant: %.2e /day\n', time_constant * 24); % Convert to per day
        fprintf('   📊 Aquifer PI: %.0f bbl/day/psi\n', aquifer_PI);
        fprintf('   📊 Aquifer strength: %s\n', aquifer_strength);
        
        %% 4. Configure MRST Aquifer Boundary Conditions
        fprintf('🌊 Configuring MRST aquifer boundary conditions...\n');
        
        % Find boundary cells using MRST function (FAIL_FAST_POLICY)
        if ~exist('boundaryFaces', 'file') && isempty(which('boundaryFaces'))
            error('MRST function boundaryFaces not available. Install required MRST modules or check initialization.');
        end
        
        boundary_faces = boundaryFaces(G);
        boundary_cells = unique(boundary_faces);
        
        % For peripheral aquifer, identify bottom and edge cells
        cell_centers = G.cells.centroids;
        
        % Convert cell depths to feet using MRST units (FAIL_FAST_POLICY)
        if ~exist('ft', 'var') && isempty(which('ft'))
            error('MRST unit ft not available. Check MRST units module initialization.');
        end
        
        cell_depths_m = cell_centers(:, 3);
        cell_depths = convertTo(abs(cell_depths_m), ft);
        
        % Identify aquifer-connected cells (bottom of reservoir + edges)
        max_depth = max(cell_depths);
        depth_threshold = max_depth - 20;  % Within 20 ft of bottom
        
        % Find cells that could connect to aquifer
        deep_cells = find(cell_depths > depth_threshold);
        
        % Find lateral boundary cells for PEBI grid (unstructured approach)
        % For PEBI grids, identify boundary cells by face connectivity
        boundary_faces = find(any(G.faces.neighbors == 0, 2));  % Faces with no neighbors (external boundary)
        
        % Get cells adjacent to boundary faces
        boundary_cells_temp = G.faces.neighbors(boundary_faces, :);
        boundary_cells_temp = boundary_cells_temp(boundary_cells_temp > 0);  % Remove zeros
        edge_cells = unique(boundary_cells_temp);
        
        % Combine deep cells and edge cells for aquifer connection
        aquifer_cells = unique([deep_cells; edge_cells]);
        
        % Remove cells that are not in boundary_cells
        aquifer_cells = intersect(aquifer_cells, boundary_cells);
        
        fprintf('   📊 Total boundary cells: %d\n', length(boundary_cells));
        fprintf('   📊 Aquifer-connected cells: %d\n', length(aquifer_cells));
        
        %% 5. Create Aquifer Model Structure
        fprintf('📝 Creating aquifer model structure...\n');
        
        % Create aquifer model structure for MRST
        aquifer_model = struct();
        aquifer_model.type = 'carter_tracy';
        aquifer_model.cells = aquifer_cells;
        aquifer_model.radius_ratio = radius_ratio;
        aquifer_model.aquifer_constant = aquifer_constant_B;
        aquifer_model.time_constant = time_constant;
        aquifer_model.PI = aquifer_PI;
        aquifer_model.strength = aquifer_strength;
        
        % Aquifer properties
        aquifer_model.properties = struct();
        aquifer_model.properties.porosity = aquifer_porosity;
        aquifer_model.properties.permeability = aquifer_permeability;
        aquifer_model.properties.thickness = aquifer_thickness;
        aquifer_model.properties.compressibility = aquifer_compressibility;
        aquifer_model.properties.radius_reservoir = reservoir_radius;
        aquifer_model.properties.radius_external = aquifer_radius;
        
        % Boundary condition specification for MRST
        aquifer_model.boundary_condition = struct();
        aquifer_model.boundary_condition.type = 'pressure';  % Pressure boundary
        aquifer_model.boundary_condition.cells = aquifer_cells;
        aquifer_model.boundary_condition.pressure_support = true;
        
        % Initial aquifer pressure (matches initial reservoir pressure at aquifer depth)
        aquifer_depth = max_depth;  % Deepest part of reservoir
        
        aquifer_pressure = datum_pressure + water_gradient * (aquifer_depth - datum_depth);
        aquifer_model.initial_pressure = aquifer_pressure;
        
        fprintf('   📊 Aquifer pressure: %.0f psi at %.0f ft\n', aquifer_pressure, aquifer_depth);
        
        %% 6. Validate Aquifer Configuration
        fprintf('✅ Validating aquifer configuration...\n');
        
        validation_passed = true;
        
        % Check aquifer cells exist
        if isempty(aquifer_cells)
            fprintf('   ⚠️  Warning: No aquifer cells identified\n');
            validation_passed = false;
        end
        
        % Check reasonable aquifer properties using physical constraints
        typical_porosity_min = 0.05;  % Physical minimum for aquifer
        typical_porosity_max = 0.50;  % Physical maximum for unconsolidated sediments
        if aquifer_porosity < typical_porosity_min || aquifer_porosity > typical_porosity_max
            fprintf('   ⚠️  Warning: Aquifer porosity (%.2f) outside physical range [%.2f-%.2f]\n', ...
                    aquifer_porosity, typical_porosity_min, typical_porosity_max);
            validation_passed = false;
        end
        
        typical_perm_min = 1;     % Physical minimum for aquifer flow
        typical_perm_max = 5000;  % Physical maximum for sandstone aquifers
        if aquifer_permeability < typical_perm_min || aquifer_permeability > typical_perm_max
            fprintf('   ⚠️  Warning: Aquifer permeability (%.0f mD) outside physical range [%.0f-%.0f]\n', ...
                    aquifer_permeability, typical_perm_min, typical_perm_max);
            validation_passed = false;
        end
        
        % Check radius ratio for numerical stability (Carter-Tracy model requirement)
        min_radius_ratio = 1.5;  % Numerical minimum for Carter-Tracy
        max_radius_ratio = 50;   % Numerical maximum for Carter-Tracy
        if radius_ratio < min_radius_ratio || radius_ratio > max_radius_ratio
            fprintf('   ⚠️  Warning: Radius ratio (%.1f) outside stable range [%.1f-%.1f]\n', ...
                    radius_ratio, min_radius_ratio, max_radius_ratio);
            validation_passed = false;
        end
        
        % Check aquifer strength consistency
        connectivity_threshold = 0.05;  % 5% of cells connected is reasonable minimum
        if strcmp(aquifer_strength, 'weak') && length(aquifer_cells) > G.cells.num * connectivity_threshold
            fprintf('   ⚠️  Warning: Weak aquifer classification inconsistent with high connectivity\n');
        end
        
        if validation_passed
            fprintf('   ✅ Aquifer validation PASSED\n');
        else
            fprintf('   ⚠️  Aquifer validation completed with warnings\n');
        end
        
        %% 7. Store Results and Analysis
        fprintf('📊 Analyzing aquifer configuration...\n');
        
        % Create aquifer analysis
        aquifer_analysis = struct();
        aquifer_analysis.connected_cells = length(aquifer_cells);
        aquifer_analysis.total_cells = G.cells.num;
        aquifer_analysis.connection_ratio = length(aquifer_cells) / G.cells.num;
        aquifer_analysis.strength_category = aquifer_strength;
        aquifer_analysis.expected_support = 'moderate_to_strong';
        
        % Estimate aquifer pore volume connected
        connected_pore_volume = 0;
        if ~isempty(aquifer_cells)
            connected_pore_volumes = rock.poro(aquifer_cells) .* G.cells.volumes(aquifer_cells);
            connected_pore_volume = sum(connected_pore_volumes);
            % Convert to barrels using MRST units (FAIL_FAST_POLICY)
            if ~exist('stb', 'var') && isempty(which('stb'))
                error('MRST unit stb not available. Check MRST units module initialization.');
            end
            connected_pore_volume_bbl = convertTo(connected_pore_volume, stb);
        end
        
        aquifer_analysis.connected_pore_volume_bbl = connected_pore_volume_bbl;
        
        fprintf('   📊 Connected pore volume: %.0f bbl\n', connected_pore_volume_bbl);
        fprintf('   📊 Connection ratio: %.1f%% of total cells\n', aquifer_analysis.connection_ratio * 100);
        
        %% 8. Export Results
        fprintf('📁 Exporting aquifer configuration data...\n');
        
        % Ensure output directory exists
        % Use same path construction as other working phases  
        script_path = fileparts(mfilename('fullpath'));
        output_dir = get_data_path('static');
        if ~exist(output_dir, 'dir')
            mkdir(output_dir);
        end
        
        % Create basic canonical directory structure
        static_path = fullfile(output_dir, 'by_type', 'static');
        if ~exist(static_path, 'dir')
            mkdir(static_path);
        end
        
        % Save directly with native .mat format
        aquifer_file = fullfile(static_path, 'aquifer_configuration_s14.mat');
        save(aquifer_file, 'aquifer_model', 'aquifer_analysis', 'aquifer_cells', ...
             'aquifer_pressure', 'boundary_cells');
        fprintf('     Canonical data saved: %s\n', aquifer_file);
        
        % Save complete initialization state for simulation (backward compatibility)
        % This combines grid, pressure, saturations, rock properties, and aquifer
        state_complete = state;  % Already has pressure and saturations from s13
        save(fullfile(output_dir, 'complete_initialization_state.mat'), ...
             'G', 'state_complete', 'rock', 'rock_types', 'aquifer_model', ...
             'fluid_complete');
        
        % Also save in canonical location
        save(fullfile(static_path, 'complete_initialization_state_s14.mat'), ...
             'G', 'state_complete', 'rock', 'rock_types', 'aquifer_model', ...
             'fluid_complete');
        fprintf('     Complete initialization state saved: %s\n', fullfile(static_path, 'complete_initialization_state_s14.mat'));
        
        %% 9. Create Output Summary
        output_data.aquifer_model = aquifer_model;
        output_data.aquifer_analysis = aquifer_analysis;
        output_data.validation_passed = validation_passed;
        output_data.aquifer_cells = aquifer_cells;
        output_data.aquifer_pressure = aquifer_pressure;
        output_data.connected_pore_volume = connected_pore_volume_bbl;
        output_data.boundary_condition = aquifer_model.boundary_condition;
        
        % Success message
        print_step_footer('S14', 'Aquifer configuration completed successfully', toc(start_time));
        
    catch ME
        print_step_footer('S14', sprintf('FAILED: %s', ME.message), toc(start_time));
        rethrow(ME);
    end
    
end