#!/bin/bash

# Remove the mismatched files (wrong function names inside)
rm s05_create_pebi_grid.m  # Contains s03 function
rm s03_structural_framework.m  # Contains s04 function  
rm s04_add_faults.m  # Contains s05 function

echo "Removed mismatched files. Current workflow:"
ls -la s0[1-8]*.m | sort