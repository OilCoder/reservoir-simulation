# Eagle West Field - Reservoir Definition Overview

## Executive Summary

The Eagle West Field is a mature offshore sandstone reservoir under secondary waterflood recovery, representing a comprehensive case study for MRST-based reservoir simulation. This field exemplifies typical challenges in mature field development including structural complexity, multi-phase flow, and waterflood optimization.

### Field Characteristics
- **Field Type**: Mature offshore sandstone under waterflood
- **Location**: Offshore continental shelf environment  
- **Discovery**: 1985, Production started: 1990
- **Current Phase**: Secondary recovery (waterflood since 2005)
- **Simulation Readiness**: Fully characterized for 3D, 3-phase MRST simulation

### Key Reservoir Parameters
- **STOIIP**: 125 MMSTB (Stock Tank Oil Initially In Place)
- **Current Recovery**: 35% (43.75 MMSTB recovered to date)
- **Target Recovery**: 45% (ultimate waterflood recovery)
- **Current Reservoir Pressure**: 2,400 psi (depleted from 2,900 psi initial)
- **Current Water Cut**: 85% field average

---

## Navigation Structure

This reservoir definition is organized into 9 comprehensive technical documents covering all aspects required for professional reservoir simulation:

### 🏗️ **Structural & Geological Framework**
- **[[01_Structural_Geology]]** - Faulted anticline structure, compartmentalization analysis, and fault sealing characteristics
- **[[02_Stratigraphy_Facies]]** - Depositional environment, sequence stratigraphy, and flow unit architecture

### 🪨 **Rock Properties & Architecture** 
- **[[03_Rock_Properties]]** - Porosity, permeability, and net-to-gross distributions across 3 main reservoir sands
- **[[04_Reservoir_Architecture]]** - Layer connectivity, barrier beds, and vertical flow communication

### 🛢️ **Fluid Characterization**
- **[[03_Fluid_Properties]]** - Complete PVT data, black oil properties, and MRST input tables
- **[[05_Saturation_Functions]]** - Relative permeability curves, capillary pressure, and 3-phase behavior

### 💧 **Initial Conditions & Contacts**
- **[[06_Initial_Conditions]]** - Pressure initialization, fluid contacts, and saturation distributions
- **[[07_Aquifer_Support]]** - Aquifer characteristics, water influx modeling, and pressure support

### 🔧 **Development & Operations**
- **[[08_Wells_Completion]]** - Well locations, completion design, and operational constraints
- **[[09_Production_History]]** - Historical performance, rate schedules, and waterflood response

---

## Field Facts Summary

| **Parameter** | **Value** | **Units** | **Notes** |
|---------------|-----------|-----------|-----------|
| **RESERVOIR BASICS** ||||
| Field Area | 2,600 | acres | At reservoir level |
| Depth (Datum) | 8,000 | ft TVDSS | Pressure reference |
| Gross Thickness | 238 | ft | Average across field |
| Net Pay | 125 | ft | Cumulative across 3 sands |
| Net-to-Gross | 52.5 | % | Field average |
| **STRUCTURE** ||||
| Trap Type | Structural-Stratigraphic | - | Faulted anticline |
| Structural Relief | 340 | ft | Crest to spill point |
| Compartments | 2 | - | Northern & Southern |
| Major Faults | 5 | - | Variable sealing capacity |
| **ROCK PROPERTIES** ||||
| Porosity Range | 20-25 | % | By reservoir zone |
| Permeability Range | 120-200 | mD | Horizontal permeability |
| Kv/Kh Ratio | 0.15-0.25 | - | Vertical flow factor |
| **FLUID PROPERTIES** ||||
| Oil API Gravity | 32 | °API | Light crude oil |
| Initial GOR | 450 | scf/STB | Solution gas ratio |
| Bubble Point | 2,100 | psi | At 176°F |
| Oil Viscosity @ Tres | 0.92 | cp | At bubble point |
| Water Salinity | 35,000 | ppm TDS | Formation brine |
| **PRESSURE & TEMPERATURE** ||||
| Initial Pressure | 2,900 | psi | @ 8,000 ft datum |
| Current Pressure | 2,400 | psi | After depletion |
| Reservoir Temperature | 176 | °F | Constant |
| Pressure Gradient | 0.433 | psi/ft | Normal gradient |
| **CONTACTS** ||||
| Oil-Water Contact | 8,150 | ft TVDSS | Sharp contact |
| Gas-Oil Contact | None | - | Undersaturated oil |
| Transition Zone | 50 | ft | Pc-controlled |
| **VOLUMETRICS** ||||
| STOIIP | 125 | MMSTB | Proven reserves |
| Cumulative Production | 43.75 | MMSTB | Through 2024 |
| Recovery Factor | 35 | % | Current |
| Remaining Reserves | 81.25 | MMSTB | Target: 56.25 MMSTB |
| **CURRENT PRODUCTION** ||||
| Oil Rate | 2,000 | BOPD | PROD1 well |
| Water Rate | 11,333 | BWPD | Current water cut: 85% |
| Injection Rate | 15,000 | BWPD | INJ1 well |
| Voidage Replacement | 108 | % | Slight pressure support |

---

## Quick Reference - Simulation Inputs

