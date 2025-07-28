# Metadata Specifications for Simulation Data Catalog

## Overview

This document defines comprehensive YAML metadata schemas for all simulation data types, ensuring standardized documentation, traceability, and quality assurance across the Eagle West Field reservoir simulation project.

## 1. Static Data Metadata Schema

### 1.1 Grid Geometry Metadata

```yaml
# Grid metadata schema
grid_metadata:
  # Required fields
  data_type: "static_grid"
  schema_version: "1.0.0"
  
  # Basic identification
  identification:
    name: "eagle_west_corner_point_grid"
    description: "Primary corner-point grid for Eagle West Field"
    data_id: "grid_001"
    creation_date: "2024-01-15T10:30:00Z"
    version: "1.2.3"
    
  # Grid specifications
  geometry:
    grid_type: "corner_point"  # corner_point, cartesian, radial, unstructured
    dimensions:
      nx: 120
      ny: 80
      nz: 25
      total_cells: 240000
      active_cells: 187432
    coordinate_system:
      type: "UTM"
      zone: "31N"
      datum: "WGS84"
    units:
      length: "meters"
      depth: "meters"
    
  # Data quality
  quality:
    completeness: 100.0  # percentage
    validation_status: "passed"  # passed, failed, pending
    qa_flags:
      - "geometry_validated"
      - "topology_checked"
      - "units_verified"
    known_issues: []
    
  # Provenance
  provenance:
    source_type: "seismic_interpretation"  # seismic_interpretation, well_data, geological_model
    creator:
      name: "Dr. Sarah Chen"
      organization: "Reservoir Modeling Team"
      email: "s.chen@company.com"
    creation_software:
      name: "Petrel"
      version: "2023.1"
      license: "commercial"
    workflow_id: "grid_construction_v2.1"
    parent_data: []
    
  # File information
  file_info:
    file_path: "/simulation_data/static/grids/eagle_west_grid.mat"
    file_format: "MATLAB"
    file_size_mb: 45.7
    checksum_md5: "a1b2c3d4e5f6789012345678901234567890abcd"
    compression: "none"
    
  # Relationships
  relationships:
    depends_on: []
    used_by:
      - "rock_properties_001"
      - "well_trajectories_001"
    related_datasets: []
    
  # Search tags
  tags:
    - "corner_point"
    - "primary_grid"
    - "eagle_west"
    - "structural_model"
```

### 1.2 Rock Properties Metadata

```yaml
# Rock properties metadata schema
rock_properties_metadata:
  # Required fields
  data_type: "static_rock_properties"
  schema_version: "1.0.0"
  
  # Basic identification
  identification:
    name: "eagle_west_rock_properties"
    description: "Porosity, permeability, and NTG for Eagle West Field"
    data_id: "rock_001"
    creation_date: "2024-01-20T14:15:00Z"
    version: "2.1.0"
    
  # Property specifications
  properties:
    included_properties:
      - name: "porosity"
        units: "fraction"
        range: [0.05, 0.35]
        distribution: "log_normal"
      - name: "permeability_x"
        units: "mD"
        range: [0.1, 2500.0]
        distribution: "log_normal"
      - name: "permeability_y"
        units: "mD"
        range: [0.1, 2500.0]
        distribution: "log_normal"
      - name: "permeability_z"
        units: "mD"
        range: [0.01, 250.0]
        distribution: "log_normal"
      - name: "net_to_gross"
        units: "fraction"
        range: [0.0, 1.0]
        distribution: "beta"
    
    modeling_method: "sequential_gaussian_simulation"
    variogram_model: "spherical"
    correlation_structure: "anisotropic"
    
  # Data quality
  quality:
    completeness: 98.5
    validation_status: "passed"
    qa_flags:
      - "statistical_validation"
      - "geological_consistency"
      - "upscaling_verified"
    known_issues:
      - "minor_gaps_in_fault_zones"
    
  # Provenance
  provenance:
    source_type: "well_logs_geostatistics"
    creator:
      name: "Dr. Michael Rodriguez"
      organization: "Petrophysics Team"
      email: "m.rodriguez@company.com"
    creation_software:
      name: "SGeMS"
      version: "2.1.3"
      license: "academic"
    workflow_id: "rock_modeling_v3.2"
    parent_data:
      - "well_logs_001"
      - "seismic_attributes_001"
    
  # File information
  file_info:
    file_path: "/simulation_data/static/rock_properties/eagle_west_rock.mat"
    file_format: "MATLAB"
    file_size_mb: 127.3
    checksum_md5: "b2c3d4e5f6789012345678901234567890abcdef"
    compression: "gzip"
    
  # Relationships
  relationships:
    depends_on:
      - "grid_001"
      - "well_logs_001"
    used_by:
      - "simulation_runs_*"
    related_datasets:
      - "seismic_attributes_001"
    
  # Search tags
  tags:
    - "rock_properties"
    - "geostatistics"
    - "porosity"
    - "permeability"
    - "reservoir_characterization"
```

