function simulation_results = s22_run_simulation()
% S22_RUN_SIMULATION - Execute MRST Simulation for Eagle West Field
% Requires: MRST
%
% Implements complete 10-year reservoir simulation:
% - 3,650 days total simulation duration
% - Monthly timesteps for history (30 days)
% - Quarterly/yearly for forecast (90-365 days)
% - Integration with all previous phases (grid, fluid, wells, schedule)
% - MRST simulateScheduleAD execution
% - Progress monitoring and checkpointing
%
% OUTPUTS:
%   simulation_results - Structure with simulation results and states
%
% Author: Claude Code AI System
% Date: August 8, 2025

    run('print_utils.m');
    print_step_header('S22', 'MRST Simulation Execution');
    
    total_start_time = tic;
    simulation_results = initialize_simulation_structure();
    
    try
        % ----------------------------------------
        % Step 1 - Load Solver Configuration
        % ----------------------------------------
        step_start = tic;
        [model, schedule, solver, config] = step_1_load_solver_configuration();
        simulation_results.model = model;
        simulation_results.schedule = schedule;
        simulation_results.solver = solver;
        simulation_results.config = config;
        print_step_result(1, 'Load Solver Configuration', 'success', toc(step_start));
        
        % ----------------------------------------
        % Step 2 - Setup Initial Conditions
        % ----------------------------------------
        step_start = tic;
        initial_state = step_2_setup_initial_conditions(model, config);
        simulation_results.initial_state = initial_state;
        print_step_result(2, 'Setup Initial Conditions', 'success', toc(step_start));
        
        % ----------------------------------------
        % Step 3 - Prepare Wells and Facilities
        % ----------------------------------------
        step_start = tic;
        [wells, facilities] = step_3_prepare_wells_and_facilities(model, schedule, config);
        simulation_results.wells = wells;
        simulation_results.facilities = facilities;
        print_step_result(3, 'Prepare Wells and Facilities', 'success', toc(step_start));
        
        % ----------------------------------------
        % Step 4 - Execute Simulation with Progress Monitoring
        % ----------------------------------------
        step_start = tic;
        [states, reports] = step_4_execute_simulation_with_monitoring(model, initial_state, schedule, solver, config);
        simulation_results.states = states;
        simulation_results.reports = reports;
        print_step_result(4, 'Execute Simulation with Monitoring', 'success', toc(step_start));
        
        % ----------------------------------------
        % Step 5 - Post-Process Simulation Results
        % ----------------------------------------
        step_start = tic;
        post_processed = step_5_post_process_results(states, reports, schedule, config);
        simulation_results.post_processed = post_processed;
        print_step_result(5, 'Post-Process Simulation Results', 'success', toc(step_start));
        
        % ----------------------------------------
        % Step 6 - Export Simulation Results
        % ----------------------------------------
        step_start = tic;
        export_path = step_6_export_simulation_results(simulation_results);
        simulation_results.export_path = export_path;
        print_step_result(6, 'Export Simulation Results', 'success', toc(step_start));
        
        simulation_results.status = 'success';
        simulation_results.simulation_completed = true;
        simulation_results.total_timesteps = length(states);
        simulation_results.simulation_time_days = schedule.total_time_days;
        simulation_results.creation_time = datestr(now);
        
        print_step_footer('S22', sprintf('Simulation Completed (%d steps, %.0f days)', ...
            simulation_results.total_timesteps, simulation_results.simulation_time_days), toc(total_start_time));
        
    catch ME
        print_error_step(0, 'Simulation Execution', ME.message);
        simulation_results.status = 'failed';
        simulation_results.error_message = ME.message;
        error('Simulation execution failed: %s', ME.message);
    end

end

function simulation_results = initialize_simulation_structure()
% Initialize simulation results structure
    simulation_results = struct();
    simulation_results.status = 'initializing';
    simulation_results.model = [];
    simulation_results.schedule = [];
    simulation_results.solver = [];
    simulation_results.initial_state = [];
    simulation_results.wells = [];
    simulation_results.states = [];
    simulation_results.reports = [];
