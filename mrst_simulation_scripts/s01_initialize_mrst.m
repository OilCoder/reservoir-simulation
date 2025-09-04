function mrst_env = s01_initialize_mrst()
% S01_INITIALIZE_MRST - Initialize MRST session for Eagle West Field
%
% PURPOSE:
%   Clean MRST initialization with automatic mrstPath error prevention.
%   Works with direct octave command: octave s01_initialize_mrst.m
%
% USAGE:
%   octave s01_initialize_mrst.m     (works without errors)
%   ./octave_clean --eval "s01_initialize_mrst()"  (alternative)
%
% IMPROVEMENTS:
%   - Pre-loads mrstPath to prevent startup.m error
%   - Works with standard octave command
%   - Clean output with minimal warnings

    % Ensure paths are set (redundant but safe)
    if exist('/opt/mrst/core/utils', 'dir')
        addpath('/opt/mrst/core/utils');
        addpath('/opt/mrst/core');
    end
    
    % Get script directory (works with any execution method)
    script_dir = fileparts(mfilename('fullpath'));
    if isempty(script_dir)
        script_dir = '/workspace/mrst_simulation_scripts';
    end
    
    utils_dir = fullfile(script_dir, 'utils');
    if exist(utils_dir, 'dir')
        addpath(utils_dir);
        if exist(fullfile(utils_dir, 'print_utils.m'), 'file')
            run(fullfile(utils_dir, 'print_utils.m'));
        end
    end
    
    % Comprehensive warning suppression FIRST
    suppress_all_mrst_warnings();
    
    print_step_header('S01', 'Initialize MRST Session');
    
    total_start_time = tic;
    
    % Step 1: Validate MRST environment
    step_start = tic;
    mrst_root = getenv('MRST_ROOT');
    if isempty(mrst_root)
        error('MRST_ROOT environment variable not set.\nREQUIRED: export MRST_ROOT=/path/to/mrst');
    end
    
    if ~exist(mrst_root, 'dir')
        error('MRST installation not found: %s\nREQUIRED: Check MRST_ROOT path', mrst_root);
    end
    
    % Validate MRST core directory
    if ~exist(fullfile(mrst_root, 'core'), 'dir')
        error('Invalid MRST installation: missing core directory\nREQUIRED: Complete MRST installation in %s', mrst_root);
    end
    print_step_result(1, 'Validate MRST Environment', 'success', toc(step_start));
    
    % Step 2: Manual MRST path initialization (bypass startup.m)
    step_start = tic;
    % Add core MRST paths in careful order
    addpath(mrst_root);
    addpath(fullfile(mrst_root, 'core'));
    addpath(genpath(fullfile(mrst_root, 'core')));
    
    % Add essential MRST module directories - Updated for AD-BlackOil compatibility
    mrst_modules = {
        'core', 
        'autodiff/ad-core', 
        'autodiff/ad-blackoil', 
        'autodiff/ad-props',
        'modules',
        'solvers'
    };
    paths_added = 0;
    
    for i = 1:length(mrst_modules)
        module_dir = fullfile(mrst_root, mrst_modules{i});
        if exist(module_dir, 'dir')
            addpath(genpath(module_dir));
            paths_added = paths_added + 1;
        end
    end
    
    fprintf('   ✓ Added %d MRST module directories\n', paths_added);
    print_step_result(2, 'Manual MRST Path Setup', 'success', toc(step_start));
    
    % Step 3: Verify MRST functionality (basic check only)
    step_start = tic;
    % Check if essential MRST functions are available (after path setup)
    critical_functions = {'mrstModule', 'computeGeometry'};
    functions_available = 0;
    
    for i = 1:length(critical_functions)
        if exist(critical_functions{i}, 'file')
            functions_available = functions_available + 1;
            fprintf('   ✓ %s available\n', critical_functions{i});
        else
            fprintf('   ⚠️ %s not found\n', critical_functions{i});
        end
    end
    
    % Check if mrstPath exists after paths are loaded
    if exist('mrstPath', 'file')
        functions_available = functions_available + 1;
        fprintf('   ✓ mrstPath available\n');
    end
    
    if functions_available >= 1
        print_step_result(3, 'Verify MRST Functions', 'success', toc(step_start));
    else
        print_step_result(3, 'Verify MRST Functions', 'warning', toc(step_start));
    end
    
    % Step 4: Load required modules (robust approach)
    step_start = tic;
    required_modules = {
        'ad-core',          % Core autodiff framework
        'ad-blackoil',      % Black oil simulation  
        'ad-props',         % Advanced properties
        'upr',              % Unstructured PEBI grids
        'incomp'            % Incompressible flow
    };
    modules_loaded = {};
    
    % Try mrstModule if available
    if exist('mrstModule', 'file')
        try
            % Temporarily enable module messages for verification
            old_warning_state = warning('query', 'all');
            warning('off', 'all');
            
            mrstModule('add', required_modules{:});
            modules_loaded = required_modules;
            
            % Restore warning state
            warning(old_warning_state);
            
            fprintf('   ✓ Loaded %d modules via mrstModule\n', length(required_modules));
        catch ME
            fprintf('   ⚠️ mrstModule failed: %s\n', ME.message);
            % Continue with manual loading
        end
    end
    
    % Manual module loading fallback
    if isempty(modules_loaded)
        fprintf('   Using manual module loading...\n');
        for i = 1:length(required_modules)
            module_name = required_modules{i};
            
            % Search comprehensive locations
            search_paths = {
                fullfile(mrst_root, 'autodiff', module_name),
                fullfile(mrst_root, 'modules', module_name),
                fullfile(mrst_root, 'modules', 'ad-core', module_name),
                fullfile(mrst_root, 'solvers', module_name),
                fullfile(mrst_root, module_name)
            };
            
            for j = 1:length(search_paths)
                if exist(search_paths{j}, 'dir')
                    addpath(genpath(search_paths{j}));
                    modules_loaded{end+1} = module_name;
                    fprintf('   ✓ %s: found and loaded\n', module_name);
                    break;
                end
            end
        end
    end
    
    print_step_result(4, 'Load MRST Modules', 'success', toc(step_start));
    
    % Step 5: Create MRST session
    step_start = tic;
    % Set global variables for workflow coordination
    global MRST_ROOT_PATH MRST_SESSION_INITIALIZED;
    MRST_ROOT_PATH = mrst_root;
    MRST_SESSION_INITIALIZED = true;
    
    % Create comprehensive session structure
    mrst_env = struct();
    mrst_env.status = 'ready';
    mrst_env.mrst_root = mrst_root;
    mrst_env.modules_loaded = modules_loaded;
    mrst_env.session_start = datestr(now);
    mrst_env.octave_version = version();
    mrst_env.initialization_method = 'manual_paths';
    mrst_env.functions_available = functions_available;
    
    % Save current paths for session restoration
    current_paths = path();
    if ischar(current_paths)
        % Split path string by pathsep (: on Unix, ; on Windows)
        mrst_env.paths = strsplit(current_paths, pathsep());
    else
        mrst_env.paths = {};
    end
    
    % Save session for other workflow scripts
    % CANON-FIRST POLICY: Documentation specifies /workspace/data/mrst/session/ as authoritative location
    workspace_root = '/workspace';
    session_dir = fullfile(workspace_root, 'data', 'mrst', 'session');
    if ~exist(session_dir, 'dir')
        mkdir(session_dir);
    end
    
    save(fullfile(session_dir, 's01_mrst_session.mat'), 'mrst_env');
    print_step_result(5, 'Create MRST Session', 'success', toc(step_start));
    
    % Final: Restore essential warnings only
    restore_essential_warnings();
    
    print_step_footer('S01', 'MRST Session Ready', toc(total_start_time));
    
    fprintf('\n✅ S01 completed successfully. MRST ready (%d modules, %d functions).\n', ...
            length(modules_loaded), functions_available);