### 1.3 Well Data Metadata

```yaml
# Well data metadata schema
well_data_metadata:
  # Required fields
  data_type: "static_wells"
  schema_version: "1.0.0"
  
  # Basic identification
  identification:
    name: "eagle_west_well_trajectories"
    description: "Well trajectories and completion data for all wells"
    data_id: "wells_001"
    creation_date: "2024-01-25T09:45:00Z"
    version: "1.1.2"
    
  # Well specifications
  wells:
    total_wells: 15
    well_types:
      producers: 10
      injectors: 5
    completion_types:
      vertical: 3
      horizontal: 12
    well_list:
      - name: "PROD-01"
        type: "producer"
        completion: "horizontal"
        total_depth: 3250.5
        perforated_length: 1200.0
      - name: "INJ-01"
        type: "water_injector"
        completion: "vertical"
        total_depth: 3180.2
        perforated_length: 85.0
    
  # Data quality
  quality:
    completeness: 100.0
    validation_status: "passed"
    qa_flags:
      - "trajectory_validated"
      - "completion_verified"
      - "grid_intersection_checked"
    known_issues: []
    
  # Provenance
  provenance:
    source_type: "drilling_reports_surveys"
    creator:
      name: "Jane Smith"
      organization: "Drilling Engineering"
      email: "j.smith@company.com"
    creation_software:
      name: "Compass"
      version: "5.1.2"
      license: "commercial"
    workflow_id: "well_trajectory_processing_v1.5"
    parent_data:
      - "drilling_surveys_raw"
      - "completion_reports"
    
  # File information
  file_info:
    file_path: "/simulation_data/static/wells/eagle_west_wells.mat"
    file_format: "MATLAB"
    file_size_mb: 8.9
    checksum_md5: "c3d4e5f6789012345678901234567890abcdef12"
    compression: "none"
    
  # Relationships
  relationships:
    depends_on:
      - "grid_001"
    used_by:
      - "simulation_runs_*"
      - "production_data_*"
    related_datasets:
      - "completion_design_001"
    
  # Search tags
  tags:
    - "well_trajectories"
    - "completions"
    - "drilling"
    - "production"
    - "injection"
```

## 2. Dynamic Data Metadata Schema

### 2.1 Timestep Solution Data

```yaml
# Dynamic solution metadata schema
dynamic_solution_metadata:
  # Required fields
  data_type: "dynamic_solution"
  schema_version: "1.0.0"
  
  # Basic identification
  identification:
    name: "eagle_west_pressure_saturation_solution"
    description: "Pressure and saturation fields for simulation timesteps"
    data_id: "solution_001"
    creation_date: "2024-02-01T16:20:00Z"
    version: "1.0.0"
    
  # Simulation specifications
  simulation:
    simulation_id: "eagle_west_base_case_v1"
    solver: "MRST"
    solver_version: "2023b"
    timesteps:
      total_steps: 120
      time_unit: "days"
      time_range: [0, 3650]  # 10 years
      step_sizes: "adaptive"
    
    solution_variables:
      - name: "pressure"
        units: "bar"
        range: [180.0, 420.0]
        description: "Cell pressure"
      - name: "s_water"
        units: "fraction"
        range: [0.15, 0.85]
        description: "Water saturation"
      - name: "s_oil"
        units: "fraction"
        range: [0.15, 0.85]
        description: "Oil saturation"
    
  # Data quality
  quality:
    completeness: 100.0
    validation_status: "passed"
    qa_flags:
      - "mass_balance_checked"
      - "convergence_verified"
      - "physical_constraints_satisfied"
    known_issues: []
    convergence_statistics:
      failed_timesteps: 0
      average_iterations: 6.2
      max_iterations: 15
    
  # Provenance
  provenance:
    source_type: "numerical_simulation"
    creator:
      name: "Dr. Ahmed Hassan"
      organization: "Reservoir Simulation Team"
      email: "a.hassan@company.com"
    creation_software:
      name: "MRST"
      version: "2023b"
      license: "open_source"
    workflow_id: "base_case_simulation_v2.0"
    parent_data:
      - "grid_001"
      - "rock_001"
      - "wells_001"
      - "fluid_001"
    
  # File information
  file_info:
    file_path: "/simulation_data/dynamic/solutions/eagle_west_solution.mat"
    file_format: "MATLAB"
    file_size_mb: 2847.6
    checksum_md5: "d4e5f6789012345678901234567890abcdef1234"
    compression: "gzip"
    
  # Performance metrics
  performance:
    computation_time_hours: 6.5
    memory_usage_gb: 12.8
    cpu_cores_used: 16
    parallel_efficiency: 0.85
    
  # Relationships
  relationships:
    depends_on:
      - "grid_001"
      - "rock_001"
      - "wells_001"
      - "fluid_001"
    used_by:
      - "production_forecast_001"
      - "visualization_001"
    related_datasets:
      - "well_controls_001"
    
  # Search tags
  tags:
    - "pressure"
    - "saturation"
    - "timestep_data"
    - "simulation_solution"
    - "dynamic_reservoir"
```

