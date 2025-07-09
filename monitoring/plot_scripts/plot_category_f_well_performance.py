#!/usr/bin/env python3
"""
Category F: Well Performance (Individual Plots)

Generates individual plots for well performance analysis:
F-1: BHP por pozo (time vs BHP, colored by well) - Bottom hole pressure evolution
F-2: Tasas instantáneas qₒ, qw (time vs rates, colored by phase) - Instantaneous rates
F-3: Producción acumulada (time vs cumulative, colored by well) - Cumulative production
F-4: Water-cut (time vs water cut, colored by well) - Water cut evolution

Uses oct2py for proper .mat file reading from optimized data structure.
"""

import numpy as np
import matplotlib.pyplot as plt
import os
from pathlib import Path

# Import the optimized data loader
try:
    from util_data_loader import (
        load_well_data, load_temporal_data, load_cumulative_data,
        calculate_water_cut, check_data_availability, print_data_summary
    )
    USE_OPTIMIZED_LOADER = True
    print("✅ Using optimized data loader with oct2py")
except ImportError:
    USE_OPTIMIZED_LOADER = False
    print("❌ Optimized data loader not available")


def plot_f1_bhp_by_well(output_path=None):
    """F-1: BHP por pozo (time vs BHP, colored by well)
    Pregunta: ¿Cómo evoluciona la presión de fondo en cada pozo?
    X-axis: Tiempo (días)
    Y-axis: BHP (psi)
    Color: Pozo
    """
    
    if output_path is None:
        output_path = (Path(__file__).parent.parent / 
                      "plots" / "F-1_bhp_by_well.png")
    
    if not USE_OPTIMIZED_LOADER:
        print("❌ F-1 requires optimized data loader with oct2py")
        return False
    
    # Load MRST well data using oct2py
    try:
        well_data = load_well_data()
        
        if not well_data:
            raise ValueError("No well data available")
        
        # Check for required data
        required_vars = ['time_days', 'well_names', 'bhp']
        missing_vars = []
        
        for var in required_vars:
            if var not in well_data:
                missing_vars.append(var)
        
        if missing_vars:
            raise ValueError(
                f"❌ MISSING DATA: Variables {missing_vars} not found\n"
                f"   Required variables: {required_vars}\n"
                f"   Available variables: {list(well_data.keys())}\n"
                f"   Check MRST well data export.")
        
        # Extract data
        time_days = well_data['time_days'].flatten()
        well_names = well_data['well_names']
        bhp = well_data['bhp']  # [time, well] Bottom hole pressure
        
        if len(time_days) == 0 or bhp.size == 0:
            raise ValueError(
                f"❌ EMPTY DATA: Well data arrays are empty\n"
                f"   Check MRST well data generation.")
        
    except Exception as e:
        print(f"❌ F-1 REQUIRES REAL MRST DATA: {e}")
        return False
    
    # Create figure
    fig, ax = plt.subplots(1, 1, figsize=(12, 8))
    
    # Define colors for different wells
    colors = ['#1f77b4', '#ff7f0e', '#2ca02c', '#d62728', '#9467bd', '#8c564b']
    
    # Plot BHP for all wells
    for i in range(bhp.shape[1]):
        well_name = well_names[i] if i < len(well_names) else f'Pozo {i+1}'
        ax.plot(time_days, bhp[:, i], 
                color=colors[i % len(colors)],
                linewidth=3, 
                label=well_name,
                marker='o', markersize=4)
    
    # Add constraint lines
    ax.axhline(y=1000, color='red', linestyle='--', alpha=0.7, linewidth=2,
               label='Límite mínimo BHP (1000 psi)')
    ax.axhline(y=4000, color='red', linestyle=':', alpha=0.7, linewidth=2,
               label='Límite máximo BHP (4000 psi)')
    
    ax.set_xlabel('Tiempo (días)', fontsize=14, fontweight='bold')
    ax.set_ylabel('Presión de Fondo BHP (psi)', fontsize=14, fontweight='bold')
    ax.set_title('F-1: Presión de Fondo por Pozo\n' +
                '¿Cómo evoluciona la presión de fondo en cada pozo?', 
                fontsize=16, fontweight='bold')
    ax.grid(True, alpha=0.3)
    ax.legend(loc='best', fontsize=12)
    
    # Add statistics
    stats_text = (f'Estadísticas BHP:\n'
                  f'Tiempo: {time_days[0]:.1f} - {time_days[-1]:.1f} días\n'
                  f'Pozos: {bhp.shape[1]}\n'
                  f'BHP min: {np.min(bhp):.1f} psi\n'
                  f'BHP max: {np.max(bhp):.1f} psi\n'
                  f'BHP promedio: {np.mean(bhp):.1f} psi')
    
    ax.text(0.02, 0.98, stats_text, transform=ax.transAxes, 
            va='top', ha='left', fontsize=11, 
            bbox=dict(boxstyle='round', facecolor='lightblue', alpha=0.8))
    
    # Add data source info
    source_text = 'Fuente: MRST\nDatos de pozos\n(Simulación real)'
    ax.text(0.98, 0.02, source_text, transform=ax.transAxes, 
            va='bottom', ha='right', fontsize=12, 
            bbox=dict(boxstyle='round', facecolor='lightgreen', alpha=0.8))
    
    os.makedirs(os.path.dirname(output_path), exist_ok=True)
    plt.savefig(output_path, dpi=150, bbox_inches='tight')
    plt.close()
    
    print(f"✅ F-1 BHP by well plot saved: {output_path}")
    return True


