function pvtw = create_water_pvt_table(pvt_config)
% CREATE_WATER_PVT_TABLE - Create MRST water PVT table from configuration
%
% Uses configuration data exclusively - no hard-coded formulas
%
% INPUT:
%   pvt_config - Configuration structure with fluid_properties  
% OUTPUT:
%   pvtw - Water PVT table in MRST format [p_ref, Bw_ref, compressibility, viscosity, vw]

config = pvt_config.fluid_properties;

% ----------------------------------------
% Step 1 – Extract Reference Conditions
% ----------------------------------------  
p_ref = config.initial_reservoir_pressure;  % Use reservoir pressure as reference
bw_ref = config.water_bw_pressure_table.bw_values(1);  % First value as reference

% ----------------------------------------
% Step 2 – Extract Water Properties
% ----------------------------------------
water_viscosity = config.water_properties.water_viscosity;  % cp
water_compressibility = config.water_compressibility_table.cw_values(1);  % 1/psi
viscosity_gradient = config.water_properties.water_viscosibility;  % Usually 0

% ----------------------------------------
% Step 3 – Convert Units for MRST
% ----------------------------------------
% MRST expects viscosity in Pa·s, compressibility in 1/Pa
water_viscosity_pas = water_viscosity * 1e-3;  % cp to Pa·s
water_compressibility_pa = water_compressibility / 6894.76;  % 1/psi to 1/Pa

% ----------------------------------------
% Step 4 – Assemble MRST PVTW Table
% ----------------------------------------
% MRST PVTW format: [p_ref, Bw_ref, compressibility, viscosity, viscosity_gradient]
pvtw = [p_ref, bw_ref, water_compressibility_pa, water_viscosity_pas, viscosity_gradient];

end