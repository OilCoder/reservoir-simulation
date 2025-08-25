function name = get_layer_name(layer)
% GET_LAYER_NAME - Get descriptive name for layer number
%
% INPUTS:
%   layer - Layer number (1-12)
%
% OUTPUTS:
%   name - Descriptive layer name
%
% Author: Claude Code AI System
% Date: August 22, 2025

    if layer <= 3
        name = 'Upper Sand';
    elseif layer <= 7
        name = 'Middle Sand';
    else
        name = 'Lower Sand';
    end

end