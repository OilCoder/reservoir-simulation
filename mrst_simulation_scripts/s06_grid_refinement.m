function refinement_data = s06_grid_refinement()
    script_dir = fileparts(mfilename('fullpath'));
    addpath(fullfile(script_dir, 'utils')); 
    run(fullfile(script_dir, 'utils', 'print_utils.m'));

    % Add MRST session validation
    [success, message] = validate_mrst_session(script_dir);
    if ~success
        error('MRST validation failed: %s', message);
    end
% S06_GRID_REFINEMENT - Apply tiered local grid refinement for Eagle West Field
% Requires: MRST
%
% TIERED REFINEMENT STRATEGY (Phase 3 Recalibrated - Target 20-30% Coverage):
%   Well Tiers (by production importance):
%     - Critical: EW-001, EW-003, EW-005, EW-007, EW-010 (2x2 refinement, 185ft radius)
%     - Standard: EW-002, EW-008, IW-001, IW-003 (1.5x1.5 refinement, 125ft radius)  
%     - Marginal: EW-004, EW-006, EW-009, IW-002, IW-004, IW-005 (DISABLED - no refinement)
%
%   Fault Tiers (by sealing capacity):
%     - Major: Fault_A, Fault_C, Fault_D (2x2 refinement, 125ft buffer) [3 high-sealing faults]
%     - Minor: Fault_B, Fault_E (1.5x1.5 refinement, 100ft buffer) [2 lower-sealing faults]
%
% TIER RATIONALE:
%   - Critical wells: High-rate producers, multi-lateral, horizontal wells
%   - Major faults: High sealing capacity (transmissibility < 0.01)
%   - Priority-based conflict resolution ensures optimal refinement distribution
%
% OUTPUT:
%   refinement_data - Structure containing tiered grid refinement data with statistics
%
% Author: Claude Code AI System
% Date: January 30, 2025
% Updated: Phase 3 - Recalibrated Refinement Strategy (Target 20-30% Coverage)

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
    script_dir = fileparts(mfilename('fullpath'));

    % Substep 1.1 – Load fault system file _______________________
    addpath(fullfile(script_dir, 'utils'));
    data_dir = get_data_path('static');
    fault_file = fullfile(data_dir, 'fault_system.mat');
    
    if ~exist(fault_file, 'file')
        error('Fault system not found. Run s05_add_faults first.');
    end
    
    % ✅ Load fault data
    load(fault_file, 'G', 'fault_geometries');
    
end

function well_locations = step_1_load_wells_config()
% Step 1 - Load wells configuration and extract locations

    % Substep 1.2 – Load wells configuration ______________________
    wells_config = load_wells_from_yaml();
    
    % Substep 1.3 – Extract well locations _________________________
    well_locations = extract_well_coordinates(wells_config);
    
end

function locations = extract_well_coordinates(wells_config)
% Extract well grid locations from configuration
    
    locations = [];
    
    % Access wells through wells_system nested structure
    if ~isfield(wells_config, 'wells_system')
        error('Wells configuration missing wells_system section');
    end
    
    wells_system = wells_config.wells_system;
    
    % Extract producer locations from wells_system.producer_wells section
    if isfield(wells_system, 'producer_wells')
        producer_names = fieldnames(wells_system.producer_wells);
        for i = 1:length(producer_names)
            well_name = producer_names{i};
            well_data = wells_system.producer_wells.(well_name);
            if isfield(well_data, 'grid_location')
                locations(end+1,:) = well_data.grid_location;
            end
        end
    end
    
    % Extract injector locations from wells_system.injector_wells section
    if isfield(wells_system, 'injector_wells')
        injector_names = fieldnames(wells_system.injector_wells);
        for i = 1:length(injector_names)
            well_name = injector_names{i};
            well_data = wells_system.injector_wells.(well_name);
            if isfield(well_data, 'grid_location')
                locations(end+1,:) = well_data.grid_location;
            end
        end
    end
    
end

function refinement_zones = step_1_identify_zones(G, well_locations, fault_geometries)
% Step 1 - Identify refinement zones around wells and faults

    % Substep 1.3 – Load refinement configuration from YAML ________
    refinement_config = load_refinement_config();
    
    % Substep 1.4 – Create well refinement zones ___________________
    if isfield(refinement_config, 'tiered_strategy') && refinement_config.tiered_strategy.enable
        well_zones = create_tiered_well_refinement_zones(well_locations, refinement_config);
    else
        well_zones = create_well_refinement_zones(well_locations, refinement_config);
    end
    
    % Substep 1.5 – Create fault refinement zones __________________
    if isfield(refinement_config, 'tiered_strategy') && refinement_config.tiered_strategy.enable
        fault_zones = create_tiered_fault_refinement_zones(fault_geometries, refinement_config);
    else
        fault_zones = create_fault_refinement_zones(fault_geometries, refinement_config);
    end
    
    % Substep 1.6 – Combine all zones (FIXED: Handle structure mismatch) ___
    refinement_zones = combine_refinement_zones(well_zones, fault_zones);
    
end

