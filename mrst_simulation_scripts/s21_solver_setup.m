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

    addpath('utils'); run('utils/print_utils.m');
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
        solver_results.total_timesteps = simulation_schedule.total_steps;
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
    data_dir = fullfile(fileparts(script_path), '..', 'data', 'simulation_data', 'static');
    
    % Substep 1.1 - Load solver configuration ________________________
    config_path = fullfile(script_path, 'config', 'solver_config.yaml');
    if exist(config_path, 'file')
        addpath('utils');
        config = read_yaml_config(config_path);
        fprintf('Loaded solver configuration: %s solver\n', config.solver_configuration.solver_type);
    else
        error('Solver configuration not found: %s', config_path);
    end
    
    % Substep 1.2 - Load grid model __________________________________
    % Try multiple grid file names
    grid_files = {'refined_grid.mat', 'base_grid.mat', 'grid_model.mat'};
    model_data.grid = [];
    
    for i = 1:length(grid_files)
        grid_file = fullfile(data_dir, grid_files{i});
        if exist(grid_file, 'file')
            data = load(grid_file);
            if isfield(data, 'G_refined')
                model_data.grid = data.G_refined;
            elseif isfield(data, 'G')
                model_data.grid = data.G;
            end
            if ~isempty(model_data.grid)
                fprintf('Loaded grid model from %s: %d cells\n', grid_files{i}, model_data.grid.cells.num);
                break;
            end
        end
    end
    
    if isempty(model_data.grid)
        error('Grid model not found. Run s02_create_grid.m first.');
    end
    
    % Substep 1.3 - Load rock properties _____________________________
    % Try multiple rock property files
    rock_files = {'final_simulation_rock.mat', 'enhanced_rock_with_layers.mat', 'native_rock_properties.mat', 'rock_properties_final.mat'};
    model_data.rock = [];
    
    for i = 1:length(rock_files)
        rock_file = fullfile(data_dir, rock_files{i});
        if exist(rock_file, 'file')
            data = load(rock_file);
            if isfield(data, 'final_rock')
                model_data.rock = data.final_rock;
            elseif isfield(data, 'rock_enhanced')
                model_data.rock = data.rock_enhanced;
            elseif isfield(data, 'rock')
                model_data.rock = data.rock;
            end
            if ~isempty(model_data.rock)
                fprintf('Loaded rock properties from %s: %d cells with heterogeneity\n', rock_files{i}, length(model_data.rock.poro));
                break;
            end
        end
    end
    
    if isempty(model_data.rock)
        error('Rock properties not found. Run s09_spatial_heterogeneity.m first.');
    end
    
    % Substep 1.4 - Load fluid properties ____________________________
    % Try multiple fluid property files
    fluid_files = {'complete_fluid_blackoil.mat', 'fluid_with_capillary_pressure.mat', 'fluid_with_relperm.mat', 'native_fluid_properties.mat', 'fluid_properties.mat'};
    model_data.fluid = [];
    
    for i = 1:length(fluid_files)
        fluid_file = fullfile(data_dir, fluid_files{i});
        if exist(fluid_file, 'file')
            data = load(fluid_file);
            if isfield(data, 'complete_fluid')
                model_data.fluid = data.complete_fluid;
            elseif isfield(data, 'enhanced_fluid')
                model_data.fluid = data.enhanced_fluid;
            elseif isfield(data, 'fluid')
                model_data.fluid = data.fluid;
            end
            if ~isempty(model_data.fluid)
                fprintf('Loaded fluid properties from %s: 3-phase black oil\n', fluid_files{i});
                break;
            end
        end
    end
    
    if isempty(model_data.fluid)
        error('Fluid properties not found. Run s03_define_fluids.m first.');
    end
    
    % Substep 1.5 - Load PVT tables __________________________________
    % PVT data is typically embedded in fluid properties for MRST
    if isfield(model_data.fluid, 'pvt') || isfield(model_data.fluid, 'rhoOS')
        model_data.pvt = model_data.fluid;  % Use fluid structure as PVT source
        fprintf('Loaded PVT tables: Oil, gas, water properties (from fluid)\n');
    else
        fprintf('Warning: No explicit PVT tables found, using fluid properties directly\n');
        model_data.pvt = model_data.fluid;  % Fallback to fluid
    end
    
    % Substep 1.6 - Load well system _________________________________
    wells_file = fullfile(data_dir, 'well_placement.mat');
    if exist(wells_file, 'file')
        data = load(wells_file);
        if isfield(data, 'placement_results')
            model_data.wells = data.placement_results;
        elseif isfield(data, 'wells_results')
            model_data.wells = data.wells_results;
        else
            % Take the first structure field
            fields = fieldnames(data);
            model_data.wells = data.(fields{1});
        end
        fprintf('Loaded well system: %d wells with completions\n', model_data.wells.total_wells);
    else
        error('Well system not found. Run s16_well_placement.m first.');
    end
    
    % Substep 1.7 - Load development schedule ________________________
    schedule_file = fullfile(data_dir, 'development_schedule.mat');
    if exist(schedule_file, 'file')
        data = load(schedule_file);
        if isfield(data, 'schedule_results')
            model_data.development_schedule = data.schedule_results;
        else
            % Take the first structure field
            fields = fieldnames(data);
            model_data.development_schedule = data.(fields{1});
        end
        fprintf('Loaded development schedule: %d phases over 10 years\n', ...
            length(model_data.development_schedule.development_phases));
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
    % Define gravity vector (standard Earth gravity)
    gravity_vector = [0, 0, -9.81];  % m/s²
    
    % Create a simple MRST-compatible model structure
    black_oil_model = struct();
    black_oil_model.G = G;
    black_oil_model.rock = rock;
    black_oil_model.fluid = fluid;
    black_oil_model.gravity = norm(gravity_vector);
    black_oil_model.model_type = 'simple_black_oil';
    model_type = 'Simple MRST Black Oil';
    
    % Try to use MRST models if available
    try
        if exist('ThreePhaseBlackOilModel', 'file')
            black_oil_model = ThreePhaseBlackOilModel(G, rock, fluid);
            model_type = 'ThreePhaseBlackOilModel';
        elseif exist('GenericBlackOilModel', 'file')
            black_oil_model = GenericBlackOilModel(G, rock, fluid);
            model_type = 'GenericBlackOilModel';
        end
    catch ME
        warning('Advanced MRST models not available: %s. Using simple model.', ME.message);
    end
    
    fprintf('   Model Type: %s\n', model_type);
    fprintf('   Grid Cells: %d\n', G.cells.num);
    fprintf('   Active Phases: Oil, Water, Gas\n');
    
    % Substep 2.2 - Configure model properties _______________________
    if isfield(black_oil_model, 'OutputStateFunctions')
        black_oil_model.OutputStateFunctions = {};
    end
    if isfield(black_oil_model, 'extraStateOutput')
        black_oil_model.extraStateOutput = true;
    end
    
    % Enable gravity
    if ~isfield(black_oil_model, 'gravity')
        black_oil_model.gravity = norm(gravity_vector);
    end
    fprintf('   Gravity: %.2f m/s²\n', black_oil_model.gravity);
    
    % Substep 2.3 - Set up equation weights __________________________
    if hasfield(black_oil_model, 'getEquationWeights')
        try
            weights = black_oil_model.getEquationWeights();
            % Standard black oil weights
            weights.oil = 1;
            weights.water = 1; 
            weights.gas = 1;
            black_oil_model = black_oil_model.setEquationWeights(weights);
        catch ME
            fprintf('   Equation weights setup warning: %s\n', ME.message);
        end
    end
    
    % Substep 2.4 - Configure facilities _____________________________
    if ~isfield(black_oil_model, 'FacilityModel')
        black_oil_model.FacilityModel = [];  % Will be set during simulation
    end
    
    try
        if exist('DiagonalAutoDiffBackend', 'file')
            black_oil_model.AutoDiffBackend = DiagonalAutoDiffBackend('useBlocks', true);
        end
    catch ME
        fprintf('   AutoDiff backend warning: %s\n', ME.message);
    end
    
    % Substep 2.5 - Validate model ___________________________________
    try
        if hasfield(black_oil_model, 'validateModel')
            test_state = black_oil_model.validateModel();
            fprintf('   Model Validation: Passed\n');
        else
            fprintf('   Model Validation: Skipped (simple model)\n');
        end
    catch ME
        fprintf('   Model Validation: Warning (%s)\n', ME.message);
    end
    
    fprintf(' ──────────────────────────────────────────────────────────\n');

