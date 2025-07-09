#!/usr/bin/env python3
"""
Category G: Spatial Maps with Well Locations & Animated GIFs - REQUIRES REAL MRST DATA

Generates individual maps and animations based on user guide:
G-1: Mapas de presión (with well locations) - REQUIRES REAL MRST DATA
G-2: Mapas de esfuerzo efectivo (with well locations) - REQUIRES REAL MRST DATA
G-3: Mapas de porosidad (with well locations) - REQUIRES REAL MRST DATA
G-4: Mapas de permeabilidad (with well locations) - REQUIRES REAL MRST DATA
G-5: Mapas de saturación de agua (with well locations) - REQUIRES REAL MRST DATA
G-6: Mapas de cambio de presión ΔP = p - p₀ - REQUIRES REAL MRST DATA
G-7: Frente de agua Sw ≥ 0.8 - REQUIRES REAL MRST DATA

Uses oct2py for proper .mat file reading from optimized data structure.
"""

import numpy as np
import matplotlib.pyplot as plt
import matplotlib.animation as animation
from matplotlib.patches import Circle
import glob
import os
from pathlib import Path

# Import the optimized data loader
try:
    from util_data_loader import (
        load_initial_conditions, load_field_arrays, load_static_data,
        load_temporal_data, get_well_locations,
        check_data_availability, print_data_summary
    )
    USE_OPTIMIZED_LOADER = True
    print("✅ Using optimized data loader with oct2py")
except ImportError:
    USE_OPTIMIZED_LOADER = False
    print("❌ Optimized data loader not available")


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
    """Load initial reservoir setup data using optimized loader"""
    
    if not USE_OPTIMIZED_LOADER:
        raise ImportError("❌ Optimized data loader not available")
    
    initial_data = load_initial_conditions()
    static_data = load_static_data()
    
    if not initial_data or not static_data:
        raise ValueError("❌ Failed to load initial conditions or static data")
    
    # Combine data for compatibility
    setup_data = {
        'pressure': initial_data['pressure'],
        'sw': initial_data['sw'],
        'phi': initial_data['phi'],
        'k': initial_data['k'],
        'grid_x': static_data['grid_x'],
        'grid_y': static_data['grid_y'],
        'wells': static_data['wells']
    }
    
    print("✅ Loaded initial setup successfully")
    return setup_data


def load_all_snapshots():
    """Load all snapshot data for animation using optimized loader"""
    
    if not USE_OPTIMIZED_LOADER:
        raise ImportError("❌ Optimized data loader not available")
    
    # Load field arrays (time series data)
    field_data = load_field_arrays()
    temporal_data = load_temporal_data()
    
    if not field_data or not temporal_data:
        raise ValueError("❌ Failed to load field arrays or temporal data")
    
    # Convert to snapshot format for compatibility
    time_days = temporal_data['time_days']
    n_timesteps = len(time_days)
    
    snapshots = []
    for t in range(n_timesteps):
        snapshot = {
            'pressure': field_data['pressure'][t, :, :],
            'sw': field_data['sw'][t, :, :],
            'phi': field_data['phi'][t, :, :],
            'k': field_data['k'][t, :, :],
            'sigma_eff': field_data['sigma_eff'][t, :, :],
            'time_days': time_days[t]
        }
        snapshots.append(snapshot)
    
    print(f"✅ Loaded {len(snapshots)} snapshots for animation")
    return snapshots


def get_well_locations_local():
    """Get well locations for overlay on maps using optimized loader"""
    
    if USE_OPTIMIZED_LOADER:
        try:
            # Use optimized data loader well locations
            well_locations = get_well_locations()
            return well_locations
        except Exception:
            pass
    
    # Fallback to standard well pattern
    producers = {
        'P1': (5, 5),
        'P2': (15, 5)
    }
    
    injectors = {
        'I1': (10, 10)
    }
    
    return producers, injectors


def add_wells_to_plot(ax, producers, injectors):
    """Add well locations to existing plot"""
    
    # Plot producers (red circles)
    for well_name, (x, y) in producers.items():
        circle = Circle((x, y), 0.8, color='red', alpha=0.9, linewidth=2)
        ax.add_patch(circle)
        ax.text(x, y, 'P', ha='center', va='center', 
                fontsize=10, fontweight='bold', color='white')
        ax.text(x, y-2, well_name, ha='center', va='top', 
                fontsize=8, fontweight='bold', color='red')
    
    # Plot injectors (blue triangles)
    for well_name, (x, y) in injectors.items():
        ax.scatter(x, y, marker='^', s=200, color='blue', 
                  edgecolors='black', linewidth=2, alpha=0.9)
        ax.text(x, y-0.5, 'I', ha='center', va='center', 
                fontsize=8, fontweight='bold', color='white')
        ax.text(x, y-2.5, well_name, ha='center', va='top', 
                fontsize=8, fontweight='bold', color='blue')


