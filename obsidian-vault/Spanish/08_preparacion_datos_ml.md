# Capítulo 8: Preparación de Datos para Machine Learning

## 8.1 Introducción

Este capítulo explica cómo preparar los datos de simulación geomecánica para desarrollar modelos de machine learning que puedan acelerar el análisis de yacimientos. Los modelos ML pueden predecir comportamiento del reservorio en minutos en lugar de horas, facilitando estudios paramétricos y optimización de desarrollo.

### **Objetivos del Capítulo**
- ✅ Entender qué datos genera la simulación para ML
- ✅ Conocer los tipos de modelos aplicables a yacimientos
- ✅ Aprender a validar calidad de datos de simulación
- ✅ Comprender el workflow de preparación de datos
- ✅ Identificar variables críticas para modelos predictivos

## 8.2 Tipos de Datos Generados por la Simulación

La simulación geomecánica genera múltiples tipos de datos que pueden usarse para entrenar modelos predictivos:

### **Datos Estáticos del Reservorio**
- **Geometría del grid**: Dimensiones 3D del reservorio (20×20×10 celdas)
- **Propiedades de roca**: Porosidad, permeabilidad, compresibilidad por capa geológica
- **Ubicación de pozos**: Coordenadas de productores e inyectores
- **Propiedades de fluidos**: Densidades, viscosidades, curvas de permeabilidad relativa

### **Condiciones Iniciales** 
Variables del reservorio al tiempo t=0:
- **Presión inicial**: Distribución espacial de presión de poro
- **Saturación inicial**: Distribución de agua/petróleo en el reservorio
- **Estado geomecánico**: Esfuerzos efectivos iniciales

### **Evolución Temporal del Reservorio**
Variables que cambian durante la simulación (500 timesteps × 10 años):
- **Campos de presión**: Evolución espacial de presión de poro
- **Frentes de saturación**: Avance del agua inyectada
- **Compactación**: Cambios en porosidad por efectos geomecánicos
- **Esfuerzos efectivos**: Evolución del estado de esfuerzos

### **Datos de Producción**
- **Tasas de producción**: Petróleo producido por pozo vs tiempo
- **Tasas de inyección**: Agua inyectada por pozo vs tiempo
- **Presiones de fondo**: BHP en productores e inyectores
- **Métricas acumuladas**: Recuperación, factor de recobro, corte de agua

## 8.3 Aplicaciones de Machine Learning en Yacimientos

### **Tipos de Problemas que Puede Resolver ML**

#### **Predicción de Comportamiento del Reservorio**
- **Predicción de presión**: Estimar campos de presión futuros sin simulación completa
- **Avance de frentes**: Predecir el breakthrough de agua en productores
- **Compactación**: Calcular subsidencia y cambios en porosidad
- **Productividad de pozos**: Estimar tasas de producción futuras

#### **Optimización de Desarrollo**
- **Ubicación óptima de pozos**: Encontrar mejores localizaciones para maximizar recuperación
- **Estrategias de inyección**: Optimizar tasas y timing de inyección de agua
- **Secuenciamiento de desarrollo**: Determinar orden óptimo de perforación de pozos

#### **Análisis de Sensibilidad Acelerado**
- **Estudios paramétricos**: Evaluar impacto de propiedades de roca en producción
- **Análisis de incertidumbre**: Cuantificar rango de resultados posibles
- **Screening de escenarios**: Identificar casos más prometedores para análisis detallado

### **Carga y Acceso a Datos**

El sistema de visualización incluye herramientas para cargar datos de simulación para análisis ML. Ver @docs/project_map.md para detalles técnicos del módulo `util_data_loader.py`.

Los datos se organizan en categorías:
- **Condiciones iniciales**: Estado del reservorio al inicio
- **Campos dinámicos**: Evolución temporal de variables espaciales  
- **Datos de pozos**: Tasas de producción e inyección
- **Métricas calculadas**: Factores de recuperación, eficiencias

## 8.4 Validación de Calidad de Datos

Antes de usar datos para ML, es crucial validar que cumplan restricciones físicas básicas:

#### **Rangos de Variables**
- **Presión**: Debe ser positiva y dentro de rangos geológicos realistas (500-8000 psi)
- **Saturación**: Estrictamente entre 0 y 1 (física de fluidos)
- **Porosidad**: Entre 0.05 y 0.40 para rocas sedimentarias
- **Permeabilidad**: Positiva, típicamente 0.1 a 5000 mD

#### **Conservación de Masa**
- **Balance volumétrico**: Volumen total de fluidos debe mantenerse constante
- **Continuidad**: No debe haber saltos abruptos irreales en campos de presión
- **Producción acumulada**: Debe ser consistente con volúmenes inyectados

