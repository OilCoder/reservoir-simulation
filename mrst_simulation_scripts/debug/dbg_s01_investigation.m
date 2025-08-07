function dbg_s01_investigation()
% DBG_S01_INVESTIGATION - Debug S01 initialization vs actual MRST state
%
% PROBLEM: S01 claims success but mrstModule is not available afterward
%
% Author: Claude Code AI System - DEBUGGER Agent  
% Date: August 7, 2025

    fprintf('\n================================================================\n');
    fprintf('DEBUG: S01 Investigation - Claims vs Reality\n');
    fprintf('================================================================\n\n');
    
    % Test BEFORE S01 execution
    fprintf('BEFORE S01 EXECUTION:\n');
    fprintf('--------------------\n');
    test_mrst_availability('Before S01');
    
    % Execute S01 and capture result
    fprintf('\nEXECUTING S01...\n');
    fprintf('---------------\n');
    try
        mrst_env = s01_initialize_mrst();
        fprintf('S01 returned successfully\n');
        fprintf('S01 status: %s\n', mrst_env.status);
        fprintf('S01 modules_loaded: %s\n', mrst_env.modules_loaded);
        
        % Show what S01 thinks it did
        if isfield(mrst_env, 'mrst_root') && ~isempty(mrst_env.mrst_root)
            fprintf('S01 claims MRST root: %s\n', mrst_env.mrst_root);
        end
        
    catch ME
        fprintf('S01 FAILED: %s\n', ME.message);
    end
    
    % Test AFTER S01 execution
    fprintf('\nAFTER S01 EXECUTION:\n');
    fprintf('-------------------\n');
    test_mrst_availability('After S01');
    
    % Detailed path analysis
    fprintf('\nPATH ANALYSIS:\n');
    fprintf('-------------\n');
    current_path = path;
    fprintf('Current path length: %d characters\n', length(current_path));
    
    % Count MRST-related paths (simple string search)
    mrst_count = 0;
    path_parts = strsplit(current_path, pathsep);
    for i = 1:length(path_parts)
        part = path_parts{i};
        if length(part) >= 4
            part_lower = lower(part);
            if strfind(part_lower, 'mrst')  % Simple search for 'mrst'
                mrst_count = mrst_count + 1;
                if mrst_count <= 5  % Show first 5
                    fprintf('MRST path %d: %s\n', mrst_count, part);
                end
            end
        end
    end
    if mrst_count == 0
        fprintf('NO MRST paths found in current MATLAB path\n');
    elseif mrst_count > 5
        fprintf('... and %d more MRST paths\n', mrst_count - 5);
    end
    
    % Manual path test
    fprintf('\nMANUAL MRST INITIALIZATION TEST:\n');
    fprintf('-------------------------------\n');
    test_manual_mrst_init();
    
    fprintf('\n================================================================\n');
    fprintf('CONCLUSION:\n');
    fprintf('================================================================\n');
    
    if exist('mrstModule', 'file')
        fprintf('✓ mrstModule is now available after investigation\n');
        fprintf('  This suggests the issue is in the initialization sequence\n');
    else
        fprintf('✗ mrstModule is still NOT available\n');
        fprintf('  S01 is not properly initializing MRST\n');
        fprintf('  The paths are added but functions are not accessible\n');
    end

end

function test_mrst_availability(phase_name)
    fprintf('[%s] Testing MRST availability:\n', phase_name);
    
    key_functions = {'mrstModule', 'cartGrid', 'computeGeometry'};
    for i = 1:length(key_functions)
        func_name = key_functions{i};
        if exist(func_name, 'file')
            fprintf('   ✓ %s: Available\n', func_name);
        else
            fprintf('   ✗ %s: NOT AVAILABLE\n', func_name);
        end
    end
    
    if exist('mrstModule', 'file')
        try
            loaded_modules = mrstModule();
            fprintf('   ✓ mrstModule() call successful, %d modules loaded\n', length(loaded_modules));
        catch ME
            fprintf('   ✗ mrstModule() call failed: %s\n', ME.message);
        end
    end
end

function test_manual_mrst_init()
    fprintf('Attempting manual MRST initialization...\n');
    
    % Find MRST installation
    mrst_root = '/opt/mrst';  % We know it exists from previous debug
    if exist(fullfile(mrst_root, 'startup.m'), 'file')
        fprintf('Found MRST at: %s\n', mrst_root);
        
        % Try to run startup.m
        fprintf('Attempting to run MRST startup.m...\n');
        original_dir = pwd;
        try
            cd(mrst_root);
            fprintf('Changed to MRST directory: %s\n', pwd);
            
            % Run startup
            run('startup.m');
            fprintf('✓ startup.m executed successfully\n');
            
            cd(original_dir);
            
            % Test if it worked
            if exist('mrstModule', 'file')
                fprintf('✓ mrstModule is now available!\n');
                try
                    loaded = mrstModule();
                    fprintf('✓ mrstModule() works, %d modules loaded\n', length(loaded));
                catch ME
                    fprintf('✗ mrstModule() failed: %s\n', ME.message);
                end
            else
                fprintf('✗ mrstModule still not available after startup\n');
            end
            
        catch ME
            cd(original_dir);
            fprintf('✗ Manual startup failed: %s\n', ME.message);
        end
    else
        fprintf('✗ MRST startup.m not found at %s\n', mrst_root);
    end
end

% Execute when called as script
if ~nargout
    dbg_s01_investigation();
end