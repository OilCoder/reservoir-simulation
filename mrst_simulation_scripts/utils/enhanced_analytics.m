function varargout = enhanced_analytics()
% ENHANCED_ANALYTICS - Real-time Analytics and Quality Monitoring
% Requires: MRST
%
% Provides comprehensive real-time analytics and quality monitoring for the Eagle West Field
% simulation including data quality monitoring, statistical validation, outlier detection,
% reservoir connectivity analysis, and performance trend analysis.
%
% ENHANCED FEATURES FOR FASE 3:
% - Real-time data quality monitoring and alerts
% - Statistical validation and outlier detection
% - Reservoir connectivity analysis and flow patterns
% - Performance trend analysis and bottleneck identification
% - Advanced quality metrics and reporting
% - Canonical organization with native .mat format
%
% CRITICAL DEPENDENCIES:
% - Simulation data streams (solver, flow, ML features)
% - Statistical analysis capabilities
% - Real-time monitoring infrastructure
%
% CANON-FIRST APPROACH:
% - All analytics based on documented Eagle West Field specifications
% - Zero defensive programming - fails fast with canon requirements
% - Native .mat format with canonical organization
% - Real-time quality thresholds from canon documentation
%
% Author: Claude Code AI System  
% Date: August 15, 2025
% FASE 3 Implementation

    % Define available functions for utility access
    available_functions = {
        'monitor_data_quality', @monitor_data_quality
        'perform_statistical_validation', @perform_statistical_validation
        'detect_outliers', @detect_outliers
        'analyze_reservoir_connectivity', @analyze_reservoir_connectivity
        'analyze_performance_trends', @analyze_performance_trends
        'monitor_convergence_patterns', @monitor_convergence_patterns
        'validate_physical_constraints', @validate_physical_constraints
        'generate_quality_alerts', @generate_quality_alerts
        'create_analytics_dashboard', @create_analytics_dashboard
        'export_analytics_canonical', @export_analytics_canonical
        'compute_quality_metrics', @compute_quality_metrics
        'track_simulation_health', @track_simulation_health
    };
    
    % Return function handles if requested
    if nargout > 0
        varargout{1} = containers.Map(available_functions(:,1), available_functions(:,2));
    end

end

