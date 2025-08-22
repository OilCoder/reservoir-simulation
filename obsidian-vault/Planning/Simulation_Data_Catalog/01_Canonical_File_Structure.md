---
title: Canonical File Structure - 7 MRST Data Files
date: 2025-08-21
author: doc-writer
tags: [canonical-files, mrst, data-structure, specification]
status: published
---

# Canonical File Structure
## Detailed Specification of 7 MRST Data Files

---

## OVERVIEW

This document provides the definitive specification for the 7 canonical .mat files that comprise the complete Eagle West Field MRST simulation dataset. Each file serves a specific purpose and contains precisely defined data structures that MRST scripts expect.

### Canonical Files Summary

| **File** | **Primary Purpose** | **MRST Equivalent** | **Size Est.** | **Update Frequency** |
|----------|--------------------|--------------------|---------------|---------------------|
| `grid.mat` | Grid geometry and geological structure | `G` structure | ~50 MB | Once per model |
| `rock.mat` | Rock properties with heterogeneity | `rock` structure | ~30 MB | Once per model |
| `fluid.mat` | Complete fluid properties | `fluid` structure | ~5 MB | Once per model |
| `wells.mat` | Well placement and completions | `W` structure | ~1 MB | Per development phase |
| `initial_state.mat` | Initial pressure and saturations | `state` structure | ~20 MB | Once per simulation |
| `schedule.mat` | Production schedule and controls | `schedule` structure | ~2 MB | Per development plan |
| `solver.mat` | Solver configuration | Solver options | <1 MB | Per simulation setup |

---

## FILE 1: GRID.MAT - GRID GEOMETRY AND GEOLOGICAL STRUCTURE

### Primary Purpose
Contains the complete PEBI grid structure with geological framework and fault system integration for the Eagle West Field.

### Created/Updated By
- **Created**: s03_create_pebi_grid.m
- **Updated**: s04_structural_framework.m (adds geological structure)
- **Finalized**: s05_add_faults.m (adds fault system)

### Canonical Structure
```matlab
% GRID.MAT STRUCTURE (CANONICAL)
load('/workspace/data/mrst/grid.mat')

% REQUIRED FIELDS:
G                     % Main MRST grid structure
├── cells             % Cell geometry and connectivity
│   ├── num           % Number of cells: 20,332 (canonical)
│   ├── facePos       % Cell-to-face connectivity
│   ├── indexMap      % Global cell indexing
│   └── centroids     % Cell center coordinates [x,y,z]
├── faces             % Face geometry
│   ├── num           % Number of faces
│   ├── nodePos       % Face-to-node connectivity  
│   ├── neighbors     % Adjacent cells [-1 for boundary]
│   ├── areas         % Face areas [m²]
│   └── centroids     % Face center coordinates [x,y,z]
├── nodes             % Node coordinates
│   ├── num           % Number of nodes
│   └── coords        % Node coordinates [x,y,z] [m]
└── type              % Grid type: 'pebi'

% GEOLOGICAL STRUCTURE (added by s04):
structure             % Geological framework
├── layers            % Stratigraphic layers
│   ├── num_layers    % Number of layers: 12 (canonical)
│   ├── layer_tops    % Top depth of each layer [m TVD]
│   ├── layer_thickness % Thickness of each layer [m]
│   └── layer_properties % Geological properties per layer
├── surfaces          % Geological surfaces
│   ├── top_structure % Top reservoir surface [m TVD]
│   ├── base_structure % Base reservoir surface [m TVD]
│   └── internal_surfaces % Internal geological surfaces
└── horizons          % Seismic horizons
    ├── horizon_1     % Top Tuscaloosa (canonical name)
    ├── horizon_2     % Mid Tuscaloosa
    └── horizon_3     % Base Tuscaloosa

% FAULT SYSTEM (added by s05):
faults                % Fault system integration
├── fault_list        % Array of fault structures
│   ├── Fault_A       % Major fault A (canonical naming)
│   ├── Fault_B       % Major fault B  
│   ├── Fault_C       % Major fault C
│   ├── Fault_D       % Major fault D
│   └── Fault_E       % Major fault E
├── fault_grid        % Fault-conforming grid elements
└── fault_transmissibility % Fault transmissibility multipliers

% GRID METADATA:
grid_info             % Grid generation metadata
├── creation_date     % Grid creation timestamp
├── grid_dimensions   % Original dimensions [41, 41, 12] (canonical)
├── cell_sizes        % Cell dimensions [82.0, 74.0] ft (canonical)
├── refinement_areas  % Areas with grid refinement
└── pebi_constraints  % PEBI generation constraints
```

