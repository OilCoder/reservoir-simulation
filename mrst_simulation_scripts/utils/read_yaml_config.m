function config = read_yaml_config(config_file, silent_mode)
% READ_YAML_CONFIG - Load YAML configuration file for MRST simulations
%
% SYNTAX:
%   config = read_yaml_config(config_file)
%   config = read_yaml_config(config_file, silent_mode)
%
% INPUT:
%   config_file - Path to YAML configuration file
%   silent_mode - (optional) Boolean flag to suppress output [default: false]
%
% OUTPUT:
%   config - Structure containing parsed configuration data
%
% DESCRIPTION:
%   Parses YAML configuration files used by Eagle West Field MRST simulation
%   workflow. Handles the specific YAML format used in the config/ directory.
%
%   Supported YAML features:
%   - Simple key: value pairs
%   - Arrays with [] notation
%   - Nested structures with indentation
%   - Wells configuration with specific well names
%   - Tier structures (critical, standard, marginal) - FIX APPLIED
%
% Author: Claude Code AI System
% Date: August 7, 2025

    % Handle optional arguments
    if nargin < 2
        silent_mode = false;
    end
    
    % Step 1 - Validate input file exists
    if ~exist(config_file, 'file')
        error('Configuration file not found: %s', config_file);
    end
    
    % Step 2 - Parse configuration file
    try
        if ~silent_mode
            fprintf('Loading configuration: %s\n', config_file);
        end
        
        % Suppress warnings during YAML parsing to prevent noise
        original_warning_state = warning('off', 'all');
        
        % Use simple YAML parser for our specific format
        if exist('yaml_parser', 'file')
            % Use YAML parser if available
            config = yaml_parser(config_file);
        else
            % Use built-in simple parser
            config = parse_simple_yaml(config_file);
        end
        
        % Restore warnings
        warning(original_warning_state);
        
    catch ME
        % Restore warnings in case of error
        if exist('original_warning_state', 'var')
            warning(original_warning_state);
        end
        error('Failed to parse YAML file %s: %s', config_file, ME.message);
    end
    
    % Step 3 - Validate configuration structure
    if isempty(config)
        error('Empty configuration file: %s', config_file);
    end
    
    % FIXED: Add validation for nested structure parsing
    validate_nested_structures(config, config_file);
    
    % Display concise success message unless in silent mode
    if ~silent_mode
        fprintf('Configuration loaded successfully\n');
    end

end

function str_out = ltrim_octave(str_in)
% LTRIM_OCTAVE - Left trim function compatible with Octave
% Remove leading whitespace characters
    str_out = str_in;
    while ~isempty(str_out) && isspace(str_out(1))
        str_out = str_out(2:end);
    end
end

