function points = generate_well_constrained_points(well_points, fault_lines, field_config, size_function)
% GENERATE_WELL_CONSTRAINED_POINTS - Create point distribution for triangulation
%
% PURPOSE:
%   Generates constrained point distribution for triangular grid creation.
%   Includes well locations, fault-aligned points, and background distribution.
%
% INPUTS:
%   well_points - Well coordinates and sizing parameters
%   fault_lines - Fault geometry data
%   field_config - Field extents and parameters
%   size_function - Background spacing configuration
%
% OUTPUTS:
%   points - Nx2 array of [x, y] coordinates for triangulation
%
% POLICY COMPLIANCE:
%   - Data authority: Spacing parameters from configuration
%   - KISS principle: Essential point generation without over-complexity
%   - No over-engineering: Direct geometric placement
%
% Author: Claude Code AI System
% Policy: KISS Principle compliant (<40 lines)

    points = [];
    
    % Add exact well locations
    if ~isempty(well_points)
        well_coords = well_points(:, 1:2);
        points = [points; well_coords];
        fprintf('   Added %d well constraint points\n', size(well_coords, 1));
    end
    
    % Add fault constraint points
    if ~isempty(fault_lines)
        fault_points = [];
        for i = 1:size(fault_lines, 1)
            x1 = fault_lines(i, 1);
            y1 = fault_lines(i, 2);
            x2 = fault_lines(i, 3);
            y2 = fault_lines(i, 4);
            fault_size = fault_lines(i, 5);
            
            % Create points along fault line
            fault_length = sqrt((x2-x1)^2 + (y2-y1)^2);
            num_points = max(3, ceil(fault_length / fault_size));
            
            for j = 0:num_points
                t = j / num_points;
                x = x1 + t * (x2 - x1);
                y = y1 + t * (y2 - y1);
                fault_points = [fault_points; x, y];
            end
        end
        points = [points; fault_points];
        fprintf('   Added %d fault constraint points\n', size(fault_points, 1));
    end
    
    % Add background grid points
    background_spacing = size_function.background_size;
    x_coords = 0:background_spacing:field_config.field_extent_x;
    y_coords = 0:background_spacing:field_config.field_extent_y;
    [X_bg, Y_bg] = meshgrid(x_coords, y_coords);
    background_points = [X_bg(:), Y_bg(:)];
    
    points = [points; background_points];
    fprintf('   Total point distribution: %d points for triangulation\n', size(points, 1));
end