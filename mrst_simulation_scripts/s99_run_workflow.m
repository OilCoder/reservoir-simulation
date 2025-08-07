function workflow_results = s99_run_workflow(varargin)
% S99_RUN_WORKFLOW - Master workflow orchestrator for Eagle West Field simulation
%
% SYNTAX:
%   workflow_results = s99_run_workflow()
%   workflow_results = s99_run_workflow('validation_only', true)
%   workflow_results = s99_run_workflow('phases', {'s01', 's02', 's03'})
%
% INPUT (optional):
%   'validation_only' - logical, if true only run validation (default: false)
%   'phases' - cell array of phase IDs to run (default: all phases)
%   'verbose' - logical, detailed output (default: true)
%
% OUTPUT:
%   workflow_results - Structure containing execution results and metrics
%
% DESCRIPTION:
%   This script orchestrates the complete Eagle West Field reservoir
%   simulation workflow following the modular phase-based architecture
%   defined in project documentation.
%
%   Workflow Phases:
%   1. s01_initialize_mrst - MRST environment setup
%   2. s02_create_grid - Grid construction (40×40×12)  
%   3. s03_define_fluids - Fluid properties (3-phase black oil)
%   4. s04_structural_framework - Geological structure 
%   5. s05_add_faults - Fault system (5 major faults)
%   6. s06_grid_refinement - Local grid refinement
%   7. s07_define_rock_types - Rock types and properties
%   8. s08_assign_layer_properties - Layer property assignment
%   9. s09_spatial_heterogeneity - Spatial heterogeneity
%   10. s10_simulation - Full field simulation
%
% Author: Claude Code AI System
% Date: January 30, 2025

    fprintf('\n');
    fprintf('########################################################\n');
    fprintf('        EAGLE WEST FIELD RESERVOIR SIMULATION\n');
    fprintf('                MRST Workflow Orchestrator\n');
    fprintf('########################################################\n\n');
    
    % Parse input arguments
    p = inputParser;
    addParameter(p, 'validation_only', false, @islogical);
    addParameter(p, 'phases', {'all'}, @(x) iscell(x) || ischar(x));
    addParameter(p, 'verbose', true, @islogical);
    parse(p, varargin{:});
    
    options = p.Results;
    
    % Initialize workflow results
    workflow_results = struct();
    workflow_results.start_time = datestr(now);
    workflow_results.phases_executed = {};
    workflow_results.phase_results = struct();
    workflow_results.success_count = 0;
    workflow_results.failure_count = 0;
    workflow_results.warnings = {};
    workflow_results.errors = {};
    workflow_results.status = 'running';
    
    % Workflow data storage (passed between phases)
    workflow_data = struct();
    
    try
        % Define workflow phases
        phases = define_workflow_phases();
        
        % Determine which phases to run
        if ischar(options.phases) && strcmp(options.phases, 'all')
            phases_to_run = phases;
        else
            phases_to_run = filter_phases(phases, options.phases);
        end
        
        if options.verbose
            fprintf('Workflow Configuration:\n');
            fprintf('  Validation only: %s\n', yesno(options.validation_only));
            fprintf('  Phases to run: %d of %d\n', length(phases_to_run), length(phases));
            fprintf('  Verbose output: %s\n', yesno(options.verbose));
            fprintf('\n');
            
            fprintf('Phase Overview:\n');
            for i = 1:length(phases_to_run)
                phase = phases_to_run{i};
                status = get_phase_implementation_status(phase.script_name);
                fprintf('  %s: %s %s\n', phase.phase_id, phase.description, status);
            end
            fprintf('\n');
        end
        
        % Execute workflow phases
        fprintf('Starting workflow execution...\n\n');
        
        for i = 1:length(phases_to_run)
            phase = phases_to_run{i};
            
            % Check if validation only and we've done basic validation
            if options.validation_only && i > 3
                fprintf('Validation-only mode: Stopping after basic phases\n\n');
                break;
            end
            
            % Execute phase
            try
                fprintf('=== PHASE %d: %s ===\n', i, upper(phase.phase_id));
                phase_start_time = tic;
                
                % Execute the specific phase
                phase_result = execute_phase(phase, workflow_data, options);
                
                % Record success
                execution_time = toc(phase_start_time);
                workflow_results.phases_executed{end+1} = phase.phase_id;
                workflow_results.phase_results.(phase.phase_id) = phase_result;
                workflow_results.phase_results.(phase.phase_id).execution_time = execution_time;
                workflow_results.success_count = workflow_results.success_count + 1;
                
                % Store phase output in workflow data for next phases
                if isfield(phase_result, 'output_data')
                    workflow_data.(phase.phase_id) = phase_result.output_data;
                end
                
                fprintf('✓ Phase %s completed successfully (%.1f seconds)\n\n', ...
                        phase.phase_id, execution_time);
                
            catch ME
                % Handle phase failure
                fprintf('❌ Phase %s FAILED: %s\n\n', phase.phase_id, ME.message);
                
                workflow_results.phase_results.(phase.phase_id) = struct();
                workflow_results.phase_results.(phase.phase_id).status = 'failed';
                workflow_results.phase_results.(phase.phase_id).error_message = ME.message;
                workflow_results.failure_count = workflow_results.failure_count + 1;
                workflow_results.errors{end+1} = sprintf('Phase %s: %s', phase.phase_id, ME.message);
                
                % Decide whether to continue or stop (FAIL_FAST policy)
                if phase.critical
                    error('Critical phase %s failed. Stopping workflow.', phase.phase_id);
                else
                    warning('Non-critical phase %s failed. Continuing workflow.', phase.phase_id);
                    workflow_results.warnings{end+1} = sprintf('Phase %s failed but workflow continued', phase.phase_id);
                end
            end
        end
        
        % Calculate final results
        total_execution_time = calculate_total_time(workflow_results.phase_results);
        workflow_results.total_execution_time = total_execution_time;
        workflow_results.end_time = datestr(now);
        
        if workflow_results.failure_count == 0
            workflow_results.status = 'completed_successfully';
            status_msg = 'SUCCESS';
        else
            workflow_results.status = 'completed_with_errors';  
            status_msg = 'COMPLETED WITH ERRORS';
        end
        
        % Print final summary
        print_workflow_summary(workflow_results, status_msg);
        
        % Export workflow results
        export_workflow_results(workflow_results, workflow_data);
        
    catch ME
        % Handle workflow-level failure
        fprintf('\n❌ WORKFLOW EXECUTION FAILED\n');
        fprintf('Error: %s\n', ME.message);
        if ~isempty(ME.stack)
            fprintf('Location: %s (line %d)\n', ME.stack(1).file, ME.stack(1).line);
        end
        
        workflow_results.status = 'failed';
        workflow_results.end_time = datestr(now);
        workflow_results.errors{end+1} = ME.message;
        
        print_workflow_summary(workflow_results, 'FAILED');
        
        rethrow(ME);
    end

