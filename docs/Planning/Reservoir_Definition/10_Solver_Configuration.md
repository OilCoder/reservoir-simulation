# Solver Configuration - Eagle West Field MRST Simulation

## Executive Summary

This document defines the numerical solver configuration, timestep control strategy, and simulation execution parameters for the Eagle West Field MRST simulation. The configuration ensures robust convergence, optimal performance, and accurate results for the 10-year, 15-well field development simulation.

### Key Configuration Elements
- **Solver Type**: Fully-implicit black oil solver (ad-fi)
- **Simulation Duration**: 3,650 days (10 years)
- **Timestep Strategy**: Adaptive control with growth/cut factors
- **Convergence Criteria**: CNV tolerance 1.0e-6, MB tolerance 1.0e-7
- **Quality Control**: Automated material balance and physical range checks

---

## 1. Solver Settings

### 1.1 Core Solver Configuration

| Parameter | Value | Description |
|-----------|-------|-------------|
| **Solver Type** | ad-fi | Fully-implicit black oil solver |
| **Max Iterations** | 25 | Maximum Newton iterations per timestep |
| **Convergence Tolerance (CNV)** | 1.0e-6 | Convergence tolerance for saturations and pressure |
| **Material Balance Tolerance** | 1.0e-7 | Mass conservation tolerance |
| **Line Search** | Enabled | Backtracking line search for stability |
| **CPR Preconditioning** | Enabled | Constrained Pressure Residual preconditioning |

### 1.2 Newton Method Configuration

**Convergence Criteria:**
$$\max\left(\frac{|R_i|}{|R_i^0|}\right) < \epsilon_{CNV} \text{ and } \sum_{i=1}^{N_{cells}} |R_i| < \epsilon_{MB}$$

Where:
- $R_i$ = Residual for cell i
- $R_i^0$ = Initial residual
- $\epsilon_{CNV}$ = 1.0e-6 (CNV tolerance)
- $\epsilon_{MB}$ = 1.0e-7 (Material balance tolerance)

---

## 2. Timestep Control

### 2.1 Timestep Parameters

| Parameter | Value | Units | Description |
|-----------|-------|-------|-------------|
| **Initial Timestep** | 1 | days | Starting timestep size |
| **Minimum Timestep** | 0.1 | days | Minimum allowed timestep |
| **Maximum Timestep** | 365 | days | Maximum allowed timestep |
| **Growth Factor** | 1.25 | - | Timestep increase multiplier |
| **Cut Factor** | 0.5 | - | Timestep reduction multiplier |
| **Max Cuts** | 8 | - | Maximum timestep cuts before failure |
| **Adaptive Control** | Enabled | - | Dynamic timestep adjustment |

### 2.2 Adaptive Timestep Algorithm

```
IF (iterations < target_iterations - 2):
    Δt_new = Δt * growth_factor
ELIF (iterations > target_iterations + 2):
    Δt_new = Δt * cut_factor
ELSE:
    Δt_new = Δt (unchanged)
    
Δt_new = MAX(min_timestep, MIN(max_timestep, Δt_new))
```

Target iterations: 8 Newton iterations per timestep

---

## 3. Simulation Schedule

### 3.1 Overall Timeline

- **Total Duration**: 3,650 days (10 years)
- **Start Date**: Day 0
- **End Date**: Day 3,650

### 3.2 History Period (Years 1-3)

| Parameter | Value | Description |
|-----------|-------|-------------|
| **Duration** | 1,095 days | First 3 years |
| **Timestep Size** | 30 days | Monthly timesteps |
| **Total Steps** | ~37 | Number of timesteps |
| **Purpose** | Detailed history matching | High-resolution early production |

**Rationale**: Monthly timesteps capture early production dynamics, pressure transients, and initial water breakthrough.

### 3.3 Forecast Period (Years 4-10)

#### Years 4-7 (Medium-Term Forecast)
| Parameter | Value | Description |
|-----------|-------|-------------|
| **Duration** | 1,460 days | Years 4-7 |
| **Timestep Size** | 90 days | Quarterly timesteps |
| **Total Steps** | ~16 | Number of timesteps |
| **Purpose** | Production forecast | Medium-resolution forecast |

#### Years 8-10 (Long-Term Forecast)
| Parameter | Value | Description |
|-----------|-------|-------------|
| **Duration** | 1,095 days | Years 8-10 |
| **Timestep Size** | 180 days | Semi-annual timesteps |
| **Total Steps** | ~6 | Number of timesteps |
| **Purpose** | Long-term behavior | Coarse resolution for trends |

