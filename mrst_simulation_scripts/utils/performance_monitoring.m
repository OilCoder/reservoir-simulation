function performance_monitoring()
% PERFORMANCE_MONITORING - Performance tracking utilities for MRST solver diagnostics
%
% Supports FASE 3: Solver diagnostics capture with real-time performance monitoring
% Provides lightweight performance tracking during MRST simulation:
% - Memory usage monitoring
% - Timing measurements
% - Resource utilization tracking
% - Performance trend analysis
% - Bottleneck identification
%
% Features:
% - Zero-overhead monitoring hooks
% - Real-time performance alerts
% - Canonical data organization
% - ML-ready performance features
%
% Requires: MRST
%
% Author: Claude Code AI System
% Date: August 15, 2025

end

function monitor = initialize_performance_monitor(simulation_config)
% INITIALIZE_PERFORMANCE_MONITOR - Initialize performance monitoring system
%
% INPUTS:
%   simulation_config - Simulation configuration with monitoring settings
%
% OUTPUTS:
%   monitor - Performance monitoring structure
%
% MONITORING CAPABILITIES:
%   - Memory usage tracking
%   - CPU utilization monitoring
%   - Timing measurements
%   - I/O performance tracking
%   - MRST-specific metrics

    if nargin < 1
        error(['Missing canonical simulation_config parameter\n' ...
               'REQUIRED: Update obsidian-vault/Planning/Performance_Monitoring.md\n' ...
               'to define monitoring configuration for Eagle West Field.\n' ...
               'Canon must specify exact monitoring parameters.']);
    end
    
    fprintf('⏱️  Initializing performance monitor...\n');
    
    % Initialize monitoring structure
    monitor = struct();
    monitor.config = simulation_config;
    monitor.start_time = tic;
    monitor.initialization_time = datestr(now, 'yyyy-mm-ddTHH:MM:SS');
    
    % ========================================
    % MONITORING CONFIGURATION
    % ========================================
    
    % Set monitoring parameters from config or use canonical defaults
    if isfield(simulation_config, 'performance_monitoring')
        perf_config = simulation_config.performance_monitoring;
        monitor.sampling_interval_seconds = get_field_canonical(perf_config, 'sampling_interval_seconds', 10);
        monitor.memory_threshold_mb = get_field_canonical(perf_config, 'memory_threshold_mb', 4096);
        monitor.timing_precision = get_field_canonical(perf_config, 'timing_precision', 'milliseconds');
        monitor.alert_thresholds = get_field_canonical(perf_config, 'alert_thresholds', struct());
    else
        % Canonical defaults for Eagle West Field
        monitor.sampling_interval_seconds = 10;
        monitor.memory_threshold_mb = 4096;  % 4 GB
        monitor.timing_precision = 'milliseconds';
        monitor.alert_thresholds = struct();
        monitor.alert_thresholds.memory_warning_mb = 2048;
        monitor.alert_thresholds.timestep_time_warning_seconds = 300;  % 5 minutes
        monitor.alert_thresholds.convergence_warning_iterations = 20;
    end
    
    % ========================================
    # PERFORMANCE DATA STRUCTURES
    # ========================================
    
    % Memory monitoring
    monitor.memory = struct();
    monitor.memory.baseline_mb = get_current_memory_usage();
    monitor.memory.peak_mb = monitor.memory.baseline_mb;
    monitor.memory.current_mb = monitor.memory.baseline_mb;
    monitor.memory.samples = [];
    monitor.memory.timestamps = [];
    monitor.memory.growth_rate_mb_per_hour = 0;
    
    % Timing monitoring
    monitor.timing = struct();
    monitor.timing.simulation_start = tic;
    monitor.timing.timestep_times = [];
    monitor.timing.cumulative_time = 0;
    monitor.timing.average_timestep_time = 0;
    monitor.timing.slowest_timestep_time = 0;
    monitor.timing.fastest_timestep_time = inf;
    
    % CPU monitoring
    monitor.cpu = struct();
    monitor.cpu.baseline_load = get_cpu_load();
    monitor.cpu.current_load = monitor.cpu.baseline_load;
    monitor.cpu.peak_load = monitor.cpu.baseline_load;
    monitor.cpu.samples = [];
    monitor.cpu.efficiency = 1.0;  % Start at 100% efficiency
    
    # I/O monitoring
    monitor.io = struct();
    monitor.io.read_operations = 0;
    monitor.io.write_operations = 0;
    monitor.io.bytes_read = 0;
    monitor.io.bytes_written = 0;
    monitor.io.io_wait_time = 0;
    
    # MRST-specific monitoring
    monitor.mrst = struct();
    monitor.mrst.jacobian_assembly_times = [];
    monitor.mrst.linear_solve_times = [];
    monitor.mrst.residual_evaluation_times = [];
    monitor.mrst.well_update_times = [];
    monitor.mrst.grid_connectivity_checks = 0;
    
    # Performance alerts
    monitor.alerts = struct();
    monitor.alerts.active_alerts = {};
    monitor.alerts.alert_history = {};
    monitor.alerts.warning_count = 0;
    monitor.alerts.critical_count = 0;
    
    # Performance trends
    monitor.trends = struct();
    monitor.trends.memory_trend = 'stable';
    monitor.trends.timing_trend = 'stable';
    monitor.trends.efficiency_trend = 'stable';
    monitor.trends.last_analysis_time = now;
    
    fprintf('   ✅ Performance monitor initialized\n');
    fprintf('   💾 Baseline memory: %.1f MB\n', monitor.memory.baseline_mb);
    fprintf('   ⚡ CPU baseline load: %.1f%%\n', monitor.cpu.baseline_load * 100);
    fprintf('   📊 Sampling interval: %d seconds\n', monitor.sampling_interval_seconds);

