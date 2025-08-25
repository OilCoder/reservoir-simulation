function phase_result = execute_workflow_phase(phase, workflow_results)
% EXECUTE_WORKFLOW_PHASE - Execute single workflow phase with error handling
%
% Executes a single MRST workflow phase with standardized error handling
% and result structure following Fail Fast and Exception Handling policies
%
% SYNTAX:
%   phase_result = execute_workflow_phase(phase, workflow_results)
%
% INPUTS:
%   phase - Phase structure from define_workflow_phases()
%   workflow_results - Current workflow state for context
%
% OUTPUT:
%   phase_result - Standardized phase execution result
%
% Author: Claude Code AI System
% Date: 2025-08-22

    % Initialize phase result structure
    phase_result = struct();
    phase_result.status = 'running';
    phase_result.phase_id = phase.phase_id;
    
    % Validate script exists before execution (Fail Fast Policy)
    script_file = [phase.script_name '.m'];
    if ~exist(script_file, 'file')
        if phase.critical
            error(['Critical script not found: %s\n' ...
                   'REQUIRED: Ensure %s exists in mrst_simulation_scripts/'], ...
                   script_file, script_file);
        else
            phase_result.status = 'skipped';
            phase_result.message = 'Script not found';
            return;
        end
    end
    
    % Execute phase using function dispatch
    try
        output_data = dispatch_phase_execution(phase.phase_id);
        phase_result.output_data = output_data;
        phase_result.status = 'completed';
        
    catch ME
        % Follow Exception Handling Policy - only catch external failures
        phase_result.status = 'failed';
        phase_result.error_message = ME.message;
        rethrow(ME);  % Re-throw for caller to handle based on criticality
    end
end

function output_data = dispatch_phase_execution(phase_id)
    % Dispatch phase execution to appropriate function
    % Using explicit mapping rather than dynamic evaluation for safety
    
    switch phase_id
        case {'s01', 's02', 's03', 's04', 's05', 's09', 's10', 's11', 's12', 's13', 's14', 's15', 's16', 's17', 's18', 's19', 's20', 's21', 's23', 's24', 's25'}
            % Function-based phases
            func_name = sprintf('%s()', phase_id);
            output_data = eval(func_name);
            
        case {'s06', 's07', 's08'}
            % File-based phases
            script_name = sprintf('%s.m', phase_id);
            run(script_name);
            output_data = sprintf('%s executed', script_name);
            
        otherwise
            error('Unknown phase ID: %s', phase_id);
    end
end