def plot_f2_instantaneous_rates(output_path=None):
    """F-2: Tasas instantáneas qₒ, qw (time vs rates, colored by phase)
    Pregunta: ¿Cómo varían las tasas de producción e inyección con el tiempo?
    X-axis: Tiempo (días)
    Y-axis: Tasa (STB/d)
    Color: Fase (aceite vs agua)
    """
    
    if output_path is None:
        output_path = (Path(__file__).parent.parent / 
                      "plots" / "F-2_instantaneous_rates.png")
    
    if not USE_OPTIMIZED_LOADER:
        print("❌ F-2 requires optimized data loader with oct2py")
        return False
    
    # Load MRST well data using oct2py
    try:
        well_data = load_well_data()
        
        if not well_data:
            raise ValueError("No well data available")
        
        # Check for required data
        required_vars = ['time_days', 'well_names', 'qWs', 'qOs']
        missing_vars = []
        
        for var in required_vars:
            if var not in well_data:
                missing_vars.append(var)
        
        if missing_vars:
            raise ValueError(
                f"❌ MISSING DATA: Variables {missing_vars} not found\n"
                f"   Required variables: {required_vars}\n"
                f"   Available variables: {list(well_data.keys())}\n"
                f"   Check MRST well data export.")
        
        # Extract data
        time_days = well_data['time_days'].flatten()
        well_names = well_data['well_names']
        qWs = well_data['qWs']  # [time, well] Water rates
        qOs = well_data['qOs']  # [time, well] Oil rates
        
        if len(time_days) == 0 or qWs.size == 0 or qOs.size == 0:
            raise ValueError(
                f"❌ EMPTY DATA: Well rate arrays are empty\n"
                f"   Check MRST well data generation.")
        
    except Exception as e:
        print(f"❌ F-2 REQUIRES REAL MRST DATA: {e}")
        return False
    
    # Create figure with subplots
    fig, (ax1, ax2) = plt.subplots(2, 1, figsize=(12, 10))
    
    # Define colors for different wells
    colors = ['#1f77b4', '#ff7f0e', '#2ca02c', '#d62728', '#9467bd', '#8c564b']
    
    # Plot 1: Water rates
    for i in range(qWs.shape[1]):
        well_name = well_names[i] if i < len(well_names) else f'Pozo {i+1}'
        ax1.plot(time_days, qWs[:, i], 
                color=colors[i % len(colors)],
                linewidth=3, 
                label=well_name,
                marker='o', markersize=4)
    
    ax1.set_xlabel('Tiempo (días)', fontsize=14, fontweight='bold')
    ax1.set_ylabel('Tasa de Agua qw (STB/d)', fontsize=14, fontweight='bold')
    ax1.set_title('Tasas de Agua por Pozo', fontsize=14, fontweight='bold')
    ax1.grid(True, alpha=0.3)
    ax1.legend(loc='best', fontsize=11)
    
    # Plot 2: Oil rates
    for i in range(qOs.shape[1]):
        well_name = well_names[i] if i < len(well_names) else f'Pozo {i+1}'
        ax2.plot(time_days, qOs[:, i], 
                color=colors[i % len(colors)],
                linewidth=3, 
                label=well_name,
                marker='s', markersize=4)
    
    ax2.set_xlabel('Tiempo (días)', fontsize=14, fontweight='bold')
    ax2.set_ylabel('Tasa de Aceite qo (STB/d)', fontsize=14, fontweight='bold')
    ax2.set_title('Tasas de Aceite por Pozo', fontsize=14, fontweight='bold')
    ax2.grid(True, alpha=0.3)
    ax2.legend(loc='best', fontsize=11)
    
    # Add main title
    fig.suptitle('F-2: Tasas Instantáneas qₒ, qw\n¿Cómo varían las tasas con el tiempo?', 
                fontsize=16, fontweight='bold')
    
    # Add statistics
    stats_text = (f'Estadísticas de Tasas:\n'
                  f'Tiempo: {time_days[0]:.1f} - {time_days[-1]:.1f} días\n'
                  f'Pozos: {qWs.shape[1]}\n'
                  f'qw promedio: {np.mean(qWs):.1f} STB/d\n'
                  f'qo promedio: {np.mean(qOs):.1f} STB/d')
    
    ax1.text(0.02, 0.98, stats_text, transform=ax1.transAxes, 
            va='top', ha='left', fontsize=11, 
            bbox=dict(boxstyle='round', facecolor='lightblue', alpha=0.8))
    
    # Add data source info
    source_text = 'Fuente: MRST\nDatos de pozos\n(Simulación real)'
    ax2.text(0.98, 0.02, source_text, transform=ax2.transAxes, 
            va='bottom', ha='right', fontsize=12, 
            bbox=dict(boxstyle='round', facecolor='lightgreen', alpha=0.8))
    
    plt.tight_layout()
    os.makedirs(os.path.dirname(output_path), exist_ok=True)
    plt.savefig(output_path, dpi=150, bbox_inches='tight')
    plt.close()
    
    print(f"✅ F-2 Instantaneous rates plot saved: {output_path}")
    return True