### 2.2 Well Production Data

```yaml
# Well production metadata schema
well_production_metadata:
  # Required fields
  data_type: "dynamic_well_production"
  schema_version: "1.0.0"
  
  # Basic identification
  identification:
    name: "eagle_west_well_production_rates"
    description: "Oil, water, and gas production rates for all wells"
    data_id: "production_001"
    creation_date: "2024-02-01T16:30:00Z"
    version: "1.0.0"
    
  # Production specifications
  production:
    wells_included: 15
    time_range: [0, 3650]  # days
    reporting_frequency: "daily"
    
    production_variables:
      - name: "oil_rate"
        units: "STB/day"
        description: "Oil production rate"
      - name: "water_rate"
        units: "STB/day"
        description: "Water production rate"
      - name: "gas_rate"
        units: "Mscf/day"
        description: "Gas production rate"
      - name: "bhp"
        units: "psia"
        description: "Bottom hole pressure"
      - name: "wct"
        units: "fraction"
        description: "Water cut"
    
  # Data quality
  quality:
    completeness: 100.0
    validation_status: "passed"
    qa_flags:
      - "material_balance_verified"
      - "rate_constraints_checked"
      - "physical_limits_respected"
    known_issues: []
    
  # Provenance
  provenance:
    source_type: "simulation_output"
    creator:
      name: "Dr. Ahmed Hassan"
      organization: "Reservoir Simulation Team"
      email: "a.hassan@company.com"
    creation_software:
      name: "MRST"
      version: "2023b"
      license: "open_source"
    workflow_id: "production_extraction_v1.2"
    parent_data:
      - "solution_001"
      - "wells_001"
    
  # File information
  file_info:
    file_path: "/simulation_data/dynamic/production/eagle_west_production.mat"
    file_format: "MATLAB"
    file_size_mb: 15.7
    checksum_md5: "e5f6789012345678901234567890abcdef12345"
    compression: "none"
    
  # Relationships
  relationships:
    depends_on:
      - "solution_001"
      - "wells_001"
    used_by:
      - "economics_001"
      - "visualization_002"
    related_datasets:
      - "well_controls_001"
    
  # Search tags
  tags:
    - "production_rates"
    - "well_performance"
    - "oil_production"
    - "water_cut"
    - "reservoir_management"
```

## 3. Derived Data Metadata Schema

### 3.1 Calculated Metrics

```yaml
# Derived metrics metadata schema
derived_metrics_metadata:
  # Required fields
  data_type: "derived_metrics"
  schema_version: "1.0.0"
  
  # Basic identification
  identification:
    name: "eagle_west_reservoir_metrics"
    description: "Calculated reservoir performance metrics and KPIs"
    data_id: "metrics_001"
    creation_date: "2024-02-05T11:15:00Z"
    version: "1.0.0"
    
  # Metrics specifications
  metrics:
    calculation_method: "post_processing"
    update_frequency: "after_simulation"
    
    included_metrics:
      - name: "recovery_factor"
        units: "fraction"
        description: "Oil recovery factor"
        calculation: "cumulative_oil_production / OOIP"
      - name: "sweep_efficiency"
        units: "fraction"
        description: "Volumetric sweep efficiency"
        calculation: "contacted_volume / total_volume"
      - name: "water_breakthrough_time"
        units: "days"
        description: "Time to first water production"
        calculation: "first_nonzero_water_rate"
      - name: "reservoir_pressure_decline"
        units: "psi/year"
        description: "Average reservoir pressure decline rate"
        calculation: "linear_regression_slope"
    
  # Calculation details
  calculation:
    algorithm: "custom_analytical"
    dependencies:
      - "solution_001"
      - "production_001"
      - "rock_001"
    validation_method: "analytical_benchmarks"
    uncertainty_quantification: true
    
  # Data quality
  quality:
    completeness: 100.0
    validation_status: "passed"
    qa_flags:
      - "physics_validated"
      - "benchmark_compared"
      - "uncertainty_quantified"
    known_issues: []
    
  # Provenance
  provenance:
    source_type: "post_processing_calculation"
    creator:
      name: "Dr. Lisa Wang"
      organization: "Reservoir Analytics Team"
      email: "l.wang@company.com"
    creation_software:
      name: "MATLAB"
      version: "R2023b"
      license: "commercial"
    workflow_id: "metrics_calculation_v2.1"
    parent_data:
      - "solution_001"
      - "production_001"
      - "rock_001"
    
  # File information
  file_info:
    file_path: "/simulation_data/derived/metrics/eagle_west_metrics.mat"
    file_format: "MATLAB"
    file_size_mb: 3.2
    checksum_md5: "f6789012345678901234567890abcdef123456"
    compression: "none"
    
  # Relationships
  relationships:
    depends_on:
      - "solution_001"
      - "production_001"
      - "rock_001"
    used_by:
      - "dashboard_001"
      - "report_001"
    related_datasets:
      - "economics_001"
    
  # Search tags
  tags:
    - "kpis"
    - "performance_metrics"
    - "recovery_factor"
    - "sweep_efficiency"
    - "reservoir_analytics"
```

