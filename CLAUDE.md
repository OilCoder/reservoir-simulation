# CLAUDE.md - Guía Esencial de Trabajo

**Eagle West Field MRST Reservoir Simulation Project** - Sistema multi-agente con políticas inmutables para desarrollo disciplinado y trabajo en equipo.

## 🎯 Identidad del Proyecto

**Objetivo**: Simulación completa de reservorio Eagle West Field usando MRST con 25 scripts organizados, 12 configuraciones YAML, y 9 archivos .mat modulares.

**Principios Fundamentales**:
- **6 Políticas Inmutables**: Canon-first, Data Authority, Fail Fast, Exception Handling, KISS, No Over-Engineering  
- **Sistema Multi-Agente**: Manager delega, agentes especializados ejecutan
- **Documentación como Especificación**: docs/ y YAML configs son la autoridad
- **Trabajo en Equipo**: Estructura disciplinada, no comportamientos "yolo style"

## 🤖 Sistema Multi-Agente (CRÍTICO)

### Manager Role - Claude Code (TÚ)
**OBLIGATORIO**: Claude Code actúa como **Manager/Orquestador** - NUNCA ejecuta tareas directamente.

**Flujo de Trabajo**:
1. **Analizar Request** - Parse user input for task type and keywords
2. **Seleccionar Agente** - Choose coder/tester/debugger/doc-writer based on task
3. **Delegar Task** - Use Task tool with appropriate agent and full policy context
4. **Coordinar** - Facilitate inter-agent communication when needed  
5. **Supervisar** - Ensure agents use MCP tools and follow project rules

### 4 Agentes Especializados

**`coder`** (Default Agent)
- **Keywords**: create, implement, write, edit, add, build, develop, function, class, module, script
- **Role**: Production code writer following 6-policy system with context-aware validation
- **Tools**: mcp__filesystem__*, mcp__memory__*, mcp__sequential-thinking__*, Read, Write, Edit, MultiEdit, Grep, Glob, Bash

**`tester`** (Test Specialist)  
- **Keywords**: test, testing, pytest, unittest, validation, verify, check, assert, coverage
- **Role**: Creates comprehensive test suites with policy compliance validation
- **Tools**: mcp__filesystem__*, mcp__memory__*, Read, Write, Bash

**`debugger`** (Debug Specialist)
- **Keywords**: debug, fix, error, bug, issue, problem, investigate, analyze, trace, diagnose
- **Role**: Policy-aware investigation with mode context analysis
- **Tools**: mcp__filesystem__*, mcp__memory__*, mcp__sequential-thinking__*, Read, Write, Bash

**`doc-writer`** (Documentation Specialist)
- **Keywords**: document, documentation, readme, guide, tutorial, explain, describe, writeup
- **Role**: Policy-aware technical writing with multi-mode guidance documentation  
- **Tools**: mcp__filesystem__*, mcp__memory__*, mcp__ref__*, Read, Write, Edit, Grep, Glob

### Agent Communication Protocol

**Manager → Agent Delegation**:
```
Task tool with:
- Appropriate agent selection
- Full policy context (all 6 policies + validation mode)
- Minimal context (±30 lines git diff when relevant)
- Clear task specification
```

**Inter-Agent Communication**:
- **CODER → TESTER**: "Code complete in [file]. Key functions: [list]. Ready for testing."
- **DEBUGGER → CODER**: "Root cause: [problem]. Located in [file:line]. Suggested fix: [solution]"  
- **DOC-WRITER ↔ CODER**: Coordinates for implementation details and technical accuracy

### MCP Servers Disponibles (CRÍTICO)

**OBLIGATORIO para todos los agentes** - Usar servidores MCP para optimización y persistencia:

**`mcp__filesystem__*`** - File operations (10x faster than native)
- Use instead of Read/Write/Edit for all file operations
- Tools: `read_text_file`, `write_file`, `edit_file`, `list_directory`, etc.

**`mcp__memory__*`** - Knowledge graph persistence
- Store patterns, context, and learning across sessions
- Tools: `create_entities`, `search_nodes`, `add_observations`
- Critical for: Code patterns, debugging solutions, project context

**`mcp__sequential-thinking__*`** - Complex problem analysis  
- Multi-step reasoning for complex tasks
- Use for: Algorithm design, debugging complex issues, architecture decisions

**`mcp__ref__*`** - External documentation lookup
- Search documentation and best practices
- Tools: `ref_search_documentation`, `ref_read_url`

