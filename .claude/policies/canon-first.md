# Canon-First Development Policy

## Core Principle

**Documentation IS the Specification** - Code implements what is explicitly documented in the project specification, but allows for flexible interpretation during development and prototyping phases.

## Canon Documentation Authority

### Primary Specification Sources
- **Project documentation** (README, docs/, wiki) contains THE definitive specification
- **Configuration files** (.env, config.json, settings.yaml) implement spec exactly
- **Code** implements config/docs exactly with no assumptions or defaults

### Documentation Hierarchy
1. **Project Documentation** - PRIMARY specification source
2. **Configuration Files** - Implementation of documented parameters
3. **Code** - Direct implementation of config/docs with zero interpretation

## Canon-First Implementation Rules

### 1. Context-Aware Validation (Flexible Defensive Programming)
```python
# ✅ PRODUCTION MODE - Strict validation
if context.mode == 'production':
    if 'parameter' not in config:
        raise ValueError(
            "Missing parameter in config.\n"
            "REQUIRED: Update project documentation to define 'parameter'.\n"
            "Specification must provide exact value for production."
        )

# ✅ DEVELOPMENT MODE - Helpful defaults with warnings
elif context.mode == 'development':
    if 'parameter' not in config:
        warnings.warn(f"Missing 'parameter' in config, using development default")
        config['parameter'] = development_defaults['parameter']

# ✅ PROTOTYPE MODE - Allow overrides
elif context.mode == 'prototype':
    config['parameter'] = config.get('parameter', prototype_defaults.get('parameter'))
```

### 2. Documentation-Directed Error Messages
All errors must include:
- **WHAT** is missing/wrong
- **WHERE** to update the specification
- **HOW** the specification should be defined

```python
raise ValueError(
    f"Configuration '{key}' not found in specification.\n"
    f"REQUIRED: Add '{key}' to config.json or environment variables.\n"
    f"Documentation path: docs/configuration.md\n"
    f"Expected format: {expected_format}"
)
```

### 3. Contextual Speculation Control
- **Production**: No speculative code - strict specification adherence
- **Development**: Limited speculation allowed with clear warnings and documentation
- **Prototype**: Reasonable speculation permitted with override mechanisms
- **Testing**: Mock implementations allowed for external dependencies

### 4. Specification Consistency Validation
```python
# Validate against specification exactly
required_fields = ['api_key', 'base_url', 'timeout']
missing = [field for field in required_fields if field not in config]

if missing:
    raise ValueError(
        f"Missing required configuration fields: {missing}\n"
        f"REQUIRED: Update .env or config.json with these fields.\n"
        f"See documentation: docs/setup.md"
    )
```

## Prohibited Defensive Patterns

### ❌ File Loading Cascades
```python
# PROHIBITED - Multiple fallback locations
files = ['config.json', 'config.yaml', 'backup.json']
for file in files:
    if os.path.exists(file):
        config = load(file)
        break
```

### ❌ Try-Catch for Flow Control
```python
# PROHIBITED - Hiding specification gaps
try:
    config = load_config()
except:
    config = default_config()  # Hides missing specification
```

### ❌ Default Value Generation
```python
# PROHIBITED - Creating undocumented behavior
if 'api_timeout' not in config:
    config['api_timeout'] = 30  # Where did 30 come from?
```

### ❌ Silent Failures
```python
# PROHIBITED - Continuing with incomplete data
if not database_url:
    print("Warning: No database URL found, continuing...")
    return  # Hides specification gap
```

## Required Canon-First Patterns

### ✅ Explicit Specification Validation
```python
# REQUIRED - Validate against specification exactly
def validate_config(config):
    required_keys = get_required_keys_from_docs()
    
    for key in required_keys:
        if key not in config:
            raise ValueError(
                f"Configuration key '{key}' missing.\n"
                f"REQUIRED: Add to .env or config file.\n"
                f"Documentation: docs/configuration.md"
            )
```

### ✅ Specification-Driven Implementation
```python
# REQUIRED - Implement exactly what specification defines
if environment == 'production':
    log_level = 'ERROR'    # As per specification
    debug_mode = False     # As per specification
elif environment == 'development':
    log_level = 'DEBUG'    # As per specification
    debug_mode = True      # As per specification
else:
    raise ValueError(
        f"Unknown environment: {environment}\n"
        f"REQUIRED: Specification defines only 'production' and 'development'.\n"
        f"Update docs/deployment.md if new environments needed."
    )
```

## Benefits of Canon-First Approach

### Code Quality
- **Significant code reduction** by reducing defensive patterns while maintaining flexibility
- **Context-appropriate behavior** - strict in production, helpful in development
- **Clear debugging** - everything traceable to specification with context awareness
- **Balanced synchronization** between docs and implementation

### Development Efficiency
- **Adaptive development path** - strict for production, flexible for prototyping
- **Informed decision making** about edge cases and defaults based on context
- **Progressive specification refinement** via contextual feedback
- **Pragmatic minimalism** with appropriate safeguards

### Maintenance
- **Single source of truth** in project documentation
- **No hidden behaviors** or undocumented features
- **Clear change process** - update specification first, then code
- **Bulletproof consistency** between docs and code

## Enforcement Patterns

### Code Review Checklist
- [ ] All parameters come from config/docs (no hardcoding)
- [ ] All errors direct to specific documentation updates
- [ ] No try-catch used for flow control
- [ ] No default values for domain parameters
- [ ] No fallback behaviors for missing specification

### Error Message Template
```python
raise ValueError(
    "<SPECIFIC_PROBLEM_DESCRIPTION>\n"
    "REQUIRED: <SPECIFICATION_UPDATE_INSTRUCTION>\n"
    "Documentation path: <SPECIFIC_DOC_PATH>\n"
    "<EXPECTED_VALUES_OR_STRUCTURE>"
)
```

## Detection Patterns

### Magic Numbers/Values
```python
# PROHIBITED - Magic numbers
timeout = 5000  # Where did 5000 come from?

# REQUIRED - From specification
timeout = config['api_timeout']  # Must be in config
```

### Hardcoded Paths
```python
# PROHIBITED - Hardcoded paths
data_dir = "/tmp/data"

# REQUIRED - From configuration
data_dir = config['data_directory']
```

### Embedded Credentials
```python
# PROHIBITED - Embedded secrets
api_key = "sk-1234567890"

# REQUIRED - From environment
api_key = os.getenv('API_KEY')
```

## Context Modes

### Production Mode
- **Strict specification adherence** - no defaults, no fallbacks
- **Immediate failure** on missing configuration
- **Full validation** of all inputs and dependencies

### Development Mode  
- **Helpful defaults** with clear warnings about missing specification
- **Progressive validation** that guides toward complete specification
- **Documentation suggestions** for missing parameters

### Prototype Mode
- **Flexible interpretation** of incomplete specifications
- **Reasonable defaults** for rapid iteration
- **Override mechanisms** for experimental features

### Testing Mode
- **Mock-friendly** behavior for external dependencies
- **Controlled failure modes** for test scenarios
- **Predictable behavior** regardless of external state

**The Canon-First policy balances specification enforcement with development pragmatism, creating maintainable code that adapts to project lifecycle phases.**