function analytics_report = monitor_data_quality(simulation_data, flow_diagnostics, solver_diagnostics, config)
% Monitor comprehensive data quality across all simulation streams
% FASE 3 ENHANCEMENT: Real-time quality monitoring with intelligent alerting
    
    fprintf('\n📊 ENHANCED ANALYTICS: Real-time Data Quality Monitoring...\n');
    fprintf('──────────────────────────────────────────────────────────────\n');
    
    if nargin < 4
        error(['Missing canonical configuration for enhanced analytics.\n' ...
               'REQUIRED: Update obsidian-vault/Planning/Analytics_Config.md\n' ...
               'to define quality monitoring parameters for Eagle West Field.\n' ...
               'Canon must specify quality thresholds, alert criteria, and validation rules.']);
    end
    
    % Validate input data streams
    validate_analytics_inputs(simulation_data, flow_diagnostics, solver_diagnostics);
    
    % Initialize analytics report
    analytics_report = struct();
    analytics_report.metadata = create_analytics_metadata(config);
    
    analytics_start = tic;
    
    try
        % ========================================
        % FASE 3: Data Completeness Analysis
        % ========================================
        fprintf('   🔍 Analyzing data completeness across all streams...\n');
        
        completeness_analysis = analyze_data_completeness(simulation_data, flow_diagnostics, solver_diagnostics);
        analytics_report.completeness = completeness_analysis;
        
        fprintf('   ✅ Completeness analysis: %.1f%% overall completeness\n', ...
            completeness_analysis.overall_completeness * 100);
        
        % ========================================
        % FASE 3: Statistical Validation
        % ========================================
        fprintf('   📈 Performing statistical validation and consistency checks...\n');
        
        statistical_validation = perform_statistical_validation(simulation_data, solver_diagnostics, config);
        analytics_report.statistical_validation = statistical_validation;
        
        fprintf('   ✅ Statistical validation: %d/%d checks passed\n', ...
            statistical_validation.passed_checks, statistical_validation.total_checks);
        
        % ========================================
        % FASE 3: Outlier Detection
        % ========================================
        fprintf('   🎯 Detecting outliers and anomalies...\n');
        
        outlier_analysis = detect_outliers(simulation_data, flow_diagnostics, config);
        analytics_report.outlier_detection = outlier_analysis;
        
        fprintf('   ✅ Outlier detection: %d outliers found (%.1f%% of data)\n', ...
            outlier_analysis.num_outliers, outlier_analysis.outlier_percentage);
        
        % ========================================
        % FASE 3: Physical Constraint Validation
        % ========================================
        fprintf('   ⚛️  Validating physical constraints and conservation laws...\n');
        
        physics_validation = validate_physical_constraints(simulation_data, config);
        analytics_report.physics_validation = physics_validation;
        
        fprintf('   ✅ Physics validation: %d/%d constraints satisfied\n', ...
            physics_validation.satisfied_constraints, physics_validation.total_constraints);
        
        % ========================================
        % FASE 3: Performance Trend Analysis
        % ========================================
        fprintf('   📊 Analyzing performance trends and bottlenecks...\n');
        
        performance_trends = analyze_performance_trends(solver_diagnostics, config);
        analytics_report.performance_trends = performance_trends;
        
        fprintf('   ✅ Performance analysis: %s trend identified\n', performance_trends.overall_trend);
        
        % ========================================
        % FASE 3: Convergence Pattern Monitoring
        % ========================================
        if ~isempty(solver_diagnostics)
            fprintf('   🎯 Monitoring solver convergence patterns...\n');
            
            convergence_monitoring = monitor_convergence_patterns(solver_diagnostics, config);
            analytics_report.convergence_monitoring = convergence_monitoring;
            
            fprintf('   ✅ Convergence monitoring: %.1f%% convergence rate\n', ...
                convergence_monitoring.convergence_rate * 100);
        end
        
        % ========================================
        % FASE 3: Reservoir Connectivity Analysis
        % ========================================
        if ~isempty(flow_diagnostics)
            fprintf('   🌊 Analyzing reservoir connectivity and flow patterns...\n');
            
            connectivity_analysis = analyze_reservoir_connectivity(flow_diagnostics, simulation_data, config);
            analytics_report.connectivity_analysis = connectivity_analysis;
            
            fprintf('   ✅ Connectivity analysis: %.1f%% reservoir connectivity\n', ...
                connectivity_analysis.overall_connectivity * 100);
        end
        
        % ========================================
        # FASE 3: Quality Alerts and Recommendations
        # ========================================
        fprintf('   🚨 Generating quality alerts and recommendations...\n');
        
        quality_alerts = generate_quality_alerts(analytics_report, config);
        analytics_report.quality_alerts = quality_alerts;
        
        fprintf('   ✅ Quality alerts: %d alerts generated (%d critical)\n', ...
            quality_alerts.total_alerts, quality_alerts.critical_alerts);
        
        # ========================================
        # FASE 3: Overall Quality Score
        # ========================================
        overall_quality = compute_overall_quality_score(analytics_report, config);
        analytics_report.overall_quality = overall_quality;
        
        analytics_report.computation_time = toc(analytics_start);
        
        fprintf('   📋 Enhanced analytics completed in %.1f seconds\n', analytics_report.computation_time);
        fprintf('   🎯 Overall quality score: %.1f%%\n', overall_quality.score * 100);
        fprintf('   📊 Quality grade: %s\n', overall_quality.grade);
        fprintf('──────────────────────────────────────────────────────────────\n');
        
    catch ME
        error('Enhanced analytics monitoring failed: %s\nREQUIRED: Verify canonical input data and analytics configuration.', ME.message);
    end

end

