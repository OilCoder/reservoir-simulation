% PRINT_UTILS - Unified printing system for Eagle West Field MRST workflow
%
% DESCRIPTION:
%   Script that defines printing functions in the workspace for
%   standardized table format printing following Option B specification.
%   Compatible with both MATLAB and Octave.
%
% USAGE:
%   run('print_utils.m') - loads all print functions into workspace
%
% Author: Claude Code AI System
% Date: January 30, 2025

% Define print_step_header function in workspace
if ~exist('print_step_header', 'var')
    print_step_header = @(step_id, description) fprintf(['\n' ...
        '════════════════════════════════════════════════════════════════\n' ...
        ' %s: %-55s \n' ...
        '════════════════════════════════════════════════════════════════\n' ...
        '  STEP │          DESCRIPTION          │ STATUS │   TIME    \n' ...
        '════════════════════════════════════════════════════════════════\n'], ...
        step_id, upper(description));
end

% Define print_step_result function in workspace
if ~exist('print_step_result', 'var')
    print_step_result = @(step_num, description, status, time_sec) print_step_result_impl(step_num, description, status, time_sec);
end

% Define print_step_footer function in workspace
if ~exist('print_step_footer', 'var')
    print_step_footer = @(step_id, final_message, total_time) print_step_footer_impl(step_id, final_message, total_time);
end

% Define print_error_step function in workspace
if ~exist('print_error_step', 'var')
    print_error_step = @(step_num, description, error_msg) print_error_step_impl(step_num, description, error_msg);
end

% Implementation functions (these won't conflict with function file rules)
function print_step_result_impl(step_num, description, status, time_sec)
    % Format description to fit column width
    desc_formatted = format_description_impl(description, 28);
    
    % Format status icon
    switch lower(status)
        case 'success'
            status_icon = '   ✅   ';
        case 'error' 
            status_icon = '   ❌   ';
        case 'warning'
            status_icon = '   ⚠️   ';
        otherwise
            status_icon = '   ❓   ';
    end
    
    % Format time
    if time_sec < 10
        time_str = sprintf('  %.1fs   ', time_sec);
    else
        time_str = sprintf(' %.1fs   ', time_sec);
    end
    
    fprintf('   %d  │ %-28s │%s│%s\n', step_num, desc_formatted, status_icon, time_str);
end

function print_step_footer_impl(step_id, final_message, total_time)
    fprintf('════════════════════════════════════════════════════════════════\n');
    
    if nargin >= 3 && ~isempty(total_time)
        fprintf(' TOTAL EXECUTION TIME: %-42s \n', sprintf('%.1fs', total_time));
        fprintf('════════════════════════════════════════════════════════════════\n');
    end
    
    fprintf('✅ %s: %s\n\n', step_id, final_message);
end

function formatted = format_description_impl(description, max_width)
    if length(description) > max_width
        formatted = [description(1:max_width-3) '...'];
    else
        formatted = description;
    end
end

function print_error_step_impl(step_num, description, error_msg)
    desc_formatted = format_description_impl(description, 28);
    fprintf('   %d  │ %-28s │   ❌   │    ---    \n', step_num, desc_formatted);
    fprintf('════════════════════════════════════════════════════════════════\n');
    fprintf('❌ ERROR in Step %d: %s\n', step_num, error_msg);
end

fprintf('Print utilities loaded successfully\n');