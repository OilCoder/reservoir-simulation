# Capítulo 10: Casos de Uso Prácticos

## 10.1 Introducción

Este capítulo presenta casos de uso prácticos completos del sistema GeomechML, desde la configuración inicial hasta la generación de modelos de machine learning. Cada caso incluye configuraciones específicas, procedimientos paso a paso y análisis de resultados.

### **Objetivos del Capítulo**
- ✅ Ejecutar casos de uso completos paso a paso
- ✅ Configurar simulaciones para diferentes escenarios
- ✅ Analizar resultados y validar modelos
- ✅ Implementar mejores prácticas de workflow
- ✅ Resolver problemas comunes de implementación

## 10.2 Caso de Uso 1: Simulación de Inyección de Agua

### **Descripción del Escenario**

Este caso simula un reservorio con inyección de agua para recuperación secundaria, modelando efectos geomecánicos de compactación durante 10 años de producción.

#### **Objetivos del Caso**
- Modelar reservorio heterogéneo de 10 capas geológicas
- Simular inyección de agua y producción de petróleo
- Analizar compactación y efectos geomecánicos
- Entrenar modelo sustituto para predicción rápida

### **Paso 1: Configuración del Reservorio**

#### **Archivo de Configuración: `reservoir_water_injection.yaml`**

```yaml
# Caso de Uso 1: Inyección de Agua
metadata:
  project_name: "Water Injection Recovery - Case Study 1"
  description: "10-year water injection simulation with geomechanical coupling"
  author: "GeomechML Team"
  case_study: "water_injection_recovery"

# Grid 3D para alta resolución
grid:
  nx: 25                      # Resolución aumentada para mejor detalle
  ny: 25
  nz: 10
  dx: 131.2                   # 25x25 grid con mismo área total
  dy: 131.2
  dz: [60.0, 50.0, 45.0, 40.0, 35.0, 30.0, 25.0, 20.0, 15.0, 10.0]

# Propiedades heterogéneas optimizadas
porosity:
  base_value: 0.22
  variation_amplitude: 0.12
  bounds:
    min: 0.08
    max: 0.38
  correlation_length: 525.0   # Correlación más localizada
  random_amplitude_factor: 0.6

permeability:
  base_value: 150.0
  variation_amplitude: 120.0
  bounds:
    min: 5.0
    max: 800.0
  correlation_length: 787.0
  porosity_correlation: 0.85  # Fuerte correlación con porosidad

# Capas geológicas específicas del caso
rock:
  reference_pressure: 3000.0
  layers:
    - id: 1
      name: "Cap Rock"
      depth_range: [7800, 7860]
      lithology: "shale"
      porosity: 0.06
      permeability: 0.05
      compressibility: 0.8e-6
      
    - id: 2
      name: "Upper Sand"
      depth_range: [7860, 7910]
      lithology: "sandstone"
      porosity: 0.28
      permeability: 250.0
      compressibility: 3.8e-6
      
    - id: 3
      name: "Tight Streak"
      depth_range: [7910, 7955]
      lithology: "shale"
      porosity: 0.12
      permeability: 2.0
      compressibility: 1.5e-6
      
    - id: 4
      name: "Main Reservoir"
      depth_range: [7955, 7995]
      lithology: "sandstone"
      porosity: 0.32
      permeability: 400.0
      compressibility: 4.2e-6
      
    - id: 5
      name: "Carbonate Streak"
      depth_range: [7995, 8030]
      lithology: "limestone"
      porosity: 0.20
      permeability: 100.0
      compressibility: 2.5e-6

# Configuración de pozos para inyección de agua
wells:
  producers:
    - name: "PROD1"
      location: [20, 12]
      control_type: "bhp"
      target_bhp: 2000.0        # BHP más bajo para mayor drawdown
      radius: 0.328
      
    - name: "PROD2"
      location: [20, 18]
      control_type: "bhp"
      target_bhp: 2000.0
      radius: 0.328
      
  injectors:
    - name: "INJ1"
      location: [5, 8]
      control_type: "rate"
      target_rate: 400.0        # Tasa de inyección aumentada
      radius: 0.328
      fluid_type: "water"
      
    - name: "INJ2"
      location: [5, 17]
      control_type: "rate"
      target_rate: 400.0
      radius: 0.328
      fluid_type: "water"

# Propiedades de fluidos para inyección de agua
fluid:
  oil_density: 820.0
  water_density: 1020.0
  oil_viscosity: 1.8
  water_viscosity: 0.6
  
  relative_permeability:
    oil:
      residual_saturation: 0.25
      endpoint_krmax: 0.85
      corey_exponent: 2.2
    water:
      connate_saturation: 0.18
      endpoint_krmax: 0.80
      corey_exponent: 2.8

# Condiciones iniciales
initial_conditions:
  datum_depth: 7950.0
  datum_pressure: 3000.0
  temperature: 180.0
  oil_water_contact: 8100.0
  
  oil_zone:
    oil_saturation: 0.78
    water_saturation: 0.22

# Simulación extendida para recuperación secundaria
simulation:
  total_time: 3650.0          # 10 años
  num_timesteps: 730          # Timesteps más frecuentes (cada 5 días)
  timestep_type: "linear"
  
  solver:
    tolerance: 5.0e-7         # Mayor precisión
    max_iterations: 30

# Geomecánica con énfasis en compactación
geomechanics:
  enabled: true
  stress:
    surface_stress: 1800.0
    overburden_gradient: 1.05
    pore_pressure_gradient: 0.445
    min_horizontal_stress_ratio: 0.65
    
  mechanical:
    young_modulus: 1650000.0
    poisson_ratio: 0.28
    biot_coefficient: 0.85
```

