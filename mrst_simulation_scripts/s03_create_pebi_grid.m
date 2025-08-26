function pebi_data = s03_create_pebi_grid()
% S03_CREATE_PEBI_GRID - Create fault-conforming PEBI grid for Eagle West Field (REFACTORED)
%
% PURPOSE:
%   Coordinator function for PEBI grid generation using modular utilities.
%   Implements all 6 policies: canon-first, data authority, fail fast, 
%   exception handling, KISS principle, and no over-engineering.
%
% OUTPUTS:
%   pebi_data - Complete PEBI grid package with statistics and validation
%
% POLICY COMPLIANCE:
%   - KISS principle: Main function under 50 lines, delegates to utilities
%   - No over-engineering: Simple coordinator without complex logic
%   - Canon-first: All configuration from authoritative YAML sources
%   - Data authority: No hardcoded values, configuration-driven approach
%   - Fail fast: Immediate validation at each step
%
% REFACTORING NOTES:
%   Original 1300+ line file broken into 7 modular utilities in utils/pebi/
%   Each utility function under policy line limits (<30-40 lines)
%   Eliminates magic numbers through geometry_parameters configuration
%
% Author: Claude Code AI System
% Date: 2025-08-22 (Policy compliance refactoring)

    script_dir = fileparts(mfilename('fullpath'));
    addpath(fullfile(script_dir, 'utils')); 
    addpath(fullfile(script_dir, 'utils', 'pebi'));
    run(fullfile(script_dir, 'utils', 'print_utils.m'));

    % Verify MRST session from s01
    if ~check_and_load_mrst_session()
        error('MRST session not found. Run s01_initialize_mrst.m first');
    end

    print_step_header('S03', 'Create PEBI Grid (Refactored)');
    total_start_time = tic;
    
    try
        % Step 1: Load all configurations (canon-first)
        step_start = tic;
        [field_config, wells_config, fault_config] = load_pebi_configuration();
        print_step_result(1, 'Load Configuration', 'success', toc(step_start));
        
        % Step 2: Extract well locations and fault geometries
        step_start = tic;
        well_points = extract_well_locations(wells_config, field_config);
        fault_lines = extract_fault_geometries(fault_config, field_config);
        print_step_result(2, 'Extract Well/Fault Geometries', 'success', toc(step_start));
        
        % Step 3: Create size function for point distribution
        step_start = tic;
        size_function = create_size_function(well_points, fault_lines, field_config);
        print_step_result(3, 'Create Size Function', 'success', toc(step_start));
        
        % Step 4: Generate 2D PEBI grid using triangleGrid + pebi
        step_start = tic;
        G_2D = generate_triangular_grid(well_points, fault_lines, size_function, field_config);
        print_step_result(4, 'Generate 2D PEBI Grid', 'success', toc(step_start));
        
        % Step 5: Apply fault properties to grid faces
        step_start = tic;
        G_2D = position_at_depths(G_2D, fault_lines, fault_config);
        print_step_result(5, 'Apply Fault Properties', 'success', toc(step_start));
        
        % Step 6: Extrude to 3D grid at Eagle West depths
        step_start = tic;
        G_3D = extrude_to_3d_grid(G_2D, field_config);
        print_step_result(6, 'Extrude to 3D Grid', 'success', toc(step_start));
        
        % Step 7: Validate and export complete grid
        step_start = tic;
        validate_pebi_grid(G_3D, well_points, fault_lines);
        pebi_data = export_pebi_results(G_3D, well_points, fault_lines, size_function);
        print_step_result(7, 'Validate and Export', 'success', toc(step_start));
        
        print_step_footer('S03', sprintf('PEBI Grid: %d cells, %d faces', G_3D.cells.num, G_3D.faces.num), toc(total_start_time));
        
    catch ME
        print_error_step(0, 'PEBI Grid Creation', ME.message);
        error('PEBI grid creation failed: %s', ME.message);
    end
end

% Main execution
if ~nargout
    pebi_data = s03_create_pebi_grid();
    fprintf('Refactored PEBI grid creation completed!\n\n');
end