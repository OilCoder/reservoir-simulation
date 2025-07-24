# Code Generation Examples

This document provides examples of properly generated code following all project rules.

## Python Module Example

File: `src/s01_load_data.py`

```python
"""
Load and preprocess reservoir data from various sources.

Key components:
- CSV data loading with validation
- Data normalization and scaling
- Train/test split functionality
"""

# ----------------------------------------
# Step 1 – Import and Setup
# ----------------------------------------

# Substep 1.1 – Standard library imports ______________________
import os
import logging
from pathlib import Path
from typing import Dict, List, Tuple, Optional

# Substep 1.2 – External library imports ______________________
import numpy as np
import pandas as pd
from sklearn.preprocessing import StandardScaler
from sklearn.model_selection import train_test_split

# Substep 1.3 – Internal imports ______________________
from src.s00_config import DATA_PATH, RANDOM_SEED

# ----------------------------------------
# Step 2 – Data Loading Functions
# ----------------------------------------

def load_reservoir_data(file_path: str) -> pd.DataFrame:
    """Load reservoir data from CSV file.
    
    Args:
        file_path: Path to the CSV file containing reservoir data.
        
    Returns:
        DataFrame with loaded reservoir data.
        
    Raises:
        FileNotFoundError: If the specified file doesn't exist.
        ValueError: If the file format is invalid.
    """
    # ✅ Validate inputs
    if not os.path.exists(file_path):
        raise FileNotFoundError(f"Data file not found: {file_path}")
    
    # 🔄 Load data
    try:
        data = pd.read_csv(file_path)
    except Exception as e:
        raise ValueError(f"Failed to read CSV: {e}")
    
    # ✅ Validate data structure
    required_columns = ['pressure', 'temperature', 'porosity']
    missing = set(required_columns) - set(data.columns)
    if missing:
        raise ValueError(f"Missing required columns: {missing}")
    
    # 📊 Return loaded data
    return data


def normalize_features(data: pd.DataFrame) -> Tuple[np.ndarray, StandardScaler]:
    """Normalize numerical features using standard scaling.
    
    Args:
        data: DataFrame containing features to normalize.
        
    Returns:
        Tuple of (normalized_array, fitted_scaler).
    """
    # ✅ Extract numerical columns
    numeric_cols = data.select_dtypes(include=[np.number]).columns
    
    # 🔄 Fit and transform
    scaler = StandardScaler()
    normalized = scaler.fit_transform(data[numeric_cols])
    
    # 📊 Return results
    return normalized, scaler

# ----------------------------------------
# Step 3 – Data Splitting
# ----------------------------------------

def create_train_test_split(
    features: np.ndarray, 
    labels: np.ndarray,
    test_size: float = 0.2
) -> Dict[str, np.ndarray]:
    """Split data into training and testing sets.
    
    Args:
        features: Feature array of shape (n_samples, n_features).
        labels: Label array of shape (n_samples,).
        test_size: Fraction of data for testing. Defaults to 0.2.
        
    Returns:
        Dictionary with keys 'X_train', 'X_test', 'y_train', 'y_test'.
    """
    # ✅ Validate inputs
    if features.shape[0] != labels.shape[0]:
        raise ValueError("Features and labels must have same length")
    
    # 🔄 Split data
    X_train, X_test, y_train, y_test = train_test_split(
        features, labels, test_size=test_size, random_state=RANDOM_SEED
    )
    
    # 📊 Return as dictionary
    return {
        'X_train': X_train,
        'X_test': X_test,
        'y_train': y_train,
        'y_test': y_test
    }

# ----------------------------------------
# Step 4 – Main Pipeline
# ----------------------------------------

def prepare_dataset(file_path: str) -> Dict[str, np.ndarray]:
    """Complete pipeline to load and prepare dataset.
    
    Args:
        file_path: Path to raw data file.
        
    Returns:
        Dictionary with prepared train/test splits.
    """
    # Load data
    data = load_reservoir_data(file_path)
    
    # Separate features and labels
    features = data.drop('target', axis=1)
    labels = data['target'].values
    
    # Normalize features
    normalized_features, _ = normalize_features(features)
    
    # Create splits
    splits = create_train_test_split(normalized_features, labels)
    
    return splits
```

## Octave/MRST Script Example

File: `mrst_simulation_scripts/s02_setup_reservoir.m`

