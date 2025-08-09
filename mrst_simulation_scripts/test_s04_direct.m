% TEST_S04_DIRECT - Direct test of s04 config loading

fprintf('Testing s04 config loading directly...\n');

try
    % Test the exact same loading as in s04
    full_config = read_yaml_config('config/structural_framework_config.yaml', 'silent', true);
    
    fprintf('Full config loaded successfully!\n');
    fprintf('Top-level fields in full_config:\n');
    if isstruct(full_config)
        fields = fieldnames(full_config);
        for i = 1:length(fields)
            fprintf('  - %s (type: %s)\n', fields{i}, class(full_config.(fields{i})));
        end
        
        % Try to extract structural_framework
        if isfield(full_config, 'structural_framework')
            config = full_config.structural_framework;
            fprintf('\n✅ Successfully extracted structural_framework\n');
            
            % Check anticline
            if isfield(config, 'anticline')
                fprintf('✅ anticline found in config\n');
                
                % Check axis_trend and list all anticline fields
                fprintf('Anticline fields:\n');
                anticline_fields = fieldnames(config.anticline);
                for j = 1:length(anticline_fields)
                    fprintf('    - %s\n', anticline_fields{j});
                end
                
                if isfield(config.anticline, 'axis_trend')
                    fprintf('✅ axis_trend found: %f degrees\n', config.anticline.axis_trend);
                else
                    fprintf('❌ axis_trend NOT found in anticline\n');
                end
            else
                fprintf('❌ anticline NOT found in config\n');
            end
        else
            fprintf('❌ structural_framework NOT found in full_config\n');
        end
    else
        fprintf('❌ full_config is not a struct! Type: %s\n', class(full_config));
    end
    
catch ME
    fprintf('❌ ERROR: %s\n', ME.message);
    fprintf('Stack:\n');
    for i = 1:length(ME.stack)
        fprintf('  %s:%d\n', ME.stack(i).name, ME.stack(i).line);
    end
end