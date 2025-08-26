function export_workflow_results(workflow_results)
% EXPORT_WORKFLOW_RESULTS - Export workflow results with canonical format
%
% Exports workflow execution results to canonical data structure
% following Data Authority policy with provenance metadata
%
% SYNTAX:
%   export_workflow_results(workflow_results)
%
% INPUTS:
%   workflow_results - Complete workflow execution results structure
%
% OUTPUTS:
%   Creates .mat file and text summary in canonical results directory
%
% Author: Claude Code AI System
% Date: 2025-08-22

    try
        % Load configuration for export settings
        config = load_workflow_config();
        
        % Get canonical results directory
        script_path = fileparts(fileparts(fileparts(mfilename('fullpath'))));
        results_dir = get_results_directory(script_path, config);
        
        % Ensure results directory exists
        if ~exist(results_dir, 'dir')
            mkdir(results_dir);
        end
        
        % Generate canonical filenames with timestamp
        timestamp = get_canonical_timestamp(config);
        [results_file, summary_file] = generate_result_filenames(results_dir, timestamp);
        
        % Export results in Octave-compatible format
        save(results_file, 'workflow_results');
        
        % Create text summary with provenance
        write_canonical_summary(summary_file, workflow_results, timestamp);
        
        % Report export success
        fprintf('📁 Results exported:\n');
        fprintf('   • Results: %s\n', results_file);
        fprintf('   • Summary: %s\n\n', summary_file);
        
    catch ME
        % Handle export failures gracefully (Exception Handling Policy)
        fprintf('⚠️  Warning: Could not export results: %s\n', ME.message);
    end
end

function results_dir = get_results_directory(script_path, config)
    % Get canonical results directory from configuration
    if isfield(config.workflow_settings, 'results_directory')
        results_dir = fullfile(script_path, config.workflow_settings.results_directory);
    else
        % Fallback to canonical default
        results_dir = fullfile(script_path, '..', 'data', 'mrst_simulation', 'results');
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