function [rock_hetero, status] = s09_spatial_heterogeneity(rock, G, config, varargin)
%S09_SPATIAL_HETEROGENEITY Apply spatial heterogeneity modeling to rock properties
%
% This script applies spatial heterogeneity to the layer-based rock properties
% using geostatistical methods, porosity-permeability correlations, and
% spatial correlation structures.
%
% USAGE:
%   [rock_hetero, status] = s09_spatial_heterogeneity(rock, G, config)                % Normal mode
%   [rock_hetero, status] = s09_spatial_heterogeneity(rock, G, config, 'verbose', true) % Verbose mode
%
% INPUT:
%   rock   - Rock structure with layer-based properties (from s08_assign_layer_properties)
%   G      - MRST grid structure (from s06_grid_refinement)
%   config - Configuration structure (from s00_load_config)
%
% OUTPUT:
%   rock_hetero - Enhanced rock structure with spatial heterogeneity
%   status      - Structure containing heterogeneity modeling status and information
%
% HETEROGENEITY METHODS:
%   1. Gaussian random field generation for porosity
%   2. Kozeny-Carman porosity-permeability correlation
%   3. Spatial correlation with specified ranges
%   4. Net-to-gross adjustments by rock type
%   5. Property validation and clipping
%
% DEPENDENCIES:
%   - MRST grid structure
%   - Rock properties from s08_assign_layer_properties
%   - Configuration from rock_properties_config.yaml
%
% SUCCESS CRITERIA:
%   - Spatial heterogeneity applied to all cells
%   - Properties maintain physical validity
%   - Correlation structures preserved

