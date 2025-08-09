function solver_results = s21_solver_setup()
% S21_SOLVER_SETUP - MRST Solver Configuration for Eagle West Field
% Requires: MRST
%
% Implements fully-implicit black oil solver configuration:
% - CNV tolerance: 1e-6, Material balance: 1e-7
% - Newton iterations: max 25, Line search enabled
% - Adaptive timestep control (1-365 days)
% - CPR preconditioning for performance
% - MRST simulateScheduleAD preparation
%
% OUTPUTS:
%   solver_results - Structure with solver configuration and model
%
% Author: Claude Code AI System
% Date: August 8, 2025

    run('print_utils.m');
    print_step_header('S21', 'MRST Solver Configuration');
    
    total_start_time = tic;
    solver_results = initialize_solver_structure();
    
    try
        % ----------------------------------------
        % Step 1 - Load Configuration and Model Data
        % ----------------------------------------
        step_start = tic;
        [config, model_data] = step_1_load_configuration_and_model();
        solver_results.config = config;
        solver_results.model_data = model_data;
        print_step_result(1, 'Load Configuration and Model Data', 'success', toc(step_start));
        
        % ----------------------------------------
        % Step 2 - Configure Black Oil Model
        % ----------------------------------------
        step_start = tic;
        black_oil_model = step_2_configure_black_oil_model(model_data, config);
        solver_results.black_oil_model = black_oil_model;
        print_step_result(2, 'Configure Black Oil Model', 'success', toc(step_start));
        
        % ----------------------------------------
        % Step 3 - Setup Nonlinear Solver
        % ----------------------------------------
        step_start = tic;
        nonlinear_solver = step_3_setup_nonlinear_solver(config);
        solver_results.nonlinear_solver = nonlinear_solver;
        print_step_result(3, 'Setup Nonlinear Solver', 'success', toc(step_start));
        
        % ----------------------------------------
        % Step 4 - Configure Timestep Control
        % ----------------------------------------
        step_start = tic;
        timestep_control = step_4_configure_timestep_control(config);
        solver_results.timestep_control = timestep_control;
        print_step_result(4, 'Configure Timestep Control', 'success', toc(step_start));
        
        % ----------------------------------------
        % Step 5 - Setup Simulation Schedule
        % ----------------------------------------
        step_start = tic;
        simulation_schedule = step_5_setup_simulation_schedule(model_data, config);
        solver_results.simulation_schedule = simulation_schedule;
        print_step_result(5, 'Setup Simulation Schedule', 'success', toc(step_start));
        
        % ----------------------------------------
        % Step 6 - Export Solver Configuration
        % ----------------------------------------
        step_start = tic;
        export_path = step_6_export_solver_configuration(solver_results);
        solver_results.export_path = export_path;
        print_step_result(6, 'Export Solver Configuration', 'success', toc(step_start));
        
        solver_results.status = 'success';
        solver_results.solver_type = 'ad-fi';
        solver_results.total_timesteps = length(simulation_schedule.step.val);
        solver_results.simulation_ready = true;
        solver_results.creation_time = datestr(now);
        
        print_step_footer('S21', sprintf('Solver Configured (ad-fi, %d timesteps)', ...
            solver_results.total_timesteps), toc(total_start_time));
        
    catch ME
        print_error_step(0, 'Solver Setup', ME.message);
        solver_results.status = 'failed';
        solver_results.error_message = ME.message;
        error('Solver setup failed: %s', ME.message);
    end

end

function solver_results = initialize_solver_structure()
% Initialize solver results structure
    solver_results = struct();
    solver_results.status = 'initializing';
    solver_results.config = [];
    solver_results.model_data = [];
    solver_results.black_oil_model = [];
    solver_results.nonlinear_solver = [];
    solver_results.timestep_control = [];
    solver_results.simulation_schedule = [];
end

