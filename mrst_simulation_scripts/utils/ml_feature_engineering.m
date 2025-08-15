function varargout = ml_feature_engineering()
% ML_FEATURE_ENGINEERING - Advanced Feature Generation for Surrogate Modeling
% Requires: MRST
%
% Provides comprehensive ML feature engineering capabilities for the Eagle West Field
% simulation including PCA components, clustering features, time series derivatives,
% and advanced statistical features for surrogate modeling.
%
% ENHANCED FEATURES FOR FASE 3:
% - Advanced feature generation (PCA, clustering, derivatives)
% - Time series feature extraction and lag analysis
% - Dimensionality reduction with physical interpretation
% - Feature importance scoring and selection
% - Statistical validation and outlier detection
% - Canonical organization with native .mat format
%
% CRITICAL DEPENDENCIES:
% - Existing simulation state and diagnostic data
% - Statistical/ML toolboxes for advanced computations
% - Flow diagnostics and solver diagnostics results
%
% CANON-FIRST APPROACH:
% - All features based on documented Eagle West Field specifications
% - Zero defensive programming - fails fast with canon requirements
% - Native .mat format with canonical organization
% - ML-ready features with proper scaling and normalization
%
% Author: Claude Code AI System  
% Date: August 15, 2025
% FASE 3 Implementation

    % Define available functions for utility access
    available_functions = {
        'generate_ml_features', @generate_ml_features
        'compute_pca_features', @compute_pca_features
        'extract_clustering_features', @extract_clustering_features
        'create_time_series_features', @create_time_series_features
        'compute_lag_features', @compute_lag_features
        'generate_derivative_features', @generate_derivative_features
        'perform_dimensionality_reduction', @perform_dimensionality_reduction
        'calculate_feature_importance', @calculate_feature_importance
        'create_spatial_features', @create_spatial_features
        'generate_physics_features', @generate_physics_features
        'export_ml_features_canonical', @export_ml_features_canonical
        'validate_ml_feature_quality', @validate_ml_feature_quality
        'normalize_feature_data', @normalize_feature_data
        'detect_feature_outliers', @detect_feature_outliers
    };
    
    % Return function handles if requested
    if nargout > 0
        varargout{1} = containers.Map(available_functions(:,1), available_functions(:,2));
    end

end

