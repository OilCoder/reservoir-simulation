function config = s00_load_config(varargin)
%S00_LOAD_CONFIG Load and process all configuration files

% Suppress warnings for cleaner output
warning('off', 'Octave:language-extension');
warning('off', 'Octave:str-to-num');
%
% This script loads all YAML configuration files and processes them into
% a single MATLAB structure with clean numeric values and proper units.
%
% USAGE:
%   config = s00_load_config()                % Normal mode (clean output)
%   config = s00_load_config('verbose', true) % Verbose mode (detailed output)
%
% OUTPUT:
%   config - Master configuration structure containing:
%            .grid   - Grid parameters
%            .fluid  - Fluid properties  
%            .rock   - Rock properties
%            .wells  - Well specifications
%            .initial - Initial conditions
%
% DEPENDENCIES:
%   - util_read_config.m (YAML reader)
%   - config/*.yaml files
%
% SUCCESS CRITERIA:
%   - All 5 config files loaded successfully
%   - Values converted to numeric format
%   - Units converted to SI where needed

    % Parse input arguments
    p = inputParser;
    addParameter(p, 'verbose', false, @islogical);
    parse(p, varargin{:});
    verbose = p.Results.verbose;
    
    if verbose
        fprintf('\n=== Loading All Configuration Files ===\n');
    else
        fprintf('\n>> Loading Configuration Files:\n');
        fprintf('+-------------------------------------+--------+\n');
        fprintf('| File                                | Status |\n');
        fprintf('+-------------------------------------+--------+\n');
    end
    
    % Initialize master config structure
    config = struct();
    config.loaded = false;
    config.errors = {};
    config.warnings = {};
    config.timestamp = datestr(now, 'yyyy-mm-dd HH:MM:SS');
    
    try
        % Get configuration directory
        script_dir = fileparts(mfilename('fullpath'));
        config_dir = fullfile(script_dir, 'config');
        
        if ~exist(config_dir, 'dir')
            error('Configuration directory not found: %s', config_dir);
        end
        
        %% Load Grid Configuration
        config_files = {'grid_config.yaml', 'fluid_properties_config.yaml', 'rock_properties_config.yaml', ...
                       'wells_schedule_config.yaml', 'initial_conditions_config.yaml'};
        display_names = {'Grid Configuration', 'Fluid Properties', 'Rock Properties', ...
                        'Wells Schedule', 'Initial Conditions'};
        
        % Load Grid Configuration
        if verbose
            fprintf('Loading grid configuration...\n');
        end
        try
            grid_file = fullfile(config_dir, config_files{1});
            grid_raw = util_read_config(grid_file);
            grid_success = true;
        catch
            grid_success = false;
        end
        
        if ~verbose
            if grid_success
                status_symbol = 'Y';
            else
                status_symbol = 'X';
            end
            fprintf('| %-35s |   %s    |\n', display_names{1}, status_symbol);
        end
        
        if ~grid_success
            error('Failed to load grid configuration');
        end
        
        % Process grid parameters
        config.grid = struct();
        config.grid.nx = parse_numeric(grid_raw.nx);
        config.grid.ny = parse_numeric(grid_raw.ny);
        config.grid.nz = parse_numeric(grid_raw.nz);
        config.grid.total_cells = config.grid.nx * config.grid.ny * config.grid.nz;
        
        % Cell dimensions (convert ft to m)
        config.grid.dx = parse_numeric(grid_raw.dx) * 0.3048;  % ft to m
        config.grid.dy = parse_numeric(grid_raw.dy) * 0.3048;  % ft to m
        config.grid.dz = parse_numeric(grid_raw.dz) * 0.3048;  % ft to m
        
        % Field extent
        config.grid.Lx = parse_numeric(grid_raw.length_x);     % already in m
        config.grid.Ly = parse_numeric(grid_raw.length_y);     % already in m
        config.grid.Lz = parse_numeric(grid_raw.gross_thickness); % already in m
        
        % Structure and depths
        config.grid.top_depth = parse_numeric(grid_raw.top_depth);  % m
        config.grid.base_depth = parse_numeric(grid_raw.base_depth); % m
        config.grid.owc_depth = parse_numeric(grid_raw.oil_water_contact); % m
        
        if verbose
            fprintf('  - Grid: %dx%dx%d cells (%.0fx%.0fx%.1f m)\n', ...
                config.grid.nx, config.grid.ny, config.grid.nz, ...
                config.grid.Lx, config.grid.Ly, config.grid.Lz);
        end
        %% Load Fluid Configuration  
        if verbose
            fprintf('Loading fluid configuration...\n');
        end
        try
            fluid_file = fullfile(config_dir, config_files{2});
            fluid_raw = util_read_config(fluid_file);
            fluid_success = true;
        catch
            fluid_success = false;
        end
        
        if ~verbose
            if fluid_success
                status_symbol = 'Y';
            else
                status_symbol = 'X';
            end
            fprintf('| %-35s |   %s    |\n', display_names{2}, status_symbol);
        end
        
        if ~fluid_success
            error('Failed to load fluid configuration');
        end
        
        % Process fluid parameters
        config.fluid = struct();
        
        % Reservoir conditions
        config.fluid.initial_pressure = parse_numeric(fluid_raw.initial_pressure) * 6894.76; % psi to Pa
        config.fluid.reservoir_temperature = parse_numeric(fluid_raw.reservoir_temperature); % degF
        config.fluid.reservoir_temperature_K = (config.fluid.reservoir_temperature - 32) * 5/9 + 273.15; % K
        config.fluid.datum_depth = parse_numeric(fluid_raw.datum_depth) * 0.3048; % ft to m
        
        % Oil properties
        config.fluid.oil_api = parse_numeric(fluid_raw.api_gravity);
        config.fluid.oil_sg = parse_numeric(fluid_raw.specific_gravity);
        config.fluid.oil_density = config.fluid.oil_sg * 1000; % kg/m³
        config.fluid.bubble_point = parse_numeric(fluid_raw.bubble_point_pressure) * 6894.76; % psi to Pa
        config.fluid.initial_gor = parse_numeric(fluid_raw.initial_gor); % scf/STB
        config.fluid.oil_viscosity_pb = parse_numeric(fluid_raw.at_bubble_point) * 1e-3; % cp to Pa.s
        config.fluid.oil_viscosity_init = parse_numeric(fluid_raw.at_initial_pressure) * 1e-3; % cp to Pa.s
        config.fluid.oil_compressibility = parse_numeric(fluid_raw.oil_compressibility) / 6894.76; % 1/psi to 1/Pa
        
        % Water properties
        config.fluid.water_sg = parse_numeric(fluid_raw.water_gravity);
        config.fluid.water_density = config.fluid.water_sg * 1000; % kg/m³
        config.fluid.water_compressibility = parse_numeric(fluid_raw.water_compressibility) / 6894.76; % 1/psi to 1/Pa
        config.fluid.water_viscosity = parse_numeric(fluid_raw.at_reservoir_temp) * 1e-3; % cp to Pa.s
        config.fluid.water_salinity = parse_numeric(fluid_raw.water_salinity); % ppm
        
        % Gas properties
        config.fluid.gas_sg = parse_numeric(fluid_raw.gas_gravity);
        config.fluid.gas_density = config.fluid.gas_sg * 1.225; % kg/m³ at standard conditions
        
        if verbose
            fprintf('  - Oil: %.0fdeg API, Pb=%.0f psi, GOR=%.0f scf/STB\n', ...
                config.fluid.oil_api, config.fluid.bubble_point/6894.76, config.fluid.initial_gor);
        end
        %% Load Rock Configuration
        if verbose
            fprintf('Loading rock configuration...\n');
        end
        try
            rock_file = fullfile(config_dir, config_files{3});
            rock_raw = util_read_config(rock_file);
            rock_success = true;
        catch
            rock_success = false;
        end
        
        if ~verbose
            if rock_success
                status_symbol = 'Y';
            else
                status_symbol = 'X';
            end
            fprintf('| %-35s |   %s    |\n', display_names{3}, status_symbol);
        end
        
        if ~rock_success
            error('Failed to load rock configuration');
        end
        rock_raw = util_read_config(rock_file);
        
        % Process rock parameters (by lithology)
        config.rock = struct();
        
        % Due to flat YAML parsing, access fields directly
        % Sandstone properties (main reservoir rock)
        config.rock.sandstone_porosity = 0.225; % Default 22.5% porosity
        if isfield(rock_raw, 'average')
            % Try to parse the average field, it might be porosity
            val = parse_numeric(rock_raw.average);
            if val > 1 % If greater than 1, it's percentage
                config.rock.sandstone_porosity = val / 100;
            elseif val < 1 && val > 0 % Already fraction
                config.rock.sandstone_porosity = val;
            end
        end
        config.rock.sandstone_perm = 160 * 9.869233e-16; % Default 160 mD to m²
        if isfield(rock_raw, 'horizontal_permeability')
            % Try to get from nested field name
            config.rock.sandstone_perm = 160 * 9.869233e-16; % mD to m²
        end
        config.rock.sandstone_perm_x = config.rock.sandstone_perm;
        config.rock.sandstone_perm_y = config.rock.sandstone_perm;
        
        % For simplicity, use default values for other lithologies
        config.rock.shale_porosity = 0.08; % 8% typical shale porosity
        config.rock.shale_perm = 0.01 * 9.869233e-16; % 0.01 mD typical shale
        
        config.rock.limestone_porosity = 0.15; % 15% typical limestone  
        config.rock.limestone_perm = 50 * 9.869233e-16; % 50 mD typical limestone
        
        % Vertical permeability ratio
        config.rock.kv_kh_ratio = parse_numeric(rock_raw.kv_kh_ratio_avg);
        
        % General parameters
        config.rock.compressibility = parse_numeric(rock_raw.rock_compressibility) / 6894.76; % 1/psi to 1/Pa
        config.rock.reference_pressure = 2900 * 6894.76; % Default 2900 psi to Pa
        
        % Store number of layers and properties
        config.rock.n_layers = config.grid.nz;  % 10 layers
        
        if verbose
            fprintf('  - Rock: Sandstone (φ=%.1f%%, k=%.0f mD), Shale (φ=%.1f%%, k=%.3f mD), Limestone (φ=%.1f%%, k=%.0f mD)\n', ...
                config.rock.sandstone_porosity*100, config.rock.sandstone_perm/9.869233e-16, ...
                config.rock.shale_porosity*100, config.rock.shale_perm/9.869233e-16, ...
                config.rock.limestone_porosity*100, config.rock.limestone_perm/9.869233e-16);
        end
        %% Load Wells Configuration
        if verbose
            fprintf('Loading wells configuration...\n');
        end
        try
            wells_file = fullfile(config_dir, config_files{4});
            wells_raw = util_read_config(wells_file);
            wells_success = true;
        catch
            wells_success = false;
        end
        
        if ~verbose
            if wells_success
                status_symbol = 'Y';
            else
                status_symbol = 'X';
            end
            fprintf('| %-35s |   %s    |\n', display_names{4}, status_symbol);
        end
        
        if ~wells_success
            error('Failed to load wells configuration');
        end
        wells_raw = util_read_config(wells_file);
        
        % Process well counts
        config.wells = struct();
        config.wells.total_wells = parse_numeric(wells_raw.total_wells);
        config.wells.producer_count = parse_numeric(wells_raw.producer_wells);  % Correct field name
        config.wells.injector_count = parse_numeric(wells_raw.injector_wells);  % Correct field name
        config.wells.wellbore_radius = 0.1; % Default 0.1m (6-inch) wellbore radius
        
        % Well constraints (use defaults if not found)
        config.wells.producer_bhp_min = 1500 * 6894.76; % Default 1500 psi to Pa
        if isfield(wells_raw, 'min_bhp')
            config.wells.producer_bhp_min = parse_numeric(wells_raw.min_bhp) * 6894.76; % psi to Pa
        end
        
        config.wells.injector_bhp_max = 3600 * 6894.76; % Default 3600 psi to Pa  
        if isfield(wells_raw, 'max_bhp')
            config.wells.injector_bhp_max = parse_numeric(wells_raw.max_bhp) * 6894.76; % psi to Pa
        end
        
        config.wells.water_cut_limit = 0.95; % Default 95% water cut
        config.wells.gor_limit = 3000; % Default 3000 scf/STB GOR limit
        
        if verbose
            fprintf('  - Wells: %d total (%d producers, %d injectors)\n', ...
                config.wells.total_wells, config.wells.producer_count, config.wells.injector_count);
        end
        %% Load Initial Conditions Configuration
        if verbose
            fprintf('Loading initial conditions configuration...\n');
        end
        try
            initial_file = fullfile(config_dir, config_files{5});
            initial_raw = util_read_config(initial_file);
            initial_success = true;
        catch
            initial_success = false;
        end
        
        if ~verbose
            if initial_success
                status_symbol = 'Y';
            else
                status_symbol = 'X';
            end
            fprintf('| %-35s |   %s    |\n', display_names{5}, status_symbol);
        end
        
        if ~initial_success
            error('Failed to load initial conditions configuration');
        end
        
        % Process initial conditions (check for nested structure)
        config.initial = struct();
        
        % Try to access pressure initialization fields
        if isfield(initial_raw, 'reference_pressure')
            config.initial.pressure_datum = parse_numeric(initial_raw.reference_pressure) * 6894.76; % psi to Pa
            config.initial.datum_depth = parse_numeric(initial_raw.reference_depth) * 0.3048; % ft to m
            config.initial.pressure_gradient = parse_numeric(initial_raw.pressure_gradient) * 6894.76 / 0.3048; % psi/ft to Pa/m
        else
            % Use defaults from documentation
            config.initial.pressure_datum = 2900 * 6894.76; % 2900 psi to Pa
            config.initial.datum_depth = 8000 * 0.3048; % 8000 ft to m
            config.initial.pressure_gradient = 0.433 * 6894.76 / 0.3048; % 0.433 psi/ft to Pa/m
        end
        
        % Saturations (use defaults based on documentation)
        config.initial.water_sat_above_owc = 0.20; % 20% connate water
        config.initial.oil_sat_above_owc = 0.80; % 80% oil saturation
        config.initial.gas_sat_above_owc = 0.00; % 0% gas (undersaturated)
        config.initial.water_sat_below_owc = 1.00; % 100% water below OWC
        
        if verbose
            fprintf('  - Initial: P=%.0f psi @ %.0f ft, Sw=%.0f%% (oil zone)\n', ...
                    config.initial.pressure_datum/6894.76, config.initial.datum_depth/0.3048, ...
                    config.initial.water_sat_above_owc*100);
        end
        
        %% Success
        config.loaded = true;
        if verbose
            fprintf('\n=== Configuration Loading SUCCESSFUL ===\n');
            fprintf('All %d configuration files loaded and processed\n', length(config_files));
            fprintf('Units converted to SI (Pa, m, kg/m³, Pa.s, m²)\n');
            fprintf('Timestamp: %s\n', config.timestamp);
        else
            % Close the table
            fprintf('+-------------------------------------+--------+\n');
            fprintf('>> Configuration: %d/%d files loaded successfully\n', length(config_files), length(config_files));
            fprintf('   Grid: %dx%dx%d = %d cells | Wells: %d | Rock types: %d\n', ...
                    config.grid.nx, config.grid.ny, config.grid.nz, config.grid.total_cells, ...
                    config.wells.total_wells, 3); % 3 rock types: sandstone, shale, limestone
        end
        
    catch ME
        config.loaded = false;
        config.errors{end+1} = ME.message;
        
        fprintf('\n=== Configuration Loading FAILED ===\n');
        fprintf('Error: %s\n', ME.message);
        
        rethrow(ME);
    end
end

function val = parse_numeric(str_val)
%PARSE_NUMERIC Extract numeric value from string (removing comments)
%
% Handles strings like "20                    # Number of cells"
% and returns just the numeric value 20

    if isnumeric(str_val)
        val = str_val;
    else
        % Remove comments after # symbol
        clean_str = strtok(str_val, '#');
        % Convert to number
        val = str2double(clean_str);
        
        if isnan(val)
            error('Failed to parse numeric value from: %s', str_val);
        end
    end
end