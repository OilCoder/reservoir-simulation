# YAML CONSOLIDATION PLAN - SURGICAL DEDUPLICATION STRATEGY

**Eagle West Field MRST Simulation Project**  
**Date**: 2025-08-31  
**Status**: CRITICAL - 187 duplicated parameters (20.8% duplication rate)  
**Objective**: Achieve 0% parameter duplication with 6 Immutable Policies compliance

## 🚨 CRITICAL CONFLICTS (PRIORITY 1 - IMMEDIATE RESOLUTION)

### Conflict Analysis Summary
- **Total YAML files**: 17 configuration files
- **Duplicated parameters**: 187 (20.8% of total parameters)
- **Critical conflicts**: 4 (blocking s99 functionality)
- **High-risk duplications**: 15 (functional inconsistencies)
- **Low-risk duplications**: 168 (documentation/unit conversion redundancy)

---

## 📋 PHASE 1: CRITICAL CONFLICT RESOLUTION

### **Conflict 1: field_specifications (CRITICAL)**
**Files**: `analysis_config.yaml` + `development_config.yaml`  
**Risk**: HIGH - Field definition conflicts causing s99 validation failure

**Current State**:
```yaml
# analysis_config.yaml (Lines 39-46)
field_specifications:
  field_name: "Eagle West Field"
  grid_dimensions: "41x41x12"
  total_design_wells: 15
  design_producers: 10
  design_injectors: 5
  simulation_duration_years: 10

# development_config.yaml (Lines 30-36)  
field_specifications:
  field_name: "Eagle West Field"
  grid_dimensions: "41x41x12"
  simulation_duration_years: 10
  major_faults: 5
  reservoir_type: "black_oil"
```

**CONSOLIDATION STRATEGY**:
- **Authoritative location**: `development_config.yaml` (canonical field specifications)
- **Rationale**: Development config is the canonical source for field planning
- **Action**: Remove from `analysis_config.yaml`, expand in `development_config.yaml`

**Target State**:
```yaml
# development_config.yaml (EXPANDED)
field_specifications:
  field_name: "Eagle West Field"
  grid_dimensions: "41x41x12" 
  total_design_wells: 15
  design_producers: 10
  design_injectors: 5
  major_faults: 5
  reservoir_type: "black_oil"
  simulation_duration_years: 10

# analysis_config.yaml (REFERENCE ONLY)
analysis_settings:
  field_source: "development_config.yaml"  # Reference to authoritative source
```

---

### **Conflict 2: grid_dimensions (HIGH RISK)**
**Files**: `analysis_config.yaml` + `development_config.yaml` + `grid_config.yaml`  
**Risk**: HIGH - Grid sizing conflicts between configs

**Current State**:
```yaml
# Three different locations defining grid_dimensions: "41x41x12"
# - analysis_config.yaml: Line 42
# - development_config.yaml: Line 33  
# - grid_config.yaml: Lines 157-159 (expanded form: nx: 41, ny: 41, nz: 12)
```

**CONSOLIDATION STRATEGY**:
- **Authoritative location**: `grid_config.yaml` (canonical grid authority)
- **Keep expanded form**: `nx: 41, ny: 41, nz: 12` (more precise)
- **Action**: Remove string form from other configs

---

### **Conflict 3: initial_saturations (HIGH RISK)**
**Files**: `initialization_config.yaml` + `simulation_config.yaml`  
**Risk**: HIGH - Initial conditions conflict

**Current State**:
```yaml
# initialization_config.yaml (Lines 52-57) - COMPREHENSIVE
initial_saturations:
  oil_zone:
    oil_saturation_range: [0.80, 0.82]
    water_saturation_range: [0.18, 0.20]
    gas_saturation: 0.00

# simulation_config.yaml (Lines 12-16) - SIMPLIFIED  
initial_saturations:
  sw_initial: 0.20
  so_initial: 0.80
  sg_initial: 0.00
```

