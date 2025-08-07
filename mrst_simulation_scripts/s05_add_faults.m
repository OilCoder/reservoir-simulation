function fault_data = s05_add_faults()
% S05_ADD_FAULTS - Add fault system to Eagle West Field
%
% SYNTAX:
%   fault_data = s05_add_faults()
%
% OUTPUT:
%   fault_data - Structure containing fault system data
%
% DESCRIPTION:
%   This script adds the fault system to Eagle West Field following
%   specifications in 01_Structural_Geology.md.
%
%   Fault System Specifications:
%   - 5 major faults (Fault A, B, C, D, E)
%   - Primary orientation: NE-SW trending normal faults
%   - Fault types: Sealing and partially-sealing barriers
%   - Transmissibility multipliers: 0.01-0.1 for fault faces
%   - Compartmentalization: Controls flow between segments
%
% Author: Claude Code AI System
% Date: January 30, 2025

    fprintf('======================================================\n');
    fprintf('Eagle West Field - Fault System Implementation (Step 5)\n');
    fprintf('======================================================\n\n');
    
    try
        % Step 1 - Load structural framework
        fprintf('Step 1: Loading structural framework...\n');
        structural_file = '../data/mrst_simulation/static/structural_framework.mat';
        if exist(structural_file, 'file')
            load(structural_file, 'G', 'layers', 'compartments');
            fprintf('   ✓ Structural framework loaded\n');
        else
            error('Structural framework not found. Run s04_structural_framework first.');
        end
        
        % Step 2 - Define fault geometries
        fprintf('Step 2: Defining fault geometries...\n');
        fault_geometries = define_fault_geometries(G);
        fprintf('   ✓ %d fault geometries defined\n', length(fault_geometries));
        
        % Step 3 - Calculate fault-cell intersections
        fprintf('Step 3: Calculating fault-cell intersections...\n');
        fault_intersections = calculate_fault_intersections(G, fault_geometries);
        fprintf('   ✓ Fault intersections calculated\n');
        
        % Step 4 - Compute transmissibility multipliers
        fprintf('Step 4: Computing transmissibility multipliers...\n');
        trans_multipliers = compute_transmissibility_multipliers(G, fault_intersections);
        fprintf('   ✓ Transmissibility multipliers computed\n');
        
        % Step 5 - Apply faults to grid
        fprintf('Step 5: Applying faults to grid structure...\n');
        G = apply_faults_to_grid(G, fault_geometries, fault_intersections, trans_multipliers);
        fprintf('   ✓ Faults applied to grid\n');
        
        % Step 6 - Validate fault system
        fprintf('Step 6: Validating fault system...\n');
        validate_fault_system(G, fault_geometries, trans_multipliers);
        fprintf('   ✓ Fault system validated\n');
        
        % Step 7 - Export fault data
        fprintf('Step 7: Exporting fault data...\n');
        export_fault_data(G, fault_geometries, fault_intersections, trans_multipliers);
        fprintf('   ✓ Fault data exported\n\n');
        
        % Assemble output structure
        fault_data = struct();
        fault_data.grid = G;
        fault_data.geometries = fault_geometries;
        fault_data.intersections = fault_intersections;
        fault_data.transmissibility_multipliers = trans_multipliers;
        fault_data.status = 'completed';
        
        % Success summary
        fprintf('======================================================\n');
        fprintf('Fault System Implementation Completed Successfully\n');
        fprintf('======================================================\n');
        fprintf('Number of faults: %d\n', length(fault_geometries));
        fprintf('Fault-affected faces: %d\n', sum(trans_multipliers < 1.0));
        fprintf('Average trans multiplier: %.3f\n', mean(trans_multipliers(trans_multipliers < 1.0)));
        fprintf('Sealing faults: %d\n', sum([fault_geometries.is_sealing]));
        fprintf('Partially sealing faults: %d\n', sum(~[fault_geometries.is_sealing]));
        fprintf('======================================================\n\n');
        
    catch ME
        fprintf('\n❌ Fault system implementation FAILED\n');
        fprintf('Error: %s\n', ME.message);
        if ~isempty(ME.stack)
            fprintf('Location: %s (line %d)\n', ME.stack(1).file, ME.stack(1).line);
        end
        error('Fault system implementation failed: %s', ME.message);
    end

