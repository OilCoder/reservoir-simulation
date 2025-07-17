# Capítulo 11: Troubleshooting y FAQ

## 11.1 Introducción

Este capítulo proporciona soluciones a problemas comunes, preguntas frecuentes y guías de optimización para el sistema GeomechML. Incluye diagnósticos paso a paso y procedimientos de resolución de problemas.

### **Estructura del Capítulo**
- ✅ Problemas de instalación y configuración
- ✅ Errores de simulación MRST
- ✅ Issues de calidad de datos
- ✅ Problemas de modelos ML
- ✅ Optimización de rendimiento
- ✅ Preguntas frecuentes

## 11.2 Problemas de Instalación y Configuración

### **Error: MRST no encontrado**

#### **Síntomas**
```bash
Error: MRST core modules not found
Check that MRST is properly installed and accessible
```

#### **Diagnóstico**
```octave
% Verificar paths de MRST
which cartGrid
which makeRock
which initSimpleFluid

% Verificar variable de entorno
getenv('MRST_ROOT')
```

#### **Soluciones**

**Solución 1: Verificar instalación de MRST**
```bash
# Descargar MRST si no está instalado
cd ~/
wget https://www.sintef.no/projectweb/mrst/download/mrst-2023a.zip
unzip mrst-2023a.zip
mv mrst-2023a mrst

# Verificar estructura
ls mrst/
# Debe mostrar: core/, modules/, utils/, etc.
```

**Solución 2: Configurar load_mrst.m**
```octave
% Editar load_mrst.m en directorio raíz del proyecto
function load_mrst()
    % Definir path de MRST
    mrst_root = '~/mrst';  % Ajustar según instalación
    
    % Agregar paths críticos
    addpath(genpath(fullfile(mrst_root, 'core')));
    addpath(genpath(fullfile(mrst_root, 'modules')));
    addpath(genpath(fullfile(mrst_root, 'utils')));
    
    % Verificar funciones clave
    assert(exist('cartGrid', 'file') == 2, 'cartGrid no encontrado');
    assert(exist('makeRock', 'file') == 2, 'makeRock no encontrado');
    
    fprintf('MRST cargado exitosamente\\n');
end
```

**Solución 3: Configurar variable de entorno**
```bash
# Agregar a ~/.bashrc o ~/.profile
export MRST_ROOT=~/mrst
export OCTAVE_PATH=$MRST_ROOT/core:$MRST_ROOT/modules:$MRST_ROOT/utils
```

### **Error: util_read_config no encontrado**

#### **Síntomas**
```
Error: 'util_read_config' undefined near line 20 column 10
```

#### **Solución**
```bash
# Verificar que util_read_config.m existe
ls mrst_simulation_scripts/util_read_config.m

# Si no existe, crear el archivo
cp docs/Spanish/examples/util_read_config.m mrst_simulation_scripts/

# Verificar permisos
chmod 644 mrst_simulation_scripts/util_read_config.m
```

### **Error: Archivo de configuración no válido**

#### **Síntomas**
```
Error: Configuration file parsing failed
YAML syntax error at line 45
```

#### **Diagnóstico y Solución**
```python
# Script de validación YAML
import yaml
import sys

def validate_yaml_config(config_file):
    """Validar sintaxis YAML y estructura."""
    
    try:
        with open(config_file, 'r') as f:
            config = yaml.safe_load(f)
        
        print("✅ Sintaxis YAML válida")
        
        # Verificar secciones requeridas
        required_sections = ['grid', 'rock', 'fluid', 'wells', 'simulation']
        missing_sections = []
        
        for section in required_sections:
            if section not in config:
                missing_sections.append(section)
        
        if missing_sections:
            print(f"❌ Secciones faltantes: {missing_sections}")
            return False
        
        print("✅ Estructura de configuración válida")
        return True
        
    except yaml.YAMLError as e:
        print(f"❌ Error de sintaxis YAML: {e}")
        return False
    except FileNotFoundError:
        print(f"❌ Archivo no encontrado: {config_file}")
        return False

# Usar validador
if __name__ == "__main__":
    config_file = sys.argv[1] if len(sys.argv) > 1 else 'config/reservoir_config.yaml'
    validate_yaml_config(config_file)
```

## 11.3 Errores de Simulación MRST

### **Error: Simulación no converge**

#### **Síntomas**
```
Warning: Maximum iterations reached without convergence
Final residual: 1.2345e-02 (tolerance: 1.0000e-06)
Simulation stopped at timestep 45
```

#### **Diagnóstico**

