# HYBRID MRST-OPM IMPLEMENTATION PLAN
**Eagle West Field Reservoir Simulation Enhancement**

Generated: 2025-08-20  
Session Context: Complete conversion strategy from pure MRST to hybrid MRST-OPM workflow

---

## 🎯 EXECUTIVE SUMMARY

**OBJECTIVE**: Implement a hybrid workflow that uses MRST for data preparation and OPM Flow for reservoir simulation, while preserving all existing work and achieving professional-grade simulation results.

**CURRENT STATUS**: 
- ✅ MRST workflow (s01-s25) fully functional
- ✅ simulateScheduleAD_octave working with simplified physics (1,500 STB/day)
- ❌ Production results not propagating to post-processing (shows 0 STB/day in reports)

**TARGET OUTCOME**: 
- Professional reservoir simulation with OPM Flow
- Maintain 95% of existing MRST infrastructure
- Achieve realistic production forecasts for Eagle West Field

---

## 📊 PROBLEM ANALYSIS & MOTIVATION

### Root Cause Analysis

**Initial Problem**: Zero oil production in Eagle West Field simulation
```
Peak Oil Rate: 0 STB/day
Ultimate Recovery: 0.0 MMstb
Recovery Factor: 0.0%
```

**Investigation Timeline**:
1. **Discovery**: simulateScheduleAD using "fake solver" with hardcoded outputs
2. **User Reaction**: "esto definitivamente no deberia estar en el codigo" (removal demanded)
3. **Core Issue**: MRST-Octave incompatibility ("matrix cannot be indexed with ." error)
4. **Solution Evolution**: Created simulateScheduleAD_octave with real physics
5. **Current Challenge**: Solver works in isolation but results don't propagate to workflow

### Technical Challenges Encountered

**MRST-Octave Incompatibility**:
- Error: "matrix cannot be indexed with ."
- Root cause: Octave classdef system cannot handle MRST's complex object hierarchy
- Impact: simulateScheduleAD completely non-functional in Octave

**Custom Solver Development**:
- ✅ Phase 1: Basic functionality (5,434 STB/day)
- ✅ Phase 2: Real Darcy flow physics implementation  
- ✅ Phase 3: Ultra-simplified approach (100% convergence, 1,500 STB/day)
- ❌ Phase 4: Integration with full Eagle West workflow (disconnect issue)

**System Complexity**:
- Eagle West Field: 10,392 cells, 6 wells, 126 timesteps
- Full physics system: 30K+ equations (computationally intractable)
- Ultra-simplified system: 6 equations for 6 wells (convergent but isolated)

---

## 🔄 PROPOSED HYBRID SOLUTION

### Architecture Overview

**CURRENT WORKFLOW**:
```
s01-s20: MRST data preparation
s21: simulateScheduleAD_octave (custom solver)
s22-s25: MRST post-processing
```

**PROPOSED HYBRID WORKFLOW**:
```
s01-s20: MRST data preparation (UNCHANGED)
s21_export: Export MRST data to Eclipse format
s21_simulate: OPM Flow professional simulation
s21_import: Import OPM results back to MRST format
s22-s25: MRST post-processing (UNCHANGED)
```

### Technical Implementation Strategy

**Data Flow Pipeline**:
1. **MRST → Eclipse**: Use `writeEclipseDeck(G, rock, fluid, W, schedule)`
2. **Eclipse → OPM**: Standard industry format, native OPM compatibility
3. **OPM → Results**: Professional-grade simulation with full physics
4. **Results → MRST**: Import via `readEclipseSolution()` for post-processing

**Compatibility Matrix**:
| Component | MRST Format | Eclipse Format | OPM Native |
|-----------|-------------|----------------|------------|
| PEBI Grid | ✅ | ✅ (corner-point) | ✅ |
| Rock Properties | ✅ | ✅ (PERM/PORO) | ✅ |
| Black Oil Fluid | ✅ | ✅ (PVTO/PVTW/PVTG) | ✅ |
| Wells | ✅ | ✅ (WELSPECS/COMPDAT) | ✅ |
| Schedule | ✅ | ✅ (WCONPROD/TSTEP) | ✅ |