---

## 4. Progress Monitoring

### 4.1 Checkpoint Configuration

| Parameter | Value | Description |
|-----------|-------|-------------|
| **Checkpoint Frequency** | 50 steps | Save full state every 50 timesteps |
| **Progress Report Frequency** | 10 steps | Console output every 10 timesteps |
| **Save Intermediate Results** | Enabled | Store states for restart capability |
| **Convergence Tracking** | Enabled | Monitor iteration counts and residuals |

### 4.2 Monitoring Metrics

**Per-Timestep Tracking:**
- Newton iteration count
- Linear solver iterations
- Maximum residual values
- Material balance error
- CPU time per timestep
- Timestep size history

**Cumulative Tracking:**
- Total Newton iterations
- Average iterations per timestep
- Timestep success rate
- Total CPU time
- Memory usage peaks

---

## 5. Quality Control

### 5.1 Material Balance Checks

| Check | Tolerance | Action on Failure |
|-------|-----------|-------------------|
| **Volume Balance** | 1% | Warning + timestep reduction |
| **Mass Conservation** | 0.01% | Error + timestep retry |
| **Phase Sum** | 1.0e-6 | Correction + warning |

### 5.2 Physical Range Validation

#### Pressure Limits
- **Minimum**: 1.0e6 Pa (145 psi)
- **Maximum**: 5.0e7 Pa (7,250 psi)
- **Action**: Clip and warn if exceeded

#### Saturation Limits
- **Oil**: [0.0, 1.0]
- **Water**: [0.0, 1.0] 
- **Gas**: [0.0, 1.0]
- **Sum Check**: Sw + So + Sg = 1.0 ± 1.0e-6

### 5.3 Grid Quality Metrics

| Metric | Threshold | Description |
|--------|-----------|-------------|
| **Max Aspect Ratio** | 10.0 | Cell dimension ratio limit |
| **Min Cell Volume** | 1.0 m³ | Minimum allowed cell size |
| **Max Cell Volume** | 100,000 m³ | Maximum allowed cell size |
| **Orthogonality** | 0.1 rad | Maximum deviation from orthogonal |

### 5.4 Well Performance Validation

**Producer Wells:**
- Rate within ±5% of target (if rate-controlled)
- BHP above minimum limit
- Water cut < 95%
- GOR < 3,000 scf/STB

**Injector Wells:**
- Rate within ±5% of target (if rate-controlled)
- BHP below maximum limit
- Injection efficiency > 80%

---

## 6. Output Control

### 6.1 Output Configuration

| Parameter | Setting | Description |
|-----------|---------|-------------|
| **Save States** | Enabled | Store complete reservoir states |
| **Save Well Solutions** | Enabled | Detailed well performance data |
| **Save Reports** | Enabled | Summary reports and diagnostics |
| **Export Diagnostics** | Enabled | Convergence and performance metrics |
| **Create Plots** | Disabled | Disable automatic plotting for performance |

### 6.2 Output Files

**State Files:**
- Format: HDF5 or MAT files
- Content: Pressure, saturations, fluxes
- Frequency: Every checkpoint (50 steps)

**Well Files:**
- Format: CSV or structured arrays
- Content: Rates, pressures, water cut, GOR
- Frequency: Every timestep

**Report Files:**
- Format: Text or JSON
- Content: Material balance, convergence stats
- Frequency: End of simulation + checkpoints

---

## 7. Performance Optimization

### 7.1 Memory Management

- **State Storage**: Keep only necessary timesteps in memory
- **Checkpoint Strategy**: Write to disk at regular intervals
- **Matrix Storage**: Use sparse formats for Jacobian
- **Clear Temporary**: Release intermediate variables

### 7.2 Computational Efficiency

**Linear Solver Optimization:**
- Use CPR preconditioning for pressure system
- Reuse preconditioners when possible
- Adjust tolerances based on Newton iteration

**Parallel Processing:**
- Matrix assembly parallelization
- Well equation parallel evaluation
- Property calculation vectorization

### 7.3 Convergence Enhancement

**Strategies:**
1. **Relaxation**: Apply factor 0.8 for difficult timesteps
2. **Chopping**: Reduce timestep on convergence failure
3. **Ramping**: Gradual increase in rates/pressures
4. **Switching**: Change well controls if needed

---

## 8. Error Handling

### 8.1 Convergence Failures

