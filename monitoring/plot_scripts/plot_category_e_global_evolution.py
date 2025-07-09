#!/usr/bin/env python3
"""
Category E: Global Evolution (Time Series) - REQUIRES REAL MRST DATA

Generates individual plots for reservoir-wide evolution:
E-1: Pressure evolution (average + range) - REQUIRES REAL MRST DATA
E-2: Effective stress evolution - REQUIRES REAL MRST DATA  
E-3: Porosity evolution - REQUIRES REAL MRST DATA
E-4: Permeability evolution - REQUIRES REAL MRST DATA
E-5: Water saturation histogram evolution - REQUIRES REAL MRST DATA

Uses optimized data loader with oct2py for proper .mat file reading.
"""

import numpy as np
import matplotlib.pyplot as plt
import os
from pathlib import Path

# Import the optimized data loader
try:
    from util_data_loader import (
        load_field_arrays, load_temporal_data,
        check_data_availability, print_data_summary
    )
    USE_OPTIMIZED_LOADER = True
    print("✅ Using optimized data loader with oct2py")
except ImportError:
    USE_OPTIMIZED_LOADER = False
    print("❌ Optimized data loader not available")


def plot_pressure_evolution(output_path=None):
    """E-1: Evolución de presión promedio + rango
    Pregunta: ¿Cómo cambia la presión del yacimiento con el tiempo?
    X-axis: Tiempo (días)
    Y-axis: Presión (psi)
    """
    
    if output_path is None:
        output_path = (Path(__file__).parent.parent / 
                      "plots" / "E-1_pressure_evolution.png")
    
    if not USE_OPTIMIZED_LOADER:
        print("❌ E-1 requires optimized data loader with oct2py")
        return False
    
    # Load MRST data using optimized loader
    try:
        field_data = load_field_arrays()
        temporal_data = load_temporal_data()
        
        if not field_data or not temporal_data:
            raise ValueError("No field or temporal data available")
        
        # Check for required data
        if 'pressure' not in field_data:
            raise ValueError(
                f"❌ MISSING DATA: 'pressure' not found in field data\n"
                f"   Required variables: pressure\n"
                f"   Available variables: {list(field_data.keys())}\n"
                f"   Check MRST field arrays export.")
        
        pressure_data = field_data['pressure']  # [time, y, x]
        time_days = temporal_data['time_days']
        
        if len(pressure_data.shape) != 3:
            raise ValueError(
                f"❌ INVALID DATA: Pressure data should be 3D [time, y, x]\n"
                f"   Current shape: {pressure_data.shape}")
        
        # Calculate statistics for each timestep
        n_steps = pressure_data.shape[0]
        pressure_avg = np.zeros(n_steps)
        pressure_min = np.zeros(n_steps)
        pressure_max = np.zeros(n_steps)
        
        for i in range(n_steps):
            pressure_snapshot = pressure_data[i, :, :].flatten()
            pressure_avg[i] = np.mean(pressure_snapshot)
            pressure_min[i] = np.min(pressure_snapshot)
            pressure_max[i] = np.max(pressure_snapshot)
        
    except Exception as e:
        print(f"❌ E-1 REQUIRES REAL MRST DATA: {e}")
        return False
    
    # Create figure
    fig, ax = plt.subplots(1, 1, figsize=(14, 8))
    
    # Plot average pressure
    ax.plot(time_days, pressure_avg, 'b-', linewidth=4, 
           label='Presión Promedio', marker='o', markersize=6)
    
    # Add range as filled area
    ax.fill_between(time_days, pressure_min, pressure_max, 
                    alpha=0.3, color='blue', label='Rango Min-Max')
    
    ax.set_xlabel('Tiempo (días)', fontsize=14, fontweight='bold')
    ax.set_ylabel('Presión (psi)', fontsize=14, fontweight='bold')
    ax.set_title('E-1: Evolución de Presión del Yacimiento\n¿Cómo cambia la presión del yacimiento con el tiempo?', 
                fontsize=16, fontweight='bold')
    
    # Move legend outside plot area
    ax.legend(loc='center left', bbox_to_anchor=(1.02, 0.5), fontsize=12)
    ax.grid(True, alpha=0.3)
    
    # Add statistics outside plot area
    initial_avg = pressure_avg[0]
    final_avg = pressure_avg[-1]
    pressure_change = final_avg - initial_avg
    pressure_decline_rate = pressure_change / (time_days[-1] - time_days[0]) if len(time_days) > 1 else 0
    
    stats_text = (f'Estadísticas de Presión:\n'
                 f'Inicial: {initial_avg:.1f} psi\n'
                 f'Final: {final_avg:.1f} psi\n'
                 f'Cambio: {pressure_change:+.1f} psi\n'
                 f'Tasa: {pressure_decline_rate:.2f} psi/día\n'
                 f'Tiempo: {time_days[0]:.1f} - {time_days[-1]:.1f} días')
    
    ax.text(1.02, 0.98, stats_text, transform=ax.transAxes, 
            va='top', ha='left', fontsize=11, 
            bbox=dict(boxstyle='round', facecolor='lightblue', alpha=0.8))
    
    # Add source info
    ax.text(1.02, 0.65, 'Fuente: MRST\nDatos de campo\n(Simulación real)', 
            transform=ax.transAxes, va='top', ha='left', fontsize=10,
            bbox=dict(boxstyle='round', facecolor='lightgreen', alpha=0.8))
    
    # Adjust layout
    plt.subplots_adjust(right=0.75)
    
    os.makedirs(os.path.dirname(output_path), exist_ok=True)
    plt.savefig(output_path, dpi=150, bbox_inches='tight')
    plt.close()
    
    print(f"✅ E-1 Pressure evolution plot saved: {output_path}")
    return True