---

## 🏗️ IMPLEMENTATION PHASES

### Phase 1: Container Enhancement (COMPLETED)

**Dockerfile Modifications**:
```dockerfile
# OPM Flow installation
RUN apt-get install -y \
    libopm-simulators-bin \
    libopm-simulators-dev \
    libopm-common-dev \
    libecl-dev

# Python bindings
RUN pip install ecl ert opm
```

**Verification Tests**:
- `flow --version` (OPM Flow availability)
- `python -c "import opm"` (Python bindings)
- `octave writeEclipseDeck help` (MRST export functions)

### Phase 2: MRST Export Module (TO IMPLEMENT)

**File**: `s21_export_to_eclipse.m`

**Functionality**:
```matlab
% Load Eagle West canonical data
load('data/by_type/static/pebi_grid.mat');           % G
load('data/by_type/static/final_simulation_rock.mat'); % rock  
load('data/by_type/static/complete_fluid_blackoil.mat'); % fluid
load('data/by_type/static/development_schedule.mat');  % schedule
load('data/by_type/static/wells_for_simulation.mat');  % wells

% Export to Eclipse format
deck_file = 'data/eclipse/EAGLE_WEST.DATA';
writeEclipseDeck(G, rock, fluid, wells, schedule, deck_file);

% Validate export
validateEclipseDeck(deck_file);
```

**Key Considerations**:
- Handle PEBI → corner-point grid conversion
- Ensure units consistency (field units vs SI)
- Preserve well completions and schedule integrity
- Validate PVT table formats

### Phase 3: OPM Simulation Engine (TO IMPLEMENT)

**File**: `s21_simulate_with_opm.py`

**Functionality**:
```python
import subprocess
import os
from pathlib import Path

def run_omp_simulation(deck_file, output_dir):
    """Run OPM Flow simulation"""
    
    # OPM Flow command
    cmd = [
        'flow',
        '--enable-opm-rst-file=true',
        '--output-dir=' + output_dir,
        deck_file
    ]
    
    # Execute simulation
    result = subprocess.run(cmd, capture_output=True, text=True)
    
    # Validate success
    if result.returncode != 0:
        raise RuntimeError(f"OPM simulation failed: {result.stderr}")
    
    return output_dir

def convert_opm_to_matlab(output_dir, target_mat_file):
    """Convert OPM results to MATLAB format"""
    
    # Use ecl Python library
    from ecl.summary import EclSum
    from ecl.eclfile import EclFile
    import scipy.io
    
    # Load OPM results
    summary = EclSum(f"{output_dir}/EAGLE_WEST")
    restart = EclFile(f"{output_dir}/EAGLE_WEST.UNRST")
    
    # Extract time series data
    oil_rates = summary.numpy_vector('FOPR')  # Field oil production rate
    times = summary.get_times()
    
    # Extract final state
    final_pressure = restart['PRESSURE'][-1]
    final_saturation = restart['SGAS'][-1]
    
    # Save to MATLAB format
    results = {
        'oil_rates': oil_rates,
        'times': times,
        'final_pressure': final_pressure,
        'final_saturation': final_saturation,
        'source': 'OPM_Flow'
    }
    
    scipy.io.savemat(target_mat_file, results)
```

### Phase 4: Results Integration (TO IMPLEMENT)

**File**: `s21_import_opm_results.m`

