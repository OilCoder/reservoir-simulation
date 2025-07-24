# Claude Code Setup Guide

This guide explains how to set up and use the Claude Code integration with our project rules.

## Prerequisites

- Node.js 18 or newer
- Python 3.9+
- Git
- Octave (optional, for MRST scripts)

## Installation

1. Install Claude Code globally:
```bash
npm install -g @anthropic-ai/claude-code
```

2. Clone this repository:
```bash
git clone <repository-url>
cd <project-directory>
```

3. Install pre-commit hooks:
```bash
pip install pre-commit
pre-commit install
```

## Project Structure

```
/workspace/
├── .claude/               # Claude Code configuration
│   ├── commands/         # Custom slash commands
│   ├── hooks/           # Validation hooks
│   ├── templates/       # Code generation templates
│   └── settings.json    # Project settings
├── src/                 # Python source code
├── mrst_simulation_scripts/  # Octave/MRST scripts
├── tests/              # Test files (gitignored)
├── debug/              # Debug scripts (gitignored)
├── docs/               # Documentation
│   ├── English/
│   └── Spanish/
├── rules/              # Project coding rules
└── CLAUDE.md           # Main project memory file
```

## Using Claude Code

### Starting a Session

```bash
# Start new session
claude

# Resume previous session
claude --continue
```

### Custom Commands

- `/new-script 01 load data python` - Create new workflow script
- `/new-test src/s01_load_data.py` - Create test for module
- `/new-debug src/s01_load_data.py memory_issue` - Create debug script
- `/validate src/` - Validate all files in directory
- `/cleanup src/s01_load_data.py` - Clean file before commit

### Code Generation

When Claude Code generates code, it automatically:
1. Validates file naming conventions
2. Checks code style compliance
3. Ensures English-only comments
4. Verifies docstring presence
5. Warns about print statements

### Validation Hooks

The following hooks run automatically:
- **Pre-write**: Validates before creating/editing files
- **Post-write**: Checks for cleanup needs
- **User prompt**: Adds project context

## Common Workflows

### 1. Create New Feature

```bash
# Start Claude Code
claude

# Create new script
/new-script 03 process data python

# The script will be created with proper structure
# Edit as needed, validation runs automatically
```

### 2. Debug Issue

```bash
# Create debug script
/new-debug src/s03_process_data.py convergence_issue

# Debug script created in debug/ folder
# Liberal use of prints allowed here
```

### 3. Prepare for Commit

```bash
# Validate all files
/validate all

# Clean up specific file
/cleanup src/s03_process_data.py

# Run pre-commit
pre-commit run --all-files
```

## Rule Violations

If validation fails, you'll see:
- ❌ ERROR: Blocking issues that must be fixed
- ⚠️ WARNING: Non-blocking suggestions

Common violations:
- Wrong file naming pattern
- Non-English comments
- Missing docstrings
- Functions over 40 lines
- Broad try/except blocks

## Tips

1. Always use `/validate` before committing
2. Keep functions under 40 lines
3. Use descriptive snake_case names
4. Write docstrings for all public functions
5. Remove prints before committing
6. Follow the step/substep comment structure

## Troubleshooting

If hooks aren't working:
```bash
chmod +x .claude/hooks/*.sh
```

If commands aren't found:
```bash
# Check commands directory
ls .claude/commands/
```

For more help:
```bash
claude /help
```