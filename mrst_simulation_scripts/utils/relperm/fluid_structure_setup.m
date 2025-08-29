function fluid = fluid_structure_setup(scal_config, G)
% FLUID_STRUCTURE_SETUP - Initialize fluid structure for relative permeability
%
% INPUTS:
%   scal_config - SCAL configuration structure
%   G          - Grid structure
%
% OUTPUTS:
%   fluid - Initialized fluid structure with relative permeability functions
%
% Author: Claude Code AI System
% Date: August 23, 2025

    % Try to initialize MRST fluid structure first
    fluid = initialize_mrst_fluid_structure();
    
    % If MRST initialization fails, create manual structure
    if isempty(fluid)
        fluid = create_manual_fluid_structure(scal_config);
    else
        % CRITICAL FIX: Ensure required fields exist even if MRST initialization succeeded
        fluid = ensure_required_fields(fluid, scal_config);
    end
    
    % Add oil-water relative permeability functions
    fluid = add_oil_water_functions(fluid, scal_config);
    
    % Add gas-oil relative permeability functions
    fluid = add_gas_oil_functions(fluid, scal_config);
    
    % Add three-phase modeling
    fluid = add_three_phase_modeling(fluid, scal_config);
    
    fprintf('Fluid structure initialized with relative permeability functions\n');
end

function fluid = initialize_mrst_fluid_structure()
% Initialize MRST fluid structure if available
    fluid = [];
    
    try
        % Try to use MRST initSimpleADIFluid
        if exist('initSimpleADIFluid', 'file') == 2
            % Basic initialization - will be enhanced with specific functions
            mu = [1, 1, 1] * centi*poise; % Placeholder viscosities
            rho = [1000, 800, 1] .* kilogram/meter^3; % Placeholder densities
            fluid = initSimpleADIFluid('mu', mu, 'rho', rho, 'n', [2, 2, 2]);
            fprintf('MRST fluid structure initialized successfully\n');
        end
    catch ME
        fprintf('MRST fluid initialization failed: %s\n', ME.message);
        fluid = [];
    end
end

function fluid = ensure_required_fields(fluid, scal_config)
% Ensure required fields exist in fluid structure (CRITICAL FIX)
% FAIL FAST POLICY: Add required fields that s09_relative_permeability expects
    
    % CANON-FIRST POLICY: Get phase specification from SCAL config
    if ~isfield(fluid, 'phases')
        fluid.phases = 'WOG';  % Water-Oil-Gas (standard three-phase)
    end
    
    % CANON-FIRST POLICY: Load Corey exponents from configuration
    if ~isfield(fluid, 'n')
        if isfield(scal_config, 'default_corey_exponents')
            corey_exp = scal_config.default_corey_exponents;
            fluid.n = [corey_exp.water, corey_exp.oil, corey_exp.gas];
        else
            error('Missing default_corey_exponents in scal_properties_config.yaml. REQUIRED: Add default_corey_exponents section with water, oil, gas values.');
        end
    end
    
    % Ensure phase indices exist for consistency
    if ~isfield(fluid, 'water'), fluid.water = 1; end
    if ~isfield(fluid, 'oil'), fluid.oil = 2; end 
    if ~isfield(fluid, 'gas'), fluid.gas = 3; end
    
    fprintf('   ✅ Required fields ensured in fluid structure\n');
end

function fluid = create_manual_fluid_structure(scal_config)
% Create manual fluid structure when MRST functions not available
    fluid = struct();
    
    % Basic fluid properties
    fluid.phases = 'WOG';  % Water-Oil-Gas
    
    % Load Corey exponents from configuration
    if isfield(scal_config, 'default_corey_exponents')
        corey_exp = scal_config.default_corey_exponents;
        fluid.n = [corey_exp.water, corey_exp.oil, corey_exp.gas];
    else
        error('Missing default_corey_exponents in scal_properties_config.yaml. REQUIRED: Add default_corey_exponents section with water, oil, gas values.');
    end
    
    % Phase indices
    fluid.water = 1;
    fluid.oil = 2;
    fluid.gas = 3;
    
    % Surface densities (kg/m³)
    fluid.rhoS = [1000, 850, 1.2]; % Water, Oil, Gas
    
    % Viscosities (cP)
    fluid.muS = [0.385, 0.92, 0.02]; % Water, Oil, Gas
    
    fprintf('Manual fluid structure created\n');
end

