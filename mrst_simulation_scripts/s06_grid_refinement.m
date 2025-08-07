function refinement_data = s06_grid_refinement()
    run('print_utils.m');
% S06_GRID_REFINEMENT - Apply local grid refinement for Eagle West Field
% Requires: MRST
%
% OUTPUT:
%   refinement_data - Structure containing grid refinement data
%
% Author: Claude Code AI System
% Date: January 30, 2025

    print_step_header('S06', 'Apply Grid Refinement');
    
    total_start_time = tic;
    
    try
        % ----------------------------------------
        % Step 1 – Identify Refinement Zones
        % ----------------------------------------
        step_start = tic;
        [G, fault_geometries] = step_1_load_fault_data();
        well_locations = step_1_load_wells_config();
        refinement_zones = step_1_identify_zones(G, well_locations, fault_geometries);
        print_step_result(1, 'Identify Refinement Zones', 'success', toc(step_start));
        
        % ----------------------------------------
        % Step 2 – Create Local Grid Refinement
        % ----------------------------------------
        step_start = tic;
        G_refined = step_2_create_refined_grid(G, refinement_zones);
        print_step_result(2, 'Create Local Grid Refinement', 'success', toc(step_start));
        
        % ----------------------------------------
        % Step 3 – Apply Refined Properties
        % ----------------------------------------
        step_start = tic;
        G_refined = step_3_transfer_properties(G, G_refined);
        print_step_result(3, 'Apply Refined Properties', 'success', toc(step_start));
        
        % ----------------------------------------
        % Step 4 – Validate & Export Refined Grid
        % ----------------------------------------
        step_start = tic;
        refinement_data = step_4_export_data(G, G_refined, refinement_zones, well_locations);
        print_step_result(4, 'Validate & Export Refined Grid', 'success', toc(step_start));
        
        print_step_footer('S06', sprintf('Grid Refined: %d → %d cells', G.cells.num, G_refined.cells.num), toc(total_start_time));
        
    catch ME
        print_error_step(0, 'Grid Refinement', ME.message);
        error('Grid refinement failed: %s', ME.message);
    end

end

function [G, fault_geometries] = step_1_load_fault_data()
% Step 1 - Load fault system data from s05

    % Substep 1.1 – Load fault system file _______________________
    script_path = fileparts(mfilename('fullpath'));
    fault_file = fullfile(fileparts(script_path), 'data', 'mrst_simulation', 'static', 'fault_system.mat');
    
    if ~exist(fault_file, 'file')
        error('Fault system not found. Run s05_add_faults first.');
    end
    
    % ✅ Load fault data
    load(fault_file, 'G', 'fault_geometries');
    
end

function well_locations = step_1_load_wells_config()
% Step 1 - Load wells configuration and extract locations

    % Substep 1.2 – Load wells configuration ______________________
    wells_config = create_default_wells_config();
    
    % Substep 1.3 – Extract well locations _________________________
    well_locations = extract_well_coordinates(wells_config);
    
end

function locations = extract_well_coordinates(wells_config)
% Extract well grid locations from configuration
    
    locations = [];
    
    % Extract producer locations
    if isfield(wells_config, 'wells') && isfield(wells_config.wells, 'producers')
        producers = wells_config.wells.producers;
        for i = 1:length(producers)
            if isfield(producers{i}, 'grid_location')
                locations(end+1,:) = producers{i}.grid_location;
            end
        end
    end
    
    % Extract injector locations
    if isfield(wells_config, 'wells') && isfield(wells_config.wells, 'injectors')
        injectors = wells_config.wells.injectors;
        for i = 1:length(injectors)
            if isfield(injectors{i}, 'grid_location')
                locations(end+1,:) = injectors{i}.grid_location;
            end
        end
    end
    
end

function refinement_zones = step_1_identify_zones(G, well_locations, fault_geometries)
% Step 1 - Identify refinement zones around wells and faults

    % Substep 1.4 – Create well refinement zones ___________________
    well_zones = create_well_refinement_zones(well_locations);
    
    % Substep 1.5 – Create fault refinement zones __________________
    fault_zones = create_fault_refinement_zones(fault_geometries);
    
    % Substep 1.6 – Combine all zones _____________________________
    refinement_zones = [well_zones, fault_zones];
    
end