### Validation Requirements
- Grid must have exactly 20,332 cells (canonical Eagle West count)
- 12 geological layers must be defined
- 5 major faults (Fault_A through Fault_E) must be included
- Grid type must be 'pebi'
- All coordinate systems must be consistent (meters, TVD)

### Error Conditions
```matlab
% CANONICAL ERROR - Missing grid file
if ~exist('/workspace/data/mrst/grid.mat', 'file')
    error(['Missing canonical grid file: /workspace/data/mrst/grid.mat\n' ...
           'REQUIRED: Run s03_create_pebi_grid.m to create PEBI grid.\n' ...
           'Canon specifies 41×41×12 grid with 20,332 cells for Eagle West Field.']);
end

% CANONICAL ERROR - Invalid cell count  
if G.cells.num ~= 20332
    error(['Invalid grid cell count: %d (expected: 20,332)\n' ...
           'REQUIRED: Grid must have canonical Eagle West cell count.\n' ...
           'Verify PEBI grid generation with proper refinement.'], G.cells.num);
end
```

---

## FILE 2: ROCK.MAT - ROCK PROPERTIES WITH HETEROGENEITY

### Primary Purpose
Contains complete rock property distribution including porosity, permeability, and spatial heterogeneity for all grid cells.

### Created/Updated By
- **Created**: s06_create_base_rock_structure.m
- **Updated**: s07_add_layer_metadata.m (adds layer-specific properties)
- **Finalized**: s08_apply_spatial_heterogeneity.m (adds heterogeneity)

### Canonical Structure
```matlab
% ROCK.MAT STRUCTURE (CANONICAL)
load('/workspace/data/mrst/rock.mat')

% REQUIRED FIELDS:
rock                  % Main MRST rock structure
├── perm              % Permeability tensor [m²]
│   ├── size          % [20332, 3] - one per cell, x/y/z components
│   ├── units         % 'meter^2' (MRST standard)
│   └── range         % [1e-15, 1e-12] m² (canonical Eagle West range)
├── poro              % Porosity [dimensionless]
│   ├── size          % [20332, 1] - one per cell  
│   ├── units         % 'dimensionless' 
│   └── range         % [0.05, 0.25] (canonical Eagle West range)
└── ntg               % Net-to-gross ratio [dimensionless]
    ├── size          % [20332, 1] - one per cell
    ├── units         % 'dimensionless'
    └── range         % [0.7, 1.0] (canonical Eagle West range)

% LAYER PROPERTIES (added by s07):
layer_properties      % Layer-specific rock properties
├── layer_01          % Top layer properties
│   ├── avg_perm      % Average permeability [m²]
│   ├── avg_poro      % Average porosity
│   ├── facies_type   % 'sand' | 'shale' | 'carbonate'
│   └── deposition    % Depositional environment
├── layer_02          % Layer 2 properties
│   └── ...           % (similar structure for all 12 layers)
└── layer_12          % Bottom layer properties

% HETEROGENEITY MODEL (added by s08):
heterogeneity         % Spatial heterogeneity implementation
├── variogram_model   % Geostatistical model
│   ├── type          % 'gaussian' | 'exponential' | 'spherical'
│   ├── range         % Correlation range [m]
│   ├── sill          % Variance parameter
│   └── nugget        % Nugget effect
├── permeability_field % Heterogeneous permeability
│   ├── base_field    % Base statistical realization
│   ├── trend_overlay % Large-scale trends
│   └── local_variation % Small-scale heterogeneity
└── porosity_field    % Heterogeneous porosity
    ├── base_field    % Base statistical realization
    ├── permeability_correlation % φ-k correlation
    └── local_variation % Small-scale heterogeneity

% ROCK METADATA:
rock_info             % Rock property metadata
├── creation_date     % Rock structure creation timestamp
├── source_data       % Source of rock property data
├── upscaling_method  % Method used for upscaling
├── quality_metrics   % Property distribution statistics
└── validation_results % QC validation results
```

