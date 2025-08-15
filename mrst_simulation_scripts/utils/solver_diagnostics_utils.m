function solver_diagnostics_utils()
% SOLVER_DIAGNOSTICS_UTILS - Comprehensive solver diagnostics capture for MRST workflow
%
% Implements FASE 3: Solver diagnostics capture for surrogate modeling
% Captures ALL solver internal data without re-simulation:
% - Newton iteration convergence data
% - Residual norms and convergence rates
% - Linear solver performance metrics
% - Timestep control diagnostics
% - Memory usage and computational performance
% - Matrix conditioning and numerical stability
%
% Features:
% - Canonical organization with native .mat format
% - Zero-overhead capture during simulation
% - Complete ML feature engineering preparation
% - Canon-First error handling (no fallbacks)
%
% Requires: MRST
%
% Author: Claude Code AI System  
% Date: August 15, 2025

end

function solver_diagnostics = initialize_solver_diagnostics(total_timesteps, model_info)
% INITIALIZE_SOLVER_DIAGNOSTICS - Initialize comprehensive diagnostics structure
%
% INPUTS:
%   total_timesteps - Total number of simulation timesteps
%   model_info      - Model metadata (grid size, well count, etc.)
%
% OUTPUTS:
%   solver_diagnostics - Complete diagnostics tracking structure
%
% CANONICAL FIELDS:
%   convergence_data    - Newton iteration tracking
%   residual_norms      - L2, L∞ residuals per equation
%   linear_solver_data  - Matrix properties and solve performance
%   timestep_control    - Adaptive timestep diagnostics
%   performance_metrics - Computational performance tracking
%   numerical_stability - Conditioning and stability indicators

    if nargin < 1
        error(['Missing canonical timesteps parameter\n' ...
               'REQUIRED: Update obsidian-vault/Planning/Simulation_Data_Catalog/\n' ...
               'STEP_DATA_OUTPUT_MAPPING.md to define total_timesteps.\n' ...
               'Canon must specify exact simulation duration.']);
    end
    
    if nargin < 2
        error(['Missing canonical model_info parameter\n' ...
               'REQUIRED: Must provide model metadata for diagnostics sizing.\n' ...
               'Canon requires grid dimensions and well configuration.']);
    end
    
    fprintf('📊 Initializing solver diagnostics for %d timesteps...\n', total_timesteps);
    
    % Initialize main diagnostics structure
    solver_diagnostics = struct();
    solver_diagnostics.metadata = struct();
    solver_diagnostics.metadata.total_timesteps = total_timesteps;
    solver_diagnostics.metadata.grid_cells = model_info.grid_cells;
    solver_diagnostics.metadata.total_wells = model_info.total_wells;
    solver_diagnostics.metadata.creation_time = datestr(now, 'yyyy-mm-ddTHH:MM:SS');
    solver_diagnostics.metadata.diagnostics_version = 'canonical_v1.0';
    
    % ========================================
    % CONVERGENCE DATA (CRITICAL FOR ML)
    % ========================================
    solver_diagnostics.convergence_data = struct();
    
    % Newton iteration tracking per timestep
    solver_diagnostics.convergence_data.newton_iterations = zeros(total_timesteps, 1);
    solver_diagnostics.convergence_data.convergence_achieved = false(total_timesteps, 1);
    solver_diagnostics.convergence_data.convergence_rate = zeros(total_timesteps, 1);
    solver_diagnostics.convergence_data.stagnation_detected = false(total_timesteps, 1);
    
    % Maximum iterations and failure tracking
    max_iter_per_step = 50;  % Conservative estimate for array sizing
    solver_diagnostics.convergence_data.residual_norms_by_iteration = zeros(total_timesteps, max_iter_per_step);
    solver_diagnostics.convergence_data.residual_reduction_by_iteration = zeros(total_timesteps, max_iter_per_step);
    solver_diagnostics.convergence_data.newton_update_norms = zeros(total_timesteps, max_iter_per_step);
    
    % Convergence failure analysis
    solver_diagnostics.convergence_data.convergence_failures = zeros(total_timesteps, 1);
    solver_diagnostics.convergence_data.failure_reasons = cell(total_timesteps, 1);
    solver_diagnostics.convergence_data.recovery_attempts = zeros(total_timesteps, 1);
    
    % ========================================
    % RESIDUAL NORMS (EQUATION-LEVEL TRACKING)
    % ========================================
    solver_diagnostics.residual_norms = struct();
    
    % Per-equation residuals (oil, water, gas for black oil)
    n_equations = 3;  % Black oil: oil, water, gas
    solver_diagnostics.residual_norms.equation_residuals = zeros(total_timesteps, n_equations);
    solver_diagnostics.residual_norms.equation_residuals_l2 = zeros(total_timesteps, n_equations);
    solver_diagnostics.residual_norms.equation_residuals_linf = zeros(total_timesteps, n_equations);
    
    % Global residual metrics
    solver_diagnostics.residual_norms.global_residual_l2 = zeros(total_timesteps, 1);
    solver_diagnostics.residual_norms.global_residual_linf = zeros(total_timesteps, 1);
    solver_diagnostics.residual_norms.material_balance_error = zeros(total_timesteps, 1);
    
    % Convergence tolerance tracking
    solver_diagnostics.residual_norms.cnv_tolerance_achieved = false(total_timesteps, 1);
    solver_diagnostics.residual_norms.mb_tolerance_achieved = false(total_timesteps, 1);
    solver_diagnostics.residual_norms.tolerance_margins = zeros(total_timesteps, 2);  % CNV, MB
    
    % ========================================
    % LINEAR SOLVER PERFORMANCE
    % ========================================
    solver_diagnostics.linear_solver_data = struct();
    
    % Matrix properties and conditioning
    solver_diagnostics.linear_solver_data.jacobian_condition_number = zeros(total_timesteps, 1);
    solver_diagnostics.linear_solver_data.jacobian_rank_deficiency = zeros(total_timesteps, 1);
    solver_diagnostics.linear_solver_data.jacobian_sparsity = zeros(total_timesteps, 1);
    solver_diagnostics.linear_solver_data.jacobian_assembly_time = zeros(total_timesteps, 1);
    
    % Linear solve performance
    solver_diagnostics.linear_solver_data.linear_solve_time = zeros(total_timesteps, max_iter_per_step);
    solver_diagnostics.linear_solver_data.linear_solve_iterations = zeros(total_timesteps, max_iter_per_step);
    solver_diagnostics.linear_solver_data.linear_solve_residual = zeros(total_timesteps, max_iter_per_step);
    solver_diagnostics.linear_solver_data.preconditioner_setup_time = zeros(total_timesteps, 1);
    
    % Memory usage tracking
    solver_diagnostics.linear_solver_data.jacobian_memory_mb = zeros(total_timesteps, 1);
    solver_diagnostics.linear_solver_data.preconditioner_memory_mb = zeros(total_timesteps, 1);
    solver_diagnostics.linear_solver_data.total_linear_memory_mb = zeros(total_timesteps, 1);
    
    % ========================================
    % TIMESTEP CONTROL DIAGNOSTICS
    % ========================================
    solver_diagnostics.timestep_control = struct();
    
    % Adaptive timestep tracking
    solver_diagnostics.timestep_control.timestep_size_days = zeros(total_timesteps, 1);
    solver_diagnostics.timestep_control.timestep_cuts = zeros(total_timesteps, 1);
    solver_diagnostics.timestep_control.timestep_growth = zeros(total_timesteps, 1);
    solver_diagnostics.timestep_control.cfl_numbers = zeros(total_timesteps, 1);
    
    % Timestep selection reasoning
    solver_diagnostics.timestep_control.selection_criteria = cell(total_timesteps, 1);
    solver_diagnostics.timestep_control.pressure_change_limit = zeros(total_timesteps, 1);
    solver_diagnostics.timestep_control.saturation_change_limit = zeros(total_timesteps, 1);
    solver_diagnostics.timestep_control.well_performance_limit = zeros(total_timesteps, 1);
    
    % Stability indicators
    solver_diagnostics.timestep_control.stability_indicator = zeros(total_timesteps, 1);
    solver_diagnostics.timestep_control.oscillation_detected = false(total_timesteps, 1);
    solver_diagnostics.timestep_control.monotonicity_preserved = true(total_timesteps, 1);
    
    % ========================================
    % PERFORMANCE METRICS
    % ========================================
    solver_diagnostics.performance_metrics = struct();
    
    % Computational timing
    solver_diagnostics.performance_metrics.total_timestep_time = zeros(total_timesteps, 1);
    solver_diagnostics.performance_metrics.newton_solve_time = zeros(total_timesteps, 1);
    solver_diagnostics.performance_metrics.jacobian_time = zeros(total_timesteps, 1);
    solver_diagnostics.performance_metrics.residual_evaluation_time = zeros(total_timesteps, 1);
    solver_diagnostics.performance_metrics.well_update_time = zeros(total_timesteps, 1);
    
    % Memory usage tracking
    solver_diagnostics.performance_metrics.peak_memory_mb = zeros(total_timesteps, 1);
    solver_diagnostics.performance_metrics.memory_allocation_count = zeros(total_timesteps, 1);
    solver_diagnostics.performance_metrics.garbage_collection_time = zeros(total_timesteps, 1);
    
    % Computational efficiency
    solver_diagnostics.performance_metrics.flops_per_iteration = zeros(total_timesteps, max_iter_per_step);
    solver_diagnostics.performance_metrics.cache_hit_ratio = zeros(total_timesteps, 1);
    solver_diagnostics.performance_metrics.parallel_efficiency = zeros(total_timesteps, 1);
    
    % ========================================
    # NUMERICAL STABILITY INDICATORS
    % ========================================
    solver_diagnostics.numerical_stability = struct();
    
    % Matrix conditioning and health
    solver_diagnostics.numerical_stability.condition_number_trend = zeros(total_timesteps, 1);
    solver_diagnostics.numerical_stability.near_singularity_detected = false(total_timesteps, 1);
    solver_diagnostics.numerical_stability.pivot_magnitude = zeros(total_timesteps, 1);
    solver_diagnostics.numerical_stability.matrix_norm_changes = zeros(total_timesteps, 1);
    
    % Numerical accuracy indicators
    solver_diagnostics.numerical_stability.roundoff_error_estimate = zeros(total_timesteps, 1);
    solver_diagnostics.numerical_stability.backward_error = zeros(total_timesteps, 1);
    solver_diagnostics.numerical_stability.solution_smoothness = zeros(total_timesteps, 1);
    
    % Physical validity checks
    solver_diagnostics.numerical_stability.negative_pressures = zeros(total_timesteps, 1);
    solver_diagnostics.numerical_stability.saturation_violations = zeros(total_timesteps, 1);
    solver_diagnostics.numerical_stability.unphysical_values_detected = false(total_timesteps, 1);
    
    fprintf('   ✅ Solver diagnostics structure initialized\n');
    fprintf('   📊 Tracking %d timesteps with %d equations\n', total_timesteps, n_equations);
    fprintf('   🔍 Memory allocated: ~%.1f MB for diagnostics\n', ...
        estimate_diagnostics_memory_mb(solver_diagnostics));

