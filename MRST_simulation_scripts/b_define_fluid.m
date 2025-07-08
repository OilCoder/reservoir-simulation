function fluid = b_define_fluid(config_file)
% b_define_fluid - Create MRST fluid structure from configuration
%
% Creates two-phase oil-water fluid with properties from configuration.
% Uses MRST initSimpleFluid function with realistic relative permeability curves.
%
% Args:
%   config_file: Path to YAML configuration file
%
% Returns:
%   fluid: MRST fluid structure with oil-water properties
%
% Requires: MRST

%% ----
%% Step 1 – Load configuration
%% ----

% Substep 1.1 – Read configuration file ________________________
config = util_read_config(config_file);

fprintf('[INFO] Creating two-phase oil-water fluid\n');

%% ----
%% Step 2 – Create MRST fluid
%% ----

% Substep 2.1 – Define fluid properties _________________________
% Viscosities [water, oil] in cP (converted to Pa·s)
mu_w = config.fluid.water_viscosity * 1e-3;  % cP to Pa·s
mu_o = config.fluid.oil_viscosity * 1e-3;    % cP to Pa·s

% Densities [water, oil] in kg/m³
rho_w = config.fluid.water_density;  % kg/m³
rho_o = config.fluid.oil_density;    % kg/m³

% Substep 2.2 – Create simple fluid with MRST ___________________
% Use MRST's initSimpleFluid function
fluid = initSimpleFluid('mu', [mu_w, mu_o], 'rho', [rho_w, rho_o], 'n', [2, 2]);

% Ensure viscosity field exists
if ~isfield(fluid, 'mu')
    fluid.mu = [mu_w, mu_o];
end

% Ensure density field exists
if ~isfield(fluid, 'rho')
    fluid.rho = [rho_w, rho_o];
end

fprintf('[INFO] Fluid properties set:\n');
fprintf('  Water: μ = %.1f cP, ρ = %.0f kg/m³\n', config.fluid.water_viscosity, config.fluid.water_density);
fprintf('  Oil: μ = %.1f cP, ρ = %.0f kg/m³\n', config.fluid.oil_viscosity, config.fluid.oil_density);

%% ----
%% Step 3 – Set saturation endpoints
%% ----

% Substep 3.1 – Define saturation limits _______________________
% Use configuration values if available, otherwise defaults
if isfield(config.fluid, 'connate_water_saturation')
    fluid.sWcon = config.fluid.connate_water_saturation;
else
    fluid.sWcon = 0.15;  % Default connate water saturation
end

if isfield(config.fluid, 'residual_oil_saturation')
    fluid.sOres = config.fluid.residual_oil_saturation;
else
    fluid.sOres = 0.20;  % Default residual oil saturation
end

% Critical saturations for relative permeability
fluid.sWcrit = fluid.sWcon;
fluid.sOcrit = fluid.sOres;

fprintf('  Saturation limits: Sw = %.2f - %.2f\n', fluid.sWcon, 1-fluid.sOres);

%% ----
%% Step 4 – Verify fluid structure
%% ----

% Substep 4.1 – Check required fields ___________________________
assert(isfield(fluid, 'krW'), 'Water relative permeability function missing');
assert(isfield(fluid, 'krO'), 'Oil relative permeability function missing');
assert(isfield(fluid, 'mu'), 'Viscosity values missing');
assert(isfield(fluid, 'rho'), 'Density values missing');

fprintf('[INFO] Fluid structure created successfully\n');

end 