% export_dataset.m
% Loop over simulation states, extract snapshots using extract_snapshot,
% save to data/raw/ directory, and update metadata.
% Requires: MRST

%% ----
%% Step 1 – Setup and validation
%% ----

% Substep 1.1 – Check required variables ______________________
required_vars = {'G', 'rock', 'states', 'schedule'};
for i = 1:length(required_vars)
    var_name = required_vars{i};
    if ~exist(var_name, 'var')
        error('[ERROR] Required variable %s not found. Run simulation first.', var_name);
    end
end

% Substep 1.2 – Create output directories ______________________
output_dir = 'data/raw';
if ~exist(output_dir, 'dir')
    mkdir(output_dir);
    fprintf('[INFO] Created output directory: %s\n', output_dir);
end

% Substep 1.3 – Initialize export counters ____________________
n_states = length(states);
n_exported = 0;
n_failed = 0;

fprintf('[INFO] Starting dataset export for %d timesteps...\n', n_states);

%% ----
%% Step 2 – Export loop
%% ----

% Substep 2.1 – Loop over all simulation states _______________
for i = 1:n_states
    try
        % 🔄 Extract snapshot data
        % Substep 2.2 – Extract snapshot data _________________________
        % 🔄 Get all required variables from simulation state
        [sigma_eff, phi, k, rock_id] = extract_snapshot(G, rock, states{i}, i);
        
        % Substep 2.3 – Create snapshot structure _____________________
        % 📊 Package all snapshot data
        snapshot = struct();
        snapshot.sigma_eff = sigma_eff;  % Effective stress [psia]
        snapshot.phi = phi;              % Porosity [-]
        snapshot.k = k;                  % Permeability [mD]
        snapshot.rock_id = rock_id;      % Rock region ID [-]
        snapshot.timestamp = i;          % Timestep number
        snapshot.time_days = sum(schedule.step.val(1:i)) / day;  % Time in days
        
        % Add pressure field if available
        if isfield(states{i}, 'pressure')
            snapshot.pressure = reshape(states{i}.pressure, [G.cartDims(1), G.cartDims(2)])' / psia;  % [psia]
        end
        
        % Substep 2.4 – Save snapshot file _____________________________
        % 💾 Write to data/raw/snap_i.mat
        try
            filename = sprintf('snap_%03d.mat', i);
            filepath = fullfile(output_dir, filename);
            save(filepath, 'snapshot');
            
            n_exported = n_exported + 1;
            fprintf('[INFO] Exported timestep %d/%d to %s\n', i, length(states), filename);
        catch
            fprintf('[ERROR] Failed to save snapshot for timestep %d\n', i);
        end
        
        % Progress reporting
        if mod(i, 10) == 0 || i == n_states
            fprintf('[INFO] Exported %d/%d snapshots (%.1f%%)\n', ...
                i, n_states, 100*i/n_states);
        end
        
    catch ME
        fprintf('[ERROR] Failed to export timestep %d: %s\n', i, ME.message);
        n_failed = n_failed + 1;
    end
end

%% ----
%% Step 3 – Create metadata file
%% ----

% Substep 3.1 – Compile dataset metadata _____________________
metadata = struct();
metadata.dataset_info.name = 'MRST Geomechanical Simulation';
metadata.dataset_info.description = 'Flow-compaction simulation results';
metadata.dataset_info.created = datestr(now, 'yyyy-mm-dd HH:MM:SS');
metadata.dataset_info.n_snapshots = n_exported;
metadata.dataset_info.n_failed = n_failed;

% Simulation parameters
metadata.simulation.total_time_days = sum(schedule.step.val) / day;
metadata.simulation.n_timesteps = length(schedule.step.val);
metadata.simulation.n_wells = length(schedule.control(1).W);

% Grid information
metadata.grid.dimensions = [G.cartDims(1), G.cartDims(2)];
metadata.grid.cell_size = [50, 50];  % meters, from setup_field.m
metadata.grid.total_cells = G.cells.num;

% Rock properties
metadata.rock.n_regions = length(unique(rock.regions));
metadata.rock.porosity_range = [min(rock.poro), max(rock.poro)];
metadata.rock.permeability_range_mD = [min(rock.perm), max(rock.perm)] / (milli*darcy);

% Fluid properties
metadata.fluid.phases = {'water', 'oil'};
metadata.fluid.viscosity_cp = [1.0, 2.0];  % From define_fluid.m