## 4. Visualization Metadata Schema

### 4.1 Static Plots

```yaml
# Visualization metadata schema
visualization_metadata:
  # Required fields
  data_type: "visualization_static"
  schema_version: "1.0.0"
  
  # Basic identification
  identification:
    name: "eagle_west_pressure_maps"
    description: "Static pressure field visualizations at key timesteps"
    data_id: "viz_001"
    creation_date: "2024-02-10T13:45:00Z"
    version: "1.0.0"
    
  # Visualization specifications
  visualization:
    plot_type: "2d_field_map"
    variable: "pressure"
    timesteps: [0, 365, 1095, 2190, 3650]  # days
    color_scheme: "jet"
    resolution: "high"
    
    plot_parameters:
      figure_size: [12, 8]  # inches
      dpi: 300
      color_bar: true
      grid_overlay: true
      well_locations: true
      contour_lines: 10
    
    output_formats:
      - "PNG"
      - "PDF"
      - "SVG"
    
  # Data quality
  quality:
    completeness: 100.0
    validation_status: "passed"
    qa_flags:
      - "data_range_verified"
      - "color_scale_appropriate"
      - "visual_quality_checked"
    known_issues: []
    
  # Provenance
  provenance:
    source_type: "automated_visualization"
    creator:
      name: "Visualization Pipeline"
      organization: "Data Visualization Team"
      email: "viz.team@company.com"
    creation_software:
      name: "MATLAB"
      version: "R2023b"
      license: "commercial"
    workflow_id: "pressure_mapping_v1.3"
    parent_data:
      - "solution_001"
      - "grid_001"
    
  # File information
  file_info:
    file_path: "/simulation_data/visualization/static/pressure_maps/"
    file_format: "multiple"
    file_size_mb: 45.8
    checksum_md5: "789012345678901234567890abcdef1234567"
    compression: "none"
    
  # Relationships
  relationships:
    depends_on:
      - "solution_001"
      - "grid_001"
    used_by:
      - "presentation_001"
      - "report_001"
    related_datasets:
      - "saturation_maps_001"
    
  # Search tags
  tags:
    - "pressure_maps"
    - "field_visualization"
    - "2d_plots"
    - "reservoir_monitoring"
    - "static_visualization"
```

### 4.2 Animations

```yaml
# Animation metadata schema
animation_metadata:
  # Required fields
  data_type: "visualization_animation"
  schema_version: "1.0.0"
  
  # Basic identification
  identification:
    name: "eagle_west_saturation_evolution"
    description: "Water saturation evolution animation over simulation time"
    data_id: "anim_001"
    creation_date: "2024-02-12T15:30:00Z"
    version: "1.0.0"
    
  # Animation specifications
  animation:
    variable: "water_saturation"
    time_range: [0, 3650]  # days
    frame_rate: 10  # fps
    total_frames: 120
    resolution: "1920x1080"
    
    animation_parameters:
      color_scheme: "blue_white_red"
      fixed_color_scale: [0.15, 0.85]
      well_trajectories: true
      time_indicator: true
      progress_bar: true
      
    output_formats:
      - "MP4"
      - "AVI"
      - "GIF"
    
  # Technical details
  technical:
    file_size_mb: 187.5
    duration_seconds: 12.0
    compression: "H.264"
    quality: "high"
    
  # Data quality
  quality:
    completeness: 100.0
    validation_status: "passed"
    qa_flags:
      - "smooth_transitions"
      - "consistent_scaling"
      - "temporal_continuity"
    known_issues: []
    
  # Provenance
  provenance:
    source_type: "automated_animation"
    creator:
      name: "Animation Pipeline"
      organization: "Data Visualization Team"
      email: "viz.team@company.com"
    creation_software:
      name: "MATLAB"
      version: "R2023b"
      license: "commercial"
    workflow_id: "saturation_animation_v2.0"
    parent_data:
      - "solution_001"
      - "grid_001"
    
  # File information
  file_info:
    file_path: "/simulation_data/visualization/animations/saturation_evolution.mp4"
    file_format: "MP4"
    file_size_mb: 187.5
    checksum_md5: "89012345678901234567890abcdef12345678"
    compression: "H.264"
    
  # Relationships
  relationships:
    depends_on:
      - "solution_001"
      - "grid_001"
    used_by:
      - "presentation_002"
      - "training_materials_001"
    related_datasets:
      - "pressure_animation_001"
    
  # Search tags
  tags:
    - "saturation_animation"
    - "time_evolution"
    - "water_flooding"
    - "reservoir_dynamics"
    - "video_visualization"
```

## 5. ML Features Metadata Schema

