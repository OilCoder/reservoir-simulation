% Test suite for [module_name] functionality
% TEST_GROUP: unit
% Requires: MRST

% ----------------------------------------
% Step 1 – Test Setup
% ----------------------------------------

function test_suite = test_module_name()
    % Main test runner function
    test_suite = functiontests(localfunctions);
end

% Setup function run before each test
function setup(testCase)
    % Add paths if needed
    addpath('..');
    
    % Initialize test data
    testCase.TestData.input1 = [1, 2, 3, 4, 5];
    testCase.TestData.input2 = struct('field1', 10, 'field2', 20);
    testCase.TestData.expected = 15;
end

% Teardown function run after each test  
function teardown(testCase)
    % Clean up after tests
    close all;
end

% ----------------------------------------
% Step 2 – Unit Tests for Main Function
% ----------------------------------------

function test_main_function_normal_case(testCase)
    % Test function with normal valid inputs
    
    % ✅ Arrange
    input_data = testCase.TestData.input1;
    expected = testCase.TestData.expected;
    
    % 🔄 Act
    result = main_function(input_data);
    
    % 📊 Assert
    assert(result == expected, ...
           sprintf('Expected %g but got %g', expected, result));
end

function test_main_function_empty_input(testCase)
    % Test function with empty input
    
    % ✅ Arrange
    empty_input = [];
    
    % 🔄 Act & Assert
    try
        result = main_function(empty_input);
        assert(false, 'Should have thrown error for empty input');
    catch ME
        assert(contains(ME.message, 'empty'), ...
               'Error message should mention empty input');
    end
end

function test_main_function_struct_input(testCase)
    % Test function with structure input
    
    % ✅ Arrange  
    struct_input = testCase.TestData.input2;
    
    % 🔄 Act
    result = main_function_struct(struct_input);
    
    % 📊 Assert
    assert(isstruct(result), 'Result should be a structure');
    assert(isfield(result, 'output1'), 'Result should have output1 field');
end

% ----------------------------------------
% Step 3 – Edge Case Tests
% ----------------------------------------

function test_boundary_conditions(testCase)
    % Test function at boundary conditions
    
    % Test with single element
    single_element = [42];
    result = main_function(single_element);
    assert(result == 42, 'Single element should return itself');
    
    % Test with negative values
    negative_vals = [-1, -2, -3];
    result = main_function(negative_vals);
    assert(result == -6, 'Should handle negative values correctly');
    
    % Test with zeros
    zeros_array = [0, 0, 0];
    result = main_function(zeros_array);
    assert(result == 0, 'Should handle zeros correctly');
end

function test_large_input_performance(testCase)
    % Test performance with large dataset
    
    % ✅ Arrange
    large_data = rand(1, 1000000);
    
    % 🔄 Act
    tic;
    result = main_function(large_data);
    elapsed_time = toc;
    
    % 📊 Assert
    assert(~isempty(result), 'Should return non-empty result');
    assert(elapsed_time < 1.0, ...
           sprintf('Should complete in < 1s, took %.2fs', elapsed_time));
end

% ----------------------------------------
% Step 4 – Integration Tests
% ----------------------------------------

function test_full_workflow(testCase)
    % Test complete workflow integration
    
    % ✅ Arrange
    input_data = testCase.TestData.input1;
    options = struct('verbose', false, 'validate', true);
    
    % 🔄 Act
    step1_result = preprocess_data(input_data);
    step2_result = main_function(step1_result, options);
    final_result = postprocess_data(step2_result);
    
    % 📊 Assert
    assert(~isempty(final_result), 'Workflow should produce result');
    assert(isnumeric(final_result), 'Result should be numeric');
end

% ----------------------------------------
% Step 5 – Helper Functions for Testing
% ----------------------------------------

function data = preprocess_data(raw_data)
    % Mock preprocessing function
    data = raw_data * 2;
end

function result = postprocess_data(processed_data)
    % Mock postprocessing function
    result = processed_data / 2;
end

% ----------------------------------------
% Step 6 – Test Utilities
% ----------------------------------------

function assert_approx_equal(actual, expected, tolerance)
    % Assert approximate equality for floating point
    if nargin < 3
        tolerance = 1e-10;
    end
    
    diff = abs(actual - expected);
    assert(diff < tolerance, ...
           sprintf('Expected %.10g but got %.10g (diff: %.10g)', ...
                   expected, actual, diff));
end