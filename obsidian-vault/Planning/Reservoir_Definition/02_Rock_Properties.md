# Rock Properties - Eagle West Field

## Overview

This document defines the rock properties for the Eagle West Field reservoir simulation model, including petrophysical characteristics, rock typing, heterogeneity modeling, and geomechanical properties for integration with MRST workflows.

## 1. Petrophysical Properties by Zone

### 1.1 Reservoir Zone Classification

The Eagle West Field contains three main reservoir sands with distinct petrophysical characteristics:

| Zone | Depth Range (ft) | Net Thickness (ft) | Primary Lithology | Depositional Environment |
|------|------------------|--------------------|--------------------|-------------------------|
| Upper Sand | 8,200 - 8,350 | 45-85 | Fine-medium sandstone | Distributary channel |
| Middle Sand | 8,400 - 8,600 | 60-120 | Medium-coarse sandstone | Main channel complex |
| Lower Sand | 8,650 - 8,850 | 35-75 | Fine sandstone/siltstone | Overbank/crevasse splay |

### 1.2 Porosity-Permeability Relationships

#### Upper Sand Zone
```
Porosity Range: 12-28% (mean: 19.5%)
Permeability Range: 5-450 mD (geometric mean: 85 mD)

Power Law Relationship:
k = 0.0234 * φ^3.2  (where k in mD, φ in %)
R² = 0.78

Kozeny-Carmen Form:
k = 1250 * φ³ / (1-φ)²
```

#### Middle Sand Zone
```
Porosity Range: 15-32% (mean: 22.8%)
Permeability Range: 15-850 mD (geometric mean: 165 mD)

Power Law Relationship:
k = 0.0456 * φ^2.8  (where k in mD, φ in %)
R² = 0.82

Kozeny-Carman Form:
k = 1850 * φ³ / (1-φ)²
```

#### Lower Sand Zone
```
Porosity Range: 8-22% (mean: 14.5%)
Permeability Range: 0.5-120 mD (geometric mean: 25 mD)

Power Law Relationship:
k = 0.0145 * φ^4.1  (where k in mD, φ in %)
R² = 0.75

Kozeny-Carman Form:
k = 850 * φ³ / (1-φ)²
```

### 1.3 Net-to-Gross Ratios

| Zone | Net-to-Gross | Cutoff Criteria |
|------|--------------|-----------------|
| Upper Sand | 0.75 ± 0.12 | φ > 12%, Sw < 0.65 |
| Middle Sand | 0.85 ± 0.08 | φ > 15%, Sw < 0.60 |
| Lower Sand | 0.62 ± 0.15 | φ > 10%, Sw < 0.70 |

### 1.4 Core Analysis Data Summary

#### Grain Size Analysis
```
Upper Sand:
  - D50: 0.18 mm (fine sand)
  - Sorting: 1.8 (moderately sorted)
  - Skewness: 0.15 (near symmetric)

Middle Sand:
  - D50: 0.35 mm (medium sand)
  - Sorting: 1.5 (moderately well sorted)
  - Skewness: -0.05 (symmetric)

Lower Sand:
  - D50: 0.12 mm (very fine sand)
  - Sorting: 2.2 (poorly sorted)
  - Skewness: 0.25 (fine skewed)
```

#### Formation Volume Factor
```
Oil FVF: 1.25 - 1.35 rb/stb (pressure dependent)
Gas FVF: 0.003 - 0.008 rb/scf (pressure dependent)
Water FVF: 1.02 - 1.04 rb/stb
```

## 2. Rock Typing and Flow Units

### 2.1 Flow Unit Classification

Five distinct flow units have been identified based on hydraulic properties:

#### Flow Unit 1 (High Quality Reservoir)
```
Zone: Primarily Middle Sand
Porosity: 25-32%
Permeability: 300-850 mD
RQI: > 3.5 μm
FZI: 8-15 μm
Description: Clean, well-sorted channel sands
```

#### Flow Unit 2 (Good Quality Reservoir)
```
Zone: Upper and Middle Sand
Porosity: 20-25%
Permeability: 100-300 mD
RQI: 2.5-3.5 μm
FZI: 5-8 μm
Description: Moderately clean channel-bar deposits
```

