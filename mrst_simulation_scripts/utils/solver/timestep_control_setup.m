function timestep_control = timestep_control_setup(config)
% TIMESTEP_CONTROL_SETUP - Configure timestep control for MRST simulation
%
% INPUTS:
%   config - Configuration structure with solver_configuration section
%
% OUTPUTS:
%   timestep_control - Configured timestep control structure
%
% Author: Claude Code AI System
% Date: August 23, 2025

    solver_config = config.solver_configuration;
    
    if ~isfield(solver_config, 'timestep_control')
        error('Missing timestep_control section in solver_configuration. REQUIRED: Add timestep_control section to solver_config.yaml');
    end
    
    tc_config = solver_config.timestep_control;
    
    % Initialize timestep control structure
    timestep_control = struct();
    
    % Load timestep parameters from configuration
    timestep_control.initial_timestep = get_config_value(tc_config, 'initial_timestep_days', 1) * day();
    timestep_control.min_timestep = get_config_value(tc_config, 'min_timestep_days', 0.1) * day();
    timestep_control.max_timestep = get_config_value(tc_config, 'max_timestep_days', 365) * day();
    timestep_control.growth_factor = get_config_value(tc_config, 'timestep_growth_factor', 1.25);
    timestep_control.cut_factor = get_config_value(tc_config, 'timestep_cut_factor', 0.5);
    timestep_control.max_cuts = get_config_value(tc_config, 'max_timestep_cuts', 8);
    timestep_control.adaptive_control = get_config_value(tc_config, 'adaptive_control', true);
    
    % Load cutting criteria if available
    if isfield(tc_config, 'cut_criteria')
        cut_criteria = tc_config.cut_criteria;
        timestep_control.max_saturation_change = get_config_value(cut_criteria, 'max_saturation_change', 0.2);
        timestep_control.max_pressure_change = get_config_value(cut_criteria, 'max_pressure_change_pa', 5e6);
        timestep_control.cut_on_convergence_failure = get_config_value(cut_criteria, 'convergence_failure', true);
    end
    
    fprintf('Timestep control configured: %.1f to %.1f days with %.2fx growth factor\n', ...
        timestep_control.min_timestep / day(), ...
        timestep_control.max_timestep / day(), ...
        timestep_control.growth_factor);
end

function value = get_config_value(config, field, default_value)
% Get configuration value with fallback to default
    if isfield(config, field)
        value = config.(field);
    else
        value = default_value;
    end
end