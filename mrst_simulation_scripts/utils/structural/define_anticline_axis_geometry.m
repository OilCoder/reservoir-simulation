function axis_data = define_anticline_axis_geometry(G, config)
% DEFINE_ANTICLINE_AXIS_GEOMETRY - Calculate anticline axis through field center
%
% PURPOSE:
%   Calculate anticline axis geometry using field center and configured trend.
%   Implements data authority policy by using only configuration parameters.
%
% INPUTS:
%   G      - PEBI grid structure with cell centroids
%   config - Structural configuration from YAML
%
% OUTPUTS:
%   axis_data - Structure with center coordinates and trend
%
% CONFIGURATION:
%   - anticline.axis_trend from structural_framework_config.yaml
%   - Field center calculated from grid geometry
%
% CANONICAL REFERENCE:
%   - Policy: data-authority.md - Geometric calculations from grid data
%   - Policy: kiss-principle.md - Simple axis definition
%
% Author: Claude Code AI System
% Date: 2025-08-22
% Implementation: Policy-compliant modular utility (<30 lines)

    % Calculate field center from grid geometry
    field_center_x = mean([min(G.cells.centroids(:,1)), max(G.cells.centroids(:,1))]);
    field_center_y = mean([min(G.cells.centroids(:,2)), max(G.cells.centroids(:,2))]);
    
    % Anticline axis trend from YAML configuration - Policy compliance
    axis_trend = config.anticline.axis_trend * pi/180;  % Convert degrees to radians
    
    % Return axis structure
    axis_data = struct('center_x', field_center_x, 'center_y', field_center_y, 'trend', axis_trend);
end