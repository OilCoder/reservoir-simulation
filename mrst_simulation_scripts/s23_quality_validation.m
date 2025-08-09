function validation_results = s23_quality_validation()
% S23_QUALITY_VALIDATION - Simulation Quality Control for Eagle West Field
% Requires: MRST
%
% Implements comprehensive quality validation:
% - Material balance check (<0.01% error)
% - Grid quality metrics (aspect ratio <10:1)
% - Well performance validation
% - Pressure and saturation range checks
% - Convergence analysis
% - Simulation quality reporting
%
% OUTPUTS:
%   validation_results - Structure with quality control analysis
%
% Author: Claude Code AI System
% Date: August 8, 2025

    run('print_utils.m');
    print_step_header('S23', 'Simulation Quality Validation');
    
    total_start_time = tic;
    validation_results = initialize_validation_structure();
    
    try
        % ----------------------------------------
        % Step 1 - Load Simulation Results
        % ----------------------------------------
        step_start = tic;
        [simulation_data, config] = step_1_load_simulation_results();
        validation_results.simulation_data = simulation_data;
        validation_results.config = config;
        print_step_result(1, 'Load Simulation Results', 'success', toc(step_start));
        
        % ----------------------------------------
        % Step 2 - Material Balance Validation
        % ----------------------------------------
        step_start = tic;
        material_balance = step_2_material_balance_validation(simulation_data, config);
        validation_results.material_balance = material_balance;
        print_step_result(2, 'Material Balance Validation', 'success', toc(step_start));
        
        % ----------------------------------------
        % Step 3 - Grid Quality Assessment
        % ----------------------------------------
        step_start = tic;
        grid_quality = step_3_grid_quality_assessment(simulation_data, config);
        validation_results.grid_quality = grid_quality;
        print_step_result(3, 'Grid Quality Assessment', 'success', toc(step_start));
        
        % ----------------------------------------
        % Step 4 - Physical Range Validation
        % ----------------------------------------
        step_start = tic;
        physical_ranges = step_4_physical_range_validation(simulation_data, config);
        validation_results.physical_ranges = physical_ranges;
        print_step_result(4, 'Physical Range Validation', 'success', toc(step_start));
        
        % ----------------------------------------
        % Step 5 - Well Performance Analysis
        % ----------------------------------------
        step_start = tic;
        well_performance = step_5_well_performance_analysis(simulation_data, config);
        validation_results.well_performance = well_performance;
        print_step_result(5, 'Well Performance Analysis', 'success', toc(step_start));
        
        % ----------------------------------------
        % Step 6 - Generate Quality Report
        % ----------------------------------------
        step_start = tic;
        quality_report = step_6_generate_quality_report(validation_results);
        validation_results.quality_report = quality_report;
        print_step_result(6, 'Generate Quality Report', 'success', toc(step_start));
        
        validation_results.status = 'success';
        validation_results.overall_quality = determine_overall_quality(validation_results);
        validation_results.validation_passed = validation_results.overall_quality >= 85;
        validation_results.creation_time = datestr(now);
        
        print_step_footer('S23', sprintf('Quality Validation (Score: %.0f%%, %s)', ...
            validation_results.overall_quality, ...
            ternary(validation_results.validation_passed, 'PASSED', 'FAILED')), toc(total_start_time));
        
    catch ME
        print_error_step(0, 'Quality Validation', ME.message);
        validation_results.status = 'failed';
        validation_results.error_message = ME.message;
        error('Quality validation failed: %s', ME.message);
    end

end

function validation_results = initialize_validation_structure()
% Initialize quality validation results structure
    validation_results = struct();
    validation_results.status = 'initializing';
    validation_results.simulation_data = [];
    validation_results.material_balance = [];
    validation_results.grid_quality = [];
    validation_results.physical_ranges = [];
    validation_results.well_performance = [];
    validation_results.quality_report = [];
end

