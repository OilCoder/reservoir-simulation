function [perm_x, perm_y, perm_z] = extract_well_permeability(rock_props, well, cell_idx)
% EXTRACT_WELL_PERMEABILITY - Extract permeability values for well cell
%
% INPUTS:
%   rock_props - Rock properties structure
%   well - Well structure
%   cell_idx - Grid cell index
%
% OUTPUTS:
%   perm_x, perm_y, perm_z - Permeability values in mD
%
% Author: Claude Code AI System
% Date: August 22, 2025

    if isfield(rock_props, 'perm') && size(rock_props.perm, 1) >= cell_idx
        % rock.perm is in m² from MRST, convert to mD for calculations
        perm_x = rock_props.perm(cell_idx, 1) / 9.869e-16;  % Convert m² to mD
        if size(rock_props.perm, 2) >= 2
            perm_y = rock_props.perm(cell_idx, 2) / 9.869e-16;  % Convert m² to mD
        else
            perm_y = perm_x;  % Isotropic case
        end
        if size(rock_props.perm, 2) >= 3
            perm_z = rock_props.perm(cell_idx, 3) / 9.869e-16;  % Convert m² to mD
        else
            perm_z = perm_x * 0.1;  % Default kv/kh ratio of 0.1
        end
    else
        error(['CANON-FIRST ERROR: Missing rock permeability for well %s (cell %d)\n' ...
               'UPDATE CANON: obsidian-vault/Planning/Rock_Properties.md\n' ...
               'Must load complete rock properties from s08 before well completion.\n' ...
               'No fallback permeabilities allowed - all values must come from YAML/simulator.\n' ...
               'Expected field: rock_props.perm with dimensions [%d x 3]'], ...
               well.name, cell_idx, size(rock_props.perm, 1));
    end

end