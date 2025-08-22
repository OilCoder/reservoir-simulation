function rock = s06_create_base_rock_structure()
% S06_CREATE_BASE_ROCK_STRUCTURE - Create fundamental MRST rock structure
% 
% OBJECTIVE: Load YAML configuration once and create base rock structure using
%            MRST native makeRock() function. No metadata or enhancement.
%
% INPUT: Grid from s05, rock_properties_config.yaml
% OUTPUT: Base rock structure with core permeability/porosity properties
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

    print_step_header('S06', 'Create Base Rock Structure');
    
    total_start_time = tic;
    
    try
        % ----------------------------------------
        % Step 1 – Load Configuration and Grid
        % ----------------------------------------
        step_start = tic;
        G = load_grid_structure();
        rock_config = load_rock_configuration();
        print_step_result(1, 'Load Configuration and Grid', 'success', toc(step_start));
        
        % ----------------------------------------
        % Step 2 – Create MRST Rock Structure
        % ----------------------------------------
        step_start = tic;
        rock = create_mrst_rock_structure(G, rock_config);
        print_step_result(2, 'Create MRST Rock Structure', 'success', toc(step_start));
        
        % ----------------------------------------
        % Step 3 – Validate and Store Configuration
        % ----------------------------------------
        step_start = tic;
        validate_rock_dimensions(rock, G);
        validate_property_ranges(rock);
        validate_mrst_compatibility(rock);
        rock.meta.source_config = rock_config;  % Store for downstream use
        print_step_result(3, 'Validate Base Rock Structure', 'success', toc(step_start));
        
        % Save base rock structure to file for s07
        save_base_rock_structure(rock, G);
        
        print_step_footer('S06', sprintf('Base Rock Ready: %d cells, %d layers', ...
                         G.cells.num, length(rock_config.rock_properties.porosity_layers)), ...
                         toc(total_start_time));
        
    catch ME
        print_error_step(0, 'Base Rock Creation', ME.message);
        error('Base rock structure creation failed: %s', ME.message);
    end

end

function G = load_grid_structure()
% Load canonical PEBI grid structure using new canonical MRST structure
    
    % NEW CANONICAL STRUCTURE: Load from grid.mat
    canonical_file = '/workspace/data/mrst/grid.mat';
    
    if exist(canonical_file, 'file')
        load(canonical_file, 'data_struct');
        % Use fault grid if available, otherwise use base grid
        if isfield(data_struct, 'fault_grid') && ~isempty(data_struct.fault_grid)
            G = data_struct.fault_grid;
        else
            G = data_struct.G;
        end
        fprintf('   ✅ Loading grid from canonical location\n');
    else
        % Fallback to legacy location if canonical doesn't exist
        script_path = fileparts(mfilename('fullpath'));
        data_dir = get_data_path('static');
        
        pebi_grid_file = fullfile(data_dir, 'pebi_grid.mat');
        
        if ~exist(pebi_grid_file, 'file')
            error(['CANON-FIRST ERROR: Grid structure not found.\n' ...
                   'REQUIRED: Run s03_create_pebi_grid.m and s05_add_faults.m first.']);
        end
        
        load_data = load(pebi_grid_file);
        if ~isfield(load_data, 'G_pebi')
            error('CANON-FIRST ERROR: Invalid grid file format.');
        end
        
        G = load_data.G_pebi;
        fprintf('   ⚠️  Loading grid from legacy location\n');
    end
    
    % CRITICAL FIX: Always recompute geometry to ensure valid volumes
    fprintf('   🔧 Recomputing geometry to ensure valid volumes...\n');
    G = computeGeometry(G);  % ALWAYS recompute

    % FAIL_FAST: Validate volumes immediately  
    if any(G.cells.volumes <= 0)
        error(['CRITICAL: Grid has %d cells with negative/zero volumes\n' ...
               'UPDATE CANON: obsidian-vault/Planning/Grid_Definition.md\n' ...
               'Grid generation must produce valid positive volumes.'], sum(G.cells.volumes <= 0));
    end
    fprintf('   ✅ Grid geometry validated: %d cells, all volumes > 0\n', G.cells.num);
    
end

