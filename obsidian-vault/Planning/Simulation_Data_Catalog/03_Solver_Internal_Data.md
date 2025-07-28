# Solver Internal Data

## Overview

Solver internal data provides detailed insights into the numerical performance and convergence behavior of reservoir simulators. This data is crucial for understanding simulation quality, diagnosing numerical issues, and developing machine learning models for solver optimization and convergence prediction.

## Data Categories

### 1. Newton Iteration Data

#### Description
Data capturing the nonlinear Newton-Raphson iteration process for each timestep.

#### Content
- **Residual norms**: L2, L∞ norms for each equation type (mass balance, energy, etc.)
- **Convergence rates**: Rate of residual reduction between iterations
- **Iteration counts**: Number of Newton iterations per timestep
- **Convergence flags**: Success/failure status for each iteration

#### When Generated
- Every Newton iteration within each timestep
- Typically 3-15 iterations per timestep for well-conditioned problems
- More iterations for challenging problems (phase transitions, near-critical conditions)

#### Storage Considerations

**Pros of Storing:**
- Essential for debugging convergence issues
- Enables ML models for predicting convergence behavior
- Helps identify problematic grid cells or time periods
- Valuable for adaptive solver parameter tuning

**Cons of Storing:**
- High frequency data (potentially 10⁶-10⁷ data points per simulation)
- Large storage requirements for long simulations
- May contain redundant information for well-converged cases

**Recommendation**: Store with configurable frequency (e.g., every 10th timestep for routine cases, all data for critical studies)

#### Use Cases
- **Debugging**: Identify non-converging timesteps and root causes
- **ML Applications**: Train models to predict convergence difficulty
- **Solver Tuning**: Optimize Newton parameters for specific reservoir types
- **Quality Assurance**: Monitor simulation health in real-time

#### Storage Format
```json
{
  "timestep": 145,
  "time_days": 365.25,
  "newton_iterations": [
    {
      "iteration": 1,
      "residuals": {
        "oil_mass": 1.23e-3,
        "water_mass": 2.45e-4,
        "gas_mass": 5.67e-5,
        "pressure": 8.90e-2
      },
      "residual_norms": {
        "l2": 1.45e-3,
        "linf": 2.34e-2
      },
      "convergence_rate": 0.45,
      "wall_time_seconds": 0.123
    }
  ],
  "converged": true,
  "total_iterations": 4
}
```

#### Metadata Requirements
- Simulator version and settings
- Convergence tolerances used
- Grid size and complexity metrics
- Reservoir fluid properties (PVT complexity indicators)

### 2. Linear Solver Statistics

#### Description
Performance metrics from the linear system solution within each Newton iteration.

#### Content
- **Condition numbers**: Matrix conditioning indicators
- **Solver time**: CPU/wall time for linear solve
- **Iteration counts**: For iterative solvers (GMRES, BiCGSTAB)
- **Memory usage**: Peak memory during linear solve
- **Preconditioner effectiveness**: Reduction in condition number

#### When Generated
- Every linear solve within each Newton iteration
- Frequency: (Newton iterations) × (timesteps)

#### Storage Considerations

**Pros of Storing:**
- Critical for linear solver optimization
- Helps identify memory bottlenecks
- Enables hardware-specific performance tuning
- Useful for parallel efficiency analysis

**Cons of Storing:**
- Very high frequency data
- Platform-dependent metrics may not transfer
- Large storage overhead for minor performance gains

**Recommendation**: Store summary statistics per timestep, detailed data for problematic cases only

#### Use Cases
- **Performance Optimization**: Identify optimal linear solver settings
- **Hardware Scaling**: Understand parallel solver efficiency
- **Preconditioner Tuning**: Optimize preconditioning strategies
- **Memory Management**: Predict and manage memory requirements

#### Storage Format
```json
{
  "timestep": 145,
  "newton_iteration": 2,
  "linear_solver": {
    "type": "GMRES",
    "condition_number": 1.23e6,
    "iterations": 45,
    "residual_reduction": 1.23e-8,
    "wall_time_seconds": 2.34,
    "memory_mb": 1024,
    "preconditioner": "ILU(2)"
  }
}
```

#### Metadata Requirements
- Hardware specifications (CPU, memory, architecture)
- Compiler and optimization flags
- Linear solver parameters and settings
- Matrix characteristics (size, sparsity pattern)

