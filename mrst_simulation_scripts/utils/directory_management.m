function directory_management()
% DIRECTORY_MANAGEMENT - Utilities for canonical directory structure management
%
% This utility provides functions for creating and managing the canonical
% Simulation Data Catalog directory structure:
% - by_type/ (static, dynamic, solver, derived, ml_features)
% - by_usage/ (simulation_setup, ML_training, visualization)  
% - by_phase/ (pre_simulation, simulation, post_analysis)
% - metadata/ (schemas, validation reports)
%
% Features:
% - Complete canonical structure creation
% - Symlink management for multi-organization access
% - Directory validation and repair
% - Structure documentation generation
% - Canon-First error handling (fail fast)
%
% Requires: MRST
%
% Author: Claude Code AI System
% Date: August 15, 2025

end

function create_canonical_structure(base_path, varargin)
% CREATE_CANONICAL_STRUCTURE - Creates complete canonical directory structure
%
% INPUTS:
%   base_path - Base directory for simulation_data (default: auto-detect)
%   varargin  - Optional name-value pairs:
%               'force_recreate' - true/false to recreate existing structure (default: false)
%               'create_symlinks' - true/false to create organization symlinks (default: true)
%               'create_metadata' - true/false to create metadata schemas (default: true)
%               'verbose' - true/false for detailed output (default: true)
%
% OUTPUTS:
%   Creates complete canonical directory structure following
%   Simulation Data Catalog specifications
%
% CANONICAL STRUCTURE:
%   data/simulation_data/
%   ├── by_type/           # Primary organization by data characteristics
%   │   ├── static/        # Time-invariant data
%   │   ├── dynamic/       # Time-varying simulation results
%   │   ├── solver/        # Numerical solver diagnostics
%   │   ├── derived/       # Calculated/analyzed data
%   │   └── ml_features/   # ML-ready feature sets
%   ├── by_usage/          # Secondary organization by application
%   │   ├── simulation_setup/
%   │   ├── ML_training/
%   │   └── visualization/
%   ├── by_phase/          # Tertiary organization by project phase
%   │   ├── pre_simulation/
%   │   ├── simulation/
%   │   └── post_analysis/
%   └── metadata/          # Schemas and documentation
%
% CANON-FIRST VALIDATION:
%   Fails fast if base_path cannot be created or accessed
%   No fallbacks for directory creation failures
%   Clear error messages directing to canon documentation

    % Parse input arguments
    p = inputParser;
    addRequired(p, 'base_path', @ischar);
    addParameter(p, 'force_recreate', false, @islogical);
    addParameter(p, 'create_symlinks', true, @islogical);
    addParameter(p, 'create_metadata', true, @islogical);
    addParameter(p, 'verbose', true, @islogical);
    parse(p, base_path, varargin{:});
    
    % Validate base path
    if isempty(base_path)
        error(['Empty base_path provided.\n' ...
               'REQUIRED: Specify valid base directory for canonical structure.\n' ...
               'Canon requires explicit path specification - no defaults allowed.']);
    end
    
    % Determine simulation_data path
    if ~contains(base_path, 'simulation_data')
        sim_data_path = fullfile(base_path, 'simulation_data');
    else
        sim_data_path = base_path;
    end
    
    if p.Results.verbose
        fprintf('🏗️  Creating canonical directory structure...\n');
        fprintf('   Base path: %s\n', sim_data_path);
    end
    
    % Check if structure already exists
    if exist(sim_data_path, 'dir') && ~p.Results.force_recreate
        if p.Results.verbose
            fprintf('   Directory already exists. Use force_recreate=true to rebuild.\n');
        end
        
        % Validate existing structure
        validation_result = validate_directory_structure(sim_data_path);
        if validation_result.structure_complete
            if p.Results.verbose
                fprintf('   ✅ Existing structure is canonical compliant\n');
            end
            return;
        else
            if p.Results.verbose
                fprintf('   ⚠️  Existing structure incomplete, completing...\n');
            end
        end
    end
    
    try
        % Create primary by_type organization
        if p.Results.verbose
            fprintf('   Creating by_type organization...\n');
        end
        create_by_type_structure(sim_data_path);
        
        % Create secondary by_usage organization
        if p.Results.verbose
            fprintf('   Creating by_usage organization...\n');
        end
        create_by_usage_structure(sim_data_path);
        
        % Create tertiary by_phase organization
        if p.Results.verbose
            fprintf('   Creating by_phase organization...\n');
        end
        create_by_phase_structure(sim_data_path);
        
        % Create metadata infrastructure
        if p.Results.create_metadata
            if p.Results.verbose
                fprintf('   Creating metadata infrastructure...\n');
            end
            create_metadata_structure(sim_data_path);
        end
        
        % Create README files for documentation
        create_structure_documentation(sim_data_path);
        
        % Create example symlinks if requested
        if p.Results.create_symlinks
            if p.Results.verbose
                fprintf('   Creating example symlinks...\n');
            end
            create_example_symlinks(sim_data_path);
        end
        
        % Final validation
        validation_result = validate_directory_structure(sim_data_path);
        
        if validation_result.structure_complete
            if p.Results.verbose
                fprintf('   ✅ Canonical structure created successfully\n');
                fprintf('   📁 Total directories: %d\n', validation_result.total_directories);
                fprintf('   🔗 Symlinks ready: %s\n', string(p.Results.create_symlinks));
                fprintf('   📋 Metadata schemas: %s\n', string(p.Results.create_metadata));
            end
        else
            error(['Canonical structure creation incomplete.\n' ...
                   'REQUIRED: All canonical directories must be created successfully.\n' ...
                   'Canon specification requires complete directory hierarchy.\n' ...
                   'Missing: %s'], strjoin(validation_result.missing_directories, ', '));
        end
        
    catch ME
        error(['Failed to create canonical structure: %s\n' ...
               'REQUIRED: Directory creation must succeed for canonical compliance.\n' ...
               'Canon requires write access and proper permissions.\n' ...
               'Check base path permissions and disk space.'], ME.message);
    end