end

function phases = define_workflow_phases()
% DEFINE_WORKFLOW_PHASES - Define all workflow phases with metadata
%
% OUTPUT:
%   phases - Cell array of phase definition structures

    phases = {
        struct('phase_id', 's01', 'script_name', 's01_initialize_mrst', ...
               'description', 'Initialize MRST Environment', ...
               'critical', true, 'estimated_time', 30),
               
        struct('phase_id', 's02', 'script_name', 's02_create_grid', ...
               'description', 'Create Reservoir Grid (40×40×12)', ...
               'critical', true, 'estimated_time', 60),
               
        struct('phase_id', 's03', 'script_name', 's03_define_fluids', ...
               'description', 'Define Fluid Properties (3-phase)', ...
               'critical', true, 'estimated_time', 45),
               
        struct('phase_id', 's04', 'script_name', 's04_structural_framework', ...
               'description', 'Setup Structural Framework', ...
               'critical', true, 'estimated_time', 90),
               
        struct('phase_id', 's05', 'script_name', 's05_add_faults', ...
               'description', 'Add Fault System (5 faults)', ...
               'critical', true, 'estimated_time', 75),
               
        struct('phase_id', 's06', 'script_name', 's06_grid_refinement', ...
               'description', 'Apply Grid Refinement', ...
               'critical', false, 'estimated_time', 120),
               
        struct('phase_id', 's07', 'script_name', 's07_define_rock_types', ...
               'description', 'Define Rock Types (RT1-RT6)', ...
               'critical', true, 'estimated_time', 60),
               
        struct('phase_id', 's08', 'script_name', 's08_assign_layer_properties', ...
               'description', 'Assign Layer Properties', ...
               'critical', true, 'estimated_time', 180),
               
        struct('phase_id', 's09', 'script_name', 's09_spatial_heterogeneity', ...
               'description', 'Apply Spatial Heterogeneity', ...
               'critical', false, 'estimated_time', 240),
               
        struct('phase_id', 's10', 'script_name', 's10_run_simulation', ...
               'description', 'Run Full Field Simulation', ...
               'critical', true, 'estimated_time', 1800)
    };

