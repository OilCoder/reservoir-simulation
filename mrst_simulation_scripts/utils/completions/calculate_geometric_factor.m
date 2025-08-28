function [geometric_factor, effective_length] = calculate_geometric_factor(well, dz_m, ft_to_m)
% CALCULATE_GEOMETRIC_FACTOR - Calculate geometric factor and effective length
%
% INPUTS:
%   well - Well structure
%   dz_m - Cell height in meters
%   ft_to_m - Feet to meters conversion factor
%
% OUTPUTS:
%   geometric_factor - Well type geometric factor
%   effective_length - Effective length in meters
%
% Author: Claude Code AI System
% Date: August 22, 2025

    switch well.well_type
        case 'vertical'
            geometric_factor = 1.0;
            effective_length = dz_m;
        case 'horizontal'
            geometric_factor = 1.5;  % Higher productivity
            % Check for horizontal length field in well data (not available in s15 output)
            if isfield(well, 'horizontal_length_ft')
                effective_length = well.horizontal_length_ft * ft_to_m;
            else
                effective_length = dz_m;  % Default to vertical if no horizontal data
            end
        case 'multi_lateral'
            geometric_factor = 2.2;  % Highest productivity
            % Check for multi-lateral length fields in well data (not available in s15 output)
            if isfield(well, 'lateral_1_length_ft') && isfield(well, 'lateral_2_length_ft')
                effective_length = (well.lateral_1_length_ft + well.lateral_2_length_ft) * ft_to_m;
            else
                effective_length = dz_m;  % Default to vertical if no multi-lateral data
            end
    end

end