end

function create_by_type_structure(base_path)
% CREATE_BY_TYPE_STRUCTURE - Create primary data organization by intrinsic type
%
% Based on STEP_DATA_OUTPUT_MAPPING.md canonical specifications

    by_type_path = fullfile(base_path, 'by_type');
    ensure_directory_exists(by_type_path);
    
    % Static data categories
    static_path = fullfile(by_type_path, 'static');
    ensure_directory_exists(static_path);
    
    % Static subcategories from canonical mapping
    static_subcategories = {
        'geometry',           % Grid data (s05)
        'geology',           % Rock properties, structural framework, faults (s03, s04, s06-s08)
        'fluid_properties',  % PVT data (s02)
        'scal_properties',   % Relative permeability, capillary pressure (s09)
        'wells',            % Well definitions and completions
        'initial_conditions' % Initial pressure and saturation
    };
    
    for i = 1:length(static_subcategories)
        subcat_path = fullfile(static_path, static_subcategories{i});
        ensure_directory_exists(subcat_path);
    end
    
    % Dynamic data categories
    dynamic_path = fullfile(by_type_path, 'dynamic');
    ensure_directory_exists(dynamic_path);
    
    % Dynamic subcategories for simulation results
    dynamic_subcategories = {
        'pressures',      % Pressure field evolution
        'saturations',    % Saturation field evolution
        'rates',          % Well production/injection rates
        'states',         % Complete solution states
        'transport'       % Flow transport calculations
    };
    
    for i = 1:length(dynamic_subcategories)
        subcat_path = fullfile(dynamic_path, dynamic_subcategories{i});
        ensure_directory_exists(subcat_path);
    end
    
    % Solver internal data categories  
    solver_path = fullfile(by_type_path, 'solver');
    ensure_directory_exists(solver_path);
    
    % Solver subcategories for numerical diagnostics
    solver_subcategories = {
        'convergence',    % Newton iteration data, residual norms
        'performance',    % Solver timing and performance metrics
        'diagnostics',    % Numerical stability indicators
        'failures'        % Failed timesteps and recovery information
    };
    
    for i = 1:length(solver_subcategories)
        subcat_path = fullfile(solver_path, solver_subcategories{i});
        ensure_directory_exists(subcat_path);
    end
    
    % Derived/calculated data categories
    derived_path = fullfile(by_type_path, 'derived');
    ensure_directory_exists(derived_path);
    
    % Derived subcategories for analysis results
    derived_subcategories = {
        'recovery_factors',   % Field and pattern recovery analysis
        'sweep_efficiency',   % Displacement efficiency metrics
        'connectivity',       % Well-to-well connectivity analysis
        'flow_diagnostics',   % Advanced flow analysis
        'sensitivity'         % Parameter sensitivity analysis
    };
    
    for i = 1:length(derived_subcategories)
        subcat_path = fullfile(derived_path, derived_subcategories{i});
        ensure_directory_exists(subcat_path);
    end
    
    % ML-ready features categories
    ml_features_path = fullfile(by_type_path, 'ml_features');
    ensure_directory_exists(ml_features_path);
    
    % ML features subcategories for machine learning applications
    ml_subcategories = {
        'static_features',    % Time-invariant features from static data
        'dynamic_features',   % Time-varying features from simulation
        'temporal_features',  % Time-based feature engineering (lags, derivatives)
        'spatial_features',   % Spatial correlation and connectivity features
        'engineering_features' % Derived features for specific ML applications
    };
    
    for i = 1:length(ml_subcategories)
        subcat_path = fullfile(ml_features_path, ml_subcategories{i});
        ensure_directory_exists(subcat_path);
    end
    
    % Control/environment data
    control_path = fullfile(by_type_path, 'control');
    ensure_directory_exists(control_path);
