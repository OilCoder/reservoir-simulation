function workflow_results = s99_run_workflow_fixed(varargin)
% S99_RUN_WORKFLOW_FIXED - Fixed MRST workflow orchestrator for Octave compatibility
%
% SYNTAX:
%   workflow_results = s99_run_workflow_fixed()
%   workflow_results = s99_run_workflow_fixed('validation_only', true)
%   workflow_results = s99_run_workflow_fixed('phases', {'s01', 's02', 's03'})
%
% Author: Claude Code AI System
% Date: January 30, 2025

    % ASCII Art Header
    fprintf('\n');
    fprintf('################################################################\n');
    fprintf('#                                                              #\n');
    fprintf('#     🛢️   EAGLE WEST FIELD RESERVOIR SIMULATION   🛢️       #\n');  
    fprintf('#              MRST Workflow Orchestrator v2.0                #\n');
    fprintf('#                  Octave Compatible                          #\n');
    fprintf('#                                                              #\n');
    fprintf('################################################################\n\n');
    
    % Parse input arguments (simplified for Octave compatibility)
    validation_only = false;
    phases_requested = {};
    verbose = true;
    
    % Simple argument parsing
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
    
    try
        % Define workflow phases
        phases = define_workflow_phases();
        
        % Determine which phases to run (fixed logic)
        if isempty(phases_requested)
            phases_to_run = phases;
        else
            phases_to_run = filter_phases_fixed(phases, phases_requested);
        end
        
        if verbose
            print_workflow_header(validation_only, phases_to_run, phases);
        end
        
        % Execute workflow phases with progress indicators
        fprintf('🚀 Starting workflow execution...\n\n');
        
        for i = 1:length(phases_to_run)
            phase = phases_to_run{i};
            
            % Check validation-only mode
            if validation_only && i > 3
                fprintf('✋ Validation-only mode: Stopping after basic phases\n\n');
                break;
            end
            
            % Execute phase with progress display
            try
                print_phase_header(i, length(phases_to_run), phase);
                phase_start_time = tic;
                
                % Execute the specific phase
                phase_result = execute_phase_fixed(phase, workflow_results);
                
                % Record success
                execution_time = toc(phase_start_time);
                workflow_results.phases_executed{end+1} = phase.phase_id;
                workflow_results.phase_results.(phase.phase_id) = phase_result;
                workflow_results.success_count = workflow_results.success_count + 1;
                
                print_phase_success(phase.phase_id, execution_time);
                
            catch ME
                % Handle phase failure
                execution_time = toc(phase_start_time);
                print_phase_failure(phase.phase_id, ME.message);
                
                workflow_results.phase_results.(phase.phase_id) = struct();
                workflow_results.phase_results.(phase.phase_id).status = 'failed';
                workflow_results.phase_results.(phase.phase_id).error_message = ME.message;
                workflow_results.failure_count = workflow_results.failure_count + 1;
                workflow_results.errors{end+1} = sprintf('Phase %s: %s', phase.phase_id, ME.message);
                
                if phase.critical
                    error('Critical phase %s failed: %s', phase.phase_id, ME.message);
                else
                    fprintf('⚠️  Non-critical phase failed, continuing...\n\n');
                    workflow_results.warnings{end+1} = sprintf('Phase %s failed but workflow continued', phase.phase_id);
                end
            end
        end
        
        % Calculate final results
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
        
        % Print final summary
        print_workflow_summary(workflow_results, status_msg, status_color);
        
        % Export workflow results (Octave compatible)
        export_workflow_results_octave(workflow_results);
        
    catch ME
        % Handle workflow-level failure
        print_workflow_failure(ME.message);
        
        workflow_results.status = 'failed';
        workflow_results.end_time = datestr(now);
        workflow_results.errors{end+1} = ME.message;
        
        print_workflow_summary(workflow_results, '💥 FAILED', '❌');
        
        rethrow(ME);
    end

end

function phases = define_workflow_phases()
    % Define all workflow phases (same as before but simplified)
    phases = {};
    
    phases{1} = struct('phase_id', 's01', 'script_name', 's01_initialize_mrst', ...
                      'description', 'Initialize MRST Environment', ...
                      'critical', true, 'estimated_time', 30);
                      
    phases{2} = struct('phase_id', 's02', 'script_name', 's02_create_grid', ...
                      'description', 'Create Grid (40×40×12)', ...
                      'critical', true, 'estimated_time', 60);
                      
    phases{3} = struct('phase_id', 's03', 'script_name', 's03_define_fluids', ...
                      'description', 'Define Fluids (3-phase)', ...
                      'critical', true, 'estimated_time', 45);
                      
    phases{4} = struct('phase_id', 's04', 'script_name', 's04_structural_framework', ...
                      'description', 'Structural Framework', ...
                      'critical', true, 'estimated_time', 90);
                      
    phases{5} = struct('phase_id', 's05', 'script_name', 's05_add_faults', ...
                      'description', 'Add Fault System', ...
                      'critical', true, 'estimated_time', 75);
                      
    phases{6} = struct('phase_id', 's06', 'script_name', 's06_grid_refinement', ...
                      'description', 'Grid Refinement', ...
                      'critical', false, 'estimated_time', 120);
                      
    phases{7} = struct('phase_id', 's07', 'script_name', 's07_define_rock_types', ...
                      'description', 'Rock Types (RT1-RT6)', ...
                      'critical', true, 'estimated_time', 60);
                      
    phases{8} = struct('phase_id', 's08', 'script_name', 's08_assign_layer_properties', ...
                      'description', 'Layer Properties', ...
                      'critical', true, 'estimated_time', 180);
                      
    phases{9} = struct('phase_id', 's09', 'script_name', 's09_spatial_heterogeneity', ...
                      'description', 'Spatial Heterogeneity', ...
                      'critical', false, 'estimated_time', 240);
