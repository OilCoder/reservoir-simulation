% Requires: MRST
function results = s06a_manual_overlap_analysis()
% S06A_MANUAL_OVERLAP_ANALYSIS - Manual diagnostic analysis of zone overlaps
% Requires: MRST
%
% PURPOSE:
%   Diagnose the 77.3% grid refinement coverage issue by analyzing:
%   - Well coordinates and 250 ft radius zones  
%   - Fault coordinates and 300 ft buffer zones
%   - Overlap patterns causing excessive coverage
%
% OUTPUT:
%   results - Diagnostic data structure
%
% Author: Claude Code AI System  
% Date: August 14, 2025

    fprintf('\n=== EAGLE WEST FIELD ZONE OVERLAP DIAGNOSTIC ===\n\n');
    
    % Initialize results structure
    results = struct();
    
    % Step 1: Extract configuration data
    fprintf('Step 1: Extracting zone coordinates...\n');
    [well_data, fault_data, grid_config] = extract_configuration_data();
    
    % Step 2: Calculate zone coverage
    fprintf('Step 2: Calculating zone coverage...\n');
    coverage_data = calculate_zone_coverage(well_data, fault_data, grid_config);
    
    % Step 3: Identify overlaps
    fprintf('Step 3: Identifying zone overlaps...\n');
    overlap_data = identify_zone_overlaps(well_data, fault_data, grid_config);
    
    % Step 4: Generate diagnostic report
    fprintf('Step 4: Generating diagnostic report...\n');
    results = generate_diagnostic_report(well_data, fault_data, coverage_data, overlap_data, grid_config);
    
    % Display results
    display_diagnostic_results(results);
    
    fprintf('\nDiagnostic analysis complete!\n\n');
    
end

