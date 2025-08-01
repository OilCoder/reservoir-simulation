# MRST Implementation Specification

## Executive Summary

This document defines technical specifications and requirements for MRST (MATLAB Reservoir Simulation Toolbox) implementation of a multi-compartment reservoir simulation. It serves as a comprehensive technical guide for developers implementing the simulation system for a mature offshore sandstone reservoir under waterflood conditions.

**Technical Specifications:**
- **Grid Architecture**: 20×20×10 Cartesian tensor grid (4,000 active cells)
- **Reservoir Model**: 3-layer heterogeneous sandstone with fault compartmentalization  
- **Fluid System**: 3-phase black oil model with PVT correlations
- **Well Network**: 10 producers + 5 injectors with multi-layer completions [CORRECTED]
- **Flow Physics**: Multi-phase Darcy flow with capillary and gravitational effects
- **Numerical Methods**: Fully-implicit finite volume with automatic differentiation

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
- **Mass Conservation Equations**: For each phase $\alpha \in \{o,w,g\}$:
  $$\frac{\partial}{\partial t}\left(\phi \rho_\alpha S_\alpha\right) + \nabla \cdot \left(\rho_\alpha \mathbf{v}_\alpha\right) = q_\alpha$$
  where $\phi$ is porosity, $\rho_\alpha$ is phase density, $S_\alpha$ is saturation, $\mathbf{v}_\alpha$ is velocity, and $q_\alpha$ is source/sink term
- **Darcy Flow**: $\mathbf{v}_\alpha = -\frac{k k_{r\alpha}}{\mu_\alpha}\left(\nabla p_\alpha - \rho_\alpha g \nabla z\right)$

### Convergence Tolerances
- **CNV Tolerance**: $\epsilon_{CNV} = 1 \times 10^{-6}$ (Convergence tolerance for saturations and pressure)
- **Material Balance**: $\epsilon_{MB} = 1 \times 10^{-7}$ (Mass conservation tolerance)
- **Maximum Newton Iterations**: $n_{max} = 25$ per timestep
- **Minimum Iterations**: $n_{min} = 1$ (allow early convergence)
- **Newton Convergence Criteria**: 
  $$\max\left(\frac{|R_i|}{|R_i^0|}\right) < \epsilon_{CNV} \text{ and } \sum_{i=1}^{N_{cells}} |R_i| < \epsilon_{MB}$$
  where $R_i$ is the residual for cell $i$ and $R_i^0$ is the initial residual

### Linear Solver Configuration
- **Primary Solver**: BackslashSolverAD (direct sparse solver)
- **Alternative**: AMGCLSolverAD for larger systems
- **Linear Tolerance**: $\epsilon_{linear} = 1 \times 10^{-8}$
- **Maximum Linear Iterations**: $m_{max} = 100$
- **Preconditioner**: ILU for iterative methods
- **Convergence Criterion**: $\frac{\|Ax - b\|_2}{\|b\|_2} < \epsilon_{linear}$

### Non-Linear Solver Parameters
- **Line Search**: Enabled with $\alpha_{max} = 5$ maximum iterations
- **Acceptance Factor**: $\alpha_{accept} = 1 \times 10^{-3}$ for solution acceptance
- **Line Search Criterion**: $f(x + \alpha p) \leq f(x) + c_1 \alpha \nabla f(x)^T p$ where $c_1 = 1 \times 10^{-4}$
- **Error Handling**: Continue on failure with reduced timestep
- **Verbosity**: Enabled for monitoring convergence behavior

### Time Stepping Strategy
- **Initial Steps**: $\Delta t_{init} = 1-20$ days for stability
- **Historical Period**: $\Delta t_{hist} = 30$ days (monthly timesteps)
- **Forecast Period**: $\Delta t_{forecast} = 90-365$ days (quarterly to yearly)
- **Adaptive Control**: Target $n_{Newton} = 8$ iterations per timestep
- **Step Multipliers**: $\beta_{decrease} = 0.7$, $\beta_{increase} = 1.3$
- **Timestep Control**: 
  $$\Delta t_{n+1} = \begin{cases}
  \beta_{decrease} \cdot \Delta t_n & \text{if } n_{Newton} > 12 \\
  \beta_{increase} \cdot \Delta t_n & \text{if } n_{Newton} < 5 \\
  \Delta t_n & \text{otherwise}
  \end{cases}$$
