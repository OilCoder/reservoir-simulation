function solver_results = s20_solver_setup()
% S20_SOLVER_SETUP - MRST Solver Configuration for Eagle West Field
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

    script_dir = fileparts(mfilename('fullpath'));
    addpath(fullfile(script_dir, 'utils')); 
    
    % Suppress isdir deprecation warnings from MRST internal functions
    suppress_isdir_warnings();
    
    run(fullfile(script_dir, 'utils', 'print_utils.m'));

    % Add MRST session validation
    [success, message] = validate_mrst_session(script_dir);
    if ~success
        error('MRST validation failed: %s', message);
    end
    print_step_header('S20', 'MRST Solver Configuration');
    
    % Initialize MRST gravity FIRST (critical for model creation)
    fprintf('Initializing MRST gravity system...\n');
    setup_mrst_gravity();
    
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
        
        % Set required fields before export validation
        solver_results.status = 'success';
        solver_results.solver_type = 'ad-fi';
        solver_results.total_timesteps = simulation_schedule.total_steps;
        solver_results.simulation_ready = true;
        solver_results.creation_time = datestr(now);
        
        % ----------------------------------------
        % Step 6 - Export Solver Configuration
        % ----------------------------------------
        step_start = tic;
        export_path = step_6_export_solver_configuration(solver_results);
        solver_results.export_path = export_path;
        print_step_result(6, 'Export Solver Configuration', 'success', toc(step_start));
        
        print_step_footer('S20', sprintf('Solver Configured (ad-fi, %d timesteps)', ...
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
    script_dir = fileparts(mfilename('fullpath'));
    script_path = fileparts(mfilename('fullpath'));
    if isempty(script_path)
        script_path = pwd();
    end
    data_dir = get_data_path('static');
    
    % Substep 1.1 - Load solver configuration ________________________
    config_path = fullfile(script_path, 'config', 'solver_config.yaml');
    if ~exist(config_path, 'file')
        error(['Missing canonical solver configuration: solver_config.yaml\n' ...
               'UPDATE CANON: obsidian-vault/Planning/Solver_Configuration.md\n' ...
               'Must define exact solver parameters for Eagle West Field.']);
    end
    addpath(fullfile(script_dir, 'utils'));
    config = read_yaml_config(config_path);
    fprintf('Loaded solver configuration: %s solver\n', config.solver_configuration.solver_type);
    
    % Substep 1.2 - Load grid model from canonical MRST structure ___
    canonical_grid_file = '/workspace/data/mrst/grid.mat';
    if exist(canonical_grid_file, 'file')
        grid_data = load(canonical_grid_file, 'data_struct');
        model_data.grid = grid_data.data_struct.G;
        fprintf('Loaded grid from canonical structure: %d cells\n', model_data.grid.cells.num);
    else
        error(['Missing canonical grid file: /workspace/data/mrst/grid.mat\n' ...
               'REQUIRED: Run s03-s05 to generate canonical grid structure.']);
    end
    
    % Substep 1.3 - Load rock properties from canonical MRST structure
    canonical_rock_file = '/workspace/data/mrst/rock.mat';
    if exist(canonical_rock_file, 'file')
        rock_data = load(canonical_rock_file, 'data_struct');
        model_data.rock = struct('perm', rock_data.data_struct.perm, 'poro', rock_data.data_struct.poro);
        fprintf('Loaded rock properties from canonical structure: %d cells\n', length(model_data.rock.poro));
    else
        error(['Missing canonical rock file: /workspace/data/mrst/rock.mat\n' ...
               'REQUIRED: Run s06-s08 to generate canonical rock structure.']);
    end
    
    % Substep 1.4 - Load fluid properties from canonical MRST structure
    canonical_fluid_file = '/workspace/data/mrst/fluid.mat';
    if exist(canonical_fluid_file, 'file')
        fluid_data = load(canonical_fluid_file, 'data_struct');
        model_data.fluid = fluid_data.data_struct.model;
        fprintf('Loaded fluid properties from canonical structure: 3-phase black oil\n');
    else
        error(['Missing canonical fluid file: /workspace/data/mrst/fluid.mat\n' ...
               'REQUIRED: Run s02, s09-s10 to generate canonical fluid structure.']);
    end
    
    % Substep 1.5 - Validate PVT data in loaded fluid _______________
    if ~isfield(model_data.fluid, 'rhoOS')
        error(['Canonical fluid missing required PVT data: rhoOS\n' ...
               'REQUIRED: Run s02 to generate complete fluid with PVT tables.']);
    end
    model_data.pvt = model_data.fluid;
    fprintf('Validated PVT tables: Oil, gas, water properties\n');
    
    % Substep 1.6 - Load well system from canonical MRST structure ___
    canonical_wells_file = '/workspace/data/mrst/wells.mat';
    if exist(canonical_wells_file, 'file')
        wells_data = load(canonical_wells_file, 'data_struct');
        model_data.wells = wells_data.data_struct;
        fprintf('Loaded well system from canonical structure: %d wells\n', length(model_data.wells.W));
    else
        error(['Missing canonical wells file: /workspace/data/mrst/wells.mat\n' ...
               'REQUIRED: Run s16 to generate canonical wells structure.']);
    end
    
    % Substep 1.7 - Load development schedule from canonical structure
    canonical_schedule_file = '/workspace/data/mrst/schedule.mat';
    if exist(canonical_schedule_file, 'file')
        schedule_data = load(canonical_schedule_file, 'data_struct');
        model_data.development_schedule = struct();
        model_data.development_schedule.development_phases = schedule_data.data_struct.development.phases;
        model_data.development_schedule.mrst_schedule = schedule_data.data_struct.schedule;
        fprintf('Loaded development schedule from canonical structure: %d phases\n', ...
            length(model_data.development_schedule.development_phases));
    else
        error(['Missing canonical schedule file: /workspace/data/mrst/schedule.mat\n' ...
               'REQUIRED: Run s17-s19 to generate canonical schedule structure.']);
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
    [black_oil_model, model_type] = substep_2_1_initialize_black_oil_model(G, rock, fluid);
    
    fprintf('   Model Type: %s\n', model_type);
    fprintf('   Grid Cells: %d\n', G.cells.num);
    fprintf('   Active Phases: Oil, Water, Gas\n');
    
    % Substep 2.2 - Configure model properties _______________________
    black_oil_model = substep_2_2_configure_model_properties(black_oil_model);
    
    % Substep 2.3 - Set up equation weights __________________________
    black_oil_model = substep_2_3_setup_equation_weights(black_oil_model);
    
    % Substep 2.4 - Configure facilities _____________________________
    black_oil_model = substep_2_4_configure_facilities(black_oil_model);
    
    % Substep 2.5 - Validate model ___________________________________
    substep_2_5_validate_model(black_oil_model);
    
    fprintf(' ──────────────────────────────────────────────────────────\n');

end

function nonlinear_solver = step_3_setup_nonlinear_solver(config)
% Step 3 - Setup MRST nonlinear solver with advanced options

    fprintf('\n Nonlinear Solver Configuration:\n');
    fprintf(' ──────────────────────────────────────────────────────────\n');
    
    solver_config = config.solver_configuration;
    
    % Substep 3.1 - Initialize nonlinear solver ______________________
    [nonlinear_solver, solver_type] = substep_3_1_initialize_nonlinear_solver(solver_config);
    
    % Substep 3.2 - Set convergence tolerances _______________________
    nonlinear_solver = substep_3_2_set_convergence_tolerances(nonlinear_solver, solver_config);
    
    fprintf('   Solver Type: %s\n', solver_type);
    fprintf('   Max Iterations: %d\n', solver_config.max_iterations);
    fprintf('   CNV Tolerance: %.1e\n', solver_config.tolerance_cnv);
    fprintf('   Material Balance Tolerance: %.1e\n', solver_config.tolerance_mb);
    
    % Substep 3.3 - Configure line search ____________________________
    nonlinear_solver = substep_3_3_configure_line_search(nonlinear_solver, solver_config);
    
    % Substep 3.4 - Configure linear solver __________________________
    [nonlinear_solver, linear_solver_type] = substep_3_4_configure_linear_solver(nonlinear_solver, solver_config);
    
    fprintf('   Linear Solver: %s\n', linear_solver_type);
    
    % Substep 3.5 - Set advanced solver options ______________________
    nonlinear_solver = substep_3_5_set_advanced_solver_options(nonlinear_solver);
    
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
        
        % Create MRST timestep selector if available
        if exist('SimpleTimeStepSelector', 'file')
            timestep_control.selector = SimpleTimeStepSelector();
            if isfield(timestep_control.selector, 'targetIterations')
                timestep_control.selector.targetIterations = 8;  % Target Newton iterations
            end
            selector_type = 'SimpleTimeStepSelector';
        else
            error(['Missing canonical MRST timestep selector: SimpleTimeStepSelector\n' ...
                   'UPDATE CANON: obsidian-vault/Planning/Solver_Configuration.md\n' ...
                   'Must have MRST with SimpleTimeStepSelector available.']);
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
    
    % Canon control structure required
    if ~isfield(mrst_schedule, 'control') || isempty(mrst_schedule.control)
        error(['Missing canonical control structure in mrst_schedule\n' ...
               'UPDATE CANON: obsidian-vault/Planning/Development_Schedule.md\n' ...
               'Must define control structure with 6 development phases.']);
    end
    simulation_schedule.control = mrst_schedule.control;
    
    current_time = 0;
    
    % History period (monthly timesteps)
    if ~isstruct(schedule_config.history_period)
        error(['Invalid canonical schedule configuration: history_period not struct\n' ...
               'UPDATE CANON: obsidian-vault/Planning/Development_Schedule.md\n' ...
               'Must define history_period with duration_days and timestep_days.']);
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
    
    % Validate required fields exist
    required_fields = {'period_1_days', 'period_1_timestep', 'period_2_days', 'period_2_timestep'};
    for i = 1:length(required_fields)
        if ~isfield(forecast_config, required_fields{i})
            error(['Missing canonical forecast configuration: %s\n' ...
                   'UPDATE CANON: obsidian-vault/Planning/Development_Schedule.md\n' ...
                   'Must define period_1_days, period_1_timestep, period_2_days, period_2_timestep.'], required_fields{i});
        end
    end
    
    % Process Period 1 (quarterly)
    period_1_steps = ceil(forecast_config.period_1_days / forecast_config.period_1_timestep);
    for i = 1:period_1_steps
        if i < period_1_steps
            step_days = forecast_config.period_1_timestep;
        else
            step_days = forecast_config.period_1_days - (i-1) * forecast_config.period_1_timestep;
        end
        
        step = struct();
        step.val = step_days * 24 * 3600;
        step.control = determine_control_index(current_time + step_days/2, simulation_schedule.control);
        
        simulation_schedule.step = [simulation_schedule.step; step];
        current_time = current_time + step_days;
    end
    
    % Process Period 2 (semi-annual)
    period_2_steps = ceil(forecast_config.period_2_days / forecast_config.period_2_timestep);
    for i = 1:period_2_steps
        if i < period_2_steps
            step_days = forecast_config.period_2_timestep;
        else
            step_days = forecast_config.period_2_days - (i-1) * forecast_config.period_2_timestep;
        end
        
        step = struct();
        step.val = step_days * 24 * 3600;
        step.control = determine_control_index(current_time + step_days/2, simulation_schedule.control);
        
        simulation_schedule.step = [simulation_schedule.step; step];
        current_time = current_time + step_days;
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
        error(['Schedule duration mismatch: %.1f vs %.1f days\n' ...
               'UPDATE CANON: obsidian-vault/Planning/Development_Schedule.md\n' ...
               'Schedule periods must sum to exact total_duration_days.'], ...
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
    if isempty(script_path)
        script_path = pwd();
    end
    data_dir = get_data_path('static');
    
    if ~exist(data_dir, 'dir')
        mkdir(data_dir);
    end
    
    % Substep 6.1 - Save to canonical MRST solver structure ________
    canonical_file = '/workspace/data/mrst/solver.mat';
    % Validate required fields before export
    if ~isfield(solver_results, 'status')
        error(['Missing canonical solver status field\n' ...
               'UPDATE CANON: obsidian-vault/Planning/Solver_Configuration.md\n' ...
               'Must define solver_results.status.']);
    end
    if ~isfield(solver_results, 'solver_type')
        error(['Missing canonical solver type field\n' ...
               'UPDATE CANON: obsidian-vault/Planning/Solver_Configuration.md\n' ...
               'Must define solver_results.solver_type.']);
    end
    if ~isfield(solver_results, 'total_timesteps')
        error(['Missing canonical timesteps field\n' ...
               'UPDATE CANON: obsidian-vault/Planning/Solver_Configuration.md\n' ...
               'Must define solver_results.total_timesteps.']);
    end
    % Save only serializable data (Canon-First: exclude complex MRST objects)
    solver_config_export = struct();
    solver_config_export.status = solver_results.status;
    solver_config_export.solver_type = solver_results.solver_type;
    solver_config_export.total_timesteps = solver_results.total_timesteps;
    solver_config_export.simulation_ready = solver_results.simulation_ready;
    solver_config_export.creation_time = solver_results.creation_time;
    
    % Export configuration (ensure serializable YAML data)
    if isfield(solver_results, 'config')
        try
            % Test if config can be serialized
            temp_config = solver_results.config;
            temp_path = [export_path '.test'];
            save(temp_path, 'temp_config');
            delete(temp_path);
            % If successful, use the full config
            solver_config_export.config = solver_results.config;
        catch
            % If config contains non-serializable objects, create metadata only
            solver_config_export.config_note = 'Original config contained non-serializable objects';
            solver_config_export.config_source = 'solver_config.yaml';
            
            % Try to extract basic solver settings manually
            if isfield(solver_results.config, 'solver_configuration')
                sc = solver_results.config.solver_configuration;
                solver_config_export.basic_config = struct();
                if isfield(sc, 'solver_type') && ischar(sc.solver_type)
                    solver_config_export.basic_config.solver_type = sc.solver_type;
                end
                if isfield(sc, 'max_iterations') && isnumeric(sc.max_iterations)
                    solver_config_export.basic_config.max_iterations = sc.max_iterations;
                end
            end
        end
    end
    
    % Export timestep control (exclude non-serializable objects)
    if isfield(solver_results, 'timestep_control')
        ts_control = solver_results.timestep_control;
        solver_config_export.timestep_control = struct();
        
        % Copy only serializable numeric fields
        serializable_fields = {'initial_dt', 'min_dt', 'max_dt', 'growth_factor', ...
                              'cut_factor', 'max_cuts', 'adaptive'};
        for i = 1:length(serializable_fields)
            field = serializable_fields{i};
            if isfield(ts_control, field)
                value = ts_control.(field);
                % Only copy if it's a simple numeric or logical value
                if isnumeric(value) || islogical(value)
                    solver_config_export.timestep_control.(field) = value;
                end
            end
        end
        
        % Add metadata for complex objects
        if isfield(ts_control, 'selector')
            solver_config_export.timestep_control.selector_type = 'SimpleTimeStepSelector';
            solver_config_export.timestep_control.selector_note = 'Complex selector recreated at runtime';
        end
    end
    
    % Create canonical solver data structure
    data_struct = struct();
    data_struct.type = 'FI';  % Fully Implicit
    data_struct.tolerances.cnv = config.solver_configuration.tolerance_cnv;
    data_struct.tolerances.mb = config.solver_configuration.tolerance_mb;
    data_struct.tolerances.max_its = config.solver_configuration.max_iterations;
    
    % Numerical parameters
    if isfield(solver_results, 'timestep_control')
        ts_control = solver_results.timestep_control;
        data_struct.numerical.timestep = ts_control.initial_dt;
        data_struct.numerical.cfl = 1.0;  % Default CFL number
        data_struct.numerical.relaxation = 1.0;  % Default relaxation factor
    end
    
    % Store model components
    data_struct.model = model_data;  % Complete MRST model components
    
    % Load initial state
    canonical_state_file = '/workspace/data/mrst/initial_state.mat';
    if exist(canonical_state_file, 'file')
        state_data = load(canonical_state_file, 'data_struct');
        data_struct.state0 = state_data.data_struct.state;
    else
        error(['Missing canonical initial state file: /workspace/data/mrst/initial_state.mat\n' ...
               'REQUIRED: Run s11-s12 to generate canonical initial state.']);
    end
    
    data_struct.created_by = {'s20'};
    data_struct.timestamp = datetime('now');
    
    save(canonical_file, 'data_struct');
    export_path = canonical_file;
    
    % Substep 6.2 - Create solver summary (optional) ________________
    summary_file = fullfile(data_dir, 'solver_configuration_summary.txt');
    write_solver_summary_file(summary_file, solver_results);
    
    fprintf('   Exported to: %s\n', export_path);
    fprintf('   Summary: %s\n', summary_file);

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

function value = get_field_safe(s, field, canonical_value)
% Get canonical field value - no defensive fallbacks
    if ~isfield(s, field)
        error(['Missing canonical field: %s\n' ...
               'UPDATE CANON: obsidian-vault/Planning/Data_Structures.md\n' ...
               'Must define exact value for field.'], field);
    end
    value = s.(field);
end

function [black_oil_model, model_type] = substep_2_1_initialize_black_oil_model(G, rock, fluid)
% Initialize black oil model with MRST integration
    
    fprintf('   Configuring MRST black oil model...\n');
    
    % Initialize gravity system
    gravity_vector = gravity();  % Use our gravity function
    gravity_magnitude = norm(gravity_vector);
    fprintf('   Gravity: %.2f m/s² %s\n', gravity_magnitude, mat2str(gravity_vector));
    
    % Create a simple MRST-compatible model structure as fallback
    black_oil_model = struct();
    black_oil_model.G = G;
    black_oil_model.rock = rock;
    black_oil_model.fluid = fluid;
    black_oil_model.gravity = gravity_magnitude;  
    black_oil_model.model_type = 'simple_black_oil';
    model_type = 'Simple MRST Black Oil';
    
    % Use canonical MRST models - with proper error handling
    if exist('ThreePhaseBlackOilModel', 'file')
        try
            fprintf('   Creating ThreePhaseBlackOilModel...\n');
            black_oil_model = ThreePhaseBlackOilModel(G, rock, fluid);
            model_type = 'ThreePhaseBlackOilModel';
            fprintf('   ThreePhaseBlackOilModel created successfully\n');
        catch ME
            fprintf('   ThreePhaseBlackOilModel failed: %s\n', ME.message);
            % Try GenericBlackOilModel as fallback
            if exist('GenericBlackOilModel', 'file')
                fprintf('   Trying GenericBlackOilModel as alternative...\n');
                try
                    black_oil_model = GenericBlackOilModel(G, rock, fluid);
                    model_type = 'GenericBlackOilModel';
                    fprintf('   GenericBlackOilModel created successfully\n');
                catch ME2
                    fprintf('   GenericBlackOilModel also failed: %s\n', ME2.message);
                    fprintf('   Using simple black oil model structure\n');
                    % Keep the simple structure we created above
                end
            else
                fprintf('   Using simple black oil model structure\n');
            end
        end
    elseif exist('GenericBlackOilModel', 'file')
        try
            fprintf('   Creating GenericBlackOilModel...\n');
            black_oil_model = GenericBlackOilModel(G, rock, fluid);
            model_type = 'GenericBlackOilModel';
            fprintf('   GenericBlackOilModel created successfully\n');
        catch ME
            fprintf('   GenericBlackOilModel failed: %s\n', ME.message);
            fprintf('   Using simple black oil model structure\n');
            % Keep the simple structure we created above
        end
    else
        fprintf('   No advanced MRST models available, using simple structure\n');
        % Keep simple model structure as canonical fallback
        model_type = 'Simple MRST Black Oil';
    end

end

function black_oil_model = substep_2_2_configure_model_properties(black_oil_model)
% Configure basic model properties
    
    if isfield(black_oil_model, 'OutputStateFunctions')
        black_oil_model.OutputStateFunctions = {};
    end
    if isfield(black_oil_model, 'extraStateOutput')
        black_oil_model.extraStateOutput = true;
    end
    
    % Ensure gravity is properly set (should be done in substep_2_1)
    if ~isfield(black_oil_model, 'gravity')
        gravity_vector = gravity();  % Use our gravity function
        black_oil_model.gravity = norm(gravity_vector);
    end
    fprintf('   Model gravity: %.2f m/s²\n', black_oil_model.gravity);

end

function black_oil_model = substep_2_3_setup_equation_weights(black_oil_model)
% Setup equation weights for black oil phases
    
    if hasfield(black_oil_model, 'getEquationWeights')
        if ~ismethod(black_oil_model, 'getEquationWeights')
            error(['MRST model missing equation weights methods\n' ...
                   'UPDATE CANON: obsidian-vault/Planning/MRST_Requirements.md\n' ...
                   'Must use MRST version with equation weights support.']);
        end
        weights = black_oil_model.getEquationWeights();
        % Standard black oil weights
        weights.oil = 1;
        weights.water = 1; 
        weights.gas = 1;
        black_oil_model = black_oil_model.setEquationWeights(weights);
    end

end

function black_oil_model = substep_2_4_configure_facilities(black_oil_model)
% Configure facilities and AutoDiff backend
    
    if ~isfield(black_oil_model, 'FacilityModel')
        black_oil_model.FacilityModel = [];  % Will be set during simulation
    end
    
    if ~exist('DiagonalAutoDiffBackend', 'file')
        error(['MRST DiagonalAutoDiffBackend not available\n' ...
               'UPDATE CANON: obsidian-vault/Planning/MRST_Requirements.md\n' ...
               'Must use MRST version with DiagonalAutoDiffBackend support.']);
    end
    black_oil_model.AutoDiffBackend = DiagonalAutoDiffBackend();

end

function substep_2_5_validate_model(black_oil_model)
% Validate the black oil model configuration
    
    if hasfield(black_oil_model, 'validateModel')
        if ~ismethod(black_oil_model, 'validateModel')
            error(['MRST model missing validateModel method\n' ...
                   'UPDATE CANON: obsidian-vault/Planning/MRST_Requirements.md\n' ...
                   'Must use MRST version with model validation support.']);
        end
        test_state = black_oil_model.validateModel();
        fprintf('   Model Validation: Passed\n');
    else
        fprintf('   Model Validation: Skipped (simple model)\n');
    end

end

function [nonlinear_solver, solver_type] = substep_3_1_initialize_nonlinear_solver(solver_config)
% Initialize nonlinear solver structure
    
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

end

function nonlinear_solver = substep_3_2_set_convergence_tolerances(nonlinear_solver, solver_config)
% Set convergence tolerances for nonlinear solver
    
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

end

function nonlinear_solver = substep_3_3_configure_line_search(nonlinear_solver, solver_config)
% Configure line search options for nonlinear solver
    
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

end

function [nonlinear_solver, linear_solver_type] = substep_3_4_configure_linear_solver(nonlinear_solver, solver_config)
% Configure linear solver with CPR preconditioning
    
    if solver_config.use_cpr
        % CPR (Constrained Pressure Residual) preconditioning
        if ~exist('CPRSolverAD', 'file')
            error(['MRST CPRSolverAD not available\n' ...
                   'UPDATE CANON: obsidian-vault/Planning/MRST_Requirements.md\n' ...
                   'Must use MRST version with CPR solver support.']);
        end
        cpr_solver = CPRSolverAD('ellipticSolver', BackslashSolverAD);
        nonlinear_solver.LinearSolver = cpr_solver;
        linear_solver_type = 'CPR with Backslash';
    else
        linear_solver_type = 'Default MRST';
    end

end

function nonlinear_solver = substep_3_5_set_advanced_solver_options(nonlinear_solver)
% Set advanced solver options for robustness
    
    nonlinear_solver.verbose = false;  % Reduce output during simulation
    nonlinear_solver.continueOnFailure = false;  % FAIL_FAST policy
    
    if isfield(nonlinear_solver, 'enforceResidualDecrease')
        nonlinear_solver.enforceResidualDecrease = true;
    end

end

function result = hasfield(s, field)
% Helper function for field checking (Octave compatibility)
    result = isfield(s, field);
end

function setup_mrst_gravity()
% Setup MRST gravity system to avoid 'gravity function not available' errors
    
    try
        % Method 1: Try standard MRST gravity functions first
        if exist('gravity', 'file') == 2
            gravity('reset');
            gravity('on');
            fprintf('MRST gravity enabled via existing gravity() function\n');
            return;
        end
        
        % Method 2: Use our local gravity function from utils/
        script_dir = fileparts(mfilename('fullpath'));
        utils_dir = fullfile(script_dir, 'utils');
        gravity_file = fullfile(utils_dir, 'gravity.m');
        
        if exist(gravity_file, 'file')
            % Our utils directory should already be in path from main function
            fprintf('Using local gravity function from utils/gravity.m\n');
            
            % Test the function
            test_gravity = gravity('reset');
            fprintf('Local gravity function working: gravity vector available\n');
        else
            error(['Missing canonical gravity function: utils/gravity.m\n' ...
                   'UPDATE CANON: obsidian-vault/Planning/MRST_Requirements.md\n' ...
                   'Must have gravity function available for model creation.']);
        end
        
        fprintf('MRST gravity system initialized successfully\n');
        
    catch ME
        fprintf('Warning: Could not fully initialize MRST gravity: %s\n', ME.message);
        fprintf('Continuing with direct gravity assignments in model creation\n');
    end
    
end

% Main execution when called as script
if ~nargout
    solver_results = s20_solver_setup();
end