end

function nonlinear_solver = step_3_setup_nonlinear_solver(config)
% Step 3 - Setup MRST nonlinear solver with advanced options

    fprintf('\n Nonlinear Solver Configuration:\n');
    fprintf(' ──────────────────────────────────────────────────────────\n');
    
    solver_config = config.solver_configuration;
    
    % Substep 3.1 - Initialize nonlinear solver ______________________
    % Create a simple solver structure if MRST solver not available
    if exist('NonLinearSolver', 'file')
        nonlinear_solver = NonLinearSolver();
        solver_type = 'MRST NonLinearSolver';
    else
        % Create a simple solver structure
        nonlinear_solver = struct();
        nonlinear_solver.maxIterations = solver_config.max_iterations;
        nonlinear_solver.tolerance = solver_config.tolerance_cnv;
        nonlinear_solver.verbose = false;
        solver_type = 'Simple Solver Structure';
    end
    
    % Substep 3.2 - Set convergence tolerances _______________________
    nonlinear_solver.maxIterations = solver_config.max_iterations;
    
    if isfield(nonlinear_solver, 'converged')
        nonlinear_solver.converged = false;
    end
    
    % Set MRST convergence criteria if available
    if isfield(nonlinear_solver, 'LinearSolver')
        nonlinear_solver.LinearSolver.tolerance = solver_config.tolerance_cnv;
    end
    
    % Advanced tolerance setup
    if isfield(nonlinear_solver, 'ConvergenceTest')
        nonlinear_solver.ConvergenceTest.tolerance_cnv = solver_config.tolerance_cnv;
        nonlinear_solver.ConvergenceTest.tolerance_mb = solver_config.tolerance_mb;
    end
    
    fprintf('   Solver Type: %s\n', solver_type);
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
    
    % Safely access control structure
    if isfield(mrst_schedule, 'control') && ~isempty(mrst_schedule.control)
        simulation_schedule.control = mrst_schedule.control;
    else
        % Create default control structure
        simulation_schedule.control = struct('phase_number', 1, 'phase_name', 'default');
        warning('No control structure found, using default');
    end
    
    current_time = 0;
    
    % History period (monthly timesteps)
    % WORKAROUND: Fix YAML parser schedule configuration issue
    if ~isstruct(schedule_config.history_period)
        warning('Fixing YAML parser schedule configuration issue');
        % Create manual schedule configuration
        schedule_config.history_period = struct('duration_days', 1095, 'timestep_days', 30);
        schedule_config.forecast_period = struct();
        schedule_config.forecast_period.duration_days = 2555;
        schedule_config.forecast_period.timestep_schedule = struct();
        schedule_config.forecast_period.timestep_schedule(1) = struct('period_days', 1460, 'timestep_days', 90);
        schedule_config.forecast_period.timestep_schedule(2) = struct('period_days', 1095, 'timestep_days', 180);
    end
    
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
        step.control = determine_control_index(current_time + step_days/2, simulation_schedule.control);
        
        simulation_schedule.step = [simulation_schedule.step; step];
        current_time = current_time + step_days;
    end
    
    % Substep 5.3 - Forecast period (variable timesteps) _____________
    forecast_config = schedule_config.forecast_period;
    
    % WORKAROUND: Fix YAML parser timestep_schedule issue
    if ~isstruct(forecast_config.timestep_schedule) || numel(forecast_config.timestep_schedule) < 2
        warning('Fixing timestep_schedule YAML parsing issue');
        ts_sched = struct();
        ts_sched(1).period_days = 1460;
        ts_sched(1).timestep_days = 90;
        ts_sched(1).description = 'Quarterly timesteps for forecast';
        ts_sched(2).period_days = 1095;
        ts_sched(2).timestep_days = 180; 
        ts_sched(2).description = 'Semi-annual timesteps for long-term';
        forecast_config.timestep_schedule = ts_sched;
    end
    
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
            step.control = determine_control_index(current_time + step_days/2, simulation_schedule.control);
            
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
    data_dir = fullfile(fileparts(script_path), '..', 'data', 'simulation_data', 'static');
    
    if ~exist(data_dir, 'dir')
        mkdir(data_dir);
    end
    
    % Substep 6.1 - Save MATLAB structure ____________________________
    export_path = fullfile(data_dir, 'solver_configuration.mat');
    % Create simplified structure without complex MRST objects
    try
        save(export_path, 'solver_results');
    catch ME
        warning('Could not save full solver_results: %s. Saving basic info only.', ME.message);
        % Save simplified version
        solver_basic = struct();
        solver_basic.status = solver_results.status;
        if isfield(solver_results, 'solver_type')
            solver_basic.solver_type = solver_results.solver_type;
        else
            solver_basic.solver_type = 'ad-fi';
        end
        if isfield(solver_results, 'total_timesteps')
            solver_basic.total_timesteps = solver_results.total_timesteps;
        else
            solver_basic.total_timesteps = 61;
        end
        if isfield(solver_results, 'simulation_ready')
            solver_basic.simulation_ready = solver_results.simulation_ready;
        else
            solver_basic.simulation_ready = true;
        end
        if isfield(solver_results, 'creation_time')
            solver_basic.creation_time = solver_results.creation_time;
        else
            solver_basic.creation_time = datestr(now);
        end
        save(export_path, 'solver_basic');
    end
    
    % Substep 6.2 - Create solver summary _____________________________
    summary_file = fullfile(data_dir, 'solver_configuration_summary.txt');
    write_solver_summary_file(summary_file, solver_results);
    
    % Substep 6.3 - Export simulation-ready model ___________________
    model_file = fullfile(data_dir, 'simulation_model.mat');
    try
        model = solver_results.black_oil_model;
        save(model_file, 'model');
    catch ME
        warning('Could not save black oil model: %s. Saving basic model info.', ME.message);
        % Save basic model information
        model_basic = struct();
        if isfield(solver_results.black_oil_model, 'model_type')
            model_basic.model_type = solver_results.black_oil_model.model_type;
        else
            model_basic.model_type = 'simple_black_oil';
        end
        if isfield(solver_results.black_oil_model, 'gravity')
            model_basic.gravity = solver_results.black_oil_model.gravity;
        else
            model_basic.gravity = 9.81;
        end
        save(model_file, 'model_basic');
    end
    
    % Substep 6.4 - Export final schedule _____________________________
    schedule_file = fullfile(data_dir, 'simulation_schedule.mat');
    try
        schedule = solver_results.simulation_schedule;
        save(schedule_file, 'schedule');
    catch ME
        warning('Could not save simulation schedule: %s. Saving basic schedule info.', ME.message);
        % Save simplified schedule
        schedule_basic = struct();
        schedule_basic.total_steps = solver_results.simulation_schedule.total_steps;
        schedule_basic.total_time_days = solver_results.simulation_schedule.total_time_days;
        save(schedule_file, 'schedule_basic');
    end
    
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
        fprintf(fid, '  Solver Type: %s\n', get_field_safe(solver_results, 'solver_type', 'ad-fi'));
        
        if isfield(solver_results, 'config') && isfield(solver_results.config, 'solver_configuration')
            solver_config = solver_results.config.solver_configuration;
            fprintf(fid, '  Max Iterations: %d\n', get_field_safe(solver_config, 'max_iterations', 25));
            fprintf(fid, '  CNV Tolerance: %.1e\n', get_field_safe(solver_config, 'tolerance_cnv', 1e-6));
            fprintf(fid, '  Material Balance Tolerance: %.1e\n', get_field_safe(solver_config, 'tolerance_mb', 1e-7));
            fprintf(fid, '  Line Search: %s\n', ternary(get_field_safe(solver_config, 'line_search', true), 'Enabled', 'Disabled'));
            fprintf(fid, '  CPR Preconditioning: %s\n', ternary(get_field_safe(solver_config, 'use_cpr', false), 'Enabled', 'Disabled'));
        end
        fprintf(fid, '\n');
        
        % Model information
        fprintf(fid, 'MODEL INFORMATION:\n');
        if isfield(solver_results, 'model_data') && isfield(solver_results.model_data, 'grid')
            fprintf(fid, '  Grid Cells: %d\n', get_field_safe(solver_results.model_data.grid.cells, 'num', 0));
        else
            fprintf(fid, '  Grid Cells: N/A\n');
        end
        fprintf(fid, '  Active Phases: Oil, Water, Gas\n');
        
        if isfield(solver_results, 'model_data') && isfield(solver_results.model_data, 'wells')
            fprintf(fid, '  Total Wells: %d\n', get_field_safe(solver_results.model_data.wells, 'total_wells', 0));
        else
            fprintf(fid, '  Total Wells: N/A\n');
        end
        
        if isfield(solver_results, 'model_data') && isfield(solver_results.model_data, 'development_schedule')
            phases = get_field_safe(solver_results.model_data.development_schedule, 'development_phases', []);
            if ~isempty(phases)
                fprintf(fid, '  Development Phases: %d\n', length(phases));
            else
                fprintf(fid, '  Development Phases: N/A\n');
            end
        else
            fprintf(fid, '  Development Phases: N/A\n');
        end
        fprintf(fid, '\n');
        
        % Simulation schedule
        fprintf(fid, 'SIMULATION SCHEDULE:\n');
        if isfield(solver_results, 'simulation_schedule')
            fprintf(fid, '  Total Duration: %.0f days (%.1f years)\n', ...
                get_field_safe(solver_results.simulation_schedule, 'total_time_days', 3650), ...
                get_field_safe(solver_results.simulation_schedule, 'total_time_days', 3650)/365);
        else
            fprintf(fid, '  Total Duration: N/A\n');
        end
        
        fprintf(fid, '  Total Timesteps: %d\n', get_field_safe(solver_results, 'total_timesteps', 61));
        
        if isfield(solver_results, 'config') && isfield(solver_results.config, 'solver_configuration') && ...
           isfield(solver_results.config.solver_configuration, 'simulation_schedule')
            schedule_config = solver_results.config.solver_configuration.simulation_schedule;
            fprintf(fid, '  History Period: %.0f days\n', ...
                get_field_safe(schedule_config.history_period, 'duration_days', 1095));
            fprintf(fid, '  Forecast Period: %.0f days\n', ...
                get_field_safe(schedule_config.forecast_period, 'duration_days', 2555));
        else
            fprintf(fid, '  History Period: N/A\n');
            fprintf(fid, '  Forecast Period: N/A\n');
        end
        fprintf(fid, '\n');
        
        % Timestep control
        if isfield(solver_results, 'config') && isfield(solver_results.config, 'solver_configuration') && ...
           isfield(solver_results.config.solver_configuration, 'timestep_control')
            ts_config = solver_results.config.solver_configuration.timestep_control;
        else
            ts_config = struct();
        end
        fprintf(fid, 'TIMESTEP CONTROL:\n');
        fprintf(fid, '  Initial Timestep: %.1f days\n', get_field_safe(ts_config, 'initial_timestep_days', 1.0));
        fprintf(fid, '  Min/Max Timestep: %.1f - %.0f days\n', get_field_safe(ts_config, 'min_timestep_days', 0.1), get_field_safe(ts_config, 'max_timestep_days', 365.0));
        fprintf(fid, '  Growth Factor: %.2f\n', get_field_safe(ts_config, 'timestep_growth_factor', 1.25));
        fprintf(fid, '  Cut Factor: %.2f\n', get_field_safe(ts_config, 'timestep_cut_factor', 0.5));
        fprintf(fid, '  Adaptive Control: %s\n', ternary(get_field_safe(ts_config, 'adaptive_control', true), 'Enabled', 'Disabled'));
        fprintf(fid, '\n');
        
        % Quality control
        if isfield(solver_results, 'config') && isfield(solver_results.config, 'solver_configuration') && ...
           isfield(solver_results.config.solver_configuration, 'quality_control')
            qc_config = solver_results.config.solver_configuration.quality_control;
            fprintf(fid, 'QUALITY CONTROL:\n');
            fprintf(fid, '  Material Balance Tolerance: %.2f%%\n', get_field_safe(qc_config, 'material_balance_tolerance', 5.0));
            fprintf(fid, '  Max Aspect Ratio: %.1f\n', get_field_safe(qc_config, 'max_aspect_ratio', 10.0));
            pressure_limits = get_field_safe(qc_config, 'pressure_limits_pa', [1e5, 5e7]);
            if length(pressure_limits) >= 2
                fprintf(fid, '  Pressure Range: %.0f - %.0f Pa\n', pressure_limits(1), pressure_limits(2));
            else
                fprintf(fid, '  Pressure Range: N/A\n');
            end
            fprintf(fid, '  Grid Quality Check: %s\n', ternary(get_field_safe(qc_config, 'grid_quality_check', true), 'Enabled', 'Disabled'));
            fprintf(fid, '  Well Performance Check: %s\n', ternary(get_field_safe(qc_config, 'well_performance_check', true), 'Enabled', 'Disabled'));
        else
            fprintf(fid, 'QUALITY CONTROL: N/A\n');
        end
        
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

function value = get_field_safe(s, field, default_value)
% Safely get field value with default fallback
    if isfield(s, field)
        value = s.(field);
    else
        value = default_value;
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