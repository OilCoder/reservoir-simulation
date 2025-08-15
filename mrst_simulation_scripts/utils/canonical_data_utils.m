function canonical_data_utils()
% CANONICAL_DATA_UTILS - Utilities for canonical data organization and export
%
% This utility provides the core functions for saving MRST simulation data
% following the canonical Simulation Data Catalog organization:
% - by_type/ (static, dynamic, solver, derived, ml_features)
% - by_usage/ (simulation_setup, ML_training, visualization)
% - by_phase/ (pre_simulation, simulation, post_analysis)
%
% Features:
% - Native .mat format for oct2py compatibility
% - YAML metadata generation
% - Automatic symlink creation for multi-organization
% - Timestamp-based versioning
% - Canon-First error handling (fail fast)
%
% Requires: MRST
%
% Author: Claude Code AI System
% Date: August 15, 2025

end

function output_files = save_canonical_data(step_name, data_struct, varargin)
% SAVE_CANONICAL_DATA - Universal function for saving data following canonical organization
%
% INPUTS:
%   step_name   - String identifying workflow step ('s05', 's06', etc.)
%   data_struct - Structure containing all data to save
%   varargin    - Optional name-value pairs:
%                 'base_path' - Base data directory (default: auto-detect)
%                 'formats' - Cell array of formats {'hdf5', 'yaml'} (default: both)
%                 'organizations' - Cell array {'by_type', 'by_usage', 'by_phase'} (default: all)
%                 'timestamp' - Custom timestamp (default: current)
%                 'metadata' - Additional metadata structure (default: auto-generate)
%
% OUTPUTS:
%   output_files - Structure containing paths to all saved files
%
% CANONICAL ORGANIZATION:
%   Primary files saved to by_type/ hierarchy
%   Symlinks created for by_usage/ and by_phase/ access patterns
%   YAML metadata accompanies all data files
%   HDF5 format for arrays, YAML for configurations
%
% CANON-FIRST VALIDATION:
%   Fails fast if step_name not recognized
%   Fails fast if required data fields missing
%   Fails fast if target directories cannot be created

    % Parse input arguments
    p = inputParser;
    addRequired(p, 'step_name', @(x) ischar(x) && ~isempty(x));
    addRequired(p, 'data_struct', @isstruct);
    addParameter(p, 'base_path', '', @ischar);
    addParameter(p, 'formats', {'mat', 'yaml'}, @iscell);
    addParameter(p, 'organizations', {'by_type', 'by_usage', 'by_phase'}, @iscell);
    addParameter(p, 'timestamp', datestr(now, 'yyyymmdd_HHMMSS'), @ischar);
    addParameter(p, 'metadata', struct(), @isstruct);
    parse(p, step_name, data_struct, varargin{:});
    
    % Validate step name follows canonical naming
    if ~validate_step_name(step_name)
        error(['Invalid step name: %s\n' ...
               'REQUIRED: Update obsidian-vault/Planning/Simulation_Data_Catalog/\n' ...
               'STEP_DATA_OUTPUT_MAPPING.md to define canonical step mapping.\n' ...
               'Canon must specify exact step naming pattern.'], step_name);
    end
    
    % Determine base path
    base_path = p.Results.base_path;
    if isempty(base_path)
        script_path = fileparts(mfilename('fullpath'));
        base_path = fullfile(fileparts(script_path), '..', 'data', 'simulation_data');
    end
    
    % Validate base path exists or can be created
    if ~exist(base_path, 'dir')
        try
            mkdir(base_path);
        catch ME
            error(['Cannot create canonical data directory: %s\n' ...
                   'REQUIRED: Update directory permissions or specify valid base_path.\n' ...
                   'Canon requires write access to simulation_data directory.\n' ...
                   'Error: %s'], base_path, ME.message);
        end
    end
    
    fprintf('📁 Saving canonical data for step %s...\n', step_name);
    
    % Get canonical step configuration
    step_config = get_step_configuration(step_name);
    
    % Validate required data fields for this step
    validate_step_data(step_name, data_struct, step_config);
    
    % Generate canonical filenames with timestamp
    timestamp = p.Results.timestamp;
    filenames = generate_canonical_filenames(step_name, step_config, timestamp);
    
    % Initialize output structure
    output_files = struct();
    output_files.step_name = step_name;
    output_files.timestamp = timestamp;
    output_files.primary_files = {};
    output_files.symlinks = {};
    output_files.metadata_files = {};
    
    try
        % Create primary data files in by_type organization
        primary_path = fullfile(base_path, 'by_type', step_config.primary_category, step_config.data_subcategory);
        ensure_directory_exists(primary_path);
        
        % Save data in specified formats
        formats = p.Results.formats;
        for i = 1:length(formats)
            format = formats{i};
            switch format
                case 'mat'
                    if any(contains(fieldnames(data_struct), {'grid', 'rock', 'fluid', 'pressure', 'saturation', 'mrst_modules', 'structural_framework', 'faults'}))
                        mat_file = save_as_mat(data_struct, primary_path, filenames, step_config);
                        output_files.primary_files{end+1} = mat_file;
                    end
                    
                case 'yaml'
                    if any(contains(fieldnames(data_struct), {'config', 'metadata', 'summary'}))
                        yaml_file = save_as_yaml(data_struct, primary_path, filenames, step_config);
                        output_files.primary_files{end+1} = yaml_file;
                    end
                    
                otherwise
                    warning('Unsupported format: %s. Supported: mat, yaml', format);
            end
        end
        
        % Generate metadata for all primary files
        metadata_files = generate_canonical_metadata(output_files.primary_files, step_name, data_struct, p.Results.metadata, step_config);
        output_files.metadata_files = metadata_files;
        
        % Create symlinks for alternative organizations
        organizations = p.Results.organizations;
        symlink_paths = create_organization_symlinks(output_files.primary_files, base_path, step_config, organizations);
        output_files.symlinks = symlink_paths;
        
        % Validate output completeness
        validate_output_completeness(output_files, step_config);
        
        fprintf('   ✅ Canonical data saved successfully\n');
        fprintf('   📄 Primary files: %d\n', length(output_files.primary_files));
        fprintf('   🔗 Symlinks created: %d\n', length(output_files.symlinks));
        fprintf('   📋 Metadata files: %d\n', length(output_files.metadata_files));
        
    catch ME
        fprintf('   ❌ Error saving canonical data: %s\n', ME.message);
        rethrow(ME);
    end
