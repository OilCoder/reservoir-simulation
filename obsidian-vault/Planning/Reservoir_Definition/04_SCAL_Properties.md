# Special Core Analysis (SCAL) Properties - Eagle West Field

## Document Information
- **Field**: Eagle West Field
- **Date**: 2025-01-25
- **Document**: 04_SCAL_Properties.md
- **Purpose**: Comprehensive SCAL characterization for MRST 3-phase simulation

## Executive Summary

This document presents the Special Core Analysis (SCAL) properties for the Eagle West Field, providing essential input parameters for 3-phase relative permeability modeling in MRST reservoir simulation. The data encompasses relative permeability curves, capillary pressure relationships, wettability characterization, and hysteresis effects required for accurate multiphase flow modeling.

---

## 1. 3-Phase Relative Permeability

### 1.1 Oil-Water Relative Permeability Curves

#### Core Sample Data Summary
| Sample ID | Depth (ft) | Porosity (%) | Permeability (mD) | Rock Type |
|-----------|------------|--------------|-------------------|-----------|
| EW-01-H1  | 8,245      | 18.5         | 125               | Sandstone |
| EW-02-H2  | 8,267      | 16.8         | 89                | Sandstone |
| EW-03-H3  | 8,291      | 19.2         | 158               | Sandstone |
| EW-04-H4  | 8,315      | 17.4         | 112               | Sandstone |
| EW-05-H5  | 8,338      | 20.1         | 187               | Sandstone |

#### Oil-Water Relative Permeability Parameters
| Parameter | Symbol | Value | Units | Source |
|-----------|---------|-------|-------|---------|
| Connate Water Saturation | Swc | 0.22 | fraction | Laboratory |
| Residual Oil Saturation (Water) | Sorw | 0.25 | fraction | Laboratory |
| Oil Relative Permeability at Swc | kro_max | 0.85 | fraction | Laboratory |
| Water Relative Permeability at Sor | krw_max | 0.35 | fraction | Laboratory |
| Oil Corey Exponent | no | 2.8 | - | Curve Fit |
| Water Corey Exponent | nw | 1.9 | - | Curve Fit |

#### Corey Model Parameters (Oil-Water)
```
kro = kro_max * ((So - Sorw)/(1 - Swc - Sorw))^no
krw = krw_max * ((Sw - Swc)/(1 - Swc - Sorw))^nw
```

### 1.2 Gas-Oil Relative Permeability Curves

#### Gas-Oil Relative Permeability Parameters
| Parameter | Symbol | Value | Units | Source |
|-----------|---------|-------|-------|---------|
| Critical Gas Saturation | Sgc | 0.05 | fraction | Laboratory |
| Residual Oil Saturation (Gas) | Sorg | 0.18 | fraction | Laboratory |
| Gas Relative Permeability at Sor | krg_max | 0.75 | fraction | Laboratory |
| Oil Relative Permeability at Sgc | krog_max | 0.82 | fraction | Laboratory |
| Gas Corey Exponent | ng | 1.6 | - | Curve Fit |
| Oil Corey Exponent (Gas) | nog | 2.2 | - | Curve Fit |

#### Corey Model Parameters (Gas-Oil)
```
krg = krg_max * ((Sg - Sgc)/(1 - Swc - Sorg - Sgc))^ng
krog = krog_max * ((So - Sorg)/(1 - Swc - Sorg - Sgc))^nog
```

### 1.3 3-Phase Relative Permeability Model

#### Stone's Second Model (Stone II)
The Eagle West Field utilizes Stone's Second Model for 3-phase relative permeability calculations:

```
kro3 = kro_max * [(krow/kro_max + krw) * (krog/kro_max + krg) - (krw + krg)]
```

Where:
- kro3 = 3-phase oil relative permeability
- krow = oil relative permeability in oil-water system
- krog = oil relative permeability in gas-oil system
- krw = water relative permeability
- krg = gas relative permeability