function config = parse_simple_yaml(filename)
% PARSE_SIMPLE_YAML - Simple YAML parser for basic configuration files
%
% This is a minimal YAML parser for the specific structure used in
% Eagle West Field configuration files. Handles:
% - Simple key: value pairs
% - Arrays with [] notation
% - Nested structures with indentation
% - Wells configuration with specific well names (EW-001, IW-001, etc.)
% - Tier structures (critical, standard, marginal) - FIX APPLIED
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
        current_subsection = '';
        current_well = '';
        current_subwell = '';
        line_num = 0;
        
        while ~feof(fid)
            line = fgetl(fid);
            line_num = line_num + 1;
            
            if ischar(line)
                original_line = line;
                line = strtrim(line);
                
                % Skip empty lines and comments
                if isempty(line) || strncmp(line, '#', 1)
                    continue;
                end
                
                % Determine indentation level for structure parsing
                indent_level = length(original_line) - length(ltrim_octave(original_line));
                
                % Top-level sections (no indentation)
                if ~isempty(strfind(line, ':')) && indent_level == 0 && ~strncmp(line, '-', 1)
                    tokens = strsplit(line, ':');
                    current_section = strtrim(tokens{1});
                    current_subsection = '';
                    current_well = '';
                    current_subwell = '';
                    
                    if length(tokens) > 1 && ~isempty(strtrim(tokens{2}))
                        config.(current_section) = parse_value(strtrim(tokens{2}));
                    else
                        config.(current_section) = struct();
                    end
                    
                % Second-level sections (2 spaces)
                elseif ~isempty(strfind(line, ':')) && indent_level == 2 && ~strncmp(line, '-', 1)
                    if isempty(current_section)
                        continue;
                    end
                    
                    tokens = strsplit(line, ':');
                    current_subsection = strtrim(tokens{1});
                    current_well = '';
                    current_subwell = '';
                    
                    if length(tokens) > 1 && ~isempty(strtrim(tokens{2}))
                        config.(current_section).(current_subsection) = parse_value(strtrim(tokens{2}));
                    else
                        % Initialize as struct for nested content - FIXED FOR NESTED STRUCTURES
                        config.(current_section).(current_subsection) = struct();
                    end
                    
                % Third-level sections (4 spaces) - well names or parameters
                elseif ~isempty(strfind(line, ':')) && indent_level == 4 && ~strncmp(line, '-', 1)
                    if isempty(current_section) || isempty(current_subsection)
                        continue;
                    end
                    
                    tokens = strsplit(line, ':');
                    param_name = strtrim(tokens{1});
                    
                    % Check if it's a well name (EW-001, IW-001, etc.) or fault name (Fault_A, Fault_B, etc.)
                    if ~isempty(strfind(param_name, 'W-')) || ~isempty(strfind(param_name, 'Fault_')) || strcmp(param_name, 'phase_1') || ...
                       strcmp(param_name, 'phase_2') || strcmp(param_name, 'phase_3') || ...
                       strcmp(param_name, 'phase_4') || strcmp(param_name, 'phase_5') || ...
                       strcmp(param_name, 'phase_6')
                        current_well = param_name;
                        current_subwell = '';
                        
                        if length(tokens) > 1 && ~isempty(strtrim(tokens{2}))
                            config.(current_section).(current_subsection).(current_well) = parse_value(strtrim(tokens{2}));
                        else
                            config.(current_section).(current_subsection).(current_well) = struct();
                        end
                    else
                        % CRITICAL FIX: Handle zone names at same indentation level
                        % Check if this is a new zone definition (empty value after colon)
                        if length(tokens) > 1 && ~isempty(strtrim(tokens{2}))
                            % Has a value - this is a parameter for current zone
                            if ~isempty(current_well)
                                % Add parameter to current nested structure (e.g., layers to upper_zone)
                                param_value = strtrim(tokens{2});
                                config.(current_section).(current_subsection).(current_well).(param_name) = parse_value(param_value);
                            else
                                % Regular parameter at this level
                                param_value = strtrim(tokens{2});
                                config.(current_section).(current_subsection).(param_name) = parse_value(param_value);
                            end
                        else
                            % Empty value - this is a new zone definition
                            % FIXED: Reset context for new zone at same level
                            config.(current_section).(current_subsection).(param_name) = struct();
                            current_well = param_name;
                            current_subwell = '';
                        end
                    end
                    
                % Fourth-level sections (6 spaces) - well parameters or tier names
                elseif ~isempty(strfind(line, ':')) && indent_level == 6 && ~strncmp(line, '-', 1)
                    if isempty(current_section) || isempty(current_subsection)
                        continue;
                    end
                    
                    tokens = strsplit(line, ':');
                    param_name = strtrim(tokens{1});
                    
                    % FIX: Handle tier names (critical, standard, marginal, major, minor) at 6-space level
                    if strcmp(param_name, 'critical') || strcmp(param_name, 'standard') || ...
                       strcmp(param_name, 'marginal') || strcmp(param_name, 'major') || strcmp(param_name, 'minor')
                        
                        % This is a tier definition - need to find the parent structure
                        % Look for well_tiers or fault_tiers in current subsection
                        if isfield(config.(current_section).(current_subsection), 'well_tiers')
                            % Add to well_tiers
                            if length(tokens) > 1 && ~isempty(strtrim(tokens{2}))
                                config.(current_section).(current_subsection).well_tiers.(param_name) = parse_value(strtrim(tokens{2}));
                            else
                                config.(current_section).(current_subsection).well_tiers.(param_name) = struct();
                            end
                            current_well = param_name; % Track current tier for nested params
                            
                        elseif isfield(config.(current_section).(current_subsection), 'fault_tiers')
                            % Add to fault_tiers
                            if length(tokens) > 1 && ~isempty(strtrim(tokens{2}))
                                config.(current_section).(current_subsection).fault_tiers.(param_name) = parse_value(strtrim(tokens{2}));
                            else
                                config.(current_section).(current_subsection).fault_tiers.(param_name) = struct();
                            end
                            current_well = param_name; % Track current tier for nested params
                        end
                        
                    elseif ~isempty(current_well)
                        % Check if it's a sub-well element (like ESP systems)
                        if strcmp(param_name, 'GC-2500') || strcmp(param_name, 'GC-4000') || ...
                           strcmp(param_name, 'GC-6000') || strcmp(param_name, 'GC-8000') || ...
                           strcmp(param_name, 'GC-10000') || ~isempty(strfind(param_name, '_'))
                            current_subwell = param_name;
                            
                            if length(tokens) > 1 && ~isempty(strtrim(tokens{2}))
                                config.(current_section).(current_subsection).(current_well).(current_subwell) = parse_value(strtrim(tokens{2}));
                            else
                                config.(current_section).(current_subsection).(current_well).(current_subwell) = struct();
                            end
                        else
                            % Regular well parameter
                            if length(tokens) > 1
                                param_value = strtrim(tokens{2});
                                config.(current_section).(current_subsection).(current_well).(param_name) = parse_value(param_value);
                            end
                        end
                    end
                    
                % Fifth-level sections (8 spaces) - tier parameters
                elseif ~isempty(strfind(line, ':')) && indent_level == 8 && ~strncmp(line, '-', 1)
                    if isempty(current_section) || isempty(current_subsection) || isempty(current_well)
                        continue;
                    end
                    
                    tokens = strsplit(line, ':');
                    param_name = strtrim(tokens{1});
                    
                    if length(tokens) > 1
                        param_value = strtrim(tokens{2});
                        
                        % FIX: Handle tier parameters (wells, radius, factor, etc.)
                        if strcmp(current_well, 'critical') || strcmp(current_well, 'standard') || ...
                           strcmp(current_well, 'marginal') || strcmp(current_well, 'major') || strcmp(current_well, 'minor')
                            
                            % Check if we're in well_tiers or fault_tiers context
                            if isfield(config.(current_section).(current_subsection), 'well_tiers') && ...
                               isfield(config.(current_section).(current_subsection).well_tiers, current_well)
                                config.(current_section).(current_subsection).well_tiers.(current_well).(param_name) = parse_value(param_value);
                            elseif isfield(config.(current_section).(current_subsection), 'fault_tiers') && ...
                                   isfield(config.(current_section).(current_subsection).fault_tiers, current_well)
                                config.(current_section).(current_subsection).fault_tiers.(current_well).(param_name) = parse_value(param_value);
                            end
                            
                        elseif ~isempty(current_subwell)
                            % Property of sub-well element
                            config.(current_section).(current_subsection).(current_well).(current_subwell).(param_name) = parse_value(param_value);
                        else
                            % Property of well
                            config.(current_section).(current_subsection).(current_well).(param_name) = parse_value(param_value);
                        end
                    end
                    
                elseif strncmp(original_line, '    -', 5) || strncmp(original_line, '      -', 7) || strncmp(original_line, '        -', 9)
                    % Array element with dash format (e.g., "    - name: Fault_A")
                    array_content = strtrim(line(2:end)); % Remove the dash
                    
                    if ~isempty(current_section) && ~isempty(current_subsection)
                        target_struct = config.(current_section).(current_subsection);
                        if ~isempty(current_well)
                            target_struct = target_struct.(current_well);
                        end
                        if ~isempty(current_subwell)
                            target_struct = target_struct.(current_subwell);
                        end
                        
                        % Initialize array if it doesn't exist - this creates issues, skip arrays for now
                        % Arrays are not heavily used in wells config
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
                        % String element - FIX: Remove quotes from array elements
                        % Remove quotes if present (this fixes the s20 error)
                        if (strncmp(element, '"', 1) && element(end) == '"') || ...
                           (strncmp(element, "'", 1) && element(end) == "'")
                            element = element(2:end-1);
                        end
                        
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
    if strcmpi(value_str, 'true') || strcmpi(value_str, 'yes')
        value = true;
        return;
    elseif strcmpi(value_str, 'false') || strcmpi(value_str, 'no')
        value = false;
        return;
    end
    
    % Handle null/empty values
    if strcmpi(value_str, 'null') || strcmpi(value_str, 'nil') || ...
       strcmpi(value_str, '~') || isempty(value_str)
        value = [];
        return;
    end
    
    % Handle string ranges like [85, 120]
    if ~isempty(strfind(value_str, ',')) && ...
       ~isempty(strfind(value_str, '[')) && ...
       ~isempty(strfind(value_str, ']'))
        % This should be handled by array parsing above
        value = value_str;
        return;
    end
    
    % Default to string
    value = value_str;

