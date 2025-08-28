function mwell = create_single_mrst_well(well, wi, G, init_config, wells_config)
% CREATE_SINGLE_MRST_WELL - Create single MRST-compatible well structure
%
% INPUTS:
%   well - Well structure from wells placement
%   wi - Well index structure
%   G - Grid structure from MRST
%   init_config - Initialization configuration from YAML
%
% OUTPUTS:
%   mwell - MRST-compatible well structure
%
% Author: Claude Code AI System
% Date: August 22, 2025

    mwell = struct();
    mwell.name = well.name;
    mwell.type = well.type;  % 'producer' or 'injector'
    
    % Well location and completion
    mwell.cells = well.cells;
    mwell.WI = wi.well_index;  % Well index from Peaceman calculation
    mwell.dir = 'z';  % Default direction
    mwell.r = wi.wellbore_radius_m;
    mwell.skin = wi.skin_factor;
    
    % Add completion layers if multiple
    if length(well.completion_layers) > 1
        [completion_cells, completion_WI] = find_completion_cells(well, wi, G);
        mwell.cells = completion_cells;
        mwell.WI = completion_WI;
    end
    
    % Set pressure limits and controls
    mwell = set_well_controls(mwell, well, init_config, wells_config);
    
    % Display MRST well structure details
    fprintf('   ■ %s: MRST well (cells: %d, WI: %.2e, BHP: %.0f-%.0f psi, rate: %.0f m³/day)\n', ...
            mwell.name, length(mwell.cells), mean(mwell.WI), mwell.min_bhp/6895, mwell.max_bhp/6895, mwell.target_rate);

end