end

function create_by_usage_structure(base_path)
% CREATE_BY_USAGE_STRUCTURE - Create secondary organization by application purpose

    by_usage_path = fullfile(base_path, 'by_usage');
    ensure_directory_exists(by_usage_path);
    
    % Simulation setup usage category
    sim_setup_path = fullfile(by_usage_path, 'simulation_setup');
    ensure_directory_exists(sim_setup_path);
    
    % Simulation setup subcategories
    sim_setup_subcategories = {
        'grid_definition',    % Grid files for simulation
        'rock_properties',    % Rock property files for simulation
        'fluid_definition',   % Fluid property files for simulation
        'well_configuration', % Well definition files for simulation
        'initial_state',      % Initial conditions for simulation
        'schedule_definition' % Production schedule files
    };
    
    for i = 1:length(sim_setup_subcategories)
        subcat_path = fullfile(sim_setup_path, sim_setup_subcategories{i});
        ensure_directory_exists(subcat_path);
    end
    
    % ML training usage category
    ml_training_path = fullfile(by_usage_path, 'ML_training');
    ensure_directory_exists(ml_training_path);
    
    % ML training subcategories
    ml_training_subcategories = {
        'features',           % Feature matrices for ML
        'targets',           % Target variables for supervised learning
        'training_sets',     % Training dataset splits
        'validation_sets',   % Validation dataset splits
        'test_sets',         % Test dataset splits
        'metadata'           % ML experiment metadata
    };
    
    for i = 1:length(ml_training_subcategories)
        subcat_path = fullfile(ml_training_path, ml_training_subcategories{i});
        ensure_directory_exists(subcat_path);
    end
    
    % Visualization usage category
    visualization_path = fullfile(by_usage_path, 'visualization');
    ensure_directory_exists(visualization_path);
    
    % Visualization subcategories
    viz_subcategories = {
        'grid_plots',        % Grid visualization data
        'field_maps',        % Pressure/saturation field plots
        'well_plots',        % Well production plots
        'time_series',       % Time series plot data
        'cross_sections',    % Cross-sectional data
        'animations'         % Animation frame data
    };
    
    for i = 1:length(viz_subcategories)
        subcat_path = fullfile(visualization_path, viz_subcategories{i});
        ensure_directory_exists(subcat_path);
    end
    
    % Geological modeling usage category
    geological_modeling_path = fullfile(by_usage_path, 'geological_modeling');
    ensure_directory_exists(geological_modeling_path);
    
    % Geological modeling subcategories
    geo_subcategories = {
        'structural_model',   % Structural framework for geological analysis
        'property_model',     % Rock property models
        'fault_model',        % Fault system models
        'validation',         % Geological model validation
        'uncertainty'         % Geological uncertainty analysis
    };
    
    for i = 1:length(geo_subcategories)
        subcat_path = fullfile(geological_modeling_path, geo_subcategories{i});
        ensure_directory_exists(subcat_path);
    end
end

function create_by_phase_structure(base_path)
% CREATE_BY_PHASE_STRUCTURE - Create tertiary organization by project timeline phase

    by_phase_path = fullfile(base_path, 'by_phase');
    ensure_directory_exists(by_phase_path);
    
    % Pre-simulation phase (s01-s09)
    pre_sim_path = fullfile(by_phase_path, 'pre_simulation');
    ensure_directory_exists(pre_sim_path);
    
    % Pre-simulation subcategories
    pre_sim_subcategories = {
        'environment',       % MRST environment setup (s01)
        'fluid',            % Fluid property definition (s02)
        'geology',          % Structural framework and faults (s03, s04)
        'grid',             % Grid generation (s05)
        'rock',             % Rock property definition (s06-s08)
        'scal',             % Relative permeability/capillary pressure (s09)
        'wells',            % Well placement and completion
        'initialization',   % Initial conditions setup
        'validation'        % Pre-simulation validation
    };
    
    for i = 1:length(pre_sim_subcategories)
        subcat_path = fullfile(pre_sim_path, pre_sim_subcategories{i});
        ensure_directory_exists(subcat_path);
    end
    
    % Simulation phase (s10-s23)
    simulation_path = fullfile(by_phase_path, 'simulation');
    ensure_directory_exists(simulation_path);
    
    % Simulation subcategories
    sim_subcategories = {
        'timesteps',        % Individual timestep results
        'phases',           % Development phase results (Phase 1-6)
        'diagnostics',      % Runtime diagnostics and monitoring
        'checkpoints',      % Simulation restart checkpoints
        'convergence',      % Convergence monitoring
        'performance'       % Simulation performance metrics
    };
    
    for i = 1:length(sim_subcategories)
        subcat_path = fullfile(simulation_path, sim_subcategories{i});
        ensure_directory_exists(subcat_path);
    end
    
    % Post-analysis phase (s24-s25)
    post_analysis_path = fullfile(by_phase_path, 'post_analysis');
    ensure_directory_exists(post_analysis_path);
    
    % Post-analysis subcategories
    post_analysis_subcategories = {
        'results_analysis',  % Comprehensive results analysis
        'recovery_analysis', % Recovery factor analysis
        'performance_analysis', % Field performance analysis
        'optimization',      % Parameter optimization studies
        'reporting',         % Final reports and summaries
        'ml_preparation'     % ML-ready dataset preparation
    };
    
    for i = 1:length(post_analysis_subcategories)
        subcat_path = fullfile(post_analysis_path, post_analysis_subcategories{i});
        ensure_directory_exists(subcat_path);
    end
    
    % Simulation-ready phase (final inputs)
    sim_ready_path = fullfile(by_phase_path, 'simulation_ready');
    ensure_directory_exists(sim_ready_path);
