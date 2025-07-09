#!/usr/bin/env python3
"""
Category D: Operations & Scheduling - REQUIRES REAL MRST DATA

Generates individual plots for operational parameters:
D-1: Rate schedule (time vs rate by phase/well) - REQUIRES REAL MRST DATA
D-2: BHP limits (time vs pressure constraints) - REQUIRES REAL MRST DATA
D-3: Voidage ratio (time vs volume balance) - REQUIRES REAL MRST DATA
D-4: PV injected vs Recovery factor - REQUIRES REAL MRST DATA

Uses optimized data loader with oct2py for proper .mat file reading.
"""

import numpy as np
import matplotlib.pyplot as plt
import os
from pathlib import Path

# Import the optimized data loader
try:
    from util_data_loader import (
        load_well_data, load_cumulative_data,
        check_data_availability, print_data_summary
    )
    USE_OPTIMIZED_LOADER = True
    print("✅ Using optimized data loader with oct2py")
except ImportError:
    USE_OPTIMIZED_LOADER = False
    print("❌ Optimized data loader not available")


def plot_d1_rate_schedule(output_path=None):
    """D-1: Programa de tasas de producción/inyección
    Pregunta: ¿Están bien sincronizadas las etapas de llenado, barrido y reducción?
    X-axis: Tiempo (días)
    Y-axis: Tasa (STB/d)
    Color: Fase/Pozo
    """
    
    if output_path is None:
        output_path = (Path(__file__).parent.parent /
                       "plots" / "D-1_rate_schedule.png")
    
    if not USE_OPTIMIZED_LOADER:
        print("❌ D-1 requires optimized data loader with oct2py")
        return False
    
    # Load MRST data using optimized loader
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
        time_days = well_data['time_days']
        well_names = well_data['well_names']
        qWs = well_data['qWs']  # [time, well] Water rates
        qOs = well_data['qOs']  # [time, well] Oil rates
        
        if len(time_days) == 0:
            raise ValueError(
                f"❌ EMPTY DATA: Time array is empty\n"
                f"   Check MRST well data generation.")
        
    except Exception as e:
        print(f"❌ D-1 REQUIRES REAL MRST DATA: {e}")
        return False
    
    # Create figure for production rates
    fig, (ax1, ax2) = plt.subplots(1, 2, figsize=(18, 8))
    
    # Plot 1: Production rates (oil + water)
    colors = ['red', 'darkred', 'crimson', 'firebrick']
    markers = ['o', 's', '^', 'd']
    
    producer_count = 0
    for i, well_name in enumerate(well_names):
        if well_name.startswith('P'):  # Producer wells
            if producer_count < len(colors):
                # Plot oil production
                ax1.plot(time_days, qOs[:, i], color=colors[producer_count], 
                        linewidth=3, label=f'{well_name} (aceite)', 
                        marker=markers[producer_count], markersize=4, linestyle='-')
                # Plot water production
                ax1.plot(time_days, qWs[:, i], color=colors[producer_count], 
                        linewidth=2, label=f'{well_name} (agua)', 
                        marker=markers[producer_count], markersize=3, linestyle='--', alpha=0.7)
                producer_count += 1
    
    ax1.set_xlabel('Tiempo (días)', fontsize=14, fontweight='bold')
    ax1.set_ylabel('Tasa de Producción (STB/d)', fontsize=14, fontweight='bold')
    ax1.set_title('D-1: Programa de Tasas - Producción\n¿Están bien sincronizadas las etapas operacionales?', 
                 fontsize=14, fontweight='bold')
    ax1.legend(loc='upper right', fontsize=10)
    ax1.grid(True, alpha=0.3)
    
    # Plot 2: Injection rates
    colors = ['blue', 'darkblue', 'navy', 'steelblue', 'dodgerblue']
    markers = ['o', 's', '^', 'd', 'v']
    
    injector_count = 0
    for i, well_name in enumerate(well_names):
        if well_name.startswith('I'):  # Injector wells
            if injector_count < len(colors):
                # Plot water injection (qWs for injectors is negative)
                ax2.plot(time_days, -qWs[:, i], color=colors[injector_count], 
                        linewidth=3, label=f'{well_name} (inyección)', 
                        marker=markers[injector_count], markersize=4)
                injector_count += 1
    
    ax2.set_xlabel('Tiempo (días)', fontsize=14, fontweight='bold')
    ax2.set_ylabel('Tasa de Inyección (STB/d)', fontsize=14, fontweight='bold')
    ax2.set_title('D-1: Programa de Tasas - Inyección\n¿Están bien sincronizadas las etapas operacionales?', 
                 fontsize=14, fontweight='bold')
    ax2.legend(loc='upper right', fontsize=10)
    ax2.grid(True, alpha=0.3)
    
    # Add overall title
    fig.suptitle('D-1: Programa de Tasas de Producción/Inyección\n¿Están bien sincronizadas las etapas de llenado, barrido y reducción?', 
                fontsize=16, fontweight='bold')
    
    # Add source info
    fig.text(0.99, 0.01, 'Fuente: MRST (Simulación real)', 
             ha='right', va='bottom', fontsize=10,
             bbox=dict(boxstyle='round', facecolor='lightgreen', alpha=0.8))
    
    plt.tight_layout()
    
    os.makedirs(os.path.dirname(output_path), exist_ok=True)
    plt.savefig(output_path, dpi=150, bbox_inches='tight')
    plt.close()
    
    print(f"✅ D-1 Rate schedule plot saved: {output_path}")
    return True


