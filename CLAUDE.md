# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**Eagle West Field MRST Reservoir Simulation Project** - A comprehensive reservoir simulation project using MRST (MATLAB Reservoir Simulation Toolbox) with complete documentation coverage and AI-assisted development.

**CANONICAL STATUS: This documentation is authoritative and reflects the current project state as of 2025-08-12.**

### Key Achievements

- **100% YAML-Documentation Coverage** - All 9 configuration files fully documented
- **900+ Variable Inventory** - LLM-optimized organization in VARIABLE_INVENTORY.md
- **Complete MRST Workflow** - 25+ integrated simulation scripts (23/25 phases working)
- **Eagle West Field Model** - Realistic offshore field with 41×41×12 grid, 15 wells
- **Multi-Agent Architecture** - Specialized agents for efficient development

### Project Characteristics

- **MRST-based reservoir simulation** for Eagle West offshore field
- **Canon-First Development Philosophy** - Documentation as specification, zero fallbacks
- **Strict coding standards** enforced automatically
- **Claude Code integration** for AI-assisted development
- **Dual language support** (Python & Octave/MRST)
- **Comprehensive documentation** with LLM optimization

## Architecture

📦 workspace/
├── 🤖 .claude/ # Claude Code configuration
│ ├── agents/ # Specialized agent definitions (coder, tester, debugger, doc-writer)
│ ├── commands/ # Custom slash commands
│ ├── hooks/ # Validation hooks
│ ├── rules/ # Project coding rules (8 comprehensive rules)
│ ├── templates/ # Code generation templates
│ └── settings.json # Project settings
├── 🐍 src/ # Python source code
├── 📊 mrst_simulation_scripts/ # Octave/MRST scripts (25+ workflow steps)
│ ├── config/ # YAML configuration files (9 files, 100% documented)
│ ├── s01_initialize_mrst.m → s25_reservoir_analysis.m
│ ├── s99_run_workflow.m # Complete workflow runner
│ └── tests/ # MRST test files  
├── 📖 obsidian-vault/ # Documentation system
│ ├── Planning/Reservoir_Definition/ # Technical documentation (CANONICAL)
│ │ ├── VARIABLE_INVENTORY.md # 900+ variables with LLM optimization
│ └── Spanish/ # Spanish documentation
├── 🧪 tests/ # Test files (gitignored)
├── 🐛 debug/ # Debug scripts (gitignored)
├── 📊 data/ # Simulation data and results
└── 🧠 CLAUDE.md # Main project memory (THIS FILE - CANONICAL)

## Claude Code Agent System (CANONICAL)

**CRITICAL**: Claude Code acts as a **Manager/Orquestador** that delegates tasks to specialized agents rather than executing tasks directly.

### Manager Role

Claude Code (this AI) functions as:
- **Task Analyzer** - Determines which specialized agent should handle each request
- **Work Delegator** - Uses Task tool to assign work to appropriate agents  
- **Coordinator** - Facilitates communication between agents when needed
- **Progress Supervisor** - Ensures agents use MCP tools and follow project rules

**Key Principle**: Claude Code NEVER executes tasks directly - always delegates to specialized agents.

The project uses an **optimized multi-agent architecture** for efficient code generation and task management:

### Available Agents

1. **`coder`** (Default Agent)

   - **Role**: Production code writer for `src/` and `mrst_simulation_scripts/`
   - **Activation**: Default for all code-related tasks
   - **Keywords**: create, implement, write, edit, add, build, develop, function, class, module
   - **Tools**: Read, Write, Edit, MultiEdit, Grep, Glob, Bash

2. **`tester`** (Test Specialist)

   - **Role**: Creates comprehensive test suites in `tests/`
   - **Activation**: On-demand when test keywords detected
   - **Keywords**: test, pytest, unittest, validation, verify, check, assert, coverage
   - **Tools**: Read, Write, Bash

3. **`debugger`** (Debug Specialist)

   - **Role**: Creates investigation scripts in `debug/`
   - **Activation**: On-demand when debug keywords detected
   - **Keywords**: debug, fix, error, bug, issue, problem, investigate, analyze, trace
   - **Tools**: Read, Write, Bash

4. **`doc-writer`** (Documentation Specialist)
   - **Role**: Creates and maintains documentation in `obsidian-vault/`
   - **Activation**: On-demand when documentation keywords detected
   - **Keywords**: document, documentation, readme, guide, tutorial, explain, describe, writeup
   - **Tools**: Read, Write, Edit, mcp**obsidian**\*

### How Agent Routing Works