end

function filtered_phases = filter_phases(phases, requested_phases)
% FILTER_PHASES - Filter phases based on requested phase IDs
%
% INPUT:
%   phases - All available phases
%   requested_phases - Cell array of requested phase IDs
%
% OUTPUT:
%   filtered_phases - Filtered phase list

    filtered_phases = {};
    
    for i = 1:length(requested_phases)
        requested_id = requested_phases{i};
        
        % Find matching phase
        found = false;
        for j = 1:length(phases)
            if strcmp(phases{j}.phase_id, requested_id)
                filtered_phases{end+1} = phases{j};
                found = true;
                break;
            end
        end
        
        if ~found
            warning('Requested phase not found: %s', requested_id);
        end
    end

end

function status = get_phase_implementation_status(script_name)
% GET_PHASE_IMPLEMENTATION_STATUS - Check if phase script exists
%
% INPUT:
%   script_name - Name of the script file
%
% OUTPUT:
%   status - Status string

    script_file = [script_name '.m'];
    
    if exist(script_file, 'file')
        status = '✓ Implemented';
    else
        status = '❌ Not Implemented';
    end

end

function phase_result = execute_phase(phase, workflow_data, options)
% EXECUTE_PHASE - Execute a single workflow phase
%
% INPUT:
%   phase - Phase definition structure
%   workflow_data - Data from previous phases
%   options - Execution options
%
% OUTPUT:
%   phase_result - Phase execution results

    phase_result = struct();
    phase_result.status = 'running';
    phase_result.phase_id = phase.phase_id;
    
    % Check if script exists
    script_file = [phase.script_name '.m'];
    if ~exist(script_file, 'file')
        if phase.critical
            error('Critical script not found: %s', script_file);
        else
            warning('Script not found: %s. Creating placeholder.', script_file);
            create_placeholder_script(phase.script_name, phase.description);
            phase_result.status = 'skipped';
            phase_result.message = 'Script not implemented - placeholder created';
            return;
        end
    end
    
    % Execute the phase script
    try
        switch phase.phase_id
            case 's01'
                % Initialize MRST
                mrst_env = s01_initialize_mrst();
                phase_result.output_data = mrst_env;
                
            case 's02'
                % Create grid
                G = s02_create_grid();
                phase_result.output_data = G;
                
            case 's03'
                % Define fluids
                fluid = s03_define_fluids();
                phase_result.output_data = fluid;
                
            otherwise
                % For unimplemented phases, call the function if it exists
                if exist(phase.script_name, 'file')
                    output_data = feval(phase.script_name);
                    phase_result.output_data = output_data;
                else
                    phase_result.status = 'skipped';
                    phase_result.message = 'Script not implemented';
                    return;
                end
        end
        
        phase_result.status = 'completed';
        
    catch ME
        phase_result.status = 'failed';
        phase_result.error_message = ME.message;
        rethrow(ME);
    end

end

