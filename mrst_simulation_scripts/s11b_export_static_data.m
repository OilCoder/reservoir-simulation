function export_static_data(G, rock, schedule, base_dir)
% export_static_data - Export static reservoir data
%
% Exports rock regions, grid geometry, and well locations to the
% optimized data structure.
%
% Args:
%   G: MRST grid structure
%   rock: MRST rock structure
%   schedule: MRST schedule structure
%   base_dir: Base directory for data export
%
% Returns:
%   None (exports data to file)
%
% Requires: MRST

fprintf('[INFO] Exporting static data...\n');

%% ----
%% Step 1 – Prepare static data structure
%% ----

static_data = struct();

% Grid dimensions
nx = G.cartDims(1);
ny = G.cartDims(2);

%% ----
%% Step 2 – Export rock regions
%% ----

static_data.rock_id = reshape(rock.regions, [nx, ny])';  % [-]

%% ----
%% Step 3 – Export grid geometry
%% ----

static_data.grid_x = linspace(0, nx, nx+1);  % Grid x-coordinates [m]
static_data.grid_y = linspace(0, ny, ny+1);  % Grid y-coordinates [m]
static_data.cell_centers_x = 0.5 * (static_data.grid_x(1:end-1) + static_data.grid_x(2:end));
static_data.cell_centers_y = 0.5 * (static_data.grid_y(1:end-1) + static_data.grid_y(2:end));

%% ----
%% Step 4 – Export well locations
%% ----

well_data = struct();
n_wells = length(schedule.control(1).W);
well_data.well_names = cell(n_wells, 1);
well_data.well_i = zeros(n_wells, 1);
well_data.well_j = zeros(n_wells, 1);
well_data.well_types = cell(n_wells, 1);

for w = 1:n_wells
    well_data.well_names{w} = schedule.control(1).W(w).name;
    
    % Convert linear cell index to i,j coordinates
    cell_idx = schedule.control(1).W(w).cells(1);  % First cell of well
    [i, j] = ind2sub([nx, ny], cell_idx);
    well_data.well_i(w) = i;
    well_data.well_j(w) = j;
    
    % Determine well type from name or controls
    well_name = schedule.control(1).W(w).name;
    if ~isempty(strfind(well_name, 'INJ')) || strcmp(schedule.control(1).W(w).type, 'rate')
        well_data.well_types{w} = 'injector';
    else
        well_data.well_types{w} = 'producer';
    end
end

static_data.wells = well_data;

%% ----
%% Step 5 – Save static data
%% ----

static_file = fullfile(base_dir, 'static', 'static_data.mat');
save(static_file, 'static_data', '-v7');
fprintf('[INFO] Static data saved: %s\n', static_file);

end
