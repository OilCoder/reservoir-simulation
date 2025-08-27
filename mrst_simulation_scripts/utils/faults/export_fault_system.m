function fault_data = export_fault_system(G, fault_geometries, fault_intersections, trans_multipliers)
% EXPORT_FAULT_SYSTEM - Export fault system data and create output structure
%
% POLICY COMPLIANCE:
%   - Canon-first: Updates canonical grid.mat file
%   - Fail-fast: Validates fault system before export
%
% Author: Claude Code (Policy-compliant refactor)
% Date: 2025-08-22

    % Validate, export, and create output
    validate_fault_system(fault_geometries, trans_multipliers);
    export_to_canonical_files(G, fault_geometries, fault_intersections, trans_multipliers);
    fault_data = create_output_structure(G, fault_geometries, fault_intersections, trans_multipliers);

end

function validate_fault_system(fault_geometries, trans_multipliers)
% Validate fault system implementation with fail-fast approach
    
    n_faults = length(fault_geometries);
    
    % Validate fault geometries
    for f = 1:n_faults
        fault = fault_geometries(f);
        
        if fault.length <= 0
            error('Fault %s has invalid length: %.1f', fault.name, fault.length);
        end
        
        if fault.trans_mult <= 0 || fault.trans_mult > 1
            error('Fault %s has invalid transmissibility multiplier: %.3f', ...
                fault.name, fault.trans_mult);
        end
    end
    
    % Validate transmissibility multipliers
    if any(trans_multipliers < 0) || any(trans_multipliers > 1)
        error('Invalid transmissibility multipliers detected in range [%.3f, %.3f]', ...
            min(trans_multipliers), max(trans_multipliers));
    end

end

function export_to_canonical_files(G, fault_geometries, fault_intersections, trans_multipliers)
% Export fault data to canonical file location and simulation data catalog
    
    % CATALOG STRUCTURE: Save to /workspace/data/simulation_data/
    data_dir = '/workspace/data/simulation_data';
    if ~exist(data_dir, 'dir')
        mkdir(data_dir);
    end
    
    % Create fault_properties.mat according to catalog specification
    fault_properties_file = fullfile(data_dir, 'fault_properties.mat');
    
    % Fault Geometry (Section 6 of catalog)
    n_faults = length(fault_geometries);
    fault_cells = zeros(n_faults, 2);
    fault_normals = zeros(n_faults, 3);
    fault_areas = zeros(n_faults, 1);
    trans_multiplier = zeros(n_faults, 1);
    fault_aperture = zeros(n_faults, 1);
    fault_permeability = zeros(n_faults, 1);
    friction_coefficient = zeros(n_faults, 1);
    cohesion = zeros(n_faults, 1);
    stress_ratio = zeros(n_faults, 1);
    
    for f = 1:n_faults
        fault = fault_geometries(f);
        trans_multiplier(f) = fault.trans_mult;
        fault_aperture(f) = fault.aperture;
        fault_permeability(f) = fault.permeability;
        friction_coefficient(f) = fault.friction;
        cohesion(f) = fault.cohesion;
        stress_ratio(f) = fault.stress_ratio;
        fault_areas(f) = fault.area;
        
        % Extract fault normals and cell pairs from geometry
        if isfield(fault, 'normal_vector')
            fault_normals(f, :) = fault.normal_vector;
        end
        if isfield(fault, 'cell_pairs')
            fault_cells(f, :) = fault.cell_pairs(1, :);
        end
    end
    
    % Save catalog-compliant fault properties
    save(fault_properties_file, 'fault_cells', 'fault_normals', 'fault_areas', ...
         'trans_multiplier', 'fault_aperture', 'fault_permeability', ...
         'friction_coefficient', 'cohesion', 'stress_ratio', ...
         'fault_geometries', 'fault_intersections', '-v7');
    
    fprintf('     Fault properties saved to catalog location: %s\n', fault_properties_file);
    
    % Legacy canonical file update
    canonical_file = '/workspace/data/mrst/grid.mat';
    
    % Load existing canonical data or create new
    if exist(canonical_file, 'file')
        load(canonical_file, 'data_struct');
    else
        data_struct = struct();
        data_struct.created_by = {};
    end
    
    % Add fault information to canonical structure
    data_struct.structure.faults = fault_geometries;
    data_struct.fault_grid = G;
    data_struct.created_by{end+1} = 's05';
    data_struct.timestamp = datestr(now);
    
    % Save updated canonical structure
    save(canonical_file, 'data_struct');
    
    % Report export results
    sealing_count = count_sealing_faults(fault_geometries);
    fprintf('     Legacy canonical: Grid with fault system updated in %s\n', canonical_file);
    fprintf('     Fault system: %d total, %d sealing\n', length(fault_geometries), sealing_count);

end

function sealing_count = count_sealing_faults(fault_geometries)
% Count sealing faults using standard threshold
    sealing_count = 0;
    for i = 1:length(fault_geometries)
        if fault_geometries(i).trans_mult <= 0.01
            sealing_count = sealing_count + 1;
        end
    end
end

function fault_data = create_output_structure(G, fault_geometries, fault_intersections, trans_multipliers)
% Create final output structure
    fault_data = struct();
    fault_data.grid = G;
    fault_data.geometries = fault_geometries;
    fault_data.intersections = fault_intersections;
    fault_data.transmissibility_multipliers = trans_multipliers;
    fault_data.status = 'completed';
end