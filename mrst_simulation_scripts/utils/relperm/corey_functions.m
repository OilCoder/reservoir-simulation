function [krW_func, krO_func, krG_func, krOG_func] = corey_functions()
% COREY_FUNCTIONS - Collection of Corey relative permeability functions
%
% OUTPUTS:
%   krW_func  - Water relative permeability function
%   krO_func  - Oil relative permeability function (oil-water)
%   krG_func  - Gas relative permeability function
%   krOG_func - Oil relative permeability function (gas-oil)
%
% Author: Claude Code AI System
% Date: August 23, 2025

    % Return function handles for each relative permeability curve
    krW_func = @create_water_relperm_function;
    krO_func = @create_oil_water_relperm_function;
    krG_func = @create_gas_relperm_function;
    krOG_func = @create_oil_gas_relperm_function;
end

function krW_func = create_water_relperm_function(params)
% Create water relative permeability function
    swc = params.connate_water_saturation;
    sor = params.residual_oil_saturation;
    krw_max = params.water_relperm_max;
    nw = params.water_corey_exponent;
    
    krW_func = @(sw) water_relperm_corey(sw, swc, sor, krw_max, nw);
end

function krO_func = create_oil_water_relperm_function(params)
% Create oil relative permeability function (oil-water system)
    swc = params.connate_water_saturation;
    sor = params.residual_oil_saturation;
    kro_max = params.oil_relperm_max;
    no = params.oil_corey_exponent;
    
    krO_func = @(sw) oil_water_relperm_corey(sw, swc, sor, kro_max, no);
end

function krG_func = create_gas_relperm_function(params)
% Create gas relative permeability function
    sgc = params.critical_gas_saturation;
    sorg = params.residual_oil_to_gas;
    krg_max = params.gas_relperm_max;
    ng = params.gas_corey_exponent;
    
    krG_func = @(sg) gas_relperm_corey(sg, sgc, sorg, krg_max, ng);
end

function krOG_func = create_oil_gas_relperm_function(params)
% Create oil relative permeability function (gas-oil system)
    sgc = params.critical_gas_saturation;
    sorg = params.residual_oil_to_gas;
    krog_max = params.oil_gas_relperm_max;
    nog = params.oil_gas_corey_exponent;
    
    krOG_func = @(sg) oil_gas_relperm_corey(sg, sgc, sorg, krog_max, nog);
end

function dkrW_func = create_water_relperm_derivative(params)
% Create water relative permeability derivative function
    swc = params.connate_water_saturation;
    sor = params.residual_oil_saturation;
    krw_max = params.water_relperm_max;
    nw = params.water_corey_exponent;
    
    dkrW_func = @(sw) water_relperm_derivative(sw, swc, sor, krw_max, nw);
end

function dkrO_func = create_oil_water_relperm_derivative(params)
% Create oil relative permeability derivative function (oil-water)
    swc = params.connate_water_saturation;
    sor = params.residual_oil_saturation;
    kro_max = params.oil_relperm_max;
    no = params.oil_corey_exponent;
    
    dkrO_func = @(sw) oil_water_relperm_derivative(sw, swc, sor, kro_max, no);
end

function dkrG_func = create_gas_relperm_derivative(params)
% Create gas relative permeability derivative function
    sgc = params.critical_gas_saturation;
    sorg = params.residual_oil_to_gas;
    krg_max = params.gas_relperm_max;
    ng = params.gas_corey_exponent;
    
    dkrG_func = @(sg) gas_relperm_derivative(sg, sgc, sorg, krg_max, ng);
end

function dkrOG_func = create_oil_gas_relperm_derivative(params)
% Create oil relative permeability derivative function (gas-oil)
    sgc = params.critical_gas_saturation;
    sorg = params.residual_oil_to_gas;
    krog_max = params.oil_gas_relperm_max;
    nog = params.oil_gas_corey_exponent;
    
    dkrOG_func = @(sg) oil_gas_relperm_derivative(sg, sgc, sorg, krog_max, nog);
end

% Core Corey correlation implementations
function kr = water_relperm_corey(sw, swc, sor, krw_max, nw)
% Water relative permeability using Corey correlation
    swe = max(0, (sw - swc) ./ (1 - swc - sor));
    kr = krw_max .* swe.^nw;
    kr(sw < swc) = 0;
end

function kr = oil_water_relperm_corey(sw, swc, sor, kro_max, no)
% Oil relative permeability using Corey correlation (oil-water system)
    soe = max(0, (1 - sw - sor) ./ (1 - swc - sor));
    kr = kro_max .* soe.^no;
    kr(sw > (1 - sor)) = 0;
end

function kr = gas_relperm_corey(sg, sgc, sorg, krg_max, ng)
% Gas relative permeability using Corey correlation
    sge = max(0, (sg - sgc) ./ (1 - sgc - sorg));
    kr = krg_max .* sge.^ng;
    kr(sg < sgc) = 0;
end

function kr = oil_gas_relperm_corey(sg, sgc, sorg, krog_max, nog)
% Oil relative permeability using Corey correlation (gas-oil system)
    soe = max(0, (1 - sg - sorg) ./ (1 - sgc - sorg));
    kr = krog_max .* soe.^nog;
    kr(sg > (1 - sorg)) = 0;
end

% Derivative implementations
function dkr = water_relperm_derivative(sw, swc, sor, krw_max, nw)
% Water relative permeability derivative
    swe = max(0, (sw - swc) ./ (1 - swc - sor));
    dkr = krw_max .* nw .* swe.^(nw-1) ./ (1 - swc - sor);
    dkr(sw < swc) = 0;
end

function dkr = oil_water_relperm_derivative(sw, swc, sor, kro_max, no)
% Oil relative permeability derivative (oil-water system)
    soe = max(0, (1 - sw - sor) ./ (1 - swc - sor));
    dkr = -kro_max .* no .* soe.^(no-1) ./ (1 - swc - sor);
    dkr(sw > (1 - sor)) = 0;
end

function dkr = gas_relperm_derivative(sg, sgc, sorg, krg_max, ng)
% Gas relative permeability derivative
    sge = max(0, (sg - sgc) ./ (1 - sgc - sorg));
    dkr = krg_max .* ng .* sge.^(ng-1) ./ (1 - sgc - sorg);
    dkr(sg < sgc) = 0;
end

function dkr = oil_gas_relperm_derivative(sg, sgc, sorg, krog_max, nog)
% Oil relative permeability derivative (gas-oil system)
    soe = max(0, (1 - sg - sorg) ./ (1 - sgc - sorg));
    dkr = -krog_max .* nog .* soe.^(nog-1) ./ (1 - sgc - sorg);
    dkr(sg > (1 - sorg)) = 0;
end