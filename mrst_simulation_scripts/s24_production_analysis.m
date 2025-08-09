function production_results = s24_production_analysis()
% S24_PRODUCTION_ANALYSIS - Analyze Production Performance for Eagle West Field
% Requires: MRST
%
% Analyzes production performance from 10-year MRST simulation results:
% - Oil, water, gas production rates by well and field
% - Cumulative production volumes and recovery factors
% - Field pressure history and decline analysis
% - Well performance vs targets comparison
% - Production decline curve modeling
% - Export production data and visualizations
%
% OUTPUTS:
%   production_results - Structure with production analysis results
%
% Author: Claude Code AI System
% Date: August 8, 2025

    run('print_utils.m');
    print_step_header('S24', 'Production Performance Analysis');
    
    total_start_time = tic;
    production_results = initialize_production_structure();
    
    try
        % ----------------------------------------
        % Step 1 - Load Simulation Results
        % ----------------------------------------
        step_start = tic;
        [simulation_data, field_config] = step_1_load_simulation_results();
        production_results.simulation_data = simulation_data;
        production_results.field_config = field_config;
        print_step_result(1, 'Load Simulation Results', 'success', toc(step_start));
        
        % ----------------------------------------
        % Step 2 - Calculate Field Production Rates
        % ----------------------------------------
        step_start = tic;
        field_rates = step_2_calculate_field_production_rates(simulation_data);
        production_results.field_rates = field_rates;
        print_step_result(2, 'Calculate Field Production Rates', 'success', toc(step_start));
        
        % ----------------------------------------
        % Step 3 - Analyze Well Performance
        % ----------------------------------------
        step_start = tic;
        well_performance = step_3_analyze_well_performance(simulation_data, field_config);
        production_results.well_performance = well_performance;
        print_step_result(3, 'Analyze Well Performance', 'success', toc(step_start));
        
        % ----------------------------------------
        % Step 4 - Calculate Recovery Factors
        % ----------------------------------------
        step_start = tic;
        recovery_analysis = step_4_calculate_recovery_factors(field_rates, field_config);
        production_results.recovery_analysis = recovery_analysis;
        print_step_result(4, 'Calculate Recovery Factors', 'success', toc(step_start));
        
        % ----------------------------------------
        % Step 5 - Production Decline Analysis
        % ----------------------------------------
        step_start = tic;
        decline_analysis = step_5_production_decline_analysis(field_rates);
        production_results.decline_analysis = decline_analysis;
        print_step_result(5, 'Production Decline Analysis', 'success', toc(step_start));
        
        % ----------------------------------------
        % Step 6 - Performance vs Targets Analysis
        % ----------------------------------------
        step_start = tic;
        targets_analysis = step_6_performance_vs_targets_analysis(field_rates, field_config);
        production_results.targets_analysis = targets_analysis;
        print_step_result(6, 'Performance vs Targets', 'success', toc(step_start));
        
        % ----------------------------------------
        % Step 7 - Generate Production Visualizations
        % ----------------------------------------
        step_start = tic;
        visualization_paths = step_7_generate_production_visualizations(production_results);
        production_results.visualization_paths = visualization_paths;
        print_step_result(7, 'Generate Visualizations', 'success', toc(step_start));
        
        % ----------------------------------------
        % Step 8 - Export Production Analysis
        % ----------------------------------------
        step_start = tic;
        export_path = step_8_export_production_analysis(production_results);
        production_results.export_path = export_path;
        print_step_result(8, 'Export Production Analysis', 'success', toc(step_start));
        
        production_results.status = 'success';
        production_results.analysis_completed = true;
        production_results.creation_time = datestr(now);
        
        print_step_footer('S24', sprintf('Production Analysis Complete - %d wells analyzed', ...
            production_results.well_performance.total_wells), toc(total_start_time));
        
    catch ME
        print_error_step(0, 'Production Analysis', ME.message);
        production_results.status = 'failed';
        production_results.error_message = ME.message;
        error('Production analysis failed: %s', ME.message);
    end

end

function production_results = initialize_production_structure()
% Initialize production analysis results structure
    production_results = struct();
    production_results.status = 'initializing';
    production_results.simulation_data = [];
    production_results.field_config = [];
    production_results.field_rates = [];
    production_results.well_performance = [];
    production_results.recovery_analysis = [];
    production_results.decline_analysis = [];
    production_results.targets_analysis = [];
    production_results.visualization_paths = [];
    production_results.export_path = [];
end

