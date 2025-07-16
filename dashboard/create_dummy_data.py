#!/usr/bin/env python3
"""
Create dummy MRST simulation data for testing the dashboard.
This generates realistic-looking data following the MRST data structure.
"""

import numpy as np
import scipy.io as sio
from pathlib import Path
import warnings

def create_dummy_data():
    """Create dummy MRST simulation data for dashboard testing."""
    
    # Grid parameters
    nx, ny = 20, 20
    n_timesteps = 25
    n_wells = 2
    
    # Time vector
    time_days = np.linspace(0, 365, n_timesteps)
    
    # ----------------------------------------
    # 1. Initial conditions
    # ----------------------------------------
    print("Creating initial conditions...")
    
    # Create realistic pressure field (higher in center, lower at edges)
    x = np.linspace(0, 1, nx)
    y = np.linspace(0, 1, ny)
    X, Y = np.meshgrid(x, y)
    
    # Pressure: higher in center, some noise
    pressure_base = 3000 + 500 * np.exp(-((X-0.5)**2 + (Y-0.5)**2) / 0.1)
    pressure = pressure_base + np.random.normal(0, 50, (ny, nx))
    
    # Water saturation: lower in center (more oil), higher at edges
    sw_base = 0.2 + 0.3 * (1 - np.exp(-((X-0.5)**2 + (Y-0.5)**2) / 0.1))
    sw = sw_base + np.random.normal(0, 0.02, (ny, nx))
    sw = np.clip(sw, 0.1, 0.8)
    
    # Porosity: correlated with saturation
    phi = 0.15 + 0.15 * np.random.random((ny, nx))
    phi = np.clip(phi, 0.05, 0.35)
    
    # Permeability: log-normal distribution, correlated with porosity
    k = 100 * np.exp(2 * (phi - 0.2) + np.random.normal(0, 0.5, (ny, nx)))
    k = np.clip(k, 1, 1000)
    
    # Save initial conditions
    initial_data = {
        'pressure': pressure,
        'sw': sw,
        'phi': phi,
        'k': k
    }
    sio.savemat('../data/initial/initial_conditions.mat', initial_data)
    
    # ----------------------------------------
    # 2. Static data
    # ----------------------------------------
    print("Creating static data...")
    
    # Rock regions (3 types)
    rock_id = np.ones((ny, nx), dtype=int)
    rock_id[Y < 0.3] = 2  # Bottom layer
    rock_id[Y > 0.7] = 3  # Top layer
    rock_id += np.random.randint(0, 2, (ny, nx)) * 0  # Add some noise
    
    # Grid coordinates
    grid_x = np.linspace(0, 20*164.0, nx+1)  # 164 ft cell size
    grid_y = np.linspace(0, 20*164.0, ny+1)
    cell_centers_x = (grid_x[:-1] + grid_x[1:]) / 2
    cell_centers_y = (grid_y[:-1] + grid_y[1:]) / 2
    
    # Wells
    wells = {
        'names': ['PROD1', 'INJ1'],
        'x_coords': [cell_centers_x[5], cell_centers_x[15]],
        'y_coords': [cell_centers_y[5], cell_centers_y[15]],
        'types': ['producer', 'injector']
    }
    
    static_data = {
        'rock_id': rock_id,
        'grid_x': grid_x,
        'grid_y': grid_y,
        'cell_centers_x': cell_centers_x,
        'cell_centers_y': cell_centers_y,
        'wells': wells
    }
    sio.savemat('../data/static/static_data.mat', static_data)
    
    # ----------------------------------------
    # 3. Dynamic fields
    # ----------------------------------------
    print("Creating dynamic fields...")
    
    # Initialize 3D arrays
    pressure_3d = np.zeros((n_timesteps, ny, nx))
    sw_3d = np.zeros((n_timesteps, ny, nx))
    phi_3d = np.zeros((n_timesteps, ny, nx))
    k_3d = np.zeros((n_timesteps, ny, nx))
    
    # Simulate evolution
    for t in range(n_timesteps):
        # Pressure decline over time
        pressure_3d[t] = pressure * (1 - 0.3 * t / n_timesteps)
        
        # Water saturation increase (waterflooding)
        sw_increase = 0.4 * (t / n_timesteps) * np.exp(-((X-0.2)**2 + (Y-0.2)**2) / 0.2)
        sw_3d[t] = sw + sw_increase
        sw_3d[t] = np.clip(sw_3d[t], 0.1, 0.9)
        
        # Porosity and permeability changes due to compaction
        phi_3d[t] = phi * (1 - 0.05 * t / n_timesteps)
        k_3d[t] = k * (phi_3d[t] / phi) ** 3  # Kozeny-Carman
    
    field_arrays = {
        'pressure': pressure_3d,
        'sw': sw_3d,
        'phi': phi_3d,
        'k': k_3d
    }
    sio.savemat('../data/dynamic/fields/field_arrays.mat', field_arrays)
    
    # ----------------------------------------
    # 4. Flow data
    # ----------------------------------------
    print("Creating flow data...")
    
    # Velocity fields
    vx = np.zeros((n_timesteps, ny, nx))
    vy = np.zeros((n_timesteps, ny, nx))
    
    for t in range(n_timesteps):
        # Simple flow from injector to producer
        vx[t] = 0.1 * (X - 0.8) * np.exp(-t / 10)
        vy[t] = 0.1 * (Y - 0.8) * np.exp(-t / 10)
    
    velocity_magnitude = np.sqrt(vx**2 + vy**2)
    
    flow_data = {
        'time_days': time_days,
        'vx': vx,
        'vy': vy,
        'velocity_magnitude': velocity_magnitude
    }
    sio.savemat('../data/dynamic/fields/flow_data.mat', flow_data)
    
    # ----------------------------------------
    # 5. Well data
    # ----------------------------------------
    print("Creating well data...")
    
    # Production rates
    qOs = np.zeros((n_timesteps, n_wells))
    qWs = np.zeros((n_timesteps, n_wells))
    bhp = np.zeros((n_timesteps, n_wells))
    
    for t in range(n_timesteps):
        # Producer (well 0): declining oil, increasing water
        qOs[t, 0] = 100 * np.exp(-t / 15) + np.random.normal(0, 5)
        qWs[t, 0] = 20 * (1 - np.exp(-t / 10)) + np.random.normal(0, 2)
        bhp[t, 0] = 2000 + 500 * np.exp(-t / 20) + np.random.normal(0, 20)
        
        # Injector (well 1): water injection
        qOs[t, 1] = 0
        qWs[t, 1] = 150 + np.random.normal(0, 10)
        bhp[t, 1] = 3500 + np.random.normal(0, 50)
    
    well_data = {
        'time_days': time_days,
        'well_names': ['PROD1', 'INJ1'],
        'qOs': qOs,
        'qWs': qWs,
        'bhp': bhp
    }
    sio.savemat('../data/dynamic/wells/well_data.mat', well_data)
    
    # ----------------------------------------
    # 6. Cumulative data
    # ----------------------------------------
    print("Creating cumulative data...")
    
    # Calculate cumulative production
    dt = np.diff(time_days)
    dt = np.concatenate([[dt[0]], dt])  # Add first timestep
    
    cum_oil_prod = np.zeros((n_timesteps, n_wells))
    cum_water_prod = np.zeros((n_timesteps, n_wells))
    cum_water_inj = np.zeros((n_timesteps, n_wells))
    
    for t in range(1, n_timesteps):
        cum_oil_prod[t] = cum_oil_prod[t-1] + qOs[t] * dt[t]
        cum_water_prod[t] = cum_water_prod[t-1] + qWs[t] * dt[t]
        cum_water_inj[t] = cum_water_inj[t-1] + qWs[t] * dt[t]
    
    # Recovery factor (simplified)
    ooip = 1e6  # Original oil in place
    recovery_factor = np.sum(cum_oil_prod, axis=1) / ooip
    
    cumulative_data = {
        'time_days': time_days,
        'well_names': ['PROD1', 'INJ1'],
        'cum_oil_prod': cum_oil_prod,
        'cum_water_prod': cum_water_prod,
        'cum_water_inj': cum_water_inj,
        'recovery_factor': recovery_factor
    }
    sio.savemat('../data/dynamic/wells/cumulative_data.mat', cumulative_data)
    
    # ----------------------------------------
    # 7. Metadata
    # ----------------------------------------
    print("Creating metadata...")
    
    metadata = {
        'dataset_info': {
            'name': 'MRST Dummy Simulation',
            'description': 'Test data for dashboard visualization',
            'creation_date': '2025-07-16',
            'version': '1.0'
        },
        'simulation': {
            'total_time': float(time_days[-1]),
            'timesteps': n_timesteps,
            'wells': n_wells,
            'grid_dimensions': [nx, ny]
        },
        'units': {
            'pressure': 'psi',
            'time': 'days',
            'rates': 'm3/day',
            'distance': 'ft'
        }
    }
    sio.savemat('../data/metadata/metadata.mat', metadata)
    
    print("✅ Dummy data created successfully!")
    print(f"Data available at: ../data/")
    print(f"Time range: {time_days[0]:.1f} to {time_days[-1]:.1f} days")
    print(f"Grid size: {nx}x{ny}")
    print(f"Number of wells: {n_wells}")
    print(f"Number of timesteps: {n_timesteps}")

if __name__ == "__main__":
    create_dummy_data()