end

function capture_newton_iteration_data(solver_diagnostics, timestep_idx, iteration_data)
% CAPTURE_NEWTON_ITERATION_DATA - Capture detailed Newton iteration diagnostics
%
% INPUTS:
%   solver_diagnostics - Main diagnostics structure (modified in-place)
%   timestep_idx       - Current timestep index
%   iteration_data     - Structure with Newton iteration information
%
% CANONICAL ITERATION_DATA FIELDS:
%   iteration_number    - Current Newton iteration
%   residual_norm      - Current residual norm
%   residual_reduction - Reduction from previous iteration
%   newton_update_norm - Norm of Newton update vector
%   convergence_check  - Convergence status
%   linear_solve_info  - Linear solver diagnostics

    if timestep_idx < 1 || timestep_idx > length(solver_diagnostics.convergence_data.newton_iterations)
        error(['Invalid timestep index for Newton diagnostics: %d\n' ...
               'REQUIRED: timestep_idx must be within simulation range.\n' ...
               'Canon requires valid timestep tracking.'], timestep_idx);
    end
    
    if ~isfield(iteration_data, 'iteration_number')
        error(['Missing canonical iteration_number in iteration_data\n' ...
               'REQUIRED: Update MRST solver hooks to provide iteration_number.\n' ...
               'Canon requires complete Newton iteration tracking.']);
    end
    
    iteration_num = iteration_data.iteration_number;
    
    % ========================================
    % CONVERGENCE TRACKING
    % ========================================
    
    % Update iteration count for this timestep
    solver_diagnostics.convergence_data.newton_iterations(timestep_idx) = iteration_num;
    
    % Capture residual norms
    if isfield(iteration_data, 'residual_norm')
        max_iter = size(solver_diagnostics.convergence_data.residual_norms_by_iteration, 2);
        if iteration_num <= max_iter
            solver_diagnostics.convergence_data.residual_norms_by_iteration(timestep_idx, iteration_num) = ...
                iteration_data.residual_norm;
        end
    end
    
    % Capture residual reduction
    if isfield(iteration_data, 'residual_reduction')
        max_iter = size(solver_diagnostics.convergence_data.residual_reduction_by_iteration, 2);
        if iteration_num <= max_iter
            solver_diagnostics.convergence_data.residual_reduction_by_iteration(timestep_idx, iteration_num) = ...
                iteration_data.residual_reduction;
        end
    end
    
    % Capture Newton update norm
    if isfield(iteration_data, 'newton_update_norm')
        max_iter = size(solver_diagnostics.convergence_data.newton_update_norms, 2);
        if iteration_num <= max_iter
            solver_diagnostics.convergence_data.newton_update_norms(timestep_idx, iteration_num) = ...
                iteration_data.newton_update_norm;
        end
    end
    
    % ========================================
    # LINEAR SOLVER DIAGNOSTICS
    % ========================================
    
    if isfield(iteration_data, 'linear_solve_info')
        linear_info = iteration_data.linear_solve_info;
        
        % Linear solve timing
        if isfield(linear_info, 'solve_time')
            max_iter = size(solver_diagnostics.linear_solver_data.linear_solve_time, 2);
            if iteration_num <= max_iter
                solver_diagnostics.linear_solver_data.linear_solve_time(timestep_idx, iteration_num) = ...
                    linear_info.solve_time;
            end
        end
        
        % Linear iterations
        if isfield(linear_info, 'linear_iterations')
            max_iter = size(solver_diagnostics.linear_solver_data.linear_solve_iterations, 2);
            if iteration_num <= max_iter
                solver_diagnostics.linear_solver_data.linear_solve_iterations(timestep_idx, iteration_num) = ...
                    linear_info.linear_iterations;
            end
        end
        
        # Linear residual
        if isfield(linear_info, 'linear_residual')
            max_iter = size(solver_diagnostics.linear_solver_data.linear_solve_residual, 2);
            if iteration_num <= max_iter
                solver_diagnostics.linear_solver_data.linear_solve_residual(timestep_idx, iteration_num) = ...
                    linear_info.linear_residual;
            end
        end
        
        % Matrix condition number (expensive - capture only first iteration)
        if iteration_num == 1 && isfield(linear_info, 'condition_number')
            solver_diagnostics.linear_solver_data.jacobian_condition_number(timestep_idx) = ...
                linear_info.condition_number;
        end
    end
    
    % ========================================
    % CONVERGENCE ANALYSIS
    # ========================================
    
    % Check convergence status
    if isfield(iteration_data, 'convergence_check')
        solver_diagnostics.convergence_data.convergence_achieved(timestep_idx) = ...
            iteration_data.convergence_check.converged;
            
        % Store convergence tolerances achieved
        if isfield(iteration_data.convergence_check, 'cnv_satisfied')
            solver_diagnostics.residual_norms.cnv_tolerance_achieved(timestep_idx) = ...
                iteration_data.convergence_check.cnv_satisfied;
        end
        
        if isfield(iteration_data.convergence_check, 'mb_satisfied')
            solver_diagnostics.residual_norms.mb_tolerance_achieved(timestep_idx) = ...
                iteration_data.convergence_check.mb_satisfied;
        end
    end
    
    # Stagnation detection
    if iteration_num > 2
        recent_residuals = solver_diagnostics.convergence_data.residual_norms_by_iteration(timestep_idx, max(1,iteration_num-2):iteration_num);
        recent_residuals = recent_residuals(recent_residuals > 0);  % Filter valid entries
        
        if length(recent_residuals) >= 3
            residual_changes = diff(recent_residuals);
            if all(abs(residual_changes) < 1e-12)  % Stagnation threshold
                solver_diagnostics.convergence_data.stagnation_detected(timestep_idx) = true;
            end
        end
    end

