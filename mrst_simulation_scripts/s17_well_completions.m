function completion_results = s17_well_completions()
% S17_WELL_COMPLETIONS - Well Completion Design for Eagle West Field
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
    print_step_header('S17', 'Well Completion Design');
    
    total_start_time = tic;
    completion_results = initialize_completion_structure();
    
    try
        % ----------------------------------------
        % Step 1 - Load Wells and Rock Properties
        % ----------------------------------------
        step_start = tic;
        [wells_data, rock_props, G] = step_1_load_wells_and_properties();
        completion_results.wells_data = wells_data;
        completion_results.rock_props = rock_props;
        print_step_result(1, 'Load Wells and Properties', 'success', toc(step_start));
        
        % ----------------------------------------
        % Step 2 - Design Wellbore Completions
        % ----------------------------------------
        step_start = tic;
        wellbore_design = step_2_design_wellbore_completions(wells_data);
        completion_results.wellbore_design = wellbore_design;
        print_step_result(2, 'Design Wellbore Completions', 'success', toc(step_start));
        
        % ----------------------------------------
        % Step 3 - Calculate Well Indices (Peaceman)
        % ----------------------------------------
        step_start = tic;
        well_indices = step_3_calculate_well_indices(wells_data, rock_props, G);
        completion_results.well_indices = well_indices;
        print_step_result(3, 'Calculate Well Indices', 'success', toc(step_start));
        
        % ----------------------------------------
        % Step 4 - Define Completion Intervals
        % ----------------------------------------
        step_start = tic;
        completion_intervals = step_4_define_completion_intervals(wells_data, G);
        completion_results.completion_intervals = completion_intervals;
        print_step_result(4, 'Define Completion Intervals', 'success', toc(step_start));
        
        % ----------------------------------------
        % Step 5 - Create MRST Well Structures
        % ----------------------------------------
        step_start = tic;
        mrst_wells = step_5_create_mrst_wells(wells_data, well_indices, G);
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
        
        print_step_footer('S17', sprintf('Well Completions Designed (%d wells)', ...
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

function [wells_data, rock_props, G] = step_1_load_wells_and_properties()
% Step 1 - Load well placement and rock properties data

    script_path = fileparts(mfilename('fullpath'));
    if isempty(script_path)
        script_path = pwd();
    end
    data_dir = get_data_path('static');
    
    % Substep 1.1 - Load well placement data ________________________
    well_file = fullfile(data_dir, 'well_placement.mat');
    if exist(well_file, 'file')
        load(well_file, 'wells_results');
        wells_data = wells_results;
        fprintf('Loaded well placement: %d wells\n', wells_data.total_wells);
    else
        error('Well placement file not found. Run s16_well_placement.m first.');
    end
    
    % Substep 1.2 - Load rock properties ___________________________
    % Try multiple possible rock properties files
    rock_files = {'final_simulation_rock.mat', 'enhanced_rock_with_layers.mat', 'native_rock_properties.mat'};
    rock_props = [];
    
    for i = 1:length(rock_files)
        rock_file = fullfile(data_dir, rock_files{i});
        if exist(rock_file, 'file')
            try
                load(rock_file);
                
                % Check for different rock property variables
                if exist('final_rock', 'var')
                    rock_props = final_rock;
                    fprintf('Loaded rock properties from %s: %d cells\n', rock_files{i}, length(rock_props.poro));
                    % Check if grid is also in this file
                    if exist('G', 'var')
                        grid_from_rock_file = G;
                        fprintf('Also found grid in %s: %d cells\n', rock_files{i}, G.cells.num);
                    end
                    break;
                elseif exist('rock_enhanced', 'var')
                    rock_props = rock_enhanced;
                    fprintf('Loaded rock properties from %s: %d cells\n', rock_files{i}, length(rock_props.poro));
                    break;
                elseif exist('rock', 'var')
                    rock_props = rock;
                    fprintf('Loaded rock properties from %s: %d cells\n', rock_files{i}, length(rock_props.poro));
                    break;
                elseif exist('rock_props', 'var')
                    fprintf('Loaded rock properties from %s: %d cells\n', rock_files{i}, length(rock_props.poro));
                    break;
                else
                    fprintf('File %s exists but contains no recognized rock properties variable\n', rock_files{i});
                end
            catch ME
                fprintf('Error loading %s: %s\n', rock_files{i}, ME.message);
            end
        end
    end
    
    if isempty(rock_props)
        error('Rock properties file not found. Run rock property scripts first.');
    end
    
    % Substep 1.3 - Load grid structure ____________________________
    % First check if we already loaded grid with rock properties
    if exist('grid_from_rock_file', 'var')
        G = grid_from_rock_file;
        fprintf('Using grid from rock file: %d cells\n', G.cells.num);
    else
        % Try separate grid files
        refined_grid_file = fullfile(data_dir, 'refined_grid.mat');
        base_grid_file = fullfile(data_dir, 'base_grid.mat');
        
        if exist(refined_grid_file, 'file')
            data = load(refined_grid_file);
            if isfield(data, 'G_refined')
                G = data.G_refined;
            elseif isfield(data, 'G')
                G = data.G;
            else
                error('No grid structure found in refined_grid.mat');
            end
            fprintf('Loaded refined grid: %d cells\n', G.cells.num);
        elseif exist(base_grid_file, 'file')
            data = load(base_grid_file);
            if isfield(data, 'G')
                G = data.G;
            else
                error('No grid structure found in base_grid.mat');
            end
            fprintf('Loaded base grid: %d cells\n', G.cells.num);
        else
            error('Grid structure file not found. Run grid creation scripts first.');
        end
    end

end

function wellbore_design = step_2_design_wellbore_completions(wells_data)
% Step 2 - Design wellbore completions for all wells

    wellbore_design = struct();
    
    fprintf('\n Wellbore Completion Design:\n');
    fprintf(' ─────────────────────────────────────────────────────────\n');
    
    all_wells = [wells_data.producer_wells; wells_data.injector_wells];
    
    % Substep 2.1 - Standard wellbore parameters ___________________
    wellbore_design.standard_radius_m = 0.1;  % 6-inch wellbore
    wellbore_design.standard_radius_ft = 0.328;
    
    % Substep 2.2 - Design completions for each well _______________
    wellbore_design.wells = [];
    
    for i = 1:length(all_wells)
        well = all_wells(i);
        
        wb = struct();
        wb.name = well.name;
        wb.type = well.type;
        wb.well_type = well.well_type;
        
        % Wellbore geometry
        wb.radius_m = 0.1;  % Standard 6-inch
        wb.radius_ft = well.wellbore_radius;
        wb.skin_factor = well.skin_factor;
        
        % Completion design based on well type
        switch well.well_type
            case 'vertical'
                wb = design_vertical_completion(wb, well);
            case 'horizontal'
                wb = design_horizontal_completion(wb, well);
            case 'multi_lateral'
                wb = design_multilateral_completion(wb, well);
        end
        
        wellbore_design.wells = [wellbore_design.wells; wb];
        
        fprintf('   %-8s │ %-12s │ R=%.3fm │ S=%+5.1f │ %d layers\n', ...
            wb.name, wb.well_type, wb.radius_m, wb.skin_factor, length(wb.completion_layers));
    end
    
    fprintf(' ─────────────────────────────────────────────────────────\n');
    
    % Substep 2.3 - Completion statistics __________________________
    wellbore_design.statistics = calculate_completion_statistics(wellbore_design.wells);

end

function wb = design_vertical_completion(wb, well)
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
    
    % Perforation design
    wb.perforation_density = 12;  % shots per foot
    wb.perforation_diameter = 0.43;  % inches
    wb.perforation_penetration = 12;  % inches
    
    % Completion intervals (assume 30 ft per layer)
    wb.completion_length_ft = length(well.completion_layers) * 30;
    
    % Sand control for vertical wells
    wb.sand_control = 'gravel_pack';
    wb.screen_type = 'slotted_liner';

end

function wb = design_horizontal_completion(wb, well)
% Design horizontal well completion

    wb.trajectory = 'horizontal';
    wb.completion_type = 'openhole_completion';
    wb.completion_layers = well.completion_layers;
    
    % Lateral specifications
    wb.lateral_length_ft = well.lateral_length;
    wb.lateral_tvd = well.total_depth_tvd_ft;
    
    % Multi-stage completion
    wb.completion_stages = ceil(wb.lateral_length_ft / 250);  % ~250 ft per stage
    wb.stage_length_ft = wb.lateral_length_ft / wb.completion_stages;
    
    % Multi-lateral fields (initialized for horizontal wells)
    wb.lateral_1_length_ft = wb.lateral_length_ft;  % Single lateral
    wb.lateral_2_length_ft = 0;
    wb.junction_type = 'none';
    wb.lateral_1_stages = wb.completion_stages;
    wb.lateral_2_stages = 0;
    wb.total_stages = wb.completion_stages;
    
    % Perforation design for horizontals
    wb.perforation_density = 6;  % shots per foot (fewer for horizontals)
    wb.perforation_diameter = 0.50;  % larger holes
    wb.perforation_penetration = 18;  % inches
    
    % Sand control for horizontal wells
    wb.sand_control = 'premium_screens';
    wb.screen_type = 'wire_wrap_screen';
    
    wb.completion_length_ft = wb.lateral_length_ft;

end

function wb = design_multilateral_completion(wb, well)
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
    
    % Multi-stage completion for each lateral
    wb.lateral_1_stages = ceil(wb.lateral_1_length_ft / 200);
    wb.lateral_2_stages = ceil(wb.lateral_2_length_ft / 200);
    wb.total_stages = wb.lateral_1_stages + wb.lateral_2_stages;
    wb.completion_stages = wb.total_stages;  % For consistency with horizontal
    wb.stage_length_ft = wb.lateral_length_ft / wb.total_stages;
    
    % Perforation design
    wb.perforation_density = 8;  % moderate density
    wb.perforation_diameter = 0.47;
    wb.perforation_penetration = 15;
    
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

function well_indices = step_3_calculate_well_indices(wells_data, rock_props, G)
% Step 3 - Calculate well indices using Peaceman model

    fprintf('\n Calculating Well Indices (Peaceman Model):\n');
    fprintf(' ───────────────────────────────────────────────────────────\n');
    
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
        if isfield(rock_props, 'permeability') && length(rock_props.permeability) >= cell_idx
            perm_x = rock_props.permeability(cell_idx, 1) * 1000;  % Convert to mD
            perm_y = rock_props.permeability(cell_idx, 2) * 1000;
            perm_z = rock_props.permeability(cell_idx, 3) * 1000;
        else
            % Default permeabilities by layer
            layer_k = well.completion_layers(1);
            if layer_k <= 3
                perm_x = 200; perm_y = 180; perm_z = 20;  % Upper sand
            elseif layer_k <= 7
                perm_x = 150; perm_y = 130; perm_z = 15;  % Middle sand
            else
                perm_x = 100; perm_y = 90; perm_z = 10;   % Lower sand
            end
        end
        
        % Substep 3.3 - Calculate equivalent radius (Peaceman) ________
        if cell_idx <= G.cells.num
            dx = G.cells.volumes(cell_idx)^(1/3);  % Approximate cell size
            dy = dx;
            dz = dx;
        else
            dx = 135; dy = 135; dz = 15;  % Default cell dimensions (ft)
        end
        
        % Convert to meters for calculation
        dx_m = dx * 0.3048;
        dy_m = dy * 0.3048;
        dz_m = dz * 0.3048;
        
        % Peaceman equivalent radius
        r_eq = 0.28 * sqrt(sqrt((perm_y/perm_x) * dx_m^4 + (perm_x/perm_y) * dy_m^4) / ...
                           ((perm_y/perm_x)^0.5 + (perm_x/perm_y)^0.5));
        
        % Substep 3.4 - Calculate well index ________________________
        rw = well.wellbore_radius * 0.3048;  % Convert ft to m
        skin = well.skin_factor;
        
        % Geometric factor based on well type
        switch well.well_type
            case 'vertical'
                geometric_factor = 1.0;
                effective_length = dz_m;
            case 'horizontal'
                geometric_factor = 1.5;  % Higher productivity
                effective_length = well.lateral_length * 0.3048;  % Convert to m
            case 'multi_lateral'
                geometric_factor = 2.2;  % Highest productivity
                effective_length = (well.lateral_1_length + well.lateral_2_length) * 0.3048;
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
        
        fprintf('   %-8s │ WI=%.2e │ r_eq=%.2f │ perm=%.0f mD\n', ...
            wi.name, wi.well_index, wi.equivalent_radius_m, perm_x);
    end
    
    fprintf(' ───────────────────────────────────────────────────────────\n');

end

function completion_intervals = step_4_define_completion_intervals(wells_data, G)
% Step 4 - Define layer-specific completion intervals

    fprintf('\n Completion Intervals by Layer:\n');
    fprintf(' ─────────────────────────────────────────────────────────────\n');
    
    completion_intervals = struct();
    completion_intervals.layer_definitions = define_layer_intervals();
    
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
            
            % Calculate depth interval for this layer
            base_depth = well.total_depth_tvd_ft;
            if layer <= 3
                % Upper Sand (layers 1-3)
                interval.top_depth_ft = base_depth - 250 + (layer-1) * 30;
                interval.bottom_depth_ft = interval.top_depth_ft + 25;
            elseif layer <= 7
                % Middle Sand (layers 4-7)  
                interval.top_depth_ft = base_depth - 150 + (layer-4) * 30;
                interval.bottom_depth_ft = interval.top_depth_ft + 25;
            else
                % Lower Sand (layers 8-12)
                interval.top_depth_ft = base_depth - 50 + (layer-8) * 30;
                interval.bottom_depth_ft = interval.top_depth_ft + 25;
            end
            
            interval.net_pay_ft = interval.bottom_depth_ft - interval.top_depth_ft;
            
            ci.intervals = [ci.intervals; interval];
        end
        
        ci.total_net_pay_ft = sum([ci.intervals.net_pay_ft]);
        completion_intervals.wells = [completion_intervals.wells; ci];
        
        fprintf('   %-8s │ %d layers │ %.0f ft net pay │ %s\n', ...
            ci.name, length(ci.intervals), ci.total_net_pay_ft, ...
            strjoin({ci.intervals.layer_name}, ', '));
    end
    
    fprintf(' ─────────────────────────────────────────────────────────────\n');
    
    % Substep 4.3 - Summary by sand interval _______________________
    completion_intervals.summary = calculate_completion_summary(completion_intervals.wells);

end

function layer_def = define_layer_intervals()
% Define standard layer intervals
    layer_def = struct();
    layer_def.upper_sand = struct('layers', [1, 2, 3], 'name', 'Upper Sand', 'avg_perm_md', 200);
    layer_def.middle_sand = struct('layers', [4, 5, 6, 7], 'name', 'Middle Sand', 'avg_perm_md', 150);
    layer_def.lower_sand = struct('layers', [8, 9, 10, 11, 12], 'name', 'Lower Sand', 'avg_perm_md', 100);
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

function mrst_wells = step_5_create_mrst_wells(wells_data, well_indices, G)
% Step 5 - Create MRST-compatible well structures

    fprintf('\n Creating MRST Well Structures:\n');
    fprintf(' ───────────────────────────────────────────────────────────\n');
    
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
            for j = 1:length(well.completion_layers)
                layer = well.completion_layers(j);
                % Calculate cell index for this layer
                [I, J, K] = ind2sub(G.cartDims, well.cell_index);
                cell_idx = sub2ind(G.cartDims, I, J, layer);
                if cell_idx <= G.cells.num
                    completion_cells = [completion_cells; cell_idx];
                    completion_WI = [completion_WI; wi.well_index / length(well.completion_layers)];
                end
            end
            mwell.cells = completion_cells;
            mwell.WI = completion_WI;
        end
        
        % Initialize all possible control fields for consistency
        mwell.target_rate = 0;
        mwell.min_bhp = 1000 * 6895;  % Default minimum BHP in Pa
        mwell.max_bhp = 3000 * 6895;  % Default maximum BHP in Pa
        
        % Well controls (will be detailed in s18)
        if strcmp(well.type, 'producer')
            mwell.target_rate = well.target_oil_rate * 0.159;  % Convert STB/day to m³/day
            mwell.min_bhp = well.min_bhp_psi * 6895;  % Convert psi to Pa
        else
            mwell.target_rate = well.target_injection_rate * 0.159;  % Convert BBL/day to m³/day  
            mwell.max_bhp = well.max_bhp_psi * 6895;  % Convert psi to Pa
        end
        
        mrst_wells = [mrst_wells; mwell];
        
        fprintf('   %-8s │ %-9s │ %d cells │ WI=%.2e\n', ...
            mwell.name, mwell.type, length(mwell.cells), mean(mwell.WI));
    end
    
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
    
    % Substep 6.1 - Save MATLAB structure __________________________
    export_path = fullfile(data_dir, 'well_completions.mat');
    save(export_path, 'completion_results');
    
    % Substep 6.2 - Create completion summary ______________________
    summary_file = fullfile(data_dir, 'completion_summary.txt');
    write_completion_summary_file(summary_file, completion_results);
    
    % Substep 6.3 - Create well indices table ______________________
    wi_file = fullfile(data_dir, 'well_indices.txt');
    write_well_indices_file(wi_file, completion_results);
    
    fprintf('   Exported to: %s\n', export_path);
    fprintf('   Summary: %s\n', summary_file);
    fprintf('   Well Indices: %s\n', wi_file);

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
    completion_results = s17_well_completions();
end