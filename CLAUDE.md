# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

A geomechanical machine learning project integrating MRST (MATLAB Reservoir Simulation Toolbox) with strict coding standards and validation hooks. The project focuses on reservoir simulation and analysis with enforced code quality.

## Key Commands

### Testing and Validation
```bash
# Run Python tests
pytest tests/

# Validate code compliance  
/validate src/

# Clean up before commit
/cleanup src/s01_load_data.py

# Run linting
ruff check .
pylint src/
pydocstyle src/
```

### MRST/Octave Workflow
```bash
# Run complete MRST workflow
octave mrst_simulation_scripts/s99_run_workflow.m

# Run individual steps
octave mrst_simulation_scripts/s01_initialize_mrst.m
```

## Architecture

### Directory Structure
- `mrst_simulation_scripts/` - MRST/Octave simulation workflow (s01-s15 + s99_run_workflow.m)
- `data/` - Input data and simulation results
- `tests/` - Test files (gitignored, use test_NN_folder_module.py pattern)
- `debug/` - Debug scripts (gitignored, use dbg_*.m pattern)
- `.claude/` - Claude Code configuration, rules, hooks, templates
- `obsidian-vault/` - Documentation in English and Spanish

### MRST Workflow Pipeline
Sequential execution of numbered scripts (s01-s15):
1. **s01_initialize_mrst.m** - Load MRST modules
2. **s02_create_grid.m** - Build reservoir grid
3. **s03_define_fluids.m** - Configure fluid properties
4. **s04_structural_framework.m** - Define geological structure
5. **s05_add_faults.m** - Insert fault systems
6. **s06_grid_refinement.m** - Refine grid near features
7. **s07_define_rock_types.m** - Assign rock properties
8. **s08_assign_layer_properties.m** - Layer-specific properties
9. **s09_spatial_heterogeneity.m** - Add property variations
10. **s10_relative_permeability.m** - Kr curves
11. **s11_capillary_pressure.m** - Pc relationships
12. **s12_pvt_tables.m** - PVT data
13. **s13_pressure_initialization.m** - Initial pressures
14. **s14_saturation_distribution.m** - Initial saturations
15. **s15_aquifer_configuration.m** - Aquifer setup
16. **s99_run_workflow.m** - Main orchestrator

### Configuration System
- YAML configs in `mrst_simulation_scripts/config/`
- Read by `read_yaml_config.m` parser
- Validated against expected parameter ranges

## Critical Rules

### File Naming (STRICTLY ENFORCED)
- **Workflow scripts**: `sNN[x]_<verb>_<noun>.<ext>` (e.g., `s01_load_data.py`)
- **Tests**: `test_NN_<folder>_<module>.py` (e.g., `test_01_src_load_data.py`)
- **Debug**: `dbg_<issue>.m` (e.g., `dbg_convergence_issue.m`)

### Code Style Requirements
- **Function length**: Maximum 40 lines
- **Naming**: snake_case only
- **Comments**: English only, no Spanish in code
- **Docstrings**: Google Style required for all public functions
- **Structure**: Use Step/Substep visual markers:
  ```python
  # ----------------------------------------
  # Step 1 – High-level action
  # ----------------------------------------
  
  # Substep 1.1 – Specific action ______________________
  ```

### Exception Handling Policy
**ALLOWED only for**:
- File I/O operations
- Network operations  
- Optional imports
- OS-level operations

**PROHIBITED for**:
- Flow control
- Input validation
- Data access
- Type conversion

### FAIL FAST Policy
- No defensive programming
- No default values for domain parameters
- Fail immediately with clear error messages
- Never generate workarounds for missing inputs

## Validation Hooks

Automatic validation on file operations:
- **Pre-write**: Validates naming, style, docstrings
- **Post-write**: Checks for print statements, cleanup needs
- **Pre-commit**: Full compliance check

## Custom Claude Code Commands

- `/new-script` - Create workflow script with template
- `/new-test` - Generate test file for module
- `/new-debug` - Create debug script
- `/validate` - Check rule compliance
- `/cleanup` - Remove prints/debug code before commit

## Key Libraries and Dependencies

### Python
- numpy, pandas - Data manipulation
- ruff, pylint, pydocstyle - Linting
- pytest - Testing
- pre-commit - Git hooks

### Octave/MATLAB
- MRST (MATLAB Reservoir Simulation Toolbox) - Core simulation
- Required MRST modules loaded in s01_initialize_mrst.m

## Important Notes

1. **All code must pass validation hooks** - Files will be rejected if they don't comply
2. **No speculative abstractions** - Write only what's needed for the current requirement
3. **Data must come from simulators** - Never hardcode domain values
4. **Tests are mandatory** - Every module needs corresponding tests
5. **English only in code** - Spanish allowed only in obsidian-vault/Spanish/ documentation