end

function capture_timestep_diagnostics(solver_diagnostics, timestep_idx, timestep_data)
% CAPTURE_TIMESTEP_DIAGNOSTICS - Capture timestep control and performance diagnostics
%
% INPUTS:
%   solver_diagnostics - Main diagnostics structure (modified in-place)
%   timestep_idx       - Current timestep index
%   timestep_data      - Structure with timestep control information
%
% CANONICAL TIMESTEP_DATA FIELDS:
%   dt_days            - Timestep size in days
%   dt_cuts            - Number of timestep cuts this step
%   dt_growth_factor   - Timestep growth from previous step
%   cfl_number         - CFL stability number
%   selection_reason   - Reason for timestep size selection

    if timestep_idx < 1 || timestep_idx > length(solver_diagnostics.timestep_control.timestep_size_days)
        error(['Invalid timestep index for timestep diagnostics: %d\n' ...
               'REQUIRED: timestep_idx must be within simulation range.\n' ...
               'Canon requires valid timestep tracking.'], timestep_idx);
    end
    
    % ========================================
    # TIMESTEP SIZE TRACKING
    % ========================================
    
    if isfield(timestep_data, 'dt_days')
        solver_diagnostics.timestep_control.timestep_size_days(timestep_idx) = timestep_data.dt_days;
    else
        error(['Missing canonical dt_days in timestep_data\n' ...
               'REQUIRED: Update timestep controller to provide dt_days.\n' ...
               'Canon requires complete timestep size tracking.']);
    end
    
    % Timestep cuts tracking
    if isfield(timestep_data, 'dt_cuts')
        solver_diagnostics.timestep_control.timestep_cuts(timestep_idx) = timestep_data.dt_cuts;
    end
    
    % Timestep growth factor
    if timestep_idx > 1 && solver_diagnostics.timestep_control.timestep_size_days(timestep_idx-1) > 0
        current_dt = solver_diagnostics.timestep_control.timestep_size_days(timestep_idx);
        previous_dt = solver_diagnostics.timestep_control.timestep_size_days(timestep_idx-1);
        solver_diagnostics.timestep_control.timestep_growth(timestep_idx) = current_dt / previous_dt;
    end
    
    # ========================================
    # STABILITY INDICATORS
    # ========================================
    
    % CFL number tracking
    if isfield(timestep_data, 'cfl_number')
        solver_diagnostics.timestep_control.cfl_numbers(timestep_idx) = timestep_data.cfl_number;
    end
    
    % Selection criteria
    if isfield(timestep_data, 'selection_reason')
        solver_diagnostics.timestep_control.selection_criteria{timestep_idx} = timestep_data.selection_reason;
    end
    
    % Physical limits tracking
    if isfield(timestep_data, 'pressure_change_pa')
        solver_diagnostics.timestep_control.pressure_change_limit(timestep_idx) = timestep_data.pressure_change_pa;
    end
    
    if isfield(timestep_data, 'max_saturation_change')
        solver_diagnostics.timestep_control.saturation_change_limit(timestep_idx) = timestep_data.max_saturation_change;
    end
    
    # ========================================
    # PERFORMANCE METRICS
    # ========================================
    
    % Total timestep timing
    if isfield(timestep_data, 'total_timestep_time')
        solver_diagnostics.performance_metrics.total_timestep_time(timestep_idx) = timestep_data.total_timestep_time;
    end
    
    % Memory usage
    if isfield(timestep_data, 'peak_memory_mb')
        solver_diagnostics.performance_metrics.peak_memory_mb(timestep_idx) = timestep_data.peak_memory_mb;
    end
    
    % Computational breakdown
    if isfield(timestep_data, 'newton_time')
        solver_diagnostics.performance_metrics.newton_solve_time(timestep_idx) = timestep_data.newton_time;
    end
    
    if isfield(timestep_data, 'jacobian_time')
        solver_diagnostics.performance_metrics.jacobian_time(timestep_idx) = timestep_data.jacobian_time;
    end

