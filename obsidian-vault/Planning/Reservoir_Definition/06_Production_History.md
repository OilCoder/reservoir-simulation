# Eagle West Field Initial Conditions

**Field**: Eagle West Field  
**Location**: North Sea  
**Operator**: Eagle Petroleum  
**Document Date**: July 2025  
**Status**: Initial simulation setup (time zero)

---

## 1. Initial Reservoir Conditions

### Pressure and Temperature
- **Initial Reservoir Pressure**: 2,900 psi @ 8,850 ft TVD
- **Reservoir Temperature**: 180°F (82°C)
- **Bubble Point Pressure**: 2,650 psi
- **Saturation Pressure**: 2,650 psi (oil saturated)
- **Initial Gas Cap**: None (undersaturated oil)

### Initial Fluid Saturations
- **Initial Oil Saturation (So)**: 69% (average)
- **Initial Water Saturation (Sw)**: 31% (connate water)
- **Initial Gas Saturation (Sg)**: 0% (no free gas)
- **Critical Water Saturation**: 25%
- **Residual Oil Saturation**: 20%

### Initial Fluid Properties
- **Solution Gas-Oil Ratio (Rs)**: 750 scf/STB
- **Oil Formation Volume Factor (Bo)**: 1.285 bbl/STB
- **Gas Formation Volume Factor (Bg)**: 0.00485 ft³/scf
- **Oil Density**: 35° API
- **Gas Specific Gravity**: 0.72
- **Water Salinity**: 35,000 ppm NaCl

---

## 2. Initial Well Test Data

### Discovery Well Initial Performance (EW-001)
- **Initial Flow Rate**: 2,850 bopd (choke limited)
- **Initial Water Cut**: 20% (connate water)
- **Initial GOR**: 750 scf/bbl
- **Flowing Bottom Hole Pressure**: 2,650 psi
- **Productivity Index**: 4.2 bbl/d/psi
- **Skin Factor**: +1.5 (minor completion damage)

### Early Well Test Results
| Well   | Flow Rate (bopd) | Water Cut (%) | GOR (scf/bbl) | PI (bbl/d/psi) | Skin |
|--------|-------------------|---------------|---------------|----------------|------|
| EW-001 | 2,850            | 20            | 750           | 4.2            | +1.5 |
| EW-002 | 3,200            | 18            | 740           | 4.5            | +0.8 |

---

## 3. Initial Drive Mechanisms

### Primary Drive Identification
1. **Solution Gas Drive**: Primary mechanism (60% contribution)
   - Dissolved gas provides expansion energy
   - Expected GOR increase with depletion
   - Initial gas solubility: 750 scf/STB

2. **Rock/Fluid Compressibility**: Secondary mechanism (25% contribution)
   - Rock compressibility: 5 × 10⁻⁶ psi⁻¹
   - Oil compressibility: 12 × 10⁻⁶ psi⁻¹
   - Water compressibility: 3 × 10⁻⁶ psi⁻¹

3. **Aquifer Support**: Minor mechanism (15% contribution)
   - Weak edge water drive from east and south
   - Aquifer strength: Limited
   - Expected minimal pressure support

---

## 4. Initial Material Balance Parameters

### Reservoir Volumes
- **Initial Oil in Place (OOIP)**: 173.5 MMbbl
- **Bulk Rock Volume**: 245.0 MMbbl
- **Net to Gross**: 0.72
- **Porosity**: 18% (average)
- **Hydrocarbon Pore Volume**: 120.3 MMbbl

### PVT Properties at Initial Conditions
- **Oil Viscosity**: 1.85 cp @ reservoir conditions
- **Gas Viscosity**: 0.018 cp @ reservoir conditions  
- **Water Viscosity**: 0.45 cp @ reservoir conditions
- **Oil Compressibility**: 12 × 10⁻⁶ psi⁻¹
- **Water Compressibility**: 3 × 10⁻⁶ psi⁻¹

---

## 5. Initial Well Configuration

### Planned Initial Wells
| Well   | Location | Depth (ft TVD) | Completion | Status |
|--------|----------|----------------|------------|--------|
| EW-001 | North    | 8,835          | Perforated | Ready  |
| EW-002 | Central  | 8,860          | Perforated | Ready  |

### Initial Completion Design
- **Casing**: 7" production casing, cemented
- **Tubing**: 4.5" production tubing
- **Perforations**: 0.5" diameter, 4 shots/ft
- **Completion Fluid**: 9.2 ppg brine
- **Skin Factor**: 0 to +2 (minimal damage expected)

---

## 6. MRST Simulation Initial Setup

### Initial Conditions for Simulation
```matlab
% Initial reservoir conditions
initCond = struct(...
    'pressure', 2900 * psia, ...         % Initial pressure
    'sOil',     0.69, ...                % Initial oil saturation
    'sWater',   0.31, ...                % Initial water saturation
    'sGas',     0.00, ...                % Initial gas saturation
    'Rs',       750 * ft^3/stb, ...      % Solution GOR
    'temp',     180 + 459.67);           % Temperature in Rankine

% Initial well constraints
wellCond = struct(...
    'EW-001', struct('rate', 2850*stb/day, 'bhp', 2650*psia), ...
    'EW-002', struct('rate', 3200*stb/day, 'bhp', 2620*psia));
```

### Initial Simulation Parameters
- **Time Step**: Start with 1 day
- **Minimum Pressure**: 500 psi (abandonment)
- **Maximum Water Cut**: 98%
- **Convergence Tolerance**: 1e-6
- **Newton Iterations**: 25 max

---

## 7. Initial Production Targets

### Early Production Forecast
- **Target Oil Rate**: 6,000 bopd (initial 2-well production)
- **Expected Water Cut**: 18-22% (connate water)
- **Expected GOR**: 750-800 scf/bbl
- **Flowing Tubing Head Pressure**: 1,200-1,400 psi
- **Expected Drawdown**: 250-300 psi

### Initial Development Strategy
- **Phase 1**: Natural depletion with 2 wells
- **Well Spacing**: 1,000 ft (to be optimized)
- **Completion Strategy**: Conventional perforated completions
- **Artificial Lift**: Not required initially
- **Pressure Monitoring**: Monthly pressure surveys

This initial conditions setup provides the foundation for starting reservoir simulation from time zero without historical production constraints.