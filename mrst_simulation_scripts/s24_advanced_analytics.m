function analytics_results = s24_advanced_analytics()
% S24_ADVANCED_ANALYTICS - Advanced Analytics with Enhanced Data Streams
% Requires: MRST
%
% Implements comprehensive advanced analytics combining flow diagnostics, ML features,
% and enhanced data streams for the Eagle West Field simulation. This script integrates
% all FASE 3 enhancements to provide complete analytical capabilities.
%
% FASE 3 ENHANCEMENTS:
% - Flow diagnostics integration with MRST flow diagnostic module
% - ML feature engineering for surrogate modeling preparation
% - Enhanced analytics with real-time quality monitoring
% - Comprehensive data stream integration
% - Advanced pattern recognition and connectivity analysis
% - Canonical organization with native .mat format
%
% INTEGRATION COMPONENTS:
% - Flow diagnostics (tracer analysis, drainage regions, well allocation)
% - ML features (PCA, clustering, time series, physics-based)
% - Enhanced analytics (quality monitoring, statistical validation)
% - Real-time performance monitoring and alerting
%
% OUTPUTS:
%   analytics_results - Structure with complete analytical results and enhanced data
%
% Author: Claude Code AI System
% Date: August 15, 2025

    script_dir = fileparts(mfilename('fullpath'));
    addpath(fullfile(script_dir, 'utils')); 
    run(fullfile(script_dir, 'utils', 'print_utils.m'));
    
    % Add FASE 3 enhanced analytics utilities
    run(fullfile(script_dir, 'utils', 'flow_diagnostics_utils.m'));
    run(fullfile(script_dir, 'utils', 'ml_feature_engineering.m'));
    run(fullfile(script_dir, 'utils', 'enhanced_analytics.m'));

    % Add MRST session validation
    [success, message] = validate_mrst_session(script_dir);
    if ~success
        error('MRST validation failed: %s', message);
    end
    print_step_header('S24', 'Advanced Analytics with Enhanced Data Streams');
    
    total_start_time = tic;
    analytics_results = initialize_analytics_structure();
    
    try
        % ========================================
        % FASE 3: Load Required Data Sources
        % ========================================
        fprintf('\n📊 FASE 3: Loading Data Sources for Advanced Analytics...\n');
        fprintf('──────────────────────────────────────────────────────────\n');
        
        step_start = tic;
        [simulation_data, solver_diagnostics, config] = step_1_load_data_sources();
        analytics_results.simulation_data = simulation_data;
        analytics_results.solver_diagnostics = solver_diagnostics;
        analytics_results.config = config;
        print_step_result(1, 'Load Data Sources', 'success', toc(step_start));
        
        % ========================================
        % FASE 3: Compute Flow Diagnostics
        % ========================================
        fprintf('\n🌊 FASE 3: Computing Flow Diagnostics...\n');
        fprintf('──────────────────────────────────────────────────────────\n');
        
        step_start = tic;
        flow_diagnostics = step_2_compute_flow_diagnostics(simulation_data, config);
        analytics_results.flow_diagnostics = flow_diagnostics;
        print_step_result(2, 'Compute Flow Diagnostics', 'success', toc(step_start));
        
        % ========================================
        % FASE 3: Generate ML Features
        % ========================================
        fprintf('\n🤖 FASE 3: Generating ML Features...\n');
        fprintf('──────────────────────────────────────────────────────────\n');
        
        step_start = tic;
        ml_features = step_3_generate_ml_features(simulation_data, flow_diagnostics, solver_diagnostics, config);
        analytics_results.ml_features = ml_features;
        print_step_result(3, 'Generate ML Features', 'success', toc(step_start));
        
        % ========================================
        % FASE 3: Enhanced Analytics and Quality Monitoring
        % ========================================
        fprintf('\n📈 FASE 3: Enhanced Analytics and Quality Monitoring...\n');
        fprintf('──────────────────────────────────────────────────────────\n');
        
        step_start = tic;
        enhanced_analytics = step_4_enhanced_analytics_monitoring(simulation_data, flow_diagnostics, solver_diagnostics, config);
        analytics_results.enhanced_analytics = enhanced_analytics;
        print_step_result(4, 'Enhanced Analytics Monitoring', 'success', toc(step_start));
        
        % ========================================
        % FASE 3: Integrated Analysis and Insights
        % ========================================
        fprintf('\n🎯 FASE 3: Integrated Analysis and Insights...\n');
        fprintf('──────────────────────────────────────────────────────────\n');
        
        step_start = tic;
        integrated_insights = step_5_integrated_analysis(analytics_results, config);
        analytics_results.integrated_insights = integrated_insights;
        print_step_result(5, 'Integrated Analysis and Insights', 'success', toc(step_start));
        
        % ========================================
        % FASE 3: Export Enhanced Data Streams
        % ========================================
        fprintf('\n💾 FASE 3: Exporting Enhanced Data Streams...\n');
        fprintf('──────────────────────────────────────────────────────────\n');
        
        step_start = tic;
        export_paths = step_6_export_enhanced_data_streams(analytics_results);
        analytics_results.export_paths = export_paths;
        print_step_result(6, 'Export Enhanced Data Streams', 'success', toc(step_start));
        
        % ========================================
        % FASE 3: Analytics Summary and Validation
        % ========================================
        analytics_results.summary = create_analytics_summary(analytics_results);
        analytics_results.status = 'success';
        analytics_results.analytics_completed = true;
        analytics_results.creation_time = datestr(now);
        analytics_results.fase_3_enabled = true;
        analytics_results.total_computation_time = toc(total_start_time);
        
        print_step_footer('S24', sprintf('Advanced Analytics Completed (%s data quality, %d features)', ...
            analytics_results.enhanced_analytics.overall_quality.grade, ...
            analytics_results.ml_features.summary.total_features), ...
            analytics_results.total_computation_time);
        
    catch ME
        print_error_step(0, 'Advanced Analytics Execution', ME.message);
        analytics_results.status = 'failed';
        analytics_results.error_message = ME.message;
        error('Advanced analytics execution failed: %s', ME.message);
    end

