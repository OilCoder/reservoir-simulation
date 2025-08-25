function validation_results = fluid_validation(fluid, G)
% FLUID_VALIDATION - Validate fluid structure and properties
%
% INPUTS:
%   fluid - Fluid structure with relative permeability functions
%   G     - Grid structure
%
% OUTPUTS:
%   validation_results - Structure with validation results
%
% Author: Claude Code AI System
% Date: August 23, 2025

    validation_results = struct();
    validation_results.validation_passed = true;
    validation_results.warnings = {};
    validation_results.errors = {};
    validation_results.tests_performed = {};
    
    % Validate required fields
    field_validation = validate_required_fields(fluid);
    validation_results = merge_validation_results(validation_results, field_validation);
    
    % Validate function handles
    function_validation = validate_function_handles(fluid, G);
    validation_results = merge_validation_results(validation_results, function_validation);
    
    % Validate SCAL parameters
    scal_validation = validate_scal_parameters(fluid, G);
    validation_results = merge_validation_results(validation_results, scal_validation);
    
    % Print validation summary
    print_validation_summary(validation_results);
end

function validation_results = validate_required_fields(fluid)
% Validate that fluid has required fields
    validation_results = struct();
    validation_results.validation_passed = true;
    validation_results.warnings = {};
    validation_results.errors = {};
    validation_results.tests_performed = {'Required Fields Check'};
    
    % Required fields for basic fluid structure
    required_fields = {'phases', 'n'};
    
    for i = 1:length(required_fields)
        field = required_fields{i};
        if ~isfield(fluid, field)
            validation_results.errors{end+1} = sprintf('Missing required field: %s', field);
            validation_results.validation_passed = false;
        end
    end
    
    % Check relative permeability function fields
    relperm_fields = {'krW', 'krOW', 'krG', 'krO'};
    missing_relperm = 0;
    
    for i = 1:length(relperm_fields)
        field = relperm_fields{i};
        if ~isfield(fluid, field)
            missing_relperm = missing_relperm + 1;
        end
    end
    
    if missing_relperm > 0
        validation_results.warnings{end+1} = sprintf('Missing %d relative permeability functions', missing_relperm);
    end
end

function validation_results = validate_function_handles(fluid, G)
% Validate that relative permeability functions work correctly
    validation_results = struct();
    validation_results.validation_passed = true;
    validation_results.warnings = {};
    validation_results.errors = {};
    validation_results.tests_performed = {'Function Handle Tests'};
    
    % Test saturation ranges
    sw_test = [0.0, 0.2, 0.5, 0.8, 1.0];
    sg_test = [0.0, 0.1, 0.3, 0.6, 1.0];
    
    % Test water relative permeability function
    if isfield(fluid, 'krW') && isa(fluid.krW, 'function_handle')
        try
            kr_values = fluid.krW(sw_test);
            if any(isnan(kr_values)) || any(isinf(kr_values))
                validation_results.errors{end+1} = 'Water relperm function returns NaN or Inf values';
                validation_results.validation_passed = false;
            end
            if any(kr_values < 0) || any(kr_values > 1)
                validation_results.warnings{end+1} = 'Water relperm values outside [0,1] range';
            end
        catch ME
            validation_results.errors{end+1} = sprintf('Water relperm function error: %s', ME.message);
            validation_results.validation_passed = false;
        end
    end
    
    % Test oil relative permeability function
    if isfield(fluid, 'krOW') && isa(fluid.krOW, 'function_handle')
        try
            kr_values = fluid.krOW(sw_test);
            if any(isnan(kr_values)) || any(isinf(kr_values))
                validation_results.errors{end+1} = 'Oil relperm function returns NaN or Inf values';
                validation_results.validation_passed = false;
            end
            if any(kr_values < 0) || any(kr_values > 1)
                validation_results.warnings{end+1} = 'Oil relperm values outside [0,1] range';
            end
        catch ME
            validation_results.errors{end+1} = sprintf('Oil relperm function error: %s', ME.message);
            validation_results.validation_passed = false;
        end
    end
    
    % Test gas relative permeability function
    if isfield(fluid, 'krG') && isa(fluid.krG, 'function_handle')
        try
            kr_values = fluid.krG(sg_test);
            if any(isnan(kr_values)) || any(isinf(kr_values))
                validation_results.errors{end+1} = 'Gas relperm function returns NaN or Inf values';
                validation_results.validation_passed = false;
            end
            if any(kr_values < 0) || any(kr_values > 1)
                validation_results.warnings{end+1} = 'Gas relperm values outside [0,1] range';
            end
        catch ME
            validation_results.errors{end+1} = sprintf('Gas relperm function error: %s', ME.message);
            validation_results.validation_passed = false;
        end
    end
