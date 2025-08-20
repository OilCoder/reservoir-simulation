function completion_results = s16_well_completions()
% S16_WELL_COMPLETIONS - Well Completion Design for Eagle West Field
% Requires: MRST
%
% Creates well completions with:
% - Wellbore radius: 0.1 m (6-inch)
% - Skin factors: 3.0-5.0 (producers), -2.5 to 1.0 (injectors)
% - Well indices calculation (Peaceman model)
% - Completion intervals per well from documentation
% - Layer-specific completions (Upper/Middle/Lower Sand)
%
% OUTPUTS:
%   completion_results - Structure with completion design results
%
% Author: Claude Code AI System
% Date: August 8, 2025

    script_dir = fileparts(mfilename('fullpath'));
    addpath(fullfile(script_dir, 'utils')); 
    run(fullfile(script_dir, 'utils', 'print_utils.m'));

    % Add MRST session validation
    [success, message] = validate_mrst_session(script_dir);
    if ~success
        error('MRST validation failed: %s', message);
    end
    print_step_header('S16', 'Well Completion Design');
    
    total_start_time = tic;
    completion_results = initialize_completion_structure();
    
    try
        % ----------------------------------------
        % Step 1 - Load Wells and Rock Properties
        % ----------------------------------------
        step_start = tic;
        [wells_data, rock_props, G, wells_config, init_config] = step_1_load_wells_and_properties();
        completion_results.wells_data = wells_data;
        completion_results.rock_props = rock_props;
        print_step_result(1, 'Load Wells and Properties', 'success', toc(step_start));
        
        % ----------------------------------------
        % Step 2 - Design Wellbore Completions
        % ----------------------------------------
        step_start = tic;
        wellbore_design = step_2_design_wellbore_completions(wells_data, wells_config, init_config);
        completion_results.wellbore_design = wellbore_design;
        print_step_result(2, 'Design Wellbore Completions', 'success', toc(step_start));
        
        % ----------------------------------------
        % Step 3 - Calculate Well Indices (Peaceman)
        % ----------------------------------------
        step_start = tic;
        well_indices = step_3_calculate_well_indices(wells_data, rock_props, G, init_config);
        completion_results.well_indices = well_indices;
        print_step_result(3, 'Calculate Well Indices', 'success', toc(step_start));
        
        % ----------------------------------------
        % Step 4 - Define Completion Intervals
        % ----------------------------------------
        step_start = tic;
        completion_intervals = step_4_define_completion_intervals(wells_data, G, wells_config);
        completion_results.completion_intervals = completion_intervals;
        print_step_result(4, 'Define Completion Intervals', 'success', toc(step_start));
        
        % ----------------------------------------
        % Step 5 - Create MRST Well Structures
        % ----------------------------------------
        step_start = tic;
        mrst_wells = step_5_create_mrst_wells(wells_data, well_indices, G, init_config, wells_config);
        completion_results.mrst_wells = mrst_wells;
        print_step_result(5, 'Create MRST Well Structures', 'success', toc(step_start));
        
        % ----------------------------------------
        % Step 6 - Export Completion Data
        % ----------------------------------------
        step_start = tic;
        export_path = step_6_export_completion_data(completion_results);
        completion_results.export_path = export_path;
        print_step_result(6, 'Export Completion Data', 'success', toc(step_start));
        
        completion_results.status = 'success';
        completion_results.total_wells = length([completion_results.wells_data.producer_wells; ...
                                                 completion_results.wells_data.injector_wells]);
        completion_results.creation_time = datestr(now);
        
        print_step_footer('S16', sprintf('Well Completions Designed (%d wells)', ...
            completion_results.total_wells), toc(total_start_time));
        
    catch ME
        print_error_step(0, 'Well Completions', ME.message);
        completion_results.status = 'failed';
        completion_results.error_message = ME.message;
        error('Well completion design failed: %s', ME.message);
    end

end

function completion_results = initialize_completion_structure()
% Initialize well completion results structure
    completion_results = struct();
    completion_results.status = 'initializing';
    completion_results.wellbore_design = [];
    completion_results.well_indices = [];
    completion_results.completion_intervals = [];
    completion_results.mrst_wells = [];
end