end

function create_metadata_structure(base_path)
% CREATE_METADATA_STRUCTURE - Create metadata infrastructure

    metadata_path = fullfile(base_path, 'metadata');
    ensure_directory_exists(metadata_path);
    
    % Schemas subdirectory for YAML schemas
    schemas_path = fullfile(metadata_path, 'schemas');
    ensure_directory_exists(schemas_path);
    
    % Create canonical metadata schemas
    create_metadata_schemas(schemas_path);
    
    % Validation reports subdirectory
    validation_path = fullfile(metadata_path, 'validation');
    ensure_directory_exists(validation_path);
    
    % Documentation subdirectory
    docs_path = fullfile(metadata_path, 'documentation');
    ensure_directory_exists(docs_path);
    
    % Catalogs subdirectory for data catalogs
    catalogs_path = fullfile(metadata_path, 'catalogs');
    ensure_directory_exists(catalogs_path);
end

function create_metadata_schemas(schemas_path)
% CREATE_METADATA_SCHEMAS - Create YAML schemas for canonical metadata

    % Data identification schema
    identification_schema = struct();
    identification_schema.schema_type = 'data_identification';
    identification_schema.required_fields = {
        'name', 'description', 'data_id', 'creation_date', 'creator'
    };
    identification_schema.optional_fields = {
        'version', 'license', 'citation', 'contact'
    };
    
    write_schema_file(fullfile(schemas_path, 'identification_schema.yaml'), identification_schema);
    
    % Data type schema
    data_type_schema = struct();
    data_type_schema.schema_type = 'data_type_classification';
    data_type_schema.required_fields = {
        'primary', 'category', 'subcategory', 'tags'
    };
    data_type_schema.valid_categories = {
        'static', 'dynamic', 'solver', 'derived', 'ml_features', 'control'
    };
    
    write_schema_file(fullfile(schemas_path, 'data_type_schema.yaml'), data_type_schema);
    
    % File information schema
    file_info_schema = struct();
    file_info_schema.schema_type = 'file_information';
    file_info_schema.required_fields = {
        'file_path', 'file_format', 'file_size_mb', 'last_modified'
    };
    file_info_schema.supported_formats = {
        'hdf5', 'yaml', 'parquet', 'csv', 'mat', 'json'
    };
    
    write_schema_file(fullfile(schemas_path, 'file_info_schema.yaml'), file_info_schema);
    
    % Quality information schema
    quality_schema = struct();
    quality_schema.schema_type = 'data_quality';
    quality_schema.required_fields = {
        'validation_status', 'completeness', 'known_issues'
    };
    quality_schema.validation_levels = {
        'not_validated', 'basic_validation', 'comprehensive_validation', 'certified'
    };
    
    write_schema_file(fullfile(schemas_path, 'quality_schema.yaml'), quality_schema);
end

function write_schema_file(file_path, schema_struct)
% WRITE_SCHEMA_FILE - Write schema structure to YAML file

    fid = fopen(file_path, 'w');
    if fid == -1
        error(['Cannot create schema file: %s\n' ...
               'REQUIRED: Schema creation must succeed for canonical compliance.\n' ...
               'Canon requires complete metadata infrastructure.'], file_path);
    end
    
    try
        fprintf(fid, '# Canonical Metadata Schema\n');
        fprintf(fid, '# Generated: %s\n\n', datestr(now, 'yyyy-mm-ddTHH:MM:SS'));
        
        write_yaml_structure(fid, schema_struct, 0);
        
        fclose(fid);
    catch ME
        fclose(fid);
        error('Error writing schema file %s: %s', file_path, ME.message);
    end
end

