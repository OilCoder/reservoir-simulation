% main_phase1.m
% Complete Phase 1 workflow orchestrator for MRST geomechanical simulation.
% Calls all functions in correct order for reproducible simulation execution.
% Requires: MRST

%% ----
%% Step 1 – Initialize and setup
%% ----

% Substep 1.1 – Clear workspace and initialize ________________
clear all; close all; clc;

fprintf('=== MRST Geomechanical Simulation - Phase 1 ===\n');
fprintf('Starting complete workflow at %s\n', datestr(now));

% Substep 1.2 – Initialize MRST properly for Octave ___________
fprintf('[INFO] Initializing MRST for Octave...\n');

% Navigate to MRST core directory and run startup
current_dir = pwd;
mrst_core_path = fullfile(fileparts(pwd), 'mrst', 'core');

if exist(mrst_core_path, 'dir')
    addpath(mrst_core_path);
    cd(mrst_core_path);
    try
        startup();  % Run the core MRST startup
        fprintf('[INFO] MRST initialized successfully\n');
    catch ME
        fprintf('[ERROR] MRST startup failed: %s\n', ME.message);
        cd(current_dir);
        error('Cannot proceed without MRST');
    end
    cd(current_dir);  % Return to original directory
else
    error('[ERROR] MRST core not found at %s', mrst_core_path);
end

% Substep 1.3 – Load required MRST modules ___________________
fprintf('[INFO] Loading required MRST modules...\n');

% Add essential MRST paths manually for Octave compatibility
mrst_base = fullfile(fileparts(pwd), 'mrst');

% Core incompressible flow functions
incomp_path = fullfile(mrst_base, 'solvers', 'incomp');
if exist(incomp_path, 'dir')
    addpath(genpath(incomp_path));
    fprintf('[INFO] Added incomp module paths\n');
end

% Autodiff modules for advanced simulation
autodiff_path = fullfile(mrst_base, 'autodiff');
if exist(autodiff_path, 'dir')
    addpath(genpath(autodiff_path));
    fprintf('[INFO] Added autodiff module paths\n');
end

% Specifically add ad-blackoil module 
ad_blackoil_path = fullfile(mrst_base, 'autodiff', 'ad-blackoil');
if exist(ad_blackoil_path, 'dir')
    addpath(genpath(ad_blackoil_path));
    fprintf('[INFO] Added ad-blackoil module paths\n');
end

% Model-IO for data handling
modelio_path = fullfile(mrst_base, 'model-io');
if exist(modelio_path, 'dir')
    addpath(genpath(modelio_path));
    fprintf('[INFO] Added model-io module paths\n');
end

% Solvers for simulation
solvers_path = fullfile(mrst_base, 'solvers');
if exist(solvers_path, 'dir')
    addpath(genpath(solvers_path));
    fprintf('[INFO] Added solvers module paths\n');
end

% Substep 1.4 – Verify MRST functions are available ____________
try
    % Test if key MRST functions are available
    which('cartGrid');
    which('makeRock');
    which('initSimpleFluid');
    which('addWell');
    which('simpleSchedule');
    fprintf('[INFO] MRST functions verified and ready\n');
catch
    error('[ERROR] MRST functions not available, check installation');
end

% Substep 1.5 – Set random seed for reproducibility ___________
rng(42);
fprintf('[INFO] Random seed set to 42 for reproducibility\n');

% Substep 1.6 – Ensure we're in the correct directory _________
mrst_sim_dir = fullfile(fileparts(pwd), 'MRST_simulation_scripts');
if exist(mrst_sim_dir, 'dir') && ~strcmp(pwd, mrst_sim_dir)
    cd(mrst_sim_dir);
    fprintf('[INFO] Changed to MRST_simulation_scripts directory\n');
end

% Substep 1.7 – Create required directories ___________________
fprintf('[INFO] Setting up directory structure...\n');
util_ensure_directories();

%% ----
%% Step 2 – Grid and rock setup
%% ----

% Substep 2.1 – Create grid and rock properties _______________
fprintf('\n--- Step 2: Grid and Rock Setup ---\n');
tic;

