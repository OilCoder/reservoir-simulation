"""
Well Performance Analysis

Creates plots for water cut and well comparison analysis.
Data: dynamic/wells/cumulative_data.mat
"""

import numpy as np
import plotly.graph_objects as go
from typing import Optional, Dict, Any

def create_water_cut_plot(
    cumulative_data: Dict[str, Any],
    title: str = "Water Cut Evolution"
) -> go.Figure:
    """
    Create water cut evolution plot.
    
    Args:
        cumulative_data: Cumulative data dictionary
        title: Plot title
        
    Returns:
        plotly.graph_objects.Figure: Interactive water cut plot
    """
    time_days = cumulative_data['time_days']
    cum_oil = cumulative_data['cum_oil_prod']
    cum_water = cumulative_data['cum_water_prod']
    
    # Calculate water cut
    total_oil = np.sum(cum_oil, axis=1)
    total_water = np.sum(cum_water, axis=1)
    water_cut = total_water / (total_oil + total_water + 1e-10)  # Avoid division by zero
    
    fig = go.Figure(data=go.Scatter(
        x=time_days,
        y=water_cut * 100,  # Convert to percentage
        mode="lines+markers",
        name="Water Cut",
        line=dict(color="darkblue", width=2),
        marker=dict(size=4)
    ))
    
    fig.update_layout(
        title=dict(text=title, x=0.5, font=dict(size=16)),
        xaxis=dict(title="Time (days)", showgrid=True),
        yaxis=dict(title="Water Cut (%)", showgrid=True, range=[0, 100]),
        plot_bgcolor="white",
        width=700,
        height=400
    )
    
    return fig

def create_well_comparison_plot(
    well_data: Dict[str, Any],
    title: str = "Well Performance Comparison"
) -> go.Figure:
    """
    Create well performance comparison plot.
    
    Args:
        well_data: Well data dictionary
        title: Plot title
        
    Returns:
        plotly.graph_objects.Figure: Interactive well comparison plot
    """
    time_days = well_data['time_days']
    well_names = well_data['well_names']
    qOs = well_data['qOs']
    
    fig = go.Figure()
    
    for i, well_name in enumerate(well_names):
        if i < qOs.shape[1]:
            fig.add_trace(go.Scatter(
                x=time_days,
                y=qOs[:, i],
                mode="lines+markers",
                name=well_name,
                line=dict(width=2),
                marker=dict(size=4)
            ))
    
    fig.update_layout(
        title=dict(text=title, x=0.5, font=dict(size=16)),
        xaxis=dict(title="Time (days)", showgrid=True),
        yaxis=dict(title="Oil Rate (m³/day)", showgrid=True),
        plot_bgcolor="white",
        width=700,
        height=400
    )
    
    return fig