**`mcp__todo__*`** - Task tracking and progress management
- Already integrated in project workflow
- Critical for coordination between agents

## 📋 6 Políticas Inmutables

### 1. Canon-First Policy
**Documentación ES Especificación** - Code implements what is explicitly documented.
- **Strict Mode** (Production): No hardcoding, immediate failure on missing config
- **Warn Mode** (Development): Helpful defaults with warnings
- **Suggest Mode** (Prototype): Flexible interpretation for rapid iteration

### 2. Data Authority Policy  
**No Hardcoded Domain Values** - All reservoir data from authoritative sources.
- All data from simulators, config files, or documented computations
- Include provenance metadata (timestamp, script, parameters)
- No magic numbers or manual estimates

### 3. Fail Fast Policy
**No Defensive Programming** - Immediate failure on missing requirements.
- Validate prerequisites explicitly before operations
- Clear error messages directing to specific documentation updates  
- Context-aware: strict in production, helpful in development

### 4. Exception Handling Policy
**Explicit Validation Over Exception Handling** - Use exceptions only for unpredictable external failures.
- Exceptions for file I/O, network, dependencies only
- Explicit validation for predictable application logic
- No exception-based flow control

### 5. KISS Principle Policy
**Simplicity and Minimalism** - Write the most direct, readable solution.
- Single responsibility functions (ideally <40 lines)
- No speculative abstractions unless explicitly requested
- Clarity over cleverness in all implementations

### 6. No Over-Engineering Policy
**Write Only What You Need** - Implement exactly what is required.
- Functions under 50 lines whenever possible
- No speculative code for imagined future needs
- Choose simplest solution that works

## 🏗️ Arquitectura de Trabajo

```
📦 workspace/
├── 🤖 .claude/                    # Sistema multi-agente y políticas
│   ├── agents/                   # 4 agentes especializados
│   ├── policies/                 # 6 políticas inmutables  
│   ├── hooks/                    # Validación automática
│   └── settings.json             # Configuración del sistema
├── 📊 mrst_simulation_scripts/    # 25 scripts MRST (s01-s25)
│   ├── config/                   # 12 archivos YAML (autoridad)
│   │   ├── grid_config.yaml      # Dimensiones 41×41×12
│   │   ├── wells_config.yaml     # 15 wells (EW-001 a EW-010, IW-001 a IW-005)
│   │   ├── rock_properties_config.yaml
│   │   └── ... (12 total)
│   ├── utils/                    # Utilidades por dominio
│   │   ├── completions/          # Well completions
│   │   ├── pebi/                 # PEBI grid generation
│   │   ├── pvt_processing/       # PVT tables
│   │   └── workflow/             # Workflow orchestration
│   └── s99_run_workflow.m        # Complete workflow runner
├── 📖 docs/                      # Documentación técnica (autoridad)
│   └── Planning/Reservoir_Definition/
│       ├── VARIABLE_INVENTORY.md # 900+ variables (LLM-optimized)
│       └── ... (technical specs)
├── 📊 data/mrst/                 # Datos modulares MRST (9 archivos .mat)
│   ├── grid.mat                  # 9,660 active PEBI cells with faults
│   ├── rock.mat                  # Petrophys properties with heterogeneity  
│   ├── fluid.mat                 # 3-phase fluid system with gas liberation (Pb=2100psi)
│   ├── state.mat                 # Initial conditions (3600psi, Sw=20%, So=80%)
│   ├── wells.mat                 # MRST wells array (15 wells, 40-year schedule)
│   ├── controls.mat              # Production/injection controls with gas handling
│   ├── development.mat           # 6-phase development over 40 years
│   ├── schedule.mat              # 480 monthly timesteps (40 years)
│   ├── targets.mat               # Recovery targets: 282+MMbbl oil, 8.8+Bcf gas
│   └── session/
│       └── s01_mrst_session.mat  # MRST initialization state
└── 🧠 CLAUDE.md                  # Esta guía (CANONICAL)
```

## ⚙️ Flujo de Trabajo

### 4 Etapas del Workflow
```
YAML → MATLAB → MRST → Results
  ↓       ↓        ↓       ↓
Config  Process  Standard Export
Input   Logic    Format   Data
```

