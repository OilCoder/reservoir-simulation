# YAML CONSOLIDATION MAPPING TABLE - COMPLETE PARAMETER INVENTORY

**Eagle West Field MRST Simulation Project**  
**Date**: 2025-08-31  
**Purpose**: Detailed mapping for 187 duplicated parameters across 17 YAML files

## 📊 MASTER CONSOLIDATION MAPPING

### **CRITICAL CONFLICTS (Priority 1)**

| Parameter | Current Locations | Values | Target Location | Consolidation Action | Risk Level |
|-----------|-------------------|---------|-----------------|---------------------|------------|
| `field_specifications` | analysis_config.yaml<br>development_config.yaml | Overlapping but different fields | development_config.yaml | Merge all fields, remove from analysis | **CRITICAL** |
| `grid_dimensions` | analysis_config.yaml<br>development_config.yaml<br>grid_config.yaml | "41x41x12" (string)<br>nx:41, ny:41, nz:12 (expanded) | grid_config.yaml | Keep expanded form only | **HIGH** |
| `initial_saturations` | initialization_config.yaml<br>simulation_config.yaml | Comprehensive vs simplified | initialization_config.yaml | Keep comprehensive, remove simple | **HIGH** |
| `material_balance_tolerance` | initialization_config.yaml<br>solver_config.yaml | 0.0001 vs 0.01 | solver_config.yaml | Use 0.0001 (stricter) | **CRITICAL** |

---

### **HIGH-VOLUME DUPLICATIONS (Priority 2)**

#### **Unit Conversions (45 duplications)**
| Parameter | Current Locations | Target Location | Action |
|-----------|-------------------|-----------------|---------|
| `m3_to_bbl` | analysis, initialization, simulation, pvt, fluid | units_config.yaml | Create new file |
| `pa_to_psi` | analysis, initialization, solver | units_config.yaml | Consolidate |
| `psi_to_pa` | initialization, simulation, solver | units_config.yaml | Consolidate |
| `day_to_seconds` | simulation, solver, workflow | units_config.yaml | Consolidate |
| `barrel_to_m3` | simulation, pvt, fluid | units_config.yaml | Consolidate |
| `m_to_ft` | initialization, grid, structural | units_config.yaml | Consolidate |
| `ft_to_m` | initialization, grid, structural | units_config.yaml | Consolidate |
| `pa_to_barsa` | analysis, solver, production | units_config.yaml | Consolidate |

#### **Wells Parameters (30 duplications)**
| Parameter | Current Locations | Target Location | Action |
|-----------|-------------------|-----------------|---------|
| `total_design_wells: 15` | analysis, development, wells | wells_config.yaml | Remove from others |
| `design_producers: 10` | analysis, development, wells | wells_config.yaml | Remove from others |
| `design_injectors: 5` | analysis, development, wells | wells_config.yaml | Remove from others |
| `well_name_prefixes` | analysis, wells, production | wells_config.yaml | Consolidate |
| `producer_names: EW-001 to EW-010` | wells, completions, development | wells_config.yaml | Single source |
| `injector_names: IW-001 to IW-005` | wells, completions, development | wells_config.yaml | Single source |
| `minimum_producers: 8` | development, wells | wells_config.yaml | Consolidate |
| `minimum_injectors: 3` | development, wells | wells_config.yaml | Consolidate |
| `maximum_well_count: 20` | development, wells, grid | wells_config.yaml | Consolidate |

#### **Domain Bounds (25 duplications)**
| Parameter | Current Locations | Target Location | Action |
|-----------|-------------------|-----------------|---------|
| `field_extent_x: 3280.0` | grid, fault, pebi, structural | grid_config.yaml | Remove from others |
| `field_extent_y: 2950.0` | grid, fault, pebi, structural | grid_config.yaml | Remove from others |
| `x_min: 0.0` | grid, pebi, fault | grid_config.yaml | Consolidate |
| `x_max: 3280.0` | grid, pebi, fault | grid_config.yaml | Consolidate |
| `y_min: 0.0` | grid, pebi, fault | grid_config.yaml | Consolidate |
| `y_max: 2950.0` | grid, pebi, fault | grid_config.yaml | Consolidate |
| `total_thickness: 340.0` | grid, structural, rock | grid_config.yaml | Remove from others |
| `datum_depth_tvdss: 8000.0` | grid, initialization, structural | grid_config.yaml | Consolidate |

