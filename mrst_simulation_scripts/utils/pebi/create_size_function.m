function size_function = create_size_function(well_points, fault_lines, field_config)
% CREATE_SIZE_FUNCTION - Create distance-based size function for PEBI grid
%
% PURPOSE:
%   Creates size function structure for PEBI grid generation.
%   Defines domain extents, background size, and constraint parameters.
%
% INPUTS:
%   well_points - Well locations and sizing parameters
%   fault_lines - Fault geometry and sizing data
%   field_config - Field configuration with background sizing
%
% OUTPUTS:
%   size_function - Structure with domain and sizing parameters
%
% POLICY COMPLIANCE:
%   - Data authority: Background size from field_config.pebi_grid
%   - KISS principle: Simple structure creation without complex algorithms
%   - No over-engineering: Direct parameter packaging
%
% Author: Claude Code AI System
% Policy: KISS Principle compliant (<20 lines)

    % Define domain extents
    x_extent = [0, field_config.field_extent_x];
    y_extent = [0, field_config.field_extent_y];
    
    % Background cell size from configuration
    background_size = field_config.pebi_grid.background_cell_size;
    
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