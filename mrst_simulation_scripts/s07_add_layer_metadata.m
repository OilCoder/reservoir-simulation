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
    
    % Load validation functions (inline for compatibility)
    load_validation_functions();

    % Add MRST session validation
    [success, message] = validate_mrst_session(script_dir);
    if ~success
        error('MRST validation failed: %s', message);
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
        
        % Save enhanced rock structure to file for s08
        save_enhanced_rock_structure(enhanced_rock, G);
        
        print_step_footer('S07', sprintf('Layer Metadata Added: %d cells, %d layers', ...
                         length(enhanced_rock.poro), enhanced_rock.meta.layer_info.n_layers), ...
                         toc(total_start_time));
        
    catch ME
        print_error_step(0, 'Layer Metadata Enhancement', ME.message);
        error('Layer metadata enhancement failed: %s', ME.message);
    end

end

function [base_rock, G] = load_base_rock_from_file()
% Load base rock structure from file created by s06 (CANON-FIRST)
    
    script_path = fileparts(mfilename('fullpath'));
    data_dir = get_data_path('static');
    
    % CANON-FIRST: Only load from s06 data file, no fallbacks
    base_rock_file = fullfile(data_dir, 'base_rock.mat');
    
    if ~exist(base_rock_file, 'file')
        error(['CANON-FIRST ERROR: Base rock data file not found.\n' ...
               'REQUIRED: Run s06_create_base_rock_structure.m first.\n' ...
               'EXPECTED: %s\n' ...
               'Canon specification requires base rock from s06.'], ...
               base_rock_file);
    end
    
    load_data = load(base_rock_file);
    if ~isfield(load_data, 'rock') || ~isfield(load_data, 'G')
        error(['CANON-FIRST ERROR: Invalid base rock file format.\n' ...
               'REQUIRED: File must contain rock and G structures from s06.\n' ...
               'Found fields: %s\n' ...
               'Canon specification requires rock and G fields.'], ...
               strjoin(fieldnames(load_data), ', '));
    end
    
    base_rock = load_data.rock;
    G = load_data.G;
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
    
    % Verify it's from the correct workflow stage
    if ~isfield(rock.meta, 'workflow_stage') || ~strcmp(rock.meta.workflow_stage, 'base_structure')
        error('Input rock is not from base structure creation stage');
    end
    
end

function save_enhanced_rock_structure(enhanced_rock, G)
% Save enhanced rock structure to data file for downstream workflow
    
    script_path = fileparts(mfilename('fullpath'));
    data_dir = get_data_path('static');
    
    if ~exist(data_dir, 'dir')
        mkdir(data_dir);
    end
    
    % Save enhanced rock structure with canonical naming
    enhanced_rock_file = fullfile(data_dir, 'enhanced_rock.mat');
    save(enhanced_rock_file, 'enhanced_rock', 'G');
    
    fprintf('   ✅ Enhanced rock structure saved to %s\n', enhanced_rock_file);
    
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
    for rt = [1, 2, 6]  % Only active rock types
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
    fprintf('Implementation: File-based workflow (no function dependencies)\n');
    fprintf('Input: base_rock.mat from s06\n');
    fprintf('Output: enhanced_rock.mat for s08\n');
    fprintf('Total cells: %d\n', length(enhanced_rock.poro));
    fprintf('Layers: %d\n', enhanced_rock.meta.layer_info.n_layers);
    fprintf('Stratification zones: %d\n', length(fieldnames(enhanced_rock.meta.stratification)));
    fprintf('Ready for spatial heterogeneity in s08\n\n');
end