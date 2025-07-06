function test_01_sim_scripts_util_read_config()
% test_01_sim_scripts_util_read_config - Test YAML configuration system
%
% Tests util_read_config.m and configuration-based setup_field functions.
% Verifies YAML parsing, parameter validation, and configuration modification.
%
% Test functions:
%   - test_config_loading_basic
%   - test_setup_field_with_config
%   - test_config_modification
%
% Requires: MRST

fprintf('=== Testing YAML Configuration System ===\n');

% Run all test functions
test_config_loading_basic();
test_setup_field_with_config();
test_config_modification();

fprintf('\n✅ All configuration tests PASSED!\n');
fprintf('=== Configuration System Test Complete ===\n');

end

function test_config_loading_basic()
% Test basic configuration file loading and parsing

fprintf('\n--- Test: Configuration Loading ---\n');

try
    config_file = '../config/reservoir_config.yaml';
    config = util_read_config(config_file);
    
    % Basic structure validation
    assert(isstruct(config), 'Config must be a structure');
    assert(isfield(config, 'grid'), 'Config must have grid section');
    assert(isfield(config, 'porosity'), 'Config must have porosity section');
    assert(isfield(config, 'permeability'), 'Config must have permeability section');
    assert(isfield(config, 'wells'), 'Config must have wells section');
    
    % Display key configuration values
    fprintf('Grid: %dx%d cells, %.1f x %.1f ft\n', ...
        config.grid.nx, config.grid.ny, config.grid.dx, config.grid.dy);
    fprintf('Porosity: %.3f base, %.3f variation\n', ...
        config.porosity.base_value, config.porosity.variation_amplitude);
    fprintf('Permeability: %.1f mD base, %.1f mD variation\n', ...
        config.permeability.base_value, config.permeability.variation_amplitude);
    fprintf('Initial pressure: %.0f psi\n', config.initial_conditions.pressure);
    
    fprintf('[SUCCESS] Configuration loading test passed\n');
    
catch ME
    error('[ERROR] Configuration loading failed: %s', ME.message);
end

end

function test_setup_field_with_config()
% Test setup_field function with configuration

fprintf('\n--- Test: Setup Field with Config ---\n');

try
    % Initialize MRST (minimal setup for testing)
    current_dir = pwd;
    mrst_core_path = fullfile(fileparts(pwd), 'mrst', 'core');
    
    if exist(mrst_core_path, 'dir')
        addpath(mrst_core_path);
        cd(mrst_core_path);
        startup();
        cd(current_dir);
    end
    
    % Load config and test setup_field
    config_file = '../config/reservoir_config.yaml';
    config = util_read_config(config_file);
    [G, rock, fluid] = setup_field(config_file);
    
    % Verify results match configuration
    assert(G.cartDims(1) == config.grid.nx, 'Grid nx mismatch');
    assert(G.cartDims(2) == config.grid.ny, 'Grid ny mismatch');
    assert(G.cells.num == config.grid.nx * config.grid.ny, 'Total cells mismatch');
    
    % Check porosity range
    poro_min = min(rock.poro);
    poro_max = max(rock.poro);
    assert(poro_min >= config.porosity.min_value - 0.01, 'Porosity minimum violation');
    assert(poro_max <= config.porosity.max_value + 0.01, 'Porosity maximum violation');
    
    % Check permeability range
    perm_min = min(rock.perm) / (milli*darcy);
    perm_max = max(rock.perm) / (milli*darcy);
    assert(perm_min >= config.permeability.min_value - 1, 'Permeability minimum violation');
    assert(perm_max <= config.permeability.max_value + 1, 'Permeability maximum violation');
    
    % Check rock regions
    n_regions = length(unique(rock.regions));
    assert(n_regions >= 1, 'At least one rock region must exist');
    
    fprintf('[SUCCESS] Setup field with config test passed\n');
    
catch ME
    error('[ERROR] Setup field test failed: %s', ME.message);