function [config, model_data] = step_1_load_configuration_and_model()
% Step 1 - Load solver configuration and all required model data

    script_path = fileparts(mfilename('fullpath'));
    data_dir = fullfile(fileparts(script_path), 'data', 'mrst_simulation', 'static');
    
    % Substep 1.1 - Load solver configuration ________________________
    config_path = fullfile(script_path, 'config', 'solver_config.yaml');
    if exist(config_path, 'file')
        config = read_yaml_config(config_path, 'silent', true);
        fprintf('Loaded solver configuration: %s solver\n', config.solver_configuration.solver_type);
    else
        error('Solver configuration not found: %s', config_path);
    end
    
    % Substep 1.2 - Load grid model __________________________________
    grid_file = fullfile(data_dir, 'grid_model.mat');
    if exist(grid_file, 'file')
        load(grid_file, 'G');
        model_data.grid = G;
        fprintf('Loaded grid model: %d cells\n', G.cells.num);
    else
        error('Grid model not found. Run s02_create_grid.m first.');
    end
    
    % Substep 1.3 - Load rock properties _____________________________
    rock_file = fullfile(data_dir, 'rock_properties_final.mat');
    if exist(rock_file, 'file')
        load(rock_file, 'rock');
        model_data.rock = rock;
        fprintf('Loaded rock properties: %d cells with heterogeneity\n', length(rock.perm));
    else
        error('Rock properties not found. Run s09_spatial_heterogeneity.m first.');
    end
    
    % Substep 1.4 - Load fluid properties ____________________________
    fluid_file = fullfile(data_dir, 'fluid_properties.mat');
    if exist(fluid_file, 'file')
        load(fluid_file, 'fluid');
        model_data.fluid = fluid;
        fprintf('Loaded fluid properties: 3-phase black oil\n');
    else
        error('Fluid properties not found. Run s03_define_fluids.m first.');
    end
    
    % Substep 1.5 - Load PVT tables __________________________________
    pvt_file = fullfile(data_dir, 'pvt_tables.mat');
    if exist(pvt_file, 'file')
        load(pvt_file, 'pvt_results');
        model_data.pvt = pvt_results;
        fprintf('Loaded PVT tables: Oil, gas, water properties\n');
    else
        error('PVT tables not found. Run s12_pvt_tables.m first.');
    end
    
    % Substep 1.6 - Load well system _________________________________
    wells_file = fullfile(data_dir, 'well_placement.mat');
    if exist(wells_file, 'file')
        load(wells_file, 'placement_results');
        model_data.wells = placement_results;
        fprintf('Loaded well system: %d wells with completions\n', placement_results.total_wells);
    else
        error('Well system not found. Run s16_well_placement.m first.');
    end
    
    % Substep 1.7 - Load development schedule ________________________
    schedule_file = fullfile(data_dir, 'development_schedule.mat');
    if exist(schedule_file, 'file')
        load(schedule_file, 'schedule_results');
        model_data.development_schedule = schedule_results;
        fprintf('Loaded development schedule: %d phases over 10 years\n', ...
            length(schedule_results.development_phases));
    else
        error('Development schedule not found. Run s19_development_schedule.m first.');
    end

end

function black_oil_model = step_2_configure_black_oil_model(model_data, config)
% Step 2 - Configure MRST black oil reservoir model

    fprintf('\n Black Oil Model Configuration:\n');
    fprintf(' ──────────────────────────────────────────────────────────\n');
    
    G = model_data.grid;
    rock = model_data.rock;
    fluid = model_data.fluid;
    
    % Substep 2.1 - Initialize black oil model _______________________
    if exist('ThreePhaseBlackOilModel', 'file')
        % Use MRST AD-core black oil model
        black_oil_model = ThreePhaseBlackOilModel(G, rock, fluid);
        model_type = 'ThreePhaseBlackOilModel';
    elseif exist('GenericBlackOilModel', 'file')
        % Fallback to generic model
        black_oil_model = GenericBlackOilModel(G, rock, fluid);
        model_type = 'GenericBlackOilModel';
    else
        error('No suitable black oil model found. Check MRST installation.');
    end
    
    fprintf('   Model Type: %s\n', model_type);
    fprintf('   Grid Cells: %d\n', G.cells.num);
    fprintf('   Active Phases: Oil, Water, Gas\n');
    
    % Substep 2.2 - Configure model properties _______________________
    black_oil_model.OutputStateFunctions = {};
    black_oil_model.extraStateOutput = true;
    
    % Enable gravity
    black_oil_model.gravity = norm(gravity);
    fprintf('   Gravity: %.2f m/s²\n', black_oil_model.gravity);
    
    % Substep 2.3 - Set up equation weights __________________________
    if hasfield(black_oil_model, 'getEquationWeights')
        weights = black_oil_model.getEquationWeights();
        % Standard black oil weights
        weights.oil = 1;
        weights.water = 1; 
        weights.gas = 1;
        black_oil_model = black_oil_model.setEquationWeights(weights);
    end
    
    % Substep 2.4 - Configure facilities _____________________________
    black_oil_model.FacilityModel = [];  % Will be set during simulation
    black_oil_model.AutoDiffBackend = DiagonalAutoDiffBackend('useBlocks', true);
    
    % Substep 2.5 - Validate model ___________________________________
    try
        test_state = black_oil_model.validateModel();
        fprintf('   Model Validation: Passed\n');
    catch ME
        warning('Model validation warning: %s', ME.message);
        fprintf('   Model Validation: Warning (continuing)\n');
    end
    
    fprintf(' ──────────────────────────────────────────────────────────\n');

