#!/usr/bin/env python3
"""
Category B: Initial Conditions - REQUIRES REAL MRST DATA

Generates individual plots for initial reservoir conditions:
B-1: Initial water saturation distribution map - REQUIRES REAL DATA
B-2: Initial pressure distribution map - REQUIRES REAL DATA

IMPORTANT: This script now requires real MRST simulation data.
No synthetic data generation. Will fail if data is not available.
Uses oct2py for proper .mat file reading.
"""

import numpy as np
import matplotlib.pyplot as plt
import os
from pathlib import Path

# Import the new optimized data loader
try:
    from util_data_loader import (
        load_initial_conditions, check_data_availability, 
        print_data_summary
    )
    USE_OPTIMIZED_LOADER = True
    print("✅ Using optimized data loader with oct2py")
except ImportError:
    USE_OPTIMIZED_LOADER = False
    print("❌ Optimized data loader not available")


def reshape_to_grid(data, grid_shape=(20, 20)):
    """Reshape 1D data to 2D grid"""
    if len(data) != grid_shape[0] * grid_shape[1]:
        raise ValueError(
            "❌ DATA SIZE MISMATCH: Expected {} points, got {}".format(
                grid_shape[0] * grid_shape[1], len(data)))
    return data.reshape(grid_shape)


def plot_sw_initial(output_path=None):
    """B-1: Initial water saturation distribution - REQUIRES REAL MRST DATA
    Question: Water patches causing early breakthrough?
    """
    
    if output_path is None:
        output_path = (Path(__file__).parent.parent / 
                      "plots" / "B-1_sw_initial.png")
    
    if not USE_OPTIMIZED_LOADER:
        print("❌ B-1 requires optimized data loader with oct2py")
        return False
    
    # Load initial setup data using oct2py
    try:
        initial_data = load_initial_conditions()
        
        # Check for required data (handle both old and new formats)
        sw_data = None
        if 'sw_init' in initial_data:
            sw_data = initial_data['sw_init']
        elif 'sw' in initial_data:
            sw_data = initial_data['sw']
        else:
            raise ValueError(
                "❌ MISSING DATA: Water saturation not found in initial data\n"
                "   Required variables: 'sw_init' or 'sw'\n"
                "   Available variables: {}\n"
                "   Check MRST initial conditions setup.".format(
                    list(initial_data.keys())))
        
        # Handle both 2D and 1D data
        if len(sw_data.shape) == 2:
            sw_map = sw_data  # Already 2D
        else:
            sw_init = sw_data.flatten()
            if len(sw_init) == 0:
                raise ValueError(
                    f"❌ EMPTY DATA: Initial water saturation array is empty\n"
                    f"   Check MRST initial conditions generation.")
            sw_map = reshape_to_grid(sw_init)
        
    except Exception as e:
        print(f"❌ B-1 REQUIRES REAL MRST DATA: {e}")
        return False
    
    # Create figure with extra space for legends/info
    fig, ax = plt.subplots(1, 1, figsize=(14, 8))
    
    im = ax.imshow(sw_map, cmap='Blues', origin='lower', 
                   extent=[0, 20, 0, 20], vmin=0.1, vmax=0.9)
    
    ax.set_title('B-1: Initial Water Saturation Distribution\n' +
                'Question: Water patches causing early breakthrough?', 
                fontsize=16, fontweight='bold')
    ax.set_xlabel('X Grid', fontsize=14, fontweight='bold')
    ax.set_ylabel('Y Grid', fontsize=14, fontweight='bold')
    
    # Add colorbar outside plot area
    cbar = plt.colorbar(im, ax=ax, shrink=0.8, pad=0.15)
    cbar.set_label('Water Saturation (Sw)', fontsize=12, fontweight='bold')
    
    # Add well locations
    # Producers (red circles)
    producers = [(5, 5), (15, 5), (5, 15), (15, 15)]
    for i, (x, y) in enumerate(producers):
        ax.scatter(x, y, c='red', s=200, marker='o', 
                  edgecolors='black', linewidth=2)
        ax.text(x, y, f'P{i+1}', ha='center', va='center', fontsize=10, 
                fontweight='bold', color='white')
    
    # Injectors (blue triangles)
    injectors = [(10, 10), (2, 10), (18, 10), (10, 2), (10, 18)]
    for i, (x, y) in enumerate(injectors):
        ax.scatter(x, y, c='blue', s=200, marker='^', 
                  edgecolors='black', linewidth=2)
        ax.text(x, y, f'I{i+1}', ha='center', va='center', fontsize=10, 
                fontweight='bold', color='white')
    
    # Add statistics outside plot area (right side)
    sw_flat = sw_map.flatten()
    stats_text = (f'Statistics:\n'
                 f'Mean Sw: {np.mean(sw_flat):.3f}\n'
                 f'Std Sw: {np.std(sw_flat):.3f}\n'
                 f'Range: {np.min(sw_flat):.3f} - {np.max(sw_flat):.3f}\n'
                 f'N cells: {len(sw_flat)}')
    
    ax.text(1.02, 0.98, stats_text, transform=ax.transAxes, 
            va='top', ha='left', fontsize=11, 
            bbox=dict(boxstyle='round', facecolor='lightblue', alpha=0.8))
    
    # Add data source info
    source_text = 'Source: MRST\nOptimized structure\n(Real simulation)'
    ax.text(1.02, 0.75, source_text, 
            transform=ax.transAxes, va='top', ha='left', fontsize=10,
            bbox=dict(boxstyle='round', facecolor='lightgreen', alpha=0.8))
    
    # Add well legend outside plot area
    well_legend_text = 'Well Locations:\n● Producers (P1-P4)\n▲ Injectors (I1-I5)'
    ax.text(1.02, 0.55, well_legend_text, transform=ax.transAxes, 
            va='top', ha='left', fontsize=11, 
            bbox=dict(boxstyle='round', facecolor='white', alpha=0.8))
    
    # Add grid lines
    ax.grid(True, alpha=0.3, color='white', linewidth=0.5)
    
    # Adjust layout to accommodate external elements
    plt.subplots_adjust(right=0.75)
    
    os.makedirs(os.path.dirname(output_path), exist_ok=True)
    plt.savefig(output_path, dpi=150, bbox_inches='tight')
    plt.close()
    
    print(f"✅ Initial Sw plot saved: {output_path}")
    return True