```yaml
# ML features metadata schema
ml_features_metadata:
  # Required fields
  data_type: "ml_features"
  schema_version: "1.0.0"
  
  # Basic identification
  identification:
    name: "eagle_west_reservoir_features"
    description: "Engineered features for reservoir ML applications"
    data_id: "features_001"
    creation_date: "2024-02-15T10:20:00Z"
    version: "1.0.0"
    
  # Feature specifications
  features:
    feature_engineering_method: "domain_expert_guided"
    total_features: 47
    target_applications:
      - "production_forecasting"
      - "well_placement_optimization"
      - "reservoir_characterization"
    
    feature_categories:
      static_features:
        - name: "porosity_statistics"
          count: 5
          description: "Mean, std, min, max, p90 of cell porosity"
        - name: "permeability_statistics"
          count: 6
          description: "Statistics for kx, ky, kz"
        - name: "geometric_features"
          count: 8
          description: "Distance to boundaries, well spacing, etc."
      
      dynamic_features:
        - name: "pressure_derivatives"
          count: 4
          description: "Pressure gradients and time derivatives"
        - name: "saturation_patterns"
          count: 6
          description: "Saturation front characteristics"
        - name: "well_performance"
          count: 8
          description: "Rate histories and performance indicators"
      
      engineered_features:
        - name: "connectivity_indices"
          count: 5
          description: "Flow connectivity measures"
        - name: "sweep_indicators"
          count: 5
          description: "Volumetric sweep characteristics"
    
    preprocessing:
      scaling_method: "standard_scaler"
      outlier_handling: "iqr_clipping"
      missing_value_strategy: "interpolation"
      feature_selection: "mutual_information"
    
  # Data quality
  quality:
    completeness: 98.7
    validation_status: "passed"
    qa_flags:
      - "feature_correlation_analyzed"
      - "scaling_verified"
      - "missing_values_handled"
    known_issues:
      - "minor_edge_effects_in_boundary_features"
    
    feature_statistics:
      highly_correlated_pairs: 3
      zero_variance_features: 0
      missing_value_percentage: 1.3
    
  # Provenance
  provenance:
    source_type: "feature_engineering"
    creator:
      name: "Dr. Maria Gonzalez"
      organization: "Data Science Team"
      email: "m.gonzalez@company.com"
    creation_software:
      name: "Python"
      version: "3.9.16"
      license: "open_source"
    workflow_id: "feature_engineering_v3.1"
    parent_data:
      - "solution_001"
      - "production_001"
      - "rock_001"
      - "grid_001"
    
  # File information
  file_info:
    file_path: "/simulation_data/ml/features/eagle_west_features.pkl"
    file_format: "pickle"
    file_size_mb: 89.4
    checksum_md5: "9012345678901234567890abcdef123456789"
    compression: "gzip"
    
  # ML specifications
  ml_specs:
    feature_matrix_shape: [187432, 47]  # [n_samples, n_features]
    data_splits:
      train: 0.7
      validation: 0.15
      test: 0.15
    cross_validation: "5_fold_spatial"
    
  # Relationships
  relationships:
    depends_on:
      - "solution_001"
      - "production_001"
      - "rock_001"
      - "grid_001"
    used_by:
      - "ml_model_001"
      - "ml_model_002"
    related_datasets:
      - "ml_targets_001"
    
  # Search tags
  tags:
    - "machine_learning"
    - "feature_engineering"
    - "reservoir_features"
    - "production_forecasting"
    - "data_science"
```

## 6. Simulation Run Metadata Schema

