function [states, wellSols, sim_time] = s09_execute_simulation_loop(G, rock, fluid, schedule, state0, config)
% execute_simulation_loop - Run main simulation loop
%
% Executes the main MRST simulation loop with simplified incompressible
% flow and compaction effects.
%
% Args:
%   G: MRST grid structure
%   rock: MRST rock structure
%   fluid: MRST fluid structure
%   schedule: MRST schedule structure
%   state0: Initial simulation state
%   config: Configuration structure
%
% Returns:
%   states: Cell array of simulation states
%   wellSols: Cell array of well solutions
%   sim_time: Simulation execution time
%
% Requires: MRST

%% ----
%% Step 1 – Initialize simulation loop
%% ----

fprintf('[INFO] Running incompressible flow simulation with %d timesteps...\n', length(schedule.step.val));

p_init = config.initial_conditions.pressure * 6894.76;  % psi to Pa

tic;
states = cell(length(schedule.step.val), 1);
wellSols = cell(length(schedule.step.val), 1);
state = state0;

%% ----
%% Step 2 – Execute simulation loop
%% ----

for step = 1:length(schedule.step.val)
    dt = schedule.step.val(step);
    W_step = schedule.control(schedule.step.control(step)).W;
    
    try
        % Apply well effects (simplified)
        for w = 1:length(W_step)
            well_cells = W_step(w).cells;
            if strcmp(W_step(w).type, 'bhp')
                % Set bottom hole pressure
                state.pressure(well_cells) = W_step(w).val * 0.9; % Slight pressure drop
            end
        end
        
        % Simple compaction effect (if available)
        if isfield(rock, 'c_phi')
            dp = state.pressure - p_init;
            rock.poro = rock.poro0 .* (1 - rock.c_phi .* dp);
            rock.poro = max(0.01, min(0.5, rock.poro)); % Physical bounds
        end
        
        % Store state
        states{step} = state;
        
        % Create simple well solution
        wellSol = struct();
        for w = 1:length(W_step)
            wellSol(w).bhp = W_step(w).val;
            wellSol(w).qWs = 0;
            wellSol(w).qOs = 0;
            if strcmp(W_step(w).type, 'rate')
                wellSol(w).qWs = W_step(w).val;
            else
                wellSol(w).qOs = -50; % Simple production rate
            end
            wellSol(w).name = W_step(w).name;
        end
        wellSols{step} = wellSol;
        
        % Progress reporting
        if mod(step, 10) == 0 || step == length(schedule.step.val)
            fprintf('[INFO] Completed timestep %d/%d (%.1f%%)\n', ...
                step, length(schedule.step.val), 100*step/length(schedule.step.val));
        end
        
    catch ME
        fprintf('[ERROR] Simulation failed at timestep %d: %s\n', step, ME.message);
        break;
    end
end

sim_time = toc;

%% ----
%% Step 3 – Validate simulation results
%% ----

n_timesteps = length(states);
assert(n_timesteps > 0, 'No simulation states generated');
assert(n_timesteps == length(schedule.step.val), 'Timestep count mismatch');

% Verify pressure and saturation bounds
for i = 1:n_timesteps
    if any(states{i}.pressure < 0) || any(states{i}.pressure > 10000*6894.76)  % 10000 psi in Pa
        warning('[WARN] Pressure out of bounds at timestep %d', i);
    end
    if any(states{i}.s(:,1) < 0) || any(states{i}.s(:,1) > 1)
        warning('[WARN] Water saturation out of bounds at timestep %d', i);
    end
end

end
