# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**Eagle West Field MRST Reservoir Simulation Project** - A comprehensive reservoir simulation project using MRST (MATLAB Reservoir Simulation Toolbox) with complete documentation coverage and AI-assisted development.

**CANONICAL STATUS: This documentation reflects current project state as of 2025-08-24 with CONSOLIDATED WORKFLOW IMPLEMENTATION.**

### Key Achievements

- **✅ CONSOLIDATED DATA STRUCTURE OPERATIONAL** - 4-file streamlined architecture (60% complexity reduction)
- **✅ CORE WORKFLOW COMPLETE (S01-S13)** - All essential simulation phases operational with Octave compatibility
- **✅ FUNCTION HANDLE COMPATIBILITY RESOLVED** - All scripts save successfully without MATLAB/Octave conflicts
- **100% YAML-Documentation Coverage** - All 9 configuration files fully documented
- **900+ Variable Inventory** - LLM-optimized organization in VARIABLE_INVENTORY.md
- **Core MRST Workflow Operational** - 13/20 simulation scripts fully functional with consolidated structure
- **Streamlined Data Organization** - Migrated from 9-file legacy to 4-file consolidated structure
- **Enhanced Analytics & Diagnostics** - ML-ready features and solver diagnostics
- **Comprehensive Testing Framework** - 38+ test files covering all workflow phases
- **Eagle West Field Model** - Realistic offshore field with 9,660-cell PEBI grid, 15 wells
- **Multi-Agent Architecture** - 4 specialized agents with policy-aware coordination
- **Multi-Mode Policy System** - Context-aware validation (suggest/warn/strict)
- **6 Immutable Policies** - Canon-first, data authority, fail fast, exception handling, KISS, no over-engineering

### Project Characteristics

- **MRST-based reservoir simulation** for Eagle West offshore field
- **Multi-Mode Policy System** - Context-aware enforcement (suggest/warn/strict)
- **Policy-aware coding standards** with flexible enforcement based on development phase
- **Claude Code integration** for AI-assisted development
- **Dual language support** (Python & Octave/MRST)
- **Comprehensive documentation** with LLM optimization

## Architecture

📦 workspace/
├── 🤖 .claude/ # Claude Code configuration
│ ├── policies/ # 5 immutable principles (canon-first, data-authority, fail-fast, exception-handling, kiss-principle)
│ ├── agents/ # 4 specialized agent definitions with policy awareness
│ ├── commands/ # Custom slash commands
│ ├── hooks/ # Multi-mode validation hooks (suggest/warn/strict)
│ ├── rules/ # 8 coding standards (verifiable conventions)
│ ├── templates/ # Code generation templates
│ └── settings.json # Project settings
├── 🐍 src/ # Python source code
├── 📊 mrst_simulation_scripts/ # Octave/MRST scripts (25+ workflow steps)
│ ├── config/ # YAML configuration files (9 files, 100% documented)
│ ├── session/ # MRST session persistence (local only)
│ ├── s01_initialize_mrst.m → s25_reservoir_analysis.m
│ ├── s99_run_workflow.m # Complete workflow runner
│ └── utils/ # MRST utility functions  
├── 📖 docs/ # Documentation system
│ ├── Planning/Reservoir_Definition/ # Technical documentation (CANONICAL)
│ │ ├── VARIABLE_INVENTORY.md # 900+ variables with LLM optimization
│ └── Spanish/ # Spanish documentation
├── 🧪 tests/ # Test files (gitignored)
├── 🐛 debug/ # Debug scripts (gitignored)
├── 📊 data/ # Simulation data and results
└── 🧠 CLAUDE.md # Main project memory (THIS FILE - CANONICAL)

## Multi-Mode Policy System (IMMUTABLE)

**CRITICAL**: All code generation follows a 6-policy system with context-aware enforcement:

