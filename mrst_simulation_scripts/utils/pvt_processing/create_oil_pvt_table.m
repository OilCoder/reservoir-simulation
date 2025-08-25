function pvto = create_oil_pvt_table(pvt_config)
% CREATE_OIL_PVT_TABLE - Create MRST oil PVT table from configuration
%
% Uses configuration data exclusively - no hard-coded formulas
%
% INPUT:
%   pvt_config - Configuration structure with fluid_properties
% OUTPUT:
%   pvto - Oil PVT table in MRST format [pressure, Rs, Bo, viscosity]

config = pvt_config.fluid_properties;

% ----------------------------------------
% Step 1 – Extract Configuration Data
% ----------------------------------------
pressures = config.oil_bo_pressure_table.pressures;
bo_values = config.oil_bo_pressure_table.bo_values; 
rs_values = config.solution_gor_table.rs_values;
viscosity_values = config.oil_viscosity_table.viscosity_values;

% ----------------------------------------
% Step 2 – Validate Data Consistency
% ----------------------------------------
n_points = length(pressures);
if length(bo_values) ~= n_points || length(rs_values) ~= n_points || ...
   length(viscosity_values) ~= n_points
    error('Oil PVT tables must have consistent length: pressures, bo_values, rs_values, viscosity_values');
end

% ----------------------------------------  
% Step 3 – Assemble MRST PVTO Table
% ----------------------------------------
% MRST PVTO format: [pressure, Rs, Bo, viscosity]
pvto = [pressures(:), rs_values(:), bo_values(:), viscosity_values(:)];

end