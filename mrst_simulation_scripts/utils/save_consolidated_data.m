function save_consolidated_data(file_type, script_name, varargin)
% SAVE_CONSOLIDATED_DATA - Save data to consolidated file structure
%
% Usage:
%   save_consolidated_data('grid', 's05', 'G', G, 'structural_data', structural_data, 'fault_system', fault_system)
%   save_consolidated_data('rock', 's08', 'rock', rock, 'layer_info', layer_info)
%   save_consolidated_data('fluid', 's11', 'fluid', fluid, 'pvt_tables', pvt_tables)
%
% INPUTS:
%   file_type   - String: 'grid', 'rock', 'fluid', 'state', 'wells', 'schedule'
%   script_name - String: Name of contributing script (e.g., 's05')
%   varargin    - Variable name-value pairs to save
%
% Policy Compliant: KISS principle, explicit validation, canon-first

    % Validate inputs (FAIL-FAST)
    valid_types = {'grid', 'rock', 'fluid', 'state', 'wells', 'schedule'};
    if ~ismember(file_type, valid_types)
        error('Invalid file_type: %s. Must be one of: %s', file_type, strjoin(valid_types, ', '));
    end
    
    if mod(length(varargin), 2) ~= 0
        error('Variable arguments must be name-value pairs');
    end
    
    % Create directory structure (absolute path from workspace root)
    % CANON-FIRST POLICY: Documentation specifies /workspace/data/mrst/ as authoritative location
    workspace_root = '/workspace';
    data_dir = fullfile(workspace_root, 'data', 'mrst');
    metadata_dir = fullfile(data_dir, 'metadata');
    
    if ~exist(data_dir, 'dir')
        mkdir(data_dir);
    end
    if ~exist(metadata_dir, 'dir')
        mkdir(metadata_dir);
    end
    
    % Prepare file path
    filename = sprintf('%s.mat', file_type);
    filepath = fullfile(data_dir, filename);
    
    % Save variables to consolidated file
    if mod(length(varargin), 2) ~= 0
        error('Variable arguments must be name-value pairs');
    end
    
    % Create data structure with variable names and values
    data_struct = struct();
    for i = 1:2:length(varargin)
        var_name = varargin{i};
        var_value = varargin{i+1};
        data_struct.(var_name) = var_value;
    end
    
    % Save the data structure (Octave compatible)
    save(filepath, '-struct', 'data_struct');
    
    % Update workflow metadata
    update_workflow_metadata(file_type, script_name, filepath, varargin(1:2:end));
    
    % Print success message
    variable_names = varargin(1:2:end);
    fprintf('   ✅ Saved to %s: %s\n', filename, strjoin(variable_names, ', '));
end

function update_workflow_metadata(file_type, script_name, filepath, variable_names)
% Update workflow.yaml with execution information

    workspace_root = '/workspace';
    metadata_file = fullfile(workspace_root, 'data', 'mrst', 'metadata', 'workflow.yaml');
    timestamp = datestr(now, 'yyyy-mm-dd HH:MM:SS');
    
    % Create basic metadata entry (simplified for initial implementation)
    metadata_entry = struct();
    metadata_entry.script = script_name;
    metadata_entry.file_type = file_type;
    metadata_entry.filepath = filepath;
    metadata_entry.variables = variable_names;
    metadata_entry.timestamp = timestamp;
    metadata_entry.status = 'completed';
    
    % For now, create a simple log file (can be enhanced to update YAML)
    workspace_root = '/workspace';
    log_file = fullfile(workspace_root, 'data', 'mrst', 'metadata', 'execution.log');
    log_entry = sprintf('[%s] %s -> %s.mat: %s\n', timestamp, script_name, file_type, strjoin(variable_names, ', '));
    
    % Append to log file
    fid = fopen(log_file, 'a');
    if fid > 0
        fprintf(fid, log_entry);
        fclose(fid);
    end
end