function [well_data, fault_data, grid_config] = extract_configuration_data()
% Extract well and fault configuration data manually

    script_dir = fileparts(mfilename('fullpath'));
    
    % Extract grid configuration
    grid_config = struct();
    grid_config.nx = 41;
    grid_config.ny = 41; 
    grid_config.nz = 12;
    grid_config.cell_size_x = 82.0;  % ft
    grid_config.cell_size_y = 74.0;  % ft
    grid_config.field_extent_x = 3280.0;  % ft
    grid_config.field_extent_y = 2950.0;  % ft
    grid_config.well_radius = 250.0;  % ft
    grid_config.fault_buffer = 300.0;  % ft
    grid_config.refinement_factor = 2;
    grid_config.total_cells = grid_config.nx * grid_config.ny * grid_config.nz;
    
    % Extract well data from wells_config.yaml data
    well_data = [];
    
    % Producer wells (from configuration file)
    producers = {
        'EW-001', 15, 10, 3, 2750, 1750;
        'EW-002', 25, 15, 2, 3570, 2010;
        'EW-003', 20, 25, 6, 3240, 2840;
        'EW-004', 12, 32, 3, 2400, 3220;
        'EW-005', 30, 20, 2, 4050, 2470;
        'EW-006', 8, 18, 4, 1890, 2340;
        'EW-007', 18, 8, 3, 2970, 1480;
        'EW-008', 35, 12, 6, 4460, 1880;
        'EW-009', 22, 35, 4, 3400, 3530;
        'EW-010', 28, 28, 5, 3810, 3070
    };
    
    % Injector wells (from configuration file)
    injectors = {
        'IW-001', 5, 10, 6, 750, 1750;
        'IW-002', 35, 35, 7, 4460, 3530;
        'IW-003', 10, 30, 8, 2080, 3220;
        'IW-004', 32, 8, 9, 4130, 1480;
        'IW-005', 15, 38, 10, 2750, 3830
    };
    
    % Convert to structure array
    well_count = 1;
    for i = 1:size(producers, 1)
        well_data(well_count).name = producers{i,1};
        well_data(well_count).type = 'producer';
        well_data(well_count).grid_i = producers{i,2};
        well_data(well_count).grid_j = producers{i,3};
        well_data(well_count).grid_k = producers{i,4};
        well_data(well_count).x = (producers{i,2} - 1) * grid_config.cell_size_x;
        well_data(well_count).y = (producers{i,3} - 1) * grid_config.cell_size_y;
        well_data(well_count).radius = grid_config.well_radius;
        well_count = well_count + 1;
    end
    
    for i = 1:size(injectors, 1)
        well_data(well_count).name = injectors{i,1};
        well_data(well_count).type = 'injector';
        well_data(well_count).grid_i = injectors{i,2};
        well_data(well_count).grid_j = injectors{i,3};
        well_data(well_count).grid_k = injectors{i,4};
        well_data(well_count).x = (injectors{i,2} - 1) * grid_config.cell_size_x;
        well_data(well_count).y = (injectors{i,3} - 1) * grid_config.cell_size_y;
        well_data(well_count).radius = grid_config.well_radius;
        well_count = well_count + 1;
    end
    
    % Extract fault data from fault_config.yaml data
    fault_data = [];
    
    % Major faults (from configuration file)
    faults = {
        'Fault_A', 65.0, 70.0, 16896.0, 0.0, 1475.0, true;
        'Fault_B', 20.0, 65.0, 14784.0, 1640.0, 0.0, false;
        'Fault_C', 285.0, 62.0, 11088.0, 0.0, -1475.0, true;
        'Fault_D', 345.0, 68.0, 13200.0, -1640.0, 0.0, true;
        'Fault_E', 45.0, 72.0, 8448.0, 410.0, 370.0, false
    };
    
    % Convert to structure array with endpoints
    for i = 1:size(faults, 1)
        fault_name = faults{i,1};
        strike = faults{i,2};
        dip = faults{i,3};
        length = faults{i,4};
        offset_x = faults{i,5};
        offset_y = faults{i,6};
        is_sealing = faults{i,7};
        
        % Calculate fault endpoints
        center_x = grid_config.field_extent_x / 2 + offset_x;
        center_y = grid_config.field_extent_y / 2 + offset_y;
        
        strike_rad = deg2rad(strike);
        half_length = length / 2;
        
        dx = half_length * sin(strike_rad);
        dy = half_length * cos(strike_rad);
        
        fault_data(i).name = fault_name;
        fault_data(i).strike = strike;
        fault_data(i).dip = dip;
        fault_data(i).length = length;
        fault_data(i).x1 = center_x - dx;
        fault_data(i).y1 = center_y - dy;
        fault_data(i).x2 = center_x + dx;
        fault_data(i).y2 = center_y + dy;
        fault_data(i).buffer = grid_config.fault_buffer;
        fault_data(i).is_sealing = is_sealing;
    end
    
    fprintf('   Extracted %d wells and %d faults\n', length(well_data), length(fault_data));
    
end

function coverage_data = calculate_zone_coverage(well_data, fault_data, grid_config)
% Calculate which grid cells are covered by each type of zone

    % Initialize coverage tracking
    coverage_data = struct();
    coverage_data.well_coverage = zeros(grid_config.nx, grid_config.ny);
    coverage_data.fault_coverage = zeros(grid_config.nx, grid_config.ny);
    coverage_data.total_coverage = zeros(grid_config.nx, grid_config.ny);
    
    % Create grid of cell center coordinates
    [i_grid, j_grid] = meshgrid(1:grid_config.nx, 1:grid_config.ny);
    x_centers = (i_grid - 1) * grid_config.cell_size_x;
    y_centers = (j_grid - 1) * grid_config.cell_size_y;
    
    % Calculate well zone coverage
    for w = 1:length(well_data)
        well = well_data(w);
        distances = sqrt((x_centers - well.x).^2 + (y_centers - well.y).^2);
        well_mask = distances <= well.radius;
        coverage_data.well_coverage = coverage_data.well_coverage + well_mask;
    end
    
    % Calculate fault zone coverage
    for f = 1:length(fault_data)
        fault = fault_data(f);
        
        % Calculate distance to fault line for each cell
        fault_distances = zeros(size(x_centers));
        for i = 1:grid_config.nx
            for j = 1:grid_config.ny
                fault_distances(i,j) = point_to_line_distance(...
                    x_centers(i,j), y_centers(i,j), fault.x1, fault.y1, fault.x2, fault.y2);
            end
        end
        
        fault_mask = fault_distances <= fault.buffer;
        coverage_data.fault_coverage = coverage_data.fault_coverage + fault_mask;
    end
    
    % Calculate total coverage (any zone)
    coverage_data.total_coverage = (coverage_data.well_coverage > 0) | (coverage_data.fault_coverage > 0);
    
    % Calculate statistics
    total_cells = grid_config.nx * grid_config.ny;
    coverage_data.well_cells = sum(coverage_data.well_coverage(:) > 0);
    coverage_data.fault_cells = sum(coverage_data.fault_coverage(:) > 0);
    coverage_data.total_cells = sum(coverage_data.total_coverage(:));
    
    coverage_data.well_percent = (coverage_data.well_cells / total_cells) * 100;
    coverage_data.fault_percent = (coverage_data.fault_cells / total_cells) * 100;
    coverage_data.total_percent = (coverage_data.total_cells / total_cells) * 100;
    
    fprintf('   Well coverage: %.1f%%, Fault coverage: %.1f%%, Total: %.1f%%\n', ...
        coverage_data.well_percent, coverage_data.fault_percent, coverage_data.total_percent);
    
