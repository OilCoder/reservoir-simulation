function nonlinear_solver = nonlinear_solver_setup(config)
% NONLINEAR_SOLVER_SETUP - Configure MRST nonlinear solver
%
% INPUTS:
%   config - Configuration structure with solver_configuration section
%
% OUTPUTS:
%   nonlinear_solver - Configured nonlinear solver
%
% Author: Claude Code AI System  
% Date: August 23, 2025

    % Initialize nonlinear solver
    [nonlinear_solver, solver_type] = initialize_nonlinear_solver(config.solver_configuration);
    
    % Set convergence tolerances
    nonlinear_solver = set_convergence_tolerances(nonlinear_solver, config.solver_configuration);
    
    % Configure line search
    nonlinear_solver = configure_line_search(nonlinear_solver, config.solver_configuration);
    
    % Configure linear solver
    [nonlinear_solver, linear_solver_type] = configure_linear_solver(nonlinear_solver, config.solver_configuration);
    
    % Set advanced solver options
    nonlinear_solver = set_advanced_solver_options(nonlinear_solver);
    
    fprintf('Nonlinear solver configured: %s with %s linear solver\n', solver_type, linear_solver_type);
end

function [nonlinear_solver, solver_type] = initialize_nonlinear_solver(solver_config)
% Initialize nonlinear solver based on configuration
    switch lower(solver_config.solver_type)
        case 'ad-fi'
            nonlinear_solver = NonLinearSolver();
            solver_type = 'Fully-Implicit AD';
        case 'sequential'
            nonlinear_solver = SequentialPressureTransportModel();
            solver_type = 'Sequential';
        otherwise
            nonlinear_solver = NonLinearSolver();
            solver_type = 'Default NonLinear';
    end
end

function nonlinear_solver = set_convergence_tolerances(nonlinear_solver, solver_config)
% Set convergence tolerances for solver
    if isprop(nonlinear_solver, 'toleranceAD')
        nonlinear_solver.toleranceAD = solver_config.tolerance_cnv;
    end
    if isprop(nonlinear_solver, 'toleranceMB')
        nonlinear_solver.toleranceMB = solver_config.tolerance_mb;
    end
    if isprop(nonlinear_solver, 'maxIterations')
        nonlinear_solver.maxIterations = solver_config.max_iterations;
    end
end

function nonlinear_solver = configure_line_search(nonlinear_solver, solver_config)
% Configure line search for solver
    if isprop(nonlinear_solver, 'useLineSearch') && isfield(solver_config, 'line_search')
        nonlinear_solver.useLineSearch = solver_config.line_search;
    end
    if isprop(nonlinear_solver, 'lineSearchMinDecrease')
        nonlinear_solver.lineSearchMinDecrease = 0.01;
    end
end

function [nonlinear_solver, linear_solver_type] = configure_linear_solver(nonlinear_solver, solver_config)
% Configure linear solver
    if isprop(nonlinear_solver, 'LinearSolver') && isfield(solver_config, 'use_cpr') && solver_config.use_cpr
        try
            nonlinear_solver.LinearSolver = CPRSolverAD('tolerance', 1e-8);
            linear_solver_type = 'CPR';
        catch
            linear_solver_type = 'Default';
        end
    else
        linear_solver_type = 'Default';
    end
end

function nonlinear_solver = set_advanced_solver_options(nonlinear_solver)
% Set advanced solver options
    if isprop(nonlinear_solver, 'minIterations')
        nonlinear_solver.minIterations = 1;
    end
    if isprop(nonlinear_solver, 'enforceMaxIterations')
        nonlinear_solver.enforceMaxIterations = true;
    end
end