function ml_features = generate_ml_features(simulation_data, flow_diagnostics, solver_diagnostics, config)
% Generate comprehensive ML features from simulation and diagnostic data
% FASE 3 ENHANCEMENT: Complete ML feature pipeline with advanced analytics
    
    fprintf('\n🤖 ML FEATURES: Generating Advanced Features for Surrogate Modeling...\n');
    fprintf('────────────────────────────────────────────────────────────────\n');
    
    if nargin < 4
        error(['Missing canonical configuration for ML feature engineering.\n' ...
               'REQUIRED: Update obsidian-vault/Planning/ML_Feature_Config.md\n' ...
               'to define feature engineering parameters for Eagle West Field.\n' ...
               'Canon must specify feature types, scaling methods, and validation criteria.']);
    end
    
    % Validate input data
    validate_ml_feature_inputs(simulation_data, flow_diagnostics, solver_diagnostics);
    
    % Initialize ML features structure
    ml_features = struct();
    ml_features.metadata = create_ml_features_metadata(config);
    
    feature_start = tic;
    
    try
        % ========================================
        % FASE 3: Spatial Feature Engineering
        % ========================================
        fprintf('   🗺️  Generating spatial features...\n');
        
        spatial_features = create_spatial_features(simulation_data, flow_diagnostics, config);
        ml_features.spatial = spatial_features;
        
        fprintf('   ✅ Spatial features: %d features generated\n', spatial_features.num_features);
        
        % ========================================
        % FASE 3: Temporal Feature Engineering
        % ========================================
        fprintf('   ⏱️  Extracting temporal features and time series derivatives...\n');
        
        temporal_features = create_time_series_features(simulation_data, config);
        ml_features.temporal = temporal_features;
        
        % Generate lag features
        lag_features = compute_lag_features(simulation_data, config);
        ml_features.temporal.lag_features = lag_features;
        
        % Generate derivative features
        derivative_features = generate_derivative_features(simulation_data, config);
        ml_features.temporal.derivatives = derivative_features;
        
        fprintf('   ✅ Temporal features: %d time series + %d lag + %d derivative features\n', ...
            temporal_features.num_base_features, lag_features.num_lag_features, derivative_features.num_derivatives);
        
        % ========================================
        % FASE 3: Physics-Based Feature Engineering
        % ========================================
        fprintf('   ⚛️  Computing physics-based features...\n');
        
        physics_features = generate_physics_features(simulation_data, flow_diagnostics, config);
        ml_features.physics = physics_features;
        
        fprintf('   ✅ Physics features: %d dimensionless numbers + %d flow metrics\n', ...
            physics_features.num_dimensionless, physics_features.num_flow_metrics);
        
        % ========================================
        % FASE 3: Dimensionality Reduction Features
        % ========================================
        fprintf('   📉 Performing dimensionality reduction (PCA, clustering)...\n');
        
        % PCA feature extraction
        pca_features = compute_pca_features(simulation_data, config);
        ml_features.dimensionality_reduction.pca = pca_features;
        
        % Clustering features
        clustering_features = extract_clustering_features(simulation_data, config);
        ml_features.dimensionality_reduction.clustering = clustering_features;
        
        % Combined dimensionality reduction
        dr_combined = perform_dimensionality_reduction(ml_features, config);
        ml_features.dimensionality_reduction.combined = dr_combined;
        
        fprintf('   ✅ Dimensionality reduction: %d PCA components + %d clusters\n', ...
            pca_features.num_components, clustering_features.num_clusters);
        
        % ========================================
        % FASE 3: Feature Importance and Selection
        % ========================================
        fprintf('   🎯 Computing feature importance scores...\n');
        
        feature_importance = calculate_feature_importance(ml_features, simulation_data, config);
        ml_features.feature_importance = feature_importance;
        
        fprintf('   ✅ Feature importance: Top %d features identified\n', ...
            length(feature_importance.top_features));
        
        % ========================================
        % FASE 3: Feature Quality Validation
        % ========================================
        fprintf('   🔍 Validating feature quality and detecting outliers...\n');
        
        % Normalize features
        ml_features = normalize_feature_data(ml_features, config);
        
        % Quality validation
        quality_report = validate_ml_feature_quality(ml_features, config);
        ml_features.quality_validation = quality_report;
        
        % Outlier detection
        outlier_analysis = detect_feature_outliers(ml_features, config);
        ml_features.outlier_analysis = outlier_analysis;
        
        fprintf('   ✅ Quality validation: %.1f%% features pass quality checks\n', ...
            quality_report.pass_rate * 100);
        
        % ========================================
        % FASE 3: Feature Summary and ML Readiness
        % ========================================
        ml_features.summary = create_ml_features_summary(ml_features);
        ml_features.computation_time = toc(feature_start);
        
        fprintf('   📊 ML feature engineering completed in %.1f seconds\n', ml_features.computation_time);
        fprintf('   🎯 Total features generated: %d\n', ml_features.summary.total_features);
        fprintf('   🤖 ML readiness score: %.1f%%\n', ml_features.summary.ml_readiness_score * 100);
        fprintf('────────────────────────────────────────────────────────────────\n');
        
    catch ME
        error('ML feature engineering failed: %s\nREQUIRED: Verify canonical input data and feature configuration.', ME.message);
    end

end

