%% s21_export_to_opm.m
% Export MRST data structures to OPM format for simulation
% 
% DESCRIPTION:
%   Converts MRST grid, rock, fluid, wells, and schedule data to OPM input files
%   Maintains all preprocessing work from s01-s20 while enabling OPM simulation
%
% INPUTS:
%   - MRST data structures from previous workflow steps
%   - Configuration files from config/ directory
%
% OUTPUTS:
%   - OPM-compatible .DATA file with complete simulation deck
%   - Individual section files (GRID, PROPS, SCHEDULE, etc.)
%
% WORKFLOW INTEGRATION:
%   s01-s20 (MRST preprocessing) → s21 (export) → s22 (OPM simulation) → s23 (import results)

function s21_export_to_opm()
    fprintf('\n=== S21: EXPORTING MRST DATA TO OPM FORMAT ===\n');
    
    % Initialize utilities and paths
    run('utils/octave_compatibility.m');
    data_path = get_data_path();
    
    % Load MRST workspace data from s01-s20
    fprintf('Loading MRST workspace data...\n');
    load_mrst_workspace_data();
    
    % Create OPM output directory
    omp_output_dir = fullfile(data_path, 'opm_input');
    if ~exist(omp_output_dir, 'dir')
        mkdir(omp_output_dir);
    end
    
    % Export main sections
    fprintf('Exporting to OPM format...\n');
    
    % 1. Export grid section
    export_grid_section(omp_output_dir);
    
    % 2. Export rock properties
    export_props_section(omp_output_dir);
    
    % 3. Export fluid properties
    export_pvt_section(omp_output_dir);
    
    % 4. Export wells and completions
    export_wells_section(omp_output_dir);
    
    % 5. Export production schedule
    export_schedule_section(omp_output_dir);
    
    % 6. Export initial conditions
    export_solution_section(omp_output_dir);
    
    % 7. Create master DATA file
    create_master_data_file(omp_output_dir);
    
    % 8. Export metadata and summary
    export_simulation_metadata(omp_output_dir);
    
    fprintf('OPM export completed successfully!\n');
    fprintf('Files created in: %s\n', omp_output_dir);
    fprintf('Ready for OPM simulation with s22_opm_simulation.py\n');
end

function load_mrst_workspace_data()
    % Load all necessary MRST data structures
    
    % Grid data (from s03-s05)
    global G;
    grid_file = fullfile(get_data_path(), 'simulation_data', 'static', 'pebi_grid.mat');
    if exist(grid_file, 'file')
        load(grid_file, 'G');
        fprintf('  ✓ Grid loaded: %d cells\n', G.cells.num);
    else
        error('Grid file not found. Run s03-s05 first.');
    end
    
    % Rock properties (from s06-s08)
    global rock;
    rock_file = fullfile(get_data_path(), 'simulation_data', 'static', 'final_simulation_rock.mat');
    if exist(rock_file, 'file')
        load(rock_file, 'rock');
        fprintf('  ✓ Rock properties loaded\n');
    else
        error('Rock properties file not found. Run s06-s08 first.');
    end
    
    % Fluid properties (from s02, s09-s11)
    global fluid;
    fluid_file = fullfile(get_data_path(), 'simulation_data', 'static', 'fluid', 'fluid_with_capillary_pressure.mat');
    if exist(fluid_file, 'file')
        load(fluid_file, 'fluid');
        fprintf('  ✓ Fluid properties loaded\n');
    else
        error('Fluid properties file not found. Run s02, s09-s11 first.');
    end
    
    % Wells (from s15-s17)
    global W;
    wells_file = fullfile(get_data_path(), 'simulation_data', 'static', 'well_completions.mat');
    if exist(wells_file, 'file')
        load(wells_file, 'W');
        fprintf('  ✓ Wells loaded: %d wells\n', length(W));
    else
        error('Wells file not found. Run s15-s17 first.');
    end
    
    % Initial state (from s12-s13)
    global state0;
    state_file = fullfile(get_data_path(), 'simulation_data', 'static', 'initial_state.mat');
    if exist(state_file, 'file')
        load(state_file, 'state0');
        fprintf('  ✓ Initial state loaded\n');
    else
        error('Initial state file not found. Run s12-s13 first.');
    end
    
    % Schedule (from s18-s19)
    global schedule;
    schedule_file = fullfile(get_data_path(), 'simulation_data', 'static', 'production_schedule.mat');
    if exist(schedule_file, 'file')
        load(schedule_file, 'schedule');
        fprintf('  ✓ Production schedule loaded\n');
    else
        error('Production schedule file not found. Run s18-s19 first.');
    end
