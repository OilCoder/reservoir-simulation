function mrst_env = s01_initialize_mrst()
% S01_INITIALIZE_MRST - Initialize MRST environment for Eagle West Field simulation
%
% SYNTAX:
%   mrst_env = s01_initialize_mrst()
%
% OUTPUT:
%   mrst_env - Structure containing MRST environment information
%
% DESCRIPTION:
%   This script initializes the MRST environment for Eagle West Field
%   reservoir simulation. It sets up all required MRST modules and
%   validates the installation following the FAIL_FAST policy.
%
%   Based on documentation: 08_MRST_Implementation.md
%   
%   Key functions:
%   - Locate and initialize MRST installation
%   - Load required modules for black oil simulation
%   - Validate environment setup
%   - Create working directories
%
% Author: Claude Code AI System
% Date: January 30, 2025

    fprintf('======================================================\n');
    fprintf('Eagle West Field - MRST Environment Initialization\n');
    fprintf('======================================================\n\n');
    
    % Initialize return structure
    mrst_env = struct();
    mrst_env.status = 'initializing';
    mrst_env.mrst_root = '';
    mrst_env.modules_loaded = {};
    mrst_env.version = '';
    
    try
        % Step 1 - Locate MRST installation
        fprintf('Step 1: Locating MRST installation...\n');
        mrst_root = locate_mrst_installation();
        mrst_env.mrst_root = mrst_root;
        fprintf('   ✓ MRST found at: %s\n\n', mrst_root);
        
        % Step 2 - Initialize MRST
        fprintf('Step 2: Initializing MRST...\n');
        initialize_mrst_core(mrst_root);
        fprintf('   ✓ MRST core initialized\n\n');
        
        % Step 3 - Load required modules
        fprintf('Step 3: Loading required MRST modules...\n');
        modules_loaded = load_required_modules();
        mrst_env.modules_loaded = modules_loaded;
        fprintf('   ✓ Loaded %d modules successfully\n\n', length(modules_loaded));
        
        % Step 4 - Get MRST version information
        fprintf('Step 4: Getting MRST version information...\n');
        version_info = get_mrst_version();
        mrst_env.version = version_info;
        fprintf('   ✓ MRST version: %s\n\n', version_info);
        
        % Step 5 - Validate installation
        fprintf('Step 5: Validating MRST installation...\n');
        validate_mrst_installation();
        fprintf('   ✓ MRST validation successful\n\n');
        
        % Step 6 - Create working directories
        fprintf('Step 6: Creating working directories...\n');
        create_working_directories();
        fprintf('   ✓ Working directories created\n\n');
        
        % Step 7 - Final setup
        mrst_env.status = 'initialized';
        mrst_env.initialization_time = datestr(now);
        
        % Success message
        fprintf('======================================================\n');
        fprintf('MRST Environment Successfully Initialized\n');
        fprintf('======================================================\n');
        fprintf('MRST Root: %s\n', mrst_env.mrst_root);
        fprintf('Version: %s\n', mrst_env.version);
        fprintf('Modules Loaded: %s\n', strjoin(mrst_env.modules_loaded, ', '));
        fprintf('Status: %s\n', mrst_env.status);
        fprintf('Timestamp: %s\n', mrst_env.initialization_time);
        fprintf('======================================================\n\n');
        
    catch ME
        % Error handling following FAIL_FAST policy
        fprintf('\n❌ MRST initialization FAILED\n');
        fprintf('Error: %s\n', ME.message);
        fprintf('Location: %s (line %d)\n', ME.stack(1).file, ME.stack(1).line);
        
        mrst_env.status = 'failed';
        mrst_env.error_message = ME.message;
        
        error('MRST initialization failed: %s', ME.message);
    end

end

