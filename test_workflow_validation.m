% Test workflow with validation only mode to check Phase 8 integration
fprintf('Testing Eagle West Field workflow with Phase 8 integration...\n\n');

try
    % Test validation mode (first 3 phases only)
    fprintf('Running validation mode (phases 1-3)...\n');
    workflow_results = s99_run_workflow('validation_only', true);
    
    if strcmp(workflow_results.status, 'completed_successfully')
        fprintf('✅ Validation mode completed successfully\n');
    else
        fprintf('⚠️ Validation mode completed with warnings\n');
    end
    
    fprintf('\nValidation Results:\n');
    fprintf('  Phases executed: %d\n', length(workflow_results.phases_executed));
    fprintf('  Success count: %d\n', workflow_results.success_count);
    fprintf('  Failure count: %d\n', workflow_results.failure_count);
    
    % Test Phase 8 script availability
    fprintf('\nChecking Phase 8 script availability...\n');
    phase8_scripts = {'s21_solver_setup', 's22_run_simulation', 's23_quality_validation'};
    
    for i = 1:length(phase8_scripts)
        script_name = phase8_scripts{i};
        if exist([script_name '.m'], 'file')
            fprintf('  ✅ %s.m found\n', script_name);
        else
            fprintf('  ❌ %s.m missing\n', script_name);
        end
    end
    
    % Test configuration file
    config_file = 'config/solver_config.yaml';
    if exist(config_file, 'file')
        fprintf('  ✅ %s found\n', config_file);
    else
        fprintf('  ❌ %s missing\n', config_file);
    end
    
    fprintf('\n✅ Workflow integration test completed.\n');
    
catch ME
    fprintf('❌ Workflow test failed: %s\n', ME.message);
    fprintf('Stack trace:\n');
    for i = 1:length(ME.stack)
        fprintf('  %s (line %d)\n', ME.stack(i).name, ME.stack(i).line);
    end
end