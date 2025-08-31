# Reservoir Definition Overview - MRST Simulation Parameters

## Executive Summary

This document defines reservoir parameters for comprehensive 3-phase (oil-gas-water) flow simulation using MRST for a full field development program. The reservoir model incorporates multiple lithologies including sandstone, shale, and limestone formations with complex structural geometry and heterogeneous rock properties across a 2,600-acre reservoir.

### Field Development Program (UPDATED - CANON)

- **Development Strategy**: 15-well full field development program
- **Well Configuration**: 15 wells (10 producers + 5 injectors)
- **Development Phases**: 6-phase implementation over **40 years** (14,610 days)
- **Production Target**: 282+ MMbbl oil + 8.8+ Bcf gas production
- **Recovery Physics**: Complete 3-phase flow with gas liberation below 2100 psi
- **Well Types**: Vertical, horizontal, and multi-lateral completions
- **Simulation Duration**: 480 monthly timesteps (40-year lifecycle)

### Simulation Characteristics

- **Model Type**: 3D, 3-phase flow simulation (oil, gas, water)
- **Lithologies**: Sandstone reservoirs with shale and limestone interbeds
- **Field Size**: 2,600 acres with comprehensive well coverage
- **Simulation Framework**: Fully parameterized for MRST implementation

### Simulation Objectives

The reservoir simulation supports comprehensive analysis of:

- **Full Field Development**: 15-well optimization across 2,600-acre reservoir
- **Extended Lifecycle**: 6-phase development strategy over **40-year timeline**
- **Recovery Optimization**: 282+ MMbbl oil + 8.8+ Bcf gas production
- **Gas Liberation Physics**: Active below 2100 psi bubble point (Years 28-40)
- **Pressure Depletion**: 3600 psi → 1412 psi (2188 psi total depletion)
- **3-Phase Recovery**: Water + oil + gas flow with mature field performance

### Key Model Parameters (UPDATED - CANON)

- **Initial Reservoir Pressure**: 3,600 psi at datum depth (8000 ft)
- **Reservoir Temperature**: 176°F (constant)
- **Bubble Point Pressure**: 2,100 psi (gas liberation threshold)
- **Final Pressure Range**: 1,412 psi (after 40-year depletion)
- **Gas Liberation Period**: Years 28-40 (pressure below bubble point)

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

| **Parameter**              | **Value**                | **Units** | **Notes**                 |
| -------------------------- | ------------------------ | --------- | ------------------------- |
| **RESERVOIR GEOMETRY**     |                          |           |                           |
| Model Area                 | 2,600                    | acres     | Simulation grid extent    |
| Depth (Datum)              | 8,000                    | ft TVDSS  | Pressure reference        |
| Gross Thickness            | 238                      | ft        | Total stratigraphic interval |
| Net Pay                    | 125                      | ft        | Flow contributing layers  |
| Net-to-Gross               | 52.5                     | %         | Average across model      |
| **STRUCTURAL FRAMEWORK**   |                          |           |                           |
| Structural Type            | Faulted Anticline        | -         | For grid construction     |
| Structural Relief          | 340                      | ft        | Top to base structure     |
| Fault Compartments         | 2                        | -         | Northern & Southern blocks |
| Major Faults               | 5                        | -         | For transmissibility multipliers |
| **LITHOLOGY & PROPERTIES** |                          |           |                           |
| Primary Lithology          | Sandstone                | -         | Main reservoir rock       |
| Secondary Lithologies      | Shale, Limestone         | -         | Barrier/seal layers       |
| Porosity Range             | 20-25                    | %         | Sandstone reservoir zones |
| Permeability Range         | 120-200                  | mD        | Horizontal permeability   |
| Kv/Kh Ratio                | 0.15-0.25                | -         | Vertical flow factor      |
| **FLUID SYSTEM**           |                          |           |                           |
| Phase System               | Oil-Gas-Water            | -         | 3-phase simulation        |
| Oil API Gravity            | 32                       | °API      | Light crude oil           |
| Initial GOR                | 450                      | scf/STB   | Solution gas ratio        |
| Bubble Point               | 2,100                    | psi       | At reservoir temperature  |
| Oil Viscosity @ Tres       | 0.92                     | cp        | At bubble point           |
| Water Salinity             | 35,000                   | ppm TDS   | Formation brine           |
| **PRESSURE CONDITIONS**    |                          |           |                           |
| Initial Pressure           | 3,600                    | psi       | @ 8,000 ft datum          |
| Final Pressure (40yr)      | 1,412                    | psi       | After complete depletion  |
| Total Pressure Depletion   | 2,188                    | psi       | 40-year field life        |
| Reservoir Temperature      | 176                      | °F        | Constant throughout       |
| Pressure Gradient          | 0.433                    | psi/ft    | Hydrostatic gradient      |
| **FLUID CONTACTS**         |                          |           |                           |
| Oil-Water Contact          | 8,150                    | ft TVDSS  | Sharp contact             |
| Gas-Oil Contact            | None                     | -         | Initially undersaturated  |
| Transition Zone            | 50                       | ft        | Capillary pressure controlled |
| **WELL CONFIGURATION**     |                          |           |                           |
| Total Wells                | 15                       | -         | 10 producers + 5 injectors |
| Producer Wells             | 10                       | -         | Oil production wells      |
| Injector Wells             | 5                        | -         | Water injection wells     |
| Development Phases         | 6                        | -         | Phased implementation     |
| Development Timeline       | **40**                   | **years** | **Extended field lifecycle** |
| Cumulative Oil Production  | **282+**                 | **MMbbl** | **40-year recovery**      |
| Cumulative Gas Production  | **8.8+**                 | **Bcf**   | **Gas liberation**        |
| Gas Liberation Period      | Years 28-40              | -         | When P < 2100 psi         |
| Well Types                 | Vertical/Horizontal/Multi-lateral | -  | Multiple completion designs |

