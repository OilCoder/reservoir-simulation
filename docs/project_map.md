# GeomechML Project Map

*Auto-generated on 2025-07-06 19:54:07*

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
├── src/               # Python ML/surrogate code
│   ├── surrogate/     # ML model implementations
│   └── utils/         # Python utilities
├── data/
│   ├── raw/          # Binary simulation outputs (*.mat)
│   └── processed/    # Processed datasets (*.csv)
├── tests/            # Test files mirroring source structure
├── debug/            # Debug scripts (git-ignored)
├── to_dos/           # LLM-generated task lists
├── plots/            # QA/QC visualization outputs
├── docs/
│   ├── English/      # English documentation
│   ├── Spanish/      # Spanish documentation
│   └── ADR/          # Architecture Decision Records
└── .cursor/rules/    # Cursor IDE rules
```

## File Catalog


### sim_scripts/

*Octave simulation scripts using MRST for reservoir modeling*

**create_schedule.m** (Octave)
- create_schedule - Create MRST schedule with wells, controls and timesteps  Creates schedule structure with: - Production and injection wells - Pressure/rate controls - Timestep sequence with rampupTimesteps  Args: G: MRST grid structure rock: MRST rock structure fluid: MRST fluid structure config_file: Optional path to YAML configuration file  Returns: schedule: MRST schedule structure ready for simulation  Requires: MRST % ---- % Step 1 – Load configuration % ----
- Functions: create_schedule
- Role: simulation
- Size: 5590 bytes

**define_fluid.m** (Octave)
- define_fluid - Create fluid structure with viscosities, densities and kr curves  Args: config_file: Optional path to YAML configuration file  Returns MRST fluid structure with: - Oil and water viscosities and densities - Simple relative permeability curves (initSimpleFluid) - Compressibility factors  Returns: fluid: MRST fluid structure ready for simulation  Requires: MRST % ---- % Step 1 – Load configuration % ----
- Functions: define_fluid
- Role: simulation
- Size: 4095 bytes

**define_rock_regions.m** (Octave)
- define_rock_regions - Generate rock.regions vector and assign lithology parameters  Assigns geomechanical parameters (c_φ, n, k₀) by lithology to facilitate scaling to multiple rock types without rewriting setup_field.m  Args: rock: MRST rock structure with existing porosity and permeability  Returns: rock: Updated rock structure with regions and lithology parameters  Requires: MRST % ---- % Step 1 – Rock region classification % ---- Substep 1.1 – Define porosity thresholds ____________________
- Functions: define_rock_regions
- Role: simulation
- Size: 3731 bytes

**export_dataset.m** (Octave)
- export_dataset.m Loop over simulation states, extract snapshots using extract_snapshot, save to data/raw/ directory, and update metadata. Requires: MRST % ---- % Step 1 – Setup and validation % ---- Substep 1.1 – Check required variables ______________________
- Role: simulation
- Size: 7971 bytes

**extract_snapshot.m** (Octave)
- extract_snapshot - Extract 20x20 matrices from simulation state  Extracts and processes simulation data into 20x20 matrices for ML training: - Effective stress (σ') - Porosity (φ) - Permeability (k) - Rock region ID  Args: G: MRST grid structure rock: MRST rock structure with regions state: MRST simulation state for specific timestep timestep: Current timestep number (for reference)  Returns: sigma_eff: 20x20 matrix of effective stress [psi] porosity: 20x20 matrix of current porosity [-] permeability: 20x20 matrix of current permeability [mD] rock_id: 20x20 matrix of rock region IDs [-]  Requires: MRST % ---- % Step 1 – Input validation % ---- Substep 1.1 – Check required inputs __________________________
- Role: simulation
- Size: 5545 bytes

**main_phase1.m** (Octave)
- main_phase1.m Complete Phase 1 workflow orchestrator for MRST geomechanical simulation. Calls all functions in correct order for reproducible simulation execution. Requires: MRST % ---- % Step 1 – Initialize and setup % ---- Substep 1.1 – Clear workspace and initialize ________________
- Role: simulation
- Size: 11185 bytes

**plot_quicklook.m** (Octave)
- plot_quicklook - Quick visualization of simulation results  Creates rapid visualization plots of effective stress, porosity, and permeability to validate heterogeneity and numerical stability after simulation runs.  Args: G: MRST grid structure rock: MRST rock structure states: Cell array of simulation states timestep_idx: Index of timestep to plot (optional, default: last)  Returns: None (creates figure)  Requires: MRST % ---- % Step 1 – Input validation and setup % ---- Substep 1.1 – Check inputs ___________________________________
- Functions: plot_quicklook
- Role: simulation
- Size: 6130 bytes

**run_simulation.m** (Octave)
- run_simulation.m Execute main MRST simulation using simulateScheduleAD and save states in memory. Main orchestrator for flow-compaction simulation. Requires: MRST % ---- % Step 1 – Simulation setup and validation % ---- Substep 1.1 – Check required variables ______________________
- Role: simulation
- Size: 7227 bytes

**setup_field.m** (Octave)
- Build 2D mesh, assign initial porosity ϕ₀ and permeability k₀ (heterogeneous), define rock regions, and set up linear compaction model (pvMultR). Requires: MRST  Args: config_file: Optional path to YAML configuration file  Returns: G: Grid structure rock: Rock properties structure fluid: Fluid properties structure (placeholder) % ---- % Step 1 – Load configuration % ----
- Role: simulation
- Size: 6383 bytes

**util_read_config.m** (Octave)
- util_read_config.m Simple and robust YAML configuration parser for Octave compatibility.
- Functions: util_read_config, set_defaults, parse_value
- Role: simulation
- Size: 8696 bytes


### tests/

*Test files mirroring the source structure (Python and Octave)*

**test_01_sim_scripts_util_read_config.m** (Octave)
- test_01_sim_scripts_util_read_config - Test YAML configuration system  Tests util_read_config.m and configuration-based setup_field functions. Verifies YAML parsing, parameter validation, and configuration modification.  Test functions: - test_config_loading_basic - test_setup_field_with_config - test_config_modification  Requires: MRST
- Functions: test_01_sim_scripts_util_read_config, test_config_loading_basic, test_setup_field_with_config, test_config_modification, write_temp_config
- Role: utility
- Size: 7073 bytes

**test_02_sim_scripts_setup_field.m** (Octave)
- test_02_sim_scripts_setup_field - Test field units configuration system  Tests setup_field.m, define_fluid.m, and create_schedule.m functions with field units (psi, ft, bbl/day) to ensure proper unit handling.  Test functions: - test_field_units_config - test_setup_field_units - test_fluid_definition_units - test_schedule_creation_units  Requires: MRST
- Functions: test_02_sim_scripts_setup_field, test_field_units_config, test_setup_field_units, test_fluid_definition_units, test_schedule_creation_units
- Role: utility
- Size: 6307 bytes