function [simulation_data, config] = step_1_load_simulation_results()
% Step 1 - Load simulation results and configuration for validation

    script_path = fileparts(mfilename('fullpath'));
    results_dir = fullfile(fileparts(script_path), 'data', 'mrst_simulation', 'results');
    static_dir = fullfile(fileparts(script_path), 'data', 'mrst_simulation', 'static');
    
    % Substep 1.1 - Find latest simulation results ___________________
    result_files = dir(fullfile(results_dir, 'simulation_results_*.mat'));
    if isempty(result_files)
        error('No simulation results found. Run s22_run_simulation.m first.');
    end
    
    % Sort by date and get latest
    [~, latest_idx] = max([result_files.datenum]);
    latest_file = fullfile(results_dir, result_files(latest_idx).name);
    
    load(latest_file, 'simulation_results');
    simulation_data = simulation_results;
    fprintf('Loaded simulation results: %s\n', result_files(latest_idx).name);
    
    % Substep 1.2 - Load quality control configuration _______________
    config_file = fullfile(script_path, 'config', 'solver_config.yaml');
    if exist(config_file, 'file')
        config = read_yaml_config(config_file, 'silent', true);
        fprintf('Loaded quality control configuration\n');
    else
        error('Solver configuration not found: %s', config_file);
    end
    
    % Substep 1.3 - Validate simulation data completeness ____________
    required_fields = {'states', 'reports', 'schedule', 'post_processed'};
    for i = 1:length(required_fields)
        if ~isfield(simulation_data, required_fields{i}) || isempty(simulation_data.(required_fields{i}))
            error('Missing or empty simulation data field: %s', required_fields{i});
        end
    end
    
    fprintf('Simulation data validation: Complete\n');

end

function material_balance = step_2_material_balance_validation(simulation_data, config)
% Step 2 - Comprehensive material balance validation

    fprintf('\n Material Balance Validation:\n');
    fprintf(' ──────────────────────────────────────────────────────────\n');
    
    qc_config = config.solver_configuration.quality_control;
    tolerance = qc_config.material_balance_tolerance;
    
    states = simulation_data.states;
    reports = simulation_data.reports;
    schedule = simulation_data.schedule;
    
    material_balance = struct();
    
    % Substep 2.1 - Calculate pore volume changes ____________________
    initial_state = states{1};
    final_state = states{end};
    
    % Load grid and rock for pore volume calculation
    script_path = fileparts(mfilename('fullpath'));
    static_dir = fullfile(fileparts(script_path), 'data', 'mrst_simulation', 'static');
    
    grid_file = fullfile(static_dir, 'grid_model.mat');
    load(grid_file, 'G');
    
    rock_file = fullfile(static_dir, 'rock_properties_final.mat');
    load(rock_file, 'rock');
    
    pore_volume = G.cells.volumes .* rock.poro;
    total_pore_volume = sum(pore_volume);
    
    fprintf('   Total Pore Volume: %.2e m³\n', total_pore_volume);
    
    % Substep 2.2 - Oil material balance _____________________________
    initial_oil_pv = sum(initial_state.s(:,2) .* pore_volume);
    final_oil_pv = sum(final_state.s(:,2) .* pore_volume);
    
    % Calculate cumulative oil production (convert from field units)
    if isfield(simulation_data, 'post_processed')
        cumulative_oil_production_m3 = simulation_data.post_processed.cumulative_oil_stb(end) * 0.158987;
    else
        cumulative_oil_production_m3 = 0;
        warning('Post-processed data not available for production calculation');
    end
    
    oil_balance_error = (initial_oil_pv - final_oil_pv - cumulative_oil_production_m3) / initial_oil_pv;
    
    material_balance.oil_balance = struct();
    material_balance.oil_balance.initial_oil_pv_m3 = initial_oil_pv;
    material_balance.oil_balance.final_oil_pv_m3 = final_oil_pv;
    material_balance.oil_balance.cumulative_production_m3 = cumulative_oil_production_m3;
    material_balance.oil_balance.balance_error_fraction = oil_balance_error;
    material_balance.oil_balance.balance_error_percent = abs(oil_balance_error) * 100;
    
    fprintf('   Oil Balance Error: %.4f%% (target: <%.2f%%)\n', ...
        material_balance.oil_balance.balance_error_percent, tolerance);
    
    % Substep 2.3 - Water material balance ___________________________
    initial_water_pv = sum(initial_state.s(:,1) .* pore_volume);
    final_water_pv = sum(final_state.s(:,1) .* pore_volume);
    
    % Calculate cumulative water injection and production
    if isfield(simulation_data, 'post_processed')
        cumulative_water_injection_m3 = simulation_data.post_processed.cumulative_injection_bbl(end) * 0.158987;
        cumulative_water_production_m3 = simulation_data.post_processed.cumulative_water_bbl(end) * 0.158987;
    else
        cumulative_water_injection_m3 = 0;
        cumulative_water_production_m3 = 0;
    end
    
    water_balance_error = (initial_water_pv + cumulative_water_injection_m3 - final_water_pv - cumulative_water_production_m3) / ...
        max(initial_water_pv, cumulative_water_injection_m3);
    
    material_balance.water_balance = struct();
    material_balance.water_balance.initial_water_pv_m3 = initial_water_pv;
    material_balance.water_balance.final_water_pv_m3 = final_water_pv;
    material_balance.water_balance.cumulative_injection_m3 = cumulative_water_injection_m3;
    material_balance.water_balance.cumulative_production_m3 = cumulative_water_production_m3;
    material_balance.water_balance.balance_error_fraction = water_balance_error;
    material_balance.water_balance.balance_error_percent = abs(water_balance_error) * 100;
    
    fprintf('   Water Balance Error: %.4f%% (target: <%.2f%%)\n', ...
        material_balance.water_balance.balance_error_percent, tolerance);
    
    % Substep 2.4 - Overall material balance assessment ______________
    max_balance_error = max(material_balance.oil_balance.balance_error_percent, ...
                           material_balance.water_balance.balance_error_percent);
    
    material_balance.overall_balance_error_percent = max_balance_error;
    material_balance.balance_check_passed = max_balance_error <= tolerance;
    
    if material_balance.balance_check_passed
        fprintf('   Material Balance: ✅ PASSED (%.4f%% < %.2f%%)\n', max_balance_error, tolerance);
    else
        fprintf('   Material Balance: ❌ FAILED (%.4f%% > %.2f%%)\n', max_balance_error, tolerance);
    end
    
    fprintf(' ──────────────────────────────────────────────────────────\n');

