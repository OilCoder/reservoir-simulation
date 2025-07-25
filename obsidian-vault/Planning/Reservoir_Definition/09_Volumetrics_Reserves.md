# Eagle West Field - Reservoir Characterization and Material Balance

## Executive Summary

This document provides reservoir characterization framework and material balance principles for the Eagle West Field simulation studies. The analysis focuses on grid volume calculations, pore volume distribution by rock type, and material balance validation methods without predefined volumetric targets or reserves classification.

### Key Characterization Elements
- **Grid Volume Analysis**: Systematic calculation of bulk rock volumes across reservoir zones
- **Pore Volume Distribution**: Rock type-based porosity and saturation characterization
- **Initial Fluid Volumes**: In-place hydrocarbon and water volumes for simulation initialization
- **Material Balance Framework**: Validation methodology for simulation model consistency
- **Uncertainty Quantification**: Property ranges for sensitivity analysis

---

## 1. Grid Volume Characterization

### 1.1 Bulk Rock Volume Calculations

Grid volume analysis provides the foundation for reservoir simulation model initialization and material balance validation.

#### Grid Geometry Parameters
| Parameter | Value | Units | Uncertainty Range |
|-----------|-------|-------|-------------------|
| **Reservoir Extent** | | | |
| Field Area | 2,600 | acres | ±150 acres |
| Average Gross Thickness | 238 | ft | ±25 ft |
| Net-to-Gross Ratio | 52.5 | % | ±8% |
| **Grid Resolution** | | | |
| Grid Cells (I×J×K) | 50×40×12 | - | Fixed |
| Cell Size (avg) | 200×200×20 | ft | Variable |
| **Rock Volume Calculation** | | | |
| Gross Rock Volume | 63.2 | billion ft³ | Calculated |
| Net Rock Volume | 33.2 | billion ft³ | Calculated |

#### Grid Volume Distribution
```
Grid Analysis Framework:
- Total grid cells: 24,000
- Active cells: ~18,500 (accounting for geometry)
- Cell volume range: 400,000 - 1,200,000 ft³
- Net rock volume = Σ(cell_volume × NTG × active_flag)
```

### 1.2 Pore Volume Analysis by Rock Type

#### Rock Type Classification
| Rock Type | Porosity Range (%) | Permeability Range (mD) | Net-to-Gross (%) | Volume Fraction (%) |
|-----------|-------------------|------------------------|------------------|---------------------|
| **RT1 - High Quality Sand** | 24-28 | 200-500 | 75-85 | 35 |
| **RT2 - Medium Quality Sand** | 20-24 | 100-200 | 60-75 | 45 |
| **RT3 - Low Quality Sand** | 16-20 | 50-100 | 40-60 | 15 |
| **RT4 - Shale/Tight** | 8-16 | 1-50 | 10-40 | 5 |

#### Pore Volume Distribution
| Rock Type | Bulk Volume (billion ft³) | Pore Volume (billion ft³) | Initial Water Saturation Range (%) |
|-----------|----------------------------|----------------------------|-------------------------------------|
| **RT1** | 11.1 | 2.8 | 18-22 |
| **RT2** | 14.9 | 3.3 | 22-28 |
| **RT3** | 5.0 | 0.9 | 28-35 |
| **RT4** | 1.7 | 0.2 | 35-50 |
| **Total** | 32.7 | 7.2 | - |

#### Uncertainty Quantification
| Parameter | P10 | P50 | P90 | Distribution Type |
|-----------|-----|-----|-----|------------------|
| Total Pore Volume (billion ft³) | 6.2 | 7.2 | 8.4 | Lognormal |
| Average Porosity (%) | 20.5 | 22.5 | 24.5 | Normal |
| Water Saturation Range (%) | 20-32 | 22-25 | 25-35 | Variable by RT |

### 1.3 Initial Fluid Volume Distribution

#### Fluid Volumes by Zone
| Zone | Hydrocarbon Pore Volume (billion ft³) | Water Pore Volume (billion ft³) | Contact Depth (ft TVD) |
|------|----------------------------------------|-----------------------------------|-------------------------|
| **Sand 1 (Upper)** | 2.1 | 0.9 | 8,420 |
| **Sand 2 (Middle)** | 1.8 | 1.2 | 8,465 |
| **Sand 3 (Lower)** | 1.2 | 0.8 | 8,510 |
| **Total** | 5.1 | 2.9 | - |

#### Sensitivity Analysis - Volume Impact
```
Parameter Sensitivity on Total Pore Volume (±10% variation):

Net-to-Gross Ratio    ████████████████████ ±15% impact
Porosity Distribution ████████████████     ±12% impact  
Grid Resolution       ██████████████       ±10% impact
Reservoir Extent      ████████████         ±8% impact
Rock Type Definition  ████                 ±3% impact
```

