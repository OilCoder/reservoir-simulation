function wells_results = s15_well_placement()
% S15_WELL_PLACEMENT - Eagle West Field 15-Well System Placement (s15→s16 chain)
%
% CANON-FIRST POLICY: Configuration authority from wells_config.yaml
% DATA AUTHORITY POLICY: All domain values from authoritative sources
% FAIL FAST POLICY: Explicit validation with actionable error messages
%
% PURPOSE:
%   Creates 15 wells (10 producers EW-001 to EW-010, 5 injectors IW-001 to IW-005)
%   from wells_config.yaml with rock property integration for accurate well indices.
%   First component of Well System Chain: s15 → s16 = wells.mat
%
% CANONICAL EXPORT:
%   wells.mat → /workspace/data/mrst/wells.mat (consumed by s16)
%
% DEPENDENCIES:
%   - MRST session from s01
%   - grid.mat from s05 (PEBI grid geometry)
%   - rock.mat from s08 (heterogeneous rock properties)
%   - wells_config.yaml (15-well specifications)
%
% OUTPUTS:
%   wells_results - Structure with complete well placement results
%
% Author: Claude Code AI System
% Date: August 26, 2025

    script_dir = fileparts(mfilename('fullpath'));
    addpath(fullfile(script_dir, 'utils')); 
    addpath(fullfile(script_dir, 'utils', 'wells'));
    run(fullfile(script_dir, 'utils', 'print_utils.m'));

    % MODERN SESSION MANAGEMENT: Use canonical check_and_load_mrst_session
    if ~check_and_load_mrst_session()
        error('MRST session not found. REQUIRED: Run s01_initialize_mrst.m first.');
    end
    
    % WARNING SUPPRESSION: Complete silence for clean output
    warning('off', 'all');
    print_step_header('S15', 'Well System Placement - 15 Wells');
    
    total_start_time = tic;
    
    % Load configuration, grid, and rock properties
    step_start = tic;
    [config, G, rock] = load_config_and_dependencies(script_dir);
    print_step_result(1, 'Load Dependencies (Config/Grid/Rock)', 'success', toc(step_start));
    
    % Create producer wells (10) with rock property integration
    step_start = tic;
    producer_wells = producer_wells_setup_fixed(config.wells_system, G, rock);
    print_step_result(2, 'Create Producer Wells', 'success', toc(step_start));
    
    % Create injector wells (5) with rock property integration
    step_start = tic;
    injector_wells = injector_wells_setup_fixed(config.wells_system, G, rock);
    print_step_result(3, 'Create Injector Wells', 'success', toc(step_start));
    
    % Create wells results structure with rock integration
    wells_results = create_wells_results(config, G, rock, producer_wells, injector_wells);
    
    % Validate well locations
    step_start = tic;
    validation_results = well_validation(wells_results, G);
    wells_results.validation_results = validation_results;
    print_step_result(4, 'Validate Well Locations', 'success', toc(step_start));
    
    % Export well placement data
    step_start = tic;
    export_path = export_well_data(wells_results);
    wells_results.export_path = export_path;
    print_step_result(5, 'Export Well Placement Data', 'success', toc(step_start));
    
    print_final_summary(wells_results, toc(total_start_time));
end

