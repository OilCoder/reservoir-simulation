# Rock Properties - Eagle West Field

## Overview

This document defines the rock properties for the Eagle West Field reservoir simulation model, including petrophysical characteristics by lithology, rock typing, and parameters required for 3-phase oil/gas/water flow simulation.

## 1. Lithology Classification and Properties

### 1.1 Primary Lithologies

The Eagle West Field reservoir contains three distinct lithologies with varying petrophysical properties:

| Lithology | Depth Range (ft) | Thickness Range (ft) | Flow Characteristics |
|-----------|------------------|----------------------|---------------------|
| Sandstone | 8,200 - 8,850 | 35-120 | High porosity, high permeability |
| Shale | Interbedded | 2-15 | Low porosity, flow barriers |
| Limestone | 8,300 - 8,500 | 10-45 | Moderate porosity, variable permeability |

### 1.2 Sandstone Properties

#### Porosity Characteristics
| Property | High Quality | Medium Quality | Low Quality |
|----------|-------------|----------------|-------------|
| Porosity Range (%) | 22-32 | 15-22 | 8-15 |
| Mean Porosity (%) | 27 | 18.5 | 11.5 |
| Initial Porosity Conditions | Water-saturated, ambient conditions | Water-saturated, ambient conditions | Water-saturated, ambient conditions |

#### Permeability Characteristics
| Property | High Quality | Medium Quality | Low Quality |
|----------|-------------|----------------|-------------|
| Horizontal Permeability (mD) | 200-850 | 50-200 | 5-50 |
| Vertical Permeability (mD) | 100-425 | 25-100 | 2.5-25 |
| Kv/Kh Ratio | 0.5 | 0.5 | 0.5 |

#### Grain Size and Texture
| Property | Fine Sandstone | Medium Sandstone | Coarse Sandstone |
|----------|---------------|------------------|------------------|
| Mean Grain Size (mm) | 0.125-0.25 | 0.25-0.5 | 0.5-1.0 |
| Sorting Coefficient | 1.2-1.8 | 1.1-1.6 | 1.3-2.0 |
| Cementation Factor (m) | 1.8-2.2 | 1.9-2.3 | 2.0-2.4 |

### 1.3 Shale Properties

#### Porosity and Permeability
| Property | Value Range | Mean Value |
|----------|-------------|------------|
| Porosity (%) | 2-8 | 5 |
| Horizontal Permeability (mD) | 0.001-0.1 | 0.01 |
| Vertical Permeability (mD) | 0.0001-0.01 | 0.001 |
| Kv/Kh Ratio | 0.1 | 0.1 |

#### Clay Mineral Composition
| Clay Type | Content (%) | Characteristics |
|-----------|-------------|----------------|
| Illite | 40-60 | Stable, low swelling |
| Kaolinite | 25-40 | Non-swelling, stable |
| Chlorite | 10-20 | Stable, acid-sensitive |
| Smectite | 5-15 | Swelling clay, water-sensitive |

### 1.4 Limestone Properties

#### Porosity Characteristics
| Property | Vuggy Limestone | Crystalline Limestone | Tight Limestone |
|----------|----------------|----------------------|-----------------|
| Porosity Range (%) | 15-28 | 8-18 | 3-8 |
| Mean Porosity (%) | 21.5 | 13 | 5.5 |
| Pore Type | Primary/secondary vugs | Intercrystalline | Microporosity |

#### Permeability Characteristics
| Property | Vuggy Limestone | Crystalline Limestone | Tight Limestone |
|----------|----------------|----------------------|-----------------|
| Horizontal Permeability (mD) | 50-300 | 10-75 | 0.5-10 |
| Vertical Permeability (mD) | 25-150 | 5-37.5 | 0.25-5 |
| Kv/Kh Ratio | 0.5 | 0.5 | 0.5 |

## 2. Rock Types and Flow Characteristics

### 2.1 Rock Type Classification