% Run setup_field.m script with configuration file
config_file = '../config/reservoir_config.yaml';
[G, rock, fluid_placeholder] = setup_field(config_file);

% Verify grid and rock were created
assert(exist('G', 'var') && isstruct(G), 'Grid G not created');
assert(exist('rock', 'var') && isstruct(rock), 'Rock structure not created');

setup_time = toc;
fprintf('[INFO] Grid and rock setup completed in %.1f seconds\n', setup_time);

%% ----
%% Step 3 – Fluid properties definition
%% ----

% Substep 3.1 – Define fluid properties _______________________
fprintf('\n--- Step 3: Fluid Properties ---\n');
tic;

% Create fluid structure with configuration
fluid = define_fluid(config_file);

% Verify fluid was created
assert(exist('fluid', 'var') && isstruct(fluid), 'Fluid structure not created');

fluid_time = toc;
fprintf('[INFO] Fluid properties defined in %.1f seconds\n', fluid_time);

%% ----
%% Step 4 – Rock region definition
%% ----

% Substep 4.1 – Define rock regions ___________________________
fprintf('\n--- Step 4: Rock Regions ---\n');
tic;

% Update rock structure with regions
rock = define_rock_regions(rock);

% Verify rock regions were created
assert(isfield(rock, 'regions'), 'Rock regions not defined');
assert(isfield(rock, 'c_phi'), 'Compaction coefficients not defined');

regions_time = toc;
fprintf('[INFO] Rock regions defined in %.1f seconds\n', regions_time);

%% ----
%% Step 5 – Schedule creation
%% ----

% Substep 5.1 – Create simulation schedule ____________________
fprintf('\n--- Step 5: Schedule Creation ---\n');
tic;

% Create schedule with wells and timesteps
schedule = create_schedule(G, rock, fluid, config_file);

% Verify schedule was created
assert(exist('schedule', 'var') && isstruct(schedule), 'Schedule not created');
assert(isfield(schedule, 'step'), 'Schedule timesteps not defined');
assert(isfield(schedule, 'control'), 'Schedule controls not defined');

schedule_time = toc;
fprintf('[INFO] Schedule created in %.1f seconds\n', schedule_time);

%% ----
%% Step 6 – Simulation execution
%% ----

% Substep 6.1 – Run main simulation ____________________________
fprintf('\n--- Step 6: Simulation Execution ---\n');
tic;

% Execute simulation
run_simulation;

% Verify simulation results
assert(exist('states', 'var') && iscell(states), 'Simulation states not created');
assert(exist('wellSols', 'var') && iscell(wellSols), 'Well solutions not created');
assert(length(states) > 0, 'No simulation states generated');

simulation_time = toc;
fprintf('[INFO] Simulation completed in %.1f seconds\n', simulation_time);

%% ----
%% Step 7 – Dataset export
%% ----

% Substep 7.1 – Export simulation results ____________________
fprintf('\n--- Step 7: Dataset Export ---\n');
tic;

% Export snapshots to data/
export_dataset;

export_time = toc;
fprintf('[INFO] Dataset export completed in %.1f seconds\n', export_time);

%% ----
%% Step 8 – Visualization (optional)
%% ----

% Substep 8.1 – Create quicklook plots ________________________
fprintf('\n--- Step 8: Visualization ---\n');
tic;

% Check if graphics toolkit is available
try
    figure();
    close();
    graphics_available = true;
catch
    graphics_available = false;
    fprintf('[WARN] Graphics toolkit not available, skipping visualization\n');
end

% Plots directory already created by util_ensure_directories

if graphics_available
    % Plot initial and final states
    plot_quicklook(G, rock, states, 1);      % Initial state
    plot_quicklook(G, rock, states, length(states));  % Final state

    % Plot intermediate state if available
    if length(states) > 10
        mid_idx = round(length(states) / 2);
        plot_quicklook(G, rock, states, mid_idx);
    end
    
    fprintf('[INFO] Visualization plots created\n');
else
    fprintf('[INFO] Visualization skipped (no graphics available)\n');
end

plot_time = toc;
fprintf('[INFO] Visualization completed in %.1f seconds\n', plot_time);

%% ----
%% Step 9 – Final summary and validation
%% ----

