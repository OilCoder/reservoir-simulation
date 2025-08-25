function export_grid_files(G_pebi)
% EXPORT_GRID_FILES - Export PEBI grid to simulation data catalog structure
%
% PURPOSE:
%   Exports PEBI grid following simulation data catalog specification.
%   Creates static_data.mat with grid geometry according to catalog requirements.
%
% INPUTS:
%   G_pebi - PEBI grid structure to export
%
% POLICY COMPLIANCE:
%   - Data authority: Uses catalog-specified file structure
%   - KISS principle: Simple file export without complex formatting
%   - No over-engineering: Direct .mat file saves
%
% Author: Claude Code AI System
% Policy: KISS Principle compliant (<30 lines)

    % CATALOG STRUCTURE: Save to /workspace/data/simulation_data/static/
    static_dir = '/workspace/data/simulation_data/static';
    if ~exist(static_dir, 'dir')
        mkdir(static_dir);
    end
    
    % Create static_data.mat according to catalog specification
    static_data_file = fullfile(static_dir, 'static_data.mat');
    
    % Grid Geometry (Section 1 of catalog)
    grid_x = G_pebi.nodes.coords(:,1);
    grid_y = G_pebi.nodes.coords(:,2);
    grid_z = G_pebi.nodes.coords(:,3);
    cell_centers_x = G_pebi.cells.centroids(:,1);
    cell_centers_y = G_pebi.cells.centroids(:,2);
    cell_centers_z = G_pebi.cells.centroids(:,3);
    
    % Well Configuration placeholders (will be populated by well scripts)
    well_names = {};
    well_i = [];
    well_j = [];
    well_k = [];
    well_types = {};
    
    % Save catalog-compliant static data
    save(static_data_file, 'grid_x', 'grid_y', 'grid_z', ...
         'cell_centers_x', 'cell_centers_y', 'cell_centers_z', ...
         'well_names', 'well_i', 'well_j', 'well_k', 'well_types', ...
         'G_pebi', '-v7');
    
    fprintf('     Static data saved to catalog location: %s\n', static_data_file);
    
    % Legacy compatibility
    try
        legacy_data_dir = get_data_path('static');
        if ~exist(legacy_data_dir, 'dir')
            mkdir(legacy_data_dir);
        end
        
        pebi_grid_file = fullfile(legacy_data_dir, 'pebi_grid.mat');
        save(pebi_grid_file, 'G_pebi');
        
        G = G_pebi;  % Compatible variable name
        refined_grid_file = fullfile(legacy_data_dir, 'refined_grid.mat');
        save(refined_grid_file, 'G');
        
        fprintf('     Legacy compatibility maintained\n');
    catch ME
        fprintf('Warning: Legacy export failed: %s\n', ME.message);
    end
end