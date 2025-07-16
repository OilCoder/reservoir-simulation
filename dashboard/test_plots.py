#!/usr/bin/env python3
"""Test script for hierarchical plot modules."""

import numpy as np
import sys
from pathlib import Path

# Add dashboard to path
sys.path.append(str(Path(__file__).parent))

def test_plot_modules():
    """Test all plot modules."""
    print("Testing hierarchical plot modules...")
    
    # Test initial conditions plots
    try:
        from plots.plot_01_initial_conditions import create_initial_pressure_map
        test_data = np.random.rand(20, 20) * 1000 + 2000
        fig = create_initial_pressure_map(test_data)
        print("✅ Initial conditions plots: SUCCESS")
    except Exception as e:
        print(f"❌ Initial conditions plots: {e}")
    
    # Test static properties plots
    try:
        from plots.plot_02_static_properties import create_porosity_map
        test_porosity = np.random.rand(20, 20) * 0.3 + 0.1
        fig = create_porosity_map(test_porosity)
        print("✅ Static properties plots: SUCCESS")
    except Exception as e:
        print(f"❌ Static properties plots: {e}")
    
    # Test dynamic fields plots
    try:
        from plots.plot_03_dynamic_fields import create_pressure_snapshot
        test_3d_data = np.random.rand(10, 20, 20) * 1000 + 2000
        test_time = np.linspace(0, 365, 10)
        fig = create_pressure_snapshot(test_3d_data, 0, time_days=test_time)
        print("✅ Dynamic fields plots: SUCCESS")
    except Exception as e:
        print(f"❌ Dynamic fields plots: {e}")
    
    print("Plot modules testing complete!")

if __name__ == "__main__":
    test_plot_modules()