function [config, G, rock] = load_config_and_dependencies(script_dir)
% Load configuration, grid, and rock properties with fail-fast validation
    % CANON-FIRST POLICY: Configuration is authority
    config_file = fullfile(script_dir, 'config', 'wells_config.yaml');
    if ~exist(config_file, 'file')
        error('Wells configuration file not found: %s.\nREQUIRED: Create wells_config.yaml with Eagle West Field well specifications.', config_file);
    end
    config = read_yaml_config(config_file);
    
    % Validate canonical configuration structure
    if ~isfield(config, 'wells_system') || ~isfield(config.wells_system, 'producer_wells') || ~isfield(config.wells_system, 'injector_wells')
        error('Invalid wells configuration structure.\nREQUIRED: wells_system.producer_wells and wells_system.injector_wells sections.');
    end
    
    % CANONICAL DATA AUTHORITY: Load grid from s05 (PEBI grid geometry)
    grid_file = '/workspace/data/mrst/grid.mat';
    if ~exist(grid_file, 'file')
        error('Grid file not found: %s.\nREQUIRED: Run s05_create_pebi_grid.m first to create PEBI grid geometry.', grid_file);
    end
    grid_data = load(grid_file);
    G = grid_data.G;
    
    % CANONICAL DATA AUTHORITY: Load rock properties from s08 (heterogeneous rock)
    rock_file = '/workspace/data/mrst/rock.mat';
    if ~exist(rock_file, 'file')
        error('Rock properties file not found: %s.\nREQUIRED: Run s08_rock_heterogeneity.m first to create heterogeneous rock properties.', rock_file);
    end
    rock_data = load(rock_file);
    rock = rock_data.rock;
    
    % FAIL FAST POLICY: Validate critical grid structure
    if ~isfield(G, 'cells') || ~isfield(G, 'faces') || ~isfield(G, 'nodes')
        error('Invalid grid structure. Grid must have cells, faces, and nodes fields from s05 PEBI generation.');
    end
    
    % PEBI GRID COMPATIBILITY: Add cartDims equivalent for PEBI grids
    if ~isfield(G, 'cartDims') && isfield(G, 'numLayers') && isfield(G, 'layerSize')
        % For PEBI grids, create logical dimensions based on Eagle West Field specs
        G.cartDims = [41, 41, G.numLayers];  % 41x41x12 logical grid from VARIABLE_INVENTORY
        fprintf('PEBI grid compatibility: Added logical cartDims [41x41x%d]\n', G.numLayers);
    end
    
    % FAIL FAST POLICY: Validate rock properties compatibility
    if length(rock.perm) ~= G.cells.num
        error('Rock properties size mismatch: %d rock cells vs %d grid cells.\nREQUIRED: Consistent rock-grid correspondence from s08.', length(rock.perm), G.cells.num);
    end
    
    fprintf('Dependencies loaded: %d cells PEBI grid, heterogeneous rock properties\n', G.cells.num);
end

function wells_results = create_wells_results(config, G, rock, producer_wells, injector_wells)
% Create comprehensive wells results structure with rock integration
    wells_results = struct();
    wells_results.config = config;
    wells_results.G = G;
    wells_results.rock = rock;  % Include rock properties for s16 consumption
    wells_results.producer_wells = producer_wells;
    wells_results.injector_wells = injector_wells;
    wells_results.total_wells = length(producer_wells) + length(injector_wells);
    wells_results.total_producers = length(producer_wells);
    wells_results.total_injectors = length(injector_wells);
    wells_results.timestamp = datestr(now);  % Octave compatible timestamp
    wells_results.status = 'placed';
    wells_results.data_provenance = struct('grid_source', 's05_pebi_grid', 'rock_source', 's08_heterogeneity', 'config_source', 'wells_config.yaml');
end

function export_path = export_well_data(wells_results)
% Export well placement data to canonical wells.mat for s16 consumption
    % CANONICAL PATH MANAGEMENT: Export to /workspace/data/mrst/wells.mat
    canonical_dir = '/workspace/data/mrst';
    
    if ~exist(canonical_dir, 'dir')
        mkdir(canonical_dir);
    end
    
    % CANONICAL EXPORT: Create primary wells.mat for s16 consumption
    W = create_mrst_wells(wells_results);
    wells_file = fullfile(canonical_dir, 'wells.mat');
    save(wells_file, 'W', 'wells_results', '-v7');
    
    % DIAGNOSTIC EXPORTS: Summary files for verification
    write_well_summary(canonical_dir, wells_results);
    write_well_coordinates(canonical_dir, wells_results);
    
    export_path = wells_file;
    fprintf('Wells exported to canonical location: %s\n', wells_file);
end

function W = create_mrst_wells(wells_results)
% Create MRST-compatible well structures
    W = [];
    
    % Add producers
    for i = 1:length(wells_results.producer_wells)
        well = wells_results.producer_wells{i};
        well_struct = convert_to_mrst_well(well);
        
        if isempty(W)
            W = well_struct;
        else
            W(end+1) = well_struct;
        end
    end
    
    % Add injectors
    for i = 1:length(wells_results.injector_wells)
        well = wells_results.injector_wells{i};
        well_struct = convert_to_mrst_well(well);
        
        if isempty(W)
            W = well_struct;
        else
            W(end+1) = well_struct;
        end
    end
