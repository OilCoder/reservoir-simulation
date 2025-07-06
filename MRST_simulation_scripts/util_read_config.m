function config = util_read_config(config_file)
    % util_read_config.m
    % Simple and robust YAML configuration parser for Octave compatibility.
    
    if nargin < 1
        error('Configuration file path required');
    end
    
    if ~exist(config_file, 'file')
        error('Configuration file not found: %s', config_file);
    end
    
    % Read file content
    fid = fopen(config_file, 'r');
    if fid == -1
        error('Cannot open configuration file: %s', config_file);
    end
    
    yaml_content = {};
    while ~feof(fid)
        line = fgetl(fid);
        yaml_content{end+1} = line;
    end
    fclose(fid);
    
    % Initialize configuration with all required sections
    config = struct();
    config.grid = struct();
    config.porosity = struct();
    config.permeability = struct();
    config.rock = struct();
    config.fluid = struct();
    config.wells = struct();
    config.simulation = struct();
    config.initial_conditions = struct();
    config.geomechanics = struct();
    config.output = struct();
    config.metadata = struct();
    
    % Parse YAML content
    current_section = '';
    
    for i = 1:length(yaml_content)
        line = yaml_content{i};
        
        % Skip empty lines and comments
        if isempty(strtrim(line)) || (~isempty(strtrim(line)) && strtrim(line)(1) == '#')
            continue;
        end
        
        % Count indentation
        indent = length(line) - length(strtrim(line));
        trimmed_line = strtrim(line);
        
        % Parse key-value pairs
        if ~isempty(strfind(trimmed_line, ':'))
            colon_pos = strfind(trimmed_line, ':');
            key = strtrim(trimmed_line(1:colon_pos(1)-1));
            value_str = strtrim(trimmed_line(colon_pos(1)+1:end));
            
            % Remove comments from value
            if ~isempty(strfind(value_str, '#'))
                comment_pos = strfind(value_str, '#');
                value_str = strtrim(value_str(1:comment_pos(1)-1));
            end
            
            % Parse value
            value = parse_value(value_str);
            
            % Assign based on indentation level
            if indent == 0
                % Top level section
                current_section = key;
            elseif indent <= 2 && ~isempty(current_section)
                % Subsection - assign directly
                if strcmp(current_section, 'grid')
                    config.grid = setfield(config.grid, key, value);
                elseif strcmp(current_section, 'porosity')
                    config.porosity = setfield(config.porosity, key, value);
                elseif strcmp(current_section, 'permeability')
                    config.permeability = setfield(config.permeability, key, value);
                elseif strcmp(current_section, 'rock')
                    config.rock = setfield(config.rock, key, value);
                elseif strcmp(current_section, 'fluid')
                    config.fluid = setfield(config.fluid, key, value);
                elseif strcmp(current_section, 'wells')
                    config.wells = setfield(config.wells, key, value);
                elseif strcmp(current_section, 'simulation')
                    config.simulation = setfield(config.simulation, key, value);
                elseif strcmp(current_section, 'initial_conditions')
                    config.initial_conditions = setfield(config.initial_conditions, key, value);
                elseif strcmp(current_section, 'geomechanics')
                    config.geomechanics = setfield(config.geomechanics, key, value);
                elseif strcmp(current_section, 'output')
                    config.output = setfield(config.output, key, value);
                elseif strcmp(current_section, 'metadata')
                    config.metadata = setfield(config.metadata, key, value);
                end
            end
        end
    end
    
    % Set defaults for missing values
    config = set_defaults(config);
    
    fprintf('[INFO] Configuration loaded from: %s\n', config_file);
    
end

