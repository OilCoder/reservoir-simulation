# 06 ML-Ready Features

## Overview

This document catalogs all data that has been pre-processed and structured specifically for machine learning applications in reservoir simulation. These features are ready for direct ingestion into ML pipelines without additional preprocessing steps.

## 1. Spatial Features

### 1.1 Cell Coordinates and Geometry

**Feature Engineering Methodology:**
- Extract 3D cell centroids (X, Y, Z) from grid geometry
- Convert to normalized coordinates relative to field boundaries
- Calculate cell volumes, areas, and aspect ratios
- Generate relative positioning features using distance calculation:
  $$d_{ij} = \sqrt{(x_i - x_j)^2 + (y_i - y_j)^2 + (z_i - z_j)^2}$$

**Input Data Dependencies:**
- Grid geometry (COORD, ZCORN)
- Field boundary definitions
- Structural framework data

**Dimensionality and Data Structure:**
- Shape: [Nx × Ny × Nz, 10] features per cell
- Features: [X_norm, Y_norm, Z_norm, volume, area_xy, area_xz, area_yz, aspect_ratio, boundary_dist, center_dist]
- Data type: Float32 arrays
- Storage: Compressed HDF5 format

**Normalization/Scaling Requirements:**
- Coordinates: Min-max normalized to [0, 1]
- Geometric properties: Log-normal scaling for volumes/areas
- Distances: StandardScaler normalization using:
  $$x_{norm} = \frac{x - \mu}{\sigma}$$

**ML Model Suitability:**
- Regression: Excellent for spatial interpolation tasks
- Classification: Good for facies prediction
- Forecasting: Moderate (static features)

**Update Frequency:** Static (model initialization only)

**Computational Requirements:**
- Memory: Scales with grid size
- Processing: <1 minute on single CPU core

**Storage Format:**
- `/ml_features/spatial/coordinates.h5` - Normalized 3D coordinates
- `/ml_features/spatial/geometry.h5` - Cell geometric properties  
- `/ml_features/spatial/distances.h5` - Distance-based features

### 1.2 Well Proximity Features

**Feature Engineering Methodology:**
- Calculate Euclidean distance to each well (producer/injector) using:
  $$d_{ij} = \sqrt{(x_i - x_j)^2 + (y_i - y_j)^2 + (z_i - z_j)^2}$$
- Compute minimum distance to any well
- Generate well density maps using Gaussian kernels
- Create directional features (bearing to nearest wells)

**Input Data Dependencies:**
- Well trajectories and completions
- Grid cell centers
- Well classifications (producer/injector/observation)

**Dimensionality and Data Structure:**
- Shape: [Nx × Ny × Nz, Nwells + 6] features per cell
- Features: [dist_to_well_i, min_dist_prod, min_dist_inj, well_density, bearing_nearest, elevation_diff]
- Data type: Float32 arrays

**Normalization/Scaling Requirements:**
- Distances: Log transformation + StandardScaler
- Bearings: Sine/cosine encoding for cyclical nature
- Density: Min-max normalization

**ML Model Suitability:**
- Regression: Excellent for pressure/saturation prediction
- Classification: Good for drainage area classification
- Forecasting: Moderate (static unless wells added)

**Update Frequency:** 
- Static features: Once per simulation
- Dynamic updates: When wells are added/modified

**Storage Format:**
- `/ml_features/spatial/well_distances.h5` - Distance to each well
- `/ml_features/spatial/well_proximity.h5` - Aggregated proximity features
- `/ml_features/spatial/well_density.h5` - Kernel density estimates

### 1.3 Fault Proximity Features

**Feature Engineering Methodology:**
- Calculate minimum distance to fault surfaces
- Generate fault density indicators
- Create transmissibility multiplier zones
- Extract fault strike/dip relative orientations

**Input Data Dependencies:**
- Fault surface definitions
- Transmissibility multipliers (MULTFLT)
- Grid cell centers

**Dimensionality and Data Structure:**
- Shape: [Nx × Ny × Nz, 8] features per cell
- Features: [min_fault_dist, fault_density, trans_mult_x, trans_mult_y, fault_strike_rel, fault_dip_rel, fault_zone_id, fault_impact]
- Data type: Float32 arrays