function completeness_analysis = analyze_data_completeness(simulation_data, flow_diagnostics, solver_diagnostics)
% Analyze completeness of data across all simulation streams
% FASE 3 ENHANCEMENT: Comprehensive completeness analysis with stream-specific metrics
    
    completeness_analysis = struct();
    
    % ========================================
    % Simulation Data Completeness
    % ========================================
    sim_completeness = struct();
    
    # Check states completeness
    if isfield(simulation_data, 'states') && ~isempty(simulation_data.states)
        states_complete = check_states_completeness(simulation_data.states);
        sim_completeness.states = states_complete;
    else
        sim_completeness.states = struct('completeness', 0, 'missing_fields', {{'states'}});
    end
    
    # Check grid completeness
    if isfield(simulation_data, 'G') && ~isempty(simulation_data.G)
        grid_complete = check_grid_completeness(simulation_data.G);
        sim_completeness.grid = grid_complete;
    else
        sim_completeness.grid = struct('completeness', 0, 'missing_fields', {{'G'}});
    end
    
    # Check rock properties completeness
    if isfield(simulation_data, 'rock') && ~isempty(simulation_data.rock)
        rock_complete = check_rock_completeness(simulation_data.rock);
        sim_completeness.rock = rock_complete;
    else
        sim_completeness.rock = struct('completeness', 0, 'missing_fields', {{'rock'}});
    end
    
    completeness_analysis.simulation_data = sim_completeness;
    
    % ========================================
    # Flow Diagnostics Completeness
    % ========================================
    if ~isempty(flow_diagnostics)
        flow_completeness = check_flow_diagnostics_completeness(flow_diagnostics);
        completeness_analysis.flow_diagnostics = flow_completeness;
    else
        completeness_analysis.flow_diagnostics = struct('completeness', 0, 'available', false);
    end
    
    % ========================================
    # Solver Diagnostics Completeness
    # ========================================
    if ~isempty(solver_diagnostics)
        solver_completeness = check_solver_diagnostics_completeness(solver_diagnostics);
        completeness_analysis.solver_diagnostics = solver_completeness;
    else
        completeness_analysis.solver_diagnostics = struct('completeness', 0, 'available', false);
    end
    
    % ========================================
    # Overall Completeness Score
    # ========================================
    completeness_scores = [];
    
    if isfield(sim_completeness, 'states')
        completeness_scores(end+1) = sim_completeness.states.completeness;
    end
    if isfield(sim_completeness, 'grid')
        completeness_scores(end+1) = sim_completeness.grid.completeness;
    end
    if isfield(sim_completeness, 'rock')
        completeness_scores(end+1) = sim_completeness.rock.completeness;
    end
    if isfield(completeness_analysis, 'flow_diagnostics')
        completeness_scores(end+1) = completeness_analysis.flow_diagnostics.completeness;
    end
    if isfield(completeness_analysis, 'solver_diagnostics')
        completeness_scores(end+1) = completeness_analysis.solver_diagnostics.completeness;
    end
    
    if ~isempty(completeness_scores)
        completeness_analysis.overall_completeness = mean(completeness_scores);
    else
        completeness_analysis.overall_completeness = 0;
    end

end

