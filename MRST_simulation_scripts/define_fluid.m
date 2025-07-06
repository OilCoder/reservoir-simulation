function fluid = define_fluid(config_file)
% define_fluid - Create fluid structure with viscosities, densities and kr curves
%
% Args:
%   config_file: Optional path to YAML configuration file
%
% Returns MRST fluid structure with:
% - Oil and water viscosities and densities
% - Simple relative permeability curves (initSimpleFluid)
% - Compressibility factors
%
% Returns:
%   fluid: MRST fluid structure ready for simulation
%
% Requires: MRST

%% ----
%% Step 1 – Load configuration
%% ----

if nargin < 1
    config_file = '../config/reservoir_config.yaml';
end

% Load configuration
config = util_read_config(config_file);

%% ----
%% Step 2 – Basic fluid properties from config
%% ----

% Substep 2.1 – Define fluid viscosities from config ___________
mu_oil = config.fluid.oil_viscosity * centi*poise;   % Oil viscosity
mu_water = config.fluid.water_viscosity * centi*poise; % Water viscosity

% Substep 2.2 – Define fluid densities from config _____________
% Convert from kg/m³ to lb/ft³ for field units
rho_oil_kgm3 = config.fluid.oil_density;     % kg/m³
rho_water_kgm3 = config.fluid.water_density; % kg/m³

% Convert to lb/ft³ for field units (1 kg/m³ = 0.062428 lb/ft³)
rho_oil = rho_oil_kgm3 * 0.062428;   % lb/ft³
rho_water = rho_water_kgm3 * 0.062428; % lb/ft³

%% ----
%% Step 3 – Relative permeability setup from config
%% ----

% Substep 3.1 – Set up simple relative permeability model ______
% ✅ Use MRST's initSimpleFluid for basic oil-water system
fluid = initSimpleFluid('mu' , [mu_water, mu_oil], ...
                       'rho', [rho_water, rho_oil], ...
                       'n'  , [2, 2]);  % Use default values for now

% Substep 3.2 – Set residual saturations from config ___________
% 📊 Values from simplified configuration - use default values
fluid.sWcon = 0.15;  % Connate water saturation
fluid.sOres = 0.20;  % Residual oil saturation

%% ----
%% Step 4 – Compressibility properties from config
%% ----

% Substep 4.1 – Oil compressibility from config _______________
% Use typical oil compressibility in field units
c_oil = 15e-6;  % Oil compressibility [1/psi] - typical value
fluid.cO = c_oil;

% Substep 4.2 – Water compressibility from config _____________
% Use typical water compressibility in field units
c_water = 3e-6;  % Water compressibility [1/psi] - typical value
fluid.cW = c_water;

%% ----
%% Step 5 – PVT properties from config
%% ----

% Substep 5.1 – Reference pressure and formation volume factors
p_ref = config.initial_conditions.pressure * psia;  % Reference pressure from config
fluid.bO = @(p) 1.2 * (1 + c_oil * (p - p_ref));   % Oil FVF
fluid.bW = @(p) 1.0 * (1 + c_water * (p - p_ref)); % Water FVF

% Substep 5.2 – Surface density functions ______________________
fluid.rhoOS = rho_oil;   % Oil density at surface conditions [lb/ft³]
fluid.rhoWS = rho_water; % Water density at surface conditions [lb/ft³]

%% ----
%% Step 6 – Validation and output
%% ----

% Substep 6.1 – Validate fluid structure _______________________
assert(isfield(fluid, 'krW'), 'Water relative permeability not defined');
assert(isfield(fluid, 'krO'), 'Oil relative permeability not defined');
assert(fluid.sWcon >= 0 && fluid.sWcon <= 1, 'Invalid connate water saturation');
assert(fluid.sOres >= 0 && fluid.sOres <= 1, 'Invalid residual oil saturation');

% Substep 6.2 – Summary output _________________________________
fprintf('[INFO] Fluid properties defined:\n');
fprintf('  Oil viscosity: %.2f cP\n', mu_oil / (centi*poise));
fprintf('  Water viscosity: %.2f cP\n', mu_water / (centi*poise));
fprintf('  Oil density: %.1f lb/ft³ (%.0f kg/m³)\n', rho_oil, rho_oil_kgm3);
fprintf('  Water density: %.1f lb/ft³ (%.0f kg/m³)\n', rho_water, rho_water_kgm3);
fprintf('  Connate water sat: %.2f\n', fluid.sWcon);
fprintf('  Residual oil sat: %.2f\n', fluid.sOres);
fprintf('  Oil compressibility: %.2e /psi\n', c_oil);
fprintf('  Water compressibility: %.2e /psi\n', c_water);
fprintf('  Reference pressure: %.0f psi\n', p_ref/psia);

fprintf('[INFO] Fluid structure ready for simulation\n');

end 