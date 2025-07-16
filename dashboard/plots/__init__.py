"""
MRST Simulation Dashboard Plot Modules

Hierarchical organization of plotting functions for reservoir simulation visualization.
Each category corresponds to specific analysis requirements:

1. Initial Conditions (t=0) - Baseline reservoir state
2. Static Properties - Time-invariant grid and rock properties  
3. Dynamic Fields - Time-dependent field evolution
4. Well Production - Production and injection analysis
5. Flow & Velocity - Flow field visualization
6. Transect Profiles - Cross-sectional analysis
"""

from .initial_conditions import *
from .static_properties import *
from .dynamic_fields import *
from .well_production import *
from .flow_velocity import *
from .transect_profiles import *