# SOLVER STRATEGY - Eagle West Field MRST Simulation

## 🎯 Branch-Based Solver Organization

This repository uses a **branch-based approach** for different MRST solver implementations, allowing parallel development and easy comparison of simulation results.

## 🌿 Branch Structure

### `main` - Production Baseline
- **Current Status**: Latest stable implementation
- **Default Branch**: Primary development and integration
- **Merging**: All tested solver implementations merge back to main

### `incompTPFA` - Incompressible Two-Point Flux Solver
- **Solver Type**: `incompTPFA` (MRST incompressible pressure solver)
- **Status**: ✅ **WORKING** - Validated implementation
- **Production Rate**: 20,630 bbl/day
- **Recovery Factor**: 1.2% (limited by incompressible assumptions)
- **Use Case**: Pressure-driven flow, single-phase oil, no gas/compressibility
- **Limitations**: 
  - No gas liberation
  - No oil compressibility effects
  - Unrealistic recovery factors for real reservoirs
  - Steady-state pressure assumptions

### `ad-blackoil` - Automatic Differentiation Black-Oil Solver
- **Solver Type**: `ad-blackoil` (MRST compressible multi-phase solver)
- **Status**: 🚧 **PLANNED** - Not implemented yet
- **Target Features**:
  - Gas liberation and dissolution (Rs, Bo curves)
  - Oil and gas compressibility
  - Realistic PVT behavior with bubble point pressure
  - Time-dependent pressure depletion
  - Realistic recovery factors (15-25% for primary recovery)
- **Expected Performance**: More realistic production decline and recovery
- **Migration Priority**: HIGH - Next major implementation phase

### `experimental` - Testing Ground
- **Purpose**: Testing other MRST solvers and experimental configurations
- **Status**: 🧪 **SANDBOX** - For exploration
- **Potential Solvers**:
  - `eosAD` - Compositional equation of state
  - `fully-implicit` - Advanced fully-implicit solvers
  - `geothermal` - Thermal recovery methods
  - Custom solvers and enhanced oil recovery (EOR) methods
- **Use Case**: Research, validation, and proof-of-concept implementations

## 🔄 Solver Migration Strategy

### Phase 1: Current State (incompTPFA) ✅ COMPLETE
```
YAML Config → MATLAB Processing → incompTPFA → Basic Results
```
- **Completed**: Working simulation with 25 scripts
- **Data**: 9 modular .mat files with validated results
- **Performance**: 20,630 bbl/day production rate
- **Limitation**: Unrealistic 1.2% recovery due to incompressible flow

### Phase 2: Compressible Implementation (ad-blackoil) 🎯 NEXT
```
YAML Config → MATLAB Processing → ad-blackoil → Realistic Results
```
- **Implementation Steps**:
  1. PVT table processing (bubble point, gas-oil ratio)
  2. Compressible fluid properties (Bo, Rs, μo curves)
  3. ad-blackoil solver integration
  4. Time-stepping and pressure depletion
  5. Validation against field analogues
- **Expected Outcome**: 15-25% recovery factor with realistic decline curves
- **Timeline**: Priority implementation after incompTPFA validation

### Phase 3: Advanced Solvers (experimental) 🔬 FUTURE
```
YAML Config → MATLAB Processing → Advanced Solvers → Specialized Results
```
- **Research Areas**:
  - Compositional modeling for volatile oils
  - Enhanced oil recovery (EOR) methods
  - Thermal recovery processes
  - Fractured reservoir modeling
- **Timeline**: After ad-blackoil completion and production needs assessment

## 📊 Performance Comparison Framework

### Current Results (incompTPFA)
| Metric | Value | Realistic? |
|--------|-------|------------|
| **Production Rate** | 20,630 bbl/day | ✅ Reasonable for 15 wells |
| **Initial Oil Saturation** | 71.1% | ✅ Typical for oil reservoir |
| **Recovery Factor** | 1.2% | ❌ Unrealistically low |
| **Pressure Decline** | Minimal | ❌ Should show depletion |
| **Gas Production** | None | ❌ Should have solution gas |

### Expected Results (ad-blackoil)
| Metric | Expected Value | Basis |
|--------|---------------|-------|
| **Production Rate** | 18,000-22,000 bbl/day | Compressible decline |
| **Initial Oil Saturation** | 71.1% | Same as incompTPFA |
| **Recovery Factor** | 15-25% | Industry standard primary recovery |
| **Pressure Decline** | 500-1000 psi/year | Realistic depletion |
| **Gas Production** | 2000-4000 scf/stb | Solution gas drive |

## 🔧 Implementation Guidelines

### Switching Between Solvers

**Check current branch:**
```bash
git branch
```

**Switch to specific solver:**
```bash
# Switch to incompressible solver
git checkout incompTPFA

# Switch to compressible solver (when available)
git checkout ad-blackoil

# Switch to experimental testing
git checkout experimental
```

**Compare solver results:**
```bash
# Compare branches
git diff incompTPFA ad-blackoil

# Compare specific files
git diff incompTPFA:data/mrst/results.mat ad-blackoil:data/mrst/results.mat
```

### Development Workflow

1. **Create feature branch** from appropriate solver branch:
   ```bash
   git checkout ad-blackoil
   git branch feature/pvt-table-integration
   git checkout feature/pvt-table-integration
   ```

2. **Implement changes** following Canon-First Policy:
   - Update YAML configurations first
   - Implement MATLAB processing logic
   - Integrate with MRST solver
   - Validate results against documentation

3. **Test and validate**:
   ```bash
   octave mrst_simulation_scripts/s99_run_workflow.m
   ```

4. **Merge back to solver branch**:
   ```bash
   git checkout ad-blackoil
   git merge feature/pvt-table-integration
   ```

5. **Integrate to main** when stable:
   ```bash
   git checkout main
   git merge ad-blackoil
   ```

## 📋 Technical Specifications

### Grid and Wells (Consistent Across All Solvers)
- **Grid**: 41×41×12 cells (20,332 total cells)
- **Wells**: 15 total (EW-001 to EW-010 producers, IW-001 to IW-005 injectors)
- **Reservoir Volume**: ~2,850 acres, 200 ft gross thickness
- **Faults**: 5 major faults (Fault_A through Fault_E)

### Fluid Properties (Solver-Dependent)
| Property | incompTPFA | ad-blackoil | experimental |
|----------|------------|-------------|--------------|
| **Phases** | Oil + Water | Oil + Gas + Water | Variable |
| **Compressibility** | None | Full PVT | Variable |
| **Gas Liberation** | None | Rs, Bo curves | Advanced |
| **Pressure Dependence** | None | Full PVT tables | Variable |

## 🚀 Next Steps

### Immediate Actions (Week 1-2)
1. ✅ **Complete**: Current incompTPFA implementation committed
2. ✅ **Complete**: Branch structure created
3. 🎯 **Next**: Document PVT requirements for ad-blackoil
4. 🎯 **Next**: Implement fluid property processing

### Short-term Goals (Month 1)
- Complete ad-blackoil solver integration
- Validate compressible results against field data
- Create automated comparison framework
- Document performance differences

### Long-term Vision (Months 2-6)
- Implement advanced solver options in experimental branch
- Create production forecasting capabilities
- Integrate enhanced oil recovery methods
- Develop uncertainty quantification framework

---

**Last Updated**: 2025-08-30  
**Current Status**: incompTPFA working, ad-blackoil planned, experimental ready  
**Next Milestone**: ad-blackoil solver implementation with realistic recovery factors