end

function capture_equation_residuals(solver_diagnostics, timestep_idx, residual_data)
% CAPTURE_EQUATION_RESIDUALS - Capture detailed equation-level residual diagnostics
%
% INPUTS:
%   solver_diagnostics - Main diagnostics structure (modified in-place)
%   timestep_idx       - Current timestep index
%   residual_data      - Structure with equation residual information
%
% CANONICAL RESIDUAL_DATA FIELDS:
%   equation_residuals - Array of residuals per equation [oil, water, gas]
%   l2_norms          - L2 norms per equation
%   linf_norms        - L∞ norms per equation
%   material_balance  - Material balance error
%   global_residual   - Global residual norm

    if timestep_idx < 1 || timestep_idx > size(solver_diagnostics.residual_norms.equation_residuals, 1)
        error(['Invalid timestep index for residual diagnostics: %d\n' ...
               'REQUIRED: timestep_idx must be within simulation range.\n' ...
               'Canon requires valid residual tracking.'], timestep_idx);
    end
    
    % ========================================
    # EQUATION-LEVEL RESIDUALS
    % ========================================
    
    if isfield(residual_data, 'equation_residuals')
        n_equations = size(solver_diagnostics.residual_norms.equation_residuals, 2);
        equation_residuals = residual_data.equation_residuals;
        
        if length(equation_residuals) == n_equations
            solver_diagnostics.residual_norms.equation_residuals(timestep_idx, :) = equation_residuals;
        else
            error(['Equation residuals dimension mismatch: got %d, expected %d\n' ...
                   'REQUIRED: Update residual calculation to match canonical equation count.\n' ...
                   'Canon requires [oil, water, gas] residuals for black oil model.'], ...
                   length(equation_residuals), n_equations);
        end
    end
    
    % L2 norms per equation
    if isfield(residual_data, 'l2_norms')
        n_equations = size(solver_diagnostics.residual_norms.equation_residuals_l2, 2);
        l2_norms = residual_data.l2_norms;
        
        if length(l2_norms) == n_equations
            solver_diagnostics.residual_norms.equation_residuals_l2(timestep_idx, :) = l2_norms;
        end
    end
    
    % L∞ norms per equation
    if isfield(residual_data, 'linf_norms')
        n_equations = size(solver_diagnostics.residual_norms.equation_residuals_linf, 2);
        linf_norms = residual_data.linf_norms;
        
        if length(linf_norms) == n_equations
            solver_diagnostics.residual_norms.equation_residuals_linf(timestep_idx, :) = linf_norms;
        end
    end
    
    # ========================================
    # GLOBAL RESIDUAL METRICS
    # ========================================
    
    % Global L2 norm
    if isfield(residual_data, 'global_l2_norm')
        solver_diagnostics.residual_norms.global_residual_l2(timestep_idx) = residual_data.global_l2_norm;
    end
    
    % Global L∞ norm
    if isfield(residual_data, 'global_linf_norm')
        solver_diagnostics.residual_norms.global_residual_linf(timestep_idx) = residual_data.global_linf_norm;
    end
    
    % Material balance error
    if isfield(residual_data, 'material_balance_error')
        solver_diagnostics.residual_norms.material_balance_error(timestep_idx) = residual_data.material_balance_error;
    end
    
    # ========================================
    # TOLERANCE ANALYSIS
    # ========================================
    
    % CNV tolerance margin
    if isfield(residual_data, 'cnv_tolerance') && isfield(residual_data, 'cnv_achieved')
        if residual_data.cnv_achieved
            solver_diagnostics.residual_norms.tolerance_margins(timestep_idx, 1) = ...
                residual_data.cnv_tolerance / max(solver_diagnostics.residual_norms.global_residual_l2(timestep_idx), 1e-16);
        end
    end
    
    % Material balance tolerance margin
    if isfield(residual_data, 'mb_tolerance') && isfield(residual_data, 'mb_achieved')
        if residual_data.mb_achieved
            solver_diagnostics.residual_norms.tolerance_margins(timestep_idx, 2) = ...
                residual_data.mb_tolerance / max(solver_diagnostics.residual_norms.material_balance_error(timestep_idx), 1e-16);
        end
    end

end