Six distinct rock types have been identified based on petrophysical properties and flow characteristics:

#### Rock Type 1 - High Permeability Sandstone
| Property | Value/Range |
|----------|-------------|
| Lithology | Clean, well-sorted sandstone |
| Porosity Range (%) | 25-32 |
| Horizontal Permeability (mD) | 300-850 |
| Vertical Permeability (mD) | 150-425 |
| Reservoir Quality Index (μm) | > 3.5 |
| Flow Zone Indicator (μm) | 8-15 |

#### Rock Type 2 - Medium Permeability Sandstone
| Property | Value/Range |
|----------|-------------|
| Lithology | Moderately sorted sandstone |
| Porosity Range (%) | 20-25 |
| Horizontal Permeability (mD) | 100-300 |
| Vertical Permeability (mD) | 50-150 |
| Reservoir Quality Index (μm) | 2.5-3.5 |
| Flow Zone Indicator (μm) | 5-8 |

#### Rock Type 3 - Low Permeability Sandstone
| Property | Value/Range |
|----------|-------------|
| Lithology | Cemented, fine-grained sandstone |
| Porosity Range (%) | 15-20 |
| Horizontal Permeability (mD) | 25-100 |
| Vertical Permeability (mD) | 12.5-50 |
| Reservoir Quality Index (μm) | 1.5-2.5 |
| Flow Zone Indicator (μm) | 3-5 |

#### Rock Type 4 - Tight Sandstone
| Property | Value/Range |
|----------|-------------|
| Lithology | Heavily cemented, argillaceous sandstone |
| Porosity Range (%) | 10-15 |
| Horizontal Permeability (mD) | 5-25 |
| Vertical Permeability (mD) | 2.5-12.5 |
| Reservoir Quality Index (μm) | 0.8-1.5 |
| Flow Zone Indicator (μm) | 1.5-3 |

#### Rock Type 5 - Vuggy Limestone
| Property | Value/Range |
|----------|-------------|
| Lithology | Limestone with secondary porosity |
| Porosity Range (%) | 15-28 |
| Horizontal Permeability (mD) | 50-300 |
| Vertical Permeability (mD) | 25-150 |
| Reservoir Quality Index (μm) | 2.0-4.0 |
| Flow Zone Indicator (μm) | 4-10 |

#### Rock Type 6 - Shale/Barrier
| Property | Value/Range |
|----------|-------------|
| Lithology | Clay-rich shale and mudstone |
| Porosity Range (%) | 2-8 |
| Horizontal Permeability (mD) | 0.001-0.1 |
| Vertical Permeability (mD) | 0.0001-0.01 |
| Reservoir Quality Index (μm) | < 0.5 |
| Flow Zone Indicator (μm) | < 1.0 |

### 2.2 Porosity-Permeability Correlations

#### Mathematical Relationships

The fundamental porosity-permeability relationship follows the power law:

$$k = a\phi^n$$

where:
- $k$ = permeability (mD)
- $\phi$ = porosity (fraction)
- $a$ = rock-specific constant
- $n$ = porosity exponent

#### Kozeny-Carman Theoretical Foundation

The theoretical basis for permeability is described by the Kozeny-Carman equation:

$$k = \frac{\phi^3}{c\tau^2 S^2}$$

where:
- $c$ = Kozeny constant (≈ 5 for granular media)
- $\tau$ = tortuosity factor
- $S$ = specific surface area per unit volume

#### Power Law Relationships by Rock Type

| Rock Type | Correlation | R² | Applicable Range |
|-----------|-------------|-----|------------------|
| RT1 - High Perm Sandstone | k = 0.0314 × φ^2.1 | 0.82 | φ: 25-32% |
| RT2 - Medium Perm Sandstone | k = 0.0156 × φ^2.5 | 0.78 | φ: 20-25% |
| RT3 - Low Perm Sandstone | k = 0.0089 × φ^3.2 | 0.75 | φ: 15-20% |
| RT4 - Tight Sandstone | k = 0.0045 × φ^4.1 | 0.71 | φ: 10-15% |
| RT5 - Vuggy Limestone | k = 0.0128 × φ^2.8 | 0.65 | φ: 15-28% |
| RT6 - Shale/Barrier | k = 0.0001 × φ^6.0 | 0.45 | φ: 2-8% |