end

function overlap_data = identify_zone_overlaps(well_data, fault_data, grid_config)
% Identify specific zone overlaps

    overlap_data = struct();
    overlap_data.well_to_well = [];
    overlap_data.well_to_fault = [];
    overlap_data.fault_to_fault = [];
    
    % Well-to-well overlaps
    overlap_id = 1;
    for i = 1:length(well_data)
        for j = i+1:length(well_data)
            well1 = well_data(i);
            well2 = well_data(j);
            
            distance = sqrt((well1.x - well2.x)^2 + (well1.y - well2.y)^2);
            combined_radius = well1.radius + well2.radius;  % 500 ft
            
            if distance < combined_radius
                overlap_data.well_to_well(overlap_id).well1 = well1.name;
                overlap_data.well_to_well(overlap_id).well2 = well2.name;
                overlap_data.well_to_well(overlap_id).distance = distance;
                overlap_data.well_to_well(overlap_id).overlap_distance = combined_radius - distance;
                overlap_data.well_to_well(overlap_id).severity = categorize_severity(distance, combined_radius);
                overlap_id = overlap_id + 1;
            end
        end
    end
    
    % Well-to-fault overlaps
    overlap_id = 1;
    for i = 1:length(well_data)
        for j = 1:length(fault_data)
            well = well_data(i);
            fault = fault_data(j);
            
            distance = point_to_line_distance(well.x, well.y, fault.x1, fault.y1, fault.x2, fault.y2);
            combined_buffer = well.radius + fault.buffer;  % 550 ft
            
            if distance < combined_buffer
                overlap_data.well_to_fault(overlap_id).well = well.name;
                overlap_data.well_to_fault(overlap_id).fault = fault.name;
                overlap_data.well_to_fault(overlap_id).distance = distance;
                overlap_data.well_to_fault(overlap_id).overlap_distance = combined_buffer - distance;
                overlap_data.well_to_fault(overlap_id).severity = categorize_severity(distance, combined_buffer);
                overlap_id = overlap_id + 1;
            end
        end
    end
    
    % Fault-to-fault overlaps
    overlap_id = 1;
    for i = 1:length(fault_data)
        for j = i+1:length(fault_data)
            fault1 = fault_data(i);
            fault2 = fault_data(j);
            
            distance = line_to_line_distance(fault1, fault2);
            combined_buffer = fault1.buffer + fault2.buffer;  % 600 ft
            
            if distance < combined_buffer
                overlap_data.fault_to_fault(overlap_id).fault1 = fault1.name;
                overlap_data.fault_to_fault(overlap_id).fault2 = fault2.name;
                overlap_data.fault_to_fault(overlap_id).distance = distance;
                overlap_data.fault_to_fault(overlap_id).overlap_distance = combined_buffer - distance;
                overlap_data.fault_to_fault(overlap_id).severity = categorize_severity(distance, combined_buffer);
                overlap_id = overlap_id + 1;
            end
        end
    end
    
    fprintf('   Found %d well-well, %d well-fault, %d fault-fault overlaps\n', ...
        length(overlap_data.well_to_well), length(overlap_data.well_to_fault), length(overlap_data.fault_to_fault));
    
end

function distance = point_to_line_distance(px, py, x1, y1, x2, y2)
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

