#!/usr/bin/env python3
"""
Plot Evolution - Simple temporal evolution plots

Reads simulation snapshots from sim_scripts/data/raw/ and generates
evolution plots showing how reservoir properties change over time.
"""

import numpy as np
import matplotlib.pyplot as plt
import glob
import os
from pathlib import Path


def parse_octave_mat_file(filepath):
    """Parse Octave text format .mat file"""
    
    data = {}
    current_var = None
    reading_matrix = False
    
    with open(filepath, 'r') as f:
        lines = f.readlines()
    
    i = 0
    while i < len(lines):
        line = lines[i].strip()
        
        # Skip comments and empty lines
        if line.startswith('#') or not line:
            # Check for variable name
            if line.startswith('# name:'):
                current_var = line.split(':', 1)[1].strip()
            # Check for matrix type
            elif line.startswith('# type: matrix'):
                reading_matrix = True
            # Check for rows
            elif line.startswith('# rows:'):
                rows = int(line.split(':', 1)[1].strip())
            # Check for columns  
            elif line.startswith('# columns:'):
                cols = int(line.split(':', 1)[1].strip())
                # Read matrix data
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


def load_snapshots():
    """Load all simulation snapshots from sim_scripts/data/raw/"""
    
    # Path to simulation data
    data_path = Path(__file__).parent.parent.parent / "sim_scripts" / "data" / "raw"
    
    # Find all snapshot files
    snapshot_files = sorted(glob.glob(str(data_path / "snap_*.mat")))
    
    if not snapshot_files:
        print(f"❌ No snapshot files found in {data_path}")
        return None
    
    print(f"📊 Found {len(snapshot_files)} snapshots")
    
    # Load snapshots
    snapshots = []
    timesteps = []
    
    for file_path in snapshot_files:
        try:
            # Extract timestep from filename
            filename = os.path.basename(file_path)
            timestep = int(filename.replace('snap_', '').replace('.mat', ''))
            
            # Parse Octave file
            snapshot_data = parse_octave_mat_file(file_path)
            
            snapshots.append(snapshot_data)
            timesteps.append(timestep)
            
        except Exception as e:
            print(f"⚠️  Error loading {file_path}: {e}")
            continue
    
    print(f"✅ Loaded {len(snapshots)} snapshots successfully")
    return snapshots, timesteps


def extract_evolution_data(snapshots, timesteps):
    """Extract time series data from snapshots"""
    
    n_steps = len(snapshots)
    
    # Initialize arrays
    evolution_data = {
        'timesteps': np.array(timesteps),
        'pressure_avg': np.zeros(n_steps),
        'pressure_min': np.zeros(n_steps),
        'pressure_max': np.zeros(n_steps),
        'stress_avg': np.zeros(n_steps),
        'stress_min': np.zeros(n_steps),
        'stress_max': np.zeros(n_steps),
        'porosity_avg': np.zeros(n_steps),
        'porosity_min': np.zeros(n_steps),
        'porosity_max': np.zeros(n_steps),
        'permeability_avg': np.zeros(n_steps),
        'permeability_min': np.zeros(n_steps),
        'permeability_max': np.zeros(n_steps)
    }
    
    for i, snapshot in enumerate(snapshots):
        
        # Pressure (assume in psi)
        if 'pressure' in snapshot:
            pressure_psi = snapshot['pressure'].flatten()
        else:
            pressure_psi = np.zeros(400)
        
        evolution_data['pressure_avg'][i] = np.mean(pressure_psi)
        evolution_data['pressure_min'][i] = np.min(pressure_psi)
        evolution_data['pressure_max'][i] = np.max(pressure_psi)
        
        # Effective stress (assume in psi)
        if 'sigma_eff' in snapshot:
            stress_psi = snapshot['sigma_eff'].flatten()
        else:
            stress_psi = np.zeros(400)
            
        evolution_data['stress_avg'][i] = np.mean(stress_psi)
        evolution_data['stress_min'][i] = np.min(stress_psi)
        evolution_data['stress_max'][i] = np.max(stress_psi)
        
        # Porosity
        if 'phi' in snapshot:
            porosity = snapshot['phi'].flatten()
        else:
            porosity = np.ones(400) * 0.2  # Default porosity
            
        evolution_data['porosity_avg'][i] = np.mean(porosity)
        evolution_data['porosity_min'][i] = np.min(porosity)
        evolution_data['porosity_max'][i] = np.max(porosity)
        
        # Permeability
        if 'k' in snapshot:
            permeability_mD = snapshot['k'].flatten()
        else:
            permeability_mD = np.ones(400) * 100  # Default permeability
            
        evolution_data['permeability_avg'][i] = np.mean(permeability_mD)
        evolution_data['permeability_min'][i] = np.min(permeability_mD)
        evolution_data['permeability_max'][i] = np.max(permeability_mD)
    
    return evolution_data