end

function filtered_phases = filter_phases_fixed(phases, requested_phases)
    % Fixed phase filtering logic
    filtered_phases = {};
    
    if isempty(requested_phases)
        filtered_phases = phases;
        return;
    end
    
    if ischar(requested_phases)
        requested_phases = {requested_phases};
    end
    
    for i = 1:length(requested_phases)
        requested_id = requested_phases{i};
        
        % Find matching phase
        for j = 1:length(phases)
            if strcmp(phases{j}.phase_id, requested_id)
                filtered_phases{end+1} = phases{j};
                break;
            end
        end
    end
end

function print_workflow_header(validation_only, phases_to_run, all_phases)
    fprintf('📋 WORKFLOW CONFIGURATION\n');
    fprintf('══════════════════════════\n');
    fprintf('🔧 Mode: %s\n', ternary(validation_only, 'Validation Only', 'Full Execution'));
    fprintf('📊 Phases: %d of %d selected\n', length(phases_to_run), length(all_phases));
    fprintf('💻 Platform: Octave Compatible\n');
    fprintf('🕐 Start Time: %s\n\n', datestr(now));
    
    fprintf('📈 PHASE OVERVIEW\n');
    fprintf('═════════════════\n');
    for i = 1:length(phases_to_run)
        phase = phases_to_run{i};
        status = get_phase_status(phase.script_name);
        priority = ternary(phase.critical, '🔴 Critical', '🟡 Optional');
        fprintf('  %d. %s: %s [%s] %s\n', i, phase.phase_id, phase.description, priority, status);
    end
    fprintf('\n');
end

function print_phase_header(current, total, phase)
    fprintf('╔══════════════════════════════════════════════════════════════════╗\n');
    fprintf('║  Phase %d/%d: %-20s                                ║\n', current, total, upper(phase.phase_id));
    fprintf('║  📝 %s                                                    \n', phase.description);
    fprintf('║  ⏱️  Estimated time: %d seconds                                   ║\n', phase.estimated_time);
    fprintf('╚══════════════════════════════════════════════════════════════════╝\n\n');
end

function print_phase_success(phase_id, execution_time)
    fprintf('\n✅ Phase %s completed successfully in %.1f seconds\n', upper(phase_id), execution_time);
    fprintf('════════════════════════════════════════════════════════════════════\n\n');
end

function print_phase_failure(phase_id, error_message)
    fprintf('\n❌ Phase %s FAILED\n', upper(phase_id));
    fprintf('Error: %s\n', error_message);
    fprintf('════════════════════════════════════════════════════════════════════\n\n');
end

function phase_result = execute_phase_fixed(phase, workflow_results)
    % Execute phase with better error handling
    phase_result = struct();
    phase_result.status = 'running';
    phase_result.phase_id = phase.phase_id;
    
    % Check if script exists
    script_file = [phase.script_name '.m'];
    if ~exist(script_file, 'file')
        if phase.critical
            error('Critical script not found: %s', script_file);
        else
            fprintf('⚠️  Script not found: %s\n', script_file);
            phase_result.status = 'skipped';
            phase_result.message = 'Script not found';
            return;
        end
    end
    
    % Execute the phase
    fprintf('🔄 Executing %s...\n', phase.script_name);
    
    try
        switch phase.phase_id
            case 's01'
                fprintf('🔧 Initializing MRST environment...\n');
                output_data = s01_initialize_mrst();
                
            case 's02'
                fprintf('🏗️  Creating reservoir grid...\n');
                output_data = s02_create_grid();
                
            case 's03'
                fprintf('💧 Defining fluid properties...\n');
                output_data = s03_define_fluids();
                
            case 's04'
                fprintf('🏔️  Setting up structural framework...\n');
                output_data = s04_structural_framework();
                
            case 's05'
                fprintf('⚡ Adding fault system...\n');
                output_data = s05_add_faults();
                
            case 's06'
                fprintf('🔍 Applying grid refinement...\n');
                output_data = s06_grid_refinement();
                
            case 's07'
                fprintf('🪨 Defining rock types...\n');
                output_data = s07_define_rock_types();
                
            case 's08'
                fprintf('📊 Assigning layer properties...\n');
                output_data = s08_assign_layer_properties();
                
            case 's09'
                fprintf('🌊 Applying spatial heterogeneity...\n');
                output_data = s09_spatial_heterogeneity();
                
            otherwise
                fprintf('❓ Unknown phase: %s\n', phase.phase_id);
                output_data = struct();
        end
        
        phase_result.output_data = output_data;
        phase_result.status = 'completed';
        
    catch ME
        phase_result.status = 'failed';
        phase_result.error_message = ME.message;
        rethrow(ME);
    end