### 3. Jacobian Matrix Properties

#### Description
Characteristics of the Newton-Raphson Jacobian matrix, if computed and stored.

#### Content
- **Matrix dimensions**: Size and sparsity
- **Condition number**: Numerical stability indicator
- **Eigenvalue spectrum**: For stability analysis
- **Sparsity pattern**: Structure and fill-in characteristics
- **Assembly time**: Time to construct the matrix

#### When Generated
- Once per Newton iteration (if stored)
- Typically computed but not retained due to storage requirements

#### Storage Considerations

**Pros of Storing:**
- Enables advanced numerical analysis
- Critical for developing adaptive algorithms
- Valuable for understanding problem characteristics
- Essential for some ML applications

**Cons of Storing:**
- Extremely large storage requirements (matrices can be GB-sized)
- Computationally expensive to analyze
- May contain sensitive information about reservoir structure

**Recommendation**: Store matrix properties (not full matrices) for selected timesteps only

#### Use Cases
- **Numerical Analysis**: Understand system conditioning
- **Algorithm Development**: Design better preconditioning strategies
- **ML Training**: Features for convergence prediction models
- **Research**: Fundamental understanding of reservoir simulation numerics

#### Storage Format
```json
{
  "timestep": 145,
  "newton_iteration": 2,
  "jacobian_properties": {
    "dimensions": [125000, 125000],
    "nnz": 4500000,
    "condition_number": 1.23e8,
    "assembly_time_seconds": 5.67,
    "sparsity_ratio": 0.00036,
    "eigenvalue_bounds": {
      "min": 1.23e-12,
      "max": 4.56e4
    }
  }
}
```

#### Metadata Requirements
- Grid discretization details
- Physical equations included
- Boundary condition types
- Well model complexity

### 4. Timestep Control Data

#### Description
Information about adaptive timestep control decisions and timestep modifications.

#### Content
- **Timestep changes**: dt increases, decreases, and reasons
- **Chopping events**: When and why timesteps were reduced
- **Stability indicators**: CFL numbers, material balance errors
- **Control mechanisms**: Which criteria triggered timestep changes

#### When Generated
- Every timestep where dt changes occur
- At user-specified monitoring intervals
- During critical simulation periods (well events, phase transitions)

#### Storage Considerations

**Pros of Storing:**
- Essential for understanding simulation stability
- Helps optimize timestep control parameters
- Critical for reproducing simulation behavior
- Valuable for ML-based timestep prediction

**Cons of Storing:**
- Moderate storage requirements
- May contain redundant information for stable simulations
- Analysis complexity for long-term trends

**Recommendation**: Always store - relatively small data with high value

#### Use Cases
- **Simulation Optimization**: Improve timestep control algorithms
- **Quality Control**: Monitor simulation stability
- **ML Applications**: Predict optimal timestep sequences
- **Post-processing**: Understand simulation behavior patterns

#### Storage Format
```json
{
  "timestep": 145,
  "time_days": 365.25,
  "timestep_control": {
    "dt_current": 1.0,
    "dt_previous": 2.0,
    "dt_next": 1.5,
    "change_reason": "convergence_difficulty",
    "chopping_event": false,
    "cfl_number": 0.45,
    "material_balance_error": 1.23e-6,
    "control_active": ["newton_iterations", "cfl_limit"]
  }
}
```

#### Metadata Requirements
- Timestep control parameters and limits
- Simulation control settings
- Physical phenomena active (thermal, compositional, etc.)
- Well event schedule

### 5. Phase Appearance/Disappearance Events

#### Description
Records of phase transitions in grid cells during simulation, particularly important for compositional and thermal simulations.

#### Content
- **Phase changes**: Gas/oil/water appearance or disappearance
- **Cell locations**: Grid coordinates where changes occur
- **Trigger conditions**: Pressure, temperature, composition at transition
- **Recovery actions**: How the simulator handled the transition

#### When Generated
- Whenever phase transitions occur in any grid cell
- Typically during pressure depletion, gas injection, or thermal processes
- More frequent in compositional simulations near critical points

#### Storage Considerations

**Pros of Storing:**
- Critical for understanding reservoir behavior
- Essential for validating phase behavior models
- Helps identify numerical artifacts vs. physical transitions
- Valuable for optimizing phase detection algorithms