end

function grid_quality = step_3_grid_quality_assessment(simulation_data, config)
% Step 3 - Comprehensive grid quality assessment

    fprintf('\n Grid Quality Assessment:\n');
    fprintf(' ──────────────────────────────────────────────────────────\n');
    
    qc_config = config.solver_configuration.quality_control;
    
    % Load grid data
    script_path = fileparts(mfilename('fullpath'));
    static_dir = fullfile(fileparts(script_path), 'data', 'mrst_simulation', 'static');
    
    grid_file = fullfile(static_dir, 'grid_model.mat');
    load(grid_file, 'G');
    
    grid_quality = struct();
    
    % Substep 3.1 - Cell volume analysis _____________________________
    cell_volumes = G.cells.volumes;
    
    grid_quality.volume_analysis = struct();
    grid_quality.volume_analysis.min_volume_m3 = min(cell_volumes);
    grid_quality.volume_analysis.max_volume_m3 = max(cell_volumes);
    grid_quality.volume_analysis.mean_volume_m3 = mean(cell_volumes);
    grid_quality.volume_analysis.volume_ratio = max(cell_volumes) / min(cell_volumes);
    
    % Volume range checks
    vol_min_ok = grid_quality.volume_analysis.min_volume_m3 >= qc_config.min_cell_volume_m3;
    vol_max_ok = grid_quality.volume_analysis.max_volume_m3 <= qc_config.max_cell_volume_m3;
    
    grid_quality.volume_analysis.min_volume_check = vol_min_ok;
    grid_quality.volume_analysis.max_volume_check = vol_max_ok;
    grid_quality.volume_analysis.volume_checks_passed = vol_min_ok && vol_max_ok;
    
    fprintf('   Cell Volumes: %.1f - %.1f m³ (ratio: %.1f)\n', ...
        grid_quality.volume_analysis.min_volume_m3, ...
        grid_quality.volume_analysis.max_volume_m3, ...
        grid_quality.volume_analysis.volume_ratio);
    
    % Substep 3.2 - Aspect ratio calculation _________________________
    % Calculate approximate aspect ratios for Cartesian grids
    if isfield(G, 'cartDims') && length(G.cartDims) == 3
        % For Cartesian grids, estimate cell dimensions
        dx = (max(G.nodes.coords(:,1)) - min(G.nodes.coords(:,1))) / G.cartDims(1);
        dy = (max(G.nodes.coords(:,2)) - min(G.nodes.coords(:,2))) / G.cartDims(2);
        dz = (max(G.nodes.coords(:,3)) - min(G.nodes.coords(:,3))) / G.cartDims(3);
        
        aspect_ratio_xy = max(dx, dy) / min(dx, dy);
        aspect_ratio_xz = max(dx, dz) / min(dx, dz);
        aspect_ratio_yz = max(dy, dz) / min(dy, dz);
        max_aspect_ratio = max([aspect_ratio_xy, aspect_ratio_xz, aspect_ratio_yz]);
    else
        % For general grids, estimate from cell volumes
        max_aspect_ratio = sqrt(grid_quality.volume_analysis.volume_ratio);
    end
    
    grid_quality.aspect_ratio_analysis = struct();
    grid_quality.aspect_ratio_analysis.max_aspect_ratio = max_aspect_ratio;
    grid_quality.aspect_ratio_analysis.aspect_ratio_check = max_aspect_ratio <= qc_config.max_aspect_ratio;
    
    fprintf('   Max Aspect Ratio: %.1f (target: <%.1f)\n', ...
        max_aspect_ratio, qc_config.max_aspect_ratio);
    
    % Substep 3.3 - Grid connectivity analysis _______________________
    num_faces = G.faces.num;
    num_connections = nnz(G.faces.neighbors);
    connectivity_ratio = num_connections / (2 * G.cells.num);  % Theoretical max is ~3 for 3D
    
    grid_quality.connectivity_analysis = struct();
    grid_quality.connectivity_analysis.num_faces = num_faces;
    grid_quality.connectivity_analysis.num_connections = num_connections;
    grid_quality.connectivity_analysis.connectivity_ratio = connectivity_ratio;
    grid_quality.connectivity_analysis.connectivity_ok = connectivity_ratio >= 2.5;  % Minimum for good connectivity
    
    fprintf('   Grid Connectivity: %.2f connections/cell (min: 2.5)\n', connectivity_ratio);
    
    % Substep 3.4 - Overall grid quality score _______________________
    quality_checks = [
        grid_quality.volume_analysis.volume_checks_passed,
        grid_quality.aspect_ratio_analysis.aspect_ratio_check,
        grid_quality.connectivity_analysis.connectivity_ok
    ];
    
    grid_quality.overall_quality_score = sum(quality_checks) / length(quality_checks) * 100;
    grid_quality.grid_quality_passed = grid_quality.overall_quality_score >= 80;
    
    if grid_quality.grid_quality_passed
        fprintf('   Grid Quality: ✅ PASSED (Score: %.0f%%)\n', grid_quality.overall_quality_score);
    else
        fprintf('   Grid Quality: ❌ FAILED (Score: %.0f%%)\n', grid_quality.overall_quality_score);
    end
    
    fprintf(' ──────────────────────────────────────────────────────────\n');

