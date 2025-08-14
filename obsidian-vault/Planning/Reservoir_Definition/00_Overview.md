# Reservoir Definition Overview - MRST Simulation Parameters

## Executive Summary

This document defines reservoir parameters for comprehensive 3-phase (oil-gas-water) flow simulation using MRST for a full field development program. The reservoir model incorporates multiple lithologies including sandstone, shale, and limestone formations with complex structural geometry and heterogeneous rock properties across a 2,600-acre reservoir.

### Field Development Program

- **Development Strategy**: 15-well full field development program
- **Well Configuration**: 15 wells (10 producers + 5 injectors)
- **Development Phases**: 6-phase implementation over 10 years
- **Production Target**: Peak production 18,500 STB/day
- **Well Types**: Vertical, horizontal, and multi-lateral completions

### Simulation Characteristics

- **Model Type**: 3D, 3-phase flow simulation (oil, gas, water)
- **Lithologies**: Sandstone reservoirs with shale and limestone interbeds
- **Field Size**: 2,600 acres with comprehensive well coverage
- **Simulation Framework**: Fully parameterized for MRST implementation

### Simulation Objectives

The reservoir simulation supports comprehensive analysis of:

- **Full Field Development**: 15-well optimization across 2,600-acre reservoir
- **Phased Implementation**: 6-phase development strategy over 10-year timeline
- **Production Optimization**: Target peak production of 18,500 STB/day
- **Recovery Maximization**: Enhanced oil recovery through optimized well placement
- **Reservoir Management**: Long-term pressure maintenance and sweep efficiency

### Key Model Parameters

- **Initial Reservoir Pressure**: 2,900 psi at datum depth
- **Reservoir Temperature**: 176°F (constant)

---

## Navigation Structure

This reservoir definition is organized into 9 comprehensive technical documents covering all simulation parameters required for MRST implementation:

### **Structural & Geological Framework**

- **[[01_Structural_Geology]]** - Structural geometry, fault systems, and compartmentalization for grid design
- **[[02_Stratigraphy_Facies]]** - Stratigraphic layers, facies distribution, and flow unit definition

### **Rock Properties & Architecture**

- **[[03_Rock_Properties]]** - Porosity, permeability, and petrophysical properties for sandstone, shale, and limestone
- **[[04_Reservoir_Architecture]]** - Layer architecture, connectivity, and heterogeneity modeling

### **Fluid Characterization**

- **[[03_Fluid_Properties]]** - PVT data, equation of state parameters, and phase behavior for 3-phase simulation
- **[[05_Saturation_Functions]]** - Relative permeability and capillary pressure for oil-gas-water systems

### **Initial Conditions & Contacts**

- **[[06_Initial_Conditions]]** - Pressure initialization, fluid contacts, and initial saturation distribution
- **[[07_Aquifer_Support]]** - Aquifer modeling, boundary conditions, and pressure support mechanisms

### **Well Configuration & Simulation**

- **[[08_Wells_Completion]]** - Well placement, completion parameters, and flow constraints for 15-well system
- **[[09_Production_History]]** - Well controls, rate specifications, and phased development simulation

---

## Simulation Parameters Summary

