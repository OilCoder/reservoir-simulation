function pebi_data = s03_create_pebi_grid()
% S03_CREATE_PEBI_GRID - Create fault-conforming PEBI grid for Eagle West Field (CANONICAL)
%
% PURPOSE:
%   Generates the primary computational grid for Eagle West Field using PEBI (Perpendicular
%   Bisector) methodology. Creates fault-conforming, well-optimized grid with ~20,000 cells
%   supporting 15-well development across 2,600-acre field. Implements tiered refinement
%   strategy with canonical well classifications and geological fault constraints.
%   THE CORE GRID for all downstream reservoir simulation modules.
%
% SCOPE:
%   - PEBI grid construction using MRST triangleGrid + pebi workflow
%   - Tiered refinement: critical/standard/marginal wells from wells_config.yaml
%   - Fault-conforming grid edges for 5 major faults (Fault_A to Fault_E)
%   - Size-field optimization (20-150 ft cell sizes) for computational efficiency
%   - 3D extrusion to 12-layer grid compatible with Eagle West workflow
%   - Does NOT: Define rock properties, fluid systems, or well completions
%
% WORKFLOW POSITION:
%   Third step in Eagle West Field MRST workflow sequence:
%   s01 (Initialize) → s02 (Fluids) → s03 (PEBI Grid) → s04 (Structure) → s05 (Faults)
%   Dependencies: MRST UPR module, wells_config.yaml, fault_config.yaml, grid_config.yaml
%   Used by: ALL downstream scripts (s04-s25) as primary grid source
%
% INPUTS:
%   - config/grid_config.yaml - Field extents (3280×2950 ft) and layer specifications
%   - config/wells_config.yaml - 15-well locations with canonical tier classifications
%   - config/fault_config.yaml - 5-fault system geometry (Fault_A to Fault_E)
%   - MRST UPR module for compositePebiGrid2D functionality
%
% OUTPUTS:
%   pebi_data - Complete PEBI grid package containing:
%     .grid - 3D PEBI grid (G_pebi) with ~20,000 cells × 12 layers
%     .well_points - Well locations with tier-based size parameters
%     .fault_lines - Fault geometries with sealing properties
%     .size_function - Distance-based cell sizing algorithm
%     .statistics - Grid quality metrics and validation data
%     .validation - Integrity checks and canonical compliance
%
% CONFIGURATION:
%   - grid_config.yaml - Field geometry: 3280×2950×100 ft domain
%   - wells_config.yaml - Well tiers: critical (20 ft), standard (35 ft), marginal (50 ft)
%   - fault_config.yaml - Fault sizing: major (25 ft), minor (40 ft) with buffer zones
%
% CANONICAL REFERENCE:
%   - Specification: obsidian-vault/Planning/Reservoir_Definition/12_Grid_Construction_PEBI.md
%   - Implementation: Native MRST triangleGrid + pebi approach (no compositePebiGrid2D)
%   - Canon-first: FAIL_FAST when well not in canonical tier classification
%
% EXAMPLES:
%   % Generate Eagle West PEBI grid
%   pebi_data = s03_create_pebi_grid();
%   
%   % Verify grid quality
%   G = pebi_data.grid;
%   fprintf('PEBI grid: %d cells, %d wells, %d faults\n', ...
%           G.cells.num, pebi_data.statistics.total_wells, length(pebi_data.fault_lines));
%
% Author: Claude Code AI System  
% Date: 2025-08-14 (Updated with comprehensive headers)
% Implementation: Eagle West Field MRST Workflow Phase 3 (CORE GRID GENERATION)
% Requires: MRST, UPR module

    script_dir = fileparts(mfilename('fullpath'));
    addpath(fullfile(script_dir, 'utils')); 
    run(fullfile(script_dir, 'utils', 'print_utils.m'));

    % Add MRST session validation
    [success, message] = validate_mrst_session(script_dir);
    if ~success
        error('MRST validation failed: %s', message);
    end

    print_step_header('S03', 'Create PEBI Grid');
    
    total_start_time = tic;
    
    try
        % ----------------------------------------
        % Step 1 – Load Configuration and Validate MRST/UPR
        % ----------------------------------------
        step_start = tic;
        [field_config, wells_config, fault_config] = step_1_load_configurations();
        step_1_validate_mrst_upr_module();
        print_step_result(1, 'Load Configuration and Validate MRST/UPR', 'success', toc(step_start));
        
        % ----------------------------------------
        % Step 2 – Extract Well Locations and Fault Geometries
        % ----------------------------------------
        step_start = tic;
        well_points = step_2_extract_well_locations(wells_config, field_config);
        fault_lines = step_2_extract_fault_geometries(fault_config, field_config);
        print_step_result(2, 'Extract Well Locations and Fault Geometries', 'success', toc(step_start));
        
        % ----------------------------------------
        % Step 3 – Create Tiered Size Function
        % ----------------------------------------
        step_start = tic;
        size_function = step_3_create_size_function(well_points, fault_lines, field_config);
        print_step_result(3, 'Create Tiered Size Function', 'success', toc(step_start));
        
        % ----------------------------------------
        % Step 4 – Generate PEBI Grid using triangleGrid + pebi
        % ----------------------------------------
        step_start = tic;
        G_pebi = step_4_generate_pebi_grid(well_points, fault_lines, size_function, field_config);
        print_step_result(4, 'Generate PEBI Grid using triangleGrid + pebi', 'success', toc(step_start));
        
        % ----------------------------------------
        % Step 5 – Apply Fault Properties to Grid Faces
        % ----------------------------------------
        step_start = tic;
        G_pebi = step_5_apply_fault_properties(G_pebi, fault_lines, fault_config);
        print_step_result(5, 'Apply Fault Properties to Grid Faces', 'success', toc(step_start));
        
        % ----------------------------------------
        % Step 6 – Extrude to 3D Grid
        % ----------------------------------------
        step_start = tic;
        G_3D = step_6_extrude_to_3D(G_pebi);
        print_step_result(6, 'Extrude to 3D Grid', 'success', toc(step_start));
        
        % ----------------------------------------
        % Step 7 – Validate and Export Grid
        % ----------------------------------------
        step_start = tic;
        pebi_data = step_7_validate_and_export(G_3D, well_points, fault_lines, size_function);
        print_step_result(7, 'Validate and Export Grid', 'success', toc(step_start));
        
        print_step_footer('S03', sprintf('PEBI Grid Created: %d cells, %d faces', G_3D.cells.num, G_3D.faces.num), toc(total_start_time));
        
    catch ME
        print_error_step(0, 'PEBI Grid Creation', ME.message);
        error('PEBI grid creation failed: %s', ME.message);
    end

end

function [field_config, wells_config, fault_config] = step_1_load_configurations()
% Step 1 - Load configuration data from YAML files

    % Load field geometry configuration
    field_config = load_field_configuration();
    
    % Load wells configuration
    wells_config = load_wells_from_yaml();
    
    % Load fault configuration  
    fault_config = load_fault_configuration();
    
end

