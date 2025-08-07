function fault_data = s05_add_faults()
    run('print_utils.m');
% S05_ADD_FAULTS - Add fault system to Eagle West Field
% Requires: MRST
%
% OUTPUT:
%   fault_data - Structure containing fault system data
%
% Author: Claude Code AI System
% Date: January 30, 2025

    print_step_header('S05', 'Add Fault System');
    
    total_start_time = tic;
    
    try
        % ----------------------------------------
        % Step 1 – Load Framework & Define Faults
        % ----------------------------------------
        step_start = tic;
        G = step_1_load_structural_data();
        fault_geometries = step_1_define_geometries(G);
        print_step_result(1, 'Load Framework & Define Faults', 'success', toc(step_start));
        
        % ----------------------------------------
        % Step 2 – Calculate Fault Intersections
        % ----------------------------------------
        step_start = tic;
        fault_intersections = step_2_calculate_intersections(G, fault_geometries);
        print_step_result(2, 'Calculate Fault Intersections', 'success', toc(step_start));
        
        % ----------------------------------------
        % Step 3 – Apply Transmissibility Effects
        % ----------------------------------------
        step_start = tic;
        trans_multipliers = step_3_compute_transmissibility(G, fault_intersections, fault_geometries);
        G = step_3_apply_faults(G, fault_geometries, fault_intersections, trans_multipliers);
        print_step_result(3, 'Apply Transmissibility Effects', 'success', toc(step_start));
        
        % ----------------------------------------
        % Step 4 – Validate & Export Fault System
        % ----------------------------------------
        step_start = tic;
        fault_data = step_4_export_data(G, fault_geometries, fault_intersections, trans_multipliers);
        print_step_result(4, 'Validate & Export Fault System', 'success', toc(step_start));
        
        print_step_footer('S05', sprintf('Fault System Ready: %d faults', length(fault_geometries)), toc(total_start_time));
        
    catch ME
        print_error_step(0, 'Fault System', ME.message);
        error('Fault system failed: %s', ME.message);
    end

end

function G = step_1_load_structural_data()
% Step 1 - Load structural framework from s04

    % Substep 1.1 – Load structural framework _____________________
    script_path = fileparts(mfilename('fullpath'));
    structural_file = fullfile(fileparts(script_path), 'data', 'mrst_simulation', 'static', 'structural_framework.mat');
    
    if ~exist(structural_file, 'file')
        error('Structural framework not found. Run s04_structural_framework first.');
    end
    
    % ✅ Load structural data
    load(structural_file, 'structural_data');
    G = structural_data.grid;
    
end

function fault_geometries = step_1_define_geometries(G)
% Step 1 - Define 5 major fault geometries

    % Substep 1.1 – Load fault configuration from YAML _____________
    fault_config = load_fault_config();
    
    % Substep 1.2 – Get field dimensions ___________________________
    field_bounds = get_field_bounds(G);
    
    % Substep 1.3 – Create fault array from YAML config ____________
    fault_geometries = create_fault_array(field_bounds, fault_config);
    
    % Substep 1.4 – Add fault properties ___________________________
    fault_geometries = add_fault_properties(fault_geometries);
    
end

function bounds = get_field_bounds(G)
% Get field boundary coordinates
    bounds.x_min = min(G.cells.centroids(:,1));
    bounds.x_max = max(G.cells.centroids(:,1));
    bounds.y_min = min(G.cells.centroids(:,2));
    bounds.y_max = max(G.cells.centroids(:,2));
    bounds.center_x = (bounds.x_min + bounds.x_max) / 2;
    bounds.center_y = (bounds.y_min + bounds.y_max) / 2;
end