end

function fault_geometries = define_fault_geometries(G)
% DEFINE_FAULT_GEOMETRIES - Define the 5 major faults

    % Get field dimensions for fault placement
    x_min = min(G.cells.centroids(:,1));
    x_max = max(G.cells.centroids(:,1));
    y_min = min(G.cells.centroids(:,2));
    y_max = max(G.cells.centroids(:,2));
    
    field_center_x = (x_min + x_max) / 2;
    field_center_y = (y_min + y_max) / 2;
    
    % Define 5 major faults based on Eagle West Field specifications
    fault_geometries = [];
    
    % Fault A - Major NE-SW trending fault (Northern boundary)
    fault_geometries(1).name = 'Fault_A';
    fault_geometries(1).type = 'sealing';
    fault_geometries(1).is_sealing = true;
    fault_geometries(1).strike = 45;  % degrees (NE-SW)
    fault_geometries(1).dip = 75;     % degrees (steep normal fault)
    fault_geometries(1).length = 2500; % ft
    fault_geometries(1).x1 = x_min + 400;
    fault_geometries(1).y1 = field_center_y + 600;
    fault_geometries(1).x2 = fault_geometries(1).x1 + fault_geometries(1).length * cosd(fault_geometries(1).strike);
    fault_geometries(1).y2 = fault_geometries(1).y1 + fault_geometries(1).length * sind(fault_geometries(1).strike);
    fault_geometries(1).trans_mult = 0.001;  % Highly sealing
    
    % Fault B - Secondary NE-SW trending fault (Central)
    fault_geometries(2).name = 'Fault_B';
    fault_geometries(2).type = 'partially_sealing';
    fault_geometries(2).is_sealing = false;
    fault_geometries(2).strike = 50;
    fault_geometries(2).dip = 70;
    fault_geometries(2).length = 2000;
    fault_geometries(2).x1 = field_center_x - 600;
    fault_geometries(2).y1 = field_center_y - 200;
    fault_geometries(2).x2 = fault_geometries(2).x1 + fault_geometries(2).length * cosd(fault_geometries(2).strike);
    fault_geometries(2).y2 = fault_geometries(2).y1 + fault_geometries(2).length * sind(fault_geometries(2).strike);
    fault_geometries(2).trans_mult = 0.05;  % Partially sealing
    
    % Fault C - NW-SE trending fault (Cross fault)
    fault_geometries(3).name = 'Fault_C';
    fault_geometries(3).type = 'sealing';
    fault_geometries(3).is_sealing = true;
    fault_geometries(3).strike = 135;  % NW-SE
    fault_geometries(3).dip = 80;
    fault_geometries(3).length = 1800;
    fault_geometries(3).x1 = field_center_x + 300;
    fault_geometries(3).y1 = y_max - 300;
    fault_geometries(3).x2 = fault_geometries(3).x1 + fault_geometries(3).length * cosd(fault_geometries(3).strike);
    fault_geometries(3).y2 = fault_geometries(3).y1 + fault_geometries(3).length * sind(fault_geometries(3).strike);
    fault_geometries(3).trans_mult = 0.002;
    
    % Fault D - Southern boundary fault
    fault_geometries(4).name = 'Fault_D';
    fault_geometries(4).type = 'partially_sealing';
    fault_geometries(4).is_sealing = false;
    fault_geometries(4).strike = 40;
    fault_geometries(4).dip = 65;
    fault_geometries(4).length = 2200;
    fault_geometries(4).x1 = x_min + 600;
    fault_geometries(4).y1 = field_center_y - 700;
    fault_geometries(4).x2 = fault_geometries(4).x1 + fault_geometries(4).length * cosd(fault_geometries(4).strike);
    fault_geometries(4).y2 = fault_geometries(4).y1 + fault_geometries(4).length * sind(fault_geometries(4).strike);
    fault_geometries(4).trans_mult = 0.1;   % More permeable
    
    % Fault E - Eastern boundary fault
    fault_geometries(5).name = 'Fault_E';
    fault_geometries(5).type = 'sealing';
    fault_geometries(5).is_sealing = true;
    fault_geometries(5).strike = 30;
    fault_geometries(5).dip = 78;
    fault_geometries(5).length = 1600;
    fault_geometries(5).x1 = x_max - 800;
    fault_geometries(5).y1 = y_min + 400;
    fault_geometries(5).x2 = fault_geometries(5).x1 + fault_geometries(5).length * cosd(fault_geometries(5).strike);
    fault_geometries(5).y2 = fault_geometries(5).y1 + fault_geometries(5).length * sind(fault_geometries(5).strike);
    fault_geometries(5).trans_mult = 0.001;
    
    % Add additional fault properties
    for i = 1:length(fault_geometries)
        fault_geometries(i).id = i;
        fault_geometries(i).displacement = 20 + 10*rand();  % ft vertical displacement
        fault_geometries(i).width = 5 + 3*rand();          % ft fault zone width
    end

