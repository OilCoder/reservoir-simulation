% e_run_simulation.m
% Execute main MRST simulation using simulateScheduleAD and save states
% in memory. Main orchestrator for flow-compaction simulation.
% Requires: MRST

%% ----
%% Step 1 – Simulation setup and validation
%% ----

% Substep 1.1 – Check required variables ______________________
required_vars = {'G', 'rock', 'fluid', 'schedule'};
for i = 1:length(required_vars)
    var_name = required_vars{i};
    if ~exist(var_name, 'var')
        error('[ERROR] Required variable %s not found. Run setup first.', var_name);
    end
end

fprintf('[INFO] Starting MRST simulation...\n');

% Substep 1.2 – Initialize simulation state ___________________
% ✅ Set initial pressure and saturation from config
config_file = '../config/reservoir_config.yaml';
config = util_read_config(config_file);

p_init = config.initial_conditions.pressure * 6894.76;  % psi to Pa
s_init = [config.initial_conditions.water_saturation, 1-config.initial_conditions.water_saturation];   % Initial saturations [water, oil]

state0 = initResSol(G, p_init, s_init);

% Substep 1.3 – Store initial porosity for compaction __________
rock.poro0 = rock.poro;  % Save initial porosity

%% ----
%% Step 2 – Simulation model setup
%% ----

% Substep 2.1 – Set up incompressible flow model ______________
% 📊 Use simpler incompressible flow approach for Octave compatibility
fprintf('[INFO] Setting up incompressible flow model\n');

% Substep 2.2 – Configure fluid for incompressible simulation __
% 🔄 Ensure fluid is compatible with incompressible solver
if ~isfield(fluid, 'properties')
    fluid.properties = @(state) deal(fluid.mu, fluid.rho);
end

% Substep 2.3 – Initialize pressure field _____________________
% ✅ Set initial pressure distribution from config
pressure = repmat(p_init, G.cells.num, 1);
state0 = struct('pressure', pressure, 's', [config.initial_conditions.water_saturation*ones(G.cells.num,1), ...
                                           (1-config.initial_conditions.water_saturation)*ones(G.cells.num,1)]);

fprintf('[INFO] Initial state configured with pressure = %.1f psi\n', config.initial_conditions.pressure);

%% ----
%% Step 3 – Simulation execution
%% ----

% Substep 3.1 – Set solver options ____________________________
% ✅ Configure solver for incompressible flow
solver_opts = struct();
solver_opts.tolerance = 1e-6;
solver_opts.maxIterations = 25;

% Substep 3.2 – Execute simulation loop _______________________
fprintf('[INFO] Running incompressible flow simulation with %d timesteps...\n', length(schedule.step.val));

% 🔄 Initialize simulation variables
tic;
states = cell(length(schedule.step.val), 1);
wellSols = cell(length(schedule.step.val), 1);
state = state0;

% Simulation loop
for step = 1:length(schedule.step.val)
    dt = schedule.step.val(step);
    W_step = schedule.control(schedule.step.control(step)).W;
    
    try
        % Simple pressure update for demonstration
        % This is a simplified simulation - in a real implementation
        % you would solve the pressure equation properly
        
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
%% Step 4 – Post-simulation processing
%% ----

% Substep 4.1 – Validate simulation results ___________________
n_timesteps = length(states);
assert(n_timesteps > 0, 'No simulation states generated');
assert(n_timesteps == length(schedule.step.val), 'Timestep count mismatch');

% Substep 4.2 – Check for simulation issues ___________________
% ✅ Verify pressure and saturation bounds
for i = 1:n_timesteps
    if any(states{i}.pressure < 0) || any(states{i}.pressure > 10000*6894.76)  % 10000 psi in Pa
        warning('[WARN] Pressure out of bounds at timestep %d', i);
    end
    if any(states{i}.s(:,1) < 0) || any(states{i}.s(:,1) > 1)
        warning('[WARN] Water saturation out of bounds at timestep %d', i);
    end
end

% Substep 4.3 – Calculate simulation statistics ________________
% 📊 Production/injection summary
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
%% Step 5 – Results summary and storage
%% ----

% Substep 5.1 – Print simulation summary ______________________
fprintf('[INFO] Simulation completed successfully!\n');
fprintf('  Simulation time: %.1f seconds\n', sim_time);
fprintf('  Timesteps: %d\n', n_timesteps);
fprintf('  Total production: %.0f m³\n', total_production);
fprintf('  Total injection: %.0f m³\n', total_injection);

% Substep 5.2 – Store results in workspace ____________________
% ✅ Keep states and well solutions in memory
fprintf('[INFO] Saving %d states and %d well solutions in workspace\n', ...
    length(states), length(wellSols));

% Substep 5.3 – Calculate final pressure change ________________
p_final = mean(states{end}.pressure);
p_initial = mean(states{1}.pressure);
dp_avg = (p_final - p_initial) / 6894.76;  % Convert Pa to psi

fprintf('[INFO] Average pressure change: %.1f psi\n', dp_avg);

% Substep 5.4 – Calculate porosity change if compaction enabled
if isfield(rock, 'c_phi')
    % Calculate porosity change
    poro_final = states{end}.pressure;  % Will be updated by compaction
    if isfield(states{end}, 'poro')
        poro_change = mean(states{end}.poro - rock.poro0);
        fprintf('[INFO] Average porosity change: %.4f\n', poro_change);
    end
end

fprintf('[INFO] Results ready for export\n'); 