### Validation Requirements
- Rock structure must have exactly 20,332 entries (matching grid)
- Permeability must be positive and in range [1e-15, 1e-12] m²
- Porosity must be in range [0.05, 0.25]
- Net-to-gross must be in range [0.7, 1.0]
- All 12 layers must have defined properties

### Error Conditions
```matlab
% CANONICAL ERROR - Missing rock file
if ~exist('/workspace/data/mrst/rock.mat', 'file')
    error(['Missing canonical rock file: /workspace/data/mrst/rock.mat\n' ...
           'REQUIRED: Run s06_create_base_rock_structure.m to create rock properties.\n' ...
           'Canon specifies heterogeneous rock properties for Eagle West Field.']);
end

% CANONICAL ERROR - Size mismatch
if length(rock.poro) ~= 20332
    error(['Rock property size mismatch: %d (expected: 20,332)\n' ...
           'REQUIRED: Rock properties must match grid cell count.\n' ...
           'Verify rock property generation matches grid structure.'], length(rock.poro));
end
```

---

## FILE 3: FLUID.MAT - COMPLETE FLUID PROPERTIES

### Primary Purpose
Contains complete fluid property specifications including PVT tables, relative permeability, and capillary pressure curves.

### Created/Updated By
- **Created**: s02_define_fluids.m
- **Updated**: s09_relative_permeability.m (adds relperm)
- **Updated**: s10_capillary_pressure.m (adds capillary pressure)
- **Finalized**: s11_pvt_tables.m (adds complete PVT)

### Canonical Structure
```matlab
% FLUID.MAT STRUCTURE (CANONICAL)
load('/workspace/data/mrst/fluid.mat')

% REQUIRED FIELDS:
fluid                 % Main MRST fluid structure
├── properties        % Base fluid properties
│   ├── oil           % Oil properties
│   │   ├── density   % Oil density [kg/m³]
│   │   ├── viscosity % Oil viscosity [Pa·s]
│   │   └── compressibility % Oil compressibility [1/Pa]
│   ├── water         % Water properties  
│   │   ├── density   % Water density [kg/m³]
│   │   ├── viscosity % Water viscosity [Pa·s]
│   │   └── compressibility % Water compressibility [1/Pa]
│   └── gas           % Gas properties
│       ├── density   % Gas density [kg/m³]
│       ├── viscosity % Gas viscosity [Pa·s]
│       └── compressibility % Gas compressibility [1/Pa]
├── pvt               % PVT tables (added by s11)
│   ├── PVTO          % Oil PVT table
│   ├── PVTG          % Gas PVT table
│   ├── PVTW          % Water PVT table
│   └── DENSITY       % Phase density tables
└── surface_conditions % Standard conditions
    ├── pressure      % Standard pressure [Pa]
    ├── temperature   % Standard temperature [K]
    └── gas_oil_ratio % Standard GOR [m³/m³]

% RELATIVE PERMEABILITY (added by s09):
relperm               % Relative permeability functions
├── krw               % Water relative permeability function
├── kro               % Oil relative permeability function  
├── krg               % Gas relative permeability function
├── saturation_table  % Saturation lookup table
└── endpoints         % Critical saturations
    ├── swc           % Connate water saturation
    ├── sor           % Residual oil saturation
    └── sgc           % Critical gas saturation

% CAPILLARY PRESSURE (added by s10):
capillary             % Capillary pressure functions
├── pcow              % Oil-water capillary pressure [Pa]
├── pcog              % Oil-gas capillary pressure [Pa]
├── saturation_table  % Saturation lookup table
└── parameters        % Capillary pressure parameters
    ├── entry_pressure % Entry pressure [Pa]
    ├── lambda         % Pore size distribution parameter
    └── contact_angle  % Wetting angle [degrees]

% FLUID METADATA:
fluid_info            % Fluid property metadata
├── creation_date     % Fluid structure creation timestamp
├── pvt_correlation   % PVT correlation used
├── lab_data_source   % Laboratory data source
├── quality_validation % Fluid property validation
└── temperature_range % Applicable temperature range [K]
```

