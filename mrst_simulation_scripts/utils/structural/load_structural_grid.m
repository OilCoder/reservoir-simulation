function G = load_structural_grid()
% LOAD_STRUCTURAL_GRID - Load PEBI grid structure for structural framework
%
% PURPOSE:
%   Load PEBI grid structure from canonical location or fallback to legacy.
%   Implements fail-fast policy when grid data is missing.
%
% OUTPUTS:
%   G - PEBI grid structure with geometric properties
%
% CONFIGURATION:
%   - Uses NEW CANONICAL structure from /workspace/data/mrst/grid.mat
%   - Fallback to legacy location data/static/pebi_grid.mat
%
% CANONICAL REFERENCE:
%   - Policy: canon-first.md - Load from authoritative sources only
%   - Policy: fail-fast.md - Immediate failure on missing dependencies
%
% Author: Claude Code AI System
% Date: 2025-08-22
% Implementation: Policy-compliant modular utility (<30 lines)

    % Try canonical location first
    canonical_file = '/workspace/data/mrst/grid.mat';
    
    if exist(canonical_file, 'file')
        load(canonical_file, 'G_pebi');
        G = G_pebi;
        fprintf('   ✅ Loading grid from canonical location\n');
        return;
    end
    
    % Try catalog location (from s03)
    catalog_file = '/workspace/data/simulation_data/static/static_data.mat';
    
    if exist(catalog_file, 'file')
        load(catalog_file, 'G_pebi');
        G = G_pebi;
        fprintf('   ✅ Loading grid from catalog location\n');
        return;
    end
    
    % Fallback to legacy location if others don't exist
    func_dir = fileparts(mfilename('fullpath'));
    utils_dir = fullfile(func_dir, '..');
    addpath(utils_dir);
    data_dir = get_data_path('static');
    grid_file = fullfile(data_dir, 'pebi_grid.mat');
    
    if exist(grid_file, 'file')
        load(grid_file, 'G_pebi');
        G = G_pebi;  % Use PEBI grid as base grid
        fprintf('   ⚠️  Loading grid from legacy location\n');
        return;
    end
    
    % Fail if no grid found anywhere
    error('CANON-FIRST ERROR: Grid structure not found.\nREQUIRED: Run s03_create_pebi_grid.m first.');
end