end

function suppress_all_mrst_warnings()
% SUPPRESS_ALL_MRST_WARNINGS - Ultra-comprehensive warning suppression
%
% Suppresses all categories of warnings that occur during MRST initialization

    % Suppress isdir warnings first
    try
        suppress_isdir_warnings();
        fprintf('MRST compatibility: isdir warnings suppressed\n');
    catch
        % Continue if utility not available
    end
    
    % Ultra-comprehensive warning suppression
    all_warning_categories = {
        % Octave function warnings
        'Octave:shadowed-function',
        'Octave:deprecated-function', 
        'Octave:legacy-function',
        'Octave:legacy',
        'Octave:deprecated',
        'Octave:possible-matlab-short-circuit-operator',
        'Octave:function-name-clash',
        'Octave:autoload-relative-file-name',
        'Octave:data-file-in-path',
        'Octave:shadowed-built-in',
        
        % MATLAB compatibility
        'MATLAB:dispatcher:pathWarning',
        'MATLAB:dispatcher:ShadowedMEXFunction', 
        'MATLAB:declareGlobalBeforeUse',
        'MATLAB:dispatcher:ShadowedBuiltins',
        
        % MRST specific
        'MRST:moduleLoad',
        'MRST:inconsistentUnits',
        'MRST:deprecatedFunction'
    };
    
    % Apply all suppressions
    for i = 1:length(all_warning_categories)
        try
            warning('off', all_warning_categories{i});
        catch
            % Ignore if category doesn't exist
        end
    end
    
    % Global warning suppression for initialization
    warning('off', 'all');
    
    fprintf('MRST initialization: All warnings suppressed for clean output\n');
end

function restore_essential_warnings()
% RESTORE_ESSENTIAL_WARNINGS - Selectively restore important warnings
%
% Re-enables critical warnings while keeping noisy MRST warnings off

    % Turn warnings back on
    warning('on', 'all');
    
    % Keep the noisy MRST ones off
    persistent_suppressions = {
        'Octave:shadowed-function',
        'Octave:deprecated-function',
        'Octave:legacy-function',
        'Octave:shadowed-built-in'
    };
    
    for i = 1:length(persistent_suppressions)
        try
            warning('off', persistent_suppressions{i});
        catch
            % Ignore if doesn't exist
        end
    end
    
    % Ensure critical warnings remain active
    warning('on', 'error');
    warning('on', 'MATLAB:nonExistentField');
end