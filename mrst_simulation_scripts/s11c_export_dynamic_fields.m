function s11c_export_dynamic_fields(G, rock, states, base_dir)
% export_dynamic_fields - Export dynamic field arrays (2D or 3D)
%
% Exports arrays of pressure, saturation, porosity, permeability,
% and effective stress. Handles both 2D (nz=1) and 3D (nz>1) automatically.
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

fprintf('[INFO] Exporting dynamic field data...\n');

%% ----
%% Step 1 – Initialize 4D arrays
%% ----

% Grid dimensions
nx = G.cartDims(1);
ny = G.cartDims(2);
nz = G.cartDims(3);
n_steps = length(states);

if nz == 1
    fprintf('[INFO] Grid dimensions: %d x %d (2D with nz=1)\n', nx, ny);
else
    fprintf('[INFO] Grid dimensions: %d x %d x %d (3D)\n', nx, ny, nz);
end
fprintf('[INFO] Number of timesteps: %d\n', n_steps);

% Pre-allocate arrays: [time, z, y, x] for Python compatibility (z=1 for 2D)
pressure_4d = zeros(n_steps, nz, ny, nx);
sw_4d = zeros(n_steps, nz, ny, nx);
phi_4d = zeros(n_steps, nz, ny, nx);
k_4d = zeros(n_steps, nz, ny, nx);
sigma_eff_4d = zeros(n_steps, nz, ny, nx);

%% ----
%% Step 2 – Fill 4D arrays from simulation states
%% ----

for t = 1:n_steps
    try
        % Extract snapshot data using unified function (handles 2D/3D automatically)
        [sigma_eff, phi, k, rock_id, pressure, saturation] = s12_extract_snapshot(G, rock, states{t}, t);
        
        % Store in arrays (format: [time, z, y, x] - works for both 2D and 3D)
        pressure_4d(t, :, :, :) = pressure;     % Already converted to psi
        sw_4d(t, :, :, :) = saturation;         % Already extracted
        phi_4d(t, :, :, :) = phi;               % Unified format
        k_4d(t, :, :, :) = k;                   % Unified format
        sigma_eff_4d(t, :, :, :) = sigma_eff;   % Unified format
        
        if mod(t, 10) == 0 || t == n_steps
            fprintf('[INFO] Processed timestep %d/%d (%.1f%%)\n', t, n_steps, 100*t/n_steps);
        end
        
    catch ME
        fprintf('[ERROR] Failed to process timestep %d: %s\n', t, ME.message);
    end
end

%% ----
%% Step 3 – Save 4D field arrays
%% ----

fields_data = struct();
fields_data.pressure = pressure_4d;    % [time, z, y, x] in psi
fields_data.sw = sw_4d;                % [time, z, y, x] water saturation
fields_data.phi = phi_4d;              % [time, z, y, x] porosity
fields_data.k = k_4d;                  % [time, z, y, x] permeability in mD
fields_data.sigma_eff = sigma_eff_4d;  % [time, z, y, x] effective stress in psi

% Save metadata about array structure
fields_data.dimensions = struct();
fields_data.dimensions.order = 'time, z, y, x';
fields_data.dimensions.nx = nx;
fields_data.dimensions.ny = ny;
fields_data.dimensions.nz = nz;
fields_data.dimensions.n_timesteps = n_steps;

% Save field data
fields_file = fullfile(base_dir, 'simulation_data', 'dynamic', 'fields', 'field_arrays.mat');
save(fields_file, 'fields_data', '-v7');
if nz == 1
    fprintf('[INFO] 2D Dynamic fields saved: %s\n', fields_file);
else
    fprintf('[INFO] 3D Dynamic fields saved: %s\n', fields_file);
end

% Calculate file size
file_info = dir(fields_file);
file_size_mb = file_info.bytes / (1024^2);
fprintf('[INFO] File size: %.2f MB\n', file_size_mb);

%% ----
%% Step 4 – Export rock_id separately (static field)
%% ----

% Extract rock_id once (it's static)
if n_steps > 0
    [~, ~, ~, rock_id, ~, ~] = s12_extract_snapshot(G, rock, states{1}, 1);
    
    % Save static rock_id
    static_data = struct();
    static_data.rock_id = rock_id;  % [z, y, x] (z=1 for 2D)
    static_data.dimensions = struct();
    static_data.dimensions.order = 'z, y, x';
    static_data.dimensions.nx = nx;
    static_data.dimensions.ny = ny;
    static_data.dimensions.nz = nz;
    
    static_file = fullfile(base_dir, 'simulation_data', 'static', 'static_data.mat');
    save(static_file, 'static_data', '-v7');
    if nz == 1
        fprintf('[INFO] Static 2D data saved: %s\n', static_file);
    else
        fprintf('[INFO] Static 3D data saved: %s\n', static_file);
    end
end

if nz == 1
    fprintf('[INFO] 2D export completed successfully!\n');
else
    fprintf('[INFO] 3D export completed successfully!\n');
end

end