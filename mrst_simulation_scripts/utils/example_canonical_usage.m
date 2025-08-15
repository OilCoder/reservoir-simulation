function example_canonical_usage()
% EXAMPLE_CANONICAL_USAGE - Demonstration of canonical data utilities usage
%
% This script demonstrates how to use the canonical data utilities framework
% for the MRST workflow following the Simulation Data Catalog canon.
%
% Features demonstrated:
% - Creating canonical directory structure
% - Saving data with canonical organization
% - Validating workflow data
% - Migrating legacy data to canonical format
%
% Requires: MRST
%
% Author: Claude Code AI System
% Date: August 15, 2025

    fprintf('🎯 Canonical Data Utilities - Usage Examples\n\n');
    
    % Example 1: Create canonical directory structure
    example_create_structure();
    
    % Example 2: Save data using canonical utilities
    example_save_canonical_data();
    
    % Example 3: Validate workflow data
    example_validate_workflow();
    
    % Example 4: Migration from legacy format
    example_migrate_legacy();
    
    fprintf('✅ All canonical data utility examples completed\n\n');
end

function example_create_structure()
% EXAMPLE_CREATE_STRUCTURE - Demonstrate canonical structure creation

    fprintf('📁 Example 1: Creating Canonical Directory Structure\n');
    
    % Define base path (adjust for your environment)
    base_path = fullfile(tempdir, 'example_canonical_structure');
    
    try
        % Create complete canonical structure
        create_canonical_structure(base_path, ...
            'force_recreate', true, ...
            'create_symlinks', true, ...
            'create_metadata', true, ...
            'verbose', true);
        
        % Get structure information
        structure_info = get_structure_info(base_path);
        
        fprintf('   📊 Structure Summary:\n');
        fprintf('      Total directories: %d\n', structure_info.validation.total_directories);
        fprintf('      Structure complete: %s\n', string(structure_info.validation.structure_complete));
        fprintf('      Completion: %.1f%%\n', structure_info.validation.completion_percentage);
        
        % Cleanup example
        if exist(base_path, 'dir')
            rmdir(base_path, 's');
            fprintf('   🗑️  Example structure cleaned up\n');
        end
        
    catch ME
        fprintf('   ❌ Error: %s\n', ME.message);
    end
    
    fprintf('\n');
end

function example_save_canonical_data()
% EXAMPLE_SAVE_CANONICAL_DATA - Demonstrate canonical data saving

    fprintf('💾 Example 2: Saving Data with Canonical Organization\n');
    
    % Create example base path
    base_path = fullfile(tempdir, 'example_data_save');
    
    try
        % First create the canonical structure
        create_canonical_structure(base_path, 'verbose', false);
        
        % Create example grid data (simulating s05_create_pebi_grid output)
        fprintf('   Creating example grid data...\n');
        example_grid_data = create_example_grid_data();
        
        % Save using canonical utilities
        fprintf('   Saving with canonical organization...\n');
        output_files = save_canonical_data('s05', example_grid_data, ...
            'base_path', base_path, ...
            'formats', {'hdf5', 'yaml'}, ...
            'organizations', {'by_type', 'by_usage', 'by_phase'});
        
        fprintf('   📄 Files created:\n');
        for i = 1:length(output_files.primary_files)
            [~, filename, ext] = fileparts(output_files.primary_files{i});
            fprintf('      %s%s\n', filename, ext);
        end
        
        fprintf('   🔗 Symlinks created: %d\n', length(output_files.symlinks));
        fprintf('   📋 Metadata files: %d\n', length(output_files.metadata_files));
        
        % Create example rock data (simulating s06_create_base_rock output)
        fprintf('   Creating example rock data...\n');
        example_rock_data = create_example_rock_data();
        
        % Save rock data
        fprintf('   Saving rock properties...\n');
        rock_output = save_canonical_data('s06', example_rock_data, ...
            'base_path', base_path, ...
            'formats', {'hdf5', 'yaml'});
        
        fprintf('   📄 Rock files created: %d\n', length(rock_output.primary_files));
        
        % Cleanup example
        if exist(base_path, 'dir')
            rmdir(base_path, 's');
            fprintf('   🗑️  Example data cleaned up\n');
        end
        
    catch ME
        fprintf('   ❌ Error: %s\n', ME.message);
    end
    
    fprintf('\n');
end

