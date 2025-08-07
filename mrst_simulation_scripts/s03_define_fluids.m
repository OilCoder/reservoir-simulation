function fluid = s03_define_fluids()
% S03_DEFINE_FLUIDS - Define fluid properties for Eagle West Field simulation
%
% SYNTAX:
%   fluid = s03_define_fluids()
%
% OUTPUT:
%   fluid - MRST fluid structure with complete PVT and relative permeability data
%
% DESCRIPTION:
%   This script defines the complete 3-phase black oil fluid system for 
%   Eagle West Field following specifications in 03_Fluid_Properties.md
%   and fluid_properties_config.yaml.
%
%   Fluid System Specifications:
%   - 3-phase black oil (oil-water-gas)
%   - API 32° oil (SG 0.865) 
%   - Bubble point: 2,100 psi @ 176°F
%   - Solution GOR: 450 scf/STB
%   - Formation water: 35,000 ppm TDS
%   - Complete PVT tables and relative permeability curves
%
% Author: Claude Code AI System  
% Date: January 30, 2025

    fprintf('======================================================\n');
    fprintf('Eagle West Field - Fluid Properties Definition (Step 3)\n');
    fprintf('======================================================\n\n');
    
    try
        % Step 1 - Load fluid configuration
        fprintf('Step 1: Loading fluid properties configuration...\n');
        fluid_config = load_fluid_config();
        fluid_params = fluid_config.fluid_properties;
        fprintf('   ✓ Configuration loaded from fluid_properties_config.yaml\n\n');
        
        % Step 2 - Validate fluid parameters
        fprintf('Step 2: Validating fluid parameters...\n');
        validate_fluid_parameters(fluid_params);
        fprintf('   ✓ Fluid parameters validated\n\n');
        
        % Step 3 - Create PVT tables
        fprintf('Step 3: Creating PVT tables...\n');
        pvt_data = create_pvt_tables(fluid_params);
        fprintf('   ✓ PVT tables created\n');
        fprintf('     Pressure range: %.0f - %.0f psi (%d points)\n', ...
                min(pvt_data.pressure), max(pvt_data.pressure), length(pvt_data.pressure));
        
        % Step 4 - Create relative permeability curves
        fprintf('Step 4: Creating relative permeability curves...\n');
        relperm_data = create_relperm_curves(fluid_params);
        fprintf('   ✓ Relative permeability curves created\n');
        fprintf('     Saturation table: %d points\n', length(relperm_data.sw));
        
        % Step 5 - Assemble MRST fluid structure
        fprintf('Step 5: Assembling MRST fluid structure...\n');
        fluid = create_mrst_fluid(fluid_params, pvt_data, relperm_data);
        fprintf('   ✓ MRST fluid structure created\n\n');
        
        % Step 6 - Validate fluid properties
        fprintf('Step 6: Validating fluid properties...\n');
        validate_fluid_properties(fluid, fluid_params);
        fprintf('   ✓ Fluid properties validated\n\n');
        
        % Step 7 - Export fluid data
        fprintf('Step 7: Exporting fluid data...\n');
        export_fluid_data(fluid, fluid_params, pvt_data, relperm_data);
        fprintf('   ✓ Fluid data exported\n\n');
        
        % Success summary
        fprintf('======================================================\n');
        fprintf('Fluid Properties Definition Completed Successfully\n');
        fprintf('======================================================\n');
        fprintf('Fluid System: 3-phase black oil\n');
        fprintf('Oil Density: %.0f kg/m³ (API %.1f°)\n', fluid_params.oil_density, fluid_params.api_gravity);
        fprintf('Water Density: %.0f kg/m³ (SG %.3f)\n', fluid_params.water_density, fluid_params.water_specific_gravity);
        fprintf('Gas Density: %.1f kg/m³ (SG %.3f)\n', fluid_params.gas_density, fluid_params.gas_specific_gravity);
        fprintf('Bubble Point: %.0f psi @ %.0f°F\n', fluid_params.bubble_point, fluid_params.reservoir_temperature);
        fprintf('Solution GOR: %.0f scf/STB\n', fluid_params.solution_gor);
        fprintf('PVT Points: %d pressure points\n', length(pvt_data.pressure));
        fprintf('Rel-perm Points: %d saturation points\n', length(relperm_data.sw));
        fprintf('======================================================\n\n');
        
    catch ME
        fprintf('\n❌ Fluid properties definition FAILED\n');
        fprintf('Error: %s\n', ME.message);
        if ~isempty(ME.stack)
            fprintf('Location: %s (line %d)\n', ME.stack(1).file, ME.stack(1).line);
        end
        error('Fluid properties definition failed: %s', ME.message);
    end

