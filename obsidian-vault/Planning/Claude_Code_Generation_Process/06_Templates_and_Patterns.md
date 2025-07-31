# Templates and Patterns - Code Generation Standards

## Overview

Claude Code's template system provides standardized starting points for different file types, ensuring consistency across the codebase while enforcing project conventions. This document details all available templates and their usage patterns.

## Template Philosophy

### Core Principles

1. **Consistency**: All code follows the same structural patterns
2. **Convention Enforcement**: Templates embed project rules
3. **Self-Documenting**: Structure implies purpose
4. **Minimal Boilerplate**: Only essential elements included

### Template Benefits

- **Immediate Compliance**: Pre-formatted with all rules
- **Learning Tool**: Shows best practices by example
- **Time Saving**: No need to remember conventions
- **Error Prevention**: Correct structure from the start

## Python Templates

### Python Module Template

**File**: `python_module.py`
**Purpose**: Standard Python module structure

**Structure Overview**:
```
1. Module docstring (Google Style)
2. Step 1: Imports (organized by category)
3. Step 2: Constants and configuration
4. Step 3: Main implementation
5. Step 4: Module execution block
```

**Key Features**:
- Pre-defined step/substep structure
- Type hints included
- Google Style docstrings
- Error handling patterns
- Execution guard

**Usage Patterns**:
- Data processing modules
- API clients
- Utility libraries
- Service layers

### Python Test Template

**File**: `python_test.py`
**Purpose**: Unit test file structure

**Structure Overview**:
```
1. Test module docstring
2. Import test framework and target
3. Test fixtures
4. Test cases (AAA pattern)
5. Test execution
```

**Key Features**:
- Arrange-Act-Assert pattern
- Fixture organization
- Parametrized test examples
- Mock usage patterns
- Coverage considerations

**Naming Convention**:
```
test_<NN>_<folder>_<module>[_<purpose>].py
```

### Debug Script Template (Python)

**File**: `debug_script.py`
**Purpose**: Debugging and investigation scripts

**Structure Overview**:
```
1. Debug purpose header
2. Investigation setup
3. Data collection
4. Analysis steps
5. Findings output
```

**Key Features**:
- Extensive logging allowed
- Temporary file handling
- Performance profiling setup
- Data inspection utilities
- Clear findings section

**Usage Patterns**:
- Performance investigation
- Data quality checks
- Integration debugging
- Error reproduction

## Octave/MATLAB Templates

### Octave Script Template

**File**: `octave_script.m`
**Purpose**: General Octave/MATLAB scripts

**Structure Overview**:
```
1. Script header with purpose
2. Clear workspace setup
3. Path configuration
4. Main processing steps
5. Results output
```

**Key Features**:
- MATLAB-compatible syntax
- Step-based organization
- Variable naming standards
- Plot configuration
- Data export patterns

**Common Patterns**:
```matlab
% ----------------------------------------
% Step N – Description
% ----------------------------------------

% Substep N.1 – Specific action ______________________
```

### Octave Test Template

**File**: `octave_test.m`
**Purpose**: Test scripts for Octave/MATLAB code

**Structure Overview**:
```
1. Test description header
2. Test environment setup
3. Test data preparation
4. Test execution
5. Assertion checks
6. Cleanup
```

**Key Features**:
- Test isolation
- Clear assertions
- Expected vs actual comparison
- Error case testing
- Performance benchmarks

### Reservoir Simulation Template

**File**: `reservoir_simulation_script.m`
**Purpose**: MRST-specific simulation scripts

**Structure Overview**:
```
1. Simulation description
2. MRST startup
3. Model definition
4. Grid and rock properties
5. Fluid properties
6. Wells and controls
7. Simulation schedule
8. Run simulation
9. Post-processing
10. Visualization
```

**Key Features**:
- MRST module loading
- Standard unit system
- Property definition patterns
- Well placement conventions
- Output organization

**MRST-Specific Patterns**:
```matlab
% Load required modules
mrstModule add coarsegrid deckformat

% Standard units
meter = 1;
darcy = 9.869233e-13;
barsa = 1e5;
```

## Specialized Templates

### Dashboard Component Template

**File**: `dashboard_component.py`
**Purpose**: Streamlit dashboard components

**Structure Overview**:
```
1. Component description
2. Streamlit imports
3. State management
4. Layout definition
5. Interaction handlers
6. Data visualization
7. Component registration
```

**Key Features**:
- Streamlit best practices
- State management patterns
- Responsive layout
- Caching strategies
- Error boundaries

**Common Patterns**:
```python
# State initialization
if 'counter' not in st.session_state:
    st.session_state.counter = 0

# Layout columns
col1, col2, col3 = st.columns([2, 1, 1])

# Caching
@st.cache_data
def load_data():
    return process_data()
```

## Template Selection Logic

### Automatic Selection

```python
def select_template(file_path, context):
    filename = os.path.basename(file_path)
    
    # Test files
    if filename.startswith('test_'):
        if filename.endswith('.py'):
            return 'python_test.py'
        elif filename.endswith('.m'):
            return 'octave_test.m'
    
    # Debug files
    if filename.startswith('dbg_'):
        if filename.endswith('.py'):
            return 'debug_script.py'
        elif filename.endswith('.m'):
            return 'debug_script.m'
    
    # Dashboard files
    if 'dashboard' in file_path and filename.endswith('.py'):
        return 'dashboard_component.py'
    
    # MRST scripts
    if 'mrst' in file_path and filename.endswith('.m'):
        return 'reservoir_simulation_script.m'
    
    # Default templates
    if filename.endswith('.py'):
        return 'python_module.py'
    elif filename.endswith('.m'):
        return 'octave_script.m'
```

