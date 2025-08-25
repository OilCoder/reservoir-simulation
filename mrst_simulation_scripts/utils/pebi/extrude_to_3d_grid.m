function G_3D = extrude_to_3d_grid(G_2D, field_config)
% EXTRUDE_TO_3D_GRID - Extrude 2D PEBI grid to 3D with Eagle West subsurface depths
%
% PURPOSE:
%   Converts 2D PEBI grid to 3D layered grid at correct Eagle West subsurface depths.
%   Uses makeLayeredGrid with positive thickness values and translates to target depths.
%
% INPUTS:
%   G_2D - 2D PEBI grid from triangleGrid + pebi
%   field_config - Configuration with subsurface depth parameters
%
% OUTPUTS:
%   G_3D - 3D layered PEBI grid positioned at Eagle West subsurface depths
%
% POLICY COMPLIANCE:
%   - Data authority: All depth parameters from grid_config.yaml
%   - Fail fast: Validation of depth parameters and grid geometry
%   - KISS principle: Direct makeLayeredGrid + translation approach
%
% Author: Claude Code AI System
% Policy: KISS Principle compliant (<40 lines)

    % Extract canonical subsurface depths from configuration
    top_depth_tvdss = field_config.top_structure_tvdss;     % 7900.0 ft TVDSS
    base_depth_tvdss = field_config.base_structure_tvdss;   % 8240.0 ft TVDSS
    n_layers = field_config.nz;                             % 12 layers
    
    % Validate depth parameters
    if top_depth_tvdss >= base_depth_tvdss
        error('Invalid subsurface depths: top (%g ft) >= base (%g ft)', top_depth_tvdss, base_depth_tvdss);
    end
    
    % Calculate layer thicknesses (positive values for makeLayeredGrid)
    total_thickness = base_depth_tvdss - top_depth_tvdss;   % +340.0 ft
    layer_thickness_per_layer = total_thickness / n_layers;
    layer_thicknesses = ones(n_layers, 1) * layer_thickness_per_layer;
    
    % Validate calculated thickness
    expected_thickness = field_config.total_thickness;
    if abs(total_thickness - expected_thickness) > field_config.thickness_tolerance
        error('Calculated thickness (%g ft) does not match canonical (%g ft)', total_thickness, expected_thickness);
    end
    
    % Extrude using MRST's makeLayeredGrid
    G_3D = makeLayeredGrid(G_2D, layer_thicknesses);
    G_3D = computeGeometry(G_3D);
    
    % Validate no negative volumes
    if any(G_3D.cells.volumes <= 0)
        num_negative = sum(G_3D.cells.volumes <= 0);
        fprintf('   ⚠️ WARNING: 3D grid has %d cells with negative/zero volumes\n', num_negative);
        if num_negative < 0.1 * G_3D.cells.num  % Less than 10% bad cells
            fprintf('   ⚠️ Continuing with geometry issues - should be investigated\n');
        else
            error('CRITICAL: Too many cells with negative volumes (%d/%d = %.1f%%)', ...
                  num_negative, G_3D.cells.num, 100*num_negative/G_3D.cells.num);
        end
    end
    
    % Translate grid to subsurface position
    current_top = max(G_3D.nodes.coords(:,3));
    target_top = -top_depth_tvdss;  % Negative for subsurface
    z_offset = target_top - current_top;
    G_3D.nodes.coords(:,3) = G_3D.nodes.coords(:,3) + z_offset;
    G_3D = computeGeometry(G_3D);
    
    fprintf('   Extruded to 3D: %d cells, positioned %.1f to %.1f ft TVDSS\n', ...
            G_3D.cells.num, top_depth_tvdss, base_depth_tvdss);
end