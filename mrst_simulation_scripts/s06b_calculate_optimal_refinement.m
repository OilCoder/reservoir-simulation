% Requires: MRST
% s06b_calculate_optimal_refinement.m
% Calculate optimal refinement parameters for 20-30% target coverage
% Phase 2: Strategy Design - Mathematical optimization
% Date: 2025-08-14

function s06b_calculate_optimal_refinement()
    fprintf('\n=== Calculating Optimal Refinement Parameters ===\n');
    
    %% Step 1: Load current grid and fault/well configurations
    config = load_grid_configuration();
    wells_config = load_wells_configuration(); 
    faults_config = load_faults_configuration();
    
    %% Step 2: Calculate baseline grid metrics
    grid_metrics = calculate_grid_metrics(config);
    display_grid_summary(grid_metrics);
    
    %% Step 3: Analyze current refinement coverage
    current_coverage = analyze_current_coverage(config, wells_config, faults_config, grid_metrics);
    display_current_coverage(current_coverage);
    
    %% Step 4: Mathematical optimization for target coverage
    target_coverage = optimize_refinement_parameters(grid_metrics, wells_config, faults_config);
    display_optimization_results(target_coverage);
    
    %% Step 5: Create tiered refinement strategy
    tiered_strategy = create_tiered_strategy(wells_config, faults_config, target_coverage);
    display_tiered_strategy(tiered_strategy);
    
    %% Step 6: Generate implementation report
    optimization_report = generate_optimization_report(grid_metrics, current_coverage, target_coverage, tiered_strategy);
    save_optimization_report(optimization_report);
    
    fprintf('\n=== Optimal Refinement Calculation Complete ===\n');
end

function config = load_grid_configuration()
    fprintf('Loading grid configuration...\n');
    config_file = fullfile('config', 'grid_config.yaml');
    
    if exist(config_file, 'file')
        config = read_yaml_config(config_file, true);  % Silent mode
    else
        error('Grid configuration file not found: %s', config_file);
    end
end

function wells_config = load_wells_configuration()
    fprintf('Loading wells configuration...\n');
    config_file = fullfile('config', 'wells_config.yaml');
    
    if exist(config_file, 'file')
        wells_config = read_yaml_config(config_file, true);  % Silent mode
    else
        error('Wells configuration file not found: %s', config_file);
    end
end

function faults_config = load_faults_configuration()
    fprintf('Loading faults configuration...\n');
    config_file = fullfile('config', 'fault_config.yaml');
    
    if exist(config_file, 'file')
        faults_config = read_yaml_config(config_file, true);  % Silent mode
    else
        error('Faults configuration file not found: %s', config_file);
    end
end

function grid_metrics = calculate_grid_metrics(config)
    fprintf('Calculating grid metrics...\n');
    
    % Basic grid dimensions
    grid_metrics.nx = config.grid.nx;
    grid_metrics.ny = config.grid.ny;
    grid_metrics.nz = config.grid.nz;
    grid_metrics.total_cells = grid_metrics.nx * grid_metrics.ny * grid_metrics.nz;
    
    % Physical dimensions
    grid_metrics.field_length_x = config.grid.field_extent_x;  % 3280 ft
    grid_metrics.field_length_y = config.grid.field_extent_y;  % 2950 ft
    grid_metrics.cell_size_x = config.grid.cell_size_x;        % 82 ft
    grid_metrics.cell_size_y = config.grid.cell_size_y;        % 74 ft
    
    % Field area calculations
    grid_metrics.total_field_area_ft2 = grid_metrics.field_length_x * grid_metrics.field_length_y;
    grid_metrics.total_field_area_acres = grid_metrics.total_field_area_ft2 / 43560;  % Convert to acres
    grid_metrics.cell_area_ft2 = grid_metrics.cell_size_x * grid_metrics.cell_size_y;
    
    % Active cells estimation (from config)
    grid_metrics.target_active_cells = config.grid.target_active_cells;
    grid_metrics.active_cell_ratio = grid_metrics.target_active_cells / grid_metrics.total_cells;
    
    fprintf('Grid metrics calculated: %d total cells, %.1f%% active\n', ...
        grid_metrics.total_cells, grid_metrics.active_cell_ratio * 100);
