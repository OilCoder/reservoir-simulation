% debug_config.m
% Debug script to check YAML parsing

clear all; close all; clc;

fprintf('=== Debug YAML Configuration Parsing ===\n');

config_file = '../config/reservoir_config.yaml';
config = util_read_config(config_file);

fprintf('\nConfig structure:\n');
disp(config);

fprintf('\nRock section:\n');
if isfield(config, 'rock')
    disp(config.rock);
    
    fprintf('\nRock regions:\n');
    if isfield(config.rock, 'regions')
        regions = config.rock.regions;
        fprintf('Type: %s\n', class(regions));
        fprintf('Length: %d\n', length(regions));
        
        if iscell(regions)
            fprintf('Cell array contents:\n');
            for i = 1:length(regions)
                fprintf('  regions{%d}:\n', i);
                disp(regions{i});
            end
        elseif isstruct(regions)
            fprintf('Struct array contents:\n');
            for i = 1:length(regions)
                fprintf('  regions(%d):\n', i);
                disp(regions(i));
            end
        else
            fprintf('Other type contents:\n');
            disp(regions);
        end
    else
        fprintf('No regions field found\n');
    end
else
    fprintf('No rock field found\n');
end

fprintf('\n=== Debug Complete ===\n'); 