def plot_stress_evolution(output_path=None):
    """E-2: Evolución de esfuerzo efectivo promedio + rango
    Pregunta: ¿Cómo cambia el esfuerzo efectivo con el agotamiento?
    X-axis: Tiempo (días)
    Y-axis: Esfuerzo efectivo (psi)
    """
    
    if output_path is None:
        output_path = (Path(__file__).parent.parent / 
                      "plots" / "E-2_stress_evolution.png")
    
    if not USE_OPTIMIZED_LOADER:
        print("❌ E-2 requires optimized data loader with oct2py")
        return False
    
    # Load MRST data using optimized loader
    try:
        field_data = load_field_arrays()
        temporal_data = load_temporal_data()
        
        if not field_data or not temporal_data:
            raise ValueError("No field or temporal data available")
        
        # Check for required data
        if 'sigma_eff' not in field_data:
            raise ValueError(
                f"❌ MISSING DATA: 'sigma_eff' not found in field data\n"
                f"   Required variables: sigma_eff\n"
                f"   Available variables: {list(field_data.keys())}\n"
                f"   Check MRST field arrays export.")
        
        stress_data = field_data['sigma_eff']  # [time, y, x]
        time_days = temporal_data['time_days']
        
        if len(stress_data.shape) != 3:
            raise ValueError(
                f"❌ INVALID DATA: Stress data should be 3D [time, y, x]\n"
                f"   Current shape: {stress_data.shape}")
        
        # Calculate statistics for each timestep
        n_steps = stress_data.shape[0]
        stress_avg = np.zeros(n_steps)
        stress_min = np.zeros(n_steps)
        stress_max = np.zeros(n_steps)
        
        for i in range(n_steps):
            stress_snapshot = stress_data[i, :, :].flatten()
            stress_avg[i] = np.mean(stress_snapshot)
            stress_min[i] = np.min(stress_snapshot)
            stress_max[i] = np.max(stress_snapshot)
        
    except Exception as e:
        print(f"❌ E-2 REQUIRES REAL MRST DATA: {e}")
        return False
    
    # Create figure
    fig, ax = plt.subplots(1, 1, figsize=(14, 8))
    
    # Plot average stress
    ax.plot(time_days, stress_avg, 'r-', linewidth=4, 
           label='Esfuerzo Efectivo Promedio', marker='s', markersize=6)
    
    # Add range as filled area
    ax.fill_between(time_days, stress_min, stress_max, 
                    alpha=0.3, color='red', label='Rango Min-Max')
    
    ax.set_xlabel('Tiempo (días)', fontsize=14, fontweight='bold')
    ax.set_ylabel('Esfuerzo Efectivo (psi)', fontsize=14, fontweight='bold')
    ax.set_title('E-2: Evolución de Esfuerzo Efectivo\n¿Cómo cambia el esfuerzo efectivo con el agotamiento?', 
                fontsize=16, fontweight='bold')
    
    # Move legend outside plot area
    ax.legend(loc='center left', bbox_to_anchor=(1.02, 0.5), fontsize=12)
    ax.grid(True, alpha=0.3)
    
    # Add statistics outside plot area
    initial_avg = stress_avg[0]
    final_avg = stress_avg[-1]
    stress_change = final_avg - initial_avg
    stress_increase_rate = stress_change / (time_days[-1] - time_days[0]) if len(time_days) > 1 else 0
    
    stats_text = (f'Estadísticas de Esfuerzo:\n'
                 f'Inicial: {initial_avg:.1f} psi\n'
                 f'Final: {final_avg:.1f} psi\n'
                 f'Cambio: {stress_change:+.1f} psi\n'
                 f'Tasa: {stress_increase_rate:.2f} psi/día\n'
                 f'Tiempo: {time_days[0]:.1f} - {time_days[-1]:.1f} días')
    
    ax.text(1.02, 0.98, stats_text, transform=ax.transAxes, 
            va='top', ha='left', fontsize=11, 
            bbox=dict(boxstyle='round', facecolor='lightcoral', alpha=0.8))
    
    # Add source info
    ax.text(1.02, 0.65, 'Fuente: MRST\nDatos de campo\n(Simulación real)', 
            transform=ax.transAxes, va='top', ha='left', fontsize=10,
            bbox=dict(boxstyle='round', facecolor='lightgreen', alpha=0.8))
    
    # Adjust layout
    plt.subplots_adjust(right=0.75)
    
    os.makedirs(os.path.dirname(output_path), exist_ok=True)
    plt.savefig(output_path, dpi=150, bbox_inches='tight')
    plt.close()
    
    print(f"✅ E-2 Stress evolution plot saved: {output_path}")
    return True