end

function validate_nested_structures(config, config_file)
% VALIDATE_NESTED_STRUCTURES - Check for common nested structure parsing issues
%
% This function validates that nested structures were parsed correctly,
% specifically checking for empty arrays where structures should be.

    % Check rock_properties.layer_architecture if present
    if isfield(config, 'rock_properties') && isfield(config.rock_properties, 'layer_architecture')
        layer_arch = config.rock_properties.layer_architecture;
        
        if isstruct(layer_arch)
            zone_names = fieldnames(layer_arch);
            for i = 1:length(zone_names)
                zone_name = zone_names{i};
                zone_data = layer_arch.(zone_name);
                
                % Check for the bug: empty array instead of structure
                if isempty(zone_data) && ~isstruct(zone_data)
                    error(['YAML Parser Error: Zone "%s" in layer_architecture is empty.\n' ...
                           'This indicates nested structure parsing failed.\n' ...
                           'Expected: structure with fields like layers, description\n' ...
                           'Got: empty array\n' ...
                           'File: %s'], zone_name, config_file);
                end
                
                % Warn if structure exists but is missing expected fields
                if isstruct(zone_data) && ~isfield(zone_data, 'layers')
                    warning('Zone "%s" missing expected "layers" field in %s', zone_name, config_file);
                end
                
                % CRITICAL: Check for the zone merging bug
                % Detect if other zones are nested as fields within this zone
                if isstruct(zone_data)
                    zone_fields = fieldnames(zone_data);
                    known_zone_names = {'upper_zone', 'shale_barrier_1', 'middle_zone', 'shale_barrier_2', 'lower_zone'};
                    other_zones = setdiff(known_zone_names, {zone_name});
                    
                    % Check if any field matches another zone name
                    nested_zones = intersect(zone_fields, other_zones);
                    if ~isempty(nested_zones)
                        error(['YAML Parser Error: Zone merging bug detected in zone "%s".\n' ...
                               'Found other zones nested as fields: %s\n' ...
                               'This indicates incorrect zone context tracking.\n' ...
                               'Expected: Each zone as separate struct in layer_architecture\n' ...
                               'Got: Zones merged into first zone\n' ...
                               'File: %s'], zone_name, strjoin(nested_zones, ', '), config_file);
                    end
                end
            end
        end
    end
    
    % Can add more validation for other nested structures as needed
    
end