**ML Model Suitability:**
- Regression: Excellent for flow prediction
- Classification: Good for compartmentalization
- Forecasting: Static features

## 2. Temporal Features

### 2.1 Time-Series Lags

**Feature Engineering Methodology:**
- Create lagged versions of key variables (pressure, saturation)
- Multiple lag intervals: 1, 3, 6, 12 months
- Forward differences for trend capture
- Seasonal decomposition components

**Input Data Dependencies:**
- Time-series simulation outputs
- Pressure and saturation fields
- Production/injection rates

**Dimensionality and Data Structure:**
- Shape: [N_timesteps, Nx × Ny × Nz, N_vars × N_lags]
- Variables: [pressure, oil_sat, water_sat, gas_sat]
- Lags: [1, 3, 6, 12] time steps
- Total features: 16 per cell per timestep

**Normalization/Scaling Requirements:**
- Temporal standardization within each variable
- Lag features scaled consistently with current values
- Handle missing values at sequence starts

**ML Model Suitability:**
- Regression: Good for next-step prediction
- Classification: Moderate
- Forecasting: Excellent for LSTM/GRU models

**Update Frequency:** Each simulation timestep

**Computational Requirements:**
- Memory: Scales with grid size and timestep count
- Processing: ~5 minutes per timestep for lag computation

**Storage Format:**
- `/ml_features/temporal/lags/pressure_lags.h5`
- `/ml_features/temporal/lags/saturation_lags.h5`
- `/ml_features/temporal/lags/rate_lags.h5`
- `/ml_features/temporal/metadata.json` - Lag configuration

### 2.2 Moving Averages and Trends

**Feature Engineering Methodology:**
- Exponentially weighted moving averages (EWMA)
- Simple moving averages using:
  $$MA_n(t) = \frac{1}{n}\sum_{i=0}^{n-1} x(t-i)$$
- Linear trend coefficients over sliding windows
- Volatility measures (rolling standard deviation)

**Input Data Dependencies:**
- Time-series dynamic variables
- Configurable window sizes
- Trend detection parameters

**Dimensionality and Data Structure:**
- Shape: [N_timesteps, Nx × Ny × Nz, 12]
- Features: [ewma_7d, ewma_30d, sma_30d, sma_90d, trend_30d, trend_90d, volatility_30d, volatility_90d, acceleration, momentum, seasonal_component, residual]

**Normalization/Scaling Requirements:**
- Moving averages: Same scaling as original variables
- Trend coefficients: StandardScaler normalization
- Volatility: Log transformation + scaling

**ML Model Suitability:**
- Regression: Excellent for smooth prediction
- Classification: Good for regime detection
- Forecasting: Excellent for trend-following models

### 2.3 Temporal Indicators

**Feature Engineering Methodology:**
- Cyclical time encoding (day of year, month)
- Production phase indicators (primary, secondary, tertiary)
- Event flags (well completions, workovers, shutdowns)
- Time since last significant event

**Dimensionality and Data Structure:**
- Shape: [N_timesteps, 15] global temporal features
- Features: [day_sin, day_cos, month_sin, month_cos, year_norm, phase_primary, phase_secondary, phase_tertiary, event_well_new, event_workover, time_since_event, simulation_time_norm, timestep_delta, weekend_flag, season_spring/summer/fall/winter]

**ML Model Suitability:**
- All model types benefit from temporal context
- Critical for seasonality modeling

## 3. Physics-Based Features

### 3.1 Flow Velocity Features

**Feature Engineering Methodology:**
- Compute Darcy velocity vectors from pressure gradients using:
  $$\vec{v} = -\frac{k}{\mu} \nabla P$$
- Calculate velocity magnitude and direction
- Generate streamline-based features
- Compute flow convergence/divergence using gradient calculation:
  $$\nabla f = \left(\frac{\partial f}{\partial x}, \frac{\partial f}{\partial y}, \frac{\partial f}{\partial z}\right)$$

**Input Data Dependencies:**
- Pressure fields
- Permeability tensors
- Fluid viscosities
- Grid transmissibilities

