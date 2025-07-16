# GeomechML Project Map

*Auto-generated on 2025-07-16 02:11:17*

## Overview

This document provides a comprehensive map of the GeomechML project structure, including:
- **Octave simulation scripts** using MRST for reservoir modeling
- **Python machine learning** components for surrogate modeling
- **Test files** ensuring code quality and correctness
- **Documentation** and project organization

## Directory Structure

```
GeomechML/
├── sim_scripts/        # Octave simulation runners with MRST
├── data/
│   ├── raw/          # Binary simulation outputs (*.mat)
│   └── processed/    # Processed datasets (*.csv)
├── tests/            # Test files mirroring source structure
├── debug/            # Debug scripts (git-ignored)
├── docs/
│   ├── English/      # English documentation
│   ├── Spanish/      # Spanish documentation
```

## File Catalog


### monitoring/

*Project files*

**launch.py** (Python)
- MRST Monitoring System - Launch Script

This script launches the MRST monitoring system with categorized plots.
Uses oct2py for proper .mat file reading from the optimized data structure.

Categories:
- A: Fluid & Rock Properties (Individual)
- B: Initial Conditions  
- C: Geometry (Individual)
- D: Operations (Individual)
- E: Global Evolution
- G: Spatial Maps with Well Locations & Animations
- H: Multiphysics

Data Structure:
/workspace/data/
├── initial/
│   └── initial_conditions.mat
├── static/
│   └── static_data.mat
├── temporal/
│   └── time_data.mat
├── dynamic/
│   ├── fields/
│   │   └── field_arrays.mat
│   └── wells/
│       └── well_data.mat
└── metadata/
    └── metadata.mat
- Functions: check_oct2py_installation, check_data_structure, run_category_script, run_all_categories, main
- Role: utility
- Size: 6905 bytes


### monitoring/plot_scripts/

*Project files*

**plot_category_a_fluid_rock_individual.py** (Python)
- Category A: Fluid & Rock Properties (Individual Plots)

Generates individual plots based on user guide:
A-1: Curvas de kr,w, kr,o(Sw) - Relative permeability curves
A-2: Propiedades PVT (P vs B or μ, colored by phase) - PVT properties
A-3: Histogramas φ₀ y k₀ (value vs frequency) - Porosity and permeability histograms
A-4: Cross-plot log k vs φ (colored by σ′) - Permeability vs porosity cross-plot

Uses oct2py for proper .mat file reading from optimized data structure.
- Functions: plot_a1_kr_curves, plot_a2_pvt_properties, plot_a3_porosity_histogram, plot_a3_permeability_histogram, plot_a4_k_phi_crossplot, main
- Role: utility
- Size: 22160 bytes

**plot_category_b_initial_conditions.py** (Python)
- Category B: Initial Conditions - REQUIRES REAL MRST DATA

Generates individual plots for initial reservoir conditions:
B-1: Initial water saturation distribution map - REQUIRES REAL DATA
B-2: Initial pressure distribution map - REQUIRES REAL DATA

IMPORTANT: This script now requires real MRST simulation data.
No synthetic data generation. Will fail if data is not available.
Uses oct2py for proper .mat file reading.
- Functions: reshape_to_grid, plot_sw_initial, plot_pressure_initial, main
- Role: utility
- Size: 12195 bytes

**plot_category_c_geometry_individual.py** (Python)
- Category C: Geometry & Configuration (Individual Plots)

Generates individual plots for reservoir geometry and well configuration:
C-1: Well locations map (XY plane)
C-2: Rock regions map (proposed)
C-3: Well completion intervals (proposed)
- Functions: plot_c1_well_locations, plot_c2_rock_regions, plot_c3_well_completions, main
- Role: utility
- Size: 9577 bytes

**plot_category_d_operations_individual.py** (Python)
- Category D: Operations & Scheduling - REQUIRES REAL MRST DATA

Generates individual plots for operational parameters:
D-1: Rate schedule (time vs rate by phase/well) - REQUIRES REAL MRST DATA
D-2: BHP limits (time vs pressure constraints) - REQUIRES REAL MRST DATA
D-3: Voidage ratio (time vs volume balance) - REQUIRES REAL MRST DATA
D-4: PV injected vs Recovery factor - REQUIRES REAL MRST DATA