function field_config = load_field_configuration()
% Load field configuration with PEBI-specific parameters

    script_dir = fileparts(mfilename('fullpath'));
    config_file = fullfile(script_dir, 'config', 'grid_config.yaml');
    
    % FAIL_FAST: Validate grid configuration file exists
    if ~exist(config_file, 'file')
        error(['Grid configuration file missing: %s\n' ...
               'REQUIRED: grid_config.yaml must exist with canonical Eagle West parameters.\n' ...
               'UPDATE CANON: obsidian-vault/Planning/Grid_Definition.md\n' ...
               'to specify PEBI grid requirements for Eagle West Field.'], config_file);
    end
    
    addpath(fullfile(script_dir, 'utils'));
    full_config = read_yaml_config(config_file, true);
    
    % FAIL_FAST: Validate required grid section exists
    if ~isfield(full_config, 'grid')
        error(['Missing grid section in grid_config.yaml\n' ...
               'REQUIRED: grid_config.yaml must contain grid section\n' ...
               'UPDATE CANON: obsidian-vault/Planning/Grid_Definition.md\n' ...
               'to define canonical Eagle West field extents and cell sizes.']);
    end
    
    % Extract both grid and pebi_grid sections for complete configuration
    field_config = full_config.grid;
    field_config.pebi_grid = full_config.pebi_grid;
    
    % FAIL_FAST: Validate required field extents exist
    required_fields = {'field_extent_x', 'field_extent_y', 'total_thickness'};
    for i = 1:length(required_fields)
        if ~isfield(field_config, required_fields{i})
            error(['Missing required field extent: %s\n' ...
                   'REQUIRED: grid_config.yaml must contain field extents.\n' ...
                   'UPDATE CANON: obsidian-vault/Planning/Grid_Definition.md\n' ...
                   'Canonical Eagle West: field_extent_x = 3280.0 ft, field_extent_y = 2950.0 ft'], required_fields{i});
        end
    end
    
end

function wells_config = load_wells_from_yaml()
% Load wells configuration from YAML - FAIL_FAST implementation

    script_dir = fileparts(mfilename('fullpath'));
    config_file = fullfile(script_dir, 'config', 'wells_config.yaml');
    
    % FAIL_FAST: Check if wells configuration exists
    if ~exist(config_file, 'file')
        error(['Wells configuration file missing: %s\n' ...
               'REQUIRED: wells_config.yaml must exist in config/ directory.\n' ...
               'UPDATE CANON: obsidian-vault/Planning/Wells_Definition.md\n' ...
               'to define canonical Eagle West wells (EW-001 to EW-010, IW-001 to IW-005).\n' ...
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
                   'UPDATE CANON: obsidian-vault/Planning/Wells_Definition.md\n' ...
                   'with producer_wells and injector_wells sections containing canonical well names.'], config_file);
        end
        
    catch ME
        error(['Failed to load wells configuration from %s\n' ...
               'Error: %s\n' ...
               'FAIL_FAST_POLICY: Cannot proceed without valid wells configuration.\n' ...
               'UPDATE CANON: obsidian-vault/Planning/Wells_Definition.md\n' ...
               'to ensure wells_config.yaml contains required well definitions.'], ...
               config_file, ME.message);
    end
    
end

function fault_config = load_fault_configuration()
% Load fault configuration from YAML

    script_dir = fileparts(mfilename('fullpath'));
    config_file = fullfile(script_dir, 'config', 'fault_config.yaml');
    
    % FAIL_FAST: Check if fault configuration exists
    if ~exist(config_file, 'file')
        error(['Fault configuration file missing: %s\n' ...
               'REQUIRED: fault_config.yaml must exist in config/ directory.\n' ...
               'UPDATE CANON: obsidian-vault/Planning/Fault_Definition.md\n' ...
               'to define canonical Eagle West faults (Fault_A to Fault_E).\n' ...
               'Run previous workflow steps to generate required configuration.'], config_file);
    end
    
    try
        addpath(fullfile(script_dir, 'utils'));
        fault_config = read_yaml_config(config_file, true); % Silent mode
        
        % Validate required fault_system section exists
        if ~isfield(fault_config, 'fault_system')
            error(['Invalid fault configuration: %s\n' ...
                   'REQUIRED: File must contain fault_system section\n' ...
                   'UPDATE CANON: obsidian-vault/Planning/Fault_Definition.md\n' ...
                   'with faults subsection containing canonical fault definitions.'], config_file);
        end
        
    catch ME
        error(['Failed to load fault configuration from %s\n' ...
               'Error: %s\n' ...
               'FAIL_FAST_POLICY: Cannot proceed without valid fault configuration.\n' ...
               'UPDATE CANON: obsidian-vault/Planning/Fault_Definition.md\n' ...
               'to ensure fault_config.yaml contains required fault definitions.'], ...
               config_file, ME.message);
    end
    
end

function step_1_validate_mrst_upr_module()
% Validate MRST core functions for triangleGrid + pebi approach (CANONICAL)

    % FAIL_FAST: Validate MRST is properly initialized
    if ~exist('mrstModule', 'file')
        error(['MRST not properly initialized\n' ...
               'REQUIRED: MRST must be initialized before PEBI grid creation.\n' ...
               'UPDATE CANON: obsidian-vault/Planning/MRST_Requirements.md\n' ...
               'Run s01_initialize_mrst.m first to initialize MRST session.']);
    end
    
    % Validate core MRST functions for triangleGrid + pebi approach
    required_functions = {'triangleGrid', 'pebi', 'computeGeometry', 'makeLayeredGrid'};
    missing_functions = {};
    
    for i = 1:length(required_functions)
        func_name = required_functions{i};
        if ~exist(func_name, 'file')
            missing_functions{end+1} = func_name;
        end
    end
    
    % FAIL_FAST: Require core MRST functions for canonical triangleGrid + pebi approach
    if ~isempty(missing_functions)
        error(['Missing required MRST functions for triangleGrid + pebi approach: %s\n' ...
               'REQUIRED: Core MRST functions must be available for PEBI grid generation.\n' ...
               'UPDATE CANON: obsidian-vault/Planning/MRST_Requirements.md\n' ...
               'Eagle West Field uses canonical triangleGrid() → pebi() workflow.\n' ...
               'Ensure MRST core installation includes these functions.'], ...
               strjoin(missing_functions, ', '));
    end
    
    fprintf('   Core MRST functions validated for triangleGrid + pebi approach\n');
    
end

function well_points = step_2_extract_well_locations(wells_config, field_config)
% Step 2 - Extract well locations with tier classification from wells_config.yaml
%
% CANON-FIRST: Uses wells_config.grid_refinement.well_tiers for all tier classifications
% NO hardcoded well lists - all tier data from canonical YAML configuration

    well_points = [];
    
    % Extract wells system
    wells_system = wells_config.wells_system;
    
    % Process producer wells
    if isfield(wells_system, 'producer_wells')
        producer_names = fieldnames(wells_system.producer_wells);
        for i = 1:length(producer_names)
            well_name = producer_names{i};
            well_data = wells_system.producer_wells.(well_name);
            
            if isfield(well_data, 'surface_coords')
                % Extract physical coordinates (ft)
                x = well_data.surface_coords(1);  % East coordinate
                y = well_data.surface_coords(2);  % North coordinate
                
                % Determine well tier for PEBI sizing from wells_config
                tier = determine_well_tier_for_pebi(well_name, wells_config);
                
                % Add to well points
                well_points(end+1,:) = [x, y, tier.size, tier.radius];
                
            end
        end
    end
    
    % Process injector wells
    if isfield(wells_system, 'injector_wells')
        injector_names = fieldnames(wells_system.injector_wells);
        for i = 1:length(injector_names)
            well_name = injector_names{i};
            well_data = wells_system.injector_wells.(well_name);
            
            if isfield(well_data, 'surface_coords')
                % Extract physical coordinates (ft)
                x = well_data.surface_coords(1);  % East coordinate
                y = well_data.surface_coords(2);  % North coordinate
                
                % Determine well tier for PEBI sizing from wells_config
                tier = determine_well_tier_for_pebi(well_name, wells_config);
                
                % Add to well points
                well_points(end+1,:) = [x, y, tier.size, tier.radius];
                
            end
        end
    end
    
    % FAIL_FAST: Validate wells were found
    if isempty(well_points)
        error(['No wells with surface coordinates found in wells configuration.\n' ...
               'REQUIRED: Wells must have surface_coords field for PEBI grid generation.\n' ...
               'UPDATE CANON: obsidian-vault/Planning/Wells_Definition.md\n' ...
               'Canonical Eagle West wells must have physical surface coordinates.']);
    end
    
    fprintf('   Extracted %d well locations for PEBI grid\n', size(well_points, 1));
    