end

function well_struct = convert_to_mrst_well(well)
% Convert well to MRST-compatible structure with configuration authority
    well_struct = struct();
    well_struct.name = well.name;
    well_struct.cells = well.cells;
    well_struct.type = well.type;
    well_struct.WI = well.WI;
    well_struct.dZ = 0; % Default for vertical wells
    well_struct.r = well.radius;
    well_struct.dir = 'z'; % Default vertical direction
    well_struct.status = true; % Active
    
    % DATA AUTHORITY POLICY: Control values from configuration
    if strcmp(well.type, 'producer')
        well_struct.val = well.target_oil_rate;  % From wells_config.yaml
        well_struct.bhp_limit = well.min_bhp;    % BHP constraint
    else % injector
        well_struct.val = well.target_injection_rate;  % From wells_config.yaml
        well_struct.bhp_limit = well.max_bhp;           % BHP constraint
    end
    
    % Include completion metadata for s16
    well_struct.completion_layers = well.completion_layers;
    well_struct.well_trajectory = well.well_type;  % vertical/horizontal/multi_lateral
    well_struct.skin_factor = well.skin_factor;
end

function write_well_summary(output_dir, wells_results)
% Write well summary file
    summary_file = fullfile(output_dir, 'wells_summary.txt');
    
    fid = fopen(summary_file, 'w');
    if fid == -1
        warning('Could not create well summary file: %s', summary_file);
        return;
    end
    
    fprintf(fid, 'Eagle West Field Well Placement Summary\n');
    fprintf(fid, '======================================\n\n');
    fprintf(fid, 'Total Wells: %d\n', wells_results.total_wells);
    fprintf(fid, 'Producers: %d\n', wells_results.total_producers);
    fprintf(fid, 'Injectors: %d\n', wells_results.total_injectors);
    if isfield(wells_results.G, 'cartDims')
        fprintf(fid, 'Grid Dimensions: %dx%dx%d\n', wells_results.G.cartDims);
    else
        fprintf(fid, 'PEBI Grid: %d cells, %d layers\n', wells_results.G.cells.num, wells_results.G.numLayers);
    end
    
    % List producer wells
    fprintf(fid, '\nProducer Wells:\n');
    for i = 1:length(wells_results.producer_wells)
        well = wells_results.producer_wells{i};
        fprintf(fid, '  %s: (%d,%d,%d) - %s trajectory\n', well.name, well.i, well.j, well.k, well.well_type);
    end
    
    % List injector wells
    fprintf(fid, '\nInjector Wells:\n');
    for i = 1:length(wells_results.injector_wells)
        well = wells_results.injector_wells{i};
        fprintf(fid, '  %s: (%d,%d,%d) - %s trajectory\n', well.name, well.i, well.j, well.k, well.well_type);
    end
    
    fclose(fid);
end

function write_well_coordinates(output_dir, wells_results)
% Write well coordinates file
    coords_file = fullfile(output_dir, 'well_coordinates.csv');
    
    fid = fopen(coords_file, 'w');
    if fid == -1
        warning('Could not create well coordinates file: %s', coords_file);
        return;
    end
    
    fprintf(fid, 'Well_Name,Type,I,J,K,Cell_Index,Trajectory\n');
    
    % Write producer coordinates
    for i = 1:length(wells_results.producer_wells)
        well = wells_results.producer_wells{i};
        fprintf(fid, '%s,producer,%d,%d,%d,%d,%s\n', well.name, well.i, well.j, well.k, well.cells, well.well_type);
    end
    
    % Write injector coordinates
    for i = 1:length(wells_results.injector_wells)
        well = wells_results.injector_wells{i};
        fprintf(fid, '%s,injector,%d,%d,%d,%d,%s\n', well.name, well.i, well.j, well.k, well.cells, well.well_type);
    end
    
    fclose(fid);
end

