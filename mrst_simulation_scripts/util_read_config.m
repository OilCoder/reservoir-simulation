function config = util_read_config(config_file)
% UTIL_READ_CONFIG - Read YAML configuration files for MRST simulation
%
% SYNTAX:
%   config = util_read_config(config_file)
%
% DESCRIPTION:
%   Reads YAML configuration files and returns structured data for MRST
%   reservoir simulation setup. Handles nested structures, arrays, and
%   numeric conversions required for simulation parameters.
%
% INPUT:
%   config_file - String path to YAML configuration file
%
% OUTPUT:
%   config - Structure containing configuration parameters
%
% EXAMPLE:
%   rock_config = util_read_config('config/rock_properties_config.yaml');
%   fluid_config = util_read_config('config/fluid_properties_config.yaml');
%
% NOTE:
%   Requires MATLAB R2019a or later for built-in YAML support.
%   For older versions, falls back to manual parsing.

    % Validate input
    if nargin < 1
        error('util_read_config:MissingInput', 'Configuration file path required');
    end
    
    % Check if file exists
    if ~exist(config_file, 'file')
        error('util_read_config:FileNotFound', 'Configuration file not found: %s', config_file);
    end
    
    try
        % Try MATLAB built-in YAML support (R2019a+)
        if exist('yaml.load', 'file') == 2
            fprintf('[INFO] Reading YAML using MATLAB built-in parser: %s\n', config_file);
            fid = fopen(config_file, 'r');
            yaml_text = fread(fid, '*char')';
            fclose(fid);
            config = yaml.load(yaml_text);
        else
            % Fallback to manual parsing for older MATLAB versions
            fprintf('[INFO] Using fallback YAML parser for: %s\n', config_file);
            config = parse_yaml_fallback(config_file);
        end
        
        % Validate configuration structure
        if ~isstruct(config)
            error('util_read_config:InvalidFormat', 'Configuration file must contain valid YAML structure');
        end
        
        fprintf('[SUCCESS] Configuration loaded successfully: %s\n', config_file);
        
    catch ME
        fprintf('[ERROR] Failed to read configuration file: %s\n', config_file);
        fprintf('[ERROR] %s\n', ME.message);
        rethrow(ME);
    end
end

function config = parse_yaml_fallback(config_file)
% Fallback YAML parser for older MATLAB versions
% Handles basic YAML structures needed for MRST configuration

    fid = fopen(config_file, 'r');
    if fid == -1
        error('util_read_config:CannotOpen', 'Cannot open file: %s', config_file);
    end
    
    config = struct();
    current_section = '';
    current_subsection = '';
    indent_level = 0;
    
    try
        while ~feof(fid)
            line = fgetl(fid);
            if ischar(line)
                line = strtrim(line);
                
                % Skip comments and empty lines
                if isempty(line) || strncmp(line, '#', 1)
                    continue;
                end
                
                % Parse key-value pairs
                if ~isempty(strfind(line, ':'))
                    [key, value] = parse_yaml_line(line);
                    
                    % Determine nesting level
                    leading_spaces = length(line) - length(regexprep(line, '^[ \t]*', ''));
                    
                    if leading_spaces == 0
                        % Top level
                        current_section = key;
                        if isempty(value)
                            config.(key) = struct();
                        else
                            config.(key) = value;
                        end
                    elseif leading_spaces <= 2
                        % Second level
                        current_subsection = key;
                        if isempty(value)
                            if ~isfield(config, current_section)
                                config.(current_section) = struct();
                            end
                            config.(current_section).(key) = struct();
                        else
                            if ~isfield(config, current_section)
                                config.(current_section) = struct();
                            end
                            config.(current_section).(key) = value;
                        end
                    else
                        % Third level and deeper
                        if ~isempty(current_section) && ~isempty(current_subsection)
                            if ~isfield(config, current_section)
                                config.(current_section) = struct();
                            end
                            if ~isfield(config.(current_section), current_subsection)
                                config.(current_section).(current_subsection) = struct();
                            end
                            config.(current_section).(current_subsection).(key) = value;
                        end
                    end
                end
            end
        end
        
        fclose(fid);
        
    catch ME
        fclose(fid);
        rethrow(ME);
    end
end

function [key, value] = parse_yaml_line(line)
% Parse individual YAML line into key-value pair

    colon_pos = strfind(line, ':');
    if isempty(colon_pos)
        parts = {line};
    else
        parts = {line(1:colon_pos(1)-1), line(colon_pos(1)+1:end)};
    end
    key = strtrim(parts{1});
    
    % Clean key name for MATLAB struct field
    key = regexprep(key, '[^a-zA-Z0-9_]', '_');
    key = regexprep(key, '^[0-9]', 'n$0'); % Prefix numbers with 'n'
    
    if length(parts) > 1
        value_str = strtrim(parts{2});
        
        % Handle different value types
        if isempty(value_str)
            value = [];
        elseif strcmp(value_str, 'true') || strcmp(value_str, 'True')
            value = true;
        elseif strcmp(value_str, 'false') || strcmp(value_str, 'False')
            value = false;
        elseif strcmp(value_str, 'null') || strcmp(value_str, 'NULL')
            value = [];
        elseif length(value_str) >= 2 && value_str(1) == '"' && value_str(end) == '"'
            % String value
            value = value_str(2:end-1);
        elseif length(value_str) >= 2 && value_str(1) == '[' && value_str(end) == ']'
            % Array value
            array_str = value_str(2:end-1);
            value = parse_yaml_array(array_str);
        else
            % Try numeric conversion
            num_val = str2double(value_str);
            if ~isnan(num_val)
                value = num_val;
            else
                value = value_str;
            end
        end
    else
        value = [];
    end
end

function array_val = parse_yaml_array(array_str)
% Parse YAML array string into MATLAB array

    elements = split(array_str, ',');
    array_val = [];
    
    for i = 1:length(elements)
        elem = strtrim(elements{i});
        
        % Try numeric conversion
        num_val = str2double(elem);
        if ~isnan(num_val)
            array_val(end+1) = num_val; %#ok<AGROW>
        else
            % Handle string elements
            if length(elem) >= 2 && elem(1) == '"' && elem(end) == '"'
                elem = elem(2:end-1);
            end
            if isempty(array_val)
                array_val = {elem};
            else
                array_val{end+1} = elem; %#ok<AGROW>
            end
        end
    end
end