% Substep 9.1 – Calculate total workflow time __________________
total_time = setup_time + fluid_time + regions_time + schedule_time + ...
            simulation_time + export_time + plot_time;

% Substep 9.2 – Validate complete workflow ____________________
fprintf('\n--- Step 9: Final Validation ---\n');

% Check all required variables exist
required_vars = {'G', 'rock', 'fluid', 'schedule', 'states', 'wellSols'};
all_vars_exist = true;

for i = 1:length(required_vars)
    var_name = required_vars{i};
    if ~exist(var_name, 'var')
        fprintf('[ERROR] Required variable %s not found\n', var_name);
        all_vars_exist = false;
    end
end

% Check data directory exists
if ~exist('data', 'dir')
    fprintf('[ERROR] Data directory not created\n');
    all_vars_exist = false;
end

% Check snapshot files exist
snap_files = dir('data/snap_*.mat');
if isempty(snap_files)
    fprintf('[ERROR] No snapshot files found\n');
    all_vars_exist = false;
end

% Check plots directory exists
if ~exist('plots', 'dir')
    fprintf('[ERROR] Plots directory not created\n');
    all_vars_exist = false;
end

%% ----
%% Step 10 – Completion report
%% ----

% Substep 10.1 – Generate completion report ___________________
fprintf('\n=== PHASE 1 COMPLETION REPORT ===\n');
fprintf('Workflow finished at: %s\n', datestr(now));
fprintf('Total execution time: %.1f seconds (%.1f minutes)\n', total_time, total_time/60);
fprintf('\nTiming breakdown:\n');
fprintf('  Grid/Rock setup: %.1f s (%.1f%%)\n', setup_time, 100*setup_time/total_time);
fprintf('  Fluid properties: %.1f s (%.1f%%)\n', fluid_time, 100*fluid_time/total_time);
fprintf('  Rock regions: %.1f s (%.1f%%)\n', regions_time, 100*regions_time/total_time);
fprintf('  Schedule creation: %.1f s (%.1f%%)\n', schedule_time, 100*schedule_time/total_time);
fprintf('  Simulation: %.1f s (%.1f%%)\n', simulation_time, 100*simulation_time/total_time);
fprintf('  Data export: %.1f s (%.1f%%)\n', export_time, 100*export_time/total_time);
fprintf('  Visualization: %.1f s (%.1f%%)\n', plot_time, 100*plot_time/total_time);

% Substep 10.2 – Results summary ______________________________
fprintf('\nResults summary:\n');
fprintf('  Grid cells: %d (20x20)\n', G.cells.num);
fprintf('  Timesteps: %d\n', length(states));
fprintf('  Simulation time: %.1f days\n', sum(schedule.step.val)/day);
fprintf('  Wells: %d\n', length(schedule.control(1).W));
fprintf('  Rock regions: %d\n', length(unique(rock.regions)));
fprintf('  Snapshot files: %d\n', length(snap_files));
fprintf('  Total data size: %.1f MB\n', sum([snap_files.bytes])/(1024^2));

% Substep 10.3 – Success/failure status _______________________
if all_vars_exist
    fprintf('\n✅ PHASE 1 COMPLETED SUCCESSFULLY!\n');
    fprintf('All required outputs generated and validated.\n');
    fprintf('Dataset ready for ML training pipeline.\n');
else
    fprintf('\n❌ PHASE 1 COMPLETED WITH ERRORS!\n');
    fprintf('Some required outputs missing. Check error messages above.\n');
end

% Substep 10.4 – Next steps instructions ______________________
fprintf('\nNext steps:\n');
fprintf('  1. Inspect plots in plots/ directory\n');
fprintf('  2. Examine snapshot data in data/\n');
fprintf('  3. Review metadata.yaml for dataset details\n');
fprintf('  4. Proceed to Phase 2 (ML model development)\n');

% Substep 10.5 – Workspace cleanup (optional) __________________
fprintf('\nWorkspace variables available:\n');
fprintf('  G, rock, fluid, schedule, states, wellSols\n');
fprintf('  Use "clear all" to clean workspace if needed\n');

fprintf('\n=== END OF PHASE 1 ===\n'); 