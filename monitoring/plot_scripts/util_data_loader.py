#!/usr/bin/env python3
"""
MRST Data Loader - Optimized Structure with oct2py

This module provides functions to load data from the optimized MRST export structure
using oct2py for proper .mat file reading.

Data Structure:
/workspace/data/
├── initial/
│   └── initial_conditions.mat
├── static/
│   ├── static_data.mat
│   └── fluid_properties.mat
├── temporal/
│   ├── time_data.mat
│   └── schedule_data.mat
├── dynamic/
│   ├── fields/
│   │   ├── field_arrays.mat
│   │   └── flow_data.mat
│   └── wells/
│       ├── well_data.mat
│       └── cumulative_data.mat
├── sensitivity/
│   └── sensitivity_data.mat
└── metadata/
    └── metadata.mat
"""

import numpy as np
import matplotlib.pyplot as plt
from pathlib import Path
import os

# Check if oct2py is available
try:
    import oct2py
    OCT2PY_AVAILABLE = True
except ImportError:
    OCT2PY_AVAILABLE = False
    print("[WARN] oct2py not available. Some functions may not work.")


def check_data_availability():
    """Check availability of all data files in the optimized structure.
    
    Returns:
        dict: Dictionary with availability status for each data category
    """
    base_path = Path('/workspace/data')
    
    availability = {
        'initial_conditions': False,
        'static_data': False,
        'fluid_properties': False,
        'temporal_data': False,
        'schedule_data': False,
        'field_arrays': False,
        'well_data': False,
        'cumulative_data': False,
        'flow_data': False,
        'sensitivity_data': False,
        'metadata': False
    }
    
    # Check each file
    files_to_check = {
        'initial_conditions': base_path / 'initial/initial_conditions.mat',
        'static_data': base_path / 'static/static_data.mat',
        'fluid_properties': base_path / 'static/fluid_properties.mat',
        'temporal_data': base_path / 'temporal/time_data.mat',
        'schedule_data': base_path / 'temporal/schedule_data.mat',
        'field_arrays': base_path / 'dynamic/fields/field_arrays.mat',
        'well_data': base_path / 'dynamic/wells/well_data.mat',
        'cumulative_data': base_path / 'dynamic/wells/cumulative_data.mat',
        'flow_data': base_path / 'dynamic/fields/flow_data.mat',
        'sensitivity_data': base_path / 'sensitivity/sensitivity_data.mat',
        'metadata': base_path / 'metadata/metadata.mat'
    }
    
    for key, file_path in files_to_check.items():
        availability[key] = file_path.exists()
    
    return availability


def print_data_summary():
    """Print a summary of data availability."""
    availability = check_data_availability()
    
    print("\n📊 Data Availability Summary:")
    print("=" * 50)
    
    # Essential data
    essential_files = ['initial_conditions', 'static_data', 'temporal_data', 'field_arrays', 'well_data', 'metadata']
    print("Essential Data:")
    for file in essential_files:
        status = "✅" if availability[file] else "❌"
        print(f"  {status} {file}")
    
    # Optional data
    optional_files = ['fluid_properties', 'schedule_data', 'cumulative_data', 'flow_data', 'sensitivity_data']
    print("\nOptional Data:")
    for file in optional_files:
        status = "✅" if availability[file] else "❌"
        print(f"  {status} {file}")
    
    # Count available files
    total_files = len(availability)
    available_files = sum(availability.values())
    print(f"\nTotal: {available_files}/{total_files} files available ({100*available_files/total_files:.1f}%)")


def load_initial_conditions():
    """Load initial reservoir conditions."""
    try:
        file_path = '/workspace/data/initial/initial_conditions.mat'
        data = oct2py.io.loadmat(file_path)
        
        # Extract initial_data struct
        initial_data = data['initial_data']
        
        return {
            'pressure': np.array(initial_data['pressure'][0,0]),  # [psi]
            'sw': np.array(initial_data['sw'][0,0]),  # [-]
            'phi': np.array(initial_data['phi'][0,0]),  # [-]
            'k': np.array(initial_data['k'][0,0])  # [mD]
        }
        
    except Exception as e:
        print(f"[ERROR] Failed to load initial conditions: {e}")
        return None


def load_static_data():
    """Load static reservoir data."""
    try:
        file_path = '/workspace/data/static/static_data.mat'
        data = oct2py.io.loadmat(file_path)
        
        # Extract static_data struct
        static_data = data['static_data']
        
        return {
            'rock_id': np.array(static_data['rock_id'][0,0]),  # [-]
            'grid_x': np.array(static_data['grid_x'][0,0]).flatten(),
            'grid_y': np.array(static_data['grid_y'][0,0]).flatten(),
            'cell_centers_x': np.array(static_data['cell_centers_x'][0,0]).flatten(),
            'cell_centers_y': np.array(static_data['cell_centers_y'][0,0]).flatten(),
            'wells': static_data['wells'][0,0]
        }
        
    except Exception as e:
        print(f"[ERROR] Failed to load static data: {e}")
        return None


