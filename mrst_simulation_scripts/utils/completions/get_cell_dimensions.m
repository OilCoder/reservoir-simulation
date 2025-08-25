function [dx_m, dy_m, dz_m] = get_cell_dimensions(G, well, cell_idx, ft_to_m)
% GET_CELL_DIMENSIONS - Get grid cell dimensions for well
%
% INPUTS:
%   G - Grid structure from MRST
%   well - Well structure
%   cell_idx - Grid cell index
%   ft_to_m - Feet to meters conversion factor
%
% OUTPUTS:
%   dx_m, dy_m, dz_m - Cell dimensions in meters
%
% Author: Claude Code AI System
% Date: August 22, 2025

    if cell_idx <= G.cells.num
        dx = G.cells.volumes(cell_idx)^(1/3);  % Approximate cell size
        dy = dx;
        dz = dx;
        
        % Convert to meters
        dx_m = dx * ft_to_m;
        dy_m = dy * ft_to_m;
        dz_m = dz * ft_to_m;
    else
        error(['CANON-FIRST ERROR: Missing grid cell information for well %s (cell %d)\n' ...
               'UPDATE CANON: obsidian-vault/Planning/Grid_Configuration.md\n' ...
               'Must load complete grid from s05 before well completion.\n' ...
               'No fallback cell dimensions allowed - all values must come from YAML/simulator.'], ...
               well.name, cell_idx);
    end

end