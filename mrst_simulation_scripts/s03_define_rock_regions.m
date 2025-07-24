function rock = s03_define_rock_regions(rock)
% s03_define_rock_regions - Generate rock.regions vector and assign lithology parameters
%
% Assigns geomechanical parameters (c_φ, n, k₀) by lithology to facilitate
% scaling to multiple rock types without rewriting setup_field.m
%
% Args:
%   rock: MRST rock structure with existing porosity and permeability
%
% Returns:
%   rock: Updated rock structure with regions and lithology parameters
%
% Requires: MRST

%% ----
%% Step 1 – Rock region classification
%% ----

% Substep 1.1 – Define porosity thresholds ____________________
poro_thresh_low = 0.18;   % Tight rock threshold
poro_thresh_high = 0.22;  % Loose rock threshold

% Substep 1.2 – Assign regions based on porosity ______________
% ✅ Region 1: Tight rock (low porosity)
% ✅ Region 2: Medium rock (intermediate porosity)  
% ✅ Region 3: Loose rock (high porosity)
rock.regions = zeros(size(rock.poro));
rock.regions(rock.poro < poro_thresh_low) = 1;
rock.regions(rock.poro >= poro_thresh_low & rock.poro < poro_thresh_high) = 2;
rock.regions(rock.poro >= poro_thresh_high) = 3;

%% ----
%% Step 2 – Lithology-specific parameters
%% ----

% Substep 2.1 – Compaction coefficients c_φ ___________________
% 📊 Region-specific compaction sensitivity
c_phi = zeros(size(rock.poro));
c_phi(rock.regions == 1) = 1e-5 / psia;  % Tight rock - low compaction
c_phi(rock.regions == 2) = 3e-5 / psia;  % Medium rock - moderate compaction
c_phi(rock.regions == 3) = 5e-5 / psia;  % Loose rock - high compaction

rock.c_phi = c_phi;

% Substep 2.2 – Permeability-porosity exponent n ______________
% 🔄 Kozeny-Carman type relation: k/k₀ = (φ/φ₀)ⁿ
n_exp = zeros(size(rock.poro));
n_exp(rock.regions == 1) = 8;   % Tight rock - sensitive to porosity changes
n_exp(rock.regions == 2) = 6;   % Medium rock - moderate sensitivity
n_exp(rock.regions == 3) = 4;   % Loose rock - less sensitive

rock.n_exp = n_exp;

% Substep 2.3 – Initial permeability k₀ _______________________
% 📊 Store initial permeability for porosity-permeability coupling
rock.perm0 = rock.perm;

%% ----
%% Step 3 – Regional statistics and validation
%% ----

% Substep 3.1 – Count cells by region __________________________
n_region1 = sum(rock.regions == 1);
n_region2 = sum(rock.regions == 2);
n_region3 = sum(rock.regions == 3);
n_total = length(rock.regions);

% Substep 3.2 – Validate region assignment ____________________
assert(n_region1 + n_region2 + n_region3 == n_total, ...
    'Region assignment incomplete');
assert(all(rock.regions >= 1 & rock.regions <= 3), ...
    'Invalid region values');

%% ----
%% Step 4 – Regional parameter summary
%% ----

% Substep 4.1 – Calculate regional averages ___________________
for i = 1:3
    mask = rock.regions == i;
    if sum(mask) > 0
        poro_avg = mean(rock.poro(mask));
        perm_avg = mean(rock.perm(mask)) / milli / darcy;
        c_phi_val = unique(rock.c_phi(mask));
        n_exp_val = unique(rock.n_exp(mask));
        
        fprintf('[INFO] Region %d (%d cells, %.1f%%):\n', i, sum(mask), 100*sum(mask)/n_total);
        fprintf('  Porosity: %.3f (avg)\n', poro_avg);
        fprintf('  Permeability: %.1f mD (avg)\n', perm_avg);
        fprintf('  Compaction coeff: %.2e /psia\n', c_phi_val);
        fprintf('  k-φ exponent: %.0f\n', n_exp_val);
    end
end

%% ----
%% Step 5 – Final validation
%% ----

% Substep 5.1 – Check parameter consistency ____________________
assert(all(rock.c_phi > 0), 'Invalid compaction coefficients');
assert(all(rock.n_exp > 0), 'Invalid permeability exponents');
assert(isfield(rock, 'perm0'), 'Initial permeability not stored');

fprintf('[INFO] Rock regions and lithology parameters defined\n');

end
