% main.m
% Complete workflow orchestrator for MRST geomechanical simulation
%
% Calls all functions in correct order for reproducible simulation execution.
% Requires: MRST

function s99_run_workflow()
% s99_run_workflow - Complete MRST geomechanical simulation workflow
%
% Orchestrates the complete simulation workflow including MRST initialization,
% component setup, simulation execution, and data export.
%
% Args:
%   None
%
% Returns:
%   None (executes complete workflow)
%
% Requires: MRST

%% ----
%% Step 1 – Initialize and setup
%% ----

% Substep 1.1 – Clear workspace and initialize ________________
clear all; close all; clc;

fprintf('=== MRST Geomechanical Simulation - Phase 1 ===\n');
fprintf('Starting complete workflow at %s\n', datestr(now));

% Substep 1.2 – Initialize MRST properly for Octave ___________
s00_initialize_mrst();

% Substep 1.3 – Set random seed for reproducibility ___________
rand('seed', 42);
randn('seed', 42);
fprintf('[INFO] Random seed set to 42 for reproducibility\n');

% Substep 1.4 – Ensure we're in the correct directory _________
mrst_sim_dir = fullfile(fileparts(pwd), 'MRST_simulation_scripts');
if exist(mrst_sim_dir, 'dir') && ~strcmp(pwd, mrst_sim_dir)
    cd(mrst_sim_dir);
    fprintf('[INFO] Changed to MRST_simulation_scripts directory\n');
end

% Substep 1.5 – Create required directories ___________________
fprintf('[INFO] Setting up directory structure...\n');
util_ensure_directories();

%% ----
%% Step 2 – Setup simulation components
%% ----

config_file = '../config/reservoir_config.yaml';
[G, rock, fluid, schedule, timing] = s07a_setup_components(config_file);

%% ----
%% Step 3 – Run simulation and export
%% ----

[states, wellSols, simulation_time, export_time] = s08_run_workflow_steps(G, rock, fluid, schedule);

% Update timing structure
timing.simulation_time = simulation_time;
timing.export_time = export_time;

%% ----
%% Step 4 – Final validation
%% ----

fprintf('\n--- Step 8: Final Validation ---\n');

% Check all required variables exist
required_vars = {'G', 'rock', 'fluid', 'schedule', 'states', 'wellSols'};
all_vars_exist = validate_workflow_results(required_vars);

%% ----
%% Step 5 – Generate completion report
%% ----

s13_generate_completion_report(G, rock, states, schedule, timing, all_vars_exist);

end

function all_vars_exist = validate_workflow_results(required_vars)
% validate_workflow_results - Validate that all required outputs exist
%
% Checks that all required variables and data files were created
% successfully during the workflow execution.
%
% Args:
%   required_vars: Cell array of required variable names
%
% Returns:
%   all_vars_exist: Boolean indicating if all validation passed
%
% Requires: None

all_vars_exist = true;

for i = 1:length(required_vars)
    var_name = required_vars{i};
    if ~exist(var_name, 'var')
        fprintf('[ERROR] Required variable %s not found\n', var_name);
        all_vars_exist = false;
    end
end

% Check optimized data directory structure exists
data_dir = '../data';
if ~exist(data_dir, 'dir')
    fprintf('[ERROR] Data directory not created\n');
    all_vars_exist = false;
else
    % Check for optimized data structure files
    required_files = {
        'initial/initial_conditions.mat',
        'static/static_data.mat', 
        'temporal/time_data.mat',
        'dynamic/fields/field_arrays.mat',
        'dynamic/wells/well_data.mat',
        'metadata/metadata.mat'
    };
    
    missing_files = 0;
    for i = 1:length(required_files)
        file_path = fullfile(data_dir, required_files{i});
        if ~exist(file_path, 'file')
            fprintf('[ERROR] Required file missing: %s\n', required_files{i});
            missing_files = missing_files + 1;
        end
    end
    
    if missing_files == 0
        fprintf('[INFO] All optimized data files created successfully\n');
    else
        fprintf('[ERROR] %d required data files missing\n', missing_files);
        all_vars_exist = false;
    end
end

end
