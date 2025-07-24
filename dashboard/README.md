# GeomechML Dashboard

Dashboard interactivo de Streamlit para visualización y análisis de simulaciones de reservorio geomecánico desarrolladas con MRST (MATLAB Reservoir Simulation Toolbox).

## 🚀 Características Principales

### 📊 Visualización Completa
- **Resumen General**: Métricas clave, configuración del grid, ubicación de pozos
- **Propiedades del Reservorio**: Mapas 2D/3D de porosidad, permeabilidad, presión
- **Rendimiento de Producción**: Curvas de producción, análisis de eficiencia
- **Evolución de Presión**: Mapas temporales, análisis geomecánico

### 🎯 Funcionalidades Avanzadas
- Navegación temporal interactiva con slider
- Mapas de calor 2D y visualizaciones 3D
- Análisis estadístico detallado
- Correlaciones entre propiedades
- Exportación de gráficos y datos

## 📋 Requisitos

### Dependencias de Python
```bash
pip install -r requirements.txt
```

Principales librerías:
- `streamlit>=1.28.0` - Framework web
- `plotly>=5.15.0` - Visualizaciones interactivas  
- `pandas>=2.0.0` - Manipulación de datos
- `numpy>=1.24.0` - Computación numérica
- `scipy>=1.10.0` - Lectura de archivos MATLAB
- `PyYAML>=6.0` - Configuración

### Datos Requeridos
El dashboard espera datos de simulación MRST en la siguiente estructura:
```
../data/
├── initial/     # Datos iniciales del reservorio
├── static/      # Propiedades estáticas (porosidad, permeabilidad)
├── dynamic/     # Datos dinámicos por timestep (presión, saturación)
├── temporal/    # Series temporales (producción, inyección)
└── metadata/    # Metadatos de la simulación
```

## 🚀 Ejecución

### Método Recomendado (Auto-launch)
```bash
# Desde el directorio dashboard
cd dashboard
python s99_dashboard_app.py
```

### Método Alternativo (Streamlit directo)
```bash
# Desde el directorio del proyecto
streamlit run dashboard/s99_dashboard_app.py
```

### Ejecutar Simulación (si necesitas datos)
```bash
# Generar datos de simulación MRST
cd mrst_simulation_scripts
octave --eval "s99_run_workflow()"
```

### Acceso Web
Una vez ejecutado, el dashboard estará disponible en:
- **Local**: http://localhost:8501
- **Red local**: http://[tu-ip]:8501

## 📁 Estructura del Código

```
dashboard/
├── s99_dashboard_app.py      # Aplicación principal y launcher
├── s01_data_loader.py        # Carga de datos MATLAB/YAML
├── s02_viz_components.py     # Utilidades de visualización
├── s03_overview_page.py      # Módulo de resumen general
├── s04_pressure_page.py      # Evolución de presión
├── s05_production_page.py    # Análisis de producción
├── s06_reservoir_page.py     # Visualización de propiedades
├── s07_export_utils.py       # Exportación de datos/gráficos
└── README.md                 # Esta documentación
```

**Naming Convention**: Los archivos siguen el patrón `sNN_verb_noun.py` donde:
- `s99_` = Launcher principal (orquestador)
- `s01-s07_` = Componentes del workflow en orden de ejecución
- Nomenclatura en inglés siguiendo Rule 05 del proyecto

## 🎮 Guía de Uso

### 1. Navegación Principal
- **🏠 Resumen General**: Vista de alto nivel de la simulación
- **🗻 Propiedades del Reservorio**: Análisis espacial de propiedades rocosas
- **🛢️ Rendimiento de Producción**: Métricas de pozos y eficiencia
- **📈 Evolución de Presión**: Análisis temporal de presión
- **📊 Análisis Estadístico**: Distribuciones y correlaciones
- **⚙️ Configuración**: Parámetros de simulación

### 2. Controles Interactivos
- **Slider temporal**: Navegar entre timesteps
- **Selector de capas**: Visualizar diferentes niveles del reservorio
- **Tipo de visualización**: 2D, 3D, comparación de capas
- **Propiedades**: Cambiar entre porosidad, permeabilidad, presión, etc.

