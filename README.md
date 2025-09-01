# Eagle West Field - Simulación de Reservorios con MRST

## 🛢️ Bienvenido al Proyecto

Este es un proyecto de **simulación de reservorios petrolíferos** que combina ingeniería de yacimientos tradicional con herramientas modernas de desarrollo de software y asistencia de IA.

### ¿Qué encontrarás aquí?

Un **modelo completo del Campo Eagle West** desarrollado con MRST (MATLAB Reservoir Simulation Toolbox), diseñado para:

- **Ingenieros de Petróleo**: Flujo de trabajo completo desde geología hasta producción
- **Desarrolladores**: Arquitectura modular con estándares de código estrictos  
- **Investigadores**: Sistema documentado y reproducible para estudios de reservorios

## 🎯 ¿Por qué este proyecto?

La simulación de reservorios es compleja: involucra geología, física de fluidos, ingeniería de pozos, y análisis económico. Este proyecto demuestra cómo organizar toda esta complejidad en un sistema **modular, documentado y automatizado**.

### Campo Eagle West - Características principales

- **2,600 acres** de extensión offshore
- **15 pozos** (10 productores + 5 inyectores)  
- **5 fallas principales** que afectan el flujo
- **3 fases** (petróleo, agua, gas) con liberación de gas
- **40 años** de desarrollo planificado

## 🚀 Cómo explorar el proyecto

### 1. **Para entender el modelo técnico**
👉 Ve a [`docs/`](/docs) - Documentación técnica completa del reservorio

### 2. **Para ver el código en acción**
```bash
# Ejecutar simulación completa (requiere Octave + MRST)
octave mrst_simulation_scripts/s99_run_workflow.m
```

### 3. **Para desarrolladores**
- **Arquitectura**: Sistema multi-agente con IA (Claude Code)
- **Estándares**: Validación automática y reglas de código estrictas
- **Datos**: Estructura modular en 9 archivos `.mat` canónicos

## 📊 Estructura del proyecto

```
📦 Proyecto Eagle West Field
├── 🛢️ mrst_simulation_scripts/    # Scripts de simulación (25 fases)
├── 📖 docs/                       # Documentación técnica detallada  
├── 🤖 .claude/                    # Configuración de IA y agentes
├── 📊 data/                       # Modelo de datos del reservorio
└── 📝 README.md                   # Esta guía de bienvenida
```

## 🎓 ¿Qué puedes aprender?

### Ingeniería de Reservorios
- Modelado geológico y grillas PEBI
- Propiedades de roca y fluidos (PVT/SCAL)  
- Sistemas de pozos y controles de producción
- Simulación de flujo multifásico

### Desarrollo de Software
- Arquitectura modular y documentación como especificación
- Validación automática y estándares de código
- Integración de IA para desarrollo asistido
- Gestión de datos científicos complejos

### Buenas Prácticas
- **Canon-First**: La documentación es la autoridad
- **Fail-Fast**: Validación inmediata, errores claros
- **KISS**: Simplicidad sobre complejidad
- **Modularidad**: Cada componente con responsabilidad única

## 🛠️ Herramientas utilizadas

- **MRST**: Simulación de reservorios (Octave/MATLAB)
- **Claude Code**: Desarrollo asistido por IA
- **YAML**: Configuración centralizada
- **Git**: Control de versiones con hooks automáticos

## 🤝 ¿Cómo contribuir?

1. **Explora** la documentación en [`docs/`](/docs)
2. **Entiende** el modelo usando [`VARIABLE_INVENTORY.md`](/docs/Planning/Reservoir_Definition/VARIABLE_INVENTORY.md)
3. **Sigue** las reglas de desarrollo en [`.claude/rules/`](/.claude/rules/)
4. **Usa** los comandos automáticos (`/validate`, `/new-script`, etc.)

## 📈 Estado del proyecto

✅ **Simulación completa funcional** - 25 scripts integrados  
✅ **Documentación al 100%** - Todas las configuraciones documentadas  
✅ **Sistema de pruebas** - 38+ archivos de test  
✅ **Datos consolidados** - 9 archivos .mat canónicos  
✅ **IA integrada** - Claude Code para desarrollo asistido  

---

## 💡 ¿Por dónde empezar?

- **Ingeniero de Petróleo**: [`docs/Planning/Reservoir_Definition/`](/docs/Planning/Reservoir_Definition/)
- **Desarrollador**: [`.claude/`](/.claude/) y [`CLAUDE.md`](/CLAUDE.md)  
- **Investigador**: [`data/`](/data/) y scripts de simulación
- **Curioso**: Ejecuta `octave mrst_simulation_scripts/s99_run_workflow.m` y observa

---

**¿Preguntas?** Este proyecto está diseñado para ser autoexplicativo. La documentación en `docs/` contiene todo el análisis técnico profundo, mientras que este README te da la bienvenida y te orienta hacia donde necesitas ir.

🚀 **¡Bienvenido al mundo de la simulación de reservorios moderna!**