*Note: k in mD, φ in %, correlations valid for reservoir conditions*

### 2.3 Rock Type Distribution by Depth

#### Vertical Distribution Profile
| Depth Interval (ft) | RT1 (%) | RT2 (%) | RT3 (%) | RT4 (%) | RT5 (%) | RT6 (%) |
|---------------------|---------|---------|---------|---------|---------|---------|
| 8,200 - 8,350 | 15 | 35 | 30 | 15 | 3 | 2 |
| 8,350 - 8,500 | 25 | 30 | 25 | 10 | 8 | 2 |
| 8,500 - 8,650 | 40 | 35 | 20 | 3 | 1 | 1 |
| 8,650 - 8,800 | 5 | 20 | 35 | 25 | 10 | 5 |
| 8,800 - 8,850 | 2 | 15 | 30 | 25 | 18 | 10 |

### 2.4 Lithofacies Characteristics

#### High Permeability Sandstone (RT1)
| Property | Specification |
|----------|---------------|
| Grain Size | Medium to coarse (0.25-1.0 mm) |
| Sorting | Well sorted (1.1-1.6) |
| Clay Content | < 5% |
| Cementation | Minimal silica/carbonate |
| Lateral Continuity | 500-1200 m |

#### Medium Permeability Sandstone (RT2)
| Property | Specification |
|----------|---------------|
| Grain Size | Fine to medium (0.125-0.5 mm) |
| Sorting | Moderately sorted (1.2-1.8) |
| Clay Content | 5-15% |
| Cementation | Moderate silica/carbonate |
| Lateral Continuity | 200-800 m |

#### Vuggy Limestone (RT5)
| Property | Specification |
|----------|---------------|
| Texture | Crystalline with secondary vugs |
| Vug Size | 0.5-10 mm diameter |
| Matrix Porosity | 8-15% |
| Vug Porosity | 5-15% |
| Lateral Continuity | 100-600 m |

#### Shale Barriers (RT6)
| Property | Specification |
|----------|---------------|
| Clay Content | > 60% |
| Lamination | Parallel to bedding |
| Thickness | 0.5-15 ft |
| Lateral Continuity | 50-500 m |

## 3. Three-Phase Flow Properties

### 3.1 Relative Permeability Characteristics

#### Oil-Water Relative Permeability by Rock Type

| Rock Type | Swir | Sor | krw@Sor | kro@Swir | nw | no |
|-----------|------|-----|---------|----------|----|----|
| RT1 - High Perm Sandstone | 0.15 | 0.25 | 0.40 | 0.85 | 2.5 | 2.0 |
| RT2 - Medium Perm Sandstone | 0.18 | 0.28 | 0.35 | 0.80 | 2.8 | 2.2 |
| RT3 - Low Perm Sandstone | 0.22 | 0.32 | 0.28 | 0.72 | 3.2 | 2.5 |
| RT4 - Tight Sandstone | 0.28 | 0.38 | 0.20 | 0.65 | 3.8 | 3.0 |
| RT5 - Vuggy Limestone | 0.12 | 0.22 | 0.45 | 0.88 | 2.2 | 1.8 |
| RT6 - Shale/Barrier | 0.35 | 0.45 | 0.05 | 0.25 | 5.0 | 4.0 |

#### Gas-Oil Relative Permeability by Rock Type