#### Flow Unit 3 (Moderate Quality Reservoir)
```
Zone: All zones
Porosity: 15-20%
Permeability: 25-100 mD
RQI: 1.5-2.5 μm
FZI: 3-5 μm
Description: Bioturbated and cemented sands
```

#### Flow Unit 4 (Poor Quality Reservoir)
```
Zone: Upper and Lower Sand
Porosity: 10-15%
Permeability: 5-25 mD
RQI: 0.8-1.5 μm
FZI: 1.5-3 μm
Description: Argillaceous and heavily cemented
```

#### Flow Unit 5 (Tight/Barrier)
```
Zone: Lower Sand and shale interbeds
Porosity: 5-10%
Permeability: 0.1-5 mD
RQI: < 0.8 μm
FZI: < 1.5 μm
Description: Shaly sandstone and mudstone
```

### 2.2 Permeability-Porosity Transforms by Flow Unit

```matlab
% MRST Compatible Functions
function k = flowUnitPermeability(phi, FU)
    switch FU
        case 1  % High Quality
            k = 0.0314 * (phi/100).^2.1 * 1000;  % mD
        case 2  % Good Quality
            k = 0.0156 * (phi/100).^2.5 * 1000;  % mD
        case 3  % Moderate Quality
            k = 0.0089 * (phi/100).^3.2 * 1000;  % mD
        case 4  % Poor Quality
            k = 0.0045 * (phi/100).^4.1 * 1000;  % mD
        case 5  % Tight/Barrier
            k = 0.0012 * (phi/100).^5.5 * 1000;  % mD
        otherwise
            error('Invalid flow unit');
    end
end
```

### 2.3 Stratigraphic Correlations

#### Flow Unit Distribution by Zone
```
Upper Sand:
  - FU1: 15%  - FU2: 35%  - FU3: 30%  - FU4: 15%  - FU5: 5%

Middle Sand:
  - FU1: 40%  - FU2: 35%  - FU3: 20%  - FU4: 4%   - FU5: 1%

Lower Sand:
  - FU1: 5%   - FU2: 20%  - FU3: 35%  - FU4: 25%  - FU5: 15%
```

### 2.4 Depositional Facies Descriptions

#### Facies A: Channel Axis (FU1, FU2)
```
Characteristics:
  - Trough cross-bedded medium to coarse sandstone
  - Minimal clay content (< 5%)
  - Excellent reservoir quality
  - Lateral continuity: 500-1200 m
  - Vertical thickness: 8-25 ft
```

#### Facies B: Channel Margin (FU2, FU3)
```
Characteristics:
  - Planar and low-angle cross-bedded fine to medium sandstone
  - Moderate clay content (5-15%)
  - Good to moderate reservoir quality
  - Lateral continuity: 200-800 m
  - Vertical thickness: 4-15 ft
```

#### Facies C: Overbank/Levee (FU3, FU4)
```
Characteristics:
  - Horizontally laminated fine sandstone and siltstone
  - High clay content (15-30%)
  - Poor reservoir quality
  - Lateral continuity: 100-500 m
  - Vertical thickness: 2-10 ft
```

#### Facies D: Floodplain (FU4, FU5)
```
Characteristics:
  - Mudstone with thin sandstone stringers
  - Very high clay content (> 30%)
  - Barrier to flow
  - Lateral continuity: 50-200 m
  - Vertical thickness: 1-8 ft
```

## 3. Heterogeneity Modeling

### 3.1 Spatial Correlation Lengths

#### Porosity Correlation Lengths
```
Major Direction (N30°E - paleocurrent):
  - Upper Sand: 1200 m
  - Middle Sand: 1800 m
  - Lower Sand: 800 m

Minor Direction (N60°W - across paleocurrent):
  - Upper Sand: 400 m
  - Middle Sand: 600 m
  - Lower Sand: 300 m

Vertical Direction:
  - Upper Sand: 12 m
  - Middle Sand: 18 m
  - Lower Sand: 8 m
```