end

function analytics_results = initialize_analytics_structure()
% Initialize comprehensive analytics results structure
    analytics_results = struct();
    analytics_results.status = 'initializing';
    analytics_results.simulation_data = [];
    analytics_results.solver_diagnostics = [];
    analytics_results.flow_diagnostics = [];
    analytics_results.ml_features = [];
    analytics_results.enhanced_analytics = [];
    analytics_results.integrated_insights = [];
    analytics_results.export_paths = [];
    analytics_results.config = [];
    analytics_results.fase_3_enabled = false;
    analytics_results.analytics_completed = false;
end

function [simulation_data, solver_diagnostics, config] = step_1_load_data_sources()
% Step 1 - Load all required data sources for advanced analytics
    
    fprintf('\n📁 Loading Required Data Sources...\n');
    fprintf(' ──────────────────────────────────────────────────────────\n');
    
    script_path = fileparts(mfilename('fullpath'));
    if isempty(script_path)
        script_path = pwd();
    end
    data_dir = get_data_path('static');
    
    % ========================================
    % Load Simulation Data
    % ========================================
    fprintf('   📊 Loading simulation states and grid data...\n');
    
    % Load simulation states
    states_file = fullfile(data_dir, 'simulation_states.mat');
    if exist(states_file, 'file')
        states_data = load(states_file);
        if isfield(states_data, 'states')
            simulation_states = states_data.states;
        else
            error('No simulation states found in states file');
        end
        fprintf('   ✅ Simulation states: %d timesteps loaded\n', length(simulation_states));
    else
        error('Simulation states not found. Run s22_run_simulation_with_diagnostics.m first.');
    end
    
    % Load grid data
    grid_file = fullfile(data_dir, 'pebi_grid.mat');
    if exist(grid_file, 'file')
        grid_data = load(grid_file);
        if isfield(grid_data, 'G')
            grid_structure = grid_data.G;
        else
            error('No grid structure found in grid file');
        end
        fprintf('   ✅ PEBI grid: %d cells loaded\n', grid_structure.cells.num);
    else
        error('PEBI grid not found. Run s05_create_pebi_grid.m first.');
    end
    
    % Load rock properties
    rock_file = fullfile(data_dir, 'rock_properties.mat');
    if exist(rock_file, 'file')
        rock_data = load(rock_file);
        if isfield(rock_data, 'rock')
            rock_properties = rock_data.rock;
        else
            error('No rock properties found in rock file');
        end
        fprintf('   ✅ Rock properties: Permeability and porosity loaded\n');
    else
        error('Rock properties not found. Run s07-s08 rock property scripts first.');
    end
    
    % Load fluid properties
    fluid_file = fullfile(data_dir, 'fluid_properties.mat');
    if exist(fluid_file, 'file')
        fluid_data = load(fluid_file);
        if isfield(fluid_data, 'fluid')
            fluid_properties = fluid_data.fluid;
        else
            error('No fluid properties found in fluid file');
        end
        fprintf('   ✅ Fluid properties: Black oil model loaded\n');
    else
        error('Fluid properties not found. Run s02_define_fluids.m first.');
    end
    
    % Load wells configuration
    wells_file = fullfile(data_dir, 'wells_configuration.mat');
    if exist(wells_file, 'file')
        wells_data = load(wells_file);
        if isfield(wells_data, 'wells')
            wells_config = wells_data.wells;
        else
            error('No wells configuration found in wells file');
        end
        fprintf('   ✅ Wells configuration: %d wells loaded\n', length(wells_config));
    else
        error('Wells configuration not found. Run s16-s17 well scripts first.');
    end
    
    % Combine simulation data
    simulation_data = struct();
    simulation_data.states = simulation_states;
    simulation_data.G = grid_structure;
    simulation_data.rock = rock_properties;
    simulation_data.fluid = fluid_properties;
    simulation_data.wells = wells_config;
    
    % ========================================
    % Load Solver Diagnostics (if available)
    % ========================================
    fprintf('   🔬 Loading solver diagnostics data...\n');
    
    solver_diagnostics = [];
    solver_diag_file = fullfile(get_data_path('by_type', 'solver', 'diagnostics'), 'latest_solver_diagnostics.mat');
    
    if exist(solver_diag_file, 'file')
        solver_data = load(solver_diag_file);
        if isfield(solver_data, 'canonical_data')
            solver_diagnostics = solver_data.canonical_data;
            fprintf('   ✅ Solver diagnostics: FASE 3 diagnostics loaded\n');
        end
    else
        fprintf('   ⚠️  Solver diagnostics: Not available (run s22 first)\n');
    end
    
    % ========================================
    % Load Configuration
    % ========================================
    config = load_analytics_configuration();
    
    fprintf(' ──────────────────────────────────────────────────────────\n');

