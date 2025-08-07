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

    % Substep 1.2 – Get field dimensions ___________________________
    field_bounds = get_field_bounds(G);
    
    % Substep 1.3 – Create fault array _____________________________
    fault_geometries = create_fault_array(field_bounds);
    
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

function faults = create_fault_array(bounds)
% Create array of 5 major faults
    
    faults = struct([]);
    
    % Fault A - Major NE-SW sealing fault
    faults(1).name = 'Fault_A';
    faults(1).type = 'sealing';
    faults(1).is_sealing = true;
    faults(1).strike = 45;
    faults(1).dip = 75;
    faults(1).length = 2500;
    faults(1).trans_mult = 0.001;
    [faults(1).x1, faults(1).y1, faults(1).x2, faults(1).y2] = ...
        calculate_fault_endpoints(bounds.x_min + 400, bounds.center_y + 600, faults(1).length, faults(1).strike);
    
    % Fault B - Secondary partially sealing fault
    faults(2).name = 'Fault_B';
    faults(2).type = 'partially_sealing';
    faults(2).is_sealing = false;
    faults(2).strike = 50;
    faults(2).dip = 70;
    faults(2).length = 2000;
    faults(2).trans_mult = 0.05;
    [faults(2).x1, faults(2).y1, faults(2).x2, faults(2).y2] = ...
        calculate_fault_endpoints(bounds.center_x - 600, bounds.center_y - 200, faults(2).length, faults(2).strike);
    
    % Fault C - NW-SE cross fault
    faults(3).name = 'Fault_C';
    faults(3).type = 'sealing';
    faults(3).is_sealing = true;
    faults(3).strike = 135;
    faults(3).dip = 80;
    faults(3).length = 1800;
    faults(3).trans_mult = 0.002;
    [faults(3).x1, faults(3).y1, faults(3).x2, faults(3).y2] = ...
        calculate_fault_endpoints(bounds.center_x + 300, bounds.y_max - 300, faults(3).length, faults(3).strike);
    
    % Fault D - Southern boundary fault
    faults(4).name = 'Fault_D';
    faults(4).type = 'partially_sealing';
    faults(4).is_sealing = false;
    faults(4).strike = 40;
    faults(4).dip = 65;
    faults(4).length = 2200;
    faults(4).trans_mult = 0.1;
    [faults(4).x1, faults(4).y1, faults(4).x2, faults(4).y2] = ...
        calculate_fault_endpoints(bounds.x_min + 600, bounds.center_y - 700, faults(4).length, faults(4).strike);
    
    % Fault E - Eastern boundary fault
    faults(5).name = 'Fault_E';
    faults(5).type = 'sealing';
    faults(5).is_sealing = true;
    faults(5).strike = 30;
    faults(5).dip = 78;
    faults(5).length = 1600;
    faults(5).trans_mult = 0.001;
    [faults(5).x1, faults(5).y1, faults(5).x2, faults(5).y2] = ...
        calculate_fault_endpoints(bounds.x_max - 800, bounds.y_min + 400, faults(5).length, faults(5).strike);
    
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



% Main execution when called as script
if ~nargout
    % If called as script (not function), add fault system
    fault_data = s05_add_faults();
    
    fprintf('Fault system implemented!\n');
    fprintf('Grid updated with %d major faults.\n', length(fault_data.geometries));
    fprintf('Use plotGrid(G) to visualize fault-affected grid.\n\n');
end