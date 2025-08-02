function [G, status] = s02_create_grid(varargin)
%S02_CREATE_GRID Create basic Cartesian grid from configuration

% Suppress warnings for cleaner output
warning('off', 'Octave:language-extension');
warning('off', 'Octave:str-to-num');
%
% This script creates a Cartesian tensor grid based on the centralized
% configuration for the Eagle West Field simulation.
%
% USAGE:
%   [G, status] = s02_create_grid(config)                    % Normal mode (clean output)
%   [G, status] = s02_create_grid(config, 'verbose', true)   % Verbose mode (detailed output)
%   [G, status] = s02_create_grid('verbose', true)           % Load config automatically, verbose
%
% INPUT:
%   config - Configuration structure from s00_load_config (optional)
%            If not provided, will load configuration automatically
%
% OUTPUT:
%   G      - MRST grid structure with computed geometry
%   status - Structure containing grid creation status and information
%
% DEPENDENCIES:
%   - MRST environment (assumed already initialized by workflow)
%   - s00_load_config.m (centralized configuration loader)
%
% SUCCESS CRITERIA:
%   - Grid created without errors  
%   - Geometry computed successfully
%   - Properties assigned from config
%   - Grid quality validated

    % Parse input arguments
    p = inputParser;
    addOptional(p, 'config', [], @isstruct);
    addParameter(p, 'verbose', false, @islogical);
    parse(p, varargin{:});
    config = p.Results.config;
    verbose = p.Results.verbose;
    
    if verbose
        fprintf('\n=== Grid Creation ===\n');
    else
        fprintf('\n>> Creating Grid Structure:\n');
        fprintf('+-------------------------------------+--------+\n');
        fprintf('| Task                                | Status |\n');
        fprintf('+-------------------------------------+--------+\n');
    end
    
    % Initialize status structure
    status = struct();
    status.success = false;
    status.grid_created = false;
    status.geometry_computed = false;
    status.errors = {};
    status.warnings = {};
    
    % Initialize return values
    G = [];
    
    % Define grid creation tasks
    task_names = {'Load Configuration', 'Extract Parameters', 'Create Cartesian Grid', 'Compute Geometry', 'Validate Quality'};
    
    try
        %% Step 1: Load configuration if not provided
        if verbose
            fprintf('Step 1: Loading configuration...\n');
        end
        
        try
            % Load config if not provided as input
            if isempty(config)
                config = s00_load_config('verbose', false);
                if ~config.loaded
                    error('Failed to load configuration');
                end
                config_source = 'auto-loaded';
            else
                config_source = 'provided';
            end
            grid_config = config.grid;
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
        
        %% Step 2: Extract grid parameters
        if verbose
            fprintf('Step 2: Extracting grid parameters...\n');
        end
        
        try
            % Grid dimensions (already processed)
            nx = grid_config.nx;
            ny = grid_config.ny; 
            nz = grid_config.nz;
            
            % Cell dimensions (already in m)
            dx = grid_config.dx;
            dy = grid_config.dy;
            dz = grid_config.dz;
            
            % Field extent (already in m)
            Lx = grid_config.Lx;
            Ly = grid_config.Ly;
            Lz = grid_config.Lz;
            
            % Validate parameters
            if nx <= 0 || ny <= 0 || nz <= 0 || dx <= 0 || dy <= 0 || dz <= 0
                error('Invalid grid parameters');
            end
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
            fprintf('  - Grid dimensions: %d x %d x %d cells\n', nx, ny, nz);
            fprintf('  - Cell size: %.1f x %.1f x %.1f m\n', dx, dy, dz);
            fprintf('  - Field extent: %.0f x %.0f x %.1f m\n', Lx, Ly, Lz);
        end
        
        if ~step2_success
            error('Failed to extract grid parameters');
        end
        
        %% Step 3: Create Cartesian grid
        if verbose
            fprintf('Step 3: Creating Cartesian tensor grid...\n');
        end
        
        try
            % Create MRST Cartesian grid
            G = cartGrid([nx, ny, nz], [Lx, Ly, Lz]);
            if isempty(G) || G.cells.num == 0
                error('Grid creation failed');
            end
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
            fprintf('| %-35s |   %s    |\n', sprintf('%s (%dx%dx%d)', task_names{3}, nx, ny, nz), status_symbol);
        else
            fprintf('  - Cartesian grid created: %d cells\n', G.cells.num);
        end
        
        if ~step3_success
            error('Failed to create Cartesian grid');
        end
        
        status.grid_created = true;
        
        %% Step 4: Compute grid geometry
        if verbose
            fprintf('Step 4: Computing grid geometry...\n');
        end
        
        try
            G = computeGeometry(G);
            % Verify geometry computation
            if ~isfield(G, 'cells') || ~isfield(G.cells, 'volumes') || ...
               ~isfield(G, 'faces') || ~isfield(G.faces, 'areas')
                error('Geometry computation failed');
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
            fprintf('| %-35s |   %s    |\n', task_names{4}, status_symbol);
        else
            fprintf('  - Geometry computed successfully\n');
            fprintf('  - Total pore volume: %.2e m??\n', sum(G.cells.volumes));
            fprintf('  - Average cell volume: %.2e m??\n', mean(G.cells.volumes));
        end
        
        if ~step4_success
            error('Failed to compute grid geometry');
        end
        
        status.geometry_computed = true;
        
        %% Step 5: Grid quality validation
        if verbose
            fprintf('Step 5: Validating grid quality...\n');
        end
        
        try
            % Check aspect ratios
            cell_dims = [dx, dy, dz];
            max_aspect = max(cell_dims) / min(cell_dims);
            
            % Check volume consistency
            expected_volume = Lx * Ly * Lz;
            actual_volume = sum(G.cells.volumes);
            volume_error = abs(actual_volume - expected_volume) / expected_volume;
            
            if max_aspect > 10
                status.warnings{end+1} = sprintf('High aspect ratio: %.1f', max_aspect);
            end
            
            if volume_error > 0.01
                status.warnings{end+1} = sprintf('Volume error: %.2f%%', volume_error * 100);
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
            fprintf('| %-35s |   %s    |\n', sprintf('%s (ratio %.1f)', task_names{5}, max_aspect), status_symbol);
        else
            fprintf('  - Aspect ratio: %.1f\n', max_aspect);
            fprintf('  - Volume consistency: %.4f%% error\n', volume_error * 100);
        end
        
        % Store grid parameters in status
        status.grid_params = struct();
        status.grid_params.nx = nx;
        status.grid_params.ny = ny;
        status.grid_params.nz = nz;
        status.grid_params.dx = dx;
        status.grid_params.dy = dy;  
        status.grid_params.dz = dz;
        status.grid_params.Lx = Lx;
        status.grid_params.Ly = Ly;
        status.grid_params.Lz = Lz;
        status.grid_params.total_cells = G.cells.num;
        status.grid_params.total_volume = actual_volume;
        status.grid_params.aspect_ratio = max_aspect;
        
        %% Success
        status.success = step1_success && step2_success && step3_success && step4_success && step5_success;
        status.timestamp = datestr(now, 'yyyy-mm-dd HH:MM:SS');
        
        if verbose
            fprintf('\n=== Grid Creation SUCCESSFUL ===\n');
            fprintf('Grid: %d x %d x %d = %d cells\n', nx, ny, nz, G.cells.num);
            fprintf('Extent: %.0f x %.0f x %.1f m\n', Lx, Ly, Lz);
            fprintf('Volume: %.2e m³\n', actual_volume);
            fprintf('Timestamp: %s\n', status.timestamp);
        else
            % Close the table
            fprintf('+-------------------------------------+--------+\n');
            fprintf('>> Grid: %d cells (%dx%dx%d) created successfully\n', G.cells.num, nx, ny, nz);
            fprintf('   Volume: %.2e m³ | Aspect ratio: %.1f | Quality: verified\n', actual_volume, max_aspect);
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
        
        fprintf('\n=== Grid Creation FAILED ===\n');
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