#!/usr/bin/env python3
"""
ResInsight Data Preparation
Enhanced version of prepare_for_resinsight.py
"""

import os
import shutil
from pathlib import Path

def prepare_resinsight_data():
    """Prepare OPM results for ResInsight analysis"""
    opm_dir = Path(__file__).parent.parent
    
    # Source directories
    results_dir = opm_dir / 'results'
    resinsight_data_dir = opm_dir / 'resinsight_data'
    
    # Ensure resinsight_data exists
    resinsight_data_dir.mkdir(exist_ok=True)
    
    print("Preparing data for ResInsight...")
    
    # Copy OPM results to ResInsight directory
    for file_pattern in ['*.UNRST', '*.RSM', '*.EGRID', '*.INIT']:
        for file_path in results_dir.glob(file_pattern):
            dest_path = resinsight_data_dir / file_path.name
            shutil.copy2(file_path, dest_path)
            print(f"  Copied: {file_path.name}")
    
    # Ensure input files are also available
    input_files = ['EAGLE_WEST.DATA', 'GRID.inc', 'PROPS.inc', 'PVT.inc', 'WELLS.inc', 'SCHEDULE.inc']
    for filename in input_files:
        if not (resinsight_data_dir / filename).exists():
            print(f"  Warning: {filename} not found in resinsight_data")
    
    print(f"✓ ResInsight data prepared in: {resinsight_data_dir}")
    print("  Ready for ResInsight analysis from Windows")

if __name__ == "__main__":
    prepare_resinsight_data()