function rock_config = load_rock_configuration()
% Load rock configuration from YAML - single source of truth
    
    script_dir = fileparts(mfilename('fullpath'));
    addpath(fullfile(script_dir, 'utils'));
    
    try
        % Load complete YAML configuration once
        rock_config = read_yaml_config('config/rock_properties_config.yaml');
        
        % Validate required configuration sections
        validate_yaml_configuration(rock_config);
        
        fprintf('   ✅ Rock configuration loaded from YAML: %d layers\n', ...
                length(rock_config.rock_properties.porosity_layers));
        
    catch ME
        error('Failed to load rock configuration from YAML: %s\nPolicy violation: No hardcoding allowed', ME.message);
    end
    
end

function validate_yaml_configuration(config)
% Validate required YAML configuration sections exist
    
    if ~isfield(config, 'rock_properties')
        error('Missing rock_properties section in YAML configuration');
    end
    
    rock_props = config.rock_properties;
    required_fields = {'porosity_layers', 'permeability_layers', 'kv_kh_ratios', ...
                      'rock_type_classification'};
    
    for i = 1:length(required_fields)
        if ~isfield(rock_props, required_fields{i})
            error('Missing required field in rock_properties_config.yaml: %s', required_fields{i});
        end
    end
    
    % Validate array consistency
    n_layers = length(rock_props.porosity_layers);
    if length(rock_props.permeability_layers) ~= n_layers || ...
       length(rock_props.kv_kh_ratios) ~= n_layers
        error('Layer property arrays must have consistent length in YAML configuration');
    end
    
end

function rock = create_mrst_rock_structure(G, rock_config)
% Create MRST rock structure using native makeRock function
    
    rock_props = rock_config.rock_properties;
    
    % Extract layer properties
    porosity_layers = rock_props.porosity_layers;
    permeability_layers = rock_props.permeability_layers;
    kv_kh_ratios = rock_props.kv_kh_ratios;
    
    % Assign properties to cells based on vertical position
    [cell_porosity, cell_permeability_tensor] = assign_properties_to_cells(...
        G, porosity_layers, permeability_layers, kv_kh_ratios);
    
    % Create canonical MRST rock structure (CANON-FIRST)
    % Note: makeRock function may not be available in all MRST versions
    % Use canonical MRST rock structure format directly
    
    % Validate input dimensions (CANON-FIRST requirement)
    if size(cell_permeability_tensor, 1) ~= G.cells.num
        error(['CANON-FIRST ERROR: Permeability tensor size mismatch.\n' ...
               'REQUIRED: Tensor size (%d) must match grid cells (%d).\n' ...
               'Canon specification requires exact dimensional consistency.'], ...
               size(cell_permeability_tensor, 1), G.cells.num);
    end
    
    if length(cell_porosity) ~= G.cells.num
        error(['CANON-FIRST ERROR: Porosity array size mismatch.\n' ...
               'REQUIRED: Array size (%d) must match grid cells (%d).\n' ...
               'Canon specification requires exact dimensional consistency.'], ...
               length(cell_porosity), G.cells.num);
    end
    
    % Create canonical MRST rock structure format
    rock = struct();
    rock.perm = cell_permeability_tensor;  % Nx3 tensor [kx, ky, kz]
    rock.poro = cell_porosity(:);          % Nx1 column vector
    
    fprintf('   ✅ Created canonical MRST rock structure\n');
    
    % Add basic metadata
    rock.meta = struct();
    rock.meta.creation_method = 'canonical_mrst_format';
    rock.meta.source = 'YAML_configuration';
    rock.meta.creation_date = datestr(now);
    rock.meta.workflow_stage = 'base_structure';
    
end

function [porosity, perm_tensor] = assign_properties_to_cells(G, poro_layers, perm_layers, kv_kh_layers)
% Assign layer properties to cells based on vertical position
    
    n_cells = G.cells.num;
    n_layers = length(poro_layers);
    
    porosity = zeros(n_cells, 1);
    perm_tensor = zeros(n_cells, 3);
    
    % Calculate z-coordinate bounds for layer assignment
    z_min = min(G.cells.centroids(:,3));
    z_max = max(G.cells.centroids(:,3));
    
    for cell_id = 1:n_cells
        % Determine layer index from z-coordinate
        cell_z = G.cells.centroids(cell_id, 3);
        layer_index = ceil(n_layers * (cell_z - z_min) / (z_max - z_min + eps));
        layer_index = min(max(layer_index, 1), n_layers);
        
        % Assign properties
        porosity(cell_id) = poro_layers(layer_index);
        
        % Create permeability tensor (kx, ky, kz)
        kx = perm_layers(layer_index);
        ky = kx;  % Isotropic in horizontal plane
        kz = kx * kv_kh_layers(layer_index);
        
        perm_tensor(cell_id, :) = [kx, ky, kz];
    end
    
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

