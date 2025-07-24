#!/bin/bash
# Visualization component validation hook for dashboard/ directory
# Validates data visualization best practices and component patterns

FILE_PATH="$1"
CONTENT="$2"

# Exit codes:
# 0 - Success (continue)
# 2 - Blocking error (stop operation)

# Only validate Python files
if [[ ! "$FILE_PATH" =~ \.py$ ]]; then
    exit 0
fi

# Check for proper visualization library imports
check_viz_imports() {
    # Check for plotting library imports
    if echo "$CONTENT" | grep -E "import.*plotly|import.*matplotlib|import.*seaborn" > /dev/null; then
        # Plotly imports
        if echo "$CONTENT" | grep "import plotly" > /dev/null; then
            if ! echo "$CONTENT" | grep -E "import plotly\.express as px|import plotly\.graph_objects as go" > /dev/null; then
                echo "⚠️  WARNING: Use standard Plotly aliases"
                echo "   import plotly.express as px"
                echo "   import plotly.graph_objects as go"
            fi
        fi
        
        # Matplotlib imports
        if echo "$CONTENT" | grep "import matplotlib" > /dev/null; then
            if ! echo "$CONTENT" | grep "import matplotlib.pyplot as plt" > /dev/null; then
                echo "⚠️  WARNING: Use standard matplotlib alias"
                echo "   import matplotlib.pyplot as plt"
            fi
        fi
        
        # Seaborn imports
        if echo "$CONTENT" | grep "import seaborn" > /dev/null; then
            if ! echo "$CONTENT" | grep "import seaborn as sns" > /dev/null; then
                echo "⚠️  WARNING: Use standard seaborn alias"
                echo "   import seaborn as sns"
            fi
        fi
    fi
}

# Check for chart configuration best practices
check_chart_config() {
    # Check for chart titles and labels
    if echo "$CONTENT" | grep -E "px\.|go\.|plt\.|sns\." > /dev/null; then
        # Plotly charts
        if echo "$CONTENT" | grep -E "px\.(line|bar|scatter|histogram)" > /dev/null; then
            if ! echo "$CONTENT" | grep -E "title=|labels=" > /dev/null; then
                echo "⚠️  WARNING: Consider adding titles and labels to Plotly charts"
                echo "   Add title='Chart Title' and labels={'x': 'X Label', 'y': 'Y Label'}"
            fi
        fi
        
        # Matplotlib charts
        if echo "$CONTENT" | grep -E "plt\.(plot|bar|scatter|hist)" > /dev/null; then
            if ! echo "$CONTENT" | grep -E "plt\.(title|xlabel|ylabel)" > /dev/null; then
                echo "⚠️  WARNING: Consider adding titles and labels to matplotlib charts"
                echo "   Add plt.title(), plt.xlabel(), plt.ylabel()"
            fi
        fi
    fi
    
    # Check for responsive design
    if echo "$CONTENT" | grep -E "fig\.update_layout|plt\.figure" > /dev/null; then
        # Plotly responsive design
        if echo "$CONTENT" | grep "fig\.update_layout" > /dev/null; then
            if ! echo "$CONTENT" | grep -E "autosize=True|width=|height=" > /dev/null; then
                echo "⚠️  WARNING: Consider making Plotly charts responsive"
                echo "   Add autosize=True or specific width/height in update_layout()"
            fi
        fi
        
        # Matplotlib figure size
        if echo "$CONTENT" | grep "plt\.figure" > /dev/null; then
            if ! echo "$CONTENT" | grep "figsize=" > /dev/null; then
                echo "⚠️  WARNING: Consider setting figure size for matplotlib"
                echo "   Add figsize=(10, 6) to plt.figure()"
            fi
        fi
    fi
}

# Check for color and styling consistency
check_styling_consistency() {
    # Check for color palette usage
    if echo "$CONTENT" | grep -E "color=|colors=" > /dev/null; then
        # Look for hardcoded colors
        if echo "$CONTENT" | grep -E "color='red'|color='blue'|color='green'" > /dev/null; then
            echo "⚠️  WARNING: Consider using consistent color palettes"
            echo "   Use color palettes like px.colors.qualitative.Set1 or custom brand colors"
        fi
    fi
    
    # Check for theme consistency
    if echo "$CONTENT" | grep -E "plotly_theme|template=" > /dev/null; then
        if ! echo "$CONTENT" | grep -E "template='plotly_white'|template='plotly_dark'" > /dev/null; then
            echo "⚠️  WARNING: Consider using consistent Plotly themes"
            echo "   Use template='plotly_white' or template='plotly_dark' for consistency"
        fi
    fi
}

# Check for data handling in visualizations
check_data_handling() {
    # Check for data validation before plotting
    if echo "$CONTENT" | grep -E "px\.|plt\.|sns\." > /dev/null; then
        # Look for data validation
        if ! echo "$CONTENT" | grep -E "\.isnull|\.isna|\.empty|len\(" > /dev/null; then
            echo "⚠️  WARNING: Consider validating data before plotting"
            echo "   Check for null values, empty datasets, or data types"
        fi
        
        # Check for large dataset handling
        if echo "$CONTENT" | grep -E "\.shape\[0\]|len\(" > /dev/null; then
            if ! echo "$CONTENT" | grep -E "sample\(|head\(|tail\(" > /dev/null; then
                echo "⚠️  WARNING: Consider sampling large datasets for better performance"
                echo "   Use .sample(n=1000) or .head(1000) for large datasets"
            fi
        fi
    fi
}