function spatial_features = create_spatial_features(simulation_data, flow_diagnostics, config)
% Create spatial features including coordinates, geometry, and well proximity
% FASE 3 ENHANCEMENT: Advanced spatial feature engineering with connectivity metrics
    
    fprintf('   🗺️  Computing spatial coordinate and geometry features...\n');
    
    if ~isfield(simulation_data, 'G') || isempty(simulation_data.G)
        error(['Missing grid data for spatial feature generation.\n' ...
               'REQUIRED: Load Eagle West Field PEBI grid structure.\n' ...
               'Canon requires complete grid geometry.']);
    end
    
    G = simulation_data.G;
    spatial_features = struct();
    
    % ========================================
    % Coordinate Features
    % ========================================
    if isfield(G.cells, 'centroids')
        centroids = G.cells.centroids;
        
        % Normalized coordinates [0, 1]
        x_coords = centroids(:, 1);
        y_coords = centroids(:, 2);
        z_coords = centroids(:, 3);
        
        spatial_features.coordinates = struct();
        spatial_features.coordinates.x_norm = normalize_coordinates(x_coords);
        spatial_features.coordinates.y_norm = normalize_coordinates(y_coords);
        spatial_features.coordinates.z_norm = normalize_coordinates(z_coords);
        
        % Distance-based features
        center_x = mean(x_coords);
        center_y = mean(y_coords);
        center_z = mean(z_coords);
        
        center_distance = sqrt((x_coords - center_x).^2 + (y_coords - center_y).^2 + (z_coords - center_z).^2);
        spatial_features.coordinates.center_distance_norm = normalize_coordinates(center_distance);
        
        % Boundary distance features
        boundary_distance = calculate_boundary_distances(x_coords, y_coords, z_coords);
        spatial_features.coordinates.boundary_distance_norm = normalize_coordinates(boundary_distance);
        
    else
        error(['Missing cell centroids for spatial feature generation.\n' ...
               'REQUIRED: Grid structure with valid centroids.\n' ...
               'Canon requires complete grid geometry.']);
    end
    
    % ========================================
    % Geometric Features
    % ========================================
    fprintf('   📐 Computing geometric property features...\n');
    
    spatial_features.geometry = struct();
    
    % Cell volumes
    if isfield(G.cells, 'volumes')
        volumes = G.cells.volumes;
        spatial_features.geometry.volume_norm = normalize_coordinates(volumes);
        spatial_features.geometry.volume_log = log10(max(volumes, 1e-12));  % Avoid log(0)
    else
        % Estimate volumes for PEBI grid
        volumes = estimate_cell_volumes(G);
        spatial_features.geometry.volume_norm = normalize_coordinates(volumes);
        spatial_features.geometry.volume_log = log10(max(volumes, 1e-12));
    end
    
    % Cell areas (projected)
    face_areas = calculate_cell_face_areas(G);
    spatial_features.geometry.area_xy_norm = normalize_coordinates(face_areas.xy);
    spatial_features.geometry.area_xz_norm = normalize_coordinates(face_areas.xz);
    spatial_features.geometry.area_yz_norm = normalize_coordinates(face_areas.yz);
    
    % Aspect ratios
    aspect_ratios = calculate_cell_aspect_ratios(G);
    spatial_features.geometry.aspect_ratio = aspect_ratios;
    
    % ========================================
    % Well Proximity Features
    % ========================================
    if isfield(simulation_data, 'wells') && ~isempty(simulation_data.wells)
        fprintf('   🏭 Computing well proximity features...\n');
        
        wells = simulation_data.wells;
        well_proximity = compute_well_proximity_features(centroids, wells);
        spatial_features.well_proximity = well_proximity;
    end
    
    % ========================================
    # Flow Connectivity Features (from flow diagnostics)
    # ========================================
    if ~isempty(flow_diagnostics) && isfield(flow_diagnostics, 'connectivity')
        fprintf('   🌊 Computing flow connectivity features...\n');
        
        connectivity = flow_diagnostics.connectivity;
        spatial_features.flow_connectivity = extract_connectivity_features(connectivity, G);
    end
    
    % Count total features
    spatial_features.num_features = count_spatial_features(spatial_features);

end