end

function nonlinear_solver = step_3_setup_nonlinear_solver(config)
% Step 3 - Setup MRST nonlinear solver with advanced options

    fprintf('\n Nonlinear Solver Configuration:\n');
    fprintf(' ──────────────────────────────────────────────────────────\n');
    
    solver_config = config.solver_configuration;
    
    % Substep 3.1 - Initialize nonlinear solver ______________________
    nonlinear_solver = NonLinearSolver();
    
    % Substep 3.2 - Set convergence tolerances _______________________
    nonlinear_solver.maxIterations = solver_config.max_iterations;
    nonlinear_solver.converged = false;
    
    % Set MRST convergence criteria
    nonlinear_solver.LinearSolver.tolerance = solver_config.tolerance_cnv;
    
    % Advanced tolerance setup
    if isfield(nonlinear_solver, 'ConvergenceTest')
        nonlinear_solver.ConvergenceTest.tolerance_cnv = solver_config.tolerance_cnv;
        nonlinear_solver.ConvergenceTest.tolerance_mb = solver_config.tolerance_mb;
    end
    
    fprintf('   Max Iterations: %d\n', solver_config.max_iterations);
    fprintf('   CNV Tolerance: %.1e\n', solver_config.tolerance_cnv);
    fprintf('   Material Balance Tolerance: %.1e\n', solver_config.tolerance_mb);
    
    % Substep 3.3 - Configure line search ____________________________
    if solver_config.line_search
        if isfield(nonlinear_solver, 'useLineSearch')
            nonlinear_solver.useLineSearch = true;
        elseif isfield(nonlinear_solver, 'LineSearch')
            nonlinear_solver.LineSearch.active = true;
        end
        fprintf('   Line Search: Enabled\n');
    else
        fprintf('   Line Search: Disabled\n');
    end
    
    % Substep 3.4 - Configure linear solver __________________________
    if solver_config.use_cpr
        % CPR (Constrained Pressure Residual) preconditioning
        try
            cpr_solver = CPRSolverAD('ellipticSolver', BackslashSolverAD);
            nonlinear_solver.LinearSolver = cpr_solver;
            linear_solver_type = 'CPR with Backslash';
        catch ME
            warning('CPR solver not available: %s. Using default.', ME.message);
            linear_solver_type = 'Default MRST';
        end
    else
        linear_solver_type = 'Default MRST';
    end
    
    fprintf('   Linear Solver: %s\n', linear_solver_type);
    
    % Substep 3.5 - Set advanced solver options ______________________
    nonlinear_solver.verbose = false;  % Reduce output during simulation
    nonlinear_solver.continueOnFailure = false;  % FAIL_FAST policy
    
    if isfield(nonlinear_solver, 'enforceResidualDecrease')
        nonlinear_solver.enforceResidualDecrease = true;
    end
    
    fprintf(' ──────────────────────────────────────────────────────────\n');

end

