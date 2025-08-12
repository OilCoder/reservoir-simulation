function create_well_completions()
% CREATE_WELL_COMPLETIONS - Create basic well completions file for S22

    data_dir = '/workspaces/claudeclean/data/simulation_data/static';
    
    % Create basic completion_results structure expected by S22
    completion_results = struct();
    
    % Create wells_data array (for now, empty as we have no wells)
    completion_results.wells_data = [];
    
    % Basic Eagle West field specification (15 wells planned)
    completion_results.total_wells = 0; % No wells for basic simulation
    completion_results.completion_status = 'no_wells';
    completion_results.field_name = 'Eagle West';
    
    % Save the well completions
    completions_file = fullfile(data_dir, 'well_completions.mat');
    save(completions_file, 'completion_results');
    
    fprintf('Created basic well completions file (no wells for initial simulation)\n');
    
end