### **Paso 2: Ejecutar la Simulación**

```bash
# Navegar al directorio de scripts
cd mrst_simulation_scripts/

# Ejecutar workflow completo
octave --eval "s99_run_workflow()"

# Monitorear progreso
tail -f ../data/logs/simulation.log
```

#### **Salida Esperada**

```
================================================================
MRST GEOMECHANICAL SIMULATION WORKFLOW - INICIANDO
================================================================

✅ Paso 1: Inicialización MRST completada
✅ Paso 2: Estructura de directorios creada
✅ Paso 3: Componentes del sistema configurados
  - Grid: 25×25×10 = 6250 celdas
  - Pozos: 2 productores, 2 inyectores
  - Capas geológicas: 5 unidades

✅ Paso 4: Simulación ejecutada
  - Tiempo de simulación: 3650 días
  - Timesteps: 730
  - Tiempo de cómputo: 8.7 minutos

✅ Paso 5: Datos exportados
  - Condiciones iniciales: 156 KB
  - Campos dinámicos: 1.2 GB
  - Datos de pozos: 45 KB
  - Metadata: 12 KB

================================================================
WORKFLOW COMPLETADO EXITOSAMENTE
================================================================
```

### **Paso 3: Análisis de Resultados**

#### **Dashboard de Visualización**

```bash
# Iniciar dashboard
cd ../dashboard/
streamlit run dashboard.py
```

#### **Análisis de Métricas Clave**

```python
# Script de análisis post-simulación
import numpy as np
import matplotlib.pyplot as plt
from dashboard.util_data_loader import MRSTDataLoader
from dashboard.util_metrics import PerformanceMetrics

# Cargar datos
data_loader = MRSTDataLoader('data/')
dataset = data_loader.load_complete_dataset()

# Calcular métricas de rendimiento
metrics_calculator = PerformanceMetrics(dataset)
kpis = metrics_calculator.calculate_key_performance_indicators()

print("=== MÉTRICAS DEL CASO DE USO 1 ===")
print(f"Factor de recuperación: {kpis['recovery_factor']:.1%}")
print(f"Eficiencia de barrido: {kpis['sweep_efficiency']:.1%}")
print(f"Producción acumulada: {kpis['cumulative_oil']:.0f} bbl")
print(f"Inyección acumulada: {kpis['cumulative_water_inj']:.0f} bbl")
print(f"Relación voidage: {kpis['voidage_ratio']:.2f}")

# Análisis de compactación
pressure_data = dataset['fields']['pressure']
initial_pressure = dataset['initial']['pressure']

# Máximo drop de presión
max_pressure_drop = np.max(initial_pressure) - np.min(pressure_data[-1])
print(f"Máximo drop de presión: {max_pressure_drop:.0f} psi")

# Análisis de frente de agua
saturation_data = dataset['fields']['sw']
water_breakthrough_time = None

for t, sat_field in enumerate(saturation_data):
    # Verificar breakthrough en productores (ubicaciones [20,12] y [20,18])
    if sat_field[12, 20] > 0.5 or sat_field[18, 20] > 0.5:
        water_breakthrough_time = dataset['temporal']['time_days'][t]
        break

if water_breakthrough_time:
    print(f"Tiempo de breakthrough: {water_breakthrough_time:.0f} días")
else:
    print("No se detectó breakthrough de agua")
```

