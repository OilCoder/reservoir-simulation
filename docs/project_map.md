# Reservoir Simulation Project Map

*Auto-generated on 2025-07-17 03:28:33*

## Overview

This document provides a completely dynamic map of the project structure. 
Everything is extracted automatically from actual code content, following DATA_GENERATION_POLICY.

**Project Statistics:**
- Total code files analyzed: 64
- Generated from: Live codebase scan
- No hardcoded values: All content extracted dynamically

## Project Tree Structure

```
reservoir-simulation/
├── dashboard/
│   ├── plots/
│   │   ├── dynamic_fields/
│   │   │   ├── __init__.py
│   │   │   ├── field_animation.py
│   │   │   ├── field_evolution.py
│   │   │   └── field_snapshots.py
│   │   ├── flow_velocity/
│   │   │   ├── __init__.py
│   │   │   ├── flow_evolution.py
│   │   │   └── velocity_fields.py
│   │   ├── initial_conditions/
│   │   │   ├── __init__.py
│   │   │   ├── pressure_map.py
│   │   │   └── saturation_map.py
│   │   ├── simulation_parameters/
│   │   │   ├── __init__.py
│   │   │   ├── reservoir_parameters.py
│   │   │   ├── simulation_setup.py
│   │   │   └── well_parameters.py
│   │   ├── static_properties/
│   │   │   ├── __init__.py
│   │   │   ├── permeability_map.py
│   │   │   ├── porosity_map.py
│   │   │   ├── property_histograms.py
│   │   │   └── rock_regions.py
│   │   ├── transect_profiles/
│   │   │   ├── __init__.py
│   │   │   ├── pressure_profiles.py
│   │   │   └── saturation_profiles.py
│   │   ├── well_production/
│   │   │   ├── __init__.py
│   │   │   ├── cumulative_production.py
│   │   │   ├── production_rates.py
│   │   │   └── well_performance.py
│   │   ├── __init__.py
│   │   └── plot_utils.py
│   ├── config_reader.py
│   ├── dashboard.py
│   ├── start_service.py
│   ├── status_service.py
│   ├── stop_service.py
│   ├── util_data_loader.py
│   ├── util_metrics.py
│   └── util_visualization.py
├── debug/
│   ├── dbg_config.m
│   ├── dbg_config_parsing.m
│   ├── dbg_fluid_config.m
│   └── debug_yaml_simple.m
├── docs/
│   └── generated_projects_map.py
├── mrst_simulation_scripts/
│   ├── s00_initialize_mrst.m
│   ├── s01_setup_field.m
│   ├── s02_define_fluid.m
│   ├── s03_define_rock_regions.m
│   ├── s04_create_schedule.m
│   ├── s05_run_simulation.m
│   ├── s06_export_dataset.m
│   ├── s07a_setup_components.m
│   ├── s07b_setup_state.m
│   ├── s08_run_workflow_steps.m
│   ├── s09_execute_simulation_loop.m
│   ├── s10_calculate_volumetric_data.m
│   ├── s11a_export_initial_conditions.m
│   ├── s11b_export_static_data.m
│   ├── s11c_export_dynamic_fields.m
│   ├── s11d_export_metadata.m
│   ├── s12_extract_snapshot.m
│   ├── s13_generate_completion_report.m
│   ├── s99_run_workflow.m
│   └── util_ensure_directories.m
├── test/
│   ├── test_01_sim_scripts_util_read_config.m
│   └── test_02_sim_scripts_setup_field.m
└── load_mrst.m
```

## Complete File Documentation

The following sections provide detailed documentation for each file, 
including all functions, classes, and their docstrings.


## PROJECT_ROOT/

### MATLAB/Octave Files (1 files)

#### `load_mrst.m`

**Description:** % Load MRST - MATLAB Reservoir Simulation Toolbox This function properly initializes MRST for use in simulation scripts

**Functions:**

**`load_mrst()`** *(line 1)*

% Load MRST - MATLAB Reservoir Simulation Toolbox This function properly initializes MRST for use in simulation scripts

---



## dashboard/

### Python Files (8 files)

#### `config_reader.py`

**Description:** Configuration Reader for Reservoir Simulation Parameters

This module reads and parses the reservoir_config.yaml file to extract 
simulation parameters for display in the dashboard.

**Functions:**

**`load_simulation_config(config_path)`** *(line 13)*

Load the reservoir simulation configuration from YAML file.

**Args:**
config_path: Path to the configuration file (optional)

**Returns:**
Dict containing all simulation parameters

---

**`get_grid_parameters(config)`** *(line 35)*

Extract grid parameters from configuration.

---

**`get_rock_parameters(config)`** *(line 50)*

Extract rock parameters from configuration.

---

**`get_fluid_parameters(config)`** *(line 66)*

Extract fluid parameters from configuration.

---

**`get_well_parameters(config)`** *(line 81)*

Extract well parameters from configuration.

---

**`get_simulation_parameters(config)`** *(line 124)*

Extract simulation parameters from configuration.

---

**`get_initial_conditions(config)`** *(line 138)*

Extract initial conditions from configuration.

---

**`get_geomechanics_parameters(config)`** *(line 147)*

Extract geomechanics parameters from configuration.

---

**`get_metadata(config)`** *(line 157)*

Extract metadata from configuration.

---


#### `dashboard.py`

**Description:** MRST Geomechanical Simulation Dashboard - Complete Workflow

Single file that handles:
1. MRST simulation execution (generates real data)
2. Interactive dashboard launch (visualizes results)

Usage:
    streamlit run dashboard.py

Or for command line launcher:
    python dashboard.py

**Functions:**

**`verify_simulation_data()`** *(line 73)*

Check which simulation data files are available.

---

**`get_data_status()`** *(line 96)*

Get summary of data availability.

---

**`load_simulation_config()`** *(line 116)*

Load simulation configuration from YAML file.

---

**`load_simulation_data()`** *(line 125)*

Load MRST simulation data with caching.

---

**`create_initial_pressure_map(pressure_data, layer_idx, title)`** *(line 149)*

Create pressure map for initial conditions.

---

**`create_initial_saturation_map(saturation_data, layer_idx, title)`** *(line 189)*

Create saturation map for initial conditions.

---

**`create_vertical_profile(data_3d, depth_data, title, location)`** *(line 230)*

Create vertical profile plot for 3D data.

---

**`create_rock_properties_map(property_data, title)`** *(line 273)*

Create rock property map.

---

**`show_data_status()`** *(line 308)*

Show data availability status.

---

**`show_dashboard()`** *(line 365)*

Show the main dashboard interface.

---

**`show_initial_conditions(data)`** *(line 402)*

Show initial conditions section.

---

**`show_rock_properties(data)`** *(line 480)*

Show rock properties section.

---

**`show_dynamic_fields(data)`** *(line 521)*

Show dynamic fields section.

---

**`show_well_performance(data)`** *(line 532)*

Show well performance section.

---

**`show_configuration(data)`** *(line 543)*

Show configuration section.

---

**`main()`** *(line 577)*

Main application logic.

---


#### `start_service.py`

**Description:** MRST Dashboard Background Service

Starts the dashboard as a background service that stays running.

**Functions:**

**`start_dashboard_service()`** *(line 15)*

Start dashboard as background service.

---

**`create_stop_script()`** *(line 66)*

Create stop service script.

---

**`create_status_script()`** *(line 114)*

Create status check script.

---


#### `status_service.py`

**Description:** Check MRST Dashboard Service Status

**Functions:**

**`check_dashboard_status()`** *(line 8)*

Check if dashboard service is running.

---


#### `stop_service.py`

**Description:** Stop MRST Dashboard Service

**Functions:**

**`stop_dashboard_service()`** *(line 8)*

Stop the dashboard service.

---


#### `util_data_loader.py`

**Description:** MRST Simulation Data Loader

Loads and processes MRST simulation data from MAT files following the
data generation policy. All data originates from MRST simulator authority
with proper traceability and no hard-coded values.

**Functions:**

**`__init__(self, data_root)`** *(line 30)*

Initialize data loader with base path.

**Args:**
data_root: Base path to simulation data directory

---