#### Saturation Endpoints Summary
| Parameter | Value | Definition |
|-----------|-------|------------|
| Swc | 0.22 | Connate water saturation |
| Sorw | 0.25 | Residual oil saturation to water |
| Sorg | 0.18 | Residual oil saturation to gas |
| Sgr | 0.08 | Residual gas saturation |
| Sgc | 0.05 | Critical gas saturation |

---

## 2. Capillary Pressure

### 2.1 Primary Drainage Curves

#### Mercury Injection Capillary Pressure (MICP) Data
| Sample | Pore Throat Radius (μm) | Pc_entry (psi) | Pc_50 (psi) | Sorting Coefficient |
|--------|-------------------------|----------------|-------------|-------------------|
| EW-01  | 12.5                   | 8.2            | 15.6        | 2.1               |
| EW-02  | 9.8                    | 10.5           | 19.8        | 2.4               |
| EW-03  | 15.2                   | 6.8            | 12.9        | 1.9               |
| EW-04  | 11.1                   | 9.1            | 17.2        | 2.2               |
| EW-05  | 16.8                   | 5.9            | 11.4        | 1.8               |

#### Brooks-Corey Capillary Pressure Model
```
Pc = Pd * (Sw_eff)^(-1/λ)
```

Where:
- Sw_eff = (Sw - Swc)/(1 - Swc)
- Pd = Displacement pressure
- λ = Pore size distribution index

#### Brooks-Corey Parameters
| Rock Type | Displacement Pressure Pd (psi) | Pore Size Index λ | R² |
|-----------|--------------------------------|-------------------|-----|
| Sandstone | 8.5                           | 0.45              | 0.96|

### 2.2 Imbibition Curves

#### Imbibition Capillary Pressure Parameters
| Parameter | Primary Drainage | Imbibition | Hysteresis Factor |
|-----------|------------------|------------|-------------------|
| Displacement Pressure (psi) | 8.5 | 12.8 | 1.5 |
| Pore Size Index | 0.45 | 0.38 | - |
| Maximum Pc (psi) | 85.2 | 72.6 | 0.85 |

### 2.3 Height Above Free Water Level

#### Leverett J-Function Correlation
```
J(Sw) = (Pc * √(k/φ)) / (σ * cos(θ))
```

#### J-Function Parameters
| Parameter | Value | Units |
|-----------|-------|-------|
| Surface Tension (σ) | 28.5 | dyne/cm |
| Contact Angle (θ) | 25° | degrees |
| J-Function at Swc | 1.85 | - |
| J-Function Coefficient | 0.67 | - |

#### Transition Zone Modeling
| Zone | HAFWL Range (ft) | Sw Range | Characteristics |
|------|------------------|----------|----------------|
| Free Water Level | 0 | 1.00 | 100% water saturation |
| Transition Zone | 0-45 | 0.22-0.85 | Mixed saturation |
| Oil Zone | >45 | 0.22 | Connate water only |

---

## 3. Wettability Characterization

### 3.1 Contact Angle Measurements

#### Contact Angle Data by Sample
| Sample ID | Advancing Angle (°) | Receding Angle (°) | Average Angle (°) | Wettability |
|-----------|---------------------|-------------------|-------------------|-------------|
| EW-01-H1  | 28                 | 18                | 23                | Water-wet   |
| EW-02-H2  | 32                 | 22                | 27                | Water-wet   |
| EW-03-H3  | 25                 | 15                | 20                | Water-wet   |
| EW-04-H4  | 35                 | 25                | 30                | Water-wet   |
| EW-05-H5  | 22                 | 12                | 17                | Water-wet   |

#### Wettability Classification
- **Contact Angle < 30°**: Strongly water-wet
- **Contact Angle 30-90°**: Weakly water-wet
- **Contact Angle 90-150°**: Weakly oil-wet
- **Contact Angle > 150°**: Strongly oil-wet