#### **Resultados Esperados del Caso 1**

```
=== MÉTRICAS DEL CASO DE USO 1 ===
Factor de recuperación: 24.3%
Eficiencia de barrido: 68.5%
Producción acumulada: 487250 bbl
Inyección acumulada: 584000 bbl
Relación voidage: 1.12
Máximo drop de presión: 845 psi
Tiempo de breakthrough: 1247 días
```

### **Paso 4: Entrenamiento de Modelo Sustituto**

```python
# Pipeline de ML para el caso de uso
from docs.Spanish.examples.ml_pipeline_case1 import WaterInjectionMLPipeline

# Inicializar pipeline específico
ml_pipeline = WaterInjectionMLPipeline(
    data_root='data/',
    case_name='water_injection_recovery'
)

# Preparar datos para modelos específicos
ml_pipeline.prepare_water_injection_data()

# Entrenar modelo de breakthrough prediction
breakthrough_model = ml_pipeline.train_breakthrough_model(
    epochs=150,
    validation_split=0.2
)

# Entrenar modelo de pressure decline
pressure_model = ml_pipeline.train_pressure_decline_model(
    epochs=100,
    sequence_length=50
)

# Evaluar modelos
evaluation_results = ml_pipeline.evaluate_models()

print("=== RESULTADOS DE MODELOS ML ===")
print(f"Precisión breakthrough: {evaluation_results['breakthrough']['accuracy']:.3f}")
print(f"Error presión (RMSE): {evaluation_results['pressure']['rmse']:.1f} psi")
print(f"R² score presión: {evaluation_results['pressure']['r2']:.3f}")
```

## 10.3 Caso de Uso 2: Análisis de Sensibilidad Geomecánica

### **Descripción del Escenario**

Este caso analiza el impacto de parámetros geomecánicos en la compactación del reservorio, ejecutando múltiples simulaciones con diferentes propiedades mecánicas.

#### **Configuración Paramétrica**

