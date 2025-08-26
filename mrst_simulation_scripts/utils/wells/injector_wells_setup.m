function injector_wells = injector_wells_setup(config, G)
% INJECTOR_WELLS_SETUP - Create injector well structures for Eagle West Field
%
% INPUTS:
%   config - Configuration structure with wells configuration
%   G      - Grid structure
%
% OUTPUTS:
%   injector_wells - Cell array of injector well structures
%
% Author: Claude Code AI System
% Date: August 23, 2025

    if ~isfield(config, 'injectors')
        error('Missing injectors section in wells configuration. REQUIRED: Add injectors section to wells_config.yaml');
    end
    
    injectors_config = config.injectors;
    injector_names = fieldnames(injectors_config);
    injector_wells = cell(length(injector_names), 1);
    
    for i = 1:length(injector_names)
        well_name = injector_names{i};
        well_config = injectors_config.(well_name);
        
        % Create basic well structure
        well = create_well_structure(well_name, 'injector', well_config, G);
        
        % Add injector-specific properties
        well = add_injector_properties(well, well_config);
        
        % Add well geometry
        well = add_well_geometry(well, well_config, G);
        
        injector_wells{i} = well;
    end
    
    fprintf('Injector wells created: %d wells\n', length(injector_wells));
end

function well = create_well_structure(well_name, well_type, well_config, G)
% Create basic well structure
    well = struct();
    well.name = well_name;
    well.type = well_type;
    well.status = 'active';
    
    % Load well location from configuration
    if isfield(well_config, 'grid_location')
        grid_loc = well_config.grid_location;
        well.i = grid_loc.i;
        well.j = grid_loc.j;
        well.k = grid_loc.k;
    else
        error('Missing grid_location for well %s. REQUIRED: Add grid_location: {i, j, k} to well configuration.', well_name);
    end
    
    % Calculate cell index
    if well.i >= 1 && well.i <= G.cartDims(1) && well.j >= 1 && well.j <= G.cartDims(2) && well.k >= 1 && well.k <= G.cartDims(3)
        well.cells = sub2ind(G.cartDims, well.i, well.j, well.k);
    else
        error('Invalid grid location for well %s: (%d,%d,%d). Grid dimensions: %dx%dx%d', ...
            well_name, well.i, well.j, well.k, G.cartDims(1), G.cartDims(2), G.cartDims(3));
    end
end

function well = add_injector_properties(well, well_config)
% Add injector-specific properties
    % Injection rate control
    if isfield(well_config, 'injection_rate_bpd')
        well.injection_rate = well_config.injection_rate_bpd;
    else
        well.injection_rate = 2000; % Default injection rate
    end
    
    % Maximum bottom hole pressure
    if isfield(well_config, 'bhp_max_psi')
        well.bhp_max = well_config.bhp_max_psi;
    else
        well.bhp_max = 5000; % Default maximum BHP
    end
    
    % Injected fluid type
    if isfield(well_config, 'injected_fluid')
        well.injected_fluid = well_config.injected_fluid;
    else
        well.injected_fluid = 'water'; % Default to water injection
    end
    
    % Well control type
    well.control_type = 'rate'; % Default to rate control
end

function well = add_well_geometry(well, well_config, G)
% Add well geometry information
    % Well trajectory
    if isfield(well_config, 'well_trajectory')
        well.trajectory = well_config.well_trajectory;
    else
        well.trajectory = 'vertical'; % Default trajectory
    end
    
    % Well radius
    if isfield(well_config, 'wellbore_radius_in')
        well.radius = well_config.wellbore_radius_in / 12; % Convert to feet
    else
        well.radius = 0.25; % Default radius in feet
    end
    
    % Completion layers
    if isfield(well_config, 'completion_layers')
        well.completion_layers = well_config.completion_layers;
    else
        well.completion_layers = well.k; % Default to single layer
    end
    
    % Calculate well index (simplified)
    well.WI = calculate_well_index(well, G);
end

function WI = calculate_well_index(well, G)
% Calculate simplified well index
    % This is a simplified calculation - should use proper MRST functions
    cell_volume = G.cells.volumes(well.cells);
    perm = 100; % Default permeability in mD (should come from rock properties)
    
    % Peaceman well index formula (simplified)
    WI = 2 * pi * perm * 0.001 / log(0.2 * sqrt(cell_volume) / well.radius);
    
    if WI <= 0
        WI = 1.0; % Fallback value
    end
end