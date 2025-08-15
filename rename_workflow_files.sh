#!/bin/bash

# Renumber MRST workflow files s03-s08 to match correct execution order
# Current execution order: s01→s02→s05→s03→s04→s06→s07→s08
# Target execution order:  s01→s02→s03→s04→s05→s06→s07→s08

cd /workspaces/claudeclean/mrst_simulation_scripts

echo "Starting file renumbering..."

# Step 1: Move files to temporary names to avoid conflicts
echo "Step 1: Creating temporary names..."
mv s05_create_pebi_grid.m temp_s03_create_pebi_grid.m
mv s03_structural_framework.m temp_s04_structural_framework.m  
mv s04_add_faults.m temp_s05_add_faults.m

# Step 2: Rename to final target names
echo "Step 2: Renaming to final names..."
mv temp_s03_create_pebi_grid.m s03_create_pebi_grid.m
mv temp_s04_structural_framework.m s04_structural_framework.m
mv temp_s05_add_faults.m s05_add_faults.m

echo "File renaming completed successfully!"
echo "New execution order: s01→s02→s03→s04→s05→s06→s07→s08"