Uses optimized data loader with oct2py for proper .mat file reading.
- Functions: plot_d1_rate_schedule, plot_d2_bhp_limits, plot_d3_voidage_ratio, plot_d4_pv_vs_recovery, main
- Role: utility
- Size: 19810 bytes

**plot_category_e_global_evolution.py** (Python)
- Category E: Global Evolution (Time Series) - REQUIRES REAL MRST DATA

Generates individual plots for reservoir-wide evolution:
E-1: Pressure evolution (average + range) - REQUIRES REAL MRST DATA
E-2: Effective stress evolution - REQUIRES REAL MRST DATA  
E-3: Porosity evolution - REQUIRES REAL MRST DATA
E-4: Permeability evolution - REQUIRES REAL MRST DATA
E-5: Water saturation histogram evolution - REQUIRES REAL MRST DATA

Uses optimized data loader with oct2py for proper .mat file reading.
- Functions: plot_pressure_evolution, plot_stress_evolution, plot_porosity_evolution, plot_permeability_evolution, plot_saturation_histogram_evolution, main
- Role: utility
- Size: 23295 bytes

**plot_category_f_well_performance.py** (Python)
- Category F: Well Performance (Individual Plots)

Generates individual plots for well performance analysis:
F-1: BHP por pozo (time vs BHP, colored by well) - Bottom hole pressure evolution
F-2: Tasas instantáneas qₒ, qw (time vs rates, colored by phase) - Instantaneous rates
F-3: Producción acumulada (time vs cumulative, colored by well) - Cumulative production
F-4: Water-cut (time vs water cut, colored by well) - Water cut evolution

Uses oct2py for proper .mat file reading from optimized data structure.
- Functions: plot_f1_bhp_by_well, plot_f2_instantaneous_rates, plot_f3_cumulative_production, plot_f4_water_cut, main
- Role: utility
- Size: 19838 bytes

**plot_category_g_maps_animated.py** (Python)
- Category G: Spatial Maps with Well Locations & Animated GIFs - REQUIRES REAL MRST DATA

Generates individual maps and animations based on user guide:
G-1: Mapas de presión (with well locations) - REQUIRES REAL MRST DATA
G-2: Mapas de esfuerzo efectivo (with well locations) - REQUIRES REAL MRST DATA
G-3: Mapas de porosidad (with well locations) - REQUIRES REAL MRST DATA
G-4: Mapas de permeabilidad (with well locations) - REQUIRES REAL MRST DATA
G-5: Mapas de saturación de agua (with well locations) - REQUIRES REAL MRST DATA
G-6: Mapas de cambio de presión ΔP = p - p₀ - REQUIRES REAL MRST DATA
G-7: Frente de agua Sw ≥ 0.8 - REQUIRES REAL MRST DATA

Uses oct2py for proper .mat file reading from optimized data structure.
- Functions: parse_octave_mat_file, load_initial_setup, load_all_snapshots, get_well_locations_local, add_wells_to_plot, reshape_to_grid, plot_g1_pressure_map, plot_g2_stress_map, plot_g3_porosity_map, plot_g4_permeability_map, plot_g5_saturation_map, main, animate_frame, animate_frame
- Role: utility
- Size: 27442 bytes

**plot_category_h_multiphysics.py** (Python)
- Category H: Multiphysics & Diagnostics - THEORETICAL AND REAL DATA

Generates individual plots for advanced multiphysics analysis:
H-1: Flujo fraccional fw(Sw) - THEORETICAL CURVES (OK - based on physics)
H-2: Análisis de sensibilidad tornado - REQUIRES REAL MRST DATA

Uses oct2py for proper .mat file reading from optimized data structure.
- Functions: parse_octave_mat_file, load_schedule_data_local, plot_fractional_flow, plot_kr_sensitivity, plot_h2_tornado_sensitivity, plot_voidage_ratio_evolution, main
- Role: utility
- Size: 20381 bytes

**util_data_loader.py** (Python)
- MRST Data Loader - Optimized Structure with oct2py

This module provides functions to load data from the optimized MRST export structure
using oct2py for proper .mat file reading.