function distance = line_to_line_distance(fault1, fault2)
% Calculate minimum distance between two line segments

    d1 = point_to_line_distance(fault1.x1, fault1.y1, fault2.x1, fault2.y1, fault2.x2, fault2.y2);
    d2 = point_to_line_distance(fault1.x2, fault1.y2, fault2.x1, fault2.y1, fault2.x2, fault2.y2);
    d3 = point_to_line_distance(fault2.x1, fault2.y1, fault1.x1, fault1.y1, fault1.x2, fault1.y2);
    d4 = point_to_line_distance(fault2.x2, fault2.y2, fault1.x1, fault1.y1, fault1.x2, fault1.y2);
    
    distance = min([d1, d2, d3, d4]);
    
end

function severity = categorize_severity(distance, threshold)
% Categorize overlap severity

    overlap_ratio = 1 - (distance / threshold);
    
    if overlap_ratio > 0.75
        severity = 'SEVERE';
    elseif overlap_ratio > 0.5
        severity = 'HIGH';
    elseif overlap_ratio > 0.25
        severity = 'MODERATE';
    else
        severity = 'MINOR';
    end
    
end

function results = generate_diagnostic_report(well_data, fault_data, coverage_data, overlap_data, grid_config)
% Generate comprehensive diagnostic report

    results = struct();
    
    % Basic metrics
    results.total_wells = length(well_data);
    results.total_faults = length(fault_data);
    results.well_coverage_percent = coverage_data.well_percent;
    results.fault_coverage_percent = coverage_data.fault_percent;
    results.total_coverage_percent = coverage_data.total_percent;
    
    % Overlap counts
    results.well_well_overlaps = length(overlap_data.well_to_well);
    results.well_fault_overlaps = length(overlap_data.well_to_fault);
    results.fault_fault_overlaps = length(overlap_data.fault_to_fault);
    results.total_overlaps = results.well_well_overlaps + results.well_fault_overlaps + results.fault_fault_overlaps;
    
    % Zone efficiency analysis
    total_cells = grid_config.nx * grid_config.ny;
    well_zone_area = results.total_wells * pi * (grid_config.well_radius^2);
    fault_zone_area = sum([fault_data.length]) * grid_config.fault_buffer * 2;
    field_area = grid_config.field_extent_x * grid_config.field_extent_y;
    
    results.theoretical_well_coverage = (well_zone_area / field_area) * 100;
    results.theoretical_fault_coverage = (fault_zone_area / field_area) * 100;
    results.theoretical_total = results.theoretical_well_coverage + results.theoretical_fault_coverage;
    
    % Overlap efficiency
    results.coverage_efficiency = results.total_coverage_percent / results.theoretical_total;
    results.overlap_factor = results.theoretical_total / results.total_coverage_percent;
    
    % Problem identification
    results.coverage_problem = results.total_coverage_percent > 60;  % Threshold
    results.overlap_problem = results.total_overlaps > 20;  % Threshold
    
    % Severity analysis
    all_overlaps = [overlap_data.well_to_well, overlap_data.well_to_fault, overlap_data.fault_to_fault];
    if ~isempty(all_overlaps)
        severities = {all_overlaps.severity};
        results.severe_overlaps = sum(strcmp(severities, 'SEVERE'));
        results.high_overlaps = sum(strcmp(severities, 'HIGH'));
        results.moderate_overlaps = sum(strcmp(severities, 'MODERATE'));
        results.minor_overlaps = sum(strcmp(severities, 'MINOR'));
    else
        results.severe_overlaps = 0;
        results.high_overlaps = 0;
        results.moderate_overlaps = 0;
        results.minor_overlaps = 0;
    end
    
    % Store detailed data
    results.well_data = well_data;
    results.fault_data = fault_data;
    results.coverage_data = coverage_data;
    results.overlap_data = overlap_data;
    results.grid_config = grid_config;
    
    % Generate recommendations
    results.recommendations = generate_recommendations_list(results);
    
end