### Validation Requirements
- All three phases (oil, water, gas) must be defined
- PVT tables must cover operational pressure range [10-500] bar
- Relative permeability endpoints must be physically consistent
- Capillary pressure must be monotonic with saturation

### Error Conditions
```matlab
% CANONICAL ERROR - Missing fluid file
if ~exist('/workspace/data/mrst/fluid.mat', 'file')
    error(['Missing canonical fluid file: /workspace/data/mrst/fluid.mat\n' ...
           'REQUIRED: Run s02_define_fluids.m to create fluid properties.\n' ...
           'Canon specifies three-phase fluid system for Eagle West Field.']);
end
```

---

## FILE 4: WELLS.MAT - WELL PLACEMENT AND COMPLETIONS

### Primary Purpose
Contains well placement, completion design, and MRST well structure for all 15 Eagle West Field wells.

### Created/Updated By
- **Created**: s15_well_placement.m
- **Finalized**: s16_well_completions.m (adds completions and W structure)

### Canonical Structure
```matlab
% WELLS.MAT STRUCTURE (CANONICAL)
load('/workspace/data/mrst/wells.mat')

% REQUIRED FIELDS:
W                     % Main MRST well structure array [15×1]
% Each well contains:
├── name              % Well name: 'EW-001' to 'EW-010', 'IW-001' to 'IW-005'
├── cells             % Completed grid cells
├── type              % 'bhp' | 'rate' | 'resv'
├── val               % Control value
├── r                 % Well radius [m]
├── dir               % Well direction 'x' | 'y' | 'z'
├── WI                % Well index [m³·s/Pa]
├── dZ                % Completion length per cell [m]
├── S                 % Skin factor [dimensionless]
└── compi             % Injection composition [oil, water, gas]

% WELL PLACEMENT:
well_placement        % Well location and trajectory data
├── producers         % Producer wells EW-001 to EW-010
│   ├── EW-001        % Well EW-001 details
│   │   ├── surface_location % [x, y] coordinates [m]
│   │   ├── target_location  % Bottom hole location [x, y, z] [m]
│   │   ├── trajectory       % Well path coordinates
│   │   ├── measured_depth   % Total measured depth [m]
│   │   └── true_vertical_depth % TVD [m]
│   └── ...           % (similar for EW-002 through EW-010)
└── injectors         % Injector wells IW-001 to IW-005
    ├── IW-001        % Injector well details
    └── ...           % (similar for IW-002 through IW-005)

% COMPLETION DESIGN:
completions           % Well completion specifications
├── completion_type   % 'horizontal' | 'vertical' | 'deviated'
├── perforation_design % Perforation specifications
│   ├── shot_density  % Shots per meter
│   ├── hole_diameter % Perforation diameter [m]
│   └── phasing       % Perforation phasing [degrees]
├── screen_design     % Sand screen specifications (if applicable)
└── artificial_lift   % Artificial lift systems (if applicable)

% WELL METADATA:
well_info             % Well placement metadata
├── creation_date     % Well structure creation timestamp
├── development_phase % Development phase (1-6)
├── drilling_order    % Planned drilling sequence
├── target_rates      % Design production rates
└── completion_date   % Planned completion dates
```

