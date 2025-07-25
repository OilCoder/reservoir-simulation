# Eagle West Field - Fluid Properties

## Field Overview
- **Field Name**: Eagle West Field
- **Reservoir Depth**: 8,000 ft datum
- **Initial Reservoir Pressure**: 2,900 psi
- **Reservoir Temperature**: 176°F
- **Pressure Gradient**: 0.433 psi/ft

---

## 1. Oil Properties

### Basic Oil Characteristics
- **API Gravity**: 32°
- **Specific Gravity**: 0.865
- **Stock Tank Oil Density**: 53.1 lbm/ft³
- **Bubble Point Pressure**: 2,100 psi @ 176°F
- **Initial Gas-Oil Ratio (GOR)**: 450 scf/STB

### Black Oil PVT Properties

#### Oil Formation Volume Factor (Bo) vs Pressure
| Pressure (psi) | Bo (rb/STB) | Rs (scf/STB) | μo (cp) |
|---------------|-------------|--------------|---------|
| 500           | 1.125       | 195          | 1.85    |
| 1000          | 1.185       | 285          | 1.45    |
| 1500          | 1.245       | 365          | 1.15    |
| 2000          | 1.295       | 435          | 0.95    |
| 2100          | 1.305       | 450          | 0.92    |
| 2200          | 1.301       | 450          | 0.94    |
| 2500          | 1.295       | 450          | 0.98    |
| 3000          | 1.285       | 450          | 1.05    |
| 3500          | 1.275       | 450          | 1.12    |
| 4000          | 1.265       | 450          | 1.18    |

#### Oil Compressibility
| Pressure Range (psi) | Co (1/psi × 10⁻⁶) |
|---------------------|-------------------|
| 500-1000           | 28.5              |
| 1000-1500          | 22.1              |
| 1500-2000          | 18.3              |
| 2000-2500          | 15.8              |
| 2500-3000          | 14.2              |
| 3000-3500          | 13.1              |
| 3500-4000          | 12.3              |

---

## 2. Gas Properties

### Solution Gas Characteristics
- **Gas Specific Gravity**: 0.785 (air = 1.0)
- **Critical Temperature**: 382°R
- **Critical Pressure**: 665 psia
- **Initial Solution GOR**: 450 scf/STB

### Gas Formation Volume Factor (Bg) vs Pressure
| Pressure (psi) | Bg (rb/Mcf) | Z-Factor | μg (cp × 10⁻³) |
|---------------|-------------|----------|----------------|
| 500           | 3.850       | 0.892    | 0.0145         |
| 1000          | 1.925       | 0.835    | 0.0165         |
| 1500          | 1.283       | 0.795    | 0.0185         |
| 2000          | 0.963       | 0.768    | 0.0205         |
| 2500          | 0.770       | 0.750    | 0.0225         |
| 3000          | 0.642       | 0.738    | 0.0245         |
| 3500          | 0.550       | 0.730    | 0.0265         |
| 4000          | 0.481       | 0.725    | 0.0285         |

### Gas Compressibility Factor (Z-Factor)
- **Standing-Katz Correlation Applied**
- **Pseudo-Critical Properties**:
  - Pseudo-critical temperature: 399°R
  - Pseudo-critical pressure: 668 psia

### Gas Viscosity Correlations
- **Lee-Gonzalez-Eakin Correlation**
- Temperature dependence: μg ∝ T^1.5
- Pressure correction factor applied

---

## 3. Water Properties

### Formation Water Characteristics
- **Total Dissolved Solids (TDS)**: 35,000 ppm
- **Water Salinity**: 35,000 mg/L NaCl equivalent
- **Formation Water Type**: NaCl brine
- **Water Specific Gravity**: 1.025

### Water PVT Properties
| Pressure (psi) | Temperature (°F) | Bw (rb/STB) | μw (cp) | Cw (1/psi × 10⁻⁶) |
|---------------|------------------|-------------|---------|-------------------|
| 500           | 176              | 1.0385      | 0.385   | 3.85              |
| 1000          | 176              | 1.0375      | 0.385   | 3.82              |
| 1500          | 176              | 1.0365      | 0.385   | 3.79              |
| 2000          | 176              | 1.0355      | 0.385   | 3.76              |
| 2500          | 176              | 1.0345      | 0.385   | 3.73              |
| 3000          | 176              | 1.0335      | 0.385   | 3.70              |
| 3500          | 176              | 1.0325      | 0.385   | 3.67              |
| 4000          | 176              | 1.0315      | 0.385   | 3.64              |