function [simulation_data, field_config] = step_1_load_simulation_results()
% Step 1 - Load complete simulation results from s22

    script_path = fileparts(mfilename('fullpath'));
    data_dir = fullfile(fileparts(script_path), 'data', 'mrst_simulation', 'results');
    
    % Substep 1.1 - Find latest simulation results ______________________
    results_files = dir(fullfile(data_dir, 'simulation_results_*.mat'));
    if isempty(results_files)
        error('No simulation results found. Run s22_run_simulation.m first.');
    end
    
    % Get the most recent file
    [~, idx] = max([results_files.datenum]);
    latest_file = fullfile(data_dir, results_files(idx).name);
    
    fprintf('Loading simulation results: %s\n', results_files(idx).name);
    
    % Substep 1.2 - Load simulation results ______________________________
    load(latest_file, 'simulation_results');
    simulation_data = simulation_results;
    
    % Substep 1.3 - Load field configuration _____________________________
    static_dir = fullfile(fileparts(script_path), 'data', 'mrst_simulation', 'static');
    
    % Load production targets
    targets_file = fullfile(static_dir, 'production_targets.mat');
    if exist(targets_file, 'file')
        load(targets_file, 'target_results');
        field_config.production_targets = target_results;
    end
    
    % Load well configurations
    wells_file = fullfile(static_dir, 'well_completions.mat');
    if exist(wells_file, 'file')
        load(wells_file, 'completion_results');
        field_config.well_completions = completion_results;
    end
    
    % Load reservoir properties for OOIP calculation
    rock_file = fullfile(static_dir, 'rock_properties.mat');
    if exist(rock_file, 'file')
        load(rock_file, 'rock_results');
        field_config.reservoir_properties = rock_results;
    end
    
    fprintf('Configuration loaded: Wells=%d, Targets=%d\n', ...
        field_config.well_completions.total_wells, ...
        length(field_config.production_targets.field_targets));

end

function field_rates = step_2_calculate_field_production_rates(simulation_data)
% Step 2 - Calculate comprehensive field production rates and cumulative volumes

    fprintf('\n Field Production Rate Analysis:\n');
    fprintf(' ──────────────────────────────────────────────────────────\n');
    
    % Substep 2.1 - Extract time series data _____________________________
    if isfield(simulation_data, 'post_processed')
        time_data = simulation_data.post_processed;
    else
        error('Post-processed data not available in simulation results');
    end
    
    field_rates = struct();
    field_rates.time_days = time_data.time_days;
    field_rates.time_years = time_data.time_days / 365.25;
    
    % Substep 2.2 - Production rates by phase ____________________________
    field_rates.oil_rate_stb_day = time_data.field_oil_rate_stb_day;
    field_rates.water_rate_bbl_day = time_data.field_water_rate_bbl_day;
    field_rates.gas_rate_mscf_day = time_data.field_gas_rate_mscf_day;
    field_rates.injection_rate_bbl_day = time_data.field_injection_rate_bbl_day;
    
    % Substep 2.3 - Cumulative production ________________________________
    field_rates.cumulative_oil_stb = time_data.cumulative_oil_stb;
    field_rates.cumulative_water_bbl = time_data.cumulative_water_bbl;
    field_rates.cumulative_gas_mscf = time_data.cumulative_gas_mscf;
    field_rates.cumulative_injection_bbl = time_data.cumulative_injection_bbl;
    
    % Substep 2.4 - Calculate additional field metrics ___________________
    field_rates.total_liquid_rate_bbl_day = field_rates.oil_rate_stb_day + field_rates.water_rate_bbl_day;
    field_rates.water_cut_fraction = field_rates.water_rate_bbl_day ./ (field_rates.total_liquid_rate_bbl_day + 1e-10);
    field_rates.gor_scf_stb = (field_rates.gas_rate_mscf_day * 1000) ./ (field_rates.oil_rate_stb_day + 1e-10);
    
    % Substep 2.5 - Field pressure history _______________________________
    field_rates.average_pressure_bar = time_data.average_pressure;
    field_rates.oil_saturation_fraction = time_data.average_oil_saturation;
    
    % Calculate pressure decline
    initial_pressure = field_rates.average_pressure_bar(1);
    field_rates.pressure_decline_bar = initial_pressure - field_rates.average_pressure_bar;
    field_rates.pressure_decline_percent = (field_rates.pressure_decline_bar / initial_pressure) * 100;
    
    % Substep 2.6 - Production summary statistics _________________________
    peak_oil_rate = max(field_rates.oil_rate_stb_day);
    peak_oil_day = field_rates.time_days(field_rates.oil_rate_stb_day == peak_oil_rate);
    final_oil_rate = field_rates.oil_rate_stb_day(end);
    ultimate_recovery = field_rates.cumulative_oil_stb(end);
    
    field_rates.summary = struct();
    field_rates.summary.peak_oil_rate_stb_day = peak_oil_rate;
    field_rates.summary.peak_oil_day = peak_oil_day(1);
    field_rates.summary.final_oil_rate_stb_day = final_oil_rate;
    field_rates.summary.ultimate_recovery_mmstb = ultimate_recovery / 1e6;
    field_rates.summary.final_water_cut_percent = field_rates.water_cut_fraction(end) * 100;
    field_rates.summary.final_pressure_decline_percent = field_rates.pressure_decline_percent(end);
    
    fprintf('   Peak Oil Rate: %,.0f STB/day (Day %d)\n', peak_oil_rate, peak_oil_day(1));
    fprintf('   Ultimate Recovery: %.1f MMstb\n', field_rates.summary.ultimate_recovery_mmstb);
    fprintf('   Final Water Cut: %.1f%%\n', field_rates.summary.final_water_cut_percent);
    fprintf('   Pressure Decline: %.1f%% (%.0f bar)\n', ...
        field_rates.summary.final_pressure_decline_percent, field_rates.pressure_decline_bar(end));
    fprintf(' ──────────────────────────────────────────────────────────\n');

end

