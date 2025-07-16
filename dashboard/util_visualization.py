#!/usr/bin/env python3
"""
Dashboard Visualization Utilities

Creates interactive visualizations for MRST simulation results using Plotly.
All visualizations follow product owner requirements for user-accessible
information display with proper styling and interactivity.
"""

import numpy as np
import plotly.graph_objects as go
import plotly.express as px
from plotly.subplots import make_subplots
from typing import Dict, Any, Optional

# ----------------------------------------
# Step 1 – Main visualization class
# ----------------------------------------

class DashboardVisualizer:
    """
    Creates interactive visualizations for MRST simulation dashboard.
    
    Provides user-accessible visualization of reservoir simulation results
    with appropriate styling, interactivity, and product owner focus.
    """
    
    def __init__(self, data: Dict[str, Any]):
        """
        Initialize visualizer with simulation data.
        
        Args:
            data: Complete simulation dataset
        """
        self.data = data
        self.color_schemes = self._define_color_schemes()
        self.default_height = 500
        self.default_font_size = 12
    
    def _define_color_schemes(self) -> Dict[str, str]:
        """
        Define color schemes for different data types.
        
        Returns:
            dict: Color scheme mapping for visualization consistency
        """
        return {
            'pressure': 'RdYlBu_r',
            'saturation': 'Blues',
            'porosity': 'YlOrRd',
            'permeability': 'viridis',
            'velocity': 'coolwarm',
            'production': 'Greens',
            'injection': 'Blues'
        }
    
    def create_pressure_heatmap(self, pressure_data: np.ndarray, title: str) -> go.Figure:
        """
        Create pressure distribution heatmap visualization.
        
        Args:
            pressure_data: 2D pressure array [psi]
            title: Plot title
            
        Returns:
            plotly.graph_objects.Figure: Interactive heatmap
        """
        fig = go.Figure(data=go.Heatmap(
            z=pressure_data,
            colorscale=self.color_schemes['pressure'],
            showscale=True,
            colorbar=dict(title="Pressure [psi]"),
            hovertemplate='X: %{x}<br>Y: %{y}<br>Pressure: %{z:.1f} psi<extra></extra>'
        ))
        
        fig.update_layout(
            title=title,
            xaxis_title="X [grid cells]",
            yaxis_title="Y [grid cells]",
            height=self.default_height,
            font=dict(size=self.default_font_size)
        )
        
        return fig
    
    def create_saturation_heatmap(self, saturation_data: np.ndarray, title: str) -> go.Figure:
        """
        Create water saturation distribution heatmap.
        
        Args:
            saturation_data: 2D saturation array [-]
            title: Plot title
            
        Returns:
            plotly.graph_objects.Figure: Interactive heatmap
        """
        fig = go.Figure(data=go.Heatmap(
            z=saturation_data,
            colorscale=self.color_schemes['saturation'],
            showscale=True,
            colorbar=dict(title="Water Saturation [-]"),
            hovertemplate='X: %{x}<br>Y: %{y}<br>Saturation: %{z:.3f}<extra></extra>'
        ))
        
        fig.update_layout(
            title=title,
            xaxis_title="X [grid cells]",
            yaxis_title="Y [grid cells]",
            height=self.default_height,
            font=dict(size=self.default_font_size)
        )
        
        return fig
    
    def create_porosity_heatmap(self, porosity_data: np.ndarray, title: str) -> go.Figure:
        """
        Create porosity distribution heatmap.
        
        Args:
            porosity_data: 2D porosity array [-]
            title: Plot title
            
        Returns:
            plotly.graph_objects.Figure: Interactive heatmap
        """
        fig = go.Figure(data=go.Heatmap(
            z=porosity_data,
            colorscale=self.color_schemes['porosity'],
            showscale=True,
            colorbar=dict(title="Porosity [-]"),
            hovertemplate='X: %{x}<br>Y: %{y}<br>Porosity: %{z:.3f}<extra></extra>'
        ))
        
        fig.update_layout(
            title=title,
            xaxis_title="X [grid cells]",
            yaxis_title="Y [grid cells]",
            height=self.default_height,
            font=dict(size=self.default_font_size)
        )
        
        return fig
    
    def create_permeability_heatmap(self, permeability_data: np.ndarray, title: str) -> go.Figure:
        """
        Create permeability distribution heatmap.
        
        Args:
            permeability_data: 2D permeability array [mD]
            title: Plot title
            
        Returns:
            plotly.graph_objects.Figure: Interactive heatmap
        """
        fig = go.Figure(data=go.Heatmap(
            z=permeability_data,
            colorscale=self.color_schemes['permeability'],
            showscale=True,
            colorbar=dict(title="Permeability [mD]"),
            hovertemplate='X: %{x}<br>Y: %{y}<br>Permeability: %{z:.1f} mD<extra></extra>'
        ))
        
        fig.update_layout(
            title=title,
            xaxis_title="X [grid cells]",
            yaxis_title="Y [grid cells]",
            height=self.default_height,
            font=dict(size=self.default_font_size)
        )
        
        return fig
    
    def create_velocity_heatmap(self, velocity_data: np.ndarray, title: str) -> go.Figure:
        """
        Create velocity magnitude heatmap.
        
        Args:
            velocity_data: 2D velocity magnitude array [m/day]
            title: Plot title
            
        Returns:
            plotly.graph_objects.Figure: Interactive heatmap
        """
        fig = go.Figure(data=go.Heatmap(
            z=velocity_data,
            colorscale=self.color_schemes['velocity'],
            showscale=True,
            colorbar=dict(title="Velocity [m/day]"),
            hovertemplate='X: %{x}<br>Y: %{y}<br>Velocity: %{z:.3f} m/day<extra></extra>'
        ))
        
        fig.update_layout(
            title=title,
            xaxis_title="X [grid cells]",
            yaxis_title="Y [grid cells]",
            height=self.default_height,
            font=dict(size=self.default_font_size)
        )
        
        return fig
    
    def create_property_histogram(self, property_data: np.ndarray, title: str, xlabel: str) -> go.Figure:
        """
        Create property distribution histogram.
        
        Args:
            property_data: Property data array
            title: Plot title
            xlabel: X-axis label
            
        Returns:
            plotly.graph_objects.Figure: Interactive histogram
        """
        fig = px.histogram(
            x=property_data.flatten(),
            nbins=30,
            title=title,
            labels={'x': xlabel, 'y': 'Frequency'}
        )
        
        fig.update_layout(
            height=self.default_height,
            font=dict(size=self.default_font_size),
            showlegend=False
        )
        
        return fig
    
    def create_production_rates_plot(self, well_data: Dict[str, Any], title: str) -> go.Figure:
        """
        Create oil production rates time series plot.
        
        Args:
            well_data: Well operational data
            title: Plot title
            
        Returns:
            plotly.graph_objects.Figure: Interactive time series plot
        """
        fig = go.Figure()
        
        # ✅ Extract well information
        time_days = well_data['time_days']
        well_names = well_data['well_names']
        qOs = well_data['qOs']
        
        # 🔄 Plot each well's oil production
        for i, well_name in enumerate(well_names):
            # Handle well name extraction
            if hasattr(well_name, '__iter__') and not isinstance(well_name, str):
                display_name = str(well_name[0]) if len(well_name) > 0 else f'Well_{i}'
            else:
                display_name = str(well_name)
            
            fig.add_trace(go.Scatter(
                x=time_days,
                y=qOs[:, i],
                mode='lines',
                name=display_name,
                line=dict(width=2),
                hovertemplate=f'{display_name}<br>Time: %{{x}} days<br>Oil Rate: %{{y:.1f}} m³/day<extra></extra>'
            ))
        
        fig.update_layout(
            title=title,
            xaxis_title="Time [days]",
            yaxis_title="Oil Production Rate [m³/day]",
            height=self.default_height,
            font=dict(size=self.default_font_size),
            hovermode='x unified'
        )
        
        return fig
    
    def create_injection_rates_plot(self, well_data: Dict[str, Any], title: str) -> go.Figure:
        """
        Create water injection rates time series plot.
        
        Args:
            well_data: Well operational data
            title: Plot title
            
        Returns:
            plotly.graph_objects.Figure: Interactive time series plot
        """
        fig = go.Figure()
        
        # ✅ Extract well information
        time_days = well_data['time_days']
        well_names = well_data['well_names']
        qWs = well_data['qWs']
        
        # 🔄 Plot each well's water injection
        for i, well_name in enumerate(well_names):
            # Handle well name extraction
            if hasattr(well_name, '__iter__') and not isinstance(well_name, str):
                display_name = str(well_name[0]) if len(well_name) > 0 else f'Well_{i}'
            else:
                display_name = str(well_name)
            
            # ✅ Only plot if well has injection (positive rates)
            if np.any(qWs[:, i] > 0):
                fig.add_trace(go.Scatter(
                    x=time_days,
                    y=qWs[:, i],
                    mode='lines',
                    name=display_name,
                    line=dict(width=2),
                    hovertemplate=f'{display_name}<br>Time: %{{x}} days<br>Water Rate: %{{y:.1f}} m³/day<extra></extra>'
                ))
        
        fig.update_layout(
            title=title,
            xaxis_title="Time [days]",
            yaxis_title="Water Injection Rate [m³/day]",
            height=self.default_height,
            font=dict(size=self.default_font_size),
            hovermode='x unified'
        )
        
        return fig
    
    def create_cumulative_production_plot(self, cumulative_data: Dict[str, Any], title: str) -> go.Figure:
        """
        Create cumulative production plot.
        
        Args:
            cumulative_data: Cumulative production data
            title: Plot title
            
        Returns:
            plotly.graph_objects.Figure: Interactive time series plot
        """
        fig = go.Figure()
        
        # ✅ Extract cumulative data
        time_days = cumulative_data['time_days']
        cum_oil = np.sum(cumulative_data['cum_oil_prod'], axis=1)
        cum_water = np.sum(cumulative_data['cum_water_prod'], axis=1)
        
        # 📊 Add oil production trace
        fig.add_trace(go.Scatter(
            x=time_days,
            y=cum_oil,
            mode='lines',
            name='Oil Production',
            line=dict(color='black', width=2),
            hovertemplate='Time: %{x} days<br>Cumulative Oil: %{y:.1f} m³<extra></extra>'
        ))
        
        # 📊 Add water production trace
        fig.add_trace(go.Scatter(
            x=time_days,
            y=cum_water,
            mode='lines',
            name='Water Production',
            line=dict(color='blue', width=2),
            hovertemplate='Time: %{x} days<br>Cumulative Water: %{y:.1f} m³<extra></extra>'
        ))
        
        fig.update_layout(
            title=title,
            xaxis_title="Time [days]",
            yaxis_title="Cumulative Production [m³]",
            height=self.default_height,
            font=dict(size=self.default_font_size),
            hovermode='x unified'
        )
        
        return fig
    
    def create_recovery_factor_plot(self, cumulative_data: Dict[str, Any], title: str) -> go.Figure:
        """
        Create recovery factor evolution plot.
        
        Args:
            cumulative_data: Cumulative production data
            title: Plot title
            
        Returns:
            plotly.graph_objects.Figure: Interactive time series plot
        """
        fig = go.Figure()
        
        # ✅ Extract recovery factor data
        time_days = cumulative_data['time_days']
        recovery_factor = cumulative_data['recovery_factor']
        
        # 📊 Add recovery factor trace
        fig.add_trace(go.Scatter(
            x=time_days,
            y=recovery_factor * 100,  # Convert to percentage
            mode='lines',
            name='Recovery Factor',
            line=dict(color='green', width=2),
            hovertemplate='Time: %{x} days<br>Recovery Factor: %{y:.2f}%<extra></extra>'
        ))
        
        fig.update_layout(
            title=title,
            xaxis_title="Time [days]",
            yaxis_title="Recovery Factor [%]",
            height=self.default_height,
            font=dict(size=self.default_font_size),
            hovermode='x unified'
        )
        
        return fig
    
    def create_pressure_evolution_plot(self, field_data: Dict[str, Any], title: str) -> go.Figure:
        """
        Create average pressure evolution plot.
        
        Args:
            field_data: Field arrays data
            title: Plot title
            
        Returns:
            plotly.graph_objects.Figure: Interactive time series plot
        """
        fig = go.Figure()
        
        # ✅ Calculate average pressure over time
        pressure_data = field_data['pressure']
        avg_pressure = np.mean(pressure_data, axis=(1, 2))
        
        # 📊 Generate time vector if not available
        n_timesteps = len(avg_pressure)
        time_days = np.linspace(0, 365, n_timesteps)  # Default 1 year simulation
        
        # 📊 Add pressure evolution trace
        fig.add_trace(go.Scatter(
            x=time_days,
            y=avg_pressure,
            mode='lines',
            name='Average Pressure',
            line=dict(color='blue', width=2),
            hovertemplate='Time: %{x} days<br>Average Pressure: %{y:.1f} psi<extra></extra>'
        ))
        
        fig.update_layout(
            title=title,
            xaxis_title="Time [days]",
            yaxis_title="Average Pressure [psi]",
            height=self.default_height,
            font=dict(size=self.default_font_size),
            hovermode='x unified'
        )
        
        return fig
    
    def create_velocity_evolution_plot(self, flow_data: Dict[str, Any], title: str) -> go.Figure:
        """
        Create average velocity magnitude evolution plot.
        
        Args:
            flow_data: Flow velocity data
            title: Plot title
            
        Returns:
            plotly.graph_objects.Figure: Interactive time series plot
        """
        fig = go.Figure()
        
        # ✅ Extract velocity data
        time_days = flow_data['time_days']
        velocity_magnitude = flow_data['velocity_magnitude']
        
        # 📊 Calculate average velocity magnitude
        avg_velocity = np.mean(velocity_magnitude, axis=(1, 2))
        
        # 📊 Add velocity evolution trace
        fig.add_trace(go.Scatter(
            x=time_days,
            y=avg_velocity,
            mode='lines',
            name='Average Velocity',
            line=dict(color='green', width=2),
            hovertemplate='Time: %{x} days<br>Average Velocity: %{y:.3f} m/day<extra></extra>'
        ))
        
        fig.update_layout(
            title=title,
            xaxis_title="Time [days]",
            yaxis_title="Average Velocity Magnitude [m/day]",
            height=self.default_height,
            font=dict(size=self.default_font_size),
            hovermode='x unified'
        )
        
        return fig