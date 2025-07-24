---
allowed-tools: [Write, Read]
description: Create a new MRST reservoir simulation script
---

# Create New Reservoir Simulation Script

Generate a new Octave/MRST script for reservoir simulation following project conventions and MRST best practices.

Arguments: `$ARGUMENTS`
Expected format: `<step_number> <action_description> [simulation_type]`
Example: `05 run simulation pressure` or `12 extract data production`

Available simulation types:
- `pressure`: Pressure-related simulation
- `production`: Production forecasting
- `geomechanics`: Geomechanical analysis
- `fluid`: Fluid flow simulation
- `wells`: Well management
- `export`: Data export and analysis
- `initialization`: Setup and initialization
- `workflow`: Workflow orchestration

## Instructions:

1. **Parse arguments to extract**:
   - Step number (with optional letter suffix)
   - Action description (verb + noun format)
   - Simulation type (determines template specialization)

2. **Create filename following pattern**: `sNN[x]_<verb>_<noun>.m`
   - Example: `s05_run_simulation.m`, `s12a_extract_data.m`

3. **Use reservoir simulation template**: `.claude/templates/reservoir_simulation_script.m`

4. **Place in correct directory**: `/workspace/mrst_simulation_scripts/`

5. **Customize template based on simulation type**:

### Pressure Simulation
- Include pressure field initialization
- Add pressure monitoring and analysis
- Configure pressure-based well controls

### Production Simulation  
- Include production well definitions
- Add rate and cumulative production calculations
- Configure production constraints

### Geomechanics Simulation
- Include stress-strain calculations
- Add geomechanical coupling
- Configure deformation analysis

### Fluid Simulation
- Include multi-phase fluid definitions
- Add PVT properties
- Configure fluid flow equations

### Wells Simulation
- Include well placement optimization
- Add well control strategies
- Configure completion design

### Export Simulation
- Include data extraction routines
- Add visualization preparation
- Configure output formatting

### Initialization Simulation
- Include MRST environment setup
- Add configuration loading
- Configure simulation parameters

### Workflow Simulation
- Include step orchestration
- Add error handling and logging
- Configure parallel execution

## Template Customization:

Based on the simulation type, the script will:

1. **Include appropriate MRST modules**:
   ```matlab
   % Pressure: ad-core, ad-blackoil
   % Production: ad-core, ad-blackoil, wellpaths
   % Geomechanics: ad-mechanics, geomech
   % Fluid: ad-core, ad-props, fluid
   ```

2. **Add specialized functions**:
   - Pressure: `initializePressureField()`, `monitorPressure()`
   - Production: `defineProductionWells()`, `calculateRates()`
   - Geomechanics: `computeStress()`, `analyzeDeformation()`

3. **Configure appropriate output**:
   - Pressure: Pressure maps, pressure profiles
   - Production: Rate curves, cumulative production
   - Geomechanics: Stress fields, displacement maps

## Integration with Project:

The generated script will:

- ✅ Follow `sNN_verb_noun.m` naming convention
- ✅ Include proper MRST requirements comment
- ✅ Use step/substep comment structure  
- ✅ Include English-only documentation
- ✅ Load configuration from `config/reservoir_config.yaml`
- ✅ Include error handling with proper logging
- ✅ Generate structured output for dashboard integration

## Example Usage:

```bash
# Create pressure simulation script
/new-reservoir-script 05 run simulation pressure

# Create data export script  
/new-reservoir-script 12 extract data export

# Create geomechanics analysis script
/new-reservoir-script 08 analyze stress geomechanics

# Create workflow orchestrator
/new-reservoir-script 99 run workflow workflow
```

## Generated Script Features:

### Configuration Integration
- Automatic loading of `reservoir_config.yaml`
- Parameter validation and default handling
- Grid and rock property setup from config

### MRST Best Practices
- Proper module loading and verification
- Standard grid and rock initialization
- Fluid property definition
- State management

### Error Handling
- Try-catch blocks for I/O operations only
- Informative error messages with context
- Graceful degradation when possible

### Documentation
- Complete function header with Args/Returns
- Step-by-step workflow documentation
- MRST requirements clearly specified

### Dashboard Integration
- Structured output format compatible with Python dashboard
- Metadata for visualization
- Standard data export formats

The script will be immediately ready for use in the reservoir simulation workflow and will integrate seamlessly with the existing codebase and dashboard components.