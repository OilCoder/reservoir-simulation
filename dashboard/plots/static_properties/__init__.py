"""
Static Properties Plots

Visualizes time-invariant reservoir properties.
Data sources: initial/initial_conditions.mat, static/static_data.mat
"""

from .porosity_map import create_porosity_map
from .permeability_map import create_permeability_map
from .rock_regions import create_rock_regions_map
from .property_histograms import create_porosity_histogram, create_permeability_boxplot

__all__ = [
    'create_porosity_map',
    'create_permeability_map', 
    'create_rock_regions_map',
    'create_porosity_histogram',
    'create_permeability_boxplot'
]