### 3.2 Wettability Index

#### Amott-Harvey Wettability Index
| Sample | Water Index (Iw) | Oil Index (Io) | Amott Index (Ia) | Harvey Index (Ih) |
|--------|------------------|----------------|------------------|-------------------|
| EW-01  | 0.68            | 0.15           | 0.53             | 0.31              |
| EW-02  | 0.72            | 0.12           | 0.60             | 0.35              |
| EW-03  | 0.75            | 0.10           | 0.65             | 0.38              |
| EW-04  | 0.65            | 0.18           | 0.47             | 0.28              |
| EW-05  | 0.78            | 0.08           | 0.70             | 0.41              |

#### Wettability Index Interpretation
- **Ia > 0.3**: Water-wet
- **-0.3 < Ia < 0.3**: Intermediate-wet
- **Ia < -0.3**: Oil-wet

### 3.3 Impact on Relative Permeability

#### Wettability Effects on kr Curves
| Wettability State | krw_max | kro_max | Swc | Sor | Curve Shape |
|-------------------|---------|---------|-----|-----|-------------|
| Strongly Water-wet| 0.35    | 0.85    | 0.22| 0.25| Concave krw |
| Intermediate      | 0.45    | 0.75    | 0.18| 0.28| Linear krw  |
| Strongly Oil-wet  | 0.60    | 0.65    | 0.12| 0.35| Convex krw  |

### 3.4 Aging Effects

#### Core Aging Protocol
1. **Initial State**: Cleaned core saturated with synthetic brine
2. **Oil Saturation**: Flooded with live oil at reservoir conditions
3. **Aging Period**: 21 days at 185°F and 4,200 psi
4. **Wettability Test**: Contact angle and Amott measurements

#### Aging Impact on Properties
| Property | Fresh Core | Aged Core | Change (%) |
|----------|------------|-----------|------------|
| Contact Angle (°) | 15 | 25 | +67 |
| krw_max | 0.42 | 0.35 | -17 |
| kro_max | 0.78 | 0.85 | +9 |
| Swc | 0.25 | 0.22 | -12 |
| Sor | 0.22 | 0.25 | +14 |

---

## 4. Hysteresis Effects

### 4.1 Drainage vs Imbibition

#### Primary Drainage Path
- **Initial State**: 100% water saturation
- **Process**: Oil displaces water under increasing capillary pressure
- **End Point**: Connate water saturation (Swc = 0.22)

#### Imbibition Path
- **Initial State**: Connate water saturation
- **Process**: Water displaces oil under decreasing capillary pressure
- **End Point**: Residual oil saturation (Sor = 0.25)

### 4.2 Hysteresis Modeling Approach

#### Land's Model for Trapped Gas
```
Sgt = Sgmax / (1 + C * Sgmax)
```

Where:
- Sgt = Trapped gas saturation
- Sgmax = Maximum historical gas saturation
- C = Land's coefficient = 2.8

#### Killough's Model Implementation
| Phase | Hysteresis Model | Parameters |
|-------|------------------|------------|
| Water | Carlson | α = 0.15 |
| Oil | Killough | β = 0.25 |
| Gas | Land | C = 2.8 |

### 4.3 Impact on Waterflood Performance

#### Hysteresis Effects on Recovery
| Scenario | Oil Recovery (%) | Water Cut at Breakthrough | Comments |
|----------|------------------|---------------------------|----------|
| No Hysteresis | 52.8 | 0.15 | Optimistic case |
| With Hysteresis | 48.3 | 0.22 | Realistic case |
| Strong Hysteresis | 44.1 | 0.28 | Conservative case |

### 4.4 Residual Saturation Changes

#### Saturation Hysteresis Parameters
| Saturation | Primary Drainage | Imbibition | Secondary Drainage |
|------------|------------------|------------|-------------------|
| Swc | 0.22 | 0.25 | 0.23 |
| Sor | - | 0.25 | 0.20 |
| Sgr | 0.08 | - | 0.12 |

