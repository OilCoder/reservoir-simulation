#!/usr/bin/env python3
"""
Data Loader Module - GeomechML Dashboard
========================================

Module for loading and processing MRST simulation data from .mat files.
Handles YAML configuration and temporal simulation data.

Author: GeomechML Team
Date: 2025-07-23
"""

import os
import numpy as np
import pandas as pd
import yaml
from scipy.io import loadmat
from typing import Dict, List, Optional, Union, Tuple
import glob
import logging
from pathlib import Path

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

class ConfigLoader:
    """Project YAML configuration loader"""
    
    def __init__(self, config_path: str = "../config/reservoir_config.yaml"):
        """
        Initialize the configuration loader.
        
        Args:
            config_path: Path to the YAML configuration file
        """
        self.config_path = os.path.join(os.path.dirname(__file__), config_path)
        
    def load_config(self) -> Optional[Dict]:
        """
        Load configuration from YAML file.
        
        Returns:
            Dictionary with configuration or None if error
        """
        try:
            with open(self.config_path, 'r', encoding='utf-8') as file:
                config = yaml.safe_load(file)
            logger.info(f"Configuration loaded successfully from {self.config_path}")
            return config
        except FileNotFoundError:
            logger.error(f"Configuration file not found: {self.config_path}")
            return None
        except yaml.YAMLError as e:
            logger.error(f"Error parsing YAML: {e}")
            return None
        except Exception as e:
            logger.error(f"Unexpected error loading configuration: {e}")
            return None

