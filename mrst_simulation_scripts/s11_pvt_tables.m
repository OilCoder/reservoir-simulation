function fluid_complete = s11_pvt_tables()
% S11_PVT_TABLES - Define PVT tables for black oil simulation
    script_dir = fileparts(mfilename('fullpath'));
    addpath(fullfile(script_dir, 'utils')); 
    run(fullfile(script_dir, 'utils', 'print_utils.m'));

    % Verify MRST session from s01
    if ~check_and_load_mrst_session()
        error('MRST session not found. Run s01_initialize_mrst.m first');
    end
    % WARNING SUPPRESSION: Complete silence for clean output
    warning('off', 'all');
    print_step_header('S11', 'Define PVT Tables (MRST Native)');
    
    total_start_time = tic;
    
    % Step 1 – Load Dependencies
    step_start = tic;
    addpath(fullfile(script_dir, 'utils', 'pvt_processing'));
    
    % Load from canonical data structure (Canon-First Policy)
    fluid_file = '/workspace/data/mrst/fluid.mat';
    grid_file = '/workspace/data/mrst/grid.mat';
    
    % Explicit validation before loading files
    if ~exist(fluid_file, 'file')
        error(['Missing consolidated fluid file: %s\n' ...
               'REQUIRED: Run s02-s10 workflow to generate fluid data.'], fluid_file);
    end
    if ~exist(grid_file, 'file')
        error(['Missing consolidated grid file: %s\n' ...
               'REQUIRED: Run s03-s05 workflow to generate grid data.'], grid_file);
    end
    
    % Load fluid with capillary pressure from consolidated structure
    fluid_data = load(fluid_file);
    
    % Validate fluid data structure
    if ~isfield(fluid_data, 'fluid')
        error(['Invalid fluid file structure: missing fluid\n' ...
               'REQUIRED: Re-run s02-s10 workflow to regenerate fluid.mat']);
    end
    
    % Load complete fluid structure from consolidated data
    fluid = fluid_data.fluid;
    fluid_with_pc = fluid_data.fluid;  % Complete MRST fluid model with relperm and capillary
    % Note: fluid already contains krW, krO, krG from s09 and pcOW, pcOG from s10
    
    % Load grid from consolidated structure
    grid_data = load(grid_file);
    
    % Load grid from consolidated data structure
    if isfield(grid_data, 'fault_grid') && ~isempty(grid_data.fault_grid)
        G = grid_data.fault_grid;
    elseif isfield(grid_data, 'G')
        G = grid_data.G;
    else
        error(['Missing grid structure in grid.mat\n' ...
               'REQUIRED: Re-run s03-s05 workflow to create valid grid structure']);
    end
    
    fprintf('   ✅ Loading from canonical MRST structure\n');
    pvt_config = load_pvt_config();
    print_step_result(1, 'Load Dependencies', 'success', toc(step_start));
    
    % Step 2 – Create PVT Tables
    step_start = tic;
    
    fluid_complete = create_pvt_tables(fluid_with_pc, pvt_config, G);
    print_step_result(2, 'Create PVT Tables', 'success', toc(step_start));
    
    % Step 3 – Export Complete Fluid
    step_start = tic;
    export_pvt_results(fluid_complete);
    print_step_result(3, 'Export Complete Fluid', 'success', toc(step_start));
    
    print_step_footer('S11', 'Complete MRST Fluid Ready for Black Oil Simulation', toc(total_start_time));
end