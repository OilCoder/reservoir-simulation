#!/bin/bash
# Smart file routing hook - suggests correct folder placement
# Exit codes: 0 = continue, 1 = suggestion (non-blocking), 2 = blocking error

FILE_PATH="$1"
CONTENT="$2"
OPERATION="$3"  # Write, Edit, or MultiEdit

echo "🔍 Analyzing file routing for: $(basename "$FILE_PATH")"

# Extract filename and current directory
filename=$(basename "$FILE_PATH")
current_dir=$(dirname "$FILE_PATH")

# Function to suggest routing based on filename patterns
suggest_by_filename() {
    local file="$1"
    
    # Test file patterns
    if [[ "$file" =~ ^test_.*\.py$ ]] || [[ "$file" =~ .*_test\.py$ ]] || [[ "$file" =~ ^test.*\.m$ ]]; then
        echo "tests"
        return 0
    fi
    
    # Debug file patterns  
    if [[ "$file" =~ ^debug_.*\.(py|m)$ ]] || [[ "$file" =~ ^dbg_.*\.(py|m)$ ]]; then
        echo "debug"
        return 0
    fi
    
    # MRST simulation patterns
    if [[ "$file" =~ ^s[0-9]{2}.*\.m$ ]]; then
        echo "mrst_simulation_scripts"
        return 0
    fi
    
    # Dashboard patterns
    if [[ "$file" =~ .*dashboard.*\.py$ ]] || [[ "$file" =~ .*streamlit.*\.py$ ]]; then
        echo "dashboard"
        return 0
    fi
    
    # Regular source files
    if [[ "$file" =~ ^s[0-9]{2}.*\.py$ ]]; then
        echo "src"
        return 0
    fi
    
    return 1
}

# Function to suggest routing based on content analysis
suggest_by_content() {
    local content="$1"
    
    # Test framework imports
    if echo "$content" | grep -E "(import pytest|import unittest|from unittest|assert.*=|def test_)" >/dev/null; then
        echo "tests"
        return 0
    fi
    
    # Debug patterns in content
    if echo "$content" | grep -E "(print\(.*debug|disp\(.*debug|DEBUG.*=.*True)" >/dev/null; then
        echo "debug"
        return 0
    fi
    
    # Streamlit imports
    if echo "$content" | grep -E "(import streamlit|st\.|plotly)" >/dev/null; then
        echo "dashboard" 
        return 0
    fi
    
    # MRST functions
    if echo "$content" | grep -E "(startup|ROOTDIR|mrstModule|Grid|Rock)" >/dev/null; then
        echo "mrst_simulation_scripts"
        return 0
    fi
    
    # ML/Data science patterns
    if echo "$content" | grep -E "(import (sklearn|tensorflow|torch|pandas|numpy)|from (sklearn|tensorflow|torch))" >/dev/null; then
        echo "src"
        return 0
    fi
    
    return 1
}

# Get routing suggestions
filename_suggestion=$(suggest_by_filename "$filename")
content_suggestion=""

if [ -n "$CONTENT" ]; then
    content_suggestion=$(suggest_by_content "$CONTENT")
fi

# Determine final suggestion
suggested_folder=""
confidence="low"

if [ -n "$filename_suggestion" ] && [ -n "$content_suggestion" ]; then
    if [ "$filename_suggestion" = "$content_suggestion" ]; then
        suggested_folder="$filename_suggestion"
        confidence="high"
    else
        suggested_folder="$filename_suggestion"  # Filename takes precedence
        confidence="medium"
    fi
elif [ -n "$filename_suggestion" ]; then
    suggested_folder="$filename_suggestion"
    confidence="medium"
elif [ -n "$content_suggestion" ]; then
    suggested_folder="$content_suggestion"
    confidence="low"
fi

# Check if file is already in the suggested location
if [ -n "$suggested_folder" ]; then
    if [[ "$current_dir" == *"$suggested_folder"* ]]; then
        echo "✅ File is already in correct location: $suggested_folder/"
        exit 0
    else
        suggested_path="/workspace/$suggested_folder/$filename"
        echo "💡 ROUTING SUGGESTION ($confidence confidence):"
        echo "   Current:   $FILE_PATH"
        echo "   Suggested: $suggested_path"
        echo "   Reason:    File pattern/content indicates this should be in $suggested_folder/"
        
        # For high confidence suggestions, we could make it blocking
        if [ "$confidence" = "high" ] && [ "$OPERATION" = "Write" ]; then
            echo "⚠️  WARNING: High confidence routing suggestion - consider using suggested path"
            # Non-blocking for now, but could be made blocking:
            # exit 2
        fi
        exit 1  # Non-blocking suggestion
    fi
else
    echo "ℹ️  No specific routing suggestion (generic file)"
    exit 0
fi