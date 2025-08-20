function workflow_results = s99_run_workflow(varargin)
% S99_RUN_WORKFLOW - MRST workflow orchestrator with table format display
%
% SYNTAX:
%   workflow_results = s99_run_workflow()
%   workflow_results = s99_run_workflow('validation_only', true)
%   workflow_results = s99_run_workflow('phases', {'s01', 's02', 's03'})
%
% Author: Claude Code AI System
% Date: January 30, 2025

    % Load print utilities for consistent table format
    script_dir = fileparts(mfilename('fullpath'));
    addpath(fullfile(script_dir, 'utils')); 
    run(fullfile(script_dir, 'utils', 'print_utils.m'));
    
    % Suppress isdir deprecation warning from MRST internal functions
    suppress_isdir_warnings();

    % ASCII Art Header
    fprintf('\n');
    fprintf('################################################################\n');
    fprintf('#                                                              #\n');
    fprintf('#     🛢️   EAGLE WEST FIELD RESERVOIR SIMULATION   🛢️            #\n');  
    fprintf('#              MRST Workflow Orchestrator v3.0                 #\n');
    fprintf('#                With Table Format Display                     #\n');
    fprintf('#                                                              #\n');
    fprintf('################################################################\n\n');
    
    % Parse input arguments
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
        
        % Determine which phases to run
        if isempty(phases_requested)
            phases_to_run = phases;
        else
            phases_to_run = filter_phases_fixed(phases, phases_requested);
        end
        
        if verbose
            print_workflow_header(validation_only, phases_to_run, phases);
        end
        
        % Start workflow execution with header only
        print_step_header('WORKFLOW', 'EAGLE WEST FIELD EXECUTION');
        
        for i = 1:length(phases_to_run)
            phase = phases_to_run{i};
            
            % Check validation-only mode
            if validation_only && i > 3
                fprintf('\n⏸️  Validation Mode: Stopping at phase 3 as requested.\n\n');
                break;
            end
            
            % Execute phase
            try
                phase_start_time = tic;
                
                % Execute the specific phase (each phase prints its own detailed table)
                phase_result = execute_phase_fixed(phase, workflow_results);
                
                % Record success
                execution_time = toc(phase_start_time);
                workflow_results.phases_executed{end+1} = phase.phase_id;
                workflow_results.phase_results.(phase.phase_id) = phase_result;
                workflow_results.success_count = workflow_results.success_count + 1;
                
            catch ME
                % Handle phase failure
                execution_time = toc(phase_start_time);
                
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
        end
        
        % Close with summary footer
        total_time = (now - datenum(workflow_results.start_time)) * 24 * 60 * 60; % Convert to seconds
        status_msg = sprintf('Workflow Completed: %d/%d phases successful', workflow_results.success_count, length(phases_to_run));
        print_step_footer('WORKFLOW', status_msg, total_time);
        
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
        
        % Export workflow results
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
    % Define all workflow phases
    phases = {};
    
    phases{1} = struct('phase_id', 's01', 'script_name', 's01_initialize_mrst', ...
                      'description', 'Initialize MRST Environment', ...
                      'critical', true, 'estimated_time', 30);
                      
    phases{2} = struct('phase_id', 's02', 'script_name', 's02_define_fluids', ...
                      'description', 'Define Fluids (3-phase)', ...
                      'critical', true, 'estimated_time', 45);
                      
    phases{3} = struct('phase_id', 's03', 'script_name', 's03_create_pebi_grid', ...
                      'description', 'PEBI Grid Construction (Canonical)', ...
                      'critical', true, 'estimated_time', 120);
                      
    phases{4} = struct('phase_id', 's04', 'script_name', 's04_structural_framework', ...
                      'description', 'Structural Framework', ...
                      'critical', true, 'estimated_time', 90);
                      
    phases{5} = struct('phase_id', 's05', 'script_name', 's05_add_faults', ...
                      'description', 'Add Fault System', ...
                      'critical', true, 'estimated_time', 75);
                      
    phases{6} = struct('phase_id', 's06', 'script_name', 's06_create_base_rock_structure', ...
                      'description', 'Create Base Rock Structure', ...
                      'critical', true, 'estimated_time', 60);
                      
    phases{7} = struct('phase_id', 's07', 'script_name', 's07_add_layer_metadata', ...
                      'description', 'Add Layer Metadata', ...
                      'critical', true, 'estimated_time', 60);
                      
    phases{8} = struct('phase_id', 's08', 'script_name', 's08_apply_spatial_heterogeneity', ...
                      'description', 'Apply Spatial Heterogeneity', ...
                      'critical', false, 'estimated_time', 120);
                      
    phases{9} = struct('phase_id', 's09', 'script_name', 's09_relative_permeability', ...
                       'description', 'Relative Permeability', ...
                       'critical', true, 'estimated_time', 90);
                       
    phases{10} = struct('phase_id', 's10', 'script_name', 's10_capillary_pressure', ...
                       'description', 'Capillary Pressure', ...
                       'critical', true, 'estimated_time', 75);
                       
    phases{11} = struct('phase_id', 's11', 'script_name', 's11_pvt_tables', ...
                       'description', 'PVT Tables', ...
                       'critical', true, 'estimated_time', 120);
                       
    % Phase 5: Initial Conditions Setup
    phases{12} = struct('phase_id', 's12', 'script_name', 's12_pressure_initialization', ...
                       'description', 'Pressure Initialization', ...
                       'critical', true, 'estimated_time', 90);
                       
    phases{13} = struct('phase_id', 's13', 'script_name', 's13_saturation_distribution', ...
                       'description', 'Saturation Distribution', ...
                       'critical', true, 'estimated_time', 75);
                       
    phases{14} = struct('phase_id', 's14', 'script_name', 's14_aquifer_configuration', ...
                       'description', 'Aquifer Configuration', ...
                       'critical', true, 'estimated_time', 60);
                       
    % Phase 6: Well System Implementation                   
    phases{15} = struct('phase_id', 's15', 'script_name', 's15_well_placement', ...
                       'description', 'Well Placement (15 wells)', ...
                       'critical', true, 'estimated_time', 90);
                       
    phases{16} = struct('phase_id', 's16', 'script_name', 's16_well_completions', ...
                       'description', 'Well Completions', ...
                       'critical', true, 'estimated_time', 80);
                       
    phases{17} = struct('phase_id', 's17', 'script_name', 's17_production_controls', ...
                       'description', 'Production Controls', ...
                       'critical', true, 'estimated_time', 70);
    
    % Phase 7: Development Schedule Implementation
    phases{18} = struct('phase_id', 's18', 'script_name', 's18_development_schedule', ...
                       'description', 'Development Schedule (6 phases)', ...
                       'critical', true, 'estimated_time', 100);
                       
    phases{19} = struct('phase_id', 's19', 'script_name', 's19_production_targets', ...
                       'description', 'Production Targets', ...
                       'critical', true, 'estimated_time', 85);
                       
    % Phase 8: Simulation Execution & Quality Control
    phases{20} = struct('phase_id', 's20', 'script_name', 's20_solver_setup', ...
                       'description', 'Solver Configuration (ad-fi)', ...
                       'critical', true, 'estimated_time', 60);
                       
    phases{21} = struct('phase_id', 's21', 'script_name', 's21_run_simulation', ...
                       'description', 'Run Simulation (10 years)', ...
                       'critical', true, 'estimated_time', 600);
                       
    % Phase 9: Quality Control and Analysis
    phases{22} = struct('phase_id', 's23', 'script_name', 's23_quality_validation', ...
                       'description', 'Quality Validation', ...
                       'critical', false, 'estimated_time', 120);
                       
    phases{23} = struct('phase_id', 's24', 'script_name', 's24_production_analysis', ...
                       'description', 'Production Analysis', ...
                       'critical', false, 'estimated_time', 150);
                       
    phases{24} = struct('phase_id', 's25', 'script_name', 's25_reservoir_analysis', ...
                       'description', 'Reservoir Analysis', ...
                       'critical', false, 'estimated_time', 180);
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
    fprintf('💻 Platform: With Table Format\n');
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