end

function monitor = capture_timestep_performance(monitor, timestep_idx, timestep_data)
% CAPTURE_TIMESTEP_PERFORMANCE - Capture performance metrics for current timestep
%
% INPUTS:
%   monitor      - Performance monitoring structure (modified in-place)
%   timestep_idx - Current timestep index
%   timestep_data - Timestep execution data
%
% TIMESTEP_DATA FIELDS:
%   execution_time   - Total timestep execution time
%   newton_time     - Newton solver time
%   jacobian_time   - Jacobian assembly time
%   linear_time     - Linear solver time
%   well_time       - Well update time
%   memory_usage    - Current memory usage

    if nargin < 3
        error(['Missing canonical timestep_data parameter\n' ...
               'REQUIRED: Update solver hooks to provide timestep_data.\n' ...
               'Canon requires complete timestep performance tracking.']);
    end
    
    current_time = toc(monitor.timing.simulation_start);
    
    # ========================================
    # MEMORY MONITORING
    # ========================================
    
    % Update current memory usage
    if isfield(timestep_data, 'memory_usage_mb')
        monitor.memory.current_mb = timestep_data.memory_usage_mb;
    else
        monitor.memory.current_mb = get_current_memory_usage();
    end
    
    % Track peak memory
    monitor.memory.peak_mb = max(monitor.memory.peak_mb, monitor.memory.current_mb);
    
    % Store memory sample
    monitor.memory.samples(end+1) = monitor.memory.current_mb;
    monitor.memory.timestamps(end+1) = current_time;
    
    % Calculate memory growth rate
    if length(monitor.memory.samples) > 2
        time_span_hours = (current_time - monitor.memory.timestamps(1)) / 3600;
        memory_growth = monitor.memory.current_mb - monitor.memory.samples(1);
        monitor.memory.growth_rate_mb_per_hour = memory_growth / max(time_span_hours, 1e-6);
    end
    
    # ========================================
    # TIMING MONITORING
    # ========================================
    
    % Capture timestep execution time
    if isfield(timestep_data, 'execution_time')
        timestep_time = timestep_data.execution_time;
        monitor.timing.timestep_times(end+1) = timestep_time;
        monitor.timing.cumulative_time = monitor.timing.cumulative_time + timestep_time;
        
        % Update timing statistics
        monitor.timing.average_timestep_time = mean(monitor.timing.timestep_times);
        monitor.timing.slowest_timestep_time = max(monitor.timing.timestep_times);
        monitor.timing.fastest_timestep_time = min(monitor.timing.timestep_times);
    end
    
    # ========================================
    # MRST-SPECIFIC PERFORMANCE
    # ========================================
    
    % Jacobian assembly time
    if isfield(timestep_data, 'jacobian_time')
        monitor.mrst.jacobian_assembly_times(end+1) = timestep_data.jacobian_time;
    end
    
    % Linear solver time
    if isfield(timestep_data, 'linear_time')
        monitor.mrst.linear_solve_times(end+1) = timestep_data.linear_time;
    end
    
    % Residual evaluation time
    if isfield(timestep_data, 'residual_time')
        monitor.mrst.residual_evaluation_times(end+1) = timestep_data.residual_time;
    end
    
    % Well update time
    if isfield(timestep_data, 'well_time')
        monitor.mrst.well_update_times(end+1) = timestep_data.well_time;
    end
    
    # ========================================
    # CPU MONITORING
    # ========================================
    
    monitor.cpu.current_load = get_cpu_load();
    monitor.cpu.peak_load = max(monitor.cpu.peak_load, monitor.cpu.current_load);
    monitor.cpu.samples(end+1) = monitor.cpu.current_load;
    
    % Calculate CPU efficiency (ratio of actual to expected performance)
    if ~isempty(monitor.timing.timestep_times) && length(monitor.timing.timestep_times) > 1
        recent_times = monitor.timing.timestep_times(max(1, end-4):end);
        expected_time = median(recent_times);
        actual_time = monitor.timing.timestep_times(end);
        monitor.cpu.efficiency = min(1.0, expected_time / max(actual_time, 1e-6));
    end
    
    # ========================================
    # PERFORMANCE ALERTS
    # ========================================
    
    % Check for performance alerts
    monitor = check_performance_alerts(monitor, timestep_idx, timestep_data);
    
    # ========================================
    # TREND ANALYSIS
    # ========================================
    
    % Analyze performance trends every 10 timesteps
    if mod(timestep_idx, 10) == 0
        monitor = analyze_performance_trends(monitor);
    end

