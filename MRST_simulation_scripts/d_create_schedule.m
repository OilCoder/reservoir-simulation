function schedule = d_create_schedule(G, rock, fluid, config_file)
% d_create_schedule - Create MRST simulation schedule with wells and timesteps
%
% Creates schedule with producer and injector wells based on configuration.
% Uses MRST functions for well creation and schedule setup.
%
% Args:
%   G: MRST grid structure
%   rock: MRST rock structure
%   fluid: MRST fluid structure
%   config_file: Path to YAML configuration file
%
% Returns:
%   schedule: MRST schedule structure with wells and timesteps
%
% Requires: MRST

%% ----
%% Step 1 – Load configuration
%% ----

% Substep 1.1 – Read configuration file ________________________
config = util_read_config(config_file);

fprintf('[INFO] Creating simulation schedule\n');

%% ----
%% Step 2 – Create wells
%% ----

% Substep 2.1 – Initialize empty well array ____________________
W = [];

% Substep 2.2 – Add producer well _______________________________
prod_i = config.wells.producer_i;
prod_j = config.wells.producer_j;
prod_bhp = config.wells.producer_bhp * 6894.76;  % psi to Pa

% Convert (i,j) to cell index
prod_cell = sub2ind([G.cartDims(1), G.cartDims(2)], prod_i, prod_j);

W = addWell(W, G, rock, prod_cell, 'Type', 'bhp', 'Val', prod_bhp, ...
           'Radius', 0.1, 'Name', 'PRODUCER', 'Comp_i', [0, 1]);

% Substep 2.3 – Add injector well _______________________________
inj_i = config.wells.injector_i;
inj_j = config.wells.injector_j;
inj_rate = config.wells.injector_rate * 1.589873e-7;  % bbl/day to m³/s

% Convert (i,j) to cell index
inj_cell = sub2ind([G.cartDims(1), G.cartDims(2)], inj_i, inj_j);

W = addWell(W, G, rock, inj_cell, 'Type', 'rate', 'Val', inj_rate, ...
           'Radius', 0.1, 'Name', 'INJECTOR', 'Comp_i', [1, 0]);

fprintf('[INFO] Wells created:\n');
fprintf('  Producer: (%d,%d) BHP = %.0f psi\n', prod_i, prod_j, config.wells.producer_bhp);
fprintf('  Injector: (%d,%d) Rate = %.0f bbl/day\n', inj_i, inj_j, config.wells.injector_rate);

%% ----
%% Step 3 – Create timesteps
%% ----

% Substep 3.1 – Define simulation time parameters _______________
total_time = config.simulation.total_time * 86400;  % days to seconds
num_steps = config.simulation.num_timesteps;

% Create timesteps with increasing size
dt_base = total_time / num_steps;
dt_mult = 1.1;  % Multiplier for timestep increase

% Generate timesteps
timesteps = zeros(num_steps, 1);
timesteps(1) = dt_base;

for i = 2:num_steps
    timesteps(i) = timesteps(i-1) * dt_mult;
end

% Normalize to match total time
timesteps = timesteps * total_time / sum(timesteps);

fprintf('[INFO] Timesteps created: %d steps over %.0f days\n', num_steps, config.simulation.total_time);

%% ----
%% Step 4 – Create schedule
%% ----

% Substep 4.1 – Create schedule structure _______________________
schedule = struct();
schedule.control = struct('W', W);
schedule.step = struct('val', timesteps, 'control', ones(num_steps, 1));

fprintf('[INFO] Schedule created successfully\n');
fprintf('  Total time: %.1f days\n', sum(timesteps)/86400);
fprintf('  Timesteps: %d\n', length(timesteps));
fprintf('  Wells: %d\n', length(W));

end 