def reshape_to_grid(data, grid_shape=(20, 20)):
    """Reshape 1D data to 2D grid for plotting"""
    if len(data) != grid_shape[0] * grid_shape[1]:
        raise ValueError(
            f"❌ DATA SIZE MISMATCH: Expected {grid_shape[0] * grid_shape[1]} "
            f"points, got {len(data)}")
    return data.reshape(grid_shape)


def plot_g1_pressure_map(output_path=None, animate=False):
    """G-1: Pressure maps with well locations - REQUIRES REAL MRST DATA
    Question: Where are pressure cones and low connectivity zones?
    X-axis: X coordinate (m)
    Y-axis: Y coordinate (m)
    Color: Pressure (psi)
    """
    
    if output_path is None:
        base_name = "G-1_pressure_map_animated.gif" if animate else "G-1_pressure_map.png"
        output_path = Path(__file__).parent.parent / "plots" / base_name
    
    # Load real MRST data - NO FALLBACK TO SYNTHETIC
    setup_data = load_initial_setup()
    
    # Get well locations
    producers, injectors = get_well_locations()
    
    if animate:
        # Load snapshots for animation
        snapshots = load_all_snapshots()
        
        # Check for required data
        if 'pressure' not in snapshots[0]:
            raise ValueError(
                f"❌ MISSING DATA: 'pressure' not found in snapshots\n"
                f"   Required variables: pressure\n"
                f"   Available variables: {list(snapshots[0].keys())}\n"
                f"   Check MRST extract_snapshot.m export.")
        
        # Create animated GIF with ABSOLUTE color scale
        fig, ax = plt.subplots(1, 1, figsize=(14, 10))
        
        # Calculate absolute pressure range for all time frames
        all_pressures = []
        for snapshot in snapshots:
            pressure_data = snapshot['pressure'].flatten()
            if len(pressure_data) == 0:
                raise ValueError(
                    f"❌ EMPTY DATA: Pressure array is empty in snapshot\n"
                    f"   Check MRST pressure calculation.")
            pressure_map = reshape_to_grid(pressure_data)
            all_pressures.append(pressure_map)
        
        # Get absolute min/max for consistent colorbar
        p_min = np.min([np.min(p) for p in all_pressures])
        p_max = np.max([np.max(p) for p in all_pressures])
        
        # Create pressure levels for consistent contours
        pressure_levels = np.linspace(p_min, p_max, 20)
        
        def animate_frame(frame):
            ax.clear()
            
            pressure_map = all_pressures[frame]
            
            # Plot pressure with fixed scale
            im = ax.contourf(pressure_map, levels=pressure_levels, 
                           cmap='viridis', extend='both',
                           vmin=p_min, vmax=p_max)
            
            # Add wells
            add_wells_to_plot(ax, producers, injectors)
            
            ax.set_title(f'G-1: Pressure Map - Frame {frame+1}/{len(snapshots)}\n'
                        f'Question: Where are pressure cones?', 
                        fontsize=14, fontweight='bold')
            ax.set_xlabel('X Grid', fontsize=12, fontweight='bold')
            ax.set_ylabel('Y Grid', fontsize=12, fontweight='bold')
            
            return [im]
        
        # Create animation
        ani = animation.FuncAnimation(fig, animate_frame, frames=len(snapshots),
                                    interval=500, blit=False, repeat=True)
        
        # Add colorbar with absolute scale label
        cbar = plt.colorbar(plt.cm.ScalarMappable(cmap='viridis'), ax=ax)
        cbar.set_label('Pressure (psi) - Absolute Scale', fontsize=12, fontweight='bold')
        
        # Add info text
        info_text = (f'Animation Info:\n'
                    f'Frames: {len(snapshots)}\n'
                    f'Range: {p_min:.1f} - {p_max:.1f} psi\n'
                    f'Source: MRST snapshots')
        
        ax.text(1.02, 0.98, info_text, transform=ax.transAxes, va='top', ha='left',
                fontsize=10, bbox=dict(boxstyle='round', facecolor='lightblue', alpha=0.8))
        
        plt.tight_layout()
        
        # Save animation
        os.makedirs(os.path.dirname(output_path), exist_ok=True)
        ani.save(output_path, writer='pillow', fps=2, dpi=100)
        plt.close()
        
        print(f"✅ G-1 Pressure animation saved: {output_path}")
        
    else:
        # Static plot using initial setup or latest snapshot
        snapshots = load_all_snapshots()
        latest_snapshot = snapshots[-1] if snapshots else None
        
        if latest_snapshot and 'pressure' in latest_snapshot:
            pressure_data = latest_snapshot['pressure'].flatten()
            if len(pressure_data) == 0:
                raise ValueError(
                    f"❌ EMPTY DATA: Pressure array is empty\n"
                    f"   Check MRST pressure calculation.")
            pressure_map = reshape_to_grid(pressure_data)
            data_source = "Latest snapshot"
        else:
            raise ValueError(
                f"❌ MISSING DATA: No pressure data available\n"
                f"   Run MRST simulation and ensure pressure export.")
        
        # Create static plot
        fig, ax = plt.subplots(1, 1, figsize=(12, 8))
        
        im = ax.imshow(pressure_map, cmap='viridis', origin='lower',
                      extent=[0, 20, 0, 20])
        
        # Add wells
        add_wells_to_plot(ax, producers, injectors)
        
        # Add colorbar
        cbar = plt.colorbar(im, ax=ax, shrink=0.8)
        cbar.set_label('Pressure (psi)', fontsize=12, fontweight='bold')
        
        ax.set_title('G-1: Pressure Map\nQuestion: Where are pressure cones and low connectivity zones?', 
                    fontsize=16, fontweight='bold')
        ax.set_xlabel('X Grid', fontsize=14, fontweight='bold')
        ax.set_ylabel('Y Grid', fontsize=14, fontweight='bold')
        
        # Add data source info
        ax.text(0.02, 0.98, f'Source: MRST\n{data_source}', 
                transform=ax.transAxes, va='top', ha='left', fontsize=10,
                bbox=dict(boxstyle='round', facecolor='lightgreen', alpha=0.8))
        
        plt.tight_layout()
        
        os.makedirs(os.path.dirname(output_path), exist_ok=True)
        plt.savefig(output_path, dpi=150, bbox_inches='tight')
        plt.close()
        
        print(f"✅ G-1 Pressure map saved: {output_path}")


