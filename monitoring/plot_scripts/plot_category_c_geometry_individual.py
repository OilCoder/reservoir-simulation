#!/usr/bin/env python3
"""
Category C: Geometry & Configuration (Individual Plots)

Generates individual plots for reservoir geometry and well configuration:
C-1: Well locations map (XY plane)
C-2: Rock regions map (proposed)
C-3: Well completion intervals (proposed)
"""

import numpy as np
import matplotlib.pyplot as plt
import os
from pathlib import Path


def plot_c1_well_locations(output_path=None):
    """C-1: Well locations map (XY plane)
    Question: Does the drainage and injection pattern cover the reservoir?
    X-axis: X (m)
    Y-axis: Y (m)
    Color: Well type (symbol I vs P)
    """
    
    if output_path is None:
        output_path = (Path(__file__).parent.parent / 
                      "plots" / "C-1_well_locations.png")
    
    fig, ax = plt.subplots(1, 1, figsize=(10, 8))
    
    # Create reservoir outline
    reservoir_x = [0, 20, 20, 0, 0]
    reservoir_y = [0, 0, 20, 20, 0]
    ax.plot(reservoir_x, reservoir_y, 'k-', linewidth=3, label='Reservoir Boundary')
    
    # Producer wells (red circles)
    producer_x = [5, 15, 5, 15]
    producer_y = [5, 5, 15, 15]
    ax.scatter(producer_x, producer_y, s=200, c='red', marker='o', 
               label='Producers (P)', edgecolors='black', linewidth=2)
    
    # Injector wells (blue triangles)
    injector_x = [10, 2, 18, 10, 10]
    injector_y = [10, 10, 10, 2, 18]
    ax.scatter(injector_x, injector_y, s=200, c='blue', marker='^', 
               label='Injectors (I)', edgecolors='black', linewidth=2)
    
    # Add well labels
    for i, (x, y) in enumerate(zip(producer_x, producer_y)):
        ax.annotate(f'P{i+1}', (x, y), xytext=(0, 0), 
                   textcoords='offset points', fontsize=12, fontweight='bold',
                   ha='center', va='center', color='white')
    
    for i, (x, y) in enumerate(zip(injector_x, injector_y)):
        ax.annotate(f'I{i+1}', (x, y), xytext=(0, 0), 
                   textcoords='offset points', fontsize=12, fontweight='bold',
                   ha='center', va='center', color='white')
    
    # Add drainage areas (visual guide)
    for px, py in zip(producer_x, producer_y):
        circle = plt.Circle((px, py), 3, fill=False, color='red', 
                           linestyle='--', alpha=0.5, linewidth=2)
        ax.add_patch(circle)
    
    # Add injection influence areas
    for ix, iy in zip(injector_x, injector_y):
        circle = plt.Circle((ix, iy), 2.5, fill=False, color='blue', 
                           linestyle=':', alpha=0.5, linewidth=2)
        ax.add_patch(circle)
    
    ax.set_xlim(-1, 21)
    ax.set_ylim(-1, 21)
    ax.set_aspect('equal')
    ax.set_xlabel('X Position (m)', fontsize=14, fontweight='bold')
    ax.set_ylabel('Y Position (m)', fontsize=14, fontweight='bold')
    ax.set_title('C-1: Well Locations Map\n' +
                'Question: Does pattern cover the reservoir?', 
                fontsize=16, fontweight='bold')
    ax.legend(fontsize=12, loc='upper left')
    ax.grid(True, alpha=0.3)
    
    # Add statistics
    ax.text(0.98, 0.02, f'Producers: {len(producer_x)}\nInjectors: {len(injector_x)}', 
            transform=ax.transAxes, va='bottom', ha='right', fontsize=12,
            bbox=dict(boxstyle='round', facecolor='white', alpha=0.8))
    
    plt.tight_layout()
    
    os.makedirs(os.path.dirname(output_path), exist_ok=True)
    plt.savefig(output_path, dpi=150, bbox_inches='tight')
    plt.close()
    
    print(f"✅ C-1 Well locations plot saved: {output_path}")