---

## 2. Material Balance Framework

### 2.1 Material Balance Principles

Material balance provides the fundamental validation framework for reservoir simulation models by ensuring mass conservation across all phases and components.

#### General Material Balance Equation
The comprehensive material balance equation accounts for:
- Oil, water, and gas phase changes
- Reservoir compressibility effects  
- Aquifer influx contributions
- Injection and production volumes

```
Material Balance Framework:
N = (Np×Bo + Wp×Bw - Wi×Bw - We) / [(Bo-Boi) + (Rsi-Rs)×Bg + m×Boi×((Bo×Swi×cw + cf)/(1-Swi))×ΔP]

Where:
- N = Initial oil in place (simulation input)
- Production/injection terms validate against history
- PVT properties from laboratory measurements
- Drive mechanisms quantified through pressure response
```

### 2.2 Drive Mechanism Identification

#### Pressure-Production Analysis
Material balance analysis helps identify active drive mechanisms without assuming recovery factors:

| Drive Mechanism | Pressure Response | Production Characteristics | Validation Method |
|-----------------|-------------------|---------------------------|-------------------|
| **Solution Gas Drive** | Rapid decline below Pb | Increasing GOR, declining rate | Gas-oil ratio tracking |
| **Water Drive** | Pressure maintenance | Increasing water cut | Aquifer influx calculation |
| **Compaction Drive** | Gradual pressure decline | Steady decline rate | Rock compressibility |
| **Injection Support** | Pressure stabilization | Pattern performance | Voidage replacement |

### 2.3 Simulation Model Validation

#### Mass Balance Verification
| Component | Input Volume | Simulation Output | Validation Criteria |
|-----------|--------------|-------------------|---------------------|
| **Initial Oil** | Grid-based calculation | Model initialization | ±2% agreement |
| **Initial Water** | Saturation × pore volume | Water in place | ±3% agreement |
| **Cumulative Production** | Historical data | Model history match | ±5% annual |
| **Pressure Response** | Field measurements | Grid block pressures | ±50 psi average |

### 2.4 Uncertainty Propagation

#### Property Impact on Material Balance
| Parameter | Uncertainty Range | Material Balance Impact | Simulation Sensitivity |
|-----------|-------------------|------------------------|------------------------|
| **Porosity** | ±10% | Linear volume scaling | High |
| **Compressibility** | ±30% | Pressure response | Medium |
| **PVT Properties** | ±5% | Phase behavior | High |
| **Aquifer Strength** | ±50% | Pressure support | Medium |

---

## 3. Aquifer Volume Calculations

### 3.1 Aquifer Characterization Framework

Aquifer volume analysis provides essential boundary conditions for reservoir simulation and material balance validation.

#### Aquifer Geometry Definition
The Eagle West Field is supported by a peripheral aquifer system providing natural pressure support and boundary conditions for simulation modeling.

### 3.2 Aquifer Properties and Geometry

#### Aquifer Characteristics
| Parameter | Value | Units | Uncertainty Range |
|-----------|-------|-------|-------------------|
| **Aquifer Type** | Peripheral | - | Confirmed |
| **Aquifer Radius** | 8,500 | ft | ±500 ft |
| **Aquifer Thickness** | 180 | ft | ±20 ft |
| **Aquifer Porosity** | 18 | % | ±3% |
| **Aquifer Permeability** | 85 | mD | ±25 mD |
| **Net-to-Gross** | 65 | % | ±10% |

#### Volume Calculations
```
Aquifer Geometry Analysis:
- Field Area: 2,600 acres (reservoir)
- Aquifer Area: π × (8,500 ft)² - 2,600 acres = 45,850 acres
- Gross Aquifer Volume: 45,850 acres × 180 ft = 63.95 billion ft³
- Net Aquifer Volume: 63.95 × 0.65 = 41.57 billion ft³
- Aquifer Pore Volume: 41.57 × 0.18 = 7.48 billion ft³
```

### 3.3 Aquifer-Reservoir Interface

#### Boundary Conditions for Simulation
| Interface Parameter | Value | Impact on Simulation |
|-------------------|-------|---------------------|
| **Aquifer Strength Index** | 0.25 | Moderate pressure support |
| **Connectivity** | Peripheral | Lateral boundary condition |
| **Transmissibility** | 85 mD×ft | Water influx rate |
| **Compressibility** | 4.1×10⁻⁶ psi⁻¹ | Pressure response |

---

## 4. Simulation Model Validation

