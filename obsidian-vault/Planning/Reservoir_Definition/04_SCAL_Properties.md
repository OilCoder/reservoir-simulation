# Special Core Analysis (SCAL) Properties

## Document Information
- **Date**: 2025-01-25
- **Document**: 04_SCAL_Properties.md
- **Purpose**: Comprehensive SCAL characterization for 3-phase relative permeability modeling

## Executive Summary

This document presents Special Core Analysis (SCAL) properties providing essential input parameters for 3-phase relative permeability modeling in reservoir simulation. The data encompasses relative permeability curves, capillary pressure relationships, wettability characterization, and hysteresis effects for multiple lithologies including sandstone, shale, and limestone formations.

---

## 1. 3-Phase Relative Permeability

### 1.1 Oil-Water Relative Permeability Curves

#### Core Sample Data Summary - Multiple Lithologies
| Sample ID | Depth (ft) | Porosity (%) | Permeability (mD) | Rock Type | TOC (%) |
|-----------|------------|--------------|-------------------|-----------|---------|
| SS-01     | 8,245      | 18.5         | 125               | Sandstone | - |
| SS-02     | 8,267      | 16.8         | 89                | Sandstone | - |
| SH-01     | 8,291      | 8.2          | 0.085             | Shale     | 3.2 |
| SH-02     | 8,315      | 6.8          | 0.062             | Shale     | 4.1 |
| LS-01     | 8,338      | 12.4         | 15.8              | Limestone | - |
| LS-02     | 8,362      | 14.2         | 22.6              | Limestone | - |

#### Oil-Water Relative Permeability Parameters by Lithology

##### Sandstone Parameters
| Parameter | Symbol | Value | Units | Source |
|-----------|---------|-------|-------|---------|
| Connate Water Saturation | Swc | 0.22 | fraction | Laboratory |
| Residual Oil Saturation (Water) | Sorw | 0.25 | fraction | Laboratory |
| Oil Relative Permeability at Swc | kro_max | 0.85 | fraction | Laboratory |
| Water Relative Permeability at Sor | krw_max | 0.35 | fraction | Laboratory |
| Oil Corey Exponent | no | 2.8 | - | Curve Fit |
| Water Corey Exponent | nw | 1.9 | - | Curve Fit |

##### Shale Parameters
| Parameter | Symbol | Value | Units | Source |
|-----------|---------|-------|-------|---------|
| Connate Water Saturation | Swc | 0.45 | fraction | Laboratory |
| Residual Oil Saturation (Water) | Sorw | 0.35 | fraction | Laboratory |
| Oil Relative Permeability at Swc | kro_max | 0.65 | fraction | Laboratory |
| Water Relative Permeability at Sor | krw_max | 0.15 | fraction | Laboratory |
| Oil Corey Exponent | no | 1.8 | - | Curve Fit |
| Water Corey Exponent | nw | 3.2 | - | Curve Fit |

##### Limestone Parameters
| Parameter | Symbol | Value | Units | Source |
|-----------|---------|-------|-------|---------|
| Connate Water Saturation | Swc | 0.18 | fraction | Laboratory |
| Residual Oil Saturation (Water) | Sorw | 0.28 | fraction | Laboratory |
| Oil Relative Permeability at Swc | kro_max | 0.92 | fraction | Laboratory |
| Water Relative Permeability at Sor | krw_max | 0.42 | fraction | Laboratory |
| Oil Corey Exponent | no | 3.2 | - | Curve Fit |
| Water Corey Exponent | nw | 2.1 | - | Curve Fit |

#### Corey Model Correlations (Oil-Water)

**Oil Phase Correlation:**
$$k_{ro} = k_{ro}^* \left(\frac{S_o - S_{or}}{1 - S_{wc} - S_{or}}\right)^{n_o}$$

**Water Phase Correlation:**
$$k_{rw} = k_{rw}^* \left(\frac{S_w - S_{wc}}{1 - S_{wc} - S_{or}}\right)^{n_w}$$

### 1.2 Gas-Oil Relative Permeability Curves

#### Gas-Oil Relative Permeability Parameters by Lithology

##### Sandstone Parameters
| Parameter | Symbol | Value | Units | Source |
|-----------|---------|-------|-------|---------|
| Critical Gas Saturation | Sgc | 0.05 | fraction | Laboratory |
| Residual Oil Saturation (Gas) | Sorg | 0.18 | fraction | Laboratory |
| Gas Relative Permeability at Sor | krg_max | 0.75 | fraction | Laboratory |
| Oil Relative Permeability at Sgc | krog_max | 0.82 | fraction | Laboratory |
| Gas Corey Exponent | ng | 1.6 | - | Curve Fit |
| Oil Corey Exponent (Gas) | nog | 2.2 | - | Curve Fit |