function recommendations = generate_recommendations_list(results)
% Generate list of specific recommendations

    recommendations = {};
    
    % Coverage recommendations
    if results.total_coverage_percent > 70
        recommendations{end+1} = sprintf('URGENT: %.1f%% coverage exceeds 70%% threshold. Major optimization required.', results.total_coverage_percent);
    elseif results.total_coverage_percent > 60
        recommendations{end+1} = sprintf('HIGH: %.1f%% coverage exceeds 60%% recommended maximum.', results.total_coverage_percent);
    end
    
    % Well spacing recommendations
    if results.well_well_overlaps > 5
        recommendations{end+1} = sprintf('CRITICAL: %d well-to-well overlaps. Consider reducing well radius from 250 ft to 200 ft.', results.well_well_overlaps);
    end
    
    % Fault buffer recommendations
    if results.well_fault_overlaps > 10
        recommendations{end+1} = sprintf('HIGH: %d well-to-fault overlaps. Consider reducing fault buffer from 300 ft to 250 ft.', results.well_fault_overlaps);
    end
    
    % Fault optimization
    if results.fault_fault_overlaps > 3
        recommendations{end+1} = sprintf('MODERATE: %d fault-to-fault overlaps. Review fault buffer sizes for optimization.', results.fault_fault_overlaps);
    end
    
    % Severity-based recommendations
    if results.severe_overlaps > 0
        recommendations{end+1} = sprintf('SEVERE: %d severe overlaps detected. Immediate zone adjustment required.', results.severe_overlaps);
    end
    
    % Efficiency recommendations
    if results.coverage_efficiency < 0.7
        recommendations{end+1} = sprintf('EFFICIENCY: Coverage efficiency %.1f%% indicates significant overlap waste.', results.coverage_efficiency * 100);
    end
    
    % Specific parameter suggestions
    if results.total_coverage_percent > 75
        recommendations{end+1} = 'SUGGESTED: Reduce well radius to 200 ft AND fault buffer to 250 ft for ~60% coverage.';
    elseif results.total_coverage_percent > 65
        recommendations{end+1} = 'SUGGESTED: Reduce either well radius to 200 ft OR fault buffer to 250 ft.';
    end
    
end

function display_diagnostic_results(results)
% Display diagnostic results in formatted output

    fprintf('\n=== DIAGNOSTIC RESULTS ===\n\n');
    
    fprintf('ZONE CONFIGURATION:\n');
    fprintf('- Total Wells: %d (radius: %.0f ft)\n', results.total_wells, results.grid_config.well_radius);
    fprintf('- Total Faults: %d (buffer: %.0f ft)\n', results.total_faults, results.grid_config.fault_buffer);
    fprintf('- Grid Size: %dx%d cells\n', results.grid_config.nx, results.grid_config.ny);
    fprintf('\n');
    
    fprintf('COVERAGE ANALYSIS:\n');
    fprintf('- Well Coverage: %.1f%%\n', results.well_coverage_percent);
    fprintf('- Fault Coverage: %.1f%%\n', results.fault_coverage_percent);
    fprintf('- Total Coverage: %.1f%%\n', results.total_coverage_percent);
    fprintf('- Theoretical Total: %.1f%%\n', results.theoretical_total);
    fprintf('- Coverage Efficiency: %.1f%%\n', results.coverage_efficiency * 100);
    fprintf('\n');
    
    fprintf('OVERLAP ANALYSIS:\n');
    fprintf('- Well-to-Well Overlaps: %d\n', results.well_well_overlaps);
    fprintf('- Well-to-Fault Overlaps: %d\n', results.well_fault_overlaps);
    fprintf('- Fault-to-Fault Overlaps: %d\n', results.fault_fault_overlaps);
    fprintf('- Total Overlaps: %d\n', results.total_overlaps);
    fprintf('\n');
    
    fprintf('OVERLAP SEVERITY:\n');
    fprintf('- Severe: %d\n', results.severe_overlaps);
    fprintf('- High: %d\n', results.high_overlaps);
    fprintf('- Moderate: %d\n', results.moderate_overlaps);
    fprintf('- Minor: %d\n', results.minor_overlaps);
    fprintf('\n');
    
    fprintf('PROBLEM ASSESSMENT:\n');
    if results.coverage_problem
        fprintf('- Coverage Problem: YES (>60%% threshold)\n');
    else
        fprintf('- Coverage Problem: NO\n');
    end
    if results.overlap_problem
        fprintf('- Overlap Problem: YES (>20 overlaps)\n');
    else
        fprintf('- Overlap Problem: NO\n');
    end
    fprintf('\n');
    
    fprintf('RECOMMENDATIONS:\n');
    for i = 1:length(results.recommendations)
        fprintf('%d. %s\n', i, results.recommendations{i});
    end
    
    % Detailed overlap listings
    if results.well_well_overlaps > 0
        fprintf('\nWELL-TO-WELL OVERLAPS:\n');
        for i = 1:length(results.overlap_data.well_to_well)
            overlap = results.overlap_data.well_to_well(i);
            fprintf('  %s <-> %s: %.0f ft apart (%.0f ft overlap, %s)\n', ...
                overlap.well1, overlap.well2, overlap.distance, overlap.overlap_distance, overlap.severity);
        end
    end
    
    if results.well_fault_overlaps > 0 && results.well_fault_overlaps <= 10
        fprintf('\nWELL-TO-FAULT OVERLAPS (showing first 10):\n');
        for i = 1:min(10, length(results.overlap_data.well_to_fault))
            overlap = results.overlap_data.well_to_fault(i);
            fprintf('  %s <-> %s: %.0f ft apart (%.0f ft overlap, %s)\n', ...
                overlap.well, overlap.fault, overlap.distance, overlap.overlap_distance, overlap.severity);
        end
    end
    
    if results.fault_fault_overlaps > 0
        fprintf('\nFAULT-TO-FAULT OVERLAPS:\n');
        for i = 1:length(results.overlap_data.fault_to_fault)
            overlap = results.overlap_data.fault_to_fault(i);
            fprintf('  %s <-> %s: %.0f ft apart (%.0f ft overlap, %s)\n', ...
                overlap.fault1, overlap.fault2, overlap.distance, overlap.overlap_distance, overlap.severity);
        end
    end
    
    fprintf('\n');
    