**`_define_file_structure(self)`** *(line 48)*

Define expected MRST export file structure.

**Returns:**
dict: Mapping of data types to file paths

---

**`check_data_availability(self)`** *(line 68)*

Check availability of MRST simulation data files.

**Returns:**
dict: Availability status for each data type

---

**`load_initial_conditions(self)`** *(line 82)*

Load initial reservoir conditions from MRST export.

**Returns:**
dict: Initial conditions data including pressure, saturation, porosity, permeability

---

**`load_static_data(self)`** *(line 125)*

Load static reservoir data from MRST export.

**Returns:**
dict: Static data including grid coordinates, rock regions, well locations

---

**`load_field_arrays(self)`** *(line 175)*

Load dynamic field arrays from MRST export.

**Returns:**
dict: Field arrays including pressure, saturation evolution over time

---

**`load_flow_data(self)`** *(line 231)*

Load flow velocity data from MRST export.

**Returns:**
dict: Flow data including velocity components and magnitude

---

**`load_well_data(self)`** *(line 263)*

Load well operational data from MRST export.

**Returns:**
dict: Well data including production rates, injection rates, pressures

---

**`load_cumulative_data(self)`** *(line 296)*

Load cumulative production data from MRST export.

**Returns:**
dict: Cumulative data including production, injection, recovery factor

---

**`load_metadata(self)`** *(line 331)*

Load simulation metadata from MRST export.

**Returns:**
dict: Metadata including simulation parameters, grid info, units

---

**`load_complete_dataset(self)`** *(line 366)*

Load complete MRST simulation dataset.

**Returns:**
dict: Complete dataset with all available data types

---

**Classes:**

**`MRSTDataLoader`** *(line 20)*

Loads MRST simulation data from the standardized export structure.

Follows data generation policy:
- No hard-coded values except physical constants
- All data originates from MRST simulator authority
- Proper traceability through metadata

---


#### `util_metrics.py`

**Description:** Performance Metrics Calculator

Calculates key performance indicators and metrics from MRST simulation data.
All calculations follow reservoir engineering principles and provide
product owner focused metrics for decision making.

**Functions:**

**`__init__(self, data)`** *(line 25)*

Initialize metrics calculator with simulation data.

**Args:**
data: Complete simulation dataset

---

**`calculate_key_performance_indicators(self)`** *(line 39)*

Calculate key performance indicators for product owner dashboard.

**Returns:**
dict: Key performance indicators including grid size, time, wells, recovery

---

**`calculate_recovery_efficiency(self)`** *(line 77)*

Calculate recovery efficiency metrics.

**Returns:**
dict: Recovery efficiency metrics including sweep and displacement efficiency

---

**`_calculate_sweep_efficiency(self)`** *(line 105)*

Calculate sweep efficiency from saturation data.

**Returns:**
float: Sweep efficiency as fraction of reservoir volume contacted

---

**`calculate_production_performance(self)`** *(line 132)*

Calculate production performance metrics.

**Returns:**
dict: Production performance metrics including rates and cumulative volumes

---

**`_calculate_decline_rate(self, production_rates)`** *(line 167)*

Calculate production decline rate.

**Args:**
production_rates: Time series of production rates

**Returns:**
float: Decline rate as fraction per unit time

---

**`calculate_pressure_performance(self)`** *(line 199)*

Calculate pressure performance metrics.

**Returns:**
dict: Pressure performance metrics including decline and maintenance

---

**`calculate_injection_efficiency(self)`** *(line 236)*

Calculate water injection efficiency metrics.

**Returns:**
dict: Injection efficiency metrics including voidage ratio and pattern efficiency

---

**`calculate_flow_performance(self)`** *(line 278)*

Calculate flow performance metrics.

**Returns:**
dict: Flow performance metrics including velocity and flow patterns

---

**`calculate_comprehensive_metrics(self)`** *(line 311)*

Calculate comprehensive performance metrics for product owner dashboard.

**Returns:**
dict: Comprehensive metrics including all performance indicators

---

**Classes:**

**`PerformanceMetrics`** *(line 17)*

Calculates key performance indicators for MRST simulation results.

Provides product owner focused metrics including recovery factors,
production performance, and reservoir efficiency indicators.

---


#### `util_visualization.py`

**Description:** Dashboard Visualization Utilities

Creates interactive visualizations for MRST simulation results using Plotly.
All visualizations follow product owner requirements for user-accessible
information display with proper styling and interactivity.

**Functions:**

**`__init__(self, data)`** *(line 28)*

Initialize visualizer with simulation data.

**Args:**
data: Complete simulation dataset

---

**`_define_color_schemes(self)`** *(line 40)*

Define color schemes for different data types.

**Returns:**
dict: Color scheme mapping for visualization consistency

---

**`create_pressure_heatmap(self, pressure_data, title)`** *(line 57)*

Create pressure distribution heatmap visualization.

**Args:**
pressure_data: 2D pressure array [psi]
title: Plot title

**Returns:**
plotly.graph_objects.Figure: Interactive heatmap

---

**`create_saturation_heatmap(self, saturation_data, title)`** *(line 86)*

Create water saturation distribution heatmap.

**Args:**
saturation_data: 2D saturation array [-]
title: Plot title

**Returns:**
plotly.graph_objects.Figure: Interactive heatmap

---

**`create_porosity_heatmap(self, porosity_data, title)`** *(line 115)*

Create porosity distribution heatmap.

**Args:**
porosity_data: 2D porosity array [-]
title: Plot title

**Returns:**
plotly.graph_objects.Figure: Interactive heatmap

---

**`create_permeability_heatmap(self, permeability_data, title)`** *(line 144)*

Create permeability distribution heatmap.

**Args:**
permeability_data: 2D permeability array [mD]
title: Plot title

**Returns:**
plotly.graph_objects.Figure: Interactive heatmap

---

**`create_velocity_heatmap(self, velocity_data, title)`** *(line 173)*

Create velocity magnitude heatmap.

**Args:**
velocity_data: 2D velocity magnitude array [m/day]
title: Plot title

**Returns:**
plotly.graph_objects.Figure: Interactive heatmap

---

**`create_property_histogram(self, property_data, title, xlabel)`** *(line 202)*

Create property distribution histogram.

**Args:**
property_data: Property data array
title: Plot title
xlabel: X-axis label

**Returns:**
plotly.graph_objects.Figure: Interactive histogram

---

**`create_production_rates_plot(self, well_data, title)`** *(line 229)*

Create oil production rates time series plot.

**Args:**
well_data: Well operational data
title: Plot title

**Returns:**
plotly.graph_objects.Figure: Interactive time series plot

---

**`create_injection_rates_plot(self, well_data, title)`** *(line 275)*

Create water injection rates time series plot.

**Args:**
well_data: Well operational data
title: Plot title

**Returns:**
plotly.graph_objects.Figure: Interactive time series plot

---

**`create_cumulative_production_plot(self, cumulative_data, title)`** *(line 323)*

Create cumulative production plot.

**Args:**
cumulative_data: Cumulative production data
title: Plot title

**Returns:**
plotly.graph_objects.Figure: Interactive time series plot

---

**`create_recovery_factor_plot(self, cumulative_data, title)`** *(line 372)*

Create recovery factor evolution plot.

**Args:**
cumulative_data: Cumulative production data
title: Plot title

**Returns:**
plotly.graph_objects.Figure: Interactive time series plot

---

**`create_pressure_evolution_plot(self, field_data, title)`** *(line 410)*

Create average pressure evolution plot.

**Args:**
field_data: Field arrays data
title: Plot title

**Returns:**
plotly.graph_objects.Figure: Interactive time series plot

---

**`create_velocity_evolution_plot(self, flow_data, title)`** *(line 452)*

Create average velocity magnitude evolution plot.

**Args:**
flow_data: Flow velocity data
title: Plot title

**Returns:**
plotly.graph_objects.Figure: Interactive time series plot

---

**Classes:**

**`DashboardVisualizer`** *(line 20)*

Creates interactive visualizations for MRST simulation dashboard.

Provides user-accessible visualization of reservoir simulation results
with appropriate styling, interactivity, and product owner focus.

---