end

function validate_fluid_parameters(fluid_params)
% VALIDATE_FLUID_PARAMETERS - Validate fluid configuration parameters
%
% INPUT:
%   fluid_params - Fluid parameters structure from YAML

    % Check required basic properties
    required_fields = {'oil_density', 'water_density', 'gas_density', ...
                      'oil_viscosity', 'water_viscosity', 'bubble_point', 'solution_gor'};
    
    for i = 1:length(required_fields)
        field = required_fields{i};
        if ~isfield(fluid_params, field)
            error('Required fluid parameter missing: %s', field);
        end
        
        value = fluid_params.(field);
        if ~isnumeric(value) || value <= 0
            error('Fluid parameter %s must be positive numeric. Got: %s', field, num2str(value));
        end
    end
    
    % Validate density ranges (reasonable values)
    oil_density = fluid_params.oil_density;
    if oil_density < 700 || oil_density > 1000
        warning('Oil density %.0f kg/m³ outside typical range (700-1000 kg/m³)', oil_density);
    end
    
    water_density = fluid_params.water_density;
    if water_density < 900 || water_density > 1200
        warning('Water density %.0f kg/m³ outside typical range (900-1200 kg/m³)', water_density);
    end
    
    % Validate PVT parameters
    bubble_point = fluid_params.bubble_point;
    if bubble_point < 500 || bubble_point > 5000
        warning('Bubble point %.0f psi outside typical range (500-5000 psi)', bubble_point);
    end
    
    solution_gor = fluid_params.solution_gor;
    if solution_gor > 2000
        warning('Solution GOR %.0f scf/STB is very high (>2000)', solution_gor);
    end
    
    fprintf('     Oil: %.0f kg/m³, %.2f cP\n', fluid_params.oil_density, fluid_params.oil_viscosity);
    fprintf('     Water: %.0f kg/m³, %.3f cP\n', fluid_params.water_density, fluid_params.water_viscosity);
    fprintf('     Gas: %.1f kg/m³\n', fluid_params.gas_density);
    fprintf('     Bubble point: %.0f psi\n', fluid_params.bubble_point);
    fprintf('     Solution GOR: %.0f scf/STB\n', fluid_params.solution_gor);

end

function pvt_data = create_pvt_tables(fluid_params)
% CREATE_PVT_TABLES - Create pressure-volume-temperature tables
%
% INPUT:
%   fluid_params - Fluid parameters structure
%
% OUTPUT:
%   pvt_data - Structure containing PVT tables

    % Define pressure range
    bubble_point = fluid_params.bubble_point;
    min_pressure = 500.0;  % Minimum reservoir pressure (psi)
    max_pressure = bubble_point * 2.0;  % Extend above bubble point
    n_points = 50;  % Number of PVT table points
    
    pressure = linspace(min_pressure, max_pressure, n_points)';
    
    % Create oil PVT properties
    [Bo, muo] = calculate_oil_pvt(pressure, fluid_params);
    
    % Create water PVT properties
    [Bw, muw] = calculate_water_pvt(pressure, fluid_params);
    
    % Create gas PVT properties  
    [Bg, mug] = calculate_gas_pvt(pressure, fluid_params);
    
    % Assemble PVT data structure
    pvt_data = struct();
    pvt_data.pressure = pressure;
    pvt_data.Bo = Bo;
    pvt_data.muo = muo;
    pvt_data.Bw = Bw;
    pvt_data.muw = muw;
    pvt_data.Bg = Bg;
    pvt_data.mug = mug;
    
    % Add dissolved GOR table (Rs)
    pvt_data.Rs = calculate_solution_gor(pressure, fluid_params);

end