function capture_numerical_stability(solver_diagnostics, timestep_idx, stability_data)
% CAPTURE_NUMERICAL_STABILITY - Capture numerical stability and health indicators
%
% INPUTS:
%   solver_diagnostics - Main diagnostics structure (modified in-place)
%   timestep_idx       - Current timestep index
%   stability_data     - Structure with numerical stability information
%
% CANONICAL STABILITY_DATA FIELDS:
%   condition_number   - Matrix condition number
%   pivot_magnitude    - Smallest pivot magnitude
%   roundoff_error     - Estimated roundoff error
%   solution_quality   - Solution quality indicators
%   physical_validity  - Physical constraint violations

    if timestep_idx < 1 || timestep_idx > length(solver_diagnostics.numerical_stability.condition_number_trend)
        error(['Invalid timestep index for stability diagnostics: %d\n' ...
               'REQUIRED: timestep_idx must be within simulation range.\n' ...
               'Canon requires valid stability tracking.'], timestep_idx);
    end
    
    # ========================================
    # MATRIX CONDITIONING
    # ========================================
    
    % Condition number tracking
    if isfield(stability_data, 'condition_number')
        solver_diagnostics.numerical_stability.condition_number_trend(timestep_idx) = stability_data.condition_number;
        
        % Near-singularity detection
        if stability_data.condition_number > 1e12
            solver_diagnostics.numerical_stability.near_singularity_detected(timestep_idx) = true;
        end
    end
    
    % Pivot magnitude
    if isfield(stability_data, 'pivot_magnitude')
        solver_diagnostics.numerical_stability.pivot_magnitude(timestep_idx) = stability_data.pivot_magnitude;
    end
    
    % Matrix norm changes
    if timestep_idx > 1 && isfield(stability_data, 'matrix_norm')
        current_norm = stability_data.matrix_norm;
        previous_norm = solver_diagnostics.numerical_stability.matrix_norm_changes(timestep_idx-1);
        if previous_norm > 0
            solver_diagnostics.numerical_stability.matrix_norm_changes(timestep_idx) = ...
                current_norm / previous_norm;
        else
            solver_diagnostics.numerical_stability.matrix_norm_changes(timestep_idx) = current_norm;
        end
    end
    
    # ========================================
    # ACCURACY INDICATORS
    # ========================================
    
    % Roundoff error estimation
    if isfield(stability_data, 'roundoff_error_estimate')
        solver_diagnostics.numerical_stability.roundoff_error_estimate(timestep_idx) = ...
            stability_data.roundoff_error_estimate;
    end
    
    % Backward error
    if isfield(stability_data, 'backward_error')
        solver_diagnostics.numerical_stability.backward_error(timestep_idx) = stability_data.backward_error;
    end
    
    % Solution smoothness
    if isfield(stability_data, 'solution_smoothness')
        solver_diagnostics.numerical_stability.solution_smoothness(timestep_idx) = stability_data.solution_smoothness;
    end
    
    # ========================================
    # PHYSICAL VALIDITY
    # ========================================
    
    % Negative pressure detection
    if isfield(stability_data, 'negative_pressures')
        solver_diagnostics.numerical_stability.negative_pressures(timestep_idx) = stability_data.negative_pressures;
    end
    
    % Saturation violations
    if isfield(stability_data, 'saturation_violations')
        solver_diagnostics.numerical_stability.saturation_violations(timestep_idx) = stability_data.saturation_violations;
    end
    
    % General unphysical values flag
    if isfield(stability_data, 'unphysical_detected')
        solver_diagnostics.numerical_stability.unphysical_values_detected(timestep_idx) = ...
            stability_data.unphysical_detected;
    end

end

function final_diagnostics = finalize_solver_diagnostics(solver_diagnostics)
% FINALIZE_SOLVER_DIAGNOSTICS - Complete diagnostics processing and generate summary statistics
%
% INPUTS:
%   solver_diagnostics - Complete diagnostics structure
%
% OUTPUTS:
%   final_diagnostics - Finalized diagnostics with summary statistics
%
% PROCESSING:
%   - Calculate aggregate statistics
%   - Generate ML-ready feature matrices
%   - Validate data completeness
%   - Prepare canonical export format

    fprintf('📊 Finalizing solver diagnostics...\n');
    
    % Copy input structure
    final_diagnostics = solver_diagnostics;
    
    % ========================================
    # SUMMARY STATISTICS
    # ========================================
    
    final_diagnostics.summary_statistics = struct();
    
    % Convergence summary
    final_diagnostics.summary_statistics.total_newton_iterations = ...
        sum(final_diagnostics.convergence_data.newton_iterations);
    final_diagnostics.summary_statistics.average_iterations_per_timestep = ...
        mean(final_diagnostics.convergence_data.newton_iterations);
    final_diagnostics.summary_statistics.max_iterations_per_timestep = ...
        max(final_diagnostics.convergence_data.newton_iterations);
    final_diagnostics.summary_statistics.convergence_success_rate = ...
        sum(final_diagnostics.convergence_data.convergence_achieved) / ...
        length(final_diagnostics.convergence_data.convergence_achieved);
    
    % Performance summary
    total_simulation_time = sum(final_diagnostics.performance_metrics.total_timestep_time);
    final_diagnostics.summary_statistics.total_simulation_time_hours = total_simulation_time / 3600;
    final_diagnostics.summary_statistics.average_timestep_time_minutes = ...
        mean(final_diagnostics.performance_metrics.total_timestep_time) / 60;
    final_diagnostics.summary_statistics.peak_memory_usage_gb = ...
        max(final_diagnostics.performance_metrics.peak_memory_mb) / 1024;
    
    % Stability summary
    final_diagnostics.summary_statistics.worst_condition_number = ...
        max(final_diagnostics.numerical_stability.condition_number_trend);
    final_diagnostics.summary_statistics.stability_issues_count = ...
        sum(final_diagnostics.numerical_stability.near_singularity_detected) + ...
        sum(final_diagnostics.numerical_stability.unphysical_values_detected);
    
    # ========================================
    # ML FEATURE ENGINEERING
    # ========================================
    
    final_diagnostics.ml_features = struct();
    
    % Convergence features
    final_diagnostics.ml_features.convergence_features = create_convergence_features(final_diagnostics);
    
    % Performance features
    final_diagnostics.ml_features.performance_features = create_performance_features(final_diagnostics);
    
    % Stability features  
    final_diagnostics.ml_features.stability_features = create_stability_features(final_diagnostics);
    
    % Temporal features (lag features, derivatives)
    final_diagnostics.ml_features.temporal_features = create_temporal_features(final_diagnostics);
    
    # ========================================
    # DATA QUALITY VALIDATION
    # ========================================
    
    final_diagnostics.data_quality = struct();
    
    % Completeness check
    final_diagnostics.data_quality.completeness_percentage = calculate_data_completeness(final_diagnostics);
    
    % Consistency validation
    final_diagnostics.data_quality.consistency_checks = validate_data_consistency(final_diagnostics);
    
    % Outlier detection
    final_diagnostics.data_quality.outliers_detected = detect_diagnostic_outliers(final_diagnostics);
    
    # ========================================
    # CANONICAL METADATA
    # ========================================
    
    final_diagnostics.metadata.finalization_time = datestr(now, 'yyyy-mm-ddTHH:MM:SS');
    final_diagnostics.metadata.data_quality_score = final_diagnostics.data_quality.completeness_percentage;
    final_diagnostics.metadata.ml_readiness = assess_ml_readiness(final_diagnostics);
    final_diagnostics.metadata.canonical_version = 'solver_diagnostics_v1.0';
    
    fprintf('   ✅ Diagnostics finalized\n');
    fprintf('   📈 Convergence success rate: %.1f%%\n', final_diagnostics.summary_statistics.convergence_success_rate * 100);
    fprintf('   ⏱️  Total simulation time: %.1f hours\n', final_diagnostics.summary_statistics.total_simulation_time_hours);
    fprintf('   🎯 Data quality score: %.1f%%\n', final_diagnostics.data_quality.completeness_percentage);
    fprintf('   🤖 ML readiness: %s\n', final_diagnostics.metadata.ml_readiness);

