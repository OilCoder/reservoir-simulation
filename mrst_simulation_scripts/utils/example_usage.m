% EXAMPLE_USAGE - Demonstrates standardized MRST validation usage
% Requires: MRST
%
% DESCRIPTION:
%   This example shows how to integrate the standardized validate_mrst_session
%   function into existing MRST workflow scripts. This pattern should be used
%   to replace the 18 inconsistent initialization patterns identified in the audit.
%
% Author: Claude Code AI System
% Date: January 30, 2025

function example_usage()
    fprintf('\n');
    fprintf('MRST Standardized Validation - Usage Example\n');
    fprintf('============================================\n\n');
    
    % STEP 1: Standard setup pattern for all sNN scripts
    script_dir = fileparts(mfilename('fullpath'));
    script_dir = fileparts(script_dir); % Go up from utils/ to main directory
    addpath(fullfile(script_dir, 'utils'));
    
    % Load print utilities (standard pattern)
    run(fullfile(script_dir, 'utils', 'print_utils.m'));
    
    % STEP 2: Standardized MRST validation (replaces all inconsistent patterns)
    fprintf('Step 1: Validating MRST session...\n');
    
    try
        [success, message] = validate_mrst_session(script_dir);
        
        if ~success
            error('MRST validation failed: %s', message);
        end
        
        fprintf('✅ MRST validation successful: %s\n', message);
        
    catch ME
        fprintf('❌ MRST validation error: %s\n', ME.message);
        fprintf('\nThis would cause the script to exit in production.\n');
        fprintf('Continuing with example for demonstration...\n');
    end
    
    fprintf('\n');
    
    % STEP 3: Now safe to use MRST functions
    fprintf('Step 2: Using MRST functions (example)...\n');
    
    if exist('cartGrid', 'file')
        try
            % Example MRST grid creation
            G_example = cartGrid([3, 3, 1], [100, 100, 10]);
            G_example = computeGeometry(G_example);
            
            fprintf('✅ Example grid created: %d cells\n', G_example.cells.num);
            fprintf('   Grid dimensions: [%d, %d, %d]\n', ...
                    G_example.cartDims(1), G_example.cartDims(2), G_example.cartDims(3));
            
        catch ME
            fprintf('❌ Grid creation failed: %s\n', ME.message);
        end
    else
        fprintf('⚠️  cartGrid function not available - MRST not fully initialized\n');
    end
    
    fprintf('\n');
    
    % STEP 4: Standard completion pattern
    fprintf('Example completed successfully.\n');
    fprintf('This pattern should be used in all 18 scripts identified in audit.\n\n');
    
    % Show the pattern summary
    show_pattern_summary();

end

function show_pattern_summary()
    fprintf('STANDARDIZED PATTERN SUMMARY:\n');
    fprintf('============================\n\n');
    
    fprintf('BEFORE (Inconsistent - from audit):\n');
    fprintf('  if ~exist(''cartGrid'', ''file'')\n');
    fprintf('      run(''s01_initialize_mrst.m'')\n');
    fprintf('  end\n\n');
    
    fprintf('AFTER (Standardized - this implementation):\n');
    fprintf('  [success, message] = validate_mrst_session(script_dir);\n');
    fprintf('  if ~success\n');
    fprintf('      error(''MRST validation failed: %%s'', message);\n');
    fprintf('  end\n\n');
    
    fprintf('BENEFITS:\n');
    fprintf('  ✅ Unified error handling\n');
    fprintf('  ✅ Consistent logging format\n');
    fprintf('  ✅ Clear success/failure indicators\n');
    fprintf('  ✅ Robust fallback initialization\n');
    fprintf('  ✅ Module validation included\n\n');
    
    fprintf('SCRIPTS TO UPDATE (from audit):\n');
    fprintf('  18 sNN scripts need this standardization\n');
    fprintf('  Replace individual MRST checks with validate_mrst_session()\n');
    
end

% Run example if called as script
if ~nargout
    example_usage();
end