## dashboard/plots/

### Python Files (2 files)

#### `__init__.py`

**Description:** MRST Simulation Dashboard Plot Modules

Hierarchical organization of plotting functions for reservoir simulation visualization.
Each category corresponds to specific analysis requirements:

1. Initial Conditions (t=0) - Baseline reservoir state
2. Static Properties - Time-invariant grid and rock properties  
3. Dynamic Fields - Time-dependent field evolution
4. Well Production - Production and injection analysis
5. Flow & Velocity - Flow field visualization
6. Transect Profiles - Cross-sectional analysis


#### `plot_utils.py`

**Description:** Utility functions for plot formatting and well locations.

**Functions:**

**`add_wells_to_plot(fig, wells_data, grid_x, grid_y)`** *(line 9)*

Add well locations to a plot.

**Args:**
fig: Plotly figure to add wells to
wells_data: Dictionary with well information
grid_x: Grid x-coordinates
grid_y: Grid y-coordinates

---

**`set_square_aspect_ratio(fig, grid_x, grid_y)`** *(line 97)*

Set square aspect ratio for grid plots.

**Args:**
fig: Plotly figure to modify
grid_x: Grid x-coordinates
grid_y: Grid y-coordinates

---

**`format_grid_plot(fig, title, colorbar_title, wells_data, grid_x, grid_y)`** *(line 135)*

Apply standard formatting to grid plots.

**Args:**
fig: Plotly figure to format
title: Plot title
colorbar_title: Title for colorbar
wells_data: Well information
grid_x: Grid x-coordinates
grid_y: Grid y-coordinates

---



## dashboard/plots/dynamic_fields/

### Python Files (4 files)

#### `__init__.py`

**Description:** Dynamic Fields Plots

Visualizes time-dependent field evolution during simulation.
Data source: dynamic/fields/field_arrays.mat, dynamic/fields/flow_data.mat


#### `field_animation.py`

**Description:** Dynamic Field Animation

Creates animated visualizations of field evolution over time.
Data: dynamic/fields/field_arrays.mat

**Functions:**

**`create_pressure_animation(pressure_data, time_days, grid_x, grid_y, title, colorscale, frame_duration)`** *(line 12)*

Create animated visualization of pressure field evolution.

**Args:**
pressure_data: Pressure field [n_timesteps, 20, 20] in psi
time_days: Time vector [n_timesteps] in days
grid_x: Grid x-coordinates [21×1] in meters (optional)
grid_y: Grid y-coordinates [21×1] in meters (optional)
title: Plot title
colorscale: Plotly colorscale name
frame_duration: Animation frame duration in milliseconds

**Returns:**
plotly.graph_objects.Figure: Interactive animated plot

---

**`create_saturation_animation(saturation_data, time_days, grid_x, grid_y, title, colorscale, frame_duration)`** *(line 192)*

Create animated visualization of water saturation field evolution.

**Args:**
saturation_data: Saturation field [n_timesteps, 20, 20] dimensionless
time_days: Time vector [n_timesteps] in days
grid_x: Grid x-coordinates [21×1] in meters (optional)
grid_y: Grid y-coordinates [21×1] in meters (optional)
title: Plot title
colorscale: Plotly colorscale name
frame_duration: Animation frame duration in milliseconds

**Returns:**
plotly.graph_objects.Figure: Interactive animated plot

---


#### `field_evolution.py`

**Description:** Dynamic Field Evolution

Creates time series plots of spatially-averaged field variables.
Data: dynamic/fields/field_arrays.mat + dynamic/fields/flow_data.mat

**Functions:**

**`create_average_pressure_evolution(pressure_data, time_days, title, line_color)`** *(line 12)*

Create time series plot of spatially-averaged pressure.

**Args:**
pressure_data: Pressure field [n_timesteps, 20, 20] in psi
time_days: Time vector [n_timesteps] in days
title: Plot title
line_color: Line color

**Returns:**
plotly.graph_objects.Figure: Interactive time series plot

---

**`create_average_saturation_evolution(saturation_data, time_days, title, line_color)`** *(line 86)*

Create time series plot of spatially-averaged water saturation.

**Args:**
saturation_data: Saturation field [n_timesteps, 20, 20] dimensionless
time_days: Time vector [n_timesteps] in days
title: Plot title
line_color: Line color

**Returns:**
plotly.graph_objects.Figure: Interactive time series plot

---

**`create_field_statistics_evolution(field_data, time_days, field_name, title)`** *(line 161)*

Create time series plot of field statistics (min, max, mean, std).

**Args:**
field_data: Field data [n_timesteps, 20, 20]
time_days: Time vector [n_timesteps] in days
field_name: Name of the field
title: Plot title (optional)

**Returns:**
plotly.graph_objects.Figure: Interactive statistics plot

---

**`create_dual_field_evolution(field1_data, field2_data, time_days, field1_name, field2_name, title)`** *(line 275)*

Create time series plot comparing two fields on different y-axes.

**Args:**
field1_data: First field data [n_timesteps, 20, 20]
field2_data: Second field data [n_timesteps, 20, 20]
time_days: Time vector [n_timesteps] in days
field1_name: Name of first field
field2_name: Name of second field
title: Plot title

**Returns:**
plotly.graph_objects.Figure: Interactive dual-axis plot

---


#### `field_snapshots.py`

**Description:** Dynamic Field Snapshots

Creates 2D maps of field variables at specific time steps.
Data: dynamic/fields/field_arrays.mat - pressure[t,:,:], sw[t,:,:]

**Functions:**

**`create_pressure_snapshot(pressure_data, timestep, time_days, grid_x, grid_y, title, colorscale, wells_data)`** *(line 16)*

Create 2D pressure map at specific timestep.

**Args:**
pressure_data: Pressure field [n_timesteps, 20, 20] in psi
timestep: Time step index to visualize
time_days: Time vector [n_timesteps] in days (optional)
grid_x: Grid x-coordinates [21×1] in meters (optional)
grid_y: Grid y-coordinates [21×1] in meters (optional)
title: Plot title (optional)
colorscale: Plotly colorscale name

**Returns:**
plotly.graph_objects.Figure: Interactive pressure snapshot

---

**`create_saturation_snapshot(saturation_data, timestep, time_days, grid_x, grid_y, title, colorscale, wells_data)`** *(line 88)*

Create 2D saturation map at specific timestep.

**Args:**
saturation_data: Saturation field [n_timesteps, 20, 20] dimensionless
timestep: Time step index to visualize
time_days: Time vector [n_timesteps] in days (optional)
grid_x: Grid x-coordinates [21×1] in meters (optional)
grid_y: Grid y-coordinates [21×1] in meters (optional)
title: Plot title (optional)
colorscale: Plotly colorscale name

**Returns:**
plotly.graph_objects.Figure: Interactive saturation snapshot

---

**`get_key_timesteps(time_days, n_snapshots)`** *(line 164)*

Get key timestep indices for snapshot visualization.

**Args:**
time_days: Time vector [n_timesteps] in days
n_snapshots: Number of snapshot timesteps to select

**Returns:**
list: List of timestep indices

---

**`create_snapshot_summary_stats(field_data, timestep, field_name)`** *(line 199)*

Calculate summary statistics for field snapshot.

**Args:**
field_data: Field data [n_timesteps, 20, 20]
timestep: Time step index
field_name: Name of the field

**Returns:**
dict: Statistical summary

---



## dashboard/plots/flow_velocity/

### Python Files (3 files)

#### `__init__.py`

**Description:** Flow and Velocity Plots

Visualizes flow fields and velocity distributions.
Data source: dynamic/fields/flow_data.mat


#### `flow_evolution.py`

**Description:** Flow Evolution Plots

Creates time series plots of flow field evolution.
Data: dynamic/fields/flow_data.mat

**Functions:**

**`create_velocity_evolution_plot(flow_data, title)`** *(line 12)*

Create velocity magnitude evolution plot.

**Args:**
flow_data: Flow data dictionary
title: Plot title

**Returns:**
plotly.graph_objects.Figure: Interactive velocity evolution plot

---


#### `velocity_fields.py`

**Description:** Velocity Field Visualization