**Dimensionality and Data Structure:**
- Shape: [N_timesteps, Nx × Ny × Nz, 8]
- Features: [vel_x, vel_y, vel_z, vel_magnitude, vel_direction_theta, vel_direction_phi, divergence, vorticity]

**Normalization/Scaling Requirements:**
- Velocities: Log transformation + StandardScaler
- Directions: Sine/cosine encoding
- Divergence: StandardScaler normalization

**ML Model Suitability:**
- Regression: Excellent for transport prediction
- Classification: Good for flow regime classification
- Forecasting: Good with proper temporal modeling

**Update Frequency:** Each simulation timestep

**Computational Requirements:**
- Memory: Scales with grid size and timestep count
- Processing: ~10 minutes per timestep for velocity computation

**Storage Format:**
- `/ml_features/physics/darcy_velocity.h5`
- `/ml_features/physics/flow_directions.h5`
- `/ml_features/physics/flow_diagnostics.h5`

### 3.2 Dimensionless Numbers

**Feature Engineering Methodology:**
- Calculate capillary number:
  $$N_{ca} = \frac{\mu v}{\sigma}$$
- Compute Reynolds number for flow regime:
  $$Re = \frac{\rho v L}{\mu}$$
- Generate Bond number for gravity effects
- Calculate Péclet number for transport

**Input Data Dependencies:**
- Fluid properties (viscosity, surface tension, density)
- Flow velocities
- Characteristic lengths
- Temperature and pressure conditions

**Dimensionality and Data Structure:**
- Shape: [N_timesteps, Nx × Ny × Nz, 6]
- Features: [capillary_number, reynolds_number, bond_number, peclet_number, mobility_ratio, gravity_number]

**Normalization/Scaling Requirements:**
- Log transformation for all dimensionless numbers
- StandardScaler normalization
- Handle extreme values with clipping

**ML Model Suitability:**
- Regression: Excellent for physics-informed predictions
- Classification: Good for flow regime identification
- Forecasting: Moderate (depends on rate changes)

### 3.3 Thermodynamic Features

**Feature Engineering Methodology:**
- Extract PVT properties at local conditions
- Calculate phase equilibrium indicators
- Generate compressibility features
- Compute thermal expansion coefficients

**Dimensionality and Data Structure:**
- Shape: [N_timesteps, Nx × Ny × Nz, 10]
- Features: [oil_fvf, gas_fvf, water_fvf, oil_viscosity, gas_viscosity, water_viscosity, oil_density, gas_density, water_density, compressibility]

## 4. Well Interaction Features

### 4.1 Interference Matrices

**Feature Engineering Methodology:**
- Calculate pressure interference coefficients between wells
- Generate rate-rate interference matrices
- Compute well connectivity metrics
- Create drainage area overlap indicators

**Input Data Dependencies:**
- Well locations and completions
- Pressure response data
- Rate allocation factors
- Reservoir connectivity maps

**Dimensionality and Data Structure:**
- Shape: [Nwells, Nwells] symmetric matrices
- Features: Multiple matrices for different interaction types
- Temporal dimension: [N_timesteps, Nwells, Nwells]

**Normalization/Scaling Requirements:**
- Interference coefficients: Standardized by well pair distance
- Connectivity: Min-max normalization to [0, 1]
- Temporal stability through smoothing

**ML Model Suitability:**
- Regression: Excellent for multi-well optimization
- Classification: Good for well interaction clustering
- Forecasting: Good for production allocation

**Update Frequency:** Monthly or quarterly

**Storage Format:**
- `/ml_features/well_interactions/pressure_interference.h5`
- `/ml_features/well_interactions/rate_interference.h5`
- `/ml_features/well_interactions/connectivity_matrix.h5`
- `/ml_features/well_interactions/drainage_overlap.h5`

### 4.2 Well Performance Features

**Feature Engineering Methodology:**
- Calculate well productivity indices
- Generate decline curve parameters
- Compute water cut evolution features
- Extract well efficiency metrics

**Dimensionality and Data Structure:**
- Shape: [N_timesteps, Nwells, 12]
- Features: [productivity_index, decline_rate, water_cut, water_cut_derivative, gor, gor_trend, efficiency_factor, uptime_ratio, cumulative_oil, cumulative_water, cumulative_gas, days_on_production]

