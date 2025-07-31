# Hook System - Pre/Post Tool Validation

## Overview

Claude Code's hook system implements a sophisticated event-driven architecture that intercepts tool operations at critical points, enabling validation, transformation, and intelligent routing. This document details the complete hook infrastructure and execution patterns.

## Hook Architecture

### Event Types

The system supports four primary hook events:

1. **UserPromptSubmit**: Triggered when user submits input
2. **PreToolUse**: Triggered before tool execution
3. **PostToolUse**: Triggered after tool execution
4. **Stop**: Triggered at session end

### Hook Configuration Format

```json
{
  "hooks": {
    "EventType": [
      {
        "matcher": "ToolPattern",
        "hooks": [
          {
            "type": "command",
            "command": "/path/to/script.sh",
            "args": ["$VARIABLE1", "$VARIABLE2"]
          }
        ]
      }
    ]
  }
}
```

## Global Hook Inventory

### File Routing Hook

**File**: `route-files.sh`
**Purpose**: Intelligent file placement based on patterns and content
**Triggers**: Write, Edit, MultiEdit operations

**Detection Patterns**:
- Filename patterns (test_*, dbg_*, s##_*)
- Content analysis (imports, functions, patterns)
- Confidence scoring (high/medium/low)

**Routing Logic**:
```
test_*.py → /workspace/tests/
dbg_*.m → /workspace/debug/
s##_*.m → /workspace/mrst_simulation_scripts/
*dashboard*.py → /workspace/dashboard/
s##_*.py → /workspace/src/
```

**Exit Codes**:
- 0: File in correct location
- 1: Suggestion provided (non-blocking)
- 2: High-confidence suggestion (could block)

### Pre-Write Validation Hook

**File**: `pre-write-validation.sh`
**Purpose**: Orchestrates all validation checks before write operations
**Triggers**: Write operations only

**Validation Sequence**:
1. File naming validation
2. Code style validation
3. Docstring validation (Python only)
4. Print statement detection

**Aggregation Logic**:
- Counts total errors
- Provides consolidated feedback
- Blocks on any critical error

### Code Style Validation Hook

**File**: `validate-code-style.sh`
**Purpose**: Enforces Rule 01 code style requirements
**Triggers**: Write, Edit operations

**Validation Checks**:
- Function length (<40 lines)
- Naming conventions (snake_case)
- Comment language (English only)
- Step/substep format
- Import organization

**Smart Features**:
- Context-aware validation
- Specific error messages
- Line number reporting

### Docstring Validation Hook

**File**: `validate-docstrings.sh`
**Purpose**: Enforces Rule 06 documentation requirements
**Triggers**: Post-write on Python files

**Validation Scope**:
- Google Style format
- Required sections presence
- English language only
- Length constraints

**Parsing Logic**:
- AST-based analysis
- Function/class detection
- Docstring extraction

### File Naming Validation Hook

**File**: `validate-file-naming.sh`
**Purpose**: Enforces Rule 05 naming conventions
**Triggers**: All file operations

**Pattern Matching**:
```bash
# Script patterns
^s[0-9]{2}[a-z]?_[a-z_]+\.(py|m)$

# Test patterns  
^test_[0-9]{2}_[a-z_]+\.(py|m)$

# Debug patterns
^dbg_[a-z_]+\.(py|m)$
```

**Validation Rules**:
- No spaces or special characters
- English names only
- Correct prefixes
- Appropriate extensions

### Bash Command Validation Hook

**File**: `validate-bash-commands.sh`
**Purpose**: Security validation for bash operations
**Triggers**: Bash tool usage

**Security Checks**:
- Dangerous command detection
- Path traversal prevention
- Environment variable safety
- Command injection prevention

**Blocked Patterns**:
- `rm -rf /`
- `eval` with user input
- Unquoted variables
- Pipe to shell

### Multi-Edit Scope Validation Hook

**File**: `validate-multiedit-scope.sh`
**Purpose**: Ensures Rule 02 compliance for batch edits
**Triggers**: MultiEdit operations

**Validation Logic**:
- Scope boundary checking
- Edit sequence validation
- Conflict detection
- Atomicity verification

### Task Security Validation Hook

**File**: `validate-task-security.sh`
**Purpose**: Prevents malicious task execution
**Triggers**: Task tool usage

**Security Analysis**:
- Prompt content scanning
- Subagent type validation
- Resource limit checking
- Output sanitization

### TODO Format Validation Hook

**File**: `validate-todo-format.sh`
**Purpose**: Ensures consistent TODO formatting
**Triggers**: TodoWrite operations

**Format Requirements**:
- Valid status values
- Priority levels
- ID uniqueness
- Content clarity

### Print Statement Cleanup Hook

**File**: `cleanup-print-statements.sh`
**Purpose**: Removes unauthorized print/logging statements
**Triggers**: Post-write/edit operations

**Cleanup Actions**:
- Detect print() in Python
- Detect disp() in Octave
- Remove or comment out
- Log cleanup actions

## Area-Specific Hooks

### ML/Source Hooks (`/workspace/src/.claude/hooks/`)

**validate-ml-patterns.sh**:
- ML best practice enforcement
- Data leakage prevention
- Model serialization standards
- Feature engineering patterns

**validate-python-imports.sh**:
- Import order validation
- Unused import detection
- Circular dependency prevention
- Standard aliasing enforcement

### Test Hooks (`/workspace/tests/.claude/hooks/`)

**validate-test-patterns.sh**:
- Test structure validation
- Assertion presence
- Test isolation verification
- Naming convention checks

**validate-test-coverage.sh**:
- Coverage threshold enforcement
- Missing test detection
- Test completeness analysis

### Debug Hooks (`/workspace/debug/.claude/hooks/`)

**validate-debug-security.sh**:
- Sensitive data detection
- Production code isolation
- Temporary file management
- Output sanitization

**cleanup-temp-files.sh**:
- Automatic temp file removal
- Debug artifact cleanup
- Log rotation

### Dashboard Hooks (`/workspace/dashboard/.claude/hooks/`)

**validate-streamlit-patterns.sh**:
- Streamlit best practices
- State management validation
- Component structure checks
- Performance patterns

**validate-viz-components.sh**:
- Visualization consistency
- Color scheme validation
- Accessibility checks
- Responsive design

### Documentation Hooks (`/workspace/obsidian-vault/.claude/hooks/`)

**validate-markdown-structure.sh**:
- Heading hierarchy
- Link format validation
- Image reference checks
- Table formatting

**validate-frontmatter.sh**:
- Required fields presence
- Date format validation
- Tag consistency
- Metadata completeness

## Hook Execution Flow

### Sequential Flow Diagram

```
User Input
    ↓
UserPromptSubmit Hooks
    ├─→ Load rules notification
    └─→ Context injection
    ↓
Tool Selection
    ↓
PreToolUse Hooks (Parallel)
    ├─→ route-files.sh
    ├─→ validate-code-style.sh
    ├─→ validate-file-naming.sh
    └─→ area-specific validators
    ↓
[All Pass?] → No → Block Operation
    ↓ Yes
Tool Execution
    ↓
PostToolUse Hooks (Sequential)
    ├─→ validate-docstrings.sh
    ├─→ cleanup-print-statements.sh
    └─→ area-specific post-processors
    ↓
Stop Hooks
    ├─→ metadata tracking
    └─→ session cleanup
```

### Parallel Execution

PreToolUse hooks execute in parallel for performance:

```bash
# Parallel execution with wait
{
  validate-code-style.sh "$@" &
  validate-file-naming.sh "$@" &
  route-files.sh "$@" &
  validate-scope.sh "$@" &
} 
wait
```

### Error Aggregation

```bash
errors=0
for validator in "${validators[@]}"; do
  if ! "$validator" "$@"; then
    ((errors++))
  fi
done

if [ $errors -gt 0 ]; then
  exit 2  # Block operation
fi
```

## Hook Development Guidelines

### Exit Code Convention

- **0**: Success, continue operation
- **1**: Warning, non-blocking suggestion
- **2**: Error, block operation

### Variable Access

Available variables depend on the tool:

**Write Tool**:
- `$FILE_PATH`: Target file path
- `$CONTENT`: File content

**Edit Tool**:
- `$FILE_PATH`: Target file path
- `$OLD_STRING`: Text to replace
- `$NEW_STRING`: Replacement text

**MultiEdit Tool**:
- `$FILE_PATH`: Target file path
- `$EDITS`: JSON array of edits

### Performance Considerations

1. **Timeout**: Keep execution under 2 seconds
2. **Resource Usage**: Minimal CPU/memory
3. **I/O Operations**: Batch when possible
4. **Caching**: Use for repeated validations

### Error Messaging

```bash
echo "❌ ERROR: Clear description of problem"
echo "   File: $FILE_PATH"
echo "   Line: $line_number"
echo "   Issue: Specific violation"
echo "   Fix: How to resolve"
```

## Hook Integration Patterns

### Conditional Execution

```json
{
  "matcher": "Write",
  "condition": "*.py",
  "hooks": [...]
}
```

### Hook Chaining

```json
{
  "hooks": [
    {
      "type": "command",
      "command": "validator1.sh",
      "continueOnError": false
    },
    {
      "type": "command", 
      "command": "validator2.sh",
      "dependsOn": "validator1"
    }
  ]
}
```

### Dynamic Arguments

```bash
# Access tool-specific variables
case "$TOOL_NAME" in
  "Write")
    validate_content "$CONTENT"
    ;;
  "Edit")
    validate_edit "$OLD_STRING" "$NEW_STRING"
    ;;
esac
```

## Debugging Hooks

### Enable Debug Mode

```bash
export CLAUDE_DEBUG=1
export CLAUDE_HOOK_VERBOSE=1
```

### Hook Logs

Location: `/workspace/.claude/logs/hooks/`

Format:
```
[timestamp] [hook-name] [exit-code] [duration]
[timestamp] Input: <arguments>
[timestamp] Output: <stdout>
[timestamp] Errors: <stderr>
```

### Testing Hooks

```bash
# Test individual hook
./validate-code-style.sh test.py "test content"

# Test hook pipeline
simulate-hook-pipeline.sh Write test.py "content"
```

## Best Practices

### Hook Design

1. **Single Responsibility**: One validation per hook
2. **Fast Failure**: Exit early on first error
3. **Clear Feedback**: Specific error messages
4. **Idempotency**: Same result on repeated runs

### Security

1. **Input Sanitization**: Validate all arguments
2. **Path Security**: Prevent directory traversal
3. **Command Injection**: Quote all variables
4. **Resource Limits**: Prevent DoS

### Maintenance

1. **Version Control**: Track all changes
2. **Documentation**: Comment complex logic
3. **Testing**: Unit tests for hooks
4. **Monitoring**: Track execution metrics

## Advanced Features

### Context-Aware Validation

Hooks can access session context:
- Current directory
- Git branch
- Environment variables
- Previous operations

### Machine Learning Integration

Some hooks use ML for:
- Pattern detection
- Anomaly identification
- Style consistency
- Security analysis

### Adaptive Behavior

Hooks can adapt based on:
- User preferences
- Project phase
- File history
- Team standards

## Conclusion

Claude Code's hook system provides a powerful, flexible infrastructure for enforcing code quality and standards through event-driven validation. By intercepting operations at critical points and executing targeted validations in parallel, it ensures that every code generation operation meets project standards while maintaining high performance. The system's extensibility allows for continuous improvement and adaptation to evolving project needs.