### 1. Canon-First Policy (Context-Aware)
**Documentation IS the Specification** - but flexible based on development phase:
- **Strict Mode** (Production): No hardcoding, immediate failure on missing config
- **Warn Mode** (Development): Helpful defaults with warnings  
- **Suggest Mode** (Prototype): Flexible interpretation for rapid iteration

@.claude/policies/canon-first.md

### 2. Data Authority Policy
**Authoritative Sources Only** - No hardcoded domain values:
- All domain data from simulators, config files, or documented computations
- Include provenance metadata (timestamp, script, parameters)
- No magic numbers or manual estimates

@.claude/policies/data-authority.md

### 3. Fail Fast Policy
**No Defensive Programming** - Immediate failure on missing requirements:
- Validate prerequisites explicitly before operations
- Clear error messages directing to specific documentation updates
- Context-aware: strict in production, helpful in development

@.claude/policies/fail-fast.md

### 4. Exception Handling Policy
**Explicit Validation Over Exception Handling**:
- Exceptions only for unpredictable external failures (file I/O, network, dependencies)
- Explicit validation for predictable application logic
- No exception-based flow control

@.claude/policies/exception-handling.md

### 5. KISS Principle Policy
**Simplicity and Minimalism**:
- Single responsibility functions (ideally <40 lines)
- No speculative abstractions unless explicitly requested
- Clarity over cleverness in all implementations

@.claude/policies/kiss-principle.md

### 6. No Over-Engineering Policy  
**Write Only What You Need**:
- Functions under 50 lines whenever possible
- No speculative code for imagined future needs
- Eliminate unnecessary complexity and abstractions
- Choose simplest solution that works

@.claude/policies/no-overengineering.md

## Validation Modes

### 🎯 Context-Aware Enforcement
- **suggest** - Prototyping: Recommendations and guidance
- **warn** - Development: Violations flagged but not blocking
- **strict** - Production: Full enforcement with blocking on errors

### 🔧 Override Mechanisms
- **File-level**: `# @policy-override: suggest`
- **Environment**: `CLAUDE_VALIDATION_MODE=strict`
- **Context-based**: Automatic detection from file paths and project structure

## Claude Code Agent System (CANONICAL)

**CRITICAL**: Claude Code acts as a **Manager/Orquestador** that delegates tasks to specialized agents rather than executing tasks directly.

### Manager Role

Claude Code (this AI) functions as:
- **Task Analyzer** - Determines which specialized agent should handle each request
- **Work Delegator** - Uses Task tool to assign work to appropriate agents  
- **Coordinator** - Facilitates communication between agents when needed
- **Progress Supervisor** - Ensures agents use MCP tools and follow project rules
- **Policy Enforcer** - Injects all 6 policies with context-aware mode into agent tasks

**Key Principle**: Claude Code NEVER executes tasks directly - always delegates to specialized agents with policy context.

The project uses an **optimized multi-agent architecture** for efficient code generation and task management:

### Available Agents

1. **`coder`** (Default Agent)
   - **Role**: Production code writer following 6-policy system with context-aware validation
   - **Policies**: All 6 policies with suggest/warn/strict mode awareness
   - **Activation**: Default for all code-related tasks
   - **Keywords**: create, implement, write, edit, add, build, develop, function, class, module
   - **Tools**: Read, Write, Edit, MultiEdit, Grep, Glob, Bash, mcp__filesystem__*

2. **`tester`** (Test Specialist)
   - **Role**: Creates comprehensive test suites with policy compliance validation across all modes
   - **Policies**: Tests policy compliance for suggest/warn/strict validation modes
   - **Activation**: On-demand when test keywords detected
   - **Keywords**: test, pytest, unittest, validation, verify, check, assert, coverage
   - **Tools**: Read, Write, Bash, mcp__filesystem__*

3. **`debugger`** (Debug Specialist)
   - **Role**: Policy-aware investigation with mode context analysis
   - **Policies**: Debug policy violations and mode mismatches
   - **Activation**: On-demand when debug keywords detected
   - **Keywords**: debug, fix, error, bug, issue, problem, investigate, analyze, trace
   - **Tools**: Read, Write, Bash, mcp__filesystem__*

