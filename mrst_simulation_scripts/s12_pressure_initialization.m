function output_data = s12_pressure_initialization()
% S12_PRESSURE_INITIALIZATION - MRST pressure initialization with hydrostatic equilibrium
%
% DESCRIPTION:
%   Implements hydrostatic pressure distribution across the Eagle West Field
%   with phase-specific gradients and compartment variations. Sets up initial
%   pressure conditions for 3-phase reservoir simulation.
%
% DEPENDENCIES:
%   - S03: PEBI grid (pebi_grid_s03.mat)
%   - initialization_config.yaml: Pressure parameters
%
% CANON REFERENCE: 
%   [[07_Initialization]] - Pressure initialization section
%   - Datum: 3600 psi @ 8000 ft TVDSS
%   - Oil gradient: 0.350 psi/ft
%   - Water gradient: 0.433 psi/ft  
%   - Gas gradient: 0.076 psi/ft
%   - Compartment variations: ±10 psi
%   - OWC: 8150 ft TVDSS
%
% WORKFLOW:
%   1. Load PEBI grid from s03 and initialization configuration
%   2. Calculate depth-dependent pressure distribution
%   3. Apply phase-specific gradients above/below contacts
%   4. Add compartment-specific pressure variations
%   5. Validate pressure ranges (3500-3750 psi)
%   6. Export pressure field for simulation
%
% RETURNS:
%   output_data - Structure with pressure initialization results
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
    print_step_header('S12', 'PRESSURE INITIALIZATION');
    
    % Start timer
    start_time = tic;
    output_data = struct();
    
    try
        %% 1. Load Configuration and Previous Results
        fprintf('📋 Loading configuration and grid data...\n');
        
        % Load YAML configurations
        addpath(fullfile(script_dir, 'utils'));
        init_config = read_yaml_config('config/initialization_config.yaml', true);
        
        % Load from new canonical MRST data structure
        base_data_path = fullfile(fileparts(fileparts(mfilename('fullpath'))), 'data');
        canonical_mrst_dir = fullfile(base_data_path, 'mrst');
        
        % Load grid from canonical MRST structure
        grid_file = fullfile(canonical_mrst_dir, 'grid.mat');
        
        if ~exist(grid_file, 'file')
            error(['Missing canonical grid file: grid.mat\n' ...
                   'UPDATE CANON: obsidian-vault/Planning/Data_Pipeline.md\n' ...
                   'Previous scripts must generate grid.mat file in canonical location:\n' ...
                   '%s'], grid_file);
        end
        
        % Load grid from canonical MRST structure
        grid_data = load(grid_file, 'data_struct'); 
        G = grid_data.data_struct.G;
        fprintf('   ✅ Loading grid from canonical MRST structure\n');
        
        % Load rock properties (if available)
        rock_file = fullfile(canonical_mrst_dir, 'rock.mat');
        if exist(rock_file, 'file')
            rock_data = load(rock_file, 'data_struct');
            rock = struct('perm', rock_data.data_struct.perm, 'poro', rock_data.data_struct.poro);
            fprintf('   ✅ Loading rock properties from canonical MRST structure\n');
        end
        
        % Load fluid properties (if available) 
        fluid_file = fullfile(canonical_mrst_dir, 'fluid.mat');
        if exist(fluid_file, 'file')
            fluid_data = load(fluid_file, 'data_struct');
            fluid = fluid_data.data_struct.model;
            fprintf('   ✅ Loading fluid properties from canonical MRST structure\n');
        end
        
        %% 2. Extract Pressure Initialization Parameters
        fprintf('⚙️  Extracting pressure initialization parameters...\n');
        
        % CANON-FIRST: Extract pressure parameters from YAML configuration
        if ~isfield(init_config, 'initialization')
            error(['CANON-FIRST ERROR: Missing initialization section in initialization_config.yaml\n' ...
                   'UPDATE CANON: obsidian-vault/Planning/Initial_Conditions.md\n' ...
                   'Must define complete initialization parameters for Eagle West Field.']);
        end
        
        init_params = init_config.initialization;
        
        % Datum and reference conditions (CANON-FIRST)
        if ~isfield(init_params, 'equilibration_method') || ~isfield(init_params.equilibration_method, 'datum_depth_ft_tvdss')
            error(['CANON-FIRST ERROR: Missing datum_depth_ft_tvdss in initialization_config.yaml\n' ...
                   'UPDATE CANON: obsidian-vault/Planning/Initial_Conditions.md\n' ...
                   'Must define exact datum depth for Eagle West Field.']);
        end
        datum_depth = init_params.equilibration_method.datum_depth_ft_tvdss;
        
        if ~isfield(init_params, 'initial_conditions') || ~isfield(init_params.initial_conditions, 'initial_pressure_psi')
            error(['CANON-FIRST ERROR: Missing initial_pressure_psi in initialization_config.yaml\n' ...
                   'UPDATE CANON: obsidian-vault/Planning/Initial_Conditions.md\n' ...
                   'Must define exact datum pressure for Eagle West Field.']);
        end
        datum_pressure = init_params.initial_conditions.initial_pressure_psi;
        
        % Phase-specific gradients (CANON-FIRST)
        if ~isfield(init_params, 'pressure_gradients')
            error(['CANON-FIRST ERROR: Missing pressure_gradients in initialization_config.yaml\n' ...
                   'UPDATE CANON: obsidian-vault/Planning/Initial_Conditions.md\n' ...
                   'Must define exact pressure gradients for Eagle West Field.']);
        end
        
        gradients = init_params.pressure_gradients;
        if ~isfield(gradients, 'oil_gradient_psi_ft')
            error(['CANON-FIRST ERROR: Missing oil_gradient_psi_ft in initialization_config.yaml\n' ...
                   'UPDATE CANON: obsidian-vault/Planning/Initial_Conditions.md\n' ...
                   'Must define exact oil gradient for Eagle West Field.']);
        end
        oil_gradient = gradients.oil_gradient_psi_ft;
        
        if ~isfield(gradients, 'water_gradient_psi_ft')
            error(['CANON-FIRST ERROR: Missing water_gradient_psi_ft in initialization_config.yaml\n' ...
                   'UPDATE CANON: obsidian-vault/Planning/Initial_Conditions.md\n' ...
                   'Must define exact water gradient for Eagle West Field.']);
        end
        water_gradient = gradients.water_gradient_psi_ft;
        
        if ~isfield(gradients, 'gas_gradient_psi_ft')
            error(['CANON-FIRST ERROR: Missing gas_gradient_psi_ft in initialization_config.yaml\n' ...
                   'UPDATE CANON: obsidian-vault/Planning/Initial_Conditions.md\n' ...
                   'Must define exact gas gradient for Eagle West Field.']);
        end
        gas_gradient = gradients.gas_gradient_psi_ft;
        
        % Fluid contacts (CANON-FIRST)
        if ~isfield(init_params, 'fluid_contacts') || ~isfield(init_params.fluid_contacts, 'oil_water_contact')
            error(['CANON-FIRST ERROR: Missing oil_water_contact in initialization_config.yaml\n' ...
                   'UPDATE CANON: obsidian-vault/Planning/Initial_Conditions.md\n' ...
                   'Must define exact OWC depth for Eagle West Field.']);
        end
        
        owc_config = init_params.fluid_contacts.oil_water_contact;
        if ~isfield(owc_config, 'depth_ft_tvdss')
            error(['CANON-FIRST ERROR: Missing depth_ft_tvdss in oil_water_contact configuration\n' ...
                   'UPDATE CANON: obsidian-vault/Planning/Initial_Conditions.md\n' ...
                   'Must define exact OWC depth for Eagle West Field.']);
        end
        owc_depth = owc_config.depth_ft_tvdss;
        
        if ~isfield(init_params.fluid_contacts, 'transition_zones') || ~isfield(init_params.fluid_contacts.transition_zones, 'oil_water_transition')
            error(['CANON-FIRST ERROR: Missing transition zone configuration in initialization_config.yaml\n' ...
                   'UPDATE CANON: obsidian-vault/Planning/Initial_Conditions.md\n' ...
                   'Must define exact transition zone thickness for Eagle West Field.']);
        end
        transition_zone_thickness = init_params.fluid_contacts.transition_zones.oil_water_transition.thickness_ft;
        
        % Compartment pressure variations (CANON-FIRST)
        if ~isfield(init_params, 'compartmentalization')
            error(['CANON-FIRST ERROR: Missing compartmentalization in initialization_config.yaml\n' ...
                   'UPDATE CANON: obsidian-vault/Planning/Initial_Conditions.md\n' ...
                   'Must define exact compartment pressures for Eagle West Field.']);
        end
        
        compartment_config = init_params.compartmentalization;
        
        if ~isfield(compartment_config, 'northern_compartment') || ~isfield(compartment_config.northern_compartment, 'pressure_datum_psi')
            error(['CANON-FIRST ERROR: Missing northern compartment pressure in initialization_config.yaml\n' ...
                   'UPDATE CANON: obsidian-vault/Planning/Initial_Conditions.md\n' ...
                   'Must define exact northern compartment pressure for Eagle West Field.']);
        end
        northern_pressure_datum = compartment_config.northern_compartment.pressure_datum_psi;
        northern_variation = compartment_config.northern_compartment.pressure_variation_psi;
        
        if ~isfield(compartment_config, 'southern_compartment') || ~isfield(compartment_config.southern_compartment, 'pressure_datum_psi')
            error(['CANON-FIRST ERROR: Missing southern compartment pressure in initialization_config.yaml\n' ...
                   'UPDATE CANON: obsidian-vault/Planning/Initial_Conditions.md\n' ...
                   'Must define exact southern compartment pressure for Eagle West Field.']);
        end
        southern_pressure_datum = compartment_config.southern_compartment.pressure_datum_psi;
        southern_variation = compartment_config.southern_compartment.pressure_variation_psi;
        
        % Additional compartment variations (CANON-FIRST)
        if ~isfield(compartment_config, 'additional_variations')
            error(['CANON-FIRST ERROR: Missing additional_variations in compartmentalization\n' ...
                   'UPDATE CANON: obsidian-vault/Planning/Initial_Conditions.md\n' ...
                   'Must define exact additional pressure variations for Eagle West Field.']);
        end
        
        additional_vars = compartment_config.additional_variations;
        eastern_variation = additional_vars.eastern_fault_block_psi;
        western_variation = additional_vars.western_fault_block_psi;
        
        % Create compartment variations structure (CANON-FIRST)
        compartment_variations = struct();
        compartment_variations.northern_psi = northern_pressure_datum - datum_pressure;
        compartment_variations.southern_psi = southern_pressure_datum - datum_pressure;
        compartment_variations.eastern_psi = eastern_variation;
        compartment_variations.western_psi = western_variation;
        
        fprintf('   📊 Datum: %.0f psi @ %.0f ft TVDSS\n', datum_pressure, datum_depth);
        fprintf('   📊 Oil gradient: %.3f psi/ft\n', oil_gradient);
        fprintf('   📊 Water gradient: %.3f psi/ft\n', water_gradient);
        fprintf('   📊 OWC depth: %.0f ft TVDSS\n', owc_depth);
        
        %% 3. Calculate Grid Cell Depths
        fprintf('🗺️  Calculating grid cell depths...\n');
        
        % Get cell centers (coordinates already in feet from s03)
        cell_centers = G.cells.centroids;
        cell_depths_ft = cell_centers(:, 3);  % Z-coordinate already in feet from s03
        
        % CRITICAL FIX: Grid coordinates from s03 are already in feet (-8240 to -7900 ft)
        % No unit conversion needed - just take absolute value for depth
        cell_depths = abs(cell_depths_ft);  % Convert from negative feet to positive feet depth
        
        fprintf('   📊 Z-coordinate range: %.0f to %.0f ft (negative subsurface)\n', min(cell_depths_ft), max(cell_depths_ft));
        fprintf('   📊 Depth range: %.0f - %.0f ft\n', min(cell_depths), max(cell_depths));
        fprintf('   📊 Average depth: %.0f ft\n', mean(cell_depths));
        
        %% 4. Initialize Pressure Field
        fprintf('💧 Calculating hydrostatic pressure distribution...\n');
        
        num_cells = G.cells.num;
        pressure = zeros(num_cells, 1);
        
        % Calculate pressure for each cell based on depth relative to datum
        for i = 1:num_cells
            depth = cell_depths(i);
            depth_diff = depth - datum_depth;  % Positive if below datum
            
            if depth <= owc_depth
                % Oil zone: use oil gradient
                pressure(i) = datum_pressure + oil_gradient * depth_diff;
            else
                % Water zone: calculate pressure at OWC first, then water gradient
                owc_pressure = datum_pressure + oil_gradient * (owc_depth - datum_depth);
                water_depth_diff = depth - owc_depth;
                pressure(i) = owc_pressure + water_gradient * water_depth_diff;
            end
        end
        
        fprintf('   📊 Pressure range: %.0f - %.0f psi\n', min(pressure), max(pressure));
        fprintf('   📊 Average pressure: %.0f psi\n', mean(pressure));
        
        %% 4.5. Validate Hydrostatic Gradient (Before Compartmentalization)
        fprintf('✅ Validating hydrostatic pressure gradient...\n');
        validation_passed = true;
        
        % Find oil zone cells (above OWC)
        oil_zone_cells = find(cell_depths <= owc_depth);
        if ~isempty(oil_zone_cells)
            oil_pressures = pressure(oil_zone_cells);
            oil_depths = cell_depths(oil_zone_cells);
            [sorted_depths, sort_idx] = sort(oil_depths);
            sorted_pressures = oil_pressures(sort_idx);
            
            % Calculate average gradient in oil zone
            depth_range = max(sorted_depths) - min(sorted_depths);
            pressure_range = max(sorted_pressures) - min(sorted_pressures);
            if depth_range > 0
                calculated_oil_gradient = pressure_range / depth_range;
                gradient_error = abs(calculated_oil_gradient - oil_gradient) / oil_gradient;
                
                if gradient_error > 0.15  % 15% tolerance for realistic reservoir simulation
                    fprintf('   ⚠️  Warning: Hydrostatic gradient deviation %.1f%% (calculated: %.3f, expected: %.3f)\n', ...
                            gradient_error*100, calculated_oil_gradient, oil_gradient);
                    if gradient_error > 0.5  % 50% is too much deviation
                        validation_passed = false;
                    end
                end
            end
        end
        
        %% 5. Apply Compartment Variations
        fprintf('🔀 Applying compartment-specific pressure variations...\n');
        
        % Simple compartmentalization based on grid location
        % Use cell centroids for compartment assignment
        cell_x = G.cells.centroids(:,1);  % X coordinates
        cell_y = G.cells.centroids(:,2);  % Y coordinates
        
        % Create pressure variations based on compartments
        compartment_pressure_adj = zeros(num_cells, 1);
        
        % Simple compartmentalization based on Y coordinates
        y_max = max(cell_y);
        y_min = min(cell_y);
        y_range = y_max - y_min;
        
        for i = 1:num_cells
            y_coord = cell_y(i);
            
            % Northern compartment (higher Y values - top 40% of field)
            if y_coord > y_min + 0.6 * y_range
                compartment_pressure_adj(i) = compartment_variations.northern_psi;
            % Southern compartment (lower Y values - bottom 40% of field)
            elseif y_coord < y_min + 0.4 * y_range
                compartment_pressure_adj(i) = compartment_variations.southern_psi;
            % Central compartment: no adjustment
            else
                compartment_pressure_adj(i) = 0.0;
            end
            
            % Eastern/Western compartment adjustment based on X coordinates
            x_coord = cell_x(i);
            x_max = max(cell_x);
            x_min = min(cell_x);
            x_range = x_max - x_min;
            
            % Eastern compartment adjustment (higher X values)
            if x_coord > x_min + 0.7 * x_range
                compartment_pressure_adj(i) = compartment_pressure_adj(i) + compartment_variations.eastern_psi;
            % Western compartment adjustment (lower X values)
            elseif x_coord < x_min + 0.3 * x_range
                compartment_pressure_adj(i) = compartment_pressure_adj(i) + compartment_variations.western_psi;
            end
        end
        
        % Apply compartment adjustments
        pressure = pressure + compartment_pressure_adj;
        
        fprintf('   📊 Final pressure range: %.0f - %.0f psi\n', min(pressure), max(pressure));
        fprintf('   📊 Compartment variations: %.1f to %.1f psi\n', ...
                min(compartment_pressure_adj), max(compartment_pressure_adj));
        
        %% 6. Validate Pressure Distribution
        fprintf('✅ Validating pressure distribution...\n');
        
        % Check pressure ranges against CANON specifications for Eagle West Field
        expected_min = 3500;  % Adjusted for 3600 psi datum
        expected_max = 3750;  % Adjusted for realistic compartment variations
        
        actual_min = min(pressure);
        actual_max = max(pressure);
        
        validation_passed = true;
        
        if actual_min < expected_min - 50  % Allow 50 psi tolerance
            fprintf('   ⚠️  Warning: Minimum pressure (%.0f psi) below expected (%.0f psi)\n', ...
                    actual_min, expected_min);
            validation_passed = false;
        end
        
        if actual_max > expected_max + 50  % Allow 50 psi tolerance
            fprintf('   ⚠️  Warning: Maximum pressure (%.0f psi) above expected (%.0f psi)\n', ...
                    actual_max, expected_max);
            validation_passed = false;
        end
        
        % Check pressure gradient consistency
        % Define zone cells for final analysis
        oil_zone_cells = cell_depths <= owc_depth;
        water_zone_cells = cell_depths > owc_depth;
        
        if validation_passed
            fprintf('   ✅ Pressure validation PASSED\n');
        else
            error(['CANON-FIRST ERROR: Pressure validation FAILED\n' ...
                   'UPDATE CANON: obsidian-vault/Planning/Initial_Conditions.md\n' ...
                   'Must define valid pressure initialization parameters for Eagle West Field.']);
        end
        
        %% 7. Store Results and Create Output
        fprintf('💾 Storing pressure initialization results...\n');
        
        % Create detailed pressure analysis
        pressure_stats = struct();
        pressure_stats.min_pressure = min(pressure);
        pressure_stats.max_pressure = max(pressure);
        pressure_stats.mean_pressure = mean(pressure);
        pressure_stats.std_pressure = std(pressure);
        pressure_stats.datum_pressure = datum_pressure;
        pressure_stats.datum_depth = datum_depth;
        pressure_stats.owc_depth = owc_depth;
        pressure_stats.oil_gradient = oil_gradient;
        pressure_stats.water_gradient = water_gradient;
        pressure_stats.validation_passed = validation_passed;
        
        % Pressure distribution by zone
        oil_zone_pressures = pressure(oil_zone_cells);
        water_zone_pressures = pressure(water_zone_cells);
        
        pressure_by_zone = struct();
        pressure_by_zone.oil_zone = struct('min', min(oil_zone_pressures), ...
                                          'max', max(oil_zone_pressures), ...
                                          'mean', mean(oil_zone_pressures), ...
                                          'count', length(oil_zone_pressures));
        
        if ~isempty(water_zone_pressures)
            pressure_by_zone.water_zone = struct('min', min(water_zone_pressures), ...
                                                'max', max(water_zone_pressures), ...
                                                'mean', mean(water_zone_pressures), ...
                                                'count', length(water_zone_pressures));
        else
            pressure_by_zone.water_zone = struct('min', NaN, 'max', NaN, 'mean', NaN, 'count', 0);
        end
        
        % Create state structure for MRST
        state = struct();
        state.pressure = pressure;  % Cell pressures in psi (will convert to Pa for MRST)
        
        % Convert pressure to MRST units (Pascal) using CANON conversion factor
        if ~isfield(init_config.initialization, 'unit_conversions') || ~isfield(init_config.initialization.unit_conversions.pressure, 'psi_to_pa')
            error(['CANON-FIRST ERROR: Missing psi_to_pa conversion factor in initialization_config.yaml\n' ...
                   'UPDATE CANON: obsidian-vault/Planning/Initial_Conditions.md\n' ...
                   'Must define exact unit conversion factors for Eagle West Field.']);
        end
        psi_to_pa = init_config.initialization.unit_conversions.pressure.psi_to_pa;
        state.pressure_Pa = pressure * psi_to_pa;
        
        %% 8. Export Results to Canonical MRST Structure
        fprintf('📁 Exporting pressure initialization data...\n');
        
        % Ensure canonical MRST directory exists
        if ~exist(canonical_mrst_dir, 'dir')
            mkdir(canonical_mrst_dir);
        end
        
        % Create canonical MRST data structure
        canonical_file = fullfile(canonical_mrst_dir, 'initial_state.mat');
        data_struct = struct();
        data_struct.pressure = pressure;  % Pressure distribution [Pa]
        data_struct.state = state;  % Initial MRST state
        data_struct.equilibrium.datum = datum_depth;  % Datum depth reference
        data_struct.equilibrium.datum_pressure = datum_pressure;  % Datum pressure
        data_struct.created_by = {'s12'};
        data_struct.timestamp = datetime('now');
        
        % Save to canonical MRST location
        save(canonical_file, 'data_struct');
        fprintf('     ✅ Canonical MRST data saved: %s\n', canonical_file);
        
        % Also save pressure statistics for compatibility
        stats_file = fullfile(canonical_mrst_dir, 'pressure_stats.txt');
        fid = fopen(stats_file, 'w');
        if fid ~= -1
            fprintf(fid, 'Eagle West Field - Pressure Initialization Statistics\n');
            fprintf(fid, '================================================\n\n');
            fprintf(fid, 'Pressure Range: %.0f - %.0f psi\n', min(pressure), max(pressure));
            fprintf(fid, 'Average Pressure: %.0f psi\n', mean(pressure));
            fprintf(fid, 'Datum: %.0f psi @ %.0f ft TVDSS\n', datum_pressure, datum_depth);
            fprintf(fid, 'OWC Depth: %.0f ft TVDSS\n', owc_depth);
            fprintf(fid, 'Oil Gradient: %.3f psi/ft\n', oil_gradient);
            fprintf(fid, 'Water Gradient: %.3f psi/ft\n', water_gradient);
            fclose(fid);
        end
        
        %% 9. Create Output Summary
        output_data.pressure_field = pressure;
        output_data.pressure_stats = pressure_stats;
        output_data.pressure_by_zone = pressure_by_zone;
        output_data.validation_passed = validation_passed;
        output_data.cell_depths = cell_depths;
        output_data.state = state;
        output_data.num_cells = num_cells;
        
        % Success message
        print_step_footer('S12', 'Pressure initialization completed successfully', toc(start_time));
        
    catch ME
        print_step_footer('S12', sprintf('FAILED: %s', ME.message), toc(start_time));
        rethrow(ME);
    end
    
end

function ternary_result = ternary(condition, true_val, false_val)
    if condition
        ternary_result = true_val;
    else
        ternary_result = false_val;
    end
end