function fault_geometries = define_fault_geometries(G)
% DEFINE_FAULT_GEOMETRIES - Create 5-fault system from YAML configuration
%
% PURPOSE:
%   Define complete Eagle West fault geometries from fault_config.yaml.
%   Creates array of 5 faults (Fault_A to Fault_E) with properties.
%
% POLICY COMPLIANCE:
%   - Data authority: All parameters from fault_config.yaml
%   - KISS: Delegates to focused utility functions
%
% Author: Claude Code (Policy-compliant refactor)
% Date: 2025-08-22

    % Load configuration and calculate bounds
    fault_config = load_fault_configuration();
    bounds = calculate_field_bounds(G);
    
    % Create and enhance fault array
    fault_geometries = create_fault_array_from_config(bounds, fault_config);
    fault_geometries = add_fault_calculated_properties(fault_geometries, fault_config);

end

function config = load_fault_configuration()
% Load and validate fault configuration from YAML
    try
        func_dir = fileparts(mfilename('fullpath'));
        addpath(fullfile(func_dir, '..'));
        full_config = read_yaml_config('config/fault_config.yaml');
        config = full_config.fault_system;
        
        % Fail-fast validation
        if ~isfield(config, 'faults')
            error('Missing required field in fault_config.yaml: faults');
        end
        
        fprintf('   → Fault configuration loaded: %d faults\n', length(fieldnames(config.faults)));
        
    catch ME
        error(['Failed to load fault configuration from YAML: %s\n' ...
               'Policy violation: No hardcoding allowed'], ME.message);
    end
end

function bounds = calculate_field_bounds(G)
% Calculate field boundary coordinates from grid
    bounds.x_min = min(G.cells.centroids(:,1));
    bounds.x_max = max(G.cells.centroids(:,1));
    bounds.y_min = min(G.cells.centroids(:,2));
    bounds.y_max = max(G.cells.centroids(:,2));
    bounds.center_x = (bounds.x_min + bounds.x_max) / 2;
    bounds.center_y = (bounds.y_min + bounds.y_max) / 2;
end

function faults = create_fault_array_from_config(bounds, fault_config)
% Create fault array directly from YAML configuration
    faults = struct([]);
    yaml_faults = fault_config.faults;
    fault_names = fieldnames(yaml_faults);
    
    for i = 1:length(fault_names)
        fault_data = yaml_faults.(fault_names{i});
        faults(i) = create_single_fault(i, bounds, fault_data);
    end
end

function fault = create_single_fault(index, bounds, fault_data)
% Create single fault from YAML data
    fault.name = fault_data.name;
    fault.type = fault_data.type;
    fault.is_sealing = fault_data.is_sealing;
    fault.strike = fault_data.strike;
    fault.dip = fault_data.dip;
    fault.length = fault_data.length;
    fault.trans_mult = fault_data.transmissibility_multiplier;
    
    % Calculate endpoints
    start_pos = calculate_fault_start_position(index, bounds, fault_data);
    [fault.x1, fault.y1, fault.x2, fault.y2] = ...
        calculate_fault_endpoints(start_pos.x, start_pos.y, fault.length, fault.strike);
end

function start_pos = calculate_fault_start_position(fault_index, bounds, fault_data)
% Calculate fault start position from YAML offsets
    switch fault_index
        case 1  % Fault A
            start_pos.x = bounds.x_min + fault_data.position_offset_x;
            start_pos.y = bounds.center_y + fault_data.position_offset_y;
        case 2  % Fault B
            start_pos.x = bounds.center_x + fault_data.position_offset_x;
            start_pos.y = bounds.center_y + fault_data.position_offset_y;
        case 3  % Fault C
            start_pos.x = bounds.center_x + fault_data.position_offset_x;
            start_pos.y = bounds.y_max + fault_data.position_offset_y;
        case 4  % Fault D
            start_pos.x = bounds.x_min + fault_data.position_offset_x;
            start_pos.y = bounds.center_y + fault_data.position_offset_y;
        case 5  % Fault E
            start_pos.x = bounds.x_max + fault_data.position_offset_x;
            start_pos.y = bounds.y_min + fault_data.position_offset_y;
    end
end

function [x1, y1, x2, y2] = calculate_fault_endpoints(start_x, start_y, length, strike)
% Calculate fault endpoints from geometry
    x1 = start_x;
    y1 = start_y;
    x2 = x1 + length * cosd(strike);
    y2 = y1 + length * sind(strike);
end

function faults = add_fault_calculated_properties(faults, fault_config)
% Add calculated properties from YAML parameters
    geom_params = fault_config.fault_system_properties;
    
    for i = 1:length(faults)
        faults(i).id = i;
        % Use YAML parameters for random variation
        faults(i).displacement = geom_params.displacement_base + ...
            geom_params.displacement_variation * rand();
        faults(i).width = geom_params.width_base + ...
            geom_params.width_variation * rand();
    end
end