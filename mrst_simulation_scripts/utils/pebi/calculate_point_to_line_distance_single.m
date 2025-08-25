function distance = calculate_point_to_line_distance_single(px, py, x1, y1, x2, y2)
% CALCULATE_POINT_TO_LINE_DISTANCE_SINGLE - Distance from point to line segment
%
% PURPOSE:
%   Calculates perpendicular distance from a point to a line segment.
%   Used for fault face alignment detection in PEBI grid generation.
%
% INPUTS:
%   px, py - Point coordinates
%   x1, y1, x2, y2 - Line segment endpoints
%
% OUTPUTS:
%   distance - Perpendicular distance from point to line segment
%
% Author: Claude Code AI System
% Policy: KISS Principle compliant (<15 lines)

    A = px - x1;
    B = py - y1;
    C = x2 - x1;
    D = y2 - y1;
    
    dot = A * C + B * D;
    len_sq = C^2 + D^2;
    
    if len_sq == 0
        distance = sqrt(A^2 + B^2);
        return;
    end
    
    param = max(0, min(1, dot / len_sq));
    
    xx = x1 + param * C;
    yy = y1 + param * D;
    
    distance = sqrt((px - xx)^2 + (py - yy)^2);
end