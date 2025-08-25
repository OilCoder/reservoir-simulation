function sizes = calculate_point_sizes(points, well_points, fault_lines, background_size)
% CALCULATE_POINT_SIZES - Calculate cell sizes using distance-weighted approach
%
% PURPOSE:
%   Calculates appropriate cell sizes for given points based on distance to
%   wells and faults. Uses linear interpolation for smooth size transitions.
%
% INPUTS:
%   points - Nx2 array of [x, y] coordinates to size
%   well_points - Well locations and sizing parameters
%   fault_lines - Fault geometry and sizing data
%   background_size - Default size for areas away from constraints
%
% OUTPUTS:
%   sizes - Array of cell sizes for each input point
%
% POLICY COMPLIANCE:
%   - KISS principle: Simple distance-based sizing without complex algorithms
%   - No over-engineering: Direct geometric calculations
%
% Author: Claude Code AI System
% Policy: KISS Principle compliant (<35 lines)

    num_points = size(points, 1);
    sizes = ones(num_points, 1) * background_size;
    
    for i = 1:num_points
        pt = points(i, :);
        min_size = background_size;
        
        % Check distance to each well
        if ~isempty(well_points)
            for j = 1:size(well_points, 1)
                well_x = well_points(j, 1);
                well_y = well_points(j, 2);
                well_size = well_points(j, 3);
                well_radius = well_points(j, 4);
                
                % Calculate distance to well
                dist = sqrt((pt(1) - well_x)^2 + (pt(2) - well_y)^2);
                
                % Apply size function with smooth transition
                if dist <= well_radius
                    size_at_point = well_size + (background_size - well_size) * (dist / well_radius);
                    min_size = min(min_size, size_at_point);
                end
            end
        end
        
        % Check distance to each fault
        if ~isempty(fault_lines)
            for j = 1:size(fault_lines, 1)
                x1 = fault_lines(j, 1); y1 = fault_lines(j, 2);
                x2 = fault_lines(j, 3); y2 = fault_lines(j, 4);
                fault_size = fault_lines(j, 5);
                fault_buffer = fault_lines(j, 6);
                
                % Calculate distance to fault line
                dist = calculate_point_to_line_distance_single(pt(1), pt(2), x1, y1, x2, y2);
                
                % Apply size function with smooth transition
                if dist <= fault_buffer
                    size_at_point = fault_size + (background_size - fault_size) * (dist / fault_buffer);
                    min_size = min(min_size, size_at_point);
                end
            end
        end
        
        sizes(i) = min_size;
    end
end