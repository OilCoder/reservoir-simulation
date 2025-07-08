#!/usr/bin/env python3
"""
Utility functions for loading optimized MRST data structure

This module provides functions to load data from the optimized MRST export system:
- initial/: Initial reservoir conditions (t=0)
- static/: Data that never changes (grid, wells, rock regions)
- dynamic/fields/: 3D time-dependent field arrays [time, y, x]
- dynamic/wells/: Well operational data [time, well]
- temporal/: Time vectors and schedules
- metadata/: Dataset documentation
"""

import numpy as np
import scipy.io
from pathlib import Path
from typing import Dict, List, Tuple, Optional, Any


def parse_octave_mat_file(filepath: Path) -> Dict[str, Any]:
    """
    Parse Octave text format .mat file
    
    Args:
        filepath: Path to the .mat file
        
    Returns:
        Dictionary containing the loaded data
    """
    data = {}
    current_var = None
    reading_matrix = False
    
    with open(filepath, 'r') as f:
        lines = f.readlines()
    
    i = 0
    while i < len(lines):
        line = lines[i].strip()
        
        if line.startswith('#') or not line:
            if line.startswith('# name:'):
                current_var = line.split(':', 1)[1].strip()
            elif line.startswith('# type: matrix'):
                reading_matrix = True
            elif line.startswith('# rows:'):
                rows = int(line.split(':', 1)[1].strip())
            elif line.startswith('# columns:'):
                cols = int(line.split(':', 1)[1].strip())
                if reading_matrix and current_var:
                    matrix_data = []
                    for j in range(i + 1, i + 1 + rows):
                        if j < len(lines):
                            row_data = [float(x) for x in lines[j].split()]
                            matrix_data.extend(row_data)
                    data[current_var] = np.array(matrix_data).reshape(rows, cols)
                    i += rows
                    reading_matrix = False
                    current_var = None
        i += 1
    
    return data


def load_initial_conditions(data_path: str = "/workspace/data") -> Dict[str, np.ndarray]:
    """
    Load initial reservoir conditions (t=0)
    
    Args:
        data_path: Base path to the data directory
        
    Returns:
        Dictionary containing initial conditions:
        - pressure: [y, x] initial pressure in psia
        - sw: [y, x] initial water saturation
        - phi: [y, x] initial porosity
        - k: [y, x] initial permeability in mD
    """
    data_path = Path(data_path)
    initial_file = data_path / "initial" / "initial_conditions.mat"
    
    if not initial_file.exists():
        # Fallback to old structure
        initial_file = data_path / "initial" / "initial_setup.mat"
        if not initial_file.exists():
            raise FileNotFoundError(f"Initial conditions file not found: {initial_file}")
    
    try:
        # Try scipy.io first (for binary .mat files)
        data = scipy.io.loadmat(str(initial_file))
        # Extract the actual data structure
        if 'initial_data' in data:
            initial_data = data['initial_data'][0, 0]  # Extract from structured array
            result = {}
            
            # Handle structured array format from MRST export
            if hasattr(initial_data, 'dtype') and initial_data.dtype.names:
                # Structured array format
                for field in ['pressure', 'sw', 'phi', 'k']:
                    if field in initial_data.dtype.names:
                        field_data = initial_data[field]
                        # Extract from nested arrays
                        if isinstance(field_data, np.ndarray) and field_data.size > 0:
                            if field_data.dtype == 'O':  # Object array
                                result[field] = field_data.flatten()[0]
                            else:
                                result[field] = field_data
            else:
                # Regular struct format
                for field in ['pressure', 'sw', 'phi', 'k']:
                    if hasattr(initial_data, field):
                        result[field] = getattr(initial_data, field)
            return result
        elif 'initial_setup' in data:
            # Old format compatibility
            initial_setup = data['initial_setup'][0, 0]
            result = {}
            
            # Handle structured array format
            if hasattr(initial_setup, 'dtype') and initial_setup.dtype.names:
                # Map old field names to new names
                field_mapping = {
                    'pressure_init': 'pressure',
                    'sw_init': 'sw',
                    'phi': 'phi',
                    'k': 'k'
                }
                for old_field, new_field in field_mapping.items():
                    if old_field in initial_setup.dtype.names:
                        field_data = initial_setup[old_field]
                        if isinstance(field_data, np.ndarray) and field_data.size > 0:
                            if field_data.dtype == 'O':  # Object array
                                result[new_field] = field_data.flatten()[0]
                            else:
                                result[new_field] = field_data
            else:
                # Regular struct format
                if hasattr(initial_setup, 'pressure_init'):
                    result['pressure'] = getattr(initial_setup, 'pressure_init')
                if hasattr(initial_setup, 'sw_init'):
                    result['sw'] = getattr(initial_setup, 'sw_init')
                if hasattr(initial_setup, 'phi'):
                    result['phi'] = getattr(initial_setup, 'phi')
                if hasattr(initial_setup, 'k'):
                    result['k'] = getattr(initial_setup, 'k')
            return result
    except Exception:
        # Fallback to Octave text format parser
        data = parse_octave_mat_file(initial_file)
        if 'initial_data' in data:
            return data['initial_data']
        elif 'initial_setup' in data:
            # Map old names to new names
            result = {}
            setup = data['initial_setup']
            if 'pressure_init' in setup:
                result['pressure'] = setup['pressure_init']
            if 'sw_init' in setup:
                result['sw'] = setup['sw_init']
            if 'phi' in setup:
                result['phi'] = setup['phi']
            if 'k' in setup:
                result['k'] = setup['k']
            return result
    
    raise ValueError(f"Could not parse initial conditions from {initial_file}")


