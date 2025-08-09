---
description: Consolidated coding rules for maximum prompt efficiency  
---

# COMPACT CODING RULES (≤400 words)

## Core Principles
**KISS Policy**: Write direct, readable code. Single-purpose functions <40 lines. No speculative abstractions.

**Fail Fast**: Validate prerequisites immediately. No defaults for domain parameters (pressure, temperature, coordinates). Error messages must specify what's missing and where to provide it.

**Data Authority**: All domain values from MRST/Octave simulators, never hard-coded. Include provenance metadata (timestamp, script, parameters).

## Code Style
**Naming**: snake_case (Python/Octave). Self-explanatory names, no generics (temp, foo, data1).

**Structure**: Organize with visual headers:
```python  
# ----------------------------------------
# Step 1 – High-level action
# ----------------------------------------
# Substep 1.1 – Specific sub-action ______________________
# ✅ Validate inputs  
# 🔄 Process data
```

**Languages**: ALL code/comments in English only. No Spanish.

**Imports**: Python: standard→external→internal. Octave: addpath() + required toolboxes documented.

## File Naming (snake_case)
**Scripts**: `sNN[x]_<verb>_<noun>.<ext>` (s00a_setup_field.m, s01_prepare_data.py)
**Tests**: `test_<NN>_<module>.m` (test_01_setup_field.m) 
**Debug**: `dbg_<slug>.m` (dbg_pressure_map.m)
**Launcher**: `s99_run_workflow.m` (orchestrator = step 99)

## Scope Control  
**Edit Boundaries**: Modify only specified function/class. Multi-file changes only when explicitly requested.

**No Side Effects**: Don't add logging, debug helpers, or abstractions outside request scope.

## Exception Handling
**Allowed**: File operations, network calls, optional imports, OS operations
**Prohibited**: Flow control via exceptions, input validation shortcuts, silent failures

## Testing & Debug
**Tests**: One file per module in tests/. Comprehensive coverage. No mocked implementations.
**Debug**: Isolate in debug/ folder. Liberal print() allowed for investigation.

## Output Control
**Print Policy**: Temporary print/disp allowed during development. Remove before commits except CLI tools, demos, simulation progress.
**Production**: Use structured logging (Python: logging.getLogger(__name__), Octave: [INFO]/[WARN] prefixes).

## Project Structure
- **src/**: Production Python code
- **mrst_simulation_scripts/**: Octave+MRST workflows  
- **tests/**: Isolated test files
- **debug/**: Investigation scripts
- **obsidian-vault/**: Documentation (English/Spanish)

## Output Format
Return only: unified diff + 1-line title. No explanations or reasoning unless requested.