| Rock Type | Sgr | Sorg | krg@Sorg | krog@Sgr | ng | nog |
|-----------|-----|------|----------|-----------|----|----|
| RT1 - High Perm Sandstone | 0.05 | 0.15 | 0.75 | 0.90 | 1.8 | 2.2 |
| RT2 - Medium Perm Sandstone | 0.08 | 0.18 | 0.68 | 0.85 | 2.0 | 2.4 |
| RT3 - Low Perm Sandstone | 0.12 | 0.22 | 0.60 | 0.78 | 2.2 | 2.8 |
| RT4 - Tight Sandstone | 0.18 | 0.28 | 0.45 | 0.68 | 2.8 | 3.2 |
| RT5 - Vuggy Limestone | 0.03 | 0.12 | 0.80 | 0.92 | 1.6 | 2.0 |
| RT6 - Shale/Barrier | 0.25 | 0.35 | 0.15 | 0.30 | 4.0 | 4.5 |

*Note: Swir = irreducible water saturation, Sor = residual oil saturation, Sgr = residual gas saturation, Sorg = residual oil saturation to gas, n = Corey exponent*

### 3.2 Capillary Pressure Properties

#### Air-Mercury Capillary Pressure Parameters

| Rock Type | Entry Pressure (psi) | Pore Size Distribution Index | Permeability Modifier |
|-----------|---------------------|------------------------------|----------------------|
| RT1 - High Perm Sandstone | 0.8 | 0.45 | 1.0 |
| RT2 - Medium Perm Sandstone | 1.5 | 0.38 | 0.7 |
| RT3 - Low Perm Sandstone | 3.2 | 0.32 | 0.4 |
| RT4 - Tight Sandstone | 8.5 | 0.25 | 0.15 |
| RT5 - Vuggy Limestone | 1.2 | 0.50 | 0.9 |
| RT6 - Shale/Barrier | 45.0 | 0.15 | 0.001 |

#### Oil-Water Capillary Pressure at Reservoir Conditions

| Rock Type | Pc threshold (psi) | Height above FWL (ft) | Transition Zone (ft) |
|-----------|-------------------|----------------------|---------------------|
| RT1 - High Perm Sandstone | 0.5 | 15 | 25 |
| RT2 - Medium Perm Sandstone | 1.2 | 35 | 40 |
| RT3 - Low Perm Sandstone | 2.8 | 80 | 60 |
| RT4 - Tight Sandstone | 6.5 | 185 | 95 |
| RT5 - Vuggy Limestone | 0.8 | 22 | 30 |
| RT6 - Shale/Barrier | 25.0 | 715 | 150 |

### 3.3 Wettability Characteristics

#### Contact Angle and Wettability Index

| Rock Type | Water Contact Angle (°) | Oil Contact Angle (°) | Wettability Index |
|-----------|------------------------|----------------------|-------------------|
| RT1 - High Perm Sandstone | 25-35 | 135-145 | 0.2-0.4 (water-wet) |
| RT2 - Medium Perm Sandstone | 30-40 | 130-140 | 0.3-0.5 (water-wet) |
| RT3 - Low Perm Sandstone | 35-50 | 120-135 | 0.4-0.6 (mixed-wet) |
| RT4 - Tight Sandstone | 45-65 | 110-125 | 0.5-0.7 (mixed-wet) |
| RT5 - Vuggy Limestone | 20-30 | 140-150 | 0.1-0.3 (water-wet) |
| RT6 - Shale/Barrier | 60-80 | 95-115 | 0.7-0.9 (oil-wet) |

### 3.4 Depth-Dependent Property Trends

#### Porosity Variation with Depth

| Lithology | Surface Porosity (%) | Compaction Gradient (%/1000 ft) | Depth Range (ft) |
|-----------|---------------------|--------------------------------|------------------|
| Sandstone | 35-40 | 2.5-3.5 | 8,200-8,850 |
| Limestone | 25-30 | 1.8-2.8 | 8,300-8,500 |
| Shale | 15-20 | 4.0-6.0 | Throughout |

#### Permeability Variation with Depth

