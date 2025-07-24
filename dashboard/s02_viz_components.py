#!/usr/bin/env python3
"""
Visualization Utilities - GeomechML Dashboard
===========================================

Visualization utilities using Plotly for the GeomechML dashboard.
Includes functions for 2D, 3D, heatmaps, time series and more.

Author: GeomechML Team
Date: 2025-07-23
"""

import numpy as np
import pandas as pd
import plotly.graph_objects as go
import plotly.express as px
from plotly.subplots import make_subplots
import streamlit as st
from typing import Dict, List, Optional, Union, Tuple, Any
import logging

logger = logging.getLogger(__name__)

class ColorSchemes:
    """Predefined color schemes for different data types"""
    
    # Schemes for reservoir properties
    POROSITY = 'Viridis'
    PERMEABILITY = 'Plasma'
    PRESSURE = 'RdYlBu_r'
    SATURATION = 'Blues'
    STRESS = 'Reds'
    
    # Schemes for rock types
    ROCK_TYPES = px.colors.qualitative.Set3
    
    # Schemes for wells
    WELLS = ['#1f77b4', '#ff7f0e', '#2ca02c', '#d62728', '#9467bd']

class PlotUtils:
    """General utilities for plots"""
    
    @staticmethod
    def create_base_layout(title: str, width: int = 800, height: int = 600) -> Dict:
        """
        Create base layout for charts.
        
        Args:
            title: Chart title
            width: Chart width
            height: Chart height
            
        Returns:
            Dictionary with layout configuration
        """
        return {
            'title': {
                'text': title,
                'x': 0.5,
                'font': {'size': 16, 'family': 'Arial, sans-serif'}
            },
            'width': width,
            'height': height,
            'margin': {'l': 60, 'r': 40, 't': 60, 'b': 60},
            'paper_bgcolor': 'white',
            'plot_bgcolor': 'white',
            'font': {'family': 'Arial, sans-serif', 'size': 12}
        }
    
    @staticmethod
    def format_axis(axis_dict: Dict, title: str, units: str = "") -> Dict:
        """
        Format axis configuration.
        
        Args:
            axis_dict: Axis configuration dictionary
            title: Axis title
            units: Units of measurement
            
        Returns:
            Dictionary with formatted configuration
        """
        full_title = f"{title}" + (f" [{units}]" if units else "")
        
        axis_dict.update({
            'title': full_title,
            'showgrid': True,
            'gridcolor': 'lightgray',
            'gridwidth': 1,
            'showline': True,
            'linecolor': 'black',
            'linewidth': 1,
            'mirror': True
        })
        
        return axis_dict

