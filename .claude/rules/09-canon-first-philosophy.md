# Rule 09: Canon-First Development Philosophy

## Core Principle

**Documentation IS the Specification** - The project follows a revolutionary "Canon-First" approach where code implements ONLY what is explicitly documented in the canonical specification, with zero defensive programming or fallbacks.

## Canon Documentation Authority

### Primary Specification Source
- **`obsidian-vault/Planning/`** contains THE definitive specification for Eagle West Field
- **YAML configs** implement canon specification exactly with zero deviation
- **Code** implements YAML/canon exactly with no assumptions or defaults

### Documentation Hierarchy
1. **Canon Documentation** (`obsidian-vault/Planning/`) - PRIMARY specification
2. **YAML Configurations** - Implementation of canon parameters
3. **Code** - Direct implementation of YAML/canon with zero interpretation

## Canon-First Implementation Rules

### 1. Zero Defensive Programming
```matlab
// ❌ PROHIBITED - Defensive fallback
if isempty(config.parameter)
    config.parameter = default_value;  % Creates hidden behavior
end

// ✅ REQUIRED - Fail fast to documentation
if ~isfield(config, 'parameter') || isempty(config.parameter)
    error(['Missing canonical parameter in config.\n' ...
           'REQUIRED: Update obsidian-vault/Planning/CONFIG_SPEC.md\n' ...
           'to define parameter for Eagle West Field.\n' ...
           'Canon must specify exact value, no defaults allowed.']);
end
```

### 2. Documentation-Directed Error Messages
All errors must include:
- **WHAT** is missing/wrong
- **WHERE** to update the canon documentation
- **HOW** the specification should be defined

```matlab
error(['Fault "%s" not found in canonical tier configuration.\n' ...
       'REQUIRED: All Eagle West faults must be assigned to exactly one tier:\n' ...
       '- major: Fault_A, Fault_C, Fault_D (high sealing capacity)\n' ...
       '- minor: Fault_B, Fault_E (lower sealing capacity)\n' ...
       'Check grid_config.yaml refinement.fault_refinement.fault_tiers configuration.'], fault_name);
```

### 3. No Speculative Code
- **No "just in case" logic** for undocumented scenarios
- **No multiple options** when canon specifies one approach
- **No edge case handling** for cases not in specification
- **No backwards compatibility** for deprecated approaches

### 4. Canon Consistency Validation
```matlab
% Validate against canon specification
if well_count ~= 15
    error(['Invalid well count: %d. Eagle West Field has exactly 15 wells.\n' ...
           'REQUIRED: Canon specification defines EW-001 to EW-010, IW-001 to IW-005.\n' ...
           'Update obsidian-vault/Planning/Wells_Definition.md if field changes.'], well_count);
end
```

## Prohibited Defensive Patterns

### ❌ File Loading Cascades
```matlab
% PROHIBITED - Multiple fallback locations
files = {'file1.mat', 'file2.mat', 'backup.mat'};
for i = 1:length(files)
    if exist(files{i}, 'file')
        data = load(files{i});
        break;
    end
end
```

### ❌ Try-Catch for Flow Control
```matlab
% PROHIBITED - Hiding specification gaps
try
    config = load_config();
catch
    config = default_config();  % Hides missing specification
end
```

### ❌ Default Value Generation
```matlab
% PROHIBITED - Creating undocumented behavior
if ~isfield(config, 'pressure')
    config.pressure = 3000;  % Where did 3000 come from?
end
```

### ❌ Silent Failures
```matlab
% PROHIBITED - Continuing with incomplete data
if isempty(wells_data)
    warning('No wells found, continuing...');
    return;  % Hides specification gap
end
```

## Required Canon-First Patterns

### ✅ Explicit Canon Validation
```matlab
% REQUIRED - Validate against canon exactly
required_wells = {'EW-001', 'EW-002', 'EW-003', 'EW-004', 'EW-005', ...
                  'EW-006', 'EW-007', 'EW-008', 'EW-009', 'EW-010', ...
                  'IW-001', 'IW-002', 'IW-003', 'IW-004', 'IW-005'};

if length(wells) ~= length(required_wells)
    error(['Canon violation: Expected %d wells, found %d.\n' ...
           'REQUIRED: Update obsidian-vault/Planning/Wells_Definition.md\n' ...
           'if Eagle West well configuration has changed.'], ...
           length(required_wells), length(wells));
end
```

### ✅ Specification-Driven Implementation
```matlab
% REQUIRED - Implement exactly what canon specifies
if strcmp(refinement_tier, 'critical')
    refinement_factor = 2;    % As per canon specification
    radius = 185;             % As per canon specification  
elseif strcmp(refinement_tier, 'standard')
    refinement_factor = 1.5;  % As per canon specification
    radius = 125;             % As per canon specification
else
    error(['Unknown refinement tier: %s\n' ...
           'REQUIRED: Canon defines only "critical" and "standard" tiers.\n' ...
           'Update obsidian-vault/Planning/Grid_Refinement.md if new tiers needed.'], refinement_tier);
end
```

## Benefits of Canon-First Approach

### Code Quality
- **60-75% code reduction** by eliminating defensive patterns
- **Zero ambiguity** about system behavior
- **Trivial debugging** - everything traceable to canon
- **Perfect specifications** always synchronized with implementation

### Development Efficiency  
- **Clear development path** - implement canon exactly
- **No guesswork** about edge cases or defaults
- **Immediate specification feedback** via error messages
- **True minimalism** with maximum clarity

### Maintenance
- **Single source of truth** in canon documentation
- **No hidden behaviors** or undocumented features
- **Clear change process** - update canon first, then code
- **Bulletproof consistency** between docs and code

## Enforcement

### Code Review Checklist
- [ ] All parameters come from canon/YAML (no hardcoding)
- [ ] All errors direct to specific canon documentation updates
- [ ] No try-catch used for flow control
- [ ] No default values for domain parameters
- [ ] No fallback behaviors for missing specification

### Automatic Validation
- Pre-commit hooks validate canon-first patterns
- No defensive programming allowed in production code
- All configuration must be traceable to canon documentation

## Canon-First Error Message Template

```matlab
error(['<SPECIFIC_PROBLEM_DESCRIPTION>\n' ...
       'REQUIRED: <CANON_UPDATE_INSTRUCTION>\n' ...
       'Canon specification: <SPECIFIC_DOCUMENTATION_PATH>\n' ...
       '<EXPECTED_CANONICAL_VALUES_OR_STRUCTURE>']);
```

## Integration with Other Rules

- **Rule 0** (FAIL_FAST): Enhanced with canon-directed failure
- **Rule 1** (Code Style): Simplified by eliminating defensive complexity  
- **Rule 6** (Documentation): Canon documentation becomes specification
- **Rule 8** (Logging): Errors must direct to canon updates

**The Canon-First philosophy transforms defensive programming into specification enforcement, creating truly minimal, maintainable, and unambiguous code.**