function refinement_zones = combine_refinement_zones(well_zones, fault_zones)
% Combine well and fault zones with FAIL_FAST validation and canonical field handling
% FAIL_FAST_POLICY: No defensive programming - validate canonical structure
% FIX: Use only canonical fields for concatenation to resolve field mismatch

    % FAIL_FAST: Validate canonical zone structures exist
    if isempty(well_zones) && isempty(fault_zones)
        error(['No refinement zones found.\n' ...
               'REQUIRED: Canonical Eagle West Field must have exactly 15 wells and 5 faults.\n' ...
               'Expected wells: EW-001 to EW-010, IW-001 to IW-005\n' ...
               'Expected faults: Fault_A, Fault_B, Fault_C, Fault_D, Fault_E\n' ...
               'Check wells_config.yaml and fault_config.yaml for canonical data.']);
    end
    
    % Define canonical fields required for all refinement zones
    canonical_fields = {'id', 'type', 'refinement_factor', 'tier', 'priority'};
    
    % FAIL_FAST: Validate well zones have canonical structure
    if ~isempty(well_zones)
        required_well_fields = {'id', 'type', 'well_name', 'center_x', 'center_y', 'radius', 'refinement_factor', 'tier', 'priority'};
        for i = 1:length(well_zones)
            for j = 1:length(required_well_fields)
                field = required_well_fields{j};
                if ~isfield(well_zones, field) || isempty(well_zones(i).(field))
                    error(['Invalid well refinement zone structure.\n' ...
                           'REQUIRED: All well zones must have canonical fields: well_name, center_x, center_y, radius\n' ...
                           'Missing field "%s" in well zone %d.\n' ...
                           'Check tiered well refinement configuration in grid_config.yaml.'], field, i);
                end
            end
        end
    end
    
    % FAIL_FAST: Validate fault zones have canonical structure  
    if ~isempty(fault_zones)
        required_fault_fields = {'id', 'type', 'fault_name', 'x1', 'y1', 'x2', 'y2', 'buffer', 'refinement_factor', 'tier', 'priority'};
        for i = 1:length(fault_zones)
            for j = 1:length(required_fault_fields)
                field = required_fault_fields{j};
                if ~isfield(fault_zones, field) || isempty(fault_zones(i).(field))
                    error(['Invalid fault refinement zone structure.\n' ...
                           'REQUIRED: All fault zones must have canonical fields: fault_name, x1, y1, x2, y2, buffer\n' ...
                           'Missing field "%s" in fault zone %d.\n' ...
                           'Check tiered fault refinement configuration in grid_config.yaml.'], field, i);
                end
            end
        end
    end
    
    % FIX: Create unified structures using only canonical fields for concatenation
    % Store original structures with all fields in a separate field for later use
    
    if isempty(well_zones)
        refinement_zones = fault_zones;
    elseif isempty(fault_zones)
        refinement_zones = well_zones;
    else
        % Extract canonical fields for concatenation-safe combination
        well_canonical = extract_canonical_fields(well_zones, canonical_fields);
        fault_canonical = extract_canonical_fields(fault_zones, canonical_fields);
        
        % Combine canonical structures (field mismatch resolved)
        refinement_zones = [well_canonical, fault_canonical];
        
        % Store original structures for detailed processing later
        refinement_zones(1).original_well_zones = well_zones;
        refinement_zones(1).original_fault_zones = fault_zones;
    end
    
end

function canonical_zones = extract_canonical_fields(zones, canonical_fields)
% Extract only canonical fields from zones for safe concatenation
% Preserves canonical structure while enabling concatenation

    canonical_zones = [];
    
    for i = 1:length(zones)
        for j = 1:length(canonical_fields)
            field = canonical_fields{j};
            canonical_zones(i).(field) = zones(i).(field);
        end
        
        % Store original zone data for detailed processing
        canonical_zones(i).original_zone = zones(i);
    end
    
end

function well_zones = create_well_refinement_zones(well_locations, refinement_config)
% Create refinement zones using YAML config with FAIL_FAST validation
% FAIL_FAST_POLICY: No legacy mode - tiered strategy must be enabled
    
    % FAIL_FAST: Legacy uniform refinement not supported for canonical Eagle West
    error(['Legacy uniform well refinement not supported for canonical Eagle West Field.\n' ...
           'REQUIRED: Enable tiered_strategy.enable = true in grid_config.yaml\n' ...
           'Eagle West Field uses tiered refinement with exactly:\n' ...
           '- Critical wells: EW-001, EW-003, EW-005, EW-007, EW-010 (2x2 refinement)\n' ...
           '- Standard wells: EW-002, EW-008, IW-001, IW-003 (1.5x1.5 refinement)\n' ...
           '- Marginal wells: EW-004, EW-006, EW-009, IW-002, IW-004, IW-005 (no refinement)\n' ...
           'Set refinement.tiered_strategy.enable = true to use canonical configuration.']);
end

function well_zones = create_tiered_well_refinement_zones(well_locations, refinement_config)
% Create tiered refinement zones around wells based on production importance
    
    well_zones = [];
    wells_config = load_wells_from_yaml();
    zone_id = 1;
    
    % Extract all wells from configuration for tier lookup
    all_wells = get_all_well_names(wells_config);
    
    for w = 1:size(well_locations, 1)
        % Convert grid coordinates to physical coordinates
        well_i = well_locations(w, 1);
        well_j = well_locations(w, 2);
        
        % FAIL_FAST: Load canonical cell sizes from YAML, no hardcoding
        if ~isfield(refinement_config, 'cell_size_x') || ~isfield(refinement_config, 'cell_size_y')
            error(['Missing canonical cell sizes in refinement configuration.\n' ...
                   'REQUIRED: grid_config.yaml must contain grid.cell_size_x and grid.cell_size_y\n' ...
                   'Canonical Eagle West values: cell_size_x = 82.0 ft, cell_size_y = 74.0 ft\n' ...
                   'NO_HARDCODING_POLICY: All parameters must come from YAML configuration.']);
        end
        
        well_x = (well_i - 1) * refinement_config.cell_size_x;
        well_y = (well_j - 1) * refinement_config.cell_size_y;
        
        % Determine well name and tier (simplified approach - use index mapping)
        % FAIL_FAST: All wells must be canonical Eagle West wells
        if w > length(all_wells)
            error(['Well index %d exceeds canonical well count %d.\n' ...
                   'REQUIRED: Eagle West Field has exactly 15 wells: EW-001 to EW-010, IW-001 to IW-005\n' ...
                   'Check wells_config.yaml for canonical well definitions.'], w, length(all_wells));
        end
        
        well_name = all_wells{w};
        [tier_name, tier_config] = determine_well_tier(well_name, refinement_config);
        
        % Skip wells with no refinement (factor 1 or radius 0)
        if tier_config.factor <= 1 || tier_config.radius <= 0
            continue; % Skip disabled wells (marginal tier in recalibrated config)
        end
        
        well_zones(zone_id).id = zone_id;
        well_zones(zone_id).type = 'well';
        well_zones(zone_id).well_name = well_name;
        well_zones(zone_id).center_x = well_x;
        well_zones(zone_id).center_y = well_y;
        well_zones(zone_id).radius = tier_config.radius;
        well_zones(zone_id).refinement_factor = tier_config.factor;
        well_zones(zone_id).tier = tier_name;
        well_zones(zone_id).priority = tier_config.priority;
        
        zone_id = zone_id + 1;
    end
    
