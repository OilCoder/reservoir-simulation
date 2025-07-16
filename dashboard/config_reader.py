"""
Configuration Reader for Reservoir Simulation Parameters

This module reads and parses the reservoir_config.yaml file to extract 
simulation parameters for display in the dashboard.
"""

import yaml
import os
from typing import Dict, Any, Optional
from pathlib import Path

def load_simulation_config(config_path: Optional[str] = None) -> Dict[str, Any]:
    """
    Load the reservoir simulation configuration from YAML file.
    
    Args:
        config_path: Path to the configuration file (optional)
        
    Returns:
        Dict containing all simulation parameters
    """
    if config_path is None:
        # Default path relative to dashboard directory
        config_path = Path(__file__).parent.parent / "config" / "reservoir_config.yaml"
    
    if not os.path.exists(config_path):
        raise FileNotFoundError(f"Configuration file not found: {config_path}")
    
    with open(config_path, 'r') as file:
        config = yaml.safe_load(file)
    
    return config

def get_grid_parameters(config: Dict[str, Any]) -> Dict[str, Any]:
    """Extract grid parameters from configuration."""
    grid = config.get('grid', {})
    return {
        'nx': grid.get('nx', 20),
        'ny': grid.get('ny', 20),
        'nz': grid.get('nz', 1),
        'dx': grid.get('dx', 164.0),
        'dy': grid.get('dy', 164.0),
        'dz': grid.get('dz', 33.0),
        'total_cells': grid.get('nx', 20) * grid.get('ny', 20) * grid.get('nz', 1),
        'total_area': grid.get('nx', 20) * grid.get('dx', 164.0) * grid.get('ny', 20) * grid.get('dy', 164.0),
        'total_volume': grid.get('nx', 20) * grid.get('dx', 164.0) * grid.get('ny', 20) * grid.get('dy', 164.0) * grid.get('dz', 33.0)
    }

def get_rock_parameters(config: Dict[str, Any]) -> Dict[str, Any]:
    """Extract rock parameters from configuration."""
    rock = config.get('rock', {})
    porosity = config.get('porosity', {})
    permeability = config.get('permeability', {})
    
    return {
        'porosity': porosity,
        'permeability': permeability,
        'rock_regions': rock.get('regions', []),
        'n_regions': rock.get('n_regions', 3),
        'reference_pressure': rock.get('reference_pressure', 2900.0),
        'compaction_coefficients': rock.get('compaction_coefficients', {}),
        'permeability_exponents': rock.get('permeability_exponents', {})
    }

def get_fluid_parameters(config: Dict[str, Any]) -> Dict[str, Any]:
    """Extract fluid parameters from configuration."""
    fluid = config.get('fluid', {})
    return {
        'oil': fluid.get('oil', {}),
        'water': fluid.get('water', {}),
        'relative_permeability': fluid.get('relative_permeability', {}),
        'oil_density': fluid.get('oil_density', 850.0),
        'water_density': fluid.get('water_density', 1000.0),
        'oil_viscosity': fluid.get('oil_viscosity', 2.0),
        'water_viscosity': fluid.get('water_viscosity', 0.5),
        'connate_water_saturation': fluid.get('connate_water_saturation', 0.15),
        'residual_oil_saturation': fluid.get('residual_oil_saturation', 0.20)
    }

def get_well_parameters(config: Dict[str, Any]) -> Dict[str, Any]:
    """Extract well parameters from configuration."""
    wells = config.get('wells', {})
    grid = config.get('grid', {})
    dx = grid.get('dx', 164.0)
    dy = grid.get('dy', 164.0)
    
    # Process wells data
    processed_wells = {
        'producers': [],
        'injectors': [],
        'names': [],
        'x_coords': [],
        'y_coords': [],
        'types': []
    }
    
    # Process producers
    for prod in wells.get('producers', []):
        processed_wells['producers'].append(prod)
        processed_wells['names'].append(prod.get('name', 'PROD'))
        # Convert grid coordinates to physical coordinates
        i, j = prod.get('location', [15, 10])
        x_coord = (i - 0.5) * dx  # Cell center
        y_coord = (j - 0.5) * dy  # Cell center
        processed_wells['x_coords'].append(x_coord)
        processed_wells['y_coords'].append(y_coord)
        processed_wells['types'].append('producer')
    
    # Process injectors
    for inj in wells.get('injectors', []):
        processed_wells['injectors'].append(inj)
        processed_wells['names'].append(inj.get('name', 'INJ'))
        # Convert grid coordinates to physical coordinates
        i, j = inj.get('location', [5, 10])
        x_coord = (i - 0.5) * dx  # Cell center
        y_coord = (j - 0.5) * dy  # Cell center
        processed_wells['x_coords'].append(x_coord)
        processed_wells['y_coords'].append(y_coord)
        processed_wells['types'].append('injector')
    
    return processed_wells

def get_simulation_parameters(config: Dict[str, Any]) -> Dict[str, Any]:
    """Extract simulation parameters from configuration."""
    simulation = config.get('simulation', {})
    return {
        'total_time': simulation.get('total_time', 365.0),
        'num_timesteps': simulation.get('num_timesteps', 50),
        'timestep_type': simulation.get('timestep_type', 'linear'),
        'timestep_multiplier': simulation.get('timestep_multiplier', 1.1),
        'solver': simulation.get('solver', {}),
        'tolerance': simulation.get('solver', {}).get('tolerance', 1.0e-6),
        'max_iterations': simulation.get('solver', {}).get('max_iterations', 25),
        'linear_solver': simulation.get('solver', {}).get('linear_solver', 'direct')
    }

def get_initial_conditions(config: Dict[str, Any]) -> Dict[str, Any]:
    """Extract initial conditions from configuration."""
    initial = config.get('initial_conditions', {})
    return {
        'pressure': initial.get('pressure', 2900.0),
        'water_saturation': initial.get('water_saturation', 0.20),
        'temperature': initial.get('temperature', 176.0)
    }

def get_geomechanics_parameters(config: Dict[str, Any]) -> Dict[str, Any]:
    """Extract geomechanics parameters from configuration."""
    geomech = config.get('geomechanics', {})
    return {
        'enabled': geomech.get('enabled', True),
        'plasticity': geomech.get('plasticity', False),
        'stress': geomech.get('stress', {}),
        'mechanical': geomech.get('mechanical', {})
    }

def get_metadata(config: Dict[str, Any]) -> Dict[str, Any]:
    """Extract metadata from configuration."""
    metadata = config.get('metadata', {})
    return {
        'project_name': metadata.get('project_name', 'MRST Simulation'),
        'description': metadata.get('description', 'Reservoir simulation project'),
        'author': metadata.get('author', 'Simulation Team'),
        'version': metadata.get('version', '1.0'),
        'created_date': metadata.get('created_date', '2025-01-15'),
        'last_modified': metadata.get('last_modified', '2025-01-15'),
        'units': metadata.get('units', {}),
        'conversion_factors': metadata.get('conversion_factors', {})
    }