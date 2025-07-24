#!/bin/bash
# Pre-write validation hook - runs all validation checks

# This script is called before Write/Edit operations
# It receives the file path and content as arguments

FILE_PATH="$1"
FILE_CONTENT="$2"
HOOKS_DIR="$(dirname "$0")"

echo "="*50
echo "PRE-WRITE VALIDATION"
echo "File: $(basename "$FILE_PATH")"
echo "="*50

# Run all validation checks
errors=0

# 1. File naming validation
echo -e "\n[1/4] File Naming Check"
if ! "$HOOKS_DIR/validate-file-naming.sh" "$FILE_PATH"; then
    ((errors++))
fi

# 2. Code style validation
echo -e "\n[2/4] Code Style Check"
if ! "$HOOKS_DIR/validate-code-style.sh" "$FILE_PATH" "$FILE_CONTENT"; then
    ((errors++))
fi

# 3. Docstring validation (Python only)
if [[ "$FILE_PATH" =~ \.py$ ]]; then
    echo -e "\n[3/4] Docstring Check"
    if ! "$HOOKS_DIR/validate-docstrings.sh" "$FILE_PATH"; then
        ((errors++))
    fi
else
    echo -e "\n[3/4] Docstring Check - Skipped (not Python)"
fi

# 4. Print statement check
echo -e "\n[4/4] Print Statement Check"
"$HOOKS_DIR/cleanup-print-statements.sh" "$FILE_PATH" "$FILE_CONTENT"

echo -e "\n$('='*50)"

# Final decision
if [ $errors -gt 0 ]; then
    echo "❌ VALIDATION FAILED: $errors critical error(s) found"
    echo "Please fix the errors above before proceeding"
    exit 2
else
    echo "✅ VALIDATION PASSED: File meets all requirements"
    exit 0
fi