#### Permeability Correlation Lengths
```
Major Direction: 0.7 × porosity correlation length
Minor Direction: 0.6 × porosity correlation length
Vertical Direction: 0.5 × porosity correlation length
```

### 3.2 Variogram Parameters

#### Spherical Variogram Model
```matlab
% MRST Variogram Parameters
gamma_phi = struct();
gamma_phi.type = 'spherical';
gamma_phi.range = [1200, 400, 12];  % [major, minor, vertical] in m
gamma_phi.sill = 0.0025;             % variance in porosity²
gamma_phi.nugget = 0.0005;           % measurement error

gamma_log_k = struct();
gamma_log_k.type = 'spherical';
gamma_log_k.range = [840, 240, 6];   % [major, minor, vertical] in m
gamma_log_k.sill = 0.85;             % variance in (log k)²
gamma_log_k.nugget = 0.15;           % measurement error
```

#### Exponential Variogram Model (Alternative)
```matlab
% Alternative exponential model for comparison
gamma_phi_exp = struct();
gamma_phi_exp.type = 'exponential';
gamma_phi_exp.range = [800, 300, 8];  % practical range in m
gamma_phi_exp.sill = 0.0028;
gamma_phi_exp.nugget = 0.0004;
```

### 3.3 Stochastic Modeling Approach

#### Sequential Gaussian Simulation (SGSIM)
```
Primary Variable: Porosity (Gaussian transform)
Secondary Variable: log(Permeability)
Cross-correlation coefficient: 0.75-0.85

Simulation Parameters:
  - Grid cell size: 50m × 50m × 2m
  - Number of realizations: 100
  - Search radius: 2 × correlation length
  - Minimum data points: 8
  - Maximum data points: 20
```

#### Co-located Cosimulation
```matlab
% MRST Implementation Framework
function [phi_sim, k_sim] = colocatedCosim(G, wells, variogram_params)
    % Conditional simulation of porosity and permeability
    % Input: Grid G, well data, variogram parameters
    % Output: Simulated porosity and permeability fields
    
    % Transform porosity to Gaussian
    phi_gauss = normalTransform(wells.porosity);
    
    % Sequential Gaussian simulation for porosity
    phi_sim_gauss = sgsim(G, wells.coords, phi_gauss, variogram_params.phi);
    
    % Back-transform to original scale
    phi_sim = inverseNormalTransform(phi_sim_gauss);
    
    % Co-simulate log-permeability
    log_k_sim = cosim(G, phi_sim, wells.log_k, variogram_params.log_k, 0.8);
    k_sim = exp(log_k_sim);
end
```

### 3.4 Uncertainty Quantification

#### Parameter Uncertainty Ranges
```
Porosity Uncertainty:
  - Mean: ±2 porosity units
  - Variance: ±0.5 (porosity units)²
  - Correlation length: ±20%

Permeability Uncertainty:
  - Geometric mean: ±30%
  - Variance in log(k): ±0.2
  - Correlation length: ±25%

Flow Unit Proportion Uncertainty:
  - FU1: ±5%
  - FU2: ±8%
  - FU3: ±10%
  - FU4: ±12%
  - FU5: ±15%
```

#### Monte Carlo Sampling Strategy
```matlab
% Uncertainty sampling for MRST workflows
function params = uncertaintySampling(n_realizations)
    % Generate parameter samples for uncertainty analysis
    
    params = struct();
    
    % Porosity statistics
    params.phi_mean = normrnd(19.5, 2.0, [n_realizations, 1]);
    params.phi_var = lognrnd(log(0.0025), 0.2, [n_realizations, 1]);
    
    % Permeability statistics
    params.k_geomean = lognrnd(log(85), 0.3, [n_realizations, 1]);
    params.log_k_var = lognrnd(log(0.85), 0.15, [n_realizations, 1]);
    
    % Correlation lengths (multipliers)
    params.range_mult = lognrnd(0, 0.2, [n_realizations, 3]);
end
```

## 4. Geomechanical Properties

