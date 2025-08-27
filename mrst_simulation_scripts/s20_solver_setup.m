function solver_results = s20_solver_setup()
% S20_SOLVER_SETUP - Simplified MRST Solver Configuration for Eagle West Field
% 
% POLICY COMPLIANT: Functions under 50 lines, no over-engineering
% Requires: MRST
%
% OUTPUTS:
%   solver_results - Structure with solver configuration and model
%
% Author: Claude Code AI System
% Date: August 23, 2025

    script_dir = fileparts(mfilename('fullpath'));
    addpath(fullfile(script_dir, 'utils')); 
    addpath(fullfile(script_dir, 'utils', 'solver'));
    
    % Suppress isdir deprecation warnings from MRST internal functions
    suppress_isdir_warnings();
    run(fullfile(script_dir, 'utils', 'print_utils.m'));

    % Add MRST session validation
    [success, message] = validate_mrst_session(script_dir);
    if ~success
        error('MRST validation failed: %s', message);
    end
    print_step_header('S20', 'MRST Solver Configuration');
    
    % Initialize MRST gravity system
    fprintf('Initializing MRST gravity system...\n');
    setup_mrst_gravity();
    
    total_start_time = tic;
    
    % Load configuration and model data
    step_start = tic;
    [config, model_data] = load_configuration_and_model();
    print_step_result(1, 'Load Configuration and Model Data', 'success', toc(step_start));
    
    % Configure black oil model
    step_start = tic;
    black_oil_model = black_oil_model_setup(model_data.G, model_data.rock, model_data.fluid, config);
    print_step_result(2, 'Configure Black Oil Model', 'success', toc(step_start));
    
    % Setup nonlinear solver
    step_start = tic;
    nonlinear_solver = nonlinear_solver_setup(config);
    print_step_result(3, 'Setup Nonlinear Solver', 'success', toc(step_start));
    
    % Configure timestep control
    step_start = tic;
    timestep_control = timestep_control_setup(config);
    print_step_result(4, 'Configure Timestep Control', 'success', toc(step_start));
    
    % Setup simulation schedule
    step_start = tic;
    simulation_schedule = simulation_schedule_setup(model_data, config);
    print_step_result(5, 'Setup Simulation Schedule', 'success', toc(step_start));
    
    % Export solver configuration
    step_start = tic;
    export_path = export_solver_configuration(config, model_data, black_oil_model, nonlinear_solver, timestep_control, simulation_schedule);
    print_step_result(6, 'Export Solver Configuration', 'success', toc(step_start));
    
    % Create results structure
    solver_results = create_solver_results(config, model_data, black_oil_model, nonlinear_solver, timestep_control, simulation_schedule, export_path);
    
    print_final_summary(solver_results, toc(total_start_time));
end

function [config, model_data] = load_configuration_and_model()
% Load configuration and required model data
    script_dir = fileparts(mfilename('fullpath'));
    
    % Load configuration
    config_file = fullfile(script_dir, 'config', 'solver_config.yaml');
    if exist(config_file, 'file')
        config = read_yaml_config(config_file);
    else
        error('Configuration file not found: %s. REQUIRED: Create solver_config.yaml with solver configuration.', config_file);
    end
    
    % Load model data
    model_data = load_model_data(script_dir);
end

function model_data = load_model_data(script_dir)
% Load required model data from previous steps
    data_dir = '/workspace/data/simulation_data';
    
    % Load grid
    grid_file = fullfile(data_dir, 'pebi_grid.mat');
    if ~exist(grid_file, 'file')
        error('Grid file not found: %s. REQUIRED: Run s03_create_pebi_grid.m first.', grid_file);
    end
    grid_data = load(grid_file);
    
    % Load rock properties
    rock_file = fullfile(data_dir, 'final_simulation_rock.mat');
    if ~exist(rock_file, 'file')
        error('Rock properties file not found: %s. REQUIRED: Complete rock property workflow first.', rock_file);
    end
    rock_data = load(rock_file);
    
    % Load fluid properties
    fluid_file = fullfile(data_dir, 'fluid', 'fluid_with_capillary_pressure.mat');
    if ~exist(fluid_file, 'file')
        error('Fluid properties file not found: %s. REQUIRED: Complete fluid property workflow first.', fluid_file);
    end
    fluid_data = load(fluid_file);
    
    % Load wells
    wells_file = fullfile(data_dir, 'wells_final.mat');
    if ~exist(wells_file, 'file')
        error('Wells file not found: %s. REQUIRED: Complete wells workflow first.', wells_file);
    end
    wells_data = load(wells_file);
    
    % Assemble model data
    model_data = struct();
    model_data.G = grid_data.G;
    model_data.rock = rock_data.enhanced_rock;
    model_data.fluid = fluid_data.fluid;
    model_data.wells = wells_data.W;
