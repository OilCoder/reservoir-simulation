#!/usr/bin/env python3
"""
Simulation Overview Module - GeomechML Dashboard
==============================================

Module para show el resumen general de la simulación incluyendo:
- Información del grid y configuretion
- Ubicación de pozos
- Métricas clave de la simulación
- Timeline de la simulación

Author: GeomechML Team
Date: 2025-07-23
"""

import streamlit as st
import numpy as np
import pandas as pd
import plotly.graph_objects as go
from plotly.subplots import make_subplots
from typing import Dict, List, Optional
import logging

from s01_data_loader import DataLoader, ConfigLoader
from s02_viz_components import ReservoirVisualizer, WellVisualizer, PlotUtils, TimeSeriesVisualizer

logger = logging.getLogger(__name__)

class SimulationOverview:
    """Class to generate simulation overview"""
    
    def __init__(self, data_loader: DataLoader, config: Dict):
        """
        Initialize el overview de simulación.
        
        Args:
            data_loader: Instancia del cargador de data
            config: Configuretion del project
        """
        self.data_loader = data_loader
        self.config = config
        self.grid_config = config.get('grid', {})
        self.wells_config = config.get('wells', {})
        self.sim_config = config.get('simulation', {})
        self.metadata = config.get('metadata', {})
        
        # Obtener dimensiones del grid
        self.nx = self.grid_config.get('nx', 20)
        self.ny = self.grid_config.get('ny', 20)
        self.nz = self.grid_config.get('nz', 10)
        
        # Initialize visualizadores
        self.reservoir_viz = ReservoirVisualizer(self.nx, self.ny, self.nz)
        self.well_viz = WellVisualizer()
        self.ts_viz = TimeSeriesVisualizer()
    
    def render(self):
        """Render the overview page"""
        
        st.markdown('<h2 class="section-header">🏠 General Simulation Overview</h2>', 
                   unsafe_allow_html=True)
        
        # Section 1: Key metrics
        self._render_key_metrics()
        
        st.markdown("---")
        
        # Section 2: Grid and wells configuration
        col1, col2 = st.columns(2)
        
        with col1:
            self._render_grid_info()
            
        with col2:
            self._render_wells_info()
        
        st.markdown("---")
        
        # Section 3: Wells maps and base properties
        self._render_field_overview()
        
        st.markdown("---")
        
        # Section 4: Simulation timeline
        self._render_simulation_timeline()
        
        st.markdown("---")
        
        # Section 5: Available data summary
        self._render_data_summary()
    
    def _render_key_metrics(self):
        """Render key simulation metrics"""
        
        st.markdown("### 📊 Key Metrics")
        
        # Create columns for metrics
        col1, col2, col3, col4 = st.columns(4)
        
        # Calculate basic metrics
        total_cells = self.nx * self.ny * self.nz
        total_time = self.sim_config.get('total_time', 0)
        num_timesteps = self.sim_config.get('num_timesteps', 0)
        num_producers = len(self.wells_config.get('producers', []))
        num_injectors = len(self.wells_config.get('injectors', []))
        
        with col1:
            st.metric(
                label="🔢 Total de Celdas",
                value=f"{total_cells:,}",
                help=f"Grid de {self.nx}×{self.ny}×{self.nz} celdas"
            )
        
        with col2:
            st.metric(
                label="⏱️ Tiempo de Simulación",
                value=f"{total_time:,.0f} días",
                delta=f"{total_time/365:.1f} años"
            )
        
        with col3:
            st.metric(
                label="📈 Timesteps",
                value=f"{num_timesteps:,}",
                help=f"Timestep average: {total_time/num_timesteps:.1f} días"
            )
        
        with col4:
            st.metric(
                label="🛢️ Pozos Totales",
                value=f"{num_producers + num_injectors}",
                delta=f"{num_producers}P + {num_injectors}I"
            )
        
        # Additional reservoir metrics
        col5, col6, col7, col8 = st.columns(4)
        
        # Get geological layer information
        rock_layers = self.config.get('rock', {}).get('layers', [])
        num_layers = len(rock_layers)
        
        # Calculate profundidad total
        if rock_layers:
            min_depth = min(layer['depth_range'][0] for layer in rock_layers)
            max_depth = max(layer['depth_range'][1] for layer in rock_layers)
            total_depth = max_depth - min_depth
        else:
            min_depth = max_depth = total_depth = 0
        
        with col5:
            st.metric(
                label="🗻 Capas Geológicas",
                value=f"{num_layers}",
                help="Número de capas de roca definidas"
            )
        
        with col6:
            st.metric(
                label="📏 Profundidad Total",
                value=f"{total_depth:.0f} ft",
                help=f"Desde {min_depth:.0f} ft hasta {max_depth:.0f} ft"
            )
        
        with col7:
            # Porosidad average
            avg_porosity = np.mean([layer.get('porosity', 0) for layer in rock_layers])
            st.metric(
                label="🕳️ Porosidad Promedio",
                value=f"{avg_porosity:.2f}",
                help="Porosidad average de todas las capas"
            )
        
        with col8:
            # Permeabilidad average
            avg_perm = np.mean([layer.get('permeability', 0) for layer in rock_layers])
            st.metric(
                label="🌊 Permeabilidad Promedio",
                value=f"{avg_perm:.1f} mD",
                help="Permeabilidad average de todas las capas"
            )
    
    def _render_grid_info(self):
        """Render information del grid"""
        
        st.markdown("### 🔢 Configuretion del Grid")
        
        # Crear table con information del grid
        grid_data = {
            'Parámetro': [
                'Dimensiones (nx × ny × nz)',
                'Tamaño de celda X',
                'Tamaño de celda Y', 
                'Número de capas',
                'Total de celdas activas',
                'Volumen total del grid'
            ],
            'Valor': [
                f"{self.nx} × {self.ny} × {self.nz}",
                f"{self.grid_config.get('dx', 0):.1f} ft",
                f"{self.grid_config.get('dy', 0):.1f} ft",
                f"{self.nz}",
                f"{self.nx * self.ny * self.nz:,}",
                f"{self._calculate_grid_volume():,.0f} ft³"
            ]
        }
        
        grid_df = pd.DataFrame(grid_data)
        st.dataframe(grid_df, hide_index=True, use_container_width=True)
        
        # Layer information
        if 'dz' in self.grid_config:
            st.markdown("#### 📏 Espesor de Capas")
            dz_values = self.grid_config['dz']
            
            # Crear chart de barras para espesores de capas
            fig = go.Figure(data=[
                go.Bar(
                    x=[f"Capa {i+1}" for i in range(len(dz_values))],
                    y=dz_values,
                    marker_color='lightblue',
                    marker_line_color='navy',
                    marker_line_width=1.5
                )
            ])
            
            fig.update_layout(
                title="Espesor por Capa",
                xaxis_title="Capa",
                yaxis_title="Espesor [ft]",
                height=300,
                margin=dict(l=20, r=20, t=40, b=20)
            )
            
            st.plotly_chart(fig, use_container_width=True)
    
    def _render_wells_info(self):
        """Render information de pozos"""
        
        st.markdown("### 🛢️ Configuretion de Pozos")
        
        producers = self.wells_config.get('producers', [])
        injectors = self.wells_config.get('injectors', [])
        
        # Resumen de pozos
        wells_summary = {
            'Tipo': ['Productores', 'Inyectores', 'Total'],
            'Cantidad': [len(producers), len(injectors), len(producers) + len(injectors)]
        }
        
        wells_df = pd.DataFrame(wells_summary)
        st.dataframe(wells_df, hide_index=True, use_container_width=True)
        
        # Detalles de pozos productores
        if producers:
            st.markdown("#### 🔴 Pozos Productores")
            prod_data = []
            for well in producers:
                prod_data.append({
                    'Nombre': well.get('name', ''),
                    'Ubicación (i,j)': f"({well.get('location', [0,0])[0]}, {well.get('location', [0,0])[1]})",
                    'Control': well.get('control_type', ''),
                    'BHP Objetivo': f"{well.get('target_bhp', 0):.0f} psi"
                })
            
            prod_df = pd.DataFrame(prod_data)
            st.dataframe(prod_df, hide_index=True, use_container_width=True)
        
        # Detalles de pozos inyectores
        if injectors:
            st.markdown("#### 🔵 Pozos Inyectores")
            inj_data = []
            for well in injectors:
                inj_data.append({
                    'Nombre': well.get('name', ''),
                    'Ubicación (i,j)': f"({well.get('location', [0,0])[0]}, {well.get('location', [0,0])[1]})",
                    'Control': well.get('control_type', ''),
                    'Tasa Objetivo': f"{well.get('target_rate', 0):.0f} bbl/día"
                })
            
            inj_df = pd.DataFrame(inj_data)
            st.dataframe(inj_df, hide_index=True, use_container_width=True)
    
    def _render_field_overview(self):
        """Render vista general del campo"""
        
        st.markdown("### 🗺️ Vista General del Campo")
        
        col1, col2 = st.columns(2)
        
        with col1:
            # Mapa de pozos
            producers = self.wells_config.get('producers', [])
            injectors = self.wells_config.get('injectors', [])
            
            # Intentar get data de porosidad como fondo
            try:
                static_data = self.data_loader.get_static_data()
                if static_data and 'porosity' in static_data:
                    porosity_data = static_data['porosity']
                    if porosity_data.ndim == 3:
                        background_data = porosity_data[:, :, 0]  # Primera capa
                    elif porosity_data.ndim == 2:
                        background_data = porosity_data
                    else:
                        background_data = None
                else:
                    background_data = None
            except:
                background_data = None
            
            well_map = self.well_viz.create_well_map(
                producers, injectors, 
                self.nx, self.ny,
                background_data
            )
            
            st.plotly_chart(well_map, use_container_width=True)
        
        with col2:
            # Geological information by layers
            st.markdown("#### 🗻 Reservoir Stratigraphy")
            
            rock_layers = self.config.get('rock', {}).get('layers', [])
            if rock_layers:
                # Crear chart estratichart
                fig = go.Figure()
                
                colors = ['#8B4513', '#DAA520', '#696969', '#F4A460', '#D2B48C', 
                         '#CD853F', '#A0522D', '#2F4F4F', '#DEB887', '#BC8F8F']
                
                y_pos = 0
                for i, layer in enumerate(rock_layers):
                    thickness = layer.get('thickness', 0)
                    color = colors[i % len(colors)]
                    
                    fig.add_trace(go.Bar(
                        x=[layer.get('name', f'Capa {i+1}')],
                        y=[thickness],
                        base=y_pos,
                        marker_color=color,
                        name=layer.get('lithology', 'Desconocido'),
                        hovertemplate=f"<b>{layer.get('name')}</b><br>" +
                                    f"Litología: {layer.get('lithology', 'N/A')}<br>" +
                                    f"Espesor: {thickness} ft<br>" +
                                    f"Porosidad: {layer.get('porosity', 0):.3f}<br>" +
                                    f"Permeabilidad: {layer.get('permeability', 0):.1f} mD<extra></extra>"
                    ))
                    
                    y_pos += thickness
                
                fig.update_layout(
                    title="Columna Estratigráfica",
                    xaxis_title="",
                    yaxis_title="Profundidad [ft]",
                    height=400,
                    showlegend=False,
                    margin=dict(l=20, r=20, t=40, b=20)
                )
                
                # Invertir eje Y para show profundidad creciente hacia abajo
                fig.update_yaxes(autorange="reversed")
                
                st.plotly_chart(fig, use_container_width=True)
            else:
                st.info("No information de capas geológicas available")
    
    def _render_simulation_timeline(self):
        """Render simulation timeline"""
        
        st.markdown("### ⏱️ Simulation Timeline")
        
        # Temporal information
        total_time = self.sim_config.get('total_time', 3650)
        num_timesteps = self.sim_config.get('num_timesteps', 500)
        timestep_type = self.sim_config.get('timestep_type', 'linear')
        
        col1, col2 = st.columns(2)
        
        with col1:
            # Timeline information
            timeline_info = {
                'Parámetro': [
                    'Tiempo total de simulación',
                    'Número de timesteps',
                    'Tipo de timestep',
                    'Timestep average',
                    'Timestep inicial estimado',
                    'Timestep final estimado'
                ],
                'Valor': [
                    f"{total_time:,.0f} días ({total_time/365:.1f} años)",
                    f"{num_timesteps:,}",
                    timestep_type.capitalize(),
                    f"{total_time/num_timesteps:.2f} días",
                    f"{self._estimate_initial_timestep():.2f} días",
                    f"{self._estimate_final_timestep():.2f} días"
                ]
            }
            
            timeline_df = pd.DataFrame(timeline_info)
            st.dataframe(timeline_df, hide_index=True, use_container_width=True)
        
        with col2:
            # Timestep distribution chart
            if timestep_type == 'linear':
                timesteps = np.linspace(total_time/num_timesteps, total_time/num_timesteps, num_timesteps)
            elif timestep_type == 'logarithmic':
                multiplier = self.sim_config.get('timestep_multiplier', 1.1)
                timesteps = self._generate_log_timesteps(total_time, num_timesteps, multiplier)
            else:
                timesteps = np.linspace(1, total_time/num_timesteps * 2, num_timesteps)
            
            fig = go.Figure()
            fig.add_trace(go.Scatter(
                x=np.arange(1, num_timesteps + 1),
                y=timesteps,
                mode='lines+markers',
                name='Tamaño de timestep',
                line=dict(color='blue', width=2),
                marker=dict(size=4)
            ))
            
            fig.update_layout(
                title="Distribución de Timesteps",
                xaxis_title="Número de Timestep",
                yaxis_title="Tamaño del Timestep [días]",
                height=300,
                margin=dict(l=20, r=20, t=40, b=20)
            )
            
            st.plotly_chart(fig, use_container_width=True)
    
    def _render_data_summary(self):
        """Render resumen de data available"""
        
        st.markdown("### 📁 Resumen de Data Disponibles")
        
        # Obtener files available
        available_files = self.data_loader.get_available_files()
        
        col1, col2 = st.columns(2)
        
        with col1:
            # File table by category
            summary_data = []
            for category, files in available_files.items():
                summary_data.append({
                    'Categoría': category.capitalize(),
                    'Archivos': len(files),
                    'Estado': '✅ Disponible' if files else '❌ No available'
                })
            
            summary_df = pd.DataFrame(summary_data)
            st.dataframe(summary_df, hide_index=True, use_container_width=True)
        
        with col2:
            # Cache information
            cache_info = self.data_loader.get_cache_info()
            
            st.markdown("#### 💾 Cache Status")
            st.write(f"**Archivos en caché:** {cache_info['cached_files']}")
            st.write(f"**Tamaño total:** {cache_info['total_size_mb']:.2f} MB")
            
            if st.button("🗑️ Limpiar Caché"):
                self.data_loader.clear_cache()
                st.success("Caché limpiada successfully")
                st.rerun()
        
        # Expandible con detalles de files
        with st.expander("📋 Ver detalles de files available", expanded=False):
            for category, files in available_files.items():
                if files:
                    st.markdown(f"**{category.upper()}:**")
                    for file in files:
                        st.write(f"- {file}")
                else:
                    st.markdown(f"**{category.upper()}:** Sin files")
    
    def _calculate_grid_volume(self) -> float:
        """Calculate el volumen total del grid"""
        dx = self.grid_config.get('dx', 164.0)
        dy = self.grid_config.get('dy', 164.0)
        dz_values = self.grid_config.get('dz', [10.0] * self.nz)
        
        total_dz = sum(dz_values)
        return self.nx * dx * self.ny * dy * total_dz
    
    def _estimate_initial_timestep(self) -> float:
        """Estimar el timestep inicial"""
        timestep_type = self.sim_config.get('timestep_type', 'linear')
        total_time = self.sim_config.get('total_time', 3650)
        num_timesteps = self.sim_config.get('num_timesteps', 500)
        
        if timestep_type == 'linear':
            return total_time / num_timesteps
        elif timestep_type == 'logarithmic':
            return 0.1  # Típico timestep inicial pequeño
        else:
            return 1.0  # Valor por defecto
    
    def _estimate_final_timestep(self) -> float:
        """Estimar el timestep final"""
        timestep_type = self.sim_config.get('timestep_type', 'linear')
        total_time = self.sim_config.get('total_time', 3650)
        num_timesteps = self.sim_config.get('num_timesteps', 500)
        
        if timestep_type == 'linear':
            return total_time / num_timesteps
        elif timestep_type == 'logarithmic':
            multiplier = self.sim_config.get('timestep_multiplier', 1.1)
            return 0.1 * (multiplier ** (num_timesteps - 1))
        else:
            return total_time / num_timesteps * 2
    
    def _generate_log_timesteps(self, total_time: float, num_steps: int, multiplier: float) -> np.ndarray:
        """Generate logarithmic timesteps"""
        initial_dt = 0.1
        timesteps = []
        current_dt = initial_dt
        
        for i in range(num_steps):
            timesteps.append(current_dt)
            current_dt *= multiplier
        
        # Escalar para que la suma sea igual al tiempo total
        timesteps = np.array(timesteps)
        timesteps = timesteps * (total_time / np.sum(timesteps))
        
        return timesteps