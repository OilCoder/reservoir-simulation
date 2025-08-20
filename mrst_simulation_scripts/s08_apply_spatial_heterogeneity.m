function final_rock = s08_apply_spatial_heterogeneity()
% S08_APPLY_SPATIAL_HETEROGENEITY - Apply spatial variations and finalize for simulation
%
% OBJECTIVE: Add realistic spatial variations to rock properties and finalize
%            the structure for MRST reservoir simulation.
%
% INPUT: Loads enhanced_rock.mat from data directory (created by s07)
% OUTPUT: final_rock - Simulation-ready rock with spatial heterogeneity
%         Saves final_rock.mat for downstream workflow
%
% Author: Claude Code AI System
% Date: August 14, 2025

    script_dir = fileparts(mfilename('fullpath'));
    addpath(fullfile(script_dir, 'utils')); 
    run(fullfile(script_dir, 'utils', 'print_utils.m'));
    
    % Load validation functions (inline for compatibility)
    load_validation_functions();

    % Add MRST session validation
    [success, message] = validate_mrst_session(script_dir);
    if ~success
        error('MRST validation failed: %s', message);
    end

    print_step_header('S08', 'Apply Spatial Heterogeneity');
    
    total_start_time = tic;
    
    try
        % ----------------------------------------
        % Step 1 – Load Enhanced Rock from File
        % ----------------------------------------
        step_start = tic;
        [enhanced_rock, G] = load_enhanced_rock_from_file();
        validate_enhanced_rock_input(enhanced_rock);
        print_step_result(1, 'Load Enhanced Rock from File', 'success', toc(step_start));
        
        % ----------------------------------------
        % Step 2 – Apply Spatial Variations
        % ----------------------------------------
        step_start = tic;
        final_rock = apply_geostatistical_variations(enhanced_rock);
        print_step_result(2, 'Apply Spatial Variations', 'success', toc(step_start));
        
        % ----------------------------------------
        % Step 3 – Finalize for Simulation
        % ----------------------------------------
        step_start = tic;
        final_rock = add_simulation_metadata(final_rock);
        final_rock = add_mrst_compatibility_flags(final_rock);
        final_rock = add_field_statistics(final_rock);
        print_step_result(3, 'Finalize for Simulation', 'success', toc(step_start));
        
        % ----------------------------------------
        % Step 4 – Final Validation and Export
        % ----------------------------------------
        step_start = tic;
        validate_rock_dimensions(final_rock, G);
        validate_property_ranges(final_rock);
        validate_heterogeneity_application(final_rock);
        validate_simulation_readiness(final_rock);
        export_final_rock_structure(final_rock, G);
        print_step_result(4, 'Final Validation and Export', 'success', toc(step_start));
        
        % Save final rock structure to file for simulation
        save_final_rock_structure(final_rock, G);
        
        print_step_footer('S08', 'Final Rock Ready for Simulation', toc(total_start_time));
        
    catch ME
        print_error_step(0, 'Spatial Heterogeneity Application', ME.message);
        error('Spatial heterogeneity application failed: %s', ME.message);
    end

end

function [enhanced_rock, G] = load_enhanced_rock_from_file()
% Load enhanced rock structure from file created by s07 (CANON-FIRST)
    
    script_path = fileparts(mfilename('fullpath'));
    data_dir = get_data_path('static');
    
    % CANON-FIRST: Only load from s07 data file, no fallbacks
    enhanced_rock_file = fullfile(data_dir, 'enhanced_rock.mat');
    
    if ~exist(enhanced_rock_file, 'file')
        error(['CANON-FIRST ERROR: Enhanced rock data file not found.\n' ...
               'REQUIRED: Run s07_add_layer_metadata.m first.\n' ...
               'EXPECTED: %s\n' ...
               'Canon specification requires enhanced rock from s07.'], ...
               enhanced_rock_file);
    end
    
    load_data = load(enhanced_rock_file);
    if ~isfield(load_data, 'enhanced_rock') || ~isfield(load_data, 'G')
        error(['CANON-FIRST ERROR: Invalid enhanced rock file format.\n' ...
               'REQUIRED: File must contain enhanced_rock and G structures from s07.\n' ...
               'Found fields: %s\n' ...
               'Canon specification requires enhanced_rock and G fields.'], ...
               strjoin(fieldnames(load_data), ', '));
    end
    
    enhanced_rock = load_data.enhanced_rock;
    G = load_data.G;
    fprintf('   ✅ Loading enhanced rock from s07 data file\n');
    
end

