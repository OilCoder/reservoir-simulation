function s00_initialize_mrst()
% s00_initialize_mrst - Initialize MRST environment for Octave
%
% Initializes MRST core, loads required modules, and verifies functions
% are available for simulation execution.
%
% Args:
%   None
%
% Returns:
%   None (sets up MRST environment)
%
% Requires: MRST

% ----------------------------------------
% Step 1 – MRST Core Detection and Loading
% ----------------------------------------

fprintf('[INFO] Initializing MRST for Octave...\n');

% Substep 1.1 – Use existing load_mrst function _______________
current_dir = pwd;
try
    % Navigate to project root to use load_mrst function
    cd('..');
    
    % Define mrstPath before using it
    mrstPath = '/opt/mrst';
    addpath(mrstPath);
    
    % Call the existing load_mrst function
    load_mrst();
    fprintf('[INFO] MRST loaded successfully using load_mrst()\n');
    
    % Ensure MRST paths are still available after returning
    % Add critical MRST paths that may be needed
    addpath('/opt/mrst/core');
    addpath('/opt/mrst/core/gridprocessing');
    addpath('/opt/mrst/core/utils');
    addpath('/opt/mrst/core/solvers');
    addpath('/opt/mrst/core/params/rock');
    addpath('/opt/mrst/solvers/incomp/fluid/incompressible');
    
    % Add utils recursively since it contains many subdirectories
    addpath(genpath('/opt/mrst/core/utils'));
    addpath(genpath('/opt/mrst/core/params'));
    addpath(genpath('/opt/mrst/solvers'));
    
    % Return to mrst_simulation_scripts directory
    cd(current_dir);
    
catch ME
    cd(current_dir); % Ensure we return to original directory
    error('[ERROR] Failed to load MRST: %s', ME.message);
end

% ----------------------------------------
% Step 2 – Verify MRST functions are available
% ----------------------------------------

try
    % Test if key MRST functions are available
    which('cartGrid');
    which('makeRock');
    which('initSimpleFluid');
    which('addWell');
    which('simpleSchedule');
    fprintf('[INFO] MRST functions verified and ready\n');
catch
    error('[ERROR] MRST functions not available, check installation');
end

end