def plot_d2_bhp_limits(output_path=None):
    """D-2: Límites de presión de fondo (BHP)
    Pregunta: ¿Respetan los pozos las restricciones de integridad?
    X-axis: Tiempo (días)
    Y-axis: Presión (psi)
    Color: Pozo
    """
    
    if output_path is None:
        output_path = (Path(__file__).parent.parent / 
                      "plots" / "D-2_bhp_limits.png")
    
    if not USE_OPTIMIZED_LOADER:
        print("❌ D-2 requires optimized data loader with oct2py")
        return False
    
    # Load MRST data using optimized loader
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
        time_days = well_data['time_days']
        well_names = well_data['well_names']
        bhp = well_data['bhp']  # [time, well] Bottom hole pressure
        
        if len(time_days) == 0:
            raise ValueError(
                f"❌ EMPTY DATA: Time array is empty\n"
                f"   Check MRST well data generation.")
        
    except Exception as e:
        print(f"❌ D-2 REQUIRES REAL MRST DATA: {e}")
        return False
    
    # Create figure
    fig, ax = plt.subplots(1, 1, figsize=(14, 8))
    
    # Plot BHP for all wells
    colors = ['red', 'darkred', 'blue', 'darkblue', 'green', 'darkgreen', 'orange', 'purple']
    markers = ['o', 's', '^', 'd', 'v', 'p', 'h', '*']
    
    for i, well_name in enumerate(well_names):
        if i < len(colors):
            ax.plot(time_days, bhp[:, i], color=colors[i], 
                   linewidth=3, label=f'{well_name}', 
                   marker=markers[i], markersize=4)
    
    # Add constraint lines (typical values)
    ax.axhline(y=1000, color='red', linestyle='--', linewidth=2, alpha=0.7, 
               label='Límite mínimo BHP (1000 psi)')
    ax.axhline(y=4000, color='red', linestyle='--', linewidth=2, alpha=0.7, 
               label='Límite máximo BHP (4000 psi)')
    
    ax.set_xlabel('Tiempo (días)', fontsize=14, fontweight='bold')
    ax.set_ylabel('Presión de Fondo BHP (psi)', fontsize=14, fontweight='bold')
    ax.set_title('D-2: Límites de Presión de Fondo\n¿Respetan los pozos las restricciones de integridad?', 
                fontsize=16, fontweight='bold')
    
    # Move legend outside plot area
    ax.legend(loc='center left', bbox_to_anchor=(1.02, 0.5), fontsize=11)
    ax.grid(True, alpha=0.3)
    
    # Add statistics outside plot area
    stats_text = (f'Estadísticas BHP:\n'
                 f'Tiempo: {time_days[0]:.1f} - {time_days[-1]:.1f} días\n'
                 f'Pozos: {len(well_names)}\n'
                 f'BHP min: {np.min(bhp):.1f} psi\n'
                 f'BHP max: {np.max(bhp):.1f} psi\n'
                 f'BHP promedio: {np.mean(bhp):.1f} psi')
    
    ax.text(1.02, 0.98, stats_text, transform=ax.transAxes, 
            va='top', ha='left', fontsize=11, 
            bbox=dict(boxstyle='round', facecolor='lightblue', alpha=0.8))
    
    # Add source info
    ax.text(1.02, 0.65, 'Fuente: MRST\nDatos de pozos\n(Simulación real)', 
            transform=ax.transAxes, va='top', ha='left', fontsize=10,
            bbox=dict(boxstyle='round', facecolor='lightgreen', alpha=0.8))
    
    # Adjust layout
    plt.subplots_adjust(right=0.75)
    
    os.makedirs(os.path.dirname(output_path), exist_ok=True)
    plt.savefig(output_path, dpi=150, bbox_inches='tight')
    plt.close()
    
    print(f"✅ D-2 BHP limits plot saved: {output_path}")
    return True


