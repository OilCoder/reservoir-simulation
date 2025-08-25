# Eagle West Field MRST Simulation Project

A comprehensive reservoir simulation project using MRST (MATLAB Reservoir Simulation Toolbox) with Claude Code integration for AI-assisted development and strict coding standards.

## 🎯 Project Overview

A complete MRST-based simulation workflow for the Eagle West Field with:
- **100% YAML-Documentation coverage** achieved across 9 configuration files
- **900+ variable inventory** with LLM-optimized organization
- **Multi-agent architecture** for efficient code generation and task management
- **Complete MRST simulation workflow** - 25/25 integrated scripts working
- **Canonical data organization** with native .mat format and oct2py compatibility
- **Enhanced analytics & diagnostics** with ML-ready features
- **Comprehensive testing framework** with 38+ test files
- **Strict coding standards** enforced automatically
- **Dual language support** (Python & Octave/MRST)

## 🏗️ Project Structure

```
📦 workspace/
├── 🤖 .claude/              # Claude Code configuration
│   ├── agents/             # Specialized agent definitions (coder, tester, debugger)
│   ├── commands/            # Custom slash commands
│   ├── hooks/              # Validation hooks
│   ├── rules/              # Project coding rules (8 comprehensive rules)
│   ├── templates/          # Code generation templates
│   └── settings.json       # Project settings
├── 🐍 src/                 # Python source code
├── 📊 mrst_simulation_scripts/  # Octave/MRST scripts (25+ workflow steps)
│   ├── config/             # YAML configuration files (9 files, 100% documented)
│   ├── s01_initialize_mrst.m - s25_reservoir_analysis.m
│   ├── s99_run_workflow.m  # Complete workflow runner
│   └── tests/              # MRST test files
├── 📖 obsidian-vault/      # Documentation system
│   ├── Planning/Reservoir_Definition/  # Technical documentation
│   └── Spanish/            # Spanish documentation
├── 🧪 tests/              # Test files (gitignored)
├── 🐛 debug/              # Debug scripts (gitignored)
├── 📊 data/               # Simplified 6-file data structure
│   └── simulation_data/   # Complete Eagle West Field model (6 canonical files)
└── 🧠 CLAUDE.md           # Main project memory and instructions
```

## 📊 Data Structure

**Simple 6-File Eagle West Field Model**

```
data/simulation_data/
├── grid.mat           # Complete geometry with faults and structure
├── rock.mat           # Final petroPhysical properties with heterogeneity  
├── fluid.mat          # Complete 3-phase fluid system with PVT
├── state.mat          # Initial pressure and saturation distribution
├── wells.mat          # 15-well system with completions and controls
└── schedule.mat       # Development plan and solver configuration
```

### Script Contributions
| File | Created By | Updated By | Contains |
|------|------------|------------|----------|
| `grid.mat` | s03 (PEBI grid) | s04 (structure), s05 (faults) | Complete geometry with 5 faults |
| `rock.mat` | s06 (base props) | s07 (layers), s08 (heterogeneity) | Spatially varying properties |
| `fluid.mat` | s02 (basic fluid) | s09 (relperm), s10 (capillary), s11 (PVT) | Complete 3-phase system |
| `state.mat` | s12 (pressure) | s13 (saturations), s14 (aquifer) | Initial conditions |
| `wells.mat` | s15 (placement) | s16 (completions) | 15 wells with controls |
| `schedule.mat` | s17 (controls) | s18 (schedule), s19 (targets) | Development plan |

### Key Features
- **Single Location**: All data in `/workspace/data/simulation_data/`
- **MRST Ready**: Standard MRST structures for direct simulation use
- **Complete Model**: 2,600-acre Eagle West Field with 41×41×12 grid
- **15 Wells**: 10 producers (EW-001 to EW-010) + 5 injectors (IW-001 to IW-005)
- **5 Major Faults**: Fault_A through Fault_E with transmissibility effects

## 🚀 Quick Start

### 1. Prerequisites
```bash
# Install Claude Code
npm install -g @anthropic-ai/claude-code

# Install Python dependencies  
pip install ruff pylint pydocstyle pytest pre-commit

# Install Octave and MRST dependencies
sudo apt install octave
# Download MRST from www.sintef.no/mrst
```

### 2. Start MRST Simulation
```bash
# Initialize MRST environment
octave mrst_simulation_scripts/s01_initialize_mrst.m

# Run complete workflow (corrected sequence: s01→s02→s05→s03→s04→s06→s07→s08)
octave mrst_simulation_scripts/s99_run_workflow.m

# Run enhanced diagnostics
octave mrst_simulation_scripts/s22_run_simulation_with_diagnostics.m

# Run comprehensive testing
octave tests/test_05_run_all_tests.m
```

### 3. Start Claude Code
```bash
claude --continue
```

### 4. Use the Variable Inventory for LLM Context
- **Primary Reference**: `obsidian-vault/Planning/Reservoir_Definition/VARIABLE_INVENTORY.md`
- **900+ variables** organized by workflow stages and domains
- **LLM-optimized structure** for understanding project complexity

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

