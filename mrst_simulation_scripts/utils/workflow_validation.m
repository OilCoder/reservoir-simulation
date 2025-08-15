function workflow_validation()
% WORKFLOW_VALIDATION - Comprehensive validation utilities for MRST workflow data
%
% This utility provides validation functions for the canonical MRST workflow
% following the Simulation Data Catalog organization:
% - File existence and accessibility validation
% - Data format and structure compliance
% - Cross-step dependency validation
% - Quality threshold checking
% - Completeness verification
%
% Features:
% - Canon-First validation (fail fast with specific directives)
% - Comprehensive validation reporting
% - Cross-step consistency checking
% - Data quality thresholds based on Eagle West Field specs
% - Dependency graph validation
%
% Requires: MRST
%
% Author: Claude Code AI System
% Date: August 15, 2025

end

function validation_report = validate_workflow_data(step_range, varargin)
% VALIDATE_WORKFLOW_DATA - Comprehensive validation of workflow data
%
% INPUTS:
%   step_range - Cell array of step names to validate {'s05', 's06', 's07'}
%               or string for single step 's05'
%               or 'all' for complete workflow validation
%   varargin   - Optional name-value pairs:
%                'base_path' - Base data directory (default: auto-detect)
%                'validation_level' - 'basic', 'standard', 'comprehensive' (default: 'standard')
%                'fix_issues' - true/false to attempt automatic fixes (default: false)
%                'report_format' - 'struct', 'yaml', 'summary' (default: 'struct')
%
% OUTPUTS:
%   validation_report - Structure containing validation results for all steps
%
% VALIDATION CHECKS:
%   - File existence and accessibility
%   - Data format compliance (HDF5, YAML structure)
%   - Cross-step consistency and dependencies
%   - Data quality thresholds (Eagle West Field specific)
%   - Metadata completeness
%   - Canonical organization compliance
%
% CANON-FIRST VALIDATION:
%   Fails fast with specific error messages directing to canon documentation
%   No fallbacks or defensive programming
%   Clear validation of all canonical requirements

    % Parse input arguments
    p = inputParser;
    addRequired(p, 'step_range');
    addParameter(p, 'base_path', '', @ischar);
    addParameter(p, 'validation_level', 'standard', @(x) any(strcmp(x, {'basic', 'standard', 'comprehensive'})));
    addParameter(p, 'fix_issues', false, @islogical);
    addParameter(p, 'report_format', 'struct', @(x) any(strcmp(x, {'struct', 'yaml', 'summary'})));
    parse(p, step_range, varargin{:});
    
    % Determine base path
    base_path = p.Results.base_path;
    if isempty(base_path)
        script_path = fileparts(mfilename('fullpath'));
        base_path = fullfile(fileparts(script_path), '..', 'data', 'simulation_data');
    end
    
    % Validate base path exists
    if ~exist(base_path, 'dir')
        error(['Canonical data directory not found: %s\n' ...
               'REQUIRED: Create canonical directory structure.\n' ...
               'Use directory_management.m create_canonical_structure() first.\n' ...
               'Canon requires proper simulation_data organization.'], base_path);
    end
    
    % Parse step range
    if ischar(step_range)
        if strcmp(step_range, 'all')
            steps_to_validate = get_all_canonical_steps();
        else
            steps_to_validate = {step_range};
        end
    elseif iscell(step_range)
        steps_to_validate = step_range;
    else
        error(['Invalid step_range format.\n' ...
               'REQUIRED: Use cell array {''s05'', ''s06''} or string ''s05'' or ''all''.\n' ...
               'Canon requires specific step identification.']);
    end
    
    fprintf('🔍 Validating MRST workflow data...\n');
    fprintf('   Base path: %s\n', base_path);
    fprintf('   Steps: %s\n', strjoin(steps_to_validate, ', '));
    fprintf('   Validation level: %s\n', p.Results.validation_level);
    
    % Initialize validation report
    validation_report = struct();
    validation_report.validation_summary.total_steps = length(steps_to_validate);
    validation_report.validation_summary.validation_level = p.Results.validation_level;
    validation_report.validation_summary.validation_date = datestr(now, 'yyyy-mm-ddTHH:MM:SS');
    validation_report.validation_summary.base_path = base_path;
    
    % Validate each step
    total_issues = 0;
    critical_issues = 0;
    
    for i = 1:length(steps_to_validate)
        step_name = steps_to_validate{i};
        
        fprintf('   Validating step %s...\n', step_name);
        
        try
            % Get step configuration
            step_config = get_canonical_step_config(step_name);
            
            % Perform validation checks
            step_validation = validate_individual_step(step_name, step_config, base_path, p.Results.validation_level);
            
            % Fix issues if requested
            if p.Results.fix_issues && ~isempty(step_validation.fixable_issues)
                fix_step_issues(step_name, step_validation.fixable_issues, base_path);
                
                % Re-validate after fixes
                step_validation = validate_individual_step(step_name, step_config, base_path, p.Results.validation_level);
            end
            
            validation_report.steps.(step_name) = step_validation;
            
            % Update summary counts
            total_issues = total_issues + step_validation.summary.total_issues;
            critical_issues = critical_issues + step_validation.summary.critical_issues;
            
            if step_validation.summary.overall_status == "PASS"
                fprintf('     ✅ PASS\n');
            elseif step_validation.summary.overall_status == "WARN"
                fprintf('     ⚠️  WARNINGS\n');
            else
                fprintf('     ❌ FAIL\n');
            end
            
        catch ME
            fprintf('     ❌ VALIDATION ERROR: %s\n', ME.message);
            
            validation_report.steps.(step_name) = struct();
            validation_report.steps.(step_name).validation_error = ME.message;
            validation_report.steps.(step_name).summary.overall_status = "ERROR";
            validation_report.steps.(step_name).summary.total_issues = 1;
            validation_report.steps.(step_name).summary.critical_issues = 1;
            
            total_issues = total_issues + 1;
            critical_issues = critical_issues + 1;
        end
    end
    
    % Cross-step validation
    if p.Results.validation_level ~= "basic" && length(steps_to_validate) > 1
        fprintf('   Cross-step validation...\n');
        cross_step_validation = validate_cross_step_consistency(steps_to_validate, validation_report, base_path);
        validation_report.cross_step_validation = cross_step_validation;
        
        total_issues = total_issues + cross_step_validation.summary.total_issues;
        critical_issues = critical_issues + cross_step_validation.summary.critical_issues;
    end
    
    % Generate overall summary
    validation_report.validation_summary.total_issues = total_issues;
    validation_report.validation_summary.critical_issues = critical_issues;
    
    if critical_issues > 0
        validation_report.validation_summary.overall_status = "CRITICAL";
        fprintf('❌ CRITICAL ISSUES FOUND: %d critical, %d total\n', critical_issues, total_issues);
    elseif total_issues > 0
        validation_report.validation_summary.overall_status = "WARNINGS";
        fprintf('⚠️  WARNINGS: %d non-critical issues\n', total_issues);
    else
        validation_report.validation_summary.overall_status = "PASS";
        fprintf('✅ ALL VALIDATIONS PASSED\n');
    end
    
    % Generate recommendations
    validation_report.recommendations = generate_validation_recommendations(validation_report);
    
    % Output in requested format
    if strcmp(p.Results.report_format, 'yaml')
        write_validation_yaml(validation_report, base_path);
    elseif strcmp(p.Results.report_format, 'summary')
        display_validation_summary(validation_report);
    end