end

function save_solver_diagnostics_canonical(solver_diagnostics, step_name, varargin)
% SAVE_SOLVER_DIAGNOSTICS_CANONICAL - Save diagnostics using canonical data organization
%
% INPUTS:
%   solver_diagnostics - Complete solver diagnostics structure
%   step_name         - Canonical step name (e.g., 's21_diagnostics')
%   varargin          - Optional parameters for canonical save
%
% CANONICAL ORGANIZATION:
%   by_type/solver/convergence/       - Newton iteration data
%   by_type/solver/performance/       - Timing and memory data
%   by_type/solver/stability/         - Numerical stability indicators
%   by_usage/ML_training/solver/      - ML-ready features
%   by_phase/simulation/diagnostics/  - Simulation phase organization

    % Parse optional arguments
    p = inputParser;
    addParameter(p, 'timestamp', datestr(now, 'yyyymmdd_HHMMSS'), @ischar);
    addParameter(p, 'base_path', '', @ischar);
    parse(p, varargin{:});
    
    fprintf('💾 Saving solver diagnostics to canonical organization...\n');
    
    % Prepare canonical data structure
    canonical_data = struct();
    canonical_data.solver_diagnostics = solver_diagnostics;
    canonical_data.data_type = 'solver_internal_diagnostics';
    canonical_data.capture_method = 'real_time_hooks';
    canonical_data.ml_features_included = true;
    
    % Add canonical metadata
    canonical_data.canonical_metadata = struct();
    canonical_data.canonical_metadata.data_category = 'solver_internal';
    canonical_data.canonical_metadata.subcategory = 'convergence_diagnostics';
    canonical_data.canonical_metadata.intended_usage = {'ML_training', 'performance_analysis', 'debugging'};
    canonical_data.canonical_metadata.simulation_phase = 'dynamic_simulation';
    canonical_data.canonical_metadata.criticality = 'high';  % Cannot be recreated without re-simulation
    
    try
        % Use canonical data utilities for organized export
        script_dir = fileparts(mfilename('fullpath'));
        addpath(script_dir);
        
        output_files = save_canonical_data(step_name, canonical_data, ...
            'base_path', p.Results.base_path, ...
            'timestamp', p.Results.timestamp, ...
            'formats', {'mat', 'yaml'}, ...
            'organizations', {'by_type', 'by_usage', 'by_phase'});
        
        fprintf('   ✅ Canonical solver diagnostics saved\n');
        fprintf('   📄 Primary files: %d\n', length(output_files.primary_files));
        fprintf('   🔗 Symlinks created: %d\n', length(output_files.symlinks));
        
        % Additional ML-focused export
        export_ml_ready_diagnostics(solver_diagnostics, output_files, p.Results.timestamp);
        
    catch ME
        error(['Failed to save solver diagnostics to canonical organization: %s\n' ...
               'REQUIRED: Canonical save must complete successfully.\n' ...
               'Canon requires organized solver diagnostics for ML pipeline.'], ME.message);
    end

end

% ========================================
% HELPER FUNCTIONS
% ========================================

function memory_mb = estimate_diagnostics_memory_mb(solver_diagnostics)
% Estimate memory usage of diagnostics structure
    
    n_timesteps = length(solver_diagnostics.convergence_data.newton_iterations);
    max_iterations = size(solver_diagnostics.convergence_data.residual_norms_by_iteration, 2);
    n_equations = size(solver_diagnostics.residual_norms.equation_residuals, 2);
    
    % Estimate memory requirements (rough calculation)
    bytes_per_double = 8;
    
    % Arrays in structure
    convergence_arrays = n_timesteps * (1 + 1 + 1 + 1 + max_iterations * 3) * bytes_per_double;
    residual_arrays = n_timesteps * (n_equations * 3 + 6) * bytes_per_double;
    linear_solver_arrays = n_timesteps * (4 + max_iterations * 3 + 3) * bytes_per_double;
    timestep_arrays = n_timesteps * 10 * bytes_per_double;
    performance_arrays = n_timesteps * (5 + 3 + max_iterations) * bytes_per_double;
    stability_arrays = n_timesteps * 8 * bytes_per_double;
    
    total_bytes = convergence_arrays + residual_arrays + linear_solver_arrays + ...
                  timestep_arrays + performance_arrays + stability_arrays;
    
    memory_mb = total_bytes / (1024 * 1024);

end