**Cons of Storing:**
- Highly variable frequency (zero to thousands per timestep)
- Can create large datasets for complex reservoirs
- May require specialized analysis tools

**Recommendation**: Always store - critical diagnostic information with manageable size

#### Use Cases
- **Reservoir Engineering**: Understand phase behavior evolution
- **Model Validation**: Verify EOS and phase behavior models
- **Numerical Diagnostics**: Distinguish physical vs. numerical transitions
- **Process Optimization**: Optimize gas injection or thermal recovery

#### Storage Format
```json
{
  "timestep": 145,
  "time_days": 365.25,
  "phase_events": [
    {
      "cell_id": [15, 23, 8],
      "event_type": "gas_appearance",
      "conditions": {
        "pressure_psia": 2345.6,
        "temperature_f": 180.5,
        "composition": {
          "c1": 0.45,
          "c7+": 0.23
        }
      },
      "previous_phases": ["oil", "water"],
      "new_phases": ["oil", "water", "gas"],
      "trigger": "pressure_depletion"
    }
  ]
}
```

#### Metadata Requirements
- EOS model and tuning parameters
- Critical properties of components
- Phase behavior test data
- Reservoir fluid composition

### 6. Numerical Issues Log

#### Description
Record of numerical problems encountered during simulation, including violations of physical constraints and recovery actions.

#### Content
- **Negative saturations**: Values, locations, and corrections applied
- **Non-physical states**: Pressure/temperature outside valid ranges
- **Mass balance violations**: Magnitude and affected components
- **Recovery actions**: How the simulator corrected each issue

#### When Generated
- Whenever numerical violations are detected
- During post-timestep validation checks
- When automatic correction algorithms are triggered

#### Storage Considerations

**Pros of Storing:**
- Essential for simulation quality assessment
- Helps identify problematic reservoir regions
- Critical for debugging and model improvement
- Valuable for developing robust numerical methods

**Cons of Storing:**
- Can generate large amounts of data for challenging reservoirs
- May indicate more serious model problems requiring investigation
- Requires careful interpretation to avoid false alarms

**Recommendation**: Always store - critical for simulation reliability

#### Use Cases
- **Quality Assurance**: Monitor simulation physical consistency
- **Model Debugging**: Identify reservoir model issues
- **Method Development**: Improve numerical robustness
- **Risk Assessment**: Understand simulation uncertainty

#### Storage Format
```json
{
  "timestep": 145,
  "time_days": 365.25,
  "numerical_issues": [
    {
      "issue_type": "negative_saturation",
      "severity": "warning",
      "cell_id": [12, 18, 5],
      "details": {
        "phase": "water",
        "value": -0.001234,
        "correction": "clamp_to_zero",
        "mass_balance_error": 1.23e-8
      },
      "recovery_successful": true,
      "wall_time_seconds": 0.001
    }
  ]
}
```

#### Metadata Requirements
- Numerical method settings and tolerances
- Physical constraint definitions
- Correction algorithm parameters
- Grid quality metrics

## Implementation Guidelines

### Storage Strategy
1. **Hierarchical Storage**: High-frequency data on fast storage, summaries on archive storage
2. **Compression**: Use appropriate compression for time-series data
3. **Indexing**: Efficient querying by timestep, cell location, or issue type
4. **Metadata**: Rich metadata for reproducibility and interpretation

### Data Quality
1. **Validation**: Implement checks for data consistency and completeness
2. **Documentation**: Clear definitions of all metrics and units
3. **Versioning**: Track changes in data format and content
4. **Provenance**: Link data to specific simulator runs and configurations

### Access Patterns
1. **Real-time Monitoring**: Support live dashboard displays during simulation
2. **Post-processing**: Efficient bulk data access for analysis
3. **ML Training**: Optimized data formats for machine learning workflows
4. **Long-term Archive**: Compressed storage for historical analysis

## Integration with ML Workflows

### Feature Engineering
- Derive stability indicators from Newton iteration patterns
- Create convergence difficulty scores from historical data
- Generate grid-based features from spatial numerical issues

### Model Applications
- Convergence prediction models for adaptive solver tuning
- Timestep optimization using reinforcement learning
- Numerical issue prediction for proactive problem avoidance
- Performance optimization models for hardware-specific tuning

### Data Preparation
- Standardized feature extraction pipelines
- Automated data quality checks and cleaning
- Integration with experimental design frameworks
- Support for online learning and model updating