function phase_result = execute_phase_fixed(phase, workflow_results)
    % Execute phase (silent mode for table format)
    phase_result = struct();
    phase_result.status = 'running';
    phase_result.phase_id = phase.phase_id;
    
    % Check if script exists
    script_file = [phase.script_name '.m'];
    if ~exist(script_file, 'file')
        if phase.critical
            error('Critical script not found: %s', script_file);
        else
            phase_result.status = 'skipped';
            phase_result.message = 'Script not found';
            return;
        end
    end
    
    % Execute the phase (no extra output for table format)
    try
        switch phase.phase_id
            case 's01'
                output_data = s01_initialize_mrst();
                
            case 's02'
                output_data = s02_define_fluids();
                
            case 's03'
                output_data = s03_create_pebi_grid();
                
            case 's04'
                output_data = s04_structural_framework();
                
            case 's05'
                output_data = s05_add_faults();
                
            case 's06'  % Base Rock Structure (FILE-BASED)
                run('s06_create_base_rock_structure.m');
                output_data = 'base_rock.mat saved';
                
            case 's07'  % Layer Metadata Enhancement (FILE-BASED)
                run('s07_add_layer_metadata.m');
                output_data = 'enhanced_rock.mat saved';
                
            case 's08'  % Spatial Heterogeneity (FILE-BASED)
                run('s08_apply_spatial_heterogeneity.m');
                output_data = 'final_rock.mat saved';
                
            case 's09'
                output_data = s09_relative_permeability();
                
            case 's10'
                output_data = s10_capillary_pressure();
                
            case 's11'
                output_data = s11_pvt_tables();
                
            case 's12'
                output_data = s12_pressure_initialization();
                
            case 's13'
                output_data = s13_saturation_distribution();
                
            case 's14'
                output_data = s14_aquifer_configuration();
                
            case 's15'
                output_data = s15_well_placement();
                
            case 's16'
                output_data = s16_well_completions();
                
            case 's17'
                output_data = s17_production_controls();
                
            case 's18'
                output_data = s18_development_schedule();
                
            case 's19'
                output_data = s19_production_targets();
                
            case 's20'
                output_data = s20_solver_setup();
                
            case 's21'
                output_data = s21_run_simulation();
                
            case 's23'
                output_data = s23_quality_validation();
                
            case 's24'
                output_data = s24_production_analysis();
                
            case 's25'
                output_data = s25_reservoir_analysis();
                
            otherwise
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
        data_dir = fullfile(script_path, '..', 'data', 'mrst_simulation', 'results');
        
        if ~exist(data_dir, 'dir')
            mkdir(data_dir);
        end
        
        % Use default Octave format
        timestamp = datestr(now, 'yyyymmdd_HHMMSS');
        results_file = fullfile(data_dir, sprintf('workflow_results_%s.mat', timestamp));
        
        save(results_file, 'workflow_results');
        
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

function str = pad_or_truncate(str, width)
    % Pad or truncate string to specified width
    if length(str) > width
        str = [str(1:width-3) '...'];
    else
        str = sprintf('%-*s', width, str);
    end
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