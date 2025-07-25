# Session Plan: Clear Reservoir Definition and Characterization

## Date: January 25, 2025

## 1. OBJECTIVE
Define and characterize a realistic reservoir model that represents a professional-grade simulation case study, ensuring all parameters are clearly specified as expected by reservoir engineers.

## 2. CURRENT STATE ANALYSIS

### 2.1 Existing Configuration
The current simulation setup includes:
- **Grid**: 20×20×10 cells (3,280 ft × 3,280 ft × 233 ft total)
- **Depth Range**: 7,900 - 8,138 ft TVDSS
- **Layers**: 10 geological layers with mixed lithology
- **Wells**: 1 producer (PROD1) and 1 injector (INJ1)
- **Simulation**: 10-year waterflood scenario

### 2.2 Issues with Current Model
1. **Unclear reservoir type**: Is this conventional sandstone, carbonate, or mixed?
2. **Missing key parameters**: API gravity, GOR, bubble point, etc.
3. **Incomplete PVT data**: Need full black oil tables
4. **Geological context unclear**: No structural information
5. **Field size ambiguous**: Need STOIIP/GIIP estimates

## 3. PROPOSED RESERVOIR MODEL

### 3.1 Reservoir Type
**Mature Offshore Sandstone Field Under Waterflood**
- **Field Name**: "Eagle West Field" (fictional)
- **Location**: Offshore shelf environment
- **Discovery**: 1985, Production start: 1990
- **Current Stage**: Secondary recovery (waterflood since 2005)
- **Drive Mechanism**: Originally weak aquifer, now waterflood

### 3.2 Geological Setting
```
Structure: Faulted anticline with 4-way dip closure
Trap Type: Structural-stratigraphic combination
Depositional Environment: Deltaic to shallow marine
Age: Miocene
```

### 3.3 Reservoir Architecture
```
Top Structure: 7,900 ft TVDSS at crest
Gross Thickness: 238 ft
Net Pay: 125 ft (cumulative)
Number of Sands: 3 main reservoir intervals
Compartmentalization: Minor, good lateral continuity
```

### 3.4 Rock Properties (by Reservoir Zone)
| Zone | Name | Depth (ft) | NTG | Porosity | Perm (mD) | Sw |
|------|------|------------|-----|----------|-----------|-----|
| 1 | Upper Sand | 7,950-7,990 | 0.85 | 0.25 | 200 | 0.20 |
| 2 | Middle Sand | 8,025-8,055 | 0.75 | 0.22 | 150 | 0.22 |
| 3 | Lower Sand | 8,100-8,115 | 0.80 | 0.20 | 120 | 0.25 |

### 3.5 Fluid Properties
```yaml
Oil Properties:
  API_gravity: 32°
  Oil_density: 53.1 lb/ft³ (850 kg/m³)
  Viscosity_at_Tres: 2.0 cP
  Bubble_point: 2,100 psi
  GOR: 450 scf/STB
  FVF_at_Pb: 1.25 rb/STB
  Compressibility: 10×10⁻⁶ psi⁻¹

Water Properties:
  Salinity: 35,000 ppm TDS
  Density: 62.4 lb/ft³ (1,000 kg/m³)
  Viscosity: 0.5 cP
  FVF: 1.01 rb/STB
  Compressibility: 3×10⁻⁶ psi⁻¹

Reservoir Conditions:
  Initial_pressure: 2,900 psi @ 8,000 ft datum
  Temperature: 176°F
  Pressure_gradient: 0.433 psi/ft (normal)
```

### 3.6 Contacts and Saturations
```yaml
Contacts:
  GOC: None (undersaturated oil)
  OWC: 8,150 ft TVDSS
  Transition_zone: 50 ft

Initial Saturations:
  Above_OWC:
    So: 0.80
    Sw: 0.20 (connate)
  Transition_zone: Variable (Pc-driven)
  Below_OWC:
    Sw: 1.0
```

### 3.7 Volumetrics
```yaml
Area: 2,600 acres (10.73 km²)
STOIIP: 125 MMSTB
Recovery_to_date: 43.75 MMSTB (35% RF)
Current_reservoir_pressure: 2,400 psi
Water_cut: 85% (field average)
```

### 3.8 Well Configuration
```yaml
PROD1:
  Type: Vertical producer
  Location: Structural crest
  Completion: Perforated 7,950-8,115 ft
  Current_rate: 2,000 BOPD, 11,333 BWPD
  Operating_constraint: Min BHP 1,500 psi

INJ1:
  Type: Vertical water injector
  Location: Down-dip flank
  Completion: Perforated 8,025-8,133 ft
  Injection_rate: 15,000 BWPD
  Operating_constraint: Max BHP 3,500 psi
```

### 3.9 Development Strategy
- **Primary Recovery**: 1990-2005 (25% RF)
- **Secondary Recovery**: 2005-present (targeting 45% RF)
- **Simulation Objective**: Optimize water injection pattern
- **Key Decisions**: Infill drilling vs. injection rebalancing

## 4. IMPLEMENTATION TASKS

### 4.1 Configuration Updates
1. **Update rock_properties_config.yaml**
   - Align layer properties with reservoir zones
   - Add NTG factors
   - Include formation names

2. **Update fluid_properties_config.yaml**
   - Add complete PVT tables
   - Include solution GOR
   - Add formation volume factors vs pressure

3. **Update initial_conditions_config.yaml**
   - Set proper datum and reference pressure
   - Define transition zone initialization
   - Add field volumetrics

4. **Update wells_schedule_config.yaml**
   - Realistic production/injection rates
   - Add completion intervals
   - Include operational constraints

### 4.2 Code Updates
1. **Enhance s01_setup_field.m**
   - Implement NTG in porosity/permeability
   - Add structural dip (optional)
   - Include fault barriers (if needed)

2. **Enhance s02_define_fluid.m**
   - Implement black oil PVT tables
   - Add solution gas handling
   - Include proper FVF calculations

3. **Create s14_calculate_reserves.m**
   - Calculate STOIIP/GIIP
   - Track recovery factors
   - Generate reserve reports

### 4.3 Validation Steps
1. **Volume validation**: Calculated STOIIP matches input
2. **Material balance**: Check injection/production balance
3. **Pressure behavior**: Realistic depletion/support
4. **Water cut evolution**: Matches mature field behavior

## 5. SUCCESS CRITERIA
1. ✓ Clear reservoir definition document
2. ✓ All parameters specified with units
3. ✓ Realistic fluid and rock properties
4. ✓ Volumetrics that make engineering sense
5. ✓ Wells with realistic rates and constraints
6. ✓ Simulation runs without errors
7. ✓ Results show expected waterflood behavior

## 6. DELIVERABLES
1. Updated configuration files (4 YAML files)
2. Enhanced simulation scripts
3. Reservoir characterization report
4. Volumetric calculations spreadsheet
5. Initial simulation results

## 7. RISKS & MITIGATION
- **Risk**: Over-complicating the model
  - **Mitigation**: Start simple, add complexity gradually
- **Risk**: Unrealistic parameter combinations
  - **Mitigation**: Cross-check with analog fields
- **Risk**: Numerical convergence issues
  - **Mitigation**: Test incrementally

## 8. NOTES
- Follow MRST coding conventions from CLAUDE.md
- All changes must maintain backward compatibility
- Document assumptions clearly
- Use industry-standard terminology