function [state0, config] = s07b_setup_state(G, rock)
% setup_simulation_state - Initialize simulation state and configuration
%
% Sets up initial pressure and saturation state for MRST simulation
% using hydrostatic equilibrium and capillary pressure equilibrium.
%
% Args:
%   G: MRST grid structure
%   rock: MRST rock structure
%
% Returns:
%   state0: Initial simulation state
%   config: Configuration structure
%
% Requires: MRST

%% ----
%% Step 1 – Load configuration and set initial conditions
%% ----

config_file = '../config/reservoir_config.yaml';
config = util_read_config(config_file);

% Store initial porosity for compaction
rock.poro0 = rock.poro;

%% ----
%% Step 2 – Initialize hydrostatic pressure equilibrium
%% ----

% Get pressure parameters
datum_depth = config.initial_conditions.datum_depth;      % ft
datum_pressure = config.initial_conditions.datum_pressure; % psi
pressure_gradient = config.initial_conditions.pressure_gradient; % psi/ft

% Convert datum depth to meters
datum_depth_m = datum_depth * 0.3048;

% Initialize pressure field based on hydrostatic equilibrium
pressure = zeros(G.cells.num, 1);

for c = 1:G.cells.num
    % Get cell depth in meters, then convert to feet
    cell_depth = G.cells.centroids(c, 3) / 0.3048;
    
    % Calculate pressure using hydrostatic gradient
    % P = P_datum + gradient * (depth - datum_depth)
    pressure_psi = datum_pressure + pressure_gradient * (cell_depth - datum_depth);
    
    % Convert to Pa
    pressure(c) = pressure_psi * 6894.76;
end

fprintf('[INFO] Hydrostatic pressure initialized: %.1f - %.1f psi\n', ...
    min(pressure)/6894.76, max(pressure)/6894.76);

%% ----
%% Step 3 – Initialize saturation with fluid contacts
%% ----

% Get fluid contact depths
owc_depth = config.initial_conditions.oil_water_contact;  % ft
goc_depth = config.initial_conditions.gas_oil_contact;    % ft

% Initialize saturation arrays
sw_init = zeros(G.cells.num, 1);
so_init = zeros(G.cells.num, 1);
sg_init = zeros(G.cells.num, 1);

for c = 1:G.cells.num
    % Get cell depth in feet
    cell_depth = G.cells.centroids(c, 3) / 0.3048;
    
    % Determine fluid zone based on depth
    if cell_depth <= goc_depth
        % Gas zone
        sg_init(c) = config.initial_conditions.gas_zone.gas_saturation;
        so_init(c) = config.initial_conditions.gas_zone.oil_saturation;
        sw_init(c) = config.initial_conditions.gas_zone.water_saturation;
    elseif cell_depth <= owc_depth
        % Oil zone
        so_init(c) = config.initial_conditions.oil_zone.oil_saturation;
        sw_init(c) = config.initial_conditions.oil_zone.water_saturation;
        sg_init(c) = 0.0;
    else
        % Water zone
        sw_init(c) = config.initial_conditions.water_zone.water_saturation;
        so_init(c) = 0.0;
        sg_init(c) = 0.0;
    end
    
    % Apply capillary pressure transition if enabled
    if config.initial_conditions.capillary_pressure.enabled
        transition_height = config.initial_conditions.capillary_pressure.transition_zone_height;
        
        % Apply transition near OWC
        if abs(cell_depth - owc_depth) <= transition_height/2
            % Simple linear transition
            transition_factor = (transition_height/2 - abs(cell_depth - owc_depth)) / (transition_height/2);
            
            if cell_depth < owc_depth
                % Above OWC - increase water saturation
                sw_increase = 0.1 * transition_factor;
                sw_init(c) = min(1.0, sw_init(c) + sw_increase);
                so_init(c) = max(0.0, so_init(c) - sw_increase);
            else
                % Below OWC - decrease water saturation
                sw_decrease = 0.1 * transition_factor;
                sw_init(c) = max(0.0, sw_init(c) - sw_decrease);
                so_init(c) = min(1.0, so_init(c) + sw_decrease);
            end
        end
    end
end

% Create state structure (assuming 2-phase oil-water for now)
state0 = struct('pressure', pressure, 's', [sw_init, so_init]);

fprintf('[INFO] Initial saturations by zone:\n');
fprintf('  Gas zone: Sg=%.2f, So=%.2f, Sw=%.2f\n', ...
    mean(sg_init(sg_init > 0)), mean(so_init(sg_init > 0)), mean(sw_init(sg_init > 0)));
fprintf('  Oil zone: So=%.2f, Sw=%.2f\n', ...
    mean(so_init(so_init > 0 & sg_init == 0)), mean(sw_init(so_init > 0 & sg_init == 0)));
fprintf('  Water zone: Sw=%.2f\n', mean(sw_init(sw_init > 0.9)));

fprintf('[INFO] Initial state configured with hydrostatic equilibrium\n');

end