| Lithology | Permeability Gradient (log units/1000 ft) | Stress Sensitivity Factor |
|-----------|-------------------------------------------|--------------------------|
| Sandstone | -0.15 to -0.25 | 6.0 × 10⁻⁵ psi⁻¹ |
| Limestone | -0.20 to -0.35 | 8.5 × 10⁻⁵ psi⁻¹ |
| Shale | -0.45 to -0.65 | 1.2 × 10⁻⁴ psi⁻¹ |

## 4. Rock Compressibility and Mechanical Properties

### 4.1 Pore Volume Compressibility by Rock Type

#### Mathematical Definition

Rock compressibility is defined as the fractional change in pore volume with pressure:

$$c_r = -\frac{1}{V_p}\frac{dV_p}{dP}$$

where:
- $c_r$ = rock compressibility (psi⁻¹)
- $V_p$ = pore volume
- $P$ = pore pressure

#### Compressibility Parameters

| Rock Type | Pore Compressibility (×10⁻⁶ psi⁻¹) | Reference Pressure (psi) | Pressure Exponent |
|-----------|-----------------------------------|-------------------------|-------------------|
| RT1 - High Perm Sandstone | 3.5 | 2000 | -0.12 |
| RT2 - Medium Perm Sandstone | 4.2 | 2000 | -0.15 |
| RT3 - Low Perm Sandstone | 5.8 | 2000 | -0.18 |
| RT4 - Tight Sandstone | 7.2 | 2000 | -0.22 |
| RT5 - Vuggy Limestone | 2.8 | 2000 | -0.10 |
| RT6 - Shale/Barrier | 12.5 | 2000 | -0.35 |

#### Rock Matrix Compressibility

| Lithology | Matrix Compressibility (×10⁻⁶ psi⁻¹) | Grain Bulk Modulus (GPa) |
|-----------|---------------------------------------|--------------------------|
| Sandstone | 2.1 | 38 (Quartz) |
| Limestone | 1.8 | 65 (Calcite) |
| Shale | 3.5 | 25 (Clay minerals) |

### 4.2 Elastic Properties by Lithology

#### Young's Modulus and Poisson Ratio

| Lithology | Young's Modulus (GPa) | Poisson Ratio | Porosity Correlation |
|-----------|----------------------|---------------|---------------------|
| Sandstone | 2.5 - 5.2 | 0.18 - 0.28 | E = 6.8 - 0.15φ |
| Limestone | 15 - 45 | 0.15 - 0.25 | E = 52 - 0.85φ |
| Shale | 1.5 - 8.5 | 0.25 - 0.35 | E = 12 - 1.2φ |

*Note: E in GPa, φ in %, correlations valid for reservoir depth range*

#### Bulk and Shear Moduli

| Lithology | Bulk Modulus (GPa) | Shear Modulus (GPa) | Depth Gradient (GPa/1000 ft) |
|-----------|-------------------|--------------------|-----------------------------|
| Sandstone | 1.8 - 3.2 | 1.2 - 2.1 | 0.15 - 0.25 |
| Limestone | 12 - 28 | 8 - 18 | 0.8 - 1.2 |
| Shale | 0.8 - 5.5 | 0.6 - 3.2 | 0.3 - 0.6 |

### 4.3 Stress Sensitivity Parameters

#### Mathematical Model for Stress-Dependent Permeability

The stress-dependent permeability follows an exponential relationship:

$$k(P) = k_0 e^{-\gamma(P-P_0)}$$

where:
- $k(P)$ = permeability at pressure P
- $k_0$ = reference permeability at pressure $P_0$
- $\gamma$ = stress sensitivity coefficient
- $P$ = current pressure
- $P_0$ = reference pressure

#### Permeability Stress Sensitivity

| Rock Type | Stress Coefficient (×10⁻⁵ psi⁻¹) | Reversibility (%) | Critical Stress (psi) |
|-----------|----------------------------------|------------------|----------------------|
| RT1 - High Perm Sandstone | 6.2 | 85 | 3500 |
| RT2 - Medium Perm Sandstone | 8.5 | 75 | 3000 |
| RT3 - Low Perm Sandstone | 12.0 | 65 | 2500 |
| RT4 - Tight Sandstone | 18.5 | 45 | 2000 |
| RT5 - Vuggy Limestone | 4.8 | 90 | 4000 |
| RT6 - Shale/Barrier | 35.0 | 15 | 1500 |

