"""
Porosity Map Visualization

Creates 2D colormesh visualization of porosity distribution.
Data: initial/initial_conditions.mat - phi [20×20] dimensionless
"""

import numpy as np
import plotly.graph_objects as go
from typing import Optional, Dict, Any
import sys
from pathlib import Path
sys.path.append(str(Path(__file__).parent.parent))
from plot_utils import format_grid_plot

def create_porosity_map(
    porosity_data: np.ndarray,
    grid_x: Optional[np.ndarray] = None,
    grid_y: Optional[np.ndarray] = None,
    title: str = "Porosity Distribution",
    colorscale: str = "plasma",
    wells_data: Optional[Dict] = None
) -> go.Figure:
    """
    Create 2D porosity map visualization.
    
    Args:
        porosity_data: Porosity field [20×20] dimensionless
        grid_x: Grid x-coordinates [21×1] in meters (optional)
        grid_y: Grid y-coordinates [21×1] in meters (optional)
        title: Plot title
        colorscale: Plotly colorscale name
        
    Returns:
        plotly.graph_objects.Figure: Interactive porosity map
    """
    # Validate input data
    if porosity_data is None:
        raise ValueError("Porosity data cannot be None")
    
    if porosity_data.shape != (20, 20):
        raise ValueError(f"Expected porosity shape (20, 20), got {porosity_data.shape}")
    
    # Create coordinate grids if not provided
    if grid_x is None:
        grid_x = np.linspace(0, 20*164.0, 21)  # 164 ft cell size
    if grid_y is None:
        grid_y = np.linspace(0, 20*164.0, 21)
    
    # Create heatmap
    fig = go.Figure(data=go.Heatmap(
        z=porosity_data,
        x=grid_x[:-1],  # Cell centers
        y=grid_y[:-1],
        colorscale=colorscale,
        zmin=0,
        zmax=0.5,  # Typical porosity range
        colorbar=dict(
            title="Porosity",
            
            tickformat=".3f"
        ),
        hovertemplate="<b>Position</b><br>" +
                      "X: %{x:.1f} ft<br>" +
                      "Y: %{y:.1f} ft<br>" +
                      "<b>Porosity: %{z:.3f}</b><br>" +
                      "<extra></extra>"
    ))
    
    # Format plot with wells and square aspect ratio
    format_grid_plot(fig, title, "Porosity", wells_data, grid_x, grid_y)
    
    return fig

def create_porosity_statistics_summary(porosity_data: np.ndarray) -> Dict[str, Any]:
    """
    Calculate porosity field statistics.
    
    Args:
        porosity_data: Porosity field [20×20] dimensionless
        
    Returns:
        dict: Statistical summary
    """
    if porosity_data is None:
        return {}
    
    return {
        'min_porosity': float(np.min(porosity_data)),
        'max_porosity': float(np.max(porosity_data)),
        'mean_porosity': float(np.mean(porosity_data)),
        'std_porosity': float(np.std(porosity_data)),
        'median_porosity': float(np.median(porosity_data)),
        'coefficient_of_variation': float(np.std(porosity_data) / np.mean(porosity_data))
    }