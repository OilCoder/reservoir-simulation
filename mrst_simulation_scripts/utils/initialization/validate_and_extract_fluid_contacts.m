function fluid_contacts = validate_and_extract_fluid_contacts(init_config)
% VALIDATE_AND_EXTRACT_FLUID_CONTACTS - Extract fluid contact data from config
%
% Implements FAIL_FAST policy - terminates if required data missing
%
% INPUT:
%   init_config - Initialization configuration structure
% OUTPUT:
%   fluid_contacts - Structure with validated fluid contact data

% ----------------------------------------
% Step 1 – Validate Configuration Structure
% ----------------------------------------
if ~isstruct(init_config) || ~isfield(init_config, 'initialization')
    error('Invalid initialization config. Provide valid initialization_config.yaml');
end

config = init_config.initialization;

% ----------------------------------------
% Step 2 – Validate Fluid Contacts Section
% ----------------------------------------
if ~isfield(config, 'fluid_contacts')
    error('Missing fluid_contacts section in initialization_config.yaml');
end

contacts = config.fluid_contacts;

% ----------------------------------------
% Step 3 – Validate Oil-Water Contact
% ----------------------------------------
if ~isfield(contacts, 'oil_water_contact')
    error('Missing oil_water_contact in fluid_contacts section');
end

owc = contacts.oil_water_contact;
if ~isfield(owc, 'depth_ft_tvdss')
    error('Missing depth_ft_tvdss in oil_water_contact section');
end

% ----------------------------------------
% Step 4 – Validate Transition Zone
% ----------------------------------------
if ~isfield(contacts, 'transition_zones') || ...
   ~isfield(contacts.transition_zones, 'oil_water_transition')
    error('Missing transition_zones.oil_water_transition in initialization_config.yaml');
end

transition = contacts.transition_zones.oil_water_transition;
required_fields = {'top_ft_tvdss', 'bottom_ft_tvdss'};
for i = 1:length(required_fields)
    field = required_fields{i};
    if ~isfield(transition, field)
        error('Missing %s in oil_water_transition section', field);
    end
end

% ----------------------------------------
% Step 5 – Extract Validated Data
% ----------------------------------------
fluid_contacts = struct();
fluid_contacts.owc_depth = owc.depth_ft_tvdss;
fluid_contacts.transition_top = transition.top_ft_tvdss;
fluid_contacts.transition_bottom = transition.bottom_ft_tvdss;

end