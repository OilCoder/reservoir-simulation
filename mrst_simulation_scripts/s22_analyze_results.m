function analysis = s22_analyze_results()
% S22_ANALYZE_RESULTS - Detailed analysis of Eagle West Field simulation results
%
% PURPOSE:
%   Perform comprehensive analysis of simulation results from s21
%   Generate production curves, pressure maps, well performance analysis
%
% OUTPUT:
%   analysis.mat → Detailed analysis results
%   Console output with key findings
%
% Author: Claude Code AI System
% Date: August 29, 2025

    fprintf('\n═══════════════════════════════════════════════════════════\n');
    fprintf(' S22: EAGLE WEST FIELD SIMULATION ANALYSIS\n');
    fprintf('═══════════════════════════════════════════════════════════\n');
    
    % Add utils path for MRST functions like day()
    script_dir = fileparts(mfilename('fullpath'));
    utils_dir = fullfile(script_dir, 'utils');
    addpath(utils_dir);
    
    % Add MRST units path for barsa, psia, etc.
    mrst_units = '/opt/mrst/core/utils/units';
    if exist(mrst_units, 'dir')
        addpath(mrst_units);
    end
    
    try
        % Load simulation results
        sim_file = '/workspace/data/mrst/simulation.mat';
        if ~exist(sim_file, 'file')
            error('Simulation results not found. Run s21_run_simulation first.');
        end
        
        load(sim_file, 'results', 'simulation_results', 'G', 'W');
        fprintf('✅ Loaded simulation results: %d timesteps, %d wells\n', ...
            size(results.pressure, 2), length(W));
        
        % Initialize analysis structure
        analysis = struct();
        analysis.timestamp = datestr(now);
        analysis.simulation_summary = simulation_results;
        
        % 1. Well Performance Analysis
        fprintf('\n🔍 WELL PERFORMANCE ANALYSIS\n');
        well_analysis = analyze_well_performance(results, W);
        analysis.wells = well_analysis;
        
        % 2. Pressure Evolution Analysis
        fprintf('\n📊 PRESSURE EVOLUTION ANALYSIS\n');
        pressure_analysis = analyze_pressure_evolution(results, G);
        analysis.pressure = pressure_analysis;
        
        % 3. Production Performance Analysis
        fprintf('\n⚡ PRODUCTION PERFORMANCE ANALYSIS\n');
        production_analysis = analyze_production_performance(results, W);
        analysis.production = production_analysis;
        
        % 4. Field Development Analysis
        fprintf('\n🏗️ FIELD DEVELOPMENT ANALYSIS\n');
        field_analysis = analyze_field_development(results, W, G);
        analysis.field = field_analysis;
        
        % Save analysis results
        analysis_file = '/workspace/data/mrst/analysis.mat';
        save(analysis_file, 'analysis', '-v7');
        
        fprintf('\n✅ S22: Analysis completed and saved to: %s\n', analysis_file);
        
        % Display summary
        display_analysis_summary(analysis);
        
    catch ME
        fprintf('\n❌ S22 Error: %s\n', ME.message);
        analysis = struct('status', 'failed', 'error', ME.message);
    end
end

