#!/bin/bash
# Octave/MRST code style validation hook
# Validates MATLAB/Octave syntax and MRST-specific patterns

FILE_PATH="$1"
CONTENT="$2"

# Exit codes:
# 0 - Success (continue)
# 2 - Blocking error (stop operation)

# Only validate Octave/MATLAB files
if [[ ! "$FILE_PATH" =~ \.m$ ]]; then
    exit 0
fi

# Check file naming convention
check_file_naming() {
    filename=$(basename "$FILE_PATH")
    
    # Check for workflow script naming (sNN_verb_noun.m)
    if [[ ! "$filename" =~ ^(s[0-9]{2}[a-z]?_[a-z]+_[a-z_]+\.m|util_[a-z_]+\.m)$ ]]; then
        echo "🚫 ERROR: File doesn't follow naming convention"
        echo "   Expected: sNN[x]_verb_noun.m or util_name.m"
        echo "   Example: s01_setup_field.m, util_read_config.m"
        exit 2
    fi
    
    echo "✅ File naming follows convention"
}

# Check for proper MRST requirements
check_mrst_requirements() {
    # Check for MRST requirement comment
    if echo "$CONTENT" | grep -q "% Requires: MRST"; then
        echo "✅ MRST requirement documented"
    else
        echo "⚠️  WARNING: Add MRST requirement comment"
        echo "   Add: % Requires: MRST"
    fi
    
    # Check for MRST module loading
    if echo "$CONTENT" | grep -E "mrstModule add|mrstModule('add')" > /dev/null; then
        modules=$(echo "$CONTENT" | grep -E "mrstModule add|mrstModule('add')" | sed 's/.*add \(.*\);.*/\1/')
        echo "✅ MRST modules loaded: $modules"
    else
        echo "⚠️  WARNING: No MRST modules loaded"
        echo "   Add: mrstModule add module1 module2;"
    fi
    
    # Check for MRST availability check
    if echo "$CONTENT" | grep -E "exist.*mrstModule|mrstVerbose|checkForMRST" > /dev/null; then
        echo "✅ MRST availability check found"
    else
        echo "⚠️  WARNING: Consider checking MRST availability"
        echo "   Add: if ~exist('mrstModule', 'file'), error('MRST not found'); end"
    fi
}

# Check Octave/MATLAB syntax patterns
check_syntax_patterns() {
    # Check for proper variable naming (snake_case)
    camelCase_vars=$(echo "$CONTENT" | grep -o "[a-z][a-zA-Z]*[A-Z][a-zA-Z]*" | head -5)
    if [ -n "$camelCase_vars" ]; then
        echo "⚠️  WARNING: Consider using snake_case for variables"
        echo "   Found camelCase: $camelCase_vars"
        echo "   Use: variable_name instead of variableName"
    fi
    
    # Check for semicolon usage (suppress output)
    missing_semicolons=$(echo "$CONTENT" | grep -c "^[[:space:]]*[a-zA-Z_][a-zA-Z0-9_]*[[:space:]]*=" | head -5)
    total_assignments=$(echo "$CONTENT" | grep -c "=" | head -5)
    
    if [ "$missing_semicolons" -gt 0 ]; then
        echo "ℹ️  Consider adding semicolons to suppress output"
        echo "   Example: variable = value; % Suppresses output"
    fi
    
    # Check for clear/close statements
    if echo "$CONTENT" | grep -E "clear all|close all" > /dev/null; then
        echo "✅ Found workspace cleanup commands"
    else
        echo "ℹ️  Consider adding workspace cleanup at start"
        echo "   clear all; close all; clc;"
    fi
    
    # Check for proper function definitions
    functions=$(echo "$CONTENT" | grep -n "^function")
    if [ -n "$functions" ]; then
        echo "✅ Found function definitions"
        
        # Check function documentation
        echo "$functions" | while read -r line; do
            line_num=$(echo "$line" | cut -d: -f1)
            func_line=$(echo "$line" | cut -d: -f2-)
            
            # Check for function comments
            comment_found=false
            for i in {1..5}; do
                check_line=$((line_num - i))
                if [ "$check_line" -gt 0 ]; then
                    comment_line=$(sed -n "${check_line}p" <<< "$CONTENT")
                    if echo "$comment_line" | grep "^%" > /dev/null; then
                        comment_found=true
                        break
                    fi
                fi
            done
            
            if [ "$comment_found" = false ]; then
                func_name=$(echo "$func_line" | sed 's/function.*= \([^(]*\).*/\1/' | sed 's/function \([^(]*\).*/\1/')
                echo "⚠️  WARNING: Function '$func_name' missing documentation"
                echo "   Add PURPOSE, INPUTS, OUTPUTS comments above function"
            fi
        done
    fi
}