### Validation Requirements
- Must contain exactly 15 wells (10 producers + 5 injectors)
- Producer names: EW-001 through EW-010 (canonical naming)
- Injector names: IW-001 through IW-005 (canonical naming)
- All wells must have valid grid cell connections
- Well indices must be positive

### Error Conditions
```matlab
% CANONICAL ERROR - Missing wells file
if ~exist('/workspace/data/mrst/wells.mat', 'file')
    error(['Missing canonical wells file: /workspace/data/mrst/wells.mat\n' ...
           'REQUIRED: Run s15_well_placement.m to create well structure.\n' ...
           'Canon specifies 15 wells (10 producers, 5 injectors) for Eagle West Field.']);
end

% CANONICAL ERROR - Invalid well count
if length(W) ~= 15
    error(['Invalid well count: %d (expected: 15)\n' ...
           'REQUIRED: Eagle West Field must have exactly 15 wells.\n' ...
           'Canon specifies 10 producers (EW-001 to EW-010) and 5 injectors (IW-001 to IW-005).'], length(W));
end
```

---

## FILE 5: INITIAL_STATE.MAT - INITIAL CONDITIONS

### Primary Purpose
Contains initial pressure and saturation distribution for simulation startup.

### Created/Updated By
- **Created**: s12_pressure_initialization.m
- **Updated**: s13_saturation_distribution.m (adds saturations)
- **Finalized**: s14_aquifer_configuration.m (adds aquifer effects)

### Canonical Structure
```matlab
% INITIAL_STATE.MAT STRUCTURE (CANONICAL)
load('/workspace/data/mrst/initial_state.mat')

% REQUIRED FIELDS:
state                 % Main MRST state structure
├── pressure          % Initial pressure [Pa] [20332×1]
├── s                 % Phase saturations [20332×3]
│   ├── (:,1)         % Water saturation
│   ├── (:,2)         % Oil saturation  
│   └── (:,3)         % Gas saturation
├── rs                % Solution gas-oil ratio [m³/m³] [20332×1]
├── rv                % Vaporized oil-gas ratio [m³/m³] [20332×1]
└── wellSol           % Initial well solution (empty for startup)

% EQUILIBRIUM DATA (added by s13):
equilibrium           % Fluid contact and equilibrium
├── contacts          % Fluid contacts
│   ├── owc_depth     % Oil-water contact depth [m TVD]
│   ├── goc_depth     % Gas-oil contact depth [m TVD]  
│   └── transition_zones % Transition zone properties
├── saturation_distribution % Initial saturation profiles
│   ├── water_profile % Water saturation vs depth
│   ├── oil_profile   % Oil saturation vs depth
│   └── gas_profile   % Gas saturation vs depth
└── pressure_gradient % Hydrostatic pressure gradient
    ├── water_gradient % Water gradient [Pa/m]
    ├── oil_gradient   % Oil gradient [Pa/m]
    └── gas_gradient   % Gas gradient [Pa/m]

% AQUIFER SUPPORT (added by s14):
aquifer               % Aquifer drive support
├── aquifer_model     % 'carter_tracy' | 'fetkovich' | 'analytical'
├── aquifer_strength  % Aquifer strength parameter
├── aquifer_geometry  % Aquifer geometric parameters
└── connection_cells  % Grid cells connected to aquifer

% INITIALIZATION METADATA:
init_info             % Initialization metadata
├── creation_date     % Initialization timestamp
├── reference_depth   % Reference depth for initialization [m TVD]
├── reference_pressure % Reference pressure [Pa]
├── initialization_method % Method used for initialization
└── convergence_criteria % Equilibrium convergence criteria
```

### Validation Requirements
- State pressure must be positive for all cells
- Phase saturations must sum to 1.0 for each cell
- Saturation values must be in range [0, 1]
- Pressure must be consistent with fluid contacts