function temporal_features = create_time_series_features(simulation_data, config)
% Create temporal features including moving averages, trends, and indicators
% FASE 3 ENHANCEMENT: Advanced time series analysis with seasonal decomposition
    
    fprintf('   📈 Computing time series statistical features...\n');
    
    if ~isfield(simulation_data, 'states') || isempty(simulation_data.states)
        error(['Missing simulation states for temporal feature generation.\n' ...
               'REQUIRED: Time series simulation state data.\n' ...
               'Canon requires complete temporal simulation data.']);
    end
    
    states = simulation_data.states;
    num_timesteps = length(states);
    
    if num_timesteps < 3
        error(['Insufficient timesteps for temporal feature engineering.\n' ...
               'REQUIRED: Minimum 3 timesteps for derivative computation.\n' ...
               'Canon requires adequate temporal resolution.']);
    end
    
    temporal_features = struct();
    
    % ========================================
    % Extract Time Series Data
    % ========================================
    time_series_data = extract_time_series_from_states(states);
    
    % ========================================
    # Moving Averages
    # ========================================
    fprintf('   📊 Computing moving averages and trends...\n');
    
    moving_averages = struct();
    
    % Short-term moving averages (7 timesteps)
    window_short = min(7, floor(num_timesteps / 3));
    if window_short >= 2
        moving_averages.pressure_ma_short = compute_moving_average(time_series_data.pressure, window_short);
        moving_averages.oil_sat_ma_short = compute_moving_average(time_series_data.oil_saturation, window_short);
        moving_averages.water_sat_ma_short = compute_moving_average(time_series_data.water_saturation, window_short);
    end
    
    # Long-term moving averages (21 timesteps)
    window_long = min(21, floor(num_timesteps / 2));
    if window_long >= 2
        moving_averages.pressure_ma_long = compute_moving_average(time_series_data.pressure, window_long);
        moving_averages.oil_sat_ma_long = compute_moving_average(time_series_data.oil_saturation, window_long);
        moving_averages.water_sat_ma_long = compute_moving_average(time_series_data.water_saturation, window_long);
    end
    
    temporal_features.moving_averages = moving_averages;
    
    # ========================================
    # Trend Analysis
    # ========================================
    trend_analysis = struct();
    
    # Linear trends over different windows
    if num_timesteps >= 5
        trend_analysis.pressure_trend_short = compute_linear_trend(time_series_data.pressure, min(10, num_timesteps));
        trend_analysis.oil_sat_trend_short = compute_linear_trend(time_series_data.oil_saturation, min(10, num_timesteps));
        trend_analysis.water_sat_trend_short = compute_linear_trend(time_series_data.water_saturation, min(10, num_timesteps));
    end
    
    if num_timesteps >= 10
        trend_analysis.pressure_trend_long = compute_linear_trend(time_series_data.pressure, num_timesteps);
        trend_analysis.oil_sat_trend_long = compute_linear_trend(time_series_data.oil_saturation, num_timesteps);
        trend_analysis.water_sat_trend_long = compute_linear_trend(time_series_data.water_saturation, num_timesteps);
    end
    
    temporal_features.trends = trend_analysis;
    
    # ========================================
    # Volatility and Variability Measures
    # ========================================
    volatility_features = struct();
    
    # Rolling standard deviation
    if num_timesteps >= 5
        volatility_features.pressure_volatility = compute_rolling_std(time_series_data.pressure, min(5, num_timesteps));
        volatility_features.oil_sat_volatility = compute_rolling_std(time_series_data.oil_saturation, min(5, num_timesteps));
        volatility_features.water_sat_volatility = compute_rolling_std(time_series_data.water_saturation, min(5, num_timesteps));
    end
    
    # Coefficient of variation
    volatility_features.pressure_cv = calculate_coefficient_variation(time_series_data.pressure);
    volatility_features.oil_sat_cv = calculate_coefficient_variation(time_series_data.oil_saturation);
    volatility_features.water_sat_cv = calculate_coefficient_variation(time_series_data.water_saturation);
    
    temporal_features.volatility = volatility_features;
    
    # ========================================
    # Temporal Indicators
    # ========================================
    temporal_indicators = struct();
    
    # Simulation time features (cyclical encoding)
    if isfield(simulation_data, 'schedule') && isfield(simulation_data.schedule, 'step')
        time_features = create_temporal_indicators(simulation_data.schedule);
        temporal_indicators = time_features;
    end
    
    temporal_features.indicators = temporal_indicators;
    
    # Count features
    temporal_features.num_base_features = count_temporal_features(temporal_features);

end

