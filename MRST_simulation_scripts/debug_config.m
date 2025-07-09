% debug_config.m
% Debug script to see what's in the config structure

fprintf('Loading config...\n');
config = util_read_config('../config/reservoir_config.yaml');

fprintf('Config structure:\n');
disp(config);

fprintf('\nGrid fields:\n');
if isfield(config, 'grid')
    disp(fieldnames(config.grid));
    if isfield(config.grid, 'nx')
        fprintf('nx value: %s\n', mat2str(config.grid.nx));
    end
else
    fprintf('No grid field found\n');
end 