function s11d_export_metadata(G, schedule, temporal_data, base_dir)
% s11d_export_metadata - Export comprehensive dataset metadata
%
% Creates comprehensive metadata with dataset information, simulation
% parameters, data structure details, and optimization information.
%
% Args:
%   G: MRST grid structure
%   schedule: MRST schedule structure
%   temporal_data: Temporal data structure
%   n_wells: Number of wells
%   fields_file: Path to fields file for size calculation
%   base_dir: Base directory for data export
%
% Returns:
%   None (exports metadata to file)
%
% Requires: MRST

fprintf('[INFO] Creating metadata...\n');

%% ----
%% Step 1 – Create metadata structure
%% ----

metadata = struct();

% Grid dimensions
nx = G.cartDims(1);
ny = G.cartDims(2);
nz = G.cartDims(3);
n_steps = length(temporal_data.time_days);

%% ----
%% Step 2 – Dataset information
%% ----

metadata.dataset_info.name = 'MRST Geomechanical Simulation - Optimized';
metadata.dataset_info.description = 'Flow-compaction simulation with optimized data structure';
metadata.dataset_info.created = datestr(now, 'yyyy-mm-dd HH:MM:SS');
metadata.dataset_info.version = '2.0';
metadata.dataset_info.format = 'Optimized with deduplication';

%% ----
%% Step 3 – Simulation parameters
%% ----

metadata.simulation.total_time_days = max(temporal_data.time_days);
metadata.simulation.n_timesteps = n_steps;
metadata.simulation.n_wells = length(schedule.control(1).W);
metadata.simulation.grid_size = [nx, ny, nz];
metadata.grid_dimensions = [nx, ny, nz];  % For compatibility with data loader
metadata.simulation.is_3d = (nz > 1);  % Flag for 3D simulation

%% ----
%% Step 4 – Data structure information
%% ----

metadata.structure.folders = {
    'initial/ - Initial reservoir conditions (t=0)'
    'static/ - Data that never changes'
    'dynamic/fields/ - 3D/4D time-dependent fields'
    'dynamic/wells/ - Well operational data [time, well]'
    'temporal/ - Time vectors and schedules'
    'metadata/ - Dataset information'
};

if nz > 1
    metadata.structure.variables = {
        'pressure: [time, z, y, x] in psia'
        'sw: [time, z, y, x] water saturation'
        'phi: [time, z, y, x] porosity'
        'k: [time, z, y, x] permeability in mD'
        'sigma_eff: [time, z, y, x] effective stress in psia'
        'rock_id: [z, y, x] rock region IDs'
        'depth: [z, y, x] cell depth in ft'
    };
else
    metadata.structure.variables = {
        'pressure: [time, y, x] in psia'
        'sw: [time, y, x] water saturation'
        'phi: [time, y, x] porosity'
        'k: [time, y, x] permeability in mD'
        'sigma_eff: [time, y, x] effective stress in psia'
        'rock_id: [y, x] rock region IDs'
    };
end

%% ----
%% Step 5 – File sizes and optimization
%% ----

fields_file = fullfile(base_dir, 'simulation_data', 'dynamic', 'fields', 'field_arrays.mat');
if exist(fields_file, 'file')
    fields_info = dir(fields_file);
    total_size_MB = fields_info.bytes / (1024^2);
else
    total_size_MB = 0;
end

metadata.optimization.total_size_MB = total_size_MB;
metadata.optimization.deduplication = 'Rock regions, time vectors, and grid stored once';
metadata.optimization.format = '3D arrays for efficient time series analysis';

%% ----
%% Step 6 – Units and conventions
%% ----

metadata.units.pressure = 'psia';
metadata.units.permeability = 'mD';
metadata.units.porosity = 'dimensionless';
metadata.units.stress = 'psia';
metadata.units.time = 'days';
metadata.units.rates = 'm³/day';

if nz > 1
    metadata.conventions.array_order = '[time, z, y, x] for Python compatibility';
else
    metadata.conventions.array_order = '[time, y, x] for Python compatibility';
end
metadata.conventions.coordinate_system = 'Origin at (0,0,0), Z increases with depth';
metadata.conventions.well_indexing = 'Zero-based in Python, one-based in MATLAB';

%% ----
%% Step 7 – Save metadata
%% ----

metadata_file = fullfile(base_dir, 'simulation_data', 'metadata', 'metadata.mat');
save(metadata_file, 'metadata', '-v7');
fprintf('[INFO] Metadata saved: %s\n', metadata_file);

%% ----
%% Step 8 – Create YAML metadata for human readability
%% ----

yaml_content = {
    '# MRST Geomechanical Simulation Dataset - Optimized Structure'
    '# Generated automatically by export_optimized_dataset.m'
    ''
    'dataset_info:'
    sprintf('  name: "%s"', metadata.dataset_info.name)
    sprintf('  description: "%s"', metadata.dataset_info.description)
    sprintf('  created: "%s"', metadata.dataset_info.created)
    sprintf('  version: "%s"', metadata.dataset_info.version)
    ''
    'structure:'
    '  folders:'
    '    initial/: Initial reservoir conditions (t=0)'
    '    static/: Data that never changes'
    '    dynamic/fields/: 3D time-dependent fields [time, y, x]'
    '    dynamic/wells/: Well operational data [time, well]'
    '    temporal/: Time vectors and schedules'
    '    metadata/: Dataset information'
    ''
    'optimization:'
    sprintf('  total_size_MB: %.1f', metadata.optimization.total_size_MB)
    '  deduplication: "Rock regions, time, grid stored once"'
    '  format: "3D arrays for efficient analysis"'
    ''
    'python_compatibility:'
    '  array_order: "[time, y, x]"'
    '  indexing: "Zero-based"'
    '  file_format: "Octave text .mat (readable by Python)"'
    ''
    'units:'
    '  pressure: psia'
    '  permeability: mD'
    '  porosity: dimensionless'
    '  stress: psia'
    '  time: days'
    '  rates: m³/day'
    ''
    'usage:'
    '  python: "import scipy.io; data = scipy.io.loadmat(''file.mat'')"'
    '  matlab: "load(''file.mat'')"'
    '  octave: "load(''file.mat'')"'
};

% Write YAML file
yaml_file = fullfile(base_dir, 'metadata', 'metadata.yaml');
fid = fopen(yaml_file, 'w');
if fid > 0
    for i = 1:length(yaml_content)
        fprintf(fid, '%s\n', yaml_content{i});
    end
    fclose(fid);
    fprintf('[INFO] YAML metadata saved: %s\n', yaml_file);
end

end
