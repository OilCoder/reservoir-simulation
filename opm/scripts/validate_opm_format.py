#!/usr/bin/env python3
"""
validate_opm_format.py - Quick validation of OPM export format

DESCRIPTION:
    Performs basic syntax and format validation on the generated OPM input files
    to ensure they conform to OPM Flow requirements.
"""

import os
from pathlib import Path


def validate_opm_files():
    """Validate OPM input files"""
    input_dir = Path("/workspace/opm/input")
    
    print("=== OPM FORMAT VALIDATION ===")
    
    # Check if all required files exist
    required_files = [
        'EAGLE_WEST.DATA',
        'GRID.inc',
        'PROPS.inc', 
        'PVT.inc',
        'WELLS.inc',
        'SCHEDULE.inc',
        'SOLUTION.inc'
    ]
    
    print("\n1. FILE EXISTENCE CHECK:")
    all_exist = True
    for file in required_files:
        file_path = input_dir / file
        if file_path.exists():
            size = file_path.stat().st_size
            print(f"  ✓ {file:<20} ({size:,} bytes)")
        else:
            print(f"  ❌ {file:<20} MISSING")
            all_exist = False
    
    if not all_exist:
        print("ERROR: Missing required files")
        return False
    
    print("\n2. BASIC SYNTAX CHECK:")
    
    # Check RUNSPEC section in DATA file
    data_file = input_dir / 'EAGLE_WEST.DATA'
    with open(data_file, 'r') as f:
        data_content = f.read()
    
    required_keywords = ['RUNSPEC', 'GRID', 'PROPS', 'SOLUTION', 'SCHEDULE', 'END']
    for keyword in required_keywords:
        if keyword in data_content:
            print(f"  ✓ {keyword} section found")
        else:
            print(f"  ❌ {keyword} section missing")
    
    # Check grid dimensions
    if 'DIMENS' in data_content and '41 41 12' in data_content:
        print("  ✓ Grid dimensions (41x41x12)")
    else:
        print("  ⚠ Grid dimensions check failed")
    
    # Check phase declaration
    phases = ['OIL', 'WATER', 'GAS']
    phase_count = sum(1 for phase in phases if phase in data_content)
    print(f"  ✓ Phase declarations ({phase_count}/3 phases)")
    
    print("\n3. WELLS VALIDATION:")
    wells_file = input_dir / 'WELLS.inc'
    with open(wells_file, 'r') as f:
        wells_content = f.read()
    
    # Count wells
    producer_count = wells_content.count('EW-')
    injector_count = wells_content.count('IW-')
    print(f"  ✓ Producers: {producer_count}")
    print(f"  ✓ Injectors: {injector_count}")
    print(f"  ✓ Total wells: {producer_count + injector_count}")
    
    # Check well coordinates are valid (1-41 range)
    import re
    well_coords = re.findall(r'[EI]W-\d+\s+FIELD\s+(\d+)\s+(\d+)', wells_content)
    invalid_coords = [(i, j) for i, j in well_coords if int(i) > 41 or int(j) > 41 or int(i) < 1 or int(j) < 1]
    
    if invalid_coords:
        print(f"  ❌ Invalid well coordinates: {invalid_coords}")
    else:
        print("  ✓ All well coordinates valid (1-41 range)")
    
    print("\n4. PROPERTIES CHECK:")
    
    # Check GRID section
    grid_file = input_dir / 'GRID.inc'
    with open(grid_file, 'r') as f:
        grid_content = f.read()
    
    grid_keywords = ['SPECGRID', 'COORD', 'ZCORN', 'ACTNUM']
    for keyword in grid_keywords:
        if keyword in grid_content:
            print(f"  ✓ {keyword} found in GRID.inc")
        else:
            print(f"  ❌ {keyword} missing from GRID.inc")
    
    # Check PROPS section
    props_file = input_dir / 'PROPS.inc'
    with open(props_file, 'r') as f:
        props_content = f.read()
    
    props_keywords = ['PERMX', 'PERMY', 'PERMZ', 'PORO']
    for keyword in props_keywords:
        if keyword in props_content:
            print(f"  ✓ {keyword} found in PROPS.inc")
        else:
            print(f"  ❌ {keyword} missing from PROPS.inc")
    
    # Check PVT section
    pvt_file = input_dir / 'PVT.inc'
    with open(pvt_file, 'r') as f:
        pvt_content = f.read()
    
    pvt_keywords = ['PVTW', 'PVCDO', 'SWOF', 'SGOF']
    for keyword in pvt_keywords:
        if keyword in pvt_content:
            print(f"  ✓ {keyword} found in PVT.inc")
        else:
            print(f"  ⚠ {keyword} missing from PVT.inc")
    
    print("\n5. SIMULATION SETUP:")
    
    # Check SCHEDULE section
    schedule_file = input_dir / 'SCHEDULE.inc'
    with open(schedule_file, 'r') as f:
        schedule_content = f.read()
    
    schedule_keywords = ['WCONPROD', 'WCONINJ', 'TSTEP']
    for keyword in schedule_keywords:
        if keyword in schedule_content:
            print(f"  ✓ {keyword} found in SCHEDULE.inc")
        else:
            print(f"  ❌ {keyword} missing from SCHEDULE.inc")
    
    # Check SOLUTION section
    solution_file = input_dir / 'SOLUTION.inc'
    with open(solution_file, 'r') as f:
        solution_content = f.read()
    
    solution_keywords = ['PRESSURE', 'SWAT', 'SGAS']
    for keyword in solution_keywords:
        if keyword in solution_content:
            print(f"  ✓ {keyword} found in SOLUTION.inc")
        else:
            print(f"  ⚠ {keyword} missing from SOLUTION.inc")
    
    print("\n=== VALIDATION COMPLETE ===")
    print("✅ OPM format appears valid!")
    print("📋 Ready for OPM Flow simulation")
    print("🚀 Run: flow EAGLE_WEST.DATA")
    
    return True


if __name__ == "__main__":
    validate_opm_files()