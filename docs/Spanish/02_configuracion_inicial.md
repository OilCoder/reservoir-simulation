# Capítulo 2: Configuración Inicial

## 2.1 Introducción

En este capítulo aprenderás a configurar tu entorno de trabajo para ejecutar GeomechML. Seguiremos un proceso paso a paso que te llevará desde la instalación de dependencias hasta la verificación de que todo funciona correctamente.

### **Objetivos del Capítulo**
- ✅ Instalar y configurar MRST
- ✅ Configurar el entorno de Python para ML
- ✅ Organizar la estructura del proyecto
- ✅ Verificar que la instalación funciona
- ✅ Ejecutar tu primera simulación de prueba

## 2.2 Requisitos del Sistema

### **Requisitos Mínimos**
| Componente | Especificación |
|-----------|----------------|
| **Sistema Operativo** | Linux, macOS, Windows 10+ |
| **RAM** | 4 GB (recomendado: 8 GB) |
| **Almacenamiento** | 2 GB libres |
| **CPU** | Dual-core 2.0 GHz+ |

### **Software Requerido**
- 🐙 **Octave 6.0+** - Para ejecutar MRST
- 🐍 **Python 3.8+** - Para modelos ML
- 📄 **Git** - Para control de versiones
- 📝 **Editor de texto** - VS Code, Vim, etc.

## 2.3 Instalación de MRST

### **Paso 1: Descargar MRST**

```bash
# Crear directorio de trabajo
mkdir ~/geomech-workspace
cd ~/geomech-workspace

# Descargar MRST
wget https://www.sintef.no/projectweb/mrst/download/
# O usar git si está disponible
git clone https://bitbucket.org/mrst/mrst-core.git mrst
```

### **Paso 2: Configurar MRST en Octave**

```octave
% Iniciar Octave
octave

% Navegar al directorio MRST
cd ~/geomech-workspace/mrst

% Ejecutar startup de MRST
startup

% Verificar instalación
mrstModule list
```

### **Paso 3: Instalar Módulos Necesarios**

```octave
% Agregar módulos requeridos para GeomechML
mrstModule add ad-core
mrstModule add ad-blackoil  
mrstModule add ad-props
mrstModule add incomp
mrstModule add mrst-gui

% Verificar módulos instalados
mrstModule list
```

### **✅ Verificación de MRST**

```octave
% Test básico de MRST
G = cartGrid([10, 10], [100, 100]);
G = computeGeometry(G);

if G.cells.num == 100
    fprintf('✅ MRST instalado correctamente\n');
else
    fprintf('❌ Error en instalación de MRST\n');
end
```

## 2.4 Configuración de Python para ML

### **Paso 1: Crear Entorno Virtual**

```bash
# Crear entorno virtual para GeomechML
python3 -m venv geomech-env

# Activar entorno (Linux/macOS)
source geomech-env/bin/activate

# Activar entorno (Windows)
geomech-env\Scripts\activate
```

### **Paso 2: Instalar Dependencias Python**

```bash
# Actualizar pip
pip install --upgrade pip

# Instalar librerías base
pip install numpy>=1.20.0
pip install scipy>=1.7.0
pip install matplotlib>=3.4.0
pip install pandas>=1.3.0

# Instalar librerías ML
pip install scikit-learn>=1.0.0
pip install tensorflow>=2.8.0

# Instalar utilidades
pip install pyyaml>=6.0
pip install jupyter>=1.0.0
```

### **Paso 3: Crear requirements.txt**

```bash
# Generar archivo de dependencias
pip freeze > requirements.txt
```

### **✅ Verificación de Python**

```python
# Test básico de librerías
import numpy as np
import scipy.io
import matplotlib.pyplot as plt
import sklearn
import tensorflow as tf

print("✅ Todas las librerías Python instaladas correctamente")
print(f"NumPy: {np.__version__}")
print(f"TensorFlow: {tf.__version__}")
```

## 2.5 Estructura del Proyecto

### **Paso 1: Clonar GeomechML**

```bash
# Clonar repositorio del proyecto
cd ~/geomech-workspace
git clone <repository-url> GeomechML
cd GeomechML
```

### **Paso 2: Estructura de Directorios**

```bash
# Crear estructura de directorios si no existe
mkdir -p MRST_simulation_scripts
mkdir -p src/{surrogate,utils}
mkdir -p data/{raw,processed}
mkdir -p tests
mkdir -p debug
mkdir -p config
mkdir -p plots
mkdir -p docs/{Spanish,English,ADR}
mkdir -p to_dos
```

### **Verificar Estructura**

```bash
# Listar estructura del proyecto
tree -L 3
```

