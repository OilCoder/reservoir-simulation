function mrst_schedule = mrst_schedule_generator(schedule_results, control_data)
% MRST_SCHEDULE_GENERATOR - Generate MRST-compatible schedule from development data
%
% INPUTS:
%   schedule_results - Complete schedule results structure
%   control_data - Production control data
%
% OUTPUTS:
%   mrst_schedule - MRST-compatible schedule structure
%
% Author: Claude Code AI System  
% Date: August 23, 2025

    mrst_schedule = struct();
    mrst_schedule.step = struct();
    mrst_schedule.control = [];
    
    % Generate timesteps based on development phases
    timesteps = generate_timesteps(schedule_results);
    mrst_schedule.step.val = timesteps;
    
    % Generate control assignments for each timestep
    control_assignments = generate_control_assignments(schedule_results, length(timesteps));
    mrst_schedule.step.control = control_assignments;
    
    % Generate well controls for each phase
    mrst_schedule.control = generate_well_controls(schedule_results, control_data);
    
    fprintf('MRST schedule generated: %d timesteps, %d control periods\n', ...
        length(timesteps), length(mrst_schedule.control));
end

function timesteps = generate_timesteps(schedule_results)
% Generate timesteps based on development schedule
    total_duration = schedule_results.total_duration_days;
    
    % Use monthly timesteps for first year, quarterly afterwards
    timesteps = [];
    
    % Monthly timesteps for first year
    monthly_steps = 12;
    monthly_duration = 365.25 / monthly_steps; % ~30.4 days
    
    for i = 1:monthly_steps
        timesteps(end+1) = monthly_duration;
    end
    
    % Quarterly timesteps for remaining years
    remaining_duration = total_duration - 365.25;
    quarterly_duration = 365.25 / 4; % ~91.3 days
    quarterly_steps = ceil(remaining_duration / quarterly_duration);
    
    for i = 1:quarterly_steps
        timesteps(end+1) = quarterly_duration;
    end
    
    % Convert to column vector and apply day() units if available
    timesteps = timesteps(:);
    
    % Apply MRST time units if day() function is available
    if exist('day', 'file') == 2
        timesteps = timesteps * day();
    end
end

function control_assignments = generate_control_assignments(schedule_results, n_timesteps)
% Generate control period assignments for each timestep
    control_assignments = ones(n_timesteps, 1);
    
    % Assign different control periods based on development phases
    if isfield(schedule_results, 'development_phases')
        phase_names = fieldnames(schedule_results.development_phases);
        n_phases = length(phase_names);
        
        % Simple assignment: distribute timesteps evenly across phases
        timesteps_per_phase = floor(n_timesteps / n_phases);
        
        for phase_idx = 1:n_phases
            start_step = (phase_idx - 1) * timesteps_per_phase + 1;
            end_step = min(phase_idx * timesteps_per_phase, n_timesteps);
            
            control_assignments(start_step:end_step) = phase_idx;
        end
    end
end

function well_controls = generate_well_controls(schedule_results, control_data)
% Generate well control structures for each control period
    if ~isfield(schedule_results, 'development_phases')
        error('Missing development_phases in schedule_results');
    end
    
    phase_names = fieldnames(schedule_results.development_phases);
    n_phases = length(phase_names);
    well_controls = cell(n_phases, 1);
    
    for phase_idx = 1:n_phases
        phase_name = phase_names{phase_idx};
        phase = schedule_results.development_phases.(phase_name);
        
        % Create control structure for this phase
        control = struct();
        control.W = create_phase_wells(phase, control_data);
        
        well_controls{phase_idx} = control;
    end
end

function W = create_phase_wells(phase, control_data)
% Create well structures for a specific development phase
    W = [];
    
    % This would normally create MRST well structures
    % For now, create placeholder structure
    all_wells = [phase.active_producers, phase.active_injectors];
    
    for i = 1:length(all_wells)
        well_name = all_wells{i};
        
        well_struct = struct();
        well_struct.name = well_name;
        well_struct.type = determine_well_type(well_name);
        well_struct.val = get_well_control_value(well_name, control_data);
        
        if isempty(W)
            W = well_struct;
        else
            W(end+1) = well_struct;
        end
    end
end

function well_type = determine_well_type(well_name)
% Determine well type from name
    if startsWith(well_name, 'EW-')
        well_type = 'rate'; % Producer
    elseif startsWith(well_name, 'IW-')
        well_type = 'rate'; % Injector
    else
        well_type = 'rate'; % Default
    end
end

function control_value = get_well_control_value(well_name, control_data)
% Get control value for well from control data
    % Default control values (should come from configuration)
    if startsWith(well_name, 'EW-')
        control_value = 1000; % 1000 STB/day production rate
    elseif startsWith(well_name, 'IW-')
        control_value = 2000; % 2000 STB/day injection rate
    else
        control_value = 500;  % Default rate
    end
end