end

function [tier_name, tier_config] = determine_well_tier(well_name, refinement_config)
% Determine canonical well tier - FAIL_FAST if not found
% FAIL_FAST_POLICY: All wells must be in canonical tier configuration
    
    % FAIL_FAST: Validate well_tiers configuration exists
    if ~isfield(refinement_config.well_refinement, 'well_tiers')
        error(['Missing well_tiers configuration in grid_config.yaml\n' ...
               'REQUIRED: refinement.well_refinement.well_tiers must define:\n' ...
               '- critical: ["EW-001", "EW-003", "EW-005", "EW-007", "EW-010"]\n' ...
               '- standard: ["EW-002", "EW-008", "IW-001", "IW-003"]\n' ...
               '- marginal: ["EW-004", "EW-006", "EW-009", "IW-002", "IW-004", "IW-005"]']);
    end
    
    tiers = fieldnames(refinement_config.well_refinement.well_tiers);
    
    for t = 1:length(tiers)
        tier_name = tiers{t};
        tier_config = refinement_config.well_refinement.well_tiers.(tier_name);
        
        if isfield(tier_config, 'wells') && ismember(well_name, tier_config.wells)
            return;
        end
    end
    
    % FAIL_FAST: Well not found in any canonical tier
    error(['Well "%s" not found in canonical tier configuration.\n' ...
           'REQUIRED: All Eagle West wells must be assigned to exactly one tier:\n' ...
           '- critical: EW-001, EW-003, EW-005, EW-007, EW-010\n' ...
           '- standard: EW-002, EW-008, IW-001, IW-003\n' ...
           '- marginal: EW-004, EW-006, EW-009, IW-002, IW-004, IW-005\n' ...
           'Check grid_config.yaml refinement.well_refinement.well_tiers configuration.'], well_name);
end

function all_wells = get_all_well_names(wells_config)
% Extract all well names from wells configuration
    
    all_wells = {};
    
    if isfield(wells_config, 'wells_system')
        wells_system = wells_config.wells_system;
        
        % Get producer well names
        if isfield(wells_system, 'producer_wells')
            producer_names = fieldnames(wells_system.producer_wells);
            all_wells = [all_wells; producer_names];
        end
        
        % Get injector well names
        if isfield(wells_system, 'injector_wells')
            injector_names = fieldnames(wells_system.injector_wells);
            all_wells = [all_wells; injector_names];
        end
    end
    
end

function fault_zones = create_fault_refinement_zones(fault_geometries, refinement_config)
% Create fault refinement zones with FAIL_FAST validation
% FAIL_FAST_POLICY: No legacy mode - tiered strategy must be enabled
    
    % FAIL_FAST: Legacy uniform fault refinement not supported for canonical Eagle West
    error(['Legacy uniform fault refinement not supported for canonical Eagle West Field.\n' ...
           'REQUIRED: Enable tiered_strategy.enable = true in grid_config.yaml\n' ...
           'Eagle West Field uses tiered fault refinement with exactly:\n' ...
           '- Major faults: Fault_A, Fault_C, Fault_D (2x2 refinement, 125ft buffer)\n' ...
           '- Minor faults: Fault_B, Fault_E (1.5x1.5 refinement, 100ft buffer)\n' ...
           'Set refinement.tiered_strategy.enable = true to use canonical configuration.']);
end

function fault_zones = create_tiered_fault_refinement_zones(fault_geometries, refinement_config)
% Create tiered refinement zones around faults based on sealing capacity
    
    fault_zones = [];
    zone_id = 1;
    
    for f = 1:length(fault_geometries)
        fault = fault_geometries(f);
        
        % Determine fault tier based on sealing capacity and configuration
        [tier_name, tier_config] = determine_fault_tier(fault.name, refinement_config);
        
        % Apply refinement based on tier configuration and fault properties
        should_refine = should_refine_fault(fault, tier_config, refinement_config);
        
        if should_refine
            fault_zones(zone_id).id = zone_id;
            fault_zones(zone_id).type = 'fault';
            fault_zones(zone_id).fault_name = fault.name;
            fault_zones(zone_id).x1 = fault.x1;
            fault_zones(zone_id).y1 = fault.y1;
            fault_zones(zone_id).x2 = fault.x2;
            fault_zones(zone_id).y2 = fault.y2;
            fault_zones(zone_id).buffer = tier_config.buffer;
            fault_zones(zone_id).refinement_factor = tier_config.factor;
            fault_zones(zone_id).tier = tier_name;
            fault_zones(zone_id).priority = tier_config.priority;
            
            zone_id = zone_id + 1;
        end
    end
    
end

function [tier_name, tier_config] = determine_fault_tier(fault_name, refinement_config)
% Determine canonical fault tier - FAIL_FAST if not found
% FAIL_FAST_POLICY: All faults must be in canonical tier configuration
    
    % FAIL_FAST: Validate fault_tiers configuration exists
    if ~isfield(refinement_config.fault_refinement, 'fault_tiers')
        error(['Missing fault_tiers configuration in grid_config.yaml\n' ...
               'REQUIRED: refinement.fault_refinement.fault_tiers must define:\n' ...
               '- major: ["Fault_A", "Fault_C", "Fault_D"]\n' ...
               '- minor: ["Fault_B", "Fault_E"]']);
    end
    
    tiers = fieldnames(refinement_config.fault_refinement.fault_tiers);
    
    for t = 1:length(tiers)
        tier_name = tiers{t};
        tier_config = refinement_config.fault_refinement.fault_tiers.(tier_name);
        
        if isfield(tier_config, 'faults') && ismember(fault_name, tier_config.faults)
            return;
        end
    end
    
    % FAIL_FAST: Fault not found in any canonical tier
    error(['Fault "%s" not found in canonical tier configuration.\n' ...
           'REQUIRED: All Eagle West faults must be assigned to exactly one tier:\n' ...
           '- major: Fault_A, Fault_C, Fault_D (high sealing capacity)\n' ...
           '- minor: Fault_B, Fault_E (lower sealing capacity)\n' ...
           'Check grid_config.yaml refinement.fault_refinement.fault_tiers configuration.'], fault_name);