---

## 5. Laboratory Data Quality

### 5.1 Core Preparation Procedures

#### Sample Selection Criteria
1. **Representative Lithology**: Samples from main reservoir intervals
2. **Preservation**: Sealed in aluminum foil immediately after cutting
3. **Storage**: Maintained at 40°F until analysis
4. **Handling**: Minimal exposure to atmosphere during preparation

#### Cleaning Protocol
1. **Solvent Extraction**: Toluene/methanol (87:13) for 48 hours
2. **Drying**: Oven dried at 140°F for 24 hours
3. **Vacuum Saturation**: With synthetic brine for 24 hours
4. **Quality Check**: Porosity and permeability verification

### 5.2 Measurement Uncertainties

#### Experimental Uncertainties
| Measurement | Precision | Accuracy | Repeatability |
|-------------|-----------|----------|---------------|
| Relative Permeability | ±0.02 | ±0.05 | ±0.03 |
| Capillary Pressure | ±0.5 psi | ±1.0 psi | ±0.8 psi |
| Contact Angle | ±2° | ±3° | ±1.5° |
| Saturation | ±0.01 | ±0.02 | ±0.015 |

#### Statistical Analysis
| Parameter | Mean | Std Dev | 95% Confidence |
|-----------|------|---------|----------------|
| Swc | 0.22 | 0.018 | 0.22 ± 0.035 |
| Sor | 0.25 | 0.022 | 0.25 ± 0.043 |
| kro_max | 0.85 | 0.042 | 0.85 ± 0.082 |
| krw_max | 0.35 | 0.025 | 0.35 ± 0.049 |

### 5.3 Representative Sample Selection

#### Reservoir Zonation for SCAL
| Zone | Depth Range (ft) | Porosity Range (%) | K Range (mD) | Samples |
|------|------------------|--------------------|--------------|---------| 
| Upper | 8,200-8,260 | 16-19 | 80-140 | 15 |
| Middle | 8,260-8,320 | 17-20 | 100-180 | 20 |
| Lower | 8,320-8,380 | 15-18 | 60-120 | 12 |

#### Sample Distribution by Rock Type
| Rock Type | Samples | Porosity Avg (%) | K Avg (mD) | Weight (%) |
|-----------|---------|------------------|------------|------------|
| Fine Sandstone | 18 | 16.8 | 95 | 38 |
| Medium Sandstone | 22 | 18.5 | 135 | 47 |
| Coarse Sandstone | 7 | 19.8 | 165 | 15 |

### 5.4 Quality Control Checks

#### Routine QC Procedures
1. **Mass Balance**: ±2% for all displacement tests
2. **Pressure Stability**: ±0.1 psi during steady-state
3. **Temperature Control**: ±1°F throughout testing
4. **Flow Rate Verification**: ±5% of target rate

#### Data Validation Criteria
| Check | Acceptance Criteria | Action if Failed |
|-------|--------------------|-----------------| 
| Material Balance | <2% error | Repeat test |
| Pressure Equilibrium | <0.1 psi/hr drift | Continue monitoring |
| kr Sum Check | kro + krw ≤ 1.0 | Review data |
| Endpoint Verification | Within ±0.02 of target | Re-calibrate |

---

## 6. Correlations and Scaling

### 6.1 Corey Exponents

#### Statistical Analysis of Corey Exponents
| Phase | Mean Exponent | Std Deviation | Range | Distribution |
|-------|---------------|---------------|--------|--------------|
| Oil (water) | 2.8 | 0.3 | 2.2-3.4 | Normal |
| Water | 1.9 | 0.2 | 1.5-2.3 | Normal |
| Oil (gas) | 2.2 | 0.25 | 1.8-2.7 | Normal |
| Gas | 1.6 | 0.18 | 1.2-1.9 | Normal |

