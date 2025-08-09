function reservoir_results = s25_reservoir_analysis()
% S25_RESERVOIR_ANALYSIS - Analyze Reservoir Performance for Eagle West Field  
% Requires: MRST
%
% Analyzes reservoir performance and dynamics from 10-year MRST simulation:
% - Pressure depletion maps and evolution by timestep
% - Saturation distribution changes (oil, water, gas)
% - Sweep efficiency analysis by compartment and fault block
% - Reservoir energy mechanisms and drive analysis
% - Aquifer performance and pressure support
% - Export reservoir maps and comprehensive analysis
%
% OUTPUTS:
%   reservoir_results - Structure with reservoir analysis results
%
% Author: Claude Code AI System
% Date: August 8, 2025

    run('print_utils.m');
    print_step_header('S25', 'Reservoir Performance Analysis');
    
    total_start_time = tic;
    reservoir_results = initialize_reservoir_structure();
    
    try
        % ----------------------------------------
        % Step 1 - Load Simulation and Grid Data
        % ----------------------------------------
        step_start = tic;
        [simulation_data, grid_model, config] = step_1_load_simulation_and_grid_data();
        reservoir_results.simulation_data = simulation_data;
        reservoir_results.grid_model = grid_model;
        reservoir_results.config = config;
        print_step_result(1, 'Load Simulation and Grid Data', 'success', toc(step_start));
        
        % ----------------------------------------
        % Step 2 - Pressure Field Evolution Analysis
        % ----------------------------------------
        step_start = tic;
        pressure_analysis = step_2_pressure_field_evolution_analysis(simulation_data, grid_model);
        reservoir_results.pressure_analysis = pressure_analysis;
        print_step_result(2, 'Pressure Field Evolution', 'success', toc(step_start));
        
        % ----------------------------------------
        % Step 3 - Saturation Distribution Analysis
        % ----------------------------------------
        step_start = tic;
        saturation_analysis = step_3_saturation_distribution_analysis(simulation_data, grid_model);
        reservoir_results.saturation_analysis = saturation_analysis;
        print_step_result(3, 'Saturation Distribution', 'success', toc(step_start));
        
        % ----------------------------------------
        % Step 4 - Sweep Efficiency by Compartment
        % ----------------------------------------
        step_start = tic;
        sweep_analysis = step_4_sweep_efficiency_by_compartment(simulation_data, grid_model, config);
        reservoir_results.sweep_analysis = sweep_analysis;
        print_step_result(4, 'Sweep Efficiency Analysis', 'success', toc(step_start));
        
        % ----------------------------------------
        % Step 5 - Fault Block Drainage Analysis
        % ----------------------------------------
        step_start = tic;
        drainage_analysis = step_5_fault_block_drainage_analysis(simulation_data, grid_model, config);
        reservoir_results.drainage_analysis = drainage_analysis;
        print_step_result(5, 'Fault Block Drainage', 'success', toc(step_start));
        
        % ----------------------------------------
        % Step 6 - Reservoir Energy Analysis
        % ----------------------------------------
        step_start = tic;
        energy_analysis = step_6_reservoir_energy_analysis(simulation_data, grid_model);
        reservoir_results.energy_analysis = energy_analysis;
        print_step_result(6, 'Reservoir Energy Analysis', 'success', toc(step_start));
        
        % ----------------------------------------
        % Step 7 - Generate Reservoir Maps
        % ----------------------------------------
        step_start = tic;
        map_paths = step_7_generate_reservoir_maps(reservoir_results);
        reservoir_results.map_paths = map_paths;
        print_step_result(7, 'Generate Reservoir Maps', 'success', toc(step_start));
        
        % ----------------------------------------
        % Step 8 - Export Reservoir Analysis
        % ----------------------------------------
        step_start = tic;
        export_path = step_8_export_reservoir_analysis(reservoir_results);
        reservoir_results.export_path = export_path;
        print_step_result(8, 'Export Reservoir Analysis', 'success', toc(step_start));
        
        reservoir_results.status = 'success';
        reservoir_results.analysis_completed = true;
        reservoir_results.creation_time = datestr(now);
        
        print_step_footer('S25', sprintf('Reservoir Analysis Complete - %d cells analyzed', ...
            reservoir_results.grid_model.G.cells.num), toc(total_start_time));
        
    catch ME
        print_error_step(0, 'Reservoir Analysis', ME.message);
        reservoir_results.status = 'failed';
        reservoir_results.error_message = ME.message;
        error('Reservoir analysis failed: %s', ME.message);
    end

end

function reservoir_results = initialize_reservoir_structure()
% Initialize reservoir analysis results structure
    reservoir_results = struct();
    reservoir_results.status = 'initializing';
    reservoir_results.simulation_data = [];
    reservoir_results.grid_model = [];
    reservoir_results.config = [];
    reservoir_results.pressure_analysis = [];
    reservoir_results.saturation_analysis = [];
    reservoir_results.sweep_analysis = [];
    reservoir_results.drainage_analysis = [];
    reservoir_results.energy_analysis = [];
    reservoir_results.map_paths = [];
    reservoir_results.export_path = [];
end

function [simulation_data, grid_model, config] = step_1_load_simulation_and_grid_data()
% Step 1 - Load simulation results and grid model for reservoir analysis

    script_path = fileparts(mfilename('fullpath'));
    results_dir = fullfile(fileparts(script_path), 'data', 'mrst_simulation', 'results');
    static_dir = fullfile(fileparts(script_path), 'data', 'mrst_simulation', 'static');
    
    % Substep 1.1 - Load simulation results ______________________________
    results_files = dir(fullfile(results_dir, 'simulation_results_*.mat'));
    if isempty(results_files)
        error('No simulation results found. Run s22_run_simulation.m first.');
    end
    
    [~, idx] = max([results_files.datenum]);
    latest_file = fullfile(results_dir, results_files(idx).name);
    
    fprintf('Loading simulation results: %s\n', results_files(idx).name);
    load(latest_file, 'simulation_results');
    simulation_data = simulation_results;
    
    % Substep 1.2 - Load grid model _______________________________________
    model_file = fullfile(static_dir, 'simulation_model.mat');
    if exist(model_file, 'file')
        load(model_file, 'model');
        grid_model = model;
        fprintf('Loaded grid model: %d cells, %d faces\n', grid_model.G.cells.num, grid_model.G.faces.num);
    else
        error('Grid model not found. Run s21_solver_setup.m first.');
    end
    
    % Substep 1.3 - Load configuration data ______________________________
    config = struct();
    
    % Load fault configuration
    fault_file = fullfile(static_dir, 'fault_results.mat');
    if exist(fault_file, 'file')
        load(fault_file, 'fault_results');
        config.fault_data = fault_results;
    end
    
    % Load structural framework
    struct_file = fullfile(static_dir, 'structural_framework.mat');
    if exist(struct_file, 'file')
        load(struct_file, 'structural_results');
        config.structural_data = structural_results;
    end
    
    % Load aquifer configuration
    aquifer_file = fullfile(static_dir, 'aquifer_configuration.mat');
    if exist(aquifer_file, 'file')
        load(aquifer_file, 'aquifer_results');
        config.aquifer_data = aquifer_results;
    end
    
    fprintf('Configuration loaded: Faults=%s, Aquifer=%s\n', ...
        num2str(isfield(config, 'fault_data')), num2str(isfield(config, 'aquifer_data')));

