# VARIABLE INVENTORY - MRST Simulation Scripts

## PURPOSE
**LLM-Optimized** variable inventory designed to help AI understand the complexity and structure of the Eagle West Field MRST simulation project. This inventory maps 900+ variables across their usage contexts, dependencies, and workflow stages.

**Source**: Extracted from all `.m` and `.yaml` files in `mrst_simulation_scripts/`  
**Date**: 2025-08-12  
**Total Variables**: 900+ unique identifiers  
**Optimization**: Structured for LLM comprehension and navigation

---

## 🗺️ SYSTEM CONCEPTUAL MAP

### Data Flow Architecture
```
YAML Configs (Input) → MATLAB Processing (Logic) → MRST Structures (Framework) → Results (Output)
       ↓                        ↓                         ↓                        ↓
  User Settings          Algorithm Variables        MRST Standard Format    Files & Analysis
  Configuration          Temporary Calculations     Required by Framework   Validation Reports
  Business Rules         Domain Logic               Simulation Engine       Export Data
```

### Workflow Dependencies
```
s01 Initialize → s07 Rock → s17 Wells → s22 Simulation → s24 Analysis
      ↓             ↓          ↓            ↓              ↓
   MRST Setup   Rock Properties Well Setup  Run Solver   Results
   (Foundation)  (Reservoir)   (Production) (Compute)    (Output)
```

### Critical Integration Points
1. **YAML → MATLAB**: Configuration loading (`read_yaml_config`)
2. **MATLAB → MRST**: Structure creation (`G.*`, `fluid.*`, `rock.*`, `state.*`)  
3. **MRST → Results**: Data export (`export_*`, `save_*`)
4. **Cross-module**: Shared data files (`.mat` files)

---

## 🚀 VARIABLES BY WORKFLOW STAGE

### STAGE 1: CONFIGURATION INPUT (YAML → MATLAB)
*Variables that bring user settings into the system*

#### **Configuration Loaders**
- `config`, `full_config`, `config_file`, `config_path` - Main config structures
- `rock_params`, `fluid_params`, `wells_config`, `solver_config` - Domain configs
- `fault_config`, `grid_config`, `scal_config`, `pvt_config` - Specialized configs

#### **YAML Parameters** (User-settable values)
- `porosity_layers`, `permeability_layers`, `kv_kh_ratios`, `lithology_layers` - Rock definition
- `target_oil_rate_stb_day`, `min_bhp_psi`, `esp_type`, `esp_stages` - Well configuration  
- `solver_type`, `max_iterations`, `tolerance_cnv`, `timestep_control` - Solver settings
- `owc_depth_ft_tvdss`, `initial_pressure_psi`, `aquifer_type` - Initialization
- `Fault_A`, `Fault_B`, `Fault_C`, `Fault_D`, `Fault_E` - Fault definitions

---

### STAGE 2: MRST INTEGRATION (MATLAB → MRST Framework)
*Variables that interface with MRST core structures*

#### **MRST Core Structures** (Required by MRST)
- `G` - Grid structure
  - `G.cells.num`, `G.cells.centroids`, `G.cells.volumes`
  - `G.cartDims`, `G.faces.num`, `G.nodes.coords`
- `rock` - Rock properties structure  
  - `rock.perm`, `rock.poro`
- `fluid` - Fluid properties structure
  - `fluid.phases`, `fluid.mu`, `fluid.krW`, `fluid.krO`, `fluid.krG`
- `state` - Simulation state structure
  - `state.pressure`, `state.s`, `state.sw`, `state.so`, `state.sg`
- `W` - Wells structure (MRST wells array)

#### **MRST Framework Variables**
- `deck`, `schedule`, `model` - MRST simulation objects
- `wellSols`, `states` - MRST solution arrays
- `black_oil_model`, `three_phase` - MRST model types

---

### STAGE 3: PROCESSING LOGIC (Algorithm Variables)
*Variables used for calculations, transformations, and business logic*

