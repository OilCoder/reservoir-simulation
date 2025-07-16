"""
Dynamic Field Snapshots

Creates 2D maps of field variables at specific time steps.
Data: dynamic/fields/field_arrays.mat - pressure[t,:,:], sw[t,:,:]
"""

import numpy as np
import plotly.graph_objects as go
from typing import Optional, Dict, Any, List
import sys
from pathlib import Path
sys.path.append(str(Path(__file__).parent.parent))
from plot_utils import format_grid_plot

def create_pressure_snapshot(
    pressure_data: np.ndarray,
    timestep: int,
    time_days: Optional[np.ndarray] = None,
    grid_x: Optional[np.ndarray] = None,
    grid_y: Optional[np.ndarray] = None,
    title: Optional[str] = None,
    colorscale: str = "viridis",
    wells_data: Optional[Dict] = None
) -> go.Figure:
    """
    Create 2D pressure map at specific timestep.
    
    Args:
        pressure_data: Pressure field [n_timesteps, 20, 20] in psi
        timestep: Time step index to visualize
        time_days: Time vector [n_timesteps] in days (optional)
        grid_x: Grid x-coordinates [21×1] in meters (optional)
        grid_y: Grid y-coordinates [21×1] in meters (optional)
        title: Plot title (optional)
        colorscale: Plotly colorscale name
        
    Returns:
        plotly.graph_objects.Figure: Interactive pressure snapshot
    """
    # Validate input data
    if pressure_data is None:
        raise ValueError("Pressure data cannot be None")
    
    if len(pressure_data.shape) != 3:
        raise ValueError(f"Expected 3D pressure data, got shape {pressure_data.shape}")
    
    if timestep < 0 or timestep >= pressure_data.shape[0]:
        raise ValueError(f"Timestep {timestep} out of range [0, {pressure_data.shape[0]-1}]")
    
    # Extract pressure at timestep
    pressure_snapshot = pressure_data[timestep, :, :]
    
    # Create coordinate grids if not provided
    if grid_x is None:
        grid_x = np.linspace(0, 20*164.0, 21)  # 164 ft cell size
    if grid_y is None:
        grid_y = np.linspace(0, 20*164.0, 21)
    
    # Create title if not provided
    if title is None:
        if time_days is not None:
            title = f"Pressure Distribution - Day {time_days[timestep]:.1f}"
        else:
            title = f"Pressure Distribution - Time Step {timestep}"
    
    # Create heatmap
    fig = go.Figure(data=go.Heatmap(
        z=pressure_snapshot,
        x=grid_x[:-1],  # Cell centers
        y=grid_y[:-1],
        colorscale=colorscale,
        colorbar=dict(
            title="Pressure (psi)"
        ),
        hovertemplate="<b>Position</b><br>" +
                      "X: %{x:.1f} ft<br>" +
                      "Y: %{y:.1f} ft<br>" +
                      "<b>Pressure: %{z:.1f} psi</b><br>" +
                      "<extra></extra>"
    ))
    
    # Format plot with wells and square aspect ratio
    format_grid_plot(fig, title, "Pressure (psi)", wells_data, grid_x, grid_y)
    
    return fig

def create_saturation_snapshot(
    saturation_data: np.ndarray,
    timestep: int,
    time_days: Optional[np.ndarray] = None,
    grid_x: Optional[np.ndarray] = None,
    grid_y: Optional[np.ndarray] = None,
    title: Optional[str] = None,
    colorscale: str = "blues",
    wells_data: Optional[Dict] = None
) -> go.Figure:
    """
    Create 2D saturation map at specific timestep.
    
    Args:
        saturation_data: Saturation field [n_timesteps, 20, 20] dimensionless
        timestep: Time step index to visualize
        time_days: Time vector [n_timesteps] in days (optional)
        grid_x: Grid x-coordinates [21×1] in meters (optional)
        grid_y: Grid y-coordinates [21×1] in meters (optional)
        title: Plot title (optional)
        colorscale: Plotly colorscale name
        
    Returns:
        plotly.graph_objects.Figure: Interactive saturation snapshot
    """
    # Validate input data
    if saturation_data is None:
        raise ValueError("Saturation data cannot be None")
    
    if len(saturation_data.shape) != 3:
        raise ValueError(f"Expected 3D saturation data, got shape {saturation_data.shape}")
    
    if timestep < 0 or timestep >= saturation_data.shape[0]:
        raise ValueError(f"Timestep {timestep} out of range [0, {saturation_data.shape[0]-1}]")
    
    # Extract saturation at timestep
    saturation_snapshot = saturation_data[timestep, :, :]
    
    # Create coordinate grids if not provided
    if grid_x is None:
        grid_x = np.linspace(0, 20*164.0, 21)  # 164 ft cell size
    if grid_y is None:
        grid_y = np.linspace(0, 20*164.0, 21)
    
    # Create title if not provided
    if title is None:
        if time_days is not None:
            title = f"Water Saturation Distribution - Day {time_days[timestep]:.1f}"
        else:
            title = f"Water Saturation Distribution - Time Step {timestep}"
    
    # Create heatmap
    fig = go.Figure(data=go.Heatmap(
        z=saturation_snapshot,
        x=grid_x[:-1],  # Cell centers
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
    
    # Format plot with wells and square aspect ratio
    format_grid_plot(fig, title, "Water Saturation", wells_data, grid_x, grid_y)
    
    return fig

def get_key_timesteps(
    time_days: np.ndarray,
    n_snapshots: int = 4
) -> List[int]:
    """
    Get key timestep indices for snapshot visualization.
    
    Args:
        time_days: Time vector [n_timesteps] in days
        n_snapshots: Number of snapshot timesteps to select
        
    Returns:
        list: List of timestep indices
    """
    if time_days is None or len(time_days) == 0:
        return [0]
    
    n_timesteps = len(time_days)
    
    if n_timesteps <= n_snapshots:
        return list(range(n_timesteps))
    
    # Include initial, final, and evenly spaced intermediate timesteps
    indices = [0]  # Initial
    
    if n_snapshots > 2:
        # Intermediate timesteps
        for i in range(1, n_snapshots - 1):
            idx = int(i * (n_timesteps - 1) / (n_snapshots - 1))
            indices.append(idx)
    
    indices.append(n_timesteps - 1)  # Final
    
    return sorted(list(set(indices)))

def create_snapshot_summary_stats(
    field_data: np.ndarray,
    timestep: int,
    field_name: str = "Field"
) -> Dict[str, Any]:
    """
    Calculate summary statistics for field snapshot.
    
    Args:
        field_data: Field data [n_timesteps, 20, 20]
        timestep: Time step index
        field_name: Name of the field
        
    Returns:
        dict: Statistical summary
    """
    if field_data is None:
        return {}
    
    snapshot = field_data[timestep, :, :]
    
    return {
        'timestep': timestep,
        'min_value': float(np.min(snapshot)),
        'max_value': float(np.max(snapshot)),
        'mean_value': float(np.mean(snapshot)),
        'std_value': float(np.std(snapshot)),
        'median_value': float(np.median(snapshot)),
        'field_name': field_name
    }