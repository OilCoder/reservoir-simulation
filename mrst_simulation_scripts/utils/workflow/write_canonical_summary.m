function write_canonical_summary(filename, results, timestamp)
% WRITE_CANONICAL_SUMMARY - Write standardized workflow summary file
%
% Creates canonical text summary with provenance metadata
% following Data Authority policy for result traceability
%
% SYNTAX:
%   write_canonical_summary(filename, results, timestamp)
%
% INPUTS:
%   filename - Full path for summary text file
%   results - Workflow results structure
%   timestamp - Canonical timestamp for provenance
%
% Author: Claude Code AI System
% Date: 2025-08-22

    fid = fopen(filename, 'w');
    if fid == -1
        error('Failed to create summary file: %s', filename);
    end
    
    try
        % Header with provenance metadata
        fprintf(fid, 'Eagle West Field - Workflow Execution Summary\n');
        fprintf(fid, '=============================================\n\n');
        fprintf(fid, 'Generated: %s\n', timestamp);
        fprintf(fid, 'Generator: s99_run_workflow.m v3.0\n');
        fprintf(fid, 'Field: Eagle West Offshore Field\n\n');
        
        % Execution summary
        fprintf(fid, 'Execution Time: %s to %s\n', results.start_time, results.end_time);
        fprintf(fid, 'Status: %s\n', results.status);
        fprintf(fid, 'Phases Executed: %d\n', length(results.phases_executed));
        fprintf(fid, 'Success Count: %d\n', results.success_count);
        fprintf(fid, 'Failure Count: %d\n', results.failure_count);
        
        % Completed phases section
        if ~isempty(results.phases_executed)
            fprintf(fid, '\nCompleted Phases:\n');
            for i = 1:length(results.phases_executed)
                fprintf(fid, '  %d. %s\n', i, results.phases_executed{i});
            end
        end
        
        % Warnings section
        if ~isempty(results.warnings)
            fprintf(fid, '\nWarnings:\n');
            for i = 1:length(results.warnings)
                fprintf(fid, '  • %s\n', results.warnings{i});
            end
        end
        
        % Errors section
        if ~isempty(results.errors)
            fprintf(fid, '\nErrors:\n');
            for i = 1:length(results.errors)
                fprintf(fid, '  • %s\n', results.errors{i});
            end
        end
        
        % Footer with metadata
        fprintf(fid, '\n--- End of Summary ---\n');
        
    catch ME
        fclose(fid);
        rethrow(ME);
    end
    
    fclose(fid);
end