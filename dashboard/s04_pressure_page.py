#!/usr/bin/env python3
"""
Pressure Evolution Module - GeomechML Dashboard
==============================================

Module for pressure evolution analysis:
- Pressure maps at different timesteps
- Temporal pressure analysis by region
- Pressure gradients
- Pressure-geomechanical correlation

Author: GeomechML Team
Date: 2025-07-23
"""

import streamlit as st
import numpy as np
import pandas as pd
import plotly.graph_objects as go
from plotly.subplots import make_subplots
from typing import Dict, Optional, List, Tuple
import logging

from s01_data_loader import DataLoader
from s02_viz_components import ReservoirVisualizer, TimeSeriesVisualizer, ColorSchemes

logger = logging.getLogger(__name__)

class PressureEvolution:
    """Class for pressure evolution analysis"""
    
    def __init__(self, data_loader: DataLoader, config: Dict):
        """
        Initialize the pressure evolution module.
        
        Args:
            data_loader: Data loader instance
            config: Project configuretion
        """
        self.data_loader = data_loader
        self.config = config
        
        # Grid and wells configuretion
        self.nx = config.get('grid', {}).get('nx', 20)
        self.ny = config.get('grid', {}).get('ny', 20)
        self.nz = config.get('grid', {}).get('nz', 10)
        
        self.wells_config = config.get('wells', {})
        self.initial_conditions = config.get('initial_conditions', {})
        
        # Initialize visualizers
        self.reservoir_viz = ReservoirVisualizer(self.nx, self.ny, self.nz)
        self.ts_viz = TimeSeriesVisualizer()
        
        # Load temporal data once
        self.temporal_data = self.data_loader.get_temporal_data()
    
    def render(self):
        """Render the pressure evolution page"""
        
        st.markdown('<h2 class="section-header">📈 Pressure Evolution</h2>', 
                   unsafe_allow_html=True)
        
        if self.temporal_data is None:
            st.error("❌ Could not load temporal pressure data")
            return
        
        # Section 1: Pressure overview
        self._render_pressure_overview()
        
        st.markdown("---")
        
        # Section 2: Temporal evolution
        self._render_temporal_evolution()
        
        st.markdown("---")
        
        # Section 3: Interactive pressure maps
        self._render_pressure_maps()
        
        st.markdown("---")
        
        # Sección 4: Analysis geomecánico
        self._render_geomechanical_analysis()
    
    def _render_pressure_overview(self):
        """Render vista general de pressure"""
        
        st.markdown("### 🌊 Pressure Overview")
        
        # Calculate pressure statistics
        pressure_stats = self._calculate_pressure_statistics()
        
        # Key metrics
        col1, col2, col3, col4 = st.columns(4)
        
        with col1:
            st.metric(
                label="📊 Initial Pressure",
                value=f"{pressure_stats['initial_pressure']:.0f} psi",
                help="Initial reservoir pressure"
            )
        
        with col2:
            st.metric(
                label="📉 Pressure Actual",
                value=f"{pressure_stats['current_pressure']:.0f} psi",
                delta=f"{pressure_stats['pressure_drop']:.0f} psi",
                help="Pressure current average"
            )
        
        with col3:
            st.metric(
                label="⬇️ Caída Máxima",
                value=f"{pressure_stats['max_pressure_drop']:.0f} psi",
                help="Máxima caída de pressure observada"
            )
        
        with col4:
            st.metric(
                label="📍 Pressure Mínima",
                value=f"{pressure_stats['min_pressure']:.0f} psi",
                help="Pressure mínima current en el reservorio"
            )
        
        # Gráficos de evolution
        col1, col2 = st.columns(2)
        
        with col1:
            self._render_pressure_history()
        
        with col2:
            self._render_pressure_distribution()
    
    def _render_temporal_evolution(self):
        """Render evolution temporal de pressure"""
        
        st.markdown("### ⏱️ Evolution Temporal")
        
        # Selector de región de analysis
        analysis_regions = {
            'Todo el Reservorio': 'global',
            'Cerca de Productores': 'near_producers',
            'Cerca de Inyectores': 'near_injectors',
            'Región Central': 'center',
            'Bordes del Reservorio': 'edges'
        }
        
        selected_region = st.selectbox(
            "Región de analysis:",
            list(analysis_regions.keys()),
            index=0
        )
        
        region_key = analysis_regions[selected_region]
        
        # Analysis por capas
        layer_analysis = st.checkbox("Mostrar analysis por capas", value=False)
        
        if layer_analysis:
            self._render_layer_pressure_evolution(region_key)
        else:
            self._render_global_pressure_evolution(region_key)
        
        # Tabla de statistics temporales
        self._render_temporal_statistics(region_key)
    
    def _render_pressure_maps(self):
        """Render mapas de pressure interactivos"""
        
        st.markdown("### 🗺️ Mapas de Pressure")
        
        # Controles de visualization
        col1, col2, col3 = st.columns(3)
        
        with col1:
            # Selector de timestep
            if 'time' in self.temporal_data.columns:
                time_values = self.temporal_data['time'].values
                timestep_idx = st.slider(
                    "Timestep:",
                    min_value=0,
                    max_value=len(time_values) - 1,
                    value=len(time_values) - 1,
                    format=f"T%d"
                )
                current_time = time_values[timestep_idx]
                st.write(f"Tiempo: {current_time:.1f} días")
            else:
                timestep_idx = None
                current_time = 0
        
        with col2:
            # Selector de capa
            layer = st.selectbox(
                "Capa a visualize:",
                range(self.nz),
                index=0,
                format_func=lambda x: f"Capa {x+1}"
            )
        
        with col3:
            # Tipo de mapa
            map_type = st.selectbox(
                "Tipo de mapa:",
                ["Pressure Absoluta", "Caída de Pressure", "Gradiente", "Con Pozos"],
                index=0
            )
        
        # Load data spatiales
        spatial_data = self.data_loader.get_spatial_data(timestep_idx)
        
        if spatial_data is None or 'pressure' not in spatial_data:
            st.error("❌ Could not load data de pressure spatial")
            return
        
        pressure_data = spatial_data['pressure']
        
        # Render según tipo de mapa
        if map_type == "Pressure Absoluta":
            self._render_absolute_pressure_map(pressure_data, layer, current_time)
            
        elif map_type == "Caída de Pressure":
            self._render_pressure_drop_map(pressure_data, layer, current_time)
            
        elif map_type == "Gradiente":
            self._render_pressure_gradient_map(pressure_data, layer, current_time)
            
        elif map_type == "Con Pozos":
            self._render_pressure_map_with_wells(pressure_data, layer, current_time)
    
    def _render_geomechanical_analysis(self):
        """Render geomechanical analysis"""
        
        st.markdown("### 🏗️ Geomechanical Analysis")
        
        # Verificar si hay data de esfuerzo efectivo
        latest_spatial = self.data_loader.get_spatial_data()
        
        if latest_spatial is None:
            st.error("❌ Could not load data spatiales")
            return
        
        has_stress = 'effective_stress' in latest_spatial
        has_porosity = 'porosity' in latest_spatial
        has_pressure = 'pressure' in latest_spatial
        
        if not any([has_stress, has_porosity, has_pressure]):
            st.info("ℹ️ Data geomecánicos no available")
            return
        
        col1, col2 = st.columns(2)
        
        with col1:
            if has_stress and has_pressure:
                self._render_stress_pressure_correlation()
            else:
                st.info("Correlación esfuerzo-pressure no available")
        
        with col2:
            if has_porosity and has_pressure:
                self._render_porosity_pressure_evolution()
            else:
                st.info("Evolution porosidad-pressure no available")
        
        # Analysis de compactación
        if has_stress:
            self._render_compaction_analysis()
    
    def _calculate_pressure_statistics(self) -> Dict:
        """Calculate statistics de pressure"""
        stats = {
            'initial_pressure': 2900.0,  # Desde configuretion
            'current_pressure': 2900.0,
            'pressure_drop': 0.0,
            'max_pressure_drop': 0.0,
            'min_pressure': 2900.0
        }
        
        try:
            # Pressure inicial desde configuretion
            initial_pressure = self.initial_conditions.get('datum_pressure', 2900.0)
            stats['initial_pressure'] = initial_pressure
            
            # Obtener data de pressure current
            latest_spatial = self.data_loader.get_spatial_data()
            if latest_spatial and 'pressure' in latest_spatial:
                pressure_data = latest_spatial['pressure']
                
                stats['current_pressure'] = np.mean(pressure_data)
                stats['min_pressure'] = np.min(pressure_data)
                stats['pressure_drop'] = initial_pressure - stats['current_pressure']
                stats['max_pressure_drop'] = initial_pressure - stats['min_pressure']
        
        except Exception as e:
            logger.warning(f"Error calculando statistics de pressure: {e}")
        
        return stats
    
    def _render_pressure_history(self):
        """Render historial de pressure average"""
        st.markdown("#### 📈 Historial de Pressure Promedio")
        
        # Buscar columnas de pressure en data temporales
        pressure_cols = [col for col in self.temporal_data.columns 
                        if 'pressure' in col.lower() or 'press' in col.lower()]
        
        if not pressure_cols:
            st.info("No data de pressure temporal available")
            return
        
        time_col = self.temporal_data['time'] if 'time' in self.temporal_data.columns else self.temporal_data.index
        
        fig = go.Figure()
        
        for i, col in enumerate(pressure_cols[:3]):  # Máximo 3 series
            fig.add_trace(go.Scatter(
                x=time_col,
                y=self.temporal_data[col],
                mode='lines',
                name=col.replace('_', ' ').title(),
                line=dict(width=2)
            ))
        
        fig.update_layout(
            title="Pressure Evolution",
            xaxis_title="Tiempo [días]",
            yaxis_title="Pressure [psi]",
            height=400,
            legend=dict(x=0.02, y=0.98)
        )
        
        st.plotly_chart(fig, use_container_width=True)
    
    def _render_pressure_distribution(self):
        """Render distribution current de pressure"""
        st.markdown("#### 📊 Current Distribution")
        
        latest_spatial = self.data_loader.get_spatial_data()
        
        if latest_spatial is None or 'pressure' not in latest_spatial:
            st.info("No data spatiales de pressure available")
            return
        
        pressure_data = latest_spatial['pressure'].flatten()
        
        fig = go.Figure(data=[go.Histogram(
            x=pressure_data,
            nbinsx=30,
            marker_color='lightblue',
            marker_line_color='navy',
            marker_line_width=1,
            opacity=0.7
        )])
        
        fig.update_layout(
            title="Distribución de Pressure Actual",
            xaxis_title="Pressure [psi]",
            yaxis_title="Frecuencia",
            height=400
        )
        
        st.plotly_chart(fig, use_container_width=True)
    
    def _render_global_pressure_evolution(self, region: str):
        """Render evolution global de pressure"""
        
        # Para demo, create data sintéticos basados en configuretion
        time_col = self.temporal_data['time'] if 'time' in self.temporal_data.columns else self.temporal_data.index
        
        # Simular evolution de pressure
        initial_pressure = self.initial_conditions.get('datum_pressure', 2900.0)
        pressure_evolution = self._simulate_pressure_evolution(time_col, initial_pressure, region)
        
        fig = go.Figure()
        fig.add_trace(go.Scatter(
            x=time_col,
            y=pressure_evolution,
            mode='lines',
            name=f'Pressure - {region}',
            line=dict(color='blue', width=3)
        ))
        
        # Agregar línea de pressure inicial
        fig.add_hline(
            y=initial_pressure,
            line_dash="dash",
            line_color="red",
            annotation_text="Pressure Inicial"
        )
        
        fig.update_layout(
            title=f"Pressure Evolution - {region.replace('_', ' ').title()}",
            xaxis_title="Tiempo [días]",
            yaxis_title="Pressure [psi]",
            height=400
        )
        
        st.plotly_chart(fig, use_container_width=True)
    
    def _render_layer_pressure_evolution(self, region: str):
        """Render evolution por capas"""
        
        time_col = self.temporal_data['time'] if 'time' in self.temporal_data.columns else self.temporal_data.index
        initial_pressure = self.initial_conditions.get('datum_pressure', 2900.0)
        
        fig = go.Figure()
        
        colors = ['red', 'blue', 'green', 'orange', 'purple', 'brown', 'pink', 'gray', 'olive', 'cyan']
        
        for layer in range(min(self.nz, 5)):  # Máximo 5 capas para claridad
            pressure_evolution = self._simulate_pressure_evolution(
                time_col, initial_pressure, region, layer_factor=0.9 + 0.02 * layer
            )
            
            fig.add_trace(go.Scatter(
                x=time_col,
                y=pressure_evolution,
                mode='lines',
                name=f'Capa {layer + 1}',
                line=dict(color=colors[layer % len(colors)], width=2)
            ))
        
        fig.update_layout(
            title=f"Evolution por Capas - {region.replace('_', ' ').title()}",
            xaxis_title="Tiempo [días]",
            yaxis_title="Pressure [psi]",
            height=400,
            legend=dict(x=0.02, y=0.98)
        )
        
        st.plotly_chart(fig, use_container_width=True)
    
    def _render_temporal_statistics(self, region: str):
        """Render statistics temporales"""
        
        st.markdown("#### 📋 Temporal Statistics")
        
        time_col = self.temporal_data['time'] if 'time' in self.temporal_data.columns else self.temporal_data.index
        initial_pressure = self.initial_conditions.get('datum_pressure', 2900.0)
        
        # Simular data para statistics
        pressure_evolution = self._simulate_pressure_evolution(time_col, initial_pressure, region)
        
        stats_data = {
            'Métrica': [
                'Pressure Inicial [psi]',
                'Pressure Final [psi]',
                'Caída Total [psi]',
                'Caída Promedio [psi/día]',
                'Tiempo de Mayor Caída [días]',
                'Estabilización [días]'
            ],
            'Valor': [
                f"{initial_pressure:.0f}",
                f"{pressure_evolution[-1]:.0f}",
                f"{initial_pressure - pressure_evolution[-1]:.0f}",
                f"{(initial_pressure - pressure_evolution[-1]) / len(time_col):.3f}",
                f"{time_col[np.argmax(np.diff(-pressure_evolution))]:.0f}",
                f"{len(time_col) * 0.8:.0f}"  # Estimation
            ]
        }
        
        stats_df = pd.DataFrame(stats_data)
        st.dataframe(stats_df, hide_index=True, use_container_width=True)
    
    def _render_absolute_pressure_map(self, pressure_data: np.ndarray, layer: int, time: float):
        """Render absolute pressure map"""
        
        fig = self.reservoir_viz.create_2d_heatmap(
            pressure_data, 
            f"Pressure Absoluta - T={time:.1f} días", 
            ColorSchemes.PRESSURE, 
            "psi", 
            layer
        )
        
        st.plotly_chart(fig, use_container_width=True)
    
    def _render_pressure_drop_map(self, pressure_data: np.ndarray, layer: int, time: float):
        """Render pressure drop map"""
        
        # Calculate caída respecto a pressure inicial
        initial_pressure = self.initial_conditions.get('datum_pressure', 2900.0)
        
        if pressure_data.ndim == 3:
            pressure_drop = initial_pressure - pressure_data[:, :, layer]
        elif pressure_data.ndim == 2:
            pressure_drop = initial_pressure - pressure_data
        else:
            pressure_drop = initial_pressure - pressure_data.reshape(self.ny, self.nx)
        
        fig = go.Figure(data=go.Heatmap(
            z=pressure_drop,
            colorscale='Reds',
            colorbar=dict(title="Caída de Pressure [psi]")
        ))
        
        fig.update_layout(
            title=f"Caída de Pressure - T={time:.1f} días",
            xaxis_title="Posición X [grid cells]",
            yaxis_title="Posición Y [grid cells]",
            height=500
        )
        
        st.plotly_chart(fig, use_container_width=True)
    
    def _render_pressure_gradient_map(self, pressure_data: np.ndarray, layer: int, time: float):
        """Render mapa de gradientes de pressure"""
        
        if pressure_data.ndim == 3:
            layer_data = pressure_data[:, :, layer]
        elif pressure_data.ndim == 2:
            layer_data = pressure_data
        else:
            layer_data = pressure_data.reshape(self.ny, self.nx)
        
        # Calculate gradientes
        grad_x = np.gradient(layer_data, axis=1)
        grad_y = np.gradient(layer_data, axis=0)
        grad_magnitude = np.sqrt(grad_x**2 + grad_y**2)
        
        fig = self.reservoir_viz.create_2d_heatmap(
            grad_magnitude,
            f"Gradiente de Pressure - T={time:.1f} días",
            'Plasma',
            "psi/celda",
            0
        )
        
        st.plotly_chart(fig, use_container_width=True)
    
    def _render_pressure_map_with_wells(self, pressure_data: np.ndarray, layer: int, time: float):
        """Render mapa de pressure con ubicación de pozos"""
        
        fig = self.reservoir_viz.create_2d_heatmap(
            pressure_data, 
            f"Pressure con Pozos - T={time:.1f} días", 
            ColorSchemes.PRESSURE, 
            "psi", 
            layer
        )
        
        # Agregar pozos productores
        for well in self.wells_config.get('producers', []):
            loc = well['location']
            fig.add_trace(go.Scatter(
                x=[loc[0]], y=[loc[1]],
                mode='markers+text',
                marker=dict(symbol='circle', size=15, color='red', 
                          line=dict(width=2, color='darkred')),
                text=[well['name']],
                textposition='top center',
                name='Productores',
                showlegend=False
            ))
        
        # Agregar pozos inyectores
        for well in self.wells_config.get('injectors', []):
            loc = well['location']
            fig.add_trace(go.Scatter(
                x=[loc[0]], y=[loc[1]],
                mode='markers+text',
                marker=dict(symbol='square', size=15, color='blue',
                          line=dict(width=2, color='darkblue')),
                text=[well['name']],
                textposition='top center',
                name='Inyectores',
                showlegend=False
            ))
        
        st.plotly_chart(fig, use_container_width=True)
    
    def _render_stress_pressure_correlation(self):
        """Render correlation esfuerzo-pressure"""
        
        st.markdown("#### 🔗 Correlación Esfuerzo-Pressure")
        
        latest_spatial = self.data_loader.get_spatial_data()
        
        if 'effective_stress' in latest_spatial and 'pressure' in latest_spatial:
            stress_data = latest_spatial['effective_stress'].flatten()
            pressure_data = latest_spatial['pressure'].flatten()
            
            fig = go.Figure()
            fig.add_trace(go.Scatter(
                x=pressure_data,
                y=stress_data,
                mode='markers',
                marker=dict(
                    color=pressure_data,
                    colorscale='Viridis',
                    size=4,
                    opacity=0.6
                ),
                name='Data'
            ))
            
            fig.update_layout(
                title="Correlación Esfuerzo Efectivo vs Pressure",
                xaxis_title="Pressure [psi]",
                yaxis_title="Esfuerzo Efectivo [psi]",
                height=400
            )
            
            st.plotly_chart(fig, use_container_width=True)
        else:
            st.info("Data de esfuerzo no available")
    
    def _render_porosity_pressure_evolution(self):
        """Render evolution porosidad-pressure"""
        
        st.markdown("#### 📊 Evolution Porosidad-Pressure")
        
        latest_spatial = self.data_loader.get_spatial_data()
        
        if 'porosity' in latest_spatial and 'pressure' in latest_spatial:
            porosity_data = latest_spatial['porosity'].flatten()
            pressure_data = latest_spatial['pressure'].flatten()
            
            fig = go.Figure()
            fig.add_trace(go.Scatter(
                x=pressure_data,
                y=porosity_data,
                mode='markers',
                marker=dict(
                    color=porosity_data,
                    colorscale='Plasma',
                    size=4,
                    opacity=0.6
                ),
                name='Data'
            ))
            
            fig.update_layout(
                title="Porosidad vs Pressure",
                xaxis_title="Pressure [psi]",
                yaxis_title="Porosidad [-]",
                height=400
            )
            
            st.plotly_chart(fig, use_container_width=True)
        else:
            st.info("Data de porosidad no available")
    
    def _render_compaction_analysis(self):
        """Render compaction analysis"""
        
        st.markdown("#### 🏗️ Compaction Analysis")
        
        # Mostrar information conceptual
        col1, col2 = st.columns(2)
        
        with col1:
            st.markdown("""
            **Efectos Geomecánicos:**
            - ⬇️ Reducción de pressure de poro
            - 📈 Aumento del esfuerzo efectivo  
            - 🗜️ Compactación de la roca
            - 📉 Reducción de porosidad
            - 🌊 Cambios en permeabilidad
            """)
        
        with col2:
            # Gráfico conceptual de compactación
            compaction_time = np.linspace(0, self.temporal_data.shape[0], 100)
            compaction_values = 1 - 0.05 * (1 - np.exp(-compaction_time / 50))
            
            fig = go.Figure()
            fig.add_trace(go.Scatter(
                x=compaction_time,
                y=compaction_values,
                mode='lines',
                name='Porosidad Normalizada',
                line=dict(color='red', width=3)
            ))
            
            fig.update_layout(
                title="Evolution de Compactación (Conceptual)",
                xaxis_title="Tiempo [adimensional]",
                yaxis_title="Porosidad Normalizada",
                height=300
            )
            
            st.plotly_chart(fig, use_container_width=True)
    
    def _simulate_pressure_evolution(self, time_col: np.ndarray, initial_pressure: float, 
                                   region: str, layer_factor: float = 1.0) -> np.ndarray:
        """Simular evolution de pressure para demo"""
        
        # Factores de caída según región
        region_factors = {
            'global': 1.0,
            'near_producers': 1.5,
            'near_injectors': 0.8,
            'center': 1.2,
            'edges': 0.6
        }
        
        factor = region_factors.get(region, 1.0) * layer_factor
        
        # Simulación simplificada de caída exponencial
        normalized_time = time_col / np.max(time_col)
        pressure_drop = initial_pressure * 0.2 * factor * (1 - np.exp(-3 * normalized_time))
        
        return initial_pressure - pressure_drop