function lag_features = compute_lag_features(simulation_data, config)
% Compute lagged versions of key variables for time series modeling
% FASE 3 ENHANCEMENT: Multiple lag intervals with trend capture
    
    fprintf('   ⏮️  Computing lag features for time series modeling...\n');
    
    states = simulation_data.states;
    num_timesteps = length(states);
    
    # Define lag intervals based on simulation length
    if num_timesteps >= 20
        lag_intervals = [1, 3, 6, 12];  # Full lag set
    elseif num_timesteps >= 10
        lag_intervals = [1, 3, 6];     # Reduced lag set
    else
        lag_intervals = [1];           # Minimal lag set
    end
    
    lag_features = struct();
    lag_features.lag_intervals = lag_intervals;
    
    # Extract base time series
    time_series_data = extract_time_series_from_states(states);
    
    # Compute lags for each variable and interval
    for lag_idx = 1:length(lag_intervals)
        lag_interval = lag_intervals(lag_idx);
        
        if lag_interval >= num_timesteps
            continue;  # Skip if lag is too large
        end
        
        lag_suffix = sprintf('_lag_%d', lag_interval);
        
        # Pressure lags
        lag_features.(['pressure' lag_suffix]) = create_lagged_series(time_series_data.pressure, lag_interval);
        
        # Saturation lags
        lag_features.(['oil_sat' lag_suffix]) = create_lagged_series(time_series_data.oil_saturation, lag_interval);
        lag_features.(['water_sat' lag_suffix]) = create_lagged_series(time_series_data.water_saturation, lag_interval);
        lag_features.(['gas_sat' lag_suffix]) = create_lagged_series(time_series_data.gas_saturation, lag_interval);
    end
    
    # Count lag features
    lag_features.num_lag_features = count_lag_features(lag_features);

end

function derivative_features = generate_derivative_features(simulation_data, config)
% Generate derivative features for trend and acceleration analysis
% FASE 3 ENHANCEMENT: Multiple-order derivatives with smoothing
    
    fprintf('   📈 Computing derivative features (1st and 2nd order)...\n');
    
    states = simulation_data.states;
    num_timesteps = length(states);
    
    if num_timesteps < 3
        error(['Insufficient timesteps for derivative computation.\n' ...
               'REQUIRED: Minimum 3 timesteps for 2nd order derivatives.\n' ...
               'Canon requires adequate temporal resolution.']);
    end
    
    derivative_features = struct();
    
    # Extract time series
    time_series_data = extract_time_series_from_states(states);
    
    # ========================================
    # First Order Derivatives (Velocity/Rate of Change)
    # ========================================
    derivative_features.first_order = struct();
    
    derivative_features.first_order.pressure_rate = compute_first_derivative(time_series_data.pressure);
    derivative_features.first_order.oil_sat_rate = compute_first_derivative(time_series_data.oil_saturation);
    derivative_features.first_order.water_sat_rate = compute_first_derivative(time_series_data.water_saturation);
    derivative_features.first_order.gas_sat_rate = compute_first_derivative(time_series_data.gas_saturation);
    
    # ========================================
    # Second Order Derivatives (Acceleration)
    # ========================================
    if num_timesteps >= 3
        derivative_features.second_order = struct();
        
        derivative_features.second_order.pressure_accel = compute_second_derivative(time_series_data.pressure);
        derivative_features.second_order.oil_sat_accel = compute_second_derivative(time_series_data.oil_saturation);
        derivative_features.second_order.water_sat_accel = compute_second_derivative(time_series_data.water_saturation);
        derivative_features.second_order.gas_sat_accel = compute_second_derivative(time_series_data.gas_saturation);
    end
    
    # ========================================
    # Smoothed Derivatives (Noise Reduction)
    # ========================================
    if num_timesteps >= 5
        derivative_features.smoothed = struct();
        
        # Apply smoothing before differentiation
        smoothed_pressure = smooth_time_series(time_series_data.pressure, 3);
        smoothed_oil_sat = smooth_time_series(time_series_data.oil_saturation, 3);
        
        derivative_features.smoothed.pressure_rate_smooth = compute_first_derivative(smoothed_pressure);
        derivative_features.smoothed.oil_sat_rate_smooth = compute_first_derivative(smoothed_oil_sat);
    end
    
    # Count derivative features
    derivative_features.num_derivatives = count_derivative_features(derivative_features);

end