4. **`doc-writer`** (Documentation Specialist)
   - **Role**: Policy-aware technical writing with multi-mode guidance documentation
   - **Policies**: Documents policy implementation and contextual application
   - **Activation**: On-demand when documentation keywords detected
   - **Keywords**: document, documentation, readme, guide, tutorial, explain, describe, writeup
   - **Tools**: Read, Write, Edit, mcp__filesystem__*, Grep, Glob

### How Agent Routing Works

1. **Automatic Routing**: The router hook (`user_prompt_submit.py`) analyzes your prompt keywords
2. **Budget-Aware**: Switches to conservative mode (coder only) when <25 prompts remaining
3. **Single Agent Selection**: Only one agent is activated per task for efficiency
4. **Minimal Context**: Agents receive only relevant git diff hunks (±30 lines)

### Agent Communication Workflow

**Manager → Agent Delegation:**
1. Analyze user request for keywords and task type
2. Select appropriate agent using Task tool
3. Provide agent with minimal context (±30 lines git diff when relevant) and policy context
4. Monitor agent progress and coordinate with other agents if needed
5. Ensure policy compliance through multi-mode validation

**Inter-Agent Communication:**
- **CODER → TESTER**: "Code complete in [file]. Key functions: [list]. Ready for testing."
- **DEBUGGER → CODER**: "Root cause: [problem]. Located in [file:line]. Suggested fix: [solution]"
- **DOC-WRITER ↔ CODER**: Coordinates for implementation details and technical accuracy

**Agent → MCP Priority:**
All agents must use MCP tools when available instead of native tools:
- `mcp__filesystem__*` instead of Read/Write/Edit
- `mcp__memory__*` for storing patterns and context

### Usage Tips

- **Be specific with keywords** to activate the right agent
- **Batch related tasks** in a single prompt for efficiency
- **Use explicit agent requests** like "only test" or "just debug" for guaranteed routing
- **Monitor budget** - system tracks remaining prompts per session

### MRST/Octave Workflow (CANONICAL)

**Eagle West Field Simulation - 25-Step Workflow** 
**CORRECTED SEQUENCE: s01→s02→s05→s03→s04→s06→s07→s08**

```bash
# Run complete MRST workflow (recommended)
octave mrst_simulation_scripts/s99_run_workflow.m

# Run individual workflow steps (corrected sequence)
octave mrst_simulation_scripts/s01_initialize_mrst.m
octave mrst_simulation_scripts/s02_define_fluids.m
octave mrst_simulation_scripts/s05_create_pebi_grid.m # PEBI grid construction FIRST
octave mrst_simulation_scripts/s03_structural_framework.m
octave mrst_simulation_scripts/s04_add_faults.m
octave mrst_simulation_scripts/s06_create_base_rock_structure.m
octave mrst_simulation_scripts/s07_add_layer_metadata.m
octave mrst_simulation_scripts/s08_apply_spatial_heterogeneity.m
# ... continuing through s25

# Enhanced diagnostics and analytics
octave mrst_simulation_scripts/s22_run_simulation_with_diagnostics.m
octave mrst_simulation_scripts/s24_advanced_analytics.m
```

### Simplified Data Organization (CANONICAL - 6-FILE STRUCTURE)

**✅ CANONICAL: 6-File Eagle West Field Model (80% complexity reduction)**

```
data/simulation_data/
├── grid.mat           # Complete geometry with faults and structure
├── rock.mat           # Final petroPhysical properties with heterogeneity  
├── fluid.mat          # Complete 3-phase fluid system with PVT
├── state.mat          # Initial pressure and saturation distribution
├── wells.mat          # 15-well system with completions and controls
└── schedule.mat       # Development plan and solver configuration
```

