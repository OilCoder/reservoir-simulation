# SCRIPT UPDATE REQUIREMENTS - YAML CONSOLIDATION IMPACT

**Eagle West Field MRST Simulation Project**  
**Date**: 2025-08-31  
**Purpose**: Detailed MATLAB script modifications required for YAML consolidation

## 🎯 CRITICAL SCRIPT UPDATES (Priority 1)

### **s21_run_simulation.m - Solver Tolerance Consolidation**
**Issue**: material_balance_tolerance conflict resolved in `solver_config.yaml`  
**Action**: Remove tolerance loading from `initialization_config.yaml`, use `solver_config.yaml` only

**Required Changes**:
```matlab
% BEFORE (problematic dual loading)
init_cfg = read_yaml_config('initialization_config.yaml');
solver_cfg = read_yaml_config('solver_config.yaml');
tolerance = init_cfg.quality_control.material_balance_tolerance;  % 0.0001

% AFTER (single authoritative source)
solver_cfg = read_yaml_config('solver_config.yaml');
tolerance = solver_cfg.quality_control.material_balance_tolerance;  % 0.0001 (updated)
```

### **s22_analyze_results.m - Field Specifications Consolidation**
**Issue**: field_specifications removed from `analysis_config.yaml`, now in `development_config.yaml`  
**Action**: Load field specs from development config, not analysis config

**Required Changes**:
```matlab
% BEFORE (field specs in analysis config)
analysis_cfg = read_yaml_config('analysis_config.yaml');
field_name = analysis_cfg.field_specifications.field_name;
total_wells = analysis_cfg.field_specifications.total_design_wells;

% AFTER (field specs in development config)
development_cfg = read_yaml_config('development_config.yaml');
analysis_cfg = read_yaml_config('analysis_config.yaml');
field_name = development_cfg.field_specifications.field_name;
total_wells = development_cfg.field_specifications.total_design_wells;
```

### **s12_initialize_state.m - Initial Saturations Consolidation**
**Issue**: initial_saturations removed from `simulation_config.yaml`, kept in `initialization_config.yaml`  
**Action**: Remove simulation config loading for saturations

**Required Changes**:
```matlab
% BEFORE (dual loading)
init_cfg = read_yaml_config('initialization_config.yaml');
sim_cfg = read_yaml_config('simulation_config.yaml');
sw_init = sim_cfg.initial_saturations.sw_initial;  % Remove this

% AFTER (single source)
init_cfg = read_yaml_config('initialization_config.yaml');
sw_init = init_cfg.initial_saturations.oil_zone.water_saturation_range(1);
so_init = init_cfg.initial_saturations.oil_zone.oil_saturation_range(1);
```

### **s05_create_pebi_grid.m - Grid Dimensions Consolidation**  
**Issue**: grid_dimensions string removed from other configs, expanded form in `grid_config.yaml`  
**Action**: Use only grid_config.yaml for dimensions

**Required Changes**:
```matlab
% BEFORE (potentially conflicting sources)
grid_cfg = read_yaml_config('grid_config.yaml');
development_cfg = read_yaml_config('development_config.yaml');
dims_string = development_cfg.field_specifications.grid_dimensions;  % Remove this

% AFTER (single authoritative source)
grid_cfg = read_yaml_config('grid_config.yaml');
nx = grid_cfg.grid.nx;  % 41
ny = grid_cfg.grid.ny;  % 41  
nz = grid_cfg.grid.nz;  % 12
```

---

## 📋 UNIT CONVERSION SCRIPT UPDATES (Priority 2)

### **All Scripts Using Unit Conversions**
**Issue**: 45+ unit conversion duplications across 8 files  
**Action**: Load all conversions from new `units_config.yaml`

**Scripts Requiring Unit Conversion Updates**:
- `s02_process_pvt.m`
- `s09_create_fluid.m`
- `s12_initialize_state.m`
- `s13_validate_initial_state.m`
- `s21_run_simulation.m`
- `s22_analyze_results.m`

**Required Pattern Change**:
```matlab
% BEFORE (hardcoded or config-specific conversions)
m3_to_bbl = 6.289;  % Hardcoded
% OR
init_cfg = read_yaml_config('initialization_config.yaml');
m3_to_bbl = init_cfg.unit_conversions.m3_to_bbl;

% AFTER (centralized units)
units_cfg = read_yaml_config('units_config.yaml');
m3_to_bbl = units_cfg.unit_conversions.volume.m3_to_bbl;
psi_to_pa = units_cfg.unit_conversions.pressure.psi_to_pa;
day_to_sec = units_cfg.unit_conversions.time.day_to_seconds;
```