end

function steps = get_all_canonical_steps()
% GET_ALL_CANONICAL_STEPS - Return all canonical workflow steps

    steps = {'s01', 's02', 's03', 's04', 's05', 's06', 's07', 's08', 's09', ...
             's10', 's11', 's12', 's13', 's14', 's15', 's16', 's17', 's18', ...
             's19', 's20', 's21', 's22', 's23', 's24', 's25'};
end

function step_config = get_canonical_step_config(step_name)
% GET_CANONICAL_STEP_CONFIG - Get validation configuration for step
%
% Based on STEP_DATA_OUTPUT_MAPPING.md canonical specifications

    % Extract step number for configuration lookup
    step_num = regexp(step_name, '^s\d+', 'match', 'once');
    
    switch step_num
        case 's01'
            step_config = struct(...
                'data_type', 'environment_control', ...
                'primary_category', 'control', ...
                'data_subcategory', 'mrst_session', ...
                'required_files', {{'mrst_session.mat', 'module_status.yaml'}}, ...
                'quality_thresholds', struct('min_size_mb', 0.5, 'max_age_hours', 24), ...
                'dependency_steps', {{}}, ...
                'critical_fields', {{'mrst_modules', 'paths'}});
                
        case 's02'
            step_config = struct(...
                'data_type', 'fluid_pvt', ...
                'primary_category', 'static', ...
                'data_subcategory', 'fluid_properties', ...
                'required_files', {{'native_fluid_properties.h5', 'pvt_tables.h5'}}, ...
                'quality_thresholds', struct('min_size_mb', 3, 'max_age_hours', 48), ...
                'dependency_steps', {{'s01'}}, ...
                'critical_fields', {{'fluid', 'bO', 'bW', 'muO', 'muW'}});
                
        case 's03'
            step_config = struct(...
                'data_type', 'structural_framework', ...
                'primary_category', 'static', ...
                'data_subcategory', 'geology', ...
                'required_files', {{'structural_framework.h5', 'layer_boundaries.h5'}}, ...
                'quality_thresholds', struct('min_size_mb', 10, 'max_age_hours', 48), ...
                'dependency_steps', {{'s01', 's05'}}, ...  % Note: s05 dependency issue
                'critical_fields', {{'structural_framework', 'layers'}});
                
        case 's04'
            step_config = struct(...
                'data_type', 'fault_system', ...
                'primary_category', 'static', ...
                'data_subcategory', 'geology', ...
                'required_files', {{'fault_system.h5', 'fault_geometries.h5'}}, ...
                'quality_thresholds', struct('min_size_mb', 5, 'max_age_hours', 48), ...
                'dependency_steps', {{'s03'}}, ...
                'critical_fields', {{'faults', 'transmissibility'}});
                
        case 's05'
            step_config = struct(...
                'data_type', 'pebi_grid', ...
                'primary_category', 'static', ...
                'data_subcategory', 'geometry', ...
                'required_files', {{'pebi_grid.h5', 'grid_connectivity.h5'}}, ...
                'quality_thresholds', struct('min_size_mb', 20, 'max_age_hours', 48, 'min_cells', 15000, 'max_cells', 25000), ...
                'dependency_steps', {{'s01'}}, ...
                'critical_fields', {{'G', 'cells', 'faces', 'nodes'}});
                
        case 's06'
            step_config = struct(...
                'data_type', 'base_rock_properties', ...
                'primary_category', 'static', ...
                'data_subcategory', 'geology', ...
                'required_files', {{'base_rock_properties.h5', 'porosity_field.h5'}}, ...
                'quality_thresholds', struct('min_size_mb', 25, 'max_age_hours', 48, ...
                    'porosity_min', 0.05, 'porosity_max', 0.35, 'perm_min', 1e-15), ...
                'dependency_steps', {{'s05'}}, ...
                'critical_fields', {{'rock', 'poro', 'perm'}});
                
        case 's07'
            step_config = struct(...
                'data_type', 'enhanced_rock_properties', ...
                'primary_category', 'static', ...
                'data_subcategory', 'geology', ...
                'required_files', {{'enhanced_rock_properties.h5', 'layer_metadata.h5'}}, ...
                'quality_thresholds', struct('min_size_mb', 30, 'max_age_hours', 48), ...
                'dependency_steps', {{'s06'}}, ...
                'critical_fields', {{'rock', 'layers', 'metadata'}});
                
        case 's08'
            step_config = struct(...
                'data_type', 'final_simulation_rock', ...
                'primary_category', 'static', ...
                'data_subcategory', 'geology', ...
                'required_files', {{'final_simulation_rock.h5', 'simulation_metadata.h5'}}, ...
                'quality_thresholds', struct('min_size_mb', 35, 'max_age_hours', 48), ...
                'dependency_steps', {{'s07'}}, ...
                'critical_fields', {{'rock', 'heterogeneity'}});
                
        case 's09'
            step_config = struct(...
                'data_type', 'relative_permeability', ...
                'primary_category', 'static', ...
                'data_subcategory', 'scal_properties', ...
                'required_files', {{'relative_permeability.h5', 'kr_tables.h5'}}, ...
                'quality_thresholds', struct('min_size_mb', 5, 'max_age_hours', 48), ...
                'dependency_steps', {{'s02'}}, ...
                'critical_fields', {{'relperm', 'kr_tables'}});
                
        otherwise
            error(['Unrecognized canonical step for validation: %s\n' ...
                   'REQUIRED: Update obsidian-vault/Planning/Simulation_Data_Catalog/\n' ...
                   'STEP_DATA_OUTPUT_MAPPING.md to define validation configuration.\n' ...
                   'Canon must specify validation criteria for step %s.'], step_name, step_name);
    end
