% test_field_units.m
% Simple test to verify field units configuration

clear all; close all; clc;

fprintf('=== Testing Field Units Configuration ===\n');

try
    % Test configuration loading
    config_file = '../config/reservoir_config_simple.yaml';
    config = util_read_config(config_file);
    
    fprintf('[SUCCESS] Configuration loaded\n');
    fprintf('Grid: %dx%d cells, %.1f x %.1f ft\n', ...
        config.grid.nx, config.grid.ny, config.grid.dx, config.grid.dy);
    fprintf('Initial pressure: %.0f psi\n', config.initial_conditions.pressure);
    fprintf('Producer BHP: %.0f psi\n', config.wells.producer_bhp);
    fprintf('Injector rate: %.0f bbl/day\n', config.wells.injector_rate);
    
    % Test MRST initialization
    current_dir = pwd;
    mrst_core_path = fullfile(fileparts(pwd), 'mrst', 'core');
    
    if exist(mrst_core_path, 'dir')
        addpath(mrst_core_path);
        cd(mrst_core_path);
        startup();
        cd(current_dir);
        fprintf('[SUCCESS] MRST initialized\n');
    else
        fprintf('[WARN] MRST not found, skipping grid test\n');
        return;
    end
    
    % Test setup_field with field units
    [G, rock, fluid] = setup_field(config_file);
    
    fprintf('[SUCCESS] setup_field completed\n');
    fprintf('Grid dimensions: %dx%d\n', G.cartDims(1), G.cartDims(2));
    fprintf('Porosity range: %.3f - %.3f\n', min(rock.poro), max(rock.poro));
    fprintf('Permeability range: %.1f - %.1f mD\n', ...
        min(rock.perm/milli/darcy), max(rock.perm/milli/darcy));
    
    % Test fluid properties
    fluid = define_fluid(config_file);
    fprintf('[SUCCESS] define_fluid completed\n');
    fprintf('Water saturation limits: %.2f - %.2f\n', fluid.sWcon, 1-fluid.sOres);
    
    % Test schedule creation
    schedule = create_schedule(G, rock, fluid, config_file);
    fprintf('[SUCCESS] create_schedule completed\n');
    fprintf('Simulation time: %.0f days\n', sum(schedule.step.val)/day);
    fprintf('Number of timesteps: %d\n', length(schedule.step.val));
    
    fprintf('\n✅ All field units tests PASSED!\n');
    fprintf('System ready for field units simulation.\n');
    
catch ME
    fprintf('[ERROR] Test failed: %s\n', ME.message);
end

fprintf('\n=== Field Units Test Complete ===\n'); 