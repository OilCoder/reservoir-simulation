function write_well_indices_file(filename, completion_results)
% WRITE_WELL_INDICES_FILE - Write well indices data in CSV format
%
% INPUTS:
%   filename - Output file path
%   completion_results - Complete completion results structure
%
% Author: Claude Code AI System
% Date: August 22, 2025

    fid = fopen(filename, 'w');
    if fid == -1
        error('Cannot open file for writing: %s', filename);
    end
    
    try
        % CSV header
        fprintf(fid, 'Well_Name,Type,Well_Type,Well_Index,Perm_X_mD,Perm_Y_mD,Perm_Z_mD,Equivalent_Radius_m,Wellbore_Radius_m,Skin_Factor\n');
        
        % Well indices data
        for i = 1:length(completion_results.well_indices)
            wi = completion_results.well_indices(i);
            fprintf(fid, '%s,%s,%s,%.6e,%.1f,%.1f,%.1f,%.4f,%.4f,%.2f\n', ...
                wi.name, wi.type, wi.well_type, wi.well_index, ...
                wi.permeability_md(1), wi.permeability_md(2), wi.permeability_md(3), ...
                wi.equivalent_radius_m, wi.wellbore_radius_m, wi.skin_factor);
        end
        
        fclose(fid);
        
    catch ME
        fclose(fid);
        error('Error writing well indices file: %s', ME.message);
    end

end