### Error Conditions
```matlab
% CANONICAL ERROR - Missing initial state file
if ~exist('/workspace/data/mrst/initial_state.mat', 'file')
    error(['Missing canonical initial state file: /workspace/data/mrst/initial_state.mat\n' ...
           'REQUIRED: Run s12_pressure_initialization.m to create initial conditions.\n' ...
           'Canon specifies hydrostatic equilibrium initialization for Eagle West Field.']);
end
```

---

## FILE 6: SCHEDULE.MAT - PRODUCTION SCHEDULE AND CONTROLS

### Primary Purpose
Contains complete production schedule with well controls, development phases, and operational constraints.

### Created/Updated By
- **Created**: s17_production_controls.m
- **Updated**: s18_development_schedule.m (adds phased development)
- **Finalized**: s19_production_targets.m (adds production targets)

### Canonical Structure
```matlab
% SCHEDULE.MAT STRUCTURE (CANONICAL)
load('/workspace/data/mrst/schedule.mat')

% REQUIRED FIELDS:
schedule              % Main MRST schedule structure
├── control           % Well control specifications
├── step              % Time step specifications
│   ├── val           % Time step values [s]
│   ├── control       % Control index for each step
│   └── num           % Number of time steps: 120 (canonical - 10 years monthly)
└── time              % Cumulative time [s]

% DEVELOPMENT PHASES (added by s18):
development           % Phased development plan
├── phase_1           % Phase 1: Initial development
│   ├── start_time    % Phase start time [days]
│   ├── duration      % Phase duration [days]
│   ├── active_wells  % Wells active in this phase
│   └── objectives    % Phase objectives and targets
├── phase_2           % Phase 2: Expansion
│   └── ...           % (similar structure for phases 2-6)
└── phase_6           % Phase 6: Final development

% PRODUCTION TARGETS (added by s19):
targets               % Production targets and constraints
├── field_targets     % Field-level targets
│   ├── oil_rate      % Target oil rate [m³/day]
│   ├── water_cut     % Maximum water cut [fraction]
│   ├── gor           % Target gas-oil ratio [m³/m³]
│   └── recovery_factor % Target recovery factor [fraction]
├── well_targets      % Individual well targets
│   ├── max_oil_rate  % Maximum oil rate per well [m³/day]
│   ├── max_water_rate % Maximum water rate per well [m³/day]
│   ├── min_bhp       % Minimum bottom hole pressure [Pa]
│   └── max_bhp       % Maximum bottom hole pressure [Pa]
└── economic_limits   % Economic constraints
    ├── oil_price     % Oil price [$/bbl]
    ├── opex          % Operating expenditure [$/day]
    └── abandonment_rate % Economic limit rate [m³/day]

% SCHEDULE METADATA:
schedule_info         % Schedule metadata
├── creation_date     % Schedule creation timestamp
├── simulation_period % Total simulation time [years]: 10 (canonical)
├── time_stepping     % Time stepping strategy
└── control_strategy  % Well control strategy
```

### Validation Requirements
- Schedule must cover exactly 10 years (3,650 days) canonical period
- Must contain 120 monthly time steps (canonical)
- All active wells must be defined in wells.mat
- Control values must be physically reasonable

---

## FILE 7: SOLVER.MAT - SOLVER CONFIGURATION

### Primary Purpose
Contains MRST solver configuration including nonlinear solver settings, time stepping, and convergence criteria.

### Created/Updated By
- **Created**: s20_solver_setup.m