##### Shale Parameters
| Parameter | Symbol | Value | Units | Source |
|-----------|---------|-------|-------|---------|
| Critical Gas Saturation | Sgc | 0.08 | fraction | Laboratory |
| Residual Oil Saturation (Gas) | Sorg | 0.25 | fraction | Laboratory |
| Gas Relative Permeability at Sor | krg_max | 0.45 | fraction | Laboratory |
| Oil Relative Permeability at Sgc | krog_max | 0.58 | fraction | Laboratory |
| Gas Corey Exponent | ng | 1.2 | - | Curve Fit |
| Oil Corey Exponent (Gas) | nog | 1.8 | - | Curve Fit |

##### Limestone Parameters
| Parameter | Symbol | Value | Units | Source |
|-----------|---------|-------|-------|---------|
| Critical Gas Saturation | Sgc | 0.04 | fraction | Laboratory |
| Residual Oil Saturation (Gas) | Sorg | 0.15 | fraction | Laboratory |
| Gas Relative Permeability at Sor | krg_max | 0.85 | fraction | Laboratory |
| Oil Relative Permeability at Sgc | krog_max | 0.88 | fraction | Laboratory |
| Gas Corey Exponent | ng | 1.8 | - | Curve Fit |
| Oil Corey Exponent (Gas) | nog | 2.8 | - | Curve Fit |

#### Corey Model Correlations (Gas-Oil)

**Gas Phase Correlation:**
$$k_{rg} = k_{rg}^* \left(\frac{S_g - S_{gc}}{1 - S_{wc} - S_{org} - S_{gc}}\right)^{n_g}$$

**Oil Phase Correlation:**
$$k_{rog} = k_{rog}^* \left(\frac{S_o - S_{org}}{1 - S_{wc} - S_{org} - S_{gc}}\right)^{n_{og}}$$

### 1.3 3-Phase Relative Permeability Model

#### Stone's Second Model (Stone II)
The reservoir utilizes Stone's Second Model for 3-phase relative permeability calculations:

**Stone II Correlation:**
$$k_{ro} = k_{ro}^* \left[\left(\frac{S_o - S_{or}}{1 - S_{wc} - S_{or}}\right)^2 \frac{k_{rw}}{k_{rw}^*} \frac{k_{rg}}{k_{rg}^*}\right]$$

Where:
- $k_{ro}$ = 3-phase oil relative permeability
- $k_{ro}^*$ = oil relative permeability at connate water saturation
- $k_{rw}$ = water relative permeability
- $k_{rg}$ = gas relative permeability
- $k_{rw}^*$ = water relative permeability at residual oil saturation
- $k_{rg}^*$ = gas relative permeability at residual oil saturation

#### Saturation Endpoints Summary by Lithology

##### Sandstone Endpoints
| Parameter | Value | Definition |
|-----------|-------|------------|
| Swc | 0.22 | Connate water saturation |
| Sorw | 0.25 | Residual oil saturation to water |
| Sorg | 0.18 | Residual oil saturation to gas |
| Sgr | 0.08 | Residual gas saturation |
| Sgc | 0.05 | Critical gas saturation |

##### Shale Endpoints
| Parameter | Value | Definition |
|-----------|-------|------------|
| Swc | 0.45 | Connate water saturation |
| Sorw | 0.35 | Residual oil saturation to water |
| Sorg | 0.25 | Residual oil saturation to gas |
| Sgr | 0.12 | Residual gas saturation |
| Sgc | 0.08 | Critical gas saturation |

##### Limestone Endpoints
| Parameter | Value | Definition |
|-----------|-------|------------|
| Swc | 0.18 | Connate water saturation |
| Sorw | 0.28 | Residual oil saturation to water |
| Sorg | 0.15 | Residual oil saturation to gas |
| Sgr | 0.06 | Residual gas saturation |
| Sgc | 0.04 | Critical gas saturation |

---

## 2. Capillary Pressure

### 2.1 Primary Drainage Curves

#### Mercury Injection Capillary Pressure (MICP) Data by Lithology