function create_structure_documentation(base_path)
% CREATE_STRUCTURE_DOCUMENTATION - Create README files documenting structure

    % Main README for simulation_data
    main_readme = fullfile(base_path, 'README.md');
    create_main_readme(main_readme);
    
    % by_type README
    by_type_readme = fullfile(base_path, 'by_type', 'README.md');
    create_by_type_readme(by_type_readme);
    
    % by_usage README
    by_usage_readme = fullfile(base_path, 'by_usage', 'README.md');
    create_by_usage_readme(by_usage_readme);
    
    % by_phase README
    by_phase_readme = fullfile(base_path, 'by_phase', 'README.md');
    create_by_phase_readme(by_phase_readme);
    
    % metadata README
    metadata_readme = fullfile(base_path, 'metadata', 'README.md');
    create_metadata_readme(metadata_readme);
end

function create_main_readme(file_path)
% CREATE_MAIN_README - Create main README for simulation_data

    fid = fopen(file_path, 'w');
    if fid ~= -1
        fprintf(fid, '# MRST Simulation Data Catalog\n\n');
        fprintf(fid, 'Canonical data organization for Eagle West Field MRST simulation workflow.\n\n');
        fprintf(fid, '## Organization Strategies\n\n');
        fprintf(fid, '- **by_type/**: Primary organization by intrinsic data characteristics\n');
        fprintf(fid, '- **by_usage/**: Secondary organization by application purpose\n');
        fprintf(fid, '- **by_phase/**: Tertiary organization by project timeline\n');
        fprintf(fid, '- **metadata/**: Schemas, validation reports, and documentation\n\n');
        fprintf(fid, '## Data Access\n\n');
        fprintf(fid, 'Data is stored in `by_type/` with symlinks in `by_usage/` and `by_phase/` for alternative access patterns.\n\n');
        fprintf(fid, '## Canonical Compliance\n\n');
        fprintf(fid, 'This structure follows the Simulation Data Catalog canon documented in:\n');
        fprintf(fid, '`obsidian-vault/Planning/Simulation_Data_Catalog/STEP_DATA_OUTPUT_MAPPING.md`\n\n');
        fprintf(fid, 'Generated: %s\n', datestr(now, 'yyyy-mm-dd HH:MM:SS'));
        fclose(fid);
    end
end

function create_by_type_readme(file_path)
% CREATE_BY_TYPE_README - Create README for by_type organization

    fid = fopen(file_path, 'w');
    if fid ~= -1
        fprintf(fid, '# Data Organization by Type\n\n');
        fprintf(fid, 'Primary data organization based on intrinsic data characteristics.\n\n');
        fprintf(fid, '## Categories\n\n');
        fprintf(fid, '- **static/**: Time-invariant data (grid, rock properties, fluid properties)\n');
        fprintf(fid, '- **dynamic/**: Time-varying simulation results (pressure, saturation, rates)\n');
        fprintf(fid, '- **solver/**: Numerical solver diagnostics and performance data\n');
        fprintf(fid, '- **derived/**: Calculated and analyzed data (recovery factors, connectivity)\n');
        fprintf(fid, '- **ml_features/**: ML-ready feature sets for machine learning applications\n');
        fprintf(fid, '- **control/**: Environment and session control data\n\n');
        fprintf(fid, 'Generated: %s\n', datestr(now, 'yyyy-mm-dd HH:MM:SS'));
        fclose(fid);
    end
end

function create_by_usage_readme(file_path)
% CREATE_BY_USAGE_README - Create README for by_usage organization

    fid = fopen(file_path, 'w');
    if fid ~= -1
        fprintf(fid, '# Data Organization by Usage\n\n');
        fprintf(fid, 'Secondary data organization based on application purpose.\n\n');
        fprintf(fid, '## Usage Categories\n\n');
        fprintf(fid, '- **simulation_setup/**: Data files required for MRST simulation runs\n');
        fprintf(fid, '- **ML_training/**: Feature matrices and datasets for machine learning\n');
        fprintf(fid, '- **visualization/**: Data prepared for plotting and visualization\n');
        fprintf(fid, '- **geological_modeling/**: Data for geological analysis and modeling\n\n');
        fprintf(fid, '## Access Pattern\n\n');
        fprintf(fid, 'Files are symlinks pointing to primary storage in `../by_type/`\n\n');
        fprintf(fid, 'Generated: %s\n', datestr(now, 'yyyy-mm-dd HH:MM:SS'));
        fclose(fid);
    end
end

function create_by_phase_readme(file_path)
% CREATE_BY_PHASE_README - Create README for by_phase organization

    fid = fopen(file_path, 'w');
    if fid ~= -1
        fprintf(fid, '# Data Organization by Project Phase\n\n');
        fprintf(fid, 'Tertiary data organization based on project timeline.\n\n');
        fprintf(fid, '## Project Phases\n\n');
        fprintf(fid, '- **pre_simulation/**: Setup data (s01-s09) - grid, rock, fluid, wells\n');
        fprintf(fid, '- **simulation/**: Runtime data (s10-s23) - timesteps, diagnostics, checkpoints\n');
        fprintf(fid, '- **post_analysis/**: Analysis results (s24-s25) - recovery analysis, reporting\n');
        fprintf(fid, '- **simulation_ready/**: Final inputs ready for simulation execution\n\n');
        fprintf(fid, '## Workflow Mapping\n\n');
        fprintf(fid, 'Each directory corresponds to major workflow phases of the Eagle West Field simulation.\n\n');
        fprintf(fid, 'Generated: %s\n', datestr(now, 'yyyy-mm-dd HH:MM:SS'));
        fclose(fid);
    end
