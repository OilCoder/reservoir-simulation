# Dynamic Data Inventory

## Overview
This document catalogs all time-varying data generated during reservoir simulation. Dynamic data represents the evolving state of the reservoir system and is critical for machine learning model training, real-time monitoring, and decision support systems.

## Mathematical Foundations

The dynamic data inventory is governed by fundamental conservation principles:

**Conservation Equations:**
$\frac{\partial}{\partial t}(\phi \rho S) + \nabla \cdot (\rho \vec{v}) = Q$

where:
- $\phi$ = porosity
- $\rho$ = fluid density  
- $S$ = phase saturation
- $\vec{v}$ = Darcy velocity vector
- $Q$ = source/sink terms

**Phase Balance Constraint:**
$S_o + S_w + S_g = 1$

where $S_o$, $S_w$, and $S_g$ represent oil, water, and gas saturations respectively.

## Data Categories

### 1. Reservoir State Arrays

#### 1.1 Primary State Variables

**Pressure Field (`PRESSURE`)**
- **Structure**: 3D array [nx, ny, nz] per timestep
- **Units**: psia or bar
- **Update Frequency**: Every timestep
- **ML Applications**: 
  - Pressure transient analysis
  - Flow pattern identification
  - Well interference detection
  - Aquifer strength characterization

**Oil Saturation (`SOIL`)**
- **Structure**: 3D array [nx, ny, nz] per timestep
- **Units**: Fraction (0-1)
- **Update Frequency**: Every timestep
- **Storage Optimization**: Can be derived from SWAT and SGAS
- **ML Applications**:
  - Sweep efficiency analysis
  - Remaining oil identification
  - Breakthrough prediction

**Water Saturation (`SWAT`)**
- **Structure**: 3D array [nx, ny, nz] per timestep
- **Units**: Fraction (0-1)
- **Update Frequency**: Every timestep
- **Critical for**: Water cut prediction, flood front tracking

**Gas Saturation (`SGAS`)**
- **Structure**: 3D array [nx, ny, nz] per timestep
- **Units**: Fraction (0-1)
- **Update Frequency**: Every timestep
- **Applications**: Gas cap expansion, solution gas evolution

#### 1.2 PVT State Variables

**Solution Gas-Oil Ratio (`RS`)**
- **Structure**: 3D array [nx, ny, nz] per timestep
- **Units**: scf/STB or sm³/sm³
- **Update Frequency**: Every timestep for black oil models
- **Dependency**: Function of pressure and oil composition
- **ML Features**: Bubble point tracking, gas liberation patterns

**Vaporized Oil-Gas Ratio (`RV`)**
- **Structure**: 3D array [nx, ny, nz] per timestep
- **Units**: STB/MMscf or sm³/sm³
- **Update Frequency**: Every timestep (volatile oil systems)
- **Applications**: Retrograde condensation, rich gas systems

**Temperature (`TEMP`)**
- **Structure**: 3D array [nx, ny, nz] per timestep
- **Units**: °F or °C
- **Update Frequency**: Every timestep (thermal models)
- **Storage**: Required for thermal EOR, SAGD operations
- **ML Applications**: Heat front tracking, steam chamber evolution

### 2. Well Solutions

#### 2.1 Production Data

**Well Oil Rate (`WOPR`)**
- **Structure**: Array [nwells] per timestep
- **Units**: STB/day or sm³/day
- **Update Frequency**: Every timestep
- **Aggregation Options**: Hourly, daily, monthly averages
- **Real-time Requirement**: Critical for production optimization

**Well Water Rate (`WWPR`)**
- **Structure**: Array [nwells] per timestep
- **Units**: STB/day or sm³/day
- **ML Applications**: Water cut prediction, breakthrough timing

**Well Gas Rate (`WGPR`)**
- **Structure**: Array [nwells] per timestep
- **Units**: Mscf/day or sm³/day
- **Features**: GOR trends, gas breakthrough detection

