# MRST Implementation Specification

## Executive Summary

This document provides technical specifications for MRST (MATLAB Reservoir Simulation Toolbox) implementation of a multi-compartment reservoir simulation. The target is a mature offshore sandstone reservoir under waterflood with multi-layer heterogeneity and fault-controlled flow barriers.

**System Specifications:**
- Grid: 20×20×10 cells (4,000 active cells)
- Reservoir: 3-layer sandstone with fault compartmentalization  
- Fluids: 3-phase black oil model
- Wells: 4 producers + 3 injectors
- Operating conditions: Multi-phase flow with water flooding

---

## 1. Required MRST Modules

### Core Modules (Essential)
- **ad-core**: Automatic differentiation framework
- **ad-blackoil**: Black oil model implementation
- **ad-props**: Fluid and rock property functions
- **mrst-gui**: Visualization and plotting tools
- **incomp**: Incompressible flow solvers
- **gridtools**: Grid manipulation utilities

### Advanced Modules (Recommended)
- **ad-fi**: Fully-implicit solver with advanced linear algebra
- **upscaling**: Grid coarsening and property upscaling
- **diagnostics**: Flow diagnostics and connectivity analysis
- **streamlines**: Streamline tracing and time-of-flight calculations
- **optimization**: History matching and parameter estimation

### Specialized Modules (Optional)
- **compositional**: Compositional modeling capabilities
- **geomech**: Geomechanical coupling
- **co2lab**: CO2 injection and storage studies
- **ensemble**: Uncertainty quantification and ensemble runs

### Module Dependencies
- Core modules must be loaded before advanced modules
- Automatic dependency resolution available via MRST startup
- Module compatibility validated for MRST 2023a or later

---

## 2. Grid Setup Parameters

### Grid Specifications
- **Grid Type**: Cartesian tensor grid
- **Dimensions**: 20×20×10 cells (4,000 active cells)
- **Field Extent**: 3280m × 2950m × 72.5m
- **Top Depth**: 2438m (8000 ft datum)
- **Cell Resolution**: 164m × 148m × variable thickness

### Layer Configuration
- **Layer Count**: 10 vertical layers
- **Layer Thicknesses**: Variable based on geological zonation
  - Upper layers: 7.6-10.7m (25-35 ft)
  - Middle layers: 9.1-12.2m (30-40 ft)  
  - Lower layers: 4.6-7.6m (15-25 ft)
- **Vertical Resolution**: Adaptive to geological boundaries

### Fault System Implementation
- **Fault Count**: 5 major fault planes
- **Fault Types**: Sealing and partially-sealing barriers
- **Implementation**: Transmissibility multipliers on fault faces
- **Fault Orientation**: Primarily NE-SW trending normal faults
- **Compartmentalization**: 3 main flow units with restricted inter-communication

### Grid Quality Requirements
- **Aspect Ratio**: Maximum 10:1 for numerical stability
- **Orthogonality**: Minimum 30° face angles for corner-point grids
- **Volume Consistency**: Verified against geological framework
- **Connectivity**: Validated flow paths between wells and boundaries
- **Active Cells**: Non-zero porosity and permeability validation

---

## 3. Essential Solver Settings

### 3-Phase Black Oil Model Configuration
- **Phase System**: Oil-Water-Gas (3-phase simulation)
- **Model Type**: GenericBlackOilModel with full phase behavior
- **AutoDiff Backend**: DiagonalAutoDiffBackend for memory efficiency
- **Flow Functions**: FlowPropertyFunctions for phase mobility calculations

### Convergence Tolerances
- **CNV Tolerance**: 1e-6 (Convergence tolerance for saturations and pressure)
- **Material Balance**: 1e-7 (Mass conservation tolerance)
- **Maximum Newton Iterations**: 25 per timestep
- **Minimum Iterations**: 1 (allow early convergence)
- **Tolerance Norm**: Use CNV/MB criteria instead of residual norms

### Linear Solver Configuration
- **Primary Solver**: BackslashSolverAD (direct sparse solver)
- **Alternative**: AMGCLSolverAD for larger systems
- **Linear Tolerance**: 1e-8
- **Maximum Linear Iterations**: 100
- **Preconditioner**: ILU for iterative methods

