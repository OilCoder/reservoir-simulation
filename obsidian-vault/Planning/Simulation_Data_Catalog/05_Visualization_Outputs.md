# Visualization Outputs Catalog

## Overview
This document catalogs all possible visualization outputs from the MRST Eagle West Field simulation system, organized by category with detailed specifications for each visualization type.

## 1. 3D Reservoir Maps

### Pressure Maps
- **Generated Files**: `pressure_3d_YYYY-MM-DD_HHMMSS.png`, `pressure_3d_YYYY-MM-DD_HHMMSS.fig`
- **Format**: PNG (static), FIG (MATLAB), optional PDF export
- **Resolution**: 1920x1080 (HD), 3840x2160 (4K) for publications
- **Quality Settings**: 300 DPI for print, 72 DPI for web
- **Generation Frequency**: Every timestep, monthly snapshots, milestone reports
- **Storage Location**: `/outputs/visualizations/3d_maps/pressure/`
- **Metadata**: Timestep, units (psi/bar), colorbar range, grid dimensions
- **Dashboard Usage**: Featured on main reservoir overview page

### Saturation Maps (Oil, Water, Gas)
- **Generated Files**: `saturation_oil_3d_YYYY-MM-DD_HHMMSS.png`, similar for water/gas
- **Format**: PNG, FIG, optional GIF for animations
- **Resolution**: 1920x1080 standard, 2560x1440 for detailed analysis
- **Quality Settings**: 300 DPI publication, 150 DPI standard
- **Generation Frequency**: Monthly, quarterly milestones, end-of-simulation
- **Storage Location**: `/outputs/visualizations/3d_maps/saturations/`
- **Metadata**: Phase type, saturation range (0-1), timestep, well locations
- **Dashboard Usage**: Phase distribution monitoring, sweep efficiency analysis

### Reservoir Properties (Porosity, Permeability)
- **Generated Files**: `porosity_3d.png`, `permeability_3d_[direction].png`
- **Format**: PNG, FIG, EPS for vector graphics
- **Resolution**: 2560x1440 for property detail
- **Quality Settings**: 300 DPI minimum for geological features
- **Generation Frequency**: Once per simulation setup, updated if grid modified
- **Storage Location**: `/outputs/visualizations/3d_maps/properties/`
- **Metadata**: Property units, statistical summaries, grid cell count
- **Dashboard Usage**: Static reference maps, geological characterization

## 2. 2D Cross-sections

### I-J Grid Slices
- **Generated Files**: `slice_ij_layer[N]_YYYY-MM-DD_HHMMSS.png`
- **Format**: PNG, SVG for scalable graphics
- **Resolution**: 1600x1200, aspect ratio preserved for grid geometry
- **Quality Settings**: 200 DPI standard, 300 DPI for reports
- **Generation Frequency**: Every 10 timesteps, milestone reports
- **Storage Location**: `/outputs/visualizations/2d_slices/layers/`
- **Metadata**: Layer number, depth (ft/m), property displayed
- **Dashboard Usage**: Layer-by-layer analysis, vertical sweep monitoring

### Well Cross-sections
- **Generated Files**: `well_xsection_[WellName]_YYYY-MM-DD_HHMMSS.png`
- **Format**: PNG, PDF for technical reports
- **Resolution**: 1400x1000, elongated for well trajectory
- **Quality Settings**: 250 DPI, enhanced contrast for small features
- **Generation Frequency**: Monthly per well, completion events
- **Storage Location**: `/outputs/visualizations/2d_slices/wells/`
- **Metadata**: Well name, MD range, perforation intervals
- **Dashboard Usage**: Individual well performance analysis

### Geological Cross-sections
- **Generated Files**: `geocross_[orientation]_[position].png`
- **Format**: PNG, PDF, EPS for publications
- **Resolution**: 2048x1536, high detail for facies
- **Quality Settings**: 300 DPI minimum, enhanced color depth
- **Generation Frequency**: Static (geology), updated with dynamic properties
- **Storage Location**: `/outputs/visualizations/2d_slices/geology/`
- **Metadata**: Orientation (NS/EW), coordinate position, facies legend
- **Dashboard Usage**: Geological context, heterogeneity visualization

## 3. Time Series Plots

