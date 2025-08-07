function dbg_mrst_modules_simple()
% DBG_MRST_MODULES_SIMPLE - Simple debug for MRST module loading issue
%
% PROBLEM: S01 claims to load modules but S03 can't find them
%
% Author: Claude Code AI System - DEBUGGER Agent
% Date: August 7, 2025

    fprintf('\n================================================================\n');
    fprintf('DEBUG: MRST Modules Loading Issue Investigation\n');
    fprintf('================================================================\n\n');
    
    debug_start_time = tic;
    
    try
        % Check 1: Basic MRST functions availability
        fprintf('1. Checking key MRST functions...\n');
        key_functions = {'mrstModule', 'cartGrid', 'computeGeometry'};
        for i = 1:length(key_functions)
            func_name = key_functions{i};
            if exist(func_name, 'file')
                fprintf('   ✓ %s: Available\n', func_name);
            else
                fprintf('   ✗ %s: NOT AVAILABLE\n', func_name);
            end
        end
        
        % Check 2: Try mrstModule() call
        fprintf('\n2. Testing mrstModule() function...\n');
        if exist('mrstModule', 'file')
            fprintf('   ✓ mrstModule function exists\n');
            try
                loaded_modules = mrstModule();
                fprintf('   ✓ mrstModule() call successful\n');
                fprintf('   - Currently loaded modules: %d\n', length(loaded_modules));
                if isempty(loaded_modules)
                    fprintf('   ! WARNING: No modules are loaded\n');
                else
                    fprintf('   - Loaded modules:\n');
                    for j = 1:length(loaded_modules)
                        fprintf('     %d. %s\n', j, loaded_modules{j});
                    end
                end
            catch ME
                fprintf('   ✗ mrstModule() call FAILED: %s\n', ME.message);
            end
        else
            fprintf('   ✗ mrstModule function NOT AVAILABLE\n');
            fprintf('   ! This is the likely root cause\n');
        end
        
        % Check 3: Search for MRST installation
        fprintf('\n3. Searching for MRST installation...\n');
        potential_paths = {
            '/opt/mrst',
            '/usr/local/mrst',
            fullfile(getenv('HOME'), 'mrst'),
            fullfile(pwd, 'mrst')
        };
        
        mrst_found = 0;
        for i = 1:length(potential_paths)
            path_to_check = potential_paths{i};
            fprintf('   Checking: %s\n', path_to_check);
            if exist(fullfile(path_to_check, 'startup.m'), 'file')
                fprintf('     ✓ MRST installation found!\n');
                mrst_found = 1;
                
                % Check key directories
                key_dirs = {'core', 'modules'};
                for j = 1:length(key_dirs)
                    dir_path = fullfile(path_to_check, key_dirs{j});
                    if exist(dir_path, 'dir')
                        fprintf('     ✓ %s directory exists\n', key_dirs{j});
                    else
                        fprintf('     ✗ %s directory missing\n', key_dirs{j});
                    end
                end
                break;
            else
                fprintf('     ✗ Not found\n');
            end
        end
        
        if ~mrst_found
            fprintf('   ✗ MRST installation NOT FOUND anywhere\n');
        end
        
        % Check 4: Simulate the S01 issue
        fprintf('\n4. Simulating S01 step_3_load_modules() behavior...\n');
        if exist('mrstModule', 'file')
            fprintf('   - S01 sees mrstModule available\n');
            fprintf('   - S01 returns "modules_attempted"\n');
            fprintf('   ! But S01 does NOT verify actual loading success!\n');
        else
            fprintf('   - S01 sees mrstModule NOT available\n');
            fprintf('   - S01 returns "basic_paths_only"\n');
        end
        
        % Check 5: Simulate the S03 issue  
        fprintf('\n5. Simulating S03 verify_mrst_modules() behavior...\n');
        if ~exist('mrstModule', 'file')
            fprintf('   - S03 fails immediately: mrstModule not found\n');
            fprintf('   - Error: "MRST not initialized. Run s01_initialize_mrst.m first."\n');
        else
            fprintf('   - S03 finds mrstModule\n');
            try
                loaded_modules_s03 = mrstModule();
                required_modules = {'ad-core', 'ad-blackoil', 'ad-props'};
                missing_modules = {};
                
                for j = 1:length(required_modules)
                    module = required_modules{j};
                    module_found = 0;
                    for k = 1:length(loaded_modules_s03)
                        if strcmp(loaded_modules_s03{k}, module)
                            module_found = 1;
                            break;
                        end
                    end
                    if ~module_found
                        missing_modules{end+1} = module;
                    end
                end
                
                if ~isempty(missing_modules)
                    fprintf('   - S03 finds missing modules: ');
                    for j = 1:length(missing_modules)
                        if j > 1, fprintf(', '); end
                        fprintf('%s', missing_modules{j});
                    end
                    fprintf('\n');
                    fprintf('   - S03 fails with: "Missing required MRST modules"\n');
                else
                    fprintf('   - S03 finds all required modules loaded\n');
                    fprintf('   - S03 would succeed\n');
                end
                
            catch ME
                fprintf('   - S03 fails on mrstModule() call: %s\n', ME.message);
            end
        end
        
        % Final diagnosis
        fprintf('\n================================================================\n');
        fprintf('DIAGNOSIS SUMMARY:\n');
        fprintf('================================================================\n');
        
        if ~exist('mrstModule', 'file')
            fprintf('ROOT CAUSE: mrstModule function is not available\n\n');
            fprintf('This means either:\n');
            fprintf('1. MRST is not installed\n');
            fprintf('2. MRST paths are not properly added\n');
            fprintf('3. MRST core initialization failed\n\n');
            
            fprintf('RECOMMENDED FIXES:\n');
            fprintf('1. Verify MRST installation exists\n');
            fprintf('2. Fix S01 to properly run MRST startup.m\n');
            fprintf('3. Ensure MRST core paths are added correctly\n');
            fprintf('4. Test basic MRST functions before claiming success\n');
        else
            fprintf('mrstModule is available, but modules may not be loaded.\n');
            fprintf('The issue is likely in the module loading process itself.\n');
        end
        
        fprintf('\nDEBUG COMPLETED in %.2f seconds\n', toc(debug_start_time));
        
    catch ME
        fprintf('\nDEBUG FAILED: %s\n', ME.message);
    end
    
    fprintf('================================================================\n\n');

end

% Execute when called as script  
if ~nargout
    dbg_mrst_modules_simple();
end