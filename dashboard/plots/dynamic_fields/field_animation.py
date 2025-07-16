"""
Dynamic Field Animation

Creates animated visualizations of field evolution over time.
Data: dynamic/fields/field_arrays.mat
"""

import numpy as np
import plotly.graph_objects as go
from typing import Optional, Dict, Any, List

def create_pressure_animation(
    pressure_data: np.ndarray,
    time_days: np.ndarray,
    grid_x: Optional[np.ndarray] = None,
    grid_y: Optional[np.ndarray] = None,
    title: str = "Pressure Evolution Animation",
    colorscale: str = "viridis",
    frame_duration: int = 500
) -> go.Figure:
    """
    Create animated visualization of pressure field evolution.
    
    Args:
        pressure_data: Pressure field [n_timesteps, 20, 20] in psi
        time_days: Time vector [n_timesteps] in days
        grid_x: Grid x-coordinates [21×1] in meters (optional)
        grid_y: Grid y-coordinates [21×1] in meters (optional)
        title: Plot title
        colorscale: Plotly colorscale name
        frame_duration: Animation frame duration in milliseconds
        
    Returns:
        plotly.graph_objects.Figure: Interactive animated plot
    """
    # Validate input data
    if pressure_data is None:
        raise ValueError("Pressure data cannot be None")
    if time_days is None:
        raise ValueError("Time data cannot be None")
    
    if len(pressure_data.shape) != 3:
        raise ValueError(f"Expected 3D pressure data, got shape {pressure_data.shape}")
    
    if len(time_days) != pressure_data.shape[0]:
        raise ValueError(f"Time vector length {len(time_days)} doesn't match pressure timesteps {pressure_data.shape[0]}")
    
    # Create coordinate grids if not provided
    if grid_x is None:
        grid_x = np.linspace(0, 20*164.0, 21)  # 164 ft cell size
    if grid_y is None:
        grid_y = np.linspace(0, 20*164.0, 21)
    
    # Determine color scale limits
    z_min = np.min(pressure_data)
    z_max = np.max(pressure_data)
    
    # Create initial frame
    fig = go.Figure(data=go.Heatmap(
        z=pressure_data[0, :, :],
        x=grid_x[:-1],
        y=grid_y[:-1],
        colorscale=colorscale,
        zmin=z_min,
        zmax=z_max,
        colorbar=dict(
            title="Pressure (psi)",
            titleside="right"
        ),
        hovertemplate="<b>Position</b><br>" +
                      "X: %{x:.1f} ft<br>" +
                      "Y: %{y:.1f} ft<br>" +
                      "<b>Pressure: %{z:.1f} psi</b><br>" +
                      "<extra></extra>"
    ))
    
    # Create animation frames
    frames = []
    for i in range(len(time_days)):
        frame = go.Frame(
            data=[go.Heatmap(
                z=pressure_data[i, :, :],
                x=grid_x[:-1],
                y=grid_y[:-1],
                colorscale=colorscale,
                zmin=z_min,
                zmax=z_max,
                colorbar=dict(
                    title="Pressure (psi)",
                    titleside="right"
                ),
                hovertemplate="<b>Position</b><br>" +
                              "X: %{x:.1f} ft<br>" +
                              "Y: %{y:.1f} ft<br>" +
                              "<b>Pressure: %{z:.1f} psi</b><br>" +
                              "<extra></extra>"
            )],
            name=f"Day {time_days[i]:.1f}",
            layout=go.Layout(
                title=f"{title} - Day {time_days[i]:.1f}"
            )
        )
        frames.append(frame)
    
    fig.frames = frames
    
    # Add animation controls
    fig.update_layout(
        title=dict(
            text=f"{title} - Day {time_days[0]:.1f}",
            x=0.5,
            font=dict(size=16)
        ),
        xaxis=dict(
            title="X Distance (ft)",
            showgrid=True,
            gridcolor="lightgray",
            gridwidth=1
        ),
        yaxis=dict(
            title="Y Distance (ft)",
            showgrid=True,
            gridcolor="lightgray",
            gridwidth=1
        ),
        plot_bgcolor="white",
        width=700,
        height=600,
        margin=dict(l=50, r=50, t=70, b=50),
        updatemenus=[{
            "type": "buttons",
            "direction": "left",
            "pad": {"r": 10, "t": 87},
            "showactive": False,
            "x": 0.1,
            "xanchor": "right",
            "y": 0,
            "yanchor": "top",
            "buttons": [
                {
                    "label": "Play",
                    "method": "animate",
                    "args": [None, {
                        "frame": {"duration": frame_duration, "redraw": True},
                        "fromcurrent": True,
                        "transition": {"duration": 100}
                    }]
                },
                {
                    "label": "Pause",
                    "method": "animate",
                    "args": [[None], {
                        "frame": {"duration": 0, "redraw": True},
                        "mode": "immediate",
                        "transition": {"duration": 0}
                    }]
                }
            ]
        }],
        sliders=[{
            "active": 0,
            "yanchor": "top",
            "xanchor": "left",
            "currentvalue": {
                "font": {"size": 20},
                "prefix": "Day: ",
                "visible": True,
                "xanchor": "right"
            },
            "transition": {"duration": 100},
            "pad": {"b": 10, "t": 50},
            "len": 0.9,
            "x": 0.1,
            "y": 0,
            "steps": [
                {
                    "args": [[frame.name], {
                        "frame": {"duration": frame_duration, "redraw": True},
                        "mode": "immediate",
                        "transition": {"duration": 100}
                    }],
                    "label": f"{time_days[i]:.1f}",
                    "method": "animate"
                }
                for i, frame in enumerate(frames)
            ]
        }]
    )
    
    return fig