#### Corey Exponent Correlations
```matlab
% Porosity correlation for water Corey exponent
nw = 1.45 + 0.025 * phi

% Permeability correlation for oil Corey exponent  
no = 3.2 - 0.003 * log(k)

% Clay content correlation for gas Corey exponent
ng = 1.8 - 0.08 * Vclay
```

### 6.2 Brooks-Corey Parameters

#### Pore Size Distribution Analysis
| Sample | λ (Pore Size Index) | Pd (psi) | Sw50 | Pc50 (psi) |
|--------|---------------------|----------|------|------------|
| EW-01 | 0.45 | 8.2 | 0.48 | 15.6 |
| EW-02 | 0.42 | 10.5 | 0.45 | 19.8 |
| EW-03 | 0.48 | 6.8 | 0.52 | 12.9 |
| EW-04 | 0.44 | 9.1 | 0.47 | 17.2 |
| EW-05 | 0.51 | 5.9 | 0.55 | 11.4 |

#### Parameter Correlations
```matlab
% Permeability-Porosity correlation for displacement pressure
Pd = 25.6 * (k/phi)^(-0.32)

% Pore size index correlation with sorting
lambda = 0.65 - 0.08 * So (sorting coefficient)
```

### 6.3 Leverett J-Function

#### J-Function Normalization
```matlab
J(Sw) = (Pc * sqrt(k/phi)) / (sigma * cos(theta))
```

#### Universal J-Function Parameters
| Parameter | Value | Units | Correlation |
|-----------|-------|--------|-------------|
| J at Swc | 1.85 | - | J_swc = 2.1 - 0.15*phi |
| J Slope | -0.67 | - | Slope = -0.8 + 0.05*lambda |
| J at Sw=1 | 0.05 | - | Constant |

#### Rock Type J-Function Curves
```matlab
% Rock Type 1 (Fine Sandstone)
J1 = 1.95 * (Sw_eff)^(-0.72)

% Rock Type 2 (Medium Sandstone)  
J2 = 1.75 * (Sw_eff)^(-0.62)

% Rock Type 3 (Coarse Sandstone)
J3 = 1.55 * (Sw_eff)^(-0.58)
```

### 6.4 Upscaling Methodology

#### Relative Permeability Upscaling
1. **Arithmetic Average**: For high flow rates
2. **Harmonic Average**: For low flow rates
3. **Power Law**: For intermediate cases

```matlab
kr_up = (sum(fi * kri^n))^(1/n)
```

Where:
- fi = facies fraction
- kri = facies relative permeability
- n = flow regime parameter (0.33 for viscous flow)

#### Capillary Pressure Upscaling

##### Leverett Scaling
```matlab
Pc_up = Pc_ref * sqrt(phi_ref/phi_up) * sqrt(k_up/k_ref)
```

##### Height Function Method
```matlab
h(Sw) = integral(1/(krw/mu_w + kro/mu_o) * dSw/dPc)
```

#### Upscaling Parameters for MRST
| Property | Method | Parameters | Validation |
|----------|---------|------------|------------|
| kr Curves | Power Law | n = 0.33 | Fine-scale match |
| Pc Curves | Leverett | J-function | Saturation profile |
| Endpoints | Arithmetic | Volume weighted | Material balance |

---

## MRST Implementation Parameters

### Relative Permeability Tables for MRST

#### Oil-Water System
```matlab
% SWOF table for MRST
swof = [
    0.22  0     0.85  0     % Swc
    0.30  0.005 0.75  0
    0.40  0.018 0.62  0
    0.50  0.042 0.48  0
    0.60  0.078 0.35  0
    0.70  0.125 0.22  0
    0.75  0.160 0.15  0
    0.78  0.190 0.08  0
    1.00  0.35  0     0     % Sor
];
```

