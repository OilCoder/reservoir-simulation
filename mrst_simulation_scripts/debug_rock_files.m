% DEBUG_ROCK_FILES - Check what's in rock property files

data_dir = '/workspaces/claudeclean/data/mrst_simulation/static';
rock_files = {'final_simulation_rock.mat', 'enhanced_rock_with_layers.mat', 'native_rock_properties.mat'};

for i = 1:length(rock_files)
    rock_file = fullfile(data_dir, rock_files{i});
    fprintf('\n=== Checking %s ===\n', rock_files{i});
    
    if exist(rock_file, 'file')
        try
            % Load and show variables
            vars = load(rock_file);
            var_names = fieldnames(vars);
            
            fprintf('Variables in file:\n');
            for j = 1:length(var_names)
                var_name = var_names{j};
                var_data = vars.(var_name);
                fprintf('  - %s: %s, size %s\n', var_name, class(var_data), mat2str(size(var_data)));
                
                % If it's a struct, show first few fields
                if isstruct(var_data) && ~isempty(var_data)
                    fields = fieldnames(var_data);
                    fprintf('    Fields: %s\n', strjoin(fields(1:min(5, length(fields))), ', '));
                end
            end
            
        catch ME
            fprintf('Error loading: %s\n', ME.message);
        end
    else
        fprintf('File does not exist\n');
    end
end