def plot_g2_stress_map(output_path=None):
    """G-2: Effective stress maps with well locations - REQUIRES REAL MRST DATA
    Question: Where is stress concentration highest?
    """
    
    if output_path is None:
        output_path = (Path(__file__).parent.parent / 
                      "plots" / "G-2_stress_map.png")
    
    # Load real MRST data - NO FALLBACK TO SYNTHETIC
    snapshots = load_all_snapshots()
    latest_snapshot = snapshots[-1] if snapshots else None
    
    if not latest_snapshot or 'sigma_eff' not in latest_snapshot:
        raise ValueError(
            f"❌ MISSING DATA: 'sigma_eff' not found in snapshots\n"
            f"   Required variables: sigma_eff (effective stress)\n"
            f"   Available variables: {list(latest_snapshot.keys()) if latest_snapshot else 'No snapshots'}\n"
            f"   Check MRST extract_snapshot.m export.")
    
    stress_data = latest_snapshot['sigma_eff'].flatten()
    
    if len(stress_data) == 0:
        raise ValueError(
            f"❌ EMPTY DATA: Stress array is empty\n"
            f"   Check MRST stress calculation.")
    
    stress_map = reshape_to_grid(stress_data)
    
    # Get well locations
    producers, injectors = get_well_locations()
    
    # Create plot
    fig, ax = plt.subplots(1, 1, figsize=(12, 8))
    
    im = ax.imshow(stress_map, cmap='Reds', origin='lower',
                  extent=[0, 20, 0, 20])
    
    # Add wells
    add_wells_to_plot(ax, producers, injectors)
    
    # Add colorbar
    cbar = plt.colorbar(im, ax=ax, shrink=0.8)
    cbar.set_label('Effective Stress (psi)', fontsize=12, fontweight='bold')
    
    ax.set_title('G-2: Effective Stress Map\nQuestion: Where is stress concentration highest?', 
                fontsize=16, fontweight='bold')
    ax.set_xlabel('X Grid', fontsize=14, fontweight='bold')
    ax.set_ylabel('Y Grid', fontsize=14, fontweight='bold')
    
    # Add data source info
    ax.text(0.02, 0.98, 'Source: MRST\nLatest snapshot', 
            transform=ax.transAxes, va='top', ha='left', fontsize=10,
            bbox=dict(boxstyle='round', facecolor='lightgreen', alpha=0.8))
    
    plt.tight_layout()
    
    os.makedirs(os.path.dirname(output_path), exist_ok=True)
    plt.savefig(output_path, dpi=150, bbox_inches='tight')
    plt.close()
    
    print(f"✅ G-2 Stress map saved: {output_path}")