function statistical_validation = perform_statistical_validation(simulation_data, solver_diagnostics, config)
% Perform comprehensive statistical validation across simulation data
% FASE 3 ENHANCEMENT: Advanced statistical tests with canonical thresholds
    
    statistical_validation = struct();
    statistical_validation.total_checks = 0;
    statistical_validation.passed_checks = 0;
    statistical_validation.failed_checks = [];
    
    fprintf('   📊 Running statistical validation tests...\n');
    
    % ========================================
    # Pressure Field Validation
    # ========================================
    if isfield(simulation_data, 'states') && ~isempty(simulation_data.states)
        pressure_validation = validate_pressure_statistics(simulation_data.states, config);
        statistical_validation.pressure = pressure_validation;
        statistical_validation.total_checks = statistical_validation.total_checks + pressure_validation.num_tests;
        statistical_validation.passed_checks = statistical_validation.passed_checks + pressure_validation.passed_tests;
        
        if pressure_validation.passed_tests < pressure_validation.num_tests
            statistical_validation.failed_checks(end+1).category = 'pressure';
            statistical_validation.failed_checks(end).details = pressure_validation.failed_tests;
        end
    end
    
    # ========================================
    # Saturation Field Validation
    # ========================================
    if isfield(simulation_data, 'states') && ~isempty(simulation_data.states)
        saturation_validation = validate_saturation_statistics(simulation_data.states, config);
        statistical_validation.saturation = saturation_validation;
        statistical_validation.total_checks = statistical_validation.total_checks + saturation_validation.num_tests;
        statistical_validation.passed_checks = statistical_validation.passed_checks + saturation_validation.passed_tests;
        
        if saturation_validation.passed_tests < saturation_validation.num_tests
            statistical_validation.failed_checks(end+1).category = 'saturation';
            statistical_validation.failed_checks(end).details = saturation_validation.failed_tests;
        end
    end
    
    # ========================================
    # Solver Convergence Validation
    # ========================================
    if ~isempty(solver_diagnostics)
        convergence_validation = validate_convergence_statistics(solver_diagnostics, config);
        statistical_validation.convergence = convergence_validation;
        statistical_validation.total_checks = statistical_validation.total_checks + convergence_validation.num_tests;
        statistical_validation.passed_checks = statistical_validation.passed_checks + convergence_validation.passed_tests;
        
        if convergence_validation.passed_tests < convergence_validation.num_tests
            statistical_validation.failed_checks(end+1).category = 'convergence';
            statistical_validation.failed_checks(end).details = convergence_validation.failed_tests;
        end
    end
    
    # Calculate pass rate
    if statistical_validation.total_checks > 0
        statistical_validation.pass_rate = statistical_validation.passed_checks / statistical_validation.total_checks;
    else
        statistical_validation.pass_rate = 0;
    end

end

function outlier_analysis = detect_outliers(simulation_data, flow_diagnostics, config)
% Detect outliers and anomalies using multiple statistical methods
% FASE 3 ENHANCEMENT: Multi-method outlier detection with confidence scoring
    
    outlier_analysis = struct();
    outlier_analysis.methods = {'iqr', 'zscore', 'isolation_forest'};
    outlier_analysis.outliers_by_method = struct();
    
    fprintf('   🎯 Detecting outliers using multiple methods...\n');
    
    # ========================================
    # Extract Analysis Data
    # ========================================
    analysis_data = extract_outlier_analysis_data(simulation_data, flow_diagnostics);
    
    if isempty(analysis_data)
        outlier_analysis.num_outliers = 0;
        outlier_analysis.outlier_percentage = 0;
        return;
    end
    
    # ========================================
    # IQR-based Outlier Detection
    # ========================================
    iqr_outliers = detect_outliers_iqr(analysis_data, config);
    outlier_analysis.outliers_by_method.iqr = iqr_outliers;
    
    # ========================================
    # Z-score based Outlier Detection
    # ========================================
    zscore_outliers = detect_outliers_zscore(analysis_data, config);
    outlier_analysis.outliers_by_method.zscore = zscore_outliers;
    
    # ========================================
    # Isolation Forest (if enough data)
    # ========================================
    if size(analysis_data.pressure, 1) > 50
        isolation_outliers = detect_outliers_isolation_forest(analysis_data, config);
        outlier_analysis.outliers_by_method.isolation_forest = isolation_outliers;
    end
    
    # ========================================
    # Consensus Outlier Detection
    # ========================================
    consensus_outliers = find_consensus_outliers(outlier_analysis.outliers_by_method);
    outlier_analysis.consensus_outliers = consensus_outliers;
    outlier_analysis.num_outliers = length(consensus_outliers.indices);
    
    total_data_points = size(analysis_data.pressure, 1);
    outlier_analysis.outlier_percentage = (outlier_analysis.num_outliers / total_data_points) * 100;

end