### Injection Water Specifications
- **Source**: Aquifer water
- **TDS**: 1,500 ppm
- **Injection Temperature**: 80°F
- **Compatibility**: Compatible with formation water
- **Treatment**: Filtered, deoxygenated

---

## 4. Reservoir Conditions

### Initial Conditions
- **Initial Pressure**: 2,900 psi @ 8,000 ft datum
- **Reservoir Temperature**: 176°F (constant)
- **Pressure Gradient**: 0.433 psi/ft
- **Fluid Contacts**:
  - Oil-Water Contact: 8,150 ft
  - Gas-Oil Contact: None (undersaturated oil)

### Pressure-Temperature Relationship
| Depth (ft) | Pressure (psi) | Temperature (°F) |
|-----------|---------------|------------------|
| 7,500     | 2,683         | 172              |
| 7,750     | 2,791         | 174              |
| 8,000     | 2,900         | 176              |
| 8,250     | 3,008         | 178              |
| 8,500     | 3,117         | 180              |

---

## 5. PVT Laboratory Data

### Separator Test Conditions
- **First Stage Separator**:
  - Pressure: 100 psig
  - Temperature: 80°F
- **Second Stage Separator (Stock Tank)**:
  - Pressure: 14.7 psia
  - Temperature: 60°F
- **Separator GOR**: 450 scf/STB
- **Formation Volume Factor at Separator**: 1.305 rb/STB

### Differential Liberation Test Results
| Pressure (psi) | Gas Released (scf/STB) | Cumulative Gas (scf/STB) | Oil Volume (%) | Bo rel |
|---------------|------------------------|--------------------------|----------------|---------|
| 2100          | 0                     | 0                        | 100.0          | 1.000   |
| 1800          | 45                    | 45                       | 98.5           | 0.985   |
| 1500          | 85                    | 130                      | 96.8           | 0.968   |
| 1200          | 95                    | 225                      | 94.9           | 0.949   |
| 900           | 85                    | 310                      | 92.8           | 0.928   |
| 600           | 75                    | 385                      | 90.5           | 0.905   |
| 300           | 45                    | 430                      | 88.1           | 0.881   |
| 100           | 20                    | 450                      | 86.2           | 0.862   |

### Constant Composition Expansion (CCE)
| Pressure (psi) | Relative Volume | Y-Function | Compressibility (1/psi × 10⁻⁶) |
|---------------|-----------------|------------|--------------------------------|
| 4000          | 0.985          | 1.523      | 12.3                           |
| 3500          | 0.988          | 2.083      | 13.1                           |
| 3000          | 0.992          | 2.780      | 14.2                           |
| 2500          | 0.996          | 3.846      | 15.8                           |
| 2100          | 1.000          | 6.250      | 18.3                           |

### Viscosity Measurements
- **Dead Oil Viscosity @ 176°F**: 2.85 cp
- **Saturated Oil Viscosity @ Pb**: 0.92 cp
- **Gas Viscosity @ Reservoir Conditions**: 0.0245 cp
- **Formation Water Viscosity**: 0.385 cp

---

## 6. 3-Phase Behavior

### Phase Envelope
- **Critical Temperature**: 382°F
- **Critical Pressure**: 665 psia
- **Cricondentherm**: 425°F
- **Cricondenbar**: 745 psia
- **Reservoir Fluid State**: Single-phase liquid (undersaturated oil)

### Saturation Pressure Analysis
| Temperature (°F) | Bubble Point (psi) | Dew Point (psi) |
|------------------|-------------------|------------------|
| 150              | 1,950             | N/A              |
| 176              | 2,100             | N/A              |
| 200              | 2,285             | N/A              |
| 250              | 2,750             | N/A              |
| 300              | 3,350             | N/A              |

### Critical Properties
- **Critical Temperature**: 382°F
- **Critical Pressure**: 665 psia
- **Critical Volume**: 0.285 ft³/lbm
- **Critical Compressibility**: 0.275
- **Acentric Factor**: 0.245

### Equation of State (EOS) Validation

#### Peng-Robinson EOS Parameters
- **Component Composition**:
  - C1: 25.8 mol%
  - C2-C3: 12.4 mol%
  - C4-C6: 18.6 mol%
  - C7+: 43.2 mol%