end

function pressure_analysis = step_2_pressure_field_evolution_analysis(simulation_data, grid_model)
% Step 2 - Analyze pressure field evolution throughout simulation

    fprintf('\n Pressure Field Evolution Analysis:\n');
    fprintf(' ──────────────────────────────────────────────────────────\n');
    
    pressure_analysis = struct();
    
    % Substep 2.1 - Extract pressure data from all timesteps _____________
    states = simulation_data.states;
    num_timesteps = length(states);
    num_cells = grid_model.G.cells.num;
    
    pressure_evolution = zeros(num_cells, num_timesteps);
    time_days = [];
    
    if isfield(simulation_data, 'post_processed')
        time_days = simulation_data.post_processed.time_days;
    else
        % Reconstruct time array
        for i = 1:length(simulation_data.schedule.step)
            if i == 1
                time_days(i) = simulation_data.schedule.step(i).val / (24 * 3600);
            else
                time_days(i) = time_days(i-1) + simulation_data.schedule.step(i).val / (24 * 3600);
            end
        end
    end
    
    % Extract pressure at each timestep
    for t = 1:num_timesteps
        pressure_evolution(:, t) = states{t}.pressure / 1e5;  % Convert to bar
    end
    
    pressure_analysis.pressure_evolution_bar = pressure_evolution;
    pressure_analysis.time_days = [0; time_days(:)];  % Include initial time
    pressure_analysis.time_years = pressure_analysis.time_days / 365.25;
    
    % Substep 2.2 - Calculate pressure statistics _________________________
    initial_pressure = pressure_evolution(:, 1);
    final_pressure = pressure_evolution(:, end);
    
    pressure_analysis.initial_pressure_bar = initial_pressure;
    pressure_analysis.final_pressure_bar = final_pressure;
    pressure_analysis.pressure_decline_bar = initial_pressure - final_pressure;
    pressure_analysis.pressure_decline_percent = (pressure_analysis.pressure_decline_bar ./ (initial_pressure + 1e-10)) * 100;
    
    % Field averages
    pressure_analysis.average_initial_pressure_bar = mean(initial_pressure);
    pressure_analysis.average_final_pressure_bar = mean(final_pressure);
    pressure_analysis.average_pressure_decline_bar = mean(pressure_analysis.pressure_decline_bar);
    pressure_analysis.average_pressure_decline_percent = mean(pressure_analysis.pressure_decline_percent);
    
    % Substep 2.3 - Identify pressure depletion patterns _________________
    % Maximum depletion location
    [max_depletion, max_depl_cell] = max(pressure_analysis.pressure_decline_bar);
    pressure_analysis.max_depletion_bar = max_depletion;
    pressure_analysis.max_depletion_cell = max_depl_cell;
    
    % Minimum depletion location (best pressure support)
    [min_depletion, min_depl_cell] = min(pressure_analysis.pressure_decline_bar);
    pressure_analysis.min_depletion_bar = min_depletion;
    pressure_analysis.min_depletion_cell = min_depl_cell;
    
    % Substep 2.4 - Calculate pressure gradients __________________________
    G = grid_model.G;
    cell_centroids = G.cells.centroids;
    
    % Calculate spatial pressure gradient at final time
    if num_cells > 1
        pressure_gradient = calculate_spatial_gradient(final_pressure, cell_centroids, G);
        pressure_analysis.final_pressure_gradient_bar_per_m = pressure_gradient;
        pressure_analysis.max_pressure_gradient_bar_per_m = max(abs(pressure_gradient));
    end
    
    % Substep 2.5 - Pressure depletion by layer __________________________ 
    if isfield(grid_model, 'rock') && isfield(grid_model.rock, 'poro')
        % Identify layers based on depth
        cell_depths = cell_centroids(:, 3);  % Z-coordinate
        depth_layers = discretize_depths(cell_depths, 5);  % 5 layers
        
        pressure_analysis.layer_analysis = struct();
        for layer = 1:max(depth_layers)
            layer_cells = find(depth_layers == layer);
            if ~isempty(layer_cells)
                layer_initial = mean(initial_pressure(layer_cells));
                layer_final = mean(final_pressure(layer_cells));
                layer_decline = layer_initial - layer_final;
                
                pressure_analysis.layer_analysis.(sprintf('layer_%d', layer)) = struct();
                pressure_analysis.layer_analysis.(sprintf('layer_%d', layer)).initial_pressure_bar = layer_initial;
                pressure_analysis.layer_analysis.(sprintf('layer_%d', layer)).final_pressure_bar = layer_final;
                pressure_analysis.layer_analysis.(sprintf('layer_%d', layer)).pressure_decline_bar = layer_decline;
                pressure_analysis.layer_analysis.(sprintf('layer_%d', layer)).pressure_decline_percent = (layer_decline / layer_initial) * 100;
            end
        end
    end
    
    fprintf('   Average Pressure Decline: %.1f bar (%.1f%%)\n', ...
        pressure_analysis.average_pressure_decline_bar, pressure_analysis.average_pressure_decline_percent);
    fprintf('   Maximum Depletion: %.1f bar (Cell %d)\n', max_depletion, max_depl_cell);
    fprintf('   Minimum Depletion: %.1f bar (Cell %d)\n', min_depletion, min_depl_cell);
    fprintf(' ──────────────────────────────────────────────────────────\n');

end

