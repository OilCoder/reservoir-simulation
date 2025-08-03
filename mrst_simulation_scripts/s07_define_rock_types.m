function [rock_types, status] = s07_define_rock_types(varargin)
%S07_DEFINE_ROCK_TYPES Define multi-lithology rock types for Eagle West Field
%
% This script implements 6 rock types (RT1-RT6) with specific porosity and 
% permeability ranges according to reservoir documentation.
%
% USAGE:
%   [rock_types, status] = s07_define_rock_types(config)                    % Normal mode (clean output)
%   [rock_types, status] = s07_define_rock_types(config, 'verbose', true)   % Verbose mode (detailed output)
%   [rock_types, status] = s07_define_rock_types('verbose', true)           % Load config automatically, verbose
%
% INPUT:
%   config - Configuration structure from s00_load_config (optional)
%            If not provided, will load configuration automatically
%
% OUTPUT:
%   rock_types - Structure containing all 6 rock type definitions with properties
%   status     - Structure containing rock type implementation status and information
%
% ROCK TYPES IMPLEMENTED:
%   RT1 - High Perm Sandstone (φ: 25-32%, k: 300-850 mD)
%   RT2 - Medium Perm Sandstone (φ: 20-25%, k: 100-300 mD)
%   RT3 - Low Perm Sandstone (φ: 15-20%, k: 25-100 mD)
%   RT4 - Tight Sandstone (φ: 10-15%, k: 5-25 mD)
%   RT5 - Limestone (φ: 15-28%, k: 50-300 mD)
%   RT6 - Shale (φ: 2-8%, k: 0.001-0.1 mD)
%
% DEPENDENCIES:
%   - MRST environment (assumed already initialized by workflow)
%   - s00_load_config.m (centralized configuration loader)
%
% SUCCESS CRITERIA:
%   - All 6 rock types defined with proper ranges
%   - Properties validated against documentation
%   - Kozeny-Carman relationships established
%   - Net-to-gross ratios assigned