function [wells_data, rock_props, G, wells_config, init_config] = step_1_load_wells_and_properties()
% Step 1 - Load well placement and rock properties data

    script_path = fileparts(mfilename('fullpath'));
    if isempty(script_path)
        script_path = pwd();
    end
    
    % Load YAML configurations for unit conversions and well parameters
    addpath(fullfile(script_path, 'utils'));
    wells_config = read_yaml_config('config/wells_config.yaml', true);
    init_config = read_yaml_config('config/initialization_config.yaml', true);
    
    data_dir = get_data_path('static');
    
    % Substep 1.1 - Load well placement data from S15 (CANON-FIRST: exact predecessor output)
    % S15 generates well_placement_s15.mat - use exact file from predecessor
    required_s15_file = fullfile(data_dir, 'well_placement_s15.mat');
    if exist(required_s15_file, 'file')
        load(required_s15_file, 'wells_results');
        wells_data = wells_results;
        % Wells loaded successfully from canonical S15 output
    else
        error(['CANON-FIRST ERROR: Missing required S15 well placement data.\n' ...
               'REQUIRED: Run s15_well_placement.m first.\n' ...
               'Expected file: %s\n' ...
               'Canon specification: S16 requires exact S15 output with well coordinates and cell indices.\n' ...
               'No fallbacks allowed - predecessor must generate complete placement data.'], required_s15_file);
    end
    
    % Substep 1.2 - Load rock properties from canonical structure (CANON-FIRST)
    % Use same canonical data organization pattern as s13 and s09
    base_data_path = fullfile(fileparts(fileparts(mfilename('fullpath'))), 'data');
    canonical_data_dir = fullfile(base_data_path, 'by_type', 'static');
    canonical_rock_file = fullfile(canonical_data_dir, 'final_simulation_rock.mat');
    
    if exist(canonical_rock_file, 'file')
        % Loading rock properties from canonical structure
        
        % ROBUST LOADING: Handle both 'rock' and 'final_rock' variable names for compatibility
        file_vars = whos('-file', canonical_rock_file);
        var_names = {file_vars.name};
        
        if ismember('rock', var_names)
            % New canonical format with 'rock' variable name
            load(canonical_rock_file, 'rock', 'G');
            rock_props = rock;
        elseif ismember('final_rock', var_names)
            % Legacy format with 'final_rock' variable name
            load_data = load(canonical_rock_file, 'final_rock', 'G');
            rock_props = load_data.final_rock;  % Rename for consistency
            if isfield(load_data, 'G') && ~exist('G', 'var')
                grid_from_rock_file = load_data.G;
            end
            clear load_data;
        else
            error(['CANON-FIRST ERROR: Neither ''rock'' nor ''final_rock'' variables found in canonical file.\n' ...
                   'REQUIRED: Run s08_apply_spatial_heterogeneity.m first.\n' ...
                   'File: %s\n' ...
                   'Available variables: %s'], canonical_rock_file, strjoin(var_names, ', '));
        end
        % Rock properties loaded successfully
    else
        % CANON-FIRST ERROR: No fallbacks allowed, must use canonical structure
        error(['CANON-FIRST ERROR: Final rock structure not found at canonical location.\n' ...
               'REQUIRED: Update obsidian-vault/Planning/Rock_Properties.md\n' ...
               'REQUIRED: Run s08_apply_spatial_heterogeneity.m first.\n' ...
               'CANON LOCATION: %s\n' ...
               'No legacy fallbacks allowed - data must be in by_type/static structure.'], canonical_rock_file);
    end
    
    % Substep 1.3 - Load grid structure (CANON-FIRST) ______________
    % First check if we already loaded grid with rock properties
    if exist('grid_from_rock_file', 'var')
        G = grid_from_rock_file;
        % Grid loaded with rock properties
    elseif exist('G', 'var')
        % Grid was loaded together with rock properties above
        % Grid available from rock properties loading
    else
        % Load grid from canonical structure or fallback to legacy locations
        canonical_grid_file = fullfile(canonical_data_dir, 'pebi_grid.mat');
        if exist(canonical_grid_file, 'file')
            % Loading grid from canonical structure
            load(canonical_grid_file, 'G');
            % Grid loaded from canonical structure
        else
            % CANON-FIRST ERROR: No fallbacks allowed, must use canonical structure
            error(['CANON-FIRST ERROR: Grid structure not found at canonical location.\n' ...
                   'REQUIRED: Update obsidian-vault/Planning/Grid_Configuration.md\n' ...
                   'REQUIRED: Run s05_create_pebi_grid.m first.\n' ...
                   'CANON LOCATION: %s\n' ...
                   'No legacy fallbacks allowed - data must be in by_type/static structure.'], canonical_grid_file);
        end
    end

end

