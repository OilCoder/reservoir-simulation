function [field_config, wells_config, fault_config] = load_pebi_configuration()
% LOAD_PEBI_CONFIGURATION - Load all configuration files for PEBI grid generation
%
% PURPOSE:
%   Centralized configuration loading for PEBI grid with fail-fast validation.
%   Implements canon-first policy by validating configuration completeness
%   before proceeding with grid generation.
%
% OUTPUTS:
%   field_config - Grid and PEBI configuration from grid_config.yaml
%   wells_config - Wells system configuration from wells_config.yaml
%   fault_config - Fault system configuration from fault_config.yaml
%
% POLICY COMPLIANCE:
%   - Canon-first: Fails immediately if required configuration missing
%   - Data authority: All parameters sourced from authoritative YAML files
%   - Fail fast: No defensive defaults, explicit validation required
%
% Author: Claude Code AI System
% Policy: KISS Principle compliant (<30 lines)

    % Get script directory (utils/pebi/) and navigate to main mrst directory
    current_file_dir = fileparts(mfilename('fullpath'));  % utils/pebi/
    script_dir = fileparts(fileparts(current_file_dir));   % mrst_simulation_scripts/
    
    % Load field geometry configuration
    field_config = load_field_configuration_internal(script_dir);
    
    % Load wells configuration
    wells_config = load_wells_configuration_internal(script_dir);
    
    % Load fault configuration  
    fault_config = load_fault_configuration_internal(script_dir);
    
end

function field_config = load_field_configuration_internal(script_dir)
% Load and validate field configuration
    config_file = fullfile(script_dir, 'config', 'grid_config.yaml');
    
    if ~exist(config_file, 'file')
        error(['Grid configuration file missing: %s\n' ...
               'REQUIRED: grid_config.yaml must exist with canonical Eagle West parameters.'], config_file);
    end
    
    addpath(fullfile(script_dir, 'utils'));
    full_config = read_yaml_config(config_file, true);
    
    if ~isfield(full_config, 'grid')
        error('Missing grid section in grid_config.yaml');
    end
    
    field_config = full_config.grid;
    field_config.pebi_grid = full_config.pebi_grid;
end

function wells_config = load_wells_configuration_internal(script_dir)
% Load and validate wells configuration
    config_file = fullfile(script_dir, 'config', 'wells_config.yaml');
    
    if ~exist(config_file, 'file')
        error('Wells configuration file missing: %s', config_file);
    end
    
    addpath(fullfile(script_dir, 'utils'));
    wells_config = read_yaml_config(config_file, true);
    
    if ~isfield(wells_config, 'wells_system')
        error('Invalid wells configuration - missing wells_system section');
    end
end

function fault_config = load_fault_configuration_internal(script_dir)
% Load and validate fault configuration
    config_file = fullfile(script_dir, 'config', 'fault_config.yaml');
    
    if ~exist(config_file, 'file')
        error('Fault configuration file missing: %s', config_file);
    end
    
    addpath(fullfile(script_dir, 'utils'));
    fault_config = read_yaml_config(config_file, true);
    
    if ~isfield(fault_config, 'fault_system')
        error('Invalid fault configuration - missing fault_system section');
    end
end