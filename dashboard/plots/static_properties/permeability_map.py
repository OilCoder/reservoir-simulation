"""
Permeability Map Visualization

Creates 2D colormesh visualization of permeability distribution.
Data: initial/initial_conditions.mat - k [20×20] in mD
"""

import numpy as np
import plotly.graph_objects as go
from typing import Optional, Dict, Any
import sys
from pathlib import Path
sys.path.append(str(Path(__file__).parent.parent))
from plot_utils import format_grid_plot

def create_permeability_map(
    permeability_data: np.ndarray,
    grid_x: Optional[np.ndarray] = None,
    grid_y: Optional[np.ndarray] = None,
    title: str = "Permeability Distribution",
    colorscale: str = "hot",
    log_scale: bool = True,
    wells_data: Optional[Dict] = None
) -> go.Figure:
    """
    Create 2D permeability map visualization.
    
    Args:
        permeability_data: Permeability field [20×20] in mD
        grid_x: Grid x-coordinates [21×1] in meters (optional)
        grid_y: Grid y-coordinates [21×1] in meters (optional)
        title: Plot title
        colorscale: Plotly colorscale name
        log_scale: Whether to use logarithmic scale
        
    Returns:
        plotly.graph_objects.Figure: Interactive permeability map
    """
    # Validate input data
    if permeability_data is None:
        raise ValueError("Permeability data cannot be None")
    
    if permeability_data.shape != (20, 20):
        raise ValueError(f"Expected permeability shape (20, 20), got {permeability_data.shape}")
    
    # Create coordinate grids if not provided
    if grid_x is None:
        grid_x = np.linspace(0, 20*164.0, 21)  # 164 ft cell size
    if grid_y is None:
        grid_y = np.linspace(0, 20*164.0, 21)
    
    # Handle logarithmic scale
    plot_data = permeability_data
    colorbar_title = "Permeability (mD)"
    tickformat = ".1f"
    
    if log_scale and np.all(permeability_data > 0):
        plot_data = np.log10(permeability_data)
        colorbar_title = "Log₁₀ Permeability (mD)"
        tickformat = ".2f"
    
    # Create heatmap
    fig = go.Figure(data=go.Heatmap(
        z=plot_data,
        x=grid_x[:-1],  # Cell centers
        y=grid_y[:-1],
        colorscale=colorscale,
        colorbar=dict(
            title=colorbar_title,
            
            tickformat=tickformat
        ),
        hovertemplate="<b>Position</b><br>" +
                      "X: %{x:.1f} ft<br>" +
                      "Y: %{y:.1f} ft<br>" +
                      "<b>Permeability: %{customdata:.1f} mD</b><br>" +
                      "<extra></extra>",
        customdata=permeability_data
    ))
    
    # Format plot with wells and square aspect ratio
    format_grid_plot(fig, title, colorbar_title, wells_data, grid_x, grid_y)
    
    return fig

def create_permeability_statistics_summary(permeability_data: np.ndarray) -> Dict[str, Any]:
    """
    Calculate permeability field statistics.
    
    Args:
        permeability_data: Permeability field [20×20] in mD
        
    Returns:
        dict: Statistical summary
    """
    if permeability_data is None:
        return {}
    
    return {
        'min_permeability': float(np.min(permeability_data)),
        'max_permeability': float(np.max(permeability_data)),
        'mean_permeability': float(np.mean(permeability_data)),
        'std_permeability': float(np.std(permeability_data)),
        'median_permeability': float(np.median(permeability_data)),
        'geometric_mean': float(np.exp(np.mean(np.log(permeability_data[permeability_data > 0])))),
        'coefficient_of_variation': float(np.std(permeability_data) / np.mean(permeability_data))
    }