### 4.1 History Matching Validation

#### Production History Constraints
Simulation models must reproduce historical field performance to validate reservoir characterization:

| Validation Parameter | Historical Range | Simulation Target | Tolerance |
|---------------------|------------------|-------------------|-----------|
| **Cumulative Oil Production** | Field data | Match within ±3% | Annual basis |
| **Water Cut Evolution** | 15% → 85% | Match trend | ±5% absolute |
| **Field Pressure** | 2,900 → 2,400 psi | Match decline | ±50 psi |
| **Gas-Oil Ratio** | 450 → 800 scf/STB | Match increase | ±10% |

#### Model Calibration Metrics
```
History Match Quality Assessment:
- Production rate match: R² > 0.90 required
- Pressure match: Average error < 3%
- Water cut match: Trend correlation > 0.85
- Overall field performance: Integrated validation
```

### 4.2 Grid Block Validation

#### Spatial Distribution Verification
Simulation grid must accurately represent reservoir heterogeneity and fluid distribution:

```
Grid Block Validation Framework:
- Porosity distribution: Match core and log data
- Permeability trends: Honor geological structure
- Saturation initialization: Validate capillary pressure
- Rock type distribution: Maintain facies architecture
```

#### Property Correlation Checks
| Grid Property | Data Source | Validation Method | Acceptance Criteria |
|---------------|-------------|------------------|---------------------|
| **Porosity** | Core + Logs | Statistical comparison | R² > 0.80 |
| **Permeability** | Core + Tests | Permeability-porosity trend | Within 1 std dev |
| **Net-to-Gross** | Geological model | Zone-by-zone check | ±10% of geocellular |
| **Initial Saturations** | Capillary pressure | J-function normalization | Match free water level |

### 4.3 Quality Control Framework

#### Model Consistency Checks
Systematic validation ensures simulation model accuracy and reliability:

| Validation Category | Check Method | Quality Standard | Action if Failed |
|-------------------|--------------|------------------|------------------|
| **Mass Balance** | Material balance equation | <2% error | Recalibrate model |
| **Pressure Continuity** | Gradient consistency | No isolated cells | Adjust transmissibility |
| **Saturation Bounds** | Physical constraints | 0 ≤ S ≤ 1 | Review initialization |
| **Phase Behavior** | PVT validation | Match laboratory data | Update fluid model |

#### Uncertainty Assessment for Simulation
```
Reservoir Model Uncertainty Sources:
- Structural interpretation: ±5% volume impact
- Rock property distribution: ±10% flow impact  
- Fluid contacts: ±2% initial volume impact
- Boundary conditions: ±15% pressure support impact
```

---

## 5. Property Uncertainty Ranges

### 5.1 Rock Property Uncertainties

#### Core-Scale Measurements
Rock properties exhibit natural heterogeneity requiring uncertainty quantification for simulation studies:

| Rock Property | Base Value | P10 | P50 | P90 | Distribution | Data Source |
|---------------|------------|-----|-----|-----|-------------|-------------|
| **Porosity** | 22.5% | 20.5% | 22.5% | 24.5% | Normal | Core + Logs |
| **Permeability** | 150 mD | 85 mD | 150 mD | 220 mD | Lognormal | Core + Tests |
| **Net-to-Gross** | 52.5% | 44% | 52.5% | 61% | Beta | Geological |
| **Rock Compressibility** | 4.1×10⁻⁶ psi⁻¹ | 3.2×10⁻⁶ | 4.1×10⁻⁶ | 5.0×10⁻⁶ | Normal | Laboratory |

### 5.2 Fluid Property Uncertainties  

#### PVT Parameter Ranges
| Fluid Property | Base Value | Low Case | High Case | Impact on Simulation |
|---------------|------------|----------|-----------|---------------------|
| **Oil Viscosity** | 0.92 cp | 0.85 cp | 1.05 cp | Flow rates |
| **Formation Volume Factor** | 1.202 rb/STB | 1.185 | 1.220 | Volume calculations |
| **Solution GOR** | 450 scf/STB | 420 | 480 | Gas liberation |
| **Water Compressibility** | 3.2×10⁻⁶ psi⁻¹ | 3.0×10⁻⁶ | 3.5×10⁻⁶ | Pressure response |

### 5.3 Saturation Uncertainty

#### Initial Water Saturation Ranges by Rock Type
| Rock Type | Base Sw (%) | Minimum Sw (%) | Maximum Sw (%) | Uncertainty Source |
|-----------|-------------|----------------|----------------|-------------------|
| **RT1 - High Quality** | 20 | 18 | 22 | Capillary pressure |
| **RT2 - Medium Quality** | 25 | 22 | 28 | Core measurements |
| **RT3 - Low Quality** | 31 | 28 | 35 | Log interpretation |
| **RT4 - Tight/Shale** | 42 | 35 | 50 | Limited data |