def plot_porosity_evolution(output_path=None):
    """E-3: Evolución de porosidad promedio + rango
    Pregunta: ¿Cómo cambia la porosidad con la compactación?
    X-axis: Tiempo (días)
    Y-axis: Porosidad (-)
    """
    
    if output_path is None:
        output_path = (Path(__file__).parent.parent / 
                      "plots" / "E-3_porosity_evolution.png")
    
    if not USE_OPTIMIZED_LOADER:
        print("❌ E-3 requires optimized data loader with oct2py")
        return False
    
    # Load MRST data using optimized loader
    try:
        field_data = load_field_arrays()
        temporal_data = load_temporal_data()
        
        if not field_data or not temporal_data:
            raise ValueError("No field or temporal data available")
        
        # Check for required data
        if 'phi' not in field_data:
            raise ValueError(
                f"❌ MISSING DATA: 'phi' not found in field data\n"
                f"   Required variables: phi\n"
                f"   Available variables: {list(field_data.keys())}\n"
                f"   Check MRST field arrays export.")
        
        phi_data = field_data['phi']  # [time, y, x]
        time_days = temporal_data['time_days']
        
        if len(phi_data.shape) != 3:
            raise ValueError(
                f"❌ INVALID DATA: Porosity data should be 3D [time, y, x]\n"
                f"   Current shape: {phi_data.shape}")
        
        # Calculate statistics for each timestep
        n_steps = phi_data.shape[0]
        phi_avg = np.zeros(n_steps)
        phi_min = np.zeros(n_steps)
        phi_max = np.zeros(n_steps)
        
        for i in range(n_steps):
            phi_snapshot = phi_data[i, :, :].flatten()
            phi_avg[i] = np.mean(phi_snapshot)
            phi_min[i] = np.min(phi_snapshot)
            phi_max[i] = np.max(phi_snapshot)
        
    except Exception as e:
        print(f"❌ E-3 REQUIRES REAL MRST DATA: {e}")
        return False
    
    # Create figure
    fig, ax = plt.subplots(1, 1, figsize=(14, 8))
    
    # Plot average porosity
    ax.plot(time_days, phi_avg, 'g-', linewidth=4, 
           label='Porosidad Promedio', marker='^', markersize=6)
    
    # Add range as filled area
    ax.fill_between(time_days, phi_min, phi_max, 
                    alpha=0.3, color='green', label='Rango Min-Max')
    
    ax.set_xlabel('Tiempo (días)', fontsize=14, fontweight='bold')
    ax.set_ylabel('Porosidad (-)', fontsize=14, fontweight='bold')
    ax.set_title('E-3: Evolución de Porosidad\n¿Cómo cambia la porosidad con la compactación?', 
                fontsize=16, fontweight='bold')
    
    # Move legend outside plot area
    ax.legend(loc='center left', bbox_to_anchor=(1.02, 0.5), fontsize=12)
    ax.grid(True, alpha=0.3)
    
    # Add statistics outside plot area
    initial_avg = phi_avg[0]
    final_avg = phi_avg[-1]
    phi_change = final_avg - initial_avg
    phi_reduction_rate = phi_change / (time_days[-1] - time_days[0]) if len(time_days) > 1 else 0
    
    stats_text = (f'Estadísticas de Porosidad:\n'
                 f'Inicial: {initial_avg:.4f}\n'
                 f'Final: {final_avg:.4f}\n'
                 f'Cambio: {phi_change:+.4f}\n'
                 f'Tasa: {phi_reduction_rate:.6f} /día\n'
                 f'Tiempo: {time_days[0]:.1f} - {time_days[-1]:.1f} días')
    
    ax.text(1.02, 0.98, stats_text, transform=ax.transAxes, 
            va='top', ha='left', fontsize=11, 
            bbox=dict(boxstyle='round', facecolor='lightgreen', alpha=0.8))
    
    # Add source info
    ax.text(1.02, 0.65, 'Fuente: MRST\nDatos de campo\n(Simulación real)', 
            transform=ax.transAxes, va='top', ha='left', fontsize=10,
            bbox=dict(boxstyle='round', facecolor='lightgreen', alpha=0.8))
    
    # Adjust layout
    plt.subplots_adjust(right=0.75)
    
    os.makedirs(os.path.dirname(output_path), exist_ok=True)
    plt.savefig(output_path, dpi=150, bbox_inches='tight')
    plt.close()
    
    print(f"✅ E-3 Porosity evolution plot saved: {output_path}")
    return True


