# Geomechanical ML Project with Claude Code Integration

This project demonstrates a complete integration of Claude Code with strict coding standards for a geomechanical machine learning project using Python and Octave/MRST.

## 🎯 Project Overview

A machine learning pipeline for geomechanical reservoir analysis with:
- **Strict coding standards** enforced automatically
- **Claude Code integration** for AI-assisted development
- **Dual language support** (Python & Octave/MRST)
- **Automated validation** and compliance checking

## 🏗️ Project Structure

```
📦 workspace/
├── 🤖 .claude/              # Claude Code configuration
│   ├── commands/            # Custom slash commands
│   ├── hooks/              # Validation hooks
│   ├── templates/          # Code generation templates
│   └── settings.json       # Project settings
├── 🐍 src/                 # Python source code
├── 📊 mrst_simulation_scripts/  # Octave/MRST scripts
├── 🧪 tests/              # Test files (gitignored)
├── 🐛 debug/              # Debug scripts (gitignored)
├── 📖 docs/               # Documentation
├── 📋 rules/              # Project coding rules
└── 🧠 CLAUDE.md           # Main project memory
```

## 🚀 Quick Start

### 1. Prerequisites
```bash
# Install Claude Code
npm install -g @anthropic-ai/claude-code

# Install Python dependencies
pip install ruff pylint pydocstyle pytest pre-commit

# Install pre-commit hooks
pre-commit install
```

### 2. Start Claude Code
```bash
claude --continue
```

### 3. Create Your First Script
```bash
# In Claude Code session
/new-script 01 load data python
```

## 🎮 Custom Commands

### Core Commands
| Command | Description | Example |
|---------|-------------|---------|
| `/new-script` | Create workflow script | `/new-script 02 process data python` |
| `/new-test` | Create test file | `/new-test src/s01_load_data.py` |
| `/new-debug` | Create debug script | `/new-debug src/s01_load_data.py memory_issue` |
| `/validate` | Check compliance | `/validate src/` |
| `/cleanup` | Clean before commit | `/cleanup src/s01_load_data.py` |

### Parallel Execution Commands
| Command | Description | Example |
|---------|-------------|---------|
| `/parallel-features` | Create multiple feature worktrees | `/parallel-features auth logging dashboard` |
| `/parallel-review` | Deploy specialized review agents | `/parallel-review src/ security,performance,style` |
| `/parallel-test` | Run tests across environments | `/parallel-test all python3.9,python3.10,octave` |
| `/parallel-explore` | Multi-agent codebase analysis | `/parallel-explore src/ architecture,dependencies` |
| `/merge-worktrees` | Consolidate parallel work | `/merge-worktrees sequential auth logging` |

## 📏 Coding Standards

### File Naming Convention
- **Workflow scripts**: `sNN[x]_<verb>_<noun>.<ext>`
  - ✅ `s01_load_data.py`
  - ✅ `s02a_setup_field.m`
- **Test files**: `test_NN_<folder>_<module>.<ext>`
  - ✅ `test_01_src_load_data.py`
- **Debug files**: `dbg_<slug>.<ext>`
  - ✅ `dbg_convergence_issue.py`

### Code Style Rules
- 🎯 **KISS Principle**: Keep it simple, no speculative abstractions
- 📏 **Function length**: Maximum 40 lines
- 🐍 **Naming**: snake_case for all identifiers
- 🌍 **Language**: English-only comments and documentation
- 📝 **Docstrings**: Google Style for all public functions
- 🚫 **Try/Catch**: Only for I/O operations, never silence errors

### Step/Substep Structure
```python
# ----------------------------------------
# Step 1 – High-level action
# ----------------------------------------

# Substep 1.1 – Specific sub-action ______________________
# ✅ Validate inputs
# 🔄 Process data
# 📊 Return results
```

## 🔧 Validation Hooks

Automatic validation runs on every file operation:

| Hook | When | Checks |
|------|------|--------|
| **Pre-write** | Before creating/editing | File naming, code style, docstrings |
| **Post-write** | After file changes | Print statements, cleanup needs |
| **Pre-commit** | Before git commit | All rules, linting, security |

## 📊 Examples

### Python Module
```python
"""
Load and preprocess reservoir data from various sources.

Key components:
- CSV data loading with validation
- Data normalization and scaling
"""

def load_reservoir_data(file_path: str) -> pd.DataFrame:
    """Load reservoir data from CSV file.
    
    Args:
        file_path: Path to the CSV file.
        
    Returns:
        DataFrame with loaded data.
        
    Raises:
        FileNotFoundError: If file doesn't exist.
    """
    # ✅ Validate inputs
    if not os.path.exists(file_path):
        raise FileNotFoundError(f"File not found: {file_path}")
    
    # 🔄 Load and return data
    return pd.read_csv(file_path)
```

### Octave/MRST Script
```matlab
% Setup reservoir model with heterogeneous properties
% Requires: MRST

function [G, rock] = create_reservoir_model(nx, ny, nz, dims)
    % PURPOSE: Create 3D reservoir grid
    % INPUTS:
    %   nx, ny, nz - Grid dimensions
    %   dims       - Physical dimensions [Lx, Ly, Lz]
    % OUTPUTS:
    %   G    - Grid structure
    %   rock - Rock properties
    
    % ✅ Validate inputs
    assert(all([nx, ny, nz] > 0), 'Dimensions must be positive');
    
    % 🔄 Create grid
    G = cartGrid([nx, ny, nz], dims);
    G = computeGeometry(G);
    
    % 📊 Return results
    rock = makeRock(G, 100*milli*darcy, 0.2);
end
```

## 🔍 Validation Example

```bash
# Files are automatically validated
❌ ERROR: File 'loadData.py' does not follow naming convention
Expected pattern: sNN[x]_<verb>_<noun>.py
Example: s01_load_data.py

✅ File naming validation passed
✅ Code style validation passed
✅ Docstring validation passed
⚠️  WARNING: Found print() statements (remove before commit)
```

## 🚦 CI/CD Integration

GitHub Actions automatically:
- ✅ Validates file naming
- ✅ Checks code style
- ✅ Verifies docstrings
- ✅ Runs linting
- ✅ Ensures project structure

## 📚 Documentation

- [Setup Guide](obsidian-vault/English/00_setup_guide.md) - Complete setup instructions
- [Code Examples](obsidian-vault/English/01_code_generation_examples.md) - Proper code examples
- [Project Rules](rules/) - Detailed coding standards

## 🤝 Contributing

1. Follow the naming conventions
2. Use `/validate` before committing
3. Ensure all hooks pass
4. Write tests in `tests/` (gitignored)
5. Use `debug/` for troubleshooting (gitignored)

## 🔗 Key Features

### ✨ Automatic Code Generation
- Templates ensure consistency
- Validation prevents rule violations
- Step-by-step guided structure

### 🛡️ Quality Assurance
- Pre-commit hooks block bad code
- Real-time validation feedback
- Comprehensive rule checking

### 🎓 Learning Integration
- Claude Code learns project patterns
- Context-aware suggestions
- Memory system for consistency

### 📈 Productivity Boost
- Custom slash commands
- Template-based generation
- Automated cleanup and validation

### 🤖 Parallel Execution
- **Git Worktrees**: Complete isolation for feature development
- **Task Tool**: Concurrent specialized agents (up to 10)
- **Multi-Agent Review**: Security, performance, style, architecture agents
- **Parallel Testing**: Cross-environment and cross-version testing
- **Codebase Exploration**: Concurrent analysis by specialized agents

---

**Powered by Claude Code** - AI-assisted development with strict quality standards.