function example_validate_workflow()
% EXAMPLE_VALIDATE_WORKFLOW - Demonstrate workflow validation

    fprintf('🔍 Example 3: Validating Workflow Data\n');
    
    % Create example workflow with data
    base_path = fullfile(tempdir, 'example_validation');
    
    try
        % Create structure and sample data
        create_canonical_structure(base_path, 'verbose', false);
        
        % Create sample data for multiple steps
        steps_to_create = {'s05', 's06', 's07'};
        
        for i = 1:length(steps_to_create)
            step_name = steps_to_create{i};
            
            switch step_name
                case 's05'
                    sample_data = create_example_grid_data();
                case 's06'
                    sample_data = create_example_rock_data();
                case 's07'
                    sample_data = create_example_enhanced_rock_data();
            end
            
            save_canonical_data(step_name, sample_data, ...
                'base_path', base_path, 'formats', {'hdf5', 'yaml'});
        end
        
        fprintf('   Sample data created for steps: %s\n', strjoin(steps_to_create, ', '));
        
        % Validate basic level
        fprintf('   Running basic validation...\n');
        validation_basic = validate_workflow_data(steps_to_create, ...
            'base_path', base_path, ...
            'validation_level', 'basic', ...
            'report_format', 'struct');
        
        fprintf('   📊 Basic Validation Results:\n');
        fprintf('      Overall status: %s\n', validation_basic.validation_summary.overall_status);
        fprintf('      Total issues: %d\n', validation_basic.validation_summary.total_issues);
        fprintf('      Critical issues: %d\n', validation_basic.validation_summary.critical_issues);
        
        % Validate standard level
        fprintf('   Running standard validation...\n');
        validation_standard = validate_workflow_data(steps_to_create, ...
            'base_path', base_path, ...
            'validation_level', 'standard');
        
        fprintf('   📊 Standard Validation Results:\n');
        fprintf('      Overall status: %s\n', validation_standard.validation_summary.overall_status);
        fprintf('      Total issues: %d\n', validation_standard.validation_summary.total_issues);
        
        % Display recommendations
        if isfield(validation_standard, 'recommendations') && ~isempty(validation_standard.recommendations)
            fprintf('   💡 Recommendations:\n');
            for i = 1:min(3, length(validation_standard.recommendations))
                fprintf('      - %s\n', validation_standard.recommendations{i});
            end
        end
        
        % Cleanup example
        if exist(base_path, 'dir')
            rmdir(base_path, 's');
            fprintf('   🗑️  Example validation data cleaned up\n');
        end
        
    catch ME
        fprintf('   ❌ Error: %s\n', ME.message);
    end
    
    fprintf('\n');
end

function example_migrate_legacy()
% EXAMPLE_MIGRATE_LEGACY - Demonstrate legacy data migration

    fprintf('🔄 Example 4: Migrating Legacy Data to Canonical Format\n');
    
    % Create example legacy data structure
    legacy_path = fullfile(tempdir, 'example_legacy_data');
    canonical_path = fullfile(tempdir, 'example_migrated_data');
    
    try
        % Create legacy data structure
        create_example_legacy_structure(legacy_path);
        fprintf('   Example legacy structure created\n');
        
        % Migrate to canonical format
        fprintf('   Migrating to canonical format...\n');
        migrate_to_canonical_format(legacy_path, ...
            'target_base_path', canonical_path, ...
            'preserve_legacy', true, ...
            'validation_level', 'basic');
        
        % Validate migrated data
        fprintf('   Validating migrated data...\n');
        validation_result = validate_workflow_data('all', ...
            'base_path', canonical_path, ...
            'validation_level', 'basic');
        
        fprintf('   📊 Migration Validation:\n');
        fprintf('      Status: %s\n', validation_result.validation_summary.overall_status);
        fprintf('      Issues: %d\n', validation_result.validation_summary.total_issues);
        
        % Count migrated files
        if exist(canonical_path, 'dir')
            canonical_info = get_structure_info(canonical_path);
            fprintf('      Files in canonical structure: %d\n', canonical_info.file_counts.total);
        end
        
        % Cleanup examples
        if exist(legacy_path, 'dir')
            rmdir(legacy_path, 's');
        end
        if exist(canonical_path, 'dir')
            rmdir(canonical_path, 's');
        end
        fprintf('   🗑️  Example migration data cleaned up\n');
        
    catch ME
        fprintf('   ❌ Error: %s\n', ME.message);
    end
    
    fprintf('\n');
end

% ========================================
% Helper Functions for Examples
% ========================================

function grid_data = create_example_grid_data()
% CREATE_EXAMPLE_GRID_DATA - Create example grid data for demonstration

    % Simulate PEBI grid structure
    n_cells = 20172;  % Eagle West Field canonical cell count
    
    grid_data = struct();
    
    % Grid structure (simplified MRST grid)
    grid_data.G = struct();
    grid_data.G.cells = struct();
    grid_data.G.cells.num = n_cells;
    grid_data.G.cells.centroids = rand(n_cells, 3) * 1000;  % Random centroids in meters
    grid_data.G.cells.volumes = 100 + rand(n_cells, 1) * 200;  % Cell volumes
    
    grid_data.G.faces = struct();
    grid_data.G.faces.num = n_cells * 6;  % Approximate face count
    grid_data.G.faces.areas = 10 + rand(grid_data.G.faces.num, 1) * 20;  % Face areas
    
    grid_data.G.nodes = struct();
    grid_data.G.nodes.num = n_cells * 8;  % Approximate node count
    grid_data.G.nodes.coords = rand(grid_data.G.nodes.num, 3) * 1000;
    
    % Additional grid metadata
    grid_data.grid_cells = grid_data.G.cells;
    grid_data.grid_faces = grid_data.G.faces;
    grid_data.grid_nodes = grid_data.G.nodes;
    
    % Grid quality metrics
    grid_data.grid_quality = struct();
    grid_data.grid_quality.min_volume = min(grid_data.G.cells.volumes);
    grid_data.grid_quality.max_volume = max(grid_data.G.cells.volumes);
    grid_data.grid_quality.total_volume = sum(grid_data.G.cells.volumes);