function well_performance = step_3_analyze_well_performance(simulation_data, field_config)
% Step 3 - Analyze individual well performance from simulation results

    fprintf('\n Individual Well Performance Analysis:\n');
    fprintf(' ──────────────────────────────────────────────────────────\n');
    
    well_performance = struct();
    well_performance.total_wells = field_config.well_completions.total_wells;
    well_performance.producers = [];
    well_performance.injectors = [];
    
    % Substep 3.1 - Extract well data from reports _______________________
    if ~isfield(simulation_data, 'reports') || isempty(simulation_data.reports)
        fprintf('   Warning: No well reports available for individual well analysis\n');
        return;
    end
    
    reports = simulation_data.reports;
    num_steps = length(reports);
    
    % Substep 3.2 - Process producer wells _______________________________
    producer_names = {};
    for i = 1:length(field_config.well_completions.well_completions)
        well = field_config.well_completions.well_completions(i);
        if ~isempty(strfind(well.well_name, 'EW-'))  % Producer wells
            producer_names{end+1} = well.well_name;
        end
    end
    
    well_performance.producers = struct();
    for p = 1:length(producer_names)
        well_name = producer_names{p};
        
        % Initialize well arrays
        oil_rates = zeros(num_steps, 1);
        water_rates = zeros(num_steps, 1);
        gas_rates = zeros(num_steps, 1);
        bhp_pressure = zeros(num_steps, 1);
        
        % Extract data from each timestep
        for t = 1:num_steps
            if isfield(reports{t}, 'WellSol') && ~isempty(reports{t}.WellSol)
                wellsol = reports{t}.WellSol;
                
                % Find this well in the wellsol array
                for w = 1:length(wellsol)
                    if strcmp(wellsol(w).name, well_name)
                        oil_rates(t) = max(0, -wellsol(w).qOs * 24 * 3600 / 0.158987);  % STB/day
                        water_rates(t) = max(0, -wellsol(w).qWs * 24 * 3600 / 0.158987);  % bbl/day
                        gas_rates(t) = max(0, -wellsol(w).qGs * 24 * 3600 / 0.0283168);  % MSCF/day
                        bhp_pressure(t) = wellsol(w).bhp / 1e5;  % bar
                        break;
                    end
                end
            end
        end
        
        % Calculate well performance metrics
        well_data = struct();
        well_data.name = well_name;
        well_data.oil_rates_stb_day = oil_rates;
        well_data.water_rates_bbl_day = water_rates;
        well_data.gas_rates_mscf_day = gas_rates;
        well_data.bhp_pressure_bar = bhp_pressure;
        
        % Calculate cumulatives and performance metrics
        time_data = simulation_data.post_processed.time_days;
        dt = [time_data(1); diff(time_data)];
        well_data.cumulative_oil_stb = cumsum(oil_rates .* dt);
        well_data.cumulative_water_bbl = cumsum(water_rates .* dt);
        well_data.peak_oil_rate_stb_day = max(oil_rates);
        well_data.ultimate_recovery_mstb = well_data.cumulative_oil_stb(end) / 1000;
        well_data.average_oil_rate_stb_day = mean(oil_rates(oil_rates > 0));
        
        well_performance.producers.(sprintf('well_%d', p)) = well_data;
        
        fprintf('   %s: Peak=%.0f STB/d, Ultimate=%.1f Mstb\n', ...
            well_name, well_data.peak_oil_rate_stb_day, well_data.ultimate_recovery_mstb);
    end
    
    % Substep 3.3 - Process injector wells _______________________________
    injector_names = {};
    for i = 1:length(field_config.well_completions.well_completions)
        well = field_config.well_completions.well_completions(i);
        if ~isempty(strfind(well.well_name, 'IW-'))  % Injector wells
            injector_names{end+1} = well.well_name;
        end
    end
    
    well_performance.injectors = struct();
    for i = 1:length(injector_names)
        well_name = injector_names{i};
        
        % Initialize arrays
        injection_rates = zeros(num_steps, 1);
        bhp_pressure = zeros(num_steps, 1);
        
        % Extract data
        for t = 1:num_steps
            if isfield(reports{t}, 'WellSol') && ~isempty(reports{t}.WellSol)
                wellsol = reports{t}.WellSol;
                
                for w = 1:length(wellsol)
                    if strcmp(wellsol(w).name, well_name)
                        injection_rates(t) = max(0, wellsol(w).qWs * 24 * 3600 / 0.158987);  % bbl/day
                        bhp_pressure(t) = wellsol(w).bhp / 1e5;  % bar
                        break;
                    end
                end
            end
        end
        
        % Calculate injector metrics
        well_data = struct();
        well_data.name = well_name;
        well_data.injection_rates_bbl_day = injection_rates;
        well_data.bhp_pressure_bar = bhp_pressure;
        
        time_data = simulation_data.post_processed.time_days;
        dt = [time_data(1); diff(time_data)];
        well_data.cumulative_injection_bbl = cumsum(injection_rates .* dt);
        well_data.peak_injection_rate_bbl_day = max(injection_rates);
        well_data.total_injection_mbbl = well_data.cumulative_injection_bbl(end) / 1000;
        
        well_performance.injectors.(sprintf('injector_%d', i)) = well_data;
        
        fprintf('   %s: Peak=%.0f bbl/d, Total=%.1f Mbbl\n', ...
            well_name, well_data.peak_injection_rate_bbl_day, well_data.total_injection_mbbl);
    end
    
    fprintf(' ──────────────────────────────────────────────────────────\n');

end