def load_static_data(data_path: str = "/workspace/data") -> Dict[str, Any]:
    """
    Load static data (never changes during simulation)
    
    Args:
        data_path: Base path to the data directory
        
    Returns:
        Dictionary containing static data:
        - rock_id: [y, x] rock region IDs
        - grid_x: Grid x-coordinates
        - grid_y: Grid y-coordinates
        - wells: Well location and type information
    """
    data_path = Path(data_path)
    static_file = data_path / "static" / "static_data.mat"
    
    if not static_file.exists():
        raise FileNotFoundError(f"Static data file not found: {static_file}")
    
    try:
        # Try scipy.io first
        data = scipy.io.loadmat(str(static_file))
        if 'static_data' in data:
            static_data = data['static_data'][0, 0]
            result = {}
            for field in ['rock_id', 'grid_x', 'grid_y', 'cell_centers_x', 'cell_centers_y']:
                if hasattr(static_data, field):
                    result[field] = getattr(static_data, field)
            
            # Handle wells structure
            if hasattr(static_data, 'wells'):
                wells = getattr(static_data, 'wells')[0, 0]
                well_data = {}
                for field in ['well_names', 'well_i', 'well_j', 'well_types']:
                    if hasattr(wells, field):
                        well_data[field] = getattr(wells, field)
                result['wells'] = well_data
            
            return result
    except:
        # Fallback to Octave text format
        data = parse_octave_mat_file(static_file)
        return data.get('static_data', data)
    
    raise ValueError(f"Could not parse static data from {static_file}")


def load_dynamic_fields(data_path: str = "/workspace/data") -> Dict[str, np.ndarray]:
    """
    Load 3D dynamic field arrays [time, y, x]
    
    Args:
        data_path: Base path to the data directory
        
    Returns:
        Dictionary containing 3D field arrays:
        - pressure: [time, y, x] pressure in psia
        - sw: [time, y, x] water saturation
        - phi: [time, y, x] porosity
        - k: [time, y, x] permeability in mD
        - sigma_eff: [time, y, x] effective stress in psia
    """
    data_path = Path(data_path)
    fields_file = data_path / "dynamic" / "fields" / "field_arrays.mat"
    
    if not fields_file.exists():
        raise FileNotFoundError(f"Dynamic fields file not found: {fields_file}")
    
    try:
        # Try scipy.io first
        data = scipy.io.loadmat(str(fields_file))
        if 'fields_data' in data:
            fields_data = data['fields_data'][0, 0]
            result = {}
            for field in ['pressure', 'sw', 'phi', 'k', 'sigma_eff']:
                if hasattr(fields_data, field):
                    result[field] = getattr(fields_data, field)
            return result
    except:
        # Fallback to Octave text format
        data = parse_octave_mat_file(fields_file)
        return data.get('fields_data', data)
    
    raise ValueError(f"Could not parse dynamic fields from {fields_file}")


