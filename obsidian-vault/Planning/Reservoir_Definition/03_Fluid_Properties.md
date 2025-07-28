# Reservoir Fluid Properties - PVT Analysis Report

## Fundamental PVT Relationships

### Formation Volume Factor Equations
The oil formation volume factor relates reservoir and surface volumes:
$$B_o = \frac{V_{oil,res}}{V_{oil,std}}$$

The gas formation volume factor is derived from the equation of state:
$$B_g = \frac{0.02827 ZT}{P}$$

### Solution Gas-Oil Ratio
The solution GOR varies with pressure above and below the bubble point:
$$R_s = R_{sb}\left(\frac{P}{P_b}\right)^n$$

where $R_{sb}$ is the solution GOR at bubble point pressure $P_b$.

### Equation of State
The real gas equation of state governs gas behavior:
$$PV = nZRT$$

where $Z$ is the gas compressibility factor.

### Compressibility Definitions
Isothermal compressibility is defined as:
$$c = -\frac{1}{V}\frac{dV}{dP}$$

This applies to oil ($c_o$), gas ($c_g$), and water ($c_w$) compressibilities.

### Viscosity Correlations
- **Oil viscosity**: Function of pressure, temperature, and dissolved gas
- **Gas viscosity**: Correlation with pressure, temperature, and gas gravity
- **Water viscosity**: Function of temperature, pressure, and salinity

---

## Reservoir Conditions
- **Reservoir Depth**: 8,000 ft datum
- **Initial Reservoir Pressure**: 2,900 psi
- **Reservoir Temperature**: 176°F (constant)
- **Pressure Gradient**: 0.433 psi/ft
- **Fluid Type**: Black oil (3-phase system)
- **Initial Fluid State**: Undersaturated oil

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
- **Gas Critical Temperature**: 382°R
- **Gas Critical Pressure**: 665 psia
- **Initial Solution GOR**: 450 scf/STB
- **Gas Composition**: Predominantly methane with C2-C6 components

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

### Gas Compressibility
| Pressure (psi) | Cg (1/psi × 10⁻⁶) | Z-Factor |
|---------------|-------------------|----------|
| 500           | 1,785             | 0.892    |
| 1000          | 960               | 0.835    |
| 1500          | 680               | 0.795    |
| 2000          | 520               | 0.768    |
| 2500          | 420               | 0.750    |
| 3000          | 350               | 0.738    |
| 3500          | 300               | 0.730    |
| 4000          | 260               | 0.725    |

### Gas Properties at Reservoir Temperature (176°F)
- **Pseudo-Critical Temperature**: 399°R
- **Pseudo-Critical Pressure**: 668 psia
- **Gas Viscosity Correlation**: Lee-Gonzalez-Eakin method

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

### Water Compressibility vs Pressure
| Pressure (psi) | Cw (1/psi × 10⁻⁶) |
|---------------|-------------------|
| 500           | 3.85              |
| 1000          | 3.82              |
| 1500          | 3.79              |
| 2000          | 3.76              |
| 2500          | 3.73              |
| 3000          | 3.70              |
| 3500          | 3.67              |
| 4000          | 3.64              |

### Injection Water Properties
- **Source**: Treated surface water
- **Salinity**: 1,500 ppm TDS
- **Injection Temperature**: 80°F
- **Formation Compatibility**: Compatible
- **Viscosity at Injection**: 1.0 cp

---

## 4. Three-Phase Saturation Endpoints

### Critical Saturations
- **Connate Water Saturation (Swc)**: 0.20
- **Residual Oil Saturation to Water (Sorw)**: 0.20
- **Residual Oil Saturation to Gas (Sorg)**: 0.15
- **Critical Gas Saturation (Sgc)**: 0.05
- **Maximum Water Saturation**: 0.80
- **Maximum Gas Saturation**: 0.50

### Three-Phase Relative Permeability Endpoints
| Phase | Endpoint Saturation | Relative Permeability |
|-------|-------------------|----------------------|
| Water | Swc = 0.20        | krw = 0.000          |
| Water | Sw = 0.80         | krw = 0.720          |
| Oil   | So = 1.00         | kro = 1.000          |
| Oil   | Sorw = 0.20       | krow = 0.000         |
| Oil   | Sorg = 0.15       | krog = 0.000         |
| Gas   | Sgc = 0.05        | krg = 0.000          |
| Gas   | Sg = 0.50         | krg = 0.500          |