function create_placeholder_script(script_name, description)
% CREATE_PLACEHOLDER_SCRIPT - Create placeholder for unimplemented scripts
%
% INPUT:
%   script_name - Name of script to create
%   description - Phase description

    script_file = [script_name '.m'];
    
    fid = fopen(script_file, 'w');
    fprintf(fid, 'function output = %s()\n', script_name);
    fprintf(fid, '%% %s - %s\n', upper(script_name), description);
    fprintf(fid, '%%\n');
    fprintf(fid, '%% PLACEHOLDER FUNCTION - NOT YET IMPLEMENTED\n');
    fprintf(fid, '%%\n');
    fprintf(fid, '%% This is a placeholder script created automatically by s99_run_workflow.\n');
    fprintf(fid, '%% Please implement the actual functionality according to project documentation.\n');
    fprintf(fid, '%%\n');
    fprintf(fid, '%% Author: Claude Code AI System\n');
    fprintf(fid, '%% Date: %s\n\n', datestr(now));
    
    fprintf(fid, '    fprintf(''======================================================\\n'');\n');
    fprintf(fid, '    fprintf(''%s - %s\\n'');\n', upper(script_name), description);
    fprintf(fid, '    fprintf(''======================================================\\n\\n'');\n');
    fprintf(fid, '    \n');
    fprintf(fid, '    fprintf(''⚠️  PLACEHOLDER: This script is not yet implemented\\n'');\n');
    fprintf(fid, '    fprintf(''Please implement according to project documentation\\n\\n'');\n');
    fprintf(fid, '    \n');
    fprintf(fid, '    %% Return empty output for now\n');
    fprintf(fid, '    output = struct();\n');
    fprintf(fid, '    output.status = ''placeholder'';\n');
    fprintf(fid, '    output.message = ''Script not yet implemented'';\n\n');
    fprintf(fid, 'end\n');
    
    fclose(fid);
    
    fprintf('   Created placeholder script: %s\n', script_file);

end

function total_time = calculate_total_time(phase_results)
% CALCULATE_TOTAL_TIME - Calculate total execution time from phase results
%
% INPUT:
%   phase_results - Structure containing phase execution results
%
% OUTPUT:
%   total_time - Total execution time in seconds

    total_time = 0;
    phase_names = fieldnames(phase_results);
    
    for i = 1:length(phase_names)
        phase_data = phase_results.(phase_names{i});
        if isfield(phase_data, 'execution_time')
            total_time = total_time + phase_data.execution_time;
        end
    end

end

function print_workflow_summary(workflow_results, status_msg)
% PRINT_WORKFLOW_SUMMARY - Print comprehensive workflow summary
%
% INPUT:
%   workflow_results - Workflow execution results
%   status_msg - Overall status message

    fprintf('########################################################\n');
    fprintf('                 WORKFLOW EXECUTION SUMMARY\n');
    fprintf('########################################################\n\n');
    
    fprintf('Overall Status: %s\n', status_msg);
    fprintf('Start Time: %s\n', workflow_results.start_time);
    fprintf('End Time: %s\n', workflow_results.end_time);
    fprintf('Total Execution Time: %.1f seconds\n', workflow_results.total_execution_time);
    fprintf('\n');
    
    fprintf('Phase Statistics:\n');
    fprintf('  Phases Executed: %d\n', length(workflow_results.phases_executed));
    fprintf('  Successful: %d\n', workflow_results.success_count);
    fprintf('  Failed: %d\n', workflow_results.failure_count);
    fprintf('  Warnings: %d\n', length(workflow_results.warnings));
    fprintf('\n');
    
    % Phase-by-phase results
    if ~isempty(workflow_results.phases_executed)
        fprintf('Phase Execution Results:\n');
        for i = 1:length(workflow_results.phases_executed)
            phase_id = workflow_results.phases_executed{i};
            phase_data = workflow_results.phase_results.(phase_id);
            
            if isfield(phase_data, 'execution_time')
                time_str = sprintf('(%.1fs)', phase_data.execution_time);
            else
                time_str = '';
            end
            
            fprintf('  %s: ✓ %s\n', phase_id, time_str);
        end
        fprintf('\n');
    end
    
    % Print warnings if any
    if ~isempty(workflow_results.warnings)
        fprintf('Warnings:\n');
        for i = 1:length(workflow_results.warnings)
            fprintf('  ⚠️  %s\n', workflow_results.warnings{i});
        end
        fprintf('\n');
    end
    
    % Print errors if any
    if ~isempty(workflow_results.errors)
        fprintf('Errors:\n');
        for i = 1:length(workflow_results.errors)
            fprintf('  ❌ %s\n', workflow_results.errors{i});
        end
        fprintf('\n');
    end
    
    fprintf('########################################################\n\n');