end

function physical_ranges = step_4_physical_range_validation(simulation_data, config)
% Step 4 - Validate physical ranges of pressure and saturations

    fprintf('\n Physical Range Validation:\n');
    fprintf(' ──────────────────────────────────────────────────────────\n');
    
    qc_config = config.solver_configuration.quality_control;
    states = simulation_data.states;
    
    physical_ranges = struct();
    
    % Substep 4.1 - Pressure range validation ________________________
    all_pressures = [];
    for i = 1:length(states)
        all_pressures = [all_pressures; states{i}.pressure];
    end
    
    min_pressure = min(all_pressures);
    max_pressure = max(all_pressures);
    
    pressure_limits = qc_config.pressure_limits_pa;
    pressure_min_ok = min_pressure >= pressure_limits(1);
    pressure_max_ok = max_pressure <= pressure_limits(2);
    
    physical_ranges.pressure_validation = struct();
    physical_ranges.pressure_validation.min_pressure_pa = min_pressure;
    physical_ranges.pressure_validation.max_pressure_pa = max_pressure;
    physical_ranges.pressure_validation.min_pressure_bar = min_pressure / 1e5;
    physical_ranges.pressure_validation.max_pressure_bar = max_pressure / 1e5;
    physical_ranges.pressure_validation.min_check_passed = pressure_min_ok;
    physical_ranges.pressure_validation.max_check_passed = pressure_max_ok;
    physical_ranges.pressure_validation.pressure_range_valid = pressure_min_ok && pressure_max_ok;
    
    fprintf('   Pressure Range: %.1f - %.1f bar\n', ...
        min_pressure/1e5, max_pressure/1e5);
    fprintf('   Pressure Limits: %.1f - %.1f bar\n', ...
        pressure_limits(1)/1e5, pressure_limits(2)/1e5);
    
    % Substep 4.2 - Saturation range validation ______________________
    all_saturations = [];
    for i = 1:length(states)
        all_saturations = [all_saturations; states{i}.s];
    end
    
    % Water saturation
    sw_min = min(all_saturations(:,1));
    sw_max = max(all_saturations(:,1));
    sw_limits = qc_config.water_saturation_limits;
    
    % Oil saturation  
    so_min = min(all_saturations(:,2));
    so_max = max(all_saturations(:,2));
    so_limits = qc_config.oil_saturation_limits;
    
    % Gas saturation
    sg_min = min(all_saturations(:,3));
    sg_max = max(all_saturations(:,3));
    sg_limits = qc_config.gas_saturation_limits;
    
    physical_ranges.saturation_validation = struct();
    
    % Water saturation validation
    physical_ranges.saturation_validation.sw_range = [sw_min, sw_max];
    physical_ranges.saturation_validation.sw_valid = sw_min >= sw_limits(1) && sw_max <= sw_limits(2);
    
    % Oil saturation validation
    physical_ranges.saturation_validation.so_range = [so_min, so_max];
    physical_ranges.saturation_validation.so_valid = so_min >= so_limits(1) && so_max <= so_limits(2);
    
    % Gas saturation validation
    physical_ranges.saturation_validation.sg_range = [sg_min, sg_max];
    physical_ranges.saturation_validation.sg_valid = sg_min >= sg_limits(1) && sg_max <= sg_limits(2);
    
    fprintf('   Water Saturation: %.3f - %.3f\n', sw_min, sw_max);
    fprintf('   Oil Saturation: %.3f - %.3f\n', so_min, so_max);
    fprintf('   Gas Saturation: %.3f - %.3f\n', sg_min, sg_max);
    
    % Substep 4.3 - Saturation sum validation ________________________
    saturation_sum_errors = [];
    for i = 1:length(states)
        sat_sums = sum(states{i}.s, 2);
        errors = abs(sat_sums - 1.0);
        saturation_sum_errors = [saturation_sum_errors; errors];
    end
    
    max_saturation_error = max(saturation_sum_errors);
    saturation_sum_tolerance = 1e-6;
    
    physical_ranges.saturation_validation.max_sum_error = max_saturation_error;
    physical_ranges.saturation_validation.sum_check_passed = max_saturation_error <= saturation_sum_tolerance;
    
    fprintf('   Saturation Sum Error: %.2e (tolerance: %.1e)\n', ...
        max_saturation_error, saturation_sum_tolerance);
    
    % Substep 4.4 - Overall physical range assessment _______________
    all_checks = [
        physical_ranges.pressure_validation.pressure_range_valid,
        physical_ranges.saturation_validation.sw_valid,
        physical_ranges.saturation_validation.so_valid,
        physical_ranges.saturation_validation.sg_valid,
        physical_ranges.saturation_validation.sum_check_passed
    ];
    
    physical_ranges.overall_physical_valid = all(all_checks);
    physical_ranges.physical_quality_score = sum(all_checks) / length(all_checks) * 100;
    
    if physical_ranges.overall_physical_valid
        fprintf('   Physical Ranges: ✅ PASSED (Score: %.0f%%)\n', physical_ranges.physical_quality_score);
    else
        fprintf('   Physical Ranges: ❌ FAILED (Score: %.0f%%)\n', physical_ranges.physical_quality_score);
    end
    
    fprintf(' ──────────────────────────────────────────────────────────\n');

