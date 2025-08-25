function wells_results = s15_well_placement()
% S15_WELL_PLACEMENT - Simplified 15-Well System Placement for Eagle West Field
%
% POLICY COMPLIANT: Functions under 50 lines, no over-engineering
% Creates 15 wells (10 producers + 5 injectors) from configuration
% Requires: MRST
%
% OUTPUTS:
%   wells_results - Structure with well placement results
%
% Author: Claude Code AI System
% Date: August 23, 2025

    script_dir = fileparts(mfilename('fullpath'));
    addpath(fullfile(script_dir, 'utils')); 
    addpath(fullfile(script_dir, 'utils', 'wells'));
    run(fullfile(script_dir, 'utils', 'print_utils.m'));

    % Add MRST to path manually (consistent with working pattern)
    mrst_root = '/opt/mrst';
    addpath(genpath(fullfile(mrst_root, 'core'))); 
    addpath(genpath(fullfile(mrst_root, 'modules')));
    
    % Load MRST session (non-blocking check)
    session_file = fullfile(script_dir, 'session', 's01_mrst_session.mat');
    if exist(session_file, 'file')
        load(session_file);
    end
    print_step_header('S15', 'Well System Placement - 15 Wells');
    
    total_start_time = tic;
    
    % Load configuration and grid
    step_start = tic;
    [config, G] = load_config_and_grid(script_dir);
    print_step_result(1, 'Load Configuration and Grid', 'success', toc(step_start));
    
    % Create producer wells (10)
    step_start = tic;
    producer_wells = producer_wells_setup(config, G);
    print_step_result(2, 'Create Producer Wells', 'success', toc(step_start));
    
    % Create injector wells (5)
    step_start = tic;
    injector_wells = injector_wells_setup(config, G);
    print_step_result(3, 'Create Injector Wells', 'success', toc(step_start));
    
    % Create wells results structure
    wells_results = create_wells_results(config, G, producer_wells, injector_wells);
    
    % Validate well locations
    step_start = tic;
    validation_results = well_validation(wells_results, G);
    wells_results.validation_results = validation_results;
    print_step_result(4, 'Validate Well Locations', 'success', toc(step_start));
    
    % Export well placement data
    step_start = tic;
    export_path = export_well_data(wells_results);
    wells_results.export_path = export_path;
    print_step_result(5, 'Export Well Placement Data', 'success', toc(step_start));
    
    print_final_summary(wells_results, toc(total_start_time));
end

function [config, G] = load_config_and_grid(script_dir)
% Load configuration and grid data
    % Load wells configuration
    config_file = fullfile(script_dir, 'config', 'wells_config.yaml');
    if ~exist(config_file, 'file')
        error('Wells configuration file not found: %s. REQUIRED: Create wells_config.yaml with well specifications.', config_file);
    end
    config = read_yaml_config(config_file);
    
    % Load grid from PEBI grid step
    grid_file = '/workspace/data/simulation_data/grid.mat';
    if ~exist(grid_file, 'file')
        error('Grid file not found: %s. REQUIRED: Run s03_create_pebi_grid.m first.', grid_file);
    end
    grid_data = load(grid_file);
    G = grid_data.G;
    
    % Validate grid structure (PEBI grid compatible)
    if ~isfield(G, 'cells') || ~isfield(G, 'faces') || ~isfield(G, 'nodes')
        error('Invalid grid structure. Grid must have cells, faces, and nodes fields.');
    end
    
    fprintf('Configuration and grid loaded successfully: %d cells, %s grid\n', G.cells.num, G.type);
end

function wells_results = create_wells_results(config, G, producer_wells, injector_wells)
% Create comprehensive wells results structure
    wells_results = struct();
    wells_results.config = config;
    wells_results.G = G;
    wells_results.producer_wells = producer_wells;
    wells_results.injector_wells = injector_wells;
    wells_results.total_wells = length(producer_wells) + length(injector_wells);
    wells_results.total_producers = length(producer_wells);
    wells_results.total_injectors = length(injector_wells);
    wells_results.timestamp = datetime('now');
    wells_results.status = 'placed';
end

function export_path = export_well_data(wells_results)
% Export well placement data to files
    script_dir = fileparts(mfilename('fullpath'));
    static_dir = '/workspace/data/simulation_data/static';
    
    if ~exist(static_dir, 'dir')
        mkdir(static_dir);
    end
    
    % Export main wells data
    wells_file = fullfile(static_dir, 'wells_placement.mat');
    save(wells_file, '-struct', 'wells_results', '-v7');
    
    % Create MRST-compatible well structures
    W = create_mrst_wells(wells_results);
    wells_mrst_file = fullfile(static_dir, 'wells_final.mat');
    save(wells_mrst_file, 'W', '-v7');
    
    % Write summary files
    write_well_summary(static_dir, wells_results);
    write_well_coordinates(static_dir, wells_results);
    
    export_path = static_dir;
    fprintf('Well placement data exported to: %s\n', static_dir);