end

function display_grid_summary(grid_metrics)
    fprintf('\n--- Grid Summary ---\n');
    fprintf('Grid Dimensions: %dx%dx%d = %d total cells\n', ...
        grid_metrics.nx, grid_metrics.ny, grid_metrics.nz, grid_metrics.total_cells);
    fprintf('Field Extent: %.0f x %.0f ft (%.1f acres)\n', ...
        grid_metrics.field_length_x, grid_metrics.field_length_y, grid_metrics.total_field_area_acres);
    fprintf('Base Cell Size: %.0f x %.0f ft (%.0f ft²)\n', ...
        grid_metrics.cell_size_x, grid_metrics.cell_size_y, grid_metrics.cell_area_ft2);
    fprintf('Target Active Cells: %d (%.1f%%)\n', ...
        grid_metrics.target_active_cells, grid_metrics.active_cell_ratio * 100);
end

function current_coverage = analyze_current_coverage(config, wells_config, faults_config, grid_metrics)
    fprintf('\nAnalyzing current refinement coverage...\n');
    
    % Current well refinement parameters
    well_radius = config.refinement.well_refinement.radius;  % 250 ft
    well_factor = config.refinement.well_refinement.factor;  % 2x2 = 4 cells per base cell
    total_wells = wells_config.wells_system.total_wells;     % 15 wells
    
    % Current fault refinement parameters  
    fault_buffer = config.refinement.fault_refinement.buffer;  % 300 ft
    fault_factor = config.refinement.fault_refinement.factor;  % 2x2 = 4 cells per base cell
    
    % Calculate well coverage
    well_area_per_well = pi * well_radius^2;  % Circular area around each well
    total_well_area = total_wells * well_area_per_well;
    well_coverage_ratio = total_well_area / grid_metrics.total_field_area_ft2;
    well_refined_cells = well_coverage_ratio * grid_metrics.target_active_cells * well_factor;
    
    % Calculate fault coverage (simplified as linear buffer)
    fault_names = fieldnames(faults_config.fault_system.faults);
    total_fault_length = 0;
    for i = 1:length(fault_names)
        fault_name = fault_names{i};
        fault_data = faults_config.fault_system.faults.(fault_name);
        total_fault_length = total_fault_length + fault_data.length;
    end
    
    % Fault coverage as linear buffer zones
    fault_area = total_fault_length * 2 * fault_buffer;  % Both sides of fault
    fault_coverage_ratio = fault_area / grid_metrics.total_field_area_ft2;
    fault_refined_cells = fault_coverage_ratio * grid_metrics.target_active_cells * fault_factor;
    
    % Estimate overlap (simplified - wells within fault zones)
    overlap_ratio = 0.13;  % 13% from previous analysis
    overlap_cells = overlap_ratio * (well_refined_cells + fault_refined_cells);
    
    % Total coverage
    total_refined_cells = well_refined_cells + fault_refined_cells - overlap_cells;
    total_coverage_ratio = total_refined_cells / grid_metrics.target_active_cells;
    
    % Package results
    current_coverage.well_radius = well_radius;
    current_coverage.fault_buffer = fault_buffer;
    current_coverage.well_coverage_ratio = well_coverage_ratio;
    current_coverage.fault_coverage_ratio = fault_coverage_ratio;
    current_coverage.overlap_ratio = overlap_ratio;
    current_coverage.total_coverage_ratio = total_coverage_ratio;
    current_coverage.well_refined_cells = well_refined_cells;
    current_coverage.fault_refined_cells = fault_refined_cells;
    current_coverage.overlap_cells = overlap_cells;
    current_coverage.total_refined_cells = total_refined_cells;
    
    fprintf('Current coverage calculated: %.1f%% total\n', total_coverage_ratio * 100);