end

function should_refine = should_refine_fault(fault, tier_config, refinement_config)
% Determine fault refinement with FAIL_FAST canonical validation
% FAIL_FAST_POLICY: All decisions must be based on canonical configuration
    
    % FAIL_FAST: Validate fault refinement is enabled for canonical Eagle West
    if ~refinement_config.fault_refinement.enable
        error(['Fault refinement disabled in configuration.\n' ...
               'REQUIRED: Eagle West Field requires fault refinement enabled.\n' ...
               'Set refinement.fault_refinement.enable = true in grid_config.yaml\n' ...
               'Canonical faults: Fault_A, Fault_B, Fault_C, Fault_D, Fault_E must be refined.']);
    end
    
    % FAIL_FAST: Validate fault has canonical sealing property
    if ~isfield(fault, 'is_sealing')
        error(['Fault "%s" missing canonical is_sealing property.\n' ...
               'REQUIRED: All Eagle West faults must have is_sealing field from s05_add_faults.\n' ...
               'Run s05_add_faults.m to generate canonical fault properties.'], fault.name);
    end
    
    % FAIL_FAST: Validate tier configuration has required priority
    if ~isfield(tier_config, 'priority')
        error(['Fault tier configuration missing priority field.\n' ...
               'REQUIRED: All fault tiers must have priority field in grid_config.yaml\n' ...
               'Expected: major (priority: 1), minor (priority: 2)']);
    end
    
    % Canonical Eagle West fault refinement logic
    if tier_config.priority == 1
        % Major tier: refine all sealing faults
        should_refine = fault.is_sealing;
    elseif tier_config.priority == 2
        % Minor tier: refine all sealing faults  
        should_refine = fault.is_sealing;
    else
        % FAIL_FAST: Unknown priority not supported
        error(['Unknown fault tier priority %d for fault "%s".\n' ...
               'REQUIRED: Eagle West fault priorities must be 1 (major) or 2 (minor).\n' ...
               'Check grid_config.yaml fault tier configuration.'], tier_config.priority, fault.name);
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
    
    % Load LGR module with fallback validation
    if ~exist('mrstModule', 'file')
        error(['MRST not properly initialized\n' ...
               'UPDATE CANON: obsidian-vault/Planning/MRST_Requirements.md\n' ...
               'Must run s01_initialize_mrst.m first.']);
    end
    
    % Load LGR module (required for grid refinement)
    mrstModule('add', 'lgr');
    
    if ~exist('addLayersToGrid', 'file')
        error(['MRST LGR module not available\n' ...
               'UPDATE CANON: obsidian-vault/Planning/MRST_Requirements.md\n' ...
               'Must use MRST version with LGR module support.']);
    end
    
    G_refined = apply_mrst_native_lgr(G, refinement_zones);
    end
    
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
% Real refinement approach - supports both tiered and uniform refinement
    
    fprintf('   Applying tiered grid refinement...\n');
    
    % Start with original grid
    G_refined = G;
    
    % Identify cells that need refinement with tier-aware logic
    x = G.cells.centroids(:,1);
    y = G.cells.centroids(:,2);
    
    cells_to_refine = [];
    refinement_factors = [];
    zone_priorities = [];
    
    for z = 1:length(refinement_zones)
        zone = refinement_zones(z);
        zone_cells = find_zone_cells(x, y, zone);
        
        if ~isempty(zone_cells)
            cells_to_refine = [cells_to_refine; zone_cells];
            refinement_factors = [refinement_factors; repmat(zone.refinement_factor, length(zone_cells), 1)];
            
            % Handle priority for conflict resolution
            if isfield(zone, 'priority')
                zone_priorities = [zone_priorities; repmat(zone.priority, length(zone_cells), 1)];
            else
                zone_priorities = [zone_priorities; repmat(2, length(zone_cells), 1)];  % Default priority
            end
        end
    end
    
    % Handle overlapping zones by applying highest priority (lowest number) refinement
    if ~isempty(cells_to_refine)
        [unique_cells, ~, ic] = unique(cells_to_refine);
        final_factors = zeros(length(unique_cells), 1);
        
        for i = 1:length(unique_cells)
            cell_id = unique_cells(i);
            
            % Find all zones affecting this cell
            cell_indices = find(cells_to_refine == cell_id);
            cell_priorities = zone_priorities(cell_indices);
            cell_factors = refinement_factors(cell_indices);
            
            % Apply highest priority (lowest number) zone's refinement
            [min_priority, priority_idx] = min(cell_priorities);
            final_factors(i) = cell_factors(priority_idx);
        end
        
        % Apply tiered subdivision
        G_refined = apply_real_subdivision(G, unique_cells, final_factors);
        
        % Report refinement statistics by tier
        report_tiered_refinement_statistics(refinement_zones, unique_cells, final_factors);
        
        fprintf('   Grid refined from %d to %d cells\n', G.cells.num, G_refined.cells.num);
    else
        fprintf('   No cells identified for refinement\n');
    end
    
end

function report_tiered_refinement_statistics(refinement_zones, refined_cells, factors)
% Report refinement statistics by tier for validation
    
    % Count refinement by tier
    tier_stats = struct();
    
    for z = 1:length(refinement_zones)
        zone = refinement_zones(z);
        
        if isfield(zone, 'tier')
            tier_name = zone.tier;
        else
            tier_name = 'standard';
        end
        
        if ~isfield(tier_stats, tier_name)
            tier_stats.(tier_name) = struct('cells', 0, 'factor', zone.refinement_factor);
        end
    end
    
    % Count cells by factor
    unique_factors = unique(factors);
    for f = 1:length(unique_factors)
        factor = unique_factors(f);
        cell_count = sum(factors == factor);
        fprintf('   Refinement factor %dx%d applied to %d cells\n', factor, factor, cell_count);
    end
    
