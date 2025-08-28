function completion_intervals = define_completion_intervals(wells_data, G, wells_config)
% DEFINE_COMPLETION_INTERVALS - Define layer-specific completion intervals
%
% INPUTS:
%   wells_data - Wells placement structure from s15
%   G - Grid structure from MRST
%   wells_config - Wells configuration from YAML
%
% OUTPUTS:
%   completion_intervals - Structure with completion intervals by layer
%
% Author: Claude Code AI System
% Date: August 22, 2025

    completion_intervals = struct();
    
    % Add helper functions to path
    script_path = fileparts(mfilename('fullpath'));
    addpath(script_path);
    
    completion_intervals.layer_definitions = define_layer_intervals(wells_config);
    
    % Combine cell arrays properly (producer_wells and injector_wells are cell arrays)
    all_wells = [wells_data.producer_wells(:); wells_data.injector_wells(:)];
    completion_intervals.wells = [];
    
    % Define intervals for each well
    for i = 1:length(all_wells)
        well = all_wells{i};  % Access cell array element
        
        ci = struct();
        ci.name = well.name;
        ci.type = well.type;
        ci.completion_layers = well.completion_layers;
        ci.intervals = [];
        
        % Create intervals for each completed layer
        for j = 1:length(well.completion_layers)
            layer = well.completion_layers(j);
            
            interval = struct();
            interval.layer = layer;
            interval.layer_name = get_layer_name(layer);
            
            % CANON-FIRST: Use existing geological structure from grid G
            [interval.top_depth_ft, interval.bottom_depth_ft] = get_layer_depths_from_grid(G, well, layer);
            
            interval.net_pay_ft = interval.bottom_depth_ft - interval.top_depth_ft;
            
            ci.intervals = [ci.intervals; interval];
        end
        
        ci.total_net_pay_ft = sum([ci.intervals.net_pay_ft]);
        completion_intervals.wells = [completion_intervals.wells; ci];
        
        % Display completion intervals details
        fprintf('   ■ %s: %d layers, total pay: %.0f ft', ci.name, length(ci.intervals), ci.total_net_pay_ft);
        for k = 1:length(ci.intervals)
            fprintf(' [L%d:%.0f-%.0f ft]', ci.intervals(k).layer, ci.intervals(k).top_depth_ft, ci.intervals(k).bottom_depth_ft);
        end
        fprintf('\n');
    end
    
    % Summary by sand interval
    completion_intervals.summary = calculate_completion_summary(completion_intervals.wells);

end