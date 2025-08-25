function wb = design_vertical_completion(wb, well, wells_config)
% DESIGN_VERTICAL_COMPLETION - Design vertical well completion
%
% INPUTS:
%   wb - Wellbore structure to populate
%   well - Well data from wells placement
%   wells_config - Wells configuration from YAML
%
% OUTPUTS:
%   wb - Completed wellbore structure for vertical well
%
% Author: Claude Code AI System
% Date: August 22, 2025

    wb.trajectory = 'vertical';
    wb.completion_type = 'open_hole_gravel_pack';
    wb.completion_layers = well.completion_layers;
    
    % Initialize all fields for consistency
    wb.lateral_length_ft = 0;  % No lateral for vertical wells
    wb.lateral_tvd = well.total_depth_tvd_ft;
    wb.completion_stages = 1;  % Single stage for vertical
    wb.stage_length_ft = 0;
    
    % Multi-lateral fields (initialized to default values)
    wb.lateral_1_length_ft = 0;
    wb.lateral_2_length_ft = 0;
    wb.junction_type = 'none';
    wb.lateral_1_stages = 0;
    wb.lateral_2_stages = 0;
    wb.total_stages = 1;
    
    % Perforation design (CANON-FIRST)
    if ~isfield(wells_config.wells_system.completion_parameters, 'perforation_density') || ~isfield(wells_config.wells_system.completion_parameters, 'perforation_diameter_inch')
        error(['CANON-FIRST ERROR: Missing perforation parameters in wells_config.yaml\n' ...
               'UPDATE CANON: obsidian-vault/Planning/Wells_Configuration.md\n' ...
               'Must define exact perforation parameters for Eagle West Field.']);
    end
    wb.perforation_density = wells_config.wells_system.completion_parameters.perforation_density;
    wb.perforation_diameter = wells_config.wells_system.completion_parameters.perforation_diameter_inch;
    wb.perforation_penetration = 12;  % inches - equipment specification
    
    % Completion length from CANON configuration
    if ~isfield(wells_config.wells_system.completion_parameters, 'horizontal_completion') || ~isfield(wells_config.wells_system.completion_parameters.horizontal_completion, 'vertical_completion_length_ft')
        error(['CANON-FIRST ERROR: Missing vertical_completion_length_ft in wells_config.yaml\n' ...
               'UPDATE CANON: obsidian-vault/Planning/Wells_Configuration.md\n' ...
               'Must define exact completion length for vertical wells in Eagle West Field.']);
    end
    vertical_completion_length = wells_config.wells_system.completion_parameters.horizontal_completion.vertical_completion_length_ft;
    wb.completion_length_ft = length(well.completion_layers) * vertical_completion_length;
    
    % Sand control for vertical wells
    wb.sand_control = 'gravel_pack';
    wb.screen_type = 'slotted_liner';

end