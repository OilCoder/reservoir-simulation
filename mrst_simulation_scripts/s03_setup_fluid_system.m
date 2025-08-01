function [fluid, state] = s03_setup_fluid_system(G, rock, simulation_data)
% S03_SETUP_FLUID_SYSTEM - Configure 3-phase black oil fluid system

%
% DESCRIPTION:
%   Sets up 3-phase black oil fluid model for Eagle West Field with PVT
%   properties, relative permeability curves, and initial equilibrium state.
%   Implements oil-water-gas system with solution gas and capillary pressure.
%
% INPUT:
%   G - MRST grid structure from s02_build_static_model
%   rock - Rock properties structure from s02_build_static_model  
%   simulation_data - Structure from s01_initialize_simulation (optional)
%
% OUTPUT:
%   fluid - MRST fluid structure with PVT and relative permeability
%   state - Initial reservoir state with pressure and saturations
%
% FLUID SPECIFICATIONS:
%   - Oil: 32° API gravity, 450 scf/STB GOR, 2100 psi bubble point
%   - Water: 35,000 ppm TDS formation brine  
%   - Gas: Solution gas with 0.785 specific gravity
%   - Model: 3-phase black oil with Corey relative permeability
%
% REFERENCE:
%   Based on fluid_properties_config.yaml and 03_Fluid_Properties.md

    fprintf('\n');
    fprintf('=================================================================\n');
    fprintf('  EAGLE WEST FIELD - FLUID SYSTEM SETUP                          \n');
    fprintf('=================================================================\n');
    fprintf('Script: s03_setup_fluid_system.m\n');
    fprintf('Purpose: Configure 3-phase black oil fluid system\n');
    fprintf('=================================================================\n\n');

    % Record start time
    fluid_start_time = tic;
    
    % Validate inputs
    if nargin < 2
        error('s03_setup_fluid_system:InsufficientInputs', 'Grid (G) and rock properties required');
    end
    
    if nargin < 3
        simulation_data = struct();
        fprintf('[INFO] No simulation_data provided, using default parameters\n');
    end
    
    % Check if MRST is available
    if ~exist('initSimpleADIFluid', 'file')
        fprintf('[WARN] MRST not available - returning minimal structures\n');
        
        % Create minimal valid structures for testing
        fluid = struct();
        fluid.name = 'minimal_fluid';
        fluid.phases = 'WOG';
        
        state = struct();
        state.pressure = zeros(G.cells.num, 1);
        state.s = zeros(G.cells.num, 3);  % [water, oil, gas]
        
        fprintf('[INFO] Returned empty but valid fluid and state structures\n');
        fprintf('=================================================================\n\n');
        return;
    end
    
    try
        %% STEP 1: LOAD FLUID PROPERTIES CONFIGURATION
        fprintf('[STEP 1] Loading fluid properties configuration...\n');
        
        % Load fluid properties from YAML configuration
        config_file = fullfile(pwd, 'config', 'fluid_properties_config.yaml');
        
        if exist(config_file, 'file')
            fluid_config = util_read_config(config_file);
            fprintf('  [OK] Fluid properties loaded from: %s\n', config_file);
        else
            error('s03_setup_fluid_system:ConfigNotFound', 'Fluid properties configuration not found: %s', config_file);
        end
        
        % Load initial conditions configuration
        init_config_file = fullfile(pwd, 'config', 'initial_conditions_config.yaml');
        
        if exist(init_config_file, 'file')
            init_config = util_read_config(init_config_file);
            fprintf('  [OK] Initial conditions loaded from: %s\n', init_config_file);
        else
            fprintf('  [WARN] Initial conditions config not found, using defaults\n');
            init_config = struct();
        end
        
        %% STEP 2: UNIT CONVERSIONS AND CONSTANTS
        fprintf('\n[STEP 2] Setting up unit conversions and physical constants...\n');
        
        % Unit conversions
        psi_to_Pa = 6894.76; % Convert psi to Pascal
        ft_to_m = 0.3048; % Convert feet to meters
        darcy_to_m2 = 9.869e-16; % Convert Darcy to m²
        stb_to_m3 = 0.158987; % Convert STB to m³
        scf_to_m3 = 0.0283168; % Convert SCF to m³
        cp_to_Pas = 0.001; % Convert centipoise to Pa·s
        
        % Extract key reservoir parameters from config or use defaults
        try
            % Reservoir conditions
            if isfield(fluid_config, 'reservoir_conditions')
                res_cond = fluid_config.reservoir_conditions;
                initial_pressure_psi = res_cond.initial_pressure; % 2900 psi
                temperature_F = res_cond.reservoir_temperature; % 176°F
                datum_depth_ft = res_cond.datum_depth; % 8000 ft
            else
                initial_pressure_psi = 2900;
                temperature_F = 176;
                datum_depth_ft = 8000;
                fprintf('  [WARN] Using default reservoir conditions\n');
            end
            
            % Oil properties
            if isfield(fluid_config, 'oil_properties')
                oil_prop = fluid_config.oil_properties;
                api_gravity = oil_prop.api_gravity; % 32° API
                initial_gor = oil_prop.initial_gor; % 450 scf/STB
                bubble_point_psi = oil_prop.bubble_point_pressure; % 2100 psi
            else
                api_gravity = 32;
                initial_gor = 450;
                bubble_point_psi = 2100;
                fprintf('  [WARN] Using default oil properties\n');
            end
            
            % Fluid contacts
            if isfield(fluid_config, 'fluid_contacts')
                contacts = fluid_config.fluid_contacts;
                owc_depth_ft = contacts.oil_water_contact; % 8150 ft
            else
                owc_depth_ft = 8150;
                fprintf('  [WARN] Using default fluid contacts\n');
            end
            
        catch
            % Fallback to default values
            initial_pressure_psi = 2900;
            temperature_F = 176;
            datum_depth_ft = 8000;
            api_gravity = 32;
            initial_gor = 450;
            bubble_point_psi = 2100;
            owc_depth_ft = 8150;
            fprintf('  [WARN] Using all default fluid parameters\n');
        end
        
        % Convert to SI units
        initial_pressure_Pa = initial_pressure_psi * psi_to_Pa;
        temperature_K = (temperature_F - 32) * 5/9 + 273.15; % Convert °F to K
        datum_depth_m = datum_depth_ft * ft_to_m;
        bubble_point_Pa = bubble_point_psi * psi_to_Pa;
        owc_depth_m = owc_depth_ft * ft_to_m;
        
        fprintf('  --> Initial pressure: %.0f psi (%.2e Pa)\n', initial_pressure_psi, initial_pressure_Pa);
        fprintf('  --> Temperature: %.0f°F (%.1f K)\n', temperature_F, temperature_K);
        fprintf('  --> Oil: %.0f° API, GOR %.0f scf/STB, Pb %.0f psi\n', api_gravity, initial_gor, bubble_point_psi);
        fprintf('  --> OWC depth: %.0f ft (%.1f m)\n', owc_depth_ft, owc_depth_m);
        
        %% STEP 3: PVT PROPERTIES SETUP
        fprintf('\n[STEP 3] Setting up PVT properties...\n');
        
        % Initialize fluid structure
        fluid = initSimpleADIFluid('phases', 'WOG', 'mu', [0.5, 1.0, 0.02]*cp_to_Pas, ...
                                   'rho', [1000, 850, 50], 'n', [2, 2, 2]);
        
        fprintf('  [OK] Basic fluid structure initialized\n');
        
        % Oil PVT properties (from config or correlations)
        try
            if isfield(fluid_config, 'pvt_tables') && isfield(fluid_config.pvt_tables, 'oil_pvt')
                oil_pvt = fluid_config.pvt_tables.oil_pvt;
                
                % Extract PVT data arrays
                pressure_psi = oil_pvt.pressure;
                rs_scf_stb = oil_pvt.rs;
                bo_rb_stb = oil_pvt.bo;
                muo_cp = oil_pvt.muo;
                
                fprintf('  --> Oil PVT: %d data points from config\n', length(pressure_psi));
            else
                % Use default PVT correlations
                pressure_psi = [14.7, 500, 1000, 1500, 2000, 2100, 2200, 2500, 3000];
                rs_scf_stb = [0, 195, 285, 365, 435, 450, 450, 450, 450];
                bo_rb_stb = [1.125, 1.125, 1.185, 1.245, 1.295, 1.305, 1.301, 1.295, 1.285];
                muo_cp = [1.85, 1.85, 1.45, 1.15, 0.95, 0.92, 0.94, 0.98, 1.05];
                
                fprintf('  --> Oil PVT: %d default correlation points\n', length(pressure_psi));
            end
        catch
            % Fallback PVT data
            pressure_psi = [14.7, 2100, 3000];
            rs_scf_stb = [0, 450, 450];
            bo_rb_stb = [1.125, 1.305, 1.285];
            muo_cp = [1.85, 0.92, 1.05];
            fprintf('  [WARN] Using minimal PVT data (3 points)\n');
        end
        
        % Convert units for MRST
        pressure_Pa = pressure_psi * psi_to_Pa;
        rs_m3_m3 = rs_scf_stb * scf_to_m3 / stb_to_m3;
        bo_factor = bo_rb_stb; % Dimensionless
        muo_Pas = muo_cp * cp_to_Pas;
        
        % Create oil PVT interpolation functions
        fluid.bO = @(p, rs, flag) interp1(pressure_Pa, bo_factor, p, 'linear', 'extrap');
        fluid.muO = @(p, rs, flag) interp1(pressure_Pa, muo_Pas, p, 'linear', 'extrap');
        fluid.rsSat = @(p) interp1(pressure_Pa, rs_m3_m3, p, 'linear', 'extrap');
        
        fprintf('  [OK] Oil PVT functions created (Bo, μo, Rs)\n');
        
        % Gas PVT properties
        try
            if isfield(fluid_config, 'pvt_tables') && isfield(fluid_config.pvt_tables, 'gas_pvt')
                gas_pvt = fluid_config.pvt_tables.gas_pvt;
                gas_pressure_psi = gas_pvt.pressure;
                bg_rb_mscf = gas_pvt.bg;
                mug_cp = gas_pvt.mug;
                fprintf('  --> Gas PVT: %d data points from config\n', length(gas_pressure_psi));
            else
                % Default gas PVT
                gas_pressure_psi = pressure_psi;
                bg_rb_mscf = [178.0, 3.850, 1.925, 1.283, 0.963, 0.889, 0.857, 0.770, 0.642];
                mug_cp = [0.010, 0.0145, 0.0165, 0.0185, 0.0205, 0.0215, 0.0220, 0.0225, 0.0245];
                fprintf('  --> Gas PVT: %d default correlation points\n', length(gas_pressure_psi));
            end
        catch
            gas_pressure_psi = [14.7, 2100, 3000];
            bg_rb_mscf = [178.0, 0.889, 0.642];
            mug_cp = [0.010, 0.0215, 0.0245];
            fprintf('  [WARN] Using minimal gas PVT data\n');
        end
        
        % Convert gas units
        gas_pressure_Pa = gas_pressure_psi * psi_to_Pa;
        bg_factor = bg_rb_mscf * stb_to_m3 / (1000 * scf_to_m3); % Convert RB/Mscf to m³/m³
        mug_Pas = mug_cp * cp_to_Pas;
        
        % Create gas PVT functions
        fluid.bG = @(p, rv, flag) interp1(gas_pressure_Pa, bg_factor, p, 'linear', 'extrap');
        fluid.muG = @(p, rv, flag) interp1(gas_pressure_Pa, mug_Pas, p, 'linear', 'extrap');
        
        fprintf('  [OK] Gas PVT functions created (Bg, μg)\n');
        
        % Water PVT properties
        try
            if isfield(fluid_config, 'pvt_tables') && isfield(fluid_config.pvt_tables, 'water_pvt')
                water_pvt = fluid_config.pvt_tables.water_pvt;
                bw_ref = water_pvt.bw; % 1.012 RB/STB
                cw_psi = water_pvt.cw; % 3.2e-6 1/psi
                muw_cp = water_pvt.muw; % 0.38 cp
                fprintf('  --> Water PVT: reference properties from config\n');
            else
                bw_ref = 1.012;
                cw_psi = 3.2e-6;
                muw_cp = 0.38;
                fprintf('  --> Water PVT: default properties\n');
            end
        catch
            bw_ref = 1.012;
            cw_psi = 3.2e-6;
            muw_cp = 0.38;
            fprintf('  [WARN] Using default water properties\n');
        end
        
        % Water compressibility function
        cw_Pa = cw_psi / psi_to_Pa;
        muw_Pas = muw_cp * cp_to_Pas;
        
        fluid.bW = @(p) bw_ref * exp(cw_Pa * (p - initial_pressure_Pa));
        fluid.muW = @(p) muw_Pas * ones(size(p)); % Constant viscosity
        
        fprintf('  [OK] Water PVT functions created (Bw, μw)\n');
        
        %% STEP 4: RELATIVE PERMEABILITY CURVES
        fprintf('\n[STEP 4] Setting up relative permeability curves...\n');
        
        % Saturation endpoints (from config or defaults)
        try
            if isfield(fluid_config, 'rel_perm_scaling')
                rel_perm = fluid_config.rel_perm_scaling;
                
                % Water-oil endpoints
                if isfield(rel_perm, 'water_oil')
                    swl = rel_perm.water_oil.swl; % 0.20
                    swcr = rel_perm.water_oil.swcr; % 0.20
                    sowcr = rel_perm.water_oil.sowcr; % 0.25
                else
                    swl = 0.20; swcr = 0.20; sowcr = 0.25;
                end
                
                % Gas-oil endpoints
                if isfield(rel_perm, 'gas_oil')
                    sgl = rel_perm.gas_oil.sgl; % 0.00
                    sgcr = rel_perm.gas_oil.sgcr; % 0.05
                    sogcr = rel_perm.gas_oil.sogcr; % 0.20
                else
                    sgl = 0.00; sgcr = 0.05; sogcr = 0.20;
                end
                
                fprintf('  --> Saturation endpoints from config\n');
            else
                % Default endpoints
                swl = 0.20; swcr = 0.20; sowcr = 0.25;
                sgl = 0.00; sgcr = 0.05; sogcr = 0.20;
                fprintf('  --> Default saturation endpoints\n');
            end
        catch
            swl = 0.20; swcr = 0.20; sowcr = 0.25;
            sgl = 0.00; sgcr = 0.05; sogcr = 0.20;
            fprintf('  [WARN] Using default saturation endpoints\n');
        end
        
        % Corey exponents
        nw = 2.0; % Water Corey exponent
        now = 2.5; % Oil-water Corey exponent
        ng = 1.8; % Gas Corey exponent
        nog = 2.2; % Oil-gas Corey exponent
        
        % Maximum relative permeabilities
        krw_max = 0.4; % Maximum water relative permeability
        kro_max = 1.0; % Maximum oil relative permeability
        krg_max = 0.8; % Maximum gas relative permeability
        
        fprintf('  --> Saturation endpoints: Swcr=%.2f, Sowcr=%.2f, Sgcr=%.2f\n', swcr, sowcr, sgcr);
        fprintf('  --> Corey exponents: nw=%.1f, now=%.1f, ng=%.1f, nog=%.1f\n', nw, now, ng, nog);
        
        % Create relative permeability functions
        % Water-oil system
        fluid.krW = @(sw, varargin) krw_max * ((sw - swcr) / (1 - swcr - sowcr)).^nw .* (sw >= swcr);
        fluid.krOW = @(so, varargin) kro_max * ((so - sowcr) / (1 - swcr - sowcr)).^now .* (so >= sowcr);
        
        % Gas-oil system
        fluid.krG = @(sg, varargin) krg_max * ((sg - sgcr) / (1 - sgcr - sogcr)).^ng .* (sg >= sgcr);
        fluid.krOG = @(so, varargin) kro_max * ((so - sogcr) / (1 - sgcr - sogcr)).^nog .* (so >= sogcr);
        
        % Three-phase oil relative permeability (Stone's Model II)
        fluid.krO = @(so, sw, sg, varargin) stone_model_ii(so, sw, sg, fluid.krOW, fluid.krOG, ...
                                                           swcr, sgcr, sowcr, sogcr);
        
        fprintf('  [OK] Relative permeability functions created (Corey model)\n');
        
        %% STEP 5: CAPILLARY PRESSURE
        fprintf('\n[STEP 5] Setting up capillary pressure curves...\n');
        
        % Oil-water capillary pressure (Leverett J-function)
        entry_pressure_Pa = 5.0 * psi_to_Pa; % Entry pressure
        lambda_ow = 2.0; % Pore size distribution index
        
        fluid.pcOW = @(sw, varargin) entry_pressure_Pa * ((sw - swl) / (1 - swl)).^(-1/lambda_ow) .* (sw > swl);
        
        % Gas-oil capillary pressure (minimal)
        fluid.pcOG = @(sg, varargin) 0.5 * psi_to_Pa * sg; % Small gas-oil capillary pressure
        
        fprintf('  [OK] Capillary pressure functions created (Leverett J-function)\n');
        
        %% STEP 6: INITIAL STATE CALCULATION
        fprintf('\n[STEP 6] Calculating initial reservoir state...\n');
        
        % Get cell center depths
        cell_depths_m = G.cells.centroids(:,3);
        cell_depths_ft = cell_depths_m / ft_to_m;
        
        fprintf('  --> Cell depth range: %.1f - %.1f m (%.0f - %.0f ft)\n', ...
                min(cell_depths_m), max(cell_depths_m), min(cell_depths_ft), max(cell_depths_ft));
        
        % Initialize state structure
        state = initResSol(G, initial_pressure_Pa);
        
        % Calculate hydrostatic pressure distribution
        % Oil density at reservoir conditions (32° API ≈ 0.865 g/cm³ = 865 kg/m³)
        oil_density = 865; % kg/m³
        water_density = 1020; % kg/m³ (35,000 ppm brine)
        
        % Pressure gradients
        oil_gradient_Pa_m = oil_density * 9.81; % Pa/m
        water_gradient_Pa_m = water_density * 9.81; % Pa/m
        
        fprintf('  --> Oil gradient: %.1f Pa/m (%.3f psi/ft)\n', oil_gradient_Pa_m, oil_gradient_Pa_m * ft_to_m / psi_to_Pa);
        fprintf('  --> Water gradient: %.1f Pa/m (%.3f psi/ft)\n', water_gradient_Pa_m, water_gradient_Pa_m * ft_to_m / psi_to_Pa);
        
        % Calculate pressure in each cell
        for i = 1:G.cells.num
            if cell_depths_m(i) <= owc_depth_m
                % Above OWC - use oil gradient
                state.pressure(i) = initial_pressure_Pa + oil_gradient_Pa_m * (cell_depths_m(i) - datum_depth_m);
            else
                % Below OWC - use water gradient
                pressure_at_owc = initial_pressure_Pa + oil_gradient_Pa_m * (owc_depth_m - datum_depth_m);
                state.pressure(i) = pressure_at_owc + water_gradient_Pa_m * (cell_depths_m(i) - owc_depth_m);
            end
        end
        
        fprintf('  [OK] Hydrostatic pressure calculated\n');
        
        % Initialize saturations based on depth relative to OWC
        state.s = zeros(G.cells.num, 3); % [Water, Oil, Gas]
        
        % Initial saturations per documentation
        so_initial = 0.75; % Oil saturation in oil zone
        sw_connate = 0.25; % Connate water saturation
        sg_initial = 0.00; % No free gas initially (undersaturated)
        
        for i = 1:G.cells.num
            if cell_depths_m(i) <= owc_depth_m
                % Above OWC - oil zone
                state.s(i, 1) = sw_connate; % Water
                state.s(i, 2) = so_initial; % Oil
                state.s(i, 3) = sg_initial; % Gas
            else
                % Below OWC - water zone
                state.s(i, 1) = 1.0; % Water
                state.s(i, 2) = 0.0; % Oil
                state.s(i, 3) = 0.0; % Gas
            end
        end
        
        % Normalize saturations to ensure sum = 1
        state.s = bsxfun(@rdivide, state.s, sum(state.s, 2));
        
        fprintf('  [OK] Initial saturations assigned\n');
        fprintf('    Oil zone (above OWC): So=%.2f, Sw=%.2f, Sg=%.2f\n', so_initial, sw_connate, sg_initial);
        fprintf('    Water zone (below OWC): So=%.2f, Sw=%.2f, Sg=%.2f\n', 0.0, 1.0, 0.0);
        
        % Initialize solution gas ratio
        state.rs = initial_gor * scf_to_m3 / stb_to_m3 * ones(G.cells.num, 1);
        
        % Initialize vaporized oil in gas (minimal for black oil)
        state.rv = zeros(G.cells.num, 1);
        
        fprintf('  [OK] Solution GOR initialized: %.0f scf/STB\n', initial_gor);
        
        %% STEP 7: VALIDATION AND MATERIAL BALANCE
        fprintf('\n[STEP 7] Validating fluid system and material balance...\n');
        
        validation_passed = true;
        validation_errors = {};
        
        % Saturation validation
        saturation_sums = sum(state.s, 2);
        if any(abs(saturation_sums - 1.0) > 1e-6)
            validation_errors{end+1} = 'Saturation normalization error detected';
            validation_passed = false;
        end
        
        if any(state.s(:) < 0) || any(state.s(:) > 1)
            validation_errors{end+1} = 'Invalid saturation values detected';
            validation_passed = false;
        end
        
        % Pressure validation
        if any(state.pressure <= 0)
            validation_errors{end+1} = 'Invalid pressure values detected';
            validation_passed = false;
        end
        
        % Check bubble point condition
        cells_above_bubble = sum(state.pressure > bubble_point_Pa);
        if cells_above_bubble ~= sum(cell_depths_m <= owc_depth_m)
            fprintf('  [WARN] Some cells may be at/below bubble point pressure\n');
        end
        
        % Material balance check
        oil_cells = cell_depths_m <= owc_depth_m;
        water_cells = cell_depths_m > owc_depth_m;
        
        total_pore_volume = sum(G.cells.volumes .* rock.poro);
        oil_pore_volume = sum(G.cells.volumes(oil_cells) .* rock.poro(oil_cells) .* state.s(oil_cells, 2));
        water_pore_volume = sum(G.cells.volumes .* rock.poro .* state.s(:, 1));
        
        material_balance_error = abs(total_pore_volume - oil_pore_volume - water_pore_volume) / total_pore_volume;
        
        fprintf('  --> Material balance error: %.2e (%.4f%%)\n', material_balance_error, material_balance_error * 100);
        
        if material_balance_error > 0.01
            validation_errors{end+1} = sprintf('Material balance error too large: %.2e', material_balance_error);
            validation_passed = false;
        end
        
        if validation_passed
            fprintf('  [OK] All validations passed\n');
        else
            fprintf('  [FAIL] Validation errors:\n');
            for i = 1:length(validation_errors)
                fprintf('    - %s\n', validation_errors{i});
            end
        end
        
        %% STEP 8: FLUID SYSTEM SUMMARY
        fprintf('\n[STEP 8] Fluid system statistics and summary...\n');
        
        % Pressure statistics
        pressure_psi = state.pressure / psi_to_Pa;
        fprintf('  Pressure Statistics:\n');
        fprintf('    Range: %.0f - %.0f psi (%.2f - %.2f MPa)\n', ...
                min(pressure_psi), max(pressure_psi), min(state.pressure)/1e6, max(state.pressure)/1e6);
        fprintf('    Datum pressure: %.0f psi @ %.0f ft\n', initial_pressure_psi, datum_depth_ft);
        fprintf('    OWC pressure: %.0f psi @ %.0f ft\n', ...
                mean(pressure_psi(abs(cell_depths_ft - owc_depth_ft) < 10)), owc_depth_ft);
        
        % Saturation statistics
        fprintf('  Saturation Statistics:\n');
        fprintf('    Water: %.3f - %.3f (avg: %.3f)\n', min(state.s(:,1)), max(state.s(:,1)), mean(state.s(:,1)));
        fprintf('    Oil: %.3f - %.3f (avg: %.3f)\n', min(state.s(:,2)), max(state.s(:,2)), mean(state.s(:,2)));
        fprintf('    Gas: %.3f - %.3f (avg: %.3f)\n', min(state.s(:,3)), max(state.s(:,3)), mean(state.s(:,3)));
        
        % Phase volumes
        oil_volume_m3 = sum(G.cells.volumes .* rock.poro .* state.s(:,2));
        water_volume_m3 = sum(G.cells.volumes .* rock.poro .* state.s(:,1));
        oil_volume_bbl = oil_volume_m3 / stb_to_m3;
        water_volume_bbl = water_volume_m3 / stb_to_m3;
        
        fprintf('  Phase Volumes:\n');
        fprintf('    Oil: %.0f m³ (%.0f bbl)\n', oil_volume_m3, oil_volume_bbl);
        fprintf('    Water: %.0f m³ (%.0f bbl)\n', water_volume_m3, water_volume_bbl);
        fprintf('    Total pore volume: %.0f m³ (%.0f bbl)\n', total_pore_volume, total_pore_volume / stb_to_m3);
        
        % Fluid contacts verification
        oil_zone_cells = sum(oil_cells);
        water_zone_cells = sum(water_cells);
        
        fprintf('  Fluid Contact Verification:\n');
        fprintf('    Oil zone cells: %d (%.1f%% of total)\n', oil_zone_cells, oil_zone_cells/G.cells.num*100);
        fprintf('    Water zone cells: %d (%.1f%% of total)\n', water_zone_cells, water_zone_cells/G.cells.num*100);
        fprintf('    OWC depth: %.0f ft (%.1f m)\n', owc_depth_ft, owc_depth_m);
        
        %% FINAL OUTPUT
        duration = toc(fluid_start_time);
        
        fprintf('\n=================================================================\n');
        fprintf('  FLUID SYSTEM SETUP SUMMARY\n');
        fprintf('=================================================================\n');
        fprintf('Status: COMPLETED\n');
        fprintf('Duration: %.2f seconds\n', duration);
        fprintf('Fluid Model: 3-phase black oil (Oil-Water-Gas)\n');
        fprintf('Oil: %.0f° API, GOR %.0f scf/STB, Pb %.0f psi\n', api_gravity, initial_gor, bubble_point_psi);
        fprintf('Initial State: Hydrostatic equilibrium, OWC at %.0f ft\n', owc_depth_ft);
        fprintf('Material Balance: %.2e error (%.4f%%)\n', material_balance_error, material_balance_error * 100);
        fprintf('Validation: %s\n', iff(validation_passed, 'PASSED', 'FAILED'));
        
        if validation_passed
            fprintf('\n[OK] FLUID SYSTEM SETUP COMPLETED SUCCESSFULLY\n');
            fprintf('--> Ready to proceed to well implementation and simulation\n');
        else
            fprintf('\n[FAIL] FLUID SYSTEM SETUP COMPLETED WITH ERRORS\n');
            fprintf('--> Review validation errors before proceeding\n');
        end
        
        fprintf('=================================================================\n\n');
        
    catch ME
        % Handle fluid system setup errors
        fprintf('\n[FAIL] FLUID SYSTEM SETUP FAILED\n');
        fprintf('Error: %s\n', ME.message);
        if ~isempty(ME.stack)
            fprintf('Location: %s (line %d)\n', ME.stack(1).name, ME.stack(1).line);
        end
        
        % Return empty structures on failure
        fluid = [];
        state = [];
        
        rethrow(ME);
    end
end

function kro = stone_model_ii(so, sw, sg, krOW_func, krOG_func, swcr, sgcr, sowcr, sogcr)
% Stone's Model II for three-phase oil relative permeability
    
    % Normalize saturations
    sw_norm = (sw - swcr) / (1 - swcr - sowcr);
    sg_norm = (sg - sgcr) / (1 - sgcr - sogcr);
    
    % Calculate two-phase relative permeabilities
    krOW = krOW_func(so);
    krOG = krOG_func(so);
    
    % Stone's Model II equation
    if so > max(sowcr, sogcr)
        kro = krOW .* krOG;
    else
        kro = 0;
    end
    
    % Ensure non-negative values
    kro = max(kro, 0);
end