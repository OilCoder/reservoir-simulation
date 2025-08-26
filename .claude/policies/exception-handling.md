# Exception Handling Policy

## Core Principle
**Explicit Validation Over Exception Handling** - Use exceptions only for truly unpredictable external failures. For application logic, validate prerequisites explicitly before attempting operations.

## Fundamental Rules

### 1. **ALLOWED: Unpredictable External Failures Only**
Exception handling is appropriate for situations where external systems may fail unpredictably:

- **File system operations** where files may not exist or permissions may change
- **Network operations** where external services may be unavailable
- **Optional dependency imports** where libraries may not be installed
- **OS-level operations** that depend on system state
- **Hardware-dependent operations** that may fail due to resource constraints

### 2. **PROHIBITED: Predictable Application Logic**
Never use exception handling for flow control in situations where you can validate beforehand:

- **Input validation** where you can check validity before processing
- **Data structure access** where you can verify existence first  
- **Type conversion** where you can validate format before converting
- **Mathematical operations** where you can validate inputs beforehand
- **Configuration access** where you can check for required fields first

### 3. **Required Approach for Application Logic**
- Validate prerequisites explicitly before attempting operations
- Use conditional checks rather than try-catch for predictable scenarios
- Fail immediately with specific, actionable error messages
- Never use exception handling to bypass proper input validation
- Never return default values when required data is missing

## Application Guidelines

### **Appropriate Exception Usage:**

```python
# ✅ CORRECT: External file operations
try:
    with open(config_file, 'r') as f:
        config = yaml.safe_load(f)
except FileNotFoundError:
    raise ConfigurationError(f"Configuration file not found: {config_file}")
except PermissionError:
    raise ConfigurationError(f"Permission denied reading: {config_file}")

# ✅ CORRECT: Optional dependency imports
try:
    import matplotlib.pyplot as plt
    PLOTTING_AVAILABLE = True
except ImportError:
    PLOTTING_AVAILABLE = False
    plt = None

# ✅ CORRECT: Network operations
try:
    response = requests.get(api_url, timeout=10)
    response.raise_for_status()
except requests.exceptions.RequestException as e:
    raise NetworkError(f"Failed to fetch data from {api_url}: {e}")
```

### **Prohibited Exception Usage:**

```python
# ❌ PROHIBITED: Using exceptions for flow control
try:
    pressure = config['reservoir_pressure']
except KeyError:
    pressure = 3500.0  # Default fallback

# ✅ CORRECT: Explicit validation
if 'reservoir_pressure' not in config:
    raise ConfigurationError("Missing required field 'reservoir_pressure'")
pressure = config['reservoir_pressure']

# ❌ PROHIBITED: Exception-based data access
try:
    first_well = wells[0]
except IndexError:
    first_well = None

# ✅ CORRECT: Explicit checking
if not wells:
    raise DataError("No wells defined in configuration")
first_well = wells[0]
```

## Benefits of This Approach

### **Explicit Validation Benefits:**
- **Clearer Code Logic**: Validation intentions are obvious
- **Better Error Messages**: Can provide specific guidance about what's missing
- **Easier Debugging**: Failures happen at logical decision points
- **Performance**: No exception overhead for predictable conditions

### **Appropriate Exception Use Benefits:**
- **Robust External Operations**: Handles truly unpredictable failures gracefully
- **Clean Resource Management**: Proper cleanup in finally blocks
- **System Integration**: Handles external system unavailability appropriately

## Implementation Patterns

### **Configuration Validation Pattern:**
```python
def validate_required_config(config, required_fields):
    """Validate all required fields exist before processing."""
    missing = [field for field in required_fields if field not in config]
    if missing:
        raise ConfigurationError(
            f"Missing required configuration fields: {', '.join(missing)}\n"
            f"REQUIRED: Add these fields to your config.yaml file"
        )
```

### **Data Structure Validation Pattern:**
```python
def process_wells(wells_data):
    """Process wells with explicit validation."""
    if not wells_data:
        raise DataError("No wells data provided")
    
    if not isinstance(wells_data, list):
        raise DataError("Wells data must be a list")
    
    for i, well in enumerate(wells_data):
        if 'name' not in well:
            raise DataError(f"Well {i} missing required 'name' field")
```

### **Safe External Operation Pattern:**
```python
def load_simulation_results(filepath):
    """Load results with proper external failure handling."""
    try:
        # Validate path format first (explicit check)
        if not filepath.endswith(('.mat', '.h5')):
            raise ValueError(f"Unsupported file format: {filepath}")
        
        # Then handle external file operations
        return scipy.io.loadmat(filepath)
        
    except FileNotFoundError:
        raise DataError(f"Simulation results file not found: {filepath}")
    except scipy.io.matlab.MioError as e:
        raise DataError(f"Failed to read MATLAB file {filepath}: {e}")
```

## Enforcement Guidelines

### **Code Review Checklist:**
- [ ] Are exceptions used only for external/unpredictable failures?
- [ ] Is input validation done explicitly before processing?
- [ ] Do error messages provide actionable guidance?
- [ ] Are there any try-catch blocks used for flow control?
- [ ] Are default values used to hide missing requirements?

### **Anti-Pattern Detection:**
- Any `except:` or broad exception handling without re-raising
- Try-catch blocks around configuration or data access
- Default value assignments in exception handlers
- Silent failure (catching exceptions without error reporting)
- Exception handling used instead of if-statements for predictable conditions

**Remember: If you can check for a condition beforehand, validate explicitly. Save exceptions for truly exceptional circumstances.**