"""
Pressure Transect Profiles

Creates cross-sectional pressure profiles through the reservoir.
Data: dynamic/fields/field_arrays.mat - pressure
"""

import numpy as np
import plotly.graph_objects as go
from typing import Optional, Dict, Any, List

def create_pressure_transect_plot(
    pressure_data: np.ndarray,
    time_days: np.ndarray,
    transect_type: str = "horizontal",
    transect_index: int = 10,
    title: Optional[str] = None,
    key_timesteps: Optional[List[int]] = None
) -> go.Figure:
    """
    Create pressure profile along a transect line.
    
    Args:
        pressure_data: Pressure field [n_timesteps, 20, 20] in psi
        time_days: Time vector [n_timesteps] in days
        transect_type: "horizontal" or "vertical"
        transect_index: Index of the transect line (0-19)
        title: Plot title
        key_timesteps: List of timestep indices to plot
        
    Returns:
        plotly.graph_objects.Figure: Interactive transect profile plot
    """
    # Validate inputs
    if pressure_data is None:
        raise ValueError("Pressure data cannot be None")
    
    if transect_index < 0 or transect_index >= 20:
        raise ValueError(f"Transect index must be between 0 and 19, got {transect_index}")
    
    # Select key timesteps if not provided
    if key_timesteps is None:
        n_timesteps = pressure_data.shape[0]
        key_timesteps = [0, n_timesteps//4, n_timesteps//2, 3*n_timesteps//4, n_timesteps-1]
        key_timesteps = [t for t in key_timesteps if t < n_timesteps]
    
    # Create distance vector
    distance = np.linspace(0, 20*164.0, 20)  # 164 ft cell size
    
    # Create title if not provided
    if title is None:
        direction = "Y" if transect_type == "horizontal" else "X"
        title = f"Pressure Profile - {direction} = {transect_index * 164.0:.0f} ft"
    
    # Create figure
    fig = go.Figure()
    
    # Add traces for key timesteps
    for timestep in key_timesteps:
        if timestep < len(time_days):
            # Extract pressure profile
            if transect_type == "horizontal":
                profile = pressure_data[timestep, transect_index, :]
                xlabel = "X Distance (ft)"
            else:  # vertical
                profile = pressure_data[timestep, :, transect_index]
                xlabel = "Y Distance (ft)"
            
            fig.add_trace(go.Scatter(
                x=distance,
                y=profile,
                mode="lines+markers",
                name=f"Day {time_days[timestep]:.1f}",
                line=dict(width=2),
                marker=dict(size=4),
                hovertemplate=f"<b>Day {time_days[timestep]:.1f}</b><br>" +
                              f"{xlabel.split()[0]}: %{{x:.1f}} ft<br>" +
                              "Pressure: %{y:.1f} psi<br>" +
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
            title=xlabel,
            showgrid=True,
            gridcolor="lightgray",
            gridwidth=1
        ),
        yaxis=dict(
            title="Pressure (psi)",
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