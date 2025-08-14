function pvtg = create_gas_pvt_table(pvt_config)
% CREATE_GAS_PVT_TABLE - Create MRST gas PVT table from configuration
%
% Uses configuration data exclusively - no hard-coded formulas
%
% INPUT:
%   pvt_config - Configuration structure with fluid_properties
% OUTPUT:
%   pvtg - Gas PVT table in MRST format [pressure, Rv, Bg, viscosity]

config = pvt_config.fluid_properties;

% ----------------------------------------
% Step 1 – Extract Configuration Data  
% ----------------------------------------
pressures = config.gas_bg_pressure_table.pressures;
bg_values = config.gas_bg_pressure_table.bg_values;
viscosity_values = config.gas_viscosity_table.viscosity_values;

% ----------------------------------------
% Step 2 – Extract Gas-Oil Ratio (Rv)
% ----------------------------------------
% For dry gas system, Rv = 0 (no oil vaporization into gas phase)
if isfield(config.gas_properties, 'rv_dry_gas')
    rv_values = config.gas_properties.rv_dry_gas * ones(size(pressures));
else
    rv_values = zeros(size(pressures));  % Default for dry gas
end

% ----------------------------------------
% Step 3 – Validate Data Consistency
% ----------------------------------------
n_points = length(pressures);
if length(bg_values) ~= n_points || length(viscosity_values) ~= n_points
    error('Gas PVT tables must have consistent length: pressures, bg_values, viscosity_values');
end

% ----------------------------------------
% Step 4 – Convert Units for MRST
% ----------------------------------------
% Convert gas viscosity from cp to Pa·s  
gas_viscosity_pas = viscosity_values * 1e-3;  % cp to Pa·s

% ----------------------------------------
% Step 5 – Assemble MRST PVTG Table
% ----------------------------------------
% MRST PVTG format: [pressure, Rv, Bg, viscosity]
pvtg = [pressures(:), rv_values(:), bg_values(:), gas_viscosity_pas(:)];

end