#### **Tendencias Esperadas**
- **Decline de presión**: Cerca de pozos productores
- **Avance de saturación**: Desde inyectores hacia productores
- **Compactación**: Correlacionada con decline de presión

### **Preparación para Modelos ML**

#### **Normalización de Variables**
Para entrenar modelos efectivos, las variables deben normalizarse apropiadamente:

- **Presión**: Escalar por presión inicial de referencia
- **Permeabilidad**: Usar escala logarítmica debido a variación de órdenes de magnitud
- **Coordenadas espaciales**: Normalizar por dimensiones del grid
- **Tiempo**: Escalar por tiempo total de simulación

#### **Selección de Variables Relevantes**
No todas las variables son igualmente útiles para predicción:

**Variables clave para modelos de presión:**
- Propiedades de roca (porosidad, permeabilidad)
- Ubicación y tasas de pozos
- Tiempo de simulación
- Condiciones de frontera

**Variables clave para modelos de saturación:**
- Distribución inicial de fluidos
- Patrón de inyección de agua
- Heterogeneidades de permeabilidad
- Curvas de permeabilidad relativa

## 8.5 Workflow de Preparación de Datos

### **Proceso Completo**

El workflow típico para preparar datos de yacimientos para ML incluye:

1. **Extracción de Datos**
   - Cargar resultados de simulación MRST
   - Verificar completitud de datos temporal
   - Validar consistencia entre archivos

2. **Control de Calidad**
   - Verificar rangos físicos de variables
   - Confirmar balance de masa
   - Identificar outliers o datos corruptos

3. **Preparación de Features**
   - Seleccionar variables relevantes para el problema
   - Crear features derivadas (gradientes, promedios)
   - Normalizar variables por rangos físicos

4. **Formateo para ML**
   - Organizar datos en secuencias temporales
   - Dividir en conjuntos de entrenamiento/validación
   - Guardar parámetros de normalización

### **Consideraciones Especiales para Yacimientos**

#### **Tiempo de Simulación**
- Los primeros timesteps pueden tener transitorios no físicos
- Considerar "burn-in period" antes de usar datos para entrenamiento
- El breakthrough marca cambio de régimen importante

#### **Heterogeneidad Espacial**
- Propiedades de roca varían espacialmente de forma correlacionada
- Pozos crean efectos locales que dominan respuesta
- Fronteras del modelo pueden introducir artefactos

## 8.6 Métricas de Evaluación para Modelos de Yacimientos

### **Métricas Técnicas**
- **Error relativo promedio**: Más relevante que error absoluto en yacimientos
- **R² por variable**: Correlación entre predicciones y simulación de referencia
- **Error en breakthrough time**: Precisión en tiempo de llegada de agua

### **Métricas de Ingeniería**
- **Factor de recuperación**: Predicción vs realidad en producción acumulada
- **NPV estimado**: Impacto económico de errores de predicción
- **Ranking de pozos**: Capacidad de identificar mejores localizaciones

### **Herramientas de Implementación**

Para implementar estos conceptos técnicamente, consultar @docs/project_map.md para detalles sobre:
- **`util_data_loader.py`**: Carga y organización de datos de simulación
- **`util_metrics.py`**: Cálculo de métricas de rendimiento del reservorio
- **`util_visualization.py`**: Herramientas de visualización para validación

## 8.7 Mejores Prácticas

### **Recomendaciones para Ingenieros de Yacimientos**

1. **Validación Física Primero**
   - Siempre verificar que los datos de simulación son físicamente consistentes
   - Confirmar balance de masa antes de usar para ML
   - Revisar tendencias esperadas (decline de presión, avance de frentes)

2. **Selección Inteligente de Variables**
   - Usar conocimiento de ingeniería para seleccionar features relevantes
   - Considerar las escalas de tiempo y espacio apropriadas
   - Incluir información de heterogeneidad de yacimiento

3. **Interpretabilidad**
   - Priorizar modelos que permitan entender relaciones físicas
   - Validar predicciones contra expectativas de ingeniería
   - Mantener capacidad de explicar resultados a stakeholders

4. **Integración con Workflow de Ingeniería**
   - Los modelos ML deben complementar, no reemplazar, la simulación
   - Usar ML para screening rápido y simulación para análisis detallado
   - Mantener trazabilidad desde predicciones hasta decisiones de desarrollo

**Fuente**: Para implementación técnica ver @docs/project_map.md

---

*Continúa en [Capítulo 9: Modelos Sustitutos](09_modelos_sustitutos.md)*