end

function create_metadata_readme(file_path)
% CREATE_METADATA_README - Create README for metadata infrastructure

    fid = fopen(file_path, 'w');
    if fid ~= -1
        fprintf(fid, '# Metadata Infrastructure\n\n');
        fprintf(fid, 'Comprehensive metadata system for canonical data management.\n\n');
        fprintf(fid, '## Components\n\n');
        fprintf(fid, '- **schemas/**: YAML schemas defining metadata structure\n');
        fprintf(fid, '- **validation/**: Validation reports and quality assessments\n');
        fprintf(fid, '- **documentation/**: Structure documentation and guides\n');
        fprintf(fid, '- **catalogs/**: Data catalogs and inventories\n\n');
        fprintf(fid, '## Metadata Standards\n\n');
        fprintf(fid, 'All data files include YAML metadata following canonical schemas.\n\n');
        fprintf(fid, 'Generated: %s\n', datestr(now, 'yyyy-mm-dd HH:MM:SS'));
        fclose(fid);
    end
end

function create_example_symlinks(base_path)
% CREATE_EXAMPLE_SYMLINKS - Create example symlinks to demonstrate organization
%
% Creates placeholder symlinks to show how multi-organization access works

    % Example: Grid data accessible from multiple organizations
    grid_source = fullfile(base_path, 'by_type', 'static', 'geometry');
    
    % Symlink in simulation_setup
    grid_sim_link = fullfile(base_path, 'by_usage', 'simulation_setup', 'grid_definition');
    create_organizational_symlink(grid_source, grid_sim_link, 'example_grid.h5');
    
    % Symlink in pre_simulation phase
    grid_phase_link = fullfile(base_path, 'by_phase', 'pre_simulation', 'grid');
    create_organizational_symlink(grid_source, grid_phase_link, 'example_grid.h5');
    
    % Example: Rock properties accessible from multiple organizations
    rock_source = fullfile(base_path, 'by_type', 'static', 'geology');
    
    % Symlink in simulation_setup
    rock_sim_link = fullfile(base_path, 'by_usage', 'simulation_setup', 'rock_properties');
    create_organizational_symlink(rock_source, rock_sim_link, 'example_rock.h5');
    
    % Symlink in geological_modeling
    rock_geo_link = fullfile(base_path, 'by_usage', 'geological_modeling', 'property_model');
    create_organizational_symlink(rock_source, rock_geo_link, 'example_rock.h5');
    
    % Create placeholder files to demonstrate structure
    create_placeholder_files(base_path);
end

function create_organizational_symlink(source_dir, target_dir, filename)
% CREATE_ORGANIZATIONAL_SYMLINK - Create symlink between organizational strategies

    % Create placeholder file in source if it doesn't exist
    source_file = fullfile(source_dir, filename);
    if ~exist(source_file, 'file')
        create_placeholder_file(source_file, 'Example data file for canonical structure demonstration');
    end
    
    % Create symlink in target directory
    target_file = fullfile(target_dir, filename);
    
    if exist(target_file, 'file')
        delete(target_file);
    end
    
    try
        if isunix || ismac
            % Unix/Mac: use relative path for symlink
            rel_path = get_relative_path(source_file, target_dir);
            system_cmd = sprintf('ln -s "%s" "%s"', rel_path, target_file);
            [status, ~] = system(system_cmd);
            
            if status ~= 0
                % Fallback: copy file
                copyfile(source_file, target_file);
            end
        else
            % Windows: copy file (admin rights required for symlinks)
            copyfile(source_file, target_file);
        end
    catch ME
        warning('Could not create organizational symlink: %s', ME.message);
    end
end

function create_placeholder_files(base_path)
% CREATE_PLACEHOLDER_FILES - Create placeholder files for structure demonstration

    % Placeholder files with descriptions
    placeholders = {
        {'by_type/static/geometry/example_grid.h5', 'Example grid data (PEBI grid structure)'};
        {'by_type/static/geology/example_rock.h5', 'Example rock properties (porosity, permeability)'};
        {'by_type/static/fluid_properties/example_fluid.h5', 'Example fluid properties (PVT data)'};
        {'by_type/static/wells/example_wells.h5', 'Example well configuration'};
        {'by_type/dynamic/pressures/example_pressure.h5', 'Example pressure evolution data'};
        {'by_type/solver/convergence/example_convergence.h5', 'Example solver convergence data'};
        {'by_type/derived/recovery_factors/example_recovery.h5', 'Example recovery factor analysis'};
        {'by_type/ml_features/static_features/example_features.parquet', 'Example ML feature matrix'};
        {'metadata/schemas/example_schema.yaml', 'Example metadata schema'}
    };
    
    for i = 1:length(placeholders)
        file_info = placeholders{i};
        file_path = fullfile(base_path, file_info{1});
        description = file_info{2};
        
        create_placeholder_file(file_path, description);
    end
