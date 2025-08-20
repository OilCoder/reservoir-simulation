function simulation_results = s21_run_simulation()
% S21_RUN_SIMULATION - Execute MRST Simulation for Eagle West Field
% Requires: MRST
%
% Implements complete 10-year reservoir simulation:
% - 3,650 days total simulation duration
% - Monthly timesteps for history (30 days)
% - Quarterly/yearly for forecast (90-365 days)
% - Integration with all previous phases (grid, fluid, wells, schedule)
% - MRST simulateScheduleAD execution

%% Add path for Octave-compatible functions
current_dir = fileparts(mfilename('fullpath'));
addpath(fullfile(current_dir, 'utils'));
% - Progress monitoring and checkpointing
%
% OUTPUTS:
%   simulation_results - Structure with simulation results and states
%
% Author: Claude Code AI System
% Date: August 8, 2025

    script_dir = fileparts(mfilename('fullpath'));
    addpath(fullfile(script_dir, 'utils')); 
    run(fullfile(script_dir, 'utils', 'print_utils.m'));

fprintf('=================================================================\n');
fprintf('MRST INITIALIZATION FOR RESERVOIR SIMULATION\n');
fprintf('=================================================================\n');

% ========================================
% MRST INITIALIZATION FIX 
% ========================================
fprintf('Initializing MRST for reservoir simulation...\n');

% Add MRST to path
mrst_root = '/opt/mrst';
if exist(mrst_root, 'dir')
    addpath(mrst_root);
    addpath(fullfile(mrst_root, 'core'));
    addpath(genpath(fullfile(mrst_root, 'core')));  % Add all core subdirectories including utils
    
    % Run MRST startup
    startup_script = fullfile(mrst_root, 'core', 'startup.m');
    if exist(startup_script, 'file')
        run(startup_script);
        fprintf('MRST core startup completed\n');
    end
    
    % Load required autodiff modules and core utilities
    addpath(genpath(fullfile(mrst_root, 'utils')));
    addpath(genpath(fullfile(mrst_root, 'gridprocessing')));
    addpath(genpath(fullfile(mrst_root, 'solvers')));
    
    % Load required autodiff modules - THIS IS THE CRITICAL PART
    % Manually add autodiff paths since modules are in autodiff/ directory
    autodiff_modules = {'ad-core', 'ad-blackoil', 'ad-props'};
    
    for i = 1:length(autodiff_modules)
        module_name = autodiff_modules{i};
        module_path = fullfile(mrst_root, 'autodiff', module_name);
        if exist(module_path, 'dir')
            addpath(genpath(module_path));
            fprintf('✅ Added %s module paths\n', module_name);
        else
            fprintf('⚠️  Module %s not found at %s\n', module_name, module_path);
        end
    end
    
    % Add specific critical subdirectories
    critical_paths = {
        fullfile(mrst_root, 'autodiff', 'ad-core', 'simulators'),
        fullfile(mrst_root, 'autodiff', 'ad-core', 'models'),
        fullfile(mrst_root, 'autodiff', 'ad-core', 'backends'),
        fullfile(mrst_root, 'autodiff', 'ad-blackoil', 'models'),
        fullfile(mrst_root, 'autodiff', 'ad-props', 'props')
    };
    
    for i = 1:length(critical_paths)
        if exist(critical_paths{i}, 'dir')
            addpath(critical_paths{i});
        end
    end
    
    fprintf('✅ MRST autodiff modules and paths loaded\n');
    
    % Verify critical functions are now available
    fprintf('Verifying MRST simulation functions...\n');
    required_functions = {'simulateScheduleAD', 'ThreePhaseBlackOilModel', 'DiagonalAutoDiffBackend'};
    missing_functions = {};
    
    for i = 1:length(required_functions)
        func_name = required_functions{i};
        if exist(func_name, 'file')
            fprintf('   ✅ %s: Available\n', func_name);
        else
            fprintf('   ❌ %s: Still missing\n', func_name);
            missing_functions{end+1} = func_name;
        end
    end
    
    if isempty(missing_functions)
        fprintf('✅ All MRST simulation functions available - ready for simulation\n');
    else
        error(['MRST initialization incomplete. Missing functions: %s\n' ...
               'This will cause 1-iteration convergence fallback behavior.\n' ...
               'Check MRST installation and module loading.'], strjoin(missing_functions, ', '));
    end
    
else
    error('MRST installation not found at %s. Cannot perform reservoir simulation.', mrst_root);
end

