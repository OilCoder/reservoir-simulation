function validate_pvt_config(pvt_config)
% VALIDATE_PVT_CONFIG - Validate required PVT configuration fields
%
% Implements FAIL_FAST policy - terminates immediately if required data missing

% ----------------------------------------
% Step 1 – Check Root Configuration Structure
% ----------------------------------------
if ~isstruct(pvt_config)
    error('PVT config must be a structure. Provide valid fluid_properties_config.yaml');
end

if ~isfield(pvt_config, 'fluid_properties')
    error('Missing fluid_properties section in config. Add to fluid_properties_config.yaml');
end

config = pvt_config.fluid_properties;

% ----------------------------------------
% Step 2 – Validate Oil PVT Data
% ----------------------------------------
validate_oil_pvt_data(config);

% ----------------------------------------  
% Step 3 – Validate Water PVT Data
% ----------------------------------------
validate_water_pvt_data(config);

% ----------------------------------------
% Step 4 – Validate Gas PVT Data  
% ----------------------------------------
validate_gas_pvt_data(config);

end


function validate_oil_pvt_data(config)
% Validate oil PVT table requirements

required_fields = {'oil_bo_pressure_table', 'solution_gor_table', 'oil_viscosity_table'};
for i = 1:length(required_fields)
    field = required_fields{i};
    if ~isfield(config, field)
        error('Missing %s in fluid_properties_config.yaml. Required for oil PVT.', field);
    end
end

% Validate oil Bo table structure
oil_bo = config.oil_bo_pressure_table;
if ~isfield(oil_bo, 'pressures') || ~isfield(oil_bo, 'bo_values')
    error('oil_bo_pressure_table requires pressures and bo_values arrays');
end

if length(oil_bo.pressures) ~= length(oil_bo.bo_values)
    error('oil_bo_pressure_table: pressures and bo_values must have same length');
end

end


function validate_water_pvt_data(config)
% Validate water PVT table requirements

if ~isfield(config, 'water_bw_pressure_table')
    error('Missing water_bw_pressure_table in fluid_properties_config.yaml');
end

if ~isfield(config, 'water_compressibility_table') 
    error('Missing water_compressibility_table in fluid_properties_config.yaml');
end

water_bw = config.water_bw_pressure_table;
if ~isfield(water_bw, 'pressures') || ~isfield(water_bw, 'bw_values')
    error('water_bw_pressure_table requires pressures and bw_values arrays');
end

end


function validate_gas_pvt_data(config)
% Validate gas PVT table requirements

if ~isfield(config, 'gas_bg_pressure_table')
    error('Missing gas_bg_pressure_table in fluid_properties_config.yaml');
end

if ~isfield(config, 'gas_viscosity_table')
    error('Missing gas_viscosity_table in fluid_properties_config.yaml');
end

gas_bg = config.gas_bg_pressure_table;  
if ~isfield(gas_bg, 'pressures') || ~isfield(gas_bg, 'bg_values')
    error('gas_bg_pressure_table requires pressures and bg_values arrays');
end

end