function [swi_by_type, sor_by_type, sgr_by_type, pc_params] = validate_and_extract_scal_parameters(scal_config)
% VALIDATE_AND_EXTRACT_SCAL_PARAMETERS - Extract SCAL data from config
%
% Implements FAIL_FAST policy - terminates if required data missing
%
% INPUT:
%   scal_config - SCAL configuration structure
% OUTPUT:
%   swi_by_type - Irreducible water saturation by rock type
%   sor_by_type - Residual oil saturation by rock type  
%   sgr_by_type - Residual gas saturation by rock type
%   pc_params - Capillary pressure parameters by rock type

% ----------------------------------------
% Step 1 – Validate Configuration Structure
% ----------------------------------------
if ~isstruct(scal_config) || ~isfield(scal_config, 'scal_properties')
    error('Invalid SCAL config. Provide valid scal_properties_config.yaml');
end

config = scal_config.scal_properties;

% ----------------------------------------
% Step 2 – Validate Rock Types Section
% ----------------------------------------
if ~isfield(config, 'rock_types')
    error('Missing rock_types section in scal_properties_config.yaml');
end

rock_types = config.rock_types;

% ----------------------------------------
% Step 3 – Extract Parameters for Each Rock Type
% ----------------------------------------
rock_type_names = fieldnames(rock_types);
n_types = length(rock_type_names);

swi_by_type = zeros(n_types, 1);
sor_by_type = zeros(n_types, 1);
sgr_by_type = zeros(n_types, 1);
pc_params = struct();

for i = 1:n_types
    type_name = rock_type_names{i};
    rock_type_data = rock_types.(type_name);
    
    % Validate saturation endpoints
    if ~isfield(rock_type_data, 'saturation_endpoints')
        error('Missing saturation_endpoints for rock type %s', type_name);
    end
    
    endpoints = rock_type_data.saturation_endpoints;
    required_sat_fields = {'swi', 'sor', 'sgr'};
    
    for j = 1:length(required_sat_fields)
        field = required_sat_fields{j};
        if ~isfield(endpoints, field)
            error('Missing %s in saturation_endpoints for rock type %s', field, type_name);
        end
    end
    
    % Extract saturation endpoints
    swi_by_type(i) = endpoints.swi;
    sor_by_type(i) = endpoints.sor;
    sgr_by_type(i) = endpoints.sgr;
    
    % Validate capillary pressure parameters
    if ~isfield(rock_type_data, 'capillary_pressure')
        error('Missing capillary_pressure section for rock type %s', type_name);
    end
    
    cap_pressure = rock_type_data.capillary_pressure;
    required_pc_fields = {'entry_pressure_psi', 'lambda', 'max_pc_psi'};
    
    for j = 1:length(required_pc_fields)
        field = required_pc_fields{j};
        if ~isfield(cap_pressure, field)
            error('Missing %s in capillary_pressure for rock type %s', field, type_name);
        end
    end
    
    % Extract capillary pressure parameters
    pc_params.(type_name) = struct();
    pc_params.(type_name).entry_pressure = cap_pressure.entry_pressure_psi;
    pc_params.(type_name).lambda = cap_pressure.lambda;
    pc_params.(type_name).max_pc = cap_pressure.max_pc_psi;
end

end