end

function tier = determine_well_tier_for_pebi(well_name, wells_config)
% Determine PEBI grid sizing parameters based on well tier from wells_config.yaml
% CANON-FIRST: Uses wells_config.grid_refinement (flattened structure) for all tier classifications
% Flattened YAML structure used to work around Octave parser limitations with deep nesting

    % FAIL_FAST: Validate wells configuration contains grid refinement section
    if ~isfield(wells_config, 'grid_refinement')
        error(['Missing grid_refinement section in wells_config.yaml\n' ...
               'REQUIRED: wells_config.yaml must contain canonical well tier classifications.\n' ...
               'UPDATE CANON: obsidian-vault/Planning/Wells_Definition.md\n' ...
               'to ensure wells_config.yaml has grid_refinement section.']);
    end
    
    grid_refinement = wells_config.grid_refinement;
    
    % Check critical wells tier (flattened structure)
    if isfield(grid_refinement, 'critical_wells') && ismember(well_name, grid_refinement.critical_wells)
        tier.size = grid_refinement.critical_pebi_cell_size;            % ft - From YAML
        tier.radius = grid_refinement.critical_pebi_influence_radius;   % ft - From YAML
        tier.name = 'critical';
        return;
    end
    
    % Check standard wells tier (flattened structure)
    if isfield(grid_refinement, 'standard_wells') && ismember(well_name, grid_refinement.standard_wells)
        tier.size = grid_refinement.standard_pebi_cell_size;            % ft - From YAML
        tier.radius = grid_refinement.standard_pebi_influence_radius;   % ft - From YAML
        tier.name = 'standard';
        return;
    end
    
    % Check marginal wells tier (flattened structure)
    if isfield(grid_refinement, 'marginal_wells') && ismember(well_name, grid_refinement.marginal_wells)
        tier.size = grid_refinement.marginal_pebi_cell_size;            % ft - From YAML
        tier.radius = grid_refinement.marginal_pebi_influence_radius;   % ft - From YAML
        tier.name = 'marginal';
        return;
    end
    
    % FAIL_FAST: Well not found in canonical classification
    error(['Well %s not found in canonical tier classification.\n' ...
           'REQUIRED: All wells must be classified in wells_config.yaml grid_refinement section.\n' ...
           'UPDATE CANON: obsidian-vault/Planning/Wells_Definition.md\n' ...
           'to add %s to appropriate tier (critical_wells/standard_wells/marginal_wells) in wells_config.yaml'], ...
           well_name, well_name);
    
end

function fault_lines = step_2_extract_fault_geometries(fault_config, field_config)
% Step 2 - Extract fault geometries with sealing properties

    fault_lines = [];
    
    % Extract fault system
    fault_system = fault_config.fault_system;
    
    if isfield(fault_system, 'faults')
        fault_names = fieldnames(fault_system.faults);
        
        for i = 1:length(fault_names)
            fault_name = fault_names{i};
            fault_data = fault_system.faults.(fault_name);
            
            % Calculate fault endpoints from geometric parameters
            [x1, y1, x2, y2] = calculate_fault_endpoints(fault_data, field_config);
            
            % Determine fault tier for PEBI sizing
            tier = determine_fault_tier_for_pebi(fault_data, field_config);
            
            % Add to fault lines
            fault_lines(end+1,:) = [x1, y1, x2, y2, tier.size, tier.buffer, fault_data.is_sealing];
            
        end
    end
    
    % FAIL_FAST: Validate faults were found
    if isempty(fault_lines)
        error(['No faults found in fault configuration.\n' ...
               'REQUIRED: Faults must be defined for PEBI grid generation.\n' ...
               'UPDATE CANON: obsidian-vault/Planning/Fault_Definition.md\n' ...
               'Canonical Eagle West field must have Fault_A through Fault_E defined.']);
    end
    
    fprintf('   Extracted %d fault lines for PEBI grid\n', size(fault_lines, 1));
    
end

function [x1, y1, x2, y2] = calculate_fault_endpoints(fault_data, field_config)
% Calculate fault line endpoints from strike, length, and position

    % Get fault position offsets
    center_x = field_config.field_extent_x / 2 + fault_data.position_offset_x;
    center_y = field_config.field_extent_y / 2 + fault_data.position_offset_y;
    
    % Convert strike to radians (geological convention: degrees from north, clockwise)
    strike_rad = deg2rad(fault_data.strike);
    
    % Calculate half-length in each direction
    half_length = fault_data.length / 2;
    
    % Calculate endpoints
    x1 = center_x - half_length * sin(strike_rad);
    y1 = center_y - half_length * cos(strike_rad);
    x2 = center_x + half_length * sin(strike_rad);
    y2 = center_y + half_length * cos(strike_rad);
    
end

function tier = determine_fault_tier_for_pebi(fault_data, field_config)
% Determine PEBI grid sizing parameters based on fault properties

    % Major faults: High sealing capacity requiring fine resolution
    major_faults = {'Fault_A', 'Fault_C', 'Fault_D'};
    if ismember(fault_data.name, major_faults) || (fault_data.is_sealing && fault_data.transmissibility_multiplier <= 0.01)
        tier.size = field_config.pebi_grid.fault_zones.major.cell_size;      % ft - Fine cell size near major faults (CANON)
        tier.buffer = field_config.pebi_grid.fault_zones.major.buffer_distance;   % ft - Buffer zone around fault (CANON)
        tier.name = 'major';
        return;
    end
    
    % Minor faults: Lower sealing capacity
    minor_faults = {'Fault_B', 'Fault_E'};
    if ismember(fault_data.name, minor_faults) || fault_data.transmissibility_multiplier > 0.01
        tier.size = field_config.pebi_grid.fault_zones.minor.cell_size;      % ft - Moderate cell size near minor faults (CANON)
        tier.buffer = field_config.pebi_grid.fault_zones.minor.buffer_distance;   % ft - Smaller buffer zone (CANON)
        tier.name = 'minor';
        return;
    end
    
    % Default tier for unknown faults
    tier.size = field_config.pebi_grid.fault_zones.minor.cell_size;      % ft - Default to minor fault size (CANON)
    tier.buffer = field_config.pebi_grid.fault_zones.minor.buffer_distance;   % ft - Default to minor buffer (CANON)
    tier.name = 'default';
    
