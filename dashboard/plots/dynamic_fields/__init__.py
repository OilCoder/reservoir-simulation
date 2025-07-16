"""
Dynamic Fields Plots

Visualizes time-dependent field evolution during simulation.
Data source: dynamic/fields/field_arrays.mat, dynamic/fields/flow_data.mat
"""

from .field_snapshots import create_pressure_snapshot, create_saturation_snapshot
from .field_evolution import create_average_pressure_evolution, create_average_saturation_evolution
from .field_animation import create_pressure_animation, create_saturation_animation

__all__ = [
    'create_pressure_snapshot',
    'create_saturation_snapshot',
    'create_average_pressure_evolution',
    'create_average_saturation_evolution',
    'create_pressure_animation',
    'create_saturation_animation'
]