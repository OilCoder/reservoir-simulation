% Requires: MRST
function overlap_analysis = s06a_analyze_zone_overlaps()
% S06A_ANALYZE_ZONE_OVERLAPS - Detailed analysis of well and fault zone overlaps
% Requires: MRST
%
% PURPOSE:
%   Diagnose excessive grid refinement coverage (77.3%) by analyzing:
%   - Well-to-well overlaps (250 ft radius zones)
%   - Well-to-fault overlaps (250 ft + 300 ft buffer zones)
%   - Fault-to-fault overlaps (300 ft buffers)
%   - Compound refinement effects
%
% OUTPUT:
%   overlap_analysis - Structure containing detailed overlap analysis
%
% Author: Claude Code AI System
% Date: August 14, 2025

    script_dir = fileparts(mfilename('fullpath'));
    addpath(fullfile(script_dir, 'utils')); 
    run(fullfile(script_dir, 'utils', 'print_utils.m'));

    % Add MRST session validation
    [success, message] = validate_mrst_session(script_dir);
    if ~success
        error('MRST validation failed: %s', message);
    end

    print_step_header('S06A', 'Analyze Zone Overlaps');
    
    total_start_time = tic;
    
    try
        % ----------------------------------------
        % Step 1 – Extract Zone Coordinates
        % ----------------------------------------
        step_start = tic;
        [well_zones, fault_zones, grid_info] = step_1_extract_coordinates();
        print_step_result(1, 'Extract Zone Coordinates', 'success', toc(step_start));
        
        % ----------------------------------------
        % Step 2 – Calculate Zone Overlaps
        % ----------------------------------------
        step_start = tic;
        overlap_data = step_2_calculate_overlaps(well_zones, fault_zones, grid_info);
        print_step_result(2, 'Calculate Zone Overlaps', 'success', toc(step_start));
        
        % ----------------------------------------
        % Step 3 – Analyze Grid Cell Coverage
        % ----------------------------------------
        step_start = tic;
        coverage_analysis = step_3_analyze_coverage(well_zones, fault_zones, overlap_data, grid_info);
        print_step_result(3, 'Analyze Grid Cell Coverage', 'success', toc(step_start));
        
        % ----------------------------------------
        % Step 4 – Generate Overlap Report
        % ----------------------------------------
        step_start = tic;
        overlap_analysis = step_4_generate_report(well_zones, fault_zones, overlap_data, coverage_analysis, grid_info);
        print_step_result(4, 'Generate Overlap Report', 'success', toc(step_start));
        
        print_step_footer('S06A', sprintf('Coverage Analysis Complete: %.1f%% overlap identified', ...
            overlap_analysis.total_overlap_percentage), toc(total_start_time));
        
    catch ME
        print_error_step(0, 'Zone Overlap Analysis', ME.message);
        error('Zone overlap analysis failed: %s', ME.message);
    end

end

function [well_zones, fault_zones, grid_info] = step_1_extract_coordinates()
% Step 1 - Extract well and fault coordinates from configuration files

    script_dir = fileparts(mfilename('fullpath'));
    
    % Substep 1.1 – Load grid configuration _________________________
    addpath(fullfile(script_dir, 'utils'));
    grid_config_file = fullfile(script_dir, 'config', 'grid_config.yaml');
    grid_config = read_yaml_config(grid_config_file, true);
    
    % Extract grid information
    grid_info = struct();
    grid_info.nx = grid_config.grid.nx;  % 41
    grid_info.ny = grid_config.grid.ny;  % 41
    grid_info.nz = grid_config.grid.nz;  % 12
    grid_info.cell_size_x = grid_config.grid.cell_size_x;  % 82 ft
    grid_info.cell_size_y = grid_config.grid.cell_size_y;  % 74 ft
    grid_info.total_cells = grid_info.nx * grid_info.ny * grid_info.nz;
    grid_info.field_extent_x = grid_config.grid.field_extent_x;  % 3280 ft
    grid_info.field_extent_y = grid_config.grid.field_extent_y;  % 2950 ft
    
    % Extract refinement parameters
    grid_info.well_radius = grid_config.refinement.well_refinement.radius;  % 250 ft
    grid_info.fault_buffer = grid_config.refinement.fault_refinement.buffer;  % 300 ft
    grid_info.refinement_factor = grid_config.refinement.well_refinement.factor;  % 2
    
    % Substep 1.2 – Extract well coordinates ________________________
    wells_config_file = fullfile(script_dir, 'config', 'wells_config.yaml');
    wells_config = read_yaml_config(wells_config_file, true);
    well_zones = extract_well_zones(wells_config, grid_info);
    
    % Substep 1.3 – Extract fault coordinates _______________________
    fault_config_file = fullfile(script_dir, 'config', 'fault_config.yaml');
    fault_config = read_yaml_config(fault_config_file, true);
    fault_zones = extract_fault_zones(fault_config, grid_info);
    
    fprintf('   Extracted %d well zones and %d fault zones\n', length(well_zones), length(fault_zones));
    