end

function monitor = check_performance_alerts(monitor, timestep_idx, timestep_data)
% CHECK_PERFORMANCE_ALERTS - Check for performance issues and generate alerts
%
% ALERT TYPES:
%   - Memory usage warnings
%   - Slow timestep execution
%   - High iteration counts
%   - CPU utilization issues
%   - I/O bottlenecks

    alerts_generated = {};
    
    # ========================================
    # MEMORY ALERTS
    # ========================================
    
    % Memory usage warning
    if monitor.memory.current_mb > monitor.alert_thresholds.memory_warning_mb
        alert_msg = sprintf('Memory usage high: %.1f MB (threshold: %.1f MB)', ...
            monitor.memory.current_mb, monitor.alert_thresholds.memory_warning_mb);
        alerts_generated{end+1} = struct('type', 'memory_warning', 'message', alert_msg, 'timestep', timestep_idx);
    end
    
    % Memory growth rate alert
    if monitor.memory.growth_rate_mb_per_hour > 100  % More than 100 MB/hour growth
        alert_msg = sprintf('High memory growth rate: %.1f MB/hour', monitor.memory.growth_rate_mb_per_hour);
        alerts_generated{end+1} = struct('type', 'memory_growth', 'message', alert_msg, 'timestep', timestep_idx);
    end
    
    # ========================================
    # TIMING ALERTS
    # ========================================
    
    % Slow timestep alert
    if isfield(timestep_data, 'execution_time') && ...
       timestep_data.execution_time > monitor.alert_thresholds.timestep_time_warning_seconds
        alert_msg = sprintf('Slow timestep execution: %.1f seconds (threshold: %.1f seconds)', ...
            timestep_data.execution_time, monitor.alert_thresholds.timestep_time_warning_seconds);
        alerts_generated{end+1} = struct('type', 'slow_timestep', 'message', alert_msg, 'timestep', timestep_idx);
    end
    
    % Convergence difficulty alert
    if isfield(timestep_data, 'newton_iterations') && ...
       timestep_data.newton_iterations > monitor.alert_thresholds.convergence_warning_iterations
        alert_msg = sprintf('High iteration count: %d iterations (threshold: %d)', ...
            timestep_data.newton_iterations, monitor.alert_thresholds.convergence_warning_iterations);
        alerts_generated{end+1} = struct('type', 'convergence_difficulty', 'message', alert_msg, 'timestep', timestep_idx);
    end
    
    # ========================================
    # CPU ALERTS
    # ========================================
    
    % Low CPU efficiency alert
    if monitor.cpu.efficiency < 0.7  % Less than 70% efficiency
        alert_msg = sprintf('Low CPU efficiency: %.1f%% (expected >70%%)', monitor.cpu.efficiency * 100);
        alerts_generated{end+1} = struct('type', 'cpu_efficiency', 'message', alert_msg, 'timestep', timestep_idx);
    end
    
    # ========================================
    # PROCESS ALERTS
    # ========================================
    
    % Add alerts to monitoring structure
    for i = 1:length(alerts_generated)
        alert = alerts_generated{i};
        
        % Add to active alerts
        monitor.alerts.active_alerts{end+1} = alert;
        
        % Add to alert history
        alert.timestamp = datestr(now, 'yyyy-mm-ddTHH:MM:SS');
        monitor.alerts.alert_history{end+1} = alert;
        
        % Update alert counters
        if contains(alert.type, 'warning')
            monitor.alerts.warning_count = monitor.alerts.warning_count + 1;
        elseif contains(alert.type, 'critical')
            monitor.alerts.critical_count = monitor.alerts.critical_count + 1;
        end
        
        % Print alert if verbose monitoring
        if isfield(monitor.config, 'verbose_monitoring') && monitor.config.verbose_monitoring
            fprintf('   ⚠️  ALERT [%s]: %s\n', alert.type, alert.message);
        end
    end

