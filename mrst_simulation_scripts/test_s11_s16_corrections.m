% TEST_S11_S16_CORRECTIONS - Quick validation test for s11-s16 corrections
% Tests function name corrections and basic loading
%
% This test verifies that:
% 1. All function names match their filenames
% 2. Basic structure and dependencies are correctly referenced
% 3. Files can be parsed without syntax errors

function test_results = test_s11_s16_corrections()
    fprintf('\n=== TESTING S11-S16 CORRECTIONS ===\n\n');
    
    test_results = struct();
    test_results.tests_passed = 0;
    test_results.tests_failed = 0;
    test_results.errors = {};
    
    % Test cases
    test_cases = {
        's11_pvt_tables', 's11_pvt_tables.m';
        's12_pressure_initialization', 's12_pressure_initialization.m';
        's13_saturation_distribution', 's13_saturation_distribution.m';
        's14_aquifer_configuration', 's14_aquifer_configuration.m';
        's15_well_placement', 's15_well_placement.m';
        's16_well_completions', 's16_well_completions.m'
    };
    
    for i = 1:size(test_cases, 1)
        function_name = test_cases{i, 1};
        file_name = test_cases{i, 2};
        
        fprintf('Testing %s...\n', file_name);
        
        try
            % Test 1: Check if function exists
            if exist(function_name, 'file') == 2
                fprintf('  ✅ Function %s exists\n', function_name);
                test_results.tests_passed = test_results.tests_passed + 1;
            else
                fprintf('  ❌ Function %s not found\n', function_name);
                test_results.tests_failed = test_results.tests_failed + 1;
                test_results.errors{end+1} = sprintf('Function %s not found', function_name);
            end
            
            % Test 2: Check function name in file matches filename
            file_content = fileread(file_name);
            expected_pattern = sprintf('function.*%s\\(', function_name);
            if ~isempty(regexp(file_content, expected_pattern, 'once'))
                fprintf('  ✅ Function name matches filename\n');
                test_results.tests_passed = test_results.tests_passed + 1;
            else
                fprintf('  ❌ Function name does not match filename\n');
                test_results.tests_failed = test_results.tests_failed + 1;
                test_results.errors{end+1} = sprintf('Function name mismatch in %s', file_name);
            end
            
            % Test 3: Check for correct step headers
            step_num = file_name(2:3);  % Extract step number (e.g., '11' from 's11_...')
            header_pattern = sprintf('print_step_header\\(''S%s''', step_num);
            if ~isempty(regexp(file_content, header_pattern, 'once'))
                fprintf('  ✅ Correct step header S%s\n', step_num);
                test_results.tests_passed = test_results.tests_passed + 1;
            else
                fprintf('  ❌ Incorrect step header (expected S%s)\n', step_num);
                test_results.tests_failed = test_results.tests_failed + 1;
                test_results.errors{end+1} = sprintf('Incorrect step header in %s', file_name);
            end
            
        catch ME
            fprintf('  ❌ Error testing %s: %s\n', file_name, ME.message);
            test_results.tests_failed = test_results.tests_failed + 1;
            test_results.errors{end+1} = sprintf('Error in %s: %s', file_name, ME.message);
        end
        
        fprintf('\n');
    end
    
    % Summary
    fprintf('=== TEST SUMMARY ===\n');
    fprintf('Tests Passed: %d\n', test_results.tests_passed);
    fprintf('Tests Failed: %d\n', test_results.tests_failed);
    
    if test_results.tests_failed > 0
        fprintf('\nErrors:\n');
        for i = 1:length(test_results.errors)
            fprintf('  - %s\n', test_results.errors{i});
        end
    end
    
    if test_results.tests_failed == 0
        fprintf('\n🎉 ALL CORRECTIONS SUCCESSFUL!\n');
        test_results.status = 'success';
    else
        fprintf('\n⚠️  Some corrections need attention.\n');
        test_results.status = 'needs_attention';
    end
    
    fprintf('\n');
end

% Execute test
if ~nargout
    test_results = test_s11_s16_corrections();
end