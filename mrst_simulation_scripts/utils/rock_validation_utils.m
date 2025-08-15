function rock_validation_utils()
% ROCK_VALIDATION_UTILS - Shared validation functions for rock properties
% Eliminates duplicate validation code across s06-s08 workflow
%
% FUNCTIONS:
%   validate_rock_dimensions(rock, G) - Check rock array sizes match grid
%   validate_property_ranges(rock) - Check porosity/permeability ranges
%   validate_mrst_compatibility(rock) - Check MRST structure compliance
%   validate_layer_metadata(rock) - Check layer information completeness
%
% Author: Claude Code AI System
% Date: August 14, 2025

    % This function serves as a container for shared validation utilities
    % Individual validation functions are defined below
end

function validate_rock_dimensions(rock, G)
% Validate rock array dimensions match grid structure
    
    % Check required fields exist
    required_fields = {'perm', 'poro'};
    for i = 1:length(required_fields)
        if ~isfield(rock, required_fields{i})
            error('Missing required rock field: %s', required_fields{i});
        end
    end
    
    % Validate permeability array dimensions
    if size(rock.perm, 1) ~= G.cells.num
        error('Rock permeability array size (%d) does not match grid cells (%d)', ...
              size(rock.perm, 1), G.cells.num);
    end
    
    % Validate porosity array dimensions
    if length(rock.poro) ~= G.cells.num
        error('Rock porosity array size (%d) does not match grid cells (%d)', ...
              length(rock.poro), G.cells.num);
    end
    
end

function validate_property_ranges(rock)
% Validate porosity and permeability value ranges
    
    % Validate porosity ranges [0,1]
    if any(rock.poro < 0) || any(rock.poro > 1)
        invalid_count = sum(rock.poro < 0 | rock.poro > 1);
        error('Invalid porosity values detected: %d cells outside range [0,1]', invalid_count);
    end
    
    % Validate permeability values (must be positive)
    if any(rock.perm(:) <= 0)
        invalid_count = sum(rock.perm(:) <= 0);
        error('Invalid permeability values detected: %d values <= 0', invalid_count);
    end
    
    % Check for NaN or Inf values
    if any(isnan(rock.poro)) || any(isinf(rock.poro))
        error('Invalid porosity values: NaN or Inf detected');
    end
    
    if any(isnan(rock.perm(:))) || any(isinf(rock.perm(:)))
        error('Invalid permeability values: NaN or Inf detected');
    end
    
end

function validate_mrst_compatibility(rock)
% Validate MRST structure compatibility
    
    % Check permeability tensor format (should be Nx3 for 3D)
    if size(rock.perm, 2) ~= 3
        error('Permeability tensor must be Nx3 for 3D MRST compatibility');
    end
    
    % Ensure porosity is column vector
    if size(rock.poro, 2) ~= 1
        error('Porosity must be column vector for MRST compatibility');
    end
    
    % Check for MRST metadata structure
    if isfield(rock, 'meta')
        if ~isstruct(rock.meta)
            error('Rock metadata must be structure for MRST compatibility');
        end
    end
    
end

function validate_layer_metadata(rock)
% Validate layer metadata completeness (for enhanced rock structures)
    
    % Check if metadata exists
    if ~isfield(rock, 'meta')
        error('Enhanced rock structure missing metadata field');
    end
    
    % Check layer information
    if ~isfield(rock.meta, 'layer_info')
        error('Enhanced rock structure missing layer_info in metadata');
    end
    
    layer_info = rock.meta.layer_info;
    
    % Validate required layer fields
    required_layer_fields = {'n_layers', 'porosity_by_layer', 'permeability_by_layer'};
    for i = 1:length(required_layer_fields)
        if ~isfield(layer_info, required_layer_fields{i})
            error('Missing required layer field: %s', required_layer_fields{i});
        end
    end
    
    % Validate layer array consistency
    n_layers = layer_info.n_layers;
    if length(layer_info.porosity_by_layer) ~= n_layers
        error('Layer porosity array length inconsistent with n_layers');
    end
    
    if length(layer_info.permeability_by_layer) ~= n_layers
        error('Layer permeability array length inconsistent with n_layers');
    end
    
end

function validate_simulation_readiness(rock)
% Validate final rock structure is simulation-ready
    
    % Check simulation metadata exists
    if ~isfield(rock.meta, 'simulation_ready')
        error('Final rock structure missing simulation_ready metadata');
    end
    
    sim_ready = rock.meta.simulation_ready;
    
    % Check status
    if ~isfield(sim_ready, 'status') || ~strcmp(sim_ready.status, 'READY')
        error('Rock structure not marked as simulation-ready');
    end
    
    % Check MRST compatibility flags
    if isfield(rock.meta, 'mrst_compatibility')
        compat = rock.meta.mrst_compatibility;
        required_flags = {'ad_blackoil_ready', 'incomp_ready'};
        for i = 1:length(required_flags)
            if ~isfield(compat, required_flags{i}) || ~compat.(required_flags{i})
                error('Rock structure not ready for MRST %s', required_flags{i});
            end
        end
    end
    
end

function validate_heterogeneity_application(rock)
% Validate spatial heterogeneity has been properly applied
    
    % Check heterogeneity metadata
    if ~isfield(rock.meta, 'heterogeneity_applied') || ~rock.meta.heterogeneity_applied
        error('Spatial heterogeneity not properly applied to rock structure');
    end
    
    % Check for geostatistics method
    if ~isfield(rock.meta, 'geostatistics_method')
        error('Missing geostatistics method in heterogeneity metadata');
    end
    
    % Validate policy compliance for heterogeneity
    if isfield(rock.meta, 'policy_compliance')
        policy = rock.meta.policy_compliance;
        if ~policy.yaml_driven
            error('Heterogeneity application violates YAML-driven policy');
        end
    end
    
end