**Script de diagnóstico de convergencia:**
```octave
function diagnose_convergence_issues(G, rock, fluid, schedule, state0)
    % Diagnosticar problemas de convergencia en simulación
    
    fprintf('=== DIAGNÓSTICO DE CONVERGENCIA ===\\n');
    
    % 1. Verificar grid
    fprintf('Grid: %d x %d x %d = %d celdas\\n', G.cartDims, G.cells.num);
    
    % Verificar aspect ratio
    dx = max(G.cells.centroids(:,1)) - min(G.cells.centroids(:,1));
    dy = max(G.cells.centroids(:,2)) - min(G.cells.centroids(:,2));
    aspect_ratio = max(dx, dy) / min(dx, dy);
    
    if aspect_ratio > 10
        fprintf('⚠️  Warning: Aspect ratio alto (%.1f) puede causar problemas\\n', aspect_ratio);
    end
    
    % 2. Verificar propiedades de roca
    poro_range = [min(rock.poro), max(rock.poro)];
    perm_range = [min(rock.perm), max(rock.perm)];
    
    fprintf('Porosidad: [%.3f, %.3f]\\n', poro_range);
    fprintf('Permeabilidad: [%.2e, %.2e] mD\\n', perm_range);
    
    if perm_range(2) / perm_range(1) > 1e6
        fprintf('⚠️  Warning: Contraste de permeabilidad muy alto\\n');
    end
    
    % 3. Verificar estado inicial
    pressure_range = [min(state0.pressure), max(state0.pressure)];
    sat_range = [min(state0.s(:,1)), max(state0.s(:,1))];
    
    fprintf('Presión inicial: [%.1f, %.1f] psi\\n', pressure_range);
    fprintf('Saturación agua: [%.3f, %.3f]\\n', sat_range);
    
    if any(state0.s(:,1) < 0) || any(state0.s(:,1) > 1)
        fprintf('❌ Error: Saturaciones fuera de rango [0,1]\\n');
    end
    
    % 4. Verificar pozos
    fprintf('\\nPozos configurados: %d\\n', numel(schedule.control(1).W));
    
    for i = 1:numel(schedule.control(1).W)
        well = schedule.control(1).W(i);
        fprintf('  %s: Tipo=%s, Control=%.1f\\n', well.name, well.type, well.val);
        
        % Verificar ubicación del pozo
        well_cell = well.cells(1);
        well_perm = rock.perm(well_cell);
        
        if well_perm < 1  % mD
            fprintf('    ⚠️  Warning: Baja permeabilidad en pozo %s (%.2f mD)\\n', ...
                    well.name, well_perm);
        end
    end
    
    % 5. Verificar timesteps
    dt = schedule.step.val;
    fprintf('\\nTimesteps: %d pasos, rango [%.2f, %.2f] días\\n', ...
            numel(dt), min(dt), max(dt));
    
    if max(dt) / min(dt) > 100
        fprintf('⚠️  Warning: Timesteps muy variables\\n');
    end
    
    fprintf('\\n=== FIN DIAGNÓSTICO ===\\n');
end
```

#### **Soluciones**

**Solución 1: Ajustar tolerancia y iteraciones**
```yaml
# En reservoir_config.yaml
simulation:
  solver:
    tolerance: 1.0e-5          # Relajar tolerancia
    max_iterations: 50         # Aumentar iteraciones máximas
    linear_solver: "direct"    # Cambiar a solver directo
```

**Solución 2: Reducir timesteps**
```yaml
simulation:
  total_time: 3650.0
  num_timesteps: 1000         # Aumentar número de timesteps
  timestep_type: "logarithmic" # Usar timesteps crecientes
  timestep_multiplier: 1.05   # Factor más conservador
```

**Solución 3: Suavizar propiedades**
```octave
% Suavizar permeabilidad extrema
rock.perm = max(rock.perm, 0.1);  % Mínimo 0.1 mD
rock.perm = min(rock.perm, 1000); % Máximo 1000 mD

% Aplicar filtro Gaussiano
rock.perm = imgaussfilt(reshape(rock.perm, G.cartDims), 1);
rock.perm = rock.perm(:);
```

### **Error: Balance de masa incorrecto**

#### **Síntomas**
```
Warning: Mass balance error exceeds tolerance
Total fluid volume change: 5.23% (tolerance: 1.0%)
```

