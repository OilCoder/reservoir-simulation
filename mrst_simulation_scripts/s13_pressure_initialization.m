function output_data = s13_pressure_initialization()
% S13_PRESSURE_INITIALIZATION - MRST pressure initialization with hydrostatic equilibrium
%
% DESCRIPTION:
%   Implements hydrostatic pressure distribution across the Eagle West Field
%   with phase-specific gradients and compartment variations. Sets up initial
%   pressure conditions for 3-phase reservoir simulation.
%
% CANON REFERENCE: 
%   [[07_Initialization]] - Pressure initialization section
%   - Datum: 2900 psi @ 8000 ft TVDSS
%   - Oil gradient: 0.350 psi/ft
%   - Water gradient: 0.433 psi/ft  
%   - Gas gradient: 0.076 psi/ft
%   - Compartment variations: ±10 psi
%   - OWC: 8150 ft TVDSS
%
% WORKFLOW:
%   1. Load grid and initialization configuration
%   2. Calculate depth-dependent pressure distribution
%   3. Apply phase-specific gradients above/below contacts
%   4. Add compartment-specific pressure variations
%   5. Validate pressure ranges (2830-2995 psi)
%   6. Export pressure field for simulation
%
% RETURNS:
%   output_data - Structure with pressure initialization results
%
% Author: Claude Code AI System
% Date: January 30, 2025

    % Load print utilities for consistent table format
    run('print_utils.m');
    
    % Print module header
    print_step_header('S13', 'PRESSURE INITIALIZATION');
    
    output_data = struct();
    
    try
        %% 1. Load Configuration and Previous Results
        fprintf('📋 Loading configuration and grid data...\n');
        
        % Load YAML configurations
        init_config = read_yaml_config('config/initialization_config.yaml', 'silent', true);
        
        % Load grid and rock properties from previous steps
        if exist('data/mrst_simulation/static/final_rock_summary.txt', 'file')
            fprintf('   ✅ Loading grid from rock properties step\n');
            load('data/mrst_simulation/static/grid_with_rock_properties.mat', 'G');
        else
            error('Grid not found. Run s08_assign_layer_properties.m first');
        end
        
        %% 2. Extract Pressure Initialization Parameters
        fprintf('⚙️  Extracting pressure initialization parameters...\n');
        
        % Datum and reference conditions
        datum_depth = init_config.pressure_initialization.datum_depth_ft;  % 8000 ft TVDSS
        datum_pressure = init_config.pressure_initialization.datum_pressure_psi;  % 2900 psi
        
        % Phase-specific gradients (psi/ft)
        oil_gradient = init_config.pressure_initialization.oil_gradient_psi_per_ft;    % 0.350
        water_gradient = init_config.pressure_initialization.water_gradient_psi_per_ft; % 0.433
        gas_gradient = init_config.pressure_initialization.gas_gradient_psi_per_ft;     % 0.076
        
        % Fluid contacts
        owc_depth = init_config.saturation_initialization.owc_depth_ft;  % 8150 ft TVDSS
        transition_zone_thickness = init_config.saturation_initialization.transition_zone_ft; % 100 ft
        
        % Compartment pressure variations by fault block (from YAML)
        northern_comp = init_config.initialization.compartmentalization.northern_compartment;
        southern_comp = init_config.initialization.compartmentalization.southern_compartment;
        
        % Create compartment variations structure from YAML
        additional_vars = init_config.initialization.compartmentalization.additional_variations;
        compartment_variations = struct();
        compartment_variations.northern_psi = northern_comp.pressure_datum_psi - datum_pressure;  % +5 psi
        compartment_variations.southern_psi = southern_comp.pressure_datum_psi - datum_pressure;  % -5 psi  
        compartment_variations.eastern_psi = additional_vars.eastern_fault_block_psi;   % From YAML
        compartment_variations.western_psi = additional_vars.western_fault_block_psi;   % From YAML
        
        fprintf('   📊 Datum: %.0f psi @ %.0f ft TVDSS\n', datum_pressure, datum_depth);
        fprintf('   📊 Oil gradient: %.3f psi/ft\n', oil_gradient);
        fprintf('   📊 Water gradient: %.3f psi/ft\n', water_gradient);
        fprintf('   📊 OWC depth: %.0f ft TVDSS\n', owc_depth);
        
        %% 3. Calculate Grid Cell Depths
        fprintf('🗺️  Calculating grid cell depths...\n');
        
        % Get cell centers (MRST uses SI units - meters)
        cell_centers = G.cells.centroids;
        cell_depths_m = cell_centers(:, 3);  % Z-coordinate as depth in meters
        
        % Convert to feet using MRST native function
        cell_depths = convertTo(abs(cell_depths_m), ft);
        
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
        
        %% 5. Apply Compartment Variations
        fprintf('🔀 Applying compartment-specific pressure variations...\n');
        
        % Simple compartmentalization based on grid location
        % Divide field into compartments based on I,J coordinates
        [I, J, K] = gridLogicalIndices(G);
        
        % Create pressure variations based on compartments
        compartment_pressure_adj = zeros(num_cells, 1);
        
        % Example compartmentalization (can be refined based on fault blocks)
        for i = 1:num_cells
            i_coord = I(i);
            j_coord = J(i);
            
            % Northern compartment (higher J values)
            if j_coord > G.cartDims(2) * 0.6
                compartment_pressure_adj(i) = compartment_variations.northern_psi;
            % Southern compartment (lower J values)
            elseif j_coord < G.cartDims(2) * 0.4
                compartment_pressure_adj(i) = compartment_variations.southern_psi;
            % Central compartment: no adjustment
            else
                compartment_pressure_adj(i) = 0.0;
            end
            
            % Eastern compartment adjustment (higher I values)
            if i_coord > G.cartDims(1) * 0.7
                compartment_pressure_adj(i) = compartment_pressure_adj(i) + compartment_variations.eastern_psi;
            % Western compartment adjustment (lower I values)
            elseif i_coord < G.cartDims(1) * 0.3
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
        
        % Check pressure ranges against CANON specifications (2830-2995 psi)
        expected_min = 2830;
        expected_max = 2995;
        
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
        oil_zone_cells = cell_depths <= owc_depth;
        water_zone_cells = cell_depths > owc_depth;
        
        if sum(oil_zone_cells) > 1
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
                
                if gradient_error > 0.1  % 10% tolerance
                    fprintf('   ⚠️  Warning: Oil gradient deviation %.1f%% (calculated: %.3f, expected: %.3f)\n', ...
                            gradient_error*100, calculated_oil_gradient, oil_gradient);
                    validation_passed = false;
                end
            end
        end
        
        if validation_passed
            fprintf('   ✅ Pressure validation PASSED\n');
        else
            fprintf('   ⚠️  Pressure validation completed with warnings\n');
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
        
        % Convert pressure to MRST units (Pascal) using native function
        state.pressure_Pa = convertTo(pressure, Pascal);
        
        %% 8. Export Results
        fprintf('📁 Exporting pressure initialization data...\n');
        
        % Ensure output directory exists
        output_dir = 'data/mrst_simulation/static';
        if ~exist(output_dir, 'dir')
            mkdir(output_dir);
        end
        
        % Save pressure field and analysis
        save(fullfile(output_dir, 'pressure_initialization.mat'), ...
             'pressure', 'pressure_stats', 'pressure_by_zone', 'state', ...
             'cell_depths', 'compartment_pressure_adj');
        
        % Save for next phase
        G_with_pressure = G;  % Copy grid structure
        save(fullfile(output_dir, 'grid_with_pressure.mat'), 'G_with_pressure', 'state');
        
        %% 9. Create Output Summary
        output_data.pressure_field = pressure;
        output_data.pressure_stats = pressure_stats;
        output_data.pressure_by_zone = pressure_by_zone;
        output_data.validation_passed = validation_passed;
        output_data.cell_depths = cell_depths;
        output_data.state = state;
        output_data.num_cells = num_cells;
        
        % Success message
        print_step_footer('S13', 'Pressure initialization completed successfully', toc);
        
    catch ME
        print_step_footer('S13', sprintf('FAILED: %s', ME.message), toc);
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