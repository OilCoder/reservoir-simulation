#!/bin/bash
# Validate file naming conventions for the project

# Exit codes:
# 0 - Success (continue)
# 2 - Blocking error (stop operation)

# Get the file path from the tool parameters
FILE_PATH="$1"

# Function to check file naming convention
check_naming() {
    local file="$1"
    local dir=$(dirname "$file")
    local basename=$(basename "$file")
    
    # Skip validation for files outside project structure
    if [[ ! "$file" =~ ^/workspace/(src|mrst_simulation_scripts|tests|debug)/ ]]; then
        return 0
    fi
    
    # Check source files (Python and Octave)
    if [[ "$dir" =~ /workspace/(src|mrst_simulation_scripts) ]]; then
        if [[ "$basename" =~ \.(py|m)$ ]]; then
            # Must follow sNN[x]_verb_noun pattern
            if [[ ! "$basename" =~ ^s[0-9]{2}[a-z]?_[a-z]+_[a-z]+\.(py|m)$ ]]; then
                echo "❌ ERROR: File '$basename' does not follow naming convention"
                echo "Expected pattern: sNN[x]_<verb>_<noun>.<ext>"
                echo "Examples: s01_load_data.py, s02a_setup_field.m"
                return 2
            fi
        fi
    fi
    
    # Check test files
    if [[ "$dir" =~ /workspace/tests ]]; then
        if [[ "$basename" =~ \.(py|m)$ ]]; then
            # Must follow test_NN_folder_module pattern
            if [[ ! "$basename" =~ ^test_[0-9]{2}_[a-z]+_[a-z]+(\.[a-z]+)*\.(py|m)$ ]]; then
                echo "❌ ERROR: Test file '$basename' does not follow naming convention"
                echo "Expected pattern: test_NN_<folder>_<module>[_<purpose>].<ext>"
                echo "Example: test_01_src_data_loader.py"
                return 2
            fi
        fi
    fi
    
    # Check debug files
    if [[ "$dir" =~ /workspace/debug ]]; then
        if [[ "$basename" =~ \.(py|m)$ ]]; then
            # Must follow dbg_slug pattern
            if [[ ! "$basename" =~ ^dbg_[a-z_]+\.(py|m)$ ]]; then
                echo "❌ ERROR: Debug file '$basename' does not follow naming convention"
                echo "Expected pattern: dbg_<slug>[_<experiment>].<ext>"
                echo "Example: dbg_pressure_analysis.m"
                return 2
            fi
        fi
    fi
    
    # Check documentation files
    if [[ "$dir" =~ /workspace/docs/(English|Spanish) ]]; then
        if [[ "$basename" =~ \.md$ ]]; then
            # Must follow NN_slug pattern
            if [[ ! "$basename" =~ ^[0-9]{2}_[a-zA-Z0-9_]+\.md$ ]]; then
                echo "❌ ERROR: Doc file '$basename' does not follow naming convention"
                echo "Expected pattern: NN_<slug>.md"
                echo "Example: 01_introduction.md"
                return 2
            fi
        fi
    fi
    
    echo "✅ File naming validation passed for: $basename"
    return 0
}

# Main validation
if [ -n "$FILE_PATH" ]; then
    check_naming "$FILE_PATH"
    exit $?
fi

exit 0