### Stone's Model Parameters
- **Stone's Model II** for 3-phase relative permeability
- **Water-Oil Corey Exponent (nw)**: 2.0
- **Oil-Water Corey Exponent (now)**: 2.5
- **Gas-Oil Corey Exponent (ng)**: 1.8
- **Oil-Gas Corey Exponent (nog)**: 2.2

---

## 5. PVT Laboratory Analysis Results

### Standard Separator Conditions
- **Stage 1 Separator**: 100 psig @ 80°F
- **Stage 2 (Stock Tank)**: 14.7 psia @ 60°F
- **Total GOR**: 450 scf/STB
- **Stock Tank Oil Gravity**: 32° API
- **Formation Volume Factor**: 1.305 rb/STB @ bubble point

### Flash Liberation Test
- **Test Temperature**: 176°F (reservoir temperature)
- **Sample Type**: Recombined bottomhole sample
- **Initial Pressure**: 2,900 psi
- **Bubble Point Pressure**: 2,100 psi

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

## 6. Phase Behavior and Fluid Characterization

### Black Oil Model Applicability
- **Reservoir Fluid Type**: Black oil (volatile oil)
- **Initial State**: Undersaturated liquid
- **Black Oil Model**: Valid for reservoir pressure range
- **Compositional Effects**: Minimal due to low gas content

### Bubble Point Pressure vs Temperature
| Temperature (°F) | Bubble Point (psi) | Remarks |
|------------------|-------------------|---------|
| 150              | 1,950             | Below reservoir temperature |
| 176              | 2,100             | Reservoir temperature |
| 200              | 2,285             | Above reservoir temperature |
| 250              | 2,750             | High temperature case |
| 300              | 3,350             | Maximum expected |

### Fluid Properties Summary
- **Oil API Gravity**: 32° (light crude oil)
- **Gas Specific Gravity**: 0.785 (lean gas)
- **Formation Water Salinity**: 35,000 ppm TDS
- **Reservoir Pressure**: 2,900 psi (above bubble point)
- **Fluid Contacts**: Oil-water contact at 8,150 ft

### Critical Fluid Properties
- **Oil Density at SC**: 53.1 lbm/ft³
- **Gas Density at SC**: 0.0525 lbm/ft³  
- **Water Density at RC**: 64.0 lbm/ft³
- **Total System Compressibility**: Dominated by oil phase

---

## 7. Black Oil Simulation Data Tables

### Oil-Water Relative Permeability (SWOF)
| Sw    | krw   | krow  | Pcow (psi) |
|-------|-------|-------|------------|
| 0.20  | 0.000 | 1.000 | 15.0       |
| 0.25  | 0.005 | 0.850 | 12.5       |
| 0.30  | 0.020 | 0.720 | 10.0       |
| 0.35  | 0.045 | 0.600 | 7.5        |
| 0.40  | 0.080 | 0.490 | 5.0        |
| 0.45  | 0.125 | 0.390 | 2.5        |
| 0.50  | 0.180 | 0.300 | 0.0        |
| 0.55  | 0.245 | 0.220 | 0.0        |
| 0.60  | 0.320 | 0.150 | 0.0        |
| 0.65  | 0.405 | 0.090 | 0.0        |
| 0.70  | 0.500 | 0.040 | 0.0        |
| 0.75  | 0.605 | 0.010 | 0.0        |
| 0.80  | 0.720 | 0.000 | 0.0        |

### Gas-Oil Relative Permeability (SGOF)
| Sg   | krg   | krog  | Pcog (psi) |
|------|-------|-------|------------|
| 0.00 | 0.000 | 1.000 | 0.0        |
| 0.05 | 0.005 | 0.900 | 0.5        |
| 0.10 | 0.020 | 0.800 | 1.0        |
| 0.15 | 0.045 | 0.700 | 1.5        |
| 0.20 | 0.080 | 0.600 | 2.0        |
| 0.25 | 0.125 | 0.500 | 2.5        |
| 0.30 | 0.180 | 0.400 | 3.0        |
| 0.35 | 0.245 | 0.300 | 3.5        |
| 0.40 | 0.320 | 0.200 | 4.0        |
| 0.45 | 0.405 | 0.100 | 4.5        |
| 0.50 | 0.500 | 0.000 | 5.0        |

