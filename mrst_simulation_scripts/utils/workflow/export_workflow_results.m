function export_workflow_results(workflow_results)
% EXPORT_WORKFLOW_RESULTS - Export workflow results (DISABLED - No Over-Engineering)
%
% DISABLED: Workflow results files are redundant - actual data is in 9 modular .mat files
% Following KISS principle and No Over-Engineering policy
%
% SYNTAX:
%   export_workflow_results(workflow_results)
%
% INPUTS:
%   workflow_results - Complete workflow execution results structure
%
% OUTPUTS:
%   No files created - data exists in /workspace/data/mrst/*.mat files
%
% Author: Claude Code AI System
% Date: 2025-08-22

    % No export - data already exists in modular .mat files
    fprintf('📁 Workflow results available in modular data files:\n');
    fprintf('   • Grid: /workspace/data/mrst/grid.mat\n');
    fprintf('   • Rock: /workspace/data/mrst/rock.mat\n');
    fprintf('   • Fluid: /workspace/data/mrst/fluid.mat\n');
    fprintf('   • State: /workspace/data/mrst/state.mat\n');
    fprintf('   • Wells: /workspace/data/mrst/wells.mat\n');
    fprintf('   • Controls: /workspace/data/mrst/controls.mat\n');
    fprintf('   • Development: /workspace/data/mrst/development.mat\n');
    fprintf('   • Schedule: /workspace/data/mrst/schedule.mat\n');
    fprintf('   • Targets: /workspace/data/mrst/targets.mat\n\n');
    
    fprintf('✅ No redundant workflow files generated (KISS principle)\n\n');
end

function results_dir = get_results_directory(script_path, config)
    % Get canonical results directory from configuration
    if isfield(config.workflow_settings, 'results_directory')
        % Use absolute path directly (no concatenation with script_path)
        results_dir = config.workflow_settings.results_directory;
    else
        % Fallback to canonical default
        results_dir = '/workspace/data/mrst';
    end
end

function timestamp = get_canonical_timestamp(config)
    % Get timestamp in canonical format from configuration
    if isfield(config, 'output_settings') && isfield(config.output_settings, 'timestamp_format')
        timestamp = datestr(now, config.output_settings.timestamp_format);
    else
        timestamp = datestr(now, 'yyyymmdd_HHMMSS');
    end
end

function [results_file, summary_file] = generate_result_filenames(results_dir, timestamp)
    % Generate canonical result filenames
    results_file = fullfile(results_dir, sprintf('workflow_results_%s.mat', timestamp));
    summary_file = fullfile(results_dir, sprintf('workflow_summary_%s.txt', timestamp));
end