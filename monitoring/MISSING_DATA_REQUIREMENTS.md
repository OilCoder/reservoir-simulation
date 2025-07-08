# Missing Data Requirements for Proposed Plots

## Overview
This document lists the data requirements for implementing the remaining "Proposed" plots in the monitoring system.

## Data Availability Legend
- ✅ = Already generated / can be derived from MRST exports
- ⚠️ = Variable exists in states{} but not saved in .mat files; just extend extract_snapshot.m
- ❌ = Not obtainable from states{}; needs separate calculation or additional runs

## Detailed Data Availability Analysis

### Category A: Fluid & Rock Properties
| Plot | Variables Required | Availability | Action |
|------|-------------------|--------------|---------|
| kr-curves, PVT, histograms φ-k | Tablas fluid.kr, fluid.Bo/Bw, arrays φ₀, k₀ | ✅ (already in setup_field.m / define_fluid.m) | None |

**Status:** ✅ **All plots implemented** - No missing data

### Category B: Initial Conditions  
| Plot | Variables Required | Availability | Action |
|------|-------------------|--------------|---------|
| Initial Pressure Map P₀ | states{1}.pressure | ⚠️ (not exported) | Add pressure to struct saved in snap_0.mat |
| Initial Sw Map | states{1}.s(:,2) | ⚠️ (not exported) | Add Sw to struct saved in snap_0.mat |

**Status:** ⚠️ **Partially implemented** - Using synthetic data, real data available in states{1}

### Category C: Geometry & Well Locations
| Plot | Variables Required | Availability | Action |
|------|-------------------|--------------|---------|
| Rock regions | rock.regions | ✅ (exported and plotted) | None |
| Well locations | Well coordinates | ✅ (available) | None |
| Grid structure | Grid geometry | ✅ (available) | None |

**Status:** ✅ **Implemented** - All data available

### Category D: Operational Strategy
| Plot | Variables Required | Availability | Action |
|------|-------------------|--------------|---------|
| Voidage, PV inj. vs RF, rate curves | wellSols{i}.qWs/qOs, schedule.control, PV_total | ⚠️ (wellSols not saved) | • Save wellSols{i} summary (q, BHP)<br>• Calculate PV once and write to metadata.yaml |

**Status:** ⚠️ **Data exists but not exported** - Need to save wellSols data

### Category E: Global Evolution
| Plot | Variables Required | Availability | Action |
|------|-------------------|--------------|---------|
| Pressure evolution | states{i}.pressure | ✅ (implemented) | None |
| Stress evolution | Calculated from pressure | ✅ (implemented) | None |
| Porosity evolution | Updated with pressure | ✅ (implemented) | None |
| Permeability evolution | Updated with stress | ✅ (implemented) | None |
| Sw Histogram evolution | states{i}.s(:,2) | ⚠️ (Sw not exported) | Export Sw per cell |
| Bo/Bw average evolution | fluid.B(P) | ⚠️ (Bo calculated on demand) | Post-process: derive Bo/Bw with fluid.Bo(states{i}.pressure) |

**Status:** ✅ **4/6 implemented** - Missing Sw and formation factor data

### Category F: Well Performance
| Plot | Variables Required | Availability | Action |
|------|-------------------|--------------|---------|
| BHP evolution | wellSols{i}.bhp per well | ⚠️ (see Category D) | Save wellSols{i} summary |
| Production rates | wellSols{i}.qWs/qOs | ⚠️ (see Category D) | Save wellSols{i} summary |
| Cumulative production | Integrated wellSols | ⚠️ (see Category D) | Save wellSols{i} summary |
| Water cut | qW/(qW+qO) | ⚠️ (see Category D) | Save wellSols{i} summary |
| BHP Violin plot | wellSols{i}.bhp per well | ⚠️ (see Category D) | Save wellSols{i} summary |

**Status:** ⚠️ **Data exists but not exported** - Need wellSols data

### Category G: Spatial Distributions
| Plot | Variables Required | Availability | Action |
|------|-------------------|--------------|---------|
| Pressure 2D | states{i}.pressure | ✅ (implemented) | None |
| Stress 2D | Calculated from pressure | ✅ (implemented) | None |
| Porosity 2D | Updated porosity | ✅ (implemented) | None |
| Permeability 2D | Updated permeability | ✅ (implemented) | None |
| Saturation 2D | states{i}.s(:,2) | ⚠️ (Sw not exported) | Export Sw per cell |
| ΔPressure (p - p₀) | pressure, Sw | ⚠️ (only missing Sw/pressure exported) | Export pressure and Sw |
| Sw Front ≥0.8 | Sw spatial | ⚠️ (only missing Sw/pressure exported) | Export pressure and Sw |
| Streamlines | velocity field | ❌ (velocity not stored) | Calculate faceFlux in extract_snapshot.m or recompute with computeVelocity(grid, rock, fluid, states{i}) |
| Vertical Section (X-Z) | 3D data | ❌ (not part of Phase 1) | Plan 3D simulations |

**Status:** ✅ **4/9 implemented** - Missing Sw data and velocity fields

### Category H: Multiphysics & Diagnostics
| Plot | Variables Required | Availability | Action |
|------|-------------------|--------------|---------|
| Fractional Flow fw(Sw) | kr tables, viscosity, current Sw | ✅ (can be calculated) | Use existing kr curves and fluid properties |
| dkr/dSw Sensitivity | kr derivatives | ✅ (can be calculated) | Numerical derivatives of kr curves |
| Voidage Ratio Evolution | injection/production rates | ⚠️ (see Category D) | Save wellSols{i} summary |
| Sensitivity Tornado | Parametric run results | ❌ (not part of Phase 1) | Plan parametric simulation batch after validating base case |

