#!/bin/bash

cd /workspaces/claudeclean/mrst_simulation_scripts

echo "Removing old numbered files..."

# Remove the old files that have been renamed
rm -f s05_create_pebi_grid.m
rm -f s03_structural_framework.m  
rm -f s04_add_faults.m

echo "Old files removed successfully!"
echo "Current workflow files:"
ls -la s0[1-8]*.m | sort