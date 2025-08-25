function [top_depth_ft, bottom_depth_ft] = get_layer_depths_from_grid(G, well, layer)
% GET_LAYER_DEPTHS_FROM_GRID - Get layer depths from existing geological grid
%
% INPUTS:
%   G - Grid structure from MRST
%   well - Well structure with surface coordinates
%   layer - Layer number (1-12)
%
% OUTPUTS:
%   top_depth_ft - Top depth of layer in feet
%   bottom_depth_ft - Bottom depth of layer in feet
%
% Author: Claude Code AI System
% Date: August 22, 2025

    % Convert well surface coordinates to grid coordinates
    well_x = well.surface_coords(1);  % ft
    well_y = well.surface_coords(2);  % ft
    
    % Find cells near well location for the specific layer
    xy_distances = sqrt((G.cells.centroids(:,1) - well_x).^2 + ...
                        (G.cells.centroids(:,2) - well_y).^2);
    
    % Start with reasonable radius and expand if needed
    search_radius = 500;  % ft
    nearby_cells = find(xy_distances <= search_radius);
    
    % If no cells found, expand search radius gradually
    while isempty(nearby_cells) && search_radius <= 2000
        search_radius = search_radius * 2;
        nearby_cells = find(xy_distances <= search_radius);
        if ~isempty(nearby_cells)
            fprintf('   Warning: Well %s at [%.0f, %.0f] outside standard grid, using %.0f ft radius\n', ...
                    well.name, well_x, well_y, search_radius);
        end
    end
    
    if isempty(nearby_cells)
        error('CANON-FIRST ERROR: No grid cells found near well %s at [%.0f, %.0f] even with 2000 ft radius', ...
              well.name, well_x, well_y);
    end
    
    % Get z-coordinates (depths) of nearby cells
    nearby_depths = G.cells.centroids(nearby_cells, 3);
    
    % For layer-based completion, estimate layer boundaries
    % Based on canonical 12-layer structure from rock_properties_config.yaml
    z_min = min(G.cells.centroids(:,3));
    z_max = max(G.cells.centroids(:,3));
    total_thickness = z_max - z_min;
    
    % Layer thickness based on canonical structure (12 layers)
    layer_thickness = total_thickness / 12;
    
    % Calculate layer boundaries using canonical layer structure
    layer_top = z_min + (layer - 1) * layer_thickness;
    layer_bottom = z_min + layer * layer_thickness;
    
    % Find cells within this layer range near the well
    layer_cells = nearby_cells(nearby_depths >= layer_top & nearby_depths <= layer_bottom);
    
    if isempty(layer_cells)
        % If no cells in exact layer range, use estimated depths
        top_depth_ft = layer_top;
        bottom_depth_ft = layer_bottom;
        fprintf('   Warning: Using estimated depths for %s layer %d\n', well.name, layer);
    else
        % Use actual grid cell depths for more accuracy
        layer_depths = G.cells.centroids(layer_cells, 3);
        top_depth_ft = min(layer_depths);
        bottom_depth_ft = max(layer_depths);
    end
    
    % Ensure minimum thickness for completion interval
    min_thickness = 10;  % ft
    if (bottom_depth_ft - top_depth_ft) < min_thickness
        bottom_depth_ft = top_depth_ft + min_thickness;
    end

end