**Estructura Esperada:**
```
GeomechML/
├── MRST_simulation_scripts/          # Scripts de simulación MRST
├── src/                  # Código fuente Python
│   ├── surrogate/        # Modelos ML
│   └── utils/            # Utilidades
├── data/
│   ├── raw/              # Datos de simulación
│   └── processed/        # Datos procesados
├── tests/                # Tests automatizados
├── debug/                # Scripts de debug
├── config/               # Configuraciones YAML
├── plots/                # Visualizaciones
├── docs/                 # Documentación
├── to_dos/               # Tareas pendientes
└── README.md
```

## 2.6 Configuración de Archivos Base

### **Paso 1: Configurar MRST Path**

Crear `setup_mrst.m` en el directorio raíz:

```octave
% setup_mrst.m - Configuración de MRST para GeomechML
function setup_mrst()
    % Configurar path de MRST
    mrst_path = fullfile(fileparts(pwd), 'mrst');
    
    if exist(mrst_path, 'dir')
        addpath(mrst_path);
        cd(mrst_path);
        startup;
        cd(fileparts(mrst_path));
        
        % Agregar módulos necesarios
        mrstModule add ad-core ad-blackoil ad-props
        mrstModule add incomp mrst-gui
        
        fprintf('✅ MRST configurado correctamente\n');
    else
        error('❌ MRST no encontrado en: %s', mrst_path);
    end
end
```

### **Paso 2: Configurar Variables de Entorno**

Crear `.env` en el directorio raíz:

```bash
# .env - Variables de entorno para GeomechML
export GEOMECH_ROOT=$(pwd)
export MRST_PATH=$GEOMECH_ROOT/../mrst
export PYTHONPATH=$GEOMECH_ROOT/src:$PYTHONPATH
export OCTAVE_PATH=$GEOMECH_ROOT/MRST_simulation_scripts:$OCTAVE_PATH
```

### **Paso 3: Script de Inicialización**

Crear `init_geomech.sh`:

```bash
#!/bin/bash
# init_geomech.sh - Inicialización del entorno GeomechML

echo "🚀 Inicializando GeomechML..."

# Cargar variables de entorno
source .env

# Activar entorno Python
if [ -d "../geomech-env" ]; then
    source ../geomech-env/bin/activate
    echo "✅ Entorno Python activado"
else
    echo "⚠️  Entorno Python no encontrado"
fi

# Verificar MRST
if [ -d "$MRST_PATH" ]; then
    echo "✅ MRST encontrado en $MRST_PATH"
else
    echo "❌ MRST no encontrado"
fi

echo "📁 Directorio de trabajo: $GEOMECH_ROOT"
echo "🎉 GeomechML listo para usar"
```

## 2.7 Verificación Completa del Sistema

### **Test de Integración Completo**

Crear `test_installation.m`:

```octave
function test_installation()
    % test_installation.m - Verificación completa del sistema
    
    fprintf('=== Test de Instalación GeomechML ===\n');
    
    % Test 1: MRST
    fprintf('\n1. Testing MRST...\n');
    try
        G = cartGrid([5, 5], [100, 100]);
        G = computeGeometry(G);
        fprintf('✅ MRST: OK\n');
    catch ME
        fprintf('❌ MRST: FAILED - %s\n', ME.message);
        return;
    end
    
    % Test 2: Configuración YAML
    fprintf('\n2. Testing YAML configuration...\n');
    config_file = 'config/reservoir_config.yaml';
    if exist(config_file, 'file')
        try
            config = util_read_config(config_file);
            fprintf('✅ YAML Config: OK\n');
        catch ME
            fprintf('❌ YAML Config: FAILED - %s\n', ME.message);
        end
    else
        fprintf('⚠️  YAML Config: No encontrado (se creará más tarde)\n');
    end
    
    % Test 3: Estructura de directorios
    fprintf('\n3. Testing directory structure...\n');
    required_dirs = {'MRST_simulation_scripts', 'data', 'tests', 'config'};
    all_dirs_exist = true;
    
    for i = 1:length(required_dirs)
        if exist(required_dirs{i}, 'dir')
            fprintf('✅ %s: OK\n', required_dirs{i});
        else
            fprintf('❌ %s: MISSING\n', required_dirs{i});
            all_dirs_exist = false;
        end
    end
    
    % Test 4: Python (si está disponible)
    fprintf('\n4. Testing Python integration...\n');
    try
        [status, result] = system('python3 -c "import numpy, scipy, sklearn; print(''Python OK'')"');
        if status == 0
            fprintf('✅ Python ML: OK\n');
        else
            fprintf('❌ Python ML: FAILED\n');
        end
    catch
        fprintf('⚠️  Python ML: No disponible\n');
    end
    
    % Resumen
    fprintf('\n=== Resumen ===\n');
    if all_dirs_exist
        fprintf('🎉 Instalación completa exitosa\n');
        fprintf('📖 Continúa con el Capítulo 3: Configuración de Parámetros\n');
    else
        fprintf('⚠️  Instalación incompleta - revisar errores arriba\n');
    end
end
```

