% DEBUG_YAML_PARSING - Test YAML parser with wells config
% This script tests the YAML parser to understand why s16 fails

% Load the wells config
script_path = fileparts(mfilename('fullpath'));
config_path = fullfile(script_path, 'config', 'wells_config.yaml');

fprintf('Testing YAML parser...\n');
fprintf('Config file: %s\n', config_path);
fprintf('File exists: %s\n', mat2str(exist(config_path, 'file')));

try
    % Test the YAML parser
    config = read_yaml_config(config_path, 'silent', true);
    
    fprintf('YAML loaded successfully!\n');
    fprintf('Top-level fields:\n');
    if isstruct(config)
        field_names = fieldnames(config);
        for i = 1:length(field_names)
            fprintf('  - %s (type: %s)\n', field_names{i}, class(config.(field_names{i})));
        end
        
        % Check wells_system structure
        if isfield(config, 'wells_system')
            fprintf('\nwells_system fields:\n');
            ws = config.wells_system;
            if isstruct(ws)
                ws_fields = fieldnames(ws);
                for i = 1:length(ws_fields)
                    fprintf('  - %s (type: %s)\n', ws_fields{i}, class(ws.(ws_fields{i})));
                end
                
                % Check producer_wells structure
                if isfield(ws, 'producer_wells')
                    fprintf('\nproducer_wells structure:\n');
                    pw = ws.producer_wells;
                    fprintf('  Type: %s\n', class(pw));
                    
                    if isstruct(pw)
                        pw_fields = fieldnames(pw);
                        fprintf('  Well names found: %d\n', length(pw_fields));
                        for i = 1:min(3, length(pw_fields))  % Show first 3 wells
                            fprintf('    - %s (type: %s)\n', pw_fields{i}, class(pw.(pw_fields{i})));
                            
                            % Show first well details
                            if i == 1 && isstruct(pw.(pw_fields{i}))
                                well_fields = fieldnames(pw.(pw_fields{i}));
                                fprintf('      Properties: ');
                                for j = 1:min(5, length(well_fields))
                                    fprintf('%s ', well_fields{j});
                                end
                                fprintf('\n');
                            end
                        end
                    else
                        fprintf('  ERROR: producer_wells is not a struct!\n');
                        disp(pw);
                    end
                else
                    fprintf('  ERROR: producer_wells field not found!\n');
                end
            else
                fprintf('  ERROR: wells_system is not a struct!\n');
                fprintf('  Type: %s\n', class(ws));
                disp(ws);
            end
        else
            fprintf('  ERROR: wells_system field not found!\n');
        end
    else
        fprintf('ERROR: Config is not a struct!\n');
        fprintf('Type: %s\n', class(config));
        disp(config);
    end
    
catch ME
    fprintf('ERROR loading YAML: %s\n', ME.message);
    fprintf('Identifier: %s\n', ME.identifier);
    fprintf('Stack:\n');
    for i = 1:length(ME.stack)
        fprintf('  %s at line %d\n', ME.stack(i).name, ME.stack(i).line);
    end
end