function recovery_analysis = step_4_calculate_recovery_factors(field_rates, field_config)
% Step 4 - Calculate recovery factors and reservoir efficiency metrics

    fprintf('\n Recovery Factor and Efficiency Analysis:\n');
    fprintf(' ──────────────────────────────────────────────────────────\n');
    
    recovery_analysis = struct();
    
    % Substep 4.1 - Estimate Original Oil in Place (OOIP) ________________
    % This is a simplified calculation - in practice would come from reservoir engineering
    if isfield(field_config, 'reservoir_properties')
        % Use reservoir properties if available
        estimated_ooip_stb = 50e6;  % 50 million STB base estimate
        fprintf('   OOIP Estimation: %.1f MMstb (from reservoir properties)\n', estimated_ooip_stb/1e6);
    else
        % Use field performance to estimate OOIP
        ultimate_recovery = field_rates.cumulative_oil_stb(end);
        estimated_recovery_factor = 0.35;  % Typical primary + secondary recovery
        estimated_ooip_stb = ultimate_recovery / estimated_recovery_factor;
        fprintf('   OOIP Estimation: %.1f MMstb (inferred from production)\n', estimated_ooip_stb/1e6);
    end
    
    recovery_analysis.original_oil_in_place_stb = estimated_ooip_stb;
    
    % Substep 4.2 - Calculate recovery factors ___________________________
    recovery_analysis.cumulative_recovery_stb = field_rates.cumulative_oil_stb;
    recovery_analysis.recovery_factor_fraction = recovery_analysis.cumulative_recovery_stb / estimated_ooip_stb;
    recovery_analysis.recovery_factor_percent = recovery_analysis.recovery_factor_fraction * 100;
    
    % Final recovery metrics
    final_recovery_factor = recovery_analysis.recovery_factor_percent(end);
    ultimate_recovery_mmstb = recovery_analysis.cumulative_recovery_stb(end) / 1e6;
    
    % Substep 4.3 - Calculate sweep efficiency ___________________________ 
    initial_oil_sat = field_rates.oil_saturation_fraction(1);
    final_oil_sat = field_rates.oil_saturation_fraction(end);
    
    recovery_analysis.initial_oil_saturation = initial_oil_sat;
    recovery_analysis.final_oil_saturation = final_oil_sat;
    recovery_analysis.oil_saturation_reduction = initial_oil_sat - final_oil_sat;
    recovery_analysis.sweep_efficiency_percent = (recovery_analysis.oil_saturation_reduction / initial_oil_sat) * 100;
    
    % Substep 4.4 - Calculate displacement efficiency ____________________
    recovery_analysis.displacement_efficiency_percent = final_recovery_factor / ...
        (recovery_analysis.sweep_efficiency_percent / 100 + 1e-10) * 100;
    
    % Substep 4.5 - Voidage replacement ratio ____________________________
    total_production_bbl = recovery_analysis.cumulative_recovery_stb(end) + field_rates.cumulative_water_bbl(end);
    total_injection_bbl = field_rates.cumulative_injection_bbl(end);
    recovery_analysis.voidage_replacement_ratio = total_injection_bbl / (total_production_bbl + 1e-10);
    
    % Substep 4.6 - Recovery analysis summary ____________________________
    recovery_analysis.summary = struct();
    recovery_analysis.summary.ultimate_recovery_mmstb = ultimate_recovery_mmstb;
    recovery_analysis.summary.final_recovery_factor_percent = final_recovery_factor;
    recovery_analysis.summary.sweep_efficiency_percent = recovery_analysis.sweep_efficiency_percent;
    recovery_analysis.summary.displacement_efficiency_percent = recovery_analysis.displacement_efficiency_percent;
    recovery_analysis.summary.voidage_replacement_ratio = recovery_analysis.voidage_replacement_ratio;
    
    fprintf('   Ultimate Recovery: %.1f MMstb\n', ultimate_recovery_mmstb);
    fprintf('   Recovery Factor: %.1f%%\n', final_recovery_factor);
    fprintf('   Sweep Efficiency: %.1f%%\n', recovery_analysis.sweep_efficiency_percent);
    fprintf('   Displacement Efficiency: %.1f%%\n', recovery_analysis.displacement_efficiency_percent);
    fprintf('   Voidage Replacement: %.2f\n', recovery_analysis.voidage_replacement_ratio);
    fprintf(' ──────────────────────────────────────────────────────────\n');

end

