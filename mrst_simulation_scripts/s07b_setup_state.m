function [state0, config] = s07b_setup_state(G, rock)
% setup_simulation_state - Initialize simulation state and configuration
%
% Sets up initial pressure and saturation state for MRST simulation
% and loads configuration parameters.
%
% Args:
%   G: MRST grid structure
%   rock: MRST rock structure
%
% Returns:
%   state0: Initial simulation state
%   config: Configuration structure
%
% Requires: MRST

%% ----
%% Step 1 – Load configuration and set initial conditions
%% ----

config_file = '../config/reservoir_config.yaml';
config = util_read_config(config_file);

p_init = config.initial_conditions.pressure * 6894.76;  % psi to Pa
s_init = [config.initial_conditions.water_saturation, 1-config.initial_conditions.water_saturation];

state0 = initResSol(G, p_init, s_init);

% Store initial porosity for compaction
rock.poro0 = rock.poro;

% Initialize pressure field
pressure = repmat(p_init, G.cells.num, 1);
state0 = struct('pressure', pressure, 's', [config.initial_conditions.water_saturation*ones(G.cells.num,1), ...
                                           (1-config.initial_conditions.water_saturation)*ones(G.cells.num,1)]);

fprintf('[INFO] Initial state configured with pressure = %.1f psi\n', config.initial_conditions.pressure);

end