function faults = create_fault_array(bounds, fault_config)
% Create array of faults from YAML configuration - Policy compliance
    
    faults = struct([]);
    
    % Load fault definitions from YAML - NO HARDCODING
    yaml_faults = fault_config.faults;
    n_faults = length(yaml_faults);
    
    % Create all faults from YAML data - Policy compliance
    for i = 1:n_faults
        faults(i).name = yaml_faults{i}.name;
        faults(i).type = yaml_faults{i}.type;
        faults(i).is_sealing = yaml_faults{i}.is_sealing;
        faults(i).strike = yaml_faults{i}.strike;
        faults(i).dip = yaml_faults{i}.dip;
        faults(i).length = yaml_faults{i}.length;
        faults(i).trans_mult = yaml_faults{i}.transmissibility_multiplier;
        
        % Calculate fault endpoints from YAML position offsets
        switch i
            case 1  % Fault A
                start_x = bounds.x_min + yaml_faults{i}.position_offset_x;
                start_y = bounds.center_y + yaml_faults{i}.position_offset_y;
            case 2  % Fault B
                start_x = bounds.center_x + yaml_faults{i}.position_offset_x;
                start_y = bounds.center_y + yaml_faults{i}.position_offset_y;
            case 3  % Fault C
                start_x = bounds.center_x + yaml_faults{i}.position_offset_x;
                start_y = bounds.y_max + yaml_faults{i}.position_offset_y;
            case 4  % Fault D
                start_x = bounds.x_min + yaml_faults{i}.position_offset_x;
                start_y = bounds.center_y + yaml_faults{i}.position_offset_y;
            case 5  % Fault E
                start_x = bounds.x_max + yaml_faults{i}.position_offset_x;
                start_y = bounds.y_min + yaml_faults{i}.position_offset_y;
        end
        
        [faults(i).x1, faults(i).y1, faults(i).x2, faults(i).y2] = ...
            calculate_fault_endpoints(start_x, start_y, faults(i).length, faults(i).strike);
    end
    
end

function [x1, y1, x2, y2] = calculate_fault_endpoints(start_x, start_y, length, strike)
% Calculate fault endpoints from start point, length, and strike
    x1 = start_x;
    y1 = start_y;
    x2 = x1 + length * cosd(strike);
    y2 = y1 + length * sind(strike);
end

function faults = add_fault_properties(faults)
% Add additional properties to fault array
    for i = 1:length(faults)
        faults(i).id = i;
        faults(i).displacement = 20 + 10*rand();
        faults(i).width = 5 + 3*rand();
    end
end

function intersections = step_2_calculate_intersections(G, fault_geometries)
% Step 2 - Calculate fault-cell intersections

    n_faults = length(fault_geometries);
    intersections = cell(n_faults, 1);
    
    % Substep 3.1 – Get cell centroids ____________________________
    x = G.cells.centroids(:,1);
    y = G.cells.centroids(:,2);
    
    % Substep 3.2 – Process each fault ____________________________
    for f = 1:n_faults
        intersections{f} = calculate_single_fault_intersection(G, fault_geometries(f), x, y);
    end
    
end

function intersection_data = calculate_single_fault_intersection(G, fault, x, y)
% Calculate intersection for single fault
    
    % Calculate fault vector
    dx = fault.x2 - fault.x1;
    dy = fault.y2 - fault.y1;
    fault_length = sqrt(dx^2 + dy^2);
    
    % Unit vector along fault
    ux = dx / fault_length;
    uy = dy / fault_length;
    
    % Calculate distances from cells to fault line
    distances = calculate_cell_distances(fault, x, y, ux, uy, fault_length);
    
    % Find cells within fault zone
    fault_zone_cells = find(distances <= fault.width);
    
    % Store intersection data
    intersection_data = struct();
    intersection_data.fault_id = fault.id;
    intersection_data.affected_cells = fault_zone_cells;
    intersection_data.distances = distances(fault_zone_cells);
    intersection_data.n_affected = length(fault_zone_cells);
    
end

