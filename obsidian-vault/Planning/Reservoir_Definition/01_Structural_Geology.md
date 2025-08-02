# Structural Geology - Eagle West Field

## Executive Summary

The Eagle West Field is a structural-stratigraphic hydrocarbon accumulation located on the offshore continental shelf. The field exhibits a 4-way dip closure bounded by 5 major fault systems, creating a compartmentalized reservoir with significant structural complexity. The main reservoir interval occurs at approximately 7,900 ft TVDSS at the structural crest, with a gross thickness of 238 ft and net pay of 125 ft cumulative.

## 1. Regional Geological Setting

### 1.1 Depositional Environment
- **Age**: Miocene epoch (23.0-5.3 Ma)
- **Setting**: Offshore continental shelf environment
- **Depositional System**: Deltaic to shallow marine transition
- **Facies Association**: Delta front to shoreface sandstones with interbedded marine shales

### 1.2 Tectonic Framework
- **Regional Structure**: Part of extensional fault system related to post-rift thermal subsidence
- **Structural Style**: Growth fault-bounded tilted blocks with rollover anticlines
- **Fault Orientation**: Predominantly NE-SW trending normal faults
- **Regional Dip**: 2-4° southeastward into basin center

### 1.3 Stratigraphic Context
- **Formation**: Eagle West Sand Member
- **Sequence**: Third-order depositional sequence within transgressive systems tract
- **Regional Correlation**: Correlates with productive intervals in adjacent fields
- **Seal Rock**: Overlying marine shale unit (40-60 ft thick)

## 2. Structural Framework

### 2.1 Overall Structure Type
- **Primary Trap**: Faulted anticline with 4-way dip closure
- **Trap Category**: Structural-stratigraphic combination trap
- **Closure Area**: Approximately 2,600 acres at spill point [CORRECTED for consistency]
- **Structural Relief**: 340 ft from crest to spill point

### 2.2 Major Fault Systems

#### Fault A (Northern Boundary)
- **Orientation**: N65°E, dip 70° SE
- **Throw**: 120-180 ft (variable along strike)
- **Length**: 3.2 miles
- **Type**: Normal fault with minor reverse component
- **Sealing Character**: Likely sealing based on shale gouge ratio >20%

#### Fault B (Eastern Boundary)
- **Orientation**: N20°E, dip 65° NW
- **Throw**: 80-140 ft
- **Length**: 2.8 miles
- **Type**: Normal fault
- **Sealing Character**: Partially sealing, potential for across-fault communication

#### Fault C (Southern Boundary)
- **Orientation**: N75°W, dip 62° NE
- **Throw**: 95-160 ft
- **Length**: 2.1 miles
- **Type**: Normal fault
- **Sealing Character**: Sealing in central portion, possibly leaking at terminations

#### Fault D (Western Boundary)
- **Orientation**: N15°W, dip 68° NE
- **Throw**: 110-200 ft
- **Length**: 2.5 miles
- **Type**: Normal fault with growth fault characteristics
- **Sealing Character**: Good sealing capacity throughout

#### Fault E (Internal Fault)
- **Orientation**: N45°E, dip 72° SE
- **Throw**: 40-80 ft
- **Length**: 1.6 miles
- **Type**: Normal fault (internal compartmentalization)
- **Sealing Character**: Partially sealing, creates northern compartment

### 2.3 Compartmentalization Analysis

#### Northern Compartment
- **Area**: 980 acres
- **Bounded by**: Faults A, E, and portions of B and D
- **Structural High**: 7,900 ft TVDSS
- **Average Dip**: 3.2° SE

#### Southern Compartment
- **Area**: 1,870 acres
- **Bounded by**: Faults C, E, and portions of B and D
- **Structural High**: 7,920 ft TVDSS
- **Average Dip**: 2.8° NE