Data Structure:
/workspace/data/
├── initial/
│   └── initial_conditions.mat
├── static/
│   ├── static_data.mat
│   └── fluid_properties.mat
├── temporal/
│   ├── time_data.mat
│   └── schedule_data.mat
├── dynamic/
│   ├── fields/
│   │   ├── field_arrays.mat
│   │   └── flow_data.mat
│   └── wells/
│       ├── well_data.mat
│       └── cumulative_data.mat
├── sensitivity/
│   └── sensitivity_data.mat
└── metadata/
    └── metadata.mat
- Functions: check_data_availability, print_data_summary, load_initial_conditions, load_static_data, load_temporal_data, load_field_arrays, load_well_data, load_metadata, load_fluid_properties, load_schedule_data, load_cumulative_data, load_flow_data, load_sensitivity_data, load_reservoir_data, load_dynamic_fields, get_well_locations, calculate_water_cut, calculate_voidage_ratio, calculate_fractional_flow
- Role: utility
- Size: 19978 bytes


### monitoring/streamlit/

*Project files*

**app.py** (Python)
- Role: utility
- Size: 18688 bytes

**utils.py** (Python)
- Utilities for MRST Monitoring Dashboard

Simple utility functions for the Streamlit dashboard.
- Functions: get_data_path, get_plot_path, plot_exists, get_plot_age_minutes, count_snapshots, get_latest_timestep, format_plot_status
- Role: utility
- Size: 1928 bytes


### mrst_simulation_scripts/

*Project files*

**s00_initialize_mrst.m** (Octave)
- initialize_mrst - Initialize MRST environment for Octave  Initializes MRST core, loads required modules, and verifies functions are available for simulation execution.  Args: None  Returns: None (sets up MRST environment)  Requires: MRST % ---- % Step 1 – Initialize MRST properly for Octave % ----
- Functions: initialize_mrst
- Role: utility
- Size: 2503 bytes

**s01_setup_field.m** (Octave)
- a_setup_field - Create MRST grid and rock properties from configuration  Creates 20x20 cartesian grid with heterogeneous porosity and permeability based on reservoir configuration file. Uses MRST functions exclusively.  Args: config_file: Path to YAML configuration file  Returns: G: MRST grid structure rock: MRST rock structure with porosity and permeability fluid: Empty fluid structure (placeholder)  Requires: MRST % ---- % Step 1 – Load configuration % ---- Substep 1.1 – Read configuration file ________________________
- Role: utility
- Size: 3723 bytes

**s02_define_fluid.m** (Octave)
- b_define_fluid - Create MRST fluid structure from configuration  Creates two-phase oil-water fluid with properties from configuration. Uses MRST initSimpleFluid function with realistic relative permeability curves.  Args: config_file: Path to YAML configuration file  Returns: fluid: MRST fluid structure with oil-water properties  Requires: MRST % ---- % Step 1 – Load configuration % ---- Substep 1.1 – Read configuration file ________________________
- Functions: b_define_fluid, interpTable
- Role: utility
- Size: 4743 bytes

**s03_define_rock_regions.m** (Octave)
- c_define_rock_regions - Generate rock.regions vector and assign lithology parameters  Assigns geomechanical parameters (c_φ, n, k₀) by lithology to facilitate scaling to multiple rock types without rewriting setup_field.m  Args: rock: MRST rock structure with existing porosity and permeability  Returns: rock: Updated rock structure with regions and lithology parameters  Requires: MRST % ---- % Step 1 – Rock region classification % ---- Substep 1.1 – Define porosity thresholds ____________________
- Functions: c_define_rock_regions
- Role: utility
- Size: 3735 bytes

**s04_create_schedule.m** (Octave)
- d_create_schedule - Create MRST simulation schedule with wells and timesteps  Creates schedule with producer and injector wells based on configuration. Uses MRST functions for well creation and schedule setup.  Args: G: MRST grid structure rock: MRST rock structure fluid: MRST fluid structure config_file: Path to YAML configuration file  Returns: schedule: MRST schedule structure with wells and timesteps  Requires: MRST % ---- % Step 1 – Load configuration % ---- Substep 1.1 – Read configuration file ________________________
- Functions: d_create_schedule
- Role: utility
- Size: 3105 bytes

