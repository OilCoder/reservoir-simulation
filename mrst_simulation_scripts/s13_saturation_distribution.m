function output_data = s13_saturation_distribution()
% S13_SATURATION_DISTRIBUTION - MRST saturation initialization with capillary-gravity equilibrium
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
    script_dir = fileparts(mfilename('fullpath'));
    addpath(fullfile(script_dir, 'utils')); 
    run(fullfile(script_dir, 'utils', 'print_utils.m'));

    % Add MRST session validation
    [success, message] = validate_mrst_session(script_dir);
    if ~success
        error('MRST validation failed: %s', message);
    end
    
    % Print module header
    print_step_header('S13', 'SATURATION DISTRIBUTION');
    
    % Start timer
    start_time = tic;
    output_data = struct();
    
    try
        %% 1. Load Configuration and Previous Results
        fprintf('📋 Loading configuration and previous results...\n');
        
        % Load YAML configurations
        addpath(fullfile(script_dir, 'utils'));
        init_config = read_yaml_config('config/initialization_config.yaml', true);
        addpath(fullfile(script_dir, 'utils'));
        scal_config = read_yaml_config('config/scal_properties_config.yaml', true);
        fprintf('   ✅ Configurations loaded successfully\n');
        
        % Use same path construction as other working phases
        script_path = fileparts(mfilename('fullpath'));
        if isempty(script_path)
            script_path = pwd();
        end
        addpath(fullfile(script_dir, 'utils'));
        data_dir = get_data_path('static');
        
        % Load pressure field from s12 (CANON-FIRST with correct path)
        % Use canonical data organization pattern
        base_data_path = fullfile(fileparts(fileparts(mfilename('fullpath'))), 'data');
        canonical_data_dir = fullfile(base_data_path, 'by_type', 'static');
        pressure_file = fullfile(canonical_data_dir, 'grid_with_pressure_s12.mat');
        if exist(pressure_file, 'file')
            fprintf('   ✅ Loading pressure field from s12\n');
            load(pressure_file, 'G_with_pressure', 'state');
            G = G_with_pressure;
        else
            error(['CANON-FIRST ERROR: Pressure field not found at canonical location.\n' ...
                   'REQUIRED: Run s12_pressure_initialization.m first.\n' ...
                   'Expected file: %s'], pressure_file);
        end
        
        % Load capillary pressure functions from s10 (CANON-FIRST with correct path)
        % Use same canonical data organization pattern as pressure file
        capillary_file = fullfile(canonical_data_dir, 'fluid_capillary_s10.mat');
        if exist(capillary_file, 'file')
            fprintf('   ✅ Loading capillary pressure functions from s10\n');
            load(capillary_file, 'fluid_with_pc');
        else
            error('Capillary pressure functions not found. Run s10_capillary_pressure.m first');
        end
        
        % Load rock properties with types
        % Use legacy path for rock properties (until S08 is updated to canonical)
        legacy_data_dir = fullfile(fileparts(script_path), 'data', 'simulation_data', 'static');
        rock_file = fullfile(legacy_data_dir, 'enhanced_rock.mat');
        if exist(rock_file, 'file')
            fprintf('   ✅ Loading enhanced rock properties from s07\n');
            load(rock_file, 'enhanced_rock', 'G');
            rock = enhanced_rock;
            % Validate required rock type assignments (FAIL_FAST)
            if ~isfield(rock, 'meta') || ~isfield(rock.meta, 'rock_type_assignments')
                error('Missing rock_type_assignments in enhanced_rock. Check s07_add_layer_metadata.m output.');
            end
            rock_types = rock.meta.rock_type_assignments;
        else
            error(['CANON-FIRST ERROR: Rock properties not found at legacy location.\n' ...
                   'REQUIRED: Run s08_assign_layer_properties.m first.\n' ...
                   'Expected file: %s'], rock_file);
        end
        
        %% 2. Extract Configuration-Driven Parameters
        fprintf('⚙️  Extracting saturation initialization parameters...\n');
        
        % CANON-FIRST: Extract saturation parameters from YAML configurations
        if ~isfield(init_config, 'initialization')
            error(['CANON-FIRST ERROR: Missing initialization section in initialization_config.yaml\n' ...
                   'UPDATE CANON: obsidian-vault/Planning/Initial_Conditions.md\n' ...
                   'Must define complete initialization parameters for Eagle West Field.']);
        end
        
        init_params = init_config.initialization;
        
        % Fluid contacts (CANON-FIRST)
        if ~isfield(init_params, 'fluid_contacts') || ~isfield(init_params.fluid_contacts, 'oil_water_contact')
            error(['CANON-FIRST ERROR: Missing oil_water_contact in initialization_config.yaml\n' ...
                   'UPDATE CANON: obsidian-vault/Planning/Initial_Conditions.md\n' ...
                   'Must define exact OWC depth for Eagle West Field.']);
        end
        
        owc_config = init_params.fluid_contacts.oil_water_contact;
        owc_depth = owc_config.depth_ft_tvdss;
        
        if ~isfield(init_params.fluid_contacts, 'transition_zones') || ~isfield(init_params.fluid_contacts.transition_zones, 'oil_water_transition')
            error(['CANON-FIRST ERROR: Missing transition zone configuration in initialization_config.yaml\n' ...
                   'UPDATE CANON: obsidian-vault/Planning/Initial_Conditions.md\n' ...
                   'Must define exact transition zone for Eagle West Field.']);
        end
        
        transition_config = init_params.fluid_contacts.transition_zones.oil_water_transition;
        transition_zone_top = transition_config.top_ft_tvdss;
        transition_zone_bottom = transition_config.bottom_ft_tvdss;
        transition_zone_thickness = transition_config.thickness_ft;
        
        % Initial saturations above OWC (CANON-FIRST)
        if ~isfield(init_params, 'initial_saturations') || ~isfield(init_params.initial_saturations, 'oil_zone')
            error(['CANON-FIRST ERROR: Missing oil_zone saturations in initialization_config.yaml\n' ...
                   'UPDATE CANON: obsidian-vault/Planning/Initial_Conditions.md\n' ...
                   'Must define exact initial saturations for Eagle West Field.']);
        end
        
        oil_zone_config = init_params.initial_saturations.oil_zone;
        initial_so = mean(oil_zone_config.oil_saturation_range);  % Use mean of range
        initial_sw = mean(oil_zone_config.water_saturation_range);  % Use mean of range
        initial_sg = oil_zone_config.gas_saturation;
        
        % SCAL properties by rock type (CANON-FIRST)
        if ~isfield(scal_config, 'scal_properties')
            error(['CANON-FIRST ERROR: Missing scal_properties section in scal_properties_config.yaml\n' ...
                   'UPDATE CANON: obsidian-vault/Planning/SCAL_Properties.md\n' ...
                   'Must define complete SCAL properties for Eagle West Field.']);
        end
        
        scal_props = scal_config.scal_properties;
        
        % Extract SCAL parameters for different lithologies
        if ~isfield(scal_props, 'sandstone_ow') || ~isfield(scal_props, 'shale_ow')
            error(['CANON-FIRST ERROR: Missing lithology SCAL parameters in scal_properties_config.yaml\n' ...
                   'UPDATE CANON: obsidian-vault/Planning/SCAL_Properties.md\n' ...
                   'Must define sandstone and shale SCAL properties for Eagle West Field.']);
        end
        
        % Rock type properties from SCAL data (6 rock types based on workflow)
        % Map to appropriate lithology parameters
        sandstone_ow = scal_props.sandstone_ow;
        shale_ow = scal_props.shale_ow;
        
        % Create arrays for 6 rock types (mix of sandstone and shale characteristics)
        swi_by_type = zeros(1, 6);
        sor_by_type = zeros(1, 6);
        sgr_by_type = zeros(1, 6);
        
        % Assign properties based on typical Eagle West rock type distribution
        for i = 1:6
            if i <= 4  % First 4 types: sandstone-dominated
                swi_by_type(i) = sandstone_ow.connate_water_saturation + (i-1) * 0.01;  % Slight variation
                sor_by_type(i) = sandstone_ow.residual_oil_saturation + (i-1) * 0.01;
                if isfield(scal_props, 'sandstone_go')
                    sgr_by_type(i) = scal_props.sandstone_go.critical_gas_saturation;
                else
                    sgr_by_type(i) = 0.05;  % Default for sandstone
                end
            else  % Last 2 types: shale-influenced
                swi_by_type(i) = shale_ow.connate_water_saturation - (i-5) * 0.02;  % Slightly lower
                sor_by_type(i) = shale_ow.residual_oil_saturation - (i-5) * 0.02;
                if isfield(scal_props, 'shale_go')
                    sgr_by_type(i) = scal_props.shale_go.critical_gas_saturation;
                else
                    sgr_by_type(i) = 0.08;  % Default for shale
                end
            end
        end
        
        % Capillary pressure parameters by rock type (CANON-FIRST)
        if ~isfield(scal_props, 'sandstone_pc') || ~isfield(scal_props, 'shale_pc')
            error(['CANON-FIRST ERROR: Missing capillary pressure parameters in scal_properties_config.yaml\n' ...
                   'UPDATE CANON: obsidian-vault/Planning/SCAL_Properties.md\n' ...
                   'Must define capillary pressure properties for Eagle West Field.']);
        end
        
        sandstone_pc = scal_props.sandstone_pc;
        shale_pc = scal_props.shale_pc;
        
        % Create capillary pressure parameters for 6 rock types
        rock_type_names = {'RT1', 'RT2', 'RT3', 'RT4', 'RT5', 'RT6'};
        pc_params = struct();
        
        for i = 1:6
            type_name = rock_type_names{i};
            pc_params.(type_name) = struct();
            
            if i <= 4  % Sandstone-dominated types
                pc_params.(type_name).entry_pressure = sandstone_pc.entry_pressure_ow + (i-1) * 0.1;
                pc_params.(type_name).lambda = sandstone_pc.brooks_corey_lambda;
                pc_params.(type_name).max_pc = sandstone_pc.maximum_pc_ow;
            else  % Shale-influenced types
                pc_params.(type_name).entry_pressure = shale_pc.entry_pressure_ow + (i-5) * 0.2;
                pc_params.(type_name).lambda = shale_pc.brooks_corey_lambda;
                pc_params.(type_name).max_pc = shale_pc.maximum_pc_ow;
            end
        end
        
        fprintf('   📊 OWC depth: %.0f ft TVDSS\n', owc_depth);
        fprintf('   📊 Transition zone: %.0f - %.0f ft TVDSS\n', transition_zone_top, transition_zone_bottom);
        fprintf('   📊 Initial saturations: Sw=%.2f, So=%.2f, Sg=%.2f\n', initial_sw, initial_so, initial_sg);
        
        %% 3. Calculate Grid Cell Heights Above OWC
        fprintf('📏 Calculating height above OWC for each cell...\n');
        
        % Get cell centers and depths (from pressure initialization)
        cell_centers = G.cells.centroids;
        cell_depths = cell_centers(:, 3);
        
        % Convert to feet using CANON unit conversion factor
        if ~isfield(init_params, 'unit_conversions') || ~isfield(init_params.unit_conversions.length, 'm_to_ft')
            error(['CANON-FIRST ERROR: Missing m_to_ft conversion factor in initialization_config.yaml\n' ...
                   'UPDATE CANON: obsidian-vault/Planning/Initial_Conditions.md\n' ...
                   'Must define exact unit conversion factors for Eagle West Field.']);
        end
        m_to_ft = init_params.unit_conversions.length.m_to_ft;
        cell_depths = abs(cell_depths) * m_to_ft;
        
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
        saturation_file = fullfile(static_path, 'saturation_distribution_s13.mat');
        save(saturation_file, 'sw', 'so', 'sg', 'sat_stats', 'sat_by_zone', 'state', ...
             'height_above_owc', 'owc_depth', 'pc_params');
        fprintf('     Canonical data saved: %s\n', saturation_file);
        
        % Save combined grid with pressure and saturations for next phase (backward compatibility)
        G_with_pressure_sat = G;
        save(fullfile(output_dir, 'grid_with_pressure_saturation.mat'), ...
             'G_with_pressure_sat', 'state', 'rock', 'rock_types');
        
        % Also save in canonical location
        save(fullfile(static_path, 'grid_with_pressure_saturation_s13.mat'), ...
             'G_with_pressure_sat', 'state', 'rock', 'rock_types');
        fprintf('     Grid with pressure/saturations saved: %s\n', fullfile(static_path, 'grid_with_pressure_saturation_s13.mat'));
        
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
        print_step_footer('S13', 'Saturation distribution completed successfully', toc(start_time));
        
    catch ME
        print_step_footer('S13', sprintf('FAILED: %s', ME.message), toc(start_time));
        rethrow(ME);
    end
    
end