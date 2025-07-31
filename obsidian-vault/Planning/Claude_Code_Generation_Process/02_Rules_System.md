# Rules System and Enforcement Mechanisms

## Overview

Claude Code's rules system implements 8 comprehensive rules that define every aspect of code generation, from style and structure to documentation and error handling. This document details each rule and its enforcement mechanisms.

## Rule Categories

### Foundation Rules (00-02)

These rules establish the core principles governing all code generation.

### Isolation Rules (03-04)

These rules ensure proper separation of production, test, and debug code.

### Convention Rules (05-08)

These rules enforce naming, documentation, and output standards.

## Detailed Rule Specifications

### Rule 00: Project Guidelines (KISS Principle)

**Core Principles:**
1. **Simplicity First**: Write the most direct, readable solution
2. **No Speculative Abstractions**: Build only what's needed now
3. **Explicit Over Implicit**: Clear intent in every line

**Key Constraints:**

#### Try/Except Restrictions
- **Allowed Only For**:
  - File I/O operations
  - Network calls
  - External API interactions
  - Database operations
  
- **Never Allowed For**:
  - Logic flow control
  - Silencing errors
  - Replacing validation

#### Data Generation Policy
- **Prohibited**:
  - Hard-coded numeric answers
  - Formula constants without source
  - Magic numbers in calculations
  
- **Required**:
  - All reservoir properties from MRST/Octave
  - Provenance metadata for every dataset
  - Timestamp, script name, parameters tracking

**Enforcement:**
- `validate_kiss.py`: Detects violations in real-time
- Blocks generation with hard-coded values
- Requires explicit data sources

### Rule 01: Code Style

**Structure Requirements:**

#### Function Design
- **Maximum Length**: 40 lines (ideally under 30)
- **Single Responsibility**: One clear purpose per function
- **Helper Functions**: Required for multi-step operations

#### Naming Conventions
- **Style**: snake_case throughout (no camelCase, PascalCase)
- **Descriptive**: Self-explanatory names required
- **No Generic Names**: Avoid foo, bar, temp, data

#### Comment Standards
- **Language**: ALL COMMENTS IN ENGLISH
- **Structure**: Step/substep format mandatory
- **Visual Separators**: Required for major sections

**Step Format:**
```
# ----------------------------------------
# Step N – High-level description
# ----------------------------------------
```

**Substep Format:**
```
# Substep N.M – Specific action ______________________
```

**Inline Actions:**
- ✅ Validate inputs
- 🔄 Process/transform data
- 📊 Generate results
- ⚠️ Handle edge cases
- 🔍 Search/filter operations

**Import Organization:**
1. Standard library imports
2. External package imports
3. Internal module imports

**Enforcement:**
- `validate-code-style.sh`: Real-time validation
- Checks function length, naming, comment format
- Blocks non-compliant code

### Rule 02: Code Change Boundaries

**Scope Control:**
- **Edit Only**: The specific function/class/block requested
- **Find Smallest Block**: Minimal change principle
- **Preserve Structure**: Maintain existing organization

**Multi-File Changes:**
- **Allowed For**:
  - Clear cross-file dependencies
  - Web application components
  - Pipeline updates
  - Test-implementation pairs

**Prohibited Actions:**
- Inserting debug code in production
- Adding logging to core functions
- Modifying unrelated code sections

**Output Requirements:**
- Return only modified sections
- Include context markers
- Preserve indentation exactly

**Enforcement:**
- `validate-scope.py`: Boundary checking
- Detects out-of-scope modifications
- Ensures structural integrity

### Rule 03: Test Script Standards

**Location Requirements:**
- **Directory**: All tests in `/workspace/tests/`
- **Git Status**: Entire folder in `.gitignore`
- **No Production Import**: Tests never imported by src/

**Naming Convention:**
```
test_<NN>_<folder>_<module>[_<purpose>].<ext>
```

**Structure Requirements:**

Python Tests:
```python
def test_<method>_<case>():
    """Test description"""
    # Arrange
    # Act  
    # Assert
```

Octave Tests:
```matlab
function test_<method>_<case>()
    % Test description
    % Arrange
    % Act
    % Assert
end
```

**Test Principles:**
- Each file tests single module/class
- Self-contained execution
- Clear assert statements
- Isolated from production

**Enforcement:**
- `route-files.sh`: Automatic test detection
- Routes test files to correct directory
- Validates test structure

### Rule 04: Debug Script Management

**Location Requirements:**
- **Directory**: All debug in `/workspace/debug/`
- **Git Status**: Entire folder in `.gitignore`
- **Isolation**: Never imported by any code

**Naming Convention:**
```
dbg_<slug>[_<experiment>].<ext>
```

**Debug Features Allowed:**
- Extensive print statements
- Temporary logging
- Performance profiling
- Data inspection

**Cleanup Requirements:**
- Remove all debug code before final commit
- No debug artifacts in production
- Clean, noise-free final code

**Enforcement:**
- `route-files.sh`: Automatic debug detection
- `validate-debug-security.sh`: Security checks
- Prevents debug code in production

### Rule 05: File Naming Conventions

**General Rules:**
- **Case**: snake_case for all files
- **Characters**: No spaces, accents, or special chars
- **Language**: English names only

**Script Patterns:**

Step-based Scripts:
```
sNN[x]_<verb>_<noun>.<ext>
```
- `s` = fixed prefix
- `NN` = two-digit index (00-99)
- `x` = optional substep (a-z)

