# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a **GeomechML** project - a MATLAB Reservoir Simulation Toolbox (MRST) based geomechanical reservoir simulation system with machine learning capabilities for surrogate modeling. The project combines:

- **MRST simulation scripts** (Octave/MATLAB) for reservoir geomechanical modeling
- **Python visualization and monitoring** tools for data analysis and QA/QC
- **Configuration-driven workflow** using YAML files for reproducible simulations

## Architecture

### Core Components

1. **MRST Simulation Engine** (`mrst_simulation_scripts/`)
   - `main.m` - Main workflow orchestrator
   - `a_setup_field.m` - Grid and rock property setup
   - `b_define_fluid.m` - Two-phase oil-water fluid definition
   - `c_define_rock_regions.m` - Rock lithology assignment
   - `d_create_schedule.m` - Wells and timesteps
   - `e_run_simulation.m` - Main simulation execution
   - `f_export_dataset.m` - Optimized data export

2. **Configuration System** (`config/`)
   - `reservoir_config.yaml` - Master configuration file controlling all simulation parameters
   - Grid, porosity, permeability, rock regions, fluid properties, wells, and simulation settings

3. **Monitoring & Visualization** (`monitoring/`)
   - `launch.py` - Main monitoring system launcher
   - `plot_scripts/` - Categorized plotting scripts (A-H categories)
   - `streamlit/app.py` - Interactive dashboard
   - `plots/` - Generated visualization outputs

4. **Data Organization** (`data/`)
   - Optimized structure: `initial/`, `static/`, `temporal/`, `dynamic/`, `metadata/`
   - MATLAB `.mat` files for simulation data
   - Uses oct2py for Python-MATLAB data exchange

## Common Development Commands

### Running Simulations

**Primary simulation workflow:**
```bash
# In Octave/MATLAB
cd mrst_simulation_scripts
main
```

**Individual simulation steps:**
```matlab
cd mrst_simulation_scripts
% Run individual components
test_config                    % Test configuration loading
a_setup_field('config/reservoir_config.yaml')
b_define_fluid('config/reservoir_config.yaml')
% ... etc
```

**Test configuration:**
```matlab
cd mrst_simulation_scripts
test_config
```

**Test directory setup:**
```matlab
cd mrst_simulation_scripts
test_directory_setup
```

### Running Tests

**MRST/Octave tests:**
```matlab
cd test
test_01_sim_scripts_util_read_config
test_02_sim_scripts_setup_field
```

### Monitoring and Visualization

**Launch monitoring system:**
```bash
cd monitoring
python3 launch.py
```

**Run Streamlit dashboard:**
```bash
cd monitoring/streamlit
streamlit run app.py
```

**Launch Jupyter Lab:**
```bash
./start_jupyter.sh
```

**Launch TensorBoard:**
```bash
./start_tensorboard.sh
```

**Individual plot categories:**
```bash
cd monitoring/plot_scripts
python3 plot_category_a_fluid_rock_individual.py
python3 plot_category_b_initial_conditions.py
# ... etc (categories A through H)
```

### MRST Initialization

**Load MRST in Octave:**
```matlab
load_mrst    % Uses load_mrst.m function
```

## Key Workflows

### 1. Configuration-Driven Simulation

All simulation parameters are controlled via `config/reservoir_config.yaml`. Modify this file to change:
- Grid resolution (`nx`, `ny`, `dx`, `dy`)
- Rock properties (porosity, permeability distributions)
- Fluid properties (oil/water densities, viscosities)
- Well locations and operating conditions
- Simulation timing and solver settings

### 2. Data Export Structure

The system exports simulation data to an optimized structure at `data/`:
- `initial/` - Initial conditions
- `static/` - Time-invariant properties  
- `temporal/` - Time series data
- `dynamic/fields/` - Field arrays per timestep
- `dynamic/wells/` - Well performance data
- `metadata/` - Simulation metadata

### 3. Visualization Pipeline

Eight categories of plots (A-H) following the user guide:
- A: Fluid & Rock Properties
- B: Initial Conditions
- C: Geometry & Configuration  
- D: Operations & Scheduling
- E: Global Evolution
- F: Well Performance
- G: Spatial Maps & Animations
- H: Multiphysics & Diagnostics

## Dependencies and Requirements

### MRST Setup
- Requires MRST installation (expected at `/opt/mrst` or relative path)
- Uses `load_mrst.m` for proper initialization
- Octave-compatible MRST workflow

### Python Environment
- Uses `oct2py` for MATLAB-Python data exchange
- Streamlit for interactive dashboards
- Standard scientific Python stack (numpy, matplotlib, etc.)

## Configuration Notes

### Modifying Simulations
1. Edit `config/reservoir_config.yaml`
2. Run `test_config.m` to validate changes
3. Execute `main.m` for full simulation
4. Monitor results via `launch.py` or Streamlit dashboard

### Grid and Domain
- Default: 20x20 Cartesian grid
- Domain size controlled by `dx`, `dy` cell dimensions
- Well locations specified as grid coordinates `[i, j]`

### Geomechanical Coupling
- Enabled by default with stress-dependent porosity/permeability
- Rock regions assigned by porosity thresholds
- Compaction parameters vary by lithology

## File Locations

**Main scripts:** `mrst_simulation_scripts/main.m`
**Configuration:** `config/reservoir_config.yaml`  
**Tests:** `test/test_*.m`
**Monitoring:** `monitoring/launch.py`
**Dashboard:** `monitoring/streamlit/app.py`
**Documentation:** `docs/Spanish/` (comprehensive Spanish user manual)