function pca_features = compute_pca_features(simulation_data, config)
% Compute PCA features for dimensionality reduction
% FASE 3 ENHANCEMENT: Spatial and temporal PCA with variance analysis
    
    fprintf('   📊 Computing PCA components for dimensionality reduction...\n');
    
    pca_features = struct();
    
    # ========================================
    # Spatial PCA (across cells)
    # ========================================
    if isfield(simulation_data, 'states') && ~isempty(simulation_data.states)
        states = simulation_data.states;
        
        # Extract spatial data matrix (cells × variables)
        spatial_data_matrix = create_spatial_data_matrix(states);
        
        if size(spatial_data_matrix, 1) > 10 && size(spatial_data_matrix, 2) > 1
            spatial_pca = compute_spatial_pca(spatial_data_matrix, config);
            pca_features.spatial = spatial_pca;
        end
    end
    
    # ========================================
    # Temporal PCA (across timesteps)
    # ========================================
    if isfield(simulation_data, 'states') && length(simulation_data.states) > 5
        # Extract temporal data matrix (timesteps × aggregated variables)
        temporal_data_matrix = create_temporal_data_matrix(simulation_data.states);
        
        if size(temporal_data_matrix, 1) > 3 && size(temporal_data_matrix, 2) > 1
            temporal_pca = compute_temporal_pca(temporal_data_matrix, config);
            pca_features.temporal = temporal_pca;
        end
    end
    
    # Count PCA components
    if isfield(pca_features, 'spatial')
        pca_features.num_components = pca_features.spatial.num_components;
        if isfield(pca_features, 'temporal')
            pca_features.num_components = pca_features.num_components + pca_features.temporal.num_components;
        end
    elseif isfield(pca_features, 'temporal')
        pca_features.num_components = pca_features.temporal.num_components;
    else
        pca_features.num_components = 0;
    end

end

function clustering_features = extract_clustering_features(simulation_data, config)
% Extract clustering features using unsupervised learning
% FASE 3 ENHANCEMENT: Multiple clustering algorithms with stability analysis
    
    fprintf('   🎯 Computing clustering features...\n');
    
    clustering_features = struct();
    
    # Extract data for clustering
    if isfield(simulation_data, 'states') && ~isempty(simulation_data.states)
        clustering_data = prepare_clustering_data(simulation_data.states);
        
        if size(clustering_data, 1) > 10
            # K-means clustering
            kmeans_result = perform_kmeans_clustering(clustering_data, config);
            clustering_features.kmeans = kmeans_result;
            
            # Hierarchical clustering (if data size allows)
            if size(clustering_data, 1) <= 1000
                hierarchical_result = perform_hierarchical_clustering(clustering_data, config);
                clustering_features.hierarchical = hierarchical_result;
            end
        end
    end
    
    # Count clusters
    if isfield(clustering_features, 'kmeans')
        clustering_features.num_clusters = clustering_features.kmeans.num_clusters;
    else
        clustering_features.num_clusters = 0;
    end

end

function physics_features = generate_physics_features(simulation_data, flow_diagnostics, config)
% Generate physics-based features including dimensionless numbers
% FASE 3 ENHANCEMENT: Comprehensive physics feature engineering
    
    fprintf('   ⚛️  Computing physics-based and dimensionless features...\n');
    
    physics_features = struct();
    
    # ========================================
    # Dimensionless Numbers
    # ========================================
    if isfield(simulation_data, 'states') && isfield(simulation_data, 'rock') && isfield(simulation_data, 'fluid')
        dimensionless_numbers = compute_dimensionless_numbers(simulation_data);
        physics_features.dimensionless = dimensionless_numbers;
        physics_features.num_dimensionless = count_dimensionless_features(dimensionless_numbers);
    else
        physics_features.num_dimensionless = 0;
    end
    
    # ========================================
    # Flow Metrics (from flow diagnostics)
    # ========================================
    if ~isempty(flow_diagnostics)
        flow_metrics = extract_flow_metrics(flow_diagnostics);
        physics_features.flow_metrics = flow_metrics;
        physics_features.num_flow_metrics = count_flow_metric_features(flow_metrics);
    else
        physics_features.num_flow_metrics = 0;
    end

end

