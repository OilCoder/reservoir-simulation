function wi = calculate_single_well_index(wi, well, perm_x, perm_y, perm_z, r_eq, dz_m, ft_to_m)
% CALCULATE_SINGLE_WELL_INDEX - Calculate well index for single well
%
% INPUTS:
%   wi - Well index structure to populate
%   well - Well structure
%   perm_x, perm_y, perm_z - Permeability values in mD
%   r_eq - Peaceman equivalent radius in meters
%   dz_m - Cell height in meters
%   ft_to_m - Feet to meters conversion factor
%
% OUTPUTS:
%   wi - Completed well index structure
%
% Author: Claude Code AI System
% Date: August 22, 2025

    % Convert wellbore radius to meters
    rw = well.wellbore_radius_ft * ft_to_m;
    skin = well.skin_factor;
    
    % Calculate geometric factor and effective length
    [geometric_factor, effective_length] = calculate_geometric_factor(well, dz_m, ft_to_m);
    
    % Well index calculation (Peaceman formula)
    perm_avg = sqrt(perm_x * perm_y) * 9.869e-16;  % Convert mD to m²
    
    if r_eq > rw && effective_length > 0
        wi.well_index = (2 * pi * perm_avg * effective_length * geometric_factor) / ...
                       (log(r_eq/rw) + skin);
    else
        wi.well_index = 1e-12;  % Default small value
    end
    
    % Store calculation details
    wi.permeability_md = [perm_x, perm_y, perm_z];
    wi.equivalent_radius_m = r_eq;
    wi.wellbore_radius_m = rw;
    wi.skin_factor = skin;
    wi.geometric_factor = geometric_factor;
    wi.effective_length_m = effective_length;

end