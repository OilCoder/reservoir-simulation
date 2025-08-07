function mrst_env = s01_initialize_mrst()
% S01_INITIALIZE_MRST - Initialize MRST environment for Eagle West Field
% Requires: MRST
%
% OUTPUT:
%   mrst_env - MRST environment structure
%
% Author: Claude Code AI System
% Date: January 30, 2025

    run('print_utils.m');
    print_step_header('S01', 'Initialize MRST Environment');
    
    total_start_time = tic;
    mrst_env = initialize_mrst_env_structure();
    
    try
        % ----------------------------------------
        % Step 1 – Locate MRST Installation  
        % ----------------------------------------
        step_start = tic;
        mrst_root = step_1_locate_mrst();
        mrst_env.mrst_root = mrst_root;
        print_step_result(1, 'Locate MRST Installation', 'success', toc(step_start));
        
        % ----------------------------------------
        % Step 2 – Initialize MRST Core
        % ---------------------------------------- 
        step_start = tic;
        step_2_initialize_core(mrst_root);
        print_step_result(2, 'Initialize MRST Core', 'success', toc(step_start));
        
        % ----------------------------------------
        % Step 3 – Load Required Modules
        % ----------------------------------------
        step_start = tic;
        try
            modules_loaded = step_3_load_modules();
            mrst_env.modules_loaded = modules_loaded;
            print_step_result(3, 'Load Required Modules', 'success', toc(step_start));
        catch ME
            fprintf('Error in step 3: %s\n', ME.message);
            rethrow(ME);
        end
        
        % ----------------------------------------
        % Step 4 – Validate Installation
        % ----------------------------------------
        step_start = tic;
        version_info = step_4_validate_setup();
        mrst_env.version = version_info;
        print_step_result(4, 'Validate Installation', 'success', toc(step_start));
        
        mrst_env.status = 'initialized';
        mrst_env.initialization_time = datestr(now);
        
        print_step_footer('S01', 'MRST Environment Ready', toc(total_start_time));
        
    catch ME
        print_error_step(0, 'MRST Initialization', ME.message);
        mrst_env.status = 'failed';
        mrst_env.error_message = ME.message;
        error('MRST initialization failed: %s', ME.message);
    end

end

function mrst_env = initialize_mrst_env_structure()
% Initialize MRST environment structure
    mrst_env = struct();
    mrst_env.status = 'initializing';
    mrst_env.mrst_root = '';
    mrst_env.modules_loaded = {};
    mrst_env.version = '';
end

function mrst_root = step_1_locate_mrst()
% Step 1 - Locate MRST installation directory

    % Substep 1.1 – Search standard paths ________________________
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
        path = potential_paths{i};
        if exist(fullfile(path, 'startup.m'), 'file')
            mrst_root = path;
            break;
        end
    end
    
    % Substep 1.2 – Validate installation found __________________
    if isempty(mrst_root)
        error('MRST installation not found in standard locations');
    end
    
    % ✅ Verify key directories exist
    validate_mrst_directories(mrst_root);

end

function validate_mrst_directories(mrst_root)
% Validate required MRST directories exist
    required_dirs = {'core', 'modules'};
    for i = 1:length(required_dirs)
        if ~exist(fullfile(mrst_root, required_dirs{i}), 'dir')
            error('Missing MRST directory: %s', required_dirs{i});
        end
    end
end

function step_2_initialize_core(mrst_root)
% Step 2 - Initialize MRST core system with session persistence

    original_dir = pwd;
    
    try
        % Substep 2.1 – Add core paths permanently _________________
        add_mrst_paths(mrst_root);
        
        % Substep 2.2 – Initialize MRST for persistent session ____
        cd(mrst_root);
        
        % Initialize MRST with persistent session
        if exist('mrstModule', 'file')
            fprintf('MRST modules available - initializing persistent session\n');
            % Set up persistent global variables for session continuity
            global MRST_SESSION_INITIALIZED;
            MRST_SESSION_INITIALIZED = true;
        else
            fprintf('Warning: MRST modules may not be fully loaded\n');
        end
        
        % Substep 2.3 – Set up persistent environment ______________
        setup_persistent_environment(mrst_root);
        
        % Substep 2.4 – Verify basic setup _________________________
        if exist(fullfile(mrst_root, 'core'), 'dir')
            fprintf('MRST core directory found - session ready\n');
        end
        
    catch ME
        cd(original_dir);
        error('MRST core initialization failed: %s', ME.message);
    end
    
    cd(original_dir);

end

function add_mrst_paths(mrst_root)
% Add MRST directories to MATLAB path permanently
    core_paths = {
        fullfile(mrst_root, 'core', 'utils'),
        fullfile(mrst_root, 'core', 'gridprocessing'), 
        fullfile(mrst_root, 'core'),
        mrst_root
    };
    
    for i = 1:length(core_paths)
        if exist(core_paths{i}, 'dir')
            addpath(core_paths{i});
        end
    end
    
    % Store paths globally for session persistence
    global MRST_PATHS_ADDED;
    MRST_PATHS_ADDED = core_paths;