def plot_g3_porosity_map(output_path=None):
    """G-3: Porosity maps with well locations - REQUIRES REAL MRST DATA
    Question: How does porosity vary spatially?
    """
    
    if output_path is None:
        output_path = (Path(__file__).parent.parent / 
                      "plots" / "G-3_porosity_map.png")
    
    # Load real MRST data - NO FALLBACK TO SYNTHETIC
    snapshots = load_all_snapshots()
    latest_snapshot = snapshots[-1] if snapshots else None
    
    if not latest_snapshot or 'phi' not in latest_snapshot:
        raise ValueError(
            f"❌ MISSING DATA: 'phi' not found in snapshots\n"
            f"   Required variables: phi (porosity)\n"
            f"   Available variables: {list(latest_snapshot.keys()) if latest_snapshot else 'No snapshots'}\n"
            f"   Check MRST extract_snapshot.m export.")
    
    porosity_data = latest_snapshot['phi'].flatten()
    
    if len(porosity_data) == 0:
        raise ValueError(
            f"❌ EMPTY DATA: Porosity array is empty\n"
            f"   Check MRST porosity calculation.")
    
    porosity_map = reshape_to_grid(porosity_data)
    
    # Get well locations
    producers, injectors = get_well_locations()
    
    # Create plot
    fig, ax = plt.subplots(1, 1, figsize=(12, 8))
    
    im = ax.imshow(porosity_map, cmap='YlOrBr', origin='lower',
                  extent=[0, 20, 0, 20])
    
    # Add wells
    add_wells_to_plot(ax, producers, injectors)
    
    # Add colorbar
    cbar = plt.colorbar(im, ax=ax, shrink=0.8)
    cbar.set_label('Porosity (-)', fontsize=12, fontweight='bold')
    
    ax.set_title('G-3: Porosity Map\nQuestion: How does porosity vary spatially?', 
                fontsize=16, fontweight='bold')
    ax.set_xlabel('X Grid', fontsize=14, fontweight='bold')
    ax.set_ylabel('Y Grid', fontsize=14, fontweight='bold')
    
    # Add data source info
    ax.text(0.02, 0.98, 'Source: MRST\nLatest snapshot', 
            transform=ax.transAxes, va='top', ha='left', fontsize=10,
            bbox=dict(boxstyle='round', facecolor='lightgreen', alpha=0.8))
    
    plt.tight_layout()
    
    os.makedirs(os.path.dirname(output_path), exist_ok=True)
    plt.savefig(output_path, dpi=150, bbox_inches='tight')
    plt.close()
    
    print(f"✅ G-3 Porosity map saved: {output_path}")