function wellbore_design = step_2_design_wellbore_completions(wells_data, wells_config, init_config)
% Step 2 - Design wellbore completions for all wells

    wellbore_design = struct();
    
    % Wellbore completion design phase
    
    all_wells = [wells_data.producer_wells; wells_data.injector_wells];
    
    % Substep 2.1 - Standard wellbore parameters (CANON-FIRST) ___________________
    % Extract wellbore parameters from wells configuration
    if ~isfield(wells_config, 'wells_system') || ~isfield(wells_config.wells_system, 'completion_parameters') || ~isfield(wells_config.wells_system.completion_parameters, 'wellbore_radius_m')
        error(['CANON-FIRST ERROR: Missing wellbore_radius_m in wells_config.yaml\n' ...
               'UPDATE CANON: obsidian-vault/Planning/Wells_Configuration.md\n' ...
               'Must define exact wellbore radius for Eagle West Field.']);
    end
    wellbore_design.standard_radius_m = wells_config.wells_system.completion_parameters.wellbore_radius_m;  % CANON wellbore radius
    
    % Convert to feet using CANON conversion factor
    if ~isfield(init_config.initialization, 'unit_conversions') || ~isfield(init_config.initialization.unit_conversions.length, 'm_to_ft')
        error(['CANON-FIRST ERROR: Missing m_to_ft conversion factor in initialization_config.yaml\n' ...
               'UPDATE CANON: obsidian-vault/Planning/Initial_Conditions.md\n' ...
               'Must define exact unit conversion factors for Eagle West Field.']);
    end
    m_to_ft = init_config.initialization.unit_conversions.length.m_to_ft;
    wellbore_design.standard_radius_ft = wellbore_design.standard_radius_m * m_to_ft;
    
    % Substep 2.2 - Design completions for each well _______________
    wellbore_design.wells = [];
    
    for i = 1:length(all_wells)
        well = all_wells(i);
        
        wb = struct();
        wb.name = well.name;
        wb.type = well.type;
        wb.well_type = well.well_type;
        
        % Wellbore geometry (CANON-FIRST)
        wb.radius_m = wellbore_design.standard_radius_m;  % CANON wellbore radius from YAML
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
        
        % Display detailed completion design (CANON-FIRST: Always show consistent output)
        fprintf('   ■ %s: %s completion (radius: %.2f ft, skin: %.1f, stages: %d, length: %.0f ft)\n', ...
                wb.name, wb.completion_type, wb.radius_ft, wb.skin_factor, wb.completion_stages, wb.completion_length_ft);
    end
    
    % Step section complete
    
    % Display wellbore design table (CANON-FIRST: Always show detailed completion information)
    fprintf('\n   WELLBORE COMPLETION DESIGN SUMMARY:\n');
    fprintf('   ┌─────────┬────────────┬─────────┬────────┬────────┬──────────┐\n');
    fprintf('   │ Well    │ Type       │ Radius  │ Skin   │ Stages │ Length   │\n');
    fprintf('   │         │            │ (ft)    │        │        │ (ft)     │\n');
    fprintf('   ├─────────┼────────────┼─────────┼────────┼────────┼──────────┤\n');
    for i = 1:length(wellbore_design.wells)
        wb = wellbore_design.wells(i);
        fprintf('   │ %-7s │ %-10s │ %6.2f  │ %6.1f │ %6d │ %8.0f │\n', ...
                wb.name, wb.well_type, wb.radius_ft, wb.skin_factor, wb.completion_stages, wb.completion_length_ft);
    end
    fprintf('   └─────────┴────────────┴─────────┴────────┴────────┴──────────┘\n');
    
    % Substep 2.3 - Completion statistics __________________________
    wellbore_design.statistics = calculate_completion_statistics(wellbore_design.wells);

end

function wb = design_vertical_completion(wb, well, wells_config)
% Design vertical well completion

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
    wb.perforation_density = wells_config.wells_system.completion_parameters.perforation_density;  % CANON from YAML
    wb.perforation_diameter = wells_config.wells_system.completion_parameters.perforation_diameter_inch;  % CANON from YAML
    % Use default penetration (this is typically equipment-specific constant)
    wb.perforation_penetration = 12;  % inches - equipment specification
    
    % Completion length from CANON configuration (CANON-FIRST)
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

function wb = design_horizontal_completion(wb, well, wells_config)
% Design horizontal well completion

    wb.trajectory = 'horizontal';
    wb.completion_type = 'openhole_completion';
    wb.completion_layers = well.completion_layers;
    
    % Lateral specifications
    wb.lateral_length_ft = well.lateral_length;
    wb.lateral_tvd = well.total_depth_tvd_ft;
    
    % Multi-stage completion from CANON configuration (CANON-FIRST)
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
    
    % Perforation design for horizontals from CANON configuration (CANON-FIRST)
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

function wb = design_multilateral_completion(wb, well, wells_config)
% Design multi-lateral well completion

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
    
    % Multi-stage completion for each lateral from CANON configuration (CANON-FIRST)
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
    
    % Perforation design for multilaterals from CANON configuration (CANON-FIRST)
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

function stats = calculate_completion_statistics(wells)
% Calculate completion design statistics

    stats = struct();
    
    % Count by well type
    stats.vertical_count = sum(strcmp({wells.well_type}, 'vertical'));
    stats.horizontal_count = sum(strcmp({wells.well_type}, 'horizontal'));
    stats.multilateral_count = sum(strcmp({wells.well_type}, 'multi_lateral'));
    
    % Skin factor statistics
    skin_factors = [wells.skin_factor];
    stats.skin_factor_min = min(skin_factors);
    stats.skin_factor_max = max(skin_factors);
    stats.skin_factor_mean = mean(skin_factors);
    
    % Completion length statistics
    completion_lengths = [wells.completion_length_ft];
    stats.total_completion_length_ft = sum(completion_lengths);
    stats.average_completion_length_ft = mean(completion_lengths);
    stats.max_completion_length_ft = max(completion_lengths);

end

