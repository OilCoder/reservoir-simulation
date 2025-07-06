# Capítulo 3: Configuración de Parámetros

## 3.1 Introducción

En este capítulo aprenderás a configurar los parámetros de simulación usando el sistema YAML de GeomechML. Este sistema centralizado permite modificar todos los aspectos de la simulación sin tocar el código, facilitando la experimentación y garantizando la reproducibilidad.

### **Objetivos del Capítulo**
- ✅ Entender el sistema de configuración YAML
- ✅ Configurar parámetros de grid y geometría
- ✅ Definir propiedades de roca y fluidos
- ✅ Configurar pozos y controles
- ✅ Personalizar parámetros de simulación

## 3.2 Sistema de Configuración YAML

GeomechML utiliza un sistema de configuración centralizado basado en archivos YAML que permite modificar parámetros de simulación sin cambiar código. Este enfoque facilita la experimentación y la reproducibilidad.

## Arquitectura de Configuración

### Jerarquía de Configuración

```
config/
├── reservoir_config.yaml    # Configuración principal
└── README.md               # Documentación de parámetros
```

### Parser de Configuración

El módulo `util_read_config.m` proporciona:
- Parser YAML compatible con Octave
- Validación de tipos de datos
- Valores por defecto automáticos
- Manejo de errores robusto

## Archivo Principal: `reservoir_config.yaml`

### Estructura Completa

```yaml
# Configuración de Grid
grid:
  nx: 20                    # Número de celdas en X
  ny: 20                    # Número de celdas en Y
  dx: 164                   # Tamaño de celda en X [ft]
  dy: 164                   # Tamaño de celda en Y [ft]
  dz: 33                    # Espesor de celda [ft]

# Propiedades de Porosidad
porosity:
  base_value: 0.2           # Porosidad base [-]
  variation_amplitude: 0.05 # Amplitud de variación [-]
  min_value: 0.05           # Valor mínimo [-]
  max_value: 0.3            # Valor máximo [-]

# Propiedades de Permeabilidad
permeability:
  base_value: 100           # Permeabilidad base [mD]
  variation_amplitude: 50   # Amplitud de variación [mD]
  min_value: 1              # Valor mínimo [mD]
  max_value: 500            # Valor máximo [mD]

# Propiedades de Roca
rock:
  compressibility: 1e-5     # Compresibilidad de roca [1/psi]
  n_regions: 3              # Número de regiones litológicas

# Propiedades de Fluidos
fluid:
  oil_density: 850          # Densidad del oil [kg/m³]
  water_density: 1000       # Densidad del water [kg/m³]
  oil_viscosity: 2          # Viscosidad del oil [cP]
  water_viscosity: 0.5      # Viscosidad del water [cP]

# Configuración de Pozos
wells:
  injector_i: 5             # Posición I del inyector
  injector_j: 10            # Posición J del inyector
  producer_i: 15            # Posición I del productor
  producer_j: 10            # Posición J del productor
  injector_rate: 251        # Tasa de inyección [bbl/day]
  producer_bhp: 2175        # BHP del productor [psi]

# Parámetros de Simulación
simulation:
  total_time: 365           # Tiempo total [days]
  num_timesteps: 50         # Número de timesteps

# Condiciones Iniciales
initial_conditions:
  pressure: 2900            # Presión inicial [psi]
  temperature: 176          # Temperatura [°F]
  water_saturation: 0.2     # Saturación de water [-]

# Parámetros Geomecánicos
geomechanics:
  enabled: true             # Activar geomecánica
  overburden_gradient: 1.0  # Gradiente de sobrecarga [psi/ft]
  pore_pressure_gradient: 0.433  # Gradiente de presión de poro [psi/ft]

# Configuración de Salida
output:
  save_states: true         # Guardar states de simulación
  save_wells: true          # Guardar soluciones de pozos
  export_format: "mat"      # Formato de exportación
  
# Metadata del Proyecto
metadata:
  project_name: "GeomechML"
  version: "1.0"
  description: "MRST Geomechanical Simulation for ML"
```