end

function validation_results = validate_scal_parameters(fluid, G)
% Validate SCAL parameters and consistency
    validation_results = struct();
    validation_results.validation_passed = true;
    validation_results.warnings = {};
    validation_results.errors = {};
    validation_results.tests_performed = {'SCAL Parameter Validation'};
    
    % Check Corey exponents
    if isfield(fluid, 'n')
        if length(fluid.n) ~= 3
            validation_results.errors{end+1} = 'Corey exponents must be a 3-element vector [nw, no, ng]';
            validation_results.validation_passed = false;
        elseif any(fluid.n <= 0) || any(fluid.n > 10)
            validation_results.warnings{end+1} = 'Corey exponents outside typical range [0.1, 5]';
        end
    end
    
    % Check density values
    if isfield(fluid, 'rhoS')
        if length(fluid.rhoS) ~= 3
            validation_results.errors{end+1} = 'Surface densities must be a 3-element vector [rho_w, rho_o, rho_g]';
            validation_results.validation_passed = false;
        elseif any(fluid.rhoS <= 0)
            validation_results.errors{end+1} = 'Surface densities must be positive';
            validation_results.validation_passed = false;
        end
    end
    
    % Check viscosity values
    if isfield(fluid, 'muS')
        if length(fluid.muS) ~= 3
            validation_results.errors{end+1} = 'Surface viscosities must be a 3-element vector [mu_w, mu_o, mu_g]';
            validation_results.validation_passed = false;
        elseif any(fluid.muS <= 0)
            validation_results.errors{end+1} = 'Surface viscosities must be positive';
            validation_results.validation_passed = false;
        end
    end
    
    % Check grid compatibility
    if isfield(fluid, 'cells') && length(fluid.cells) ~= G.cells.num
        validation_results.warnings{end+1} = sprintf('Fluid cell data length (%d) does not match grid cells (%d)', ...
            length(fluid.cells), G.cells.num);
    end
end

function combined_results = merge_validation_results(results1, results2)
% Merge validation results from different tests
    combined_results = results1;
    combined_results.validation_passed = results1.validation_passed && results2.validation_passed;
    combined_results.warnings = [results1.warnings, results2.warnings];
    combined_results.errors = [results1.errors, results2.errors];
    combined_results.tests_performed = [results1.tests_performed, results2.tests_performed];
end

function print_validation_summary(validation_results)
% Print validation summary
    fprintf('\n=== FLUID VALIDATION SUMMARY ===\n');
    fprintf('Tests performed: %d\n', length(validation_results.tests_performed));
    for i = 1:length(validation_results.tests_performed)
        fprintf('  - %s\n', validation_results.tests_performed{i});
    end
    
    fprintf('Warnings: %d\n', length(validation_results.warnings));
    fprintf('Errors: %d\n', length(validation_results.errors));
    
    if validation_results.validation_passed
        fprintf('Status: PASSED\n');
    else
        fprintf('Status: FAILED\n');
        fprintf('\nErrors:\n');
        for i = 1:length(validation_results.errors)
            fprintf('  - %s\n', validation_results.errors{i});
        end
    end
    
    if ~isempty(validation_results.warnings)
        fprintf('\nWarnings:\n');
        for i = 1:length(validation_results.warnings)
            fprintf('  - %s\n', validation_results.warnings{i});
        end
    end
    
    fprintf('===============================\n');
end