end

% Export results function
function export_diagnostic_results(results)
% Export diagnostic results to file

    script_dir = fileparts(mfilename('fullpath'));
    data_dir = fullfile(script_dir, '..', 'data', 'simulation_data', 'static');
    
    if ~exist(data_dir, 'dir')
        mkdir(data_dir);
    end
    
    % Export to text file
    report_file = fullfile(data_dir, 'zone_overlap_diagnostic_report.txt');
    fid = fopen(report_file, 'w');
    
    if fid ~= -1
        fprintf(fid, 'EAGLE WEST FIELD ZONE OVERLAP DIAGNOSTIC REPORT\n');
        fprintf(fid, 'Generated: %s\n\n', datestr(now));
        
        fprintf(fid, 'EXECUTIVE SUMMARY:\n');
        fprintf(fid, '- Total Coverage: %.1f%%\n', results.total_coverage_percent);
        fprintf(fid, '- Total Overlaps: %d\n', results.total_overlaps);
        fprintf(fid, '- Coverage Problem: %s\n', logical_to_text(results.coverage_problem));
        fprintf(fid, '- Overlap Problem: %s\n\n', logical_to_text(results.overlap_problem));
        
        fprintf(fid, 'DETAILED ANALYSIS:\n');
        fprintf(fid, 'Wells: %d zones @ %.0f ft radius\n', results.total_wells, results.grid_config.well_radius);
        fprintf(fid, 'Faults: %d zones @ %.0f ft buffer\n', results.total_faults, results.grid_config.fault_buffer);
        fprintf(fid, 'Well Coverage: %.1f%%\n', results.well_coverage_percent);
        fprintf(fid, 'Fault Coverage: %.1f%%\n', results.fault_coverage_percent);
        fprintf(fid, 'Coverage Efficiency: %.1f%%\n\n', results.coverage_efficiency * 100);
        
        fprintf(fid, 'RECOMMENDATIONS:\n');
        for i = 1:length(results.recommendations)
            fprintf(fid, '%d. %s\n', i, results.recommendations{i});
        end
        
        fclose(fid);
        fprintf('Diagnostic report exported to: %s\n', report_file);
    end
    
end

function text = logical_to_text(logical_value)
    if logical_value
        text = 'YES';
    else
        text = 'NO';
    end
end

% Main execution
if ~nargout
    results = s06a_manual_overlap_analysis();
    export_diagnostic_results(results);
    fprintf('Manual overlap analysis completed!\n\n');
end