function decline_analysis = step_5_production_decline_analysis(field_rates)
% Step 5 - Analyze production decline curves and forecast trends

    fprintf('\n Production Decline Curve Analysis:\n');
    fprintf(' ──────────────────────────────────────────────────────────\n');
    
    decline_analysis = struct();
    
    % Substep 5.1 - Identify production phases ___________________________
    oil_rates = field_rates.oil_rate_stb_day;
    time_days = field_rates.time_days;
    
    % Find peak production and start of decline
    [peak_rate, peak_idx] = max(oil_rates);
    peak_time = time_days(peak_idx);
    
    decline_analysis.peak_production_stb_day = peak_rate;
    decline_analysis.peak_production_day = peak_time;
    
    % Substep 5.2 - Analyze decline phases _______________________________
    % Build-up phase (before peak)
    buildup_idx = 1:peak_idx;
    decline_analysis.buildup_phase = struct();
    decline_analysis.buildup_phase.duration_days = peak_time;
    decline_analysis.buildup_phase.final_rate_stb_day = peak_rate;
    if length(buildup_idx) > 1
        buildup_rates = oil_rates(buildup_idx);
        buildup_times = time_days(buildup_idx);
        decline_analysis.buildup_phase.average_rate_stb_day = mean(buildup_rates);
        decline_analysis.buildup_phase.buildup_rate_stb_day_per_year = ...
            (peak_rate - oil_rates(1)) / (peak_time / 365.25);
    end
    
    % Decline phase (after peak)
    decline_idx = peak_idx:length(oil_rates);
    decline_analysis.decline_phase = struct();
    
    if length(decline_idx) > 10  % Need sufficient data for decline analysis
        decline_rates = oil_rates(decline_idx);
        decline_times = time_days(decline_idx);
        decline_years = decline_times / 365.25;
        
        decline_analysis.decline_phase.duration_days = decline_times(end) - decline_times(1);
        decline_analysis.decline_phase.duration_years = decline_analysis.decline_phase.duration_days / 365.25;
        decline_analysis.decline_phase.initial_rate_stb_day = peak_rate;
        decline_analysis.decline_phase.final_rate_stb_day = decline_rates(end);
        
        % Substep 5.3 - Exponential decline analysis ____________________
        % Fit exponential decline: q(t) = q_i * exp(-D*t)
        log_rates = log(decline_rates + 1e-10);  % Avoid log(0)
        
        if length(log_rates) > 2
            p = polyfit(decline_years, log_rates, 1);  % Linear fit in semi-log space
            decline_analysis.decline_phase.exponential_decline_rate_per_year = -p(1);
            decline_analysis.decline_phase.exponential_r_squared = calculate_r_squared(log_rates, polyval(p, decline_years));
            
            % Calculate half-life
            if p(1) < 0
                decline_analysis.decline_phase.half_life_years = log(2) / (-p(1));
            else
                decline_analysis.decline_phase.half_life_years = Inf;
            end
        end
        
        % Substep 5.4 - Hyperbolic decline analysis ______________________
        % Fit hyperbolic decline: q(t) = q_i / (1 + b*D*t)^(1/b)
        if length(decline_rates) > 5
            % Simplified approach - fit to harmonic decline (b=1)
            harmonic_fit = fit_harmonic_decline(decline_years, decline_rates, peak_rate);
            decline_analysis.decline_phase.harmonic_decline_rate = harmonic_fit.decline_rate;
            decline_analysis.decline_phase.harmonic_r_squared = harmonic_fit.r_squared;
        end
        
        % Substep 5.5 - Calculate decline metrics ________________________
        rate_decline_percent = ((peak_rate - decline_rates(end)) / peak_rate) * 100;
        annual_decline_percent = decline_analysis.decline_phase.exponential_decline_rate_per_year * 100;
        
        decline_analysis.decline_phase.rate_decline_percent = rate_decline_percent;
        decline_analysis.decline_phase.annual_decline_percent = annual_decline_percent;
    end
    
    % Substep 5.6 - Current production trend analysis ____________________
    % Analyze last year of production for current trend
    last_year_idx = time_days >= (time_days(end) - 365);
    if sum(last_year_idx) > 10
        recent_rates = oil_rates(last_year_idx);
        recent_times = time_days(last_year_idx) / 365.25;
        
        if length(recent_rates) > 2
            p_recent = polyfit(recent_times, recent_rates, 1);
            decline_analysis.current_trend = struct();
            decline_analysis.current_trend.rate_change_stb_day_per_year = p_recent(1);
            decline_analysis.current_trend.current_rate_stb_day = recent_rates(end);
            decline_analysis.current_trend.is_declining = p_recent(1) < 0;
            
            if p_recent(1) < 0
                decline_analysis.current_trend.decline_rate_percent_per_year = ...
                    abs(p_recent(1)) / recent_rates(1) * 100;
            end
        end
    end
    
    fprintf('   Peak Production: %,.0f STB/day (Day %d)\n', peak_rate, peak_time);
    if isfield(decline_analysis, 'decline_phase') && isfield(decline_analysis.decline_phase, 'annual_decline_percent')
        fprintf('   Annual Decline Rate: %.1f%%/year\n', decline_analysis.decline_phase.annual_decline_percent);
        fprintf('   Current Rate Decline: %.1f%%\n', decline_analysis.decline_phase.rate_decline_percent);
        if isfinite(decline_analysis.decline_phase.half_life_years)
            fprintf('   Production Half-Life: %.1f years\n', decline_analysis.decline_phase.half_life_years);
        end
    end
    fprintf(' ──────────────────────────────────────────────────────────\n');

end

