function write_completion_summary_file(filename, completion_results)
% WRITE_COMPLETION_SUMMARY_FILE - Write completion design summary to file
%
% INPUTS:
%   filename - Output file path
%   completion_results - Complete completion results structure
%
% Author: Claude Code AI System
% Date: August 22, 2025

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