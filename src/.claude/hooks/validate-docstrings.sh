#!/bin/bash
# Docstring validation hook for src/ directory
# Validates Google Style docstrings for ML pipeline code

FILE_PATH="$1"

# Exit codes:
# 0 - Success (continue)
# 2 - Blocking error (stop operation)

# Only validate Python files
if [[ ! "$FILE_PATH" =~ \.py$ ]]; then
    exit 0
fi

if [ ! -f "$FILE_PATH" ]; then
    exit 0
fi

# Check for functions/classes without docstrings
check_missing_docstrings() {
    # Find function definitions
    functions=$(grep -n "^def " "$FILE_PATH" | grep -v "__init__\|__str__\|__repr__")
    
    if [ -n "$functions" ]; then
        echo "$functions" | while read -r line; do
            line_num=$(echo "$line" | cut -d: -f1)
            func_name=$(echo "$line" | sed 's/.*def \([^(]*\).*/\1/')
            
            # Check if next few lines contain docstring
            docstring_found=false
            for i in {1..3}; do
                check_line=$((line_num + i))
                if sed -n "${check_line}p" "$FILE_PATH" | grep -E '""".*"""' > /dev/null; then
                    docstring_found=true
                    break
                elif sed -n "${check_line}p" "$FILE_PATH" | grep '"""' > /dev/null; then
                    docstring_found=true
                    break
                fi
            done
            
            if [ "$docstring_found" = false ]; then
                echo "⚠️  WARNING: Function '$func_name' missing docstring (line $line_num)"
            fi
        done
    fi
    
    # Find class definitions
    classes=$(grep -n "^class " "$FILE_PATH")
    
    if [ -n "$classes" ]; then
        echo "$classes" | while read -r line; do
            line_num=$(echo "$line" | cut -d: -f1)
            class_name=$(echo "$line" | sed 's/.*class \([^(]*\).*/\1/' | sed 's/:.*//')
            
            # Check if next few lines contain docstring
            docstring_found=false
            for i in {1..5}; do
                check_line=$((line_num + i))
                if sed -n "${check_line}p" "$FILE_PATH" | grep -E '""".*"""' > /dev/null; then
                    docstring_found=true
                    break
                elif sed -n "${check_line}p" "$FILE_PATH" | grep '"""' > /dev/null; then
                    docstring_found=true
                    break
                fi
            done
            
            if [ "$docstring_found" = false ]; then
                echo "⚠️  WARNING: Class '$class_name' missing docstring (line $line_num)"
            fi
        done
    fi
}

# Check docstring format (basic Google Style check)
check_docstring_format() {
    # Look for docstrings
    docstrings=$(grep -n '"""' "$FILE_PATH")
    
    if [ -n "$docstrings" ]; then
        # Check for common Google Style sections
        if grep -q '"""' "$FILE_PATH"; then
            # Look for Args: section in functions with parameters
            functions_with_params=$(grep -n "def .*(" "$FILE_PATH" | grep -v "def.*():")
            
            if [ -n "$functions_with_params" ]; then
                echo "$functions_with_params" | while read -r line; do
                    line_num=$(echo "$line" | cut -d: -f1)
                    func_name=$(echo "$line" | sed 's/.*def \([^(]*\).*/\1/')
                    
                    # Check if docstring has Args: section
                    start_line=$((line_num + 1))
                    end_line=$((line_num + 20))
                    
                    docstring_section=$(sed -n "${start_line},${end_line}p" "$FILE_PATH")
                    
                    if echo "$docstring_section" | grep '"""' > /dev/null; then
                        if ! echo "$docstring_section" | grep -i "Args:" > /dev/null; then
                            if echo "$line" | grep -E "def.*\([^)]+\):" > /dev/null; then
                                echo "⚠️  WARNING: Function '$func_name' with parameters missing 'Args:' section"
                            fi
                        fi
                        
                        # Check for Returns: section if function returns something
                        if echo "$docstring_section" | grep "return " > /dev/null; then
                            if ! echo "$docstring_section" | grep -i "Returns:" > /dev/null; then
                                echo "⚠️  WARNING: Function '$func_name' with return statement missing 'Returns:' section"
                            fi
                        fi
                    fi
                done
            fi
        fi
    fi
}

# Check for ML-specific docstring requirements
check_ml_docstring_requirements() {
    # Check for fit/transform methods in classes
    if grep -q "def fit(" "$FILE_PATH" || grep -q "def transform(" "$FILE_PATH"; then
        if ! grep -i "sklearn" "$FILE_PATH" > /dev/null; then
            echo "⚠️  WARNING: ML transformer class should document sklearn compatibility"
        fi
    fi
    
    # Check for model classes
    if grep -q "class.*Model\|class.*Classifier\|class.*Regressor" "$FILE_PATH"; then
        if ! grep -A 10 'class.*Model\|class.*Classifier\|class.*Regressor' "$FILE_PATH" | grep -i "parameters\|attributes" > /dev/null; then
            echo "⚠️  WARNING: ML model class should document parameters and attributes"
        fi
    fi
}

# Run all checks
check_missing_docstrings
check_docstring_format
check_ml_docstring_requirements

echo "✅ Docstring validation completed for $FILE_PATH"
exit 0