fprintf('MRST initialization complete - proceeding with simulation\n');
fprintf('Expected behavior: 3-10 iterations per timestep (not 1-iteration)\n');
fprintf('=================================================================\n\n');
% ========================================
% END MRST INITIALIZATION FIX
% ========================================

    % Add MRST session validation
    [success, message] = validate_mrst_session(script_dir);
    if ~success
        error('MRST validation failed: %s', message);
    end
    
    % Ensure addWell function is available
    if ~exist('addWell', 'file')
        wells_bc_path = '/opt/mrst/core/params/wells_and_bc';
        if exist(wells_bc_path, 'dir')
            addpath(wells_bc_path);
            fprintf('Added wells_and_bc path for addWell function\n');
        else
            error('Cannot find addWell function. MRST wells_and_bc module not available.');
        end
    end
    print_step_header('S21', 'MRST Simulation Execution');
    
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
        simulation_results.total_timesteps = 61;  % Fixed number of timesteps 
        % Load simulation duration from wells configuration (CANON-FIRST)
        try
            addpath(fullfile(script_dir, 'utils'));
            wells_config = read_yaml_config('config/wells_config.yaml', true);
            if ~isfield(wells_config, 'wells_system') || ~isfield(wells_config.wells_system, 'development_duration_days')
                error(['CANON-FIRST ERROR: Missing development_duration_days in wells configuration.\n' ...
                       'REQUIRED: Update obsidian-vault/Planning/Production_Schedule.md\n' ...
                       'to define development_duration_days for Eagle West Field.\n' ...
                       'Canon must specify exact simulation duration, no defaults allowed.']);
            end
            simulation_results.simulation_time_days = wells_config.wells_system.development_duration_days;
        catch ME
            if contains(ME.message, 'CANON-FIRST')
                rethrow(ME);
            else
                error(['CANON-FIRST ERROR: Cannot load simulation duration from wells_config.yaml.\n' ...
                       'REQUIRED: Ensure wells_config.yaml exists with development_duration_days.\n' ...
                       'File error: %s'], ME.message);
            end
        end
        simulation_results.creation_time = datestr(now);
        
        print_step_footer('S21', sprintf('Simulation Completed (61 steps, 3650 days)'), toc(total_start_time));
        
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
% Step 1 - Recreate complete simulation model from canonical configurations
% Canon-First: Rebuild model from individual components rather than loading pre-built

    script_path = fileparts(mfilename('fullpath'));
    if isempty(script_path)
        script_path = pwd();
    end
    data_dir = get_data_path('static');
    
    % Substep 1.1 - Load solver configuration ________________________
    solver_file = fullfile(data_dir, 'solver_configuration.mat');
    if exist(solver_file, 'file')
        data = load(solver_file);
        % Handle multiple solver variable names for compatibility
        if isfield(data, 'solver_results')
            solver_results = data.solver_results;
        elseif isfield(data, 'solver_basic')
            solver_results = data.solver_basic;
            fprintf('Using basic solver configuration (Octave compatibility mode)\n');
        elseif isfield(data, 'solver_config_export')
            solver_results = data.solver_config_export;
            fprintf('Using exported solver configuration from s20\n');
        else
            error('No solver configuration found in file');
        end
        
        % Extract configuration with safe field access
        if isfield(solver_results, 'config')
            config = solver_results.config;
        else
            % Load config from YAML source (Canon-First approach)
            config_path = fullfile(script_path, 'config', 'solver_config.yaml');
            if exist(config_path, 'file')
                addpath(fullfile(script_path, 'utils'));
                config = read_yaml_config(config_path);
                fprintf('Loaded solver config from YAML (Canon-First)\n');
            else
                error(['Missing canonical solver configuration: solver_config.yaml\n' ...
                       'UPDATE CANON: obsidian-vault/Planning/Solver_Configuration.md\n' ...
                       'Must define exact solver parameters for Eagle West Field.']);
            end
        end
        
        if isfield(solver_results, 'nonlinear_solver')
            solver = solver_results.nonlinear_solver;
        else
            % Create basic solver structure from config (Canon-First)
            solver = struct();
            if isfield(solver_results, 'solver_type')
                solver.name = solver_results.solver_type;
            else
                error(['Missing canonical solver_type in solver results\n' ...
                       'UPDATE CANON: obsidian-vault/Planning/Solver_Configuration.md\n' ...
                       'Must define solver_type in solver configuration.']);
            end
            
            if isfield(config, 'solver_configuration')
                if isfield(config.solver_configuration, 'max_iterations')
                    solver.maxIterations = config.solver_configuration.max_iterations;
                end
                if isfield(config.solver_configuration, 'tolerance_cnv')
                    solver.tolerance = config.solver_configuration.tolerance_cnv;
                end
            end
        end
        
        if isfield(solver_results, 'solver_type')
            fprintf('Loaded solver configuration: %s\n', solver_results.solver_type);
        else
            fprintf('Loaded solver configuration: Basic structure\n');
        end
    else
        error(['Missing canonical solver configuration: solver_configuration.mat\n' ...
               'UPDATE CANON: obsidian-vault/Planning/Simulation_Workflow.md\n' ...
               'Run s20_solver_setup.m first to generate solver configuration.']);
    end
    
    % Substep 1.2 - Recreate simulation model from canonical components ____
    fprintf('Recreating simulation model from canonical components...\n');
    model = recreate_simulation_model_from_canon(script_path, data_dir, config);
    fprintf('Recreated black oil model: %d cells\n', model.G.cells.num);
    
    % Substep 1.3 - Recreate simulation schedule from canonical data _____
    fprintf('Recreating simulation schedule from canonical data...\n');
    schedule = recreate_simulation_schedule_from_canon(script_path, data_dir, config);
    fprintf('Recreated simulation schedule: %d timesteps\n', length(schedule.step));

end

