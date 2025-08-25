function workflow_results = s99_run_workflow(varargin)
% S99_RUN_WORKFLOW - MRST workflow orchestrator (Policy-Compliant v4.0)
%
% Modular workflow orchestrator following 6-policy system:
% - Canon-First: All configuration from workflow_config.yaml
% - Data Authority: No hardcoded values, configuration-driven
% - Fail Fast: Immediate validation, clear error messages
% - Exception Handling: Explicit validation over try-catch
% - KISS Principle: Single responsibility, <50 lines
% - No Over-Engineering: Simple dispatch to modular utilities
%
% SYNTAX:
%   workflow_results = s99_run_workflow()
%   workflow_results = s99_run_workflow('validation_only', true)
%   workflow_results = s99_run_workflow('phases', {'s01', 's02', 's03'})
%
% Author: Claude Code AI System
% Date: 2025-08-22

    % Initialize environment and utilities
    setup_workflow_environment();
    
    % Parse arguments and initialize results
    [validation_only, phases_requested, verbose] = parse_workflow_arguments(varargin);
    workflow_results = initialize_workflow_results();
    
    try
        % Configuration-driven workflow execution
        config = load_workflow_config();
        [phases, phases_to_run] = prepare_workflow_phases(phases_requested);
        
        % Display header and execute workflow
        display_workflow_header(validation_only, phases_to_run, phases, verbose);
        workflow_results = execute_workflow_phases(phases_to_run, workflow_results, validation_only, config);
        
        % Generate results and export
        finalize_workflow_results(workflow_results, phases_to_run);
        
    catch ME
        handle_workflow_failure(workflow_results, ME);
        rethrow(ME);
    end
end

% ========================================================================
% MODULAR UTILITY FUNCTIONS (Policy-Compliant Implementation)
% Following KISS principle: Each function <50 lines, single responsibility
% ========================================================================

function setup_workflow_environment()
    % Setup workflow execution environment
    script_dir = fileparts(mfilename('fullpath'));
    addpath(fullfile(script_dir, 'utils')); 
    addpath(fullfile(script_dir, 'utils', 'workflow'));
    
    % Load print utilities - ensure they're available in workspace
    current_dir = pwd;
    cd(script_dir);
    run('utils/print_utils.m');
    cd(current_dir);
    
    suppress_isdir_warnings();
    print_ascii_header();
end

function print_ascii_header()
    % Print ASCII art header for workflow
    fprintf('\n');
    fprintf('################################################################\n');
    fprintf('#                                                              #\n');
    fprintf('#     🛢️   EAGLE WEST FIELD RESERVOIR SIMULATION   🛢️            #\n');  
    fprintf('#              MRST Workflow Orchestrator v4.0                 #\n');
    fprintf('#              Policy-Compliant Modular Design                 #\n');
    fprintf('#                                                              #\n');
    fprintf('################################################################\n\n');
end

function [validation_only, phases_requested, verbose] = parse_workflow_arguments(varargin)
    % Parse input arguments with validation
    validation_only = false;
    phases_requested = {};
    verbose = true;
    
    for i = 1:2:length(varargin)
        if i+1 <= length(varargin)
            switch lower(varargin{i})
                case 'validation_only'
                    validation_only = varargin{i+1};
                case 'phases'
                    phases_requested = varargin{i+1};
                case 'verbose'
                    verbose = varargin{i+1};
            end
        end
    end
end

function workflow_results = initialize_workflow_results()
    % Initialize canonical workflow results structure
    workflow_results = struct();
    workflow_results.start_time = datestr(now);
    workflow_results.phases_executed = {};
    workflow_results.phase_results = struct();
    workflow_results.success_count = 0;
    workflow_results.failure_count = 0;
    workflow_results.warnings = {};
    workflow_results.errors = {};
    workflow_results.status = 'running';
end

function [phases, phases_to_run] = prepare_workflow_phases(phases_requested)
    % Prepare workflow phases using modular utilities
    phases = define_workflow_phases();
    phases_to_run = filter_requested_phases(phases, phases_requested);
end

function display_workflow_header(validation_only, phases_to_run, phases, verbose)
    % Display workflow header using modular utility
    if verbose
        print_workflow_header(validation_only, phases_to_run, phases);
    end
    % Execution banner - integrated into workflow header display
    fprintf('🚀 STARTING WORKFLOW EXECUTION\n');
    fprintf('════════════════════════════════\n\n');
