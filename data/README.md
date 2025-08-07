# Data Directory - Eagle West Field Project

Carpeta centralizada para **todos los datos** del proyecto.

## Estructura de Carpetas

```
data/
├── mrst_simulation/     # 🎯 Datos de simulador MRST
│   ├── results/         # Resultados de simulación
│   ├── logs/           # Logs de ejecución
│   ├── static/         # Datos estáticos (grid, propiedades)
│   ├── dynamic/        # Datos dinámicos (presión, saturación)
│   └── exports/        # Datos exportados (HDF5, NetCDF)
├── ml_models/          # 🤖 Modelos de Machine Learning
│   ├── trained_models/ # Modelos entrenados
│   ├── training_data/  # Datos de entrenamiento
│   └── predictions/    # Predicciones de modelos
├── other_simulators/   # 🔧 Otros simuladores
│   ├── eclipse/        # Datos de Eclipse
│   ├── cmg/           # Datos de CMG
│   └── petrel/        # Datos de Petrel
└── raw_data/          # 📊 Datos originales/brutos
    ├── field_data/    # Datos de campo reales
    ├── well_logs/     # Registros de pozos
    └── seismic/       # Datos sísmicos
```

## Uso por Simuladores

### MRST Python
- **Input**: Lee configuración desde `mrst_simulation_scripts/config/`
- **Output**: Guarda resultados en `data/mrst_simulation/`

### Machine Learning
- **Training**: Usa datos de `data/mrst_simulation/results/`
- **Models**: Guarda modelos en `data/ml_models/`

### Otros Simuladores
- **Import**: Puede leer datos de `data/raw_data/`
- **Export**: Guarda en carpetas específicas

## Formatos de Datos

- **HDF5** (`.h5`): Arrays multidimensionales, datos complejos
- **NetCDF** (`.nc`): Series temporales geoespaciales
- **Parquet** (`.parquet`): Datos tabulares, time-series
- **JSON** (`.json`): Metadatos, configuraciones
- **CSV** (`.csv`): Datos simples, compatibilidad

## Integración de Componentes

1. **MRST** → Genera datos de simulación
2. **ML Models** → Procesa datos de MRST para predicciones  
3. **Dashboard** → Visualiza datos de todas las fuentes
4. **Otros Simuladores** → Valida/compara con MRST

Esta estructura permite **máxima flexibilidad** y **fácil integración** entre todos los componentes del proyecto.