**Well Liquid Rate (`WLPR`)**
- **Structure**: Array [nwells] per timestep
- **Units**: STB/day or sm³/day
- **Calculation**: WOPR + WWPR
- **Dashboard**: Primary production monitoring metric

#### 2.2 Injection Data

**Water Injection Rate (`WWIR`)**
- **Structure**: Array [nwells] per timestep
- **Units**: STB/day or sm³/day
- **Control**: Voidage replacement, pressure maintenance

**Gas Injection Rate (`WGIR`)**
- **Structure**: Array [nwells] per timestep
- **Units**: Mscf/day or sm³/day
- **Applications**: Gas lift, pressure maintenance, EOR

#### 2.3 Well Pressures

**Bottom Hole Pressure (`WBHP`)**
- **Structure**: Array [nwells] per timestep
- **Units**: psia or bar
- **Update Frequency**: Every timestep
- **ML Features**: Well performance analysis, drawdown calculation

**Tubing Head Pressure (`WTHP`)**
- **Structure**: Array [nwells] per timestep
- **Units**: psia or bar
- **Applications**: Surface facility constraints, flow assurance

#### 2.4 Derived Well Metrics

**Water Cut (`WWCT`)**
- **Structure**: Array [nwells] per timestep
- **Units**: Fraction (0-1)
- **Calculation**: WWPR / (WOPR + WWPR)
- **ML Priority**: High - primary prediction target

**Gas-Oil Ratio (`WGOR`)**
- **Structure**: Array [nwells] per timestep
- **Units**: scf/STB or sm³/sm³
- **Calculation**: WGPR / WOPR
- **Trend Analysis**: Solution gas vs. free gas production

**Well Productivity Index (`WPI`)**
- **Structure**: Array [nwells] per timestep
- **Units**: STB/day/psi or sm³/day/bar
- **Calculation**: Rate / (Reservoir Pressure - BHP)
- **ML Applications**: Well performance degradation prediction

### 3. Inter-cell Fluxes

#### 3.1 Oil Flow Rates

**X-Direction Oil Flux (`FLOIXI+`)**
- **Structure**: 3D array [nx-1, ny, nz] per timestep
- **Units**: STB/day or sm³/day
- **Applications**: Flow path visualization, sweep efficiency

**Y-Direction Oil Flux (`FLOIYJ+`)**
- **Structure**: 3D array [nx, ny-1, nz] per timestep
- **ML Features**: Anisotropy effects, compartmentalization

**Z-Direction Oil Flux (`FLOIZK+`)**
- **Structure**: 3D array [nx, ny, nz-1] per timestep
- **Critical for**: Gravity segregation, vertical sweep

#### 3.2 Water Flow Rates

**X-Direction Water Flux (`FLOWIXI+`)**
- **Structure**: 3D array [nx-1, ny, nz] per timestep
- **Applications**: Water front tracking, fingering detection

**Y-Direction Water Flux (`FLOWIYJ+`)**
- **Structure**: 3D array [nx, ny-1, nz] per timestep

**Z-Direction Water Flux (`FLOWIZK+`)**
- **Structure**: 3D array [nx, ny, nz-1] per timestep

#### 3.3 Gas Flow Rates

**X-Direction Gas Flux (`FLGAXI+`)**
- **Structure**: 3D array [nx-1, ny, nz] per timestep
- **Units**: Mscf/day or sm³/day

**Y-Direction Gas Flux (`FLGAYJ+`)**
- **Structure**: 3D array [nx, ny-1, nz] per timestep

**Z-Direction Gas Flux (`FLGAZK+`)**
- **Structure**: 3D array [nx, ny, nz-1] per timestep

### 4. Phase Presence Indicators

#### 4.1 Phase State Arrays

**Oil Phase Present (`POIL`)**
- **Structure**: 3D boolean array [nx, ny, nz] per timestep
- **Update**: When saturation > residual

**Water Phase Present (`PWAT`)**
- **Structure**: 3D boolean array [nx, ny, nz] per timestep
- **Applications**: Connate water regions, water invasion zones