Creates quiver plots and velocity magnitude maps.
Data: dynamic/fields/flow_data.mat - vx, vy, velocity_magnitude

**Functions:**

**`create_velocity_field_plot(flow_data, timestep, title, subsample)`** *(line 12)*

Create velocity field quiver plot.

**Args:**
flow_data: Flow data dictionary containing vx, vy
timestep: Time step index
title: Plot title
subsample: Subsampling factor for arrows

**Returns:**
plotly.graph_objects.Figure: Interactive velocity field plot

---

**`create_velocity_magnitude_plot(flow_data, timestep, title)`** *(line 70)*

Create velocity magnitude heatmap.

**Args:**
flow_data: Flow data dictionary containing velocity_magnitude
timestep: Time step index
title: Plot title

**Returns:**
plotly.graph_objects.Figure: Interactive velocity magnitude plot

---



## dashboard/plots/initial_conditions/

### Python Files (3 files)

#### `__init__.py`

**Description:** Initial Conditions Plots (t=0)

Visualizes baseline reservoir state at simulation start.
Data source: initial/initial_conditions.mat


#### `pressure_map.py`

**Description:** Initial Pressure Map Visualization

Creates 2D colormesh visualization of initial pressure distribution.
Data: initial/initial_conditions.mat - pressure [20×20] in psi

**Functions:**

**`create_initial_pressure_map(pressure_data, grid_x, grid_y, title, colorscale, wells_data, layer_idx)`** *(line 16)*

Create 2D pressure map visualization for initial conditions.

**Args:**
pressure_data: Pressure field [y,x] or [z,y,x] in psi
grid_x: Grid x-coordinates in meters (optional)
grid_y: Grid y-coordinates in meters (optional)
title: Plot title
colorscale: Plotly colorscale name
wells_data: Wells data dictionary
layer_idx: Layer index for 3D data (optional)

**Returns:**
plotly.graph_objects.Figure: Interactive pressure map

---

**`create_pressure_statistics_summary(pressure_data)`** *(line 85)*

Calculate pressure field statistics for initial conditions.

**Args:**
pressure_data: Pressure field [y,x] or [z,y,x] in psi

**Returns:**
dict: Statistical summary

---

**`create_vertical_pressure_profile(pressure_data, depth_data, well_location, title)`** *(line 107)*

Create vertical pressure profile for 3D data.

**Args:**
pressure_data: Pressure field [z, y, x] in psi
depth_data: Depth field [z, y, x] in ft (optional)
well_location: (i, j) location for profile (optional, uses center if None)
title: Plot title

**Returns:**
plotly.graph_objects.Figure: Vertical pressure profile

---


#### `saturation_map.py`

**Description:** Initial Saturation Map Visualization

Creates 2D colormesh visualization of initial water saturation distribution.
Data: initial/initial_conditions.mat - sw [20×20] dimensionless

**Functions:**

**`create_initial_saturation_map(saturation_data, grid_x, grid_y, title, colorscale, wells_data, layer_idx)`** *(line 17)*

Create 2D saturation map visualization for initial conditions.

**Args:**
saturation_data: Water saturation field [y,x] or [z,y,x] dimensionless
grid_x: Grid x-coordinates in meters (optional)
grid_y: Grid y-coordinates in meters (optional)
title: Plot title
colorscale: Plotly colorscale name
wells_data: Wells data dictionary
layer_idx: Layer index for 3D data (optional)

**Returns:**
plotly.graph_objects.Figure: Interactive saturation map

---

**`create_saturation_statistics_summary(saturation_data)`** *(line 90)*

Calculate saturation field statistics for initial conditions.

**Args:**
saturation_data: Water saturation field [y,x] or [z,y,x] dimensionless

**Returns:**
dict: Statistical summary

---

**`create_vertical_saturation_profile(saturation_data, depth_data, well_location, title)`** *(line 112)*

Create vertical saturation profile for 3D data.

**Args:**
saturation_data: Water saturation field [z, y, x] dimensionless
depth_data: Depth field [z, y, x] in ft (optional)
well_location: (i, j) location for profile (optional, uses center if None)
title: Plot title

**Returns:**
plotly.graph_objects.Figure: Vertical saturation profile

---



## dashboard/plots/simulation_parameters/

### Python Files (4 files)

#### `__init__.py`

**Description:** Simulation Parameters Module

This module provides visualization and display functions for simulation input parameters
designed for reservoir engineers to understand the project setup.


#### `reservoir_parameters.py`

**Description:** Reservoir Parameters Visualization

Creates organized displays of reservoir properties and geometry for reservoir engineers.

**Functions:**

**`create_reservoir_summary_table(config)`** *(line 19)*

Create a comprehensive reservoir summary table.

**Args:**
config: Configuration dictionary (optional, will load from file if None)

**Returns:**
pd.DataFrame: Formatted reservoir summary table

---

**`create_reservoir_geometry_display(config)`** *(line 132)*

Create a 3D visualization of reservoir geometry.

**Args:**
config: Configuration dictionary (optional, will load from file if None)

**Returns:**
go.Figure: 3D reservoir geometry plot

---

**`create_fluid_properties_table(config)`** *(line 233)*

Create a table with fluid properties used in the simulation.

**Args:**
config: Configuration dictionary (optional, will load from file if None)

**Returns:**
pd.DataFrame: Fluid properties table

---


#### `simulation_setup.py`

**Description:** Simulation Setup Visualization

Creates organized displays of simulation configuration and numerical parameters.

**Functions:**

**`create_simulation_timeline(config)`** *(line 25)*

Create a timeline visualization of the simulation.

**Args:**
config: Configuration dictionary (optional, will load from file if None)

**Returns:**
go.Figure: Simulation timeline plot

---

**`create_numerical_parameters_table(config)`** *(line 119)*

Create a table with numerical simulation parameters.

**Args:**
config: Configuration dictionary (optional, will load from file if None)

**Returns:**
pd.DataFrame: Numerical parameters table

---

**`create_solver_settings_display(config)`** *(line 240)*

Create a visualization of solver convergence settings.

**Args:**
config: Configuration dictionary (optional, will load from file if None)

**Returns:**
go.Figure: Solver settings visualization

---

**`create_project_metadata_table(config)`** *(line 335)*

Create a table with project metadata and information.

**Args:**
config: Configuration dictionary (optional, will load from file if None)

**Returns:**
pd.DataFrame: Project metadata table

---


#### `well_parameters.py`

**Description:** Well Parameters Visualization

Creates organized displays of well configuration and parameters for reservoir engineers.

**Functions:**

**`create_well_summary_table(config)`** *(line 19)*

Create a comprehensive well summary table.

**Args:**
config: Configuration dictionary (optional, will load from file if None)

**Returns:**
pd.DataFrame: Well summary table

---

**`create_well_locations_map(config)`** *(line 69)*

Create a 2D map showing well locations on the reservoir grid.

**Args:**
config: Configuration dictionary (optional, will load from file if None)

**Returns:**
go.Figure: 2D well locations map

---

**`create_well_schedule_table(config)`** *(line 232)*

Create a well schedule table showing operational parameters.

**Args:**
config: Configuration dictionary (optional, will load from file if None)

**Returns:**
pd.DataFrame: Well schedule table

---



## dashboard/plots/static_properties/

### Python Files (5 files)

#### `__init__.py`

**Description:** Static Properties Plots

Visualizes time-invariant reservoir properties.
Data sources: initial/initial_conditions.mat, static/static_data.mat


#### `permeability_map.py`

**Description:** Permeability Map Visualization

Creates 2D colormesh visualization of permeability distribution.
Data: initial/initial_conditions.mat - k [20×20] in mD

**Functions:**

**`create_permeability_map(permeability_data, grid_x, grid_y, title, colorscale, log_scale, wells_data)`** *(line 16)*

Create 2D permeability map visualization.

**Args:**
permeability_data: Permeability field [20×20] in mD
grid_x: Grid x-coordinates [21×1] in meters (optional)
grid_y: Grid y-coordinates [21×1] in meters (optional)
title: Plot title
colorscale: Plotly colorscale name
log_scale: Whether to use logarithmic scale