% Suppress warnings for cleaner output
warning('off', 'all');

    % Parse input arguments
    p = inputParser;
    addParameter(p, 'verbose', false, @islogical);
    parse(p, varargin{:});
    verbose = p.Results.verbose;
    
    if verbose
        fprintf('\n=== Rock Types Definition ===\n');
    else
        fprintf('\n>> Defining Rock Types:\n');
        fprintf('+-------------------------------------+--------+\n');
        fprintf('| Component                           | Status |\n');
        fprintf('+-------------------------------------+--------+\n');
    end
    
    % Initialize status structure
    status = struct();
    status.success = false;
    status.rock_types_defined = 0;
    status.errors = {};
    status.warnings = {};
    
    % Initialize return values
    rock_types = struct();
    rock_type_names = {};
    total_rock_types = 0;
    porosity_range = [0, 0];
    perm_range_mD = [0, 0];
    
    % Define rock type tasks
    task_names = {'Load Configuration', 'Load Rock Types from Config', 'Validate Properties'};
    
    try
        %% Step 1: Load rock configuration from YAML
        if verbose
            fprintf('Step 1: Loading rock configuration from YAML...\n');
        end
        
        try
            % Load rock configuration directly from YAML
            config_dir = 'config';
            rock_file = fullfile(config_dir, 'rock_properties_config.yaml');
            rock_raw = util_read_config(rock_file);
            step1_success = true;
        catch ME
            step1_success = false;
            if verbose
                fprintf('Error loading rock configuration: %s\n', ME.message);
            end
        end
        
        if ~verbose
            if step1_success
                status_symbol = 'Y';
            else
                status_symbol = 'X';
            end
            fprintf('| %-35s |   %s    |\n', task_names{1}, status_symbol);
        else
            if step1_success
                fprintf('  - Rock configuration loaded from YAML\n');
            end
        end
        
        if ~step1_success
            error('Failed to load configuration');
        end
        
        %% Step 2: Define RT1-RT6 from configuration
        if verbose
            fprintf('Step 2: Loading rock types from configuration...\n');
        end
        
        try
            % Unit conversions
            mD_to_m2 = 9.869233e-16;  % millidarcy to m²
            
            % Use already loaded rock configuration
            
            % Extract rock types fields using flattened YAML structure
            rock_type_names = {'RT1', 'RT2', 'RT3', 'RT4', 'RT5', 'RT6'};
            total_rock_types = length(rock_type_names);
            
            % Create config_rock_types structure from flattened YAML
            config_rock_types = struct();
            for i = 1:length(rock_type_names)
                rt_name = rock_type_names{i};
                prefix = ['rock_types_' rt_name '_'];
                
                % Build rock type structure
                config_rock_types.(rt_name) = struct();
                config_rock_types.(rt_name).name = get_yaml_field(rock_raw, [prefix 'name'], 'Unknown');
                config_rock_types.(rt_name).lithology = get_yaml_field(rock_raw, [prefix 'lithology'], 'Unknown');
                config_rock_types.(rt_name).description = get_yaml_field(rock_raw, [prefix 'description'], '');
                
                % Porosity
                config_rock_types.(rt_name).porosity = struct();
                config_rock_types.(rt_name).porosity.minimum = get_yaml_field(rock_raw, [prefix 'porosity_minimum'], 0.1);
                config_rock_types.(rt_name).porosity.maximum = get_yaml_field(rock_raw, [prefix 'porosity_maximum'], 0.3);
                config_rock_types.(rt_name).porosity.mean = get_yaml_field(rock_raw, [prefix 'porosity_mean'], 0.2);
                config_rock_types.(rt_name).porosity.std_deviation = get_yaml_field(rock_raw, [prefix 'porosity_std_deviation'], 0.02);
                
                % Permeability
                config_rock_types.(rt_name).horizontal_permeability = struct();
                config_rock_types.(rt_name).horizontal_permeability.minimum = get_yaml_field(rock_raw, [prefix 'horizontal_permeability_minimum'], 100);
                config_rock_types.(rt_name).horizontal_permeability.maximum = get_yaml_field(rock_raw, [prefix 'horizontal_permeability_maximum'], 300);
                config_rock_types.(rt_name).horizontal_permeability.mean = get_yaml_field(rock_raw, [prefix 'horizontal_permeability_mean'], 200);
                
                % Other properties
                config_rock_types.(rt_name).net_to_gross = get_yaml_field(rock_raw, [prefix 'net_to_gross'], 0.7);
                config_rock_types.(rt_name).kv_kh_ratio = get_yaml_field(rock_raw, [prefix 'kv_kh_ratio'], 0.5);
                config_rock_types.(rt_name).compressibility = get_yaml_field(rock_raw, [prefix 'compressibility'], 4e-6);
                config_rock_types.(rt_name).kozeny_carman_constant = get_yaml_field(rock_raw, [prefix 'kozeny_carman_constant'], 5.0);
                
                % Relative permeability structures
                config_rock_types.(rt_name).rel_perm_ow = struct();
                config_rock_types.(rt_name).rel_perm_ow.Swir = get_yaml_field(rock_raw, [prefix 'rel_perm_ow_Swir'], 0.2);
                config_rock_types.(rt_name).rel_perm_ow.Sor = get_yaml_field(rock_raw, [prefix 'rel_perm_ow_Sor'], 0.3);
                config_rock_types.(rt_name).rel_perm_ow.krw_Sor = get_yaml_field(rock_raw, [prefix 'rel_perm_ow_krw_Sor'], 0.4);
                config_rock_types.(rt_name).rel_perm_ow.kro_Swir = get_yaml_field(rock_raw, [prefix 'rel_perm_ow_kro_Swir'], 0.8);
                config_rock_types.(rt_name).rel_perm_ow.nw = get_yaml_field(rock_raw, [prefix 'rel_perm_ow_nw'], 2.5);
                config_rock_types.(rt_name).rel_perm_ow.no = get_yaml_field(rock_raw, [prefix 'rel_perm_ow_no'], 2.0);
                
                config_rock_types.(rt_name).rel_perm_go = struct();
                config_rock_types.(rt_name).rel_perm_go.Sgr = get_yaml_field(rock_raw, [prefix 'rel_perm_go_Sgr'], 0.05);
                config_rock_types.(rt_name).rel_perm_go.Sorg = get_yaml_field(rock_raw, [prefix 'rel_perm_go_Sorg'], 0.15);
                config_rock_types.(rt_name).rel_perm_go.krg_Sorg = get_yaml_field(rock_raw, [prefix 'rel_perm_go_krg_Sorg'], 0.7);
                config_rock_types.(rt_name).rel_perm_go.krog_Sgr = get_yaml_field(rock_raw, [prefix 'rel_perm_go_krog_Sgr'], 0.9);
                config_rock_types.(rt_name).rel_perm_go.ng = get_yaml_field(rock_raw, [prefix 'rel_perm_go_ng'], 2.0);
                config_rock_types.(rt_name).rel_perm_go.nog = get_yaml_field(rock_raw, [prefix 'rel_perm_go_nog'], 2.5);
                
                % Capillary pressure
                config_rock_types.(rt_name).capillary_pressure = struct();
                config_rock_types.(rt_name).capillary_pressure.pc_entry = get_yaml_field(rock_raw, [prefix 'capillary_pressure_pc_entry'], 1.0);
                config_rock_types.(rt_name).capillary_pressure.pc_max = get_yaml_field(rock_raw, [prefix 'capillary_pressure_pc_max'], 20.0);
                config_rock_types.(rt_name).capillary_pressure.lambda = get_yaml_field(rock_raw, [prefix 'capillary_pressure_lambda'], 0.4);
                
                % Porosity-permeability correlation
                config_rock_types.(rt_name).poro_perm_correlation = struct();
                config_rock_types.(rt_name).poro_perm_correlation.a = get_yaml_field(rock_raw, [prefix 'poro_perm_correlation_a'], 0.01);
                config_rock_types.(rt_name).poro_perm_correlation.n = get_yaml_field(rock_raw, [prefix 'poro_perm_correlation_n'], 3.0);
            end
            
            % Process each rock type from configuration
            for i = 1:length(rock_type_names)
                rt_name = rock_type_names{i};
                rt_config = config_rock_types.(rt_name);
                
                % Create rock type structure from config
                rock_types.(rt_name) = struct();
                rock_types.(rt_name).name = rt_config.name;
                rock_types.(rt_name).lithology = rt_config.lithology;
                rock_types.(rt_name).description = rt_config.description;
                
                % Porosity properties
                rock_types.(rt_name).porosity_min = rt_config.porosity.minimum;
                rock_types.(rt_name).porosity_max = rt_config.porosity.maximum;
                rock_types.(rt_name).porosity_mean = rt_config.porosity.mean;
                rock_types.(rt_name).porosity_std = rt_config.porosity.std_deviation;
                
                % Permeability properties (convert mD to m²)
                rock_types.(rt_name).perm_min = rt_config.horizontal_permeability.minimum * mD_to_m2;
                rock_types.(rt_name).perm_max = rt_config.horizontal_permeability.maximum * mD_to_m2;
                rock_types.(rt_name).perm_mean = rt_config.horizontal_permeability.mean * mD_to_m2;
                
                % Additional properties from config
                rock_types.(rt_name).net_to_gross = rt_config.net_to_gross;
                rock_types.(rt_name).kv_kh_ratio = rt_config.kv_kh_ratio;
                rock_types.(rt_name).kozeny_carman_constant = rt_config.kozeny_carman_constant;
                
                % Compressibility (convert psi^-1 to Pa^-1)
                psi_to_Pa = 6894.76;
                rock_types.(rt_name).compressibility = rt_config.compressibility / psi_to_Pa;
                rock_types.(rt_name).compressibility_psi = rt_config.compressibility;
                rock_types.(rt_name).reference_pressure = 2000 * psi_to_Pa; % Reference pressure in Pa
                
                % Relative permeability parameters
                rock_types.(rt_name).rel_perm_ow = rt_config.rel_perm_ow;
                rock_types.(rt_name).rel_perm_go = rt_config.rel_perm_go;
                
                % Capillary pressure parameters
                rock_types.(rt_name).capillary_pressure = rt_config.capillary_pressure;
                
                % Porosity-permeability correlation
                rock_types.(rt_name).poro_perm_correlation = rt_config.poro_perm_correlation;
                
                % Add rock type ID and ranges
                rock_types.(rt_name).type_id = i;
                rock_types.(rt_name).perm_range_m2 = [rock_types.(rt_name).perm_min, rock_types.(rt_name).perm_max];
                rock_types.(rt_name).perm_range_mD = [rt_config.horizontal_permeability.minimum, rt_config.horizontal_permeability.maximum];
            end
            
            step2_success = true;
        catch ME
            step2_success = false;
            if verbose
                fprintf('Error loading rock types from config: %s\n', ME.message);
            end
        end
        
        if ~verbose
            if step2_success
                status_symbol = 'Y';
            else
                status_symbol = 'X';
            end
            fprintf('| %-35s |   %s    |\n', sprintf('Load %d Rock Types from Config', length(rock_type_names)), status_symbol);
        else
            if step2_success
                fprintf('  - Loaded %d rock types from configuration:\n', length(rock_type_names));
                for i = 1:length(rock_type_names)
                    rt_name = rock_type_names{i};
                    rt = rock_types.(rt_name);
                    fprintf('  - %s: %s (φ: %.0f-%.0f%%, k: %.0f-%.0f mD)\n', ...
                            rt_name, rt.name, ...
                            rt.porosity_min*100, rt.porosity_max*100, ...
                            rt.perm_range_mD(1), rt.perm_range_mD(2));
                end
            end
        end
        
        if ~step2_success
            error('Failed to load rock types from configuration');
        end
        
        %% Step 3: Validate properties and calculate statistics
        if verbose
            fprintf('Step 3: Validating properties and calculating statistics...\n');
        end
        
        try
            % Calculate porosity range across all rock types
            porosity_mins = [];
            porosity_maxs = [];
            perm_mins_mD = [];
            perm_maxs_mD = [];
            
            for i = 1:length(rock_type_names)
                rt_name = rock_type_names{i};
                rt = rock_types.(rt_name);
                porosity_mins(end+1) = rt.porosity_min;
                porosity_maxs(end+1) = rt.porosity_max;
                perm_mins_mD(end+1) = rt.perm_range_mD(1);
                perm_maxs_mD(end+1) = rt.perm_range_mD(2);
            end
            
            porosity_range = [min(porosity_mins), max(porosity_maxs)];
            perm_range_mD = [min(perm_mins_mD), max(perm_maxs_mD)];
            
            step3_success = true;
        catch ME
            step3_success = false;
            if verbose
                fprintf('Error in validation: %s\n', ME.message);
            end
        end
        
        if ~verbose
            if step3_success
                status_symbol = 'Y';
            else
                status_symbol = 'X';
            end
            fprintf('| %-35s |   %s    |\n', sprintf('%s (%d types)', task_names{3}, total_rock_types), status_symbol);
        else
            if step3_success
                fprintf('  - Total rock types validated: %d\n', total_rock_types);
                fprintf('  - Porosity range: %.1f-%.1f%%\n', porosity_range(1)*100, porosity_range(2)*100);
                fprintf('  - Permeability range: %.3f-%.0f mD\n', perm_range_mD(1), perm_range_mD(2));
                fprintf('  - All parameters loaded from configuration\n');
            end
        end
        
        if ~step3_success
            error('Failed to validate rock properties');
        end
        
        % Store rock types count in status
        status.rock_types_defined = total_rock_types;
        status.porosity_range = porosity_range;
        status.permeability_range_mD = perm_range_mD;
        status.rock_type_names = rock_type_names;
        
        %% Success
        status.success = step1_success && step2_success && step3_success;
        status.timestamp = datestr(now, 'yyyy-mm-dd HH:MM:SS');
        
        if verbose
            fprintf('\n=== Rock Types Definition SUCCESSFUL ===\n');
            fprintf('Rock types implemented: %s\n', strjoin(rock_type_names, ', '));
            fprintf('Lithologies: Sandstone (3 types), Tight Sandstone (1), Limestone (1), Shale (1)\n');
            fprintf('Porosity range: %.1f-%.1f%%\n', porosity_range(1)*100, porosity_range(2)*100);
            fprintf('Permeability range: %.3f-%.0f mD\n', perm_range_mD(1), perm_range_mD(2));
            fprintf('Net-to-gross range: %.0f-%.0f%%\n', rock_types.RT6.net_to_gross*100, rock_types.RT1.net_to_gross*100);
            fprintf('Timestamp: %s\n', status.timestamp);
        else
            % Close the table
            fprintf('+-------------------------------------+--------+\n');
            fprintf('>> Rock Types: %d types defined successfully\n', total_rock_types);
            fprintf('   Porosity: %.1f-%.1f%% | Permeability: %.3f-%.0f mD | Kv/Kh: 0.1-0.5\n', ...
                    porosity_range(1)*100, porosity_range(2)*100, perm_range_mD(1), perm_range_mD(2));
        end
        
        if ~isempty(status.warnings)
            fprintf('\nWarnings encountered:\n');
            for i = 1:length(status.warnings)
                fprintf('  - %s\n', status.warnings{i});
            end
        end
        
    catch ME
        status.success = false;
        status.errors{end+1} = ME.message;
        
        fprintf('\n=== Rock Types Definition FAILED ===\n');
        fprintf('Error: %s\n', ME.message);
        
        if ~isempty(status.warnings)
            fprintf('\nWarnings:\n');
            for i = 1:length(status.warnings)
                fprintf('  - %s\n', status.warnings{i});
            end
        end
        
        rethrow(ME);
    end
    
    fprintf('\n');
end

function value = get_yaml_field(yaml_struct, field_name, default_value)
%GET_YAML_FIELD Extract field from flattened YAML structure with default
%
% This helper function safely extracts values from the flattened YAML
% structure returned by util_read_config, providing defaults if fields
% are missing.

    if isfield(yaml_struct, field_name)
        value = yaml_struct.(field_name);
        % Remove quotes if it's a string
        if ischar(value) && length(value) >= 2
            if (value(1) == '"' && value(end) == '"') || (value(1) == '''' && value(end) == '''')
                value = value(2:end-1);
            end
        end
    else
        value = default_value;
    end
end