function mrst_root = locate_mrst_installation()
% LOCATE_MRST_INSTALLATION - Find MRST installation directory
%
% This function searches for MRST in standard installation locations
% and validates that it contains the required startup.m file.

    % Standard MRST installation paths
    potential_paths = {
        '/opt/mrst',
        '/usr/local/mrst', 
        fullfile(getenv('HOME'), 'mrst'),
        fullfile(getenv('HOME'), 'MRST'),
        fullfile(pwd, 'mrst'),
        fullfile(pwd, 'MRST')
    };
    
    % Check each potential path
    mrst_root = '';
    for i = 1:length(potential_paths)
        path = potential_paths{i};
        startup_file = fullfile(path, 'startup.m');
        
        if exist(path, 'dir') && exist(startup_file, 'file')
            mrst_root = path;
            break;
        end
    end
    
    % Validate MRST installation found
    if isempty(mrst_root)
        error(['MRST installation not found in standard locations:\n%s\n\n' ...
               'Please install MRST and ensure startup.m exists in installation directory.\n' ...
               'See: https://www.sintef.no/projectweb/mrst/download/'], ...
               strjoin(potential_paths, '\n'));
    end
    
    % Additional validation - check for key directories in correct structure
    % MRST 2025a has gridprocessing and utils under core/
    required_paths = {
        'core',
        fullfile('core', 'gridprocessing'),
        fullfile('core', 'utils'),
        'modules'
    };
    
    for i = 1:length(required_paths)
        dir_path = fullfile(mrst_root, required_paths{i});
        if ~exist(dir_path, 'dir')
            error('Incomplete MRST installation: missing directory %s', required_paths{i});
        end
    end

end

function initialize_mrst_core(mrst_root)
% INITIALIZE_MRST_CORE - Run MRST startup sequence
%
% INPUT:
%   mrst_root - Path to MRST installation directory

    % Change to MRST directory and run startup
    original_dir = pwd;
    
    try
        % Add MRST core utilities to path first (required for startup)
        addpath(fullfile(mrst_root, 'core', 'utils'));
        fprintf('   Added MRST core utilities to path\n');
        
        % Add other core directories to path
        addpath(fullfile(mrst_root, 'core', 'gridprocessing'));
        addpath(fullfile(mrst_root, 'core'));
        fprintf('   Added MRST core directories to path\n');
        
        % Add MRST root to path
        addpath(mrst_root);
        fprintf('   Added MRST root to path\n');
        
        % Change to MRST directory
        cd(mrst_root);
        
        % Run MRST startup script
        fprintf('   Running MRST startup script...\n');
        startup();
        
        % Verify startup was successful
        if ~exist('mrstModule', 'file')
            error('MRST startup failed - mrstModule function not available');
        end
        
        % Verify key functions are available
        if ~exist('cartGrid', 'file')
            error('MRST startup failed - cartGrid function not available');
        end
        
        fprintf('   MRST startup completed successfully\n');
        
    catch ME
        cd(original_dir); % Restore directory
        error('Failed to initialize MRST core: %s', ME.message);
    end
    
    % Return to original directory
    cd(original_dir);

end

function modules_loaded = load_required_modules()
% LOAD_REQUIRED_MODULES - Load all modules required for black oil simulation
%
% Based on 08_MRST_Implementation.md requirements:
% - ad-core: Automatic differentiation framework
% - ad-blackoil: Black oil model  
% - ad-props: Property functions
% - incomp: Flow solvers
% - mrst-gui: Visualization tools

    % Define required modules for Eagle West Field simulation
    required_modules = {
        'ad-core',      % Automatic differentiation framework
        'ad-blackoil',  % Black oil model
        'ad-props',     % Property functions  
        'ad-fi',        % Fully-implicit solver
        'incomp',       % Flow solvers
        'gridprocessing', % Grid utilities
        'mrst-gui'      % Visualization tools
    };
    
    % Define optional advanced modules
    optional_modules = {
        'upscaling',    % Grid coarsening
        'diagnostics',  % Flow diagnostics
        'ad-mechanics', % Geomechanics
        'wellpaths'     % Well trajectory tools
    };
    
    modules_loaded = {};
    
    % Load required modules
    fprintf('   Loading required modules:\n');
    for i = 1:length(required_modules)
        module = required_modules{i};
        fprintf('     Loading %s...', module);
        
        try
            mrstModule add %s', module;
            modules_loaded{end+1} = module;
            fprintf(' ✓\n');
        catch
            fprintf(' ❌ FAILED\n');
            error('Failed to load required MRST module: %s', module);
        end
    end
    
    % Load optional modules (non-fatal if missing)
    fprintf('   Loading optional modules:\n');
    for i = 1:length(optional_modules)
        module = optional_modules{i};
        fprintf('     Loading %s...', module);
        
        try
            eval(sprintf('mrstModule add %s', module));
            modules_loaded{end+1} = module;
            fprintf(' ✓\n');
        catch
            fprintf(' ⚠ (not available)\n');
        end
    end