### 2.4 Structural Trap Description
- **Trap Geometry**: Asymmetric anticline with steeper eastern flank
- **Closure Mechanism**: Structural dip with fault-bounded limits
- **Four-way Closure**: Confirmed by seismic interpretation and well control
- **Spill Point**: Located at southeastern structural nose at 8,240 ft TVDSS

## 3. Grid Design for MRST

### 3.1 Optimal Grid Dimensions
- **Field Extent**: 3280 ft (E-W) × 2950 ft (N-S) [0.62 × 0.56 miles]
- **Grid Origin**: UTM Zone 15N, Easting: 745,280 m, Northing: 3,258,470 m
- **Grid Orientation**: N15°E (aligned with dominant fault trend)
- **Total Grid Cells**: 40 × 40 × 12 (I × J × K) = 19,200 active cells

### 3.2 Cell Size Recommendations

#### Areal Grid Resolution
- **Standard Cell Size**: 82 ft × 74 ft (25.0 m × 22.6 m)
- **Near-fault Refinement**: 41 ft × 37 ft within 200 ft of major faults
- **Well Area Refinement**: 20 ft × 18 ft within 150 ft radius of wellbores
- **Total Active Cells**: 19,200 (optimized for numerical stability)

#### Vertical Grid Resolution
- **Layer Thickness**: Average 8.3 ft per layer (100 ft gross / 12 layers)
- **Minimum Layer Thickness**: 6 ft (thin flow units)
- **Maximum Layer Thickness**: 12 ft (thick flow units)
- **Total Layers**: 12 (representing major flow units)
- **Aspect Ratio**: 9.9 (82 ft / 8.3 ft) - within recommended limit of ≤10

### 3.3 Local Grid Refinement Needs

#### Near-Fault Areas
- **Refinement Zone**: 300 ft buffer around Faults A, B, C, D
- **Cell Size**: 25 ft × 25 ft × 4 ft
- **Purpose**: Accurate fault transmissibility modeling
- **Implementation**: Local grid refinement (LGR) blocks

#### Well Drainage Areas
- **Refinement Zone**: 250 ft radius around each wellbore
- **Cell Size**: 12.5 ft × 12.5 ft × 4 ft
- **Purpose**: Near-wellbore flow modeling and rate allocation
- **Transition**: Smooth transition to coarser parent grid

### 3.4 Handling of Faults in Simulation

#### Fault Representation
- **Method**: Explicit fault plane representation using MRST fault processing
- **Fault Cells**: Inactive cells along fault planes
- **Transmissibility**: Fault-dependent multipliers based on sealing analysis
- **Fault Properties**: Assigned based on fault throw and shale content

#### Fault Transmissibility Multipliers
- **Fault A**: 0.001-0.01 (highly sealing)
- **Fault B**: 0.01-0.1 (moderately sealing)
- **Fault C**: 0.001-0.05 (variable sealing)
- **Fault D**: 0.001-0.01 (highly sealing)
- **Fault E**: 0.1-0.5 (partially sealing)

## 4. Depth Structure Details

### 4.1 Top Structure Mapping
- **Structural Crest**: 7,900 ft TVDSS (Northern Compartment)
- **Secondary High**: 7,920 ft TVDSS (Southern Compartment)
- **Structural Low**: 8,240 ft TVDSS (spill point)
- **Contour Interval**: 20 ft for detailed mapping
- **Datum**: Mean Sea Level (MSL)

### 4.2 Structural Relief and Dip Angles

#### Regional Dip Patterns
- **Northern Flank**: 2.5-4.2° southward
- **Eastern Flank**: 4.8-6.1° westward (steepest)
- **Southern Flank**: 3.1-4.7° northward
- **Western Flank**: 2.8-3.9° eastward

#### Local Structural Features
- **Structural Terraces**: Present on western and southern flanks
- **Rollover Structure**: Minor rollover into Fault D
- **Nose Features**: Structural noses extending southeast and southwest

### 4.3 Fault Throw Analysis

#### Fault Throw Distribution
- **Maximum Throw**: 200 ft (Fault D, central portion)
- **Minimum Throw**: 40 ft (Fault E, terminations)
- **Average Throw**: 125 ft (across all major faults)
- **Throw Variation**: Systematic along-strike changes

