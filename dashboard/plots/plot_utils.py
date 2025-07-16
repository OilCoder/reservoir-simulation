"""
Utility functions for plot formatting and well locations.
"""

import numpy as np
import plotly.graph_objects as go
from typing import Optional, Dict, Any

def add_wells_to_plot(fig: go.Figure, wells_data: Optional[Dict] = None, 
                     grid_x: Optional[np.ndarray] = None, grid_y: Optional[np.ndarray] = None):
    """
    Add well locations to a plot.
    
    Args:
        fig: Plotly figure to add wells to
        wells_data: Dictionary with well information
        grid_x: Grid x-coordinates
        grid_y: Grid y-coordinates
    """
    if wells_data is None:
        # Default well locations for dummy data
        wells_data = {
            'names': ['PROD1', 'INJ1'],
            'x_coords': [5*164.0, 15*164.0],  # Approximate positions
            'y_coords': [5*164.0, 15*164.0],
            'types': ['producer', 'injector']
        }
    
    if 'names' not in wells_data:
        return
    
    # Add producer wells
    prod_x = []
    prod_y = []
    prod_names = []
    
    # Add injector wells
    inj_x = []
    inj_y = []
    inj_names = []
    
    for i, (name, well_type) in enumerate(zip(wells_data['names'], wells_data['types'])):
        x_coord = wells_data['x_coords'][i]
        y_coord = wells_data['y_coords'][i]
        
        if well_type == 'producer':
            prod_x.append(x_coord)
            prod_y.append(y_coord)
            prod_names.append(name)
        else:
            inj_x.append(x_coord)
            inj_y.append(y_coord)
            inj_names.append(name)
    
    # Add producer wells
    if prod_x:
        fig.add_trace(go.Scatter(
            x=prod_x,
            y=prod_y,
            mode='markers',
            marker=dict(
                size=12,
                color='red',
                symbol='circle',
                line=dict(width=2, color='darkred')
            ),
            name='Productores',
            text=prod_names,
            hovertemplate="<b>%{text}</b><br>" +
                          "Tipo: Productor<br>" +
                          "X: %{x:.1f} ft<br>" +
                          "Y: %{y:.1f} ft<br>" +
                          "<extra></extra>"
        ))
    
    # Add injector wells
    if inj_x:
        fig.add_trace(go.Scatter(
            x=inj_x,
            y=inj_y,
            mode='markers',
            marker=dict(
                size=12,
                color='blue',
                symbol='triangle-up',
                line=dict(width=2, color='darkblue')
            ),
            name='Inyectores',
            text=inj_names,
            hovertemplate="<b>%{text}</b><br>" +
                          "Tipo: Inyector<br>" +
                          "X: %{x:.1f} ft<br>" +
                          "Y: %{y:.1f} ft<br>" +
                          "<extra></extra>"
        ))

def set_square_aspect_ratio(fig: go.Figure, grid_x: Optional[np.ndarray] = None, 
                           grid_y: Optional[np.ndarray] = None):
    """
    Set square aspect ratio for grid plots.
    
    Args:
        fig: Plotly figure to modify
        grid_x: Grid x-coordinates
        grid_y: Grid y-coordinates
    """
    if grid_x is None:
        grid_x = np.linspace(0, 20*164.0, 21)
    if grid_y is None:
        grid_y = np.linspace(0, 20*164.0, 21)
    
    # Calculate ranges
    x_range = [grid_x[0], grid_x[-1]]
    y_range = [grid_y[0], grid_y[-1]]
    
    # Update layout for square aspect ratio
    fig.update_layout(
        xaxis=dict(
            range=x_range,
            scaleanchor="y",
            scaleratio=1,
            constraintoward="center"
        ),
        yaxis=dict(
            range=y_range,
            scaleanchor="x",
            scaleratio=1,
            constraintoward="center"
        ),
        width=600,
        height=600,  # Square dimensions
        margin=dict(l=50, r=50, t=70, b=50)
    )

def format_grid_plot(fig: go.Figure, title: str, colorbar_title: str,
                    wells_data: Optional[Dict] = None,
                    grid_x: Optional[np.ndarray] = None, 
                    grid_y: Optional[np.ndarray] = None):
    """
    Apply standard formatting to grid plots.
    
    Args:
        fig: Plotly figure to format
        title: Plot title
        colorbar_title: Title for colorbar
        wells_data: Well information
        grid_x: Grid x-coordinates
        grid_y: Grid y-coordinates
    """
    # Set square aspect ratio
    set_square_aspect_ratio(fig, grid_x, grid_y)
    
    # Add wells
    add_wells_to_plot(fig, wells_data, grid_x, grid_y)
    
    # Update layout
    fig.update_layout(
        title=dict(
            text=title,
            x=0.5,
            font=dict(size=16)
        ),
        xaxis=dict(
            title="Distancia X (ft)",
            showgrid=True,
            gridcolor="lightgray",
            gridwidth=1
        ),
        yaxis=dict(
            title="Distancia Y (ft)",
            showgrid=True,
            gridcolor="lightgray",
            gridwidth=1
        ),
        plot_bgcolor="white",
        showlegend=True,
        legend=dict(
            yanchor="top",
            y=0.99,
            xanchor="left",
            x=1.02
        )
    )
    
    return fig