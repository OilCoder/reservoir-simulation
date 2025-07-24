function [states, wellSols, simulation_time, export_time] = s08_run_workflow_steps(G, rock, fluid, schedule)
% s08_run_workflow_steps - Execute simulation and export workflow
%
% Runs the MRST simulation and exports the results using the optimized
% data structure.
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
%   simulation_time: Time taken for simulation
%   export_time: Time taken for data export
%
% Requires: MRST

%% ----
%% Step 1 – Simulation execution
%% ----

fprintf('\n--- Step 6: Simulation Execution ---\n');
tic;

% Execute simulation
[states, wellSols] = s05_run_simulation(G, rock, fluid, schedule);

% Verify simulation results
assert(exist('states', 'var') && iscell(states), 'Simulation states not created');
assert(exist('wellSols', 'var') && iscell(wellSols), 'Well solutions not created');
assert(length(states) > 0, 'No simulation states generated');

simulation_time = toc;
fprintf('[INFO] Simulation completed in %.1f seconds\n', simulation_time);

%% ----
%% Step 2 – Dataset export (OPTIMIZED)
%% ----

fprintf('\n--- Step 7: Optimized Dataset Export ---\n');
tic;

% Export snapshots using new optimized system
s06_export_dataset(G, rock, fluid, schedule, states, wellSols);

export_time = toc;
fprintf('[INFO] Optimized dataset export completed in %.1f seconds\n', export_time);

end