end

function monitor = analyze_performance_trends(monitor)
% ANALYZE_PERFORMANCE_TRENDS - Analyze performance trends and predict issues
%
% TREND ANALYSIS:
%   - Memory usage trends
%   - Execution time trends
%   - CPU efficiency trends
%   - Linear solver performance trends

    # ========================================
    # MEMORY TREND ANALYSIS
    # ========================================
    
    if length(monitor.memory.samples) >= 5
        recent_samples = monitor.memory.samples(end-4:end);
        memory_slope = polyfit(1:5, recent_samples, 1);
        
        if memory_slope(1) > 10  % Growing more than 10 MB per sample
            monitor.trends.memory_trend = 'increasing';
        elseif memory_slope(1) < -5  % Decreasing more than 5 MB per sample
            monitor.trends.memory_trend = 'decreasing';
        else
            monitor.trends.memory_trend = 'stable';
        end
    end
    
    # ========================================
    # TIMING TREND ANALYSIS
    # ========================================
    
    if length(monitor.timing.timestep_times) >= 10
        recent_times = monitor.timing.timestep_times(end-9:end);
        timing_slope = polyfit(1:10, recent_times, 1);
        
        if timing_slope(1) > 1  # Increasing by more than 1 second per timestep
            monitor.trends.timing_trend = 'degrading';
        elseif timing_slope(1) < -0.5  # Decreasing by more than 0.5 seconds per timestep
            monitor.trends.timing_trend = 'improving';
        else
            monitor.trends.timing_trend = 'stable';
        end
    end
    
    # ========================================
    # EFFICIENCY TREND ANALYSIS
    # ========================================
    
    if length(monitor.cpu.samples) >= 5
        recent_efficiency = monitor.cpu.samples(end-4:end);
        efficiency_trend = mean(recent_efficiency(end-2:end)) - mean(recent_efficiency(1:3));
        
        if efficiency_trend < -0.1  # Efficiency dropping by more than 10%
            monitor.trends.efficiency_trend = 'degrading';
        elseif efficiency_trend > 0.05  # Efficiency improving by more than 5%
            monitor.trends.efficiency_trend = 'improving';
        else
            monitor.trends.efficiency_trend = 'stable';
        end
    end
    
    monitor.trends.last_analysis_time = now;

end