#### **Diagnóstico y Solución**
```octave
function check_mass_balance(G, rock, states, schedule)
    % Verificar balance de masa en simulación
    
    fprintf('=== VERIFICACIÓN DE BALANCE DE MASA ===\\n');
    
    % Volumen poroso total
    pore_volume = sum(G.cells.volumes .* rock.poro);
    fprintf('Volumen poroso total: %.2e bbl\\n', pore_volume / 5.615);  % ft³ a bbl
    
    % Balance por timestep
    mass_errors = [];
    
    for t = 1:numel(states)
        state = states{t};
        
        % Volumen de fluidos in-situ
        oil_volume = sum(G.cells.volumes .* rock.poro .* (1 - state.s(:,1)));
        water_volume = sum(G.cells.volumes .* rock.poro .* state.s(:,1));
        total_volume = oil_volume + water_volume;
        
        % Error de balance
        mass_error = abs(total_volume - pore_volume) / pore_volume;
        mass_errors(t) = mass_error;
        
        if mass_error > 0.01  % 1%
            fprintf('⚠️  Timestep %d: Error de masa %.3f%%\\n', t, mass_error*100);
        end
    end
    
    % Estadísticas finales
    fprintf('\\nError de masa promedio: %.4f%%\\n', mean(mass_errors)*100);
    fprintf('Error de masa máximo: %.4f%%\\n', max(mass_errors)*100);
    
    if max(mass_errors) > 0.05
        fprintf('❌ Balance de masa inaceptable - revisar configuración\\n');
    else
        fprintf('✅ Balance de masa aceptable\\n');
    end
end
```

## 11.4 Issues de Calidad de Datos

### **Problema: Datos de simulación corruptos**

#### **Síntomas**
```python
ValueError: Invalid data in pressure field
NaN values detected in timestep 234
Array shapes inconsistent: expected (500, 20, 20), got (500, 20, 19)
```