#### Fault Displacement Patterns
- **Growth Fault Character**: Evidence of syn-depositional movement on Fault D
- **Displacement Transfer**: Throw transfer between fault segments
- **Fault Interactions**: Complex interactions at fault intersections

### 4.4 Spill Point Analysis
- **Primary Spill Point**: 8,240 ft TVDSS (southeastern structural nose)
- **Secondary Spill**: 8,260 ft TVDSS (southwestern nose)
- **Closure Volume**: 45.2 million barrels gross rock volume to spill
- **Risk Assessment**: High confidence in structural closure

## 5. 3D Reservoir Architecture

### 5.1 Gross Reservoir Dimensions
- **Gross Thickness**: 100 ft (average across field, typical for Miocene offshore sandstone)
- **Thickness Variation**: 85-120 ft (structural control on deposition)
- **Areal Extent**: 2,600 acres at reservoir level
- **Gross Rock Volume**: 1.13 billion ft³

### 5.2 Net Pay Distribution
- **Net Pay**: 65 ft cumulative (65% net-to-gross, typical for offshore deltaic sandstone)
- **Pay Thickness Range**: 50-80 ft across field
- **Thickest Pay**: Northern compartment structural high
- **Thinnest Pay**: Fault-bounded edges and structural flanks

#### Net Pay by Compartment
- **Northern Compartment**: 72 ft average net pay
- **Southern Compartment**: 58 ft average net pay
- **Fault-bounded Areas**: 45 ft average net pay

### 5.3 Layer Connectivity

#### Flow Unit Architecture
- **Major Flow Units**: 12 primary flow units (FU-1 through FU-12)
- **Layer Continuity**: Good lateral continuity within compartments
- **Vertical Communication**: Moderate, limited by shale interbeds
- **Flow Unit Thickness**: 6-12 ft per unit (average 8.3 ft)
- **Barrier Beds**: 1-3 ft thin shale intervals at FU boundaries

#### Connectivity Analysis
- **Intra-compartment**: High connectivity (>80% sand connectivity)
- **Inter-compartment**: Limited by Fault E (10-30% connectivity)
- **Vertical Flow**: Moderate vertical permeability (Kv/Kh = 0.15-0.25)

### 5.4 Structural Uncertainty

#### Sources of Uncertainty
- **Fault Sealing**: ±20% uncertainty in transmissibility multipliers
- **Structural Depth**: ±10 ft at well control, ±25 ft between wells
- **Compartmentalization**: 15% probability of additional compartments
- **Spill Point**: ±15 ft uncertainty in closure definition

#### Uncertainty Impact on Reserves
- **P90 Structural Case**: Conservative fault sealing, deeper spill point
- **P50 Structural Case**: Most likely interpretation
- **P10 Structural Case**: Optimistic fault leakage, shallow spill point
- **Sensitivity Range**: 25% variation in structural reserves

## Key Implications for MRST Simulation

1. **Grid Design**: Implement multi-scale grid with fault-area refinement
2. **Fault Modeling**: Use explicit fault representation with calibrated transmissibility
3. **Compartmentalization**: Model as two primary compartments with limited communication
4. **Uncertainty**: Run multiple structural realizations for uncertainty quantification
5. **History Matching**: Focus on inter-compartment communication and fault sealing
6. **Development Strategy**: Consider compartment-specific development schemes

## Data Sources and Validation

- **Seismic Data**: 3D seismic survey (2019) with fault interpretation
- **Well Control**: 12 penetrations with structural tops and fault cuts
- **Analog Studies**: Regional fault seal analysis and structural comparisons
- **Petrophysical Data**: Core and log analysis for structural validation
- **Pressure Data**: Pre-production pressure gradients confirming compartmentalization

---

*Document prepared for MRST reservoir simulation setup and development planning.*
*Last updated: 2025-01-25*