end

function well_zones = extract_well_zones(wells_config, grid_info)
% Extract well zone coordinates from wells configuration

    well_zones = [];
    zone_id = 1;
    
    % Process producer wells
    if isfield(wells_config, 'wells_system') && isfield(wells_config.wells_system, 'producer_wells')
        producer_names = fieldnames(wells_config.wells_system.producer_wells);
        for i = 1:length(producer_names)
            well_name = producer_names{i};
            well_data = wells_config.wells_system.producer_wells.(well_name);
            
            if isfield(well_data, 'grid_location')
                grid_loc = well_data.grid_location;
                
                % Convert grid coordinates to physical coordinates
                well_x = (grid_loc(1) - 1) * grid_info.cell_size_x;
                well_y = (grid_loc(2) - 1) * grid_info.cell_size_y;
                
                well_zones(zone_id).name = well_name;
                well_zones(zone_id).type = 'producer';
                well_zones(zone_id).grid_i = grid_loc(1);
                well_zones(zone_id).grid_j = grid_loc(2);
                well_zones(zone_id).grid_k = grid_loc(3);
                well_zones(zone_id).x = well_x;
                well_zones(zone_id).y = well_y;
                well_zones(zone_id).radius = grid_info.well_radius;
                
                zone_id = zone_id + 1;
            end
        end
    end
    
    % Process injector wells
    if isfield(wells_config, 'wells_system') && isfield(wells_config.wells_system, 'injector_wells')
        injector_names = fieldnames(wells_config.wells_system.injector_wells);
        for i = 1:length(injector_names)
            well_name = injector_names{i};
            well_data = wells_config.wells_system.injector_wells.(well_name);
            
            if isfield(well_data, 'grid_location')
                grid_loc = well_data.grid_location;
                
                % Convert grid coordinates to physical coordinates
                well_x = (grid_loc(1) - 1) * grid_info.cell_size_x;
                well_y = (grid_loc(2) - 1) * grid_info.cell_size_y;
                
                well_zones(zone_id).name = well_name;
                well_zones(zone_id).type = 'injector';
                well_zones(zone_id).grid_i = grid_loc(1);
                well_zones(zone_id).grid_j = grid_loc(2);
                well_zones(zone_id).grid_k = grid_loc(3);
                well_zones(zone_id).x = well_x;
                well_zones(zone_id).y = well_y;
                well_zones(zone_id).radius = grid_info.well_radius;
                
                zone_id = zone_id + 1;
            end
        end
    end
    
end

function fault_zones = extract_fault_zones(fault_config, grid_info)
% Extract fault zone coordinates from fault configuration

    fault_zones = [];
    
    if isfield(fault_config, 'fault_system') && isfield(fault_config.fault_system, 'faults')
        fault_names = fieldnames(fault_config.fault_system.faults);
        
        for i = 1:length(fault_names)
            fault_name = fault_names{i};
            fault_data = fault_config.fault_system.faults.(fault_name);
            
            % Calculate fault line endpoints
            fault_endpoints = calculate_fault_endpoints(fault_data, grid_info);
            
            fault_zones(i).name = fault_name;
            fault_zones(i).type = 'fault';
            fault_zones(i).x1 = fault_endpoints.x1;
            fault_zones(i).y1 = fault_endpoints.y1;
            fault_zones(i).x2 = fault_endpoints.x2;
            fault_zones(i).y2 = fault_endpoints.y2;
            fault_zones(i).buffer = grid_info.fault_buffer;
            fault_zones(i).is_sealing = fault_data.is_sealing;
            fault_zones(i).strike = fault_data.strike;
            fault_zones(i).length = fault_data.length;
        end
    end
    
end

