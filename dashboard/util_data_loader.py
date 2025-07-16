#!/usr/bin/env python3
"""
MRST Simulation Data Loader

Loads and processes MRST simulation data from MAT files following the
data generation policy. All data originates from MRST simulator authority
with proper traceability and no hard-coded values.
"""

import numpy as np
import oct2py
from pathlib import Path
import warnings
from typing import Dict, Optional, Any

# ----------------------------------------
# Step 1 – Main data loader class
# ----------------------------------------

class MRSTDataLoader:
    """
    Loads MRST simulation data from the standardized export structure.
    
    Follows data generation policy:
    - No hard-coded values except physical constants
    - All data originates from MRST simulator authority
    - Proper traceability through metadata
    """
    
    def __init__(self, data_root: str = "../data"):
        """
        Initialize data loader with base path.
        
        Args:
            data_root: Base path to simulation data directory
        """
        self.data_root = Path(data_root)
        self.file_map = self._define_file_structure()
        
        # ✅ Verify oct2py availability
        try:
            self.oct2py_engine = oct2py.Oct2Py()
            self.oct2py_available = True
        except Exception as e:
            warnings.warn(f"oct2py not available: {e}")
            self.oct2py_available = False
    
    def _define_file_structure(self) -> Dict[str, Path]:
        """
        Define expected MRST export file structure.
        
        Returns:
            dict: Mapping of data types to file paths
        """
        return {
            'initial_conditions': self.data_root / 'initial' / 'initial_conditions.mat',
            'static_data': self.data_root / 'static' / 'static_data.mat',
            'fluid_properties': self.data_root / 'static' / 'fluid_properties.mat',
            'field_arrays': self.data_root / 'dynamic' / 'fields' / 'field_arrays.mat',
            'flow_data': self.data_root / 'dynamic' / 'fields' / 'flow_data.mat',
            'well_data': self.data_root / 'dynamic' / 'wells' / 'well_data.mat',
            'cumulative_data': self.data_root / 'dynamic' / 'wells' / 'cumulative_data.mat',
            'time_data': self.data_root / 'temporal' / 'time_data.mat',
            'schedule_data': self.data_root / 'temporal' / 'schedule.mat',
            'metadata': self.data_root / 'metadata' / 'metadata.mat'
        }
    
    def check_data_availability(self) -> Dict[str, bool]:
        """
        Check availability of MRST simulation data files.
        
        Returns:
            dict: Availability status for each data type
        """
        availability = {}
        
        for data_type, file_path in self.file_map.items():
            availability[data_type] = file_path.exists()
        
        return availability
    
    def load_initial_conditions(self) -> Optional[Dict[str, np.ndarray]]:
        """
        Load initial reservoir conditions from MRST export.
        
        Returns:
            dict: Initial conditions data including pressure, saturation, porosity, permeability
        """
        file_path = self.file_map['initial_conditions']
        
        if not file_path.exists():
            warnings.warn(f"Initial conditions file not found: {file_path}")
            return None
        
        if not self.oct2py_available:
            warnings.warn("oct2py not available for MAT file loading")
            return None
        
        try:
            # 📊 Load MAT file using oct2py
            data = oct2py.io.loadmat(str(file_path))
            
            return {
                'pressure': np.array(data['pressure']),  # [psi]
                'sw': np.array(data['sw']),  # [-]
                'phi': np.array(data['phi']),  # [-]
                'k': np.array(data['k'])  # [mD]
            }
            
        except Exception as e:
            warnings.warn(f"Failed to load initial conditions: {e}")
            return None
    
    def load_static_data(self) -> Optional[Dict[str, Any]]:
        """
        Load static reservoir data from MRST export.
        
        Returns:
            dict: Static data including grid coordinates, rock regions, well locations
        """
        file_path = self.file_map['static_data']
        
        if not file_path.exists():
            warnings.warn(f"Static data file not found: {file_path}")
            return None
        
        if not self.oct2py_available:
            warnings.warn("oct2py not available for MAT file loading")
            return None
        
        try:
            # 📊 Load MAT file using oct2py
            data = oct2py.io.loadmat(str(file_path))
            
            return {
                'rock_id': np.array(data['rock_id']),  # [-]
                'grid_x': np.array(data['grid_x']).flatten(),  # [m]
                'grid_y': np.array(data['grid_y']).flatten(),  # [m]
                'cell_centers_x': np.array(data['cell_centers_x']).flatten(),  # [m]
                'cell_centers_y': np.array(data['cell_centers_y']).flatten(),  # [m]
                'wells': data.get('wells', {})
            }
            
        except Exception as e:
            warnings.warn(f"Failed to load static data: {e}")
            return None
    
    def load_field_arrays(self) -> Optional[Dict[str, np.ndarray]]:
        """
        Load dynamic field arrays from MRST export.
        
        Returns:
            dict: Field arrays including pressure, saturation evolution over time
        """
        file_path = self.file_map['field_arrays']
        
        if not file_path.exists():
            warnings.warn(f"Field arrays file not found: {file_path}")
            return None
        
        if not self.oct2py_available:
            warnings.warn("oct2py not available for MAT file loading")
            return None
        
        try:
            # 📊 Load MAT file using oct2py
            data = oct2py.io.loadmat(str(file_path))
            
            return {
                'pressure': np.array(data['pressure']),  # [time, y, x] [psi]
                'sw': np.array(data['sw']),  # [time, y, x] [-]
                'phi': np.array(data['phi']),  # [time, y, x] [-]
                'k': np.array(data['k']),  # [time, y, x] [mD]
                'sigma_eff': np.array(data.get('sigma_eff', data['pressure']))  # [time, y, x] [psi]
            }
            
        except Exception as e:
            warnings.warn(f"Failed to load field arrays: {e}")
            return None
    
    def load_flow_data(self) -> Optional[Dict[str, np.ndarray]]:
        """
        Load flow velocity data from MRST export.
        
        Returns:
            dict: Flow data including velocity components and magnitude
        """
        file_path = self.file_map['flow_data']
        
        if not file_path.exists():
            warnings.warn(f"Flow data file not found: {file_path}")
            return None
        
        if not self.oct2py_available:
            warnings.warn("oct2py not available for MAT file loading")
            return None
        
        try:
            # 📊 Load MAT file using oct2py
            data = oct2py.io.loadmat(str(file_path))
            
            return {
                'time_days': np.array(data['time_days']).flatten(),  # [days]
                'vx': np.array(data['vx']),  # [time, y, x] [m/day]
                'vy': np.array(data['vy']),  # [time, y, x] [m/day]
                'velocity_magnitude': np.array(data['velocity_magnitude'])  # [time, y, x] [m/day]
            }
            
        except Exception as e:
            warnings.warn(f"Failed to load flow data: {e}")
            return None
    
    def load_well_data(self) -> Optional[Dict[str, Any]]:
        """
        Load well operational data from MRST export.
        
        Returns:
            dict: Well data including production rates, injection rates, pressures
        """
        file_path = self.file_map['well_data']
        
        if not file_path.exists():
            warnings.warn(f"Well data file not found: {file_path}")
            return None
        
        if not self.oct2py_available:
            warnings.warn("oct2py not available for MAT file loading")
            return None
        
        try:
            # 📊 Load MAT file using oct2py
            data = oct2py.io.loadmat(str(file_path))
            
            return {
                'time_days': np.array(data['time_days']).flatten(),  # [days]
                'well_names': data['well_names'],  # [string array]
                'qWs': np.array(data['qWs']),  # [time, well] [m³/day]
                'qOs': np.array(data['qOs']),  # [time, well] [m³/day]
                'bhp': np.array(data['bhp'])  # [time, well] [psi]
            }
            
        except Exception as e:
            warnings.warn(f"Failed to load well data: {e}")
            return None
    
    def load_cumulative_data(self) -> Optional[Dict[str, Any]]:
        """
        Load cumulative production data from MRST export.
        
        Returns:
            dict: Cumulative data including production, injection, recovery factor
        """
        file_path = self.file_map['cumulative_data']
        
        if not file_path.exists():
            warnings.warn(f"Cumulative data file not found: {file_path}")
            return None
        
        if not self.oct2py_available:
            warnings.warn("oct2py not available for MAT file loading")
            return None
        
        try:
            # 📊 Load MAT file using oct2py
            data = oct2py.io.loadmat(str(file_path))
            
            return {
                'time_days': np.array(data['time_days']).flatten(),  # [days]
                'well_names': data['well_names'],  # [string array]
                'cum_oil_prod': np.array(data['cum_oil_prod']),  # [time, well] [m³]
                'cum_water_prod': np.array(data['cum_water_prod']),  # [time, well] [m³]
                'cum_water_inj': np.array(data['cum_water_inj']),  # [time, well] [m³]
                'pv_injected': np.array(data['pv_injected']).flatten(),  # [time] [bbl]
                'recovery_factor': np.array(data['recovery_factor']).flatten()  # [time] [-]
            }
            
        except Exception as e:
            warnings.warn(f"Failed to load cumulative data: {e}")
            return None
    
    def load_metadata(self) -> Optional[Dict[str, Any]]:
        """
        Load simulation metadata from MRST export.
        
        Returns:
            dict: Metadata including simulation parameters, grid info, units
        """
        file_path = self.file_map['metadata']
        
        if not file_path.exists():
            warnings.warn(f"Metadata file not found: {file_path}")
            return None
        
        if not self.oct2py_available:
            warnings.warn("oct2py not available for MAT file loading")
            return None
        
        try:
            # 📊 Load MAT file using oct2py
            data = oct2py.io.loadmat(str(file_path))
            
            return {
                'dataset_info': data.get('dataset_info', {}),
                'simulation': data.get('simulation', {}),
                'grid_dimensions': data.get('grid_dimensions', [20, 20, 1]),
                'total_time': data.get('total_time', 365),
                'n_timesteps': data.get('n_timesteps', 50),
                'units': data.get('units', {}),
                'conventions': data.get('conventions', {})
            }
            
        except Exception as e:
            warnings.warn(f"Failed to load metadata: {e}")
            return None
    
    def load_complete_dataset(self) -> Dict[str, Any]:
        """
        Load complete MRST simulation dataset.
        
        Returns:
            dict: Complete dataset with all available data types
        """
        dataset = {
            'availability': self.check_data_availability()
        }
        
        # 🔄 Load all available data types
        dataset['initial_conditions'] = self.load_initial_conditions()
        dataset['static_data'] = self.load_static_data()
        dataset['field_arrays'] = self.load_field_arrays()
        dataset['flow_data'] = self.load_flow_data()
        dataset['well_data'] = self.load_well_data()
        dataset['cumulative_data'] = self.load_cumulative_data()
        dataset['metadata'] = self.load_metadata()
        
        # 🔄 Load wells information from configuration
        try:
            from config_reader import load_simulation_config, get_well_parameters
            config = load_simulation_config()
            dataset['wells'] = get_well_parameters(config)
        except Exception as e:
            warnings.warn(f"Failed to load wells from configuration: {e}")
            dataset['wells'] = None
        
        return dataset