Special Scripts:
- Main launcher: `s99_*` (appears last)
- Test files: `test_NN_*`
- Debug files: `dbg_*`

**Documentation Naming:**
```
<NN>_<descriptive_slug>.md
```

**Enforcement:**
- `validate-file-naming.sh`: Pattern checking
- Blocks non-compliant names
- Suggests corrections

### Rule 06: Documentation Enforcement

**Required Documentation:**

#### Python Requirements
- **Docstrings**: Google Style mandatory
- **Scope**: All public functions/classes
- **Non-trivial Private**: Documentation required

#### Octave Requirements
- **Comment Blocks**: Standard help format
- **Scope**: All public functions
- **Format**: Structured sections

**Module Headers:**
Every file must start with purpose description

**Structure Requirements:**
1. One-line summary (required)
2. Detailed description (optional)
3. Args section (if applicable)
4. Returns section (if applicable)
5. Raises section (if applicable)

**Style Guidelines:**
- Google Style formatting only
- Under 100 words typical
- Avoid vague descriptions
- English only

**Enforcement:**
- `validate-docstrings.sh`: Format validation
- Checks presence and structure
- Validates Google Style compliance

### Rule 07: Documentation File Standards

**File Organization:**
```
docs/
├── English/
│   └── NN_<topic>.md
└── Spanish/
    └── NN_<topic>.md
```

**Required Sections:**
1. **Title and Purpose**: One-sentence summary
2. **Workflow Description**: Numbered steps
3. **Inputs and Outputs**: Clear specifications
4. **Mathematical Explanation**: LaTeX when applicable
5. **Code Reference**: Source module paths

**Quality Standards:**
- Clear, concise writing
- Current behavior only (no speculation)
- Mermaid diagrams for workflows
- LaTeX in code blocks for math

**Enforcement:**
- Manual review process
- Template compliance checking
- Language-specific validation

### Rule 08: Logging and Output Policy

**Development Phase:**
- `print()`/`disp()` allowed temporarily
- Must be removed before commit
- Use for debugging only

**Allowed Exceptions:**
- CLI tool output
- Demo notebooks
- User-facing feedback
- MRST simulation progress
- Error messages

**Production Logging:**

Python:
```python
import logging
logger = logging.getLogger(__name__)
logger.info("Message")
```

Octave:
```matlab
warning('[INFO] Message');
error('[ERROR] Message');
```

**Language Requirement:**
- ALL output in English
- No multilingual messages
- Consistent formatting

**Enforcement:**
- `cleanup-print-statements.sh`: Automatic removal
- Detects unauthorized print/disp
- Post-processing cleanup

## Rule Interactions and Dependencies

### Hierarchical Dependencies

```
Rule 00 (KISS) 
    └── Rule 01 (Style)
        └── Rule 05 (Naming)
            └── Rule 06 (Documentation)

Rule 03 (Tests) ←→ Rule 04 (Debug)
    └── Rule 08 (Logging)

Rule 02 (Scope) → All other rules
```

### Cross-Rule Validation

1. **Style + Documentation**: Consistent formatting
2. **Naming + Routing**: Automatic file placement
3. **KISS + Scope**: Minimal change principle
4. **Tests + Debug**: Complete isolation

## Enforcement Pipeline

### Pre-Generation Phase

1. **Intent Analysis**: Determine applicable rules
2. **Context Loading**: Load relevant rules
3. **Template Selection**: Choose appropriate template

### Validation Phase

Parallel execution of:
- Style validation (Rule 01)
- Scope validation (Rule 02)
- Naming validation (Rule 05)
- KISS validation (Rule 00)

### Post-Generation Phase

Sequential execution of:
1. Documentation validation (Rule 06)
2. Output cleanup (Rule 08)
3. Final formatting

### Blocking Mechanisms

**Hard Blocks** (Exit code 2):
- KISS violations
- Wrong file location
- Missing documentation
- Scope violations

**Soft Warnings** (Exit code 1):
- Style suggestions
- Naming improvements
- Documentation enhancements

## Rule Evolution

### Adding New Rules

1. Create `NN-rule-name.md` in `rules/`
2. Define clear constraints
3. Provide examples
4. Create validation hook
5. Update documentation

### Modifying Rules

1. Version control all changes
2. Update validation hooks
3. Communicate changes
4. Gradual enforcement

### Deprecating Rules

1. Mark as deprecated
2. Provide migration path
3. Update validators
4. Remove after transition

## Compliance Metrics

### Measurement Points

1. **Pre-generation**: Rule loading
2. **Validation**: Pass/fail rates
3. **Post-generation**: Cleanup actions
4. **Overall**: Compliance percentage

### Tracking Mechanisms

- Hook execution logs
- Validation results
- Metadata tracking
- Git commit analysis

## Best Practices

### For Rule Creation

1. **Specificity**: Clear, measurable constraints
2. **Examples**: Both good and bad patterns
3. **Rationale**: Explain the "why"
4. **Enforcement**: Automated validation

### For Rule Compliance

1. **Templates**: Start with templates
2. **Early Validation**: Check before writing
3. **Incremental Changes**: Small, focused edits
4. **Documentation**: Always included

## Conclusion

Claude Code's rules system provides a comprehensive framework for maintaining code quality, consistency, and best practices across the entire project. Through its eight interrelated rules and sophisticated enforcement mechanisms, it ensures that every line of generated code meets the highest standards while remaining practical and maintainable. The system's strength lies not just in its rules, but in its automated, deterministic enforcement that prevents violations before they occur.