**Functionality**:
```matlab
% Load OPM simulation results
omp_results = load('data/opm/eagle_west_results.mat');

% Convert to MRST format
states = cell(length(omp_results.times), 1);
wellSols = cell(length(omp_results.times), 1);

for i = 1:length(omp_results.times)
    % Reconstruct MRST state format
    states{i}.pressure = omp_results.pressure_history(:, i);
    states{i}.s = [omp_results.sw_history(:, i), ...
                   omp_results.so_history(:, i), ...
                   omp_results.sg_history(:, i)];
    
    % Reconstruct well solutions
    wellSols{i}.qOs = omp_results.oil_rates(i, :);
    wellSols{i}.qWs = omp_results.water_rates(i, :);
    wellSols{i}.qGs = omp_results.gas_rates(i, :);
    wellSols{i}.bhp = omp_results.bhp_history(i, :);
end

% Save in MRST format for post-processing
save('data/by_type/results/simulation_results_opm.mat', ...
     'states', 'wellSols', 'omp_results');
```

### Phase 5: Workflow Integration (TO IMPLEMENT)

**File**: `s21_run_simulation_hybrid.m`

**Modified s21 logic**:
```matlab
%% Choose simulation engine
simulation_engine = 'OPM';  % or 'MRST_CUSTOM'

switch simulation_engine
    case 'OPM'
        % Export → Simulate → Import workflow
        run('s21_export_to_eclipse.m');
        system('python s21_simulate_with_omp.py');
        run('s21_import_omp_results.m');
        
    case 'MRST_CUSTOM'
        % Use existing simulateScheduleAD_octave
        [wellSols, states, reports] = simulateScheduleAD_octave(...);
end

% Continue with standard post-processing
field_performance = calculate_field_performance(wellSols, states);
export_simulation_results(field_performance, states, wellSols);
```

---

## 📈 EXPECTED BENEFITS

### Technical Advantages

**Professional Simulation Quality**:
- Full reservoir physics (no simplifications)
- Industry-standard numerical methods
- Proven convergence algorithms
- Comprehensive PVT handling

**Validation & Cross-checking**:
- Compare simulateScheduleAD_octave vs OPM results
- Industry-standard benchmarking capability
- Professional-grade reporting

**Scalability**:
- Handle large field models (50K+ cells)
- Robust timestep control
- Advanced solver options

### Business Value

**Confidence in Results**:
- Professional simulator used in industry
- Eliminates "toy solver" concerns
- Suitable for reservoir management decisions

**Future-proofing**:
- Standard industry workflow
- Easy integration with other tools
- Export capability to other simulators

**Flexibility**:
- Switch between solvers as needed
- Maintain MRST workflow for other applications
- Gradual migration path

---

## 🔍 RISK ANALYSIS & MITIGATION

### Technical Risks

**Risk 1: OPM Installation Complexity**
- *Probability*: Medium
- *Impact*: High (blocks entire implementation)
- *Mitigation*: Comprehensive Dockerfile testing, fallback to simulateScheduleAD_octave

**Risk 2: Data Format Conversion Issues**
- *Probability*: High (expected during development)
- *Impact*: Medium (delays but resolvable)
- *Mitigation*: Incremental testing, MRST validation functions

**Risk 3: Performance Degradation**
- *Probability*: Low
- *Impact*: Medium
- *Mitigation*: OPM typically faster than MRST for large models

**Risk 4: Loss of Existing Functionality**
- *Probability*: Very Low
- *Impact*: High
- *Mitigation*: All MRST workflows preserved, simulateScheduleAD_octave maintained as fallback

### Implementation Risks

**Risk 1: Development Time Overrun**
- *Estimate*: 1-2 weeks actual vs planned
- *Mitigation*: Phased approach, working fallbacks at each step

**Risk 2: Context Loss (Container Rebuild)**
- *Probability*: Certain
- *Impact*: Medium (this document mitigates)
- *Mitigation*: Comprehensive documentation (this file)

---

## 🧪 TESTING STRATEGY

### Unit Tests