end

function intersections = calculate_fault_intersections(G, fault_geometries)
% CALCULATE_FAULT_INTERSECTIONS - Find cells intersected by faults

    n_faults = length(fault_geometries);
    intersections = cell(n_faults, 1);
    
    % Get grid cell centers
    x = G.cells.centroids(:,1);
    y = G.cells.centroids(:,2);
    
    for f = 1:n_faults
        fault = fault_geometries(f);
        
        % Calculate distance from each cell to fault line
        % Fault line from (x1,y1) to (x2,y2)
        x1 = fault.x1; y1 = fault.y1;
        x2 = fault.x2; y2 = fault.y2;
        
        % Vector from point 1 to point 2
        dx = x2 - x1;
        dy = y2 - y1;
        fault_length = sqrt(dx^2 + dy^2);
        
        % Unit vector along fault
        ux = dx / fault_length;
        uy = dy / fault_length;
        
        % For each cell, find distance to fault line
        distances = zeros(G.cells.num, 1);
        
        for i = 1:G.cells.num
            % Vector from fault start to cell center
            cx = x(i) - x1;
            cy = y(i) - y1;
            
            % Project onto fault direction
            projection = cx * ux + cy * uy;
            
            % Clamp projection to fault length
            projection = max(0, min(fault_length, projection));
            
            % Find closest point on fault line
            closest_x = x1 + projection * ux;
            closest_y = y1 + projection * uy;
            
            % Distance from cell to closest point
            distances(i) = sqrt((x(i) - closest_x)^2 + (y(i) - closest_y)^2);
        end
        
        % Cells within fault zone (fault width buffer)
        fault_zone_cells = find(distances <= fault.width);
        
        % Store intersection data
        intersections{f} = struct();
        intersections{f}.fault_id = fault.id;
        intersections{f}.affected_cells = fault_zone_cells;
        intersections{f}.distances = distances(fault_zone_cells);
        intersections{f}.n_affected = length(fault_zone_cells);
    end

end

function trans_mult = compute_transmissibility_multipliers(G, intersections)
% COMPUTE_TRANSMISSIBILITY_MULTIPLIERS - Calculate transmissibility multipliers

    % Initialize all multipliers to 1.0 (no reduction)
    trans_mult = ones(G.faces.num, 1);
    
    n_faults = length(intersections);
    
    for f = 1:n_faults
        fault_data = intersections{f};
        affected_cells = fault_data.affected_cells;
        
        if isempty(affected_cells)
            continue;
        end
        
        % Find faces connected to affected cells
        for i = 1:length(affected_cells)
            cell_id = affected_cells(i);
            
            % Get faces for this cell (MRST cell-face connectivity)
            % This is a simplified approach - in full MRST implementation
            % would use G.cells.faces and proper connectivity
            
            % For now, estimate affected faces based on cell neighbors
            % In full implementation: use faceFlux and cell-face topology
            
            % Apply fault transmissibility multiplier
            % Find neighboring cells and reduce transmissibility between them
            
            % Simplified: reduce transmissibility for faces near fault zone
            x_cell = G.cells.centroids(cell_id, 1);
            y_cell = G.cells.centroids(cell_id, 2);
            
            % Find faces with centroids near this cell
            face_distances = sqrt((G.faces.centroids(:,1) - x_cell).^2 + ...
                                 (G.faces.centroids(:,2) - y_cell).^2);
            
            nearby_faces = find(face_distances <= 100); % Within 100 ft
            
            % Apply fault multiplier
            fault_mult = fault_data.fault_id;
            if fault_mult <= length(fault_geometries)
                multiplier = fault_geometries(fault_mult).trans_mult;
                trans_mult(nearby_faces) = min(trans_mult(nearby_faces), multiplier);
            end
        end
    end

