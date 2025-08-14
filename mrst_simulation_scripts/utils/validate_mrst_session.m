function [success, message] = validate_mrst_session(script_dir)
% VALIDATE_MRST_SESSION - Ensure MRST is properly initialized
% Requires: MRST
%
% SYNTAX:
%   [success, message] = validate_mrst_session(script_dir)
%
% INPUT:
%   script_dir - Directory containing s01_initialize_mrst.m (optional)
%               If not provided, uses fileparts(mfilename('fullpath'))
%
% OUTPUT:
%   success - Boolean indicating if MRST is ready for use
%   message - String describing the initialization status
%
% DESCRIPTION:
%   This function implements the standardized MRST session validation pattern
%   identified in the audit. If MRST is not initialized, it automatically
%   executes s01_initialize_mrst.m as a fallback strategy.
%
%   Pattern B Implementation (successful from s02):
%   1. Check if critical MRST functions exist
%   2. If not found, execute s01_initialize_mrst.m automatically
%   3. Verify modules are loaded after initialization
%   4. Return clear status indicator
%
% Author: Claude Code AI System
% Date: January 30, 2025

    % Step 1 - Set default script directory if not provided
    if nargin < 1 || isempty(script_dir)
        % Get calling function's directory
        caller_stack = dbstack();
        if length(caller_stack) > 1
            caller_file = caller_stack(2).file;
            script_dir = fileparts(which(caller_file));
        else
            % Fallback to current directory
            script_dir = fileparts(mfilename('fullpath'));
            script_dir = fileparts(script_dir); % Go up one level from utils/
        end
    end
    
    % Step 2 - Check if MRST is already initialized
    fprintf('   Validating MRST session...\n');
    
    % Check for critical MRST functions (Pattern B from s02)
    critical_functions = {'mrstModule', 'cartGrid', 'computeGeometry'};
    all_functions_available = true;
    
    for i = 1:length(critical_functions)
        func_name = critical_functions{i};
        if ~exist(func_name, 'file')
            all_functions_available = false;
            break;
        end
    end
    
    % Step 3 - Initialize MRST if needed
    if ~all_functions_available
        fprintf('   MRST not fully initialized - running fallback initialization...\n');
        
        try
            % Execute s01_initialize_mrst.m from script directory
            s01_path = fullfile(script_dir, 's01_initialize_mrst.m');
            
            if exist(s01_path, 'file')
                fprintf('   Executing: %s\n', s01_path);
                run(s01_path);
            else
                success = false;
                message = sprintf('s01_initialize_mrst.m not found at: %s', s01_path);
                return;
            end
            
        catch ME
            success = false;
            message = sprintf('MRST initialization failed: %s', ME.message);
            return;
        end
    end
    
    % Step 4 - Verify MRST is now ready
    verification_passed = true;
    missing_functions = {};
    
    for i = 1:length(critical_functions)
        func_name = critical_functions{i};
        if ~exist(func_name, 'file')
            verification_passed = false;
            missing_functions{end+1} = func_name;
        end
    end
    
    % Step 5 - Check for loaded modules (optional validation)
    modules_status = 'unknown';
    if exist('mrstModule', 'file')
        try
            current_modules = mrstModule();
            if iscell(current_modules) && ~isempty(current_modules)
                modules_status = sprintf('%d modules loaded', length(current_modules));
            elseif ischar(current_modules) || isstring(current_modules)
                modules_status = 'modules available';
            else
                modules_status = 'no modules loaded';
            end
        catch
            modules_status = 'module check failed';
        end
    end
    
    % Step 6 - Return results
    if verification_passed
        success = true;
        message = sprintf('MRST session ready (%s)', modules_status);
        fprintf('   ✅ MRST session validated successfully\n');
    else
        success = false;
        message = sprintf('MRST validation failed - missing functions: %s', ...
                         strjoin(missing_functions, ', '));
        fprintf('   ❌ MRST validation failed: %s\n', message);
    end

end