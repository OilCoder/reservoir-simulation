function wells_results = s16_well_placement()
% S16_WELL_PLACEMENT - 15-Well System Placement for Eagle West Field
% Requires: MRST
%
% Creates 15 wells (10 producers + 5 injectors) with strategic placement:
% - Mixed well types: vertical, horizontal, multi-lateral
% - Grid locations per canonical documentation  
% - Well trajectories and target depths
% - YAML configuration integration
%
% OUTPUTS:
%   wells_results - Structure with well placement results
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
    print_step_header('S16', 'Well System Placement - 15 Wells');
    
    total_start_time = tic;
    wells_results = initialize_wells_structure();
    
    try
        % ----------------------------------------
        % Step 1 - Load Configuration and Grid
        % ----------------------------------------
        step_start = tic;
        [config, G] = step_1_load_config_and_grid();
        wells_results.config = config;
        wells_results.G = G;
        print_step_result(1, 'Load Configuration and Grid', 'success', toc(step_start));
        
        % ----------------------------------------
        % Step 2 - Create Producer Wells (10)
        % ----------------------------------------
        step_start = tic;
        producer_wells = step_2_create_producer_wells(config, G);
        wells_results.producer_wells = producer_wells;
        print_step_result(2, 'Create Producer Wells', 'success', toc(step_start));
        
        % ----------------------------------------
        % Step 3 - Create Injector Wells (5)
        % ----------------------------------------
        step_start = tic;
        injector_wells = step_3_create_injector_wells(config, G);
        wells_results.injector_wells = injector_wells;
        print_step_result(3, 'Create Injector Wells', 'success', toc(step_start));
        
        % ----------------------------------------
        % Step 4 - Validate Well Locations
        % ----------------------------------------
        step_start = tic;
        validation_results = step_4_validate_well_locations(wells_results, G);
        wells_results.validation = validation_results;
        print_step_result(4, 'Validate Well Locations', 'success', toc(step_start));
        
        % ----------------------------------------
        % Step 5 - Export Well Placement Data
        % ----------------------------------------
        step_start = tic;
        wells_results.status = 'success';
        wells_results.total_wells = length(producer_wells) + length(injector_wells);
        export_path = step_5_export_well_data(wells_results);
        wells_results.export_path = export_path;
        print_step_result(5, 'Export Well Placement Data', 'success', toc(step_start));
        wells_results.creation_time = datestr(now);
        
        print_step_footer('S16', sprintf('15-Well System Placed (%d producers + %d injectors)', ...
            length(producer_wells), length(injector_wells)), toc(total_start_time));
        
    catch ME
        print_error_step(0, 'Well Placement', ME.message);
        wells_results.status = 'failed';
        wells_results.error_message = ME.message;
        error('Well placement failed: %s', ME.message);
    end

end

function wells_results = initialize_wells_structure()
% Initialize well placement results structure
    wells_results = struct();
    wells_results.status = 'initializing';
    wells_results.producer_wells = [];
    wells_results.injector_wells = [];
    wells_results.total_wells = 0;
end

function [config, G] = step_1_load_config_and_grid()
% Step 1 - Load YAML configuration and grid structure
    script_dir = fileparts(mfilename('fullpath'));

    % Substep 1.1 - Load YAML configuration ________________________
    script_path = fileparts(mfilename('fullpath'));
    config_path = fullfile(script_path, 'config', 'wells_config.yaml');
    
    if ~exist(config_path, 'file')
        error('Wells configuration file not found: %s', config_path);
    end
    
    % Load YAML using working parser
        addpath(fullfile(script_dir, 'utils'));
    config = read_yaml_config(config_path);
    
    % Substep 1.2 - Load grid structure _____________________________
    data_dir = get_data_path('static');
    
    % Try refined grid first, then base grid
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
        fprintf('Refined grid loaded: %d cells, %d faces\n', G.cells.num, G.faces.num);
    elseif exist(base_grid_file, 'file')
        data = load(base_grid_file);
        if isfield(data, 'G')
            G = data.G;
        else
            error('No grid structure found in base_grid.mat');
        end
        fprintf('Base grid loaded: %d cells, %d faces\n', G.cells.num, G.faces.num);
    else
        error('Grid file not found. Run grid creation scripts first.');
    end

