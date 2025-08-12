function rock_with_layers = s08_assign_layer_properties()
    addpath('utils'); run('utils/print_utils.m');
% S08_ASSIGN_LAYER_PROPERTIES - Assign layer properties (MRST Native)
% Requires: MRST
%
% OUTPUT:
%   rock_with_layers - Enhanced MRST rock structure with layer metadata
%
% Author: Claude Code AI System
% Date: January 30, 2025

    print_step_header('S08', 'Assign Layer Properties (MRST Native)');
    
    total_start_time = tic;
    
    try
        % ----------------------------------------
        % Step 1 – Load Layers Configuration
        % ----------------------------------------
        step_start = tic;
        [rock, G, rock_params] = step_1_load_rock_data();
        layer_config = step_1_load_layer_config();
        print_step_result(1, 'Load Layers Configuration', 'success', toc(step_start));
        
        % ----------------------------------------
        % Step 2 – Assign Properties to Rock
        % ----------------------------------------
        step_start = tic;
        rock_with_layers = step_2_enhance_rock_layers(rock, G, rock_params, layer_config);
        print_step_result(2, 'Assign Properties to Rock', 'success', toc(step_start));
        
        % ----------------------------------------
        % Step 3 – Validate & Export Enhanced Rock
        % ----------------------------------------
        step_start = tic;
        step_3_export_enhanced_rock(rock_with_layers, G, rock_params);
        print_step_result(3, 'Validate & Export Enhanced Rock', 'success', toc(step_start));
        
        print_step_footer('S08', sprintf('Layer Properties Ready: %d cells, %d layers', length(rock_with_layers.poro), rock_with_layers.meta.layer_info.n_layers), toc(total_start_time));
        
    catch ME
        print_error_step(0, 'Layer Properties', ME.message);
        error('Layer properties assignment failed: %s', ME.message);
    end

end

function [rock, G, rock_params] = step_1_load_rock_data()
% Step 1 - Load native MRST rock structure from s07

    % Substep 1.1 – Locate rock file ______________________________
    script_path = fileparts(mfilename('fullpath'));
    data_dir = fullfile(fileparts(script_path), '..', 'data', 'simulation_data', 'static');
    rock_file = fullfile(data_dir, 'native_rock_properties.mat');
    
    if ~exist(rock_file, 'file')
        error('Native rock structure not found. Run s07_define_rock_types.m first.');
    end
    
    % Substep 1.2 – Load rock structure ____________________________
    load(rock_file, 'rock', 'G', 'rock_params');
    
end

function layer_config = step_1_load_layer_config()
% Step 1 - Load layer configuration (simplified approach)

    % Substep 1.2 – Use simplified configuration __________________
    % Avoid YAML parsing - use direct configuration
    layer_config = create_default_layer_config();
    
end

function layer_config = create_default_layer_config()
% Create default layer configuration to avoid YAML dependencies
    
    layer_config = struct();
    layer_config.rock_properties = struct();
    
    % Layer enhancement settings
    layer_config.enhancement_settings = struct();
    layer_config.enhancement_settings.add_layer_metadata = true;
    layer_config.enhancement_settings.add_stratification_zones = true;
    layer_config.enhancement_settings.create_cell_mapping = true;
    
end

function rock_enhanced = step_2_enhance_rock_layers(rock, G, rock_params, layer_config)
% Step 2 - Enhance rock structure with layer metadata

    % Substep 3.1 – Initialize enhanced structure ____________________
    rock_enhanced = rock;
    if ~isfield(rock_enhanced, 'meta')
        rock_enhanced.meta = struct();
    end
    
    % Substep 3.2 – Add layer information ____________________________
    rock_enhanced = add_layer_information(rock_enhanced, rock_params);
    
    % Substep 3.3 – Add stratification zones _________________________
    rock_enhanced = add_stratification_zones(rock_enhanced);
    
    % Substep 3.4 – Create cell-layer mapping ________________________
    rock_enhanced = create_cell_layer_mapping(rock_enhanced, G);
    
end

