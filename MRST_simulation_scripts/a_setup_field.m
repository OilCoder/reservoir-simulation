function [G, rock, fluid] = a_setup_field(config_file)
% a_setup_field - Create MRST grid and rock properties from configuration
%
% Creates 20x20 cartesian grid with heterogeneous porosity and permeability
% based on reservoir configuration file. Uses MRST functions exclusively.
%
% Args:
%   config_file: Path to YAML configuration file
%
% Returns:
%   G: MRST grid structure
%   rock: MRST rock structure with porosity and permeability
%   fluid: Empty fluid structure (placeholder)
%
% Requires: MRST

%% ----
%% Step 1 – Load configuration
%% ----

% Substep 1.1 – Read configuration file ________________________
config = util_read_config(config_file);

% Substep 1.2 – Extract grid parameters from config _____________
nx = config.grid.nx;
ny = config.grid.ny;
dx = config.grid.dx * 0.3048;  % Convert ft to meters
dy = config.grid.dy * 0.3048;  % Convert ft to meters
dz = config.grid.dz * 0.3048;  % Convert ft to meters

fprintf('[INFO] Creating %dx%d grid with %.1f x %.1f ft cells\n', nx, ny, config.grid.dx, config.grid.dy);

%% ----
%% Step 2 – Create MRST grid
%% ----

% Substep 2.1 – Create cartesian grid ___________________________
G = cartGrid([nx, ny], [nx*dx, ny*dy]);
G = computeGeometry(G);

fprintf('[INFO] Grid created with %d cells\n', G.cells.num);

%% ----
%% Step 3 – Create rock properties
%% ----

% Substep 3.1 – Generate heterogeneous porosity from config _____
poro_base = config.porosity.base_value;
poro_var = config.porosity.variation_amplitude;

% Use actual grid dimensions
nx_grid = nx;
ny_grid = ny;
fprintf('[INFO] Using grid dimensions for porosity: %dx%d\n', nx_grid, ny_grid);

% Create spatial correlation using simple 2D pattern
[X, Y] = meshgrid(1:nx_grid, 1:ny_grid);  % X, Y are ny_grid x nx_grid

% Element‐wise porosity pattern
poro_pattern = poro_base + poro_var * sin(2*pi*X/nx_grid) .* cos(2*pi*Y/ny_grid);

% Add random variation
rng(42);  % For reproducibility
poro_random = poro_var * 0.5 * (rand(ny_grid, nx_grid) - 0.5);

% Final porosity field
poro_field = poro_pattern + poro_random;

% Apply bounds from config
poro_field = max(config.porosity.min_value, min(config.porosity.max_value, poro_field));

% Convert to vector for MRST (transpose for column-major ordering)
poro_vec = reshape(poro_field', [], 1);

% Substep 3.2 – Generate permeability from porosity and config ___
% Use Kozeny-Carman type relation
perm_base = config.permeability.base_value * 9.869233e-16;  % mD to m²
poro_ref = poro_base;

% k = k0 * (phi/phi0)^n
perm_vec = perm_base * (poro_vec / poro_ref).^3;

% Apply bounds from config
perm_min = config.permeability.min_value * 9.869233e-16;   % mD to m²
perm_max = config.permeability.max_value * 9.869233e-16;  % mD to m²
perm_vec = max(perm_min, min(perm_max, perm_vec));

% Substep 3.3 – Create rock structure ___________________________
rock = makeRock(G, perm_vec, poro_vec);

% Add initial values for compaction
rock.poro0 = poro_vec;  % Initial porosity
rock.perm0 = perm_vec;  % Initial permeability

% Add rock regions (will be updated by define_rock_regions)
rock.regions = ones(G.cells.num, 1);

fprintf('[INFO] Rock properties created\n');
fprintf('  Porosity: %.3f ± %.3f (range: %.3f - %.3f)\n', ...
    mean(poro_vec), std(poro_vec), min(poro_vec), max(poro_vec));
fprintf('  Permeability: %.1f ± %.1f mD (range: %.1f - %.1f mD)\n', ...
    mean(perm_vec/9.869233e-16), std(perm_vec/9.869233e-16), ...
    min(perm_vec/9.869233e-16), max(perm_vec/9.869233e-16));

%% ----
%% Step 4 – Create placeholder fluid
%% ----

% Substep 4.1 – Create empty fluid structure ____________________
fluid = struct();
fluid.name = 'placeholder';

fprintf('[INFO] Setup field completed successfully\n');

end 