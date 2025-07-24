function [output] = script_name(input_params)
% script_name - Brief description of reservoir simulation script purpose
%
% Detailed description of what this script accomplishes in the reservoir
% simulation workflow.
%
% Args:
%   input_params - Structure containing input parameters
%                  .field1 - Description [units]
%                  .field2 - Description [units]
%
% Returns:
%   output - Structure containing simulation results
%            .result1 - Description [units]
%            .result2 - Description [units]
%
% Requires: MRST

% ----------------------------------------
% Step 1 – MRST Environment and Configuration
% ----------------------------------------

fprintf('[INFO] Starting reservoir simulation script...\n');

% Substep 1.1 – Load MRST and required modules ______________________
try
    % Ensure MRST is loaded
    if ~exist('cartGrid', 'file')
        s00_initialize_mrst();
    end
    
    % Load additional modules as needed
    mrstModule add ad-core ad-blackoil ad-props incomp;
    
catch ME
    error('[ERROR] Failed to initialize MRST: %s', ME.message);
end

% Substep 1.2 – Load configuration parameters ______________________
try
    config = util_read_config();
    fprintf('[INFO] Configuration loaded successfully\n');
catch ME
    warning('[WARNING] Could not load config, using defaults: %s', ME.message);
    config = struct();
end

% ----------------------------------------
% Step 2 – Grid and Geometry Setup
% ----------------------------------------

% Substep 2.1 – Create computational grid ______________________
% Grid dimensions from config or defaults
nx = config.grid.nx;
ny = config.grid.ny; 
nz = config.grid.nz;

% Physical dimensions
Lx = nx * config.grid.dx;  % [ft]
Ly = ny * config.grid.dy;  % [ft]
Lz = sum(config.grid.dz);  % [ft]

% Create Cartesian grid
G = cartGrid([nx, ny, nz], [Lx, Ly, Lz]);
G = computeGeometry(G);

fprintf('[INFO] Grid created: %d x %d x %d cells\n', nx, ny, nz);

% ----------------------------------------
% Step 3 – Rock Properties Definition
% ----------------------------------------

% Substep 3.1 – Generate porosity field ______________________
% Base porosity with spatial variation
base_poro = config.porosity.base_value;
poro_variation = config.porosity.variation_amplitude;

% Create spatially correlated porosity field
poro = base_poro + poro_variation * rand(G.cells.num, 1);

% Apply bounds
poro = max(poro, config.porosity.bounds.min);
poro = min(poro, config.porosity.bounds.max);

% Substep 3.2 – Generate permeability field ______________________
% Permeability correlated with porosity
base_perm = config.permeability.base_value;  % [mD]

% Convert to MRST units
perm = base_perm * (poro / base_poro).^3 * milli*darcy;

% Create rock structure
rock = makeRock(G, perm, poro);

fprintf('[INFO] Rock properties defined\n');
fprintf('      Porosity range: [%.3f, %.3f]\n', min(poro), max(poro));
fprintf('      Permeability range: [%.1f, %.1f] mD\n', ...
        min(perm)/milli/darcy, max(perm)/milli/darcy);

% ----------------------------------------
% Step 4 – Fluid Properties Definition
% ----------------------------------------

% Substep 4.1 – Create fluid model ______________________
% Define fluid properties from config
mu_w = config.fluid.water.viscosity * centi*poise;  % [cP]
mu_o = config.fluid.oil.viscosity * centi*poise;    % [cP]

rho_w = config.fluid.water.density;  % [kg/m³]
rho_o = config.fluid.oil.density;    % [kg/m³]

% Create simple fluid model
fluid = initSimpleFluid('mu', [mu_w, mu_o], ...
                       'rho', [rho_w, rho_o], ...
                       'n', [2, 2]);

fprintf('[INFO] Fluid properties defined\n');

% ----------------------------------------
% Step 5 – Main Simulation Logic
% ----------------------------------------

% Substep 5.1 – Implement main processing ______________________
% Add specific simulation logic here based on script purpose
% This section will vary depending on the specific simulation task

% Example: Initialize simulation state
state = initResSol(G, 0.0);
state.wellSol = [];

% Substep 5.2 – Execute simulation steps ______________________
% Add time-stepping or steady-state solution logic
% This is where the main reservoir simulation occurs

% ----------------------------------------
% Step 6 – Results Processing and Output
% ----------------------------------------

% Substep 6.1 – Prepare output structure ______________________
output = struct();
output.grid = G;
output.rock = rock;
output.fluid = fluid;
output.state = state;
output.config = config;

% Substep 6.2 – Generate summary information ______________________
output.summary = struct();
output.summary.cells_total = G.cells.num;
output.summary.pore_volume = sum(poreVolume(G, rock));
output.summary.avg_porosity = mean(rock.poro);
output.summary.avg_permeability = mean(rock.perm) / milli / darcy;  % [mD]

fprintf('[INFO] Simulation completed successfully\n');
fprintf('      Total cells: %d\n', output.summary.cells_total);
fprintf('      Total pore volume: %.2e ft³\n', output.summary.pore_volume);

end