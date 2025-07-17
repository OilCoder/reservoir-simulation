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
nz = G.cartDims(3);

%% ----
%% Step 2 – Extract initial conditions
%% ----

% Initial pressure field (2D or 3D matrix)
if iscell(states) && length(states) > 0 && isfield(states{1}, 'pressure')
    if nz > 1
        % 3D case: reshape to [nx, ny, nz] then permute to [nz, ny, nx]
        initial_data.pressure = permute(reshape(states{1}.pressure / 6894.76, [nx, ny, nz]), [3, 2, 1]);  % Convert Pa to psi
    else
        % 2D case
        initial_data.pressure = reshape(states{1}.pressure / 6894.76, [nx, ny])';  % Convert Pa to psi
    end
else
    % Use config default if not available
    config = util_read_config('../config/reservoir_config.yaml');
    p_init = config.initial_conditions.pressure;
    if nz > 1
        initial_data.pressure = p_init * ones(nz, ny, nx);  % [psi]
    else
        initial_data.pressure = p_init * ones(ny, nx);  % [psi]
    end
end

% Initial water saturation (2D or 3D matrix)
if iscell(states) && length(states) > 0 && isfield(states{1}, 's') && size(states{1}.s, 2) >= 2
    if nz > 1
        % 3D case
        initial_data.sw = permute(reshape(states{1}.s(:,1), [nx, ny, nz]), [3, 2, 1]);  % Water saturation [-]
    else
        % 2D case
        initial_data.sw = reshape(states{1}.s(:,1), [nx, ny])';  % Water saturation [-]
    end
else
    % Use config default if not available
    config = util_read_config('../config/reservoir_config.yaml');
    sw_init = config.initial_conditions.water_saturation;
    if nz > 1
        initial_data.sw = sw_init * ones(nz, ny, nx);  % [-]
    else
        initial_data.sw = sw_init * ones(ny, nx);  % [-]
    end
end

% Initial porosity (2D or 3D matrix)
if nz > 1
    initial_data.phi = permute(reshape(rock.poro, [nx, ny, nz]), [3, 2, 1]);  % [-]
else
    initial_data.phi = reshape(rock.poro, [nx, ny])';  % [-]
end

% Initial permeability (2D or 3D matrix)
if nz > 1
    initial_data.k = permute(reshape(rock.perm / 9.869233e-16, [nx, ny, nz]), [3, 2, 1]);  % Convert m² to mD
else
    initial_data.k = reshape(rock.perm / 9.869233e-16, [nx, ny])';  % Convert m² to mD
end

% Add depth information for 3D case
if nz > 1
    % Calculate depth for each cell center
    depth_vec = G.cells.centroids(:,3) / 0.3048;  % Convert m to ft
    initial_data.depth = permute(reshape(depth_vec, [nx, ny, nz]), [3, 2, 1]);  % [ft]
end

%% ----
%% Step 3 – Save initial conditions
%% ----

initial_file = fullfile(base_dir, 'initial', 'initial_conditions.mat');
save(initial_file, 'initial_data', '-v7');
fprintf('[INFO] Initial conditions saved: %s\n', initial_file);

end