function convergence_features = create_convergence_features(diagnostics)
% Create ML-ready convergence features
    
    convergence_features = struct();
    
    % Basic convergence metrics
    convergence_features.newton_iterations = diagnostics.convergence_data.newton_iterations;
    convergence_features.convergence_success = double(diagnostics.convergence_data.convergence_achieved);
    convergence_features.stagnation_episodes = double(diagnostics.convergence_data.stagnation_detected);
    
    % Convergence rate features
    convergence_features.avg_residual_reduction = zeros(size(convergence_features.newton_iterations));
    for i = 1:length(convergence_features.newton_iterations)
        residuals = diagnostics.convergence_data.residual_norms_by_iteration(i, :);
        valid_residuals = residuals(residuals > 0);
        if length(valid_residuals) > 1
            reductions = diff(log10(valid_residuals + 1e-16));
            convergence_features.avg_residual_reduction(i) = mean(reductions);
        end
    end
    
    % Convergence difficulty indicators
    convergence_features.convergence_difficulty = convergence_features.newton_iterations ./ ...
        max(convergence_features.newton_iterations);

end

function performance_features = create_performance_features(diagnostics)
% Create ML-ready performance features
    
    performance_features = struct();
    
    % Timing features
    performance_features.total_timestep_time = diagnostics.performance_metrics.total_timestep_time;
    performance_features.newton_solve_fraction = diagnostics.performance_metrics.newton_solve_time ./ ...
        max(diagnostics.performance_metrics.total_timestep_time, 1e-6);
    performance_features.jacobian_time_fraction = diagnostics.performance_metrics.jacobian_time ./ ...
        max(diagnostics.performance_metrics.total_timestep_time, 1e-6);
    
    % Memory features
    performance_features.peak_memory_mb = diagnostics.performance_metrics.peak_memory_mb;
    performance_features.memory_growth = [0; diff(performance_features.peak_memory_mb)];
    
    % Efficiency indicators
    performance_features.time_per_iteration = performance_features.total_timestep_time ./ ...
        max(diagnostics.convergence_data.newton_iterations, 1);

end

function stability_features = create_stability_features(diagnostics)
% Create ML-ready stability features
    
    stability_features = struct();
    
    # Matrix conditioning features
    stability_features.condition_number = diagnostics.numerical_stability.condition_number_trend;
    stability_features.log_condition_number = log10(max(stability_features.condition_number, 1));
    stability_features.near_singular = double(diagnostics.numerical_stability.near_singularity_detected);
    
    % Solution quality features
    stability_features.roundoff_error = diagnostics.numerical_stability.roundoff_error_estimate;
    stability_features.backward_error = diagnostics.numerical_stability.backward_error;
    stability_features.solution_smoothness = diagnostics.numerical_stability.solution_smoothness;
    
    % Physical validity features
    stability_features.negative_pressures = diagnostics.numerical_stability.negative_pressures;
    stability_features.saturation_violations = diagnostics.numerical_stability.saturation_violations;
    stability_features.unphysical_detected = double(diagnostics.numerical_stability.unphysical_values_detected);

end

function temporal_features = create_temporal_features(diagnostics)
% Create temporal ML features (lags, derivatives, trends)
    
    temporal_features = struct();
    
    % Lag features (previous timestep influence)
    iterations = diagnostics.convergence_data.newton_iterations;
    temporal_features.iterations_lag1 = [0; iterations(1:end-1)];
    temporal_features.iterations_lag2 = [0; 0; iterations(1:end-2)];
    
    # Derivative features (change rates)
    temporal_features.iterations_change = [0; diff(iterations)];
    temporal_features.condition_number_change = [0; diff(diagnostics.numerical_stability.condition_number_trend)];
    
    % Trend features (moving averages)
    window_size = min(5, length(iterations));
    temporal_features.iterations_moving_avg = movmean(iterations, window_size);
    temporal_features.timestep_size_trend = movmean(diagnostics.timestep_control.timestep_size_days, window_size);

end

