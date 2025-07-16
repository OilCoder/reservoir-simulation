function s11a_export_initial_conditions(G, rock, states, base_dir)
% export_initial_conditions - Export initial reservoir conditions
%
% Exports initial pressure, saturation, porosity, and permeability
% to the optimized data structure.
%
% Args:
%   G: MRST grid structure
%   rock: MRST rock structure
%   states: Cell array of simulation states
%   base_dir: Base directory for data export
%
% Returns:
%   None (exports data to file)
%
% Requires: MRST

fprintf('[INFO] Exporting initial conditions...\n');

%% ----
%% Step 1 – Prepare initial data structure
%% ----

initial_data = struct();

% Grid dimensions
nx = G.cartDims(1);
ny = G.cartDims(2);

%% ----
%% Step 2 – Extract initial conditions
%% ----

% Initial pressure field (2D matrix)
if iscell(states) && length(states) > 0 && isfield(states{1}, 'pressure')
    initial_data.pressure = reshape(states{1}.pressure / 6894.76, [nx, ny])';  % Convert Pa to psi
else
    % Use config default if not available
    config = util_read_config('../config/reservoir_config.yaml');
    p_init = config.initial_conditions.pressure;
    initial_data.pressure = p_init * ones(ny, nx);  % [psi]
end

% Initial water saturation (2D matrix)
if iscell(states) && length(states) > 0 && isfield(states{1}, 's') && size(states{1}.s, 2) >= 2
    initial_data.sw = reshape(states{1}.s(:,1), [nx, ny])';  % Water saturation [-]
else
    % Use config default if not available
    config = util_read_config('../config/reservoir_config.yaml');
    sw_init = config.initial_conditions.water_saturation;
    initial_data.sw = sw_init * ones(ny, nx);  % [-]
end

% Initial porosity (2D matrix)
initial_data.phi = reshape(rock.poro, [nx, ny])';  % [-]

% Initial permeability (2D matrix)
initial_data.k = reshape(rock.perm / 9.869233e-16, [nx, ny])';  % Convert m² to mD

%% ----
%% Step 3 – Save initial conditions
%% ----

initial_file = fullfile(base_dir, 'initial', 'initial_conditions.mat');
save(initial_file, 'initial_data', '-v7');
fprintf('[INFO] Initial conditions saved: %s\n', initial_file);

end
