"""
Flow Evolution Plots

Creates time series plots of flow field evolution.
Data: dynamic/fields/flow_data.mat
"""

import numpy as np
import plotly.graph_objects as go
from typing import Optional, Dict, Any

def create_velocity_evolution_plot(
    flow_data: Dict[str, Any],
    title: str = "Average Velocity Magnitude Evolution"
) -> go.Figure:
    """
    Create velocity magnitude evolution plot.
    
    Args:
        flow_data: Flow data dictionary
        title: Plot title
        
    Returns:
        plotly.graph_objects.Figure: Interactive velocity evolution plot
    """
    time_days = flow_data['time_days']
    velocity_magnitude = flow_data['velocity_magnitude']
    
    # Calculate spatial average
    avg_velocity = np.mean(velocity_magnitude, axis=(1, 2))
    
    fig = go.Figure(data=go.Scatter(
        x=time_days,
        y=avg_velocity,
        mode="lines+markers",
        name="Average Velocity",
        line=dict(color="purple", width=2),
        marker=dict(size=4)
    ))
    
    fig.update_layout(
        title=dict(text=title, x=0.5, font=dict(size=16)),
        xaxis=dict(title="Time (days)", showgrid=True),
        yaxis=dict(title="Average Velocity Magnitude", showgrid=True),
        plot_bgcolor="white",
        width=700,
        height=400
    )
    
    return fig