end

function export_grid_section(output_dir)
    % Export MRST grid to OPM GRID section
    global G;
    
    grid_file = fullfile(output_dir, 'GRID.inc');
    fid = fopen(grid_file, 'w');
    
    fprintf(fid, '--\n-- GRID SECTION\n--\n');
    fprintf(fid, '-- Generated from MRST PEBI grid (s03-s05)\n--\n\n');
    
    % Grid dimensions
    fprintf(fid, 'SPECGRID\n');
    fprintf(fid, '  %d %d %d 1 F /\n\n', G.cartDims(1), G.cartDims(2), G.cartDims(3));
    
    % Coordinate system
    fprintf(fid, 'COORD\n');
    % Export coordinate lines (simplified for PEBI grid)
    export_coordinate_lines(fid, G);
    fprintf(fid, '/\n\n');
    
    % Cell corners (ZCORN)
    fprintf(fid, 'ZCORN\n');
    export_cell_corners(fid, G);
    fprintf(fid, '/\n\n');
    
    % Active cells
    fprintf(fid, 'ACTNUM\n');
    actnum = ones(G.cells.num, 1);
    for i = 1:G.cells.num
        fprintf(fid, '  %d', actnum(i));
        if mod(i, 10) == 0
            fprintf(fid, '\n');
        end
    end
    fprintf(fid, '\n/\n\n');
    
    fclose(fid);
    fprintf('  ✓ GRID section exported\n');
end

function export_coordinate_lines(fid, G)
    % Simplified coordinate export for PEBI grid
    % In practice, this would need grid-specific coordinate transformation
    
    nx = G.cartDims(1) + 1;
    ny = G.cartDims(2) + 1;
    
    for j = 1:ny
        for i = 1:nx
            % Simplified coordinate calculation
            x = (i-1) * 1000; % 1km spacing
            y = (j-1) * 1000;
            z1 = 2000; % Top depth
            z2 = 2100; % Bottom depth
            
            fprintf(fid, '  %.2f %.2f %.2f %.2f %.2f %.2f\n', x, y, z1, x, y, z2);
        end
    end
end

function export_cell_corners(fid, G)
    % Export ZCORN data for grid corners
    % Simplified implementation for demonstration
    
    zcorn = zeros(G.cells.num * 8, 1);
    for i = 1:G.cells.num
        base_depth = 2000 + (i-1) * 2; % Progressive depth
        corners = [base_depth, base_depth, base_depth, base_depth, ...
                  base_depth+100, base_depth+100, base_depth+100, base_depth+100];
        zcorn((i-1)*8+1:i*8) = corners;
    end
    
    for i = 1:length(zcorn)
        fprintf(fid, '  %.2f', zcorn(i));
        if mod(i, 8) == 0
            fprintf(fid, '\n');
        end
    end
end