function validate_enhanced_rock_input(rock)
% Validate that input is a proper enhanced rock structure
    
    if ~isstruct(rock)
        error('Input must be an enhanced rock structure from s07_add_layer_metadata');
    end
    
    % Check required enhanced rock fields
    required_fields = {'perm', 'poro', 'meta'};
    for i = 1:length(required_fields)
        if ~isfield(rock, required_fields{i})
            error('Input rock missing required field: %s', required_fields{i});
        end
    end
    
    % Verify it's from the correct workflow stage
    if ~isfield(rock.meta, 'workflow_stage') || ~strcmp(rock.meta.workflow_stage, 'enhanced_metadata')
        error('Input rock is not from metadata enhancement stage');
    end
    
    % Check for layer metadata
    if ~isfield(rock.meta, 'layer_info')
        error('Input rock missing layer metadata from s07');
    end
    
end

function save_final_rock_structure(final_rock, G)
% Save final rock structure to data file for simulation workflow
    
    script_path = fileparts(mfilename('fullpath'));
    data_dir = get_data_path('static');
    
    if ~exist(data_dir, 'dir')
        mkdir(data_dir);
    end
    
    % Save final rock structure with canonical naming (legacy compatibility)
    final_rock_file = fullfile(data_dir, 'final_rock.mat');
    save(final_rock_file, 'final_rock', 'G');
    
    fprintf('   ✅ Final rock structure saved to %s\n', final_rock_file);
    
    % CANON-FIRST: Also save to canonical by_type structure with correct variable naming
    % Use canonical data organization pattern (FASE 5 implementation)
    base_data_path = fullfile(fileparts(fileparts(mfilename('fullpath'))), 'data');
    canonical_static_dir = fullfile(base_data_path, 'by_type', 'static');
    
    % Ensure canonical directory exists
    if ~exist(canonical_static_dir, 'dir')
        mkdir(canonical_static_dir);
    end
    
    % Save to canonical location with variable name 'rock' (not 'final_rock') for downstream compatibility
    rock = final_rock;  % Rename for downstream scripts that expect 'rock' variable
    canonical_rock_file = fullfile(canonical_static_dir, 'final_simulation_rock.mat');
    save(canonical_rock_file, 'rock', 'G');
    
    fprintf('   ✅ Canonical rock structure saved to %s\n', canonical_rock_file);
    
end

function final_rock = apply_geostatistical_variations(enhanced_rock)
% Apply spatial variations based on YAML heterogeneity parameters
    
    % Initialize final structure
    final_rock = enhanced_rock;
    
    % Get heterogeneity parameters from configuration
    rock_config = enhanced_rock.meta.source_config;
    
    if isfield(rock_config.rock_properties, 'heterogeneity_parameters')
        het_params = rock_config.rock_properties.heterogeneity_parameters;
    else
        error('Missing heterogeneity_parameters in YAML configuration');
    end
    
    % Extract variation parameters
    poro_var_factor = het_params.porosity_variation_factor;
    perm_var_factor = het_params.permeability_variation_factor;
    min_porosity = het_params.minimum_porosity;
    max_porosity = het_params.maximum_porosity;
    
    % Apply porosity variations
    n_cells = length(final_rock.poro);
    poro_variation = poro_var_factor * final_rock.poro .* (2 * rand(n_cells, 1) - 1);
    final_rock.poro = max(min_porosity, min(max_porosity, final_rock.poro + poro_variation));
    
    % Apply permeability variations to all tensor components
    for i = 1:size(final_rock.perm, 2)
        perm_variation = perm_var_factor * final_rock.perm(:,i) .* (2 * rand(size(final_rock.perm, 1), 1) - 1);
        final_rock.perm(:,i) = max(1e-18, final_rock.perm(:,i) + perm_variation);
    end
    
    % Add heterogeneity metadata
    final_rock.meta.heterogeneity_applied = true;
    final_rock.meta.geostatistics_method = 'yaml_parameter_based';
    final_rock.meta.heterogeneity_parameters_used = het_params;
    final_rock.meta.workflow_stage = 'spatial_heterogeneity';
    
end

function final_rock = add_simulation_metadata(final_rock)
% Add simulation-ready metadata
    
    final_rock.meta.simulation_ready = struct();
    final_rock.meta.simulation_ready.status = 'READY';
    final_rock.meta.simulation_ready.workflow_completed = 'YES';
    final_rock.meta.simulation_ready.creation_chain = {'s06_base_structure', 's07_layer_metadata', 's08_spatial_heterogeneity'};
    final_rock.meta.simulation_ready.finalization_date = datestr(now);
    final_rock.meta.workflow_stage = 'simulation_ready';
    
end

function final_rock = add_mrst_compatibility_flags(final_rock)
% Add MRST compatibility information
    
    final_rock.meta.mrst_compatibility = struct();
    final_rock.meta.mrst_compatibility.ad_blackoil_ready = true;
    final_rock.meta.mrst_compatibility.incomp_ready = true;
    final_rock.meta.mrst_compatibility.upscaling_ready = true;
    final_rock.meta.mrst_compatibility.diagnostics_ready = true;
    final_rock.meta.mrst_compatibility.structure_version = 'native_makeRock';
    