**Response Strategy:**
```
1. IF (iterations > max_iterations):
   - Cut timestep by factor 0.5
   - Retry from previous state
   
2. IF (cuts > max_cuts):
   - Report detailed diagnostics
   - Identify problematic cells/wells
   - Consider control switching
   
3. IF (persistent failure):
   - Save debug information
   - Halt simulation gracefully
```

### 8.2 Numerical Issues

| Issue | Detection | Response |
|-------|-----------|----------|
| **Negative Saturations** | S < -1.0e-6 | Clip to 0, warn |
| **Pressure Oscillations** | ΔP > 500 psi/step | Reduce timestep |
| **Material Balance Error** | > 1% | Reduce tolerance, retry |
| **Ill-conditioned Matrix** | Condition > 1.0e12 | Rescale, use better preconditioner |

---

## 9. Restart Capability

### 9.1 Checkpoint System

- **Frequency**: Every 50 timesteps
- **Content**: Complete state + well history
- **Format**: Binary with metadata
- **Retention**: Keep last 5 checkpoints

### 9.2 Restart Procedure

```matlab
% Load checkpoint
checkpoint = load('checkpoint_step_250.mat');
state = checkpoint.state;
schedule = checkpoint.schedule;
step_number = checkpoint.step_number;

% Resume simulation
[wellSols, states] = simulateScheduleAD(state, model, ...
    schedule((step_number+1):end), ...
    'restartStep', step_number);
```

---

## 10. MRST Implementation

### 10.1 Solver Setup Code

```matlab
% Configure solver
solver = NonLinearSolver();
solver.maxIterations = 25;
solver.tolerance = 1e-6;
solver.LineSearchType = 'basic';
solver.useRelaxation = true;
solver.relaxationParameter = 0.8;

% Configure timestep control
timestep = simpleTimeStepSelector();
timestep.minTimeStep = 0.1*day;
timestep.maxTimeStep = 365*day;
timestep.growthFactor = 1.25;
timestep.cutFactor = 0.5;
timestep.targetIterationCount = 8;

% Configure model
model = GenericBlackOilModel(G, rock, fluid, ...
    'water', true, 'oil', true, 'gas', true);
model.toleranceCNV = 1e-6;
model.toleranceMB = 1e-7;
```

### 10.2 Quality Control Implementation

```matlab
% Quality control function
function checkSimulationQuality(state, model, report)
    % Material balance check
    mb_error = checkMaterialBalance(state, model);
    assert(mb_error < 0.01, 'Material balance error: %.2f%%', mb_error*100);
    
    % Physical range check
    assert(all(state.pressure > 1e6), 'Pressure below minimum');
    assert(all(state.pressure < 5e7), 'Pressure above maximum');
    assert(all(state.s(:) >= -1e-6), 'Negative saturations detected');
    assert(all(abs(sum(state.s, 2) - 1) < 1e-6), 'Saturation sum error');
    
    % Convergence check
    avg_iterations = mean(report.Iterations);
    fprintf('Average iterations: %.1f\n', avg_iterations);
    if avg_iterations > 15
        warning('Poor convergence: consider timestep reduction');
    end
end
```

---

## 11. Validation & Benchmarking

### 11.1 Performance Targets

| Metric | Target | Acceptable Range |
|--------|--------|------------------|
| **Simulation Runtime** | 4 hours | 2-6 hours |
| **Average Iterations** | 8 | 6-10 |
| **Timestep Success Rate** | 95% | > 90% |
| **Material Balance Error** | < 0.01% | < 0.1% |
| **Memory Usage** | 8 GB | < 16 GB |

### 11.2 Validation Tests

1. **Single-Phase Flow**: Verify against analytical solutions
2. **Material Balance**: Check volume conservation
3. **Well Models**: Compare with Peaceman equations
4. **Restart Consistency**: Ensure identical results

---

## Technical References

1. **MRST Documentation**: "Automatic Differentiation Framework", SINTEF (2023)
2. **SPE Papers**: 
   - SPE-118993: "Fully Implicit Simulation"
   - SPE-163593: "CPR Preconditioning Methods"
3. **Convergence Criteria**: Aziz & Settari, "Petroleum Reservoir Simulation" (1979)
4. **Timestep Selection**: Coats, K.H., "Implicit Compositional Simulation" (1980)

---

## Document Control

- **Created**: 2025-08-12
- **Version**: 1.0
- **Purpose**: Complete solver configuration documentation
- **Source**: solver_config.yaml
- **Status**: Production Ready

---

_This document provides complete solver configuration specifications for the Eagle West Field MRST simulation, ensuring robust numerical performance and accurate results throughout the 10-year simulation period._