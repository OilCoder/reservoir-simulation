# Análisis de Datos para Dashboard Streamlit MRST

## Datos Disponibles Actualmente

### ✅ Initial Conditions (`initial_conditions.mat`)
- `pressure`: Presión inicial (psi)
- `sw`: Saturación de agua inicial
- `phi`: Porosidad inicial
- `k`: Permeabilidad inicial (mD)

### ✅ Static Data (`static_data.mat`)
- `rock_id`: ID de región de roca
- `grid_x`, `grid_y`: Coordenadas de grilla
- `cell_centers_x`, `cell_centers_y`: Centros de celdas
- `wells`: Información de pozos

### ✅ Temporal Data (`time_data.mat`)
- `time_days`: Vector de tiempo (días)
- `dt_days`: Pasos de tiempo (días)
- `control_indices`: Índices de control

### ✅ Dynamic Fields (`field_arrays.mat`)
- `pressure`: Presión [time, y, x] (psi)
- `sw`: Saturación de agua [time, y, x]
- `phi`: Porosidad [time, y, x]
- `k`: Permeabilidad [time, y, x] (mD)
- `sigma_eff`: Esfuerzo efectivo [time, y, x] (psi)

### ✅ Well Data (`well_data.mat`)
- `time_days`: Tiempo de datos de pozos
- `well_names`: Nombres de pozos
- `qWs`: Tasas de agua (STB/d)
- `qOs`: Tasas de aceite (STB/d)
- `bhp`: Bottom hole pressure (psi)

### ✅ Metadata (`metadata.mat`)
- `dataset_info`: Información del dataset
- `simulation`: Parámetros de simulación
- `structure`: Estructura de datos
- `optimization`: Configuración de optimización
- `units`: Unidades utilizadas
- `conventions`: Convenciones

## Análisis de Gráficos Requeridos vs Datos Disponibles

### ✅ GRÁFICOS POSIBLES (Datos Completos)

#### **Categoría A: Fluid & Rock Properties**
- **A-1**: Curvas kr (sw, krw, kro) ❌ **FALTA** - No hay datos de curvas kr
- **A-2**: Propiedades PVT ❌ **FALTA** - No hay datos PVT
- **A-3**: Histogramas φ₀ y k₀ ✅ **POSIBLE** - Datos: phi, k (initial)
- **A-4**: Cross-plot log k vs φ (σ′ como color) ✅ **POSIBLE** - Datos: phi, k, sigma_eff

#### **Categoría B: Initial Conditions**
- **B-1**: Mapa inicial de Sw ✅ **POSIBLE** - Datos: sw (initial)
- **B-2**: Mapa de P₀ ✅ **POSIBLE** - Datos: pressure (initial)

#### **Categoría C: Geometry**
- **C-1**: Plano XY de pozos ✅ **POSIBLE** - Datos: wells, grid_x, grid_y
- **C-2**: Mapa de regiones de roca ✅ **POSIBLE** - Datos: rock_id

#### **Categoría D: Operations**
- **D-1**: Programa de tasas ✅ **POSIBLE** - Datos: time_days, qWs, qOs
- **D-2**: Límites de BHP ✅ **POSIBLE** - Datos: time_days, bhp
- **D-3**: Voidage ratio ❌ **FALTA** - Necesita cálculo de volúmenes
- **D-4**: PV inyectado vs Recuperación ❌ **FALTA** - Necesita datos acumulados

#### **Categoría E: Global Evolution**
- **E-1**: Presión promedio + rango ✅ **POSIBLE** - Datos: pressure [time, y, x]
- **E-2**: Esfuerzo efectivo promedio + rango ✅ **POSIBLE** - Datos: sigma_eff [time, y, x]
- **E-3**: Porosidad promedio + rango ✅ **POSIBLE** - Datos: phi [time, y, x]
- **E-4**: Permeabilidad promedio + rango ✅ **POSIBLE** - Datos: k [time, y, x]
- **E-5**: Histograma evolutivo de Sw ✅ **POSIBLE** - Datos: sw [time, y, x]

