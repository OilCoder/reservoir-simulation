function fault_data = s05_add_faults()
% S05_ADD_FAULTS - Implement 5-fault system for Eagle West Field
%
% POLICY-COMPLIANT REFACTOR: Modular fault system implementation
% Uses utils/faults/ modules to satisfy policy line limits and KISS principle
%
% WORKFLOW: s01 → s02 → s03 → s04 → s05 → s06
% INPUTS: structural_framework.mat, fault_config.yaml, MRST session
% OUTPUTS: fault_data with enhanced grid, geometries, intersections, multipliers
%
% FEATURES: 5 major faults (Fault_A to Fault_E), compartmentalization, sealing
% POLICY: Canon-first data loading, fail-fast validation, no hardcoding
%
% Author: Claude Code (Policy-compliant refactor)
% Date: 2025-08-22

    % Initialize environment
    script_dir = fileparts(mfilename('fullpath'));
    addpath(fullfile(script_dir, 'utils')); 
    addpath(fullfile(script_dir, 'utils', 'faults'));
    run(fullfile(script_dir, 'utils', 'print_utils.m'));

    % Verify MRST session from s01
    if ~check_and_load_mrst_session()
        error('MRST session not found. Run s01_initialize_mrst.m first');
    end

    print_step_header('S05', 'Add Fault System');
    total_start_time = tic;
    
    try
        % Step 1: Load framework and define fault geometries
        step_start = tic;
        G = load_structural_framework();
        fault_geometries = define_fault_geometries(G);
        print_step_result(1, 'Load Framework and Define Faults', 'success', toc(step_start));
        
        % Step 2: Calculate intersections and transmissibility effects
        step_start = tic;
        fault_intersections = calculate_fault_intersections(G, fault_geometries);
        trans_multipliers = compute_transmissibility_effects(G, fault_intersections, fault_geometries);
        print_step_result(2, 'Calculate Fault Intersections', 'success', toc(step_start));
        
        % Step 3: Apply properties and export system
        step_start = tic;
        G = apply_fault_properties(G, fault_geometries, fault_intersections, trans_multipliers);
        print_step_result(3, 'Apply Fault Properties to Grid', 'success', toc(step_start));
        
        % Step 4: Save consolidated grid data
        step_start = tic;
        save_consolidated_data('grid', 's05', 'G', G, 'fault_geometries', fault_geometries, ...
                              'fault_intersections', fault_intersections, 'trans_multipliers', trans_multipliers);
        fault_data = create_fault_output_structure(G, fault_geometries, fault_intersections, trans_multipliers);
        print_step_result(4, 'Save Consolidated Grid Data', 'success', toc(step_start));
        
        print_step_footer('S05', sprintf('Fault System Ready: %d faults', length(fault_geometries)), toc(total_start_time));
        
    catch ME
        print_error_step(0, 'Fault System', ME.message);
        error('Fault system failed: %s', ME.message);
    end

end

function fault_data = create_fault_output_structure(G, fault_geometries, fault_intersections, trans_multipliers)
% Create fault output structure for return value
    fault_data = struct();
    fault_data.grid = G;
    fault_data.geometries = fault_geometries;
    fault_data.intersections = fault_intersections;
    fault_data.transmissibility_multipliers = trans_multipliers;
    fault_data.status = 'completed';
end

% Script execution mode
if ~nargout
    fault_data = s05_add_faults();
    fprintf('Fault system implemented: %d major faults.\n', length(fault_data.geometries));
end