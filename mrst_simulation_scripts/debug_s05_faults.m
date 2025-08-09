% DEBUG_S05_FAULTS - Debug fault configuration parsing

fprintf('Debugging fault configuration...\n');

try
    % Load fault configuration
    config = read_yaml_config('config/fault_config.yaml', 'silent', true);
    
    fprintf('Fault config loaded successfully!\n');
    fprintf('Top-level fields:\n');
    if isstruct(config)
        fields = fieldnames(config);
        for i = 1:length(fields)
            fprintf('  - %s (type: %s)\n', fields{i}, class(config.(fields{i})));
        end
        
        % Check fault_system structure
        if isfield(config, 'fault_system')
            fprintf('\nfault_system structure:\n');
            fs = config.fault_system;
            if isstruct(fs)
                fs_fields = fieldnames(fs);
                for i = 1:length(fs_fields)
                    fprintf('  - %s (type: %s)\n', fs_fields{i}, class(fs.(fs_fields{i})));
                end
                
                % Check faults list
                if isfield(fs, 'faults')
                    fprintf('\nfaults data:\n');
                    faults_data = fs.faults;
                    fprintf('  Type: %s\n', class(faults_data));
                    
                    if iscell(faults_data)
                        fprintf('  Is cell array with %d elements\n', length(faults_data));
                        if ~isempty(faults_data)
                            fprintf('  First element type: %s\n', class(faults_data{1}));
                        end
                    elseif isstruct(faults_data)
                        fprintf('  Is struct with fields:\n');
                        fault_fields = fieldnames(faults_data);
                        for j = 1:length(fault_fields)
                            fprintf('    - %s (type: %s)\n', fault_fields{j}, class(faults_data.(fault_fields{j})));
                        end
                    else
                        fprintf('  Unknown type!\n');
                        disp(faults_data);
                    end
                end
            end
        end
    end
    
catch ME
    fprintf('ERROR: %s\n', ME.message);
    for i = 1:length(ME.stack)
        fprintf('  %s:%d\n', ME.stack(i).name, ME.stack(i).line);
    end
end