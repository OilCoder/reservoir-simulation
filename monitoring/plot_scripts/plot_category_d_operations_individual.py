#!/usr/bin/env python3
"""
Category D: Operations & Scheduling - REQUIRES REAL MRST DATA

Generates individual plots for operational parameters:
D-1: Rate schedule (time vs rate by phase/well) - REQUIRES REAL MRST DATA
D-2: BHP limits (time vs pressure constraints) - REQUIRES REAL MRST DATA
D-3: Voidage ratio (time vs volume balance) - REQUIRES REAL MRST DATA
D-4: PV injected vs Recovery factor - REQUIRES REAL MRST DATA

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


def load_well_solutions():
    """Load well solution data from MRST simulation - REQUIRED FOR ALL D PLOTS"""
    
    data_path = Path("/workspace/data")
    
    # Look for well solution files
    wellsol_files = sorted(glob.glob(str(data_path / "wells/wellSols_*.mat")))
    
    if not wellsol_files:
        raise FileNotFoundError(
            f"❌ MISSING DATA: No wellSols files found in {data_path}\n"
            f"   Required: wells/wellSols_*.mat files from MRST simulation\n"
            f"   Run MRST simulation and export well solutions first.")
    
    print(f"✅ Found {len(wellsol_files)} well solution files")
    
    # Load all well solution data
    all_wellsols = []
    for wellsol_file in wellsol_files:
        try:
            wellsol_data = parse_octave_mat_file(wellsol_file)
            all_wellsols.append(wellsol_data)
        except Exception as e:
            raise ValueError(
                f"❌ INVALID DATA: Could not parse {wellsol_file}\n"
                f"   Error: {e}\n"
                f"   Check MRST well solution export format.")
    
    return all_wellsols


def load_schedule_data():
    """Load schedule data from MRST simulation - REQUIRED FOR ALL D PLOTS"""
    
    data_path = Path("/workspace/data")
    schedule_file = data_path / "schedule/schedule.mat"
    
    if not schedule_file.exists():
        raise FileNotFoundError(
            f"❌ MISSING DATA: Schedule file not found: {schedule_file}\n"
            f"   Required: schedule/schedule.mat from MRST simulation\n"
            f"   Run MRST create_schedule.m first.")
    
    schedule_data = parse_octave_mat_file(schedule_file)
    
    if not schedule_data:
        raise ValueError(
            f"❌ INVALID DATA: Could not parse {schedule_file}\n"
            f"   Check MRST schedule export format.")
    
    print("✅ Loaded schedule data successfully")
    return schedule_data


def plot_d1_rate_schedule(output_path=None):
    """D-1: Rate schedule - REQUIRES REAL MRST DATA
    Question: Are filling, sweep, and taper stages well timed?
    X-axis: Time (d)
    Y-axis: Rate (STB/d)
    Color: Phase/Well
    """
    
    if output_path is None:
        output_path = (Path(__file__).parent.parent / 
                      "plots" / "D-1_rate_schedule.png")
    
    # Load real MRST data - NO FALLBACK TO SYNTHETIC
    wellsols = load_well_solutions()
    schedule_data = load_schedule_data()
    
    # Check for required data
    required_vars = ['time', 'well_rates', 'well_names']
    missing_vars = []
    
    for var in required_vars:
        if var not in schedule_data:
            missing_vars.append(var)
    
    if missing_vars:
        raise ValueError(
            f"❌ MISSING DATA: Variables {missing_vars} not found in schedule\n"
            f"   Required variables: {required_vars}\n"
            f"   Available variables: {list(schedule_data.keys())}\n"
            f"   Check MRST create_schedule.m export.")
    
    # Extract real data
    time_days = schedule_data['time'].flatten()
    well_rates = schedule_data['well_rates']
    well_names = schedule_data['well_names']
    
    if len(time_days) == 0:
        raise ValueError(
            f"❌ EMPTY DATA: Time array is empty\n"
            f"   Check MRST schedule generation.")
    
    # Create figure for production rates
    fig, ax = plt.subplots(1, 1, figsize=(14, 8))
    
    # Plot production rates from real data
    producer_count = 0
    colors = ['r-', 'r--', 'r:', 'r-.']
    markers = ['o', 's', '^', 'd']
    
    for i, well_name in enumerate(well_names):
        if well_name.startswith('P'):  # Producer wells
            if producer_count < len(colors):
                ax.plot(time_days, well_rates[i, :], colors[producer_count], 
                       linewidth=3, label=well_name, 
                       marker=markers[producer_count], markersize=4)
                producer_count += 1
    
    # Add statistics outside plot area
    stats_text = (f'Production Summary:\n'
                 f'Time span: {time_days[0]:.1f} - {time_days[-1]:.1f} days\n'
                 f'Total producers: {producer_count}\n'
                 f'Data points: {len(time_days)}')
    
    ax.text(1.02, 0.98, stats_text, transform=ax.transAxes, va='top', ha='left',
            fontsize=11, bbox=dict(boxstyle='round', facecolor='lightblue', alpha=0.8))
    
    # Add data source info
    ax.text(1.02, 0.75, 'Source: MRST\nSchedule data\n(Real simulation)', 
            transform=ax.transAxes, va='top', ha='left', fontsize=10,
            bbox=dict(boxstyle='round', facecolor='lightgreen', alpha=0.8))
    
    ax.set_xlabel('Time (days)', fontsize=14, fontweight='bold')
    ax.set_ylabel('Production Rate (STB/d)', fontsize=14, fontweight='bold')
    ax.set_title('D-1: Rate Schedule\nQuestion: Are operational phases well timed?\nProduction Rate Schedule', 
                 fontsize=16, fontweight='bold')
    
    # Move legend outside plot area
    ax.legend(loc='center left', bbox_to_anchor=(1.02, 0.5), fontsize=12)
    ax.grid(True, alpha=0.3)
    
    # Adjust layout
    plt.subplots_adjust(right=0.75)
    
    os.makedirs(os.path.dirname(output_path), exist_ok=True)
    plt.savefig(output_path, dpi=150, bbox_inches='tight')
    plt.close()
    
    print(f"✅ D-1 Production rate schedule plot saved: {output_path}")
    
    # Create figure for injection rates
    fig, ax = plt.subplots(1, 1, figsize=(14, 8))
    
    # Plot injection rates from real data
    injector_count = 0
    colors = ['b-', 'b--', 'b:', 'b-.', 'c-']
    markers = ['o', 's', '^', 'd', 'v']
    
    for i, well_name in enumerate(well_names):
        if well_name.startswith('I'):  # Injector wells
            if injector_count < len(colors):
                ax.plot(time_days, well_rates[i, :], colors[injector_count], 
                       linewidth=3, label=well_name, 
                       marker=markers[injector_count], markersize=4)
                injector_count += 1
    
    # Add statistics outside plot area
    stats_text = (f'Injection Summary:\n'
                 f'Time span: {time_days[0]:.1f} - {time_days[-1]:.1f} days\n'
                 f'Total injectors: {injector_count}\n'
                 f'Data points: {len(time_days)}')
    
    ax.text(1.02, 0.98, stats_text, transform=ax.transAxes, va='top', ha='left',
            fontsize=11, bbox=dict(boxstyle='round', facecolor='lightblue', alpha=0.8))
    
    # Add data source info
    ax.text(1.02, 0.75, 'Source: MRST\nSchedule data\n(Real simulation)', 
            transform=ax.transAxes, va='top', ha='left', fontsize=10,
            bbox=dict(boxstyle='round', facecolor='lightgreen', alpha=0.8))
    
    ax.set_xlabel('Time (days)', fontsize=14, fontweight='bold')
    ax.set_ylabel('Injection Rate (STB/d)', fontsize=14, fontweight='bold')
    ax.set_title('D-1: Rate Schedule\nQuestion: Are operational phases well timed?\nInjection Rate Schedule', 
                 fontsize=16, fontweight='bold')
    
    # Move legend outside plot area
    ax.legend(loc='center left', bbox_to_anchor=(1.02, 0.5), fontsize=12)
    ax.grid(True, alpha=0.3)
    
    # Adjust layout
    plt.subplots_adjust(right=0.75)
    
    # Save injection plot
    injection_output_path = output_path.parent / "D-1_injection_schedule.png"
    plt.savefig(injection_output_path, dpi=150, bbox_inches='tight')
    plt.close()
    
    print(f"✅ D-1 Injection rate schedule plot saved: {injection_output_path}")


def plot_d2_bhp_limits(output_path=None):
    """D-2: BHP limits - REQUIRES REAL MRST DATA
    Question: Do wells respect integrity constraints?
    X-axis: Time
    Y-axis: Pressure (psi)
    Color: Well
    """
    
    if output_path is None:
        output_path = (Path(__file__).parent.parent / 
                      "plots" / "D-2_bhp_limits.png")
    
    # Load real MRST data - NO FALLBACK TO SYNTHETIC
    wellsols = load_well_solutions()
    schedule_data = load_schedule_data()
    
    # Check for required data
    required_vars = ['time', 'well_bhp', 'well_names', 'bhp_limits']
    missing_vars = []
    
    for var in required_vars:
        if var not in schedule_data:
            missing_vars.append(var)
    
    if missing_vars:
        raise ValueError(
            f"❌ MISSING DATA: Variables {missing_vars} not found in schedule\n"
            f"   Required variables: {required_vars}\n"
            f"   Available variables: {list(schedule_data.keys())}\n"
            f"   Check MRST create_schedule.m BHP export.")
    
    # Extract real data
    time_days = schedule_data['time'].flatten()
    well_bhp = schedule_data['well_bhp']
    well_names = schedule_data['well_names']
    bhp_limits = schedule_data['bhp_limits']
    
    if len(time_days) == 0:
        raise ValueError(
            f"❌ EMPTY DATA: Time array is empty\n"
            f"   Check MRST schedule generation.")
    
    # Create figure for producer BHP constraints
    fig, ax = plt.subplots(1, 1, figsize=(14, 8))
    
    # Plot producer BHP data
    producer_count = 0
    colors = ['r', 'g', 'b', 'm']
    
    for i, well_name in enumerate(well_names):
        if well_name.startswith('P'):  # Producer wells
            if producer_count < len(colors):
                color = colors[producer_count]
                
                # Plot BHP limits (dashed)
                ax.plot(time_days, bhp_limits[i, :], f'{color}--', 
                       linewidth=3, alpha=0.7, label=f'{well_name} Min Limit')
                
                # Plot actual BHP (solid)
                ax.plot(time_days, well_bhp[i, :], f'{color}-', 
                       linewidth=3, label=f'{well_name} Actual')
                
                producer_count += 1
    
    # Add statistics outside plot area
    stats_text = (f'Producer BHP Summary:\n'
                 f'Time span: {time_days[0]:.1f} - {time_days[-1]:.1f} days\n'
                 f'Total producers: {producer_count}\n'
                 f'Data points: {len(time_days)}')
    
    ax.text(1.02, 0.98, stats_text, transform=ax.transAxes, va='top', ha='left',
            fontsize=11, bbox=dict(boxstyle='round', facecolor='lightblue', alpha=0.8))
    
    # Add data source info
    ax.text(1.02, 0.75, 'Source: MRST\nWell solutions\n(Real simulation)', 
            transform=ax.transAxes, va='top', ha='left', fontsize=10,
            bbox=dict(boxstyle='round', facecolor='lightgreen', alpha=0.8))
    
    ax.set_xlabel('Time (days)', fontsize=14, fontweight='bold')
    ax.set_ylabel('Pressure (psi)', fontsize=14, fontweight='bold')
    ax.set_title('D-2: BHP Limits\nQuestion: Do wells respect integrity constraints?\nProducer BHP Limits', 
                 fontsize=16, fontweight='bold')
    
    # Move legend outside plot area
    ax.legend(loc='center left', bbox_to_anchor=(1.02, 0.5), fontsize=10)
    ax.grid(True, alpha=0.3)
    
    # Adjust layout
    plt.subplots_adjust(right=0.75)
    
    os.makedirs(os.path.dirname(output_path), exist_ok=True)
    plt.savefig(output_path, dpi=150, bbox_inches='tight')
    plt.close()
    
    print(f"✅ D-2 Producer BHP limits plot saved: {output_path}")
    
    # Create figure for injector BHP constraints
    fig, ax = plt.subplots(1, 1, figsize=(14, 8))
    
    # Plot injector BHP data
    injector_count = 0
    colors = ['b', 'c', 'g', 'm', 'y']
    
    for i, well_name in enumerate(well_names):
        if well_name.startswith('I'):  # Injector wells
            if injector_count < len(colors):
                color = colors[injector_count]
                
                # Plot BHP limits (dashed)
                ax.plot(time_days, bhp_limits[i, :], f'{color}--', 
                       linewidth=3, alpha=0.7, label=f'{well_name} Max Limit')
                
                # Plot actual BHP (solid)
                ax.plot(time_days, well_bhp[i, :], f'{color}-', 
                       linewidth=3, label=f'{well_name} Actual')
                
                injector_count += 1
    
    # Add statistics outside plot area
    stats_text = (f'Injector BHP Summary:\n'
                 f'Time span: {time_days[0]:.1f} - {time_days[-1]:.1f} days\n'
                 f'Total injectors: {injector_count}\n'
                 f'Data points: {len(time_days)}')
    
    ax.text(1.02, 0.98, stats_text, transform=ax.transAxes, va='top', ha='left',
            fontsize=11, bbox=dict(boxstyle='round', facecolor='lightblue', alpha=0.8))
    
    # Add data source info
    ax.text(1.02, 0.75, 'Source: MRST\nWell solutions\n(Real simulation)', 
            transform=ax.transAxes, va='top', ha='left', fontsize=10,
            bbox=dict(boxstyle='round', facecolor='lightgreen', alpha=0.8))
    
    ax.set_xlabel('Time (days)', fontsize=14, fontweight='bold')
    ax.set_ylabel('Pressure (psi)', fontsize=14, fontweight='bold')
    ax.set_title('D-2: BHP Limits\nQuestion: Do wells respect integrity constraints?\nInjector BHP Limits', 
                 fontsize=16, fontweight='bold')
    
    # Move legend outside plot area
    ax.legend(loc='center left', bbox_to_anchor=(1.02, 0.5), fontsize=10)
    ax.grid(True, alpha=0.3)
    
    # Adjust layout
    plt.subplots_adjust(right=0.75)
    
    # Save injector plot
    injector_output_path = output_path.parent / "D-2_injector_bhp_limits.png"
    plt.savefig(injector_output_path, dpi=150, bbox_inches='tight')
    plt.close()
    
    print(f"✅ D-2 Injector BHP limits plot saved: {injector_output_path}")


def plot_d3_voidage_ratio(output_path=None):
    """D-3: Voidage ratio - REQUIRES REAL MRST DATA
    Question: Is reservoir pressure maintained?
    X-axis: Time
    Y-axis: Voidage ratio (-)
    """
    
    if output_path is None:
        output_path = (Path(__file__).parent.parent / 
                      "plots" / "D-3_voidage_ratio.png")
    
    # Load real MRST data - NO FALLBACK TO SYNTHETIC
    wellsols = load_well_solutions()
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
    
    # Create figure
    fig, ax = plt.subplots(1, 1, figsize=(14, 8))
    
    ax.plot(time_days, voidage_ratio, 'g-', linewidth=4, label='Voidage Ratio')
    ax.axhline(y=1.0, color='r', linestyle='--', linewidth=2, label='Perfect Balance')
    ax.axhline(y=0.9, color='orange', linestyle=':', linewidth=2, label='90% Replacement')
    
    # Add statistics outside plot area
    stats_text = (f'Voidage Statistics:\n'
                 f'Mean ratio: {np.mean(voidage_ratio):.3f}\n'
                 f'Std ratio: {np.std(voidage_ratio):.3f}\n'
                 f'Range: {np.min(voidage_ratio):.3f} - {np.max(voidage_ratio):.3f}\n'
                 f'Data points: {len(time_days)}')
    
    ax.text(1.02, 0.98, stats_text, transform=ax.transAxes, va='top', ha='left',
            fontsize=11, bbox=dict(boxstyle='round', facecolor='lightblue', alpha=0.8))
    
    # Add data source info
    ax.text(1.02, 0.75, 'Source: MRST\nSchedule data\n(Real simulation)', 
            transform=ax.transAxes, va='top', ha='left', fontsize=10,
            bbox=dict(boxstyle='round', facecolor='lightgreen', alpha=0.8))
    
    ax.set_xlabel('Time (days)', fontsize=14, fontweight='bold')
    ax.set_ylabel('Voidage Ratio (-)', fontsize=14, fontweight='bold')
    ax.set_title('D-3: Voidage Ratio\nQuestion: Is reservoir pressure maintained?', 
                 fontsize=16, fontweight='bold')
    
    # Move legend outside plot area
    ax.legend(loc='center left', bbox_to_anchor=(1.02, 0.5), fontsize=12)
    ax.grid(True, alpha=0.3)
    
    # Adjust layout
    plt.subplots_adjust(right=0.75)
    
    os.makedirs(os.path.dirname(output_path), exist_ok=True)
    plt.savefig(output_path, dpi=150, bbox_inches='tight')
    plt.close()
    
    print(f"✅ D-3 Voidage ratio plot saved: {output_path}")


def plot_d4_pv_vs_recovery(output_path=None):
    """D-4: PV injected vs Recovery factor - REQUIRES REAL MRST DATA
    Question: How efficient is the recovery process?
    X-axis: PV injected (-)
    Y-axis: Recovery factor (%)
    """
    
    if output_path is None:
        output_path = (Path(__file__).parent.parent / 
                      "plots" / "D-4_pv_vs_recovery.png")
    
    # Load real MRST data - NO FALLBACK TO SYNTHETIC
    wellsols = load_well_solutions()
    schedule_data = load_schedule_data()
    
    # Check for required data
    required_vars = ['pv_injected', 'recovery_factor']
    missing_vars = []
    
    for var in required_vars:
        if var not in schedule_data:
            missing_vars.append(var)
    
    if missing_vars:
        raise ValueError(
            f"❌ MISSING DATA: Variables {missing_vars} not found in schedule\n"
            f"   Required variables: {required_vars}\n"
            f"   Available variables: {list(schedule_data.keys())}\n"
            f"   Check MRST recovery calculation export.")
    
    # Extract real data
    pv_injected = schedule_data['pv_injected'].flatten()
    recovery_factor = schedule_data['recovery_factor'].flatten()
    
    if len(pv_injected) == 0:
        raise ValueError(
            f"❌ EMPTY DATA: PV injected array is empty\n"
            f"   Check MRST recovery calculation.")
    
    # Create figure
    fig, ax = plt.subplots(1, 1, figsize=(14, 8))
    
    ax.plot(pv_injected, recovery_factor * 100, 'b-', linewidth=4, 
           marker='o', markersize=6, label='Recovery Curve')
    
    # Add reference lines
    ax.axhline(y=30, color='r', linestyle='--', linewidth=2, label='30% RF Target')
    ax.axvline(x=1.0, color='g', linestyle=':', linewidth=2, label='1 PV Injected')
    
    # Add statistics outside plot area
    stats_text = (f'Recovery Statistics:\n'
                 f'Max RF: {np.max(recovery_factor) * 100:.1f}%\n'
                 f'RF at 1 PV: {np.interp(1.0, pv_injected, recovery_factor) * 100:.1f}%\n'
                 f'PV range: {np.min(pv_injected):.2f} - {np.max(pv_injected):.2f}\n'
                 f'Data points: {len(pv_injected)}')
    
    ax.text(1.02, 0.98, stats_text, transform=ax.transAxes, va='top', ha='left',
            fontsize=11, bbox=dict(boxstyle='round', facecolor='lightblue', alpha=0.8))
    
    # Add data source info
    ax.text(1.02, 0.75, 'Source: MRST\nSchedule data\n(Real simulation)', 
            transform=ax.transAxes, va='top', ha='left', fontsize=10,
            bbox=dict(boxstyle='round', facecolor='lightgreen', alpha=0.8))
    
    ax.set_xlabel('PV Injected (-)', fontsize=14, fontweight='bold')
    ax.set_ylabel('Recovery Factor (%)', fontsize=14, fontweight='bold')
    ax.set_title('D-4: PV Injected vs Recovery Factor\nQuestion: How efficient is the recovery process?', 
                 fontsize=16, fontweight='bold')
    
    # Move legend outside plot area
    ax.legend(loc='center left', bbox_to_anchor=(1.02, 0.5), fontsize=12)
    ax.grid(True, alpha=0.3)
    
    # Adjust layout
    plt.subplots_adjust(right=0.75)
    
    os.makedirs(os.path.dirname(output_path), exist_ok=True)
    plt.savefig(output_path, dpi=150, bbox_inches='tight')
    plt.close()
    
    print(f"✅ D-4 PV vs Recovery plot saved: {output_path}")


def main():
    """Main function"""
    print("⚙️  Generating Category D: Operations & Scheduling...")
    print("=" * 70)
    print("⚠️  IMPORTANT: This script requires real MRST simulation data.")
    print("   D-1, D-2, D-3, D-4: Require real MRST well solutions (no synthetic fallback)")
    print("=" * 70)
    
    # Generate all plots for Category D - will fail if data not available
    try:
        plot_d1_rate_schedule()
        plot_d2_bhp_limits()
        plot_d3_voidage_ratio()
        plot_d4_pv_vs_recovery()
    except (FileNotFoundError, ValueError) as e:
        print(f"\n❌ CATEGORY D INCOMPLETE: {e}")
        print(f"   To fix: Run MRST simulation and ensure well solution export")
        return False
    
    print("✅ Category D operations plots complete!")
    return True


if __name__ == "__main__":
    main() 