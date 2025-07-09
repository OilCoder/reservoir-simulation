#!/usr/bin/env python3
"""
MRST Monitoring System - Launch Script

This script launches the MRST monitoring system with categorized plots.
Uses oct2py for proper .mat file reading from the optimized data structure.

Categories:
- A: Fluid & Rock Properties (Individual)
- B: Initial Conditions  
- C: Geometry (Individual)
- D: Operations (Individual)
- E: Global Evolution
- G: Spatial Maps with Well Locations & Animations
- H: Multiphysics

Data Structure:
/workspace/data/
├── initial/
│   └── initial_conditions.mat
├── static/
│   └── static_data.mat
├── temporal/
│   └── time_data.mat
├── dynamic/
│   ├── fields/
│   │   └── field_arrays.mat
│   └── wells/
│       └── well_data.mat
└── metadata/
    └── metadata.mat
"""

import os
import sys
import subprocess
from pathlib import Path
import argparse

# Add the plot_scripts directory to the path
script_dir = Path(__file__).parent
plot_scripts_dir = script_dir / "plot_scripts"
sys.path.insert(0, str(plot_scripts_dir))

# Try to import the optimized data loader
try:
    from plot_scripts.util_data_loader import (
        check_data_availability, print_data_summary
    )
    USE_OPTIMIZED_LOADER = True
    print("✅ Using optimized data loader with oct2py")
except ImportError:
    USE_OPTIMIZED_LOADER = False
    print("❌ Optimized data loader not available")


def check_oct2py_installation():
    """Check if oct2py is installed"""
    try:
        import oct2py
        print("✅ oct2py is installed")
        return True
    except ImportError:
        print("❌ oct2py is not installed")
        print("   Install with: pip install oct2py")
        return False


def check_data_structure():
    """Check if the optimized data structure exists"""
    data_dir = Path("/workspace/data")
    
    if not data_dir.exists():
        print(f"❌ Data directory not found: {data_dir}")
        return False
    
    required_structure = [
        "initial/initial_conditions.mat",
        "static/static_data.mat", 
        "temporal/time_data.mat",
        "dynamic/fields/field_arrays.mat",
        "dynamic/wells/well_data.mat",
        "metadata/metadata.mat"
    ]
    
    missing_files = []
    for file_path in required_structure:
        full_path = data_dir / file_path
        if not full_path.exists():
            missing_files.append(file_path)
    
    if missing_files:
        print("❌ Missing data files:")
        for file_path in missing_files:
            print(f"   - {file_path}")
        return False
    
    print("✅ Optimized data structure found")
    return True


def run_category_script(category):
    """Run a specific category script"""
    script_name = f"plot_category_{category}.py"
    script_path = plot_scripts_dir / script_name
    
    if not script_path.exists():
        print(f"❌ Category script not found: {script_path}")
        return False
    
    print(f"🚀 Running {script_name}...")
    print("=" * 50)
    
    try:
        result = subprocess.run([
            sys.executable, str(script_path)
        ], capture_output=True, text=True, cwd=str(plot_scripts_dir))
        
        if result.returncode == 0:
            print(f"✅ {script_name} completed successfully")
            if result.stdout:
                print(result.stdout)
        else:
            print(f"❌ {script_name} failed")
            if result.stderr:
                print(result.stderr)
            return False
            
    except Exception as e:
        print(f"❌ Error running {script_name}: {e}")
        return False
    
    return True


def run_all_categories():
    """Run all category scripts"""
    categories = ['a_fluid_rock_individual', 'b_initial_conditions', 
                 'c_geometry_individual', 'd_operations_individual',
                 'e_global_evolution', 'f_well_performance', 
                 'g_maps_animated', 'h_multiphysics']
    
    print("🚀 Running all monitoring categories...")
    print("=" * 70)
    
    success_count = 0
    total_count = len(categories)
    
    for category in categories:
        print(f"\n📊 Category {category.upper()}:")
        if run_category_script(category):
            success_count += 1
        else:
            print(f"⚠️  Category {category} failed - continuing with others")
    
    print(f"\n📈 Summary: {success_count}/{total_count} categories completed")
    
    if success_count == total_count:
        print("✅ All monitoring categories completed successfully!")
    else:
        print(f"⚠️  {total_count - success_count} categories failed")
    
    return success_count == total_count


def main():
    """Main function"""
    parser = argparse.ArgumentParser(
        description="MRST Monitoring System - Launch Script")
    parser.add_argument(
        '--category', '-c', 
        choices=['a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'all'],
        default='all',
        help='Category to run (default: all)')
    parser.add_argument(
        '--check-only', action='store_true',
        help='Only check data availability without running plots')
    
    args = parser.parse_args()
    
    print("🔍 MRST Monitoring System - Launch Script")
    print("=" * 70)
    print("📊 Using optimized data structure with oct2py")
    print("=" * 70)
    
    # Check prerequisites
    if not check_oct2py_installation():
        print("❌ Cannot proceed without oct2py")
        return False
    
    if not USE_OPTIMIZED_LOADER:
        print("❌ Cannot proceed without optimized data loader")
        return False
    
    # Check data structure
    if not check_data_structure():
        print("❌ Cannot proceed without optimized data structure")
        print("   Run MRST simulation first to generate data")
        return False
    
    # Check data availability
    print("\n📊 Checking data availability...")
    try:
        availability = check_data_availability()
        print_data_summary()
    except Exception as e:
        print(f"❌ Error checking data availability: {e}")
        return False
    
    if args.check_only:
        print("✅ Data availability check completed")
        return True
    
    # Run selected category or all
    if args.category == 'all':
        return run_all_categories()
    else:
        category_map = {
            'a': 'a_fluid_rock_individual',
            'b': 'b_initial_conditions', 
            'c': 'c_geometry_individual',
            'd': 'd_operations_individual',
            'e': 'e_global_evolution',
            'f': 'f_well_performance',
            'g': 'g_maps_animated',
            'h': 'h_multiphysics'
        }
        
        category_name = category_map[args.category]
        return run_category_script(category_name)


if __name__ == "__main__":
    success = main()
    sys.exit(0 if success else 1) 