# MRST Implementation Specification (Native MATLAB/Octave)

## Executive Summary

This document defines technical specifications and requirements for **native MRST** implementation of a multi-compartment reservoir simulation. It serves as a comprehensive technical guide for developers implementing the simulation system for a mature offshore sandstone reservoir under waterflood conditions using native MATLAB/Octave MRST scripts.

**Technical Specifications:**
- **Grid Architecture**: Fault-conforming PEBI grid (19,500-21,500 active cells)
- **Reservoir Model**: 12-layer heterogeneous sandstone with fault compartmentalization  
- **Fluid System**: 3-phase black oil model with PVT correlations
- **Well Network**: 15 wells with multi-layer completions
- **Flow Physics**: Multi-phase Darcy flow with capillary and gravitational effects
- **Numerical Methods**: Fully-implicit finite volume with automatic differentiation

---

## 1. Required MRST Dependencies

### Core MRST Environment
- **MRST**: MATLAB Reservoir Simulation Toolbox (native installation)
- **MATLAB/Octave**: Runtime environment for MRST execution
- **Core modules**: Essential MRST modules for reservoir simulation

### Essential MRST Modules
- **upr**: Unstructured Perpendicular Bisection (PEBI) grids - **REQUIRED for PEBI grid construction**
- **ad-core**: Automatic differentiation framework
- **ad-blackoil**: Black oil model implementation
- **ad-props**: Advanced fluid and rock property models
- **ad-fi**: Fully-implicit solvers
- **incomp**: Incompressible flow solvers
- **gridprocessing**: Grid generation and processing tools
- **mrst-gui**: Visualization and plotting utilities

### Optional MRST Modules
- **upscaling**: Grid coarsening and upscaling
- **diagnostics**: Flow diagnostics and analysis
- **ad-mechanics**: Geomechanical coupling
- **wellpaths**: Well trajectory and completion modeling

### Development Dependencies
- **YAML parser**: Custom YAML configuration reader (read_yaml_config.m)
- **Visualization**: MRST plotting functions and custom visualization
- **Data export**: MATLAB/Octave data formats (.mat files)

### Container Requirements
- **Octave 6.0+**: Open-source MATLAB alternative
- **MRST 2025a**: Latest MRST release with required modules
- **File system**: Access to configuration files and data directories

---

## 2. Grid Setup Parameters

### Grid Specifications
- **Grid Type**: Fault-conforming PEBI (Perpendicular Bisection) grid
- **Approximate Cell Count**: 19,500-21,500 cells (variable due to size-field optimization)
- **Field Extent**: 3280 ft × 2950 ft × 100 ft (1000m × 899m × 30.5m)
- **Top Depth**: 2438m (8000 ft datum)
- **Cell Resolution**: Variable size-field (20-82 ft horizontal, 8.3 ft vertical)

### Layer Configuration
- **Layer Count**: 12 vertical layers
- **Layer Thicknesses**: Uniform based on flow unit architecture
  - Average layer: 8.3 ft (2.5 m) per flow unit
  - Upper layers: 6-10 ft (thin flow units)
  - Middle layers: 8-12 ft (thick flow units)  
  - Lower layers: 6-10 ft (variable flow units)
- **Vertical Resolution**: Optimized for geological flow units and numerical stability

### Fault System Implementation
- **Fault Count**: 5 major fault planes
- **Fault Types**: Sealing and partially-sealing barriers
- **Implementation**: Fault-conforming grid edges (native PEBI geometry, no transmissibility multipliers needed)
- **Fault Orientation**: Primarily NE-SW trending normal faults
- **Compartmentalization**: 3 main flow units with natural grid-based barriers

### Grid Quality Requirements
- **Aspect Ratio**: Maximum 10:1 for numerical stability (variable due to size-field)
- **Cell Angles**: Minimum 20° internal angles for PEBI cells
- **Size Transitions**: Maximum 30% size change per distance unit (gradient limit)
- **Volume Consistency**: Verified against geological framework
- **Connectivity**: Validated flow paths with fault-conforming geometry
- **Active Cells**: Non-zero porosity and permeability validation
- **Total Cells**: 19,500-21,500 active cells (size-field optimized for accuracy vs computational efficiency)

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
**Layer-by-Layer Implementation (PEBI grid):**
- **Upper Zone** (Layers 1-3): Sandstone - 19.5% avg porosity, 85 mD avg permeability, Kv/Kh=0.5
- **Layer 4**: Shale barrier - 5.0% porosity, 0.01 mD permeability, Kv/Kh=0.1
- **Middle Zone** (Layers 5-7): Sandstone - 22.8% avg porosity, 165 mD avg permeability, Kv/Kh=0.5
- **Layer 8**: Shale barrier - 5.0% porosity, 0.01 mD permeability, Kv/Kh=0.1
- **Lower Zone** (Layers 9-12): Sandstone - 14.5% avg porosity, 25 mD avg permeability, Kv/Kh=0.5
- **Fault Zones**: Reduced transmissibility (0.1-0.01 multipliers)
- **Property Correlation**: See Section 9.1 in [[02_Rock_Properties]] for complete specification