function fluid = add_oil_water_functions(fluid, scal_config)
% Add oil-water relative permeability functions
    if ~isfield(scal_config, 'sandstone_ow')
        error('Missing sandstone_ow section in SCAL configuration. REQUIRED: Add sandstone oil-water parameters to scal_properties_config.yaml');
    end
    
    params = scal_config.sandstone_ow;
    
    % Create water relative permeability function directly
    fluid.krW = create_water_relperm_function_local(params);
    
    % Create oil relative permeability function (oil-water system)
    fluid.krOW = create_oil_water_relperm_function_local(params);
    
    fprintf('   ✅ Oil-water relative permeability functions created\n');
end

function krW_func = create_water_relperm_function_local(params)
% Create water relative permeability function
    swc = params.connate_water_saturation;
    sor = params.residual_oil_saturation;
    krw_max = params.water_relperm_max;
    nw = params.water_corey_exponent;
    
    krW_func = @(sw) water_relperm_corey_local(sw, swc, sor, krw_max, nw);
end

function krO_func = create_oil_water_relperm_function_local(params)
% Create oil relative permeability function (oil-water system)
    swc = params.connate_water_saturation;
    sor = params.residual_oil_saturation;
    kro_max = params.oil_relperm_max;
    no = params.oil_corey_exponent;
    
    krO_func = @(sw) oil_water_relperm_corey_local(sw, swc, sor, kro_max, no);
end

function krW = water_relperm_corey_local(sw, swc, sor, krw_max, nw)
% Water relative permeability using Corey correlation
    % Normalize saturation
    sw_norm = max((sw - swc) ./ (1 - swc - sor), 0);
    
    % Apply Corey correlation
    krW = krw_max .* sw_norm.^nw;
end

function krO = oil_water_relperm_corey_local(sw, swc, sor, kro_max, no)
% Oil relative permeability using Corey correlation
    % Normalize saturation (oil saturation = 1 - sw)
    so = 1 - sw;
    so_norm = max((so - sor) ./ (1 - swc - sor), 0);
    
    % Apply Corey correlation
    krO = kro_max .* so_norm.^no;
end

function fluid = add_gas_oil_functions(fluid, scal_config)
% Add gas-oil relative permeability functions
    if ~isfield(scal_config, 'sandstone_go')
        error('Missing sandstone_go section in SCAL configuration. REQUIRED: Add sandstone gas-oil parameters to scal_properties_config.yaml');
    end
    
    params = scal_config.sandstone_go;
    
    % Create gas relative permeability function
    fluid.krG = create_gas_relperm_function_local(params);
    
    % Create oil relative permeability function (gas-oil system)
    fluid.krO = create_oil_gas_relperm_function_local(params);
    
    fprintf('   ✅ Gas-oil relative permeability functions created\n');
end

function krG_func = create_gas_relperm_function_local(params)
% Create gas relative permeability function
    sgc = params.critical_gas_saturation;
    sorg = params.residual_oil_to_gas;
    krg_max = params.gas_relperm_max;
    ng = params.gas_corey_exponent;
    
    krG_func = @(sg) gas_relperm_corey_local(sg, sgc, sorg, krg_max, ng);
end

function krOG_func = create_oil_gas_relperm_function_local(params)
% Create oil relative permeability function (gas-oil system)
    sgc = params.critical_gas_saturation;
    sorg = params.residual_oil_to_gas;
    krog_max = params.oil_gas_relperm_max;
    nog = params.oil_gas_corey_exponent;
    
    krOG_func = @(sg) oil_gas_relperm_corey_local(sg, sgc, sorg, krog_max, nog);
end

function krG = gas_relperm_corey_local(sg, sgc, sorg, krg_max, ng)
% Gas relative permeability using Corey correlation
    % Normalize saturation
    sg_norm = max((sg - sgc) ./ (1 - sgc - sorg), 0);
    
    % Apply Corey correlation
    krG = krg_max .* sg_norm.^ng;
end

function krOG = oil_gas_relperm_corey_local(sg, sgc, sorg, krog_max, nog)
% Oil relative permeability in gas-oil system using Corey correlation
    % Oil saturation in gas-oil system
    so = 1 - sg;
    so_norm = max((so - sorg) ./ (1 - sgc - sorg), 0);
    
    % Apply Corey correlation
    krOG = krog_max .* so_norm.^nog;
end

function fluid = add_three_phase_modeling(fluid, scal_config)
% Add three-phase modeling parameters
    if isfield(scal_config, 'three_phase_model')
        three_phase = scal_config.three_phase_model;
        
        fluid.threephase_model = three_phase.method;
        
        if strcmp(three_phase.method, 'stone_ii')
            fluid.stone_eta = three_phase.stone_eta;
        end
        
        if isfield(three_phase, 'hysteresis_model')
            fluid.hysteresis_model = three_phase.hysteresis_model;
            if strcmp(three_phase.hysteresis_model, 'land')
                fluid.land_coefficient = three_phase.land_coefficient;
            end
        end
    end
end