end

function export_workflow_results(workflow_results, workflow_data)
% EXPORT_WORKFLOW_RESULTS - Export workflow results to files
%
% INPUT:
%   workflow_results - Workflow execution results
%   workflow_data - Workflow data from phases

    % Create output directory
    script_path = fileparts(mfilename('fullpath'));
    data_dir = fullfile(fileparts(script_path), 'data', 'mrst_simulation', 'results');
    
    if ~exist(data_dir, 'dir')
        mkdir(data_dir);
    end
    
    % Generate timestamp for files
    timestamp = datestr(now, 'yyyymmdd_HHMMSS');
    
    % Save complete results in MATLAB format
    results_file = fullfile(data_dir, sprintf('workflow_results_%s.mat', timestamp));
    save(results_file, 'workflow_results', 'workflow_data', '');
    
    % Save summary report
    summary_file = fullfile(data_dir, sprintf('workflow_summary_%s.txt', timestamp));
    fid = fopen(summary_file, 'w');
    
    fprintf(fid, 'Eagle West Field - Workflow Execution Summary\n');
    fprintf(fid, '=============================================\n\n');
    fprintf(fid, 'Execution Date: %s\n', workflow_results.start_time);
    fprintf(fid, 'Status: %s\n', workflow_results.status);
    fprintf(fid, 'Total Time: %.1f seconds\n', workflow_results.total_execution_time);
    fprintf(fid, 'Phases Executed: %d\n', length(workflow_results.phases_executed));
    fprintf(fid, 'Success Count: %d\n', workflow_results.success_count);
    fprintf(fid, 'Failure Count: %d\n', workflow_results.failure_count);
    
    if ~isempty(workflow_results.phases_executed)
        fprintf(fid, '\nPhase Results:\n');
        for i = 1:length(workflow_results.phases_executed)
            phase_id = workflow_results.phases_executed{i};
            phase_data = workflow_results.phase_results.(phase_id);
            
            if isfield(phase_data, 'execution_time')
                fprintf(fid, '  %s: Success (%.1fs)\n', phase_id, phase_data.execution_time);
            else
                fprintf(fid, '  %s: Success\n', phase_id);
            end
        end
    end
    
    if ~isempty(workflow_results.warnings)
        fprintf(fid, '\nWarnings:\n');
        for i = 1:length(workflow_results.warnings)
            fprintf(fid, '  - %s\n', workflow_results.warnings{i});
        end
    end
    
    if ~isempty(workflow_results.errors)
        fprintf(fid, '\nErrors:\n');
        for i = 1:length(workflow_results.errors)
            fprintf(fid, '  - %s\n', workflow_results.errors{i});
        end
    end
    
    fclose(fid);
    
    fprintf('Workflow results exported:\n');
    fprintf('  Results file: %s\n', results_file);
    fprintf('  Summary file: %s\n', summary_file);

end

function str = yesno(bool_val)
% YESNO - Convert boolean to yes/no string
    if bool_val
        str = 'Yes';
    else
        str = 'No';
    end
end

% Main execution when called as script
if ~nargout
    % If called as script (not function), run complete workflow
    try
        workflow_results = s99_run_workflow();
        
        if strcmp(workflow_results.status, 'completed_successfully')
            fprintf('🎉 Eagle West Field simulation workflow completed successfully!\n\n');
        else
            fprintf('⚠️  Eagle West Field simulation workflow completed with issues.\n');
            fprintf('Check the results and logs for details.\n\n');
        end
        
    catch ME
        fprintf('💥 Eagle West Field simulation workflow failed:\n');
        fprintf('   %s\n\n', ME.message);
        fprintf('Please check configuration files and MRST installation.\n');
        exit(1);
    end
end