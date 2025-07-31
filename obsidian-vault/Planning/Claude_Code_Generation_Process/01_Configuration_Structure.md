# Configuration Structure and Hierarchy

## Overview

Claude Code's configuration system implements a sophisticated multi-level hierarchy that provides both global control and area-specific customization. This document details the complete structure and interaction patterns between configuration levels.

## Directory Structure

### Root Configuration (`/workspace/.claude/`)

The master configuration directory containing:

```
.claude/
├── settings.json          # Global hook configurations
├── settings.local.json    # Local overrides and MCP servers
├── rules/                 # Project-wide rule definitions
│   ├── 00-project-guidelines.md
│   ├── 01-code-style.md
│   ├── 02-code-change.md
│   ├── 03-test-script.md
│   ├── 04-debug-script.md
│   ├── 05-file-naming.md
│   ├── 06-doc-enforcement.md
│   ├── 07-docs-style.md
│   └── 08-logging-policy.md
├── hooks/                 # Global validation scripts
│   ├── route-files.sh
│   ├── pre-write-validation.sh
│   ├── validate-code-style.sh
│   ├── validate-docstrings.sh
│   ├── validate-file-naming.sh
│   ├── validate-bash-commands.sh
│   ├── validate-multiedit-scope.sh
│   ├── validate-task-security.sh
│   ├── validate-todo-format.sh
│   └── cleanup-print-statements.sh
├── templates/             # Code generation templates
│   ├── python_module.py
│   ├── python_test.py
│   ├── octave_script.m
│   ├── octave_test.m
│   ├── debug_script.py
│   ├── debug_script.m
│   ├── dashboard_component.py
│   └── reservoir_simulation_script.m
├── commands/              # Custom commands
├── logs/                  # Execution logs
└── scripts/              # Utility scripts
```

### Area-Specific Configurations

Each major project area has its own `.claude` directory with specialized configurations:

#### 1. Source Code (`/workspace/src/.claude/`)
- **Purpose**: ML and data processing validation
- **Special Hooks**: 
  - `validate-ml-patterns.sh`: Ensures ML best practices
  - `validate-python-imports.sh`: Import organization
  - `validate-docstrings.sh`: Documentation compliance

#### 2. Test Directory (`/workspace/tests/.claude/`)
- **Purpose**: Test pattern enforcement
- **Special Hooks**:
  - `validate-test-patterns.sh`: Test structure validation
  - `validate-test-coverage.sh`: Coverage requirements
  - `validate-fixtures.sh`: Test data management

#### 3. Debug Directory (`/workspace/debug/.claude/`)
- **Purpose**: Debug code isolation and security
- **Special Hooks**:
  - `validate-debug-security.sh`: Prevent sensitive data exposure
  - `cleanup-temp-files.sh`: Temporary file management

#### 4. Dashboard (`/workspace/dashboard/.claude/`)
- **Purpose**: Streamlit and visualization standards
- **Special Hooks**:
  - `validate-streamlit-patterns.sh`: UI component standards
  - `validate-viz-components.sh`: Visualization consistency
  - `validate-dashboard-structure.sh`: Layout standards

#### 5. MRST Scripts (`/workspace/mrst_simulation_scripts/.claude/`)
- **Purpose**: MRST-specific conventions
- **Configuration**: Minimal, relies on global rules with MRST focus

#### 6. Documentation (`/workspace/obsidian-vault/.claude/`)
- **Purpose**: Markdown and documentation standards
- **Special Hooks**:
  - `validate-markdown-structure.sh`: Document formatting
  - `validate-links.sh`: Link integrity
  - `validate-frontmatter.sh`: Metadata standards

## Configuration File Formats

### settings.json Structure

The primary configuration file uses a hook-based architecture:

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Write|Edit|MultiEdit",
        "hooks": [
          {
            "type": "command",
            "command": "/path/to/validation/script.sh",
            "args": ["$FILE_PATH", "$CONTENT"]
          }
        ]
      }
    ],
    "PostToolUse": [...],
    "UserPromptSubmit": [...],
    "Stop": [...]
  }
}
```

### Hook Types

1. **PreToolUse**: Executes before tool operations
   - Validates inputs
   - Blocks operations on failure
   - Suggests corrections

2. **PostToolUse**: Executes after tool operations
   - Cleanup and formatting
   - Documentation validation
   - Metadata updates

3. **UserPromptSubmit**: Executes on user input
   - Context injection
   - Intent analysis
   - Rule loading

4. **Stop**: Executes at session end
   - Logging finalization
   - Metadata tracking
   - Cleanup operations

## Configuration Hierarchy

### Inheritance Model

```
Global Rules (/workspace/.claude/rules/)
    ↓