**Script Contributions to Each File:**
- **grid.mat**: s03 (PEBI base) → s04 (structure) → s05 (faults) = Complete geometry
- **rock.mat**: s06 (base) → s07 (layers) → s08 (heterogeneity) = Final rock properties
- **fluid.mat**: s02 (basic) → s09 (relperm) → s10 (capillary) → s11 (PVT) = Complete fluid
- **state.mat**: s12 (pressure) → s13 (saturations) → s14 (aquifer) = Initial conditions  
- **wells.mat**: s15 (placement) → s16 (completions) = 15-well system
- **schedule.mat**: s17 (controls) → s18 (schedule) → s19 (targets) = Development plan

**Key Advantages:**
- **Single Location**: All data in `/workspace/data/simulation_data/`
- **MRST Ready**: Standard structures for `simulateScheduleAD(state, G, rock, fluid, schedule, 'Wells', W)`
- **Complete Model**: Eagle West Field with 20,332 cells, 5 faults, 15 wells
- **Maximum Simplicity**: Each script contributes to specific canonical files

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

**9 YAML Configuration Files** (all documented in docs/Planning/):

- `fault_config.yaml` - 5 major faults (Fault_A through Fault_E)
- `grid_config.yaml` - 41×41×12 grid dimensions
- `wells_config.yaml` - 15 wells, 6-phase development
- `rock_properties_config.yaml` - Reservoir properties
- `fluid_properties_config.yaml` - PVT properties
- `scal_properties_config.yaml` - Relative permeability/capillary pressure
- `initial_conditions_config.yaml` - Pressure/saturation initialization
- `production_config.yaml` - Rate controls and constraints
- `solver_config.yaml` - MRST solver settings

## Rules and Policies (CANONICAL)

### 8 Coding Rules (Verifiable Standards)

**RULE_INDEX**: 0. 00-project-guidelines.md – Defines the role and scope of each rule

1. **01-code-style.md** – Layout, naming, spacing, and step/substep structure
2. **02-code-change.md** – Scope discipline for focused changes
3. **03-test-script.md** – Test naming conventions and structure
4. **04-debug-script.md** – Debug practices and cleanup standards
5. **05-file-naming.md** – File naming patterns across project
6. **06-doc-enforcement.md** – Docstring requirements and standards
7. **07-docs-style.md** – Markdown documentation format
8. **08-logging-policy.md** – Logging and output control

### 5 Immutable Policies (Fundamental Principles)

Located in `.claude/policies/` with context-aware enforcement:

1. **canon-first.md** – Context-aware specification enforcement
2. **data-authority.md** – Authoritative data sources and anti-hardcoding
3. **fail-fast.md** – Immediate failure on missing requirements
4. **exception-handling.md** – Explicit validation over exception handling
5. **kiss-principle.md** – Simplicity and minimalism in design

### Policy Enforcement Strategy

- **Context-Aware Validation**: suggest/warn/strict modes based on development phase
- **Progressive Enforcement**: prototype → development → production
- **Override Mechanisms**: File-level (`# @policy-override:`) and environment (`CLAUDE_VALIDATION_MODE`)
- **Multi-Mode Support**: Flexible enforcement balancing principles with pragmatism

## LLM NAVIGATION GUIDE (CANONICAL)

**CRITICAL**: Always consult VARIABLE_INVENTORY.md for understanding project variables and workflow.

### Primary References for AI Assistants

1. **VARIABLE_INVENTORY.md** (`/workspaces/reservoir-simulation/docs/Planning/Reservoir_Definition/VARIABLE_INVENTORY.md`)

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
- **Secondary**: docs/Planning/Reservoir_Definition/ for technical specifications
- **Tertiary**: Individual YAML configs for specific parameters
- Structure follows 4-stage workflow: YAML→MATLAB→MRST→Results

## Development Policies (OBSOLETE - MIGRATED)

**DEPRECATED**: The following sections have been migrated to the new 5-policy system in `.claude/policies/`.