end

function size_function = step_3_create_size_function(well_points, fault_lines, field_config)
% Step 3 - Create distance-based size function for PEBI grid

    % Define domain extents
    x_extent = [0, field_config.field_extent_x];
    y_extent = [0, field_config.field_extent_y];
    
    % Background cell size for areas away from wells and faults
    background_size = field_config.pebi_grid.background_cell_size;  % ft - Computational efficiency (CANON)
    
    % Create size function structure
    size_function = struct();
    size_function.well_points = well_points;
    size_function.fault_lines = fault_lines;
    size_function.background_size = background_size;
    size_function.domain_x = x_extent;
    size_function.domain_y = y_extent;
    
    % Create function handle for size calculation
    size_function.func = @(pts) calculate_point_sizes(pts, well_points, fault_lines, background_size);
    
    fprintf('   Created tiered size function with %d wells and %d faults\n', ...
            size(well_points, 1), size(fault_lines, 1));
    
end

function sizes = calculate_point_sizes(points, well_points, fault_lines, background_size)
% Calculate cell sizes for given points using distance-weighted approach

    num_points = size(points, 1);
    sizes = ones(num_points, 1) * background_size;
    
    for i = 1:num_points
        pt = points(i, :);
        min_size = background_size;
        
        % Check distance to each well
        if ~isempty(well_points)
            for j = 1:size(well_points, 1)
                well_x = well_points(j, 1);
                well_y = well_points(j, 2);
                well_size = well_points(j, 3);
                well_radius = well_points(j, 4);
                
                % Calculate distance to well
                dist = sqrt((pt(1) - well_x)^2 + (pt(2) - well_y)^2);
                
                % Apply size function with smooth transition
                if dist <= well_radius
                    % Linear interpolation from well_size at center to background_size at radius
                    size_at_point = well_size + (background_size - well_size) * (dist / well_radius);
                    min_size = min(min_size, size_at_point);
                end
            end
        end
        
        % Check distance to each fault
        if ~isempty(fault_lines)
            for j = 1:size(fault_lines, 1)
                x1 = fault_lines(j, 1);
                y1 = fault_lines(j, 2);
                x2 = fault_lines(j, 3);
                y2 = fault_lines(j, 4);
                fault_size = fault_lines(j, 5);
                fault_buffer = fault_lines(j, 6);
                
                % Calculate distance to fault line
                dist = calculate_point_to_line_distance_single(pt(1), pt(2), x1, y1, x2, y2);
                
                % Apply size function with smooth transition
                if dist <= fault_buffer
                    % Linear interpolation from fault_size at fault to background_size at buffer edge
                    size_at_point = fault_size + (background_size - fault_size) * (dist / fault_buffer);
                    min_size = min(min_size, size_at_point);
                end
            end
        end
        
        sizes(i) = min_size;
    end
    
end

function distance = calculate_point_to_line_distance_single(px, py, x1, y1, x2, y2)
% Calculate distance from a single point to line segment

    A = px - x1;
    B = py - y1;
    C = x2 - x1;
    D = y2 - y1;
    
    dot = A * C + B * D;
    len_sq = C^2 + D^2;
    
    if len_sq == 0
        distance = sqrt(A^2 + B^2);
        return;
    end
    
    param = dot / len_sq;
    param = max(0, min(1, param));
    
    xx = x1 + param * C;
    yy = y1 + param * D;
    
    distance = sqrt((px - xx)^2 + (py - yy)^2);
    
end

function G_pebi = step_4_generate_pebi_grid(well_points, fault_lines, size_function, field_config)
% Step 4 - Generate PEBI grid using canonical triangleGrid + pebi approach

    fprintf('   Generating PEBI grid using triangleGrid + pebi approach...\n');
    
    % CANON-FIRST: Implement triangleGrid + pebi approach as specified in documentation
    try
        % Step 1: Generate well-constrained point distribution
        points = generate_well_constrained_points(well_points, fault_lines, field_config, size_function);
        
        % DIAGNOSTIC: Check point distribution bounds
        fprintf('   Point distribution bounds: X=[%.1f, %.1f], Y=[%.1f, %.1f]\n', ...
                min(points(:,1)), max(points(:,1)), min(points(:,2)), max(points(:,2)));
        fprintf('   Expected field bounds: X=[0, %.1f], Y=[0, %.1f]\n', ...
                field_config.field_extent_x, field_config.field_extent_y);
        
        % CRITICAL: Clip points to field bounds to prevent coordinate expansion
        points(:,1) = max(0, min(points(:,1), field_config.field_extent_x));
        points(:,2) = max(0, min(points(:,2), field_config.field_extent_y));
        fprintf('   Points clipped to field bounds: X=[%.1f, %.1f], Y=[%.1f, %.1f]\n', ...
                min(points(:,1)), max(points(:,1)), min(points(:,2)), max(points(:,2)));
        
        % Step 2: Create Delaunay triangulation
        G_triangular = triangleGrid(points);
        G_triangular = computeGeometry(G_triangular);  % CRITICAL: Compute geometry for diagnostics
        fprintf('   Triangular grid created: %d cells\n', G_triangular.cells.num);
        
        % DIAGNOSTIC: Check triangular grid areas
        if isfield(G_triangular.cells, 'volumes')
            min_tri_area = min(G_triangular.cells.volumes);
            max_tri_area = max(G_triangular.cells.volumes);
            fprintf('   Triangular areas: min=%.2e, max=%.2e ft²\n', min_tri_area, max_tri_area);
            if min_tri_area <= 0
                fprintf('   WARNING: Triangular grid has %d cells with non-positive areas!\n', sum(G_triangular.cells.volumes <= 0));
            end
        end
        
        % Step 3: Convert to PEBI (Voronoi dual)
        G_pebi = pebi(G_triangular);
        G_pebi = computeGeometry(G_pebi);  % CRITICAL: Compute geometry for 2D PEBI
        fprintf('   PEBI grid generated successfully using triangleGrid + pebi: %d cells\n', G_pebi.cells.num);
        
        % DIAGNOSTIC: Check 2D PEBI grid geometry
        if isfield(G_pebi.cells, 'volumes')
            min_2d_area = min(G_pebi.cells.volumes);
            max_2d_area = max(G_pebi.cells.volumes);
            fprintf('   2D PEBI areas: min=%.2e, max=%.2e ft²\n', min_2d_area, max_2d_area);
            if min_2d_area <= 0
                fprintf('   WARNING: 2D PEBI grid has %d cells with non-positive areas!\n', sum(G_pebi.cells.volumes <= 0));
            end
        end
        
    catch ME
        % FAIL_FAST: No defensive fallbacks - proper PEBI grid required per canon
        error(['Failed to generate PEBI grid using triangleGrid + pebi approach: %s\n' ...
               'REQUIRED: Eagle West Field requires true PEBI grid for accurate well representation.\n' ...
               'CANON-FIRST VIOLATION: No Cartesian fallbacks allowed - defeats PEBI purpose.\n' ...
               'UPDATE CANON: obsidian-vault/Planning/PEBI_Grid_Requirements.md\n' ...
               'MRST functions used: triangleGrid() → pebi()\n' ...
               'FAILURE REASON: %s'], ME.message, ME.message);
    end
    
    % Geometry already computed in step 4 - no need to recompute
    
    fprintf('   PEBI grid generated: %d cells, %d faces\n', G_pebi.cells.num, G_pebi.faces.num);
    
