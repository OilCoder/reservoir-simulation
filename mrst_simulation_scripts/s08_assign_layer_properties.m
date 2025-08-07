function layer_properties = s08_assign_layer_properties()
% S08_ASSIGN_LAYER_PROPERTIES - Assign layer properties for Eagle West Field
%
% SYNTAX:
%   layer_properties = s08_assign_layer_properties()
%
% OUTPUT:
%   layer_properties - Structure containing layer property assignments
%
% DESCRIPTION:
%   Assign rock properties to each of the 12 layers following
%   specifications in 02_Rock_Properties.md and rock_properties_config.yaml.
%
% Author: Claude Code AI System
% Date: January 30, 2025

    fprintf('======================================================\n');
    fprintf('Eagle West Field - Layer Properties Assignment (Step 8)\n');
    fprintf('======================================================\n\n');
    
    try
        % Load required data
        fprintf('Step 1: Loading required data...\n');
        
        % Load refined grid
        refined_file = '../data/mrst_simulation/static/refined_grid.mat';
        if exist(refined_file, 'file')
            load(refined_file, 'G_refined');
            G = G_refined;
        else
            % Fall back to structural framework
            structural_file = '../data/mrst_simulation/static/structural_framework.mat';
            if exist(structural_file, 'file')
                load(structural_file, 'G');
            else
                error('No grid data found. Run previous steps first.');
            end
        end
        
        % Load rock types
        rock_types_file = '../data/mrst_simulation/static/rock_types.mat';
        if exist(rock_types_file, 'file')
            load(rock_types_file, 'rock_types');
        else
            error('Rock types not found. Run s07_define_rock_types first.');
        end
        
        % Load configuration
        rock_config = load_rock_config();
        fprintf('   ✓ Data loaded successfully\n');
        
        % Step 2 - Assign properties by layer
        fprintf('Step 2: Assigning properties to 12 layers...\n');
        G = assign_properties_to_layers(G, rock_config, rock_types);
        fprintf('   ✓ Properties assigned to all %d cells\n', G.cells.num);
        
        % Step 3 - Validate property assignment
        fprintf('Step 3: Validating property assignments...\n');
        validate_property_assignment(G);
        fprintf('   ✓ Property assignment validated\n');
        
        % Step 4 - Export layer properties
        fprintf('Step 4: Exporting layer properties...\n');
        export_layer_properties_data(G, rock_config);
        fprintf('   ✓ Layer properties exported\n\n');
        
        % Assemble output
        layer_properties = struct();
        layer_properties.grid = G;
        layer_properties.n_layers = 12;
        layer_properties.rock_config = rock_config;
        layer_properties.status = 'completed';
        
        fprintf('======================================================\n');
        fprintf('Layer Properties Assignment Completed\n');
        fprintf('======================================================\n');
        fprintf('Total cells: %d\n', G.cells.num);
        fprintf('Layers: 12 (Upper/Middle/Lower zones + barriers)\n');
        fprintf('Property range - Porosity: %.3f - %.3f\n', min(G.cells.porosity), max(G.cells.porosity));
        fprintf('Property range - Permeability: %.2f - %.0f mD\n', min(G.cells.permeability), max(G.cells.permeability));
        fprintf('======================================================\n\n');
        
    catch ME
        fprintf('❌ Layer properties assignment failed: %s\n', ME.message);
        error('Layer properties assignment failed: %s', ME.message);
    end

end

function rock_config = load_rock_config()
    run('read_yaml_config.m');
    rock_config = read_yaml_config('config/rock_properties_config.yaml');
end

function G = assign_properties_to_layers(G, rock_config, rock_types)
    % Assign porosity, permeability, and other properties based on layer
    
    rock_props = rock_config.rock_properties;
    
    % Initialize property arrays
    G.cells.porosity = zeros(G.cells.num, 1);
    G.cells.permeability = zeros(G.cells.num, 1);
    G.cells.kv_kh_ratio = zeros(G.cells.num, 1);
    
    % Layer-by-layer assignment (12 layers)
    porosity_layers = rock_props.porosity_layers;
    permeability_layers = rock_props.permeability_layers;
    kv_kh_ratios = rock_props.kv_kh_ratios;
    
    % Assign properties based on layer index
    for layer = 1:12
        layer_cells = find(G.cells.layer_index == layer);
        
        if ~isempty(layer_cells)
            G.cells.porosity(layer_cells) = porosity_layers(layer);
            G.cells.permeability(layer_cells) = permeability_layers(layer);
            G.cells.kv_kh_ratio(layer_cells) = kv_kh_ratios(layer);
        end
    end
    
    % Apply some spatial variability (±10% variation)
    variability = 0.1;
    
    % Porosity variation
    variation = 1 + variability * (2*rand(G.cells.num, 1) - 1);
    G.cells.porosity = G.cells.porosity .* variation;
    G.cells.porosity = max(G.cells.porosity, 0.01); % Minimum porosity
    
    % Permeability variation (log-normal)
    log_perm = log(G.cells.permeability);
    log_variation = variability * (2*rand(G.cells.num, 1) - 1);
    G.cells.permeability = exp(log_perm + log_variation);
    G.cells.permeability = max(G.cells.permeability, 0.001); % Minimum permeability
end

function validate_property_assignment(G)
    % Validate that all cells have reasonable properties
    
    % Check for unassigned cells
    zero_porosity = sum(G.cells.porosity == 0);
    zero_permeability = sum(G.cells.permeability == 0);
    
    if zero_porosity > 0 || zero_permeability > 0
        error('%d cells with zero porosity, %d cells with zero permeability', ...
              zero_porosity, zero_permeability);
    end
    
    % Check reasonable ranges
    min_por = min(G.cells.porosity);
    max_por = max(G.cells.porosity);
    min_perm = min(G.cells.permeability);
    max_perm = max(G.cells.permeability);
    
    if min_por < 0 || max_por > 0.5
        warning('Porosity range [%.3f, %.3f] may be unrealistic', min_por, max_por);
    end
    
    if min_perm < 0.001 || max_perm > 10000
        warning('Permeability range [%.3f, %.0f] mD may be unrealistic', min_perm, max_perm);
    end
    
    fprintf('     Porosity range: %.3f - %.3f\n', min_por, max_por);
    fprintf('     Permeability range: %.2f - %.0f mD\n', min_perm, max_perm);
end

function export_layer_properties_data(G, rock_config)
    script_path = fileparts(mfilename('fullpath'));
    data_dir = fullfile(fileparts(script_path), 'data', 'mrst_simulation', 'static');
    
    if ~exist(data_dir, 'dir')
        mkdir(data_dir);
    end
    
    % Save grid with properties
    properties_file = fullfile(data_dir, 'layer_properties.mat');
    save(properties_file, 'G', 'rock_config', '');
    
    fprintf('     Layer properties saved to: %s\n', properties_file);
end

if ~nargout
    layer_properties = s08_assign_layer_properties();
end