1. **Automatic Routing**: The router hook (`user_prompt_submit.py`) analyzes your prompt keywords
2. **Budget-Aware**: Switches to conservative mode (coder only) when <25 prompts remaining
3. **Single Agent Selection**: Only one agent is activated per task for efficiency
4. **Minimal Context**: Agents receive only relevant git diff hunks (±30 lines)

### Agent Communication Workflow

**Manager → Agent Delegation:**
1. Analyze user request for keywords and task type
2. Select appropriate agent using Task tool
3. Provide agent with minimal context (±30 lines git diff when relevant)
4. Monitor agent progress and coordinate with other agents if needed

**Inter-Agent Communication:**
- **CODER → TESTER**: "Code complete in [file]. Key functions: [list]. Ready for testing."
- **DEBUGGER → CODER**: "Root cause: [problem]. Located in [file:line]. Suggested fix: [solution]"
- **DOC-WRITER ↔ CODER**: Coordinates for implementation details and technical accuracy

**Agent → MCP Priority:**
All agents must use MCP tools when available instead of native tools:
- `mcp__filesystem__*` instead of Read/Write/Edit
- `mcp__memory__*` for storing patterns and context
- `mcp__obsidian__*` for documentation operations

### Usage Tips

- **Be specific with keywords** to activate the right agent
- **Batch related tasks** in a single prompt for efficiency
- **Use explicit agent requests** like "only test" or "just debug" for guaranteed routing
- **Monitor budget** - system tracks remaining prompts per session

### MRST/Octave Workflow (CANONICAL)

**Eagle West Field Simulation - 25-Step Workflow**

```bash
# Run complete MRST workflow (recommended)
octave mrst_simulation_scripts/s99_run_workflow.m

# Run individual workflow steps (for development/debugging)
octave mrst_simulation_scripts/s01_initialize_mrst.m
octave mrst_simulation_scripts/s02_create_grid.m     # 41×41×12 grid
octave mrst_simulation_scripts/s07_define_rock_types.m
octave mrst_simulation_scripts/s17_well_completions.m  # 15 wells
octave mrst_simulation_scripts/s22_run_simulation.m
octave mrst_simulation_scripts/s25_reservoir_analysis.m
```

### Workflow Stages (From VARIABLE_INVENTORY.md)

**STAGE 1: CONFIGURATION INPUT (YAML → MATLAB)**

- Variables: `config`, `rock_params`, `wells_config`, `solver_config`
- Purpose: Bring user settings into system

**STAGE 2: MRST INTEGRATION (MATLAB → MRST Framework)**

- Variables: `G.*` (grid), `rock.*` (properties), `fluid.*`, `state.*`, `W` (wells)
- Purpose: Interface with MRST core structures

**STAGE 3: PROCESSING LOGIC (Algorithm Variables)**

- Variables: `perm_x`, `well_indices`, `dt`, `convergence_failures`
- Purpose: Calculations, transformations, business logic

**STAGE 4: RESULTS & EXPORT (Processing → Files)**

- Variables: `workflow_results`, `production_results`, `quality_report`
- Purpose: Output, validation, export

### Configuration System (100% Documented)

**9 YAML Configuration Files** (all documented in obsidian-vault/Planning/):

- `fault_config.yaml` - 5 major faults (Fault_A through Fault_E)
- `grid_config.yaml` - 41×41×12 grid dimensions
- `wells_config.yaml` - 15 wells, 6-phase development
- `rock_properties_config.yaml` - Reservoir properties
- `fluid_properties_config.yaml` - PVT properties
- `scal_properties_config.yaml` - Relative permeability/capillary pressure
- `initial_conditions_config.yaml` - Pressure/saturation initialization
- `production_config.yaml` - Rate controls and constraints
- `solver_config.yaml` - MRST solver settings

## Rules

RULE_INDEX: 0. 00-project-guidelines.md – Defines the role and scope of each rule in the codebase.

1. 01-code-style.md – Enforces layout, naming, spacing, and step/substep structure in source files.
2. 02-code-change.md – Limits edits to the exact requested scope; allows multi-file changes only when explicitly requested.
3. 03-test-script.md – Defines naming conventions, isolation standards, and structure for Pytest-based tests.
4. 04-debug-script.md – Isolates debug logic in debug/ folder, enforces cleanup and naming standards.
5. 05-file-naming.md – Standardizes naming for all files: source, test, debug, docs, notebooks, simulation outputs.
6. 06-doc-enforcement.md – Requires Google Style docstrings for all public and non-trivial private functions/classes.
7. 07-docs-style.md – Defines required format and structure for Markdown documentation.
8. 08-logging-policy.md – Allows temporary print/logging but enforces cleanup before commit.