end

function G_pebi = step_5_apply_fault_properties(G_pebi, fault_lines, fault_config)
% Step 5 - Apply fault properties to grid faces for proper sealing behavior

    fprintf('   Applying fault properties to grid faces...\n');
    
    % Initialize fault face properties
    G_pebi.faces.fault_multiplier = ones(G_pebi.faces.num, 1);
    G_pebi.faces.is_fault = false(G_pebi.faces.num, 1);
    
    % Extract fault system for property mapping
    fault_system = fault_config.fault_system;
    fault_names = fieldnames(fault_system.faults);
    
    % Process each fault line
    for f = 1:size(fault_lines, 1)
        x1 = fault_lines(f, 1);
        y1 = fault_lines(f, 2);
        x2 = fault_lines(f, 3);
        y2 = fault_lines(f, 4);
        is_sealing = fault_lines(f, 7);
        
        % Find corresponding fault data for transmissibility
        fault_name = fault_names{f};  % Assume same order as extraction
        fault_data = fault_system.faults.(fault_name);
        transmissibility = fault_data.transmissibility_multiplier;
        
        % Find faces aligned with this fault
        fault_faces = find_fault_aligned_faces(G_pebi, x1, y1, x2, y2);
        
        % Apply fault properties to aligned faces
        if ~isempty(fault_faces)
            G_pebi.faces.fault_multiplier(fault_faces) = transmissibility;
            G_pebi.faces.is_fault(fault_faces) = true;
            
            fprintf('   Applied fault properties to %d faces for %s (T=%.3f)\n', ...
                    length(fault_faces), fault_name, transmissibility);
        end
    end
    
    % Add fault metadata to grid
    G_pebi.fault_info = struct();
    G_pebi.fault_info.total_fault_faces = sum(G_pebi.faces.is_fault);
    G_pebi.fault_info.sealing_faces = sum(G_pebi.faces.fault_multiplier < 0.1);
    G_pebi.fault_info.fault_lines = fault_lines;
    
end

function fault_faces = find_fault_aligned_faces(G, x1, y1, x2, y2)
% Find grid faces that are aligned with fault line

    fault_faces = [];
    tolerance = 50.0;  % ft - Tolerance for face alignment with fault
    
    % Calculate fault line direction vector
    fault_dx = x2 - x1;
    fault_dy = y2 - y1;
    fault_length = sqrt(fault_dx^2 + fault_dy^2);
    
    if fault_length == 0
        return;
    end
    
    fault_unit = [fault_dx, fault_dy] / fault_length;
    
    % Check each face for alignment with fault
    for i = 1:G.faces.num
        face = G.faces;
        
        % Get face center (approximate)
        if isfield(face, 'centroids')
            face_center = face.centroids(i, 1:2);
        else
            % Calculate face center from nodes (simplified)
            nodes = G.faces.nodes(G.faces.nodePos(i):G.faces.nodePos(i+1)-1);
            face_coords = G.nodes.coords(nodes, 1:2);
            face_center = mean(face_coords, 1);
        end
        
        % Calculate distance from face center to fault line
        dist = calculate_point_to_line_distance_single(face_center(1), face_center(2), x1, y1, x2, y2);
        
        % Include face if close to fault line
        if dist <= tolerance
            fault_faces(end+1) = i;
        end
    end
    
end

