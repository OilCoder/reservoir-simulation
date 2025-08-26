function success = check_and_load_mrst_session()
% CHECK_AND_LOAD_MRST_SESSION - Verify and restore MRST session from s01
%
% PURPOSE:
%   Ensures MRST session persistence across different script executions.
%   Each sXX script calls this function to verify s01 has been run and
%   restore the MRST environment for independent execution.
%
% RETURNS:
%   success - true if MRST session loaded successfully, false otherwise
%
% WORKFLOW:
%   1. Check if s01_mrst_session.mat exists
%   2. Load session data and validate
%   3. Restore MRST paths and modules
%   4. Verify MRST functionality
%   5. Return success status
%
% USAGE:
%   if ~check_and_load_mrst_session()
%       error('MRST session not found. Run s01_initialize_mrst.m first');
%   end

    success = false;
    
    try
        % Step 1: Locate session file
        % CANON-FIRST POLICY: Documentation specifies /workspace/data/mrst/session/ as authoritative location
        workspace_root = '/workspace';
        session_file = fullfile(workspace_root, 'data', 'mrst', 'session', 's01_mrst_session.mat');
        
        if ~exist(session_file, 'file')
            fprintf('❌ MRST session file not found: %s\n', session_file);
            fprintf('   Please run: octave s01_initialize_mrst.m\n');
            return;
        end
        
        % Step 2: Load and validate session data (suppress load output)
        session_data = load(session_file);
        
        if ~isfield(session_data, 'mrst_env') || ~strcmp(session_data.mrst_env.status, 'ready')
            fprintf('❌ Invalid MRST session data\n');
            return;
        end
        
        mrst_env = session_data.mrst_env;
        
        % Step 3: Restore MRST environment
        mrst_root = mrst_env.mrst_root;
        
        % Verify MRST_ROOT environment
        if isempty(getenv('MRST_ROOT'))
            fprintf('⚠️  MRST_ROOT not set, using session value: %s\n', mrst_root);
        end
        
        % Restore core MRST paths
        if exist(mrst_root, 'dir')
            addpath(mrst_root);
            addpath(fullfile(mrst_root, 'core'));
            addpath(genpath(fullfile(mrst_root, 'core')));
            
            % Add essential MRST module directories
            mrst_modules = {'autodiff', 'modules', 'solvers', 'multiscale', 'visualization'};
            for i = 1:length(mrst_modules)
                module_dir = fullfile(mrst_root, mrst_modules{i});
                if exist(module_dir, 'dir')
                    addpath(genpath(module_dir));
                end
            end
        else
            fprintf('❌ MRST directory not found: %s\n', mrst_root);
            return;
        end
        
        % Step 4: Restore MRST modules if possible
        if exist('mrstModule', 'file') && ~isempty(mrst_env.modules_loaded)
            try
                % Suppress all warnings during module loading to prevent spam
                original_warning_state = warning('off', 'all');
                mrstModule('add', mrst_env.modules_loaded{:});
                warning(original_warning_state);  % Restore original state
                fprintf('✅ Restored %d MRST modules\n', length(mrst_env.modules_loaded));
            catch
                fprintf('⚠️  Module restoration failed, but paths are loaded\n');
            end
        end
        
        % Step 5: Set global variables for coordination
        global MRST_ROOT_PATH MRST_SESSION_INITIALIZED;
        MRST_ROOT_PATH = mrst_root;
        MRST_SESSION_INITIALIZED = true;
        
        % Step 6: Verify MRST functionality
        if exist('cartGrid', 'file') && exist('computeGeometry', 'file')
            fprintf('✅ MRST session ready (%d modules loaded)\n', length(mrst_env.modules_loaded));
            success = true;
        else
            fprintf('❌ MRST functions not available after session restore\n');
        end
        
    catch ME
        fprintf('❌ Error loading MRST session: %s\n', ME.message);
        success = false;
    end
end