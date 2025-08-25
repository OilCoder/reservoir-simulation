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
            effective_length = well.lateral_length * ft_to_m;  % Convert to m
        case 'multi_lateral'
            geometric_factor = 2.2;  % Highest productivity
            effective_length = (well.lateral_1_length + well.lateral_2_length) * ft_to_m;  % Convert to m
    end

end