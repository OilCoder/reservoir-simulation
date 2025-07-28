# Simulation Data Access Guide

## Overview

This guide provides comprehensive specifications for accessing and interpreting simulation data from the Eagle West Field reservoir simulation. The guide focuses on data structures, naming conventions, unit conversions, and validation requirements that developers need to implement data access systems.

## Table of Contents

1. [File Naming Conventions](#1-file-naming-conventions)
2. [Data Structure Specifications](#2-data-structure-specifications)
3. [YAML Metadata Schema](#3-yaml-metadata-schema)
4. [Unit Conversions](#4-unit-conversions)
5. [Data Validation Requirements](#5-data-validation-requirements)
6. [Common Issues and Specifications](#6-common-issues-and-specifications)
7. [Performance Considerations](#7-performance-considerations)
8. [Cross-Reference Navigation](#8-cross-reference-navigation)

---

## 1. File Naming Conventions

### 1.1 Static Data Files

**Static Data Directory Structure:**
- `/simulation_data/static/` - Root directory for static data
  - `static_data.mat` - Grid geometry, rock regions, well locations
  - `geology/` - Geological model files
  - `petrophysics/` - Rock property files
  - `fluids/` - Fluid property tables
  - `wells/` - Well trajectory and completion data

### 1.2 Dynamic Data Files

**Dynamic Data Directory Structure:**
- `/simulation_data/dynamic/` - Root directory for time-varying data
  - `fields/` - 4D field arrays (pressure, saturation, etc.)
  - `temporal/` - Individual timestep solution files
  - `production/` - Well production and injection data
  - `solver/` - Numerical solver performance data

### 1.3 Derived Data Files

**Derived Data Directory Structure:**
- `/simulation_data/derived/` - Root directory for calculated/processed data
  - `analytics/` - Performance metrics and KPIs
  - `economics/` - Financial analysis and projections
  - `ml_features/` - Machine learning ready datasets

### 1.4 Naming Pattern Rules

**Standard Naming Patterns:**
- Static files: `^[a-z_]+\.mat$`
- Dynamic files: `^(timestep_\d{4}|field_arrays)\.mat$`
- Derived files: `^[a-z_]+_(factors|efficiency|analysis|results)\.mat$`

**Timestep Naming Convention:**
- Format: `timestep_{NNNN}.mat` where NNNN is zero-padded 4-digit timestep number
- Examples: `timestep_0001.mat`, `timestep_0120.mat`

**Validation Requirements:**
- All filenames must match their respective patterns
- No spaces or special characters except underscores
- File extensions must be lowercase
- Timestep numbers must be sequential and zero-padded

---

## 2. Data Structure Specifications

### 2.1 MATLAB File Format Requirements

**Configuration Requirements:**
- MATLAB version compatibility: R2018b or later
- Required packages: I/O package for extended file format support
- Path configuration: Custom functions must be in accessible MATLAB path
- File format: MATLAB v7.3 (.mat) for files > 2GB

**Data Access Patterns:**
- Static data: Single load at initialization
- Dynamic data: Batch loading or streaming for large datasets
- Metadata: Always validate before data access
- Error handling: Implement fallback mechanisms for file access failures

### 2.2 Static Data Structure Specification

**File: static_data.mat**

**Grid Information Structure:**
- `dimensions.nx`: Number of cells in x-direction (integer)
- `dimensions.ny`: Number of cells in y-direction (integer)
- `dimensions.nz`: Number of cells in z-direction (integer, ≥1)
- `grid_x`: Node coordinates in x-direction (nx+1 elements, meters)
- `grid_y`: Node coordinates in y-direction (ny+1 elements, meters)
- `grid_z`: Node coordinates in z-direction (nz+1 elements, meters, if 3D)
- `cell_centers_x`: Cell center x-coordinates (nx elements, meters)
- `cell_centers_y`: Cell center y-coordinates (ny elements, meters)
- `cell_centers_z`: Cell center z-coordinates (nz elements, meters, if 3D)

**Rock Region Structure:**
- `rock_id`: Rock type identifier array
  - Dimensions: [nz, ny, nx] for 3D or [ny, nx] for 2D
  - Data type: Integer
  - Value range: 1 to number of rock types

**Well Information Structure:**
- `wells.well_names`: Cell array of well name strings
- `wells.well_i`: Well i-coordinates (1-based indexing)
- `wells.well_j`: Well j-coordinates (1-based indexing)
- `wells.well_k`: Well k-coordinates (1-based indexing, if 3D)
- `wells.well_types`: Cell array of well type strings ('producer' or 'injector')

### 2.3 Dynamic Field Data Structure

**File: field_arrays.mat**

**Field Array Specifications:**
- `fields_data.dimensions.n_timesteps`: Total number of timesteps (integer)
- `fields_data.dimensions.nx/ny/nz`: Grid dimensions (integers)
- `fields_data.pressure`: Pressure field [time, z, y, x] (psi)
- `fields_data.sw`: Water saturation field [time, z, y, x] (fraction)
- `fields_data.phi`: Porosity field [time, z, y, x] (fraction)
- `fields_data.k`: Permeability field [time, z, y, x] (mD)
- `fields_data.sigma_eff`: Effective stress field [time, z, y, x] (psi)

**Array Indexing Convention:**
- Dimension order: [time, z, y, x]
- Time index: 1 to n_timesteps
- Spatial indices: 1-based MATLAB indexing

### 2.4 Individual Timestep Data Structure

**File: timestep_NNNN.mat**

**Timestep Data Specifications:**
- `timestep_data.time_days`: Simulation time in days (double)
- `timestep_data.wells.names`: Cell array of well names
- `timestep_data.wells.oil_rates`: Oil production rates (STB/day)
- `timestep_data.wells.water_rates`: Water production rates (STB/day)
- `timestep_data.wells.gas_rates`: Gas production rates (MSCF/day)
- `timestep_data.wells.bhp`: Bottom-hole pressures (psi)
- `timestep_data.wells.wct`: Water cut (fraction)

**Solver Information:**
- `timestep_data.solver.converged`: Convergence status (boolean)
- `timestep_data.solver.iterations`: Newton iterations (integer)
- `timestep_data.solver.residual`: Final residual norm (double)
- `timestep_data.solver.time_step_days`: Time step size (days)

### 2.5 Production Data Structure

**File: well_rates.mat, cumulative_production.mat, well_pressures.mat**

**Rate Data Specifications:**
- `rates_data.time_days`: Time vector (days)
- `rates_data.well_names`: Cell array of well names
- `rates_data.oil_rates`: Oil rates matrix [time, wells] (STB/day)
- `rates_data.water_rates`: Water rates matrix [time, wells] (STB/day)
- `rates_data.gas_rates`: Gas rates matrix [time, wells] (MSCF/day)

**Cumulative Data Specifications:**
- `cumulative_data.time_days`: Time vector (days)
- `cumulative_data.well_names`: Cell array of well names
- `cumulative_data.cum_oil`: Cumulative oil matrix [time, wells] (STB)
- `cumulative_data.cum_water`: Cumulative water matrix [time, wells] (STB)
- `cumulative_data.cum_gas`: Cumulative gas matrix [time, wells] (MSCF)

---

## 3. YAML Metadata Schema

### 3.1 Metadata File Structure

Each data file has an associated YAML metadata file with standardized schema:

**Metadata Directory Structure:**
- `/simulation_data/metadata/` - Root directory for YAML metadata files
  - `static/` - Metadata for static data files
  - `dynamic/` - Metadata for dynamic simulation data
  - `derived/` - Metadata for calculated/processed data
- Each `.mat` file has corresponding `.yaml` metadata file
- Hierarchical organization mirrors data file structure

### 3.2 Metadata Schema Specification

**Core Identification Fields:**
- `identification.name`: Human-readable dataset name
- `identification.description`: Detailed description
- `identification.data_id`: Unique identifier
- `identification.creation_date`: ISO 8601 timestamp
- `identification.creator`: Creator information

**Data Type Classification:**
- `data_type`: Primary classification (static_grid, dynamic_solution, etc.)
- `sub_type`: Secondary classification
- `tags`: Array of descriptive tags

**File Information:**
- `file_info.file_format`: File format specification (MATLAB, HDF5, etc.)
- `file_info.file_size_mb`: File size in megabytes
- `file_info.checksum_md5`: MD5 checksum for integrity validation
- `file_info.compression`: Compression information

**Units Specification:**
- `units.pressure`: Pressure units (psi, Pa, bar)
- `units.permeability`: Permeability units (mD, m², darcy)
- `units.length`: Length units (m, ft, cm)
- `units.rates`: Rate units (STB/day, m³/s, bbl/day)
- `units.time`: Time units (days, seconds, years)

**Quality Information:**
- `quality.validation_status`: passed, failed, not_validated
- `quality.completeness`: Data completeness percentage
- `quality.accuracy`: Accuracy assessment
- `quality.known_issues`: Array of known data issues

**Relationships:**
- `relationships.depends_on`: Array of dependency data IDs
- `relationships.used_by`: Array of consumer data IDs
- `relationships.version`: Version information

### 3.3 Metadata Validation Requirements

**Required Fields:**
- All identification fields must be present
- data_type must match approved taxonomy
- units must be specified for all physical quantities
- file_info must include size and format

**Validation Rules:**
- creation_date must be valid ISO 8601
- checksum must match file content
- units must be from approved unit lists
- relationships must reference valid data IDs

---

## 4. Unit Conversions

### 4.1 Standard Unit Conversion Factors

**Pressure Conversions:**
$$P_{Pa} = P_{psi} \times 6894.76$$
$$P_{Pa} = P_{bar} \times 100000$$
$$P_{Pa} = P_{kPa} \times 1000$$
$$P_{Pa} = P_{atm} \times 101325$$

**Length Conversions:**
$$L_m = L_{ft} \times 0.3048$$
$$L_m = L_{in} \times 0.0254$$
$$L_m = L_{cm} \times 0.01$$

**Permeability Conversions:**
$$k_{m^2} = k_{mD} \times 9.869233 \times 10^{-16}$$
$$k_{m^2} = k_{darcy} \times 9.869233 \times 10^{-13}$$

**Volume Conversions:**
$$V_{m^3} = V_{bbl} \times 0.158987294928$$
$$V_{m^3} = V_{ft^3} \times 0.0283168466$$
$$V_{m^3} = V_{gal} \times 0.003785411784$$

**Rate Conversions:**
$$\dot{V}_{m^3/s} = \dot{V}_{STB/day} \times \frac{0.158987294928}{86400}$$
$$\dot{V}_{m^3/s} = \dot{V}_{MSCF/day} \times \frac{28.3168466}{86400}$$

### 4.2 Unit Conversion Implementation Requirements

**Conversion Function Specifications:**
- All conversions must be bidirectional
- Precision: Maintain at least 6 significant digits
- Error handling: Validate input units against approved lists
- Metadata integration: Read source units from metadata

**Supported Unit Systems:**
- SI units (primary): Pa, m, m², m³, kg, s
- Field units: psi, ft, mD, STB, lbm, day
- Mixed units: As specified in metadata

### 4.3 Unit Validation Requirements

**Input Validation:**
- Verify unit strings match approved vocabulary
- Check dimensional consistency
- Validate conversion factor availability

**Output Validation:**
- Verify converted values are physically reasonable
- Check for overflow/underflow conditions
- Maintain conversion audit trail

---

## 5. Data Validation Requirements

### 5.1 Static Data Validation Specifications

**Grid Dimension Validation:**
- nx, ny, nz must be positive integers
- Grid coordinates must be monotonically increasing
- Cell centers must be within grid bounds
- Grid coordinate arrays must have correct lengths (nx+1, ny+1, nz+1)

**Rock ID Validation:**
- Array dimensions must match grid: [nz, ny, nx] or [ny, nx]
- Values must be positive integers starting from 1
- All referenced rock types must exist in rock properties
- No missing or undefined rock regions

**Well Location Validation:**
- Well coordinates must be within grid bounds: 1 ≤ i ≤ nx, 1 ≤ j ≤ ny, 1 ≤ k ≤ nz
- Well names must be unique and non-empty
- Well types must be 'producer' or 'injector'
- Coordinate arrays must have same length as well names

### 5.2 Dynamic Data Validation Specifications

**Array Dimension Validation:**
- All field arrays must have dimensions [n_timesteps, nz, ny, nx]
- Timestep count must match metadata specification
- Spatial dimensions must match static grid
- No missing timesteps in sequence

**Physical Constraint Validation:**
- Pressure: P ≥ 0, typically 14.7 ≤ P ≤ 10000 psi
- Water saturation: 0 ≤ Sw ≤ 1
- Porosity: 0 ≤ φ ≤ 1, typically 0.05 ≤ φ ≤ 0.35
- Permeability: k ≥ 0, typically 0.001 ≤ k ≤ 10000 mD

**Temporal Consistency Validation:**
- Time vector must be monotonically increasing
- Time steps must be positive
- No unrealistic changes between timesteps (e.g., ΔP > 1000 psi/step)

### 5.3 Production Data Validation Specifications

**Rate Validation:**
- Production rates should be non-negative for producers
- Injection rates should be non-negative for injectors
- Rate magnitudes should be within realistic bounds (0 ≤ oil rate ≤ 10000 STB/day)
- Water cut must be between 0 and 1

**Cumulative Validation:**
- Cumulative volumes must be monotonically non-decreasing
- Cumulative values must be consistent with rate integration
- No negative cumulative production

**Pressure Validation:**
- Bottom-hole pressures must be positive
- Pressure values should be within reservoir pressure range
- Pressure trends should be physically consistent

### 5.4 Validation Workflow Requirements

**Validation Execution:**
1. File integrity check (checksum validation)
2. Metadata schema validation
3. Data structure validation
4. Physical constraint validation
5. Cross-reference validation
6. Temporal consistency validation

**Validation Results:**
- Status: passed, passed_with_warnings, failed
- Detailed check results for each validation category
- Warning and error messages with specific locations
- Suggested remediation actions

**Validation Reporting:**
- Timestamp of validation
- Validation criteria version
- Summary statistics (files checked, passed, failed)
- Detailed logs for failed validations

---

## 6. Common Issues and Specifications

### 6.1 File Access Issue Specifications

**File Path Issues:**
- Root directory existence validation
- Expected subdirectory structure verification
- File permission and access rights
- Path separator consistency across platforms

**MATLAB File Loading Issues:**
- Version compatibility requirements (R2018b+)
- Memory limitations for large files
- oct2py/scipy.io fallback mechanisms
- Custom function path configuration

**Diagnostic Requirements:**
- Systematic path existence checking
- File size and format validation
- Alternative file location searching
- Detailed error message generation

### 6.2 Data Format Issue Specifications

**Array Dimension Issues:**
- Expected vs actual dimension comparison
- Singleton dimension handling
- Reshape operation validation
- Transpose operation detection

**Common Dimension Fixes:**
- Squeeze operations for singleton dimensions
- Reshape when total elements match
- Transpose for swapped dimensions
- Error reporting when fixes impossible

### 6.3 Unit Inconsistency Detection

**Pressure Range Analysis:**
- Values < 1: Likely atm/bar, should be psi
- Values > 100000: Likely Pa, should be psi
- Typical reservoir pressure: 100-8000 psi

**Permeability Range Analysis:**
- Values < 1e-12: Likely m², should be mD
- Values > 1e6: Unrealistically high, check conversion
- Typical reservoir permeability: 0.1-1000 mD

**Rate Range Analysis:**
- Oil rates: 0-10000 STB/day typical
- Gas rates: 0-50000 MSCF/day typical
- Water rates: 0-10000 STB/day typical

---

## 7. Performance Considerations

### 7.1 Memory Management Specifications

**Memory Usage Estimation:**
- Array memory = elements × element_size_bytes
- Typical 4D field array: 120 × nz × ny × nx × 8 bytes
- Maximum recommended memory: 80% of available RAM

**Memory Optimization Strategies:**
- Temporal chunking for large datasets
- Spatial subsetting for regional analysis
- Data type optimization (float32 vs float64)
- Memory mapping for very large files

### 7.2 I/O Optimization Specifications

**File Loading Strategies:**
- Static data: Single load at initialization
- Dynamic data: Progressive/streaming loading
- Production data: Batch loading by time ranges
- Metadata: Preload all for fast searching

**Caching Specifications:**
- Cache frequently accessed datasets
- Implement LRU cache eviction
- Maximum cache size limits
- Cache invalidation on file changes

### 7.3 Parallel Processing Considerations

**Parallelization Opportunities:**
- Multiple timestep loading
- Spatial region processing
- Independent well data processing
- Validation operations

**Performance Benchmarking:**
- File loading throughput (MB/s)
- Memory usage efficiency
- Processing time scaling
- I/O bottleneck identification

---

## 8. Cross-Reference Navigation

### 8.1 Navigation Between Organizational Structures

The simulation data is organized in three parallel structures that reference the same underlying datasets:

**Structure Relationships:**
- `by_type/` → Technical data organization
- `by_usage/` → Application-specific organization  
- `by_phase/` → Simulation workflow organization

**Cross-Reference Mapping Requirements:**
- `type_to_usage.yaml`: Maps technical files to usage contexts
- `type_to_phase.yaml`: Maps technical files to workflow phases
- `usage_to_phase.yaml`: Maps usage contexts to workflow phases

### 8.2 Data Lineage Specifications

**Lineage Information Requirements:**
- File creation timestamp and creator
- Source data dependencies
- Processing steps applied
- Version control information
- Quality assessment history

**Lineage Tracking Implementation:**
- Unique data identifiers for all files
- Dependency graph construction
- Version history maintenance  
- Impact analysis for data changes

### 8.3 Workflow-Based Navigation Patterns

**ML Training Workflow:**
1. Load static features (grid properties, well locations, geological data)
2. Load dynamic features (pressure/rate history, saturation evolution)
3. Load targets (production/recovery targets)
4. Load prepared datasets (train/validation/test splits)

**Real-time Monitoring Workflow:**
1. Load current state (latest pressures, rates)
2. Load historical context (production history, trends)
3. Check alerts (anomaly detection, threshold violations)

**Model Validation Workflow:**
1. Load simulation results (final solution state)
2. Load benchmarks (analytical solutions, reference cases)
3. Load quality metrics (convergence analysis, mass balance)

### 8.4 Data Discovery Specifications

**Catalog Exploration Requirements:**
- Metadata-driven dataset discovery
- Category-based organization (by data type)
- Search functionality (text, tags, properties)
- Size and complexity indicators

**Navigation Tools:**
- Cross-reference lookup functions
- Workflow execution frameworks
- Alternative path identification
- Data lineage visualization

---

## Summary

This comprehensive guide provides the essential specifications for accessing Eagle West Field simulation data without implementation code. Key specifications include:

1. **File Naming**: Standardized patterns for predictable data organization
2. **Data Structures**: Complete MATLAB structure specifications with types and dimensions
3. **Metadata Schema**: YAML schema requirements for data description and validation
4. **Unit Conversions**: Mathematical formulas and conversion requirements with LaTeX equations
5. **Validation Requirements**: Comprehensive data quality specifications and constraints
6. **Issue Specifications**: Common problems and their diagnostic requirements
7. **Performance Considerations**: Memory management and I/O optimization guidelines
8. **Navigation Patterns**: Cross-reference systems and workflow specifications

The guide emphasizes data specifications and requirements over implementation details, providing developers with the necessary information to build robust data access systems for reservoir simulation data.