##### Sandstone MICP Data
| Sample | Pore Throat Radius (μm) | Pc_entry (psi) | Pc_50 (psi) | Sorting Coefficient |
|--------|-------------------------|----------------|-------------|-------------------|
| SS-01  | 12.5                   | 8.2            | 15.6        | 2.1               |
| SS-02  | 9.8                    | 10.5           | 19.8        | 2.4               |
| SS-03  | 15.2                   | 6.8            | 12.9        | 1.9               |

##### Shale MICP Data
| Sample | Pore Throat Radius (μm) | Pc_entry (psi) | Pc_50 (psi) | Sorting Coefficient |
|--------|-------------------------|----------------|-------------|-------------------|
| SH-01  | 0.15                   | 285.4          | 542.8       | 4.8               |
| SH-02  | 0.12                   | 358.2          | 688.5       | 5.2               |
| SH-03  | 0.18                   | 245.6          | 465.3       | 4.6               |

##### Limestone MICP Data
| Sample | Pore Throat Radius (μm) | Pc_entry (psi) | Pc_50 (psi) | Sorting Coefficient |
|--------|-------------------------|----------------|-------------|-------------------|
| LS-01  | 3.8                    | 22.5           | 48.6        | 3.2               |
| LS-02  | 4.2                    | 18.8           | 42.1        | 2.9               |
| LS-03  | 2.9                    | 28.6           | 56.8        | 3.6               |

#### Brooks-Corey Capillary Pressure Model

**Primary Drainage Correlation:**
$$P_c = P_d \left(\frac{S_w - S_{wc}}{1 - S_{wc}}\right)^{-1/\lambda}$$

Where:
- $S_{w,eff} = \frac{S_w - S_{wc}}{1 - S_{wc}}$ = effective water saturation
- $P_d$ = displacement pressure
- $\lambda$ = pore size distribution index

#### Brooks-Corey Parameters by Lithology
| Rock Type | Displacement Pressure Pd (psi) | Pore Size Index λ | R² |
|-----------|--------------------------------|-------------------|-----|
| Sandstone | 8.5                           | 0.45              | 0.96|
| Shale     | 295.8                         | 0.18              | 0.94|
| Limestone | 23.3                          | 0.62              | 0.97|

### 2.2 Imbibition Curves

#### Imbibition Capillary Pressure Parameters by Lithology

##### Sandstone Imbibition Parameters
| Parameter | Primary Drainage | Imbibition | Hysteresis Factor |
|-----------|------------------|------------|-------------------|
| Displacement Pressure (psi) | 8.5 | 12.8 | 1.5 |
| Pore Size Index | 0.45 | 0.38 | - |
| Maximum Pc (psi) | 85.2 | 72.6 | 0.85 |

##### Shale Imbibition Parameters
| Parameter | Primary Drainage | Imbibition | Hysteresis Factor |
|-----------|------------------|------------|-------------------|
| Displacement Pressure (psi) | 295.8 | 445.2 | 1.5 |
| Pore Size Index | 0.18 | 0.15 | - |
| Maximum Pc (psi) | 2850.6 | 2425.5 | 0.85 |

##### Limestone Imbibition Parameters
| Parameter | Primary Drainage | Imbibition | Hysteresis Factor |
|-----------|------------------|------------|-------------------|
| Displacement Pressure (psi) | 23.3 | 35.0 | 1.5 |
| Pore Size Index | 0.62 | 0.52 | - |
| Maximum Pc (psi) | 185.4 | 157.6 | 0.85 |

### 2.3 Height Above Free Water Level

#### Leverett J-Function Correlation

**J-Function Definition:**
$$J(S_w) = \frac{P_c}{\sigma \cos\theta} \sqrt{\frac{\phi}{k}}$$

Where:
- $J(S_w)$ = dimensionless J-function
- $P_c$ = capillary pressure
- $\sigma$ = interfacial tension
- $\theta$ = contact angle
- $\phi$ = porosity
- $k$ = permeability

#### J-Function Parameters by Lithology

##### Sandstone J-Function Parameters
| Parameter | Value | Units |
|-----------|-------|-------|
| Surface Tension (σ) | 28.5 | dyne/cm |
| Contact Angle (θ) | 25° | degrees |
| J-Function at Swc | 1.85 | - |
| J-Function Coefficient | 0.67 | - |

##### Shale J-Function Parameters
| Parameter | Value | Units |
|-----------|-------|-------|
| Surface Tension (σ) | 28.5 | dyne/cm |
| Contact Angle (θ) | 45° | degrees |
| J-Function at Swc | 4.25 | - |
| J-Function Coefficient | 1.85 | - |