**s05_run_simulation.m** (Octave)
- e_run_simulation.m Execute main MRST simulation using simulateScheduleAD and save states in memory. Main orchestrator for flow-compaction simulation. Requires: MRST % ---- % Step 1 – Simulation setup and validation % ---- Substep 1.1 – Check required variables ______________________
- Role: utility
- Size: 2858 bytes

**s06_export_dataset.m** (Octave)
- f_export_dataset.m Optimized MRST data export system with deduplication and organized structure Exports to: ../data/ with optimized folder organization Requires: MRST % ---- % Step 1 – Setup and validation % ---- Substep 1.1 – Check required variables ______________________
- Role: utility
- Size: 6338 bytes

**s07a_setup_components.m** (Octave)
- setup_simulation_components - Setup all simulation components  Creates grid, rock, fluid, and schedule structures for MRST simulation workflow execution.  Args: config_file: Path to YAML configuration file  Returns: G: MRST grid structure rock: MRST rock structure with regions fluid: MRST fluid structure schedule: MRST schedule structure timing: Structure with timing information  Requires: MRST
- Role: utility
- Size: 2317 bytes

**s07b_setup_state.m** (Octave)
- setup_simulation_state - Initialize simulation state and configuration  Sets up initial pressure and saturation state for MRST simulation and loads configuration parameters.  Args: G: MRST grid structure rock: MRST rock structure  Returns: state0: Initial simulation state config: Configuration structure  Requires: MRST % ---- % Step 1 – Load configuration and set initial conditions % ----
- Role: utility
- Size: 1266 bytes

**s08_run_workflow_steps.m** (Octave)
- run_workflow_steps - Execute simulation and export workflow  Runs the MRST simulation and exports the results using the optimized data structure.  Args: G: MRST grid structure rock: MRST rock structure fluid: MRST fluid structure schedule: MRST schedule structure  Returns: states: Cell array of simulation states wellSols: Cell array of well solutions simulation_time: Time taken for simulation export_time: Time taken for data export  Requires: MRST % ---- % Step 1 – Simulation execution % ----
- Role: utility
- Size: 1409 bytes

**s09_execute_simulation_loop.m** (Octave)
- execute_simulation_loop - Run main simulation loop  Executes the main MRST simulation loop with simplified incompressible flow and compaction effects.  Args: G: MRST grid structure rock: MRST rock structure fluid: MRST fluid structure schedule: MRST schedule structure state0: Initial simulation state config: Configuration structure  Returns: states: Cell array of simulation states wellSols: Cell array of well solutions sim_time: Simulation execution time  Requires: MRST % ---- % Step 1 – Initialize simulation loop % ----
- Role: utility
- Size: 3392 bytes

**s10_calculate_volumetric_data.m** (Octave)
- calculate_volumetric_data - Calculate and export volumetric data  Calculates cumulative production/injection, recovery factors, and flow velocities for dashboard visualization.  Args: G: MRST grid structure rock: MRST rock structure fluid: MRST fluid structure schedule: MRST schedule structure states: Cell array of simulation states wellSols: Cell array of well solutions config: Configuration structure  Returns: None (exports data to files)  Requires: MRST % ---- % Step 1 – Calculate cumulative production/injection % ---- Initialize cumulative arrays
- Functions: calculate_volumetric_data
- Role: utility
- Size: 6013 bytes

**s11a_export_initial_conditions.m** (Octave)
- export_initial_conditions - Export initial reservoir conditions  Exports initial pressure, saturation, porosity, and permeability to the optimized data structure.  Args: G: MRST grid structure rock: MRST rock structure states: Cell array of simulation states base_dir: Base directory for data export  Returns: None (exports data to file)  Requires: MRST
- Functions: export_initial_conditions
- Role: utility
- Size: 1965 bytes

**s11b_export_static_data.m** (Octave)
- export_static_data - Export static reservoir data  Exports rock regions, grid geometry, and well locations to the optimized data structure.  Args: G: MRST grid structure rock: MRST rock structure schedule: MRST schedule structure base_dir: Base directory for data export  Returns: None (exports data to file)  Requires: MRST
- Functions: export_static_data
- Role: utility
- Size: 2240 bytes

