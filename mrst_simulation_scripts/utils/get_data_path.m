function data_path = get_data_path(category, subcategory, filename)
% GET_DATA_PATH - Get standardized data path for simulation data using by_type organization
%
% INPUT:
%   category - Main data category: 'static', 'dynamic', 'derived', 'visualizations', 'metadata'
%   subcategory - Subcategory within category (optional)
%   filename - Filename (optional)
% OUTPUT:
%   data_path - Full path to data file or directory
%
% EXAMPLES:
%   get_data_path('static') -> '/workspace/data/by_type/static'
%   get_data_path('static', 'geology') -> '.../by_type/static/geology'
%   get_data_path('dynamic', 'pressures', 'pressure_timeseries.nc') -> '.../by_type/dynamic/pressures/pressure_timeseries.nc'
%   get_data_path('metadata', 'control', 'session.mat') -> '.../by_type/metadata/control/session.mat'
%
% CANONICAL STRUCTURE:
%   /workspace/data/by_type/
%   ├── static/         (geology/, wells/, fluid_properties/, scal_properties/, field_boundaries/)
%   ├── dynamic/        (pressures/, saturations/, rates/, velocities/, compositions/)
%   ├── derived/        (recovery_factors/, sweep_efficiency/, connectivity/, economics/, analytics/)
%   ├── visualizations/ (3d_maps/, 2d_plots/, animations/, dashboards/)
%   └── metadata/       (control/, processing_logs/, version_control/, schema_definitions/)

    base_path = '/workspace/data/by_type';
    
    if nargin < 2 || isempty(subcategory)
        subcategory = '';
    end
    if nargin < 3 || isempty(filename)
        filename = '';
    end
    
    % Build path
    if isempty(subcategory) && isempty(filename)
        data_path = fullfile(base_path, category);
    elseif isempty(filename)
        data_path = fullfile(base_path, category, subcategory);
    elseif isempty(subcategory)
        data_path = fullfile(base_path, category, filename);
    else
        data_path = fullfile(base_path, category, subcategory, filename);
    end
    
    % Ensure directory exists for write operations
    if ~isempty(filename) && ~exist(fileparts(data_path), 'dir')
        mkdir(fileparts(data_path));
    end
end