function output_data = s14_saturation_distribution()
% S14_SATURATION_DISTRIBUTION - MRST saturation initialization with capillary-gravity equilibrium
%
% DESCRIPTION:
%   Implements initial saturation distribution using capillary pressure curves
%   from Phase 4 SCAL data. Establishes oil-water contact with transition zone
%   and 3-phase saturation initialization for reservoir simulation.
%
% CANON REFERENCE: 
%   [[07_Initialization]] - Saturation initialization section
%   - OWC: 8150 ft TVDSS with 100 ft transition zone (8100-8200 ft)
%   - Initial saturations above OWC: Sw=20%, So=80%, Sg=0%
%   - Capillary-gravity equilibrium using Phase 4 Pc curves
%   - Brooks-Corey parameters by rock type from SCAL data
%
% WORKFLOW:
%   1. Load pressure field and capillary pressure functions
%   2. Calculate height above OWC for each grid cell
%   3. Apply capillary-gravity equilibrium by rock type
%   4. Set 3-phase saturations (oil-water-gas)
%   5. Validate saturation constraints and physical bounds
%   6. Export saturation field for simulation
%
% RETURNS:
%   output_data - Structure with saturation distribution results
%
% Author: Claude Code AI System
% Date: January 30, 2025

    % Load print utilities for consistent table format
    run('print_utils.m');
    
    % Print module header
    print_step_header('S14', 'SATURATION DISTRIBUTION');
    
    output_data = struct();
    
    try
        %% 1. Load Configuration and Previous Results
        fprintf('📋 Loading configuration and previous results...\n');
        
        % Load YAML configurations
        init_config = read_yaml_config('config/initialization_config.yaml', 'silent', true);
        scal_config = read_yaml_config('config/scal_properties_config.yaml', 'silent', true);
        fprintf('   ✅ Configurations loaded successfully\n');
        
        % Load pressure field from s13
        if exist('data/mrst_simulation/static/grid_with_pressure.mat', 'file')
            fprintf('   ✅ Loading pressure field from s13\n');
            load('data/mrst_simulation/static/grid_with_pressure.mat', 'G_with_pressure', 'state');
            G = G_with_pressure;
        else
            error('Pressure field not found. Run s13_pressure_initialization.m first');
        end
        
        % Load capillary pressure functions from s11
        if exist('data/mrst_simulation/static/fluid_with_capillary_pressure.mat', 'file')
            fprintf('   ✅ Loading capillary pressure functions from s11\n');
            load('data/mrst_simulation/static/fluid_with_capillary_pressure.mat', 'fluid_with_pc');
        else
            error('Capillary pressure functions not found. Run s11_capillary_pressure.m first');
        end
        
        % Load rock properties with types
        if exist('data/mrst_simulation/static/grid_with_rock_properties.mat', 'file')
            fprintf('   ✅ Loading rock properties from s08\n');
            load('data/mrst_simulation/static/grid_with_rock_properties.mat', 'rock', 'rock_types');
        else
            error('Rock properties not found. Run s08_assign_layer_properties.m first');
        end
        
        %% 2. Extract Saturation Initialization Parameters
        fprintf('⚙️  Extracting saturation initialization parameters...\n');
        
        % Fluid contact depths
        owc_depth = init_config.saturation_initialization.owc_depth_ft;  % 8150 ft TVDSS
        transition_zone_top = owc_depth - init_config.saturation_initialization.transition_zone_ft/2; % 8100 ft
        transition_zone_bottom = owc_depth + init_config.saturation_initialization.transition_zone_ft/2; % 8200 ft
        
        % Initial saturations above OWC
        initial_sw = init_config.saturation_initialization.initial_water_saturation; % 0.20
        initial_so = init_config.saturation_initialization.initial_oil_saturation;   % 0.80
        initial_sg = init_config.saturation_initialization.initial_gas_saturation;   % 0.00
        
        % Critical saturations by rock type from SCAL config
        swi_by_type = []; sor_by_type = []; sgr_by_type = [];
        pc_params = struct();
        
        rock_type_names = fieldnames(scal_config.rock_types);
        for i = 1:length(rock_type_names)
            type_name = rock_type_names{i};
            type_data = scal_config.rock_types.(type_name);
            
            swi_by_type(i) = type_data.saturation_endpoints.swi;
            sor_by_type(i) = type_data.saturation_endpoints.sor; 
            sgr_by_type(i) = type_data.saturation_endpoints.sgr;
            
            % Brooks-Corey capillary pressure parameters
            pc_params.(type_name) = struct();
            pc_params.(type_name).entry_pressure = type_data.capillary_pressure.entry_pressure_psi;
            pc_params.(type_name).lambda = type_data.capillary_pressure.brooks_corey_lambda;
            pc_params.(type_name).max_pc = type_data.capillary_pressure.max_capillary_pressure_psi;
        end
        
        fprintf('   📊 OWC depth: %.0f ft TVDSS\n', owc_depth);
        fprintf('   📊 Transition zone: %.0f - %.0f ft TVDSS\n', transition_zone_top, transition_zone_bottom);
        fprintf('   📊 Initial saturations: Sw=%.2f, So=%.2f, Sg=%.2f\n', initial_sw, initial_so, initial_sg);
        
        %% 3. Calculate Grid Cell Heights Above OWC
        fprintf('📏 Calculating height above OWC for each cell...\n');
        
        % Get cell centers and depths (from pressure initialization)
        cell_centers = G.cells.centroids;
        cell_depths = cell_centers(:, 3);
        
        % Convert to feet using MRST native function (consistent with s13)
        cell_depths = convertTo(abs(cell_depths), ft);
        
        % Calculate height above OWC (negative below OWC)
        height_above_owc = owc_depth - cell_depths;
        
        fprintf('   📊 Height range above OWC: %.1f to %.1f ft\n', min(height_above_owc), max(height_above_owc));
        fprintf('   📊 Cells above OWC: %d/%d\n', sum(height_above_owc > 0), length(height_above_owc));
        
        %% 4. Initialize 3-Phase Saturations
        fprintf('💧 Calculating 3-phase saturation distribution...\n');
        
        num_cells = G.cells.num;
        sw = zeros(num_cells, 1);
        so = zeros(num_cells, 1);
        sg = zeros(num_cells, 1);
        
        % Process each cell based on rock type and height above OWC
        for i = 1:num_cells
            cell_rock_type = rock_types(i);  % Rock type index (1-6)
            height = height_above_owc(i);
            
            if height > 50  % Well above transition zone (oil zone)
                % Use initial saturations from YAML with rock type adjustments
                sw(i) = max(swi_by_type(cell_rock_type), min(initial_sw * 1.25, initial_sw)); 
                so(i) = 1.0 - sw(i);  % No free gas initially
                sg(i) = 0.0;
                
            elseif height < -50  % Well below transition zone (water zone)
                % Pure water zone
                sw(i) = 1.0;
                so(i) = 0.0;
                sg(i) = 0.0;
                
            else  % Transition zone (-50 ft to +50 ft around OWC)
                % Use capillary pressure-based saturation distribution
                type_name = rock_type_names{cell_rock_type};
                entry_pc = pc_params.(type_name).entry_pressure;
                lambda = pc_params.(type_name).lambda;
                max_pc = pc_params.(type_name).max_pc;
                
                % Calculate capillary pressure from height using fluid properties
                % Load water and oil densities from completed fluid model  
                water_density_lbft3 = fluid_with_pc.rhoWS;  % From s12 PVT data
                oil_density_lbft3 = fluid_with_pc.rhoOS;    % From s12 PVT data
                oil_water_density_diff = water_density_lbft3 - oil_density_lbft3;  % lb/ft³
                pc_height = abs(height) * oil_water_density_diff / 144;  % Convert to psi
                pc = max(0, min(max_pc, pc_height));
                
                if height > 0  % Above OWC in transition zone
                    % Brooks-Corey saturation function
                    if pc > entry_pc
                        sw_norm = (entry_pc / pc)^lambda;
                        sw(i) = swi_by_type(cell_rock_type) + sw_norm * (1 - swi_by_type(cell_rock_type) - sor_by_type(cell_rock_type));
                        % Clamp using SCAL endpoints instead of hard-coded values
                        max_sw_transition = 1.0 - sor_by_type(cell_rock_type);
                        sw(i) = max(swi_by_type(cell_rock_type), min(max_sw_transition, sw(i)));
                    else
                        sw(i) = swi_by_type(cell_rock_type);
                    end
                    so(i) = 1.0 - sw(i);
                    sg(i) = 0.0;
                    
                else  % Below OWC in transition zone
                    % Increasing water saturation with depth below OWC
                    depth_factor = abs(height) / 50;  % Normalize to 0-1 over 50 ft
                    sw(i) = 0.6 + 0.4 * depth_factor;  % Range from 60% to 100%
                    sw(i) = min(1.0, sw(i));
                    so(i) = max(0.0, 1.0 - sw(i));
                    sg(i) = 0.0;
                end
            end
        end
        
        % Ensure saturation constraints
        for i = 1:num_cells
            % Normalize to ensure sum = 1.0
            total_sat = sw(i) + so(i) + sg(i);
            if total_sat > 1.001 || total_sat < 0.999  % Allow small numerical tolerance
                sw(i) = sw(i) / total_sat;
                so(i) = so(i) / total_sat;
                sg(i) = sg(i) / total_sat;
            end
        end
        
        fprintf('   📊 Water saturation range: %.3f - %.3f\n', min(sw), max(sw));
        fprintf('   📊 Oil saturation range: %.3f - %.3f\n', min(so), max(so));
        fprintf('   📊 Gas saturation range: %.3f - %.3f\n', min(sg), max(sg));
        
        %% 5. Validate Saturation Distribution
        fprintf('✅ Validating saturation distribution...\n');
        
        validation_passed = true;
        
        % Check physical bounds (0 ≤ S ≤ 1)
        if any(sw < -0.001) || any(sw > 1.001) || any(so < -0.001) || any(so > 1.001) || any(sg < -0.001) || any(sg > 1.001)
            fprintf('   ⚠️  Warning: Saturations outside physical bounds [0,1]\n');
            validation_passed = false;
        end
        
        % Check saturation sum = 1.0
        sat_sum = sw + so + sg;
        sum_error = max(abs(sat_sum - 1.0));
        if sum_error > 0.01
            fprintf('   ⚠️  Warning: Maximum saturation sum error: %.4f\n', sum_error);
            validation_passed = false;
        end
        
        % Check oil zone saturations using YAML initial values as reference
        oil_zone_cells = height_above_owc > transition_zone_thickness/2;  % Well above OWC
        if sum(oil_zone_cells) > 0
            avg_sw_oil_zone = mean(sw(oil_zone_cells));
            avg_so_oil_zone = mean(so(oil_zone_cells));
            
            % Use YAML initial values for validation ranges (±25% tolerance)
            sw_min = initial_sw * 0.75;
            sw_max = initial_sw * 1.25;
            so_min = initial_so * 0.85;
            so_max = initial_so * 1.05;
            
            if avg_sw_oil_zone < sw_min || avg_sw_oil_zone > sw_max
                fprintf('   ⚠️  Warning: Oil zone water saturation (%.3f) outside expected range [%.3f-%.3f]\n', ...
                        avg_sw_oil_zone, sw_min, sw_max);
                validation_passed = false;
            end
            
            if avg_so_oil_zone < so_min || avg_so_oil_zone > so_max
                fprintf('   ⚠️  Warning: Oil zone oil saturation (%.3f) outside expected range [%.3f-%.3f]\n', ...
                        avg_so_oil_zone, so_min, so_max);
                validation_passed = false;
            end
        end
        
        % Check water zone saturations
        water_zone_cells = height_above_owc < -transition_zone_thickness/2;  % Well below OWC
        if sum(water_zone_cells) > 0
            avg_sw_water_zone = mean(sw(water_zone_cells));
            if avg_sw_water_zone < 0.90  % Physical requirement for water zone
                fprintf('   ⚠️  Warning: Water zone water saturation (%.3f) too low\n', avg_sw_water_zone);
                validation_passed = false;
            end
        end
        
        if validation_passed
            fprintf('   ✅ Saturation validation PASSED\n');
        else
            fprintf('   ⚠️  Saturation validation completed with warnings\n');
        end
        
        %% 6. Create MRST State with Saturations
        fprintf('💾 Creating MRST state with saturations...\n');
        
        % Add saturations to existing state
        state.s = [sw, so, sg];  % MRST expects [water, oil, gas] order
        
        % Store individual phase saturations for clarity
        state.sw = sw;
        state.so = so; 
        state.sg = sg;
        
        %% 7. Store Results and Analysis
        fprintf('📊 Analyzing saturation distribution...\n');
        
        % Create saturation statistics
        sat_stats = struct();
        sat_stats.water = struct('min', min(sw), 'max', max(sw), 'mean', mean(sw), 'std', std(sw));
        sat_stats.oil = struct('min', min(so), 'max', max(so), 'mean', mean(so), 'std', std(so));
        sat_stats.gas = struct('min', min(sg), 'max', max(sg), 'mean', mean(sg), 'std', std(sg));
        
        % Saturation by zone analysis
        oil_zone_mask = height_above_owc > 10;
        transition_zone_mask = abs(height_above_owc) <= 10;
        water_zone_mask = height_above_owc < -10;
        
        sat_by_zone = struct();
        if sum(oil_zone_mask) > 0
            sat_by_zone.oil_zone = struct('sw_mean', mean(sw(oil_zone_mask)), ...
                                         'so_mean', mean(so(oil_zone_mask)), ...
                                         'count', sum(oil_zone_mask));
        end
        
        if sum(transition_zone_mask) > 0
            sat_by_zone.transition_zone = struct('sw_mean', mean(sw(transition_zone_mask)), ...
                                                'so_mean', mean(so(transition_zone_mask)), ...
                                                'count', sum(transition_zone_mask));
        end
        
        if sum(water_zone_mask) > 0
            sat_by_zone.water_zone = struct('sw_mean', mean(sw(water_zone_mask)), ...
                                           'so_mean', mean(so(water_zone_mask)), ...
                                           'count', sum(water_zone_mask));
        end
        
        %% 8. Export Results
        fprintf('📁 Exporting saturation distribution data...\n');
        
        % Ensure output directory exists
        output_dir = 'data/mrst_simulation/static';
        if ~exist(output_dir, 'dir')
            mkdir(output_dir);
        end
        
        % Save saturation field and analysis
        save(fullfile(output_dir, 'saturation_distribution.mat'), ...
             'sw', 'so', 'sg', 'sat_stats', 'sat_by_zone', 'state', ...
             'height_above_owc', 'owc_depth', 'pc_params');
        
        % Save combined grid with pressure and saturations for next phase
        G_with_pressure_sat = G;
        save(fullfile(output_dir, 'grid_with_pressure_saturation.mat'), ...
             'G_with_pressure_sat', 'state', 'rock', 'rock_types');
        
        %% 9. Create Output Summary
        output_data.saturations = struct('sw', sw, 'so', so, 'sg', sg);
        output_data.sat_stats = sat_stats;
        output_data.sat_by_zone = sat_by_zone;
        output_data.validation_passed = validation_passed;
        output_data.height_above_owc = height_above_owc;
        output_data.state = state;
        output_data.owc_depth = owc_depth;
        output_data.num_cells = num_cells;
        
        % Success message
        print_step_footer('S14', 'Saturation distribution completed successfully', toc);
        
    catch ME
        print_step_footer('S14', sprintf('FAILED: %s', ME.message), toc);
        rethrow(ME);
    end
    
end