end

function producer_wells = step_2_create_producer_wells(config, G)
% Step 2 - Create 10 producer wells with mixed well types

    producer_wells = [];
    producers_config = config.wells_system.producer_wells;
    producer_names = fieldnames(producers_config);
    
    fprintf('\n Creating %d Producer Wells:\n', length(producer_names));
    fprintf(' ─────────────────────────────────────────────────\n');
    
    for i = 1:length(producer_names)
        well_name = producer_names{i};
        well_config = producers_config.(well_name);
        
        % Substep 2.1 - Create basic well structure __________________
        well = create_well_structure(well_name, 'producer', well_config, G);
        
        % Substep 2.2 - Add producer-specific properties _____________
        well = add_producer_properties(well, well_config);
        
        % Substep 2.3 - Handle well type specific geometry ___________
        well = add_well_geometry(well, well_config, G);
        
        producer_wells = [producer_wells; well];
        
        fprintf('   %-8s │ %-12s │ [%2d,%2d] │ %4d ft TVD\n', ...
            well_name, well_config.well_type, ...
            well_config.grid_location(1), well_config.grid_location(2), ...
            well_config.total_depth_tvd_ft);
    end
    
    fprintf(' ─────────────────────────────────────────────────\n');

end

function injector_wells = step_3_create_injector_wells(config, G)
% Step 3 - Create 5 injector wells for pressure support

    injector_wells = [];
    injectors_config = config.wells_system.injector_wells;
    injector_names = fieldnames(injectors_config);
    
    fprintf('\n Creating %d Injector Wells:\n', length(injector_names));
    fprintf(' ─────────────────────────────────────────────────\n');
    
    for i = 1:length(injector_names)
        well_name = injector_names{i};
        well_config = injectors_config.(well_name);
        
        % Substep 3.1 - Create basic well structure __________________
        well = create_well_structure(well_name, 'injector', well_config, G);
        
        % Substep 3.2 - Add injector-specific properties _____________
        well = add_injector_properties(well, well_config);
        
        % Substep 3.3 - Handle well type specific geometry ___________
        well = add_well_geometry(well, well_config, G);
        
        injector_wells = [injector_wells; well];
        
        fprintf('   %-8s │ %-12s │ [%2d,%2d] │ %4d ft TVD\n', ...
            well_name, well_config.well_type, ...
            well_config.grid_location(1), well_config.grid_location(2), ...
            well_config.total_depth_tvd_ft);
    end
    
    fprintf(' ─────────────────────────────────────────────────\n');

end

function well = create_well_structure(well_name, well_type, well_config, G)
% Create basic well structure with common properties

    well = struct();
    well.name = well_name;
    well.type = well_type;  % 'producer' or 'injector'
    well.well_type = well_config.well_type;  % 'vertical', 'horizontal', 'multi_lateral'
    well.phase = well_config.phase;
    well.drill_date = well_config.drill_date_day;
    
    % Grid location and coordinates
    well.grid_location = well_config.grid_location;  % [I, J, K]
    well.surface_coords = well_config.surface_coords;  % [X, Y] in ft
    
    % Depths
    well.total_depth_tvd_ft = well_config.total_depth_tvd_ft;
    
    % Initialize all possible well fields to ensure consistency
    well.wellbore_radius = 0.328;  % Default 6-inch wellbore
    well.skin_factor = 0;
    
    % Producer-specific fields (initialized for all wells)
    well.target_oil_rate = 0;
    well.min_bhp_psi = 1000;
    well.max_water_cut = 0.95;
    well.max_gor_scf_stb = 3000;
    well.esp_type = '';
    well.esp_stages = 0;
    well.esp_hp = 0;
    
    % Injector-specific fields (initialized for all wells)
    well.target_injection_rate = 0;
    well.max_bhp_psi = 3000;
    well.injection_fluid = '';
    
    % Convert grid location to cell index
    I = well_config.grid_location(1);
    J = well_config.grid_location(2);
    K_top = well_config.grid_location(3);
    
    % Validate grid location
    if I < 1 || I > G.cartDims(1) || J < 1 || J > G.cartDims(2)
        error(['Well %s location [%d,%d] outside 41x41 grid bounds\n' ...
               'UPDATE CANON: obsidian-vault/Planning/Well_Placement.md\n' ...
               'Well coordinates must be within [1,41] x [1,41] grid.'], ...
            well_name, I, J);
    end
    
    well.cell_index = sub2ind(G.cartDims, I, J, K_top);
    
    % Well completion layers
    if isfield(well_config, 'completion_layers')
        well.completion_layers = well_config.completion_layers;
    else
        well.completion_layers = K_top;  % Default to single layer
    end