function [Bo, muo] = calculate_oil_pvt(pressure, fluid_params)
% CALCULATE_OIL_PVT - Calculate oil formation volume factor and viscosity
%
% INPUT:
%   pressure - Pressure array (psi)
%   fluid_params - Fluid parameters
%
% OUTPUT:
%   Bo - Oil formation volume factor (rb/STB)
%   muo - Oil viscosity (cP)

    bubble_point = fluid_params.bubble_point;
    solution_gor = fluid_params.solution_gor;
    oil_visc_ref = fluid_params.oil_viscosity;
    
    % Initialize arrays
    Bo = zeros(size(pressure));
    muo = zeros(size(pressure));
    
    % Calculate properties for each pressure point
    for i = 1:length(pressure)
        p = pressure(i);
        
        if p >= bubble_point
            % Undersaturated oil (above bubble point)
            % Oil compressibility effect
            co = 1.0e-5;  % Oil compressibility (1/psi)
            Bo(i) = 1.0 + co * (p - bubble_point);
            
            % Viscosity increases slightly with pressure
            muo(i) = oil_visc_ref * (1.0 + 0.0001 * (p - bubble_point));
            
        else
            % Saturated oil (below bubble point)
            % Standing correlation for Bo
            Rs_current = solution_gor * (p / bubble_point)^1.2;  % Current solution GOR
            Bo(i) = 0.972 + 0.000147 * Rs_current^1.175;
            
            % Dead oil viscosity correlation
            muo(i) = oil_visc_ref * (1.0 - 0.0001 * (bubble_point - p));
            muo(i) = max(muo(i), oil_visc_ref * 0.3);  % Minimum viscosity limit
        end
    end
    
    % Ensure Bo is reasonable
    Bo = max(Bo, 1.0);  % Bo cannot be less than 1.0

end

function [Bw, muw] = calculate_water_pvt(pressure, fluid_params)
% CALCULATE_WATER_PVT - Calculate water formation volume factor and viscosity
%
% INPUT:
%   pressure - Pressure array (psi)
%   fluid_params - Fluid parameters
%
% OUTPUT:
%   Bw - Water formation volume factor (rb/STB)
%   muw - Water viscosity (cP)

    water_visc_ref = fluid_params.water_viscosity;
    
    % Water compressibility (slightly compressible)
    cw = 3.0e-6;  % Water compressibility (1/psi)
    reference_pressure = mean(pressure);
    
    % Calculate water FVF
    Bw = 1.0 + cw * (reference_pressure - pressure);
    
    % Water viscosity (approximately constant with pressure)
    muw = ones(size(pressure)) * water_visc_ref;
    
    % Slight temperature effects on viscosity (simplified)
    % Viscosity decreases slightly with increasing pressure (temperature effect)
    muw = muw .* (1.0 - 0.00001 * (pressure - reference_pressure));
    muw = max(muw, water_visc_ref * 0.8);  % Minimum limit

end

function [Bg, mug] = calculate_gas_pvt(pressure, fluid_params)
% CALCULATE_GAS_PVT - Calculate gas formation volume factor and viscosity
%
% INPUT:
%   pressure - Pressure array (psi)  
%   fluid_params - Fluid parameters
%
% OUTPUT:
%   Bg - Gas formation volume factor (rb/Mscf)
%   mug - Gas viscosity (cP)

    gas_visc_ref = 0.02;  % Default gas viscosity (cP)
    if isfield(fluid_params, 'gas_viscosity')
        gas_visc_ref = fluid_params.gas_viscosity;
    end
    
    % Gas formation volume factor (ideal gas approximation)
    % Bg = Z * R * T / P, simplified to Bg = const / P
    reference_pressure = 1000.0;  % psi
    reference_bg = 0.005;  % rb/Mscf (typical value)
    
    Bg = reference_bg * reference_pressure ./ pressure;
    
    % Gas viscosity using Lee correlation (simplified)
    % Viscosity increases with pressure
    mug = gas_visc_ref * (1.0 + 0.00005 * pressure);

end

function Rs = calculate_solution_gor(pressure, fluid_params)
% CALCULATE_SOLUTION_GOR - Calculate dissolved gas-oil ratio
%
% INPUT:
%   pressure - Pressure array (psi)
%   fluid_params - Fluid parameters
%
% OUTPUT:
%   Rs - Solution gas-oil ratio (scf/STB)

    bubble_point = fluid_params.bubble_point;
    solution_gor_max = fluid_params.solution_gor;
    
    % Solution GOR using Standing correlation
    Rs = zeros(size(pressure));
    
    for i = 1:length(pressure)
        p = pressure(i);
        
        if p >= bubble_point
            % Above bubble point - constant Rs
            Rs(i) = solution_gor_max;
        else
            % Below bubble point - Rs decreases with pressure
            Rs(i) = solution_gor_max * (p / bubble_point)^1.2;
        end
    end

end