**ML Model Suitability:**
- Regression: Excellent for well performance prediction
- Classification: Good for well type classification
- Forecasting: Excellent for production forecasting

## 5. Geological Features

### 5.1 Facies Encoding

**Feature Engineering Methodology:**
- One-hot encoding for categorical facies
- Ordinal encoding for hierarchical facies
- Embeddings for high-cardinality facies
- Spatial facies transition probabilities

**Input Data Dependencies:**
- Facies models (discrete and continuous)
- Stratigraphic framework
- Depositional environment classifications

**Dimensionality and Data Structure:**
- Shape: [Nx × Ny × Nz, N_facies + 5]
- One-hot: Binary indicators for each facies type
- Additional: [facies_continuity, transition_prob, facies_thickness, facies_quality, vertical_order]

**Normalization/Scaling Requirements:**
- One-hot: No scaling required (binary)
- Transition probabilities: Already [0, 1] normalized
- Thickness/quality: Log transformation + scaling

**ML Model Suitability:**
- Regression: Good for property prediction
- Classification: Excellent for facies prediction
- Forecasting: Static features (model input)

**Update Frequency:** Static (geological model dependent)

**Storage Format:**
- `/ml_features/geology/facies_onehot.h5`
- `/ml_features/geology/facies_ordinal.h5`
- `/ml_features/geology/facies_embeddings.h5`
- `/ml_features/geology/facies_spatial.h5`

### 5.2 Stratigraphic Features

**Feature Engineering Methodology:**
- Extract layer/zone membership
- Calculate relative stratigraphic position
- Generate thickness and net-to-gross ratios
- Compute structural dip and azimuth

**Dimensionality and Data Structure:**
- Shape: [Nx × Ny × Nz, 8]
- Features: [layer_id, relative_position, thickness, net_to_gross, structural_dip, dip_azimuth, depth_structure, depth_stratigraphic]

**ML Model Suitability:**
- Excellent for all model types as fundamental geological context
- Critical for physics-informed neural networks

## 6. Production History Features

### 6.1 Cumulative Production Features

**Feature Engineering Methodology:**
- Calculate cumulative oil, gas, water production by well
- Generate field-level cumulative metrics
- Compute recovery factors and depletion ratios
- Create production efficiency indicators

**Input Data Dependencies:**
- Well production rates (oil, gas, water)
- Initial fluid volumes in place
- Time-series production data

**Dimensionality and Data Structure:**
- Well-level: [N_timesteps, Nwells, 9]
- Field-level: [N_timesteps, 6]
- Features: [cum_oil, cum_gas, cum_water, oil_recovery_factor, gas_recovery_factor, water_cut_cum, gor_cum, production_efficiency, economic_recovery]

**Normalization/Scaling Requirements:**
- Cumulative volumes: Log transformation + StandardScaler
- Recovery factors: Already normalized ratios [0, 1]
- Efficiency metrics: StandardScaler normalization

**ML Model Suitability:**
- Regression: Excellent for EUR prediction
- Classification: Good for well performance classification
- Forecasting: Excellent for production forecasting

**Update Frequency:** Each production report (monthly/daily)

**Storage Format:**
- `/ml_features/production/cumulative_well.h5`
- `/ml_features/production/cumulative_field.h5`
- `/ml_features/production/recovery_factors.h5`
- `/ml_features/production/production_metrics.h5`

### 6.2 Rate Evolution Features

**Feature Engineering Methodology:**
- Extract rate trends and derivatives
- Calculate rate ratios and normalized rates
- Generate peak rate and decline characteristics
- Compute rate volatility and stability metrics

**Dimensionality and Data Structure:**
- Shape: [N_timesteps, Nwells, 15]
- Features: [oil_rate, oil_rate_norm, oil_rate_trend, oil_rate_volatility, gas_rate, gas_rate_norm, water_rate, water_rate_norm, total_rate, rate_stability, peak_rate_ratio, decline_exponent, time_to_peak, time_since_peak, rate_acceleration]

**ML Model Suitability:**
- Forecasting: Excellent for rate prediction models
- Regression: Good for rate-dependent property prediction
- Classification: Good for production phase classification

