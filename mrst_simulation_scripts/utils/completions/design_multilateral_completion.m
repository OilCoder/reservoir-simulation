function wb = design_multilateral_completion(wb, well, wells_config)
% DESIGN_MULTILATERAL_COMPLETION - Design multi-lateral well completion
%
% INPUTS:
%   wb - Wellbore structure to populate
%   well - Well data from wells placement
%   wells_config - Wells configuration from YAML
%
% OUTPUTS:
%   wb - Completed wellbore structure for multi-lateral well
%
% Author: Claude Code AI System
% Date: August 22, 2025

    wb.trajectory = 'multi_lateral';
    wb.completion_type = 'multi_lateral_junction';
    wb.completion_layers = well.completion_layers;
    
    % Multi-lateral specifications
    wb.lateral_1_length_ft = well.lateral_1_length;
    wb.lateral_2_length_ft = well.lateral_2_length;
    wb.junction_type = 'level_4_mechanical';
    
    % Standard fields for consistency
    wb.lateral_length_ft = wb.lateral_1_length_ft + wb.lateral_2_length_ft;  % Total lateral length
    wb.lateral_tvd = well.total_depth_tvd_ft;
    
    % Multi-stage completion for each lateral from CANON configuration
    if ~isfield(wells_config.wells_system.completion_parameters, 'horizontal_completion') || ~isfield(wells_config.wells_system.completion_parameters.horizontal_completion, 'multilateral_stage_length_ft')
        error(['CANON-FIRST ERROR: Missing multilateral_stage_length_ft in wells_config.yaml\n' ...
               'UPDATE CANON: obsidian-vault/Planning/Wells_Configuration.md\n' ...
               'Must define exact stage length for multilateral wells in Eagle West Field.']);
    end
    multilateral_stage_length = wells_config.wells_system.completion_parameters.horizontal_completion.multilateral_stage_length_ft;
    wb.lateral_1_stages = ceil(wb.lateral_1_length_ft / multilateral_stage_length);
    wb.lateral_2_stages = ceil(wb.lateral_2_length_ft / multilateral_stage_length);
    wb.total_stages = wb.lateral_1_stages + wb.lateral_2_stages;
    wb.completion_stages = wb.total_stages;  % For consistency with horizontal
    wb.stage_length_ft = wb.lateral_length_ft / wb.total_stages;
    
    % Perforation design for multilaterals from CANON configuration
    if ~isfield(wells_config.wells_system.completion_parameters, 'perforation_factors')
        error(['CANON-FIRST ERROR: Missing perforation_factors in wells_config.yaml\n' ...
               'UPDATE CANON: obsidian-vault/Planning/Wells_Configuration.md\n' ...
               'Must define exact perforation factors for multilateral wells in Eagle West Field.']);
    end
    perf_factors = wells_config.wells_system.completion_parameters.perforation_factors;
    wb.perforation_density = wells_config.wells_system.completion_parameters.perforation_density * perf_factors.multilateral_density_factor;
    wb.perforation_diameter = wells_config.wells_system.completion_parameters.perforation_diameter_inch * perf_factors.multilateral_diameter_factor;
    wb.perforation_penetration = perf_factors.multilateral_penetration_inch;
    
    % Advanced sand control
    wb.sand_control = 'expandable_screens';
    wb.screen_type = 'alpha_beta_wave';
    
    wb.completion_length_ft = wb.lateral_1_length_ft + wb.lateral_2_length_ft;

end