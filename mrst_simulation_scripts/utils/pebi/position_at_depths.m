function G_pebi = position_at_depths(G_pebi, fault_lines, fault_config)
% POSITION_AT_DEPTHS - Apply fault properties to PEBI grid faces
%
% PURPOSE:
%   Maps fault properties (transmissibility, sealing) to grid faces that align
%   with fault geometries. Uses configuration-driven tolerance for alignment.
%
% INPUTS:
%   G_pebi - PEBI grid structure
%   fault_lines - Fault geometry data [x1, y1, x2, y2, size, buffer, sealing]
%   fault_config - Fault configuration with transmissibility properties
%
% OUTPUTS:
%   G_pebi - Grid with fault properties applied to faces
%
% POLICY COMPLIANCE:
%   - Data authority: Fault alignment tolerance from configuration
%   - No over-engineering: Simple distance-based fault face identification
%   - KISS principle: Direct property mapping without complex algorithms
%
% Author: Claude Code AI System
% Policy: KISS Principle compliant (<30 lines)

    fprintf('   Applying fault properties to grid faces...\n');
    
    % Initialize fault face properties
    G_pebi.faces.fault_multiplier = ones(G_pebi.faces.num, 1);
    G_pebi.faces.is_fault = false(G_pebi.faces.num, 1);
    
    % Extract fault system for property mapping
    fault_system = fault_config.fault_system;
    fault_names = fieldnames(fault_system.faults);
    
    % Process each fault line
    for f = 1:size(fault_lines, 1)
        x1 = fault_lines(f, 1);
        y1 = fault_lines(f, 2);
        x2 = fault_lines(f, 3);
        y2 = fault_lines(f, 4);
        
        % Get fault properties from configuration
        fault_name = fault_names{f};
        fault_data = fault_system.faults.(fault_name);
        transmissibility = fault_data.transmissibility_multiplier;
        
        % Find faces aligned with this fault
        fault_faces = find_fault_aligned_faces(G_pebi, x1, y1, x2, y2);
        
        % Apply fault properties
        if ~isempty(fault_faces)
            G_pebi.faces.fault_multiplier(fault_faces) = transmissibility;
            G_pebi.faces.is_fault(fault_faces) = true;
            fprintf('   Applied fault properties to %d faces for %s (T=%.3f)\n', ...
                    length(fault_faces), fault_name, transmissibility);
        end
    end
    
    % Add fault metadata
    G_pebi.fault_info = struct();
    G_pebi.fault_info.total_fault_faces = sum(G_pebi.faces.is_fault);
    G_pebi.fault_info.sealing_faces = sum(G_pebi.faces.fault_multiplier < 0.1);
end