#### Porosity Stress Sensitivity

| Rock Type | Compaction Coefficient (×10⁻⁶ psi⁻¹) | Plastic Threshold (psi) |
|-----------|--------------------------------------|------------------------|
| RT1 - High Perm Sandstone | 2.8 | 4500 |
| RT2 - Medium Perm Sandstone | 3.2 | 4000 |
| RT3 - Low Perm Sandstone | 4.1 | 3500 |
| RT4 - Tight Sandstone | 5.2 | 3000 |
| RT5 - Vuggy Limestone | 1.9 | 5500 |
| RT6 - Shale/Barrier | 8.5 | 2000 |

### 4.4 Biot Poroelastic Parameters

#### Biot Coefficient by Rock Type

| Rock Type | Biot Coefficient | Undrained Bulk Modulus (GPa) | Skempton B Parameter |
|-----------|-----------------|------------------------------|---------------------|
| RT1 - High Perm Sandstone | 0.72 ± 0.06 | 2.8 | 0.85 |
| RT2 - Medium Perm Sandstone | 0.75 ± 0.08 | 2.5 | 0.82 |
| RT3 - Low Perm Sandstone | 0.78 ± 0.10 | 2.2 | 0.78 |
| RT4 - Tight Sandstone | 0.82 ± 0.12 | 1.8 | 0.72 |
| RT5 - Vuggy Limestone | 0.65 ± 0.08 | 18 | 0.65 |
| RT6 - Shale/Barrier | 0.88 ± 0.15 | 3.2 | 0.95 |

#### Effective Stress Relationships

| Parameter | Terzaghi Model | Biot Model | Application Range |
|-----------|----------------|------------|-------------------|
| Effective Stress | σ' = σ - P | σ' = σ - αP | All rock types |
| Pore Pressure Effect | Full coupling | Partial coupling (α) | Consolidated rocks |
| Applicability | Soils, unconsolidated | Consolidated rocks | Per lithology |

## 5. Core Analysis and Laboratory Data

### 5.1 Standard Core Analysis Results

#### Porosity and Permeability Measurements

| Analysis Type | Sample Count | Porosity Range (%) | Permeability Range (mD) | Measurement Precision |
|---------------|--------------|-------------------|-------------------------|----------------------|
| Helium Porosimetry | 245 | 2.5 - 32.8 | - | ±0.3% |
| Gas Permeability (Steady-state) | 245 | - | 0.001 - 850 | ±10% (k>1mD) |
| Mercury Injection | 85 | 2.1 - 31.5 | 0.001 - 780 | ±0.2% / ±15% |
| Probe Permeameter | 420 | - | 0.1 - 650 | ±20% |

#### Grain Density and Bulk Density

| Lithology | Grain Density (g/cm³) | Bulk Density Range (g/cm³) | Sample Count |
|-----------|----------------------|---------------------------|--------------|
| Sandstone | 2.65 ± 0.05 | 2.15 - 2.55 | 180 |
| Limestone | 2.71 ± 0.08 | 2.25 - 2.65 | 45 |
| Shale | 2.68 ± 0.12 | 2.35 - 2.62 | 20 |

### 5.2 Special Core Analysis Program

#### Test Conditions and Standards

| Test Type | Temperature (°F) | Pressure Range (psi) | Fluid System | Standard |
|-----------|-----------------|---------------------|--------------|----------|
| Relative Permeability | 180 | 500 - 4000 | Oil/Brine/Gas | API RP 40 |
| Capillary Pressure | 180 | 0 - 8000 | Hg/Air, Oil/Brine | ASTM D4404 |
| Formation Factor | 75 | Ambient | NaCl Brine | ASTM D5202 |
| Compaction | 180 | 500 - 8000 | Synthetic Brine | Industry Standard |