function well_indices = step_3_calculate_well_indices(wells_data, rock_props, G, init_config)
% Step 3 - Calculate well indices using Peaceman model

    % Calculating well indices using Peaceman model
    
    all_wells = [wells_data.producer_wells; wells_data.injector_wells];
    well_indices = [];
    
    % Substep 3.1 - Calculate for each well __________________________
    for i = 1:length(all_wells)
        well = all_wells(i);
        
        wi = struct();
        wi.name = well.name;
        wi.type = well.type;
        wi.well_type = well.well_type;
        
        % Get grid cell properties
        cell_idx = well.cell_index;
        
        % Substep 3.2 - Get rock properties for well cell _____________
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
            % CANON-FIRST ERROR: Rock properties must be available for well index calculation
            error(['CANON-FIRST ERROR: Missing rock permeability for well %s (cell %d)\n' ...
                   'UPDATE CANON: obsidian-vault/Planning/Rock_Properties.md\n' ...
                   'Must load complete rock properties from s08 before well completion.\n' ...
                   'No fallback permeabilities allowed - all values must come from YAML/simulator.\n' ...
                   'Expected field: rock_props.perm with dimensions [%d x 3]'], ...
                   well.name, cell_idx, size(rock_props.perm, 1));
        end
        
        % Substep 3.3 - Calculate equivalent radius (Peaceman) ________
        if cell_idx <= G.cells.num
            dx = G.cells.volumes(cell_idx)^(1/3);  % Approximate cell size
            dy = dx;
            dz = dx;
        else
            % CANON-FIRST ERROR: Grid cell information must be available
            error(['CANON-FIRST ERROR: Missing grid cell information for well %s (cell %d)\n' ...
                   'UPDATE CANON: obsidian-vault/Planning/Grid_Configuration.md\n' ...
                   'Must load complete grid from s05 before well completion.\n' ...
                   'No fallback cell dimensions allowed - all values must come from YAML/simulator.'], ...
                   well.name, cell_idx);
        end
        
        % Convert to meters using CANON conversion factor
        if ~isfield(init_config.initialization, 'unit_conversions') || ~isfield(init_config.initialization.unit_conversions.length, 'ft_to_m')
            error(['CANON-FIRST ERROR: Missing ft_to_m conversion factor in initialization_config.yaml\n' ...
                   'UPDATE CANON: obsidian-vault/Planning/Initial_Conditions.md\n' ...
                   'Must define exact unit conversion factors for Eagle West Field.']);
        end
        ft_to_m = init_config.initialization.unit_conversions.length.ft_to_m;
        dx_m = dx * ft_to_m;
        dy_m = dy * ft_to_m;
        dz_m = dz * ft_to_m;
        
        % Peaceman equivalent radius
        r_eq = 0.28 * sqrt(sqrt((perm_y/perm_x) * dx_m^4 + (perm_x/perm_y) * dy_m^4) / ...
                           ((perm_y/perm_x)^0.5 + (perm_x/perm_y)^0.5));
        
        % Substep 3.4 - Calculate well index ________________________
        % Convert wellbore radius to meters using CANON conversion factor
        if ~isfield(init_config.initialization, 'unit_conversions') || ~isfield(init_config.initialization.unit_conversions.length, 'ft_to_m')
            error(['CANON-FIRST ERROR: Missing ft_to_m conversion factor in initialization_config.yaml\n' ...
                   'UPDATE CANON: obsidian-vault/Planning/Initial_Conditions.md\n' ...
                   'Must define exact unit conversion factors for Eagle West Field.']);
        end
        ft_to_m = init_config.initialization.unit_conversions.length.ft_to_m;
        rw = well.wellbore_radius * ft_to_m;  % CANON ft to m conversion
        skin = well.skin_factor;
        
        % Geometric factor based on well type
        switch well.well_type
            case 'vertical'
                geometric_factor = 1.0;
                effective_length = dz_m;
            case 'horizontal'
                geometric_factor = 1.5;  % Higher productivity
                effective_length = well.lateral_length * ft_to_m;  % CANON Convert to m
            case 'multi_lateral'
                geometric_factor = 2.2;  % Highest productivity
                effective_length = (well.lateral_1_length + well.lateral_2_length) * ft_to_m;  % CANON Convert to m
        end
        
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
        
        well_indices = [well_indices; wi];
        
        % Display well index calculation details (CANON-FIRST: Always show consistent output)
        fprintf('   ■ %s: WI=%.2e, Perm=[%.0f,%.0f,%.0f] mD, r_eq=%.3f m, skin=%.1f\n', ...
                wi.name, wi.well_index, wi.permeability_md(1), wi.permeability_md(2), wi.permeability_md(3), ...
                wi.equivalent_radius_m, wi.skin_factor);
    end
    
    % Display well indices table (CANON-FIRST: Always show detailed WI calculation results)
    fprintf('\n   WELL INDICES (PEACEMAN MODEL) CALCULATION RESULTS:\n');
    fprintf('   ┌─────────┬────────────┬────────────┬───────────┬──────────┬────────┐\n');
    fprintf('   │ Well    │ Well Index │ Perm (mD) │ r_eq (m)  │ Skin     │ Type   │\n');
    fprintf('   ├─────────┼────────────┼────────────┼───────────┼──────────┼────────┤\n');
    for i = 1:length(well_indices)
        wi = well_indices(i);
        fprintf('   │ %-7s │ %10.2e │ %9.0f  │ %9.3f  │ %8.1f │ %-6s │\n', ...
                wi.name, wi.well_index, wi.permeability_md(1), wi.equivalent_radius_m, wi.skin_factor, wi.well_type);
    end
    fprintf('   └─────────┴────────────┴────────────┴───────────┴──────────┴────────┘\n');
    
    fprintf(' ───────────────────────────────────────────────────────────\n');

end