| **Parameter**              | **Value**                         | **Units** | **Notes**                        |
| -------------------------- | --------------------------------- | --------- | -------------------------------- |
| **RESERVOIR GEOMETRY**     |                                   |           |                                  |
| Model Area                 | 2,600                             | acres     | Simulation grid extent           |
| Depth (Datum)              | 8,000                             | ft TVDSS  | Pressure reference               |
| Gross Thickness            | 238                               | ft        | Total stratigraphic interval     |
| Net Pay                    | 125                               | ft        | Flow contributing layers         |
| Net-to-Gross               | 52.5                              | %         | Average across model             |
| **STRUCTURAL FRAMEWORK**   |                                   |           |                                  |
| Structural Type            | Faulted Anticline                 | -         | For grid construction            |
| Structural Relief          | 340                               | ft        | Top to base structure            |
| Fault Compartments         | 2                                 | -         | Northern & Southern blocks       |
| Major Faults               | 5                                 | -         | For transmissibility multipliers |
| **LITHOLOGY & PROPERTIES** |                                   |           |                                  |
| Primary Lithology          | Sandstone                         | -         | Main reservoir rock              |
| Secondary Lithologies      | Shale, Limestone                  | -         | Barrier/seal layers              |
| Porosity Range             | 20-25                             | %         | Sandstone reservoir zones        |
| Permeability Range         | 120-200                           | mD        | Horizontal permeability          |
| Kv/Kh Ratio                | 0.15-0.25                         | -         | Vertical flow factor             |
| **FLUID SYSTEM**           |                                   |           |                                  |
| Phase System               | Oil-Gas-Water                     | -         | 3-phase simulation               |
| Oil API Gravity            | 32                                | °API      | Light crude oil                  |
| Initial GOR                | 450                               | scf/STB   | Solution gas ratio               |
| Bubble Point               | 2,100                             | psi       | At reservoir temperature         |
| Oil Viscosity @ Tres       | 0.92                              | cp        | At bubble point                  |
| Water Salinity             | 35,000                            | ppm TDS   | Formation brine                  |
| **PRESSURE CONDITIONS**    |                                   |           |                                  |
| Initial Pressure           | 2,900                             | psi       | @ 8,000 ft datum                 |
| Reservoir Temperature      | 176                               | °F        | Constant throughout              |
| Pressure Gradient          | 0.433                             | psi/ft    | Hydrostatic gradient             |
| **FLUID CONTACTS**         |                                   |           |                                  |
| Oil-Water Contact          | 8,150                             | ft TVDSS  | Sharp contact                    |
| Gas-Oil Contact            | None                              | -         | Initially undersaturated         |
| Transition Zone            | 50                                | ft        | Capillary pressure controlled    |
| **WELL CONFIGURATION**     |                                   |           |                                  |
| Total Wells                | 15                                | -         | 10 producers + 5 injectors       |
| Producer Wells             | 10                                | -         | Oil production wells             |
| Injector Wells             | 5                                 | -         | Water injection wells            |
| Development Phases         | 6                                 | -         | Phased implementation            |
| Development Timeline       | 10                                | years     | Full field development           |
| Peak Production Target     | 18,500                            | STB/day   | Maximum field capacity           |
| Well Types                 | Vertical/Horizontal/Multi-lateral | -         | Multiple completion designs      |

---

## Quick Reference - Simulation Implementation

### Grid Specifications

**Recommended Grid Design:**

- Grid dimensions: 41 × 41 × 12 cells (I × J × K) [CORRECTED for detailed simulation]
- Cell dimensions: 82 × 74 × 8.3 ft (X × Y × Z) [UPDATED for field extent]
- Total active cells: 19,200 (high resolution) [CORRECTED for realistic simulation]
- Refinement strategy: **Tiered optimization** (20-30% coverage target) [CANONICAL APPROACH]
- Refinement areas: Critical wells, major faults, with tier-based prioritization

### Key Initialization Parameters

**Reservoir Conditions:**

- Initial pressure: 2,900 psi at datum depth
- Reference depth: 8,000 ft TVDSS
- Oil-water contact: 8,150 ft TVDSS
- Bubble point: 2,100 psi
- Reservoir temperature: 176°F

**Fluid System:**

- Phase system: Three-phase (oil-gas-water)
- API gravity: 32°
- Initial GOR: 450 scf/STB

### Well Configuration

**Field Development Configuration:**

- Total wells: 15 (10 producers + 5 injectors)
- Development phases: 6 phases over 10 years
- Peak field production target: 18,500 STB/day
- Well types: Vertical, horizontal, and multi-lateral
- BHP constraints: 1,500 psi (min producer), 3,500 psi (max injector)
- Phase development schedule: [3, 3, 2, 3, 2, 2] wells per phase

---

## Document Organization

### Document Structure Philosophy

Each document in this reservoir definition follows a standardized format designed for MRST simulation implementation:

1. **Executive Summary** - Key parameters and simulation relevance
2. **Technical Content** - Detailed data and parameter specifications
3. **MRST Implementation** - Direct simulation input parameters
4. **Quality Control** - Data validation and uncertainty quantification
5. **References** - Technical standards and methodologies

### Data Integration Workflow

The documents are designed with clear data flow for simulation model construction:

