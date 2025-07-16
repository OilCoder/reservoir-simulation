function [states, wellSols] = s05_run_simulation(G, rock, fluid, schedule)
% s05_run_simulation - Execute main MRST simulation using simulateScheduleAD
%
% Execute main MRST simulation using simulateScheduleAD and save states
% in memory. Main orchestrator for flow-compaction simulation.
%
% Args:
%   G: MRST grid structure
%   rock: MRST rock structure  
%   fluid: MRST fluid structure
%   schedule: MRST schedule structure
%
% Returns:
%   states: Cell array of simulation states
%   wellSols: Cell array of well solutions
%
% Requires: MRST

%% ----
%% Step 1 – Simulation setup and validation
%% ----

fprintf('[INFO] Starting MRST simulation...\n');

%% ----
%% Step 2 – Initialize simulation state
%% ----

[state0, config] = s07b_setup_state(G, rock);

%% ----
%% Step 3 – Configure fluid for incompressible simulation
%% ----

fprintf('[INFO] Setting up incompressible flow model\n');

% Ensure fluid is compatible with incompressible solver
if ~isfield(fluid, 'properties')
    fluid.properties = @(state) deal(fluid.mu, fluid.rho);
end

%% ----
%% Step 4 – Execute simulation loop
%% ----

[states, wellSols, sim_time] = s09_execute_simulation_loop(G, rock, fluid, schedule, state0, config);

%% ----
%% Step 5 – Post-simulation processing and statistics
%% ----

% Calculate simulation statistics
total_production = 0;
total_injection = 0;

for i = 1:length(wellSols)
    well_data = wellSols{i};
    for j = 1:length(well_data)
        if strcmp(well_data(j).name, 'PRODUCER')
            total_production = total_production + abs(well_data(j).qOs) * schedule.step.val(i);
        elseif strcmp(well_data(j).name, 'INJECTOR')
            total_injection = total_injection + well_data(j).qWs * schedule.step.val(i);
        end
    end
end

%% ----
%% Step 6 – Print simulation summary
%% ----

fprintf('[INFO] Simulation completed successfully!\n');
fprintf('  Simulation time: %.1f seconds\n', sim_time);
fprintf('  Timesteps: %d\n', length(states));
fprintf('  Total production: %.0f m³\n', total_production);
fprintf('  Total injection: %.0f m³\n', total_injection);

% Calculate final pressure change
p_final = mean(states{end}.pressure);
p_initial = mean(states{1}.pressure);
dp_avg = (p_final - p_initial) / 6894.76;  % Convert Pa to psi

fprintf('[INFO] Average pressure change: %.1f psi\n', dp_avg);

% Calculate porosity change if compaction enabled
if isfield(rock, 'c_phi')
    if isfield(states{end}, 'poro')
        poro_change = mean(states{end}.poro - rock.poro0);
        fprintf('[INFO] Average porosity change: %.4f\n', poro_change);
    end
end

fprintf('[INFO] Saving %d states and %d well solutions\n', ...
    length(states), length(wellSols));

%% ----
%% Step 7 – Calculate and export volumetric data for dashboard
%% ----

try
    s10_calculate_volumetric_data(G, states{end});
    fprintf('[INFO] Volumetric data calculated\n');
catch ME
    fprintf('[WARN] Could not calculate volumetric data: %s\n', ME.message);
end

fprintf('[INFO] Results ready for export\n');

end