function completeness = calculate_data_completeness(diagnostics)
% Calculate percentage of diagnostic data completeness
    
    total_fields = 0;
    complete_fields = 0;
    
    % Check main diagnostic arrays
    arrays_to_check = {
        'convergence_data.newton_iterations',
        'residual_norms.global_residual_l2',
        'timestep_control.timestep_size_days',
        'performance_metrics.total_timestep_time',
        'numerical_stability.condition_number_trend'
    };
    
    for i = 1:length(arrays_to_check)
        total_fields = total_fields + 1;
        field_path = arrays_to_check{i};
        
        try
            data = getfield(diagnostics, strsplit(field_path, '.')');
            if ~isempty(data) && sum(~isnan(data) & data ~= 0) > length(data) * 0.8
                complete_fields = complete_fields + 1;
            end
        catch
            % Field doesn't exist or is inaccessible
        end
    end
    
    completeness = (complete_fields / total_fields) * 100;

end

function consistency_checks = validate_data_consistency(diagnostics)
% Validate internal consistency of diagnostic data
    
    consistency_checks = struct();
    consistency_checks.passed = true;
    consistency_checks.issues = {};
    
    n_timesteps = length(diagnostics.convergence_data.newton_iterations);
    
    % Check array length consistency
    arrays_to_check = {
        diagnostics.residual_norms.global_residual_l2,
        diagnostics.timestep_control.timestep_size_days,
        diagnostics.performance_metrics.total_timestep_time
    };
    
    for i = 1:length(arrays_to_check)
        if length(arrays_to_check{i}) ~= n_timesteps
            consistency_checks.passed = false;
            consistency_checks.issues{end+1} = sprintf('Array %d length mismatch', i);
        end
    end
    
    # Check logical consistency
    % Convergence should correlate with low iteration counts
    high_iter_converged = sum(diagnostics.convergence_data.newton_iterations > 20 & ...
                             diagnostics.convergence_data.convergence_achieved);
    if high_iter_converged > n_timesteps * 0.1  % More than 10% seems inconsistent
        consistency_checks.passed = false;
        consistency_checks.issues{end+1} = 'High iteration convergence rate seems inconsistent';
    end

end

function outliers = detect_diagnostic_outliers(diagnostics)
% Detect outliers in diagnostic data
    
    outliers = struct();
    
    % Detect outliers in iteration counts
    iterations = diagnostics.convergence_data.newton_iterations;
    q75 = prctile(iterations, 75);
    q25 = prctile(iterations, 25);
    iqr = q75 - q25;
    outlier_threshold = q75 + 1.5 * iqr;
    outliers.iteration_outliers = sum(iterations > outlier_threshold);
    
    # Detect outliers in timing
    times = diagnostics.performance_metrics.total_timestep_time;
    times = times(times > 0);  % Filter valid times
    if ~isempty(times)
        q75_time = prctile(times, 75);
        q25_time = prctile(times, 25);
        iqr_time = q75_time - q25_time;
        time_threshold = q75_time + 1.5 * iqr_time;
        outliers.timing_outliers = sum(times > time_threshold);
    else
        outliers.timing_outliers = 0;
    end
    
    outliers.total_outliers = outliers.iteration_outliers + outliers.timing_outliers;

end

function ml_readiness = assess_ml_readiness(diagnostics)
% Assess ML readiness of diagnostic data
    
    readiness_score = 0;
    max_score = 5;
    
    % Check data completeness (20%)
    if diagnostics.data_quality.completeness_percentage > 90
        readiness_score = readiness_score + 1;
    end
    
    % Check data consistency (20%)
    if diagnostics.data_quality.consistency_checks.passed
        readiness_score = readiness_score + 1;
    end
    
    % Check feature availability (20%)
    if isfield(diagnostics, 'ml_features') && isfield(diagnostics.ml_features, 'convergence_features')
        readiness_score = readiness_score + 1;
    end
    
    % Check temporal coverage (20%)
    if length(diagnostics.convergence_data.newton_iterations) > 20  # Sufficient data points
        readiness_score = readiness_score + 1;
    end
    
    % Check outlier level (20%)
    if diagnostics.data_quality.outliers_detected.total_outliers < length(diagnostics.convergence_data.newton_iterations) * 0.05
        readiness_score = readiness_score + 1;
    end
    
    if readiness_score >= 4
        ml_readiness = 'excellent';
    elseif readiness_score >= 3
        ml_readiness = 'good';
    elseif readiness_score >= 2
        ml_readiness = 'fair';
    else
        ml_readiness = 'poor';
    end

end

function export_ml_ready_diagnostics(solver_diagnostics, output_files, timestamp)
% Export ML-ready format diagnostics for Python/ML pipeline
    
    if ~isfield(solver_diagnostics, 'ml_features')
        return;
    end
    
    fprintf('   🤖 Exporting ML-ready diagnostics...\n');
    
    % Create ML features matrix
    ml_data = struct();
    ml_data.convergence_features = solver_diagnostics.ml_features.convergence_features;
    ml_data.performance_features = solver_diagnostics.ml_features.performance_features;
    ml_data.stability_features = solver_diagnostics.ml_features.stability_features;
    ml_data.temporal_features = solver_diagnostics.ml_features.temporal_features;
    
    # Add metadata for ML pipeline
    ml_data.metadata = struct();
    ml_data.metadata.feature_version = 'v1.0';
    ml_data.metadata.export_timestamp = timestamp;
    ml_data.metadata.data_quality_score = solver_diagnostics.data_quality.completeness_percentage;
    ml_data.metadata.ml_readiness = solver_diagnostics.metadata.ml_readiness;
    
    # Save ML-ready format
    ml_file = strrep(output_files.primary_files{1}, '.mat', '_ml_features.mat');
    save(ml_file, 'ml_data');
    
    fprintf('       ML features exported to: %s\n', ml_file);

end

function create_solver_diagnostics_summary(solver_diagnostics, summary_file)
% Create comprehensive summary report for solver diagnostics
    
    fid = fopen(summary_file, 'w');
    if fid == -1
        error('Cannot create solver diagnostics summary file: %s', summary_file);
    end
    
    try
        fprintf(fid, 'MRST Solver Diagnostics Summary\n');
        fprintf(fid, 'Generated: %s\n', datestr(now));
        fprintf(fid, '=====================================\n\n');
        
        % Overview
        fprintf(fid, 'SIMULATION OVERVIEW:\n');
        fprintf(fid, '  Total Timesteps: %d\n', length(solver_diagnostics.convergence_data.newton_iterations));
        fprintf(fid, '  Grid Cells: %d\n', solver_diagnostics.metadata.grid_cells);
        fprintf(fid, '  Total Wells: %d\n', solver_diagnostics.metadata.total_wells);
        fprintf(fid, '\n');
        
        % Convergence Summary
        if isfield(solver_diagnostics, 'summary_statistics')
            stats = solver_diagnostics.summary_statistics;
            fprintf(fid, 'CONVERGENCE SUMMARY:\n');
            fprintf(fid, '  Total Newton Iterations: %d\n', stats.total_newton_iterations);
            fprintf(fid, '  Average Iterations/Timestep: %.1f\n', stats.average_iterations_per_timestep);
            fprintf(fid, '  Maximum Iterations/Timestep: %d\n', stats.max_iterations_per_timestep);
            fprintf(fid, '  Convergence Success Rate: %.1f%%\n', stats.convergence_success_rate * 100);
            fprintf(fid, '\n');
            
            # Performance Summary
            fprintf(fid, 'PERFORMANCE SUMMARY:\n');
            fprintf(fid, '  Total Simulation Time: %.1f hours\n', stats.total_simulation_time_hours);
            fprintf(fid, '  Average Timestep Time: %.1f minutes\n', stats.average_timestep_time_minutes);
            fprintf(fid, '  Peak Memory Usage: %.1f GB\n', stats.peak_memory_usage_gb);
            fprintf(fid, '\n');
            
            % Stability Summary
            fprintf(fid, 'NUMERICAL STABILITY:\n');
            fprintf(fid, '  Worst Condition Number: %.2e\n', stats.worst_condition_number);
            fprintf(fid, '  Stability Issues: %d\n', stats.stability_issues_count);
            fprintf(fid, '\n');
        end
        
        % Data Quality
        if isfield(solver_diagnostics, 'data_quality')
            fprintf(fid, 'DATA QUALITY ASSESSMENT:\n');
            fprintf(fid, '  Completeness: %.1f%%\n', solver_diagnostics.data_quality.completeness_percentage);
            fprintf(fid, '  Consistency: %s\n', ternary_str(solver_diagnostics.data_quality.consistency_checks.passed, 'PASS', 'FAIL'));
            fprintf(fid, '  ML Readiness: %s\n', upper(solver_diagnostics.metadata.ml_readiness));
            fprintf(fid, '\n');
        end
        
        fclose(fid);
        
    catch ME
        fclose(fid);
        error('Error writing solver diagnostics summary: %s', ME.message);
    end

end

function result = ternary_str(condition, true_str, false_str)
% String ternary operator
    if condition
        result = true_str;
    else
        result = false_str;
    end
end