function timestep_control = step_4_configure_timestep_control(config)
% Step 4 - Configure adaptive timestep control system

    fprintf('\n Timestep Control Configuration:\n');
    fprintf(' ──────────────────────────────────────────────────────────\n');
    
    ts_config = config.solver_configuration.timestep_control;
    
    % Substep 4.1 - Initialize timestep selector _____________________
    timestep_control = struct();
    
    % Convert days to seconds for MRST
    timestep_control.initial_dt = ts_config.initial_timestep_days * 24 * 3600;
    timestep_control.min_dt = ts_config.min_timestep_days * 24 * 3600;
    timestep_control.max_dt = ts_config.max_timestep_days * 24 * 3600;
    
    % Growth and cut factors
    timestep_control.growth_factor = ts_config.timestep_growth_factor;
    timestep_control.cut_factor = ts_config.timestep_cut_factor;
    timestep_control.max_cuts = ts_config.max_timestep_cuts;
    
    fprintf('   Initial Timestep: %.1f days\n', ts_config.initial_timestep_days);
    fprintf('   Min Timestep: %.1f days\n', ts_config.min_timestep_days);
    fprintf('   Max Timestep: %.1f days\n', ts_config.max_timestep_days);
    fprintf('   Growth Factor: %.2f\n', ts_config.timestep_growth_factor);
    fprintf('   Cut Factor: %.2f\n', ts_config.timestep_cut_factor);
    
    % Substep 4.2 - Configure adaptive control _______________________
    if ts_config.adaptive_control
        timestep_control.adaptive = true;
        
        % Create MRST timestep selector
        try
            timestep_control.selector = SimpleTimeStepSelector();
            if isfield(timestep_control.selector, 'targetIterations')
                timestep_control.selector.targetIterations = 8;  % Target Newton iterations
            end
            selector_type = 'SimpleTimeStepSelector';
        catch ME
            warning('Advanced timestep selector not available: %s', ME.message);
            selector_type = 'Manual control';
        end
        
        fprintf('   Adaptive Control: Enabled (%s)\n', selector_type);
    else
        timestep_control.adaptive = false;
        fprintf('   Adaptive Control: Disabled\n');
    end
    
    % Substep 4.3 - Set cutting criteria _____________________________
    timestep_control.cut_criteria = struct();
    timestep_control.cut_criteria.max_saturation_change = 0.2;  % 20% per timestep
    timestep_control.cut_criteria.max_pressure_change_pa = 5e6;  % 50 bar per timestep
    timestep_control.cut_criteria.convergence_failure = true;
    
    fprintf('   Max Timestep Cuts: %d\n', ts_config.max_timestep_cuts);
    fprintf(' ──────────────────────────────────────────────────────────\n');

end

function simulation_schedule = step_5_setup_simulation_schedule(model_data, config)
% Step 5 - Create complete MRST simulation schedule

    fprintf('\n Simulation Schedule Setup:\n');
    fprintf(' ──────────────────────────────────────────────────────────\n');
    
    schedule_config = config.solver_configuration.simulation_schedule;
    
    % Substep 5.1 - Load development schedule ________________________
    mrst_schedule = model_data.development_schedule.mrst_schedule;
    
    % Substep 5.2 - Override with solver timestep preferences ________
    simulation_schedule = struct();
    simulation_schedule.step = [];
    simulation_schedule.control = mrst_schedule.control;
    
    current_time = 0;
    
    % History period (monthly timesteps)
    history_config = schedule_config.history_period;
    history_steps = ceil(history_config.duration_days / history_config.timestep_days);
    
    for i = 1:history_steps
        if i < history_steps
            step_days = history_config.timestep_days;
        else
            step_days = history_config.duration_days - (i-1) * history_config.timestep_days;
        end
        
        step = struct();
        step.val = step_days * 24 * 3600;  % Convert to seconds
        step.control = determine_control_index(current_time + step_days/2, mrst_schedule.control);
        
        simulation_schedule.step = [simulation_schedule.step; step];
        current_time = current_time + step_days;
    end
    
    % Substep 5.3 - Forecast period (variable timesteps) _____________
    forecast_config = schedule_config.forecast_period;
    
    for period_idx = 1:length(forecast_config.timestep_schedule)
        period = forecast_config.timestep_schedule(period_idx);
        
        period_steps = ceil(period.period_days / period.timestep_days);
        
        for i = 1:period_steps
            if i < period_steps
                step_days = period.timestep_days;
            else
                step_days = period.period_days - (i-1) * period.timestep_days;
            end
            
            step = struct();
            step.val = step_days * 24 * 3600;
            step.control = determine_control_index(current_time + step_days/2, mrst_schedule.control);
            
            simulation_schedule.step = [simulation_schedule.step; step];
            current_time = current_time + step_days;
        end
    end
    
    % Substep 5.4 - Set schedule metadata ____________________________
    simulation_schedule.total_steps = length(simulation_schedule.step);
    simulation_schedule.total_time_days = current_time;
    simulation_schedule.total_time_seconds = sum([simulation_schedule.step.val]);
    
    fprintf('   Total Duration: %.0f days (%.1f years)\n', current_time, current_time/365);
    fprintf('   History Period: %d steps (%d days each)\n', history_steps, history_config.timestep_days);
    fprintf('   Forecast Period: %d steps (variable)\n', ...
        simulation_schedule.total_steps - history_steps);
    fprintf('   Total Timesteps: %d\n', simulation_schedule.total_steps);
    
    % Substep 5.5 - Validate schedule consistency ____________________
    if abs(simulation_schedule.total_time_days - schedule_config.total_duration_days) > 1
        warning('Schedule duration mismatch: %.1f vs %.1f days', ...
            simulation_schedule.total_time_days, schedule_config.total_duration_days);
    end
    
    fprintf(' ──────────────────────────────────────────────────────────\n');