function saturation_analysis = step_3_saturation_distribution_analysis(simulation_data, grid_model)
% Step 3 - Analyze saturation distribution changes throughout simulation

    fprintf('\n Saturation Distribution Analysis:\n');
    fprintf(' ──────────────────────────────────────────────────────────\n');
    
    saturation_analysis = struct();
    
    % Substep 3.1 - Extract saturation data from all timesteps ___________
    states = simulation_data.states;
    num_timesteps = length(states);
    num_cells = grid_model.G.cells.num;
    
    % MRST saturation order: [water, oil, gas]
    oil_saturation_evolution = zeros(num_cells, num_timesteps);
    water_saturation_evolution = zeros(num_cells, num_timesteps);
    gas_saturation_evolution = zeros(num_cells, num_timesteps);
    
    for t = 1:num_timesteps
        water_saturation_evolution(:, t) = states{t}.s(:, 1);  % Water
        oil_saturation_evolution(:, t) = states{t}.s(:, 2);    % Oil
        gas_saturation_evolution(:, t) = states{t}.s(:, 3);    % Gas
    end
    
    saturation_analysis.oil_saturation_evolution = oil_saturation_evolution;
    saturation_analysis.water_saturation_evolution = water_saturation_evolution;
    saturation_analysis.gas_saturation_evolution = gas_saturation_evolution;
    
    % Time array
    if isfield(simulation_data, 'post_processed')
        time_days = simulation_data.post_processed.time_days;
    else
        time_days = cumsum([simulation_data.schedule.step.val]) / (24 * 3600);
    end
    saturation_analysis.time_days = [0; time_days(:)];
    
    % Substep 3.2 - Calculate saturation changes _________________________
    initial_oil_sat = oil_saturation_evolution(:, 1);
    final_oil_sat = oil_saturation_evolution(:, end);
    initial_water_sat = water_saturation_evolution(:, 1);
    final_water_sat = water_saturation_evolution(:, end);
    initial_gas_sat = gas_saturation_evolution(:, 1);
    final_gas_sat = gas_saturation_evolution(:, end);
    
    saturation_analysis.initial_oil_saturation = initial_oil_sat;
    saturation_analysis.final_oil_saturation = final_oil_sat;
    saturation_analysis.oil_saturation_change = final_oil_sat - initial_oil_sat;
    
    saturation_analysis.initial_water_saturation = initial_water_sat;
    saturation_analysis.final_water_saturation = final_water_sat;
    saturation_analysis.water_saturation_change = final_water_sat - initial_water_sat;
    
    saturation_analysis.initial_gas_saturation = initial_gas_sat;
    saturation_analysis.final_gas_saturation = final_gas_sat;
    saturation_analysis.gas_saturation_change = final_gas_sat - initial_gas_sat;
    
    % Substep 3.3 - Field average saturation evolution ___________________
    saturation_analysis.average_oil_saturation = mean(oil_saturation_evolution, 1);
    saturation_analysis.average_water_saturation = mean(water_saturation_evolution, 1);
    saturation_analysis.average_gas_saturation = mean(gas_saturation_evolution, 1);
    
    % Substep 3.4 - Calculate drainage and imbibition zones ______________
    oil_decrease_cells = find(saturation_analysis.oil_saturation_change < -0.01);  % Significant oil loss
    water_increase_cells = find(saturation_analysis.water_saturation_change > 0.01);  % Water invasion
    
    saturation_analysis.drainage_zone_cells = oil_decrease_cells;
    saturation_analysis.imbibition_zone_cells = water_increase_cells;
    saturation_analysis.drainage_zone_fraction = length(oil_decrease_cells) / num_cells;
    saturation_analysis.imbibition_zone_fraction = length(water_increase_cells) / num_cells;
    
    % Substep 3.5 - Oil recovery by saturation zones _____________________
    G = grid_model.G;
    cell_volumes = G.cells.volumes;
    
    if isfield(grid_model, 'rock') && isfield(grid_model.rock, 'poro')
        pore_volumes = cell_volumes .* grid_model.rock.poro;
    else
        pore_volumes = cell_volumes * 0.2;  % Default porosity
    end
    
    % Calculate oil volumes
    initial_oil_volume = sum(initial_oil_sat .* pore_volumes);
    final_oil_volume = sum(final_oil_sat .* pore_volumes);
    oil_recovery_volume = initial_oil_volume - final_oil_volume;
    
    saturation_analysis.initial_oil_volume_m3 = initial_oil_volume;
    saturation_analysis.final_oil_volume_m3 = final_oil_volume;
    saturation_analysis.oil_recovery_volume_m3 = oil_recovery_volume;
    saturation_analysis.oil_recovery_fraction = oil_recovery_volume / (initial_oil_volume + 1e-10);
    
    % Substep 3.6 - Residual oil analysis ________________________________
    residual_oil_cells = find(final_oil_sat > 0.1 & saturation_analysis.oil_saturation_change < -0.05);
    bypassed_oil_cells = find(final_oil_sat > 0.3);  % High remaining oil
    
    saturation_analysis.residual_oil_cells = residual_oil_cells;
    saturation_analysis.bypassed_oil_cells = bypassed_oil_cells;
    saturation_analysis.residual_oil_fraction = length(residual_oil_cells) / num_cells;
    saturation_analysis.bypassed_oil_fraction = length(bypassed_oil_cells) / num_cells;
    
    % Calculate remaining oil volumes
    remaining_oil_volume = sum(final_oil_sat .* pore_volumes);
    saturation_analysis.remaining_oil_volume_m3 = remaining_oil_volume;
    saturation_analysis.remaining_oil_mmstb = remaining_oil_volume / 0.158987 / 1e6;  % Convert to MMstb
    
    fprintf('   Oil Recovery Fraction: %.1f%%\n', saturation_analysis.oil_recovery_fraction * 100);
    fprintf('   Drainage Zone: %.1f%% of reservoir\n', saturation_analysis.drainage_zone_fraction * 100);
    fprintf('   Imbibition Zone: %.1f%% of reservoir\n', saturation_analysis.imbibition_zone_fraction * 100);
    fprintf('   Bypassed Oil: %.1f MMstb (%.1f%% of reservoir)\n', ...
        saturation_analysis.remaining_oil_mmstb, saturation_analysis.bypassed_oil_fraction * 100);
    fprintf(' ──────────────────────────────────────────────────────────\n');

end