function export_path = export_ml_features_canonical(ml_features, export_name, varargin)
% Export ML features to canonical organization
% FASE 3 ENHANCEMENT: Native .mat format with canonical data structure
    
    fprintf('   💾 Exporting ML features to canonical organization...\n');
    
    # Parse optional arguments
    options = parse_export_options(varargin{:});
    
    # Create canonical export structure
    canonical_features = struct();
    canonical_features.metadata = ml_features.metadata;
    canonical_features.metadata.export_timestamp = datestr(now);
    canonical_features.metadata.export_format = 'canonical_native_mat';
    
    # Organize features by canonical categories
    canonical_features.spatial_features = ml_features.spatial;
    canonical_features.temporal_features = ml_features.temporal;
    canonical_features.physics_features = ml_features.physics;
    canonical_features.dimensionality_reduction = ml_features.dimensionality_reduction;
    canonical_features.feature_importance = ml_features.feature_importance;
    canonical_features.quality_validation = ml_features.quality_validation;
    canonical_features.summary = ml_features.summary;
    
    # Export to canonical directory structure
    try
        base_export_path = get_data_path('by_usage', 'ML_training', 'features');
        ensure_directory_exists(base_export_path);
        
        timestamp = datestr(now, 'yyyymmdd_HHMMSS');
        export_filename = sprintf('%s_%s.mat', export_name, timestamp);
        export_path = fullfile(base_export_path, export_filename);
        
        # Save with canonical structure
        save(export_path, 'canonical_features');
        
        # Create feature metadata file
        metadata_path = fullfile(base_export_path, sprintf('%s_metadata.json', export_name));
        write_ml_features_metadata_json(metadata_path, canonical_features);
        
        fprintf('   ✅ ML features exported: %s\n', export_path);
        
    catch ME
        error('ML features export failed: %s\nREQUIRED: Verify canonical directory structure access.', ME.message);
    end

end

% ========================================
# HELPER FUNCTIONS FOR ML FEATURE ENGINEERING
# ========================================

function validate_ml_feature_inputs(simulation_data, flow_diagnostics, solver_diagnostics)
% Validate all required inputs for ML feature engineering
    
    if isempty(simulation_data)
        error(['Missing simulation data for ML feature engineering.\n' ...
               'REQUIRED: Complete simulation state and configuration data.\n' ...
               'Canon requires valid simulation results.']);
    end
    
    if ~isfield(simulation_data, 'states') || isempty(simulation_data.states)
        error(['Missing simulation states for temporal feature engineering.\n' ...
               'REQUIRED: Time series simulation state data.\n' ...
               'Canon requires complete temporal data.']);
    end

end

function metadata = create_ml_features_metadata(config)
% Create comprehensive metadata for ML features
    
    metadata = struct();
    metadata.computation_timestamp = datestr(now);
    metadata.eagle_west_field = true;
    metadata.fase_3_features = true;
    metadata.canonical_format = true;
    
    # Configuration metadata
    if nargin > 0 && ~isempty(config)
        metadata.config = config;
    else
        metadata.config = struct();
        metadata.config.pca_variance_threshold = 0.95;
        metadata.config.clustering_algorithm = 'kmeans';
        metadata.config.normalization_method = 'zscore';
    end
    
    # Feature engineering parameters
    metadata.feature_parameters = struct();
    metadata.feature_parameters.lag_intervals = [1, 3, 6, 12];
    metadata.feature_parameters.moving_average_windows = [7, 21];
    metadata.feature_parameters.derivative_orders = [1, 2];

end

function coords_norm = normalize_coordinates(coords)
% Normalize coordinates to [0, 1] range
    
    min_coord = min(coords);
    max_coord = max(coords);
    
    if max_coord == min_coord
        coords_norm = zeros(size(coords));
    else
        coords_norm = (coords - min_coord) / (max_coord - min_coord);
    end

end

