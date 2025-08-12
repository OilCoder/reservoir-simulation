function [simulation_data, field_config] = load_simulation_results()
% LOAD_SIMULATION_RESULTS - Load simulation results for production analysis
%
% OUTPUT:
%   simulation_data - Structure with simulation results
%   field_config - Field configuration data

    % Load simulation results from latest run
    data_dir = '/workspaces/claudeclean/data/simulation_data/results';
    
    % Find latest simulation results file
    files = dir(fullfile(data_dir, 'simulation_results_*.mat'));
    if isempty(files)
        error('No simulation results found in %s', data_dir);
    end
    
    % Sort by date and get latest
    [~, idx] = sort({files.date}, 'descend');
    latest_file = fullfile(data_dir, files(idx(1)).name);
    
    % Load simulation data
    fprintf('   Loading simulation results: %s\n', files(idx(1)).name);
    simulation_data = load(latest_file);
    
    % Load field configuration
    config_file = '/workspaces/claudeclean/mrst_simulation_scripts/config/wells_config.yaml';
    if exist(config_file, 'file')
        addpath('../');
        field_config = read_yaml_config(config_file, true);
    else
        warning('Field configuration not found, using defaults');
        field_config = struct();
    end
    
    fprintf('   ✅ Simulation results loaded successfully\n');
end