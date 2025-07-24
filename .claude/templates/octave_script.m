% Script purpose - Brief description of what this script does
% Requires: MRST
% Author: [Name]
% Date: [Date]
%
% Description:
%   Detailed description of the script's functionality
%
% Usage:
%   result = script_name(input1, input2)

% ----------------------------------------
% Step 1 – Initialize Environment
% ----------------------------------------

% Substep 1.1 – Clear workspace and setup MRST ______________________
clear all; close all; clc;

% Check if MRST is in path
if ~exist('mrstModule', 'file')
    error('MRST not found. Please run startup.m first');
end

% Load required MRST modules
mrstModule add ad-core ad-blackoil ad-props;

% Substep 1.2 – Define global parameters ______________________
% Physical dimensions
nx = 20;  % Grid cells in x-direction
ny = 20;  % Grid cells in y-direction  
nz = 5;   % Grid cells in z-direction

% Fluid properties
fluid_viscosity = 1*centi*poise;  % [cP]
fluid_density = 1000;              % [kg/m³]

% ----------------------------------------
% Step 2 – Main Function Definition
% ----------------------------------------

function [output] = main_processing_function(input_data, options)
    % PURPOSE: Main processing function for the script
    % INPUTS:
    %   input_data - Structure containing input parameters
    %                .field1 - Description [units]
    %                .field2 - Description [units]
    %   options    - Optional parameters (struct)
    %                .verbose - Enable verbose output (logical)
    %                .plot    - Generate plots (logical)
    % OUTPUTS:
    %   output     - Structure containing results
    %                .result1 - Description [units]
    %                .result2 - Description [units]
    % EXAMPLE:
    %   opts = struct('verbose', true, 'plot', false);
    %   result = main_processing_function(data, opts);
    
    % ✅ Validate inputs
    assert(isstruct(input_data), 'Input must be a structure');
    assert(isfield(input_data, 'field1'), 'Missing required field: field1');
    
    % Set default options
    if nargin < 2 || isempty(options)
        options = struct();
    end
    if ~isfield(options, 'verbose')
        options.verbose = false;
    end
    
    % 🔄 Process data
    if options.verbose
        fprintf('Processing started...\n');
    end
    
    % Main processing logic here
    intermediate_result = process_step_one(input_data);
    final_result = process_step_two(intermediate_result);
    
    % 📊 Prepare output
    output = struct();
    output.result1 = final_result.value1;
    output.result2 = final_result.value2;
    
    if options.verbose
        fprintf('Processing completed successfully\n');
    end
end

% ----------------------------------------
% Step 3 – Helper Functions
% ----------------------------------------

function result = process_step_one(data)
    % PURPOSE: First processing step
    % INPUTS:
    %   data - Input data structure
    % OUTPUTS:
    %   result - Intermediate results
    
    % Processing implementation
    result = data;  % Placeholder
end

function result = process_step_two(data)
    % PURPOSE: Second processing step  
    % INPUTS:
    %   data - Intermediate data
    % OUTPUTS:
    %   result - Final results
    
    % Processing implementation
    result.value1 = 1;  % Placeholder
    result.value2 = 2;  % Placeholder
end

% ----------------------------------------
% Step 4 – Script Execution
% ----------------------------------------

% Only run if called directly (not as function)
if ~nargout
    % Example usage
    fprintf('Running example...\n');
    
    % Create sample input
    sample_input = struct('field1', 100, 'field2', 200);
    opts = struct('verbose', true, 'plot', true);
    
    % Run main function
    results = main_processing_function(sample_input, opts);
    
    % Display results
    fprintf('Results: result1=%g, result2=%g\n', ...
            results.result1, results.result2);
end