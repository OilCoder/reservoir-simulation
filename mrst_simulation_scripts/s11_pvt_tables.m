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
        
        % Use canonical data organization pattern
        base_data_path = fullfile(fileparts(fileparts(mfilename('fullpath'))), 'data');
        canonical_data_dir = fullfile(base_data_path, 'by_type', 'static');
        fluid_file = fullfile(canonical_data_dir, 'fluid_capillary_s10.mat');
        grid_file = fullfile(canonical_data_dir, 'pebi_grid_s03.mat');
        
        if ~exist(fluid_file, 'file')
            error(['Missing canonical fluid file: fluid_capillary_s10.mat\n' ...
                   'UPDATE CANON: obsidian-vault/Planning/Data_Pipeline.md\n' ...
                   'S10 must generate fluid_capillary_s10.mat file in canonical location:\n' ...
                   '%s'], fluid_file);
        end
        if ~exist(grid_file, 'file')
            error(['Missing canonical grid file: pebi_grid_s03.mat\n' ...
                   'UPDATE CANON: obsidian-vault/Planning/Data_Pipeline.md\n' ...
                   'S03 must generate pebi_grid_s03.mat file in canonical location:\n' ...
                   '%s'], grid_file);
        end
        
        % Load fluid with capillary pressure from s10
        fluid_data = load(fluid_file); 
        if isfield(fluid_data, 'fluid_with_pc')
            fluid_with_pc = fluid_data.fluid_with_pc;
        else
            error(['Invalid fluid file structure. Expected variable: fluid_with_pc\n' ...
                   'UPDATE CANON: obsidian-vault/Planning/Data_Pipeline.md\n' ...
                   'S10 must save fluid_with_pc variable in canonical format.']);
        end
        
        % Load PEBI grid from s03
        grid_data = load(grid_file); 
        if isfield(grid_data, 'G_pebi')
            G = grid_data.G_pebi;
        elseif isfield(grid_data, 'G')
            G = grid_data.G;
        else
            error(['Invalid grid file structure. Expected variable: G_pebi or G\n' ...
                   'UPDATE CANON: obsidian-vault/Planning/Data_Pipeline.md\n' ...
                   'S03 must save G_pebi variable in canonical format.']);
        end
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