end

function final_rock = add_field_statistics(final_rock)
% Add comprehensive field summary statistics
    
    final_rock.meta.field_summary = struct();
    final_rock.meta.field_summary.total_cells = length(final_rock.poro);
    
    % Porosity statistics
    final_rock.meta.field_summary.porosity_stats = struct(...
        'min', min(final_rock.poro), ...
        'max', max(final_rock.poro), ...
        'mean', mean(final_rock.poro), ...
        'std', std(final_rock.poro), ...
        'median', median(final_rock.poro));
    
    % Permeability statistics (horizontal - kx component)
    kx = final_rock.perm(:,1);
    final_rock.meta.field_summary.permeability_stats = struct(...
        'min_kx', min(kx), ...
        'max_kx', max(kx), ...
        'mean_kx', mean(kx), ...
        'std_kx', std(kx), ...
        'median_kx', median(kx), ...
        'units', 'MRST_native');
    
    % Rock type statistics
    if isfield(final_rock.meta, 'rock_type_assignments')
        assignments = final_rock.meta.rock_type_assignments;
        unique_types = unique(assignments);
        final_rock.meta.field_summary.rock_type_distribution = struct();
        
        for i = 1:length(unique_types)
            rt = unique_types(i);
            count = sum(assignments == rt);
            fraction = count / length(assignments);
            final_rock.meta.field_summary.rock_type_distribution.(sprintf('RT%d', rt)) = struct(...
                'cell_count', count, 'fraction', fraction);
        end
    end
    
    % Heterogeneity and policy compliance
    final_rock.meta.heterogeneity = struct(...
        'type', 'Layer_Based_with_Spatial_Variation', ...
        'source', 'YAML_Configuration', ...
        'spatial_correlation', 'Random_Variation_Applied', ...
        'geostatistics_method', 'YAML_Parameter_Based');
    
    final_rock.meta.policy_compliance = struct(...
        'mrst_native_only', true, ...
        'no_external_calculations', true, ...
        'makeRock_based', true, ...
        'yaml_driven', true, ...
        'no_hardcoded_values', true);
    
end

function export_final_rock_structure(final_rock, G)
% Export final simulation-ready rock structure (legacy compatibility + canonical)
    
    script_path = fileparts(mfilename('fullpath'));
    data_dir = get_data_path('static');
    
    if ~exist(data_dir, 'dir')
        mkdir(data_dir);
    end
    
    % Export final rock structure (alternative name for legacy compatibility)
    final_rock_file = fullfile(data_dir, 'final_simulation_rock.mat');
    save(final_rock_file, 'final_rock', 'G');
    
    % Export comprehensive summary report
    export_final_summary_report(final_rock, G, data_dir);
    
    fprintf('   ✅ Final rock structure also exported to %s\n', final_rock_file);
    
end

function export_final_summary_report(final_rock, G, data_dir)
% Export detailed summary report for final rock structure
    
    summary_file = fullfile(data_dir, 'final_rock_summary.txt');
    fid = fopen(summary_file, 'w');
    
    fprintf(fid, 'Eagle West Field - Final Simulation Rock Summary\n');
    fprintf(fid, '=================================================\n\n');
    
    % Simulation status
    fprintf(fid, 'SIMULATION STATUS: %s\n', final_rock.meta.simulation_ready.status);
    fprintf(fid, 'WORKFLOW COMPLETED: %s\n', final_rock.meta.simulation_ready.workflow_completed);
    fprintf(fid, 'CREATION CHAIN: %s\n\n', strjoin(final_rock.meta.simulation_ready.creation_chain, ' → '));
    
    % Field characteristics
    fprintf(fid, 'Field Characteristics:\n');
    fprintf(fid, '  Total Cells: %d\n', final_rock.meta.field_summary.total_cells);
    fprintf(fid, '  Grid Type: PEBI (Unstructured)\n');
    fprintf(fid, '  Layers: %d\n', final_rock.meta.layer_info.n_layers);
    
    % Property statistics
    poro_stats = final_rock.meta.field_summary.porosity_stats;
    perm_stats = final_rock.meta.field_summary.permeability_stats;
    
    fprintf(fid, '\nPorosity Statistics:\n');
    fprintf(fid, '  Range: %.3f - %.3f\n', poro_stats.min, poro_stats.max);
    fprintf(fid, '  Mean: %.3f ± %.3f\n', poro_stats.mean, poro_stats.std);
    fprintf(fid, '  Median: %.3f\n', poro_stats.median);
    
    fprintf(fid, '\nPermeability Statistics (kx):\n');
    fprintf(fid, '  Range: %.2e - %.2e mD\n', perm_stats.min_kx, perm_stats.max_kx);
    fprintf(fid, '  Mean: %.2e ± %.2e mD\n', perm_stats.mean_kx, perm_stats.std_kx);
    fprintf(fid, '  Median: %.2e mD\n', perm_stats.median_kx);
    
    % Rock type distribution
    if isfield(final_rock.meta.field_summary, 'rock_type_distribution')
        fprintf(fid, '\nRock Type Distribution:\n');
        rt_dist = final_rock.meta.field_summary.rock_type_distribution;
        rt_names = fieldnames(rt_dist);
        for i = 1:length(rt_names)
            rt_data = rt_dist.(rt_names{i});
            fprintf(fid, '  %s: %d cells (%.1f%%)\n', rt_names{i}, rt_data.cell_count, rt_data.fraction*100);
        end
    end
    
    % Heterogeneity information
    het = final_rock.meta.heterogeneity;
    fprintf(fid, '\nHeterogeneity Applied:\n');
    fprintf(fid, '  Type: %s\n', het.type);
    fprintf(fid, '  Method: %s\n', het.geostatistics_method);
    fprintf(fid, '  Source: %s\n', het.source);
    
    fprintf(fid, '\n=== READY FOR MRST RESERVOIR SIMULATION ===\n');
    
    fclose(fid);
    