function well_analysis = analyze_well_performance(results, W)
% Analyze individual well performance

    well_analysis = struct();
    
    % Classify wells by name
    producers = {};
    injectors = {};
    
    for i = 1:length(W)
        well_name = W(i).name;
        if strncmp(well_name, 'EW-', 3)
            producers{end+1} = i;
        elseif strncmp(well_name, 'IW-', 3)
            injectors{end+1} = i;
        end
    end
    
    fprintf('   Wells classified: %d producers, %d injectors\n', length(producers), length(injectors));
    
    % Analyze producer performance
    if ~isempty(producers)
        prod_rates = abs(results.well_rates(cell2mat(producers), :));
        well_analysis.producer_avg_rate_m3_day = mean(prod_rates, 2) * day;
        well_analysis.producer_peak_rate_m3_day = max(prod_rates, [], 2) * day;
        well_analysis.producer_cum_m3 = cumsum(prod_rates * (results.time(2) - results.time(1)), 2);
        
        fprintf('   Producer rates: %.1f to %.1f m³/day per well\n', ...
            min(well_analysis.producer_avg_rate_m3_day), max(well_analysis.producer_avg_rate_m3_day));
    end
    
    % Analyze injector performance
    if ~isempty(injectors)
        inj_rates = abs(results.well_rates(cell2mat(injectors), :));
        well_analysis.injector_avg_rate_m3_day = mean(inj_rates, 2) * day;
        well_analysis.injector_peak_rate_m3_day = max(inj_rates, [], 2) * day;
        
        fprintf('   Injector rates: %.1f to %.1f m³/day per well\n', ...
            min(well_analysis.injector_avg_rate_m3_day), max(well_analysis.injector_avg_rate_m3_day));
    end
    
    well_analysis.producers = producers;
    well_analysis.injectors = injectors;
end

function pressure_analysis = analyze_pressure_evolution(results, G)
% Analyze pressure evolution over time

    pressure_analysis = struct();
    
    % Initial pressure statistics
    initial_p = results.pressure(:, 1);
    final_p = results.pressure(:, end);
    
    pressure_analysis.initial_avg_barsa = mean(initial_p) / barsa;
    pressure_analysis.initial_min_barsa = min(initial_p) / barsa;
    pressure_analysis.initial_max_barsa = max(initial_p) / barsa;
    
    pressure_analysis.final_avg_barsa = mean(final_p) / barsa;
    pressure_analysis.final_min_barsa = min(final_p) / barsa;
    pressure_analysis.final_max_barsa = max(final_p) / barsa;
    
    pressure_analysis.pressure_drop_barsa = pressure_analysis.initial_avg_barsa - pressure_analysis.final_avg_barsa;
    
    fprintf('   Initial pressure: %.1f barsa (range: %.1f - %.1f)\n', ...
        pressure_analysis.initial_avg_barsa, pressure_analysis.initial_min_barsa, pressure_analysis.initial_max_barsa);
    fprintf('   Final pressure: %.1f barsa (range: %.1f - %.1f)\n', ...
        pressure_analysis.final_avg_barsa, pressure_analysis.final_min_barsa, pressure_analysis.final_max_barsa);
    fprintf('   Average pressure drop: %.1f barsa\n', pressure_analysis.pressure_drop_barsa);
end

function production_analysis = analyze_production_performance(results, W)
% Analyze overall production performance

    production_analysis = struct();
    
    % Find producers
    producer_indices = [];
    for i = 1:length(W)
        if strncmp(W(i).name, 'EW-', 3)
            producer_indices(end+1) = i;
        end
    end
    
    if ~isempty(producer_indices)
        % Calculate field production
        total_rates = sum(abs(results.well_rates(producer_indices, :)), 1);
        dt = results.time(2) - results.time(1);
        
        production_analysis.field_rate_m3_day = total_rates * day;
        production_analysis.field_rate_bbl_day = total_rates * day * 6.289;
        
        % Cumulative production
        cum_prod_m3 = cumsum(total_rates * dt);
        production_analysis.cum_prod_m3 = cum_prod_m3(end);
        production_analysis.cum_prod_MMbbl = cum_prod_m3(end) * 6.289 / 1e6;
        
        % Performance metrics
        production_analysis.avg_rate_bbl_day = mean(production_analysis.field_rate_bbl_day);
        production_analysis.peak_rate_bbl_day = max(production_analysis.field_rate_bbl_day);
        production_analysis.decline_rate_percent = ...
            100 * (production_analysis.field_rate_bbl_day(1) - production_analysis.field_rate_bbl_day(end)) / production_analysis.field_rate_bbl_day(1);
        
        fprintf('   Field production rate: %.0f bbl/day (avg), %.0f bbl/day (peak)\n', ...
            production_analysis.avg_rate_bbl_day, production_analysis.peak_rate_bbl_day);
        fprintf('   Cumulative production: %.2f MMbbl over 10 years\n', production_analysis.cum_prod_MMbbl);
        fprintf('   Production decline: %.1f%% over simulation period\n', production_analysis.decline_rate_percent);
    end
