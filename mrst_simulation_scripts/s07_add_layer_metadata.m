function enhanced_rock = s07_add_layer_metadata()
% S07_ADD_LAYER_METADATA - Add layer metadata to base rock structure
%
% OBJECTIVE: Enhance base rock structure with layer information, stratification
%            zones, and cell mappings without modifying core rock properties.
%
% INPUT: Loads base_rock.mat from data directory (created by s06)
% OUTPUT: enhanced_rock - Rock with layer metadata and stratification zones
%         Saves enhanced_rock.mat for s08
%
% Author: Claude Code AI System  
% Date: August 14, 2025

    script_dir = fileparts(mfilename('fullpath'));
    addpath(fullfile(script_dir, 'utils')); 
    run(fullfile(script_dir, 'utils', 'print_utils.m'));
    
    % Add utilities for consolidated data handling
    addpath(fullfile(script_dir, 'utils'));
    
    % Load validation functions (inline for compatibility)
    load_validation_functions();

    % Add MRST to path manually (since session doesn't save paths)
    mrst_root = '/opt/mrst';
    addpath(genpath(fullfile(mrst_root, 'core'))); % Add all core subdirectories
    addpath(genpath(fullfile(mrst_root, 'modules')));
    
    % Load saved MRST session to check status
    % CANON-FIRST POLICY: Documentation specifies /workspace/data/mrst/session/ as authoritative location
    workspace_root = '/workspace';
    session_file = fullfile(workspace_root, 'data', 'mrst', 'session', 's01_mrst_session.mat');
    if exist(session_file, 'file')
        loaded_data = load(session_file);
        if isfield(loaded_data, 'mrst_env') && strcmp(loaded_data.mrst_env.status, 'ready')
            fprintf('   ✅ MRST session validated\n');
        end
    else
        error('MRST session not found. Please run s01_initialize_mrst.m first.');
    end

    print_step_header('S07', 'Add Layer Metadata');
    
    total_start_time = tic;
    
    try
        % ----------------------------------------
        % Step 1 – Load Base Rock from File
        % ----------------------------------------
        step_start = tic;
        [base_rock, G] = load_base_rock_from_file();
        validate_base_rock_input(base_rock);
        print_step_result(1, 'Load Base Rock from File', 'success', toc(step_start));
        
        % ----------------------------------------
        % Step 2 – Add Layer Information
        % ----------------------------------------
        step_start = tic;
        enhanced_rock = add_layer_information_metadata(base_rock);
        print_step_result(2, 'Add Layer Information', 'success', toc(step_start));
        
        % ----------------------------------------
        % Step 3 – Add Stratification and Mapping
        % ----------------------------------------
        step_start = tic;
        enhanced_rock = add_stratification_zones(enhanced_rock);
        enhanced_rock = create_cell_layer_mapping(enhanced_rock, G);
        enhanced_rock = create_rock_type_assignments(enhanced_rock, G);
        print_step_result(3, 'Add Stratification and Mapping', 'success', toc(step_start));
        
        % ----------------------------------------
        % Step 4 – Validate Enhanced Structure
        % ----------------------------------------
        step_start = tic;
        validate_rock_dimensions(enhanced_rock, G);
        validate_layer_metadata(enhanced_rock);
        enhanced_rock = update_enhancement_metadata(enhanced_rock);
        print_step_result(4, 'Validate Enhanced Structure', 'success', toc(step_start));
        
        % Save enhanced rock structure using consolidated data
        layer_info = enhanced_rock.meta.layer_info;
        if isfield(enhanced_rock.meta, 'stratification')
            save_consolidated_data('rock', 's07', 'rock', enhanced_rock, 'layer_info', layer_info, ...
                                 'stratification', enhanced_rock.meta.stratification);
        else
            save_consolidated_data('rock', 's07', 'rock', enhanced_rock, 'layer_info', layer_info);
        end
        
        print_step_footer('S07', sprintf('Layer Metadata Added: %d cells, %d layers', ...
                         length(enhanced_rock.poro), enhanced_rock.meta.layer_info.n_layers), ...
                         toc(total_start_time));
        
    catch ME
        print_error_step(0, 'Layer Metadata Enhancement', ME.message);
        error('Layer metadata enhancement failed: %s', ME.message);
    end

end

function [base_rock, G] = load_base_rock_from_file()
% Load base rock structure using new canonical MRST structure
    
    % Load from consolidated data structure
    % CANON-FIRST POLICY: Documentation specifies /workspace/data/mrst/ as authoritative location
    rock_file = '/workspace/data/mrst/rock.mat';
    
    if exist(rock_file, 'file')
        rock_data = load(rock_file);
        
        % Load rock structure directly from consolidated data
        base_rock = rock_data.rock;
        
        % Load and attach source configuration
        func_dir = fileparts(mfilename('fullpath'));
        addpath(fullfile(func_dir, 'utils'));
        config = read_yaml_config('config/rock_properties_config.yaml');
        base_rock.meta.source_config = config;
        
        fprintf('   ✅ Loading rock from consolidated data structure\n');
    else
        error(['Missing consolidated rock file: /workspace/data/mrst/rock.mat\n' ...
               'REQUIRED: Run s06_create_base_rock_structure.m first.\n' ...
               'Canon specifies rock.mat must exist before layer metadata addition.']);
    end
    
    % Load grid from consolidated data structure
    % CANON-FIRST POLICY: Documentation specifies /workspace/data/mrst/ as authoritative location
    grid_file = '/workspace/data/mrst/grid.mat';
    if exist(grid_file, 'file')
        grid_data = load(grid_file);
        if isfield(grid_data, 'fault_grid') && ~isempty(grid_data.fault_grid)
            G = grid_data.fault_grid;
        else
            G = grid_data.G;
        end
    else
        error('CANON-FIRST ERROR: Grid data not found in consolidated structure.');
    end
    
    fprintf('   ✅ Loading base rock from s06 data file\n');
    
end

function validate_base_rock_input(rock)
% Validate that input is a proper base rock structure
    
    if ~isstruct(rock)
        error('Input must be a rock structure from s06_create_base_rock_structure');
    end
    
    % Check required base rock fields
    required_fields = {'perm', 'poro', 'meta'};
    for i = 1:length(required_fields)
        if ~isfield(rock, required_fields{i})
            error('Input rock missing required field: %s', required_fields{i});
        end
    end
    
    % Verify it's from the correct workflow stage or already enhanced
    if isfield(rock.meta, 'workflow_stage')
        if strcmp(rock.meta.workflow_stage, 'enhanced_metadata')
            fprintf('   ✅ Rock already has enhanced metadata from previous run\n');
            % Rock already processed - this is normal for reruns
        elseif ~strcmp(rock.meta.workflow_stage, 'base_structure')
            error('Input rock is not from base structure creation stage');
        end
    else
        error('Input rock missing workflow_stage information');
    end
    
end


function enhanced_rock = add_layer_information_metadata(base_rock)
% Add layer information metadata without modifying core properties
    
    % Initialize enhanced structure (copy base rock)
    enhanced_rock = base_rock;
    
    % Extract configuration from stored metadata
    if ~isfield(base_rock.meta, 'source_config')
        error('Base rock missing source configuration metadata');
    end
    
    rock_config = base_rock.meta.source_config;
    rock_props = rock_config.rock_properties;
    
    % Add layer information metadata
    enhanced_rock.meta.layer_info = struct();
    enhanced_rock.meta.layer_info.n_layers = length(rock_props.porosity_layers);
    enhanced_rock.meta.layer_info.porosity_by_layer = rock_props.porosity_layers;
    enhanced_rock.meta.layer_info.permeability_by_layer = rock_props.permeability_layers;
    enhanced_rock.meta.layer_info.kv_kh_by_layer = rock_props.kv_kh_ratios;
    
    % Add lithology information if available
    if isfield(rock_props, 'lithology_layers')
        enhanced_rock.meta.layer_info.lithology_by_layer = rock_props.lithology_layers;
    end
    
    % Update workflow stage
    enhanced_rock.meta.workflow_stage = 'layer_metadata';
    
end

function enhanced_rock = add_stratification_zones(enhanced_rock)
% Add stratification zone definitions based on YAML configuration
    
    % Get configuration from metadata
    rock_config = enhanced_rock.meta.source_config;
    
    % Add stratification zones if defined in configuration
    if isfield(rock_config.rock_properties, 'layer_architecture')
        layer_arch = rock_config.rock_properties.layer_architecture;
        
        enhanced_rock.meta.stratification = struct();
        
        % Add each defined zone
        zone_names = fieldnames(layer_arch);
        for i = 1:length(zone_names)
            zone_name = zone_names{i};
            zone_data = layer_arch.(zone_name);
            
            enhanced_rock.meta.stratification.(zone_name) = struct();
            enhanced_rock.meta.stratification.(zone_name).layers = zone_data.layers;
            enhanced_rock.meta.stratification.(zone_name).description = zone_data.description;
            
            % Add additional zone properties if available
            if isfield(zone_data, 'avg_net_to_gross')
                enhanced_rock.meta.stratification.(zone_name).net_to_gross = zone_data.avg_net_to_gross;
            end
            if isfield(zone_data, 'lateral_continuity')
                enhanced_rock.meta.stratification.(zone_name).lateral_continuity = zone_data.lateral_continuity;
            end
        end
    else
        % Default stratification if not defined in YAML
        enhanced_rock.meta.stratification = create_default_stratification(enhanced_rock.meta.layer_info.n_layers);
    end
    
end

function stratification = create_default_stratification(n_layers)
% Create default stratification zones when not specified in YAML
    
    stratification = struct();
    stratification.upper_zone = struct('layers', [1,2,3], 'description', 'Upper reservoir zone');
    stratification.middle_zone = struct('layers', 4:7, 'description', 'Middle reservoir zone');
    stratification.lower_zone = struct('layers', 8:n_layers, 'description', 'Lower reservoir zone');
    
end

function enhanced_rock = create_cell_layer_mapping(enhanced_rock, G)
% Create cell-to-layer mapping based on grid geometry
    
    n_cells = G.cells.num;
    n_layers = enhanced_rock.meta.layer_info.n_layers;
    
    % Initialize cell-to-layer mapping
    enhanced_rock.meta.layer_info.cell_to_layer = zeros(n_cells, 1);
    
    % Calculate z-coordinate bounds for layer assignment
    z_min = min(G.cells.centroids(:,3));
    z_max = max(G.cells.centroids(:,3));
    
    for cell_id = 1:n_cells
        cell_z = G.cells.centroids(cell_id, 3);
        layer_index = ceil(n_layers * (cell_z - z_min) / (z_max - z_min + eps));
        layer_index = min(max(layer_index, 1), n_layers);
        enhanced_rock.meta.layer_info.cell_to_layer(cell_id) = layer_index;
    end
    
    % Explicit return of modified structure
    return;
    
end

function enhanced_rock = create_rock_type_assignments(enhanced_rock, G)
% Create rock type assignments for downstream workflows
    
    n_cells = G.cells.num;
    rock_config = enhanced_rock.meta.source_config;
    rock_props = rock_config.rock_properties;
    
    % Get classification thresholds from YAML
    classification = rock_props.rock_type_classification;
    rt1_threshold = classification.rt1_high_perm_threshold;
    rt2_threshold = classification.rt2_medium_perm_threshold;
    
    % Create rock type assignments based on layer permeabilities
    rock_type_assignments = zeros(n_cells, 1);
    
    for cell_id = 1:n_cells
        layer_index = enhanced_rock.meta.layer_info.cell_to_layer(cell_id);
        layer_perm = rock_props.permeability_layers(layer_index);
        
        if layer_perm >= rt1_threshold
            rock_type_assignments(cell_id) = 1;  % RT1 - High permeability
        elseif layer_perm >= rt2_threshold
            rock_type_assignments(cell_id) = 2;  % RT2 - Medium permeability
        else
            rock_type_assignments(cell_id) = 6;  % RT6 - Low permeability/barriers
        end
    end
    
    % Store assignments in metadata
    enhanced_rock.meta.rock_type_assignments = rock_type_assignments;
    
    % Add summary statistics
    enhanced_rock.meta.rock_type_summary = struct();
    
    % Load active rock types from configuration
    if isfield(rock_config, 'rock_properties') && isfield(rock_config.rock_properties, 'rock_type_classification') && isfield(rock_config.rock_properties.rock_type_classification, 'active_rock_types')
        active_rock_types = rock_config.rock_properties.rock_type_classification.active_rock_types;
    else
        error('Missing active_rock_types in rock_properties_config.yaml rock_type_classification section. REQUIRED: Add active_rock_types: [1, 2, 6] to rock_type_classification section.');
    end
    
    for rt = active_rock_types
        cells_of_type = sum(rock_type_assignments == rt);
        enhanced_rock.meta.rock_type_summary.(sprintf('RT%d_cells', rt)) = cells_of_type;
        enhanced_rock.meta.rock_type_summary.(sprintf('RT%d_fraction', rt)) = cells_of_type / n_cells;
    end
    
    % Explicit return of modified structure
    return;
    
end

function enhanced_rock = update_enhancement_metadata(enhanced_rock)
% Update enhancement metadata to track processing
    
    enhanced_rock.meta.layer_enhancement_date = datestr(now);
    enhanced_rock.meta.enhancement_method = 'metadata_integration';
    enhanced_rock.meta.workflow_stage = 'enhanced_metadata';
    
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

function validate_layer_metadata(rock)
% Validate layer metadata completeness (for enhanced rock structures)
    
    % Check if metadata exists
    if ~isfield(rock, 'meta')
        error('Enhanced rock structure missing metadata field');
    end
    
    % Check layer information
    if ~isfield(rock.meta, 'layer_info')
        error('Enhanced rock structure missing layer_info in metadata');
    end
    
    layer_info = rock.meta.layer_info;
    
    % Validate required layer fields
    required_layer_fields = {'n_layers', 'porosity_by_layer', 'permeability_by_layer'};
    for i = 1:length(required_layer_fields)
        if ~isfield(layer_info, required_layer_fields{i})
            error('Missing required layer field: %s', required_layer_fields{i});
        end
    end
    
    % Validate layer array consistency
    n_layers = layer_info.n_layers;
    if length(layer_info.porosity_by_layer) ~= n_layers
        error('Layer porosity array length inconsistent with n_layers');
    end
    
    if length(layer_info.permeability_by_layer) ~= n_layers
        error('Layer permeability array length inconsistent with n_layers');
    end
    
end


% Main execution when called as script - FILE-BASED WORKFLOW
if ~nargout
    enhanced_rock = s07_add_layer_metadata();
    
    fprintf('\n=== LAYER METADATA ENHANCEMENT COMPLETE ===\n');
    fprintf('Implementation: Consolidated data workflow\n');
    fprintf('Input: rock.mat from consolidated data structure\n');
    fprintf('Output: enhanced rock.mat via save_consolidated_data\n');
    fprintf('Total cells: %d\n', length(enhanced_rock.poro));
    fprintf('Layers: %d\n', enhanced_rock.meta.layer_info.n_layers);
    fprintf('Stratification zones: %d\n', length(fieldnames(enhanced_rock.meta.stratification)));
    fprintf('Ready for spatial heterogeneity in s08\n\n');
end