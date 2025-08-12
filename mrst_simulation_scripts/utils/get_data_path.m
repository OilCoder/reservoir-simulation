function data_path = get_data_path(category, subcategory, filename)
% GET_DATA_PATH - Get standardized data path for simulation data
%
% INPUT:
%   category - 'static', 'dynamic', or 'results'
%   subcategory - subcategory within category (optional)
%   filename - filename (optional)
% OUTPUT:
%   data_path - Full path to data file or directory
%
% EXAMPLES:
%   get_data_path('static') -> '/workspaces/claudeclean/data/simulation_data/static'
%   get_data_path('static', 'grid') -> '.../static/grid'
%   get_data_path('results', '', 'analysis.mat') -> '.../results/analysis.mat'

    base_path = '/workspaces/claudeclean/data/simulation_data';
    
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