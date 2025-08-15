#!/bin/bash

# Quick test script for S11-S16 corrections
cd /workspaces/claudeclean/mrst_simulation_scripts

echo "=== TESTING S11-S16 CANON-FIRST CORRECTIONS ==="
echo

# Run Octave test
octave --no-gui --eval "test_s11_s16_corrections()"

echo "=== TEST COMPLETED ==="