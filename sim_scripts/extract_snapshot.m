function [sigma_eff, phi, k, rock_id] = extract_snapshot(G, rock, state, timestep)
% extract_snapshot - Extract 20x20 matrices from simulation state
%
% Extracts and processes simulation data into 20x20 matrices for ML training:
% - Effective stress (σ')
% - Porosity (φ)
% - Permeability (k)
% - Rock region ID
%
% Args:
%   G: MRST grid structure
%   rock: MRST rock structure with regions
%   state: MRST simulation state for specific timestep
%   timestep: Current timestep number (for reference)
%
% Returns:
%   sigma_eff: 20x20 matrix of effective stress [psi]
%   porosity: 20x20 matrix of current porosity [-]
%   permeability: 20x20 matrix of current permeability [mD]
%   rock_id: 20x20 matrix of rock region IDs [-]
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
assert(G.cartDims(1) == 20 && G.cartDims(2) == 20, ...
    'Grid must be 20x20 for snapshot extraction');

nx = G.cartDims(1);
ny = G.cartDims(2);

%% ----
%% Step 2 – Extract pressure and calculate effective stress
%% ----

% Substep 2.1 – Get pressure field _____________________________
% ✅ Extract pressure from simulation state
pressure = state.pressure;  % [psi internal units]

% Substep 2.2 – Calculate effective stress _____________________
% 🔄 Effective stress: σ' = σ_total - α * p_pore
% For simplicity, assume total stress is lithostatic
% and Biot coefficient α = 1

% Substep 1.1 – Calculate effective stress ____________________
% ✅ Terzaghi's effective stress: σ' = σ_total - p_pore
% Assume lithostatic stress gradient and initial conditions

% Get pressure from state
p_pore = state.pressure / psia;  % Convert to psia for consistency

% Calculate depth-dependent total stress (lithostatic)
% For 2D grid, use relative depth based on grid position
if size(G.cells.centroids, 2) >= 3
    % 3D grid - use actual Z coordinates
    depths = G.cells.centroids(:,3) * 3.28084;  % Convert m to ft
else
    % 2D grid - use relative depth based on Y position (assuming Y is depth)
    depths = G.cells.centroids(:,2) * 3.28084;  % Convert m to ft
end
sigma_total = 2000 + 1.0 * depths;  % Total stress in psi (2000 psi surface + 1 psi/ft)

% Calculate effective stress
sigma_eff = sigma_total - p_pore;

% ✅ Ensure positive effective stress (physical constraint)
if any(sigma_eff < 0)
    fprintf('[WARN] Adjusting %d negative effective stress values\n', sum(sigma_eff < 0));
    sigma_eff = max(sigma_eff, 100);  % Minimum 100 psi effective stress
end

%% ----
%% Step 3 – Extract porosity
%% ----

% Substep 3.1 – Current porosity calculation ___________________
% Substep 1.2 – Update porosity from compaction ________________
% 🔄 Apply pressure-dependent porosity changes
if isfield(rock, 'c_phi')
    % Calculate porosity change due to effective stress
    dp_eff = sigma_eff - 2000;  % Change from reference effective stress
    phi_vec = rock.poro0 .* (1 + rock.c_phi .* dp_eff);
    phi_vec = max(0.01, min(0.5, phi_vec));  % Physical bounds
else
    phi_vec = rock.poro;
end

%% ----
%% Step 4 – Calculate permeability
%% ----

% Substep 4.1 – Update permeability with porosity ______________
% Substep 1.3 – Update permeability from φ-k relationship ______
% 🔄 Apply Kozeny-Carman or power law: k = k₀ * (φ/φ₀)^n
if isfield(rock, 'k_phi_exp')
    phi_ratio = phi_vec ./ rock.poro0;
    k_vec = rock.perm .* (phi_ratio .^ rock.k_phi_exp);
else
    k_vec = rock.perm;
end

% Convert to consistent units
k_vec = k_vec / milli / darcy;  % Convert to mD

%% ----
%% Step 5 – Extract rock regions
%% ----

% Substep 5.1 – Get rock region IDs ____________________________
% Substep 1.4 – Get rock region IDs ____________________________
rock_id_vec = rock.regions;

%% ----
%% Step 2 – Reshape to 2D matrices
%% ----

% Substep 2.1 – Reshape vectors to 2D matrices _________________
% ✅ MRST uses column-major ordering (Fortran style)
sigma_eff = reshape(sigma_eff, [nx, ny])';     % [psi]
phi = reshape(phi_vec, [nx, ny])';             % [-]
k = reshape(k_vec, [nx, ny])';                 % [mD]
rock_id = reshape(rock_id_vec, [nx, ny])';     % [-]

%% ----
%% Step 3 – Output preparation
%% ----

% Substep 3.1 – Validate matrix dimensions _____________________
% ✅ Ensure all matrices are 20x20 as expected
assert(all(size(sigma_eff) == [20, 20]), 'sigma_eff matrix is not 20x20');
assert(all(size(phi) == [20, 20]), 'phi matrix is not 20x20');
assert(all(size(k) == [20, 20]), 'k matrix is not 20x20');
assert(all(size(rock_id) == [20, 20]), 'rock_id matrix is not 20x20');

% Substep 3.2 – Summary statistics ____________________________
% 📊 Calculate and report snapshot statistics
fprintf('[INFO] Snapshot extracted for timestep %d:\n', timestep);
fprintf('  σ_eff: %.1f ± %.1f psi (range: %.1f - %.1f)\n', ...
    mean(sigma_eff(:)), std(sigma_eff(:)), min(sigma_eff(:)), max(sigma_eff(:)));
fprintf('  φ: %.3f ± %.3f (range: %.3f - %.3f)\n', ...
    mean(phi(:)), std(phi(:)), min(phi(:)), max(phi(:)));
fprintf('  k: %.1f ± %.1f mD (range: %.1f - %.1f)\n', ...
    mean(k(:)), std(k(:)), min(k(:)), max(k(:)));
fprintf('  Regions: %d unique values\n', length(unique(rock_id(:))));

end 