def create_saturation_animation(
    saturation_data: np.ndarray,
    time_days: np.ndarray,
    grid_x: Optional[np.ndarray] = None,
    grid_y: Optional[np.ndarray] = None,
    title: str = "Water Saturation Evolution Animation",
    colorscale: str = "blues",
    frame_duration: int = 500
) -> go.Figure:
    """
    Create animated visualization of water saturation field evolution.
    
    Args:
        saturation_data: Saturation field [n_timesteps, 20, 20] dimensionless
        time_days: Time vector [n_timesteps] in days
        grid_x: Grid x-coordinates [21×1] in meters (optional)
        grid_y: Grid y-coordinates [21×1] in meters (optional)
        title: Plot title
        colorscale: Plotly colorscale name
        frame_duration: Animation frame duration in milliseconds
        
    Returns:
        plotly.graph_objects.Figure: Interactive animated plot
    """
    # Validate input data
    if saturation_data is None:
        raise ValueError("Saturation data cannot be None")
    if time_days is None:
        raise ValueError("Time data cannot be None")
    
    if len(saturation_data.shape) != 3:
        raise ValueError(f"Expected 3D saturation data, got shape {saturation_data.shape}")
    
    if len(time_days) != saturation_data.shape[0]:
        raise ValueError(f"Time vector length {len(time_days)} doesn't match saturation timesteps {saturation_data.shape[0]}")
    
    # Create coordinate grids if not provided
    if grid_x is None:
        grid_x = np.linspace(0, 20*164.0, 21)  # 164 ft cell size
    if grid_y is None:
        grid_y = np.linspace(0, 20*164.0, 21)
    
    # Create initial frame
    fig = go.Figure(data=go.Heatmap(
        z=saturation_data[0, :, :],
        x=grid_x[:-1],
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
    
    # Create animation frames
    frames = []
    for i in range(len(time_days)):
        frame = go.Frame(
            data=[go.Heatmap(
                z=saturation_data[i, :, :],
                x=grid_x[:-1],
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
            )],
            name=f"Day {time_days[i]:.1f}",
            layout=go.Layout(
                title=f"{title} - Day {time_days[i]:.1f}"
            )
        )
        frames.append(frame)
    
    fig.frames = frames
    
    # Add animation controls
    fig.update_layout(
        title=dict(
            text=f"{title} - Day {time_days[0]:.1f}",
            x=0.5,
            font=dict(size=16)
        ),
        xaxis=dict(
            title="X Distance (ft)",
            showgrid=True,
            gridcolor="lightgray",
            gridwidth=1
        ),
        yaxis=dict(
            title="Y Distance (ft)",
            showgrid=True,
            gridcolor="lightgray",
            gridwidth=1
        ),
        plot_bgcolor="white",
        width=700,
        height=600,
        margin=dict(l=50, r=50, t=70, b=50),
        updatemenus=[{
            "type": "buttons",
            "direction": "left",
            "pad": {"r": 10, "t": 87},
            "showactive": False,
            "x": 0.1,
            "xanchor": "right",
            "y": 0,
            "yanchor": "top",
            "buttons": [
                {
                    "label": "Play",
                    "method": "animate",
                    "args": [None, {
                        "frame": {"duration": frame_duration, "redraw": True},
                        "fromcurrent": True,
                        "transition": {"duration": 100}
                    }]
                },
                {
                    "label": "Pause",
                    "method": "animate",
                    "args": [[None], {
                        "frame": {"duration": 0, "redraw": True},
                        "mode": "immediate",
                        "transition": {"duration": 0}
                    }]
                }
            ]
        }],
        sliders=[{
            "active": 0,
            "yanchor": "top",
            "xanchor": "left",
            "currentvalue": {
                "font": {"size": 20},
                "prefix": "Day: ",
                "visible": True,
                "xanchor": "right"
            },
            "transition": {"duration": 100},
            "pad": {"b": 10, "t": 50},
            "len": 0.9,
            "x": 0.1,
            "y": 0,
            "steps": [
                {
                    "args": [[frame.name], {
                        "frame": {"duration": frame_duration, "redraw": True},
                        "mode": "immediate",
                        "transition": {"duration": 100}
                    }],
                    "label": f"{time_days[i]:.1f}",
                    "method": "animate"
                }
                for i, frame in enumerate(frames)
            ]
        }]
    )
    
    return fig