### Context-Aware Customization

```python
def customize_template(template, context):
    content = load_template(template)
    
    # Replace placeholders
    content = content.replace('MODULE_NAME', context.module_name)
    content = content.replace('AUTHOR', context.author)
    content = content.replace('DATE', context.date)
    
    # Add specific imports
    if context.needs_numpy:
        content = add_import(content, 'import numpy as np')
    
    if context.needs_pandas:
        content = add_import(content, 'import pandas as pd')
    
    return content
```

## Common Patterns

### Step/Substep Organization

**Standard Format**:
```python
# ----------------------------------------
# Step 1 – High-level description
# ----------------------------------------

# Substep 1.1 – Specific action ______________________
code_for_substep_1_1()

# Substep 1.2 – Another action ______________________
code_for_substep_1_2()
```

**Benefits**:
- Clear visual hierarchy
- Easy navigation
- Logical grouping
- Self-documenting

### Error Handling Patterns

**I/O Operations Only**:
```python
# ✅ Correct - I/O boundary
try:
    with open(file_path, 'r') as f:
        data = f.read()
except IOError as e:
    logger.error(f"Failed to read file: {e}")
    raise

# ❌ Incorrect - Logic control
try:
    result = process_data(data)
except:
    result = default_value  # Never do this
```

### Documentation Patterns

**Google Style Format**:
```python
def process_data(data: List[Dict], threshold: float = 0.5) -> pd.DataFrame:
    """Process raw data into analysis-ready format.
    
    Applies cleaning, transformation, and filtering steps to prepare
    data for downstream analysis.
    
    Args:
        data: List of dictionaries containing raw measurements.
        threshold: Minimum value for filtering. Defaults to 0.5.
        
    Returns:
        Processed dataframe with standardized columns.
        
    Raises:
        ValueError: If data is empty or threshold is negative.
    """
```

### Import Organization

**Standard Order**:
```python
# ----------------------------------------
# Step 1 – Import and Setup
# ----------------------------------------

# Substep 1.1 – Standard library imports ______________________
import os
import sys
from typing import Dict, List, Optional

# Substep 1.2 – External library imports ______________________
import numpy as np
import pandas as pd
from sklearn.preprocessing import StandardScaler

# Substep 1.3 – Internal imports ______________________
from src.utils import load_config
from src.processors import DataProcessor
```

### Naming Patterns

**Variable Naming**:
```python
# ✅ Correct - descriptive snake_case
user_input = get_user_input()
processed_data = transform_data(user_input)
final_results = calculate_metrics(processed_data)

# ❌ Incorrect - generic or wrong case
data = get_user_input()  # Too generic
processedData = transform_data(data)  # Wrong case
x = calculate_metrics(processedData)  # Non-descriptive
```

## Template Evolution

### Adding New Templates

1. **Identify Pattern**: Recognize repeated structures
2. **Extract Template**: Create generalized version
3. **Add Placeholders**: Mark customization points
4. **Document Usage**: Explain when to use
5. **Test Template**: Validate with real usage

### Updating Templates

1. **Version Control**: Track all changes
2. **Backward Compatibility**: Consider existing usage
3. **Communication**: Notify team of updates
4. **Migration Path**: Provide update scripts
5. **Documentation**: Update usage guides

### Template Validation

```python
def validate_template(template_path):
    content = load_file(template_path)
    
    # Check required sections
    assert 'Step 1' in content, "Missing step structure"
    assert 'Args:' in content or not is_python(template_path), "Missing Args section"
    
    # Validate conventions
    assert not has_camel_case(content), "Contains camelCase"
    assert is_english_only(content), "Contains non-English text"
    
    # Check patterns
    assert has_proper_imports(content), "Import organization incorrect"
    assert has_docstrings(content), "Missing docstrings"
```

## Best Practices

### Template Usage

1. **Always Start with Template**: Never create from scratch
2. **Customize Minimally**: Keep template structure
3. **Preserve Patterns**: Maintain step organization
4. **Update Collectively**: Share improvements

### Template Maintenance

1. **Regular Review**: Check for outdated patterns
2. **User Feedback**: Incorporate common changes
3. **Rule Alignment**: Ensure template compliance
4. **Performance**: Keep templates lightweight

### Anti-Patterns to Avoid

1. **Over-Customization**: Breaking template structure
2. **Copy-Paste Programming**: Duplicating without templates
3. **Ignoring Updates**: Using outdated templates
4. **Breaking Conventions**: Modifying core patterns

## Integration with Generation Flow

### Template Injection

```python
def inject_template(context):
    # Select appropriate template
    template = select_template(context.file_path, context)
    
    # Load and customize
    content = load_template(template)
    content = customize_template(content, context)
    
    # Inject into generation context
    context.add_template(content)
    context.add_instruction("Follow template structure")
    
    return context
```

### Validation Integration

Templates are pre-validated to pass all hooks:
- Style compliance built-in
- Naming conventions followed
- Documentation included
- Structure optimized

## Conclusion

Claude Code's template system provides a robust foundation for consistent, high-quality code generation. By embedding project conventions directly into templates and providing specialized versions for different use cases, it ensures that every generated file starts with the correct structure and patterns. The system's extensibility allows for continuous improvement while maintaining consistency across the entire codebase.