function unit_conversion = validate_and_get_unit_conversion(init_config)
% VALIDATE_AND_GET_UNIT_CONVERSION - Extract unit conversion factors from config
%
% Implements FAIL_FAST policy - no hard-coded conversion factors
%
% INPUT:
%   init_config - Initialization configuration structure
% OUTPUT:
%   unit_conversion - Structure with validated conversion factors

% ----------------------------------------
% Step 1 – Validate Configuration Structure
% ----------------------------------------
if ~isstruct(init_config) || ~isfield(init_config, 'initialization')
    error('Invalid initialization config. Provide valid initialization_config.yaml');
end

config = init_config.initialization;

% ----------------------------------------
% Step 2 – Validate Unit Conversion Section
% ----------------------------------------
if ~isfield(config, 'unit_conversions')
    error('Missing unit_conversions section in initialization_config.yaml. Add length conversions.');
end

conversions = config.unit_conversions;

% ----------------------------------------
% Step 3 – Validate Required Conversion Factors
% ----------------------------------------
if ~isfield(conversions, 'length')
    error('Missing length conversions in unit_conversions section');
end

length_conv = conversions.length;
if ~isfield(length_conv, 'm_to_ft')
    error('Missing m_to_ft conversion factor in unit_conversions.length');
end

% ----------------------------------------
% Step 4 – Extract Validated Conversion Factors
% ----------------------------------------
unit_conversion = struct();
unit_conversion.m_to_ft = length_conv.m_to_ft;

% Validate conversion factor is reasonable
if unit_conversion.m_to_ft < 3.0 || unit_conversion.m_to_ft > 4.0
    error('Invalid m_to_ft conversion factor: %.6f. Expected ~3.28084', unit_conversion.m_to_ft);
end

end