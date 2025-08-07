function dbg_mrst_modules_persistence()
% DBG_MRST_MODULES_PERSISTENCE - Debug MRST module loading persistence issue
%
% PROBLEM ANALYSIS:
% - S01 claims to load modules but they're not available to S03
% - S03 fails with: "Missing required MRST modules: ad-core, ad-blackoil, ad-props"
% - Module loading appears to work in S01 but doesn't persist to S03
%
% INVESTIGATION FOCUS:
% 1. Check if mrstModule function is actually available
% 2. Verify module loading scope and persistence
% 3. Test module availability between function calls
% 4. Identify root cause of persistence failure
%
% Author: Claude Code AI System - DEBUGGER Agent
% Date: August 7, 2025

    fprintf('\n');
    fprintf('################################################################\n');
    fprintf('#                                                              #\n');
    fprintf('#       🔍 MRST MODULES PERSISTENCE DEBUG INVESTIGATION        #\n');
    fprintf('#                                                              #\n');
    fprintf('################################################################\n\n');
    
    debug_start_time = tic;
    
    try
        % ========================================
        % INVESTIGATION 1: MRST Initialization Status
        % ========================================
        fprintf('🔍 INVESTIGATION 1: Current MRST Status\n');
        fprintf('════════════════════════════════════════\n');
        
        % Check if MRST paths are in the path
        mrst_paths = path;
        fprintf('DEBUG: MATLAB path contains %d characters\n', length(mrst_paths));
        
        % Look for MRST-related paths
        if contains(mrst_paths, 'mrst')
            fprintf('✅ MRST paths found in MATLAB path\n');
            mrst_path_lines = strsplit(mrst_paths, pathsep);
            mrst_lines = mrst_path_lines(contains(mrst_path_lines, 'mrst'));
            fprintf('   Found %d MRST-related paths:\n', length(mrst_lines));
            for i = 1:min(5, length(mrst_lines))  % Show first 5
                fprintf('     %d. %s\n', i, mrst_lines{i});
            end
            if length(mrst_lines) > 5
                fprintf('     ... and %d more\n', length(mrst_lines) - 5);
            end
        else
            fprintf('❌ NO MRST paths found in MATLAB path\n');
        end
        
        % Check if key MRST functions exist
        key_functions = {'mrstModule', 'cartGrid', 'computeGeometry', 'initDeckADIFluid', 'initSimpleADIFluid'};
        fprintf('\n📋 Key MRST Functions Availability:\n');
        for i = 1:length(key_functions)
            func_name = key_functions{i};
            if exist(func_name, 'file')
                fprintf('   ✅ %s: Available\n', func_name);
            else
                fprintf('   ❌ %s: NOT AVAILABLE\n', func_name);
            end
        end
        
        % ========================================
        % INVESTIGATION 2: Test Module Loading Directly
        % ========================================
        fprintf('\n\n🔍 INVESTIGATION 2: Direct Module Loading Test\n');
        fprintf('════════════════════════════════════════════════\n');
        
        if exist('mrstModule', 'file')
            fprintf('✅ mrstModule function is available\n');
            
            % Try to get current loaded modules
            fprintf('📋 Attempting to get currently loaded modules...\n');
            try
                loaded_modules = mrstModule();
                fprintf('✅ mrstModule() call successful\n');
                fprintf('   Currently loaded modules: %d\n', length(loaded_modules));
                if isempty(loaded_modules)
                    fprintf('   ⚠️  No modules are currently loaded\n');
                else
                    fprintf('   📋 Loaded modules:\n');
                    for i = 1:length(loaded_modules)
                        fprintf('     %d. %s\n', i, loaded_modules{i});
                    end
                end
            catch ME
                fprintf('❌ mrstModule() call failed: %s\n', ME.message);
                fprintf('   This suggests MRST core is not properly initialized\n');
            end
            
            % Try to load required modules
            required_modules = {'ad-core', 'ad-blackoil', 'ad-props'};
            fprintf('\n📋 Attempting to load required modules...\n');
            for i = 1:length(required_modules)
                module_name = required_modules{i};
                fprintf('   Loading %s...', module_name);
                try
                    mrstModule('add', module_name);
                    fprintf(' ✅ SUCCESS\n');
                catch ME
                    fprintf(' ❌ FAILED: %s\n', ME.message);
                end
            end
            
            % Check what's loaded after attempted loading
            fprintf('\n📋 Modules after loading attempt:\n');
            try
                loaded_modules_after = mrstModule();
                if isempty(loaded_modules_after)
                    fprintf('   ⚠️  Still no modules loaded\n');
                else
                    fprintf('   📋 Now loaded:\n');
                    for i = 1:length(loaded_modules_after)
                        fprintf('     %d. %s\n', i, loaded_modules_after{i});
                    end
                end
            catch ME
                fprintf('   ❌ Cannot check loaded modules: %s\n', ME.message);
            end
            
        else
            fprintf('❌ mrstModule function is NOT available\n');
            fprintf('   This is the root cause - MRST core is not initialized\n');
        end
        
        % ========================================
        % INVESTIGATION 3: Simulate S01 Behavior
        % ========================================
        fprintf('\n\n🔍 INVESTIGATION 3: Simulate S01 Module Loading\n');
        fprintf('═════════════════════════════════════════════════\n');
        
        fprintf('📋 Replicating S01 step_3_load_modules() logic:\n');
        
        if exist('mrstModule', 'file')
            fprintf('✅ mrstModule function available, attempting to load modules\n');
            modules_loaded_result = 'modules_attempted';
            fprintf('   S01 would return: %s\n', modules_loaded_result);
            fprintf('   ⚠️  Notice: S01 doesn''t actually verify successful loading!\n');
        else
            fprintf('❌ mrstModule function not available, skipping module loading\n');
            modules_loaded_result = 'basic_paths_only';
            fprintf('   S01 would return: %s\n', modules_loaded_result);
        end
        
        % ========================================
        % INVESTIGATION 4: Simulate S03 Behavior
        % ========================================
        fprintf('\n\n🔍 INVESTIGATION 4: Simulate S03 Module Verification\n');
        fprintf('══════════════════════════════════════════════════\n');
        
        fprintf('📋 Replicating S03 verify_mrst_modules() logic:\n');
        
        if ~exist('mrstModule', 'file')
            fprintf('❌ MRST not initialized. Run s01_initialize_mrst.m first.\n');
            fprintf('   S03 would fail here with this error\n');
        else
            fprintf('✅ mrstModule function available\n');
            
            try
                loaded_modules_s03 = mrstModule();
                fprintf('✅ Got loaded modules list: %d modules\n', length(loaded_modules_s03));
                
                % Check for required modules
                required_modules = {'ad-core', 'ad-blackoil', 'ad-props'};
                missing_modules = {};
                
                for i = 1:length(required_modules)
                    module = required_modules{i};
                    if ~any(strcmp(loaded_modules_s03, module))
                        missing_modules{end+1} = module;
                    end
                end
                
                if ~isempty(missing_modules)
                    fprintf('❌ Missing required MRST modules: %s\n', strjoin(missing_modules, ', '));
                    fprintf('   S03 would fail here with this error\n');
                else
                    fprintf('✅ All required modules are loaded\n');
                end
                
            catch ME
                fprintf('❌ mrstModule() call failed: %s\n', ME.message);
                fprintf('   S03 would fail with this error\n');
            end
        end
        
        % ========================================
        % INVESTIGATION 5: Cross-Function Persistence Test
        % ========================================
        fprintf('\n\n🔍 INVESTIGATION 5: Cross-Function Persistence Test\n');
        fprintf('═══════════════════════════════════════════════════\n');
        
        % Test if we can load modules in one function and access in another
        fprintf('📋 Testing module persistence across function calls:\n');
        
        % Call a test function that tries to load modules
        fprintf('   Calling test_module_loader()...\n');
        result1 = test_module_loader();
        fprintf('   Result: %s\n', result1);
        
        % Call another test function that checks modules
        fprintf('   Calling test_module_checker()...\n');
        result2 = test_module_checker();
        fprintf('   Result: %s\n', result2);
        
        % ========================================
        % INVESTIGATION 6: MRST Installation Analysis
        % ========================================
        fprintf('\n\n🔍 INVESTIGATION 6: MRST Installation Analysis\n');
        fprintf('════════════════════════════════════════════════════\n');
        
        % Search for MRST installation
        potential_paths = {
            '/opt/mrst',
            '/usr/local/mrst', 
            fullfile(getenv('HOME'), 'mrst'),
            fullfile(getenv('HOME'), 'MRST'),
            fullfile(pwd, 'mrst'),
            fullfile(pwd, 'MRST')
        };
        
        mrst_root = '';
        for i = 1:length(potential_paths)
            path_to_check = potential_paths{i};
            fprintf('   Checking: %s\n', path_to_check);
            if exist(fullfile(path_to_check, 'startup.m'), 'file')
                fprintf('     ✅ Found MRST installation!\n');
                mrst_root = path_to_check;
                break;
            else
                fprintf('     ❌ Not found\n');
            end
        end
        
        if ~isempty(mrst_root)
            fprintf('\n✅ MRST Installation found at: %s\n', mrst_root);
            
            % Check key directories
            key_dirs = {'core', 'modules', 'modules/ad-core', 'modules/ad-blackoil', 'modules/ad-props'};
            for i = 1:length(key_dirs)
                dir_path = fullfile(mrst_root, key_dirs{i});
                if exist(dir_path, 'dir')
                    fprintf('   ✅ %s: exists\n', key_dirs{i});
                else
                    fprintf('   ❌ %s: missing\n', key_dirs{i});
                end
            end
            
            % Check startup.m content
            startup_file = fullfile(mrst_root, 'startup.m');
            fprintf('\n📋 Checking startup.m content:\n');
            if exist(startup_file, 'file')
                fprintf('   ✅ startup.m exists\n');
                % Note: We won't execute it, just check its existence
            else
                fprintf('   ❌ startup.m missing\n');
            end
            
        else
            fprintf('\n❌ MRST Installation NOT FOUND\n');
            fprintf('   This is likely the root cause of the problem\n');
        end
        
        % ========================================
        % FINAL DIAGNOSIS
        % ========================================
        fprintf('\n\n🎯 FINAL DIAGNOSIS\n');
        fprintf('═══════════════════\n');
        
        diagnosis_summary();
        
        fprintf('\n✅ Debug investigation completed in %.2f seconds\n', toc(debug_start_time));
        
    catch ME
        fprintf('\n💥 Debug investigation failed: %s\n', ME.message);
        fprintf('Stack trace:\n');
        for i = 1:length(ME.stack)
            fprintf('  %s (line %d)\n', ME.stack(i).name, ME.stack(i).line);
        end
    end
    
    fprintf('\n################################################################\n');

