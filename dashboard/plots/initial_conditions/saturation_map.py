"""
Initial Saturation Map Visualization

Creates 2D colormesh visualization of initial water saturation distribution.
Data: initial/initial_conditions.mat - sw [20×20] dimensionless
"""

import numpy as np
import plotly.graph_objects as go
import plotly.express as px
from typing import Optional, Dict, Any
import sys
from pathlib import Path
sys.path.append(str(Path(__file__).parent.parent))
from plot_utils import format_grid_plot

def create_initial_saturation_map(
    saturation_data: np.ndarray,
    grid_x: Optional[np.ndarray] = None,
    grid_y: Optional[np.ndarray] = None,
    title: str = "Initial Water Saturation Distribution",
    colorscale: str = "blues",
    wells_data: Optional[Dict] = None
) -> go.Figure:
    """
    Create 2D saturation map visualization for initial conditions.
    
    Args:
        saturation_data: Water saturation field [20×20] dimensionless
        grid_x: Grid x-coordinates [21×1] in meters (optional)
        grid_y: Grid y-coordinates [21×1] in meters (optional)
        title: Plot title
        colorscale: Plotly colorscale name
        
    Returns:
        plotly.graph_objects.Figure: Interactive saturation map
    """
    # Validate input data
    if saturation_data is None:
        raise ValueError("Saturation data cannot be None")
    
    if saturation_data.shape != (20, 20):
        raise ValueError(f"Expected saturation shape (20, 20), got {saturation_data.shape}")
    
    # Create coordinate grids if not provided
    if grid_x is None:
        grid_x = np.linspace(0, 20*164.0, 21)  # 164 ft cell size
    if grid_y is None:
        grid_y = np.linspace(0, 20*164.0, 21)
    
    # Create heatmap
    fig = go.Figure(data=go.Heatmap(
        z=saturation_data,
        x=grid_x[:-1],  # Cell centers
        y=grid_y[:-1],
        colorscale=colorscale,
        zmin=0,
        zmax=1,
        colorbar=dict(
            title="Water Saturation",
            
            tickformat=".2f"
        ),
        hovertemplate="<b>Position</b><br>" +
                      "X: %{x:.1f} ft<br>" +
                      "Y: %{y:.1f} ft<br>" +
                      "<b>Sw: %{z:.3f}</b><br>" +
                      "<extra></extra>"
    ))
    
    # Format plot with wells and square aspect ratio
    format_grid_plot(fig, title, "Water Saturation", wells_data, grid_x, grid_y)
    
    return fig

def create_saturation_statistics_summary(saturation_data: np.ndarray) -> Dict[str, Any]:
    """
    Calculate saturation field statistics for initial conditions.
    
    Args:
        saturation_data: Water saturation field [20×20] dimensionless
        
    Returns:
        dict: Statistical summary
    """
    if saturation_data is None:
        return {}
    
    return {
        'min_saturation': float(np.min(saturation_data)),
        'max_saturation': float(np.max(saturation_data)),
        'mean_saturation': float(np.mean(saturation_data)),
        'std_saturation': float(np.std(saturation_data)),
        'median_saturation': float(np.median(saturation_data)),
        'oil_saturation_mean': float(np.mean(1.0 - saturation_data))
    }