end

function create_placeholder_file(file_path, description)
% CREATE_PLACEHOLDER_FILE - Create a small placeholder file with description

    [file_dir, ~, ext] = fileparts(file_path);
    ensure_directory_exists(file_dir);
    
    fid = fopen(file_path, 'w');
    if fid ~= -1
        switch ext
            case '.yaml'
                fprintf(fid, '# Placeholder file for canonical structure\n');
                fprintf(fid, 'description: "%s"\n', description);
                fprintf(fid, 'created: "%s"\n', datestr(now, 'yyyy-mm-ddTHH:MM:SS'));
                fprintf(fid, 'type: "placeholder"\n');
                
            case '.h5'
                % For HDF5, create text placeholder
                fprintf(fid, '# HDF5 Placeholder\n');
                fprintf(fid, '# %s\n', description);
                fprintf(fid, '# Created: %s\n', datestr(now, 'yyyy-mm-dd HH:MM:SS'));
                
            case '.parquet'
                % For Parquet, create text placeholder
                fprintf(fid, '# Parquet Placeholder\n');
                fprintf(fid, '# %s\n', description);
                fprintf(fid, '# Created: %s\n', datestr(now, 'yyyy-mm-dd HH:MM:SS'));
                
            otherwise
                fprintf(fid, '# Placeholder file\n');
                fprintf(fid, '# %s\n', description);
                fprintf(fid, '# Created: %s\n', datestr(now, 'yyyy-mm-dd HH:MM:SS'));
        end
        fclose(fid);
    end
end

function validation_result = validate_directory_structure(base_path)
% VALIDATE_DIRECTORY_STRUCTURE - Validate canonical structure completeness

    validation_result = struct();
    validation_result.structure_complete = false;
    validation_result.missing_directories = {};
    validation_result.total_directories = 0;
    
    % Define required directories from canonical specification
    required_directories = {
        'by_type',
        'by_type/static',
        'by_type/static/geometry',
        'by_type/static/geology', 
        'by_type/static/fluid_properties',
        'by_type/static/scal_properties',
        'by_type/static/wells',
        'by_type/static/initial_conditions',
        'by_type/dynamic',
        'by_type/dynamic/pressures',
        'by_type/dynamic/saturations',
        'by_type/dynamic/rates',
        'by_type/dynamic/states',
        'by_type/dynamic/transport',
        'by_type/solver',
        'by_type/solver/convergence',
        'by_type/solver/performance',
        'by_type/solver/diagnostics',
        'by_type/solver/failures',
        'by_type/derived',
        'by_type/derived/recovery_factors',
        'by_type/derived/sweep_efficiency',
        'by_type/derived/connectivity',
        'by_type/derived/flow_diagnostics',
        'by_type/derived/sensitivity',
        'by_type/ml_features',
        'by_type/ml_features/static_features',
        'by_type/ml_features/dynamic_features',
        'by_type/ml_features/temporal_features',
        'by_type/ml_features/spatial_features',
        'by_type/ml_features/engineering_features',
        'by_type/control',
        'by_usage',
        'by_usage/simulation_setup',
        'by_usage/ML_training',
        'by_usage/visualization',
        'by_usage/geological_modeling',
        'by_phase',
        'by_phase/pre_simulation',
        'by_phase/simulation',
        'by_phase/post_analysis',
        'by_phase/simulation_ready',
        'metadata',
        'metadata/schemas',
        'metadata/validation',
        'metadata/documentation',
        'metadata/catalogs'
    };
    
    % Check each required directory
    for i = 1:length(required_directories)
        dir_path = fullfile(base_path, required_directories{i});
        
        if exist(dir_path, 'dir')
            validation_result.total_directories = validation_result.total_directories + 1;
        else
            validation_result.missing_directories{end+1} = required_directories{i};
        end
    end
    
    % Structure is complete if no directories are missing
    validation_result.structure_complete = isempty(validation_result.missing_directories);
    validation_result.completion_percentage = (validation_result.total_directories / length(required_directories)) * 100;
end