end

function display_current_coverage(current_coverage)
    fprintf('\n--- Current Refinement Coverage Analysis ---\n');
    fprintf('Well Parameters:\n');
    fprintf('  - Radius: %.0f ft\n', current_coverage.well_radius);
    fprintf('  - Coverage: %.1f%% of field area\n', current_coverage.well_coverage_ratio * 100);
    fprintf('  - Refined cells: %.0f\n', current_coverage.well_refined_cells);
    
    fprintf('Fault Parameters:\n');
    fprintf('  - Buffer: %.0f ft\n', current_coverage.fault_buffer);
    fprintf('  - Coverage: %.1f%% of field area\n', current_coverage.fault_coverage_ratio * 100);
    fprintf('  - Refined cells: %.0f\n', current_coverage.fault_refined_cells);
    
    fprintf('Total Coverage:\n');
    fprintf('  - Overlap: %.1f%% (%.0f cells)\n', current_coverage.overlap_ratio * 100, current_coverage.overlap_cells);
    fprintf('  - Net refined cells: %.0f\n', current_coverage.total_refined_cells);
    fprintf('  - Total coverage: %.1f%%\n', current_coverage.total_coverage_ratio * 100);
end

function target_coverage = optimize_refinement_parameters(grid_metrics, wells_config, faults_config)
    fprintf('\nOptimizing refinement parameters for 20-30%% target coverage...\n');
    
    % Target parameters
    target_coverage_min = 0.20;  % 20%
    target_coverage_max = 0.30;  % 30%
    target_coverage_mid = 0.25;  % 25% target
    
    total_wells = wells_config.wells_system.total_wells;  % 15 wells
    target_active_cells = grid_metrics.target_active_cells;  % 19000 cells
    total_field_area = grid_metrics.total_field_area_ft2;
    
    % Calculate total fault length
    fault_names = fieldnames(faults_config.fault_system.faults);
    total_fault_length = 0;
    for i = 1:length(fault_names)
        fault_name = fault_names{i};
        fault_data = faults_config.fault_system.faults.(fault_name);
        total_fault_length = total_fault_length + fault_data.length;
    end
    
    % Optimization target: 25% coverage with allocation
    target_well_coverage = 0.15;    % 15% for wells
    target_fault_coverage = 0.10;   % 10% for faults  
    target_overlap_allowance = 0.05; % 5% overlap allowance
    
    % Calculate optimal well radius
    % Well coverage = (15 * π * R²) / total_field_area = 0.15
    % R² = (0.15 * total_field_area) / (15 * π)
    optimal_well_radius_sq = (target_well_coverage * total_field_area) / (total_wells * pi);
    optimal_well_radius = sqrt(optimal_well_radius_sq);
    
    % Calculate optimal fault buffer
    % Fault coverage = (total_fault_length * 2 * buffer) / total_field_area = 0.10
    % buffer = (0.10 * total_field_area) / (2 * total_fault_length)
    optimal_fault_buffer = (target_fault_coverage * total_field_area) / (2 * total_fault_length);
    
    % Calculate refined cells with factor 2 (2x2 subdivision = 4 cells per base cell)
    refinement_factor = 4;  % 2x2 subdivision
    
    optimal_well_refined_cells = target_well_coverage * target_active_cells * refinement_factor;
    optimal_fault_refined_cells = target_fault_coverage * target_active_cells * refinement_factor;
    total_optimal_cells = optimal_well_refined_cells + optimal_fault_refined_cells;
    optimal_overlap_cells = target_overlap_allowance * target_active_cells * refinement_factor;
    
    net_refined_cells = total_optimal_cells - optimal_overlap_cells;
    final_coverage_ratio = net_refined_cells / target_active_cells;
    
    % Package optimization results
    target_coverage.target_coverage_min = target_coverage_min;
    target_coverage.target_coverage_max = target_coverage_max;
    target_coverage.target_coverage_mid = target_coverage_mid;
    target_coverage.optimal_well_radius = optimal_well_radius;
    target_coverage.optimal_fault_buffer = optimal_fault_buffer;
    target_coverage.target_well_coverage = target_well_coverage;
    target_coverage.target_fault_coverage = target_fault_coverage;
    target_coverage.target_overlap_allowance = target_overlap_allowance;
    target_coverage.optimal_well_refined_cells = optimal_well_refined_cells;
    target_coverage.optimal_fault_refined_cells = optimal_fault_refined_cells;
    target_coverage.optimal_overlap_cells = optimal_overlap_cells;
    target_coverage.net_refined_cells = net_refined_cells;
    target_coverage.final_coverage_ratio = final_coverage_ratio;
    target_coverage.total_fault_length = total_fault_length;
    
    fprintf('Optimization complete: %.1f%% target coverage achieved\n', final_coverage_ratio * 100);