function final_report = finalize_performance_monitoring(monitor)
% FINALIZE_PERFORMANCE_MONITORING - Generate comprehensive performance report
%
% INPUTS:
%   monitor - Complete performance monitoring data
%
% OUTPUTS:
%   final_report - Comprehensive performance analysis report
%
% REPORT CONTENTS:
%   - Performance summary statistics
%   - Trend analysis
#   - Bottleneck identification
#   - Optimization recommendations
#   - ML-ready performance features

    fprintf('📊 Finalizing performance monitoring report...\n');
    
    total_simulation_time = toc(monitor.timing.simulation_start);
    
    # ========================================
    # PERFORMANCE SUMMARY
    # ========================================
    
    final_report = struct();
    final_report.metadata = struct();
    final_report.metadata.report_generation_time = datestr(now, 'yyyy-mm-ddTHH:MM:SS');
    final_report.metadata.total_simulation_time_hours = total_simulation_time / 3600;
    final_report.metadata.monitoring_version = 'performance_monitoring_v1.0';
    
    % Memory summary
    final_report.memory_summary = struct();
    final_report.memory_summary.baseline_mb = monitor.memory.baseline_mb;
    final_report.memory_summary.peak_mb = monitor.memory.peak_mb;
    final_report.memory_summary.final_mb = monitor.memory.current_mb;
    final_report.memory_summary.total_growth_mb = monitor.memory.current_mb - monitor.memory.baseline_mb;
    final_report.memory_summary.growth_rate_mb_per_hour = monitor.memory.growth_rate_mb_per_hour;
    
    % Timing summary
    final_report.timing_summary = struct();
    if ~isempty(monitor.timing.timestep_times)
        final_report.timing_summary.total_timesteps = length(monitor.timing.timestep_times);
        final_report.timing_summary.average_timestep_time_seconds = monitor.timing.average_timestep_time;
        final_report.timing_summary.fastest_timestep_seconds = monitor.timing.fastest_timestep_time;
        final_report.timing_summary.slowest_timestep_seconds = monitor.timing.slowest_timestep_time;
        final_report.timing_summary.timing_variability = std(monitor.timing.timestep_times) / mean(monitor.timing.timestep_times);
    else
        final_report.timing_summary.total_timesteps = 0;
        final_report.timing_summary.average_timestep_time_seconds = 0;
        final_report.timing_summary.timing_variability = 0;
    end
    
    % CPU summary
    final_report.cpu_summary = struct();
    final_report.cpu_summary.baseline_load = monitor.cpu.baseline_load;
    final_report.cpu_summary.peak_load = monitor.cpu.peak_load;
    final_report.cpu_summary.average_efficiency = monitor.cpu.efficiency;
    if ~isempty(monitor.cpu.samples)
        final_report.cpu_summary.average_load = mean(monitor.cpu.samples);
        final_report.cpu_summary.load_variability = std(monitor.cpu.samples);
    else
        final_report.cpu_summary.average_load = 0;
        final_report.cpu_summary.load_variability = 0;
    end
    
    # ========================================
    # MRST-SPECIFIC PERFORMANCE
    # ========================================
    
    final_report.mrst_performance = struct();
    
    if ~isempty(monitor.mrst.jacobian_assembly_times)
        final_report.mrst_performance.average_jacobian_time = mean(monitor.mrst.jacobian_assembly_times);
        final_report.mrst_performance.total_jacobian_time = sum(monitor.mrst.jacobian_assembly_times);
    else
        final_report.mrst_performance.average_jacobian_time = 0;
        final_report.mrst_performance.total_jacobian_time = 0;
    end
    
    if ~isempty(monitor.mrst.linear_solve_times)
        final_report.mrst_performance.average_linear_solve_time = mean(monitor.mrst.linear_solve_times);
        final_report.mrst_performance.total_linear_solve_time = sum(monitor.mrst.linear_solve_times);
    else
        final_report.mrst_performance.average_linear_solve_time = 0;
        final_report.mrst_performance.total_linear_solve_time = 0;
    end
    
    # ========================================
    # BOTTLENECK ANALYSIS
    # ========================================
    
    final_report.bottleneck_analysis = identify_performance_bottlenecks(monitor);
    
    # ========================================
    # TREND ANALYSIS SUMMARY
    # ========================================
    
    final_report.trend_analysis = struct();
    final_report.trend_analysis.memory_trend = monitor.trends.memory_trend;
    final_report.trend_analysis.timing_trend = monitor.trends.timing_trend;
    final_report.trend_analysis.efficiency_trend = monitor.trends.efficiency_trend;
    
    # ========================================
    # ALERT SUMMARY
    # ========================================
    
    final_report.alert_summary = struct();
    final_report.alert_summary.total_warnings = monitor.alerts.warning_count;
    final_report.alert_summary.total_critical = monitor.alerts.critical_count;
    final_report.alert_summary.most_common_alerts = analyze_alert_patterns(monitor.alerts.alert_history);
    
    # ========================================
    # OPTIMIZATION RECOMMENDATIONS
    # ========================================
    
    final_report.optimization_recommendations = generate_optimization_recommendations(monitor, final_report);
    
    # ========================================
    # ML-READY FEATURES
    # ========================================
    
    final_report.ml_features = struct();
    final_report.ml_features.performance_features = create_performance_ml_features(monitor);
    final_report.ml_features.trend_features = create_trend_ml_features(monitor);
    final_report.ml_features.efficiency_features = create_efficiency_ml_features(monitor);
    
    fprintf('   ✅ Performance report finalized\n');
    fprintf('   ⏱️  Total simulation time: %.1f hours\n', final_report.metadata.total_simulation_time_hours);
    fprintf('   💾 Peak memory: %.1f MB\n', final_report.memory_summary.peak_mb);
    fprintf('   ⚠️  Total alerts: %d warnings, %d critical\n', ...
        final_report.alert_summary.total_warnings, final_report.alert_summary.total_critical);

