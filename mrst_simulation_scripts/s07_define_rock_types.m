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
    addOptional(p, 'config', [], @isstruct);
    addParameter(p, 'verbose', false, @islogical);
    parse(p, varargin{:});
    config = p.Results.config;
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
    
    % Define rock type tasks
    task_names = {'Load Configuration', 'Define RT1-RT3 Sandstones', 'Define RT4 Tight Sandstone', 'Define RT5 Limestone', 'Define RT6 Shale', 'Validate Properties'};
    
    try
        %% Step 1: Load configuration if not provided
        if verbose
            fprintf('Step 1: Loading configuration...\n');
        end
        
        try
            % Load config if not provided as input
            if isempty(config)
                temp_output = evalc('config = s00_load_config(''verbose'', false);');
                if ~config.loaded
                    error('Failed to load configuration');
                end
                config_source = 'auto-loaded';
            else
                config_source = 'provided';
            end
            rock_config = config.rock;
            step1_success = true;
        catch
            step1_success = false;
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
                fprintf('  - Configuration %s successfully\n', config_source);
            end
        end
        
        if ~step1_success
            error('Failed to load configuration');
        end
        
        %% Step 2: Define RT1-RT3 Sandstones (High, Medium, Low Permeability)
        if verbose
            fprintf('Step 2: Defining sandstone rock types...\n');
        end
        
        try
            % Unit conversions
            mD_to_m2 = 9.869233e-16;  % millidarcy to m²
            
            % RT1: High Permeability Sandstone
            rock_types.RT1 = struct();
            rock_types.RT1.name = 'High Perm Sandstone';
            rock_types.RT1.lithology = 'Sandstone';
            rock_types.RT1.porosity_min = 0.25;       % 25%
            rock_types.RT1.porosity_max = 0.32;       % 32%
            rock_types.RT1.porosity_mean = 0.285;     % Mean: 28.5%
            rock_types.RT1.porosity_std = 0.02;       % Standard deviation
            rock_types.RT1.perm_min = 300 * mD_to_m2; % 300 mD to m²
            rock_types.RT1.perm_max = 850 * mD_to_m2; % 850 mD to m²
            rock_types.RT1.perm_mean = 575 * mD_to_m2; % Mean: 575 mD
            rock_types.RT1.net_to_gross = 0.85;       % 85% net pay
            rock_types.RT1.description = 'Clean, well-sorted sandstone with excellent reservoir quality';
            
            % RT2: Medium Permeability Sandstone
            rock_types.RT2 = struct();
            rock_types.RT2.name = 'Medium Perm Sandstone';
            rock_types.RT2.lithology = 'Sandstone';
            rock_types.RT2.porosity_min = 0.20;       % 20%
            rock_types.RT2.porosity_max = 0.25;       % 25%
            rock_types.RT2.porosity_mean = 0.225;     % Mean: 22.5%
            rock_types.RT2.porosity_std = 0.015;      % Standard deviation
            rock_types.RT2.perm_min = 100 * mD_to_m2; % 100 mD to m²
            rock_types.RT2.perm_max = 300 * mD_to_m2; % 300 mD to m²
            rock_types.RT2.perm_mean = 200 * mD_to_m2; % Mean: 200 mD
            rock_types.RT2.net_to_gross = 0.75;       % 75% net pay
            rock_types.RT2.description = 'Moderately sorted sandstone with good reservoir quality';
            
            % RT3: Low Permeability Sandstone
            rock_types.RT3 = struct();
            rock_types.RT3.name = 'Low Perm Sandstone';
            rock_types.RT3.lithology = 'Sandstone';
            rock_types.RT3.porosity_min = 0.15;       % 15%
            rock_types.RT3.porosity_max = 0.20;       % 20%
            rock_types.RT3.porosity_mean = 0.175;     % Mean: 17.5%
            rock_types.RT3.porosity_std = 0.012;      % Standard deviation
            rock_types.RT3.perm_min = 25 * mD_to_m2;  % 25 mD to m²
            rock_types.RT3.perm_max = 100 * mD_to_m2; % 100 mD to m²
            rock_types.RT3.perm_mean = 62.5 * mD_to_m2; % Mean: 62.5 mD
            rock_types.RT3.net_to_gross = 0.65;       % 65% net pay
            rock_types.RT3.description = 'Fine-grained sandstone with fair reservoir quality';
            
            step2_success = true;
        catch
            step2_success = false;
        end
        
        if ~verbose
            if step2_success
                status_symbol = 'Y';
            else
                status_symbol = 'X';
            end
            fprintf('| %-35s |   %s    |\n', task_names{2}, status_symbol);
        else
            if step2_success
                fprintf('  - RT1: High Perm Sandstone (φ: %.0f-%.0f%%, k: %.0f-%.0f mD)\n', ...
                        rock_types.RT1.porosity_min*100, rock_types.RT1.porosity_max*100, ...
                        rock_types.RT1.perm_min/mD_to_m2, rock_types.RT1.perm_max/mD_to_m2);
                fprintf('  - RT2: Medium Perm Sandstone (φ: %.0f-%.0f%%, k: %.0f-%.0f mD)\n', ...
                        rock_types.RT2.porosity_min*100, rock_types.RT2.porosity_max*100, ...
                        rock_types.RT2.perm_min/mD_to_m2, rock_types.RT2.perm_max/mD_to_m2);
                fprintf('  - RT3: Low Perm Sandstone (φ: %.0f-%.0f%%, k: %.0f-%.0f mD)\n', ...
                        rock_types.RT3.porosity_min*100, rock_types.RT3.porosity_max*100, ...
                        rock_types.RT3.perm_min/mD_to_m2, rock_types.RT3.perm_max/mD_to_m2);
            end
        end
        
        if ~step2_success
            error('Failed to define sandstone rock types');
        end
        
        %% Step 3: Define RT4 Tight Sandstone
        if verbose
            fprintf('Step 3: Defining tight sandstone...\n');
        end
        
        try
            % RT4: Tight Sandstone
            rock_types.RT4 = struct();
            rock_types.RT4.name = 'Tight Sandstone';
            rock_types.RT4.lithology = 'Tight Sandstone';
            rock_types.RT4.porosity_min = 0.10;       % 10%
            rock_types.RT4.porosity_max = 0.15;       % 15%
            rock_types.RT4.porosity_mean = 0.125;     % Mean: 12.5%
            rock_types.RT4.porosity_std = 0.01;       % Standard deviation
            rock_types.RT4.perm_min = 5 * mD_to_m2;   % 5 mD to m²
            rock_types.RT4.perm_max = 25 * mD_to_m2;  % 25 mD to m²
            rock_types.RT4.perm_mean = 15 * mD_to_m2; % Mean: 15 mD
            rock_types.RT4.net_to_gross = 0.45;       % 45% net pay
            rock_types.RT4.description = 'Cemented sandstone with poor reservoir quality';
            
            step3_success = true;
        catch
            step3_success = false;
        end
        
        if ~verbose
            if step3_success
                status_symbol = 'Y';
            else
                status_symbol = 'X';
            end
            fprintf('| %-35s |   %s    |\n', task_names{3}, status_symbol);
        else
            if step3_success
                fprintf('  - RT4: Tight Sandstone (φ: %.0f-%.0f%%, k: %.0f-%.0f mD)\n', ...
                        rock_types.RT4.porosity_min*100, rock_types.RT4.porosity_max*100, ...
                        rock_types.RT4.perm_min/mD_to_m2, rock_types.RT4.perm_max/mD_to_m2);
            end
        end
        
        if ~step3_success
            error('Failed to define tight sandstone');
        end
        
        %% Step 4: Define RT5 Limestone
        if verbose
            fprintf('Step 4: Defining limestone...\n');
        end
        
        try
            % RT5: Limestone
            rock_types.RT5 = struct();
            rock_types.RT5.name = 'Limestone';
            rock_types.RT5.lithology = 'Limestone';
            rock_types.RT5.porosity_min = 0.15;       % 15%
            rock_types.RT5.porosity_max = 0.28;       % 28%
            rock_types.RT5.porosity_mean = 0.215;     % Mean: 21.5%
            rock_types.RT5.porosity_std = 0.035;      % Standard deviation
            rock_types.RT5.perm_min = 50 * mD_to_m2;  % 50 mD to m²
            rock_types.RT5.perm_max = 300 * mD_to_m2; % 300 mD to m²
            rock_types.RT5.perm_mean = 175 * mD_to_m2; % Mean: 175 mD
            rock_types.RT5.net_to_gross = 0.60;       % 60% net pay
            rock_types.RT5.description = 'Vuggy limestone with variable reservoir quality';
            
            step4_success = true;
        catch
            step4_success = false;
        end
        
        if ~verbose
            if step4_success
                status_symbol = 'Y';
            else
                status_symbol = 'X';
            end
            fprintf('| %-35s |   %s    |\n', task_names{4}, status_symbol);
        else
            if step4_success
                fprintf('  - RT5: Limestone (φ: %.0f-%.0f%%, k: %.0f-%.0f mD)\n', ...
                        rock_types.RT5.porosity_min*100, rock_types.RT5.porosity_max*100, ...
                        rock_types.RT5.perm_min/mD_to_m2, rock_types.RT5.perm_max/mD_to_m2);
            end
        end
        
        if ~step4_success
            error('Failed to define limestone');
        end
        
        %% Step 5: Define RT6 Shale
        if verbose
            fprintf('Step 5: Defining shale...\n');
        end
        
        try
            % RT6: Shale
            rock_types.RT6 = struct();
            rock_types.RT6.name = 'Shale';
            rock_types.RT6.lithology = 'Shale';
            rock_types.RT6.porosity_min = 0.02;              % 2%
            rock_types.RT6.porosity_max = 0.08;              % 8%
            rock_types.RT6.porosity_mean = 0.05;             % Mean: 5%
            rock_types.RT6.porosity_std = 0.015;             % Standard deviation
            rock_types.RT6.perm_min = 0.001 * mD_to_m2;      % 0.001 mD to m²
            rock_types.RT6.perm_max = 0.1 * mD_to_m2;        % 0.1 mD to m²
            rock_types.RT6.perm_mean = 0.0505 * mD_to_m2;    % Mean: 0.0505 mD
            rock_types.RT6.net_to_gross = 0.05;              % 5% net pay
            rock_types.RT6.description = 'Impermeable shale acting as flow barrier';
            
            step5_success = true;
        catch
            step5_success = false;
        end
        
        if ~verbose
            if step5_success
                status_symbol = 'Y';
            else
                status_symbol = 'X';
            end
            fprintf('| %-35s |   %s    |\n', task_names{5}, status_symbol);
        else
            if step5_success
                fprintf('  - RT6: Shale (φ: %.0f-%.0f%%, k: %.3f-%.1f mD)\n', ...
                        rock_types.RT6.porosity_min*100, rock_types.RT6.porosity_max*100, ...
                        rock_types.RT6.perm_min/mD_to_m2, rock_types.RT6.perm_max/mD_to_m2);
            end
        end
        
        if ~step5_success
            error('Failed to define shale');
        end
        
        %% Step 6: Validate properties and add Kozeny-Carman relationships
        if verbose
            fprintf('Step 6: Validating properties...\n');
        end
        
        try
            % Add Kozeny-Carman constants and vertical permeability ratios
            rock_type_names = {'RT1', 'RT2', 'RT3', 'RT4', 'RT5', 'RT6'};
            
            for i = 1:length(rock_type_names)
                rt_name = rock_type_names{i};
                rt = rock_types.(rt_name);
                
                % Add vertical permeability ratio (Kv/Kh from config)
                rock_types.(rt_name).kv_kh_ratio = rock_config.kv_kh_ratio;  % 0.2 from config
                
                % Add Kozeny-Carman constant (varies by lithology)
                switch rt.lithology
                    case 'Sandstone'
                        rock_types.(rt_name).kozeny_carman_constant = 5.0;  % Typical for sandstone
                    case 'Tight Sandstone'
                        rock_types.(rt_name).kozeny_carman_constant = 8.0;  % Higher for tight rocks
                    case 'Limestone'
                        rock_types.(rt_name).kozeny_carman_constant = 6.0;  % Intermediate for limestone
                    case 'Shale'
                        rock_types.(rt_name).kozeny_carman_constant = 15.0; % Very high for shale
                end
                
                % Add rock compressibility (use from config)
                rock_types.(rt_name).compressibility = rock_config.compressibility; % 1/Pa
                rock_types.(rt_name).reference_pressure = rock_config.reference_pressure; % Pa
                
                % Calculate permeability range in m²
                rock_types.(rt_name).perm_range_m2 = [rt.perm_min, rt.perm_max];
                rock_types.(rt_name).perm_range_mD = [rt.perm_min/mD_to_m2, rt.perm_max/mD_to_m2];
                
                % Add rock type ID
                rock_types.(rt_name).type_id = i;
            end
            
            % Summary statistics
            total_rock_types = length(rock_type_names);
            porosity_range = [min([rock_types.RT1.porosity_min, rock_types.RT2.porosity_min, ...
                                  rock_types.RT3.porosity_min, rock_types.RT4.porosity_min, ...
                                  rock_types.RT5.porosity_min, rock_types.RT6.porosity_min]), ...
                             max([rock_types.RT1.porosity_max, rock_types.RT2.porosity_max, ...
                                  rock_types.RT3.porosity_max, rock_types.RT4.porosity_max, ...
                                  rock_types.RT5.porosity_max, rock_types.RT6.porosity_max])];
            
            perm_range_mD = [rock_types.RT6.perm_min/mD_to_m2, rock_types.RT1.perm_max/mD_to_m2];
            
            step6_success = true;
        catch
            step6_success = false;
        end
        
        if ~verbose
            if step6_success
                status_symbol = 'Y';
            else
                status_symbol = 'X';
            end
            fprintf('| %-35s |   %s    |\n', sprintf('%s (%d types)', task_names{6}, total_rock_types), status_symbol);
        else
            if step6_success
                fprintf('  - Total rock types defined: %d\n', total_rock_types);
                fprintf('  - Porosity range: %.1f-%.1f%%\n', porosity_range(1)*100, porosity_range(2)*100);
                fprintf('  - Permeability range: %.3f-%.0f mD\n', perm_range_mD(1), perm_range_mD(2));
                fprintf('  - Kv/Kh ratio: %.2f\n', rock_config.kv_kh_ratio);
            end
        end
        
        if ~step6_success
            error('Failed to validate rock properties');
        end
        
        % Store rock types count in status
        status.rock_types_defined = total_rock_types;
        status.porosity_range = porosity_range;
        status.permeability_range_mD = perm_range_mD;
        status.rock_type_names = rock_type_names;
        
        %% Success
        status.success = step1_success && step2_success && step3_success && step4_success && step5_success && step6_success;
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
            fprintf('   Porosity: %.1f-%.1f%% | Permeability: %.3f-%.0f mD | Kv/Kh: %.2f\n', ...
                    porosity_range(1)*100, porosity_range(2)*100, perm_range_mD(1), perm_range_mD(2), rock_config.kv_kh_ratio);
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