#### **Script de Validación de Datos**
```python
import numpy as np
import scipy.io as sio
from pathlib import Path

class DataQualityChecker:
    """Verificador de calidad de datos de simulación."""
    
    def __init__(self, data_root='data/'):
        self.data_root = Path(data_root)
        self.issues = []
    
    def check_all_data(self):
        """Verificar todos los archivos de datos."""
        
        print("=== VERIFICACIÓN DE CALIDAD DE DATOS ===")
        
        # Verificar archivos principales
        self._check_file_existence()
        self._check_initial_conditions()
        self._check_static_data()
        self._check_dynamic_fields()
        self._check_well_data()
        self._check_metadata()
        
        # Reporte final
        self._generate_report()
    
    def _check_file_existence(self):
        """Verificar existencia de archivos."""
        
        required_files = [
            'initial/initial_conditions.mat',
            'static/static_data.mat',
            'dynamic/fields/field_arrays.mat',
            'dynamic/wells/well_data.mat',
            'metadata/dataset_metadata.mat'
        ]
        
        missing_files = []
        for file_path in required_files:
            full_path = self.data_root / file_path
            if not full_path.exists():
                missing_files.append(file_path)
        
        if missing_files:
            self.issues.append(f"Archivos faltantes: {missing_files}")
        else:
            print("✅ Todos los archivos requeridos existen")
    
    def _check_initial_conditions(self):
        """Verificar condiciones iniciales."""
        
        try:
            file_path = self.data_root / 'initial/initial_conditions.mat'
            data = sio.loadmat(file_path)
            
            # Verificar variables requeridas
            required_vars = ['pressure', 'sw', 'porosity', 'permeability']
            for var in required_vars:
                if var not in data:
                    self.issues.append(f"Variable faltante en initial_conditions: {var}")
                    continue
                
                field = data[var]
                
                # Verificar NaN/Inf
                if np.any(np.isnan(field)) or np.any(np.isinf(field)):
                    self.issues.append(f"Valores NaN/Inf en {var}")
                
                # Verificar rangos físicos
                if var == 'pressure' and (np.any(field <= 0) or np.any(field > 10000)):
                    self.issues.append(f"Presión fuera de rango físico: [{np.min(field):.1f}, {np.max(field):.1f}]")
                
                elif var == 'sw' and (np.any(field < 0) or np.any(field > 1)):
                    self.issues.append(f"Saturación fuera de rango [0,1]: [{np.min(field):.3f}, {np.max(field):.3f}]")
                
                elif var == 'porosity' and (np.any(field <= 0) or np.any(field > 0.5)):
                    self.issues.append(f"Porosidad fuera de rango físico: [{np.min(field):.3f}, {np.max(field):.3f}]")
                
                elif var == 'permeability' and (np.any(field <= 0) or np.any(field > 10000)):
                    self.issues.append(f"Permeabilidad fuera de rango físico: [{np.min(field):.3f}, {np.max(field):.3f}]")
            
            print("✅ Condiciones iniciales verificadas")
            
        except Exception as e:
            self.issues.append(f"Error leyendo initial_conditions: {e}")
    
    def _check_dynamic_fields(self):
        """Verificar campos dinámicos."""
        
        try:
            file_path = self.data_root / 'dynamic/fields/field_arrays.mat'
            data = sio.loadmat(file_path)
            
            # Verificar variables temporales
            temporal_vars = ['pressure', 'sw']
            expected_shape = None
            
            for var in temporal_vars:
                if var not in data:
                    self.issues.append(f"Variable temporal faltante: {var}")
                    continue
                
                field = data[var]
                
                # Verificar forma consistente
                if expected_shape is None:
                    expected_shape = field.shape
                elif field.shape != expected_shape:
                    self.issues.append(f"Forma inconsistente en {var}: {field.shape} vs {expected_shape}")
                
                # Verificar evolución temporal física
                if var == 'pressure':
                    # Presión debe declinar generalmente
                    initial_avg = np.mean(field[0])
                    final_avg = np.mean(field[-1])
                    if final_avg > initial_avg * 1.1:  # Tolerancia 10%
                        self.issues.append(f"Presión promedio aumenta anómalamente: {initial_avg:.1f} → {final_avg:.1f}")
                
                elif var == 'sw':
                    # Saturación de agua debe aumentar cerca de inyectores
                    sat_increase = np.mean(field[-1]) - np.mean(field[0])
                    if sat_increase < 0:
                        self.issues.append(f"Saturación de agua disminuye globalmente: {sat_increase:.3f}")
            
            print("✅ Campos dinámicos verificados")
            
        except Exception as e:
            self.issues.append(f"Error leyendo field_arrays: {e}")
    
    def _check_well_data(self):
        """Verificar datos de pozos."""
        
        try:
            file_path = self.data_root / 'dynamic/wells/well_data.mat'
            data = sio.loadmat(file_path)
            
            # Verificar tasas de producción/inyección
            if 'qOs' in data:  # Oil production rates
                oil_rates = data['qOs']
                if np.any(oil_rates < 0):
                    self.issues.append("Tasas de producción de petróleo negativas detectadas")
            
            if 'qWs' in data:  # Water injection rates
                water_rates = data['qWs']
                # Para inyectores, tasas deben ser positivas
                # Para productores, tasas deben ser negativas o cero
                # Verificar que hay inyección neta
                total_injection = np.sum(water_rates[water_rates > 0])
                if total_injection == 0:
                    self.issues.append("No se detecta inyección de agua")
            
            print("✅ Datos de pozos verificados")
            
        except Exception as e:
            self.issues.append(f"Error leyendo well_data: {e}")
    
    def _check_metadata(self):
        """Verificar metadata."""
        
        try:
            file_path = self.data_root / 'metadata/dataset_metadata.mat'
            data = sio.loadmat(file_path)
            
            # Verificar información básica
            required_metadata = ['grid_size', 'num_timesteps', 'simulation_time']
            for item in required_metadata:
                if item not in data:
                    self.issues.append(f"Metadata faltante: {item}")
            
            print("✅ Metadata verificada")
            
        except Exception as e:
            self.issues.append(f"Error leyendo metadata: {e}")
    
    def _generate_report(self):
        """Generar reporte final."""
        
        print("\\n" + "="*50)
        print("REPORTE DE CALIDAD DE DATOS")
        print("="*50)
        
        if not self.issues:
            print("✅ Todos los checks de calidad pasaron exitosamente")
        else:
            print(f"❌ Se encontraron {len(self.issues)} issues:")
            for i, issue in enumerate(self.issues, 1):
                print(f"  {i}. {issue}")
        
        print("="*50)
    
    def fix_common_issues(self):
        """Corregir issues comunes automáticamente."""
        
        print("\\n=== CORRECCIÓN AUTOMÁTICA ===")
        
        # Corregir saturaciones fuera de rango
        try:
            file_path = self.data_root / 'dynamic/fields/field_arrays.mat'
            data = sio.loadmat(file_path)
            
            if 'sw' in data:
                sw = data['sw']
                original_range = [np.min(sw), np.max(sw)]
                
                # Clipear a rango válido
                sw_fixed = np.clip(sw, 0.0, 1.0)
                
                if not np.array_equal(sw, sw_fixed):
                    data['sw'] = sw_fixed
                    sio.savemat(file_path, data)
                    print(f"✅ Saturaciones corregidas: {original_range} → [0.0, 1.0]")
            
        except Exception as e:
            print(f"❌ Error en corrección automática: {e}")

# Usar verificador
if __name__ == "__main__":
    checker = DataQualityChecker('data/')
    checker.check_all_data()
    
    # Corregir issues si es necesario
    if checker.issues:
        print("\\n¿Intentar corrección automática? (y/n)")
        if input().lower() == 'y':
            checker.fix_common_issues()
```

## 11.5 Problemas de Modelos ML

### **Problema: Modelo no aprende (loss no disminuye)**

