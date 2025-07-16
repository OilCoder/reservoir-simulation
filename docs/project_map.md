# GeomechML Project Map

*Auto-generated on 2025-07-16 18:16:21*

## Overview

This document provides a comprehensive map of the GeomechML project structure, including:
- **Octave simulation scripts** using MRST for reservoir modeling
- **Python machine learning** components for surrogate modeling
- **Test files** ensuring code quality and correctness
- **Documentation** and project organization

## Directory Structure

```
GeomechML/
├── mrst_simulation_scripts/        # Octave simulation runners with MRST
├── data/
├── tests/            # Test files mirroring source structure
├── debug/            # Debug scripts (git-ignored)
├── docs/
    ├── English/      # English documentation
    ├── Spanish/      # Spanish documentation
```

## File Catalog


### dashboard/

*Interactive Streamlit dashboard for MRST simulation visualization*

**s99_run_dashboard.py** (Python)
- MRST Simulation Results Dashboard Launcher

This script launches an interactive Streamlit dashboard for visualizing
MRST geomechanical simulation results. The dashboard provides user-accessible
information about reservoir simulation data following product owner requirements.

The dashboard leverages the existing conda environment with streamlit and oct2py
for proper MAT file reading from MRST simulation outputs.
- Functions: load_simulation_data, main, show_simulation_overview, show_reservoir_properties, show_production_performance, show_pressure_evolution, show_flow_analysis
- Role: utility
- Size: 14220 bytes

**util_data_loader.py** (Python)
- MRST Simulation Data Loader

Loads and processes MRST simulation data from MAT files following the
data generation policy. All data originates from MRST simulator authority
with proper traceability and no hard-coded values.
- Functions: __init__, _define_file_structure, check_data_availability, load_initial_conditions, load_static_data, load_field_arrays, load_flow_data, load_well_data, load_cumulative_data, load_metadata, load_complete_dataset
- Role: utility
- Size: 12548 bytes

**util_metrics.py** (Python)
- Performance Metrics Calculator

Calculates key performance indicators and metrics from MRST simulation data.
All calculations follow reservoir engineering principles and provide
product owner focused metrics for decision making.
- Functions: __init__, calculate_key_performance_indicators, calculate_recovery_efficiency, _calculate_sweep_efficiency, calculate_production_performance, _calculate_decline_rate, calculate_pressure_performance, calculate_injection_efficiency, calculate_flow_performance, calculate_comprehensive_metrics
- Role: utility
- Size: 12714 bytes

**util_visualization.py** (Python)
- Dashboard Visualization Utilities

Creates interactive visualizations for MRST simulation results using Plotly.
All visualizations follow product owner requirements for user-accessible
information display with proper styling and interactivity.
- Functions: __init__, _define_color_schemes, create_pressure_heatmap, create_saturation_heatmap, create_porosity_heatmap, create_permeability_heatmap, create_velocity_heatmap, create_property_histogram, create_production_rates_plot, create_injection_rates_plot, create_cumulative_production_plot, create_recovery_factor_plot, create_pressure_evolution_plot, create_velocity_evolution_plot
- Role: utility
- Size: 16294 bytes


### mrst_simulation_scripts/

*Project files*

**s00_initialize_mrst.m** (Octave)
- s00_initialize_mrst - Initialize MRST environment for Octave  Initializes MRST core, loads required modules, and verifies functions are available for simulation execution.  Args: None  Returns: None (sets up MRST environment)  Requires: MRST ---------------------------------------- Step 1 – MRST Core Detection and Loading ----------------------------------------
- Functions: s00_initialize_mrst
- Role: utility
- Size: 2124 bytes

**s01_setup_field.m** (Octave)
- s01_setup_field - Create MRST grid and rock properties from configuration  Creates 20x20 cartesian grid with heterogeneous porosity and permeability based on reservoir configuration file. Uses MRST functions exclusively.  Args: config_file: Path to YAML configuration file  Returns: G: MRST grid structure rock: MRST rock structure with porosity and permeability fluid: Empty fluid structure (placeholder)  Requires: MRST % ---- % Step 1 – Load configuration % ---- Substep 1.1 – Read configuration file ________________________
- Role: utility
- Size: 3736 bytes

**s02_define_fluid.m** (Octave)
- s02_define_fluid - Create MRST fluid structure from configuration  Creates two-phase oil-water fluid with properties from configuration. Uses MRST initSimpleFluid function with realistic relative permeability curves.  Args: config_file: Path to YAML configuration file  Returns: fluid: MRST fluid structure with oil-water properties  Requires: MRST % ---- % Step 1 – Load configuration % ---- Substep 1.1 – Read configuration file ________________________
- Functions: s02_define_fluid, interpTable
- Role: utility
- Size: 4917 bytes

