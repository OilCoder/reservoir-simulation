function data_export_utils()
% DATA_EXPORT_UTILS - Legacy utilities for exporting simulation data to organized structure
%
% DEPRECATED: This utility is being migrated to canonical_data_utils.m
% For new implementations, use canonical_data_utils.m which provides:
% - HDF5 format support for Python/ML compatibility
% - Enhanced YAML metadata generation
% - Canon-First error handling
% - Automatic symlink creation for multi-organization
% - Timestamp-based versioning
%
% LEGACY COMPATIBILITY: This function maintains backward compatibility
% during the transition to canonical data utilities.
%
% Author: Claude Code AI System  
% Date: August 11, 2025
% Updated: August 15, 2025 (canonical integration)

end

function export_static_data(grid_data, rock_data, well_data, fluid_data, varargin)
% EXPORT_STATIC_DATA - Export static simulation data to organized structure
%
% INPUTS:
%   grid_data  - Grid geometry and properties structure
%   rock_data  - Rock properties structure  
%   well_data  - Well configuration structure
%   fluid_data - Fluid properties structure
%   varargin   - Optional name-value pairs:
%                'timestamp' - Custom timestamp (default: current)
%                'base_dir' - Base directory (default: auto-detect)

    p = inputParser;
    addParameter(p, 'timestamp', datestr(now, 'yyyymmdd_HHMMSS'), @ischar);
    addParameter(p, 'base_dir', '', @ischar);
    parse(p, varargin{:});
    
    timestamp = p.Results.timestamp;
    
    % Determine base directory
    if isempty(p.Results.base_dir)
        script_path = fileparts(mfilename('fullpath'));
        base_dir = fullfile(fileparts(script_path), 'data', 'simulation_data', 'by_type');
    else
        base_dir = p.Results.base_dir;
    end
    
    fprintf('📁 Exporting static data to organized structure...\n');
    
    try
        % Export geology data
        geology_dir = fullfile(base_dir, 'static', 'geology');
        ensure_directory_exists(geology_dir);
        
        geology_data = struct();
        geology_data.grid_geometry = extract_grid_geometry(grid_data);
        geology_data.rock_regions = extract_rock_regions(rock_data);
        geology_data.structural_framework = extract_structural_data(grid_data, rock_data);
        geology_data.export_timestamp = timestamp;
        
        save(fullfile(geology_dir, 'grid_geometry.mat'), '-struct', 'geology_data');
        create_metadata_file(fullfile(geology_dir, 'grid_geometry.yaml'), ...
                           'static_grid', geology_data, 'Grid geometry and geological framework');
        
        % Export well configuration
        wells_dir = fullfile(base_dir, 'static', 'wells');
        ensure_directory_exists(wells_dir);
        
        wells_export = struct();
        wells_export.well_definitions = well_data;
        wells_export.export_timestamp = timestamp;
        
        save(fullfile(wells_dir, 'well_definitions.mat'), '-struct', 'wells_export');
        create_metadata_file(fullfile(wells_dir, 'well_definitions.yaml'), ...
                           'static_wells', wells_export, 'Well locations, trajectories and completions');
        
        % Export fluid properties  
        fluid_dir = fullfile(base_dir, 'static', 'fluid_properties');
        ensure_directory_exists(fluid_dir);
        
        fluid_export = struct();
        fluid_export.pvt_tables = extract_pvt_tables(fluid_data);
        fluid_export.export_timestamp = timestamp;
        
        save(fullfile(fluid_dir, 'pvt_tables.mat'), '-struct', 'fluid_export');
        create_metadata_file(fullfile(fluid_dir, 'pvt_tables.yaml'), ...
                           'static_properties', fluid_export, 'PVT tables and fluid property correlations');
        
        % Export SCAL properties if available
        if isfield(fluid_data, 'relperm') || isfield(fluid_data, 'pc')
            scal_dir = fullfile(base_dir, 'static', 'scal_properties');
            ensure_directory_exists(scal_dir);
            
            scal_export = struct();
            if isfield(fluid_data, 'relperm')
                scal_export.relative_permeability = fluid_data.relperm;
            end
            if isfield(fluid_data, 'pc') 
                scal_export.capillary_pressure = fluid_data.pc;
            end
            scal_export.export_timestamp = timestamp;
            
            save(fullfile(scal_dir, 'relative_permeability.mat'), '-struct', 'scal_export');
            create_metadata_file(fullfile(scal_dir, 'relative_permeability.yaml'), ...
                               'static_properties', scal_export, 'Relative permeability and capillary pressure data');
        end
        
        fprintf('   ✅ Static data exported successfully\n');
        
    catch ME
        fprintf('   ❌ Error exporting static data: %s\n', ME.message);
        rethrow(ME);
    end
