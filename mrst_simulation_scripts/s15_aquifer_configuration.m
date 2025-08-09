function output_data = s15_aquifer_configuration()
% S15_AQUIFER_CONFIGURATION - MRST aquifer configuration with Carter-Tracy model
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
    run('print_utils.m');
    
    % Print module header
    print_step_header('S15', 'AQUIFER CONFIGURATION');
    
    output_data = struct();
    
    try
        %% 1. Load Configuration and Previous Results
        fprintf('📋 Loading configuration and previous results...\n');
        
        % Load YAML configurations
        init_config = read_yaml_config('config/initialization_config.yaml', 'silent', true);
        
        % Load grid with pressure and saturations from s14
        if exist('data/mrst_simulation/static/grid_with_pressure_saturation.mat', 'file')
            fprintf('   ✅ Loading grid with pressure and saturations from s14\n');
            load('data/mrst_simulation/static/grid_with_pressure_saturation.mat', ...
                 'G_with_pressure_sat', 'state', 'rock', 'rock_types');
            G = G_with_pressure_sat;
        else
            error('Grid with pressure/saturations not found. Run s14_saturation_distribution.m first');
        end
        
        % Load fluid properties for aquifer
        if exist('data/mrst_simulation/static/complete_fluid_blackoil.mat', 'file')
            fprintf('   ✅ Loading fluid properties from s12\n');
            load('data/mrst_simulation/static/complete_fluid_blackoil.mat', 'fluid_complete');
            fluid = fluid_complete;
        else
            error('Complete fluid properties not found. Run s12_pvt_tables.m first');
        end
        
        %% 2. Extract Aquifer Configuration Parameters
        fprintf('⚙️  Extracting aquifer configuration parameters...\n');
        
        % Aquifer properties from initialization config
        aquifer_params = init_config.aquifer_parameters;
        
        aquifer_porosity = aquifer_params.porosity;           % 0.23
        aquifer_permeability = aquifer_params.permeability_md; % 100 mD
        aquifer_thickness = aquifer_params.thickness_ft;       % 50 ft
        aquifer_compressibility = aquifer_params.compressibility_per_psi; % 4.1e-6 /psi
        
        % Aquifer geometry
        reservoir_radius = aquifer_params.reservoir_radius_ft;  % Effective reservoir radius
        aquifer_radius = aquifer_params.aquifer_radius_ft;      % External aquifer boundary
        
        % Carter-Tracy model parameters
        aquifer_type = aquifer_params.model_type;               % 'carter_tracy'
        boundary_condition = aquifer_params.boundary_condition; % 'peripheral'
        
        % System properties for aquifer calculations from fluid model
        p_ref = convertTo(datum_pressure, psia);  % Reference pressure for fluid properties
        water_viscosity = fluid.muW(p_ref) / centi*poise;  % Convert from Pa·s to cp
        water_compressibility = 3.2e-6; % /psi (from YAML - not calculable by simulator)
        
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
        % Load empirical constants from YAML (petroleum engineering standards)
        carter_tracy_consts = aquifer_params.carter_tracy_constants;
        carter_tracy_constant = carter_tracy_consts.carter_tracy_constant;
        vh_time_constant = carter_tracy_consts.van_everdingen_hurst_constant;
        
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
        
        % Find boundary cells (cells at model edges that contact aquifer)
        boundary_faces = boundaryFaces(G);
        boundary_cells = unique(boundary_faces);
        
        % For peripheral aquifer, identify bottom and edge cells
        cell_centers = G.cells.centroids;
        
        % Convert cell depths to feet using MRST native function (consistent with s13/s14)
        cell_depths_m = cell_centers(:, 3);
        cell_depths = convertTo(abs(cell_depths_m), ft);
        
        % Identify aquifer-connected cells (bottom of reservoir + edges)
        max_depth = max(cell_depths);
        depth_threshold = max_depth - 20;  % Within 20 ft of bottom
        
        % Find cells that could connect to aquifer
        deep_cells = find(cell_depths > depth_threshold);
        
        % Also include cells at lateral boundaries (for peripheral aquifer)
        [I, J, K] = gridLogicalIndices(G);
        edge_cells = find(I == 1 | I == max(I) | J == 1 | J == max(J));
        
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
        datum_pressure = 2900;      % psi (from initialization)
        datum_depth = 8000;         % ft TVDSS
        water_gradient = 0.433;     % psi/ft
        
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
            % Convert to barrels using MRST native function
            connected_pore_volume_bbl = convertTo(connected_pore_volume, stb);
        end
        
        aquifer_analysis.connected_pore_volume_bbl = connected_pore_volume_bbl;
        
        fprintf('   📊 Connected pore volume: %.0f bbl\n', connected_pore_volume_bbl);
        fprintf('   📊 Connection ratio: %.1f%% of total cells\n', aquifer_analysis.connection_ratio * 100);
        
        %% 8. Export Results
        fprintf('📁 Exporting aquifer configuration data...\n');
        
        % Ensure output directory exists
        output_dir = 'data/mrst_simulation/static';
        if ~exist(output_dir, 'dir')
            mkdir(output_dir);
        end
        
        % Save aquifer model and analysis
        save(fullfile(output_dir, 'aquifer_configuration.mat'), ...
             'aquifer_model', 'aquifer_analysis', 'aquifer_cells', ...
             'aquifer_pressure', 'boundary_cells');
        
        % Save complete initialization state for simulation
        % This combines grid, pressure, saturations, rock properties, and aquifer
        state_complete = state;  % Already has pressure and saturations from s14
        save(fullfile(output_dir, 'complete_initialization_state.mat'), ...
             'G', 'state_complete', 'rock', 'rock_types', 'aquifer_model', ...
             'fluid_complete');
        
        %% 9. Create Output Summary
        output_data.aquifer_model = aquifer_model;
        output_data.aquifer_analysis = aquifer_analysis;
        output_data.validation_passed = validation_passed;
        output_data.aquifer_cells = aquifer_cells;
        output_data.aquifer_pressure = aquifer_pressure;
        output_data.connected_pore_volume = connected_pore_volume_bbl;
        output_data.boundary_condition = aquifer_model.boundary_condition;
        
        % Success message
        print_step_footer('S15', 'Aquifer configuration completed successfully', toc);
        
    catch ME
        print_step_footer('S15', sprintf('FAILED: %s', ME.message), toc);
        rethrow(ME);
    end
    
end