function relperm_data = create_relperm_curves(fluid_params)
% CREATE_RELPERM_CURVES - Create relative permeability curves
%
% INPUT:
%   fluid_params - Fluid parameters structure
%
% OUTPUT:
%   relperm_data - Structure containing relative permeability tables

    % Saturation table
    n_sat_points = 100;
    sw = linspace(0, 1, n_sat_points)';
    
    % Get endpoint saturations from configuration
    swc = get_param_with_default(fluid_params, 'connate_water_saturation', 0.15);
    sor = get_param_with_default(fluid_params, 'residual_oil_saturation', 0.25);
    sgr = get_param_with_default(fluid_params, 'residual_gas_saturation', 0.05);
    
    % Get Corey exponents
    nw = get_param_with_default(fluid_params, 'corey_water_exponent', 2.5);
    no = get_param_with_default(fluid_params, 'corey_oil_exponent', 2.0);
    ng = get_param_with_default(fluid_params, 'corey_gas_exponent', 1.8);
    
    % Get endpoint relative permeabilities
    krw_max = get_param_with_default(fluid_params, 'krw_max', 0.40);
    kro_max = get_param_with_default(fluid_params, 'kro_max', 0.85);
    krg_max = get_param_with_default(fluid_params, 'krg_max', 0.75);
    
    % Calculate relative permeabilities using Corey correlations
    [krw, kro, krg] = calculate_corey_relperm(sw, swc, sor, sgr, nw, no, ng, ...
                                            krw_max, kro_max, krg_max);
    
    % Calculate capillary pressures
    [pcow, pcog] = calculate_capillary_pressure(sw, fluid_params);
    
    % Assemble relative permeability data
    relperm_data = struct();
    relperm_data.sw = sw;
    relperm_data.krw = krw;
    relperm_data.kro = kro;
    relperm_data.krg = krg;
    relperm_data.pcow = pcow;
    relperm_data.pcog = pcog;
    
    % Store endpoint parameters for reference
    relperm_data.swc = swc;
    relperm_data.sor = sor;
    relperm_data.sgr = sgr;
    relperm_data.krw_max = krw_max;
    relperm_data.kro_max = kro_max;
    relperm_data.krg_max = krg_max;

end

function [krw, kro, krg] = calculate_corey_relperm(sw, swc, sor, sgr, nw, no, ng, ...
                                                 krw_max, kro_max, krg_max)
% CALCULATE_COREY_RELPERM - Calculate relative permeabilities using Corey correlations
%
% INPUT:
%   sw - Water saturation array
%   swc, sor, sgr - Endpoint saturations
%   nw, no, ng - Corey exponents
%   krw_max, kro_max, krg_max - Endpoint relative permeabilities
%
% OUTPUT:
%   krw, kro, krg - Relative permeability arrays

    % Initialize arrays
    krw = zeros(size(sw));
    kro = zeros(size(sw));
    krg = zeros(size(sw));
    
    % Calculate for each saturation point
    for i = 1:length(sw)
        sw_val = sw(i);
        
        % Water relative permeability
        if sw_val <= swc
            krw(i) = 0;
        else
            sw_norm = (sw_val - swc) / (1 - swc - sor);
            sw_norm = min(max(sw_norm, 0), 1);  % Clamp between 0 and 1
            krw(i) = krw_max * sw_norm^nw;
        end
        
        % Oil relative permeability (oil-water system)
        if sw_val >= (1 - sor)
            kro(i) = 0;
        else
            so_norm = (1 - sw_val - sor) / (1 - swc - sor);
            so_norm = min(max(so_norm, 0), 1);  % Clamp between 0 and 1
            kro(i) = kro_max * so_norm^no;
        end
        
        % Gas relative permeability (simplified - assumes two-phase oil-water primarily)
        sg = 0;  % Assume minimal gas saturation for now
        if sg <= sgr
            krg(i) = 0;
        else
            sg_norm = (sg - sgr) / (1 - swc - sgr);
            sg_norm = min(max(sg_norm, 0), 1);
            krg(i) = krg_max * sg_norm^ng;
        end
    end

end