function completion_intervals = step_4_define_completion_intervals(wells_data, G, wells_config)
% Step 4 - Define layer-specific completion intervals

    % Defining completion intervals by layer
    
    completion_intervals = struct();
    completion_intervals.layer_definitions = define_layer_intervals(wells_config);
    
    all_wells = [wells_data.producer_wells; wells_data.injector_wells];
    completion_intervals.wells = [];
    
    % Substep 4.1 - Define intervals for each well __________________
    for i = 1:length(all_wells)
        well = all_wells(i);
        
        ci = struct();
        ci.name = well.name;
        ci.type = well.type;
        ci.completion_layers = well.completion_layers;
        ci.intervals = [];
        
        % Substep 4.2 - Create intervals for each completed layer ____
        for j = 1:length(well.completion_layers)
            layer = well.completion_layers(j);
            
            interval = struct();
            interval.layer = layer;
            interval.layer_name = get_layer_name(layer);
            
            % Calculate depth interval using CANON configuration (CANON-FIRST)
            if ~isfield(wells_config.wells_system.completion_parameters, 'layer_completion_parameters')
                error(['CANON-FIRST ERROR: Missing layer_completion_parameters in wells_config.yaml\n' ...
                       'UPDATE CANON: obsidian-vault/Planning/Wells_Configuration.md\n' ...
                       'Must define exact layer offsets and thicknesses for Eagle West Field.\n' ...
                       'No hardcoded depth calculations allowed - all values must come from YAML specification.']);
            end
            layer_params = wells_config.wells_system.completion_parameters.layer_completion_parameters;
            
            base_depth = well.total_depth_tvd_ft;
            if layer <= 3
                % Upper Sand (layers 1-3)
                interval.top_depth_ft = base_depth - layer_params.upper_sand_offset_ft + (layer-1) * layer_params.layer_spacing_ft;
                interval.bottom_depth_ft = interval.top_depth_ft + layer_params.layer_thickness_ft;
            elseif layer <= 7
                % Middle Sand (layers 4-7)  
                interval.top_depth_ft = base_depth - layer_params.middle_sand_offset_ft + (layer-4) * layer_params.layer_spacing_ft;
                interval.bottom_depth_ft = interval.top_depth_ft + layer_params.layer_thickness_ft;
            else
                % Lower Sand (layers 8-12)
                interval.top_depth_ft = base_depth - layer_params.lower_sand_offset_ft + (layer-8) * layer_params.layer_spacing_ft;
                interval.bottom_depth_ft = interval.top_depth_ft + layer_params.layer_thickness_ft;
            end
            
            interval.net_pay_ft = interval.bottom_depth_ft - interval.top_depth_ft;
            
            ci.intervals = [ci.intervals; interval];
        end
        
        ci.total_net_pay_ft = sum([ci.intervals.net_pay_ft]);
        completion_intervals.wells = [completion_intervals.wells; ci];
        
        % Display completion intervals details (CANON-FIRST: Always show consistent output)
        fprintf('   ■ %s: %d layers, total pay: %.0f ft', ci.name, length(ci.intervals), ci.total_net_pay_ft);
        for k = 1:length(ci.intervals)
            fprintf(' [L%d:%.0f-%.0f ft]', ci.intervals(k).layer, ci.intervals(k).top_depth_ft, ci.intervals(k).bottom_depth_ft);
        end
        fprintf('\n');
    end
    
    % Display completion intervals table (CANON-FIRST: Always show layer completion details)
    fprintf('\n   COMPLETION INTERVALS BY LAYER:\n');
    fprintf('   ┌─────────┬─────────────┬───────────┬────────────┬──────────┐\n');
    fprintf('   │ Well    │ Sand Unit    │ Layers    │ Depth (ft)  │ Pay (ft) │\n');
    fprintf('   ├─────────┼─────────────┼───────────┼────────────┼──────────┤\n');
    for i = 1:length(completion_intervals.wells)
        ci = completion_intervals.wells(i);
        for j = 1:length(ci.intervals)
            interval = ci.intervals(j);
            if j == 1
                fprintf('   │ %-7s │ %-11s │ Layer %-2d │ %5.0f-%-5.0f │ %8.0f │\n', ...
                        ci.name, interval.layer_name, interval.layer, interval.top_depth_ft, interval.bottom_depth_ft, interval.net_pay_ft);
            else
                fprintf('   │         │ %-11s │ Layer %-2d │ %5.0f-%-5.0f │ %8.0f │\n', ...
                        interval.layer_name, interval.layer, interval.top_depth_ft, interval.bottom_depth_ft, interval.net_pay_ft);
            end
        end
        if length(ci.intervals) > 1
            fprintf('   ├─────────┼─────────────┼───────────┼────────────┼──────────┤\n');
            fprintf('   │ TOTAL   │             │ %d Layers │             │ %8.0f │\n', length(ci.intervals), ci.total_net_pay_ft);
        end
        if i < length(completion_intervals.wells)
            fprintf('   ├─────────┼─────────────┼───────────┼────────────┼──────────┤\n');
        end
    end
    fprintf('   └─────────┴─────────────┴───────────┴────────────┴──────────┘\n');
    
    fprintf(' ─────────────────────────────────────────────────────────────\n');
    
    % Substep 4.3 - Summary by sand interval _______________________
    completion_intervals.summary = calculate_completion_summary(completion_intervals.wells);

