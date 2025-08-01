function init_and_run()
% INIT_AND_RUN - Initialize MRST and run Eagle West workflow
%
% This script properly initializes MRST with correct paths and then
% executes the complete Eagle West Field Phase 1 workflow

    fprintf('Initializing MRST environment...\n');
    
    % Add MRST paths
    mrst_path = '/opt/mrst';
    addpath(mrst_path);
    addpath(fullfile(mrst_path, 'core'));
    addpath(fullfile(mrst_path, 'autodiff'));
    addpath(fullfile(mrst_path, 'solvers'));
    addpath(fullfile(mrst_path, 'visualization'));
    addpath(fullfile(mrst_path, 'model-io'));
    
    % Add specific modules
    addpath(fullfile(mrst_path, 'autodiff', 'ad-core'));
    addpath(fullfile(mrst_path, 'autodiff', 'ad-blackoil'));
    addpath(fullfile(mrst_path, 'autodiff', 'ad-props'));
    addpath(fullfile(mrst_path, 'solvers', 'incomp'));
    addpath(fullfile(mrst_path, 'core', 'gridtools'));
    addpath(fullfile(mrst_path, 'visualization', 'mrst-gui'));
    
    fprintf('MRST paths configured. Running Eagle West workflow...\n\n');
    
    % Run the workflow
    s00_run_complete_workflow();
end