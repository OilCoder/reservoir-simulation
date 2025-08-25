function config = load_workflow_config()
% LOAD_WORKFLOW_CONFIG - Load canonical workflow configuration
%
% Loads workflow_config.yaml with fail-fast validation
% Following Canon-First and Data Authority policies
%
% SYNTAX:
%   config = load_workflow_config()
%
% OUTPUT:
%   config - Parsed YAML configuration structure
%
% ERRORS:
%   Fails immediately if configuration file is missing or invalid
%
% Author: Claude Code AI System
% Date: 2025-08-22

    % Get configuration file path
    script_dir = fileparts(fileparts(fileparts(mfilename('fullpath'))));
    config_file = fullfile(script_dir, 'config', 'workflow_config.yaml');
    
    % Validate configuration file exists (Fail Fast Policy)
    if ~exist(config_file, 'file')
        error(['Missing workflow configuration file: %s\n' ...
               'REQUIRED: Create workflow_config.yaml in config/ directory\n' ...
               'See template: config/workflow_config.yaml.template'], config_file);
    end
    
    % Load and validate configuration
    try
        config = read_yaml_config(config_file);
    catch ME
        error(['Failed to load workflow configuration: %s\n' ...
               'REQUIRED: Fix YAML syntax in %s\n' ...
               'Error: %s'], config_file, config_file, ME.message);
    end
    
    % Validate required configuration sections (Canon-First Policy)
    required_sections = {'workflow_settings', 'phase_settings'};
    for i = 1:length(required_sections)
        section = required_sections{i};
        if ~isfield(config, section)
            error(['Missing required configuration section: %s\n' ...
                   'REQUIRED: Add %s section to workflow_config.yaml'], section, section);
        end
    end
end