```matlab
% Setup reservoir model with heterogeneous properties
% Requires: MRST
% Author: Engineering Team
% Date: 2024-01-01

% ----------------------------------------
% Step 1 – Initialize MRST Environment
% ----------------------------------------

% Substep 1.1 – Clear workspace and load MRST ______________________
clear all; close all; clc;
mrstModule add ad-core ad-blackoil ad-props incomp;

% Substep 1.2 – Define simulation parameters ______________________
% Grid dimensions
nx = 40;  % Cells in x-direction
ny = 40;  % Cells in y-direction
nz = 10;  % Cells in z-direction

% Physical dimensions
Lx = 1000;  % Length in x-direction [m]
Ly = 1000;  % Length in y-direction [m]
Lz = 50;    % Height [m]

% ----------------------------------------
% Step 2 – Create Grid and Rock Properties
% ----------------------------------------

function [G, rock] = create_reservoir_model(nx, ny, nz, dims)
    % PURPOSE: Create 3D reservoir grid with heterogeneous properties
    % INPUTS:
    %   nx, ny, nz - Number of cells in each direction
    %   dims       - Physical dimensions [Lx, Ly, Lz] in meters
    % OUTPUTS:
    %   G    - Grid structure
    %   rock - Rock properties (perm, poro)
    % EXAMPLE:
    %   [G, rock] = create_reservoir_model(20, 20, 5, [100, 100, 10]);
    
    % ✅ Validate inputs
    assert(all([nx, ny, nz] > 0), 'Grid dimensions must be positive');
    assert(length(dims) == 3, 'dims must be [Lx, Ly, Lz]');
    
    % 🔄 Create Cartesian grid
    G = cartGrid([nx, ny, nz], dims);
    G = computeGeometry(G);
    
    % 🔄 Generate heterogeneous permeability
    % Layer-based permeability
    perm = zeros(G.cells.num, 1);
    for k = 1:nz
        layer_cells = (k-1)*nx*ny + 1 : k*nx*ny;
        layer_perm = 100 - 10*k;  % Decreasing with depth
        perm(layer_cells) = layer_perm * milli*darcy;
    end
    
    % Add random variation
    perm = perm .* (0.8 + 0.4*rand(G.cells.num, 1));
    
    % 🔄 Generate porosity (correlated with permeability)
    poro = 0.1 + 0.15 * (perm / max(perm));
    
    % 📊 Create rock structure
    rock = makeRock(G, perm, poro);
end

% ----------------------------------------
% Step 3 – Define Fluid Properties
% ----------------------------------------

function fluid = setup_fluid_model()
    % PURPOSE: Define two-phase fluid model (oil-water)
    % OUTPUTS:
    %   fluid - Fluid structure for MRST simulation
    
    % ✅ Define fluid properties
    mu_w = 1.0*centi*poise;     % Water viscosity
    mu_o = 5.0*centi*poise;     % Oil viscosity
    rho_w = 1000*kilogram/meter^3;  % Water density
    rho_o = 800*kilogram/meter^3;   % Oil density
    
    % 🔄 Create fluid model
    fluid = initSimpleFluid('mu', [mu_w, mu_o], ...
                           'rho', [rho_w, rho_o], ...
                           'n',   [2, 2]);
    
    % 📊 Return fluid structure
end

% ----------------------------------------
% Step 4 – Main Execution
% ----------------------------------------

% Create reservoir model
[G, rock] = create_reservoir_model(nx, ny, nz, [Lx, Ly, Lz]);

% Setup fluid
fluid = setup_fluid_model();

% Display summary
fprintf('Reservoir model created:\n');
fprintf('  Grid: %d x %d x %d cells\n', nx, ny, nz);
fprintf('  Dimensions: %.0f x %.0f x %.0f meters\n', Lx, Ly, Lz);
fprintf('  Permeability range: [%.1f, %.1f] mD\n', ...
        min(rock.perm)/milli/darcy, max(rock.perm)/milli/darcy);
fprintf('  Porosity range: [%.3f, %.3f]\n', ...
        min(rock.poro), max(rock.poro));

% Save results
save('output/reservoir_model.mat', 'G', 'rock', 'fluid');
```

## Test File Example

File: `tests/test_01_src_load_data.py`

