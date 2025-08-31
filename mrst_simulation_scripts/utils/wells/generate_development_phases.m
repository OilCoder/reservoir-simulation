function development_phases = generate_development_phases(wells_config)
% GENERATE_DEVELOPMENT_PHASES - Create development phases from configuration
%
% PURPOSE:
%   Creates 6-phase development plan from wells_config.yaml
%   ELIMINATES hardcoded well names - uses configuration data only
%
% INPUTS:
%   wells_config - Configuration structure from read_yaml_config()
%
% OUTPUTS:
%   development_phases - Array of structures with phase information
%
% POLICY COMPLIANCE:
%   - Data Authority Policy: Zero hardcoded domain values
%   - Canon-First Policy: All data from wells_config.yaml
%   - Fail Fast Policy: Explicit validation of required config sections
%
% Author: Claude Code AI System
% Date: August 31, 2025

    % Validate required configuration sections exist
    if ~isfield(wells_config, 'wells_system')
        error('Missing wells_system section in wells configuration - Canon-First Policy violation');
    end
    
    if ~isfield(wells_config.wells_system, 'development_phases')
        error('Missing development_phases section in wells configuration - Canon-First Policy violation');
    end
    
    phases_config = wells_config.wells_system.development_phases;
    phase_names = fieldnames(phases_config);
    development_phases = [];
    
    % Process each phase from configuration
    for i = 1:length(phase_names)
        phase_name = phase_names{i};
        phase_config = phases_config.(phase_name);
        
        % Create phase structure
        phase = struct();
        phase.phase_number = i;
        phase.phase_name = sprintf('PHASE_%d', i);
        phase.duration_days = phase_config.duration_days;
        phase.start_day = phase_config.start_day;
        phase.end_day = phase_config.end_day;
        
        % Combine active wells from configuration
        active_wells = {};
        if isfield(phase_config, 'active_producers')
            active_wells = [active_wells, phase_config.active_producers];
        end
        if isfield(phase_config, 'active_injectors')
            active_wells = [active_wells, phase_config.active_injectors];
        end
        phase.active_wells = active_wells;
        
        % New wells for this phase
        if isfield(phase_config, 'new_wells')
            phase.new_wells = phase_config.new_wells;
        else
            phase.new_wells = {};
        end
        
        development_phases = [development_phases; phase];
    end
    
    fprintf('Generated %d development phases from configuration\n', length(development_phases));
end