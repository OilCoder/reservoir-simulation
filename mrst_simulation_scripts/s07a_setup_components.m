function [G, rock, fluid, schedule, timing] = s07a_setup_components(config_file)
% s07a_setup_components - Setup all simulation components
%
% Creates grid, rock, fluid, and schedule structures for MRST simulation
% workflow execution.
%
% Args:
%   config_file: Path to YAML configuration file
%
% Returns:
%   G: MRST grid structure
%   rock: MRST rock structure with regions
%   fluid: MRST fluid structure
%   schedule: MRST schedule structure
%   timing: Structure with timing information
%
% Requires: MRST

timing = struct();

%% ----
%% Step 1 – Grid and rock setup
%% ----

fprintf('\n--- Step 2: Grid and Rock Setup ---\n');
tic;

[G, rock, fluid_placeholder] = s01_setup_field(config_file);

% Verify grid and rock were created
assert(exist('G', 'var') && isstruct(G), 'Grid G not created');
assert(exist('rock', 'var') && isstruct(rock), 'Rock structure not created');

timing.setup_time = toc;
fprintf('[INFO] Grid and rock setup completed in %.1f seconds\n', timing.setup_time);

%% ----
%% Step 2 – Fluid properties definition
%% ----

fprintf('\n--- Step 3: Fluid Properties ---\n');
tic;

fluid = s02_define_fluid(config_file);

% Verify fluid was created
assert(exist('fluid', 'var') && isstruct(fluid), 'Fluid structure not created');

timing.fluid_time = toc;
fprintf('[INFO] Fluid properties defined in %.1f seconds\n', timing.fluid_time);

%% ----
%% Step 3 – Rock region definition
%% ----

fprintf('\n--- Step 4: Rock Regions ---\n');
tic;

rock = s03_define_rock_regions(rock);

% Verify rock regions were created
assert(isfield(rock, 'regions'), 'Rock regions not defined');
assert(isfield(rock, 'c_phi'), 'Compaction coefficients not defined');

timing.regions_time = toc;
fprintf('[INFO] Rock regions defined in %.1f seconds\n', timing.regions_time);

%% ----
%% Step 4 – Schedule creation
%% ----

fprintf('\n--- Step 5: Schedule Creation ---\n');
tic;

schedule = s04_create_schedule(G, rock, fluid, config_file);

% Verify schedule was created
assert(exist('schedule', 'var') && isstruct(schedule), 'Schedule not created');
assert(isfield(schedule, 'step'), 'Schedule timesteps not defined');
assert(isfield(schedule, 'control'), 'Schedule controls not defined');

timing.schedule_time = toc;
fprintf('[INFO] Schedule created in %.1f seconds\n', timing.schedule_time);

end