#### **Categoría F: Well Performance**
- **F-1**: BHP por pozo ✅ **POSIBLE** - Datos: time_days, bhp, well_names
- **F-2**: Tasas instantáneas q_o, q_w ✅ **POSIBLE** - Datos: time_days, qOs, qWs
- **F-3**: Producción acumulada ❌ **FALTA** - Necesita integración temporal
- **F-4**: Water-cut ✅ **POSIBLE** - Datos: qWs, qOs (cálculo: qWs/(qWs+qOs))

#### **Categoría G: Spatial Maps**
- **G-1**: Mapa de presión ✅ **POSIBLE** - Datos: pressure [time, y, x]
- **G-2**: Mapa σ′ ✅ **POSIBLE** - Datos: sigma_eff [time, y, x]
- **G-3**: Mapa φ ✅ **POSIBLE** - Datos: phi [time, y, x]
- **G-4**: Mapa log k ✅ **POSIBLE** - Datos: k [time, y, x]
- **G-5**: Mapa Sw ✅ **POSIBLE** - Datos: sw [time, y, x]
- **G-6**: ΔPresión = p−p₀ ✅ **POSIBLE** - Datos: pressure [time, y, x] - pressure (initial)
- **G-7**: Frente Sw≥0.8 ✅ **POSIBLE** - Datos: sw [time, y, x] (contorno)
- **G-8**: Streamlines ❌ **FALTA** - Necesita datos de velocidad de flujo

#### **Categoría H: Multiphysics**
- **H-1**: Fractional-flow fw vs Sw ✅ **POSIBLE** - Datos: sw [time, y, x], qWs, qOs
- **H-2**: Tornado de sensibilidad ❌ **FALTA** - Necesita múltiples simulaciones

## ❌ DATOS FALTANTES CRÍTICOS

### 1. **Fluid Properties (Categoría A)**
```
REQUERIDO EN MRST:
- Curvas de permeabilidad relativa (krw, kro vs Sw)
- Datos PVT (B_o, B_w, μ_o, μ_w vs P)
- Puntos críticos (Swc, Sor)

EXPORTAR EN:
- static_data.mat o nuevo archivo fluid_properties.mat
```

### 2. **Volumetric Data (Categorías D, F)**
```
REQUERIDO EN MRST:
- Volúmenes acumulados por pozo
- PV inyectado acumulado
- OOIP inicial
- Balance volumétrico

EXPORTAR EN:
- well_data.mat (agregar campos acumulados)
- metadata.mat (agregar OOIP, PV inicial)
```

### 3. **Flow Data (Categoría G)**
```
REQUERIDO EN MRST:
- Velocidades de flujo (vx, vy)
- Streamlines
- Datos de conectividad

EXPORTAR EN:
- Nuevo archivo flow_data.mat
```

### 4. **Sensitivity Data (Categoría H)**
```
REQUERIDO EN MRST:
- Múltiples simulaciones con parámetros variados
- Matriz de sensibilidad
- Análisis de incertidumbre

EXPORTAR EN:
- Nuevo directorio sensitivity/
```

## 📊 RESUMEN DE IMPLEMENTACIÓN

### ✅ **INMEDIATAMENTE IMPLEMENTABLE (22/26 gráficos)**
- Categoría B: 2/2 gráficos
- Categoría C: 2/2 gráficos  
- Categoría D: 2/4 gráficos
- Categoría E: 5/5 gráficos
- Categoría F: 3/4 gráficos
- Categoría G: 7/8 gráficos
- Categoría H: 1/2 gráficos

### ❌ **REQUIERE DATOS ADICIONALES (4/26 gráficos)**
- A-1, A-2: Curvas kr y PVT
- D-3, D-4: Datos volumétricos
- F-3: Producción acumulada
- G-8: Streamlines
- H-2: Análisis de sensibilidad

## 🚀 RECOMENDACIONES DE IMPLEMENTACIÓN

### Fase 1: Dashboard Básico (22 gráficos)
1. Implementar todos los gráficos marcados como ✅ POSIBLE
2. Usar datos reales de MRST sin hardcoding
3. Validar visualización y navegación

### Fase 2: Extensión de Datos (4 gráficos restantes)
1. Modificar scripts MRST para exportar datos faltantes
2. Agregar nuevos loaders en util_data_loader.py
3. Implementar gráficos restantes

### Fase 3: Optimización
1. Agregar animaciones para mapas temporales
2. Implementar filtros interactivos
3. Agregar análisis estadísticos avanzados 