# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**GeomechML** is a reservoir simulation and machine learning system that integrates MATLAB/Octave with MRST (MATLAB Reservoir Simulation Toolbox) to generate synthetic datasets for training ML models that predict geomechanical properties in oil & gas reservoirs.

## Development Environment

The project uses a VSCode dev container with:
- CUDA 12.4.1 for GPU acceleration
- Octave + MRST for reservoir simulation
- Python ML stack in conda environment `simulation`
- Streamlit dashboard for data visualization

## AI Code Governance System

This project implements a **deterministic code generation system** in `.claude/` that transforms traditional AI-assisted development:

### Core Philosophy
- **Prevention over Correction**: Block violations before code generation, not after
- **Complete Determinism**: 100% compliance with project standards guaranteed
- **Self-Validation**: System applies its own rules to its own code
- **Complete Traceability**: Full audit trail of every code generation session

### System Architecture
```
UserPrompt → Context Injection → [Orchestration] → Pre-Validation → Code Generation → Post-Processing → Metadata Tracking
```

### Key Components
- **Rules System** (`.claude/rules/`): 9 comprehensive coding standards
- **Validation Pipeline** (`.claude/tools/`): 10 specialized validators with 4-layer architecture
- **MCP Integration** (`.claude/.mcp.json`): 6 servers for extended capabilities
- **Orchestration System**: Parallel subagent coordination with sequential thinking
- **Complete Metadata**: Git integration, environment capture, session tracking

### Workflow Documentation
See `flujo_trabajo_generacion_codigo.md` for complete technical analysis including Mermaid diagrams.

## Key Commands

### Run Complete Simulation
```bash
# Navigate to simulation scripts and run complete workflow
cd mrst_simulation_scripts
octave --eval "s99_run_workflow()"
```

### Launch Interactive Dashboard
```bash
# Start Streamlit visualization dashboard
streamlit run dashboard/dashboard.py
```

### Run Tests
```bash
# Test configuration parsing
cd test
octave --eval "test_01_sim_scripts_util_read_config()"

# Test field setup
octave --eval "test_02_sim_scripts_setup_field()"
```

### Configuration Management
```bash
# Edit main reservoir parameters
nano config/reservoir_config.yaml
```

## Architecture

### Core Components

1. **MRST Simulation Engine** (`mrst_simulation_scripts/`)
   - 20 sequential MATLAB/Octave scripts (s00-s13, s99)
   - Modular workflow: initialization → grid setup → simulation → data export
   - 3D geomechanical reservoir simulation (20×20×10 grid)

2. **Configuration System** (`config/`)
   - YAML-based parameter configuration (`reservoir_config.yaml`)
   - Custom YAML parser in pure Octave (`util_read_config.m`)
   - No hardcoded simulation parameters

3. **Data Management** (`data/`)
   - Structured export: `initial/`, `static/`, `dynamic/`, `temporal/`, `metadata/`
   - MATLAB format optimized for Python ML compatibility
   - Complete simulation results (~620KB per run)

4. **Visualization Dashboard** (`dashboard/`)
   - Python Streamlit application with 64 visualization modules
   - Hierarchical plotting organization by analysis type
   - Real-time data analysis capabilities

### Simulation Workflow

Sequential execution pattern:
- **s00**: Initialize MRST environment
- **s01**: Setup 3D reservoir grid and rock properties  
- **s02**: Define two-phase oil-water fluid system
- **s03**: Create rock regions with geomechanical parameters
- **s04**: Configure wells and simulation schedule
- **s05**: Execute MRST simulation
- **s06**: Export structured datasets for ML training
- **s07a-s13**: Component setup and data processing

### Data Generation Policy

- All data originates from MRST simulator (no synthetic/hardcoded values except physical constants)
- Configuration-driven parameters via `reservoir_config.yaml`
- Complete traceability through metadata
- Field units: psi, ft, mD, bbl/day

## File Structure

```
mrst_simulation_scripts/    # Core simulation workflow (20 scripts)
config/                     # YAML configuration system  
data/                       # Structured simulation outputs
dashboard/                  # Python visualization dashboard
test/                       # Automated testing framework
debug/                      # Development utilities
docs/                       # Comprehensive documentation
```

## Key Configuration Parameters

In `config/reservoir_config.yaml`:
- **Grid**: 20×20×10 cells, variable layer thickness
- **Wells**: Producer/injector configuration with rates/pressures
- **Geomechanics**: Stress-dependent porosity and permeability
- **Time**: 3650 days (10 years) with 500 timesteps
- **Output**: 5 dynamic fields (pressure, saturation, porosity, permeability, effective stress)

## Development Notes

- Python interpreter: `/opt/conda/envs/simulation/bin/python`
- Container automatically activates `simulation` conda environment
- MRST must be initialized before running simulations
- All reservoir parameters should be modified via YAML config, not in code
- Testing framework validates configuration parsing and field setup
- Data export format designed for direct Python ML library consumption