function sweep_analysis = step_4_sweep_efficiency_by_compartment(simulation_data, grid_model, config)
% Step 4 - Analyze sweep efficiency by reservoir compartments

    fprintf('\n Sweep Efficiency Analysis by Compartment:\n');
    fprintf(' ──────────────────────────────────────────────────────────\n');
    
    sweep_analysis = struct();
    
    % Substep 4.1 - Define reservoir compartments ________________________
    G = grid_model.G;
    cell_centroids = G.cells.centroids;
    num_cells = G.cells.num;
    
    % Define compartments based on spatial location
    x_coords = cell_centroids(:, 1);
    y_coords = cell_centroids(:, 2);
    
    % Divide reservoir into spatial compartments
    x_bins = linspace(min(x_coords), max(x_coords), 4);  % 3 x-compartments
    y_bins = linspace(min(y_coords), max(y_coords), 4);  % 3 y-compartments
    
    [~, x_indices] = histc(x_coords, x_bins);
    [~, y_indices] = histc(y_coords, y_bins);
    
    % Create compartment IDs
    compartment_ids = (y_indices - 1) * 3 + x_indices;
    compartment_ids(compartment_ids == 0) = 1;  % Handle edge cases
    max_compartments = 9;  % 3x3 grid
    
    sweep_analysis.compartment_ids = compartment_ids;
    sweep_analysis.num_compartments = max_compartments;
    
    % Substep 4.2 - Calculate sweep efficiency by compartment _____________
    states = simulation_data.states;
    initial_state = states{1};
    final_state = states{end};
    
    initial_oil_sat = initial_state.s(:, 2);  % Oil saturation
    final_oil_sat = final_state.s(:, 2);
    
    sweep_analysis.compartment_analysis = struct();
    
    for comp = 1:max_compartments
        comp_cells = find(compartment_ids == comp);
        if isempty(comp_cells)
            continue;
        end
        
        % Calculate compartment metrics
        comp_initial_oil = initial_oil_sat(comp_cells);
        comp_final_oil = final_oil_sat(comp_cells);
        comp_oil_change = comp_initial_oil - comp_final_oil;
        
        % Sweep efficiency metrics
        contacted_cells = sum(comp_oil_change > 0.01);  % Cells with significant oil decrease
        total_cells = length(comp_cells);
        sweep_efficiency = contacted_cells / total_cells;
        
        % Recovery efficiency in swept zones
        swept_cells = comp_cells(comp_oil_change > 0.01);
        if ~isempty(swept_cells)
            swept_oil_change = comp_oil_change(comp_oil_change > 0.01);
            swept_initial_oil = comp_initial_oil(comp_oil_change > 0.01);
            displacement_efficiency = mean(swept_oil_change ./ (swept_initial_oil + 1e-10));
        else
            displacement_efficiency = 0;
        end
        
        % Compartment results
        comp_result = struct();
        comp_result.compartment_id = comp;
        comp_result.total_cells = total_cells;
        comp_result.contacted_cells = contacted_cells;
        comp_result.sweep_efficiency = sweep_efficiency;
        comp_result.displacement_efficiency = displacement_efficiency;
        comp_result.overall_recovery_efficiency = sweep_efficiency * displacement_efficiency;
        
        % Volume-weighted calculations if rock properties available
        if isfield(grid_model, 'rock') && isfield(grid_model.rock, 'poro')
            comp_volumes = G.cells.volumes(comp_cells);
            comp_poro = grid_model.rock.poro(comp_cells);
            comp_pore_volumes = comp_volumes .* comp_poro;
            
            initial_oil_volume = sum(comp_initial_oil .* comp_pore_volumes);
            final_oil_volume = sum(comp_final_oil .* comp_pore_volumes);
            recovery_volume = initial_oil_volume - final_oil_volume;
            
            comp_result.initial_oil_volume_m3 = initial_oil_volume;
            comp_result.recovery_volume_m3 = recovery_volume;
            comp_result.recovery_factor = recovery_volume / (initial_oil_volume + 1e-10);
        end
        
        sweep_analysis.compartment_analysis.(sprintf('compartment_%d', comp)) = comp_result;
        
        fprintf('   Compartment %d: Sweep=%.1f%%, Displacement=%.1f%%, Recovery=%.1f%%\n', ...
            comp, sweep_efficiency*100, displacement_efficiency*100, ...
            comp_result.overall_recovery_efficiency*100);
    end
    
    % Substep 4.3 - Overall field sweep efficiency _______________________
    all_compartments = fieldnames(sweep_analysis.compartment_analysis);
    total_sweep_values = [];
    total_displacement_values = [];
    total_recovery_values = [];
    
    for i = 1:length(all_compartments)
        comp_data = sweep_analysis.compartment_analysis.(all_compartments{i});
        total_sweep_values(end+1) = comp_data.sweep_efficiency;
        total_displacement_values(end+1) = comp_data.displacement_efficiency;
        total_recovery_values(end+1) = comp_data.overall_recovery_efficiency;
    end
    
    sweep_analysis.field_sweep_efficiency = mean(total_sweep_values);
    sweep_analysis.field_displacement_efficiency = mean(total_displacement_values);
    sweep_analysis.field_recovery_efficiency = mean(total_recovery_values);
    
    fprintf('   Field Averages: Sweep=%.1f%%, Displacement=%.1f%%, Recovery=%.1f%%\n', ...
        sweep_analysis.field_sweep_efficiency*100, sweep_analysis.field_displacement_efficiency*100, ...
        sweep_analysis.field_recovery_efficiency*100);
    fprintf(' ──────────────────────────────────────────────────────────\n');

end