end

function layer_def = define_layer_intervals(wells_config)
% Define standard layer intervals using CANON rock properties configuration
    
    % Load rock properties configuration (CANON-FIRST)
    script_path = fileparts(mfilename('fullpath'));
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

function name = get_layer_name(layer)
% Get descriptive name for layer number
    if layer <= 3
        name = 'Upper Sand';
    elseif layer <= 7
        name = 'Middle Sand';
    else
        name = 'Lower Sand';
    end
end

function summary = calculate_completion_summary(wells)
% Calculate completion summary statistics
    summary = struct();
    
    % Count completions by sand interval
    upper_wells = 0; middle_wells = 0; lower_wells = 0;
    total_upper_pay = 0; total_middle_pay = 0; total_lower_pay = 0;
    
    for i = 1:length(wells)
        well = wells(i);
        for j = 1:length(well.intervals)
            interval = well.intervals(j);
            if interval.layer <= 3
                upper_wells = upper_wells + 1;
                total_upper_pay = total_upper_pay + interval.net_pay_ft;
            elseif interval.layer <= 7
                middle_wells = middle_wells + 1;
                total_middle_pay = total_middle_pay + interval.net_pay_ft;
            else
                lower_wells = lower_wells + 1;
                total_lower_pay = total_lower_pay + interval.net_pay_ft;
            end
        end
    end
    
    summary.upper_sand_completions = upper_wells;
    summary.middle_sand_completions = middle_wells;
    summary.lower_sand_completions = lower_wells;
    summary.total_upper_pay_ft = total_upper_pay;
    summary.total_middle_pay_ft = total_middle_pay;
    summary.total_lower_pay_ft = total_lower_pay;
    summary.total_completion_length_ft = total_upper_pay + total_middle_pay + total_lower_pay;

end