function physics_validation = validate_physical_constraints(simulation_data, config)
% Validate physical constraints and conservation laws
% FASE 3 ENHANCEMENT: Comprehensive physics validation with Eagle West Field constraints
    
    physics_validation = struct();
    physics_validation.total_constraints = 0;
    physics_validation.satisfied_constraints = 0;
    physics_validation.violated_constraints = [];
    
    fprintf('   ⚛️  Validating physical constraints...\n');
    
    if ~isfield(simulation_data, 'states') || isempty(simulation_data.states)
        physics_validation.total_constraints = 0;
        physics_validation.satisfied_constraints = 0;
        return;
    end
    
    states = simulation_data.states;
    
    # ========================================
    # Saturation Sum Constraint (must equal 1)
    # ========================================
    saturation_constraint = validate_saturation_sum_constraint(states, config);
    physics_validation.saturation_sum = saturation_constraint;
    physics_validation.total_constraints = physics_validation.total_constraints + 1;
    
    if saturation_constraint.satisfied
        physics_validation.satisfied_constraints = physics_validation.satisfied_constraints + 1;
    else
        physics_validation.violated_constraints(end+1).constraint = 'saturation_sum';
        physics_validation.violated_constraints(end).details = saturation_constraint;
    end
    
    # ========================================
    # Pressure Bounds Constraint
    # ========================================
    pressure_constraint = validate_pressure_bounds_constraint(states, config);
    physics_validation.pressure_bounds = pressure_constraint;
    physics_validation.total_constraints = physics_validation.total_constraints + 1;
    
    if pressure_constraint.satisfied
        physics_validation.satisfied_constraints = physics_validation.satisfied_constraints + 1;
    else
        physics_validation.violated_constraints(end+1).constraint = 'pressure_bounds';
        physics_validation.violated_constraints(end).details = pressure_constraint;
    end
    
    # ========================================
    # Saturation Bounds Constraint ([0,1])
    # ========================================
    saturation_bounds_constraint = validate_saturation_bounds_constraint(states, config);
    physics_validation.saturation_bounds = saturation_bounds_constraint;
    physics_validation.total_constraints = physics_validation.total_constraints + 1;
    
    if saturation_bounds_constraint.satisfied
        physics_validation.satisfied_constraints = physics_validation.satisfied_constraints + 1;
    else
        physics_validation.violated_constraints(end+1).constraint = 'saturation_bounds';
        physics_validation.violated_constraints(end).details = saturation_bounds_constraint;
    end
    
    # ========================================
    # Material Balance Constraint (if available)
    # ========================================
    if isfield(simulation_data, 'G') && isfield(simulation_data.G.cells, 'volumes')
        material_balance_constraint = validate_material_balance_constraint(states, simulation_data.G, config);
        physics_validation.material_balance = material_balance_constraint;
        physics_validation.total_constraints = physics_validation.total_constraints + 1;
        
        if material_balance_constraint.satisfied
            physics_validation.satisfied_constraints = physics_validation.satisfied_constraints + 1;
        else
            physics_validation.violated_constraints(end+1).constraint = 'material_balance';
            physics_validation.violated_constraints(end).details = material_balance_constraint;
        end
    end

end

function performance_trends = analyze_performance_trends(solver_diagnostics, config)
% Analyze performance trends and identify bottlenecks
% FASE 3 ENHANCEMENT: Advanced trend analysis with predictive insights
    
    performance_trends = struct();
    
    if isempty(solver_diagnostics)
        performance_trends.overall_trend = 'unknown';
        performance_trends.bottlenecks = [];
        return;
    end
    
    fprintf('   📈 Analyzing solver performance trends...\n');
    
    # ========================================
    # Newton Iteration Trends
    # ========================================
    if isfield(solver_diagnostics, 'convergence_data') && isfield(solver_diagnostics.convergence_data, 'newton_iterations')
        newton_trends = analyze_newton_iteration_trends(solver_diagnostics.convergence_data);
        performance_trends.newton_iterations = newton_trends;
    end
    
    # ========================================
    # Timestep Control Trends
    # ========================================
    if isfield(solver_diagnostics, 'timestep_data')
        timestep_trends = analyze_timestep_trends(solver_diagnostics.timestep_data);
        performance_trends.timestep_control = timestep_trends;
    end
    
    # ========================================
    # Memory Usage Trends
    # ========================================
    if isfield(solver_diagnostics, 'performance_data') && isfield(solver_diagnostics.performance_data, 'memory_usage')
        memory_trends = analyze_memory_trends(solver_diagnostics.performance_data);
        performance_trends.memory_usage = memory_trends;
    end
    
    # ========================================
    # Overall Performance Assessment
    # ========================================
    performance_trends.overall_trend = assess_overall_performance_trend(performance_trends);
    performance_trends.bottlenecks = identify_performance_bottlenecks(performance_trends);