**CONSOLIDATION STRATEGY**:
- **Authoritative location**: `initialization_config.yaml` (canonical initial conditions)
- **Preserve comprehensive format** (range specifications)
- **Action**: Remove simplified version from `simulation_config.yaml`

---

### **Conflict 4: material_balance_tolerance (CRITICAL)**
**Files**: `initialization_config.yaml` (0.0001) + `solver_config.yaml` (0.01)  
**Risk**: CRITICAL - Different solver tolerances causing numerical inconsistency

**Current State**:
```yaml
# initialization_config.yaml (Line 144)
material_balance_tolerance: 0.0001  # 0.01% error tolerance

# solver_config.yaml (Line 69)  
material_balance_tolerance: 0.01    # 1% error maximum
```

**CONSOLIDATION STRATEGY**:
- **Authoritative location**: `solver_config.yaml` (canonical solver parameters)
- **Use stricter tolerance**: 0.0001 (more conservative for initialization)
- **Action**: Remove from `initialization_config.yaml`, update `solver_config.yaml`

---

## 📋 PHASE 2: HIGH-VOLUME DUPLICATIONS

### **Unit Conversions (45 duplications)**
**Files**: 8 different configs with redundant unit conversion factors

**CONSOLIDATION STRATEGY**:
- **Create**: `units_config.yaml` (new canonical units file)
- **Consolidate all conversions** into single authoritative source
- **Reference pattern**: Other configs reference units_config.yaml

### **Wells Parameters (30 duplications)**
**Pattern**: Well counts, names, classifications repeated across multiple configs

**CONSOLIDATION STRATEGY**:
- **Authoritative location**: `wells_config.yaml` 
- **Remove duplications** from: `analysis_config.yaml`, `development_config.yaml`, `grid_config.yaml`

### **Field Bounds and Extents (25 duplications)**
**Pattern**: Domain boundaries repeated in grid, fault, and development configs

**CONSOLIDATION STRATEGY**:
- **Authoritative location**: `grid_config.yaml` (canonical geometry)
- **Reference pattern**: Other configs load bounds from grid_config.yaml

---

## 📋 PHASE 3: IMPLEMENTATION ROADMAP

### **Stage 1: Critical Conflicts (Day 1)**
1. **Fix Conflict 4**: Update `solver_config.yaml` material balance tolerance
2. **Fix Conflict 1**: Consolidate field_specifications in `development_config.yaml`
3. **Fix Conflict 3**: Remove duplicate initial_saturations from `simulation_config.yaml`
4. **Fix Conflict 2**: Remove grid_dimensions strings, keep expanded form in `grid_config.yaml`
5. **Test s99**: Verify workflow functionality after each fix

### **Stage 2: High-Volume Consolidation (Day 2)**
1. **Create** `units_config.yaml` with all unit conversions
2. **Consolidate wells parameters** in `wells_config.yaml`
3. **Remove field bounds duplications** (keep in `grid_config.yaml`)
4. **Test s99**: Verify full workflow after consolidation

### **Stage 3: Script Updates (Day 3)**
1. **Update MATLAB scripts** to load from consolidated locations
2. **Add reference loading** where configs need cross-references
3. **Final s99 testing**: Complete 20-phase workflow validation

---

## 📊 CONSOLIDATION MAPPING TABLE

| Parameter Group | Current Locations | Target Location | Action | Priority |
|-----------------|-------------------|-----------------|---------|----------|
| field_specifications | analysis, development | development_config.yaml | consolidate | P1 |
| grid_dimensions | analysis, development, grid | grid_config.yaml (expanded) | remove strings | P1 |
| initial_saturations | initialization, simulation | initialization_config.yaml | remove simple | P1 |
| material_balance_tolerance | initialization, solver | solver_config.yaml | use strict | P1 |
| unit_conversions | 8 files | units_config.yaml (NEW) | consolidate | P2 |
| well_counts | analysis, development, wells | wells_config.yaml | remove dups | P2 |
| domain_bounds | grid, fault, development | grid_config.yaml | remove dups | P2 |
| pressure_limits | initialization, solver, simulation | solver_config.yaml | consolidate | P3 |
| validation_thresholds | 5 files | workflow_config.yaml | consolidate | P3 |