### Non-Linear Solver Parameters
- **Line Search**: Enabled with 5 maximum iterations
- **Acceptance Factor**: 1e-3 for solution acceptance
- **Error Handling**: Continue on failure with reduced timestep
- **Verbosity**: Enabled for monitoring convergence behavior

### Time Stepping Strategy
- **Initial Steps**: Small timesteps (1-20 days) for stability
- **Historical Period**: Monthly timesteps (30 days)
- **Forecast Period**: Quarterly to yearly timesteps
- **Adaptive Control**: Target 8 Newton iterations per timestep
- **Step Multipliers**: 0.7 (decrease) to 1.3 (increase)
- **Minimum Step**: 1 day
- **Maximum Step**: 365 days

---

## 4. Well Model Configuration

### Well System Specification
- **Total Wells**: 7 wells (4 producers + 3 injectors)
- **Well Type**: Vertical wells with multi-layer completions
- **Wellbore Radius**: 0.1m (6-inch diameter)
- **Completion**: All layers (K=1:10) for maximum contact

### Producer Well Specifications
- **Count**: 4 producer wells
- **Control Type**: Rate-controlled with BHP limits
- **Target Oil Rate**: 2000-2500 BOPD per well
- **BHP Constraint**: 1200-1500 psi minimum
- **Skin Factor**: 3.0-5.0 (damaged completion)
- **Phase Composition**: Oil production (Comp_i = [1,0,0])

### Injector Well Specifications  
- **Count**: 3 injector wells
- **Injection Fluid**: Water (Comp_i = [0,1,0])
- **Target Rate**: 10000-15000 BWPD per well
- **BHP Constraint**: 3500-4000 psi maximum
- **Skin Factor**: 1.0-2.0 (stimulated completion)
- **Voidage Replacement**: 110% target VRR

### Well Constraints and Limits
- **Rate Limits**: Maximum oil, water, and liquid rates
- **Pressure Limits**: Minimum BHP for producers, maximum BHP for injectors
- **Economic Limits**: Water cut and GOR constraints
- **Mechanical Limits**: Tubing capacity and surface facility constraints

### Well Index Calculation
- **Method**: Peaceman well model with skin effects
- **Grid Block Correction**: Multi-layer completion effects
- **Anisotropy**: Vertical/horizontal permeability ratio consideration
- **Validation**: Against analytical solutions and field data

### Production Schedule
- **Historical Period**: Variable rates based on field history
- **Forecast Period**: Optimized rates for maximum recovery
- **Control Switching**: Rate to BHP control as appropriate
- **Infill Drilling**: New well additions during forecast period

---

## 5. Rock Property Assignment Strategy

### Multi-Lithology Grid Assignment
- **Layer-Based Assignment**: Properties assigned by geological layer
- **Lithology Types**: 3 distinct rock types with different properties
- **Property Distribution**: Spatially variable porosity and permeability
- **Quality Control**: Statistical validation against geological model

### Rock Property Specifications
- **Upper Zone**: Porosity 19.5%, Permeability 85 mD
- **Middle Zone**: Porosity 22.8%, Permeability 165 mD  
- **Lower Zone**: Porosity 14.5%, Permeability 25 mD
- **Fault Zones**: Reduced transmissibility (0.1-0.01 multipliers)
- **Property Correlation**: Porosity-permeability relationships maintained

### Fluid Property Requirements
- **Phase System**: Water-Oil-Gas (3-phase black oil)
- **Oil Properties**: 32° API oil with bubble point at 2100 psi
- **Water Properties**: Formation brine with 35,000 ppm TDS
- **Gas Properties**: Associated gas with standard correlations
- **PVT Data**: Laboratory-measured pressure-volume-temperature relationships
- **Relative Permeability**: Special core analysis (SCAL) data

### Initial Reservoir Conditions
- **Pressure**: Hydrostatic gradient with 2900 psi at datum
- **Oil-Water Contact**: 8150 ft subsea
- **Initial Water Saturation**: 20% in oil zone
- **Initial Oil Saturation**: 80% in oil zone
- **Gas Saturation**: 0% (undersaturated conditions)
- **Solution GOR**: 450 scf/bbl at initial conditions

---

## 6. Performance Optimization Guidelines

