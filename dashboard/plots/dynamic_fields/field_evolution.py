"""
Dynamic Field Evolution

Creates time series plots of spatially-averaged field variables.
Data: dynamic/fields/field_arrays.mat + dynamic/fields/flow_data.mat
"""

import numpy as np
import plotly.graph_objects as go
from typing import Optional, Dict, Any, List

def create_average_pressure_evolution(
    pressure_data: np.ndarray,
    time_days: np.ndarray,
    title: str = "Average Reservoir Pressure Evolution",
    line_color: str = "blue"
) -> go.Figure:
    """
    Create time series plot of spatially-averaged pressure.
    
    Args:
        pressure_data: Pressure field [n_timesteps, 20, 20] in psi
        time_days: Time vector [n_timesteps] in days
        title: Plot title
        line_color: Line color
        
    Returns:
        plotly.graph_objects.Figure: Interactive time series plot
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
    
    # Calculate spatial average at each timestep
    avg_pressure = np.mean(pressure_data, axis=(1, 2))
    
    # Create line plot
    fig = go.Figure(data=go.Scatter(
        x=time_days,
        y=avg_pressure,
        mode="lines+markers",
        name="Average Pressure",
        line=dict(color=line_color, width=2),
        marker=dict(size=4),
        hovertemplate="<b>Time: %{x:.1f} days</b><br>" +
                      "Average Pressure: %{y:.1f} psi<br>" +
                      "<extra></extra>"
    ))
    
    # Update layout
    fig.update_layout(
        title=dict(
            text=title,
            x=0.5,
            font=dict(size=16)
        ),
        xaxis=dict(
            title="Time (days)",
            showgrid=True,
            gridcolor="lightgray",
            gridwidth=1
        ),
        yaxis=dict(
            title="Average Pressure (psi)",
            showgrid=True,
            gridcolor="lightgray",
            gridwidth=1
        ),
        plot_bgcolor="white",
        width=700,
        height=400,
        margin=dict(l=50, r=50, t=70, b=50),
        showlegend=False
    )
    
    return fig

def create_average_saturation_evolution(
    saturation_data: np.ndarray,
    time_days: np.ndarray,
    title: str = "Average Water Saturation Evolution",
    line_color: str = "darkblue"
) -> go.Figure:
    """
    Create time series plot of spatially-averaged water saturation.
    
    Args:
        saturation_data: Saturation field [n_timesteps, 20, 20] dimensionless
        time_days: Time vector [n_timesteps] in days
        title: Plot title
        line_color: Line color
        
    Returns:
        plotly.graph_objects.Figure: Interactive time series plot
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
    
    # Calculate spatial average at each timestep
    avg_saturation = np.mean(saturation_data, axis=(1, 2))
    
    # Create line plot
    fig = go.Figure(data=go.Scatter(
        x=time_days,
        y=avg_saturation,
        mode="lines+markers",
        name="Average Water Saturation",
        line=dict(color=line_color, width=2),
        marker=dict(size=4),
        hovertemplate="<b>Time: %{x:.1f} days</b><br>" +
                      "Average Sw: %{y:.3f}<br>" +
                      "<extra></extra>"
    ))
    
    # Update layout
    fig.update_layout(
        title=dict(
            text=title,
            x=0.5,
            font=dict(size=16)
        ),
        xaxis=dict(
            title="Time (days)",
            showgrid=True,
            gridcolor="lightgray",
            gridwidth=1
        ),
        yaxis=dict(
            title="Average Water Saturation",
            showgrid=True,
            gridcolor="lightgray",
            gridwidth=1,
            range=[0, 1]
        ),
        plot_bgcolor="white",
        width=700,
        height=400,
        margin=dict(l=50, r=50, t=70, b=50),
        showlegend=False
    )
    
    return fig

