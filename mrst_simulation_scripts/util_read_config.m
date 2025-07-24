function config = util_read_config(config_file)
%util_read_config - Read and parse reservoir configuration from YAML file
%
% Loads reservoir simulation configuration from YAML file and returns
% structured configuration data for MRST simulation workflow.
%
% Args:
%   config_file: Path to YAML configuration file
%
% Returns:
%   config: Structure containing all simulation parameters
%
% Requires: None (pure Octave/MATLAB)

% ----
% Step 1 – Input validation
% ----

if nargin < 1
    error('util_read_config:MissingInput', 'Configuration file path is required');
end

if ~exist(config_file, 'file')
    error('util_read_config:FileNotFound', 'Configuration file not found: %s', config_file);
end

% ----
% Step 2 – Read YAML file content
% ----

% Read file line by line
fid = fopen(config_file, 'r');
if fid == -1
    error('util_read_config:FileAccess', 'Cannot open configuration file: %s', config_file);
end

lines = {};
while ~feof(fid)
    line = fgetl(fid);
    if ischar(line)
        lines{end+1} = line;
    end
end
fclose(fid);

% ----
% Step 3 – Parse YAML content
% ----

config = struct();
current_section = '';
current_subsection = '';
current_list_key = '';
list_index = 0;

for i = 1:length(lines)
    line = strtrim(lines{i});
    
    % Skip empty lines and comments
    if isempty(line) || (length(line) >= 1 && line(1) == '#')
        continue;
    end
    
    % Detect section headers (no indentation, ends with colon)
    if ~(length(line) >= 1 && line(1) == ' ') && (length(line) >= 1 && line(end) == ':')
        current_section = strtrim(line(1:end-1));
        current_subsection = '';
        current_list_key = '';
        list_index = 0;
        config.(current_section) = struct();
        continue;
    end
    
    % Detect subsection headers (2-space indentation, ends with colon)
    if (length(line) >= 2 && strncmp(line, '  ', 2)) && ~(length(line) >= 4 && strncmp(line, '    ', 4)) && (length(line) >= 1 && line(end) == ':')
        current_subsection = strtrim(line(3:end-1));
        current_list_key = '';
        list_index = 0;
        if ~isempty(current_section)
            config.(current_section).(current_subsection) = struct();
        end
        continue;
    end
    
    % Detect list items (starts with dash)
    if ~isempty(strfind(line, '- '))
        dash_pos = strfind(line, '- ');
        indent_level = dash_pos(1) - 1;
        
        if indent_level == 4  % List under subsection
            list_index = list_index + 1;
            item_content = strtrim(line(dash_pos(1)+2:end));
            
            if ~isempty(strfind(item_content, ':'))
                % List item with properties
                current_list_key = sprintf('item_%d', list_index);
                if ~isempty(current_section) && ~isempty(current_subsection)
                    config.(current_section).(current_subsection).(current_list_key) = struct();
                end
                
                % Parse the first property on the same line
                colon_pos = strfind(item_content, ':');
                if length(colon_pos) > 0
                    key = strtrim(item_content(1:colon_pos(1)-1));
                    value = strtrim(item_content(colon_pos(1)+1:end));
                    parsed_value = parse_yaml_value(value);
                    if ~isempty(current_section) && ~isempty(current_subsection)
                        config.(current_section).(current_subsection).(current_list_key).(key) = parsed_value;
                    end
                end
            else
                % Simple list item
                parsed_value = parse_yaml_value(item_content);
                if ~isempty(current_section) && ~isempty(current_subsection)
                    if ~isfield(config.(current_section), current_subsection)
                        config.(current_section).(current_subsection) = {};
                    end
                    config.(current_section).(current_subsection){end+1} = parsed_value;
                end
            end
        end
        continue;
    end
    
    % Parse key-value pairs
    if ~isempty(strfind(line, ':'))
        colon_pos = strfind(line, ':');
        key = strtrim(line(1:colon_pos(1)-1));
        value = strtrim(line(colon_pos(1)+1:end));
        
        % Determine indentation level
        indent_level = length(line) - length(ltrim(line));
        
        if indent_level >= 6 && ~isempty(current_list_key)
            % Property of list item
            parsed_value = parse_yaml_value(value);
            if ~isempty(current_section) && ~isempty(current_subsection)
                config.(current_section).(current_subsection).(current_list_key).(key) = parsed_value;
            end
        elseif indent_level >= 4 && ~isempty(current_subsection)
            % Property of subsection
            parsed_value = parse_yaml_value(value);
            if ~isempty(current_section)
                config.(current_section).(current_subsection).(key) = parsed_value;
            end
        elseif indent_level >= 2 && ~isempty(current_section)
            % Property of section
            parsed_value = parse_yaml_value(value);
            config.(current_section).(key) = parsed_value;
        end
    end
end

% ----
% Step 4 – Validate required sections
% ----

required_sections = {'grid', 'rock', 'fluid', 'wells', 'simulation', 'initial_conditions'};
for i = 1:length(required_sections)
    section = required_sections{i};
    if ~isfield(config, section)
        warning('util_read_config:MissingSection', 'Required section "%s" not found in configuration', section);
    end
end

fprintf('Configuration loaded successfully from: %s\n', config_file);

end

function parsed_value = parse_yaml_value(value_str)
%parse_yaml_value - Parse YAML value string to appropriate MATLAB type
%
% Args:
%   value_str: String value from YAML file
%
% Returns:
%   parsed_value: Parsed value (number, string, logical, or array)

value_str = strtrim(value_str);

% Handle null/empty values
if isempty(value_str) || strcmp(value_str, 'null') || strcmp(value_str, '~')
    parsed_value = [];
    return;
end

% Handle boolean values
if strcmp(value_str, 'true')
    parsed_value = true;
    return;
elseif strcmp(value_str, 'false')
    parsed_value = false;
    return;
end

% Handle arrays [a, b, c]
if (length(value_str) >= 1 && value_str(1) == '[') && (length(value_str) >= 1 && value_str(end) == ']')
    array_content = value_str(2:end-1);
    if isempty(strtrim(array_content))
        parsed_value = [];
        return;
    end
    
    % Split by comma and parse each element
    elements = strsplit(array_content, ',');
    parsed_value = [];
    for i = 1:length(elements)
        element = strtrim(elements{i});
        element_value = parse_yaml_value(element);
        if isnumeric(element_value)
            parsed_value(end+1) = element_value;
        else
            % Non-numeric arrays not supported in this simple parser
            parsed_value{end+1} = element_value;
        end
    end
    return;
end

% Handle quoted strings
if ((length(value_str) >= 2 && value_str(1) == '"' && value_str(end) == '"')) || ...
   ((length(value_str) >= 2 && value_str(1) == '''' && value_str(end) == ''''))
    parsed_value = value_str(2:end-1);
    return;
end

% Try to parse as number
num_value = str2double(value_str);
if ~isnan(num_value)
    parsed_value = num_value;
    return;
end

% Handle scientific notation
if ~isempty(strfind(value_str, 'e')) || ~isempty(strfind(value_str, 'E'))
    num_value = str2double(value_str);
    if ~isnan(num_value)
        parsed_value = num_value;
        return;
    end
end

% Default to string
parsed_value = value_str;

end