function endpoints = calculate_fault_endpoints(fault_data, grid_info)
% Calculate fault line endpoints from strike, position, and length

    % Get fault position offset (center point)
    center_x = grid_info.field_extent_x / 2 + fault_data.position_offset_x;
    center_y = grid_info.field_extent_y / 2 + fault_data.position_offset_y;
    
    % Convert strike to radians (measured from North, clockwise)
    strike_rad = deg2rad(fault_data.strike);
    
    % Calculate half-length in each direction
    half_length = fault_data.length / 2;
    
    % Calculate endpoints
    dx = half_length * sin(strike_rad);
    dy = half_length * cos(strike_rad);
    
    endpoints.x1 = center_x - dx;
    endpoints.y1 = center_y - dy;
    endpoints.x2 = center_x + dx;
    endpoints.y2 = center_y + dy;
    
end

function overlap_data = step_2_calculate_overlaps(well_zones, fault_zones, grid_info)
% Step 2 - Calculate all types of zone overlaps

    overlap_data = struct();
    
    % Substep 2.1 – Calculate well-to-well overlaps __________________
    overlap_data.well_to_well = calculate_well_to_well_overlaps(well_zones);
    
    % Substep 2.2 – Calculate well-to-fault overlaps _________________
    overlap_data.well_to_fault = calculate_well_to_fault_overlaps(well_zones, fault_zones);
    
    % Substep 2.3 – Calculate fault-to-fault overlaps ________________
    overlap_data.fault_to_fault = calculate_fault_to_fault_overlaps(fault_zones);
    
    % Substep 2.4 – Summary statistics _______________________________
    overlap_data.summary = create_overlap_summary(overlap_data);
    
    fprintf('   Well-Well overlaps: %d, Well-Fault overlaps: %d, Fault-Fault overlaps: %d\n', ...
        length(overlap_data.well_to_well), length(overlap_data.well_to_fault), ...
        length(overlap_data.fault_to_fault));
    
end

function overlaps = calculate_well_to_well_overlaps(well_zones)
% Calculate overlaps between well zones (250 ft radius each)

    overlaps = [];
    overlap_id = 1;
    
    for i = 1:length(well_zones)
        for j = i+1:length(well_zones)
            well1 = well_zones(i);
            well2 = well_zones(j);
            
            % Calculate distance between well centers
            distance = sqrt((well1.x - well2.x)^2 + (well1.y - well2.y)^2);
            
            % Check if zones overlap (sum of radii > distance)
            combined_radius = well1.radius + well2.radius;  % 250 + 250 = 500 ft
            
            if distance < combined_radius
                overlap_area = calculate_circle_overlap_area(well1.x, well1.y, well1.radius, ...
                    well2.x, well2.y, well2.radius);
                
                overlaps(overlap_id).type = 'well-well';
                overlaps(overlap_id).zone1_name = well1.name;
                overlaps(overlap_id).zone2_name = well2.name;
                overlaps(overlap_id).distance = distance;
                overlaps(overlap_id).overlap_area = overlap_area;
                overlaps(overlap_id).severity = categorize_overlap_severity(distance, combined_radius);
                
                overlap_id = overlap_id + 1;
            end
        end
    end
    
end

function overlaps = calculate_well_to_fault_overlaps(well_zones, fault_zones)
% Calculate overlaps between well zones and fault buffers

    overlaps = [];
    overlap_id = 1;
    
    for i = 1:length(well_zones)
        for j = 1:length(fault_zones)
            well = well_zones(i);
            fault = fault_zones(j);
            
            % Calculate minimum distance from well center to fault line
            distance = calculate_point_to_line_distance_single(well.x, well.y, ...
                fault.x1, fault.y1, fault.x2, fault.y2);
            
            % Check if well zone overlaps with fault buffer
            combined_buffer = well.radius + fault.buffer;  % 250 + 300 = 550 ft
            
            if distance < combined_buffer
                overlap_area = calculate_well_fault_overlap_area(well, fault, distance);
                
                overlaps(overlap_id).type = 'well-fault';
                overlaps(overlap_id).zone1_name = well.name;
                overlaps(overlap_id).zone2_name = fault.name;
                overlaps(overlap_id).distance = distance;
                overlaps(overlap_id).overlap_area = overlap_area;
                overlaps(overlap_id).severity = categorize_overlap_severity(distance, combined_buffer);
                
                overlap_id = overlap_id + 1;
            end
        end
    end
    
end