#### **Rock Processing**
- `perm_x`, `perm_y`, `perm_z` - Permeability components (mD)
- `perm_avg`, `perm_tensor`, `perm_variation` - Derived permeability
- `porosity`, `poro_variation`, `rock_types` - Porosity calculations
- `rt1_props`, `rt2_props`, `rt6_props` - Rock type properties

#### **Well Processing**  
- `well_indices`, `completion_intervals`, `wellbore_design` - Well calculations
- `wi` (well index), `r_eq` (equivalent radius), `skin` - Well productivity
- `well_config`, `wells_data`, `completion_results` - Well data structures

#### **Fluid Processing**
- `Bo`, `Bg`, `Bw` - Formation volume factors
- `mu_o`, `mu_g`, `mu_w` - Viscosities  
- `Rs` - Solution gas-oil ratio
- `krw`, `kro`, `krg` - Relative permeabilities

#### **Grid Processing**
- `nx`, `ny`, `nz` - Grid dimensions
- `dx`, `dy`, `dz` - Cell dimensions
- `refinement_factors`, `refined_cells`, `cell_volumes` - Grid operations

#### **Solver Processing**
- `dt`, `timesteps`, `convergence_failures` - Time stepping
- `tolerance`, `max_iterations`, `linear_solver_type` - Convergence control
- `checkpoint_frequency`, `progress_config` - Monitoring

---

### STAGE 4: RESULTS & EXPORT (Processing → Files)
*Variables that handle output, validation, and export*

#### **Results Structures**
- `workflow_results`, `completion_results`, `production_results` - Main results
- `simulation_results`, `reservoir_results`, `quality_report` - Analysis results
- `field_rates`, `cumulative_oil_production_m3`, `recovery_factor` - Production metrics

#### **File Management** 
- `data_dir`, `results_dir`, `export_path` - Directory paths
- `grid_file`, `rock_file`, `wells_file`, `fluid_file` - Input files
- `results_file`, `summary_file`, `csv_file` - Output files  
- `timestamp`, `filename`, `file_info` - File operations

#### **Validation Variables**
- `material_balance`, `saturation_sum_errors`, `pressure_stats` - Quality checks
- `validation_results`, `quality_checks`, `consistency_scores` - Validation metrics

## 🎯 DOMAIN-BASED LOOKUP (For Quick Navigation)

### **RESERVOIR PROPERTIES**
*Variables related to rock, fluid, and reservoir characterization*

#### Rock Properties
- **Configuration**: `porosity_layers`, `permeability_layers`, `kv_kh_ratios`, `lithology_layers`
- **MRST Standard**: `rock.perm`, `rock.poro`  
- **Processing**: `perm_x`, `perm_y`, `perm_z`, `perm_avg`, `porosity`
- **Rock Types**: `rt1_props`, `rt2_props`, `rt6_props`, `rock_types`

#### Fluid Properties  
- **Configuration**: `oil_bo_pressure_table`, `gas_bg_pressure_table`, `water_bw_pressure_table`
- **MRST Standard**: `fluid.mu`, `fluid.krW`, `fluid.krO`, `fluid.krG`
- **Processing**: `Bo`, `Bg`, `Bw`, `mu_o`, `mu_g`, `mu_w`, `Rs`
- **Relative Permeability**: `krw`, `kro`, `krg`, `Swc`, `Sor`, `Sgc`

#### Pressure & Initialization
- **Configuration**: `initial_pressure_psi`, `owc_depth_ft_tvdss`, `aquifer_type`
- **MRST Standard**: `state.pressure`
- **Processing**: `datum_pressure`, `initial_pressure`, `compartment_pressure_adj`

---

### **WELL ENGINEERING**
*Variables related to wells, completions, and production*

#### Well Configuration
- **Configuration**: `target_oil_rate_stb_day`, `min_bhp_psi`, `esp_type`, `esp_stages`
- **Processing**: `well_config`, `wells_data`, `well_indices`
- **MRST Standard**: `W` (wells array)

#### Completions & Productivity
- **Processing**: `wi` (well index), `r_eq`, `skin`, `completion_intervals`
- **Design**: `wellbore_design`, `completion_WI`
- **ESP Systems**: `esp_type`, `esp_stages`, `esp_hp`