### Production Curves
- **Generated Files**: `production_timeseries_YYYY-MM-DD.png`, `_[WellName].png`
- **Format**: PNG, SVG for web, PDF for reports
- **Resolution**: 1600x900, wide format for time axis
- **Quality Settings**: 150 DPI web, 300 DPI print
- **Generation Frequency**: Weekly updates, end-of-month reports
- **Storage Location**: `/outputs/visualizations/timeseries/production/`
- **Metadata**: Units (bbl/d, Mscf/d), forecast vs actual, confidence intervals
- **Dashboard Usage**: Primary KPI monitoring, trend analysis

### Injection Curves
- **Generated Files**: `injection_timeseries_YYYY-MM-DD.png`
- **Format**: PNG, interactive HTML for web dashboards
- **Resolution**: 1600x900, consistent with production plots
- **Quality Settings**: 150 DPI standard
- **Generation Frequency**: Weekly, synchronized with production
- **Storage Location**: `/outputs/visualizations/timeseries/injection/`
- **Metadata**: Injection rates, pressures, cumulative volumes
- **Dashboard Usage**: EOR monitoring, voidage replacement tracking

### Pressure Evolution
- **Generated Files**: `pressure_evolution_[Location]_YYYY-MM-DD.png`
- **Format**: PNG, interactive Plotly HTML
- **Resolution**: 1400x800, focused on pressure trends
- **Quality Settings**: 200 DPI, clear axis labeling
- **Generation Frequency**: Daily for key wells, weekly field average
- **Storage Location**: `/outputs/visualizations/timeseries/pressure/`
- **Metadata**: Pressure units, measurement locations, BHP vs tubing head
- **Dashboard Usage**: Reservoir energy monitoring, interference analysis

## 4. Well Performance Plots

### Rate Transient Analysis
- **Generated Files**: `rta_[WellName]_YYYY-MM-DD.png`
- **Format**: PNG, PDF for technical analysis
- **Resolution**: 1200x900, log-log scale clarity
- **Quality Settings**: 250 DPI, enhanced line weights
- **Generation Frequency**: Monthly per well, post-workover
- **Storage Location**: `/outputs/visualizations/well_performance/rta/`
- **Metadata**: Analysis type, derivative plots, interpretation parameters
- **Dashboard Usage**: Well diagnostic analysis, EUR estimation

### Water Cut Evolution
- **Generated Files**: `watercut_[WellName]_YYYY-MM-DD.png`
- **Format**: PNG, SVG for presentations
- **Resolution**: 1400x800, clear trend visualization
- **Quality Settings**: 200 DPI, color-blind friendly palette
- **Generation Frequency**: Monthly, water breakthrough events
- **Storage Location**: `/outputs/visualizations/well_performance/watercut/`
- **Metadata**: Water cut percentage, breakthrough timing, forecast models
- **Dashboard Usage**: Water management, completion effectiveness

### PI Evolution and Skin Analysis
- **Generated Files**: `pi_evolution_[WellName]_YYYY-MM-DD.png`
- **Format**: PNG, technical PDF reports
- **Resolution**: 1300x900, dual-axis clarity
- **Quality Settings**: 250 DPI, professional formatting
- **Generation Frequency**: Quarterly, post-stimulation
- **Storage Location**: `/outputs/visualizations/well_performance/productivity/`
- **Metadata**: PI units, skin values, completion details
- **Dashboard Usage**: Well completion analysis, workover planning

## 5. Diagnostic Plots

### Material Balance Plots
- **Generated Files**: `mbal_[Region]_YYYY-MM-DD.png`
- **Format**: PNG, high-resolution PDF for technical review
- **Resolution**: 1400x1000, detailed axis labeling
- **Quality Settings**: 300 DPI, clear regression lines
- **Generation Frequency**: Quarterly, major milestone reports
- **Storage Location**: `/outputs/visualizations/diagnostics/material_balance/`
- **Metadata**: Drive mechanisms, OOIP estimates, aquifer parameters
- **Dashboard Usage**: Reservoir engineering analysis, reserves assessment

### P/Z Plots (Gas Reservoirs)
- **Generated Files**: `pz_plot_[Zone]_YYYY-MM-DD.png`
- **Format**: PNG, vector EPS for publications
- **Resolution**: 1200x900, logarithmic scale precision
- **Quality Settings**: 300 DPI, enhanced point markers
- **Generation Frequency**: Monthly for gas zones
- **Storage Location**: `/outputs/visualizations/diagnostics/pz_analysis/`
- **Metadata**: Z-factors, abandonment pressure, OGIP estimates
- **Dashboard Usage**: Gas reserves monitoring, depletion tracking

