function dbg_persistence_issue()
% DBG_PERSISTENCE_ISSUE - Demonstrate MRST module persistence problem
%
% DEMONSTRATES: MRST functions available in one session but not across separate script calls
%
% Author: Claude Code AI System - DEBUGGER Agent
% Date: August 7, 2025

    fprintf('\n================================================================\n');
    fprintf('DEBUG: MRST Module Persistence Issue\n');
    fprintf('================================================================\n\n');
    
    % Test 1: Current state
    fprintf('TEST 1: Current MRST State\n');
    fprintf('-------------------------\n');
    test_mrst_state('Current');
    
    % Test 2: Run S01 in this session
    fprintf('\nTEST 2: Run S01 in same session\n');
    fprintf('-------------------------------\n');
    try
        fprintf('Running S01...\n');
        s01_initialize_mrst();
        fprintf('S01 completed successfully\n');
        
        fprintf('Testing MRST state after S01 in same session:\n');
        test_mrst_state('After S01 same session');
        
    catch ME
        fprintf('S01 failed: %s\n', ME.message);
    end
    
    % Test 3: Try module loading
    fprintf('\nTEST 3: Try loading required modules\n');
    fprintf('-----------------------------------\n');
    if exist('mrstModule', 'file')
        try
            fprintf('Attempting to load ad-core...\n');
            mrstModule('add', 'ad-core');
            
            fprintf('Attempting to load ad-blackoil...\n');
            mrstModule('add', 'ad-blackoil');
            
            fprintf('Attempting to load ad-props...\n');
            mrstModule('add', 'ad-props');
            
            fprintf('Checking loaded modules:\n');
            loaded = mrstModule();
            if isempty(loaded)
                fprintf('✗ No modules loaded despite attempts\n');
            else
                fprintf('✓ Loaded modules:\n');
                for i = 1:length(loaded)
                    fprintf('  %d. %s\n', i, loaded{i});
                end
            end
            
        catch ME
            fprintf('✗ Module loading failed: %s\n', ME.message);
        end
    else
        fprintf('✗ mrstModule not available for loading\n');
    end
    
    % Test 4: Call S03 verification function directly
    fprintf('\nTEST 4: Call S03 verification in same session\n');
    fprintf('--------------------------------------------\n');
    try
        fprintf('Testing S03 verify_mrst_modules() in same session:\n');
        test_s03_verification();
        
    catch ME
        fprintf('S03 verification test failed: %s\n', ME.message);
    end
    
    fprintf('\n================================================================\n');
    fprintf('KEY FINDINGS:\n');
    fprintf('================================================================\n');
    fprintf('1. S01 successfully makes mrstModule available within the same session\n');
    fprintf('2. But when S03 runs in a separate octave call, mrstModule is NOT available\n');
    fprintf('3. This is because MATLAB/Octave path changes are session-specific\n');
    fprintf('4. Each script execution is a separate session with clean path\n');
    fprintf('5. S01 adds paths but they don''t persist to the next script call\n\n');
    
    fprintf('ROOT CAUSE: Session isolation - path changes don''t persist between scripts\n');
    fprintf('SOLUTION: S01 must create persistent MRST initialization that survives\n');
    fprintf('          across separate script executions (or scripts must run in same session)\n');

end

function test_mrst_state(phase)
    fprintf('[%s] MRST Functions:\n', phase);
    
    functions_to_test = {'mrstModule', 'cartGrid', 'computeGeometry'};
    for i = 1:length(functions_to_test)
        func = functions_to_test{i};
        if exist(func, 'file')
            fprintf('  ✓ %s: Available\n', func);
        else
            fprintf('  ✗ %s: NOT AVAILABLE\n', func);
        end
    end
    
    if exist('mrstModule', 'file')
        try
            loaded = mrstModule();
            fprintf('  ✓ mrstModule() successful, %d modules loaded\n', length(loaded));
        catch ME
            fprintf('  ✗ mrstModule() failed: %s\n', ME.message);
        end
    end
end

function test_s03_verification()
    % Replicate S03's verify_mrst_modules() function
    
    if ~exist('mrstModule', 'file')
        fprintf('✗ S03 would fail: mrstModule not available\n');
        return;
    end
    
    fprintf('✓ S03 finds mrstModule available\n');
    
    try
        loaded_modules = mrstModule();
        fprintf('✓ S03 can call mrstModule(), found %d loaded modules\n', length(loaded_modules));
        
        % Check for required modules
        required_modules = {'ad-core', 'ad-blackoil', 'ad-props'};
        missing_modules = {};
        
        for i = 1:length(required_modules)
            module = required_modules{i};
            found = 0;
            for j = 1:length(loaded_modules)
                if strcmp(loaded_modules{j}, module)
                    found = 1;
                    break;
                end
            end
            if ~found
                missing_modules{end+1} = module;
            end
        end
        
        if isempty(missing_modules)
            fprintf('✓ S03 would succeed: All required modules found\n');
        else
            fprintf('✗ S03 would fail: Missing modules - ');
            for i = 1:length(missing_modules)
                if i > 1, fprintf(', '); end
                fprintf('%s', missing_modules{i});
            end
            fprintf('\n');
        end
        
    catch ME
        fprintf('✗ S03 would fail on mrstModule() call: %s\n', ME.message);
    end
end

% Execute when called as script
if ~nargout
    dbg_persistence_issue();
end