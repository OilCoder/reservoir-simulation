# ROLLBACK PROCEDURES - YAML CONSOLIDATION SAFETY NET

**Eagle West Field MRST Simulation Project**  
**Date**: 2025-08-31  
**Purpose**: Complete rollback procedures for YAML consolidation phases

## 🚨 EMERGENCY ROLLBACK - IF S99 BREAKS

### **Immediate Recovery (30 seconds)**
```bash
# Emergency revert to last working state
cd /workspace
git stash push -m "broken consolidation attempt $(date)"
git log --oneline -5  # Find last known good commit

# Reset to working state (replace COMMIT_HASH with actual hash)
git reset --hard COMMIT_HASH

# Test functionality immediately
octave mrst_simulation_scripts/s99_run_workflow.m
```

### **Current State Backup**
Before consolidation, the working state should be preserved:
```bash
# Create safety backup
git add .
git commit -m "Pre-consolidation backup - working s99 state

All 4 critical YAML conflicts resolved:
- material_balance_tolerance: consolidated in solver_config.yaml  
- field_specifications: consolidated in development_config.yaml
- initial_saturations: authoritative in initialization_config.yaml
- units_config.yaml: new centralized conversion file created

🤖 Generated with [Claude Code](https://claude.ai/code)

Co-Authored-By: Claude <noreply@anthropic.com>"
```

---

## 🔧 SELECTIVE ROLLBACK PROCEDURES

### **Rollback Phase 1 Changes (Critical Conflicts)**
If only Phase 1 changes need reverting:

#### **Rollback material_balance_tolerance**
```bash
# Restore original tolerance values
sed -i 's/material_balance_tolerance: 0.0001  # 0.01% error tolerance (consolidated from initialization)/material_balance_tolerance: 0.01  # 1% error maximum/' \
  mrst_simulation_scripts/config/solver_config.yaml

# Restore initialization config
sed -i 's/# Material Balance Validation (moved to solver_config.yaml for consolidation)/# Material Balance Validation\n    material_balance_tolerance: 0.0001  # 0.01% error tolerance/' \
  mrst_simulation_scripts/config/initialization_config.yaml
```

#### **Rollback field_specifications**
```bash  
# Restore analysis_config.yaml field_specifications
cat > temp_field_specs << 'EOF'
# Field characteristics (Canon-First: authoritative field data)
field_specifications:
  field_name: "Eagle West Field"
  grid_dimensions: "41x41x12"
  total_design_wells: 15
  design_producers: 10
  design_injectors: 5
  simulation_duration_years: 10
EOF

# Replace reference with original content
sed -i '/^# Field characteristics reference/,/^field_source:/c\
# Field characteristics (Canon-First: authoritative field data)\
field_specifications:\
  field_name: "Eagle West Field"\
  grid_dimensions: "41x41x12"\
  total_design_wells: 15\
  design_producers: 10\
  design_injectors: 5\
  simulation_duration_years: 10' \
  mrst_simulation_scripts/config/analysis_config.yaml

# Restore development_config.yaml original
sed -i 's/# Field specifications (Canon-First: authoritative field data - CONSOLIDATED)/# Field specifications (Canon-First: authoritative field data)/' \
  mrst_simulation_scripts/config/development_config.yaml

sed -i '/  total_design_wells: 15/d' mrst_simulation_scripts/config/development_config.yaml
sed -i '/  design_producers: 10/d' mrst_simulation_scripts/config/development_config.yaml  
sed -i '/  design_injectors: 5/d' mrst_simulation_scripts/config/development_config.yaml
```

#### **Rollback initial_saturations**
```bash
# Restore simulation_config.yaml saturations
sed -i 's/  # Initial Saturations (moved to initialization_config.yaml for consolidation)/  # Initial Saturations (CANON - eliminate hardcoded values)/' \
  mrst_simulation_scripts/config/simulation_config.yaml

sed -i 's/  saturation_source: "initialization_config.yaml"  # Authoritative initial conditions/  initial_saturations:\
    sw_initial: 0.20                      # Initial water saturation (line 236, 472)\
    so_initial: 0.80                      # Initial oil saturation (line 236, 472)\
    sg_initial: 0.00                      # Initial gas saturation (line 236, 472)/' \
  mrst_simulation_scripts/config/simulation_config.yaml
```

#### **Remove units_config.yaml (if needed)**
```bash
# Remove new units file if causing issues
rm mrst_simulation_scripts/config/units_config.yaml

# Remove from any scripts that reference it
find mrst_simulation_scripts/ -name "*.m" -exec grep -l "units_config.yaml" {} \; | \
  xargs sed -i '/units_config.yaml/d'
```

---

## 🧪 VALIDATION AFTER ROLLBACK

### **Mandatory Tests After Rollback**
```bash
# Test core functionality
octave -q --eval "s21_run_simulation"
octave -q --eval "s22_analyze_results" 
octave -q --eval "s12_initialize_state"
octave -q --eval "s05_create_pebi_grid"

# Full workflow test
timeout 1800 octave mrst_simulation_scripts/s99_run_workflow.m
```

### **Validation Checklist**
- [ ] **s99 workflow completes** without YAML loading errors
- [ ] **All 20 phases execute** successfully  
- [ ] **No missing parameter errors** in MATLAB output
- [ ] **Simulation results match** previous known good results
- [ ] **Git status clean** or expected modifications only

---

## 📋 PARTIAL ROLLBACK STRATEGIES

### **Keep Successful Changes, Revert Problem Areas**
If some consolidation works but specific changes cause issues:

