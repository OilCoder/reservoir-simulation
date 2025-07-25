# Reservoir Definition Overview - MRST Simulation Parameters

## Executive Summary

This document defines reservoir parameters for comprehensive 3-phase (oil-gas-water) flow simulation using MRST. The reservoir model incorporates multiple lithologies including sandstone, shale, and limestone formations with complex structural geometry and heterogeneous rock properties.

### Simulation Characteristics

- **Model Type**: 3D, 3-phase flow simulation (oil, gas, water)
- **Lithologies**: Sandstone reservoirs with shale and limestone interbeds
- **Well Configuration**: 4 production wells, 3 injection wells (7 total)
- **Simulation Framework**: Fully parameterized for MRST implementation

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

- **[[08_Wells_Completion]]** - Well placement, completion parameters, and flow constraints for 7 wells
- **[[09_Production_History]]** - Well controls, rate specifications, and simulation constraints

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
| Initial Pressure           | 2,900                    | psi       | @ 8,000 ft datum          |
| Reservoir Temperature      | 176                      | °F        | Constant throughout       |
| Pressure Gradient          | 0.433                    | psi/ft    | Hydrostatic gradient      |
| **FLUID CONTACTS**         |                          |           |                           |
| Oil-Water Contact          | 8,150                    | ft TVDSS  | Sharp contact             |
| Gas-Oil Contact            | None                     | -         | Initially undersaturated  |
| Transition Zone            | 50                       | ft        | Capillary pressure controlled |
| **WELL CONFIGURATION**     |                          |           |                           |
| Total Wells                | 7                        | -         | 4 producers + 3 injectors |
| Producer Wells             | 4                        | -         | Oil production wells      |
| Injector Wells             | 3                        | -         | Water injection wells     |

---

## Quick Reference - MRST Implementation

### Grid Specifications

```matlab
% Recommended grid dimensions
Grid_Size = [20, 20, 10];           % I × J × K cells
Cell_Dimensions = [164, 164, 23.8]; % ft (X × Y × Z)
Total_Active_Cells = 4000;          % Active cells
Refinement_Areas = {'Near_Wells', 'Fault_Zones'};
```

### Key Initialization Parameters

```matlab
% Reservoir conditions
Initial_Pressure = 2900;            % psi @ datum
Reference_Depth = 8000;             % ft TVDSS
Oil_Water_Contact = 8150;           % ft TVDSS
Bubble_Point = 2100;                % psi
Reservoir_Temperature = 176;        % deg F

% Fluid system
Phase_System = 'oil-gas-water';     % 3-phase simulation
API_Gravity = 32;                   % deg API
Initial_GOR = 450;                  % scf/STB
```

### Well Configuration

```matlab
% Well counts and types
Total_Wells = 7;                    % 4 producers + 3 injectors
Producer_Count = 4;                 % Oil production wells
Injector_Count = 3;                 % Water injection wells

% Well constraints (example)
Oil_Rate_Target = 'Variable';       % Per well specification
Water_Injection_Rate = 'Variable';  % Per well specification
BHP_Constraints = [1500, 3500];     % [min_prod, max_inj] psi
```

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

```
Structural Geology (01) ─┐
                        ├─→ Grid Design & Fault Modeling
Stratigraphy (02) ──────┘

Rock Properties (03) ────┐
                        ├─→ Static Model Construction
Reservoir Architecture (04) ─┘

Fluid Properties (03) ───┐
                        ├─→ 3-Phase System Setup
Saturation Functions (05) ┘

Initial Conditions (06) ─┐
                        ├─→ Model Initialization
Aquifer Support (07) ────┘

Wells & Completion (08) ─┐
                        ├─→ Well Model Implementation
Production History (09) ─┘
```

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

- Place 7 wells (4 producers, 3 injectors) per completion design (08)
- Configure well controls and operational constraints (09)
- Set up simulation schedule and well management

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

_This overview document serves as the primary navigation hub for reservoir simulation parameter definition. All technical documents are maintained to professional simulation standards and provide complete MRST implementation specifications._

**Document Control:**

- **Created**: January 25, 2025
- **Last Updated**: January 25, 2025
- **Version**: 1.0
- **Review Status**: Technical Review Complete
- **Approved for**: MRST Simulation Implementation

**Technical Contact:** Reservoir Simulation Team  
**Document Classification:** Technical Simulation Documentation