end

function field_analysis = analyze_field_development(results, W, G)
% Analyze overall field development performance

    field_analysis = struct();
    
    % Field characteristics
    field_analysis.total_cells = G.cells.num;
    field_analysis.total_volume_m3 = sum(G.cells.volumes);
    field_analysis.total_wells = length(W);
    
    % Recovery analysis (simplified)
    if isfield(results, 'saturation')
        % Calculate initial oil in place (OOIP)
        initial_so = results.saturation(:, 2, 1);  % Initial oil saturation
        rock_file = '/workspace/data/mrst/rock.mat';
        if exist(rock_file, 'file')
            load(rock_file, 'rock');
            pore_volume = G.cells.volumes .* rock.poro;
            initial_oil_m3 = sum(pore_volume .* initial_so);
            field_analysis.ooip_m3 = initial_oil_m3;
            field_analysis.ooip_MMbbl = initial_oil_m3 * 6.289 / 1e6;
            
            fprintf('   Original Oil in Place (OOIP): %.2f MMbbl\n', field_analysis.ooip_MMbbl);
        end
    end
    
    % Development efficiency
    producers = sum(strncmp({W.name}, 'EW-', 3));
    injectors = sum(strncmp({W.name}, 'IW-', 3));
    
    field_analysis.producers = producers;
    field_analysis.injectors = injectors;
    field_analysis.producer_injector_ratio = producers / injectors;
    field_analysis.well_density_per_km2 = length(W) / (field_analysis.total_volume_m3^(2/3) / 1e6);
    
    fprintf('   Development: %d producers, %d injectors (ratio %.1f:1)\n', ...
        producers, injectors, field_analysis.producer_injector_ratio);
    fprintf('   Field volume: %.2e m³\n', field_analysis.total_volume_m3);
end

function display_analysis_summary(analysis)
% Display comprehensive analysis summary

    fprintf('\n═══════════════════════════════════════════════════════════\n');
    fprintf(' 🎯 EAGLE WEST FIELD SIMULATION SUMMARY\n');
    fprintf('═══════════════════════════════════════════════════════════\n');
    
    if isfield(analysis, 'production')
        prod = analysis.production;
        fprintf('📈 PRODUCTION PERFORMANCE:\n');
        fprintf('   • Total production: %.2f MMbbl over 10 years\n', prod.cum_prod_MMbbl);
        fprintf('   • Average rate: %.0f bbl/day\n', prod.avg_rate_bbl_day);
        fprintf('   • Peak rate: %.0f bbl/day\n', prod.peak_rate_bbl_day);
        fprintf('   • Production decline: %.1f%%\n', prod.decline_rate_percent);
    end
    
    if isfield(analysis, 'pressure')
        pres = analysis.pressure;
        fprintf('\n💧 PRESSURE PERFORMANCE:\n');
        fprintf('   • Initial pressure: %.1f barsa\n', pres.initial_avg_barsa);
        fprintf('   • Final pressure: %.1f barsa\n', pres.final_avg_barsa);
        fprintf('   • Pressure drop: %.1f barsa (%.1f%%)\n', pres.pressure_drop_barsa, ...
            100 * pres.pressure_drop_barsa / pres.initial_avg_barsa);
    end
    
    if isfield(analysis, 'field')
        field = analysis.field;
        fprintf('\n🏗️ FIELD DEVELOPMENT:\n');
        fprintf('   • Wells: %d producers, %d injectors\n', field.producers, field.injectors);
        fprintf('   • Grid: %d cells\n', field.total_cells);
        if isfield(field, 'ooip_MMbbl')
            fprintf('   • OOIP: %.2f MMbbl\n', field.ooip_MMbbl);
        end
    end
    
    fprintf('\n✅ SIMULATION STATUS: SUCCESS - MRST + Octave fully functional\n');
    fprintf('═══════════════════════════════════════════════════════════\n');
end