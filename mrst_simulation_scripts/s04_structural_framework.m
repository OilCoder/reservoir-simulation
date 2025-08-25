function structural_data = s04_structural_framework()
% S04_STRUCTURAL_FRAMEWORK - Create geological structural framework for Eagle West Field
%
% PURPOSE:
%   Establishes the geological and structural framework for Eagle West Field reservoir model.
%   Defines anticline geometry, fault compartmentalization, and stratigraphic layering
%   required for PEBI grid construction and reservoir property distribution.
%   Provides structural foundation for 2,600-acre offshore field development.
%
% SCOPE:
%   - Anticline structural geometry definition and axis orientation
%   - Geological layer framework (12 layers, 8.3 ft average thickness)
%   - Compartment boundaries (Northern/Southern fault blocks)
%   - Structural depth relationships and crest definition
%   - Does NOT: Create actual grid geometry, fault planes, or rock properties
%
% WORKFLOW POSITION:
%   Fourth step in Eagle West Field MRST workflow sequence:
%   s01 (Initialize) → s02 (Fluids) → s03 (PEBI Grid) → s04 (Structure) → s05 (Faults)
%   Dependencies: s03 (PEBI grid) | Used by: s05 (fault system), s06 (refinement)
%
% INPUTS:
%   - data/static/pebi_grid.mat - PEBI grid from s03_create_pebi_grid.m
%   - config/structural_framework_config.yaml - Eagle West geological parameters
%   - MRST session from s01_initialize_mrst.m
%
% OUTPUTS:
%   structural_data - Geological framework structure containing:
%     .grid - Enhanced grid with structural properties
%     .surfaces - Anticline geometry and compartment definitions
%     .layers - Stratigraphic layer framework (12 layers)
%     .status - 'completed' when successful
%
% CONFIGURATION:
%   - structural_framework_config.yaml - Eagle West geological specification
%   - Key parameters: anticline axis trend, crest depth 7900 ft, structural relief 340 ft
%   - Layer configuration: 12 layers at 8.3 ft average thickness
%
% CANONICAL REFERENCE:
%   - Specification: obsidian-vault/Planning/Reservoir_Definition/01_Structural_Geology.md
%   - Implementation: Faulted anticline with 2 compartments, 238 ft gross thickness
%   - Canon-first: FAIL_FAST when structural configuration missing from YAML
%
% EXAMPLES:
%   % Create structural framework
%   structural_data = s04_structural_framework();
%   
%   % Verify anticline setup
%   fprintf('Anticline axis trend: %.1f degrees\n', structural_data.surfaces.anticline_axis.trend * 180/pi);
%   fprintf('Layer count: %d\n', structural_data.layers.n_layers);
%
% Author: Claude Code AI System
% Date: 2025-08-14 (Updated with comprehensive headers)
% Implementation: Eagle West Field MRST Workflow Phase 4

    script_dir = fileparts(mfilename('fullpath'));
    addpath(fullfile(script_dir, 'utils')); 
    run(fullfile(script_dir, 'utils', 'print_utils.m'));

    % Validate MRST session - basic check only
    if ~exist('cartGrid', 'file')
        error('MRST not initialized. Run s01_initialize_mrst() first.');
    end

    print_step_header('S04', 'Setup Structural Framework');
    
    total_start_time = tic;
    
    try
        % Add structural utilities to path
        addpath(fullfile(script_dir, 'utils', 'structural'));
        
        % Load configuration once for all operations
        config = load_structural_config();
        
        % Step 1 – Load Grid & Define Surfaces
        step_start = tic;
        G = load_structural_grid();
        surfaces = define_structural_surfaces(G);
        print_step_result(1, 'Load Grid & Define Surfaces', 'success', toc(step_start));
        
        % Step 2 – Apply Structural Framework  
        step_start = tic;
        layers = create_geological_layers(G, surfaces, config);
        G = apply_structural_framework(G, surfaces, layers);
        print_step_result(2, 'Apply Structural Framework', 'success', toc(step_start));
        
        % Step 3 – Export Framework
        step_start = tic;
        structural_data = export_structural_data(G, surfaces, layers);
        print_step_result(3, 'Validate & Export Framework', 'success', toc(step_start));
        
        print_step_footer('S04', 'Structural Framework Ready', toc(total_start_time));
        
    catch ME
        print_error_step(0, 'Structural Framework', ME.message);
        error('Structural framework failed: %s', ME.message);
    end

end



% Main execution when called as script
if ~nargout
    structural_data = s04_structural_framework();
end