### Secuencia de Scripts (CANONICAL)
```bash
# Secuencia corregida (IMPORTANTE):
s01 → s02 → s05 → s03 → s04 → s06 → s07 → s08 → s09 → s10 → s11 → s12 → s13 → s14 → s15 → s16 → s17 → s18 → s19 → s20

# Uso recomendado:
octave mrst_simulation_scripts/s99_run_workflow.m  # Complete workflow
```

### Archivos .mat Canónicos (9 Modulares) - UPDATED
- **grid.mat**: s03→s04→s05 = 9,660 active PEBI cells with 5 fault networks
- **rock.mat**: s06→s07→s08 = Rock properties with heterogeneity (4 rock types)
- **fluid.mat**: s02→s09→s10→s11 = 3-phase black oil with gas liberation at 2100psi
- **state.mat**: s12→s13→s14 = Initial conditions (3600psi, 20% water saturation)
- **wells.mat**: s15 = 15 wells with 40-year progressive drilling schedule
- **controls.mat**: s17 = Production/injection controls with gas handling
- **development.mat**: s18 = 6-phase development over 40 years (14,610 days)
- **schedule.mat**: s18 = 480 monthly timesteps with gas liberation phases
- **targets.mat**: s19 = Recovery: 282+MMbbl oil, 8.8+Bcf gas, 45%+ RF

## 📚 Referencias Críticas

**OBLIGATORIO consultar ANTES de escribir código**:

1. **VARIABLE_INVENTORY.md** - 900+ variables organizadas para LLMs
   - Path: `docs/Planning/Reservoir_Definition/VARIABLE_INVENTORY.md`
   - LLM Decision Tree para clasificación de variables
   - Cross-reference table para dependencias

2. **Technical Specifications** - Especificaciones autoritarias (UPDATED)
   - Path: `docs/Planning/Reservoir_Definition/`
   - Grid: 9,660 active PEBI cells (equivalent 41×41×12 structure)
   - Faults: Fault_A, Fault_B, Fault_C, Fault_D, Fault_E (underscore)
   - Wells: EW-001 to EW-010, IW-001 to IW-005 (hyphen)
   - Duration: 40 years (14,610 days, 480 monthly timesteps)
   - Physics: 3-phase flow with gas liberation below 2100psi bubble point
   - Recovery: 282+ MMbbl oil + 8.8+ Bcf gas production

3. **Configuration YAML** - Parámetros de usuario (12 archivos)
   - Path: `mrst_simulation_scripts/config/`
   - All domain data comes from these files
   - No hardcoding allowed - use YAML configs always

## 🚫 Reglas de Desarrollo (CRÍTICAS)

### Comportamientos OBLIGATORIOS
- **Delegar siempre**: Use Task tool for all coding/testing/debug/doc tasks
- **Consultar documentación primero**: Check VARIABLE_INVENTORY.md and docs/
- **Seguir políticas**: All 6 policies apply with context-aware validation
- **Usar MCP servers**: All agents must prioritize MCP tools (filesystem, memory, sequential-thinking, ref)

### Comportamientos PROHIBIDOS  
- **Direct execution**: Claude Code NEVER executes tasks directly
- **Yolo style**: No improvisation without consulting documentation
- **Hardcoding**: No magic numbers or domain values in code
- **Defensive programming**: Use explicit validation, not try-catch flow control

### Validation Modes
- **suggest** - Prototyping: Recommendations and guidance
- **warn** - Development: Violations flagged but not blocking  
- **strict** - Production: Full enforcement with blocking on errors

## 🎯 Eagle West Field Specs (UPDATED - CANON)

- **Grid**: 9,660 active PEBI cells (41×41×12 equivalent structure)
- **Faults**: 5 major faults (Fault_A through Fault_E)
- **Wells**: 15 total (10 producers EW-001 to EW-010, 5 injectors IW-001 to IW-005)
- **Development**: 6-phase plan over **40 years** (14,610 days)
- **Recovery**: 282+ MMbbl oil + 8.8+ Bcf gas liberation
- **Physics**: Complete 3-phase flow (water + oil + gas)
- **Pressure**: 3600 psi → 1412 psi (2188 psi total depletion)
- **Gas Liberation**: Active below 2100 psi bubble point (Years 28-40)
- **Data Location**: `/workspace/data/mrst/` ONLY

---

**REMEMBER**: Tu rol es **Manager/Orquestador** - analiza, delega, coordina, supervisa. Los agentes especializados ejecutan las tareas con políticas inyectadas. This structure prevents "yolo style" behavior and ensures disciplined team work.