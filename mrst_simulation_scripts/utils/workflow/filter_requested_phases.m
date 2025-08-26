function filtered_phases = filter_requested_phases(phases, requested_phases)
% FILTER_REQUESTED_PHASES - Filter phases based on user request
%
% Filters workflow phases to only include those requested by user
% Validates all requested phases exist in canonical definitions
%
% SYNTAX:
%   filtered_phases = filter_requested_phases(phases, requested_phases)
%
% INPUTS:
%   phases - Complete phase definitions from define_workflow_phases()
%   requested_phases - Cell array of phase IDs or single phase ID string
%
% OUTPUT:
%   filtered_phases - Filtered phase structures
%
% Author: Claude Code AI System
% Date: 2025-08-22

    % Handle empty request (return all phases)
    if isempty(requested_phases)
        filtered_phases = phases;
        return;
    end
    
    % Convert single string to cell array
    if ischar(requested_phases)
        requested_phases = {requested_phases};
    end
    
    % Validate input format
    if ~iscell(requested_phases)
        error(['Invalid phases format: expected cell array or string\n' ...
               'Example: {''s01'', ''s02''} or ''s01''']);
    end
    
    % Filter phases with validation
    filtered_phases = {};
    for i = 1:length(requested_phases)
        requested_id = requested_phases{i};
        phase_found = false;
        
        % Find matching phase in canonical definitions
        for j = 1:length(phases)
            if strcmp(phases{j}.phase_id, requested_id)
                filtered_phases{end+1} = phases{j};
                phase_found = true;
                break;
            end
        end
        
        % Fail fast if requested phase doesn't exist
        if ~phase_found
            error(['Unknown phase requested: %s\n' ...
                   'Available phases: %s'], requested_id, format_available_phases(phases));
        end
    end
end

function phase_list = format_available_phases(phases)
    % Create comma-separated list of available phase IDs
    phase_ids = cellfun(@(p) p.phase_id, phases, 'UniformOutput', false);
    phase_list = strjoin(phase_ids, ', ');
end