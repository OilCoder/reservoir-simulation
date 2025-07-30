# Static Data Inventory

## Overview

This document catalogs all static data that remains constant throughout the simulation lifecycle. Static data forms the foundation of the reservoir model and includes grid geometry, rock properties, well configurations, fluid property tables, and simulation parameters.

All static data is stored in `/workspace/data/simulation_data/static/` directory with oct2py-compatible .mat files (v7 format) for seamless Python integration.

---

## 1. Grid Geometry

### Grid Structure
| Attribute | Description | Dimensions | Units | Storage Format |
|-----------|-------------|------------|-------|----------------|
| **grid_x** | Grid node coordinates (X-axis) | [nx+1] | m | Double array |
| **grid_y** | Grid node coordinates (Y-axis) | [ny+1] | m | Double array |
| **grid_z** | Grid node coordinates (Z-axis) | [nz+1] | m | Double array |
| **cell_centers_x** | Cell center coordinates (X-axis) | [nx] | m | Double array |
| **cell_centers_y** | Cell center coordinates (Y-axis) | [ny] | m | Double array |
| **cell_centers_z** | Cell center coordinates (Z-axis) | [nz] | m | Double array |

### Grid Configuration
- **Grid Dimensions**: 20×20×10 cells (configurable)
- **Cell Size**: 164×164 ft horizontal, variable vertical (5-50 ft)
- **Total Domain**: 3,280×3,280 ft horizontal extent
- **Depth Range**: 7,900-8,138 ft TVD

### Storage Details
- **File**: `static_data.mat`
- **Format**: MATLAB v7 (oct2py compatible)
- **Metadata**: `metadata/metadata.yaml`

### ML Usage Potential
- **High**: Spatial interpolation, grid refinement optimization
- **Applications**: Mesh generation, upscaling/downscaling, coordinate transformations
- **Features**: Regular structured grid, ideal for CNN architectures

### Dashboard Usage
- **Primary**: Grid visualization, cell highlighting, 3D rendering
- **Interactive**: Cross-sections, layer selection, zoom controls

---

## 2. Rock Properties by Lithology

### Porosity Distribution
| Attribute | Description | Dimensions | Units | Storage Format |
|-----------|-------------|------------|-------|----------------|
| **phi** | Initial porosity field | [nz, ny, nx] | dimensionless | Double array |
| **phi_base** | Base porosity by layer | [10] | dimensionless | Double array |
| **phi_bounds** | Min/max porosity limits | [2] | dimensionless | Double array |

### Permeability Distribution
| Attribute | Description | Dimensions | Units | Storage Format |
|-----------|-------------|------------|-------|----------------|
| **k** | Initial permeability field | [nz, ny, nx] | mD | Double array |
| **k_base** | Base permeability by layer | [10] | mD | Double array |
| **k_bounds** | Min/max permeability limits | [2] | mD | Double array |
| **k_tensor** | Directional multipliers | [3] | dimensionless | Double array |

### Rock Region Mapping
| Attribute | Description | Dimensions | Units | Storage Format |
|-----------|-------------|------------|-------|----------------|
| **rock_id** | Rock type identifier | [nz, ny, nx] | integer | Integer array |
| **layer_names** | Geological layer names | [10] | string | Cell array |
| **lithology** | Rock type classification | [10] | string | Cell array |

### Geological Layers
| Layer ID | Name | Depth Range (ft) | Thickness (ft) | Lithology | Porosity | Permeability (mD) |
|----------|------|------------------|----------------|-----------|----------|-------------------|
| 1 | Shale Cap | 7900-7950 | 50.0 | Shale | 0.08 | 0.1 |
| 2 | Reservoir Sand 1 | 7950-7990 | 40.0 | Sandstone | 0.25 | 200.0 |
| 3 | Shale Barrier | 7990-8025 | 35.0 | Shale | 0.10 | 0.5 |
| 4 | Reservoir Sand 2 | 8025-8055 | 30.0 | Sandstone | 0.22 | 150.0 |
| 5 | Limestone | 8055-8080 | 25.0 | Limestone | 0.18 | 80.0 |
| 6 | Tight Sand | 8080-8100 | 20.0 | Sandstone | 0.15 | 25.0 |
| 7 | Reservoir Sand 3 | 8100-8115 | 15.0 | Sandstone | 0.20 | 120.0 |
| 8 | Shale Seal | 8115-8125 | 10.0 | Shale | 0.06 | 0.05 |
| 9 | Aquifer Sand | 8125-8133 | 8.0 | Sandstone | 0.28 | 300.0 |
| 10 | Basement | 8133-8138 | 5.0 | Granite | 0.02 | 0.001 |