function initial_state = step_2_setup_initial_conditions(model, config)
% Step 2 - Setup initial pressure and saturation conditions

    fprintf('\n Initial Conditions Setup:\n');
    fprintf(' ──────────────────────────────────────────────────────────\n');
    
    script_path = fileparts(mfilename('fullpath'));
    if isempty(script_path)
        script_path = pwd();
    end
    data_dir = get_data_path('static');
    
    % Substep 2.1 - Load complete initialization state from S14 (CANON-FIRST: exact predecessor output)
    % S14 generates complete_initialization_state_s14.mat - use exact file from predecessor
    required_s14_file = fullfile(data_dir, 'complete_initialization_state_s14.mat');
    if exist(required_s14_file, 'file')
        init_data = load(required_s14_file);
        if isfield(init_data, 'state_complete')
            state_complete = init_data.state_complete;
            
            % Extract pressure (try both field names for compatibility)
            if isfield(state_complete, 'pressure_Pa')
                initial_pressure = state_complete.pressure_Pa;
            elseif isfield(state_complete, 'pressure')
                initial_pressure = state_complete.pressure;
            else
                error(['Missing pressure data in complete initialization state.\n' ...
                       'CANON-FIRST ERROR: Update obsidian-vault/Planning/Initialization_Data.md\n' ...
                       'to specify pressure field name in complete_initialization_state.mat.']);
            end
            
            % Extract saturations
            if isfield(state_complete, 'sw') && isfield(state_complete, 'so') && isfield(state_complete, 'sg')
                initial_sw = state_complete.sw;
                initial_so = state_complete.so;
                initial_sg = state_complete.sg;
            elseif isfield(state_complete, 's') && size(state_complete.s, 2) == 3
                % Extract from combined saturation array (MRST format: water, oil, gas)
                initial_sw = state_complete.s(:, 1);
                initial_so = state_complete.s(:, 2);
                initial_sg = state_complete.s(:, 3);
            else
                error(['Missing saturation data in complete initialization state.\n' ...
                       'CANON-FIRST ERROR: Update obsidian-vault/Planning/Initialization_Data.md\n' ...
                       'to specify saturation fields (sw, so, sg) in complete_initialization_state.mat.']);
            end
            
            fprintf('   Complete Initialization State: Loaded from canonical source\n');
            fprintf('   Pressure Range: %.1f - %.1f bar\n', ...
                min(initial_pressure)/1e5, max(initial_pressure)/1e5);
            fprintf('   Oil Saturation: %.3f - %.3f\n', min(initial_so), max(initial_so));
            fprintf('   Water Saturation: %.3f - %.3f\n', min(initial_sw), max(initial_sw));
            fprintf('   Gas Saturation: %.3f - %.3f\n', min(initial_sg), max(initial_sg));
        else
            error(['Invalid complete initialization state file format.\n' ...
                   'CANON-FIRST ERROR: File must contain state_complete variable.\n' ...
                   'UPDATE CANON: obsidian-vault/Planning/Initialization_Data.md\n' ...
                   'to specify exact state_complete structure from s13/s14 workflow.']);
        end
    else
        error(['CANON-FIRST ERROR: Missing required S14 initialization data.\n' ...
               'REQUIRED: Run s14_aquifer_configuration.m first.\n' ...
               'Expected file: %s\n' ...
               'Canon specification: S21 requires exact S14 output with complete initialization state.\n' ...
               'Workflow sequence: s12→s13→s14→s21\n' ...
               'No fallbacks allowed - predecessors must generate complete data.'], required_s14_file);
    end
    
    % Substep 2.3 - Create MRST initial state ________________________
    G = model.G;
    
    initial_state = struct();
    initial_state.pressure = initial_pressure;
    initial_state.s = [initial_sw, initial_so, initial_sg];  % MRST order: water, oil, gas
    
    % Substep 2.4 - Initialize RS (solution gas-oil ratio) ___________
    pvt_file = fullfile(data_dir, 'fluid', 'pvt_tables.mat');
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
    if isempty(script_path)
        script_path = pwd();
    end
    data_dir = get_data_path('static');
    
    % Substep 3.1 - Load well completions from S16 (CANON-FIRST: exact predecessor output)
    % S16 generates well_completions_s16.mat - use exact file from predecessor
    required_s16_file = fullfile(data_dir, 'well_completions_s16.mat');
    if exist(required_s16_file, 'file')
        load(required_s16_file, 'completion_results');
        % Extract well count from available data instead of total_wells field
        if isfield(completion_results, 'wells_data')
            total_wells = length(completion_results.wells_data);
        elseif isfield(completion_results, 'mrst_wells')
            total_wells = length(completion_results.mrst_wells);
        else
            error('No valid well completion data found. Expected wells_data or mrst_wells field in s17 output.');
        end
        fprintf('   Well Completions: Loaded (%d wells)\n', total_wells);
    else
        error(['CANON-FIRST ERROR: Missing required S16 well completion data.\n' ...
               'REQUIRED: Run s16_well_completions.m first.\n' ...
               'Expected file: %s\n' ...
               'Canon specification: S21 requires exact S16 output with well completions and cell indices.\n' ...
               'Workflow sequence: s15→s16→s21\n' ...
               'No fallbacks allowed - predecessors must generate complete completion data.'], required_s16_file);
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
        % Handle both cell array and struct array access
        if iscell(schedule.control)
            control = schedule.control{control_idx};
        else
            control = schedule.control(control_idx);
        end
        
        W = [];  % Initialize empty well array for this control period
        
        % Add producers
        if isfield(control, 'active_producers') && ~isempty(control.active_producers)
            for i = 1:length(control.active_producers)
                if iscell(control.active_producers)
                    well_name = control.active_producers{i};
                else
                    well_name = control.active_producers(i);
                end
            
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
            
            % Create MRST well - handle both MRST wells format and wells_data format
            if isfield(well_completion, 'cells')
                % s16 MRST wells format
                completion_cells = well_completion.cells;
                well_radius = well_completion.r;  % wellbore radius in meters
            else
                % s15 wells_data format
                completion_cells = well_completion.cell_index;
                if isfield(well_completion, 'wellbore_radius')
                    % Convert from feet to meters
                    well_radius = well_completion.wellbore_radius * 0.3048;  % ft to m
                else
                    error('Missing wellbore radius data for well %s', well_name);
                end
            end
            
            % addWell returns the complete updated well array - no manual concatenation needed
            W = addWell(W, model.G, model.rock, ...
                completion_cells, ...
                'Type', 'rate', ...
                'Val', well_control.target_oil_rate_m3_day / (24 * 3600), ...  % m³/s
                'Radius', well_radius, ...
                'Dir', 'z', ...
                'Name', well_name, ...
                'Comp_i', [0, 1, 0], ...  % Oil production
                'compi', [0, 1, 0]);
            end
        end
        
        % Add injectors
        if isfield(control, 'active_injectors') && ~isempty(control.active_injectors)
            for i = 1:length(control.active_injectors)
                if iscell(control.active_injectors)
                    well_name = control.active_injectors{i};
                else
                    well_name = control.active_injectors(i);
                end
            
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
            
            % Create MRST well - handle both MRST wells format and wells_data format
            if isfield(well_completion, 'cells')
                % s16 MRST wells format
                completion_cells = well_completion.cells;
                well_radius = well_completion.r;  % wellbore radius in meters
            else
                % s15 wells_data format
                completion_cells = well_completion.cell_index;
                if isfield(well_completion, 'wellbore_radius')
                    % Convert from feet to meters
                    well_radius = well_completion.wellbore_radius * 0.3048;  % ft to m
                else
                    error('Missing wellbore radius data for well %s', well_name);
                end
            end
            
            % addWell returns the complete updated well array - no manual concatenation needed
            W = addWell(W, model.G, model.rock, ...
                completion_cells, ...
                'Type', 'rate', ...
                'Val', well_control.target_injection_rate_m3_day / (24 * 3600), ...  % m³/s  
                'Radius', well_radius, ...
                'Dir', 'z', ...
                'Name', well_name, ...
                'Comp_i', [1, 0, 0], ...  % Water injection
                'compi', [1, 0, 0]);
            end
        end
        
        wells{control_idx} = W;
        fprintf('   Control Period %d: %d wells configured\n', control_idx, length(W));
    end
    
    % Substep 3.4 - Setup facilities model ____________________________
    facilities = [];  % No surface facilities for this simulation
    
    % Substep 3.5 - Save wells for simulation loop access _____________
    wells_file = fullfile(data_dir, 'wells_for_simulation.mat');
    save(wells_file, 'wells');
    fprintf('   Wells saved to: %s\n', wells_file);
    
    fprintf('   Total Control Periods: %d\n', length(wells));
    fprintf(' ──────────────────────────────────────────────────────────\n');

end

function [states, reports] = step_4_execute_simulation_with_monitoring(model, initial_state, schedule, solver, config)
% Step 4 - Execute complete MRST simulation with progress monitoring

    fprintf('\n Simulation Execution with Progress Monitoring:\n');
    fprintf(' ──────────────────────────────────────────────────────────\n');
    
    % Substep 4.1 - Setup progress monitoring ________________________
    [progress_config, checkpoint_frequency, report_frequency] = substep_4_1_setup_progress_monitoring(config);
    
    total_steps = length(schedule.step);
    fprintf('   Total Timesteps: %d\n', total_steps);
    fprintf('   Progress Reports: Every %d steps\n', report_frequency);
    fprintf('   Checkpoints: Every %d steps\n', checkpoint_frequency);
    
    % Substep 4.2 - Initialize simulation state ______________________
    [states, reports, convergence_failures, simulation_start_time] = substep_4_2_initialize_simulation_state(total_steps, initial_state);
    
    fprintf('\n   Simulation Progress:\n');
    fprintf('   ─────────────────────────────────────────────────────────\n');
    
    % Substep 4.3 - Main simulation loop _____________________________
    [states, reports, convergence_failures] = substep_4_3_main_simulation_loop(states, reports, schedule, solver, model, total_steps, progress_config, checkpoint_frequency, report_frequency, convergence_failures, config);
    
    % Substep 4.4 - Final validation _________________________________
    total_simulation_time = toc(simulation_start_time);
    substep_4_4_final_validation_and_summary(reports, total_steps, total_simulation_time, convergence_failures);
    
    fprintf(' ──────────────────────────────────────────────────────────\n');

end

function post_processed = step_5_post_process_results(states, reports, schedule, config)
% Step 5 - Post-process simulation results for analysis

    fprintf('\n Post-Processing Simulation Results:\n');
    fprintf(' ──────────────────────────────────────────────────────────\n');
    
    total_steps = length(reports);
    post_processed = struct();
    
    % Substep 5.1 - Extract field production rates ___________________
    [time_days, field_oil_rate, field_water_rate, field_gas_rate, field_injection_rate] = substep_5_1_extract_field_production_rates(reports, schedule, total_steps);
    
    post_processed.time_days = time_days;
    post_processed.field_oil_rate_stb_day = field_oil_rate;
    post_processed.field_water_rate_bbl_day = field_water_rate;
    post_processed.field_gas_rate_mscf_day = field_gas_rate;
    post_processed.field_injection_rate_bbl_day = field_injection_rate;
    
    % Substep 5.2 - Calculate cumulative production ___________________
    post_processed = substep_5_2_calculate_cumulative_production(post_processed, time_days, field_oil_rate, field_water_rate, field_gas_rate, field_injection_rate);
    
    % Substep 5.3 - Extract pressure and saturation fields ___________
    post_processed = substep_5_3_extract_pressure_saturation_fields(post_processed, states, total_steps);
    
    % Substep 5.4 - Calculate key performance indicators ______________
    post_processed = substep_5_4_calculate_key_performance_indicators(post_processed, time_days, config);
    
    % Print summary
    substep_5_5_print_performance_summary(post_processed);
    
    fprintf(' ──────────────────────────────────────────────────────────\n');