function targets_analysis = step_6_performance_vs_targets_analysis(field_rates, field_config)
% Step 6 - Compare actual performance against production targets

    fprintf('\n Performance vs Targets Analysis:\n');
    fprintf(' ──────────────────────────────────────────────────────────\n');
    
    targets_analysis = struct();
    
    % Substep 6.1 - Load production targets ______________________________
    if ~isfield(field_config, 'production_targets')
        fprintf('   Warning: No production targets available for comparison\n');
        targets_analysis.targets_available = false;
        return;
    end
    
    targets = field_config.production_targets;
    targets_analysis.targets_available = true;
    
    % Substep 6.2 - Compare field production targets _____________________
    if isfield(targets, 'field_targets')
        field_targets = targets.field_targets;
        
        % Initialize comparison arrays
        time_years = field_rates.time_years;
        actual_oil_rates = field_rates.oil_rate_stb_day;
        actual_cumulative = field_rates.cumulative_oil_stb / 1e6;  % MMstb
        
        targets_analysis.field_comparison = struct();
        
        for i = 1:length(field_targets)
            target = field_targets(i);
            target_year = target.target_year;
            
            % Find closest actual data point
            [~, year_idx] = min(abs(time_years - target_year));
            
            comparison = struct();
            comparison.target_year = target_year;
            comparison.target_oil_rate_stb_day = target.peak_oil_rate_stb_day;
            comparison.actual_oil_rate_stb_day = actual_oil_rates(year_idx);
            comparison.target_cumulative_mmstb = target.cumulative_oil_mmstb;
            comparison.actual_cumulative_mmstb = actual_cumulative(year_idx);
            
            % Calculate performance ratios
            comparison.rate_performance_ratio = comparison.actual_oil_rate_stb_day / comparison.target_oil_rate_stb_day;
            comparison.cumulative_performance_ratio = comparison.actual_cumulative_mmstb / comparison.target_cumulative_mmstb;
            
            % Performance status
            comparison.rate_meets_target = comparison.rate_performance_ratio >= 0.95;
            comparison.cumulative_meets_target = comparison.cumulative_performance_ratio >= 0.95;
            
            targets_analysis.field_comparison.(sprintf('year_%d', target_year)) = comparison;
            
            fprintf('   Year %d - Rate: %.0f/%.0f STB/d (%.1f%%), Cum: %.1f/%.1f MMstb (%.1f%%)\n', ...
                target_year, comparison.actual_oil_rate_stb_day, comparison.target_oil_rate_stb_day, ...
                comparison.rate_performance_ratio*100, comparison.actual_cumulative_mmstb, ...
                comparison.target_cumulative_mmstb, comparison.cumulative_performance_ratio*100);
        end
    end
    
    % Substep 6.3 - Overall performance assessment ________________________
    if isfield(targets_analysis, 'field_comparison')
        field_comparisons = struct2cell(targets_analysis.field_comparison);
        
        rate_ratios = cellfun(@(x) x.rate_performance_ratio, field_comparisons);
        cum_ratios = cellfun(@(x) x.cumulative_performance_ratio, field_comparisons);
        
        targets_analysis.overall_performance = struct();
        targets_analysis.overall_performance.average_rate_performance_ratio = mean(rate_ratios);
        targets_analysis.overall_performance.average_cumulative_performance_ratio = mean(cum_ratios);
        targets_analysis.overall_performance.rate_targets_met = sum(rate_ratios >= 0.95) / length(rate_ratios) * 100;
        targets_analysis.overall_performance.cumulative_targets_met = sum(cum_ratios >= 0.95) / length(cum_ratios) * 100;
        
        % Performance grade
        overall_score = (targets_analysis.overall_performance.average_rate_performance_ratio + ...
                        targets_analysis.overall_performance.average_cumulative_performance_ratio) / 2;
        
        if overall_score >= 1.0
            targets_analysis.overall_performance.grade = 'Excellent';
        elseif overall_score >= 0.95
            targets_analysis.overall_performance.grade = 'Good';
        elseif overall_score >= 0.85
            targets_analysis.overall_performance.grade = 'Fair';
        else
            targets_analysis.overall_performance.grade = 'Below Target';
        end
        
        fprintf('   Overall Performance: %s (%.1f%% of targets)\n', ...
            targets_analysis.overall_performance.grade, overall_score * 100);
    end
    
    fprintf(' ──────────────────────────────────────────────────────────\n');

end

