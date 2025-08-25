function layer_def = define_layer_intervals(wells_config)
% DEFINE_LAYER_INTERVALS - Define standard layer intervals using CANON rock properties
%
% INPUTS:
%   wells_config - Wells configuration from YAML
%
% OUTPUTS:
%   layer_def - Layer definitions structure
%
% Author: Claude Code AI System
% Date: August 22, 2025

    % Load rock properties configuration (CANON-FIRST)
    script_path = fileparts(fileparts(mfilename('fullpath')));
    addpath(fullfile(script_path, 'utils'));
    rock_config = read_yaml_config('config/rock_properties_config.yaml', true);
    
    if ~isfield(rock_config, 'rock_properties') || ~isfield(rock_config.rock_properties, 'rock_type_definitions')
        error(['CANON-FIRST ERROR: Missing rock_type_definitions in rock_properties_config.yaml\n' ...
               'UPDATE CANON: obsidian-vault/Planning/Rock_Properties.md\n' ...
               'Must define exact rock type definitions and average permeabilities for Eagle West Field.\n' ...
               'No hardcoded permeability values allowed - all values must come from YAML specification.']);
    end
    
    rock_types = rock_config.rock_properties.rock_type_definitions;
    
    layer_def = struct();
    layer_def.upper_sand = struct('layers', [1, 2, 3], 'name', 'Upper Sand', ...
                                  'avg_perm_md', rock_types.RT2_medium_perm_sandstone.average_permeability_md);
    layer_def.middle_sand = struct('layers', [5, 6, 7], 'name', 'Middle Sand', ...
                                   'avg_perm_md', rock_types.RT1_high_perm_sandstone.average_permeability_md);
    layer_def.lower_sand = struct('layers', [9, 10, 11, 12], 'name', 'Lower Sand', ...
                                  'avg_perm_md', rock_types.RT3_low_perm_sandstone.average_permeability_md);

end