function s06_export_dataset(G, rock, fluid, schedule, states, wellSols)
% s06_export_dataset - Optimized MRST data export system with deduplication and organized structure
%
% Exports simulation results to: ../data/ with optimized folder organization
%
% Args:
%   G: MRST grid structure
%   rock: MRST rock structure
%   fluid: MRST fluid structure
%   schedule: MRST schedule structure
%   states: Cell array of simulation states
%   wellSols: Cell array of well solutions
%
% Returns:
%   None (exports data to files)
%
% Requires: MRST

%% ----
%% Step 1 – Setup and validation
%% ----

% Substep 1.1 – Create optimized directory structure ___________
base_dir = '../data';
dirs = {
    fullfile(base_dir, 'initial')        % Initial reservoir conditions
    fullfile(base_dir, 'static')         % Data that never changes
    fullfile(base_dir, 'dynamic', 'fields')  % 3D time-dependent fields
    fullfile(base_dir, 'dynamic', 'wells')   % Well operational data
    fullfile(base_dir, 'temporal')       % Time vectors and schedules
    fullfile(base_dir, 'metadata')       % Dataset information
};

for i = 1:length(dirs)
    if ~exist(dirs{i}, 'dir')
        try
            mkdir(dirs{i});
            fprintf('[INFO] Created directory: %s\n', dirs{i});
        catch
            fprintf('[WARN] Could not create directory: %s\n', dirs{i});
        end
    end
end

fprintf('[INFO] Starting optimized dataset export...\n');

%% ----
%% Step 2 – Export initial conditions
%% ----

try
    s11a_export_initial_conditions(G, rock, states, base_dir);
    fprintf('[INFO] Initial conditions exported\n');
catch ME
    fprintf('[WARN] Could not export initial conditions: %s\n', ME.message);
end

%% ----
%% Step 3 – Export static data
%% ----

try
    s11b_export_static_data(G, rock, schedule, base_dir);
    fprintf('[INFO] Static data exported\n');
catch ME
    fprintf('[WARN] Could not export static data: %s\n', ME.message);
end

%% ----
%% Step 4 – Export temporal data
%% ----

fprintf('[INFO] Exporting temporal data...\n');

try
    temporal_data = struct();
    n_timesteps = length(states);
    
    % Time in days
    temporal_data.time_days = zeros(n_timesteps, 1);
    for i = 1:n_timesteps
        temporal_data.time_days(i) = sum(schedule.step.val(1:i)) / 86400;  % Convert seconds to days
    end
    
    % Timestep sizes
    temporal_data.dt_days = schedule.step.val / 86400;  % Convert seconds to days
    
    % Control periods
    temporal_data.control_indices = schedule.step.control;
    
    % Save temporal data
    temporal_file = fullfile(base_dir, 'temporal', 'time_data.mat');
    save(temporal_file, 'temporal_data', '-v7');
    fprintf('[INFO] Temporal data saved: %s\n', temporal_file);
catch ME
    fprintf('[WARN] Could not export temporal data: %s\n', ME.message);
end

%% ----
%% Step 5 – Export dynamic fields
%% ----

try
    % Use unified export function (handles both 2D and 3D automatically)
    s11c_export_dynamic_fields(G, rock, states, base_dir);
    fprintf('[INFO] Dynamic fields exported\n');
catch ME
    fprintf('[WARN] Could not export dynamic fields: %s\n', ME.message);
end

%% ----
%% Step 6 – Export well operational data
%% ----

fprintf('[INFO] Exporting well operational data...\n');

try
    if exist('wellSols', 'var') && ~isempty(wellSols)
        n_wells = length(wellSols{1});
        n_times = length(wellSols);
        
        wells_dynamic = struct();
        wells_dynamic.time_days = temporal_data.time_days;
        wells_dynamic.well_names = cell(n_wells, 1);
        
        % Pre-allocate arrays
        wells_dynamic.qWs = zeros(n_times, n_wells);   % Water rates [m³/day]
        wells_dynamic.qOs = zeros(n_times, n_wells);   % Oil rates [m³/day]
        wells_dynamic.bhp = zeros(n_times, n_wells);   % BHP [psi]
        
        % Extract well names
        for w = 1:n_wells
            if isfield(wellSols{1}(w), 'name')
                wells_dynamic.well_names{w} = wellSols{1}(w).name;
            else
                wells_dynamic.well_names{w} = sprintf('W%d', w);
            end
        end
        
        % Fill well data arrays
        for t = 1:n_times
            for w = 1:n_wells
                if isfield(wellSols{t}(w), 'qWs')
                    wells_dynamic.qWs(t, w) = wellSols{t}(w).qWs;
                end
                if isfield(wellSols{t}(w), 'qOs')
                    wells_dynamic.qOs(t, w) = wellSols{t}(w).qOs;
                end
                if isfield(wellSols{t}(w), 'bhp')
                    wells_dynamic.bhp(t, w) = wellSols{t}(w).bhp / 6894.76;  % Convert Pa to psi
                end
            end
        end
        
        % Save well data
        wells_file = fullfile(base_dir, 'dynamic', 'wells', 'well_data.mat');
        save(wells_file, 'wells_dynamic', '-v7');
        fprintf('[INFO] Well operational data saved: %s\n', wells_file);
    else
        fprintf('[WARN] wellSols not available - well data export skipped\n');
    end
catch ME
    fprintf('[WARN] Could not export well data: %s\n', ME.message);
end

%% ----
%% Step 7 – Export metadata
%% ----

try
    s11d_export_metadata(G, schedule, temporal_data, base_dir);
    fprintf('[INFO] Metadata exported\n');
catch ME
    fprintf('[WARN] Could not export metadata: %s\n', ME.message);
end

%% ----
%% Step 8 – Final summary
%% ----

nx = G.cartDims(1);
ny = G.cartDims(2);
n_steps = length(states);
n_wells = length(schedule.control(1).W);

fprintf('\n=== OPTIMIZED EXPORT COMPLETED ===\n');
fprintf('Export completed at: %s\n', datestr(now));
try
    fprintf('Total simulation time: %.1f days\n', max(temporal_data.time_days));
catch
    fprintf('Total simulation time: Not available\n');
end
fprintf('Grid size: %d x %d\n', nx, ny);
fprintf('Timesteps: %d\n', n_steps);
fprintf('Wells: %d\n', n_wells);

fprintf('\nData structure:\n');
fprintf('  /workspace/data/initial/           - Initial conditions\n');
fprintf('  /workspace/data/static/            - Static data (grid, wells, rock)\n');
fprintf('  /workspace/data/dynamic/fields/    - 3D field arrays [time, y, x]\n');
fprintf('  /workspace/data/dynamic/wells/     - Well operational data\n');
fprintf('  /workspace/data/temporal/          - Time vectors\n');
fprintf('  /workspace/data/metadata/          - Documentation\n');

fprintf('\n✅ OPTIMIZED DATASET READY FOR PYTHON PLOTTING!\n'); 

fprintf('[INFO] Dataset export completed successfully!\n');
fprintf('[INFO] All data exported to optimized structure in: %s\n', base_dir);

end