#### **Keep units_config.yaml, Revert Conflicts**
```bash
# Keep the new units file (if working)
# Revert only the conflicting parameter changes
git checkout HEAD~1 -- mrst_simulation_scripts/config/solver_config.yaml
git checkout HEAD~1 -- mrst_simulation_scripts/config/initialization_config.yaml
git checkout HEAD~1 -- mrst_simulation_scripts/config/analysis_config.yaml  
git checkout HEAD~1 -- mrst_simulation_scripts/config/development_config.yaml
git checkout HEAD~1 -- mrst_simulation_scripts/config/simulation_config.yaml

# Test with partial rollback
octave mrst_simulation_scripts/s99_run_workflow.m
```

#### **Keep Field Consolidation, Revert Solver Changes**
```bash
# If field specs consolidation works but solver tolerance causes issues
git checkout HEAD~1 -- mrst_simulation_scripts/config/solver_config.yaml
git checkout HEAD~1 -- mrst_simulation_scripts/config/initialization_config.yaml

# Keep field consolidation changes
# Test targeted rollback
octave mrst_simulation_scripts/s99_run_workflow.m
```

---

## 🔍 TROUBLESHOOTING COMMON ROLLBACK ISSUES

### **YAML Loading Errors After Rollback**
**Symptom**: "Parameter not found" or "Field does not exist" errors  
**Cause**: MATLAB scripts updated for consolidation but YAML rolled back  
**Solution**: 
```bash
# Reset both YAML and scripts together
git checkout HEAD~1 -- mrst_simulation_scripts/config/
git checkout HEAD~1 -- mrst_simulation_scripts/s*.m
```

### **Inconsistent Parameter Values**
**Symptom**: Different values for same parameter across configs  
**Cause**: Incomplete rollback of consolidated parameters  
**Solution**:
```bash
# Full rollback of specific file
git checkout HEAD~1 -- mrst_simulation_scripts/config/solver_config.yaml

# Or reset all configs to known good state
git checkout HEAD~1 -- mrst_simulation_scripts/config/
```

### **Missing units_config.yaml References**
**Symptom**: Scripts try to load units_config.yaml but file doesn't exist  
**Cause**: Scripts updated for units consolidation but file removed  
**Solution**:
```bash
# Restore units file OR remove references
git checkout HEAD -- mrst_simulation_scripts/config/units_config.yaml
# OR
find mrst_simulation_scripts/ -name "*.m" -exec sed -i '/units_config/d' {} \;
```

---

## 📊 ROLLBACK TESTING MATRIX

### **Test Matrix After Rollback**
| Test Case | Expected Result | Command |
|-----------|----------------|---------|
| Grid Creation | Success | `octave -q --eval "s05_create_pebi_grid"` |
| State Initialization | Success | `octave -q --eval "s12_initialize_state"` |
| Simulation Execution | Success | `octave -q --eval "s21_run_simulation"` |
| Results Analysis | Success | `octave -q --eval "s22_analyze_results"` |
| Full Workflow | Success | `octave s99_run_workflow.m` |
| Config Loading | No errors | `grep -r "error\|Error" *.log` |

---

## 🚀 RECOVERY STRATEGIES

### **Forward Recovery (Fix Issues Without Rollback)**
If rollback is undesirable, attempt forward fixes:

#### **Missing Parameter Quick Fixes**
```yaml
# Add missing parameter temporarily to problematic config
missing_parameter: "temporary_value"  # TODO: Fix in proper consolidation
```

#### **Duplicate Parameter Resolution**
```yaml
# Choose authoritative source and document decision
authoritative_parameter: "final_value"  # Consolidated from [source1, source2]
```

### **Progressive Recovery**
```bash
# Fix one config at a time
git checkout HEAD~1 -- mrst_simulation_scripts/config/solver_config.yaml
octave -q --eval "s21_run_simulation"  # Test

# If working, continue with next file
git checkout HEAD~1 -- mrst_simulation_scripts/config/analysis_config.yaml  
octave -q --eval "s22_analyze_results"  # Test
```

---

## 📋 PREVENTION FOR FUTURE CONSOLIDATION

### **Pre-Consolidation Safety Measures**
```bash
# Always create working branch
git checkout -b yaml-consolidation-attempt-$(date +%Y%m%d)

# Create comprehensive backup
git add -A
git commit -m "Pre-consolidation snapshot - complete working state"

# Test baseline before changes
octave mrst_simulation_scripts/s99_run_workflow.m > baseline_test.log 2>&1
```

### **Progressive Consolidation Strategy**
```bash
# One critical conflict at a time
git add mrst_simulation_scripts/config/solver_config.yaml
git commit -m "Fix material_balance_tolerance conflict only"
octave mrst_simulation_scripts/s99_run_workflow.m  # Test

git add mrst_simulation_scripts/config/analysis_config.yaml
git commit -m "Fix field_specifications conflict only"  
octave mrst_simulation_scripts/s99_run_workflow.m  # Test
```

---

## ✅ ROLLBACK SUCCESS CRITERIA

### **Successful Rollback Indicators**:
- [ ] **s99 workflow executes** completely without errors
- [ ] **All 20 phases complete** as before consolidation attempt
- [ ] **No YAML loading errors** in MATLAB output
- [ ] **Parameter values consistent** with pre-consolidation state
- [ ] **Git history preserved** with clear rollback documentation

### **Documentation Requirements**:
```bash
# Document rollback decision
git commit -m "Rollback YAML consolidation due to [specific issue]

Issue: [describe the problem that caused rollback]
Files affected: [list files rolled back]
Next steps: [plan for addressing the issue]

🤖 Generated with [Claude Code](https://claude.ai/code)

Co-Authored-By: Claude <noreply@anthropic.com>"
```

---

**CRITICAL REMINDER**: Always test s99 workflow functionality after ANY rollback operation. The ultimate success criterion is maintaining 100% simulation workflow functionality.