def create_field_statistics_evolution(
    field_data: np.ndarray,
    time_days: np.ndarray,
    field_name: str = "Field",
    title: Optional[str] = None
) -> go.Figure:
    """
    Create time series plot of field statistics (min, max, mean, std).
    
    Args:
        field_data: Field data [n_timesteps, 20, 20]
        time_days: Time vector [n_timesteps] in days
        field_name: Name of the field
        title: Plot title (optional)
        
    Returns:
        plotly.graph_objects.Figure: Interactive statistics plot
    """
    # Validate input data
    if field_data is None:
        raise ValueError("Field data cannot be None")
    if time_days is None:
        raise ValueError("Time data cannot be None")
    
    if len(field_data.shape) != 3:
        raise ValueError(f"Expected 3D field data, got shape {field_data.shape}")
    
    if len(time_days) != field_data.shape[0]:
        raise ValueError(f"Time vector length {len(time_days)} doesn't match field timesteps {field_data.shape[0]}")
    
    # Calculate statistics at each timestep
    min_values = np.min(field_data, axis=(1, 2))
    max_values = np.max(field_data, axis=(1, 2))
    mean_values = np.mean(field_data, axis=(1, 2))
    std_values = np.std(field_data, axis=(1, 2))
    
    # Create title if not provided
    if title is None:
        title = f"{field_name} Statistics Evolution"
    
    # Create figure with secondary y-axis for standard deviation
    fig = go.Figure()
    
    # Add mean line
    fig.add_trace(go.Scatter(
        x=time_days,
        y=mean_values,
        mode="lines",
        name="Mean",
        line=dict(color="blue", width=2),
        hovertemplate="<b>Time: %{x:.1f} days</b><br>" +
                      "Mean: %{y:.3f}<br>" +
                      "<extra></extra>"
    ))
    
    # Add min/max range
    fig.add_trace(go.Scatter(
        x=time_days,
        y=max_values,
        mode="lines",
        name="Max",
        line=dict(color="red", width=1, dash="dash"),
        hovertemplate="<b>Time: %{x:.1f} days</b><br>" +
                      "Max: %{y:.3f}<br>" +
                      "<extra></extra>"
    ))
    
    fig.add_trace(go.Scatter(
        x=time_days,
        y=min_values,
        mode="lines",
        name="Min",
        line=dict(color="green", width=1, dash="dash"),
        fill="tonexty",
        fillcolor="rgba(0,0,255,0.1)",
        hovertemplate="<b>Time: %{x:.1f} days</b><br>" +
                      "Min: %{y:.3f}<br>" +
                      "<extra></extra>"
    ))
    
    # Update layout
    fig.update_layout(
        title=dict(
            text=title,
            x=0.5,
            font=dict(size=16)
        ),
        xaxis=dict(
            title="Time (days)",
            showgrid=True,
            gridcolor="lightgray",
            gridwidth=1
        ),
        yaxis=dict(
            title=f"{field_name} Value",
            showgrid=True,
            gridcolor="lightgray",
            gridwidth=1
        ),
        plot_bgcolor="white",
        width=700,
        height=400,
        margin=dict(l=50, r=50, t=70, b=50),
        legend=dict(
            orientation="h",
            yanchor="bottom",
            y=1.02,
            xanchor="right",
            x=1
        )
    )
    
    return fig

def create_dual_field_evolution(
    field1_data: np.ndarray,
    field2_data: np.ndarray,
    time_days: np.ndarray,
    field1_name: str = "Field 1",
    field2_name: str = "Field 2",
    title: str = "Dual Field Evolution"
) -> go.Figure:
    """
    Create time series plot comparing two fields on different y-axes.
    
    Args:
        field1_data: First field data [n_timesteps, 20, 20]
        field2_data: Second field data [n_timesteps, 20, 20]
        time_days: Time vector [n_timesteps] in days
        field1_name: Name of first field
        field2_name: Name of second field
        title: Plot title
        
    Returns:
        plotly.graph_objects.Figure: Interactive dual-axis plot
    """
    # Calculate spatial averages
    avg_field1 = np.mean(field1_data, axis=(1, 2))
    avg_field2 = np.mean(field2_data, axis=(1, 2))
    
    # Create figure with secondary y-axis
    fig = go.Figure()
    
    # Add first field
    fig.add_trace(go.Scatter(
        x=time_days,
        y=avg_field1,
        mode="lines+markers",
        name=field1_name,
        line=dict(color="blue", width=2),
        marker=dict(size=4),
        yaxis="y"
    ))
    
    # Add second field
    fig.add_trace(go.Scatter(
        x=time_days,
        y=avg_field2,
        mode="lines+markers",
        name=field2_name,
        line=dict(color="red", width=2),
        marker=dict(size=4),
        yaxis="y2"
    ))
    
    # Update layout with dual y-axes
    fig.update_layout(
        title=dict(
            text=title,
            x=0.5,
            font=dict(size=16)
        ),
        xaxis=dict(
            title="Time (days)",
            showgrid=True,
            gridcolor="lightgray",
            gridwidth=1
        ),
        yaxis=dict(
            title=field1_name,
            titlefont=dict(color="blue"),
            tickfont=dict(color="blue"),
            showgrid=True,
            gridcolor="lightblue",
            gridwidth=1
        ),
        yaxis2=dict(
            title=field2_name,
            titlefont=dict(color="red"),
            tickfont=dict(color="red"),
            overlaying="y",
            side="right"
        ),
        plot_bgcolor="white",
        width=700,
        height=400,
        margin=dict(l=50, r=50, t=70, b=50),
        legend=dict(
            orientation="h",
            yanchor="bottom",
            y=1.02,
            xanchor="right",
            x=1
        )
    )
    
    return fig