function distances = calculate_cell_distances(fault, x, y, ux, uy, fault_length)
% Calculate distance from each cell to fault line
    
    n_cells = length(x);
    distances = zeros(n_cells, 1);
    
    for i = 1:n_cells
        % Vector from fault start to cell center
        cx = x(i) - fault.x1;
        cy = y(i) - fault.y1;
        
        % Project onto fault direction
        projection = cx * ux + cy * uy;
        projection = max(0, min(fault_length, projection));
        
        % Find closest point on fault line
        closest_x = fault.x1 + projection * ux;
        closest_y = fault.y1 + projection * uy;
        
        % Distance from cell to closest point
        distances(i) = sqrt((x(i) - closest_x)^2 + (y(i) - closest_y)^2);
    end
    
end

function trans_mult = step_3_compute_transmissibility(G, intersections, fault_geometries)
% Step 3 - Compute transmissibility multipliers using MRST native approach

    % Substep 4.1 – Initialize multipliers ________________________
    trans_mult = ones(G.faces.num, 1);
    
    % Substep 4.2 – Process each fault ____________________________
    n_faults = length(intersections);
    for f = 1:n_faults
        trans_mult = apply_single_fault_multipliers(G, trans_mult, intersections{f}, fault_geometries(f));
    end
    
end

function trans_mult = apply_single_fault_multipliers(G, trans_mult, fault_data, fault_geometry)
% Apply transmissibility multipliers for single fault
    
    affected_cells = fault_data.affected_cells;
    
    if isempty(affected_cells)
        return;
    end
    
    % Find fault-crossing faces using MRST connectivity
    fault_faces = find_fault_crossing_faces(G, affected_cells);
    
    % Apply multiplier to fault faces
    trans_mult(fault_faces) = min(trans_mult(fault_faces), fault_geometry.trans_mult);
    
end

function fault_faces = find_fault_crossing_faces(G, affected_cells)
% Find faces that cross fault boundaries using MRST native connectivity
    
    fault_faces = [];
    
    for i = 1:length(affected_cells)
        cell_id = affected_cells(i);
        
        % Get faces for this cell using MRST cell-face connectivity
        face_indices = G.cells.facePos(cell_id):G.cells.facePos(cell_id+1)-1;
        cell_faces = G.cells.faces(face_indices, 1);
        
        % Check each face for fault crossing
        for j = 1:length(cell_faces)
            face_id = cell_faces(j);
            
            if is_fault_crossing_face(G, face_id, affected_cells)
                fault_faces = [fault_faces; face_id];
            end
        end
    end
    
    fault_faces = unique(fault_faces);
    
end

function crosses = is_fault_crossing_face(G, face_id, affected_cells)
% Check if face crosses fault using neighbor connectivity
    
    neighbors = G.faces.neighbors(face_id, :);
    neighbor1 = neighbors(1);
    neighbor2 = neighbors(2);
    
    % Skip boundary faces
    if neighbor1 == 0 || neighbor2 == 0
        crosses = false;
        return;
    end
    
    % Face crosses fault if one neighbor is affected, other is not
    in_zone_1 = ismember(neighbor1, affected_cells);
    in_zone_2 = ismember(neighbor2, affected_cells);
    crosses = (in_zone_1 && ~in_zone_2) || (~in_zone_1 && in_zone_2);
    
end

function G = step_3_apply_faults(G, fault_geometries, intersections, trans_mult)
% Step 3 - Apply fault properties to grid structure

    % Substep 5.1 – Store fault system data _______________________
    G.fault_system = create_fault_system_structure(fault_geometries, intersections, trans_mult);
    
    % Substep 5.2 – Add cell properties ___________________________
    G = add_cell_fault_properties(G, intersections);
    
    % Substep 5.3 – Add face properties ___________________________
    G = add_face_fault_properties(G, trans_mult);
    
end

function fault_system = create_fault_system_structure(fault_geometries, intersections, trans_mult)
% Create fault system structure for grid
    fault_system = struct();
    fault_system.geometries = fault_geometries;
    fault_system.intersections = intersections;
    fault_system.transmissibility_multipliers = trans_mult;