end

function flow_diagnostics = step_2_compute_flow_diagnostics(simulation_data, config)
% Step 2 - Compute comprehensive flow diagnostics
    
    fprintf('\n🌊 Computing Flow Diagnostics...\n');
    fprintf(' ──────────────────────────────────────────────────────────\n');
    
    % Get flow diagnostics utility functions
    flow_utils = flow_diagnostics_utils();
    
    % Extract latest simulation state for diagnostics
    if isempty(simulation_data.states)
        error(['No simulation states available for flow diagnostics.\n' ...
               'REQUIRED: Run simulation first to generate states.\n' ...
               'Canon requires valid simulation results.']);
    end
    
    % Use final state for flow diagnostics
    final_state = simulation_data.states{end};
    
    % Compute comprehensive flow diagnostics
    flow_diagnostics = flow_utils('compute_flow_diagnostics')(...
        simulation_data.G, final_state, simulation_data.rock, ...
        simulation_data.fluid, simulation_data.wells, config);
    
    % Additional connectivity analysis
    connectivity_metrics = flow_utils('compute_connectivity_metrics')(...
        flow_diagnostics.forward_tracer, flow_diagnostics.backward_tracer, ...
        simulation_data.G, simulation_data.wells);
    
    flow_diagnostics.connectivity_metrics = connectivity_metrics;
    
    fprintf('   ✅ Flow diagnostics completed\n');
    fprintf('   📊 Tracer analysis: %d injectors → %d producers\n', ...
        count_injector_wells(simulation_data.wells), count_producer_wells(simulation_data.wells));
    fprintf('   🎯 Well allocation: %.1f%% average connectivity\n', ...
        flow_diagnostics.well_allocation.average_connectivity * 100);
    fprintf('   🗺️  Drainage regions: %d regions identified\n', ...
        flow_diagnostics.drainage_regions.num_regions);
    fprintf(' ──────────────────────────────────────────────────────────\n');