### 4.1 Elastic Properties

#### Young's Modulus and Poisson Ratio
```
Upper Sand:
  - Young's Modulus: 2.8 - 4.2 GPa (mean: 3.5 GPa)
  - Poisson Ratio: 0.18 - 0.28 (mean: 0.23)
  - Correlation with porosity: E = 6.2 - 0.14φ (GPa)

Middle Sand:
  - Young's Modulus: 3.2 - 5.1 GPa (mean: 4.1 GPa)
  - Poisson Ratio: 0.16 - 0.25 (mean: 0.21)
  - Correlation with porosity: E = 7.8 - 0.16φ (GPa)

Lower Sand:
  - Young's Modulus: 2.1 - 3.8 GPa (mean: 2.9 GPa)
  - Poisson Ratio: 0.22 - 0.32 (mean: 0.27)
  - Correlation with porosity: E = 5.1 - 0.18φ (GPa)
```

#### Bulk and Shear Moduli
```matlab
% MRST compatible elastic moduli calculations
function [K, G] = elasticModuli(E, nu)
    % Bulk modulus
    K = E ./ (3 * (1 - 2*nu));
    
    % Shear modulus
    G = E ./ (2 * (1 + nu));
end

% Typical values (GPa)
K_bulk = [1.9, 2.3, 1.7];     % [Upper, Middle, Lower]
G_shear = [1.4, 1.7, 1.1];    % [Upper, Middle, Lower]
```

### 4.2 Rock Compressibility Values

#### Pore Volume Compressibility
```
Upper Sand: 
  - Cp = 4.2 × 10⁻⁶ psi⁻¹ (6.1 × 10⁻⁴ MPa⁻¹)
  - Pressure dependence: Cp = Cp₀ × (P/P₀)⁻⁰·¹⁵

Middle Sand:
  - Cp = 3.1 × 10⁻⁶ psi⁻¹ (4.5 × 10⁻⁴ MPa⁻¹)
  - Pressure dependence: Cp = Cp₀ × (P/P₀)⁻⁰·¹²

Lower Sand:
  - Cp = 5.8 × 10⁻⁶ psi⁻¹ (8.4 × 10⁻⁴ MPa⁻¹)
  - Pressure dependence: Cp = Cp₀ × (P/P₀)⁻⁰·¹⁸
```

#### Rock Matrix Compressibility
```
All Zones:
  - Cr = 2.1 × 10⁻⁶ psi⁻¹ (3.0 × 10⁻⁴ MPa⁻¹)
  - Assumed constant (low compressibility)
```

### 4.3 Stress-Dependent Permeability

#### Exponential Stress Sensitivity Model
```matlab
% MRST implementation
function k_eff = stressDependentPerm(k0, sigma_eff, gamma)
    % k0: initial permeability (mD)
    % sigma_eff: effective stress (psi or MPa)
    % gamma: stress sensitivity coefficient
    
    k_eff = k0 .* exp(-gamma .* sigma_eff);
end

% Stress sensitivity coefficients (psi⁻¹)
gamma_values = struct();
gamma_values.upper = 8.5e-5;    % Upper Sand
gamma_values.middle = 6.2e-5;   % Middle Sand
gamma_values.lower = 1.2e-4;    % Lower Sand
```

#### Power Law Alternative
```matlab
function k_eff = stressDependentPermPower(k0, sigma_eff, alpha, sigma_ref)
    % Power law model
    k_eff = k0 .* (sigma_eff / sigma_ref).^(-alpha);
end

% Power law exponents
alpha_values = [0.15, 0.12, 0.22];  % [Upper, Middle, Lower]
sigma_ref = 3000;  % Reference stress (psi)
```

### 4.4 Biot Coefficient

#### Biot Coefficient by Zone
```
Upper Sand: α = 0.75 ± 0.08
Middle Sand: α = 0.72 ± 0.06
Lower Sand: α = 0.82 ± 0.12

Correlation with porosity:
α = 1 - Km/Ks

Where:
  Km = bulk modulus of rock frame
  Ks = bulk modulus of mineral grains (38 GPa for quartz)
```

