#!/bin/bash
# Markdown structure validation hook for obsidian-vault/ directory
# Validates markdown structure and documentation standards

FILE_PATH="$1"
CONTENT="$2"

# Exit codes:
# 0 - Success (continue)
# 2 - Blocking error (stop operation)

# Only validate markdown files
if [[ ! "$FILE_PATH" =~ \.md$ ]]; then
    exit 0
fi

# Check markdown structure
check_markdown_structure() {
    # Check for proper heading hierarchy
    headings=$(echo "$CONTENT" | grep -n "^#" 2>/dev/null || true)
    
    if [ -n "$headings" ]; then
        echo "✅ Found markdown headings"
        
        # Check heading levels
        prev_level=0
        heading_issues=0
        
        echo "$headings" | while read -r line; do
            level=$(echo "$line" | sed 's/[^#].*$//' | wc -c)
            level=$((level - 1))  # Subtract 1 because wc -c counts newline
            
            if [ "$level" -gt $((prev_level + 1)) ] && [ "$prev_level" -gt 0 ]; then
                echo "⚠️  WARNING: Heading level skip detected (h$prev_level to h$level)"
                echo "   Line: $line"
                heading_issues=$((heading_issues + 1))
            fi
            
            prev_level=$level
        done
        
        # Check for main title (h1)
        if ! echo "$CONTENT" | grep -q "^# "; then
            echo "⚠️  WARNING: Document missing main title (h1)"
            echo "   Add a single # Main Title at the top"
        fi
        
        # Check for multiple h1s
        h1_count=$(echo "$CONTENT" | grep -c "^# " 2>/dev/null || echo "0")
        if [ "$h1_count" -gt 1 ]; then
            echo "⚠️  WARNING: Multiple h1 headings found ($h1_count)"
            echo "   Use only one h1 per document"
        fi
    else
        echo "⚠️  WARNING: No headings found in markdown document"
        echo "   Consider adding structure with # headings"
    fi
}

# Check for proper list formatting
check_list_formatting() {
    # Check for consistent bullet points
    bullets=$(echo "$CONTENT" | grep -E "^[[:space:]]*[\-\*\+]" 2>/dev/null || true)
    if [ -n "$bullets" ]; then
        # Check for mixed bullet styles
        dash_bullets=$(echo "$bullets" | grep -c "^[[:space:]]*-" 2>/dev/null || echo "0")
        star_bullets=$(echo "$bullets" | grep -c "^[[:space:]]*\*" 2>/dev/null || echo "0")
        plus_bullets=$(echo "$bullets" | grep -c "^[[:space:]]*+" 2>/dev/null || echo "0")
        
        mixed_count=0
        [ "$dash_bullets" -gt 0 ] && mixed_count=$((mixed_count + 1))
        [ "$star_bullets" -gt 0 ] && mixed_count=$((mixed_count + 1))
        [ "$plus_bullets" -gt 0 ] && mixed_count=$((mixed_count + 1))
        
        if [ "$mixed_count" -gt 1 ]; then
            echo "⚠️  WARNING: Mixed bullet point styles detected"
            echo "   Use consistent style: - (dash), * (star), or + (plus)"
        else
            echo "✅ Consistent bullet point style"
        fi
    fi
    
    # Check for proper numbered list formatting
    numbered_lists=$(echo "$CONTENT" | grep -E "^[[:space:]]*[0-9]+\." 2>/dev/null || true)
    if [ -n "$numbered_lists" ]; then
        # Check for proper numbering sequence
        echo "✅ Found numbered lists"
        
        # Check for consistent indentation
        inconsistent_indent=$(echo "$numbered_lists" | awk '{print length($0) - length(ltrim($0))}' | sort -u | wc -l)
        if [ "$inconsistent_indent" -gt 2 ]; then
            echo "⚠️  WARNING: Inconsistent list indentation"
            echo "   Use consistent spacing for nested lists"
        fi
    fi
}

# Check for code block formatting
check_code_blocks() {
    # Check for fenced code blocks
    fenced_blocks=$(echo "$CONTENT" | grep -c "^\`\`\`" 2>/dev/null || echo "0")
    
    if [ "$fenced_blocks" -gt 0 ]; then
        # Should be even number (opening and closing)
        if [ $((fenced_blocks % 2)) -ne 0 ]; then
            echo "🚫 ERROR: Unmatched code fence blocks"
            echo "   Each ``` opening must have a closing ```"
            exit 2
        else
            echo "✅ Found properly closed code blocks"
        fi
        
        # Check for language specification
        code_starts=$(echo "$CONTENT" | grep -n "^\`\`\`" | sed -n '1~2p')
        unspecified_count=0
        
        echo "$code_starts" | while read -r line; do
            if echo "$line" | grep -E "^\`\`\`$" > /dev/null; then
                unspecified_count=$((unspecified_count + 1))
            fi
        done
        
        if [ "$unspecified_count" -gt 0 ]; then
            echo "⚠️  WARNING: Code blocks without language specification"
            echo "   Use \`\`\`python, \`\`\`bash, \`\`\`json, etc. for syntax highlighting"
        fi
    fi
    
    # Check for inline code formatting
    inline_code=$(echo "$CONTENT" | grep -c "\`[^\`]*\`" 2>/dev/null || echo "0")
    if [ "$inline_code" -gt 0 ]; then
        echo "✅ Found inline code formatting ($inline_code instances)"
    fi
}

