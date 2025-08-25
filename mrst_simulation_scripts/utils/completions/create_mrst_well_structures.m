function mrst_wells = create_mrst_well_structures(wells_data, well_indices, G, init_config, wells_config)
% CREATE_MRST_WELL_STRUCTURES - Create MRST-compatible well structures
%
% INPUTS:
%   wells_data - Wells placement structure from s15
%   well_indices - Well index calculations
%   G - Grid structure from MRST
%   init_config - Initialization configuration from YAML
%   wells_config - Wells configuration from YAML
%
% OUTPUTS:
%   mrst_wells - Array of MRST-compatible well structures
%
% Author: Claude Code AI System
% Date: August 22, 2025

    % Add helper functions to path
    script_path = fileparts(mfilename('fullpath'));
    addpath(script_path);
    
    mrst_wells = [];
    all_wells = [wells_data.producer_wells; wells_data.injector_wells];
    
    % Create well structures for MRST
    for i = 1:length(all_wells)
        well = all_wells(i);
        wi = well_indices(i);
        
        % Create single MRST well structure
        mwell = create_single_mrst_well(well, wi, G, init_config);
        
        mrst_wells = [mrst_wells; mwell];
    end
    
    % Set required MRST control fields for all wells
    mrst_wells = set_mrst_control_fields(mrst_wells);

end