#### **Síntomas**
```
Epoch 1/100 - loss: 0.8457 - val_loss: 0.8461
Epoch 50/100 - loss: 0.8455 - val_loss: 0.8459
Epoch 100/100 - loss: 0.8454 - val_loss: 0.8458
```

#### **Diagnóstico y Soluciones**

**Script de diagnóstico ML:**
```python
import numpy as np
import matplotlib.pyplot as plt
from sklearn.preprocessing import StandardScaler

def diagnose_ml_training_issues(X_train, y_train, X_val, y_val):
    """Diagnosticar problemas de entrenamiento ML."""
    
    print("=== DIAGNÓSTICO DE ENTRENAMIENTO ML ===")
    
    # 1. Verificar datos de entrada
    print(f"Forma de datos de entrenamiento: X={X_train.shape}, y={y_train.shape}")
    print(f"Forma de datos de validación: X={X_val.shape}, y={y_val.shape}")
    
    # 2. Verificar distribuciones
    print("\\nEstadísticas de entrada:")
    print(f"  X - Media: {np.mean(X_train):.4f}, Std: {np.std(X_train):.4f}")
    print(f"  X - Rango: [{np.min(X_train):.4f}, {np.max(X_train):.4f}]")
    
    print("\\nEstadísticas de salida:")
    print(f"  y - Media: {np.mean(y_train):.4f}, Std: {np.std(y_train):.4f}")
    print(f"  y - Rango: [{np.min(y_train):.4f}, {np.max(y_train):.4f}]")
    
    # 3. Verificar escalamiento
    if np.std(X_train) > 10 or np.mean(X_train) > 100:
        print("⚠️  Warning: Datos de entrada no normalizados")
        
        # Sugerir normalización
        scaler = StandardScaler()
        X_normalized = scaler.fit_transform(X_train.reshape(-1, 1))
        print(f"  Después de normalización: Media={np.mean(X_normalized):.4f}, Std={np.std(X_normalized):.4f}")
    
    # 4. Verificar variabilidad en targets
    y_std = np.std(y_train)
    y_range = np.max(y_train) - np.min(y_train)
    
    if y_std < 1e-6:
        print("❌ Error: Targets sin variabilidad (todos iguales)")
    elif y_range / np.mean(y_train) < 0.01:
        print("⚠️  Warning: Targets con poca variabilidad")
    
    # 5. Verificar balance de dataset
    if len(X_train) < 100:
        print("⚠️  Warning: Dataset muy pequeño para ML")
    
    if len(X_val) / len(X_train) < 0.1:
        print("⚠️  Warning: Conjunto de validación muy pequeño")
    
    # 6. Detectar outliers
    Q1 = np.percentile(y_train, 25)
    Q3 = np.percentile(y_train, 75)
    IQR = Q3 - Q1
    outlier_threshold = 1.5 * IQR
    
    outliers = np.sum((y_train < Q1 - outlier_threshold) | (y_train > Q3 + outlier_threshold))
    outlier_fraction = outliers / len(y_train)
    
    if outlier_fraction > 0.05:
        print(f"⚠️  Warning: {outlier_fraction:.1%} de outliers en targets")
    
    print("\\n=== RECOMENDACIONES ===")
    
    # Recomendaciones específicas
    if np.std(X_train) > 10:
        print("1. Normalizar datos de entrada")
    
    if y_std > 1000:
        print("2. Normalizar targets o usar log transform")
    
    if len(X_train) < 1000:
        print("3. Considerar data augmentation o transfer learning")
    
    if outlier_fraction > 0.05:
        print("4. Filtrar outliers o usar loss functions robustos")

# Soluciones específicas
def fix_normalization_issues(X_train, y_train, X_val, y_val):
    """Corregir problemas de normalización."""
    
    # Normalizar features
    scaler_X = StandardScaler()
    X_train_norm = scaler_X.fit_transform(X_train.reshape(X_train.shape[0], -1))
    X_val_norm = scaler_X.transform(X_val.reshape(X_val.shape[0], -1))
    
    # Normalizar targets si es necesario
    if np.std(y_train) > 1000:
        scaler_y = StandardScaler()
        y_train_norm = scaler_y.fit_transform(y_train.reshape(-1, 1)).flatten()
        y_val_norm = scaler_y.transform(y_val.reshape(-1, 1)).flatten()
    else:
        scaler_y = None
        y_train_norm = y_train
        y_val_norm = y_val
    
    # Reshape back to original dimensions
    X_train_norm = X_train_norm.reshape(X_train.shape)
    X_val_norm = X_val_norm.reshape(X_val.shape)
    
    return X_train_norm, y_train_norm, X_val_norm, y_val_norm, scaler_X, scaler_y

def adjust_learning_rate_schedule(model):
    """Ajustar learning rate schedule."""
    
    import tensorflow as tf
    
    # Learning rate schedule con warm-up y decay
    initial_lr = 1e-3
    
    def lr_schedule(epoch):
        if epoch < 10:
            return initial_lr * (epoch + 1) / 10  # Warm-up
        else:
            return initial_lr * 0.95 ** (epoch - 10)  # Exponential decay
    
    lr_callback = tf.keras.callbacks.LearningRateScheduler(lr_schedule)
    
    return lr_callback
```

