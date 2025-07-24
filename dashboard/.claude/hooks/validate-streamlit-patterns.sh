#!/bin/bash
# Streamlit pattern validation hook for dashboard/ directory
# Validates Streamlit best practices and dashboard patterns

FILE_PATH="$1"
CONTENT="$2"

# Exit codes:
# 0 - Success (continue)
# 2 - Blocking error (stop operation)

# Only validate Python files
if [[ ! "$FILE_PATH" =~ \.py$ ]]; then
    exit 0
fi

# Check for proper Streamlit imports
check_streamlit_imports() {
    if echo "$CONTENT" | grep "import streamlit" > /dev/null; then
        # Check for standard streamlit alias
        if ! echo "$CONTENT" | grep "import streamlit as st" > /dev/null; then
            echo "⚠️  WARNING: Use standard streamlit alias 'st'"
            echo "   import streamlit as st"
        fi
        
        # Check for streamlit components imports
        if echo "$CONTENT" | grep "from streamlit" > /dev/null; then
            if echo "$CONTENT" | grep -E "from streamlit import \*" > /dev/null; then
                echo "🚫 ERROR: Wildcard imports from streamlit are not allowed"
                echo "   Use specific imports: from streamlit import sidebar, columns"
                exit 2
            fi
        fi
    fi
}

# Check for proper page configuration
check_page_config() {
    if echo "$CONTENT" | grep "st\.set_page_config" > /dev/null; then
        # Check if set_page_config is at the top
        first_st_call=$(echo "$CONTENT" | grep -n "st\." | head -1 | cut -d: -f1)
        page_config_line=$(echo "$CONTENT" | grep -n "st\.set_page_config" | cut -d: -f1)
        
        if [ -n "$first_st_call" ] && [ -n "$page_config_line" ]; then
            if [ "$page_config_line" -gt "$first_st_call" ]; then
                echo "🚫 ERROR: st.set_page_config() must be the first Streamlit command"
                echo "   Move st.set_page_config() to the top of the script"
                exit 2
            fi
        fi
        
        # Check for required page config parameters
        if ! echo "$CONTENT" | grep "page_title=" > /dev/null; then
            echo "⚠️  WARNING: Consider adding page_title to st.set_page_config()"
        fi
    fi
}

# Check for proper state management
check_state_management() {
    # Check for session state usage
    if echo "$CONTENT" | grep "st\.session_state" > /dev/null; then
        # Look for proper initialization patterns
        if ! echo "$CONTENT" | grep -E "if.*not in st\.session_state" > /dev/null; then
            echo "⚠️  WARNING: Initialize session state variables safely"
            echo "   Use: if 'key' not in st.session_state: st.session_state.key = default_value"
        fi
    fi
    
    # Check for deprecated state management
    if echo "$CONTENT" | grep "@st\.cache" > /dev/null; then
        echo "⚠️  WARNING: @st.cache is deprecated"
        echo "   Use @st.cache_data or @st.cache_resource instead"
    fi
}

# Check for proper caching
check_caching_patterns() {
    # Check for function caching
    if echo "$CONTENT" | grep -E "def.*load|def.*fetch|def.*get" > /dev/null; then
        if ! echo "$CONTENT" | grep -E "@st\.cache_data|@st\.cache_resource" > /dev/null; then
            echo "⚠️  WARNING: Consider caching data loading functions"
            echo "   Use @st.cache_data for data functions or @st.cache_resource for global resources"
        fi
    fi
    
    # Check for proper cache parameters
    if echo "$CONTENT" | grep "@st\.cache_data" > /dev/null; then
        # Check for TTL in data loading functions
        if echo "$CONTENT" | grep -A 5 "@st\.cache_data" | grep -E "requests\.|pd\.read|load.*file" > /dev/null; then
            if ! echo "$CONTENT" | grep "ttl=" > /dev/null; then
                echo "⚠️  WARNING: Consider adding TTL to cached data loading functions"
                echo "   @st.cache_data(ttl=3600)  # Cache for 1 hour"
            fi
        fi
    fi
}

