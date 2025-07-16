"""
Flow and Velocity Plots

Visualizes flow fields and velocity distributions.
Data source: dynamic/fields/flow_data.mat
"""

from .velocity_fields import create_velocity_field_plot, create_velocity_magnitude_plot
from .flow_evolution import create_velocity_evolution_plot

__all__ = [
    'create_velocity_field_plot',
    'create_velocity_magnitude_plot',
    'create_velocity_evolution_plot'
]