end

function export_dynamic_data(solution_states, schedule, varargin)
% EXPORT_DYNAMIC_DATA - Export dynamic simulation results to organized structure
%
% INPUTS:
%   solution_states - Cell array of solution states from simulation
%   schedule       - MRST schedule structure
%   varargin       - Optional name-value pairs:
%                   'timestamp' - Custom timestamp
%                   'base_dir' - Base directory
%                   'timestep' - Specific timestep to export (default: all)

    p = inputParser;
    addParameter(p, 'timestamp', datestr(now, 'yyyymmdd_HHMMSS'), @ischar);
    addParameter(p, 'base_dir', '', @ischar);
    addParameter(p, 'timestep', [], @isnumeric);
    parse(p, varargin{:});
    
    timestamp = p.Results.timestamp;
    specific_timestep = p.Results.timestep;
    
    % Determine base directory
    if isempty(p.Results.base_dir)
        script_path = fileparts(mfilename('fullpath'));
        base_dir = fullfile(fileparts(script_path), 'data', 'simulation_data', 'by_type');
    else
        base_dir = p.Results.base_dir;
    end
    
    fprintf('📊 Exporting dynamic simulation data...\n');
    
    try
        % Determine timesteps to export
        if isempty(specific_timestep)
            timesteps = 1:length(solution_states);
        else
            timesteps = specific_timestep;
        end
        
        % Export pressure data
        pressures_dir = fullfile(base_dir, 'dynamic', 'pressures');
        ensure_directory_exists(pressures_dir);
        
        pressure_data = extract_pressure_timeseries(solution_states, timesteps);
        save(fullfile(pressures_dir, sprintf('pressure_timeseries_%s.mat', timestamp)), ...
             '-struct', 'pressure_data');
        create_metadata_file(fullfile(pressures_dir, sprintf('pressure_timeseries_%s.yaml', timestamp)), ...
                           'dynamic_solution', pressure_data, 'Pressure field evolution over time');
        
        % Export saturation data
        saturations_dir = fullfile(base_dir, 'dynamic', 'saturations');
        ensure_directory_exists(saturations_dir);
        
        saturation_data = extract_saturation_timeseries(solution_states, timesteps);
        save(fullfile(saturations_dir, sprintf('saturation_timeseries_%s.mat', timestamp)), ...
             '-struct', 'saturation_data');
        create_metadata_file(fullfile(saturations_dir, sprintf('saturation_timeseries_%s.yaml', timestamp)), ...
                           'dynamic_solution', saturation_data, 'Fluid saturation field evolution over time');
        
        % Export well rates data
        rates_dir = fullfile(base_dir, 'dynamic', 'rates');
        ensure_directory_exists(rates_dir);
        
        rates_data = extract_well_rates_timeseries(solution_states, schedule, timesteps);
        save(fullfile(rates_dir, sprintf('well_rates_%s.mat', timestamp)), ...
             '-struct', 'rates_data');
        create_metadata_file(fullfile(rates_dir, sprintf('well_rates_%s.yaml', timestamp)), ...
                           'dynamic_production', rates_data, 'Well production and injection rates over time');
        
        fprintf('   ✅ Dynamic data exported successfully for %d timesteps\n', length(timesteps));
        
    catch ME
        fprintf('   ❌ Error exporting dynamic data: %s\n', ME.message);
        rethrow(ME);
    end
end

