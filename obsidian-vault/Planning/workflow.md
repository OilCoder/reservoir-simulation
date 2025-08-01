# Flujo de Trabajo Circular

## 🔄 Ciclo de Desarrollo

```
USER PROMPT
     ↓
┌─────────────┐
│    PLAN     │ ←─────────┐
│ (Analyze &  │           │
│  Design)    │           │
└─────────────┘           │
     ↓                    │
┌─────────────┐           │
│    CODE     │           │
│ (Generate & │           │
│  Implement) │           │
└─────────────┘           │
     ↓                    │
┌─────────────┐           │
│    TEST     │           │
│ (Execute &  │           │
│  Validate)  │           │
└─────────────┘           │
     ↓                    │
┌─────────────┐           │
│   DEBUG     │           │
│ (Find &     │           │
│  Analyze)   │           │
└─────────────┘           │
     ↓                    │
┌─────────────┐           │
│   REFINE    │ ──────────┘
│ (Fix &      │ ← Loop hasta que
│  Improve)   │   funcione
└─────────────┘
     ↓
┌─────────────┐
│   DONE      │
│ (Task       │
│  Solved)    │
└─────────────┘
```

## 📋 Rules por Fase

### Transversales (Todo el ciclo)
- **Rule 1**: Naming, spacing, English comments
- **Rule 5**: File naming conventions
- **Rule 0**: KISS principle, DATA_GENERATION_POLICY

### PLAN Phase
- **Rule 0**: KISS principle, single-purpose functions <40 lines

### CODE Phase (Create/Edit)
- **Rule 1**: Layout, step/substep structure
- **Rule 2**: Edit scope discipline, structural integrity
- **Rule 6**: Google Style docstrings
- **Rule 8**: Temporary prints OK, cleanup before commit

### TEST Phase
- **Rule 3**: Test naming, isolation, structure
- **Rule 5**: Test file patterns (`test_NN_folder_module`)

### DEBUG Phase
- **Rule 4**: Debug isolation in debug/, cleanup, naming
- **Rule 5**: Debug file patterns (`dbg_slug`)
- **Rule 8**: Temporary logging allowed

### REFINE Phase
- **Rule 2**: Edit scope discipline
- **Rule 8**: Cleanup prints/logs before finalizing

## 🛠️ Herramientas por Fase

### PLAN Phase
- **`Task`** → Analizar requirements complejos
- **`Read`** → Examinar codebase, patrones
- **`Glob/Grep`** → Buscar implementaciones similares
- **`TodoWrite`** → Planificar subtareas

### CODE Phase
- **`Write`** → Crear nuevos archivos/componentes
- **`Edit/MultiEdit`** → Modificar código existente
- **Rules application** → Seguir `/workspace/.claude/rules/`

### TEST Phase
- **`Write`** → Crear tests (unit, integration, e2e)
- **`Bash`** → Ejecutar test suites
- **`Read`** → Analizar coverage, resultados

### DEBUG Phase
- **`Write`** → Crear scripts de debugging
- **`Bash`** → Ejecutar debugging tools
- **`Read`** → Analizar logs, stack traces

### REFINE Phase
- **`Edit`** → Aplicar fixes, optimizaciones
- **`TodoWrite`** → Actualizar progreso
- **Loop back** → Repetir ciclo si no resuelto

## 📝 Quick Reference

**Flujo**: Plan → Code → Test → Debug → Refine → Loop hasta resolver
**Rules**: Transversales + específicas por fase
**Tools**: Claude Code nativo + rules application manual
**Goal**: Resolver tarea completamente mediante iteraciones