"""
Well Production Plots

Visualizes well production and injection performance.
Data sources: dynamic/wells/well_data.mat, dynamic/wells/cumulative_data.mat
"""

from .production_rates import create_oil_production_plot, create_water_injection_plot
from .cumulative_production import create_cumulative_production_plot, create_recovery_factor_plot
from .well_performance import create_water_cut_plot, create_well_comparison_plot

__all__ = [
    'create_oil_production_plot',
    'create_water_injection_plot',
    'create_cumulative_production_plot',
    'create_recovery_factor_plot',
    'create_water_cut_plot',
    'create_well_comparison_plot'
]