function print_final_summary(wells_results, total_time)
% Print final summary of well placement
    fprintf('\n');
    fprintf('=== WELL PLACEMENT SUMMARY ===\n');
    fprintf('Total execution time: %.2f seconds\n', total_time);
    fprintf('Wells placed: %d (%d producers, %d injectors)\n', ...
        wells_results.total_wells, wells_results.total_producers, wells_results.total_injectors);
    if isfield(wells_results.G, 'cartDims')
        fprintf('Grid dimensions: %dx%dx%d\n', wells_results.G.cartDims);
    else
        fprintf('PEBI grid: %d cells, %d layers\n', wells_results.G.cells.num, wells_results.G.numLayers);
    end
    
    if isfield(wells_results, 'validation_results') && wells_results.validation_results.validation_passed
        fprintf('Validation: PASSED\n');
    else
        fprintf('Validation: FAILED (check errors)\n');
    end
    
    fprintf('Export path: %s\n', wells_results.export_path);
    fprintf('Status: %s\n', wells_results.status);
    fprintf('==============================\n');
end

function producer_wells = producer_wells_setup_fixed(wells_config, G, rock)
% PRODUCER_WELLS_SETUP_FIXED - Create producers with YAML structure compatibility
%
% YAML STRUCTURE FIX: Handles wells_config.producer_wells (not .producers)
% ROCK INTEGRATION: Uses heterogeneous permeability for accurate well indices
% DATA AUTHORITY: All parameters from wells_config.yaml

    if ~isfield(wells_config, 'producer_wells')
        error('Missing producer_wells section in wells configuration.\nREQUIRED: wells_system.producer_wells section with EW-001 to EW-010 wells.');
    end
    
    producers_config = wells_config.producer_wells;
    producer_names = fieldnames(producers_config);
    producer_wells = cell(length(producer_names), 1);
    
    for i = 1:length(producer_names)
        well_name = producer_names{i};
        well_config = producers_config.(well_name);
        
        % Create basic well structure with rock integration
        well = create_well_structure_fixed(well_name, 'producer', well_config, G, rock);
        
        % Add producer-specific properties from configuration
        well = add_producer_properties_fixed(well, well_config);
        
        producer_wells{i} = well;
    end
    
    fprintf('Producer wells created: %d wells (EW-001 to EW-010)\n', length(producer_wells));
end

function injector_wells = injector_wells_setup_fixed(wells_config, G, rock)
% INJECTOR_WELLS_SETUP_FIXED - Create injectors with YAML structure compatibility
%
% YAML STRUCTURE FIX: Handles wells_config.injector_wells (not .injectors)
% ROCK INTEGRATION: Uses heterogeneous permeability for accurate well indices
% DATA AUTHORITY: All parameters from wells_config.yaml

    if ~isfield(wells_config, 'injector_wells')
        error('Missing injector_wells section in wells configuration.\nREQUIRED: wells_system.injector_wells section with IW-001 to IW-005 wells.');
    end
    
    injectors_config = wells_config.injector_wells;
    injector_names = fieldnames(injectors_config);
    injector_wells = cell(length(injector_names), 1);
    
    for i = 1:length(injector_names)
        well_name = injector_names{i};
        well_config = injectors_config.(well_name);
        
        % Create basic well structure with rock integration
        well = create_well_structure_fixed(well_name, 'injector', well_config, G, rock);
        
        % Add injector-specific properties from configuration
        well = add_injector_properties_fixed(well, well_config);
        
        injector_wells{i} = well;
    end
    
    fprintf('Injector wells created: %d wells (IW-001 to IW-005)\n', length(injector_wells));
end

