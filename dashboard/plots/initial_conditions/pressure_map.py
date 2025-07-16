"""
Initial Pressure Map Visualization

Creates 2D colormesh visualization of initial pressure distribution.
Data: initial/initial_conditions.mat - pressure [20×20] in psi
"""

import numpy as np
import plotly.graph_objects as go
import plotly.express as px
from typing import Optional, Dict, Any
import sys
from pathlib import Path
sys.path.append(str(Path(__file__).parent.parent))
from plot_utils import format_grid_plot

def create_initial_pressure_map(
    pressure_data: np.ndarray,
    grid_x: Optional[np.ndarray] = None,
    grid_y: Optional[np.ndarray] = None,
    title: str = "Initial Pressure Distribution",
    colorscale: str = "viridis",
    wells_data: Optional[Dict] = None
) -> go.Figure:
    """
    Create 2D pressure map visualization for initial conditions.
    
    Args:
        pressure_data: Pressure field [20×20] in psi
        grid_x: Grid x-coordinates [21×1] in meters (optional)
        grid_y: Grid y-coordinates [21×1] in meters (optional)
        title: Plot title
        colorscale: Plotly colorscale name
        
    Returns:
        plotly.graph_objects.Figure: Interactive pressure map
    """
    # Validate input data
    if pressure_data is None:
        raise ValueError("Pressure data cannot be None")
    
    if pressure_data.shape != (20, 20):
        raise ValueError(f"Expected pressure shape (20, 20), got {pressure_data.shape}")
    
    # Create coordinate grids if not provided
    if grid_x is None:
        grid_x = np.linspace(0, 20*164.0, 21)  # 164 ft cell size
    if grid_y is None:
        grid_y = np.linspace(0, 20*164.0, 21)
    
    # Create meshgrid for plotting
    X, Y = np.meshgrid(grid_x, grid_y)
    
    # Create heatmap
    fig = go.Figure(data=go.Heatmap(
        z=pressure_data,
        x=grid_x[:-1],  # Cell centers
        y=grid_y[:-1],
        colorscale=colorscale,
        colorbar=dict(
            title="Pressure (psi)"
        ),
        hovertemplate="<b>Position</b><br>" +
                      "X: %{x:.1f} ft<br>" +
                      "Y: %{y:.1f} ft<br>" +
                      "<b>Pressure: %{z:.1f} psi</b><br>" +
                      "<extra></extra>"
    ))
    
    # Format plot with wells and square aspect ratio
    format_grid_plot(fig, title, "Pressure (psi)", wells_data, grid_x, grid_y)
    
    return fig

def create_pressure_statistics_summary(pressure_data: np.ndarray) -> Dict[str, Any]:
    """
    Calculate pressure field statistics for initial conditions.
    
    Args:
        pressure_data: Pressure field [20×20] in psi
        
    Returns:
        dict: Statistical summary
    """
    if pressure_data is None:
        return {}
    
    return {
        'min_pressure': float(np.min(pressure_data)),
        'max_pressure': float(np.max(pressure_data)),
        'mean_pressure': float(np.mean(pressure_data)),
        'std_pressure': float(np.std(pressure_data)),
        'median_pressure': float(np.median(pressure_data)),
        'pressure_range': float(np.max(pressure_data) - np.min(pressure_data))
    }