end

function G = apply_faults_to_grid(G, fault_geometries, intersections, trans_mult)
% APPLY_FAULTS_TO_GRID - Apply fault properties to grid structure

    % Store fault information in grid
    G.fault_system = struct();
    G.fault_system.geometries = fault_geometries;
    G.fault_system.intersections = intersections;
    G.fault_system.transmissibility_multipliers = trans_mult;
    
    % Add fault properties to cells
    G.cells.fault_zone = zeros(G.cells.num, 1);
    G.cells.nearest_fault = zeros(G.cells.num, 1);
    
    % Mark cells in fault zones
    for f = 1:length(intersections)
        affected_cells = intersections{f}.affected_cells;
        G.cells.fault_zone(affected_cells) = f;
        G.cells.nearest_fault(affected_cells) = f;
    end
    
    % Add fault-affected flag to faces
    G.faces.fault_affected = (trans_mult < 1.0);
    G.faces.transmissibility_multiplier = trans_mult;
    
    % Calculate fault compartmentalization effects
    n_compartments_original = max(G.cells.compartment_id);
    fault_compartments = calculate_fault_compartments(G, fault_geometries);
    
    % Update compartment assignments considering faults
    if ~isempty(fault_compartments)
        G.cells.fault_compartment = fault_compartments;
    end

end

function fault_compartments = calculate_fault_compartments(G, fault_geometries)
% CALCULATE_FAULT_COMPARTMENTS - Calculate fault-based compartmentalization

    % Simplified compartmentalization based on major sealing faults
    fault_compartments = ones(G.cells.num, 1);
    
    % Find sealing faults
    sealing_faults = find([fault_geometries.is_sealing]);
    
    if isempty(sealing_faults)
        return;
    end
    
    % Use first major sealing fault to define compartments
    major_fault = fault_geometries(sealing_faults(1));
    
    % Divide field based on major fault orientation
    x = G.cells.centroids(:,1);
    y = G.cells.centroids(:,2);
    
    % Line equation for fault
    x1 = major_fault.x1; y1 = major_fault.y1;
    x2 = major_fault.x2; y2 = major_fault.y2;
    
    % Determine which side of fault line each cell is on
    for i = 1:G.cells.num
        % Cross product to determine side
        cross_prod = (x2 - x1) * (y(i) - y1) - (y2 - y1) * (x(i) - x1);
        
        if cross_prod > 0
            fault_compartments(i) = 1;  % One side of fault
        else
            fault_compartments(i) = 2;  % Other side of fault
        end
    end

end