class ReservoirVisualizer:
    """Visualizer for reservoir data"""
    
    def __init__(self, nx: int = 20, ny: int = 20, nz: int = 10):
        """
        Initialize visualizer.
        
        Args:
            nx, ny, nz: Simulation grid dimensions
        """
        self.nx = nx
        self.ny = ny
        self.nz = nz
    
    def create_2d_heatmap(self, data: np.ndarray, title: str, 
                         colorscale: str = 'Viridis', 
                         units: str = "", layer: int = 0) -> go.Figure:
        """
        Create 2D heatmap for a reservoir property.
        
        Args:
            data: 2D or 3D array with data
            title: Chart title
            colorscale: Color scheme
            units: Units of measurement
            layer: Layer to visualize (for 3D data)
            
        Returns:
            Plotly figure
        """
        try:
            # Process data according to dimensions
            if data.ndim == 3:
                plot_data = data[:, :, layer]
            elif data.ndim == 2:
                plot_data = data
            else:
                # Try reshape for 1D data
                if data.size == self.nx * self.ny:
                    plot_data = data.reshape(self.ny, self.nx)
                else:
                    raise ValueError(f"Cannot process array with shape {data.shape}")
            
            # Create figure
            fig = go.Figure(data=go.Heatmap(
                z=plot_data,
                colorscale=colorscale,
                colorbar=dict(
                    title=f"{title}" + (f" [{units}]" if units else ""),
                    titleside='right'
                ),
                hovertemplate='X: %{x}<br>Y: %{y}<br>Value: %{z}<extra></extra>'
            ))
            
            # Configure layout
            layout = PlotUtils.create_base_layout(title)
            layout.update({
                'xaxis': PlotUtils.format_axis({}, 'X Position', 'grid cells'),
                'yaxis': PlotUtils.format_axis({}, 'Y Position', 'grid cells'),
                'aspect': dict(ratio=1)  # Maintain square aspect
            })
            
            fig.update_layout(**layout)
            
            return fig
            
        except Exception as e:
            logger.error(f"Error creating 2D heatmap: {e}")
            return self._create_error_plot(f"Error in 2D heatmap: {str(e)}")
    
    def create_3d_volume(self, data: np.ndarray, title: str, 
                        colorscale: str = 'Viridis', 
                        units: str = "") -> go.Figure:
        """
        Create 3D volumetric visualization.
        
        Args:
            data: 3D array with data
            title: Chart title
            colorscale: Color scheme
            units: Units of measurement
            
        Returns:
            Plotly figure
        """
        try:
            if data.ndim != 3:
                raise ValueError("Data must be 3D for volumetric visualization")
            
            # Create meshgrid for coordinates
            x, y, z = np.meshgrid(
                np.arange(data.shape[0]),
                np.arange(data.shape[1]),
                np.arange(data.shape[2]),
                indexing='ij'
            )
            
            # Flatten arrays for plotly
            x_flat = x.flatten()
            y_flat = y.flatten()
            z_flat = z.flatten()
            values_flat = data.flatten()
            
            # Create 3D scatter
            fig = go.Figure(data=go.Scatter3d(
                x=x_flat,
                y=y_flat,
                z=z_flat,
                mode='markers',
                marker=dict(
                    size=3,
                    color=values_flat,
                    colorscale=colorscale,
                    colorbar=dict(
                        title=f"{title}" + (f" [{units}]" if units else ""),
                        titleside='right'
                    ),
                    opacity=0.8
                ),
                hovertemplate='X: %{x}<br>Y: %{y}<br>Z: %{z}<br>Value: %{marker.color}<extra></extra>'
            ))
            
            # Configure 3D layout
            layout = PlotUtils.create_base_layout(title, height=700)
            layout.update({
                'scene': {
                    'xaxis_title': 'X Position [grid cells]',
                    'yaxis_title': 'Y Position [grid cells]',
                    'zaxis_title': 'Z Position [grid cells]',
                    'aspectmode': 'cube'
                }
            })
            
            fig.update_layout(**layout)
            
            return fig
            
        except Exception as e:
            logger.error(f"Error creating 3D visualization: {e}")
            return self._create_error_plot(f"Error in 3D visualization: {str(e)}")
    
    def create_layer_comparison(self, data: np.ndarray, title: str,
                               colorscale: str = 'Viridis',
                               units: str = "") -> go.Figure:
        """
        Create layer comparison in subplots.
        
        Args:
            data: 3D array with data
            title: Chart title
            colorscale: Color scheme
            units: Units of measurement
            
        Returns:
            Plotly figure with subplots
        """
        try:
            if data.ndim != 3:
                raise ValueError("Data must be 3D for layer comparison")
            
            nz = data.shape[2]
            
            # Calculate subplot layout
            cols = min(5, nz)
            rows = (nz + cols - 1) // cols
            
            # Create subplots
            fig = make_subplots(
                rows=rows, cols=cols,
                subplot_titles=[f'Layer {i+1}' for i in range(nz)],
                vertical_spacing=0.1,
                horizontal_spacing=0.1
            )
            
            # Add heatmap for each layer
            for i in range(nz):
                row = i // cols + 1
                col = i % cols + 1
                
                fig.add_trace(
                    go.Heatmap(
                        z=data[:, :, i],
                        colorscale=colorscale,
                        showscale=(i == 0),  # Only show scale on first plot
                        colorbar=dict(
                            title=f"{title}" + (f" [{units}]" if units else ""),
                            titleside='right'
                        ) if i == 0 else None,
                        hovertemplate=f'Layer {i+1}<br>X: %{{x}}<br>Y: %{{y}}<br>Value: %{{z}}<extra></extra>'
                    ),
                    row=row, col=col
                )
            
            # Configure layout
            fig.update_layout(
                title=title,
                height=200 * rows + 100,
                showlegend=False
            )
            
            return fig
            
        except Exception as e:
            logger.error(f"Error creating layer comparison: {e}")
            return self._create_error_plot(f"Error in layer comparison: {str(e)}")
    
    def _create_error_plot(self, error_message: str) -> go.Figure:
        """Create error chart when visualization fails"""
        fig = go.Figure()
        fig.add_annotation(
            text=error_message,
            xref="paper", yref="paper",
            x=0.5, y=0.5,
            showarrow=False,
            font=dict(size=16, color="red")
        )
        fig.update_layout(
            title="Visualization Error",
            xaxis=dict(showgrid=False, showticklabels=False),
            yaxis=dict(showgrid=False, showticklabels=False)
        )
        return fig