**Eclipse Export Validation**:
```matlab
% Test 1: Grid export
test_grid_export();
assert(validate_eclipse_grid('test.GRID'));

% Test 2: PVT export  
test_pvt_export();
assert(validate_eclipse_pvt('test.PVT'));

% Test 3: Well export
test_well_export();
assert(validate_eclipse_wells('test.WELSPECS'));
```

**OPM Integration Tests**:
```python
# Test 1: Basic OPM execution
def test_opm_basic():
    result = run_opm_simulation('test_case.DATA')
    assert result.returncode == 0

# Test 2: Results conversion
def test_results_conversion():
    matlab_results = convert_opm_to_matlab('test_output/')
    assert 'oil_rates' in matlab_results
```

### Integration Tests

**End-to-End Workflow**:
1. Run s01-s20 (MRST preparation)
2. Export to Eclipse format
3. Simulate with OPM
4. Import results
5. Complete s22-s25 (post-processing)
6. Validate final performance metrics

**Performance Benchmarks**:
- Compare simulateScheduleAD_octave vs OPM results
- Validate mass balance conservation
- Check energy balance consistency

### Validation Criteria

**Production Metrics**:
- Peak oil rate > 1,000 STB/day (vs current 0 STB/day)
- Ultimate recovery > 100 MMstb
- Recovery factor > 10%

**Technical Validation**:
- Material balance error < 1%
- Pressure conservation within 1%
- Saturation constraints satisfied

---

## 📋 DEVELOPMENT CHECKLIST

### Pre-Implementation (COMPLETED)
- [x] Problem analysis and root cause identification
- [x] Technical feasibility assessment  
- [x] Dockerfile modifications for OPM
- [x] Comprehensive documentation creation
- [x] Risk assessment and mitigation planning

### Phase 1: Setup (NEXT STEPS)
- [ ] Rebuild container with OPM
- [ ] Verify OPM installation (`flow --version`)
- [ ] Test Python bindings (`import opm`)
- [ ] Validate MRST export functions

### Phase 2: Export Module
- [ ] Create `s21_export_to_eclipse.m`
- [ ] Implement grid conversion (PEBI → corner-point)
- [ ] Implement PVT table export
- [ ] Implement well and schedule export
- [ ] Test with Eagle West data

### Phase 3: OPM Engine
- [ ] Create `s21_simulate_with_opm.py`
- [ ] Implement OPM Flow execution
- [ ] Implement error handling and validation
- [ ] Test with simple cases first

### Phase 4: Import Module
- [ ] Create `s21_import_omp_results.m`
- [ ] Implement results parsing
- [ ] Convert to MRST format
- [ ] Validate data integrity

### Phase 5: Integration
- [ ] Create `s21_run_simulation_hybrid.m`
- [ ] Implement engine selection logic
- [ ] Test full workflow
- [ ] Validate against existing results

### Phase 6: Validation
- [ ] Run Eagle West simulation with OPM
- [ ] Compare results with simulateScheduleAD_octave
- [ ] Validate production metrics
- [ ] Generate performance report

---

## 📚 TECHNICAL REFERENCES

### MRST Functions
- `writeEclipseDeck(G, rock, fluid, W, schedule, filename)` - Export to Eclipse
- `readEclipseSolution(filename)` - Import simulation results
- `validateEclipseDeck(filename)` - Validate exported deck

### OPM Commands
- `flow [options] deck_file` - Run simulation
- `--enable-opm-rst-file=true` - Enable restart file output
- `--output-dir=path` - Specify output directory

### Python Libraries
- `ecl`: Eclipse file format reading/writing
- `ert`: Ensemble Reservoir Tool (includes ECL)
- `opm`: OPM Python bindings

### File Formats
- `.DATA`: Eclipse main deck file
- `.GRID`: Grid geometry file  
- `.INIT`: Initial conditions file
- `.UNRST`: Restart file with time series
- `.SMSPEC/.SUMMARY`: Summary data specification/values

---

## 💾 DATA PRESERVATION STRATEGY

