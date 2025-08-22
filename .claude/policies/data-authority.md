# Data Authority Policy

## Core Principle
**Configuration and Simulation Authority** - All domain-specific data must originate from authoritative sources. Never hardcode scientific values, domain parameters, or computed results.

## Fundamental Rules

### 1. **Prohibition of Hard-Coding**
- Never embed fixed numeric answers, lookup tables, or formula constants directly in source files
- Exception: Universal physical constants (π, gravity, speed of light) are allowed
- Expected outputs for tests must be computed at runtime via simulator calls or helper utilities
- No pasted literals or "magic numbers" in business logic

### 2. **Simulator Authority**
- Reservoir properties, stress calculations, synthetic logs, and domain-specific values must originate from:
  - MRST scripts and simulations
  - Octave computational pipelines  
  - Designated ML processing pipelines
  - Configuration files (YAML, JSON, etc.)
- If introducing a new computational tool, adoption must be documented with clear justification

### 3. **Traceability Requirements**
- Each dataset or artifact must include provenance metadata:
  - Timestamp of generation
  - Script name and version that produced it
  - Input parameters used
- Metadata can be in filename or accompanying `.meta.json` file
- Formulas and numerical methods belong in simulator scripts, not scattered across utilities

## Application Guidelines

### **Data Sources (Hierarchical Authority):**
1. **Primary**: Configuration files (YAML/JSON) - User-specified parameters
2. **Secondary**: Simulation outputs - Computed by authoritative simulators
3. **Tertiary**: Derived calculations - From primary/secondary using documented algorithms
4. **Prohibited**: Hardcoded values, manual estimates, or "reasonable defaults"

### **When Working with Domain Data:**
- Always trace data back to its authoritative source
- If source is unclear, fail immediately with specific guidance
- Document the data lineage in comments or metadata
- Use configuration injection patterns, not embedded constants

### **Test Data Requirements:**
- Test expectations must be computed, not copied
- Use helper functions that call the same computational pipeline
- Mock external dependencies, not internal domain logic
- Maintain test data in configuration files, not test code

## Benefits of Data Authority
- **Scientific Integrity**: Results are traceable to authoritative sources
- **Reproducibility**: All computations can be recreated from source parameters
- **Maintainability**: Changes to domain logic happen in one authoritative place
- **Testability**: Tests verify computational pipelines, not hardcoded expectations

## Anti-Patterns to Avoid
- Copying simulation results into test assertions
- Hardcoding "typical" values for reservoir properties
- Embedding lookup tables derived from external sources
- Using estimates or approximations when exact values are computable
- Creating "safe" default values for scientific parameters

## Enforcement Examples

```python
# ❌ PROHIBITED: Hardcoded domain values
pressure_gradient = 0.433  # psi/ft - where did this come from?
typical_porosity = 0.15    # "reasonable" estimate

# ✅ CORRECT: Configuration-driven
pressure_gradient = config['reservoir']['pressure_gradient']
porosity = rock_properties.compute_porosity(depth, lithology)
```

```python
# ❌ PROHIBITED: Hardcoded test expectations  
def test_pressure_calculation():
    result = calculate_pressure(1000)
    assert result == 433.0  # Magic number from manual calculation

# ✅ CORRECT: Computed test expectations
def test_pressure_calculation():
    depth = 1000
    expected = reference_simulator.calculate_pressure(depth)
    result = calculate_pressure(depth)
    assert abs(result - expected) < tolerance
```

**Remember: If you can't trace data back to an authoritative source, configuration file, or documented computation, it doesn't belong in the code.**