### Fluid Property Requirements
- **Phase System**: Water-Oil-Gas (3-phase black oil)
- **Oil Properties**: 32° API oil with bubble point at 2100 psi
- **Water Properties**: Formation brine with 35,000 ppm TDS
- **Gas Properties**: Associated gas with standard correlations
- **PVT Data**: Laboratory-measured pressure-volume-temperature relationships
- **Relative Permeability**: Special core analysis (SCAL) data

### Initial Reservoir Conditions
- **Pressure**: Hydrostatic gradient with 3600 psi at datum
- **Oil-Water Contact**: 8150 ft subsea
- **Initial Water Saturation**: 20% in oil zone
- **Initial Oil Saturation**: 80% in oil zone
- **Gas Saturation**: 0% (undersaturated conditions)
- **Solution GOR**: 450 scf/bbl at initial conditions

---

## 6. Performance Optimization Guidelines

### Memory Management Requirements
- **Memory Allocation**: Minimum 8 GB RAM, recommended 16 GB for full field model
- **NumPy Arrays**: Use efficient numpy arrays with appropriate dtype (float32/float64)
- **Sparse Matrices**: scipy.sparse matrices for connectivity and transmissibility
- **State Vector Storage**: HDF5 format for time-series data with compression
- **Memory Monitoring**: psutil for tracking memory usage at each major operation
- **Memory Target**: Total memory usage should not exceed 75% of available system RAM

### Parallel Computing Requirements
- **Multiprocessing**: Native Python multiprocessing or concurrent.futures
- **Dask Integration**: Distributed computing for large grid operations
- **Worker Configuration**: Optimal worker count = $\min(N_{cores}, \lfloor N_{cells}/1000 \rfloor)$
- **Parallel Efficiency**: Target parallel efficiency $\eta = T_{sequential}/(N_{workers} \times T_{parallel}) > 0.7$
- **Load Balancing**: Use dask.distributed for automatic load balancing
- **Communication Overhead**: Minimize data transfer between workers using shared memory

### Solver Performance Requirements
- **Linear Solver Selection**: 
  - scipy.sparse.linalg.spsolve for systems with $N_{DOF} < 100,000$
  - scipy.sparse.linalg.lgmres or petsc4py for systems with $N_{DOF} \geq 100,000$
- **Convergence Efficiency**: Target convergence rate of $10^{-1}$ reduction per Newton iteration
- **Linear Solver Efficiency**: Linear solver must achieve $>90\%$ success rate within maximum iterations
- **Preconditioning Requirements**: 
  - scipy.sparse.linalg incomplete LU for condition numbers $\kappa < 10^6$
  - pyamg algebraic multigrid for condition numbers $\kappa \geq 10^6$

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
- **Data Export**: Time series data in HDF5/NetCDF format with automatic compression
- **Alternative Formats**: Parquet for tabular data, JSON for metadata
- **Visualization**: matplotlib/plotly for 2D plots, pyvista for 3D visualization
- **File Organization**: Structured directory hierarchy following Python conventions
- **Data Integrity**: hashlib for checksum validation of all output files
- **Quality Assurance**: Results validation against material balance closure $< 0.1\%$

---

## 7. Python-MRST Integration Architecture

### Interface Strategy Options
1. **oct2py Interface**: Python-to-Octave bridge for MRST functions
2. **MATLAB Engine API**: Direct Python-to-MATLAB interface
3. **Native Python**: Pure Python reservoir simulation (pyrst, devito)
4. **Hybrid Approach**: Python orchestration with MRST computational core

### Recommended Architecture: Hybrid Python-MRST
```python
# Core Python modules for workflow orchestration
import numpy as np
import scipy.sparse as sp
from dataclasses import dataclass
from typing import Dict, List, Optional, Tuple
import h5py
import yaml

# MRST interface (choose one)
from oct2py import octave  # Option 1: Octave interface
# import matlab.engine     # Option 2: MATLAB engine

@dataclass
class ReservoirConfig:
    grid_dims: Tuple[int, int, int]
    cell_size: Tuple[float, float, float]
    rock_properties: Dict[str, float]
    fluid_properties: Dict[str, float]
    well_config: Dict[str, List]
```