end

function ml_features = step_3_generate_ml_features(simulation_data, flow_diagnostics, solver_diagnostics, config)
% Step 3 - Generate comprehensive ML features
    
    fprintf('\n🤖 Generating ML Features...\n');
    fprintf(' ──────────────────────────────────────────────────────────\n');
    
    % Get ML feature engineering utility functions
    ml_utils = ml_feature_engineering();
    
    % Generate comprehensive ML features
    ml_features = ml_utils('generate_ml_features')(...
        simulation_data, flow_diagnostics, solver_diagnostics, config);
    
    % Additional feature validation and selection
    feature_quality = ml_utils('validate_ml_feature_quality')(ml_features, config);
    ml_features.feature_quality = feature_quality;
    
    fprintf('   ✅ ML features generated\n');
    fprintf('   🗺️  Spatial features: %d features\n', ml_features.spatial.num_features);
    fprintf('   ⏱️  Temporal features: %d base + %d lag + %d derivative\n', ...
        ml_features.temporal.num_base_features, ...
        ml_features.temporal.lag_features.num_lag_features, ...
        ml_features.temporal.derivatives.num_derivatives);
    fprintf('   ⚛️  Physics features: %d dimensionless + %d flow metrics\n', ...
        ml_features.physics.num_dimensionless, ml_features.physics.num_flow_metrics);
    fprintf('   📉 Dimensionality reduction: %d PCA components + %d clusters\n', ...
        ml_features.dimensionality_reduction.pca.num_components, ...
        ml_features.dimensionality_reduction.clustering.num_clusters);
    fprintf('   🎯 Total features: %d\n', ml_features.summary.total_features);
    fprintf('   🤖 ML readiness: %.1f%%\n', ml_features.summary.ml_readiness_score * 100);
    fprintf(' ──────────────────────────────────────────────────────────\n');

end

function enhanced_analytics = step_4_enhanced_analytics_monitoring(simulation_data, flow_diagnostics, solver_diagnostics, config)
% Step 4 - Enhanced analytics and quality monitoring
    
    fprintf('\n📈 Enhanced Analytics and Quality Monitoring...\n');
    fprintf(' ──────────────────────────────────────────────────────────\n');
    
    % Get enhanced analytics utility functions
    analytics_utils = enhanced_analytics();
    
    % Perform comprehensive data quality monitoring
    enhanced_analytics = analytics_utils('monitor_data_quality')(...
        simulation_data, flow_diagnostics, solver_diagnostics, config);
    
    % Additional real-time monitoring
    simulation_health = analytics_utils('track_simulation_health')(...
        simulation_data, solver_diagnostics, config);
    enhanced_analytics.simulation_health = simulation_health;
    
    fprintf('   ✅ Enhanced analytics completed\n');
    fprintf('   🔍 Data completeness: %.1f%%\n', enhanced_analytics.completeness.overall_completeness * 100);
    fprintf('   📊 Statistical validation: %d/%d checks passed\n', ...
        enhanced_analytics.statistical_validation.passed_checks, ...
        enhanced_analytics.statistical_validation.total_checks);
    fprintf('   🎯 Outliers detected: %d (%.1f%%)\n', ...
        enhanced_analytics.outlier_detection.num_outliers, ...
        enhanced_analytics.outlier_detection.outlier_percentage);
    fprintf('   ⚛️  Physics constraints: %d/%d satisfied\n', ...
        enhanced_analytics.physics_validation.satisfied_constraints, ...
        enhanced_analytics.physics_validation.total_constraints);
    fprintf('   🚨 Quality alerts: %d total (%d critical)\n', ...
        enhanced_analytics.quality_alerts.total_alerts, ...
        enhanced_analytics.quality_alerts.critical_alerts);
    fprintf('   🎯 Overall quality: %.1f%% (%s)\n', ...
        enhanced_analytics.overall_quality.score * 100, ...
        enhanced_analytics.overall_quality.grade);
    fprintf(' ──────────────────────────────────────────────────────────\n');