- **Step Bounds**: $1 \leq \Delta t \leq 365$ days

---

## 4. Well Model Configuration

### Well System Specification
- **Total Wells**: 15 wells (10 producers + 5 injectors) [CORRECTED from 7 wells]
- **Well Type**: Mixed completion types (vertical, horizontal, multi-lateral)
- **Wellbore Radius**: 0.1m (6-inch diameter)
- **Completion**: Multi-layer completions across reservoir zones
- **Development**: 6-phase program over 10 years (3,650 days)

### Producer Well Specifications
- **Count**: 10 producer wells (EW-001 to EW-010) [CORRECTED from 4 wells]
- **Control Type**: Rate-controlled with BHP limits
- **Target Oil Rate**: Phase-dependent (1,500-2,800 STB/day per well)
- **BHP Constraint**: 1,350-1,650 psi minimum (well-specific)
- **Skin Factor**: 3.0-5.0 (damaged completion)
- **Phase Composition**: Oil production (Comp_i = [1,0,0])
- **Peak Field Rate**: 18,500 STB/day (Phase 6)

### Injector Well Specifications  
- **Count**: 5 injector wells (IW-001 to IW-005) [CORRECTED from 3 wells]
- **Injection Fluid**: Water (Comp_i = [0,1,0])
- **Target Rate**: Phase-dependent (5,100-21,500 BWPD total field)
- **BHP Constraint**: 3,100-3,600 psi maximum (well-specific)
- **Skin Factor**: -2.5 to +1.0 (stimulated to damaged)
- **Voidage Replacement**: 1.1-1.18 VRR (phase-dependent)

### Well Constraints and Limits
- **Rate Limits**: Maximum oil, water, and liquid rates
- **Pressure Limits**: Minimum BHP for producers, maximum BHP for injectors
- **Economic Limits**: Water cut and GOR constraints
- **Mechanical Limits**: Tubing capacity and surface facility constraints

### Well Index Calculation
- **Method**: Peaceman well model with skin effects
- **Well Index Formula**: 
  $$WI = \frac{2\pi k h}{\ln(r_e/r_w) + S}$$
  where $k$ is permeability, $h$ is completion height, $r_e$ is equivalent radius, $r_w$ is wellbore radius, and $S$ is skin factor
- **Equivalent Radius**: $r_e = 0.28 \sqrt{\sqrt{(k_y/k_x)}\Delta x^2 + \sqrt{(k_x/k_y)}\Delta y^2} / \left[(k_y/k_x)^{1/4} + (k_x/k_y)^{1/4}\right]$
- **Multi-layer Completion**: $WI_{total} = \sum_{i=1}^{N_{layers}} WI_i$
- **Anisotropy Correction**: Account for $k_v/k_h$ ratio in vertical flow calculations
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

### Memory Management Requirements
- **Memory Allocation**: Minimum 8 GB RAM, recommended 16 GB for full field model
- **Sparse Matrix Storage**: Connectivity matrices must use sparse format for memory efficiency
- **State Vector Preallocation**: Pre-allocate arrays for $N_{cells} \times N_{phases} \times N_{timesteps}$ state data
- **Memory Monitoring**: System must track and report memory usage at each major operation
- **Memory Target**: Total memory usage should not exceed 75% of available system RAM

### Parallel Computing Requirements
- **Parallel Toolbox**: MATLAB Parallel Computing Toolbox required for multi-core execution
- **Worker Configuration**: Optimal worker count = $\min(N_{cores}, \lfloor N_{cells}/1000 \rfloor)$
- **Parallel Efficiency**: Target parallel efficiency $\eta = T_{sequential}/(N_{workers} \times T_{parallel}) > 0.7$
- **Load Balancing**: Computational load must be distributed to achieve $\pm 10\%$ variance in worker utilization
- **Communication Overhead**: Inter-worker communication time should not exceed 5% of total computation time

### Solver Performance Requirements
- **Linear Solver Selection**: 
  - BackslashSolverAD for systems with $N_{DOF} < 100,000$
  - AMGCLSolverAD for systems with $N_{DOF} \geq 100,000$