### Decline Curve Analysis
- **Generated Files**: `dca_[WellName]_YYYY-MM-DD.png`
- **Format**: PNG, interactive HTML with zoom
- **Resolution**: 1500x900, semi-log clarity
- **Quality Settings**: 250 DPI, multiple forecast scenarios
- **Generation Frequency**: Monthly per well, EUR updates
- **Storage Location**: `/outputs/visualizations/diagnostics/decline_curves/`
- **Metadata**: Decline parameters, EUR estimates, economic limits
- **Dashboard Usage**: Production forecasting, well economics

## 6. Animation/Movies

### Saturation Front Movement
- **Generated Files**: `saturation_animation_YYYY-MM-DD.mp4`, `.gif`
- **Format**: MP4 (high quality), GIF (web), AVI (technical)
- **Resolution**: 1920x1080 (MP4), 800x600 (GIF)
- **Quality Settings**: 30 fps, H.264 encoding, bitrate 5-10 Mbps
- **Generation Frequency**: End of simulation, quarterly milestones
- **Storage Location**: `/outputs/visualizations/animations/saturations/`
- **Metadata**: Frame rate, duration, timestep intervals, colorbar info
- **Dashboard Usage**: Executive presentations, technical reviews

### Pressure Evolution Movies
- **Generated Files**: `pressure_evolution_YYYY-MM-DD.mp4`
- **Format**: MP4, WebM for web players
- **Resolution**: 1920x1080, 4K for special presentations
- **Quality Settings**: 24-30 fps, high bitrate for smooth transitions
- **Generation Frequency**: Major milestones, EOR implementation
- **Storage Location**: `/outputs/visualizations/animations/pressure/`
- **Metadata**: Pressure ranges, well events timeline, simulation period
- **Dashboard Usage**: Reservoir behavior demonstration, training materials

### Well Drilling Sequence
- **Generated Files**: `drilling_sequence_YYYY-MM-DD.mp4`
- **Format**: MP4, annotated versions with callouts
- **Resolution**: 1920x1080, optimized for projection
- **Quality Settings**: 30 fps, clear well symbols and labels
- **Generation Frequency**: Development planning updates
- **Storage Location**: `/outputs/visualizations/animations/development/`
- **Metadata**: Well sequence, drilling dates, completion types
- **Dashboard Usage**: Development planning presentations, investor updates

## 7. Statistical Plots

### Property Histograms
- **Generated Files**: `histogram_[Property]_YYYY-MM-DD.png`
- **Format**: PNG, SVG for scalable graphics
- **Resolution**: 1200x800, clear bin definitions
- **Quality Settings**: 200 DPI, statistical overlays
- **Generation Frequency**: Static for properties, monthly for dynamic variables
- **Storage Location**: `/outputs/visualizations/statistics/histograms/`
- **Metadata**: Statistical moments, bin counts, distribution fits
- **Dashboard Usage**: Uncertainty quantification, property characterization

### Correlation Matrices
- **Generated Files**: `correlation_matrix_YYYY-MM-DD.png`
- **Format**: PNG, high-resolution for coefficient readability
- **Resolution**: 1400x1400, square format for matrix
- **Quality Settings**: 250 DPI, heat map color scheme
- **Generation Frequency**: Quarterly analysis, sensitivity studies
- **Storage Location**: `/outputs/visualizations/statistics/correlations/`
- **Metadata**: Variable lists, correlation coefficients, significance levels
- **Dashboard Usage**: Parameter sensitivity analysis, model validation

### Scatter Plot Matrices
- **Generated Files**: `scatterplot_matrix_YYYY-MM-DD.png`
- **Format**: PNG, interactive HTML versions
- **Resolution**: 1600x1600, multiple subplot clarity
- **Quality Settings**: 200 DPI, point transparency for density
- **Generation Frequency**: Ad-hoc analysis, uncertainty studies
- **Storage Location**: `/outputs/visualizations/statistics/scatter_plots/`
- **Metadata**: Variable pairs, regression fits, outlier identification
- **Dashboard Usage**: Data quality assessment, relationship exploration

## 8. Dashboard Elements

### KPI Gauges
- **Generated Files**: `gauge_[KPI_name]_YYYY-MM-DD.png`, `.svg`
- **Format**: SVG (scalable), PNG for static embedding
- **Resolution**: 400x400, circular gauge format
- **Quality Settings**: Vector-based, crisp at all scales
- **Generation Frequency**: Real-time updates, hourly refresh
- **Storage Location**: `/outputs/visualizations/dashboard/gauges/`
- **Metadata**: Current value, target ranges, alert thresholds
- **Dashboard Usage**: Main dashboard KPI display, mobile views
- **Size Estimates**: 50-200 KB per SVG, 100-300 KB per PNG

