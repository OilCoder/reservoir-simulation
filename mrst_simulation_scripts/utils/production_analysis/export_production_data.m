function export_production_data(production_results)
% EXPORT_PRODUCTION_DATA - Export production analysis results
%
% INPUT:
%   production_results - Structure with production analysis results

    % Create timestamp for files
    timestamp = datestr(now, 'yyyymmdd_HHMMSS');
    results_dir = '/workspaces/claudeclean/data/simulation_data/results';
    
    % Ensure results directory exists
    if ~exist(results_dir, 'dir')
        mkdir(results_dir);
    end
    
    % Export production analysis results
    analysis_file = fullfile(results_dir, sprintf('production_analysis_%s.mat', timestamp));
    save(analysis_file, '-struct', 'production_results');
    fprintf('   ✅ Analysis saved: %s\n', analysis_file);
    
    % Export production summary text
    summary_file = fullfile(results_dir, sprintf('production_summary_%s.txt', timestamp));
    write_production_summary(production_results, summary_file);
    fprintf('   ✅ Summary saved: %s\n', summary_file);
    
    % Export CSV timeseries if available
    if isfield(production_results, 'field_rates') && ...
       isfield(production_results.field_rates, 'oil_stb_day')
        csv_file = fullfile(results_dir, sprintf('production_timeseries_%s.csv', timestamp));
        write_production_timeseries_csv(production_results.field_rates, csv_file);
        fprintf('   ✅ Timeseries saved: %s\n', csv_file);
    end
end

function write_production_summary(production_results, filename)
% Write text summary of production results
    fid = fopen(filename, 'w');
    if fid == -1
        error('Cannot create production summary file: %s', filename);
    end
    
    try
        fprintf(fid, 'EAGLE WEST FIELD - PRODUCTION ANALYSIS SUMMARY\n');
        fprintf(fid, '==============================================\n');
        fprintf(fid, 'Generated: %s\n\n', datestr(now));
        
        if isfield(production_results, 'field_rates') && isfield(production_results.field_rates, 'summary')
            summary = production_results.field_rates.summary;
            fprintf(fid, 'FIELD PRODUCTION SUMMARY:\n');
            fprintf(fid, '  Peak Oil Rate: %.0f STB/day\n', summary.peak_oil_rate_stb_day);
            fprintf(fid, '  Ultimate Recovery: %.1f MMstb\n', summary.ultimate_recovery_mmstb);
            if isfield(summary, 'final_water_cut_percent')
                fprintf(fid, '  Final Water Cut: %.1f%%\n', summary.final_water_cut_percent);
                fprintf(fid, '  Pressure Decline: %.1f%%\n', summary.final_pressure_decline_percent);
            end
        end
        
        fclose(fid);
    catch ME
        fclose(fid);
        error('Error writing production summary: %s', ME.message);
    end
end

function write_production_timeseries_csv(field_rates, filename)
% Write CSV timeseries of production data
    fid = fopen(filename, 'w');
    if fid == -1
        error('Cannot create CSV file: %s', filename);
    end
    
    try
        % Header
        fprintf(fid, 'Time,Oil_STB_day,Water_STB_day,Gas_Mscf_day\n');
        
        % Data
        ntimes = length(field_rates.oil_stb_day);
        for i = 1:ntimes
            fprintf(fid, '%d,%.1f,%.1f,%.1f\n', i, ...
                field_rates.oil_stb_day(i), ...
                field_rates.water_stb_day(i), ...
                field_rates.gas_mscf_day(i));
        end
        
        fclose(fid);
    catch ME
        fclose(fid);
        error('Error writing CSV file: %s', ME.message);
    end
end