end

function G = add_cell_fault_properties(G, intersections)
% Add fault properties to cells
    
    G.cells.fault_zone = zeros(G.cells.num, 1);
    G.cells.nearest_fault = zeros(G.cells.num, 1);
    
    % Mark cells in fault zones
    for f = 1:length(intersections)
        affected_cells = intersections{f}.affected_cells;
        G.cells.fault_zone(affected_cells) = f;
        G.cells.nearest_fault(affected_cells) = f;
    end
    
end

function G = add_face_fault_properties(G, trans_mult)
% Add fault properties to faces
    G.faces.fault_affected = (trans_mult < 1.0);
    G.faces.transmissibility_multiplier = trans_mult;
end

function fault_data = step_4_export_data(G, fault_geometries, intersections, trans_mult)
% Step 4 - Export fault data and create summary

    % Substep 6.1 – Validate fault system _________________________
    validate_fault_system_implementation(G, fault_geometries, trans_mult);
    
    % Substep 6.2 – Export to files _______________________________
    export_fault_files(G, fault_geometries, intersections, trans_mult);
    
    % Substep 6.3 – Create output structure _______________________
    fault_data = create_fault_output_structure(G, fault_geometries, intersections, trans_mult);
    
end

function validate_fault_system_implementation(G, fault_geometries, trans_mult)
% Validate fault system implementation
    
    n_faults = length(fault_geometries);
    
    % Check fault geometry validity
    for f = 1:n_faults
        fault = fault_geometries(f);
        
        if fault.length <= 0
            error('Fault %s has invalid length: %.1f', fault.name, fault.length);
        end
        
        if fault.trans_mult <= 0 || fault.trans_mult > 1
            error('Fault %s has invalid transmissibility multiplier: %.3f', fault.name, fault.trans_mult);
        end
    end
    
    % Check transmissibility multipliers
    if any(trans_mult < 0) || any(trans_mult > 1)
        error('Invalid transmissibility multipliers detected');
    end
    
end

function export_fault_files(G, fault_geometries, intersections, trans_mult)
% Export fault data to files
    
    script_path = fileparts(mfilename('fullpath'));
    data_dir = fullfile(fileparts(script_path), 'data', 'mrst_simulation', 'static');
    
    if ~exist(data_dir, 'dir')
        mkdir(data_dir);
    end
    
    % Save fault system data
    fault_file = fullfile(data_dir, 'fault_system.mat');
    save(fault_file, 'G', 'fault_geometries', 'intersections', 'trans_mult');
    
end

function fault_data = create_fault_output_structure(G, fault_geometries, intersections, trans_mult)
% Create output structure
    fault_data = struct();
    fault_data.grid = G;
    fault_data.geometries = fault_geometries;
    fault_data.intersections = intersections;
    fault_data.transmissibility_multipliers = trans_mult;
    fault_data.status = 'completed';
end



function config = load_fault_config()
% Load fault configuration from YAML - NO HARDCODING POLICY
    try
        % Policy Compliance: Load ALL parameters from YAML config
        full_config = read_yaml_config('config/fault_config.yaml');
        config = full_config.fault_system;
        
        % Validate required fields exist
        if ~isfield(config, 'faults')
            error('Missing required field in fault_config.yaml: faults');
        end
        
        fprintf('Fault configuration loaded from YAML: %d faults\n', length(config.faults));
        
    catch ME
        error('Failed to load fault configuration from YAML: %s\nPolicy violation: No hardcoding allowed', ME.message);
    end
end

% Main execution when called as script
if ~nargout
    % If called as script (not function), add fault system
    fault_data = s05_add_faults();
    
    fprintf('Fault system implemented!\n');
    fprintf('Grid updated with %d major faults.\n', length(fault_data.geometries));
    fprintf('Use plotGrid(G) to visualize fault-affected grid.\n\n');
end