#### Production Control
- **Rates**: `field_oil_rate`, `field_water_rate`, `field_gas_rate`
- **Targets**: `target_rate`, `producer_targets`, `injector_targets`
- **Control**: `well_control`, `producer_controls`, `injector_controls`

---

### **NUMERICAL METHODS**  
*Variables related to solver, timesteps, and convergence*

#### Solver Configuration
- **Configuration**: `solver_type`, `max_iterations`, `tolerance_cnv`, `tolerance_mb`
- **Processing**: `solver_config`, `linear_solver_type`, `nonlinear_solver`
- **Control**: `timestep_control`, `convergence_failures`

#### Time Stepping
- **Configuration**: `initial_timestep_days`, `max_timestep_days`, `min_timestep_days`
- **Processing**: `dt`, `timesteps`, `timestep_days`
- **Control**: `checkpoint_frequency`, `progress_config`

#### Quality Control
- **Validation**: `material_balance`, `saturation_sum_errors`, `pressure_stats`
- **Checks**: `quality_checks`, `validation_results`, `consistency_scores`

---

### **GRID & GEOMETRY**
*Variables related to grid construction and spatial discretization*

#### Grid Definition  
- **Configuration**: `nx`, `ny`, `nz`, `cell_size_x`, `cell_size_y`
- **MRST Standard**: `G.cells.num`, `G.cartDims`, `G.nodes.coords`
- **Processing**: `dx`, `dy`, `dz`, `cell_volumes`

#### Grid Refinement (TIERED STRATEGY - CANONICAL)
- **Configuration**: `tiered_strategy`, `well_tiers`, `fault_tiers`, `tier_parameters`
- **Processing**: `refined_cells`, `refinement_factors`, `refinement_zones`
- **Tier Classification**: `critical_tier`, `standard_tier`, `marginal_tier` (wells)
- **Tier Classification**: `major_tier`, `minor_tier` (faults)
- **Optimization**: `tier_radius`, `tier_buffer`, `tier_priority`, `coverage_target`

#### Geometry
- **Structural**: `axis_data`, `surfaces`, `layers`, `structural_data`
- **Faults**: `fault_faces`, `fault_zones`, `trans_multipliers`

---

### **GRID REFINEMENT OPTIMIZATION (CANONICAL)**
*Variables related to the tiered refinement strategy and computational optimization*

#### Tiered Strategy Configuration
- **Configuration**: `tiered_strategy.enable`, `apply_tier_based_refinement` - Strategy control
- **Well Tiers**: `critical.wells`, `standard.wells`, `marginal.wells` - Well classification
- **Fault Tiers**: `major.faults`, `minor.faults` - Fault classification
- **Tier Parameters**: `radius`, `buffer`, `factor`, `priority` - Refinement specifics

#### Optimization Variables
- **Coverage Targets**: `coverage_target` (25%), `well_coverage` (15%), `fault_coverage` (10%)
- **Mathematical Parameters**: `optimal_well_radius` (165ft), `optimal_fault_buffer` (156ft)
- **Performance Metrics**: `cell_reduction` (61.5%), `memory_savings` (65%), `time_savings` (50-60%)
- **Quality Control**: `tier_validation`, `coverage_verification`, `grid_integrity`

#### Tier-Specific Variables
- **Critical Wells**: `critical_radius` (350ft), `critical_factor` (3x3), `critical_priority` (1)
- **Standard Wells**: `standard_radius` (250ft), `standard_factor` (2x2), `standard_priority` (2)
- **Marginal Wells**: `marginal_radius` (150ft), `marginal_factor` (2x2), `marginal_priority` (3)
- **Major Faults**: `major_buffer` (400ft), `major_factor` (3x3), `major_priority` (1)
- **Minor Faults**: `minor_buffer` (200ft), `minor_factor` (2x2), `minor_priority` (2)