function repair_directory_structure(base_path)
% REPAIR_DIRECTORY_STRUCTURE - Repair incomplete or corrupted directory structure

    fprintf('🔧 Repairing canonical directory structure...\n');
    
    % Validate current structure
    validation_result = validate_directory_structure(base_path);
    
    if validation_result.structure_complete
        fprintf('   ✅ Structure is already complete\n');
        return;
    end
    
    fprintf('   Missing directories: %d\n', length(validation_result.missing_directories));
    
    % Create missing directories
    for i = 1:length(validation_result.missing_directories)
        missing_dir = validation_result.missing_directories{i};
        dir_path = fullfile(base_path, missing_dir);
        
        try
            ensure_directory_exists(dir_path);
            fprintf('   ✅ Created: %s\n', missing_dir);
        catch ME
            fprintf('   ❌ Failed to create: %s (%s)\n', missing_dir, ME.message);
        end
    end
    
    % Re-validate
    final_validation = validate_directory_structure(base_path);
    
    if final_validation.structure_complete
        fprintf('   ✅ Structure repair completed successfully\n');
    else
        fprintf('   ⚠️  Structure repair incomplete: %d directories still missing\n', ...
                length(final_validation.missing_directories));
    end
end

function structure_info = get_structure_info(base_path)
% GET_STRUCTURE_INFO - Get detailed information about canonical structure

    structure_info = struct();
    structure_info.base_path = base_path;
    structure_info.validation_date = datestr(now, 'yyyy-mm-ddTHH:MM:SS');
    
    % Validate structure
    validation_result = validate_directory_structure(base_path);
    structure_info.validation = validation_result;
    
    % Count files in each organization
    structure_info.file_counts = struct();
    
    % by_type file counts
    by_type_path = fullfile(base_path, 'by_type');
    if exist(by_type_path, 'dir')
        structure_info.file_counts.by_type = count_files_recursive(by_type_path);
    else
        structure_info.file_counts.by_type = 0;
    end
    
    % by_usage file counts
    by_usage_path = fullfile(base_path, 'by_usage');
    if exist(by_usage_path, 'dir')
        structure_info.file_counts.by_usage = count_files_recursive(by_usage_path);
    else
        structure_info.file_counts.by_usage = 0;
    end
    
    % by_phase file counts
    by_phase_path = fullfile(base_path, 'by_phase');
    if exist(by_phase_path, 'dir')
        structure_info.file_counts.by_phase = count_files_recursive(by_phase_path);
    else
        structure_info.file_counts.by_phase = 0;
    end
    
    % metadata file counts
    metadata_path = fullfile(base_path, 'metadata');
    if exist(metadata_path, 'dir')
        structure_info.file_counts.metadata = count_files_recursive(metadata_path);
    else
        structure_info.file_counts.metadata = 0;
    end
    
    % Total files
    structure_info.file_counts.total = structure_info.file_counts.by_type + ...
                                      structure_info.file_counts.metadata;
    
    % Symlink counts (by_usage and by_phase should contain mostly symlinks)
    structure_info.symlink_counts = structure_info.file_counts.by_usage + ...
                                   structure_info.file_counts.by_phase;
end

function file_count = count_files_recursive(directory_path)
% COUNT_FILES_RECURSIVE - Count all files recursively in directory

    file_count = 0;
    
    if ~exist(directory_path, 'dir')
        return;
    end
    
    try
        % Get all files and subdirectories
        items = dir(directory_path);
        
        for i = 1:length(items)
            item = items(i);
            
            % Skip . and .. entries
            if strcmp(item.name, '.') || strcmp(item.name, '..')
                continue;
            end
            
            item_path = fullfile(directory_path, item.name);
            
            if item.isdir
                % Recursively count files in subdirectory
                file_count = file_count + count_files_recursive(item_path);
            else
                % Count this file
                file_count = file_count + 1;
            end
        end
        
    catch ME
        warning('Error counting files in %s: %s', directory_path, ME.message);
    end
end

function rel_path = get_relative_path(target_file, link_dir)
% GET_RELATIVE_PATH - Calculate relative path from link directory to target file

    % Normalize paths
    target_file = strrep(target_file, '\', '/');
    link_dir = strrep(link_dir, '\', '/');
    
    target_parts = strsplit(target_file, '/');
    link_parts = strsplit(link_dir, '/');
    
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
    
    rel_path = strjoin(rel_parts, '/');
end

function ensure_directory_exists(directory_path)
% ENSURE_DIRECTORY_EXISTS - Create directory if it doesn't exist with Canon-First error handling

    if ~exist(directory_path, 'dir')
        try
            mkdir(directory_path);
        catch ME
            error(['Cannot create canonical directory: %s\n' ...
                   'REQUIRED: Directory creation must succeed for canonical compliance.\n' ...
                   'Canon requires write access and proper permissions.\n' ...
                   'Error: %s'], directory_path, ME.message);
        end
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
            elseif isnumeric(value) && length(value) == 1
                if isinteger(value)
                    fprintf(fid, '%s%s: %d\n', indent, field_name, value);
                else
                    fprintf(fid, '%s%s: %.6g\n', indent, field_name, value);
                end
            elseif islogical(value)
                fprintf(fid, '%s%s: %s\n', indent, field_name, lower(mat2str(value)));
            end
        end
    end
end