---

## 📋 WELLS PARAMETER SCRIPT UPDATES (Priority 2)

### **Scripts Using Well Counts/Names**
**Issue**: Well parameters duplicated in multiple configs  
**Action**: Load all well info from `wells_config.yaml` only

**Affected Scripts**:
- `s15_create_wells.m`
- `s17_create_controls.m`
- `s18_create_development.m`
- `s22_analyze_results.m`

**Required Changes**:
```matlab
% BEFORE (multiple sources)
analysis_cfg = read_yaml_config('analysis_config.yaml');
development_cfg = read_yaml_config('development_config.yaml');
total_wells = analysis_cfg.field_specifications.total_design_wells;
producers = development_cfg.field_standards.minimum_producers;

% AFTER (single well authority)
wells_cfg = read_yaml_config('wells_config.yaml');
total_wells = wells_cfg.well_specifications.total_design_wells;
producers = wells_cfg.well_counts.design_producers;
```

---

## 📋 DOMAIN BOUNDS SCRIPT UPDATES (Priority 3)

### **Scripts Using Field Extents**
**Issue**: Field bounds duplicated in grid, fault, structural configs  
**Action**: Use `grid_config.yaml` as single source for all geometry

**Affected Scripts**:
- `s03_process_structure.m`
- `s04_create_faults.m` 
- `s05_create_pebi_grid.m`

**Required Changes**:
```matlab
% BEFORE (multiple geometry sources)
grid_cfg = read_yaml_config('grid_config.yaml');
fault_cfg = read_yaml_config('fault_config.yaml');
struct_cfg = read_yaml_config('structural_framework_config.yaml');

field_x = fault_cfg.domain_bounds.field_extent_x;  % Remove
field_y = struct_cfg.field_bounds.extent_y;        % Remove

% AFTER (single geometry authority)
grid_cfg = read_yaml_config('grid_config.yaml');
field_x = grid_cfg.grid.field_extent_x;
field_y = grid_cfg.grid.field_extent_y;
x_min = grid_cfg.pebi_grid.domain_bounds.x_min;
x_max = grid_cfg.pebi_grid.domain_bounds.x_max;
```

---

## 📋 SPECIFIC FILE MODIFICATIONS

### **s99_run_workflow.m Updates**
**Issue**: Workflow script needs to handle consolidated config loading  
**Action**: Update validation checks for consolidated parameters

**Required Changes**:
```matlab
% Add units config loading
fprintf('Loading consolidated unit conversions...\n');
units_cfg = read_yaml_config('config/units_config.yaml');

% Update field specifications validation
fprintf('Validating field specifications from development config...\n');
development_cfg = read_yaml_config('config/development_config.yaml');
validate_field_specs(development_cfg.field_specifications);

% Remove redundant config validations
% OLD: validate multiple configs for same parameters
% NEW: validate single authoritative source per parameter type
```

### **read_yaml_config.m Utility Enhancement**
**Issue**: May need cross-reference resolution capability  
**Action**: Add optional reference resolution for consolidated configs

**Enhancement**:
```matlab
function config = read_yaml_config(yaml_file, resolve_references)
% Enhanced YAML loader with cross-reference resolution
% resolve_references: optional boolean to resolve field_source references

if nargin < 2
    resolve_references = false;
end

config = yaml.loadFile(yaml_file);

% Handle cross-references (e.g., field_source: "development_config.yaml")
if resolve_references && isfield(config, 'field_source')
    ref_config = read_yaml_config(config.field_source);
    config.field_specifications = ref_config.field_specifications;
end
```

---

## 🧪 VALIDATION SCRIPT UPDATES

### **validate_mrst_session.m Enhancement**
**Issue**: Validation logic needs to check consolidated parameter sources  
**Action**: Update validation to check single authoritative sources