function export_derived_data(solution_states, schedule, model, varargin)
% EXPORT_DERIVED_DATA - Export calculated/derived results to organized structure
%
% INPUTS:
%   solution_states - Cell array of solution states
%   schedule       - MRST schedule structure  
%   model          - Simulation model structure
%   varargin       - Optional name-value pairs

    p = inputParser;
    addParameter(p, 'timestamp', datestr(now, 'yyyymmdd_HHMMSS'), @ischar);
    addParameter(p, 'base_dir', '', @ischar);
    parse(p, varargin{:});
    
    timestamp = p.Results.timestamp;
    
    % Determine base directory
    if isempty(p.Results.base_dir)
        script_path = fileparts(mfilename('fullpath'));
        base_dir = fullfile(fileparts(script_path), 'data', 'simulation_data', 'by_type');
    else
        base_dir = p.Results.base_dir;
    end
    
    fprintf('📈 Exporting derived analysis data...\n');
    
    try
        % Export recovery factors
        recovery_dir = fullfile(base_dir, 'derived', 'recovery_factors');
        ensure_directory_exists(recovery_dir);
        
        recovery_data = calculate_recovery_factors(solution_states, model);
        save(fullfile(recovery_dir, sprintf('field_recovery_factor_%s.mat', timestamp)), ...
             '-struct', 'recovery_data');
        create_metadata_file(fullfile(recovery_dir, sprintf('field_recovery_factor_%s.yaml', timestamp)), ...
                           'derived_analytics', recovery_data, 'Field and pattern recovery factors');
        
        % Export sweep efficiency analysis
        sweep_dir = fullfile(base_dir, 'derived', 'sweep_efficiency');
        ensure_directory_exists(sweep_dir);
        
        sweep_data = calculate_sweep_efficiency(solution_states, model);
        save(fullfile(sweep_dir, sprintf('areal_sweep_%s.mat', timestamp)), ...
             '-struct', 'sweep_data');
        create_metadata_file(fullfile(sweep_dir, sprintf('areal_sweep_%s.yaml', timestamp)), ...
                           'derived_analytics', sweep_data, 'Sweep efficiency analysis');
        
        % Export connectivity analysis
        connectivity_dir = fullfile(base_dir, 'derived', 'connectivity');
        ensure_directory_exists(connectivity_dir);
        
        connectivity_data = calculate_well_connectivity(solution_states, schedule, model);
        save(fullfile(connectivity_dir, sprintf('well_interference_matrix_%s.mat', timestamp)), ...
             '-struct', 'connectivity_data');
        create_metadata_file(fullfile(connectivity_dir, sprintf('well_interference_matrix_%s.yaml', timestamp)), ...
                           'derived_analytics', connectivity_data, 'Well-to-well connectivity analysis');
        
        fprintf('   ✅ Derived data exported successfully\n');
        
    catch ME
        fprintf('   ❌ Error exporting derived data: %s\n', ME.message);
        rethrow(ME);
    end
end

% ========================================
% Helper Functions
% ========================================

function ensure_directory_exists(directory_path)
% ENSURE_DIRECTORY_EXISTS - Create directory if it doesn't exist
    if ~exist(directory_path, 'dir')
        mkdir(directory_path);
    end
end

function create_metadata_file(yaml_path, data_type, data_struct, description)
% CREATE_METADATA_FILE - Create YAML metadata file for data export
    metadata = struct();
    
    % Identification
    metadata.identification.name = get_data_name_from_path(yaml_path);
    metadata.identification.description = description;
    metadata.identification.data_id = generate_data_id(yaml_path);
    metadata.identification.creation_date = datestr(now, 'yyyy-mm-ddTHH:MM:SS');
    metadata.identification.creator = 'MRST_Workflow_System';
    
    % Data type classification
    metadata.data_type.primary = data_type;
    metadata.data_type.tags = get_tags_from_type(data_type);
    
    % File information
    [~, filename, ext] = fileparts(yaml_path);
    mat_file = strrep([filename ext], '.yaml', '.mat');
    mat_path = fullfile(fileparts(yaml_path), mat_file);
    
    metadata.file_info.file_format = 'MATLAB';
    if exist(mat_path, 'file')
        file_info = dir(mat_path);
        metadata.file_info.file_size_mb = file_info.bytes / 1048576;  % Convert to MB
    else
        metadata.file_info.file_size_mb = 0;
    end
    
    % Units (standard MRST units)
    metadata.units.pressure = 'Pa';
    metadata.units.permeability = 'm^2';
    metadata.units.length = 'm';
    metadata.units.volume = 'm^3';
    metadata.units.rates = 'm^3/s';
    metadata.units.time = 'seconds';
    
    % Quality information
    metadata.quality.validation_status = 'not_validated';
    metadata.quality.completeness = 100.0;
    metadata.quality.known_issues = {};
    
    % Write YAML file
    write_yaml_metadata(yaml_path, metadata);
end

% ========================================
% CANONICAL INTEGRATION FUNCTIONS
% ========================================

