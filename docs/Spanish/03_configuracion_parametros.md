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

### Estructura Completa (Configuración 3D Actualizada)

```yaml
# Configuración de Grid 3D
grid:
  nx: 20                      # Número de celdas en X
  ny: 20                      # Número de celdas en Y
  nz: 10                      # Número de celdas en Z (3D)
  dx: 164.0                   # Tamaño de celda en X [ft]
  dy: 164.0                   # Tamaño de celda en Y [ft]
  dz: [50.0, 40.0, 35.0, 30.0, 25.0, 20.0, 15.0, 10.0, 8.0, 5.0]  # Espesor variable por capa [ft]

# Configuración General
general:
  random_seed: 42             # Semilla aleatoria para reproducibilidad

# Propiedades de Porosidad (Mejoradas)
porosity:
  base_value: 0.20            # Porosidad base [-]
  variation_amplitude: 0.10   # Amplitud de variación espacial [-]
  bounds:
    min: 0.05                 # Valor mínimo permitido [-]
    max: 0.35                 # Valor máximo permitido [-]
  correlation_length: 656.0    # Longitud de correlación espacial [ft]
  random_amplitude_factor: 0.5 # Factor de variación aleatoria [-]

# Propiedades de Permeabilidad (Extendidas)
permeability:
  base_value: 100.0           # Permeabilidad base [mD]
  variation_amplitude: 80.0   # Amplitud de variación espacial [mD]
  bounds:
    min: 10.0                 # Valor mínimo permitido [mD]
    max: 500.0                # Valor máximo permitido [mD]
  correlation_length: 984.0   # Longitud de correlación espacial [ft]
  porosity_correlation: 0.8   # Correlación con porosidad [-]
  tensor:
    Kx_factor: 1.0            # Factor de tensor de permeabilidad en X [-]
    Ky_factor: 1.0            # Factor de tensor de permeabilidad en Y [-]
    Kz_factor: 1.0            # Factor de tensor de permeabilidad en Z [-]

# Propiedades de Roca (10 Capas Geológicas)
rock:
  reference_pressure: 2900.0   # Presión de referencia [psi]
  layers:
    - id: 1
      name: "Shale Cap"
      depth_range: [7900, 7950]      # Rango de profundidad [ft]
      thickness: 50.0                # Espesor de capa [ft]
      lithology: "shale"
      porosity: 0.08                 # Porosidad promedio [-]
      permeability: 0.1              # Permeabilidad promedio [mD]
      compressibility: 1.0e-6        # Compresibilidad de roca [1/psi]
    # ... (9 capas adicionales con propiedades específicas)

# Propiedades de Fluidos (Oil-Water Completas)
fluid:
  oil_density: 850.0            # Densidad del petróleo [kg/m³]
  water_density: 1000.0         # Densidad del agua [kg/m³]
  oil_viscosity: 2.0            # Viscosidad del petróleo [cP]
  water_viscosity: 0.5          # Viscosidad del agua [cP]
  
  # Curvas de permeabilidad relativa
  relative_permeability:
    oil:
      residual_saturation: 0.20    # Saturación residual de petróleo [-]
      endpoint_krmax: 0.90         # Permeabilidad relativa máxima [-]
      corey_exponent: 2.0          # Exponente de Corey [-]
    water:
      connate_saturation: 0.15     # Saturación connata [-]
      endpoint_krmax: 0.85         # Permeabilidad relativa máxima [-]
      corey_exponent: 2.5          # Exponente de Corey [-]

# Configuración de Pozos (Estructura Mejorada)
wells:
  producers:
    - name: "PROD1"
      location: [15, 10]        # Coordenadas de grid [i, j]
      control_type: "bhp"       # Tipo de control: "bhp" o "rate"
      target_bhp: 2175.0        # BHP objetivo [psi]
      radius: 0.33              # Radio del pozo [ft]
      
  injectors:
    - name: "INJ1"
      location: [5, 10]         # Coordenadas de grid [i, j]
      control_type: "rate"      # Tipo de control: "bhp" o "rate"
      target_rate: 251.0        # Tasa de inyección objetivo [bbl/day]
      radius: 0.33              # Radio del pozo [ft]
      fluid_type: "water"       # Tipo de fluido inyectado

# Parámetros de Simulación (Extendidos)
simulation:
  total_time: 3650.0             # Tiempo total de simulación [days] (10 años)
  num_timesteps: 500             # Número de timesteps
  timestep_type: "linear"        # Tipo: "linear", "logarithmic", "custom"
  timestep_multiplier: 1.1       # Multiplicador para timesteps crecientes
  
  # Configuración del solver
  solver:
    tolerance: 1.0e-6            # Tolerancia de convergencia
    max_iterations: 25           # Iteraciones máximas por timestep
    linear_solver: "iterative"   # Solver: "direct", "iterative"

# Condiciones Iniciales (Detalladas)
initial_conditions:
  datum_depth: 8000.0         # Profundidad de referencia [ft]
  datum_pressure: 2900.0      # Presión en profundidad de referencia [psi]
  temperature: 176.0          # Temperatura del reservorio [°F]
  pressure_gradient: 0.433    # Gradiente de presión de poro [psi/ft]
  oil_water_contact: 8150.0   # Contacto petróleo-agua [ft]
  
  # Saturaciones iniciales por zona
  oil_zone:
    oil_saturation: 0.80      # Saturación de petróleo en zona petrolífera [-]
    water_saturation: 0.20    # Saturación de agua en zona petrolífera [-]

# Parámetros Geomecánicos (Completos)
geomechanics:
  enabled: true                 # Activar acoplamiento geomecánico
  plasticity: false             # Activar plasticidad
  
  # Parámetros de esfuerzo
  stress:
    surface_stress: 2000.0       # Esfuerzo total en superficie [psi]
    overburden_gradient: 1.0     # Gradiente de sobrecarga [psi/ft]
    pore_pressure_gradient: 0.433  # Gradiente de presión de poro [psi/ft]
    min_horizontal_stress_ratio: 0.7  # Relación K0 [-]
    
  # Propiedades mecánicas
  mechanical:
    young_modulus: 1450000.0      # Módulo de Young [psi]
    poisson_ratio: 0.25           # Relación de Poisson [-]
    biot_coefficient: 0.8         # Coeficiente de Biot [-]

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