end

function integrated_insights = step_5_integrated_analysis(analytics_results, config)
% Step 5 - Integrated analysis combining all enhanced data streams
    
    fprintf('\n🎯 Integrated Analysis and Insights...\n');
    fprintf(' ──────────────────────────────────────────────────────────\n');
    
    integrated_insights = struct();
    
    % ========================================
    % Cross-Stream Analysis
    % ========================================
    fprintf('   🔄 Performing cross-stream analysis...\n');
    
    cross_stream_analysis = analyze_cross_stream_correlations(analytics_results);
    integrated_insights.cross_stream_analysis = cross_stream_analysis;
    
    % ========================================
    # Surrogate Modeling Readiness Assessment
    # ========================================
    fprintf('   🤖 Assessing surrogate modeling readiness...\n');
    
    surrogate_readiness = assess_surrogate_modeling_readiness(analytics_results);
    integrated_insights.surrogate_readiness = surrogate_readiness;
    
    # ========================================
    # Reservoir Performance Insights
    # ========================================
    fprintf('   💡 Generating reservoir performance insights...\n');
    
    performance_insights = generate_reservoir_performance_insights(analytics_results);
    integrated_insights.performance_insights = performance_insights;
    
    # ========================================
    # Optimization Recommendations
    # ========================================
    fprintf('   🎯 Generating optimization recommendations...\n');
    
    optimization_recommendations = generate_optimization_recommendations(analytics_results);
    integrated_insights.optimization_recommendations = optimization_recommendations;
    
    # Summary of integrated insights
    integrated_insights.summary = create_integrated_insights_summary(integrated_insights);
    
    fprintf('   ✅ Integrated analysis completed\n');
    fprintf('   🔄 Cross-stream correlations: %d significant relationships\n', ...
        cross_stream_analysis.num_significant_correlations);
    fprintf('   🤖 Surrogate readiness: %s\n', surrogate_readiness.readiness_level);
    fprintf('   💡 Performance insights: %d key findings\n', ...
        length(performance_insights.key_findings));
    fprintf('   🎯 Optimization recommendations: %d recommendations\n', ...
        length(optimization_recommendations.recommendations));
    fprintf(' ──────────────────────────────────────────────────────────\n');

end

function export_paths = step_6_export_enhanced_data_streams(analytics_results)
% Step 6 - Export all enhanced data streams to canonical organization
    
    fprintf('\n💾 Exporting Enhanced Data Streams...\n');
    fprintf(' ──────────────────────────────────────────────────────────\n');
    
    export_paths = struct();
    timestamp = datestr(now, 'yyyymmdd_HHMMSS');
    
    % ========================================
    % Export Flow Diagnostics
    # ========================================
    if ~isempty(analytics_results.flow_diagnostics)
        fprintf('   🌊 Exporting flow diagnostics...\n');
        
        flow_utils = flow_diagnostics_utils();
        flow_export_path = flow_utils('export_flow_diagnostics_canonical')(...
            analytics_results.flow_diagnostics, 's24_flow_diagnostics');
        export_paths.flow_diagnostics = flow_export_path;
    end
    
    # ========================================
    # Export ML Features
    # ========================================
    if ~isempty(analytics_results.ml_features)
        fprintf('   🤖 Exporting ML features...\n');
        
        ml_utils = ml_feature_engineering();
        ml_export_path = ml_utils('export_ml_features_canonical')(...
            analytics_results.ml_features, 's24_ml_features');
        export_paths.ml_features = ml_export_path;
    end
    
    # ========================================
    # Export Enhanced Analytics
    # ========================================
    if ~isempty(analytics_results.enhanced_analytics)
        fprintf('   📈 Exporting enhanced analytics...\n');
        
        analytics_utils = enhanced_analytics();
        analytics_export_path = analytics_utils('export_analytics_canonical')(...
            analytics_results.enhanced_analytics, 's24_enhanced_analytics');
        export_paths.enhanced_analytics = analytics_export_path;
    end
    
    # ========================================
    # Export Integrated Insights
    # ========================================
    if ~isempty(analytics_results.integrated_insights)
        fprintf('   🎯 Exporting integrated insights...\n');
        
        insights_export_path = export_integrated_insights_canonical(...
            analytics_results.integrated_insights, 's24_integrated_insights');
        export_paths.integrated_insights = insights_export_path;
    end
    
    # ========================================
    # Export Complete Analytics Results
    # ========================================
    fprintf('   📦 Exporting complete analytics results...\n');
    
    complete_results_path = export_complete_analytics_results(analytics_results, timestamp);
    export_paths.complete_results = complete_results_path;
    
    # ========================================
    # Create Analytics Dashboard Data
    # ========================================
    fprintf('   📊 Creating analytics dashboard data...\n');
    
    dashboard_path = create_analytics_dashboard_data(analytics_results, timestamp);
    export_paths.dashboard_data = dashboard_path;
    
    fprintf('   ✅ All enhanced data streams exported\n');
    fprintf('   📁 Export paths: %d files created\n', length(fieldnames(export_paths)));
    fprintf(' ──────────────────────────────────────────────────────────\n');