**Gas Phase Present (`PGAS`)**
- **Structure**: 3D boolean array [nx, ny, nz] per timestep
- **Critical for**: Gas cap tracking, solution gas evolution

#### 4.2 Phase Transition Tracking

**Bubble Point Cells (`PBUB`)**
- **Structure**: 3D boolean array [nx, ny, nz] per timestep
- **Indicates**: Cells at bubble point pressure
- **ML Applications**: Gas liberation prediction

**Dew Point Cells (`PDEW`)**
- **Structure**: 3D boolean array [nx, ny, nz] per timestep
- **Applications**: Retrograde condensation regions

### 5. Mobility and Transmissibility Updates

#### 5.1 Phase Mobilities

**Oil Mobility (`MOBILO`)**
- **Structure**: 3D array [nx, ny, nz] per timestep
- **Units**: mD/cp or similar
- **Calculation**: krₒ/μₒ
- **Update Frequency**: Every timestep

**Water Mobility (`MOBILW`)**
- **Structure**: 3D array [nx, ny, nz] per timestep
- **Calculation**: krw/μw

**Gas Mobility (`MOBILG`)**
- **Structure**: 3D array [nx, ny, nz] per timestep
- **Calculation**: krg/μg

#### 5.2 Transmissibility Updates

**X-Direction Transmissibility (`TRANXI+`)**
- **Structure**: 3D array [nx-1, ny, nz] per timestep
- **Updates**: Pressure-dependent permeability, geomechanics

**Y-Direction Transmissibility (`TRANYJ+`)**
- **Structure**: 3D array [nx, ny-1, nz] per timestep

**Z-Direction Transmissibility (`TRANZK+`)**
- **Structure**: 3D array [nx, ny, nz-1] per timestep

### 6. Material Balance Tracking

#### 6.1 Field-Level Material Balance

**Field Oil In Place (`FOIP`)**
- **Structure**: Scalar per timestep
- **Units**: STB or sm³
- **Update Frequency**: Every reporting step
- **ML Applications**: Recovery factor prediction

**Field Water In Place (`FWIP`)**
- **Structure**: Scalar per timestep
- **Components**: Original + injected water

**Field Gas In Place (`FGIP`)**
- **Structure**: Scalar per timestep
- **Components**: Free gas + solution gas

#### 6.2 Regional Material Balance

**Region Oil In Place (`ROIP`)**
- **Structure**: Array [nregions] per timestep
- **Applications**: Compartment-specific recovery tracking

**Region Pressure (`RPR`)**
- **Structure**: Array [nregions] per timestep
- **Calculation**: Pore volume weighted average

#### 6.3 Well-Based Material Balance

**Well Drainage Volume (`WDV`)**
- **Structure**: Array [nwells] per timestep
- **Estimation**: Based on well allocation factors
- **ML Features**: Well interference quantification

## Storage Optimization Strategies

### 1. Compression Techniques

**Array Compression**
- **Method**: HDF5 with GZIP compression
- **Ratio**: Typically 3:1 to 5:1 for reservoir arrays
- **Trade-off**: CPU time vs. storage space

**Precision Reduction**
- **Single Precision**: Sufficient for most applications
- **Half Precision**: Possible for certain arrays (saturations)

### 2. Selective Storage

**Reporting Steps Only**
- **Frequency**: Monthly or quarterly snapshots
- **Storage Reduction**: 90% for monthly reporting
- **Applications**: Long-term trend analysis

**Critical Cells Only**
- **Selection**: Producer drainage areas, high-permeability paths
- **Reduction**: 70-80% storage savings
- **Applications**: Real-time optimization

### 3. Adaptive Resolution

**Temporal Adaptive**
- **High Frequency**: During critical periods (breakthrough)
- **Low Frequency**: Stable production periods
- **Implementation**: Automatic based on rate of change

**Spatial Adaptive**
- **High Resolution**: Near wellbores, fractures
- **Low Resolution**: Low-permeability regions
- **Method**: Upscaling/downscaling based on gradients