### 6.3 Water Cut Evolution

**Feature Engineering Methodology:**
- Calculate water cut and its derivatives
- Generate water cut acceleration features
- Extract breakthrough timing features
- Compute water cut prediction indicators

**Dimensionality and Data Structure:**
- Shape: [N_timesteps, Nwells, 8]
- Features: [water_cut, water_cut_derivative, water_cut_acceleration, breakthrough_time, time_since_breakthrough, water_cut_trend, water_cut_volatility, water_cut_forecast]

## 7. Dimensionality Reduction Features

### 7.1 Principal Component Analysis (PCA)

**Feature Engineering Methodology:**
- Apply PCA to high-dimensional spatial fields using transformation:
  $$Y = XW$$
  where $W$ are eigenvectors of the covariance matrix
- Retain components explaining 95% variance
- Generate temporal PCA for dynamic variables
- Create combined spatio-temporal PCA

**Input Data Dependencies:**
- Pre-processed simulation variables
- Standardized feature matrices
- Temporal alignment of data

**Dimensionality and Data Structure:**
- Spatial PCA: [Nx × Ny × Nz] → [N_components_spatial]
- Temporal PCA: [N_timesteps] → [N_components_temporal]
- Combined: [N_timesteps, N_components_combined]
- Typical reduction: 1M cells → 50-200 components

**Normalization/Scaling Requirements:**
- Input standardization required before PCA
- Components are orthonormal (no additional scaling)
- Loadings preserved for interpretability

**ML Model Suitability:**
- Regression: Excellent for reduced-order modeling
- Classification: Good for pattern classification
- Forecasting: Excellent for low-dimensional dynamics

**Update Frequency:**
- Model fitting: Once per simulation case
- Transform: Each timestep for dynamic features

**Computational Requirements:**
- Memory: Scales with grid complexity and decomposition method
- Processing: ~30 minutes for initial decomposition
- Transform: <1 minute per timestep

**Storage Format:**
- `/ml_features/dimensionality_reduction/pca/spatial_components.h5` - Spatial PCA components
- `/ml_features/dimensionality_reduction/pca/temporal_components.h5` - Temporal PCA components
- `/ml_features/dimensionality_reduction/pca/combined_components.h5` - Spatio-temporal PCA
- `/ml_features/dimensionality_reduction/pca/explained_variance.h5` - Variance ratios
- `/ml_features/dimensionality_reduction/pca/loadings.h5` - Component loadings
- `/ml_features/dimensionality_reduction/pca/pca_config.json` - PCA parameters

### 7.2 Proper Orthogonal Decomposition (POD)

**Feature Engineering Methodology:**
- Decompose spatio-temporal fields into spatial modes and temporal coefficients
- Extract dominant flow patterns and their evolution
- Generate mode-based reconstruction features
- Compute modal energy and participation factors

**Input Data Dependencies:**
- Spatio-temporal simulation snapshots
- Pressure and saturation fields
- Velocity fields (optional)

**Dimensionality and Data Structure:**
- Spatial modes: [Nx × Ny × Nz, N_modes]
- Temporal coefficients: [N_timesteps, N_modes]
- Reconstruction features: [N_timesteps, N_modes + derived]
- Typical modes: 10-50 for 95% energy

**Normalization/Scaling Requirements:**
- Snapshot matrix mean-centering
- Optional energy normalization of modes
- Temporal coefficients: StandardScaler normalization

**ML Model Suitability:**
- Regression: Excellent for modal amplitude prediction
- Classification: Good for flow regime classification
- Forecasting: Excellent for reduced-order forecasting

**Storage Format:**
- `/ml_features/dimensionality_reduction/pod/spatial_modes.h5` - POD spatial modes
- `/ml_features/dimensionality_reduction/pod/temporal_coefficients.h5` - Modal time coefficients
- `/ml_features/dimensionality_reduction/pod/singular_values.h5` - Energy content
- `/ml_features/dimensionality_reduction/pod/reconstruction_error.h5` - Mode truncation error
- `/ml_features/dimensionality_reduction/pod/pod_config.json` - POD parameters

### 7.3 Autoencoder Latent Features