function drainage_analysis = step_5_fault_block_drainage_analysis(simulation_data, grid_model, config)
% Step 5 - Analyze drainage patterns and connectivity by fault blocks

    fprintf('\n Fault Block Drainage Analysis:\n');
    fprintf(' ──────────────────────────────────────────────────────────\n');
    
    drainage_analysis = struct();
    
    % Substep 5.1 - Identify fault blocks ________________________________
    G = grid_model.G;
    num_cells = G.cells.num;
    
    if isfield(config, 'fault_data') && ~isempty(config.fault_data)
        % Use fault data to define blocks if available
        fault_data = config.fault_data;
        if isfield(fault_data, 'fault_cells') && ~isempty(fault_data.fault_cells)
            drainage_analysis.fault_blocks_defined = true;
            fault_blocks = identify_fault_blocks_from_data(G, fault_data);
        else
            drainage_analysis.fault_blocks_defined = false;
            fault_blocks = create_spatial_blocks(G, 6);  % Default 6 blocks
        end
    else
        drainage_analysis.fault_blocks_defined = false;
        fault_blocks = create_spatial_blocks(G, 6);  % Default 6 blocks
    end
    
    drainage_analysis.fault_blocks = fault_blocks;
    drainage_analysis.num_fault_blocks = max(fault_blocks);
    
    % Substep 5.2 - Analyze drainage by fault block ______________________
    states = simulation_data.states;
    initial_pressure = states{1}.pressure;
    final_pressure = states{end}.pressure;
    initial_oil_sat = states{1}.s(:, 2);
    final_oil_sat = states{end}.s(:, 2);
    
    drainage_analysis.block_analysis = struct();
    
    for block = 1:max(fault_blocks)
        block_cells = find(fault_blocks == block);
        if isempty(block_cells)
            continue;
        end
        
        % Pressure analysis
        block_initial_pressure = initial_pressure(block_cells);
        block_final_pressure = final_pressure(block_cells);
        block_pressure_decline = block_initial_pressure - block_final_pressure;
        
        % Saturation analysis
        block_initial_oil = initial_oil_sat(block_cells);
        block_final_oil = final_oil_sat(block_cells);
        block_oil_recovery = block_initial_oil - block_final_oil;
        
        % Drainage efficiency metrics
        avg_pressure_decline = mean(block_pressure_decline) / 1e5;  % bar
        avg_oil_recovery = mean(block_oil_recovery);
        recovery_efficiency = avg_oil_recovery / (mean(block_initial_oil) + 1e-10);
        
        % Connectivity assessment based on pressure communication
        pressure_variance = var(block_pressure_decline) / 1e10;  % Normalized variance
        connectivity_index = 1 / (1 + pressure_variance);  % Higher variance = lower connectivity
        
        block_result = struct();
        block_result.block_id = block;
        block_result.total_cells = length(block_cells);
        block_result.average_pressure_decline_bar = avg_pressure_decline;
        block_result.pressure_variance_normalized = pressure_variance;
        block_result.connectivity_index = connectivity_index;
        block_result.average_oil_recovery_fraction = avg_oil_recovery;
        block_result.recovery_efficiency = recovery_efficiency;
        
        % Drainage pattern classification
        if recovery_efficiency > 0.3
            block_result.drainage_quality = 'Excellent';
        elseif recovery_efficiency > 0.2
            block_result.drainage_quality = 'Good';
        elseif recovery_efficiency > 0.1
            block_result.drainage_quality = 'Fair';
        else
            block_result.drainage_quality = 'Poor';
        end
        
        drainage_analysis.block_analysis.(sprintf('block_%d', block)) = block_result;
        
        fprintf('   Block %d: Recovery=%.1f%%, Connectivity=%.2f, Quality=%s\n', ...
            block, recovery_efficiency*100, connectivity_index, block_result.drainage_quality);
    end
    
    % Substep 5.3 - Inter-block connectivity analysis ____________________
    drainage_analysis.connectivity_matrix = calculate_inter_block_connectivity(G, fault_blocks, final_pressure);
    
    % Substep 5.4 - Overall drainage assessment ___________________________
    all_blocks = fieldnames(drainage_analysis.block_analysis);
    recovery_efficiencies = [];
    connectivity_indices = [];
    
    for i = 1:length(all_blocks)
        block_data = drainage_analysis.block_analysis.(all_blocks{i});
        recovery_efficiencies(end+1) = block_data.recovery_efficiency;
        connectivity_indices(end+1) = block_data.connectivity_index;
    end
    
    drainage_analysis.field_average_recovery = mean(recovery_efficiencies);
    drainage_analysis.field_average_connectivity = mean(connectivity_indices);
    drainage_analysis.recovery_heterogeneity = std(recovery_efficiencies) / (mean(recovery_efficiencies) + 1e-10);
    
    fprintf('   Field Averages: Recovery=%.1f%%, Connectivity=%.2f, Heterogeneity=%.2f\n', ...
        drainage_analysis.field_average_recovery*100, drainage_analysis.field_average_connectivity, ...
        drainage_analysis.recovery_heterogeneity);
    fprintf(' ──────────────────────────────────────────────────────────\n');

end

function energy_analysis = step_6_reservoir_energy_analysis(simulation_data, grid_model)
% Step 6 - Analyze reservoir energy mechanisms and drive types

    fprintf('\n Reservoir Energy Analysis:\n');
    fprintf(' ──────────────────────────────────────────────────────────\n');
    
    energy_analysis = struct();
    
    % Substep 6.1 - Material balance analysis ____________________________
    states = simulation_data.states;
    G = grid_model.G;
    
    if isfield(grid_model, 'rock') && isfield(grid_model.rock, 'poro')
        pore_volumes = G.cells.volumes .* grid_model.rock.poro;
        total_pore_volume = sum(pore_volumes);
    else
        pore_volumes = G.cells.volumes * 0.2;  % Default porosity
        total_pore_volume = sum(pore_volumes);
    end
    
    % Track fluid volumes over time
    num_timesteps = length(states);
    oil_volumes = zeros(num_timesteps, 1);
    water_volumes = zeros(num_timesteps, 1);
    gas_volumes = zeros(num_timesteps, 1);
    total_pore_pressures = zeros(num_timesteps, 1);
    
    for t = 1:num_timesteps
        state = states{t};
        oil_volumes(t) = sum(state.s(:, 2) .* pore_volumes);  % Oil
        water_volumes(t) = sum(state.s(:, 1) .* pore_volumes);  % Water
        gas_volumes(t) = sum(state.s(:, 3) .* pore_volumes);  % Gas
        total_pore_pressures(t) = sum(state.pressure .* pore_volumes) / total_pore_volume;  % Average pressure
    end
    
    energy_analysis.oil_volume_evolution_m3 = oil_volumes;
    energy_analysis.water_volume_evolution_m3 = water_volumes;
    energy_analysis.gas_volume_evolution_m3 = gas_volumes;
    energy_analysis.average_pressure_evolution_pa = total_pore_pressures;
    
    % Substep 6.2 - Identify drive mechanisms _____________________________
    initial_oil_volume = oil_volumes(1);
    final_oil_volume = oil_volumes(end);
    oil_production = initial_oil_volume - final_oil_volume;
    
    initial_water_volume = water_volumes(1);
    final_water_volume = water_volumes(end);
    water_influx = final_water_volume - initial_water_volume;
    
    initial_gas_volume = gas_volumes(1);
    final_gas_volume = gas_volumes(end);
    
    initial_pressure = total_pore_pressures(1);
    final_pressure = total_pore_pressures(end);
    pressure_decline = initial_pressure - final_pressure;
    
    % Drive mechanism analysis
    energy_analysis.drive_mechanisms = struct();
    
    % Solution gas drive (gas coming out of solution)
    if final_gas_volume > initial_gas_volume * 1.1  % Significant gas increase
        gas_drive_strength = (final_gas_volume - initial_gas_volume) / oil_production;
        energy_analysis.drive_mechanisms.solution_gas_drive = true;
        energy_analysis.drive_mechanisms.gas_drive_strength = gas_drive_strength;
    else
        energy_analysis.drive_mechanisms.solution_gas_drive = false;
        energy_analysis.drive_mechanisms.gas_drive_strength = 0;
    end
    
    % Water drive (aquifer support)
    if water_influx > 0.01 * initial_oil_volume  % Significant water influx
        water_drive_strength = water_influx / oil_production;
        energy_analysis.drive_mechanisms.water_drive = true;
        energy_analysis.drive_mechanisms.water_drive_strength = water_drive_strength;
    else
        energy_analysis.drive_mechanisms.water_drive = false;
        energy_analysis.drive_mechanisms.water_drive_strength = 0;
    end
    
    % Depletion drive (pressure depletion)
    depletion_drive_strength = (pressure_decline / initial_pressure) / (oil_production / initial_oil_volume + 1e-10);
    energy_analysis.drive_mechanisms.depletion_drive = true;
    energy_analysis.drive_mechanisms.depletion_drive_strength = depletion_drive_strength;
    
    % Substep 6.3 - Calculate drive indices _______________________________
    total_drive_strength = energy_analysis.drive_mechanisms.gas_drive_strength + ...
                           energy_analysis.drive_mechanisms.water_drive_strength + ...
                           energy_analysis.drive_mechanisms.depletion_drive_strength;
    
    if total_drive_strength > 0
        energy_analysis.drive_indices = struct();
        energy_analysis.drive_indices.gas_drive_index = energy_analysis.drive_mechanisms.gas_drive_strength / total_drive_strength;
        energy_analysis.drive_indices.water_drive_index = energy_analysis.drive_mechanisms.water_drive_strength / total_drive_strength;
        energy_analysis.drive_indices.depletion_drive_index = energy_analysis.drive_mechanisms.depletion_drive_strength / total_drive_strength;
    end
    
    % Substep 6.4 - Reservoir energy efficiency ___________________________
    energy_analysis.energy_efficiency = struct();
    
    % Pressure maintenance efficiency
    pressure_maintenance = 1 - (pressure_decline / initial_pressure);
    energy_analysis.energy_efficiency.pressure_maintenance = pressure_maintenance;
    
    # Voidage replacement efficiency
    if isfield(simulation_data, 'post_processed')
        cum_production = simulation_data.post_processed.cumulative_oil_stb(end) + ...
                        simulation_data.post_processed.cumulative_water_bbl(end);
        cum_injection = simulation_data.post_processed.cumulative_injection_bbl(end);
        voidage_replacement = cum_injection / (cum_production + 1e-10);
        energy_analysis.energy_efficiency.voidage_replacement_ratio = voidage_replacement;
    end
    
    # Substep 6.5 - Energy mechanism classification ______________________
    if energy_analysis.drive_indices.water_drive_index > 0.6
        energy_analysis.primary_drive_mechanism = 'Water Drive';
    elseif energy_analysis.drive_indices.gas_drive_index > 0.6
        energy_analysis.primary_drive_mechanism = 'Solution Gas Drive';
    elseif energy_analysis.drive_indices.depletion_drive_index > 0.6
        energy_analysis.primary_drive_mechanism = 'Depletion Drive';
    else
        energy_analysis.primary_drive_mechanism = 'Combination Drive';
    end
    
    fprintf('   Primary Drive Mechanism: %s\n', energy_analysis.primary_drive_mechanism);
    fprintf('   Drive Indices - Gas: %.1f%%, Water: %.1f%%, Depletion: %.1f%%\n', ...
        energy_analysis.drive_indices.gas_drive_index*100, ...
        energy_analysis.drive_indices.water_drive_index*100, ...
        energy_analysis.drive_indices.depletion_drive_index*100);
    fprintf('   Pressure Maintenance: %.1f%%\n', pressure_maintenance*100);
    fprintf(' ──────────────────────────────────────────────────────────\n');