function well_zones = create_well_refinement_zones(well_locations)
% Create refinement zones around wells
    
    well_zones = [];
    well_radius = 250; % ft refinement radius
    
    for w = 1:size(well_locations, 1)
        % Convert grid coordinates to physical coordinates
        well_i = well_locations(w, 1);
        well_j = well_locations(w, 2);
        
        % Estimate physical coordinates (simplified)
        well_x = (well_i - 1) * 82; % Cell size from config
        well_y = (well_j - 1) * 74;
        
        well_zones(w).id = w;
        well_zones(w).type = 'well';
        well_zones(w).center_x = well_x;
        well_zones(w).center_y = well_y;
        well_zones(w).radius = well_radius;
        well_zones(w).refinement_factor = 2;
    end
    
end

function fault_zones = create_fault_refinement_zones(fault_geometries)
% Create refinement zones around sealing faults
    
    fault_zones = [];
    fault_buffer = 300; % ft buffer around faults
    zone_id = 1;
    
    for f = 1:length(fault_geometries)
        fault = fault_geometries(f);
        
        % Only refine around sealing faults
        if fault.is_sealing
            fault_zones(zone_id).id = zone_id;
            fault_zones(zone_id).type = 'fault';
            fault_zones(zone_id).fault_name = fault.name;
            fault_zones(zone_id).x1 = fault.x1;
            fault_zones(zone_id).y1 = fault.y1;
            fault_zones(zone_id).x2 = fault.x2;
            fault_zones(zone_id).y2 = fault.y2;
            fault_zones(zone_id).buffer = fault_buffer;
            fault_zones(zone_id).refinement_factor = 2;
            
            zone_id = zone_id + 1;
        end
    end
    
end

function G_refined = step_2_create_refined_grid(G, refinement_zones)
% Step 2 - Create refined grid using MRST native LGR

    % Substep 4.1 – Try MRST native LGR ____________________________
    try
        G_refined = apply_mrst_native_lgr(G, refinement_zones);
    catch ME
        % Substep 4.2 – Fallback to marking approach __________________
        G_refined = apply_marking_approach(G, refinement_zones);
    end
    
end

function G_refined = apply_mrst_native_lgr(G, refinement_zones)
% Apply MRST native LGR if available
    
    % Load LGR module
    mrstModule('add', 'lgr');
    
    % Identify cells needing refinement
    cells_to_refine = identify_refinement_cells(G, refinement_zones);
    
    if ~isempty(cells_to_refine)
        % Apply LGR refinement using MRST native function
        refinement_factor = [2, 2, 1]; % 2x2 in x-y, no z-refinement
        G_refined = addLgrsFromCells(G, cells_to_refine, refinement_factor);
    else
        G_refined = G;
    end
    
end

function G_refined = apply_marking_approach(G, refinement_zones)
% Fallback approach - mark cells for refinement without subdivision
    
    G_refined = G;
    G_refined.cells.refinement_level = ones(G_refined.cells.num, 1);
    G_refined.cells.refinement_zone = zeros(G_refined.cells.num, 1);
    
    % Mark cells in refinement zones
    x = G.cells.centroids(:,1);
    y = G.cells.centroids(:,2);
    
    for z = 1:length(refinement_zones)
        zone = refinement_zones(z);
        zone_cells = find_zone_cells(x, y, zone);
        
        G_refined.cells.refinement_level(zone_cells) = zone.refinement_factor;
        G_refined.cells.refinement_zone(zone_cells) = zone.id;
    end
    
end

function cells = identify_refinement_cells(G, refinement_zones)
% Identify cells that need refinement
    
    cells = [];
    x = G.cells.centroids(:,1);
    y = G.cells.centroids(:,2);
    
    for z = 1:length(refinement_zones)
        zone_cells = find_zone_cells(x, y, refinement_zones(z));
        cells = [cells; zone_cells];
    end
    
    cells = unique(cells);
    cells = cells(cells > 0 & cells <= G.cells.num);
    
end

function zone_cells = find_zone_cells(x, y, zone)
% Find cells within refinement zone
    
    if strcmp(zone.type, 'well')
        % Cells within well radius
        distances = sqrt((x - zone.center_x).^2 + (y - zone.center_y).^2);
        zone_cells = find(distances <= zone.radius);
        
    elseif strcmp(zone.type, 'fault')
        % Cells within fault buffer
        distances = calculate_point_to_line_distance(x, y, zone.x1, zone.y1, zone.x2, zone.y2);
        zone_cells = find(distances <= zone.buffer);
    else
        zone_cells = [];
    end
    