**Returns:**
plotly.graph_objects.Figure: Interactive permeability map

---

**`create_permeability_statistics_summary(permeability_data)`** *(line 86)*

Calculate permeability field statistics.

**Args:**
permeability_data: Permeability field [20×20] in mD

**Returns:**
dict: Statistical summary

---


#### `porosity_map.py`

**Description:** Porosity Map Visualization

Creates 2D colormesh visualization of porosity distribution.
Data: initial/initial_conditions.mat - phi [20×20] dimensionless

**Functions:**

**`create_porosity_map(porosity_data, grid_x, grid_y, title, colorscale, wells_data)`** *(line 16)*

Create 2D porosity map visualization.

**Args:**
porosity_data: Porosity field [20×20] dimensionless
grid_x: Grid x-coordinates [21×1] in meters (optional)
grid_y: Grid y-coordinates [21×1] in meters (optional)
title: Plot title
colorscale: Plotly colorscale name

**Returns:**
plotly.graph_objects.Figure: Interactive porosity map

---

**`create_porosity_statistics_summary(porosity_data)`** *(line 75)*

Calculate porosity field statistics.

**Args:**
porosity_data: Porosity field [20×20] dimensionless

**Returns:**
dict: Statistical summary

---


#### `property_histograms.py`

**Description:** Property Histograms and Box Plots

Creates histograms and box plots for reservoir property distributions.
Data: initial/initial_conditions.mat, static/static_data.mat

**Functions:**

**`create_porosity_histogram(porosity_data, title, bins, color)`** *(line 13)*

Create histogram of porosity distribution.

**Args:**
porosity_data: Porosity field [20×20] dimensionless
title: Plot title
bins: Number of histogram bins
color: Bar color

**Returns:**
plotly.graph_objects.Figure: Interactive histogram

---

**`create_permeability_boxplot(permeability_data, rock_id_data, title, rock_labels)`** *(line 87)*

Create box plot of permeability distribution grouped by rock type.

**Args:**
permeability_data: Permeability field [20×20] in mD
rock_id_data: Rock ID field [20×20] dimensionless
title: Plot title
rock_labels: Dictionary mapping rock IDs to names

**Returns:**
plotly.graph_objects.Figure: Interactive box plot

---

**`create_property_correlation_plot(porosity_data, permeability_data, rock_id_data, title, rock_labels)`** *(line 174)*

Create scatter plot showing porosity-permeability correlation.

**Args:**
porosity_data: Porosity field [20×20] dimensionless
permeability_data: Permeability field [20×20] in mD
rock_id_data: Rock ID field [20×20] for coloring (optional)
title: Plot title
rock_labels: Dictionary mapping rock IDs to names

**Returns:**
plotly.graph_objects.Figure: Interactive scatter plot

---


#### `rock_regions.py`

**Description:** Rock Regions Map Visualization

Creates 2D map of rock region identifiers with categorical coloring.
Data: static/static_data.mat - rock_id [20×20] dimensionless

**Functions:**

**`create_rock_regions_map(rock_id_data, grid_x, grid_y, title, rock_labels, wells_data)`** *(line 17)*

Create 2D rock regions map with categorical coloring.

**Args:**
rock_id_data: Rock ID field [20×20] dimensionless
grid_x: Grid x-coordinates [21×1] in meters (optional)
grid_y: Grid y-coordinates [21×1] in meters (optional)
title: Plot title
rock_labels: Dictionary mapping rock IDs to names

**Returns:**
plotly.graph_objects.Figure: Interactive rock regions map

---

**`create_rock_regions_statistics(rock_id_data)`** *(line 91)*

Calculate rock regions statistics.

**Args:**
rock_id_data: Rock ID field [20×20] dimensionless

**Returns:**
dict: Statistical summary

---



## dashboard/plots/transect_profiles/

### Python Files (3 files)

#### `__init__.py`

**Description:** Transect Profile Plots

Visualizes cross-sectional profiles through the reservoir.
Data source: dynamic/fields/field_arrays.mat


#### `pressure_profiles.py`

**Description:** Pressure Transect Profiles

Creates cross-sectional pressure profiles through the reservoir.
Data: dynamic/fields/field_arrays.mat - pressure

**Functions:**

**`create_pressure_transect_plot(pressure_data, time_days, transect_type, transect_index, title, key_timesteps)`** *(line 12)*

Create pressure profile along a transect line.

**Args:**
pressure_data: Pressure field [n_timesteps, 20, 20] in psi
time_days: Time vector [n_timesteps] in days
transect_type: "horizontal" or "vertical"
transect_index: Index of the transect line (0-19)
title: Plot title
key_timesteps: List of timestep indices to plot

**Returns:**
plotly.graph_objects.Figure: Interactive transect profile plot

---


#### `saturation_profiles.py`

**Description:** Saturation Transect Profiles

Creates cross-sectional saturation profiles through the reservoir.
Data: dynamic/fields/field_arrays.mat - sw

**Functions:**

**`create_saturation_transect_plot(saturation_data, time_days, transect_type, transect_index, title, key_timesteps)`** *(line 12)*

Create saturation profile along a transect line.

**Args:**
saturation_data: Saturation field [n_timesteps, 20, 20] dimensionless
time_days: Time vector [n_timesteps] in days
transect_type: "horizontal" or "vertical"
transect_index: Index of the transect line (0-19)
title: Plot title
key_timesteps: List of timestep indices to plot

**Returns:**
plotly.graph_objects.Figure: Interactive transect profile plot

---



## dashboard/plots/well_production/

### Python Files (4 files)

#### `__init__.py`

**Description:** Well Production Plots

Visualizes well production and injection performance.
Data sources: dynamic/wells/well_data.mat, dynamic/wells/cumulative_data.mat


#### `cumulative_production.py`

**Description:** Cumulative Production Plots

Creates plots for cumulative oil/water production and recovery factors.
Data: dynamic/wells/cumulative_data.mat

**Functions:**

**`create_cumulative_production_plot(cumulative_data, title, show_water)`** *(line 13)*

Create cumulative oil and water production plot.

**Args:**
cumulative_data: Cumulative data dictionary
title: Plot title
show_water: Whether to show water production

**Returns:**
plotly.graph_objects.Figure: Interactive cumulative production plot

---

**`create_recovery_factor_plot(cumulative_data, title)`** *(line 77)*

Create recovery factor evolution plot.

**Args:**
cumulative_data: Cumulative data dictionary
title: Plot title

**Returns:**
plotly.graph_objects.Figure: Interactive recovery factor plot

---


#### `production_rates.py`

**Description:** Well Production Rates

Creates time series plots of oil production and water injection rates.
Data: dynamic/wells/well_data.mat - qOs, qWs vs time_days

**Functions:**

**`create_oil_production_plot(well_data, title, well_colors)`** *(line 13)*

Create time series plot of oil production rates by well.

**Args:**
well_data: Well data dictionary containing time_days, well_names, qOs
title: Plot title
well_colors: Dictionary mapping well names to colors

**Returns:**
plotly.graph_objects.Figure: Interactive production rates plot

---

**`create_water_injection_plot(well_data, title, well_colors)`** *(line 108)*

Create time series plot of water injection rates by well.

**Args:**
well_data: Well data dictionary containing time_days, well_names, qWs
title: Plot title
well_colors: Dictionary mapping well names to colors

**Returns:**
plotly.graph_objects.Figure: Interactive injection rates plot

---

**`create_combined_rates_plot(well_data, title, production_wells, injection_wells)`** *(line 203)*

Create combined plot showing both production and injection rates.

**Args:**
well_data: Well data dictionary containing time_days, well_names, qOs, qWs
title: Plot title
production_wells: List of production well names
injection_wells: List of injection well names

**Returns:**
plotly.graph_objects.Figure: Interactive combined rates plot

---


#### `well_performance.py`

**Description:** Well Performance Analysis

Creates plots for water cut and well comparison analysis.
Data: dynamic/wells/cumulative_data.mat

**Functions:**

**`create_water_cut_plot(cumulative_data, title)`** *(line 12)*

Create water cut evolution plot.

**Args:**
cumulative_data: Cumulative data dictionary
title: Plot title