### 🎯 Critical References for LLMs
- **[VARIABLE_INVENTORY.md](obsidian-vault/Planning/Reservoir_Definition/VARIABLE_INVENTORY.md)** - 900+ variables with LLM-optimized structure
- **[CLAUDE.md](CLAUDE.md)** - Project memory and AI assistant instructions
- **[12_Technical_Variable_Mapping.md](obsidian-vault/Planning/Reservoir_Definition/12_Technical_Variable_Mapping.md)** - Standardized variable naming

### 📊 MRST Simulation Documentation
- **[01_Structural_Geology.md](obsidian-vault/Planning/Reservoir_Definition/01_Structural_Geology.md)** - Field structure and grid design (41×41×12 cells)
- **[05_Wells_Completions.md](obsidian-vault/Planning/Reservoir_Definition/05_Wells_Completions.md)** - 15 wells (10 producers, 5 injectors)
- **[10_Solver_Configuration.md](obsidian-vault/Planning/Reservoir_Definition/10_Solver_Configuration.md)** - MRST solver setup

### 🔧 Development Standards
- **[Project Rules](.claude/rules/)** - 8 comprehensive coding rules
- **[Agent System](CLAUDE.md#agent-system)** - Multi-agent architecture documentation

## 🤝 Contributing

### For MRST Development
1. Check **VARIABLE_INVENTORY.md** for existing variables before creating new ones
2. Follow Fault_A/Fault_B naming convention (underscore format)
3. Use EW-XXX/IW-XXX format for well names
4. Maintain 41×41×12 grid dimensions for consistency
5. Update YAML configs and documentation simultaneously

### For General Development
1. Follow the naming conventions in [Project Rules](.claude/rules/)
2. Use `/validate` before committing
3. Ensure all hooks pass
4. Write tests in `tests/` (gitignored)
5. Use `debug/` for troubleshooting (gitignored)

## 🔗 Key Features

### 📊 MRST Simulation Capabilities
- **Complete Workflow**: 25/25 integrated simulation scripts (s01-s25, s99) - ALL WORKING
- **Corrected Dependencies**: s01→s02→s05→s03→s04→s06→s07→s08 sequence
- **PEBI Grid Construction**: Fault-conforming geometry with size-field optimization
- **Simplified Data Structure**: 6 canonical .mat files with complete Eagle West Field model
- **Enhanced Analytics**: ML-ready features and solver diagnostics (s22, s24)
- **100% Documentation Coverage**: All 9 YAML config files fully documented
- **Eagle West Field Model**: Realistic offshore field with 41×41×12 grid
- **15-Well Development**: 6-phase development plan with ESP systems
- **Fault Modeling**: 5 major faults with transmissibility multipliers
- **Comprehensive Testing**: 38+ test files covering all workflow phases

### 🧠 LLM-Optimized Organization
- **Variable Inventory**: 900+ variables organized by workflow stages and domains
- **Technical Mapping**: Standardized YAML↔MATLAB↔Documentation naming
- **Context Helpers**: Decision trees and usage patterns for AI assistance
- **Cross-References**: Variable dependencies and criticality tracking

### ✨ Multi-Agent Architecture
- **Coder Agent**: Production code for src/ and mrst_simulation_scripts/
- **Tester Agent**: Comprehensive test coverage in tests/
- **Debugger Agent**: Problem investigation scripts in debug/
- **Budget-Aware Routing**: Automatic agent selection based on remaining prompts

### 🛡️ Quality Assurance
- **8 Comprehensive Rules**: File naming, code style, documentation enforcement
- **Validation Hooks**: Pre-write, post-write, and pre-commit checking
- **Fail-Fast Policy**: No defensive programming, immediate error reporting
- **Naming Standards**: Enforced sNN_verb_noun.ext pattern

### 🎓 Learning Integration
- **CLAUDE.md Memory**: Project instructions and context for AI consistency
- **Template System**: Code generation templates for all file types
- **Context-Aware**: AI understands project complexity through structured documentation

---

## 📈 Project Status

### ✅ Completed (Latest Session)
- **100% YAML-Documentation Coverage** - All configuration parameters documented
- **Variable Inventory Creation** - 900+ variables with LLM optimization
- **Documentation Inconsistency Fixes** - Grid dimensions, fault naming standardized
- **Technical Variable Mapping** - Standardized naming across all systems

### 🔄 Current State
- **Complete MRST Workflow** - 25/25 phases operational
- **Canonical Data Organization** - Native .mat format with enhanced analytics
- **Enhanced Testing Framework** - 38+ test files with comprehensive coverage
- **Solver Diagnostics** - Advanced analytics and ML-ready features
- **Comprehensive Documentation** - Technical specifications complete
- **AI-Ready Structure** - LLM can navigate and understand project complexity

### 🎯 For New Contributors
1. **Start with VARIABLE_INVENTORY.md** - Your primary reference for understanding the project
2. **Follow CLAUDE.md instructions** - Contains project memory and development patterns
3. **Use the agent system** - Specialized agents for different development tasks
4. **Maintain documentation consistency** - Update both YAML configs and docs together

---

**Powered by Claude Code** - AI-assisted reservoir simulation with comprehensive documentation and strict quality standards.