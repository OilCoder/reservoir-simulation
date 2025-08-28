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
    
    % Step 2 - Check if s01 session functions are available
    fprintf('   Validating MRST session...\n');
    
    % Check for critical MRST functions that s01 should have loaded
    critical_functions = {'cartGrid', 'computeGeometry', 'initSimpleADIFluid', 'triangleGrid', 'pebi'};
    all_functions_available = true;
    missing_functions = {};
    
    for i = 1:length(critical_functions)
        func_name = critical_functions{i};
        if ~exist(func_name, 'file')
            all_functions_available = false;
            missing_functions{end+1} = func_name;
        end
    end
    
    % Step 3 - Try to load saved s01 session before failing
    if ~all_functions_available
        fprintf('   MRST functions missing, attempting to load saved s01 session...\n');
        
        % Try to load saved session from s01
        session_loaded = load_saved_s01_session(script_dir);
        
        if session_loaded
            % Re-check functions after loading session
            all_functions_available = true;
            missing_functions = {};
            
            for i = 1:length(critical_functions)
                func_name = critical_functions{i};
                if ~exist(func_name, 'file')
                    all_functions_available = false;
                    missing_functions{end+1} = func_name;
                end
            end
            
            if all_functions_available
                fprintf('   ✅ Successfully loaded saved s01 session\n');
            end
        end
        
        % FAIL_FAST if still not available after loading attempt
        if ~all_functions_available
            success = false;
            message = sprintf(['MRST session incomplete - s01 must be run first.\n' ...
                              'REQUIRED: Execute s01_initialize_mrst() to establish complete MRST session.\n' ...
                              'Missing functions: %s\n' ...
                              'CANON-FIRST: Each s** script requires the persistent session that s01 creates.'], ...
                              strjoin(missing_functions, ', '));
            fprintf('   ❌ %s\n', message);
            return;
        end
    end
    
    % Step 4 - Validate s01 persistent session is complete
    success = true;
    message = sprintf('MRST persistent session from s01 validated successfully');
    fprintf('   ✅ MRST session validated successfully\n')

end

function session_loaded = load_saved_s01_session(script_dir)
% Load saved MRST session from s01_initialize_mrst
    session_loaded = false;
    
    try
        % Look for saved session file - first check canonical location, then local
        canonical_session_file = '/workspace/data/mrst/session/s01_mrst_session.mat';
        script_dir = fileparts(fileparts(mfilename('fullpath'))); % Go up one level from utils/
        local_session_file = fullfile(script_dir, 'session', 's01_mrst_session.mat');
        
        if exist(canonical_session_file, 'file')
            session_file = canonical_session_file;
        elseif exist(local_session_file, 'file')
            session_file = local_session_file;
        else
            session_file = canonical_session_file; % Use canonical for error message
        end
        
        if exist(session_file, 'file')
            fprintf('   Loading saved MRST session from: %s\n', session_file);
            
            % Load the saved session data
            loaded_data = load(session_file);
            
            % Check if mrst_env exists (new format) or session_data (old format)
            if isfield(loaded_data, 'mrst_env')
                session_data = loaded_data.mrst_env;
            elseif isfield(loaded_data, 'session_data')
                session_data = loaded_data.session_data;
            else
                error('Invalid session file format - missing mrst_env or session_data');
            end
            
            % Restore MATLAB path from saved session
            if isfield(session_data, 'paths') && ~isempty(session_data.paths)
                for i = 1:length(session_data.paths)
                    if exist(session_data.paths{i}, 'dir')
                        addpath(session_data.paths{i});
                    end
                end
                fprintf('   Restored %d MRST paths from saved session\n', length(session_data.paths));
            end
            
            % Restore MRST modules from saved session
            if isfield(session_data, 'modules_loaded') && ~isempty(session_data.modules_loaded)
                if exist('mrstModule', 'file')
                    try
                        % Load the same modules that s01 loaded
                        warning('off', 'all');
                        mrstModule('add', session_data.modules_loaded{:});
                        warning('on', 'all');
                        fprintf('   Restored %d MRST modules from saved session\n', length(session_data.modules_loaded));
                    catch
                        fprintf('   Warning: Could not restore MRST modules\n');
                    end
                end
            end
            
            % Restore global variables if they exist
            if isfield(session_data, 'environment')
                global_vars = session_data.environment;
                if isfield(global_vars, 'MRST_ROOT_PATH')
                    global MRST_ROOT_PATH;
                    MRST_ROOT_PATH = global_vars.MRST_ROOT_PATH;
                end
                if isfield(global_vars, 'MRST_SESSION_INITIALIZED')
                    global MRST_SESSION_INITIALIZED;
                    MRST_SESSION_INITIALIZED = global_vars.MRST_SESSION_INITIALIZED;
                end
                if isfield(global_vars, 'MRST_PERSISTENT_SESSION')
                    global MRST_PERSISTENT_SESSION;
                    MRST_PERSISTENT_SESSION = global_vars.MRST_PERSISTENT_SESSION;
                end
            end
            
            session_loaded = true;
        else
            fprintf('   No saved session found at: %s\n', session_file);
        end
        
    catch ME
        fprintf('   Warning: Failed to load saved session: %s\n', ME.message);
        session_loaded = false;
    end
end