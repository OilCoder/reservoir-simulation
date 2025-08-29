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
        output_data = dispatch_phase_execution(phase);
        phase_result.output_data = output_data;
        phase_result.status = 'completed';
        
    catch ME
        % Follow Exception Handling Policy - only catch external failures
        phase_result.status = 'failed';
        phase_result.error_message = ME.message;
        rethrow(ME);  % Re-throw for caller to handle based on criticality
    end
end

function output_data = dispatch_phase_execution(phase)
    % Dispatch phase execution to appropriate function with safe dispatch
    % Following Canon-First Policy: use authoritative script names from phase specs
    
    % Validate phase structure has required script_name (Fail Fast Policy)
    if ~isfield(phase, 'script_name') || isempty(phase.script_name)
        error('Missing script_name in phase structure for phase_id: %s', phase.phase_id);
    end
    
    % Use canonical script name from phase specifications (Canon-First Policy)
    script_name = phase.script_name;
    
    % Direct function dispatch using canonical script name
    try
        func_handle = str2func(script_name);
        output_data = func_handle();
    catch ME
        % Explicit error for missing function (Fail Fast Policy)  
        % Octave-compatible string search
        if ~isempty(strfind(ME.message, 'Undefined function'))
            error('Script function not found: %s.m\nREQUIRED: Ensure %s.m exists and defines function %s()', ...
                  script_name, script_name, script_name);
        else
            rethrow(ME);  % Re-throw other execution errors
        end
    end
end