def load_temporal_data():
    """Load temporal data (time vectors)."""
    try:
        file_path = '/workspace/data/temporal/time_data.mat'
        data = oct2py.io.loadmat(file_path)
        
        # Extract temporal_data struct
        temporal_data = data['temporal_data']
        
        return {
            'time_days': np.array(temporal_data['time_days'][0,0]).flatten(),
            'dt_days': np.array(temporal_data['dt_days'][0,0]).flatten(),
            'control_indices': np.array(temporal_data['control_indices'][0,0]).flatten()
        }
        
    except Exception as e:
        print(f"[ERROR] Failed to load temporal data: {e}")
        return None


def load_field_arrays():
    """Load dynamic field arrays."""
    try:
        file_path = '/workspace/data/dynamic/fields/field_arrays.mat'
        data = oct2py.io.loadmat(file_path)
        
        # Extract fields_data struct (note: different name than field_arrays)
        fields_data = data['fields_data']
        
        return {
            'pressure': np.array(fields_data['pressure'][0,0]),  # [time, y, x] [psi]
            'sw': np.array(fields_data['sw'][0,0]),  # [time, y, x] [-]
            'phi': np.array(fields_data['phi'][0,0]),  # [time, y, x] [-]
            'k': np.array(fields_data['k'][0,0]),  # [time, y, x] [mD]
            'sigma_eff': np.array(fields_data['sigma_eff'][0,0])  # [time, y, x] [psi]
        }
        
    except Exception as e:
        print(f"[ERROR] Failed to load field arrays: {e}")
        return None


def load_well_data():
    """Load well operational data."""
    try:
        file_path = '/workspace/data/dynamic/wells/well_data.mat'
        data = oct2py.io.loadmat(file_path)
        
        # Extract wells_dynamic struct (note: different name than well_data)
        wells_dynamic = data['wells_dynamic']
        
        return {
            'time_days': np.array(wells_dynamic['time_days'][0,0]).flatten(),
            'well_names': [str(name[0]) for name in wells_dynamic['well_names'][0,0]],
            'qWs': np.array(wells_dynamic['qWs'][0,0]),  # [time, well] [STB/d]
            'qOs': np.array(wells_dynamic['qOs'][0,0]),  # [time, well] [STB/d]
            'bhp': np.array(wells_dynamic['bhp'][0,0])  # [time, well] [psi]
        }
        
    except Exception as e:
        print(f"[ERROR] Failed to load well data: {e}")
        return None


def load_metadata():
    """Load dataset metadata."""
    try:
        file_path = '/workspace/data/metadata/metadata.mat'
        data = oct2py.io.loadmat(file_path)
        
        # Extract metadata struct
        metadata = data['metadata']
        
        return {
            'dataset_info': metadata['dataset_info'][0,0],
            'simulation': metadata['simulation'][0,0],
            'structure': metadata['structure'][0,0],
            'optimization': metadata['optimization'][0,0],
            'units': metadata['units'][0,0],
            'conventions': metadata['conventions'][0,0]
        }
        
    except Exception as e:
        print(f"[ERROR] Failed to load metadata: {e}")
        return None


def load_fluid_properties():
    """Load fluid properties data (kr curves and PVT data).
    
    Returns:
        dict: Fluid properties data with kr_curves and pvt_data
    """
    try:
        file_path = '/workspace/data/static/fluid_properties.mat'
        data = oct2py.io.loadmat(file_path)
        
        # Extract fluid_props struct (note: different name than fluid_properties)
        fluid_props = data['fluid_props']
        
        # Handle different possible structures
        result = {}
        
        # Try to extract kr curves
        if 'sw' in fluid_props.dtype.names:
            result['sw'] = np.array(fluid_props['sw'][0,0]).flatten()
        if 'krw' in fluid_props.dtype.names:
            result['krw'] = np.array(fluid_props['krw'][0,0]).flatten()
        if 'kro' in fluid_props.dtype.names:
            result['kro'] = np.array(fluid_props['kro'][0,0]).flatten()
        if 'sWcon' in fluid_props.dtype.names:
            result['sWcon'] = float(fluid_props['sWcon'][0,0])
        if 'sOres' in fluid_props.dtype.names:
            result['sOres'] = float(fluid_props['sOres'][0,0])
        
        # Try to extract viscosities
        if 'mu_water' in fluid_props.dtype.names:
            result['mu_water'] = float(fluid_props['mu_water'][0,0])
        if 'mu_oil' in fluid_props.dtype.names:
            result['mu_oil'] = float(fluid_props['mu_oil'][0,0])
        
        # Try to extract densities
        if 'rho_water' in fluid_props.dtype.names:
            result['rho_water'] = float(fluid_props['rho_water'][0,0])
        if 'rho_oil' in fluid_props.dtype.names:
            result['rho_oil'] = float(fluid_props['rho_oil'][0,0])
        
        return result
        
    except Exception as e:
        print(f"[ERROR] Failed to load fluid properties: {e}")
        return None


