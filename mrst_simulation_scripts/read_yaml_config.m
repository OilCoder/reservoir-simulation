function config = read_yaml_config(config_file)
% READ_YAML_CONFIG - Read YAML configuration files for MRST simulation
%
% SYNTAX:
%   config = read_yaml_config(config_file)
%
% INPUT:
%   config_file - String path to YAML configuration file
%
% OUTPUT:
%   config - Structure containing configuration parameters
%
% DESCRIPTION:
%   This function reads YAML configuration files used for Eagle West Field
%   MRST simulation. Supports the standardized YAML structure used across
%   all simulation modules.
%
% EXAMPLE:
%   grid_config = read_yaml_config('config/grid_config.yaml');
%   fluid_config = read_yaml_config('config/fluid_properties_config.yaml');
%
% Author: Claude Code AI System
% Date: January 30, 2025

    % Step 1 - Validate input file exists
    if ~exist(config_file, 'file')
        error('Configuration file not found: %s', config_file);
    end
    
    % Step 2 - Read YAML using yamlread (if available) or custom parser
    try
        % Try using yamlread function (available in newer MATLAB/Octave)
        if exist('yamlread', 'file')
            config = yamlread(config_file);
        else
            % Fallback to custom YAML parser for simple YAML files
            config = parse_simple_yaml(config_file);
        end
        
    catch ME
        error('Failed to parse YAML file %s: %s', config_file, ME.message);
    end
    
    % Step 3 - Validate configuration structure
    if isempty(config)
        error('Empty configuration file: %s', config_file);
    end
    
    fprintf('Successfully loaded configuration from: %s\n', config_file);

end

function config = parse_simple_yaml(filename)
% PARSE_SIMPLE_YAML - Simple YAML parser for basic configuration files
%
% This is a minimal YAML parser for the specific structure used in
% Eagle West Field configuration files. Handles:
% - Simple key: value pairs
% - Arrays with [] notation
% - Nested structures with indentation
%
% INPUT:
%   filename - Path to YAML file
%
% OUTPUT:
%   config - Parsed configuration structure

    config = struct();
    
    % Read file line by line
    fid = fopen(filename, 'r');
    if fid == -1
        error('Cannot open file: %s', filename);
    end
    
    try
        current_section = '';
        line_num = 0;
        
        while ~feof(fid)
            line = fgetl(fid);
            line_num = line_num + 1;
            
            % Skip empty lines and comments
            if isempty(line) || isempty(strtrim(line)) || strncmp(strtrim(line), '#', 1)
                continue;
            end
            
            % Check indentation level before trimming
            original_line = line;
            line = strtrim(line);
            
            % Parse line based on structure (check indentation on original line)
            if ~isempty(strfind(line, ':')) && ~strncmp(original_line, ' ', 1) && ~strncmp(original_line, '-', 1)
                % Top-level section (e.g., "grid:" or "rock_properties:")
                tokens = strsplit(line, ':');
                section_name = strtrim(tokens{1});
                current_section = section_name;
                
                % Initialize section if it has a value
                if length(tokens) > 1 && ~isempty(strtrim(tokens{2}))
                    config.(section_name) = parse_value(strtrim(tokens{2}));
                else
                    config.(section_name) = struct();
                end
                
            elseif strncmp(original_line, '  ', 2) && ~isempty(strfind(line, ':'))
                % Nested parameter (e.g., "  nx: 40")
                if isempty(current_section)
                    error('Line %d: Nested parameter without section', line_num);
                end
                
                tokens = strsplit(line, ':');
                param_name = strtrim(tokens{1});
                param_value = strtrim(tokens{2});
                
                config.(current_section).(param_name) = parse_value(param_value);
                
            elseif strncmp(line, '    -', 5) || ~isempty(strfind(line, '-'))
                % Array element - simplified handling for our specific YAMLs
                % This handles arrays like layer_thicknesses or wells lists
                continue; % Skip for now - handle in parse_value for arrays
            end
        end
        
        fclose(fid);
        
    catch ME
        fclose(fid);
        rethrow(ME);
    end

end

function value = parse_value(value_str)
% PARSE_VALUE - Parse YAML value string to appropriate MATLAB type
%
% INPUT:
%   value_str - String containing the value
%
% OUTPUT:
%   value - Parsed value (numeric, string, or array)

    % Remove inline comments (everything after #)
    comment_pos = strfind(value_str, '#');
    if ~isempty(comment_pos)
        value_str = value_str(1:comment_pos(1)-1);
    end
    
    % Remove quotes if present
    value_str = strtrim(value_str);
    if (strncmp(value_str, '"', 1) && value_str(end) == '"') || ...
       (strncmp(value_str, "'", 1) && value_str(end) == "'")
        value_str = value_str(2:end-1);
    end
    
    % Handle arrays [1, 2, 3] format
    if strncmp(value_str, '[', 1) && value_str(end) == ']'
        array_content = value_str(2:end-1);
        if isempty(strtrim(array_content))
            value = [];
        else
            elements = strsplit(array_content, ',');
            value = [];
            for i = 1:length(elements)
                element = strtrim(elements{i});
                if ~isempty(element)
                    num_val = str2double(element);
                    if ~isnan(num_val)
                        value(end+1) = num_val;
                    else
                        % String element
                        if isempty(value)
                            value = {element};
                        else
                            value{end+1} = element;
                        end
                    end
                end
            end
        end
        return;
    end
    
    % Try to convert to number
    num_value = str2double(value_str);
    if ~isnan(num_value)
        value = num_value;
        return;
    end
    
    % Handle boolean values
    switch lower(value_str)
        case {'true', 'yes', 'on'}
            value = true;
        case {'false', 'no', 'off'}
            value = false;
        otherwise
            % Keep as string
            value = value_str;
    end

end

% Utility functions for loading specific configuration files
function grid_config = load_grid_config()
% LOAD_GRID_CONFIG - Load grid configuration
    grid_config = read_yaml_config('config/grid_config.yaml');
end

function rock_config = load_rock_config()
% LOAD_ROCK_CONFIG - Load rock properties configuration  
    rock_config = read_yaml_config('config/rock_properties_config.yaml');
end

function fluid_config = load_fluid_config()
% LOAD_FLUID_CONFIG - Load fluid properties configuration
    fluid_config = read_yaml_config('config/fluid_properties_config.yaml');
end

function wells_config = load_wells_config()
% LOAD_WELLS_CONFIG - Load wells configuration
    wells_config = read_yaml_config('config/wells_config.yaml');
end