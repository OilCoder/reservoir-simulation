function test_02_sim_scripts_setup_field()
% test_02_sim_scripts_setup_field - Test field units configuration system
%
% Tests setup_field.m, define_fluid.m, and create_schedule.m functions
% with field units (psi, ft, bbl/day) to ensure proper unit handling.
%
% Test functions:
%   - test_field_units_config
%   - test_setup_field_units
%   - test_fluid_definition_units
%   - test_schedule_creation_units
%
% Requires: MRST

fprintf('=== Testing Field Units Configuration ===\n');

% Run all test functions
test_field_units_config();
test_setup_field_units();
test_fluid_definition_units();
test_schedule_creation_units();

fprintf('\n✅ All field units tests PASSED!\n');
fprintf('System ready for field units simulation.\n');
fprintf('=== Field Units Test Complete ===\n');

end

function test_field_units_config()
% Test configuration loading with field units

fprintf('\n--- Test: Field Units Configuration ---\n');

try
    % Test configuration loading
    config_file = '../config/reservoir_config.yaml';
    config = util_read_config(config_file);
    
    % Verify field units are present
    assert(isfield(config, 'grid'), 'Grid section missing');
    assert(isfield(config, 'initial_conditions'), 'Initial conditions missing');
    assert(isfield(config, 'wells'), 'Wells section missing');
    
    % Check typical field unit values
    assert(config.initial_conditions.pressure > 1000, 'Pressure should be in psi (>1000)');
    assert(config.wells.producer_bhp > 1000, 'Producer BHP should be in psi (>1000)');
    assert(config.wells.injector_rate > 100, 'Injector rate should be in bbl/day (>100)');
    
    fprintf('Grid: %dx%d cells, %.1f x %.1f ft\n', ...
        config.grid.nx, config.grid.ny, config.grid.dx, config.grid.dy);
    fprintf('Initial pressure: %.0f psi\n', config.initial_conditions.pressure);
    fprintf('Producer BHP: %.0f psi\n', config.wells.producer_bhp);
    fprintf('Injector rate: %.0f bbl/day\n', config.wells.injector_rate);
    
    fprintf('[SUCCESS] Field units configuration test passed\n');
    
catch ME
    error('[ERROR] Field units configuration test failed: %s', ME.message);
end

end

function test_setup_field_units()
% Test setup_field function with field units

fprintf('\n--- Test: Setup Field with Field Units ---\n');

try
    % Initialize MRST
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
    config_file = '../config/reservoir_config.yaml';
    [G, rock, fluid] = setup_field(config_file);
    
    % Verify grid was created
    assert(isstruct(G), 'Grid must be a structure');
    assert(isfield(G, 'cartDims'), 'Grid must have cartDims');
    assert(isfield(G, 'cells'), 'Grid must have cells');
    
    % Verify rock properties
    assert(isstruct(rock), 'Rock must be a structure');
    assert(isfield(rock, 'poro'), 'Rock must have porosity');
    assert(isfield(rock, 'perm'), 'Rock must have permeability');
    assert(all(rock.poro > 0 & rock.poro < 1), 'Porosity must be between 0 and 1');
    assert(all(rock.perm > 0), 'Permeability must be positive');
    
    fprintf('Grid dimensions: %dx%d\n', G.cartDims(1), G.cartDims(2));
    fprintf('Porosity range: %.3f - %.3f\n', min(rock.poro), max(rock.poro));
    fprintf('Permeability range: %.1f - %.1f mD\n', ...
        min(rock.perm/milli/darcy), max(rock.perm/milli/darcy));
    
    fprintf('[SUCCESS] Setup field with field units test passed\n');
    
catch ME
    error('[ERROR] Setup field test failed: %s', ME.message);
end

end

function test_fluid_definition_units()
% Test fluid definition with field units

fprintf('\n--- Test: Fluid Definition Units ---\n');

try
    % Test fluid properties
    config_file = '../config/reservoir_config.yaml';
    fluid = define_fluid(config_file);
    
    % Verify fluid structure
    assert(isstruct(fluid), 'Fluid must be a structure');
    assert(isfield(fluid, 'krW'), 'Fluid must have water rel perm');
    assert(isfield(fluid, 'krO'), 'Fluid must have oil rel perm');
    assert(isfield(fluid, 'sWcon'), 'Fluid must have connate water sat');
    assert(isfield(fluid, 'sOres'), 'Fluid must have residual oil sat');
    
    % Check saturation limits
    assert(fluid.sWcon >= 0 && fluid.sWcon <= 1, 'Invalid connate water saturation');
    assert(fluid.sOres >= 0 && fluid.sOres <= 1, 'Invalid residual oil saturation');
    
    fprintf('Water saturation limits: %.2f - %.2f\n', fluid.sWcon, 1-fluid.sOres);
    
    fprintf('[SUCCESS] Fluid definition units test passed\n');
    
catch ME
    error('[ERROR] Fluid definition test failed: %s', ME.message);
end

end

function test_schedule_creation_units()
% Test schedule creation with field units

fprintf('\n--- Test: Schedule Creation Units ---\n');

try
    % Need grid, rock, and fluid first
    config_file = '../config/reservoir_config.yaml';
    [G, rock, fluid] = setup_field(config_file);
    fluid = define_fluid(config_file);
    
    % Test schedule creation
    schedule = create_schedule(G, rock, fluid, config_file);
    
    % Verify schedule structure
    assert(isstruct(schedule), 'Schedule must be a structure');
    assert(isfield(schedule, 'step'), 'Schedule must have timesteps');
    assert(isfield(schedule, 'control'), 'Schedule must have controls');
    assert(length(schedule.step.val) > 0, 'Schedule must have timesteps');
    assert(length(schedule.control) > 0, 'Schedule must have controls');
    
    % Check time units (should be in seconds internally)
    total_time_days = sum(schedule.step.val) / day;
    assert(total_time_days > 0, 'Total simulation time must be positive');
    assert(total_time_days < 10000, 'Total simulation time seems too large');
    
    fprintf('Simulation time: %.0f days\n', total_time_days);
    fprintf('Number of timesteps: %d\n', length(schedule.step.val));
    
    fprintf('[SUCCESS] Schedule creation units test passed\n');
    
catch ME
    error('[ERROR] Schedule creation test failed: %s', ME.message);
end

end 