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
    wells_data: Optional[Dict] = None,
    layer_idx: Optional[int] = None
) -> go.Figure:
    """
    Create 2D saturation map visualization for initial conditions.
    
    Args:
        saturation_data: Water saturation field [y,x] or [z,y,x] dimensionless
        grid_x: Grid x-coordinates in meters (optional)
        grid_y: Grid y-coordinates in meters (optional)
        title: Plot title
        colorscale: Plotly colorscale name
        wells_data: Wells data dictionary
        layer_idx: Layer index for 3D data (optional)
        
    Returns:
        plotly.graph_objects.Figure: Interactive saturation map
    """
    # Validate input data
    if saturation_data is None:
        raise ValueError("Saturation data cannot be None")
    
    # Handle 3D data
    if len(saturation_data.shape) == 3:
        # 3D data [z, y, x]
        if layer_idx is None:
            # Use middle layer by default
            layer_idx = saturation_data.shape[0] // 2
        saturation_2d = saturation_data[layer_idx, :, :]
        title = f"{title} - Layer {layer_idx + 1}"
    else:
        # 2D data [y, x]
        saturation_2d = saturation_data
    
    # Create coordinate grids if not provided
    if grid_x is None:
        nx = saturation_2d.shape[1]
        grid_x = np.linspace(0, nx*164.0, nx+1)  # 164 ft cell size
    if grid_y is None:
        ny = saturation_2d.shape[0]
        grid_y = np.linspace(0, ny*164.0, ny+1)
    
    # Create heatmap
    fig = go.Figure(data=go.Heatmap(
        z=saturation_2d,
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
        saturation_data: Water saturation field [y,x] or [z,y,x] dimensionless
        
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

def create_vertical_saturation_profile(
    saturation_data: np.ndarray,
    depth_data: Optional[np.ndarray] = None,
    well_location: Optional[tuple] = None,
    title: str = "Vertical Saturation Profile"
) -> go.Figure:
    """
    Create vertical saturation profile for 3D data.
    
    Args:
        saturation_data: Water saturation field [z, y, x] dimensionless
        depth_data: Depth field [z, y, x] in ft (optional)
        well_location: (i, j) location for profile (optional, uses center if None)
        title: Plot title
        
    Returns:
        plotly.graph_objects.Figure: Vertical saturation profile
    """
    if len(saturation_data.shape) != 3:
        raise ValueError("Vertical profile requires 3D saturation data")
    
    nz, ny, nx = saturation_data.shape
    
    # Use center location if not specified
    if well_location is None:
        well_location = (nx // 2, ny // 2)
    
    i, j = well_location
    
    # Extract vertical profile
    sw_profile = saturation_data[:, j, i]
    so_profile = 1.0 - sw_profile  # Oil saturation
    
    # Create depth array if not provided
    if depth_data is None:
        # Assume uniform spacing
        depth_profile = np.linspace(7900, 8138, nz)  # Based on config
    else:
        depth_profile = depth_data[:, j, i]
    
    # Create figure
    fig = go.Figure()
    
    # Add water saturation profile
    fig.add_trace(go.Scatter(
        x=sw_profile,
        y=depth_profile,
        mode='lines+markers',
        name='Water Saturation',
        line=dict(color='blue', width=2),
        marker=dict(size=8)
    ))
    
    # Add oil saturation profile
    fig.add_trace(go.Scatter(
        x=so_profile,
        y=depth_profile,
        mode='lines+markers',
        name='Oil Saturation',
        line=dict(color='green', width=2),
        marker=dict(size=8)
    ))
    
    # Update layout
    fig.update_layout(
        title=title,
        xaxis_title="Saturation (-)",
        yaxis_title="Depth (ft)",
        yaxis=dict(autorange='reversed'),  # Depth increases downward
        xaxis=dict(range=[0, 1]),
        template="plotly_white",
        height=600,
        showlegend=True,
        legend=dict(x=0.7, y=0.95)
    )
    
    # Add grid
    fig.update_xaxis(showgrid=True, gridwidth=1, gridcolor='lightgray')
    fig.update_yaxis(showgrid=True, gridwidth=1, gridcolor='lightgray')
    
    return fig