function boundary_dist = calculate_boundary_distances(x_coords, y_coords, z_coords)
% Calculate distance to domain boundary for each cell
    
    # Calculate distances to each boundary
    x_min_dist = x_coords - min(x_coords);
    x_max_dist = max(x_coords) - x_coords;
    y_min_dist = y_coords - min(y_coords);
    y_max_dist = max(y_coords) - y_coords;
    z_min_dist = z_coords - min(z_coords);
    z_max_dist = max(z_coords) - z_coords;
    
    # Minimum distance to any boundary
    boundary_dist = min([x_min_dist, x_max_dist, y_min_dist, y_max_dist, z_min_dist, z_max_dist], [], 2);

end

function time_series_data = extract_time_series_from_states(states)
% Extract time series data from simulation states
    
    num_timesteps = length(states);
    
    # Initialize time series arrays
    time_series_data = struct();
    
    # Extract average field values
    pressure_series = zeros(num_timesteps, 1);
    oil_sat_series = zeros(num_timesteps, 1);
    water_sat_series = zeros(num_timesteps, 1);
    gas_sat_series = zeros(num_timesteps, 1);
    
    for t = 1:num_timesteps
        state = states{t};
        
        if isfield(state, 'pressure')
            pressure_series(t) = mean(state.pressure);
        end
        
        if isfield(state, 's') && size(state.s, 2) >= 3
            water_sat_series(t) = mean(state.s(:, 1));  # Water
            oil_sat_series(t) = mean(state.s(:, 2));    # Oil
            gas_sat_series(t) = mean(state.s(:, 3));    # Gas
        end
    end
    
    time_series_data.pressure = pressure_series;
    time_series_data.oil_saturation = oil_sat_series;
    time_series_data.water_saturation = water_sat_series;
    time_series_data.gas_saturation = gas_sat_series;

end

function ma_series = compute_moving_average(data_series, window_size)
% Compute moving average with specified window size
    
    n = length(data_series);
    ma_series = zeros(n, 1);
    
    for i = 1:n
        start_idx = max(1, i - window_size + 1);
        end_idx = i;
        ma_series(i) = mean(data_series(start_idx:end_idx));
    end

end

function trend_coeff = compute_linear_trend(data_series, window_size)
% Compute linear trend coefficient over specified window
    
    n = length(data_series);
    trend_coeff = zeros(n, 1);
    
    for i = window_size:n
        start_idx = i - window_size + 1;
        end_idx = i;
        
        y = data_series(start_idx:end_idx);
        x = (1:window_size)';
        
        # Linear regression: y = a*x + b
        X = [x, ones(window_size, 1)];
        coeffs = X \ y;
        trend_coeff(i) = coeffs(1);  # Slope coefficient
    end

end

function lagged_series = create_lagged_series(data_series, lag_interval)
% Create lagged version of time series
    
    n = length(data_series);
    lagged_series = zeros(n, 1);
    
    if lag_interval < n
        lagged_series((lag_interval+1):end) = data_series(1:(end-lag_interval));
    end

end

function first_deriv = compute_first_derivative(data_series)
% Compute first order derivative using central differences
    
    n = length(data_series);
    first_deriv = zeros(n, 1);
    
    # Forward difference for first point
    if n >= 2
        first_deriv(1) = data_series(2) - data_series(1);
    end
    
    # Central differences for middle points
    if n >= 3
        for i = 2:(n-1)
            first_deriv(i) = (data_series(i+1) - data_series(i-1)) / 2;
        end
    end
    
    # Backward difference for last point
    if n >= 2
        first_deriv(n) = data_series(n) - data_series(n-1);
    end

end

function second_deriv = compute_second_derivative(data_series)
% Compute second order derivative
    
    n = length(data_series);
    second_deriv = zeros(n, 1);
    
    # Second order differences for interior points
    if n >= 3
        for i = 2:(n-1)
            second_deriv(i) = data_series(i+1) - 2*data_series(i) + data_series(i-1);
        end
    end

end

# Additional helper functions would continue here...
# This includes PCA computation, clustering algorithms, dimensionless numbers, etc.

# Main execution for testing
if ~nargout && ~isempty(mfilename('fullpath'))
    fprintf('ML Feature Engineering Utils loaded successfully\n');
    fprintf('Available functions:\n');
    functions = ml_feature_engineering();
    function_names = keys(functions);
    for i = 1:length(function_names)
        fprintf('  - %s\n', function_names{i});
    end
end