function validate_fault_system(G, fault_geometries, trans_mult)
% VALIDATE_FAULT_SYSTEM - Validate fault system implementation

    n_faults = length(fault_geometries);
    
    % Check fault geometry validity
    for f = 1:n_faults
        fault = fault_geometries(f);
        
        if fault.length <= 0
            error('Fault %s has invalid length: %.1f', fault.name, fault.length);
        end
        
        if fault.trans_mult <= 0 || fault.trans_mult > 1
            error('Fault %s has invalid transmissibility multiplier: %.3f', ...
                  fault.name, fault.trans_mult);
        end
        
        if fault.dip < 0 || fault.dip > 90
            error('Fault %s has invalid dip angle: %.1f degrees', fault.name, fault.dip);
        end
    end
    
    % Check transmissibility multipliers
    if any(trans_mult < 0) || any(trans_mult > 1)
        error('Invalid transmissibility multipliers detected');
    end
    
    % Check fault coverage
    fault_affected_faces = sum(trans_mult < 1.0);
    total_faces = length(trans_mult);
    fault_coverage = fault_affected_faces / total_faces * 100;
    
    if fault_coverage < 1 || fault_coverage > 50
        warning('Fault coverage %.1f%% may be unrealistic', fault_coverage);
    end
    
    % Statistics
    sealing_faults = sum([fault_geometries.is_sealing]);
    partially_sealing = n_faults - sealing_faults;
    
    fprintf('     Fault validation successful\n');
    fprintf('     Total faults: %d (%d sealing, %d partially sealing)\n', ...
            n_faults, sealing_faults, partially_sealing);
    fprintf('     Fault-affected faces: %d (%.1f%%)\n', fault_affected_faces, fault_coverage);
    fprintf('     Average fault length: %.0f ft\n', mean([fault_geometries.length]));

end

function export_fault_data(G, fault_geometries, intersections, trans_mult)
% EXPORT_FAULT_DATA - Export fault system data

    % Create output directory
    script_path = fileparts(mfilename('fullpath'));
    data_dir = fullfile(fileparts(script_path), 'data', 'mrst_simulation', 'static');
    
    if ~exist(data_dir, 'dir')
        mkdir(data_dir);
    end
    
    % Save fault data
    fault_file = fullfile(data_dir, 'fault_system.mat');
    save(fault_file, 'G', 'fault_geometries', 'intersections', 'trans_mult', '');
    
    % Create fault summary report
    summary_file = fullfile(data_dir, 'fault_summary.txt');
    fid = fopen(summary_file, 'w');
    
    fprintf(fid, 'Eagle West Field - Fault System Summary\n');
    fprintf(fid, '======================================\n\n');
    
    fprintf(fid, 'Fault System Configuration:\n');
    fprintf(fid, '  Total Faults: %d\n', length(fault_geometries));
    fprintf(fid, '  Sealing Faults: %d\n', sum([fault_geometries.is_sealing]));
    fprintf(fid, '  Partially Sealing Faults: %d\n', sum(~[fault_geometries.is_sealing]));
    
    fprintf(fid, '\nFault Details:\n');
    for f = 1:length(fault_geometries)
        fault = fault_geometries(f);
        fprintf(fid, '  %s:\n', fault.name);
        fprintf(fid, '    Type: %s\n', fault.type);
        fprintf(fid, '    Strike: %.0f° (NE-SW)\n', fault.strike);
        fprintf(fid, '    Dip: %.0f°\n', fault.dip);
        fprintf(fid, '    Length: %.0f ft\n', fault.length);
        fprintf(fid, '    Transmissibility Multiplier: %.3f\n', fault.trans_mult);
        fprintf(fid, '    Displacement: %.1f ft\n', fault.displacement);
        fprintf(fid, '    Affected Cells: %d\n', intersections{f}.n_affected);
        fprintf(fid, '\n');
    end
    
    fprintf(fid, 'Grid Impact:\n');
    fprintf(fid, '  Fault-affected faces: %d (%.1f%%)\n', sum(trans_mult < 1.0), ...
            sum(trans_mult < 1.0)/length(trans_mult)*100);
    fprintf(fid, '  Average trans multiplier: %.3f\n', mean(trans_mult(trans_mult < 1.0)));
    fprintf(fid, '  Minimum trans multiplier: %.3f\n', min(trans_mult));
    
    fprintf(fid, '\nCreation Date: %s\n', datestr(now));
    
    fclose(fid);
    
    fprintf('     Fault data saved to: %s\n', fault_file);
    fprintf('     Summary saved to: %s\n', summary_file);

end

% Main execution when called as script
if ~nargout
    % If called as script (not function), add fault system
    fault_data = s05_add_faults();
    
    fprintf('Fault system implemented!\n');
    fprintf('Grid updated with %d major faults.\n', length(fault_data.geometries));
    fprintf('Use plotGrid(G) to visualize fault-affected grid.\n\n');
end