---

## 6. Material Balance Validation Framework

### 6.1 Aquifer Modeling for Material Balance

#### Aquifer Properties for Simulation
The Eagle West Field aquifer provides boundary conditions for material balance validation and simulation studies.

| Parameter | Value | Units | Uncertainty Range | Use in Material Balance |
|-----------|-------|-------|------------------|------------------------|
| **Aquifer Type** | Peripheral | - | Confirmed | Boundary condition type |
| **Aquifer Radius** | 8,500 | ft | ±500 ft | Influx calculation |
| **Aquifer Thickness** | 180 | ft | ±20 ft | Volume capacity |
| **Aquifer Porosity** | 18 | % | ±3% | Compressibility calculation |
| **Aquifer Permeability** | 85 | mD | ±25 mD | Influx rate estimation |
| **Water Compressibility** | 3.2×10⁻⁶ | psi⁻¹ | ±0.5×10⁻⁶ | Pressure response |
| **Rock Compressibility** | 4.1×10⁻⁶ | psi⁻¹ | ±0.8×10⁻⁶ | Volume change |

### 6.2 Water Influx Modeling Framework

#### Theoretical Aquifer Models
Material balance validation requires proper aquifer influx modeling without specific production targets:

```
Van Everdingen-Hurst Radial Aquifer Model:

Dimensionless Parameters:
- Radius Ratio (re/rR): Geometry-dependent
- Dimensionless Time: tD = 0.0002367 × k × t / (φ × μ × ct × rR²)
- Water Influx Function: WeD = f(tD, re/rR)

Material Balance Integration:
- Aquifer influx term (We) in material balance equation
- Pressure-dependent influx calculation
- Time-dependent boundary conditions
```

### 6.3 Voidage Replacement Concepts

#### Material Balance Pressure Validation
```
General Voidage Balance Framework:
- Reservoir voidage = Production - Injection ± Compressibility effects
- Pressure response validation through material balance
- Aquifer support quantification for boundary conditions
- Simulation model calibration using pressure trends
```

#### Validation Criteria for Simulation
| Material Balance Component | Simulation Input | Validation Check |
|---------------------------|------------------|------------------|
| **Initial Fluid Volumes** | Grid-based calculation | Volume consistency |
| **Pressure Response** | Aquifer boundary conditions | Pressure trend match |  
| **Phase Behavior** | PVT properties | Laboratory validation |
| **Compressibility Effects** | Rock and fluid properties | Pressure-volume relations |

---

## 7. References and Technical Standards

### 7.1 Reservoir Engineering Standards

#### Industry Guidelines for Reservoir Characterization
- **Material Balance Methods**: Standard practices for reservoir fluid accounting
- **Grid Volume Calculations**: Systematic approaches to bulk and pore volume determination  
- **Property Characterization**: Rock and fluid property uncertainty quantification
- **Simulation Validation**: Quality control frameworks for reservoir models

### 7.2 Material Balance References
- **Dake, L.P.** (1978). *Fundamentals of Reservoir Engineering*. Elsevier.
- **McCain, W.D.** (1990). *The Properties of Petroleum Fluids*. PennWell Books.
- **van Everdingen, A.F. & Hurst, W.** (1949). *Water Influx in Oil Reservoirs*. Trans. AIME.
- **Craft, B.C. & Hawkins, M.F.** (1991). *Applied Petroleum Reservoir Engineering*. Prentice Hall.

### 7.3 Data Quality Standards
- **Core Data**: Laboratory measurements following API RP 40 standards
- **Log Data**: Petrophysical interpretation with uncertainty quantification
- **PVT Data**: Representative fluid sampling and laboratory analysis
- **Pressure Data**: Field measurements with calibrated instrumentation

---

**Document Control:**
- **Created**: January 25, 2025
- **Last Updated**: January 25, 2025  
- **Version**: 2.0 (Reservoir Characterization Focus)
- **Review Status**: Technical Review Complete
- **Approved for**: MRST Simulation Studies & Reservoir Characterization

**Technical Contact:** Reservoir Engineering Team  
**Classification:** Internal Technical Documentation  
**Next Review**: Quarterly (April 2025)

*This reservoir characterization document provides systematic framework for grid volume analysis, pore volume distribution, and material balance validation for Eagle West Field simulation studies. All methodologies follow industry standard practices for reservoir simulation initialization and model validation without predefined volumetric targets or reserves classification.*