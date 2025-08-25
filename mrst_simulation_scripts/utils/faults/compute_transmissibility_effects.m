function trans_multipliers = compute_transmissibility_effects(G, fault_intersections, fault_geometries)
% COMPUTE_TRANSMISSIBILITY_EFFECTS - Calculate fault transmissibility multipliers
%
% POLICY COMPLIANCE:
%   - Data authority: Uses transmissibility values from YAML config
%   - KISS principle: Direct face identification using MRST connectivity
%
% Author: Claude Code (Policy-compliant refactor)
% Date: 2025-08-22

    % Initialize and apply multipliers for each fault
    trans_multipliers = ones(G.faces.num, 1);
    
    for f = 1:length(fault_intersections)
        trans_multipliers = apply_fault_transmissibility(G, trans_multipliers, ...
            fault_intersections{f}, fault_geometries(f));
    end

end

function trans_mult = apply_fault_transmissibility(G, trans_mult, fault_data, fault_geometry)
% Apply transmissibility multipliers for single fault
    
    affected_cells = fault_data.affected_cells;
    
    if isempty(affected_cells)
        return;
    end
    
    % Find faces crossing fault boundaries
    fault_faces = identify_fault_crossing_faces(G, affected_cells);
    
    % Apply transmissibility multiplier from YAML config
    trans_mult(fault_faces) = min(trans_mult(fault_faces), fault_geometry.trans_mult);

end

function fault_faces = identify_fault_crossing_faces(G, affected_cells)
% Identify faces that cross fault boundaries using MRST connectivity
    
    fault_faces = [];
    
    for i = 1:length(affected_cells)
        cell_id = affected_cells(i);
        
        % Get faces for this cell using MRST connectivity
        face_indices = G.cells.facePos(cell_id):G.cells.facePos(cell_id+1)-1;
        cell_faces = G.cells.faces(face_indices, 1);
        
        % Check each face for fault crossing
        for j = 1:length(cell_faces)
            face_id = cell_faces(j);
            
            if is_boundary_crossing_face(G, face_id, affected_cells)
                fault_faces = [fault_faces; face_id];
            end
        end
    end
    
    % Remove duplicates
    fault_faces = unique(fault_faces);

end

function crosses = is_boundary_crossing_face(G, face_id, affected_cells)
% Check if face crosses fault boundary using neighbor analysis
    
    neighbors = G.faces.neighbors(face_id, :);
    neighbor1 = neighbors(1);
    neighbor2 = neighbors(2);
    
    % Skip boundary faces (have zero neighbor)
    if neighbor1 == 0 || neighbor2 == 0
        crosses = false;
        return;
    end
    
    % Face crosses fault if one neighbor is affected, other is not
    in_zone_1 = ismember(neighbor1, affected_cells);
    in_zone_2 = ismember(neighbor2, affected_cells);
    crosses = (in_zone_1 && ~in_zone_2) || (~in_zone_1 && in_zone_2);

end