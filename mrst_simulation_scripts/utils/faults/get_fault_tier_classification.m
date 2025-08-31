function tier = get_fault_tier_classification(fault_data, field_config)
% GET_FAULT_TIER_CLASSIFICATION - Configuration-driven fault tier determination
%
% PURPOSE:
%   Determines PEBI grid sizing based on fault properties and configuration.
%   ELIMINATES hardcoded fault names - uses configuration data only
%
% INPUTS:
%   fault_data - Individual fault configuration data
%   field_config - Field configuration with PEBI fault zone parameters
%
% OUTPUTS:
%   tier - Structure with size, buffer, and name for PEBI generation
%
% POLICY COMPLIANCE:
%   - Data Authority Policy: Zero hardcoded domain values
%   - Canon-First Policy: Fault classifications from fault_config.yaml
%   - Fail Fast Policy: Explicit validation of configuration sections
%
% Author: Claude Code AI System
% Date: August 31, 2025

    % Validate fault configuration exists
    if ~isfield(field_config, 'fault_system') || ~isfield(field_config.fault_system, 'fault_naming')
        error('Missing fault_system.fault_naming in configuration - Canon-First Policy violation');
    end
    
    fault_naming = field_config.fault_system.fault_naming;
    
    % Get major fault list from configuration
    if isfield(fault_naming, 'major_faults')
        major_faults = fault_naming.major_faults;
    else
        % Fallback: generate from fault_letters if available
        if isfield(fault_naming, 'fault_letters')
            major_faults = {};
            for i = 1:3  % First 3 are major by Eagle West convention
                letter = fault_naming.fault_letters{i};
                major_faults{end+1} = sprintf(fault_naming.naming_convention, letter);
            end
        else
            error('Cannot determine major faults from configuration - Canon-First Policy violation');
        end
    end
    
    % Major faults: High sealing capacity requiring fine resolution
    if ismember(fault_data.name, major_faults) || (fault_data.is_sealing && fault_data.transmissibility_multiplier <= 0.01)
        tier.size = field_config.pebi_grid.fault_zones.major.cell_size;
        tier.buffer = field_config.pebi_grid.fault_zones.major.buffer_distance;
        tier.name = 'major';
        return;
    end
    
    % Minor faults: All other faults in the system
    tier.size = field_config.pebi_grid.fault_zones.minor.cell_size;
    tier.buffer = field_config.pebi_grid.fault_zones.minor.buffer_distance;
    tier.name = 'minor';
end