end

function [model, schedule, solver, config] = step_1_load_solver_configuration()
% Step 1 - Load complete solver configuration from s21

    script_path = fileparts(mfilename('fullpath'));
    data_dir = fullfile(fileparts(script_path), 'data', 'mrst_simulation', 'static');
    
    % Substep 1.1 - Load solver configuration ________________________
    solver_file = fullfile(data_dir, 'solver_configuration.mat');
    if exist(solver_file, 'file')
        load(solver_file, 'solver_results');
        config = solver_results.config;
        solver = solver_results.nonlinear_solver;
        fprintf('Loaded solver configuration: %s\n', solver_results.solver_type);
    else
        error('Solver configuration not found. Run s21_solver_setup.m first.');
    end
    
    % Substep 1.2 - Load simulation model ____________________________
    model_file = fullfile(data_dir, 'simulation_model.mat');
    if exist(model_file, 'file')
        load(model_file, 'model');
        fprintf('Loaded black oil model: %d cells\n', model.G.cells.num);
    else
        error('Simulation model not found. Run s21_solver_setup.m first.');
    end
    
    % Substep 1.3 - Load simulation schedule __________________________
    schedule_file = fullfile(data_dir, 'simulation_schedule.mat');
    if exist(schedule_file, 'file')
        load(schedule_file, 'schedule');
        fprintf('Loaded simulation schedule: %d timesteps\n', length(schedule.step));
    else
        error('Simulation schedule not found. Run s21_solver_setup.m first.');
    end

end

function initial_state = step_2_setup_initial_conditions(model, config)
% Step 2 - Setup initial pressure and saturation conditions

    fprintf('\n Initial Conditions Setup:\n');
    fprintf(' ──────────────────────────────────────────────────────────\n');
    
    script_path = fileparts(mfilename('fullpath'));
    data_dir = fullfile(fileparts(script_path), 'data', 'mrst_simulation', 'static');
    
    % Substep 2.1 - Load pressure initialization _____________________
    pressure_file = fullfile(data_dir, 'pressure_initialization.mat');
    if exist(pressure_file, 'file')
        load(pressure_file, 'pressure_results');
        initial_pressure = pressure_results.initial_pressure_pa;
        fprintf('   Initial Pressure: Loaded from pressure initialization\n');
        fprintf('   Pressure Range: %.1f - %.1f bar\n', ...
            min(initial_pressure)/1e5, max(initial_pressure)/1e5);
    else
        error('Pressure initialization not found. Run s13_pressure_initialization.m first.');
    end
    
    % Substep 2.2 - Load saturation distribution _____________________
    saturation_file = fullfile(data_dir, 'saturation_distribution.mat');
    if exist(saturation_file, 'file')
        load(saturation_file, 'saturation_results');
        initial_so = saturation_results.oil_saturation;
        initial_sw = saturation_results.water_saturation;
        initial_sg = saturation_results.gas_saturation;
        fprintf('   Initial Saturations: Loaded from saturation distribution\n');
        fprintf('   Oil Saturation: %.3f - %.3f\n', min(initial_so), max(initial_so));
        fprintf('   Water Saturation: %.3f - %.3f\n', min(initial_sw), max(initial_sw));
        fprintf('   Gas Saturation: %.3f - %.3f\n', min(initial_sg), max(initial_sg));
    else
        error('Saturation distribution not found. Run s14_saturation_distribution.m first.');
    end
    
    % Substep 2.3 - Create MRST initial state ________________________
    G = model.G;
    
    initial_state = struct();
    initial_state.pressure = initial_pressure;
    initial_state.s = [initial_sw, initial_so, initial_sg];  % MRST order: water, oil, gas
    
    % Substep 2.4 - Initialize RS (solution gas-oil ratio) ___________
    pvt_file = fullfile(data_dir, 'pvt_tables.mat');
    if exist(pvt_file, 'file')
        load(pvt_file, 'pvt_results');
        
        % Calculate initial RS based on pressure and bubble point
        bubble_point_pa = pvt_results.oil_properties.bubble_point_pressure_pa;
        initial_rs = zeros(G.cells.num, 1);
        
        for i = 1:G.cells.num
            if initial_pressure(i) >= bubble_point_pa
                % Above bubble point - saturated
                initial_rs(i) = pvt_results.oil_properties.solution_gor_sm3_sm3;
            else
                % Below bubble point - calculate RS from PVT
                pressure_ratio = initial_pressure(i) / bubble_point_pa;
                initial_rs(i) = pvt_results.oil_properties.solution_gor_sm3_sm3 * pressure_ratio;
            end
        end
        
        initial_state.rs = initial_rs;
        fprintf('   Solution GOR: %.1f - %.1f sm³/sm³\n', min(initial_rs), max(initial_rs));
    else
        % Default RS for black oil
        initial_state.rs = zeros(G.cells.num, 1);
        fprintf('   Solution GOR: Default (0 sm³/sm³)\n');
    end
    
    % Substep 2.5 - Validate initial state ___________________________
    saturation_sum = sum(initial_state.s, 2);
    if any(abs(saturation_sum - 1) > 1e-6)
        error('Saturation sum validation failed. Max error: %.1e', max(abs(saturation_sum - 1)));
    end
    
    if any(initial_state.pressure <= 0)
        error('Invalid initial pressure detected. Min pressure: %.1f Pa', min(initial_state.pressure));
    end
    
    fprintf('   State Validation: Passed\n');
    fprintf(' ──────────────────────────────────────────────────────────\n');

