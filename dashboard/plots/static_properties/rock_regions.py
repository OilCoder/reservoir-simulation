"""
Rock Regions Map Visualization

Creates 2D map of rock region identifiers with categorical coloring.
Data: static/static_data.mat - rock_id [20×20] dimensionless
"""

import numpy as np
import plotly.graph_objects as go
import plotly.express as px
from typing import Optional, Dict, Any, List
import sys
from pathlib import Path
sys.path.append(str(Path(__file__).parent.parent))
from plot_utils import format_grid_plot

def create_rock_regions_map(
    rock_id_data: np.ndarray,
    grid_x: Optional[np.ndarray] = None,
    grid_y: Optional[np.ndarray] = None,
    title: str = "Rock Region Map",
    rock_labels: Optional[Dict[int, str]] = None,
    wells_data: Optional[Dict] = None
) -> go.Figure:
    """
    Create 2D rock regions map with categorical coloring.
    
    Args:
        rock_id_data: Rock ID field [20×20] dimensionless
        grid_x: Grid x-coordinates [21×1] in meters (optional)
        grid_y: Grid y-coordinates [21×1] in meters (optional)
        title: Plot title
        rock_labels: Dictionary mapping rock IDs to names
        
    Returns:
        plotly.graph_objects.Figure: Interactive rock regions map
    """
    # Validate input data
    if rock_id_data is None:
        raise ValueError("Rock ID data cannot be None")
    
    if rock_id_data.shape != (20, 20):
        raise ValueError(f"Expected rock ID shape (20, 20), got {rock_id_data.shape}")
    
    # Create coordinate grids if not provided
    if grid_x is None:
        grid_x = np.linspace(0, 20*164.0, 21)  # 164 ft cell size
    if grid_y is None:
        grid_y = np.linspace(0, 20*164.0, 21)
    
    # Get unique rock IDs
    unique_rocks = np.unique(rock_id_data)
    
    # Create default rock labels if not provided
    if rock_labels is None:
        rock_labels = {int(rock_id): f"Rock Type {int(rock_id)}" for rock_id in unique_rocks}
    
    # Create discrete colorscale
    colors = px.colors.qualitative.Set3[:len(unique_rocks)]
    
    # Create heatmap with discrete colors
    fig = go.Figure(data=go.Heatmap(
        z=rock_id_data,
        x=grid_x[:-1],  # Cell centers
        y=grid_y[:-1],
        colorscale=[[i/(len(unique_rocks)-1), colors[i]] for i in range(len(unique_rocks))],
        zmin=np.min(unique_rocks),
        zmax=np.max(unique_rocks),
        colorbar=dict(
            title="Rock Type",
            
            tickmode="array",
            tickvals=list(unique_rocks),
            ticktext=[rock_labels.get(int(rock_id), f"Rock {int(rock_id)}") for rock_id in unique_rocks]
        ),
        hovertemplate="<b>Position</b><br>" +
                      "X: %{x:.1f} ft<br>" +
                      "Y: %{y:.1f} ft<br>" +
                      "<b>Rock Type: %{customdata}</b><br>" +
                      "<extra></extra>",
        customdata=[[rock_labels.get(int(rock_id_data[i, j]), f"Rock {int(rock_id_data[i, j])}") 
                     for j in range(rock_id_data.shape[1])] 
                    for i in range(rock_id_data.shape[0])]
    ))
    
    # Format plot with wells and square aspect ratio
    format_grid_plot(fig, title, "Rock Type", wells_data, grid_x, grid_y)
    
    return fig

def create_rock_regions_statistics(rock_id_data: np.ndarray) -> Dict[str, Any]:
    """
    Calculate rock regions statistics.
    
    Args:
        rock_id_data: Rock ID field [20×20] dimensionless
        
    Returns:
        dict: Statistical summary
    """
    if rock_id_data is None:
        return {}
    
    unique_rocks, counts = np.unique(rock_id_data, return_counts=True)
    total_cells = rock_id_data.size
    
    return {
        'unique_rock_types': len(unique_rocks),
        'rock_ids': unique_rocks.tolist(),
        'rock_counts': counts.tolist(),
        'rock_fractions': (counts / total_cells).tolist(),
        'most_common_rock': int(unique_rocks[np.argmax(counts)]),
        'most_common_fraction': float(np.max(counts) / total_cells)
    }