### **Problema: Overfitting severo**

#### **Síntomas**
```
Epoch 100/100
loss: 0.0045 - val_loss: 0.8234
Training accuracy: 0.99 - Validation accuracy: 0.62
```

#### **Soluciones Anti-Overfitting**

```python
def create_regularized_model(input_shape, n_outputs):
    """Crear modelo con regularización anti-overfitting."""
    
    import tensorflow as tf
    from tensorflow.keras import layers, Model
    
    inputs = layers.Input(shape=input_shape)
    
    # Red con dropout y batch normalization
    x = layers.Dense(128, activation='relu')(inputs)
    x = layers.BatchNormalization()(x)
    x = layers.Dropout(0.3)(x)
    
    x = layers.Dense(64, activation='relu')(x)
    x = layers.BatchNormalization()(x)
    x = layers.Dropout(0.4)(x)
    
    x = layers.Dense(32, activation='relu')(x)
    x = layers.Dropout(0.3)(x)
    
    # Capa de salida sin regularización
    outputs = layers.Dense(n_outputs, activation='linear')(x)
    
    model = Model(inputs=inputs, outputs=outputs)
    
    # Compilar con regularización L2 en el optimizador
    optimizer = tf.keras.optimizers.Adam(
        learning_rate=1e-3,
        weight_decay=1e-4  # L2 regularization
    )
    
    model.compile(
        optimizer=optimizer,
        loss='mse',
        metrics=['mae']
    )
    
    return model

def get_anti_overfitting_callbacks():
    """Callbacks para prevenir overfitting."""
    
    import tensorflow as tf
    
    callbacks = [
        # Early stopping agresivo
        tf.keras.callbacks.EarlyStopping(
            monitor='val_loss',
            patience=15,
            restore_best_weights=True,
            min_delta=1e-4
        ),
        
        # Reducir learning rate cuando se estanque
        tf.keras.callbacks.ReduceLROnPlateau(
            monitor='val_loss',
            factor=0.5,
            patience=8,
            min_lr=1e-7,
            verbose=1
        ),
        
        # Model checkpoint
        tf.keras.callbacks.ModelCheckpoint(
            'best_model.h5',
            monitor='val_loss',
            save_best_only=True,
            save_weights_only=False
        )
    ]
    
    return callbacks
```

## 11.6 Optimización de Rendimiento

### **Problema: Simulación muy lenta**

#### **Diagnóstico de Performance**

```octave
function profile_simulation_performance()
    % Perfilar rendimiento de simulación MRST
    
    fprintf('=== PERFIL DE RENDIMIENTO ===\\n');
    
    % Iniciar profiler
    profile on
    
    % Ejecutar workflow
    tic;
    s99_run_workflow();
    total_time = toc;
    
    % Detener profiler y analizar
    profile off
    prof_info = profile('info');
    
    % Mostrar funciones más costosas
    fprintf('\\nTiempo total de simulación: %.2f minutos\\n', total_time/60);
    
    % Top 10 funciones más costosas
    [~, idx] = sort([prof_info.FunctionTable.TotalTime], 'descend');
    top_functions = prof_info.FunctionTable(idx(1:min(10, end)));
    
    fprintf('\\nTop 10 funciones más costosas:\\n');
    for i = 1:length(top_functions)
        func = top_functions(i);
        fprintf('%d. %s: %.2f seg (%.1f%%)\\n', i, func.FunctionName, ...
                func.TotalTime, 100*func.TotalTime/total_time);
    end
    
    % Recomendaciones de optimización
    fprintf('\\n=== RECOMENDACIONES DE OPTIMIZACIÓN ===\\n');
    
    if total_time > 600  % > 10 minutos
        fprintf('⚠️  Simulación lenta detectada\\n');
        fprintf('1. Considerar reducir resolución de grid\\n');
        fprintf('2. Aumentar tolerancia del solver\\n');
        fprintf('3. Usar timesteps más grandes\\n');
    end
    
    % Verificar si linear solver es el cuello de botella
    solver_functions = {'mldivide', 'linsolve', 'gmres'};
    solver_time = 0;
    
    for i = 1:length(prof_info.FunctionTable)
        func_name = prof_info.FunctionTable(i).FunctionName;
        if any(contains(func_name, solver_functions))
            solver_time = solver_time + prof_info.FunctionTable(i).TotalTime;
        end
    end
    
    if solver_time / total_time > 0.5
        fprintf('4. Linear solver consume >50%% del tiempo - considerar solver iterativo\\n');
    end
end
```

