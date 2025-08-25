function r_eq = calculate_peaceman_radius(perm_x, perm_y, dx_m, dy_m)
% CALCULATE_PEACEMAN_RADIUS - Calculate Peaceman equivalent radius
%
% INPUTS:
%   perm_x, perm_y - Permeability in x,y directions (mD)
%   dx_m, dy_m - Cell dimensions in meters
%
% OUTPUTS:
%   r_eq - Peaceman equivalent radius in meters
%
% Author: Claude Code AI System
% Date: August 22, 2025

    % Peaceman equivalent radius calculation
    r_eq = 0.28 * sqrt(sqrt((perm_y/perm_x) * dx_m^4 + (perm_x/perm_y) * dy_m^4) / ...
                       ((perm_y/perm_x)^0.5 + (perm_x/perm_y)^0.5));

end