end

function well = add_producer_properties(well, well_config)
% Add producer-specific properties

    well.target_oil_rate = well_config.target_oil_rate_stb_day;  % STB/day
    well.min_bhp_psi = well_config.min_bhp_psi;  % psi
    well.max_water_cut = well_config.max_water_cut;
    well.max_gor_scf_stb = well_config.max_gor_scf_stb;  % SCF/STB
    
    % ESP system properties
    well.esp_type = well_config.esp_type;
    well.esp_stages = well_config.esp_stages;
    well.esp_hp = well_config.esp_hp;
    
    % Well completion properties
    well.wellbore_radius = well_config.wellbore_radius_ft;  % ft
    well.skin_factor = well_config.skin_factor;

end

function well = add_injector_properties(well, well_config)
% Add injector-specific properties

    well.target_injection_rate = well_config.target_injection_rate_bbl_day;  % BBL/day
    well.max_bhp_psi = well_config.max_bhp_psi;  % psi
    well.injection_fluid = well_config.injection_fluid;
    
    % Well completion properties
    well.wellbore_radius = well_config.wellbore_radius_ft;  % ft
    well.skin_factor = well_config.skin_factor;

end

function well = add_well_geometry(well, well_config, G)
% Add well geometry based on well type

    % Initialize all geometry fields to ensure consistent structure
    well.trajectory_type = '';
    well.lateral_length = 0;
    well.kickoff_depth = 0;
    well.lateral_1_length = 0;
    well.lateral_2_length = 0;
    well.total_depth_md_ft = well.total_depth_tvd_ft;  % Default
    
    switch well_config.well_type
        case 'vertical'
            % Substep - Vertical well geometry ____________________
            well.trajectory_type = 'vertical';
            well.lateral_length = 0;
            well.kickoff_depth = 0;
            well.total_depth_md_ft = well.total_depth_tvd_ft;
            
        case 'horizontal'
            % Substep - Horizontal well geometry __________________
            well.trajectory_type = 'horizontal';
            well.lateral_length = well_config.horizontal_length_ft;
            well.kickoff_depth = well_config.total_depth_tvd_ft - 200;  % Typical kickoff
            well.total_depth_md_ft = well.total_depth_tvd_ft + well.lateral_length;
            
        case 'multi_lateral'
            % Substep - Multi-lateral well geometry _______________
            well.trajectory_type = 'multi_lateral';
            if isfield(well_config, 'lateral_1_length_ft')
                well.lateral_1_length = well_config.lateral_1_length_ft;
                well.lateral_2_length = well_config.lateral_2_length_ft;
            else
                well.lateral_1_length = 1500;  % Default lengths
                well.lateral_2_length = 1200;
            end
            well.kickoff_depth = well_config.total_depth_tvd_ft - 300;
            well.total_depth_md_ft = well.total_depth_tvd_ft + well.lateral_1_length + well.lateral_2_length;
            
        otherwise
            error('Unknown well type: %s', well_config.well_type);
    end

end