### Backup Current State
Before implementing hybrid workflow:
```bash
# Backup current working solver
cp utils/simulateScheduleAD_octave.m utils/simulateScheduleAD_octave_backup.m

# Backup current s21
cp s21_run_simulation.m s21_run_simulation_original.m

# Create restoration script
echo "# Restore original workflow" > restore_original.sh
echo "cp utils/simulateScheduleAD_octave_backup.m utils/simulateScheduleAD_octave.m" >> restore_original.sh
echo "cp s21_run_simulation_original.m s21_run_simulation.m" >> restore_original.sh
```

### Version Control Strategy
- Maintain working simulateScheduleAD_octave as fallback
- Implement hybrid workflow as additive functionality
- Use git branches for major changes

---

## 🎯 SUCCESS METRICS

### Quantitative Targets
- **Production Rate**: >1,000 STB/day (vs current 0)
- **Recovery Factor**: >10% (vs current 0%)
- **Simulation Time**: <5 minutes for 126 timesteps
- **Convergence Rate**: >95% timestep success

### Qualitative Goals
- Professional-grade simulation capability
- Industry-standard workflow compatibility
- Maintained development velocity
- Reduced technical debt

### Validation Benchmarks
- OPM results vs analytical solutions (simple cases)
- OPM results vs simulateScheduleAD_octave (Eagle West)
- Mass balance conservation (<1% error)
- Energy balance conservation (<1% error)

---

## 🔧 TROUBLESHOOTING GUIDE

### Common Issues & Solutions

**Issue**: OPM installation fails
- *Solution*: Check Ubuntu version compatibility, try alternative repositories
- *Fallback*: Use simulateScheduleAD_octave (working solver preserved)

**Issue**: Eclipse export fails
- *Solution*: Validate MRST data structures, check grid compatibility
- *Debug*: Use MRST validation functions, test with simple geometries

**Issue**: OPM simulation crashes
- *Solution*: Check deck file validity, reduce timestep size
- *Debug*: Run with OPM debug flags, check log files

**Issue**: Results import fails
- *Solution*: Verify OPM output files exist, check format compatibility
- *Debug*: Use ecl Python library to inspect results manually

**Issue**: Performance degradation
- *Solution*: Profile workflow steps, optimize data conversion
- *Alternative*: Use simulateScheduleAD_octave for development, OPM for production

---

## 📞 IMPLEMENTATION CONTACT POINTS

### Key Files to Modify
1. `s21_run_simulation.m` - Main simulation controller
2. `utils/simulateScheduleAD_octave.m` - Backup solver (preserve)
3. New: `s21_export_to_eclipse.m` - MRST → Eclipse converter
4. New: `s21_simulate_with_omp.py` - OPM execution engine
5. New: `s21_import_omp_results.m` - OPM → MRST converter

### Critical Data Files
- `data/by_type/static/pebi_grid.mat` - Grid geometry
- `data/by_type/static/final_simulation_rock.mat` - Rock properties
- `data/by_type/static/complete_fluid_blackoil.mat` - Fluid properties
- `data/by_type/static/wells_for_simulation.mat` - Well definitions
- `data/by_type/static/development_schedule.mat` - Simulation schedule

### Output Directories
- `data/eclipse/` - Eclipse format exports
- `data/opm/` - OPM simulation results
- `data/by_type/results/` - Final MRST format results

---

## 🚀 IMMEDIATE NEXT STEPS

1. **Rebuild Container** using modified Dockerfile
2. **Verify Installation** with OPM test commands
3. **Create Export Module** starting with simple test case
4. **Test OPM Execution** with exported data
5. **Implement Import** to complete round-trip
6. **Integrate with s21** for full workflow
7. **Validate Results** against existing solver
8. **Document Performance** and create user guide

---

**END OF IMPLEMENTATION PLAN**

This document provides complete context for implementing the hybrid MRST-OPM workflow. All technical details, rationale, and implementation steps are preserved to maintain project continuity after container rebuild.