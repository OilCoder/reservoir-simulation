function G_pebi = generate_triangular_grid(well_points, fault_lines, size_function, field_config)
% GENERATE_TRIANGULAR_GRID - Generate PEBI grid using triangleGrid + pebi approach
%
% PURPOSE:
%   Implements canonical triangleGrid + pebi approach for Eagle West Field.
%   Creates fault-conforming, well-optimized PEBI grid with proper validation.
%
% INPUTS:
%   well_points - Well locations and sizing parameters
%   fault_lines - Fault geometries and properties
%   size_function - Distance-based size function for point distribution
%   field_config - Field extents and validation parameters
%
% OUTPUTS:
%   G_pebi - MRST PEBI grid structure with computed geometry
%
% POLICY COMPLIANCE:
%   - No over-engineering: Simple triangleGrid + pebi workflow
%   - Fail fast: Immediate failure if PEBI generation fails
%   - KISS principle: Direct implementation without unnecessary abstraction
%
% Author: Claude Code AI System
% Policy: KISS Principle compliant (<40 lines)

    fprintf('   Generating PEBI grid using triangleGrid + pebi approach...\n');
    
    try
        % Generate well-constrained point distribution
        points = generate_well_constrained_points(well_points, fault_lines, field_config, size_function);
        
        % Clip points to field bounds to prevent coordinate expansion
        points(:,1) = max(0, min(points(:,1), field_config.field_extent_x));
        points(:,2) = max(0, min(points(:,2), field_config.field_extent_y));
        
        % Create Delaunay triangulation
        G_triangular = triangleGrid(points);
        G_triangular = computeGeometry(G_triangular);
        fprintf('   Triangular grid created: %d cells\n', G_triangular.cells.num);
        
        % Convert to PEBI (Voronoi dual)
        G_pebi = pebi(G_triangular);
        G_pebi = computeGeometry(G_pebi);
        fprintf('   PEBI grid generated: %d cells\n', G_pebi.cells.num);
        
        % Validate grid quality
        if isfield(G_pebi.cells, 'volumes')
            min_area = min(G_pebi.cells.volumes);
            if min_area <= 0
                error('PEBI grid has %d cells with non-positive areas', sum(G_pebi.cells.volumes <= 0));
            end
            fprintf('   2D PEBI areas: min=%.2e, max=%.2e ft²\n', min_area, max(G_pebi.cells.volumes));
        end
        
    catch ME
        error(['Failed to generate PEBI grid: %s\n' ...
               'REQUIRED: Eagle West Field requires true PEBI grid for accurate well representation.'], ME.message);
    end
    
    fprintf('   PEBI grid completed: %d cells, %d faces\n', G_pebi.cells.num, G_pebi.faces.num);
end