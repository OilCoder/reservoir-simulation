#!/bin/bash
# Validate docstring compliance for Python files

# Exit codes:
# 0 - Success
# 1 - Non-blocking warning
# 2 - Blocking error

FILE_PATH="$1"

# Only check Python files
if [[ ! "$FILE_PATH" =~ \.py$ ]]; then
    exit 0
fi

# Skip test and debug files
if [[ "$FILE_PATH" =~ /(tests|debug)/ ]]; then
    exit 0
fi

echo "🔍 Checking docstrings in: $(basename "$FILE_PATH")"

# Function to check module docstring
check_module_docstring() {
    local file="$1"
    
    # Check if file starts with docstring (after optional shebang and encoding)
    local first_lines=$(head -n 10 "$file" | grep -v "^#!" | grep -v "^# -\*-" | grep -v "^$")
    
    if ! echo "$first_lines" | head -n 1 | grep -E '^"""' >/dev/null; then
        echo "❌ ERROR: Missing module docstring"
        echo "Every Python file must start with a docstring describing its purpose"
        return 2
    fi
    
    return 0
}

# Function to check function docstrings
check_function_docstrings() {
    local file="$1"
    local errors=0
    
    # Find all function definitions
    while IFS= read -r line; do
        if [[ "$line" =~ ^[[:space:]]*def[[:space:]]+([a-zA-Z_][a-zA-Z0-9_]*) ]]; then
            local func_name="${BASH_REMATCH[1]}"
            local line_num=$(grep -n "def $func_name" "$file" | head -1 | cut -d: -f1)
            
            # Skip private functions starting with _
            if [[ "$func_name" =~ ^_ ]]; then
                continue
            fi
            
            # Check if next non-empty line after def is a docstring
            local next_lines=$(tail -n +$((line_num + 1)) "$file" | head -n 5)
            if ! echo "$next_lines" | grep -E '^[[:space:]]*"""' >/dev/null; then
                echo "❌ ERROR: Missing docstring for function '$func_name'"
                ((errors++))
            fi
        fi
    done < "$file"
    
    return $errors
}

# Function to check Google Style format
check_google_style() {
    local file="$1"
    
    # Look for docstrings and check format
    if grep -A 10 '"""' "$file" | grep -E "Args:|Returns:|Raises:" >/dev/null; then
        # Found Google style markers, do basic validation
        
        # Check for proper indentation
        if grep -A 10 '"""' "$file" | grep -E "^ {0,3}Args:" >/dev/null; then
            echo "⚠️  WARNING: 'Args:' section might have incorrect indentation"
            echo "Google Style requires 4-space indentation for docstring sections"
        fi
    fi
    
    return 0
}

# Main validation
errors=0

# Check module docstring
if ! check_module_docstring "$FILE_PATH"; then
    ((errors++))
fi

# Check function docstrings
func_errors=$(check_function_docstrings "$FILE_PATH")
errors=$((errors + func_errors))

# Check Google Style format
check_google_style "$FILE_PATH"

# Final result
if [ $errors -gt 0 ]; then
    echo "❌ Docstring validation failed with $errors error(s)"
    echo "Refer to rule 06-doc-enforcement.md for requirements"
    exit 2
else
    echo "✅ Docstring validation passed"
    exit 0
fi