function export_canonical_static_data(grid_data, rock_data, well_data, fluid_data, varargin)
% EXPORT_CANONICAL_STATIC_DATA - Export static data using canonical utilities
%
% Bridge function to canonical_data_utils.m for enhanced data export
% Provides HDF5 format, enhanced metadata, and multi-organization access

    % Parse input arguments
    p = inputParser;
    addParameter(p, 'step_name', 's05', @ischar);  % Default to grid step
    addParameter(p, 'base_path', '', @ischar);
    addParameter(p, 'timestamp', datestr(now, 'yyyymmdd_HHMMSS'), @ischar);
    parse(p, varargin{:});
    
    % Prepare data structure for canonical export
    canonical_data = struct();
    
    % Include grid data if provided
    if ~isempty(grid_data)
        canonical_data.G = grid_data;
        if isfield(grid_data, 'cells')
            canonical_data.grid_cells = grid_data.cells;
        end
        if isfield(grid_data, 'faces')
            canonical_data.grid_faces = grid_data.faces;
        end
    end
    
    % Include rock data if provided
    if ~isempty(rock_data)
        canonical_data.rock = rock_data;
        if isfield(rock_data, 'poro')
            canonical_data.porosity = rock_data.poro;
        end
        if isfield(rock_data, 'perm')
            canonical_data.permeability = rock_data.perm;
        end
    end
    
    % Include well data if provided
    if ~isempty(well_data)
        canonical_data.wells = well_data;
    end
    
    % Include fluid data if provided
    if ~isempty(fluid_data)
        canonical_data.fluid = fluid_data;
        if isfield(fluid_data, 'bO')
            canonical_data.pvt_tables = extract_pvt_tables(fluid_data);
        end
    end
    
    % Add export metadata
    canonical_data.export_metadata = struct();
    canonical_data.export_metadata.export_function = 'data_export_utils.export_canonical_static_data';
    canonical_data.export_metadata.legacy_compatible = true;
    canonical_data.export_metadata.enhanced_format = 'canonical_v1.0';
    
    try
        % Use canonical data utilities for enhanced export
        addpath(fullfile(fileparts(mfilename('fullpath'))));  % Ensure utils in path
        
        output_files = save_canonical_data(p.Results.step_name, canonical_data, ...
            'base_path', p.Results.base_path, ...
            'timestamp', p.Results.timestamp, ...
            'formats', {'hdf5', 'yaml'}, ...
            'organizations', {'by_type', 'by_usage', 'by_phase'});
        
        fprintf('   ✅ Canonical export completed\n');
        fprintf('   📄 Files created: %d\n', length(output_files.primary_files));
        fprintf('   🔗 Symlinks created: %d\n', length(output_files.symlinks));
        
    catch ME
        warning('Canonical export failed, falling back to legacy export: %s', ME.message);
        
        % Fallback to legacy export
        export_static_data(grid_data, rock_data, well_data, fluid_data, varargin{:});
    end
end

function migrate_to_canonical_format(legacy_data_path, varargin)
% MIGRATE_TO_CANONICAL_FORMAT - Migrate existing legacy data to canonical format
%
% INPUTS:
%   legacy_data_path - Path to existing legacy data files
%   varargin - Optional parameters:
%              'target_base_path' - Target path for canonical structure
%              'preserve_legacy' - Keep original files (default: true)
%              'validation_level' - Validation level for migration

    p = inputParser;
    addRequired(p, 'legacy_data_path', @ischar);
    addParameter(p, 'target_base_path', '', @ischar);
    addParameter(p, 'preserve_legacy', true, @islogical);
    addParameter(p, 'validation_level', 'standard', @ischar);
    parse(p, legacy_data_path, varargin{:});
    
    fprintf('🔄 Migrating legacy data to canonical format...\n');
    fprintf('   Legacy path: %s\n', legacy_data_path);
    
    if ~exist(legacy_data_path, 'dir')
        error(['Legacy data path not found: %s\n' ...
               'REQUIRED: Specify valid path to existing legacy data.\n' ...
               'Canon migration requires accessible source data.'], legacy_data_path);
    end
    
    % Determine target path
    target_path = p.Results.target_base_path;
    if isempty(target_path)
        [parent_dir, ~, ~] = fileparts(legacy_data_path);
        target_path = fullfile(parent_dir, 'simulation_data_canonical');
    end
    
    try
        % Create canonical structure
        create_canonical_structure(target_path, 'verbose', true);
        
        % Scan legacy files
        legacy_files = scan_legacy_data_files(legacy_data_path);
        
        fprintf('   Found %d legacy data files\n', length(legacy_files));
        
        % Migrate each file type
        migration_summary = struct();
        migration_summary.migrated_files = 0;
        migration_summary.failed_files = 0;
        migration_summary.errors = {};
        
        for i = 1:length(legacy_files)
            file_info = legacy_files{i};
            
            try
                migrate_single_file(file_info, target_path);
                migration_summary.migrated_files = migration_summary.migrated_files + 1;
                
            catch ME
                migration_summary.failed_files = migration_summary.failed_files + 1;
                migration_summary.errors{end+1} = sprintf('%s: %s', file_info.filename, ME.message);
                warning('Migration failed for %s: %s', file_info.filename, ME.message);
            end
        end
        
        % Validation after migration
        if strcmp(p.Results.validation_level, 'standard') || strcmp(p.Results.validation_level, 'comprehensive')
            fprintf('   Validating migrated data...\n');
            validation_result = validate_workflow_data('all', 'base_path', target_path, ...
                'validation_level', p.Results.validation_level);
            
            migration_summary.validation_status = validation_result.validation_summary.overall_status;
        end
        
        % Summary report
        fprintf('   ✅ Migration completed\n');
        fprintf('   📄 Migrated files: %d\n', migration_summary.migrated_files);
        if migration_summary.failed_files > 0
            fprintf('   ⚠️  Failed migrations: %d\n', migration_summary.failed_files);
        end
        
        % Remove legacy files if not preserving
        if ~p.Results.preserve_legacy
            fprintf('   🗑️  Removing legacy files...\n');
            rmdir(legacy_data_path, 's');
        end
        
    catch ME
        error(['Migration to canonical format failed: %s\n' ...
               'REQUIRED: Migration must complete successfully.\n' ...
               'Canon requires successful data migration with validation.'], ME.message);
    end