##### Limestone J-Function Parameters
| Parameter | Value | Units |
|-----------|-------|-------|
| Surface Tension (σ) | 28.5 | dyne/cm |
| Contact Angle (θ) | 18° | degrees |
| J-Function at Swc | 2.15 | - |
| J-Function Coefficient | 0.85 | - |

#### Transition Zone Modeling by Lithology

##### Sandstone Transition Zone
| Zone | HAFWL Range (ft) | Sw Range | Characteristics |
|------|------------------|----------|----------------|
| Free Water Level | 0 | 1.00 | 100% water saturation |
| Transition Zone | 0-45 | 0.22-0.85 | Mixed saturation |
| Oil Zone | >45 | 0.22 | Connate water only |

##### Shale Transition Zone
| Zone | HAFWL Range (ft) | Sw Range | Characteristics |
|------|------------------|----------|----------------|
| Free Water Level | 0 | 1.00 | 100% water saturation |
| Transition Zone | 0-125 | 0.45-0.85 | Mixed saturation |
| Oil Zone | >125 | 0.45 | Connate water only |

##### Limestone Transition Zone
| Zone | HAFWL Range (ft) | Sw Range | Characteristics |
|------|------------------|----------|----------------|
| Free Water Level | 0 | 1.00 | 100% water saturation |
| Transition Zone | 0-65 | 0.18-0.85 | Mixed saturation |
| Oil Zone | >65 | 0.18 | Connate water only |

---

## 3. Wettability Characterization

### 3.1 Contact Angle Measurements

#### Contact Angle Data by Lithology

##### Sandstone Contact Angle Data
| Sample ID | Advancing Angle (°) | Receding Angle (°) | Average Angle (°) | Wettability |
|-----------|---------------------|-------------------|-------------------|-------------|
| SS-01     | 28                 | 18                | 23                | Water-wet   |
| SS-02     | 32                 | 22                | 27                | Water-wet   |
| SS-03     | 25                 | 15                | 20                | Water-wet   |

##### Shale Contact Angle Data
| Sample ID | Advancing Angle (°) | Receding Angle (°) | Average Angle (°) | Wettability |
|-----------|---------------------|-------------------|-------------------|-------------|
| SH-01     | 65                 | 48                | 57                | Intermediate |
| SH-02     | 72                 | 55                | 64                | Intermediate |
| SH-03     | 58                 | 42                | 50                | Intermediate |

##### Limestone Contact Angle Data
| Sample ID | Advancing Angle (°) | Receding Angle (°) | Average Angle (°) | Wettability |
|-----------|---------------------|-------------------|-------------------|-------------|
| LS-01     | 15                 | 8                 | 12                | Water-wet   |
| LS-02     | 18                 | 12                | 15                | Water-wet   |
| LS-03     | 22                 | 14                | 18                | Water-wet   |

#### Wettability Classification
- **Contact Angle < 30°**: Strongly water-wet
- **Contact Angle 30-90°**: Weakly water-wet
- **Contact Angle 90-150°**: Weakly oil-wet
- **Contact Angle > 150°**: Strongly oil-wet

### 3.2 Wettability Index

**Wettability Index Mathematical Definition:**
$$I_w = \frac{A_1 - A_2}{A_1 + A_2}$$

Where:
- $I_w$ = wettability index  
- $A_1$ = area under water imbibition curve
- $A_2$ = area under oil imbibition curve

#### Amott-Harvey Wettability Index by Lithology

##### Sandstone Wettability Index
| Sample | Water Index (Iw) | Oil Index (Io) | Amott Index (Ia) | Harvey Index (Ih) |
|--------|------------------|----------------|------------------|-------------------|
| SS-01  | 0.68            | 0.15           | 0.53             | 0.31              |
| SS-02  | 0.72            | 0.12           | 0.60             | 0.35              |
| SS-03  | 0.75            | 0.10           | 0.65             | 0.38              |

##### Shale Wettability Index
| Sample | Water Index (Iw) | Oil Index (Io) | Amott Index (Ia) | Harvey Index (Ih) |
|--------|------------------|----------------|------------------|-------------------|
| SH-01  | 0.35            | 0.42           | -0.07            | -0.09             |
| SH-02  | 0.28            | 0.48           | -0.20            | -0.26             |
| SH-03  | 0.40            | 0.38           | 0.02             | 0.03              |

