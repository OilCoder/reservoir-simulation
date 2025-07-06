function schedule = create_schedule(G, rock, fluid, config_file)
% create_schedule - Create MRST schedule with wells, controls and timesteps
%
% Creates schedule structure with:
% - Production and injection wells
% - Pressure/rate controls
% - Timestep sequence with rampupTimesteps
%
% Args:
%   G: MRST grid structure
%   rock: MRST rock structure
%   fluid: MRST fluid structure
%   config_file: Optional path to YAML configuration file
%
% Returns:
%   schedule: MRST schedule structure ready for simulation
%
% Requires: MRST

%% ----
%% Step 1 – Load configuration
%% ----

if nargin < 4
    config_file = '../config/reservoir_config.yaml';
end

% Load configuration
config = util_read_config(config_file);

%% ----
%% Step 2 – Well locations and setup from config
%% ----

% Substep 2.1 – Define well locations from config _____________
% ✅ Producer location from config
prod_i = config.wells.producer_i;   % Grid cell i-index
prod_j = config.wells.producer_j;   % Grid cell j-index
prod_cell = sub2ind(G.cartDims, prod_i, prod_j);

% ✅ Injector location from config
inj_i = config.wells.injector_i;   % Grid cell i-index
inj_j = config.wells.injector_j;   % Grid cell j-index
inj_cell = sub2ind(G.cartDims, inj_i, inj_j);

%% ----
%% Step 3 – Well definition from config
%% ----

% Substep 3.1 – Initialize well structure ____________________
W = [];

% Substep 3.2 – Add production well from config _______________
% 📊 Oil production well with pressure control
W = addWell(W, G, rock, prod_cell, ...
    'Type', 'bhp', ...
    'Val', config.wells.producer_bhp * psia, ...
    'Radius', 0.33 * ft, ...
    'Name', 'PROD1', ...
    'Compi', [0 1]);  % Pure oil production

% Substep 3.3 – Add injection well from config ________________
% 💧 Water injection well with rate control
% Convert bbl/day to m³/day (1 bbl = 0.158987 m³)
inj_rate_m3day = config.wells.injector_rate * 0.158987 * meter^3/day;

W = addWell(W, G, rock, inj_cell, ...
    'Type', 'rate', ...
    'Val', inj_rate_m3day, ...
    'Radius', 0.33 * ft, ...
    'Name', 'INJ1', ...
    'Compi', [1 0]);  % Pure water injection

%% ----
%% Step 4 – Timestep sequence from config
%% ----

% Substep 4.1 – Define simulation periods from config _________
% 🔄 Total simulation time with increasing timesteps
total_time = config.simulation.total_time * day;  % Simulation time from config
n_steps = config.simulation.num_timesteps;       % Number of timesteps from config

% Substep 4.2 – Create rampup timesteps ______________________
% ✅ Use MRST's rampupTimesteps for stable startup
dt_init = 1*day;       % Initial timestep
dt_max = 30*day;       % Maximum timestep
dt_rampup = rampupTimesteps(total_time, dt_init, 8);

% Substep 4.3 – Adjust timestep sequence _____________________
% 📊 Ensure reasonable timestep distribution
if length(dt_rampup) > n_steps
    dt_rampup = dt_rampup(1:n_steps);
    dt_rampup(end) = total_time - sum(dt_rampup(1:end-1));
end

% Trim to total time
dt_rampup = dt_rampup(cumsum(dt_rampup) <= total_time);

%% ----
%% Step 5 – Control sequence from config
%% ----

% Substep 5.1 – Define control periods ________________________
n_controls = length(dt_rampup);

% Substep 5.2 – Create schedule structure ____________________
schedule = simpleSchedule(dt_rampup, 'W', W);

% Substep 5.3 – Modify controls for later periods _____________
% 🔄 Increase injection rate after initial period
for i = 1:n_controls
    if i > n_controls/3  % After first third of simulation
        % Increase injection rate by 50%
        new_rate = config.wells.injector_rate * 1.5 * 0.158987 * meter^3/day;
        schedule.control(i).W(2).val = new_rate;
    end
    if i > 2*n_controls/3  % After second third
        % Reduce producer BHP by 10%
        schedule.control(i).W(1).val = config.wells.producer_bhp * 0.9 * psia;
    end
end

%% ----
%% Step 6 – Validation and output
%% ----

% Substep 6.1 – Validate schedule structure ___________________
assert(isfield(schedule, 'control'), 'Schedule controls not defined');
assert(isfield(schedule, 'step'), 'Schedule timesteps not defined');
assert(length(schedule.control) == length(schedule.step.control), ...
    'Control and timestep length mismatch');

% Substep 6.2 – Well validation ________________________________
n_wells = length(schedule.control(1).W);
assert(n_wells == 2, 'Expected 2 wells in schedule');

% Find producer and injector
prod_idx = find(strcmp({schedule.control(1).W.name}, 'PROD1'));
inj_idx = find(strcmp({schedule.control(1).W.name}, 'INJ1'));

assert(~isempty(prod_idx), 'Producer well not found');
assert(~isempty(inj_idx), 'Injector well not found');

%% ----
%% Step 7 – Summary output
%% ----

% Substep 7.1 – Calculate simulation summary __________________
total_sim_time = sum(schedule.step.val) / day;
n_timesteps = length(schedule.step.val);
avg_dt = mean(schedule.step.val) / day;

fprintf('[INFO] Schedule created:\n');
fprintf('  Wells: %d (%s at [%d,%d], %s at [%d,%d])\n', ...
    n_wells, schedule.control(1).W(prod_idx).name, prod_i, prod_j, ...
    schedule.control(1).W(inj_idx).name, inj_i, inj_j);
fprintf('  Total time: %.1f days\n', total_sim_time);
fprintf('  Timesteps: %d (avg: %.1f days)\n', n_timesteps, avg_dt);
fprintf('  Initial producer BHP: %.0f psi\n', schedule.control(1).W(prod_idx).val / psia);
fprintf('  Initial injector rate: %.0f bbl/day\n', schedule.control(1).W(inj_idx).val / (meter^3/day) / 0.158987);
fprintf('  Control periods: %d\n', length(schedule.control));

fprintf('[INFO] Schedule ready for simulation\n');

end 