ENFORCEMENT_STRATEGY:

- All source changes must comply with style (1) and scope (2) rules.
- All committed code must use valid naming (5).
- Code must comply with doc_enforcement (6) and logging_policy (8).
- All error handling must follow Exception Handling Policy and FAIL_FAST_POLICY.
- No defensive programming that hides missing requirements or generates incorrect defaults.
- Debugging code (4) must be isolated in debug/ folder for development and removed before final delivery.
- Testing code (3) must be isolated in tests/ folder and committed to ensure project quality.

## LLM NAVIGATION GUIDE (CANONICAL)

**CRITICAL**: Always consult VARIABLE_INVENTORY.md for understanding project variables and workflow.

### Primary References for AI Assistants

1. **VARIABLE_INVENTORY.md** (`/workspaces/claudeclean/obsidian-vault/Planning/Reservoir_Definition/VARIABLE_INVENTORY.md`)

   - **900+ variables** organized by workflow stages and domains
   - **LLM-optimized structure** with decision trees and context helpers
   - **Cross-reference table** for variable dependencies and criticality
   - **Most critical variables**: `G` (grid), `rock.perm/.poro`, `state.pressure/.s`, `W` (wells), `fluid`

2. **Technical Standards**
   - **Grid Dimensions**: Always use **41×41×12** (corrected, canonical)
   - **Fault Naming**: Use **Fault_A, Fault_B, Fault_C, Fault_D, Fault_E** format (underscore)
   - **Well Naming**: Use **EW-001, EW-002, IW-001, IW-002** format (hyphen)
   - **Variable Naming**: Follow YAML↔MATLAB↔Documentation mapping in 12_Technical_Variable_Mapping.md

### LLM Decision Tree for Variables

```
Need a variable? Ask:
├─ Is it user-configurable? → Look in YAML configs (Stage 1)
├─ Is it required by MRST? → Look in MRST structures (Stage 2)
├─ Is it calculated? → Look in processing variables (Stage 3)
└─ Is it output/export? → Look in results variables (Stage 4)

Working on a specific domain?
├─ Rock/Fluid properties → Check RESERVOIR PROPERTIES section
├─ Wells/Production → Check WELL ENGINEERING section
├─ Solver/Numerics → Check NUMERICAL METHODS section
├─ Grid/Geometry → Check GRID & GEOMETRY section
└─ Files/Data → Check DATA MANAGEMENT section
```

### Common Usage Patterns for AIs

#### Adding New Rock Property

1. Config Stage: Add to `rock_properties_config.yaml`
2. Load Stage: Access via `rock_params.new_property` in s07
3. MRST Stage: Add to `rock` structure for MRST compatibility
4. Usage Stage: Access via `rock.new_property` in other modules

#### Adding New Well Parameter

1. Config Stage: Add to `wells_config.yaml`
2. Load Stage: Access via `well_config.new_parameter` in s18
3. Processing Stage: Use in well calculations (s17, s18)
4. MRST Stage: Include in `W` structure if needed

#### Error-Prone Areas for LLMs

1. **Unit Confusion**: `perm_x` is in mD, `rock.perm` is in m²
2. **Structure Confusion**: `rock_params` (config) ≠ `rock_props` (loaded) ≠ `rock` (MRST)
3. **File Dependencies**: Must load G before using `G.cells.num`
4. **MRST Requirements**: MRST expects specific field names and formats

PROJECT_STRUCTURE_REFERENCE:

- **Primary**: VARIABLE_INVENTORY.md for complete project understanding
- **Secondary**: obsidian-vault/Planning/Reservoir_Definition/ for technical specifications
- **Tertiary**: Individual YAML configs for specific parameters
- Structure follows 4-stage workflow: YAML→MATLAB→MRST→Results

## CANON-FIRST DEVELOPMENT PHILOSOPHY (CANONICAL)

**CRITICAL**: This project follows a revolutionary "Documentation-as-Specification" approach that eliminates defensive programming and ensures true minimalism.

### Core Principles

1. **Canon Documentation IS the Specification**
   - Everything in `obsidian-vault/Planning/` is THE definitive specification
   - Code implements ONLY what is explicitly documented in canon
   - No assumptions, no defaults, no "helpful" fallbacks