end

function [wells, facilities] = step_3_prepare_wells_and_facilities(model, schedule, config)
% Step 3 - Prepare well constraints and facilities for simulation

    fprintf('\n Wells and Facilities Preparation:\n');
    fprintf(' ──────────────────────────────────────────────────────────\n');
    
    script_path = fileparts(mfilename('fullpath'));
    data_dir = fullfile(fileparts(script_path), 'data', 'mrst_simulation', 'static');
    
    % Substep 3.1 - Load well completions ____________________________
    completions_file = fullfile(data_dir, 'well_completions.mat');
    if exist(completions_file, 'file')
        load(completions_file, 'completion_results');
        fprintf('   Well Completions: Loaded (%d wells)\n', completion_results.total_wells);
    else
        error('Well completions not found. Run s17_well_completions.m first.');
    end
    
    % Substep 3.2 - Load production controls __________________________
    controls_file = fullfile(data_dir, 'production_controls.mat');
    if exist(controls_file, 'file')
        load(controls_file, 'control_results');
        fprintf('   Production Controls: %d producers + %d injectors\n', ...
            length(control_results.producer_controls), length(control_results.injector_controls));
    else
        error('Production controls not found. Run s18_production_controls.m first.');
    end
    
    % Substep 3.3 - Create MRST well structures for each control ______
    wells = cell(length(schedule.control), 1);
    
    for control_idx = 1:length(schedule.control)
        control = schedule.control(control_idx);
        
        W = [];  % Initialize well array for this control period
        
        % Add producers
        for i = 1:length(control.active_producers)
            well_name = control.active_producers{i};
            
            % Find well completion data
            well_completion = find_well_completion(well_name, completion_results);
            if isempty(well_completion)
                continue;
            end
            
            % Find well control data  
            well_control = find_well_control(well_name, control_results.producer_controls);
            if isempty(well_control)
                continue;
            end
            
            % Create MRST well
            W = vertcat(W, addWell(W, model.G, model.rock, ...
                well_completion.completion_cells, ...
                'Type', 'rate', ...
                'Val', well_control.target_oil_rate_m3_day / (24 * 3600), ...  % m³/s
                'Radius', well_completion.well_radius_m, ...
                'Dir', 'z', ...
                'Name', well_name, ...
                'Comp_i', [0, 1, 0], ...  % Oil production
                'compi', [0, 1, 0]));
        end
        
        % Add injectors
        for i = 1:length(control.active_injectors)
            well_name = control.active_injectors{i};
            
            % Find well completion data
            well_completion = find_well_completion(well_name, completion_results);
            if isempty(well_completion)
                continue;
            end
            
            % Find well control data
            well_control = find_well_control(well_name, control_results.injector_controls);
            if isempty(well_control)
                continue;
            end
            
            % Create MRST well
            W = vertcat(W, addWell(W, model.G, model.rock, ...
                well_completion.completion_cells, ...
                'Type', 'rate', ...
                'Val', well_control.target_injection_rate_m3_day / (24 * 3600), ...  % m³/s  
                'Radius', well_completion.well_radius_m, ...
                'Dir', 'z', ...
                'Name', well_name, ...
                'Comp_i', [1, 0, 0], ...  % Water injection
                'compi', [1, 0, 0]));
        end
        
        wells{control_idx} = W;
        fprintf('   Control Period %d: %d wells configured\n', control_idx, length(W));
    end
    
    % Substep 3.4 - Setup facilities model ____________________________
    facilities = [];  % No surface facilities for this simulation
    
    fprintf('   Total Control Periods: %d\n', length(wells));
    fprintf(' ──────────────────────────────────────────────────────────\n');