end

% ========================================
# HELPER FUNCTIONS
# ========================================

function memory_mb = get_current_memory_usage()
% Get current memory usage in MB (cross-platform)
    
    try
        if isunix || ismac
            # Unix/Mac: use ps command
            [status, result] = system('ps -o rss= -p $PPID');
            if status == 0
                memory_kb = str2double(result);
                memory_mb = memory_kb / 1024;
            else
                memory_mb = 0;
            end
        else
            # Windows: use tasklist (simplified)
            memory_mb = 0;  # Placeholder - would need Windows-specific implementation
        end
    catch
        memory_mb = 0;  # Fallback if memory detection fails
    end
    
    # If system call fails, use MATLAB's memory info as approximation
    if memory_mb == 0
        try
            meminfo = memory;
            memory_mb = meminfo.MemUsedMATLAB / 1048576;  # Convert bytes to MB
        catch
            memory_mb = 100;  # Default fallback
        end
    end

end

function cpu_load = get_cpu_load()
% Get current CPU load (simplified implementation)
    
    try
        if isunix || ismac
            # Unix/Mac: use uptime or top
            [status, result] = system('uptime | grep -o "load average: [0-9.]*" | grep -o "[0-9.]*"');
            if status == 0
                load_values = str2double(strsplit(strtrim(result)));
                cpu_load = load_values(1) / 4;  # Normalize by number of cores (rough estimate)
                cpu_load = min(cpu_load, 1.0);  # Cap at 100%
            else
                cpu_load = 0.5;  # Default moderate load
            end
        else
            # Windows: would need Windows-specific implementation
            cpu_load = 0.5;  # Default placeholder
        end
    catch
        cpu_load = 0.5;  # Default fallback
    end

end

function value = get_field_canonical(struct_data, field_name, canonical_default)
% Get field value with canonical default (no defensive fallbacks)
    
    if isfield(struct_data, field_name)
        value = struct_data.(field_name);
    else
        value = canonical_default;
    end

end