function config = set_defaults(config)
    % Set default values for missing configuration parameters
    
    % Grid defaults
    if ~isfield(config.grid, 'nx')
        config.grid.nx = 20;
    end
    if ~isfield(config.grid, 'ny')
        config.grid.ny = 20;
    end
    if ~isfield(config.grid, 'dx')
        config.grid.dx = 164;  % ft
    end
    if ~isfield(config.grid, 'dy')
        config.grid.dy = 164;  % ft
    end
    if ~isfield(config.grid, 'dz')
        config.grid.dz = 33;  % ft
    end
    
    % Porosity defaults
    if ~isfield(config.porosity, 'base_value')
        config.porosity.base_value = 0.2;
    end
    if ~isfield(config.porosity, 'variation_amplitude')
        config.porosity.variation_amplitude = 0.05;
    end
    if ~isfield(config.porosity, 'min_value')
        config.porosity.min_value = 0.05;
    end
    if ~isfield(config.porosity, 'max_value')
        config.porosity.max_value = 0.3;
    end
    
    % Permeability defaults
    if ~isfield(config.permeability, 'base_value')
        config.permeability.base_value = 100;  % mD
    end
    if ~isfield(config.permeability, 'variation_amplitude')
        config.permeability.variation_amplitude = 50;  % mD
    end
    if ~isfield(config.permeability, 'min_value')
        config.permeability.min_value = 1;  % mD
    end
    if ~isfield(config.permeability, 'max_value')
        config.permeability.max_value = 500;  % mD
    end
    
    % Rock defaults
    if ~isfield(config.rock, 'compressibility')
        config.rock.compressibility = 1e-5;  % 1/psi
    end
    if ~isfield(config.rock, 'n_regions')
        config.rock.n_regions = 3;
    end
    
    % Fluid defaults
    if ~isfield(config.fluid, 'oil_density')
        config.fluid.oil_density = 850;  % kg/m³
    end
    if ~isfield(config.fluid, 'water_density')
        config.fluid.water_density = 1000;  % kg/m³
    end
    if ~isfield(config.fluid, 'oil_viscosity')
        config.fluid.oil_viscosity = 2;  % cp
    end
    if ~isfield(config.fluid, 'water_viscosity')
        config.fluid.water_viscosity = 0.5;  % cp
    end
    
    % Wells defaults
    if ~isfield(config.wells, 'injector_i')
        config.wells.injector_i = 5;
    end
    if ~isfield(config.wells, 'injector_j')
        config.wells.injector_j = 10;
    end
    if ~isfield(config.wells, 'producer_i')
        config.wells.producer_i = 15;
    end
    if ~isfield(config.wells, 'producer_j')
        config.wells.producer_j = 10;
    end
    if ~isfield(config.wells, 'injector_rate')
        config.wells.injector_rate = 251;  % bbl/day
    end
    if ~isfield(config.wells, 'producer_bhp')
        config.wells.producer_bhp = 2175;  % psi
    end
    
    % Simulation defaults
    if ~isfield(config.simulation, 'total_time')
        config.simulation.total_time = 365;  % days
    end
    if ~isfield(config.simulation, 'num_timesteps')
        config.simulation.num_timesteps = 50;
    end
    
    % Initial conditions defaults
    if ~isfield(config.initial_conditions, 'pressure')
        config.initial_conditions.pressure = 2900;  % psi
    end
    if ~isfield(config.initial_conditions, 'temperature')
        config.initial_conditions.temperature = 176;  % °F
    end
    if ~isfield(config.initial_conditions, 'water_saturation')
        config.initial_conditions.water_saturation = 0.2;
    end
    
    % Geomechanics defaults
    if ~isfield(config.geomechanics, 'enabled')
        config.geomechanics.enabled = true;
    end
    if ~isfield(config.geomechanics, 'overburden_gradient')
        config.geomechanics.overburden_gradient = 1.0;  % psi/ft
    end
    if ~isfield(config.geomechanics, 'pore_pressure_gradient')
        config.geomechanics.pore_pressure_gradient = 0.433;  % psi/ft
    end
    
end

function value = parse_value(value_str)
    % Parse string value to appropriate type
    
    % Handle empty values
    if isempty(value_str)
        value = '';
        return;
    end
    
    % Remove quotes if present
    if (length(value_str) >= 2 && value_str(1) == '"' && value_str(end) == '"') || ...
       (length(value_str) >= 2 && value_str(1) == '''' && value_str(end) == '''')
        value = value_str(2:end-1);
        return;
    end
    
    % Handle boolean values
    if strcmpi(value_str, 'true')
        value = true;
        return;
    elseif strcmpi(value_str, 'false')
        value = false;
        return;
    end
    
    % Try to parse as number
    num_value = str2double(value_str);
    if ~isnan(num_value)
        value = num_value;
    else
        % Keep as string
        value = value_str;
    end
end 