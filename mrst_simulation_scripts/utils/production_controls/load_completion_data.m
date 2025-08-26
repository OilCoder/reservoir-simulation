function [completion_data, config] = load_completion_data()
% LOAD_COMPLETION_DATA - Load well completion data and configuration
%
% OUTPUTS:
%   completion_data - Structure with wells completion data and W structure
%   config          - Combined wells and production configuration
%
% DATA AUTHORITY: Loads from canonical MRST wells.mat and YAML configs
% FAIL FAST: Immediate error if required files missing

    script_path = fileparts(fileparts(fileparts(mfilename('fullpath'))));
    
    % Substep 1.1 - Load completion data from canonical wells.mat
    canonical_wells_file = '/workspace/data/mrst/wells.mat';
    if ~exist(canonical_wells_file, 'file')
        error(['Missing canonical wells file: %s\n' ...
               'REQUIRED: Run s16_well_completions.m to generate canonical wells structure.'], ...
               canonical_wells_file);
    end
    
    wells_data = load(canonical_wells_file, 'data_struct');
    completion_data = struct();
    completion_data.wells_data = wells_data.data_struct;
    completion_data.W = wells_data.data_struct.W;
    fprintf('Loaded wells data from canonical structure: %d wells\n', length(completion_data.W));
    
    % Substep 1.2 - Load wells configuration
    wells_config_path = fullfile(script_path, 'config', 'wells_config.yaml');
    if ~exist(wells_config_path, 'file')
        error(['Wells configuration not found: %s\n' ...
               'REQUIRED: Ensure wells_config.yaml exists in config directory.'], wells_config_path);
    end
    
    addpath(fullfile(script_path, 'utils'));
    wells_config = read_yaml_config(wells_config_path);
    fprintf('Loaded wells configuration\n');
    
    % Substep 1.3 - Load production configuration
    production_config_path = fullfile(script_path, 'config', 'production_config.yaml');
    if ~exist(production_config_path, 'file')
        error(['Production configuration not found: %s\n' ...
               'REQUIRED: Ensure production_config.yaml exists in config directory.'], production_config_path);
    end
    
    production_config = read_yaml_config(production_config_path);
    fprintf('Loaded production configuration\n');
    
    % Substep 1.4 - Combine configurations
    config = struct();
    config.wells_system = wells_config.wells_system;
    config.production_controls = production_config.production_controls;

end