# Check for proper table formatting
check_table_formatting() {
    # Check for markdown tables
    table_rows=$(echo "$CONTENT" | grep -c "^|.*|$" 2>/dev/null || echo "0")
    
    if [ "$table_rows" -gt 0 ]; then
        echo "✅ Found markdown tables"
        
        # Check for table headers (should have |---|--- separator)
        table_separators=$(echo "$CONTENT" | grep -c "^|.*---.*|$" 2>/dev/null || echo "0")
        
        if [ "$table_separators" -eq 0 ]; then
            echo "⚠️  WARNING: Tables missing header separators"
            echo "   Add |---|---| row after headers"
        else
            echo "✅ Tables have proper header separators"
        fi
        
        # Check for table alignment consistency
        table_content=$(echo "$CONTENT" | grep "^|.*|$")
        
        # Simple check for consistent column count
        first_row_cols=$(echo "$table_content" | head -1 | tr -cd '|' | wc -c)
        inconsistent_tables=$(echo "$table_content" | while read -r row; do
            cols=$(echo "$row" | tr -cd '|' | wc -c)
            if [ "$cols" -ne "$first_row_cols" ]; then
                echo "inconsistent"
                break
            fi
        done)
        
        if [ -n "$inconsistent_tables" ]; then
            echo "⚠️  WARNING: Inconsistent table column counts"
            echo "   Ensure all table rows have the same number of columns"
        fi
    fi
}

# Check for link formatting
check_basic_links() {
    # Check for markdown link syntax
    markdown_links=$(echo "$CONTENT" | grep -c "\[.*\](.*)" 2>/dev/null || echo "0")
    
    if [ "$markdown_links" -gt 0 ]; then
        echo "✅ Found markdown links ($markdown_links)"
        
        # Check for empty link text
        empty_links=$(echo "$CONTENT" | grep -c "\[\](.*)" 2>/dev/null || echo "0")
        if [ "$empty_links" -gt 0 ]; then
            echo "⚠️  WARNING: Empty link text found ($empty_links instances)"
            echo "   Add descriptive text: [Description](url)"
        fi
        
        # Check for empty URLs
        empty_urls=$(echo "$CONTENT" | grep -c "\[.*\]()" 2>/dev/null || echo "0")
        if [ "$empty_urls" -gt 0 ]; then
            echo "⚠️  WARNING: Empty link URLs found ($empty_urls instances)"
            echo "   Add proper URLs: [text](https://example.com)"
        fi
    fi
    
    # Check for Obsidian-style wikilinks
    wiki_links=$(echo "$CONTENT" | grep -c "\[\[.*\]\]" 2>/dev/null || echo "0")
    if [ "$wiki_links" -gt 0 ]; then
        echo "✅ Found Obsidian wikilinks ($wiki_links)"
    fi
}

# Check for image formatting
check_image_formatting() {
    # Check for image links
    images=$(echo "$CONTENT" | grep -c "!\[.*\](.*)" 2>/dev/null || echo "0")
    
    if [ "$images" -gt 0 ]; then
        echo "✅ Found images ($images)"
        
        # Check for alt text
        images_no_alt=$(echo "$CONTENT" | grep -c "!\[\](.*)" 2>/dev/null || echo "0")
        if [ "$images_no_alt" -gt 0 ]; then
            echo "⚠️  WARNING: Images without alt text ($images_no_alt instances)"
            echo "   Add descriptive alt text: ![Description](image.png)"
        fi
        
        # Check for relative vs absolute paths
        absolute_images=$(echo "$CONTENT" | grep -c "!\[.*\](http" 2>/dev/null || echo "0")
        relative_images=$((images - absolute_images))
        
        if [ "$relative_images" -gt 0 ]; then
            echo "ℹ️  Relative image paths: $relative_images"
            echo "   Ensure images exist in vault or Assets folder"
        fi
    fi
}

# Check document language and structure
check_document_language() {
    # Determine if document is in English or Spanish based on path
    if [[ "$FILE_PATH" =~ /English/ ]]; then
        expected_lang="English"
        echo "📝 Validating English documentation"
        
        # Check for Spanish words that might indicate wrong language
        spanish_indicators=$(echo "$CONTENT" | grep -c -i -E "configuración|simulación|parámetros|análisis" 2>/dev/null || echo "0")
        if [ "$spanish_indicators" -gt 0 ]; then
            echo "⚠️  WARNING: Spanish words detected in English documentation"
            echo "   Ensure content matches the language directory"
        fi
        
    elif [[ "$FILE_PATH" =~ /Spanish/ ]]; then
        expected_lang="Spanish"
        echo "📝 Validating Spanish documentation"
        
        # Check for English words that might indicate wrong language (basic check)
        english_indicators=$(echo "$CONTENT" | grep -c -E "\bthe\b|\band\b|\bor\b|\bof\b|\bin\b|\bto\b|\bfor\b" 2>/dev/null || echo "0")
        if [ "$english_indicators" -gt 5 ]; then  # Allow some English technical terms
            echo "⚠️  WARNING: High number of English words in Spanish documentation"
            echo "   Consider translating more content to Spanish"
        fi
    else
        echo "ℹ️  Language-neutral documentation"
    fi
}

# Run all checks
echo "📄 Validating markdown structure for $FILE_PATH"

check_markdown_structure
check_list_formatting
check_code_blocks
check_table_formatting
check_basic_links
check_image_formatting
check_document_language

echo "✅ Markdown structure validation completed for $FILE_PATH"
exit 0