### Canonical Structure
```matlab
% SOLVER.MAT STRUCTURE (CANONICAL)
load('/workspace/data/mrst/solver.mat')

% REQUIRED FIELDS:
solver_options        % MRST solver configuration
├── nonlinear         % Nonlinear solver options
│   ├── solver        % 'GMRES' | 'BiCGStab' | 'direct'
│   ├── tolerance     % Convergence tolerance: 1e-6 (canonical)
│   ├── maxIterations % Maximum iterations: 25 (canonical)
│   └── lineSearch    % Line search method
├── linear            % Linear solver options
│   ├── solver        % Linear solver type
│   ├── preconditioner % Preconditioner type
│   └── tolerance     % Linear solver tolerance
├── timestep          % Time stepping control
│   ├── initial_dt    % Initial time step [s]
│   ├── max_dt        % Maximum time step [s]
│   ├── min_dt        % Minimum time step [s]
│   └── growth_factor % Time step growth factor
└── convergence       % Convergence criteria
    ├── pressure      % Pressure convergence [Pa]
    ├── saturation    % Saturation convergence [fraction]
    └── mass_balance  % Mass balance convergence [kg/s]

% SOLVER METADATA:
solver_info           % Solver configuration metadata
├── creation_date     % Configuration timestamp
├── mrst_version      % MRST version compatibility
├── recommended_settings % Recommended settings for Eagle West
└── performance_notes % Performance optimization notes
```

### Validation Requirements
- Convergence tolerance must be reasonable (1e-8 to 1e-4)
- Maximum iterations must be positive
- Time step limits must be physically meaningful

---

## FILE 8: SESSION/MRST_SESSION.MAT - MRST SESSION STATE

### Primary Purpose
Maintains MRST session state for workflow continuity and debugging.

### Created/Updated By
- **Created**: s01_initialize_mrst.m

### Canonical Structure
```matlab
% SESSION/MRST_SESSION.MAT STRUCTURE (CANONICAL)
load('/workspace/data/mrst/session/mrst_session.mat')

% REQUIRED FIELDS:
session_state         % MRST session information
├── mrst_loaded       % MRST loading status
├── active_modules    % List of loaded MRST modules
├── workspace_vars    % Important workspace variables
├── path_settings     % MRST path configuration
└── initialization_time % Session start time

% SESSION METADATA:
session_info          % Session metadata
├── creation_date     % Session creation timestamp
├── mrst_version      % MRST version
├── octave_version    % Octave version
├── platform          % Operating system
└── workflow_stage    % Current workflow stage (s01-s20)
```

---

## CROSS-FILE DEPENDENCIES

### Dependency Matrix

| **File** | **Requires** | **Required By** | **Validation** |
|----------|--------------|-----------------|----------------|
| `session/mrst_session.mat` | - | All scripts | MRST environment |
| `grid.mat` | session | rock, fluid, wells, initial_state | Cell count: 20,332 |
| `rock.mat` | grid | initial_state, solver | Property ranges |
| `fluid.mat` | - | initial_state, solver | Phase definitions |
| `wells.mat` | grid | schedule, solver | Well count: 15 |
| `initial_state.mat` | grid, rock, fluid | solver | Saturation sum = 1.0 |
| `schedule.mat` | wells | solver | Time steps: 120 |
| `solver.mat` | grid, rock, fluid, wells, initial_state, schedule | simulation | Complete configuration |

### Validation Sequence
1. **session/mrst_session.mat**: MRST environment validated
2. **grid.mat**: Grid structure and cell count validated
3. **rock.mat**: Property ranges and grid compatibility validated
4. **fluid.mat**: Phase definitions and PVT consistency validated
5. **wells.mat**: Well count and grid connections validated
6. **initial_state.mat**: Equilibrium and saturation consistency validated
7. **schedule.mat**: Time steps and well references validated
8. **solver.mat**: Complete configuration validated

---

## CONCLUSION

The 7 canonical .mat files provide a complete, validated foundation for MRST simulation of the Eagle West Field. Each file serves a specific purpose with clearly defined structure, validation requirements, and cross-file dependencies.

This specification serves as the authoritative reference for all MRST data file operations, ensuring consistency, traceability, and maintainability across the simulation workflow.

---

**Navigation:**
- [Overview](./00_MRST_Data_Catalog_Overview.md)
- [Script-to-File Mapping](./02_Script_to_File_Mapping.md)
- [File Content Specification](./03_File_Content_Specification.md)
- [Data Flow and Dependencies](./04_Data_Flow_and_Dependencies.md)

---
*Canonical File Structure v1.0.0*  
*Last Updated: 2025-08-21 | Next Review: 2025-11-21*