**Grid Design & Fault Modeling:**

- Structural Geology (01) → Grid geometry and fault systems
- Stratigraphy (02) → Layer architecture and flow units

**Static Model Construction:**

- Rock Properties (03) → Porosity and permeability distributions
- Reservoir Architecture (04) → Heterogeneity and connectivity

**3-Phase System Setup:**

- Fluid Properties (03) → PVT data and phase behavior
- Saturation Functions (05) → Relative permeability and capillary pressure

**Model Initialization:**

- Initial Conditions (06) → Pressure and saturation initialization
- Aquifer Support (07) → Boundary conditions and pressure support

**Well Model Implementation:**

- Wells & Completion (08) → Well placement and completion design
- Production History (09) → Well controls and operational constraints

### Cross-Reference System

- **Internal Links**: Use `[[Document_Name]]` format for navigation
- **Parameter References**: Cross-referenced for simulation consistency
- **Quality Flags**: Data uncertainty and validation status
- **Update Tracking**: Version control for parameter modifications

### MRST Implementation Guidelines

1. **Sequential Setup**: Documents 01-09 provide ordered simulation inputs
2. **Parameter Extraction**: Use this overview for rapid parameter access
3. **Model Construction**: Extract grid, rock, and fluid parameters systematically
4. **Quality Validation**: Verify parameter consistency across all documents
5. **Documentation**: Maintain complete audit trail for simulation studies

---

## MRST Simulation Workflow

### Phase 1: Static Model Construction

- Extract structural geometry and fault systems (01-02)
- Build grid with appropriate resolution and fault representation
- Assign rock properties (porosity, permeability) to grid cells (03-04)

### Phase 2: Fluid System Setup

- Implement 3-phase PVT data (oil-gas-water) from fluid properties (03, 05)
- Configure relative permeability and capillary pressure functions
- Validate phase behavior consistency

### Phase 3: Model Initialization

- Apply initial pressure and fluid contact conditions (06)
- Configure boundary conditions and aquifer support (07)
- Establish initial saturation distributions

### Phase 4: Well Implementation

- Place 15 wells (10 producers, 5 injectors) per completion design (08)
- Configure phased development schedule with 6 implementation phases
- Set up well controls and operational constraints for full field development (09)
- Implement mixed completion types (vertical, horizontal, multi-lateral)
- Target peak field production of 18,500 STB/day

### Simulation Quality Checkpoints

✅ **Grid Quality**: Proper aspect ratios and fault connectivity  
✅ **Material Balance**: Mass conservation verification  
✅ **Phase Behavior**: Realistic oil-gas-water interactions  
✅ **Well Performance**: Reasonable productivity and injectivity  
✅ **Numerical Stability**: Convergence and timestep management

---

## Technical Standards & Compliance

### Industry Standards Applied

- **SPE**: Society of Petroleum Engineers simulation standards
- **API**: American Petroleum Institute fluid property methods
- **OGP**: International Association of Oil & Gas Producers simulation guidelines
- **MRST**: MATLAB Reservoir Simulation Toolbox standards and conventions

### Data Quality Assurance

- **Parameter Validation**: Cross-checked against published correlations and analog data
- **Uncertainty Quantification**: Statistical analysis for key simulation inputs
- **Technical Review**: Parameter consistency verification across all documents
- **Documentation**: Complete parameter traceability and audit trail

### MRST Simulation Best Practices

- **Grid Construction**: Orthogonality and aspect ratio optimization
- **Numerical Methods**: Robust solver configurations and convergence criteria
- **Sensitivity Analysis**: Multiple parameter realizations for uncertainty assessment
- **Model Validation**: Physical behavior verification and mass balance checks

---

_This overview document serves as the primary navigation hub for 15-well field development reservoir simulation. All technical documents are maintained to professional simulation standards and provide complete MRST implementation specifications for full field development analysis._

**Document Control:**

- **Created**: January 25, 2025
- **Last Updated**: January 25, 2025
- **Version**: 2.0 - 15-Well Field Development Update
- **Review Status**: Technical Review Complete
- **Approved for**: Full Field Development MRST Simulation

**Technical Contact:** Reservoir Simulation Team  
**Document Classification:** Technical Simulation Documentation