Global Hooks (/workspace/.claude/hooks/)
    ↓
Area-Specific Configurations (*/​.claude/settings.json)
    ↓
Local Overrides (/workspace/.claude/settings.local.json)
```

### Priority Order

1. **Local Overrides**: Highest priority
2. **Area-Specific**: Context-dependent rules
3. **Global Hooks**: Project-wide validation
4. **Global Rules**: Foundation standards

## MCP Server Integration

The `settings.local.json` file enables MCP (Model Context Protocol) servers:

```json
{
  "permissions": {
    "mcp": true
  },
  "mcpServers": {
    "memory": { "command": "..." },
    "filesystem": { "command": "..." },
    "sequential-thinking": { "command": "..." },
    "obsidian": { "command": "..." },
    "time": { "command": "..." }
  }
}
```

### Available MCP Servers

1. **Memory**: Knowledge graph persistence
2. **Filesystem**: Enhanced file operations
3. **Sequential-Thinking**: Complex problem decomposition
4. **Obsidian**: Note management integration
5. **Time**: Temporal operations
6. **IDE**: VS Code integration

## Template System

Templates provide standardized starting points for different file types:

### Python Templates
- `python_module.py`: Standard module structure
- `python_test.py`: Test file structure
- `debug_script.py`: Debug script format

### Octave/MATLAB Templates
- `octave_script.m`: General script structure
- `octave_test.m`: Test script format
- `reservoir_simulation_script.m`: MRST-specific template

### Specialized Templates
- `dashboard_component.py`: Streamlit components
- `debug_script.m`: MATLAB debug format

## Configuration Loading Process

1. **Initialization**
   - Load global `settings.json`
   - Load `settings.local.json` overrides
   - Initialize MCP servers

2. **Context Detection**
   - Analyze file path
   - Identify relevant area configuration
   - Load area-specific settings

3. **Hook Registration**
   - Register global hooks
   - Register area-specific hooks
   - Establish execution order

4. **Validation Pipeline Setup**
   - Configure pre-validation hooks
   - Configure post-processing hooks
   - Set blocking/non-blocking flags

## Best Practices

### Configuration Management

1. **Modularity**: Keep area-specific rules in their directories
2. **DRY Principle**: Use global rules for cross-project standards
3. **Version Control**: Track all configuration changes
4. **Documentation**: Document custom hooks and rules

### Hook Development

1. **Exit Codes**: 
   - 0 = Success (continue)
   - 1 = Warning (non-blocking)
   - 2 = Error (blocking)

2. **Performance**: Keep hooks lightweight and fast
3. **Logging**: Provide clear feedback messages
4. **Idempotency**: Ensure hooks can run multiple times safely

### Template Usage

1. **Consistency**: Maintain standard structure across templates
2. **Placeholders**: Use clear placeholder text
3. **Comments**: Include step/substep structure
4. **Language**: All templates in English

## Extensibility

The configuration system supports easy extension:

### Adding New Rules
1. Create new `.md` file in `/workspace/.claude/rules/`
2. Follow naming convention: `NN-rule-name.md`
3. Document clearly with examples

### Adding New Hooks
1. Create script in appropriate `hooks/` directory
2. Make executable: `chmod +x hook-name.sh`
3. Register in relevant `settings.json`

### Adding New Templates
1. Create template in `/workspace/.claude/templates/`
2. Follow existing naming patterns
3. Include standard headers and structure

## Troubleshooting

### Common Issues

1. **Hook Not Executing**: Check file permissions and paths
2. **Validation Failing**: Review hook output for specific errors
3. **Template Not Found**: Verify template naming and location

### Debug Mode

Enable verbose logging by setting environment variables:
```bash
export CLAUDE_DEBUG=1
export CLAUDE_HOOK_VERBOSE=1
```

## Conclusion

Claude Code's configuration structure provides a powerful, flexible system for enforcing code standards while allowing area-specific customization. Through its hierarchical design, hook-based architecture, and template system, it ensures consistent, high-quality code generation across diverse project areas while maintaining the flexibility to adapt to specific requirements.