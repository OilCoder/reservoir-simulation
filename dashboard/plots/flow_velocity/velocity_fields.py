"""
Velocity Field Visualization

Creates quiver plots and velocity magnitude maps.
Data: dynamic/fields/flow_data.mat - vx, vy, velocity_magnitude
"""

import numpy as np
import plotly.graph_objects as go
from typing import Optional, Dict, Any

def create_velocity_field_plot(
    flow_data: Dict[str, Any],
    timestep: int,
    title: Optional[str] = None,
    subsample: int = 2
) -> go.Figure:
    """
    Create velocity field quiver plot.
    
    Args:
        flow_data: Flow data dictionary containing vx, vy
        timestep: Time step index
        title: Plot title
        subsample: Subsampling factor for arrows
        
    Returns:
        plotly.graph_objects.Figure: Interactive velocity field plot
    """
    vx = flow_data['vx'][timestep, ::subsample, ::subsample]
    vy = flow_data['vy'][timestep, ::subsample, ::subsample]
    
    # Create coordinate grids
    x = np.linspace(0, 20*164.0, vx.shape[1])
    y = np.linspace(0, 20*164.0, vx.shape[0])
    X, Y = np.meshgrid(x, y)
    
    if title is None:
        title = f"Velocity Field - Time Step {timestep}"
    
    fig = go.Figure(data=go.Scatter(
        x=X.flatten(),
        y=Y.flatten(),
        mode="markers",
        marker=dict(
            size=8,
            symbol="arrow",
            angle=np.degrees(np.arctan2(vy.flatten(), vx.flatten())),
            color=np.sqrt(vx.flatten()**2 + vy.flatten()**2),
            colorscale="viridis",
            colorbar=dict(title="Velocity Magnitude")
        ),
        hovertemplate="<b>Position</b><br>" +
                      "X: %{x:.1f} ft<br>" +
                      "Y: %{y:.1f} ft<br>" +
                      "<extra></extra>"
    ))
    
    fig.update_layout(
        title=dict(text=title, x=0.5, font=dict(size=16)),
        xaxis=dict(title="X Distance (ft)", showgrid=True),
        yaxis=dict(title="Y Distance (ft)", showgrid=True),
        plot_bgcolor="white",
        width=600,
        height=500
    )
    
    return fig

def create_velocity_magnitude_plot(
    flow_data: Dict[str, Any],
    timestep: int,
    title: Optional[str] = None
) -> go.Figure:
    """
    Create velocity magnitude heatmap.
    
    Args:
        flow_data: Flow data dictionary containing velocity_magnitude
        timestep: Time step index
        title: Plot title
        
    Returns:
        plotly.graph_objects.Figure: Interactive velocity magnitude plot
    """
    velocity_mag = flow_data['velocity_magnitude'][timestep, :, :]
    
    # Create coordinate grids
    x = np.linspace(0, 20*164.0, 21)
    y = np.linspace(0, 20*164.0, 21)
    
    if title is None:
        title = f"Velocity Magnitude - Time Step {timestep}"
    
    fig = go.Figure(data=go.Heatmap(
        z=velocity_mag,
        x=x[:-1],
        y=y[:-1],
        colorscale="hot",
        colorbar=dict(title="Velocity Magnitude")
    ))
    
    fig.update_layout(
        title=dict(text=title, x=0.5, font=dict(size=16)),
        xaxis=dict(title="X Distance (ft)", showgrid=True),
        yaxis=dict(title="Y Distance (ft)", showgrid=True),
        plot_bgcolor="white",
        width=600,
        height=500
    )
    
    return fig