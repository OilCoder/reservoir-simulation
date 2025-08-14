function fluid_complete = create_pvt_tables(fluid_with_pc, pvt_config, G)
% CREATE_PVT_TABLES - Assemble MRST fluid structure from configuration
%
% INPUT:
%   fluid_with_pc - Fluid with capillary pressure
%   pvt_config - PVT configuration structure (REQUIRED)
%   G - Grid structure
% OUTPUT:
%   fluid_complete - Complete MRST fluid with PVT tables

% ----------------------------------------
% Step 1 – Validate Configuration Prerequisites
% ----------------------------------------
validate_pvt_config(pvt_config);

% ---------------------------------------- 
% Step 2 – Extract Oil PVT Data
% ----------------------------------------
pvto = create_oil_pvt_table(pvt_config);

% ----------------------------------------
% Step 3 – Extract Water PVT Data  
% ----------------------------------------
pvtw = create_water_pvt_table(pvt_config);

% ----------------------------------------
% Step 4 – Extract Gas PVT Data
% ----------------------------------------
pvtg = create_gas_pvt_table(pvt_config);

% ----------------------------------------
% Step 5 – Assemble Complete Fluid Structure
% ----------------------------------------
fluid_complete = assemble_fluid_structure(fluid_with_pc, pvto, pvtw, pvtg, pvt_config);

end