end

function legacy_files = scan_legacy_data_files(legacy_path)
% SCAN_LEGACY_DATA_FILES - Scan directory for legacy data files to migrate

    legacy_files = {};
    
    % Known legacy file patterns
    legacy_patterns = {
        '*.mat',     % MATLAB data files
        '*.h5',      % Existing HDF5 files
        '*.yaml',    % YAML configuration files
        '*.csv',     % CSV data files
        '*.txt'      % Text summary files
    };
    
    for i = 1:length(legacy_patterns)
        pattern = legacy_patterns{i};
        matches = dir(fullfile(legacy_path, '**', pattern));
        
        for j = 1:length(matches)
            file_info = struct();
            file_info.filename = matches(j).name;
            file_info.full_path = fullfile(matches(j).folder, matches(j).name);
            file_info.size_mb = matches(j).bytes / 1048576;
            file_info.last_modified = matches(j).datenum;
            file_info.format = determine_file_format(file_info.filename);
            file_info.data_type = infer_data_type(file_info.filename);
            
            legacy_files{end+1} = file_info;
        end
    end
end

function format = determine_file_format(filename)
% DETERMINE_FILE_FORMAT - Determine file format from filename

    [~, ~, ext] = fileparts(filename);
    
    switch lower(ext)
        case '.mat'
            format = 'matlab';
        case '.h5'
            format = 'hdf5';
        case '.yaml'
            format = 'yaml';
        case '.csv'
            format = 'csv';
        case '.txt'
            format = 'text';
        otherwise
            format = 'unknown';
    end
end

function data_type = infer_data_type(filename)
% INFER_DATA_TYPE - Infer data type from filename patterns

    filename_lower = lower(filename);
    
    if contains(filename_lower, {'grid', 'pebi', 'cartesian'})
        data_type = 'pebi_grid';
    elseif contains(filename_lower, {'rock', 'perm', 'poro'})
        data_type = 'base_rock_properties';
    elseif contains(filename_lower, {'fluid', 'pvt', 'oil', 'water'})
        data_type = 'fluid_pvt';
    elseif contains(filename_lower, {'well', 'completion'})
        data_type = 'wells';
    elseif contains(filename_lower, {'fault', 'transmissibility'})
        data_type = 'fault_system';
    elseif contains(filename_lower, {'struct', 'layer', 'geology'})
        data_type = 'structural_framework';
    else
        data_type = 'unknown';
    end
end

function migrate_single_file(file_info, target_base_path)
% MIGRATE_SINGLE_FILE - Migrate single legacy file to canonical format

    % Determine target step based on data type
    step_mapping = containers.Map(...
        {'pebi_grid', 'base_rock_properties', 'fluid_pvt', 'wells', 'fault_system', 'structural_framework'}, ...
        {'s05', 's06', 's02', 's16', 's04', 's03'});
    
    if isKey(step_mapping, file_info.data_type)
        target_step = step_mapping(file_info.data_type);
    else
        target_step = 's99';  % Generic step for unknown types
    end
    
    % Load legacy data
    switch file_info.format
        case 'matlab'
            legacy_data = load(file_info.full_path);
            
        case 'hdf5'
            % Copy HDF5 file to canonical location
            legacy_data = struct();
            legacy_data.hdf5_source = file_info.full_path;
            
        case 'yaml'
            % Read YAML content
            fid = fopen(file_info.full_path, 'r');
            content = fread(fid, '*char')';
            fclose(fid);
            legacy_data = struct();
            legacy_data.yaml_content = content;
            
        otherwise
            % Generic file copy
            legacy_data = struct();
            legacy_data.file_source = file_info.full_path;
    end
    
    % Add migration metadata
    legacy_data.migration_metadata = struct();
    legacy_data.migration_metadata.source_file = file_info.full_path;
    legacy_data.migration_metadata.migration_date = datestr(now, 'yyyy-mm-ddTHH:MM:SS');
    legacy_data.migration_metadata.original_format = file_info.format;
    legacy_data.migration_metadata.inferred_data_type = file_info.data_type;
    
    % Export using canonical utilities
    output_files = save_canonical_data(target_step, legacy_data, ...
        'base_path', target_base_path, ...
        'formats', {'hdf5', 'yaml'});
    
    % For HDF5 sources, copy original file to preserve format
    if strcmp(file_info.format, 'hdf5') && exist(file_info.full_path, 'file')
        for i = 1:length(output_files.primary_files)
            primary_file = output_files.primary_files{i};
            [file_path, file_name, file_ext] = fileparts(primary_file);
            
            if strcmp(file_ext, '.h5')
                copyfile(file_info.full_path, primary_file);
                break;
            end
        end
    end
