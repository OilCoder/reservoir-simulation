#!/bin/bash

cd /workspaces/claudeclean/mrst_simulation_scripts

# Remove files where the filename doesn't match the function name inside
echo "Removing files with mismatched function names..."

# s05_create_pebi_grid.m contains s03_create_pebi_grid function - remove it
echo "Removing s05_create_pebi_grid.m (contains s03 function)"
rm -f s05_create_pebi_grid.m

# s03_structural_framework.m contains s04_structural_framework function - remove it  
echo "Removing s03_structural_framework.m (contains s04 function)"
rm -f s03_structural_framework.m

# s04_add_faults.m contains s05_add_faults function - remove it
echo "Removing s04_add_faults.m (contains s05 function)"
rm -f s04_add_faults.m

echo "Cleanup complete! Remaining files:"
ls -la s0[1-8]*.m | sort