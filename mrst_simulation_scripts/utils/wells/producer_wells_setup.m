function producer_wells = producer_wells_setup(config, G)
% PRODUCER_WELLS_SETUP - Create producer well structures for Eagle West Field
%
% INPUTS:
%   config - Configuration structure with wells configuration
%   G      - Grid structure
%
% OUTPUTS:
%   producer_wells - Cell array of producer well structures
%
% Author: Claude Code AI System
% Date: August 23, 2025

    if ~isfield(config, 'producers')
        error('Missing producers section in wells configuration. REQUIRED: Add producers section to wells_config.yaml');
    end
    
    producers_config = config.producers;
    producer_names = fieldnames(producers_config);
    producer_wells = cell(length(producer_names), 1);
    
    for i = 1:length(producer_names)
        well_name = producer_names{i};
        well_config = producers_config.(well_name);
        
        % Create basic well structure
        well = create_well_structure(well_name, 'producer', well_config, G);
        
        % Add producer-specific properties
        well = add_producer_properties(well, well_config);
        
        % Add well geometry
        well = add_well_geometry(well, well_config, G);
        
        producer_wells{i} = well;
    end
    
    fprintf('Producer wells created: %d wells\n', length(producer_wells));
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

function well = add_producer_properties(well, well_config)
% Add producer-specific properties
    % Production rate control
    if isfield(well_config, 'production_rate_bpd')
        well.production_rate = well_config.production_rate_bpd;
    else
        well.production_rate = 1000; % Default rate
    end
    
    % Bottom hole pressure limit
    if isfield(well_config, 'bhp_limit_psi')
        well.bhp_limit = well_config.bhp_limit_psi;
    else
        well.bhp_limit = 1500; % Default BHP limit
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