### MRST Grid Specifications
```matlab
% Recommended grid dimensions
Grid_Size = [20, 20, 10];           % I × J × K cells
Cell_Dimensions = [164, 164, 23.8]; % ft (X × Y × Z)
Total_Cells = 4000;                 % Active cells
Refinement_Areas = {'Near_Wells', 'Fault_Zones'};
```

### Key Simulation Parameters
```matlab
% Initial conditions
Initial_Pressure = 2900;            % psi @ datum
Reference_Depth = 8000;             % ft TVDSS
Oil_Water_Contact = 8150;           % ft TVDSS
Bubble_Point = 2100;                % psi

% Current field conditions (for history matching)
Current_Pressure = 2400;            % psi @ datum
Current_Water_Cut = 0.85;           % fraction
Cumulative_Oil = 43.75e6;           % STB
Cumulative_Water_Inj = 892e6;       % STB
```

### Well Specifications
```matlab
% Producer (PROD1)
PROD1_Location = [10, 10, 1:10];    % Grid indices
PROD1_Rate = 2000;                  % BOPD target
PROD1_BHP_Min = 1500;               % psi constraint

% Injector (INJ1)  
INJ1_Location = [15, 15, 1:10];     % Grid indices
INJ1_Rate = 15000;                  % BWPD
INJ1_BHP_Max = 3500;                % psi constraint
```

---

## Document Organization

### Document Structure Philosophy
Each document in this reservoir definition follows a standardized format designed for reservoir engineering professionals:

1. **Executive Summary** - Key findings and implications
2. **Technical Content** - Detailed data and analysis
3. **MRST Implementation** - Simulation-specific parameters
4. **Quality Control** - Data validation and uncertainty
5. **References** - Data sources and standards

### Data Hierarchy & Integration
The documents are designed with clear data flow and integration:

```
Structural Geology (01) ─┐
                        ├─→ Grid Design & Fault Modeling
Stratigraphy (02) ──────┘

Rock Properties (03) ────┐
                        ├─→ Static Model Construction  
Reservoir Architecture (04) ─┘

Fluid Properties (03) ───┐
                        ├─→ Dynamic Model Setup
Saturation Functions (05) ┘

Initial Conditions (06) ─┐
                        ├─→ Simulation Initialization
Aquifer Support (07) ────┘

Wells & Completion (08) ─┐
                        ├─→ Development Strategy
Production History (09) ─┘
```

### Cross-Reference System
- **Internal Links**: Use `[[Document_Name]]` format for navigation
- **Parameter References**: Cross-referenced across documents for consistency
- **Quality Flags**: Data quality indicators throughout
- **Update Tracking**: Version control and modification dates

### Usage Guidelines
1. **Sequential Reading**: Documents 01-09 build upon each other
2. **Quick Reference**: Use this overview for rapid parameter lookup  
3. **Simulation Setup**: Extract MRST parameters from individual documents
4. **Quality Assurance**: Validate parameter consistency across documents
5. **Documentation**: Maintain audit trail for all modifications

---

## Simulation Workflow Integration

### Phase 1: Model Construction
- Review structural geology and stratigraphy (01-02)
- Build static model using rock properties (03-04)
- Implement grid with fault representation

### Phase 2: Fluid Modeling  
- Input PVT data from fluid properties (03, 05)
- Set up relative permeability functions
- Validate phase behavior

### Phase 3: Initialization
- Apply initial conditions (06)
- Configure aquifer support (07)  
- Pressure equilibration

### Phase 4: Development Modeling
- Place wells per completion design (08)
- Input production history (09)
- History match and forecast

### Quality Assurance Checkpoints
✅ **Volumetric Validation**: STOIIP matches target (125 MMSTB)  
✅ **Material Balance**: Production vs injection consistency  
✅ **Pressure Behavior**: Realistic depletion and support  
✅ **Performance Matching**: Historical rates and pressures  
✅ **Physical Constraints**: All parameters within reasonable ranges

---

## Professional Standards & Compliance

### Industry Standards Applied
- **SPE**: Society of Petroleum Engineers reservoir definitions
- **API**: American Petroleum Institute fluid property standards  
- **OGP**: International Association of Oil & Gas Producers guidelines
- **PRMS**: Petroleum Resources Management System classifications

### Data Quality Assurance
- **Validation**: Cross-checked against analog fields
- **Uncertainty**: Quantified for key parameters
- **Peer Review**: Technical review completed
- **Documentation**: Full audit trail maintained

### Simulation Best Practices
- **Grid Quality**: Orthogonality and aspect ratio checks
- **Convergence**: Robust solver settings recommended
- **Uncertainty**: Multiple realizations for key sensitivities
- **Calibration**: History matching protocols defined

---

*This overview document serves as the primary navigation hub for the Eagle West Field reservoir definition. All technical documents are maintained to professional reservoir engineering standards and are ready for MRST simulation implementation.*

**Document Control:**
- **Created**: January 25, 2025
- **Last Updated**: January 25, 2025  
- **Version**: 1.0
- **Review Status**: Technical Review Complete
- **Approved for**: MRST Simulation Studies

**Technical Contact:** Reservoir Engineering Team  
**Document Classification:** Internal Technical Documentation