class TimeSeriesVisualizer:
    """Visualizer for time series"""
    
    @staticmethod
    def create_time_series(df: pd.DataFrame, variables: List[str],
                          title: str = "Time Series",
                          units: Dict[str, str] = None) -> go.Figure:
        """
        Create time series chart.
        
        Args:
            df: DataFrame with temporal data
            variables: List of variables to plot
            title: Chart title
            units: Dictionary with units per variable
            
        Returns:
            Plotly figure
        """
        if units is None:
            units = {}
        
        fig = go.Figure()
        
        colors = px.colors.qualitative.Set1
        
        for i, var in enumerate(variables):
            if var in df.columns:
                color = colors[i % len(colors)]
                
                fig.add_trace(go.Scatter(
                    x=df.index if 'time' not in df.columns else df['time'],
                    y=df[var],
                    mode='lines',
                    name=f"{var}" + (f" [{units.get(var, '')}]" if units.get(var) else ""),
                    line=dict(color=color, width=2),
                    hovertemplate=f'{var}: %{{y}}<br>Time: %{{x}}<extra></extra>'
                ))
        
        # Configure layout
        layout = PlotUtils.create_base_layout(title, height=500)
        layout.update({
            'xaxis': PlotUtils.format_axis({}, 'Time', 'days'),
            'yaxis': PlotUtils.format_axis({}, 'Value'),
            'legend': dict(x=0.02, y=0.98, bgcolor='rgba(255,255,255,0.8)')
        })
        
        fig.update_layout(**layout)
        
        return fig
    
    @staticmethod
    def create_dual_axis_plot(df: pd.DataFrame, 
                             left_vars: List[str], right_vars: List[str],
                             title: str = "Dual Axis Chart",
                             left_title: str = "Left Axis",
                             right_title: str = "Right Axis") -> go.Figure:
        """
        Create chart with dual Y axis.
        
        Args:
            df: DataFrame with data
            left_vars: Variables for left axis
            right_vars: Variables for right axis
            title: Chart title
            left_title: Left axis title
            right_title: Right axis title
            
        Returns:
            Plotly figure
        """
        fig = make_subplots(specs=[[{"secondary_y": True}]])
        
        colors = px.colors.qualitative.Set1
        time_col = df.index if 'time' not in df.columns else df['time']
        
        # Left axis variables
        for i, var in enumerate(left_vars):
            if var in df.columns:
                fig.add_trace(
                    go.Scatter(
                        x=time_col,
                        y=df[var],
                        mode='lines',
                        name=var,
                        line=dict(color=colors[i % len(colors)], width=2)
                    ),
                    secondary_y=False
                )
        
        # Right axis variables
        for i, var in enumerate(right_vars):
            if var in df.columns:
                fig.add_trace(
                    go.Scatter(
                        x=time_col,
                        y=df[var],
                        mode='lines',
                        name=var,
                        line=dict(color=colors[(i + len(left_vars)) % len(colors)], 
                                width=2, dash='dash')
                    ),
                    secondary_y=True
                )
        
        # Configure axes
        fig.update_xaxes(title_text="Time [days]")
        fig.update_yaxes(title_text=left_title, secondary_y=False)
        fig.update_yaxes(title_text=right_title, secondary_y=True)
        
        fig.update_layout(
            title=title,
            height=500,
            legend=dict(x=0.02, y=0.98, bgcolor='rgba(255,255,255,0.8)')
        )
        
        return fig