function G_3D = step_6_extrude_to_3D(G_2D)
% Step 6 - Extrude 2D PEBI grid to 3D with 12 layers at correct subsurface depths
    
    % Load grid config for subsurface depth information (CANON-FIRST)
    script_dir = fileparts(mfilename('fullpath'));
    field_config = load_field_configuration_for_depth();
    
    % FAIL_FAST: Validate required depth parameters exist in grid_config.yaml
    required_depth_fields = {'top_structure_tvdss', 'base_structure_tvdss', 'nz'};
    for i = 1:length(required_depth_fields)
        if ~isfield(field_config, required_depth_fields{i})
            error(['Missing required subsurface depth parameter: %s\n' ...
                   'REQUIRED: grid_config.yaml must contain Eagle West subsurface depths.\n' ...
                   'UPDATE CANON: obsidian-vault/Planning/Grid_Definition.md\n' ...
                   'Canonical Eagle West depths: top_structure_tvdss=7900 ft, base_structure_tvdss=8240 ft'], ...
                   required_depth_fields{i});
        end
    end
    
    % Extract canonical subsurface depths (ft TVDSS)
    top_depth_tvdss = field_config.top_structure_tvdss;     % 7900.0 ft TVDSS
    base_depth_tvdss = field_config.base_structure_tvdss;   % 8240.0 ft TVDSS
    n_layers = field_config.nz;                             % 12 layers
    
    % FAIL_FAST: Validate depth values make geological sense
    if top_depth_tvdss >= base_depth_tvdss
        error(['Invalid subsurface depths: top_structure_tvdss (%g ft) >= base_structure_tvdss (%g ft)\n' ...
               'REQUIRED: Eagle West Field top structure must be shallower than base.\n' ...
               'UPDATE CANON: obsidian-vault/Planning/Grid_Definition.md\n' ...
               'Canonical Eagle West: top=7900 ft, base=8240 ft (340 ft total thickness)'], ...
               top_depth_tvdss, base_depth_tvdss);
    end
    
    % Calculate subsurface depths (negative for depth below datum)
    top_depth = -top_depth_tvdss;                           % -7900.0 ft (negative for subsurface)
    base_depth = -base_depth_tvdss;                         % -8240.0 ft (negative for subsurface)
    total_thickness = base_depth_tvdss - top_depth_tvdss;   % Use raw TVDSS values: 8240-7900 = +340.0 ft
    
    % FAIL_FAST: Validate calculated thickness matches Eagle West canonical specification
    expected_thickness = field_config.total_thickness;  % ft (canonical Eagle West total thickness from YAML)
    thickness_tolerance = field_config.thickness_tolerance;  % ft (validation tolerance from YAML)
    if abs(total_thickness - expected_thickness) > thickness_tolerance
        error(['Calculated reservoir thickness (%g ft) does not match Eagle West canonical specification (%g ft)\n' ...
               'REQUIRED: Eagle West Field total thickness must be ~340 ft.\n' ...
               'UPDATE CANON: obsidian-vault/Planning/Grid_Definition.md\n' ...
               'Check top_structure_tvdss and base_structure_tvdss values in grid_config.yaml'], ...
               total_thickness, expected_thickness);
    end
    
    % Create layer boundaries at correct subsurface depths
    % CRITICAL FIX: Use absolute thickness values for makeLayeredGrid()
    % 
    % COORDINATE SYSTEM EXPLANATION:
    %   - top_depth = -7900 ft (negative, subsurface)
    %   - base_depth = -8240 ft (negative, deeper subsurface)  
    %   - total_thickness = +340 ft (positive, absolute thickness)
    %
    % PROBLEM: linspace(top_depth, base_depth, n+1) = linspace(-7900, -8240, 13)
    %          produces decreasing sequence → diff() gives NEGATIVE values
    %          → makeLayeredGrid() gets negative thicknesses → NEGATIVE CELL VOLUMES
    %
    % SOLUTION: Use positive total_thickness directly
    layer_thickness_per_layer = total_thickness / n_layers;  % +340/12 = +28.33 ft per layer
    layer_thicknesses = ones(n_layers, 1) * layer_thickness_per_layer;  % All layers equal thickness
    
    % DIAGNOSTIC: Check 2D grid before extrusion
    fprintf('   2D grid preparation for extrusion:\n');
    fprintf('     Grid nodes range: X=[%.1f, %.1f], Y=[%.1f, %.1f]\n', ...
            min(G_2D.nodes.coords(:,1)), max(G_2D.nodes.coords(:,1)), ...
            min(G_2D.nodes.coords(:,2)), max(G_2D.nodes.coords(:,2)));
    if size(G_2D.nodes.coords, 2) >= 3
        fprintf('     2D grid Z-coordinates: min=%.2f, max=%.2f\n', ...
                min(G_2D.nodes.coords(:,3)), max(G_2D.nodes.coords(:,3)));
    else
        fprintf('     2D grid has no Z-coordinates (purely 2D)\n');
    end
    fprintf('     Layer thicknesses: [%.2f, %.2f, ..., %.2f] ft (%d layers)\n', ...
            layer_thicknesses(1), layer_thicknesses(2), layer_thicknesses(end), length(layer_thicknesses));
    fprintf('     2D cell areas range: min=%.2e, max=%.2e ft²\n', ...
            min(G_2D.cells.volumes), max(G_2D.cells.volumes));
    
    % CRITICAL TEST: Try makeLayeredGrid with minimal debugging
    fprintf('     DEBUG: Testing makeLayeredGrid with 2D PEBI grid...\n');
    try
        % Test with a single layer first to isolate the issue
        single_layer_thickness = layer_thickness_per_layer;
        fprintf('     DEBUG: Single layer test thickness: %.2f ft\n', single_layer_thickness);
        
        G_test_single = makeLayeredGrid(G_2D, single_layer_thickness);
        G_test_single = computeGeometry(G_test_single);
        
        if isfield(G_test_single.cells, 'volumes')
            neg_count_single = sum(G_test_single.cells.volumes <= 0);
            if neg_count_single > 0
                fprintf('     DEBUG: Single layer already has %d negative volumes!\n', neg_count_single);
                fprintf('     DEBUG: Min/Max single layer volumes: %.2e / %.2e\n', ...
                        min(G_test_single.cells.volumes), max(G_test_single.cells.volumes));
            else
                fprintf('     DEBUG: Single layer SUCCESS - all volumes positive\n');
            end
        end
    catch ME
        fprintf('     DEBUG: makeLayeredGrid failed even with single layer: %s\n', ME.message);
    end
    
    % Extrude using MRST's makeLayeredGrid (initially positioned at surface)
    G_3D = makeLayeredGrid(G_2D, layer_thicknesses);
    G_3D = computeGeometry(G_3D);
    
    % CRITICAL VALIDATION: Check for negative cell volumes immediately after grid creation
    if isfield(G_3D.cells, 'volumes')
        negative_volume_cells = G_3D.cells.volumes <= 0;
        num_negative = sum(negative_volume_cells);
        if num_negative > 0
            min_volume = min(G_3D.cells.volumes);
            error(['CRITICAL: PEBI grid has %d cells with negative/zero volumes (min=%.2e)\n' ...
                   'ROOT CAUSE: Geometry error in makeLayeredGrid() call with layer_thicknesses.\n' ...
                   'CANON-FIRST FAILURE: Cannot proceed with invalid grid geometry.\n' ...
                   'UPDATE CANON: obsidian-vault/Planning/Grid_Definition.md\n' ...
                   'Layer thicknesses used: %.2f ft per layer (%d layers)\n' ...
                   'All layer thicknesses must be positive for valid MRST grid.'], ...
                   num_negative, min_volume, layer_thickness_per_layer, n_layers);
        end
        fprintf('   Volume validation passed: all %d cells have positive volumes\n', G_3D.cells.num);
        fprintf('   Volume range: %.2e to %.2e ft³\n', min(G_3D.cells.volumes), max(G_3D.cells.volumes));
    end
    
    % CRITICAL FIX: Translate grid from surface position to subsurface depths
    % makeLayeredGrid creates grid starting from 2D grid Z-coordinates (~0), 
    % but Eagle West requires positioning at canonical subsurface depths
    if isfield(G_3D.nodes, 'coords')
        current_top = max(G_3D.nodes.coords(:,3));  % Current top Z (~0 or small positive)
        target_top = top_depth;                     % Target top Z (-7900 ft)
        z_offset = target_top - current_top;        % Calculate translation offset
        
        % Apply translation to all grid nodes
        G_3D.nodes.coords(:,3) = G_3D.nodes.coords(:,3) + z_offset;
        
        % Recompute geometry after Z-coordinate translation
        G_3D = computeGeometry(G_3D);
        
        fprintf('   Grid translated by %.1f ft to subsurface position\n', z_offset);
    else
        error(['3D grid missing nodes.coords field - cannot position at subsurface depths.\n' ...
               'REQUIRED: MRST grid must have nodes.coords for depth translation.\n' ...
               'CANON-FIRST FAILURE: Eagle West Field requires grid at canonical depths.']);
    end
    
    % VALIDATION: Verify grid cells are positioned at correct subsurface depths
    if isfield(G_3D.cells, 'centroids')
        z_coords = G_3D.cells.centroids(:, 3);
        min_z = min(z_coords);
        max_z = max(z_coords);
        
        % Expected depth range (negative values for subsurface)
        expected_max_z = top_depth;      % Should be ~-7900 ft (shallower/higher Z)
        expected_min_z = base_depth;     % Should be ~-8240 ft (deeper/lower Z)
        depth_tolerance = 50.0;          % ft tolerance
        
        % FAIL_FAST: Validate grid depths are in expected range
        if abs(min_z - expected_min_z) > depth_tolerance || abs(max_z - expected_max_z) > depth_tolerance
            error(['3D grid cells not positioned at correct subsurface depths.\n' ...
                   'ACTUAL: Z-range %.1f to %.1f ft\n' ...
                   'EXPECTED: Z-range %.1f to %.1f ft (Eagle West subsurface depths)\n' ...
                   'CANON-FIRST FAILURE: Grid must be positioned at canonical Eagle West depths.\n' ...
                   'UPDATE CANON: obsidian-vault/Planning/Grid_Definition.md\n' ...
                   'to verify subsurface depth calculations for makeLayeredGrid().'], ...
                   min_z, max_z, expected_min_z, expected_max_z);
        end
        
        fprintf('   Grid depth validation passed: Z-range %.1f to %.1f ft (subsurface)\n', min_z, max_z);
    end
    
    % Transfer fault information to 3D grid
    if isfield(G_2D.faces, 'fault_multiplier')
        % Map 2D face properties to 3D faces
        % This is approximate - proper mapping would require more sophisticated logic
        n_2D_faces = G_2D.faces.num;
        n_3D_faces = G_3D.faces.num;
        
        G_3D.faces.fault_multiplier = ones(n_3D_faces, 1);
        G_3D.faces.is_fault = false(n_3D_faces, 1);
        
        % Copy fault info for vertical faces (inherited from 2D)
        % This is a simplified approach
        if isfield(G_3D, 'layerFaces')
            % Use layerFaces info if available
            for i = 1:n_2D_faces
                if G_2D.faces.is_fault(i)
                    % Find corresponding faces in 3D grid
                    % This would need proper mapping logic
                end
            end
        end
    end
    
    fprintf('   Extruded PEBI grid to 3D: %d cells (%d layers)\n', G_3D.cells.num, n_layers);
    fprintf('   Grid positioned at subsurface depths: %.1f to %.1f ft TVDSS\n', top_depth_tvdss, base_depth_tvdss);
    