function validation_results = step_4_validate_well_locations(wells_results, G)
% Step 4 - Validate well locations and check for conflicts

    validation_results = struct();
    validation_results.status = 'success';
    validation_results.warnings = {};
    validation_results.errors = {};
    
    all_wells = [wells_results.producer_wells; wells_results.injector_wells];
    
    fprintf('\n Validating %d Well Locations:\n', length(all_wells));
    fprintf(' ─────────────────────────────────────────────────\n');
    
    % Substep 4.1 - Check grid bounds ______________________________
    for i = 1:length(all_wells)
        well = all_wells(i);
        [I, J, K] = ind2sub(G.cartDims, well.cell_index);
        
        if I < 1 || I > G.cartDims(1) || J < 1 || J > G.cartDims(2) || K < 1 || K > G.cartDims(3)
            validation_results.errors{end+1} = sprintf('Well %s outside grid bounds', well.name);
        end
    end
    
    % Substep 4.2 - Check for well spacing conflicts _______________
    min_spacing_ft = 500;  % Minimum well spacing
    for i = 1:length(all_wells)-1
        for j = i+1:length(all_wells)
            well1 = all_wells(i);
            well2 = all_wells(j);
            
            distance = sqrt((well1.surface_coords(1) - well2.surface_coords(1))^2 + ...
                           (well1.surface_coords(2) - well2.surface_coords(2))^2);
            
            if distance < min_spacing_ft
                error(['Wells %s and %s too close: %.1f ft (minimum %.1f ft)\n' ...
                       'UPDATE CANON: obsidian-vault/Planning/Well_Placement.md\n' ...
                       'Must maintain minimum spacing between all wells.'], ...
                    well1.name, well2.name, distance, min_spacing_ft);
            end
        end
    end
    
    % Substep 4.3 - Summary statistics _____________________________
    validation_results.total_wells = length(all_wells);
    validation_results.producers = length(wells_results.producer_wells);
    validation_results.injectors = length(wells_results.injector_wells);
    validation_results.vertical_wells = sum(strcmp({all_wells.trajectory_type}, 'vertical'));
    validation_results.horizontal_wells = sum(strcmp({all_wells.trajectory_type}, 'horizontal'));
    validation_results.multilateral_wells = sum(strcmp({all_wells.trajectory_type}, 'multi_lateral'));
    
    fprintf('   Total Wells: %d (%d producers + %d injectors)\n', ...
        validation_results.total_wells, validation_results.producers, validation_results.injectors);
    fprintf('   Well Types: %d vertical, %d horizontal, %d multi-lateral\n', ...
        validation_results.vertical_wells, validation_results.horizontal_wells, validation_results.multilateral_wells);
    
    if ~isempty(validation_results.errors)
        validation_results.status = 'error';
        fprintf('   Errors: %d\n', length(validation_results.errors));
        for i = 1:length(validation_results.errors)
            fprintf('     - %s\n', validation_results.errors{i});
        end
    end
    
    if ~isempty(validation_results.warnings)
        fprintf('   Warnings: %d\n', length(validation_results.warnings));
    end
    
    fprintf(' ─────────────────────────────────────────────────\n');

end

function export_path = step_5_export_well_data(wells_results)
% Step 5 - Export well placement data to static files

    script_path = fileparts(mfilename('fullpath'));
    if isempty(script_path)
        script_path = pwd();
    end
    data_dir = get_data_path('static');
    
    if ~exist(data_dir, 'dir')
        mkdir(data_dir);
    end
    
    % Substep 5.1 - Save MATLAB structure ________________________
    export_path = fullfile(data_dir, 'well_placement.mat');
    save(export_path, 'wells_results');
    
    % Substep 5.2 - Create summary text file _____________________
    summary_file = fullfile(data_dir, 'well_placement_summary.txt');
    write_well_summary_file(summary_file, wells_results);
    
    % Substep 5.3 - Create coordinates file for GIS ______________
    coords_file = fullfile(data_dir, 'well_coordinates.txt');
    write_well_coordinates_file(coords_file, wells_results);
    
    fprintf('   Exported to: %s\n', export_path);
    fprintf('   Summary: %s\n', summary_file);
    fprintf('   Coordinates: %s\n', coords_file);