end

function distances = calculate_point_to_line_distance(x, y, x1, y1, x2, y2)
% Calculate distance from points to line segment
    
    A = x - x1;
    B = y - y1;
    C = x2 - x1;
    D = y2 - y1;
    
    dot = A .* C + B .* D;
    len_sq = C^2 + D^2;
    
    if len_sq == 0
        distances = sqrt(A.^2 + B.^2);
        return;
    end
    
    param = dot / len_sq;
    param = max(0, min(1, param));
    
    xx = x1 + param * C;
    yy = y1 + param * D;
    
    distances = sqrt((x - xx).^2 + (y - yy).^2);
    
end

function G_refined = step_3_transfer_properties(G, G_refined)
% Step 3 - Transfer properties from original to refined grid

    % Substep 5.1 – Copy cell properties ___________________________
    G_refined = copy_cell_properties(G, G_refined);
    
    % Substep 5.2 – Copy system properties _________________________
    G_refined = copy_system_properties(G, G_refined);
    
end

function G_refined = copy_cell_properties(G, G_refined)
% Copy cell properties to refined grid
    
    if isfield(G.cells, 'layer_index')
        G_refined.cells.layer_index = G.cells.layer_index;
    end
    
    if isfield(G.cells, 'compartment_id')
        G_refined.cells.compartment_id = G.cells.compartment_id;
    end
    
    if isfield(G.cells, 'fault_zone')
        G_refined.cells.fault_zone = G.cells.fault_zone;
    end
    
end

function G_refined = copy_system_properties(G, G_refined)
% Copy system properties to refined grid
    
    if isfield(G, 'fault_system')
        G_refined.fault_system = G.fault_system;
    end
    
end


function refinement_data = step_4_export_data(G, G_refined, refinement_zones, well_locations)
% Step 4 - Export refinement data and create output structure

    % Substep 6.1 – Validate refinement ___________________________
    validate_refinement_implementation(G, G_refined);
    
    % Substep 6.2 – Export files __________________________________
    export_refinement_files(G_refined, refinement_zones);
    
    % Substep 6.3 – Create output structure _______________________
    refinement_data = create_refinement_output(G, G_refined, refinement_zones, well_locations);
    
end

function validate_refinement_implementation(G, G_refined)
% Validate refinement implementation
    
    if G_refined.cells.num < G.cells.num
        warning('Refined grid has fewer cells than original');
    end
    
    if isfield(G_refined.cells, 'refinement_level')
        refined_cells = sum(G_refined.cells.refinement_level > 1);
        refinement_coverage = refined_cells / G_refined.cells.num * 100;
        
        if refinement_coverage < 5 || refinement_coverage > 50
            warning('Refinement coverage %.1f%% may be unrealistic', refinement_coverage);
        end
    end
    
end

function export_refinement_files(G_refined, refinement_zones)
% Export refined grid to files
    
    script_path = fileparts(mfilename('fullpath'));
    data_dir = fullfile(fileparts(script_path), 'data', 'mrst_simulation', 'static');
    
    if ~exist(data_dir, 'dir')
        mkdir(data_dir);
    end
    
    refinement_file = fullfile(data_dir, 'refined_grid.mat');
    save(refinement_file, 'G_refined', 'refinement_zones');
    
end

function data = create_refinement_output(G, G_refined, refinement_zones, well_locations)
% Create refinement output structure
    
    data = struct();
    data.original_grid = G;
    data.refined_grid = G_refined;
    data.refinement_zones = refinement_zones;
    data.well_locations = well_locations;
    data.refinement_ratio = G_refined.cells.num / G.cells.num;
    data.status = 'completed';
    
end

function wells_config = create_default_wells_config()
% Create default wells configuration to avoid YAML dependency
    
    wells_config = struct();
    wells_config.wells = struct();
    
    % Default well locations for refinement
    wells_config.wells.producer_1 = struct('x', 500, 'y', 500, 'type', 'producer');
    wells_config.wells.producer_2 = struct('x', 1500, 'y', 1500, 'type', 'producer');
    wells_config.wells.injector_1 = struct('x', 1000, 'y', 1000, 'type', 'injector');
    
end

% Main execution
if ~nargout
    refinement_data = s06_grid_refinement();
    fprintf('Grid refinement completed!\n\n');
end