def plot_permeability_evolution(output_path=None):
    """E-4: Evolución de permeabilidad promedio + rango
    Pregunta: ¿Cómo cambia la permeabilidad con la compactación?
    X-axis: Tiempo (días)
    Y-axis: Permeabilidad (mD)
    """
    
    if output_path is None:
        output_path = (Path(__file__).parent.parent / 
                      "plots" / "E-4_permeability_evolution.png")
    
    if not USE_OPTIMIZED_LOADER:
        print("❌ E-4 requires optimized data loader with oct2py")
        return False
    
    # Load MRST data using optimized loader
    try:
        field_data = load_field_arrays()
        temporal_data = load_temporal_data()
        
        if not field_data or not temporal_data:
            raise ValueError("No field or temporal data available")
        
        # Check for required data
        if 'k' not in field_data:
            raise ValueError(
                f"❌ MISSING DATA: 'k' not found in field data\n"
                f"   Required variables: k\n"
                f"   Available variables: {list(field_data.keys())}\n"
                f"   Check MRST field arrays export.")
        
        k_data = field_data['k']  # [time, y, x]
        time_days = temporal_data['time_days']
        
        if len(k_data.shape) != 3:
            raise ValueError(
                f"❌ INVALID DATA: Permeability data should be 3D [time, y, x]\n"
                f"   Current shape: {k_data.shape}")
        
        # Calculate statistics for each timestep
        n_steps = k_data.shape[0]
        k_avg = np.zeros(n_steps)
        k_min = np.zeros(n_steps)
        k_max = np.zeros(n_steps)
        
        for i in range(n_steps):
            k_snapshot = k_data[i, :, :].flatten()
            k_avg[i] = np.mean(k_snapshot)
            k_min[i] = np.min(k_snapshot)
            k_max[i] = np.max(k_snapshot)
        
    except Exception as e:
        print(f"❌ E-4 REQUIRES REAL MRST DATA: {e}")
        return False
    
    # Create figure
    fig, ax = plt.subplots(1, 1, figsize=(14, 8))
    
    # Plot average permeability
    ax.plot(time_days, k_avg, 'purple', linewidth=4, 
           label='Permeabilidad Promedio', marker='d', markersize=6)
    
    # Add range as filled area
    ax.fill_between(time_days, k_min, k_max, 
                    alpha=0.3, color='purple', label='Rango Min-Max')
    
    ax.set_xlabel('Tiempo (días)', fontsize=14, fontweight='bold')
    ax.set_ylabel('Permeabilidad (mD)', fontsize=14, fontweight='bold')
    ax.set_title('E-4: Evolución de Permeabilidad\n¿Cómo cambia la permeabilidad con la compactación?', 
                fontsize=16, fontweight='bold')
    
    # Move legend outside plot area
    ax.legend(loc='center left', bbox_to_anchor=(1.02, 0.5), fontsize=12)
    ax.grid(True, alpha=0.3)
    
    # Add statistics outside plot area
    initial_avg = k_avg[0]
    final_avg = k_avg[-1]
    k_change = final_avg - initial_avg
    k_reduction_rate = k_change / (time_days[-1] - time_days[0]) if len(time_days) > 1 else 0
    
    stats_text = (f'Estadísticas de Permeabilidad:\n'
                 f'Inicial: {initial_avg:.2f} mD\n'
                 f'Final: {final_avg:.2f} mD\n'
                 f'Cambio: {k_change:+.2f} mD\n'
                 f'Tasa: {k_reduction_rate:.4f} mD/día\n'
                 f'Tiempo: {time_days[0]:.1f} - {time_days[-1]:.1f} días')
    
    ax.text(1.02, 0.98, stats_text, transform=ax.transAxes, 
            va='top', ha='left', fontsize=11, 
            bbox=dict(boxstyle='round', facecolor='plum', alpha=0.8))
    
    # Add source info
    ax.text(1.02, 0.65, 'Fuente: MRST\nDatos de campo\n(Simulación real)', 
            transform=ax.transAxes, va='top', ha='left', fontsize=10,
            bbox=dict(boxstyle='round', facecolor='lightgreen', alpha=0.8))
    
    # Adjust layout
    plt.subplots_adjust(right=0.75)
    
    os.makedirs(os.path.dirname(output_path), exist_ok=True)
    plt.savefig(output_path, dpi=150, bbox_inches='tight')
    plt.close()
    
    print(f"✅ E-4 Permeability evolution plot saved: {output_path}")
    return True


