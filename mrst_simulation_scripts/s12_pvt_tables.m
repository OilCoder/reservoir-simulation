function fluid_complete = s12_pvt_tables()
% S12_PVT_TABLES - Define PVT tables for black oil simulation
    addpath('utils'); run('utils/print_utils.m');
    print_step_header('S12', 'Define PVT Tables (MRST Native)');
    
    total_start_time = tic;
    
    try
        % Step 1 – Load Dependencies
        step_start = tic;
        addpath('utils/pvt_processing');
        
        fluid_file = '/workspaces/claudeclean/data/simulation_data/static/fluid/fluid_with_capillary_pressure.mat';
        grid_file = '/workspaces/claudeclean/data/simulation_data/static/grid/refined_grid.mat';
        
        if ~exist(fluid_file, 'file'), error('Run S11 first.'); end
        if ~exist(grid_file, 'file'), error('Run S06 first.'); end
        
        fluid_data = load(fluid_file); fluid_with_pc = fluid_data.fluid_with_pc;
        grid_data = load(grid_file); 
        if isfield(grid_data, 'G_refined')
            G = grid_data.G_refined;
        else
            G = grid_data.G;
        end
        pvt_config = load_pvt_config();
        print_step_result(1, 'Load Dependencies', toc(step_start), true);
        
        % Step 2 – Create PVT Tables
        step_start = tic;
        
        fluid_complete = create_pvt_tables(fluid_with_pc, pvt_config, G);
        print_step_result(2, 'Create PVT Tables', toc(step_start), true);
        
        % Step 3 – Export Complete Fluid
        step_start = tic;
        export_pvt_results(fluid_complete);
        print_step_result(3, 'Export Complete Fluid', toc(step_start), true);
        
        print_step_footer('S12', 'Complete MRST Fluid Ready for Black Oil Simulation', toc(total_start_time));
        
    catch ME
        fprintf('   ❌ PVT tables creation failed: %s\n', ME.message);
        rethrow(ME);
    end
end