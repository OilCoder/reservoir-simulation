# Eagle West Field - MRST Simulation

Simulación de yacimiento Eagle West usando MATLAB/Octave nativo con MRST.

## Archivos Principales

- **`s99_run_workflow.m`** - **Ejecutar simulación completa**
- `s01_initialize_mrst.m` - Inicializar entorno MRST
- `s02_create_grid.m` - Crear grid del yacimiento (40×40×12)
- `s03_define_fluids.m` - Definir propiedades de fluidos (3-phase)
- `read_yaml_config.m` - Lector de configuraciones YAML
- `config/` - **Configuración del yacimiento**
- `../data/mrst_simulation/` - Resultados de simulación

## Uso Básico

### 1. Configurar Yacimiento
Editar archivos en carpeta `config/`:
- `grid_config.yaml` - Grid 40×40×12 (82×74×8.3 ft celdas)
- `rock_properties_config.yaml` - Propiedades por capa (12 layers)
- `fluid_properties_config.yaml` - Black oil 3-phase (API 32°)
- `wells_config.yaml` - 15 pozos (10 productores + 5 inyectores)

### 2. Ejecutar Simulación
```matlab
% En MATLAB/Octave:
cd mrst_simulation_scripts
s99_run_workflow
```

Opciones avanzadas:
```matlab
% Solo validación (primeras 3 fases)
s99_run_workflow('validation_only', true)

% Ejecutar fases específicas
s99_run_workflow('phases', {'s01', 's02', 's03'})

% Sin output detallado
s99_run_workflow('verbose', false)
```

### 3. Ver Resultados
Los resultados se guardan en:
```
../data/mrst_simulation/
├── results/     # Resultados .mat y reportes
├── static/      # Grid, fluidos, propiedades
├── logs/        # Logs de ejecución
└── exports/     # Datos exportados
```

## Configuración Detallada

### Grid (Malla) - 40×40×12
```yaml
grid:
  nx: 40              # Celdas en X (3,280 ft total)
  ny: 40              # Celdas en Y (2,960 ft total)  
  nz: 12              # Capas en Z (100 ft total)
  cell_size_x: 82.0   # Tamaño celda X (ft)
  cell_size_y: 74.0   # Tamaño celda Y (ft)
  layer_thicknesses: [8.3, 8.3, ..., 8.3]  # 12 capas de 8.3 ft
  origin_z: 8000.0    # Profundidad top (ft TVDSS)
```

### Pozos - 15 Total (6 Fases de Desarrollo)
```yaml
wells:
  producers:    # 10 productores (EW-001 to EW-010)
    - name: "EW-001"
      grid_location: [15, 10]   # Coordenadas en grid
      start_day: 180            # Día de inicio
      well_type: "vertical"     # Tipo de pozo
      
  injectors:    # 5 inyectores (IW-001 to IW-005)  
    - name: "IW-001"
      grid_location: [5, 10]
      start_day: 450
      well_type: "vertical"
```

### Propiedades de Roca - 12 Capas
```yaml
rock_properties:
  # Upper Zone (Layers 1-3: Sand, Layer 4: Shale)
  # Middle Zone (Layers 5-7: Sand, Layer 8: Shale)
  # Lower Zone (Layers 9-12: Sand decreasing quality)
  
  porosity_layers: [0.200, 0.195, 0.190, 0.050,    # Upper + barrier
                    0.235, 0.230, 0.225, 0.050,    # Middle + barrier
                    0.150, 0.145, 0.140, 0.135]    # Lower zone
                    
  permeability_layers: [90, 85, 80, 0.01,          # mD - Upper + barrier
                        175, 170, 160, 0.01,        # mD - Middle + barrier  
                        30, 25, 22, 20]             # mD - Lower zone
```

### Fluidos - 3-Phase Black Oil
```yaml
fluid_properties:
  # Oil: API 32°, bubble point 2,100 psi
  oil_density: 865.0      # kg/m³ (SG 0.865)
  oil_viscosity: 0.92     # cP @ bubble point
  bubble_point: 2100.0    # psi @ 176°F
  solution_gor: 450.0     # scf/STB
  
  # Water: Formation brine
  water_density: 1025.0   # kg/m³ (SG 1.025) 
  water_salinity: 35000   # ppm TDS
  
  # Relative permeability endpoints
  connate_water_saturation: 0.15
  residual_oil_saturation: 0.25
```

## Requisitos

### Software Necesario
- **MATLAB R2019b+** o **Octave 6.0+**
- **MRST** instalado en `/opt/mrst` (o `/usr/local/mrst`)
  - Descarga: https://www.sintef.no/projectweb/mrst/download/
  - Módulos requeridos: ad-core, ad-blackoil, ad-props, incomp
- **YAML support** (yamlread function o parser incluído)

### Instalación MRST
```bash
# Descargar e instalar MRST
git clone https://github.com/SINTEF-AppliedCompSci/MRST.git /opt/mrst
chmod -R 755 /opt/mrst

# En MATLAB/Octave verificar:
cd /opt/mrst
startup
mrstModule add ad-core ad-blackoil ad-props incomp
```

## Workflow de Simulación