### Status Indicators
- **Generated Files**: `indicator_[System]_YYYY-MM-DD.png`
- **Format**: PNG, SVG icons, LED-style graphics
- **Resolution**: 100x100, 200x200 for high-DPI displays
- **Quality Settings**: Sharp edges, clear color states
- **Generation Frequency**: Real-time, status change triggered
- **Storage Location**: `/outputs/visualizations/dashboard/indicators/`
- **Metadata**: Status levels, color coding scheme, update timestamps
- **Dashboard Usage**: System health monitoring, alert visualization
- **Size Estimates**: 10-50 KB per PNG

### Summary Cards
- **Generated Files**: `summary_card_[Topic]_YYYY-MM-DD.png`
- **Format**: PNG, HTML cards with embedded graphics
- **Resolution**: 600x400, card-like aspect ratio
- **Quality Settings**: 150 DPI, readable typography
- **Generation Frequency**: Daily summaries, report periods
- **Storage Location**: `/outputs/visualizations/dashboard/summary_cards/`
- **Metadata**: Summary statistics, trend indicators, comparison periods
- **Dashboard Usage**: Executive summaries, mobile dashboard tiles
- **Size Estimates**: 200-500 KB per PNG

### Progress Bars and Meters
- **Generated Files**: `progress_[Metric]_YYYY-MM-DD.svg`
- **Format**: SVG (animated), PNG snapshots
- **Resolution**: 800x100, horizontal bar format
- **Quality Settings**: Vector-based, smooth gradients
- **Generation Frequency**: Daily updates, milestone achievements
- **Storage Location**: `/outputs/visualizations/dashboard/progress/`
- **Metadata**: Completion percentage, milestone dates, target values
- **Dashboard Usage**: Project tracking, performance against targets
- **Size Estimates**: 20-100 KB per SVG

## Storage and Organization

### Directory Structure
```
/outputs/visualizations/
├── 3d_maps/
│   ├── pressure/
│   ├── saturations/
│   └── properties/
├── 2d_slices/
│   ├── layers/
│   ├── wells/
│   └── geology/
├── timeseries/
│   ├── production/
│   ├── injection/
│   └── pressure/
├── well_performance/
│   ├── rta/
│   ├── watercut/
│   └── productivity/
├── diagnostics/
│   ├── material_balance/
│   ├── pz_analysis/
│   └── decline_curves/
├── animations/
│   ├── saturations/
│   ├── pressure/
│   └── development/
├── statistics/
│   ├── histograms/
│   ├── correlations/
│   └── scatter_plots/
└── dashboard/
    ├── gauges/
    ├── indicators/
    ├── summary_cards/
    └── progress/
```

### Storage Organization
- **Daily Operations**: Variable based on generation frequency and quality settings
- **Monthly Archives**: Aggregated monthly visualization sets
- **Full Simulation**: Complete visualization catalog for project duration
- **Compressed Archives**: Optimized storage using PNG optimization

### Metadata Standards
- **Timestamp**: ISO 8601 format (YYYY-MM-DDTHH:mm:ss)
- **Units**: Consistent field units or SI with explicit notation
- **Version Control**: Simulation run ID, git commit hash
- **Quality Tags**: Resolution class, intended usage, approval status
- **Access Control**: Public, internal, confidential classification

## Performance Considerations

### Generation Time Estimates
- **Simple 2D Plots**: 1-5 seconds
- **3D Reservoir Maps**: 10-60 seconds
- **Animations**: 5-30 minutes
- **Statistical Analysis**: 2-10 minutes
- **Dashboard Updates**: 30 seconds - 2 minutes

### Optimization Strategies
- **Parallel Generation**: Multi-core processing for independent plots
- **Caching**: Store intermediate results for incremental updates
- **Resolution Scaling**: Multiple versions for different use cases
- **Compression**: PNG optimization, video encoding settings
- **Selective Generation**: Only create requested visualizations

## Integration Points

### Dashboard Systems
- **Web Dashboards**: Real-time embedding via REST API
- **Mobile Apps**: Optimized resolution and file sizes
- **Executive Reports**: High-resolution, publication-ready formats
- **Technical Documentation**: Vector formats, detailed annotations

### External Tools
- **GIS Systems**: Georeferenced outputs with coordinate metadata
- **Presentation Software**: Standard formats with embedded metadata
- **Report Generators**: Template-compatible layouts and sizing
- **Archive Systems**: Compressed formats with index metadata