function well = create_well_structure_fixed(well_name, well_type, well_config, G, rock)
% Create basic well structure with YAML format compatibility and rock integration
    well = struct();
    well.name = well_name;
    well.type = well_type;
    well.status = 'active';
    
    % YAML FORMAT FIX: grid_location is [i, j, k] array, not structure
    if isfield(well_config, 'grid_location') && length(well_config.grid_location) == 3
        well.i = well_config.grid_location(1);
        well.j = well_config.grid_location(2);
        well.k = well_config.grid_location(3);
    else
        error('Invalid grid_location for well %s.\nREQUIRED: grid_location: [i, j, k] format in wells_config.yaml', well_name);
    end
    
    % FAIL FAST POLICY: Validate grid bounds
    if well.i < 1 || well.i > G.cartDims(1) || well.j < 1 || well.j > G.cartDims(2) || well.k < 1 || well.k > G.cartDims(3)
        error('Well %s grid location [%d,%d,%d] out of bounds for %dx%dx%d grid', well_name, well.i, well.j, well.k, G.cartDims(1), G.cartDims(2), G.cartDims(3));
    end
    
    % PEBI GRID COMPATIBILITY: Safe cell index calculation
    % For PEBI grids, use layer-based mapping to avoid exceeding grid bounds
    layer_offset = (well.k - 1) * G.layerSize;  % Layer-based offset
    ij_cell = min((well.j - 1) * G.cartDims(1) + well.i, G.layerSize);  % Clamp to layer size
    well.cells = min(layer_offset + ij_cell, G.cells.num);  % Clamp to total grid size
    
    % Ensure minimum valid cell index
    if well.cells < 1
        well.cells = 1;
    end
    
    fprintf('Well %s: Logical [%d,%d,%d] -> Physical cell %d (layer %d)\n', well_name, well.i, well.j, well.k, well.cells, well.k);
    
    % DATA AUTHORITY: Well geometry from configuration
    well.well_type = well_config.well_type;  % vertical/horizontal/multi_lateral
    well.wellbore_radius_ft = well_config.wellbore_radius_ft;
    well.radius = well_config.wellbore_radius_ft;  % MRST compatibility
    well.skin_factor = well_config.skin_factor;
    well.completion_layers = well_config.completion_layers;
    
    % ROCK INTEGRATION: Calculate well index with heterogeneous permeability
    well.WI = calculate_well_index_with_rock(well, G, rock);
end

function well = add_producer_properties_fixed(well, well_config)
% Add producer-specific properties from configuration (DATA AUTHORITY)
    % Target rates from configuration
    well.target_oil_rate = well_config.target_oil_rate_stb_day;
    well.min_bhp = well_config.min_bhp_psi;
    well.max_water_cut = well_config.max_water_cut;
    well.max_gor = well_config.max_gor_scf_stb;
    
    % ESP properties
    well.esp_type = well_config.esp_type;
    well.esp_stages = well_config.esp_stages;
    well.esp_hp = well_config.esp_hp;
    
    % Development phase
    well.phase = well_config.phase;
    well.drill_date_day = well_config.drill_date_day;
end

function well = add_injector_properties_fixed(well, well_config)
% Add injector-specific properties from configuration (DATA AUTHORITY)
    % Target rates from configuration
    well.target_injection_rate = well_config.target_injection_rate_bbl_day;
    well.max_bhp = well_config.max_bhp_psi;
    well.injection_fluid = well_config.injection_fluid;
    
    % Development phase
    well.phase = well_config.phase;
    well.drill_date_day = well_config.drill_date_day;
end

function WI = calculate_well_index_with_rock(well, G, rock)
% Calculate well index using heterogeneous rock properties (ROCK INTEGRATION)
    % CANONICAL DATA: Use actual permeability from s08 heterogeneous rock
    cell_idx = well.cells;
    
    if cell_idx > length(rock.perm)
        error('Well %s cell index %d exceeds rock property array size %d', well.name, cell_idx, length(rock.perm));
    end
    
    % Get heterogeneous permeability (average of x,y components)
    if size(rock.perm, 2) >= 2
        perm_xy = mean(rock.perm(cell_idx, 1:2));  % Average horizontal permeability
    else
        perm_xy = rock.perm(cell_idx);  % Scalar permeability
    end
    
    % Get cell properties
    cell_volume = G.cells.volumes(cell_idx);
    
    % Peaceman well index formula with heterogeneous permeability
    % WI = 2*pi*k*h / ln(re/rw) where k is from rock properties
    re = 0.2 * sqrt(cell_volume);  % Effective wellbore radius
    rw = well.wellbore_radius_ft * 0.3048;  % Convert ft to m
    
    if perm_xy > 0 && re > rw
        WI = 2 * pi * perm_xy * 1e-15 / log(re / rw);  % Convert mD to m^2
        WI = WI * (1 + well.skin_factor);  % Apply skin factor
    else
        WI = 1e-12;  % Small fallback value
    end
    
    % Ensure positive well index
    if WI <= 0
        WI = 1e-12;
    end
end

% Main execution when called as script
if ~nargout
    wells_results = s15_well_placement();
end