function export_path = export_completion_results(completion_results)
% EXPORT_COMPLETION_RESULTS - Export completion design data
%
% INPUTS:
%   completion_results - Complete completion results structure
%
% OUTPUTS:
%   export_path - Path to exported canonical MRST data
%
% Author: Claude Code AI System
% Date: August 22, 2025

    script_path = fileparts(fileparts(mfilename('fullpath')));
    
    % Add helper functions to path  
    completions_path = fileparts(mfilename('fullpath'));
    addpath(completions_path);
    
    % Update the canonical wells.mat file with completion data
    canonical_mrst_dir = '/workspace/data/mrst';
    
    % Load existing wells data from canonical MRST structure
    wells_file = fullfile(canonical_mrst_dir, 'wells.mat');
    if exist(wells_file, 'file')
        wells_vars = load(wells_file);  % Load all variables
        data_struct = struct();
        if isfield(wells_vars, 'wells_results')
            data_struct = wells_vars.wells_results;
        elseif isfield(wells_vars, 'W')
            data_struct.W = wells_vars.W;
        end
        if ~isfield(data_struct, 'created_by')
            data_struct.created_by = {'s15'};  % Previous script that created wells
        end
    else
        data_struct = struct();
        data_struct.created_by = {};
    end
    
    % Add completion data to existing wells structure
    data_struct.completions.intervals = completion_results.completion_intervals;
    data_struct.completions.skin = [completion_results.wellbore_design.wells.skin_factor];
    data_struct.completions.radius = completion_results.wellbore_design.standard_radius_ft;
    data_struct.completions.PI = [completion_results.well_indices.well_index];
    data_struct.W = completion_results.mrst_wells;
    data_struct.created_by{end+1} = 's16';
    data_struct.timestamp = datestr(now);
    
    % Save updated wells structure
    save(wells_file, 'data_struct');
    export_path = wells_file;
    fprintf('   ✅ Canonical MRST wells data updated: %s\n', export_path);
    
    % Save completion summary and well indices
    summary_file = fullfile(canonical_mrst_dir, 'completion_summary.txt');
    write_completion_summary_file(summary_file, completion_results);
    
    wi_file = fullfile(canonical_mrst_dir, 'well_indices.txt');
    write_well_indices_file(wi_file, completion_results);

end