**s11c_export_dynamic_fields.m** (Octave)
- export_dynamic_fields - Export dynamic field arrays  Exports 3D arrays of pressure, saturation, porosity, permeability, and effective stress to the optimized data structure.  Args: G: MRST grid structure rock: MRST rock structure states: Cell array of simulation states base_dir: Base directory for data export  Returns: None (exports data to file)  Requires: MRST
- Functions: export_dynamic_fields
- Role: utility
- Size: 2694 bytes

**s11d_export_metadata.m** (Octave)
- export_metadata - Export comprehensive dataset metadata  Creates comprehensive metadata with dataset information, simulation parameters, data structure details, and optimization information.  Args: G: MRST grid structure schedule: MRST schedule structure temporal_data: Temporal data structure n_wells: Number of wells fields_file: Path to fields file for size calculation base_dir: Base directory for data export  Returns: None (exports metadata to file)  Requires: MRST
- Functions: export_metadata
- Role: utility
- Size: 5060 bytes

**s12_extract_snapshot.m** (Octave)
- extract_snapshot - Extract 20x20 matrices from simulation state  Extracts and processes simulation data into 20x20 matrices for ML training: - Effective stress (σ') - Porosity (φ) - Permeability (k) - Rock region ID  Args: G: MRST grid structure rock: MRST rock structure with regions state: MRST simulation state for specific timestep timestep: Current timestep number (for reference)  Returns: sigma_eff: 20x20 matrix of effective stress [psi] porosity: 20x20 matrix of current porosity [-] permeability: 20x20 matrix of current permeability [mD] rock_id: 20x20 matrix of rock region IDs [-]  Requires: MRST % ---- % Step 1 – Input validation % ---- Substep 1.1 – Check required inputs __________________________
- Role: utility
- Size: 5553 bytes

**s13_generate_completion_report.m** (Octave)
- generate_completion_report - Generate final workflow completion report  Creates a comprehensive report of the simulation workflow execution including timing, results summary, and validation status.  Args: G: MRST grid structure rock: MRST rock structure with regions states: Cell array of simulation states schedule: MRST schedule structure timing: Structure with timing information all_vars_exist: Boolean indicating if all variables exist  Returns: None (prints completion report)  Requires: MRST % ---- % Step 1 – Calculate total workflow time % ----
- Functions: generate_completion_report
- Role: utility
- Size: 3398 bytes

**s14_sensitivity_analysis.m** (Octave)
- sensitivity_analysis.m Run multiple MRST simulations with varied parameters for sensitivity analysis Generates tornado plot data for dashboard visualization Requires: MRST % ---- % Step 1 – Setup and validation % ---- Substep 1.1 – Load configuration _____________________________
- Role: utility
- Size: 11334 bytes

**s99_run_workflow.m** (Octave)
- main.m Complete workflow orchestrator for MRST geomechanical simulation  Calls all functions in correct order for reproducible simulation execution. Requires: MRST
- Functions: main, validate_workflow_results
- Role: utility
- Size: 3954 bytes

**util_ensure_directories.m** (Octave)
- util_ensure_directories - Ensure all required directories exist  Creates all necessary directories for MRST simulation workflow including data storage, plots, and temporary files. Provides detailed logging of directory creation status.  Args: None  Returns: None (creates directories as needed)  Requires: None (pure Octave/MATLAB) % ---- % Step 1 – Define required directories % ---- Substep 1.1 – List all required directories __________________ Updated for optimized data structure
- Functions: util_ensure_directories
- Role: utility
- Size: 3559 bytes

**util_read_config.m** (Octave)
- util_read_config.m Simple and robust YAML parser for Octave Extracts only the actual values, ignoring comments
- Functions: util_read_config
- Role: utility
- Size: 3911 bytes


### tests/

*Test files mirroring the source structure (Python and Octave)*

**test_01_mrst_simulation_scripts_util_read_config.m** (Octave)
- test_config.m Simple test to debug configuration reading
- Role: utility
- Size: 760 bytes

**test_02_mrst_simulation_scripts_util_ensure_directories.m** (Octave)
- test_directory_setup.m Test script to verify directory setup functionality Requires: util_ensure_directories.m % ---- % Step 1 – Clean test environment % ----
- Role: utility
- Size: 2342 bytes

