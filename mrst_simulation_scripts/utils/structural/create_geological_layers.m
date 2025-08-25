function layers = create_geological_layers(G, surfaces, config)
% CREATE_GEOLOGICAL_LAYERS - Create layer framework from configuration
%
% PURPOSE:
%   Create 12-layer geological framework using configuration parameters.
%   Implements data authority policy with no hardcoded layer properties.
%
% INPUTS:
%   G        - PEBI grid structure
%   surfaces - Anticline surface structure
%   config   - Structural configuration from YAML
%
% OUTPUTS:
%   layers - Layer structure with tops, thickness, and metadata
%
% CONFIGURATION:
%   - layering.n_layers, layering.layer_thickness from config
%   - Layer tops calculated from crest depth and thickness
%
% CANONICAL REFERENCE:
%   - Policy: data-authority.md - All layer parameters from config
%   - Policy: kiss-principle.md - Simple layer structure
%
% Author: Claude Code AI System
% Date: 2025-08-22
% Implementation: Policy-compliant modular utility (<30 lines)

    % Create layer structure from YAML config
    layers = struct();
    % For PEBI grids, get number of layers from config instead of cartDims
    layers.n_layers = config.layering.n_layers;  % From YAML config - PEBI grid compatible
    layer_thickness = config.layering.layer_thickness;  % From YAML - Policy compliance
    layers.layer_tops = surfaces.crest_depth + (0:layers.n_layers-1) * layer_thickness;
    layers.anticline_structure = true;
end