- **Convergence Efficiency**: Target convergence rate of $10^{-1}$ reduction per Newton iteration
- **Linear Solver Efficiency**: Linear solver must achieve $>90\%$ success rate within maximum iterations
- **Preconditioning Requirements**: 
  - ILU preconditioner for condition numbers $\kappa < 10^6$
  - AMG preconditioner for condition numbers $\kappa \geq 10^6$

### Grid Optimization Requirements
- **Adaptive Refinement**: Grid resolution near wells must be $\leq 0.5 \times r_w$ within drainage radius
- **Coarsening Criteria**: Cell size may increase by maximum factor of 2 in regions where $|\nabla p| < 0.1 \times p_{avg}$
- **Upscaling Requirements**: Property upscaling must preserve total pore volume within $\pm 1\%$
- **Load Balancing**: Computational cell distribution variance across processors must be $< 10\%$

### Simulation Monitoring Requirements
- **Material Balance**: Conservation errors must remain $< 0.01\%$ of total fluid volume
- **Convergence Statistics**: Newton iteration count must average $6-10$ per timestep
- **Well Performance**: Production and injection rates tracked with $\pm 2\%$ accuracy
- **Timestep Control**: Automatic adjustment to maintain convergence within iteration limits
- **Diagnostic Output**: Generate material balance and convergence plots every 100 timesteps

### Results Management Requirements
- **Data Export**: Time series data exported in CSV format with minimum daily frequency
- **Visualization**: Generate standardized plots for pressure, saturation, and production data
- **File Organization**: Structured directory hierarchy for results, logs, and restart files
- **Data Integrity**: MD5 checksums required for all output files
- **Quality Assurance**: Results validation against material balance closure $< 0.1\%$

---

## Technical Implementation Requirements

### System Architecture Requirements
1. **MRST Environment**: Minimum MRST 2023a with required modules loaded
2. **Grid System**: Cartesian tensor grid with fault transmissibility multipliers
3. **Property Framework**: Multi-zone rock properties with spatial correlation
4. **Well System**: 7-well network with multi-layer completions
5. **Control System**: Adaptive timestep scheduling with constraint handling  
6. **Solver Framework**: Coupled non-linear/linear solver system
7. **State Management**: Pressure-saturation initialization from equilibrium
8. **Execution Engine**: Full-field simulation with restart capability
9. **Output System**: Structured data export and visualization pipeline

### Quality Assurance Requirements
- **Grid Validation**: Aspect ratios $< 10:1$, connectivity matrix rank validation
- **Well Verification**: Well index calculations within $\pm 5\%$ of analytical solutions
- **Property Consistency**: Statistical validation of property distributions (mean, variance, correlation)
- **Initial State**: Pressure initialization within $\pm 1\%$ of hydrostatic equilibrium
- **Convergence Monitoring**: Solver performance tracking with automated failure detection

### Performance Targets
- **Runtime**: Maximum 4 hours for 34-year simulation (12,500 timesteps)
- **Memory Usage**: Peak memory consumption $\leq 16$ GB RAM
- **Convergence**: Average Newton iterations $n_{avg} = 6-10$ per timestep
- **Linear Solver**: Efficiency $\eta_{linear} \geq 85\%$ for condition numbers $\kappa < 10^8$
- **Timestep Success**: Acceptance rate $\geq 95\%$ with adaptive control
- **Parallel Scaling**: Speedup factor $S_p \geq 0.7 \times N_{processors}$ for $N_p \leq 8$

---

## Document Information

**Document Version:** 3.0  
**Created:** January 25, 2025  
**Updated:** January 28, 2025  
**Document Type:** Technical Requirements Specification  
**Target MRST Version:** 2023a or later  
**Application:** Multi-compartment reservoir simulation  

**Related Documents:**
- [[00_Overview]] - Field overview and parameters
- [[01_Structural_Geology]] - Grid design basis  
- [[02_Rock_Properties]] - Rock property distributions
- [[03_Fluid_Properties]] - PVT data and correlations

**Specification Status:** ✅ Requirements complete  
**Mathematical Framework:** ✅ Equations and tolerances defined  
**Performance Targets:** ✅ Quantitative benchmarks established  

This technical requirements specification defines comprehensive guidelines for MRST implementation of multi-compartment reservoir simulation. All specifications include mathematical formulations, performance targets, and validation criteria following MRST best practices and industry standards for reservoir simulation. This document serves as the definitive technical reference for developers implementing the simulation system.