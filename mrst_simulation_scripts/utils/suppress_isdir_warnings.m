function suppress_isdir_warnings()
% SUPPRESS_ISDIR_WARNINGS - Suppress deprecated isdir function warnings from MRST
%
% PURPOSE:
%   MRST internal functions use the deprecated isdir() function from
%   /usr/share/octave/8.4.0/m/legacy/isdir.m which triggers warnings:
%   "warning: isdir is obsolete; use isfolder or dir_in_loadpath instead"
%
%   This function suppresses these warnings since we cannot modify MRST's
%   internal code and the warnings are not actionable for our workflow.
%
% CANONICAL STATUS:
%   This is a compatibility fix for MRST integration, not a code quality issue.
%   The warnings come from MRST's mrstSettings>ensure_directory_exists calls.
%
% USAGE:
%   Call at the beginning of scripts that use MRST functions:
%   suppress_isdir_warnings();
%
% Author: Claude Code AI System
% Date: August 19, 2025

    % Try multiple warning ID patterns to catch the isdir deprecation warning
    warning_ids = {
        'Octave:deprecated-function',
        'Octave:legacy-function', 
        'Octave:legacy',
        'Octave:deprecated'
    };
    
    for i = 1:length(warning_ids)
        try
            warning('off', warning_ids{i});
        catch
            % Ignore if warning ID doesn't exist in this Octave version
        end
    end
    
    % Also try to suppress by message pattern matching
    % This is a more aggressive approach that catches the specific message
    try
        % Get current warning state
        current_warnings = warning('query', 'all');
        
        % Find and disable any warnings containing 'isdir' or 'obsolete'
        for i = 1:length(current_warnings)
            warning_id = current_warnings(i).identifier;
            if ~isempty(warning_id)
                % Check if this might be related to isdir/obsolete warnings
                if contains(lower(warning_id), 'deprecated') || ...
                   contains(lower(warning_id), 'legacy') || ...
                   contains(lower(warning_id), 'obsolete')
                    warning('off', warning_id);
                end
            end
        end
    catch
        % If warning state query fails, continue silently
    end
    
    fprintf('MRST compatibility: isdir deprecation warnings suppressed\n');

end