#### Gas-Oil System  
```matlab
% SGOF table for MRST
sgof = [
    0     0     0.82  0     % No gas
    0.05  0     0.78  0     % Sgc
    0.10  0.005 0.72  0
    0.20  0.018 0.58  0
    0.30  0.042 0.45  0
    0.40  0.078 0.32  0
    0.50  0.125 0.20  0
    0.60  0.190 0.12  0
    0.70  0.285 0.05  0
    0.87  0.75  0     0     % Sorg
];
```

#### Stone II 3-Phase Model Parameters
```matlab
% Stone II parameters for MRST
stone2_params = struct(...
    'krw_max', 0.35, ...
    'kro_max', 0.85, ...
    'krg_max', 0.75, ...
    'swc', 0.22, ...
    'sorw', 0.25, ...
    'sorg', 0.18, ...
    'sgc', 0.05 ...
);
```

### Capillary Pressure Tables

#### Oil-Water Capillary Pressure
```matlab
% SWPC table for MRST (psi)
swpc = [
    0.22  85.2   % Swc
    0.30  42.6
    0.40  25.8
    0.50  17.2
    0.60  12.4
    0.70  9.1
    0.80  6.8
    0.90  4.2
    1.00  0      % Free water level
];
```

#### Gas-Oil Capillary Pressure
```matlab
% SGPC table for MRST (psi)
sgpc = [
    0     0      % No gas
    0.05  0.5    % Sgc
    0.10  1.2
    0.20  2.8
    0.30  4.9
    0.40  7.5
    0.50  11.2
    0.60  16.8
    0.70  25.4
    0.87  45.2   % Maximum Sg
];
```

---

## Conclusions and Recommendations

### Key Findings
1. **Wettability**: Eagle West Field exhibits strong water-wet characteristics (contact angle ~25°)
2. **Relative Permeability**: Favorable kr curves for waterflooding with krw_max = 0.35
3. **Capillary Pressure**: Moderate transition zone (45 ft) suitable for horizontal well placement
4. **Hysteresis**: Significant impact on gas mobility requiring hysteresis modeling

### MRST Simulation Recommendations
1. **Use Stone II Model**: For 3-phase relative permeability calculations
2. **Include Hysteresis**: Implement Land's model for trapped gas
3. **Scale J-Function**: Apply Leverett scaling for different rock types
4. **Validate Endpoints**: Cross-check with core analysis and log data

### Data Quality Assessment
- **Confidence Level**: High (>95% for endpoint saturations)
- **Representative Coverage**: Good spatial distribution across reservoir
- **Measurement Precision**: Meets industry standards (±0.02 for kr)
- **Validation Status**: Cross-validated with wireline log interpretations

### Future Work
1. **Enhanced Oil Recovery**: Investigate surfactant effects on wettability
2. **CO2 Flooding**: Acquire CO2-oil relative permeability data  
3. **Temperature Effects**: Study kr variation with temperature
4. **Fracture-Matrix**: Characterize dual-porosity SCAL properties

---

## References

1. Honarpour, M., Koederitz, L., & Harvey, A. H. (1986). *Relative Permeability of Petroleum Reservoirs*. CRC Press.
2. Anderson, W. G. (1987). "Wettability Literature Survey." *Journal of Petroleum Technology*, 39(10), 1125-1144.
3. Brooks, R. H., & Corey, A. T. (1964). "Hydraulic Properties of Porous Media." *Hydrology Papers*, Colorado State University.
4. Stone, H. L. (1973). "Estimation of Three-Phase Relative Permeability." *Journal of Canadian Petroleum Technology*, 12(4), 53-61.
5. Land, C. S. (1968). "Calculation of Imbibition Relative Permeability." *Society of Petroleum Engineers Journal*, 8(2), 149-156.

---

**Document Status**: Final Draft  
**Last Updated**: 2025-01-25  
**Next Review**: 2025-07-25  
**Approved By**: Reservoir Engineering Team