##### Limestone Wettability Index
| Sample | Water Index (Iw) | Oil Index (Io) | Amott Index (Ia) | Harvey Index (Ih) |
|--------|------------------|----------------|------------------|-------------------|
| LS-01  | 0.82            | 0.08           | 0.74             | 0.45              |
| LS-02  | 0.85            | 0.06           | 0.79             | 0.48              |
| LS-03  | 0.78            | 0.12           | 0.66             | 0.42              |

#### Wettability Index Interpretation
- **Ia > 0.3**: Water-wet
- **-0.3 < Ia < 0.3**: Intermediate-wet
- **Ia < -0.3**: Oil-wet

### 3.3 Impact on Relative Permeability

#### Wettability Effects on kr Curves by Lithology

##### Sandstone Wettability Effects
| Wettability State | krw_max | kro_max | Swc | Sor | Curve Shape |
|-------------------|---------|---------|-----|-----|-------------|
| Water-wet         | 0.35    | 0.85    | 0.22| 0.25| Concave krw |

##### Shale Wettability Effects
| Wettability State | krw_max | kro_max | Swc | Sor | Curve Shape |
|-------------------|---------|---------|-----|-----|-------------|
| Intermediate      | 0.15    | 0.65    | 0.45| 0.35| Linear krw  |

##### Limestone Wettability Effects
| Wettability State | krw_max | kro_max | Swc | Sor | Curve Shape |
|-------------------|---------|---------|-----|-----|-------------|
| Strongly Water-wet| 0.42    | 0.92    | 0.18| 0.28| Concave krw |

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

**Land's Trapping Model:**
$$S_{gt} = \frac{S_{g,max}}{1 + C \cdot S_{g,max}}$$

Where:
- $S_{gt}$ = trapped gas saturation
- $S_{g,max}$ = maximum historical gas saturation
- $C$ = Land's coefficient = 2.8

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

**Porosity correlation for water Corey exponent:**
$$n_w = 1.45 + 0.025 \times \phi$$

**Permeability correlation for oil Corey exponent:**
$$n_o = 3.2 - 0.003 \times \log(k)$$

**Clay content correlation for gas Corey exponent:**
$$n_g = 1.8 - 0.08 \times V_{clay}$$

### 6.2 Brooks-Corey Parameters

#### Pore Size Distribution Analysis
| Sample | λ (Pore Size Index) | Pd (psi) | Sw50 | Pc50 (psi) |
|--------|---------------------|----------|------|------------|
| SS-01 | 0.45 | 8.2 | 0.48 | 15.6 |
| SS-02 | 0.42 | 10.5 | 0.45 | 19.8 |
| SH-01 | 0.18 | 285.4 | 0.65 | 542.8 |
| LS-01 | 0.62 | 22.5 | 0.42 | 48.6 |
| LS-02 | 0.58 | 18.8 | 0.45 | 42.1 |

#### Parameter Correlations

**Permeability-Porosity correlation for displacement pressure:**
$$P_d = 25.6 \times \left(\frac{k}{\phi}\right)^{-0.32}$$

**Pore size index correlation with sorting:**
$$\lambda = 0.65 - 0.08 \times S_o$$

Where $S_o$ is the sorting coefficient

### 6.3 Leverett J-Function

#### J-Function Normalization

**J-Function Correlation:**
$$J(S_w) = \frac{P_c \sqrt{k/\phi}}{\sigma \cos\theta}$$

#### Universal J-Function Parameters
| Parameter | Value | Units | Correlation |
|-----------|-------|--------|-------------|
| J at Swc | 1.85 | - | J_swc = 2.1 - 0.15×φ |
| J Slope | -0.67 | - | Slope = -0.8 + 0.05×λ |
| J at Sw=1 | 0.05 | - | Constant |

#### Rock Type J-Function Curves

**Sandstone (Fine):**
$$J_1 = 1.95 \times (S_{w,eff})^{-0.72}$$

**Sandstone (Medium):**
$$J_2 = 1.75 \times (S_{w,eff})^{-0.62}$$

**Limestone:**
$$J_3 = 1.55 \times (S_{w,eff})^{-0.58}$$

**Shale:**
$$J_4 = 3.25 \times (S_{w,eff})^{-0.85}$$

### 6.4 Upscaling Methodology

#### Relative Permeability Upscaling
1. **Arithmetic Average**: For high flow rates
2. **Harmonic Average**: For low flow rates
3. **Power Law**: For intermediate cases

**Power Law Upscaling:**
$$k_{r,up} = \left(\sum_{i} f_i \times k_{ri}^n\right)^{1/n}$$