#### Implementation Variables
- **Zone Creation**: `create_tiered_well_refinement_zones`, `create_tiered_fault_refinement_zones`
- **Tier Assignment**: `determine_well_tier`, `determine_fault_tier`
- **Conflict Resolution**: `priority_based_resolution`, `zone_overlap_handling`
- **Validation**: `tier_assignment_validation`, `grid_quality_metrics`

---

### **DATA MANAGEMENT**
*Variables related to I/O, files, and data handling*

#### File Operations
- **Paths**: `data_dir`, `results_dir`, `export_path`, `script_path`
- **Files**: `grid_file`, `rock_file`, `wells_file`, `results_file`
- **I/O**: `load_data`, `export_path`, `timestamp`, `filename`

#### Configuration Loading
- **Loaders**: `config`, `full_config`, `read_yaml_config`
- **Validation**: `config_ranges`, `required_fields`, `validation_passed`

#### Results Export
- **Structures**: `workflow_results`, `completion_results`, `production_results`
- **Formats**: `csv_file`, `summary_file`, `report_file`
- **Metadata**: `file_info`, `creation_time`, `status`

## 📊 CROSS-REFERENCE TABLE

### Critical Variable Dependencies
| **Variable** | **Origin** | **Used By** | **Type** | **Criticality** | **Files** |
|--------------|------------|-------------|----------|-----------------|-----------|
| `rock.perm` | s07_define_rock_types.m | s17_well_completions.m, MRST solver | MRST Core | 🔴 Critical | s07→s17→s22 |
| `rock.poro` | s07_define_rock_types.m | s14_saturation_distribution.m, MRST solver | MRST Core | 🔴 Critical | s07→s14→s22 |
| `G.cells.num` | s02_create_grid.m | All modules using grid | MRST Core | 🔴 Critical | s02→ALL |
| `G_refined` | s06_grid_refinement.m | s07-s22 (all downstream) | MRST Core | 🔴 Critical | s06→ALL |
| `state.pressure` | s13_pressure_initialization.m | s22_run_simulation.m | MRST Core | 🔴 Critical | s13→s22 |
| `state.s` | s14_saturation_distribution.m | s22_run_simulation.m | MRST Core | 🔴 Critical | s14→s22 |
| `W` (wells) | s17_well_completions.m | s22_run_simulation.m | MRST Core | 🔴 Critical | s17→s22 |
| `tiered_strategy` | grid_config.yaml | s06_grid_refinement.m | Config | 🟠 High | YAML→s06 |
| `well_tiers` | grid_config.yaml | s06_grid_refinement.m | Optimization | 🟡 High | YAML→s06 |
| `fault_tiers` | grid_config.yaml | s06_grid_refinement.m | Optimization | 🟡 High | YAML→s06 |
| `perm_x` | s17_well_completions.m | Well index calculation | Processing | 🟡 High | s17 only |
| `well_config` | wells_config.yaml | s18_production_controls.m | Config | 🟡 High | YAML→s18 |
| `solver_config` | solver_config.yaml | s21_solver_setup.m | Config | 🟡 High | YAML→s21 |
| `rock_params` | rock_properties_config.yaml | s07_define_rock_types.m | Config | 🟡 High | YAML→s07 |

### Variable Lifecycle Patterns
| **Pattern** | **Example Variables** | **Lifecycle** | **Usage Notes** |
|-------------|----------------------|---------------|-----------------|
| **Config → Processing → MRST** | `porosity_layers` → `porosity` → `rock.poro` | YAML→MATLAB→MRST | Standard flow |
| **MRST → Processing → Export** | `state.pressure` → `pressure_stats` → `summary_file` | MRST→Analysis→Files | Results flow |
| **Cross-module Shared** | `G`, `rock`, `fluid`, `state` | Created once, used everywhere | Core structures |
| **Temporary Processing** | `perm_x`, `wi`, `dt` | Local calculation variables | Function scope |
| **File I/O** | `data_dir`, `export_path`, `filename` | Path and file management | System utilities |
| **Tiered Optimization** | `tiered_strategy` → `tier_assignment` → `G_refined` | YAML→Optimization→MRST | Canonical refinement |