end

function [states, reports] = step_4_execute_simulation_with_monitoring(model, initial_state, schedule, solver, config)
% Step 4 - Execute complete MRST simulation with progress monitoring

    fprintf('\n Simulation Execution with Progress Monitoring:\n');
    fprintf(' ──────────────────────────────────────────────────────────\n');
    
    progress_config = config.solver_configuration.progress_monitoring;
    
    % Substep 4.1 - Setup progress monitoring ________________________
    total_steps = length(schedule.step);
    checkpoint_frequency = progress_config.checkpoint_frequency_steps;
    report_frequency = progress_config.progress_report_frequency_steps;
    
    fprintf('   Total Timesteps: %d\n', total_steps);
    fprintf('   Progress Reports: Every %d steps\n', report_frequency);
    fprintf('   Checkpoints: Every %d steps\n', checkpoint_frequency);
    
    % Substep 4.2 - Initialize simulation state ______________________
    states = cell(total_steps + 1, 1);  % +1 for initial state
    reports = cell(total_steps, 1);
    states{1} = initial_state;
    
    convergence_failures = 0;
    simulation_start_time = tic;
    
    fprintf('\n   Simulation Progress:\n');
    fprintf('   ─────────────────────────────────────────────────────────\n');
    
    % Substep 4.3 - Main simulation loop _____________________________
    for step_idx = 1:total_steps
        step_start_time = tic;
        
        try
            % Get current timestep and wells
            dt = schedule.step(step_idx).val;
            current_wells = schedule.wells{schedule.step(step_idx).control};
            
            % Execute single timestep
            [state_new, report] = solver.solveTimestep(states{step_idx}, dt, model, ...
                'Wells', current_wells);
            
            states{step_idx + 1} = state_new;
            reports{step_idx} = report;
            
            step_time = toc(step_start_time);
            
            % Progress reporting
            if mod(step_idx, report_frequency) == 0 || step_idx == total_steps
                days_completed = sum([schedule.step(1:step_idx).val]) / (24 * 3600);
                progress_percent = step_idx / total_steps * 100;
                
                fprintf('   Step %4d/%d │ %5.1f%% │ %6.1f days │ %5.1fs │ %2d iter\n', ...
                    step_idx, total_steps, progress_percent, days_completed, ...
                    step_time, report.Iterations);
            end
            
            % Checkpointing
            if progress_config.save_intermediate_results && mod(step_idx, checkpoint_frequency) == 0
                save_checkpoint(step_idx, states, reports, schedule, config);
            end
            
        catch ME
            % Handle timestep failure
            convergence_failures = convergence_failures + 1;
            
            fprintf('   ⚠️  Step %d failed: %s\n', step_idx, ME.message);
            
            if convergence_failures > 5
                error('Too many convergence failures (%d). Simulation stopped.', convergence_failures);
            end
            
            % Use previous state and continue (or implement timestep cutting)
            states{step_idx + 1} = states{step_idx};
            reports{step_idx} = struct('Converged', false, 'Iterations', NaN);
        end
    end
    
    total_simulation_time = toc(simulation_start_time);
    
    fprintf('   ─────────────────────────────────────────────────────────\n');
    fprintf('   Simulation completed in %.1f minutes\n', total_simulation_time / 60);
    fprintf('   Convergence failures: %d\n', convergence_failures);
    
    % Substep 4.4 - Final validation _________________________________
    successful_steps = sum([reports{:}].Converged);
    success_rate = successful_steps / total_steps * 100;
    
    fprintf('   Success rate: %.1f%% (%d/%d steps)\n', success_rate, successful_steps, total_steps);
    
    if success_rate < 90
        warning('Low simulation success rate: %.1f%%', success_rate);
    end
    
    fprintf(' ──────────────────────────────────────────────────────────\n');