For current policy information, see:
- `.claude/policies/canon-first.md` - Context-aware specification enforcement
- `.claude/policies/data-authority.md` - Anti-hardcoding and authoritative data sources  
- `.claude/policies/fail-fast.md` - No defensive programming
- `.claude/policies/exception-handling.md` - Explicit validation patterns
- `.claude/policies/kiss-principle.md` - Simplicity and minimalism

**Multi-Mode Policy System**: All policies now support suggest/warn/strict validation modes with context-aware enforcement based on development phase.

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

## Validation Hooks (UPDATED)

**Multi-Mode Policy Validation System**:

- **user_prompt_submit.py**: Natural language router + policy injection
- **post_tool_use.py**: Context-aware validation (suggest/warn/strict modes)
- **post_response.py**: Auto-apply diffs + CI integration
- **subagent_stop.py**: Agent coordination and result consolidation

## Custom Claude Code Commands

- `/new-script` - Create workflow script with template
- `/new-test` - Generate test file for module
- `/new-debug` - Create debug script
- `/validate` - Check policy compliance (needs update for multi-mode)
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
- **docs/Planning/Reservoir_Definition/** - Technical specifications (CANONICAL)
- **README.md** - Current project status and overview (CANONICAL)

### Language and Testing

- **English only in code** - Spanish allowed only in docs/Spanish/ documentation
- **Tests are mandatory** - Every MRST script needs corresponding test
- **No speculative abstractions** - Write only what's needed for current requirement

### Eagle West Field Specifics

- **Reservoir**: Offshore field with structural-stratigraphic trap
- **Wells**: 15 total (10 producers EW-001 to EW-010, 5 injectors IW-001 to IW-005)
- **Development**: 6-phase plan over 10 years (3,650 days)
- **Grid**: 41×41×12 cells, 2,600 acres, 5 major faults
- **Current Status**: 25/25 workflow phases operational

# important-instruction-reminders

**FOR AI ASSISTANTS (CLAUDE CODE)**:

**CRITICAL ROLE**: You are a **Manager/Orquestador** - NEVER execute tasks directly, always delegate to specialized agents.

**Primary Workflow**:
1. **Analyze Request** - Parse user input for task type and keywords
2. **Select Agent** - Choose coder/tester/debugger/doc-writer based on task
3. **Delegate Task** - Use Task tool with appropriate agent and context
4. **Coordinate** - Facilitate inter-agent communication when needed
5. **Supervise** - Ensure agents use MCP tools and follow project rules

**MULTI-MODE POLICY ENFORCEMENT**:
- **ALWAYS apply all 6 policies** with context-aware mode selection
- **VALIDATE with appropriate strictness** based on development phase
- **USE override mechanisms** when needed (file-level or environment)
- **BALANCE principles with pragmatism** for development efficiency
- **ESCALATE mode progressively** from prototype → development → production

**Variable Management**:
- Always check VARIABLE_INVENTORY.md before working with variables
- Use the LLM Decision Tree for variable classification
- Follow the 4-stage workflow understanding
- Consult cross-reference table for variable dependencies
- Maintain consistency with canonical naming conventions

**Policy-Aware Documentation Authority**:
- docs/Planning/ contains authoritative specifications for Eagle West Field
- YAML configs implement specifications with policy compliance
- Code implements specifications following all 6 policies with context-aware validation
- Missing specifications → appropriate response based on validation mode (suggest/warn/strict)

**Data Organization (CRITICAL)**:
- **SINGLE DATA LOCATION**: `/workspace/data/simulation_data/` ONLY
- **6 CANONICAL FILES**: grid.mat, rock.mat, fluid.mat, state.mat, wells.mat, schedule.mat
- **NEVER use legacy paths**: `/workspace/data/mrst/` or `/workspace/data/by_type/` are OBSOLETE
- **Script-to-File Mapping**: Each script contributes to specific canonical files
- **MRST Ready**: All files contain standard MRST structures

**Memory Recovery** (for new sessions):
- Use `mcp__memory__search_nodes "Claude_Manager_Role"` to recover role context
- Consult this CLAUDE.md file for complete project understanding