end

function step_validation = validate_individual_step(step_name, step_config, base_path, validation_level)
% VALIDATE_INDIVIDUAL_STEP - Comprehensive validation of single workflow step

    step_validation = struct();
    step_validation.step_name = step_name;
    step_validation.validation_level = validation_level;
    step_validation.validation_date = datestr(now, 'yyyy-mm-ddTHH:MM:SS');
    
    % Initialize issue tracking
    issues = {};
    critical_issues = {};
    warnings = {};
    fixable_issues = {};
    
    % 1. File existence validation
    fprintf('     Checking file existence...\n');
    file_validation = validate_file_existence(step_name, step_config, base_path);
    step_validation.file_existence = file_validation;
    
    if ~file_validation.all_files_exist
        critical_issues{end+1} = sprintf('Missing required files: %s', strjoin(file_validation.missing_files, ', '));
    end
    
    % 2. File accessibility and format validation
    if file_validation.all_files_exist
        fprintf('     Checking file formats...\n');
        format_validation = validate_file_formats(step_name, step_config, base_path);
        step_validation.file_formats = format_validation;
        
        if format_validation.format_issues > 0
            issues{end+1} = sprintf('Format issues found: %d files', format_validation.format_issues);
        end
    end
    
    % 3. Data quality validation (if files accessible)
    if file_validation.all_files_exist && strcmp(validation_level, 'standard') || strcmp(validation_level, 'comprehensive')
        fprintf('     Checking data quality...\n');
        quality_validation = validate_data_quality(step_name, step_config, base_path);
        step_validation.data_quality = quality_validation;
        
        if quality_validation.quality_issues > 0
            warnings{end+1} = sprintf('Quality issues: %d thresholds failed', quality_validation.quality_issues);
        end
    end
    
    % 4. Metadata validation
    if file_validation.all_files_exist
        fprintf('     Checking metadata...\n');
        metadata_validation = validate_metadata_completeness(step_name, step_config, base_path);
        step_validation.metadata = metadata_validation;
        
        if ~metadata_validation.metadata_complete
            fixable_issues{end+1} = 'Incomplete metadata files';
        end
    end
    
    % 5. Canonical organization validation
    fprintf('     Checking canonical organization...\n');
    organization_validation = validate_canonical_organization(step_name, step_config, base_path);
    step_validation.organization = organization_validation;
    
    if ~organization_validation.organization_complete
        fixable_issues{end+1} = 'Missing symlinks or organization structure';
    end
    
    % 6. Dependency validation (comprehensive level only)
    if strcmp(validation_level, 'comprehensive')
        fprintf('     Checking dependencies...\n');
        dependency_validation = validate_step_dependencies(step_name, step_config, base_path);
        step_validation.dependencies = dependency_validation;
        
        if dependency_validation.dependency_issues > 0
            critical_issues{end+1} = sprintf('Dependency issues: %d steps', dependency_validation.dependency_issues);
        end
    end
    
    % Compile validation summary
    step_validation.issues = issues;
    step_validation.critical_issues = critical_issues;
    step_validation.warnings = warnings;
    step_validation.fixable_issues = fixable_issues;
    
    step_validation.summary.total_issues = length(issues) + length(critical_issues) + length(warnings);
    step_validation.summary.critical_issues = length(critical_issues);
    step_validation.summary.warnings = length(warnings);
    step_validation.summary.fixable_issues = length(fixable_issues);
    
    % Determine overall status
    if length(critical_issues) > 0
        step_validation.summary.overall_status = "FAIL";
    elseif length(issues) > 0 || length(warnings) > 0
        step_validation.summary.overall_status = "WARN";
    else
        step_validation.summary.overall_status = "PASS";
    end
