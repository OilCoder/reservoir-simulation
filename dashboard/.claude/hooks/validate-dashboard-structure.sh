#!/bin/bash
# Dashboard structure validation hook for dashboard/ directory
# Validates overall dashboard organization and structure

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

# Check for proper dashboard structure
check_dashboard_structure() {
    # Check for main page structure
    if grep -q "def main()" "$FILE_PATH"; then
        echo "✅ Found main() function - good structure"
    else
        if grep -q "st\." "$FILE_PATH"; then
            echo "⚠️  WARNING: Consider organizing code in a main() function"
            echo "   def main(): # dashboard code here"
            echo "   if __name__ == '__main__': main()"
        fi
    fi
    
    # Check for page organization
    if grep -q "st\.sidebar" "$FILE_PATH"; then
        # Look for navigation structure
        if grep -q "selectbox\|radio\|tabs" "$FILE_PATH"; then
            echo "✅ Found navigation elements - good UX structure"
        else
            echo "⚠️  WARNING: Consider adding navigation for better UX"
            echo "   Use st.selectbox() or st.radio() for page selection"
        fi
    fi
}

# Check for data flow organization
check_data_flow() {
    # Look for data loading patterns
    data_loading=$(grep -n -E "@st\.cache_data|load.*data|read.*csv|read.*parquet" "$FILE_PATH")
    data_processing=$(grep -n -E "\.transform|\.fit|\.predict|\.groupby|\.merge" "$FILE_PATH")
    visualization=$(grep -n -E "st\.plotly_chart|st\.pyplot|px\.|plt\." "$FILE_PATH")
    
    if [ -n "$data_loading" ] && [ -n "$data_processing" ] && [ -n "$visualization" ]; then
        echo "✅ Found complete data pipeline: load -> process -> visualize"
    else
        if [ -n "$visualization" ]; then
            if [ -z "$data_loading" ]; then
                echo "⚠️  WARNING: Visualization found without clear data loading"
                echo "   Consider organizing data loading with @st.cache_data"
            fi
        fi
    fi
}

# Check for user experience patterns
check_ux_patterns() {
    # Check for loading indicators
    if grep -E "\.cache_data|\.cache_resource" "$FILE_PATH" > /dev/null; then
        if ! grep -E "st\.spinner|st\.progress" "$FILE_PATH" > /dev/null; then
            echo "⚠️  WARNING: Consider adding loading indicators"
            echo "   Use st.spinner('Loading...') or st.progress() for better UX"
        fi
    fi
    
    # Check for error messages
    if grep -E "except|try:" "$FILE_PATH" > /dev/null; then
        if ! grep -E "st\.error|st\.warning|st\.success" "$FILE_PATH" > /dev/null; then
            echo "⚠️  WARNING: Consider user-friendly error messages"
            echo "   Use st.error(), st.warning(), or st.success() for user feedback"
        fi
    fi
    
    # Check for help/information
    if grep -E "st\.selectbox|st\.slider|st\.text_input" "$FILE_PATH" > /dev/null; then
        if ! grep -E "help=|st\.help|st\.info" "$FILE_PATH" > /dev/null; then
            echo "⚠️  WARNING: Consider adding help text for user inputs"
            echo "   Add help='Description' parameter to input widgets"
        fi
    fi
}

# Check for responsive design considerations
check_responsive_design() {
    # Check for column layouts
    if grep "st\.columns" "$FILE_PATH" > /dev/null; then
        echo "✅ Found column layouts - good for responsive design"
        
        # Check for adaptive column counts
        if ! grep -E "st\.columns.*\[.*\]" "$FILE_PATH" > /dev/null; then
            echo "⚠️  WARNING: Consider adaptive column layouts"
            echo "   Use st.columns([1, 2, 1]) for better control"
        fi
    fi
    
    # Check for mobile considerations
    if grep -E "use_container_width" "$FILE_PATH" > /dev/null; then
        echo "✅ Found container width usage - good for mobile"
    else
        if grep -E "st\.plotly_chart|st\.pyplot" "$FILE_PATH" > /dev/null; then
            echo "⚠️  WARNING: Consider mobile-friendly chart sizing"
            echo "   Add use_container_width=True to charts"
        fi
    fi
}

