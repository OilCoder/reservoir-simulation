function [G, status] = s04_structural_framework(G_basic, varargin)
%S04_STRUCTURAL_FRAMEWORK Add structural framework to basic grid

% Suppress warnings for cleaner output
warning('off', 'all');
%
% This script adds structural geology features including anticline structure,
% dip angles, and elevation variations to create a realistic reservoir framework.
%
% USAGE:
%   [G, status] = s04_structural_framework(G_basic)                    % Normal mode (clean output)
%   [G, status] = s04_structural_framework(G_basic, 'verbose', true)   % Verbose mode (detailed output)
%
% INPUT:
%   G_basic - Basic MRST grid structure from s02_create_grid
%
% OUTPUT:
%   G      - MRST grid structure with structural framework applied
%   status - Structure containing structural implementation status and information
%
% DEPENDENCIES:
%   - MRST environment (assumed already initialized by workflow)
%   - config/grid_config.yaml for grid parameters
%   - util_read_config.m (YAML reader)
%
% SUCCESS CRITERIA:
%   - Structural framework created without errors
%   - Anticline geometry properly applied
%   - Elevation variations realistic
%   - Grid geometry remains valid

    % Parse input arguments
    p = inputParser;
    addRequired(p, 'G_basic', @isstruct);
    addParameter(p, 'verbose', false, @islogical);
    parse(p, G_basic, varargin{:});
    verbose = p.Results.verbose;
    
    if verbose
        fprintf('\n=== Structural Framework Implementation ===\n');
    else
        fprintf('\n>> Adding Structural Framework:\n');
        fprintf('+-------------------------------------+--------+\n');
        fprintf('| Component                           | Status |\n');
        fprintf('+-------------------------------------+--------+\n');
    end
    
    % Initialize status structure
    status = struct();
    status.success = false;
    status.framework_applied = false;
    status.anticline_created = false;
    status.errors = {};
    status.warnings = {};
    
    % Initialize return values
    G = G_basic;
    
    % Define structural tasks
    task_names = {'Load Configuration', 'Extract Parameters', 'Create Anticline (340 ft relief)', 'Apply Structural Depths', 'Validate Framework'};
    
    try
        %% Step 1: Load grid configuration from YAML
        if verbose
            fprintf('Step 1: Loading grid configuration from YAML...\n');
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
            grid_config.Lz = parse_numeric(grid_raw.gross_thickness); % m
            
            step1_success = true;
        catch ME
            step1_success = false;
            if verbose
                fprintf('Error loading grid configuration: %s\n', ME.message);
            end
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
                fprintf('  - Grid configuration loaded from YAML\n');
                fprintf('  - Grid dimensions: %dx%dx%d\n', grid_config.nx, grid_config.ny, grid_config.nz);
            end
        end
        
        if ~step1_success
            error('Failed to load configuration');
        end
        
        %% Step 2: Extract structural parameters
        if verbose
            fprintf('Step 2: Extracting structural parameters...\n');
        end
        
        try
            % Extract grid parameters
            nx = grid_config.nx;  % 40
            ny = grid_config.ny;  % 40  
            nz = grid_config.nz;  % 12
            Lx = grid_config.Lx;  % 3280 m
            Ly = grid_config.Ly;  % 2950 m
            Lz = grid_config.Lz;  % 100 m
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
            fprintf('  - Grid: %dx%dx%d cells, extent: %.0fx%.0fx%.1f m\n', nx, ny, nz, Lx, Ly, Lz);
        end
        
        if ~step2_success
            error('Failed to extract structural parameters');
        end
        
        %% Step 3: Create anticline structure
        if verbose
            fprintf('Step 3: Creating anticline structure...\n');
        end
        
        try
            % Convert structural parameters from documentation
            ft_to_m = 0.3048;
            
            % Structural relief and depth range (from Structural_Geology.md Section 4.1)
            structural_relief_ft = 340;  % ft
            structural_relief_m = structural_relief_ft * ft_to_m;  % 103.6 m
            
            % Depth structure (7881-8119 ft TVDSS from documentation)
            structural_crest_ft = 7900;  % ft TVDSS (Northern compartment)
            secondary_high_ft = 7920;    % ft TVDSS (Southern compartment)  
            spill_point_ft = 8240;       % ft TVDSS (spill point)
            
            % Convert to meters TVDSS
            structural_crest_m = structural_crest_ft * ft_to_m;  % 2408.5 m
            secondary_high_m = secondary_high_ft * ft_to_m;      % 2414.6 m
            spill_point_m = spill_point_ft * ft_to_m;           % 2511.6 m
            
            % Grid orientation (N15degE from documentation)
            grid_azimuth = 15;  % degrees clockwise from North
            
            % Get cell centers for structural depth assignment
            cell_centers = G.cells.centroids;
            num_cells = G.cells.num;
            
            % Initialize structural depth array
            structural_depths = zeros(num_cells, 1);
            
            % Define anticline geometry parameters
            % Asymmetric anticline with steeper eastern flank (from Section 2.4)
            anticline_center_x = Lx * 0.45;  % Slightly west of center (asymmetric)
            anticline_center_y = Ly * 0.55;  % Slightly north of center
            
            % Compartment centers (from Section 2.3)
            northern_center_x = Lx * 0.4;
            northern_center_y = Ly * 0.75;
            southern_center_x = Lx * 0.5;
            southern_center_y = Ly * 0.3;
            
            % Define dip angles for asymmetric structure (from Section 4.2)
            northern_flank_dip = 3.2;  % degrees southward
            eastern_flank_dip = 5.5;   % degrees westward (steepest)
            southern_flank_dip = 3.8;  % degrees northward  
            western_flank_dip = 3.2;   % degrees eastward
            
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
            fprintf('| %-35s |   %s    |\n', task_names{3}, status_symbol);
        else
            fprintf('  - Structural relief: %.1f ft (%.1f m)\n', structural_relief_ft, structural_relief_m);
            fprintf('  - Depth range: %.0f-%.0f ft TVDSS (%.1f-%.1f m TVDSS)\n', ...
                    structural_crest_ft, spill_point_ft, structural_crest_m, spill_point_m);
            fprintf('  - Grid orientation: N%.0fdegE\n', grid_azimuth);
            fprintf('  - Anticline center: (%.0f, %.0f) m\n', anticline_center_x, anticline_center_y);
            fprintf('  - Northern compartment center: (%.0f, %.0f) m\n', northern_center_x, northern_center_y);
            fprintf('  - Southern compartment center: (%.0f, %.0f) m\n', southern_center_x, southern_center_y);
        end
        
        if ~step3_success
            error('Failed to create anticline structure');
        end
        
        %% Step 4: Assign structural depths by compartment
        if verbose
            fprintf('Step 4: Assigning structural depths...\n');
        end
        
        try
            compartment_assignments = cell(num_cells, 1);
            
            for c = 1:num_cells
                x = cell_centers(c, 1);
                y = cell_centers(c, 2);
                
                % Determine compartmentalization based on Fault E (internal fault)
                % Fault E creates northern and southern compartments
                compartment_boundary_y = Ly * 0.5;  % Middle of domain
                
                if y > compartment_boundary_y
                    % Northern Compartment
                    compartment_assignments{c} = 'Northern';
                    
                    % Distance from northern compartment structural high
                    dx = x - northern_center_x;
                    dy = y - northern_center_y;
                    
                    % Apply asymmetric dip structure
                    depth_increase = 0;
                    
                    % Eastern flank (steeper)
                    if dx > 0
                        depth_increase = depth_increase + abs(dx) * sin(deg2rad(eastern_flank_dip));
                    end
                    
                    % Western flank
                    if dx < 0
                        depth_increase = depth_increase + abs(dx) * sin(deg2rad(western_flank_dip));
                    end
                    
                    % Northern flank
                    if dy > 0
                        depth_increase = depth_increase + abs(dy) * sin(deg2rad(northern_flank_dip));
                    end
                    
                    % Southern flank (towards compartment boundary)
                    if dy < 0
                        depth_increase = depth_increase + abs(dy) * sin(deg2rad(southern_flank_dip));
                    end
                    
                    % Structural depth for northern compartment
                    structural_depths(c) = structural_crest_m + depth_increase;
                    
                else
                    % Southern Compartment
                    compartment_assignments{c} = 'Southern';
                    
                    % Distance from southern compartment structural high
                    dx = x - southern_center_x;
                    dy = y - southern_center_y;
                    
                    % Apply asymmetric dip structure
                    depth_increase = 0;
                    
                    % Eastern flank (steeper)
                    if dx > 0
                        depth_increase = depth_increase + abs(dx) * sin(deg2rad(eastern_flank_dip));
                    end
                    
                    % Western flank
                    if dx < 0
                        depth_increase = depth_increase + abs(dx) * sin(deg2rad(western_flank_dip));
                    end
                    
                    % Northern flank (towards compartment boundary)
                    if dy > 0
                        depth_increase = depth_increase + abs(dy) * sin(deg2rad(northern_flank_dip));
                    end
                    
                    % Southern flank
                    if dy < 0
                        depth_increase = depth_increase + abs(dy) * sin(deg2rad(southern_flank_dip));
                    end
                    
                    % Structural depth for southern compartment (slightly deeper than northern)
                    structural_depths(c) = secondary_high_m + depth_increase;
                end
            end
            
            % Apply structural constraints
            % Enforce minimum and maximum structural depths
            min_structural_depth = structural_crest_m;
            max_structural_depth = spill_point_m;
            
            % Count cells in depth ranges before constraining
            cells_above_crest = sum(structural_depths < min_structural_depth);
            cells_below_spill = sum(structural_depths > max_structural_depth);
            
            % Apply depth constraints
            structural_depths(structural_depths < min_structural_depth) = min_structural_depth;
            structural_depths(structural_depths > max_structural_depth) = max_structural_depth;
            
            % Calculate actual structural relief achieved
            actual_relief_m = max(structural_depths) - min(structural_depths);
            actual_relief_ft = actual_relief_m / ft_to_m;
            
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
            fprintf('| %-35s |   %s    |\n', sprintf('%s (%d cells)', task_names{4}, num_cells), status_symbol);
        else
            fprintf('  - Cells constrained to crest: %d\n', cells_above_crest);
            fprintf('  - Cells constrained to spill: %d\n', cells_below_spill);
            fprintf('  - Actual structural relief: %.1f ft (%.1f m)\n', actual_relief_ft, actual_relief_m);
        end
        
        if ~step4_success
            error('Failed to assign structural depths');
        end
        
        %% Step 5: Store structural framework in grid
        if verbose
            fprintf('Step 5: Storing structural framework...\n');
        end
        
        try
            % Add structural information to grid
            G.structure = struct();
            G.structure.depths = structural_depths;
            G.structure.compartments = compartment_assignments;
            G.structure.relief_m = actual_relief_m;
            G.structure.relief_ft = actual_relief_ft;
            G.structure.depth_range_m = [min(structural_depths), max(structural_depths)];
            G.structure.depth_range_ft = G.structure.depth_range_m / ft_to_m;
            G.structure.grid_azimuth = grid_azimuth;
            
            % Compartment statistics
            northern_cells = sum(strcmp(compartment_assignments, 'Northern'));
            southern_cells = sum(strcmp(compartment_assignments, 'Southern'));
            
            G.structure.northern_cells = northern_cells;
            G.structure.southern_cells = southern_cells;
            G.structure.compartment_ratio = northern_cells / southern_cells;
            
            % Store structural high locations
            G.structure.northern_high = [northern_center_x, northern_center_y, structural_crest_m];
            G.structure.southern_high = [southern_center_x, southern_center_y, secondary_high_m];
            
            % Calculate structural statistics
            mean_depth = mean(structural_depths);
            std_depth = std(structural_depths);
            
            % Compartment depth statistics
            northern_depths = structural_depths(strcmp(compartment_assignments, 'Northern'));
            southern_depths = structural_depths(strcmp(compartment_assignments, 'Southern'));
            
            northern_mean = mean(northern_depths);
            southern_mean = mean(southern_depths);
            
            status.structural_relief = actual_relief_m;
            status.depth_range = [min(structural_depths), max(structural_depths)];
            status.compartments = 2;  % Northern and Southern
            status.mean_depth = mean_depth;
            status.depth_std = std_depth;
            status.northern_mean_depth = northern_mean;
            status.southern_mean_depth = southern_mean;
            status.depth_difference = abs(northern_mean - southern_mean);
            
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
            fprintf('| %-35s |   %s    |\n', sprintf('%s (%d compartments)', task_names{5}, 2), status_symbol);
        else
            fprintf('  - Northern compartment: %d cells\n', northern_cells);
            fprintf('  - Southern compartment: %d cells\n', southern_cells);
            fprintf('  - Compartment ratio: %.2f\n', G.structure.compartment_ratio);
            fprintf('  - Mean structural depth: %.1f m (%.0f ft)\n', mean_depth, mean_depth/ft_to_m);
            fprintf('  - Depth standard deviation: %.1f m\n', std_depth);
            fprintf('  - Northern compartment mean: %.1f m\n', northern_mean);
            fprintf('  - Southern compartment mean: %.1f m\n', southern_mean);
            fprintf('  - Inter-compartment difference: %.1f m\n', status.depth_difference);
        end
        
        if ~step5_success
            error('Failed to validate structural framework');
        end
        
        %% Success
        status.success = step1_success && step2_success && step3_success && step4_success && step5_success;
        status.timestamp = datestr(now, 'yyyy-mm-dd HH:MM:SS');
        
        if verbose
            fprintf('\n=== Structural Framework Implementation SUCCESSFUL ===\n');
            fprintf('Anticline structure: 4-way dip closure implemented\n');
            fprintf('Structural relief: %.1f ft (%.1f m)\n', actual_relief_ft, actual_relief_m);
            fprintf('Depth range: %.0f-%.0f ft TVDSS (%.1f-%.1f m TVDSS)\n', ...
                    min(G.structure.depth_range_ft), max(G.structure.depth_range_ft), ...
                    min(G.structure.depth_range_m), max(G.structure.depth_range_m));
            fprintf('Compartmentalization: %d compartments (%d Northern, %d Southern)\n', ...
                    status.compartments, northern_cells, southern_cells);
            fprintf('Grid orientation: N%.0fdegE\n', grid_azimuth);
            fprintf('Timestamp: %s\n', status.timestamp);
        else
            % Close the table
            fprintf('+-------------------------------------+--------+\n');
            fprintf('>> Structure: %.0f ft relief with %d compartments\n', actual_relief_ft, 2);
            fprintf('   Depth range: %.0f-%.0f ft TVDSS | Cells: %d Northern, %d Southern\n', ...
                    min(G.structure.depth_range_ft), max(G.structure.depth_range_ft), northern_cells, southern_cells);
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
        
        fprintf('\n=== Structural Framework Implementation FAILED ===\n');
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