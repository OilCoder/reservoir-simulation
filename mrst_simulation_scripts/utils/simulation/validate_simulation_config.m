function sim_params = validate_simulation_config(solver_config)
% VALIDATE_SIMULATION_CONFIG - Extract simulation parameters from config
%
% Implements FAIL_FAST policy - no hard-coded simulation parameters
%
% INPUT:
%   solver_config - Solver configuration structure
% OUTPUT:
%   sim_params - Structure with validated simulation parameters

% ----------------------------------------
% Step 1 – Validate Configuration Structure
% ----------------------------------------
if ~isstruct(solver_config) || ~isfield(solver_config, 'solver_setup')
    error('Invalid solver config. Provide valid solver_config.yaml');
end

config = solver_config.solver_setup;

% ----------------------------------------
% Step 2 – Validate Simulation Schedule
% ----------------------------------------
if ~isfield(config, 'simulation_schedule')
    error('Missing simulation_schedule section in solver_config.yaml');
end

schedule = config.simulation_schedule;
if ~isfield(schedule, 'total_duration_days')
    error('Missing total_duration_days in simulation_schedule');
end

% ----------------------------------------
% Step 3 – Validate Timestep Control  
% ----------------------------------------
if ~isfield(config, 'timestep_control')
    error('Missing timestep_control section in solver_config.yaml');
end

timestep_ctrl = config.timestep_control;
required_timestep_fields = {'initial_timestep_days', 'max_timestep_days'};
for i = 1:length(required_timestep_fields)
    field = required_timestep_fields{i};
    if ~isfield(timestep_ctrl, field)
        error('Missing %s in timestep_control section', field);
    end
end

% ----------------------------------------
% Step 4 – Validate Progress Monitoring
% ----------------------------------------
if ~isfield(config, 'progress_monitoring')
    error('Missing progress_monitoring section in solver_config.yaml');
end

progress = config.progress_monitoring;
required_progress_fields = {'checkpoint_frequency_steps', 'progress_report_frequency_steps'};
for i = 1:length(required_progress_fields)
    field = required_progress_fields{i};
    if ~isfield(progress, field)
        error('Missing %s in progress_monitoring section', field);
    end
end

% ----------------------------------------
% Step 5 – Extract Validated Parameters
% ----------------------------------------
sim_params = struct();
sim_params.total_duration_days = schedule.total_duration_days;
sim_params.initial_timestep_days = timestep_ctrl.initial_timestep_days;
sim_params.max_timestep_days = timestep_ctrl.max_timestep_days;
sim_params.checkpoint_frequency = progress.checkpoint_frequency_steps;
sim_params.report_frequency = progress.progress_report_frequency_steps;

% Calculate total timesteps (approximate)
if isfield(schedule, 'estimated_total_timesteps')
    sim_params.estimated_timesteps = schedule.estimated_total_timesteps;
else
    % Calculate based on average timestep size
    avg_timestep = (timestep_ctrl.initial_timestep_days + timestep_ctrl.max_timestep_days) / 2;
    sim_params.estimated_timesteps = ceil(sim_params.total_duration_days / avg_timestep);
end

end