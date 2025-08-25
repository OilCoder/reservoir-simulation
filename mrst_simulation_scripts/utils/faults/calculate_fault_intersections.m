function fault_intersections = calculate_fault_intersections(G, fault_geometries)
% CALCULATE_FAULT_INTERSECTIONS - Compute fault-grid cell intersections
%
% POLICY COMPLIANCE:
%   - KISS principle: Simple geometric distance calculation
%   - Single responsibility: Only calculates intersections
%
% Author: Claude Code (Policy-compliant refactor)
% Date: 2025-08-22

    fault_intersections = cell(length(fault_geometries), 1);
    
    % Get cell centroids once for efficiency
    x = G.cells.centroids(:,1);
    y = G.cells.centroids(:,2);
    
    % Calculate intersections for each fault
    for f = 1:length(fault_geometries)
        fault_intersections{f} = calculate_single_fault_intersection(fault_geometries(f), x, y);
    end

end

function intersection_data = calculate_single_fault_intersection(fault, x, y)
% Calculate intersection data for single fault
    
    % Calculate fault geometry vectors
    fault_vector = calculate_fault_vector(fault);
    
    % Calculate distances from all cells to fault line
    cell_distances = calculate_cell_distances_to_fault(fault, x, y, fault_vector);
    
    % Find cells within fault zone
    fault_zone_cells = find(cell_distances <= fault.width);
    
    % Create intersection data structure
    intersection_data = create_intersection_data(fault, fault_zone_cells, cell_distances);

end

function fault_vector = calculate_fault_vector(fault)
% Calculate fault vector and unit direction
    dx = fault.x2 - fault.x1;
    dy = fault.y2 - fault.y1;
    fault_length = sqrt(dx^2 + dy^2);
    
    fault_vector.dx = dx;
    fault_vector.dy = dy;
    fault_vector.length = fault_length;
    fault_vector.unit_x = dx / fault_length;
    fault_vector.unit_y = dy / fault_length;
end

function distances = calculate_cell_distances_to_fault(fault, x, y, fault_vector)
% Calculate distance from each cell to fault line
    n_cells = length(x);
    distances = zeros(n_cells, 1);
    
    for i = 1:n_cells
        distances(i) = point_to_line_distance(x(i), y(i), fault, fault_vector);
    end
end

function distance = point_to_line_distance(px, py, fault, fault_vector)
% Calculate distance from point to fault line segment
    
    % Vector from fault start to point
    cx = px - fault.x1;
    cy = py - fault.y1;
    
    % Project onto fault direction
    projection = cx * fault_vector.unit_x + cy * fault_vector.unit_y;
    projection = max(0, min(fault_vector.length, projection));
    
    % Find closest point on fault line
    closest_x = fault.x1 + projection * fault_vector.unit_x;
    closest_y = fault.y1 + projection * fault_vector.unit_y;
    
    % Calculate distance
    distance = sqrt((px - closest_x)^2 + (py - closest_y)^2);

end

function intersection_data = create_intersection_data(fault, fault_zone_cells, cell_distances)
% Create structured intersection data
    intersection_data = struct();
    intersection_data.fault_id = fault.id;
    intersection_data.affected_cells = fault_zone_cells;
    intersection_data.distances = cell_distances(fault_zone_cells);
    intersection_data.n_affected = length(fault_zone_cells);
end