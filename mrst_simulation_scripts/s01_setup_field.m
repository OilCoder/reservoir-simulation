function [G, rock, fluid] = s01_setup_field(config_dir)
% s01_setup_field - Create MRST grid and rock properties from configuration
%
% Creates 20x20 cartesian grid with heterogeneous porosity and permeability
% based on reservoir configuration files. Uses MRST functions exclusively.
%
% Args:
%   config_dir: Path to configuration directory (optional, defaults to './config/')
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

% Substep 1.1 – Read configuration files ________________________
if nargin < 1
    config_dir = './config/';
end
config = util_read_config(config_dir);

% Substep 1.2 – Extract grid parameters from config _____________
nx = config.grid.nx;
ny = config.grid.ny;
nz = config.grid.nz;
dx = config.grid.dx * 0.3048;  % Convert ft to meters
dy = config.grid.dy * 0.3048;  % Convert ft to meters

% Handle variable layer thickness
if iscell(config.grid.dz) || length(config.grid.dz) > 1
    dz_layers = config.grid.dz * 0.3048;  % Convert ft to meters
else
    dz_layers = repmat(config.grid.dz * 0.3048, nz, 1);
end

fprintf('[INFO] Creating %dx%dx%d grid with %.1f x %.1f ft cells\n', nx, ny, nz, config.grid.dx, config.grid.dy);

%% ----
%% Step 2 – Create MRST grid
%% ----

% Substep 2.1 – Create cartesian grid ___________________________
G = cartGrid([nx, ny, nz], [nx*dx, ny*dy, sum(dz_layers)]);
G = computeGeometry(G);

% Set variable layer thickness if needed
if length(dz_layers) > 1
    % Update grid cell heights based on layers
    z_tops = [0; cumsum(dz_layers(1:end-1))];
    z_bottoms = cumsum(dz_layers);
    
    for k = 1:nz
        layer_cells = (k-1)*nx*ny + 1 : k*nx*ny;
        G.cells.centroids(layer_cells, 3) = (z_tops(k) + z_bottoms(k)) / 2;
    end
end

fprintf('[INFO] Grid created with %d cells\n', G.cells.num);

%% ----
%% Step 3 – Create rock properties
%% ----

% Substep 3.1 – Generate porosity from geological layers ________
poro_vec = zeros(G.cells.num, 1);
layer_id = zeros(G.cells.num, 1);

fprintf('[INFO] Assigning rock properties by geological layers\n');

% Assign properties based on geological layers
for c = 1:G.cells.num
    cell_depth = G.cells.centroids(c, 3) / 0.3048;  % Convert m to ft
    
    % Find which geological layer this cell belongs to
    found_layer = false;
    for i = 1:length(config.rock.layers)
        layer = config.rock.layers{i};
        if cell_depth >= layer.depth_range(1) && cell_depth <= layer.depth_range(2)
            poro_vec(c) = layer.porosity;
            layer_id(c) = layer.id;
            found_layer = true;
            break;
        end
    end
    
    % If no layer found, use default values
    if ~found_layer
        poro_vec(c) = config.porosity.base_value;
        layer_id(c) = 1;
    end
end

% Substep 3.2 – Generate permeability from geological layers ____
perm_vec = zeros(G.cells.num, 1);

% Assign permeability based on geological layers
for c = 1:G.cells.num
    cell_depth = G.cells.centroids(c, 3) / 0.3048;  % Convert m to ft
    
    % Find which geological layer this cell belongs to
    for i = 1:length(config.rock.layers)
        layer = config.rock.layers{i};
        if cell_depth >= layer.depth_range(1) && cell_depth <= layer.depth_range(2)
            perm_vec(c) = layer.permeability * 9.869233e-16;  % mD to m²
            break;
        end
    end
end

% Substep 3.3 – Create rock structure ___________________________
rock = makeRock(G, perm_vec, poro_vec);

% Add initial values for compaction
rock.poro0 = poro_vec;  % Initial porosity
rock.perm0 = perm_vec;  % Initial permeability

% Add rock regions based on geological layers
rock.regions = layer_id;

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