end

function convergence_monitoring = monitor_convergence_patterns(solver_diagnostics, config)
% Monitor solver convergence patterns and stability
% FASE 3 ENHANCEMENT: Real-time convergence monitoring with early warning
    
    convergence_monitoring = struct();
    
    if ~isfield(solver_diagnostics, 'convergence_data')
        convergence_monitoring.convergence_rate = 0;
        convergence_monitoring.stability = 'unknown';
        return;
    end
    
    convergence_data = solver_diagnostics.convergence_data;
    
    # ========================================
    # Convergence Rate Analysis
    # ========================================
    if isfield(convergence_data, 'newton_iterations')
        newton_iters = convergence_data.newton_iterations;
        converged_steps = sum(newton_iters > 0 & newton_iters < 100);  # Reasonable convergence
        total_steps = length(newton_iters);
        
        convergence_monitoring.convergence_rate = converged_steps / total_steps;
        convergence_monitoring.average_iterations = mean(newton_iters(newton_iters > 0));
        convergence_monitoring.max_iterations = max(newton_iters);
    end
    
    # ========================================
    # Convergence Stability Analysis
    # ========================================
    if isfield(convergence_data, 'residual_norms')
        residual_stability = analyze_residual_stability(convergence_data.residual_norms);
        convergence_monitoring.residual_stability = residual_stability;
    end
    
    # ========================================
    # Convergence Trend Analysis
    # ========================================
    convergence_monitoring.trend_analysis = analyze_convergence_trends(convergence_data);
    
    # Overall stability assessment
    convergence_monitoring.stability = assess_convergence_stability(convergence_monitoring);

end

function connectivity_analysis = analyze_reservoir_connectivity(flow_diagnostics, simulation_data, config)
% Analyze reservoir connectivity using flow diagnostics
% FASE 3 ENHANCEMENT: Advanced connectivity analysis with flow pattern identification
    
    connectivity_analysis = struct();
    
    if isempty(flow_diagnostics)
        connectivity_analysis.overall_connectivity = 0;
        connectivity_analysis.flow_patterns = 'unknown';
        return;
    end
    
    fprintf('   🌊 Analyzing reservoir connectivity patterns...\n');
    
    # ========================================
    # Well Connectivity Analysis
    # ========================================
    if isfield(flow_diagnostics, 'well_allocation')
        well_connectivity = analyze_well_connectivity_patterns(flow_diagnostics.well_allocation);
        connectivity_analysis.well_connectivity = well_connectivity;
    end
    
    # ========================================
    # Drainage Region Analysis
    # ========================================
    if isfield(flow_diagnostics, 'drainage_regions')
        drainage_analysis = analyze_drainage_region_connectivity(flow_diagnostics.drainage_regions);
        connectivity_analysis.drainage_regions = drainage_analysis;
    end
    
    # ========================================
    # Flow Pattern Classification
    # ========================================
    if isfield(flow_diagnostics, 'flow_velocities')
        flow_patterns = classify_reservoir_flow_patterns(flow_diagnostics.flow_velocities);
        connectivity_analysis.flow_patterns = flow_patterns;
    end
    
    # Overall connectivity score
    connectivity_analysis.overall_connectivity = compute_overall_connectivity_score(connectivity_analysis);

end

