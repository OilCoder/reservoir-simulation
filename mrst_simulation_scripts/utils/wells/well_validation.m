function validation_results = well_validation(wells_results, G)
% WELL_VALIDATION - Validate well locations and properties
%
% INPUTS:
%   wells_results - Structure containing all wells
%   G            - Grid structure
%
% OUTPUTS:
%   validation_results - Structure with validation results
%
% Author: Claude Code AI System
% Date: August 23, 2025

    validation_results = struct();
    validation_results.total_wells = 0;
    validation_results.valid_wells = 0;
    validation_results.invalid_wells = {};
    validation_results.warnings = {};
    validation_results.errors = {};
    
    % Validate producer wells
    if isfield(wells_results, 'producer_wells') && ~isempty(wells_results.producer_wells)
        producer_validation = validate_well_group(wells_results.producer_wells, 'producer', G);
        validation_results = merge_validation_results(validation_results, producer_validation);
    end
    
    % Validate injector wells
    if isfield(wells_results, 'injector_wells') && ~isempty(wells_results.injector_wells)
        injector_validation = validate_well_group(wells_results.injector_wells, 'injector', G);
        validation_results = merge_validation_results(validation_results, injector_validation);
    end
    
    % Overall validation status
    validation_results.validation_passed = isempty(validation_results.errors);
    validation_results.has_warnings = ~isempty(validation_results.warnings);
    
    % Print validation summary
    print_validation_summary(validation_results);
end

function group_validation = validate_well_group(wells, well_type, G)
% Validate a group of wells (producers or injectors)
    group_validation = struct();
    group_validation.total_wells = length(wells);
    group_validation.valid_wells = 0;
    group_validation.invalid_wells = {};
    group_validation.warnings = {};
    group_validation.errors = {};
    
    for i = 1:length(wells)
        well = wells{i};
        well_validation = validate_single_well(well, G);
        
        if well_validation.is_valid
            group_validation.valid_wells = group_validation.valid_wells + 1;
        else
            group_validation.invalid_wells{end+1} = well.name;
        end
        
        % Collect warnings and errors
        for j = 1:length(well_validation.warnings)
            group_validation.warnings{end+1} = sprintf('[%s] %s', well.name, well_validation.warnings{j});
        end
        
        for j = 1:length(well_validation.errors)
            group_validation.errors{end+1} = sprintf('[%s] %s', well.name, well_validation.errors{j});
        end
    end
end

function well_validation = validate_single_well(well, G)
% Validate a single well
    well_validation = struct();
    well_validation.is_valid = true;
    well_validation.warnings = {};
    well_validation.errors = {};
    
    % Check required fields
    required_fields = {'name', 'type', 'i', 'j', 'k', 'cells'};
    for i = 1:length(required_fields)
        field = required_fields{i};
        if ~isfield(well, field) || isempty(well.(field))
            well_validation.errors{end+1} = sprintf('Missing required field: %s', field);
            well_validation.is_valid = false;
        end
    end
    
    if ~well_validation.is_valid
        return; % Skip further validation if basic fields are missing
    end
    
    % Check grid location bounds
    if well.i < 1 || well.i > G.cartDims(1)
        well_validation.errors{end+1} = sprintf('i-coordinate out of bounds: %d (max: %d)', well.i, G.cartDims(1));
        well_validation.is_valid = false;
    end
    
    if well.j < 1 || well.j > G.cartDims(2)
        well_validation.errors{end+1} = sprintf('j-coordinate out of bounds: %d (max: %d)', well.j, G.cartDims(2));
        well_validation.is_valid = false;
    end
    
    if well.k < 1 || well.k > G.cartDims(3)
        well_validation.errors{end+1} = sprintf('k-coordinate out of bounds: %d (max: %d)', well.k, G.cartDims(3));
        well_validation.is_valid = false;
    end
    
    % Check well index
    if isfield(well, 'WI') && well.WI <= 0
        well_validation.warnings{end+1} = sprintf('Low or zero well index: %.2f', well.WI);
    end
    
    % Check producer-specific properties
    if strcmp(well.type, 'producer')
        if isfield(well, 'production_rate') && well.production_rate <= 0
            well_validation.warnings{end+1} = 'Non-positive production rate';
        end
        
        if isfield(well, 'bhp_limit') && well.bhp_limit <= 0
            well_validation.errors{end+1} = 'Invalid BHP limit (must be positive)';
            well_validation.is_valid = false;
        end
    end
    
    % Check injector-specific properties
    if strcmp(well.type, 'injector')
        if isfield(well, 'injection_rate') && well.injection_rate <= 0
            well_validation.warnings{end+1} = 'Non-positive injection rate';
        end
        
        if isfield(well, 'bhp_max') && well.bhp_max <= 0
            well_validation.errors{end+1} = 'Invalid maximum BHP (must be positive)';
            well_validation.is_valid = false;
        end
    end
end

function combined_results = merge_validation_results(results1, results2)
% Merge validation results from two groups
    combined_results = results1;
    combined_results.total_wells = results1.total_wells + results2.total_wells;
    combined_results.valid_wells = results1.valid_wells + results2.valid_wells;
    combined_results.invalid_wells = [results1.invalid_wells, results2.invalid_wells];
    combined_results.warnings = [results1.warnings, results2.warnings];
    combined_results.errors = [results1.errors, results2.errors];
end

function print_validation_summary(validation_results)
% Print validation summary
    fprintf('\n=== WELL VALIDATION SUMMARY ===\n');
    fprintf('Total wells: %d\n', validation_results.total_wells);
    fprintf('Valid wells: %d\n', validation_results.valid_wells);
    fprintf('Invalid wells: %d\n', length(validation_results.invalid_wells));
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
    
    if validation_results.has_warnings
        fprintf('\nWarnings:\n');
        for i = 1:length(validation_results.warnings)
            fprintf('  - %s\n', validation_results.warnings{i});
        end
    end
    
    fprintf('==============================\n');
end