# Check for interactive features
check_interactivity() {
    # Check for Plotly interactivity
    if echo "$CONTENT" | grep -E "px\.|go\." > /dev/null; then
        # Look for hover customization
        if ! echo "$CONTENT" | grep -E "hover_data=|hover_name=" > /dev/null; then
            echo "⚠️  WARNING: Consider customizing hover information"
            echo "   Add hover_data=['col1', 'col2'] for more informative tooltips"
        fi
        
        # Check for selection features
        if echo "$CONTENT" | grep -E "px\.scatter|px\.line" > /dev/null; then
            if ! echo "$CONTENT" | grep -E "selection_mode=" > /dev/null; then
                echo "⚠️  WARNING: Consider enabling selection features"
                echo "   Add selection_mode='points' for interactive point selection"
            fi
        fi
    fi
}

# Check for accessibility
check_accessibility() {
    # Check for colorblind-friendly palettes
    if echo "$CONTENT" | grep -E "color_discrete_sequence=|palette=" > /dev/null; then
        if echo "$CONTENT" | grep -E "color_discrete_sequence=.*px\.colors" > /dev/null; then
            if ! echo "$CONTENT" | grep -E "Colorblind|Safe|cb_friendly" > /dev/null; then
                echo "⚠️  WARNING: Consider using colorblind-friendly palettes"
                echo "   Use px.colors.qualitative.Safe or custom accessible colors"
            fi
        fi
    fi
    
    # Check for alt text or descriptions
    if echo "$CONTENT" | grep -E "st\.plotly_chart|st\.pyplot" > /dev/null; then
        if ! echo "$CONTENT" | grep -E "caption=|help=" > /dev/null; then
            echo "⚠️  WARNING: Consider adding chart descriptions"
            echo "   Add help='Chart description' for accessibility"
        fi
    fi
}

# Check for performance optimization
check_performance() {
    # Check for inefficient plotting patterns
    if echo "$CONTENT" | grep -E "for.*in.*:" > /dev/null; then
        if echo "$CONTENT" | grep -A 5 "for.*in.*:" | grep -E "px\.|plt\.|st\." > /dev/null; then
            echo "⚠️  WARNING: Avoid creating charts in loops"
            echo "   Prepare data first, then create single chart with grouped/faceted data"
        fi
    fi
    
    # Check for memory-intensive operations
    if echo "$CONTENT" | grep -E "\.pivot|\.groupby.*\.apply" > /dev/null; then
        if echo "$CONTENT" | grep -A 3 -B 3 -E "\.pivot|\.groupby.*\.apply" | grep -E "px\.|plt\." > /dev/null; then
            echo "⚠️  WARNING: Complex data transformations before plotting"
            echo "   Consider caching data transformations with @st.cache_data"
        fi
    fi
}

# Check for component reusability
check_reusability() {
    # Check for chart creation in functions
    chart_creation=$(echo "$CONTENT" | grep -E "px\.|go\.|plt\.|sns\.")
    function_definitions=$(echo "$CONTENT" | grep -E "def ")
    
    if [ -n "$chart_creation" ] && [ -z "$function_definitions" ]; then
        echo "⚠️  WARNING: Consider creating reusable chart functions"
        echo "   Wrap chart creation in functions for better organization and reuse"
    fi
    
    # Check for parameterized charts
    if echo "$CONTENT" | grep -E "def.*chart|def.*plot" > /dev/null; then
        chart_functions=$(echo "$CONTENT" | grep -E "def.*(chart|plot)")
        
        echo "$chart_functions" | while read -r line; do
            if ! echo "$line" | grep -E "data.*:" > /dev/null; then
                echo "⚠️  WARNING: Chart functions should accept data as parameter"
                echo "   def create_chart(data, title='Default Title'):"
            fi
        done
    fi
}

# Check for error handling in visualizations
check_viz_error_handling() {
    # Check for data-related error handling
    if echo "$CONTENT" | grep -E "px\.|plt\.|sns\." > /dev/null; then
        if ! echo "$CONTENT" | grep -E "try:|except" > /dev/null; then
            echo "⚠️  WARNING: Consider error handling for visualization code"
            echo "   Handle cases like empty data, invalid data types, or plotting errors"
        fi
    fi
    
    # Check for graceful degradation
    if echo "$CONTENT" | grep -E "st\.plotly_chart|st\.pyplot" > /dev/null; then
        if ! echo "$CONTENT" | grep -E "st\.error|st\.warning|st\.info" > /dev/null; then
            echo "⚠️  WARNING: Consider user feedback for visualization errors"
            echo "   Use st.error() or st.warning() to inform users of issues"
        fi
    fi
}

# Run all checks
check_viz_imports
check_chart_config
check_styling_consistency
check_data_handling
check_interactivity
check_accessibility
check_performance
check_reusability
check_viz_error_handling

echo "✅ Visualization component validation completed for $FILE_PATH"
exit 0