def load_well_data(data_path: str = "/workspace/data") -> Dict[str, Any]:
    """
    Load well operational data [time, well]
    
    Args:
        data_path: Base path to the data directory
        
    Returns:
        Dictionary containing well data:
        - time_days: Time vector in days
        - well_names: List of well names
        - qWs: [time, well] water rates in m³/day
        - qOs: [time, well] oil rates in m³/day
        - bhp: [time, well] bottom hole pressure in psia
    """
    data_path = Path(data_path)
    wells_file = data_path / "dynamic" / "wells" / "well_data.mat"
    
    if not wells_file.exists():
        raise FileNotFoundError(f"Well data file not found: {wells_file}")
    
    try:
        # Try scipy.io first
        data = scipy.io.loadmat(str(wells_file))
        if 'wells_dynamic' in data:
            wells_data = data['wells_dynamic'][0, 0]
            result = {}
            for field in ['time_days', 'well_names', 'qWs', 'qOs', 'bhp']:
                if hasattr(wells_data, field):
                    result[field] = getattr(wells_data, field)
            return result
    except:
        # Fallback to Octave text format
        data = parse_octave_mat_file(wells_file)
        return data.get('wells_dynamic', data)
    
    raise ValueError(f"Could not parse well data from {wells_file}")


def load_temporal_data(data_path: str = "/workspace/data") -> Dict[str, np.ndarray]:
    """
    Load temporal data (time vectors and schedules)
    
    Args:
        data_path: Base path to the data directory
        
    Returns:
        Dictionary containing temporal data:
        - time_days: Time vector in days
        - dt_days: Timestep sizes in days
        - control_indices: Control period indices
    """
    data_path = Path(data_path)
    temporal_file = data_path / "temporal" / "time_data.mat"
    
    if not temporal_file.exists():
        raise FileNotFoundError(f"Temporal data file not found: {temporal_file}")
    
    try:
        # Try scipy.io first
        data = scipy.io.loadmat(str(temporal_file))
        if 'temporal_data' in data:
            temporal_data = data['temporal_data'][0, 0]  # Extract from structured array
            result = {}
            
            # Handle structured array format from MRST export
            if hasattr(temporal_data, 'dtype') and temporal_data.dtype.names:
                # Structured array format
                for field in ['time_days', 'dt_days', 'control_indices']:
                    if field in temporal_data.dtype.names:
                        field_data = temporal_data[field]
                        # Extract from nested arrays
                        if isinstance(field_data, np.ndarray) and field_data.size > 0:
                            if field_data.dtype == 'O':  # Object array
                                result[field] = field_data.flatten()[0].flatten()
                            else:
                                result[field] = field_data.flatten()
            else:
                # Regular struct format
                for field in ['time_days', 'dt_days', 'control_indices']:
                    if hasattr(temporal_data, field):
                        result[field] = getattr(temporal_data, field)
            return result
    except:
        # Fallback to Octave text format
        data = parse_octave_mat_file(temporal_file)
        return data.get('temporal_data', data)
    
    raise ValueError(f"Could not parse temporal data from {temporal_file}")