function rock = add_layer_information(rock, rock_params)
% Add layer information to metadata
    
    rock.meta.layer_info = struct();
    rock.meta.layer_info.n_layers = length(rock_params.porosity_layers);
    rock.meta.layer_info.porosity_by_layer = rock_params.porosity_layers;
    rock.meta.layer_info.permeability_by_layer = rock_params.permeability_layers;
    rock.meta.layer_info.kv_kh_by_layer = rock_params.kv_kh_ratios;
    rock.meta.layer_info.lithology_by_layer = rock_params.lithology_layers;
    
end

function rock = add_stratification_zones(rock)
% Add stratification zone definitions
    
    rock.meta.stratification = struct();
    rock.meta.stratification.upper_zone = struct('layers', [1,2,3], 'description', 'High quality sandstones');
    rock.meta.stratification.shale_barrier_1 = struct('layers', 4, 'description', 'Upper shale barrier');
    rock.meta.stratification.middle_zone = struct('layers', [5,6,7], 'description', 'Highest quality sandstones');
    rock.meta.stratification.shale_barrier_2 = struct('layers', 8, 'description', 'Middle shale barrier');
    rock.meta.stratification.lower_zone = struct('layers', [9,10,11,12], 'description', 'Medium quality sandstones');
    
end

function rock = create_cell_layer_mapping(rock, G)
% Create cell-to-layer mapping based on grid structure
    
    rock.meta.layer_info.cell_to_layer = cell(G.cells.num, 1);
    
    for cell_id = 1:G.cells.num
        k_index = ceil(cell_id / (G.cartDims(1) * G.cartDims(2)));
        k_index = min(k_index, rock.meta.layer_info.n_layers);
        rock.meta.layer_info.cell_to_layer{cell_id} = k_index;
    end
    
    % Update enhancement metadata
    rock.meta.layer_enhancement_date = datestr(now);
    rock.meta.enhancement_method = 'metadata_integration';
    
end


function step_3_export_enhanced_rock(rock_enhanced, G, rock_params)
% Step 4 - Export enhanced rock data

    % Substep 4.1 – Validate enhanced structure ______________________
    validate_enhanced_structure(rock_enhanced, G, rock_params);
    
    % Substep 4.2 – Export to files _______________________________
    export_enhanced_files(rock_enhanced, G, rock_params);
    
end

function validate_enhanced_structure(rock, G, rock_params)
% Validate enhanced rock structure
    
    % Check core structure
    required_fields = {'perm', 'poro', 'meta'};
    for i = 1:length(required_fields)
        if ~isfield(rock, required_fields{i})
            error('Missing required field: %s', required_fields{i});
        end
    end
    
    % Check dimensions
    if size(rock.perm, 1) ~= G.cells.num
        error('Enhanced rock permeability array size mismatch');
    end
    
    if length(rock.poro) ~= G.cells.num
        error('Enhanced rock porosity array size mismatch');
    end
    
    % Check layer metadata
    if ~isfield(rock.meta, 'layer_info')
        error('Missing layer information in enhanced rock metadata');
    end
    
end

function export_enhanced_files(rock_enhanced, G, rock_params)
% Export enhanced rock to files
    
    script_path = fileparts(mfilename('fullpath'));
    data_dir = fullfile(fileparts(script_path), '..', 'data', 'simulation_data', 'static');
    
    if ~exist(data_dir, 'dir')
        mkdir(data_dir);
    end
    
    % Save enhanced rock structure
    enhanced_rock_file = fullfile(data_dir, 'enhanced_rock_with_layers.mat');
    save(enhanced_rock_file, 'rock_enhanced', 'G', 'rock_params');
    
end


% Main execution when called as script
if ~nargout
    % If called as script (not function), create enhanced rock structure
    rock_with_layers = s08_assign_layer_properties();
    
    fprintf('Enhanced MRST rock ready for simulation!\n');
    fprintf('Implementation: 100%% Native MRST with layer metadata\n');
    fprintf('Total cells: %d\n', length(rock_with_layers.poro));
    fprintf('Layers: %d (integrated as metadata)\n', rock_with_layers.meta.layer_info.n_layers);
    fprintf('Use enhanced rock structure in reservoir simulation.\n\n');
end