```python
# Script de análisis de sensibilidad
import numpy as np
import itertools
from pathlib import Path

class GeomechanicalSensitivityAnalysis:
    """Análisis de sensibilidad para parámetros geomecánicos."""
    
    def __init__(self, base_config_path='config/reservoir_config.yaml'):
        self.base_config_path = base_config_path
        self.parameter_space = self._define_parameter_space()
        self.results = {}
    
    def _define_parameter_space(self):
        """Definir espacio de parámetros para análisis."""
        return {
            'young_modulus': [800000, 1200000, 1600000, 2000000],  # psi
            'poisson_ratio': [0.15, 0.20, 0.25, 0.30, 0.35],      # -
            'biot_coefficient': [0.6, 0.7, 0.8, 0.9, 1.0],        # -
            'overburden_gradient': [0.9, 1.0, 1.1, 1.2]           # psi/ft
        }
    
    def generate_configurations(self, n_samples=50):
        """Generar configuraciones usando Latin Hypercube Sampling."""
        from scipy.stats import qmc
        
        # Parámetros y sus rangos
        params = list(self.parameter_space.keys())
        param_ranges = [self.parameter_space[p] for p in params]
        
        # Latin Hypercube Sampling
        sampler = qmc.LatinHypercube(d=len(params), seed=42)
        samples = sampler.random(n=n_samples)
        
        # Escalar a rangos de parámetros
        configurations = []
        for sample in samples:
            config = {}
            for i, param in enumerate(params):
                param_range = param_ranges[i]
                # Interpolación lineal en el rango
                value = param_range[0] + sample[i] * (param_range[-1] - param_range[0])
                config[param] = value
            configurations.append(config)
        
        return configurations
    
    def run_sensitivity_study(self, configurations):
        """Ejecutar estudio de sensibilidad."""
        
        results = []
        
        for i, config in enumerate(configurations):
            print(f"\\nEjecutando configuración {i+1}/{len(configurations)}")
            print(f"Parámetros: {config}")
            
            # Modificar archivo de configuración
            config_file = f"config/sensitivity_case_{i+1}.yaml"
            self._create_modified_config(config, config_file)
            
            # Ejecutar simulación
            simulation_results = self._run_simulation(config_file)
            
            # Calcular métricas de interés
            metrics = self._calculate_geomech_metrics(simulation_results)
            
            # Almacenar resultados
            result_entry = {
                'config_id': i+1,
                'parameters': config,
                'metrics': metrics
            }
            results.append(result_entry)
            
            print(f"Compactación máxima: {metrics['max_compaction']:.2f} ft")
            print(f"Subsidencia superficie: {metrics['surface_subsidence']:.2f} ft")
        
        return results
    
    def _create_modified_config(self, param_config, output_file):
        """Crear archivo de configuración modificado."""
        import yaml
        
        # Cargar configuración base
        with open(self.base_config_path, 'r') as f:
            base_config = yaml.safe_load(f)
        
        # Modificar parámetros geomecánicos
        if 'geomechanics' not in base_config:
            base_config['geomechanics'] = {}
        
        if 'mechanical' not in base_config['geomechanics']:
            base_config['geomechanics']['mechanical'] = {}
        
        if 'stress' not in base_config['geomechanics']:
            base_config['geomechanics']['stress'] = {}
        
        # Aplicar nuevos parámetros
        base_config['geomechanics']['mechanical']['young_modulus'] = param_config['young_modulus']
        base_config['geomechanics']['mechanical']['poisson_ratio'] = param_config['poisson_ratio']
        base_config['geomechanics']['mechanical']['biot_coefficient'] = param_config['biot_coefficient']
        base_config['geomechanics']['stress']['overburden_gradient'] = param_config['overburden_gradient']
        
        # Metadata del caso
        base_config['metadata']['case_study'] = f"sensitivity_analysis_case_{param_config}"
        
        # Guardar configuración modificada
        with open(output_file, 'w') as f:
            yaml.dump(base_config, f, default_flow_style=False, indent=2)
    
    def _run_simulation(self, config_file):
        """Ejecutar simulación MRST con configuración específica."""
        import subprocess
        import os
        
        # Cambiar al directorio de scripts
        original_dir = os.getcwd()
        os.chdir('mrst_simulation_scripts/')
        
        try:
            # Ejecutar simulación
            cmd = f'octave --eval "s99_run_workflow(\'{config_file}\')"'
            result = subprocess.run(cmd, shell=True, capture_output=True, text=True)
            
            if result.returncode != 0:
                raise Exception(f"Error en simulación: {result.stderr}")
            
            # Cargar resultados
            from dashboard.util_data_loader import MRSTDataLoader
            data_loader = MRSTDataLoader('../data/')
            dataset = data_loader.load_complete_dataset()
            
            return dataset
        
        finally:
            os.chdir(original_dir)
    
    def _calculate_geomech_metrics(self, dataset):
        """Calcular métricas geomecánicas específicas."""
        
        # Datos de presión y esfuerzo efectivo
        pressure_data = dataset['fields']['pressure']
        initial_pressure = dataset['initial']['pressure']
        
        if 'effective_stress' in dataset['fields']:
            stress_data = dataset['fields']['effective_stress']
            initial_stress = np.mean(initial_pressure)  # Aproximación
        else:
            # Calcular esfuerzo efectivo aproximado
            stress_data = pressure_data  # Simplificación
            initial_stress = np.mean(initial_pressure)
        
        # Cambio de esfuerzo efectivo
        stress_change = stress_data - initial_stress
        
        # Compactación usando relación poroelástica
        # Δh/h = -Cm * Δσ'
        if 'porosity_t' in dataset['fields']:
            porosity_change = dataset['fields']['porosity_t'] - dataset['initial']['porosity']
            max_compaction = np.max(np.abs(porosity_change)) * 100  # Convertir a ft (aproximación)
        else:
            # Estimar compactación por drop de presión
            pressure_drop = initial_pressure - pressure_data[-1]
            rock_compressibility = 3e-6  # 1/psi
            max_compaction = np.max(pressure_drop) * rock_compressibility * 238  # ft (espesor aprox.)
        
        # Subsidencia en superficie (simplificado)
        surface_subsidence = max_compaction * 0.7  # Factor de transmisión
        
        # Integridad del pozo (basado en stress change)
        max_stress_change = np.max(np.abs(stress_change))
        well_integrity_factor = max_stress_change / 1000  # Normalizado
        
        # Eficiencia de producción
        if 'cumulative' in dataset:
            recovery_factor = dataset['cumulative']['recovery_factor'][-1]
        else:
            recovery_factor = 0.15  # Valor típico
        
        return {
            'max_compaction': max_compaction,
            'surface_subsidence': surface_subsidence,
            'max_stress_change': max_stress_change,
            'well_integrity_factor': well_integrity_factor,
            'recovery_factor': recovery_factor,
            'final_pressure_drop': np.mean(initial_pressure - pressure_data[-1])
        }
    
    def analyze_sensitivities(self, results):
        """Analizar sensibilidades de parámetros."""
        import pandas as pd
        from sklearn.ensemble import RandomForestRegressor
        from sklearn.metrics import r2_score
        
        # Convertir a DataFrame
        data_rows = []
        for result in results:
            row = result['parameters'].copy()
            row.update(result['metrics'])
            data_rows.append(row)
        
        df = pd.DataFrame(data_rows)
        
        # Variables de entrada y salida
        input_vars = list(self.parameter_space.keys())
        output_vars = ['max_compaction', 'surface_subsidence', 'recovery_factor']
        
        sensitivity_results = {}
        
        for output_var in output_vars:
            print(f"\\n=== ANÁLISIS DE SENSIBILIDAD: {output_var.upper()} ===")
            
            X = df[input_vars].values
            y = df[output_var].values
            
            # Random Forest para importancia de features
            rf = RandomForestRegressor(n_estimators=100, random_state=42)
            rf.fit(X, y)
            
            # Importancia de parámetros
            importances = rf.feature_importances_
            
            # Ordenar por importancia
            importance_df = pd.DataFrame({
                'parameter': input_vars,
                'importance': importances
            }).sort_values('importance', ascending=False)
            
            print(importance_df)
            
            # R² del modelo
            y_pred = rf.predict(X)
            r2 = r2_score(y, y_pred)
            print(f"R² del modelo: {r2:.3f}")
            
            sensitivity_results[output_var] = {
                'importance_ranking': importance_df.to_dict('records'),
                'model_r2': r2,
                'correlations': df[input_vars + [output_var]].corr()[output_var].to_dict()
            }
        
        return sensitivity_results

# Ejecutar análisis de sensibilidad
if __name__ == "__main__":
    
    # Inicializar análisis
    sensitivity_analysis = GeomechanicalSensitivityAnalysis()
    
    # Generar configuraciones de prueba
    configurations = sensitivity_analysis.generate_configurations(n_samples=20)
    
    print(f"Ejecutando análisis de sensibilidad con {len(configurations)} configuraciones...")
    
    # Ejecutar estudio
    results = sensitivity_analysis.run_sensitivity_study(configurations)
    
    # Analizar sensibilidades
    sensitivity_results = sensitivity_analysis.analyze_sensitivities(results)
    
    print("\\n" + "="*60)
    print("ANÁLISIS DE SENSIBILIDAD COMPLETADO")
    print("="*60)
```