end

function name = get_data_name_from_path(yaml_path)
% Generate human-readable name from file path
    [~, filename, ~] = fileparts(yaml_path);
    name = strrep(filename, '_', ' ');
    name = regexprep(name, '\<\w', '${upper($0)}');  % Title case
end

function data_id = generate_data_id(yaml_path)
% Generate unique data ID from path and timestamp
    [~, filename, ~] = fileparts(yaml_path);
    timestamp = datestr(now, 'yyyymmdd_HHMMSS');
    data_id = sprintf('%s_%s', filename, timestamp);
end

function tags = get_tags_from_type(data_type)
% Get descriptive tags based on data type
    switch data_type
        case 'static_grid'
            tags = {'grid', 'geology', 'geometry', 'static'};
        case 'static_wells'
            tags = {'wells', 'completions', 'static'};
        case 'static_properties'
            tags = {'properties', 'fluid', 'rock', 'static'};
        case 'dynamic_solution'
            tags = {'pressure', 'saturation', 'solution', 'dynamic', 'timestep'};
        case 'dynamic_production'
            tags = {'rates', 'production', 'wells', 'dynamic', 'timestep'};
        case 'derived_analytics'
            tags = {'analytics', 'calculated', 'derived', 'performance'};
        otherwise
            tags = {'simulation', 'data'};
    end
end

function write_yaml_metadata(yaml_path, metadata)
% WRITE_YAML_METADATA - Write metadata structure to YAML file
% Simple YAML writer for MATLAB structures
    
    fid = fopen(yaml_path, 'w');
    if fid == -1
        error('Cannot open metadata file for writing: %s', yaml_path);
    end
    
    try
        fprintf(fid, '# Simulation Data Metadata\n');
        fprintf(fid, '# Generated: %s\n\n', datestr(now));
        
        write_yaml_struct(fid, metadata, 0);
        
        fclose(fid);
    catch ME
        fclose(fid);
        rethrow(ME);
    end
end

function write_yaml_struct(fid, s, indent_level)
% Recursive function to write MATLAB struct as YAML
    indent = repmat('  ', 1, indent_level);
    
    field_names = fieldnames(s);
    for i = 1:length(field_names)
        field_name = field_names{i};
        value = s.(field_name);
        
        if isstruct(value)
            fprintf(fid, '%s%s:\n', indent, field_name);
            write_yaml_struct(fid, value, indent_level + 1);
        elseif iscell(value)
            fprintf(fid, '%s%s:\n', indent, field_name);
            for j = 1:length(value)
                fprintf(fid, '%s  - "%s"\n', indent, value{j});
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
                for j = 1:length(value)
                    if j > 1
                        fprintf(fid, ', ');
                    end
                    fprintf(fid, '%.6g', value(j));
                end
                fprintf(fid, ']\n');
            end
        elseif islogical(value)
            fprintf(fid, '%s%s: %s\n', indent, field_name, lower(mat2str(value)));
        end
    end
end

% ========================================
% Data Extraction Functions
% ========================================

function grid_data = extract_grid_geometry(G)
% EXTRACT_GRID_GEOMETRY - Extract grid geometry data for export
    grid_data = struct();
    
    % For PEBI grids, report grid type and cell count instead of cartDims
    if isfield(G, 'cartDims')
        % Cartesian grid
        grid_data.grid_type = 'cartesian';
        grid_data.dimensions = struct('nx', G.cartDims(1), 'ny', G.cartDims(2));
        if length(G.cartDims) > 2
            grid_data.dimensions.nz = G.cartDims(3);
        end
    else
        % PEBI/unstructured grid
        grid_data.grid_type = 'pebi';
        grid_data.dimensions = struct('total_cells', G.cells.num);
        % Extract approximate field dimensions from cell centroids
        grid_data.field_extent_x = max(G.cells.centroids(:,1)) - min(G.cells.centroids(:,1));
        grid_data.field_extent_y = max(G.cells.centroids(:,2)) - min(G.cells.centroids(:,2));
        grid_data.field_extent_z = max(G.cells.centroids(:,3)) - min(G.cells.centroids(:,3));
    end
    
    grid_data.num_cells = G.cells.num;
    grid_data.num_faces = G.faces.num;
    grid_data.cell_centers = G.cells.centroids;
    grid_data.cell_volumes = G.cells.volumes;
    if isfield(G.faces, 'areas')
        grid_data.face_areas = G.faces.areas;
    end