#### Effective Stress Calculation
```matlab
function sigma_eff = effectiveStress(sigma_total, p_pore, alpha)
    % Terzaghi-Biot effective stress
    sigma_eff = sigma_total - alpha .* p_pore;
end
```

## 5. Special Core Analysis

### 5.1 Compaction Curves

#### Uniaxial Compaction Tests
```
Test Conditions:
  - Confining pressure: 500 - 8000 psi
  - Temperature: 180°F (reservoir temperature)
  - Loading rate: 100 psi/hr
  - Pore fluid: synthetic brine

Upper Sand Results:
  - Initial porosity: 22.5%
  - Final porosity (8000 psi): 20.1%
  - Compaction: 2.4 porosity units
  - Irreversible compaction: 60%

Middle Sand Results:
  - Initial porosity: 25.8%
  - Final porosity (8000 psi): 23.9%
  - Compaction: 1.9 porosity units
  - Irreversible compaction: 45%

Lower Sand Results:
  - Initial porosity: 16.2%
  - Final porosity (8000 psi): 13.8%
  - Compaction: 2.4 porosity units
  - Irreversible compaction: 75%
```

#### Hydrostatic Compaction Model
```matlab
function phi_eff = compactionModel(phi0, sigma_eff, Cm)
    % Exponential compaction model
    % phi0: initial porosity
    % sigma_eff: effective stress
    % Cm: uniaxial compaction coefficient
    
    phi_eff = phi0 .* exp(-Cm .* sigma_eff);
end

% Compaction coefficients (psi⁻¹)
Cm_values = [3.2e-6, 2.1e-6, 4.8e-6];  % [Upper, Middle, Lower]
```

### 5.2 Stress Sensitivity Analysis

#### Permeability vs Effective Stress
```
Upper Sand:
  - Initial k: 125 mD
  - k at 2000 psi: 98 mD (22% reduction)
  - k at 4000 psi: 78 mD (38% reduction)
  - k at 6000 psi: 63 mD (50% reduction)

Middle Sand:
  - Initial k: 280 mD  
  - k at 2000 psi: 235 mD (16% reduction)
  - k at 4000 psi: 195 mD (30% reduction)
  - k at 6000 psi: 165 mD (41% reduction)

Lower Sand:
  - Initial k: 45 mD
  - k at 2000 psi: 32 mD (29% reduction)
  - k at 4000 psi: 23 mD (49% reduction)
  - k at 6000 psi: 16 mD (64% reduction)
```

#### Porosity vs Effective Stress
```matlab
% MRST compatible stress sensitivity
function [phi_new, k_new] = applyStressSensitivity(phi0, k0, sigma_eff, zone)
    % Apply stress-dependent changes to porosity and permeability
    
    switch zone
        case 'upper'
            Cm = 3.2e-6;  % compaction coefficient
            gamma = 8.5e-5;  % permeability sensitivity
        case 'middle'
            Cm = 2.1e-6;
            gamma = 6.2e-5;
        case 'lower'
            Cm = 4.8e-6;
            gamma = 1.2e-4;
    end
    
    phi_new = phi0 .* exp(-Cm .* sigma_eff);
    k_new = k0 .* exp(-gamma .* sigma_eff);
end
```

### 5.3 Formation Damage Considerations

#### Drilling Mud Invasion
```
Skin Factor Components:
  - Mud invasion: S1 = 2.5 - 8.5
  - Mechanical damage: S2 = 0.5 - 2.0
  - Partial penetration: S3 = 0.1 - 1.5
  - Total skin: St = S1 + S2 + S3

Permeability Damage:
  - Upper Sand: 15-35% reduction
  - Middle Sand: 10-25% reduction  
  - Lower Sand: 25-55% reduction
```

#### Water Sensitivity
```
Clay Content Impact:
  - Kaolinite (5-15%): Low sensitivity
  - Illite (2-8%): Moderate sensitivity
  - Smectite (1-3%): High sensitivity

Fresh Water Damage:
  - Upper Sand: 5-15% k reduction
  - Middle Sand: 3-10% k reduction
  - Lower Sand: 15-40% k reduction
```

