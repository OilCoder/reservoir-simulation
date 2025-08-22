function fluid_complete = s11_pvt_tables()
% S11_PVT_TABLES - Define PVT tables for black oil simulation
    script_dir = fileparts(mfilename('fullpath'));
    addpath(fullfile(script_dir, 'utils')); 
    run(fullfile(script_dir, 'utils', 'print_utils.m'));

    % Add MRST session validation
    [success, message] = validate_mrst_session(script_dir);
    if ~success
        error('MRST validation failed: %s', message);
    end
    print_step_header('S11', 'Define PVT Tables (MRST Native)');
    
    total_start_time = tic;
    
    try
        % Step 1 – Load Dependencies
        step_start = tic;
        addpath('utils/pvt_processing');
        
        % NEW CANONICAL STRUCTURE: Load from fluid.mat and grid.mat
        fluid_file = '/workspace/data/mrst/fluid.mat';
        grid_file = '/workspace/data/mrst/grid.mat';
        
        if ~exist(fluid_file, 'file')
            error(['Missing canonical fluid file: fluid.mat\n' ...
                   'REQUIRED: Run s02-s10 workflow to generate fluid data.']);
        end
        if ~exist(grid_file, 'file')
            error(['Missing canonical grid file: grid.mat\n' ...
                   'REQUIRED: Run s03-s05 workflow to generate grid data.']);
        end
        
        % Load fluid with capillary pressure from canonical structure
        fluid_data = load(fluid_file, 'data_struct');
        
        % Reconstruct complete fluid structure from canonical data
        fluid_with_pc = fluid_data.data_struct.model;  % Base MRST fluid model
        if isfield(fluid_data.data_struct, 'relperm')
            % Add relative permeability functions
            fluid_with_pc.krW = fluid_data.data_struct.relperm.krw;
            fluid_with_pc.krO = fluid_data.data_struct.relperm.kro;
            fluid_with_pc.krG = fluid_data.data_struct.relperm.krg;
        end
        if isfield(fluid_data.data_struct, 'capillary')
            % Add capillary pressure functions
            fluid_with_pc.pcOW = fluid_data.data_struct.capillary.pcow;
            fluid_with_pc.pcOG = fluid_data.data_struct.capillary.pcog;
        end
        
        % Load grid from canonical structure
        grid_data = load(grid_file, 'data_struct');
        if isfield(grid_data.data_struct, 'fault_grid') && ~isempty(grid_data.data_struct.fault_grid)
            G = grid_data.data_struct.fault_grid;
        else
            G = grid_data.data_struct.G;
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
        
    catch ME
        fprintf('   ❌ PVT tables creation failed: %s\n', ME.message);
        rethrow(ME);
    end
end