end

function valid = validate_step_name(step_name)
% VALIDATE_STEP_NAME - Check if step name follows canonical pattern
%
% Canon pattern: s##[letter]_verb_noun (e.g., s05_create_pebi_grid, s06a_base_rock)
    
    valid = false;
    
    % Check basic pattern
    if ~ischar(step_name) || length(step_name) < 3
        return;
    end
    
    % Must start with 's' followed by digits
    if step_name(1) ~= 's' || ~isstrprop(step_name(2), 'digit')
        return;
    end
    
    % Known canonical steps from STEP_DATA_OUTPUT_MAPPING.md
    canonical_steps = {'s01', 's02', 's03', 's04', 's05', 's06', 's07', 's08', 's09', ...
                      's10', 's11', 's12', 's13', 's14', 's15', 's16', 's17', 's18', ...
                      's19', 's20', 's21', 's22', 's23', 's24', 's25', 's99'};
    
    % Extract step number (s##[letter])
    step_prefix = regexp(step_name, '^s\d+[a-z]*', 'match', 'once');
    
    if isempty(step_prefix)
        return;
    end
    
    % Check if step prefix is in canonical list
    step_num = regexp(step_prefix, '^s\d+', 'match', 'once');
    if any(strcmp(step_num, canonical_steps))
        valid = true;
    end
end

function step_config = get_step_configuration(step_name)
% GET_STEP_CONFIGURATION - Get canonical configuration for workflow step
%
% Returns configuration structure based on STEP_DATA_OUTPUT_MAPPING.md canon

    % Extract step number for configuration lookup
    step_num = regexp(step_name, '^s\d+', 'match', 'once');
    
    % Canonical step configurations from STEP_DATA_OUTPUT_MAPPING.md
    switch step_num
        case 's01'
            step_config = struct(...
                'primary_category', 'control', ...
                'data_subcategory', 'mrst_session', ...
                'data_type', 'environment_control', ...
                'required_fields', {{'mrst_modules', 'paths', 'environment'}}, ...
                'usage_mapping', {{'initialization'}}, ...
                'phase_mapping', {{'pre_simulation'}});
                
        case 's02'
            step_config = struct(...
                'primary_category', 'static', ...
                'data_subcategory', 'fluid_properties', ...
                'data_type', 'fluid_pvt', ...
                'required_fields', {{'fluid', 'pvt_tables'}}, ...
                'usage_mapping', {{'simulation_setup'}}, ...
                'phase_mapping', {{'pre_simulation'}});
                
        case 's03'
            step_config = struct(...
                'primary_category', 'static', ...
                'data_subcategory', 'geology', ...
                'data_type', 'structural_framework', ...
                'required_fields', {{'structural_framework', 'layers'}}, ...
                'usage_mapping', {{'geological_modeling', 'simulation_setup'}}, ...
                'phase_mapping', {{'pre_simulation'}});
                
        case 's04'
            step_config = struct(...
                'primary_category', 'static', ...
                'data_subcategory', 'geology', ...
                'data_type', 'fault_system', ...
                'required_fields', {{'faults', 'transmissibility'}}, ...
                'usage_mapping', {{'geological_modeling', 'simulation_setup'}}, ...
                'phase_mapping', {{'pre_simulation'}});
                
        case 's05'
            step_config = struct(...
                'primary_category', 'static', ...
                'data_subcategory', 'geometry', ...
                'data_type', 'pebi_grid', ...
                'required_fields', {{'G', 'grid_cells', 'grid_faces'}}, ...
                'usage_mapping', {{'simulation_setup', 'visualization'}}, ...
                'phase_mapping', {{'pre_simulation'}});
                
        case 's06'
            step_config = struct(...
                'primary_category', 'static', ...
                'data_subcategory', 'geology', ...
                'data_type', 'base_rock_properties', ...
                'required_fields', {{'rock', 'porosity', 'permeability'}}, ...
                'usage_mapping', {{'simulation_setup'}}, ...
                'phase_mapping', {{'pre_simulation'}});
                
        case 's07'
            step_config = struct(...
                'primary_category', 'static', ...
                'data_subcategory', 'geology', ...
                'data_type', 'enhanced_rock_properties', ...
                'required_fields', {{'rock', 'layers', 'metadata'}}, ...
                'usage_mapping', {{'simulation_setup', 'geological_modeling'}}, ...
                'phase_mapping', {{'pre_simulation'}});
                
        case 's08'
            step_config = struct(...
                'primary_category', 'static', ...
                'data_subcategory', 'geology', ...
                'data_type', 'final_simulation_rock', ...
                'required_fields', {{'rock', 'heterogeneity', 'simulation_metadata'}}, ...
                'usage_mapping', {{'simulation_setup'}}, ...
                'phase_mapping', {{'simulation_ready'}});
                
        case 's09'
            step_config = struct(...
                'primary_category', 'static', ...
                'data_subcategory', 'scal_properties', ...
                'data_type', 'relative_permeability', ...
                'required_fields', {{'relperm', 'kr_tables'}}, ...
                'usage_mapping', {{'simulation_setup'}}, ...
                'phase_mapping', {{'pre_simulation'}});
                
        case 's20'
            step_config = struct(...
                'primary_category', 'control', ...
                'data_subcategory', 'solver_configuration', ...
                'data_type', 'solver_setup', ...
                'required_fields', {{'nonlinear_solver', 'timestep_control', 'simulation_schedule'}}, ...
                'usage_mapping', {{'simulation_setup'}}, ...
                'phase_mapping', {{'pre_simulation'}});
                
        case 's21'
            step_config = struct(...
                'primary_category', 'dynamic', ...
                'data_subcategory', 'simulation_results', ...
                'data_type', 'dynamic_simulation', ...
                'required_fields', {{'states', 'reports', 'wells'}}, ...
                'usage_mapping', {{'analysis', 'ML_training'}}, ...
                'phase_mapping', {{'simulation'}});
                
        case 's22'
            step_config = struct(...
                'primary_category', 'dynamic', ...
                'data_subcategory', 'simulation_results', ...
                'data_type', 'dynamic_simulation_with_diagnostics', ...
                'required_fields', {{'states', 'reports', 'solver_diagnostics'}}, ...
                'usage_mapping', {{'analysis', 'ML_training', 'debugging'}}, ...
                'phase_mapping', {{'simulation'}});
                
        % FASE 3: Solver Diagnostics Steps
        case {'s22_solver_diagnostics', 's21_diagnostics', 'solver_diagnostics'}
            step_config = struct(...
                'primary_category', 'solver', ...
                'data_subcategory', 'internal_diagnostics', ...
                'data_type', 'solver_internal_diagnostics', ...
                'required_fields', {{'solver_diagnostics', 'convergence_data', 'performance_metrics'}}, ...
                'usage_mapping', {{'ML_training', 'performance_analysis', 'debugging'}}, ...
                'phase_mapping', {{'simulation', 'post_analysis'}});
                
        otherwise
            error(['Unrecognized canonical step: %s\n' ...
                   'REQUIRED: Update obsidian-vault/Planning/Simulation_Data_Catalog/\n' ...
                   'STEP_DATA_OUTPUT_MAPPING.md to define configuration for step %s.\n' ...
                   'Canon must specify primary_category, data_subcategory, data_type.'], step_name, step_name);
    end
end

function validate_step_data(step_name, data_struct, step_config)
% VALIDATE_STEP_DATA - Validate data structure contains required fields for step
%
% Canon-First validation: fail fast if required data missing

    required_fields = step_config.required_fields;
    
    for i = 1:length(required_fields)
        field = required_fields{i};
        
        if ~isfield(data_struct, field)
            error(['Missing required field for step %s: %s\n' ...
                   'REQUIRED: Update workflow step %s to provide field ''%s''.\n' ...
                   'Canon specification in STEP_DATA_OUTPUT_MAPPING.md requires this field.\n' ...
                   'No defaults allowed - canonical data must be explicitly provided.'], ...
                   step_name, field, step_name, field);
        end
        
        % Additional validation for critical fields
        if isempty(data_struct.(field))
            error(['Empty required field for step %s: %s\n' ...
                   'REQUIRED: Field ''%s'' must contain valid data.\n' ...
                   'Canon specification requires non-empty data for this field.'], ...
                   step_name, field, field);
        end
    end
end

function filenames = generate_canonical_filenames(step_name, step_config, timestamp)
% GENERATE_CANONICAL_FILENAMES - Generate canonical filenames with timestamp versioning
%
% Canon pattern: [data_type]_[timestamp].[ext]

    base_name = step_config.data_type;
    
    filenames = struct();
    filenames.mat = sprintf('%s_%s.mat', base_name, timestamp);
    filenames.yaml = sprintf('%s_%s.yaml', base_name, timestamp);
    filenames.metadata = sprintf('%s_metadata_%s.yaml', base_name, timestamp);
    
    % Create current version symlinks (without timestamp)
    filenames.current_mat = sprintf('%s_current.mat', base_name);
    filenames.current_yaml = sprintf('%s_current.yaml', base_name);
end

function mat_file = save_as_mat(data_struct, target_path, filenames, step_config)
% SAVE_AS_MAT - Save data structure to native .mat format for oct2py compatibility
%
% Features:
% - Native MATLAB structure preservation
% - Direct oct2py compatibility
% - Maintains all MRST data types

    mat_file = fullfile(target_path, filenames.mat);
    
    % Prepare data for saving with metadata
    canonical_data = data_struct;
    
    % Add canonical metadata structure
    canonical_metadata = struct();
    canonical_metadata.creation_date = datestr(now, 'yyyy-mm-ddTHH:MM:SS');
    canonical_metadata.step_name = step_config.data_type;
    canonical_metadata.data_category = step_config.primary_category;
    canonical_metadata.data_subcategory = step_config.data_subcategory;
    canonical_metadata.format_version = 'canonical_v1.0_mat';
    canonical_metadata.units = get_mrst_standard_units();
    
    % Save using native MATLAB format with -v7.3 for large data compatibility
    try
        save(mat_file, 'canonical_data', 'canonical_metadata', '-v7.3');
        fprintf('       Saved canonical .mat file: %s\n', mat_file);
        
    catch ME
        % Fallback to standard format if -v7.3 fails
        try
            save(mat_file, 'canonical_data', 'canonical_metadata');
            fprintf('       Saved canonical .mat file (standard format): %s\n', mat_file);
        catch ME2
            error('Failed to save .mat file: %s', ME2.message);
        end
    end
    
    % Create current version symlink
    current_link = fullfile(target_path, filenames.current_mat);
    create_symlink(mat_file, current_link);
end

% HDF5 functions removed - using native .mat format for oct2py compatibility

function yaml_file = save_as_yaml(data_struct, target_path, filenames, step_config)
% SAVE_AS_YAML - Save configuration and metadata to YAML format
%
% Targets: configuration data, metadata, human-readable summaries

    yaml_file = fullfile(target_path, filenames.yaml);
    
    % Prepare YAML structure
    yaml_data = struct();
    yaml_data.step_info.name = step_config.data_type;
    yaml_data.step_info.category = step_config.primary_category;
    yaml_data.step_info.subcategory = step_config.data_subcategory;
    yaml_data.step_info.creation_date = datestr(now, 'yyyy-mm-ddTHH:MM:SS');
    
    % Extract configuration and metadata fields
    field_names = fieldnames(data_struct);
    for i = 1:length(field_names)
        field_name = field_names{i};
        field_data = data_struct.(field_name);
        
        % Include non-array data in YAML
        if ~isnumeric(field_data) || numel(field_data) <= 10
            yaml_data.data.(field_name) = field_data;
        else
            % For large arrays, include summary statistics
            if isnumeric(field_data)
                yaml_data.data_summary.(field_name).type = 'numeric_array';
                yaml_data.data_summary.(field_name).size = size(field_data);
                yaml_data.data_summary.(field_name).min = min(field_data(:));
                yaml_data.data_summary.(field_name).max = max(field_data(:));
                yaml_data.data_summary.(field_name).mean = mean(field_data(:));
            end
        end
    end
    
    % Write YAML file
    write_yaml_file(yaml_file, yaml_data);
    
    % Create current version symlink
    current_link = fullfile(target_path, filenames.current_yaml);
    create_symlink(yaml_file, current_link);
end

function metadata_files = generate_canonical_metadata(primary_files, step_name, data_struct, additional_metadata, step_config)
% GENERATE_CANONICAL_METADATA - Generate comprehensive metadata for all data files
%
% Creates YAML metadata following canonical schema

    metadata_files = {};
    
    for i = 1:length(primary_files)
        primary_file = primary_files{i};
        [file_path, file_name, file_ext] = fileparts(primary_file);
        
        metadata_file = fullfile(file_path, sprintf('%s_metadata.yaml', file_name));
        
        % Generate metadata structure
        metadata = struct();
        
        % Identification
        metadata.identification.name = sprintf('%s %s', step_config.data_type, file_ext(2:end));
        metadata.identification.description = sprintf('Canonical %s data from workflow step %s', step_config.data_type, step_name);
        metadata.identification.data_id = sprintf('%s_%s_%s', step_name, file_name, datestr(now, 'yyyymmdd_HHMMSS'));
        metadata.identification.creation_date = datestr(now, 'yyyy-mm-ddTHH:MM:SS');
        metadata.identification.creator = 'MRST_Canonical_Workflow';
        
        % Classification
        metadata.data_type.primary = step_config.data_type;
        metadata.data_type.category = step_config.primary_category;
        metadata.data_type.subcategory = step_config.data_subcategory;
        metadata.data_type.tags = get_canonical_tags(step_config);
        
        % File information
        if exist(primary_file, 'file')
            file_info = dir(primary_file);
            metadata.file_info.file_path = primary_file;
            metadata.file_info.file_format = file_ext(2:end);
            metadata.file_info.file_size_mb = file_info.bytes / 1048576;
            metadata.file_info.last_modified = datestr(file_info.datenum, 'yyyy-mm-ddTHH:MM:SS');
        end
        
        % Data organization
        metadata.organization.by_type_path = extract_relative_path(primary_file, 'by_type');
        metadata.organization.usage_mappings = step_config.usage_mapping;
        metadata.organization.phase_mappings = step_config.phase_mapping;
        
        % Quality information
        metadata.quality.validation_status = 'not_validated';
        metadata.quality.completeness = 100.0;
        metadata.quality.known_issues = {};
        
        % MRST units
        metadata.units = get_mrst_standard_units();
        
        % Additional metadata
        if ~isempty(additional_metadata)
            additional_fields = fieldnames(additional_metadata);
            for j = 1:length(additional_fields)
                field = additional_fields{j};
                metadata.additional.(field) = additional_metadata.(field);
            end
        end
        
        % Write metadata file
        write_yaml_file(metadata_file, metadata);
        metadata_files{end+1} = metadata_file;
    end
end

function tags = get_canonical_tags(step_config)
% GET_CANONICAL_TAGS - Generate canonical tags based on step configuration

    tags = {step_config.primary_category, step_config.data_subcategory, step_config.data_type};
    
    % Add specific tags based on data type
    switch step_config.data_type
        case {'pebi_grid', 'cartesian_grid'}
            tags = [tags, {'grid', 'geometry', 'computational'}];
        case {'base_rock_properties', 'enhanced_rock_properties', 'final_simulation_rock'}
            tags = [tags, {'rock', 'properties', 'geology', 'porosity', 'permeability'}];
        case {'fluid_pvt', 'native_fluid_properties'}
            tags = [tags, {'fluid', 'pvt', 'properties', 'oil', 'water'}];
        case {'structural_framework'}
            tags = [tags, {'geology', 'structure', 'layers', 'stratigraphy'}];
        case {'fault_system'}
            tags = [tags, {'geology', 'faults', 'transmissibility', 'barriers'}];
        case {'solver_setup', 'solver_configuration'}
            tags = [tags, {'solver', 'configuration', 'nonlinear', 'timestep'}];
        case {'dynamic_simulation', 'dynamic_simulation_with_diagnostics'}
            tags = [tags, {'simulation', 'dynamic', 'timestep', 'states', 'wells'}];
        case {'solver_internal_diagnostics'}
            tags = [tags, {'solver', 'diagnostics', 'convergence', 'performance', 'newton', 'residuals', 'ml_features'}];
        otherwise
            tags = [tags, {'simulation', 'data'}];
    end
end

function units = get_mrst_standard_units()
% GET_MRST_STANDARD_UNITS - Standard MRST units for metadata

    units = struct();
    units.pressure = 'Pa';
    units.permeability = 'm^2';
    units.length = 'm';
    units.volume = 'm^3';
    units.rates = 'm^3/s';
    units.time = 's';
    units.porosity = 'dimensionless';
    units.saturation = 'dimensionless';
    units.temperature = 'K';
    units.density = 'kg/m^3';
    units.viscosity = 'Pa*s';
end

function symlink_paths = create_organization_symlinks(primary_files, base_path, step_config, organizations)
% CREATE_ORGANIZATION_SYMLINKS - Create symlinks for alternative data organization strategies
%
% Creates symlinks in by_usage/ and by_phase/ pointing to primary files in by_type/

    symlink_paths = {};
    
    for i = 1:length(organizations)
        org_type = organizations{i};
        
        switch org_type
            case 'by_usage'
                usage_mappings = step_config.usage_mapping;
                for j = 1:length(usage_mappings)
                    usage_path = fullfile(base_path, 'by_usage', usage_mappings{j});
                    ensure_directory_exists(usage_path);
                    
                    for k = 1:length(primary_files)
                        primary_file = primary_files{k};
                        [~, file_name, file_ext] = fileparts(primary_file);
                        symlink_target = fullfile(usage_path, [file_name, file_ext]);
                        
                        create_symlink(primary_file, symlink_target);
                        symlink_paths{end+1} = symlink_target;
                    end
                end
                
            case 'by_phase'
                phase_mappings = step_config.phase_mapping;
                for j = 1:length(phase_mappings)
                    phase_path = fullfile(base_path, 'by_phase', phase_mappings{j});
                    ensure_directory_exists(phase_path);
                    
                    for k = 1:length(primary_files)
                        primary_file = primary_files{k};
                        [~, file_name, file_ext] = fileparts(primary_file);
                        symlink_target = fullfile(phase_path, [file_name, file_ext]);
                        
                        create_symlink(primary_file, symlink_target);
                        symlink_paths{end+1} = symlink_target;
                    end
                end
        end
    end
end

function create_symlink(target_file, link_path)
% CREATE_SYMLINK - Create symbolic link with cross-platform compatibility
%
% Uses system-appropriate symlink creation

    % Remove existing symlink if present
    if exist(link_path, 'file') || exist(link_path, 'dir')
        delete(link_path);
    end
    
    % Get relative path for symlink
    [link_dir, ~, ~] = fileparts(link_path);
    rel_target = get_relative_path(target_file, link_dir);
    
    if isunix || ismac
        % Unix/Mac: use ln -s
        system_cmd = sprintf('ln -s "%s" "%s"', rel_target, link_path);
        [status, ~] = system(system_cmd);
        if status ~= 0
            warning('Could not create symlink: %s -> %s', rel_target, link_path);
        end
    else
        % Windows: use mklink (requires admin rights) or copy as fallback
        system_cmd = sprintf('mklink "%s" "%s"', link_path, target_file);
        [status, ~] = system(system_cmd);
        if status ~= 0
            % Fallback: copy file instead of symlink
            copyfile(target_file, link_path);
        end
    end
end

function rel_path = get_relative_path(target_file, link_dir)
% GET_RELATIVE_PATH - Calculate relative path from link directory to target file

    target_parts = strsplit(target_file, filesep);
    link_parts = strsplit(link_dir, filesep);
    
    % Find common prefix
    common_length = 0;
    for i = 1:min(length(target_parts), length(link_parts))
        if strcmp(target_parts{i}, link_parts{i})
            common_length = i;
        else
            break;
        end
    end
    
    % Build relative path
    up_levels = length(link_parts) - common_length;
    rel_parts = repmat({'..'}, 1, up_levels);
    rel_parts = [rel_parts, target_parts(common_length+1:end)];
    
    rel_path = strjoin(rel_parts, filesep);
end

function rel_path = extract_relative_path(full_path, organization_type)
% EXTRACT_RELATIVE_PATH - Extract relative path within organization structure

    parts = strsplit(full_path, filesep);
    
    % Find organization type in path
    org_idx = find(strcmp(parts, organization_type), 1);
    
    if ~isempty(org_idx) && org_idx < length(parts)
        rel_parts = parts(org_idx+1:end);
        rel_path = strjoin(rel_parts, '/');
    else
        rel_path = '';
    end
end

function validate_output_completeness(output_files, step_config)
% VALIDATE_OUTPUT_COMPLETENESS - Validate all expected outputs were created
%
% Canon-First validation: fail fast if outputs incomplete

    % Check primary files exist
    if isempty(output_files.primary_files)
        error(['No primary files created for step configuration.\n' ...
               'REQUIRED: Step must produce at least one primary data file.\n' ...
               'Canon specification requires data output for %s step.'], step_config.data_type);
    end
    
    % Validate each primary file exists and is accessible
    for i = 1:length(output_files.primary_files)
        primary_file = output_files.primary_files{i};
        
        if ~exist(primary_file, 'file')
            error(['Primary file not created: %s\n' ...
                   'REQUIRED: File creation failed during canonical save process.\n' ...
                   'Canon requires successful file creation with validation.'], primary_file);
        end
        
        % Check file is not empty
        file_info = dir(primary_file);
        if file_info.bytes == 0
            error(['Primary file is empty: %s\n' ...
                   'REQUIRED: Files must contain valid data.\n' ...
                   'Canon prohibits empty data files.'], primary_file);
        end
    end
    
    % Validate metadata files exist
    if length(output_files.metadata_files) ~= length(output_files.primary_files)
        error(['Metadata files count mismatch.\n' ...
               'REQUIRED: Each primary file must have corresponding metadata.\n' ...
               'Canon requires complete metadata for all data files.']);
    end
end

function ensure_directory_exists(directory_path)
% ENSURE_DIRECTORY_EXISTS - Create directory if it doesn't exist with Canon-First error handling

    if ~exist(directory_path, 'dir')
        try
            mkdir(directory_path);
        catch ME
            error(['Cannot create canonical directory: %s\n' ...
                   'REQUIRED: Directory creation failed.\n' ...
                   'Canon requires write access to simulation data structure.\n' ...
                   'Error: %s'], directory_path, ME.message);
        end
    end
end

function write_yaml_file(yaml_path, data_struct)
% WRITE_YAML_FILE - Write MATLAB structure to YAML file
%
% Simple YAML writer for canonical metadata

    fid = fopen(yaml_path, 'w');
    if fid == -1
        error(['Cannot create YAML file: %s\n' ...
               'REQUIRED: File creation failed.\n' ...
               'Canon requires write access for metadata files.'], yaml_path);
    end
    
    try
        fprintf(fid, '# Canonical Simulation Data Metadata\n');
        fprintf(fid, '# Generated: %s\n\n', datestr(now, 'yyyy-mm-ddTHH:MM:SS'));
        
        write_yaml_structure(fid, data_struct, 0);
        
        fclose(fid);
    catch ME
        fclose(fid);
        error('Error writing YAML file %s: %s', yaml_path, ME.message);
    end
end

function write_yaml_structure(fid, s, indent_level)
% WRITE_YAML_STRUCTURE - Recursively write MATLAB struct as YAML

    indent = repmat('  ', 1, indent_level);
    
    if isstruct(s)
        field_names = fieldnames(s);
        for i = 1:length(field_names)
            field_name = field_names{i};
            value = s.(field_name);
            
            if isstruct(value)
                fprintf(fid, '%s%s:\n', indent, field_name);
                write_yaml_structure(fid, value, indent_level + 1);
            elseif iscell(value)
                fprintf(fid, '%s%s:\n', indent, field_name);
                for j = 1:length(value)
                    if ischar(value{j})
                        fprintf(fid, '%s  - "%s"\n', indent, value{j});
                    else
                        fprintf(fid, '%s  - %s\n', indent, mat2str(value{j}));
                    end
                end
            elseif ischar(value)
                fprintf(fid, '%s%s: "%s"\n', indent, field_name, value);
            elseif isnumeric(value)
                if length(value) == 1
                    if isinteger(value)
                        fprintf(fid, '%s%s: %d\n', indent, field_name, value);
                    else
                        fprintf(fid, '%s%s: %.6g\n', indent, field_name, value);
                    end
                else
                    fprintf(fid, '%s%s: [', indent, field_name);
                    for j = 1:min(5, length(value))  % Limit array display
                        if j > 1
                            fprintf(fid, ', ');
                        end
                        fprintf(fid, '%.6g', value(j));
                    end
                    if length(value) > 5
                        fprintf(fid, ', ...');
                    end
                    fprintf(fid, ']\n');
                end
            elseif islogical(value)
                fprintf(fid, '%s%s: %s\n', indent, field_name, lower(mat2str(value)));
            end
        end
    end
end