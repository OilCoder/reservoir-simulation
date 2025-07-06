#!/usr/bin/env python3
"""
Plot Wells - Simple well performance plots

Generates well performance plots. Currently creates placeholder plots
since well data is not included in the simulation snapshots.
"""

import numpy as np
import matplotlib.pyplot as plt
import os
from pathlib import Path


def create_placeholder_wells_plot(output_path=None):
    """Create placeholder well performance plots"""
    
    if output_path is None:
        # Save in monitoring/plots/ directory
        output_path = Path(__file__).parent.parent / "plots" / "wells.png"
    
    fig, axes = plt.subplots(2, 2, figsize=(12, 8))
    fig.suptitle('🏭 Well Performance (Placeholder)', 
                 fontsize=16, fontweight='bold')
    
    # Generate dummy data for demonstration
    timesteps = np.arange(1, 51)  # 50 timesteps
    
    # ----
    # Plot 1: Bottom Hole Pressure (BHP)
    # ----
    ax = axes[0, 0]
    bhp_producer = 2000 - 20 * timesteps + 5 * np.random.randn(50)  # Declining BHP
    bhp_injector = 2500 + 10 * timesteps + 3 * np.random.randn(50)  # Rising BHP
    
    ax.plot(timesteps, bhp_producer, 'b-', linewidth=2, label='Producer')
    ax.plot(timesteps, bhp_injector, 'r-', linewidth=2, label='Injector')
    ax.set_xlabel('Timestep')
    ax.set_ylabel('BHP (psi)')
    ax.set_title('🔵 Bottom Hole Pressure')
    ax.grid(True, alpha=0.3)
    ax.legend()
    
    # ----
    # Plot 2: Production Rates
    # ----
    ax = axes[0, 1]
    oil_rate = 1000 * np.exp(-timesteps/30) + 50 * np.random.randn(50)  # Declining
    water_rate = 50 * (1 - np.exp(-timesteps/20)) + 10 * np.random.randn(50)  # Rising
    
    ax.plot(timesteps, oil_rate, 'g-', linewidth=2, label='Oil Rate')
    ax.plot(timesteps, water_rate, 'b-', linewidth=2, label='Water Rate')
    ax.set_xlabel('Timestep')
    ax.set_ylabel('Rate (bbl/day)')
    ax.set_title('🛢️ Production Rates')
    ax.grid(True, alpha=0.3)
    ax.legend()
    
    # ----
    # Plot 3: Cumulative Production
    # ----
    ax = axes[1, 0]
    cumulative_oil = np.cumsum(oil_rate * 7.3)  # 7.3 days per timestep
    cumulative_water = np.cumsum(water_rate * 7.3)
    
    ax.plot(timesteps, cumulative_oil, 'g-', linewidth=2, label='Oil')
    ax.plot(timesteps, cumulative_water, 'b-', linewidth=2, label='Water')
    ax.set_xlabel('Timestep')
    ax.set_ylabel('Cumulative Production (bbl)')
    ax.set_title('📈 Cumulative Production')
    ax.grid(True, alpha=0.3)
    ax.legend()
    
    # ----
    # Plot 4: Water Cut
    # ----
    ax = axes[1, 1]
    total_rate = oil_rate + water_rate
    water_cut = (water_rate / total_rate) * 100
    water_cut = np.clip(water_cut, 0, 100)  # Keep between 0-100%
    
    ax.plot(timesteps, water_cut, 'purple', linewidth=2)
    ax.set_xlabel('Timestep')
    ax.set_ylabel('Water Cut (%)')
    ax.set_title('💧 Water Cut Evolution')
    ax.grid(True, alpha=0.3)
    ax.set_ylim(0, 100)
    
    plt.tight_layout()
    
    # Save plot
    os.makedirs(os.path.dirname(output_path), exist_ok=True)
    plt.savefig(output_path, dpi=150, bbox_inches='tight')
    plt.close()
    
    print(f"✅ Wells plot saved: {output_path}")


def main():
    """Main function"""
    print("🏭 Generating Wells Plots...")
    print("=" * 40)
    
    print("ℹ️  Note: Creating placeholder well plots")
    print("   (Well data not available in simulation snapshots)")
    
    # Generate placeholder plots
    print("🎨 Creating wells plot...")
    create_placeholder_wells_plot()
    
    print("✅ Wells plots complete!")


if __name__ == "__main__":
    main() 