function overlaps = calculate_fault_to_fault_overlaps(fault_zones)
% Calculate overlaps between fault buffer zones

    overlaps = [];
    overlap_id = 1;
    
    for i = 1:length(fault_zones)
        for j = i+1:length(fault_zones)
            fault1 = fault_zones(i);
            fault2 = fault_zones(j);
            
            % Calculate minimum distance between fault lines
            distance = calculate_line_to_line_distance(fault1, fault2);
            
            % Check if fault buffers overlap
            combined_buffer = fault1.buffer + fault2.buffer;  % 300 + 300 = 600 ft
            
            if distance < combined_buffer
                overlap_area = calculate_fault_fault_overlap_area(fault1, fault2, distance);
                
                overlaps(overlap_id).type = 'fault-fault';
                overlaps(overlap_id).zone1_name = fault1.name;
                overlaps(overlap_id).zone2_name = fault2.name;
                overlaps(overlap_id).distance = distance;
                overlaps(overlap_id).overlap_area = overlap_area;
                overlaps(overlap_id).severity = categorize_overlap_severity(distance, combined_buffer);
                
                overlap_id = overlap_id + 1;
            end
        end
    end
    
end

function area = calculate_circle_overlap_area(x1, y1, r1, x2, y2, r2)
% Calculate overlapping area between two circles

    d = sqrt((x1 - x2)^2 + (y1 - y2)^2);
    
    if d >= r1 + r2
        area = 0;  % No overlap
    elseif d <= abs(r1 - r2)
        area = pi * min(r1, r2)^2;  % One circle inside the other
    else
        % Partial overlap - use intersection formula
        part1 = r1^2 * acos((d^2 + r1^2 - r2^2) / (2 * d * r1));
        part2 = r2^2 * acos((d^2 + r2^2 - r1^2) / (2 * d * r2));
        part3 = 0.5 * sqrt((-d + r1 + r2) * (d + r1 - r2) * (d - r1 + r2) * (d + r1 + r2));
        area = part1 + part2 - part3;
    end
    
end

function area = calculate_well_fault_overlap_area(well, fault, distance)
% Estimate overlap area between well circle and fault buffer zone

    % Simplified calculation - actual implementation would be more complex
    if distance <= well.radius - fault.buffer
        % Well entirely within fault buffer
        area = pi * well.radius^2;
    elseif distance >= well.radius + fault.buffer
        % No overlap
        area = 0;
    else
        % Partial overlap - approximate as fraction of well area
        overlap_fraction = max(0, (well.radius + fault.buffer - distance) / (2 * well.radius));
        area = overlap_fraction * pi * well.radius^2;
    end
    
end

function area = calculate_fault_fault_overlap_area(fault1, fault2, distance)
% Estimate overlap area between two fault buffer zones

    % Simplified calculation - approximate based on buffer overlap
    if distance <= 0
        % Fault lines intersect
        area = min(fault1.length, fault2.length) * min(fault1.buffer, fault2.buffer);
    else
        % Partial buffer overlap
        overlap_fraction = max(0, (fault1.buffer + fault2.buffer - distance) / ...
            (fault1.buffer + fault2.buffer));
        area = overlap_fraction * fault1.length * fault1.buffer * 0.5;
    end
    
end

function distance = calculate_point_to_line_distance_single(px, py, x1, y1, x2, y2)
% Calculate distance from point to line segment

    A = px - x1;
    B = py - y1;
    C = x2 - x1;
    D = y2 - y1;
    
    dot = A * C + B * D;
    len_sq = C^2 + D^2;
    
    if len_sq == 0
        distance = sqrt(A^2 + B^2);
        return;
    end
    
    param = dot / len_sq;
    param = max(0, min(1, param));
    
    xx = x1 + param * C;
    yy = y1 + param * D;
    
    distance = sqrt((px - xx)^2 + (py - yy)^2);
    
end

function distance = calculate_line_to_line_distance(fault1, fault2)
% Calculate minimum distance between two line segments

    % Check all point-to-line combinations
    d1 = calculate_point_to_line_distance_single(fault1.x1, fault1.y1, fault2.x1, fault2.y1, fault2.x2, fault2.y2);
    d2 = calculate_point_to_line_distance_single(fault1.x2, fault1.y2, fault2.x1, fault2.y1, fault2.x2, fault2.y2);
    d3 = calculate_point_to_line_distance_single(fault2.x1, fault2.y1, fault1.x1, fault1.y1, fault1.x2, fault1.y2);
    d4 = calculate_point_to_line_distance_single(fault2.x2, fault2.y2, fault1.x1, fault1.y1, fault1.x2, fault1.y2);
    
    distance = min([d1, d2, d3, d4]);
    
end

