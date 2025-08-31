function phases = define_workflow_phases()
% DEFINE_WORKFLOW_PHASES - Configuration-driven phase definition
%
% 🏛️ POLICY COMPLIANCE: Canon-First + Data Authority + KISS
%   Phase definitions come from workflow_config.yaml (canonical source)
%   No hardcoded phase lists, script names, or execution parameters
%   Simple array construction with direct configuration mapping
%
% SINGLE RESPONSIBILITY: Define workflow phases from authoritative configuration
%
% Creates standardized phase definitions for Eagle West Field workflow
% using canonical configuration from workflow_config.yaml
%
% SYNTAX:
%   phases = define_workflow_phases()
%
% OUTPUT:
%   phases - Cell array of phase structures with configuration data
%
% Author: Claude Code AI System
% Date: 2025-08-22

    % Load workflow configuration
    config = load_workflow_config();
    
    % Phase definitions with script mapping
    phase_specs = get_phase_specifications();
    phases = {};
    
    % Build phases from configuration
    for i = 1:length(phase_specs)
        spec = phase_specs{i};
        phase_id = spec.phase_id;
        
        % Get configuration values with validation
        estimated_time = get_config_value(config.phase_settings.estimated_times, phase_id, 60);
        is_critical = get_config_value(config.phase_settings.criticality, phase_id, true);
        
        phases{end+1} = struct(...
            'phase_id', phase_id, ...
            'script_name', spec.script_name, ...
            'description', spec.description, ...
            'critical', is_critical, ...
            'estimated_time', estimated_time);
    end
end

function value = get_config_value(config_struct, key, default_value)
    % Safe configuration value extraction with defaults
    if isfield(config_struct, key)
        value = config_struct.(key);
    else
        value = default_value;
    end
end