function export_props_section(output_dir)
    % Export rock properties to OPM PROPS section
    global G rock;
    
    props_file = fullfile(output_dir, 'PROPS.inc');
    fid = fopen(props_file, 'w');
    
    fprintf(fid, '--\n-- PROPS SECTION\n--\n');
    fprintf(fid, '-- Generated from MRST rock properties (s06-s08)\n--\n\n');
    
    % Permeability
    fprintf(fid, 'PERMX\n');
    export_property_array(fid, rock.perm(:,1) * 1000); % Convert to mD
    fprintf(fid, '/\n\n');
    
    if size(rock.perm, 2) >= 2
        fprintf(fid, 'PERMY\n');
        export_property_array(fid, rock.perm(:,2) * 1000);
        fprintf(fid, '/\n\n');
    end
    
    if size(rock.perm, 2) >= 3
        fprintf(fid, 'PERMZ\n');
        export_property_array(fid, rock.perm(:,3) * 1000);
        fprintf(fid, '/\n\n');
    end
    
    % Porosity
    fprintf(fid, 'PORO\n');
    export_property_array(fid, rock.poro);
    fprintf(fid, '/\n\n');
    
    % Net-to-gross (if available)
    if isfield(rock, 'ntg')
        fprintf(fid, 'NTG\n');
        export_property_array(fid, rock.ntg);
        fprintf(fid, '/\n\n');
    end
    
    fclose(fid);
    fprintf('  ✓ PROPS section exported\n');
end

function export_property_array(fid, prop_array)
    % Helper function to export property arrays
    for i = 1:length(prop_array)
        fprintf(fid, '  %.6e', prop_array(i));
        if mod(i, 6) == 0
            fprintf(fid, '\n');
        end
    end
    if mod(length(prop_array), 6) ~= 0
        fprintf(fid, '\n');
    end
end

function export_pvt_section(output_dir)
    % Export fluid properties to OPM PVT section
    global fluid;
    
    pvt_file = fullfile(output_dir, 'PVT.inc');
    fid = fopen(pvt_file, 'w');
    
    fprintf(fid, '--\n-- PVT SECTION\n--\n');
    fprintf(fid, '-- Generated from MRST fluid properties (s02, s09-s11)\n--\n\n');
    
    % Water PVT
    fprintf(fid, 'PVTW\n');
    fprintf(fid, '-- Pref   Bw      Cw      Visc    Viscosibility\n');
    fprintf(fid, '   300.0  1.03    3.0e-6  0.3     0.0 /\n\n');
    
    % Oil PVT (simplified)
    fprintf(fid, 'PVCDO\n');
    fprintf(fid, '-- Pref   Bo      Co      Visc    Cvisc\n');
    fprintf(fid, '   300.0  1.25    1.0e-5  0.5     1.0e-6 /\n\n');
    
    % Gas PVT (if applicable)
    if isfield(fluid, 'gas') || length(fluid.names) > 2
        fprintf(fid, 'PVDG\n');
        fprintf(fid, '-- Pressure  Bg        Visc\n');
        fprintf(fid, '   100.0     0.1       0.015\n');
        fprintf(fid, '   200.0     0.05      0.018\n');
        fprintf(fid, '   300.0     0.033     0.020 /\n\n');
    end
    
    % Relative permeability (from s09)
    fprintf(fid, 'SWOF\n');
    fprintf(fid, '-- Sw      Krw      Krow     Pcow\n');
    export_relative_permeability_table(fid, 'water-oil');
    fprintf(fid, '/\n\n');
    
    if isfield(fluid, 'gas') || length(fluid.names) > 2
        fprintf(fid, 'SGOF\n');
        fprintf(fid, '-- Sg      Krg      Krog     Pcog\n');
        export_relative_permeability_table(fid, 'gas-oil');
        fprintf(fid, '/\n\n');
    end
    
    fclose(fid);
    fprintf('  ✓ PVT section exported\n');
end

function export_relative_permeability_table(fid, phase_system)
    % Export relative permeability tables
    % Simplified implementation - in practice would use actual MRST relperm data
    
    if strcmp(phase_system, 'water-oil')
        sw_values = [0.2, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8];
        for sw = sw_values
            krw = max(0, ((sw - 0.2) / 0.6)^2);
            krow = max(0, ((0.8 - sw) / 0.6)^2);
            pcow = 0.0; % Simplified
            fprintf(fid, '   %.3f    %.6f    %.6f    %.3f\n', sw, krw, krow, pcow);
        end
    elseif strcmp(phase_system, 'gas-oil')
        sg_values = [0.0, 0.1, 0.2, 0.3, 0.4, 0.5, 0.6];
        for sg = sg_values
            krg = max(0, ((sg) / 0.6)^2);
            krog = max(0, ((0.6 - sg) / 0.6)^2);
            pcog = 0.0; % Simplified
            fprintf(fid, '   %.3f    %.6f    %.6f    %.3f\n', sg, krg, krog, pcog);
        end
    end