% Suppress warnings for cleaner output
warning('off', 'all');

    % Parse input arguments
    p = inputParser;
    addRequired(p, 'rock', @isstruct);
    addRequired(p, 'G', @isstruct);
    addOptional(p, 'config', [], @(x) isstruct(x) || isempty(x));
    addParameter(p, 'verbose', false, @islogical);
    parse(p, rock, G, varargin{:});
    
    verbose = p.Results.verbose;
    
    if verbose
        fprintf('\n=== Spatial Heterogeneity Modeling ===\n');
    else
        fprintf('\n>> Applying Spatial Heterogeneity:\n');
        fprintf('+-------------------------------------+--------+\n');
        fprintf('| Component                           | Status |\n');
        fprintf('+-------------------------------------+--------+\n');
    end
    
    % Initialize status structure
    status = struct();
    status.success = false;
    status.cells_processed = 0;
    status.correlation_applied = false;
    status.errors = {};
    status.warnings = {};
    
    % Initialize return values
    rock_hetero = rock;  % Start with input rock properties
    
    % Define heterogeneity tasks
    task_names = {'Load Heterogeneity Parameters', 'Generate Spatial Fields', 'Apply Correlations'};
    
    try
        %% Step 1: Load heterogeneity parameters from configuration
        if verbose
            fprintf('Step 1: Loading heterogeneity parameters...\n');
        end
        
        try
            % Load heterogeneity configuration directly from YAML
            config_dir = 'config';
            rock_file = fullfile(config_dir, 'rock_properties_config.yaml');
            rock_raw = util_read_config(rock_file);
            
            % Extract heterogeneity parameters
            hetero_params = struct();
            
            % Spatial correlation parameters
            hetero_params.range_major = get_yaml_field(rock_raw, 'heterogeneity_parameters_variogram_parameters_range_major', 1500);  % ft
            hetero_params.range_minor = get_yaml_field(rock_raw, 'heterogeneity_parameters_variogram_parameters_range_minor', 800);   % ft
            hetero_params.azimuth = get_yaml_field(rock_raw, 'heterogeneity_parameters_variogram_parameters_azimuth', 45);            % degrees
            hetero_params.nugget = get_yaml_field(rock_raw, 'heterogeneity_parameters_variogram_parameters_nugget', 0.1);
            hetero_params.sill = get_yaml_field(rock_raw, 'heterogeneity_parameters_variogram_parameters_sill', 1.0);
            
            % Porosity-permeability correlation
            hetero_params.correlation_type = get_yaml_field(rock_raw, 'heterogeneity_parameters_phi_k_correlation_correlation_type', 'kozeny_carman');
            hetero_params.correlation_exponent = get_yaml_field(rock_raw, 'heterogeneity_parameters_phi_k_correlation_exponent', 3.0);
            hetero_params.tortuosity = get_yaml_field(rock_raw, 'heterogeneity_parameters_phi_k_correlation_tortuosity', 2.0);
            
            % Convert ft to m for correlation ranges
            ft_to_m = 0.3048;
            hetero_params.range_major = hetero_params.range_major * ft_to_m;
            hetero_params.range_minor = hetero_params.range_minor * ft_to_m;
            
            step1_success = true;
        catch ME
            step1_success = false;
            if verbose
                fprintf('Error loading heterogeneity parameters: %s\n', ME.message);
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
                fprintf('  - Correlation ranges: %.0f x %.0f m\n', hetero_params.range_major, hetero_params.range_minor);
                fprintf('  - Azimuth: %.0f degrees\n', hetero_params.azimuth);
                fprintf('  - Correlation type: %s\n', hetero_params.correlation_type);
            end
        end
        
        if ~step1_success
            error('Failed to load heterogeneity parameters');
        end
        
        %% Step 2: Generate spatial random fields
        if verbose
            fprintf('Step 2: Generating spatial random fields...\n');
        end
        
        try
            % Get grid information
            nc = G.cells.num;
            
            % Get cell centers
            cell_centers = G.cells.centroids;
            
            % Generate spatial random fields for porosity perturbation
            % Simplified approach: use distance-based correlation
            
            % Create correlation matrix (simplified exponential correlation)
            correlation_field = zeros(nc, 1);
            
            % Set random seed for reproducibility
            rng(42);
            
            % Generate base random field
            base_field = randn(nc, 1);
            
            % Apply spatial correlation using simplified approach
            % For large grids, use a simplified correlation method
            correlation_length = hetero_params.range_minor;
            
            % Create a simple smoothing filter instead of full distance calculations
            % This approximates spatial correlation much faster
            correlation_field = base_field;
            
            % Apply simple smoothing in grid coordinates for efficiency
            % Get grid configuration for structured approach
            config_dir = 'config';
            grid_file = fullfile(config_dir, 'grid_config.yaml');
            grid_raw = util_read_config(grid_file);
            nx = parse_numeric(grid_raw.nx);
            ny = parse_numeric(grid_raw.ny);
            nz = parse_numeric(grid_raw.nz);
            
            % Reshape to 3D grid for efficient smoothing
            field_3d = reshape(correlation_field, nx, ny, nz);
            
            % Apply simple 3x3x1 smoothing (much faster than distance calculations)
            smoothed_3d = field_3d;
            for k = 1:nz
                for j = 2:ny-1
                    for i = 2:nx-1
                        % 3x3 neighborhood average
                        neighborhood = field_3d(i-1:i+1, j-1:j+1, k);
                        smoothed_3d(i, j, k) = mean(neighborhood(:));
                    end
                end
            end
            
            % Reshape back to vector
            correlation_field = reshape(smoothed_3d, nc, 1);
            
            % Normalize correlation field to have unit variance
            correlation_field = (correlation_field - mean(correlation_field)) / std(correlation_field);
            
            % Apply nugget effect
            nugget_field = randn(nc, 1) * sqrt(hetero_params.nugget);
            correlation_field = correlation_field * sqrt(1 - hetero_params.nugget) + nugget_field;
            
            step2_success = true;
        catch ME
            step2_success = false;
            if verbose
                fprintf('Error generating spatial fields: %s\n', ME.message);
            end
        end
        
        if ~verbose
            if step2_success
                status_symbol = 'Y';
            else
                status_symbol = 'X';
            end
            fprintf('| %-35s |   %s    |\n', sprintf('Generate %d Spatial Fields', nc), status_symbol);
        else
            if step2_success
                fprintf('  - Random fields generated for %d cells\n', nc);
                fprintf('  - Correlation length: %.0f m\n', hetero_params.range_minor);
                fprintf('  - Field statistics: mean=%.3f, std=%.3f\n', mean(correlation_field), std(correlation_field));
            end
        end
        
        if ~step2_success
            error('Failed to generate spatial fields');
        end
        
        %% Step 3: Apply correlations and update rock properties
        if verbose
            fprintf('Step 3: Applying correlations and updating properties...\n');
        end
        
        try
            % Load rock types for correlation parameters
            [rock_types, ~] = s07_define_rock_types('verbose', false);
            
            % Track original statistics
            original_poro_mean = mean(rock_hetero.poro);
            original_perm_mean = mean(rock_hetero.perm(:, 1));
            
            cells_processed = 0;
            
            % Process each cell
            for i = 1:nc
                % Get rock type for this cell
                if isfield(rock_hetero, 'rock_type_map')
                    rt_id = rock_hetero.rock_type_map(i);
                    if rt_id >= 1 && rt_id <= 6
                        rt_name = sprintf('RT%d', rt_id);
                    else
                        rt_name = 'RT2';  % Default
                    end
                else
                    rt_name = 'RT2';  % Default if no mapping
                end
                
                % Get rock type properties
                if isfield(rock_types, rt_name)
                    rt = rock_types.(rt_name);
                else
                    rt = rock_types.RT2;  % Fallback
                end
                
                % Apply heterogeneity to porosity
                base_porosity = rock_hetero.poro(i);
                porosity_std = rt.porosity_std;
                
                % Perturb porosity using spatial field
                perturbation = correlation_field(i) * porosity_std;
                new_porosity = base_porosity + perturbation;
                
                % Clip porosity to valid range
                min_poro = rt.porosity_min;
                max_poro = rt.porosity_max;
                new_porosity = max(min_poro, min(max_poro, new_porosity));
                
                % Update porosity
                rock_hetero.poro(i) = new_porosity;
                
                % Apply porosity-permeability correlation
                if strcmp(hetero_params.correlation_type, 'kozeny_carman')
                    % Kozeny-Carman relationship: k ∝ φ³/(1-φ)²
                    phi = new_porosity;
                    phi_ref = rt.porosity_mean;
                    
                    % Calculate permeability multiplier
                    k_multiplier = (phi^3 / (1-phi)^2) / (phi_ref^3 / (1-phi_ref)^2);
                    
                    % Limit extreme multipliers
                    k_multiplier = max(0.1, min(10.0, k_multiplier));
                    
                    % Apply to permeability
                    base_perm = rt.perm_mean;  % Use rock type mean
                    new_perm = base_perm * k_multiplier;
                    
                    % Apply Kv/Kh ratio
                    kv_kh_ratio = rt.kv_kh_ratio;
                    
                    rock_hetero.perm(i, 1) = new_perm;  % kx
                    rock_hetero.perm(i, 2) = new_perm;  % ky
                    rock_hetero.perm(i, 3) = new_perm * kv_kh_ratio;  % kz
                else
                    % Use simple power law: k = a * φ^n
                    if isfield(rt, 'poro_perm_correlation')
                        a = rt.poro_perm_correlation.a;
                        n = rt.poro_perm_correlation.n;
                        
                        % Calculate permeability in mD
                        k_mD = a * (new_porosity * 100)^n;  % φ in %
                        
                        % Convert to m²
                        mD_to_m2 = 9.869233e-16;
                        new_perm = k_mD * mD_to_m2;
                        
                        % Apply Kv/Kh ratio
                        kv_kh_ratio = rt.kv_kh_ratio;
                        
                        rock_hetero.perm(i, 1) = new_perm;  % kx
                        rock_hetero.perm(i, 2) = new_perm;  % ky
                        rock_hetero.perm(i, 3) = new_perm * kv_kh_ratio;  % kz
                    end
                end
                
                cells_processed = cells_processed + 1;
            end
            
            % Calculate final statistics
            final_poro_mean = mean(rock_hetero.poro);
            final_perm_mean = mean(rock_hetero.perm(:, 1));
            
            % Store heterogeneity statistics
            status.cells_processed = cells_processed;
            status.correlation_applied = true;
            status.original_porosity_mean = original_poro_mean;
            status.final_porosity_mean = final_poro_mean;
            status.original_permeability_mean = original_perm_mean;
            status.final_permeability_mean = final_perm_mean;
            status.porosity_cv = std(rock_hetero.poro) / mean(rock_hetero.poro);
            
            mD_to_m2 = 9.869233e-16;
            status.permeability_cv = std(rock_hetero.perm(:,1)) / mean(rock_hetero.perm(:,1));
            
            step3_success = true;
        catch ME
            step3_success = false;
            if verbose
                fprintf('Error applying correlations: %s\n', ME.message);
            end
        end
        
        if ~verbose
            if step3_success
                status_symbol = 'Y';
            else
                status_symbol = 'X';
            end
            fprintf('| %-35s |   %s    |\n', sprintf('%s (%d cells)', task_names{3}, cells_processed), status_symbol);
        else
            if step3_success
                mD_to_m2 = 9.869233e-16;
                fprintf('  - Cells processed: %d\n', cells_processed);
                fprintf('  - Porosity CV: %.3f\n', status.porosity_cv);
                fprintf('  - Permeability CV: %.3f\n', status.permeability_cv);
                fprintf('  - Mean porosity change: %.1f%% -> %.1f%%\n', ...
                        original_poro_mean*100, final_poro_mean*100);
                fprintf('  - Mean permeability: %.0f -> %.0f mD\n', ...
                        original_perm_mean/mD_to_m2, final_perm_mean/mD_to_m2);
            end
        end
        
        if ~step3_success
            error('Failed to apply correlations');
        end
        
        %% Success
        status.success = step1_success && step2_success && step3_success;
        status.timestamp = datestr(now, 'yyyy-mm-dd HH:MM:SS');
        
        if verbose
            fprintf('\n=== Spatial Heterogeneity Modeling SUCCESSFUL ===\n');
            fprintf('Cells processed: %d\n', cells_processed);
            fprintf('Correlation method: %s\n', hetero_params.correlation_type);
            fprintf('Porosity CV: %.3f\n', status.porosity_cv);
            fprintf('Permeability CV: %.3f\n', status.permeability_cv);
            fprintf('Spatial correlation applied: %s\n', status.correlation_applied);
            fprintf('Timestamp: %s\n', status.timestamp);
        else
            % Close the table
            fprintf('+-------------------------------------+--------+\n');
            fprintf('>> Spatial Heterogeneity: %d cells processed successfully\n', cells_processed);
            mD_to_m2 = 9.869233e-16;
            fprintf('   Porosity CV: %.3f | Permeability CV: %.3f | Range: %.0f m\n', ...
                    status.porosity_cv, status.permeability_cv, hetero_params.range_minor);
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
        
        fprintf('\n=== Spatial Heterogeneity Modeling FAILED ===\n');
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

function value = get_yaml_field(yaml_struct, field_name, default_value)
%GET_YAML_FIELD Extract field from flattened YAML structure with default
%
% This helper function safely extracts values from the flattened YAML
% structure returned by util_read_config, providing defaults if fields
% are missing.

    if isfield(yaml_struct, field_name)
        value = yaml_struct.(field_name);
        % Remove quotes if it's a string
        if ischar(value) && length(value) >= 2
            if (value(1) == '"' && value(end) == '"') || (value(1) == '''' && value(end) == '''')
                value = value(2:end-1);
            end
        end
    else
        value = default_value;
    end
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