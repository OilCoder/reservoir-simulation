# Derived and Calculated Data Catalog

## Overview
This document catalogs all calculated metrics and derived data generated from primary simulation outputs and field measurements. These metrics serve as key performance indicators, machine learning targets, and business intelligence features.

## 1. Material Balance Metrics

### 1.1 Original Oil in Place (OOIP)
- **Formula**: `OOIP = Σ(Pore_Volume × Net_to_Gross × Oil_Saturation × Formation_Volume_Factor)`
- **Input Dependencies**: 
  - Grid porosity and permeability
  - Net-to-gross ratios
  - Initial fluid saturations
  - PVT properties (Bo, Rs)
- **Update Frequency**: Static (calculated once during initialization)
- **ML Relevance**: 
  - Feature for EUR prediction models
  - Normalization factor for recovery calculations
- **Visualization**: Static reservoir maps, volumetric pie charts
- **Units**: STB (stock tank barrels)
- **Typical Range**: 10M - 500M STB (field dependent)

### 1.2 Recovery Factor (RF)
- **Formula**: `RF = Cumulative_Production / OOIP`
- **Input Dependencies**:
  - Cumulative oil production
  - OOIP calculations
- **Update Frequency**: Daily/Monthly
- **ML Relevance**: 
  - Primary target variable for field development optimization
  - Key performance indicator for well placement ML
- **Visualization**: Time series plots, recovery factor maps
- **Units**: Fraction (0-1) or percentage
- **Typical Range**: 0.1 - 0.6 (10% - 60%)

### 1.3 Voidage Replacement Ratio (VRR)
- **Formula**: `VRR = (Water_Injection_Rate + Gas_Injection_Rate) / Oil_Production_Rate`
- **Input Dependencies**:
  - Daily injection rates (water, gas)
  - Daily oil production rates
  - Formation volume factors
- **Update Frequency**: Daily
- **ML Relevance**: 
  - Feature for pressure maintenance predictions
  - Constraint variable in optimization models
- **Visualization**: Time series, pressure-VRR correlation plots
- **Units**: Dimensionless ratio
- **Typical Range**: 0.8 - 1.2 (optimal near 1.0)

## 2. Sweep Efficiency Indicators

### 2.1 Areal Sweep Efficiency (EA)
- **Formula**: `EA = Contacted_Area / Total_Reservoir_Area`
- **Input Dependencies**:
  - Pressure front propagation
  - Well spacing geometry
  - Permeability heterogeneity
- **Update Frequency**: Monthly/Quarterly
- **ML Relevance**: 
  - Feature for infill drilling optimization
  - Target for enhanced recovery screening
- **Visualization**: Areal sweep maps, contour plots
- **Units**: Fraction (0-1)
- **Typical Range**: 0.3 - 0.9

### 2.2 Vertical Sweep Efficiency (EV)
- **Formula**: `EV = Productive_Thickness / Total_Net_Thickness`
- **Input Dependencies**:
  - Layer-by-layer production allocation
  - Completion design (perforations)
  - Vertical permeability distribution
- **Update Frequency**: Monthly/Quarterly
- **ML Relevance**: 
  - Feature for completion optimization ML
  - Input for layer cake model predictions
- **Visualization**: Vertical profiles, layer contribution charts
- **Units**: Fraction (0-1)
- **Typical Range**: 0.4 - 0.8

### 2.3 Volumetric Sweep Efficiency (EV)
- **Formula**: `EV = EA × EV × Microscopic_Displacement_Efficiency`
- **Input Dependencies**:
  - Areal and vertical sweep calculations
  - Residual oil saturation
  - Displacement mechanisms
- **Update Frequency**: Monthly/Quarterly
- **ML Relevance**: 
  - Comprehensive target for EOR screening
  - Feature for ultimate recovery predictions
- **Visualization**: 3D volumetric renderings, efficiency surfaces
- **Units**: Fraction (0-1)
- **Typical Range**: 0.1 - 0.5

## 3. Well Performance Metrics

### 3.1 Productivity Index (PI)
- **Formula**: `PI = Production_Rate / (Reservoir_Pressure - Bottomhole_Pressure)`
- **Input Dependencies**:
  - Well production rates
  - Reservoir pressure measurements
  - Bottomhole pressure (measured or calculated)
