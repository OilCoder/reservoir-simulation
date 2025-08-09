% DEBUG_S04_CONFIG - Debug structural framework configuration parsing

script_path = fileparts(mfilename('fullpath'));
config_path = fullfile(script_path, 'config', 'structural_framework_config.yaml');

fprintf('Debug s04 structural framework config...\n');
fprintf('Config file: %s\n', config_path);

try
    % Load configuration
    config = read_yaml_config(config_path, 'silent', true);
    
    fprintf('Top-level fields in config:\n');
    if isstruct(config)
        fields = fieldnames(config);
        for i = 1:length(fields)
            fprintf('  - %s (type: %s)\n', fields{i}, class(config.(fields{i})));
        end
        
        % Check structural_framework structure
        if isfield(config, 'structural_framework')
            fprintf('\nstructural_framework structure:\n');
            sf = config.structural_framework;
            if isstruct(sf)
                sf_fields = fieldnames(sf);
                for i = 1:length(sf_fields)
                    fprintf('  - %s (type: %s)\n', sf_fields{i}, class(sf.(sf_fields{i})));
                end
                
                % Check anticline inside structural_framework
                if isfield(sf, 'anticline')
                    fprintf('\n  anticline structure inside structural_framework:\n');
                    anticline = sf.anticline;
                    if isstruct(anticline)
                        anticline_fields = fieldnames(anticline);
                        for i = 1:length(anticline_fields)
                            fprintf('    - %s: %s (type: %s)\n', anticline_fields{i}, ...
                                mat2str(anticline.(anticline_fields{i})), class(anticline.(anticline_fields{i})));
                        end
                    end
                end
            end
        elseif isfield(config, 'anticline')
            fprintf('\nanticline structure:\n');
            anticline = config.anticline;
            if isstruct(anticline)
                anticline_fields = fieldnames(anticline);
                for i = 1:length(anticline_fields)
                    fprintf('  - %s: %s (type: %s)\n', anticline_fields{i}, ...
                        mat2str(anticline.(anticline_fields{i})), class(anticline.(anticline_fields{i})));
                end
                
                % Check if axis_trend exists
                if isfield(anticline, 'axis_trend')
                    fprintf('\n✅ axis_trend found: %f degrees\n', anticline.axis_trend);
                else
                    fprintf('\n❌ axis_trend NOT found in anticline structure!\n');
                    fprintf('Available fields: %s\n', strjoin(anticline_fields, ', '));
                end
            else
                fprintf('ERROR: anticline is not a struct! Type: %s\n', class(anticline));
            end
        else
            fprintf('ERROR: anticline field not found in config!\n');
        end
    else
        fprintf('ERROR: config is not a struct! Type: %s\n', class(config));
    end
    
catch ME
    fprintf('ERROR: %s\n', ME.message);
    fprintf('Stack:\n');
    for i = 1:length(ME.stack)
        fprintf('  %s:%d\n', ME.stack(i).name, ME.stack(i).line);
    end
end