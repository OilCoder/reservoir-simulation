function wellbore_design = design_wellbore_completions(wells_data, wells_config, init_config)
% DESIGN_WELLBORE_COMPLETIONS - Design wellbore completions for all wells
%
% INPUTS:
%   wells_data - Wells placement structure from s15
%   wells_config - Wells configuration from YAML
%   init_config - Initialization configuration from YAML
%
% OUTPUTS:
%   wellbore_design - Structure with wellbore completion design
%
% Author: Claude Code AI System
% Date: August 22, 2025

    wellbore_design = struct();
    all_wells = [wells_data.producer_wells; wells_data.injector_wells];
    
    % Add completion design functions to path
    script_path = fileparts(mfilename('fullpath'));
    addpath(script_path);
    
    % Standard wellbore parameters (CANON-FIRST)
    if ~isfield(wells_config, 'wells_system') || ~isfield(wells_config.wells_system, 'completion_parameters') || ~isfield(wells_config.wells_system.completion_parameters, 'wellbore_radius_m')
        error(['CANON-FIRST ERROR: Missing wellbore_radius_m in wells_config.yaml\n' ...
               'UPDATE CANON: obsidian-vault/Planning/Wells_Configuration.md\n' ...
               'Must define exact wellbore radius for Eagle West Field.']);
    end
    wellbore_design.standard_radius_m = wells_config.wells_system.completion_parameters.wellbore_radius_m;
    
    % Convert to feet using CANON conversion factor
    if ~isfield(init_config.initialization, 'unit_conversions') || ~isfield(init_config.initialization.unit_conversions.length, 'm_to_ft')
        error(['CANON-FIRST ERROR: Missing m_to_ft conversion factor in initialization_config.yaml\n' ...
               'UPDATE CANON: obsidian-vault/Planning/Initial_Conditions.md\n' ...
               'Must define exact unit conversion factors for Eagle West Field.']);
    end
    m_to_ft = init_config.initialization.unit_conversions.length.m_to_ft;
    wellbore_design.standard_radius_ft = wellbore_design.standard_radius_m * m_to_ft;
    
    % Design completions for each well
    wellbore_design.wells = [];
    
    for i = 1:length(all_wells)
        well = all_wells(i);
        
        wb = struct();
        wb.name = well.name;
        wb.type = well.type;
        wb.well_type = well.well_type;
        
        % Wellbore geometry (CANON-FIRST)
        wb.radius_m = wellbore_design.standard_radius_m;
        wb.radius_ft = well.wellbore_radius;
        wb.skin_factor = well.skin_factor;
        
        % Completion design based on well type
        switch well.well_type
            case 'vertical'
                wb = design_vertical_completion(wb, well, wells_config);
            case 'horizontal'
                wb = design_horizontal_completion(wb, well, wells_config);
            case 'multi_lateral'
                wb = design_multilateral_completion(wb, well, wells_config);
        end
        
        wellbore_design.wells = [wellbore_design.wells; wb];
        
        % Display detailed completion design
        fprintf('   ■ %s: %s completion (radius: %.2f ft, skin: %.1f, stages: %d, length: %.0f ft)\n', ...
                wb.name, wb.completion_type, wb.radius_ft, wb.skin_factor, wb.completion_stages, wb.completion_length_ft);
    end
    
    % Completion statistics
    wellbore_design.statistics = calculate_completion_statistics(wellbore_design.wells);

end