end

function version_info = get_mrst_version()
% GET_MRST_VERSION - Get MRST version information

    try
        % Try to get version using mrstVersion function
        if exist('mrstVersion', 'file')
            version_info = mrstVersion();
            if isstruct(version_info)
                if isfield(version_info, 'release')
                    version_info = version_info.release;
                else
                    version_info = 'MRST (version info available)';
                end
            end
        else
            version_info = 'MRST (version unknown)';
        end
        
        % Convert to string if needed
        if ~ischar(version_info)
            version_info = 'MRST (version detected)';
        end
        
    catch
        version_info = 'MRST (version unknown)';
    end

end

function validate_mrst_installation()
% VALIDATE_MRST_INSTALLATION - Validate that MRST is properly set up
%
% This function performs basic tests to ensure MRST functionality
% is available for reservoir simulation.

    fprintf('   Running MRST functionality tests...\n');
    
    % Test 1 - Basic grid creation
    fprintf('     Testing basic grid creation...');
    try
        G = cartGrid([2, 2, 1], [1, 1, 1]);
        G = computeGeometry(G);
        
        if G.cells.num == 4
            fprintf(' ✓\n');
        else
            error('Grid creation test failed - wrong cell count');
        end
    catch ME
        fprintf(' ❌\n');
        error('Basic grid creation test failed: %s', ME.message);
    end
    
    % Test 2 - Key MRST functions
    fprintf('     Testing key MRST functions...');
    try
        % Test if key functions are available after module loading
        key_functions = {'mrstModule', 'computeGeometry', 'cartGrid'};
        missing_functions = {};
        
        for i = 1:length(key_functions)
            if ~exist(key_functions{i}, 'file')
                missing_functions{end+1} = key_functions{i};
            end
        end
        
        if isempty(missing_functions)
            fprintf(' ✓\n');
        else
            error('Missing functions: %s', strjoin(missing_functions, ', '));
        end
    catch ME
        fprintf(' ❌\n');
        error('MRST functions test failed: %s', ME.message);
    end
    
    fprintf('   All functionality tests passed!\n');

end

function create_working_directories()
% CREATE_WORKING_DIRECTORIES - Create required directories for simulation data
%
% Creates the directory structure for storing simulation results,
% following the project organization defined in documentation.

    % Get base data directory (relative to script location)
    script_path = fileparts(mfilename('fullpath'));
    base_dir = fullfile(fileparts(script_path), 'data', 'mrst_simulation');
    
    % Define directory structure
    directories = {
        fullfile(base_dir, 'results'),      % Simulation results
        fullfile(base_dir, 'logs'),         % Execution logs
        fullfile(base_dir, 'static'),       % Grid and rock properties  
        fullfile(base_dir, 'dynamic'),      % Pressure and saturation data
        fullfile(base_dir, 'exports'),      % Exported data files
        fullfile(base_dir, 'plots'),        % Generated plots and figures
        fullfile(base_dir, 'restart')       % Restart files
    };
    
    % Create directories
    for i = 1:length(directories)
        dir_path = directories{i};
        if ~exist(dir_path, 'dir')
            mkdir(dir_path);
            fprintf('     Created: %s\n', dir_path);
        else
            fprintf('     Exists: %s\n', dir_path);
        end
    end

end

% Main execution when called as script
if ~nargout
    % If called as script (not function), run initialization
    mrst_env = s01_initialize_mrst();
end