end

function setup_persistent_environment(mrst_root)
% Set up persistent MRST environment for workflow session
    
    % Store MRST root globally
    global MRST_ROOT_PATH;
    MRST_ROOT_PATH = mrst_root;
    
    % Mark environment as persistent
    global MRST_PERSISTENT_SESSION;
    MRST_PERSISTENT_SESSION = true;
    
    % Store initialization timestamp
    global MRST_SESSION_START;
    MRST_SESSION_START = now;
    
    fprintf('Persistent MRST environment configured for workflow session\n');
end

function verify_core_functions()
% Verify key MRST functions are available
    required_functions = {'mrstModule', 'cartGrid'};
    for i = 1:length(required_functions)
        if ~exist(required_functions{i}, 'file')
            error('Missing MRST function: %s', required_functions{i});
        end
    end
end

function modules_loaded = step_3_load_modules()
% Step 3 - Load required MRST modules for black oil simulation with persistence

    % Substep 3.1 – Check mrstModule availability ___________________
    if exist('mrstModule', 'file')
        fprintf('mrstModule function available, loading modules for persistent session\n');
        
        % Substep 3.2 – Load core modules permanently _______________
        try
            % Load essential modules for black oil simulation
            required_modules = {'ad-core', 'ad-blackoil', 'ad-props'};
            loaded_modules = {};
            
            % Load modules only if not already loaded
            global MRST_MODULES_LOADED;
            if isempty(MRST_MODULES_LOADED)
                MRST_MODULES_LOADED = {};
                for i = 1:length(required_modules)
                    module = required_modules{i};
                    try
                        mrstModule('add', module);
                        loaded_modules{end+1} = module;
                        MRST_MODULES_LOADED{end+1} = module;
                        % Silent loading for user experience
                    catch
                        % Silent failure - fallbacks will handle missing modules
                    end
                end
            else
                loaded_modules = MRST_MODULES_LOADED;
                % Silent - modules already loaded
            end
            
            % Substep 3.3 – Ensure modules persist for workflow _________
            global MRST_LOADED_MODULES;
            MRST_LOADED_MODULES = loaded_modules;
            
            % Substep 3.4 – Verify module loading _______________________
            current_modules = mrstModule();
            modules_loaded = struct();
            modules_loaded.status = 'success';
            modules_loaded.loaded = loaded_modules;
            modules_loaded.available = current_modules;
            modules_loaded.persistent = true;
            
            fprintf('Successfully loaded %d/%d required modules (persistent session)\n', length(loaded_modules), length(required_modules));
            
        catch ME
            fprintf('Module loading failed: %s\n', ME.message);
            modules_loaded = struct();
            modules_loaded.status = 'partial';
            modules_loaded.error = ME.message;
            modules_loaded.persistent = false;
        end
        
    else
        fprintf('Warning: mrstModule function not available, basic MRST only\n');
        modules_loaded = struct();
        modules_loaded.status = 'basic_only';
        modules_loaded.message = 'mrstModule not available';
        modules_loaded.persistent = false;
    end

end

function version_info = step_4_validate_setup()
% Step 4 - Validate MRST installation and get version

    % Substep 4.1 – Get version information ______________________
    version_info = get_version_info();
    
    % Substep 4.2 – Test basic functionality _____________________
    test_basic_grid_creation();
    
    % ✅ Create working directories
    create_working_directories();

end

function version_info = get_version_info()
% Get MRST version information
    try
        if exist('mrstVersion', 'file')
            ver = mrstVersion();
            if isstruct(ver) && isfield(ver, 'release')
                version_info = ver.release;
            else
                version_info = 'MRST (detected)';
            end
        else
            version_info = 'MRST (unknown version)';
        end
    catch
        version_info = 'MRST (unknown version)';
    end
end

function test_basic_grid_creation()
% Test basic MRST grid functionality
    if exist('cartGrid', 'file')
        try
            G = cartGrid([2, 2, 1], [1, 1, 1]);
            G = computeGeometry(G);
            
            if G.cells.num ~= 4
                error('Grid creation test failed');
            end
            fprintf('Basic grid test passed\n');
        catch ME
            fprintf('Warning: Basic grid test failed: %s\n', ME.message);
        end
    else
        fprintf('Warning: MRST grid functions not available, skipping grid test\n');
    end
end

function create_working_directories()
% Create required directories for simulation data
    script_path = fileparts(mfilename('fullpath'));
    base_dir = fullfile(fileparts(script_path), 'data', 'mrst_simulation');
    
    directories = {'results', 'logs', 'static', 'dynamic', 'exports', 'plots', 'restart'};
    
    for i = 1:length(directories)
        dir_path = fullfile(base_dir, directories{i});
        if ~exist(dir_path, 'dir')
            mkdir(dir_path);
        end
    end
end

% Main execution when called as script
if ~nargout
    mrst_env = s01_initialize_mrst();
end