#### Electrical Properties

The formation factor relates rock resistivity to formation water resistivity through Archie's equation:

$$F = a\phi^{-m}$$

where:
- $F$ = formation factor (dimensionless)
- $a$ = tortuosity factor (typically 0.62-2.15)
- $\phi$ = porosity (fraction)
- $m$ = cementation exponent

| Rock Type | Formation Factor | Cementation Exponent (m) | Saturation Exponent (n) |
|-----------|-----------------|-------------------------|------------------------|
| RT1 - High Perm Sandstone | 8 - 15 | 1.8 - 2.0 | 2.0 - 2.2 |
| RT2 - Medium Perm Sandstone | 12 - 22 | 1.9 - 2.1 | 2.1 - 2.3 |
| RT3 - Low Perm Sandstone | 18 - 35 | 2.0 - 2.3 | 2.2 - 2.5 |
| RT4 - Tight Sandstone | 28 - 65 | 2.2 - 2.5 | 2.3 - 2.8 |
| RT5 - Vuggy Limestone | 6 - 18 | 1.6 - 2.2 | 1.8 - 2.4 |
| RT6 - Shale/Barrier | 45 - 150 | 2.5 - 3.5 | 2.8 - 4.0 |

### 5.3 Formation Damage Assessment

#### Drilling Fluid Compatibility

| Rock Type | Water-Based Mud Damage (%) | Oil-Based Mud Damage (%) | Recovery Factor (%) |
|-----------|----------------------------|--------------------------|-------------------|
| RT1 - High Perm Sandstone | 5 - 15 | 2 - 8 | 85 - 95 |
| RT2 - Medium Perm Sandstone | 8 - 20 | 3 - 10 | 80 - 90 |
| RT3 - Low Perm Sandstone | 15 - 35 | 5 - 15 | 70 - 85 |
| RT4 - Tight Sandstone | 25 - 50 | 8 - 25 | 60 - 80 |
| RT5 - Vuggy Limestone | 3 - 12 | 1 - 5 | 90 - 98 |
| RT6 - Shale/Barrier | 45 - 80 | 20 - 45 | 30 - 60 |

#### Clay Swelling and Migration

| Clay Type | Swelling Index | Critical Salinity (ppm) | Migration Velocity (ft/hr) |
|-----------|----------------|------------------------|---------------------------|
| Kaolinite | 0.05 - 0.15 | > 50,000 | 0.001 - 0.01 |
| Illite | 0.20 - 0.40 | > 30,000 | 0.01 - 0.05 |
| Chlorite | 0.10 - 0.25 | > 40,000 | 0.005 - 0.02 |
| Smectite | 1.50 - 3.50 | > 5,000 | 0.1 - 0.5 |

### 5.4 Quality Assurance and Data Validation

#### Core Preservation and Handling

| Parameter | Specification | Acceptance Criteria |
|-----------|---------------|-------------------|
| Core Recovery | > 95% in reservoir zones | Pass/Fail |
| Preservation Time | < 4 hours from drill to freeze | Pass/Fail |
| Storage Temperature | -20°C to -80°C | Continuous monitoring |
| Sample Integrity | No visible fractures or damage | Visual inspection |

#### Measurement Accuracy and Precision

| Property | Accuracy | Precision | Repeatability |
|----------|----------|-----------|---------------|
| Porosity (Helium) | ±0.3% | ±0.1% | CV < 2% |
| Permeability (Gas) | ±10% | ±5% | CV < 15% |
| Grain Density | ±0.02 g/cm³ | ±0.01 g/cm³ | CV < 1% |
| Formation Factor | ±5% | ±2% | CV < 8% |

#### Data Validation Criteria