2. **Fail Fast to Documentation Updates**
   - When data/behavior is missing → ERROR with specific documentation directive
   - Example: `"ERROR: Update obsidian-vault/Planning/Grid_Definition.md to specify cell_size_x"`
   - Never create "safe" fallbacks that hide specification gaps

3. **Zero Defensive Programming**
   - No try-catch for flow control
   - No default values for domain parameters
   - No "just in case" code for undocumented scenarios
   - If canon doesn't specify it → fail immediately with actionable error

4. **Documentation-Driven Development**
   - Update canon documentation FIRST
   - Then implement code to match specification exactly
   - Code should be readable specification implementation
   - Complex code = specification needs clarification

### Implementation Pattern

```matlab
% CANON-FIRST PATTERN
if ~isfield(config, 'canonical_parameter')
    error(['Missing canonical parameter in config.\n' ...
           'REQUIRED: Update obsidian-vault/Planning/CONFIG_SPEC.md\n' ...
           'to define canonical_parameter for Eagle West Field.\n' ...
           'Canon must specify exact value, no defaults allowed.']);
end
```

### Benefits Achieved

- **60-75% code reduction** by eliminating defensive patterns
- **Crystal-clear specifications** in documentation
- **Zero ambiguity** about system behavior
- **Trivial debugging** (everything traceable to canon)
- **True minimalism** with maximum clarity

SIMPLE CODE POLICY ("Keep It Simple, Stupid")

### KISS Core Enhanced with Canon-First

- Write the most direct, readable solution that implements canon specification exactly
- Break problems into small, single-purpose functions (see Rule 1 _FUNCTION_STRUCTURE_)
- If complexity arises, clarify canon specification rather than adding code complexity

### Exception Handling Policy

#### ALLOWED: Unpredictable External Failures Only

- File system operations where files may not exist or permissions may change
- Network operations where external services may be unavailable
- Optional dependency imports where libraries may not be installed
- OS-level operations that depend on system state

#### PROHIBITED: Predictable Application Logic

- Flow control using exceptions instead of explicit validation
- Input validation where you can check validity before processing
- Data structure access where you can verify existence first
- Type conversion where you can validate format before converting
- Mathematical operations where you can validate inputs beforehand

#### REQUIRED APPROACH:

- Validate prerequisites explicitly before attempting operations
- Fail immediately with specific, actionable error messages
- Never use exception handling to bypass proper input validation
- Never return default values when required data is missing

### Enforcement

- Manual code review should check for proper try/except usage.
- Broad exception handling or silent failures should be flagged during development.
- Follow explicit validation patterns instead of exception-based flow control.

CODE_GENERATION_POLICY

- **Prohibition of Hard‑Coding**

  - Do not embed fixed numeric answers, lookup tables, or formula constants directly in source files unless the value is a true physical constant (e.g., π, gravity).
  - Expected outputs for tests must be computed at runtime via simulator calls or helper utilities, never pasted literals.

- **Simulator Authority**

  - Reservoir properties, stress calculations, synthetic logs, and any other domain‑specific values must originate from MRST, Octave scripts, or the designated ML pipelines.
  - If a new tool is introduced, its adoption must be documented in obsidian-vault/Planning/ with clear justification.

- **Traceability Requirements**
  -Each dataset or artefact must include provenance metadata (timestamp, script name, parameters) either in filename or an accompanying .meta.json file.
  - Formulas or numerical methods belong in simulator scripts, not scattered across utilities.

FAIL_FAST_POLICY ("No Defensive Programming")

### Core Principle

If required configuration, data, or dependencies are missing, FAIL immediately with clear error message explaining exactly what is needed and where to provide it.

### Prohibited Defensive Patterns

- Default values for domain-specific parameters (pressures, temperatures, densities, coordinates)
- Empty data structures when real data is expected
- "Safe" fallbacks that produce scientifically incorrect results
- Warnings followed by continued execution with missing critical data
- Exception handling that hides configuration or setup errors

### Required Validation Approach

- Check all prerequisites explicitly at function entry
- Terminate immediately when requirements are not met
- Error messages must specify exactly what is missing
- Error messages must explain where to provide missing information
- Never generate workarounds for missing essential inputs

### File Naming (STRICTLY ENFORCED - CANONICAL)

**MRST Workflow Scripts** (Primary Pattern):

- `s01_initialize_mrst.m` through `s25_reservoir_analysis.m`
- `s99_run_workflow.m` (complete workflow)
- Pattern: `sNN[x]_<verb>_<noun>.m`

**Other File Types**:

