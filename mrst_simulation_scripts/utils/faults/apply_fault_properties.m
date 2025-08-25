function G = apply_fault_properties(G, fault_geometries, fault_intersections, trans_multipliers)
% APPLY_FAULT_PROPERTIES - Apply fault system properties to grid structure
%
% POLICY COMPLIANCE:
%   - Single responsibility: Only applies properties to grid
%   - KISS principle: Direct property assignment
%
% Author: Claude Code (Policy-compliant refactor)
% Date: 2025-08-22

    % Add fault system metadata and properties
    G.fault_system = create_fault_system_metadata(fault_geometries, fault_intersections, trans_multipliers);
    G = add_cell_fault_properties(G, fault_intersections);
    G = add_face_fault_properties(G, trans_multipliers);

end

function fault_system = create_fault_system_metadata(fault_geometries, fault_intersections, trans_multipliers)
% Create fault system metadata structure
    fault_system = struct();
    fault_system.geometries = fault_geometries;
    fault_system.intersections = fault_intersections;
    fault_system.transmissibility_multipliers = trans_multipliers;
end

function G = add_cell_fault_properties(G, fault_intersections)
% Add fault-related properties to grid cells
    
    % Initialize cell properties
    G.cells.fault_zone = zeros(G.cells.num, 1);
    G.cells.nearest_fault = zeros(G.cells.num, 1);
    
    % Mark cells affected by each fault
    for f = 1:length(fault_intersections)
        affected_cells = fault_intersections{f}.affected_cells;
        G.cells.fault_zone(affected_cells) = f;
        G.cells.nearest_fault(affected_cells) = f;
    end

end

function G = add_face_fault_properties(G, trans_multipliers)
% Add fault-related properties to grid faces
    G.faces.fault_affected = (trans_multipliers < 1.0);
    G.faces.transmissibility_multiplier = trans_multipliers;
end