---

### **MEDIUM PRIORITY DUPLICATIONS (Priority 3)**

#### **Pressure Parameters (20 duplications)**
| Parameter | Current Locations | Target Location | Action |
|-----------|-------------------|-----------------|---------|
| `initial_pressure_psi: 3600.0` | initialization, simulation, development | initialization_config.yaml | Remove from others |
| `bubble_point_pressure_psi: 2100.0` | initialization, fluid, pvt | fluid_properties_config.yaml | Consolidate |
| `minimum_pressure_psi` | simulation, solver, production | solver_config.yaml | Consolidate |
| `pressure_limits_pa` | solver, simulation, initialization | solver_config.yaml | Consolidate |
| `reference_pressure` | grid, solver, initialization | solver_config.yaml | Consolidate |

#### **Fault Classifications (15 duplications)**
| Parameter | Current Locations | Target Location | Action |
|-----------|-------------------|-----------------|---------|
| `major_faults: 5` | development, fault, grid | fault_config.yaml | Remove from others |
| `fault_names: [Fault_A, Fault_B, ...]` | fault, grid, pebi | fault_config.yaml | Single source |
| `fault_tiers.major` | grid, fault | fault_config.yaml | Consolidate |
| `fault_tiers.minor` | grid, fault | fault_config.yaml | Consolidate |

#### **Validation Thresholds (12 duplications)**
| Parameter | Current Locations | Target Location | Action |
|-----------|-------------------|-----------------|---------|
| `convergence_tolerance` | solver, initialization, workflow | solver_config.yaml | Consolidate |
| `max_iterations` | solver, workflow, simulation | solver_config.yaml | Consolidate |
| `tolerance_cnv` | solver, workflow | solver_config.yaml | Consolidate |
| `tolerance_mb` | solver, workflow | solver_config.yaml | Consolidate |

---

### **LOW PRIORITY DUPLICATIONS (Priority 4)**

#### **Documentation Fields (30 duplications)**
| Parameter | Current Locations | Target Location | Action |
|-----------|-------------------|-----------------|---------|
| `field_name: "Eagle West Field"` | Multiple configs | development_config.yaml | Remove from others |
| `reservoir_type: "black_oil"` | Multiple configs | development_config.yaml | Remove from others |
| `description` fields | Multiple configs | Keep in original files | Document only |
| `purpose` fields | Multiple configs | Keep in original files | Document only |
| `date` fields | Multiple configs | Keep in original files | Document only |

---

## 📋 NEW FILE REQUIREMENTS

### **units_config.yaml (NEW FILE)**
```yaml
# Unit Conversion Configuration for Eagle West Field
# Purpose: Centralized unit conversions (Canon-First Policy compliance)
# Date: 2025-08-31

unit_conversions:
  # Length conversions
  length:
    m_to_ft: 3.28084
    ft_to_m: 0.3048
    
  # Volume conversions  
  volume:
    bbl_to_m3: 0.158987294928
    m3_to_bbl: 6.28981
    
  # Pressure conversions
  pressure:
    psi_to_pa: 6894.76
    pa_to_psi: 0.000145038
    pa_to_barsa: 0.00001
    
  # Time conversions
  time:
    day_to_seconds: 86400
    year_to_days: 365.25
    
  # Reference standards
  reference_conditions:
    standard_temperature_k: 288.15  # 15°C
    standard_pressure_pa: 101325.0  # 1 atm
```

---

## 📋 MATLAB SCRIPT UPDATE REQUIREMENTS

### **Scripts Requiring Updates After Consolidation**

| Script | Current YAML Dependencies | Required Changes | Priority |
|--------|---------------------------|------------------|----------|
| `s05_create_pebi_grid.m` | grid_config.yaml | Remove grid_dimensions loading from other configs | P1 |
| `s12_initialize_state.m` | initialization_config.yaml | Remove initial_saturations from simulation_config | P1 |
| `s21_run_simulation.m` | simulation_config.yaml, solver_config.yaml | Use consolidated tolerance from solver_config | P1 |
| `s22_analyze_results.m` | analysis_config.yaml | Load field_specifications from development_config | P1 |
| `s20_consolidate_development.m` | development_config.yaml | Use consolidated field_specifications | P2 |
| **All scripts** | Multiple configs | Add units_config.yaml loading for conversions | P2 |