function severity = categorize_overlap_severity(distance, combined_radius)
% Categorize overlap severity based on distance vs combined radius

    overlap_ratio = 1 - (distance / combined_radius);
    
    if overlap_ratio > 0.75
        severity = 'severe';
    elseif overlap_ratio > 0.5
        severity = 'high';
    elseif overlap_ratio > 0.25
        severity = 'moderate';
    else
        severity = 'minor';
    end
    
end

function summary = create_overlap_summary(overlap_data)
% Create summary statistics of overlaps

    summary = struct();
    
    % Count overlaps by type
    summary.total_well_well = length(overlap_data.well_to_well);
    summary.total_well_fault = length(overlap_data.well_to_fault);
    summary.total_fault_fault = length(overlap_data.fault_to_fault);
    summary.total_overlaps = summary.total_well_well + summary.total_well_fault + summary.total_fault_fault;
    
    % Count by severity
    all_overlaps = [overlap_data.well_to_well, overlap_data.well_to_fault, overlap_data.fault_to_fault];
    if ~isempty(all_overlaps)
        severities = {all_overlaps.severity};
        summary.severe_count = sum(strcmp(severities, 'severe'));
        summary.high_count = sum(strcmp(severities, 'high'));
        summary.moderate_count = sum(strcmp(severities, 'moderate'));
        summary.minor_count = sum(strcmp(severities, 'minor'));
    else
        summary.severe_count = 0;
        summary.high_count = 0;
        summary.moderate_count = 0;
        summary.minor_count = 0;
    end
    
    % Calculate total overlap area
    if ~isempty(all_overlaps)
        summary.total_overlap_area = sum([all_overlaps.overlap_area]);
    else
        summary.total_overlap_area = 0;
    end
    
end

function coverage_analysis = step_3_analyze_coverage(well_zones, fault_zones, overlap_data, grid_info)
% Step 3 - Analyze grid cell coverage and compound refinement effects

    % Substep 3.1 – Create grid cell coverage map ____________________
    coverage_map = create_coverage_map(well_zones, fault_zones, grid_info);
    
    % Substep 3.2 – Calculate coverage statistics ____________________
    coverage_stats = calculate_coverage_statistics(coverage_map, grid_info);
    
    % Substep 3.3 – Identify high-impact zones _______________________
    high_impact_zones = identify_high_impact_zones(coverage_map, well_zones, fault_zones, grid_info);
    
    % Substep 3.4 – Calculate compound refinement effects _____________
    compound_effects = calculate_compound_effects(coverage_map, grid_info);
    
    coverage_analysis = struct();
    coverage_analysis.coverage_map = coverage_map;
    coverage_analysis.coverage_stats = coverage_stats;
    coverage_analysis.high_impact_zones = high_impact_zones;
    coverage_analysis.compound_effects = compound_effects;
    
    fprintf('   Coverage analysis: %.1f%% of cells affected by refinement\n', ...
        coverage_stats.total_coverage_percent);
    
end

function coverage_map = create_coverage_map(well_zones, fault_zones, grid_info)
% Create 2D coverage map showing which cells are affected by refinement

    % Initialize coverage map (nx x ny)
    coverage_map = zeros(grid_info.nx, grid_info.ny);
    
    % Create grid cell center coordinates
    [i_grid, j_grid] = meshgrid(1:grid_info.nx, 1:grid_info.ny);
    x_centers = (i_grid - 1) * grid_info.cell_size_x;
    y_centers = (j_grid - 1) * grid_info.cell_size_y;
    
    % Mark cells affected by well zones
    for w = 1:length(well_zones)
        well = well_zones(w);
        distances = sqrt((x_centers - well.x).^2 + (y_centers - well.y).^2);
        well_mask = distances <= well.radius;
        coverage_map = coverage_map + well_mask;
    end
    
    % Mark cells affected by fault zones
    for f = 1:length(fault_zones)
        fault = fault_zones(f);
        
        % Calculate distance to fault line for each cell
        fault_distances = zeros(size(x_centers));
        for i = 1:grid_info.nx
            for j = 1:grid_info.ny
                fault_distances(i,j) = calculate_point_to_line_distance_single(...
                    x_centers(i,j), y_centers(i,j), fault.x1, fault.y1, fault.x2, fault.y2);
            end
        end
        
        fault_mask = fault_distances <= fault.buffer;
        coverage_map = coverage_map + fault_mask;
    end
    
end

