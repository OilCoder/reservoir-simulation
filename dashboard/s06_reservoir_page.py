#!/usr/bin/env python3
"""
Reservoir Properties Module - GeomechML Dashboard
================================================

Module para visualization de propiedades del reservorio:
- Mapas 2D de porosidad, permeabilidad, pressure
- Visualización 3D de propiedades
- Comparación entre capas
- Distribuciones statistics

Author: GeomechML Team
Date: 2025-07-23
"""

import streamlit as st
import numpy as np
import pandas as pd
import plotly.graph_objects as go
from typing import Dict, Optional, List
import logging

from s01_data_loader import DataLoader
from s02_viz_components import ReservoirVisualizer, StatisticalVisualizer, ColorSchemes

logger = logging.getLogger(__name__)

class ReservoirProperties:
    """Class para visualization de propiedades del reservorio"""
    
    def __init__(self, data_loader: DataLoader, config: Dict):
        """
        Initialize el module de propiedades.
        
        Args:
            data_loader: Instancia del cargador de data
            config: Configuretion del project
        """
        self.data_loader = data_loader
        self.config = config
        
        # Obtener dimensiones del grid
        self.nx = config.get('grid', {}).get('nx', 20)
        self.ny = config.get('grid', {}).get('ny', 20) 
        self.nz = config.get('grid', {}).get('nz', 10)
        
        # Initialize visualizadores
        self.reservoir_viz = ReservoirVisualizer(self.nx, self.ny, self.nz)
        self.stats_viz = StatisticalVisualizer()
        
        # Variables available y sus propiedades
        self.variables_info = {
            'porosity': {
                'name': 'Porosidad',
                'units': '[-]',
                'colorscale': ColorSchemes.POROSITY,
                'description': 'Fracción de espacio poroso en la roca'
            },
            'permeability': {
                'name': 'Permeabilidad',
                'units': '[mD]',
                'colorscale': ColorSchemes.PERMEABILITY,
                'description': 'Capacidad de la roca para transmit fluidos'
            },
            'pressure': {
                'name': 'Pressure',
                'units': '[psi]',
                'colorscale': ColorSchemes.PRESSURE,
                'description': 'Pressure de poro en el reservorio'
            },
            'water_saturation': {
                'name': 'Saturación de Agua',
                'units': '[-]',
                'colorscale': ColorSchemes.SATURATION,
                'description': 'Fracción de agua en el espacio poroso'
            },
            'effective_stress': {
                'name': 'Esfuerzo Efectivo',
                'units': '[psi]',
                'colorscale': ColorSchemes.STRESS,
                'description': 'Esfuerzo efectivo en la matriz rocosa'
            }
        }
    
    def render(self):
        """Render the reservoir properties page"""
        
        st.markdown('<h2 class="section-header">🗻 Reservoir Properties</h2>', 
                   unsafe_allow_html=True)
        
        # Controles de selección
        self._render_controls()
        
        st.markdown("---")
        
        # Load data según selección
        self._render_property_visualization()
        
        st.markdown("---")
        
        # Analysis estadístico
        self._render_statistical_analysis()
    
    def _render_controls(self):
        """Render controles de selección"""
        
        st.markdown("### ⚙️ Visualization Controls")
        
        col1, col2, col3, col4 = st.columns(4)
        
        with col1:
            # Selección de variable
            available_vars = list(self.variables_info.keys())
            selected_var = st.selectbox(
                "📊 Propiedad a visualize:",
                available_vars,
                format_func=lambda x: self.variables_info[x]['name']
            )
            st.session_state.selected_property = selected_var
        
        with col2:
            # Selección de timestep
            temporal_data = self._get_temporal_info()
            if temporal_data and len(temporal_data) > 1:
                timestep = st.selectbox(
                    "⏰ Timestep:",
                    range(len(temporal_data)),
                    index=len(temporal_data)-1,  # Último timestep por defecto
                    format_func=lambda x: f"T{x+1} ({temporal_data[x]:.1f} días)"
                )
                st.session_state.selected_timestep = timestep
            else:
                st.info("Usando data statics")
                st.session_state.selected_timestep = None
        
        with col3:
            # Selección de capa para visualization 2D
            layer = st.selectbox(
                "🏔️ Capa (para vista 2D):",
                range(self.nz),
                index=0,
                format_func=lambda x: f"Capa {x+1}"
            )
            st.session_state.selected_layer = layer
        
        with col4:
            # Tipo de visualization
            viz_type = st.selectbox(
                "📈 Tipo de visualization:",
                ["2D Heatmap", "3D Volume", "Comparación de Capas", "Todas las Vistas"],
                index=0
            )
            st.session_state.viz_type = viz_type
        
        # Mostrar information de la variable seleccionada
        var_info = self.variables_info[selected_var]
        st.info(f"**{var_info['name']}** {var_info['units']}: {var_info['description']}")
    
    def _render_property_visualization(self):
        """Render visualization de la propiedad seleccionada"""
        
        selected_var = st.session_state.get('selected_property', 'porosity')
        timestep = st.session_state.get('selected_timestep', None)
        layer = st.session_state.get('selected_layer', 0)
        viz_type = st.session_state.get('viz_type', '2D Heatmap')
        
        # Load data
        data = self._load_property_data(selected_var, timestep)
        
        if data is None:
            st.error(f"❌ Could not load los data para {selected_var}")
            return
        
        var_info = self.variables_info[selected_var]
        
        st.markdown(f"### 📊 Visualización: {var_info['name']}")
        
        if viz_type == "2D Heatmap":
            self._render_2d_heatmap(data, var_info, layer)
            
        elif viz_type == "3D Volume":
            self._render_3d_volume(data, var_info)
            
        elif viz_type == "Comparación de Capas":
            self._render_layer_comparison(data, var_info)
            
        elif viz_type == "Todas las Vistas":
            # Mostrar todas las visualizaciones
            col1, col2 = st.columns(2)
            
            with col1:
                st.markdown("#### 🗺️ Vista 2D")
                fig_2d = self.reservoir_viz.create_2d_heatmap(
                    data, var_info['name'], var_info['colorscale'], var_info['units'], layer
                )
                st.plotly_chart(fig_2d, use_container_width=True)
            
            with col2:
                st.markdown("#### 📊 Distribución")
                fig_hist = self.stats_viz.create_histogram(
                    data, var_info['name'], units=var_info['units']
                )
                st.plotly_chart(fig_hist, use_container_width=True)
            
            # Vista 3D completa
            st.markdown("#### 🎯 Vista 3D")
            if data.ndim == 3:
                fig_3d = self.reservoir_viz.create_3d_volume(
                    data, var_info['name'], var_info['colorscale'], var_info['units']
                )
                st.plotly_chart(fig_3d, use_container_width=True)
            else:
                st.info("Visualización 3D requiere data tridimensionales")
    
    def _render_2d_heatmap(self, data: np.ndarray, var_info: Dict, layer: int):
        """Render mapa de calor 2D"""
        
        col1, col2 = st.columns([3, 1])
        
        with col1:
            fig = self.reservoir_viz.create_2d_heatmap(
                data, var_info['name'], var_info['colorscale'], var_info['units'], layer
            )
            st.plotly_chart(fig, use_container_width=True)
        
        with col2:
            st.markdown("#### 📊 Estadísticas")
            
            # Extraer data de la capa
            if data.ndim == 3:
                layer_data = data[:, :, layer]
            elif data.ndim == 2:
                layer_data = data
            else:
                layer_data = data.reshape(self.ny, self.nx)
            
            # Calculate statistics
            stats = {
                'Mínimo': f"{np.min(layer_data):.3f}",
                'Máximo': f"{np.max(layer_data):.3f}",
                'Promedio': f"{np.mean(layer_data):.3f}",
                'Mediana': f"{np.median(layer_data):.3f}",
                'Desv. Est.': f"{np.std(layer_data):.3f}",
                'Celdas': f"{layer_data.size:,}"
            }
            
            for key, value in stats.items():
                st.metric(key, value)
    
    def _render_3d_volume(self, data: np.ndarray, var_info: Dict):
        """Render visualization 3D volumétrica"""
        
        if data.ndim == 3:
            fig = self.reservoir_viz.create_3d_volume(
                data, var_info['name'], var_info['colorscale'], var_info['units']
            )
            st.plotly_chart(fig, use_container_width=True)
            
            # Controles adicionales para 3D
            with st.expander("⚙️ Controles 3D", expanded=False):
                st.markdown("""
                **Navegación 3D:**
                - 🖱️ **Rotar:** Clic izquierdo + arrastrar
                - 🔍 **Zoom:** Rueda del mouse
                - 📱 **Mover:** Clic derecho + arrastrar
                - 🎯 **Reset:** Doble clic
                """)
        else:
            st.info("⚠️ La visualization 3D requiere data tridimensionales")
    
    def _render_layer_comparison(self, data: np.ndarray, var_info: Dict):
        """Render comparación entre capas"""
        
        if data.ndim == 3:
            fig = self.reservoir_viz.create_layer_comparison(
                data, var_info['name'], var_info['colorscale'], var_info['units']
            )
            st.plotly_chart(fig, use_container_width=True)
            
            # Tabla con statistics por capa
            st.markdown("#### 📋 Statistics per Layer")
            
            layer_stats = []
            for i in range(data.shape[2]):
                layer_data = data[:, :, i]
                layer_stats.append({
                    'Capa': i + 1,
                    'Mínimo': f"{np.min(layer_data):.3f}",
                    'Máximo': f"{np.max(layer_data):.3f}",
                    'Promedio': f"{np.mean(layer_data):.3f}",
                    'Desv. Est.': f"{np.std(layer_data):.3f}"
                })
            
            stats_df = pd.DataFrame(layer_stats)
            st.dataframe(stats_df, hide_index=True, use_container_width=True)
        else:
            st.info("⚠️ La comparación de capas requiere data tridimensionales")
    
    def _render_statistical_analysis(self):
        """Render analysis estadístico"""
        
        st.markdown("### 📈 Statistical Analysis")
        
        selected_var = st.session_state.get('selected_property', 'porosity')
        timestep = st.session_state.get('selected_timestep', None)
        
        # Load data
        data = self._load_property_data(selected_var, timestep)
        
        if data is None:
            st.error("❌ Could not load los data para analysis estadístico")
            return
        
        var_info = self.variables_info[selected_var]
        
        col1, col2 = st.columns(2)
        
        with col1:
            # Histograma
            st.markdown("#### 📊 Value Distribution")
            fig_hist = self.stats_viz.create_histogram(
                data, var_info['name'], units=var_info['units']
            )
            st.plotly_chart(fig_hist, use_container_width=True)
        
        with col2:
            # Estadísticas detalladas
            st.markdown("#### 🔍 Detailed Statistics")
            
            flat_data = data.flatten()
            
            stats_detailed = {
                'Parámetro': [
                    'Número de valores',
                    'Mínimo',
                    'Percentil 25%',
                    'Mediana (P50)',
                    'Percentil 75%',
                    'Máximo',
                    'Promedio',
                    'Desviación estándar',
                    'Coeficiente de variación',
                    'Asimetría',
                    'Curtosis'
                ],
                'Valor': [
                    f"{len(flat_data):,}",
                    f"{np.min(flat_data):.4f}",
                    f"{np.percentile(flat_data, 25):.4f}",
                    f"{np.median(flat_data):.4f}",
                    f"{np.percentile(flat_data, 75):.4f}",
                    f"{np.max(flat_data):.4f}",
                    f"{np.mean(flat_data):.4f}",
                    f"{np.std(flat_data):.4f}",
                    f"{np.std(flat_data)/np.mean(flat_data):.4f}",
                    f"{self._calculate_skewness(flat_data):.4f}",
                    f"{self._calculate_kurtosis(flat_data):.4f}"
                ]
            }
            
            stats_df = pd.DataFrame(stats_detailed)
            st.dataframe(stats_df, hide_index=True, use_container_width=True)
        
        # Comparación entre propiedades (si hay múltiples available)
        if len(self.variables_info) > 1:
            self._render_property_correlation()
    
    def _render_property_correlation(self):
        """Render analysis de correlation entre propiedades"""
        
        st.markdown("#### 🔗 Property Correlation")
        
        # Intentar load múltiples propiedades
        timestep = st.session_state.get('selected_timestep', None)
        
        correlation_data = {}
        for var_name in self.variables_info.keys():
            data = self._load_property_data(var_name, timestep)
            if data is not None:
                correlation_data[self.variables_info[var_name]['name']] = data.flatten()
        
        if len(correlation_data) > 1:
            # Crear DataFrame para correlation
            corr_df = pd.DataFrame(correlation_data)
            
            # Matriz de correlation
            fig_corr = self.stats_viz.create_correlation_matrix(
                corr_df, "Matriz de Property Correlation"
            )
            st.plotly_chart(fig_corr, use_container_width=True)
            
            # Tabla de correlaciones
            corr_matrix = corr_df.corr()
            st.markdown("##### 📋 Correlation Coefficients")
            st.dataframe(corr_matrix.round(3), use_container_width=True)
        else:
            st.info("Se necesitan al menos 2 propiedades cargadas para analysis de correlation")
    
    def _load_property_data(self, variable: str, timestep: Optional[int] = None) -> Optional[np.ndarray]:
        """
        Load data de una propiedad específica.
        
        Args:
            variable: Nombre de la variable
            timestep: Timestep específico (None para data statics)
            
        Returns:
            Array con los data o None si hay error
        """
        try:
            # Intentar load desde data dynamics primero
            if timestep is not None:
                dynamic_data = self.data_loader.get_spatial_data(timestep)
                if dynamic_data and variable in dynamic_data:
                    return dynamic_data[variable]
            
            # Intentar load desde data statics
            static_data = self.data_loader.get_static_data()
            if static_data and variable in static_data:
                return static_data[variable]
            
            # Intentar load desde data iniciales
            initial_data = self.data_loader.get_initial_data()
            if initial_data and variable in initial_data:
                return initial_data[variable]
            
            logger.warning(f"Variable {variable} no encontrada en ningún dataset")
            return None
            
        except Exception as e:
            logger.error(f"Error cargando data para {variable}: {e}")
            return None
    
    def _get_temporal_info(self) -> Optional[List[float]]:
        """Obtener information temporal available"""
        try:
            temporal_df = self.data_loader.get_temporal_data()
            if temporal_df is not None and 'time' in temporal_df.columns:
                return temporal_df['time'].tolist()
            return None
        except:
            return None
    
    def _calculate_skewness(self, data: np.ndarray) -> float:
        """Calculate asimetría de los data"""
        mean = np.mean(data)
        std = np.std(data)
        return np.mean(((data - mean) / std) ** 3)
    
    def _calculate_kurtosis(self, data: np.ndarray) -> float:
        """Calculate curtosis de los data"""
        mean = np.mean(data)
        std = np.std(data)
        return np.mean(((data - mean) / std) ** 4) - 3