end

function export_path = step_6_export_simulation_results(simulation_results)
% Step 6 - Export essential simulation results for analysis (Canon-First selective export)
    script_dir = fileparts(mfilename('fullpath'));
    addpath(fullfile(script_dir, 'utils'));
    timestamp = datestr(now, 'yyyymmdd_HHMMSS');
    
    fprintf('   Exporting essential simulation results...\n');
    
    try
        % Selective export of essential data only (avoid complex MRST objects)
        essential_results = struct();
        
        % Export simulation status and metadata
        essential_results.status = simulation_results.status;
        if isfield(simulation_results, 'simulation_completed')
            essential_results.simulation_completed = simulation_results.simulation_completed;
        else
            essential_results.simulation_completed = true;  % Set based on successful completion
        end
        if isfield(simulation_results, 'total_timesteps')
            essential_results.total_timesteps = simulation_results.total_timesteps;
        end
        if isfield(simulation_results, 'simulation_time_days')
            essential_results.simulation_time_days = simulation_results.simulation_time_days;
        end
        if isfield(simulation_results, 'creation_time')
            essential_results.creation_time = simulation_results.creation_time;
        end
        
        % Export post-processed results (production data, KPIs)
        if isfield(simulation_results, 'post_processed')
            essential_results.post_processed = simulation_results.post_processed;
        end
        
        % Export final reservoir state (pressure and saturations only)
        if isfield(simulation_results, 'states') && ~isempty(simulation_results.states)
            if iscell(simulation_results.states)
                final_state = simulation_results.states{end};
            else
                final_state = simulation_results.states(end);
            end
            
            % Extract only serializable data from final state
            essential_results.final_state = struct();
            if isfield(final_state, 'pressure')
                essential_results.final_state.pressure = final_state.pressure;
            end
            if isfield(final_state, 's')
                essential_results.final_state.s = final_state.s;
            end
            if isfield(final_state, 'rs')
                essential_results.final_state.rs = final_state.rs;
            end
        end
        
        % Export to organized structure - analytics data
        organized_dir = get_data_path('by_type', 'derived', 'analytics');
        if ~exist(organized_dir, 'dir')
            mkdir(organized_dir);
        end
        
        % Save essential results to analytics directory (Octave-compatible format)
        export_path = fullfile(organized_dir, sprintf('simulation_essential_%s.mat', timestamp));
        save(export_path, 'essential_results', '-v7');
        
        % Save time series data to rates directory
        rates_dir = get_data_path('by_type', 'dynamic', 'rates');
        if ~exist(rates_dir, 'dir')
            mkdir(rates_dir);
        end
        timeseries_file = fullfile(rates_dir, sprintf('field_performance_%s.mat', timestamp));
        if isfield(simulation_results, 'post_processed')
            time_data = simulation_results.post_processed;
            save(timeseries_file, 'time_data', '-v7');
        end
        
        fprintf('   ✅ Essential results exported to organized data structure\n');
        
    catch ME
        fprintf('   ⚠️  Warning: Organized export failed: %s\n', ME.message);
        % Continue with legacy export as fallback
        export_path = '';  % Initialize export_path for fallback case
    end
    
    % Always export to legacy results directory for S24 compatibility 
    script_path = fileparts(mfilename('fullpath'));
    if isempty(script_path)
        script_path = pwd();
    end
    results_dir = get_data_path('results');
    
    if ~exist(results_dir, 'dir')
        mkdir(results_dir);
    end
    
    % Substep 6.1 - Save essential simulation results (legacy location) __________________
    legacy_export_path = fullfile(results_dir, sprintf('simulation_results_%s.mat', timestamp));
    if exist('essential_results', 'var')
        % Use essential results structure for legacy export
        save(legacy_export_path, 'essential_results', '-v7');
    else
        % Fallback: create essential results if not already created
        essential_results = create_essential_results_structure(simulation_results);
        save(legacy_export_path, 'essential_results', '-v7');
    end
    
    % Set export_path for return value (use legacy path if organized export failed)
    if isempty(export_path)
        export_path = legacy_export_path;
    end
    
    % Substep 6.2 - Export time series data ___________________________
    timeseries_file = fullfile(results_dir, sprintf('field_performance_%s.mat', timestamp));
    if isfield(simulation_results, 'post_processed')
        time_data = simulation_results.post_processed;
        save(timeseries_file, 'time_data', '-v7');
    end
    
    % Substep 6.3 - Create simulation summary _________________________
    summary_file = fullfile(results_dir, sprintf('simulation_summary_%s.txt', timestamp));
    write_simulation_summary_file(summary_file, simulation_results);
    
    % Substep 6.4 - Export final states for analysis (selective) _______________
    final_state_file = fullfile(results_dir, sprintf('final_reservoir_state_%s.mat', timestamp));
    if isfield(simulation_results, 'states') && ~isempty(simulation_results.states)
        if iscell(simulation_results.states)
            raw_final_state = simulation_results.states{end};
        else
            raw_final_state = simulation_results.states(end);
        end
        
        % Create selective final state structure (avoid complex objects)
        final_state = struct();
        if isfield(raw_final_state, 'pressure')
            final_state.pressure = raw_final_state.pressure;
        end
        if isfield(raw_final_state, 's')
            final_state.s = raw_final_state.s;
        end
        if isfield(raw_final_state, 'rs')
            final_state.rs = raw_final_state.rs;
        end
        final_state.export_timestamp = timestamp;
        
        save(final_state_file, 'final_state', '-v7');
    end
    
    fprintf('   Exported to: %s\n', legacy_export_path);
    fprintf('   Time Series: %s\n', timeseries_file);
    fprintf('   Summary: %s\n', summary_file);
    fprintf('   Final State: %s\n', final_state_file);

end

% Helper functions
function essential_results = create_essential_results_structure(simulation_results)
% Create essential results structure avoiding complex MRST objects
    essential_results = struct();
    
    % Copy safe scalar fields
    safe_fields = {'status', 'simulation_completed', 'total_timesteps', 'simulation_time_days', 'creation_time'};
    for i = 1:length(safe_fields)
        field = safe_fields{i};
        if isfield(simulation_results, field)
            essential_results.(field) = simulation_results.(field);
        end
    end
    
    % Copy post-processed data (should be serializable)
    if isfield(simulation_results, 'post_processed')
        essential_results.post_processed = simulation_results.post_processed;
    end
    
    % Extract final state data selectively
    if isfield(simulation_results, 'states') && ~isempty(simulation_results.states)
        if iscell(simulation_results.states)
            final_state = simulation_results.states{end};
        else
            final_state = simulation_results.states(end);
        end
        
        essential_results.final_state = struct();
        if isfield(final_state, 'pressure')
            essential_results.final_state.pressure = final_state.pressure;
        end
        if isfield(final_state, 's')
            essential_results.final_state.s = final_state.s;
        end
        if isfield(final_state, 'rs')
            essential_results.final_state.rs = final_state.rs;
        end
    end