### Live Oil PVT Properties (PVTO)
| Rs (scf/STB) | Pbub (psi) | Bo (rb/STB) | μo (cp) |
|--------------|------------|-------------|---------|
| 0            | 14.7       | 1.125       | 1.85    |
| 195          | 500        | 1.125       | 1.85    |
| 285          | 1000       | 1.185       | 1.45    |
| 365          | 1500       | 1.245       | 1.15    |
| 435          | 2000       | 1.295       | 0.95    |
| 450          | 2100       | 1.305       | 0.92    |
| 450          | 2200       | 1.301       | 0.94    |
| 450          | 2500       | 1.295       | 0.98    |
| 450          | 3000       | 1.285       | 1.05    |
| 450          | 3500       | 1.275       | 1.12    |
| 450          | 4000       | 1.265       | 1.18    |

### Gas PVT Properties (PVTG)
| P (psi) | Rv (STB/Mcf) | Bg (rb/Mcf) | μg (cp) |
|---------|--------------|-------------|---------|
| 500     | 0.0          | 3.850       | 0.0145  |
| 1000    | 0.0          | 1.925       | 0.0165  |
| 1500    | 0.0          | 1.283       | 0.0185  |
| 2000    | 0.0          | 0.963       | 0.0205  |
| 2500    | 0.0          | 0.770       | 0.0225  |
| 3000    | 0.0          | 0.642       | 0.0245  |
| 3500    | 0.0          | 0.550       | 0.0265  |
| 4000    | 0.0          | 0.481       | 0.0285  |

### Water PVT Properties (PVTW)
- **Reference Pressure**: 2,900 psi
- **Formation Volume Factor**: 1.0335 rb/STB
- **Compressibility**: 3.7 × 10⁻⁶ 1/psi
- **Viscosity**: 0.385 cp
- **Viscosibility**: 0.0 × 10⁻⁶ 1/psi

### Phase Densities at Standard Conditions
- **Oil Density**: 53.1 lbm/ft³
- **Water Density**: 64.0 lbm/ft³
- **Gas Density**: 0.0525 lbm/ft³

---

## 8. Data Quality and Validation

### PVT Data Validation Checklist
- ✅ Bubble point pressure consistent with CCE measurements
- ✅ Oil formation volume factor validated against separator tests
- ✅ Solution gas-oil ratio verified across pressure range
- ✅ Viscosity correlations match laboratory measurements
- ✅ Water salinity effects properly incorporated
- ✅ Three-phase saturation endpoints verified
- ✅ Relative permeability curves honor critical saturations
- ✅ Phase behavior consistent with reservoir temperature

### Black Oil Model Limitations
1. **Compositional Effects**: Valid above bubble point only
2. **Thermal Effects**: Isothermal assumption at 176°F
3. **Vaporized Oil**: Rv = 0 assumption (dry gas)
4. **Pressure Range**: Validated from 500-4,000 psi
5. **Temperature Sensitivity**: Single temperature correlation

### Recommended Simulation Parameters
- **Time Step Control**: Adaptive based on pressure changes
- **Convergence Criteria**: 1×10⁻⁶ for mass balance
- **Relative Permeability**: Stone's Model II for 3-phase
- **Capillary Pressure**: Include oil-water and gas-oil
- **Fluid Compressibility**: Pressure-dependent tables

### Laboratory Analysis Standards
- **PVT Testing**: API Recommended Practice 40
- **Sample Collection**: API RP 44
- **Relative Permeability**: API RP 42
- **Fluid Recombination**: Bottom-hole sample methodology
- **Quality Assurance**: Duplicate measurements within 2%

---

**Technical Report Classification**: Reservoir Engineering Data
**Analysis Methodology**: Black Oil PVT Characterization
**Simulation Compatibility**: MRST, ECLIPSE, CMG
**Last Technical Review**: Current