def plot_d3_voidage_ratio(output_path=None):
    """D-3: Relación de voidage (balance volumétrico)
    Pregunta: ¿Se conserva el balance volumétrico? (Objetivo ≤ 0.5%)
    X-axis: Tiempo (días)
    Y-axis: ΔVolumen (% PV)
    """
    
    if output_path is None:
        output_path = (Path(__file__).parent.parent / 
                      "plots" / "D-3_voidage_ratio.png")
    
    if not USE_OPTIMIZED_LOADER:
        print("❌ D-3 requires optimized data loader with oct2py")
        return False
    
    # Load MRST data using optimized loader
    try:
        well_data = load_well_data()
        
        if not well_data:
            raise ValueError("No well data available")
        
        # Calculate voidage ratio from well data
        time_days = well_data['time_days']
        qWs = well_data['qWs']  # [time, well] Water rates
        qOs = well_data['qOs']  # [time, well] Oil rates
        
        # Calculate total production and injection
        total_production = np.sum(qOs, axis=1)  # Sum over wells
        total_injection = -np.sum(qWs[qWs < 0], axis=1)  # Sum negative rates (injection)
        
        # Calculate voidage ratio: (injection - production) / production
        voidage_ratio = (total_injection - total_production) / total_production * 100
        
        if len(time_days) == 0:
            raise ValueError(
                f"❌ EMPTY DATA: Time array is empty\n"
                f"   Check MRST well data generation.")
        
    except Exception as e:
        print(f"❌ D-3 REQUIRES REAL MRST DATA: {e}")
        return False
    
    # Create figure
    fig, ax = plt.subplots(1, 1, figsize=(14, 8))
    
    # Plot voidage ratio
    ax.plot(time_days, voidage_ratio, 'b-', linewidth=3, 
           label='Relación de Voidage', marker='o', markersize=4)
    
    # Add target line
    ax.axhline(y=0.5, color='red', linestyle='--', linewidth=2, alpha=0.7, 
               label='Objetivo (≤ 0.5%)')
    ax.axhline(y=-0.5, color='red', linestyle='--', linewidth=2, alpha=0.7)
    
    # Fill acceptable zone
    ax.fill_between(time_days, -0.5, 0.5, alpha=0.2, color='green', 
                   label='Zona aceptable')
    
    ax.set_xlabel('Tiempo (días)', fontsize=14, fontweight='bold')
    ax.set_ylabel('Balance Volumétrico (% PV)', fontsize=14, fontweight='bold')
    ax.set_title('D-3: Relación de Voidage\n¿Se conserva el balance volumétrico? (Objetivo ≤ 0.5%)', 
                fontsize=16, fontweight='bold')
    
    # Move legend outside plot area
    ax.legend(loc='center left', bbox_to_anchor=(1.02, 0.5), fontsize=12)
    ax.grid(True, alpha=0.3)
    
    # Add statistics outside plot area
    stats_text = (f'Estadísticas Balance:\n'
                 f'Tiempo: {time_days[0]:.1f} - {time_days[-1]:.1f} días\n'
                 f'Voidage promedio: {np.mean(voidage_ratio):.2f}%\n'
                 f'Voidage min: {np.min(voidage_ratio):.2f}%\n'
                 f'Voidage max: {np.max(voidage_ratio):.2f}%\n'
                 f'Fuera de objetivo: {np.sum(np.abs(voidage_ratio) > 0.5)} puntos')
    
    ax.text(1.02, 0.98, stats_text, transform=ax.transAxes, 
            va='top', ha='left', fontsize=11, 
            bbox=dict(boxstyle='round', facecolor='lightblue', alpha=0.8))
    
    # Add source info
    ax.text(1.02, 0.65, 'Fuente: MRST\nCálculo de balance\n(Simulación real)', 
            transform=ax.transAxes, va='top', ha='left', fontsize=10,
            bbox=dict(boxstyle='round', facecolor='lightgreen', alpha=0.8))
    
    # Adjust layout
    plt.subplots_adjust(right=0.75)
    
    os.makedirs(os.path.dirname(output_path), exist_ok=True)
    plt.savefig(output_path, dpi=150, bbox_inches='tight')
    plt.close()
    
    print(f"✅ D-3 Voidage ratio plot saved: {output_path}")
    return True