### Fases de Ejecución (s01-s10)
1. **s01_initialize_mrst** - Setup MRST, cargar módulos ✅
2. **s02_create_grid** - Grid 40×40×12 Cartesiano ✅  
3. **s03_define_fluids** - PVT 3-phase, rel-perm ✅
4. **s04_structural_framework** - Estructura geológica 🚧
5. **s05_add_faults** - Sistema de 5 fallas 🚧
6. **s06_grid_refinement** - Refinamiento local 🚧
7. **s07_define_rock_types** - 6 tipos de roca (RT1-RT6) 🚧
8. **s08_assign_layer_properties** - Propiedades por capa 🚧
9. **s09_spatial_heterogeneity** - Heterogeneidad espacial 🚧
10. **s10_run_simulation** - Simulación completa 🚧

✅ = Implementado | 🚧 = En desarrollo (placeholders automáticos)

### Estado del Proyecto
- **Arquitectura**: Convertida de Python a MATLAB/Octave nativo
- **Configuración**: YAMLs completos según documentación
- **Scripts Core**: s01-s03 completamente implementados
- **Workflow**: Orchestrador maestro s99 funcional
- **Próximo**: Implementar s04-s10 según se requiera

## Estructura de Archivos

```
mrst_simulation_scripts/
├── s99_run_workflow.m          # 🎯 EJECUTAR AQUÍ
├── s01_initialize_mrst.m       # ✅ Inicialización MRST
├── s02_create_grid.m           # ✅ Grid construction  
├── s03_define_fluids.m         # ✅ Fluid properties
├── s04_structural_framework.m  # 🚧 Auto-placeholder
├── s05_add_faults.m            # 🚧 Auto-placeholder
├── s06_grid_refinement.m       # 🚧 Auto-placeholder
├── s07_define_rock_types.m     # 🚧 Auto-placeholder
├── s08_assign_layer_properties.m # 🚧 Auto-placeholder
├── s09_spatial_heterogeneity.m # 🚧 Auto-placeholder
├── read_yaml_config.m          # ✅ YAML reader
├── config/
│   ├── grid_config.yaml        # ✅ Grid 40×40×12
│   ├── rock_properties_config.yaml # ✅ 12 layers
│   ├── fluid_properties_config.yaml # ✅ 3-phase
│   └── wells_config.yaml       # ✅ 15 wells, 6 phases
└── README.md                   # 📖 Este archivo
```

## Desarrollo Eagle West Field

### Especificaciones Técnicas
- **Yacimiento**: 2,600 acres, anticline fallado
- **Grid**: 40×40×12 = 19,200 celdas activas
- **Fallas**: 5 principales (A, B, C, D, E)
- **Compartimentos**: 2 principales (Northern/Southern)
- **Pozos**: 15 total, desarrollo en 6 fases
- **Producción**: Target 18,500 STB/day (Fase 6)
- **Simulación**: 10 años (3,650 días)

### Documentación Canon
Toda la especificación técnica está en:
```
../obsidian-vault/Planning/Reservoir_Definition/
├── 00_Overview.md              # Field overview
├── 01_Structural_Geology.md    # Grid & structure  
├── 02_Rock_Properties.md       # Rock types RT1-RT6
├── 03_Fluid_Properties.md      # PVT & SCAL data
├── 05_Wells_Completions.md     # Well locations
├── 06_Production_History.md    # Development phases
└── 08_MRST_Implementation.md   # Technical specs
```

## Troubleshooting

### Problemas Comunes

1. **MRST no encontrado**
   ```
   Error: MRST installation not found
   Solución: Instalar MRST en /opt/mrst y ejecutar startup
   ```

2. **Error al leer YAML**
   ```
   Error: yamlread function not found
   Solución: El script incluye parser YAML básico como fallback
   ```

3. **Grid creation failed**
   ```
   Error: Grid creation test failed
   Solución: Verificar módulos MRST cargados (mrstModule list)
   ```

4. **Phase script not found**
   ```
   Warning: Script s04_*.m not found. Creating placeholder.
   Solución: Normal - placeholders se crean automáticamente
   ```

### Logs y Debug
```matlab
% Ver logs detallados:
s99_run_workflow('verbose', true)

% Solo validar configuración:
s99_run_workflow('validation_only', true)

% Ejecutar fase individual:
G = s02_create_grid();  % Test grid creation
fluid = s03_define_fluids();  % Test fluid setup
```

### Archivos de Salida
- **Workflow results**: `../data/mrst_simulation/results/workflow_results_YYYYMMDD_HHMMSS.mat`
- **Grid data**: `../data/mrst_simulation/static/grid_structure.mat`  
- **Fluid data**: `../data/mrst_simulation/static/fluid_properties.mat`
- **Summary reports**: `../data/mrst_simulation/results/workflow_summary_*.txt`

## Soporte

Para problemas o preguntas:
1. Revisar logs en `../data/mrst_simulation/logs/`
2. Verificar configuración YAML en `config/`
3. Validar instalación MRST: `mrstVersion`
4. Ejecutar con `'verbose', true` para debug

---

**Eagle West Field MRST Simulation**  
*MATLAB/Octave Native Implementation*  
*Claude Code AI System - January 2025*