### File Structure Convention
```
mrst_simulation_scripts/
├── python/                      # Python implementation
│   ├── __init__.py
│   ├── s01_initialize_mrst.py   # MRST setup and validation
│   ├── s02_define_fluids.py     # Fluid property setup
│   ├── s03_structural_framework.py # Structural framework
│   ├── s04_add_faults.py        # Fault system integration
│   ├── s05_create_pebi_grid.py  # PEBI grid construction
│   ├── s99_run_workflow.py      # Main orchestrator
│   ├── utils/
│   │   ├── __init__.py
│   │   ├── config_reader.py     # YAML configuration parser
│   │   ├── data_export.py       # HDF5/NetCDF export utilities
│   │   └── validation.py        # Quality control functions
│   └── tests/                   # Unit tests
├── config/                      # YAML configuration files
└── output/                      # Simulation results
```

### Data Type Conventions
- **Arrays**: numpy.ndarray with explicit dtype specification
- **Sparse Matrices**: scipy.sparse.csr_matrix for efficient storage
- **Time Series**: pandas.DataFrame with datetime index
- **Configuration**: Python dataclasses or pydantic models
- **Output**: HDF5 with compression, metadata in JSON/YAML

---

## Technical Implementation Requirements

### System Architecture Requirements
1. **Python Environment**: Python 3.8+ with scientific computing stack
2. **MRST Interface**: oct2py or matlab.engine for MRST function access
3. **Grid System**: Fault-conforming PEBI grid using MRST UPR module (compositePebiGrid2D)
4. **Property Framework**: Multi-zone rock properties with spatial correlation
5. **Well System**: 15-well network with multi-layer completions [CORRECTED]
6. **Control System**: Adaptive timestep scheduling with constraint handling  
7. **Solver Framework**: scipy.sparse linear solvers with Newton iteration
8. **State Management**: Pressure-saturation initialization from equilibrium
9. **Execution Engine**: Full-field simulation with HDF5 restart capability
10. **Output System**: HDF5/NetCDF data export and matplotlib/pyvista visualization
11. **UPR Module**: MRST unstructured grid capabilities for PEBI construction

### Quality Assurance Requirements
- **Grid Validation**: Aspect ratios $< 10:1$, connectivity matrix rank validation
- **Well Verification**: Well index calculations within $\pm 5\%$ of analytical solutions
- **Property Consistency**: Statistical validation of property distributions (mean, variance, correlation)
- **Initial State**: Pressure initialization within $\pm 1\%$ of hydrostatic equilibrium
- **Convergence Monitoring**: Solver performance tracking with automated failure detection

### Performance Targets (Python-MRST)
- **Runtime**: Maximum 6 hours for 10-year simulation (500 timesteps)
- **Memory Usage**: Peak memory consumption $\leq 16$ GB RAM
- **Convergence**: Average Newton iterations $n_{avg} = 6-10$ per timestep
- **Linear Solver**: scipy.sparse efficiency $\eta_{linear} \geq 80\%$ for condition numbers $\kappa < 10^8$
- **Timestep Success**: Acceptance rate $\geq 95\%$ with adaptive control
- **Python Overhead**: Interface overhead $< 20\%$ compared to native MATLAB
- **Data Export**: HDF5 export speed $\geq 100$ MB/s for time-series data

---

## Document Information

**Document Version:** 4.0 (Python-MRST)  
**Created:** January 25, 2025  
**Updated:** January 30, 2025  
**Document Type:** Technical Requirements Specification  
**Target Implementation:** Python 3.8+ with MRST interface  
**Application:** Multi-compartment reservoir simulation via Python  

**Related Documents:**
- [[00_Overview]] - Field overview and parameters
- [[01_Structural_Geology]] - Grid design basis  
- [[02_Rock_Properties]] - Rock property distributions
- [[03_Fluid_Properties]] - PVT data and correlations

**Specification Status:** ✅ Requirements updated for Python-MRST  
**Mathematical Framework:** ✅ Equations and tolerances defined  
**Performance Targets:** ✅ Python-specific benchmarks established  
**Implementation Type:** ✅ Hybrid Python-MRST architecture  

This technical requirements specification defines comprehensive guidelines for **Python-MRST** implementation of multi-compartment reservoir simulation. All specifications include mathematical formulations, performance targets, and validation criteria following Python best practices and MRST standards for reservoir simulation. This document serves as the definitive technical reference for developers implementing the Python-based simulation system.