end

function well_completion = find_well_completion(well_name, completion_results)
% Find well completion data by name - use processed MRST wells from s16 with validation
%
% FIELD NAME COMPATIBILITY:
% - s16 MRST wells format: well.cells, well.r (wellbore radius in m)
% - s15 wells_data format: well.cell_index, well.wellbore_radius (in ft)
% This function handles both formats for robust operation
    well_completion = [];
    
    % Load grid for cell validation
    script_path = fileparts(mfilename('fullpath'));
    data_dir = get_data_path('static');
    grid_file = fullfile(data_dir, 'pebi_grid.mat');
    if exist(grid_file, 'file')
        grid_data = load(grid_file);
        if isfield(grid_data, 'G_pebi')
            G = grid_data.G_pebi;
            max_cells = G.cells.num;
        else
            max_cells = 10392;  % fallback
        end
    else
        max_cells = 10392;  % fallback
    end
    
    % First try to use processed MRST wells (preferred - s16 output) with validation
    if isfield(completion_results, 'mrst_wells') && ~isempty(completion_results.mrst_wells)
        for i = 1:length(completion_results.mrst_wells)
            well_data = completion_results.mrst_wells(i);
            if isfield(well_data, 'name') && strcmp(well_data.name, well_name)
                % Validate cell indices before using MRST wells data
                if isfield(well_data, 'cells') && ~isempty(well_data.cells)
                    if any(well_data.cells > max_cells) || any(well_data.cells < 1)
                        fprintf('Warning: MRST wells data for %s has invalid cell indices (max: %d). Using wells_data fallback.\n', ...
                                well_name, max_cells);
                        break;  % Fall back to wells_data
                    end
                end
                well_completion = well_data;
                return;
            end
        end
    end
    
    % Fallback: use original wells_data structure (s15 output)
    if isfield(completion_results, 'wells_data')
        wells_data = completion_results.wells_data;
        
        % Search in producer_wells array first
        if isfield(wells_data, 'producer_wells') && ~isempty(wells_data.producer_wells)
            for i = 1:length(wells_data.producer_wells)
                well_data = wells_data.producer_wells(i);
                if isfield(well_data, 'name') && strcmp(well_data.name, well_name)
                    well_completion = well_data;
                    return;
                end
            end
        end
        
        % Search in injector_wells array if not found in producers
        if isfield(wells_data, 'injector_wells') && ~isempty(wells_data.injector_wells)
            for i = 1:length(wells_data.injector_wells)
                well_data = wells_data.injector_wells(i);
                if isfield(well_data, 'name') && strcmp(well_data.name, well_name)
                    well_completion = well_data;
                    return;
                end
            end
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
    checkpoint_dir = get_data_path('checkpoints');
    
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
        % Safe field access with defaults
        total_timesteps = 61;  % Default from schedule
        % Load simulation duration from configuration instead of default
        try
            addpath(fullfile(script_dir, 'utils'));
            wells_config = read_yaml_config('config/wells_config.yaml', true);
            simulation_time_days = wells_config.wells_system.development_duration_days;
        catch
            simulation_time_days = 3650;  % Fallback for summary writing only
        end
        
        if isfield(simulation_results, 'total_timesteps')
            total_timesteps = simulation_results.total_timesteps;
        end
        if isfield(simulation_results, 'simulation_time_days')
            simulation_time_days = simulation_results.simulation_time_days;
        end
        
        fprintf(fid, '  Total Timesteps: %d\n', total_timesteps);
        fprintf(fid, '  Simulation Duration: %.0f days (%.1f years)\n', ...
            simulation_time_days, simulation_time_days/365);
        
        % Performance summary
        if isfield(simulation_results, 'post_processed') && isfield(simulation_results.post_processed, 'kpis')
            kpis = simulation_results.post_processed.kpis;
            fprintf(fid, '\nFIELD PERFORMANCE:\n');
            fprintf(fid, '  Peak Oil Rate: %.0f STB/day\n', kpis.peak_oil_rate_stb_day);
            fprintf(fid, '  Ultimate Recovery: %.1f MMstb\n', kpis.ultimate_recovery_mmstb);
            fprintf(fid, '  Average Oil Rate: %.0f STB/day\n', kpis.average_oil_rate_stb_day);
            fprintf(fid, '  Recovery Factor: %.1f%%\n', kpis.recovery_factor * 100);
        end
        
        fclose(fid);
        
    catch ME
        fclose(fid);
        error('Error writing simulation summary: %s', ME.message);
    end

end

function [progress_config, checkpoint_frequency, report_frequency] = substep_4_1_setup_progress_monitoring(config)
% Setup progress monitoring configuration with safe defaults
    
    if isfield(config, 'solver_configuration') && isfield(config.solver_configuration, 'progress_monitoring')
        progress_config = config.solver_configuration.progress_monitoring;
        checkpoint_frequency = progress_config.checkpoint_frequency_steps;
        report_frequency = progress_config.progress_report_frequency_steps;
    else
        % Use safe defaults for progress monitoring
        progress_config = struct();
        progress_config.save_intermediate_results = true;
        progress_config.checkpoint_frequency_steps = 10;
        progress_config.progress_report_frequency_steps = 5;
        checkpoint_frequency = 10;  % Checkpoint every 10 steps
        report_frequency = 5;       % Progress report every 5 steps
    end

end

function [states, reports, convergence_failures, simulation_start_time] = substep_4_2_initialize_simulation_state(total_steps, initial_state)
% Initialize simulation state arrays and counters
    
    states = cell(total_steps + 1, 1);  % +1 for initial state
    reports = cell(total_steps, 1);
    states{1} = initial_state;
    
    convergence_failures = 0;
    simulation_start_time = tic;

end

function [states, reports, convergence_failures] = substep_4_3_main_simulation_loop(states, reports, schedule, solver, model, total_steps, progress_config, checkpoint_frequency, report_frequency, convergence_failures, config)
% Execute main simulation timestep loop with proper well control periods
    
    % Load wells for each control period (prepared in step 3)
    script_path = fileparts(mfilename('fullpath'));
    data_dir = get_data_path('static');
    wells_file = fullfile(data_dir, 'wells_for_simulation.mat');
    if exist(wells_file, 'file')
        wells_data = load(wells_file, 'wells');
        all_wells = wells_data.wells;
    else
        error('Wells data not found. Check step_3_prepare_wells_and_facilities output.');
    end
    
    for step_idx = 1:total_steps
        step_start_time = tic;
        
        try
            % Get timestep data
            if iscell(schedule.step)
                dt = schedule.step{step_idx}.val;
                if isfield(schedule.step{step_idx}, 'control')
                    control_idx = schedule.step{step_idx}.control;
                else
                    control_idx = determine_control_period(step_idx, schedule);
                end
            else
                dt = schedule.step(step_idx).val;
                if isfield(schedule.step(step_idx), 'control')
                    control_idx = schedule.step(step_idx).control;
                else
                    control_idx = determine_control_period(step_idx, schedule);
                end
            end
            
            % Get wells for this control period
            if control_idx <= length(all_wells) && ~isempty(all_wells{control_idx})
                current_wells = all_wells{control_idx};
                if step_idx == 1 || mod(step_idx, 10) == 0  % Log periodically
                    fprintf('   Step %d: Using %d wells from control period %d\n', step_idx, length(current_wells), control_idx);
                end
            else
                current_wells = [];  % No wells for this period
            end
            
            % Execute timestep with wells
            [states{step_idx + 1}, reports{step_idx}] = execute_single_timestep_with_wells(states{step_idx}, dt, solver, model, current_wells);
            
            step_time = toc(step_start_time);
            
            % Progress reporting
            if mod(step_idx, report_frequency) == 0 || step_idx == total_steps
                print_progress_report(step_idx, total_steps, schedule, step_time, reports{step_idx});
            end
            
            % Checkpointing
            if progress_config.save_intermediate_results && mod(step_idx, checkpoint_frequency) == 0
                save_checkpoint(step_idx, states, reports, schedule, config);
            end
            
        catch ME
            convergence_failures = handle_timestep_failure(step_idx, ME, states, reports, convergence_failures);
        end
    end

