function schedule = s04_create_schedule(G, rock, fluid, config_dir)
% s04_create_schedule - Create MRST simulation schedule with wells and timesteps
%
% Creates schedule with producer and injector wells based on configuration.
% Uses MRST functions for well creation and schedule setup.
%
% Args:
%   G: MRST grid structure
%   rock: MRST rock structure
%   fluid: MRST fluid structure
%   config_dir: Path to configuration directory (optional, defaults to './config/')
%
% Returns:
%   schedule: MRST schedule structure with wells and timesteps
%
% Requires: MRST

%% ----
%% Step 1 – Load configuration
%% ----

% Substep 1.1 – Read configuration files ________________________
if nargin < 4
    config_dir = './config/';
end
config = util_read_config(config_dir);

fprintf('[INFO] Creating simulation schedule\n');

%% ----
%% Step 2 – Create wells
%% ----

% Substep 2.1 – Initialize empty well array ____________________
W = [];

% Substep 2.2 – Add producer wells ______________________________
for i = 1:length(config.wells.producers)
    producer = config.wells.producers{i};
    prod_i = producer.location(1);
    prod_j = producer.location(2);
    
    if strcmp(producer.control_type, 'bhp')
        prod_bhp = producer.target_bhp * 6894.76;  % psi to Pa
        control_type = 'bhp';
        control_val = prod_bhp;
    else
        prod_rate = -producer.target_rate * 1.589873e-7;  % bbl/day to m³/s (negative for production)
        control_type = 'rate';
        control_val = prod_rate;
    end
    
    % Convert (i,j) to cell index
    prod_cell = sub2ind([G.cartDims(1), G.cartDims(2)], prod_i, prod_j);
    
    W = addWell(W, G, rock, prod_cell, 'Type', control_type, 'Val', control_val, ...
               'Radius', producer.radius * 0.3048, 'Name', producer.name, 'Comp_i', [0, 1]);
end

% Substep 2.3 – Add injector wells _______________________________
for i = 1:length(config.wells.injectors)
    injector = config.wells.injectors{i};
    inj_i = injector.location(1);
    inj_j = injector.location(2);
    
    if strcmp(injector.control_type, 'rate')
        inj_rate = injector.target_rate * 1.589873e-7;  % bbl/day to m³/s
        control_type = 'rate';
        control_val = inj_rate;
    else
        inj_bhp = injector.target_bhp * 6894.76;  % psi to Pa
        control_type = 'bhp';
        control_val = inj_bhp;
    end
    
    % Convert (i,j) to cell index
    inj_cell = sub2ind([G.cartDims(1), G.cartDims(2)], inj_i, inj_j);
    
    W = addWell(W, G, rock, inj_cell, 'Type', control_type, 'Val', control_val, ...
               'Radius', injector.radius * 0.3048, 'Name', injector.name, 'Comp_i', [1, 0]);
end

fprintf('[INFO] Wells created:\n');
for i = 1:length(config.wells.producers)
    producer = config.wells.producers{i};
    fprintf('  Producer %s: (%d,%d) %s\n', producer.name, producer.location(1), producer.location(2), producer.control_type);
end
for i = 1:length(config.wells.injectors)
    injector = config.wells.injectors{i};
    fprintf('  Injector %s: (%d,%d) %s\n', injector.name, injector.location(1), injector.location(2), injector.control_type);
end

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

% Save schedule variable for later use
save('../data/simulation_data/temporal/schedule.mat', 'schedule');
fprintf('[INFO] Schedule saved to ../data/simulation_data/temporal/schedule.mat\n');

end