```yaml
# Simulation run metadata schema
simulation_run_metadata:
  # Required fields
  data_type: "simulation_run"
  schema_version: "1.0.0"
  
  # Basic identification
  identification:
    name: "eagle_west_base_case_run"
    description: "Base case reservoir simulation run for Eagle West Field"
    data_id: "run_001"
    creation_date: "2024-02-01T08:00:00Z"
    version: "1.0.0"
    
  # Simulation parameters
  simulation_parameters:
    case_name: "base_case_v1"
    simulation_type: "black_oil"
    solver: "MRST"
    solver_version: "2023b"
    
    numerical_settings:
      time_stepping: "adaptive"
      max_timestep: 30.0  # days
      min_timestep: 0.1   # days
      convergence_tolerance: 1e-6
      max_iterations: 25
      linear_solver: "GMRES"
      preconditioner: "ILU"
    
    physical_model:
      phases: ["oil", "water", "gas"]
      pvt_model: "black_oil"
      relative_permeability: "corey"
      capillary_pressure: "brooks_corey"
      aquifer_model: "carter_tracy"
    
    well_controls:
      producers:
        control_type: "bhp"
        target_bhp: 200.0  # bar
        min_oil_rate: 10.0  # STB/day
      injectors:
        control_type: "rate"
        target_rate: 2000.0  # STB/day
        max_bhp: 400.0  # bar
    
  # Execution details
  execution:
    start_time: "2024-02-01T08:00:00Z"
    end_time: "2024-02-01T14:30:00Z"
    total_runtime_hours: 6.5
    compute_environment:
      cluster_name: "HPC-Reservoir-Cluster"
      nodes_used: 2
      cores_per_node: 16
      memory_per_node_gb: 64
      operating_system: "Linux CentOS 7"
    
    performance_metrics:
      total_timesteps: 120
      failed_timesteps: 0
      average_iterations: 6.2
      max_iterations_used: 15
      memory_peak_gb: 12.8
      parallel_efficiency: 0.85
    
  # Input data versions
  input_data:
    grid: "grid_001_v1.2.3"
    rock_properties: "rock_001_v2.1.0"
    fluid_properties: "fluid_001_v1.0.0"
    wells: "wells_001_v1.1.2"
    schedule: "schedule_001_v1.0.0"
    
  # Output data generated
  output_data:
    solution_fields: "solution_001"
    well_data: "production_001"
    summary_vectors: "summary_001"
    convergence_reports: "convergence_001"
    
  # Quality assurance
  quality:
    run_status: "completed_successfully"
    validation_status: "passed"
    qa_flags:
      - "mass_balance_verified"
      - "energy_balance_verified"
      - "convergence_acceptable"
      - "physical_constraints_satisfied"
    known_issues: []
    
    validation_results:
      mass_balance_error: 1.2e-8
      energy_balance_error: 3.4e-9
      pressure_range_valid: true
      saturation_range_valid: true
    
  # Provenance
  provenance:
    creator:
      name: "Dr. Ahmed Hassan"
      organization: "Reservoir Simulation Team"
      email: "a.hassan@company.com"
    workflow_id: "standard_simulation_v2.3"
    experiment_id: "eagle_west_base_study"
    commit_hash: "a1b2c3d4e5f67890"
    
  # Version control
  version_control:
    repository: "eagle_west_simulation"
    branch: "main"
    commit_hash: "a1b2c3d4e5f67890"
    commit_message: "Base case simulation with updated rock properties"
    config_files:
      - path: "configs/base_case.yaml"
        hash: "b2c3d4e5f6789012"
      - path: "scripts/run_simulation.m"
        hash: "c3d4e5f6789012345"
    
  # File information
  file_info:
    output_directory: "/simulation_data/runs/run_001/"
    total_size_gb: 3.2
    log_file: "/simulation_data/runs/run_001/simulation.log"
    config_backup: "/simulation_data/runs/run_001/configs/"
    
  # Relationships
  relationships:
    depends_on:
      - "grid_001"
      - "rock_001"
      - "fluid_001"
      - "wells_001"
    produces:
      - "solution_001"
      - "production_001"
    related_runs:
      - "sensitivity_runs_002-010"
    
  # Search tags
  tags:
    - "base_case"
    - "black_oil_simulation"
    - "MRST"
    - "production_forecast"
    - "reservoir_simulation"
```

## 7. Cross-Reference and Search Systems

### 7.1 Metadata Cross-Reference Schema

```yaml
# Cross-reference metadata schema
cross_reference_metadata:
  schema_version: "1.0.0"
  
  # Global identifiers
  global_identifiers:
    project_id: "eagle_west_field_2024"
    study_id: "base_case_development"
    phase_id: "initial_simulation"
    
  # Relationship mapping
  relationships:
    # Parent-child relationships
    lineage:
      - parent: "grid_001"
        children: ["rock_001", "wells_001", "solution_001"]
      - parent: "solution_001"
        children: ["production_001", "metrics_001", "viz_001"]
    
    # Dependency graph
    dependencies:
      "solution_001":
        depends_on: ["grid_001", "rock_001", "wells_001", "fluid_001"]
        dependency_type: "hard"
      "metrics_001":
        depends_on: ["solution_001", "production_001"]
        dependency_type: "soft"
    
    # Usage relationships
    usage:
      "grid_001":
        used_by: ["rock_001", "wells_001", "solution_001", "viz_001"]
      "solution_001":
        used_by: ["production_001", "metrics_001", "viz_001", "anim_001"]
    
  # Cross-cutting concerns
  cross_cutting:
    quality_assurance:
      - data_id: "grid_001"
        qa_level: "high"
        validation_methods: ["geometry", "topology", "units"]
      - data_id: "solution_001"
        qa_level: "critical"
        validation_methods: ["physics", "convergence", "mass_balance"]
    
    version_control:
      - data_id: "grid_001"
        git_tracked: true
        backup_strategy: "incremental"
      - data_id: "solution_001"
        git_tracked: false
        backup_strategy: "full_snapshot"
```

### 7.2 Search and Filtering Schema