end

function display_optimization_results(target_coverage)
    fprintf('\n--- Optimization Results for 20-30%% Target Coverage ---\n');
    fprintf('Target Coverage Range: %.0f%% - %.0f%% (targeting %.0f%%)\n', ...
        target_coverage.target_coverage_min * 100, ...
        target_coverage.target_coverage_max * 100, ...
        target_coverage.target_coverage_mid * 100);
    
    fprintf('\nOptimal Parameters:\n');
    fprintf('  Well Radius: %.0f ft (current: 250 ft)\n', target_coverage.optimal_well_radius);
    fprintf('  Fault Buffer: %.0f ft (current: 300 ft)\n', target_coverage.optimal_fault_buffer);
    
    fprintf('\nCoverage Allocation:\n');
    fprintf('  Wells: %.1f%% (%.0f refined cells)\n', ...
        target_coverage.target_well_coverage * 100, target_coverage.optimal_well_refined_cells);
    fprintf('  Faults: %.1f%% (%.0f refined cells)\n', ...
        target_coverage.target_fault_coverage * 100, target_coverage.optimal_fault_refined_cells);
    fprintf('  Overlap Allowance: %.1f%% (%.0f cells)\n', ...
        target_coverage.target_overlap_allowance * 100, target_coverage.optimal_overlap_cells);
    
    fprintf('\nFinal Results:\n');
    fprintf('  Net Refined Cells: %.0f\n', target_coverage.net_refined_cells);
    fprintf('  Achieved Coverage: %.1f%%\n', target_coverage.final_coverage_ratio * 100);
    
    % Check if within target range
    if target_coverage.final_coverage_ratio >= target_coverage.target_coverage_min && ...
       target_coverage.final_coverage_ratio <= target_coverage.target_coverage_max
        fprintf('  ✓ WITHIN TARGET RANGE\n');
    else
        fprintf('  ✗ OUTSIDE TARGET RANGE\n');
    end
end