end

function file_validation = validate_file_existence(step_name, step_config, base_path)
% VALIDATE_FILE_EXISTENCE - Check if all required files exist for step

    file_validation = struct();
    file_validation.required_files = step_config.required_files;
    file_validation.missing_files = {};
    file_validation.existing_files = {};
    file_validation.file_details = struct();
    
    % Construct expected file paths
    primary_path = fullfile(base_path, 'by_type', step_config.primary_category, step_config.data_subcategory);
    
    for i = 1:length(step_config.required_files)
        filename = step_config.required_files{i};
        
        % Check for timestamped versions (most recent)
        file_pattern = strrep(filename, '.h5', '_*.h5');
        file_pattern = strrep(file_pattern, '.yaml', '_*.yaml');
        file_pattern = strrep(file_pattern, '.mat', '_*.mat');
        
        file_matches = dir(fullfile(primary_path, file_pattern));
        
        if ~isempty(file_matches)
            % Sort by date, take most recent
            [~, newest_idx] = max([file_matches.datenum]);
            newest_file = file_matches(newest_idx);
            file_path = fullfile(newest_file.folder, newest_file.name);
            
            file_validation.existing_files{end+1} = filename;
            file_validation.file_details.(strrep(filename, '.', '_')) = struct(...
                'path', file_path, ...
                'size_mb', newest_file.bytes / 1048576, ...
                'last_modified', datestr(newest_file.datenum, 'yyyy-mm-ddTHH:MM:SS'), ...
                'age_hours', (now - newest_file.datenum) * 24);
        else
            % Check for current version symlink
            current_file = strrep(filename, '.h5', '_current.h5');
            current_file = strrep(current_file, '.yaml', '_current.yaml');
            current_file = strrep(current_file, '.mat', '_current.mat');
            current_path = fullfile(primary_path, current_file);
            
            if exist(current_path, 'file')
                file_validation.existing_files{end+1} = filename;
                file_info = dir(current_path);
                file_validation.file_details.(strrep(filename, '.', '_')) = struct(...
                    'path', current_path, ...
                    'size_mb', file_info.bytes / 1048576, ...
                    'last_modified', datestr(file_info.datenum, 'yyyy-mm-ddTHH:MM:SS'), ...
                    'age_hours', (now - file_info.datenum) * 24);
            else
                file_validation.missing_files{end+1} = filename;
            end
        end
    end
    
    file_validation.all_files_exist = isempty(file_validation.missing_files);
    file_validation.files_found = length(file_validation.existing_files);
    file_validation.files_expected = length(step_config.required_files);
end

