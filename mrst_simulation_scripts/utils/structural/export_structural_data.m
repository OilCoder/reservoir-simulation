function structural_data = export_structural_data(G, surfaces, layers)
% EXPORT_STRUCTURAL_DATA - Export structural framework using canonical structure
%
% PURPOSE:
%   Export structural framework data to canonical MRST structure.
%   Updates grid.mat with structural information for workflow continuity.
%
% INPUTS:
%   G        - Enhanced PEBI grid with structural properties
%   surfaces - Anticline surface structure  
%   layers   - Layer framework structure
%
% OUTPUTS:
%   structural_data - Complete structural framework structure
%
% CONFIGURATION:
%   - Uses NEW CANONICAL structure at /workspace/data/mrst/grid.mat
%   - Updates existing grid data with structural information
%
% CANONICAL REFERENCE:
%   - Policy: canon-first.md - Use canonical data structure
%   - Policy: kiss-principle.md - Simple export with metadata
%
% Author: Claude Code AI System
% Date: 2025-08-22
% Implementation: Policy-compliant modular utility (<30 lines)

    % Assemble structural data
    structural_data = struct();
    structural_data.grid = G;
    structural_data.surfaces = surfaces;
    structural_data.layers = layers;
    structural_data.status = 'completed';
    
    % Save to simulation data catalog structure
    static_dir = '/workspace/data/simulation_data/static';
    if ~exist(static_dir, 'dir')
        mkdir(static_dir);
    end
    structural_file = fullfile(static_dir, 'structural_framework.mat');
    
    % Update canonical grid.mat using save_consolidated_data
    % CANON-FIRST POLICY: Use standard utility for all grid updates
    save_consolidated_data('grid', 's04', 'G_pebi', G, 'structure_layers', layers, 'structure_surfaces', surfaces);
    
    % Save detailed structural data to catalog
    save(structural_file, 'structural_data');
    
    fprintf('     Structural data saved to: %s\n', structural_file);
    fprintf('     ✅ Canonical grid.mat updated with structural data\n');
end