# Check for MRST-specific patterns
check_mrst_patterns() {
    # Check for grid operations
    if echo "$CONTENT" | grep -E "cartGrid|tensorGrid|Grid" > /dev/null; then
        echo "✅ Grid operations detected"
        
        # Check for geometry computation
        if echo "$CONTENT" | grep "computeGeometry" > /dev/null; then
            echo "✅ Grid geometry computation found"
        else
            echo "⚠️  WARNING: Grid created but geometry not computed"
            echo "   Add: G = computeGeometry(G);"
        fi
    fi
    
    # Check for fluid definitions
    if echo "$CONTENT" | grep -E "initSimpleFluid|initFluid|fluid" > /dev/null; then
        echo "✅ Fluid definitions detected"
    fi
    
    # Check for rock properties
    if echo "$CONTENT" | grep -E "makeRock|rock\.perm|rock\.poro" > /dev/null; then
        echo "✅ Rock properties defined"
    fi
    
    # Check for well operations
    if echo "$CONTENT" | grep -E "addWell|W.*=" > /dev/null; then
        echo "✅ Well operations detected"
    fi
    
    # Check for simulation components
    if echo "$CONTENT" | grep -E "initState|incompTPFA|explicitTransport" > /dev/null; then
        echo "✅ Simulation components found"
    fi
    
    # Check for physical units
    if echo "$CONTENT" | grep -E "\*milli\*darcy|\*centi\*poise|\*meter|\*day|\*psi" > /dev/null; then
        echo "✅ Physical units properly used"
    else
        echo "⚠️  WARNING: Consider using MRST physical units"
        echo "   Example: 100*milli*darcy, 1*centi*poise"
    fi
}

# Check for proper error handling
check_error_handling() {
    # Check for input validation
    if echo "$CONTENT" | grep -E "assert|error|nargin|nargout" > /dev/null; then
        echo "✅ Input validation found"
    else
        echo "⚠️  WARNING: Consider adding input validation"
        echo "   Use assert() or error() for parameter checking"
    fi
    
    # Check for try-catch blocks
    if echo "$CONTENT" | grep -E "try|catch" > /dev/null; then
        echo "✅ Error handling with try-catch"
    fi
    
    # Check for warning suppression
    if echo "$CONTENT" | grep "warning('off'" > /dev/null; then
        echo "⚠️  WARNING: Warning suppression detected"
        echo "   Consider addressing warnings instead of suppressing"
    fi
}

# Check for documentation standards
check_documentation() {
    # Check for file header
    if echo "$CONTENT" | head -10 | grep -E "^%.*Author|^%.*Date|^%.*Description" > /dev/null; then
        echo "✅ File header documentation found"
    else
        echo "⚠️  WARNING: Add file header with Author, Date, Description"
    fi
    
    # Check for usage examples
    if echo "$CONTENT" | grep -E "^%.*Usage|^%.*Example" > /dev/null; then
        echo "✅ Usage examples documented"
    else
        echo "ℹ️  Consider adding usage examples in comments"
    fi
    
    # Check for physical unit documentation
    if echo "$CONTENT" | grep -E "%.*\[.*\]|%.*units" > /dev/null; then
        echo "✅ Physical units documented"
    else
        echo "⚠️  WARNING: Document physical units in comments"
        echo "   Example: % pressure [psi], permeability [mD]"
    fi
}

# Check for performance considerations
check_performance() {
    # Check for vectorization
    if echo "$CONTENT" | grep -E "for.*=.*:" > /dev/null; then
        loop_count=$(echo "$CONTENT" | grep -c "for.*=.*:")
        echo "ℹ️  Found $loop_count for loops"
        
        # Look for potential vectorization opportunities
        if echo "$CONTENT" | grep -A 5 "for.*=.*:" | grep -E "\(.*i.*\)|\(.*j.*\)" > /dev/null; then
            echo "⚠️  WARNING: Consider vectorizing array operations"
            echo "   MATLAB/Octave is optimized for vectorized operations"
        fi
    fi
    
    # Check for memory pre-allocation
    if echo "$CONTENT" | grep -E "zeros\(|ones\(|nan\(" > /dev/null; then
        echo "✅ Memory pre-allocation detected"
    else
        if echo "$CONTENT" | grep -E "for.*=" > /dev/null; then
            echo "⚠️  WARNING: Consider pre-allocating arrays in loops"
            echo "   Use zeros(), ones(), or nan() for initialization"
        fi
    fi
}

# Run all checks
echo "🔍 Validating Octave/MRST code style for $FILE_PATH"

check_file_naming
check_mrst_requirements
check_syntax_patterns
check_mrst_patterns
check_error_handling
check_documentation
check_performance

echo "✅ Octave/MRST code style validation completed for $FILE_PATH"
exit 0