- **Update Frequency**: Daily/Weekly
- **ML Relevance**: 
  - Target variable for well performance prediction
  - Feature for artificial lift optimization
- **Visualization**: PI decline curves, pressure-rate plots
- **Units**: STB/day/psi
- **Typical Range**: 0.1 - 50 STB/day/psi

### 3.2 Skin Factor (S)
- **Formula**: `S = 1.151 × [(P1hr - PWF) / (q × log(k×t/(φ×μ×ct×rw²))) - log(k/(φ×μ×ct×rw²)) + 3.23]`
- **Input Dependencies**:
  - Pressure buildup test data
  - Formation properties (k, φ, μ, ct)
  - Well geometry (rw)
- **Update Frequency**: Per well test (quarterly/annually)
- **ML Relevance**: 
  - Feature for stimulation candidate selection
  - Input for well performance forecasting
- **Visualization**: Skin evolution plots, stimulation response charts
- **Units**: Dimensionless
- **Typical Range**: -5 to +20 (negative indicates stimulation)

### 3.3 Well Interference Factor
- **Formula**: `IF = ΔP_observed / ΔP_no_interference`
- **Input Dependencies**:
  - Multi-well pressure test data
  - Individual well drawdown signatures
  - Well spacing and geometry
- **Update Frequency**: Per interference test (annually)
- **ML Relevance**: 
  - Feature for optimal well spacing ML
  - Input for field development sequencing
- **Visualization**: Interference maps, pressure response surfaces
- **Units**: Dimensionless
- **Typical Range**: 1.0 - 3.0

## 4. Connectivity Measures

### 4.1 Flow Allocation Factors
- **Formula**: `FAF_ij = Flow_from_i_to_j / Total_Flow_from_i`
- **Input Dependencies**:
  - Inter-well tracer data
  - Production/injection rate correlations
  - Pressure response analysis
- **Update Frequency**: Semi-annually (with tracer campaigns)
- **ML Relevance**: 
  - Feature for waterflood optimization
  - Target for enhanced connectivity modeling
- **Visualization**: Flow network diagrams, allocation matrices
- **Units**: Fraction (0-1)
- **Typical Range**: 0.05 - 0.4 per connection

### 4.2 Drainage Region Boundaries
- **Formula**: Derived from streamline calculations and pressure interference
- **Input Dependencies**:
  - Streamline simulation results
  - Pressure transient test interpretations
  - Production rate correlations
- **Update Frequency**: Annually or with major development changes
- **ML Relevance**: 
  - Feature for infill drilling location optimization
  - Input for EUR allocation by well
- **Visualization**: Drainage area maps, Voronoi diagrams
- **Units**: Acres or square meters
- **Typical Range**: 40 - 320 acres per well

## 5. Heterogeneity Indices

### 5.1 Dykstra-Parsons Coefficient (VDP)
- **Formula**: `VDP = (k50 - k84.1) / k50`
- **Input Dependencies**:
  - Permeability distribution statistics
  - Log-normal distribution parameters
  - Core and log-derived permeability
- **Update Frequency**: Static (updated with new well data)
- **ML Relevance**: 
  - Feature for sweep efficiency predictions
  - Input for completion design optimization
- **Visualization**: Permeability distribution curves, heterogeneity maps
- **Units**: Dimensionless (0-1)
- **Typical Range**: 0.3 - 0.9 (higher = more heterogeneous)

### 5.2 Lorenz Coefficient
- **Formula**: `LC = Area_between_Lorenz_curve_and_uniform_line / 0.5`
- **Input Dependencies**:
  - Flow capacity vs. storage capacity data
  - Cumulative permeability-thickness product
  - Cumulative porosity-thickness product
- **Update Frequency**: Static (updated with new geological model)
- **ML Relevance**: 
  - Feature for waterflood performance prediction
  - Input for layer management strategies
- **Visualization**: Lorenz curves, flow unit rankings
- **Units**: Dimensionless (0-1)
- **Typical Range**: 0.1 - 0.8

## 6. Production Forecasting Metrics

### 6.1 Decline Rate (Di)
- **Formula**: 
  - Exponential: `q(t) = qi × exp(-Di × t)`
  - Hyperbolic: `q(t) = qi / (1 + b × Di × t)^(1/b)`
- **Input Dependencies**:
  - Historical production data
  - Decline curve analysis parameters
  - Operating conditions stability