**Returns:**
plotly.graph_objects.Figure: Interactive water cut plot

---

**`create_well_comparison_plot(well_data, title)`** *(line 55)*

Create well performance comparison plot.

**Args:**
well_data: Well data dictionary
title: Plot title

**Returns:**
plotly.graph_objects.Figure: Interactive well comparison plot

---



## debug/

### MATLAB/Octave Files (4 files)

#### `dbg_config.m`


#### `dbg_config_parsing.m`


#### `dbg_fluid_config.m`


#### `debug_yaml_simple.m`



## docs/

### Python Files (1 files)

#### `generated_projects_map.py`

**Description:** Auto-generates project_map.md by scanning the entire Reservoir Simulation project.

Completely dynamic generation following DATA_GENERATION_POLICY:
- No hardcoded directory lists
- No hardcoded descriptions
- Everything extracted from actual code content
- Comprehensive function documentation

**Functions:**

**`parse_docstring(docstring)`** *(line 30)*

Parse docstring into sections (description, args, returns, etc.).

---

**`extract_python_info(filepath)`** *(line 64)*

Extract complete information from Python file.

---

**`extract_matlab_info(filepath)`** *(line 118)*

Extract complete information from MATLAB/Octave file.

---

**`scan_project_tree()`** *(line 187)*

Scan entire project tree and extract information.

---

**`generate_tree_structure(tree, prefix, is_last)`** *(line 243)*

Generate ASCII tree structure.

---

**`generate_directory_documentation(tree, path_parts)`** *(line 279)*

Generate detailed documentation for each directory.

---

**`generate_project_map()`** *(line 379)*

Generate complete project map.

---

**`count_files(tree)`** *(line 398)*

---



## mrst_simulation_scripts/

### MATLAB/Octave Files (20 files)

#### `s00_initialize_mrst.m`

**Description:** s00_initialize_mrst - Initialize MRST environment for Octave Initializes MRST core, loads required modules, and verifies functions are available for simulation execution. Args: None Returns: None (sets up MRST environment) Requires: MRST Step 1 – MRST Core Detection and Loading

**Functions:**

**`s00_initialize_mrst()`** *(line 1)*

s00_initialize_mrst - Initialize MRST environment for Octave Initializes MRST core, loads required modules, and verifies functions are available for simulation execution. Args: None Returns: None (sets up MRST environment) Requires: MRST Step 1 – MRST Core Detection and Loading

---


#### `s01_setup_field.m`

**Description:** s01_setup_field - Create MRST grid and rock properties from configuration Creates 20x20 cartesian grid with heterogeneous porosity and permeability based on reservoir configuration file. Uses MRST functions exclusively. Args: config_file: Path to YAML configuration file Returns: G: MRST grid structure rock: MRST rock structure with porosity and permeability fluid: Empty fluid structure (placeholder) Requires: MRST % ---- % Step 1 – Load configuration % ---- Substep 1.1 – Read configuration file ________________________

**Functions:**

**`s01_setup_field(config_file)`** *(line 1)*

s01_setup_field - Create MRST grid and rock properties from configuration Creates 20x20 cartesian grid with heterogeneous porosity and permeability based on reservoir configuration file. Uses MRST functions exclusively. Args: config_file: Path to YAML configuration file Returns: G: MRST grid structure rock: MRST rock structure with porosity and permeability fluid: Empty fluid structure (placeholder) Requires: MRST % ---- % Step 1 – Load configuration % ---- Substep 1.1 – Read configuration file ________________________

---


#### `s02_define_fluid.m`

**Description:** s02_define_fluid - Create MRST fluid structure from configuration Creates two-phase oil-water fluid with properties from configuration. Uses MRST initSimpleFluid function with realistic relative permeability curves. Args: config_file: Path to YAML configuration file Returns: fluid: MRST fluid structure with oil-water properties Requires: MRST % ---- % Step 1 – Load configuration % ---- Substep 1.1 – Read configuration file ________________________

**Functions:**

**`s02_define_fluid(config_file)`** *(line 1)*

s02_define_fluid - Create MRST fluid structure from configuration Creates two-phase oil-water fluid with properties from configuration. Uses MRST initSimpleFluid function with realistic relative permeability curves. Args: config_file: Path to YAML configuration file Returns: fluid: MRST fluid structure with oil-water properties Requires: MRST % ---- % Step 1 – Load configuration % ---- Substep 1.1 – Read configuration file ________________________

---

**`interpTable(x, x_data, y_data)`** *(line 136)*

---


#### `s03_define_rock_regions.m`

**Description:** s03_define_rock_regions - Generate rock.regions vector and assign lithology parameters Assigns geomechanical parameters (c_φ, n, k₀) by lithology to facilitate scaling to multiple rock types without rewriting setup_field.m Args: rock: MRST rock structure with existing porosity and permeability Returns: rock: Updated rock structure with regions and lithology parameters Requires: MRST % ---- % Step 1 – Rock region classification % ---- Substep 1.1 – Define porosity thresholds ____________________

**Functions:**

**`s03_define_rock_regions(rock)`** *(line 1)*

s03_define_rock_regions - Generate rock.regions vector and assign lithology parameters Assigns geomechanical parameters (c_φ, n, k₀) by lithology to facilitate scaling to multiple rock types without rewriting setup_field.m Args: rock: MRST rock structure with existing porosity and permeability Returns: rock: Updated rock structure with regions and lithology parameters Requires: MRST % ---- % Step 1 – Rock region classification % ---- Substep 1.1 – Define porosity thresholds ____________________

---


#### `s04_create_schedule.m`

**Description:** s04_create_schedule - Create MRST simulation schedule with wells and timesteps Creates schedule with producer and injector wells based on configuration. Uses MRST functions for well creation and schedule setup. Args: G: MRST grid structure rock: MRST rock structure fluid: MRST fluid structure config_file: Path to YAML configuration file Returns: schedule: MRST schedule structure with wells and timesteps Requires: MRST % ---- % Step 1 – Load configuration % ---- Substep 1.1 – Read configuration file ________________________

**Functions:**

**`s04_create_schedule(G, rock, fluid, config_file)`** *(line 1)*

s04_create_schedule - Create MRST simulation schedule with wells and timesteps Creates schedule with producer and injector wells based on configuration. Uses MRST functions for well creation and schedule setup. Args: G: MRST grid structure rock: MRST rock structure fluid: MRST fluid structure config_file: Path to YAML configuration file Returns: schedule: MRST schedule structure with wells and timesteps Requires: MRST % ---- % Step 1 – Load configuration % ---- Substep 1.1 – Read configuration file ________________________

---


#### `s05_run_simulation.m`

**Description:** s05_run_simulation - Execute main MRST simulation using simulateScheduleAD Execute main MRST simulation using simulateScheduleAD and save states in memory. Main orchestrator for flow-compaction simulation. Args: G: MRST grid structure rock: MRST rock structure fluid: MRST fluid structure schedule: MRST schedule structure Returns: states: Cell array of simulation states wellSols: Cell array of well solutions Requires: MRST % ---- % Step 1 – Simulation setup and validation % ----

**Functions:**

**`s05_run_simulation(G, rock, fluid, schedule)`** *(line 1)*

s05_run_simulation - Execute main MRST simulation using simulateScheduleAD Execute main MRST simulation using simulateScheduleAD and save states in memory. Main orchestrator for flow-compaction simulation. Args: G: MRST grid structure rock: MRST rock structure fluid: MRST fluid structure schedule: MRST schedule structure Returns: states: Cell array of simulation states wellSols: Cell array of well solutions Requires: MRST % ---- % Step 1 – Simulation setup and validation % ----

---


#### `s06_export_dataset.m`

**Description:** s06_export_dataset - Optimized MRST data export system with deduplication and organized structure Exports simulation results to: ../data/ with optimized folder organization Args: G: MRST grid structure rock: MRST rock structure fluid: MRST fluid structure schedule: MRST schedule structure states: Cell array of simulation states wellSols: Cell array of well solutions Returns: None (exports data to files) Requires: MRST % ---- % Step 1 – Setup and validation % ---- Substep 1.1 – Create optimized directory structure ___________