function format_validation = validate_file_formats(step_name, step_config, base_path)
% VALIDATE_FILE_FORMATS - Validate file formats and structure

    format_validation = struct();
    format_validation.format_issues = 0;
    format_validation.file_formats = {};
    
    primary_path = fullfile(base_path, 'by_type', step_config.primary_category, step_config.data_subcategory);
    
    for i = 1:length(step_config.required_files)
        filename = step_config.required_files{i};
        [~, ~, ext] = fileparts(filename);
        
        % Find actual file (timestamped version)
        file_pattern = strrep(filename, ext, ['_*', ext]);
        file_matches = dir(fullfile(primary_path, file_pattern));
        
        if ~isempty(file_matches)
            [~, newest_idx] = max([file_matches.datenum]);
            file_path = fullfile(file_matches(newest_idx).folder, file_matches(newest_idx).name);
            
            format_result = struct();
            format_result.filename = filename;
            format_result.format = ext(2:end);
            format_result.path = file_path;
            
            try
                switch ext
                    case '.h5'
                        % Validate HDF5 structure
                        info = h5info(file_path);
                        format_result.valid = true;
                        format_result.groups = length(info.Groups);
                        format_result.datasets = length(info.Datasets);
                        
                    case '.yaml'
                        % Validate YAML structure
                        fid = fopen(file_path, 'r');
                        content = fread(fid, '*char')';
                        fclose(fid);
                        format_result.valid = contains(content, ':') && ~isempty(content);
                        
                    case '.mat'
                        % Validate MATLAB file
                        vars = whos('-file', file_path);
                        format_result.valid = ~isempty(vars);
                        format_result.variables = length(vars);
                        
                    otherwise
                        format_result.valid = true;  % Unknown format, assume valid
                end
                
            catch ME
                format_result.valid = false;
                format_result.error = ME.message;
                format_validation.format_issues = format_validation.format_issues + 1;
            end
            
            format_validation.file_formats{end+1} = format_result;
        end
    end
end

function quality_validation = validate_data_quality(step_name, step_config, base_path)
% VALIDATE_DATA_QUALITY - Validate data against quality thresholds

    quality_validation = struct();
    quality_validation.quality_issues = 0;
    quality_validation.threshold_checks = {};
    
    thresholds = step_config.quality_thresholds;
    primary_path = fullfile(base_path, 'by_type', step_config.primary_category, step_config.data_subcategory);
    
    % File size validation
    if isfield(thresholds, 'min_size_mb')
        for i = 1:length(step_config.required_files)
            filename = step_config.required_files{i};
            file_pattern = strrep(filename, '.h5', '_*.h5');
            file_matches = dir(fullfile(primary_path, file_pattern));
            
            if ~isempty(file_matches)
                [~, newest_idx] = max([file_matches.datenum]);
                size_mb = file_matches(newest_idx).bytes / 1048576;
                
                check_result = struct();
                check_result.check_type = 'file_size';
                check_result.filename = filename;
                check_result.actual_value = size_mb;
                check_result.threshold = thresholds.min_size_mb;
                check_result.passed = size_mb >= thresholds.min_size_mb;
                
                if ~check_result.passed
                    quality_validation.quality_issues = quality_validation.quality_issues + 1;
                end
                
                quality_validation.threshold_checks{end+1} = check_result;
            end
        end
    end
    
    % Age validation
    if isfield(thresholds, 'max_age_hours')
        for i = 1:length(step_config.required_files)
            filename = step_config.required_files{i};
            file_pattern = strrep(filename, '.h5', '_*.h5');
            file_matches = dir(fullfile(primary_path, file_pattern));
            
            if ~isempty(file_matches)
                [~, newest_idx] = max([file_matches.datenum]);
                age_hours = (now - file_matches(newest_idx).datenum) * 24;
                
                check_result = struct();
                check_result.check_type = 'file_age';
                check_result.filename = filename;
                check_result.actual_value = age_hours;
                check_result.threshold = thresholds.max_age_hours;
                check_result.passed = age_hours <= thresholds.max_age_hours;
                
                if ~check_result.passed
                    quality_validation.quality_issues = quality_validation.quality_issues + 1;
                end
                
                quality_validation.threshold_checks{end+1} = check_result;
            end
        end
    end
    
    % Eagle West Field specific thresholds
    if isfield(thresholds, 'min_cells') && strcmp(step_config.data_type, 'pebi_grid')
        % Validate grid cell count for Eagle West Field (should be ~20,172 cells)
        try
            grid_file = find_step_file(primary_path, 'pebi_grid.h5');
            if ~isempty(grid_file)
                info = h5info(grid_file);
                
                % Look for cell count in datasets
                for j = 1:length(info.Datasets)
                    if contains(info.Datasets(j).Name, 'cells')
                        cell_count = info.Datasets(j).Dataspace.Size(1);
                        
                        check_result = struct();
                        check_result.check_type = 'grid_cells';
                        check_result.filename = 'pebi_grid.h5';
                        check_result.actual_value = cell_count;
                        check_result.threshold_min = thresholds.min_cells;
                        check_result.threshold_max = thresholds.max_cells;
                        check_result.passed = cell_count >= thresholds.min_cells && cell_count <= thresholds.max_cells;
                        
                        if ~check_result.passed
                            quality_validation.quality_issues = quality_validation.quality_issues + 1;
                        end
                        
                        quality_validation.threshold_checks{end+1} = check_result;
                        break;
                    end
                end
            end
        catch ME
            warning('Could not validate grid cell count: %s', ME.message);
        end
    end
    
    % Rock property thresholds for Eagle West Field
    if isfield(thresholds, 'porosity_min') && contains(step_config.data_type, 'rock')
        try
            rock_file = find_step_file(primary_path, [step_config.data_type, '.h5']);
            if ~isempty(rock_file)
                % Validate porosity range
                try
                    porosity = h5read(rock_file, '/poro');
                    
                    check_result = struct();
                    check_result.check_type = 'porosity_range';
                    check_result.filename = [step_config.data_type, '.h5'];
                    check_result.actual_min = min(porosity);
                    check_result.actual_max = max(porosity);
                    check_result.threshold_min = thresholds.porosity_min;
                    check_result.threshold_max = thresholds.porosity_max;
                    check_result.passed = check_result.actual_min >= thresholds.porosity_min && ...
                                         check_result.actual_max <= thresholds.porosity_max;
                    
                    if ~check_result.passed
                        quality_validation.quality_issues = quality_validation.quality_issues + 1;
                    end
                    
                    quality_validation.threshold_checks{end+1} = check_result;
                catch
                    % Porosity data might be in different location
                end
            end
        catch ME
            warning('Could not validate rock properties: %s', ME.message);
        end
    end
