function [completion_cells, completion_WI] = find_completion_cells(well, wi, G)
% FIND_COMPLETION_CELLS - Find grid cells for multi-layer completion
%
% INPUTS:
%   well - Well structure from wells placement
%   wi - Well index structure
%   G - Grid structure from MRST
%
% OUTPUTS:
%   completion_cells - Array of grid cell indices
%   completion_WI - Array of well indices for each cell
%
% Author: Claude Code AI System
% Date: August 22, 2025

    completion_cells = [];
    completion_WI = [];
    
    % For PEBI grids, find cells at different z-levels near the well
    well_xy = G.cells.centroids(well.cells(1), 1:2);  % Use first cell
    z_min = min(G.cells.centroids(:,3));
    z_max = max(G.cells.centroids(:,3));
    
    for j = 1:length(well.completion_layers)
        layer = well.completion_layers(j);
        % Calculate target z-coordinate for this layer
        target_z = z_min + (layer - 1) * (z_max - z_min) / 11;  % 12 layers, 0-indexed
        
        % Find cells near well location at target z
        xy_distances = sqrt((G.cells.centroids(:,1) - well_xy(1)).^2 + ...
                          (G.cells.centroids(:,2) - well_xy(2)).^2);
        z_distances = abs(G.cells.centroids(:,3) - target_z);
        
        % Find closest cell considering both xy and z distance
        combined_distance = xy_distances + 10 * z_distances;  % Weight z-distance more
        [~, cell_idx] = min(combined_distance);
        
        % CANON-FIRST validation: ensure cell index is valid
        if cell_idx <= G.cells.num && cell_idx >= 1
            completion_cells = [completion_cells; cell_idx];
            completion_WI = [completion_WI; wi.well_index / length(well.completion_layers)];
        else
            error(['CANON-FIRST ERROR: Invalid cell index %d for well %s layer %d (grid has %d cells)\n' ...
                   'UPDATE CANON: obsidian-vault/Planning/Well_Completion_Logic.md\n' ...
                   'Multi-layer completion algorithm generated invalid cell index.'], ...
                   cell_idx, well.name, j, G.cells.num);
        end
    end

end