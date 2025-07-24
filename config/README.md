# Reservoir Configuration System

This directory contains the YAML configuration file that controls all reservoir simulation parameters. The configuration system allows you to modify reservoir properties, simulation settings, and output options without editing the simulation code directly.

## Configuration File

**Main file:** `reservoir_config.yaml`

This file contains all parameters needed for the MRST geomechanical simulation, organized into logical sections.

## Configuration Sections

### 1. Grid Configuration
Controls the computational grid:
```yaml
grid:
  nx: 20          # Number of cells in X direction
  ny: 20          # Number of cells in Y direction  
  dx: 164.0       # Cell size in X direction [ft]
  dy: 164.0       # Cell size in Y direction [ft]
```

### 2. Porosity Configuration
Defines porosity distribution:
```yaml
porosity:
  base_value: 0.20              # Base porosity [-]
  variation_amplitude: 0.10     # Spatial variation amplitude [-]
  min_value: 0.05              # Minimum allowed porosity [-]
  max_value: 0.35              # Maximum allowed porosity [-]
```

### 3. Permeability Configuration
Defines permeability distribution:
```yaml
permeability:
  base_value: 100.0            # Base permeability [mD]
  variation_amplitude: 80.0    # Spatial variation amplitude [mD]
  min_value: 10.0              # Minimum allowed permeability [mD]
  max_value: 500.0             # Maximum allowed permeability [mD]
```

### 4. Rock Properties
Defines rock regions and their properties:
```yaml
rock:
  regions:
    - id: 1
      name: "Sandstone"
      porosity_multiplier: 1.0
      permeability_multiplier: 1.0
      compressibility: 4.5e-5
```

### 5. Fluid Properties
Defines oil and water properties:
```yaml
fluid:
  oil:
    density: 850.0        # Oil density [kg/m³]
    viscosity: 2.0        # Oil viscosity [cP]
  water:
    density: 1000.0       # Water density [kg/m³]
    viscosity: 0.5        # Water viscosity [cP]
```

### 6. Wells Configuration
Defines producer and injector wells:
```yaml
wells:
  producer:
    location: [15, 10]    # Grid coordinates [i, j]
    target_bhp: 2175.0    # Target bottomhole pressure [psi]
  injector:
    location: [5, 10]     # Grid coordinates [i, j]
    target_rate: 251.0    # Target injection rate [bbl/day]
```

### 7. Simulation Parameters
Controls simulation timing and solver settings:
```yaml
simulation:
  total_time: 365.0       # Total simulation time [days]
  num_timesteps: 50       # Number of timesteps
  solver:
    tolerance: 1e-6       # Convergence tolerance
```

## How to Use

### 1. Modify Configuration
Edit `reservoir_config.yaml` to change any simulation parameters:
```bash
# Edit the configuration file
nano config/reservoir_config.yaml
```

### 2. Run Simulation
The main simulation script automatically uses the configuration:
```matlab
% In Octave/MATLAB
cd MRST_simulation_scripts
main_phase1
```

### 3. Test Configuration
Verify your configuration changes work:
```matlab
% In Octave/MATLAB
cd MRST_simulation_scripts
test_config
```

## Example Modifications

### Change Grid Resolution
```yaml
grid:
  nx: 40          # Increase from 20 to 40
  ny: 40          # Increase from 20 to 40
  dx: 82.0        # Decrease cell size to maintain domain size [ft]
  dy: 82.0        # Decrease cell size to maintain domain size [ft]
```

### Modify Porosity Range
```yaml
porosity:
  base_value: 0.15              # Lower base porosity
  variation_amplitude: 0.05     # Reduce heterogeneity
  min_value: 0.10              # Higher minimum
  max_value: 0.25              # Lower maximum
```

### Change Permeability Distribution
```yaml
permeability:
  base_value: 200.0            # Higher base permeability
  variation_amplitude: 150.0   # More heterogeneity
  correlation_length: 500.0    # Larger correlation length
```

### Adjust Simulation Time
```yaml
simulation:
  total_time: 730.0           # 2 years instead of 1 year
  num_timesteps: 100          # More timesteps for better resolution
```

### Modify Well Locations
```yaml
wells:
  producer:
    location: [18, 18]        # Move to corner
    target_bhp: 1740.0        # Lower drawdown [psi]
  injector:
    location: [2, 2]          # Move to opposite corner
    target_rate: 377.0        # Higher injection rate [bbl/day]
```

## Configuration Validation

The system automatically validates configuration parameters:

- **Grid dimensions**: Must be positive integers
- **Porosity values**: Must be between 0 and 1
- **Permeability values**: Must be positive
- **Well locations**: Must be within grid bounds
- **Time parameters**: Must be positive

## Units

All parameters use consistent field units:
- **Length**: feet [ft]
- **Pressure**: pounds per square inch [psi]
- **Permeability**: millidarcy [mD]
- **Time**: days
- **Temperature**: Fahrenheit [°F]
- **Density**: kg/m³ (config) → lb/ft³ (internal)
- **Viscosity**: centipoise [cP]
- **Volume**: barrels [bbl]
- **Rate**: barrels per day [bbl/day]

## Troubleshooting

### Configuration Not Loading
- Check YAML syntax (proper indentation, colons, etc.)
- Verify file path is correct
- Ensure all required sections are present

### Simulation Errors
- Check parameter ranges are physically reasonable
- Verify grid dimensions are appropriate
- Ensure well locations are within grid bounds

### Performance Issues
- Reduce grid resolution (nx, ny) for faster testing
- Decrease number of timesteps for initial runs
- Simplify rock regions if needed

## Advanced Usage

### Multiple Configurations
Create different configuration files for different scenarios:
```bash
config/
├── reservoir_config.yaml          # Default configuration
├── high_resolution_config.yaml    # Fine grid for detailed studies
├── low_perm_config.yaml          # Tight reservoir scenario
└── waterflooding_config.yaml     # Optimized for waterflooding
```

Use specific configurations:
```matlab
[G, rock, fluid] = setup_field('config/high_resolution_config.yaml');
```

### Parameter Studies
Create configurations for systematic parameter studies:
- Vary porosity/permeability ranges
- Test different well patterns
- Evaluate different rock types
- Study time-dependent behavior

## Support

For questions about the configuration system:
1. Check this README for common issues
2. Run `test_config.m` to verify your setup
3. Examine the generated plots and data files
4. Review the simulation log messages for warnings

The configuration system is designed to make reservoir simulation accessible and reproducible while maintaining the flexibility to study different scenarios. 