```python
"""Tests for data loading functionality."""

import pytest
import numpy as np
import pandas as pd
from pathlib import Path

from src.s01_load_data import (
    load_reservoir_data,
    normalize_features,
    create_train_test_split
)

# ----------------------------------------
# Step 1 – Test Fixtures
# ----------------------------------------

@pytest.fixture
def sample_csv_file(tmp_path):
    """Create temporary CSV file for testing."""
    data = pd.DataFrame({
        'pressure': [100, 200, 300],
        'temperature': [50, 60, 70],
        'porosity': [0.1, 0.2, 0.15],
        'target': [1, 0, 1]
    })
    file_path = tmp_path / "test_data.csv"
    data.to_csv(file_path, index=False)
    return str(file_path)

# ----------------------------------------
# Step 2 – Test Data Loading
# ----------------------------------------

def test_load_reservoir_data_success(sample_csv_file):
    """Test successful data loading."""
    # ✅ Act
    result = load_reservoir_data(sample_csv_file)
    
    # 📊 Assert
    assert isinstance(result, pd.DataFrame)
    assert len(result) == 3
    assert all(col in result.columns 
              for col in ['pressure', 'temperature', 'porosity'])

def test_load_reservoir_data_missing_file():
    """Test error handling for missing file."""
    with pytest.raises(FileNotFoundError):
        load_reservoir_data("nonexistent.csv")

# ----------------------------------------
# Step 3 – Test Normalization
# ----------------------------------------

def test_normalize_features():
    """Test feature normalization."""
    # ✅ Arrange
    data = pd.DataFrame({
        'feature1': [1, 2, 3],
        'feature2': [10, 20, 30]
    })
    
    # 🔄 Act
    normalized, scaler = normalize_features(data)
    
    # 📊 Assert
    assert normalized.shape == (3, 2)
    assert np.allclose(normalized.mean(axis=0), 0, atol=1e-10)
    assert np.allclose(normalized.std(axis=0), 1, atol=1e-10)
```

## Debug Script Example

File: `debug/dbg_convergence_issue.py`

```python
"""
Debug script for investigating convergence issues in training.

Target module: src/s03_train_model.py
Function: train_reservoir_model
Date: 2024-01-15
Author: Debug Team

Issue Description:
- Model training fails to converge after 50 epochs
- Loss plateaus at high value
- Occurs with specific dataset configurations

Hypothesis:
- Learning rate might be too high
- Data scaling issues
- Gradient explosion
"""

# ----------------------------------------
# Step 1 – Setup Debug Environment
# ----------------------------------------

import sys
sys.path.append('..')

import numpy as np
import matplotlib.pyplot as plt
from datetime import datetime

from src.s03_train_model import train_reservoir_model, create_model

print("="*50)
print("CONVERGENCE ISSUE INVESTIGATION")
print("="*50)

# ----------------------------------------
# Step 2 – Load Problematic Data
# ----------------------------------------

print("\n--- Loading test data ---")
# Load the specific dataset that causes issues
data = np.load('debug/problem_dataset.npy')
print(f"Data shape: {data.shape}")
print(f"Data range: [{data.min():.4f}, {data.max():.4f}]")

# Check for outliers
outliers = np.sum(np.abs(data) > 3 * np.std(data))
print(f"Outliers (>3 std): {outliers}")

# ----------------------------------------
# Step 3 – Test Different Configurations
# ----------------------------------------

print("\n--- Testing configurations ---")

configs = [
    {'lr': 0.001, 'batch_size': 32},
    {'lr': 0.0001, 'batch_size': 32},
    {'lr': 0.001, 'batch_size': 64},
]

results = []
for i, config in enumerate(configs):
    print(f"\nConfig {i+1}: lr={config['lr']}, batch={config['batch_size']}")
    
    try:
        model = create_model(input_dim=data.shape[1])
        history = train_reservoir_model(
            model, data, data, 
            learning_rate=config['lr'],
            batch_size=config['batch_size'],
            epochs=10,
            verbose=True
        )
        
        final_loss = history['loss'][-1]
        print(f"  Final loss: {final_loss:.4f}")
        results.append((config, history))
        
    except Exception as e:
        print(f"  Failed: {e}")
        results.append((config, None))

# ----------------------------------------
# Step 4 – Visualize Results
# ----------------------------------------

print("\n--- Creating visualizations ---")

fig, axes = plt.subplots(2, 2, figsize=(12, 10))
fig.suptitle('Convergence Analysis')

# Plot loss curves
ax1 = axes[0, 0]
for config, history in results:
    if history:
        ax1.plot(history['loss'], 
                label=f"lr={config['lr']}")
ax1.set_xlabel('Epoch')
ax1.set_ylabel('Loss')
ax1.set_title('Training Loss Comparison')
ax1.legend()

# Save figure
plt.savefig('debug/convergence_analysis.png')
print("Saved visualization to debug/convergence_analysis.png")

# ----------------------------------------
# Step 5 – Findings
# ----------------------------------------

print("\n" + "="*50)
print("FINDINGS")
print("="*50)

print("\n1. Lower learning rate (0.0001) shows better convergence")
print("2. Data contains significant outliers affecting training")
print("3. Batch size has minimal impact on convergence issue")
print("\nRecommended fix: Implement gradient clipping and reduce lr")
```

These examples demonstrate:
1. Proper file naming conventions
2. Step/substep structure with visual markers
3. Google Style docstrings (Python)
4. English-only comments
5. Appropriate use of try/except
6. Snake_case naming
7. Functions under 40 lines
8. Clear organization and purpose