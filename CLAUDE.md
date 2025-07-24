# Project Code Generation Rules

This project follows strict coding standards for geomechanical ML development using Python and Octave/MRST. The project includes a complete reservoir simulation workflow with interactive dashboard for data visualization and analysis.

## Core Principles

- **KISS (Keep It Simple, Stupid)**: Write the most direct, readable solution. No speculative abstractions.
- **Single Responsibility**: Every function must have one well-defined purpose (<40 lines).
- **English Only**: ALL comments, documentation, and output must be in English.
- **Snake Case**: Use snake_case for all Python and Octave variable/function names.

## File Naming Convention

### Workflow Scripts
- Pattern: `sNN[x]_<verb>_<noun>.<ext>`
  - `s` = Fixed prefix (safe for Octave)
  - `NN` = Two-digit step index (00-99)
  - `x` = Optional sub-step letter (a-z)
  - Examples: `s01_load_data.py`, `s02a_setup_field.m`

### Test Files
- Pattern: `test_NN_<folder>_<module>[_<purpose>].<ext>`
- Location: `/tests/` folder (gitignored)
- Examples: `test_01_src_data_loader.py`

### Debug Files
- Pattern: `dbg_<slug>[_<experiment>].<ext>`
- Location: `/debug/` folder (gitignored)
- Examples: `dbg_pressure_map.m`

### Documentation
- Pattern: `NN_<slug>.md`
- Location: `/obsidian-vault/English/` or `/obsidian-vault/Spanish/`

## Code Style Requirements

### Function Structure
```python
# ----------------------------------------
# Step 1 – High-level action
# ----------------------------------------

# Substep 1.1 – Specific sub-action ______________________
# ✅ Validate inputs
# 🔄 Process data
# 📊 Return results
```

### Try/Except Restrictions
- **Allowed ONLY for true I/O boundaries** (file access, network calls, external APIs)
- **Never silence errors** - always re-raise or log with context
- **Validate first** - use explicit checks instead of catching predictable errors

### Documentation
- **Python**: Google Style docstrings required for all public functions
- **Octave**: Structured comment blocks with purpose, inputs, outputs
- Module headers must include brief purpose description

## Import Project Rules
@rules/00-project-guidelines.md
@rules/01-code-style.md
@rules/02-code-change.md
@rules/03-test-script.md
@rules/04-debug-script.md
@rules/05-file-naming.md
@rules/06-doc-enforcement.md
@rules/07-docs-style.md
@rules/08-logging-policy.md

## Project Structure

### Main Components
- `mrst_simulation_scripts/` - Octave/MRST reservoir simulation workflow
- `dashboard/` - Python Streamlit dashboard for data visualization  
- `config/` - YAML configuration files for simulation parameters
- `src/` - Python ML pipeline components
- `docs/` - Bilingual documentation (English/Spanish)

### Key Configuration
- `config/reservoir_config.yaml` - Main simulation parameters
- `load_mrst.m` - MRST environment setup (project root)

## Common Commands

### Linting & Validation
```bash
# Python linting
ruff check .
pylint src/

# Check file naming
find . -name "*.py" -o -name "*.m" | grep -v test/ -v debug/ | \
  grep -Ev '^\./(src|mrst_simulation_scripts)/s[0-9]{2}[a-z]?_[a-z]+_[a-z]+\.(py|m)$'

# Validate docstrings
pydocstyle --convention=google src/
```

### Testing
```bash
# Run Python tests
pytest tests/ -v

# Run Octave tests
octave --eval "run_tests('tests/')"
```

## Parallel Agent Execution

### Git Worktrees for Concurrent Development
```bash
# Create parallel worktrees for different features
git worktree add ../project-feature-a -b feature-a
git worktree add ../project-feature-b -b feature-b

# Run Claude Code in each worktree
cd ../project-feature-a && claude
cd ../project-feature-b && claude
```

### Task Tool for Subagents
- Use Task tool to spawn multiple subagents for parallel work
- Each subagent has independent context and can work on separate components
- Parallelism capped at 10 concurrent tasks
- Useful for: code review, testing, exploration, independent features

### Custom Parallel Commands
- `/parallel-features`: Create multiple feature branches with worktrees
- `/parallel-review`: Deploy multiple agents for code review
- `/parallel-test`: Run tests across multiple environments
- `/parallel-explore`: Multi-agent codebase analysis
- `/merge-worktrees`: Consolidate work from parallel branches
- `/monitor-agents`: Real-time monitoring dashboard

### Unified Parallel Workflow
```bash
# Complete parallel development workflow
.claude/scripts/parallel-workflow.sh setup-features auth logging dashboard
.claude/scripts/parallel-workflow.sh monitor
.claude/scripts/parallel-workflow.sh review src/ security,performance,style
.claude/scripts/parallel-workflow.sh test all python3.9,python3.10,octave
.claude/scripts/parallel-workflow.sh merge sequential auth logging dashboard
```

## Quick Actions

- Create new script: Use pattern `sNN_verb_noun.ext`
- Add test: Place in `/tests/` with pattern `test_NN_folder_module.ext`
- Debug code: Use `/debug/` folder with `dbg_slug.ext` pattern
- Document: Add to `/obsidian-vault/English/` with `NN_slug.md` pattern
- Parallel work: Use git worktrees or Task tool for concurrent development

## Enforcement

- Pre-commit hooks validate file naming and code style
- CI/CD checks all rules on every push
- Commits blocked if rules violated
- Parallel agents must follow same rules