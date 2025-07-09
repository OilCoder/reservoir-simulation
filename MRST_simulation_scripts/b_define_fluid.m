function fluid = b_define_fluid(config_file)
% b_define_fluid - Create MRST fluid structure from configuration
%
% Creates two-phase oil-water fluid with properties from configuration.
% Uses MRST initSimpleFluid function with realistic relative permeability curves.
%
% Args:
%   config_file: Path to YAML configuration file
%
% Returns:
%   fluid: MRST fluid structure with oil-water properties
%
% Requires: MRST

%% ----
%% Step 1 – Load configuration
%% ----

% Substep 1.1 – Read configuration file ________________________
config = util_read_config(config_file);

fprintf('[INFO] Creating two-phase oil-water fluid\n');

%% ----
%% Step 2 – Create MRST fluid from config
%% ----

% Substep 2.1 – Define fluid properties from config _____________
mu_w = config.fluid.water_viscosity * 1e-3;  % cP to Pa·s
mu_o = config.fluid.oil_viscosity * 1e-3;    % cP to Pa·s
rho_w = config.fluid.water_density;  % kg/m³
rho_o = config.fluid.oil_density;    % kg/m³

fluid = initSimpleFluid('mu', [mu_w, mu_o], 'rho', [rho_w, rho_o], 'n', [2, 2]);
fluid.mu = [mu_w, mu_o];
fluid.rho = [rho_w, rho_o];

fprintf('[INFO] Fluid properties set:\n');
fprintf('  Water: μ = %.1f cP, ρ = %.0f kg/m³\n', config.fluid.water_viscosity, config.fluid.water_density);
fprintf('  Oil: μ = %.1f cP, ρ = %.0f kg/m³\n', config.fluid.oil_viscosity, config.fluid.oil_density);

%% ----
%% Step 3 – Set saturation endpoints from config
%% ----

fluid.sWcon = config.fluid.connate_water_saturation;
fluid.sOres = config.fluid.residual_oil_saturation;
fluid.sWcrit = fluid.sWcon;
fluid.sOcrit = fluid.sOres;

fprintf('  Saturation limits: Sw = %.2f - %.2f\n', fluid.sWcon, 1-fluid.sOres);

%% ----
%% Step 4 – Generate relative permeability curves from config
%% ----

% Extract kr curve parameters from config
swc = config.fluid.relative_permeability.water.connate_saturation;
sor = config.fluid.relative_permeability.oil.residual_saturation;
krw_max = config.fluid.relative_permeability.water.endpoint_krmax;
kro_max = config.fluid.relative_permeability.oil.endpoint_krmax;
nw = config.fluid.relative_permeability.water.corey_exponent;
no = config.fluid.relative_permeability.oil.corey_exponent;

num_points = config.fluid.relative_permeability.saturation_range.num_points;
smoothing_factor = config.fluid.relative_permeability.saturation_range.smoothing_factor;

sw_range = linspace(swc, 1-sor, num_points);
krw = krw_max * ((sw_range - swc) / (1 - swc - sor)).^nw;
kro = kro_max * ((1 - sw_range - sor) / (1 - swc - sor)).^no;

% Replace the smoothdata lines with Octave-compatible smoothing
if smoothing_factor > 0
    % Simple moving average smoothing for Octave compatibility
    window_size = max(1, round(num_points * smoothing_factor));
    if window_size > 1
        % Create moving average filter
        h = ones(1, window_size) / window_size;
        % Apply smoothing (pad edges to maintain array size)
        krw_padded = [repmat(krw(1), 1, floor(window_size/2)), krw, repmat(krw(end), 1, floor(window_size/2))];
        kro_padded = [repmat(kro(1), 1, floor(window_size/2)), kro, repmat(kro(end), 1, floor(window_size/2))];
        krw_smooth = conv(krw_padded, h, 'valid');
        kro_smooth = conv(kro_padded, h, 'valid');
        krw = krw_smooth(1:length(krw));
        kro = kro_smooth(1:length(kro));
    end
end

krw(sw_range <= swc) = 0;
kro(sw_range >= 1-sor) = 0;

fluid.krW = @(s) interpTable(s, sw_range, krw);
fluid.krO = @(s) interpTable(s, sw_range, kro);

fprintf('[INFO] Kr curves generated:\n');
fprintf('  Swc = %.3f, Sor = %.3f\n', swc, sor);
fprintf('  krw_max = %.3f, kro_max = %.3f\n', krw_max, kro_max);

%% ----
%% Step 5 – Export fluid properties for dashboard
%% ----

fluid_properties = struct();
fluid_properties.kr_curves = struct();
fluid_properties.kr_curves.sw = sw_range;
fluid_properties.kr_curves.krw = krw;
fluid_properties.kr_curves.kro = kro;
fluid_properties.kr_curves.swc = swc;
fluid_properties.kr_curves.sor = sor;

fluid_properties_path = '../data/static/fluid_properties.mat';
if ~exist('../data/static', 'dir')
    mkdir('../data/static');
end
save(fluid_properties_path, 'fluid_properties');

fprintf('[INFO] Fluid properties exported to: %s\n', fluid_properties_path);

%% ----
%% Step 6 – Verify fluid structure
%% ----

assert(isfield(fluid, 'krW'), 'Water relative permeability function missing');
assert(isfield(fluid, 'krO'), 'Oil relative permeability function missing');
assert(isfield(fluid, 'mu'), 'Viscosity values missing');
assert(isfield(fluid, 'rho'), 'Density values missing');

fprintf('[INFO] Fluid structure created successfully\n');

end

function y = interpTable(x, x_data, y_data)
y = interp1(x_data, y_data, x, 'pchip', 'extrap');
y = max(0, min(1, y));
end 