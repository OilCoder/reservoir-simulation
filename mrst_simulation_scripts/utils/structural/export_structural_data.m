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
    
    % Also maintain legacy location for compatibility
    legacy_dir = '/workspace/data/mrst';
    if ~exist(legacy_dir, 'dir')
        mkdir(legacy_dir);
    end
    canonical_file = fullfile(legacy_dir, 'grid.mat');
    
    % Load existing grid data
    if exist(canonical_file, 'file')
        load(canonical_file, 'data_struct');
    else
        data_struct = struct();
        data_struct.created_by = {};
    end
    
    % Add structural information and grid to data structure
    data_struct.G = G;
    data_struct.structure.layers = layers;
    data_struct.structure.surfaces = surfaces;
    data_struct.created_by{end+1} = 's04';
    data_struct.timestamp = datestr(now);
    
    % Save to both locations following data catalog
    save(structural_file, 'structural_data');
    save(canonical_file, 'data_struct');
    
    fprintf('     Structural data saved to: %s\n', structural_file);
    fprintf('     Legacy compatibility: %s\n', canonical_file);
end