### Module Interaction Map
```
YAML Configs
    ↓
s01 (Initialize) → s02 (Grid) → s06 (Refinement) → s07 (Rock) → s17 (Wells) → s22 (Simulate) → s24 (Results)
    ↓                ↓               ↓               ↓            ↓             ↓               ↓
mrst_env         G.*         G_refined        rock.*       W.*         states         analysis.*
                                ↓ (tiered)                                                         
                        tier_classification                                                       
                                                                          
Cross-cutting: config.*, *_file, *_dir, validation.*, export.*
```

---

## 🧠 CONTEXT HELPERS FOR LLMs

### **Common Usage Patterns**

#### **Adding New Rock Property**
1. **Config Stage**: Add parameter to `rock_properties_config.yaml`
2. **Load Stage**: Access via `rock_params.new_property` in s07
3. **MRST Stage**: Add to `rock` structure for MRST compatibility
4. **Usage Stage**: Access via `rock.new_property` in other modules

#### **Adding New Well Parameter**  
1. **Config Stage**: Add to `wells_config.yaml` under producer/injector wells
2. **Load Stage**: Access via `well_config.new_parameter` in s18
3. **Processing Stage**: Use in well calculations (s17, s18)
4. **MRST Stage**: Include in `W` structure if needed for solver

#### **Adding New Solver Option**
1. **Config Stage**: Add to `solver_config.yaml`
2. **Load Stage**: Access via `solver_config.new_option` in s21  
3. **Apply Stage**: Use in MRST solver setup
4. **Monitor Stage**: Track in progress monitoring if applicable

#### **Adding New Grid Refinement Tier**
1. **Config Stage**: Add tier to `grid_config.yaml` under `tiered_strategy`
2. **Classification Stage**: Implement tier logic in `determine_well_tier()` or `determine_fault_tier()`
3. **Processing Stage**: Use tier-specific parameters (radius, buffer, factor, priority)
4. **Validation Stage**: Verify tier assignment and coverage targets

### **Typical Variable Scopes**
- **Global Config**: Available throughout workflow (`config.*`)
- **MRST Structures**: Available to MRST solver (`G.*`, `rock.*`, `fluid.*`, `state.*`)  
- **Module Local**: Used within single script (`perm_x`, `wi`, `dt`)
- **Cross-Module**: Shared via .mat files (`G`, `rock`, `wells_data`)

### **Error-Prone Areas for LLMs**
1. **Unit Confusion**: `perm_x` is in mD, `rock.perm` is in m²
2. **Structure Confusion**: `rock_params` (config) ≠ `rock_props` (loaded) ≠ `rock` (MRST)
3. **File Dependencies**: Must load G before using `G.cells.num`
4. **MRST Requirements**: MRST expects specific field names and formats
5. **Grid Refinement**: Must use `G_refined` (from s06) not `G` (from s02) for downstream modules
6. **Tier Assignments**: Well/fault tiers must match configuration exactly (case-sensitive names)
7. **Coverage Targets**: Tiered strategy aims for 20-30% total coverage, not higher
8. **Legacy vs Tiered**: Enable `tiered_strategy.enable = true` for optimized refinement

### **Quick Decision Tree for LLMs**
```
Need a variable? Ask:
├─ Is it user-configurable? → Look in YAML configs (Stage 1)
├─ Is it required by MRST? → Look in MRST structures (Stage 2)  
├─ Is it calculated? → Look in processing variables (Stage 3)
└─ Is it output/export? → Look in results variables (Stage 4)

Working on a specific domain?
├─ Rock/Fluid properties → Check RESERVOIR PROPERTIES section
├─ Wells/Production → Check WELL ENGINEERING section
├─ Solver/Numerics → Check NUMERICAL METHODS section  
├─ Grid/Geometry → Check GRID & GEOMETRY section
├─ Grid Refinement → Check GRID REFINEMENT OPTIMIZATION section (CANONICAL)
└─ Files/Data → Check DATA MANAGEMENT section

Working with grid refinement?
├─ Want tiered optimization? → Use tiered_strategy (CANONICAL approach)
├─ Need tier classification? → Use well_tiers/fault_tiers configuration
├─ Setting coverage targets? → Aim for 20-30% total coverage (25% optimal)
└─ Legacy compatibility? → Set tiered_strategy.enable = false
```