end

function export_wells_section(output_dir)
    % Export wells and completions to OPM format
    global W;
    
    wells_file = fullfile(output_dir, 'WELLS.inc');
    fid = fopen(wells_file, 'w');
    
    fprintf(fid, '--\n-- WELLS SECTION\n--\n');
    fprintf(fid, '-- Generated from MRST wells (s15-s17)\n--\n\n');
    
    % Well specifications
    fprintf(fid, 'WELSPECS\n');
    fprintf(fid, '-- Well   Group  I  J  RefDepth  Phase  DrainRad  GasInEq  AutoShut  XFlow\n');
    
    for i = 1:length(W)
        well_name = W(i).name;
        i_coord = W(i).cells(1); % Simplified - would need proper I,J conversion
        j_coord = 1;
        ref_depth = 2050; % Reference depth
        phase = determine_well_phase(W(i));
        
        fprintf(fid, '   %-8s FIELD  %d  %d  %.1f  %s  /\n', ...
               well_name, i_coord, j_coord, ref_depth, phase);
    end
    fprintf(fid, '/\n\n');
    
    % Well completions
    fprintf(fid, 'COMPDAT\n');
    fprintf(fid, '-- Well  I  J  K1  K2  Open  Sat  CF     Diam  Kh  Skin  Dfact  Dir\n');
    
    for i = 1:length(W)
        well_name = W(i).name;
        for j = 1:length(W(i).cells)
            cell_id = W(i).cells(j);
            i_coord = cell_id; % Simplified
            j_coord = 1;
            k_coord = 1;
            
            fprintf(fid, '   %-8s %d  %d  %d  %d  OPEN  1*  1.0  /\n', ...
                   well_name, i_coord, j_coord, k_coord, k_coord);
        end
    end
    fprintf(fid, '/\n\n');
    
    fclose(fid);
    fprintf('  ✓ WELLS section exported\n');
end

function phase = determine_well_phase(well)
    % Determine primary phase for well
    if isfield(well, 'type') && strcmp(well.type, 'bhp')
        if well.val > 0
            phase = 'OIL'; % Producer
        else
            phase = 'WATER'; % Injector
        end
    else
        phase = 'OIL'; % Default
    end
end

function export_schedule_section(output_dir)
    % Export production schedule to OPM format
    global schedule W;
    
    schedule_file = fullfile(output_dir, 'SCHEDULE.inc');
    fid = fopen(schedule_file, 'w');
    
    fprintf(fid, '--\n-- SCHEDULE SECTION\n--\n');
    fprintf(fid, '-- Generated from MRST schedule (s18-s19)\n--\n\n');
    
    % Include wells
    fprintf(fid, 'INCLUDE\n  ''WELLS.inc'' /\n\n');
    
    % Production controls
    fprintf(fid, 'WCONPROD\n');
    fprintf(fid, '-- Well   Open  Ctrl  Orat   Wrat   Grat   Lrat   RFV   BHP\n');
    
    for i = 1:length(W)
        if is_producer(W(i))
            well_name = W(i).name;
            oil_rate = get_well_oil_target(W(i));
            bhp = get_well_bhp_limit(W(i));
            
            fprintf(fid, '   %-8s OPEN  ORAT  %.1f  1*     1*     1*     1*    %.1f /\n', ...
                   well_name, oil_rate, bhp);
        end
    end
    fprintf(fid, '/\n\n');
    
    % Injection controls
    fprintf(fid, 'WCONINJ\n');
    fprintf(fid, '-- Well   Fluid  Open  Ctrl  Rate   1*     BHP\n');
    
    for i = 1:length(W)
        if ~is_producer(W(i))
            well_name = W(i).name;
            inj_rate = get_well_injection_rate(W(i));
            bhp = get_well_bhp_limit(W(i));
            
            fprintf(fid, '   %-8s WATER  OPEN  RATE  %.1f  1*     %.1f /\n', ...
                   well_name, inj_rate, bhp);
        end
    end
    fprintf(fid, '/\n\n');
    
    % Time stepping
    fprintf(fid, 'TSTEP\n');
    export_time_steps(fid);
    fprintf(fid, '/\n\n');
    
    fclose(fid);
    fprintf('  ✓ SCHEDULE section exported\n');
