function heterogeneity_data = s09_spatial_heterogeneity()
% S09_SPATIAL_HETEROGENEITY - Apply spatial heterogeneity for Eagle West Field
%
% SYNTAX:
%   heterogeneity_data = s09_spatial_heterogeneity()
%
% OUTPUT:
%   heterogeneity_data - Structure containing spatial heterogeneity data
%
% DESCRIPTION:
%   Apply geostatistical spatial heterogeneity patterns following
%   specifications in 02_Rock_Properties.md.
%
% Author: Claude Code AI System
% Date: January 30, 2025

    fprintf('======================================================\n');
    fprintf('Eagle West Field - Spatial Heterogeneity (Step 9)\n');
    fprintf('======================================================\n\n');
    
    try
        % Load layer properties
        fprintf('Step 1: Loading layer properties data...\n');
        properties_file = '../data/mrst_simulation/static/layer_properties.mat';
        if exist(properties_file, 'file')
            load(properties_file, 'G');
        else
            error('Layer properties not found. Run s08_assign_layer_properties first.');
        end
        
        % Apply heterogeneity patterns
        fprintf('Step 2: Applying spatial heterogeneity...\n');
        G = apply_heterogeneity_patterns(G);
        fprintf('   ✓ Heterogeneity patterns applied\n');
        
        % Export final grid with heterogeneity
        fprintf('Step 3: Exporting heterogeneous grid...\n');
        export_heterogeneous_grid(G);
        fprintf('   ✓ Heterogeneous grid exported\n\n');
        
        heterogeneity_data = struct();
        heterogeneity_data.grid = G;
        heterogeneity_data.status = 'completed';
        
        fprintf('✓ Spatial heterogeneity application completed\n\n');
        
    catch ME
        fprintf('❌ Spatial heterogeneity failed: %s\n', ME.message);
        error('Spatial heterogeneity failed: %s', ME.message);
    end

end

function G = apply_heterogeneity_patterns(G)
    % Apply additional heterogeneity using simple correlation patterns
    
    % Get cell coordinates
    x = G.cells.centroids(:,1);
    y = G.cells.centroids(:,2);
    
    % Create correlation patterns (simplified geostatistics)
    correlation_length = 500; % ft
    
    % Generate random field with spatial correlation
    correlation_factor = exp(-((x - mean(x)).^2 + (y - mean(y)).^2) / (2 * correlation_length^2));
    correlation_factor = correlation_factor / max(correlation_factor);
    
    % Apply heterogeneity multiplier (±20% variation)
    heterogeneity_mult = 1 + 0.2 * correlation_factor .* (2*rand(G.cells.num, 1) - 1);
    
    % Apply to permeability (more sensitive to heterogeneity)
    G.cells.permeability = G.cells.permeability .* heterogeneity_mult;
    
    % Apply smaller effect to porosity (±10% variation)
    porosity_mult = 1 + 0.1 * correlation_factor .* (2*rand(G.cells.num, 1) - 1);
    G.cells.porosity = G.cells.porosity .* porosity_mult;
    
    % Ensure minimum values
    G.cells.permeability = max(G.cells.permeability, 0.001);
    G.cells.porosity = max(G.cells.porosity, 0.01);
end

function export_heterogeneous_grid(G)
    script_path = fileparts(mfilename('fullpath'));
    data_dir = fullfile(fileparts(script_path), 'data', 'mrst_simulation', 'static');
    
    if ~exist(data_dir, 'dir')
        mkdir(data_dir);
    end
    
    % Save final grid with all properties
    final_grid_file = fullfile(data_dir, 'final_grid_with_properties.mat');
    save(final_grid_file, 'G', '');
    
    fprintf('     Final heterogeneous grid saved to: %s\n', final_grid_file);
end

if ~nargout
    heterogeneity_data = s09_spatial_heterogeneity();
end