end

function write_well_summary_file(filename, wells_results)
% Write well placement summary to text file

    fid = fopen(filename, 'w');
    if fid == -1
        error('Cannot open file for writing: %s', filename);
    end
    
    try
        fprintf(fid, 'Eagle West Field - Well Placement Summary\n');
        fprintf(fid, 'Generated: %s\n', datestr(now));
        fprintf(fid, '=========================================\n\n');
        
        % Summary statistics
        fprintf(fid, 'FIELD OVERVIEW:\n');
        fprintf(fid, '  Total Wells: %d\n', wells_results.total_wells);
        fprintf(fid, '  Producers: %d\n', length(wells_results.producer_wells));
        fprintf(fid, '  Injectors: %d\n', length(wells_results.injector_wells));
        fprintf(fid, '  Development Phases: %d\n\n', 6);
        
        % Producer wells
        fprintf(fid, 'PRODUCER WELLS:\n');
        fprintf(fid, '%-8s %-12s %-10s %-12s %-8s %-10s\n', ...
            'Well', 'Type', 'Phase', 'Grid_I,J', 'TVD_ft', 'Target_STB');
        fprintf(fid, '%s\n', repmat('-', 1, 70));
        
        for i = 1:length(wells_results.producer_wells)
            well = wells_results.producer_wells(i);
            fprintf(fid, '%-8s %-12s %-10d [%2d,%2d]     %-8d %-10d\n', ...
                well.name, well.well_type, well.phase, ...
                well.grid_location(1), well.grid_location(2), ...
                well.total_depth_tvd_ft, well.target_oil_rate);
        end
        
        fprintf(fid, '\n');
        
        % Injector wells
        fprintf(fid, 'INJECTOR WELLS:\n');
        fprintf(fid, '%-8s %-12s %-10s %-12s %-8s %-10s\n', ...
            'Well', 'Type', 'Phase', 'Grid_I,J', 'TVD_ft', 'Target_BBL');
        fprintf(fid, '%s\n', repmat('-', 1, 70));
        
        for i = 1:length(wells_results.injector_wells)
            well = wells_results.injector_wells(i);
            fprintf(fid, '%-8s %-12s %-10d [%2d,%2d]     %-8d %-10d\n', ...
                well.name, well.well_type, well.phase, ...
                well.grid_location(1), well.grid_location(2), ...
                well.total_depth_tvd_ft, well.target_injection_rate);
        end
        
        fprintf(fid, '\n');
        
        % Validation results
        if isfield(wells_results, 'validation')
            val = wells_results.validation;
            fprintf(fid, 'VALIDATION RESULTS:\n');
            fprintf(fid, '  Status: %s\n', val.status);
            fprintf(fid, '  Vertical Wells: %d\n', val.vertical_wells);
            fprintf(fid, '  Horizontal Wells: %d\n', val.horizontal_wells);
            fprintf(fid, '  Multi-lateral Wells: %d\n', val.multilateral_wells);
            
            if ~isempty(val.warnings)
                fprintf(fid, '  Warnings: %d\n', length(val.warnings));
            end
            if ~isempty(val.errors)
                fprintf(fid, '  Errors: %d\n', length(val.errors));
            end
        end
        
        fclose(fid);
        
    catch ME
        fclose(fid);
        error('Error writing summary file: %s', ME.message);
    end

end