## Aggregation Options

### 1. Temporal Aggregation

**Hourly Averages**
- **Applications**: Real-time optimization
- **Storage**: 24 values per day
- **ML Training**: Short-term pattern recognition

**Daily Averages**
- **Standard**: Most common for production data
- **Calculation**: Flow-rate weighted for rates, simple average for pressures
- **Dashboard**: Primary frequency for operations

**Monthly Summaries**
- **Applications**: Long-term planning, reserves estimation
- **Metrics**: Total production, average rates, end-of-month values
- **Reporting**: Regulatory requirements

### 2. Spatial Aggregation

**Well-Based Aggregation**
- **Drainage Radius**: Cells within specified distance
- **Weighting**: Distance-based or flow-based
- **Applications**: Well-centric ML models

**Region-Based Aggregation**
- **Geological Regions**: Based on rock properties
- **Production Regions**: Based on well patterns
- **Flow Regions**: Based on streamline analysis

**Layer-Based Aggregation**
- **Vertical Averaging**: By geological layers
- **Applications**: Layer-specific recovery analysis
- **Weighting**: Pore volume or permeability-based

## ML Feature Engineering Possibilities

### 1. Time Series Features

**Trend Analysis**
- **Rate of Change**: First derivatives for all time series
- **Acceleration**: Second derivatives for key variables
- **Moving Averages**: 7-day, 30-day, 90-day windows

**Seasonality Detection**
- **Periodic Patterns**: Monthly, quarterly cycles
- **Fourier Transform**: Frequency domain analysis
- **Applications**: Production optimization, maintenance scheduling

**Lag Features**
- **Historical Values**: 1-day, 7-day, 30-day lags
- **Cross-Correlation**: Between different variables
- **Applications**: Cause-effect relationship modeling

### 2. Spatial Features

**Gradient Calculations**
- **Pressure Gradients**: ∇P in x, y, z directions
- **Saturation Gradients**: ∇Sw for front tracking
- **Applications**: Flow direction prediction

**Neighbor Statistics**
- **Local Averages**: Mean values in 3×3×3 neighborhood
- **Local Variance**: Heterogeneity indicators
- **Applications**: Upscaling, pattern recognition

**Distance Features**
- **Distance to Wells**: Producer/injector proximity
- **Distance to Boundaries**: Fault, aquifer boundaries
- **Path Distance**: Along preferential flow paths

### 3. Physics-Based Features

**Darcy Velocity**
- **Calculation**: v = -k∇P/μ
- **Components**: vₓ, vᵧ, v_z
- **Applications**: Streamline analysis, flow visualization

**Capillary Number**
- **Definition**: Nc = μv/σ
- **Applications**: Relative permeability scaling
- **ML Target**: Microscopic displacement efficiency

**Mobility Ratio**
- **Definition**: M = λ_displacing/λ_displaced
- **Applications**: Sweep efficiency prediction
- **Critical Values**: M > 1 indicates unfavorable mobility

### 4. Well Performance Features

**Productivity Index Trends**
- **Calculation**: PI = q/(Pr - Pwf)
- **Trends**: Decline curves, step changes
- **Applications**: Well integrity assessment

**Drainage Area Evolution**
- **Dynamic Estimation**: Based on pressure interference
- **Allocation Factors**: Well-to-well connectivity
- **Applications**: Infill drilling optimization

**Water Cut Acceleration**
- **Second Derivative**: d²(WC)/dt²
- **Critical Indicator**: Rapid water breakthrough
- **Applications**: Workover timing optimization

## Real-Time Dashboard Requirements

### 1. High-Frequency Data (Every 15 minutes)

**Well Production Rates**
- **Update**: Real-time from SCADA
- **Display**: Current + 24-hour trend
- **Alerts**: Rate deviations > 10%

**Well Pressures**
- **Sources**: Downhole gauges, surface measurements
- **Processing**: Noise filtering, outlier detection
- **Visualization**: Pressure maps, trend plots