---

## Quick Reference - Simulation Implementation

### Grid Specifications (UPDATED - CANON)

**Current PEBI Grid Design:**
- **Active cells**: 9,660 PEBI cells (equivalent 41×41×12 structure)
- **Grid type**: Perpendicular Bisector (PEBI) with well-centered refinement
- **Well refinement**: 20-50 ft cell sizes near wells (3-tier refinement system)
- **Fault representation**: 5 major faults with transmissibility multipliers
- **Layers**: 12 vertical layers with variable thickness

### Key Initialization Parameters (UPDATED - CANON)

**Reservoir Conditions:**
- **Initial pressure**: 3,600 psi at datum depth (8000 ft)
- **Final pressure**: 1,412 psi (after 40-year depletion)
- **Reference depth**: 8,000 ft TVDSS
- **Oil-water contact**: 8,150 ft TVDSS
- **Bubble point**: 2,100 psi (gas liberation threshold)
- **Reservoir temperature**: 176°F (constant)

**Fluid System:**
- **Phase system**: Three-phase (oil-gas-water) with gas liberation
- **API gravity**: 32°
- **Initial GOR**: 450 scf/STB  
- **Final GOR**: 31 scf/bbl (after gas liberation)
- **Gas production**: 8.8+ Bcf total liberation

### Well Configuration

**Field Development Configuration:**
- **Total wells**: 15 (10 producers + 5 injectors)
- **Development phases**: 6 phases over **40 years** (14,610 days)
- **Cumulative recovery**: 282+ MMbbl oil + 8.8+ Bcf gas
- **Well types**: Vertical, horizontal, and multi-lateral
- **BHP constraints**: 2,000 psi (min producer), 3,600 psi (max injector)
- **Progressive activation**: EW-001 (Year 0.5) → IW-005 (Year 8.0)
- **Gas liberation phase**: Years 28-40 (pressure below bubble point)

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

### Phase 4: Well Implementation (UPDATED)

- **Place 15 wells**: 10 producers (EW-001 to EW-010), 5 injectors (IW-001 to IW-005)
- **Progressive drilling schedule**: 40-year phased activation from wells_config.yaml
- **Mixed completion types**: Vertical, horizontal, and multi-lateral wells
- **Recovery targets**: 282+ MMbbl oil + 8.8+ Bcf gas over 40-year lifecycle
- **Gas handling**: Production controls for gas liberation below 2100 psi
- **Extended simulation**: 480 monthly timesteps with mature field performance

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
- **Last Updated**: August 31, 2025
- **Version**: 3.0 - 40-Year Extended Lifecycle with Gas Production
- **Review Status**: Technical Review Complete - Canon-First Policy Compliant
- **Approved for**: 40-Year Extended Lifecycle MRST Simulation with Gas Liberation
- **Key Updates**: 40-year timeline, 282+MMbbl oil + 8.8+Bcf gas, 3-phase flow

**Technical Contact:** Reservoir Simulation Team  
**Document Classification:** Technical Simulation Documentation