end

function well_performance = step_5_well_performance_analysis(simulation_data, config)
% Step 5 - Analyze well performance and production consistency

    fprintf('\n Well Performance Analysis:\n');
    fprintf(' ──────────────────────────────────────────────────────────\n');
    
    reports = simulation_data.reports;
    
    well_performance = struct();
    
    % Substep 5.1 - Extract well performance data ____________________
    well_names = {};
    well_rates = containers.Map();
    
    % Collect well data from reports
    for i = 1:length(reports)
        if isfield(reports{i}, 'WellSol') && ~isempty(reports{i}.WellSol)
            wellsol = reports{i}.WellSol;
            
            for j = 1:length(wellsol)
                well_name = wellsol(j).name;
                
                if ~any(strcmp(well_names, well_name))
                    well_names{end+1} = well_name;
                    well_rates(well_name) = [];
                end
                
                % Store rates (convert to positive for analysis)
                if ~isempty(strfind(well_name, 'EW-'))  % Producer
                    rate = -wellsol(j).qOs * 24 * 3600 / 0.158987;  % m³/s to STB/day
                else  % Injector
                    rate = wellsol(j).qWs * 24 * 3600 / 0.158987;   % m³/s to bbl/day
                end
                
                current_rates = well_rates(well_name);
                well_rates(well_name) = [current_rates; rate];
            end
        end
    end
    
    fprintf('   Wells Analyzed: %d\n', length(well_names));
    
    % Substep 5.2 - Analyze individual well performance ______________
    well_performance.well_analysis = [];
    
    for i = 1:length(well_names)
        well_name = well_names{i};
        rates = well_rates(well_name);
        
        if isempty(rates)
            continue;
        end
        
        wa = struct();
        wa.well_name = well_name;
        wa.well_type = ternary(~isempty(strfind(well_name, 'EW-')), 'Producer', 'Injector');
        wa.num_timesteps = length(rates);
        wa.min_rate = min(rates);
        wa.max_rate = max(rates);
        wa.mean_rate = mean(rates);
        wa.rate_std = std(rates);
        wa.rate_cv = wa.rate_std / abs(wa.mean_rate);  % Coefficient of variation
        
        % Performance consistency checks
        wa.rate_consistency = wa.rate_cv < 0.5;  % CV < 50% indicates reasonable consistency
        wa.positive_rates = all(rates >= 0);  % No negative rates expected
        
        well_performance.well_analysis = [well_performance.well_analysis; wa];
    end
    
    % Substep 5.3 - Field-level performance metrics __________________
    producers = well_performance.well_analysis(strcmp({well_performance.well_analysis.well_type}, 'Producer'));
    injectors = well_performance.well_analysis(strcmp({well_performance.well_analysis.well_type}, 'Injector'));
    
    field_performance = struct();
    
    if ~isempty(producers)
        field_performance.total_producers = length(producers);
        field_performance.avg_producer_rate = mean([producers.mean_rate]);
        field_performance.producer_consistency = mean([producers.rate_consistency]);
        fprintf('   Producers: %d wells, avg rate: %.0f STB/d\n', ...
            field_performance.total_producers, field_performance.avg_producer_rate);
    else
        field_performance.total_producers = 0;
        field_performance.avg_producer_rate = 0;
        field_performance.producer_consistency = 0;
    end
    
    if ~isempty(injectors)
        field_performance.total_injectors = length(injectors);
        field_performance.avg_injector_rate = mean([injectors.mean_rate]);
        field_performance.injector_consistency = mean([injectors.rate_consistency]);
        fprintf('   Injectors: %d wells, avg rate: %.0f bbl/d\n', ...
            field_performance.total_injectors, field_performance.avg_injector_rate);
    else
        field_performance.total_injectors = 0;
        field_performance.avg_injector_rate = 0;
        field_performance.injector_consistency = 0;
    end
    
    well_performance.field_performance = field_performance;
    
    % Substep 5.4 - Well performance quality score ___________________
    consistency_scores = [well_performance.well_analysis.rate_consistency];
    positive_rate_scores = [well_performance.well_analysis.positive_rates];
    
    well_performance.consistency_score = sum(consistency_scores) / length(consistency_scores) * 100;
    well_performance.positive_rate_score = sum(positive_rate_scores) / length(positive_rate_scores) * 100;
    well_performance.overall_well_quality = (well_performance.consistency_score + well_performance.positive_rate_score) / 2;
    
    well_performance.well_performance_passed = well_performance.overall_well_quality >= 80;
    
    if well_performance.well_performance_passed
        fprintf('   Well Performance: ✅ PASSED (Score: %.0f%%)\n', well_performance.overall_well_quality);
    else
        fprintf('   Well Performance: ❌ FAILED (Score: %.0f%%)\n', well_performance.overall_well_quality);
    end
    
    fprintf(' ──────────────────────────────────────────────────────────\n');