def plot_f3_cumulative_production(output_path=None):
    """F-3: Producción acumulada (time vs cumulative, colored by well)
    Pregunta: ¿Cuánto ha producido cada pozo acumulativamente?
    X-axis: Tiempo (días)
    Y-axis: Producción acumulada (STB)
    Color: Pozo
    """
    
    if output_path is None:
        output_path = (Path(__file__).parent.parent / 
                      "plots" / "F-3_cumulative_production.png")
    
    if not USE_OPTIMIZED_LOADER:
        print("❌ F-3 requires optimized data loader with oct2py")
        return False
    
    # Try to load cumulative data first
    try:
        cumulative_data = load_cumulative_data()
        
        if cumulative_data:
            # Use pre-calculated cumulative data
            time_days = cumulative_data['time_days'].flatten()
            well_names = cumulative_data['well_names']
            cum_oil_prod = cumulative_data['cum_oil_prod']
            cum_water_prod = cumulative_data['cum_water_prod']
            
        else:
            # Calculate from instantaneous rates
            well_data = load_well_data()
            temporal_data = load_temporal_data()
            
            if not well_data or not temporal_data:
                raise ValueError("No well or temporal data available")
            
            time_days = well_data['time_days'].flatten()
            well_names = well_data['well_names']
            qWs = well_data['qWs']  # [time, well] Water rates
            qOs = well_data['qOs']  # [time, well] Oil rates
            
            dt_days = temporal_data['dt_days'].flatten()
            
            # Calculate cumulative production by integration
            cum_oil_prod = np.zeros_like(qOs)
            cum_water_prod = np.zeros_like(qWs)
            
            for i in range(1, len(time_days)):
                dt = dt_days[i-1] if i-1 < len(dt_days) else 7.3  # Default timestep
                cum_oil_prod[i, :] = cum_oil_prod[i-1, :] + qOs[i, :] * dt
                cum_water_prod[i, :] = cum_water_prod[i-1, :] + qWs[i, :] * dt
        
    except Exception as e:
        print(f"❌ F-3 REQUIRES REAL MRST DATA: {e}")
        return False
    
    # Create figure with subplots
    fig, (ax1, ax2) = plt.subplots(2, 1, figsize=(12, 10))
    
    # Define colors for different wells
    colors = ['#1f77b4', '#ff7f0e', '#2ca02c', '#d62728', '#9467bd', '#8c564b']
    
    # Plot 1: Cumulative oil production
    for i in range(cum_oil_prod.shape[1]):
        well_name = well_names[i] if i < len(well_names) else f'Pozo {i+1}'
        ax1.plot(time_days, cum_oil_prod[:, i], 
                color=colors[i % len(colors)],
                linewidth=3, 
                label=well_name,
                marker='o', markersize=4)
    
    ax1.set_xlabel('Tiempo (días)', fontsize=14, fontweight='bold')
    ax1.set_ylabel('Producción Acumulada de Aceite (STB)', fontsize=14, fontweight='bold')
    ax1.set_title('Producción Acumulada de Aceite', fontsize=14, fontweight='bold')
    ax1.grid(True, alpha=0.3)
    ax1.legend(loc='best', fontsize=11)
    
    # Plot 2: Cumulative water production
    for i in range(cum_water_prod.shape[1]):
        well_name = well_names[i] if i < len(well_names) else f'Pozo {i+1}'
        ax2.plot(time_days, cum_water_prod[:, i], 
                color=colors[i % len(colors)],
                linewidth=3, 
                label=well_name,
                marker='s', markersize=4)
    
    ax2.set_xlabel('Tiempo (días)', fontsize=14, fontweight='bold')
    ax2.set_ylabel('Producción Acumulada de Agua (STB)', fontsize=14, fontweight='bold')
    ax2.set_title('Producción Acumulada de Agua', fontsize=14, fontweight='bold')
    ax2.grid(True, alpha=0.3)
    ax2.legend(loc='best', fontsize=11)
    
    # Add main title
    fig.suptitle('F-3: Producción Acumulada\n¿Cuánto ha producido cada pozo?', 
                fontsize=16, fontweight='bold')
    
    # Add statistics
    total_oil = np.sum(cum_oil_prod[-1, :])
    total_water = np.sum(cum_water_prod[-1, :])
    
    stats_text = (f'Producción Total:\n'
                  f'Tiempo: {time_days[0]:.1f} - {time_days[-1]:.1f} días\n'
                  f'Aceite total: {total_oil:.0f} STB\n'
                  f'Agua total: {total_water:.0f} STB\n'
                  f'Pozos: {cum_oil_prod.shape[1]}')
    
    ax1.text(0.02, 0.98, stats_text, transform=ax1.transAxes, 
            va='top', ha='left', fontsize=11, 
            bbox=dict(boxstyle='round', facecolor='lightblue', alpha=0.8))
    
    # Add data source info
    source_text = 'Fuente: MRST\nDatos de pozos\n(Simulación real)'
    ax2.text(0.98, 0.02, source_text, transform=ax2.transAxes, 
            va='bottom', ha='right', fontsize=12, 
            bbox=dict(boxstyle='round', facecolor='lightgreen', alpha=0.8))
    
    plt.tight_layout()
    os.makedirs(os.path.dirname(output_path), exist_ok=True)
    plt.savefig(output_path, dpi=150, bbox_inches='tight')
    plt.close()
    
    print(f"✅ F-3 Cumulative production plot saved: {output_path}")
    return True