### **Ejecutar Verificación**

```bash
# Hacer ejecutable el script de inicialización
chmod +x init_geomech.sh

# Inicializar entorno
./init_geomech.sh

# Ejecutar test de instalación
octave
octave> test_installation
```

## 2.8 Configuración Inicial de Archivos

### **Crear Configuración Base**

Si no existe, crear `config/reservoir_config.yaml`:

```yaml
# Configuración base para GeomechML
grid:
  nx: 20
  ny: 20
  dx: 164  # ft
  dy: 164  # ft
  dz: 33   # ft

porosity:
  base_value: 0.2
  variation_amplitude: 0.05
  min_value: 0.05
  max_value: 0.3

permeability:
  base_value: 100  # mD
  variation_amplitude: 50
  min_value: 1
  max_value: 500

wells:
  injector_i: 5
  injector_j: 10
  producer_i: 15
  producer_j: 10
  injector_rate: 251    # bbl/day
  producer_bhp: 2175    # psi

simulation:
  total_time: 365       # days
  num_timesteps: 50

initial_conditions:
  pressure: 2900        # psi
  water_saturation: 0.2
```

### **Crear .gitignore**

```bash
# .gitignore para GeomechML
data/raw/*.mat
data/processed/*.csv
debug/
plots/*.png
plots/*.pdf
*.asv
*.m~
__pycache__/
*.pyc
.env
geomech-env/
```

## 2.9 Primera Ejecución de Prueba

### **Test Rápido de Simulación**

```octave
% Cambiar al directorio de simulación
cd MRST_simulation_scripts

% Configurar MRST
setup_mrst

% Ejecutar test básico
fprintf('🧪 Ejecutando test básico...\n');

% Test de configuración
config = util_read_config('../config/reservoir_config.yaml');
fprintf('✅ Configuración cargada: Grid %dx%d\n', config.grid.nx, config.grid.ny);

% Test de setup básico
try
    [G, rock, fluid] = setup_field('../config/reservoir_config.yaml');
    fprintf('✅ Setup de campo exitoso: %d celdas\n', G.cells.num);
catch ME
    fprintf('❌ Error en setup: %s\n', ME.message);
end
```

## 2.10 Troubleshooting Común

### **Problemas de MRST**

**Error: "MRST modules not found"**
```octave
% Solución: Verificar path de MRST
which startup
% Si no encuentra, agregar path manualmente:
addpath('/path/to/mrst');
startup;
```

**Error: "Cannot add module ad-core"**
```octave
% Solución: Verificar instalación completa de MRST
mrstPath('reset');
mrstModule('reset');
startup;
```

### **Problemas de Python**

**Error: "ModuleNotFoundError"**
```bash
# Solución: Verificar entorno virtual
source ../geomech-env/bin/activate
pip list | grep numpy
```

**Error: "Permission denied"**
```bash
# Solución: Usar --user flag
pip install --user numpy scipy matplotlib
```

### **Problemas de Permisos**

```bash
# Dar permisos de ejecución
chmod +x init_geomech.sh
chmod +x scripts/*.sh

# Verificar permisos de directorios
ls -la data/
```

## 2.11 Próximos Pasos

### **Verificación Final**

Antes de continuar, asegúrate de que:
- ✅ MRST se ejecuta sin errores
- ✅ Python ML libraries están instaladas
- ✅ Estructura de directorios está completa
- ✅ `test_installation.m` pasa todos los tests
- ✅ Puedes cargar configuración YAML

### **¿Qué Sigue?**

Ahora que tienes el entorno configurado, estás listo para:

📖 **[Capítulo 3: Configuración de Parámetros](03_configuracion_parametros.md)**
- Entender el sistema de configuración YAML
- Personalizar parámetros de simulación
- Configurar propiedades de roca y fluidos

### **Recursos Adicionales**

- 📚 **MRST Tutorials**: https://www.sintef.no/mrst/tutorials/
- 🐍 **Python Virtual Environments**: https://docs.python.org/3/tutorial/venv.html
- 📝 **YAML Syntax**: https://yaml.org/spec/1.2/spec.html

---

*[⬅️ Capítulo 1: Introducción](01_introduccion.md) | [Siguiente: Configuración de Parámetros ➡️](03_configuracion_parametros.md)* 