#!/usr/bin/env python3
"""
Production Performance Module - GeomechML Dashboard
=================================================

Module para analysis de rendimiento de producción:
- Curvas de producción de pozos
- Analysis de tasas de inyección/producción
- Métricas de eficiencia de barrido
- Mapas de pressure y saturación

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
from s02_viz_components import TimeSeriesVisualizer, ReservoirVisualizer, WellVisualizer, ColorSchemes

logger = logging.getLogger(__name__)

class ProductionPerformance:
    """Class for production performance analysis"""
    
    def __init__(self, data_loader: DataLoader, config: Dict):
        """
        Initialize el module de producción.
        
        Args:
            data_loader: Instancia del cargador de data
            config: Configuretion del project
        """
        self.data_loader = data_loader
        self.config = config
        
        # Configuretion de pozos
        self.wells_config = config.get('wells', {})
        self.producers = self.wells_config.get('producers', [])
        self.injectors = self.wells_config.get('injectors', [])
        
        # Configuretion de simulación
        self.sim_config = config.get('simulation', {})
        self.total_time = self.sim_config.get('total_time', 3650)
        
        # Dimensiones del grid
        self.nx = config.get('grid', {}).get('nx', 20)
        self.ny = config.get('grid', {}).get('ny', 20)
        self.nz = config.get('grid', {}).get('nz', 10)
        
        # Initialize visualizadores
        self.ts_viz = TimeSeriesVisualizer()
        self.reservoir_viz = ReservoirVisualizer(self.nx, self.ny, self.nz)
        self.well_viz = WellVisualizer()
    
    def render(self):
        """Render the production performance page"""
        
        st.markdown('<h2 class="section-header">🛢️ Production Performance</h2>', 
                   unsafe_allow_html=True)
        
        # Verificar disponibilidad de data
        if not self._check_well_data_availability():
            st.warning("⚠️ Data de producción no available. Ejecuta la simulación completa.")
            return
        
        # Sección 1: Resumen de producción
        self._render_production_summary()
        
        st.markdown("---")
        
        # Sección 2: Curvas de producción por pozo
        self._render_well_performance()
        
        st.markdown("---")
        
        # Sección 3: Analysis de eficiencia
        self._render_efficiency_analysis()
        
        st.markdown("---")
        
        # Sección 4: Mapas de saturación y pressure
        self._render_reservoir_evolution()
    
    def _render_production_summary(self):
        """Render resumen general de producción"""
        
        st.markdown("### 📊 Resumen de Producción")
        
        # Load data temporales
        temporal_data = self.data_loader.get_temporal_data()
        
        if temporal_data is None:
            st.error("❌ Could not load data temporales")
            return
        
        # Calculate métricas de producción
        production_metrics = self._calculate_production_metrics(temporal_data)
        
        # Mostrar métricas clave
        col1, col2, col3, col4 = st.columns(4)
        
        with col1:
            st.metric(
                label="🚀 Producción Total",
                value=f"{production_metrics['total_production']:,.0f}",
                delta=f"{production_metrics['total_production']/1000:.1f}k bbl",
                help="Producción acumulada de petróleo"
            )
        
        with col2:
            st.metric(
                label="💧 Inyección Total",
                value=f"{production_metrics['total_injection']:,.0f}",
                delta=f"{production_metrics['total_injection']/1000:.1f}k bbl",
                help="Volumen total inyectado"
            )
        
        with col3:
            st.metric(
                label="⚡ Tasa Promedio",
                value=f"{production_metrics['avg_production_rate']:.1f}",
                delta="bbl/día",
                help="Tasa average de producción"
            )
        
        with col4:
            st.metric(
                label="📈 Factor de Recobro",
                value=f"{production_metrics['recovery_factor']:.2%}",
                help="Porcentaje de petróleo original recuperado"
            )
        
        # Gráfico de producción vs inyección
        col1, col2 = st.columns(2)
        
        with col1:
            self._render_production_history(temporal_data)
        
        with col2:
            self._render_cumulative_production(temporal_data)
    
    def _render_well_performance(self):
        """Render analysis por pozo individual"""
        
        st.markdown("### 🏭 Rendimiento por Pozo")
        
        # Selector de pozo
        all_wells = [(well['name'], 'Productor') for well in self.producers] + \
                   [(well['name'], 'Inyector') for well in self.injectors]
        
        if not all_wells:
            st.info("No pozos configuredos")
            return
        
        selected_well = st.selectbox(
            "Seleccionar pozo:",
            all_wells,
            format_func=lambda x: f"{x[0]} ({x[1]})"
        )
        
        well_name, well_type = selected_well
        
        # Load data del pozo
        well_data = self._get_well_data(well_name)
        
        if well_data is None:
            st.error(f"❌ No se findon data para el pozo {well_name}")
            return
        
        # Información del pozo
        well_info = self._get_well_info(well_name)
        
        col1, col2, col3 = st.columns(3)
        
        with col1:
            st.markdown("#### 📍 Información del Pozo")
            st.write(f"**Nombre:** {well_info['name']}")
            st.write(f"**Tipo:** {well_info['type']}")
            st.write(f"**Ubicación:** {well_info['location']}")
            st.write(f"**Control:** {well_info['control_type']}")
        
        with col2:
            st.markdown("#### 🎯 Parámetros Objetivo")
            if well_type == 'Productor':
                st.write(f"**BHP Objetivo:** {well_info['target_bhp']:.0f} psi")
                if 'target_rate' in well_info:
                    st.write(f"**Tasa Objetivo:** {well_info['target_rate']:.0f} bbl/día")
            else:
                st.write(f"**Tasa Inyección:** {well_info['target_rate']:.0f} bbl/día")
                st.write(f"**BHP Máximo:** {well_info['target_bhp']:.0f} psi")
        
        with col3:
            st.markdown("#### 📊 Métricas Actuales")
            current_rate = well_data['rate'].iloc[-1] if 'rate' in well_data else 0
            current_bhp = well_data['bhp'].iloc[-1] if 'bhp' in well_data else 0
            cumulative = well_data['cumulative'].iloc[-1] if 'cumulative' in well_data else 0
            
            st.write(f"**Tasa Actual:** {current_rate:.1f} bbl/día")
            st.write(f"**BHP Actual:** {current_bhp:.0f} psi")
            st.write(f"**Acumulado:** {cumulative:,.0f} bbl")
        
        # Gráficos del pozo
        self._render_well_plots(well_data, well_name, well_type)
    
    def _render_efficiency_analysis(self):
        """Render analysis de eficiencia"""
        
        st.markdown("### ⚡ Analysis de Eficiencia")
        
        col1, col2 = st.columns(2)
        
        with col1:
            st.markdown("#### 🎯 Eficiencia de Barrido")
            
            # Calculate eficiencia de barrido
            sweep_efficiency = self._calculate_sweep_efficiency()
            
            if sweep_efficiency is not None:
                # Métricas de barrido
                col_a, col_b = st.columns(2)
                
                with col_a:
                    st.metric(
                        "Eficiencia Areal",
                        f"{sweep_efficiency['areal']:.1%}",
                        help="Fracción del área contactada por el fluido desplazante"
                    )
                
                with col_b:
                    st.metric(
                        "Eficiencia Vertical",
                        f"{sweep_efficiency['vertical']:.1%}",
                        help="Fracción vertical del reservorio contactada"
                    )
                
                # Gráfico de evolution de eficiencia
                self._render_sweep_efficiency_plot(sweep_efficiency)
            else:
                st.info("Data de eficiencia no available")
        
        with col2:
            st.markdown("#### 💰 Analysis Económico Básico")
            
            # Cálculos económicos simples
            economics = self._calculate_basic_economics()
            
            if economics:
                st.metric(
                    "Producción por Pozo",
                    f"{economics['production_per_well']:,.0f} bbl",
                    help="Producción average por pozo productor"
                )
                
                st.metric(
                    "Relación I/P",
                    f"{economics['injection_production_ratio']:.2f}",
                    help="Relación entre inyección y producción volumétrica"
                )
                
                st.metric(
                    "Días de Producción",
                    f"{economics['production_days']:.0f}",
                    help="Días con producción activa"
                )
    
    def _render_reservoir_evolution(self):
        """Render evolution del reservorio"""
        
        st.markdown("### 🌊 Evolution del Reservorio")
        
        # Selector de timestep
        temporal_data = self.data_loader.get_temporal_data()
        if temporal_data is None:
            st.error("❌ Could not load data temporales")
            return
        
        if 'time' in temporal_data.columns:
            time_values = temporal_data['time'].values
            timestep = st.slider(
                "Seleccionar tiempo:",
                min_value=0,
                max_value=len(time_values) - 1,
                value=len(time_values) - 1,
                format=f"T%d ({time_values[len(time_values)-1]:.0f} días)" if len(time_values) > 0 else "T%d"
            )
        else:
            st.info("Usando último timestep available")
            timestep = None
        
        # Load data spatiales para el timestep seleccionado
        spatial_data = self.data_loader.get_spatial_data(timestep)
        
        if spatial_data is None:
            st.error("❌ Could not load data spatiales")
            return
        
        # Selector de propiedad
        available_props = [key for key in spatial_data.keys() 
                          if isinstance(spatial_data[key], np.ndarray)]
        
        if not available_props:
            st.error("❌ No se findon propiedades spatiales")
            return
        
        selected_prop = st.selectbox(
            "Propiedad a visualize:",
            available_props,
            index=0 if 'pressure' not in available_props else available_props.index('pressure')
        )
        
        # Visualización de mapas 2D
        col1, col2 = st.columns(2)
        
        with col1:
            # Mapa 2D con pozos
            prop_data = spatial_data[selected_prop]
            
            # Determinar esquema de colores
            colorscale = 'RdYlBu_r' if 'pressure' in selected_prop.lower() else 'Viridis'
            
            # Crear mapa base
            if prop_data.ndim >= 2:
                layer = 0  # Primera capa
                if prop_data.ndim == 3:
                    map_data = prop_data[:, :, layer]
                else:
                    map_data = prop_data
                
                fig = self.reservoir_viz.create_2d_heatmap(
                    prop_data, selected_prop.title(), colorscale, "", layer
                )
                
                # Agregar pozos al mapa
                for well in self.producers:
                    loc = well['location']
                    fig.add_trace(go.Scatter(
                        x=[loc[0]], y=[loc[1]],
                        mode='markers',
                        marker=dict(symbol='circle', size=12, color='red', 
                                  line=dict(width=2, color='darkred')),
                        name=well['name'],
                        showlegend=False
                    ))
                
                for well in self.injectors:
                    loc = well['location']
                    fig.add_trace(go.Scatter(
                        x=[loc[0]], y=[loc[1]],
                        mode='markers',
                        marker=dict(symbol='square', size=12, color='blue',
                                  line=dict(width=2, color='darkblue')),
                        name=well['name'],
                        showlegend=False
                    ))
                
                st.plotly_chart(fig, use_container_width=True)
            else:
                st.error("❌ Data spatiales no tienen formato correcto")
        
        with col2:
            # Estadísticas de la propiedad
            st.markdown(f"#### 📊 Estadísticas: {selected_prop.title()}")
            
            if prop_data.size > 0:
                flat_data = prop_data.flatten()
                
                stats = {
                    'Parámetro': ['Mínimo', 'Máximo', 'Promedio', 'Mediana', 'Desv. Est.'],
                    'Valor': [
                        f"{np.min(flat_data):.3f}",
                        f"{np.max(flat_data):.3f}",
                        f"{np.mean(flat_data):.3f}",
                        f"{np.median(flat_data):.3f}",
                        f"{np.std(flat_data):.3f}"
                    ]
                }
                
                stats_df = pd.DataFrame(stats)
                st.dataframe(stats_df, hide_index=True, use_container_width=True)
                
                # Histograma
                fig_hist = go.Figure(data=[go.Histogram(
                    x=flat_data,
                    nbinsx=30,
                    marker_color='lightblue',
                    opacity=0.7
                )])
                
                fig_hist.update_layout(
                    title=f"Distribución de {selected_prop.title()}",
                    xaxis_title=selected_prop.title(),
                    yaxis_title="Frecuencia",
                    height=300
                )
                
                st.plotly_chart(fig_hist, use_container_width=True)
            else:
                st.error("❌ No data para show statistics")
    
    def _check_well_data_availability(self) -> bool:
        """Verificar si hay data de pozos available"""
        temporal_data = self.data_loader.get_temporal_data()
        return temporal_data is not None
    
    def _calculate_production_metrics(self, temporal_data: pd.DataFrame) -> Dict:
        """Calculate métricas de producción"""
        metrics = {
            'total_production': 0,
            'total_injection': 0,
            'avg_production_rate': 0,
            'recovery_factor': 0
        }
        
        try:
            # Buscar columnas de producción e inyección
            prod_cols = [col for col in temporal_data.columns if 'prod' in col.lower()]
            inj_cols = [col for col in temporal_data.columns if 'inj' in col.lower()]
            
            if prod_cols:
                production_rates = temporal_data[prod_cols[0]].values
                time_steps = np.diff(temporal_data.index.values) if len(temporal_data.index) > 1 else [1]
                
                # Calculate producción acumulada (aproximación)
                if len(time_steps) > 0:
                    avg_timestep = np.mean(time_steps)
                    metrics['total_production'] = np.sum(production_rates) * avg_timestep
                    metrics['avg_production_rate'] = np.mean(production_rates[production_rates > 0])
            
            if inj_cols:
                injection_rates = temporal_data[inj_cols[0]].values
                time_steps = np.diff(temporal_data.index.values) if len(temporal_data.index) > 1 else [1]
                
                if len(time_steps) > 0:
                    avg_timestep = np.mean(time_steps)
                    metrics['total_injection'] = np.sum(injection_rates) * avg_timestep
            
            # Estimar factor de recobro (simplificado)
            # Usar configuretion para estimar OOIP
            grid_config = self.config.get('grid', {})
            porosity_config = self.config.get('porosity', {})
            
            if all(key in grid_config for key in ['nx', 'ny']) and 'base_value' in porosity_config:
                cell_volume = grid_config.get('dx', 164) * grid_config.get('dy', 164) * \
                             np.mean(grid_config.get('dz', [10]))
                total_volume = grid_config['nx'] * grid_config['ny'] * \
                              grid_config.get('nz', 10) * cell_volume
                
                avg_porosity = porosity_config['base_value']
                oil_saturation = 0.8  # Estimation típica
                
                # OOIP en ft³, convertir a barriles (1 bbl = 5.615 ft³)
                ooip = total_volume * avg_porosity * oil_saturation / 5.615
                
                if ooip > 0:
                    metrics['recovery_factor'] = metrics['total_production'] / ooip
        
        except Exception as e:
            logger.warning(f"Error calculando métricas de producción: {e}")
        
        return metrics
    
    def _render_production_history(self, temporal_data: pd.DataFrame):
        """Render historial de producción"""
        st.markdown("#### 📈 Historial de Producción/Inyección")
        
        fig = go.Figure()
        
        # Buscar columnas de producción e inyección
        prod_cols = [col for col in temporal_data.columns if 'prod' in col.lower()]
        inj_cols = [col for col in temporal_data.columns if 'inj' in col.lower()]
        
        time_col = temporal_data['time'] if 'time' in temporal_data.columns else temporal_data.index
        
        if prod_cols:
            fig.add_trace(go.Scatter(
                x=time_col,
                y=temporal_data[prod_cols[0]],
                mode='lines',
                name='Producción',
                line=dict(color='red', width=2),
                yaxis='y'
            ))
        
        if inj_cols:
            fig.add_trace(go.Scatter(
                x=time_col,
                y=temporal_data[inj_cols[0]],
                mode='lines',
                name='Inyección',
                line=dict(color='blue', width=2),
                yaxis='y2'
            ))
        
        fig.update_layout(
            title="Tasas de Producción e Inyección",
            xaxis_title="Tiempo [días]",
            yaxis=dict(title="Producción [bbl/día]", side="left", color="red"),
            yaxis2=dict(title="Inyección [bbl/día]", side="right", overlaying="y", color="blue"),
            height=400,
            legend=dict(x=0.02, y=0.98)
        )
        
        st.plotly_chart(fig, use_container_width=True)
    
    def _render_cumulative_production(self, temporal_data: pd.DataFrame):
        """Render producción acumulada"""
        st.markdown("#### 📊 Producción Acumulada")
        
        prod_cols = [col for col in temporal_data.columns if 'prod' in col.lower()]
        
        if not prod_cols:
            st.info("No data de producción available")
            return
        
        # Calculate acumulada (aproximación simple)
        production_rates = temporal_data[prod_cols[0]].values
        time_col = temporal_data['time'] if 'time' in temporal_data.columns else temporal_data.index
        
        # Estimar timesteps
        if len(time_col) > 1:
            timesteps = np.diff(time_col.values)
            timesteps = np.append(timesteps[0], timesteps)  # Usar primer timestep para el primer punto
        else:
            timesteps = np.array([1])
        
        cumulative = np.cumsum(production_rates * timesteps)
        
        fig = go.Figure()
        fig.add_trace(go.Scatter(
            x=time_col,
            y=cumulative,
            mode='lines',
            name='Producción Acumulada',
            line=dict(color='green', width=3),
            fill='tonexty'
        ))
        
        fig.update_layout(
            title="Producción Acumulada",
            xaxis_title="Tiempo [días]",
            yaxis_title="Producción Acumulada [bbl]",
            height=400
        )
        
        st.plotly_chart(fig, use_container_width=True)
    
    def _get_well_data(self, well_name: str) -> Optional[pd.DataFrame]:
        """Obtener data específicos de un pozo"""
        # Implementación simplificada - en una implementación real,
        # esto loadía data específicos del pozo desde files de simulación
        temporal_data = self.data_loader.get_temporal_data()
        
        if temporal_data is None:
            return None
        
        # Crear data simulados para el pozo (en implementación real vendrían de files)
        well_data = pd.DataFrame({
            'time': temporal_data['time'] if 'time' in temporal_data.columns else temporal_data.index,
            'rate': np.random.uniform(100, 500, len(temporal_data)),  # Placeholder
            'bhp': np.random.uniform(2000, 3000, len(temporal_data)),  # Placeholder
            'cumulative': np.cumsum(np.random.uniform(100, 500, len(temporal_data)))  # Placeholder
        })
        
        return well_data
    
    def _get_well_info(self, well_name: str) -> Dict:
        """Obtener information de configuretion de un pozo"""
        # Buscar en productores
        for well in self.producers:
            if well['name'] == well_name:
                return {
                    'name': well['name'],
                    'type': 'Productor',
                    'location': f"({well['location'][0]}, {well['location'][1]})",
                    'control_type': well['control_type'],
                    'target_bhp': well['target_bhp'],
                    'target_rate': well.get('target_rate', 0)
                }
        
        # Buscar en inyectores
        for well in self.injectors:
            if well['name'] == well_name:
                return {
                    'name': well['name'],
                    'type': 'Inyector',
                    'location': f"({well['location'][0]}, {well['location'][1]})",
                    'control_type': well['control_type'],
                    'target_bhp': well['target_bhp'],
                    'target_rate': well.get('target_rate', 0)
                }
        
        return {'name': well_name, 'type': 'Desconocido', 'location': 'N/A'}
    
    def _render_well_plots(self, well_data: pd.DataFrame, well_name: str, well_type: str):
        """Render charts específicos del pozo"""
        col1, col2 = st.columns(2)
        
        with col1:
            # Gráfico de tasa vs tiempo
            fig_rate = go.Figure()
            fig_rate.add_trace(go.Scatter(
                x=well_data['time'],
                y=well_data['rate'],
                mode='lines',
                name='Tasa',
                line=dict(color='red' if well_type == 'Productor' else 'blue', width=2)
            ))
            
            fig_rate.update_layout(
                title=f"Tasa - {well_name}",
                xaxis_title="Tiempo [días]",
                yaxis_title="Tasa [bbl/día]",
                height=350
            )
            
            st.plotly_chart(fig_rate, use_container_width=True)
        
        with col2:
            # Gráfico de BHP vs tiempo
            fig_bhp = go.Figure()
            fig_bhp.add_trace(go.Scatter(
                x=well_data['time'],
                y=well_data['bhp'],
                mode='lines',
                name='BHP',
                line=dict(color='orange', width=2)
            ))
            
            fig_bhp.update_layout(
                title=f"BHP - {well_name}",
                xaxis_title="Tiempo [días]",
                yaxis_title="BHP [psi]",
                height=350
            )
            
            st.plotly_chart(fig_bhp, use_container_width=True)
        
        # Gráfico de producción acumulada (ancho completo)
        fig_cum = go.Figure()
        fig_cum.add_trace(go.Scatter(
            x=well_data['time'],
            y=well_data['cumulative'],
            mode='lines',
            name='Acumulado',
            line=dict(color='green', width=3),
            fill='tonexty'
        ))
        
        fig_cum.update_layout(
            title=f"Producción Acumulada - {well_name}",
            xaxis_title="Tiempo [días]",
            yaxis_title="Producción Acumulada [bbl]",
            height=300
        )
        
        st.plotly_chart(fig_cum, use_container_width=True)
    
    def _calculate_sweep_efficiency(self) -> Optional[Dict]:
        """Calculate eficiencia de barrido (implementación simplificada)"""
        try:
            # En implementación real, esto analyzeía mapas de saturación
            # Para demo, usar valores estimados
            return {
                'areal': 0.65,  # 65% eficiencia areal
                'vertical': 0.80,  # 80% eficiencia vertical
                'volumetric': 0.52  # 52% eficiencia volumétrica
            }
        except:
            return None
    
    def _render_sweep_efficiency_plot(self, sweep_data: Dict):
        """Render chart de eficiencia de barrido"""
        categories = ['Areal', 'Vertical', 'Volumétrica']
        values = [sweep_data['areal'], sweep_data['vertical'], sweep_data['volumetric']]
        
        fig = go.Figure(data=[
            go.Bar(
                x=categories,
                y=values,
                marker_color=['lightblue', 'lightgreen', 'lightcoral'],
                text=[f"{v:.1%}" for v in values],
                textposition='auto'
            )
        ])
        
        fig.update_layout(
            title="Eficiencias de Barrido",
            yaxis_title="Eficiencia",
            yaxis_tickformat=".0%",
            height=300
        )
        
        st.plotly_chart(fig, use_container_width=True)
    
    def _calculate_basic_economics(self) -> Optional[Dict]:
        """Calculate métricas económicas básicas"""
        try:
            temporal_data = self.data_loader.get_temporal_data()
            if temporal_data is None:
                return None
            
            # Estimaciones básicas
            total_production = 100000  # Placeholder
            num_producers = len(self.producers)
            production_days = len(temporal_data)
            
            total_injection = 120000  # Placeholder
            
            return {
                'production_per_well': total_production / max(1, num_producers),
                'injection_production_ratio': total_injection / max(1, total_production),
                'production_days': production_days
            }
        except:
            return None