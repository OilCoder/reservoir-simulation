# Capítulo 9: Modelos Sustitutos para Simulación de Yacimientos

## 9.1 Introducción

Los modelos sustitutos (surrogate models) son herramientas fundamentales que permiten acelerar el análisis de yacimientos mediante predicciones rápidas basadas en machine learning. Estos modelos aprenden de simulaciones geomecánicas MRST para proporcionar respuestas inmediatas que complementan la simulación tradicional.

### **Objetivos del Capítulo**
- ✅ Comprender los tipos de modelos sustitutos aplicables a yacimientos
- ✅ Identificar cuándo usar cada tipo de modelo según el problema
- ✅ Conocer las aplicaciones prácticas en ingeniería de yacimientos
- ✅ Entender las limitaciones y validación de modelos ML
- ✅ Aprender integración con workflow de ingeniería

## 9.2 Tipos de Modelos Sustitutos en Yacimientos

### **Clasificación por Dominio de Aplicación**

#### **Modelos de Distribución Espacial**
Predicen mapas de variables del reservorio en momentos específicos:

- **Variables objetivo**: Campos de presión, saturación de agua, esfuerzos efectivos
- **Aplicación**: Análisis de heterogeneidad, identificación de zonas barridas
- **Beneficio**: Visualización inmediata de distribuciones sin simulación completa
- **Limitación**: No capturan evolución temporal

#### **Modelos de Evolución Temporal**  
Predicen cómo cambian las variables del yacimiento en el tiempo:

- **Variables objetivo**: Producción acumulada, presión promedio, factor de recobro
- **Aplicación**: Pronósticos de producción, análisis de decline
- **Beneficio**: Predicciones rápidas para estudios económicos
- **Limitación**: Pierden información espacial detallada

#### **Modelos Integrados Espacio-Temporales**
Combinan distribución espacial y evolución temporal:

- **Variables objetivo**: Evolución completa de campos de reservorio
- **Aplicación**: Estudios de optimización, análisis de sensibilidad
- **Beneficio**: Predicción completa del comportamiento del yacimiento
- **Limitación**: Mayor complejidad de entrenamiento y validación

### **Clasificación por Variable de Interés**

#### **Modelos de Presión**
- **Objetivo**: Predecir distribución y evolución de presión de poro
- **Aplicaciones**: Análisis de drawdown, identificación de compartimientos
- **Variables clave**: Propiedades de roca, ubicación de pozos, tasas de producción
- **Validación**: Conservación de masa, gradientes físicamente consistentes

#### **Modelos de Saturación**  
- **Objetivo**: Predecir avance de frentes de agua y breakthrough
- **Aplicaciones**: Optimización de inyección, predicción de corte de agua
- **Variables clave**: Permeabilidades relativas, heterogeneidad, patrón de inyección
- **Validación**: Monotonía de frentes, balance volumétrico

#### **Modelos de Compactación**
- **Objetivo**: Predecir cambios geomecánicos y subsidencia
- **Aplicaciones**: Análisis de integridad de pozos, predicción de subsidencia
- **Variables clave**: Propiedades geomecánicas, decline de presión
- **Validación**: Esfuerzos efectivos, deformaciones físicamente realizables

#### **Modelos de Productividad**
- **Objetivo**: Predecir tasas de producción e inyección
- **Aplicaciones**: Optimización de desarrollo, estudios económicos
- **Variables clave**: Índices de productividad, presiones de fondo
- **Validación**: Consistencia con curvas IPR, límites operacionales

## 9.3 Tecnologías de Modelos Sustitutos

### **Redes Neuronales Convolucionales (CNN)**

**Aplicación en Yacimientos:**
- Ideal para predecir distribuciones espaciales de presión y saturación
- Aprovecha la estructura espacial 2D/3D del grid de simulación
- Preserva patrones locales y continuidad espacial

**Ventajas para Ingeniería:**
- Captura heterogeneidades geológicas complejas
- Preserva gradientes de presión importantes para flujo
- Eficiente para mapeo de propiedades de roca

**Limitaciones:**
- Requiere grids estructurados para funcionar óptimamente
- No captura física explícitamente (solo por aprendizaje)
- Necesita grandes volúmenes de datos de entrenamiento

### **Redes LSTM (Long Short-Term Memory)**