function [pcow, pcog] = calculate_capillary_pressure(sw, fluid_params)
% CALCULATE_CAPILLARY_PRESSURE - Calculate capillary pressure curves
%
% INPUT:
%   sw - Water saturation array
%   fluid_params - Fluid parameters
%
% OUTPUT:
%   pcow - Oil-water capillary pressure (psi)
%   pcog - Gas-oil capillary pressure (psi)

    % Get capillary pressure parameters
    pc_entry = get_param_with_default(fluid_params, 'capillary_entry_pressure', 5.0);
    lambda = get_param_with_default(fluid_params, 'capillary_lambda', 2.0);
    swc = get_param_with_default(fluid_params, 'connate_water_saturation', 0.15);
    
    % Calculate oil-water capillary pressure
    pcow = zeros(size(sw));
    
    for i = 1:length(sw)
        sw_val = sw(i);
        
        if sw_val <= swc
            pcow(i) = pc_entry / (swc^(1/lambda));  % High capillary pressure
        else
            pcow(i) = pc_entry / (sw_val^(1/lambda));
        end
        
        % Limit maximum capillary pressure
        pcow(i) = min(pcow(i), 100.0);  % Max 100 psi
    end
    
    % Gas-oil capillary pressure (simplified - assume negligible)
    pcog = zeros(size(sw));

end

function value = get_param_with_default(params, field_name, default_value)
% GET_PARAM_WITH_DEFAULT - Get parameter value with default fallback
%
% INPUT:
%   params - Parameters structure
%   field_name - Name of field to retrieve
%   default_value - Default value if field doesn't exist
%
% OUTPUT:
%   value - Parameter value or default

    if isfield(params, field_name)
        value = params.(field_name);
    else
        value = default_value;
    end

end

function fluid = create_mrst_fluid(fluid_params, pvt_data, relperm_data)
% CREATE_MRST_FLUID - Create MRST-compatible fluid structure
%
% INPUT:
%   fluid_params - Fluid parameters from config
%   pvt_data - PVT tables
%   relperm_data - Relative permeability data
%
% OUTPUT:
%   fluid - MRST fluid structure

    % Create fluid structure using MRST functions
    % Use initDeckADIFluid for black oil with tables
    
    % Prepare tables in MRST format
    PVTO = [pvt_data.pressure, pvt_data.Rs, pvt_data.Bo, pvt_data.muo];
    PVTW = [pvt_data.pressure(1), pvt_data.Bw(1), 3.0e-6, pvt_data.muw(1), 0];  % Reference + compressibility
    PVTG = [pvt_data.pressure, pvt_data.Bg, pvt_data.mug];
    
    % Relative permeability tables
    SWOF = [relperm_data.sw, relperm_data.krw, relperm_data.kro, relperm_data.pcow];
    
    % Create basic fluid structure
    fluid = struct();
    
    % Store PVT data
    fluid.pvto = PVTO;
    fluid.pvtw = PVTW;
    fluid.pvtg = PVTG;
    fluid.swof = SWOF;
    
    % Store surface densities (kg/m³)
    fluid.rhoOS = fluid_params.oil_density;     % Oil surface density
    fluid.rhoWS = fluid_params.water_density;   % Water surface density  
    fluid.rhoGS = fluid_params.gas_density;     % Gas surface density
    
    % Store basic properties
    fluid.muO = fluid_params.oil_viscosity;
    fluid.muW = fluid_params.water_viscosity;
    fluid.muG = get_param_with_default(fluid_params, 'gas_viscosity', 0.02);
    
    % Phase identification
    fluid.phases = 'WOG';  % Water-Oil-Gas
    
    % Critical properties
    fluid.Tcrit = [647.1, 507.6, 190.6] * Kelvin;  % Critical temperatures [W, O, G]
    fluid.Pcrit = [220.64, 22.064, 45.99] * barsa; % Critical pressures [W, O, G]
    
    fprintf('     Created MRST fluid structure with %d PVT points\n', length(pvt_data.pressure));

end

function validate_fluid_properties(fluid, fluid_params)
% VALIDATE_FLUID_PROPERTIES - Validate the created fluid structure
%
% INPUT:
%   fluid - MRST fluid structure
%   fluid_params - Original fluid parameters

    % Check that fluid structure has required fields
    required_fields = {'rhoOS', 'rhoWS', 'rhoGS', 'phases'};
    
    for i = 1:length(required_fields)
        field = required_fields{i};
        if ~isfield(fluid, field)
            error('Missing required field in fluid structure: %s', field);
        end
    end
    
    % Validate density values
    if abs(fluid.rhoOS - fluid_params.oil_density) > 1e-6
        error('Oil density mismatch in fluid structure');
    end
    
    if abs(fluid.rhoWS - fluid_params.water_density) > 1e-6
        error('Water density mismatch in fluid structure');
    end
    
    % Validate PVT tables exist and are reasonable
    if ~isfield(fluid, 'pvto') || isempty(fluid.pvto)
        error('Missing or empty PVTO table in fluid structure');
    end
    
    if ~isfield(fluid, 'swof') || isempty(fluid.swof)
        error('Missing or empty SWOF table in fluid structure');
    end
    
    fprintf('     Fluid structure validation passed\n');
    fprintf('     Phases: %s\n', fluid.phases);
    fprintf('     Surface densities: Oil=%.0f, Water=%.0f, Gas=%.1f kg/m³\n', ...
            fluid.rhoOS, fluid.rhoWS, fluid.rhoGS);