def plot_evolution(evolution_data, output_path="plots/evolution.png"):
    """Create evolution plots"""
    
    fig, axes = plt.subplots(2, 2, figsize=(12, 8))
    fig.suptitle('📊 Reservoir Evolution', fontsize=16, fontweight='bold')
    
    x = evolution_data['timesteps']
    
    # ----
    # Subplot 1: Pressure Evolution
    # ----
    ax = axes[0, 0]
    ax.plot(x, evolution_data['pressure_avg'], 'b-', linewidth=2, label='Average')
    ax.fill_between(x, evolution_data['pressure_min'], evolution_data['pressure_max'], 
                    alpha=0.3, color='blue', label='Min-Max Range')
    ax.set_xlabel('Timestep')
    ax.set_ylabel('Pressure (psi)')
    ax.set_title('🔵 Pressure Evolution')
    ax.grid(True, alpha=0.3)
    ax.legend()
    
    # ----
    # Subplot 2: Effective Stress
    # ----
    ax = axes[0, 1]
    ax.plot(x, evolution_data['stress_avg'], 'r-', linewidth=2, label='Average')
    ax.fill_between(x, evolution_data['stress_min'], evolution_data['stress_max'], 
                    alpha=0.3, color='red', label='Min-Max Range')
    ax.set_xlabel('Timestep')
    ax.set_ylabel('Effective Stress (psi)')
    ax.set_title('⚖️ Effective Stress Evolution')
    ax.grid(True, alpha=0.3)
    ax.legend()
    
    # ----
    # Subplot 3: Porosity Evolution
    # ----
    ax = axes[1, 0]
    ax.plot(x, evolution_data['porosity_avg'], 'g-', linewidth=2, label='Average')
    ax.fill_between(x, evolution_data['porosity_min'], evolution_data['porosity_max'], 
                    alpha=0.3, color='green', label='Min-Max Range')
    ax.set_xlabel('Timestep')
    ax.set_ylabel('Porosity')
    ax.set_title('🟢 Porosity Evolution')
    ax.grid(True, alpha=0.3)
    ax.legend()
    
    # ----
    # Subplot 4: Permeability Evolution
    # ----
    ax = axes[1, 1]
    ax.semilogy(x, evolution_data['permeability_avg'], 'k-', linewidth=2, label='Average')
    ax.fill_between(x, evolution_data['permeability_min'], evolution_data['permeability_max'], 
                    alpha=0.3, color='black', label='Min-Max Range')
    ax.set_xlabel('Timestep')
    ax.set_ylabel('Permeability (mD)')
    ax.set_title('🟣 Permeability Evolution (Log Scale)')
    ax.grid(True, alpha=0.3)
    ax.legend()
    
    plt.tight_layout()
    
    # Save plot
    os.makedirs(os.path.dirname(output_path), exist_ok=True)
    plt.savefig(output_path, dpi=150, bbox_inches='tight')
    plt.close()
    
    print(f"✅ Evolution plot saved: {output_path}")


def main():
    """Main function"""
    print("🎨 Generating Evolution Plots...")
    print("=" * 40)
    
    # Load snapshots
    result = load_snapshots()
    if result is None:
        return
    
    snapshots, timesteps = result
    
    # Extract evolution data
    print("📈 Extracting evolution data...")
    evolution_data = extract_evolution_data(snapshots, timesteps)
    
    # Generate plot
    print("🎨 Creating evolution plot...")
    plot_evolution(evolution_data)
    
    print("✅ Evolution plots complete!")


if __name__ == "__main__":
    main() 