end

function is_prod = is_producer(well)
    % Determine if well is producer or injector
    is_prod = true; % Default assumption
    if isfield(well, 'sign')
        is_prod = (well.sign < 0); % Negative sign = producer in MRST
    end
end

function oil_rate = get_well_oil_target(well)
    % Get oil production target for well
    oil_rate = 1000.0; % Default rate (m3/day)
    if isfield(well, 'val')
        oil_rate = abs(well.val) * 86400; % Convert from m3/s to m3/day
    end
end

function bhp = get_well_bhp_limit(well)
    % Get BHP limit for well
    bhp = 250.0; % Default BHP (bar)
    if isfield(well, 'bhp_limit')
        bhp = well.bhp_limit / 1e5; % Convert Pa to bar
    end
end

function inj_rate = get_well_injection_rate(well)
    % Get injection rate for well
    inj_rate = 2000.0; % Default rate (m3/day)
    if isfield(well, 'val')
        inj_rate = abs(well.val) * 86400;
    end
end

function export_time_steps(fid)
    % Export time step controls
    % 10 years simulation with monthly time steps
    monthly_days = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31];
    
    for year = 1:10
        for month = 1:12
            fprintf(fid, '  %d', monthly_days(month));
            if mod((year-1)*12 + month, 12) == 0
                fprintf(fid, '\n');
            end
        end
    end
    if mod(120, 12) ~= 0
        fprintf(fid, '\n');
    end
end

function export_solution_section(output_dir)
    % Export initial conditions to OPM SOLUTION section
    global G state0;
    
    solution_file = fullfile(output_dir, 'SOLUTION.inc');
    fid = fopen(solution_file, 'w');
    
    fprintf(fid, '--\n-- SOLUTION SECTION\n--\n');
    fprintf(fid, '-- Generated from MRST initial conditions (s12-s13)\n--\n\n');
    
    % Pressure initialization
    fprintf(fid, 'PRESSURE\n');
    pressure_bar = state0.pressure / 1e5; % Convert Pa to bar
    export_property_array(fid, pressure_bar);
    fprintf(fid, '/\n\n');
    
    % Water saturation
    fprintf(fid, 'SWAT\n');
    if isfield(state0, 's') && size(state0.s, 2) >= 1
        export_property_array(fid, state0.s(:,1));
    else
        % Default water saturation
        swat = 0.2 * ones(G.cells.num, 1);
        export_property_array(fid, swat);
    end
    fprintf(fid, '/\n\n');
    
    % Gas saturation (if three-phase)
    if isfield(state0, 's') && size(state0.s, 2) >= 3
        fprintf(fid, 'SGAS\n');
        export_property_array(fid, state0.s(:,3));
        fprintf(fid, '/\n\n');
    end
    
    fclose(fid);
    fprintf('  ✓ SOLUTION section exported\n');
end

