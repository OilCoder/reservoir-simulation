function [sigma_eff, phi, k, rock_id, pressure, saturation] = s12_extract_snapshot(G, rock, state, timestep)
% extract_snapshot - Extract arrays from simulation state (2D or 3D)
%
% Extracts and processes simulation data into arrays for ML training.
% Handles both 2D (nz=1) and 3D (nz>1) cases automatically:
% - Effective stress (σ')
% - Porosity (φ)
% - Permeability (k)
% - Rock region ID
% - Pressure (p)
% - Saturation (s)
%
% Args:
%   G: MRST grid structure
%   rock: MRST rock structure with regions
%   state: MRST simulation state for specific timestep
%   timestep: Current timestep number (for reference)
%
% Returns:
%   sigma_eff: nz x ny x nx array of effective stress [psi] (for 2D: 1 x ny x nx)
%   phi: nz x ny x nx array of current porosity [-] (for 2D: 1 x ny x nx)
%   k: nz x ny x nx array of current permeability [mD] (for 2D: 1 x ny x nx)
%   rock_id: nz x ny x nx array of rock region IDs [-] (for 2D: 1 x ny x nx)
%   pressure: nz x ny x nx array of spatial pressure [psi] (for 2D: 1 x ny x nx)
%   saturation: nz x ny x nx array of water saturation [-] (for 2D: 1 x ny x nx)
%
% Requires: MRST

%% ----
%% Step 1 – Input validation
%% ----

% Substep 1.1 – Check required inputs __________________________
assert(isstruct(G), 'Grid G must be a structure');
assert(isstruct(rock), 'Rock must be a structure');
assert(isstruct(state), 'State must be a structure');
assert(isfield(state, 'pressure'), 'State must have pressure field');

% Substep 1.2 – Grid dimension validation ______________________
nx = G.cartDims(1);
ny = G.cartDims(2);
nz = G.cartDims(3);

if nz == 1
    fprintf('[INFO] Processing 2D grid: %d x %d (nz=1)\n', nx, ny);
else
    fprintf('[INFO] Processing 3D grid: %d x %d x %d\n', nx, ny, nz);
end

%% ----
%% Step 2 – Extract pressure and calculate effective stress
%% ----

% Substep 2.1 – Get pressure field _____________________________
% ✅ Extract pressure from simulation state
pressure_vec = state.pressure / 6894.76;  % Convert Pa to psi

% Substep 2.2 – Calculate effective stress from MRST state ______
% ✅ Use MRST's computed effective stress if available
if isfield(state, 'sigma_eff')
    % MRST provides effective stress directly
    sigma_eff_vec = state.sigma_eff / 6894.76;  % Convert Pa to psi
elseif isfield(state, 'effective_stress')
    % Alternative field name
    sigma_eff_vec = state.effective_stress / 6894.76;  % Convert Pa to psi
else
    % Fallback: extract from MRST pressure field only
    fprintf('[WARN] No effective stress field found - using pressure field only\n');
    sigma_eff_vec = state.pressure / 6894.76;  % Convert Pa to psi
end

% ✅ Validate effective stress (physical constraint)
if any(sigma_eff_vec < 0)
    fprintf('[WARN] Found %d negative effective stress values - check MRST geomechanics setup\n', sum(sigma_eff_vec < 0));
end

%% ----
%% Step 3 – Extract porosity
%% ----

% Substep 3.1 – Extract porosity from MRST state ______________
% ✅ Use MRST's computed porosity directly
if isfield(state, 'porosity')
    phi_vec = state.porosity;  % MRST computed porosity
elseif isfield(state, 'phi')
    phi_vec = state.phi;  % Alternative field name
else
    % Fallback to rock properties if no state porosity
    phi_vec = rock.poro;
    fprintf('[INFO] Using initial rock porosity - no dynamic porosity in state\n');
end

%% ----
%% Step 4 – Calculate permeability
%% ----

% Substep 4.1 – Extract permeability from MRST state __________
% ✅ Use MRST's computed permeability directly
if isfield(state, 'permeability')
    k_vec = state.permeability / 9.869233e-16;  % Convert m² to mD
elseif isfield(state, 'perm')
    k_vec = state.perm / 9.869233e-16;  % Convert m² to mD
else
    % Fallback to rock properties if no state permeability
    k_vec = rock.perm / 9.869233e-16;  % Convert m² to mD
    fprintf('[INFO] Using initial rock permeability - no dynamic permeability in state\n');
end

%% ----
%% Step 5 – Extract rock regions
%% ----

% Substep 5.1 – Get rock region IDs ____________________________
rock_id_vec = rock.regions;

%% ----
%% Step 6 – Extract spatial pressure and saturation
%% ----

% Substep 6.1 – Extract spatial pressure ______________________
% Already extracted above as pressure_vec

% Substep 6.2 – Extract spatial saturation ____________________
if isfield(state, 'saturation')
    saturation_vec = state.saturation;
elseif isfield(state, 's')
    saturation_vec = state.s;
    % For multi-phase, extract water saturation (first column)
    if size(saturation_vec, 2) > 1
        saturation_vec = saturation_vec(:, 1);
    end
elseif isfield(state, 'sw')
    saturation_vec = state.sw;
else
    % Default to zero saturation if no saturation field found
    saturation_vec = zeros(size(pressure_vec));
    fprintf('[WARN] No saturation field found in state, using zeros\n');
end

%% ----
%% Step 7 – Reshape to 3D arrays
%% ----

% Substep 7.1 – Reshape vectors to 3D arrays _________________
% ✅ MRST uses column-major ordering (Fortran style)
% Order is X-fastest, then Y, then Z
sigma_eff = reshape(sigma_eff_vec, [nx, ny, nz]);
phi = reshape(phi_vec, [nx, ny, nz]);
k = reshape(k_vec, [nx, ny, nz]);
rock_id = reshape(rock_id_vec, [nx, ny, nz]);
pressure = reshape(pressure_vec, [nx, ny, nz]);
saturation = reshape(saturation_vec, [nx, ny, nz]);

% Permute to get Z x Y x X order for consistency with Python expectations
sigma_eff = permute(sigma_eff, [3, 2, 1]);  % [nz, ny, nx]
phi = permute(phi, [3, 2, 1]);              % [nz, ny, nx]
k = permute(k, [3, 2, 1]);                  % [nz, ny, nx]
rock_id = permute(rock_id, [3, 2, 1]);      % [nz, ny, nx]
pressure = permute(pressure, [3, 2, 1]);    % [nz, ny, nx]
saturation = permute(saturation, [3, 2, 1]); % [nz, ny, nx]

%% ----
%% Step 8 – Output preparation
%% ----

% Substep 8.1 – Validate array dimensions _____________________
% ✅ Ensure all arrays are nz x ny x nx as expected
assert(all(size(sigma_eff) == [nz, ny, nx]), 'sigma_eff array has wrong dimensions');
assert(all(size(phi) == [nz, ny, nx]), 'phi array has wrong dimensions');
assert(all(size(k) == [nz, ny, nx]), 'k array has wrong dimensions');
assert(all(size(rock_id) == [nz, ny, nx]), 'rock_id array has wrong dimensions');
assert(all(size(pressure) == [nz, ny, nx]), 'pressure array has wrong dimensions');
assert(all(size(saturation) == [nz, ny, nx]), 'saturation array has wrong dimensions');

% Substep 8.2 – Summary statistics ____________________________
% 📊 Calculate and report snapshot statistics
if nz == 1
    fprintf('[INFO] 2D Snapshot extracted for timestep %d:\n', timestep);
    fprintf('  Grid: %d x %d (2D with nz=1)\n', nx, ny);
else
    fprintf('[INFO] 3D Snapshot extracted for timestep %d:\n', timestep);
    fprintf('  Grid: %d x %d x %d (3D)\n', nx, ny, nz);
end
fprintf('  σ_eff: %.1f ± %.1f psi (range: %.1f - %.1f)\n', ...
    mean(sigma_eff(:)), std(sigma_eff(:)), min(sigma_eff(:)), max(sigma_eff(:)));
fprintf('  φ: %.3f ± %.3f (range: %.3f - %.3f)\n', ...
    mean(phi(:)), std(phi(:)), min(phi(:)), max(phi(:)));
fprintf('  k: %.1f ± %.1f mD (range: %.1f - %.1f)\n', ...
    mean(k(:)), std(k(:)), min(k(:)), max(k(:)));
fprintf('  p: %.1f ± %.1f psi (range: %.1f - %.1f)\n', ...
    mean(pressure(:)), std(pressure(:)), min(pressure(:)), max(pressure(:)));
fprintf('  s: %.3f ± %.3f (range: %.3f - %.3f)\n', ...
    mean(saturation(:)), std(saturation(:)), min(saturation(:)), max(saturation(:)));
fprintf('  Regions: %d unique values\n', length(unique(rock_id(:))));

end 