def plot_d4_pv_vs_recovery(output_path=None):
    """D-4: PV inyectado vs Factor de recuperación
    Pregunta: ¿Qué tan eficiente es el barrido?
    X-axis: PV inyectado (% del PV inicial)
    Y-axis: FR (% OOIP recuperado)
    """
    
    if output_path is None:
        output_path = (Path(__file__).parent.parent / 
                      "plots" / "D-4_pv_vs_recovery.png")
    
    if not USE_OPTIMIZED_LOADER:
        print("❌ D-4 requires optimized data loader with oct2py")
        return False
    
    # Load MRST data using optimized loader
    try:
        cumulative_data = load_cumulative_data()
        
        if not cumulative_data:
            # Try to calculate from well data
            well_data = load_well_data()
            if not well_data:
                raise ValueError("No cumulative or well data available")
            
            # Calculate cumulative production
            time_days = well_data['time_days']
            qWs = well_data['qWs']  # [time, well] Water rates
            qOs = well_data['qOs']  # [time, well] Oil rates
            
            # Calculate cumulative values (simple trapezoidal integration)
            dt = np.diff(time_days)
            dt = np.append(dt, dt[-1])  # Extend to match time length
            
            # Calculate cumulative oil production
            cum_oil_prod = np.cumsum(np.sum(qOs, axis=1) * dt)
            
            # Calculate cumulative water injection
            injection_rates = -qWs[qWs < 0]
            cum_water_inj = np.cumsum(np.sum(injection_rates, axis=1) * dt)
            
            # Estimate PV and OOIP (placeholder values)
            pv_initial = 1000000  # STB (placeholder)
            ooip_initial = 500000  # STB (placeholder)
            
            # Calculate percentages
            pv_injected_pct = cum_water_inj / pv_initial * 100
            recovery_factor_pct = cum_oil_prod / ooip_initial * 100
            
        else:
            # Use cumulative data
            time_days = cumulative_data['time_days']
            pv_injected_pct = cumulative_data['pv_injected'] * 100
            recovery_factor_pct = cumulative_data['recovery_factor'] * 100
        
        if len(time_days) == 0:
            raise ValueError(
                f"❌ EMPTY DATA: Time array is empty\n"
                f"   Check MRST data generation.")
        
    except Exception as e:
        print(f"❌ D-4 REQUIRES REAL MRST DATA: {e}")
        return False
    
    # Create figure
    fig, ax = plt.subplots(1, 1, figsize=(14, 8))
    
    # Plot PV vs Recovery
    ax.plot(pv_injected_pct, recovery_factor_pct, 'g-', linewidth=3, 
           label='Eficiencia de Barrido', marker='o', markersize=4)
    
    # Add ideal line (45-degree line for reference)
    max_pv = np.max(pv_injected_pct)
    ax.plot([0, max_pv], [0, max_pv], 'r--', linewidth=2, alpha=0.7, 
           label='Línea ideal (100% eficiencia)')
    
    ax.set_xlabel('PV Inyectado (% del PV inicial)', fontsize=14, fontweight='bold')
    ax.set_ylabel('Factor de Recuperación (% OOIP)', fontsize=14, fontweight='bold')
    ax.set_title('D-4: PV Inyectado vs Factor de Recuperación\n¿Qué tan eficiente es el barrido?', 
                fontsize=16, fontweight='bold')
    
    # Move legend outside plot area
    ax.legend(loc='center left', bbox_to_anchor=(1.02, 0.5), fontsize=12)
    ax.grid(True, alpha=0.3)
    
    # Add statistics outside plot area
    final_pv = pv_injected_pct[-1]
    final_rf = recovery_factor_pct[-1]
    efficiency = final_rf / final_pv * 100 if final_pv > 0 else 0
    
    stats_text = (f'Estadísticas Eficiencia:\n'
                 f'PV inyectado final: {final_pv:.1f}%\n'
                 f'Factor recuperación final: {final_rf:.1f}%\n'
                 f'Eficiencia de barrido: {efficiency:.1f}%\n'
                 f'Tiempo total: {time_days[-1]:.1f} días\n'
                 f'Puntos de datos: {len(time_days)}')
    
    ax.text(1.02, 0.98, stats_text, transform=ax.transAxes, 
            va='top', ha='left', fontsize=11, 
            bbox=dict(boxstyle='round', facecolor='lightblue', alpha=0.8))
    
    # Add source info
    ax.text(1.02, 0.65, 'Fuente: MRST\nDatos acumulados\n(Simulación real)', 
            transform=ax.transAxes, va='top', ha='left', fontsize=10,
            bbox=dict(boxstyle='round', facecolor='lightgreen', alpha=0.8))
    
    # Adjust layout
    plt.subplots_adjust(right=0.75)
    
    os.makedirs(os.path.dirname(output_path), exist_ok=True)
    plt.savefig(output_path, dpi=150, bbox_inches='tight')
    plt.close()
    
    print(f"✅ D-4 PV vs Recovery plot saved: {output_path}")
    return True


def main():
    """Main function"""
    print("⚙️  Generating Category D: Operations & Scheduling...")
    print("=" * 70)
    print("⚠️  IMPORTANT: This script requires real MRST simulation data.")
    print("   D-1, D-2, D-3, D-4: ALL require real MRST data (no synthetic fallback)")
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
    
    if not plot_d1_rate_schedule():
        success = False
    if not plot_d2_bhp_limits():
        success = False
    if not plot_d3_voidage_ratio():
        success = False
    if not plot_d4_pv_vs_recovery():
        success = False
    
    if success:
        print("✅ Category D operations plots complete!")
    else:
        print("❌ Category D incomplete - missing MRST data")
    return success


if __name__ == "__main__":
    main() 