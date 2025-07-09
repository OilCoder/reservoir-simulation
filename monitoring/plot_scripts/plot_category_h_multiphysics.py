#!/usr/bin/env python3
"""
Category H: Multiphysics & Diagnostics - THEORETICAL AND REAL DATA

Generates individual plots for advanced multiphysics analysis:
H-1: Flujo fraccional fw(Sw) - THEORETICAL CURVES (OK - based on physics)
H-2: Análisis de sensibilidad tornado - REQUIRES REAL MRST DATA

Uses oct2py for proper .mat file reading from optimized data structure.
"""

import numpy as np
import matplotlib.pyplot as plt
import glob
import os
from pathlib import Path

# Import the optimized data loader
try:
    from util_data_loader import (
        load_schedule_data, load_well_data, load_temporal_data,
        calculate_voidage_ratio, check_data_availability, print_data_summary
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


def load_schedule_data_local():
    """Load schedule data using optimized loader"""
    
    if not USE_OPTIMIZED_LOADER:
        raise ImportError("❌ Optimized data loader not available")
    
    try:
        schedule_data = load_schedule_data()
        print("✅ Loaded schedule data successfully")
        return schedule_data
    except Exception as e:
        print(f"❌ Failed to load schedule data: {e}")
        return None


def plot_fractional_flow(output_path=None):
    """H-1: Flujo fraccional fw(Sw) - THEORETICAL CURVES (OK)
    Pregunta: ¿Cómo afecta la relación de viscosidades al flujo?
    
    Note: Uses theoretical Corey-type curves based on physics - acceptable.
    """
    
    if output_path is None:
        output_path = (Path(__file__).parent.parent / 
                      "plots" / "H-1_fractional_flow.png")
    
    # Create figure with extra space for legends
    fig, ax = plt.subplots(1, 1, figsize=(14, 8))
    
    # Water saturation range
    sw = np.linspace(0.2, 0.8, 100)
    
    # Viscosity ratio
    viscosity_ratio = 0.5 / 2.0  # μw/μo
    
    # Relative permeability curves (Corey-type) - THEORETICAL
    krw = ((sw - 0.2) / (0.8 - 0.2)) ** 2
    kro = ((0.8 - sw) / (0.8 - 0.2)) ** 2
    
    # Fractional flow function
    fw = 1 / (1 + (kro/krw) * (1/viscosity_ratio))
    
    # Handle division by zero at endpoints
    fw[0] = 0  # At Swc, fw = 0
    fw[-1] = 1  # At Sor, fw = 1
    
    # Plot fractional flow curve
    ax.plot(sw, fw, 'b-', linewidth=4, label='fw (water)', marker='o', markersize=4)
    ax.plot(sw, 1-fw, 'r-', linewidth=4, label='fo (oil)', marker='s', markersize=4)
    
    # Calculate shock front
    swc = 0.2
    shock_sw = 0.5  # Approximate shock saturation
    shock_fw = fw[np.argmin(np.abs(sw - shock_sw))]
    
    # Add tangent line from Swc to shock point
    ax.plot([swc, shock_sw], [0, shock_fw], 'g--', linewidth=3, alpha=0.7, 
            label='Shock front tangent')
    
    # Mark critical points
    ax.plot(swc, 0, 'go', markersize=10, label=f'Swc = {swc}')
    ax.plot(shock_sw, shock_fw, 'ro', markersize=10, 
            label=f'Shock front (fw = {shock_fw:.3f})')
    
    ax.set_xlabel('Saturación de Agua Sw (-)', fontsize=14, fontweight='bold')
    ax.set_ylabel('Flujo Fraccional (-)', fontsize=14, fontweight='bold')
    ax.set_title('H-1: Curva de Flujo Fraccional Agua-Aceite\n' +
                '¿Cómo afecta la relación de viscosidades al flujo?', 
                fontsize=16, fontweight='bold')
    ax.grid(True, alpha=0.3)
    ax.set_xlim(0.15, 0.85)
    ax.set_ylim(0, 1.05)
    
    # Move legend outside plot area
    ax.legend(loc='center left', bbox_to_anchor=(1.02, 0.5), fontsize=12)
    
    # Add theoretical model info outside plot area
    model_info = (f'Theoretical Model:\n'
                 f'Corey-type kr curves\n'
                 f'μw/μo = {viscosity_ratio:.2f}\n'
                 f'Swc = {swc:.1f}\n'
                 f'Sor = {0.8:.1f}\n'
                 f'Physics-based (OK)')
    
    ax.text(1.02, 0.98, model_info, transform=ax.transAxes, va='top', ha='left',
            fontsize=11, bbox=dict(boxstyle='round', facecolor='lightgreen', alpha=0.8))
    
    # Add fractional flow statistics
    fw_stats = (f'Flow Statistics:\n'
               f'Shock fw: {shock_fw:.3f}\n'
               f'Breakthrough Sw: {shock_sw:.3f}\n'
               f'Max dfw/dSw: {np.max(np.gradient(fw, sw)):.3f}')
    
    ax.text(1.02, 0.75, fw_stats, transform=ax.transAxes, va='top', ha='left',
            fontsize=11, bbox=dict(boxstyle='round', facecolor='lightblue', alpha=0.8))
    
    # Adjust layout
    plt.subplots_adjust(right=0.75)
    
    os.makedirs(os.path.dirname(output_path), exist_ok=True)
    plt.savefig(output_path, dpi=150, bbox_inches='tight')
    plt.close()
    
    print(f"✅ H-1 Fractional flow plot saved: {output_path}")


def plot_kr_sensitivity(output_path=None):
    """H-2: dkr/dSw sensitivity analysis - THEORETICAL CURVES (OK)
    Question: How sensitive are kr curves to Sw changes?
    
    Note: Uses theoretical Corey-type curves based on physics - this is acceptable.
    """
    
    if output_path is None:
        output_path = (Path(__file__).parent.parent / 
                      "plots" / "H-2_kr_sensitivity.png")
    
    # Create two separate figures for Kr curves and mobility
    # Figure 1: Kr curves and their derivatives
    fig1, ax1 = plt.subplots(1, 1, figsize=(14, 8))
    
    # Water saturation range
    sw = np.linspace(0.2, 0.8, 100)
    
    # Relative permeability curves (Corey-type) - THEORETICAL
    krw = ((sw - 0.2) / (0.8 - 0.2)) ** 2
    kro = ((0.8 - sw) / (0.8 - 0.2)) ** 2
    
    # Calculate derivatives
    dkrw_dsw = np.gradient(krw, sw)
    dkro_dsw = np.gradient(kro, sw)
    
    # Plot Kr curves
    ax1.plot(sw, krw, 'b-', linewidth=4, label='krw', marker='o', markersize=4)
    ax1.plot(sw, kro, 'r-', linewidth=4, label='kro', marker='s', markersize=4)
    
    # Create twin axis for derivatives
    ax1_twin = ax1.twinx()
    ax1_twin.plot(sw, dkrw_dsw, 'b--', linewidth=3, alpha=0.7, label='dkrw/dSw')
    ax1_twin.plot(sw, dkro_dsw, 'r--', linewidth=3, alpha=0.7, label='dkro/dSw')
    
    ax1.set_xlabel('Water Saturation (Sw)', fontsize=14, fontweight='bold')
    ax1.set_ylabel('Relative Permeability', fontsize=14, fontweight='bold', color='black')
    ax1_twin.set_ylabel('Derivative (dkr/dSw)', fontsize=14, fontweight='bold', color='gray')
    ax1.set_title('H-2: Kr Curves and Sensitivity\nQuestion: How sensitive are kr curves to Sw changes?', 
                  fontsize=16, fontweight='bold')
    ax1.grid(True, alpha=0.3)
    
    # Move legends outside plot area
    lines1, labels1 = ax1.get_legend_handles_labels()
    lines2, labels2 = ax1_twin.get_legend_handles_labels()
    ax1.legend(lines1 + lines2, labels1 + labels2, loc='center left', 
               bbox_to_anchor=(1.02, 0.5), fontsize=12)
    
    # Add statistics outside plot area
    max_dkrw_idx = np.argmax(np.abs(dkrw_dsw))
    max_dkro_idx = np.argmax(np.abs(dkro_dsw))
    
    stats_text = (f'Sensitivity Statistics:\n'
                 f'Max |dkrw/dSw|: {np.abs(dkrw_dsw[max_dkrw_idx]):.3f}\n'
                 f'   at Sw = {sw[max_dkrw_idx]:.3f}\n'
                 f'Max |dkro/dSw|: {np.abs(dkro_dsw[max_dkro_idx]):.3f}\n'
                 f'   at Sw = {sw[max_dkro_idx]:.3f}')
    
    ax1.text(1.02, 0.98, stats_text, transform=ax1.transAxes, va='top', ha='left',
             fontsize=11, bbox=dict(boxstyle='round', facecolor='lightyellow', alpha=0.8))
    
    # Add theoretical model info
    ax1.text(1.02, 0.75, 'Theoretical Model:\nCorey-type kr curves\nPhysics-based (OK)', 
             transform=ax1.transAxes, va='top', ha='left', fontsize=10,
             bbox=dict(boxstyle='round', facecolor='lightgreen', alpha=0.8))
    
    # Adjust layout
    plt.subplots_adjust(right=0.75)
    
    os.makedirs(os.path.dirname(output_path), exist_ok=True)
    plt.savefig(output_path, dpi=150, bbox_inches='tight')
    plt.close()
    
    print(f"✅ H-2 Kr sensitivity plot saved: {output_path}")
    
    # Figure 2: Mobility and mobility derivatives
    fig2, ax2 = plt.subplots(1, 1, figsize=(14, 8))
    
    # Calculate mobilities
    mobility_w = krw / 0.5  # krw / μw
    mobility_o = kro / 2.0  # kro / μo
    total_mobility = mobility_w + mobility_o
    
    dmobility_w_dsw = np.gradient(mobility_w, sw)
    dmobility_o_dsw = np.gradient(mobility_o, sw)
    dtotal_mobility_dsw = np.gradient(total_mobility, sw)
    
    # Plot mobility curves
    ax2.plot(sw, mobility_w, 'b-', linewidth=4, label='λw (krw/μw)', marker='o', markersize=4)
    ax2.plot(sw, mobility_o, 'r-', linewidth=4, label='λo (kro/μo)', marker='s', markersize=4)
    ax2.plot(sw, total_mobility, 'k-', linewidth=4, label='λt (total)', marker='^', markersize=4)
    
    # Create twin axis for derivatives
    ax2_twin = ax2.twinx()
    ax2_twin.plot(sw, dmobility_w_dsw, 'b--', linewidth=3, alpha=0.7, label='dλw/dSw')
    ax2_twin.plot(sw, dmobility_o_dsw, 'r--', linewidth=3, alpha=0.7, label='dλo/dSw')
    ax2_twin.plot(sw, dtotal_mobility_dsw, 'k--', linewidth=3, alpha=0.7, label='dλt/dSw')
    
    ax2.set_xlabel('Water Saturation (Sw)', fontsize=14, fontweight='bold')
    ax2.set_ylabel('Mobility (kr/μ)', fontsize=14, fontweight='bold', color='black')
    ax2_twin.set_ylabel('Mobility Derivative', fontsize=14, fontweight='bold', color='gray')
    ax2.set_title('H-2: Mobility and Sensitivity\nQuestion: How do mobility ratios affect flow?', 
                  fontsize=16, fontweight='bold')
    ax2.grid(True, alpha=0.3)
    
    # Move legends outside plot area
    lines3, labels3 = ax2.get_legend_handles_labels()
    lines4, labels4 = ax2_twin.get_legend_handles_labels()
    ax2.legend(lines3 + lines4, labels3 + labels4, loc='center left', 
               bbox_to_anchor=(1.02, 0.5), fontsize=11)
    
    # Add mobility statistics outside plot area
    max_mobility_w_idx = np.argmax(mobility_w)
    max_total_mobility_idx = np.argmax(total_mobility)
    
    mobility_stats = (f'Mobility Statistics:\n'
                     f'Max λw: {mobility_w[max_mobility_w_idx]:.3f}\n'
                     f'   at Sw = {sw[max_mobility_w_idx]:.3f}\n'
                     f'Max λt: {total_mobility[max_total_mobility_idx]:.3f}\n'
                     f'   at Sw = {sw[max_total_mobility_idx]:.3f}\n'
                     f'μw/μo ratio: {2.0/0.5:.1f}')
    
    ax2.text(1.02, 0.98, mobility_stats, transform=ax2.transAxes, va='top', ha='left',
             fontsize=11, bbox=dict(boxstyle='round', facecolor='lightblue', alpha=0.8))
    
    # Add theoretical model info
    ax2.text(1.02, 0.75, 'Theoretical Model:\nCorey-type kr curves\nPhysics-based (OK)', 
             transform=ax2.transAxes, va='top', ha='left', fontsize=10,
             bbox=dict(boxstyle='round', facecolor='lightgreen', alpha=0.8))
    
    # Adjust layout
    plt.subplots_adjust(right=0.75)
    
    # Save mobility plot
    mobility_output_path = output_path.parent / "H-2_mobility_sensitivity.png"
    plt.savefig(mobility_output_path, dpi=150, bbox_inches='tight')
    plt.close()
    
    print(f"✅ H-2 Mobility sensitivity plot saved: {mobility_output_path}")


def plot_h2_tornado_sensitivity(output_path=None):
    """H-2: Análisis de sensibilidad tornado - THEORETICAL PLACEHOLDER
    Pregunta: ¿Qué parámetros tienen mayor impacto en la producción?
    """
    
    if output_path is None:
        output_path = (Path(__file__).parent.parent / 
                      "plots" / "H-2_tornado_sensitivity.png")
    
    # Theoretical tornado plot (placeholder)
    parameters = ['Porosidad φ', 'Permeabilidad k', 'Viscosidad μo', 
                  'Presión inicial P₀', 'Tasa de inyección qi']
    
    low_values = [-15, -25, -8, -12, -18]
    high_values = [12, 20, 10, 8, 15]
    
    fig, ax = plt.subplots(1, 1, figsize=(12, 8))
    
    y_positions = np.arange(len(parameters))
    
    for i, (param, low, high) in enumerate(zip(parameters, low_values, high_values)):
        ax.barh(i, low, height=0.6, color='red', alpha=0.7, 
                label='Impacto negativo' if i == 0 else '')
        ax.barh(i, high, height=0.6, color='green', alpha=0.7,
                label='Impacto positivo' if i == 0 else '')
        
        ax.text(-1, i, param, ha='right', va='center', fontsize=12)
        ax.text(low - 1, i, f'{low}%', ha='right', va='center', fontsize=10)
        ax.text(high + 1, i, f'{high}%', ha='left', va='center', fontsize=10)
    
    ax.set_xlabel('Cambio en Producción (%)', fontsize=14, fontweight='bold')
    ax.set_title('H-2: Análisis de Sensibilidad Tornado\n' +
                '¿Qué parámetros tienen mayor impacto?', 
                fontsize=16, fontweight='bold')
    ax.set_yticks([])
    ax.grid(True, alpha=0.3, axis='x')
    ax.legend(loc='upper right', fontsize=12)
    ax.axvline(x=0, color='black', linewidth=2, alpha=0.8)
    
    # Add info
    model_info = ('Análisis Teórico:\n'
                 'Requiere datos de\n'
                 'múltiples simulaciones\n'
                 'con parámetros variados')
    
    ax.text(0.02, 0.98, model_info, transform=ax.transAxes, 
            va='top', ha='left', fontsize=11, 
            bbox=dict(boxstyle='round', facecolor='lightyellow', alpha=0.8))
    
    # Add data source info
    source_text = 'Fuente: Teórico\nRequiere análisis\nde sensibilidad MRST'
    ax.text(0.98, 0.02, source_text, transform=ax.transAxes, 
            va='bottom', ha='right', fontsize=12, 
            bbox=dict(boxstyle='round', facecolor='lightcoral', alpha=0.8))
    
    os.makedirs(os.path.dirname(output_path), exist_ok=True)
    plt.savefig(output_path, dpi=150, bbox_inches='tight')
    plt.close()
    
    print(f"✅ H-2 Tornado sensitivity plot saved: {output_path}")
    return True


def plot_voidage_ratio_evolution(output_path=None):
    """H-3: Voidage ratio evolution - REQUIRES REAL MRST DATA
    Question: How does voidage ratio change over time?
    """
    
    if output_path is None:
        output_path = (Path(__file__).parent.parent / 
                      "plots" / "H-3_voidage_evolution.png")
    
    # Load real MRST data - NO FALLBACK TO SYNTHETIC
    schedule_data = load_schedule_data()
    
    # Check for required data
    required_vars = ['time', 'production_rates', 'injection_rates']
    missing_vars = []
    
    for var in required_vars:
        if var not in schedule_data:
            missing_vars.append(var)
    
    if missing_vars:
        raise ValueError(
            f"❌ MISSING DATA: Variables {missing_vars} not found in schedule\n"
            f"   Required variables: {required_vars}\n"
            f"   Available variables: {list(schedule_data.keys())}\n"
            f"   Check MRST voidage calculation export.")
    
    # Extract real data
    time_days = schedule_data['time'].flatten()
    production_rates = schedule_data['production_rates'].flatten()
    injection_rates = schedule_data['injection_rates'].flatten()
    
    if len(time_days) == 0:
        raise ValueError(
            f"❌ EMPTY DATA: Time array is empty\n"
            f"   Check MRST schedule generation.")
    
    # Calculate voidage ratio from real data
    voidage_ratio = injection_rates / production_rates
    
    # Calculate cumulative voidage balance
    dt = np.diff(time_days)
    dt = np.append(dt, dt[-1])  # Extend to match array length
    
    cum_production = np.cumsum(production_rates * dt)
    cum_injection = np.cumsum(injection_rates * dt)
    cum_voidage_balance = cum_injection - cum_production
    
    # Create figure with two subplots
    fig, (ax1, ax2) = plt.subplots(2, 1, figsize=(14, 10))
    
    # Top subplot: Instantaneous voidage ratio
    ax1.plot(time_days, voidage_ratio, 'g-', linewidth=4, label='Voidage Ratio')
    ax1.axhline(y=1.0, color='r', linestyle='--', linewidth=2, label='Perfect Balance')
    ax1.axhline(y=0.9, color='orange', linestyle=':', linewidth=2, label='90% Replacement')
    
    ax1.set_ylabel('Voidage Ratio (-)', fontsize=14, fontweight='bold')
    ax1.set_title('H-3: Voidage Ratio Evolution\nQuestion: How does voidage ratio change over time?', 
                 fontsize=16, fontweight='bold')
    ax1.legend(fontsize=12)
    ax1.grid(True, alpha=0.3)
    
    # Bottom subplot: Cumulative voidage balance
    ax2.plot(time_days, cum_voidage_balance, 'purple', linewidth=4, 
            label='Cumulative Voidage Balance')
    ax2.axhline(y=0, color='black', linestyle='-', alpha=0.5, linewidth=1)
    
    ax2.set_xlabel('Time (days)', fontsize=14, fontweight='bold')
    ax2.set_ylabel('Cumulative Balance (STB)', fontsize=14, fontweight='bold')
    ax2.legend(fontsize=12)
    ax2.grid(True, alpha=0.3)
    
    # Add statistics
    mean_ratio = np.mean(voidage_ratio)
    std_ratio = np.std(voidage_ratio)
    final_balance = cum_voidage_balance[-1]
    
    stats_text = (f'Voidage Statistics:\n'
                 f'Mean ratio: {mean_ratio:.3f}\n'
                 f'Std ratio: {std_ratio:.3f}\n'
                 f'Final balance: {final_balance:.0f} STB\n'
                 f'Time span: {time_days[0]:.1f} - {time_days[-1]:.1f} days\n'
                 f'Data points: {len(time_days)}')
    
    fig.text(0.02, 0.98, stats_text, transform=fig.transFigure, va='top', ha='left',
             fontsize=11, bbox=dict(boxstyle='round', facecolor='lightblue', alpha=0.8))
    
    # Add data source info
    fig.text(0.02, 0.75, 'Source: MRST\nSchedule data\n(Real simulation)', 
             transform=fig.transFigure, va='top', ha='left', fontsize=10,
             bbox=dict(boxstyle='round', facecolor='lightgreen', alpha=0.8))
    
    plt.tight_layout()
    
    os.makedirs(os.path.dirname(output_path), exist_ok=True)
    plt.savefig(output_path, dpi=150, bbox_inches='tight')
    plt.close()
    
    print(f"✅ H-3 Voidage evolution plot saved: {output_path}")


def main():
    """Main function"""
    print("🔬 Generating Category H: Multiphysics & Diagnostics...")
    print("=" * 70)
    print("⚠️  IMPORTANT: This script requires real MRST simulation data.")
    print("   H-1: Uses theoretical curves (acceptable)")
    print("   H-2: Requires sensitivity analysis data")
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
    
    # Generate plots
    success = True
    
    # H-1: Theoretical fractional flow (always works)
    plot_fractional_flow()
    
    # H-2: Tornado sensitivity (placeholder for now)
    plot_h2_tornado_sensitivity()
    
    if success:
        print("✅ Category H multiphysics plots complete!")
    else:
        print("❌ Category H incomplete - missing MRST data")
    
    return success


if __name__ == "__main__":
    main() 