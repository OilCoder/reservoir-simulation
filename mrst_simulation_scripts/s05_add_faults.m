function fault_data = s05_add_faults()
% S05_ADD_FAULTS - Implement 5-fault system for Eagle West Field with sealing properties
%
% PURPOSE:
%   Implements the complete Eagle West Field fault system with 5 major faults (Fault_A to Fault_E)
%   providing compartmentalization and flow barriers. Calculates fault-grid intersections,
%   applies transmissibility multipliers for sealing behavior, and enhances grid with
%   fault properties for reservoir simulation. Critical for compartment flow modeling.
%
% SCOPE:
%   - 5 major fault geometry definition (NE-SW trending normal faults)
%   - Fault-cell intersection calculations using MRST connectivity
%   - Transmissibility multiplier application to fault-crossing faces
%   - Grid enhancement with fault zone properties and affected cells
%   - Does NOT: Modify grid geometry, create new grids, or handle rock properties
%
% WORKFLOW POSITION:
%   Fifth step in Eagle West Field MRST workflow sequence:
%   s01 (Initialize) → s02 (Fluids) → s03 (PEBI Grid) → s04 (Structure) → s05 (Faults)
%   Dependencies: s04 (structural framework) | Used by: s06 (refinement), s07 (rock)
%
% INPUTS:
%   - data/static/structural_framework.mat - Framework from s04_structural_framework.m
%   - config/fault_config.yaml - Eagle West fault specifications (Fault_A to Fault_E)
%   - MRST session from s01_initialize_mrst.m
%
% OUTPUTS:
%   fault_data - Complete fault system structure containing:
%     .grid - Enhanced grid with fault properties
%     .geometries - Array of 5 fault geometries with endpoints
%     .intersections - Cell arrays of fault-grid intersections
%     .transmissibility_multipliers - Face-based T-multipliers
%     .status - 'completed' when successful
%
% CONFIGURATION:
%   - fault_config.yaml - Complete Eagle West fault specification
%   - Key parameters: 5 faults, 3 sealing (T≤0.01), 2 partially sealing (T>0.01)
%   - Fault geometry: Strike, dip, length, position offsets, transmissibility values
%
% CANONICAL REFERENCE:
%   - Specification: obsidian-vault/Planning/Reservoir_Definition/01_Structural_Geology.md
%   - Implementation: Major faults (Fault_A, C, D) sealing, minor faults (Fault_B, E) leaky
%   - Canon-first: FAIL_FAST when fault configuration missing from YAML
%
% EXAMPLES:
%   % Implement fault system
%   fault_data = s05_add_faults();
%   
%   % Verify fault implementation
%   fprintf('Fault system: %d faults implemented\n', length(fault_data.geometries));
%   fprintf('Sealing faces: %d\n', sum(fault_data.grid.faces.fault_multiplier < 0.1));
%
% Author: Claude Code AI System
% Date: 2025-08-14 (Updated with comprehensive headers)
% Implementation: Eagle West Field MRST Workflow Phase 5

    script_dir = fileparts(mfilename('fullpath'));
    addpath(fullfile(script_dir, 'utils')); 
    run(fullfile(script_dir, 'utils', 'print_utils.m'));

    % Add MRST session validation
    [success, message] = validate_mrst_session(script_dir);
    if ~success
        error('MRST validation failed: %s', message);
    end

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
    func_dir = fileparts(mfilename('fullpath'));
    addpath(fullfile(func_dir, 'utils'));
    data_dir = get_data_path('static');
    structural_file = fullfile(data_dir, 'structural_framework.mat');
    
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
    fault_geometries = add_fault_properties(fault_geometries, fault_config);
    
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
    fault_names = fieldnames(yaml_faults);
    n_faults = length(fault_names);
    
    % Create all faults from YAML data - Policy compliance
    for i = 1:n_faults
        fault_name = fault_names{i};
        fault_data = yaml_faults.(fault_name);
        
        faults(i).name = fault_data.name;
        faults(i).type = fault_data.type;
        faults(i).is_sealing = fault_data.is_sealing;
        faults(i).strike = fault_data.strike;
        faults(i).dip = fault_data.dip;
        faults(i).length = fault_data.length;
        faults(i).trans_mult = fault_data.transmissibility_multiplier;
        
        % Calculate fault endpoints from YAML position offsets
        switch i
            case 1  % Fault A
                start_x = bounds.x_min + fault_data.position_offset_x;
                start_y = bounds.center_y + fault_data.position_offset_y;
            case 2  % Fault B
                start_x = bounds.center_x + fault_data.position_offset_x;
                start_y = bounds.center_y + fault_data.position_offset_y;
            case 3  % Fault C
                start_x = bounds.center_x + fault_data.position_offset_x;
                start_y = bounds.y_max + fault_data.position_offset_y;
            case 4  % Fault D
                start_x = bounds.x_min + fault_data.position_offset_x;
                start_y = bounds.center_y + fault_data.position_offset_y;
            case 5  % Fault E
                start_x = bounds.x_max + fault_data.position_offset_x;
                start_y = bounds.y_min + fault_data.position_offset_y;
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

