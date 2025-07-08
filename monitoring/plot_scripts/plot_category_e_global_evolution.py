#!/usr/bin/env python3
"""
Category E: Global Evolution (Time Series) - REQUIRES REAL MRST DATA

Generates individual plots for reservoir-wide evolution:
E-1: Pressure evolution (average + range) - REQUIRES REAL MRST DATA
E-2: Effective stress evolution - REQUIRES REAL MRST DATA  
E-3: Porosity evolution - REQUIRES REAL MRST DATA
E-4: Permeability evolution - REQUIRES REAL MRST DATA

IMPORTANT: This script now requires real MRST simulation data.
No synthetic data generation. Will fail if data is not available.
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


def load_snapshots():
    """Load all simulation snapshots - REQUIRED FOR ALL E PLOTS"""
    
    data_path = Path("/workspace/data")
    
    snapshot_files = sorted(glob.glob(str(data_path / "snapshots/snap_*.mat")))
    
    if not snapshot_files:
        raise FileNotFoundError(
            f"❌ MISSING DATA: No snapshot files found in {data_path}\n"
            f"   Required: snapshots/snap_*.mat files from MRST simulation\n"
            f"   Run MRST simulation and export_dataset.m first.")
    
    print(f"📊 Found {len(snapshot_files)} snapshots")
    
    snapshots = []
    timesteps = []
    
    for file_path in snapshot_files:
        try:
            filename = os.path.basename(file_path)
            timestep = int(filename.replace('snap_', '').replace('.mat', ''))
            
            snapshot_data = parse_octave_mat_file(file_path)
            
            if not snapshot_data:
                raise ValueError(
                    f"❌ INVALID DATA: Could not parse {file_path}\n"
                    f"   Check MRST snapshot export format.")
            
            snapshots.append(snapshot_data)
            timesteps.append(timestep)
            
        except Exception as e:
            raise ValueError(
                f"❌ ERROR loading {file_path}: {e}\n"
                f"   Check MRST snapshot export format.")
    
    if len(snapshots) == 0:
        raise ValueError(
            f"❌ NO VALID DATA: No snapshots could be loaded\n"
            f"   Check MRST snapshot generation and export.")
    
    print(f"✅ Loaded {len(snapshots)} snapshots successfully")
    return snapshots, timesteps


def plot_pressure_evolution(output_path=None):
    """E-1: Pressure evolution - REQUIRES REAL MRST DATA
    Question: How does reservoir pressure change over time?
    """
    
    if output_path is None:
        output_path = (Path(__file__).parent.parent / 
                      "plots" / "E-1_pressure_evolution.png")
    
    # Load real MRST data - NO FALLBACK TO SYNTHETIC
    snapshots, timesteps = load_snapshots()
    n_steps = len(snapshots)
    
    # Check for required data in first snapshot
    if 'pressure' not in snapshots[0]:
        raise ValueError(
            f"❌ MISSING DATA: 'pressure' not found in snapshots\n"
            f"   Required variables: pressure\n"
            f"   Available variables: {list(snapshots[0].keys())}\n"
            f"   Check MRST extract_snapshot.m export.")
    
    pressure_avg = np.zeros(n_steps)
    pressure_min = np.zeros(n_steps)
    pressure_max = np.zeros(n_steps)
    time_days = np.zeros(n_steps)
    
    for i, snapshot in enumerate(snapshots):
        pressure_psi = snapshot['pressure'].flatten()
        
        if len(pressure_psi) == 0:
            raise ValueError(
                f"❌ EMPTY DATA: Pressure array is empty at timestep {timesteps[i]}\n"
                f"   Check MRST pressure calculation.")
        
        pressure_avg[i] = np.mean(pressure_psi)
        pressure_min[i] = np.min(pressure_psi)
        pressure_max[i] = np.max(pressure_psi)
        
        # Get time in days if available
        if 'time_days' in snapshot:
            time_days[i] = snapshot['time_days']
        else:
            time_days[i] = timesteps[i]  # Use timestep as fallback
    
    fig, ax = plt.subplots(1, 1, figsize=(14, 8))
    
    ax.plot(time_days, pressure_avg, 'b-', linewidth=4, label='Average Pressure', 
            marker='o', markersize=6)
    ax.fill_between(time_days, pressure_min, pressure_max, 
                    alpha=0.3, color='blue', label='Min-Max Range')
    
    # Add statistics outside plot area
    initial_avg = pressure_avg[0]
    final_avg = pressure_avg[-1]
    pressure_change = final_avg - initial_avg
    pressure_decline_rate = pressure_change / (time_days[-1] - time_days[0]) if len(time_days) > 1 else 0
    
    stats_text = (f'Pressure Statistics:\n'
                 f'Initial: {initial_avg:.1f} psi\n'
                 f'Final: {final_avg:.1f} psi\n'
                 f'Change: {pressure_change:+.1f} psi\n'
                 f'Rate: {pressure_decline_rate:.2f} psi/day\n'
                 f'Time span: {time_days[0]:.1f} - {time_days[-1]:.1f} days')
    
    ax.text(1.02, 0.98, stats_text, transform=ax.transAxes, va='top', ha='left',
            fontsize=11, bbox=dict(boxstyle='round', facecolor='lightblue', alpha=0.8))
    
    # Add data source info
    ax.text(1.02, 0.65, 'Source: MRST\nSnapshot data\n(Real simulation)', 
            transform=ax.transAxes, va='top', ha='left', fontsize=10,
            bbox=dict(boxstyle='round', facecolor='lightgreen', alpha=0.8))
    
    ax.set_xlabel('Time (days)', fontsize=14, fontweight='bold')
    ax.set_ylabel('Pressure (psi)', fontsize=14, fontweight='bold')
    ax.set_title('E-1: Reservoir Pressure Evolution\nQuestion: How does reservoir pressure change over time?', 
                 fontsize=16, fontweight='bold')
    
    # Move legend outside plot area
    ax.legend(loc='center left', bbox_to_anchor=(1.02, 0.5), fontsize=12)
    ax.grid(True, alpha=0.3)
    
    # Adjust layout
    plt.subplots_adjust(right=0.75)
    
    os.makedirs(os.path.dirname(output_path), exist_ok=True)
    plt.savefig(output_path, dpi=150, bbox_inches='tight')
    plt.close()
    
    print(f"✅ Pressure evolution plot saved: {output_path}")


def plot_stress_evolution(output_path=None):
    """E-2: Effective stress evolution - REQUIRES REAL MRST DATA
    Question: How does effective stress change with depletion?
    """
    
    if output_path is None:
        output_path = (Path(__file__).parent.parent / 
                      "plots" / "E-2_stress_evolution.png")
    
    # Load real MRST data - NO FALLBACK TO SYNTHETIC
    snapshots, timesteps = load_snapshots()
    n_steps = len(snapshots)
    
    # Check for required data in first snapshot
    if 'sigma_eff' not in snapshots[0]:
        raise ValueError(
            f"❌ MISSING DATA: 'sigma_eff' not found in snapshots\n"
            f"   Required variables: sigma_eff (effective stress)\n"
            f"   Available variables: {list(snapshots[0].keys())}\n"
            f"   Check MRST extract_snapshot.m export.")
    
    stress_avg = np.zeros(n_steps)
    stress_min = np.zeros(n_steps)
    stress_max = np.zeros(n_steps)
    time_days = np.zeros(n_steps)
    
    for i, snapshot in enumerate(snapshots):
        stress_psi = snapshot['sigma_eff'].flatten()
        
        if len(stress_psi) == 0:
            raise ValueError(
                f"❌ EMPTY DATA: Stress array is empty at timestep {timesteps[i]}\n"
                f"   Check MRST stress calculation.")
        
        stress_avg[i] = np.mean(stress_psi)
        stress_min[i] = np.min(stress_psi)
        stress_max[i] = np.max(stress_psi)
        
        # Get time in days if available
        if 'time_days' in snapshot:
            time_days[i] = snapshot['time_days']
        else:
            time_days[i] = timesteps[i]  # Use timestep as fallback
    
    fig, ax = plt.subplots(1, 1, figsize=(14, 8))
    
    ax.plot(time_days, stress_avg, 'r-', linewidth=4, label='Average Stress', 
            marker='s', markersize=6)
    ax.fill_between(time_days, stress_min, stress_max, 
                    alpha=0.3, color='red', label='Min-Max Range')
    
    # Add statistics outside plot area
    initial_avg = stress_avg[0]
    final_avg = stress_avg[-1]
    stress_change = final_avg - initial_avg
    stress_rate = stress_change / (time_days[-1] - time_days[0]) if len(time_days) > 1 else 0
    
    stats_text = (f'Stress Statistics:\n'
                 f'Initial: {initial_avg:.1f} psi\n'
                 f'Final: {final_avg:.1f} psi\n'
                 f'Change: {stress_change:+.1f} psi\n'
                 f'Rate: {stress_rate:.2f} psi/day\n'
                 f'Time span: {time_days[0]:.1f} - {time_days[-1]:.1f} days')
    
    ax.text(1.02, 0.98, stats_text, transform=ax.transAxes, va='top', ha='left',
            fontsize=11, bbox=dict(boxstyle='round', facecolor='lightcoral', alpha=0.8))
    
    # Add data source info
    ax.text(1.02, 0.65, 'Source: MRST\nSnapshot data\n(Real simulation)', 
            transform=ax.transAxes, va='top', ha='left', fontsize=10,
            bbox=dict(boxstyle='round', facecolor='lightgreen', alpha=0.8))
    
    ax.set_xlabel('Time (days)', fontsize=14, fontweight='bold')
    ax.set_ylabel('Effective Stress (psi)', fontsize=14, fontweight='bold')
    ax.set_title('E-2: Effective Stress Evolution\nQuestion: How does effective stress change with depletion?', 
                 fontsize=16, fontweight='bold')
    
    # Move legend outside plot area
    ax.legend(loc='center left', bbox_to_anchor=(1.02, 0.5), fontsize=12)
    ax.grid(True, alpha=0.3)
    
    # Adjust layout
    plt.subplots_adjust(right=0.75)
    
    os.makedirs(os.path.dirname(output_path), exist_ok=True)
    plt.savefig(output_path, dpi=150, bbox_inches='tight')
    plt.close()
    
    print(f"✅ Stress evolution plot saved: {output_path}")


def plot_porosity_evolution(output_path=None):
    """E-3: Porosity evolution - REQUIRES REAL MRST DATA
    Question: How much does porosity change due to compaction?
    """
    
    if output_path is None:
        output_path = (Path(__file__).parent.parent / 
                      "plots" / "E-3_porosity_evolution.png")
    
    # Load real MRST data - NO FALLBACK TO SYNTHETIC
    snapshots, timesteps = load_snapshots()
    n_steps = len(snapshots)
    
    # Check for required data in first snapshot
    if 'phi' not in snapshots[0]:
        raise ValueError(
            f"❌ MISSING DATA: 'phi' not found in snapshots\n"
            f"   Required variables: phi (porosity)\n"
            f"   Available variables: {list(snapshots[0].keys())}\n"
            f"   Check MRST extract_snapshot.m export.")
    
    porosity_avg = np.zeros(n_steps)
    porosity_min = np.zeros(n_steps)
    porosity_max = np.zeros(n_steps)
    time_days = np.zeros(n_steps)
    
    for i, snapshot in enumerate(snapshots):
        porosity = snapshot['phi'].flatten()
        
        if len(porosity) == 0:
            raise ValueError(
                f"❌ EMPTY DATA: Porosity array is empty at timestep {timesteps[i]}\n"
                f"   Check MRST porosity calculation.")
        
        porosity_avg[i] = np.mean(porosity)
        porosity_min[i] = np.min(porosity)
        porosity_max[i] = np.max(porosity)
        
        # Get time in days if available
        if 'time_days' in snapshot:
            time_days[i] = snapshot['time_days']
        else:
            time_days[i] = timesteps[i]  # Use timestep as fallback
    
    fig, ax = plt.subplots(1, 1, figsize=(14, 8))
    
    ax.plot(time_days, porosity_avg, 'g-', linewidth=4, label='Average Porosity', 
            marker='^', markersize=6)
    ax.fill_between(time_days, porosity_min, porosity_max, 
                    alpha=0.3, color='green', label='Min-Max Range')
    
    # Add statistics outside plot area
    initial_avg = porosity_avg[0]
    final_avg = porosity_avg[-1]
    porosity_change = final_avg - initial_avg
    porosity_change_percent = (porosity_change / initial_avg) * 100 if initial_avg != 0 else 0
    
    stats_text = (f'Porosity Statistics:\n'
                 f'Initial: {initial_avg:.4f}\n'
                 f'Final: {final_avg:.4f}\n'
                 f'Change: {porosity_change:+.4f}\n'
                 f'% Change: {porosity_change_percent:+.2f}%\n'
                 f'Time span: {time_days[0]:.1f} - {time_days[-1]:.1f} days')
    
    ax.text(1.02, 0.98, stats_text, transform=ax.transAxes, va='top', ha='left',
            fontsize=11, bbox=dict(boxstyle='round', facecolor='lightgreen', alpha=0.8))
    
    # Add data source info
    ax.text(1.02, 0.65, 'Source: MRST\nSnapshot data\n(Real simulation)', 
            transform=ax.transAxes, va='top', ha='left', fontsize=10,
            bbox=dict(boxstyle='round', facecolor='lightgreen', alpha=0.8))
    
    ax.set_xlabel('Time (days)', fontsize=14, fontweight='bold')
    ax.set_ylabel('Porosity (-)', fontsize=14, fontweight='bold')
    ax.set_title('E-3: Porosity Evolution\nQuestion: How much does porosity change due to compaction?', 
                 fontsize=16, fontweight='bold')
    
    # Move legend outside plot area
    ax.legend(loc='center left', bbox_to_anchor=(1.02, 0.5), fontsize=12)
    ax.grid(True, alpha=0.3)
    
    # Adjust layout
    plt.subplots_adjust(right=0.75)
    
    os.makedirs(os.path.dirname(output_path), exist_ok=True)
    plt.savefig(output_path, dpi=150, bbox_inches='tight')
    plt.close()
    
    print(f"✅ Porosity evolution plot saved: {output_path}")


def plot_permeability_evolution(output_path=None):
    """E-4: Permeability evolution - REQUIRES REAL MRST DATA
    Question: How much does permeability change due to compaction?
    """
    
    if output_path is None:
        output_path = (Path(__file__).parent.parent / 
                      "plots" / "E-4_permeability_evolution.png")
    
    # Load real MRST data - NO FALLBACK TO SYNTHETIC
    snapshots, timesteps = load_snapshots()
    n_steps = len(snapshots)
    
    # Check for required data in first snapshot
    if 'k' not in snapshots[0]:
        raise ValueError(
            f"❌ MISSING DATA: 'k' not found in snapshots\n"
            f"   Required variables: k (permeability)\n"
            f"   Available variables: {list(snapshots[0].keys())}\n"
            f"   Check MRST extract_snapshot.m export.")
    
    perm_avg = np.zeros(n_steps)
    perm_min = np.zeros(n_steps)
    perm_max = np.zeros(n_steps)
    time_days = np.zeros(n_steps)
    
    for i, snapshot in enumerate(snapshots):
        permeability = snapshot['k'].flatten()
        
        if len(permeability) == 0:
            raise ValueError(
                f"❌ EMPTY DATA: Permeability array is empty at timestep {timesteps[i]}\n"
                f"   Check MRST permeability calculation.")
        
        perm_avg[i] = np.mean(permeability)
        perm_min[i] = np.min(permeability)
        perm_max[i] = np.max(permeability)
        
        # Get time in days if available
        if 'time_days' in snapshot:
            time_days[i] = snapshot['time_days']
        else:
            time_days[i] = timesteps[i]  # Use timestep as fallback
    
    fig, ax = plt.subplots(1, 1, figsize=(14, 8))
    
    # Plot on log scale for permeability
    ax.semilogy(time_days, perm_avg, 'orange', linewidth=4, 
               label='Average Permeability', marker='d', markersize=6)
    ax.fill_between(time_days, perm_min, perm_max, 
                    alpha=0.3, color='orange', label='Min-Max Range')
    
    # Add statistics outside plot area
    initial_avg = perm_avg[0]
    final_avg = perm_avg[-1]
    perm_change = final_avg - initial_avg
    perm_change_percent = (perm_change / initial_avg) * 100 if initial_avg != 0 else 0
    
    stats_text = (f'Permeability Statistics:\n'
                 f'Initial: {initial_avg:.1f} mD\n'
                 f'Final: {final_avg:.1f} mD\n'
                 f'Change: {perm_change:+.1f} mD\n'
                 f'% Change: {perm_change_percent:+.2f}%\n'
                 f'Time span: {time_days[0]:.1f} - {time_days[-1]:.1f} days')
    
    ax.text(1.02, 0.98, stats_text, transform=ax.transAxes, va='top', ha='left',
            fontsize=11, bbox=dict(boxstyle='round', facecolor='lightyellow', alpha=0.8))
    
    # Add data source info
    ax.text(1.02, 0.65, 'Source: MRST\nSnapshot data\n(Real simulation)', 
            transform=ax.transAxes, va='top', ha='left', fontsize=10,
            bbox=dict(boxstyle='round', facecolor='lightgreen', alpha=0.8))
    
    ax.set_xlabel('Time (days)', fontsize=14, fontweight='bold')
    ax.set_ylabel('Permeability (mD)', fontsize=14, fontweight='bold')
    ax.set_title('E-4: Permeability Evolution\nQuestion: How much does permeability change due to compaction?', 
                 fontsize=16, fontweight='bold')
    
    # Move legend outside plot area
    ax.legend(loc='center left', bbox_to_anchor=(1.02, 0.5), fontsize=12)
    ax.grid(True, alpha=0.3)
    
    # Adjust layout
    plt.subplots_adjust(right=0.75)
    
    os.makedirs(os.path.dirname(output_path), exist_ok=True)
    plt.savefig(output_path, dpi=150, bbox_inches='tight')
    plt.close()
    
    print(f"✅ Permeability evolution plot saved: {output_path}")


def main():
    """Main function"""
    print("📈 Generating Category E: Global Evolution...")
    print("=" * 70)
    print("⚠️  IMPORTANT: This script requires real MRST simulation data.")
    print("   E-1, E-2, E-3, E-4: Require real MRST snapshots (no synthetic fallback)")
    print("=" * 70)
    
    # Generate all plots for Category E - will fail if data not available
    try:
        plot_pressure_evolution()
        plot_stress_evolution()
        plot_porosity_evolution()
        plot_permeability_evolution()
    except (FileNotFoundError, ValueError) as e:
        print(f"\n❌ CATEGORY E INCOMPLETE: {e}")
        print(f"   To fix: Run MRST simulation and ensure snapshot export")
        return False
    
    print("✅ Category E evolution plots complete!")
    return True


if __name__ == "__main__":
    main() 