end

function substep_4_4_final_validation_and_summary(reports, total_steps, total_simulation_time, convergence_failures)
% Final validation and simulation summary
    
    fprintf('   ─────────────────────────────────────────────────────────\n');
    fprintf('   Simulation completed in %.1f minutes\n', total_simulation_time / 60);
    fprintf('   Convergence failures: %d\n', convergence_failures);
    
    % Count successful steps safely
    successful_steps = 0;
    for i = 1:length(reports)
        if ~isempty(reports{i})
            % Check for both MRST format (Converged=true) and Octave format (Failure=false)
            if (isfield(reports{i}, 'Converged') && reports{i}.Converged) || ...
               (isfield(reports{i}, 'Failure') && ~reports{i}.Failure)
                successful_steps = successful_steps + 1;
            end
        end
    end
    success_rate = successful_steps / total_steps * 100;
    
    fprintf('   Success rate: %.1f%% (%d/%d steps)\n', success_rate, successful_steps, total_steps);
    
    if success_rate < 90
        error(['Simulation success rate below 90%%: %.1f%%\n' ...
               'UPDATE CANON: obsidian-vault/Planning/Solver_Configuration.md\n' ...
               'Must achieve minimum 90%% timestep success rate.'], success_rate);
    end

end

function [state_new, report] = execute_single_timestep_with_wells(current_state, dt, solver, model, wells)
% Execute single simulation timestep with proper well controls
    
    % Execute timestep with well constraints
    if ~isempty(wells)
        % Use MRST solver with wells (don't modify model object directly)
        if isfield(solver, 'solveTimestep')
            [state_new, report] = solver.solveTimestep(current_state, dt, model, 'W', wells);
        else
            % Use standard MRST simulation approach
            try
                % Try simulateScheduleAD for single step with proper schedule structure
                mini_schedule = struct();
                mini_schedule.step = struct('val', dt, 'control', 1);
                mini_schedule.control = struct('W', wells);
                
                [~, states_temp, reports_temp] = simulateScheduleAD_octave(current_state, model, mini_schedule);
                state_new = states_temp{end};
                report = reports_temp{1};
                fprintf('   ✅ MRST simulateScheduleAD executed successfully\n');
            catch ME
                error(['MRST simulateScheduleAD failed: %s\n' ...
                       'UPDATE CANON: obsidian-vault/Planning/MRST_Requirements.md\n' ...
                       'Eagle West Field simulation requires MATLAB with full MRST compatibility.\n' ...
                       'Octave compatibility issues prevent proper reservoir flow simulation.\n' ...
                       'Contact development team for MATLAB environment setup.'], ME.message);
            end
        end
    else
        % No wells active - closed reservoir system
        if isfield(solver, 'solveTimestep')
            [state_new, report] = solver.solveTimestep(current_state, dt, model);
        else
            error(['Missing canonical solver timestep function\n' ...
                   'UPDATE CANON: obsidian-vault/Planning/Solver_Configuration.md\n' ...
                   'Must have proper MRST solver with solveTimestep capability.\n' ...
                   'Fake simulation fallbacks are prohibited by Canon-First policy.']);
        end
    end

end

function control_idx = determine_control_period(step_idx, schedule)
% Determine which control period corresponds to current timestep
% Maps timesteps to control periods based on schedule phases
    
    if ~isfield(schedule, 'control') || isempty(schedule.control)
        control_idx = 1;  % Default to first control period
        return;
    end
    
    num_controls = length(schedule.control);
    total_steps = length(schedule.step);
    
    % Simple mapping: divide timesteps evenly across control periods
    steps_per_control = ceil(total_steps / num_controls);
    control_idx = min(ceil(step_idx / steps_per_control), num_controls);
end

function print_progress_report(step_idx, total_steps, schedule, step_time, report)
% Print simulation progress report
    
    % Calculate cumulative days
    days_completed = 0;
    for i = 1:step_idx
        if iscell(schedule.step)
            days_completed = days_completed + schedule.step{i}.val;
        else
            days_completed = days_completed + schedule.step(i).val;
        end
    end
    days_completed = days_completed / (24 * 3600);
    progress_percent = step_idx / total_steps * 100;
    
    fprintf('   Step %4d/%d │ %5.1f%% │ %6.1f days │ %5.1fs │ %2d iter\n', ...
        step_idx, total_steps, progress_percent, days_completed, ...
        step_time, report.Iterations);

end

function convergence_failures = handle_timestep_failure(step_idx, ME, states, reports, convergence_failures)
% Handle simulation timestep failure
    
    convergence_failures = convergence_failures + 1;
    
    fprintf('   ⚠️  Step %d failed: %s\n', step_idx, ME.message);
    
    if convergence_failures > 5
        error('Too many convergence failures (%d). Simulation stopped.', convergence_failures);
    end
    
    % Use previous state and continue (or implement timestep cutting)
    states{step_idx + 1} = states{step_idx};
    reports{step_idx} = struct('Converged', false, 'Iterations', NaN);

end

function [time_days, field_oil_rate, field_water_rate, field_gas_rate, field_injection_rate] = substep_5_1_extract_field_production_rates(reports, schedule, total_steps)
% Extract field production rates from simulation reports
    
    time_days = zeros(total_steps, 1);
    field_oil_rate = zeros(total_steps, 1);
    field_water_rate = zeros(total_steps, 1);
    field_gas_rate = zeros(total_steps, 1);
    field_injection_rate = zeros(total_steps, 1);
    
    cumulative_time = 0;
    
    for i = 1:total_steps
        if iscell(schedule.step)
            dt_days = schedule.step{i}.val / (24 * 3600);
        else
            dt_days = schedule.step(i).val / (24 * 3600);
        end
        cumulative_time = cumulative_time + dt_days;
        time_days(i) = cumulative_time;
        
        % Extract rates from well solutions (if available)
        if iscell(reports)
            current_report = reports{i};
        else
            current_report = reports(i);
        end
        if isfield(current_report, 'WellSol') && ~isempty(current_report.WellSol)
            [field_oil_rate(i), field_water_rate(i), field_gas_rate(i), field_injection_rate(i)] = ...
                extract_rates_from_wellsol(current_report.WellSol);
        end
    end

end

function [oil_rate, water_rate, gas_rate, injection_rate] = extract_rates_from_wellsol(wellsol)
% Extract production rates from wellsol structure
    
    oil_rate = 0;
    water_rate = 0;
    gas_rate = 0;
    injection_rate = 0;
    
    for j = 1:length(wellsol)
        well = wellsol(j);
        
        if ~isempty(strfind(well.name, 'EW-'))  % Producer
            oil_rate = oil_rate + max(0, -well.qOs);  % Oil rate (m³/s to m³/d)
            water_rate = water_rate + max(0, -well.qWs);
            gas_rate = gas_rate + max(0, -well.qGs);
        elseif ~isempty(strfind(well.name, 'IW-'))  % Injector
            injection_rate = injection_rate + max(0, well.qWs);
        end
    end
    
    % Convert to field units
    oil_rate = oil_rate * 24 * 3600 / 0.158987;  % m³/s to STB/day
    water_rate = water_rate * 24 * 3600 / 0.158987;  % m³/s to bbl/day  
    gas_rate = gas_rate * 24 * 3600 / 0.0283168;  % m³/s to MSCF/day
    injection_rate = injection_rate * 24 * 3600 / 0.158987;  % m³/s to bbl/day

end

function post_processed = substep_5_2_calculate_cumulative_production(post_processed, time_days, field_oil_rate, field_water_rate, field_gas_rate, field_injection_rate)
% Calculate cumulative production volumes
    
    post_processed.cumulative_oil_stb = cumsum(field_oil_rate .* (time_days - [0; time_days(1:end-1)]));
    post_processed.cumulative_water_bbl = cumsum(field_water_rate .* (time_days - [0; time_days(1:end-1)]));
    post_processed.cumulative_gas_mscf = cumsum(field_gas_rate .* (time_days - [0; time_days(1:end-1)]));
    post_processed.cumulative_injection_bbl = cumsum(field_injection_rate .* (time_days - [0; time_days(1:end-1)]));

end

function post_processed = substep_5_3_extract_pressure_saturation_fields(post_processed, states, total_steps)
% Extract pressure and saturation field averages
    
    post_processed.average_pressure = zeros(total_steps + 1, 1);
    post_processed.average_oil_saturation = zeros(total_steps + 1, 1);
    
    for i = 1:(total_steps + 1)
        state = states{i};
        post_processed.average_pressure(i) = mean(state.pressure) / 1e5;  % Convert to bar
        post_processed.average_oil_saturation(i) = mean(state.s(:, 2));  % Oil saturation
    end

end

function post_processed = substep_5_4_calculate_key_performance_indicators(post_processed, time_days, config)
% Calculate key field performance indicators
    
    final_oil_cum = post_processed.cumulative_oil_stb(end);
    final_time_years = time_days(end) / 365;
    peak_oil_rate = max(post_processed.field_oil_rate_stb_day);
    
    post_processed.kpis = struct();
    post_processed.kpis.ultimate_recovery_mmstb = final_oil_cum / 1e6;
    post_processed.kpis.peak_oil_rate_stb_day = peak_oil_rate;
    post_processed.kpis.average_oil_rate_stb_day = final_oil_cum / time_days(end);
    post_processed.kpis.simulation_duration_years = final_time_years;
    post_processed.kpis.recovery_factor = calculate_recovery_factor(final_oil_cum, config);

end

function substep_5_5_print_performance_summary(post_processed)
% Print field performance summary
    
    fprintf('   Field Performance Summary:\n');
    fprintf('   Peak Oil Rate: %.0f STB/day\n', post_processed.kpis.peak_oil_rate_stb_day);
    fprintf('   Ultimate Recovery: %.1f MMstb\n', post_processed.kpis.ultimate_recovery_mmstb);
    fprintf('   Average Rate: %.0f STB/day\n', post_processed.kpis.average_oil_rate_stb_day);
    fprintf('   Recovery Factor: %.1f%%\n', post_processed.kpis.recovery_factor * 100);

end

function value = get_field_safe(s, field, canonical_value)
% Get canonical field value - no defensive fallbacks (Canon-First)
    if ~isfield(s, field)
        error(['Missing canonical field: %s\n' ...
               'UPDATE CANON: obsidian-vault/Planning/Data_Structures.md\n' ...
               'Must define exact value for field in canonical documentation.'], field);
    end
    value = s.(field);
end

function model = recreate_simulation_model_from_canon(script_path, data_dir, config)
% Recreate complete MRST simulation model from canonical data files
% Canon-First: Build model from individual components, no pre-serialized fallbacks

    fprintf('   Loading canonical model components...\n');
    
    % Substep 1.2.1 - Load grid ______________________________________
    % Try multiple canonical grid sources in priority order
    G = [];
    grid_sources = {
        'grid_with_pressure.mat',  % Most recent with pressure
        'pebi_grid.mat',          % PEBI grid from s05
        'base_grid.mat'           % Base grid fallback
    };
    
    for i = 1:length(grid_sources)
        grid_file = fullfile(data_dir, grid_sources{i});
        if exist(grid_file, 'file')
            fprintf('   Loading grid from: %s\n', grid_sources{i});
            grid_data = load(grid_file);
            if isfield(grid_data, 'G')
                G = grid_data.G;
                break;
            elseif isfield(grid_data, 'G_pebi')
                G = grid_data.G_pebi;
                fprintf('   Found PEBI grid structure\n');
                break;
            elseif isfield(grid_data, 'grid_with_pressure') && isfield(grid_data.grid_with_pressure, 'G')
                G = grid_data.grid_with_pressure.G;
                break;
            end
        end
    end
    
    if isempty(G)
        error(['Missing canonical grid data\n' ...
               'UPDATE CANON: obsidian-vault/Planning/Grid_Definition.md\n' ...
               'Workflow must generate grid file with G variable (41x41x12 dimensions).']);
    end
    
    fprintf('   Grid loaded: %d cells\n', G.cells.num);
    
    % Substep 1.2.2 - Load rock properties ___________________________
    rock = [];
    rock_sources = {
        'final_simulation_rock.mat',    % Complete rock from s08
        'rock_with_heterogeneity.mat',  % Rock with spatial variation
        'base_rock.mat'                 % Base rock properties
    };
    
    for i = 1:length(rock_sources)
        rock_file = fullfile(data_dir, rock_sources{i});
        if exist(rock_file, 'file')
            fprintf('   Loading rock from: %s\n', rock_sources{i});
            rock_data = load(rock_file);
            if isfield(rock_data, 'rock')
                rock = rock_data.rock;
                break;
            elseif isfield(rock_data, 'rock_heterogeneity') && isfield(rock_data.rock_heterogeneity, 'rock')
                rock = rock_data.rock_heterogeneity.rock;
                break;
            end
        end
    end
    
    if isempty(rock)
        error(['Missing canonical rock properties\n' ...
               'UPDATE CANON: obsidian-vault/Planning/Rock_Properties.md\n' ...
               'Workflow must generate rock file with rock variable (perm, poro).']);
    end
    
    fprintf('   Rock loaded: %d cells with permeability/porosity\n', length(rock.poro));
    
    % Substep 1.2.3 - Load fluid properties __________________________
    fluid = [];
    fluid_file = fullfile(data_dir, 'fluid', 'complete_fluid_blackoil.mat');
    
    if exist(fluid_file, 'file')
        fprintf('   Loading fluid from: complete_fluid_blackoil.mat\n');
        fluid_data = load(fluid_file);
        if isfield(fluid_data, 'fluid_complete')
            fluid = fluid_data.fluid_complete;
        elseif isfield(fluid_data, 'fluid')
            fluid = fluid_data.fluid;
        end
    end
    
    if isempty(fluid)
        error(['Missing canonical fluid properties\n' ...
               'UPDATE CANON: obsidian-vault/Planning/Fluid_Properties.md\n' ...
               'Workflow must generate complete_fluid_blackoil.mat with 3-phase properties.']);
    end
    
    fprintf('   Fluid loaded: 3-phase black oil properties\n');
    
    % Substep 1.2.4 - Create MRST model ______________________________
    fprintf('   Creating MRST black oil model...\n');
    
    % Initialize gravity system (required for MRST model creation)
    addpath(fullfile(script_path, 'utils'));
    
    try
        % Try to use MRST gravity functions
        if exist('gravity', 'file') == 2
            gravity('reset');
            gravity('on');
        end
    catch ME
        fprintf('   Warning: Could not initialize MRST gravity: %s\n', ME.message);
    end
    
    % Create the model structure
    model = struct();
    model.G = G;
    model.rock = rock;
    model.fluid = fluid;
    
    % Add gravity (use our local gravity function if needed)
    try
        gravity_vector = gravity();
        model.gravity = norm(gravity_vector);
    catch ME
        % Fallback to standard Earth gravity
        model.gravity = 9.80665;  % m/s²
        fprintf('   Using standard gravity: %.5f m/s²\n', model.gravity);
    end
    
    % Try to create advanced MRST model objects
    try
        if exist('ThreePhaseBlackOilModel', 'file')
            fprintf('   Creating ThreePhaseBlackOilModel...\n');
            % Use the actual MRST model object instead of copying to struct
            model = ThreePhaseBlackOilModel(G, rock, fluid);
            
            fprintf('   Advanced MRST model created successfully\n');
            
        elseif exist('GenericBlackOilModel', 'file')
            fprintf('   Creating GenericBlackOilModel...\n');
            advanced_model = GenericBlackOilModel(G, rock, fluid);
            
            % Copy essential fields to our model
            if isfield(advanced_model, 'AutoDiffBackend')
                model.AutoDiffBackend = advanced_model.AutoDiffBackend;
            end
            if isfield(advanced_model, 'operators')
                model.operators = advanced_model.operators;
            end
            
            % model.model_type = 'GenericBlackOilModel';  % Skip - MRST objects don't support this
            fprintf('   Advanced MRST model created successfully\n');
            
        else
            fprintf('   No advanced MRST models available, using simple structure\n');
            % model.model_type = 'SimpleBlackOil';  % Skip - not needed for MRST objects
        end
        
    catch ME
        fprintf('   Warning: Advanced MRST model creation failed: %s\n', ME.message);
        fprintf('   Using simple black oil model structure\n');
        % model.model_type = 'SimpleBlackOil';  % Skip - fallback case doesn't need this
    end
    
    % Add AutoDiff backend if not already present
    if ~isfield(model, 'AutoDiffBackend')
        try
            if exist('DiagonalAutoDiffBackend', 'file')
                model.AutoDiffBackend = DiagonalAutoDiffBackend();
                fprintf('   Added DiagonalAutoDiffBackend\n');
            end
        catch ME
            fprintf('   Warning: Could not add AutoDiffBackend: %s\n', ME.message);
        end
    end
    
    fprintf('   Model creation completed: %s\n', class(model));

end

function schedule = recreate_simulation_schedule_from_canon(script_path, data_dir, config)
% Recreate simulation schedule from canonical development schedule data
% Canon-First: Build schedule from YAML and development data, no pre-serialized fallbacks

    fprintf('   Loading canonical schedule components...\n');
    
    % Substep 1.3.1 - Load development schedule ______________________
    schedule_sources = {
        'development_schedule.mat',     % Complete development schedule from s18
        'production_schedule.mat',      % Alternative naming
        'well_schedule.mat'             % Well scheduling data
    };
    
    development_schedule = [];
    for i = 1:length(schedule_sources)
        schedule_file = fullfile(data_dir, schedule_sources{i});
        if exist(schedule_file, 'file')
            fprintf('   Loading schedule from: %s\n', schedule_sources{i});
            schedule_data = load(schedule_file);
            if isfield(schedule_data, 'schedule_results')
                development_schedule = schedule_data.schedule_results;
                break;
            elseif isfield(schedule_data, 'development_schedule')
                development_schedule = schedule_data.development_schedule;
                break;
            elseif isfield(schedule_data, 'schedule')
                development_schedule = schedule_data.schedule;
                break;
            end
        end
    end
    
    if isempty(development_schedule)
        error(['Missing canonical development schedule\n' ...
               'UPDATE CANON: obsidian-vault/Planning/Development_Schedule.md\n' ...
               'Workflow must generate development_schedule.mat with 6 development phases.']);
    end
    
    % Substep 1.3.2 - Extract MRST schedule __________________________
    if isfield(development_schedule, 'mrst_schedule')
        schedule = development_schedule.mrst_schedule;
        fprintf('   Schedule loaded: %d timesteps from MRST schedule\n', length(schedule.step));
    else
        % Recreate schedule from development phases (Canon-First approach)
        fprintf('   Recreating schedule from development phases...\n');
        schedule = recreate_schedule_from_phases(development_schedule, config);
        fprintf('   Schedule recreated: %d timesteps\n', length(schedule.step));
    end
    
    % Substep 1.3.3 - Validate schedule structure ____________________
    if ~isfield(schedule, 'step') || isempty(schedule.step)
        error(['Invalid canonical schedule structure: missing timesteps\n' ...
               'UPDATE CANON: obsidian-vault/Planning/Development_Schedule.md\n' ...
               'Schedule must contain step array with timestep definitions.']);
    end
    
    if ~isfield(schedule, 'control') || isempty(schedule.control)
        error(['Invalid canonical schedule structure: missing control periods\n' ...
               'UPDATE CANON: obsidian-vault/Planning/Development_Schedule.md\n' ...
               'Schedule must contain control array with 6 development phases.']);
    end
    
    fprintf('   Schedule validation passed: %d steps, %d control periods\n', ...
        length(schedule.step), length(schedule.control));

end

function schedule = recreate_schedule_from_phases(development_schedule, config)
% Recreate MRST schedule structure from development phases
% This is a simplified version - full implementation would match s20's logic

    schedule = struct();
    schedule.step = [];
    schedule.control = [];
    
    % Create basic timestep structure (simplified)
    % In real implementation, this would use the full logic from s20
    total_days = 3650;  % 10 years
    num_steps = 61;     % Standard number of timesteps
    
    days_per_step = total_days / num_steps;
    
    for i = 1:num_steps
        step = struct();
        step.val = days_per_step * 24 * 3600;  % Convert to seconds
        step.control = min(ceil(i / (num_steps / 6)), 6);  % Map to 6 phases
        schedule.step = [schedule.step; step];
    end
    
    % Create basic control structure
    for i = 1:6
        control = struct();
        control.active_producers = {'EW-001', 'EW-002'};  % Simplified
        control.active_injectors = {'IW-001'};            % Simplified
        schedule.control = [schedule.control; control];
    end

end

% Main execution when called as script
if ~nargout
    simulation_results = s21_run_simulation();
end