function faults = add_fault_properties(faults, fault_config)
% Add additional properties to fault array
    for i = 1:length(faults)
        % Use cached config to avoid re-reading file - Policy compliance
        geom_params = fault_config.fault_system_properties;
        base_displacement = geom_params.displacement_base;     % From YAML
        disp_variation = geom_params.displacement_variation;   % From YAML  
        base_width = geom_params.width_base;                   % From YAML
        width_variation = geom_params.width_variation;         % From YAML
        
        faults(i).id = i;
        faults(i).displacement = base_displacement + disp_variation*rand();
        faults(i).width = base_width + width_variation*rand();
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
% Export fault data to files using canonical organization
    
    try
        % Load canonical data utilities
        func_dir = fileparts(mfilename('fullpath'));
        addpath(fullfile(func_dir, 'utils'));
        run(fullfile(func_dir, 'utils', 'canonical_data_utils.m'));
        run(fullfile(func_dir, 'utils', 'directory_management.m'));
        
        % Create basic canonical directory structure
        base_data_path = fullfile(fileparts(func_dir), 'data');
        static_path = fullfile(base_data_path, 'by_type', 'static');
        if ~exist(static_path, 'dir')
            mkdir(static_path);
        end
        
        % Save fault system directly in canonical structure
        fault_file = fullfile(static_path, 'fault_system_s05.mat');
        save(fault_file, 'fault_geometries', 'trans_mult', 'intersections', 'G');
        
        % Count sealing vs leaky faults
        sealing_count = 0;
        for i = 1:length(fault_geometries)
            if fault_geometries(i).trans_mult <= 0.01
                sealing_count = sealing_count + 1;
            end
        end
        fprintf('     Canonical fault system saved: %s\n', fault_file);
        
        % Maintain legacy compatibility during transition
        legacy_data_dir = get_data_path('static');
        if ~exist(legacy_data_dir, 'dir')
            mkdir(legacy_data_dir);
        end
        legacy_fault_file = fullfile(legacy_data_dir, 'fault_system.mat');
        save(legacy_fault_file, 'G', 'fault_geometries', 'intersections', 'trans_mult');
        
        fprintf('     Legacy compatibility maintained: %s\n', legacy_fault_file);
        
    catch ME
        fprintf('Warning: Canonical export failed: %s\n', ME.message);
        
        % Fallback to legacy export
        func_dir = fileparts(mfilename('fullpath'));
        addpath(fullfile(func_dir, 'utils'));
        data_dir = get_data_path('static');
        
        if ~exist(data_dir, 'dir')
            mkdir(data_dir);
        end
        
        fault_file = fullfile(data_dir, 'fault_system.mat');
        save(fault_file, 'G', 'fault_geometries', 'intersections', 'trans_mult');
        fprintf('     Fallback: Fault system saved to: %s\n', fault_file);
    end
    
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
        func_dir = fileparts(mfilename('fullpath'));
        addpath(fullfile(func_dir, 'utils'));
        full_config = read_yaml_config('config/fault_config.yaml');
        config = full_config.fault_system;
        
        % Validate required fields exist
        if ~isfield(config, 'faults')
            error('Missing required field in fault_config.yaml: faults');
        end
        
        fprintf('Fault configuration loaded from YAML: %d faults\n', length(fieldnames(config.faults)));
        
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