### Storage Details
- **File**: `static_data.mat`
- **Compression**: Sparse storage for uniform regions
- **Metadata**: `rock_properties_config.yaml`

### ML Usage Potential
- **Very High**: Facies classification, property prediction
- **Applications**: Geostatistical modeling, uncertainty quantification
- **Features**: Spatial correlation patterns, lithology boundaries

### Dashboard Usage
- **Primary**: Property maps, layer visualization, histogram analysis
- **Interactive**: Property sliders, layer selection, statistics panels

---

## 3. Well Configuration

### Well Locations
| Attribute | Description | Dimensions | Units | Storage Format |
|-----------|-------------|------------|-------|----------------|
| **well_names** | Well identifiers | [n_wells] | string | Cell array |
| **well_i** | Grid I-coordinates | [n_wells] | index | Integer array |
| **well_j** | Grid J-coordinates | [n_wells] | index | Integer array |
| **well_k** | Grid K-coordinates | [n_wells] | index | Integer array |
| **well_types** | Well classification | [n_wells] | string | Cell array |

### Well Trajectories
| Attribute | Description | Dimensions | Units | Storage Format |
|-----------|-------------|------------|-------|----------------|
| **well_cells** | Perforated cell indices | [n_wells, max_cells] | index | Integer array |
| **completion_length** | Active length per cell | [n_wells, max_cells] | ft | Double array |
| **skin_factor** | Well skin by cell | [n_wells, max_cells] | dimensionless | Double array |

### Completion Data
| Attribute | Description | Dimensions | Units | Storage Format |
|-----------|-------------|------------|-------|----------------|
| **perforation_start** | Top of perforations | [n_wells, n_intervals] | ft | Double array |
| **perforation_end** | Bottom of perforations | [n_wells, n_intervals] | ft | Double array |
| **well_radius** | Wellbore radius | [n_wells] | ft | Double array |

### Storage Details
- **File**: `static_data.mat` (nested struct)
- **Format**: Structured arrays for efficient access
- **Metadata**: `wells_schedule_config.yaml`

### ML Usage Potential
- **High**: Well placement optimization, completion design
- **Applications**: Production forecasting, infill drilling analysis
- **Features**: Spatial patterns, completion effectiveness

### Dashboard Usage
- **Primary**: Well symbols, trajectory display, completion intervals
- **Interactive**: Well selection, trajectory editing, completion details

---

## 4. Fluid Properties Tables

### PVT Data Structure
| Attribute | Description | Dimensions | Units | Storage Format |
|-----------|-------------|------------|-------|----------------|
| **pressure_table** | Pressure points for PVT | [n_pressure] | psi | Double array |
| **oil_fvf** | Oil formation volume factor | [n_pressure] | rb/stb | Double array |
| **oil_viscosity** | Oil viscosity table | [n_pressure] | cP | Double array |
| **water_fvf** | Water formation volume factor | [n_pressure] | rb/stb | Double array |
| **water_viscosity** | Water viscosity table | [n_pressure] | cP | Double array |

### Relative Permeability Tables
| Attribute | Description | Dimensions | Units | Storage Format |
|-----------|-------------|------------|-------|----------------|
| **saturation_table** | Water saturation points | [n_saturation] | fraction | Double array |
| **krw_table** | Water relative permeability | [n_saturation] | fraction | Double array |
| **kro_table** | Oil relative permeability | [n_saturation] | fraction | Double array |
| **pcow_table** | Oil-water capillary pressure | [n_saturation] | psi | Double array |