function write_well_coordinates_file(filename, wells_results)
% Write well coordinates in CSV format

    fid = fopen(filename, 'w');
    if fid == -1
        error('Cannot open file for writing: %s', filename);
    end
    
    try
        % CSV header
        fprintf(fid, 'Well_Name,Type,Well_Type,Phase,X_ft,Y_ft,Grid_I,Grid_J,TVD_ft,MD_ft\n');
        
        % Producer wells
        for i = 1:length(wells_results.producer_wells)
            well = wells_results.producer_wells(i);
            fprintf(fid, '%s,%s,%s,%d,%.1f,%.1f,%d,%d,%.1f,%.1f\n', ...
                well.name, 'Producer', well.well_type, well.phase, ...
                well.surface_coords(1), well.surface_coords(2), ...
                well.grid_location(1), well.grid_location(2), ...
                well.total_depth_tvd_ft, well.total_depth_md_ft);
        end
        
        % Injector wells
        for i = 1:length(wells_results.injector_wells)
            well = wells_results.injector_wells(i);
            fprintf(fid, '%s,%s,%s,%d,%.1f,%.1f,%d,%d,%.1f,%.1f\n', ...
                well.name, 'Injector', well.well_type, well.phase, ...
                well.surface_coords(1), well.surface_coords(2), ...
                well.grid_location(1), well.grid_location(2), ...
                well.total_depth_tvd_ft, well.total_depth_md_ft);
        end
        
        fclose(fid);
        
    catch ME
        fclose(fid);
        error('Error writing coordinates file: %s', ME.message);
    end

end

function data = parse_yaml_file(filename)
% Simple YAML parser for wells configuration (Octave compatible)

    fid = fopen(filename, 'r');
    if fid == -1
        error('Cannot open YAML file: %s', filename);
    end
    
    data = struct();
    current_section = '';
    current_well = '';
    
    try
        while ~feof(fid)
            line = strtrim(fgetl(fid));
            
            % Skip empty lines and comments
            if isempty(line) || line(1) == '#'
                continue;
            end
            
            % Parse main sections
            if ~isempty(strfind(line, 'wells_system:'))
                current_section = 'wells_system';
                data.wells_system = struct();
            elseif ~isempty(strfind(line, 'producer_wells:'))
                current_section = 'producer_wells';
                data.wells_system.producer_wells = struct();
            elseif ~isempty(strfind(line, 'injector_wells:'))
                current_section = 'injector_wells';
                data.wells_system.injector_wells = struct();
            elseif line(1) ~= ' ' && ~isempty(strfind(line, ':'))
                % Top-level key
                continue;
            elseif strncmp(line, '    ', 4) && ~isempty(strfind(line, ':')) && isempty(strfind(line, '- '))
                % Well name or property
                if strcmp(current_section, 'producer_wells') || strcmp(current_section, 'injector_wells')
                    colon_pos = strfind(line, ':');
                    key = strtrim(line(1:colon_pos-1));
                    value = strtrim(line(colon_pos+1:end));
                    
                    if ~isempty(strfind(key, '-')) && length(key) > 6  % Well name like EW-001
                        current_well = key;
                        if strcmp(current_section, 'producer_wells')
                            data.wells_system.producer_wells.(current_well) = struct();
                        else
                            data.wells_system.injector_wells.(current_well) = struct();
                        end
                    elseif ~isempty(current_well)
                        % Parse property value
                        parsed_value = parse_yaml_value(value);
                        if strcmp(current_section, 'producer_wells')
                            data.wells_system.producer_wells.(current_well).(key) = parsed_value;
                        else
                            data.wells_system.injector_wells.(current_well).(key) = parsed_value;
                        end
                    end
                end
            end
        end
        
        fclose(fid);
        
    catch ME
        fclose(fid);
        error('Error parsing YAML file: %s', ME.message);
    end

end

function value = parse_yaml_value(str)
% Parse YAML value to appropriate MATLAB type

    str = strtrim(str);
    
    % Remove quotes
    if (str(1) == '"' && str(end) == '"') || (str(1) == '''' && str(end) == '''')
        value = str(2:end-1);
        return;
    end
    
    % Array notation [1, 2, 3]
    if str(1) == '[' && str(end) == ']'
        inner = str(2:end-1);
        parts = strsplit(inner, ',');
        value = [];
        for i = 1:length(parts)
            num = str2double(strtrim(parts{i}));
            if ~isnan(num)
                value(i) = num;
            end
        end
        return;
    end
    
    % Try to parse as number
    num_value = str2double(str);
    if ~isnan(num_value)
        value = num_value;
        return;
    end
    
    % String value
    value = str;

end

% Main execution when called as script
if ~nargout
    wells_results = s16_well_placement();
end