end

function print_workflow_summary(results, status_msg, status_color)
    fprintf('\n');
    fprintf('################################################################\n');
    fprintf('#                                                              #\n');
    fprintf('#                 🏁 WORKFLOW SUMMARY                         #\n');
    fprintf('#                                                              #\n');
    fprintf('################################################################\n\n');
    
    fprintf('%s OVERALL STATUS: %s\n\n', status_color, status_msg);
    
    fprintf('⏰ TIMING INFORMATION\n');
    fprintf('════════════════════════\n');
    fprintf('Start: %s\n', results.start_time);
    fprintf('End: %s\n', results.end_time);
    fprintf('\n');
    
    fprintf('📊 EXECUTION STATISTICS\n');
    fprintf('═══════════════════════\n');
    fprintf('Total Phases: %d\n', length(results.phases_executed));
    fprintf('✅ Successful: %d\n', results.success_count);
    fprintf('❌ Failed: %d\n', results.failure_count);
    fprintf('⚠️  Warnings: %d\n', length(results.warnings));
    fprintf('\n');
    
    if ~isempty(results.phases_executed)
        fprintf('✅ COMPLETED PHASES\n');
        fprintf('═══════════════════\n');
        for i = 1:length(results.phases_executed)
            fprintf('  %d. %s ✓\n', i, upper(results.phases_executed{i}));
        end
        fprintf('\n');
    end
    
    if ~isempty(results.warnings)
        fprintf('⚠️  WARNINGS\n');
        fprintf('════════════\n');
        for i = 1:length(results.warnings)
            fprintf('  • %s\n', results.warnings{i});
        end
        fprintf('\n');
    end
    
    if ~isempty(results.errors)
        fprintf('❌ ERRORS\n');
        fprintf('══════════\n');
        for i = 1:length(results.errors)
            fprintf('  • %s\n', results.errors{i});
        end
        fprintf('\n');
    end
    
    fprintf('################################################################\n\n');
end

function print_workflow_failure(error_message)
    fprintf('\n💥 WORKFLOW EXECUTION FAILED\n');
    fprintf('═══════════════════════════════\n');
    fprintf('❌ Error: %s\n', error_message);
    fprintf('\n');
end

function export_workflow_results_octave(workflow_results)
    % Export results using Octave-compatible format
    try
        script_path = fileparts(mfilename('fullpath'));
        data_dir = fullfile(fileparts(script_path), 'data', 'mrst_simulation', 'results');
        
        if ~exist(data_dir, 'dir')
            mkdir(data_dir);
        end
        
        % Use default Octave format (no )
        timestamp = datestr(now, 'yyyymmdd_HHMMSS');
        results_file = fullfile(data_dir, sprintf('workflow_results_%s.mat', timestamp));
        
        save(results_file, 'workflow_results');  % Remove  flag
        
        % Create text summary
        summary_file = fullfile(data_dir, sprintf('workflow_summary_%s.txt', timestamp));
        write_summary_file(summary_file, workflow_results);
        
        fprintf('📁 Results exported:\n');
        fprintf('   • Results: %s\n', results_file);
        fprintf('   • Summary: %s\n\n', summary_file);
        
    catch ME
        fprintf('⚠️  Warning: Could not export results: %s\n', ME.message);
    end
end

function write_summary_file(filename, results)
    fid = fopen(filename, 'w');
    if fid == -1
        return;
    end
    
    fprintf(fid, 'Eagle West Field - Workflow Execution Summary\n');
    fprintf(fid, '=============================================\n\n');
    fprintf(fid, 'Execution Time: %s to %s\n', results.start_time, results.end_time);
    fprintf(fid, 'Status: %s\n', results.status);
    fprintf(fid, 'Phases Executed: %d\n', length(results.phases_executed));
    fprintf(fid, 'Success Count: %d\n', results.success_count);
    fprintf(fid, 'Failure Count: %d\n', results.failure_count);
    
    if ~isempty(results.phases_executed)
        fprintf(fid, '\nCompleted Phases:\n');
        for i = 1:length(results.phases_executed)
            fprintf(fid, '  %d. %s\n', i, results.phases_executed{i});
        end
    end
    
    fclose(fid);
end

function status = get_phase_status(script_name)
    if exist([script_name '.m'], 'file')
        status = '✅ Ready';
    else
        status = '❌ Missing';
    end
end

function result = ternary(condition, true_val, false_val)
    if condition
        result = true_val;
    else
        result = false_val;
    end
end

% Main execution
if ~nargout
    try
        workflow_results = s99_run_workflow_fixed();
        
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