## 📋 COMPLETE ALPHABETICAL REFERENCE

### MATLAB Variables (600+ from .m files)
*For complete lookup - organized by first letter*

**A-D**: A, active_injectors, actual_max, affected_cells, all_checks, analysis_file, aquifer_PI, axis_data, B, base_depth, bg_vals, bo_values, boundary_cells, bubble_point_pa, calculated_oil_gradient, capillary_file, carter_tracy_constant, cell_centers, cell_id, checkpoint_data, config, connected_pore_volume, control_data, current_time, data, data_dir, datum_pressure, deck, depth_range, dx, dy, dz

**E-H**: effective_length, enhanced_rock_file, errors, execution_time, export_path, face_indices, fault_config, field_rates, filename, final_rock, fluid, fluid_complete, G, G_refined, gas_rates, grid_config, height_above_owc

**I-L**: initial_pressure, injector_wells, krG_func, krW_func, krg_max, layer_config, layers, load_data

**M-P**: material_balance, max_pressure, model, modules_loaded, mrst_env, mu_g, mu_o, mu_w, n_cells, nx, ny, nz, oil_rates, output_data, perm_avg, perm_x, perm_y, perm_z, phase_result, porosity, pressure, production_results

**Q-T**: quality_checks, r_eq, rock, rock_params, rock_props, saturation_data, solver_config, state, timesteps, total_wells

**U-Z**: validation_results, well_config, well_indices, wells_data, wi, workflow_results, x_coord, y_coord, zone_cells

### YAML Parameters (300+ from .yaml files)  
*For complete lookup - organized by domain*

**Configuration Structure**: adaptive_control, aquifer_configuration, completion_parameters, development_phases, fault_system, fluid_properties, grid_parameters, rock_properties, scal_properties, solver_configuration, wells_system

**Physical Properties**: bubble_point_pressure_psi, connate_water_saturation, gas_density, oil_viscosity, permeability_layers, porosity_layers, water_compressibility

**Well Parameters**: esp_hp, esp_stages, esp_type, min_bhp_psi, target_oil_rate_stb_day, well_type

**Solver Settings**: max_iterations, solver_type, timestep_control, tolerance_cnv, tolerance_mb

**Grid Definition**: cell_size_x, cell_size_y, nx, ny, nz, refinement_factor

---

## 📊 SUMMARY STATISTICS

### Variable Distribution by Type
- **MRST Core Structures**: 50+ variables (G.*, rock.*, fluid.*, state.*, W)
- **Configuration Variables**: 300+ YAML parameters 
- **Processing Variables**: 400+ calculation and temporary variables
- **File I/O Variables**: 150+ path, filename, and export variables

### Most Critical Variables (🔴)
1. `G` - Grid structure (used by all modules)
2. `rock.perm`, `rock.poro` - Rock properties (reservoir foundation)
3. `state.pressure`, `state.s` - Initial conditions (simulation start)
4. `W` - Wells array (production system)
5. `fluid` - Fluid properties (phase behavior)

### Workflow Integration Points
- **YAML → MATLAB**: 9 configuration files → `*_config` variables
- **MATLAB → MRST**: Processing variables → Core structures (G, rock, fluid, state)
- **MRST → Results**: Simulation output → Analysis and export variables

### LLM Usage Recommendations
1. **Start with Domain Lookup** for quick navigation by technical area
2. **Use Workflow Stages** to understand variable lifecycle  
3. **Check Cross-Reference Table** for dependencies and criticality
4. **Follow Decision Tree** when unsure about variable context
5. **Refer to Context Helpers** for common usage patterns

---

**Generated**: 2025-08-12  
**Optimization**: LLM-structured for complexity understanding  
**Usage**: Primary reference for AI working on MRST simulation project  
**Validation**: Based on actual codebase extraction and analysis