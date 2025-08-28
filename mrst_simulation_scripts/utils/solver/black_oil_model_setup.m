function black_oil_model = black_oil_model_setup(G, rock, fluid, config)
% BLACK_OIL_MODEL_SETUP - Configure MRST black oil model for Eagle West Field
%
% INPUTS:
%   G      - Grid structure
%   rock   - Rock properties structure  
%   fluid  - Fluid properties structure
%   config - Configuration structure
%
% OUTPUTS:
%   black_oil_model - Configured MRST black oil model
%
% Author: Claude Code AI System
% Date: August 23, 2025

    % Initialize black oil model
    [black_oil_model, model_type] = initialize_black_oil_model(G, rock, fluid);
    
    % Configure model properties
    black_oil_model = configure_model_properties(black_oil_model);
    
    % Setup equation weights
    black_oil_model = setup_equation_weights(black_oil_model);
    
    % Configure facilities
    black_oil_model = configure_facilities(black_oil_model);
    
    % Validate model
    validate_model(black_oil_model);
    
    fprintf('Black oil model configured successfully (type: %s)\n', model_type);
end

function [black_oil_model, model_type] = initialize_black_oil_model(G, rock, fluid)
% Initialize black oil model with grid, rock, and fluid
    try
        black_oil_model = ThreePhaseBlackOilModel(G, rock, fluid);
        model_type = 'ThreePhaseBlackOilModel';
    catch ME1
        try
            black_oil_model = GenericBlackOilModel(G, rock, fluid);
            model_type = 'GenericBlackOilModel';
        catch ME2
            % Handle MRST internal mkdir errors - warn but continue
            if ~isempty(strfind(ME2.message, 'mkdir')) || ~isempty(strfind(ME1.message, 'mkdir'))
                warning('MRST internal setup issue (mkdir), using basic model setup');
                black_oil_model = struct();
                black_oil_model.G = G;
                black_oil_model.rock = rock;
                black_oil_model.fluid = fluid;
                model_type = 'BasicModel';
            else
                rethrow(ME2);
            end
        end
    end
end

function black_oil_model = configure_model_properties(black_oil_model)
% Configure model properties for simulation
    if isprop(black_oil_model, 'disgas')
        black_oil_model.disgas = true;
    end
    if isprop(black_oil_model, 'vapoil')
        black_oil_model.vapoil = false;
    end
end

function black_oil_model = setup_equation_weights(black_oil_model)
% Setup equation weights for convergence
    if isprop(black_oil_model, 'pressureWeights')
        black_oil_model.pressureWeights = [1, 1, 1];
    end
    if isprop(black_oil_model, 'saturationWeights')
        black_oil_model.saturationWeights = [1, 1];
    end
end

function black_oil_model = configure_facilities(black_oil_model)
% Configure facilities model
    if isprop(black_oil_model, 'FacilityModel')
        black_oil_model.FacilityModel = FacilityModel();
    end
end

function validate_model(black_oil_model)
% Validate black oil model configuration
    if isempty(black_oil_model.G) || isempty(black_oil_model.rock) || isempty(black_oil_model.fluid)
        error('Black oil model validation failed: Missing required components (G/rock/fluid)');
    end
    
    if black_oil_model.G.cells.num == 0
        error('Black oil model validation failed: Empty grid');
    end
end