### **Required Code Pattern Changes**

#### **Before Consolidation (Multiple Sources)**:
```matlab
% Current problematic pattern - multiple YAML loads
analysis_cfg = read_yaml_config('analysis_config.yaml');
development_cfg = read_yaml_config('development_config.yaml');

% Conflict: which field_specifications to use?
field_name = analysis_cfg.field_specifications.field_name;
grid_dims = development_cfg.field_specifications.grid_dimensions;
```

#### **After Consolidation (Single Source)**:
```matlab
% Consolidated pattern - single authoritative source
development_cfg = read_yaml_config('development_config.yaml');
units_cfg = read_yaml_config('units_config.yaml');

% Clear authoritative source
field_name = development_cfg.field_specifications.field_name;
grid_dims = development_cfg.field_specifications.grid_dimensions;
conversion_factor = units_cfg.unit_conversions.volume.m3_to_bbl;
```

---

## 🧪 DETAILED TESTING STRATEGY

### **Phase 1 Testing (Critical Conflicts)**
```bash
# After each critical fix
octave -q --eval "s05_create_pebi_grid"      # Test grid creation
octave -q --eval "s12_initialize_state"      # Test initialization  
octave -q --eval "s21_run_simulation"        # Test simulation
octave -q --eval "s22_analyze_results"       # Test analysis

# Full workflow test
octave mrst_simulation_scripts/s99_run_workflow.m
```

### **Phase 2 Testing (Unit Consolidation)**
```bash
# Test unit conversion loading
octave -q --eval "units_cfg = read_yaml_config('units_config.yaml'); disp(units_cfg)"

# Test all scripts load units correctly
grep -r "m3_to_bbl\|psi_to_pa\|ft_to_m" mrst_simulation_scripts/
```

### **Phase 3 Testing (Complete Validation)**
```bash
# Full system test with monitoring
octave mrst_simulation_scripts/s99_run_workflow.m 2>&1 | tee consolidation_test.log

# Verify no YAML loading errors
grep -i "error\|warning\|failed" consolidation_test.log
```

---

## 🔧 IMPLEMENTATION COMMANDS

### **Critical Conflicts Resolution**
```bash
# Fix material balance tolerance conflict
sed -i 's/material_balance_tolerance: 0.01/material_balance_tolerance: 0.0001/' \
  mrst_simulation_scripts/config/solver_config.yaml

# Remove material_balance_tolerance from initialization_config
sed -i '/material_balance_tolerance: 0.0001/d' \
  mrst_simulation_scripts/config/initialization_config.yaml
```

### **Field Specifications Consolidation**
```bash
# Remove field_specifications from analysis_config.yaml
sed -i '/^field_specifications:/,/simulation_duration_years: 10/d' \
  mrst_simulation_scripts/config/analysis_config.yaml

# Add reference to development_config in analysis_config
echo -e "\n# Field specifications reference\nfield_source: \"development_config.yaml\"" >> \
  mrst_simulation_scripts/config/analysis_config.yaml
```

---

## ✅ VERIFICATION CHECKLIST

### **Parameter Count Verification**
- [ ] **Before**: 187 duplicated parameters identified
- [ ] **After Phase 1**: 4 critical conflicts resolved
- [ ] **After Phase 2**: 75 high-volume duplications resolved  
- [ ] **After Phase 3**: 108 medium/low priority duplications resolved
- [ ] **Final**: 0 duplicated parameters remaining

### **Functionality Verification**
- [ ] **s99 workflow**: All 20 phases complete successfully
- [ ] **Grid creation**: Consistent dimensions from single source
- [ ] **Initialization**: Correct saturations applied
- [ ] **Simulation**: Proper solver tolerances used
- [ ] **Analysis**: Accurate field specifications referenced
- [ ] **Cross-references**: All YAML references resolve correctly

---

**CRITICAL SUCCESS METRIC**: Achieve 0% parameter duplication while maintaining 100% s99 workflow functionality throughout the consolidation process.