```yaml
# Search configuration schema
search_configuration:
  schema_version: "1.0.0"
  
  # Searchable fields
  searchable_fields:
    primary:
      - "identification.name"
      - "identification.description"
      - "identification.data_id"
      - "tags"
    
    secondary:
      - "provenance.creator.name"
      - "provenance.creator.organization"
      - "file_info.file_path"
      - "quality.qa_flags"
    
    temporal:
      - "identification.creation_date"
      - "identification.version"
      - "provenance.workflow_id"
    
  # Filter categories
  filter_categories:
    data_type:
      values: ["static_grid", "static_rock_properties", "dynamic_solution", 
               "derived_metrics", "visualization_static", "ml_features"]
    
    quality_status:
      values: ["passed", "failed", "pending", "under_review"]
    
    creator_organization:
      values: ["Reservoir Modeling Team", "Petrophysics Team", 
               "Data Science Team", "Visualization Team"]
    
    file_format:
      values: ["MATLAB", "HDF5", "NetCDF", "CSV", "pickle"]
    
    validation_status:
      values: ["passed", "failed", "pending"]
    
  # Search operators
  search_operators:
    text_search: ["contains", "exact_match", "regex", "fuzzy"]
    numerical: ["equals", "greater_than", "less_than", "range"]
    temporal: ["before", "after", "between", "last_n_days"]
    categorical: ["in", "not_in", "equals"]
    
  # Search indices
  search_indices:
    full_text_index:
      fields: ["identification.name", "identification.description", "tags"]
      type: "inverted_index"
    
    temporal_index:
      fields: ["identification.creation_date"]
      type: "btree"
    
    categorical_index:
      fields: ["data_type", "quality.validation_status"]
      type: "hash"
```

## 8. Validation Rules and Quality Assurance

### 8.1 Schema Validation Rules

```yaml
# Validation rules schema
validation_rules:
  schema_version: "1.0.0"
  
  # Required field validation
  required_fields:
    all_schemas:
      - "data_type"
      - "schema_version"
      - "identification.name"
      - "identification.data_id"
      - "identification.creation_date"
      - "provenance.creator"
      - "quality.validation_status"
    
    static_data:
      additional_required:
        - "file_info.file_path"
        - "file_info.checksum_md5"
    
    dynamic_data:
      additional_required:
        - "simulation.simulation_id"
        - "performance.computation_time_hours"
    
  # Data type validation
  data_type_validation:
    identification.creation_date:
      format: "ISO8601"
      example: "2024-01-15T10:30:00Z"
    
    file_info.file_size_mb:
      type: "float"
      minimum: 0.0
    
    quality.completeness:
      type: "float"
      minimum: 0.0
      maximum: 100.0
    
    provenance.creator.email:
      format: "email"
      pattern: "^[\\w\\.-]+@[\\w\\.-]+\\.[a-zA-Z]{2,}$"
    
  # Business logic validation
  business_rules:
    file_existence:
      rule: "file_info.file_path must exist"
      severity: "error"
    
    checksum_integrity:
      rule: "file_info.checksum_md5 must match actual file"
      severity: "error"
    
    dependency_consistency:
      rule: "all dependencies in relationships.depends_on must exist"
      severity: "warning"
    
    version_consistency:
      rule: "schema_version must match current specification"
      severity: "error"
    
  # Quality thresholds
  quality_thresholds:
    completeness:
      minimum: 95.0
      warning: 98.0
      target: 100.0
    
    validation_age_days:
      maximum: 30
      warning: 7
      target: 1
```

### 8.2 Quality Assurance Flags

```yaml
# Quality assurance flags schema
qa_flags_schema:
  schema_version: "1.0.0"
  
  # Standard QA flags by data type
  standard_qa_flags:
    static_grid:
      - "geometry_validated"
      - "topology_checked"
      - "units_verified"
      - "coordinate_system_confirmed"
    
    static_rock_properties:
      - "statistical_validation"
      - "geological_consistency"
      - "upscaling_verified"
      - "correlation_structure_validated"
    
    dynamic_solution:
      - "mass_balance_checked"
      - "convergence_verified"
      - "physical_constraints_satisfied"
      - "temporal_continuity_confirmed"
    
    derived_metrics:
      - "physics_validated"
      - "benchmark_compared"
      - "uncertainty_quantified"
      - "calculation_verified"
    
    visualization:
      - "data_range_verified"
      - "color_scale_appropriate"
      - "visual_quality_checked"
      - "accessibility_compliant"
    
  # Custom QA flags
  custom_qa_flags:
    domain_specific:
      - "reservoir_engineering_approved"
      - "geophysics_validated"
      - "drilling_engineering_confirmed"
    
    technical:
      - "performance_benchmarked"
      - "security_scanned"
      - "backup_verified"
    
  # QA flag definitions
  flag_definitions:
    geometry_validated:
      description: "Grid geometry has been validated for consistency"
      validation_method: "automated_geometry_checks"
      required_for: ["static_grid"]
    
    mass_balance_checked:
      description: "Material balance has been verified within tolerance"
      validation_method: "mass_balance_calculation"
      required_for: ["dynamic_solution"]
      tolerance: 1e-6
```

## 9. Implementation Guidelines

### 9.1 Metadata Creation Workflow

