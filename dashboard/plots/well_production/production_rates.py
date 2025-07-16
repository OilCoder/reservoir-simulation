"""
Well Production Rates

Creates time series plots of oil production and water injection rates.
Data: dynamic/wells/well_data.mat - qOs, qWs vs time_days
"""

import numpy as np
import plotly.graph_objects as go
import plotly.express as px
from typing import Optional, Dict, Any, List

def create_oil_production_plot(
    well_data: Dict[str, Any],
    title: str = "Oil Production Rates",
    well_colors: Optional[Dict[str, str]] = None
) -> go.Figure:
    """
    Create time series plot of oil production rates by well.
    
    Args:
        well_data: Well data dictionary containing time_days, well_names, qOs
        title: Plot title
        well_colors: Dictionary mapping well names to colors
        
    Returns:
        plotly.graph_objects.Figure: Interactive production rates plot
    """
    # Validate input data
    if well_data is None:
        raise ValueError("Well data cannot be None")
    
    required_keys = ['time_days', 'well_names', 'qOs']
    for key in required_keys:
        if key not in well_data:
            raise ValueError(f"Missing required key: {key}")
    
    time_days = well_data['time_days']
    well_names = well_data['well_names']
    qOs = well_data['qOs']  # Oil rates [n_timesteps × n_wells]
    
    # Create figure
    fig = go.Figure()
    
    # Default colors if not provided
    if well_colors is None:
        colors = px.colors.qualitative.Set1
        well_colors = {well_names[i]: colors[i % len(colors)] for i in range(len(well_names))}
    
    # Add trace for each well
    for i, well_name in enumerate(well_names):
        if i < qOs.shape[1]:  # Check if well index exists
            # Filter out producer wells (positive rates)
            oil_rates = qOs[:, i]
            production_mask = oil_rates > 0
            
            if np.any(production_mask):
                fig.add_trace(go.Scatter(
                    x=time_days[production_mask],
                    y=oil_rates[production_mask],
                    mode="lines+markers",
                    name=well_name,
                    line=dict(
                        color=well_colors.get(well_name, "blue"),
                        width=2
                    ),
                    marker=dict(size=4),
                    hovertemplate=f"<b>{well_name}</b><br>" +
                                  "Time: %{x:.1f} days<br>" +
                                  "Oil Rate: %{y:.1f} m³/day<br>" +
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
            title="Oil Production Rate (m³/day)",
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

def create_water_injection_plot(
    well_data: Dict[str, Any],
    title: str = "Water Injection Rates",
    well_colors: Optional[Dict[str, str]] = None
) -> go.Figure:
    """
    Create time series plot of water injection rates by well.
    
    Args:
        well_data: Well data dictionary containing time_days, well_names, qWs
        title: Plot title
        well_colors: Dictionary mapping well names to colors
        
    Returns:
        plotly.graph_objects.Figure: Interactive injection rates plot
    """
    # Validate input data
    if well_data is None:
        raise ValueError("Well data cannot be None")
    
    required_keys = ['time_days', 'well_names', 'qWs']
    for key in required_keys:
        if key not in well_data:
            raise ValueError(f"Missing required key: {key}")
    
    time_days = well_data['time_days']
    well_names = well_data['well_names']
    qWs = well_data['qWs']  # Water rates [n_timesteps × n_wells]
    
    # Create figure
    fig = go.Figure()
    
    # Default colors if not provided
    if well_colors is None:
        colors = px.colors.qualitative.Set2
        well_colors = {well_names[i]: colors[i % len(colors)] for i in range(len(well_names))}
    
    # Add trace for each well
    for i, well_name in enumerate(well_names):
        if i < qWs.shape[1]:  # Check if well index exists
            # Filter out injector wells (positive rates)
            water_rates = qWs[:, i]
            injection_mask = water_rates > 0
            
            if np.any(injection_mask):
                fig.add_trace(go.Scatter(
                    x=time_days[injection_mask],
                    y=water_rates[injection_mask],
                    mode="lines+markers",
                    name=well_name,
                    line=dict(
                        color=well_colors.get(well_name, "darkblue"),
                        width=2
                    ),
                    marker=dict(size=4),
                    hovertemplate=f"<b>{well_name}</b><br>" +
                                  "Time: %{x:.1f} days<br>" +
                                  "Water Rate: %{y:.1f} m³/day<br>" +
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
            title="Water Injection Rate (m³/day)",
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

def create_combined_rates_plot(
    well_data: Dict[str, Any],
    title: str = "Combined Production and Injection Rates",
    production_wells: Optional[List[str]] = None,
    injection_wells: Optional[List[str]] = None
) -> go.Figure:
    """
    Create combined plot showing both production and injection rates.
    
    Args:
        well_data: Well data dictionary containing time_days, well_names, qOs, qWs
        title: Plot title
        production_wells: List of production well names
        injection_wells: List of injection well names
        
    Returns:
        plotly.graph_objects.Figure: Interactive combined rates plot
    """
    # Validate input data
    if well_data is None:
        raise ValueError("Well data cannot be None")
    
    required_keys = ['time_days', 'well_names', 'qOs', 'qWs']
    for key in required_keys:
        if key not in well_data:
            raise ValueError(f"Missing required key: {key}")
    
    time_days = well_data['time_days']
    well_names = well_data['well_names']
    qOs = well_data['qOs']
    qWs = well_data['qWs']
    
    # Create figure with secondary y-axis
    fig = go.Figure()
    
    # Auto-detect production and injection wells if not provided
    if production_wells is None:
        production_wells = []
        for i, well_name in enumerate(well_names):
            if i < qOs.shape[1] and np.any(qOs[:, i] > 0):
                production_wells.append(well_name)
    
    if injection_wells is None:
        injection_wells = []
        for i, well_name in enumerate(well_names):
            if i < qWs.shape[1] and np.any(qWs[:, i] > 0):
                injection_wells.append(well_name)
    
    # Add oil production traces
    for i, well_name in enumerate(well_names):
        if well_name in production_wells and i < qOs.shape[1]:
            oil_rates = qOs[:, i]
            production_mask = oil_rates > 0
            
            if np.any(production_mask):
                fig.add_trace(go.Scatter(
                    x=time_days[production_mask],
                    y=oil_rates[production_mask],
                    mode="lines+markers",
                    name=f"{well_name} (Oil)",
                    line=dict(color="red", width=2),
                    marker=dict(size=4),
                    yaxis="y1",
                    hovertemplate=f"<b>{well_name} Oil</b><br>" +
                                  "Time: %{x:.1f} days<br>" +
                                  "Rate: %{y:.1f} m³/day<br>" +
                                  "<extra></extra>"
                ))
    
    # Add water injection traces
    for i, well_name in enumerate(well_names):
        if well_name in injection_wells and i < qWs.shape[1]:
            water_rates = qWs[:, i]
            injection_mask = water_rates > 0
            
            if np.any(injection_mask):
                fig.add_trace(go.Scatter(
                    x=time_days[injection_mask],
                    y=water_rates[injection_mask],
                    mode="lines+markers",
                    name=f"{well_name} (Water)",
                    line=dict(color="blue", width=2, dash="dash"),
                    marker=dict(size=4),
                    yaxis="y2",
                    hovertemplate=f"<b>{well_name} Water</b><br>" +
                                  "Time: %{x:.1f} days<br>" +
                                  "Rate: %{y:.1f} m³/day<br>" +
                                  "<extra></extra>"
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
            title="Oil Production Rate (m³/day)",
            titlefont=dict(color="red"),
            tickfont=dict(color="red"),
            showgrid=True,
            gridcolor="lightcoral",
            gridwidth=1
        ),
        yaxis2=dict(
            title="Water Injection Rate (m³/day)",
            titlefont=dict(color="blue"),
            tickfont=dict(color="blue"),
            overlaying="y",
            side="right"
        ),
        plot_bgcolor="white",
        width=800,
        height=500,
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