### Fluid Constants
| Property | Value | Units | Description |
|----------|-------|-------|-------------|
| Oil Density | 850.0 | kg/m³ | Stock tank oil density |
| Water Density | 1000.0 | kg/m³ | Formation water density |
| Oil Viscosity | 2.0 | cP | Reference viscosity |
| Water Viscosity | 0.5 | cP | Reference viscosity |
| Connate Water Sat | 0.15 | fraction | Irreducible water |
| Residual Oil Sat | 0.20 | fraction | Trapped oil |

### Storage Details
- **File**: `fluid_properties.mat`
- **Tables**: 50 pressure points, 100 saturation points
- **Metadata**: `fluid_properties_config.yaml`

### ML Usage Potential
- **Medium**: Phase behavior prediction, PVT correlation development
- **Applications**: Equation of state tuning, fluid characterization
- **Features**: Tabular data, interpolation functions

### Dashboard Usage
- **Primary**: PVT plots, relative permeability curves
- **Interactive**: Table editing, curve fitting, parameter sensitivity

---

## 5. Simulation Parameters

### Solver Configuration
| Parameter | Description | Value | Units | Storage Format |
|-----------|-------------|-------|-------|----------------|
| **tolerance_pressure** | Pressure convergence | 1e-6 | psi | Double scalar |
| **tolerance_saturation** | Saturation convergence | 1e-6 | fraction | Double scalar |
| **max_iterations** | Maximum Newton iterations | 25 | count | Integer scalar |
| **time_step_limits** | Min/max time steps | [0.1, 30] | days | Double array |

### Numerical Methods
| Parameter | Description | Value | Type | Storage Format |
|-----------|-------------|-------|------|----------------|
| **linear_solver** | System solver type | 'GMRES' | string | Character array |
| **preconditioner** | Preconditioning method | 'ILU' | string | Character array |
| **upwind_method** | Mobility upwinding | 'standard' | string | Character array |
| **time_integration** | Time stepping scheme | 'implicit' | string | Character array |

### Control Parameters
| Parameter | Description | Value | Units | Storage Format |
|-----------|-------------|-------|-------|----------------|
| **min_pressure** | Minimum cell pressure | 500.0 | psi | Double scalar |
| **max_pressure** | Maximum cell pressure | 8000.0 | psi | Double scalar |
| **min_saturation** | Minimum phase saturation | 0.01 | fraction | Double scalar |
| **cfl_number** | Courant number limit | 0.5 | dimensionless | Double scalar |

### Storage Details
- **File**: `simulation_parameters.mat`
- **Format**: Structured parameters
- **Metadata**: `simulation_config.yaml`

### ML Usage Potential
- **Low**: Parameter optimization, convergence prediction
- **Applications**: Adaptive time stepping, solver selection
- **Features**: Scalar parameters, performance metrics

### Dashboard Usage
- **Primary**: Parameter display, convergence monitoring
- **Interactive**: Parameter adjustment, performance metrics

---

## 6. Fault Properties

### Fault Geometry
| Attribute | Description | Dimensions | Units | Storage Format |
|-----------|-------------|------------|-------|----------------|
| **fault_cells** | Cell pairs across faults | [n_faults, 2] | index | Integer array |
| **fault_normals** | Fault plane normal vectors | [n_faults, 3] | dimensionless | Double array |
| **fault_areas** | Fault surface areas | [n_faults] | ft² | Double array |

### Transmissibility Multipliers
| Attribute | Description | Dimensions | Units | Storage Format |
|-----------|-------------|------------|-------|----------------|
| **trans_multiplier** | Flow multiplier across fault | [n_faults] | dimensionless | Double array |
| **fault_aperture** | Effective fault opening | [n_faults] | ft | Double array |
| **fault_permeability** | Fault zone permeability | [n_faults] | mD | Double array |

### Geomechanical Properties
| Attribute | Description | Dimensions | Units | Storage Format |
|-----------|-------------|------------|-------|----------------|
| **friction_coefficient** | Fault friction angle | [n_faults] | dimensionless | Double array |
| **cohesion** | Fault cohesive strength | [n_faults] | psi | Double array |
| **stress_ratio** | Stress concentration factor | [n_faults] | dimensionless | Double array |

