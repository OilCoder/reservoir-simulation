#!/bin/bash
# Clean up print/log statements before commit

# Exit codes:
# 0 - Success (cleaned or no cleanup needed)
# 1 - Non-blocking error (warning only)

FILE_PATH="$1"
FILE_CONTENT="$2"

# Skip if not a source file
if [[ ! "$FILE_PATH" =~ \.(py|m)$ ]]; then
    exit 0
fi

# Skip if in debug folder (prints allowed there)
if [[ "$FILE_PATH" =~ /debug/ ]]; then
    exit 0
fi

# Function to check for print statements
check_prints() {
    local file="$1"
    local found_prints=0
    
    if [[ "$file" =~ \.py$ ]]; then
        # Python print statements
        if grep -E "^[[:space:]]*print\(" "$file" >/dev/null; then
            found_prints=1
            echo "⚠️  WARNING: Found print() statements in $file"
        fi
    elif [[ "$file" =~ \.m$ ]]; then
        # Octave/MATLAB display statements
        if grep -E "^[[:space:]]*(disp|fprintf)\(" "$file" | grep -v "% Requires:" >/dev/null; then
            # Allow fprintf for MRST progress indicators
            if ! grep -E "fprintf.*progress|fprintf.*simulation" "$file" >/dev/null; then
                found_prints=1
                echo "⚠️  WARNING: Found disp() or fprintf() statements in $file"
            fi
        fi
    fi
    
    return $found_prints
}

# Function to check for debug logging
check_debug_logging() {
    local file="$1"
    
    if [[ "$file" =~ \.py$ ]]; then
        # Check for debug-level logging
        if grep -E "logging\.debug|logger\.debug" "$file" >/dev/null; then
            echo "⚠️  WARNING: Found debug-level logging in $file"
            echo "Consider using info/warning/error levels for production"
        fi
    fi
    
    return 0
}

# Main check
echo "🔍 Checking for print/log statements in: $(basename "$FILE_PATH")"

if [ -f "$FILE_PATH" ]; then
    check_prints "$FILE_PATH"
    check_debug_logging "$FILE_PATH"
fi

echo "💡 TIP: Use logging module for production output, remove print() statements"
echo "✅ Print statement check completed (non-blocking)"

# Always exit 0 (non-blocking warning)
exit 0