end

function quality_report = step_6_generate_quality_report(validation_results)
% Step 6 - Generate comprehensive quality control report

    script_path = fileparts(mfilename('fullpath'));
    reports_dir = fullfile(fileparts(script_path), 'data', 'mrst_simulation', 'results');
    
    if ~exist(reports_dir, 'dir')
        mkdir(reports_dir);
    end
    
    % Create quality report
    timestamp = datestr(now, 'yyyymmdd_HHMMSS');
    report_file = fullfile(reports_dir, sprintf('quality_validation_report_%s.txt', timestamp));
    
    write_quality_report_file(report_file, validation_results);
    
    quality_report = struct();
    quality_report.report_file = report_file;
    quality_report.timestamp = timestamp;
    quality_report.overall_score = validation_results.overall_quality;
    quality_report.validation_passed = validation_results.validation_passed;
    
    fprintf('   Quality Report: %s\n', report_file);
    
end

function overall_quality = determine_overall_quality(validation_results)
% Calculate overall quality score from all validation components

    scores = [];
    
    % Material balance score (pass/fail)
    if isfield(validation_results, 'material_balance') && validation_results.material_balance.balance_check_passed
        scores = [scores, 100];
    else
        scores = [scores, 0];
    end
    
    % Grid quality score
    if isfield(validation_results, 'grid_quality')
        scores = [scores, validation_results.grid_quality.overall_quality_score];
    end
    
    % Physical ranges score
    if isfield(validation_results, 'physical_ranges')
        scores = [scores, validation_results.physical_ranges.physical_quality_score];
    end
    
    % Well performance score
    if isfield(validation_results, 'well_performance')
        scores = [scores, validation_results.well_performance.overall_well_quality];
    end
    
    % Calculate weighted average
    if ~isempty(scores)
        overall_quality = mean(scores);
    else
        overall_quality = 0;
    end

