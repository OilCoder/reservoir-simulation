% S00_RUN_COMPLETE_WORKFLOW - Simplified orchestrator for Eagle West Field
% This orchestrator runs the Phase 1 scripts with proper error handling

fprintf('\n=======================================================\n');
fprintf('  EAGLE WEST FIELD - PHASE 1 WORKFLOW\n');
fprintf('=======================================================\n\n');

% Ensure we're in the correct directory
cd('/workspace/mrst_simulation_scripts');

%% Phase 1: Initialize simulation
fprintf('[PHASE 1] Initializing simulation...\n');
try
    simulation_data = s01_initialize_simulation();
    
    % Check if initialization was successful
    if isfield(simulation_data, 'validation') && strcmp(simulation_data.validation.status, 'passed')
        fprintf('[OK] Phase 1 completed successfully\n\n');
    else
        fprintf('[FAIL] Phase 1 validation failed\n');
        if isfield(simulation_data, 'validation') && isfield(simulation_data.validation, 'errors')
            for i = 1:length(simulation_data.validation.errors)
                fprintf('  - %s\n', simulation_data.validation.errors{i});
            end
        end
        return;
    end
catch ME
    fprintf('[FAIL] Phase 1 failed with error: %s\n', ME.message);
    return;
end

%% Phase 2: Build static model
fprintf('[PHASE 2] Building static model...\n');
try
    [G, rock] = s02_build_static_model(simulation_data);
    
    % Verify outputs
    if isempty(G) || isempty(rock)
        fprintf('[FAIL] Phase 2 returned empty grid or rock structure\n');
        return;
    end
    
    fprintf('[OK] Phase 2 completed successfully\n');
    fprintf('  Grid: %d cells\n', G.cells.num);
    fprintf('  Rock: porosity %.1f%% - %.1f%%\n', min(rock.poro)*100, max(rock.poro)*100);
    fprintf('\n');
catch ME
    fprintf('[FAIL] Phase 2 failed with error: %s\n', ME.message);
    return;
end

%% Phase 3: Setup fluid system
fprintf('[PHASE 3] Setting up fluid system...\n');
try
    [fluid, state] = s03_setup_fluid_system(G, rock, simulation_data);
    
    % Verify outputs
    if isempty(fluid) || isempty(state)
        fprintf('[FAIL] Phase 3 returned empty fluid or state structure\n');
        return;
    end
    
    fprintf('[OK] Phase 3 completed successfully\n');
    fprintf('  Fluid: 3-phase black oil model\n');
    fprintf('  State: %d cells initialized\n', length(state.pressure));
    fprintf('\n');
catch ME
    fprintf('[FAIL] Phase 3 failed with error: %s\n', ME.message);
    return;
end

%% Summary
fprintf('=======================================================\n');
fprintf('  WORKFLOW COMPLETED SUCCESSFULLY\n');
fprintf('=======================================================\n');
fprintf('All Phase 1 scripts executed without errors\n');
fprintf('Ready for next phases (wells, schedule, simulation)\n');
fprintf('=======================================================\n\n');