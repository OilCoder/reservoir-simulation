function development_phases = development_phases_setup(config)
% DEVELOPMENT_PHASES_SETUP - Define development phases from configuration
%
% INPUTS:
%   config - Configuration structure with wells_system section
%
% OUTPUTS:
%   development_phases - Structure defining development phases
%
% Author: Claude Code AI System
% Date: August 23, 2025

    if ~isfield(config, 'wells_system')
        error('Missing wells_system in configuration. REQUIRED: Add wells_system section to wells_config.yaml');
    end
    
    wells_system = config.wells_system;
    
    % Load development duration
    if ~isfield(wells_system, 'development_duration_days')
        error(['Missing development_duration_days in wells_system configuration.\n' ...
               'REQUIRED: Add development_duration_days to wells_system section in wells_config.yaml']);
    end
    
    total_duration = wells_system.development_duration_days;
    
    % Create 6-phase development schedule
    development_phases = struct();
    
    % Phase definitions based on Eagle West Field development plan
    phase_duration = total_duration / 6;  % Equal phases for simplicity
    
    for phase_num = 1:6
        phase_name = sprintf('phase_%d', phase_num);
        
        development_phases.(phase_name) = struct();
        development_phases.(phase_name).phase_number = phase_num;
        development_phases.(phase_name).start_day = (phase_num - 1) * phase_duration + 1;
        development_phases.(phase_name).end_day = phase_num * phase_duration;
        development_phases.(phase_name).duration_days = phase_duration;
        
        % Define wells activated in each phase
        development_phases.(phase_name).active_producers = get_active_wells('producer', phase_num, wells_system);
        development_phases.(phase_name).active_injectors = get_active_wells('injector', phase_num, wells_system);
        
        % Phase description
        development_phases.(phase_name).description = sprintf('Development Phase %d: Days %.0f-%.0f', ...
            phase_num, development_phases.(phase_name).start_day, development_phases.(phase_name).end_day);
    end
    
    fprintf('Development phases configured: 6 phases over %.1f years\n', total_duration / 365.25);
end

function active_wells = get_active_wells(well_type, phase_num, wells_system)
% Get active wells for a specific phase and type
    active_wells = {};
    
    % Default well activation schedule (can be made configurable)
    switch well_type
        case 'producer'
            % Activate 2 producers per phase, up to 10 total
            max_wells = min(phase_num * 2, 10);
            for i = 1:max_wells
                active_wells{end+1} = sprintf('EW-%03d', i);
            end
            
        case 'injector'
            % Activate 1 injector per phase, up to 5 total
            max_wells = min(phase_num, 5);
            for i = 1:max_wells
                active_wells{end+1} = sprintf('IW-%03d', i);
            end
    end
end