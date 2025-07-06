#!/usr/bin/env python3
"""
Plot Maps - Simple spatial distribution maps

Reads the latest simulation snapshot and generates spatial maps
showing the 20x20 grid distribution of reservoir properties.
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


def load_latest_snapshot():
    """Load the latest simulation snapshot"""
    
    # Path to simulation data
    data_path = Path(__file__).parent.parent.parent / "MRST_simulation_scripts" / "data"
    
    # Find all snapshot files
    snapshot_files = sorted(glob.glob(str(data_path / "snap_*.mat")))
    
    if not snapshot_files:
        print(f"❌ No snapshot files found in {data_path}")
        return None, None
    
    # Get latest snapshot
    latest_file = snapshot_files[-1]
    timestep = int(os.path.basename(latest_file).replace('snap_', '').replace('.mat', ''))
    
    print(f"📊 Loading latest snapshot: timestep {timestep}")
    
    try:
        # Parse Octave file
        snapshot = parse_octave_mat_file(latest_file)
        
        print(f"✅ Loaded snapshot {timestep} successfully")
        return snapshot, timestep
        
    except Exception as e:
        print(f"❌ Error loading {latest_file}: {e}")
        return None, None


def reshape_to_grid(data, grid_shape=(20, 20)):
    """Reshape 1D data to 2D grid"""
    return data.reshape(grid_shape)


def plot_spatial_maps(snapshot, timestep, output_path=None):
    """Create spatial distribution maps"""
    
    if output_path is None:
        # Save in monitoring/plots/ directory
        output_path = Path(__file__).parent.parent / "plots" / "maps.png"
    
    fig, axes = plt.subplots(2, 3, figsize=(15, 10))
    fig.suptitle(f'🗺️ Spatial Distribution - Timestep {timestep}', 
                 fontsize=16, fontweight='bold')
    
    # ----
    # Map 1: Pressure Map
    # ----
    ax = axes[0, 0]
    pressure_psi = snapshot['pressure'].flatten()
    pressure_map = reshape_to_grid(pressure_psi)
    
    im1 = ax.imshow(pressure_map, cmap='viridis', origin='lower')
    ax.set_title('🔵 Pressure (psi)')
    ax.set_xlabel('X Grid')
    ax.set_ylabel('Y Grid')
    plt.colorbar(im1, ax=ax)
    
    # ----
    # Map 2: Effective Stress Map
    # ----
    ax = axes[0, 1]
    stress_psi = snapshot['sigma_eff'].flatten()
    stress_map = reshape_to_grid(stress_psi)
    
    im2 = ax.imshow(stress_map, cmap='plasma', origin='lower')
    ax.set_title('⚖️ Effective Stress (psi)')
    ax.set_xlabel('X Grid')
    ax.set_ylabel('Y Grid')
    plt.colorbar(im2, ax=ax)
    
    # ----
    # Map 3: Porosity Map
    # ----
    ax = axes[0, 2]
    porosity = snapshot['phi'].flatten()
    porosity_map = reshape_to_grid(porosity)
    
    im3 = ax.imshow(porosity_map, cmap='YlOrRd', origin='lower')
    ax.set_title('🟢 Porosity')
    ax.set_xlabel('X Grid')
    ax.set_ylabel('Y Grid')
    plt.colorbar(im3, ax=ax)
    
    # ----
    # Map 4: Permeability Map (Log Scale)
    # ----
    ax = axes[1, 0]
    permeability_mD = snapshot['k'].flatten()
    perm_map = reshape_to_grid(np.log10(permeability_mD))
    
    im4 = ax.imshow(perm_map, cmap='coolwarm', origin='lower')
    ax.set_title('🟣 Log₁₀ Permeability (mD)')
    ax.set_xlabel('X Grid')
    ax.set_ylabel('Y Grid')
    plt.colorbar(im4, ax=ax)
    
    # ----
    # Map 5: Water Saturation Map (Placeholder)
    # ----
    ax = axes[1, 1]
    water_sat = np.ones(400) * 0.2  # Placeholder data
    water_sat_map = reshape_to_grid(water_sat)
    
    im5 = ax.imshow(water_sat_map, cmap='Blues', origin='lower', vmin=0, vmax=1)
    ax.set_title('💧 Water Saturation')
    ax.set_xlabel('X Grid')
    ax.set_ylabel('Y Grid')
    plt.colorbar(im5, ax=ax)
    
    # ----
    # Map 6: Rock Regions Map
    # ----
    ax = axes[1, 2]
    rock_regions = snapshot['rock_id'].flatten()
    regions_map = reshape_to_grid(rock_regions)
    
    im6 = ax.imshow(regions_map, cmap='Set1', origin='lower')
    ax.set_title('🟤 Rock Regions')
    ax.set_xlabel('X Grid')
    ax.set_ylabel('Y Grid')
    plt.colorbar(im6, ax=ax)
    
    plt.tight_layout()
    
    # Save plot
    os.makedirs(os.path.dirname(output_path), exist_ok=True)
    plt.savefig(output_path, dpi=150, bbox_inches='tight')
    plt.close()
    
    print(f"✅ Spatial maps saved: {output_path}")


def main():
    """Main function"""
    print("🗺️ Generating Spatial Maps...")
    print("=" * 40)
    
    # Load latest snapshot
    snapshot, timestep = load_latest_snapshot()
    if snapshot is None:
        return
    
    # Generate maps
    print("🎨 Creating spatial maps...")
    plot_spatial_maps(snapshot, timestep)
    
    print("✅ Spatial maps complete!")


if __name__ == "__main__":
    main() 