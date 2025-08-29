# REFACTORING PLAN: S15-S19 Scripts

## PROBLEMA IDENTIFICADO
Los scripts s15-s19 tienen dependencias circulares y estructuras inconsistentes que impiden su ejecución funcional.

## NUEVA ESTRUCTURA CANÓNICA

### Archivos .mat con Responsabilidades Únicas
```
/workspace/data/mrst/
├── wells.mat         # S15→S16: W array (MRST wells)
├── controls.mat      # S17: production_controls, injection_controls
├── schedule.mat      # S18: MRST schedule structure
├── targets.mat       # S19: production_targets by phase
└── development.mat   # S20: consolidated development plan
```

### Scripts Refactorizados

#### **s15_well_placement.m**
- **Input**: grid.mat, rock.mat, wells_config.yaml
- **Output**: wells.mat con array `W` básico
- **Responsabilidad**: Solo ubicación de pozos

#### **s16_well_completions.m**
- **Input**: wells.mat (del s15)
- **Output**: wells.mat actualizado con completion data
- **Responsabilidad**: Solo completaciones

#### **s17_production_controls.m**
- **Input**: wells.mat, production_config.yaml
- **Output**: controls.mat con estructuras de control
- **Responsabilidad**: Solo controles de producción/inyección

#### **s18_development_schedule.m**
- **Input**: controls.mat
- **Output**: schedule.mat con MRST schedule
- **Responsabilidad**: Solo cronograma MRST

#### **s19_production_targets.m**
- **Input**: controls.mat, schedule.mat
- **Output**: targets.mat con production targets
- **Responsabilidad**: Solo objetivos de producción

#### **s20_consolidate_development.m** (NUEVO)
- **Input**: wells.mat, controls.mat, schedule.mat, targets.mat
- **Output**: development.mat consolidado
- **Responsabilidad**: Consolidación final para simulación

## BENEFICIOS
✅ Independencia de scripts
✅ Una responsabilidad por script
✅ Sin dependencias circulares
✅ Cumplimiento de 6 políticas inmutables
✅ Scripts funcionalmente ejecutables

Fecha: 2025-08-28
Status: En progreso