#### **Resultados Esperados del Análisis de Sensibilidad**

```
=== ANÁLISIS DE SENSIBILIDAD: MAX_COMPACTION ===
      parameter  importance
0  young_modulus    0.456
1  biot_coefficient    0.298
2  overburden_gradient    0.183
3  poisson_ratio    0.063
R² del modelo: 0.892

=== ANÁLISIS DE SENSIBILIDAD: SURFACE_SUBSIDENCE ===
      parameter  importance
0  young_modulus    0.445
1  biot_coefficient    0.312
2  overburden_gradient    0.176
3  poisson_ratio    0.067
R² del modelo: 0.875

=== ANÁLISIS DE SENSIBILIDAD: RECOVERY_FACTOR ===
      parameter  importance
0  biot_coefficient    0.387
1  young_modulus    0.234
2  poisson_ratio    0.198
3  overburden_gradient    0.181
R² del modelo: 0.654
```

## 10.4 Caso de Uso 3: Optimización de Ubicación de Pozos

### **Descripción del Escenario**

Este caso utiliza machine learning para optimizar la ubicación de pozos basándose en simulaciones de múltiples configuraciones de pozos.

#### **Algoritmo de Optimización**

```python
import numpy as np
from scipy.optimize import differential_evolution
from sklearn.gaussian_process import GaussianProcessRegressor
from sklearn.gaussian_process.kernels import Matern

class WellLocationOptimizer:
    """Optimizador de ubicación de pozos usando ML."""
    
    def __init__(self, grid_shape=(25, 25), n_producers=2, n_injectors=2):
        self.grid_shape = grid_shape
        self.n_producers = n_producers
        self.n_injectors = n_injectors
        self.simulation_results = []
        self.gp_model = None
    
    def generate_well_configurations(self, n_samples=100):
        """Generar configuraciones aleatorias de pozos."""
        
        configurations = []
        
        for _ in range(n_samples):
            config = {}
            
            # Ubicaciones de productores
            config['producers'] = []
            for i in range(self.n_producers):
                location = [
                    np.random.randint(15, self.grid_shape[0]),  # Lado derecho
                    np.random.randint(0, self.grid_shape[1])
                ]
                config['producers'].append(location)
            
            # Ubicaciones de inyectores
            config['injectors'] = []
            for i in range(self.n_injectors):
                location = [
                    np.random.randint(0, 10),  # Lado izquierdo
                    np.random.randint(0, self.grid_shape[1])
                ]
                config['injectors'].append(location)
            
            # Verificar separación mínima
            if self._validate_well_spacing(config):
                configurations.append(config)
        
        return configurations
    
    def _validate_well_spacing(self, config, min_distance=3):
        """Validar separación mínima entre pozos."""
        
        all_locations = config['producers'] + config['injectors']
        
        for i, loc1 in enumerate(all_locations):
            for j, loc2 in enumerate(all_locations[i+1:], i+1):
                distance = np.sqrt((loc1[0] - loc2[0])**2 + (loc1[1] - loc2[1])**2)
                if distance < min_distance:
                    return False
        
        return True
    
    def evaluate_well_configuration(self, config):
        """Evaluar una configuración de pozos específica."""
        
        # Crear archivo de configuración
        config_file = self._create_well_config_file(config)
        
        # Ejecutar simulación
        try:
            simulation_result = self._run_simulation(config_file)
            
            # Calcular objetivo (NPV aproximado)
            objective_value = self._calculate_objective(simulation_result)
            
            return objective_value
        
        except Exception as e:
            print(f"Error en evaluación: {e}")
            return -1e6  # Penalización por falla
    
    def _calculate_objective(self, dataset):
        """Calcular función objetivo (NPV simplificado)."""
        
        # Precios y costos
        oil_price = 70.0  # $/bbl
        water_cost = 2.0  # $/bbl
        drilling_cost = 5e6  # $ por pozo
        
        # Producción e inyección acumulada
        if 'cumulative' in dataset:
            cumulative_oil = dataset['cumulative']['cumulative_oil'][-1]
            cumulative_water_inj = dataset['cumulative']['cumulative_water_inj'][-1]
        else:
            # Estimar de datos de pozos
            well_data = dataset['wells']
            time_days = dataset['temporal']['time_days']
            
            # Integrar tasas de producción
            oil_rates = well_data.get('qOs', np.zeros_like(time_days))
            water_inj_rates = well_data.get('qWs', np.zeros_like(time_days))
            
            cumulative_oil = np.trapz(oil_rates, time_days)
            cumulative_water_inj = np.trapz(water_inj_rates, time_days)
        
        # Revenue
        oil_revenue = cumulative_oil * oil_price
        
        # Costos
        water_cost_total = cumulative_water_inj * water_cost
        drilling_cost_total = (self.n_producers + self.n_injectors) * drilling_cost
        
        # NPV simplificado (sin descuento temporal)
        npv = oil_revenue - water_cost_total - drilling_cost_total
        
        return npv
    
    def build_surrogate_model(self, configurations, objectives):
        """Construir modelo sustituto con Gaussian Process."""
        
        # Convertir configuraciones a features numéricas
        X = self._configs_to_features(configurations)
        y = np.array(objectives)
        
        # Gaussian Process con kernel Matern
        kernel = Matern(length_scale=1.0, nu=1.5)
        self.gp_model = GaussianProcessRegressor(
            kernel=kernel,
            alpha=1e-6,
            normalize_y=True,
            n_restarts_optimizer=10,
            random_state=42
        )
        
        # Entrenar modelo
        self.gp_model.fit(X, y)
        
        print(f"Modelo sustituto entrenado con {len(configurations)} configuraciones")
        print(f"Log-likelihood marginal: {self.gp_model.log_marginal_likelihood():.2f}")
        
        return self.gp_model
    
    def _configs_to_features(self, configurations):
        """Convertir configuraciones de pozos a features numéricas."""
        
        features = []
        
        for config in configurations:
            feature_vector = []
            
            # Features de productores
            for prod in config['producers']:
                feature_vector.extend(prod)
            
            # Features de inyectores
            for inj in config['injectors']:
                feature_vector.extend(inj)
            
            # Features adicionales: distancias promedio
            all_locs = config['producers'] + config['injectors']
            distances = []
            for i, loc1 in enumerate(all_locs):
                for loc2 in all_locs[i+1:]:
                    dist = np.sqrt((loc1[0] - loc2[0])**2 + (loc1[1] - loc2[1])**2)
                    distances.append(dist)
            
            feature_vector.append(np.mean(distances))  # Distancia promedio
            feature_vector.append(np.std(distances))   # Dispersión de distancias
            
            features.append(feature_vector)
        
        return np.array(features)
    
    def optimize_well_locations(self):
        """Optimizar ubicaciones usando modelo sustituto."""
        
        def objective_function(x):
            """Función objetivo para optimización."""
            
            # Convertir vector de optimización a configuración
            config = self._vector_to_config(x)
            
            # Validar configuración
            if not self._validate_well_spacing(config):
                return 1e6  # Penalización
            
            # Predecir NPV con modelo sustituto
            features = self._configs_to_features([config])
            npv_pred, npv_std = self.gp_model.predict(features, return_std=True)
            
            # Maximizar NPV (minimizar -NPV)
            return -npv_pred[0]
        
        # Bounds para optimización
        bounds = []
        
        # Bounds para productores (lado derecho)
        for _ in range(self.n_producers):
            bounds.append((15, self.grid_shape[0]-1))  # x
            bounds.append((0, self.grid_shape[1]-1))   # y
        
        # Bounds para inyectores (lado izquierdo)
        for _ in range(self.n_injectors):
            bounds.append((0, 9))                      # x
            bounds.append((0, self.grid_shape[1]-1))   # y
        
        # Optimización con Differential Evolution
        result = differential_evolution(
            objective_function,
            bounds,
            seed=42,
            maxiter=100,
            popsize=15
        )
        
        # Convertir solución óptima
        optimal_config = self._vector_to_config(result.x)
        optimal_npv = -result.fun
        
        return optimal_config, optimal_npv
    
    def _vector_to_config(self, x):
        """Convertir vector de optimización a configuración."""
        
        config = {'producers': [], 'injectors': []}
        idx = 0
        
        # Productores
        for _ in range(self.n_producers):
            config['producers'].append([int(x[idx]), int(x[idx+1])])
            idx += 2
        
        # Inyectores
        for _ in range(self.n_injectors):
            config['injectors'].append([int(x[idx]), int(x[idx+1])])
            idx += 2
        
        return config

# Ejecutar optimización
if __name__ == "__main__":
    
    # Inicializar optimizador
    optimizer = WellLocationOptimizer(grid_shape=(25, 25), n_producers=2, n_injectors=2)
    
    print("Generando configuraciones iniciales...")
    configurations = optimizer.generate_well_configurations(n_samples=50)
    
    print("Evaluando configuraciones con simulaciones MRST...")
    objectives = []
    for i, config in enumerate(configurations):
        print(f"Evaluando configuración {i+1}/{len(configurations)}")
        objective = optimizer.evaluate_well_configuration(config)
        objectives.append(objective)
    
    print("Construyendo modelo sustituto...")
    gp_model = optimizer.build_surrogate_model(configurations, objectives)
    
    print("Optimizando ubicaciones de pozos...")
    optimal_config, optimal_npv = optimizer.optimize_well_locations()
    
    print("\\n" + "="*50)
    print("OPTIMIZACIÓN DE POZOS COMPLETADA")
    print("="*50)
    print(f"Configuración óptima:")
    print(f"  Productores: {optimal_config['producers']}")
    print(f"  Inyectores: {optimal_config['injectors']}")
    print(f"NPV estimado: ${optimal_npv/1e6:.1f} MM")
    
    # Validar con simulación completa
    print("\\nValidando con simulación completa...")
    final_npv = optimizer.evaluate_well_configuration(optimal_config)
    print(f"NPV validado: ${final_npv/1e6:.1f} MM")
```

