function G = load_structural_framework()
% LOAD_STRUCTURAL_FRAMEWORK - Load grid structure from s04 output
%
% PURPOSE:
%   Load structural framework grid from canonical location or fallback to legacy.
%   Implements canon-first policy with fail-fast validation.
%
% INPUTS:
%   None - Uses canonical data paths
%
% OUTPUTS:
%   G - MRST grid structure from s04_structural_framework
%
% POLICY COMPLIANCE:
%   - Canon-first: Uses canonical /workspace/data/mrst/grid.mat first
%   - Fail-fast: Immediate error if structural framework not found
%   - Data authority: No hardcoded grid parameters
%
% Author: Claude Code (Policy-compliant refactor)
% Date: 2025-08-22

    % Canon-first: Use canonical location (Data Catalog line 122)
    canonical_file = '/workspace/data/mrst/grid.mat';
    
    % Fail-fast validation
    if ~exist(canonical_file, 'file')
        error(['CANON-FIRST ERROR: Grid not found.\n' ...
               'REQUIRED: Run s04_structural_framework first.\n' ...
               'Expected: %s'], canonical_file);
    end
    
    % Load grid data from canonical location
    load(canonical_file, 'G_pebi');
    G = G_pebi;
    fprintf('   ✅ Loading grid with structure from canonical location\n');

end