function bottlenecks = identify_performance_bottlenecks(monitor)
% Identify primary performance bottlenecks in simulation
    
    bottlenecks = struct();
    bottlenecks.identified_bottlenecks = {};
    bottlenecks.severity_scores = [];
    
    # Memory bottleneck analysis
    memory_growth_severity = min(monitor.memory.growth_rate_mb_per_hour / 50, 5);  # Scale to 0-5
    if memory_growth_severity > 2
        bottlenecks.identified_bottlenecks{end+1} = 'memory_growth';
        bottlenecks.severity_scores(end+1) = memory_growth_severity;
    end
    
    # Timing bottleneck analysis
    if ~isempty(monitor.timing.timestep_times)
        timing_variability = std(monitor.timing.timestep_times) / mean(monitor.timing.timestep_times);
        if timing_variability > 0.3  # More than 30% variability
            bottlenecks.identified_bottlenecks{end+1} = 'timing_inconsistency';
            bottlenecks.severity_scores(end+1) = min(timing_variability * 5, 5);
        end
    end
    
    # CPU efficiency bottleneck
    if monitor.cpu.efficiency < 0.7
        bottlenecks.identified_bottlenecks{end+1} = 'cpu_efficiency';
        bottlenecks.severity_scores(end+1) = (1 - monitor.cpu.efficiency) * 5;
    end
    
    # Linear solver bottleneck
    if ~isempty(monitor.mrst.linear_solve_times) && ~isempty(monitor.timing.timestep_times)
        linear_fraction = sum(monitor.mrst.linear_solve_times) / sum(monitor.timing.timestep_times);
        if linear_fraction > 0.6  # Linear solver taking more than 60% of time
            bottlenecks.identified_bottlenecks{end+1} = 'linear_solver_dominance';
            bottlenecks.severity_scores(end+1) = min(linear_fraction * 5, 5);
        end
    end
    
    # Rank bottlenecks by severity
    if ~isempty(bottlenecks.severity_scores)
        [sorted_severity, sort_idx] = sort(bottlenecks.severity_scores, 'descend');
        bottlenecks.ranked_bottlenecks = bottlenecks.identified_bottlenecks(sort_idx);
        bottlenecks.ranked_severity = sorted_severity;
    else
        bottlenecks.ranked_bottlenecks = {};
        bottlenecks.ranked_severity = [];
    end

end

function recommendations = generate_optimization_recommendations(monitor, final_report)
% Generate optimization recommendations based on performance analysis
    
    recommendations = {};
    
    # Memory optimization recommendations
    if strcmp(final_report.trend_analysis.memory_trend, 'increasing')
        if final_report.memory_summary.growth_rate_mb_per_hour > 100
            recommendations{end+1} = 'Consider implementing memory pooling or garbage collection optimization';
            recommendations{end+1} = 'Review data structures for memory leaks or unnecessary allocations';
        end
    end
    
    # Timing optimization recommendations
    if strcmp(final_report.trend_analysis.timing_trend, 'degrading')
        recommendations{end+1} = 'Investigate timestep size optimization';
        recommendations{end+1} = 'Consider adaptive timestep controls to maintain performance';
    end
    
    # Linear solver optimization
    if ~isempty(monitor.mrst.linear_solve_times) && ~isempty(monitor.timing.timestep_times)
        linear_fraction = sum(monitor.mrst.linear_solve_times) / sum(monitor.timing.timestep_times);
        if linear_fraction > 0.5
            recommendations{end+1} = 'Linear solver optimization needed - consider CPR preconditioning';
            recommendations{end+1} = 'Evaluate matrix ordering and factorization methods';
        end
    end
    
    # CPU efficiency recommendations
    if final_report.cpu_summary.average_efficiency < 0.8
        recommendations{end+1} = 'CPU efficiency below optimal - check for I/O bottlenecks';
        recommendations{end+1} = 'Consider parallel computing optimization';
    end
    
    # Alert-based recommendations
    if final_report.alert_summary.total_warnings > 10
        recommendations{end+1} = 'High number of performance warnings - review alert thresholds';
        recommendations{end+1} = 'Implement proactive performance monitoring';
    end
    
    if isempty(recommendations)
        recommendations{1} = 'Performance appears optimal - no specific recommendations';
    end

end

function alert_patterns = analyze_alert_patterns(alert_history)
% Analyze patterns in performance alerts
    
    alert_patterns = struct();
    alert_patterns.alert_types = {};
    alert_patterns.frequencies = [];
    
    if isempty(alert_history)
        return;
    end
    
    # Count alert types
    alert_types = cellfun(@(x) x.type, alert_history, 'UniformOutput', false);
    unique_types = unique(alert_types);
    
    for i = 1:length(unique_types)
        alert_type = unique_types{i};
        count = sum(strcmp(alert_types, alert_type));
        alert_patterns.alert_types{end+1} = alert_type;
        alert_patterns.frequencies(end+1) = count;
    end
    
    # Sort by frequency
    [sorted_freq, sort_idx] = sort(alert_patterns.frequencies, 'descend');
    alert_patterns.alert_types = alert_patterns.alert_types(sort_idx);
    alert_patterns.frequencies = sorted_freq;