def plot_saturation_histogram_evolution(output_path=None):
    """E-5: Evolución de histograma de saturación de agua
    Pregunta: ¿Cómo evoluciona la distribución de saturación de agua?
    X-axis: Saturación de agua Sw (-)
    Y-axis: Frecuencia (# celdas)
    """
    
    if output_path is None:
        output_path = (Path(__file__).parent.parent / 
                      "plots" / "E-5_saturation_histogram_evolution.png")
    
    if not USE_OPTIMIZED_LOADER:
        print("❌ E-5 requires optimized data loader with oct2py")
        return False
    
    # Load MRST data using optimized loader
    try:
        field_data = load_field_arrays()
        temporal_data = load_temporal_data()
        
        if not field_data or not temporal_data:
            raise ValueError("No field or temporal data available")
        
        # Check for required data
        if 'sw' not in field_data:
            raise ValueError(
                f"❌ MISSING DATA: 'sw' not found in field data\n"
                f"   Required variables: sw\n"
                f"   Available variables: {list(field_data.keys())}\n"
                f"   Check MRST field arrays export.")
        
        sw_data = field_data['sw']  # [time, y, x]
        time_days = temporal_data['time_days']
        
        if len(sw_data.shape) != 3:
            raise ValueError(
                f"❌ INVALID DATA: Saturation data should be 3D [time, y, x]\n"
                f"   Current shape: {sw_data.shape}")
        
    except Exception as e:
        print(f"❌ E-5 REQUIRES REAL MRST DATA: {e}")
        return False
    
    # Create figure with subplots for different timesteps
    n_steps = sw_data.shape[0]
    
    # Select key timesteps for histogram display
    if n_steps >= 4:
        timestep_indices = [0, n_steps//3, 2*n_steps//3, n_steps-1]
    elif n_steps >= 2:
        timestep_indices = [0, n_steps-1]
    else:
        timestep_indices = [0]
    
    fig, axes = plt.subplots(2, 2, figsize=(16, 12))
    axes = axes.flatten()
    
    colors = ['blue', 'green', 'orange', 'red']
    
    for i, timestep_idx in enumerate(timestep_indices):
        if i < len(axes):
            ax = axes[i]
            
            # Get saturation data for this timestep
            sw_snapshot = sw_data[timestep_idx, :, :].flatten()
            
            # Create histogram
            ax.hist(sw_snapshot, bins=20, alpha=0.7, color=colors[i], 
                   edgecolor='black', linewidth=1)
            
            ax.set_xlabel('Saturación de Agua Sw (-)', fontsize=12, fontweight='bold')
            ax.set_ylabel('Frecuencia (# celdas)', fontsize=12, fontweight='bold')
            ax.set_title(f'Tiempo = {time_days[timestep_idx]:.1f} días', 
                        fontsize=14, fontweight='bold')
            ax.grid(True, alpha=0.3)
            
            # Add statistics
            stats_text = (f'Media: {np.mean(sw_snapshot):.3f}\n'
                         f'Desv.Est: {np.std(sw_snapshot):.3f}\n'
                         f'Min: {np.min(sw_snapshot):.3f}\n'
                         f'Max: {np.max(sw_snapshot):.3f}')
            
            ax.text(0.98, 0.98, stats_text, transform=ax.transAxes, 
                   va='top', ha='right', fontsize=10, 
                   bbox=dict(boxstyle='round', facecolor='lightblue', alpha=0.8))
    
    # Hide unused subplots
    for i in range(len(timestep_indices), len(axes)):
        axes[i].set_visible(False)
    
    # Add overall title
    fig.suptitle('E-5: Evolución de Histograma de Saturación de Agua\n¿Cómo evoluciona la distribución de saturación de agua?', 
                fontsize=16, fontweight='bold')
    
    # Add source info
    fig.text(0.99, 0.01, 'Fuente: MRST (Simulación real)', 
             ha='right', va='bottom', fontsize=10,
             bbox=dict(boxstyle='round', facecolor='lightgreen', alpha=0.8))
    
    plt.tight_layout()
    
    os.makedirs(os.path.dirname(output_path), exist_ok=True)
    plt.savefig(output_path, dpi=150, bbox_inches='tight')
    plt.close()
    
    print(f"✅ E-5 Saturation histogram evolution plot saved: {output_path}")
    return True


def main():
    """Main function"""
    print("📈 Generating Category E: Global Evolution...")
    print("=" * 70)
    print("⚠️  IMPORTANT: This script requires real MRST simulation data.")
    print("   E-1, E-2, E-3, E-4, E-5: ALL require real MRST data (no synthetic fallback)")
    print("   Uses optimized data loader with oct2py")
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
    
    if not plot_pressure_evolution():
        success = False
    if not plot_stress_evolution():
        success = False
    if not plot_porosity_evolution():
        success = False
    if not plot_permeability_evolution():
        success = False
    if not plot_saturation_histogram_evolution():
        success = False
    
    if success:
        print("✅ Category E global evolution plots complete!")
    else:
        print("❌ Category E incomplete - missing MRST data")
    return success


if __name__ == "__main__":
    main() 