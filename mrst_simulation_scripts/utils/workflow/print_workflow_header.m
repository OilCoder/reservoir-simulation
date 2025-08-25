function print_workflow_header(validation_only, phases_to_run, all_phases)
% PRINT_WORKFLOW_HEADER - Display workflow configuration and phase overview
%
% Prints workflow header with configuration details and phase summary
% using standardized table format for Eagle West Field simulation
%
% SYNTAX:
%   print_workflow_header(validation_only, phases_to_run, all_phases)
%
% INPUTS:
%   validation_only - Boolean flag for validation mode
%   phases_to_run - Filtered phases to execute
%   all_phases - Complete phase definitions
%
% Author: Claude Code AI System
% Date: 2025-08-22

    % Load configuration for display settings
    config = load_workflow_config();
    
    % Configuration summary
    fprintf('📋 WORKFLOW CONFIGURATION\n');
    fprintf('══════════════════════════\n');
    fprintf('🔧 Mode: %s\n', get_mode_description(validation_only));
    fprintf('📊 Phases: %d of %d selected\n', length(phases_to_run), length(all_phases));
    fprintf('💻 Platform: With Table Format\n');
    fprintf('🕐 Start Time: %s\n\n', datestr(now));
    
    % Phase overview table
    fprintf('📈 PHASE OVERVIEW\n');
    fprintf('═════════════════\n');
    for i = 1:length(phases_to_run)
        phase = phases_to_run{i};
        status = get_phase_status(phase.script_name);
        priority = get_priority_indicator(phase.critical);
        
        fprintf('  %d. %s: %s [%s] %s\n', ...
                i, phase.phase_id, phase.description, priority, status);
    end
    fprintf('\n');
end

function mode_desc = get_mode_description(validation_only)
    % Get user-friendly mode description
    if validation_only
        mode_desc = 'Validation Only';
    else
        mode_desc = 'Full Execution';
    end
end

function priority_str = get_priority_indicator(is_critical)
    % Get priority indicator based on criticality
    if is_critical
        priority_str = '🔴 Critical';
    else
        priority_str = '🟡 Optional';
    end
end

function status = get_phase_status(script_name)
    % Check if script file exists and return status
    if exist([script_name '.m'], 'file')
        status = '✅ Ready';
    else
        status = '❌ Missing';
    end
end