end

function result = test_module_loader()
    % Test function to try loading modules
    fprintf('     [test_module_loader] Attempting to load modules...\n');
    
    if exist('mrstModule', 'file')
        try
            mrstModule('add', 'ad-core');
            result = 'Successfully loaded ad-core';
        catch ME
            result = sprintf('Failed to load: %s', ME.message);
        end
    else
        result = 'mrstModule not available';
    end
end

function result = test_module_checker()
    % Test function to check if modules are loaded
    fprintf('     [test_module_checker] Checking loaded modules...\n');
    
    if exist('mrstModule', 'file')
        try
            loaded = mrstModule();
            if any(strcmp(loaded, 'ad-core'))
                result = 'ad-core is loaded';
            else
                result = 'ad-core is NOT loaded';
            end
        catch ME
            result = sprintf('Failed to check: %s', ME.message);
        end
    else
        result = 'mrstModule not available';
    end
end

function diagnosis_summary()
    fprintf('Based on the investigation, the likely root causes are:\n\n');
    
    fprintf('1. 🔴 MRST INSTALLATION ISSUE:\n');
    fprintf('   • MRST may not be installed or found in expected locations\n');
    fprintf('   • S01 adds basic paths but doesn''t properly initialize MRST core\n');
    fprintf('   • mrstModule function may not be available at all\n\n');
    
    fprintf('2. 🔴 INITIALIZATION SEQUENCE FLAW:\n');
    fprintf('   • S01 step_3_load_modules() only checks if mrstModule exists\n');
    fprintf('   • It doesn''t actually verify that modules were successfully loaded\n');
    fprintf('   • Returns "modules_attempted" without confirming success\n\n');
    
    fprintf('3. 🔴 PATH vs FUNCTION AVAILABILITY:\n');
    fprintf('   • Adding paths ≠ making functions available\n');
    fprintf('   • MRST requires proper initialization beyond just path addition\n');
    fprintf('   • Module loading requires MRST core to be fully initialized\n\n');
    
    fprintf('4. 🔴 SCOPE AND PERSISTENCE:\n');
    fprintf('   • Module loading may work locally but not persist globally\n');
    fprintf('   • Function-level vs global scope issues\n');
    fprintf('   • MRST state not properly maintained between script calls\n\n');
    
    fprintf('🔧 RECOMMENDED FIXES:\n');
    fprintf('═════════════════════\n');
    fprintf('1. Fix S01 to properly initialize MRST (run startup.m)\n');
    fprintf('2. Add actual module loading verification in S01\n');
    fprintf('3. Ensure modules are loaded in global scope\n');
    fprintf('4. Add fallback module loading in S03 if needed\n');
    fprintf('5. Improve error messages to be more diagnostic\n');
    
end

% Execute when called as script
if ~nargout
    dbg_mrst_modules_persistence();
end