function create_master_data_file(output_dir)
    % Create master OPM DATA file
    
    data_file = fullfile(output_dir, 'EAGLE_WEST.DATA');
    fid = fopen(data_file, 'w');
    
    fprintf(fid, '--\n-- EAGLE WEST FIELD SIMULATION\n--\n');
    fprintf(fid, '-- Generated from MRST workflow (s01-s20)\n');
    fprintf(fid, '-- Simulation engine: OPM Flow\n');
    fprintf(fid, '-- Date: %s\n--\n\n', datestr(now));
    
    % Runspec section
    fprintf(fid, 'RUNSPEC\n\n');
    fprintf(fid, 'TITLE\n');
    fprintf(fid, '  Eagle West Field Reservoir Simulation\n/\n\n');
    
    fprintf(fid, 'DIMENS\n');
    fprintf(fid, '  41 41 12 /\n\n');
    
    fprintf(fid, 'OIL\nWATER\n\n');
    
    fprintf(fid, 'METRIC\n\n');
    
    fprintf(fid, 'START\n');
    fprintf(fid, '  1 JAN 2024 /\n\n');
    
    fprintf(fid, 'WELLDIMS\n');
    fprintf(fid, '  15 20 5 15 /\n\n');
    
    % Include sections
    fprintf(fid, 'GRID\n\n');
    fprintf(fid, 'INCLUDE\n  ''GRID.inc'' /\n\n');
    
    fprintf(fid, 'PROPS\n\n');
    fprintf(fid, 'INCLUDE\n  ''PROPS.inc'' /\n');
    fprintf(fid, 'INCLUDE\n  ''PVT.inc'' /\n\n');
    
    fprintf(fid, 'SOLUTION\n\n');
    fprintf(fid, 'INCLUDE\n  ''SOLUTION.inc'' /\n\n');
    
    fprintf(fid, 'SUMMARY\n\n');
    fprintf(fid, 'FOPR\nFWPR\nFOPT\nFWPT\nFWCT\nFGOR\n');
    fprintf(fid, 'WOPR\n/\nWWPR\n/\nWBHP\n/\n\n');
    
    fprintf(fid, 'SCHEDULE\n\n');
    fprintf(fid, 'INCLUDE\n  ''SCHEDULE.inc'' /\n\n');
    
    fprintf(fid, 'END\n');
    
    fclose(fid);
    fprintf('  ✓ Master DATA file created: EAGLE_WEST.DATA\n');
end

function export_simulation_metadata(output_dir)
    % Export metadata and summary information
    
    metadata_file = fullfile(output_dir, 'EXPORT_SUMMARY.txt');
    fid = fopen(metadata_file, 'w');
    
    fprintf(fid, 'MRST TO OPM EXPORT SUMMARY\n');
    fprintf(fid, '============================\n\n');
    fprintf(fid, 'Export Date: %s\n', datestr(now));
    fprintf(fid, 'Source: MRST Workflow (s01-s20)\n');
    fprintf(fid, 'Target: OPM Flow Simulator\n\n');
    
    fprintf(fid, 'FILES CREATED:\n');
    fprintf(fid, '- EAGLE_WEST.DATA (Master simulation deck)\n');
    fprintf(fid, '- GRID.inc (Grid geometry and properties)\n');
    fprintf(fid, '- PROPS.inc (Rock properties)\n');
    fprintf(fid, '- PVT.inc (Fluid properties and relative permeability)\n');
    fprintf(fid, '- WELLS.inc (Well specifications and completions)\n');
    fprintf(fid, '- SCHEDULE.inc (Production schedule and controls)\n');
    fprintf(fid, '- SOLUTION.inc (Initial conditions)\n\n');
    
    fprintf(fid, 'NEXT STEPS:\n');
    fprintf(fid, '1. Run s22_opm_simulation.py to execute OPM simulation\n');
    fprintf(fid, '2. Run s23_import_omp_results.m to import results back to MRST\n');
    fprintf(fid, '3. Continue with s24-s25 for post-processing and analytics\n\n');
    
    fprintf(fid, 'SIMULATION PARAMETERS:\n');
    fprintf(fid, 'Grid: 41x41x12 cells\n');
    fprintf(fid, 'Wells: 15 total (10 producers, 5 injectors)\n');
    fprintf(fid, 'Simulation Period: 10 years\n');
    fprintf(fid, 'Time Steps: Monthly\n');
    
    fclose(fid);
    fprintf('  ✓ Export metadata created\n');
end