function mrst_wells = step_5_create_mrst_wells(wells_data, well_indices, G, init_config, wells_config)
% Step 5 - Create MRST-compatible well structures

    % Creating MRST-compatible well structures
    
    mrst_wells = [];
    all_wells = [wells_data.producer_wells; wells_data.injector_wells];
    
    % Substep 5.1 - Create well structures for MRST _________________
    for i = 1:length(all_wells)
        well = all_wells(i);
        wi = well_indices(i);
        
        mwell = struct();
        mwell.name = well.name;
        mwell.type = well.type;  % 'producer' or 'injector'
        
        % Well location and completion
        mwell.cells = well.cell_index;
        mwell.WI = wi.well_index;  % Well index from Peaceman calculation
        mwell.dir = 'z';  % Default direction
        mwell.r = wi.wellbore_radius_m;
        mwell.skin = wi.skin_factor;
        
        % Add completion layers if multiple
        if length(well.completion_layers) > 1
            completion_cells = [];
            completion_WI = [];
            
            % For PEBI grids, find cells at different z-levels near the well
            well_xy = G.cells.centroids(well.cell_index, 1:2);
            z_min = min(G.cells.centroids(:,3));
            z_max = max(G.cells.centroids(:,3));
            
            for j = 1:length(well.completion_layers)
                layer = well.completion_layers(j);
                % Calculate target z-coordinate for this layer
                target_z = z_min + (layer - 1) * (z_max - z_min) / 11;  % 12 layers, 0-indexed
                
                % Find cells near well location at target z
                xy_distances = sqrt((G.cells.centroids(:,1) - well_xy(1)).^2 + ...
                                  (G.cells.centroids(:,2) - well_xy(2)).^2);
                z_distances = abs(G.cells.centroids(:,3) - target_z);
                
                % Find closest cell considering both xy and z distance
                combined_distance = xy_distances + 10 * z_distances;  % Weight z-distance more
                [~, cell_idx] = min(combined_distance);
                
                % CANON-FIRST validation: ensure cell index is valid
                if cell_idx <= G.cells.num && cell_idx >= 1
                    completion_cells = [completion_cells; cell_idx];
                    completion_WI = [completion_WI; wi.well_index / length(well.completion_layers)];
                else
                    error(['CANON-FIRST ERROR: Invalid cell index %d for well %s layer %d (grid has %d cells)\n' ...
                           'UPDATE CANON: obsidian-vault/Planning/Well_Completion_Logic.md\n' ...
                           'Multi-layer completion algorithm generated invalid cell index.'], ...
                           cell_idx, well.name, j, G.cells.num);
                end
            end
            mwell.cells = completion_cells;
            mwell.WI = completion_WI;
        end
        
        % Initialize all possible control fields for consistency
        mwell.target_rate = 0;
        
        % Set pressure limits (CANON-FIRST - must come from YAML configuration)
        if ~isfield(well, 'min_bhp_psi') || ~isfield(well, 'max_bhp_psi')
            error(['CANON-FIRST ERROR: Missing BHP limits for well %s\n' ...
                   'UPDATE CANON: obsidian-vault/Planning/Wells_Configuration.md\n' ...
                   'Must define exact min_bhp_psi/max_bhp_psi in wells_config.yaml for Eagle West Field.\n' ...
                   'No default pressure limits allowed - all values must be domain-specific.'], well.name);
        end
        
        % Convert pressure using CANON conversion factor
        if ~isfield(init_config.initialization, 'unit_conversions') || ~isfield(init_config.initialization.unit_conversions.pressure, 'psi_to_pa')
            error(['CANON-FIRST ERROR: Missing psi_to_pa conversion factor in initialization_config.yaml\n' ...
                   'UPDATE CANON: obsidian-vault/Planning/Initial_Conditions.md\n' ...
                   'Must define exact unit conversion factors for Eagle West Field.']);
        end
        psi_to_pa = init_config.initialization.unit_conversions.pressure.psi_to_pa;
        mwell.min_bhp = well.min_bhp_psi * psi_to_pa;  % CANON conversion
        mwell.max_bhp = well.max_bhp_psi * psi_to_pa;  % CANON conversion
        
        % Well controls (will be detailed in s18)
        % Extract volume conversion factor (CANON-FIRST)
        if ~isfield(init_config.initialization, 'unit_conversions') || ~isfield(init_config.initialization.unit_conversions.volume, 'bbl_to_m3')
            error(['CANON-FIRST ERROR: Missing bbl_to_m3 conversion factor in initialization_config.yaml\n' ...
                   'UPDATE CANON: obsidian-vault/Planning/Initial_Conditions.md\n' ...
                   'Must define exact unit conversion factors for Eagle West Field.']);
        end
        bbl_to_m3 = init_config.initialization.unit_conversions.volume.bbl_to_m3;
        
        if strcmp(well.type, 'producer')
            mwell.target_rate = well.target_oil_rate * bbl_to_m3;  % CANON STB/day to m³/day conversion
        else
            mwell.target_rate = well.target_injection_rate * bbl_to_m3;  % CANON BBL/day to m³/day conversion
        end
        
        mrst_wells = [mrst_wells; mwell];
        
        % Display MRST well structure details (CANON-FIRST: Always show consistent output)
        fprintf('   ■ %s: MRST well (cells: %d, WI: %.2e, BHP: %.0f-%.0f psi, rate: %.0f m³/day)\n', ...
                mwell.name, length(mwell.cells), mean(mwell.WI), mwell.min_bhp/6895, mwell.max_bhp/6895, mwell.target_rate);
    end
    
    % Substep 5.2 - Add required MRST well control fields _______________
    % CRITICAL FIX: Add missing val and sign fields for MRST well flow calculations
    % Wells have target_rate but MRST requires val and sign for proper flow calculation
    for i = 1:length(mrst_wells)
        % Set rate control value from target_rate
        mrst_wells(i).val = mrst_wells(i).target_rate;
        
        % Set well control sign and type based on well type
        if strcmp(mrst_wells(i).type, 'producer')
            mrst_wells(i).sign = 1;     % Positive for producers (fluid out)
            mrst_wells(i).type = 'rate'; % Rate-controlled well
        elseif strcmp(mrst_wells(i).type, 'injector')
            mrst_wells(i).sign = -1;    % Negative for injectors (fluid in)
            mrst_wells(i).type = 'rate'; % Rate-controlled well
        end
        
        % MRST well control validation
        fprintf('   ■ %s: MRST controls (val: %.2f m³/day, sign: %d, type: %s)\n', ...
                mrst_wells(i).name, mrst_wells(i).val, mrst_wells(i).sign, mrst_wells(i).type);
    end
    
    % Display MRST wells summary table (CANON-FIRST: Always show MRST structure details)
    fprintf('\n   MRST WELL STRUCTURES SUMMARY:\n');
    fprintf('   ┌─────────┬──────────┬─────────┬────────────┬────────────┬────────────┐\n');
    fprintf('   │ Well    │ Type     │ Cells   │ Well Index │ BHP Range  │ Rate       │\n');
    fprintf('   │         │          │         │            │ (psi)      │ (m³/day)   │\n');
    fprintf('   ├─────────┼──────────┼─────────┼────────────┼────────────┼────────────┤\n');
    for i = 1:length(mrst_wells)
        mwell = mrst_wells(i);
        bhp_min_psi = mwell.min_bhp / 6895;  % Pa to psi
        bhp_max_psi = mwell.max_bhp / 6895;  % Pa to psi
        fprintf('   │ %-7s │ %-8s │ %7d │ %10.2e │ %4.0f-%4.0f │ %10.0f │\n', ...
                mwell.name, mwell.type, length(mwell.cells), mean(mwell.WI), bhp_min_psi, bhp_max_psi, mwell.target_rate);
    end
    fprintf('   └─────────┴──────────┴─────────┴────────────┴────────────┴────────────┘\n');
    
    fprintf(' ───────────────────────────────────────────────────────────\n');

end