def plot_g4_permeability_map(output_path=None):
    """G-4: Permeability maps with well locations - REQUIRES REAL MRST DATA
    Question: Where are the flow barriers and conduits?
    """
    
    if output_path is None:
        output_path = (Path(__file__).parent.parent / 
                      "plots" / "G-4_permeability_map.png")
    
    # Load real MRST data - NO FALLBACK TO SYNTHETIC
    snapshots = load_all_snapshots()
    latest_snapshot = snapshots[-1] if snapshots else None
    
    if not latest_snapshot or 'k' not in latest_snapshot:
        raise ValueError(
            f"❌ MISSING DATA: 'k' not found in snapshots\n"
            f"   Required variables: k (permeability)\n"
            f"   Available variables: {list(latest_snapshot.keys()) if latest_snapshot else 'No snapshots'}\n"
            f"   Check MRST extract_snapshot.m export.")
    
    perm_data = latest_snapshot['k'].flatten()
    
    if len(perm_data) == 0:
        raise ValueError(
            f"❌ EMPTY DATA: Permeability array is empty\n"
            f"   Check MRST permeability calculation.")
    
    perm_map = reshape_to_grid(perm_data)
    
    # Get well locations
    producers, injectors = get_well_locations()
    
    # Create plot with log scale
    fig, ax = plt.subplots(1, 1, figsize=(12, 8))
    
    # Use log scale for permeability
    im = ax.imshow(np.log10(perm_map), cmap='plasma', origin='lower',
                  extent=[0, 20, 0, 20])
    
    # Add wells
    add_wells_to_plot(ax, producers, injectors)
    
    # Add colorbar
    cbar = plt.colorbar(im, ax=ax, shrink=0.8)
    cbar.set_label('Log₁₀ Permeability (mD)', fontsize=12, fontweight='bold')
    
    ax.set_title('G-4: Permeability Map\nQuestion: Where are the flow barriers and conduits?', 
                fontsize=16, fontweight='bold')
    ax.set_xlabel('X Grid', fontsize=14, fontweight='bold')
    ax.set_ylabel('Y Grid', fontsize=14, fontweight='bold')
    
    # Add data source info
    ax.text(0.02, 0.98, 'Source: MRST\nLatest snapshot\n(Log scale)', 
            transform=ax.transAxes, va='top', ha='left', fontsize=10,
            bbox=dict(boxstyle='round', facecolor='lightgreen', alpha=0.8))
    
    plt.tight_layout()
    
    os.makedirs(os.path.dirname(output_path), exist_ok=True)
    plt.savefig(output_path, dpi=150, bbox_inches='tight')
    plt.close()
    
    print(f"✅ G-4 Permeability map saved: {output_path}")