end

function map_paths = step_7_generate_reservoir_maps(reservoir_results)
% Step 7 - Generate comprehensive reservoir visualization maps

    fprintf('\n Generating Reservoir Maps:\n');
    fprintf(' ──────────────────────────────────────────────────────────\n');
    
    script_path = fileparts(mfilename('fullpath'));
    maps_dir = fullfile(fileparts(script_path), 'data', 'mrst_simulation', 'maps');
    
    if ~exist(maps_dir, 'dir')
        mkdir(maps_dir);
    end
    
    map_paths = struct();
    G = reservoir_results.grid_model.G;
    
    % Substep 7.1 - Pressure depletion maps ______________________________
    if isfield(reservoir_results, 'pressure_analysis')
        pressure_data = reservoir_results.pressure_analysis;
        
        figure('Position', [100, 100, 1400, 1000], 'Visible', 'off');
        
        subplot(2, 2, 1);
        plotCellData(G, pressure_data.initial_pressure_bar);
        colorbar;
        title('Initial Pressure (bar)');
        axis equal tight;
        
        subplot(2, 2, 2);
        plotCellData(G, pressure_data.final_pressure_bar);
        colorbar;
        title('Final Pressure (bar)');
        axis equal tight;
        
        subplot(2, 2, 3);
        plotCellData(G, pressure_data.pressure_decline_bar);
        colorbar;
        title('Pressure Decline (bar)');
        axis equal tight;
        
        subplot(2, 2, 4);
        plotCellData(G, pressure_data.pressure_decline_percent);
        colorbar;
        title('Pressure Decline (%)');
        axis equal tight;
        
        sgtitle('Eagle West Field - Pressure Evolution Maps', 'FontSize', 14, 'FontWeight', 'bold');
        
        pressure_map_path = fullfile(maps_dir, 'pressure_evolution_maps.png');
        saveas(gcf, pressure_map_path);
        close(gcf);
        map_paths.pressure_maps = pressure_map_path;
    end
    
    % Substep 7.2 - Saturation distribution maps _________________________
    if isfield(reservoir_results, 'saturation_analysis')
        sat_data = reservoir_results.saturation_analysis;
        
        figure('Position', [100, 100, 1400, 1000], 'Visible', 'off');
        
        subplot(2, 3, 1);
        plotCellData(G, sat_data.initial_oil_saturation);
        colorbar;
        title('Initial Oil Saturation');
        axis equal tight;
        
        subplot(2, 3, 2);
        plotCellData(G, sat_data.final_oil_saturation);
        colorbar;
        title('Final Oil Saturation');
        axis equal tight;
        
        subplot(2, 3, 3);
        plotCellData(G, sat_data.oil_saturation_change);
        colorbar;
        title('Oil Saturation Change');
        axis equal tight;
        
        subplot(2, 3, 4);
        plotCellData(G, sat_data.initial_water_saturation);
        colorbar;
        title('Initial Water Saturation');
        axis equal tight;
        
        subplot(2, 3, 5);
        plotCellData(G, sat_data.final_water_saturation);
        colorbar;
        title('Final Water Saturation');
        axis equal tight;
        
        subplot(2, 3, 6);
        plotCellData(G, sat_data.water_saturation_change);
        colorbar;
        title('Water Saturation Change');
        axis equal tight;
        
        sgtitle('Eagle West Field - Saturation Distribution Maps', 'FontSize', 14, 'FontWeight', 'bold');
        
        saturation_map_path = fullfile(maps_dir, 'saturation_distribution_maps.png');
        saveas(gcf, saturation_map_path);
        close(gcf);
        map_paths.saturation_maps = saturation_map_path;
    end
    
    % Substep 7.3 - Sweep efficiency maps ________________________________
    if isfield(reservoir_results, 'sweep_analysis')
        sweep_data = reservoir_results.sweep_analysis;
        
        figure('Position', [100, 100, 1000, 600], 'Visible', 'off');
        
        subplot(1, 2, 1);
        plotCellData(G, sweep_data.compartment_ids);
        colorbar;
        title('Reservoir Compartments');
        axis equal tight;
        
        # Create sweep efficiency map by compartment
        sweep_eff_map = zeros(G.cells.num, 1);
        compartment_fields = fieldnames(sweep_data.compartment_analysis);
        for i = 1:length(compartment_fields)
            comp_data = sweep_data.compartment_analysis.(compartment_fields{i});
            comp_cells = find(sweep_data.compartment_ids == comp_data.compartment_id);
            sweep_eff_map(comp_cells) = comp_data.overall_recovery_efficiency;
        end
        
        subplot(1, 2, 2);
        plotCellData(G, sweep_eff_map);
        colorbar;
        title('Sweep Efficiency by Compartment');
        axis equal tight;
        
        sgtitle('Eagle West Field - Sweep Efficiency Analysis', 'FontSize', 14, 'FontWeight', 'bold');
        
        sweep_map_path = fullfile(maps_dir, 'sweep_efficiency_maps.png');
        saveas(gcf, sweep_map_path);
        close(gcf);
        map_paths.sweep_maps = sweep_map_path;
    end
    
    # Substep 7.4 - Drainage pattern maps _______________________________
    if isfield(reservoir_results, 'drainage_analysis')
        drainage_data = reservoir_results.drainage_analysis;
        
        figure('Position', [100, 100, 1000, 600], 'Visible', 'off');
        
        subplot(1, 2, 1);
        plotCellData(G, drainage_data.fault_blocks);
        colorbar;
        title('Fault Block Definition');
        axis equal tight;
        
        # Create drainage quality map
        drainage_quality_map = zeros(G.cells.num, 1);
        block_fields = fieldnames(drainage_data.block_analysis);
        for i = 1:length(block_fields)
            block_data = drainage_data.block_analysis.(block_fields{i});
            block_cells = find(drainage_data.fault_blocks == block_data.block_id);
            drainage_quality_map(block_cells) = block_data.recovery_efficiency;
        end
        
        subplot(1, 2, 2);
        plotCellData(G, drainage_quality_map);
        colorbar;
        title('Drainage Quality by Fault Block');
        axis equal tight;
        
        sgtitle('Eagle West Field - Fault Block Drainage Analysis', 'FontSize', 14, 'FontWeight', 'bold');
        
        drainage_map_path = fullfile(maps_dir, 'drainage_pattern_maps.png');
        saveas(gcf, drainage_map_path);
        close(gcf);
        map_paths.drainage_maps = drainage_map_path;
    end
    
    fprintf('   Pressure Maps: %s\n', map_paths.pressure_maps);
    fprintf('   Saturation Maps: %s\n', map_paths.saturation_maps);
    if isfield(map_paths, 'sweep_maps')
        fprintf('   Sweep Maps: %s\n', map_paths.sweep_maps);
    end
    if isfield(map_paths, 'drainage_maps')
        fprintf('   Drainage Maps: %s\n', map_paths.drainage_maps);
    end
    fprintf(' ──────────────────────────────────────────────────────────\n');

