# Fail Fast Policy

## Core Principle
**No Defensive Programming** - If required configuration, data, or dependencies are missing, FAIL immediately with clear error messages. Never create workarounds that hide specification gaps.

## Fundamental Rules

### 1. **Immediate Failure on Missing Requirements**
- Validate all prerequisites explicitly at function entry
- Terminate immediately when requirements are not met
- Never continue execution with incomplete or missing critical data
- Error messages must be specific and actionable

### 2. **Prohibited Defensive Patterns**
- Default values for domain-specific parameters (pressures, temperatures, densities, coordinates)
- Empty data structures when real data is expected
- "Safe" fallbacks that produce scientifically incorrect results
- Warnings followed by continued execution with missing critical data
- Exception handling that hides configuration or setup errors

### 3. **Required Error Message Structure**
- Specify exactly what is missing
- Explain where to provide the missing information
- Include the specific action needed to resolve the issue
- Reference documentation sections when applicable

## Application Guidelines

### **Validation Approach:**
```python
# ✅ CORRECT: Explicit validation with actionable error
if 'reservoir_pressure' not in config:
    raise ConfigurationError(
        "Missing 'reservoir_pressure' in configuration.\n"
        "REQUIRED: Add reservoir_pressure to config.yaml\n"
        "Example: reservoir_pressure: 3500.0  # psi"
    )
```

### **Error Message Template:**
```
"Missing {parameter} in {location}.
REQUIRED: {specific_action}
{optional_example_or_reference}"
```

### **What Constitutes "Required":**
- Configuration parameters needed for computation
- Input files referenced by the workflow
- Required dependencies or modules
- Data fields expected by algorithms
- Environment variables for system operation

## Benefits of Fail Fast
- **Clear Error Diagnosis**: Issues are immediately apparent with precise location
- **Prevents Silent Failures**: No mysterious incorrect results from missing data
- **Forces Complete Specifications**: Gaps in requirements become obvious
- **Easier Debugging**: Failures happen at the source of the problem
- **Better User Experience**: Clear guidance on how to fix issues

## Anti-Patterns to Avoid

### ❌ Silent Defaults
```python
# PROHIBITED: Hiding missing configuration
pressure = config.get('pressure', 3500.0)  # Where did 3500 come from?
```

### ❌ Defensive Fallbacks  
```python
# PROHIBITED: Continuing with incomplete data
if not wells_data:
    wells_data = []  # "Safe" empty list hides missing requirements
```

### ❌ Generic Error Handling
```python
# PROHIBITED: Hiding the real problem
try:
    process_reservoir_data()
except Exception:
    print("Something went wrong")  # Unhelpful
```

## Correct Implementations

### ✅ Configuration Validation
```python
def validate_configuration(config):
    required_fields = [
        'reservoir_pressure', 'temperature', 'fluid_properties',
        'grid_dimensions', 'boundary_conditions'
    ]
    
    for field in required_fields:
        if field not in config:
            raise ConfigurationError(
                f"Missing required field '{field}' in configuration.\n"
                f"REQUIRED: Add {field} to your config.yaml file.\n"
                f"See docs/configuration.md for field specifications."
            )
```

### ✅ Dependency Checking
```python
def ensure_mrst_available():
    if not os.path.exists('mrst_session.mat'):
        raise DependencyError(
            "MRST session not initialized.\n"
            "REQUIRED: Run 's01_initialize_mrst.m' first.\n"
            "This creates the required MRST workspace."
        )
```

### ✅ Data Validation
```python
def validate_well_data(wells):
    if not wells:
        raise DataError(
            "No well data provided.\n"
            "REQUIRED: Define wells in wells_config.yaml\n"
            "Minimum: At least one producer or injector well required."
        )
```

## Enforcement Guidelines

### **During Development:**
- Check prerequisites before processing
- Use explicit validation functions
- Write error messages as user guidance
- Test error conditions with missing data

### **Code Review:**
- Flag any default value assignments for domain parameters
- Verify error messages are actionable
- Ensure no silent failures or warnings-only for critical missing data
- Confirm each function validates its requirements

### **Testing:**
- Write tests that verify failure behavior
- Test with missing configuration files
- Verify error messages contain required information
- Ensure failures happen at the right level (not deep in call stack)

**Remember: The goal is not to handle every possible error, but to fail quickly and clearly when requirements are not met. Let the user fix the specification rather than guessing what they intended.**