function stats = calculate_coverage_statistics(coverage_map, grid_info)
% Calculate coverage statistics from coverage map

    stats = struct();
    
    % Basic coverage statistics
    total_cells = grid_info.nx * grid_info.ny;
    affected_cells = sum(coverage_map(:) > 0);
    stats.total_coverage_percent = (affected_cells / total_cells) * 100;
    
    % Overlap statistics
    stats.single_coverage = sum(coverage_map(:) == 1);
    stats.double_coverage = sum(coverage_map(:) == 2);
    stats.triple_coverage = sum(coverage_map(:) == 3);
    stats.quadruple_plus_coverage = sum(coverage_map(:) >= 4);
    
    % Percentages
    stats.single_coverage_percent = (stats.single_coverage / total_cells) * 100;
    stats.double_coverage_percent = (stats.double_coverage / total_cells) * 100;
    stats.triple_coverage_percent = (stats.triple_coverage / total_cells) * 100;
    stats.quadruple_plus_percent = (stats.quadruple_plus_coverage / total_cells) * 100;
    
    % Compound refinement factor
    refinement_factor = grid_info.refinement_factor;  % 2
    stats.effective_refinement_factor = mean(coverage_map(coverage_map > 0)) * refinement_factor;
    
    % Maximum overlap
    stats.max_overlap_count = max(coverage_map(:));
    
end

function high_impact_zones = identify_high_impact_zones(coverage_map, well_zones, fault_zones, grid_info)
% Identify zones with highest refinement impact

    high_impact_zones = [];
    zone_id = 1;
    
    % Find regions with 3+ overlapping zones
    [high_overlap_i, high_overlap_j] = find(coverage_map >= 3);
    
    if ~isempty(high_overlap_i)
        % Group adjacent high-overlap cells into zones
        for k = 1:length(high_overlap_i)
            i = high_overlap_i(k);
            j = high_overlap_j(k);
            overlap_count = coverage_map(i, j);
            
            % Convert to physical coordinates
            x = (i - 1) * grid_info.cell_size_x;
            y = (j - 1) * grid_info.cell_size_y;
            
            high_impact_zones(zone_id).grid_i = i;
            high_impact_zones(zone_id).grid_j = j;
            high_impact_zones(zone_id).x = x;
            high_impact_zones(zone_id).y = y;
            high_impact_zones(zone_id).overlap_count = overlap_count;
            high_impact_zones(zone_id).effective_refinement = overlap_count * grid_info.refinement_factor;
            
            % Identify contributing zones
            contributing_zones = identify_contributing_zones(x, y, well_zones, fault_zones);
            high_impact_zones(zone_id).contributing_zones = contributing_zones;
            
            zone_id = zone_id + 1;
        end
    end
    
end

function contributing_zones = identify_contributing_zones(x, y, well_zones, fault_zones)
% Identify which zones contribute to overlap at given location

    contributing_zones = {};
    
    % Check well zones
    for w = 1:length(well_zones)
        well = well_zones(w);
        distance = sqrt((x - well.x)^2 + (y - well.y)^2);
        if distance <= well.radius
            contributing_zones{end+1} = sprintf('Well_%s', well.name);
        end
    end
    
    % Check fault zones
    for f = 1:length(fault_zones)
        fault = fault_zones(f);
        distance = calculate_point_to_line_distance_single(x, y, fault.x1, fault.y1, fault.x2, fault.y2);
        if distance <= fault.buffer
            contributing_zones{end+1} = sprintf('Fault_%s', fault.name);
        end
    end
    
end

function compound_effects = calculate_compound_effects(coverage_map, grid_info)
% Calculate compound refinement effects

    compound_effects = struct();
    
    % Calculate effective cell count after refinement
    refinement_factor = grid_info.refinement_factor;  % 2
    effective_refinement = coverage_map * refinement_factor;
    effective_refinement(effective_refinement == 0) = 1;  % Non-refined cells
    
    original_cells = grid_info.total_cells;
    effective_new_cells = sum(effective_refinement(:).^2);  % 2x2 subdivision per refinement level
    
    compound_effects.original_cell_count = original_cells;
    compound_effects.effective_new_cell_count = effective_new_cells;
    compound_effects.cell_multiplication_factor = effective_new_cells / original_cells;
    
    % Distribution of refinement levels
    compound_effects.refinement_distribution = containers.Map();
    for level = 0:max(coverage_map(:))
        cell_count = sum(coverage_map(:) == level);
        compound_effects.refinement_distribution(sprintf('level_%d', level)) = cell_count;
    end
    