# Check for state management patterns
check_state_management() {
    # Check for session state usage
    if grep "st\.session_state" "$FILE_PATH" > /dev/null; then
        # Check for proper initialization
        if grep -E "if.*not in st\.session_state" "$FILE_PATH" > /dev/null; then
            echo "✅ Found proper session state initialization"
        else
            echo "⚠️  WARNING: Initialize session state variables safely"
            echo "   if 'key' not in st.session_state: st.session_state.key = value"
        fi
        
        # Check for state cleanup
        state_keys=$(grep -o "st\.session_state\.[a-zA-Z_][a-zA-Z0-9_]*" "$FILE_PATH" | sort -u)
        if [ $(echo "$state_keys" | wc -l) -gt 5 ]; then
            echo "⚠️  WARNING: Many session state variables detected"
            echo "   Consider state cleanup or organization patterns"
        fi
    fi
}

# Check for security considerations
check_security() {
    # Check for file uploads
    if grep "st\.file_uploader" "$FILE_PATH" > /dev/null; then
        # Check for file validation
        if ! grep -E "\.name\.endswith|type.*in|size" "$FILE_PATH" > /dev/null; then
            echo "⚠️  WARNING: Validate uploaded files"
            echo "   Check file types, sizes, and extensions for security"
        fi
    fi
    
    # Check for external URL usage
    if grep -E "requests\.|urllib\.|http" "$FILE_PATH" > /dev/null; then
        if ! grep -E "timeout=|verify=" "$FILE_PATH" > /dev/null; then
            echo "⚠️  WARNING: Configure timeouts for external requests"
            echo "   Add timeout= parameter to prevent hanging requests"
        fi
    fi
    
    # Check for SQL injection patterns (if any database code)
    if grep -E "SELECT|INSERT|UPDATE|DELETE" "$FILE_PATH" > /dev/null; then
        if ! grep -E "params=|%s|\.format" "$FILE_PATH" > /dev/null; then
            echo "🚫 ERROR: Potential SQL injection vulnerability"
            echo "   Use parameterized queries instead of string concatenation"
            exit 2
        fi
    fi
}

# Check for performance patterns
check_performance_patterns() {
    # Check for expensive operations outside cache
    expensive_ops=$(grep -E "\.read_csv|\.read_parquet|requests\.get|\.groupby.*\.apply" "$FILE_PATH")
    cached_ops=$(grep -E "@st\.cache_data|@st\.cache_resource" "$FILE_PATH")
    
    if [ -n "$expensive_ops" ] && [ -z "$cached_ops" ]; then
        echo "⚠️  WARNING: Expensive operations without caching detected"
        echo "   Consider using @st.cache_data for data loading operations"
    fi
    
    # Check for rerun efficiency
    if grep -E "st\.rerun|st\.experimental_rerun" "$FILE_PATH" > /dev/null; then
        echo "⚠️  WARNING: Manual rerun detected"
        echo "   Consider using callbacks or session state instead of manual reruns"
    fi
}

# Check for accessibility patterns
check_accessibility() {
    # Check for semantic HTML usage
    if grep -E "st\.markdown.*<" "$FILE_PATH" > /dev/null; then
        if grep -E "<h1>|<h2>|<h3>" "$FILE_PATH" > /dev/null; then
            echo "✅ Found semantic HTML headers - good for accessibility"
        fi
    fi
    
    # Check for alt text in images
    if grep "st\.image" "$FILE_PATH" > /dev/null; then
        if ! grep "caption=" "$FILE_PATH" > /dev/null; then
            echo "⚠️  WARNING: Add captions to images for accessibility"
            echo "   st.image(image, caption='Descriptive caption')"
        fi
    fi
}

# Run all checks
echo "🔍 Validating dashboard structure for $FILE_PATH"

check_dashboard_structure
check_data_flow
check_ux_patterns
check_responsive_design
check_state_management
check_security
check_performance_patterns
check_accessibility

echo "✅ Dashboard structure validation completed for $FILE_PATH"
exit 0