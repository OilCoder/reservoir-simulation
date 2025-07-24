#!/bin/bash
# Python import validation hook for src/ directory
# Validates import organization and best practices

FILE_PATH="$1"
CONTENT="$2"

# Exit codes:
# 0 - Success (continue)
# 2 - Blocking error (stop operation)

# Only validate Python files
if [[ ! "$FILE_PATH" =~ \.py$ ]]; then
    exit 0
fi

# Check import organization
check_import_order() {
    # Extract import lines
    imports=$(echo "$CONTENT" | grep -E "^(import |from )" | head -20)
    
    if [ -z "$imports" ]; then
        exit 0
    fi
    
    # Check for proper grouping (stdlib, external, internal)
    stdlib_found=false
    external_found=false
    internal_found=false
    
    echo "$imports" | while read -r line; do
        if [[ "$line" =~ ^(import|from)\ (os|sys|typing|pathlib|json|csv|re|datetime|collections|itertools|functools|logging) ]]; then
            stdlib_found=true
        elif [[ "$line" =~ ^(import|from)\ (numpy|pandas|sklearn|matplotlib|seaborn|plotly|streamlit|pytest) ]]; then
            external_found=true
        elif [[ "$line" =~ ^(from|import)\ (src\.|\.\.|\.) ]]; then
            internal_found=true
        fi
    done
}

# Check for common import issues
check_import_issues() {
    # Check for wildcard imports
    if echo "$CONTENT" | grep -E "from .* import \*" > /dev/null; then
        echo "🚫 ERROR: Wildcard imports are not allowed"
        echo "   Use specific imports instead of 'from module import *'"
        exit 2
    fi
    
    # Check for unused imports (basic check)
    imports=$(echo "$CONTENT" | grep -E "^import |^from .* import" | sed 's/^import //; s/^from .* import //; s/,.*//; s/ as .*//')
    
    for import_name in $imports; do
        if [ "$import_name" != "os" ] && [ "$import_name" != "sys" ]; then
            if ! echo "$CONTENT" | grep -v "^import\|^from" | grep -q "$import_name"; then
                echo "⚠️  WARNING: Potentially unused import: $import_name"
            fi
        fi
    done
    
    # Check for relative imports in non-package files
    if echo "$CONTENT" | grep -E "^from \." > /dev/null; then
        if [[ ! "$FILE_PATH" =~ __init__\.py$ ]]; then
            echo "⚠️  WARNING: Relative imports detected"
            echo "   Consider using absolute imports for better clarity"
        fi
    fi
}

# Check for ML-specific import patterns
check_ml_import_patterns() {
    # sklearn imports should be specific
    if echo "$CONTENT" | grep "from sklearn" > /dev/null; then
        sklearn_imports=$(echo "$CONTENT" | grep "from sklearn")
        echo "$sklearn_imports" | while read -r line; do
            if [[ "$line" =~ "from sklearn import" ]] && [[ ! "$line" =~ "from sklearn import __version__" ]]; then
                echo "⚠️  WARNING: Prefer specific sklearn module imports"
                echo "   Example: from sklearn.model_selection import train_test_split"
            fi
        done
    fi
    
    # Check for proper pandas/numpy aliases
    if echo "$CONTENT" | grep -E "^import pandas$" > /dev/null; then
        echo "⚠️  WARNING: Use standard pandas alias"
        echo "   import pandas as pd"
    fi
    
    if echo "$CONTENT" | grep -E "^import numpy$" > /dev/null; then
        echo "⚠️  WARNING: Use standard numpy alias"
        echo "   import numpy as np"
    fi
}

# Run all checks
check_import_order
check_import_issues
check_ml_import_patterns

echo "✅ Python import validation completed for $FILE_PATH"
exit 0