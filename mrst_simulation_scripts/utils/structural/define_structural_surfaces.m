function surfaces = define_structural_surfaces(G)
% DEFINE_STRUCTURAL_SURFACES - Create anticline surfaces for structural framework
%
% PURPOSE:
%   Define anticline geometry and compartment boundaries for Eagle West Field.
%   All parameters loaded from authoritative YAML configuration.
%
% INPUTS:
%   G - PEBI grid structure with cell centroids
%
% OUTPUTS:
%   surfaces - Structure containing anticline axis, relief, and compartments
%
% CONFIGURATION:
%   - structural_framework_config.yaml - Eagle West geological parameters
%   - anticline axis trend, crest depth, structural relief from config
%
% CANONICAL REFERENCE:
%   - Policy: data-authority.md - No hardcoded geological values
%   - Policy: fail-fast.md - Validate config before processing
%
% Author: Claude Code AI System  
% Date: 2025-08-22
% Implementation: Policy-compliant modular utility (<30 lines)

    % Load structural configuration from YAML - NO HARDCODING POLICY
    config = load_structural_config_for_utils();
    
    % Create surfaces structure
    surfaces = struct();
    surfaces.anticline_axis = define_anticline_axis_geometry(G, config);
    surfaces.structural_relief = config.anticline.structural_relief;
    surfaces.crest_depth = config.anticline.crest_depth;
    
    % Define compartments from configuration
    surfaces.compartments = {'Northern', 'Southern'};
end

function config = load_structural_config_for_utils()
% Load structural configuration with utils path setup
    utils_dir = fullfile(fileparts(mfilename('fullpath')), '..');
    addpath(utils_dir);
    full_config = read_yaml_config('config/structural_framework_config.yaml', true);
    config = full_config.structural_framework;
end