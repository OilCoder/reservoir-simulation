function simulation_schedule = simulation_schedule_setup(model_data, config)
% SIMULATION_SCHEDULE_SETUP - Setup simulation schedule for Eagle West Field
%
% INPUTS:
%   model_data - Model data structure with wells, fluid, etc.
%   config - Configuration structure
%
% OUTPUTS:
%   simulation_schedule - MRST simulation schedule structure
%
% Author: Claude Code AI System
% Date: August 23, 2025

    % Load wells data
    if ~isfield(model_data, 'wells')
        error('Missing wells data in model_data. REQUIRED: Wells must be defined before creating simulation schedule.');
    end
    
    W = model_data.wells;
    
    % Load simulation schedule configuration
    if ~isfield(config.solver_configuration, 'simulation_schedule')
        error('Missing simulation_schedule section in solver_configuration. REQUIRED: Add simulation_schedule section to solver_config.yaml');
    end
    
    schedule_config = config.solver_configuration.simulation_schedule;
    total_duration = get_config_value(schedule_config, 'total_duration_days', 3650) * day();
    
    % Create timestep schedule
    timesteps = create_timestep_schedule(schedule_config);
    
    % Determine production controls schedule
    control_schedule = create_control_schedule(schedule_config);
    
    % Build MRST schedule structure
    simulation_schedule = struct();
    simulation_schedule.step.val = timesteps;
    simulation_schedule.step.control = ones(length(timesteps), 1);
    
    % Setup well controls for each control period
    simulation_schedule.control = setup_well_controls(W, control_schedule);
    
    fprintf('Simulation schedule created: %d timesteps over %.1f years\n', ...
        length(timesteps), total_duration / (365 * day()));
end

function timesteps = create_timestep_schedule(schedule_config)
% Create timestep schedule based on configuration
    total_time = 0;
    timesteps = [];
    
    % History period with monthly timesteps
    if isfield(schedule_config, 'history_period')
        history = schedule_config.history_period;
        hist_duration = get_config_value(history, 'duration_days', 1095) * day();
        hist_timestep = get_config_value(history, 'timestep_days', 30) * day();
        
        hist_steps = round(hist_duration / hist_timestep);
        timesteps = [timesteps; repmat(hist_timestep, hist_steps, 1)];
        total_time = total_time + hist_steps * hist_timestep;
    end
    
    % Forecast period with variable timesteps
    if isfield(schedule_config, 'forecast_period')
        forecast = schedule_config.forecast_period;
        
        % First forecast period
        if isfield(forecast, 'period_1_days')
            p1_duration = forecast.period_1_days * day();
            p1_timestep = get_config_value(forecast, 'period_1_timestep', 90) * day();
            p1_steps = round(p1_duration / p1_timestep);
            timesteps = [timesteps; repmat(p1_timestep, p1_steps, 1)];
            total_time = total_time + p1_steps * p1_timestep;
        end
        
        % Second forecast period
        if isfield(forecast, 'period_2_days')
            p2_duration = forecast.period_2_days * day();
            p2_timestep = get_config_value(forecast, 'period_2_timestep', 180) * day();
            p2_steps = round(p2_duration / p2_timestep);
            timesteps = [timesteps; repmat(p2_timestep, p2_steps, 1)];
        end
    end
    
    if isempty(timesteps)
        % Fallback: create uniform timesteps
        total_duration = get_config_value(schedule_config, 'total_duration_days', 3650) * day();
        default_timestep = 30 * day();
        n_steps = round(total_duration / default_timestep);
        timesteps = repmat(default_timestep, n_steps, 1);
    end
end

function control_schedule = create_control_schedule(schedule_config)
% Create control schedule for well operations
    control_schedule = struct();
    control_schedule.times = [];
    control_schedule.controls = [];
    
    % Default single control period
    total_duration = get_config_value(schedule_config, 'total_duration_days', 3650) * day();
    control_schedule.times = [0, total_duration];
    control_schedule.controls = [1, 1];
end

function controls = setup_well_controls(W, control_schedule)
% Setup well controls for simulation schedule
    n_controls = length(control_schedule.controls);
    controls = cell(n_controls, 1);
    
    for i = 1:n_controls
        controls{i}.W = W; % Use wells as configured
    end
end

function value = get_config_value(config, field, default_value)
% Get configuration value with fallback to default
    if isfield(config, field)
        value = config.(field);
    else
        value = default_value;
    end
end