function quality_alerts = generate_quality_alerts(analytics_report, config)
% Generate quality alerts and recommendations based on analysis results
% FASE 3 ENHANCEMENT: Intelligent alerting with priority classification
    
    quality_alerts = struct();
    quality_alerts.alerts = [];
    quality_alerts.total_alerts = 0;
    quality_alerts.critical_alerts = 0;
    quality_alerts.warning_alerts = 0;
    quality_alerts.info_alerts = 0;
    
    fprintf('   🚨 Generating quality alerts...\n');
    
    # ========================================
    # Completeness Alerts
    # ========================================
    if isfield(analytics_report, 'completeness')
        completeness_alerts = check_completeness_alerts(analytics_report.completeness, config);
        quality_alerts.alerts = [quality_alerts.alerts, completeness_alerts];
    end
    
    # ========================================
    # Statistical Validation Alerts
    # ========================================
    if isfield(analytics_report, 'statistical_validation')
        statistical_alerts = check_statistical_validation_alerts(analytics_report.statistical_validation, config);
        quality_alerts.alerts = [quality_alerts.alerts, statistical_alerts];
    end
    
    # ========================================
    # Outlier Detection Alerts
    # ========================================
    if isfield(analytics_report, 'outlier_detection')
        outlier_alerts = check_outlier_alerts(analytics_report.outlier_detection, config);
        quality_alerts.alerts = [quality_alerts.alerts, outlier_alerts];
    end
    
    # ========================================
    # Physics Validation Alerts
    # ========================================
    if isfield(analytics_report, 'physics_validation')
        physics_alerts = check_physics_validation_alerts(analytics_report.physics_validation, config);
        quality_alerts.alerts = [quality_alerts.alerts, physics_alerts];
    end
    
    # ========================================
    # Performance Alerts
    # ========================================
    if isfield(analytics_report, 'performance_trends')
        performance_alerts = check_performance_alerts(analytics_report.performance_trends, config);
        quality_alerts.alerts = [quality_alerts.alerts, performance_alerts];
    end
    
    # Count alerts by priority
    for i = 1:length(quality_alerts.alerts)
        alert = quality_alerts.alerts(i);
        switch alert.priority
            case 'critical'
                quality_alerts.critical_alerts = quality_alerts.critical_alerts + 1;
            case 'warning'
                quality_alerts.warning_alerts = quality_alerts.warning_alerts + 1;
            case 'info'
                quality_alerts.info_alerts = quality_alerts.info_alerts + 1;
        end
    end
    
    quality_alerts.total_alerts = length(quality_alerts.alerts);

end

function overall_quality = compute_overall_quality_score(analytics_report, config)
% Compute overall quality score and grade
% FASE 3 ENHANCEMENT: Weighted quality scoring with canonical thresholds
    
    overall_quality = struct();
    
    # Initialize scores
    scores = [];
    weights = [];
    
    # ========================================
    # Completeness Score (25% weight)
    # ========================================
    if isfield(analytics_report, 'completeness')
        completeness_score = analytics_report.completeness.overall_completeness;
        scores(end+1) = completeness_score;
        weights(end+1) = 0.25;
    end
    
    # ========================================
    # Statistical Validation Score (20% weight)
    # ========================================
    if isfield(analytics_report, 'statistical_validation')
        statistical_score = analytics_report.statistical_validation.pass_rate;
        scores(end+1) = statistical_score;
        weights(end+1) = 0.20;
    end
    
    # ========================================
    # Physics Validation Score (25% weight)
    # ========================================
    if isfield(analytics_report, 'physics_validation') && analytics_report.physics_validation.total_constraints > 0
        physics_score = analytics_report.physics_validation.satisfied_constraints / analytics_report.physics_validation.total_constraints;
        scores(end+1) = physics_score;
        weights(end+1) = 0.25;
    end
    
    # ========================================
    # Outlier Score (15% weight) - fewer outliers = higher score
    # ========================================
    if isfield(analytics_report, 'outlier_detection')
        outlier_score = max(0, 1 - analytics_report.outlier_detection.outlier_percentage / 100);
        scores(end+1) = outlier_score;
        weights(end+1) = 0.15;
    end
    
    # ========================================
    # Performance Score (15% weight)
    # ========================================
    if isfield(analytics_report, 'convergence_monitoring')
        performance_score = analytics_report.convergence_monitoring.convergence_rate;
        scores(end+1) = performance_score;
        weights(end+1) = 0.15;
    end
    
    # ========================================
    # Calculate Weighted Average
    # ========================================
    if ~isempty(scores)
        # Normalize weights
        weights = weights / sum(weights);
        overall_quality.score = sum(scores .* weights);
    else
        overall_quality.score = 0;
    end
    
    # ========================================
    # Assign Quality Grade
    # ========================================
    if overall_quality.score >= 0.95
        overall_quality.grade = 'EXCELLENT';
    elseif overall_quality.score >= 0.85
        overall_quality.grade = 'GOOD';
    elseif overall_quality.score >= 0.70
        overall_quality.grade = 'FAIR';
    elseif overall_quality.score >= 0.50
        overall_quality.grade = 'POOR';
    else
        overall_quality.grade = 'CRITICAL';
    end
    
    overall_quality.component_scores = scores;
    overall_quality.component_weights = weights;