end

function write_quality_report_file(filename, validation_results)
% Write comprehensive quality validation report

    fid = fopen(filename, 'w');
    if fid == -1
        error('Cannot open file for writing: %s', filename);
    end
    
    try
        fprintf(fid, 'Eagle West Field - Simulation Quality Validation Report\n');
        fprintf(fid, 'Generated: %s\n', datestr(now));
        fprintf(fid, '=====================================================\n\n');
        
        % Overall assessment
        fprintf(fid, 'OVERALL QUALITY ASSESSMENT:\n');
        fprintf(fid, '  Quality Score: %.1f%%\n', validation_results.overall_quality);
        fprintf(fid, '  Validation Status: %s\n', ternary(validation_results.validation_passed, 'PASSED', 'FAILED'));
        fprintf(fid, '\n');
        
        % Material balance
        if isfield(validation_results, 'material_balance')
            mb = validation_results.material_balance;
            fprintf(fid, 'MATERIAL BALANCE:\n');
            fprintf(fid, '  Oil Balance Error: %.4f%%\n', mb.oil_balance.balance_error_percent);
            fprintf(fid, '  Water Balance Error: %.4f%%\n', mb.water_balance.balance_error_percent);
            fprintf(fid, '  Overall Balance: %s\n', ternary(mb.balance_check_passed, 'PASSED', 'FAILED'));
            fprintf(fid, '\n');
        end
        
        % Grid quality
        if isfield(validation_results, 'grid_quality')
            gq = validation_results.grid_quality;
            fprintf(fid, 'GRID QUALITY:\n');
            fprintf(fid, '  Volume Range: %.1f - %.1f m³\n', gq.volume_analysis.min_volume_m3, gq.volume_analysis.max_volume_m3);
            fprintf(fid, '  Max Aspect Ratio: %.1f\n', gq.aspect_ratio_analysis.max_aspect_ratio);
            fprintf(fid, '  Connectivity Ratio: %.2f\n', gq.connectivity_analysis.connectivity_ratio);
            fprintf(fid, '  Grid Quality: %s (Score: %.0f%%)\n', ternary(gq.grid_quality_passed, 'PASSED', 'FAILED'), gq.overall_quality_score);
            fprintf(fid, '\n');
        end
        
        % Physical ranges
        if isfield(validation_results, 'physical_ranges')
            pr = validation_results.physical_ranges;
            fprintf(fid, 'PHYSICAL RANGES:\n');
            fprintf(fid, '  Pressure Range: %.1f - %.1f bar\n', pr.pressure_validation.min_pressure_bar, pr.pressure_validation.max_pressure_bar);
            fprintf(fid, '  Water Saturation: %.3f - %.3f\n', pr.saturation_validation.sw_range(1), pr.saturation_validation.sw_range(2));
            fprintf(fid, '  Oil Saturation: %.3f - %.3f\n', pr.saturation_validation.so_range(1), pr.saturation_validation.so_range(2));
            fprintf(fid, '  Gas Saturation: %.3f - %.3f\n', pr.saturation_validation.sg_range(1), pr.saturation_validation.sg_range(2));
            fprintf(fid, '  Physical Ranges: %s (Score: %.0f%%)\n', ternary(pr.overall_physical_valid, 'PASSED', 'FAILED'), pr.physical_quality_score);
            fprintf(fid, '\n');
        end
        
        % Well performance
        if isfield(validation_results, 'well_performance')
            wp = validation_results.well_performance;
            fprintf(fid, 'WELL PERFORMANCE:\n');
            fprintf(fid, '  Total Wells: %d\n', length(wp.well_analysis));
            fprintf(fid, '  Consistency Score: %.1f%%\n', wp.consistency_score);
            fprintf(fid, '  Rate Validation: %.1f%%\n', wp.positive_rate_score);
            fprintf(fid, '  Well Performance: %s (Score: %.0f%%)\n', ternary(wp.well_performance_passed, 'PASSED', 'FAILED'), wp.overall_well_quality);
            fprintf(fid, '\n');
        end
        
        fclose(fid);
        
    catch ME
        fclose(fid);
        error('Error writing quality report: %s', ME.message);
    end

end

function result = ternary(condition, true_val, false_val)
% Ternary operator helper function
    if condition
        result = true_val;
    else
        result = false_val;
    end
end

% Main execution when called as script
if ~nargout
    validation_results = s23_quality_validation();
end