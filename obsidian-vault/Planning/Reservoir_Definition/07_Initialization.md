# 07_Initialization - Eagle West Field

## Table of Contents
1. [Equilibration Methodology](#equilibration-methodology)
2. [Fluid Contacts](#fluid-contacts)
3. [Initial Saturation Distribution](#initial-saturation-distribution)
4. [Pressure Initialization](#pressure-initialization)
5. [Aquifer Characterization](#aquifer-characterization)
6. [MRST Initialization Setup](#mrst-initialization-setup)
7. [Validation and Quality Control](#validation-and-quality-control)

## Equilibration Methodology

### MRST Equilibration Approach

The Eagle West Field initialization follows MRST's gravity-capillary equilibrium approach using the `initEclipseState` function. This methodology ensures physically consistent initial conditions by solving for hydrostatic equilibrium with capillary pressure effects.

#### Key Principles:
- **Gravity-Capillary Equilibrium**: Balances gravitational forces with capillary pressure
- **Datum-Based Initialization**: Single reference point for pressure initialization
- **Phase Equilibrium**: Ensures thermodynamic consistency between phases

#### Datum Parameters:
- **Datum Depth**: 8,000 ft TVDSS (True Vertical Depth Sub-Sea)
- **Initial Pressure**: 2,900 psi at datum
- **Reference Phase**: Oil phase (undersaturated)

```matlab
% MRST Equilibration Setup
datum_depth = 8000;  % ft TVDSS
datum_pressure = 2900;  % psi
reference_phase = 'oil';

% Convert to metric units for MRST
datum_depth_m = datum_depth * 0.3048;  % meters
datum_pressure_Pa = datum_pressure * 6894.76;  % Pascal
```

## Fluid Contacts

### Contact Definitions

#### Oil-Water Contact (OWC)
- **Depth**: 8,150 ft TVDSS
- **Structural Control**: Spill point controlled
- **Uncertainty**: ±10 ft (95% confidence)
- **Evidence**: Well logs, RFT data, production history

#### Gas-Oil Contact
- **Status**: No GOC present
- **Reason**: Oil is undersaturated at initial conditions
- **Bubble Point**: Below initial reservoir pressure

#### Transition Zone Characteristics
- **Thickness**: 50 ft
- **Top**: 8,100 ft TVDSS (50 ft above OWC)
- **Bottom**: 8,200 ft TVDSS (50 ft below OWC)
- **Capillary Pressure Controlled**: Yes

```matlab
% Contact Definition for MRST
contacts = struct();
contacts.OWC = 8150 * 0.3048;  % Convert to meters
contacts.GOC = [];  % No gas cap
contacts.transition_zone = 50 * 0.3048;  % 50 ft thick

% Contact uncertainty for sensitivity analysis
contacts.OWC_uncertainty = 10 * 0.3048;  % ±10 ft
```

### Contact Validation Data

| Well | OWC Depth (ft TVDSS) | Evidence | Quality |
|------|----------------------|----------|---------|
| EW-01 | 8,148 | RFT, Log | High |
| EW-02 | 8,152 | RFT, Log | High |
| EW-03 | 8,149 | Log only | Medium |
| EW-04 | 8,151 | Production | Medium |

## Initial Saturation Distribution

### Above Oil-Water Contact
- **Oil Saturation (So)**: 0.80
- **Water Saturation (Sw)**: 0.20 (connate water)
- **Gas Saturation (Sg)**: 0.00 (undersaturated oil)

### Transition Zone
Saturation distribution governed by capillary pressure curves:

```matlab
% Capillary pressure function for transition zone
function Sw = calc_transition_saturation(depth, owc_depth, Pc_params)
    % Brooks-Corey capillary pressure model
    height = owc_depth - depth;  % Height above OWC
    
    if height <= 0
        Sw = 1.0;  % Below OWC - fully water saturated
    else
        % Capillary pressure calculation
        Pc = Pc_params.rho_diff * 9.81 * height;  % Pa
        
        % Normalize capillary pressure
        Pc_norm = Pc / Pc_params.entry_pressure;
        
        % Brooks-Corey saturation
        if Pc_norm > 1.0
            Se = Pc_norm^(-Pc_params.lambda);
            Sw = Pc_params.Swi + Se * (1 - Pc_params.Swi);
        else
            Sw = 1.0;
        end
    end
    
    % Ensure physical bounds
    Sw = max(Pc_params.Swi, min(1.0, Sw));
end
```

### Below Oil-Water Contact
- **Water Saturation (Sw)**: 1.00
- **Oil Saturation (So)**: 0.00
- **Residual Oil**: Sor = 0.15 (post-imbibition)

### 3D Saturation Initialization Maps

```matlab
% Initialize 3D saturation field
function [Sw, So] = initialize_saturations(G, rock, contacts, fluid_props)
    % Get cell centroids
    centroids = G.cells.centroids;
    depths = centroids(:,3);  % Assuming z is depth
    
    % Initialize saturation arrays
    Sw = zeros(G.cells.num, 1);
    So = zeros(G.cells.num, 1);
    
    % Loop through each cell
    for i = 1:G.cells.num
        depth = depths(i);
        
        if depth < contacts.OWC - contacts.transition_zone/2
            % Above transition zone
            Sw(i) = 0.20;  % Connate water
            So(i) = 0.80;  % Oil
        elseif depth > contacts.OWC + contacts.transition_zone/2
            % Below transition zone
            Sw(i) = 1.00;  % Water zone
            So(i) = 0.00;  % No oil
        else
            % In transition zone
            Sw(i) = calc_transition_saturation(depth, contacts.OWC, fluid_props.Pc);
            So(i) = 1.0 - Sw(i);
        end
    end
end
```

## Pressure Initialization

### Hydrostatic Pressure Gradient
- **Oil Gradient**: 0.350 psi/ft (density: 0.81 g/cm³)
- **Water Gradient**: 0.433 psi/ft (density: 1.0 g/cm³)
- **Formation Water Salinity**: 80,000 ppm NaCl

### Initial Pressure by Layer

| Layer | Depth Range (ft TVDSS) | Initial Pressure (psi) | Gradient (psi/ft) |
|-------|------------------------|------------------------|-------------------|
| 1 | 7,800 - 7,850 | 2,830 - 2,847 | 0.350 |
| 2 | 7,850 - 7,900 | 2,847 - 2,865 | 0.350 |
| 3 | 7,900 - 7,950 | 2,865 - 2,882 | 0.350 |
| 4 | 7,950 - 8,000 | 2,882 - 2,900 | 0.350 |
| 5 | 8,000 - 8,050 | 2,900 - 2,917 | 0.350 |
| 6 | 8,050 - 8,100 | 2,917 - 2,935 | 0.350 |
| 7 | 8,100 - 8,150 | 2,935 - 2,952 | 0.350 |
| 8 | 8,150 - 8,200 | 2,952 - 2,974 | 0.433 |
| 9 | 8,200 - 8,250 | 2,974 - 2,995 | 0.433 |

### Pressure vs. Depth Correlation

```matlab
% Pressure-depth function
function P = calc_pressure(depth, datum_depth, datum_pressure, phase)
    % Depth difference from datum
    dh = depth - datum_depth;
    
    % Pressure gradient based on phase
    if strcmp(phase, 'oil')
        gradient = 0.350;  % psi/ft
    elseif strcmp(phase, 'water')
        gradient = 0.433;  % psi/ft
    else
        error('Unknown phase: %s', phase);
    end
    
    % Calculate pressure
    P = datum_pressure + gradient * dh;
end
```

### Compartment Pressure Differences
- **Main Compartment**: Reference pressure
- **Northern Block**: +5 psi (minor fault seal)
- **Southern Extension**: -3 psi (slight depletion)

## Aquifer Characterization

### Bottom Aquifer (Layer 9)

#### Aquifer Properties
- **Type**: Strong bottom-drive aquifer
- **Porosity**: 0.22 (22%)
- **Permeability**: 150 mD (horizontal), 15 mD (vertical)
- **Thickness**: 50 ft
- **Areal Extent**: 2.5 times reservoir area

#### Aquifer Connectivity
- **Connection**: Direct hydraulic communication
- **Transmissibility**: High (>500 mD⋅ft/cp)
- **Boundary Conditions**: Infinite-acting (effectively)

#### Carter-Tracy Analytical Aquifer Model

```matlab
% Carter-Tracy aquifer parameters
aquifer = struct();
aquifer.type = 'carter_tracy';
aquifer.radius = 5000;  % ft - effective aquifer radius
aquifer.height = 50;    % ft - aquifer thickness
aquifer.porosity = 0.22;
aquifer.permeability = 150e-3;  % Darcy
aquifer.compressibility = 3e-6;  % 1/psi
aquifer.viscosity = 0.5;  % cp (water)

% Aquifer productivity index
aquifer.J = (2 * pi * aquifer.permeability * aquifer.height) / ...
           (aquifer.viscosity * log(aquifer.radius / 350));  % STB/day/psi
```

### Aquifer-Reservoir Interface

```matlab
% Define aquifer-reservoir connection
function aquifer_conn = setup_aquifer_connection(G, rock, aquifer_layer)
    % Find cells in aquifer layer
    aquifer_cells = find(G.cells.layer == aquifer_layer);
    
    % Calculate transmissibility multipliers
    aquifer_conn = struct();
    aquifer_conn.cells = aquifer_cells;
    aquifer_conn.trans_mult = ones(length(aquifer_cells), 1);
    
    % Apply aquifer properties
    rock.poro(aquifer_cells) = 0.22;
    rock.perm(aquifer_cells, 1) = 150e-15;  % m²
    rock.perm(aquifer_cells, 2) = 150e-15;  % m²
    rock.perm(aquifer_cells, 3) = 15e-15;   % m²
end
```

## MRST Initialization Setup

### initEclipseState Function Usage

```matlab
function state = initialize_eagle_west_field(G, rock, fluid, deck)
    % Main initialization function for Eagle West Field
    
    % Define initialization parameters
    init_params = struct();
    init_params.datum_depth = 8000 * 0.3048;  % Convert to meters
    init_params.datum_pressure = 2900 * 6894.76;  % Convert to Pascal
    init_params.OWC = 8150 * 0.3048;  % Oil-water contact
    init_params.GOC = [];  % No gas-oil contact
    
    % Use MRST's initialization function
    state = initEclipseState(G, deck, 'state', [], ...
                           'datum_pressure', init_params.datum_pressure, ...
                           'datum_depth', init_params.datum_depth);
    
    % Validate initialization
    validate_initial_state(G, state, init_params);
    
    return;
end
```

### Grid Property Assignment

```matlab
% Assign rock properties to grid
function rock = assign_rock_properties(G, layers_data)
    % Initialize rock structure
    rock = struct();
    rock.perm = zeros(G.cells.num, 3);  % Permeability tensor
    rock.poro = zeros(G.cells.num, 1);  % Porosity
    
    % Loop through layers
    for layer = 1:9
        % Find cells in current layer
        layer_cells = find(G.cells.layer == layer);
        
        % Assign properties based on layer
        layer_props = layers_data(layer);
        rock.poro(layer_cells) = layer_props.porosity;
        rock.perm(layer_cells, 1) = layer_props.perm_x * 1e-15;  % m²
        rock.perm(layer_cells, 2) = layer_props.perm_y * 1e-15;  % m²
        rock.perm(layer_cells, 3) = layer_props.perm_z * 1e-15;  % m²
    end
    
    return;
end
```

### Initial Condition Tables

#### EQUIL Table Setup
```matlab
% ECLIPSE-style EQUIL table
equil_table = [
    8000,  % Datum depth (ft)
    2900,  % Pressure at datum (psi)
    8150,  % Oil-water contact (ft)
    0,     % Oil-water capillary pressure at OWC
    0,     % Gas-oil contact (ft) - not used
    0,     % Gas-oil capillary pressure at GOC - not used
    1,     % Live oil flag
    1,     % Push-pull flag
    5      % Accuracy flag
];
```

#### PVT Initialization Tables
```matlab
% Initialize PVT properties
function pvt = initialize_pvt_tables()
    pvt = struct();
    
    % Oil PVT (undersaturated)
    pvt.oil.pressure = [14.7, 1000, 2000, 2900, 3500, 4000];  % psi
    pvt.oil.Bo = [1.150, 1.168, 1.187, 1.201, 1.213, 1.225];  % RB/STB
    pvt.oil.viscosity = [1.5, 1.4, 1.3, 1.25, 1.2, 1.15];  % cp
    pvt.oil.Rs = [200, 250, 300, 350, 350, 350];  % SCF/STB
    
    % Water PVT
    pvt.water.pressure = [14.7, 1000, 2000, 3000, 4000];  % psi
    pvt.water.Bw = [1.000, 1.003, 1.006, 1.009, 1.012];  % RB/STB
    pvt.water.viscosity = [0.5, 0.5, 0.5, 0.5, 0.5];  % cp
    pvt.water.compressibility = 3e-6;  % 1/psi
    
    return;
end
```

### Saturation Function Initialization

```matlab
% Initialize relative permeability and capillary pressure
function satfunc = initialize_saturation_functions()
    satfunc = struct();
    
    % Water-Oil System
    satfunc.SWOF = [
        % Sw    krw    krow   Pcow
        0.20,  0.000, 1.000, 25.0  ;  % Connate water
        0.25,  0.001, 0.950, 20.0  ;
        0.30,  0.005, 0.850, 15.0  ;
        0.40,  0.020, 0.650, 10.0  ;
        0.50,  0.050, 0.450, 7.0   ;
        0.60,  0.100, 0.275, 5.0   ;
        0.70,  0.180, 0.150, 3.0   ;
        0.80,  0.300, 0.050, 1.0   ;
        0.85,  0.400, 0.000, 0.5   ;  % Residual oil
        1.00,  1.000, 0.000, 0.0   ;
    ];
    
    return;
end
```

## Validation and Quality Control

### Material Balance Checks

```matlab
function validation = validate_material_balance(G, state, fluid)
    validation = struct();
    
    % Calculate pore volumes
    pv_oil = sum(state.s(:,2) .* G.cells.volumes .* rock.poro);
    pv_water = sum(state.s(:,1) .* G.cells.volumes .* rock.poro);
    pv_total = sum(G.cells.volumes .* rock.poro);
    
    % Check material balance
    validation.pv_oil = pv_oil;
    validation.pv_water = pv_water;
    validation.pv_total = pv_total;
    validation.balance_error = abs(pv_oil + pv_water - pv_total) / pv_total;
    
    % Validation criteria
    validation.balance_ok = validation.balance_error < 1e-6;
    
    if ~validation.balance_ok
        warning('Material balance error: %.2e', validation.balance_error);
    end
    
    return;
end
```

### Pressure-Depth Consistency

```matlab
function pressure_validation = validate_pressure_depth(G, state, contacts)
    pressure_validation = struct();
    
    % Get cell depths and pressures
    depths = G.cells.centroids(:,3);
    pressures = state.pressure;
    
    % Check hydrostatic consistency
    for i = 1:length(depths)
        if depths(i) < contacts.OWC
            % Oil zone - check oil gradient
            expected_p = calc_pressure(depths(i), 8000*0.3048, 2900*6894.76, 'oil');
            error = abs(pressures(i) - expected_p) / expected_p;
            pressure_validation.oil_errors(i) = error;
        else
            % Water zone - check water gradient
            expected_p = calc_pressure(depths(i), 8000*0.3048, 2900*6894.76, 'water');
            error = abs(pressures(i) - expected_p) / expected_p;
            pressure_validation.water_errors(i) = error;
        end
    end
    
    % Summary statistics
    pressure_validation.max_error = max([pressure_validation.oil_errors, ...
                                       pressure_validation.water_errors]);
    pressure_validation.pressure_ok = pressure_validation.max_error < 0.01;  % 1% tolerance
    
    return;
end
```

### Saturation Distribution Validation

```matlab
function sat_validation = validate_saturation_distribution(G, state, contacts)
    sat_validation = struct();
    
    % Get cell depths and saturations
    depths = G.cells.centroids(:,3);
    Sw = state.s(:,1);
    So = state.s(:,2);
    
    % Check saturation constraints
    sat_validation.sat_sum_ok = all(abs(Sw + So - 1.0) < 1e-6);
    sat_validation.sat_bounds_ok = all(Sw >= 0 & Sw <= 1 & So >= 0 & So <= 1);
    
    % Check contact consistency
    oil_zone_cells = depths < contacts.OWC - 25*0.3048;  % 25 ft above OWC
    water_zone_cells = depths > contacts.OWC + 25*0.3048;  % 25 ft below OWC
    
    sat_validation.oil_zone_Sw_avg = mean(Sw(oil_zone_cells));
    sat_validation.water_zone_Sw_avg = mean(Sw(water_zone_cells));
    
    % Validation criteria
    sat_validation.oil_zone_ok = sat_validation.oil_zone_Sw_avg < 0.25;  % Should be near Swi
    sat_validation.water_zone_ok = sat_validation.water_zone_Sw_avg > 0.95;  % Should be near 1.0
    
    return;
end
```

### Contact Placement Verification

```matlab
function contact_validation = validate_contact_placement(G, state, contacts)
    contact_validation = struct();
    
    % Find cells near OWC
    depths = G.cells.centroids(:,3);
    owc_cells = abs(depths - contacts.OWC) < 5*0.3048;  % Within 5 ft of OWC
    
    % Check saturation transition
    Sw_near_owc = state.s(owc_cells, 1);
    
    contact_validation.owc_sw_min = min(Sw_near_owc);
    contact_validation.owc_sw_max = max(Sw_near_owc);
    contact_validation.owc_sw_range = contact_validation.owc_sw_max - contact_validation.owc_sw_min;
    
    % Should have gradual transition
    contact_validation.transition_ok = contact_validation.owc_sw_range > 0.3 && ...
                                     contact_validation.owc_sw_range < 0.8;
    
    return;
end
```

### Complete Validation Workflow

```matlab
function run_initialization_validation(G, state, rock, fluid, contacts)
    fprintf('Running Eagle West Field Initialization Validation...\n');
    
    % Material balance check
    mb_val = validate_material_balance(G, state, fluid);
    fprintf('Material Balance Error: %.2e (OK: %d)\n', mb_val.balance_error, mb_val.balance_ok);
    
    % Pressure-depth consistency
    p_val = validate_pressure_depth(G, state, contacts);
    fprintf('Max Pressure Error: %.2f%% (OK: %d)\n', p_val.max_error*100, p_val.pressure_ok);
    
    % Saturation distribution
    s_val = validate_saturation_distribution(G, state, contacts);
    fprintf('Saturation Sum OK: %d, Bounds OK: %d\n', s_val.sat_sum_ok, s_val.sat_bounds_ok);
    fprintf('Oil Zone Sw: %.3f, Water Zone Sw: %.3f\n', s_val.oil_zone_Sw_avg, s_val.water_zone_Sw_avg);
    
    % Contact placement
    c_val = validate_contact_placement(G, state, contacts);
    fprintf('OWC Transition Range: %.3f (OK: %d)\n', c_val.owc_sw_range, c_val.transition_ok);
    
    % Overall validation
    overall_ok = mb_val.balance_ok && p_val.pressure_ok && s_val.sat_sum_ok && ...
                s_val.sat_bounds_ok && s_val.oil_zone_ok && s_val.water_zone_ok && ...
                c_val.transition_ok;
    
    fprintf('\n=== INITIALIZATION VALIDATION SUMMARY ===\n');
    fprintf('Overall Status: %s\n', char("PASS" * overall_ok + "FAIL" * ~overall_ok));
    
    if ~overall_ok
        fprintf('Please review and correct initialization parameters.\n');
    end
    
    return;
end
```

## Summary

This initialization document provides a comprehensive framework for setting up the Eagle West Field reservoir model in MRST. Key features include:

1. **Robust equilibration methodology** using MRST's gravity-capillary equilibrium
2. **Well-defined fluid contacts** with appropriate uncertainty quantification
3. **Physics-based saturation distribution** in transition zones
4. **Consistent pressure initialization** across all layers
5. **Comprehensive aquifer characterization** for pressure support
6. **Complete MRST implementation** with validation procedures

The initialization ensures material balance, pressure-depth consistency, and proper saturation distribution while maintaining numerical stability for subsequent simulation runs.

### Key Parameters Summary:
- **Datum**: 8,000 ft TVDSS @ 2,900 psi
- **OWC**: 8,150 ft TVDSS (±10 ft uncertainty)
- **Oil Zone**: So = 0.80, Sw = 0.20
- **Aquifer**: Strong bottom drive, Layer 9
- **Validation**: Multiple QC checks implemented

This initialization framework provides a solid foundation for dynamic reservoir simulation and history matching workflows.