def plot_c2_rock_regions(output_path=None):
    """C-2: Rock regions map
    Question: Where do lithological properties change?
    X-axis: X
    Y-axis: Y  
    Color: rock_id
    """
    
    if output_path is None:
        output_path = (Path(__file__).parent.parent / 
                      "plots" / "C-2_rock_regions.png")
    
    fig, ax = plt.subplots(1, 1, figsize=(10, 8))
    
    # Create synthetic rock regions
    x = np.linspace(0, 20, 20)
    y = np.linspace(0, 20, 20)
    X, Y = np.meshgrid(x, y)
    
    # Define rock regions based on geological features
    rock_map = np.ones_like(X, dtype=int)
    
    # Region 1: High permeability channel (north)
    rock_map[Y > 15] = 1
    
    # Region 2: Medium permeability (center)
    rock_map[(Y >= 8) & (Y <= 15)] = 2
    
    # Region 3: Low permeability barrier (south)
    rock_map[Y < 8] = 3
    
    # Region 4: Fracture zone (diagonal)
    for i in range(20):
        for j in range(20):
            if abs(i - j) < 2:
                rock_map[i, j] = 4
    
    # Plot rock regions
    im = ax.imshow(rock_map, cmap='tab10', origin='lower', 
                   extent=[0, 20, 0, 20], alpha=0.8)
    
    # Add well locations for context
    producer_x = [5, 15, 5, 15]
    producer_y = [5, 5, 15, 15]
    injector_x = [10, 2, 18, 10, 10]
    injector_y = [10, 10, 10, 2, 18]
    
    ax.scatter(producer_x, producer_y, s=150, c='red', marker='o', 
               edgecolors='white', linewidth=2, label='Producers')
    ax.scatter(injector_x, injector_y, s=150, c='blue', marker='^', 
               edgecolors='white', linewidth=2, label='Injectors')
    
    # Add colorbar
    cbar = plt.colorbar(im, ax=ax, shrink=0.8)
    cbar.set_label('Rock Type ID', fontsize=12, fontweight='bold')
    cbar.set_ticks([1, 2, 3, 4])
    cbar.set_ticklabels(['High k', 'Medium k', 'Low k', 'Fracture'])
    
    ax.set_xlabel('X Position (m)', fontsize=14, fontweight='bold')
    ax.set_ylabel('Y Position (m)', fontsize=14, fontweight='bold')
    ax.set_title('C-2: Rock Regions Map\n' +
                'Question: Where do lithological properties change?', 
                fontsize=16, fontweight='bold')
    ax.legend(fontsize=12, loc='upper right')
    ax.grid(True, alpha=0.3, color='white', linewidth=0.5)
    
    plt.tight_layout()
    
    os.makedirs(os.path.dirname(output_path), exist_ok=True)
    plt.savefig(output_path, dpi=150, bbox_inches='tight')
    plt.close()
    
    print(f"✅ C-2 Rock regions plot saved: {output_path}")


def plot_c3_well_completions(output_path=None):
    """C-3: Well completion intervals
    Question: Are completion intervals optimally placed?
    X-axis: Depth (m)
    Y-axis: Well ID
    Color: Well type
    """
    
    if output_path is None:
        output_path = (Path(__file__).parent.parent / 
                      "plots" / "C-3_well_completions.png")
    
    fig, ax = plt.subplots(1, 1, figsize=(12, 8))
    
    # Well information
    wells = ['P1', 'P2', 'P3', 'P4', 'I1', 'I2', 'I3', 'I4', 'I5']
    well_types = ['Producer'] * 4 + ['Injector'] * 5
    colors = ['red'] * 4 + ['blue'] * 5
    
    # Completion intervals (varying depths for realism)
    top_depths = [95, 100, 98, 102, 96, 99, 101, 97, 103]
    bottom_depths = [195, 200, 198, 202, 196, 199, 201, 197, 203]
    
    # Plot completion intervals
    for i, (well, color, top, bottom) in enumerate(zip(wells, colors, top_depths, bottom_depths)):
        # Main completion interval
        ax.barh(i, bottom - top, left=top, color=color, alpha=0.7, 
                edgecolor='black', linewidth=1.5, height=0.6)
        
        # Add perforations (small marks)
        perf_depths = np.linspace(top + 10, bottom - 10, 5)
        for perf_depth in perf_depths:
            ax.plot([perf_depth, perf_depth], [i-0.3, i+0.3], 'k-', linewidth=2)
        
        # Well label
        ax.text(top - 5, i, well, va='center', ha='right', 
                fontweight='bold', fontsize=12)
        
        # Completion stats
        ax.text(bottom + 2, i, f'{bottom-top:.0f}m', va='center', ha='left', 
                fontsize=10, style='italic')
    
    # Add formation layers (background)
    formation_tops = [90, 120, 150, 180, 210]
    formation_names = ['Cap Rock', 'Upper Sand', 'Shale', 'Lower Sand', 'Base']
    formation_colors = ['gray', 'yellow', 'brown', 'gold', 'darkgray']
    
    for i in range(len(formation_tops)-1):
        ax.axvspan(formation_tops[i], formation_tops[i+1], 
                  alpha=0.2, color=formation_colors[i])
        ax.text(formation_tops[i] + 5, len(wells), formation_names[i], 
               rotation=90, va='bottom', ha='left', fontsize=9)
    
    ax.set_yticks(range(len(wells)))
    ax.set_yticklabels(wells)
    ax.set_xlabel('Depth (m)', fontsize=14, fontweight='bold')
    ax.set_ylabel('Well ID', fontsize=14, fontweight='bold')
    ax.set_title('C-3: Well Completion Intervals\n' +
                'Question: Are completions optimally placed?', 
                fontsize=16, fontweight='bold')
    ax.grid(True, alpha=0.3)
    ax.set_xlim(80, 220)
    
    # Add legend
    from matplotlib.patches import Patch
    legend_elements = [
        Patch(facecolor='red', alpha=0.7, label='Producers'),
        Patch(facecolor='blue', alpha=0.7, label='Injectors'),
        plt.Line2D([0], [0], color='black', linewidth=2, label='Perforations')
    ]
    ax.legend(handles=legend_elements, loc='upper right', fontsize=12)
    
    plt.tight_layout()
    
    os.makedirs(os.path.dirname(output_path), exist_ok=True)
    plt.savefig(output_path, dpi=150, bbox_inches='tight')
    plt.close()
    
    print(f"✅ C-3 Well completions plot saved: {output_path}")


def main():
    """Main function"""
    print("🏗️ Generating Category C: Individual Geometry & Configuration...")
    print("=" * 70)
    
    # Generate all individual plots for Category C
    plot_c1_well_locations()
    plot_c2_rock_regions()
    plot_c3_well_completions()
    
    print("✅ Category C individual plots complete!")


if __name__ == "__main__":
    main() 