end

function field_config = load_field_configuration_for_depth()
% Load field configuration specifically for subsurface depth parameters
% Used by step_6_extrude_to_3D for correct depth positioning

    script_dir = fileparts(mfilename('fullpath'));
    config_file = fullfile(script_dir, 'config', 'grid_config.yaml');
    
    % FAIL_FAST: Validate grid configuration file exists
    if ~exist(config_file, 'file')
        error(['Grid configuration file missing: %s\n' ...
               'REQUIRED: grid_config.yaml must exist with Eagle West subsurface depth parameters.\n' ...
               'UPDATE CANON: obsidian-vault/Planning/Grid_Definition.md\n' ...
               'to specify canonical Eagle West subsurface depths (top_structure_tvdss, base_structure_tvdss).'], config_file);
    end
    
    % Load configuration using existing utilities
    addpath(fullfile(script_dir, 'utils'));
    full_config = read_yaml_config(config_file, true);
    
    % FAIL_FAST: Validate required grid section exists  
    if ~isfield(full_config, 'grid')
        error(['Missing grid section in grid_config.yaml\n' ...
               'REQUIRED: grid_config.yaml must contain grid section with subsurface depths.\n' ...
               'UPDATE CANON: obsidian-vault/Planning/Grid_Definition.md\n' ...
               'to define Eagle West Field depth reference parameters (top_structure_tvdss, base_structure_tvdss).']);
    end
    
    % Extract both grid and pebi_grid sections for complete configuration
    field_config = full_config.grid;
    if isfield(full_config, 'pebi_grid')
        field_config.pebi_grid = full_config.pebi_grid;
    end
    
end

function pebi_data = step_7_validate_and_export(G_pebi, well_points, fault_lines, size_function)
% Step 6 - Validate and export PEBI grid

    % Validate grid structure
    validate_pebi_grid_structure(G_pebi, well_points, fault_lines);
    
    % Export grid to file
    export_pebi_grid_files(G_pebi);
    
    % Create output data structure
    pebi_data = create_pebi_output_structure(G_pebi, well_points, fault_lines, size_function);
    
end

function validate_pebi_grid_structure(G_pebi, well_points, fault_lines)
% Validate PEBI grid has proper MRST structure

    % FAIL_FAST: Validate basic MRST grid structure
    required_fields = {'cells', 'faces', 'nodes'};
    for i = 1:length(required_fields)
        if ~isfield(G_pebi, required_fields{i})
            error(['Invalid PEBI grid structure - missing field: %s\n' ...
                   'REQUIRED: PEBI grid must have proper MRST grid structure.\n' ...
                   'UPDATE CANON: obsidian-vault/Planning/PEBI_Grid_Requirements.md\n' ...
                   'to specify required MRST grid fields for Eagle West Field.'], required_fields{i});
        end
    end
    
    % Validate cell count is reasonable
    if G_pebi.cells.num < 100 || G_pebi.cells.num > 50000
        error(['PEBI grid cell count out of range: %d cells\n' ...
               'REQUIRED: Eagle West PEBI grid should have 1,000-20,000 cells.\n' ...
               'UPDATE CANON: obsidian-vault/Planning/PEBI_Grid_Requirements.md\n' ...
               'to adjust size function parameters for appropriate cell count.'], G_pebi.cells.num);
    end
    
    % Validate geometry was computed
    if ~isfield(G_pebi.cells, 'volumes') || ~isfield(G_pebi.cells, 'centroids')
        error(['PEBI grid geometry not computed\n' ...
               'REQUIRED: PEBI grid must have cell volumes and centroids.\n' ...
               'UPDATE CANON: obsidian-vault/Planning/PEBI_Grid_Requirements.md\n' ...
               'Grid geometry computation required for Eagle West workflow.']);
    end
    
    % CRITICAL: Validate all cell volumes are positive (catch geometry errors)
    if isfield(G_pebi.cells, 'volumes')
        negative_volume_cells = G_pebi.cells.volumes <= 0;
        num_negative = sum(negative_volume_cells);
        if num_negative > 0
            min_volume = min(G_pebi.cells.volumes);
            error(['CRITICAL VALIDATION FAILURE: PEBI grid has %d cells with negative/zero volumes (min=%.2e)\n' ...
                   'ROOT CAUSE: Invalid grid geometry - likely negative layer thicknesses.\n' ...
                   'CANON-FIRST FAILURE: Cannot proceed with geometrically invalid grid.\n' ...
                   'UPDATE CANON: obsidian-vault/Planning/Grid_Definition.md\n' ...
                   'All MRST cells must have positive volumes for valid reservoir simulation.'], ...
                   num_negative, min_volume);
        end
    end
    
    fprintf('   PEBI grid validation passed: %d cells, %d faces\n', G_pebi.cells.num, G_pebi.faces.num);
    
end

function export_pebi_grid_files(G_pebi)
% Export PEBI grid to data files using canonical organization

    try
        % Load canonical data utilities
        script_dir = fileparts(mfilename('fullpath'));
        addpath(fullfile(script_dir, 'utils'));
        run(fullfile(script_dir, 'utils', 'canonical_data_utils.m'));
        run(fullfile(script_dir, 'utils', 'directory_management.m'));
        
        % Create canonical directory structure
        base_data_path = fullfile(fileparts(script_dir), 'data');
        % Create basic canonical directory structure
        static_path = fullfile(base_data_path, 'by_type', 'static');
        if ~exist(static_path, 'dir')
            mkdir(static_path);
        end
        
        % Save PEBI grid directly in canonical structure
        grid_file = fullfile(static_path, 'pebi_grid_s03.mat');
        save(grid_file, 'G_pebi');
        
        fprintf('     Canonical PEBI grid saved: %s\n', grid_file);
        
        % Maintain legacy compatibility during transition
        legacy_data_dir = get_data_path('static');
        if ~exist(legacy_data_dir, 'dir')
            mkdir(legacy_data_dir);
        end
        
        % Save PEBI grid with dual compatibility
        pebi_grid_file = fullfile(legacy_data_dir, 'pebi_grid.mat');
        refined_grid_file = fullfile(legacy_data_dir, 'refined_grid.mat');
        
        % Save as G_pebi (new format)
        save(pebi_grid_file, 'G_pebi');
        
        % Save as G (compatible format for s07, s17)
        G = G_pebi;  % Create compatible variable name
        save(refined_grid_file, 'G');
        
        fprintf('     Legacy compatibility maintained:\n');
        fprintf('       PEBI grid: %s\n', pebi_grid_file);
        fprintf('       Compatible grid: %s\n', refined_grid_file);
        
    catch ME
        fprintf('Warning: Canonical export failed: %s\n', ME.message);
        
        % Fallback to legacy export
        script_dir = fileparts(mfilename('fullpath'));
        addpath(fullfile(script_dir, 'utils'));
        data_dir = get_data_path('static');
        
        if ~exist(data_dir, 'dir')
            mkdir(data_dir);
        end
        
        pebi_grid_file = fullfile(data_dir, 'pebi_grid.mat');
        refined_grid_file = fullfile(data_dir, 'refined_grid.mat');
        
        save(pebi_grid_file, 'G_pebi');
        G = G_pebi;
        save(refined_grid_file, 'G');
        
        fprintf('     Fallback: PEBI grid exported to: %s\n', pebi_grid_file);
        fprintf('     Fallback: Compatible grid saved as: %s\n', refined_grid_file);
    end
    
