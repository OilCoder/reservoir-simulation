function fluid_complete = assemble_fluid_structure(fluid_with_pc, pvto, pvtw, pvtg, pvt_config)
% ASSEMBLE_FLUID_STRUCTURE - Combine PVT tables into complete MRST fluid
%
% INPUT:
%   fluid_with_pc - Base fluid structure with capillary pressure
%   pvto - Oil PVT table 
%   pvtw - Water PVT table
%   pvtg - Gas PVT table
%   pvt_config - Configuration for surface conditions
% OUTPUT:
%   fluid_complete - Complete MRST fluid ready for simulation

config = pvt_config.fluid_properties;

% ----------------------------------------
% Step 1 – Copy Base Fluid Structure
% ----------------------------------------
fluid_complete = fluid_with_pc;

% ----------------------------------------
% Step 2 – Add PVT Tables
% ----------------------------------------
fluid_complete.pvto = pvto;
fluid_complete.pvtw = pvtw;
fluid_complete.pvtg = pvtg;

% ----------------------------------------  
% Step 3 – Add Surface Conditions from Configuration
% ----------------------------------------
fluid_complete.surface = struct();

% Extract surface conditions from config (convert °F to K, psia to Pa)
surface_temp_f = config.surface_temperature;  % °F
surface_pressure_psia = config.surface_pressure;  % psia

% Unit conversions
surface_temp_k = (surface_temp_f - 32) * 5/9 + 273.15;  % °F to K
surface_pressure_pa = surface_pressure_psia * 6894.76;  % psia to Pa

fluid_complete.surface.temperature_k = surface_temp_k;
fluid_complete.surface.pressure_pa = surface_pressure_pa;

% ----------------------------------------
% Step 4 – Add Fluid Model Configuration
% ----------------------------------------
if isfield(config, 'mrst_fluid_config')
    fluid_complete.model_config = config.mrst_fluid_config;
end

end