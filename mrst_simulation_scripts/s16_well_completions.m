function completion_results = s16_well_completions()
% S16_WELL_COMPLETIONS - Well Completion Design for Eagle West Field
% Requires: MRST
%
% Creates well completions with:
% - Wellbore radius from YAML configuration
% - Skin factors from well placement
% - Well indices calculation (Peaceman model)
% - Completion intervals per well from documentation
% - Layer-specific completions (Upper/Middle/Lower Sand)
%
% OUTPUTS:
%   completion_results - Structure with completion design results
%
% Author: Claude Code AI System
% Date: August 22, 2025

    script_dir = fileparts(mfilename('fullpath'));
    addpath(fullfile(script_dir, 'utils')); 
    addpath(fullfile(script_dir, 'utils', 'completions'));
    run(fullfile(script_dir, 'utils', 'print_utils.m'));

    % Add MRST session validation
    [success, message] = validate_mrst_session(script_dir);
    if ~success
        error('MRST validation failed: %s', message);
    end
    print_step_header('S16', 'Well Completion Design');
    
    total_start_time = tic;
    completion_results = initialize_completion_structure();
    
    try
        % Step 1 - Load Wells and Rock Properties
        step_start = tic;
        [wells_data, rock_props, G, wells_config, init_config] = load_wells_and_properties();
        completion_results.wells_data = wells_data;
        completion_results.rock_props = rock_props;
        print_step_result(1, 'Load Wells and Properties', 'success', toc(step_start));
        
        % Step 2 - Design Wellbore Completions
        step_start = tic;
        wellbore_design = design_wellbore_completions(wells_data, wells_config, init_config);
        completion_results.wellbore_design = wellbore_design;
        print_step_result(2, 'Design Wellbore Completions', 'success', toc(step_start));
        
        % Step 3 - Calculate Well Indices (Peaceman)
        step_start = tic;
        well_indices = calculate_well_indices_peaceman(wells_data, rock_props, G, init_config);
        completion_results.well_indices = well_indices;
        print_step_result(3, 'Calculate Well Indices', 'success', toc(step_start));
        
        % Step 4 - Define Completion Intervals
        step_start = tic;
        completion_intervals = define_completion_intervals(wells_data, G, wells_config);
        completion_results.completion_intervals = completion_intervals;
        print_step_result(4, 'Define Completion Intervals', 'success', toc(step_start));
        
        % Step 5 - Create MRST Well Structures
        step_start = tic;
        mrst_wells = create_mrst_well_structures(wells_data, well_indices, G, init_config, wells_config);
        completion_results.mrst_wells = mrst_wells;
        print_step_result(5, 'Create MRST Well Structures', 'success', toc(step_start));
        
        % Step 6 - Export Completion Data
        step_start = tic;
        export_path = export_completion_results(completion_results);
        completion_results.export_path = export_path;
        print_step_result(6, 'Export Completion Data', 'success', toc(step_start));
        
        completion_results.status = 'success';
        completion_results.total_wells = length([completion_results.wells_data.producer_wells; ...
                                                 completion_results.wells_data.injector_wells]);
        completion_results.creation_time = datestr(now);
        
        print_step_footer('S16', sprintf('Well Completions Designed (%d wells)', ...
            completion_results.total_wells), toc(total_start_time));
        
    catch ME
        print_error_step(0, 'Well Completions', ME.message);
        completion_results.status = 'failed';
        completion_results.error_message = ME.message;
        error('Well completion design failed: %s', ME.message);
    end

end

function completion_results = initialize_completion_structure()
% Initialize well completion results structure
    completion_results = struct();
    completion_results.status = 'initializing';
    completion_results.wellbore_design = [];
    completion_results.well_indices = [];
    completion_results.completion_intervals = [];
    completion_results.mrst_wells = [];
end

% Main execution when called as script
if ~nargout
    completion_results = s16_well_completions();
end