def load_fluid_properties(data_path: str = "/workspace/data") -> Dict[str, Any]:
    """
    Load fluid properties
    
    Args:
        data_path: Base path to the data directory
        
    Returns:
        Dictionary containing fluid properties:
        - sw: Water saturation range for kr curves
        - krw: Water relative permeability
        - kro: Oil relative permeability
        - mu_water: Water viscosity in cP
        - mu_oil: Oil viscosity in cP
        - rho_water: Water density
        - rho_oil: Oil density
    """
    data_path = Path(data_path)
    fluid_file = data_path / "static" / "fluid_properties.mat"
    
    if not fluid_file.exists():
        raise FileNotFoundError(f"Fluid properties file not found: {fluid_file}")
    
    try:
        # Try scipy.io first
        data = scipy.io.loadmat(str(fluid_file))
        if 'fluid_props' in data:
            fluid_data = data['fluid_props'][0, 0]
            result = {}
            for field in ['sw', 'krw', 'kro', 'mu_water', 'mu_oil', 'rho_water', 'rho_oil', 'sWcon', 'sOres']:
                if hasattr(fluid_data, field):
                    result[field] = getattr(fluid_data, field)
            return result
        elif 'fluid_export' in data:
            # Old format compatibility
            fluid_data = data['fluid_export'][0, 0]
            result = {}
            for field in ['sw', 'krw', 'kro', 'mu_water', 'mu_oil', 'rho_water', 'rho_oil', 'sWcon', 'sOres']:
                if hasattr(fluid_data, field):
                    result[field] = getattr(fluid_data, field)
            return result
    except:
        # Fallback to Octave text format
        data = parse_octave_mat_file(fluid_file)
        if 'fluid_props' in data:
            return data['fluid_props']
        elif 'fluid_export' in data:
            return data['fluid_export']
    
    raise ValueError(f"Could not parse fluid properties from {fluid_file}")


def load_schedule_data(data_path: str = "/workspace/data") -> Dict[str, Any]:
    """
    Load schedule data for operational plots
    
    Args:
        data_path: Base path to the data directory
        
    Returns:
        Dictionary containing schedule data:
        - time_days: Time vector in days
        - production_rates: Total production rates
        - injection_rates: Total injection rates
        - well_names: List of well names
    """
    data_path = Path(data_path)
    schedule_file = data_path / "temporal" / "schedule_data.mat"
    
    if not schedule_file.exists():
        # Fallback to old location
        schedule_file = data_path / "temporal" / "schedule.mat"
        if not schedule_file.exists():
            raise FileNotFoundError(f"Schedule data file not found: {schedule_file}")
    
    try:
        # Try scipy.io first
        data = scipy.io.loadmat(str(schedule_file))
        if 'schedule_data' in data:
            schedule_data = data['schedule_data'][0, 0]
            result = {}
            for field in ['time_days', 'production_rates', 'injection_rates', 'well_names', 'n_timesteps', 'n_wells']:
                if hasattr(schedule_data, field):
                    result[field] = getattr(schedule_data, field)
            return result
        elif 'schedule_export' in data:
            # Old format compatibility
            schedule_data = data['schedule_export'][0, 0]
            result = {}
            # Map old field names to new ones
            if hasattr(schedule_data, 'time'):
                result['time_days'] = getattr(schedule_data, 'time')
            if hasattr(schedule_data, 'production_rates'):
                result['production_rates'] = getattr(schedule_data, 'production_rates')
            if hasattr(schedule_data, 'injection_rates'):
                result['injection_rates'] = getattr(schedule_data, 'injection_rates')
            if hasattr(schedule_data, 'well_names'):
                result['well_names'] = getattr(schedule_data, 'well_names')
            if hasattr(schedule_data, 'n_timesteps'):
                result['n_timesteps'] = getattr(schedule_data, 'n_timesteps')
            if hasattr(schedule_data, 'n_wells'):
                result['n_wells'] = getattr(schedule_data, 'n_wells')
            return result
    except:
        # Fallback to Octave text format
        data = parse_octave_mat_file(schedule_file)
        if 'schedule_data' in data:
            return data['schedule_data']
        elif 'schedule_export' in data:
            # Map old field names
            result = data['schedule_export'].copy()
            if 'time' in result and 'time_days' not in result:
                result['time_days'] = result['time']
            return result
    
    raise ValueError(f"Could not parse schedule data from {schedule_file}")


def load_metadata(data_path: str = "/workspace/data") -> Dict[str, Any]:
    """
    Load dataset metadata
    
    Args:
        data_path: Base path to the data directory
        
    Returns:
        Dictionary containing metadata information
    """
    data_path = Path(data_path)
    metadata_file = data_path / "metadata" / "metadata.mat"
    
    if not metadata_file.exists():
        raise FileNotFoundError(f"Metadata file not found: {metadata_file}")
    
    try:
        # Try scipy.io first
        data = scipy.io.loadmat(str(metadata_file))
        if 'metadata' in data:
            return data['metadata']
    except:
        # Fallback to Octave text format
        data = parse_octave_mat_file(metadata_file)
        return data.get('metadata', data)
    
    raise ValueError(f"Could not parse metadata from {metadata_file}")