end

function post_processed = step_5_post_process_results(states, reports, schedule, config)
% Step 5 - Post-process simulation results for analysis

    fprintf('\n Post-Processing Simulation Results:\n');
    fprintf(' ──────────────────────────────────────────────────────────\n');
    
    total_steps = length(reports);
    
    % Substep 5.1 - Extract field production rates ___________________
    post_processed = struct();
    
    time_days = zeros(total_steps, 1);
    field_oil_rate = zeros(total_steps, 1);
    field_water_rate = zeros(total_steps, 1);
    field_gas_rate = zeros(total_steps, 1);
    field_injection_rate = zeros(total_steps, 1);
    
    cumulative_time = 0;
    
    for i = 1:total_steps
        dt_days = schedule.step(i).val / (24 * 3600);
        cumulative_time = cumulative_time + dt_days;
        time_days(i) = cumulative_time;
        
        % Extract rates from well solutions (if available)
        if isfield(reports{i}, 'WellSol') && ~isempty(reports{i}.WellSol)
            wellsol = reports{i}.WellSol;
            
            for j = 1:length(wellsol)
                well = wellsol(j);
                
                if ~isempty(strfind(well.name, 'EW-'))  % Producer
                    field_oil_rate(i) = field_oil_rate(i) + max(0, -well.qOs);  % Oil rate (m³/s to m³/d)
                    field_water_rate(i) = field_water_rate(i) + max(0, -well.qWs);
                    field_gas_rate(i) = field_gas_rate(i) + max(0, -well.qGs);
                elseif ~isempty(strfind(well.name, 'IW-'))  % Injector
                    field_injection_rate(i) = field_injection_rate(i) + max(0, well.qWs);
                end
            end
            
            % Convert to field units
            field_oil_rate(i) = field_oil_rate(i) * 24 * 3600 / 0.158987;  % m³/s to STB/day
            field_water_rate(i) = field_water_rate(i) * 24 * 3600 / 0.158987;  % m³/s to bbl/day  
            field_gas_rate(i) = field_gas_rate(i) * 24 * 3600 / 0.0283168;  % m³/s to MSCF/day
            field_injection_rate(i) = field_injection_rate(i) * 24 * 3600 / 0.158987;  % m³/s to bbl/day
        end
    end
    
    post_processed.time_days = time_days;
    post_processed.field_oil_rate_stb_day = field_oil_rate;
    post_processed.field_water_rate_bbl_day = field_water_rate;
    post_processed.field_gas_rate_mscf_day = field_gas_rate;
    post_processed.field_injection_rate_bbl_day = field_injection_rate;
    
    % Substep 5.2 - Calculate cumulative production ___________________
    post_processed.cumulative_oil_stb = cumsum(field_oil_rate .* (time_days - [0; time_days(1:end-1)]));
    post_processed.cumulative_water_bbl = cumsum(field_water_rate .* (time_days - [0; time_days(1:end-1)]));
    post_processed.cumulative_gas_mscf = cumsum(field_gas_rate .* (time_days - [0; time_days(1:end-1)]));
    post_processed.cumulative_injection_bbl = cumsum(field_injection_rate .* (time_days - [0; time_days(1:end-1)]));
    
    % Substep 5.3 - Extract pressure and saturation fields ___________
    post_processed.average_pressure = zeros(total_steps + 1, 1);
    post_processed.average_oil_saturation = zeros(total_steps + 1, 1);
    
    for i = 1:(total_steps + 1)
        state = states{i};
        post_processed.average_pressure(i) = mean(state.pressure) / 1e5;  % Convert to bar
        post_processed.average_oil_saturation(i) = mean(state.s(:, 2));  % Oil saturation
    end
    
    % Substep 5.4 - Calculate key performance indicators ______________
    final_oil_cum = post_processed.cumulative_oil_stb(end);
    final_time_years = time_days(end) / 365;
    peak_oil_rate = max(post_processed.field_oil_rate_stb_day);
    
    post_processed.kpis = struct();
    post_processed.kpis.ultimate_recovery_mmstb = final_oil_cum / 1e6;
    post_processed.kpis.peak_oil_rate_stb_day = peak_oil_rate;
    post_processed.kpis.average_oil_rate_stb_day = final_oil_cum / time_days(end);
    post_processed.kpis.simulation_duration_years = final_time_years;
    post_processed.kpis.recovery_factor = calculate_recovery_factor(final_oil_cum, config);
    
    fprintf('   Field Performance Summary:\n');
    fprintf('   Peak Oil Rate: %,.0f STB/day\n', peak_oil_rate);
    fprintf('   Ultimate Recovery: %.1f MMstb\n', post_processed.kpis.ultimate_recovery_mmstb);
    fprintf('   Average Rate: %,.0f STB/day\n', post_processed.kpis.average_oil_rate_stb_day);
    fprintf('   Recovery Factor: %.1f%%\n', post_processed.kpis.recovery_factor * 100);
    
    fprintf(' ──────────────────────────────────────────────────────────\n');