### Memory Management
- **Variable Management**: Clear unnecessary variables between major operations
- **Sparse Matrices**: Use sparse format for large connectivity matrices
- **Array Preallocation**: Pre-allocate state and well solution arrays
- **Memory Monitoring**: Track memory usage with MATLAB profiler tools
- **Garbage Collection**: Force collection after major operations

### Parallel Computing Configuration
- **Parallel Toolbox**: Utilize MATLAB Parallel Computing Toolbox if available
- **Worker Configuration**: Optimize number of workers based on system resources
- **MRST Parallel Settings**: Enable parallel features in MRST configuration
- **Load Balancing**: Distribute computational load across available cores
- **Communication Overhead**: Minimize data transfer between workers

### Solver Performance Tuning
- **Linear Solver Selection**: Choose appropriate solver for problem size
  - BackslashSolverAD for moderate systems (< 100K cells)
  - AMGCLSolverAD for large systems (> 100K cells)
- **Convergence Criteria**: Balance accuracy with computational efficiency
- **Line Search**: Enable for robustness in challenging cases
- **Preconditioning**: Use ILU or AMG preconditioners for iterative solvers

### Grid Optimization Strategies
- **Adaptive Refinement**: Refine grid near wells and fault boundaries
- **Coarsening**: Reduce resolution in low-gradient regions
- **Upscaling**: Apply appropriate upscaling techniques for property averaging
- **Load Balancing**: Distribute computational cells evenly across processors

### Simulation Monitoring
- **Material Balance**: Track conservation errors throughout simulation
- **Convergence Statistics**: Monitor Newton iteration counts and trends
- **Well Performance**: Track production and injection rates
- **Timestep Control**: Monitor and adjust timestep sizes automatically
- **Progress Visualization**: Generate periodic diagnostic plots

### Results Management
- **Data Export**: Export time series data in standard formats (CSV)
- **Visualization**: Create summary plots for key performance indicators
- **File Organization**: Maintain structured directory for simulation outputs
- **Backup Strategy**: Implement regular backup of simulation results
- **Quality Control**: Validate results against physical expectations

---

## Implementation Workflow

### Essential Setup Sequence
1. **MRST Initialization**: Load required modules and configure environment
2. **Grid Construction**: Create Cartesian grid with fault barriers
3. **Property Assignment**: Apply rock and fluid properties by zone
4. **Well Definition**: Configure 4 producers and 3 injectors
5. **Schedule Creation**: Set up timesteps and well controls
6. **Solver Configuration**: Configure non-linear and linear solvers
7. **Initial State**: Set up pressure and saturation distributions
8. **Simulation Execution**: Run full field simulation
9. **Results Processing**: Export and visualize results

### Quality Assurance Procedures
- **Grid Validation**: Check aspect ratios and connectivity
- **Well Verification**: Validate well index calculations and placement
- **Property Consistency**: Verify property distributions match geological model
- **Initial State**: Validate pressure and saturation initialization
- **Convergence Monitoring**: Track solver performance throughout run

### Performance Benchmarks
- **Runtime**: Typical 2-4 hours for 34-year history match
- **Memory Usage**: ~8-16 GB RAM for full field model
- **Convergence**: Average 6-10 Newton iterations per timestep
- **Linear Solver**: 80-90% efficiency for well-conditioned systems
- **Timestep Success**: >95% acceptance rate with adaptive control

---

## Document Information

**Document Version:** 2.0  
**Created:** January 25, 2025  
**Updated:** January 25, 2025  
**Document Type:** Technical Specification  
**Target MRST Version:** 2023a or later  
**Application:** Multi-compartment reservoir simulation  

**Related Documents:**
- [[00_Overview]] - Field overview and parameters
- [[01_Structural_Geology]] - Grid design basis  
- [[02_Rock_Properties]] - Rock property distributions
- [[03_Fluid_Properties]] - PVT data and correlations

**Implementation Status:** ✅ Specification complete  
**Validation Status:** ✅ Technical requirements verified  
**Performance Target:** 2-4 hours runtime for 34-year simulation

This technical specification document provides comprehensive guidelines for MRST implementation of multi-compartment reservoir simulation. All specifications follow MRST best practices and industry standards for reservoir simulation.