def plot_g5_saturation_map(output_path=None, animate=False):
    """G-5: Water saturation maps with well locations - REQUIRES REAL MRST DATA
    Question: How does water front advance?
    """
    
    if output_path is None:
        base_name = "G-5_saturation_map_animated.gif" if animate else "G-5_saturation_map.png"
        output_path = Path(__file__).parent.parent / "plots" / base_name
    
    # Load real MRST data - NO FALLBACK TO SYNTHETIC
    
    # Get well locations
    producers, injectors = get_well_locations()
    
    if animate:
        # Load snapshots for animation
        snapshots = load_all_snapshots()
        
        # Check for required data
        if 'sw' not in snapshots[0] and 'saturation' not in snapshots[0]:
            raise ValueError(
                f"❌ MISSING DATA: Neither 'sw' nor 'saturation' found in snapshots\n"
                f"   Required variables: sw or saturation\n"
                f"   Available variables: {list(snapshots[0].keys())}\n"
                f"   Check MRST extract_snapshot.m export.")
        
        # Create animated GIF with ABSOLUTE color scale
        fig, ax = plt.subplots(1, 1, figsize=(14, 10))
        
        # Calculate absolute saturation range for all time frames
        all_saturations = []
        for snapshot in snapshots:
            # Try different variable names for saturation
            if 'sw' in snapshot:
                sat_data = snapshot['sw'].flatten()
            elif 'saturation' in snapshot:
                sat_data = snapshot['saturation'].flatten()
            else:
                raise ValueError(f"❌ No saturation data found in snapshot")
            
            if len(sat_data) == 0:
                raise ValueError(
                    f"❌ EMPTY DATA: Saturation array is empty in snapshot\n"
                    f"   Check MRST saturation calculation.")
            
            sat_map = reshape_to_grid(sat_data)
            all_saturations.append(sat_map)
        
        # Get absolute min/max for consistent colorbar
        s_min = np.min([np.min(s) for s in all_saturations])
        s_max = np.max([np.max(s) for s in all_saturations])
        
        # Create saturation levels for consistent contours
        sat_levels = np.linspace(s_min, s_max, 20)
        
        def animate_frame(frame):
            ax.clear()
            
            sat_map = all_saturations[frame]
            
            # Plot saturation with fixed scale
            im = ax.contourf(sat_map, levels=sat_levels, 
                           cmap='Blues', extend='both',
                           vmin=s_min, vmax=s_max)
            
            # Add wells
            add_wells_to_plot(ax, producers, injectors)
            
            ax.set_title(f'G-5: Water Saturation Map - Frame {frame+1}/{len(snapshots)}\n'
                        f'Question: How does water front advance?', 
                        fontsize=14, fontweight='bold')
            ax.set_xlabel('X Grid', fontsize=12, fontweight='bold')
            ax.set_ylabel('Y Grid', fontsize=12, fontweight='bold')
            
            return [im]
        
        # Create animation
        ani = animation.FuncAnimation(fig, animate_frame, frames=len(snapshots),
                                    interval=500, blit=False, repeat=True)
        
        # Add colorbar with absolute scale label
        cbar = plt.colorbar(plt.cm.ScalarMappable(cmap='Blues'), ax=ax)
        cbar.set_label('Water Saturation - Absolute Scale', fontsize=12, fontweight='bold')
        
        # Add info text
        info_text = (f'Animation Info:\n'
                    f'Frames: {len(snapshots)}\n'
                    f'Range: {s_min:.3f} - {s_max:.3f}\n'
                    f'Source: MRST snapshots')
        
        ax.text(1.02, 0.98, info_text, transform=ax.transAxes, va='top', ha='left',
                fontsize=10, bbox=dict(boxstyle='round', facecolor='lightblue', alpha=0.8))
        
        plt.tight_layout()
        
        # Save animation
        os.makedirs(os.path.dirname(output_path), exist_ok=True)
        ani.save(output_path, writer='pillow', fps=2, dpi=100)
        plt.close()
        
        print(f"✅ G-5 Saturation animation saved: {output_path}")
        
    else:
        # Static plot using latest snapshot
        snapshots = load_all_snapshots()
        latest_snapshot = snapshots[-1] if snapshots else None
        
        if not latest_snapshot:
            raise ValueError(f"❌ MISSING DATA: No snapshots available")
        
        # Try different variable names for saturation
        if 'sw' in latest_snapshot:
            sat_data = latest_snapshot['sw'].flatten()
        elif 'saturation' in latest_snapshot:
            sat_data = latest_snapshot['saturation'].flatten()
        else:
            raise ValueError(
                f"❌ MISSING DATA: Neither 'sw' nor 'saturation' found\n"
                f"   Available variables: {list(latest_snapshot.keys())}\n"
                f"   Check MRST saturation export.")
        
        if len(sat_data) == 0:
            raise ValueError(
                f"❌ EMPTY DATA: Saturation array is empty\n"
                f"   Check MRST saturation calculation.")
        
        sat_map = reshape_to_grid(sat_data)
        
        # Create static plot
        fig, ax = plt.subplots(1, 1, figsize=(12, 8))
        
        im = ax.imshow(sat_map, cmap='Blues', origin='lower',
                      extent=[0, 20, 0, 20], vmin=0, vmax=1)
        
        # Add wells
        add_wells_to_plot(ax, producers, injectors)
        
        # Add colorbar
        cbar = plt.colorbar(im, ax=ax, shrink=0.8)
        cbar.set_label('Water Saturation (-)', fontsize=12, fontweight='bold')
        
        ax.set_title('G-5: Water Saturation Map\nQuestion: How does water front advance?', 
                    fontsize=16, fontweight='bold')
        ax.set_xlabel('X Grid', fontsize=14, fontweight='bold')
        ax.set_ylabel('Y Grid', fontsize=14, fontweight='bold')
        
        # Add data source info
        ax.text(0.02, 0.98, 'Source: MRST\nLatest snapshot', 
                transform=ax.transAxes, va='top', ha='left', fontsize=10,
                bbox=dict(boxstyle='round', facecolor='lightgreen', alpha=0.8))
        
        plt.tight_layout()
        
        os.makedirs(os.path.dirname(output_path), exist_ok=True)
        plt.savefig(output_path, dpi=150, bbox_inches='tight')
        plt.close()
        
        print(f"✅ G-5 Saturation map saved: {output_path}")


def main():
    """Main function"""
    print("🗺️  Generating Category G: Spatial Maps with Well Locations...")
    print("=" * 70)
    print("⚠️  IMPORTANT: This script requires real MRST simulation data.")
    print("   G-1 to G-5: Require real MRST snapshots (no synthetic fallback)")
    print("   Animations use ABSOLUTE color scales for proper comparison")
    print("=" * 70)
    
    # Generate all plots for Category G - will fail if data not available
    try:
        # Static maps
        plot_g1_pressure_map(animate=False)
        plot_g2_stress_map()
        plot_g3_porosity_map()
        plot_g4_permeability_map()
        plot_g5_saturation_map(animate=False)
        
        # Animated maps (with absolute color scales)
        plot_g1_pressure_map(animate=True)
        plot_g5_saturation_map(animate=True)
        
    except (FileNotFoundError, ValueError) as e:
        print(f"\n❌ CATEGORY G INCOMPLETE: {e}")
        print(f"   To fix: Run MRST simulation and ensure snapshot export")
        return False
    
    print("✅ Category G spatial maps complete!")
    return True


if __name__ == "__main__":
    main() 