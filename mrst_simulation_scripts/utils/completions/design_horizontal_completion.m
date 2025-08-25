function wb = design_horizontal_completion(wb, well, wells_config)
% DESIGN_HORIZONTAL_COMPLETION - Design horizontal well completion
%
% INPUTS:
%   wb - Wellbore structure to populate
%   well - Well data from wells placement
%   wells_config - Wells configuration from YAML
%
% OUTPUTS:
%   wb - Completed wellbore structure for horizontal well
%
% Author: Claude Code AI System
% Date: August 22, 2025

    wb.trajectory = 'horizontal';
    wb.completion_type = 'openhole_completion';
    wb.completion_layers = well.completion_layers;
    
    % Lateral specifications
    wb.lateral_length_ft = well.lateral_length;
    wb.lateral_tvd = well.total_depth_tvd_ft;
    
    % Multi-stage completion from CANON configuration
    if ~isfield(wells_config.wells_system.completion_parameters, 'horizontal_completion') || ~isfield(wells_config.wells_system.completion_parameters.horizontal_completion, 'stage_length_ft')
        error(['CANON-FIRST ERROR: Missing stage_length_ft in wells_config.yaml\n' ...
               'UPDATE CANON: obsidian-vault/Planning/Wells_Configuration.md\n' ...
               'Must define exact stage length for horizontal wells in Eagle West Field.']);
    end
    stage_length = wells_config.wells_system.completion_parameters.horizontal_completion.stage_length_ft;
    wb.completion_stages = ceil(wb.lateral_length_ft / stage_length);
    wb.stage_length_ft = wb.lateral_length_ft / wb.completion_stages;
    
    % Multi-lateral fields (initialized for horizontal wells)
    wb.lateral_1_length_ft = wb.lateral_length_ft;  % Single lateral
    wb.lateral_2_length_ft = 0;
    wb.junction_type = 'none';
    wb.lateral_1_stages = wb.completion_stages;
    wb.lateral_2_stages = 0;
    wb.total_stages = wb.completion_stages;
    
    % Perforation design for horizontals from CANON configuration
    if ~isfield(wells_config.wells_system.completion_parameters, 'perforation_factors')
        error(['CANON-FIRST ERROR: Missing perforation_factors in wells_config.yaml\n' ...
               'UPDATE CANON: obsidian-vault/Planning/Wells_Configuration.md\n' ...
               'Must define exact perforation factors for horizontal wells in Eagle West Field.']);
    end
    perf_factors = wells_config.wells_system.completion_parameters.perforation_factors;
    wb.perforation_density = wells_config.wells_system.completion_parameters.perforation_density * perf_factors.horizontal_density_factor;
    wb.perforation_diameter = wells_config.wells_system.completion_parameters.perforation_diameter_inch * perf_factors.horizontal_diameter_factor;
    wb.perforation_penetration = 18;  % inches - equipment specification
    
    % Sand control for horizontal wells
    wb.sand_control = 'premium_screens';
    wb.screen_type = 'wire_wrap_screen';
    
    wb.completion_length_ft = wb.lateral_length_ft;

end