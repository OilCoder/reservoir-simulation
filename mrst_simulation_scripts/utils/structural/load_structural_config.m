function config = load_structural_config()
% LOAD_STRUCTURAL_CONFIG - Load structural configuration from YAML
%
% PURPOSE:
%   Load structural configuration with fail-fast validation.
%   Implements data authority policy by loading ALL parameters from YAML.
%
% OUTPUTS:
%   config - Structural configuration structure from YAML
%
% CONFIGURATION:
%   - structural_framework_config.yaml - Eagle West geological parameters
%   - Validates required fields: anticline, layering, compartments
%
% CANONICAL REFERENCE:
%   - Policy: data-authority.md - No hardcoding, YAML authority only
%   - Policy: fail-fast.md - Validate config structure before use
%
% Author: Claude Code AI System
% Date: 2025-08-22
% Implementation: Policy-compliant modular utility (<30 lines)

    try
        % Policy Compliance: Load ALL parameters from YAML config
        func_dir = fileparts(mfilename('fullpath'));
        utils_dir = fullfile(func_dir, '..');
        addpath(utils_dir);
        full_config = read_yaml_config('config/structural_framework_config.yaml', true);
        config = full_config.structural_framework;
        
        % Validate required fields exist
        required_fields = {'anticline', 'layering', 'compartments'};
        for i = 1:length(required_fields)
            if ~isfield(config, required_fields{i})
                error('Missing required field in structural_framework_config.yaml: %s', required_fields{i});
            end
        end
        
        fprintf('Structural framework configuration loaded from YAML\n');
        
    catch ME
        error('Failed to load structural configuration from YAML: %s\nPolicy violation: No hardcoding allowed', ME.message);
    end
end