#!/bin/bash
# run_mrst.sh - Fixed MRST initialization for headless container environment
#
# USAGE:
#   ./run_mrst.sh [script_name]
#   ./run_mrst.sh "s01_initialize_mrst.m"
#   ./run_mrst.sh "s99_run_workflow.m"
#
# This script fixes the MRST initialization issues by:
# 1. Pre-adding required MRST core paths
# 2. Using --no-init-file to prevent auto-startup conflicts
# 3. Properly initializing MRST before running user scripts

SCRIPT_PATH=${1:-"s01_initialize_mrst.m"}

echo "=== MRST Container Initialization ==="
echo "Target script: $SCRIPT_PATH"
echo "X11 display warnings are expected (headless container)"
echo ""

octave --no-gui --no-init-file --eval "
    % Pre-add MRST core paths to resolve circular dependency
    addpath('/opt/mrst/core/utils');
    addpath('/opt/mrst/core/gridprocessing'); 
    addpath('/opt/mrst/core');
    
    % Initialize MRST from its directory
    cd('/opt/mrst');
    startup();
    
    % Return to correct workspace directory with scripts
    cd('/workspace/mrst_simulation_scripts');
    fprintf('\\nCurrent directory: %s\\n', pwd);
    fprintf('Script exists: %s\\n', mat2str(exist('$SCRIPT_PATH', 'file') == 2));
    fprintf('\\n=== Running %s ===\\n', '$SCRIPT_PATH');
    run('$SCRIPT_PATH');
"