**Required Changes**:
```matlab
% BEFORE (check multiple configs for consistency)
function validate_configs()
    analysis_cfg = read_yaml_config('analysis_config.yaml');
    development_cfg = read_yaml_config('development_config.yaml');
    
    % Check consistency - causes issues with consolidation
    if ~strcmp(analysis_cfg.field_specifications.field_name, ...
               development_cfg.field_specifications.field_name)
        error('Field name mismatch between configs');
    end
end

% AFTER (single source validation)
function validate_configs()
    development_cfg = read_yaml_config('development_config.yaml');
    grid_cfg = read_yaml_config('grid_config.yaml');
    units_cfg = read_yaml_config('units_config.yaml');
    
    % Validate single authoritative sources exist
    validate_required_fields(development_cfg, 'field_specifications');
    validate_required_fields(grid_cfg, 'grid');
    validate_required_fields(units_cfg, 'unit_conversions');
end
```

---

## 📋 TESTING INTEGRATION UPDATES

### **Test Scripts Modification Requirements**
**Issue**: Any test scripts checking config consistency need updates  
**Action**: Update tests to expect single sources, not duplications

**Pattern for Test Updates**:
```matlab
% BEFORE (test expects duplications)
function test_config_consistency()
    configs = {'analysis_config.yaml', 'development_config.yaml'};
    field_names = cellfun(@(f) read_yaml_config(f).field_specifications.field_name, ...
                         configs, 'UniformOutput', false);
    assert(all(strcmp(field_names, field_names{1})), 'Field names inconsistent');
end

% AFTER (test expects single authoritative source)
function test_config_consolidation()
    development_cfg = read_yaml_config('development_config.yaml');
    assert(isfield(development_cfg, 'field_specifications'), ...
           'Field specifications missing from authoritative source');
    
    % Ensure removed from other configs
    analysis_cfg = read_yaml_config('analysis_config.yaml');
    assert(~isfield(analysis_cfg, 'field_specifications'), ...
           'Field specifications not properly consolidated');
end
```

---

## 📋 IMPLEMENTATION CHECKLIST

### **Phase 1: Critical Script Updates**
- [ ] **s21_run_simulation.m**: Update material balance tolerance loading
- [ ] **s22_analyze_results.m**: Load field specifications from development config  
- [ ] **s12_initialize_state.m**: Remove simulation config saturation loading
- [ ] **s05_create_pebi_grid.m**: Use grid config only for dimensions
- [ ] **Test**: Run these 4 scripts individually to verify fixes

### **Phase 2: Unit Conversion Updates**
- [ ] **All simulation scripts**: Add units_config.yaml loading
- [ ] **Replace all hardcoded conversions**: Use units_cfg references
- [ ] **Test**: Verify all unit conversions resolve correctly
- [ ] **Validate**: Check no hardcoded conversion factors remain

### **Phase 3: Wells and Domain Updates**
- [ ] **Wells scripts**: Load well parameters from wells_config.yaml only
- [ ] **Geometry scripts**: Load domain bounds from grid_config.yaml only
- [ ] **Test**: Verify wells and geometry scripts work correctly
- [ ] **Final validation**: Run complete s99 workflow

### **Phase 4: Workflow Integration**
- [ ] **s99_run_workflow.m**: Update for consolidated config loading
- [ ] **Validation utilities**: Update consistency checks
- [ ] **Test scripts**: Modify to expect consolidation, not duplication
- [ ] **Final test**: Complete workflow with all modifications

---

## ⚠️ CRITICAL SUCCESS FACTORS

### **Modification Order Requirements**:
1. **Fix critical conflicts first** (material balance, field specs, saturations)
2. **Test each fix immediately** before proceeding to next
3. **Add unit conversions** after critical fixes verified
4. **Update remaining scripts** only after core functionality confirmed

### **Error Handling During Updates**:
```matlab
% Add defensive loading for transition period
function cfg = safe_load_config(primary_file, backup_file, parameter_path)
    try
        cfg = read_yaml_config(primary_file);
        value = eval(['cfg.' parameter_path]);
    catch
        warning('Loading %s from backup config %s', parameter_path, backup_file);
        cfg = read_yaml_config(backup_file);
        value = eval(['cfg.' parameter_path]);
    end
end
```

### **Rollback Capability**:
```bash
# Keep backup of original scripts before modifications
mkdir -p backups/scripts_pre_consolidation
cp mrst_simulation_scripts/s*.m backups/scripts_pre_consolidation/

# Test rollback procedure
git stash push -m "script updates for YAML consolidation"
# If issues: git stash pop to restore original state
```

---

**SUCCESS METRIC**: All 25 MRST simulation scripts successfully load parameters from consolidated YAML sources with 0% duplication and 100% functional preservation.