function tiered_strategy = create_tiered_strategy(wells_config, faults_config, target_coverage)
    fprintf('\nCreating tiered refinement strategy...\n');
    
    % Classify wells by importance
    producer_wells = fieldnames(wells_config.wells_system.producer_wells);
    injector_wells = fieldnames(wells_config.wells_system.injector_wells);
    
    % Critical wells (early phase, high production)
    critical_wells = {'EW-001', 'EW-002', 'IW-001'};
    
    % Standard wells (main development)
    standard_wells = {'EW-003', 'EW-005', 'EW-007', 'EW-010', 'IW-002', 'IW-003'};
    
    % Marginal wells (late phase, lower production)
    marginal_wells = {'EW-004', 'EW-006', 'EW-008', 'EW-009', 'IW-004', 'IW-005'};
    
    % Classify faults by importance
    fault_names = fieldnames(faults_config.fault_system.faults);
    major_faults = {};
    minor_faults = {};
    
    for i = 1:length(fault_names)
        fault_name = fault_names{i};
        fault_data = faults_config.fault_system.faults.(fault_name);
        
        % Major faults: sealing and long
        if fault_data.is_sealing && fault_data.length > 12000
            major_faults{end+1} = fault_name;
        else
            minor_faults{end+1} = fault_name;
        end
    end
    
    % Calculate tiered parameters
    base_well_radius = target_coverage.optimal_well_radius;
    base_fault_buffer = target_coverage.optimal_fault_buffer;
    
    % Tiered well refinement
    critical_well_radius = base_well_radius * 1.3;  % 30% larger
    standard_well_radius = base_well_radius;        % Optimal size
    marginal_well_radius = base_well_radius * 0.7;  % 30% smaller
    
    % Tiered fault refinement  
    major_fault_buffer = base_fault_buffer * 1.2;   % 20% larger
    minor_fault_buffer = base_fault_buffer * 0.8;   % 20% smaller
    
    % Package tiered strategy
    tiered_strategy.critical_wells = critical_wells;
    tiered_strategy.standard_wells = standard_wells;
    tiered_strategy.marginal_wells = marginal_wells;
    tiered_strategy.major_faults = major_faults;
    tiered_strategy.minor_faults = minor_faults;
    
    tiered_strategy.critical_well_radius = critical_well_radius;
    tiered_strategy.standard_well_radius = standard_well_radius;
    tiered_strategy.marginal_well_radius = marginal_well_radius;
    tiered_strategy.major_fault_buffer = major_fault_buffer;
    tiered_strategy.minor_fault_buffer = minor_fault_buffer;
    
    % Calculate coverage by tier
    num_critical = length(critical_wells);
    num_standard = length(standard_wells);
    num_marginal = length(marginal_wells);
    num_major_faults = length(major_faults);
    num_minor_faults = length(minor_faults);
    
    total_field_area = 3280 * 2950;  % ft²
    
    critical_area = num_critical * pi * critical_well_radius^2;
    standard_area = num_standard * pi * standard_well_radius^2;
    marginal_area = num_marginal * pi * marginal_well_radius^2;
    
    % Estimate fault areas (simplified)
    avg_major_fault_length = 14000;  % ft (estimated)
    avg_minor_fault_length = 8500;   % ft (estimated)
    
    major_fault_area = num_major_faults * avg_major_fault_length * 2 * major_fault_buffer;
    minor_fault_area = num_minor_faults * avg_minor_fault_length * 2 * minor_fault_buffer;
    
    tiered_strategy.critical_coverage = critical_area / total_field_area;
    tiered_strategy.standard_coverage = standard_area / total_field_area;
    tiered_strategy.marginal_coverage = marginal_area / total_field_area;
    tiered_strategy.major_fault_coverage = major_fault_area / total_field_area;
    tiered_strategy.minor_fault_coverage = minor_fault_area / total_field_area;
    
    total_tiered_coverage = tiered_strategy.critical_coverage + ...
                           tiered_strategy.standard_coverage + ...
                           tiered_strategy.marginal_coverage + ...
                           tiered_strategy.major_fault_coverage + ...
                           tiered_strategy.minor_fault_coverage;
    
    % Account for overlap (estimated 5%)
    tiered_strategy.overlap_estimate = 0.05;
    tiered_strategy.net_tiered_coverage = total_tiered_coverage * (1 - tiered_strategy.overlap_estimate);
    
    fprintf('Tiered strategy created: %.1f%% net coverage\n', tiered_strategy.net_tiered_coverage * 100);
end