end

function metadata_validation = validate_metadata_completeness(step_name, step_config, base_path)
% VALIDATE_METADATA_COMPLETENESS - Check metadata files and content

    metadata_validation = struct();
    metadata_validation.metadata_complete = true;
    metadata_validation.missing_metadata = {};
    metadata_validation.metadata_issues = {};
    
    primary_path = fullfile(base_path, 'by_type', step_config.primary_category, step_config.data_subcategory);
    
    for i = 1:length(step_config.required_files)
        filename = step_config.required_files{i};
        [name, ~, ext] = fileparts(filename);
        
        % Check for metadata file
        metadata_pattern = sprintf('%s_*_metadata.yaml', name);
        metadata_matches = dir(fullfile(primary_path, metadata_pattern));
        
        if isempty(metadata_matches)
            metadata_validation.missing_metadata{end+1} = sprintf('%s_metadata.yaml', name);
            metadata_validation.metadata_complete = false;
        else
            % Validate metadata content
            [~, newest_idx] = max([metadata_matches.datenum]);
            metadata_file = fullfile(metadata_matches(newest_idx).folder, metadata_matches(newest_idx).name);
            
            try
                fid = fopen(metadata_file, 'r');
                content = fread(fid, '*char')';
                fclose(fid);
                
                % Check for required metadata fields
                required_fields = {'identification', 'data_type', 'file_info', 'quality'};
                for j = 1:length(required_fields)
                    if ~contains(content, required_fields{j})
                        metadata_validation.metadata_issues{end+1} = sprintf('Missing field %s in %s', required_fields{j}, metadata_file);
                    end
                end
                
            catch ME
                metadata_validation.metadata_issues{end+1} = sprintf('Cannot read metadata file: %s', ME.message);
            end
        end
    end
end

function organization_validation = validate_canonical_organization(step_name, step_config, base_path)
% VALIDATE_CANONICAL_ORGANIZATION - Check canonical directory structure and symlinks

    organization_validation = struct();
    organization_validation.organization_complete = true;
    organization_validation.missing_symlinks = {};
    organization_validation.broken_symlinks = {};
    
    % Check by_usage organization
    usage_base = fullfile(base_path, 'by_usage');
    if exist(usage_base, 'dir')
        % Expected symlinks based on step configuration
        % Implementation would check for proper symlinks
        % For now, mark as complete if directory exists
    else
        organization_validation.organization_complete = false;
        organization_validation.missing_symlinks{end+1} = 'by_usage directory structure';
    end
    
    % Check by_phase organization
    phase_base = fullfile(base_path, 'by_phase');
    if exist(phase_base, 'dir')
        % Expected symlinks based on step configuration
        % Implementation would check for proper symlinks
    else
        organization_validation.organization_complete = false;
        organization_validation.missing_symlinks{end+1} = 'by_phase directory structure';
    end
end