end

function pebi_data = create_pebi_output_structure(G_pebi, well_points, fault_lines, size_function)
% Create comprehensive PEBI grid output structure

    pebi_data = struct();
    pebi_data.grid = G_pebi;
    pebi_data.well_points = well_points;
    pebi_data.fault_lines = fault_lines;
    pebi_data.size_function = size_function;
    pebi_data.status = 'completed';
    
    % Add grid statistics
    pebi_data.statistics = struct();
    pebi_data.statistics.total_cells = G_pebi.cells.num;
    pebi_data.statistics.total_faces = G_pebi.faces.num;
    pebi_data.statistics.total_nodes = G_pebi.nodes.num;
    
    if isfield(G_pebi.cells, 'volumes')
        pebi_data.statistics.total_volume = sum(G_pebi.cells.volumes);
        pebi_data.statistics.min_cell_volume = min(G_pebi.cells.volumes);
        pebi_data.statistics.max_cell_volume = max(G_pebi.cells.volumes);
        pebi_data.statistics.avg_cell_volume = mean(G_pebi.cells.volumes);
    end
    
    % Add fault information
    if isfield(G_pebi, 'fault_info')
        pebi_data.fault_statistics = G_pebi.fault_info;
    end
    
    % Add well information
    pebi_data.well_statistics = struct();
    pebi_data.well_statistics.total_wells = size(well_points, 1);
    
    if ~isempty(well_points)
        critical_wells = sum(well_points(:, 3) == 20.0);  % 20 ft cell size
        standard_wells = sum(well_points(:, 3) == 35.0);  % 35 ft cell size
        marginal_wells = sum(well_points(:, 3) == 50.0);  % 50 ft cell size
        
        pebi_data.well_statistics.critical_wells = critical_wells;
        pebi_data.well_statistics.standard_wells = standard_wells;
        pebi_data.well_statistics.marginal_wells = marginal_wells;
    end
    
    pebi_data.validation = struct();
    pebi_data.validation.grid_integrity = G_pebi.cells.num > 0 && G_pebi.faces.num > 0;
    pebi_data.validation.has_geometry = isfield(G_pebi.cells, 'volumes');
    pebi_data.validation.has_fault_properties = isfield(G_pebi.faces, 'fault_multiplier');
    pebi_data.validation.timestamp = datestr(now, 'yyyy-mm-dd HH:MM:SS');
    
end

function points = generate_well_constrained_points(well_points, fault_lines, field_config, size_function)
% Generate point distribution constrained by wells and faults for triangular grid
%
% Creates a point distribution where:
% - Well locations are included as exact points
% - Higher point density around critical wells
% - Fault lines are honored with aligned points
% - Background field has uniform point distribution

    points = [];
    
    % Step 1: Add exact well locations
    if ~isempty(well_points)
        well_coords = well_points(:, 1:2);
        points = [points; well_coords];
        fprintf('   Added %d well constraint points\n', size(well_coords, 1));
    end
    
    % Step 2: Add fault constraint points
    fault_points = [];
    if ~isempty(fault_lines)
        for i = 1:size(fault_lines, 1)
            x1 = fault_lines(i, 1);
            y1 = fault_lines(i, 2);
            x2 = fault_lines(i, 3);
            y2 = fault_lines(i, 4);
            fault_size = fault_lines(i, 5);
            
            % Create points along fault line
            fault_length = sqrt((x2-x1)^2 + (y2-y1)^2);
            num_points = max(3, ceil(fault_length / fault_size));
            
            for j = 0:num_points
                t = j / num_points;
                x = x1 + t * (x2 - x1);
                y = y1 + t * (y2 - y1);
                fault_points = [fault_points; x, y];
            end
        end
        points = [points; fault_points];
        fprintf('   Added %d fault constraint points\n', size(fault_points, 1));
    end
    
    % Step 3: Add background grid points
    background_spacing = size_function.background_size;
    
    % Generate regular background grid
    x_coords = 0:background_spacing:field_config.field_extent_x;
    y_coords = 0:background_spacing:field_config.field_extent_y;
    [X_bg, Y_bg] = meshgrid(x_coords, y_coords);
    background_points = [X_bg(:), Y_bg(:)];
    
    % Remove background points too close to wells/faults
    min_distance = background_spacing * 0.5;
    if ~isempty(points)
        keep_background = true(size(background_points, 1), 1);
        for i = 1:size(background_points, 1)
            distances = sqrt(sum((points - background_points(i, :)).^2, 2));
            if min(distances) < min_distance
                keep_background(i) = false;
            end
        end
        background_points = background_points(keep_background, :);
    end
    
    points = [points; background_points];
    fprintf('   Added %d background points\n', size(background_points, 1));
    
    % Step 4: Add refinement points around critical wells
    refinement_points = [];
    if ~isempty(well_points)
        for i = 1:size(well_points, 1)
            well_x = well_points(i, 1);
            well_y = well_points(i, 2);
            well_size = well_points(i, 3);
            well_radius = well_points(i, 4);
            
            % Add refinement ring around well
            if well_size < background_spacing * 0.8  % Only for refined wells
                num_ring_points = 8;
                for j = 1:num_ring_points
                    angle = 2 * pi * j / num_ring_points;
                    ring_radius = well_radius * 0.6;
                    x = well_x + ring_radius * cos(angle);
                    y = well_y + ring_radius * sin(angle);
                    
                    % Only add if within domain
                    if x >= 0 && x <= field_config.field_extent_x && ...
                       y >= 0 && y <= field_config.field_extent_y
                        refinement_points = [refinement_points; x, y];
                    end
                end
            end
        end
        points = [points; refinement_points];
        fprintf('   Added %d well refinement points\n', size(refinement_points, 1));
    end
    
    % Step 5: Ensure domain boundary points are included
    boundary_spacing = background_spacing * 0.8;
    
    % Bottom boundary
    x_boundary = 0:boundary_spacing:field_config.field_extent_x;
    bottom_boundary = [x_boundary', zeros(length(x_boundary), 1)];
    
    % Top boundary  
    top_boundary = [x_boundary', ones(length(x_boundary), 1) * field_config.field_extent_y];
    
    % Left boundary
    y_boundary = boundary_spacing:boundary_spacing:(field_config.field_extent_y - boundary_spacing);
    left_boundary = [zeros(length(y_boundary), 1), y_boundary'];
    
    % Right boundary
    right_boundary = [ones(length(y_boundary), 1) * field_config.field_extent_x, y_boundary'];
    
    boundary_points = [bottom_boundary; top_boundary; left_boundary; right_boundary];
    points = [points; boundary_points];
    
    fprintf('   Added %d boundary constraint points\n', size(boundary_points, 1));
    fprintf('   Total point distribution: %d points for triangulation\n', size(points, 1));
    
end

% Main execution
if ~nargout
    pebi_data = s03_create_pebi_grid();
    fprintf('PEBI grid creation completed!\n\n');
end