## 10.5 Mejores Prácticas de Casos de Uso

### **Planificación de Casos**

1. **Definición Clara de Objetivos**
   - Especificar métricas de éxito cuantificables
   - Establecer restricciones físicas y operacionales
   - Definir horizonte temporal apropiado

2. **Configuración de Simulación**
   - Usar resolución de grid apropiada para el problema
   - Configurar timesteps según la dinámica del proceso
   - Validar propiedades de roca y fluidos

3. **Análisis de Resultados**
   - Implementar checks de balance de masa
   - Validar comportamiento físico
   - Comparar con casos de referencia o datos históricos

### **Implementación de ML**

1. **Preparación de Datos**
   - Asegurar diversidad en el dataset de entrenamiento
   - Implementar validación cruzada temporal
   - Considerar física del problema en normalización

2. **Selección de Modelos**
   - CNN para problemas espaciales
   - LSTM/GRU para evolución temporal
   - Gaussian Process para optimización con pocos datos
   - Physics-informed NN para conservación de leyes físicas

3. **Validación y Deployment**
   - Validar en casos no vistos durante entrenamiento
   - Implementar monitoreo de performance en producción
   - Mantener capacidad de fallback a simulación completa

### **Documentación y Reproducibilidad**

1. **Versionado de Configuraciones**
   - Usar control de versiones para archivos de configuración
   - Documentar cambios y justificaciones
   - Mantener configuraciones de casos de referencia

2. **Logging y Monitoreo**
   - Registrar métricas de performance de simulación
   - Monitorear convergencia y estabilidad
   - Implementar alertas para comportamientos anómalos

3. **Transferencia de Conocimiento**
   - Documentar lecciones aprendidas
   - Crear plantillas reutilizables
   - Establecer workflows estándar

**Fuente**: `mrst_simulation_scripts/`, `dashboard/util_data_loader.py`, `dashboard/util_metrics.py`

---

*Continúa en [Capítulo 11: Troubleshooting y FAQ](11_troubleshooting_faq.md)*