**Aplicación en Yacimientos:**
- Ideal para predecir evolución temporal de producción
- Captura tendencias de largo plazo y patrones estacionales
- Útil para pronósticos de decline y breakthrough timing

**Ventajas para Ingeniería:**
- Aprende patrones temporales complejos automáticamente
- Maneja multiple variables de entrada simultáneamente
- Excelente para estudios de sensibilidad temporal

**Limitaciones:**
- Pierde información espacial detallada
- Vulnerable a cambios operacionales abruptos
- Difícil interpretación de patrones aprendidos

### **Arquitecturas U-Net**

**Aplicación en Yacimientos:**
- Especializada en detectar y predecir frentes de saturación
- Excelente para breakthrough prediction y water coning
- Preserva discontinuidades importantes en flujo multifásico

**Ventajas para Ingeniería:**
- Detecta frentes de flujo con alta precisión
- Preserva características geológicas (fallas, barreras)
- Útil para optimización de inyección de agua

**Limitaciones:**
- Requiere resolución espacial alta para frentes nítidos
- Computacionalmente costosa para grids grandes
- Necesita training data con frentes bien definidos

### **Physics-Informed Neural Networks (PINNs)**

**Aplicación en Yacimientos:**
- Incorpora ecuaciones de flujo directamente en el entrenamiento
- Garantiza conservación de masa y energía
- Útil cuando hay datos limitados pero conocimiento físico disponible

**Ventajas para Ingeniería:**
- Respeta leyes físicas fundamentales
- Requiere menos datos de entrenamiento
- Predicciones más confiables fuera del rango de entrenamiento

**Limitaciones:**
- Complejidad de implementación significativa
- Requiere conocimiento detallado de ecuaciones gobernantes
- Puede ser lenta para entrenar en problemas complejos

## 9.4 Aplicaciones Prácticas en Ingeniería de Yacimientos

### **Screening de Escenarios de Desarrollo**

Los modelos sustitutos permiten evaluar cientos de configuraciones de desarrollo en minutos:

#### **Optimización de Ubicación de Pozos**
- **Problema**: Encontrar ubicaciones óptimas para maximizar recuperación
- **Modelo**: CNN espacial que predice campos de presión para diferentes configuraciones
- **Beneficio**: Evaluación rápida de múltiples opciones sin simulación completa
- **Aplicación**: Screening inicial antes de simulación detallada

#### **Estrategias de Inyección**
- **Problema**: Determinar tasas y timing óptimos de inyección de agua
- **Modelo**: LSTM que predice breakthrough y factor de recobro
- **Beneficio**: Optimización de water flooding en tiempo real
- **Aplicación**: Ajuste dinámico de operaciones de campo

### **Análisis de Sensibilidad Acelerado**

#### **Impacto de Heterogeneidad**
- **Problema**: Cuantificar efecto de incertidumbre en propiedades de roca
- **Modelo**: CNN que relaciona mapas de permeabilidad con producción
- **Beneficio**: Monte Carlo acelerado para análisis de riesgo
- **Aplicación**: Valuación de activos y toma de decisiones

#### **Estudios Geomecánicos**
- **Problema**: Predecir subsidencia y compactación del reservorio
- **Modelo**: PINN que conserva balance de esfuerzos
- **Beneficio**: Análisis de integridad de pozos sin simulación completa
- **Aplicación**: Mitigación de riesgos geomecánicos

### **Optimización de Desarrollo**

#### **Secuenciamiento de Pozos**
- **Problema**: Determinar orden óptimo de perforación
- **Modelo**: Modelo temporal que predice interferencias entre pozos
- **Beneficio**: Maximización de VPN considerando timing
- **Aplicación**: Planes de desarrollo de largo plazo

#### **Actualización de Modelos**
- **Problema**: Incorporar datos de producción para mejorar predicciones
- **Modelo**: Ensemble de modelos que se actualiza con datos reales
- **Beneficio**: Mejora continua de precisión predictiva
- **Aplicación**: History matching automatizado

## 9.5 Workflow de Implementación

### **Etapa 1: Definición del Problema**

#### **Identificación de Objetivos**
1. **Pregunta de ingeniería**: ¿Qué decisión debe tomarse?
2. **Variables críticas**: ¿Qué necesita predecirse?
3. **Precisión requerida**: ¿Qué error es aceptable?
4. **Tiempo disponible**: ¿Cuánto tiempo hay para obtener respuesta?