def load_schedule_data():
    """Load schedule data.
    
    Returns:
        dict: Schedule data with time series and rates
    """
    try:
        file_path = '/workspace/data/temporal/schedule_data.mat'
        data = oct2py.io.loadmat(file_path)
        
        # Extract schedule_data struct
        schedule_data = data['schedule_data']
        
        return {
            'time_days': np.array(schedule_data['time_days'][0,0]).flatten(),
            'n_timesteps': int(schedule_data['n_timesteps'][0,0]),
            'n_wells': int(schedule_data['n_wells'][0,0]),
            'well_names': [str(name[0]) for name in schedule_data['well_names'][0,0]],
            'production_rates': np.array(schedule_data['production_rates'][0,0]).flatten(),
            'injection_rates': np.array(schedule_data['injection_rates'][0,0]).flatten()
        }
        
    except Exception as e:
        print(f"[ERROR] Failed to load schedule data: {e}")
        return None


def load_cumulative_data():
    """Load cumulative production/injection data.
    
    Returns:
        dict: Cumulative data with time series and well information
    """
    try:
        file_path = '/workspace/data/dynamic/wells/cumulative_data.mat'
        data = oct2py.io.loadmat(file_path)
        
        # Extract cumulative_data struct
        cumulative_data = data['cumulative_data']
        
        return {
            'time_days': np.array(cumulative_data['time_days'][0,0]).flatten(),
            'well_names': [str(name[0]) for name in cumulative_data['well_names'][0,0]],
            'cum_oil_prod': np.array(cumulative_data['cum_oil_prod'][0,0]),
            'cum_water_prod': np.array(cumulative_data['cum_water_prod'][0,0]),
            'cum_water_inj': np.array(cumulative_data['cum_water_inj'][0,0]),
            'pv_injected': np.array(cumulative_data['pv_injected'][0,0]).flatten(),
            'recovery_factor': np.array(cumulative_data['recovery_factor'][0,0]).flatten()
        }
        
    except Exception as e:
        print(f"[ERROR] Failed to load cumulative data: {e}")
        return None


def load_flow_data():
    """Load flow velocity data.
    
    Returns:
        dict: Flow data with velocity fields
    """
    try:
        file_path = '/workspace/data/dynamic/fields/flow_data.mat'
        data = oct2py.io.loadmat(file_path)
        
        # Extract flow_data struct
        flow_data = data['flow_data']
        
        return {
            'time_days': np.array(flow_data['time_days'][0,0]).flatten(),
            'vx': np.array(flow_data['vx'][0,0]),  # [time, y, x]
            'vy': np.array(flow_data['vy'][0,0]),  # [time, y, x]
            'velocity_magnitude': np.array(flow_data['velocity_magnitude'][0,0])  # [time, y, x]
        }
        
    except Exception as e:
        print(f"[ERROR] Failed to load flow data: {e}")
        return None


def load_sensitivity_data():
    """Load sensitivity analysis data.
    
    Returns:
        dict: Sensitivity data with parameter variations and tornado plot data
    """
    try:
        file_path = '/workspace/data/sensitivity/sensitivity_data.mat'
        data = oct2py.io.loadmat(file_path)
        
        # Extract sensitivity_data struct
        sensitivity_data = data['sensitivity_data']
        
        return {
            'parameter_names': [str(name[0]) for name in sensitivity_data['parameter_names'][0,0]],
            'base_case_production': float(sensitivity_data['base_case_production'][0,0]),
            'varied_production': np.array(sensitivity_data['varied_production'][0,0]),
            'sensitivity_matrix': np.array(sensitivity_data['sensitivity_matrix'][0,0]),
            'tornado_data': {
                'parameter_names': [str(name[0]) for name in sensitivity_data['tornado_data'][0,0]['parameter_names'][0,0]],
                'sensitivity_values': np.array(sensitivity_data['tornado_data'][0,0]['sensitivity_values'][0,0]).flatten(),
                'production_low': np.array(sensitivity_data['tornado_data'][0,0]['production_low'][0,0]).flatten(),
                'production_high': np.array(sensitivity_data['tornado_data'][0,0]['production_high'][0,0]).flatten()
            },
            'parameter_values': np.array(sensitivity_data['parameter_values'][0,0]),
            'variation_levels': np.array(sensitivity_data['variation_levels'][0,0]).flatten()
        }
        
    except Exception as e:
        print(f"[ERROR] Failed to load sensitivity data: {e}")
        return None


