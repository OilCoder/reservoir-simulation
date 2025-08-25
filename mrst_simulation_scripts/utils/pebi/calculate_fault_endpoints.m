function [x1, y1, x2, y2] = calculate_fault_endpoints(fault_data, field_config)
% CALCULATE_FAULT_ENDPOINTS - Calculate fault line endpoints from parameters
%
% PURPOSE:
%   Calculates fault line endpoints from strike, length, and position data.
%   Uses geological convention for strike (degrees from north, clockwise).
%
% INPUTS:
%   fault_data - Individual fault configuration data
%   field_config - Field configuration for coordinate reference
%
% OUTPUTS:
%   x1, y1, x2, y2 - Fault line endpoints in field coordinates
%
% Author: Claude Code AI System
% Policy: KISS Principle compliant (<15 lines)

    % Get fault position offsets
    center_x = field_config.field_extent_x / 2 + fault_data.position_offset_x;
    center_y = field_config.field_extent_y / 2 + fault_data.position_offset_y;
    
    % Convert strike to radians (geological convention)
    strike_rad = deg2rad(fault_data.strike);
    
    % Calculate half-length in each direction
    half_length = fault_data.length / 2;
    
    % Calculate endpoints
    x1 = center_x - half_length * sin(strike_rad);
    y1 = center_y - half_length * cos(strike_rad);
    x2 = center_x + half_length * sin(strike_rad);
    y2 = center_y + half_length * cos(strike_rad);
end