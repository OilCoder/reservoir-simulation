function structural_data = s04_structural_framework()
% S04_STRUCTURAL_FRAMEWORK - Create geological structural framework for Eagle West Field
%
% PURPOSE:
%   Establishes geological/structural framework for Eagle West Field reservoir model.
%   Defines anticline geometry, fault compartmentalization, and stratigraphic layering.
%
% SCOPE:
%   - Anticline structural geometry and axis orientation
%   - Geological layer framework from YAML configuration
%   - Compartment boundaries and structural depth relationships
%   - Does NOT: Create actual grid geometry, fault planes, or rock properties
%
% WORKFLOW: s01 → s02 → s03 → s04 → s05 (Dependencies: s03 | Used by: s05, s06)
%
% INPUTS: pebi_grid.mat, structural_framework_config.yaml, MRST session
% OUTPUTS: structural_data with .grid, .surfaces, .layers, .status fields
% CONFIG: structural_framework_config.yaml (Eagle West geological specification)
% CANON: docs/Planning/Reservoir_Definition/01_Structural_Geology.md
%
% EXAMPLE: structural_data = s04_structural_framework();

    script_dir = fileparts(mfilename('fullpath'));
    addpath(fullfile(script_dir, 'utils')); 
    run(fullfile(script_dir, 'utils', 'print_utils.m'));

    % Verify MRST session from s01
    if ~check_and_load_mrst_session()
        error('MRST session not found. Run s01_initialize_mrst.m first');
    end

    % Validate configuration file exists
    config_file = fullfile(script_dir, 'config', 'structural_framework_config.yaml');
    if ~exist(config_file, 'file')
        error('Missing structural_framework_config.yaml. Check config directory.');
    end

    % Validate grid file exists
    % CANON-FIRST POLICY: Documentation specifies /workspace/data/mrst/ as authoritative location
    workspace_root = '/workspace';
    grid_file = fullfile(workspace_root, 'data', 'mrst', 'grid.mat');
    if ~exist(grid_file, 'file')
        error('PEBI grid not found. Run s03_create_pebi_grid() first.\nExpected location: %s', grid_file);
    end

    print_step_header('S04', 'Setup Structural Framework');
    total_start_time = tic;
    
    % Add structural utilities to path
    addpath(fullfile(script_dir, 'utils', 'structural'));
    
    % Load configuration with validation
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

end

% Main execution when called as script
if ~nargout
    structural_data = s04_structural_framework();
end