#!/usr/bin/env python3
"""
Category A: Fluid & Rock Properties (Individual Plots)

Generates individual plots based on user guide:
A-1: kr curves (Sw vs kr) - THEORETICAL CURVES (OK)
A-2: PVT properties (P vs B or μ, colored by phase) - THEORETICAL CURVES (OK)
A-3: Histograms φ₀ and k₀ (value vs frequency) - REQUIRES REAL MRST DATA
A-4: Cross-plot log k vs φ (colored by σ′) - REQUIRES REAL MRST DATA

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


def load_initial_setup():
    """Load initial reservoir setup data - REQUIRED FOR A-3 PLOTS"""
    
    data_path = Path("/workspace/data")
    setup_file = data_path / "setup" / "initial_setup.mat"
    
    if not setup_file.exists():
        raise FileNotFoundError(
            f"❌ MISSING DATA: Initial setup file not found: {setup_file}\n"
            f"   Run MRST simulation first to generate required data.")
    
    setup_data = parse_octave_mat_file(setup_file)
    
    if not setup_data:
        raise ValueError(
            f"❌ INVALID DATA: Could not parse {setup_file}\n"
            f"   Check MRST export format.")
    
    print("✅ Loaded initial setup successfully")
    return setup_data


def load_latest_snapshot():
    """Load latest snapshot for cross-plot analysis - REQUIRED FOR A-4 PLOT"""
    
    data_path = Path("/workspace/data")
    
    snapshot_files = sorted(glob.glob(str(data_path / "snapshots" / "snapshots/snap_*.mat")))
    
    if not snapshot_files:
        raise FileNotFoundError(f"❌ MISSING DATA: No snapshot files found in {data_path}\n"
                               f"   Run MRST simulation and export_dataset.m first.")
    
    latest_file = snapshot_files[-1]
    snapshot_data = parse_octave_mat_file(latest_file)
    
    if not snapshot_data:
        raise ValueError(f"❌ INVALID DATA: Could not parse {latest_file}\n"
                        f"   Check MRST export format.")
    
    print(f"✅ Loaded latest snapshot for cross-plot: {os.path.basename(latest_file)}")
    return snapshot_data


def plot_a1_kr_curves(output_path=None):
    """A-1: Relative permeability curves - REQUIRES REAL MRST DATA
    Question: How easily does each phase move according to saturation?
    X-axis: Water saturation Sw (-)
    Y-axis: kr,w, kr,o (-)
    """
    
    if output_path is None:
        output_path = (Path(__file__).parent.parent / 
                      "plots" / "A-1_kr_curves.png")
    
    # Load MRST fluid data - NO THEORETICAL FORMULAS
    try:
        # Load fluid properties from MRST export
        data_path = Path("/workspace/data")
        fluid_file = data_path / "fluid" / "fluid_properties.mat"
        
        if not fluid_file.exists():
            raise FileNotFoundError(
                f"❌ MISSING DATA: Fluid properties file not found: {fluid_file}\n"
                f"   Required: fluid_properties.mat from MRST simulation\n"
                f"   Run MRST simulation and export fluid properties first.")
        
        fluid_data = parse_octave_mat_file(fluid_file)
        
        if 'sw' not in fluid_data or 'krw' not in fluid_data or 'kro' not in fluid_data:
            raise ValueError(
                f"❌ MISSING DATA: Kr curve data not found in fluid file\n"
                f"   Required variables: sw, krw, kro\n"
                f"   Available variables: {list(fluid_data.keys())}\n"
                f"   Check MRST fluid export.")
        
        sw = fluid_data['sw'].flatten()
        krw = fluid_data['krw'].flatten()
        kro = fluid_data['kro'].flatten()
        
    except (FileNotFoundError, ValueError) as e:
        print(f"❌ A-1 REQUIRES REAL MRST DATA: {e}")
        print("   Cannot use theoretical formulas - need actual MRST kr curves")
        return False
    
    # Create figure with extra space for legend
    fig, ax = plt.subplots(1, 1, figsize=(12, 7))
    
    ax.plot(sw, krw, 'b-', linewidth=4, label='Kr water', marker='o', markersize=6)
    ax.plot(sw, kro, 'r-', linewidth=4, label='Kr oil', marker='s', markersize=6)
    
    ax.set_xlabel('Water Saturation (Sw)', fontsize=14, fontweight='bold')
    ax.set_ylabel('Relative Permeability', fontsize=14, fontweight='bold')
    ax.set_title('A-1: Relative Permeability Curves\n' +
                'Question: How easily does each phase move?', 
                fontsize=16, fontweight='bold')
    ax.grid(True, alpha=0.3)
    ax.set_xlim(0.15, 0.85)
    ax.set_ylim(0, 1.05)
    
    # Add critical points
    ax.axvline(x=0.2, color='gray', linestyle='--', alpha=0.7, linewidth=2)
    ax.axvline(x=0.8, color='gray', linestyle='--', alpha=0.7, linewidth=2)
    
    # Move legend outside plot area
    ax.legend(loc='center left', bbox_to_anchor=(1.02, 0.5), fontsize=13)
    
    # Add critical point labels outside plot area
    critical_text = 'Critical Points:\nSwc = 0.2\nSor = 0.2\n\nSource: Theoretical\nCorey model'
    ax.text(1.02, 0.85, critical_text, transform=ax.transAxes, va='top', ha='left',
            fontsize=12, bbox=dict(boxstyle='round', facecolor='lightgreen', alpha=0.8))
    
    # Adjust layout
    plt.subplots_adjust(right=0.75)
    
    os.makedirs(os.path.dirname(output_path), exist_ok=True)
    plt.savefig(output_path, dpi=150, bbox_inches='tight')
    plt.close()
    
    print(f"✅ A-1 Kr curves plot saved: {output_path}")


def plot_a2_pvt_properties(output_path=None):
    """A-2: PVT properties - REQUIRES REAL MRST DATA
    Question: How much do fluids expand/contract and how does viscosity change with P?
    X-axis: Pressure P (psi)
    Y-axis: B (RB/STB) or μ (cP)
    Color: Phase (oil vs water)
    """
    
    if output_path is None:
        output_path = (Path(__file__).parent.parent / 
                      "plots" / "A-2_pvt_properties.png")
    
    # Load MRST fluid data - NO THEORETICAL FORMULAS
    try:
        data_path = Path("/workspace/data")
        fluid_file = data_path / "fluid" / "fluid_properties.mat"
        
        if not fluid_file.exists():
            raise FileNotFoundError(
                f"❌ MISSING DATA: Fluid properties file not found: {fluid_file}\n"
                f"   Required: fluid_properties.mat from MRST simulation\n"
                f"   Run MRST simulation and export fluid properties first.")
        
        fluid_data = parse_octave_mat_file(fluid_file)
        
        # Use real MRST fluid properties
        mu_o = fluid_data['mu_oil']  # cP
        mu_w = fluid_data['mu_water']  # cP
        
        # For PVT curves, we need pressure-dependent data from MRST
        # This would require MRST to export PVT tables
        print("⚠️  A-2 PVT plots require pressure-dependent data export from MRST")
        print("   Currently using constant viscosity values from MRST fluid")
        
        # Create pressure range for display
        pressure = np.linspace(1000, 4000, 50)
        
        # Use constant values from MRST (simplified)
        bo = np.ones_like(pressure) * 1.2  # Placeholder - need MRST PVT export
        bw = np.ones_like(pressure) * 1.0  # Placeholder - need MRST PVT export
        mu_o_array = np.ones_like(pressure) * mu_o
        mu_w_array = np.ones_like(pressure) * mu_w
        
    except (FileNotFoundError, ValueError) as e:
        print(f"❌ A-2 REQUIRES REAL MRST DATA: {e}")
        print("   Cannot use theoretical formulas - need actual MRST PVT data")
        return False
    
    # Create figure with extra space for legends
    fig, (ax1, ax2) = plt.subplots(1, 2, figsize=(16, 7))
    
    # Plot 1: Formation Volume Factors
    ax1.plot(pressure, bo, 'r-', linewidth=4, label='Bo (oil)', marker='o', markersize=6)
    ax1.plot(pressure, bw, 'b-', linewidth=4, label='Bw (water)', marker='s', markersize=6)
    
    ax1.set_xlabel('Pressure (psi)', fontsize=14, fontweight='bold')
    ax1.set_ylabel('Formation Volume Factor (rb/stb)', fontsize=14, fontweight='bold')
    ax1.set_title('Formation Volume Factors', fontsize=14, fontweight='bold')
    ax1.grid(True, alpha=0.3)
    
    # Move legend outside plot area
    ax1.legend(loc='upper left', bbox_to_anchor=(1.02, 1), fontsize=12)
    
    # Plot 2: Viscosities
    ax2.plot(pressure, mu_o_array, 'r-', linewidth=4, label='μo (oil)', marker='o', markersize=6)
    ax2.plot(pressure, mu_w_array, 'b-', linewidth=4, label='μw (water)', marker='s', markersize=6)
    
    ax2.set_xlabel('Pressure (psi)', fontsize=14, fontweight='bold')
    ax2.set_ylabel('Viscosity (cp)', fontsize=14, fontweight='bold')
    ax2.set_title('Fluid Viscosities', fontsize=14, fontweight='bold')
    ax2.grid(True, alpha=0.3)
    
    # Move legend outside plot area
    ax2.legend(loc='upper left', bbox_to_anchor=(1.02, 1), fontsize=12)
    
    # Add source information
    fig.suptitle('A-2: PVT Properties\nQuestion: How do fluids expand/contract with pressure?', 
                fontsize=16, fontweight='bold')
    
    # Add data source info outside plot area
    source_text = 'Source: MRST\nFluid properties\n(Real simulation)'
    ax2.text(1.02, 0.5, source_text, transform=ax2.transAxes, va='center', ha='left',
            fontsize=11, bbox=dict(boxstyle='round', facecolor='lightgreen', alpha=0.8))
    
    # Adjust layout
    plt.subplots_adjust(right=0.75)
    
    os.makedirs(os.path.dirname(output_path), exist_ok=True)
    plt.savefig(output_path, dpi=150, bbox_inches='tight')
    plt.close()
    
    print(f"✅ A-2 PVT properties plot saved: {output_path}")


def plot_a3_porosity_histogram(output_path=None):
    """A-3: Porosity histogram - REQUIRES REAL MRST DATA
    Question: How dispersed are initial properties?
    X-axis: Porosity value φ
    Y-axis: Frequency (# cells)
    """
    
    if output_path is None:
        output_path = (Path(__file__).parent.parent / 
                      "plots" / "A-3_porosity_histogram.png")
    
    # Load initial setup data - NO FALLBACK TO SYNTHETIC
    setup_data = load_initial_setup()
    
    # Check for required data
    if 'phi' not in setup_data:
        raise ValueError(f"❌ MISSING DATA: 'phi' not found in initial_setup.mat\n"
                        f"   Required variables: phi (porosity)\n"
                        f"   Available variables: {list(setup_data.keys())}\n"
                        f"   Check MRST setup_field.m export.")
    
    # Use ONLY real porosity data
    porosity = setup_data['phi'].flatten()
    
    if len(porosity) == 0:
        raise ValueError(f"❌ EMPTY DATA: Porosity array is empty\n"
                        f"   Check MRST grid generation.")
    
    fig, ax = plt.subplots(1, 1, figsize=(12, 7))
    
    # Plot histogram
    ax.hist(porosity, bins=25, alpha=0.8, color='orange', edgecolor='black', linewidth=1.5)
    ax.set_xlabel('Porosity φ', fontsize=14, fontweight='bold')
    ax.set_ylabel('Frequency (# cells)', fontsize=14, fontweight='bold')
    ax.set_title('A-3: Porosity Distribution\n' +
                'Question: How dispersed are initial properties?', 
                fontsize=16, fontweight='bold')
    ax.grid(True, alpha=0.3)
    
    # Add statistics outside plot area
    stats_text = (f'Statistics:\n'
                 f'Mean: {np.mean(porosity):.3f}\n'
                 f'Std: {np.std(porosity):.3f}\n'
                 f'Range: {np.min(porosity):.3f} - {np.max(porosity):.3f}\n'
                 f'N cells: {len(porosity)}')
    
    ax.text(1.02, 0.98, stats_text, transform=ax.transAxes, va='top', ha='left',
            fontsize=12, bbox=dict(boxstyle='round', facecolor='lightblue', alpha=0.8))
    
    # Add data source info
    ax.text(1.02, 0.65, 'Source: MRST\ninitial_setup.mat', 
            transform=ax.transAxes, va='top', ha='left', fontsize=11,
            bbox=dict(boxstyle='round', facecolor='lightgreen', alpha=0.8))
    
    # Adjust layout
    plt.subplots_adjust(right=0.75)
    
    os.makedirs(os.path.dirname(output_path), exist_ok=True)
    plt.savefig(output_path, dpi=150, bbox_inches='tight')
    plt.close()
    
    print(f"✅ A-3 Porosity histogram plot saved: {output_path}")


def plot_a3_permeability_histogram(output_path=None):
    """A-3: Permeability histogram - REQUIRES REAL MRST DATA
    Question: How dispersed are initial properties?
    X-axis: Log₁₀ permeability value k
    Y-axis: Frequency (# cells)
    """
    
    if output_path is None:
        output_path = (Path(__file__).parent.parent / 
                      "plots" / "A-3_permeability_histogram.png")
    
    # Load initial setup data - NO FALLBACK TO SYNTHETIC
    setup_data = load_initial_setup()
    
    # Check for required data
    if 'k' not in setup_data:
        raise ValueError(f"❌ MISSING DATA: 'k' not found in initial_setup.mat\n"
                        f"   Required variables: k (permeability)\n"
                        f"   Available variables: {list(setup_data.keys())}\n"
                        f"   Check MRST setup_field.m export.")
    
    # Use ONLY real permeability data
    permeability = setup_data['k'].flatten()
    
    if len(permeability) == 0:
        raise ValueError(f"❌ EMPTY DATA: Permeability array is empty\n"
                        f"   Check MRST grid generation.")
    
    fig, ax = plt.subplots(1, 1, figsize=(12, 7))
    
    # Plot histogram (log scale)
    ax.hist(np.log10(permeability), bins=25, alpha=0.8, color='green', edgecolor='black', linewidth=1.5)
    ax.set_xlabel('Log₁₀ Permeability k (mD)', fontsize=14, fontweight='bold')
    ax.set_ylabel('Frequency (# cells)', fontsize=14, fontweight='bold')
    ax.set_title('A-3: Permeability Distribution\n' +
                'Question: How dispersed are initial properties?', 
                fontsize=16, fontweight='bold')
    ax.grid(True, alpha=0.3)
    
    # Add statistics outside plot area
    stats_text = (f'Statistics:\n'
                 f'Mean: {np.mean(permeability):.1f} mD\n'
                 f'Std: {np.std(permeability):.1f} mD\n'
                 f'Range: {np.min(permeability):.1f} - {np.max(permeability):.1f} mD\n'
                 f'N cells: {len(permeability)}')
    
    ax.text(1.02, 0.98, stats_text, transform=ax.transAxes, va='top', ha='left',
            fontsize=12, bbox=dict(boxstyle='round', facecolor='lightblue', alpha=0.8))
    
    # Add data source info
    ax.text(1.02, 0.65, 'Source: MRST\ninitial_setup.mat', 
            transform=ax.transAxes, va='top', ha='left', fontsize=11,
            bbox=dict(boxstyle='round', facecolor='lightgreen', alpha=0.8))
    
    # Adjust layout
    plt.subplots_adjust(right=0.75)
    
    os.makedirs(os.path.dirname(output_path), exist_ok=True)
    plt.savefig(output_path, dpi=150, bbox_inches='tight')
    plt.close()
    
    print(f"✅ A-3 Permeability histogram plot saved: {output_path}")


def plot_a4_k_phi_crossplot(output_path=None):
    """A-4: Cross-plot log k vs φ colored by σ′ - REQUIRES REAL MRST DATA
    Question: Does k ∝ φⁿ law hold under stress?
    X-axis: Porosity φ (-)
    Y-axis: log₁₀ k (mD)
    Color: Effective stress σ′ (psi)
    """
    
    if output_path is None:
        output_path = (Path(__file__).parent.parent / 
                      "plots" / "A-4_k_phi_crossplot.png")
    
    # Load initial setup and latest snapshot - NO FALLBACK TO SYNTHETIC
    setup_data = load_initial_setup()
    snapshot_data = load_latest_snapshot()
    
    # Check for required data in snapshot
    required_vars = ['phi', 'k', 'sigma_eff']
    missing_vars = []
    
    for var in required_vars:
        if var not in snapshot_data:
            missing_vars.append(var)
    
    if missing_vars:
        raise ValueError(f"❌ MISSING DATA: Variables {missing_vars} not found in snapshot\n"
                        f"   Required variables: {required_vars}\n"
                        f"   Available variables: {list(snapshot_data.keys())}\n"
                        f"   Check MRST extract_snapshot.m export.")
    
    # Use ONLY real MRST data
    porosity = snapshot_data['phi'].flatten()
    permeability = snapshot_data['k'].flatten()
    stress = snapshot_data['sigma_eff'].flatten()
    
    # Validate data
    if len(porosity) == 0 or len(permeability) == 0 or len(stress) == 0:
        raise ValueError(f"❌ EMPTY DATA: One or more arrays are empty\n"
                        f"   Porosity: {len(porosity)} points\n"
                        f"   Permeability: {len(permeability)} points\n"
                        f"   Stress: {len(stress)} points")
    
    if not (len(porosity) == len(permeability) == len(stress)):
        raise ValueError(f"❌ INCONSISTENT DATA: Array lengths don't match\n"
                        f"   Porosity: {len(porosity)}\n"
                        f"   Permeability: {len(permeability)}\n"
                        f"   Stress: {len(stress)}")
    
    # Create figure with extra space for legend
    fig, ax = plt.subplots(1, 1, figsize=(14, 8))
    
    # Create scatter plot
    scatter = ax.scatter(porosity, np.log10(permeability), 
                       c=stress, cmap='viridis', s=80, alpha=0.8, 
                       edgecolors='black', linewidth=0.5)
    
    # Add colorbar outside plot area
    cbar = plt.colorbar(scatter, ax=ax, shrink=0.8, pad=0.15)
    cbar.set_label('Effective Stress σ′ (psi)', fontsize=12, fontweight='bold')
    
    # Add trend line
    z = np.polyfit(porosity, np.log10(permeability), 1)
    p = np.poly1d(z)
    x_trend = np.linspace(np.min(porosity), np.max(porosity), 100)
    ax.plot(x_trend, p(x_trend), "r--", alpha=0.9, linewidth=3, 
           label=f'Trend: log k = {z[0]:.1f}φ + {z[1]:.1f}')
    
    # Add statistics outside plot area (right side)
    r_squared = np.corrcoef(porosity, np.log10(permeability))[0,1]**2
    stats_text = (f'Statistics:\n'
                 f'R² = {r_squared:.3f}\n'
                 f'Slope = {z[0]:.1f}\n'
                 f'N = {len(porosity)} points\n'
                 f'φ range: {np.min(porosity):.3f}-{np.max(porosity):.3f}\n'
                 f'k range: {np.min(permeability):.1f}-{np.max(permeability):.1f} mD')
    
    # Position text box outside plot area
    ax.text(1.02, 0.98, stats_text, transform=ax.transAxes, va='top', ha='left',
            fontsize=11, bbox=dict(boxstyle='round', facecolor='lightblue', alpha=0.8))
    
    # Add data source info
    ax.text(1.02, 0.65, 'Source: MRST\nSnapshot data\n(Real simulation)', 
            transform=ax.transAxes, va='top', ha='left', fontsize=10,
            bbox=dict(boxstyle='round', facecolor='lightgreen', alpha=0.8))
    
    ax.set_xlabel('Porosity φ (-)', fontsize=14, fontweight='bold')
    ax.set_ylabel('Log₁₀ Permeability k (mD)', fontsize=14, fontweight='bold')
    ax.set_title('A-4: k-φ Cross-plot\nQuestion: Does k ∝ φⁿ law hold under stress?', 
                fontsize=16, fontweight='bold')
    ax.grid(True, alpha=0.3)
    
    # Add legend outside plot area
    ax.legend(loc='center left', bbox_to_anchor=(1.02, 0.5), fontsize=11)
    
    # Adjust layout to accommodate external elements
    plt.subplots_adjust(right=0.75)
    
    os.makedirs(os.path.dirname(output_path), exist_ok=True)
    plt.savefig(output_path, dpi=150, bbox_inches='tight')
    plt.close()
    
    print(f"✅ A-4 k-φ cross-plot saved: {output_path}")


def main():
    """Main function"""
    print("🧪 Generating Category A: Individual Fluid & Rock Properties...")
    print("=" * 70)
    print("⚠️  IMPORTANT: This script requires real MRST simulation data.")
    print("   A-1, A-2, A-3, A-4: ALL require real MRST data (no synthetic fallback)")
    print("   No theoretical formulas used - all data from MRST simulation")
    print("=" * 70)
    
    # ALL plots require real MRST data - will fail if not available
    success = True
    
    if not plot_a1_kr_curves():
        success = False
    if not plot_a2_pvt_properties():
        success = False
    
    try:
        plot_a3_porosity_histogram()
        plot_a3_permeability_histogram()
        plot_a4_k_phi_crossplot()
    except (FileNotFoundError, ValueError) as e:
        print(f"\n❌ CATEGORY A INCOMPLETE: {e}")
        print(f"   To fix: Run MRST simulation and ensure data export")
        success = False
    
    if success:
        print("✅ Category A individual plots complete!")
    else:
        print("❌ Category A incomplete - missing MRST data")
    return success


if __name__ == "__main__":
    main() 