def load_reservoir_data():
    """Load reservoir volumetric data from metadata.
    
    Returns:
        dict: Reservoir data with OOIP, PV, and voidage information
    """
    try:
        metadata = load_metadata()
        if metadata and 'reservoir_data' in metadata:
            reservoir_data = metadata['reservoir_data']
            return {
                'ooip_initial': float(reservoir_data['ooip_initial']),
                'pv_initial': float(reservoir_data['pv_initial']),
                'voidage_ratio': np.array(reservoir_data['voidage_ratio']).flatten()
            }
        else:
            print("[WARN] Reservoir data not found in metadata")
            return None
            
    except Exception as e:
        print(f"[ERROR] Failed to load reservoir data: {e}")
        return None


def load_dynamic_fields():
    """Alias for load_field_arrays for backward compatibility."""
    return load_field_arrays()


# Helper functions for specific plot requirements
def get_well_locations():
    """Get well locations from static data.
    
    Returns:
        tuple: (producers, injectors) dictionaries with well names and locations
    """
    try:
        static_data = load_static_data()
        if static_data and 'wells' in static_data:
            wells = static_data['wells']
            
            producers = {}
            injectors = {}
            
            # Extract well information
            well_names = wells['well_names'][0,0]
            well_i = wells['well_i'][0,0]
            well_j = wells['well_j'][0,0]
            well_types = wells['well_types'][0,0]
            
            for i in range(len(well_names)):
                name = str(well_names[i][0])
                location = (int(well_i[i]), int(well_j[i]))
                well_type = str(well_types[i][0])
                
                if well_type == 'producer':
                    producers[name] = location
                else:
                    injectors[name] = location
            
            return producers, injectors
        else:
            # Default well pattern if no data available
            producers = {
                'P1': (5, 5),
                'P2': (15, 5),
                'P3': (5, 15),
                'P4': (15, 15)
            }
            
            injectors = {
                'I1': (10, 10),
                'I2': (2, 10),
                'I3': (18, 10),
                'I4': (10, 2),
                'I5': (10, 18)
            }
            
            return producers, injectors
            
    except Exception as e:
        print(f"[ERROR] Failed to get well locations: {e}")
        # Return default pattern
        producers = {
            'P1': (5, 5),
            'P2': (15, 5),
            'P3': (5, 15),
            'P4': (15, 15)
        }
        
        injectors = {
            'I1': (10, 10),
            'I2': (2, 10),
            'I3': (18, 10),
            'I4': (10, 2),
            'I5': (10, 18)
        }
        
        return producers, injectors


def calculate_water_cut(well_data):
    """Calculate water cut from well data.
    
    Args:
        well_data: Dictionary from load_well_data()
        
    Returns:
        dict: Water cut data with time and well information
    """
    try:
        qWs = well_data['qWs']
        qOs = well_data['qOs']
        
        # Calculate water cut: qw / (qw + qo)
        total_liquid = qWs + qOs
        water_cut = np.where(total_liquid > 0, qWs / total_liquid, 0)
        
        return {
            'time_days': well_data['time_days'],
            'well_names': well_data['well_names'],
            'water_cut': water_cut
        }
        
    except Exception as e:
        print(f"[ERROR] Failed to calculate water cut: {e}")
        return None


def calculate_voidage_ratio(schedule_data):
    """Calculate voidage ratio from schedule data.
    
    Args:
        schedule_data: Dictionary from load_schedule_data()
        
    Returns:
        dict: Voidage ratio data
    """
    try:
        production_rates = schedule_data['production_rates']
        injection_rates = schedule_data['injection_rates']
        
        # Calculate voidage ratio: injection / production
        voidage_ratio = np.where(production_rates > 0, injection_rates / production_rates, 0)
        
        return {
            'time_days': schedule_data['time_days'],
            'voidage_ratio': voidage_ratio
        }
        
    except Exception as e:
        print(f"[ERROR] Failed to calculate voidage ratio: {e}")
        return None


def calculate_fractional_flow(well_data):
    """Calculate fractional flow from well data.
    
    Args:
        well_data: Dictionary from load_well_data()
        
    Returns:
        dict: Fractional flow data
    """
    try:
        qWs = well_data['qWs']
        qOs = well_data['qOs']
        
        # Calculate fractional flow: qw / (qw + qo)
        total_flow = qWs + qOs
        fw = np.where(total_flow > 0, qWs / total_flow, 0)
        
        return {
            'time_days': well_data['time_days'],
            'well_names': well_data['well_names'],
            'fractional_flow': fw
        }
        
    except Exception as e:
        print(f"[ERROR] Failed to calculate fractional flow: {e}")
        return None 