"""
Cumulative Production Plots

Creates plots for cumulative oil/water production and recovery factors.
Data: dynamic/wells/cumulative_data.mat
"""

import numpy as np
import plotly.graph_objects as go
import plotly.express as px
from typing import Optional, Dict, Any

def create_cumulative_production_plot(
    cumulative_data: Dict[str, Any],
    title: str = "Cumulative Production",
    show_water: bool = True
) -> go.Figure:
    """
    Create cumulative oil and water production plot.
    
    Args:
        cumulative_data: Cumulative data dictionary
        title: Plot title
        show_water: Whether to show water production
        
    Returns:
        plotly.graph_objects.Figure: Interactive cumulative production plot
    """
    time_days = cumulative_data['time_days']
    cum_oil = cumulative_data['cum_oil_prod']
    
    fig = go.Figure()
    
    # Add cumulative oil production
    fig.add_trace(go.Scatter(
        x=time_days,
        y=np.sum(cum_oil, axis=1),
        mode="lines+markers",
        name="Cumulative Oil",
        line=dict(color="red", width=2),
        marker=dict(size=4)
    ))
    
    if show_water and 'cum_water_prod' in cumulative_data:
        cum_water = cumulative_data['cum_water_prod']
        fig.add_trace(go.Scatter(
            x=time_days,
            y=np.sum(cum_water, axis=1),
            mode="lines+markers",
            name="Cumulative Water",
            line=dict(color="blue", width=2),
            marker=dict(size=4),
            yaxis="y2"
        ))
    
    # Update layout
    fig.update_layout(
        title=dict(text=title, x=0.5, font=dict(size=16)),
        xaxis=dict(title="Time (days)", showgrid=True),
        yaxis=dict(title="Cumulative Oil (m³)", showgrid=True),
        plot_bgcolor="white",
        width=700,
        height=400
    )
    
    if show_water:
        fig.update_layout(
            yaxis2=dict(
                title="Cumulative Water (m³)",
                overlaying="y",
                side="right"
            )
        )
    
    return fig

def create_recovery_factor_plot(
    cumulative_data: Dict[str, Any],
    title: str = "Recovery Factor Evolution"
) -> go.Figure:
    """
    Create recovery factor evolution plot.
    
    Args:
        cumulative_data: Cumulative data dictionary
        title: Plot title
        
    Returns:
        plotly.graph_objects.Figure: Interactive recovery factor plot
    """
    time_days = cumulative_data['time_days']
    recovery_factor = cumulative_data['recovery_factor']
    
    fig = go.Figure(data=go.Scatter(
        x=time_days,
        y=recovery_factor * 100,  # Convert to percentage
        mode="lines+markers",
        name="Recovery Factor",
        line=dict(color="green", width=2),
        marker=dict(size=4)
    ))
    
    fig.update_layout(
        title=dict(text=title, x=0.5, font=dict(size=16)),
        xaxis=dict(title="Time (days)", showgrid=True),
        yaxis=dict(title="Recovery Factor (%)", showgrid=True),
        plot_bgcolor="white",
        width=700,
        height=400
    )
    
    return fig