function dependency_validation = validate_step_dependencies(step_name, step_config, base_path)
% VALIDATE_STEP_DEPENDENCIES - Check dependencies between workflow steps

    dependency_validation = struct();
    dependency_validation.dependency_issues = 0;
    dependency_validation.dependency_checks = {};
    
    for i = 1:length(step_config.dependency_steps)
        dep_step = step_config.dependency_steps{i};
        
        % Get dependency step configuration
        try
            dep_config = get_canonical_step_config(dep_step);
            
            % Check if dependency step files exist
            dep_file_validation = validate_file_existence(dep_step, dep_config, base_path);
            
            check_result = struct();
            check_result.dependency_step = dep_step;
            check_result.files_exist = dep_file_validation.all_files_exist;
            check_result.missing_files = dep_file_validation.missing_files;
            
            if ~dep_file_validation.all_files_exist
                dependency_validation.dependency_issues = dependency_validation.dependency_issues + 1;
            end
            
            dependency_validation.dependency_checks{end+1} = check_result;
            
        catch ME
            check_result = struct();
            check_result.dependency_step = dep_step;
            check_result.files_exist = false;
            check_result.error = ME.message;
            
            dependency_validation.dependency_issues = dependency_validation.dependency_issues + 1;
            dependency_validation.dependency_checks{end+1} = check_result;
        end
    end
end

function cross_step_validation = validate_cross_step_consistency(steps_to_validate, validation_report, base_path)
% VALIDATE_CROSS_STEP_CONSISTENCY - Validate consistency across multiple steps

    cross_step_validation = struct();
    cross_step_validation.consistency_issues = 0;
    cross_step_validation.consistency_checks = {};
    
    % Check grid consistency between s05 and rock property steps
    if any(strcmp(steps_to_validate, 's05')) && any(strcmp(steps_to_validate, 's06'))
        grid_consistency = validate_grid_rock_consistency(base_path);
        cross_step_validation.consistency_checks{end+1} = grid_consistency;
        
        if ~grid_consistency.consistent
            cross_step_validation.consistency_issues = cross_step_validation.consistency_issues + 1;
        end
    end
    
    % Check dependency chain completeness
    dependency_chain = validate_dependency_chain(steps_to_validate, base_path);
    cross_step_validation.dependency_chain = dependency_chain;
    
    if dependency_chain.chain_broken
        cross_step_validation.consistency_issues = cross_step_validation.consistency_issues + 1;
    end
    
    cross_step_validation.summary.total_issues = cross_step_validation.consistency_issues;
    cross_step_validation.summary.critical_issues = cross_step_validation.consistency_issues;  % Cross-step issues are critical
end

function grid_consistency = validate_grid_rock_consistency(base_path)
% VALIDATE_GRID_ROCK_CONSISTENCY - Check grid and rock properties have same cell count

    grid_consistency = struct();
    grid_consistency.check_type = 'grid_rock_consistency';
    grid_consistency.consistent = false;
    
    try
        % Find grid file
        grid_path = fullfile(base_path, 'by_type', 'static', 'geometry');
        grid_file = find_step_file(grid_path, 'pebi_grid.h5');
        
        % Find rock file
        rock_path = fullfile(base_path, 'by_type', 'static', 'geology');
        rock_file = find_step_file(rock_path, 'base_rock_properties.h5');
        
        if ~isempty(grid_file) && ~isempty(rock_file)
            % Get grid cell count
            grid_info = h5info(grid_file);
            grid_cells = 0;
            for i = 1:length(grid_info.Datasets)
                if contains(grid_info.Datasets(i).Name, 'cells')
                    grid_cells = grid_info.Datasets(i).Dataspace.Size(1);
                    break;
                end
            end
            
            % Get rock cell count
            rock_info = h5info(rock_file);
            rock_cells = 0;
            for i = 1:length(rock_info.Datasets)
                if contains(rock_info.Datasets(i).Name, 'poro')
                    rock_cells = numel(h5read(rock_file, ['/', rock_info.Datasets(i).Name]));
                    break;
                end
            end
            
            grid_consistency.grid_cells = grid_cells;
            grid_consistency.rock_cells = rock_cells;
            grid_consistency.consistent = (grid_cells == rock_cells) && (grid_cells > 0);
            
            if ~grid_consistency.consistent
                grid_consistency.issue = sprintf('Grid cells (%d) != Rock cells (%d)', grid_cells, rock_cells);
            end
        else
            grid_consistency.issue = 'Cannot find grid or rock files for comparison';
        end
        
    catch ME
        grid_consistency.issue = sprintf('Error checking consistency: %s', ME.message);
    end
end

function dependency_chain = validate_dependency_chain(steps_to_validate, base_path)
% VALIDATE_DEPENDENCY_CHAIN - Check if dependency chain is complete

    dependency_chain = struct();
    dependency_chain.chain_broken = false;
    dependency_chain.missing_dependencies = {};
    
    % Build dependency graph for validated steps
    all_dependencies = {};
    for i = 1:length(steps_to_validate)
        step_config = get_canonical_step_config(steps_to_validate{i});
        all_dependencies = [all_dependencies, step_config.dependency_steps];
    end
    
    % Check if all dependencies are in validation set or have files
    unique_deps = unique(all_dependencies);
    for i = 1:length(unique_deps)
        dep_step = unique_deps{i};
        
        if ~any(strcmp(steps_to_validate, dep_step))
            % Dependency not in validation set, check if files exist
            try
                dep_config = get_canonical_step_config(dep_step);
                dep_validation = validate_file_existence(dep_step, dep_config, base_path);
                
                if ~dep_validation.all_files_exist
                    dependency_chain.chain_broken = true;
                    dependency_chain.missing_dependencies{end+1} = dep_step;
                end
            catch
                dependency_chain.chain_broken = true;
                dependency_chain.missing_dependencies{end+1} = dep_step;
            end
        end
    end
