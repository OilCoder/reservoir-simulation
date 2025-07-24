function s10_calculate_volumetric_data(G, rock, fluid, schedule, states, wellSols, config)
% calculate_volumetric_data - Calculate and export volumetric data
%
% Calculates cumulative production/injection, recovery factors, and flow
% velocities for dashboard visualization.
%
% Args:
%   G: MRST grid structure
%   rock: MRST rock structure
%   fluid: MRST fluid structure
%   schedule: MRST schedule structure
%   states: Cell array of simulation states
%   wellSols: Cell array of well solutions
%   config: Configuration structure
%
% Returns:
%   None (exports data to files)
%
% Requires: MRST

%% ----
%% Step 1 – Calculate cumulative production/injection
%% ----

% Initialize cumulative arrays
time_days = cumsum(schedule.step.val) / 86400;  % Convert seconds to days
num_wells = length(schedule.control(1).W);
num_timesteps = length(wellSols);

% Initialize cumulative data arrays
cum_oil_prod = zeros(num_timesteps, num_wells);
cum_water_prod = zeros(num_timesteps, num_wells);
cum_water_inj = zeros(num_timesteps, num_wells);

% Calculate cumulative values
for t = 1:num_timesteps
    dt_days = schedule.step.val(t) / 86400;  % Convert to days
    
    for w = 1:num_wells
        if t == 1
            % First timestep
            if wellSols{t}(w).qOs < 0  % Production
                cum_oil_prod(t, w) = abs(wellSols{t}(w).qOs) * dt_days;
            end
            if wellSols{t}(w).qWs < 0  % Water production
                cum_water_prod(t, w) = abs(wellSols{t}(w).qWs) * dt_days;
            elseif wellSols{t}(w).qWs > 0  % Water injection
                cum_water_inj(t, w) = wellSols{t}(w).qWs * dt_days;
            end
        else
            % Add to previous cumulative
            if wellSols{t}(w).qOs < 0
                cum_oil_prod(t, w) = cum_oil_prod(t-1, w) + abs(wellSols{t}(w).qOs) * dt_days;
            else
                cum_oil_prod(t, w) = cum_oil_prod(t-1, w);
            end
            
            if wellSols{t}(w).qWs < 0
                cum_water_prod(t, w) = cum_water_prod(t-1, w) + abs(wellSols{t}(w).qWs) * dt_days;
            else
                cum_water_prod(t, w) = cum_water_prod(t-1, w);
            end
            
            if wellSols{t}(w).qWs > 0
                cum_water_inj(t, w) = cum_water_inj(t-1, w) + wellSols{t}(w).qWs * dt_days;
            else
                cum_water_inj(t, w) = cum_water_inj(t-1, w);
            end
        end
    end
end

%% ----
%% Step 2 – Calculate PV injected and recovery factor
%% ----

% Get reservoir volumetric data from config
pv_initial = config.reservoir_volumetrics.total_pore_volume * config.reservoir_volumetrics.ft3_to_bbl;  % Convert to bbl
ooip_initial = config.reservoir_volumetrics.oil_in_place;  % STB

% Calculate PV injected (total water injection)
pv_injected = cum_water_inj(:, end);  % Use last well (injector)

% Calculate recovery factor
total_oil_produced = cum_oil_prod(:, 1);  % Use first well (producer)
recovery_factor = total_oil_produced / ooip_initial;

% Calculate voidage ratio
voidage_ratio = (cum_water_inj(:, end) - cum_water_prod(:, 1)) / pv_initial;

fprintf('[INFO] Volumetric calculations completed:\n');
fprintf('  OOIP: %.0f STB\n', ooip_initial);
fprintf('  PV initial: %.0f bbl\n', pv_initial);
fprintf('  Final recovery: %.2f%%\n', recovery_factor(end) * 100);

%% ----
%% Step 3 – Calculate flow velocities
%% ----

% Initialize velocity arrays
vx = zeros(num_timesteps, G.cartDims(2), G.cartDims(1));
vy = zeros(num_timesteps, G.cartDims(2), G.cartDims(1));
velocity_magnitude = zeros(num_timesteps, G.cartDims(2), G.cartDims(1));

% Calculate velocities for each timestep (simplified approach)
for t = 1:num_timesteps
    % Get pressure field for this timestep
    pressure_field = reshape(states{t}.pressure, G.cartDims(2), G.cartDims(1));
    
    % Calculate pressure gradients (simplified)
    [grad_x, grad_y] = gradient(pressure_field);
    
    % Calculate velocities using Darcy's law (simplified)
    % v = -(k/μ) * ∇p
    k_avg = mean(rock.perm);  % Average permeability
    mu_avg = mean(fluid.mu);  % Average viscosity
    
    vx(t, :, :) = -(k_avg / mu_avg) * grad_x;
    vy(t, :, :) = -(k_avg / mu_avg) * grad_y;
    
    % Calculate velocity magnitude
    velocity_magnitude(t, :, :) = sqrt(vx(t, :, :).^2 + vy(t, :, :).^2);
end

fprintf('[INFO] Flow velocities calculated for %d timesteps\n', num_timesteps);

%% ----
%% Step 4 – Export data for dashboard
%% ----

% Export cumulative data
cumulative_data = struct();
cumulative_data.time_days = time_days;
cumulative_data.well_names = {'PROD1', 'INJ1'};  % Based on well configuration
cumulative_data.cum_oil_prod = cum_oil_prod;
cumulative_data.cum_water_prod = cum_water_prod;
cumulative_data.cum_water_inj = cum_water_inj;
cumulative_data.pv_injected = pv_injected;
cumulative_data.recovery_factor = recovery_factor;

% Save cumulative data
cumulative_data_path = '../data/simulation_data/dynamic/wells/cumulative_data.mat';
save(cumulative_data_path, 'cumulative_data');

fprintf('[INFO] Cumulative data exported to: %s\n', cumulative_data_path);

% Export flow data
flow_data = struct();
flow_data.time_days = time_days;
flow_data.vx = vx;
flow_data.vy = vy;
flow_data.velocity_magnitude = velocity_magnitude;

% Save flow data
flow_data_path = '../data/simulation_data/dynamic/fields/flow_data.mat';
save(flow_data_path, 'flow_data');

fprintf('[INFO] Flow data exported to: %s\n', flow_data_path);

% Update metadata with reservoir data
metadata_path = '../data/simulation_data/metadata/metadata.mat';
if exist(metadata_path, 'file')
    load(metadata_path);
else
    metadata = struct();
end

% Add reservoir volumetric data
reservoir_data = struct();
reservoir_data.ooip_initial = ooip_initial;
reservoir_data.pv_initial = pv_initial;
reservoir_data.voidage_ratio = voidage_ratio;

metadata.reservoir_data = reservoir_data;

% Save updated metadata
save(metadata_path, 'metadata');

fprintf('[INFO] Metadata updated with reservoir data\n');
fprintf('[INFO] All additional data exported for dashboard\n');

end
