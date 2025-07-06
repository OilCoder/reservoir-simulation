% test_config.m
% Test script to verify YAML configuration system
% Tests util_read_config and updated setup_field functions

clear all; close all; clc;

fprintf('=== Testing YAML Configuration System ===\n');

%% ----
%% Step 1 – Test configuration loading
%% ----

fprintf('\n--- Step 1: Configuration Loading ---\n');

try
    config_file = '../config/reservoir_config.yaml';
    config = util_read_config(config_file);
    
    fprintf('[SUCCESS] Configuration loaded successfully\n');
    
    % Display key configuration values
    fprintf('Grid: %dx%d cells, %.1f x %.1f ft\n', ...
        config.grid.nx, config.grid.ny, config.grid.dx, config.grid.dy);
    fprintf('Porosity: %.3f base, %.3f variation\n', ...
        config.porosity.base_value, config.porosity.variation_amplitude);
    fprintf('Permeability: %.1f mD base, %.1f mD variation\n', ...
        config.permeability.base_value, config.permeability.variation_amplitude);
    fprintf('Rock regions: %d defined\n', length(config.rock.regions));
    fprintf('Initial pressure: %.0f psi\n', config.initial_conditions.pressure);
    fprintf('Producer BHP: %.0f psi, Injector rate: %.0f bbl/day\n', ...
        config.wells.producer.target_bhp, config.wells.injector.target_rate);
    
catch ME
    fprintf('[ERROR] Configuration loading failed: %s\n', ME.message);
    return;
end

%% ----
%% Step 2 – Test setup_field with configuration
%% ----

fprintf('\n--- Step 2: Setup Field with Config ---\n');

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
    
    % Test setup_field with config
    [G, rock, fluid] = setup_field(config_file);
    
    fprintf('[SUCCESS] setup_field completed with configuration\n');
    
    % Verify results match configuration
    assert(G.cartDims(1) == config.grid.nx, 'Grid nx mismatch');
    assert(G.cartDims(2) == config.grid.ny, 'Grid ny mismatch');
    assert(G.cells.num == config.grid.nx * config.grid.ny, 'Total cells mismatch');
    
    fprintf('Grid verification: ✅ PASSED\n');
    
    % Check porosity range
    poro_min = min(rock.poro);
    poro_max = max(rock.poro);
    assert(poro_min >= config.porosity.min_value - 0.01, 'Porosity minimum violation');
    assert(poro_max <= config.porosity.max_value + 0.01, 'Porosity maximum violation');
    
    fprintf('Porosity range verification: ✅ PASSED\n');
    
    % Check permeability range
    perm_min = min(rock.perm) / (milli*darcy);
    perm_max = max(rock.perm) / (milli*darcy);
    assert(perm_min >= config.permeability.min_value - 1, 'Permeability minimum violation');
    assert(perm_max <= config.permeability.max_value + 1, 'Permeability maximum violation');
    
    fprintf('Permeability range verification: ✅ PASSED\n');
    
    % Check rock regions
    n_regions = length(unique(rock.regions));
    assert(n_regions == length(config.rock.regions), 'Rock regions count mismatch');
    
    fprintf('Rock regions verification: ✅ PASSED\n');
    
catch ME
    fprintf('[ERROR] setup_field test failed: %s\n', ME.message);
    return;
end

%% ----
%% Step 3 – Configuration modification test
%% ----

fprintf('\n--- Step 3: Configuration Modification Test ---\n');

try
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
    fprintf('[ERROR] Configuration modification test failed: %s\n', ME.message);
    % Clean up on error
    if exist(temp_config_file, 'file')
        delete(temp_config_file);
    end
    return;
end

%% ----
%% Step 4 – Summary and recommendations
%% ----

fprintf('\n--- Step 4: Summary ---\n');

fprintf('✅ All configuration tests PASSED!\n');
fprintf('\nConfiguration system features verified:\n');
fprintf('  • YAML file loading and parsing\n');
fprintf('  • Grid parameter configuration\n');
fprintf('  • Rock property configuration\n');
fprintf('  • Rock region configuration\n');
fprintf('  • Parameter validation and bounds checking\n');
fprintf('  • Configuration file modification support\n');

fprintf('\nUsage instructions:\n');
fprintf('  1. Edit config/reservoir_config.yaml to modify reservoir properties\n');
fprintf('  2. Run main_phase1.m - it will automatically use the configuration\n');
fprintf('  3. All simulation parameters are now centralized in the YAML file\n');

fprintf('\nKey configuration sections:\n');
fprintf('  • grid: Grid dimensions and cell sizes [ft]\n');
fprintf('  • porosity: Base value, variation, and limits [-]\n');
fprintf('  • permeability: Base value, variation, and limits [mD]\n');
fprintf('  • rock.regions: Rock types with property multipliers\n');
fprintf('  • fluid: Oil and water properties [cP, kg/m³]\n');
fprintf('  • wells: Producer and injector locations and controls [psi, bbl/day]\n');
fprintf('  • simulation: Time parameters and solver settings [days]\n');

fprintf('\n=== Configuration System Test Complete ===\n');

function write_temp_config(filename, config)
    % Write a simple temporary config file for testing
    fid = fopen(filename, 'w');
    
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
    fprintf(fid, '  regions:\n');
    fprintf(fid, '    - id: 1\n');
    fprintf(fid, '      porosity_multiplier: 1.0\n');
    fprintf(fid, '      permeability_multiplier: 1.0\n');
    fprintf(fid, '      compressibility: 4.5e-5\n');
    
    fclose(fid);
end 