## Secciones de Configuración

### 1. Grid Configuration

Define la geometría del modelo de simulación:

```yaml
grid:
  nx: 20        # Resolución horizontal
  ny: 20        # Resolución vertical
  dx: 164       # Tamaño físico [ft]
  dy: 164       # Tamaño físico [ft]
  dz: 33        # Espesor [ft]
```

**Consideraciones**:
- Grid 20x20 optimizado para ML (matrices cuadradas)
- Tamaño total: 3280 x 3280 ft (1 km²)
- Resolución adecuada para heterogeneidad

### 2. Porosity Configuration

Controla la distribución espacial de porosidad:

```yaml
porosity:
  base_value: 0.2           # Valor central
  variation_amplitude: 0.05 # ±5% de variación
  min_value: 0.05           # Límite físico inferior
  max_value: 0.3            # Límite físico superior
```

**Algoritmo de Generación**:
```octave
% Variación espacial con ruido correlacionado
phi = base_value + variation_amplitude * randn(nx, ny);
phi = max(min_value, min(phi, max_value));
```

### 3. Permeability Configuration

Define la correlación permeabilidad-porosidad:

```yaml
permeability:
  base_value: 100           # Permeabilidad de referencia [mD]
  variation_amplitude: 50   # Variación espacial [mD]
  min_value: 1              # Límite inferior [mD]
  max_value: 500            # Límite superior [mD]
```

**Relación φ-k**:
```octave
% Correlación Kozeny-Carman modificada
k = base_value * (phi/phi_ref)^n_exp;
```

### 4. Rock Properties

Parámetros geomecánicos por región:

```yaml
rock:
  compressibility: 1e-5     # Compresibilidad global [1/psi]
  n_regions: 3              # Número de litologías
```

**Regiones Automáticas**:
- **Región 1**: φ < 0.18 (tight rock)
- **Región 2**: 0.18 ≤ φ < 0.22 (medium rock)  
- **Región 3**: φ ≥ 0.22 (loose rock)

### 5. Fluid Properties

Propiedades de fluidos oil/water:

```yaml
fluid:
  oil_density: 850          # Densidad típica de crude [kg/m³]
  water_density: 1000       # Densidad de brine [kg/m³]
  oil_viscosity: 2          # Viscosidad media [cP]
  water_viscosity: 0.5      # Viscosidad de water [cP]
```

### 6. Wells Configuration

Ubicación y controles de pozos:

```yaml
wells:
  injector_i: 5             # Esquina izquierda
  injector_j: 10            # Centro vertical
  producer_i: 15            # Esquina derecha
  producer_j: 10            # Centro vertical
  injector_rate: 251        # Tasa típica [bbl/day]
  producer_bhp: 2175        # BHP de drawdown [psi]
```

**Patrón de Pozos**:
```
     1  5  10  15  20
  1  .  .   .   .   .
  5  .  .   .   .   .
 10  .  I   .   P   .    I=Inyector, P=Productor
 15  .  .   .   .   .
 20  .  .   .   .   .
```

### 7. Simulation Parameters

Control temporal de la simulación:

```yaml
simulation:
  total_time: 365           # Un año de simulación
  num_timesteps: 50         # Resolución temporal
```

**Timestep Distribution**:
- Timesteps variables (más pequeños al inicio)
- Promedio: ~7.3 días por timestep
- Permite capturar transientes

### 8. Initial Conditions

Estado inicial del yacimiento:

```yaml
initial_conditions:
  pressure: 2900            # Presión hidrostática típica [psi]
  temperature: 176          # Temperatura de yacimiento [°F]
  water_saturation: 0.2     # Saturación inicial [-]
```

## Uso del Sistema de Configuración

### Cargar Configuración

```octave
% Cargar configuración desde archivo
config = util_read_config('../config/reservoir_config.yaml');

% Acceder a parámetros
nx = config.grid.nx;
ny = config.grid.ny;
p_init = config.initial_conditions.pressure;
```