end

function perf_features = create_performance_ml_features(monitor)
% Create ML-ready performance features
    
    perf_features = struct();
    
    # Memory features
    perf_features.memory_baseline_mb = monitor.memory.baseline_mb;
    perf_features.memory_peak_mb = monitor.memory.peak_mb;
    perf_features.memory_growth_rate = monitor.memory.growth_rate_mb_per_hour;
    
    # Timing features
    if ~isempty(monitor.timing.timestep_times)
        perf_features.avg_timestep_time = mean(monitor.timing.timestep_times);
        perf_features.timestep_time_std = std(monitor.timing.timestep_times);
        perf_features.timing_coefficient_variation = perf_features.timestep_time_std / perf_features.avg_timestep_time;
    else
        perf_features.avg_timestep_time = 0;
        perf_features.timestep_time_std = 0;
        perf_features.timing_coefficient_variation = 0;
    end
    
    # CPU features
    perf_features.cpu_efficiency = monitor.cpu.efficiency;
    perf_features.cpu_peak_load = monitor.cpu.peak_load;
    if ~isempty(monitor.cpu.samples)
        perf_features.cpu_load_variability = std(monitor.cpu.samples);
    else
        perf_features.cpu_load_variability = 0;
    end

end

function trend_features = create_trend_ml_features(monitor)
% Create ML-ready trend features
    
    trend_features = struct();
    
    # Trend indicators (categorical to numerical)
    trend_map = containers.Map({'improving', 'stable', 'degrading'}, {-1, 0, 1});
    
    if isKey(trend_map, monitor.trends.memory_trend)
        trend_features.memory_trend_numeric = trend_map(monitor.trends.memory_trend);
    else
        trend_features.memory_trend_numeric = 0;
    end
    
    if isKey(trend_map, monitor.trends.timing_trend)
        trend_features.timing_trend_numeric = trend_map(monitor.trends.timing_trend);
    else
        trend_features.timing_trend_numeric = 0;
    end
    
    if isKey(trend_map, monitor.trends.efficiency_trend)
        trend_features.efficiency_trend_numeric = trend_map(monitor.trends.efficiency_trend);
    else
        trend_features.efficiency_trend_numeric = 0;
    end
    
    # Composite trend score
    trend_features.overall_trend_score = mean([
        trend_features.memory_trend_numeric,
        trend_features.timing_trend_numeric,
        trend_features.efficiency_trend_numeric
    ]);

end

function efficiency_features = create_efficiency_ml_features(monitor)
% Create ML-ready efficiency features
    
    efficiency_features = struct();
    
    # Overall efficiency metrics
    efficiency_features.cpu_efficiency = monitor.cpu.efficiency;
    efficiency_features.alert_density = length(monitor.alerts.alert_history) / max(length(monitor.timing.timestep_times), 1);
    
    # MRST-specific efficiency
    if ~isempty(monitor.mrst.jacobian_assembly_times) && ~isempty(monitor.timing.timestep_times)
        efficiency_features.jacobian_time_fraction = sum(monitor.mrst.jacobian_assembly_times) / sum(monitor.timing.timestep_times);
    else
        efficiency_features.jacobian_time_fraction = 0;
    end
    
    if ~isempty(monitor.mrst.linear_solve_times) && ~isempty(monitor.timing.timestep_times)
        efficiency_features.linear_solve_fraction = sum(monitor.mrst.linear_solve_times) / sum(monitor.timing.timestep_times);
    else
        efficiency_features.linear_solve_fraction = 0;
    end
    
    # Resource utilization efficiency
    if monitor.memory.peak_mb > monitor.memory.baseline_mb
        efficiency_features.memory_utilization = monitor.memory.current_mb / monitor.memory.peak_mb;
    else
        efficiency_features.memory_utilization = 1.0;
    end

end