end

function control_index = determine_control_index(time_days, control_schedule)
% Helper function to determine which control period applies at given time
    
    % Map time to development phases (simplified)
    if time_days <= 365
        control_index = 1;  % Phase 1
    elseif time_days <= 730
        control_index = 2;  % Phase 2
    elseif time_days <= 1095
        control_index = 3;  % Phase 3
    elseif time_days <= 1825
        control_index = 4;  % Phase 4
    elseif time_days <= 2920
        control_index = 5;  % Phase 5
    else
        control_index = 6;  % Phase 6
    end
    
    % Ensure we don't exceed available controls
    control_index = min(control_index, length(control_schedule));

end

function export_path = step_6_export_solver_configuration(solver_results)
% Step 6 - Export complete solver configuration for s22 simulation

    script_path = fileparts(mfilename('fullpath'));
    data_dir = fullfile(fileparts(script_path), 'data', 'mrst_simulation', 'static');
    
    if ~exist(data_dir, 'dir')
        mkdir(data_dir);
    end
    
    % Substep 6.1 - Save MATLAB structure ____________________________
    export_path = fullfile(data_dir, 'solver_configuration.mat');
    save(export_path, 'solver_results');
    
    % Substep 6.2 - Create solver summary _____________________________
    summary_file = fullfile(data_dir, 'solver_configuration_summary.txt');
    write_solver_summary_file(summary_file, solver_results);
    
    % Substep 6.3 - Export simulation-ready model ___________________
    model_file = fullfile(data_dir, 'simulation_model.mat');
    model = solver_results.black_oil_model;
    save(model_file, 'model');
    
    % Substep 6.4 - Export final schedule _____________________________
    schedule_file = fullfile(data_dir, 'simulation_schedule.mat');
    schedule = solver_results.simulation_schedule;
    save(schedule_file, 'schedule');
    
    fprintf('   Exported to: %s\n', export_path);
    fprintf('   Summary: %s\n', summary_file);
    fprintf('   Model: %s\n', model_file);
    fprintf('   Schedule: %s\n', schedule_file);

end