def plot_f4_water_cut(output_path=None):
    """F-4: Water-cut (time vs water cut, colored by well)
    Pregunta: ¿Cómo evoluciona la fracción de agua producida?
    X-axis: Tiempo (días)
    Y-axis: Water cut (-)
    Color: Pozo
    """
    
    if output_path is None:
        output_path = (Path(__file__).parent.parent / 
                      "plots" / "F-4_water_cut.png")
    
    if not USE_OPTIMIZED_LOADER:
        print("❌ F-4 requires optimized data loader with oct2py")
        return False
    
    # Load MRST well data using oct2py
    try:
        well_data = load_well_data()
        
        if not well_data:
            raise ValueError("No well data available")
        
        # Calculate water cut using utility function
        water_cut_data = calculate_water_cut(well_data)
        
        if not water_cut_data:
            raise ValueError("Failed to calculate water cut")
        
        time_days = water_cut_data['time_days'].flatten()
        well_names = water_cut_data['well_names']
        water_cut = water_cut_data['water_cut']  # [time, well]
        
        if len(time_days) == 0 or water_cut.size == 0:
            raise ValueError(
                f"❌ EMPTY DATA: Water cut arrays are empty\n"
                f"   Check MRST well data generation.")
        
    except Exception as e:
        print(f"❌ F-4 REQUIRES REAL MRST DATA: {e}")
        return False
    
    # Create figure
    fig, ax = plt.subplots(1, 1, figsize=(12, 8))
    
    # Define colors for different wells
    colors = ['#1f77b4', '#ff7f0e', '#2ca02c', '#d62728', '#9467bd', '#8c564b']
    
    # Plot water cut for all wells
    for i in range(water_cut.shape[1]):
        well_name = well_names[i] if i < len(well_names) else f'Pozo {i+1}'
        ax.plot(time_days, water_cut[:, i], 
                color=colors[i % len(colors)],
                linewidth=3, 
                label=well_name,
                marker='o', markersize=4)
    
    # Add reference lines
    ax.axhline(y=0.5, color='gray', linestyle='--', alpha=0.7, linewidth=2,
               label='Water cut = 50%')
    ax.axhline(y=0.9, color='red', linestyle=':', alpha=0.7, linewidth=2,
               label='Water cut = 90% (límite crítico)')
    
    ax.set_xlabel('Tiempo (días)', fontsize=14, fontweight='bold')
    ax.set_ylabel('Water Cut (-)', fontsize=14, fontweight='bold')
    ax.set_title('F-4: Water Cut por Pozo\n' +
                '¿Cómo evoluciona la fracción de agua producida?', 
                fontsize=16, fontweight='bold')
    ax.grid(True, alpha=0.3)
    ax.legend(loc='best', fontsize=12)
    ax.set_ylim(0, 1)
    
    # Add statistics
    stats_text = (f'Estadísticas Water Cut:\n'
                  f'Tiempo: {time_days[0]:.1f} - {time_days[-1]:.1f} días\n'
                  f'Pozos: {water_cut.shape[1]}\n'
                  f'WC inicial: {np.mean(water_cut[0, :]):.3f}\n'
                  f'WC final: {np.mean(water_cut[-1, :]):.3f}\n'
                  f'WC máximo: {np.max(water_cut):.3f}')
    
    ax.text(0.02, 0.98, stats_text, transform=ax.transAxes, 
            va='top', ha='left', fontsize=11, 
            bbox=dict(boxstyle='round', facecolor='lightblue', alpha=0.8))
    
    # Add data source info
    source_text = 'Fuente: MRST\nDatos de pozos\n(Simulación real)'
    ax.text(0.98, 0.02, source_text, transform=ax.transAxes, 
            va='bottom', ha='right', fontsize=12, 
            bbox=dict(boxstyle='round', facecolor='lightgreen', alpha=0.8))
    
    os.makedirs(os.path.dirname(output_path), exist_ok=True)
    plt.savefig(output_path, dpi=150, bbox_inches='tight')
    plt.close()
    
    print(f"✅ F-4 Water cut plot saved: {output_path}")
    return True


def main():
    """Main function"""
    print("🔧 Generating Category F: Well Performance...")
    print("=" * 70)
    print("⚠️  IMPORTANT: This script requires real MRST simulation data.")
    print("   F-1, F-2, F-3, F-4: ALL require real MRST data (no synthetic fallback)")
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
    
    # ALL plots require real MRST data - will fail if not available
    success = True
    
    if not plot_f1_bhp_by_well():
        success = False
    if not plot_f2_instantaneous_rates():
        success = False
    if not plot_f3_cumulative_production():
        success = False
    if not plot_f4_water_cut():
        success = False
    
    if success:
        print("✅ Category F well performance plots complete!")
    else:
        print("❌ Category F incomplete - missing MRST data")
    
    return success


if __name__ == "__main__":
    main() 