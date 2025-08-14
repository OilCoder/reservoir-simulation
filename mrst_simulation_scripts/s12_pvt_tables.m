function fluid_complete = s12_pvt_tables()
% S12_PVT_TABLES - Define PVT tables for black oil simulation
    script_dir = fileparts(mfilename('fullpath'));
    addpath(fullfile(script_dir, 'utils')); 
    run(fullfile(script_dir, 'utils', 'print_utils.m'));

    % Add MRST session validation
    [success, message] = validate_mrst_session(script_dir);
    if ~success
        error('MRST validation failed: %s', message);
    end
    print_step_header('S12', 'Define PVT Tables (MRST Native)');
    
    total_start_time = tic;
    
    try
        % Step 1 – Load Dependencies
        step_start = tic;
        addpath('utils/pvt_processing');
        
        data_dir = get_data_path('static');
        fluid_file = fullfile(data_dir, 'fluid', 'fluid_with_capillary_pressure.mat');
        grid_file = fullfile(data_dir, 'refined_grid.mat');
        
        if ~exist(fluid_file, 'file')
            error(['Missing canonical fluid file: fluid_with_capillary_pressure.mat\n' ...
                   'UPDATE CANON: obsidian-vault/Planning/Data_Pipeline.md\n' ...
                   'S11 must generate fluid_with_capillary_pressure.mat file.']);
        end
        if ~exist(grid_file, 'file')
            error(['Missing canonical grid file: refined_grid.mat\n' ...
                   'UPDATE CANON: obsidian-vault/Planning/Data_Pipeline.md\n' ...
                   'S06 must generate refined_grid.mat file.']);
        end
        
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