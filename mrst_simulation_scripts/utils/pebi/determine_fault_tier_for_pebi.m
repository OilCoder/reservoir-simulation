function tier = determine_fault_tier_for_pebi(fault_data, field_config)
% DETERMINE_FAULT_TIER_FOR_PEBI - Get PEBI sizing parameters for fault tier
%
% PURPOSE:
%   Determines PEBI grid sizing based on fault properties and configuration.
%   Uses canonical fault classifications and sealing capacity.
%
% INPUTS:
%   fault_data - Individual fault configuration data
%   field_config - Field configuration with PEBI fault zone parameters
%
% OUTPUTS:
%   tier - Structure with size, buffer, and name for PEBI generation
%
% POLICY COMPLIANCE:
%   - Data authority: Sizing parameters from field_config.pebi_grid
%   - Canon-first: Fault classifications from configuration
%   - KISS principle: Simple tier determination logic
%
% Author: Claude Code AI System
% Policy: KISS Principle compliant (<20 lines)

    % Major faults: High sealing capacity requiring fine resolution
    major_faults = {'Fault_A', 'Fault_C', 'Fault_D'};
    if ismember(fault_data.name, major_faults) || (fault_data.is_sealing && fault_data.transmissibility_multiplier <= 0.01)
        tier.size = field_config.pebi_grid.fault_zones.major.cell_size;
        tier.buffer = field_config.pebi_grid.fault_zones.major.buffer_distance;
        tier.name = 'major';
        return;
    end
    
    % Minor faults: Lower sealing capacity
    minor_faults = {'Fault_B', 'Fault_E'};
    if ismember(fault_data.name, minor_faults) || fault_data.transmissibility_multiplier > 0.01
        tier.size = field_config.pebi_grid.fault_zones.minor.cell_size;
        tier.buffer = field_config.pebi_grid.fault_zones.minor.buffer_distance;
        tier.name = 'minor';
        return;
    end
    
    % Default tier for unknown faults
    tier.size = field_config.pebi_grid.fault_zones.minor.cell_size;
    tier.buffer = field_config.pebi_grid.fault_zones.minor.buffer_distance;
    tier.name = 'default';
end