# Check for layout best practices
check_layout_patterns() {
    # Check for proper column usage
    if echo "$CONTENT" | grep "st\.columns" > /dev/null; then
        # Check for unpacking columns
        if ! echo "$CONTENT" | grep -E "col1.*col2.*=.*st\.columns|.*=.*st\.columns" > /dev/null; then
            echo "⚠️  WARNING: Unpack columns for better readability"
            echo "   col1, col2 = st.columns(2)"
        fi
    fi
    
    # Check for sidebar organization
    if echo "$CONTENT" | grep "st\.sidebar" > /dev/null; then
        if ! echo "$CONTENT" | grep "with st\.sidebar:" > /dev/null; then
            echo "⚠️  WARNING: Consider using 'with st.sidebar:' for better organization"
        fi
    fi
    
    # Check for container usage
    if echo "$CONTENT" | grep -E "st\.write.*\n.*st\.write" > /dev/null; then
        echo "⚠️  WARNING: Consider using containers for grouped content"
        echo "   Use st.container() or st.expander() to organize related elements"
    fi
}

# Check for data visualization patterns
check_visualization_patterns() {
    # Check for proper chart usage
    if echo "$CONTENT" | grep -E "st\.line_chart|st\.bar_chart|st\.area_chart" > /dev/null; then
        if ! echo "$CONTENT" | grep -E "use_container_width=True" > /dev/null; then
            echo "⚠️  WARNING: Consider using use_container_width=True for charts"
            echo "   Makes charts responsive to container width"
        fi
    fi
    
    # Check for plotly/matplotlib integration
    if echo "$CONTENT" | grep -E "plotly|matplotlib|seaborn" > /dev/null; then
        if echo "$CONTENT" | grep "plotly" > /dev/null; then
            if ! echo "$CONTENT" | grep "st\.plotly_chart" > /dev/null; then
                echo "⚠️  WARNING: Use st.plotly_chart() to display Plotly figures"
            fi
        fi
        
        if echo "$CONTENT" | grep -E "matplotlib|plt\." > /dev/null; then
            if ! echo "$CONTENT" | grep "st\.pyplot" > /dev/null; then
                echo "⚠️  WARNING: Use st.pyplot() to display matplotlib figures"
            fi
        fi
    fi
}

# Check for user input validation
check_input_validation() {
    # Check for user inputs without validation
    if echo "$CONTENT" | grep -E "st\.text_input|st\.number_input|st\.selectbox" > /dev/null; then
        input_lines=$(echo "$CONTENT" | grep -n -E "st\.text_input|st\.number_input|st\.selectbox")
        
        echo "$input_lines" | while read -r line; do
            line_num=$(echo "$line" | cut -d: -f1)
            
            # Check if there's validation after the input
            validation_found=false
            for i in {1..5}; do
                check_line=$((line_num + i))
                if sed -n "${check_line}p" <<< "$CONTENT" | grep -E "if.*len|if.*not|if.*is|if.*empty" > /dev/null; then
                    validation_found=true
                    break
                fi
            done
            
            if [ "$validation_found" = false ]; then
                echo "⚠️  WARNING: Consider validating user input (line $line_num)"
                echo "   Check for empty values, length limits, or format validation"
            fi
        done
    fi
}

# Check for error handling
check_error_handling() {
    # Check for try/except blocks around data operations
    if echo "$CONTENT" | grep -E "pd\.|np\.|requests\." > /dev/null; then
        if ! echo "$CONTENT" | grep -E "try:|except" > /dev/null; then
            echo "⚠️  WARNING: Consider adding error handling for data operations"
            echo "   Use try/except blocks around data loading and processing"
        fi
    fi
    
    # Check for st.error usage
    if echo "$CONTENT" | grep "except" > /dev/null; then
        if ! echo "$CONTENT" | grep "st\.error\|st\.warning" > /dev/null; then
            echo "⚠️  WARNING: Consider using st.error() or st.warning() to display errors"
        fi
    fi
}

# Run all checks
check_streamlit_imports
check_page_config
check_state_management
check_caching_patterns
check_layout_patterns
check_visualization_patterns
check_input_validation
check_error_handling

echo "✅ Streamlit pattern validation completed for $FILE_PATH"
exit 0