class DataLoader:
    """Main MRST simulation data loader"""
    
    def __init__(self, base_data_path: str = "../data"):
        """
        Initialize the data loader.
        
        Args:
            base_data_path: Base path to simulation data
        """
        self.base_path = Path(os.path.dirname(__file__)) / base_data_path
        self.data_cache = {}
        self._available_files = None
        
    def check_data_availability(self) -> bool:
        """
        Check if simulation data is available.
        
        Returns:
            True if data is available, False otherwise
        """
        data_dirs = ['initial', 'static', 'dynamic', 'temporal', 'metadata']
        
        for data_dir in data_dirs:
            dir_path = self.base_path / data_dir
            if dir_path.exists():
                # Search for .mat files in the directory
                mat_files = list(dir_path.glob("*.mat"))
                if mat_files:
                    return True
        
        logger.warning("No simulation data found in any directory")
        return False
    
    def get_available_files(self) -> Dict[str, List[str]]:
        """
        Get list of available files by category.
        
        Returns:
            Dictionary with file lists by category
        """
        if self._available_files is not None:
            return self._available_files
            
        self._available_files = {}
        data_dirs = ['initial', 'static', 'dynamic', 'temporal', 'metadata']
        
        for data_dir in data_dirs:
            dir_path = self.base_path / data_dir
            if dir_path.exists():
                mat_files = [f.name for f in dir_path.glob("*.mat")]
                self._available_files[data_dir] = sorted(mat_files)
            else:
                self._available_files[data_dir] = []
                
        return self._available_files
    
    def load_mat_file(self, category: str, filename: str) -> Optional[Dict]:
        """
        Load a specific .mat file.
        
        Args:
            category: Data category (initial, static, dynamic, temporal, metadata)
            filename: .mat file name
            
        Returns:
            Dictionary with file data or None if error
        """
        file_path = self.base_path / category / filename
        cache_key = f"{category}/{filename}"
        
        # Check cache
        if cache_key in self.data_cache:
            return self.data_cache[cache_key]
        
        try:
            if not file_path.exists():
                logger.error(f"File not found: {file_path}")
                return None
                
            # Load MATLAB file
            data = loadmat(str(file_path))
            
            # Filter internal MATLAB variables (start with __)
            filtered_data = {k: v for k, v in data.items() if not k.startswith('__')}
            
            # Store in cache
            self.data_cache[cache_key] = filtered_data
            
            logger.info(f"File loaded successfully: {cache_key}")
            return filtered_data
            
        except Exception as e:
            logger.error(f"Error loading file {file_path}: {e}")
            return None
    
    def get_temporal_data(self) -> Optional[pd.DataFrame]:
        """
        Load and process temporal simulation data.
        
        Returns:
            DataFrame with temporal data or None if error
        """
        temporal_files = self.get_available_files().get('temporal', [])
        
        if not temporal_files:
            logger.warning("No temporal data files found")
            return None
        
        # Try to load main temporal data file
        main_file = None
        for file in temporal_files:
            if 'temporal' in file.lower() or 'time' in file.lower():
                main_file = file
                break
        
        if not main_file:
            main_file = temporal_files[0]  # Use first available file
        
        data = self.load_mat_file('temporal', main_file)
        if data is None:
            return None
        
        try:
            # Convert temporal data to DataFrame
            df_data = {}
            
            for key, value in data.items():
                if isinstance(value, np.ndarray):
                    # Flatten multidimensional arrays if necessary
                    if value.ndim > 1:
                        if value.shape[0] == 1 or value.shape[1] == 1:
                            value = value.flatten()
                        else:
                            # For 2D arrays, use only first column or average
                            value = np.mean(value, axis=1) if value.shape[1] > 1 else value[:, 0]
                    
                    df_data[key] = value
            
            df = pd.DataFrame(df_data)
            logger.info(f"Temporal data loaded: {df.shape[0]} timesteps, {df.shape[1]} variables")
            
            return df
            
        except Exception as e:
            logger.error(f"Error processing temporal data: {e}")
            return None
    
    def get_spatial_data(self, timestep: Optional[int] = None) -> Optional[Dict]:
        """
        Load spatial data for a specific timestep.
        
        Args:
            timestep: Specific timestep (None for latest available)
            
        Returns:
            Dictionary with spatial data or None if error
        """
        dynamic_files = self.get_available_files().get('dynamic', [])
        
        if not dynamic_files:
            logger.warning("No dynamic data files found")
            return None
        
        # If no timestep specified, use last file
        if timestep is None:
            # Sort files by name (assuming sequential numbering)
            sorted_files = sorted(dynamic_files)
            target_file = sorted_files[-1]
        else:
            # Search for file corresponding to timestep
            target_file = None
            for file in dynamic_files:
                if f"{timestep:03d}" in file or f"_{timestep}_" in file:
                    target_file = file
                    break
            
            if not target_file:
                logger.warning(f"No file found for timestep {timestep}")
                return None
        
        data = self.load_mat_file('dynamic', target_file)
        return data
    
    def get_static_data(self) -> Optional[Dict]:
        """
        Load static reservoir data.
        
        Returns:
            Dictionary with static data or None if error
        """
        static_files = self.get_available_files().get('static', [])
        
        if not static_files:
            logger.warning("No static data files found")
            return None
        
        # Load first available static file
        main_file = static_files[0]
        data = self.load_mat_file('static', main_file)
        
        return data
    
    def get_initial_data(self) -> Optional[Dict]:
        """
        Load initial reservoir data.
        
        Returns:
            Dictionary with initial data or None if error
        """
        initial_files = self.get_available_files().get('initial', [])
        
        if not initial_files:
            logger.warning("No initial data files found")
            return None
        
        # Load first available initial file
        main_file = initial_files[0]
        data = self.load_mat_file('initial', main_file)
        
        return data
    
    def get_metadata(self) -> Optional[Dict]:
        """
        Load simulation metadata.
        
        Returns:
            Dictionary with metadata or None if error
        """
        metadata_files = self.get_available_files().get('metadata', [])
        
        if not metadata_files:
            logger.warning("No metadata files found")
            return None
        
        # Load first available metadata file
        main_file = metadata_files[0]
        data = self.load_mat_file('metadata', main_file)
        
        return data
    
    def get_grid_dimensions(self) -> Tuple[int, int, int]:
        """
        Get simulation grid dimensions.
        
        Returns:
            Tuple (nx, ny, nz) with grid dimensions
        """
        # Try to get dimensions from static data
        static_data = self.get_static_data()
        if static_data:
            for key, value in static_data.items():
                if isinstance(value, np.ndarray) and value.ndim >= 2:
                    if value.ndim == 2:
                        return value.shape[0], value.shape[1], 1
                    elif value.ndim == 3:
                        return value.shape[0], value.shape[1], value.shape[2]
        
        # Fallback: use configuration
        config_loader = ConfigLoader()
        config = config_loader.load_config()
        if config and 'grid' in config:
            grid_config = config['grid']
            return grid_config.get('nx', 20), grid_config.get('ny', 20), grid_config.get('nz', 10)
        
        # Default dimensions
        return 20, 20, 10
    
    def clear_cache(self):
        """Clear loaded data cache"""
        self.data_cache.clear()
        self._available_files = None
        logger.info("Data cache cleared")
    
    def get_cache_info(self) -> Dict:
        """
        Get information about current cache.
        
        Returns:
            Dictionary with cache statistics
        """
        total_size = 0
        file_count = len(self.data_cache)
        
        for key, data in self.data_cache.items():
            if isinstance(data, dict):
                for k, v in data.items():
                    if isinstance(v, np.ndarray):
                        total_size += v.nbytes
        
        return {
            'cached_files': file_count,
            'total_size_mb': total_size / (1024 * 1024),
            'cached_keys': list(self.data_cache.keys())
        }