- **Update Frequency**: Monthly
- **ML Relevance**: 
  - Primary target for production forecasting ML
  - Feature for well economic evaluation
- **Visualization**: Decline curve overlays, rate-time plots
- **Units**: 1/time (typically 1/year)
- **Typical Range**: 0.05 - 0.5 /year

### 6.2 Estimated Ultimate Recovery (EUR)
- **Formula**: `EUR = Cumulative_Production + ∫[q(t)dt]` from present to economic limit
- **Input Dependencies**:
  - Current cumulative production
  - Decline curve parameters
  - Economic limit assumptions
- **Update Frequency**: Monthly/Quarterly
- **ML Relevance**: 
  - Primary target variable for field development ML
  - Key metric for asset valuation models
- **Visualization**: EUR distribution maps, tornado charts
- **Units**: STB (stock tank barrels)
- **Typical Range**: 50K - 2M STB per well

### 6.3 Time to Economic Limit
- **Formula**: `t_econ = (qi - q_limit) / (Di × qi)` (exponential decline)
- **Input Dependencies**:
  - Current production rate
  - Economic limit rate
  - Decline parameters
- **Update Frequency**: Monthly/Quarterly
- **ML Relevance**: 
  - Feature for abandonment timing optimization
  - Input for portfolio management models
- **Visualization**: Well life expectancy maps, timing histograms
- **Units**: Years or months
- **Typical Range**: 5 - 30 years

## 7. Economic Indicators

### 7.1 Net Present Value (NPV) Metrics
- **Formula**: `NPV = Σ[(Revenue - OPEX - CAPEX) / (1 + r)^t]`
- **Input Dependencies**:
  - Production forecasts
  - Commodity price forecasts
  - Operating and capital cost estimates
  - Discount rate assumptions
- **Update Frequency**: Monthly/Quarterly
- **ML Relevance**: 
  - Ultimate target for field development optimization
  - Feature for project ranking and portfolio management
- **Visualization**: NPV sensitivity charts, project economics dashboards
- **Units**: USD (millions)
- **Typical Range**: -10M to +100M USD per project

### 7.2 Payout Time
- **Formula**: Time when cumulative cash flow = 0
- **Input Dependencies**:
  - Cash flow projections
  - Initial capital investment
  - Operating cost profiles
- **Update Frequency**: Monthly/Quarterly
- **ML Relevance**: 
  - Feature for investment timing optimization
  - Target for fast-payout opportunity screening
- **Visualization**: Payout time maps, cash flow curves
- **Units**: Years or months
- **Typical Range**: 1 - 8 years

### 7.3 Rate of Return (ROR)
- **Formula**: IRR where NPV = 0
- **Input Dependencies**:
  - Complete cash flow profile
  - Investment timing
  - Revenue and cost projections
- **Update Frequency**: Monthly/Quarterly
- **ML Relevance**: 
  - Feature for project comparison and ranking
  - Target for hurdle rate optimization
- **Visualization**: ROR distribution plots, sensitivity analyses
- **Units**: Percentage per year
- **Typical Range**: 10% - 50% per year

## Data Quality and Validation

### Calculation Validation
1. **Mass Balance Checks**: Ensure material balance closure within 2%
2. **Unit Consistency**: Automated unit conversion and validation
3. **Range Validation**: Statistical outlier detection and flagging
4. **Temporal Consistency**: Trend analysis for anomaly detection

### Update Dependencies
- **Real-time Metrics**: PI, VRR, production rates
- **Daily Updates**: Recovery factors, decline rates
- **Monthly Updates**: Sweep efficiencies, EUR estimates
- **Quarterly Updates**: Economic indicators, connectivity measures
- **Annual Updates**: Heterogeneity indices, OOIP revisions

### ML Integration Notes
- All metrics stored with uncertainty quantification
- Feature importance rankings maintained for model selection
- Target variable hierarchies defined for multi-objective optimization
- Correlation matrices updated monthly for feature engineering

### Dashboard Integration
- **Executive Level**: Recovery factors, NPV, EUR
- **Operations Level**: PI, skin factors, sweep efficiencies
- **Engineering Level**: Detailed connectivity and heterogeneity metrics
- **Real-time Monitoring**: Production rates, VRR, pressure responses

---
*Last Updated: 2025-07-28*
*Version: 1.0*
*Maintained by: Reservoir Engineering Team*