**Functions:**

**`s06_export_dataset(G, rock, fluid, schedule, states, wellSols)`** *(line 1)*

s06_export_dataset - Optimized MRST data export system with deduplication and organized structure Exports simulation results to: ../data/ with optimized folder organization Args: G: MRST grid structure rock: MRST rock structure fluid: MRST fluid structure schedule: MRST schedule structure states: Cell array of simulation states wellSols: Cell array of well solutions Returns: None (exports data to files) Requires: MRST % ---- % Step 1 – Setup and validation % ---- Substep 1.1 – Create optimized directory structure ___________

---


#### `s07a_setup_components.m`

**Description:** s07a_setup_components - Setup all simulation components Creates grid, rock, fluid, and schedule structures for MRST simulation workflow execution. Args: config_file: Path to YAML configuration file Returns: G: MRST grid structure rock: MRST rock structure with regions fluid: MRST fluid structure schedule: MRST schedule structure timing: Structure with timing information Requires: MRST

**Functions:**

**`s07a_setup_components(config_file)`** *(line 1)*

s07a_setup_components - Setup all simulation components Creates grid, rock, fluid, and schedule structures for MRST simulation workflow execution. Args: config_file: Path to YAML configuration file Returns: G: MRST grid structure rock: MRST rock structure with regions fluid: MRST fluid structure schedule: MRST schedule structure timing: Structure with timing information Requires: MRST

---


#### `s07b_setup_state.m`

**Description:** setup_simulation_state - Initialize simulation state and configuration Sets up initial pressure and saturation state for MRST simulation using hydrostatic equilibrium and capillary pressure equilibrium. Args: G: MRST grid structure rock: MRST rock structure Returns: state0: Initial simulation state config: Configuration structure Requires: MRST % ---- % Step 1 – Load configuration and set initial conditions % ----

**Functions:**

**`s07b_setup_state(G, rock)`** *(line 1)*

setup_simulation_state - Initialize simulation state and configuration Sets up initial pressure and saturation state for MRST simulation using hydrostatic equilibrium and capillary pressure equilibrium. Args: G: MRST grid structure rock: MRST rock structure Returns: state0: Initial simulation state config: Configuration structure Requires: MRST % ---- % Step 1 – Load configuration and set initial conditions % ----

---


#### `s08_run_workflow_steps.m`

**Description:** s08_run_workflow_steps - Execute simulation and export workflow Runs the MRST simulation and exports the results using the optimized data structure. Args: G: MRST grid structure rock: MRST rock structure fluid: MRST fluid structure schedule: MRST schedule structure Returns: states: Cell array of simulation states wellSols: Cell array of well solutions simulation_time: Time taken for simulation export_time: Time taken for data export Requires: MRST % ---- % Step 1 – Simulation execution % ----

**Functions:**

**`s08_run_workflow_steps(G, rock, fluid, schedule)`** *(line 1)*

s08_run_workflow_steps - Execute simulation and export workflow Runs the MRST simulation and exports the results using the optimized data structure. Args: G: MRST grid structure rock: MRST rock structure fluid: MRST fluid structure schedule: MRST schedule structure Returns: states: Cell array of simulation states wellSols: Cell array of well solutions simulation_time: Time taken for simulation export_time: Time taken for data export Requires: MRST % ---- % Step 1 – Simulation execution % ----

---


#### `s09_execute_simulation_loop.m`

**Description:** execute_simulation_loop - Run main simulation loop Executes the main MRST simulation loop with simplified incompressible flow and compaction effects. Args: G: MRST grid structure rock: MRST rock structure fluid: MRST fluid structure schedule: MRST schedule structure state0: Initial simulation state config: Configuration structure Returns: states: Cell array of simulation states wellSols: Cell array of well solutions sim_time: Simulation execution time Requires: MRST % ---- % Step 1 – Initialize simulation loop % ----

**Functions:**

**`s09_execute_simulation_loop(G, rock, fluid, schedule, state0, config)`** *(line 1)*

execute_simulation_loop - Run main simulation loop Executes the main MRST simulation loop with simplified incompressible flow and compaction effects. Args: G: MRST grid structure rock: MRST rock structure fluid: MRST fluid structure schedule: MRST schedule structure state0: Initial simulation state config: Configuration structure Returns: states: Cell array of simulation states wellSols: Cell array of well solutions sim_time: Simulation execution time Requires: MRST % ---- % Step 1 – Initialize simulation loop % ----

---


#### `s10_calculate_volumetric_data.m`

**Description:** calculate_volumetric_data - Calculate and export volumetric data Calculates cumulative production/injection, recovery factors, and flow velocities for dashboard visualization. Args: G: MRST grid structure rock: MRST rock structure fluid: MRST fluid structure schedule: MRST schedule structure states: Cell array of simulation states wellSols: Cell array of well solutions config: Configuration structure Returns: None (exports data to files) Requires: MRST % ---- % Step 1 – Calculate cumulative production/injection % ---- Initialize cumulative arrays

**Functions:**

**`s10_calculate_volumetric_data(G, rock, fluid, schedule, states, wellSols, config)`** *(line 1)*

calculate_volumetric_data - Calculate and export volumetric data Calculates cumulative production/injection, recovery factors, and flow velocities for dashboard visualization. Args: G: MRST grid structure rock: MRST rock structure fluid: MRST fluid structure schedule: MRST schedule structure states: Cell array of simulation states wellSols: Cell array of well solutions config: Configuration structure Returns: None (exports data to files) Requires: MRST % ---- % Step 1 – Calculate cumulative production/injection % ---- Initialize cumulative arrays

---


#### `s11a_export_initial_conditions.m`

**Description:** export_initial_conditions - Export initial reservoir conditions Exports initial pressure, saturation, porosity, and permeability to the optimized data structure. Args: G: MRST grid structure rock: MRST rock structure states: Cell array of simulation states base_dir: Base directory for data export Returns: None (exports data to file) Requires: MRST

**Functions:**

**`s11a_export_initial_conditions(G, rock, states, base_dir)`** *(line 1)*

export_initial_conditions - Export initial reservoir conditions Exports initial pressure, saturation, porosity, and permeability to the optimized data structure. Args: G: MRST grid structure rock: MRST rock structure states: Cell array of simulation states base_dir: Base directory for data export Returns: None (exports data to file) Requires: MRST

---


#### `s11b_export_static_data.m`

**Description:** export_static_data - Export static reservoir data Exports rock regions, grid geometry, and well locations to the optimized data structure. Args: G: MRST grid structure rock: MRST rock structure schedule: MRST schedule structure base_dir: Base directory for data export Returns: None (exports data to file) Requires: MRST

**Functions:**

**`s11b_export_static_data(G, rock, schedule, base_dir)`** *(line 1)*

export_static_data - Export static reservoir data Exports rock regions, grid geometry, and well locations to the optimized data structure. Args: G: MRST grid structure rock: MRST rock structure schedule: MRST schedule structure base_dir: Base directory for data export Returns: None (exports data to file) Requires: MRST

---


#### `s11c_export_dynamic_fields.m`

**Description:** export_dynamic_fields - Export dynamic field arrays (2D or 3D) Exports arrays of pressure, saturation, porosity, permeability, and effective stress. Handles both 2D (nz=1) and 3D (nz>1) automatically. Args: G: MRST grid structure rock: MRST rock structure states: Cell array of simulation states base_dir: Base directory for data export Returns: None (exports data to file) Requires: MRST

**Functions:**

**`s11c_export_dynamic_fields(G, rock, states, base_dir)`** *(line 1)*

export_dynamic_fields - Export dynamic field arrays (2D or 3D) Exports arrays of pressure, saturation, porosity, permeability, and effective stress. Handles both 2D (nz=1) and 3D (nz>1) automatically. Args: G: MRST grid structure rock: MRST rock structure states: Cell array of simulation states base_dir: Base directory for data export Returns: None (exports data to file) Requires: MRST

---


#### `s11d_export_metadata.m`

