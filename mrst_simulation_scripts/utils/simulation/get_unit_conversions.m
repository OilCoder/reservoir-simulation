function conversions = get_unit_conversions(init_config)
% GET_UNIT_CONVERSIONS - Extract unit conversion factors from config
%
% Implements FAIL_FAST policy - no hard-coded conversion factors
%
% INPUT:
%   init_config - Initialization configuration structure
% OUTPUT:
%   conversions - Structure with validated conversion factors

% ----------------------------------------
% Step 1 – Validate Configuration Structure
% ----------------------------------------
if ~isstruct(init_config) || ~isfield(init_config, 'initialization')
    error('Invalid initialization config for unit conversions');
end

config = init_config.initialization;

% ----------------------------------------
% Step 2 – Validate Unit Conversions Section
% ----------------------------------------
if ~isfield(config, 'unit_conversions')
    error('Missing unit_conversions section in initialization_config.yaml');
end

unit_conv = config.unit_conversions;

% ----------------------------------------
% Step 3 – Extract Pressure Conversions
% ----------------------------------------
if ~isfield(unit_conv, 'pressure')
    error('Missing pressure conversions in unit_conversions');
end

pressure_conv = unit_conv.pressure;
if ~isfield(pressure_conv, 'psi_to_pa')
    error('Missing psi_to_pa conversion factor in unit_conversions.pressure');
end

% ----------------------------------------
% Step 4 – Extract All Conversions
% ----------------------------------------
conversions = struct();
conversions.psi_to_pa = pressure_conv.psi_to_pa;
conversions.pa_to_psi = pressure_conv.pa_to_psi;

if isfield(unit_conv, 'length')
    conversions.m_to_ft = unit_conv.length.m_to_ft;
    conversions.ft_to_m = unit_conv.length.ft_to_m;
end

% ----------------------------------------
% Step 5 – Validate Conversion Factors
% ----------------------------------------
if conversions.psi_to_pa < 6800 || conversions.psi_to_pa > 7000
    error('Invalid psi_to_pa conversion factor: %.6f. Expected ~6894.76', conversions.psi_to_pa);
end

end