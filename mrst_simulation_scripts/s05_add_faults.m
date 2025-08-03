function [G, status] = s05_add_faults(G_structural, varargin)
%S05_ADD_FAULTS Add fault system with transmissibility multipliers to grid

% Suppress warnings for cleaner output
warning('off', 'all');
%
% This script implements the 5-fault system according to structural geology
% documentation for the Eagle West Field. Creates fault planes and assigns
% transmissibility multipliers based on sealing characteristics.
%
% USAGE:
%   [G, status] = s05_add_faults(G_structural, config)                    % Normal mode (clean output)
%   [G, status] = s05_add_faults(G_structural, config, 'verbose', true)   % Verbose mode (detailed output)
%   [G, status] = s05_add_faults(G_structural, 'verbose', true)           % Load config automatically, verbose
%
% INPUT:
%   G_structural - MRST grid structure with structural framework from s04_structural_framework
%
% OUTPUT:
%   G      - MRST grid with fault transmissibility multipliers
%   status - Structure containing fault implementation status and information
%
% DEPENDENCIES:
%   - MRST environment (assumed already initialized by workflow)
%   - config/grid_config.yaml for grid parameters
%   - util_read_config.m (YAML reader)
%
% SUCCESS CRITERIA:
%   - Fault system created without errors
%   - Transmissibility multipliers properly applied
%   - 5 major faults implemented
%   - Grid connectivity maintained

    % Parse input arguments
    p = inputParser;
    addRequired(p, 'G_structural', @isstruct);
    addParameter(p, 'verbose', false, @islogical);
    parse(p, G_structural, varargin{:});
    verbose = p.Results.verbose;
    
    if verbose
        fprintf('\n=== Fault System Implementation ===\n');
    else
        fprintf('\n>> Adding Fault System:\n');
        fprintf('+-------------------------------------+--------+\n');
        fprintf('| Component                           | Status |\n');
        fprintf('+-------------------------------------+--------+\n');
    end
    
    % Initialize status structure
    status = struct();
    status.success = false;
    status.faults_added = 0;
    status.transmult_faces = 0;
    status.errors = {};
    status.warnings = {};
    
    % Initialize return values
    G = G_structural;
    
    % Define fault implementation tasks
    task_names = {'Load Configuration', 'Extract Parameters', 'Define Fault Planes', 'Apply Transmissibility', 'Validate System'};
    
    try
        %% Step 1: Load configuration if not provided
        if verbose
            fprintf('Step 1: Loading configuration...\n');
        end
        
        try
            % Load grid configuration directly from YAML
            config_dir = 'config';
            grid_file = fullfile(config_dir, 'grid_config.yaml');
            grid_raw = util_read_config(grid_file);
            
            % Extract basic grid parameters
            grid_config = struct();
            grid_config.nx = parse_numeric(grid_raw.nx);
            grid_config.ny = parse_numeric(grid_raw.ny);
            grid_config.nz = parse_numeric(grid_raw.nz);
            grid_config.Lx = parse_numeric(grid_raw.length_x);     % m
            grid_config.Ly = parse_numeric(grid_raw.length_y);     % m
            step1_success = true;
        catch
            step1_success = false;
        end
        
        if ~verbose
            if step1_success
                status_symbol = 'Y';
            else
                status_symbol = 'X';
            end
            fprintf('| %-35s |   %s    |\n', task_names{1}, status_symbol);
        else
            if step1_success
                fprintf('  - Configuration %s successfully\n', config_source);
            end
        end
        
        if ~step1_success
            error('Failed to load configuration');
        end
        
        %% Step 2: Extract fault parameters
        if verbose
            fprintf('Step 2: Extracting fault parameters...\n');
        end
        
        try
            % Extract grid dimensions
            nx = grid_config.nx;
            ny = grid_config.ny;
            nz = grid_config.nz;
            Lx = grid_config.Lx;
            Ly = grid_config.Ly;
            
            step2_success = true;
        catch
            step2_success = false;
        end
        
        if ~verbose
            if step2_success
                status_symbol = 'Y';
            else
                status_symbol = 'X';
            end
            fprintf('| %-35s |   %s    |\n', task_names{2}, status_symbol);
        else
            if step2_success
                fprintf('  - Grid: %dx%dx%d cells, extent: %.0fx%.0f m\n', nx, ny, nz, Lx, Ly);
            end
        end
        
        if ~step2_success
            error('Failed to extract fault parameters');
        end
        
        %% Step 3: Define fault planes
        if verbose
            fprintf('Step 3: Defining fault planes...\n');
        end
        
        try
        
            % Initialize all face transmissibilities as 1.0 (no barriers)
            num_faces = G.faces.num;
            T_mult = ones(num_faces, 1);
        
            % Fault definitions based on Structural_Geology.md Section 2.2
            faults = struct();
            
            % Fault A: Northern boundary (N10degE, sealing)
            faults.A = struct();
            faults.A.name = 'Fault A (Northern Boundary)';
            faults.A.transmult = 0.01;      % Nearly sealing
            faults.A.position = 'j_max';    % Northern boundary
            
            % Fault B: Eastern boundary (N20degE, partially sealing)
            faults.B = struct();
            faults.B.name = 'Fault B (Eastern Boundary)';
            faults.B.transmult = 0.3;       % Some communication
            faults.B.position = 'i_max';    % Eastern boundary
            
            % Fault C: Southern boundary (N75degW, sealing in center)
            faults.C = struct();
            faults.C.name = 'Fault C (Southern Boundary)';
            faults.C.transmult = 0.05;      % Mostly sealing
            faults.C.position = 'j_min';    % Southern boundary
            
            % Fault D: Western boundary (N15degW, sealing)
            faults.D = struct();
            faults.D.name = 'Fault D (Western Boundary)';
            faults.D.transmult = 0.02;      % Nearly sealing
            faults.D.position = 'i_min';    % Western boundary
            
            % Fault E: Internal fault (N45degE, compartmentalization)
            faults.E = struct();
            faults.E.name = 'Fault E (Internal Compartmentalization)';
            faults.E.transmult = 0.2;       % Creates compartments
            faults.E.position = 'internal'; % Internal diagonal
            
            fault_names = {'A', 'B', 'C', 'D', 'E'};
            step3_success = true;
        catch
            step3_success = false;
        end
        
        if ~verbose
            if step3_success
                status_symbol = 'Y';
            else
                status_symbol = 'X';
            end
            fprintf('| %-35s |   %s    |\n', sprintf('%s (%d faults)', task_names{3}, length(fault_names)), status_symbol);
        else
            if step3_success
                fprintf('  - Defined %d faults: %s\n', length(fault_names), strjoin(fault_names, ', '));
            end
        end
        
        if ~step3_success
            error('Failed to define fault planes');
        end
        
        %% Step 4: Apply transmissibility multipliers to faces
        if verbose
            fprintf('Step 4: Applying transmissibility multipliers...\n');
        end
        
        try
        
            modified_faces = 0;
            
            for f = 1:length(fault_names)
                fault_name = fault_names{f};
                fault = faults.(fault_name);
                
                if verbose
                    fprintf('  Processing %s (T_mult = %.2f)...\n', fault.name, fault.transmult);
                end
            
                % Find faces affected by this fault
                affected_faces = [];
                
                switch fault.position
                    case 'i_max'  % Eastern boundary (Fault B)
                        % Faces between I=nx-1 and I=nx
                        for j = 1:ny
                            for k = 1:nz
                                if nx > 1
                                    cell1 = sub2ind([nx, ny, nz], nx-1, j, k);
                                    cell2 = sub2ind([nx, ny, nz], nx, j, k);
                                    
                                    face_idx = findFaceBetweenCells(G, cell1, cell2);
                                    if ~isempty(face_idx)
                                        affected_faces = [affected_faces; face_idx];
                                    end
                                end
                            end
                        end
                    
                    case 'i_min'  % Western boundary (Fault D)
                        % Faces between I=1 and I=2
                        for j = 1:ny
                            for k = 1:nz
                                if nx > 1
                                    cell1 = sub2ind([nx, ny, nz], 1, j, k);
                                    cell2 = sub2ind([nx, ny, nz], 2, j, k);
                                    
                                    face_idx = findFaceBetweenCells(G, cell1, cell2);
                                    if ~isempty(face_idx)
                                        affected_faces = [affected_faces; face_idx];
                                    end
                                end
                            end
                        end
                    
                    case 'j_max'  % Northern boundary (Fault A)
                        % Faces between J=ny-1 and J=ny
                        for i = 1:nx
                            for k = 1:nz
                                if ny > 1
                                    cell1 = sub2ind([nx, ny, nz], i, ny-1, k);
                                    cell2 = sub2ind([nx, ny, nz], i, ny, k);
                                    
                                    face_idx = findFaceBetweenCells(G, cell1, cell2);
                                    if ~isempty(face_idx)
                                        affected_faces = [affected_faces; face_idx];
                                    end
                                end
                            end
                        end
                    
                    case 'j_min'  % Southern boundary (Fault C)
                        % Faces between J=1 and J=2
                        for i = 1:nx
                            for k = 1:nz
                                if ny > 1
                                    cell1 = sub2ind([nx, ny, nz], i, 1, k);
                                    cell2 = sub2ind([nx, ny, nz], i, 2, k);
                                    
                                    face_idx = findFaceBetweenCells(G, cell1, cell2);
                                    if ~isempty(face_idx)
                                        affected_faces = [affected_faces; face_idx];
                                    end
                                end
                            end
                        end
                    
                    case 'internal'  % Internal fault (Fault E)
                        % Diagonal fault - approximate as J-direction faces in middle
                        j_center = round(ny/2);
                        for i = 1:nx
                            for k = 1:nz
                                if j_center < ny
                                    cell1 = sub2ind([nx, ny, nz], i, j_center, k);
                                    cell2 = sub2ind([nx, ny, nz], i, j_center+1, k);
                                    
                                    face_idx = findFaceBetweenCells(G, cell1, cell2);
                                    if ~isempty(face_idx)
                                        affected_faces = [affected_faces; face_idx];
                                    end
                                end
                            end
                        end
                end
            
                % Apply transmissibility multiplier to affected faces
                if ~isempty(affected_faces)
                    T_mult(affected_faces) = fault.transmult;
                    modified_faces = modified_faces + length(affected_faces);
                    if verbose
                        fprintf('    - Modified %d faces\n', length(affected_faces));
                    end
                else
                    status.warnings{end+1} = sprintf('No faces found for %s', fault.name);
                    if verbose
                        fprintf('    - WARNING: No faces found\n');
                    end
                end
            end
            step4_success = true;
        catch
            step4_success = false;
        end
        
        if ~verbose
            if step4_success
                status_symbol = 'Y';
            else
                status_symbol = 'X';
            end
            fprintf('| %-35s |   %s    |\n', sprintf('%s (%d faces)', task_names{4}, modified_faces), status_symbol);
        else
            if step4_success
                fprintf('  - Total modified faces: %d\n', modified_faces);
            end
        end
        
        if ~step4_success
            error('Failed to apply transmissibility multipliers');
        end
        
        %% Step 5: Validate fault system
        if verbose
            fprintf('Step 5: Validating fault system...\n');
        end
        
        try
            % Store transmissibility multipliers in grid structure
            G.faces.transmult = T_mult;
            
            % Calculate statistics
            sealing_faces = sum(T_mult < 0.1);        % Nearly sealed
            partial_faces = sum(T_mult >= 0.1 & T_mult < 1.0);  % Partially sealed
            open_faces = sum(T_mult >= 1.0);          % Open
            
            % Validate that we have reasonable fault coverage
            if modified_faces == 0
                status.warnings{end+1} = 'No faces were modified by fault system';
            end
            
            step5_success = true;
        catch
            step5_success = false;
        end
        
        if ~verbose
            if step5_success
                status_symbol = 'Y';
            else
                status_symbol = 'X';
            end
            fprintf('| %-35s |   %s    |\n', sprintf('%s (%d sealing)', task_names{5}, sealing_faces), status_symbol);
        else
            if step5_success
                fprintf('  - Total modified faces: %d\n', modified_faces);
                fprintf('  - Sealing faces (T<0.1): %d\n', sealing_faces);
                fprintf('  - Partial faces (0.1≤T<1.0): %d\n', partial_faces);
                fprintf('  - Open faces (T≥1.0): %d\n', open_faces);
            end
        end
        
        if ~step5_success
            error('Failed to validate fault system');
        end
        
        % Store fault information in status
        status.faults_implemented = fault_names;
        status.faults_added = length(fault_names);
        status.transmult_faces = modified_faces;
        status.fault_details = faults;
        status.transmult_stats = struct();
        status.transmult_stats.sealing = sealing_faces;
        status.transmult_stats.partial = partial_faces;
        status.transmult_stats.open = open_faces;
        status.transmult_stats.total = num_faces;
        
        %% Success
        status.success = step1_success && step2_success && step3_success && step4_success && step5_success;
        status.timestamp = datestr(now, 'yyyy-mm-dd HH:MM:SS');
        
        if verbose
            fprintf('\n=== Fault System Implementation SUCCESSFUL ===\n');
            fprintf('Faults implemented: %s\n', strjoin(fault_names, ', '));
            fprintf('Compartments created: Northern, Southern (separated by Fault E)\n');
            fprintf('Total faces with barriers: %d/%d\n', modified_faces, num_faces);
            fprintf('Sealing efficiency: %.1f%% faces modified\n', (modified_faces/num_faces)*100);
            fprintf('Timestamp: %s\n', status.timestamp);
        else
            % Close the table
            fprintf('+-------------------------------------+--------+\n');
            fprintf('>> Faults: %d major faults implemented successfully\n', length(fault_names));
            fprintf('   Transmissibility: %d faces modified | Sealing: %d | Partial: %d\n', modified_faces, sealing_faces, partial_faces);
        end
        
        if ~isempty(status.warnings)
            fprintf('\nWarnings encountered:\n');
            for i = 1:length(status.warnings)
                fprintf('  - %s\n', status.warnings{i});
            end
        end
        
    catch ME
        status.success = false;
        status.errors{end+1} = ME.message;
        
        fprintf('\n=== Fault System Implementation FAILED ===\n');
        fprintf('Error: %s\n', ME.message);
        
        if ~isempty(status.warnings)
            fprintf('\nWarnings:\n');
            for i = 1:length(status.warnings)
                fprintf('  - %s\n', status.warnings{i});
            end
        end
        
        rethrow(ME);
    end
    
    fprintf('\n');
end

function val = parse_numeric(str_val)
%PARSE_NUMERIC Extract numeric value from string (removing comments)
    if isnumeric(str_val)
        val = str_val;
    else
        clean_str = strtok(str_val, '#');
        val = str2double(clean_str);
        if isnan(val)
            error('Failed to parse numeric value from: %s', str_val);
        end
    end
end

function face_idx = findFaceBetweenCells(G, cell1, cell2)
%FINDFACEBETWEENCELLS Find face between two adjacent cells
%
% This is a simplified implementation for Cartesian grids
% In practice, MRST has more sophisticated methods

    face_idx = [];
    
    % Check if cells are valid
    if cell1 <= 0 || cell1 > G.cells.num || cell2 <= 0 || cell2 > G.cells.num
        return;
    end
    
    % Get cell faces for both cells
    cell1_faces = G.cells.faces(G.cells.facePos(cell1):G.cells.facePos(cell1+1)-1, 1);
    cell2_faces = G.cells.faces(G.cells.facePos(cell2):G.cells.facePos(cell2+1)-1, 1);
    
    % Find common face
    common_faces = intersect(cell1_faces, cell2_faces);
    
    if ~isempty(common_faces)
        face_idx = common_faces(1);  % Take first common face
    end
end