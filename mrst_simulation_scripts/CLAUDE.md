# Octave/MRST Simulation Scripts Guidelines

This directory contains Octave scripts for MRST-based reservoir simulations.

## File Naming
All files must follow: `sNN[x]_<verb>_<noun>.m`
- Examples: `s01_setup_field.m`, `s02_run_simulation.m`, `s03_export_results.m`

## Script Structure Template
```matlab
% Script purpose description
% Requires: MRST
% Author: [Name]
% Date: [Date]

% ----------------------------------------
% Step 1 – Initialize MRST
% ----------------------------------------

% Substep 1.1 – Setup environment ______________________
clear all; close all;
mrstModule add module1 module2;

% Substep 1.2 – Define parameters ______________________
% Grid dimensions
nx = 20; ny = 20; nz = 5;

% ----------------------------------------
% Step 2 – Build Model
% ----------------------------------------

function [result] = function_name(input_param)
    % PURPOSE: Brief description of function purpose
    % INPUTS:
    %   input_param - Description of parameter
    % OUTPUTS:
    %   result - Description of output
    % EXAMPLE:
    %   result = function_name(data);
    
    % ✅ Validate inputs
    assert(~isempty(input_param), 'Input cannot be empty');
    
    % 🔄 Process data
    % [Processing logic here]
    
    % 📊 Return results
    result = processed_data;
end
```

## MRST-Specific Guidelines
1. Always include `% Requires: MRST` at top
2. Use MRST conventions for variable names
3. Document physical units in comments
4. Include usage examples in function headers
5. Use fprintf() for simulation progress only
6. English comments only