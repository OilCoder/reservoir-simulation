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
%   - Uses CANONICAL structure from /workspace/data/mrst/grid.mat
%   - Fail fast on missing canonical location
%
% CANONICAL REFERENCE:
%   - Policy: canon-first.md - Load from authoritative sources only
%   - Policy: fail-fast.md - Immediate failure on missing dependencies
%
% Author: Claude Code AI System
% Date: 2025-08-22
% Implementation: Policy-compliant modular utility (<30 lines)

    % CANON-FIRST POLICY: Load from authoritative location only
    canonical_file = '/workspace/data/mrst/grid.mat';
    
    if ~exist(canonical_file, 'file')
        error(['CANON-FIRST POLICY ERROR: Grid file not found at canonical location.\n' ...
               'REQUIRED: %s\n' ...
               'SOLUTION: Run s03_create_pebi_grid.m first.\n' ...
               'REFERENCE: Data Catalog line 122 specifies canonical data location.'], canonical_file);
    end
    
    % Load grid from canonical location
    load(canonical_file, 'G_pebi');
    G = G_pebi;
    fprintf('   ✅ Loading grid from canonical location: %s\n', canonical_file);
end