end

end

function test_config_modification()
% Test configuration modification and temporary file handling

fprintf('\n--- Test: Configuration Modification ---\n');

try
    % Load base configuration
    config_file = '../config/reservoir_config.yaml';
    config = util_read_config(config_file);
    
    % Create a modified configuration
    config_modified = config;
    config_modified.grid.nx = 10;
    config_modified.grid.ny = 10;
    config_modified.porosity.base_value = 0.25;
    
    % Save modified config to temporary file
    temp_config_file = 'temp_config.yaml';
    write_temp_config(temp_config_file, config_modified);
    
    % Test with modified config
    [G_mod, rock_mod, fluid_mod] = setup_field(temp_config_file);
    
    % Verify modifications took effect
    assert(G_mod.cartDims(1) == 10, 'Modified grid nx not applied');
    assert(G_mod.cartDims(2) == 10, 'Modified grid ny not applied');
    assert(abs(mean(rock_mod.poro) - 0.25) < 0.05, 'Modified porosity not applied');
    
    fprintf('[SUCCESS] Configuration modification test passed\n');
    
    % Clean up temporary file
    if exist(temp_config_file, 'file')
        delete(temp_config_file);
    end
    
catch ME
    % Clean up on error
    if exist('temp_config_file', 'var') && exist(temp_config_file, 'file')
        delete(temp_config_file);
    end
    error('[ERROR] Configuration modification test failed: %s', ME.message);
end

end

function write_temp_config(filename, config)
% Write a simple temporary config file for testing

fid = fopen(filename, 'w');
if fid == -1
    error('Cannot create temporary config file: %s', filename);
end

fprintf(fid, 'grid:\n');
fprintf(fid, '  nx: %d\n', config.grid.nx);
fprintf(fid, '  ny: %d\n', config.grid.ny);
fprintf(fid, '  dx: %.1f\n', config.grid.dx);
fprintf(fid, '  dy: %.1f\n', config.grid.dy);

fprintf(fid, 'porosity:\n');
fprintf(fid, '  base_value: %.3f\n', config.porosity.base_value);
fprintf(fid, '  variation_amplitude: %.3f\n', config.porosity.variation_amplitude);
fprintf(fid, '  min_value: %.3f\n', config.porosity.min_value);
fprintf(fid, '  max_value: %.3f\n', config.porosity.max_value);

fprintf(fid, 'permeability:\n');
fprintf(fid, '  base_value: %.1f\n', config.permeability.base_value);
fprintf(fid, '  variation_amplitude: %.1f\n', config.permeability.variation_amplitude);
fprintf(fid, '  min_value: %.1f\n', config.permeability.min_value);
fprintf(fid, '  max_value: %.1f\n', config.permeability.max_value);

fprintf(fid, 'rock:\n');
fprintf(fid, '  compressibility: 4.5e-5\n');
fprintf(fid, '  n_regions: 3\n');

fprintf(fid, 'initial_conditions:\n');
fprintf(fid, '  pressure: 2900\n');
fprintf(fid, '  water_saturation: 0.2\n');

fprintf(fid, 'wells:\n');
fprintf(fid, '  injector_i: 5\n');
fprintf(fid, '  injector_j: 10\n');
fprintf(fid, '  producer_i: 15\n');
fprintf(fid, '  producer_j: 10\n');
fprintf(fid, '  injector_rate: 251\n');
fprintf(fid, '  producer_bhp: 2175\n');

fprintf(fid, 'simulation:\n');
fprintf(fid, '  total_time: 365\n');
fprintf(fid, '  num_timesteps: 50\n');

fprintf(fid, 'fluid:\n');
fprintf(fid, '  oil_density: 850\n');
fprintf(fid, '  water_density: 1000\n');
fprintf(fid, '  oil_viscosity: 2\n');
fprintf(fid, '  water_viscosity: 0.5\n');

fclose(fid);

end 