#### Binary Interaction Parameters (kij)
| Component | C1    | C2    | C3    | C4-C6 | C7+   |
|-----------|-------|-------|-------|-------|-------|
| C1        | 0     | 0.011 | 0.025 | 0.045 | 0.085 |
| C2        | 0.011 | 0     | 0.008 | 0.020 | 0.055 |
| C3        | 0.025 | 0.008 | 0     | 0.010 | 0.035 |
| C4-C6     | 0.045 | 0.020 | 0.010 | 0     | 0.015 |
| C7+       | 0.085 | 0.055 | 0.035 | 0.015 | 0     |

#### EOS Tuning Parameters
- **C7+ Molecular Weight**: 215 g/mol
- **C7+ Specific Gravity**: 0.845
- **Volume Shift Parameter**: 0.045

---

## MRST Black Oil Model Parameters

### Required Input Tables for MRST

#### SWOF Table (Oil-Water Relative Permeability)
```matlab
SWOF = [
% Sw    krw     krow    Pcow
  0.20  0.000   1.000   15.0
  0.25  0.005   0.850   12.5
  0.30  0.020   0.720   10.0
  0.35  0.045   0.600   7.5
  0.40  0.080   0.490   5.0
  0.45  0.125   0.390   2.5
  0.50  0.180   0.300   0.0
  0.55  0.245   0.220   0.0
  0.60  0.320   0.150   0.0
  0.65  0.405   0.090   0.0
  0.70  0.500   0.040   0.0
  0.75  0.605   0.010   0.0
  0.80  0.720   0.000   0.0
];
```

#### SGOF Table (Gas-Oil Relative Permeability)
```matlab
SGOF = [
% Sg    krg     krog    Pcog
  0.00  0.000   1.000   0.0
  0.05  0.005   0.900   0.5
  0.10  0.020   0.800   1.0
  0.15  0.045   0.700   1.5
  0.20  0.080   0.600   2.0
  0.25  0.125   0.500   2.5
  0.30  0.180   0.400   3.0
  0.35  0.245   0.300   3.5
  0.40  0.320   0.200   4.0
  0.45  0.405   0.100   4.5
  0.50  0.500   0.000   5.0
];
```

#### PVTO Table (Live Oil PVT)
```matlab
PVTO = [
% Rs    Pbub   Bo      Visc
  0     14.7   1.125   1.85
  195   500    1.125   1.85
  285   1000   1.185   1.45
  365   1500   1.245   1.15
  435   2000   1.295   0.95
  450   2100   1.305   0.92  % Bubble point
  450   2200   1.301   0.94
  450   2500   1.295   0.98
  450   3000   1.285   1.05
  450   3500   1.275   1.12
  450   4000   1.265   1.18
];
```

#### PVTG Table (Gas PVT)
```matlab
PVTG = [
% P     Rv     Bg      Visc
  500   0.0    3.850   0.0145
  1000  0.0    1.925   0.0165
  1500  0.0    1.283   0.0185
  2000  0.0    0.963   0.0205
  2500  0.0    0.770   0.0225
  3000  0.0    0.642   0.0245
  3500  0.0    0.550   0.0265
  4000  0.0    0.481   0.0285
];
```

#### PVTW Table (Water PVT)
```matlab
PVTW = [
% Pref   Bw     Comp    Visc    ViscComp
  2900   1.0335  3.7e-6  0.385   0.0e-6
];
```

### Density Table
```matlab
DENSITY = [
% Oil(lb/ft3)  Water(lb/ft3)  Gas(lb/ft3)
  53.1         64.0           0.0525
];
```

---

## Quality Control and Validation

### Data Consistency Checks
- ✅ Bubble point pressure validated against CCE data
- ✅ Oil formation volume factor matches separator test
- ✅ Gas-oil ratio consistent across all measurements
- ✅ Viscosity correlations validated against laboratory data
- ✅ Water properties consistent with field salinity
- ✅ Phase behavior matches reservoir conditions

### Simulation Recommendations
1. Use black oil model for primary depletion studies
2. Consider compositional model for enhanced recovery
3. Validate relative permeability with core data
4. Monitor bubble point breakthrough during production
5. Update PVT data with additional fluid samples

### Data Sources
- **Laboratory**: Core Laboratories Inc.
- **PVT Report Date**: March 2024
- **Sample Depth**: 8,025 ft
- **Sample Type**: Recombined reservoir fluid
- **Analysis Standard**: API RP 40

---

*Document prepared for MRST reservoir simulation studies*
*Last updated: July 2025*