**Description:** s11d_export_metadata - Export comprehensive dataset metadata Creates comprehensive metadata with dataset information, simulation parameters, data structure details, and optimization information. Args: G: MRST grid structure schedule: MRST schedule structure temporal_data: Temporal data structure n_wells: Number of wells fields_file: Path to fields file for size calculation base_dir: Base directory for data export Returns: None (exports metadata to file) Requires: MRST

**Functions:**

**`s11d_export_metadata(G, schedule, temporal_data, base_dir)`** *(line 1)*

s11d_export_metadata - Export comprehensive dataset metadata Creates comprehensive metadata with dataset information, simulation parameters, data structure details, and optimization information. Args: G: MRST grid structure schedule: MRST schedule structure temporal_data: Temporal data structure n_wells: Number of wells fields_file: Path to fields file for size calculation base_dir: Base directory for data export Returns: None (exports metadata to file) Requires: MRST

---


#### `s12_extract_snapshot.m`

**Description:** extract_snapshot - Extract arrays from simulation state (2D or 3D) Extracts and processes simulation data into arrays for ML training. Handles both 2D (nz=1) and 3D (nz>1) cases automatically: - Effective stress (σ') - Porosity (φ) - Permeability (k) - Rock region ID - Pressure (p) - Saturation (s) Args: G: MRST grid structure rock: MRST rock structure with regions state: MRST simulation state for specific timestep timestep: Current timestep number (for reference) Returns: sigma_eff: nz x ny x nx array of effective stress [psi] (for 2D: 1 x ny x nx) phi: nz x ny x nx array of current porosity [-] (for 2D: 1 x ny x nx) k: nz x ny x nx array of current permeability [mD] (for 2D: 1 x ny x nx) rock_id: nz x ny x nx array of rock region IDs [-] (for 2D: 1 x ny x nx) pressure: nz x ny x nx array of spatial pressure [psi] (for 2D: 1 x ny x nx) saturation: nz x ny x nx array of water saturation [-] (for 2D: 1 x ny x nx) Requires: MRST % ---- % Step 1 – Input validation % ---- Substep 1.1 – Check required inputs __________________________

**Functions:**

**`s12_extract_snapshot(G, rock, state, timestep)`** *(line 1)*

extract_snapshot - Extract arrays from simulation state (2D or 3D) Extracts and processes simulation data into arrays for ML training. Handles both 2D (nz=1) and 3D (nz>1) cases automatically: - Effective stress (σ') - Porosity (φ) - Permeability (k) - Rock region ID - Pressure (p) - Saturation (s) Args: G: MRST grid structure rock: MRST rock structure with regions state: MRST simulation state for specific timestep timestep: Current timestep number (for reference) Returns: sigma_eff: nz x ny x nx array of effective stress [psi] (for 2D: 1 x ny x nx) phi: nz x ny x nx array of current porosity [-] (for 2D: 1 x ny x nx) k: nz x ny x nx array of current permeability [mD] (for 2D: 1 x ny x nx) rock_id: nz x ny x nx array of rock region IDs [-] (for 2D: 1 x ny x nx) pressure: nz x ny x nx array of spatial pressure [psi] (for 2D: 1 x ny x nx) saturation: nz x ny x nx array of water saturation [-] (for 2D: 1 x ny x nx) Requires: MRST % ---- % Step 1 – Input validation % ---- Substep 1.1 – Check required inputs __________________________

---


#### `s13_generate_completion_report.m`

**Description:** generate_completion_report - Generate final workflow completion report Creates a comprehensive report of the simulation workflow execution including timing, results summary, and validation status. Args: None (loads variables from data files) Returns: None (prints completion report) Requires: MRST Load all required variables from data files

**Functions:**

**`s13_generate_completion_report()`** *(line 1)*

generate_completion_report - Generate final workflow completion report Creates a comprehensive report of the simulation workflow execution including timing, results summary, and validation status. Args: None (loads variables from data files) Returns: None (prints completion report) Requires: MRST Load all required variables from data files

---


#### `s99_run_workflow.m`

**Description:** s99_run_workflow - Complete MRST geomechanical simulation workflow Orchestrates the complete simulation workflow including MRST initialization, component setup, simulation execution, and data export. Args: None Returns: None (executes complete workflow) Requires: MRST % ---- % Step 1 – Initialize and setup % ---- Substep 1.1 – Clear workspace and initialize ________________

**Functions:**

**`s99_run_workflow()`** *(line 7)*

s99_run_workflow - Complete MRST geomechanical simulation workflow Orchestrates the complete simulation workflow including MRST initialization, component setup, simulation execution, and data export. Args: None Returns: None (executes complete workflow) Requires: MRST % ---- % Step 1 – Initialize and setup % ---- Substep 1.1 – Clear workspace and initialize ________________

---

**`validate_workflow_results(required_vars)`** *(line 91)*

validate_workflow_results - Validate that all required outputs exist Checks that all required variables and data files were created successfully during the workflow execution. Args: required_vars: Cell array of required variable names Returns: all_vars_exist: Boolean indicating if all validation passed Requires: None

---


#### `util_ensure_directories.m`

**Description:** util_ensure_directories - Ensure all required directories exist Creates all necessary directories for MRST simulation workflow including data storage, plots, and temporary files. Provides detailed logging of directory creation status. Args: None Returns: None (creates directories as needed) Requires: None (pure Octave/MATLAB) % ---- % Step 1 – Define required directories % ---- Substep 1.1 – List all required directories __________________ Updated for optimized data structure

**Functions:**

**`util_ensure_directories()`** *(line 1)*

util_ensure_directories - Ensure all required directories exist Creates all necessary directories for MRST simulation workflow including data storage, plots, and temporary files. Provides detailed logging of directory creation status. Args: None Returns: None (creates directories as needed) Requires: None (pure Octave/MATLAB) % ---- % Step 1 – Define required directories % ---- Substep 1.1 – List all required directories __________________ Updated for optimized data structure

---



## test/

### MATLAB/Octave Files (2 files)

#### `test_01_sim_scripts_util_read_config.m`

**Description:** test_01_sim_scripts_util_read_config - Test YAML configuration system Tests util_read_config.m and configuration-based setup_field functions. Verifies YAML parsing, parameter validation, and configuration modification. Test functions: - test_config_loading_basic - test_setup_field_with_config - test_config_modification Requires: MRST

**Functions:**

**`test_01_sim_scripts_util_read_config()`** *(line 1)*

test_01_sim_scripts_util_read_config - Test YAML configuration system Tests util_read_config.m and configuration-based setup_field functions. Verifies YAML parsing, parameter validation, and configuration modification. Test functions: - test_config_loading_basic - test_setup_field_with_config - test_config_modification Requires: MRST

---

**`test_config_loading_basic()`** *(line 26)*

Test basic configuration file loading and parsing

---

**`test_setup_field_with_config()`** *(line 59)*

Test setup_field function with configuration

---

**`test_config_modification()`** *(line 110)*

Test configuration modification and temporary file handling

---

**`write_temp_config(filename, config)`** *(line 155)*

Write a simple temporary config file for testing

---


#### `test_02_sim_scripts_setup_field.m`

**Description:** test_02_sim_scripts_setup_field - Test field units configuration system Tests setup_field.m, define_fluid.m, and create_schedule.m functions with field units (psi, ft, bbl/day) to ensure proper unit handling. Test functions: - test_field_units_config - test_setup_field_units - test_fluid_definition_units - test_schedule_creation_units Requires: MRST

**Functions:**

**`test_02_sim_scripts_setup_field()`** *(line 1)*

test_02_sim_scripts_setup_field - Test field units configuration system Tests setup_field.m, define_fluid.m, and create_schedule.m functions with field units (psi, ft, bbl/day) to ensure proper unit handling. Test functions: - test_field_units_config - test_setup_field_units - test_fluid_definition_units - test_schedule_creation_units Requires: MRST

---

**`test_field_units_config()`** *(line 29)*

Test configuration loading with field units

---

**`test_setup_field_units()`** *(line 63)*

Test setup_field function with field units

---

**`test_fluid_definition_units()`** *(line 113)*

Test fluid definition with field units

---

**`test_schedule_creation_units()`** *(line 144)*

Test schedule creation with field units

---




---

*This documentation is auto-generated and reflects the current state of the codebase.*