function export_path = step_6_export_completion_data(completion_results)
% Step 6 - Export completion design data

    script_path = fileparts(mfilename('fullpath'));
    if isempty(script_path)
        script_path = pwd();
    end
    data_dir = get_data_path('static');
    
    if ~exist(data_dir, 'dir')
        mkdir(data_dir);
    end
    
    % Substep 6.1 - Save to canonical by_type structure (CANON-FIRST)
    base_data_path = fullfile(fileparts(fileparts(mfilename('fullpath'))), 'data');
    canonical_static_path = fullfile(base_data_path, 'by_type', 'static');
    if ~exist(canonical_static_path, 'dir')
        mkdir(canonical_static_path);
    end
    
    % Primary canonical data file
    export_path = fullfile(canonical_static_path, 'well_completions_s16.mat');
    save(export_path, 'completion_results');
    % Canonical data saved successfully
    
    % CANON-FIRST: No legacy compatibility saves allowed
    % Data must be accessed from canonical by_type/static structure only
    
    % Substep 6.2 - Create completion summary (CANONICAL NAMING)
    summary_file = fullfile(canonical_static_path, 'completion_summary_s16.txt');
    write_completion_summary_file(summary_file, completion_results);
    
    % Substep 6.3 - Create well indices table (CANONICAL NAMING)
    wi_file = fullfile(canonical_static_path, 'well_indices_s16.txt');
    write_well_indices_file(wi_file, completion_results);
    
    % Export completed to canonical locations

end

function write_completion_summary_file(filename, completion_results)
% Write completion design summary to file

    fid = fopen(filename, 'w');
    if fid == -1
        error('Cannot open file for writing: %s', filename);
    end
    
    try
        fprintf(fid, 'Eagle West Field - Well Completion Summary\n');
        fprintf(fid, 'Generated: %s\n', datestr(now));
        fprintf(fid, '==========================================\n\n');
        
        % Wellbore design summary
        fprintf(fid, 'WELLBORE DESIGN:\n');
        fprintf(fid, '  Standard Radius: %.1f m (%.2f ft)\n', ...
            completion_results.wellbore_design.standard_radius_m, ...
            completion_results.wellbore_design.standard_radius_ft);
        
        stats = completion_results.wellbore_design.statistics;
        fprintf(fid, '  Vertical Wells: %d\n', stats.vertical_count);
        fprintf(fid, '  Horizontal Wells: %d\n', stats.horizontal_count);
        fprintf(fid, '  Multi-lateral Wells: %d\n', stats.multilateral_count);
        fprintf(fid, '  Skin Factor Range: %.1f to %.1f\n', stats.skin_factor_min, stats.skin_factor_max);
        fprintf(fid, '  Total Completion Length: %.0f ft\n\n', stats.total_completion_length_ft);
        
        % Well indices summary
        fprintf(fid, 'WELL INDICES (Peaceman Model):\n');
        fprintf(fid, '%-8s %-10s %-12s %-10s %-8s\n', ...
            'Well', 'Type', 'Well_Index', 'Perm_mD', 'Skin');
        fprintf(fid, '%s\n', repmat('-', 1, 60));
        
        for i = 1:length(completion_results.well_indices)
            wi = completion_results.well_indices(i);
            fprintf(fid, '%-8s %-10s %-12.2e %-10.0f %-8.1f\n', ...
                wi.name, wi.type, wi.well_index, wi.permeability_md(1), wi.skin_factor);
        end
        
        fprintf(fid, '\n');
        
        % Completion intervals summary
        if isfield(completion_results, 'completion_intervals')
            ci = completion_results.completion_intervals;
            fprintf(fid, 'COMPLETION INTERVALS:\n');
            fprintf(fid, '  Upper Sand Completions: %d (%.0f ft total)\n', ...
                ci.summary.upper_sand_completions, ci.summary.total_upper_pay_ft);
            fprintf(fid, '  Middle Sand Completions: %d (%.0f ft total)\n', ...
                ci.summary.middle_sand_completions, ci.summary.total_middle_pay_ft);
            fprintf(fid, '  Lower Sand Completions: %d (%.0f ft total)\n', ...
                ci.summary.lower_sand_completions, ci.summary.total_lower_pay_ft);
            fprintf(fid, '  Total Completion Length: %.0f ft\n', ...
                ci.summary.total_completion_length_ft);
        end
        
        fclose(fid);
        
    catch ME
        fclose(fid);
        error('Error writing completion summary: %s', ME.message);
    end

end

function write_well_indices_file(filename, completion_results)
% Write well indices data in CSV format

    fid = fopen(filename, 'w');
    if fid == -1
        error('Cannot open file for writing: %s', filename);
    end
    
    try
        % CSV header
        fprintf(fid, 'Well_Name,Type,Well_Type,Well_Index,Perm_X_mD,Perm_Y_mD,Perm_Z_mD,Equivalent_Radius_m,Wellbore_Radius_m,Skin_Factor\n');
        
        % Well indices data
        for i = 1:length(completion_results.well_indices)
            wi = completion_results.well_indices(i);
            fprintf(fid, '%s,%s,%s,%.6e,%.1f,%.1f,%.1f,%.4f,%.4f,%.2f\n', ...
                wi.name, wi.type, wi.well_type, wi.well_index, ...
                wi.permeability_md(1), wi.permeability_md(2), wi.permeability_md(3), ...
                wi.equivalent_radius_m, wi.wellbore_radius_m, wi.skin_factor);
        end
        
        fclose(fid);
        
    catch ME
        fclose(fid);
        error('Error writing well indices file: %s', ME.message);
    end

end

% Main execution when called as script
if ~nargout
    completion_results = s16_well_completions();
end