end

function export_path = step_8_export_reservoir_analysis(reservoir_results)
% Step 8 - Export complete reservoir analysis results

    script_path = fileparts(mfilename('fullpath'));
    results_dir = fullfile(fileparts(script_path), 'data', 'mrst_simulation', 'results');
    
    if ~exist(results_dir, 'dir')
        mkdir(results_dir);
    end
    
    # Substep 8.1 - Save complete reservoir analysis _____________________
    timestamp = datestr(now, 'yyyymmdd_HHMMSS');
    export_path = fullfile(results_dir, sprintf('reservoir_analysis_%s.mat', timestamp));
    save(export_path, 'reservoir_results', '-v7.3');
    
    # Substep 8.2 - Export reservoir summary report ______________________
    summary_file = fullfile(results_dir, sprintf('reservoir_summary_%s.txt', timestamp));
    write_reservoir_summary_file(summary_file, reservoir_results);
    
    fprintf('   Reservoir Analysis: %s\n', export_path);
    fprintf('   Summary Report: %s\n', summary_file);

end

# Helper functions
function gradient = calculate_spatial_gradient(field_values, centroids, G)
% Calculate spatial gradient of a field
    num_cells = length(field_values);
    gradient = zeros(num_cells, 1);
    
    for i = 1:num_cells
        # Find neighboring cells
        neighbors = G.cells.facePos(i):G.cells.facePos(i+1)-1;
        neighbor_faces = G.cells.faces(neighbors, 1);
        
        if length(neighbor_faces) > 1
            neighbor_cells = [];
            for j = 1:length(neighbor_faces)
                face_cells = G.faces.neighbors(neighbor_faces(j), :);
                other_cell = face_cells(face_cells ~= i);
                if ~isempty(other_cell) && other_cell > 0
                    neighbor_cells(end+1) = other_cell;
                end
            end
            
            if ~isempty(neighbor_cells)
                neighbor_values = field_values(neighbor_cells);
                neighbor_coords = centroids(neighbor_cells, :);
                current_coord = centroids(i, :);
                
                # Calculate distance-weighted gradient
                distances = sqrt(sum((neighbor_coords - current_coord).^2, 2));
                value_differences = neighbor_values - field_values(i);
                
                if any(distances > 0)
                    gradient(i) = mean(abs(value_differences ./ (distances + 1e-10)));
                end
            end
        end
    end
end

function depth_layers = discretize_depths(depths, num_layers)
% Discretize depths into layers
    min_depth = min(depths);
    max_depth = max(depths);
    layer_boundaries = linspace(min_depth, max_depth, num_layers + 1);
    depth_layers = discretize(depths, layer_boundaries);
    depth_layers(isnan(depth_layers)) = 1;  % Handle edge cases
end

