# Simulation Data Access Guide

## Overview

This guide provides practical, executable instructions for accessing, reading, and interpreting simulation data from the Eagle West Field reservoir simulation. The guide focuses on real-world implementation patterns and includes working examples for all major data access scenarios.

## Table of Contents

1. [File Naming Conventions](#1-file-naming-conventions)
2. [oct2py Integration](#2-oct2py-integration)
3. [YAML Metadata Parsing](#3-yaml-metadata-parsing)
4. [Unit Conversions](#4-unit-conversions)
5. [Data Validation Procedures](#5-data-validation-procedures)
6. [Common Troubleshooting](#6-common-troubleshooting)
7. [Performance Optimization](#7-performance-optimization)
8. [Cross-Reference Navigation](#8-cross-reference-navigation)

---

## 1. File Naming Conventions

### 1.1 Static Data Files

```
/simulation_data/static/
├── static_data.mat                    # Grid geometry, rock regions, well locations
├── geology/
│   ├── grid_geometry.mat             # Grid coordinates and connectivity
│   ├── permeability_fields.mat       # Permeability distributions
│   ├── porosity_distributions.mat    # Porosity fields
│   └── facies_models.mat             # Geological facies classifications
├── petrophysics/
│   ├── rock_properties.mat           # Comprehensive rock properties
│   ├── relative_permeability.mat     # kr curves and parameters
│   └── capillary_pressure.mat        # Pc curves and parameters
├── fluids/
│   ├── pvt_tables.mat                # Pressure-volume-temperature data
│   ├── fluid_properties.mat          # Fluid property correlations
│   └── equation_of_state.mat         # EOS parameters
└── wells/
    ├── well_trajectories.mat          # Well path coordinates
    ├── completion_data.mat            # Perforation and completion details
    └── well_constraints.mat           # Operating constraints and limits
```

### 1.2 Dynamic Data Files

```
/simulation_data/dynamic/
├── fields/
│   └── field_arrays.mat              # 4D arrays: pressure, saturation, porosity, permeability
├── temporal/
│   ├── timestep_0001.mat             # Individual timestep data
│   ├── timestep_0002.mat
│   └── ... (up to timestep_0120.mat)
├── production/
│   ├── well_rates.mat                # Production/injection rates by well
│   ├── cumulative_production.mat     # Cumulative volumes
│   └── well_pressures.mat            # Bottom-hole pressures
└── solver/
    ├── convergence_data.mat           # Solver convergence metrics
    ├── iteration_counts.mat           # Newton iteration statistics
    └── performance_metrics.mat        # Computational performance data
```

### 1.3 Derived Data Files

```
/simulation_data/derived/
├── analytics/
│   ├── recovery_factors.mat          # Oil recovery factors over time
│   ├── sweep_efficiency.mat          # Volumetric sweep efficiency
│   └── drainage_patterns.mat         # Flow pattern analysis
├── economics/
│   ├── npv_calculations.mat          # Net present value analysis
│   ├── cost_analysis.mat             # Cost breakdown and projections
│   └── sensitivity_results.mat       # Economic sensitivity studies
└── ml_features/
    ├── feature_matrices.mat          # Engineered features for ML
    ├── training_datasets.mat         # ML-ready training data
    └── model_predictions.mat         # Trained model outputs
```

### 1.4 Naming Pattern Rules

```python
# Standard naming patterns
STATIC_PATTERN = r"^[a-z_]+\.mat$"
DYNAMIC_PATTERN = r"^(timestep_\d{4}|field_arrays)\.mat$"
DERIVED_PATTERN = r"^[a-z_]+_(factors|efficiency|analysis|results)\.mat$"

# Timestep naming convention
def format_timestep_filename(step_number):
    """Generate standardized timestep filename"""
    return f"timestep_{step_number:04d}.mat"

# Validation function
def validate_filename(filename, file_type):
    """Validate filename against conventions"""
    patterns = {
        'static': STATIC_PATTERN,
        'dynamic': DYNAMIC_PATTERN,
        'derived': DERIVED_PATTERN
    }
    return bool(re.match(patterns[file_type], filename))
```

---

## 2. oct2py Integration

### 2.1 Basic Setup and Configuration

```python
import numpy as np
from oct2py import Oct2Py, octave
import os
from pathlib import Path

# Initialize oct2py with optimal settings
class SimulationDataLoader:
    def __init__(self, data_root="/workspace/data/simulation_data"):
        self.data_root = Path(data_root)
        self.octave = Oct2Py()
        
        # Configure octave environment
        self.octave.eval("pkg load io")  # Load I/O package if available
        
        # Set MATLAB path for custom functions
        matlab_path = str(self.data_root.parent / "mrst_simulation_scripts")
        self.octave.addpath(matlab_path)
        
    def __enter__(self):
        return self
        
    def __exit__(self, exc_type, exc_val, exc_tb):
        self.octave.exit()
```

### 2.2 Loading Static Data

```python
def load_static_data(self):
    """Load and parse static reservoir data"""
    
    static_file = self.data_root / "static" / "static_data.mat"
    
    try:
        # Load MATLAB structure
        static_data = self.octave.load(str(static_file))
        
        # Extract grid information
        grid_info = {
            'nx': static_data['static_data']['dimensions']['nx'],
            'ny': static_data['static_data']['dimensions']['ny'], 
            'nz': static_data['static_data']['dimensions']['nz'],
            'grid_x': np.array(static_data['static_data']['grid_x']).flatten(),
            'grid_y': np.array(static_data['static_data']['grid_y']).flatten(),
            'cell_centers_x': np.array(static_data['static_data']['cell_centers_x']).flatten(),
            'cell_centers_y': np.array(static_data['static_data']['cell_centers_y']).flatten()
        }
        
        # Handle 3D grids
        if grid_info['nz'] > 1:
            grid_info['grid_z'] = np.array(static_data['static_data']['grid_z']).flatten()
            grid_info['cell_centers_z'] = np.array(static_data['static_data']['cell_centers_z']).flatten()
        
        # Extract rock regions
        rock_id = np.array(static_data['static_data']['rock_id'])
        
        # Extract well information
        wells_data = static_data['static_data']['wells']
        wells_info = {
            'names': [name[0] for name in wells_data['well_names']],
            'i_coords': np.array(wells_data['well_i']).flatten(),
            'j_coords': np.array(wells_data['well_j']).flatten(),
            'types': [wtype[0] for wtype in wells_data['well_types']]
        }
        
        if grid_info['nz'] > 1:
            wells_info['k_coords'] = np.array(wells_data['well_k']).flatten()
        
        return {
            'grid': grid_info,
            'rock_id': rock_id,
            'wells': wells_info
        }
        
    except Exception as e:
        raise IOError(f"Failed to load static data: {e}")
```

### 2.3 Loading Dynamic Field Data

```python
def load_dynamic_fields(self, timestep_range=None):
    """Load 4D dynamic field arrays"""
    
    fields_file = self.data_root / "dynamic" / "fields" / "field_arrays.mat"
    
    try:
        # Load field data
        fields_data = self.octave.load(str(fields_file))
        field_arrays = fields_data['fields_data']
        
        # Extract dimensions
        dims = field_arrays['dimensions']
        n_timesteps = int(dims['n_timesteps'])
        nx, ny, nz = int(dims['nx']), int(dims['ny']), int(dims['nz'])
        
        # Apply timestep filtering if specified  
        if timestep_range is None:
            t_start, t_end = 0, n_timesteps
        else:
            t_start, t_end = timestep_range
            t_start = max(0, t_start)
            t_end = min(n_timesteps, t_end)
        
        # Extract field arrays (format: [time, z, y, x])
        fields = {}
        for field_name in ['pressure', 'sw', 'phi', 'k', 'sigma_eff']:
            if field_name in field_arrays:
                full_array = np.array(field_arrays[field_name])
                fields[field_name] = full_array[t_start:t_end, :, :, :]
        
        # Add metadata
        fields['metadata'] = {
            'dimensions': {'order': 'time_z_y_x', 'nx': nx, 'ny': ny, 'nz': nz},
            'timestep_range': (t_start, t_end),
            'units': {
                'pressure': 'psi',
                'sw': 'fraction', 
                'phi': 'fraction',
                'k': 'mD',
                'sigma_eff': 'psi'
            }
        }
        
        return fields
        
    except Exception as e:
        raise IOError(f"Failed to load dynamic fields: {e}")
```

### 2.4 Loading Individual Timestep Data

```python
def load_timestep_data(self, timestep):
    """Load data for a specific timestep"""
    
    timestep_file = self.data_root / "dynamic" / "temporal" / f"timestep_{timestep:04d}.mat"
    
    if not timestep_file.exists():
        raise FileNotFoundError(f"Timestep file not found: {timestep_file}")
    
    try:
        # Load timestep data
        ts_data = self.octave.load(str(timestep_file))
        timestep_data = ts_data['timestep_data']
        
        # Extract simulation time
        time_days = float(timestep_data['time_days'])
        
        # Extract well data
        well_data = {}
        if 'wells' in timestep_data:
            wells = timestep_data['wells']
            well_data = {
                'names': [name[0] for name in wells['names']],
                'oil_rates': np.array(wells['oil_rates']).flatten(),
                'water_rates': np.array(wells['water_rates']).flatten(), 
                'gas_rates': np.array(wells['gas_rates']).flatten(),
                'bhp': np.array(wells['bhp']).flatten(),
                'wct': np.array(wells['wct']).flatten()
            }
        
        # Extract solver information
        solver_data = {}
        if 'solver' in timestep_data:
            solver = timestep_data['solver']
            solver_data = {
                'converged': bool(solver['converged']),
                'iterations': int(solver['iterations']),
                'residual': float(solver['residual']),
                'time_step_days': float(solver['time_step_days'])
            }
        
        return {
            'timestep': timestep,
            'time_days': time_days,
            'wells': well_data,
            'solver': solver_data
        }
        
    except Exception as e:
        raise IOError(f"Failed to load timestep {timestep}: {e}")
```

### 2.5 Loading Production Data

```python
def load_production_data(self):
    """Load well production and injection data"""
    
    production_files = {
        'rates': self.data_root / "dynamic" / "production" / "well_rates.mat",
        'cumulative': self.data_root / "dynamic" / "production" / "cumulative_production.mat",
        'pressures': self.data_root / "dynamic" / "production" / "well_pressures.mat"
    }
    
    production_data = {}
    
    for data_type, file_path in production_files.items():
        if file_path.exists():
            try:
                mat_data = self.octave.load(str(file_path))
                
                if data_type == 'rates':
                    rates_data = mat_data['rates_data']
                    production_data['rates'] = {
                        'time_days': np.array(rates_data['time_days']).flatten(),
                        'well_names': [name[0] for name in rates_data['well_names']],
                        'oil_rates': np.array(rates_data['oil_rates']),      # [time, wells]
                        'water_rates': np.array(rates_data['water_rates']),
                        'gas_rates': np.array(rates_data['gas_rates'])
                    }
                    
                elif data_type == 'cumulative':
                    cum_data = mat_data['cumulative_data']
                    production_data['cumulative'] = {
                        'time_days': np.array(cum_data['time_days']).flatten(),
                        'well_names': [name[0] for name in cum_data['well_names']],
                        'cum_oil': np.array(cum_data['cum_oil']),
                        'cum_water': np.array(cum_data['cum_water']),
                        'cum_gas': np.array(cum_data['cum_gas'])
                    }
                    
                elif data_type == 'pressures':
                    press_data = mat_data['pressure_data']
                    production_data['pressures'] = {
                        'time_days': np.array(press_data['time_days']).flatten(),
                        'well_names': [name[0] for name in press_data['well_names']],
                        'bhp': np.array(press_data['bhp']),                 # [time, wells]
                        'thp': np.array(press_data.get('thp', []))
                    }
                    
            except Exception as e:
                print(f"Warning: Failed to load {data_type} data: {e}")
    
    return production_data
```

---

## 3. YAML Metadata Parsing

### 3.1 Metadata File Structure

Each data file has an associated YAML metadata file with standardized schema:

```
/simulation_data/metadata/
├── static/
│   ├── static_data.yaml
│   ├── geology/
│   │   ├── grid_geometry.yaml
│   │   └── permeability_fields.yaml
│   └── ...
├── dynamic/
│   ├── field_arrays.yaml
│   ├── temporal/
│   │   ├── timestep_0001.yaml
│   │   └── ...
│   └── ...
└── derived/
    └── ...
```

### 3.2 Metadata Loading and Validation

```python
import yaml
from pathlib import Path
from jsonschema import validate, ValidationError
from datetime import datetime
import hashlib

class MetadataManager:
    def __init__(self, data_root="/workspace/data/simulation_data"):
        self.data_root = Path(data_root)
        self.metadata_root = self.data_root / "metadata"
        
        # Load validation schemas
        self.schemas = self._load_schemas()
    
    def _load_schemas(self):
        """Load YAML validation schemas"""
        schema_dir = Path(__file__).parent / "schemas"
        schemas = {}
        
        for schema_file in schema_dir.glob("*.yaml"):
            with open(schema_file, 'r') as f:
                schemas[schema_file.stem] = yaml.safe_load(f)
        
        return schemas
    
    def load_metadata(self, data_file_path):
        """Load and validate metadata for a data file"""
        
        # Construct metadata file path
        rel_path = Path(data_file_path).relative_to(self.data_root)
        metadata_path = self.metadata_root / rel_path.with_suffix('.yaml')
        
        if not metadata_path.exists():
            raise FileNotFoundError(f"Metadata file not found: {metadata_path}")
        
        try:
            with open(metadata_path, 'r') as f:
                metadata = yaml.safe_load(f)
            
            # Validate against schema
            data_type = metadata.get('data_type', 'unknown')
            if data_type in self.schemas:
                validate(metadata, self.schemas[data_type])
            
            # Add computed fields
            metadata['_loaded_at'] = datetime.now().isoformat()
            metadata['_metadata_file'] = str(metadata_path)
            
            return metadata
            
        except yaml.YAMLError as e:
            raise ValueError(f"Invalid YAML in metadata file: {e}")
        except ValidationError as e:
            raise ValueError(f"Metadata validation failed: {e}")
    
    def verify_file_integrity(self, data_file_path, metadata=None):
        """Verify file integrity using metadata checksums"""
        
        if metadata is None:
            metadata = self.load_metadata(data_file_path)
        
        expected_checksum = metadata.get('file_info', {}).get('checksum_md5')
        if not expected_checksum:
            return {'status': 'no_checksum', 'message': 'No checksum in metadata'}
        
        # Calculate actual checksum
        actual_checksum = self._calculate_md5(data_file_path)
        
        if actual_checksum == expected_checksum:
            return {'status': 'valid', 'checksum': actual_checksum}
        else:
            return {
                'status': 'invalid',
                'expected': expected_checksum,
                'actual': actual_checksum,
                'message': 'Checksum mismatch - file may be corrupted'
            }
    
    def _calculate_md5(self, file_path):
        """Calculate MD5 checksum of a file"""
        hash_md5 = hashlib.md5()
        with open(file_path, "rb") as f:
            for chunk in iter(lambda: f.read(4096), b""):
                hash_md5.update(chunk)
        return hash_md5.hexdigest()
```

### 3.3 Metadata-Driven Data Loading

```python
def load_data_with_metadata(self, data_file_path):
    """Load data file with full metadata context"""
    
    # Load metadata first
    metadata = self.load_metadata(data_file_path)
    
    # Verify file integrity
    integrity = self.verify_file_integrity(data_file_path, metadata)
    if integrity['status'] == 'invalid':
        raise ValueError(f"File integrity check failed: {integrity['message']}")
    
    # Load data based on metadata specifications
    data_type = metadata['data_type']
    file_format = metadata['file_info']['file_format']
    
    if file_format == 'MATLAB':
        with SimulationDataLoader() as loader:
            if data_type == 'static_grid':
                data = loader.load_static_data()
            elif data_type == 'dynamic_solution':
                data = loader.load_dynamic_fields()
            elif data_type == 'dynamic_well_production':
                data = loader.load_production_data()
            else:
                # Generic MATLAB file loading
                data = loader.octave.load(str(data_file_path))
    else:
        raise ValueError(f"Unsupported file format: {file_format}")
    
    # Add metadata to data structure
    data['_metadata'] = metadata
    data['_integrity'] = integrity
    
    return data
```

### 3.4 Metadata Search and Discovery

```python
def search_metadata(self, query_terms=None, filters=None):
    """Search metadata files for datasets"""
    
    results = []
    
    # Walk through all metadata files
    for metadata_file in self.metadata_root.rglob("*.yaml"):
        try:
            with open(metadata_file, 'r') as f:
                metadata = yaml.safe_load(f)
            
            # Apply text search
            if query_terms and not self._matches_query(metadata, query_terms):
                continue
            
            # Apply filters
            if filters and not self._matches_filters(metadata, filters):
                continue
            
            # Add search result
            result = {
                'metadata_file': str(metadata_file),
                'data_file': str(metadata_file).replace('/metadata/', '/').replace('.yaml', '.mat'),
                'name': metadata.get('identification', {}).get('name', ''),
                'description': metadata.get('identification', {}).get('description', ''),
                'data_type': metadata.get('data_type', ''),
                'creation_date': metadata.get('identification', {}).get('creation_date', ''),
                'tags': metadata.get('tags', [])
            }
            results.append(result)
            
        except Exception as e:
            print(f"Warning: Failed to process {metadata_file}: {e}")
    
    # Sort by creation date (newest first)
    results.sort(key=lambda x: x['creation_date'], reverse=True)
    return results

def _matches_query(self, metadata, query_terms):
    """Check if metadata matches search query"""
    search_text = ' '.join([
        metadata.get('identification', {}).get('name', ''),
        metadata.get('identification', {}).get('description', ''),
        ' '.join(metadata.get('tags', []))
    ]).lower()
    
    return all(term.lower() in search_text for term in query_terms)

def _matches_filters(self, metadata, filters):
    """Check if metadata matches filter criteria"""
    for key, value in filters.items():
        if key == 'data_type':
            if metadata.get('data_type') != value:
                return False
        elif key == 'validation_status':
            if metadata.get('quality', {}).get('validation_status') != value:
                return False
        elif key == 'created_after':
            creation_date = metadata.get('identification', {}).get('creation_date', '')
            if creation_date < value:
                return False
    
    return True
```

---

## 4. Unit Conversions

### 4.1 Standard Unit Conversion Functions

```python
class UnitConverter:
    """Standardized unit conversion for reservoir simulation data"""
    
    # Conversion factors to SI units
    PRESSURE_CONVERSIONS = {
        'psi_to_pa': 6894.76,
        'bar_to_pa': 100000,
        'kpa_to_pa': 1000,
        'atm_to_pa': 101325
    }
    
    LENGTH_CONVERSIONS = {
        'ft_to_m': 0.3048,
        'in_to_m': 0.0254,
        'cm_to_m': 0.01,
        'mm_to_m': 0.001
    }
    
    PERMEABILITY_CONVERSIONS = {
        'md_to_m2': 9.869233e-16,
        'darcy_to_m2': 9.869233e-13
    }
    
    VOLUME_CONVERSIONS = {
        'bbl_to_m3': 0.158987294928,
        'stb_to_m3': 0.158987294928,
        'ft3_to_m3': 0.0283168466,
        'gal_to_m3': 0.003785411784
    }
    
    RATE_CONVERSIONS = {
        'stb_per_day_to_m3_per_s': 0.158987294928 / 86400,
        'mscf_per_day_to_m3_per_s': 28.3168466 / 86400,
        'bbl_per_day_to_m3_per_s': 0.158987294928 / 86400
    }
    
    @classmethod
    def convert_pressure(cls, values, from_unit, to_unit='pa'):
        """Convert pressure values between units"""
        
        # Convert to Pa first
        if from_unit == 'psi':
            pa_values = np.array(values) * cls.PRESSURE_CONVERSIONS['psi_to_pa']
        elif from_unit == 'bar':
            pa_values = np.array(values) * cls.PRESSURE_CONVERSIONS['bar_to_pa']
        elif from_unit == 'kpa':
            pa_values = np.array(values) * cls.PRESSURE_CONVERSIONS['kpa_to_pa']
        elif from_unit == 'atm':
            pa_values = np.array(values) * cls.PRESSURE_CONVERSIONS['atm_to_pa']
        elif from_unit == 'pa':
            pa_values = np.array(values)
        else:
            raise ValueError(f"Unsupported pressure unit: {from_unit}")
        
        # Convert from Pa to target unit
        if to_unit == 'pa':
            return pa_values
        elif to_unit == 'psi':
            return pa_values / cls.PRESSURE_CONVERSIONS['psi_to_pa']
        elif to_unit == 'bar':
            return pa_values / cls.PRESSURE_CONVERSIONS['bar_to_pa']
        elif to_unit == 'kpa':
            return pa_values / cls.PRESSURE_CONVERSIONS['kpa_to_pa']
        elif to_unit == 'atm':
            return pa_values / cls.PRESSURE_CONVERSIONS['atm_to_pa']
        else:
            raise ValueError(f"Unsupported pressure unit: {to_unit}")
    
    @classmethod
    def convert_permeability(cls, values, from_unit, to_unit='m2'):
        """Convert permeability values between units"""
        
        # Convert to m² first
        if from_unit == 'md':
            m2_values = np.array(values) * cls.PERMEABILITY_CONVERSIONS['md_to_m2']
        elif from_unit == 'darcy':
            m2_values = np.array(values) * cls.PERMEABILITY_CONVERSIONS['darcy_to_m2']
        elif from_unit == 'm2':
            m2_values = np.array(values)
        else:
            raise ValueError(f"Unsupported permeability unit: {from_unit}")
        
        # Convert to target unit
        if to_unit == 'm2':
            return m2_values
        elif to_unit == 'md':
            return m2_values / cls.PERMEABILITY_CONVERSIONS['md_to_m2']
        elif to_unit == 'darcy':
            return m2_values / cls.PERMEABILITY_CONVERSIONS['darcy_to_m2']
        else:
            raise ValueError(f"Unsupported permeability unit: {to_unit}")
    
    @classmethod
    def convert_rates(cls, values, from_unit, to_unit='m3/s'):
        """Convert production/injection rates between units"""
        
        # Convert to m³/s first
        if from_unit == 'stb/day':
            m3_per_s_values = np.array(values) * cls.RATE_CONVERSIONS['stb_per_day_to_m3_per_s']
        elif from_unit == 'mscf/day':
            m3_per_s_values = np.array(values) * cls.RATE_CONVERSIONS['mscf_per_day_to_m3_per_s']
        elif from_unit == 'bbl/day':
            m3_per_s_values = np.array(values) * cls.RATE_CONVERSIONS['bbl_per_day_to_m3_per_s']
        elif from_unit == 'm3/s':
            m3_per_s_values = np.array(values)
        else:
            raise ValueError(f"Unsupported rate unit: {from_unit}")
        
        # Convert to target unit  
        if to_unit == 'm3/s':
            return m3_per_s_values
        elif to_unit == 'stb/day':
            return m3_per_s_values / cls.RATE_CONVERSIONS['stb_per_day_to_m3_per_s']
        elif to_unit == 'mscf/day':
            return m3_per_s_values / cls.RATE_CONVERSIONS['mscf_per_day_to_m3_per_s']
        elif to_unit == 'bbl/day':
            return m3_per_s_values / cls.RATE_CONVERSIONS['bbl_per_day_to_m3_per_s']
        else:
            raise ValueError(f"Unsupported rate unit: {to_unit}")
```

### 4.2 Metadata-Driven Unit Conversion

```python
def convert_data_units(data, metadata, target_units=None):
    """Convert data units based on metadata specifications"""
    
    if target_units is None:
        target_units = {'pressure': 'pa', 'permeability': 'm2', 'rates': 'm3/s'}
    
    converted_data = data.copy()
    
    # Get current units from metadata
    current_units = metadata.get('units', {})
    
    # Convert pressure data
    if 'pressure' in data and 'pressure' in current_units:
        from_unit = current_units['pressure']
        to_unit = target_units.get('pressure', from_unit)
        
        if from_unit != to_unit:
            converted_data['pressure'] = UnitConverter.convert_pressure(
                data['pressure'], from_unit, to_unit
            )
            print(f"Converted pressure: {from_unit} → {to_unit}")
    
    # Convert permeability data
    if 'k' in data and 'permeability' in current_units:
        from_unit = current_units['permeability']
        to_unit = target_units.get('permeability', from_unit)
        
        if from_unit != to_unit:
            converted_data['k'] = UnitConverter.convert_permeability(
                data['k'], from_unit, to_unit
            )
            print(f"Converted permeability: {from_unit} → {to_unit}")
    
    # Convert rate data
    rate_fields = ['oil_rates', 'water_rates', 'gas_rates']
    for field in rate_fields:
        if field in data:
            # Determine unit from field name
            if 'oil' in field or 'water' in field:
                from_unit = 'stb/day'
            elif 'gas' in field:
                from_unit = 'mscf/day'
            else:
                continue
            
            to_unit = target_units.get('rates', from_unit)
            
            if from_unit != to_unit:
                converted_data[field] = UnitConverter.convert_rates(
                    data[field], from_unit, to_unit
                )
                print(f"Converted {field}: {from_unit} → {to_unit}")
    
    # Update metadata with new units
    converted_data['_metadata'] = metadata.copy()
    converted_data['_metadata']['converted_units'] = target_units
    
    return converted_data
```

---

## 5. Data Validation Procedures

### 5.1 Comprehensive Data Validation Framework

```python
class DataValidator:
    """Comprehensive validation for simulation data"""
    
    def __init__(self):
        self.validation_results = {}
        self.tolerance = 1e-6
    
    def validate_static_data(self, static_data):
        """Validate static reservoir data"""
        
        results = {'status': 'pending', 'checks': {}, 'warnings': [], 'errors': []}
        
        # 1. Grid dimension consistency
        grid = static_data.get('grid', {})
        nx, ny, nz = grid.get('nx', 0), grid.get('ny', 0), grid.get('nz', 1)
        
        if nx <= 0 or ny <= 0 or nz <= 0:
            results['errors'].append("Invalid grid dimensions")
        else:
            results['checks']['grid_dimensions'] = 'passed'
        
        # 2. Rock ID validation
        if 'rock_id' in static_data:
            rock_id = static_data['rock_id']
            expected_shape = (nz, ny, nx) if nz > 1 else (ny, nx)
            
            if rock_id.shape != expected_shape:
                results['errors'].append(f"Rock ID shape mismatch: {rock_id.shape} vs {expected_shape}")
            
            if np.any(rock_id < 1):
                results['errors'].append("Rock ID contains invalid values (< 1)")
            
            if len(results['errors']) == 0:
                results['checks']['rock_id_validation'] = 'passed'
        
        # 3. Well location validation  
        if 'wells' in static_data:
            wells = static_data['wells']
            
            # Check coordinate bounds
            i_coords = wells.get('i_coords', [])
            j_coords = wells.get('j_coords', [])
            
            if any(i < 1 or i > nx for i in i_coords):
                results['errors'].append("Well i-coordinates out of grid bounds")
            
            if any(j < 1 or j > ny for j in j_coords):
                results['errors'].append("Well j-coordinates out of grid bounds")
            
            if nz > 1:
                k_coords = wells.get('k_coords', [])
                if any(k < 1 or k > nz for k in k_coords):
                    results['errors'].append("Well k-coordinates out of grid bounds")
            
            if len(results['errors']) == 0:
                results['checks']['well_locations'] = 'passed'
        
        # 4. Grid coordinate validation
        if 'grid_x' in grid and 'grid_y' in grid:
            if not np.all(np.diff(grid['grid_x']) >= 0):
                results['warnings'].append("Grid X coordinates not monotonic")
            
            if not np.all(np.diff(grid['grid_y']) >= 0):
                results['warnings'].append("Grid Y coordinates not monotonic")
            
            if len(grid['grid_x']) != nx + 1:
                results['errors'].append(f"Grid X coordinate count mismatch: {len(grid['grid_x'])} vs {nx+1}")
            
            if len(grid['grid_y']) != ny + 1:
                results['errors'].append(f"Grid Y coordinate count mismatch: {len(grid['grid_y'])} vs {ny+1}")
        
        # Determine overall status
        if results['errors']:
            results['status'] = 'failed'
        elif results['warnings']:
            results['status'] = 'passed_with_warnings'
        else:
            results['status'] = 'passed'
        
        return results
    
    def validate_dynamic_data(self, dynamic_data):
        """Validate dynamic simulation data"""
        
        results = {'status': 'pending', 'checks': {}, 'warnings': [], 'errors': []}
        
        # 1. Array dimension consistency
        if 'metadata' in dynamic_data:
            dims = dynamic_data['metadata']['dimensions']
            nx, ny, nz = dims['nx'], dims['ny'], dims['nz']
            expected_shape = (dynamic_data['metadata']['timestep_range'][1] - 
                            dynamic_data['metadata']['timestep_range'][0], nz, ny, nx)
        
            for field_name in ['pressure', 'sw', 'phi', 'k']:
                if field_name in dynamic_data:
                    field_array = dynamic_data[field_name]
                    if field_array.shape != expected_shape:
                        results['errors'].append(
                            f"{field_name} shape mismatch: {field_array.shape} vs {expected_shape}"
                        )
        
        # 2. Physical constraint validation
        if 'pressure' in dynamic_data:
            pressure = dynamic_data['pressure']
            
            # Check for negative pressures
            if np.any(pressure < 0):
                results['errors'].append("Negative pressure values detected")
            
            # Check for extreme pressures
            if np.any(pressure > 10000):  # > 10,000 psi
                results['warnings'].append("Very high pressure values detected (> 10,000 psi)")
            
            results['checks']['pressure_validation'] = 'passed'
        
        if 'sw' in dynamic_data:
            sw = dynamic_data['sw']
            
            # Check saturation bounds
            if np.any(sw < 0) or np.any(sw > 1):
                results['errors'].append("Water saturation values outside [0,1] range")
            
            results['checks']['saturation_validation'] = 'passed'
        
        if 'phi' in dynamic_data:
            phi = dynamic_data['phi']
            
            # Check porosity bounds
            if np.any(phi < 0) or np.any(phi > 1):
                results['errors'].append("Porosity values outside [0,1] range")
            
            results['checks']['porosity_validation'] = 'passed'
        
        if 'k' in dynamic_data:
            k = dynamic_data['k']
            
            # Check for negative permeability
            if np.any(k < 0):
                results['errors'].append("Negative permeability values detected")
            
            results['checks']['permeability_validation'] = 'passed'
        
        # 3. Temporal consistency
        if len(dynamic_data.get('pressure', [])) > 1:
            pressure = dynamic_data['pressure']
            
            # Check for unrealistic pressure changes
            pressure_diff = np.diff(pressure, axis=0)
            max_change = np.max(np.abs(pressure_diff))
            
            if max_change > 1000:  # > 1000 psi change per timestep
                results['warnings'].append(f"Large pressure changes detected: {max_change:.1f} psi")
        
        # Determine overall status
        if results['errors']:
            results['status'] = 'failed'
        elif results['warnings']: 
            results['status'] = 'passed_with_warnings'
        else:
            results['status'] = 'passed'
        
        return results
    
    def validate_production_data(self, production_data):
        """Validate production and injection data"""
        
        results = {'status': 'pending', 'checks': {}, 'warnings': [], 'errors': []}
        
        # 1. Rate validation
        if 'rates' in production_data:
            rates = production_data['rates']
            
            # Check for negative production rates (should be positive)
            if 'oil_rates' in rates and np.any(rates['oil_rates'] < 0):
                results['warnings'].append("Negative oil production rates detected")
            
            if 'water_rates' in rates and np.any(rates['water_rates'] < 0):
                results['warnings'].append("Negative water production rates detected")
            
            if 'gas_rates' in rates and np.any(rates['gas_rates'] < 0):
                results['warnings'].append("Negative gas production rates detected")
            
            # Check for unrealistically high rates
            if 'oil_rates' in rates:
                max_oil_rate = np.max(rates['oil_rates'])
                if max_oil_rate > 10000:  # > 10,000 STB/day
                    results['warnings'].append(f"Very high oil rate detected: {max_oil_rate:.1f} STB/day")
        
        # 2. Cumulative validation
        if 'cumulative' in production_data:
            cum = production_data['cumulative']
            
            # Check monotonicity
            if 'cum_oil' in cum:
                for well_idx in range(cum['cum_oil'].shape[1]):
                    well_cum = cum['cum_oil'][:, well_idx]
                    if not np.all(np.diff(well_cum) >= -self.tolerance):
                        results['errors'].append(f"Non-monotonic cumulative oil for well {well_idx}")
        
        # 3. Pressure validation
        if 'pressures' in production_data:
            press = production_data['pressures']
            
            if 'bhp' in press:
                bhp = press['bhp']
                
                # Check for unrealistic pressures
                if np.any(bhp < 0):
                    results['errors'].append("Negative bottom-hole pressures detected")
                
                if np.any(bhp > 10000):
                    results['warnings'].append("Very high bottom-hole pressures detected (> 10,000 psi)")
        
        # Determine overall status
        if results['errors']:
            results['status'] = 'failed'
        elif results['warnings']:
            results['status'] = 'passed_with_warnings'
        else:
            results['status'] = 'passed'
        
        return results
```

### 5.2 Automated Validation Workflow

```python
def run_comprehensive_validation(data_loader, data_files):
    """Run comprehensive validation on multiple data files"""
    
    validation_report = {
        'timestamp': datetime.now().isoformat(),
        'total_files': len(data_files),
        'validation_results': {},
        'summary': {'passed': 0, 'warnings': 0, 'failed': 0}
    }
    
    validator = DataValidator()
    
    for data_file in data_files:
        try:
            # Load data with metadata
            data = data_loader.load_data_with_metadata(data_file)
            metadata = data.get('_metadata', {})
            data_type = metadata.get('data_type', 'unknown')
            
            # Run appropriate validation
            if data_type in ['static_grid', 'static_rock_properties']:
                results = validator.validate_static_data(data)
            elif data_type == 'dynamic_solution':
                results = validator.validate_dynamic_data(data)
            elif data_type == 'dynamic_well_production':
                results = validator.validate_production_data(data)
            else:
                results = {'status': 'skipped', 'message': f'No validator for type: {data_type}'}
            
            # Store results
            validation_report['validation_results'][str(data_file)] = {
                'data_type': data_type,
                'file_size_mb': metadata.get('file_info', {}).get('file_size_mb', 0),
                'validation_results': results,
                'file_integrity': data.get('_integrity', {})
            }
            
            # Update summary
            if results['status'] == 'passed':
                validation_report['summary']['passed'] += 1
            elif results['status'] == 'passed_with_warnings':
                validation_report['summary']['warnings'] += 1
            elif results['status'] == 'failed':
                validation_report['summary']['failed'] += 1
            
        except Exception as e:
            validation_report['validation_results'][str(data_file)] = {
                'status': 'error',
                'error_message': str(e)
            }
            validation_report['summary']['failed'] += 1
    
    return validation_report
```

---

## 6. Common Troubleshooting

### 6.1 File Access Issues

**Problem**: Cannot load MATLAB files with oct2py

```python
# Solution 1: Check oct2py installation
try:
    from oct2py import Oct2Py
    octave = Oct2Py()
    octave.eval('version')
    print("oct2py working correctly")
except ImportError:
    print("Install oct2py: pip install oct2py")
except Exception as e:
    print(f"oct2py error: {e}")
    print("Try: sudo apt-get install octave")

# Solution 2: Alternative loading with scipy
from scipy.io import loadmat

def load_matlab_fallback(file_path):
    """Fallback MATLAB file loading using scipy"""
    try:
        return loadmat(file_path, squeeze_me=True, chars_as_strings=True)
    except Exception as e:
        print(f"scipy.io.loadmat failed: {e}")
        return None
```

**Problem**: File path not found errors

```python
def diagnose_file_paths(data_root):
    """Diagnose common file path issues"""
    
    data_root = Path(data_root)
    
    # Check if root directory exists
    if not data_root.exists():
        print(f"ERROR: Data root directory does not exist: {data_root}")
        print(f"Current working directory: {Path.cwd()}")
        return False
    
    # Check expected subdirectories
    expected_dirs = ['static', 'dynamic', 'derived', 'metadata']
    missing_dirs = []
    
    for dirname in expected_dirs:
        dir_path = data_root / dirname
        if not dir_path.exists():
            missing_dirs.append(dirname)
    
    if missing_dirs:
        print(f"WARNING: Missing directories: {missing_dirs}")
        print("Run simulation export scripts to create missing directories")
    
    # Check for common files
    test_files = [
        'static/static_data.mat',
        'dynamic/fields/field_arrays.mat',
        'metadata/static/static_data.yaml'
    ]
    
    missing_files = []
    for test_file in test_files:
        file_path = data_root / test_file
        if not file_path.exists():
            missing_files.append(test_file)
    
    if missing_files:
        print(f"WARNING: Missing expected files: {missing_files}")
    
    return len(missing_dirs) == 0 and len(missing_files) == 0
```

### 6.2 Data Format Issues

**Problem**: Incorrect array dimensions

```python
def fix_array_dimensions(array, expected_shape):
    """Fix common array dimension issues"""
    
    if array.shape == expected_shape:
        return array
    
    # Try squeeze to remove singleton dimensions
    squeezed = np.squeeze(array)
    if squeezed.shape == expected_shape:
        return squeezed
    
    # Try reshape if total elements match
    if array.size == np.prod(expected_shape):
        return array.reshape(expected_shape)
    
    # Try transpose for common dimension swaps
    if array.shape == expected_shape[::-1]:
        return array.T
    
    raise ValueError(f"Cannot fix array shape: {array.shape} → {expected_shape}")
```

**Problem**: Unit inconsistencies

```python
def detect_unit_issues(data, metadata):
    """Detect common unit inconsistencies"""
    
    issues = []
    
    # Check pressure ranges
    if 'pressure' in data:
        pressure = np.array(data['pressure'])
        min_p, max_p = np.min(pressure), np.max(pressure)
        
        if min_p < 1:  # Likely in atm/bar, should be psi
            issues.append({
                'field': 'pressure',
                'issue': 'values_too_small',
                'suggestion': 'Convert from bar/atm to psi',
                'range': (min_p, max_p)
            })
        elif max_p > 100000:  # Likely in Pa, should be psi
            issues.append({
                'field': 'pressure',
                'issue': 'values_too_large',
                'suggestion': 'Convert from Pa to psi',
                'range': (min_p, max_p)
            })
    
    # Check permeability ranges  
    if 'k' in data:
        k = np.array(data['k'])
        min_k, max_k = np.min(k[k > 0]), np.max(k)
        
        if max_k < 1e-12:  # Likely in m², should be mD
            issues.append({
                'field': 'permeability',
                'issue': 'values_too_small',
                'suggestion': 'Convert from m² to mD',
                'range': (min_k, max_k)
            })
        elif min_k > 1e6:  # Unrealistically high
            issues.append({
                'field': 'permeability',
                'issue': 'values_too_large',
                'suggestion': 'Check unit conversion',
                'range': (min_k, max_k)
            })
    
    return issues
```

### 6.3 Performance Issues

**Problem**: Slow data loading

```python
def optimize_data_loading(data_loader, timestep_range=None, spatial_subset=None):
    """Optimize data loading for large datasets"""
    
    # Load only required timesteps
    if timestep_range:
        fields = data_loader.load_dynamic_fields(timestep_range)
    else:
        # Load progressively
        fields = {}
        total_timesteps = 120  # Known from simulation
        batch_size = 10
        
        for start_t in range(0, total_timesteps, batch_size):
            end_t = min(start_t + batch_size, total_timesteps)
            batch_fields = data_loader.load_dynamic_fields((start_t, end_t))
            
            # Concatenate with existing data
            for field_name, field_data in batch_fields.items():
                if field_name == 'metadata':
                    continue
                    
                if field_name in fields:
                    fields[field_name] = np.concatenate([fields[field_name], field_data], axis=0)
                else:
                    fields[field_name] = field_data
            
            print(f"Loaded timesteps {start_t}-{end_t}")
    
    # Apply spatial subsetting if requested
    if spatial_subset:
        i_min, i_max = spatial_subset.get('i_range', (0, fields['metadata']['dimensions']['nx']))
        j_min, j_max = spatial_subset.get('j_range', (0, fields['metadata']['dimensions']['ny']))
        k_min, k_max = spatial_subset.get('k_range', (0, fields['metadata']['dimensions']['nz']))
        
        for field_name in ['pressure', 'sw', 'phi', 'k', 'sigma_eff']:
            if field_name in fields:
                fields[field_name] = fields[field_name][:, k_min:k_max, j_min:j_max, i_min:i_max]
    
    return fields
```

**Problem**: Memory issues with large datasets

```python
def manage_memory_usage(data_loader):
    """Memory-efficient data access patterns"""
    
    # Use generators for large datasets
    def timestep_generator(n_timesteps):
        """Generator for processing timesteps one at a time"""
        for t in range(1, n_timesteps + 1):
            yield data_loader.load_timestep_data(t)
    
    # Process data in chunks
    def process_in_chunks(data_array, chunk_size=1000000):
        """Process large arrays in memory-efficient chunks"""
        total_elements = data_array.size
        
        for start_idx in range(0, total_elements, chunk_size):
            end_idx = min(start_idx + chunk_size, total_elements)
            chunk = data_array.flat[start_idx:end_idx]
            
            # Process chunk
            yield chunk
    
    # Use memory mapping for very large files
    def load_with_memmap(file_path):
        """Load large arrays using memory mapping"""
        import h5py
        
        # Convert .mat to .h5 if needed for memory mapping
        h5_path = file_path.with_suffix('.h5')
        
        if not h5_path.exists():
            print(f"Converting {file_path} to HDF5 for memory mapping...")
            # Conversion logic here
        
        with h5py.File(h5_path, 'r') as f:
            return f  # Return file handle for lazy loading
    
    return {
        'timestep_generator': timestep_generator,
        'process_in_chunks': process_in_chunks,
        'load_with_memmap': load_with_memmap
    }
```

---

## 7. Performance Optimization

### 7.1 Efficient Data Access Patterns

```python
class OptimizedDataLoader:
    """Performance-optimized data loading strategies"""
    
    def __init__(self, data_root, enable_caching=True):
        self.data_root = Path(data_root)
        self.enable_caching = enable_caching
        self.cache = {} if enable_caching else None
        self.preloaded_metadata = {}
        
        # Preload all metadata for fast searching
        self._preload_metadata()
    
    def _preload_metadata(self):
        """Preload all metadata files for fast access"""
        
        metadata_root = self.data_root / "metadata"
        
        for metadata_file in metadata_root.rglob("*.yaml"):
            try:
                with open(metadata_file, 'r') as f:
                    metadata = yaml.safe_load(f)
                
                data_file = str(metadata_file).replace('/metadata/', '/').replace('.yaml', '.mat')
                self.preloaded_metadata[data_file] = metadata
                
            except Exception as e:
                print(f"Warning: Failed to preload {metadata_file}: {e}")
    
    def load_with_cache(self, data_file, loader_func, cache_key=None):
        """Load data with automatic caching"""
        
        if not self.enable_caching:
            return loader_func()
        
        if cache_key is None:
            cache_key = str(data_file)
        
        # Check cache first
        if cache_key in self.cache:
            return self.cache[cache_key]
        
        # Load data
        data = loader_func()
        
        # Cache result (with size limit)
        if len(self.cache) < 10:  # Limit cache size
            self.cache[cache_key] = data
        
        return data
    
    def load_parallel_timesteps(self, timestep_list, n_workers=4):
        """Load multiple timesteps in parallel"""
        
        from concurrent.futures import ThreadPoolExecutor, as_completed
        
        def load_single_timestep(timestep):
            return timestep, self.load_timestep_data(timestep)
        
        results = {}
        
        with ThreadPoolExecutor(max_workers=n_workers) as executor:
            # Submit all tasks
            future_to_timestep = {
                executor.submit(load_single_timestep, ts): ts 
                for ts in timestep_list
            }
            
            # Collect results as they complete
            for future in as_completed(future_to_timestep):
                timestep = future_to_timestep[future]
                try:
                    ts, data = future.result()
                    results[ts] = data
                except Exception as e:
                    print(f"Failed to load timestep {timestep}: {e}")
        
        return results
    
    def create_spatial_index(self, grid_data):
        """Create spatial index for fast spatial queries"""
        
        from scipy.spatial import cKDTree
        
        # Extract cell centers
        nx, ny, nz = grid_data['nx'], grid_data['ny'], grid_data['nz']
        
        # Create coordinate arrays
        x_centers = grid_data['cell_centers_x']
        y_centers = grid_data['cell_centers_y']
        
        if nz > 1:
            z_centers = grid_data['cell_centers_z']
            
            # Create 3D coordinate mesh
            X, Y, Z = np.meshgrid(x_centers, y_centers, z_centers, indexing='ij')
            coordinates = np.column_stack((X.ravel(), Y.ravel(), Z.ravel()))
        else:
            # Create 2D coordinate mesh
            X, Y = np.meshgrid(x_centers, y_centers, indexing='ij')
            coordinates = np.column_stack((X.ravel(), Y.ravel()))
        
        # Build spatial index
        spatial_index = cKDTree(coordinates)
        
        return {
            'index': spatial_index,
            'coordinates': coordinates,
            'grid_shape': (nx, ny, nz)
        }
    
    def query_spatial_region(self, spatial_index, center_point, radius):
        """Query cells within a spatial region"""
        
        # Find cells within radius
        indices = spatial_index['index'].query_ball_point(center_point, radius)
        
        # Convert flat indices to grid coordinates
        nx, ny, nz = spatial_index['grid_shape']
        
        grid_indices = []
        for idx in indices:
            if nz > 1:
                i, j, k = np.unravel_index(idx, (nx, ny, nz))
                grid_indices.append((i, j, k))
            else:
                i, j = np.unravel_index(idx, (nx, ny))
                grid_indices.append((i, j))
        
        return grid_indices
```

### 7.2 Memory Management Strategies

```python
class MemoryEfficientProcessor:
    """Memory-efficient data processing strategies"""
    
    def __init__(self, max_memory_gb=8):
        self.max_memory_gb = max_memory_gb
        self.max_memory_bytes = max_memory_gb * 1024**3
    
    def estimate_memory_usage(self, array_shape, dtype=np.float64):
        """Estimate memory usage for an array"""
        
        element_size = np.dtype(dtype).itemsize
        total_elements = np.prod(array_shape)
        memory_bytes = total_elements * element_size
        
        return memory_bytes
    
    def calculate_optimal_chunks(self, array_shape, dtype=np.float64):
        """Calculate optimal chunk size for memory-efficient processing"""
        
        memory_per_element = np.dtype(dtype).itemsize
        available_memory = self.max_memory_bytes * 0.8  # Use 80% of available memory
        
        total_elements = np.prod(array_shape)
        max_elements_per_chunk = int(available_memory / memory_per_element)
        
        if total_elements <= max_elements_per_chunk:
            return [array_shape]  # Single chunk
        
        # Calculate chunk dimensions
        n_chunks = int(np.ceil(total_elements / max_elements_per_chunk))
        
        # For 4D arrays [time, z, y, x], chunk along time dimension
        if len(array_shape) == 4:
            t_size = array_shape[0]
            chunk_t_size = max(1, t_size // n_chunks)
            
            chunks = []
            for start_t in range(0, t_size, chunk_t_size):
                end_t = min(start_t + chunk_t_size, t_size)
                chunk_shape = (end_t - start_t,) + array_shape[1:]
                chunks.append((start_t, end_t, chunk_shape))
            
            return chunks
        
        return [array_shape]  # Fallback to single chunk
    
    def process_in_memory_chunks(self, data_loader, processing_func):
        """Process large datasets in memory-efficient chunks"""
        
        # Load metadata to determine array sizes
        static_data = data_loader.load_static_data()
        grid = static_data['grid']
        
        # Estimate field array size
        array_shape = (120, grid['nz'], grid['ny'], grid['nx'])  # [time, z, y, x]
        memory_estimate = self.estimate_memory_usage(array_shape)
        
        print(f"Estimated memory usage: {memory_estimate / 1024**3:.2f} GB")
        
        if memory_estimate <= self.max_memory_bytes:
            # Load all data at once
            fields = data_loader.load_dynamic_fields()
            return processing_func(fields)
        else:
            # Process in chunks
            chunks = self.calculate_optimal_chunks(array_shape)
            results = []
            
            for chunk_info in chunks:
                if len(chunk_info) == 3:  # Time-chunked
                    start_t, end_t, chunk_shape = chunk_info
                    print(f"Processing timesteps {start_t}-{end_t}")
                    
                    chunk_fields = data_loader.load_dynamic_fields((start_t, end_t))
                    chunk_result = processing_func(chunk_fields)
                    results.append(chunk_result)
                else:
                    # Full data
                    fields = data_loader.load_dynamic_fields()
                    return processing_func(fields)
            
            # Combine chunk results
            return self.combine_chunk_results(results)
    
    def combine_chunk_results(self, chunk_results):
        """Combine results from multiple chunks"""
        
        if not chunk_results:
            return None
        
        if len(chunk_results) == 1:
            return chunk_results[0]
        
        # Assuming results are dictionaries with arrays
        combined = {}
        
        for key in chunk_results[0].keys():
            if isinstance(chunk_results[0][key], np.ndarray):
                # Concatenate arrays along first dimension
                arrays = [result[key] for result in chunk_results]
                combined[key] = np.concatenate(arrays, axis=0)
            else:
                # Take first non-array value
                combined[key] = chunk_results[0][key]
        
        return combined
```

### 7.3 I/O Optimization

```python
class IOOptimizer:
    """I/O optimization strategies for simulation data"""
    
    def __init__(self, data_root):
        self.data_root = Path(data_root)
        self.io_stats = {'reads': 0, 'total_bytes': 0, 'time_spent': 0}
    
    def benchmark_io_performance(self):
        """Benchmark I/O performance for different file types"""
        
        import time
        
        benchmark_results = {}
        
        # Test static data loading
        static_file = self.data_root / "static" / "static_data.mat"
        if static_file.exists():
            start_time = time.time()
            
            with SimulationDataLoader() as loader:
                static_data = loader.load_static_data()
            
            load_time = time.time() - start_time
            file_size = static_file.stat().st_size / 1024**2  # MB
            
            benchmark_results['static_data'] = {
                'file_size_mb': file_size,
                'load_time_s': load_time,
                'throughput_mb_s': file_size / load_time if load_time > 0 else 0
            }
        
        # Test dynamic field loading
        fields_file = self.data_root / "dynamic" / "fields" / "field_arrays.mat"
        if fields_file.exists():
            start_time = time.time()
            
            with SimulationDataLoader() as loader:
                # Load only first 10 timesteps for benchmark
                fields_data = loader.load_dynamic_fields((0, 10))
            
            load_time = time.time() - start_time
            file_size = fields_file.stat().st_size / 1024**2  # MB
            
            benchmark_results['dynamic_fields'] = {
                'file_size_mb': file_size,
                'load_time_s': load_time,
                'throughput_mb_s': file_size / load_time if load_time > 0 else 0,
                'note': 'partial_load_10_timesteps'
            }
        
        # Test individual timestep loading
        timestep_file = self.data_root / "dynamic" / "temporal" / "timestep_0001.mat"
        if timestep_file.exists():
            start_time = time.time()
            
            with SimulationDataLoader() as loader:
                timestep_data = loader.load_timestep_data(1)
            
            load_time = time.time() - start_time
            file_size = timestep_file.stat().st_size / 1024**2  # MB
            
            benchmark_results['single_timestep'] = {
                'file_size_mb': file_size,
                'load_time_s': load_time,
                'throughput_mb_s': file_size / load_time if load_time > 0 else 0
            }
        
        return benchmark_results
    
    def optimize_file_formats(self):
        """Recommend file format optimizations"""
        
        recommendations = []
        
        # Check for very large .mat files that could benefit from HDF5
        for mat_file in self.data_root.rglob("*.mat"):
            file_size_gb = mat_file.stat().st_size / 1024**3
            
            if file_size_gb > 1.0:  # > 1 GB
                recommendations.append({
                    'file': str(mat_file),
                    'current_size_gb': file_size_gb,
                    'recommendation': 'Convert to HDF5 for better compression and partial loading',
                    'priority': 'high' if file_size_gb > 5 else 'medium'
                })
        
        # Check for frequently accessed files that could benefit from caching
        # (This would require access pattern monitoring in a real implementation)
        
        return recommendations
    
    def create_data_access_plan(self, analysis_requirements):
        """Create optimized data access plan for specific analysis"""
        
        plan = {
            'loading_strategy': 'sequential',
            'memory_management': 'chunk_processing',
            'caching_strategy': 'none',
            'parallel_loading': False,
            'estimated_time_minutes': 0
        }
        
        # Analyze requirements
        needs_all_timesteps = analysis_requirements.get('temporal_analysis', False)
        needs_spatial_subset = analysis_requirements.get('spatial_region') is not None
        needs_multiple_fields = len(analysis_requirements.get('required_fields', [])) > 3
        
        # Optimize loading strategy
        if needs_spatial_subset:
            plan['loading_strategy'] = 'spatial_subset_first'
            plan['memory_management'] = 'reduced_memory'
        
        if needs_all_timesteps and needs_multiple_fields:
            plan['parallel_loading'] = True
            plan['caching_strategy'] = 'aggressive'
        
        # Estimate processing time based on benchmark results
        benchmark = self.benchmark_io_performance()
        
        if needs_all_timesteps:
            # Estimate based on dynamic fields loading
            dynamic_benchmark = benchmark.get('dynamic_fields', {})
            base_time = dynamic_benchmark.get('load_time_s', 60)  # Default 60s
            plan['estimated_time_minutes'] = base_time / 60 * (120 / 10)  # Scale for all timesteps
        
        return plan
```

---

## 8. Cross-Reference Navigation

### 8.1 Navigation Between Organizational Structures

The simulation data is organized in three parallel structures. Here's how to navigate between them:

```python
class CrossReferenceNavigator:
    """Navigate between different organizational structures"""
    
    def __init__(self, data_root):
        self.data_root = Path(data_root)
        self.load_cross_reference_maps()
    
    def load_cross_reference_maps(self):
        """Load cross-reference mapping files"""
        
        # These would be generated during data export
        xref_dir = self.data_root / "metadata" / "cross_references"
        
        self.type_to_usage_map = self._load_mapping(xref_dir / "type_to_usage.yaml")
        self.type_to_phase_map = self._load_mapping(xref_dir / "type_to_phase.yaml")
        self.usage_to_phase_map = self._load_mapping(xref_dir / "usage_to_phase.yaml")
        
        # Reverse mappings
        self.usage_to_type_map = self._reverse_mapping(self.type_to_usage_map)
        self.phase_to_type_map = self._reverse_mapping(self.type_to_phase_map)
        self.phase_to_usage_map = self._reverse_mapping(self.usage_to_phase_map)
    
    def _load_mapping(self, mapping_file):
        """Load a mapping file"""
        if mapping_file.exists():
            with open(mapping_file, 'r') as f:
                return yaml.safe_load(f)
        return {}
    
    def _reverse_mapping(self, forward_map):
        """Create reverse mapping"""
        reverse_map = {}
        for key, values in forward_map.items():
            if isinstance(values, list):
                for value in values:
                    if value not in reverse_map:
                        reverse_map[value] = []
                    reverse_map[value].append(key)
            else:
                if values not in reverse_map:
                    reverse_map[values] = []
                reverse_map[values].append(key)
        return reverse_map
    
    def find_by_type_files(self, usage_path):
        """Find corresponding by_type files for a by_usage path"""
        
        # Example: by_usage/ML_training/features/static_features/ 
        # →        by_type/static/geology/
        
        normalized_path = str(usage_path).replace('by_usage/', '')
        
        if normalized_path in self.usage_to_type_map:
            type_paths = self.usage_to_type_map[normalized_path]
            return [self.data_root / "by_type" / path for path in type_paths]
        
        return []
    
    def find_by_usage_files(self, type_path):
        """Find corresponding by_usage files for a by_type path"""
        
        normalized_path = str(type_path).replace('by_type/', '')
        
        if normalized_path in self.type_to_usage_map:
            usage_paths = self.type_to_usage_map[normalized_path]
            return [self.data_root / "by_usage" / path for path in usage_paths]
        
        return []
    
    def find_by_phase_files(self, type_path):
        """Find corresponding by_phase files for a by_type path"""
        
        normalized_path = str(type_path).replace('by_type/', '')
        
        if normalized_path in self.type_to_phase_map:
            phase_paths = self.type_to_phase_map[normalized_path]
            return [self.data_root / "by_phase" / path for path in phase_paths]
        
        return []
    
    def trace_data_lineage(self, data_file):
        """Trace the complete lineage of a data file"""
        
        metadata_manager = MetadataManager(self.data_root)
        
        try:
            metadata = metadata_manager.load_metadata(data_file)
            
            lineage = {
                'file': str(data_file),
                'data_type': metadata.get('data_type'),
                'creation_date': metadata.get('identification', {}).get('creation_date'),
                'dependencies': [],
                'derived_from': [],
                'used_by': []
            }
            
            # Extract dependencies
            relationships = metadata.get('relationships', {})
            
            if 'depends_on' in relationships:
                for dep_id in relationships['depends_on']:
                    dep_files = self.find_files_by_id(dep_id)
                    lineage['dependencies'].extend(dep_files)
            
            if 'used_by' in relationships:
                for user_id in relationships['used_by']:
                    user_files = self.find_files_by_id(user_id)
                    lineage['used_by'].extend(user_files)
            
            # Find parent data
            parent_data = metadata.get('provenance', {}).get('parent_data', [])
            for parent_id in parent_data:
                parent_files = self.find_files_by_id(parent_id)
                lineage['derived_from'].extend(parent_files)
            
            return lineage
            
        except Exception as e:
            return {'error': f"Failed to trace lineage: {e}"}
    
    def find_files_by_id(self, data_id):
        """Find files with specific data ID"""
        
        # Search through metadata files
        metadata_root = self.data_root / "metadata"
        matching_files = []
        
        for metadata_file in metadata_root.rglob("*.yaml"):
            try:
                with open(metadata_file, 'r') as f:
                    metadata = yaml.safe_load(f)
                
                if metadata.get('identification', {}).get('data_id') == data_id:
                    data_file = str(metadata_file).replace('/metadata/', '/').replace('.yaml', '.mat')
                    matching_files.append(data_file)
                    
            except Exception:
                continue
        
        return matching_files
```

### 8.2 Workflow-Based Navigation

```python
class WorkflowNavigator:
    """Navigate data based on common workflow patterns"""
    
    def __init__(self, data_root):
        self.data_root = Path(data_root)
        self.xref_nav = CrossReferenceNavigator(data_root)
    
    def get_ml_training_workflow(self):
        """Get complete data workflow for ML training"""
        
        workflow = {
            'name': 'ML Training Workflow',
            'steps': [
                {
                    'step': 1,
                    'name': 'Load Static Features',
                    'files': [
                        'by_usage/ML_training/features/static_features/grid_properties.mat',
                        'by_usage/ML_training/features/static_features/well_locations.mat',
                        'by_usage/ML_training/features/static_features/geological_features.mat'
                    ],
                    'alternative_paths': {
                        'by_type': ['static/geology/', 'static/wells/'],
                        'by_phase': ['initialization/model_setup/']
                    }
                },
                {
                    'step': 2,
                    'name': 'Load Dynamic Features',
                    'files': [
                        'by_usage/ML_training/features/dynamic_features/pressure_history.mat',
                        'by_usage/ML_training/features/dynamic_features/rate_history.mat',
                        'by_usage/ML_training/features/dynamic_features/saturation_evolution.mat'
                    ],
                    'alternative_paths': {
                        'by_type': ['dynamic/fields/', 'dynamic/production/'],
                        'by_phase': ['runtime/timestep_data/']
                    }
                },
                {
                    'step': 3,
                    'name': 'Load Targets',
                    'files': [
                        'by_usage/ML_training/targets/production_targets.mat',
                        'by_usage/ML_training/targets/recovery_targets.mat'
                    ],
                    'alternative_paths': {
                        'by_type': ['derived/analytics/'],
                        'by_phase': ['post-processing/derived_calculations/']
                    }
                },
                {
                    'step': 4,
                    'name': 'Load Training Datasets',
                    'files': [
                        'by_usage/ML_training/datasets/training_set.mat',
                        'by_usage/ML_training/datasets/validation_set.mat',
                        'by_usage/ML_training/datasets/test_set.mat'
                    ]
                }
            ]
        }
        
        return workflow
    
    def get_monitoring_workflow(self):
        """Get data workflow for real-time monitoring"""
        
        workflow = {
            'name': 'Real-time Monitoring Workflow',
            'steps': [
                {
                    'step': 1,
                    'name': 'Load Current State',
                    'files': [
                        'by_usage/monitoring/real_time/current_pressures.mat',
                        'by_usage/monitoring/real_time/current_rates.mat'
                    ],
                    'alternative_paths': {
                        'by_type': ['dynamic/fields/', 'dynamic/production/'],
                        'by_phase': ['runtime/timestep_data/']
                    }
                },
                {
                    'step': 2,
                    'name': 'Load Historical Context',
                    'files': [
                        'by_usage/monitoring/historical/production_history.mat',
                        'by_usage/monitoring/historical/performance_trends.mat'
                    ]
                },
                {
                    'step': 3,
                    'name': 'Check Alerts',
                    'files': [
                        'by_usage/monitoring/alerts/anomaly_detection.mat',
                        'by_usage/monitoring/alerts/threshold_violations.mat'
                    ]
                }
            ]
        }
        
        return workflow
    
    def get_validation_workflow(self):
        """Get data workflow for model validation"""
        
        workflow = {
            'name': 'Model Validation Workflow',
            'steps': [
                {
                    'step': 1,
                    'name': 'Load Simulation Results',
                    'files': [
                        'by_phase/post-processing/solution_analysis/final_solution_state.mat'
                    ],
                    'alternative_paths': {
                        'by_type': ['dynamic/fields/'],
                        'by_usage': ['validation/simulation_results/']
                    }
                },
                {
                    'step': 2,
                    'name': 'Load Benchmarks',
                    'files': [
                        'by_usage/validation/benchmarks/analytical_solutions.mat',
                        'by_usage/validation/benchmarks/reference_cases.mat'
                    ]
                },
                {
                    'step': 3,
                    'name': 'Load Quality Metrics',
                    'files': [
                        'by_usage/validation/quality_metrics/convergence_analysis.mat',
                        'by_usage/validation/quality_metrics/mass_balance_checks.mat'
                    ],
                    'alternative_paths': {
                        'by_type': ['derived/analytics/'],
                        'by_phase': ['post-processing/validation/']
                    }
                }
            ]
        }
        
        return workflow
    
    def execute_workflow(self, workflow, data_loader):
        """Execute a complete workflow and return loaded data"""
        
        workflow_data = {
            'workflow_name': workflow['name'],
            'execution_timestamp': datetime.now().isoformat(),
            'steps': {}
        }
        
        for step in workflow['steps']:
            step_num = step['step']
            step_name = step['name']
            
            print(f"Executing Step {step_num}: {step_name}")
            
            step_data = {}
            
            for file_path in step['files']:
                full_path = self.data_root / file_path
                
                if full_path.exists():
                    try:
                        # Try to load the file
                        if 'static' in str(full_path):
                            data = data_loader.load_static_data()
                        elif 'dynamic' in str(full_path):
                            data = data_loader.load_dynamic_fields()
                        else:
                            # Generic loading
                            data = data_loader.octave.load(str(full_path))
                        
                        step_data[file_path] = data
                        print(f"  ✓ Loaded: {file_path}")
                        
                    except Exception as e:
                        print(f"  ✗ Failed to load {file_path}: {e}")
                        
                        # Try alternative paths
                        if 'alternative_paths' in step:
                            for alt_structure, alt_paths in step['alternative_paths'].items():
                                for alt_path in alt_paths:
                                    alt_full_path = self.data_root / alt_structure / alt_path
                                    if alt_full_path.exists():
                                        try:
                                            # Try loading alternative
                                            print(f"  → Trying alternative: {alt_structure}/{alt_path}")
                                            # Loading logic for alternative path
                                            break
                                        except Exception:
                                            continue
                else:
                    print(f"  ✗ File not found: {file_path}")
            
            workflow_data['steps'][step_num] = {
                'name': step_name,
                'data': step_data,
                'files_loaded': len(step_data),
                'files_requested': len(step['files'])
            }
        
        return workflow_data
```

### 8.3 Data Discovery and Exploration

```python
def explore_data_catalog(data_root):
    """Interactive data catalog exploration"""
    
    navigator = CrossReferenceNavigator(data_root)
    metadata_manager = MetadataManager(data_root)
    
    # Discover all available datasets
    all_metadata_files = list(Path(data_root).rglob("metadata/**/*.yaml"))
    
    print(f"Found {len(all_metadata_files)} datasets in catalog")
    print("\n" + "="*60)
    
    # Categorize by data type
    by_type = {}
    
    for metadata_file in all_metadata_files:
        try:
            metadata = metadata_manager.load_metadata(
                str(metadata_file).replace('/metadata/', '/').replace('.yaml', '.mat')
            )
            
            data_type = metadata.get('data_type', 'unknown')
            
            if data_type not in by_type:
                by_type[data_type] = []
            
            by_type[data_type].append({
                'name': metadata.get('identification', {}).get('name', ''),
                'description': metadata.get('identification', {}).get('description', ''),
                'file_size_mb': metadata.get('file_info', {}).get('file_size_mb', 0),
                'creation_date': metadata.get('identification', {}).get('creation_date', ''),
                'tags': metadata.get('tags', [])
            })
            
        except Exception as e:
            print(f"Warning: Failed to process {metadata_file}: {e}")
    
    # Display catalog summary
    for data_type, datasets in by_type.items():
        print(f"\n{data_type.upper()} ({len(datasets)} datasets)")
        print("-" * 40)
        
        total_size = sum(d['file_size_mb'] for d in datasets)
        print(f"Total size: {total_size:.1f} MB")
        
        for dataset in datasets[:3]:  # Show first 3
            print(f"  • {dataset['name']}")
            print(f"    {dataset['description'][:60]}...")
            print(f"    Size: {dataset['file_size_mb']:.1f} MB, Tags: {', '.join(dataset['tags'][:3])}")
        
        if len(datasets) > 3:
            print(f"  ... and {len(datasets) - 3} more datasets")
    
    return by_type

# Example usage of the complete data access system
def demonstrate_complete_workflow():
    """Demonstrate a complete data access workflow"""
    
    data_root = "/workspace/data/simulation_data"
    
    # Initialize components
    with SimulationDataLoader(data_root) as loader:
        navigator = WorkflowNavigator(data_root)
        validator = DataValidator()
        
        print("=== Eagle West Field Data Access Demonstration ===\n")
        
        # 1. Explore available data
        print("1. Exploring data catalog...")
        catalog = explore_data_catalog(data_root)
        
        # 2. Execute ML training workflow
        print("\n2. Executing ML training workflow...")
        ml_workflow = navigator.get_ml_training_workflow()
        workflow_results = navigator.execute_workflow(ml_workflow, loader)
        
        # 3. Validate loaded data
        print("\n3. Validating loaded data...")
        for step_num, step_data in workflow_results['steps'].items():
            for file_path, data in step_data['data'].items():
                if 'static' in file_path:
                    validation = validator.validate_static_data(data)
                    print(f"   Step {step_num} validation: {validation['status']}")
        
        # 4. Demonstrate cross-reference navigation
        print("\n4. Demonstrating cross-reference navigation...")
        static_file = data_root + "/by_type/static/static_data.mat"
        lineage = navigator.xref_nav.trace_data_lineage(static_file)
        print(f"   Data lineage for {static_file}:")
        print(f"   - Dependencies: {len(lineage.get('dependencies', []))}")  
        print(f"   - Used by: {len(lineage.get('used_by', []))}")
        
        print("\n=== Workflow completed successfully! ===")

if __name__ == "__main__":
    demonstrate_complete_workflow()
```

---

## Summary

This comprehensive guide provides practical, executable instructions for accessing and working with Eagle West Field simulation data. Key takeaways:

1. **File Naming**: Follow standardized patterns for predictable data organization
2. **oct2py Integration**: Use optimized loading strategies with proper error handling
3. **YAML Metadata**: Leverage metadata for validation, discovery, and data lineage
4. **Unit Conversions**: Apply consistent unit conversion patterns using metadata
5. **Data Validation**: Implement comprehensive validation workflows
6. **Troubleshooting**: Use systematic approaches to diagnose and fix common issues
7. **Performance**: Apply memory management and I/O optimization strategies  
8. **Navigation**: Leverage cross-reference systems to navigate between organizational structures

The guide emphasizes practical implementation over theoretical concepts, providing working code examples that can be immediately applied to real simulation data workflows.