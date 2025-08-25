function well_indices = calculate_well_indices_peaceman(wells_data, rock_props, G, init_config)
% CALCULATE_WELL_INDICES_PEACEMAN - Calculate well indices using Peaceman model
%
% INPUTS:
%   wells_data - Wells placement structure from s15
%   rock_props - Rock properties structure
%   G - Grid structure from MRST
%   init_config - Initialization configuration from YAML
%
% OUTPUTS:
%   well_indices - Array of well index calculations
%
% Author: Claude Code AI System
% Date: August 22, 2025

    % Add helper functions to path
    script_path = fileparts(mfilename('fullpath'));
    addpath(script_path);
    
    all_wells = [wells_data.producer_wells; wells_data.injector_wells];
    well_indices = [];
    
    % Validate unit conversions
    if ~isfield(init_config.initialization, 'unit_conversions') || ~isfield(init_config.initialization.unit_conversions.length, 'ft_to_m')
        error(['CANON-FIRST ERROR: Missing ft_to_m conversion factor in initialization_config.yaml\n' ...
               'UPDATE CANON: obsidian-vault/Planning/Initial_Conditions.md\n' ...
               'Must define exact unit conversion factors for Eagle West Field.']);
    end
    ft_to_m = init_config.initialization.unit_conversions.length.ft_to_m;
    
    % Calculate for each well
    for i = 1:length(all_wells)
        well = all_wells(i);
        cell_idx = well.cell_index;
        
        % Initialize well index structure
        wi = struct();
        wi.name = well.name;
        wi.type = well.type;
        wi.well_type = well.well_type;
        
        % Extract permeability values
        [perm_x, perm_y, perm_z] = extract_well_permeability(rock_props, well, cell_idx);
        
        % Get grid cell dimensions
        [dx_m, dy_m, dz_m] = get_cell_dimensions(G, well, cell_idx, ft_to_m);
        
        % Calculate Peaceman equivalent radius
        r_eq = calculate_peaceman_radius(perm_x, perm_y, dx_m, dy_m);
        
        % Calculate well index using Peaceman formula
        wi = calculate_single_well_index(wi, well, perm_x, perm_y, perm_z, r_eq, dz_m, ft_to_m);
        
        well_indices = [well_indices; wi];
        
        % Display well index calculation details
        fprintf('   ■ %s: WI=%.2e, Perm=[%.0f,%.0f,%.0f] mD, r_eq=%.3f m, skin=%.1f\n', ...
                wi.name, wi.well_index, wi.permeability_md(1), wi.permeability_md(2), wi.permeability_md(3), ...
                wi.equivalent_radius_m, wi.skin_factor);
    end

end