#### **Optimizaciones de Configuración**

```yaml
# Configuración optimizada para velocidad
simulation:
  # Menos timesteps para pruebas rápidas
  num_timesteps: 100          # En lugar de 500
  
  solver:
    tolerance: 1.0e-5         # Tolerancia más relajada
    max_iterations: 20        # Menos iteraciones máximas
    linear_solver: "iterative" # Solver iterativo más rápido

# Grid más pequeño para pruebas
grid:
  nx: 15                      # En lugar de 20
  ny: 15
  nz: 5                       # En lugar de 10

# Propiedades menos complejas
porosity:
  correlation_length: 1000    # Menos heterogeneidad
  random_amplitude_factor: 0.3

permeability:
  correlation_length: 1500
  porosity_correlation: 0.9  # Fuerte correlación = menos complejidad
```

### **Problema: Dashboard lento**

#### **Optimización del Dashboard**

```python
# Optimizaciones para el dashboard Streamlit

import streamlit as st
import numpy as np

# Cache para carga de datos
@st.cache_data
def load_simulation_data_cached():
    """Cargar datos con cache para evitar recargas."""
    from dashboard.util_data_loader import MRSTDataLoader
    
    data_loader = MRSTDataLoader('data/')
    return data_loader.load_complete_dataset()

# Sampling de datos para visualización
def downsample_for_visualization(data, max_points=1000):
    """Reducir datos para visualización más rápida."""
    
    if len(data) <= max_points:
        return data
    
    # Muestreo uniforme
    indices = np.linspace(0, len(data)-1, max_points, dtype=int)
    return data[indices]

# Lazy loading de plots
@st.cache_data
def create_expensive_plot(data_hash, plot_type):
    """Crear plots costosos con cache."""
    
    # Solo crear plot si no existe en cache
    if plot_type == 'pressure_evolution':
        # ... crear plot de evolución de presión
        pass
    elif plot_type == 'saturation_animation':
        # ... crear animación de saturación
        pass
    
    return plot

# Configuración de performance para Streamlit
def configure_streamlit_performance():
    """Configurar Streamlit para mejor performance."""
    
    # Configuración en .streamlit/config.toml
    config_content = '''
    [server]
    maxUploadSize = 200
    maxMessageSize = 200
    
    [browser]
    gatherUsageStats = false
    
    [global]
    developmentMode = false
    '''
    
    # Crear directorio y archivo de configuración
    import os
    os.makedirs('.streamlit', exist_ok=True)
    
    with open('.streamlit/config.toml', 'w') as f:
        f.write(config_content)
```

## 11.7 Preguntas Frecuentes (FAQ)

### **Q: ¿Cómo cambiar la resolución del grid sin afectar los resultados?**

**A:** Para cambiar la resolución del grid manteniendo la física:

```yaml
# Grid original: 20x20x10
grid:
  nx: 20
  ny: 20  
  nz: 10
  dx: 164.0
  dy: 164.0

# Grid de alta resolución: 30x30x15  
grid:
  nx: 30
  ny: 30
  nz: 15
  dx: 109.3  # 164.0 * (20/30) para mantener área total
  dy: 109.3
  
# Grid de baja resolución: 15x15x8
grid:
  nx: 15
  ny: 15
  nz: 8
  dx: 218.7  # 164.0 * (20/15)
  dy: 218.7
```

**Consideraciones importantes:**
- Mantener área total constante ajustando dx/dy
- Reducir resolución puede afectar captura de heterogeneidades
- Aumentar resolución incrementa tiempo de cómputo exponencialmente

### **Q: ¿Cómo validar que mi simulación es físicamente correcta?**

**A:** Use el siguiente checklist de validación:

