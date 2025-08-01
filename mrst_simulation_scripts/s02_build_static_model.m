function [G, rock] = s02_build_static_model(simulation_data)
% S02_BUILD_STATIC_MODEL - Create grid and assign rock properties

%
% DESCRIPTION:
%   Creates 20×20×10 Cartesian tensor grid for Eagle West Field and assigns
%   rock properties including porosity, permeability, and fault transmissibility
%   multipliers. Implements 3-zone geological model with 5 major fault systems.
%
% INPUT:
%   simulation_data - Structure from s01_initialize_simulation (optional)
%
% OUTPUT:
%   G - MRST grid structure with geometry and connectivity
%   rock - Rock properties structure with porosity, permeability, and faults
%
% GRID SPECIFICATIONS:
%   - Dimensions: 20×20×10 cells (4,000 total)
%   - Cell size: 164×148×7.25 ft (50×45×2.21 m)  
%   - Top depth: 7,881 ft (2,403.5 m)
%   - Field extent: 3,280×2,960×72.5 ft
%
% GEOLOGICAL MODEL:
%   - Upper Zone: Layers 1-3 (high porosity/permeability)
%   - Middle Zone: Layers 4-7 (best reservoir quality)
%   - Lower Zone: Layers 8-10 (moderate quality)
%   - 5 Major faults with transmissibility multipliers
%
% REFERENCE:
%   Based on rock_properties_config.yaml and 01_Structural_Geology.md

    fprintf('\n');
    fprintf('=================================================================\n');
    fprintf('  EAGLE WEST FIELD - STATIC MODEL CONSTRUCTION                   \n');
    fprintf('=================================================================\n');
    fprintf('Script: s02_build_static_model.m\n');
    fprintf('Purpose: Create grid and assign rock properties\n');
    fprintf('=================================================================\n\n');

    % Record start time
    static_start_time = tic;
    
    % Handle optional input
    if nargin < 1
        simulation_data = struct();
        fprintf('[INFO] No simulation_data provided, using default parameters\n');
    end
    
    % Check if MRST is available
    if ~exist('cartGrid', 'file')
        fprintf('[WARN] MRST not available - returning minimal structures\n');
        
        % Load grid configuration
        grid_config_file = fullfile(pwd, 'config', 'grid_config.yaml');
        if exist(grid_config_file, 'file')
            grid_config = util_read_config(grid_config_file);
            % Convert string values to numbers (parser includes comments)
            nx = str2double(strtok(grid_config.nx));
            ny = str2double(strtok(grid_config.ny));
            nz = str2double(strtok(grid_config.nz));
            total_cells = str2double(strtok(grid_config.total_active_cells));
            grid_dims = [nx, ny, nz];
        else
            error('s02_build_static_model:GridConfigNotFound', ...
                  'Grid configuration not found: %s', grid_config_file);
        end
        
        % Create minimal valid structures for testing
        G = struct();
        G.type = 'cartGrid';
        G.cartDims = grid_dims;
        G.cells = struct();
        G.cells.num = total_cells;
        G.faces = struct();
        G.faces.num = 0;
        
        rock = struct();
        rock.poro = zeros(G.cells.num, 1);
        rock.perm = zeros(G.cells.num, 1);
        
        fprintf('[INFO] Grid dimensions from config: %dx%dx%d\n', grid_dims(1), grid_dims(2), grid_dims(3));
        fprintf('[INFO] Returned empty but valid G and rock structures\n');
        fprintf('=================================================================\n\n');
        return;
    end
    
    try
        %% STEP 1: LOAD ROCK PROPERTIES CONFIGURATION
        fprintf('[STEP 1] Loading rock properties configuration...\n');
        
        % Load rock properties from YAML configuration
        config_file = fullfile(pwd, 'config', 'rock_properties_config.yaml');
        
        if exist(config_file, 'file')
            rock_config = util_read_config(config_file);
            fprintf('  [OK] Rock properties loaded from: %s\n', config_file);
        else
            error('s02_build_static_model:ConfigNotFound', 'Rock properties configuration not found: %s', config_file);
        end
        
        %% STEP 2: GRID CONSTRUCTION
        fprintf('\n[STEP 2] Constructing Cartesian tensor grid...\n');
        
        % Grid dimensions per 08_MRST_Implementation.md
        nx = 20; % I-direction cells
        ny = 20; % J-direction cells  
        nz = 10; % K-direction cells (layers)
        
        fprintf('  --> Grid dimensions: %d × %d × %d = %d cells\n', nx, ny, nz, nx*ny*nz);
        
        % Physical dimensions (convert ft to meters for MRST)
        ft_to_m = 0.3048;
        
        % Cell dimensions in feet (per documentation)
        dx_ft = 164; % ft - I-direction cell size
        dy_ft = 148; % ft - J-direction cell size
        dz_ft = 7.25; % ft - K-direction cell size (average)
        
        % Convert to meters
        dx_m = dx_ft * ft_to_m; % ~50 m
        dy_m = dy_ft * ft_to_m; % ~45 m
        dz_m = dz_ft * ft_to_m; % ~2.21 m
        
        fprintf('  --> Cell dimensions: %.1f × %.1f × %.2f m (%.0f × %.0f × %.1f ft)\n', ...
                dx_m, dy_m, dz_m, dx_ft, dy_ft, dz_ft);
        
        % Field extent
        Lx = nx * dx_m; % Total X extent: ~1000 m
        Ly = ny * dy_m; % Total Y extent: ~900 m  
        Lz = nz * dz_m; % Total Z extent: ~22 m
        
        fprintf('  --> Field extent: %.0f × %.0f × %.1f m (%.0f × %.0f × %.0f ft)\n', ...
                Lx, Ly, Lz, Lx/ft_to_m, Ly/ft_to_m, Lz/ft_to_m);
        
        % Create uniform Cartesian grid
        G = cartGrid([nx, ny, nz], [Lx, Ly, Lz]);
        
        fprintf('  [OK] Cartesian grid created: %d cells\n', G.cells.num);
        
        %% STEP 3: GRID GEOMETRY AND DEPTH
        fprintf('\n[STEP 3] Setting up grid geometry and depth structure...\n');
        
        % Compute grid geometry
        G = computeGeometry(G);
        fprintf('  [OK] Grid geometry computed\n');
        
        % Set top depth (7,881 ft = 2,403.5 m per documentation)
        top_depth_ft = 7881; % ft TVDSS
        top_depth_m = top_depth_ft * ft_to_m; % Convert to meters
        
        fprintf('  --> Top reservoir depth: %.1f m (%.0f ft TVDSS)\n', top_depth_m, top_depth_ft);
        
        % Adjust Z-coordinates to start at top depth
        G.nodes.coords(:,3) = G.nodes.coords(:,3) + top_depth_m;
        G = computeGeometry(G);
        
        % Compute cell center depths for property assignment
        cell_depths_m = G.cells.centroids(:,3);
        cell_depths_ft = cell_depths_m / ft_to_m;
        
        fprintf('  --> Depth range: %.1f - %.1f m (%.0f - %.0f ft)\n', ...
                min(cell_depths_m), max(cell_depths_m), min(cell_depths_ft), max(cell_depths_ft));
        
        %% STEP 4: GEOLOGICAL ZONE ASSIGNMENT
        fprintf('\n[STEP 4] Assigning geological zones...\n');
        
        % Define zones based on K-layers (per rock_properties_config.yaml)
        zone_assignment = zeros(G.cells.num, 1);
        
        % Get K-indices for each cell
        [I, J, K] = gridLogicalIndices(G);
        
        % Zone 1: Upper Zone (Layers 1-3) - High porosity
        upper_layers = ismember(K, 1:3);
        zone_assignment(upper_layers) = 1;
        
        % Zone 2: Middle Zone (Layers 4-7) - Best reservoir quality
        middle_layers = ismember(K, 4:7);
        zone_assignment(middle_layers) = 2;
        
        % Zone 3: Lower Zone (Layers 8-10) - Moderate quality
        lower_layers = ismember(K, 8:10);
        zone_assignment(lower_layers) = 3;
        
        fprintf('  [OK] Zone 1 (Upper): %d cells (layers 1-3)\n', sum(zone_assignment == 1));
        fprintf('  [OK] Zone 2 (Middle): %d cells (layers 4-7)\n', sum(zone_assignment == 2));
        fprintf('  [OK] Zone 3 (Lower): %d cells (layers 8-10)\n', sum(zone_assignment == 3));
        
        %% STEP 5: ROCK PROPERTIES ASSIGNMENT
        fprintf('\n[STEP 5] Assigning rock properties by zone...\n');
        
        % Initialize rock properties structure
        rock = makeRock(G, 1, 1); % Initialize with unit values
        
        % Extract properties from configuration
        try
            % Zone properties from rock_properties_config.yaml
            if isfield(rock_config, 'geological_zones')
                zones = rock_config.geological_zones;
                
                % Upper Zone properties
                if isfield(zones, 'upper_zone')
                    upper_poro = zones.upper_zone.porosity_avg / 100; % Convert % to fraction
                    upper_perm = zones.upper_zone.permeability_avg; % mD
                    fprintf('  --> Upper Zone: φ = %.1f%%, k = %.0f mD\n', upper_poro*100, upper_perm);
                else
                    upper_poro = 0.195; upper_perm = 85; % Default values
                    fprintf('  [WARN] Using default Upper Zone properties\n');
                end
                
                % Middle Zone properties  
                if isfield(zones, 'middle_zone')
                    middle_poro = zones.middle_zone.porosity_avg / 100;
                    middle_perm = zones.middle_zone.permeability_avg;
                    fprintf('  --> Middle Zone: φ = %.1f%%, k = %.0f mD\n', middle_poro*100, middle_perm);
                else
                    middle_poro = 0.228; middle_perm = 165; % Default values
                    fprintf('  [WARN] Using default Middle Zone properties\n');
                end
                
                % Lower Zone properties
                if isfield(zones, 'lower_zone')
                    lower_poro = zones.lower_zone.porosity_avg / 100;
                    lower_perm = zones.lower_zone.permeability_avg;
                    fprintf('  --> Lower Zone: φ = %.1f%%, k = %.0f mD\n', lower_poro*100, lower_perm);
                else
                    lower_poro = 0.145; lower_perm = 25; % Default values
                    fprintf('  [WARN] Using default Lower Zone properties\n');
                end
            else
                % Use default properties if config not found
                upper_poro = 0.195; upper_perm = 85;
                middle_poro = 0.228; middle_perm = 165;
                lower_poro = 0.145; lower_perm = 25;
                fprintf('  [WARN] Using default zone properties (config not found)\n');
            end
        catch
            % Fallback to default properties
            upper_poro = 0.195; upper_perm = 85;
            middle_poro = 0.228; middle_perm = 165;
            lower_poro = 0.145; lower_perm = 25;
            fprintf('  [WARN] Using default zone properties (config error)\n');
        end
        
        % Assign porosity by zone
        rock.poro = zeros(G.cells.num, 1);
        rock.poro(zone_assignment == 1) = upper_poro;   % Upper zone
        rock.poro(zone_assignment == 2) = middle_poro;  % Middle zone  
        rock.poro(zone_assignment == 3) = lower_poro;   % Lower zone
        
        % Convert permeability mD to m² (1 mD = 9.869e-16 m²)
        mD_to_m2 = 9.869e-16;
        
        % Assign permeability by zone
        rock.perm = zeros(G.cells.num, 1);
        rock.perm(zone_assignment == 1) = upper_perm * mD_to_m2;   % Upper zone
        rock.perm(zone_assignment == 2) = middle_perm * mD_to_m2;  % Middle zone
        rock.perm(zone_assignment == 3) = lower_perm * mD_to_m2;   % Lower zone
        
        fprintf('  [OK] Porosity assigned: range %.1f%% - %.1f%%\n', ...
                min(rock.poro)*100, max(rock.poro)*100);
        fprintf('  [OK] Permeability assigned: range %.0f - %.0f mD\n', ...
                min(rock.perm)/mD_to_m2, max(rock.perm)/mD_to_m2);
        
        %% STEP 6: FAULT SYSTEM IMPLEMENTATION
        fprintf('\n[STEP 6] Implementing fault system...\n');
        
        % Initialize transmissibility multipliers (default = 1.0, no reduction)
        T_mult = ones(G.faces.num, 1);
        
        % Define 5 major fault planes per 01_Structural_Geology.md
        % Faults are implemented as reduced transmissibility zones
        
        % Fault A (North boundary): I-direction faces at J=18-20
        fault_A_faces = find(G.faces.centroids(:,2) > 0.9*Ly); % Upper 10% of Y
        T_mult(fault_A_faces) = T_mult(fault_A_faces) * 0.01; % 99% reduction (highly sealing)
        fprintf('  --> Fault A (North): %d faces, T_mult = 0.01\n', length(fault_A_faces));
        
        % Fault B (East boundary): J-direction faces at I=18-20  
        fault_B_faces = find(G.faces.centroids(:,1) > 0.9*Lx); % Right 10% of X
        T_mult(fault_B_faces) = T_mult(fault_B_faces) * 0.05; % 95% reduction (moderately sealing)
        fprintf('  --> Fault B (East): %d faces, T_mult = 0.05\n', length(fault_B_faces));
        
        % Fault C (South boundary): I-direction faces at J=1-3
        fault_C_faces = find(G.faces.centroids(:,2) < 0.1*Ly); % Lower 10% of Y
        T_mult(fault_C_faces) = T_mult(fault_C_faces) * 0.02; % 98% reduction (highly sealing)
        fprintf('  --> Fault C (South): %d faces, T_mult = 0.02\n', length(fault_C_faces));
        
        % Fault D (West boundary): J-direction faces at I=1-3
        fault_D_faces = find(G.faces.centroids(:,1) < 0.1*Lx); % Left 10% of X
        T_mult(fault_D_faces) = T_mult(fault_D_faces) * 0.01; % 99% reduction (highly sealing)
        fprintf('  --> Fault D (West): %d faces, T_mult = 0.01\n', length(fault_D_faces));
        
        % Fault E (Internal): Diagonal fault through center
        internal_fault_faces = find(abs(G.faces.centroids(:,1)/Lx - G.faces.centroids(:,2)/Ly) < 0.05);
        T_mult(internal_fault_faces) = T_mult(internal_fault_faces) * 0.3; % 70% reduction (partially sealing)
        fprintf('  --> Fault E (Internal): %d faces, T_mult = 0.3\n', length(internal_fault_faces));
        
        % Store transmissibility multipliers in rock structure
        rock.perm_mult = T_mult;
        
        total_affected_faces = length(fault_A_faces) + length(fault_B_faces) + ...
                              length(fault_C_faces) + length(fault_D_faces) + ...
                              length(internal_fault_faces);
        fprintf('  [OK] Fault system implemented: %d faces affected\n', total_affected_faces);
        
        %% STEP 7: ADDITIONAL ROCK PROPERTIES
        fprintf('\n[STEP 7] Setting additional rock properties...\n');
        
        % Rock compressibility (from 02_Rock_Properties.md)
        rock.cr = 4.5e-10; % 1/Pa (average rock compressibility)
        
        % Net-to-gross ratio (assume good quality reservoir)
        rock.ntg = ones(G.cells.num, 1); % 100% net pay
        
        % Saturation function regions (all cells use same rel-perm curves)
        rock.satnum = ones(G.cells.num, 1);
        
        % PVT regions (single PVT table for entire field)
        rock.pvtnum = ones(G.cells.num, 1);
        
        % Store zone assignment for future reference
        rock.zones = zone_assignment;
        
        fprintf('  [OK] Rock compressibility: %.2e 1/Pa\n', rock.cr);
        fprintf('  [OK] Net-to-gross: %.1f (uniform)\n', mean(rock.ntg));
        fprintf('  [OK] Saturation regions: %d\n', max(rock.satnum));
        fprintf('  [OK] PVT regions: %d\n', max(rock.pvtnum));
        
        %% STEP 8: GRID AND ROCK VALIDATION
        fprintf('\n[STEP 8] Validating grid and rock properties...\n');
        
        validation_passed = true;
        validation_errors = {};
        
        % Grid validation
        if G.cells.num ~= 4000
            validation_errors{end+1} = sprintf('Grid cell count mismatch: %d (expected 4000)', G.cells.num);
            validation_passed = false;
        end
        
        if abs(G.cartDims(1) - 20) > 0 || abs(G.cartDims(2) - 20) > 0 || abs(G.cartDims(3) - 10) > 0
            validation_errors{end+1} = sprintf('Grid dimensions mismatch: %dx%dx%d (expected 20x20x10)', G.cartDims);
            validation_passed = false;
        end
        
        % Rock properties validation
        if any(rock.poro <= 0) || any(rock.poro >= 1)
            validation_errors{end+1} = 'Invalid porosity values detected';
            validation_passed = false;
        end
        
        if any(rock.perm <= 0)
            validation_errors{end+1} = 'Invalid permeability values detected';
            validation_passed = false;
        end
        
        % Zone assignment validation
        if length(unique(rock.zones)) ~= 3
            validation_errors{end+1} = sprintf('Zone count mismatch: %d (expected 3)', length(unique(rock.zones)));
            validation_passed = false;
        end
        
        if validation_passed
            fprintf('  [OK] All validations passed\n');
        else
            fprintf('  [FAIL] Validation errors:\n');
            for i = 1:length(validation_errors)
                fprintf('    - %s\n', validation_errors{i});
            end
        end
        
        %% STEP 9: SUMMARY AND STATISTICS
        fprintf('\n[STEP 9] Grid and rock model statistics...\n');
        
        % Grid statistics
        fprintf('  Grid Statistics:\n');
        fprintf('    Total cells: %d\n', G.cells.num);
        fprintf('    Grid dimensions: %d × %d × %d\n', G.cartDims);
        fprintf('    Cell volume: %.1f - %.1f m³\n', min(G.cells.volumes), max(G.cells.volumes));
        fprintf('    Depth range: %.1f - %.1f m (%.0f - %.0f ft)\n', ...
                min(cell_depths_m), max(cell_depths_m), min(cell_depths_ft), max(cell_depths_ft));
        
        % Rock statistics
        fprintf('  Rock Properties Statistics:\n');
        fprintf('    Porosity: %.1f%% - %.1f%% (avg: %.1f%%)\n', ...
                min(rock.poro)*100, max(rock.poro)*100, mean(rock.poro)*100);
        fprintf('    Permeability: %.0f - %.0f mD (avg: %.0f mD)\n', ...
                min(rock.perm)/mD_to_m2, max(rock.perm)/mD_to_m2, mean(rock.perm)/mD_to_m2);
        
        % Zone statistics
        for zone = 1:3
            zone_cells = sum(rock.zones == zone);
            zone_poro = mean(rock.poro(rock.zones == zone)) * 100;
            zone_perm = mean(rock.perm(rock.zones == zone)) / mD_to_m2;
            fprintf('    Zone %d: %d cells, φ=%.1f%%, k=%.0f mD\n', zone, zone_cells, zone_poro, zone_perm);
        end
        
        % Pore volume calculation
        pore_volume_m3 = sum(G.cells.volumes .* rock.poro);
        pore_volume_bbl = pore_volume_m3 / 0.158987; % Convert m³ to barrels
        fprintf('    Total pore volume: %.0f m³ (%.0f bbl)\n', pore_volume_m3, pore_volume_bbl);
        
        % Fault statistics
        fault_faces = sum(rock.perm_mult < 1.0);
        fprintf('  Fault System Statistics:\n');
        fprintf('    Fault-affected faces: %d (%.1f%% of total)\n', fault_faces, fault_faces/G.faces.num*100);
        fprintf('    Transmissibility reduction: %.0f%% - %.0f%%\n', ...
                (1-max(rock.perm_mult(rock.perm_mult < 1)))*100, (1-min(rock.perm_mult(rock.perm_mult < 1)))*100);
        
        %% FINAL OUTPUT
        duration = toc(static_start_time);
        
        fprintf('\n=================================================================\n');
        fprintf('  STATIC MODEL CONSTRUCTION SUMMARY\n');
        fprintf('=================================================================\n');
        fprintf('Status: COMPLETED\n');
        fprintf('Duration: %.2f seconds\n', duration);
        fprintf('Grid: %d cells (%d × %d × %d)\n', G.cells.num, G.cartDims);
        fprintf('Zones: 3 geological zones with distinct properties\n');
        fprintf('Faults: 5 major fault systems implemented\n');
        if validation_passed
            validation_status = 'PASSED';
        else
            validation_status = 'FAILED';
        end
        fprintf('Validation: %s\n', validation_status);
        
        if validation_passed
            fprintf('\n[OK] STATIC MODEL COMPLETED SUCCESSFULLY\n');
            fprintf('--> Ready to proceed to s03_setup_fluid_system.m\n');
        else
            fprintf('\n[FAIL] STATIC MODEL COMPLETED WITH ERRORS\n');
            fprintf('--> Review validation errors before proceeding\n');
        end
        
        fprintf('=================================================================\n\n');
        
    catch ME
        % Handle static model construction errors
        fprintf('\n[FAIL] STATIC MODEL CONSTRUCTION FAILED\n');
        fprintf('Error: %s\n', ME.message);
        if ~isempty(ME.stack)
            fprintf('Location: %s (line %d)\n', ME.stack(1).name, ME.stack(1).line);
        end
        
        % Return empty structures on failure
        G = [];
        rock = [];
        
        rethrow(ME);
    end
end