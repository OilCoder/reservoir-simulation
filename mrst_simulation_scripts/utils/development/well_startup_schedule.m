function well_startup_schedule = well_startup_schedule(development_phases, config)
% WELL_STARTUP_SCHEDULE - Create well startup schedule from development phases
%
% INPUTS:
%   development_phases - Development phases structure
%   config - Configuration structure
%
% OUTPUTS:
%   well_startup_schedule - Detailed well startup schedule
%
% Author: Claude Code AI System
% Date: August 23, 2025

    well_startup_schedule = struct();
    well_startup_schedule.producers = {};
    well_startup_schedule.injectors = {};
    well_startup_schedule.timeline = [];
    
    phase_names = fieldnames(development_phases);
    
    for i = 1:length(phase_names)
        phase_name = phase_names{i};
        phase = development_phases.(phase_name);
        
        % Process producers for this phase
        for j = 1:length(phase.active_producers)
            well_name = phase.active_producers{j};
            
            % Check if well is already in schedule
            existing_idx = find_well_in_schedule(well_startup_schedule.producers, well_name);
            
            if isempty(existing_idx)
                % Add new producer
                well_entry = struct();
                well_entry.well_name = well_name;
                well_entry.startup_day = phase.start_day;
                well_entry.phase_activated = phase.phase_number;
                well_entry.well_type = 'producer';
                
                well_startup_schedule.producers{end+1} = well_entry;
            end
        end
        
        % Process injectors for this phase
        for j = 1:length(phase.active_injectors)
            well_name = phase.active_injectors{j};
            
            % Check if well is already in schedule
            existing_idx = find_well_in_schedule(well_startup_schedule.injectors, well_name);
            
            if isempty(existing_idx)
                % Add new injector
                well_entry = struct();
                well_entry.well_name = well_name;
                well_entry.startup_day = phase.start_day;
                well_entry.phase_activated = phase.phase_number;
                well_entry.well_type = 'injector';
                
                well_startup_schedule.injectors{end+1} = well_entry;
            end
        end
        
        % Add phase milestone to timeline
        milestone = struct();
        milestone.day = phase.start_day;
        milestone.phase = phase.phase_number;
        milestone.event_type = 'phase_start';
        milestone.description = sprintf('Phase %d startup', phase.phase_number);
        milestone.wells_activated = [phase.active_producers, phase.active_injectors];
        
        well_startup_schedule.timeline(end+1) = milestone;
    end
    
    % Sort timeline by day
    if ~isempty(well_startup_schedule.timeline)
        [~, sort_idx] = sort([well_startup_schedule.timeline.day]);
        well_startup_schedule.timeline = well_startup_schedule.timeline(sort_idx);
    end
    
    fprintf('Well startup schedule created: %d producers, %d injectors\n', ...
        length(well_startup_schedule.producers), length(well_startup_schedule.injectors));
end

function existing_idx = find_well_in_schedule(well_list, well_name)
% Find if well already exists in schedule
    existing_idx = [];
    
    for i = 1:length(well_list)
        if strcmp(well_list{i}.well_name, well_name)
            existing_idx = i;
            break;
        end
    end
end