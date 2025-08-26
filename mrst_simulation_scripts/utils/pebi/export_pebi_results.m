function pebi_data = export_pebi_results(G_pebi, well_points, fault_lines, size_function)
% EXPORT_PEBI_RESULTS - Export PEBI grid and create comprehensive output structure
%
% PURPOSE:
%   Exports PEBI grid to canonical file locations and creates comprehensive
%   output structure with statistics and validation information.
%
% INPUTS:
%   G_pebi - PEBI grid structure
%   well_points - Well locations and sizing data
%   fault_lines - Fault geometry data
%   size_function - Size function used for generation
%
% OUTPUTS:
%   pebi_data - Comprehensive PEBI grid package with statistics and validation
%
% POLICY COMPLIANCE:
%   - Data authority: Export paths follow canonical structure
%   - KISS principle: Simple export and statistics collection
%   - No over-engineering: Direct data structure creation
%
% Author: Claude Code AI System
% Policy: KISS Principle compliant (<30 lines)

    % Export grid to canonical file locations using consolidated data structure
    % CANON-FIRST POLICY: Contribute to grid.mat as specified in documentation
    save_consolidated_data('grid', 's03', 'G_pebi', G_pebi, 'well_points', well_points, 'fault_lines', fault_lines, 'size_function', size_function);
    
    % Create comprehensive output structure
    pebi_data = struct();
    pebi_data.grid = G_pebi;
    pebi_data.well_points = well_points;
    pebi_data.fault_lines = fault_lines;
    pebi_data.size_function = size_function;
    pebi_data.status = 'completed';
    
    % Add grid statistics
    pebi_data.statistics = struct();
    pebi_data.statistics.total_cells = G_pebi.cells.num;
    pebi_data.statistics.total_faces = G_pebi.faces.num;
    pebi_data.statistics.total_nodes = G_pebi.nodes.num;
    
    if isfield(G_pebi.cells, 'volumes')
        pebi_data.statistics.total_volume = sum(G_pebi.cells.volumes);
        pebi_data.statistics.min_cell_volume = min(G_pebi.cells.volumes);
        pebi_data.statistics.max_cell_volume = max(G_pebi.cells.volumes);
        pebi_data.statistics.avg_cell_volume = mean(G_pebi.cells.volumes);
    end
    
    % Add validation summary
    pebi_data.validation = struct();
    pebi_data.validation.grid_integrity = G_pebi.cells.num > 0 && G_pebi.faces.num > 0;
    pebi_data.validation.has_geometry = isfield(G_pebi.cells, 'volumes');
    pebi_data.validation.has_fault_properties = isfield(G_pebi.faces, 'fault_multiplier');
    pebi_data.validation.timestamp = datestr(now, 'yyyy-mm-dd HH:MM:SS');
    
    fprintf('   PEBI data export completed with statistics and validation\n');
end