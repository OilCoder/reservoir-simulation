# 07_Initialization - Reservoir Engineering Specifications

## Table of Contents
1. [Equilibration Methodology](#equilibration-methodology)
2. [Fluid Contacts](#fluid-contacts)
3. [Initial Saturation Distribution](#initial-saturation-distribution)
4. [Pressure Initialization](#pressure-initialization)
5. [Lithology-Specific Initialization](#lithology-specific-initialization)
6. [Three-Phase System Specifications](#three-phase-system-specifications)
7. [Validation and Quality Control](#validation-and-quality-control)

## Equilibration Methodology

### Gravity-Capillary Equilibrium Approach

The reservoir initialization follows gravity-capillary equilibrium principles to establish physically consistent initial conditions. This methodology balances gravitational forces with capillary pressure effects across the reservoir system.

#### Fundamental Equilibrium Equations

The gravity-capillary equilibrium is governed by:

$$P_c = P_{nw} - P_w = \rho_{rel} \cdot g \cdot h$$

Where:
- $P_c$ = Capillary pressure (psi)
- $P_{nw}$ = Non-wetting phase pressure (oil/gas) (psi)
- $P_w$ = Wetting phase pressure (water) (psi)
- $\rho_{rel}$ = Relative density difference between phases (lb/ft³)
- $g$ = Gravitational acceleration (32.174 ft/s²)
- $h$ = Height above free water level (ft)

#### Key Principles:
- **Gravity-Capillary Equilibrium**: Balances gravitational forces with capillary pressure
- **Datum-Based Initialization**: Single reference point for pressure initialization  
- **Phase Equilibrium**: Ensures thermodynamic consistency between phases
- **Multi-lithology Support**: Different equilibration parameters by rock type

#### Datum Parameters:
- **Datum Depth**: 8,000 ft TVDSS (True Vertical Depth Sub-Sea)
- **Initial Pressure**: 2,900 psi at datum
- **Reference Phase**: Oil phase (undersaturated conditions)
- **Temperature**: 176°F at datum depth [CORRECTED for consistency]

## Fluid Contacts

### Three-Phase Contact System

#### Oil-Water Contact (OWC)
- **Depth**: 8,150 ft TVDSS
- **Structural Control**: Spill point controlled
- **Uncertainty**: ±10 ft (95% confidence)
- **Contact Type**: Sharp contact with transition zone

#### Gas-Oil Contact (GOC)
- **Primary Contact**: Not present at initial conditions
- **Solution Gas**: Gas dissolved in oil phase
- **Bubble Point Pressure**: 2,100 psi (below initial pressure) [CORRECTED from 2,650 psi]
- **Gas Cap Development**: Potential during depletion

#### Water-Gas Contact
- **Configuration**: Direct water-oil contact only
- **Gas Phase**: Dissolved in oil and water phases
- **Free Gas**: Minimal at initial conditions

#### Transition Zone Characteristics
- **Thickness**: 50 ft
- **Top**: 8,100 ft TVDSS (50 ft above OWC)
- **Bottom**: 8,200 ft TVDSS (50 ft below OWC)
- **Capillary Pressure Controlled**: Yes
- **Saturation Gradient**: Smooth transition between phases

## Initial Saturation Distribution

### Initial Porosity Conditions

#### Porosity Specifications by Zone
- **Oil Zone Porosity**: Range 0.18 - 0.25 (average 0.22)
- **Transition Zone Porosity**: Range 0.16 - 0.23 (average 0.20)  
- **Aquifer Zone Porosity**: Range 0.20 - 0.26 (average 0.23)
- **Porosity-Depth Relationship**: Decreasing with burial depth
- **Porosity Distribution**: Log-normal with spatial correlation

#### Three-Phase Saturation Zones

### Above Oil-Water Contact (Oil Zone)
- **Oil Saturation (So)**: 0.75 - 0.85 (average 0.80)
- **Water Saturation (Sw)**: 0.15 - 0.25 (connate water, average 0.20)
- **Gas Saturation (Sg)**: 0.00 (undersaturated conditions)
- **Residual Saturations**: Swi = 0.15, Sor = 0.15, Sgr = 0.05

### Transition Zone Specifications
- **Saturation Gradient**: Controlled by capillary pressure curves
- **Brooks-Corey Parameters**: λ = 2.5, Pce = 5.0 psi
- **Saturation Function**: Height-dependent water saturation
- **Vertical Equilibrium**: Gravity-capillary balance maintained

### Below Oil-Water Contact (Aquifer Zone)
- **Water Saturation (Sw)**: 1.00 (fully saturated)
- **Oil Saturation (So)**: 0.00 (above residual)
- **Gas Saturation (Sg)**: 0.00 (dissolved only)
- **Mobile Water**: Sw - Swi = 0.85 (85% mobile water)

## Pressure Initialization

### Hydrostatic Pressure Gradients

The pressure distribution in the reservoir follows hydrostatic principles:

$$P(z) = P_0 + \rho \cdot g \cdot (z - z_0)$$

Where:
- $P(z)$ = Pressure at depth z (psi)
- $P_0$ = Reference pressure at datum depth $z_0$ (psi)
- $\rho$ = Fluid density (lb/ft³)
- $g$ = Gravitational acceleration (32.174 ft/s²)
- $z$ = Depth (ft TVDSS)
- $z_0$ = Reference datum depth (ft TVDSS)

**Phase-Specific Gradients:**
- **Oil Gradient**: 0.350 psi/ft (density: 0.81 g/cm³)
- **Water Gradient**: 0.433 psi/ft (density: 1.0 g/cm³)
- **Gas Gradient**: 0.076 psi/ft (specific gravity: 0.65)
- **Formation Water Salinity**: 80,000 ppm NaCl equivalent

### Initial Pressure Distribution by Zone

| Zone | Depth Range (ft TVDSS) | Pressure Range (psi) | Phase | Gradient (psi/ft) |
|------|------------------------|---------------------|-------|-------------------|
| Oil Zone Top | 7,800 - 8,000 | 2,830 - 2,900 | Oil | 0.350 |
| Oil Zone Base | 8,000 - 8,150 | 2,900 - 2,952 | Oil | 0.350 |
| Transition Zone | 8,100 - 8,200 | 2,935 - 2,974 | Mixed | Variable |
| Aquifer Zone | 8,150 - 8,250 | 2,952 - 2,995 | Water | 0.433 |

### Pressure-Depth Relationship
- **Above OWC**: Oil hydrostatic gradient applies
- **Below OWC**: Water hydrostatic gradient applies  
- **Transition Zone**: Interpolated gradient based on saturation
- **Gas Phase**: Solution gas only, no free gas gradient

### Compartmentalization Effects
- **Structural Compartments**: Pressure variations up to ±10 psi
- **Fault Seal Impact**: Minor pressure differences across faults
- **Communication**: Generally good between compartments

## Lithology-Specific Initialization

### Sandstone Lithology (Primary Reservoir)

#### Initialization Parameters
- **Porosity Range**: 0.18 - 0.28 (log-normal distribution)
- **Permeability Range**: 50 - 500 mD (log-normal distribution)
- **Connate Water Saturation**: 0.15 - 0.25 (averaging 0.20)
- **Residual Oil Saturation**: 0.12 - 0.18 (averaging 0.15)
- **Entry Pressure**: 3.0 - 8.0 psi (Brooks-Corey model)

#### Capillary Pressure Parameters
- **Brooks-Corey Lambda**: 1.8 - 2.8 (averaging 2.3)
- **Irreducible Water Saturation**: 0.15
- **Oil-Water System**: Primary drainage curve
- **Gas-Oil System**: Imbibition characteristics

### Shale Interbeds (Barriers/Baffles)

#### Initialization Parameters  
- **Porosity Range**: 0.05 - 0.12 (low porosity barriers)
- **Permeability Range**: 0.01 - 1.0 mD (tight barriers)
- **Water Saturation**: 0.60 - 0.95 (high water saturation)
- **Oil Saturation**: 0.05 - 0.40 (residual to mobile)
- **Capillary Entry Pressure**: 15 - 50 psi (high entry pressure)

### Carbonate Stringers (Minor Components)

#### Initialization Parameters
- **Porosity Range**: 0.08 - 0.20 (variable porosity types)
- **Permeability Range**: 1.0 - 200 mD (fracture/matrix dependent)
- **Wettability**: Mixed to oil-wet conditions
- **Connate Water Saturation**: 0.10 - 0.30 (variable by porosity type)
- **Saturation Functions**: Separate relative permeability curves

## Three-Phase System Specifications

### Oil Phase Initialization

#### Oil Properties at Initial Conditions
- **Initial Oil Saturation**: 0.75 - 0.85 in oil zone
- **Oil Density**: 0.865 g/cm³ (32° API gravity) [CORRECTED from 45° API]
- **Oil Viscosity**: 1.25 cp at reservoir conditions
- **Solution GOR**: 450 SCF/STB (below saturation) [CORRECTED from 350]
- **Oil Formation Volume Factor**: 1.201 RB/STB
- **Oil Compressibility**: 18 × 10⁻⁶ psi⁻¹

#### Oil Saturation Distribution
- **Above Transition Zone**: So = 0.80 ± 0.05
- **Transition Zone**: Variable based on height above OWC
- **Below OWC**: So = 0.00 (residual after imbibition)
- **Critical Oil Saturation**: 0.15 (flow cutoff)

### Water Phase Initialization

#### Water Properties at Initial Conditions
- **Initial Water Saturation**: 0.15 - 1.00 (zone dependent)
- **Water Density**: 1.02 g/cm³ (80,000 ppm salinity)
- **Water Viscosity**: 0.5 cp at reservoir conditions
- **Water Formation Volume Factor**: 1.009 RB/STB
- **Water Compressibility**: 3.0 × 10⁻⁶ psi⁻¹

#### Water Saturation Distribution
- **Oil Zone**: Sw = 0.20 (connate water)
- **Transition Zone**: Variable (0.20 - 1.00)
- **Aquifer Zone**: Sw = 1.00 (fully saturated)
- **Irreducible Water Saturation**: 0.15

### Gas Phase Initialization

#### Gas Properties at Initial Conditions
- **Initial Gas Saturation**: 0.00 (solution gas only)
- **Gas Specific Gravity**: 0.65 (relative to air)
- **Gas Viscosity**: 0.025 cp at reservoir conditions
- **Gas Formation Volume Factor**: 0.0045 RB/SCF
- **Gas Compressibility**: z-factor dependent

#### Gas Distribution Specifications
- **Free Gas**: None at initial conditions
- **Solution Gas**: 450 SCF/STB in oil phase [CORRECTED from 350]
- **Dissolved Gas in Water**: Minimal (< 1 SCF/STB)
- **Critical Gas Saturation**: 0.05 (flow initiation)

### Three-Phase Relative Permeability

#### Oil-Water System

The oil-water relative permeability follows the Corey model:

$$k_{rw} = k_{rw}^{max} \left(\frac{S_w - S_{wi}}{1 - S_{wi} - S_{or}}\right)^{n_w}$$

$$k_{ro} = k_{ro}^{max} \left(\frac{1 - S_w - S_{or}}{1 - S_{wi} - S_{or}}\right)^{n_o}$$

Where:
- $k_{rw}$, $k_{ro}$ = Water and oil relative permeabilities
- $S_w$ = Water saturation
- $S_{wi}$ = Irreducible water saturation = 0.15
- $S_{or}$ = Residual oil saturation = 0.15
- $n_w$, $n_o$ = Corey exponents = 2.0, 2.5
- $k_{rw}^{max}$ = 0.4, $k_{ro}^{max}$ = 1.0

#### Gas-Oil System  

The gas-oil relative permeability follows:

$$k_{rg} = k_{rg}^{max} \left(\frac{S_g - S_{gr}}{1 - S_{gr} - S_{org}}\right)^{n_g}$$

$$k_{rog} = k_{rog}^{max} \left(\frac{1 - S_g - S_{org}}{1 - S_{gr} - S_{org}}\right)^{n_{og}}$$

Where:
- $S_{gr}$ = Residual gas saturation = 0.05
- $S_{org}$ = Residual oil saturation to gas = 0.20
- $n_g$, $n_{og}$ = Corey exponents = 1.5, 2.0
- $k_{rg}^{max}$ = 0.8

#### Three-Phase Interpolation
- **Model Type**: Stone's Model II for three-phase flow
- **Hysteresis**: Considered for imbibition/drainage cycles
- **Endpoint Scaling**: Applied based on local saturations

## Validation and Quality Control

### Material Balance Verification

#### Primary Balance Checks
- **Phase Volume Conservation**: Total pore volume = oil + water + gas volumes
- **Saturation Constraints**: So + Sw + Sg = 1.0 in all cells
- **Mass Conservation**: Initial fluid masses consistent with PVT properties
- **Tolerance Criteria**: Material balance error < 0.01% of total pore volume

#### Balance Validation Requirements
- **Oil Phase**: Volume calculated from saturation and formation volume factor
- **Water Phase**: Volume includes formation water compressibility effects
- **Gas Phase**: Solution gas accounted for in oil and water phases
- **Total System**: Mass and volume consistency across all phases

### Pressure-Depth Consistency Validation

#### Hydrostatic Equilibrium Checks
- **Oil Zone Gradient**: Pressure increases at 0.350 psi/ft
- **Water Zone Gradient**: Pressure increases at 0.433 psi/ft
- **Transition Zone**: Smooth pressure gradient transition
- **Maximum Deviation**: < 1% from theoretical hydrostatic pressure

#### Pressure Validation Criteria
- **Datum Pressure**: Exactly 2,900 psi at 8,000 ft TVDSS
- **Contact Pressure**: Consistent across oil-water contact
- **Compartment Pressure**: Within specified ranges for each compartment
- **Phase Continuity**: No pressure discontinuities within phases

### Saturation Distribution Validation

#### Saturation Constraint Verification
- **Physical Bounds**: 0 ≤ S ≤ 1 for all phases in all cells
- **Endpoint Constraints**: Saturations respect irreducible/residual limits
- **Contact Consistency**: Proper saturation transitions at fluid contacts
- **Lithology Dependence**: Saturations consistent with rock type properties

#### Saturation Quality Checks
- **Oil Zone**: Water saturation near connate values (0.15-0.25)
- **Water Zone**: Oil saturation at or below residual (≤0.15)
- **Transition Zone**: Gradual saturation change over 50 ft thickness
- **Endpoint Verification**: Critical saturations respected for flow

### Contact Placement Verification

#### Fluid Contact Validation
- **OWC Position**: Verified at 8,150 ft TVDSS ± uncertainty range
- **Contact Sharpness**: Appropriate transition zone thickness
- **Structural Consistency**: Contact follows structural contours
- **Multi-well Validation**: Consistent contact across all penetrating wells

#### Transition Zone Quality
- **Saturation Range**: Water saturation varies from 0.20 to 1.00 across zone
- **Gradient Smoothness**: No abrupt saturation changes
- **Capillary Pressure**: Consistent with saturation height function
- **Vertical Equilibrium**: Gravity-capillary balance maintained

### System Integration Validation

#### Cross-Property Consistency
- **Pressure-Saturation**: Consistent with capillary pressure curves
- **PVT Integration**: Phase properties consistent across P-T conditions
- **Relative Permeability**: Endpoint saturations match initialization
- **Rock Properties**: Porosity and permeability distributions consistent

#### Numerical Stability Checks
- **Grid Resolution**: Adequate to resolve saturation transitions
- **Property Contrasts**: Smooth property transitions between cells
- **Initialization Convergence**: Equilibration algorithm convergence achieved
- **Boundary Conditions**: Proper specification at model boundaries

## Summary

This technical initialization specification provides a comprehensive framework for reservoir engineering initialization without implementation code. Key technical specifications include:

1. **Gravity-Capillary Equilibrium Methodology** with datum-based pressure initialization
2. **Three-Phase Contact System** with oil-water contact and dissolved gas specifications  
3. **Multi-Lithology Initialization** with different parameters for sandstone, shale, and carbonate
4. **Initial Porosity Conditions** without volumetric assumptions, focusing on engineering ranges
5. **Three-Phase System Specifications** for oil, water, and gas phases with relative permeability
6. **Comprehensive Validation Framework** for material balance and consistency checks

The initialization specifications ensure:
- **Material Balance**: Phase volume conservation across the system
- **Pressure Consistency**: Hydrostatic equilibrium with appropriate gradients
- **Saturation Distribution**: Physics-based initial saturations by lithology
- **Contact Placement**: Proper fluid contact positioning and transition zones

### Key Technical Parameters:
- **Datum**: 8,000 ft TVDSS @ 2,900 psi, 176°F [CORRECTED]
- **OWC**: 8,150 ft TVDSS with 50 ft transition zone
- **Three-Phase System**: Oil-water-gas with solution gas at initial conditions
- **Multi-Lithology**: Sandstone, shale, and carbonate initialization parameters
- **Validation**: Material balance, pressure-depth, and saturation consistency

This technical specification framework provides engineering requirements for reservoir initialization without specific software implementation details, focusing on time-zero conditions for reservoir simulation workflows.