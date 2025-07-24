#!/bin/bash
# Validate code style according to project rules

# Exit codes:
# 0 - Success (continue)
# 2 - Blocking error (stop operation)

# Get file path and content from environment or arguments
FILE_PATH="$1"
FILE_CONTENT="$2"

# Function to check for non-English comments
check_english_only() {
    local content="$1"
    
    # Common Spanish words/patterns to detect
    local spanish_patterns=(
        "función" "parámetro" "ejemplo" "paso" "código"
        "configuración" "archivo" "datos" "resultado"
        "ejecutar" "cargar" "guardar" "proceso"
        "# TODO:" "# FIXME:" "# NOTA:" "# IMPORTANTE:"
    )
    
    for pattern in "${spanish_patterns[@]}"; do
        if echo "$content" | grep -qi "$pattern"; then
            echo "❌ ERROR: Non-English comment detected (found: '$pattern')"
            echo "All comments and documentation must be in English"
            return 2
        fi
    done
    
    return 0
}

# Function to check function length (Python)
check_function_length() {
    local file="$1"
    
    if [[ ! "$file" =~ \.py$ ]]; then
        return 0
    fi
    
    # Simple check for function length
    # Count lines between 'def' and next 'def' or class
    local in_function=0
    local line_count=0
    local function_name=""
    
    while IFS= read -r line; do
        if [[ "$line" =~ ^[[:space:]]*def[[:space:]]+([a-zA-Z_][a-zA-Z0-9_]*) ]]; then
            if [ $in_function -eq 1 ] && [ $line_count -gt 40 ]; then
                echo "❌ ERROR: Function '$function_name' exceeds 40 lines (found: $line_count)"
                return 2
            fi
            function_name="${BASH_REMATCH[1]}"
            in_function=1
            line_count=0
        elif [ $in_function -eq 1 ]; then
            if [[ "$line" =~ ^[[:space:]]*class[[:space:]]+ ]] || [[ "$line" =~ ^[[:space:]]*def[[:space:]]+ ]]; then
                in_function=0
            else
                ((line_count++))
            fi
        fi
    done < "$file"
    
    # Check last function
    if [ $in_function -eq 1 ] && [ $line_count -gt 40 ]; then
        echo "❌ ERROR: Function '$function_name' exceeds 40 lines (found: $line_count)"
        return 2
    fi
    
    return 0
}

# Function to check try/except usage
check_try_except() {
    local content="$1"
    local file="$2"
    
    if [[ ! "$file" =~ \.py$ ]]; then
        return 0
    fi
    
    # Check for broad except clauses
    if echo "$content" | grep -E "except[[:space:]]*:" >/dev/null; then
        echo "❌ ERROR: Broad 'except:' clause detected"
        echo "Use specific exception types (e.g., 'except ValueError:')"
        return 2
    fi
    
    # Check for except without re-raise or logging
    if echo "$content" | grep -A 2 "except.*:" | grep -E "^[[:space:]]*pass[[:space:]]*$" >/dev/null; then
        echo "❌ ERROR: Exception silenced with 'pass'"
        echo "Exceptions must be re-raised or logged with context"
        return 2
    fi
    
    return 0
}

# Function to check snake_case naming
check_snake_case() {
    local content="$1"
    local file="$2"
    
    # Only check Python and Octave files
    if [[ ! "$file" =~ \.(py|m)$ ]]; then
        return 0
    fi
    
    # Check for camelCase function/variable names (simplified check)
    if [[ "$file" =~ \.py$ ]]; then
        # Look for def functionName or variable assignments
        if echo "$content" | grep -E "(def|^[[:space:]]*)[a-z]+[A-Z][a-zA-Z]*[[:space:]]*[=(]" >/dev/null; then
            echo "⚠️  WARNING: Possible camelCase naming detected"
            echo "Use snake_case for all function and variable names"
            # Don't block, just warn
        fi
    fi
    
    return 0
}

# Function to check for step/substep structure
check_step_structure() {
    local content="$1"
    local file="$2"
    
    # Only enforce for main source files
    if [[ ! "$file" =~ /workspace/(src|mrst_simulation_scripts)/s[0-9]{2} ]]; then
        return 0
    fi
    
    # Check if file has proper step structure
    if ! echo "$content" | grep -E "^#+ -+$" >/dev/null; then
        echo "⚠️  WARNING: Missing step structure markers"
        echo "Use '# ----' to separate major steps"
    fi
    
    return 0
}

# Main validation
echo "🔍 Validating code style for: $(basename "$FILE_PATH")"

# Read file content if not provided
if [ -z "$FILE_CONTENT" ] && [ -f "$FILE_PATH" ]; then
    FILE_CONTENT=$(cat "$FILE_PATH")
fi

# Run all checks
errors=0

# Check 1: English-only comments
if ! check_english_only "$FILE_CONTENT"; then
    ((errors++))
fi

# Check 2: Function length
if [ -f "$FILE_PATH" ]; then
    if ! check_function_length "$FILE_PATH"; then
        ((errors++))
    fi
fi

# Check 3: Try/except usage
if ! check_try_except "$FILE_CONTENT" "$FILE_PATH"; then
    ((errors++))
fi

# Check 4: Snake case naming
check_snake_case "$FILE_CONTENT" "$FILE_PATH"

# Check 5: Step structure
check_step_structure "$FILE_CONTENT" "$FILE_PATH"

# Final result
if [ $errors -gt 0 ]; then
    echo "❌ Code style validation failed with $errors error(s)"
    exit 2
else
    echo "✅ Code style validation passed"
    exit 0
fi