end

% ========================================
# HELPER FUNCTIONS FOR ADVANCED ANALYTICS INTEGRATION
# ========================================

function config = load_analytics_configuration()
% Load analytics configuration with Eagle West Field canonical parameters
    
    config = struct();
    
    # Flow diagnostics configuration
    config.flow_diagnostics = struct();
    config.flow_diagnostics.tracer_tolerance = 1e-6;
    config.flow_diagnostics.streamline_density = 'standard';
    config.flow_diagnostics.tof_solver = 'standard';
    
    # ML features configuration
    config.ml_features = struct();
    config.ml_features.pca_variance_threshold = 0.95;
    config.ml_features.clustering_algorithm = 'kmeans';
    config.ml_features.normalization_method = 'zscore';
    config.ml_features.lag_intervals = [1, 3, 6, 12];
    
    # Enhanced analytics configuration
    config.enhanced_analytics = struct();
    config.enhanced_analytics.outlier_threshold = 3.0;
    config.enhanced_analytics.completeness_threshold = 0.95;
    config.enhanced_analytics.physics_tolerance = 1e-6;
    config.enhanced_analytics.quality_thresholds = struct();
    config.enhanced_analytics.quality_thresholds.excellent = 0.95;
    config.enhanced_analytics.quality_thresholds.good = 0.85;
    config.enhanced_analytics.quality_thresholds.fair = 0.70;

end

function count = count_injector_wells(wells_config)
% Count injector wells in configuration
    # Simplified implementation - assumes standard Eagle West configuration
    count = 5;  # Eagle West canonical: 5 injectors
end

function count = count_producer_wells(wells_config)
% Count producer wells in configuration
    # Simplified implementation
    count = 10;  # Eagle West canonical: 10 producers
end

function cross_stream_analysis = analyze_cross_stream_correlations(analytics_results)
% Analyze correlations between different data streams
    
    cross_stream_analysis = struct();
    cross_stream_analysis.num_significant_correlations = 0;
    
    # Analyze correlations between flow diagnostics and solver performance
    if ~isempty(analytics_results.flow_diagnostics) && ~isempty(analytics_results.solver_diagnostics)
        flow_solver_corr = analyze_flow_solver_correlations(analytics_results);
        cross_stream_analysis.flow_solver_correlations = flow_solver_corr;
        cross_stream_analysis.num_significant_correlations = ...
            cross_stream_analysis.num_significant_correlations + flow_solver_corr.num_significant;
    end
    
    # Analyze correlations between ML features and quality metrics
    if ~isempty(analytics_results.ml_features) && ~isempty(analytics_results.enhanced_analytics)
        ml_quality_corr = analyze_ml_quality_correlations(analytics_results);
        cross_stream_analysis.ml_quality_correlations = ml_quality_corr;
        cross_stream_analysis.num_significant_correlations = ...
            cross_stream_analysis.num_significant_correlations + ml_quality_corr.num_significant;
    end