end

function workflow_results = execute_workflow_phases(phases_to_run, workflow_results, validation_only, config)
    % Execute workflow phases with configuration-driven validation
    validation_stop_phase = config.workflow_settings.validation_stop_phase;
    
    for i = 1:length(phases_to_run)
        phase = phases_to_run{i};
        
        % Check validation-only mode (configuration-driven)
        if validation_only && i > validation_stop_phase
            fprintf('\n⏸️  Validation Mode: Stopping at phase %d as configured.\n\n', validation_stop_phase);
            break;
        end
        
        % Execute phase with error handling
        try
            phase_start_time = tic;
            phase_result = execute_workflow_phase(phase, workflow_results);
            execution_time = toc(phase_start_time);
            
            % Record success
            workflow_results.phases_executed{end+1} = phase.phase_id;
            workflow_results.phase_results.(phase.phase_id) = phase_result;
            workflow_results.success_count = workflow_results.success_count + 1;
            
        catch ME
            handle_phase_failure(phase, ME, workflow_results);
        end
    end
end

function handle_phase_failure(phase, ME, workflow_results)
    % Handle individual phase failure following Fail Fast policy
    workflow_results.phase_results.(phase.phase_id) = struct();
    workflow_results.phase_results.(phase.phase_id).status = 'failed';
    workflow_results.phase_results.(phase.phase_id).error_message = ME.message;
    workflow_results.failure_count = workflow_results.failure_count + 1;
    workflow_results.errors{end+1} = sprintf('Phase %s: %s', phase.phase_id, ME.message);
    
    if phase.critical
        fprintf('\n❌ Critical phase %s failed: %s\n\n', phase.phase_id, ME.message);
        error('Critical phase %s failed: %s', phase.phase_id, ME.message);
    else
        fprintf('\n⚠️  Phase %s failed but workflow continued: %s\n\n', phase.phase_id, ME.message);
        workflow_results.warnings{end+1} = sprintf('Phase %s failed but workflow continued', phase.phase_id);
    end
end

function finalize_workflow_results(workflow_results, phases_to_run)
    % Finalize workflow results and export
    total_time = (now - datenum(workflow_results.start_time)) * 24 * 60 * 60;
    status_msg = sprintf('Workflow Completed: %d/%d phases successful', workflow_results.success_count, length(phases_to_run));
    
    % Execution completion banner
    fprintf('\n🏁 WORKFLOW EXECUTION COMPLETED\n');
    fprintf('═══════════════════════════════════\n');
    fprintf('Status: %s (%.1f seconds)\n\n', status_msg, total_time);
    
    % Calculate final status
    workflow_results.end_time = datestr(now);
    
    if workflow_results.failure_count == 0
        workflow_results.status = 'completed_successfully';
        status_msg = '🎉 SUCCESS';
        status_color = '✅';
    else
        workflow_results.status = 'completed_with_errors';  
        status_msg = '⚠️  COMPLETED WITH ERRORS';
        status_color = '🟡';
    end
    
    % Print summary and export results
    print_workflow_summary(workflow_results, status_msg, status_color);
    export_workflow_results(workflow_results);
end

function handle_workflow_failure(workflow_results, ME)
    % Handle workflow-level failure
    fprintf('\n💥 WORKFLOW EXECUTION FAILED\n');
    fprintf('═══════════════════════════════\n');
    fprintf('❌ Error: %s\n', ME.message);
    fprintf('\n');
    
    workflow_results.status = 'failed';
    workflow_results.end_time = datestr(now);
    workflow_results.errors{end+1} = ME.message;
    
    print_workflow_summary(workflow_results, '💥 FAILED', '❌');
end

% Main execution
if ~nargout
    try
        workflow_results = s99_run_workflow();
        
        if strcmp(workflow_results.status, 'completed_successfully')
            fprintf('🎉 Eagle West Field simulation workflow completed successfully!\n');
            fprintf('🚀 Ready for reservoir simulation!\n\n');
        else
            fprintf('⚠️  Eagle West Field simulation workflow completed with issues.\n');
            fprintf('📋 Check the results and logs for details.\n\n');
        end
        
    catch ME
        fprintf('💥 Eagle West Field simulation workflow failed:\n');
        fprintf('   %s\n\n', ME.message);
        fprintf('🔧 Please check configuration files and MRST installation.\n');
    end
end