Where:
- $f_i$ = facies fraction
- $k_{ri}$ = facies relative permeability
- $n$ = flow regime parameter (0.33 for viscous flow)

#### Capillary Pressure Upscaling

##### Leverett Scaling

**Leverett Scaling Correlation:**
$$P_{c,up} = P_{c,ref} \times \sqrt{\frac{\phi_{ref}}{\phi_{up}}} \times \sqrt{\frac{k_{up}}{k_{ref}}}$$

##### Height Function Method

**Height Function Integration:**
$$h(S_w) = \int \left[\frac{1}{\frac{k_{rw}}{\mu_w} + \frac{k_{ro}}{\mu_o}} \times \frac{dS_w}{dP_c}\right] dS_w$$

#### Upscaling Parameters for Reservoir Simulation
| Property | Method | Parameters | Validation |
|----------|---------|------------|------------|
| kr Curves | Power Law | n = 0.33 | Fine-scale match |
| Pc Curves | Leverett | J-function | Saturation profile |
| Endpoints | Arithmetic | Volume weighted | Material balance |

---

## Conclusions and Recommendations

### Key Findings by Lithology

#### Sandstone Characteristics
1. **Wettability**: Strong water-wet characteristics (contact angle ~25°)
2. **Relative Permeability**: Favorable kr curves for waterflooding with krw_max = 0.35
3. **Capillary Pressure**: Moderate transition zone (45 ft) suitable for horizontal well placement
4. **Flow Properties**: High permeability with good oil mobility

#### Shale Characteristics
1. **Wettability**: Intermediate wettability (contact angle ~57°)
2. **Relative Permeability**: Limited water mobility with krw_max = 0.15
3. **Capillary Pressure**: Extended transition zone (125 ft) with high entry pressures
4. **Flow Properties**: Ultra-low permeability requiring hydraulic fracturing

#### Limestone Characteristics
1. **Wettability**: Strongly water-wet characteristics (contact angle ~15°)
2. **Relative Permeability**: Excellent kr curves for waterflooding with krw_max = 0.42
3. **Capillary Pressure**: Moderate transition zone (65 ft) with favorable drainage
4. **Flow Properties**: Moderate permeability with fracture-enhanced flow

### Reservoir Simulation Recommendations
1. **Use Stone II Model**: For 3-phase relative permeability calculations across all lithologies
2. **Include Hysteresis**: Implement Land's model for trapped gas saturation
3. **Scale J-Function**: Apply Leverett scaling for different rock types
4. **Validate Endpoints**: Cross-check with core analysis and log data
5. **Multi-Lithology Modeling**: Use separate SCAL functions for each rock type

### Data Quality Assessment
- **Confidence Level**: High (>95% for endpoint saturations)
- **Representative Coverage**: Good spatial distribution across multiple lithologies
- **Measurement Precision**: Meets industry standards (±0.02 for kr)
- **Validation Status**: Cross-validated with wireline log interpretations
- **Lithology Coverage**: Comprehensive SCAL data for sandstone, shale, and limestone

### Future Work
1. **Enhanced Oil Recovery**: Investigate surfactant effects on wettability for each lithology
2. **CO2 Flooding**: Acquire CO2-oil relative permeability data for all rock types
3. **Temperature Effects**: Study kr variation with temperature across lithologies
4. **Fracture-Matrix**: Characterize dual-porosity SCAL properties for naturally fractured zones
5. **Micro-Scale Analysis**: Digital rock physics for pore-scale flow modeling

---

## References

1. Honarpour, M., Koederitz, L., & Harvey, A. H. (1986). *Relative Permeability of Petroleum Reservoirs*. CRC Press.
2. Anderson, W. G. (1987). "Wettability Literature Survey." *Journal of Petroleum Technology*, 39(10), 1125-1144.
3. Brooks, R. H., & Corey, A. T. (1964). "Hydraulic Properties of Porous Media." *Hydrology Papers*, Colorado State University.
4. Stone, H. L. (1973). "Estimation of Three-Phase Relative Permeability." *Journal of Canadian Petroleum Technology*, 12(4), 53-61.
5. Land, C. S. (1968). "Calculation of Imbibition Relative Permeability." *Society of Petroleum Engineers Journal*, 8(2), 149-156.

---

**Document Status**: Technical SCAL Report  
**Last Updated**: 2025-01-25  
**Next Review**: 2025-07-25  
**Approved By**: SCAL Laboratory Team