end

function overlap_analysis = step_4_generate_report(well_zones, fault_zones, overlap_data, coverage_analysis, grid_info)
% Step 4 - Generate comprehensive overlap analysis report

    overlap_analysis = struct();
    
    % Substep 4.1 – Compile analysis results _________________________
    overlap_analysis.well_zones = well_zones;
    overlap_analysis.fault_zones = fault_zones;
    overlap_analysis.overlap_data = overlap_data;
    overlap_analysis.coverage_analysis = coverage_analysis;
    overlap_analysis.grid_info = grid_info;
    
    % Substep 4.2 – Calculate key metrics ____________________________
    overlap_analysis.key_metrics = calculate_key_metrics(overlap_data, coverage_analysis, grid_info);
    
    % Substep 4.3 – Generate recommendations _________________________
    overlap_analysis.recommendations = generate_recommendations(overlap_data, coverage_analysis);
    
    % Substep 4.4 – Export analysis results __________________________
    export_analysis_results(overlap_analysis);
    
    % Key summary metrics
    overlap_analysis.total_overlap_percentage = coverage_analysis.coverage_stats.total_coverage_percent;
    overlap_analysis.high_impact_zone_count = length(coverage_analysis.high_impact_zones);
    overlap_analysis.max_compound_refinement = coverage_analysis.coverage_stats.max_overlap_count * grid_info.refinement_factor;
    
    fprintf('   Analysis complete: %.1f%% coverage, %d high-impact zones identified\n', ...
        overlap_analysis.total_overlap_percentage, overlap_analysis.high_impact_zone_count);
    
end

function metrics = calculate_key_metrics(overlap_data, coverage_analysis, grid_info)
% Calculate key overlap metrics

    metrics = struct();
    
    % Coverage metrics
    metrics.total_coverage_percent = coverage_analysis.coverage_stats.total_coverage_percent;
    metrics.overlap_coverage_percent = coverage_analysis.coverage_stats.double_coverage_percent + ...
        coverage_analysis.coverage_stats.triple_coverage_percent + ...
        coverage_analysis.coverage_stats.quadruple_plus_percent;
    
    % Zone efficiency metrics
    total_well_area = length(coverage_analysis.coverage_map) * pi * (grid_info.well_radius^2);
    total_fault_area = sum([fault_zones.length]) * grid_info.fault_buffer * 2;
    field_area = grid_info.field_extent_x * grid_info.field_extent_y;
    
    metrics.well_zone_efficiency = (coverage_analysis.coverage_stats.single_coverage + 
        coverage_analysis.coverage_stats.double_coverage) / ...
        (total_well_area / (grid_info.cell_size_x * grid_info.cell_size_y));
    
    % Compound effect severity
    metrics.compound_effect_severity = coverage_analysis.compound_effects.cell_multiplication_factor;
    metrics.average_refinement_per_cell = mean(coverage_analysis.coverage_map(coverage_analysis.coverage_map > 0));
    
    % Problem zone identification
    metrics.problem_zones_count = length(coverage_analysis.high_impact_zones);
    metrics.severe_overlap_count = overlap_data.summary.severe_count;
    
end

function recommendations = generate_recommendations(overlap_data, coverage_analysis)
% Generate recommendations for reducing overlap coverage

    recommendations = {};
    
    % Well spacing recommendations
    if overlap_data.summary.total_well_well > 5
        recommendations{end+1} = sprintf('CRITICAL: %d well-to-well overlaps detected. Consider increasing well spacing or reducing well refinement radius from 250 ft.', ...
            overlap_data.summary.total_well_well);
    end
    
    % Fault buffer recommendations
    if overlap_data.summary.total_well_fault > 10
        recommendations{end+1} = sprintf('HIGH: %d well-to-fault overlaps detected. Consider reducing fault buffer from 300 ft or well radius from 250 ft.', ...
            overlap_data.summary.total_well_fault);
    end
    
    % Coverage reduction recommendations
    if coverage_analysis.coverage_stats.total_coverage_percent > 60
        recommendations{end+1} = sprintf('URGENT: %.1f%% grid coverage exceeds recommended 60%% maximum. Significant optimization needed.', ...
            coverage_analysis.coverage_stats.total_coverage_percent);
    end
    
    % Compound effect recommendations
    if coverage_analysis.coverage_stats.max_overlap_count >= 4
        recommendations{end+1} = sprintf('SEVERE: Maximum %dx compound refinement detected. Some cells may have %dx effective refinement.', ...
            coverage_analysis.coverage_stats.max_overlap_count, ...
            coverage_analysis.coverage_stats.max_overlap_count * 2);
    end
    
    % Specific zone adjustments
    if ~isempty(coverage_analysis.high_impact_zones)
        recommendations{end+1} = sprintf('OPTIMIZE: %d high-impact zones identified. Review zones with 3+ overlaps for selective refinement.', ...
            length(coverage_analysis.high_impact_zones));
    end
    