end

function export_path = export_solver_configuration(config, model_data, black_oil_model, nonlinear_solver, timestep_control, simulation_schedule)
% Export solver configuration and data for simulation
    script_dir = fileparts(mfilename('fullpath'));
    data_dir = '/workspace/data/simulation_data';
    
    % Create directory if it doesn't exist
    if ~exist(data_dir, 'dir')
        mkdir(data_dir);
    end
    
    % Export solver configuration
    solver_config_file = fullfile(data_dir, 'solver_configuration.mat');
    save(solver_config_file, 'config', 'nonlinear_solver', 'timestep_control', '-v7');
    
    % Export simulation parameters
    export_simulation_parameters(data_dir, config);
    
    % Export model setup
    model_file = fullfile(data_dir, 'simulation_model.mat');
    save(model_file, 'black_oil_model', 'simulation_schedule', '-v7');
    
    export_path = data_dir;
    fprintf('Solver configuration exported to: %s\n', data_dir);
end

function export_simulation_parameters(data_dir, config)
% Export simulation parameters to .mat file
    simulation_parameters_file = fullfile(data_dir, 'simulation_parameters.mat');
    
    % Load time step limits from configuration
    if isfield(config.solver_configuration, 'timestep_control') && isfield(config.solver_configuration.timestep_control, 'time_step_limits_days')
        time_step_limits = config.solver_configuration.timestep_control.time_step_limits_days;
    else
        error('Missing time_step_limits_days in solver_config.yaml timestep_control section. REQUIRED: Add time_step_limits_days: [min_days, max_days] to timestep_control section.');
    end
    
    % Simulation Parameters
    tolerance_pressure = config.solver_configuration.tolerance_cnv;
    tolerance_saturation = config.solver_configuration.tolerance_cnv;
    max_iterations = config.solver_configuration.max_iterations;
    
    % Numerical Methods
    linear_solver = 'GMRES';
    preconditioner = 'ILU';
    upwind_method = 'standard';
    time_integration = 'implicit';
    
    save(simulation_parameters_file, 'tolerance_pressure', 'tolerance_saturation', ...
         'max_iterations', 'time_step_limits', 'linear_solver', 'preconditioner', ...
         'upwind_method', 'time_integration', '-v7');
end

function solver_results = create_solver_results(config, model_data, black_oil_model, nonlinear_solver, timestep_control, simulation_schedule, export_path)
% Create comprehensive solver results structure
    solver_results = struct();
    solver_results.config = config;
    solver_results.model_data = model_data;
    solver_results.black_oil_model = black_oil_model;
    solver_results.nonlinear_solver = nonlinear_solver;
    solver_results.timestep_control = timestep_control;
    solver_results.simulation_schedule = simulation_schedule;
    solver_results.export_path = export_path;
    solver_results.timestamp = datetime('now');
    solver_results.status = 'configured';
end

function print_final_summary(solver_results, total_time)
% Print final summary of solver setup
    fprintf('\n');
    fprintf('=== SOLVER CONFIGURATION SUMMARY ===\n');
    fprintf('Total execution time: %.2f seconds\n', total_time);
    fprintf('Grid cells: %d\n', solver_results.model_data.G.cells.num);
    fprintf('Wells configured: %d\n', length(solver_results.model_data.wells));
    fprintf('Timesteps in schedule: %d\n', length(solver_results.simulation_schedule.step.val));
    fprintf('Max iterations: %d\n', solver_results.config.solver_configuration.max_iterations);
    fprintf('CNV tolerance: %.2e\n', solver_results.config.solver_configuration.tolerance_cnv);
    fprintf('Export path: %s\n', solver_results.export_path);
    fprintf('Status: %s\n', solver_results.status);
    fprintf('=====================================\n');
end

function setup_mrst_gravity()
% Setup MRST gravity system to avoid 'gravity function not available' errors
    try
        % Try standard MRST gravity functions first
        if exist('gravity', 'file') == 2
            gravity('reset');
            gravity('on');
            fprintf('MRST gravity enabled via existing gravity() function\n');
            return;
        end
        
        % Use local gravity function from utils/
        script_dir = fileparts(mfilename('fullpath'));
        utils_dir = fullfile(script_dir, 'utils');
        gravity_file = fullfile(utils_dir, 'gravity.m');
        
        if exist(gravity_file, 'file')
            fprintf('Using local gravity function from utils/gravity.m\n');
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