### 2. Medium-Frequency Data (Every Hour)

**Field Totals**
- **Aggregation**: Sum of all active wells
- **Metrics**: Oil, water, gas, liquid rates
- **Comparison**: Against targets, forecasts

**Water Cut Monitoring**
- **Calculation**: Instantaneous and 24-hour average
- **Trend Analysis**: Rate of increase, breakthrough detection
- **Alerts**: Sudden increases, approaching limits

### 3. Low-Frequency Data (Daily)

**Material Balance Updates**
- **Recovery Factors**: Oil, gas by region
- **Remaining Reserves**: Current estimates
- **Depletion Maps**: Pressure, saturation changes

**Performance Indicators**
- **Well Productivity**: PI trends, decline analysis
- **Sweep Efficiency**: Pattern-based analysis
- **Energy Efficiency**: Injection/production ratios

### 4. Dashboard Architecture

**Data Pipeline**
- **Ingestion**: Real-time + batch processing
- **Storage**: Time-series database (InfluxDB, TimescaleDB)
- **Processing**: Stream processing (Apache Kafka, Apache Flink)

**Visualization Layers**
- **Operational**: Real-time monitoring, alarms
- **Tactical**: Weekly/monthly performance review
- **Strategic**: Long-term trend analysis, planning

**User Interfaces**
- **Operations Center**: Large displays, overview dashboards
- **Field Personnel**: Mobile-friendly, key metrics
- **Management**: Executive summaries, KPIs

## Data Quality and Validation

### 1. Quality Metrics

**Completeness**
- **Target**: >95% data availability
- **Measurement**: Missing value percentage
- **Actions**: Interpolation, estimation methods

**Accuracy**
- **Validation**: Against measured data, material balance
- **Tolerance**: ±5% for production rates, ±2% for pressures
- **Monitoring**: Statistical process control

**Consistency**
- **Cross-Validation**: Between different data sources
- **Temporal**: Trend continuity, physical constraints
- **Spatial**: Neighboring cell relationships

### 2. Automated Validation

**Range Checks**
- **Physical Limits**: 0 ≤ Saturations ≤ 1
- **Operational Limits**: Maximum rates, pressures
- **Historical Ranges**: Statistical outlier detection

**Mass Balance Validation**
- **Field Level**: Total production vs. reserves depletion
- **Well Level**: Allocation factor consistency
- **Temporal**: Rate integration vs. cumulative production

**Relationship Validation**
- **PVT Consistency**: Rs vs. pressure relationships
- **Relative Permeability**: Kr curves vs. saturation
- **Well Performance**: PI vs. reservoir pressure

## Implementation Priorities

### Phase 1: Core Dynamic Data (Months 1-3)
- Reservoir state arrays (P, Sw, So, Sg)
- Well production/injection rates
- Basic material balance tracking

### Phase 2: Advanced Dynamics (Months 4-6)
- Inter-cell fluxes
- Phase presence indicators
- Mobility calculations

### Phase 3: ML-Ready Features (Months 7-9)
- Feature engineering pipeline
- Aggregation options
- Time series analysis tools

### Phase 4: Real-Time Integration (Months 10-12)
- Dashboard development
- Real-time data ingestion
- Automated quality control

## Storage Considerations

### Typical Field (200,000 cells, 50 wells, 10-year simulation)

**Full Resolution (Every Timestep)**
- All reservoir state arrays stored per timestep
- Complete well data history
- Full inter-cell flux data
- Comprehensive temporal resolution

**Optimized Storage (Monthly Reporting)**
- Reservoir arrays at reduced frequency
- Well data maintained at full resolution
- Flux data at reporting intervals
- Balanced resolution for analysis needs

**Real-Time Dashboard**
- Current state snapshot
- Rolling historical window
- Processed feature sets
- Active data for monitoring

This comprehensive inventory provides the foundation for building robust ML pipelines and real-time monitoring systems for reservoir simulation data.