end

function export_analysis_results(overlap_analysis)
% Export analysis results to files

    script_dir = fileparts(mfilename('fullpath'));
    addpath(fullfile(script_dir, 'utils'));
    data_dir = get_data_path('static');
    
    if ~exist(data_dir, 'dir')
        mkdir(data_dir);
    end
    
    % Save complete analysis
    analysis_file = fullfile(data_dir, 'zone_overlap_analysis.mat');
    save(analysis_file, 'overlap_analysis');
    
    % Create detailed text report
    report_file = fullfile(data_dir, 'zone_overlap_report.txt');
    create_detailed_report(overlap_analysis, report_file);
    
end

function create_detailed_report(overlap_analysis, report_file)
% Create detailed text report of overlap analysis

    fid = fopen(report_file, 'w');
    if fid == -1
        error(['Could not create overlap report file\n' ...
               'UPDATE CANON: obsidian-vault/Planning/Grid_Refinement.md\n' ...
               'Must have write permissions for report generation.']);
        return;
    end
    
    try
        fprintf(fid, '=== EAGLE WEST FIELD ZONE OVERLAP ANALYSIS ===\n');
        fprintf(fid, 'Generated: %s\n\n', datestr(now));
        
        % Executive summary
        fprintf(fid, 'EXECUTIVE SUMMARY:\n');
        fprintf(fid, '- Total Grid Coverage: %.1f%%\n', overlap_analysis.total_overlap_percentage);
        fprintf(fid, '- High-Impact Zones: %d\n', overlap_analysis.high_impact_zone_count);
        fprintf(fid, '- Maximum Compound Refinement: %dx\n', overlap_analysis.max_compound_refinement);
        fprintf(fid, '- Total Overlaps: %d\n', overlap_analysis.overlap_data.summary.total_overlaps);
        fprintf(fid, '\n');
        
        % Coverage breakdown
        fprintf(fid, 'COVERAGE BREAKDOWN:\n');
        stats = overlap_analysis.coverage_analysis.coverage_stats;
        fprintf(fid, '- Single Coverage: %.1f%% (%d cells)\n', stats.single_coverage_percent, stats.single_coverage);
        fprintf(fid, '- Double Coverage: %.1f%% (%d cells)\n', stats.double_coverage_percent, stats.double_coverage);
        fprintf(fid, '- Triple Coverage: %.1f%% (%d cells)\n', stats.triple_coverage_percent, stats.triple_coverage);
        fprintf(fid, '- 4+ Coverage: %.1f%% (%d cells)\n', stats.quadruple_plus_percent, stats.quadruple_plus_coverage);
        fprintf(fid, '\n');
        
        % Overlap details
        fprintf(fid, 'OVERLAP DETAILS:\n');
        summary = overlap_analysis.overlap_data.summary;
        fprintf(fid, '- Well-to-Well Overlaps: %d\n', summary.total_well_well);
        fprintf(fid, '- Well-to-Fault Overlaps: %d\n', summary.total_well_fault);
        fprintf(fid, '- Fault-to-Fault Overlaps: %d\n', summary.total_fault_fault);
        fprintf(fid, '- Severe Overlaps: %d\n', summary.severe_count);
        fprintf(fid, '- High Overlaps: %d\n', summary.high_count);
        fprintf(fid, '\n');
        
        % Recommendations
        fprintf(fid, 'RECOMMENDATIONS:\n');
        for i = 1:length(overlap_analysis.recommendations)
            fprintf(fid, '%d. %s\n', i, overlap_analysis.recommendations{i});
        end
        
        fclose(fid);
        
    catch ME
        fclose(fid);
        error(['Error writing overlap report: %s\n' ...
               'UPDATE CANON: obsidian-vault/Planning/Grid_Refinement.md\n' ...
               'Must define valid overlap report format.'], ME.message);
    end
    
end

% Main execution
if ~nargout
    overlap_analysis = s06a_analyze_zone_overlaps();
    fprintf('Zone overlap analysis completed!\n\n');
end