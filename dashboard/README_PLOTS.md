# MRST Simulation Dashboard - Plot Organization

## 📁 Hierarchical Plot Structure

The dashboard plots are organized in a hierarchical structure corresponding to the 6 main visualization categories:

### 1. **Initial Conditions** (`plots/initial_conditions/`)
Visualizes baseline reservoir state at t=0
- `pressure_map.py`: Initial pressure distribution maps
- `saturation_map.py`: Initial water saturation maps

### 2. **Static Properties** (`plots/static_properties/`)
Time-invariant reservoir properties
- `porosity_map.py`: Porosity distribution maps
- `permeability_map.py`: Permeability distribution maps (with log scale)
- `rock_regions.py`: Rock region categorical maps
- `property_histograms.py`: Porosity histograms and permeability box plots

### 3. **Dynamic Fields** (`plots/dynamic_fields/`)
Time-dependent field evolution
- `field_snapshots.py`: Pressure/saturation snapshots at specific timesteps
- `field_evolution.py`: Time series of spatially-averaged field variables
- `field_animation.py`: Animated field evolution with controls

### 4. **Well Production** (`plots/well_production/`)
Production and injection analysis
- `production_rates.py`: Oil production and water injection rate plots
- `cumulative_production.py`: Cumulative production and recovery factors
- `well_performance.py`: Water cut analysis and well comparisons

### 5. **Flow & Velocity** (`plots/flow_velocity/`)
Flow field visualization
- `velocity_fields.py`: Velocity field quiver plots and magnitude maps
- `flow_evolution.py`: Time series of velocity magnitude evolution

### 6. **Transect Profiles** (`plots/transect_profiles/`)
Cross-sectional analysis
- `pressure_profiles.py`: Cross-sectional pressure profiles
- `saturation_profiles.py`: Cross-sectional saturation profiles

## 🎯 Data Sources

Each plot category corresponds to specific MRST simulation data files:

- **Initial Conditions**: `initial/initial_conditions.mat`
- **Static Properties**: `initial/initial_conditions.mat` + `static/static_data.mat`
- **Dynamic Fields**: `dynamic/fields/field_arrays.mat`
- **Well Production**: `dynamic/wells/well_data.mat` + `dynamic/wells/cumulative_data.mat`
- **Flow & Velocity**: `dynamic/fields/flow_data.mat`
- **Transect Profiles**: `dynamic/fields/field_arrays.mat`

## 🚀 Usage

Import plot functions directly from their respective modules:

```python
from plots.initial_conditions import create_initial_pressure_map
from plots.static_properties import create_porosity_map, create_permeability_map
from plots.dynamic_fields import create_pressure_snapshot, create_average_pressure_evolution
from plots.well_production import create_oil_production_plot, create_cumulative_production_plot
from plots.flow_velocity import create_velocity_evolution_plot
from plots.transect_profiles import create_pressure_transect_plot
```

## 📊 Plot Features

- **Interactive Plotly visualizations** with hover information
- **Error handling** for missing or invalid data
- **Flexible parameters** for customization
- **Consistent styling** across all plot types
- **Comprehensive documentation** with function descriptions

## 🔧 Technical Notes

- All plots use **Plotly** for interactive visualization
- Data validation ensures proper input format
- Graceful error handling for missing simulation data
- Modular design for easy maintenance and extension