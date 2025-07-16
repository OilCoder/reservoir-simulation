function s11c_export_dynamic_fields(G, rock, states, base_dir)
% export_dynamic_fields - Export dynamic field arrays
%
% Exports 3D arrays of pressure, saturation, porosity, permeability,
% and effective stress to the optimized data structure.
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
%% Step 1 – Initialize 3D arrays
%% ----

% Grid dimensions
nx = G.cartDims(1);
ny = G.cartDims(2);
n_steps = length(states);

% Pre-allocate 3D arrays: [time, y, x] for Python compatibility
pressure_3d = zeros(n_steps, ny, nx);
sw_3d = zeros(n_steps, ny, nx);
phi_3d = zeros(n_steps, ny, nx);
k_3d = zeros(n_steps, ny, nx);
sigma_eff_3d = zeros(n_steps, ny, nx);

%% ----
%% Step 2 – Fill 3D arrays from simulation states
%% ----

for t = 1:n_steps
    try
        % Extract snapshot data using existing function
        [sigma_eff, phi, k, rock_id] = s12_extract_snapshot(G, rock, states{t}, t);
        
        % Store in 3D arrays (already in correct 2D format from extract_snapshot)
        pressure_3d(t, :, :) = reshape(states{t}.pressure / 6894.76, [nx, ny])';  % Convert Pa to psi
        
        if isfield(states{t}, 's') && size(states{t}.s, 2) >= 2
            sw_3d(t, :, :) = reshape(states{t}.s(:,1), [nx, ny])';  % Water saturation [-]
        else
            sw_3d(t, :, :) = sw_3d(max(1, t-1), :, :);  % Use previous value
        end
        
        phi_3d(t, :, :) = phi;  % Already 2D from extract_snapshot
        k_3d(t, :, :) = k;      % Already 2D from extract_snapshot
        sigma_eff_3d(t, :, :) = sigma_eff;  % Already 2D from extract_snapshot
        
        if mod(t, 10) == 0 || t == n_steps
            fprintf('[INFO] Processed timestep %d/%d (%.1f%%)\n', t, n_steps, 100*t/n_steps);
        end
        
    catch ME
        fprintf('[ERROR] Failed to process timestep %d: %s\n', t, ME.message);
    end
end

%% ----
%% Step 3 – Save 3D field arrays
%% ----

fields_data = struct();
fields_data.pressure = pressure_3d;    % [time, y, x] in psi
fields_data.sw = sw_3d;                % [time, y, x] water saturation
fields_data.phi = phi_3d;              % [time, y, x] porosity
fields_data.k = k_3d;                  % [time, y, x] permeability in mD
fields_data.sigma_eff = sigma_eff_3d;  % [time, y, x] effective stress in psi

% Save field data
fields_file = fullfile(base_dir, 'dynamic', 'fields', 'field_arrays.mat');
save(fields_file, 'fields_data', '-v7');
fprintf('[INFO] Dynamic fields saved: %s\n', fields_file);

end