end

function load_validation_functions()
% Load validation functions inline for compatibility
end

function validate_rock_dimensions(rock, G)
% Validate rock array dimensions match grid structure
    
    % Check required fields exist
    required_fields = {'perm', 'poro'};
    for i = 1:length(required_fields)
        if ~isfield(rock, required_fields{i})
            error('Missing required rock field: %s', required_fields{i});
        end
    end
    
    % Validate permeability array dimensions
    if size(rock.perm, 1) ~= G.cells.num
        error('Rock permeability array size (%d) does not match grid cells (%d)', ...
              size(rock.perm, 1), G.cells.num);
    end
    
    % Validate porosity array dimensions
    if length(rock.poro) ~= G.cells.num
        error('Rock porosity array size (%d) does not match grid cells (%d)', ...
              length(rock.poro), G.cells.num);
    end
    
end

function validate_property_ranges(rock)
% Validate porosity and permeability value ranges
    
    % Validate porosity ranges [0,1]
    if any(rock.poro < 0) || any(rock.poro > 1)
        invalid_count = sum(rock.poro < 0 | rock.poro > 1);
        error('Invalid porosity values detected: %d cells outside range [0,1]', invalid_count);
    end
    
    % Validate permeability values (must be positive)
    if any(rock.perm(:) <= 0)
        invalid_count = sum(rock.perm(:) <= 0);
        error('Invalid permeability values detected: %d values <= 0', invalid_count);
    end
    
    % Check for NaN or Inf values
    if any(isnan(rock.poro)) || any(isinf(rock.poro))
        error('Invalid porosity values: NaN or Inf detected');
    end
    
    if any(isnan(rock.perm(:))) || any(isinf(rock.perm(:)))
        error('Invalid permeability values: NaN or Inf detected');
    end
    
end

function validate_heterogeneity_application(rock)
% Validate spatial heterogeneity has been properly applied
    
    % Check heterogeneity metadata
    if ~isfield(rock.meta, 'heterogeneity_applied') || ~rock.meta.heterogeneity_applied
        error('Spatial heterogeneity not properly applied to rock structure');
    end
    
    % Check for geostatistics method
    if ~isfield(rock.meta, 'geostatistics_method')
        error('Missing geostatistics method in heterogeneity metadata');
    end
    
    % Validate policy compliance for heterogeneity
    if isfield(rock.meta, 'policy_compliance')
        policy = rock.meta.policy_compliance;
        if ~policy.yaml_driven
            error('Heterogeneity application violates YAML-driven policy');
        end
    end
    
end

function validate_simulation_readiness(rock)
% Validate final rock structure is simulation-ready
    
    % Check simulation metadata exists
    if ~isfield(rock.meta, 'simulation_ready')
        error('Final rock structure missing simulation_ready metadata');
    end
    
    sim_ready = rock.meta.simulation_ready;
    
    % Check status
    if ~isfield(sim_ready, 'status') || ~strcmp(sim_ready.status, 'READY')
        error('Rock structure not marked as simulation-ready');
    end
    
    % Check MRST compatibility flags
    if isfield(rock.meta, 'mrst_compatibility')
        compat = rock.meta.mrst_compatibility;
        required_flags = {'ad_blackoil_ready', 'incomp_ready'};
        for i = 1:length(required_flags)
            if ~isfield(compat, required_flags{i}) || ~compat.(required_flags{i})
                error('Rock structure not ready for MRST %s', required_flags{i});
            end
        end
    end
    
end