```yaml
# Metadata creation workflow
metadata_workflow:
  schema_version: "1.0.0"
  
  # Automated metadata generation
  automated_generation:
    triggers:
      - "file_creation"
      - "simulation_completion"
      - "data_processing_finish"
    
    auto_populated_fields:
      - "identification.creation_date"
      - "file_info.file_size_mb"
      - "file_info.checksum_md5"
      - "provenance.creation_software"
      - "technical.file_format"
    
    validation_hooks:
      pre_creation: ["schema_validation", "required_field_check"]
      post_creation: ["file_integrity_check", "relationship_validation"]
  
  # Manual metadata entry
  manual_entry:
    required_manual_fields:
      - "identification.name"
      - "identification.description"
      - "provenance.creator"
      - "quality.qa_flags"
      - "tags"
    
    validation_checkpoints:
      - "field_completeness"
      - "business_rule_compliance"
      - "relationship_consistency"
  
  # Quality assurance process
  qa_process:
    review_stages:
      - stage: "automated_validation"
        duration: "immediate"
        criteria: ["schema_compliance", "required_fields"]
      
      - stage: "peer_review"
        duration: "1_day"
        criteria: ["technical_accuracy", "completeness"]
      
      - stage: "domain_expert_review"
        duration: "3_days"
        criteria: ["domain_correctness", "business_alignment"]
    
    approval_workflow:
      reviewers:
        - role: "data_steward"
          required: true
        - role: "domain_expert"
          required: true
        - role: "technical_lead"
          required: false
```

### 9.2 Storage and Access Patterns

```yaml
# Storage and access patterns
storage_access:
  schema_version: "1.0.0"
  
  # Storage strategy
  storage:
    metadata_store:
      type: "document_database"
      implementation: "MongoDB"
      collections:
        - "static_data_metadata"
        - "dynamic_data_metadata"
        - "derived_data_metadata"
        - "visualization_metadata"
        - "ml_features_metadata"
        - "simulation_run_metadata"
    
    file_storage:
      type: "hierarchical_filesystem"
      structure: "/simulation_data/{data_type}/{category}/{data_id}/"
      backup_strategy: "incremental_daily"
      retention_policy: "7_years"
    
    search_index:
      type: "elasticsearch"
      indices:
        - "full_text_search"
        - "temporal_queries"
        - "relationship_graph"
  
  # Access patterns
  access_patterns:
    read_operations:
      - pattern: "single_metadata_lookup"
        frequency: "high"
        optimization: "primary_key_index"
      
      - pattern: "relationship_traversal"
        frequency: "medium"
        optimization: "graph_index"
      
      - pattern: "full_text_search"
        frequency: "low"
        optimization: "inverted_index"
    
    write_operations:
      - pattern: "metadata_creation"
        frequency: "medium"
        optimization: "batch_insertion"
      
      - pattern: "metadata_update"
        frequency: "low"
        optimization: "versioned_updates"
  
  # Performance requirements
  performance:
    read_latency_ms: 100
    write_latency_ms: 500
    search_latency_ms: 1000
    concurrent_users: 50
    data_volume_gb: 1000
```

## 10. Usage Examples and Best Practices

### 10.1 Common Usage Patterns

```bash
# Example 1: Creating metadata for new simulation run
python create_metadata.py \
  --type simulation_run \
  --name "eagle_west_sensitivity_case_001" \
  --description "Sensitivity analysis for permeability multiplier" \
  --creator "Dr. Ahmed Hassan" \
  --input-data grid_001,rock_001,wells_001 \
  --output-dir /simulation_data/runs/sensitivity_001/

# Example 2: Searching for related datasets
python search_metadata.py \
  --query "eagle west pressure" \
  --data-type dynamic_solution \
  --created-after 2024-01-01 \
  --quality-status passed

# Example 3: Validating metadata consistency
python validate_metadata.py \
  --data-id solution_001 \
  --check-dependencies \
  --verify-checksums \
  --validate-relationships

# Example 4: Generating metadata report
python generate_report.py \
  --project eagle_west_field_2024 \
  --include-lineage \
  --format html \
  --output eagle_west_metadata_report.html
```

### 10.2 Best Practices

1. **Consistent Naming Conventions**
   - Use descriptive, hierarchical names
   - Include project/field identifier
   - Use version numbers consistently
   - Follow established patterns

2. **Comprehensive Documentation**
   - Always include meaningful descriptions
   - Document assumptions and limitations
   - Record data sources and methods
   - Maintain change logs

3. **Quality Assurance**
   - Implement automated validation
   - Require peer review for critical data
   - Maintain QA flag consistency
   - Regular metadata audits

4. **Relationship Management**
   - Document all dependencies
   - Maintain bidirectional relationships
   - Regular relationship validation
   - Clear dependency versioning

5. **Search Optimization**
   - Use consistent tagging strategies
   - Include relevant keywords
   - Maintain search indices
   - Regular index optimization

This comprehensive metadata specification provides a robust framework for managing all simulation data with full traceability, quality assurance, and searchability. The YAML schemas ensure consistency while supporting the diverse needs of reservoir simulation workflows.