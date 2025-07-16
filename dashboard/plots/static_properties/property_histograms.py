"""
Property Histograms and Box Plots

Creates histograms and box plots for reservoir property distributions.
Data: initial/initial_conditions.mat, static/static_data.mat
"""

import numpy as np
import plotly.graph_objects as go
import plotly.express as px
from typing import Optional, Dict, Any

def create_porosity_histogram(
    porosity_data: np.ndarray,
    title: str = "Porosity Distribution",
    bins: int = 20,
    color: str = "skyblue"
) -> go.Figure:
    """
    Create histogram of porosity distribution.
    
    Args:
        porosity_data: Porosity field [20×20] dimensionless
        title: Plot title
        bins: Number of histogram bins
        color: Bar color
        
    Returns:
        plotly.graph_objects.Figure: Interactive histogram
    """
    # Validate input data
    if porosity_data is None:
        raise ValueError("Porosity data cannot be None")
    
    # Flatten the 2D array
    porosity_flat = porosity_data.flatten()
    
    # Create histogram
    fig = go.Figure(data=go.Histogram(
        x=porosity_flat,
        nbinsx=bins,
        marker_color=color,
        opacity=0.7,
        name="Porosity",
        hovertemplate="<b>Porosity Range</b><br>" +
                      "%{x:.3f}<br>" +
                      "<b>Count: %{y}</b><br>" +
                      "<extra></extra>"
    ))
    
    # Add mean line
    mean_porosity = np.mean(porosity_flat)
    fig.add_vline(
        x=mean_porosity,
        line_dash="dash",
        line_color="red",
        annotation_text=f"Mean: {mean_porosity:.3f}"
    )
    
    # Update layout
    fig.update_layout(
        title=dict(
            text=title,
            x=0.5,
            font=dict(size=16)
        ),
        xaxis=dict(
            title="Porosity",
            showgrid=True,
            gridcolor="lightgray",
            gridwidth=1
        ),
        yaxis=dict(
            title="Frequency",
            showgrid=True,
            gridcolor="lightgray",
            gridwidth=1
        ),
        plot_bgcolor="white",
        width=600,
        height=400,
        margin=dict(l=50, r=50, t=70, b=50)
    )
    
    return fig

def create_permeability_boxplot(
    permeability_data: np.ndarray,
    rock_id_data: np.ndarray,
    title: str = "Permeability Distribution by Rock Type",
    rock_labels: Optional[Dict[int, str]] = None
) -> go.Figure:
    """
    Create box plot of permeability distribution grouped by rock type.
    
    Args:
        permeability_data: Permeability field [20×20] in mD
        rock_id_data: Rock ID field [20×20] dimensionless
        title: Plot title
        rock_labels: Dictionary mapping rock IDs to names
        
    Returns:
        plotly.graph_objects.Figure: Interactive box plot
    """
    # Validate input data
    if permeability_data is None:
        raise ValueError("Permeability data cannot be None")
    if rock_id_data is None:
        raise ValueError("Rock ID data cannot be None")
    
    if permeability_data.shape != rock_id_data.shape:
        raise ValueError("Permeability and rock ID data must have same shape")
    
    # Flatten the 2D arrays
    perm_flat = permeability_data.flatten()
    rock_flat = rock_id_data.flatten()
    
    # Get unique rock types
    unique_rocks = np.unique(rock_flat)
    
    # Create default rock labels if not provided
    if rock_labels is None:
        rock_labels = {int(rock_id): f"Rock Type {int(rock_id)}" for rock_id in unique_rocks}
    
    # Create box plot
    fig = go.Figure()
    
    colors = px.colors.qualitative.Set3[:len(unique_rocks)]
    
    for i, rock_id in enumerate(unique_rocks):
        mask = rock_flat == rock_id
        rock_perms = perm_flat[mask]
        
        fig.add_trace(go.Box(
            y=rock_perms,
            name=rock_labels.get(int(rock_id), f"Rock {int(rock_id)}"),
            marker_color=colors[i],
            boxpoints="outliers",
            hovertemplate="<b>%{fullData.name}</b><br>" +
                          "Q1: %{q1:.1f} mD<br>" +
                          "Median: %{median:.1f} mD<br>" +
                          "Q3: %{q3:.1f} mD<br>" +
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
            title="Rock Type",
            showgrid=True,
            gridcolor="lightgray",
            gridwidth=1
        ),
        yaxis=dict(
            title="Permeability (mD)",
            showgrid=True,
            gridcolor="lightgray",
            gridwidth=1
        ),
        plot_bgcolor="white",
        width=600,
        height=400,
        margin=dict(l=50, r=50, t=70, b=50),
        showlegend=False
    )
    
    return fig

def create_property_correlation_plot(
    porosity_data: np.ndarray,
    permeability_data: np.ndarray,
    rock_id_data: Optional[np.ndarray] = None,
    title: str = "Porosity vs Permeability Correlation",
    rock_labels: Optional[Dict[int, str]] = None
) -> go.Figure:
    """
    Create scatter plot showing porosity-permeability correlation.
    
    Args:
        porosity_data: Porosity field [20×20] dimensionless
        permeability_data: Permeability field [20×20] in mD
        rock_id_data: Rock ID field [20×20] for coloring (optional)
        title: Plot title
        rock_labels: Dictionary mapping rock IDs to names
        
    Returns:
        plotly.graph_objects.Figure: Interactive scatter plot
    """
    # Validate input data
    if porosity_data is None or permeability_data is None:
        raise ValueError("Porosity and permeability data cannot be None")
    
    if porosity_data.shape != permeability_data.shape:
        raise ValueError("Porosity and permeability data must have same shape")
    
    # Flatten the arrays
    phi_flat = porosity_data.flatten()
    perm_flat = permeability_data.flatten()
    
    # Create scatter plot
    fig = go.Figure()
    
    if rock_id_data is not None:
        # Color by rock type
        rock_flat = rock_id_data.flatten()
        unique_rocks = np.unique(rock_flat)
        colors = px.colors.qualitative.Set3[:len(unique_rocks)]
        
        if rock_labels is None:
            rock_labels = {int(rock_id): f"Rock Type {int(rock_id)}" for rock_id in unique_rocks}
        
        for i, rock_id in enumerate(unique_rocks):
            mask = rock_flat == rock_id
            fig.add_trace(go.Scatter(
                x=phi_flat[mask],
                y=perm_flat[mask],
                mode="markers",
                name=rock_labels.get(int(rock_id), f"Rock {int(rock_id)}"),
                marker=dict(
                    color=colors[i],
                    size=6,
                    opacity=0.7
                ),
                hovertemplate="<b>%{fullData.name}</b><br>" +
                              "Porosity: %{x:.3f}<br>" +
                              "Permeability: %{y:.1f} mD<br>" +
                              "<extra></extra>"
            ))
    else:
        # Single color
        fig.add_trace(go.Scatter(
            x=phi_flat,
            y=perm_flat,
            mode="markers",
            name="Data Points",
            marker=dict(
                color="blue",
                size=6,
                opacity=0.7
            ),
            hovertemplate="Porosity: %{x:.3f}<br>" +
                          "Permeability: %{y:.1f} mD<br>" +
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
            title="Porosity",
            showgrid=True,
            gridcolor="lightgray",
            gridwidth=1
        ),
        yaxis=dict(
            title="Permeability (mD)",
            type="log",
            showgrid=True,
            gridcolor="lightgray",
            gridwidth=1
        ),
        plot_bgcolor="white",
        width=600,
        height=500,
        margin=dict(l=50, r=50, t=70, b=50)
    )
    
    return fig