---

## 🧪 TESTING CHECKLIST

### **After Each Phase**:
- [ ] **s99 workflow executes** without YAML loading errors
- [ ] **All 20 phases complete** successfully
- [ ] **No parameter value changes** (preserve functionality)
- [ ] **No missing parameter errors** in MATLAB scripts
- [ ] **Cross-references resolve** correctly

### **Critical Validation Points**:
- [ ] **Grid creation (s05)** uses correct dimensions from `grid_config.yaml`
- [ ] **Initialization (s12-s14)** uses correct saturations from `initialization_config.yaml`
- [ ] **Simulation (s21)** uses correct solver tolerance from `solver_config.yaml`
- [ ] **Analysis (s22)** references field specs from `development_config.yaml`
- [ ] **All unit conversions** resolve from centralized source

---

## 🔄 ROLLBACK PROCEDURES

### **If s99 Breaks During Consolidation**:
1. **Immediate revert**: `git checkout HEAD~1` to previous working state
2. **Identify failure**: Check MATLAB error messages for missing parameters
3. **Surgical fix**: Add back only the conflicting parameter temporarily
4. **Re-plan approach**: Adjust consolidation strategy for problematic parameter
5. **Re-test**: Verify s99 works before continuing

### **Rollback Command Sequence**:
```bash
# Emergency rollback
git stash
git checkout HEAD~1
octave mrst_simulation_scripts/s99_run_workflow.m  # Test functionality

# Identify specific issue
git diff HEAD~1 HEAD -- mrst_simulation_scripts/config/
# Fix issue, re-commit, continue
```

---

## ✅ SUCCESS CRITERIA

### **Quantitative Targets**:
- [ ] **0% parameter duplication** across all 17 YAML files
- [ ] **100% s99 functionality** preserved (all 20 phases)
- [ ] **Canon-First Policy compliance**: Each parameter has exactly one authoritative source
- [ ] **Data Authority Policy compliance**: All hardcoded values eliminated

### **Qualitative Targets**:
- [ ] **Clear parameter ownership**: Each config file has defined responsibility
- [ ] **Maintainable structure**: Easy to locate and modify parameters
- [ ] **Cross-reference clarity**: Dependencies between configs well-documented
- [ ] **No functionality regression**: All existing features work identically

---

## 🎯 CANON-FIRST POLICY ALIGNMENT

### **Single Source of Truth Mapping**:
- **Grid geometry**: `grid_config.yaml`
- **Well definitions**: `wells_config.yaml` 
- **Fluid properties**: `fluid_properties_config.yaml`
- **Initial conditions**: `initialization_config.yaml`
- **Solver parameters**: `solver_config.yaml`
- **Field specifications**: `development_config.yaml`
- **Unit conversions**: `units_config.yaml` (NEW)

### **Reference Pattern**:
```yaml
# Example cross-reference pattern
analysis_settings:
  field_source: "development_config.yaml"
  grid_source: "grid_config.yaml"
  units_source: "units_config.yaml"
```

---

## 📈 EXPECTED OUTCOMES

### **Before Consolidation**:
- **187 duplicated parameters** (20.8% duplication rate)
- **4 critical conflicts** blocking s99 functionality
- **Hardcoded values** scattered across multiple files
- **Maintenance overhead** for parameter updates

### **After Consolidation**:
- **0 duplicated parameters** (0% duplication rate)
- **0 conflicts** - all parameters have single authoritative source
- **Canon-First compliance** - documented single source of truth
- **Simplified maintenance** - one location per parameter type

---

**CRITICAL SUCCESS FACTOR**: Maintain s99 workflow functionality throughout the entire consolidation process. ANY break in s99 functionality requires immediate rollback and strategy revision.