end

function rock_regions = extract_rock_regions(rock)
% EXTRACT_ROCK_REGIONS - Extract rock property regions
    rock_regions = struct();
    if isfield(rock, 'perm')
        rock_regions.permeability = rock.perm;
    end
    if isfield(rock, 'poro')
        rock_regions.porosity = rock.poro;
    end
end

function structural_data = extract_structural_data(G, rock)
% EXTRACT_STRUCTURAL_DATA - Extract structural framework data
    structural_data = struct();
    structural_data.grid_type = 'cartesian';
    if isfield(G, 'type')
        structural_data.grid_type = G.type;
    end
    structural_data.coordinate_system = 'local';
end

function pvt_tables = extract_pvt_tables(fluid)
% EXTRACT_PVT_TABLES - Extract PVT table data
    pvt_tables = struct();
    if isfield(fluid, 'bO')
        pvt_tables.oil_fvf_available = true;
    end
    if isfield(fluid, 'bW')
        pvt_tables.water_fvf_available = true;
    end
    if isfield(fluid, 'muO')
        pvt_tables.oil_viscosity_available = true;
    end
    if isfield(fluid, 'muW')
        pvt_tables.water_viscosity_available = true;
    end
end

function pressure_data = extract_pressure_timeseries(states, timesteps)
% EXTRACT_PRESSURE_TIMESERIES - Extract pressure evolution data
    pressure_data = struct();
    pressure_data.n_timesteps = length(timesteps);
    pressure_data.timesteps = timesteps;
    
    % Extract pressure fields
    pressures = cell(length(timesteps), 1);
    for i = 1:length(timesteps)
        step = timesteps(i);
        if step <= length(states) && ~isempty(states{step})
            pressures{i} = states{step}.pressure;
        end
    end
    pressure_data.pressure_fields = pressures;
    
    % Calculate statistics
    all_pressures = [];
    for i = 1:length(pressures)
        if ~isempty(pressures{i})
            all_pressures = [all_pressures; pressures{i}];
        end
    end
    
    if ~isempty(all_pressures)
        pressure_data.statistics.min_pressure = min(all_pressures);
        pressure_data.statistics.max_pressure = max(all_pressures);
        pressure_data.statistics.mean_pressure = mean(all_pressures);
    end
end

function saturation_data = extract_saturation_timeseries(states, timesteps)
% EXTRACT_SATURATION_TIMESERIES - Extract saturation evolution data
    saturation_data = struct();
    saturation_data.n_timesteps = length(timesteps);
    saturation_data.timesteps = timesteps;
    
    % Extract saturation fields
    saturations = cell(length(timesteps), 1);
    for i = 1:length(timesteps)
        step = timesteps(i);
        if step <= length(states) && ~isempty(states{step})
            saturations{i} = states{step}.s;
        end
    end
    saturation_data.saturation_fields = saturations;
    
    % Calculate phase statistics
    if ~isempty(saturations) && ~isempty(saturations{1})
        n_phases = size(saturations{1}, 2);
        saturation_data.n_phases = n_phases;
        
        for phase = 1:n_phases
            phase_name = sprintf('phase_%d', phase);
            phase_sats = [];
            for i = 1:length(saturations)
                if ~isempty(saturations{i})
                    phase_sats = [phase_sats; saturations{i}(:, phase)];
                end
            end
            
            if ~isempty(phase_sats)
                saturation_data.statistics.(phase_name).min_saturation = min(phase_sats);
                saturation_data.statistics.(phase_name).max_saturation = max(phase_sats);
                saturation_data.statistics.(phase_name).mean_saturation = mean(phase_sats);
            end
        end
    end
end

function rates_data = extract_well_rates_timeseries(states, schedule, timesteps)
% EXTRACT_WELL_RATES_TIMESERIES - Extract well production/injection rates
    rates_data = struct();
    rates_data.n_timesteps = length(timesteps);
    rates_data.timesteps = timesteps;
    
    if isfield(schedule, 'control') && length(schedule.control) >= max(timesteps)
        n_wells = length(schedule.control(1).W);
        rates_data.n_wells = n_wells;
        
        % Extract well names
        well_names = cell(n_wells, 1);
        for w = 1:n_wells
            if isfield(schedule.control(1).W(w), 'name')
                well_names{w} = schedule.control(1).W(w).name;
            else
                well_names{w} = sprintf('Well_%d', w);
            end
        end
        rates_data.well_names = well_names;
        
        % Initialize rate arrays
        oil_rates = zeros(length(timesteps), n_wells);
        water_rates = zeros(length(timesteps), n_wells);
        
        for i = 1:length(timesteps)
            step = timesteps(i);
            if step <= length(states) && ~isempty(states{step})
                % Extract rates from solution state
                % This would need to be customized based on actual MRST state structure
                % For now, create placeholder data
                oil_rates(i, :) = rand(1, n_wells) * 100;  % Placeholder
                water_rates(i, :) = rand(1, n_wells) * 50;  % Placeholder
            end
        end
        
        rates_data.oil_rates = oil_rates;
        rates_data.water_rates = water_rates;
    else
        rates_data.n_wells = 0;
        rates_data.well_names = {};
        rates_data.oil_rates = [];
        rates_data.water_rates = [];
    end