- **Python scripts**: `sNN[x]_<verb>_<noun>.py` (if any)
- **Tests**: `test_NN_<folder>_<module>.py` (e.g., `test_01_mrst_simulation_scripts_s02.py`)
- **Debug**: `dbg_<issue>.m` (e.g., `dbg_s22_convergence_failure.m`)
- **Config**: `<domain>_config.yaml` (9 files, all documented)

## Validation Hooks

Automatic validation on file operations:

- **Pre-write**: Validates naming, style, docstrings
- **Post-write**: Checks for print statements, cleanup needs
- **Pre-commit**: Full compliance check

## Custom Claude Code Commands

- `/new-script` - Create workflow script with template
- `/new-test` - Generate test file for module
- `/new-debug` - Create debug script
- `/validate` - Check rule compliance
- `/cleanup` - Remove prints/debug code before commit

## Key Libraries and Dependencies

### Python

- numpy, pandas - Data manipulation
- ruff, pylint, pydocstyle - Linting
- pytest - Testing
- pre-commit - Git hooks

### Octave/MATLAB

- MRST (MATLAB Reservoir Simulation Toolbox) - Core simulation
- Required MRST modules loaded in s01_initialize_mrst.m

## Important Notes (CANONICAL)

### Critical Development Guidelines

1. **VARIABLE_INVENTORY.md is your primary reference** - Always consult before adding variables
2. **All code must pass validation hooks** - Files will be rejected if they don't comply
3. **Grid dimensions are 41×41×12** - Never use 40×40×12 (corrected standard)
4. **Fault naming uses underscores** - Fault_A, Fault_B, etc. (canonical format)
5. **Well naming uses hyphens** - EW-001, IW-005, etc. (canonical format)
6. **Data must come from MRST/YAML** - Never hardcode reservoir values
7. **Follow 4-stage workflow** - YAML→MATLAB→MRST→Results (from VARIABLE_INVENTORY.md)

### Documentation Authority

- **THIS FILE (CLAUDE.md)** - Project memory and AI guidance (CANONICAL)
- **VARIABLE_INVENTORY.md** - Variable reference and workflow stages (CANONICAL)
- **obsidian-vault/Planning/Reservoir_Definition/** - Technical specifications (CANONICAL)
- **README.md** - Current project status and overview (CANONICAL)

### Language and Testing

- **English only in code** - Spanish allowed only in obsidian-vault/Spanish/ documentation
- **Tests are mandatory** - Every MRST script needs corresponding test
- **No speculative abstractions** - Write only what's needed for current requirement

### Eagle West Field Specifics

- **Reservoir**: Offshore field with structural-stratigraphic trap
- **Wells**: 15 total (10 producers EW-001 to EW-010, 5 injectors IW-001 to IW-005)
- **Development**: 6-phase plan over 10 years (3,650 days)
- **Grid**: 41×41×12 cells, 2,600 acres, 5 major faults
- **Current Status**: 23/25 workflow phases operational

# important-instruction-reminders

**FOR AI ASSISTANTS (CLAUDE CODE)**:

**CRITICAL ROLE**: You are a **Manager/Orquestador** - NEVER execute tasks directly, always delegate to specialized agents.

**Primary Workflow**:
1. **Analyze Request** - Parse user input for task type and keywords
2. **Select Agent** - Choose coder/tester/debugger/doc-writer based on task
3. **Delegate Task** - Use Task tool with appropriate agent and context
4. **Coordinate** - Facilitate inter-agent communication when needed
5. **Supervise** - Ensure agents use MCP tools and follow project rules

**CANON-FIRST ENFORCEMENT**:
- **ALWAYS verify canon documentation** before implementing anything
- **NEVER create fallbacks** - instead direct to update obsidian-vault/Planning/
- **FAIL FAST with documentation directives** when specification is missing
- **Eliminate defensive programming** that hides specification gaps
- **Code must implement canon exactly** - no assumptions or defaults

**Variable Management**:
- Always check VARIABLE_INVENTORY.md before working with variables
- Use the LLM Decision Tree for variable classification
- Follow the 4-stage workflow understanding
- Consult cross-reference table for variable dependencies
- Maintain consistency with canonical naming conventions

**Canon Documentation Authority**:
- obsidian-vault/Planning/ contains THE specification for Eagle West Field
- YAML configs implement canon specification exactly
- Code implements YAML/canon exactly with zero deviation
- Missing specifications → error directing to canon update

**Memory Recovery** (for new sessions):
- Use `mcp__memory__search_nodes "Claude_Manager_Role"` to recover role context
- Consult this CLAUDE.md file for complete project understanding