**s03_define_rock_regions.m** (Octave)
- s03_define_rock_regions - Generate rock.regions vector and assign lithology parameters  Assigns geomechanical parameters (c_φ, n, k₀) by lithology to facilitate scaling to multiple rock types without rewriting setup_field.m  Args: rock: MRST rock structure with existing porosity and permeability  Returns: rock: Updated rock structure with regions and lithology parameters  Requires: MRST % ---- % Step 1 – Rock region classification % ---- Substep 1.1 – Define porosity thresholds ____________________
- Functions: s03_define_rock_regions
- Role: utility
- Size: 3739 bytes

**s04_create_schedule.m** (Octave)
- s04_create_schedule - Create MRST simulation schedule with wells and timesteps  Creates schedule with producer and injector wells based on configuration. Uses MRST functions for well creation and schedule setup.  Args: G: MRST grid structure rock: MRST rock structure fluid: MRST fluid structure config_file: Path to YAML configuration file  Returns: schedule: MRST schedule structure with wells and timesteps  Requires: MRST % ---- % Step 1 – Load configuration % ---- Substep 1.1 – Read configuration file ________________________
- Functions: s04_create_schedule
- Role: utility
- Size: 3269 bytes

**s05_run_simulation.m** (Octave)
- s05_run_simulation - Execute main MRST simulation using simulateScheduleAD  Execute main MRST simulation using simulateScheduleAD and save states in memory. Main orchestrator for flow-compaction simulation.  Args: G: MRST grid structure rock: MRST rock structure fluid: MRST fluid structure schedule: MRST schedule structure  Returns: states: Cell array of simulation states wellSols: Cell array of well solutions  Requires: MRST % ---- % Step 1 – Simulation setup and validation % ----
- Role: utility
- Size: 3028 bytes

**s06_export_dataset.m** (Octave)
- s06_export_dataset - Optimized MRST data export system with deduplication and organized structure  Exports simulation results to: ../data/ with optimized folder organization  Args: G: MRST grid structure rock: MRST rock structure fluid: MRST fluid structure schedule: MRST schedule structure states: Cell array of simulation states wellSols: Cell array of well solutions  Returns: None (exports data to files)  Requires: MRST % ---- % Step 1 – Setup and validation % ---- Substep 1.1 – Create optimized directory structure ___________
- Functions: s06_export_dataset
- Role: utility
- Size: 6451 bytes

**s07a_setup_components.m** (Octave)
- s07a_setup_components - Setup all simulation components  Creates grid, rock, fluid, and schedule structures for MRST simulation workflow execution.  Args: config_file: Path to YAML configuration file  Returns: G: MRST grid structure rock: MRST rock structure with regions fluid: MRST fluid structure schedule: MRST schedule structure timing: Structure with timing information  Requires: MRST
- Role: utility
- Size: 2313 bytes

**s07b_setup_state.m** (Octave)
- setup_simulation_state - Initialize simulation state and configuration  Sets up initial pressure and saturation state for MRST simulation and loads configuration parameters.  Args: G: MRST grid structure rock: MRST rock structure  Returns: state0: Initial simulation state config: Configuration structure  Requires: MRST % ---- % Step 1 – Load configuration and set initial conditions % ----
- Role: utility
- Size: 1260 bytes

**s08_run_workflow_steps.m** (Octave)
- s08_run_workflow_steps - Execute simulation and export workflow  Runs the MRST simulation and exports the results using the optimized data structure.  Args: G: MRST grid structure rock: MRST rock structure fluid: MRST fluid structure schedule: MRST schedule structure  Returns: states: Cell array of simulation states wellSols: Cell array of well solutions simulation_time: Time taken for simulation export_time: Time taken for data export  Requires: MRST % ---- % Step 1 – Simulation execution % ----
- Role: utility
- Size: 1512 bytes

**s09_execute_simulation_loop.m** (Octave)
- execute_simulation_loop - Run main simulation loop  Executes the main MRST simulation loop with simplified incompressible flow and compaction effects.  Args: G: MRST grid structure rock: MRST rock structure fluid: MRST fluid structure schedule: MRST schedule structure state0: Initial simulation state config: Configuration structure  Returns: states: Cell array of simulation states wellSols: Cell array of well solutions sim_time: Simulation execution time  Requires: MRST % ---- % Step 1 – Initialize simulation loop % ----
- Role: utility
- Size: 3396 bytes