#### **Selección de Tipo de Modelo**
- **Problemas espaciales**: Usar CNN o U-Net
- **Problemas temporales**: Usar LSTM o modelos de serie temporal
- **Problemas físicos**: Considerar PINNs si se requiere conservación
- **Problemas mixtos**: Evaluar modelos híbridos

### **Etapa 2: Preparación de Datos**

#### **Generación de Casos de Entrenamiento**
- Ejecutar simulaciones MRST con variaciones en parámetros clave
- Incluir rangos realistas de propiedades de yacimiento
- Asegurar representatividad de condiciones operacionales

#### **Control de Calidad**
- Verificar balance de masa en simulaciones
- Validar rangos físicos de todas las variables
- Confirmar convergencia de soluciones numéricas

### **Etapa 3: Validación de Modelos**

#### **Métricas de Ingeniería**
- **Factor de recuperación**: Precisión en predicción de producción acumulada
- **Breakthrough time**: Error en timing de llegada de agua
- **Distribución de presión**: Conservación de gradientes de flujo

#### **Validación Física**
- Verificar que predicciones respetan leyes de conservación
- Confirmar monotonía de frentes de saturación
- Validar rangos físicos de variables predichas

### **Etapa 4: Integración Operacional**

#### **Deployment en Workflow**
- Integrar modelos en herramientas de visualización existentes
- Crear interfaces amigables para ingenieros de campo
- Establecer protocolos de actualización de modelos

#### **Monitoreo de Performance**
- Comparar predicciones con datos reales de producción
- Actualizar modelos cuando performance degrada
- Mantener trazabilidad de versiones de modelos

## 9.6 Limitaciones y Mejores Prácticas

### **Limitaciones Fundamentales**

#### **Extrapolación**
- Los modelos ML no deben usarse fuera del rango de entrenamiento
- Cambios operacionales significativos requieren reentrenamiento
- Nuevas configuraciones de pozos pueden no estar representadas

#### **Interpretabilidad**
- Modelos complejos actúan como "cajas negras"
- Dificulta identificar causas de predicciones incorrectas
- Requiere validación cruzada con conocimiento de ingeniería

### **Mejores Prácticas**

#### **Validación Continua**
1. **Comparación con datos reales**: Monitorear precisión constantemente
2. **Validación física**: Verificar conservación de masa y energía
3. **Peer review**: Incluir revisión por expertos en yacimientos

#### **Uso Complementario**
- Usar modelos sustitutos para screening rápido
- Validar resultados prometedores con simulación completa
- Mantener simulación tradicional para análisis detallado

#### **Documentación**
- Registrar limitaciones y rangos de aplicabilidad
- Documentar datos de entrenamiento y validación
- Mantener historial de actualizaciones de modelos

### **Consideraciones Técnicas**

Para implementación técnica de estos conceptos, consultar:
- **@docs/project_map.md**: Detalles de arquitectura del sistema
- **Módulos de ML**: Estructura de código y herramientas disponibles
- **Configuración**: Parámetros de modelos en reservoir_config.yaml

## 9.7 Integración con Simulación Tradicional

### **Workflow Híbrido**

#### **Screening + Simulación Detallada**
1. **Fase 1**: Usar modelos sustitutos para evaluar cientos de escenarios
2. **Fase 2**: Seleccionar casos más prometedores (top 5-10%)
3. **Fase 3**: Ejecutar simulación completa en casos seleccionados
4. **Fase 4**: Validar y refinar decisiones finales

#### **Actualización Iterativa**
- Usar resultados de simulación detallada para mejorar modelos
- Expandir conjunto de entrenamiento con nuevos casos
- Actualizar modelos cuando cambian condiciones de yacimiento

### **Valor Agregado**

#### **Reducción de Tiempo**
- **Screening inicial**: De semanas a horas
- **Análisis de sensibilidad**: De días a minutos
- **Optimización**: Iteraciones rápidas en lugar de pocas evaluaciones

#### **Mejora de Decisiones**
- Evaluación de más opciones en tiempo disponible
- Cuantificación de incertidumbre mediante múltiples escenarios
- Identificación de variables críticas mediante sensibilidad automatizada

**Fuente**: Ver @docs/project_map.md para implementación técnica

---

*Continúa en [Capítulo 10: Casos de Uso Prácticos](10_casos_uso.md)*