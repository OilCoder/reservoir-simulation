% test_config.m
% Simple test to debug configuration reading

fprintf('Testing configuration parser...\n');

config = util_read_config('../config/reservoir_config.yaml');

fprintf('\nGrid configuration:\n');
fprintf('  nx = %d\n', config.grid.nx);
fprintf('  ny = %d\n', config.grid.ny);
fprintf('  dx = %.1f\n', config.grid.dx);
fprintf('  dy = %.1f\n', config.grid.dy);

fprintf('\nPorosity configuration:\n');
fprintf('  base_value = %.2f\n', config.porosity.base_value);
fprintf('  variation_amplitude = %.2f\n', config.porosity.variation_amplitude);

fprintf('\nFluid configuration:\n');
fprintf('  water_viscosity = %.1f\n', config.fluid.water_viscosity);
fprintf('  oil_viscosity = %.1f\n', config.fluid.oil_viscosity);

fprintf('\nTest completed.\n'); 