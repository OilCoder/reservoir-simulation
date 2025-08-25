function fluid = s02_define_fluids()
% S02_DEFINE_FLUIDS - Define 3-phase fluid system for Eagle West Field

    script_dir = fileparts(mfilename('fullpath'));
    addpath(fullfile(script_dir, 'utils'));
    run(fullfile(script_dir, 'utils', 'print_utils.m'));
    
    print_step_header('S02', 'Define Fluid Properties');
    
    total_start_time = tic;
    
    % Step 1: Load and validate YAML configuration
    step_start = tic;
    config_file = fullfile(script_dir, 'config', 'fluid_properties_config.yaml');
    if ~exist(config_file, 'file')
        error('Fluid config file not found: %s\nREQUIRED: Create fluid_properties_config.yaml', config_file);
    end
    
    config_data = read_yaml_config(config_file);
    
    % Extract fluid properties from nested structure
    if ~isfield(config_data, 'fluid_properties')
        error('Missing fluid_properties section in config\nREQUIRED: Add fluid_properties section to config');
    end
    
    fluid_config = config_data.fluid_properties;
    
    % Validate required fields exist in the config
    required_fields = {'oil_density', 'water_density', 'gas_density', ...
                      'oil_viscosity', 'water_viscosity', 'gas_viscosity'};
    missing_fields = {};
    for i = 1:length(required_fields)
        if ~isfield(fluid_config, required_fields{i})
            missing_fields{end+1} = required_fields{i};
        end
    end
    
    if ~isempty(missing_fields)
        error('Missing fluid properties in config: %s\nREQUIRED: Add missing fields to fluid_properties_config.yaml', ...
              strjoin(missing_fields, ', '));
    end
    print_step_result(1, 'Load and Validate Configuration', 'success', toc(step_start));
    
    % Step 2: Create MRST fluid structure
    step_start = tic;
    rho = [fluid_config.water_density, fluid_config.oil_density, fluid_config.gas_density];
    mu = [fluid_config.water_viscosity, fluid_config.oil_viscosity, fluid_config.gas_viscosity];
    
    if exist('initSimpleADIFluid', 'file')
        fluid = initSimpleADIFluid('phases', 'WOG', 'rho', rho, 'mu', mu);
    else
        fluid = struct();
        fluid.phases = 'WOG';
        fluid.rhoWS = rho(1);
        fluid.rhoOS = rho(2); 
        fluid.rhoGS = rho(3);
        fluid.muW = mu(1);
        fluid.muO = mu(2);
        fluid.muG = mu(3);
    end
    print_step_result(2, 'Create MRST Fluid Structure', 'success', toc(step_start));
    
    % Step 3: Save consolidated fluid data
    step_start = tic;
    save_consolidated_data('fluid', 's02', 'fluid', fluid);
    print_step_result(3, 'Save Consolidated Fluid Data', 'success', toc(step_start));
    
    print_step_footer('S02', 'Fluid Properties Ready', toc(total_start_time));
end