### Storage Details
- **File**: `fault_properties.mat`
- **Format**: Sparse connectivity matrix
- **Metadata**: `fault_config.yaml`

### ML Usage Potential
- **Medium**: Fault activation prediction, stress analysis
- **Applications**: Geomechanical modeling, fault seal analysis
- **Features**: Geometric parameters, mechanical properties

### Dashboard Usage
- **Primary**: Fault visualization, stress indicators
- **Interactive**: Fault selection, property editing, stress plots

---

## 7. Initial Conditions Snapshot

### Pressure Field
| Attribute | Description | Dimensions | Units | Storage Format |
|-----------|-------------|------------|-------|----------------|
| **pressure_initial** | Initial pressure distribution | [nz, ny, nx] | psi | Double array |
| **pressure_gradient** | Hydrostatic gradient | [nz] | psi/ft | Double array |
| **pressure_datum** | Reference depth | 1 | ft | Double scalar |

### Saturation Field
| Attribute | Description | Dimensions | Units | Storage Format |
|-----------|-------------|------------|-------|----------------|
| **sw_initial** | Initial water saturation | [nz, ny, nx] | fraction | Double array |
| **sw_contacts** | Oil-water contacts | [n_contacts] | ft | Double array |
| **transition_zone** | Contact transition thickness | [n_contacts] | ft | Double array |

### Stress Field (Geomechanical)
| Attribute | Description | Dimensions | Units | Storage Format |
|-----------|-------------|------------|-------|----------------|
| **sigma_v** | Vertical stress | [nz, ny, nx] | psi | Double array |
| **sigma_h_min** | Minimum horizontal stress | [nz, ny, nx] | psi | Double array |
| **sigma_h_max** | Maximum horizontal stress | [nz, ny, nx] | psi | Double array |
| **pore_pressure** | Initial pore pressure | [nz, ny, nx] | psi | Double array |

### Storage Details
- **File**: `initial_conditions.mat`
- **Format**: 3D arrays with consistent indexing
- **Metadata**: `initial_conditions_config.yaml`

### ML Usage Potential
- **Very High**: Initial condition optimization, uncertainty quantification
- **Applications**: History matching, ensemble generation
- **Features**: 3D spatial fields, equilibrium constraints

### Dashboard Usage
- **Primary**: Initial state visualization, cross-sections
- **Interactive**: Layer selection, property overlays, 3D slicing

---

## File Location Patterns

### Directory Structure
```
/workspace/data/simulation_data/static/
├── static_data.mat                 # Grid geometry, rock properties, wells
├── fluid_properties.mat            # PVT tables, relative permeability
├── simulation_parameters.mat       # Solver settings, tolerances
├── fault_properties.mat            # Fault geometry, transmissibility
└── volumetric_data.mat             # Static volumetric calculations
```

### Metadata Locations
```
/workspace/metadata/
├── metadata.yaml                   # Human-readable dataset info
└── simulation_metadata.mat         # Machine-readable metadata

/workspace/mrst_simulation_scripts/config/
├── rock_properties_config.yaml     # Rock property definitions
├── fluid_properties_config.yaml    # Fluid property tables
├── wells_schedule_config.yaml      # Well configuration
└── initial_conditions_config.yaml  # Initial state parameters
```

## Oct2py Compatibility

### File Format Requirements
- **MATLAB Version**: v7 format (Octave compatible)
- **Data Types**: Double arrays, cell arrays, structures
- **Indexing**: MATLAB 1-based indexing documented
- **Loading**: `scipy.io.loadmat()` compatible

### Python Integration Specification
- **File Format**: MATLAB v7 format (Octave compatible)
- **Data Types**: Double arrays, cell arrays, structures
- **Indexing**: MATLAB 1-based indexing documented
- **Loading**: scipy.io.loadmat() compatible
- **Access Pattern**: Hierarchical structure access through nested indices



---

*This inventory serves as the foundation for reservoir simulation data management, ensuring consistent access patterns for both MATLAB/Octave and Python environments while maintaining optimal performance for machine learning and dashboard applications.*