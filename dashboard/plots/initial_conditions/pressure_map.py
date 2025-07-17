"""
Initial Pressure Map Visualization

Creates 2D colormesh visualization of initial pressure distribution.
Data: initial/initial_conditions.mat - pressure [20×20] in psi
"""

import numpy as np
import plotly.graph_objects as go
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
    wells_data: Optional[Dict] = None,
    layer_idx: Optional[int] = None
) -> go.Figure:
    """
    Create 2D pressure map visualization for initial conditions.
    
    Args:
        pressure_data: Pressure field [y,x] or [z,y,x] in psi
        grid_x: Grid x-coordinates in meters (optional)
        grid_y: Grid y-coordinates in meters (optional)
        title: Plot title
        colorscale: Plotly colorscale name
        wells_data: Wells data dictionary
        layer_idx: Layer index for 3D data (optional)
        
    Returns:
        plotly.graph_objects.Figure: Interactive pressure map
    """
    # Validate input data
    if pressure_data is None:
        raise ValueError("Pressure data cannot be None")
    
    # Handle 3D data
    if len(pressure_data.shape) == 3:
        # 3D data [z, y, x]
        if layer_idx is None:
            # Use middle layer by default
            layer_idx = pressure_data.shape[0] // 2
        pressure_2d = pressure_data[layer_idx, :, :]
        title = f"{title} - Layer {layer_idx + 1}"
    else:
        # 2D data [y, x]
        pressure_2d = pressure_data
    
    # Create coordinate grids if not provided
    if grid_x is None:
        nx = pressure_2d.shape[1]
        grid_x = np.linspace(0, nx*164.0, nx+1)  # 164 ft cell size
    if grid_y is None:
        ny = pressure_2d.shape[0]
        grid_y = np.linspace(0, ny*164.0, ny+1)
    
    # Create heatmap
    fig = go.Figure(data=go.Heatmap(
        z=pressure_2d,
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
        pressure_data: Pressure field [y,x] or [z,y,x] in psi
        
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

def create_vertical_pressure_profile(
    pressure_data: np.ndarray,
    depth_data: Optional[np.ndarray] = None,
    well_location: Optional[tuple] = None,
    title: str = "Vertical Pressure Profile"
) -> go.Figure:
    """
    Create vertical pressure profile for 3D data.
    
    Args:
        pressure_data: Pressure field [z, y, x] in psi
        depth_data: Depth field [z, y, x] in ft (optional)
        well_location: (i, j) location for profile (optional, uses center if None)
        title: Plot title
        
    Returns:
        plotly.graph_objects.Figure: Vertical pressure profile
    """
    if len(pressure_data.shape) != 3:
        raise ValueError("Vertical profile requires 3D pressure data")
    
    nz, ny, nx = pressure_data.shape
    
    # Use center location if not specified
    if well_location is None:
        well_location = (nx // 2, ny // 2)
    
    i, j = well_location
    
    # Extract vertical profile
    pressure_profile = pressure_data[:, j, i]
    
    # Create depth array if not provided
    if depth_data is None:
        # Assume uniform spacing
        depth_profile = np.linspace(7900, 8138, nz)  # Based on config
    else:
        depth_profile = depth_data[:, j, i]
    
    # Create figure
    fig = go.Figure()
    
    # Add pressure profile
    fig.add_trace(go.Scatter(
        x=pressure_profile,
        y=depth_profile,
        mode='lines+markers',
        name='Pressure',
        line=dict(color='blue', width=2),
        marker=dict(size=8)
    ))
    
    # Update layout
    fig.update_layout(
        title=title,
        xaxis_title="Pressure (psi)",
        yaxis_title="Depth (ft)",
        yaxis=dict(autorange='reversed'),  # Depth increases downward
        template="plotly_white",
        height=600,
        showlegend=False
    )
    
    # Add grid
    fig.update_xaxis(showgrid=True, gridwidth=1, gridcolor='lightgray')
    fig.update_yaxis(showgrid=True, gridwidth=1, gridcolor='lightgray')
    
    return fig