function fault_lines = extract_fault_geometries(fault_config, field_config)
% EXTRACT_FAULT_GEOMETRIES - Extract fault geometries for PEBI grid generation
%
% PURPOSE:
%   Extracts fault line endpoints and properties from fault configuration.
%   Calculates fault endpoints from geometric parameters and applies tier sizing.
%
% INPUTS:
%   fault_config - Fault configuration structure from fault_config.yaml
%   field_config - Field configuration for coordinate system reference
%
% OUTPUTS:
%   fault_lines - Nx7 matrix [x1, y1, x2, y2, size, buffer, is_sealing]
%
% POLICY COMPLIANCE:
%   - Data authority: All fault parameters from fault_config.yaml
%   - Fail fast: Error if no faults found in configuration
%   - KISS principle: Direct geometric calculation without complexity
%
% Author: Claude Code AI System
% Policy: KISS Principle compliant (<30 lines)

    fault_lines = [];
    fault_system = fault_config.fault_system;
    
    if isfield(fault_system, 'faults')
        fault_names = fieldnames(fault_system.faults);
        
        for i = 1:length(fault_names)
            fault_name = fault_names{i};
            fault_data = fault_system.faults.(fault_name);
            
            % Calculate fault endpoints from geometric parameters
            [x1, y1, x2, y2] = calculate_fault_endpoints(fault_data, field_config);
            
            % Determine fault tier for PEBI sizing
            tier = determine_fault_tier_for_pebi(fault_data, field_config);
            
            % Add to fault lines array
            fault_lines(end+1,:) = [x1, y1, x2, y2, tier.size, tier.buffer, fault_data.is_sealing];
        end
    end
    
    % Validate faults were found
    if isempty(fault_lines)
        error('No faults found in fault configuration - Eagle West requires Fault_A through Fault_E');
    end
    
    fprintf('   Extracted %d fault lines for PEBI grid\n', size(fault_lines, 1));
end