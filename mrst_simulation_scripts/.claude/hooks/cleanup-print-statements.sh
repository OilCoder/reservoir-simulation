#!/bin/bash
# Cleanup hook for MRST simulation scripts
# Allows fprintf for simulation progress but warns about excessive output

FILE_PATH="$1"

# Exit codes:
# 0 - Success (continue)
# 2 - Blocking error (stop operation)

# Only validate Octave/MATLAB files
if [[ ! "$FILE_PATH" =~ \.m$ ]]; then
    exit 0
fi

if [ ! -f "$FILE_PATH" ]; then
    exit 0
fi

# Check for output statements
check_output_statements() {
    # Count different types of output
    fprintf_count=$(grep -c "fprintf" "$FILE_PATH" 2>/dev/null || echo "0")
    disp_count=$(grep -c "disp(" "$FILE_PATH" 2>/dev/null || echo "0")
    printf_count=$(grep -c "printf" "$FILE_PATH" 2>/dev/null || echo "0")
    
    total_output=$((fprintf_count + disp_count + printf_count))
    
    if [ "$total_output" -gt 0 ]; then
        echo "📊 Output statements found:"
        echo "   fprintf: $fprintf_count"
        echo "   disp: $disp_count" 
        echo "   printf: $printf_count"
        echo "   Total: $total_output"
        
        # Distinguish between progress reporting and debugging
        progress_patterns=$(grep -c -E "fprintf.*progress|fprintf.*%|fprintf.*step|fprintf.*time" "$FILE_PATH" 2>/dev/null || echo "0")
        debug_patterns=$(grep -c -E "fprintf.*debug|fprintf.*test|disp.*debug" "$FILE_PATH" 2>/dev/null || echo "0")
        
        if [ "$progress_patterns" -gt 0 ]; then
            echo "✅ Progress reporting detected ($progress_patterns statements)"
        fi
        
        if [ "$debug_patterns" -gt 0 ]; then
            echo "⚠️  WARNING: Debug output detected ($debug_patterns statements)"
            echo "   Consider removing or commenting out debug statements"
        fi
        
        # Check for excessive output
        if [ "$total_output" -gt 15 ]; then
            echo "⚠️  WARNING: High number of output statements ($total_output)"
            echo "   Consider reducing output or using verbose flags"
        fi
        
        # Check for proper progress formatting
        if grep -q "fprintf.*\\n" "$FILE_PATH" 2>/dev/null; then
            echo "✅ Proper line endings in fprintf statements"
        elif [ "$fprintf_count" -gt 0 ]; then
            echo "⚠️  WARNING: Consider adding \\n to fprintf statements"
            echo "   Example: fprintf('Progress: %d%%\\n', progress);"
        fi
    else
        echo "ℹ️  No output statements found"
        
        # Check if script might benefit from progress reporting
        if grep -E "for.*=|while" "$FILE_PATH" > /dev/null; then
            echo "ℹ️  Script has loops - consider adding progress reporting"
            echo "   Example: fprintf('Processing step %d of %d\\n', i, total);"
        fi
    fi
}

# Check for MRST-specific output patterns
check_mrst_output() {
    # Check for MRST plotting commands
    plot_commands=$(grep -c -E "figure|plot|plotGrid|plotCellData|plotWell" "$FILE_PATH" 2>/dev/null || echo "0")
    
    if [ "$plot_commands" -gt 0 ]; then
        echo "📈 MRST plotting commands found: $plot_commands"
        
        # Check for plot saving
        if grep -E "saveas|print|exportgraphics" "$FILE_PATH" > /dev/null; then
            echo "✅ Plot saving detected"
        else
            echo "ℹ️  Consider saving plots for reproducibility"
            echo "   Example: saveas(gcf, 'output/plot_name.png');"
        fi
        
        # Check for excessive figure creation
        if [ "$plot_commands" -gt 10 ]; then
            echo "⚠️  WARNING: Many plotting commands ($plot_commands)"
            echo "   Consider consolidating plots or using subplots"
        fi
    fi
    
    # Check for verbose MRST settings
    if grep -E "mrstVerbose|verbose.*true" "$FILE_PATH" > /dev/null; then
        echo "✅ MRST verbose mode detected"
    fi
}

# Check for simulation output organization
check_simulation_output() {
    # Check for data saving
    save_commands=$(grep -c -E "save|writematrix|writetable" "$FILE_PATH" 2>/dev/null || echo "0")
    
    if [ "$save_commands" -gt 0 ]; then
        echo "💾 Data saving commands found: $save_commands"
        
        # Check for organized output directories
        if grep -E "'data/|'output/|'results/" "$FILE_PATH" > /dev/null; then
            echo "✅ Organized output directories detected"
        else
            echo "ℹ️  Consider organizing output in directories"
            echo "   Example: save('data/simulation_results.mat', 'results');"
        fi
    fi
    
    # Check for variable workspace cleanup
    if grep -E "clear(?!.*all)|clearvars" "$FILE_PATH" > /dev/null; then
        echo "✅ Selective variable cleanup found"
    elif grep "clear all" "$FILE_PATH" > /dev/null; then
        echo "⚠️  WARNING: 'clear all' clears everything including functions"
        echo "   Consider 'clearvars' for selective cleanup"
    fi
}

# Check for time measurement
check_timing() {
    # Check for timing commands
    if grep -E "tic|toc|cputime|elapsed" "$FILE_PATH" > /dev/null; then
        echo "⏱️  Timing measurements detected"
        
        # Check for balanced tic/toc
        tic_count=$(grep -c "tic" "$FILE_PATH" 2>/dev/null || echo "0")
        toc_count=$(grep -c "toc" "$FILE_PATH" 2>/dev/null || echo "0")
        
        if [ "$tic_count" -ne "$toc_count" ]; then
            echo "⚠️  WARNING: Unbalanced tic/toc pairs ($tic_count tic, $toc_count toc)"
        else
            echo "✅ Balanced tic/toc timing"
        fi
    fi
}

# Check for temporary variable cleanup
check_temp_variables() {
    # Look for temporary variables that could be cleaned up
    temp_vars=$(grep -o -E "(tmp|temp|temporary)_[a-zA-Z0-9_]*" "$FILE_PATH" | sort -u)
    
    if [ -n "$temp_vars" ]; then
        echo "🧹 Temporary variables detected:"
        echo "$temp_vars" | while read -r var; do
            echo "   - $var"
        done
        
        # Check if they're cleaned up
        if grep -E "clear.*tmp|clear.*temp" "$FILE_PATH" > /dev/null; then
            echo "✅ Temporary variable cleanup found"
        else
            echo "ℹ️  Consider cleaning up temporary variables"
            echo "   Example: clear tmp_* temp_*;"
        fi
    fi
}

# Run all checks
echo "🧹 Checking output and cleanup for $FILE_PATH"

check_output_statements
check_mrst_output
check_simulation_output
check_timing
check_temp_variables

echo "✅ Output and cleanup check completed for $FILE_PATH"
exit 0