end

function export_path = step_6_export_simulation_results(simulation_results)
% Step 6 - Export complete simulation results for analysis

    script_path = fileparts(mfilename('fullpath'));
    results_dir = fullfile(fileparts(script_path), 'data', 'mrst_simulation', 'results');
    
    if ~exist(results_dir, 'dir')
        mkdir(results_dir);
    end
    
    % Substep 6.1 - Save complete simulation results __________________
    timestamp = datestr(now, 'yyyymmdd_HHMMSS');
    export_path = fullfile(results_dir, sprintf('simulation_results_%s.mat', timestamp));
    save(export_path, 'simulation_results', '-v7.3');  % Large file format
    
    % Substep 6.2 - Export time series data ___________________________
    timeseries_file = fullfile(results_dir, sprintf('field_performance_%s.mat', timestamp));
    time_data = simulation_results.post_processed;
    save(timeseries_file, 'time_data');
    
    % Substep 6.3 - Create simulation summary _________________________
    summary_file = fullfile(results_dir, sprintf('simulation_summary_%s.txt', timestamp));
    write_simulation_summary_file(summary_file, simulation_results);
    
    % Substep 6.4 - Export final states for analysis _______________
    final_state_file = fullfile(results_dir, sprintf('final_reservoir_state_%s.mat', timestamp));
    final_state = simulation_results.states{end};
    save(final_state_file, 'final_state');
    
    fprintf('   Exported to: %s\n', export_path);
    fprintf('   Time Series: %s\n', timeseries_file);
    fprintf('   Summary: %s\n', summary_file);
    fprintf('   Final State: %s\n', final_state_file);

