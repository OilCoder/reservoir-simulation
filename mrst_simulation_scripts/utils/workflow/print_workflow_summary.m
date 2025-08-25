function print_workflow_summary(results, status_msg, status_color)
% PRINT_WORKFLOW_SUMMARY - Display comprehensive workflow execution summary
%
% Prints detailed workflow summary with timing, statistics, and results
% following standardized table format for Eagle West Field simulation
%
% SYNTAX:
%   print_workflow_summary(results, status_msg, status_color)
%
% INPUTS:
%   results - Workflow results structure with execution data
%   status_msg - Summary status message (e.g., 'SUCCESS', 'FAILED')
%   status_color - Status emoji indicator (e.g., '✅', '❌')
%
% Author: Claude Code AI System
% Date: 2025-08-22

    % Header
    fprintf('\n');
    fprintf('################################################################\n');
    fprintf('#                                                              #\n');
    fprintf('#                 🏁 WORKFLOW SUMMARY                         #\n');
    fprintf('#                                                              #\n');
    fprintf('################################################################\n\n');
    
    % Overall status
    fprintf('%s OVERALL STATUS: %s\n\n', status_color, status_msg);
    
    % Timing information
    print_timing_section(results);
    
    % Execution statistics  
    print_statistics_section(results);
    
    % Completed phases
    print_completed_phases_section(results);
    
    % Warnings and errors
    print_issues_section(results);
    
    % Footer
    fprintf('################################################################\n\n');
end

function print_timing_section(results)
    % Print timing information section
    fprintf('⏰ TIMING INFORMATION\n');
    fprintf('════════════════════════\n');
    fprintf('Start: %s\n', results.start_time);
    fprintf('End: %s\n', results.end_time);
    fprintf('\n');
end

function print_statistics_section(results)
    % Print execution statistics section
    fprintf('📊 EXECUTION STATISTICS\n');
    fprintf('═══════════════════════\n');
    fprintf('Total Phases: %d\n', length(results.phases_executed));
    fprintf('✅ Successful: %d\n', results.success_count);
    fprintf('❌ Failed: %d\n', results.failure_count);
    fprintf('⚠️  Warnings: %d\n', length(results.warnings));
    fprintf('\n');
end

function print_completed_phases_section(results)
    % Print completed phases if any exist
    if ~isempty(results.phases_executed)
        fprintf('✅ COMPLETED PHASES\n');
        fprintf('═══════════════════\n');
        for i = 1:length(results.phases_executed)
            fprintf('  %d. %s ✓\n', i, upper(results.phases_executed{i}));
        end
        fprintf('\n');
    end
end

function print_issues_section(results)
    % Print warnings section
    if ~isempty(results.warnings)
        fprintf('⚠️  WARNINGS\n');
        fprintf('════════════\n');
        for i = 1:length(results.warnings)
            fprintf('  • %s\n', results.warnings{i});
        end
        fprintf('\n');
    end
    
    % Print errors section
    if ~isempty(results.errors)
        fprintf('❌ ERRORS\n');
        fprintf('══════════\n');
        for i = 1:length(results.errors)
            fprintf('  • %s\n', results.errors{i});
        end
        fprintf('\n');
    end
end