### Modificar Parámetros

```octave
% Modificar en memoria
config.grid.nx = 50;
config.simulation.total_time = 730;

% Pasar configuración modificada
[G, rock, fluid] = setup_field(config);
```

### Validación Automática

El parser incluye validaciones:

```octave
% Validaciones automáticas
assert(config.grid.nx > 0, 'Grid nx must be positive');
assert(config.porosity.min_value < config.porosity.max_value, ...
       'Invalid porosity range');
assert(config.wells.producer_bhp > 0, 'BHP must be positive');
```

## Valores por Defecto

Si faltan parámetros, se usan valores por defecto:

| Parámetro | Valor por Defecto | Unidad |
|-----------|-------------------|--------|
| `grid.nx` | 20 | - |
| `grid.ny` | 20 | - |
| `grid.dx` | 164 | ft |
| `porosity.base_value` | 0.2 | - |
| `permeability.base_value` | 100 | mD |
| `wells.producer_bhp` | 2175 | psi |
| `wells.injector_rate` | 251 | bbl/day |
| `simulation.total_time` | 365 | days |
| `simulation.num_timesteps` | 50 | - |

## Configuraciones Predefinidas

### Configuración Rápida (Testing)

```yaml
simulation:
  total_time: 30            # 1 mes
  num_timesteps: 10         # Timesteps grandes
  
grid:
  nx: 10                    # Grid reducido
  ny: 10
```

### Configuración de Alta Resolución

```yaml
grid:
  nx: 50                    # Grid fino
  ny: 50
  
simulation:
  num_timesteps: 100        # Alta resolución temporal
```

### Configuración de Heterogeneidad Alta

```yaml
porosity:
  variation_amplitude: 0.1  # ±10% variación
  
permeability:
  variation_amplitude: 100  # ±100 mD variación
```

## Troubleshooting

### Errores Comunes

1. **Sintaxis YAML inválida**
   ```
   Error: Cannot parse YAML file
   ```
   - Verificar indentación (espacios, no tabs)
   - Confirmar sintaxis de listas y diccionarios

2. **Valores fuera de rango**
   ```
   Error: Porosity values outside physical limits
   ```
   - Verificar `min_value < max_value`
   - Confirmar rangos físicos realistas

3. **Archivo no encontrado**
   ```
   Error: Configuration file not found
   ```
   - Verificar path relativo desde directorio de ejecución
   - Confirmar permisos de lectura

### Validación Manual

```octave
% Script de validación
config = util_read_config('config.yaml');

% Verificar rangos
assert(config.porosity.min_value >= 0.01, 'Porosity too low');
assert(config.porosity.max_value <= 0.5, 'Porosity too high');
assert(config.permeability.min_value >= 0.1, 'Permeability too low');

fprintf('Configuration validated successfully\n');
```

## 3.12 Próximos Pasos

### **Verificación Final**

Antes de continuar, asegúrate de que:
- ✅ Entiendes la estructura del archivo YAML
- ✅ Puedes modificar parámetros básicos
- ✅ El sistema valida tu configuración
- ✅ Puedes crear configuraciones personalizadas

### **¿Qué Sigue?**

Ahora que dominas la configuración de parámetros, estás listo para:

📖 **[Capítulo 4: Simulación de Yacimientos](04_simulacion_yacimientos.md)**
- Ejecutar simulaciones MRST completas
- Entender el workflow de simulación
- Monitorear y validar resultados

### **Recursos Adicionales**

- 📝 **YAML Specification**: https://yaml.org/spec/1.2/spec.html
- 📚 **MRST Parameters**: https://www.sintef.no/mrst/documentation/
- 🔧 **Configuration Examples**: Ver `config/examples/`

---

*[⬅️ Capítulo 2: Configuración Inicial](02_configuracion_inicial.md) | [Siguiente: Simulación de Yacimientos ➡️](04_simulacion_yacimientos.md)*

*Fuente: `config/reservoir_config.yaml` y `MRST_simulation_scripts/util_read_config.m`* 