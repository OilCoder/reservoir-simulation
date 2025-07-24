#!/bin/bash
# ML pattern validation hook for src/ directory
# Validates machine learning best practices and prevents common pitfalls

FILE_PATH="$1"
CONTENT="$2"

# Exit codes:
# 0 - Success (continue)
# 2 - Blocking error (stop operation)

# Only validate Python files
if [[ ! "$FILE_PATH" =~ \.py$ ]]; then
    exit 0
fi

# Check for data leakage patterns
check_data_leakage() {
    # Look for dangerous patterns that could cause data leakage
    if echo "$CONTENT" | grep -E "(test.*train|future.*target|target.*feature)" > /dev/null; then
        echo "⚠️  WARNING: Potential data leakage pattern detected"
        echo "   Review use of test/train data and target variables"
    fi
    
    # Check for fit_transform on test data
    if echo "$CONTENT" | grep -E "test.*fit_transform|X_test.*fit_transform" > /dev/null; then
        echo "🚫 ERROR: fit_transform() should not be used on test data"
        echo "   Use transform() instead of fit_transform() for test sets"
        exit 2
    fi
}

# Check for proper train/validation splits
check_validation_patterns() {
    # Look for train_test_split usage
    if echo "$CONTENT" | grep "train_test_split" > /dev/null; then
        if ! echo "$CONTENT" | grep "random_state=" > /dev/null; then
            echo "⚠️  WARNING: train_test_split missing random_state parameter"
            echo "   Add random_state for reproducible results"
        fi
    fi
    
    # Check for cross-validation
    if echo "$CONTENT" | grep -E "(cross_val_score|KFold|StratifiedKFold)" > /dev/null; then
        if ! echo "$CONTENT" | grep "random_state=" > /dev/null; then
            echo "⚠️  WARNING: Cross-validation missing random_state parameter"
        fi
    fi
}

# Check for proper model evaluation
check_model_evaluation() {
    # Look for model fitting without evaluation
    if echo "$CONTENT" | grep "\.fit(" > /dev/null; then
        if ! echo "$CONTENT" | grep -E "(score|predict|evaluate)" > /dev/null; then
            echo "⚠️  WARNING: Model fitting detected without evaluation"
            echo "   Consider adding model evaluation (score, predict, etc.)"
        fi
    fi
}

# Check for proper imports organization
check_ml_imports() {
    # Check for sklearn imports
    if echo "$CONTENT" | grep "from sklearn" > /dev/null; then
        # Verify proper sklearn module usage
        if echo "$CONTENT" | grep -E "from sklearn import \*" > /dev/null; then
            echo "🚫 ERROR: Wildcard imports from sklearn are not allowed"
            echo "   Use specific imports: from sklearn.model_selection import train_test_split"
            exit 2
        fi
    fi
    
    # Check for pandas imports
    if echo "$CONTENT" | grep "import pandas" > /dev/null; then
        if ! echo "$CONTENT" | grep "import pandas as pd" > /dev/null; then
            echo "⚠️  WARNING: Use standard pandas alias 'pd'"
            echo "   import pandas as pd"
        fi
    fi
    
    # Check for numpy imports
    if echo "$CONTENT" | grep "import numpy" > /dev/null; then
        if ! echo "$CONTENT" | grep "import numpy as np" > /dev/null; then
            echo "⚠️  WARNING: Use standard numpy alias 'np'"
            echo "   import numpy as np"
        fi
    fi
}

# Run all checks
check_data_leakage
check_validation_patterns
check_model_evaluation
check_ml_imports

echo "✅ ML pattern validation completed for $FILE_PATH"
exit 0