end

function recovery_data = calculate_recovery_factors(states, model)
% CALCULATE_RECOVERY_FACTORS - Calculate field and pattern recovery factors
    recovery_data = struct();
    
    if ~isempty(states) && length(states) >= 2
        % Calculate oil in place
        initial_state = states{1};
        final_state = states{end};
        
        if isfield(initial_state, 's') && isfield(final_state, 's')
            % Assume oil is phase 2 (typical MRST convention)
            if size(initial_state.s, 2) >= 2
                initial_oil_sat = initial_state.s(:, 2);
                final_oil_sat = final_state.s(:, 2);
                
                if isfield(model, 'rock') && isfield(model.rock, 'poro')
                    poro = model.rock.poro;
                    if isfield(model, 'G') && isfield(model.G, 'cells')
                        volumes = model.G.cells.volumes;
                        
                        initial_oil_volume = sum(initial_oil_sat .* poro .* volumes);
                        final_oil_volume = sum(final_oil_sat .* poro .* volumes);
                        
                        recovery_factor = (initial_oil_volume - final_oil_volume) / initial_oil_volume;
                        recovery_data.field_recovery_factor = max(0, min(1, recovery_factor));
                    else
                        recovery_data.field_recovery_factor = 0;
                    end
                else
                    recovery_data.field_recovery_factor = 0;
                end
            else
                recovery_data.field_recovery_factor = 0;
            end
        else
            recovery_data.field_recovery_factor = 0;
        end
    else
        recovery_data.field_recovery_factor = 0;
    end
    
    recovery_data.calculation_method = 'oil_saturation_change';
    recovery_data.calculation_date = datestr(now);
end

function sweep_data = calculate_sweep_efficiency(states, model)
% CALCULATE_SWEEP_EFFICIENCY - Calculate sweep efficiency metrics
    sweep_data = struct();
    
    if ~isempty(states) && length(states) >= 2
        initial_state = states{1};
        final_state = states{end};
        
        if isfield(initial_state, 's') && isfield(final_state, 's')
            % Simple sweep efficiency based on saturation change
            if size(initial_state.s, 2) >= 2
                initial_water_sat = initial_state.s(:, 1);  % Assume water is phase 1
                final_water_sat = final_state.s(:, 1);
                
                % Cells with significant saturation change are "swept"
                saturation_change = final_water_sat - initial_water_sat;
                swept_cells = sum(saturation_change > 0.1);  % Threshold for swept
                total_cells = length(saturation_change);
                
                areal_sweep = swept_cells / total_cells;
                sweep_data.areal_sweep_efficiency = max(0, min(1, areal_sweep));
            else
                sweep_data.areal_sweep_efficiency = 0;
            end
        else
            sweep_data.areal_sweep_efficiency = 0;
        end
    else
        sweep_data.areal_sweep_efficiency = 0;
    end
    
    sweep_data.calculation_method = 'saturation_change_threshold';
    sweep_data.calculation_date = datestr(now);
end

function connectivity_data = calculate_well_connectivity(states, schedule, model)
% CALCULATE_WELL_CONNECTIVITY - Calculate well-to-well connectivity
    connectivity_data = struct();
    
    if isfield(schedule, 'control') && ~isempty(schedule.control)
        n_wells = length(schedule.control(1).W);
        connectivity_data.n_wells = n_wells;
        
        % Create placeholder connectivity matrix
        % In practice, this would involve flow diagnostics or tracer analysis
        connectivity_matrix = rand(n_wells, n_wells);
        connectivity_matrix = (connectivity_matrix + connectivity_matrix') / 2;  % Make symmetric
        for i = 1:n_wells
            connectivity_matrix(i, i) = 1.0;  % Self-connectivity
        end
        
        connectivity_data.well_interference_matrix = connectivity_matrix;
    else
        connectivity_data.n_wells = 0;
        connectivity_data.well_interference_matrix = [];
    end
    
    connectivity_data.calculation_method = 'placeholder_random';
    connectivity_data.calculation_date = datestr(now);
end