function fault_blocks = identify_fault_blocks_from_data(G, fault_data)
% Identify fault blocks using fault cell data
    num_cells = G.cells.num;
    fault_blocks = ones(num_cells, 1);  # Default to block 1
    
    if isfield(fault_data, 'fault_cells') && ~isempty(fault_data.fault_cells)
        fault_cells = fault_data.fault_cells;
        
        # Simple approach: divide reservoir by fault locations
        cell_centroids = G.cells.centroids;
        x_coords = cell_centroids(:, 1);
        y_coords = cell_centroids(:, 2);
        
        # Find fault centroid as dividing line
        if length(fault_cells) > 0
            fault_centroids = cell_centroids(fault_cells, :);
            fault_center_x = mean(fault_centroids(:, 1));
            fault_center_y = mean(fault_centroids(:, 2));
            
            # Divide into blocks based on position relative to fault
            fault_blocks(x_coords < fault_center_x & y_coords < fault_center_y) = 1;
            fault_blocks(x_coords >= fault_center_x & y_coords < fault_center_y) = 2;
            fault_blocks(x_coords < fault_center_x & y_coords >= fault_center_y) = 3;
            fault_blocks(x_coords >= fault_center_x & y_coords >= fault_center_y) = 4;
        end
    else
        # Fallback to spatial blocks
        fault_blocks = create_spatial_blocks(G, 4);
    end
end

function spatial_blocks = create_spatial_blocks(G, num_blocks)
% Create spatial blocks for analysis
    cell_centroids = G.cells.centroids;
    x_coords = cell_centroids(:, 1);
    y_coords = cell_centroids(:, 2);
    
    blocks_per_dim = ceil(sqrt(num_blocks));
    x_bins = linspace(min(x_coords), max(x_coords), blocks_per_dim + 1);
    y_bins = linspace(min(y_coords), max(y_coords), blocks_per_dim + 1);
    
    [~, x_indices] = histc(x_coords, x_bins);
    [~, y_indices] = histc(y_coords, y_bins);
    
    spatial_blocks = (y_indices - 1) * blocks_per_dim + x_indices;
    spatial_blocks(spatial_blocks == 0) = 1;  # Handle edge cases
end

function connectivity_matrix = calculate_inter_block_connectivity(G, fault_blocks, pressure_field)
% Calculate connectivity between fault blocks based on pressure communication
    num_blocks = max(fault_blocks);
    connectivity_matrix = zeros(num_blocks, num_blocks);
    
    for i = 1:num_blocks
        for j = i+1:num_blocks
            block_i_cells = find(fault_blocks == i);
            block_j_cells = find(fault_blocks == j);
            
            if ~isempty(block_i_cells) && ~isempty(block_j_cells)
                pressure_i = mean(pressure_field(block_i_cells));
                pressure_j = mean(pressure_field(block_j_cells));
                pressure_diff = abs(pressure_i - pressure_j);
                
                # Connectivity inversely related to pressure difference
                connectivity = 1 / (1 + pressure_diff / 1e5);  # Normalize by 1 bar
                connectivity_matrix(i, j) = connectivity;
                connectivity_matrix(j, i) = connectivity;
            end
        end
    end
    
    # Diagonal elements (self-connectivity)
    for i = 1:num_blocks
        connectivity_matrix(i, i) = 1.0;
    end
end

function write_reservoir_summary_file(filename, reservoir_results)
% Write comprehensive reservoir analysis summary

    fid = fopen(filename, 'w');
    if fid == -1
        error('Cannot open file for writing: %s', filename);
    end
    
    try
        fprintf(fid, 'EAGLE WEST FIELD - RESERVOIR ANALYSIS SUMMARY\n');
        fprintf(fid, '=============================================\n');
        fprintf(fid, 'Generated: %s\n\n', datestr(now));
        
        # Pressure analysis summary
        if isfield(reservoir_results, 'pressure_analysis')
            pressure = reservoir_results.pressure_analysis;
            fprintf(fid, 'PRESSURE ANALYSIS:\n');
            fprintf(fid, '  Average Pressure Decline: %.1f bar (%.1f%%)\n', ...
                pressure.average_pressure_decline_bar, pressure.average_pressure_decline_percent);
            fprintf(fid, '  Maximum Depletion: %.1f bar (Cell %d)\n', ...
                pressure.max_depletion_bar, pressure.max_depletion_cell);
            fprintf(fid, '  Minimum Depletion: %.1f bar (Cell %d)\n', ...
                pressure.min_depletion_bar, pressure.min_depletion_cell);
            fprintf(fid, '\n');
        end
        
        # Saturation analysis summary
        if isfield(reservoir_results, 'saturation_analysis')
            saturation = reservoir_results.saturation_analysis;
            fprintf(fid, 'SATURATION ANALYSIS:\n');
            fprintf(fid, '  Oil Recovery Fraction: %.1f%%\n', saturation.oil_recovery_fraction * 100);
            fprintf(fid, '  Drainage Zone: %.1f%% of reservoir\n', saturation.drainage_zone_fraction * 100);
            fprintf(fid, '  Remaining Oil: %.1f MMstb\n', saturation.remaining_oil_mmstb);
            fprintf(fid, '  Bypassed Oil: %.1f%% of reservoir\n', saturation.bypassed_oil_fraction * 100);
            fprintf(fid, '\n');
        end
        
        # Sweep efficiency summary
        if isfield(reservoir_results, 'sweep_analysis')
            sweep = reservoir_results.sweep_analysis;
            fprintf(fid, 'SWEEP EFFICIENCY ANALYSIS:\n');
            fprintf(fid, '  Field Sweep Efficiency: %.1f%%\n', sweep.field_sweep_efficiency * 100);
            fprintf(fid, '  Field Displacement Efficiency: %.1f%%\n', sweep.field_displacement_efficiency * 100);
            fprintf(fid, '  Overall Recovery Efficiency: %.1f%%\n', sweep.field_recovery_efficiency * 100);
            fprintf(fid, '\n');
        end
        
        # Energy analysis summary
        if isfield(reservoir_results, 'energy_analysis')
            energy = reservoir_results.energy_analysis;
            fprintf(fid, 'ENERGY ANALYSIS:\n');
            fprintf(fid, '  Primary Drive Mechanism: %s\n', energy.primary_drive_mechanism);
            if isfield(energy, 'drive_indices')
                fprintf(fid, '  Gas Drive Index: %.1f%%\n', energy.drive_indices.gas_drive_index * 100);
                fprintf(fid, '  Water Drive Index: %.1f%%\n', energy.drive_indices.water_drive_index * 100);
                fprintf(fid, '  Depletion Drive Index: %.1f%%\n', energy.drive_indices.depletion_drive_index * 100);
            end
            fprintf(fid, '\n');
        end
        
        fclose(fid);
        
    catch ME
        fclose(fid);
        error('Error writing reservoir summary: %s', ME.message);
    end

end

# Main execution when called as script
if ~nargout
    reservoir_results = s25_reservoir_analysis();
end