end

function rock_data = create_example_rock_data()
% CREATE_EXAMPLE_ROCK_DATA - Create example rock properties for demonstration

    n_cells = 20172;  % Eagle West Field canonical cell count
    
    rock_data = struct();
    
    % Rock structure (MRST format)
    rock_data.rock = struct();
    
    % Porosity field (Eagle West Field typical range: 0.05-0.35)
    rock_data.rock.poro = 0.05 + rand(n_cells, 1) * 0.30;
    rock_data.porosity = rock_data.rock.poro;
    
    % Permeability field (log-normal distribution)
    log_perm = -15 + randn(n_cells, 1) * 2;  % Log permeability in m^2
    rock_data.rock.perm = exp(log_perm);
    rock_data.permeability = rock_data.rock.perm;
    
    % Additional rock properties
    rock_data.rock_type = ones(n_cells, 1);  % Simple rock type assignment
    rock_data.layer_mapping = mod(floor((1:n_cells)' / 1681), 12) + 1;  % 12 layers
    
    % Rock metadata
    rock_data.metadata = struct();
    rock_data.metadata.poro_min = min(rock_data.rock.poro);
    rock_data.metadata.poro_max = max(rock_data.rock.poro);
    rock_data.metadata.perm_min = min(rock_data.rock.perm);
    rock_data.metadata.perm_max = max(rock_data.rock.perm);
end

function enhanced_rock_data = create_example_enhanced_rock_data()
% CREATE_EXAMPLE_ENHANCED_ROCK_DATA - Create enhanced rock properties

    % Start with base rock data
    enhanced_rock_data = create_example_rock_data();
    
    n_cells = 20172;
    
    % Add layer information
    enhanced_rock_data.layers = struct();
    enhanced_rock_data.layers.layer_count = 12;
    enhanced_rock_data.layers.layer_names = {
        'Layer_01', 'Layer_02', 'Layer_03', 'Layer_04', 'Layer_05', 'Layer_06', ...
        'Layer_07', 'Layer_08', 'Layer_09', 'Layer_10', 'Layer_11', 'Layer_12'
    };
    
    % Enhanced metadata
    enhanced_rock_data.metadata.enhancement_level = 'layer_enhanced';
    enhanced_rock_data.metadata.processing_date = datestr(now, 'yyyy-mm-ddTHH:MM:SS');
    enhanced_rock_data.metadata.layer_statistics = struct();
    
    for i = 1:12
        layer_cells = enhanced_rock_data.layer_mapping == i;
        layer_name = sprintf('layer_%02d', i);
        enhanced_rock_data.metadata.layer_statistics.(layer_name).cell_count = sum(layer_cells);
        enhanced_rock_data.metadata.layer_statistics.(layer_name).avg_porosity = mean(enhanced_rock_data.rock.poro(layer_cells));
        enhanced_rock_data.metadata.layer_statistics.(layer_name).avg_permeability = mean(enhanced_rock_data.rock.perm(layer_cells));
    end
end

function create_example_legacy_structure(legacy_path)
% CREATE_EXAMPLE_LEGACY_STRUCTURE - Create example legacy data for migration demo

    if ~exist(legacy_path, 'dir')
        mkdir(legacy_path);
    end
    
    % Create example legacy files
    
    % Example grid file (.mat format)
    grid_legacy = create_example_grid_data();
    save(fullfile(legacy_path, 'legacy_grid_data.mat'), '-struct', 'grid_legacy');
    
    % Example rock file (.mat format)
    rock_legacy = create_example_rock_data();
    save(fullfile(legacy_path, 'legacy_rock_properties.mat'), '-struct', 'rock_legacy');
    
    % Example YAML configuration
    yaml_content = sprintf('# Legacy Configuration\nfield_name: "Eagle West Field"\ngrid_type: "PEBI"\ncreated: "%s"\n', datestr(now));
    fid = fopen(fullfile(legacy_path, 'legacy_config.yaml'), 'w');
    fprintf(fid, '%s', yaml_content);
    fclose(fid);
    
    % Example CSV data
    csv_data = [1:100; rand(1, 100) * 100]';
    csvwrite(fullfile(legacy_path, 'legacy_well_data.csv'), csv_data);
    
    % Create subdirectory with more files
    subdir_path = fullfile(legacy_path, 'results');
    mkdir(subdir_path);
    
    % Additional legacy file in subdirectory
    summary_data = struct('total_cells', 20172, 'simulation_time', 3650, 'recovery_factor', 0.35);
    save(fullfile(subdir_path, 'simulation_summary.mat'), '-struct', 'summary_data');
end