### 5.4 Quality Control Procedures

#### Core Handling and Preservation
```
Preservation Method: Liquid nitrogen freezing
Storage: Sealed aluminum containers with inert atmosphere
Core recovery: >95% in reservoir intervals
Handling time limit: <4 hours from drilling to preservation

Sample Selection Criteria:
  - Minimum diameter: 1.5 inches
  - Length to diameter ratio: >2:1
  - No visible fractures or drilling damage
  - Representative of log response
```

#### Measurement Precision and Accuracy
```
Porosity Measurements:
  - Helium porosimetry: ±0.5 porosity units
  - Mercury injection: ±0.3 porosity units
  - Thin section analysis: ±1.0 porosity units

Permeability Measurements:
  - Steady-state air: ±15% (k > 1 mD)
  - Unsteady-state: ±20% (k < 1 mD)
  - Probe permeameter: ±25%

Repeatability Standards:
  - Porosity: coefficient of variation <3%
  - Permeability: coefficient of variation <15%
  - Minimum 3 measurements per sample
```

#### Data Validation Protocols
```matlab
% MRST data validation functions
function isValid = validateRockProperties(phi, k, zone)
    % Validate porosity-permeability relationships
    
    % Physical limits
    phi_valid = (phi >= 0.05) & (phi <= 0.35);
    k_valid = (k >= 0.001) & (k <= 2000);
    
    % Relationship checks
    switch zone
        case 'upper'
            k_expected = 0.0234 .* phi.^3.2;
            rel_valid = abs(log(k) - log(k_expected)) < 1.5;
        case 'middle'
            k_expected = 0.0456 .* phi.^2.8;
            rel_valid = abs(log(k) - log(k_expected)) < 1.2;
        case 'lower'
            k_expected = 0.0145 .* phi.^4.1;
            rel_valid = abs(log(k) - log(k_expected)) < 1.8;
    end
    
    isValid = phi_valid & k_valid & rel_valid;
end
```

## MRST Integration Guidelines

### Rock Property Assignment
```matlab
% Example MRST rock property setup
function rock = assignRockProperties(G, facies, zone)
    % Assign rock properties based on facies and zone
    
    rock = makeRock(G, 1, 1);  % Initialize
    
    % Get flow unit assignments
    FU = getFlowUnits(facies, zone);
    
    % Assign porosity
    rock.poro = assignPorosity(G, FU, zone);
    
    % Assign permeability using transforms
    rock.perm = flowUnitPermeability(rock.poro * 100, FU) * milli*darcy;
    
    % Add stress sensitivity
    rock.cr = getPoreCompressibility(zone);
    rock.pvMultR = @(p) exp(-rock.cr .* (p - 1*atm));
    
    % Add permeability multiplier
    gamma = getStressSensitivity(zone);
    rock.permMultR = @(p) exp(-gamma .* (p - 1*atm));
end
```

### Uncertainty Analysis Framework
```matlab
function results = runUncertaintyAnalysis(base_case, n_realizations)
    % Monte Carlo uncertainty analysis
    
    results = cell(n_realizations, 1);
    
    for i = 1:n_realizations
        % Sample uncertain parameters
        params = uncertaintySampling(1);
        
        % Generate stochastic rock properties
        [phi_real, k_real] = colocatedCosim(G, wells, params);
        
        % Update rock properties
        rock_real = base_case.rock;
        rock_real.poro = phi_real;
        rock_real.perm = k_real;
        
        % Run simulation
        results{i} = runSimulation(base_case.schedule, rock_real);
    end
end
```

---

**Document Status**: Complete  
**Last Updated**: 2025-01-25  
**Version**: 1.0  
**Author**: Reservoir Engineering Team  
**Review Status**: Technical Review Complete

**Related Documents**:
- [[01_Structural_Geology]]
- [[03_Fluid_Properties]]
- [[Eagle West Field Development Plan]]

**MRST Compatibility**: All correlations and data formats are compatible with MRST 2023a and later versions.