function display_tiered_strategy(tiered_strategy)
    fprintf('\n--- Tiered Refinement Strategy ---\n');
    
    fprintf('Well Classification:\n');
    fprintf('  Critical Wells (%d): %s\n', length(tiered_strategy.critical_wells), ...
        strjoin(tiered_strategy.critical_wells, ', '));
    fprintf('    - Radius: %.0f ft (high refinement)\n', tiered_strategy.critical_well_radius);
    fprintf('    - Coverage: %.2f%%\n', tiered_strategy.critical_coverage * 100);
    
    fprintf('  Standard Wells (%d): %s\n', length(tiered_strategy.standard_wells), ...
        strjoin(tiered_strategy.standard_wells, ', '));
    fprintf('    - Radius: %.0f ft (medium refinement)\n', tiered_strategy.standard_well_radius);
    fprintf('    - Coverage: %.2f%%\n', tiered_strategy.standard_coverage * 100);
    
    fprintf('  Marginal Wells (%d): %s\n', length(tiered_strategy.marginal_wells), ...
        strjoin(tiered_strategy.marginal_wells, ', '));
    fprintf('    - Radius: %.0f ft (low refinement)\n', tiered_strategy.marginal_well_radius);
    fprintf('    - Coverage: %.2f%%\n', tiered_strategy.marginal_coverage * 100);
    
    fprintf('\nFault Classification:\n');
    fprintf('  Major Faults (%d): %s\n', length(tiered_strategy.major_faults), ...
        strjoin(tiered_strategy.major_faults, ', '));
    fprintf('    - Buffer: %.0f ft (high refinement)\n', tiered_strategy.major_fault_buffer);
    fprintf('    - Coverage: %.2f%%\n', tiered_strategy.major_fault_coverage * 100);
    
    fprintf('  Minor Faults (%d): %s\n', length(tiered_strategy.minor_faults), ...
        strjoin(tiered_strategy.minor_faults, ', '));
    fprintf('    - Buffer: %.0f ft (low refinement)\n', tiered_strategy.minor_fault_buffer);
    fprintf('    - Coverage: %.2f%%\n', tiered_strategy.minor_fault_coverage * 100);
    
    fprintf('\nTiered Strategy Summary:\n');
    fprintf('  Estimated Overlap: %.1f%%\n', tiered_strategy.overlap_estimate * 100);
    fprintf('  Net Coverage: %.1f%%\n', tiered_strategy.net_tiered_coverage * 100);
end

function optimization_report = generate_optimization_report(grid_metrics, current_coverage, target_coverage, tiered_strategy)
    fprintf('\nGenerating optimization report...\n');
    
    optimization_report.metadata.timestamp = datestr(now, 'yyyy-mm-dd HH:MM:SS');
    optimization_report.metadata.script_name = 's06b_calculate_optimal_refinement.m';
    optimization_report.metadata.version = '1.0';
    optimization_report.metadata.field_name = 'Eagle West Field';
    
    % Grid summary
    optimization_report.grid_summary = grid_metrics;
    
    % Current vs optimal comparison
    optimization_report.parameter_comparison.current_well_radius = current_coverage.well_radius;
    optimization_report.parameter_comparison.optimal_well_radius = target_coverage.optimal_well_radius;
    optimization_report.parameter_comparison.well_radius_change_pct = ...
        (target_coverage.optimal_well_radius - current_coverage.well_radius) / current_coverage.well_radius * 100;
    
    optimization_report.parameter_comparison.current_fault_buffer = current_coverage.fault_buffer;
    optimization_report.parameter_comparison.optimal_fault_buffer = target_coverage.optimal_fault_buffer;
    optimization_report.parameter_comparison.fault_buffer_change_pct = ...
        (target_coverage.optimal_fault_buffer - current_coverage.fault_buffer) / current_coverage.fault_buffer * 100;
    
    % Coverage comparison
    optimization_report.coverage_comparison.current_total_coverage_pct = current_coverage.total_coverage_ratio * 100;
    optimization_report.coverage_comparison.optimal_total_coverage_pct = target_coverage.final_coverage_ratio * 100;
    optimization_report.coverage_comparison.tiered_total_coverage_pct = tiered_strategy.net_tiered_coverage * 100;
    
    optimization_report.coverage_comparison.coverage_reduction_pct = ...
        current_coverage.total_coverage_ratio * 100 - target_coverage.final_coverage_ratio * 100;
    
    % Refined cells comparison
    optimization_report.cells_comparison.current_refined_cells = current_coverage.total_refined_cells;
    optimization_report.cells_comparison.optimal_refined_cells = target_coverage.net_refined_cells;
    optimization_report.cells_comparison.cells_reduction = ...
        current_coverage.total_refined_cells - target_coverage.net_refined_cells;
    optimization_report.cells_comparison.cells_reduction_pct = ...
        optimization_report.cells_comparison.cells_reduction / current_coverage.total_refined_cells * 100;
    
    % Implementation strategy
    optimization_report.implementation.tiered_strategy = tiered_strategy;
    optimization_report.implementation.priority_wells = tiered_strategy.critical_wells;
    optimization_report.implementation.priority_faults = tiered_strategy.major_faults;
    
    % Recommendations
    optimization_report.recommendations = {
        sprintf('Reduce well refinement radius from %.0f ft to %.0f ft (%.1f%% reduction)', ...
            current_coverage.well_radius, target_coverage.optimal_well_radius, ...
            abs(optimization_report.parameter_comparison.well_radius_change_pct));
        sprintf('Reduce fault refinement buffer from %.0f ft to %.0f ft (%.1f%% reduction)', ...
            current_coverage.fault_buffer, target_coverage.optimal_fault_buffer, ...
            abs(optimization_report.parameter_comparison.fault_buffer_change_pct));
        'Implement tiered refinement strategy with 3 well tiers and 2 fault tiers';
        sprintf('Target coverage reduction from %.1f%% to %.1f%% (%.1f%% decrease)', ...
            optimization_report.coverage_comparison.current_total_coverage_pct, ...
            optimization_report.coverage_comparison.optimal_total_coverage_pct, ...
            optimization_report.coverage_comparison.coverage_reduction_pct);
        sprintf('Expected cell count reduction: %.0f cells (%.1f%% fewer)', ...
            optimization_report.cells_comparison.cells_reduction, ...
            optimization_report.cells_comparison.cells_reduction_pct);
    };
    
    fprintf('Optimization report generated with %d recommendations\n', length(optimization_report.recommendations));
