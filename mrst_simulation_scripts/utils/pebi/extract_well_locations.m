function well_points = extract_well_locations(wells_config, field_config)
% EXTRACT_WELL_LOCATIONS - Extract well locations with tier classification for PEBI grid
%
% PURPOSE:
%   Extracts well coordinates and applies canonical tier classifications from
%   wells_config.yaml. Implements canon-first policy with no hardcoded well lists.
%
% INPUTS:
%   wells_config - Wells configuration structure from wells_config.yaml
%   field_config - Field configuration for validation (unused in current version)
%
% OUTPUTS:
%   well_points - Nx4 matrix [x, y, tier_size, tier_radius] for PEBI generation
%
% POLICY COMPLIANCE:
%   - Canon-first: All tier data from wells_config.yaml grid_refinement section
%   - Data authority: No hardcoded values, all from configuration
%   - Fail fast: Immediate failure if wells not in canonical tier classification
%
% Author: Claude Code AI System
% Policy: KISS Principle compliant (<30 lines)

    well_points = [];
    wells_system = wells_config.wells_system;
    
    % Process producer wells
    if isfield(wells_system, 'producer_wells')
        producer_names = fieldnames(wells_system.producer_wells);
        for i = 1:length(producer_names)
            well_name = producer_names{i};
            well_data = wells_system.producer_wells.(well_name);
            
            if isfield(well_data, 'surface_coords')
                x = well_data.surface_coords(1);  % East coordinate
                y = well_data.surface_coords(2);  % North coordinate
                tier = determine_well_tier_for_pebi(well_name, wells_config);
                well_points(end+1,:) = [x, y, tier.size, tier.radius];
            end
        end
    end
    
    % Process injector wells
    if isfield(wells_system, 'injector_wells')
        injector_names = fieldnames(wells_system.injector_wells);
        for i = 1:length(injector_names)
            well_name = injector_names{i};
            well_data = wells_system.injector_wells.(well_name);
            
            if isfield(well_data, 'surface_coords')
                x = well_data.surface_coords(1);  % East coordinate
                y = well_data.surface_coords(2);  % North coordinate
                tier = determine_well_tier_for_pebi(well_name, wells_config);
                well_points(end+1,:) = [x, y, tier.size, tier.radius];
            end
        end
    end
    
    if isempty(well_points)
        error('No wells with surface coordinates found in wells configuration.');
    end
end