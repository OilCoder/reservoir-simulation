function initial_saturations = validate_and_extract_initial_saturations(init_config)
% VALIDATE_AND_EXTRACT_INITIAL_SATURATIONS - Extract saturation data from config
%
% Implements FAIL_FAST policy - terminates if required data missing
%
% INPUT:
%   init_config - Initialization configuration structure  
% OUTPUT:
%   initial_saturations - Structure with validated saturation data

% ----------------------------------------
% Step 1 – Validate Configuration Structure
% ----------------------------------------
if ~isstruct(init_config) || ~isfield(init_config, 'initialization')
    error('Invalid initialization config. Provide valid initialization_config.yaml');
end

config = init_config.initialization;

% ----------------------------------------
% Step 2 – Validate Initial Saturations Section
% ----------------------------------------
if ~isfield(config, 'initial_saturations') || ~isfield(config.initial_saturations, 'oil_zone')
    error('Missing initial_saturations.oil_zone section in initialization_config.yaml');
end

oil_zone = config.initial_saturations.oil_zone;

% ----------------------------------------
% Step 3 – Validate Required Oil Zone Fields
% ----------------------------------------
required_fields = {'oil_saturation_range', 'water_saturation_range', 'gas_saturation'};
for i = 1:length(required_fields)
    field = required_fields{i};
    if ~isfield(oil_zone, field)
        error('Missing %s in initial_saturations.oil_zone section', field);
    end
end

% ----------------------------------------
% Step 4 – Extract Average Values and Validate
% ----------------------------------------
so_range = oil_zone.oil_saturation_range;
sw_range = oil_zone.water_saturation_range;
sg = oil_zone.gas_saturation;

% Use average values from ranges
so = mean(so_range);
sw = mean(sw_range);

if sw + so + sg ~= 1.0
    error('Initial saturations must sum to 1.0. Got sw=%.3f, so=%.3f, sg=%.3f (sum=%.3f)', ...
        sw, so, sg, sw + so + sg);
end

if sw < 0 || so < 0 || sg < 0 || sw > 1 || so > 1 || sg > 1
    error('Invalid saturation values. All must be between 0 and 1');
end

% ----------------------------------------
% Step 5 – Extract Validated Data
% ----------------------------------------
initial_saturations = struct();
initial_saturations.sw = sw;
initial_saturations.so = so;
initial_saturations.sg = sg;

end