**Feature Engineering Methodology:**
- Train convolutional autoencoders on spatial fields
- Extract latent space representations
- Generate temporal autoencoders for time-series
- Create variational autoencoder features for uncertainty

**Input Data Dependencies:**
- Gridded simulation variables
- Time-series data for temporal autoencoders
- Training/validation/test splits

**Dimensionality and Data Structure:**
- Spatial latents: [N_timesteps, latent_dim_spatial]
- Temporal latents: [N_sequences, latent_dim_temporal]
- Combined latents: [N_timesteps, latent_dim_combined]
- Typical dimensions: 32-256 latent features

**Normalization/Scaling Requirements:**
- Input normalization as per training
- Latent features may need post-processing scaling
- Variational latents: standardized by design

**ML Model Suitability:**
- Regression: Excellent for complex pattern recognition
- Classification: Excellent for learned representations
- Forecasting: Good for non-linear dynamics

**Update Frequency:**
- Model training: Periodic retraining (quarterly/yearly)
- Feature extraction: Each timestep

**Computational Requirements:**
- Training: GPU recommended, hours to days
- Inference: CPU adequate, minutes per timestep
- Memory: Model and timestep dependent

**Storage Format:**
- `/ml_features/dimensionality_reduction/autoencoders/spatial_latents.h5` - Spatial autoencoder features
- `/ml_features/dimensionality_reduction/autoencoders/temporal_latents.h5` - Temporal autoencoder features
- `/ml_features/dimensionality_reduction/autoencoders/vae_latents.h5` - Variational autoencoder features
- `/ml_features/dimensionality_reduction/autoencoders/model_checkpoints/` - Trained model weights
- `/ml_features/dimensionality_reduction/autoencoders/autoencoder_config.json` - Model architectures

## Feature Integration and Access Patterns

### Unified Feature Store Structure

**Feature Store Organization:**
- `/ml_features/metadata/` - Feature registry, update schedules, and dependencies
- `/ml_features/spatial/` - Static spatial features
- `/ml_features/temporal/` - Time-varying features
- `/ml_features/physics/` - Physics-based features
- `/ml_features/well_interactions/` - Well-related features
- `/ml_features/geology/` - Geological features
- `/ml_features/production/` - Production history features
- `/ml_features/dimensionality_reduction/` - DR features
- `/ml_features/combined/` - Pre-joined feature sets

### Access Patterns

**Batch Processing:**
- Load entire feature sets for model training
- Optimized for sequential access patterns
- Compressed storage for large datasets

**Streaming Updates:**
- Incremental feature computation
- Real-time feature serving for online models
- Delta updates for changed features only

**Random Access:**
- Cell-specific feature queries
- Well-specific feature extraction
- Time-slice feature access

### Quality Assurance

**Data Validation:**
- Range checks for all numerical features
- Consistency checks across related features
- Missing value detection and handling
- Statistical distribution monitoring

**Feature Monitoring:**
- Drift detection for feature distributions
- Correlation stability monitoring
- Feature importance tracking
- Performance impact assessment

**Documentation:**
- Automated feature lineage tracking
- Metadata preservation through pipeline
- Version control for feature definitions
- Impact analysis for feature changes

## Computational Requirements Summary

| Feature Category | Memory (100k cells) | Processing Time | Update Frequency |
|-----------------|-------------------|-----------------|------------------|
| Spatial | Grid dependent | 5 minutes | Static |
| Temporal | Per timestep | 10 minutes | Each timestep |
| Physics | Per timestep | 15 minutes | Each timestep |
| Well Interactions | Well dependent | 20 minutes | Monthly |
| Geological | Grid dependent | 2 minutes | Static |
| Production | Well dependent | 1 minute | Daily/Monthly |
| PCA | Dataset dependent | 30 minutes | Once per case |
| POD | Dataset dependent | 45 minutes | Once per case |
| Autoencoders | Model dependent | Hours (training) | Quarterly |

**Recommended Hardware:**
- RAM: Minimum 32 GB, with higher capacity preferred for larger cases
- Storage: SSD recommended for feature access
- CPU: Multi-core for parallel feature computation
- GPU: Optional for autoencoder training