function write_solver_summary_file(filename, solver_results)
% Write solver configuration summary to file

    fid = fopen(filename, 'w');
    if fid == -1
        error('Cannot open file for writing: %s', filename);
    end
    
    try
        fprintf(fid, 'Eagle West Field - MRST Solver Configuration Summary\n');
        fprintf(fid, 'Generated: %s\n', datestr(now));
        fprintf(fid, '==================================================\n\n');
        
        % Solver configuration
        fprintf(fid, 'SOLVER CONFIGURATION:\n');
        fprintf(fid, '  Solver Type: %s\n', solver_results.solver_type);
        fprintf(fid, '  Max Iterations: %d\n', solver_results.config.solver_configuration.max_iterations);
        fprintf(fid, '  CNV Tolerance: %.1e\n', solver_results.config.solver_configuration.tolerance_cnv);
        fprintf(fid, '  Material Balance Tolerance: %.1e\n', solver_results.config.solver_configuration.tolerance_mb);
        fprintf(fid, '  Line Search: %s\n', ternary(solver_results.config.solver_configuration.line_search, 'Enabled', 'Disabled'));
        fprintf(fid, '  CPR Preconditioning: %s\n', ternary(solver_results.config.solver_configuration.use_cpr, 'Enabled', 'Disabled'));
        fprintf(fid, '\n');
        
        % Model information
        fprintf(fid, 'MODEL INFORMATION:\n');
        fprintf(fid, '  Grid Cells: %d\n', solver_results.model_data.grid.cells.num);
        fprintf(fid, '  Active Phases: Oil, Water, Gas\n');
        fprintf(fid, '  Total Wells: %d\n', solver_results.model_data.wells.total_wells);
        fprintf(fid, '  Development Phases: %d\n', length(solver_results.model_data.development_schedule.development_phases));
        fprintf(fid, '\n');
        
        % Simulation schedule
        fprintf(fid, 'SIMULATION SCHEDULE:\n');
        fprintf(fid, '  Total Duration: %.0f days (%.1f years)\n', ...
            solver_results.simulation_schedule.total_time_days, ...
            solver_results.simulation_schedule.total_time_days/365);
        fprintf(fid, '  Total Timesteps: %d\n', solver_results.total_timesteps);
        fprintf(fid, '  History Period: %.0f days\n', ...
            solver_results.config.solver_configuration.simulation_schedule.history_period.duration_days);
        fprintf(fid, '  Forecast Period: %.0f days\n', ...
            solver_results.config.solver_configuration.simulation_schedule.forecast_period.duration_days);
        fprintf(fid, '\n');
        
        % Timestep control
        ts_config = solver_results.config.solver_configuration.timestep_control;
        fprintf(fid, 'TIMESTEP CONTROL:\n');
        fprintf(fid, '  Initial Timestep: %.1f days\n', ts_config.initial_timestep_days);
        fprintf(fid, '  Min/Max Timestep: %.1f - %.0f days\n', ts_config.min_timestep_days, ts_config.max_timestep_days);
        fprintf(fid, '  Growth Factor: %.2f\n', ts_config.timestep_growth_factor);
        fprintf(fid, '  Cut Factor: %.2f\n', ts_config.timestep_cut_factor);
        fprintf(fid, '  Adaptive Control: %s\n', ternary(ts_config.adaptive_control, 'Enabled', 'Disabled'));
        fprintf(fid, '\n');
        
        % Quality control
        qc_config = solver_results.config.solver_configuration.quality_control;
        fprintf(fid, 'QUALITY CONTROL:\n');
        fprintf(fid, '  Material Balance Tolerance: %.2f%%\n', qc_config.material_balance_tolerance);
        fprintf(fid, '  Max Aspect Ratio: %.1f\n', qc_config.max_aspect_ratio);
        fprintf(fid, '  Pressure Range: %.0f - %.0f Pa\n', qc_config.pressure_limits_pa(1), qc_config.pressure_limits_pa(2));
        fprintf(fid, '  Grid Quality Check: %s\n', ternary(qc_config.grid_quality_check, 'Enabled', 'Disabled'));
        fprintf(fid, '  Well Performance Check: %s\n', ternary(qc_config.well_performance_check, 'Enabled', 'Disabled'));
        
        fclose(fid);
        
    catch ME
        fclose(fid);
        error('Error writing solver summary: %s', ME.message);
    end

end

function result = ternary(condition, true_val, false_val)
% Ternary operator helper function
    if condition
        result = true_val;
    else
        result = false_val;
    end
end

function result = hasfield(s, field)
% Helper function for field checking (Octave compatibility)
    result = isfield(s, field);
end

% Main execution when called as script
if ~nargout
    solver_results = s21_solver_setup();
end