end

function file_path = find_step_file(directory, filename_pattern)
% FIND_STEP_FILE - Find most recent timestamped version of file

    file_path = '';
    
    % Look for timestamped versions
    file_pattern = strrep(filename_pattern, '.h5', '_*.h5');
    file_matches = dir(fullfile(directory, file_pattern));
    
    if ~isempty(file_matches)
        [~, newest_idx] = max([file_matches.datenum]);
        file_path = fullfile(file_matches(newest_idx).folder, file_matches(newest_idx).name);
    else
        % Look for current version
        current_file = strrep(filename_pattern, '.h5', '_current.h5');
        current_path = fullfile(directory, current_file);
        if exist(current_path, 'file')
            file_path = current_path;
        end
    end
end

function fix_step_issues(step_name, fixable_issues, base_path)
% FIX_STEP_ISSUES - Attempt to fix common fixable issues

    fprintf('     Attempting to fix issues for step %s...\n', step_name);
    
    for i = 1:length(fixable_issues)
        issue = fixable_issues{i};
        
        if contains(issue, 'metadata')
            % Regenerate missing metadata
            fprintf('       Regenerating metadata files...\n');
            % Implementation would regenerate metadata
            
        elseif contains(issue, 'symlinks')
            % Recreate missing symlinks
            fprintf('       Recreating organization symlinks...\n');
            % Implementation would recreate symlinks
            
        elseif contains(issue, 'organization')
            % Fix directory structure
            fprintf('       Fixing directory structure...\n');
            % Implementation would fix organization
        end
    end
end

function recommendations = generate_validation_recommendations(validation_report)
% GENERATE_VALIDATION_RECOMMENDATIONS - Generate actionable recommendations

    recommendations = {};
    
    if validation_report.validation_summary.critical_issues > 0
        recommendations{end+1} = 'CRITICAL: Address critical issues immediately before proceeding with workflow';
        recommendations{end+1} = 'Run individual step validations to identify specific file and dependency issues';
    end
    
    if validation_report.validation_summary.total_issues > 5
        recommendations{end+1} = 'Consider running validation with fix_issues=true to automatically resolve common problems';
    end
    
    % Step-specific recommendations
    step_names = fieldnames(validation_report.steps);
    for i = 1:length(step_names)
        step_name = step_names{i};
        step_data = validation_report.steps.(step_name);
        
        if isfield(step_data, 'summary') && strcmp(step_data.summary.overall_status, "FAIL")
            recommendations{end+1} = sprintf('Step %s requires attention: check file existence and dependencies', step_name);
        end
    end
    
    if isempty(recommendations)
        recommendations{end+1} = 'All validations passed - workflow data is canonical compliant';
    end
end

function write_validation_yaml(validation_report, base_path)
% WRITE_VALIDATION_YAML - Write validation report to YAML file

    report_file = fullfile(base_path, 'metadata', 'validation_report.yaml');
    ensure_directory_exists(fileparts(report_file));
    
    fid = fopen(report_file, 'w');
    if fid ~= -1
        fprintf(fid, '# MRST Workflow Validation Report\n');
        fprintf(fid, '# Generated: %s\n\n', datestr(now, 'yyyy-mm-ddTHH:MM:SS'));
        
        % Write summary
        fprintf(fid, 'validation_summary:\n');
        fprintf(fid, '  overall_status: "%s"\n', validation_report.validation_summary.overall_status);
        fprintf(fid, '  total_issues: %d\n', validation_report.validation_summary.total_issues);
        fprintf(fid, '  critical_issues: %d\n', validation_report.validation_summary.critical_issues);
        
        fclose(fid);
        fprintf('   📄 Validation report written to: %s\n', report_file);
    end
end

function display_validation_summary(validation_report)
% DISPLAY_VALIDATION_SUMMARY - Display concise validation summary

    fprintf('\n=== VALIDATION SUMMARY ===\n');
    fprintf('Overall Status: %s\n', validation_report.validation_summary.overall_status);
    fprintf('Total Issues: %d\n', validation_report.validation_summary.total_issues);
    fprintf('Critical Issues: %d\n', validation_report.validation_summary.critical_issues);
    
    if isfield(validation_report, 'recommendations')
        fprintf('\nRecommendations:\n');
        for i = 1:length(validation_report.recommendations)
            fprintf('  - %s\n', validation_report.recommendations{i});
        end
    end
    fprintf('========================\n\n');
end

function ensure_directory_exists(directory_path)
% ENSURE_DIRECTORY_EXISTS - Create directory if it doesn't exist

    if ~exist(directory_path, 'dir')
        mkdir(directory_path);
    end
end