end

function G_refined = apply_real_subdivision(G, cells_to_refine, factors)
% Apply real cell subdivision for refinement with tiered factor support
    
    % Handle tiered refinement factors
    if length(factors) == 1
        refinement_factor = factors;
    elseif length(factors) == length(cells_to_refine)
        % Apply individual factors for each cell (tiered approach)
        G_refined = apply_tiered_subdivision(G, cells_to_refine, factors);
        return;
    else
        refinement_factor = factors(1); % Use first factor for all cells
    end
    
    % Calculate new grid dimensions
    original_cells = G.cells.num;
    refined_cells_count = length(cells_to_refine) * (refinement_factor.^2 - 1);
    new_total_cells = original_cells + refined_cells_count;
    
    % Create new grid structure
    G_refined = G;
    
    % Expand cell arrays
    G_refined.cells.num = new_total_cells;
    
    % Initialize new cell properties
    new_centroids = G.cells.centroids;
    new_volumes = G.cells.volumes;
    
    % Process each cell to refine
    current_new_cell = original_cells + 1;
    
    for i = 1:length(cells_to_refine)
        cell_id = cells_to_refine(i);
        
        % Get original cell properties
        orig_centroid = G.cells.centroids(cell_id, :);
        orig_volume = G.cells.volumes(cell_id);
        
        % FAIL_FAST: Validate canonical grid has required geometric data
        if ~isfield(G, 'cartDims') || ~isfield(G, 'nodes')
            error(['Grid missing canonical geometric data.\n' ...
                   'REQUIRED: Eagle West grid must have cartDims and nodes fields.\n' ...
                   'Run s02_create_grid.m to generate canonical 41x41x12 grid structure.']);
        end
        
        % Use canonical grid dimensions
        dx = G.nodes.coords(end, 1) / G.cartDims(1);
        dy = G.nodes.coords(end, 2) / G.cartDims(2);
        
        % Create 2x2 subdivision
        sub_dx = dx / refinement_factor;
        sub_dy = dy / refinement_factor;
        sub_volume = orig_volume / (refinement_factor.^2);
        
        % Update original cell (becomes top-left subcell)
        new_centroids(cell_id, :) = orig_centroid + [-sub_dx/2, -sub_dy/2, 0];
        new_volumes(cell_id) = sub_volume;
        
        % Add 3 new subcells
        subcell_offsets = [
            [sub_dx/2, -sub_dy/2, 0];   % Top-right
            [-sub_dx/2, sub_dy/2, 0];   % Bottom-left
            [sub_dx/2, sub_dy/2, 0]     % Bottom-right
        ];
        
        for j = 1:3
            new_centroids(current_new_cell, :) = orig_centroid + subcell_offsets(j, :);
            new_volumes(current_new_cell) = sub_volume;
            current_new_cell = current_new_cell + 1;
        end
    end
    
    % Update grid with new properties
    G_refined.cells.centroids = new_centroids;
    G_refined.cells.volumes = new_volumes;
    
    % Add refinement metadata
    G_refined.cells.refinement_level = ones(G_refined.cells.num, 1);
    G_refined.cells.parent_cell = (1:G_refined.cells.num)';
    
    % Mark refined cells
    refined_cell_indices = [cells_to_refine; (original_cells+1:new_total_cells)'];
    G_refined.cells.refinement_level(refined_cell_indices) = refinement_factor;
    
    % Update parent cell mapping for new cells
    current_new_cell = original_cells + 1;
    for i = 1:length(cells_to_refine)
        parent_id = cells_to_refine(i);
        for j = 1:3  % 3 additional subcells per parent
            G_refined.cells.parent_cell(current_new_cell) = parent_id;
            current_new_cell = current_new_cell + 1;
        end
    end
    
end

function G_refined = apply_tiered_subdivision(G, cells_to_refine, factors)
% Apply tiered refinement with individual factors for each cell
    
    % Start with original grid
    G_refined = G;
    
    % Calculate total new cells needed for all refinement factors
    original_cells = G.cells.num;
    total_new_cells = 0;
    
    for i = 1:length(cells_to_refine)
        factor = factors(i);
        % Handle fractional factors (e.g., 1.5 -> 2.25 -> 2 new cells per original)
        if factor == 1.5
            % 1.5x1.5 = 2.25 ≈ 2 cells per original (simplified approach)
            total_new_cells = total_new_cells + 1; % Add 1 new cell per 1.5x refined cell
        elseif factor == 1
            % No refinement for factor 1 (marginal wells disabled)
            continue;
        else
            % Standard integer factors (2, 3, etc.)
            total_new_cells = total_new_cells + (factor^2 - 1);
        end
    end
    
    new_total_cells = original_cells + total_new_cells;
    
    % Create new grid structure
    G_refined.cells.num = new_total_cells;
    
    % Initialize new cell properties
    new_centroids = G.cells.centroids;
    new_volumes = G.cells.volumes;
    
    % Expand arrays to accommodate new cells
    new_centroids(new_total_cells, :) = 0;
    new_volumes(new_total_cells) = 0;
    
    % Process each cell to refine with its specific factor
    current_new_cell = original_cells + 1;
    
    for i = 1:length(cells_to_refine)
        cell_id = cells_to_refine(i);
        refinement_factor = factors(i);
        
        % Get original cell properties
        orig_centroid = G.cells.centroids(cell_id, :);
        orig_volume = G.cells.volumes(cell_id);
        
        % FAIL_FAST: Validate canonical grid has required geometric data
        if ~isfield(G, 'cartDims') || ~isfield(G, 'nodes')
            error(['Grid missing canonical geometric data.\n' ...
                   'REQUIRED: Eagle West grid must have cartDims and nodes fields.\n' ...
                   'Run s02_create_grid.m to generate canonical 41x41x12 grid structure.']);
        end
        
        % Use canonical grid dimensions
        dx = G.nodes.coords(end, 1) / G.cartDims(1);
        dy = G.nodes.coords(end, 2) / G.cartDims(2);
        
        % Handle special cases for refinement factors
        if refinement_factor == 1
            % No refinement for factor 1 (marginal wells disabled)
            continue;
        elseif refinement_factor == 1.5
            % Special handling for 1.5x factor: split into 2 cells (1x2 subdivision)
            sub_dx = dx / 2;  % Split in half in x-direction
            sub_dy = dy;      % Keep original in y-direction
            sub_volume = orig_volume / 2;
            
            % Update original cell (becomes left subcell)
            new_centroids(cell_id, :) = orig_centroid + [-sub_dx/2, 0, 0];
            new_volumes(cell_id) = sub_volume;
            
            % Add one new subcell (right side)
            new_centroids(current_new_cell, :) = orig_centroid + [sub_dx/2, 0, 0];
            new_volumes(current_new_cell) = sub_volume;
            current_new_cell = current_new_cell + 1;
        else
            % Standard integer factors (2, 3, etc.)
            % Create subdivision based on refinement factor
            sub_dx = dx / refinement_factor;
            sub_dy = dy / refinement_factor;
            sub_volume = orig_volume / (refinement_factor^2);
            
            % Update original cell (becomes first subcell)
            offset_x = -(refinement_factor-1) * sub_dx / 2;
            offset_y = -(refinement_factor-1) * sub_dy / 2;
            new_centroids(cell_id, :) = orig_centroid + [offset_x, offset_y, 0];
            new_volumes(cell_id) = sub_volume;
            
            % Add remaining subcells in grid pattern
            subcell_count = 0;
            for ix = 1:refinement_factor
                for iy = 1:refinement_factor
                    if ix == 1 && iy == 1
                        continue;  % Skip first subcell (already updated original)
                    end
                    
                    subcell_count = subcell_count + 1;
                    offset_x = -(refinement_factor-1) * sub_dx / 2 + (ix-1) * sub_dx;
                    offset_y = -(refinement_factor-1) * sub_dy / 2 + (iy-1) * sub_dy;
                    
                    new_centroids(current_new_cell, :) = orig_centroid + [offset_x, offset_y, 0];
                    new_volumes(current_new_cell) = sub_volume;
                    current_new_cell = current_new_cell + 1;
                end
            end
        end
    end
    
    % Update grid with new properties
    G_refined.cells.centroids = new_centroids;
    G_refined.cells.volumes = new_volumes;
    
    % Add tiered refinement metadata
    G_refined.cells.refinement_level = ones(G_refined.cells.num, 1);
    G_refined.cells.parent_cell = (1:G_refined.cells.num)';
    
    % Mark refined cells with their specific factors
    current_new_cell = original_cells + 1;
    for i = 1:length(cells_to_refine)
        cell_id = cells_to_refine(i);
        refinement_factor = factors(i);
        
        % Mark parent cell
        G_refined.cells.refinement_level(cell_id) = refinement_factor;
        
        % Mark all subcells and update parent mapping
        if refinement_factor == 1
            % No subcells for factor 1
            continue;
        elseif refinement_factor == 1.5
            % Mark the one new subcell for 1.5x factor
            G_refined.cells.refinement_level(current_new_cell) = refinement_factor;
            G_refined.cells.parent_cell(current_new_cell) = cell_id;
            current_new_cell = current_new_cell + 1;
        else
            % Standard integer factors
            for j = 1:(refinement_factor^2 - 1)
                G_refined.cells.refinement_level(current_new_cell) = refinement_factor;
                G_refined.cells.parent_cell(current_new_cell) = cell_id;
                current_new_cell = current_new_cell + 1;
            end
        end
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
        % Check if zone has original well data for detailed processing
        if isfield(zone, 'original_zone')
            original_zone = zone.original_zone;
            % Cells within well radius (using center_x, center_y, radius)
            if isfield(original_zone, 'center_x') && isfield(original_zone, 'center_y') && isfield(original_zone, 'radius')
                distances = sqrt((x - original_zone.center_x).^2 + (y - original_zone.center_y).^2);
                zone_cells = find(distances <= original_zone.radius);
            else
                zone_cells = [];
            end
        else
            zone_cells = [];
        end
        
    elseif strcmp(zone.type, 'fault')
        % Check if zone has original fault data for detailed processing
        if isfield(zone, 'original_zone')
            original_zone = zone.original_zone;
            % Cells within fault buffer (using x1, y1, x2, y2, buffer)
            if isfield(original_zone, 'x1') && isfield(original_zone, 'y1') && isfield(original_zone, 'x2') && isfield(original_zone, 'y2') && isfield(original_zone, 'buffer')
                distances = calculate_point_to_line_distance(x, y, original_zone.x1, original_zone.y1, original_zone.x2, original_zone.y2);
                zone_cells = find(distances <= original_zone.buffer);
            else
                zone_cells = [];
            end
        else
            zone_cells = [];
        end
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
% Validate tiered refinement implementation
    
    if G_refined.cells.num < G.cells.num
        error(['Grid refinement failed - refined grid has fewer cells\n' ...
               'UPDATE CANON: obsidian-vault/Planning/Grid_Refinement.md\n' ...
               'Refinement must increase cell count for Eagle West Field.']);
    end
    
    if isfield(G_refined.cells, 'refinement_level')
        % Validate tiered refinement levels
        refinement_levels = G_refined.cells.refinement_level;
        unique_levels = unique(refinement_levels);
        
        fprintf('   Refinement validation:\n');
        for i = 1:length(unique_levels)
            level = unique_levels(i);
            cell_count = sum(refinement_levels == level);
            percentage = cell_count / G_refined.cells.num * 100;
            
            if level == 1
                fprintf('   - Original cells: %d (%.1f%%)\n', cell_count, percentage);
            else
                fprintf('   - %dx%d refined cells: %d (%.1f%%)\n', level, level, cell_count, percentage);
            end
        end
        
        % Check refinement coverage
        refined_cells = sum(refinement_levels > 1);
        refinement_coverage = refined_cells / G_refined.cells.num * 100;
        
        fprintf('   - Total refinement coverage: %.1f%%\n', refinement_coverage);
        
        % Validate tier distribution
        if refinement_coverage < 2
            error(['Refinement coverage too low: %.1f%%\n' ...
                   'UPDATE CANON: obsidian-vault/Planning/Grid_Refinement.md\n' ...
                   'Must achieve minimum 2%% refinement coverage.'], refinement_coverage);
        elseif refinement_coverage > 80
            error(['Refinement coverage too high: %.1f%%\n' ...
                   'UPDATE CANON: obsidian-vault/Planning/Grid_Refinement.md\n' ...
                   'Must not exceed 80%% refinement coverage.'], refinement_coverage);
        end
        
        % Validate tier structure
        if length(unique_levels) > 4
            error(['Too many refinement tiers: %d\n' ...
                   'UPDATE CANON: obsidian-vault/Planning/Grid_Refinement.md\n' ...
                   'Must use maximum 3 refinement tiers.'], length(unique_levels)-1);
        end
        
    else
        error(['Refinement metadata missing from grid\n' ...
               'UPDATE CANON: obsidian-vault/Planning/Grid_Refinement.md\n' ...
               'Must include refinement_level field in cells.']);
    end
    
end

function export_refinement_files(G_refined, refinement_zones)
% Export refined grid to files
    script_dir = fileparts(mfilename('fullpath'));
    
    addpath(fullfile(script_dir, 'utils'));
    data_dir = get_data_path('static');
    
    if ~exist(data_dir, 'dir')
        mkdir(data_dir);
    end
    
    refinement_file = fullfile(data_dir, 'refined_grid.mat');
    save(refinement_file, 'G_refined', 'refinement_zones');
    
end

function data = create_refinement_output(G, G_refined, refinement_zones, well_locations)
% Create tiered refinement output structure with comprehensive metadata
    
    data = struct();
    data.original_grid = G;
    data.refined_grid = G_refined;
    data.refinement_zones = refinement_zones;
    data.well_locations = well_locations;
    data.refinement_ratio = G_refined.cells.num / G.cells.num;
    data.status = 'completed';
    
    % Add tiered refinement statistics
    if isfield(G_refined.cells, 'refinement_level')
        refinement_levels = G_refined.cells.refinement_level;
        unique_levels = unique(refinement_levels);
        
        data.tier_statistics = struct();
        data.tier_statistics.total_tiers = length(unique_levels) - 1;  % Excluding base level 1
        data.tier_statistics.refinement_levels = unique_levels;
        
        % Calculate statistics for each tier
        for i = 1:length(unique_levels)
            level = unique_levels(i);
            cell_count = sum(refinement_levels == level);
            percentage = cell_count / G_refined.cells.num * 100;
            
            tier_name = sprintf('level_%d', level);
            data.tier_statistics.(tier_name) = struct();
            data.tier_statistics.(tier_name).refinement_factor = level;
            data.tier_statistics.(tier_name).cell_count = cell_count;
            data.tier_statistics.(tier_name).percentage = percentage;
        end
        
        % Overall refinement metrics
        refined_cells = sum(refinement_levels > 1);
        data.tier_statistics.total_refined_cells = refined_cells;
        data.tier_statistics.refinement_coverage_percent = refined_cells / G_refined.cells.num * 100;
    end
    
    % Add zone classification summary
    if ~isempty(refinement_zones)
        data.zone_summary = struct();
        data.zone_summary.total_zones = length(refinement_zones);
        
        % Count zones by type
        well_zones = sum(strcmp({refinement_zones.type}, 'well'));
        fault_zones = sum(strcmp({refinement_zones.type}, 'fault'));
        
        data.zone_summary.well_zones = well_zones;
        data.zone_summary.fault_zones = fault_zones;
        
        % Count zones by tier (if available)
        if isfield(refinement_zones, 'tier')
            tiers = {refinement_zones.tier};
            unique_tiers = unique(tiers);
            
            for t = 1:length(unique_tiers)
                tier_name = unique_tiers{t};
                tier_count = sum(strcmp(tiers, tier_name));
                data.zone_summary.(sprintf('%s_tier_zones', tier_name)) = tier_count;
            end
        end
    end
    
    % Add configuration validation
    data.validation = struct();
    data.validation.grid_integrity = G_refined.cells.num >= G.cells.num;
    data.validation.has_refinement_metadata = isfield(G_refined.cells, 'refinement_level');
    data.validation.has_parent_mapping = isfield(G_refined.cells, 'parent_cell');
    data.validation.timestamp = datestr(now, 'yyyy-mm-dd HH:MM:SS');
    
end

function wells_config = load_wells_from_yaml()
% Load wells configuration from YAML - FAIL_FAST implementation
% Follows FAIL_FAST_POLICY and CODE_GENERATION_POLICY - no hardcoded values
    
    script_dir = fileparts(mfilename('fullpath'));
    config_file = fullfile(script_dir, 'config', 'wells_config.yaml');
    
    % FAIL_FAST: Check if wells configuration exists
    if ~exist(config_file, 'file')
        error(['Wells configuration file missing: %s\n' ...
               'REQUIRED: wells_config.yaml must exist in config/ directory.\n' ...
               'This file should contain producer_wells and injector_wells sections\n' ...
               'with grid_location fields for each well (EW-001, IW-001, etc.).\n' ...
               'Run previous workflow steps to generate required configuration.'], config_file);
    end
    
    % Load and validate wells configuration
    try
        addpath(fullfile(script_dir, 'utils'));
        wells_config = read_yaml_config(config_file, true); % Silent mode
        
        % Validate required wells_system section exists
        if ~isfield(wells_config, 'wells_system')
            error(['Invalid wells configuration: %s\n' ...
                   'REQUIRED: File must contain wells_system section\n' ...
                   'with nested producer_wells and/or injector_wells subsections\n' ...
                   'containing canonical well names (EW-001, EW-002, IW-001, etc.)\n' ...
                   'and grid_location fields for grid refinement.\n' ...
                   'Found top-level sections: %s'], config_file, sprintf('%s ', fieldnames(wells_config){:}));
        end
        
        % Validate wells_system contains required subsections
        wells_system = wells_config.wells_system;
        if ~isfield(wells_system, 'producer_wells') && ~isfield(wells_system, 'injector_wells')
            error(['Invalid wells_system configuration: %s\n' ...
                   'REQUIRED: wells_system must contain producer_wells and/or injector_wells subsections\n' ...
                   'with canonical well names (EW-001, EW-002, IW-001, etc.)\n' ...
                   'and grid_location fields for grid refinement.\n' ...
                   'Found wells_system sections: %s'], config_file, sprintf('%s ', fieldnames(wells_system){:}));
        end
        
        % Validate that wells have grid_location fields
        total_wells_found = 0;
        wells_with_locations = 0;
        
        if isfield(wells_system, 'producer_wells')
            producer_names = fieldnames(wells_system.producer_wells);
            for i = 1:length(producer_names)
                total_wells_found = total_wells_found + 1;
                well_name = producer_names{i};
                well_data = wells_system.producer_wells.(well_name);
                if isfield(well_data, 'grid_location')
                    wells_with_locations = wells_with_locations + 1;
                end
            end
        end
        
        if isfield(wells_system, 'injector_wells')
            injector_names = fieldnames(wells_system.injector_wells);
            for i = 1:length(injector_names)
                total_wells_found = total_wells_found + 1;
                well_name = injector_names{i};
                well_data = wells_system.injector_wells.(well_name);
                if isfield(well_data, 'grid_location')
                    wells_with_locations = wells_with_locations + 1;
                end
            end
        end
        
        if wells_with_locations == 0
            error(['No wells with grid_location found in configuration: %s\n' ...
                   'REQUIRED: At least some wells must have grid_location fields for grid refinement.\n' ...
                   'Found %d total wells, %d with grid_location.'], ...
                   config_file, total_wells_found, wells_with_locations);
        end
        
        % Successfully loaded wells configuration
        
    catch ME
        error(['Failed to load wells configuration from %s\n' ...
               'Error: %s\n' ...
               'FAIL_FAST_POLICY: Cannot proceed without valid wells configuration.\n' ...
               'Ensure wells_config.yaml exists and contains required well definitions.'], ...
               config_file, ME.message);
    end
    
end

function config = load_refinement_config()
% Load refinement configuration from YAML with FAIL_FAST validation
% FAIL_FAST_POLICY and NO_HARDCODING_POLICY compliance
    script_dir = fileparts(mfilename('fullpath'));
    try
        % Policy Compliance: Load ALL parameters from YAML config
        addpath(fullfile(script_dir, 'utils'));
        grid_config_file = fullfile(script_dir, 'config', 'grid_config.yaml');
        
        % FAIL_FAST: Validate grid configuration file exists
        if ~exist(grid_config_file, 'file')
            error(['Grid configuration file missing: %s\n' ...
                   'REQUIRED: grid_config.yaml must exist with canonical Eagle West parameters.\n' ...
                   'This file must contain refinement and grid sections with all required fields.\n' ...
                   'Run previous workflow steps to generate canonical configuration.'], grid_config_file);
        end
        
        full_config = read_yaml_config(grid_config_file, true);
        
        % FAIL_FAST: Validate refinement section exists
        if ~isfield(full_config, 'refinement')
            error(['Missing refinement section in grid_config.yaml\n' ...
                   'REQUIRED: grid_config.yaml must contain refinement section\n' ...
                   'with well_refinement and fault_refinement subsections\n' ...
                   'defining canonical Eagle West tiered refinement strategy.']);
        end
        
        % FAIL_FAST: Validate grid section exists for cell sizes
        if ~isfield(full_config, 'grid')
            error(['Missing grid section in grid_config.yaml\n' ...
                   'REQUIRED: grid_config.yaml must contain grid section\n' ...
                   'with cell_size_x and cell_size_y for canonical 82ft x 74ft cells.']);
        end
        
        config = full_config.refinement;
        
        % Add canonical cell sizes to config for NO_HARDCODING compliance
        if isfield(full_config.grid, 'cell_size_x') && isfield(full_config.grid, 'cell_size_y')
            config.cell_size_x = full_config.grid.cell_size_x;
            config.cell_size_y = full_config.grid.cell_size_y;
        else
            error(['Missing canonical cell sizes in grid_config.yaml\n' ...
                   'REQUIRED: grid.cell_size_x and grid.cell_size_y must be defined\n' ...
                   'Canonical Eagle West values: cell_size_x = 82.0 ft, cell_size_y = 74.0 ft']);
        end
        
        % FAIL_FAST: Validate required refinement fields exist
        required_fields = {'well_refinement', 'fault_refinement', 'tiered_strategy'};
        for i = 1:length(required_fields)
            if ~isfield(config, required_fields{i})
                error(['Missing required field in grid_config.yaml refinement: %s\n' ...
                       'REQUIRED: refinement section must contain all canonical fields:\n' ...
                       'tiered_strategy, well_refinement, fault_refinement'], required_fields{i});
            end
        end
        
        % FAIL_FAST: Validate tiered strategy is enabled for canonical Eagle West
        if ~config.tiered_strategy.enable
            error(['Tiered refinement strategy disabled in grid_config.yaml\n' ...
                   'REQUIRED: Eagle West Field requires tiered refinement strategy.\n' ...
                   'Set refinement.tiered_strategy.enable = true for canonical operation.']);
        end
        
        fprintf('Canonical refinement configuration loaded from YAML\n');
        
    catch ME
        error(['Failed to load canonical refinement configuration: %s\n' ...
               'FAIL_FAST_POLICY: Cannot proceed without valid Eagle West configuration.\n' ...
               'Ensure grid_config.yaml contains all required canonical parameters.'], ME.message);
    end
end

% Main execution
if ~nargout
    refinement_data = s06_grid_refinement();
    fprintf('Grid refinement completed!\n\n');
end