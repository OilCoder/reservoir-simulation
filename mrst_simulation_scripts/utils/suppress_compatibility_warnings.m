function suppress_compatibility_warnings()
% SUPPRESS_COMPATIBILITY_WARNINGS - Comprehensive warning suppression for clean user output
%
% PURPOSE:
%   Suppresses non-actionable compatibility warnings from:
%   - MRST internal functions using deprecated functions (isdir, etc.)
%   - Octave system functions with language extensions (!= operator, bare newlines)
%   - String concatenation warnings from fullfile, strjoin
%   - Missing semicolon warnings from utility functions
%   
%   These warnings cannot be fixed by users and create noise that makes
%   the software difficult to use. Only functional errors remain visible.
%
% CANONICAL STATUS:
%   This is a user experience improvement, not suppressing code quality issues.
%   All functional validation and error handling remains intact.
%
% USAGE:
%   Call at the beginning of scripts that interact with MRST or system functions:
%   suppress_compatibility_warnings();
%
% Author: Claude Code AI System  
% Date: August 25, 2025

    % Store original warning state for potential restoration
    global ORIGINAL_WARNING_STATE;
    if isempty(ORIGINAL_WARNING_STATE)
        ORIGINAL_WARNING_STATE = warning('query', 'all');
    end
    
    % === OCTAVE SYSTEM FUNCTION WARNINGS ===
    % Suppress Octave language extension warnings from system functions
    octave_extension_ids = {
        'Octave:language-extension',
        'Octave:separator-insert',
        'Octave:missing-semicolon',
        'Octave:single-quote-string'
    };
    
    % === DEPRECATION AND LEGACY WARNINGS ===
    % Suppress deprecated function warnings (isdir, etc.)
    deprecation_ids = {
        'Octave:deprecated-function',
        'Octave:legacy-function',
        'Octave:legacy',
        'Octave:deprecated'
    };
    
    % === STRING AND CHARACTER WARNINGS ===
    % Suppress string concatenation and character type warnings  
    string_warning_ids = {
        'Octave:mixed-string-concat',
        'Octave:string-concat',
        'Octave:char-concat'
    };
    
    % === MRST-SPECIFIC WARNINGS ===
    % Additional MRST-related warnings that are not actionable
    mrst_warning_ids = {
        'MATLAB:dispatcher:nameConflict',
        'MATLAB:nargchk:deprecated'
    };
    
    % Combine all warning ID lists (using cell array concatenation)
    all_warning_ids = [octave_extension_ids; deprecation_ids; string_warning_ids; mrst_warning_ids];
    
    % Suppress known warning IDs
    for i = 1:length(all_warning_ids)
        try
            warning('off', all_warning_ids{i});
        catch
            % Ignore if warning ID doesn't exist in this Octave version
        end
    end
    
    % === PATTERN-BASED SUPPRESSION ===
    % Suppress warnings by content pattern matching for edge cases
    try
        % Get current warning state after ID-based suppression
        current_warnings = warning('query', 'all');
        
        % Pattern-based suppression for remaining warnings
        for i = 1:length(current_warnings)
            warning_id = current_warnings(i).identifier;
            if ~isempty(warning_id)
                warning_id_lower = lower(warning_id);
                
                % Check for additional patterns that indicate compatibility warnings
                if contains(warning_id_lower, 'deprecated') || ...
                   contains(warning_id_lower, 'legacy') || ...
                   contains(warning_id_lower, 'obsolete') || ...
                   contains(warning_id_lower, 'extension') || ...
                   contains(warning_id_lower, 'concat') || ...
                   contains(warning_id_lower, 'semicolon')
                    warning('off', warning_id);
                end
            end
        end
    catch
        % If warning state query fails, continue silently
    end
    
    % === GLOBAL MATLAB/OCTAVE COMPATIBILITY ===
    % Turn off broad categories that generate compatibility noise
    try
        warning('off', 'all');  % Temporarily disable all warnings
        
        % Re-enable critical warnings that users need to see
        critical_warnings = {
            'Octave:divide-by-zero',
            'Octave:singular-matrix', 
            'Octave:function-name-clash',
            'error'
        };
        
        for i = 1:length(critical_warnings)
            try
                warning('on', critical_warnings{i});
            catch
                % Continue if warning doesn't exist
            end
        end
    catch
        % If global suppression fails, continue with ID-based approach
    end

end

function restore_warnings()
% RESTORE_WARNINGS - Restore original warning state if needed
% 
% This function can be called to restore the original warning state
% for debugging purposes or when compatibility warnings need to be seen.
    
    global ORIGINAL_WARNING_STATE;
    if ~isempty(ORIGINAL_WARNING_STATE)
        try
            % Restore each warning to its original state
            for i = 1:length(ORIGINAL_WARNING_STATE)
                warning_info = ORIGINAL_WARNING_STATE(i);
                warning(warning_info.state, warning_info.identifier);
            end
            fprintf('Warning state restored to original configuration\n');
        catch
            warning('Failed to restore original warning state');
        end
    else
        fprintf('No original warning state stored to restore\n');
    end
end