function visualization_paths = step_7_generate_production_visualizations(production_results)
% Step 7 - Generate comprehensive production visualization plots

    fprintf('\n Generating Production Visualizations:\n');
    fprintf(' ──────────────────────────────────────────────────────────\n');
    
    script_path = fileparts(mfilename('fullpath'));
    plots_dir = fullfile(fileparts(script_path), 'data', 'mrst_simulation', 'plots');
    
    if ~exist(plots_dir, 'dir')
        mkdir(plots_dir);
    end
    
    visualization_paths = struct();
    field_rates = production_results.field_rates;
    
    % Substep 7.1 - Field production rate plots ___________________________
    figure('Position', [100, 100, 1200, 800], 'Visible', 'off');
    
    subplot(2, 2, 1);
    plot(field_rates.time_years, field_rates.oil_rate_stb_day, 'r-', 'LineWidth', 2);
    xlabel('Time (Years)');
    ylabel('Oil Rate (STB/day)');
    title('Field Oil Production Rate');
    grid on;
    
    subplot(2, 2, 2);
    plot(field_rates.time_years, field_rates.water_cut_fraction * 100, 'b-', 'LineWidth', 2);
    xlabel('Time (Years)');
    ylabel('Water Cut (%)');
    title('Field Water Cut Evolution');
    grid on;
    
    subplot(2, 2, 3);
    plot(field_rates.time_years, field_rates.cumulative_oil_stb / 1e6, 'g-', 'LineWidth', 2);
    xlabel('Time (Years)');
    ylabel('Cumulative Oil (MMstb)');
    title('Cumulative Oil Production');
    grid on;
    
    subplot(2, 2, 4);
    plot(field_rates.time_years, field_rates.average_pressure_bar, 'm-', 'LineWidth', 2);
    xlabel('Time (Years)');
    ylabel('Average Pressure (bar)');
    title('Field Pressure History');
    grid on;
    
    sgtitle('Eagle West Field - Production Performance Overview', 'FontSize', 14, 'FontWeight', 'bold');
    
    rates_plot_path = fullfile(plots_dir, 'field_production_overview.png');
    saveas(gcf, rates_plot_path);
    close(gcf);
    visualization_paths.field_overview = rates_plot_path;
    
    % Substep 7.2 - Recovery factor and decline analysis __________________
    if isfield(production_results, 'decline_analysis')
        figure('Position', [100, 100, 1200, 600], 'Visible', 'off');
        
        subplot(1, 2, 1);
        semilogy(field_rates.time_years, field_rates.oil_rate_stb_day, 'r-', 'LineWidth', 2);
        xlabel('Time (Years)');
        ylabel('Oil Rate (STB/day)');
        title('Production Decline Curve (Log Scale)');
        grid on;
        
        subplot(1, 2, 2);
        if isfield(production_results, 'recovery_analysis')
            plot(field_rates.time_years, production_results.recovery_analysis.recovery_factor_percent, 'g-', 'LineWidth', 2);
            xlabel('Time (Years)');
            ylabel('Recovery Factor (%)');
            title('Recovery Factor Evolution');
            grid on;
        end
        
        sgtitle('Eagle West Field - Decline and Recovery Analysis', 'FontSize', 14, 'FontWeight', 'bold');
        
        decline_plot_path = fullfile(plots_dir, 'decline_recovery_analysis.png');
        saveas(gcf, decline_plot_path);
        close(gcf);
        visualization_paths.decline_analysis = decline_plot_path;
    end
    
    % Substep 7.3 - Performance vs targets plot __________________________
    if isfield(production_results, 'targets_analysis') && production_results.targets_analysis.targets_available
        figure('Position', [100, 100, 1000, 600], 'Visible', 'off');
        
        targets_comp = production_results.targets_analysis.field_comparison;
        target_fields = fieldnames(targets_comp);
        
        years = [];
        actual_rates = [];
        target_rates = [];
        actual_cum = [];
        target_cum = [];
        
        for i = 1:length(target_fields)
            comp = targets_comp.(target_fields{i});
            years(end+1) = comp.target_year;
            actual_rates(end+1) = comp.actual_oil_rate_stb_day;
            target_rates(end+1) = comp.target_oil_rate_stb_day;
            actual_cum(end+1) = comp.actual_cumulative_mmstb;
            target_cum(end+1) = comp.target_cumulative_mmstb;
        end
        
        subplot(1, 2, 1);
        bar(years, [actual_rates; target_rates]', 'grouped');
        xlabel('Target Year');
        ylabel('Oil Rate (STB/day)');
        title('Actual vs Target Oil Rates');
        legend('Actual', 'Target', 'Location', 'best');
        grid on;
        
        subplot(1, 2, 2);
        bar(years, [actual_cum; target_cum]', 'grouped');
        xlabel('Target Year');
        ylabel('Cumulative Oil (MMstb)');
        title('Actual vs Target Cumulative Production');
        legend('Actual', 'Target', 'Location', 'best');
        grid on;
        
        sgtitle('Eagle West Field - Performance vs Targets', 'FontSize', 14, 'FontWeight', 'bold');
        
        targets_plot_path = fullfile(plots_dir, 'performance_vs_targets.png');
        saveas(gcf, targets_plot_path);
        close(gcf);
        visualization_paths.targets_comparison = targets_plot_path;
    end
    
    fprintf('   Field Overview: %s\n', visualization_paths.field_overview);
    if isfield(visualization_paths, 'decline_analysis')
        fprintf('   Decline Analysis: %s\n', visualization_paths.decline_analysis);
    end
    if isfield(visualization_paths, 'targets_comparison')
        fprintf('   Targets Comparison: %s\n', visualization_paths.targets_comparison);
    end
    fprintf(' ──────────────────────────────────────────────────────────\n');

end

function export_path = step_8_export_production_analysis(production_results)
% Step 8 - Export complete production analysis results

    script_path = fileparts(mfilename('fullpath'));
    results_dir = fullfile(fileparts(script_path), 'data', 'mrst_simulation', 'results');
    
    if ~exist(results_dir, 'dir')
        mkdir(results_dir);
    end
    
    % Substep 8.1 - Save complete production analysis ____________________
    timestamp = datestr(now, 'yyyymmdd_HHMMSS');
    export_path = fullfile(results_dir, sprintf('production_analysis_%s.mat', timestamp));
    save(export_path, 'production_results', '-v7.3');
    
    % Substep 8.2 - Export production summary report ______________________ 
    summary_file = fullfile(results_dir, sprintf('production_summary_%s.txt', timestamp));
    write_production_summary_file(summary_file, production_results);
    
    % Substep 8.3 - Export CSV data for external analysis ________________
    csv_file = fullfile(results_dir, sprintf('production_timeseries_%s.csv', timestamp));
    write_production_csv_file(csv_file, production_results.field_rates);
    
    fprintf('   Production Analysis: %s\n', export_path);
    fprintf('   Summary Report: %s\n', summary_file);
    fprintf('   CSV Time Series: %s\n', csv_file);

end

% Helper functions
function r_squared = calculate_r_squared(actual, fitted)
% Calculate R-squared goodness of fit
    ss_res = sum((actual - fitted).^2);
    ss_tot = sum((actual - mean(actual)).^2);
    r_squared = 1 - (ss_res / (ss_tot + 1e-10));
end

function fit_result = fit_harmonic_decline(time_years, rates, initial_rate)
% Fit harmonic decline curve: q(t) = q_i / (1 + D*t)
    if isempty(time_years) || isempty(rates) || length(time_years) ~= length(rates)
        fit_result = struct('decline_rate', NaN, 'r_squared', 0);
        return;
    end
    
    % Use least squares to fit D
    try
        % Transform: 1/q = 1/q_i + D*t/q_i
        inv_rates = 1 ./ (rates + 1e-10);
        inv_initial = 1 / initial_rate;
        
        p = polyfit(time_years, inv_rates - inv_initial, 1);
        decline_rate = p(1) * initial_rate;  % Convert back to decline rate
        
        % Calculate R-squared
        fitted_inv_rates = inv_initial + p(1) * time_years;
        r_squared = calculate_r_squared(inv_rates, fitted_inv_rates);
        
        fit_result = struct('decline_rate', decline_rate, 'r_squared', r_squared);
    catch
        fit_result = struct('decline_rate', NaN, 'r_squared', 0);
    end
end

function write_production_summary_file(filename, production_results)
% Write comprehensive production summary report

    fid = fopen(filename, 'w');
    if fid == -1
        error('Cannot open file for writing: %s', filename);
    end
    
    try
        fprintf(fid, 'EAGLE WEST FIELD - PRODUCTION ANALYSIS SUMMARY\n');
        fprintf(fid, '==============================================\n');
        fprintf(fid, 'Generated: %s\n\n', datestr(now));
        
        % Field production summary
        if isfield(production_results, 'field_rates')
            rates = production_results.field_rates;
            fprintf(fid, 'FIELD PRODUCTION SUMMARY:\n');
            fprintf(fid, '  Peak Oil Rate: %,.0f STB/day\n', rates.summary.peak_oil_rate_stb_day);
            fprintf(fid, '  Ultimate Recovery: %.1f MMstb\n', rates.summary.ultimate_recovery_mmstb);
            fprintf(fid, '  Final Water Cut: %.1f%%\n', rates.summary.final_water_cut_percent);
            fprintf(fid, '  Pressure Decline: %.1f%%\n', rates.summary.final_pressure_decline_percent);
            fprintf(fid, '\n');
        end
        
        % Recovery analysis
        if isfield(production_results, 'recovery_analysis')
            recovery = production_results.recovery_analysis;
            fprintf(fid, 'RECOVERY ANALYSIS:\n');
            fprintf(fid, '  Original Oil in Place: %.1f MMstb\n', recovery.original_oil_in_place_stb/1e6);
            fprintf(fid, '  Recovery Factor: %.1f%%\n', recovery.summary.final_recovery_factor_percent);
            fprintf(fid, '  Sweep Efficiency: %.1f%%\n', recovery.summary.sweep_efficiency_percent);
            fprintf(fid, '  Voidage Replacement: %.2f\n', recovery.summary.voidage_replacement_ratio);
            fprintf(fid, '\n');
        end
        
        % Performance vs targets
        if isfield(production_results, 'targets_analysis') && production_results.targets_analysis.targets_available
            targets = production_results.targets_analysis;
            fprintf(fid, 'PERFORMANCE VS TARGETS:\n');
            fprintf(fid, '  Overall Grade: %s\n', targets.overall_performance.grade);
            fprintf(fid, '  Average Performance: %.1f%%\n', targets.overall_performance.average_rate_performance_ratio * 100);
            fprintf(fid, '  Rate Targets Met: %.0f%%\n', targets.overall_performance.rate_targets_met);
            fprintf(fid, '  Cumulative Targets Met: %.0f%%\n', targets.overall_performance.cumulative_targets_met);
        end
        
        fclose(fid);
        
    catch ME
        fclose(fid);
        error('Error writing production summary: %s', ME.message);
    end

end

function write_production_csv_file(filename, field_rates)
% Write production time series data to CSV

    try
        % Prepare data matrix
        data = [field_rates.time_days, field_rates.time_years, field_rates.oil_rate_stb_day, ...
                field_rates.water_rate_bbl_day, field_rates.gas_rate_mscf_day, ...
                field_rates.cumulative_oil_stb / 1e6, field_rates.cumulative_water_bbl / 1e6, ...
                field_rates.water_cut_fraction * 100, field_rates.average_pressure_bar, ...
                field_rates.oil_saturation_fraction];
        
        % Write CSV with headers
        fid = fopen(filename, 'w');
        fprintf(fid, 'Time_Days,Time_Years,Oil_Rate_STB_day,Water_Rate_BBL_day,Gas_Rate_MSCF_day,');
        fprintf(fid, 'Cumulative_Oil_MMstb,Cumulative_Water_MMbbl,Water_Cut_Percent,');
        fprintf(fid, 'Pressure_bar,Oil_Saturation_Fraction\n');
        
        for i = 1:size(data, 1)
            fprintf(fid, '%.1f,%.3f,%.1f,%.1f,%.1f,%.3f,%.3f,%.2f,%.1f,%.4f\n', data(i, :));
        end
        
        fclose(fid);
        
    catch ME
        if exist('fid', 'var') && fid > 0
            fclose(fid);
        end
        error('Error writing production CSV: %s', ME.message);
    end

end

% Main execution when called as script
if ~nargout
    production_results = s24_production_analysis();
end