end

function W = create_mrst_wells(wells_results)
% Create MRST-compatible well structures
    W = [];
    
    % Add producers
    for i = 1:length(wells_results.producer_wells)
        well = wells_results.producer_wells{i};
        well_struct = convert_to_mrst_well(well);
        
        if isempty(W)
            W = well_struct;
        else
            W(end+1) = well_struct;
        end
    end
    
    % Add injectors
    for i = 1:length(wells_results.injector_wells)
        well = wells_results.injector_wells{i};
        well_struct = convert_to_mrst_well(well);
        
        if isempty(W)
            W = well_struct;
        else
            W(end+1) = well_struct;
        end
    end
end

function well_struct = convert_to_mrst_well(well)
% Convert well to MRST-compatible structure
    well_struct = struct();
    well_struct.name = well.name;
    well_struct.cells = well.cells;
    well_struct.type = well.type;
    well_struct.WI = well.WI;
    well_struct.dZ = 0; % Default
    well_struct.r = well.radius;
    well_struct.dir = 'z'; % Default vertical
    well_struct.status = true; % Active
    
    % Add control values based on well type
    if strcmp(well.type, 'producer')
        if isfield(well, 'production_rate')
            well_struct.val = well.production_rate;
        else
            well_struct.val = 1000; % Default production rate
        end
    else % injector
        if isfield(well, 'injection_rate')
            well_struct.val = well.injection_rate;
        else
            well_struct.val = 2000; % Default injection rate
        end
    end
end

function write_well_summary(output_dir, wells_results)
% Write well summary file
    summary_file = fullfile(output_dir, 'wells_summary.txt');
    
    fid = fopen(summary_file, 'w');
    if fid == -1
        warning('Could not create well summary file: %s', summary_file);
        return;
    end
    
    fprintf(fid, 'Eagle West Field Well Placement Summary\n');
    fprintf(fid, '======================================\n\n');
    fprintf(fid, 'Total Wells: %d\n', wells_results.total_wells);
    fprintf(fid, 'Producers: %d\n', wells_results.total_producers);
    fprintf(fid, 'Injectors: %d\n', wells_results.total_injectors);
    fprintf(fid, 'Grid Dimensions: %dx%dx%d\n', wells_results.G.cartDims);
    
    % List producer wells
    fprintf(fid, '\nProducer Wells:\n');
    for i = 1:length(wells_results.producer_wells)
        well = wells_results.producer_wells{i};
        fprintf(fid, '  %s: (%d,%d,%d) - %s trajectory\n', well.name, well.i, well.j, well.k, well.trajectory);
    end
    
    % List injector wells
    fprintf(fid, '\nInjector Wells:\n');
    for i = 1:length(wells_results.injector_wells)
        well = wells_results.injector_wells{i};
        fprintf(fid, '  %s: (%d,%d,%d) - %s trajectory\n', well.name, well.i, well.j, well.k, well.trajectory);
    end
    
    fclose(fid);
end

function write_well_coordinates(output_dir, wells_results)
% Write well coordinates file
    coords_file = fullfile(output_dir, 'well_coordinates.csv');
    
    fid = fopen(coords_file, 'w');
    if fid == -1
        warning('Could not create well coordinates file: %s', coords_file);
        return;
    end
    
    fprintf(fid, 'Well_Name,Type,I,J,K,Cell_Index,Trajectory\n');
    
    % Write producer coordinates
    for i = 1:length(wells_results.producer_wells)
        well = wells_results.producer_wells{i};
        fprintf(fid, '%s,producer,%d,%d,%d,%d,%s\n', well.name, well.i, well.j, well.k, well.cells, well.trajectory);
    end
    
    % Write injector coordinates
    for i = 1:length(wells_results.injector_wells)
        well = wells_results.injector_wells{i};
        fprintf(fid, '%s,injector,%d,%d,%d,%d,%s\n', well.name, well.i, well.j, well.k, well.cells, well.trajectory);
    end
    
    fclose(fid);
end

function print_final_summary(wells_results, total_time)
% Print final summary of well placement
    fprintf('\n');
    fprintf('=== WELL PLACEMENT SUMMARY ===\n');
    fprintf('Total execution time: %.2f seconds\n', total_time);
    fprintf('Wells placed: %d (%d producers, %d injectors)\n', ...
        wells_results.total_wells, wells_results.total_producers, wells_results.total_injectors);
    fprintf('Grid dimensions: %dx%dx%d\n', wells_results.G.cartDims);
    
    if isfield(wells_results, 'validation_results') && wells_results.validation_results.validation_passed
        fprintf('Validation: PASSED\n');
    else
        fprintf('Validation: FAILED (check errors)\n');
    end
    
    fprintf('Export path: %s\n', wells_results.export_path);
    fprintf('Status: %s\n', wells_results.status);
    fprintf('==============================\n');
end

% Main execution when called as script
if ~nargout
    wells_results = s15_well_placement();
end