| Validation Check | Acceptance Range | Action if Failed |
|------------------|------------------|------------------|
| Porosity vs Bulk Density | R² > 0.85 | Re-measure suspicious points |
| Permeability vs Porosity | Within ±1 log unit of trend | Investigate outliers |
| Formation Factor vs Porosity | Within Archie relationship | Re-run electrical tests |
| Mass Balance | < 2% error | Repeat full analysis |

---

**Document Status**: Updated - Technical Parameters Only  
**Last Updated**: 2025-01-25  
**Version**: 2.0  
**Author**: Reservoir Engineering Team  
**Review Status**: Technical Review Complete

**Related Documents**:
- [[01_Structural_Geology]]
- [[03_Fluid_Properties]]
- [[Eagle West Field Development Plan]]

**Simulation Compatibility**: All rock properties and correlations are specified for direct input into reservoir simulation models supporting 3-phase oil/gas/water flow.

---

## 9. SIMULATION GRID LAYER SPECIFICATION

### 9.1 Layer-by-Layer Rock Properties Distribution

**For PEBI grid simulation - Definitive specification for all simulation studies:**

#### Upper Zone (Layers 1-4)
| Layer | Lithology | Porosity (fraction) | Permeability (mD) | Kv/Kh Ratio | Thickness (ft) |
|-------|-----------|-------------------|-------------------|-------------|----------------|
| 1 | Sandstone | 0.200 | 90 | 0.5 | 8.3 |
| 2 | Sandstone | 0.195 | 85 | 0.5 | 8.3 |
| 3 | Sandstone | 0.190 | 80 | 0.5 | 8.3 |
| 4 | **Shale Barrier** | 0.050 | 0.01 | 0.1 | 8.3 |

**Upper Zone Average**: 19.5% porosity, 85 mD permeability (sand layers only)

#### Middle Zone (Layers 5-8)
| Layer | Lithology | Porosity (fraction) | Permeability (mD) | Kv/Kh Ratio | Thickness (ft) |
|-------|-----------|-------------------|-------------------|-------------|----------------|
| 5 | Sandstone | 0.235 | 175 | 0.5 | 8.3 |
| 6 | Sandstone | 0.230 | 170 | 0.5 | 8.3 |
| 7 | Sandstone | 0.225 | 160 | 0.5 | 8.3 |
| 8 | **Shale Barrier** | 0.050 | 0.01 | 0.1 | 8.3 |

**Middle Zone Average**: 22.8% porosity, 165 mD permeability (sand layers only)

#### Lower Zone (Layers 9-12)
| Layer | Lithology | Porosity (fraction) | Permeability (mD) | Kv/Kh Ratio | Thickness (ft) |
|-------|-----------|-------------------|-------------------|-------------|----------------|
| 9 | Sandstone | 0.150 | 30 | 0.5 | 8.3 |
| 10 | Sandstone | 0.145 | 25 | 0.5 | 8.3 |
| 11 | Sandstone | 0.140 | 22 | 0.5 | 8.3 |
| 12 | Sandstone | 0.135 | 20 | 0.5 | 8.3 |

**Lower Zone Average**: 14.5% porosity, 25 mD permeability

### 9.2 Rock Compressibility by Lithology
- **Sandstone**: 1.0 × 10⁻⁵ psi⁻¹
- **Shale**: 5.0 × 10⁻⁶ psi⁻¹  
- **Limestone**: 8.0 × 10⁻⁶ psi⁻¹

### 9.3 Implementation Notes
- **Shale Barriers**: Layers 4 and 8 represent interbedded shale intervals that act as vertical flow barriers
- **Vertical Permeability**: Calculated as Kv = Kh × (Kv/Kh ratio)
- **Grid Compatibility**: Specifications exactly match PEBI simulation grid
- **Zonation**: Three main reservoir zones with realistic heterogeneity
- **Flow Barriers**: Shale layers significantly restrict vertical communication

---

**CANON ESTABLISHED**: This layer specification is definitive for all Eagle West Field simulation studies. Any deviation must be explicitly documented and justified.