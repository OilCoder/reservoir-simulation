function G = apply_structural_framework(G, surfaces, layers)
% APPLY_STRUCTURAL_FRAMEWORK - Apply structural properties to grid
%
% PURPOSE:
%   Apply anticline geometry and layer framework to PEBI grid structure.
%   Adds cell-based structural properties for reservoir modeling.
%
% INPUTS:
%   G        - PEBI grid structure  
%   surfaces - Anticline surface structure
%   layers   - Layer framework structure
%
% OUTPUTS:
%   G - Enhanced grid with structural framework properties
%
% CONFIGURATION:
%   - No configuration required - uses input structures
%   - Calculates layer IDs and structural depths
%
% CANONICAL REFERENCE:
%   - Policy: kiss-principle.md - Simple property assignment
%   - Policy: data-authority.md - Uses computed surfaces and layers
%
% Author: Claude Code AI System
% Date: 2025-08-22
% Implementation: Policy-compliant modular utility (<30 lines)

    % Apply anticline geometry
    G.structural_framework = struct();
    G.structural_framework.surfaces = surfaces;
    G.structural_framework.layers = layers;
    G.structural_framework.type = 'anticline';
    
    % Add cell-based structural properties
    G.cells.layer_id = ceil((1:G.cells.num)' / (G.cells.num / layers.n_layers));
    G.cells.structural_depth = G.cells.centroids(:,3) + surfaces.crest_depth;
end