function validate_mrst_compatibility(rock)
% Validate MRST structure compatibility
    
    % Check permeability tensor format (should be Nx3 for 3D)
    if size(rock.perm, 2) ~= 3
        error('Permeability tensor must be Nx3 for 3D MRST compatibility');
    end
    
    % Ensure porosity is column vector
    if size(rock.poro, 2) ~= 1
        error('Porosity must be column vector for MRST compatibility');
    end
    
    % Check for MRST metadata structure
    if isfield(rock, 'meta')
        if ~isstruct(rock.meta)
            error('Rock metadata must be structure for MRST compatibility');
        end
    end
    
end

function save_base_rock_structure(rock, G)
% Save base rock structure to data file using canonical organization
    
    try
        % Load canonical data utilities
        script_path = fileparts(mfilename('fullpath'));
        addpath(fullfile(script_path, 'utils'));
        
        % Create canonical directory structure
        base_data_path = fullfile(fileparts(script_path), 'data');
        static_path = fullfile(base_data_path, 'by_type', 'static');
        if ~exist(static_path, 'dir')
            mkdir(static_path);
        end
        
        % Structure data for canonical export
        rock_data = struct();
        rock_data.rock = rock;
        rock_data.porosity = rock.poro;
        rock_data.permeability = rock.perm;
        rock_data.enhanced_grid = G;
        rock_data.metadata = rock.meta;
        rock_data.metadata.rock_type = 'base_properties';
        rock_data.metadata.field_name = 'Eagle_West';
        rock_data.metadata.cell_count = length(rock.poro);
        
        % NEW CANONICAL STRUCTURE: Create rock.mat in /workspace/data/mrst/
        canonical_file = '/workspace/data/mrst/rock.mat';
        
        % Create new canonical rock structure
        data_struct = struct();
        data_struct.perm = rock.perm;
        data_struct.poro = rock.poro;
        data_struct.units.perm_unit = 'mD';
        data_struct.units.poro_unit = 'fraction';
        data_struct.created_by = {'s06'};
        data_struct.timestamp = datetime('now');
        
        % Save canonical structure
        save(canonical_file, 'data_struct');
        fprintf('     NEW CANONICAL: Rock data saved to %s\n', canonical_file);
        
        % Maintain legacy compatibility during transition
        legacy_data_dir = get_data_path('static');
        if ~exist(legacy_data_dir, 'dir')
            mkdir(legacy_data_dir);
        end
        
        base_rock_file = fullfile(legacy_data_dir, 'base_rock.mat');
        save(base_rock_file, 'rock', 'G');
        
        fprintf('     Legacy compatibility maintained: %s\n', base_rock_file);
        
    catch ME
        fprintf('Warning: Canonical export failed: %s\n', ME.message);
        
        % Fallback to legacy export
        script_path = fileparts(mfilename('fullpath'));
        data_dir = get_data_path('static');
        
        if ~exist(data_dir, 'dir')
            mkdir(data_dir);
        end
        
        base_rock_file = fullfile(data_dir, 'base_rock.mat');
        save(base_rock_file, 'rock', 'G');
        
        fprintf('     Fallback: Base rock structure saved to %s\n', base_rock_file);
    end
    
end

% Main execution when called as script
if ~nargout
    rock = s06_create_base_rock_structure();
    
    fprintf('\n=== BASE ROCK STRUCTURE CREATED ===\n');
    fprintf('Implementation: Canonical MRST Format\n');
    fprintf('Total cells: %d\n', length(rock.poro));
    fprintf('Workflow stage: %s\n', rock.meta.workflow_stage);
    fprintf('Data file: base_rock.mat\n');
    fprintf('Ready for metadata enhancement in s07\n\n');
end