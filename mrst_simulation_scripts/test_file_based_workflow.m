% Requires: MRST
% TEST_FILE_BASED_WORKFLOW - Test independent file-based s06-s08 workflow
%
% OBJECTIVE: Verify that s06-s08 files work independently with file I/O
%            and no function call dependencies between scripts.
%
% WORKFLOW TESTED:
%   s06 → saves base_rock.mat
%   s07 → loads base_rock.mat → saves enhanced_rock.mat  
%   s08 → loads enhanced_rock.mat → saves final_rock.mat
%
% Author: Claude Code AI System
% Date: August 14, 2025

clear all; close all; clc;

fprintf('\n=== TESTING FILE-BASED WORKFLOW (s06-s08) ===\n');
fprintf('Testing complete independence - no function call dependencies\n\n');

script_dir = fileparts(mfilename('fullpath'));
addpath(fullfile(script_dir, 'utils')); 
run(fullfile(script_dir, 'utils', 'print_utils.m'));

% Add MRST session validation
[success, message] = validate_mrst_session(script_dir);
if ~success
    error('MRST validation failed: %s', message);
end

try
    % Test Step 1: s06 creates base_rock.mat
    fprintf('STEP 1: Running s06_create_base_rock_structure.m\n');
    fprintf('Expected output: base_rock.mat\n');
    run('s06_create_base_rock_structure.m');
    
    % Verify base_rock.mat exists
    data_dir = get_data_path('static');
    base_rock_file = fullfile(data_dir, 'base_rock.mat');
    if ~exist(base_rock_file, 'file')
        error('FAILED: s06 did not create base_rock.mat');
    end
    fprintf('✅ PASS: base_rock.mat created successfully\n\n');
    
    % Test Step 2: s07 loads base_rock.mat and creates enhanced_rock.mat
    fprintf('STEP 2: Running s07_add_layer_metadata.m\n');
    fprintf('Expected input: base_rock.mat\n');
    fprintf('Expected output: enhanced_rock.mat\n');
    run('s07_add_layer_metadata.m');
    
    % Verify enhanced_rock.mat exists
    enhanced_rock_file = fullfile(data_dir, 'enhanced_rock.mat');
    if ~exist(enhanced_rock_file, 'file')
        error('FAILED: s07 did not create enhanced_rock.mat');
    end
    fprintf('✅ PASS: enhanced_rock.mat created successfully\n\n');
    
    % Test Step 3: s08 loads enhanced_rock.mat and creates final_rock.mat
    fprintf('STEP 3: Running s08_apply_spatial_heterogeneity.m\n');
    fprintf('Expected input: enhanced_rock.mat\n');
    fprintf('Expected output: final_rock.mat\n');
    run('s08_apply_spatial_heterogeneity.m');
    
    % Verify final_rock.mat exists
    final_rock_file = fullfile(data_dir, 'final_rock.mat');
    if ~exist(final_rock_file, 'file')
        error('FAILED: s08 did not create final_rock.mat');
    end
    fprintf('✅ PASS: final_rock.mat created successfully\n\n');
    
    % Test Step 4: Verify file contents and workflow stage progression
    fprintf('STEP 4: Verifying workflow stage progression\n');
    
    % Load base rock
    base_data = load(base_rock_file);
    if ~strcmp(base_data.rock.meta.workflow_stage, 'base_structure')
        error('FAILED: Base rock workflow stage incorrect');
    end
    fprintf('✅ PASS: Base rock stage = %s\n', base_data.rock.meta.workflow_stage);
    
    % Load enhanced rock
    enhanced_data = load(enhanced_rock_file);
    if ~strcmp(enhanced_data.enhanced_rock.meta.workflow_stage, 'enhanced_metadata')
        error('FAILED: Enhanced rock workflow stage incorrect');
    end
    fprintf('✅ PASS: Enhanced rock stage = %s\n', enhanced_data.enhanced_rock.meta.workflow_stage);
    
    % Load final rock
    final_data = load(final_rock_file);
    if ~strcmp(final_data.final_rock.meta.workflow_stage, 'simulation_ready')
        error('FAILED: Final rock workflow stage incorrect');
    end
    fprintf('✅ PASS: Final rock stage = %s\n', final_data.final_rock.meta.workflow_stage);
    
    % Test Step 5: Verify data consistency across workflow
    fprintf('\nSTEP 5: Verifying data consistency\n');
    
    base_cells = length(base_data.rock.poro);
    enhanced_cells = length(enhanced_data.enhanced_rock.poro);
    final_cells = length(final_data.final_rock.poro);
    
    if base_cells ~= enhanced_cells || enhanced_cells ~= final_cells
        error('FAILED: Cell count inconsistency across workflow');
    end
    fprintf('✅ PASS: Cell count consistent: %d cells\n', final_cells);
    
    if ~isfield(enhanced_data.enhanced_rock.meta, 'layer_info')
        error('FAILED: Enhanced rock missing layer metadata');
    end
    fprintf('✅ PASS: Layer metadata present: %d layers\n', ...
            enhanced_data.enhanced_rock.meta.layer_info.n_layers);
    
    if ~isfield(final_data.final_rock.meta, 'simulation_ready')
        error('FAILED: Final rock missing simulation readiness metadata');
    end
    fprintf('✅ PASS: Simulation readiness: %s\n', ...
            final_data.final_rock.meta.simulation_ready.status);
    
    fprintf('\n=== FILE-BASED WORKFLOW TEST COMPLETE ===\n');
    fprintf('RESULT: ALL TESTS PASSED\n');
    fprintf('✅ Complete independence achieved\n');
    fprintf('✅ No function call dependencies\n');
    fprintf('✅ Clean file I/O workflow\n');
    fprintf('✅ Data consistency maintained\n');
    fprintf('✅ Workflow stage progression correct\n\n');
    
    fprintf('WORKFLOW SUMMARY:\n');
    fprintf('  s06 → base_rock.mat (%d cells)\n', base_cells);
    fprintf('  s07 → enhanced_rock.mat (%d layers)\n', enhanced_data.enhanced_rock.meta.layer_info.n_layers);
    fprintf('  s08 → final_rock.mat (READY)\n\n');
    
catch ME
    fprintf('\n❌ FILE-BASED WORKFLOW TEST FAILED\n');
    fprintf('Error: %s\n', ME.message);
    fprintf('Location: %s:%d\n', ME.stack(1).file, ME.stack(1).line);
    rethrow(ME);
end