def plot_pressure_initial(output_path=None):
    """B-2: Initial pressure distribution - REQUIRES REAL MRST DATA
    Question: Pressure communication and flow patterns?
    """
    
    if output_path is None:
        output_path = (Path(__file__).parent.parent / 
                      "plots" / "B-2_pressure_initial.png")
    
    if not USE_OPTIMIZED_LOADER:
        print("❌ B-2 requires optimized data loader with oct2py")
        return False
    
    # Load initial setup data using oct2py
    try:
        initial_data = load_initial_conditions()
        
        # Check for required data (handle both old and new formats)
        pressure_data = None
        if 'pressure_init' in initial_data:
            pressure_data = initial_data['pressure_init']
        elif 'pressure' in initial_data:
            pressure_data = initial_data['pressure']
        else:
            raise ValueError(
                f"❌ MISSING DATA: Pressure not found in initial data\n"
                f"   Required variables: 'pressure_init' or 'pressure'\n"
                f"   Available variables: {list(initial_data.keys())}\n"
                f"   Check MRST initial conditions setup.")
        
        # Handle both 2D and 1D data
        if len(pressure_data.shape) == 2:
            pressure_map = pressure_data  # Already 2D
        else:
            pressure_init = pressure_data.flatten()
            if len(pressure_init) == 0:
                raise ValueError(
                    f"❌ EMPTY DATA: Initial pressure array is empty\n"
                    f"   Check MRST initial conditions generation.")
            pressure_map = reshape_to_grid(pressure_init)
        
    except Exception as e:
        print(f"❌ B-2 REQUIRES REAL MRST DATA: {e}")
        return False
    
    # Create figure with extra space for legends/info
    fig, ax = plt.subplots(1, 1, figsize=(14, 8))
    
    im = ax.imshow(pressure_map, cmap='viridis', origin='lower', 
                   extent=[0, 20, 0, 20])
    
    ax.set_title('B-2: Initial Pressure Distribution\n' +
                'Question: Pressure communication and flow patterns?', 
                fontsize=16, fontweight='bold')
    ax.set_xlabel('X Grid', fontsize=14, fontweight='bold')
    ax.set_ylabel('Y Grid', fontsize=14, fontweight='bold')
    
    # Add colorbar outside plot area
    cbar = plt.colorbar(im, ax=ax, shrink=0.8, pad=0.15)
    cbar.set_label('Pressure (psi)', fontsize=12, fontweight='bold')
    
    # Add well locations
    # Producers (red circles)
    producers = [(5, 5), (15, 5), (5, 15), (15, 15)]
    for i, (x, y) in enumerate(producers):
        ax.scatter(x, y, c='red', s=200, marker='o', 
                  edgecolors='black', linewidth=2)
        ax.text(x, y, f'P{i+1}', ha='center', va='center', fontsize=10, 
                fontweight='bold', color='white')
    
    # Injectors (blue triangles)
    injectors = [(10, 10), (2, 10), (18, 10), (10, 2), (10, 18)]
    for i, (x, y) in enumerate(injectors):
        ax.scatter(x, y, c='blue', s=200, marker='^', 
                  edgecolors='black', linewidth=2)
        ax.text(x, y, f'I{i+1}', ha='center', va='center', fontsize=10, 
                fontweight='bold', color='white')
    
    # Add statistics outside plot area (right side)
    pressure_flat = pressure_map.flatten()
    stats_text = (f'Statistics:\n'
                 f'Mean P: {np.mean(pressure_flat):.1f} psi\n'
                 f'Std P: {np.std(pressure_flat):.1f} psi\n'
                 f'Range: {np.min(pressure_flat):.1f} - {np.max(pressure_flat):.1f} psi\n'
                 f'N cells: {len(pressure_flat)}')
    
    ax.text(1.02, 0.98, stats_text, transform=ax.transAxes, 
            va='top', ha='left', fontsize=11, 
            bbox=dict(boxstyle='round', facecolor='lightblue', alpha=0.8))
    
    # Add data source info
    source_text = 'Source: MRST\nOptimized structure\n(Real simulation)'
    ax.text(1.02, 0.75, source_text, 
            transform=ax.transAxes, va='top', ha='left', fontsize=10,
            bbox=dict(boxstyle='round', facecolor='lightgreen', alpha=0.8))
    
    # Add well legend outside plot area
    well_legend_text = 'Well Locations:\n● Producers (P1-P4)\n▲ Injectors (I1-I5)'
    ax.text(1.02, 0.55, well_legend_text, transform=ax.transAxes, 
            va='top', ha='left', fontsize=11, 
            bbox=dict(boxstyle='round', facecolor='white', alpha=0.8))
    
    # Add grid lines and contour lines
    ax.grid(True, alpha=0.3, color='white', linewidth=0.5)
    
    # Add contour lines for better visualization
    contours = ax.contour(pressure_map, levels=10, colors='white', 
                         alpha=0.7, linewidths=1)
    ax.clabel(contours, inline=True, fontsize=8, fmt='%.0f')
    
    # Adjust layout to accommodate external elements
    plt.subplots_adjust(right=0.75)
    
    os.makedirs(os.path.dirname(output_path), exist_ok=True)
    plt.savefig(output_path, dpi=150, bbox_inches='tight')
    plt.close()
    
    print(f"✅ Initial pressure plot saved: {output_path}")
    return True


def main():
    """Main function"""
    print("🌊 Generating Category B: Initial Conditions...")
    print("=" * 70)
    print("⚠️  IMPORTANT: This script requires real MRST simulation data.")
    print("   B-1, B-2: Require real MRST initial conditions (no synthetic fallback)")
    print("   Uses oct2py for proper .mat file reading")
    print("=" * 70)
    
    if not USE_OPTIMIZED_LOADER:
        print("❌ Cannot proceed without optimized data loader")
        print("   Install oct2py: pip install oct2py")
        return False
    
    # Check data availability first
    print("📊 Checking data availability...")
    availability = check_data_availability()
    print_data_summary()
    
    # Generate all plots for Category B - will fail if data not available
    success = True
    
    if not plot_sw_initial():
        success = False
    if not plot_pressure_initial():
        success = False
    
    if success:
        print("✅ Category B initial conditions plots complete!")
    else:
        print("❌ Category B incomplete - missing MRST data")
    return success


if __name__ == "__main__":
    main() 