% File format
metadata.file_format.type = 'MATLAB .mat';
metadata.file_format.variables = {'sigma_eff', 'porosity', 'permeability', 'rock_id'};
metadata.file_format.dimensions = '20x20 matrices';

% Substep 3.2 – Save metadata file _____________________________
metadata_file = fullfile(output_dir, 'metadata.mat');
save(metadata_file, 'metadata');

%% ----
%% Step 4 – Create YAML metadata (optional)
%% ----

% Substep 4.1 – Create human-readable YAML metadata __________
yaml_content = {
    '# MRST Geomechanical Simulation Dataset'
    '# Generated automatically by export_dataset.m'
    ''
    'dataset_info:'
    sprintf('  name: "%s"', metadata.dataset_info.name)
    sprintf('  description: "%s"', metadata.dataset_info.description)
    sprintf('  created: "%s"', metadata.dataset_info.created)
    sprintf('  n_snapshots: %d', metadata.dataset_info.n_snapshots)
    sprintf('  n_failed: %d', metadata.dataset_info.n_failed)
    ''
    'simulation:'
    sprintf('  total_time_days: %.1f', metadata.simulation.total_time_days)
    sprintf('  n_timesteps: %d', metadata.simulation.n_timesteps)
    sprintf('  n_wells: %d', metadata.simulation.n_wells)
    ''
    'grid:'
    sprintf('  dimensions: [%d, %d]', metadata.grid.dimensions(1), metadata.grid.dimensions(2))
    sprintf('  cell_size: [%d, %d]', metadata.grid.cell_size(1), metadata.grid.cell_size(2))
    sprintf('  total_cells: %d', metadata.grid.total_cells)
    ''
    'rock:'
    sprintf('  n_regions: %d', metadata.rock.n_regions)
    sprintf('  porosity_range: [%.3f, %.3f]', metadata.rock.porosity_range(1), metadata.rock.porosity_range(2))
    sprintf('  permeability_range_mD: [%.1f, %.1f]', metadata.rock.permeability_range_mD(1), metadata.rock.permeability_range_mD(2))
    ''
    'fluid:'
    '  phases: [water, oil]'
    '  viscosity_cp: [1.0, 2.0]'
    ''
    'file_format:'
    '  type: "MATLAB .mat"'
    '  variables: [sigma_eff, porosity, permeability, rock_id]'
    '  dimensions: "20x20 matrices"'
    ''
    'units:'
    '  sigma_eff: Pa'
    '  porosity: dimensionless'
    '  permeability: m²'
    '  rock_id: dimensionless'
    '  time: days'
};

% Substep 4.2 – Write YAML file ________________________________
yaml_file = fullfile(output_dir, 'metadata.yaml');
fid = fopen(yaml_file, 'w');
if fid > 0
    for i = 1:length(yaml_content)
        fprintf(fid, '%s\n', yaml_content{i});
    end
    fclose(fid);
    fprintf('[INFO] YAML metadata saved to: %s\n', yaml_file);
else
    fprintf('[WARN] Could not create YAML metadata file\n');
end

%% ----
%% Step 5 – Final summary
%% ----

% Substep 5.1 – Calculate file sizes and statistics ____________
% 📊 Get directory information
file_list = dir(fullfile(output_dir, 'snap_*.mat'));
total_size_MB = sum([file_list.bytes]) / (1024^2);

% Substep 5.2 – Export summary _________________________________
fprintf('[INFO] Dataset export completed!\n');
fprintf('  Snapshots exported: %d/%d (%.1f%%)\n', n_exported, n_states, 100*n_exported/n_states);
fprintf('  Failed exports: %d\n', n_failed);
fprintf('  Total file size: %.1f MB\n', total_size_MB);
fprintf('  Average file size: %.1f MB\n', total_size_MB/n_exported);
fprintf('  Output directory: %s\n', output_dir);
fprintf('  Files created:\n');
fprintf('    - snap_001.mat to snap_%03d.mat\n', n_exported);
fprintf('    - metadata.mat\n');
fprintf('    - metadata.yaml\n');

% Substep 5.3 – Usage instructions _____________________________
fprintf('\n[INFO] Usage instructions:\n');
fprintf('  Load snapshot: data = load(''%s'');\n', fullfile(output_dir, 'snap_001.mat'));
fprintf('  Access data: sigma_eff = data.snapshot.sigma_eff;\n');
fprintf('  Load metadata: meta = load(''%s'');\n', fullfile(output_dir, 'metadata.mat'));

fprintf('\n[INFO] Dataset ready for ML training!\n'); 