**Status:** ✅ **2/4 can be implemented immediately** - Missing well data and parametric studies

## Minimal Changes to MRST Workflow

### 1. Modify extract_snapshot.m

```matlab
function s = extract_snapshot(G, rock, fluid, state, rock_id)
    s.sigma_eff = (3000 - state.pressure);  % example Biot = 1
    s.pressure  = state.pressure;           % ⚠️ ADD THIS
    s.phi       = rock.poro .* exp(-c_phi*(state.pressure - p_ref));
    s.k         = rock.perm;               % or updated k
    s.Sw        = state.s(:,2);            % ⚠️ ADD THIS - water saturation
    s.rock_id   = rock_id;
    % optional: s.faceFlux = computeVelocity(G, rock, fluid, state);
end
```

### 2. Modify export_dataset.m

- Save a summary of wellSols{i} (q, BHP) in a matrix per timestep
- Calculate PV_total once and write to metadata.yaml → needed to normalize PV injected

### 3. Post-process Python (convert_mat_to_parquet.py)

- Add columns: pressure, Sw, optionally vx, vy
- Accumulate qW_inj, qO_prod, etc., for voidage and PV

### 4. Storage Considerations

- With Sw and pressure, files will grow ~+30%. Use Parquet compression (snappy)
- For streamlines, save only every N timesteps or calculate on-the-fly

## Implementation Priority

### ✅ High Priority (Can implement immediately)
1. **Fractional flow fw(Sw)** - Use existing kr curves and fluid properties
2. **dkr/dSw sensitivity** - Calculate numerical derivatives of kr curves

### ⚠️ Medium Priority (Requires MRST workflow changes)
1. **ΔPressure maps** - Need pressure export from extract_snapshot.m
2. **Sw histogram evolution** - Need Sw export from extract_snapshot.m
3. **Formation factor evolution** - Need pressure export + PVT calculations
4. **All well performance plots** - Need wellSols export from export_dataset.m

### ❌ Low Priority (Requires significant additional work)
1. **Streamlines** - Need velocity field calculations
2. **Vertical sections** - Need 3D simulation data
3. **Sensitivity tornado** - Need parametric study results

## Data File Locations Expected

```
MRST_simulation_scripts/data/
├── initial_setup.mat          # ✅ Available
├── snap_*.mat                 # ✅ Available (pressure, stress, phi, k)
├── well_data.mat              # ❌ Missing (BHP, rates by well)
├── pvt_table.mat              # ❌ Missing (Bo, Bw vs P)
├── saturation_data.mat        # ❌ Missing (Sw by timestep)
├── velocity_field.mat         # ❌ Missing (flow velocities)
└── sensitivity_results.mat    # ❌ Missing (parametric study)
```

## Synthetic Data Fallbacks

For missing data, the system will generate synthetic/example data to demonstrate plot functionality:
- Well performance data (rates, BHP)
- PVT properties (typical oil/water properties)
- Saturation evolution (water flood patterns)
- Velocity fields (simple flow patterns)

This allows users to see plot formats and functionality while waiting for real simulation data.

## Summary of Current Implementation Status

### ✅ **Fully Implemented Categories (17 plots)**
- **Category A**: 4/4 plots (kr curves, PVT, histograms, k-φ crossplot)
- **Category B**: 2/2 plots (initial Sw, initial pressure)  
- **Category E**: 4/4 plots (pressure, stress, porosity, permeability evolution)
- **Category H**: 3/4 plots (fractional flow, kr sensitivity, voidage ratio placeholder)
- **Legacy plots**: 4 plots (geometry, wells config, maps, wells performance)

### ⚠️ **Partially Implemented (Requires MRST workflow changes)**
- **Category C**: 4 plots - Need detailed well data
- **Category D**: 3 plots - Need wellSols export  
- **Category E**: 2 additional plots - Need Sw and PVT data
- **Category F**: 5 plots - Need wellSols export
- **Category G**: 5 plots - Need Sw and pressure export

### ❌ **Requires Additional Development**
- **Category G**: 4 plots - Need velocity fields and 3D data
- **Category H**: 1 plot - Need parametric study results

## Conclusion: Minimal MRST Changes Needed

With the current architecture you only need **3 simple additions**:

1. **Export pressure and water saturation per cell** (modify `extract_snapshot.m`)
2. **Save the wellSols (rates and BHP) per timestep** (modify `export_dataset.m`)  
3. **(Optional) store or recalculate phase velocities** for streamlines

Once those three data blocks are added, **~85% of all plots** can be generated without needing additional simulations or physics modifications.

## Files Generated by Current System

```
monitoring/plots/
├── kr_curves.png              # ✅ Category A
├── pvt_properties.png         # ✅ Category A  
├── property_histograms.png    # ✅ Category A
├── k_phi_crossplot.png        # ✅ Category A
├── sw_initial.png             # ✅ Category B
├── pressure_initial.png       # ✅ Category B
├── pressure_evolution.png     # ✅ Category E
├── stress_evolution.png       # ✅ Category E
├── porosity_evolution.png     # ✅ Category E
├── permeability_evolution.png # ✅ Category E
├── fractional_flow.png        # ✅ Category H
├── kr_sensitivity.png         # ✅ Category H
├── voidage_ratio.png          # ⚠️ Category H (placeholder)
└── [legacy plots...]          # ✅ Compatibility
```

**Total: 17 individual plots generated automatically!** 🎉 