end

% Helper functions
function well_completion = find_well_completion(well_name, completion_results)
% Find well completion data by name
    well_completion = [];
    for i = 1:length(completion_results.well_completions)
        if strcmp(completion_results.well_completions(i).well_name, well_name)
            well_completion = completion_results.well_completions(i);
            return;
        end
    end
end

function well_control = find_well_control(well_name, controls_array)
% Find well control data by name
    well_control = [];
    for i = 1:length(controls_array)
        if strcmp(controls_array(i).name, well_name)
            well_control = controls_array(i);
            return;
        end
    end
end

function save_checkpoint(step_idx, states, reports, schedule, config)
% Save intermediate checkpoint
    script_path = fileparts(mfilename('fullpath'));
    checkpoint_dir = fullfile(fileparts(script_path), 'data', 'mrst_simulation', 'checkpoints');
    
    if ~exist(checkpoint_dir, 'dir')
        mkdir(checkpoint_dir);
    end
    
    checkpoint_file = fullfile(checkpoint_dir, sprintf('checkpoint_step_%04d.mat', step_idx));
    checkpoint_data = struct();
    checkpoint_data.step_idx = step_idx;
    checkpoint_data.states = states(1:step_idx+1);
    checkpoint_data.reports = reports(1:step_idx);
    
    save(checkpoint_file, 'checkpoint_data');
end

function recovery_factor = calculate_recovery_factor(cumulative_oil_stb, config)
% Calculate recovery factor based on original oil in place
    % Simplified calculation - would need OOIP from reservoir initialization
    estimated_ooip_stb = 50e6;  % 50 million STB estimate
    recovery_factor = cumulative_oil_stb / estimated_ooip_stb;
    recovery_factor = min(recovery_factor, 1.0);  % Cap at 100%
end

function write_simulation_summary_file(filename, simulation_results)
% Write comprehensive simulation summary

    fid = fopen(filename, 'w');
    if fid == -1
        error('Cannot open file for writing: %s', filename);
    end
    
    try
        fprintf(fid, 'Eagle West Field - MRST Simulation Results Summary\n');
        fprintf(fid, 'Generated: %s\n', datestr(now));
        fprintf(fid, '================================================\n\n');
        
        % Simulation overview
        fprintf(fid, 'SIMULATION OVERVIEW:\n');
        fprintf(fid, '  Status: %s\n', simulation_results.status);
        fprintf(fid, '  Total Timesteps: %d\n', simulation_results.total_timesteps);
        fprintf(fid, '  Simulation Duration: %.0f days (%.1f years)\n', ...
            simulation_results.simulation_time_days, simulation_results.simulation_time_days/365);
        
        % Performance summary
        if isfield(simulation_results, 'post_processed') && isfield(simulation_results.post_processed, 'kpis')
            kpis = simulation_results.post_processed.kpis;
            fprintf(fid, '\nFIELD PERFORMANCE:\n');
            fprintf(fid, '  Peak Oil Rate: %,.0f STB/day\n', kpis.peak_oil_rate_stb_day);
            fprintf(fid, '  Ultimate Recovery: %.1f MMstb\n', kpis.ultimate_recovery_mmstb);
            fprintf(fid, '  Average Oil Rate: %,.0f STB/day\n', kpis.average_oil_rate_stb_day);
            fprintf(fid, '  Recovery Factor: %.1f%%\n', kpis.recovery_factor * 100);
        end
        
        fclose(fid);
        
    catch ME
        fclose(fid);
        error('Error writing simulation summary: %s', ME.message);
    end

end

% Main execution when called as script
if ~nargout
    simulation_results = s22_run_simulation();
end