```python
def validate_simulation_physics(dataset):
    """Checklist de validación física."""
    
    checks = []
    
    # 1. Balance de masa
    mass_balance = check_mass_balance(dataset)
    checks.append(('Balance de masa', mass_balance < 0.01, f'{mass_balance:.3%}'))
    
    # 2. Rangos físicos de variables
    pressure = dataset['fields']['pressure']
    saturation = dataset['fields']['sw']
    
    pressure_valid = np.all(pressure > 0) and np.all(pressure < 10000)
    saturation_valid = np.all(saturation >= 0) and np.all(saturation <= 1)
    
    checks.append(('Rango de presión', pressure_valid, f'[{np.min(pressure):.1f}, {np.max(pressure):.1f}] psi'))
    checks.append(('Rango de saturación', saturation_valid, f'[{np.min(saturation):.3f}, {np.max(saturation):.3f}]'))
    
    # 3. Tendencias físicas esperadas
    # Presión debe declinar cerca de productores
    initial_p = np.mean(pressure[0])
    final_p = np.mean(pressure[-1])
    pressure_decline = initial_p > final_p
    
    checks.append(('Decline de presión', pressure_decline, f'{initial_p:.1f} → {final_p:.1f} psi'))
    
    # 4. Continuidad espacial (no jumps abruptos)
    grad_x = np.gradient(pressure[-1], axis=1)
    grad_y = np.gradient(pressure[-1], axis=0)
    max_gradient = np.max(np.sqrt(grad_x**2 + grad_y**2))
    gradient_reasonable = max_gradient < 100  # psi/cell
    
    checks.append(('Gradientes espaciales', gradient_reasonable, f'Max: {max_gradient:.1f} psi/cell'))
    
    # Reporte
    print("=== VALIDACIÓN FÍSICA ===")
    all_passed = True
    
    for check_name, passed, value in checks:
        status = "✅" if passed else "❌"
        print(f"{status} {check_name}: {value}")
        all_passed &= passed
    
    return all_passed
```

### **Q: ¿Cuándo usar qué tipo de modelo ML?**

**A:** Guía de selección de modelos:

| Tipo de Problema | Modelo Recomendado | Razón |
|------------------|-------------------|-------|
| Predicción de campos espaciales 2D | **CNN** | Captura patrones espaciales locales |
| Evolución temporal de variables promedio | **LSTM/GRU** | Modela dependencias temporales |
| Detección de frentes de saturación | **U-Net** | Preserva discontinuidades espaciales |
| Predicción con restricciones físicas | **PINN** | Incorpora ecuaciones diferenciales |
| Optimización con pocos datos | **Gaussian Process** | Cuantifica incertidumbre |
| Clasificación de regímenes de flujo | **Random Forest** | Interpretable y robusto |

### **Q: ¿Cómo interpretar las métricas de evaluación?**

**A:** Guía de interpretación:

```python
# Métricas típicas y sus interpretaciones
evaluation_guide = {
    'mse': {
        'excelente': '< 0.01',
        'bueno': '0.01 - 0.1', 
        'aceptable': '0.1 - 1.0',
        'pobre': '> 1.0'
    },
    'r2_score': {
        'excelente': '> 0.95',
        'bueno': '0.85 - 0.95',
        'aceptable': '0.70 - 0.85',
        'pobre': '< 0.70'
    },
    'relative_error': {
        'excelente': '< 5%',
        'bueno': '5% - 15%',
        'aceptable': '15% - 30%',
        'pobre': '> 30%'
    }
}

def interpret_metrics(metrics):
    """Interpretar métricas de evaluación."""
    
    print("=== INTERPRETACIÓN DE MÉTRICAS ===")
    
    for metric, value in metrics.items():
        if metric in evaluation_guide:
            ranges = evaluation_guide[metric]
            
            if metric == 'r2_score':
                if value > 0.95:
                    level = 'excelente'
                elif value > 0.85:
                    level = 'bueno'
                elif value > 0.70:
                    level = 'aceptable'
                else:
                    level = 'pobre'
            
            print(f"{metric}: {value:.3f} ({level})")
```

### **Q: ¿Cómo escalar el sistema para múltiples casos?**

**A:** Estrategias de escalamiento:

1. **Paralelización de Simulaciones**
```bash
# Usar GNU parallel para múltiples casos
parallel -j 4 octave --eval "s99_run_workflow('config/case_{}.yaml')" ::: {1..20}
```

2. **Pipeline de ML Batch**
```python
# Procesar múltiples datasets en batch
class BatchMLPipeline:
    def process_multiple_cases(self, case_list):
        for case in case_list:
            self.process_single_case(case)
            self.cleanup_memory()
```

3. **Almacenamiento Eficiente**
```python
# Usar HDF5 para datasets grandes
import h5py

def save_dataset_hdf5(dataset, filename):
    with h5py.File(filename, 'w') as f:
        for key, value in dataset.items():
            f.create_dataset(key, data=value, compression='gzip')
```

**Fuente**: `mrst_simulation_scripts/`, `dashboard/`, configuraciones YAML

---

*Este capítulo completa el manual del usuario de GeomechML. Para soporte adicional, consulta los logs de simulación y contacta al equipo de desarrollo.*