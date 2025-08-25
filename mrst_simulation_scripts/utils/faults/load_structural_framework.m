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

    % Canon-first: Try canonical location first
    canonical_file = '/workspace/data/mrst/grid.mat';
    
    if exist(canonical_file, 'file')
        load(canonical_file, 'data_struct');
        G = data_struct.G;
        fprintf('   ✅ Loading grid with structure from canonical location\n');
        return;
    end
    
    % Fallback to legacy location with clear warning
    func_dir = fileparts(mfilename('fullpath'));
    addpath(fullfile(func_dir, '..'));
    data_dir = get_data_path('static');
    structural_file = fullfile(data_dir, 'structural_framework.mat');
    
    % Fail-fast validation
    if ~exist(structural_file, 'file')
        error(['CANON-FIRST ERROR: Structural framework not found.\n' ...
               'REQUIRED: Run s04_structural_framework first.\n' ...
               'Expected: %s'], structural_file);
    end
    
    % Load structural data with warning
    load(structural_file, 'structural_data');
    G = structural_data.grid;
    fprintf('   ⚠️  Loading structural data from legacy location\n');

end