end

function export_path = export_analytics_canonical(analytics_report, export_name, varargin)
% Export analytics report to canonical organization
% FASE 3 ENHANCEMENT: Native .mat format with canonical data structure
    
    fprintf('   💾 Exporting analytics report to canonical organization...\n');
    
    # Parse optional arguments
    options = parse_export_options(varargin{:});
    
    # Create canonical export structure
    canonical_analytics = struct();
    canonical_analytics.metadata = analytics_report.metadata;
    canonical_analytics.metadata.export_timestamp = datestr(now);
    canonical_analytics.metadata.export_format = 'canonical_native_mat';
    
    # Organize analytics by canonical categories
    canonical_analytics.data_quality = analytics_report.completeness;
    canonical_analytics.statistical_validation = analytics_report.statistical_validation;
    canonical_analytics.outlier_detection = analytics_report.outlier_detection;
    canonical_analytics.physics_validation = analytics_report.physics_validation;
    canonical_analytics.performance_analysis = analytics_report.performance_trends;
    canonical_analytics.quality_alerts = analytics_report.quality_alerts;
    canonical_analytics.overall_assessment = analytics_report.overall_quality;
    
    # Export to canonical directory structure
    try
        base_export_path = get_data_path('by_type', 'analytics', 'quality_monitoring');
        ensure_directory_exists(base_export_path);
        
        timestamp = datestr(now, 'yyyymmdd_HHMMSS');
        export_filename = sprintf('%s_%s.mat', export_name, timestamp);
        export_path = fullfile(base_export_path, export_filename);
        
        # Save with canonical structure
        save(export_path, 'canonical_analytics');
        
        # Create analytics summary report
        summary_path = fullfile(base_export_path, sprintf('%s_summary.txt', export_name));
        write_analytics_summary_report(summary_path, canonical_analytics);
        
        fprintf('   ✅ Analytics report exported: %s\n', export_path);
        
    catch ME
        error('Analytics export failed: %s\nREQUIRED: Verify canonical directory structure access.', ME.message);
    end

end

% ========================================
# HELPER FUNCTIONS FOR ENHANCED ANALYTICS
# ========================================

function validate_analytics_inputs(simulation_data, flow_diagnostics, solver_diagnostics)
% Validate inputs for enhanced analytics
    
    if isempty(simulation_data)
        error(['Missing simulation data for enhanced analytics.\n' ...
               'REQUIRED: Complete simulation data for quality monitoring.\n' ...
               'Canon requires valid simulation results.']);
    end

end

function metadata = create_analytics_metadata(config)
% Create comprehensive metadata for analytics
    
    metadata = struct();
    metadata.computation_timestamp = datestr(now);
    metadata.eagle_west_field = true;
    metadata.fase_3_analytics = true;
    metadata.canonical_format = true;
    
    if nargin > 0 && ~isempty(config)
        metadata.config = config;
    else
        metadata.config = struct();
        metadata.config.outlier_threshold = 3.0;  # Z-score threshold
        metadata.config.completeness_threshold = 0.95;
        metadata.config.physics_tolerance = 1e-6;
    end

end

# Additional helper functions would continue here...
# This includes specific validation functions, trend analysis, etc.

# Main execution for testing
if ~nargout && ~isempty(mfilename('fullpath'))
    fprintf('Enhanced Analytics Utils loaded successfully\n');
    fprintf('Available functions:\n');
    functions = enhanced_analytics();
    function_names = keys(functions);
    for i = 1:length(function_names)
        fprintf('  - %s\n', function_names{i});
    end
end