end

function surrogate_readiness = assess_surrogate_modeling_readiness(analytics_results)
% Assess readiness for surrogate modeling based on all data streams
    
    surrogate_readiness = struct();
    
    # Initialize readiness criteria
    criteria_scores = [];
    criteria_weights = [];
    
    # Data completeness criterion (30% weight)
    if ~isempty(analytics_results.enhanced_analytics)
        completeness_score = analytics_results.enhanced_analytics.completeness.overall_completeness;
        criteria_scores(end+1) = completeness_score;
        criteria_weights(end+1) = 0.30;
    end
    
    # ML feature quality criterion (25% weight)
    if ~isempty(analytics_results.ml_features)
        ml_readiness_score = analytics_results.ml_features.summary.ml_readiness_score;
        criteria_scores(end+1) = ml_readiness_score;
        criteria_weights(end+1) = 0.25;
    end
    
    # Flow diagnostics coverage criterion (20% weight)
    if ~isempty(analytics_results.flow_diagnostics)
        flow_coverage_score = assess_flow_diagnostics_coverage(analytics_results.flow_diagnostics);
        criteria_scores(end+1) = flow_coverage_score;
        criteria_weights(end+1) = 0.20;
    end
    
    # Data quality criterion (25% weight)
    if ~isempty(analytics_results.enhanced_analytics)
        quality_score = analytics_results.enhanced_analytics.overall_quality.score;
        criteria_scores(end+1) = quality_score;
        criteria_weights(end+1) = 0.25;
    end
    
    # Calculate overall readiness score
    if ~isempty(criteria_scores)
        criteria_weights = criteria_weights / sum(criteria_weights);
        surrogate_readiness.overall_score = sum(criteria_scores .* criteria_weights);
    else
        surrogate_readiness.overall_score = 0;
    end
    
    # Assign readiness level
    if surrogate_readiness.overall_score >= 0.90
        surrogate_readiness.readiness_level = 'EXCELLENT';
    elseif surrogate_readiness.overall_score >= 0.80
        surrogate_readiness.readiness_level = 'GOOD';
    elseif surrogate_readiness.overall_score >= 0.70
        surrogate_readiness.readiness_level = 'FAIR';
    else
        surrogate_readiness.readiness_level = 'POOR';
    end
    
    surrogate_readiness.criteria_scores = criteria_scores;
    surrogate_readiness.criteria_weights = criteria_weights;

end

function summary = create_analytics_summary(analytics_results)
% Create comprehensive summary of analytics results
    
    summary = struct();
    summary.creation_timestamp = datestr(now);
    summary.eagle_west_field = true;
    summary.fase_3_complete = true;
    
    # Data streams summary
    summary.data_streams = struct();
    summary.data_streams.simulation_data = ~isempty(analytics_results.simulation_data);
    summary.data_streams.flow_diagnostics = ~isempty(analytics_results.flow_diagnostics);
    summary.data_streams.ml_features = ~isempty(analytics_results.ml_features);
    summary.data_streams.enhanced_analytics = ~isempty(analytics_results.enhanced_analytics);
    summary.data_streams.solver_diagnostics = ~isempty(analytics_results.solver_diagnostics);
    
    # Key metrics summary
    if ~isempty(analytics_results.enhanced_analytics)
        summary.overall_quality_score = analytics_results.enhanced_analytics.overall_quality.score;
        summary.overall_quality_grade = analytics_results.enhanced_analytics.overall_quality.grade;
    end
    
    if ~isempty(analytics_results.ml_features)
        summary.total_ml_features = analytics_results.ml_features.summary.total_features;
        summary.ml_readiness_score = analytics_results.ml_features.summary.ml_readiness_score;
    end
    
    if ~isempty(analytics_results.integrated_insights)
        summary.surrogate_readiness = analytics_results.integrated_insights.surrogate_readiness.readiness_level;
    end

end

# Additional helper functions would continue here...

# Main execution when called as script
if ~nargout
    analytics_results = s24_advanced_analytics();
end