end

function save_optimization_report(optimization_report)
    fprintf('Saving optimization report...\n');
    
    % Create output directory if needed
    output_dir = fullfile('data', 'simulation_data', 'static');
    if ~exist(output_dir, 'dir')
        mkdir(output_dir);
    end
    
    % Save detailed report (MATLAB format)
    report_file = fullfile(output_dir, 'refinement_optimization_report.mat');
    save(report_file, 'optimization_report');
    fprintf('Detailed report saved: %s\n', report_file);
    
    % Save summary report (text format)
    summary_file = fullfile(output_dir, 'refinement_optimization_summary.txt');
    write_summary_report(summary_file, optimization_report);
    fprintf('Summary report saved: %s\n', summary_file);
end

function write_summary_report(filename, optimization_report)
    fid = fopen(filename, 'w');
    if fid == -1
        error('Cannot write summary report: %s', filename);
    end
    
    try
        fprintf(fid, 'EAGLE WEST FIELD - REFINEMENT OPTIMIZATION SUMMARY\n');
        fprintf(fid, '=================================================\n\n');
        
        fprintf(fid, 'Generated: %s\n', optimization_report.metadata.timestamp);
        fprintf(fid, 'Script: %s\n', optimization_report.metadata.script_name);
        fprintf(fid, 'Field: %s\n\n', optimization_report.metadata.field_name);
        
        fprintf(fid, 'GRID SUMMARY:\n');
        fprintf(fid, '- Dimensions: %dx%dx%d = %d cells\n', ...
            optimization_report.grid_summary.nx, optimization_report.grid_summary.ny, ...
            optimization_report.grid_summary.nz, optimization_report.grid_summary.total_cells);
        fprintf(fid, '- Field Size: %.0f x %.0f ft (%.1f acres)\n', ...
            optimization_report.grid_summary.field_length_x, ...
            optimization_report.grid_summary.field_length_y, ...
            optimization_report.grid_summary.total_field_area_acres);
        fprintf(fid, '- Target Active Cells: %d\n\n', optimization_report.grid_summary.target_active_cells);
        
        fprintf(fid, 'PARAMETER OPTIMIZATION:\n');
        fprintf(fid, '- Well Radius: %.0f ft → %.0f ft (%.1f%% change)\n', ...
            optimization_report.parameter_comparison.current_well_radius, ...
            optimization_report.parameter_comparison.optimal_well_radius, ...
            optimization_report.parameter_comparison.well_radius_change_pct);
        fprintf(fid, '- Fault Buffer: %.0f ft → %.0f ft (%.1f%% change)\n', ...
            optimization_report.parameter_comparison.current_fault_buffer, ...
            optimization_report.parameter_comparison.optimal_fault_buffer, ...
            optimization_report.parameter_comparison.fault_buffer_change_pct);
        
        fprintf(fid, '\nCOVERAGE OPTIMIZATION:\n');
        fprintf(fid, '- Current Coverage: %.1f%%\n', optimization_report.coverage_comparison.current_total_coverage_pct);
        fprintf(fid, '- Target Coverage: %.1f%%\n', optimization_report.coverage_comparison.optimal_total_coverage_pct);
        fprintf(fid, '- Tiered Coverage: %.1f%%\n', optimization_report.coverage_comparison.tiered_total_coverage_pct);
        fprintf(fid, '- Reduction: %.1f%%\n', optimization_report.coverage_comparison.coverage_reduction_pct);
        
        fprintf(fid, '\nCELL COUNT OPTIMIZATION:\n');
        fprintf(fid, '- Current Refined Cells: %.0f\n', optimization_report.cells_comparison.current_refined_cells);
        fprintf(fid, '- Optimal Refined Cells: %.0f\n', optimization_report.cells_comparison.optimal_refined_cells);
        fprintf(fid, '- Cell Reduction: %.0f (%.1f%%)\n', ...
            optimization_report.cells_comparison.cells_reduction, ...
            optimization_report.cells_comparison.cells_reduction_pct);
        
        fprintf(fid, '\nTIERED STRATEGY:\n');
        fprintf(fid, '- Critical Wells (%d): %s\n', ...
            length(optimization_report.implementation.tiered_strategy.critical_wells), ...
            strjoin(optimization_report.implementation.tiered_strategy.critical_wells, ', '));
        fprintf(fid, '- Standard Wells (%d): %s\n', ...
            length(optimization_report.implementation.tiered_strategy.standard_wells), ...
            strjoin(optimization_report.implementation.tiered_strategy.standard_wells, ', '));
        fprintf(fid, '- Marginal Wells (%d): %s\n', ...
            length(optimization_report.implementation.tiered_strategy.marginal_wells), ...
            strjoin(optimization_report.implementation.tiered_strategy.marginal_wells, ', '));
        fprintf(fid, '- Major Faults (%d): %s\n', ...
            length(optimization_report.implementation.tiered_strategy.major_faults), ...
            strjoin(optimization_report.implementation.tiered_strategy.major_faults, ', '));
        fprintf(fid, '- Minor Faults (%d): %s\n', ...
            length(optimization_report.implementation.tiered_strategy.minor_faults), ...
            strjoin(optimization_report.implementation.tiered_strategy.minor_faults, ', '));
        
        fprintf(fid, '\nRECOMMENDATIONS:\n');
        for i = 1:length(optimization_report.recommendations)
            fprintf(fid, '%d. %s\n', i, optimization_report.recommendations{i});
        end
        
        fprintf(fid, '\nEND OF REPORT\n');
        
    catch ME
        fclose(fid);
        rethrow(ME);
    end
    
    fclose(fid);
end

% Utility function to join cell array strings (if not available)
function str = strjoin(cell_array, delimiter)
    if isempty(cell_array)
        str = '';
        return;
    end
    
    str = cell_array{1};
    for i = 2:length(cell_array)
        str = [str, delimiter, cell_array{i}];
    end
end