**s10_calculate_volumetric_data.m** (Octave)
- calculate_volumetric_data - Calculate and export volumetric data  Calculates cumulative production/injection, recovery factors, and flow velocities for dashboard visualization.  Args: G: MRST grid structure rock: MRST rock structure fluid: MRST fluid structure schedule: MRST schedule structure states: Cell array of simulation states wellSols: Cell array of well solutions config: Configuration structure  Returns: None (exports data to files)  Requires: MRST % ---- % Step 1 – Calculate cumulative production/injection % ---- Initialize cumulative arrays
- Functions: s10_calculate_volumetric_data
- Role: utility
- Size: 6017 bytes

**s11a_export_initial_conditions.m** (Octave)
- export_initial_conditions - Export initial reservoir conditions  Exports initial pressure, saturation, porosity, and permeability to the optimized data structure.  Args: G: MRST grid structure rock: MRST rock structure states: Cell array of simulation states base_dir: Base directory for data export  Returns: None (exports data to file)  Requires: MRST
- Functions: s11a_export_initial_conditions
- Role: utility
- Size: 2050 bytes

**s11b_export_static_data.m** (Octave)
- export_static_data - Export static reservoir data  Exports rock regions, grid geometry, and well locations to the optimized data structure.  Args: G: MRST grid structure rock: MRST rock structure schedule: MRST schedule structure base_dir: Base directory for data export  Returns: None (exports data to file)  Requires: MRST
- Functions: s11b_export_static_data
- Role: utility
- Size: 2245 bytes

**s11c_export_dynamic_fields.m** (Octave)
- export_dynamic_fields - Export dynamic field arrays  Exports 3D arrays of pressure, saturation, porosity, permeability, and effective stress to the optimized data structure.  Args: G: MRST grid structure rock: MRST rock structure states: Cell array of simulation states base_dir: Base directory for data export  Returns: None (exports data to file)  Requires: MRST
- Functions: s11c_export_dynamic_fields
- Role: utility
- Size: 2703 bytes

**s11d_export_metadata.m** (Octave)
- s11d_export_metadata - Export comprehensive dataset metadata  Creates comprehensive metadata with dataset information, simulation parameters, data structure details, and optimization information.  Args: G: MRST grid structure schedule: MRST schedule structure temporal_data: Temporal data structure n_wells: Number of wells fields_file: Path to fields file for size calculation base_dir: Base directory for data export  Returns: None (exports metadata to file)  Requires: MRST
- Functions: s11d_export_metadata
- Role: utility
- Size: 5215 bytes

**s12_extract_snapshot.m** (Octave)
- extract_snapshot - Extract 20x20 matrices from simulation state  Extracts and processes simulation data into 20x20 matrices for ML training: - Effective stress (σ') - Porosity (φ) - Permeability (k) - Rock region ID  Args: G: MRST grid structure rock: MRST rock structure with regions state: MRST simulation state for specific timestep timestep: Current timestep number (for reference)  Returns: sigma_eff: 20x20 matrix of effective stress [psi] porosity: 20x20 matrix of current porosity [-] permeability: 20x20 matrix of current permeability [mD] rock_id: 20x20 matrix of rock region IDs [-]  Requires: MRST % ---- % Step 1 – Input validation % ---- Substep 1.1 – Check required inputs __________________________
- Role: utility
- Size: 5557 bytes

**s13_generate_completion_report.m** (Octave)
- generate_completion_report - Generate final workflow completion report  Creates a comprehensive report of the simulation workflow execution including timing, results summary, and validation status.  Args: None (loads variables from data files)  Returns: None (prints completion report)  Requires: MRST Load all required variables from data files
- Functions: s13_generate_completion_report
- Role: utility
- Size: 3993 bytes

**s14_sensitivity_analysis.m** (Octave)
- sensitivity_analysis.m Run multiple MRST simulations with varied parameters for sensitivity analysis Generates tornado plot data for dashboard visualization Requires: MRST % ---- % Step 1 – Setup and validation % ---- Substep 1.1 – Load configuration _____________________________
- Role: utility
- Size: 11334 bytes

**s99_run_workflow.m** (Octave)
- main.m Complete workflow orchestrator for MRST geomechanical simulation  Calls all functions in correct order for reproducible simulation execution. Requires: MRST
- Functions: s99_run_workflow, validate_workflow_results
- Role: utility
- Size: 4182 bytes

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