def get_simulation_info(data_path: str = "/workspace/data") -> Dict[str, Any]:
    """
    Get basic simulation information
    
    Args:
        data_path: Base path to the data directory
        
    Returns:
        Dictionary with simulation info:
        - n_timesteps: Number of timesteps
        - n_wells: Number of wells
        - grid_shape: Grid dimensions [ny, nx]
        - total_time_days: Total simulation time
    """
    try:
        temporal = load_temporal_data(data_path)
        initial = load_initial_conditions(data_path)
        
        info = {
            'n_timesteps': len(temporal['time_days']),
            'total_time_days': float(np.max(temporal['time_days'])),
            'grid_shape': initial['pressure'].shape  # [ny, nx]
        }
        
        try:
            wells = load_well_data(data_path)
            info['n_wells'] = len(wells['well_names'])
        except:
            info['n_wells'] = 'Unknown'
        
        return info
    except Exception as e:
        raise ValueError(f"Could not get simulation info: {e}")


def load_snapshot_at_time(timestep: int, data_path: str = "/workspace/data") -> Dict[str, np.ndarray]:
    """
    Load a specific timestep snapshot from the 3D arrays
    
    Args:
        timestep: Timestep index (0-based)
        data_path: Base path to the data directory
        
    Returns:
        Dictionary containing 2D arrays for the specified timestep:
        - pressure: [y, x] pressure in psia
        - sw: [y, x] water saturation
        - phi: [y, x] porosity
        - k: [y, x] permeability in mD
        - sigma_eff: [y, x] effective stress in psia
    """
    fields = load_dynamic_fields(data_path)
    temporal = load_temporal_data(data_path)
    
    if timestep >= len(temporal['time_days']):
        raise ValueError(f"Timestep {timestep} out of range (max: {len(temporal['time_days'])-1})")
    
    snapshot = {}
    for field_name, field_data in fields.items():
        if len(field_data.shape) == 3:  # 3D array [time, y, x]
            snapshot[field_name] = field_data[timestep, :, :]
        else:
            snapshot[field_name] = field_data
    
    # Add time information
    snapshot['time_days'] = temporal['time_days'][timestep]
    snapshot['timestep'] = timestep
    
    return snapshot


# Convenience function for backward compatibility
def load_snapshots(data_path: str = "/workspace/data") -> Tuple[List[Dict], List[int]]:
    """
    Load all snapshots (backward compatibility function)
    
    Args:
        data_path: Base path to the data directory
        
    Returns:
        Tuple of (snapshots list, timestep indices)
    """
    fields = load_dynamic_fields(data_path)
    temporal = load_temporal_data(data_path)
    
    n_timesteps = len(temporal['time_days'])
    snapshots = []
    timesteps = list(range(n_timesteps))
    
    for t in range(n_timesteps):
        snapshot = load_snapshot_at_time(t, data_path)
        snapshots.append(snapshot)
    
    return snapshots, timesteps


if __name__ == "__main__":
    # Test the data loading functions
    try:
        print("Testing optimized data loading...")
        
        # Test basic info
        info = get_simulation_info()
        print(f"✅ Simulation info: {info}")
        
        # Test initial conditions
        initial = load_initial_conditions()
        print(f"✅ Initial conditions loaded: {list(initial.keys())}")
        
        # Test static data
        static = load_static_data()
        print(f"✅ Static data loaded: {list(static.keys())}")
        
        # Test dynamic fields
        fields = load_dynamic_fields()
        print(f"✅ Dynamic fields loaded: {list(fields.keys())}")
        
        # Test temporal data
        temporal = load_temporal_data()
        print(f"✅ Temporal data loaded: {list(temporal.keys())}")
        
        print("✅ All data loading tests passed!")
        
    except Exception as e:
        print(f"❌ Data loading test failed: {e}") 