### 3. Exportación de Datos
- **Gráficos**: PNG, PDF, SVG, HTML interactivo
- **Datos**: CSV, Excel, JSON
- **Reportes completos**: ZIP con gráficos, datos y metadatos

## 🔧 Configuración

### Variables de Entorno
```bash
# Opcional: configurar puerto personalizado
export STREAMLIT_SERVER_PORT=8502

# Opcional: configurar tema
export STREAMLIT_THEME_BASE="light"
```

### Configuración de Streamlit
Crear `.streamlit/config.toml`:
```toml
[server]
port = 8501
enableCORS = false
enableXsrfProtection = false

[browser]
gatherUsageStats = false

[theme]
base = "light"
primaryColor = "#1f77b4"
```

## 📊 Tipos de Datos Soportados

### Formatos de Entrada
- **MATLAB (.mat)**: Archivos de simulación MRST
- **YAML**: Configuración del proyecto
- **NumPy arrays**: Datos multidimensionales

### Variables Reconocidas
- `porosity` - Porosidad del reservorio
- `permeability` - Permeabilidad absoluta
- `pressure` - Presión de poro
- `water_saturation` - Saturación de agua
- `effective_stress` - Esfuerzo efectivo
- `flow_rate_prod/inj` - Tasas de pozos

## 🐛 Solución de Problemas

### Datos No Disponibles
```
⚠️ No se encontraron datos de simulación
```
**Solución**: Ejecutar workflow de simulación MRST primero.

### Error de Importación
```
ModuleNotFoundError: No module named 'plotly'
```
**Solución**: Instalar dependencias con `pip install -r requirements.txt`

### Puerto en Uso
```
Port 8501 is in use
```
**Solución**: Usar puerto diferente con `streamlit run dashboard.py --server.port 8502`

### Archivos MATLAB Corruptos
```
❌ No se pudo cargar archivo .mat
```
**Solución**: Verificar integridad de archivos, regenerar simulación si es necesario.

## 🔄 Desarrollo y Extensión

### Agregar Nueva Visualización
1. Crear función en `viz_utils.py`
2. Agregar módulo en directorio principal
3. Registrar en `dashboard.py` en `nav_options`

### Personalizar Colores
Modificar esquemas en `viz_utils.py`:
```python
class ColorSchemes:
    POROSITY = 'Viridis'      # Cambiar esquema
    PRESSURE = 'RdYlBu_r'     # Personalizar
```

### Agregar Nuevos Formatos de Export
Extender `export_utils.py`:
```python
def _export_custom(self, df, filename):
    # Implementar nuevo formato
    pass
```

## 📈 Rendimiento

### Optimizaciones Implementadas
- **Caché de datos**: Los archivos .mat se mantienen en memoria
- **Lazy loading**: Datos se cargan solo cuando se necesitan
- **Renderizado eficiente**: Plotly con configuración optimizada

### Recomendaciones de Hardware
- **RAM**: Mínimo 8GB, recomendado 16GB para datasets grandes
- **CPU**: Procesador moderno para cálculos NumPy
- **Storage**: SSD recomendado para carga rápida de archivos

## 🤝 Contribución

### Estructura de Commits
- `feat:` - Nueva funcionalidad
- `fix:` - Corrección de bugs
- `docs:` - Documentación
- `style:` - Formato, estilo
- `refactor:` - Refactorización de código

### Estándares de Código
- Seguir PEP 8 para Python
- Documentar funciones con docstrings
- Usar type hints donde sea posible
- Mantener funciones pequeñas y enfocadas

## 📄 Licencia

Este proyecto es parte del sistema GeomechML y sigue las mismas políticas de licencia del proyecto principal.

## 📞 Soporte

Para soporte técnico o reportar issues:
1. Verificar que la simulación MRST haya completado correctamente
2. Revisar logs del dashboard en la consola
3. Verificar que todos los archivos de datos estén presentes
4. Consultar la documentación del proyecto principal

---

**GeomechML Dashboard v2.0** - Sistema de visualización para simulaciones de reservorio geomecánico