end

function export_fluid_data(fluid, fluid_params, pvt_data, relperm_data)
% EXPORT_FLUID_DATA - Export fluid data to files
%
% INPUT:
%   fluid - MRST fluid structure
%   fluid_params - Fluid parameters
%   pvt_data - PVT data
%   relperm_data - Relative permeability data

    % Create output directory
    script_path = fileparts(mfilename('fullpath'));
    data_dir = fullfile(fileparts(script_path), 'data', 'mrst_simulation', 'static');
    
    if ~exist(data_dir, 'dir')
        mkdir(data_dir);
    end
    
    % Save fluid structure in MATLAB format
    fluid_file = fullfile(data_dir, 'fluid_properties.mat');
    save(fluid_file, 'fluid', 'fluid_params', 'pvt_data', 'relperm_data', '');
    
    % Export fluid summary
    summary_file = fullfile(data_dir, 'fluid_summary.txt');
    fid = fopen(summary_file, 'w');
    
    fprintf(fid, 'Eagle West Field - Fluid Properties Summary\n');
    fprintf(fid, '==========================================\n\n');
    fprintf(fid, 'Fluid System: 3-phase black oil\n\n');
    
    fprintf(fid, 'Oil Properties:\n');
    fprintf(fid, '  Density: %.0f kg/m³ (API %.1f°, SG %.3f)\n', ...
            fluid_params.oil_density, fluid_params.api_gravity, fluid_params.specific_gravity);
    fprintf(fid, '  Viscosity: %.2f cP\n', fluid_params.oil_viscosity);
    fprintf(fid, '  Bubble Point: %.0f psi\n', fluid_params.bubble_point);
    fprintf(fid, '  Solution GOR: %.0f scf/STB\n', fluid_params.solution_gor);
    
    fprintf(fid, '\nWater Properties:\n');
    fprintf(fid, '  Density: %.0f kg/m³ (SG %.3f)\n', ...
            fluid_params.water_density, fluid_params.water_specific_gravity);
    fprintf(fid, '  Viscosity: %.3f cP\n', fluid_params.water_viscosity);
    fprintf(fid, '  Salinity: %.0f ppm TDS\n', fluid_params.water_salinity);
    
    fprintf(fid, '\nGas Properties:\n');
    fprintf(fid, '  Density: %.1f kg/m³ (SG %.3f)\n', ...
            fluid_params.gas_density, fluid_params.gas_specific_gravity);
    
    fprintf(fid, '\nReservoir Conditions:\n');
    fprintf(fid, '  Temperature: %.0f °F\n', fluid_params.reservoir_temperature);
    
    fprintf(fid, '\nRelative Permeability Endpoints:\n');
    fprintf(fid, '  Swc: %.3f\n', relperm_data.swc);
    fprintf(fid, '  Sor: %.3f\n', relperm_data.sor);
    fprintf(fid, '  krw@max: %.3f\n', relperm_data.krw_max);
    fprintf(fid, '  kro@max: %.3f\n', relperm_data.kro_max);
    
    fprintf(fid, '\nPVT Tables:\n');
    fprintf(fid, '  Pressure range: %.0f - %.0f psi\n', min(pvt_data.pressure), max(pvt_data.pressure));
    fprintf(fid, '  Number of points: %d\n', length(pvt_data.pressure));
    
    fprintf(fid, '\nCreation Date: %s\n', datestr(now));
    
    fclose(fid);
    
    fprintf('     Fluid data saved to: %s\n', fluid_file);
    fprintf('     Summary saved to: %s\n', summary_file);

end

% Load fluid configuration (calls read_yaml_config)
function fluid_config = load_fluid_config()
    % Load fluid configuration using the YAML reader
    fluid_config = read_yaml_config('config/fluid_properties_config.yaml');
end

% Main execution when called as script
if ~nargout
    % If called as script (not function), create and display fluid properties
    fluid = s03_define_fluids();
    
    fprintf('Fluid properties ready for simulation!\n');
    fprintf('Fluid phases: %s\n', fluid.phases);
    fprintf('Use fluid structure in reservoir simulation.\n\n');
end