class WellVisualizer:
    """Visualizer for well data"""
    
    @staticmethod
    def create_well_map(producers: List[Dict], injectors: List[Dict],
                       nx: int = 20, ny: int = 20,
                       background_data: np.ndarray = None) -> go.Figure:
        """
        Create well location map.
        
        Args:
            producers: List of producer wells
            injectors: List of injector wells
            nx, ny: Grid dimensions
            background_data: Background data (optional)
            
        Returns:
            Plotly figure
        """
        fig = go.Figure()
        
        # Add background data if available
        if background_data is not None:
            fig.add_trace(go.Heatmap(
                z=background_data,
                colorscale='Greys',
                showscale=False,
                opacity=0.3,
                hoverinfo='skip'
            ))
        
        # Add producer wells
        if producers:
            prod_x = [well['location'][0] for well in producers]
            prod_y = [well['location'][1] for well in producers]
            prod_names = [well['name'] for well in producers]
            
            fig.add_trace(go.Scatter(
                x=prod_x, y=prod_y,
                mode='markers+text',
                marker=dict(
                    symbol='circle',
                    size=15,
                    color='red',
                    line=dict(width=2, color='darkred')
                ),
                text=prod_names,
                textposition='top center',
                name='Producers',
                hovertemplate='Producer: %{text}<br>X: %{x}<br>Y: %{y}<extra></extra>'
            ))
        
        # Add injector wells
        if injectors:
            inj_x = [well['location'][0] for well in injectors]
            inj_y = [well['location'][1] for well in injectors]
            inj_names = [well['name'] for well in injectors]
            
            fig.add_trace(go.Scatter(
                x=inj_x, y=inj_y,
                mode='markers+text',
                marker=dict(
                    symbol='square',
                    size=15,
                    color='blue',
                    line=dict(width=2, color='darkblue')
                ),
                text=inj_names,
                textposition='top center',
                name='Injectors',
                hovertemplate='Injector: %{text}<br>X: %{x}<br>Y: %{y}<extra></extra>'
            ))
        
        # Configure layout
        layout = PlotUtils.create_base_layout("Well Map", height=600)
        layout.update({
            'xaxis': PlotUtils.format_axis({'range': [0, nx]}, 'X Position', 'grid cells'),
            'yaxis': PlotUtils.format_axis({'range': [0, ny]}, 'Y Position', 'grid cells'),
            'aspect': dict(ratio=1)
        })
        
        fig.update_layout(**layout)
        
        return fig

class StatisticalVisualizer:
    """Visualizer for statistical analysis"""
    
    @staticmethod
    def create_histogram(data: np.ndarray, title: str, 
                        bins: int = 50, units: str = "") -> go.Figure:
        """
        Create distribution histogram.
        
        Args:
            data: Array with data
            title: Chart title
            bins: Number of bins
            units: Units of measurement
            
        Returns:
            Plotly figure
        """
        fig = go.Figure(data=[go.Histogram(
            x=data.flatten(),
            nbinsx=bins,
            marker_color='lightblue',
            marker_line_color='black',
            marker_line_width=1,
            opacity=0.7
        )])
        
        # Configure layout
        layout = PlotUtils.create_base_layout(f"Distribution of {title}")
        layout.update({
            'xaxis': PlotUtils.format_axis({}, title, units),
            'yaxis': PlotUtils.format_axis({}, 'Frequency'),
            'bargap': 0.1
        })
        
        fig.update_layout(**layout)
        
        return fig
    
    @staticmethod
    def create_correlation_matrix(df: pd.DataFrame, title: str = "Correlation Matrix") -> go.Figure:
        """
        Create correlation matrix.
        
        Args:
            df: DataFrame with data
            title: Chart title
            
        Returns:
            Plotly figure
        """
        # Calculate correlation matrix
        corr_matrix = df.corr()
        
        fig = go.Figure(data=go.Heatmap(
            z=corr_matrix.values,
            x=corr_matrix.columns,
            y=corr_matrix.columns,
            colorscale='RdBu',
            zmid=0,
            colorbar=dict(title="Correlation"),
            hovertemplate='%{x} vs %{y}<br>Correlation: %{z:.3f}<extra></extra>'
        ))
        
        # Configure layout
        layout = PlotUtils.create_base_layout(title)
        layout.update({
            'xaxis': dict(tickangle=45),
            'yaxis': dict(tickangle=0)
        })
        
        fig.update_layout(**layout)
        
        return fig