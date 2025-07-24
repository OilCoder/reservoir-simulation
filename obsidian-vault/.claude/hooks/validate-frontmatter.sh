#!/bin/bash
# Frontmatter validation hook for obsidian-vault/ directory
# Validates YAML frontmatter and metadata

FILE_PATH="$1"

# Exit codes:
# 0 - Success (continue)
# 2 - Blocking error (stop operation)

# Only validate markdown files
if [[ ! "$FILE_PATH" =~ \.md$ ]]; then
    exit 0
fi

if [ ! -f "$FILE_PATH" ]; then
    exit 0
fi

# Check for YAML frontmatter
check_frontmatter_structure() {
    # Check if file starts with YAML frontmatter (---)
    first_line=$(head -1 "$FILE_PATH")
    
    if [ "$first_line" = "---" ]; then
        echo "✅ Found YAML frontmatter"
        
        # Find the closing ---
        closing_line=$(tail -n +2 "$FILE_PATH" | grep -n "^---$" | head -1 | cut -d: -f1)
        
        if [ -n "$closing_line" ]; then
            # Adjust line number (add 1 for the first line we skipped)
            closing_line=$((closing_line + 1))
            echo "✅ Frontmatter properly closed at line $closing_line"
            
            # Extract frontmatter content
            frontmatter=$(sed -n "2,${closing_line}p" "$FILE_PATH" | head -n -1)
            
            # Validate YAML syntax (basic check)
            if echo "$frontmatter" | grep -E "^[a-zA-Z_][a-zA-Z0-9_]*:" > /dev/null; then
                echo "✅ Frontmatter has valid YAML structure"
            else
                echo "⚠️  WARNING: Frontmatter may have invalid YAML syntax"
            fi
            
            return 0
        else
            echo "🚫 ERROR: Frontmatter opening --- without closing ---"
            exit 2
        fi
    else
        echo "ℹ️  No YAML frontmatter found"
        
        # Check if document could benefit from frontmatter
        filename=$(basename "$FILE_PATH")
        
        # Suggest frontmatter for certain file types
        if [[ "$filename" =~ ^[0-9]{2}_ ]]; then
            echo "ℹ️  Numbered document could benefit from frontmatter:"
            echo "   ---"
            echo "   title: \"Document Title\""
            echo "   date: $(date +%Y-%m-%d)"
            echo "   tags: [documentation]"
            echo "   ---"
        fi
        
        return 1
    fi
}

# Validate frontmatter content
validate_frontmatter_content() {
    # Only run if frontmatter exists
    first_line=$(head -1 "$FILE_PATH")
    if [ "$first_line" != "---" ]; then
        return 0
    fi
    
    # Extract frontmatter
    closing_line=$(tail -n +2 "$FILE_PATH" | grep -n "^---$" | head -1 | cut -d: -f1)
    if [ -z "$closing_line" ]; then
        return 0
    fi
    
    closing_line=$((closing_line + 1))
    frontmatter=$(sed -n "2,${closing_line}p" "$FILE_PATH" | head -n -1)
    
    # Check for common fields
    echo "🔍 Validating frontmatter fields..."
    
    # Title field
    if echo "$frontmatter" | grep -q "^title:"; then
        title=$(echo "$frontmatter" | grep "^title:" | sed 's/title:[[:space:]]*//' | sed 's/^["'"'"']\|["'"'"']$//g')
        if [ -n "$title" ]; then
            echo "✅ Title: $title"
        else
            echo "⚠️  WARNING: Empty title field"
        fi
    else
        echo "ℹ️  Consider adding title field"
    fi
    
    # Date field
    if echo "$frontmatter" | grep -q "^date:"; then
        date_value=$(echo "$frontmatter" | grep "^date:" | sed 's/date:[[:space:]]*//')
        
        # Basic date format validation
        if echo "$date_value" | grep -E "^[0-9]{4}-[0-9]{2}-[0-9]{2}" > /dev/null; then
            echo "✅ Date: $date_value"
        else
            echo "⚠️  WARNING: Date format should be YYYY-MM-DD"
            echo "   Current: $date_value"
        fi
    else
        echo "ℹ️  Consider adding date field (YYYY-MM-DD format)"
    fi
    
    # Tags field
    if echo "$frontmatter" | grep -q "^tags:"; then
        tags_line=$(echo "$frontmatter" | grep "^tags:")
        
        # Check tag format
        if echo "$tags_line" | grep -E "\[.*\]" > /dev/null; then
            tags=$(echo "$tags_line" | sed 's/tags:[[:space:]]*//' | sed 's/\[//' | sed 's/\]//' | tr ',' '\n' | sed 's/^[[:space:]]*//' | sed 's/[[:space:]]*$//')
            tag_count=$(echo "$tags" | wc -l)
            echo "✅ Tags ($tag_count): $tags_line"
            
            # Validate individual tags
            echo "$tags" | while read -r tag; do
                clean_tag=$(echo "$tag" | sed 's/^["'"'"']\|["'"'"']$//g')
                if [[ "$clean_tag" =~ ^[a-zA-Z0-9_-]+$ ]]; then
                    echo "  ✅ Valid tag: $clean_tag"
                else
                    echo "  ⚠️  Tag may contain invalid characters: $clean_tag"
                fi
            done
        else
            echo "⚠️  WARNING: Tags should use array format: [tag1, tag2]"
        fi
    else
        echo "ℹ️  Consider adding tags field: [documentation, guide]"
    fi
    
    # Author field
    if echo "$frontmatter" | grep -q "^author:"; then
        author=$(echo "$frontmatter" | grep "^author:" | sed 's/author:[[:space:]]*//' | sed 's/^["'"'"']\|["'"'"']$//g')
        echo "✅ Author: $author"
    fi
    
    # Category/type field
    if echo "$frontmatter" | grep -q "^category:\|^type:"; then
        category=$(echo "$frontmatter" | grep -E "^(category|type):" | sed 's/.*:[[:space:]]*//' | sed 's/^["'"'"']\|["'"'"']$//g')
        echo "✅ Category/Type: $category"
    fi
    
    # Description field
    if echo "$frontmatter" | grep -q "^description:"; then
        description=$(echo "$frontmatter" | grep "^description:" | sed 's/description:[[:space:]]*//' | sed 's/^["'"'"']\|["'"'"']$//g')
        if [ ${#description} -lt 10 ]; then
            echo "⚠️  WARNING: Description is very short"
        else
            echo "✅ Description: ${description:0:50}..."
        fi
    else
        echo "ℹ️  Consider adding description field"
    fi
}

# Check for Obsidian-specific frontmatter
check_obsidian_specific() {
    first_line=$(head -1 "$FILE_PATH")
    if [ "$first_line" != "---" ]; then
        return 0
    fi
    
    closing_line=$(tail -n +2 "$FILE_PATH" | grep -n "^---$" | head -1 | cut -d: -f1)
    if [ -z "$closing_line" ]; then
        return 0
    fi
    
    closing_line=$((closing_line + 1))
    frontmatter=$(sed -n "2,${closing_line}p" "$FILE_PATH" | head -n -1)
    
    echo "🔍 Checking Obsidian-specific fields..."
    
    # Aliases
    if echo "$frontmatter" | grep -q "^aliases:"; then
        aliases=$(echo "$frontmatter" | grep "^aliases:" | sed 's/aliases:[[:space:]]*//')
        echo "✅ Aliases: $aliases"
    fi
    
    # CSS classes
    if echo "$frontmatter" | grep -q "^cssclass:"; then
        cssclass=$(echo "$frontmatter" | grep "^cssclass:" | sed 's/cssclass:[[:space:]]*//')
        echo "✅ CSS class: $cssclass"
    fi
    
    # Publish settings
    if echo "$frontmatter" | grep -q "^publish:"; then
        publish=$(echo "$frontmatter" | grep "^publish:" | sed 's/publish:[[:space:]]*//')
        echo "✅ Publish setting: $publish"
    fi
    
    # Template fields
    if echo "$frontmatter" | grep -q "^template:"; then
        template=$(echo "$frontmatter" | grep "^template:" | sed 's/template:[[:space:]]*//')
        echo "✅ Template: $template"
    fi
    
    # MOCs (Maps of Content)
    if echo "$frontmatter" | grep -q "^moc:"; then
        moc=$(echo "$frontmatter" | grep "^moc:" | sed 's/moc:[[:space:]]*//')
        echo "✅ MOC: $moc"
    fi
}

# Check consistency with file location
check_location_consistency() {
    filename=$(basename "$FILE_PATH")
    
    # Check if frontmatter matches file location
    if [[ "$FILE_PATH" =~ /English/ ]]; then
        echo "📍 File in English directory"
        
        # Check for language specification in frontmatter
        if [ -f "$FILE_PATH" ] && head -10 "$FILE_PATH" | grep -q "lang.*en\|language.*english"; then
            echo "✅ Language metadata matches directory"
        fi
        
    elif [[ "$FILE_PATH" =~ /Spanish/ ]]; then
        echo "📍 File in Spanish directory"
        
        # Check for language specification in frontmatter
        if [ -f "$FILE_PATH" ] && head -10 "$FILE_PATH" | grep -q "lang.*es\|language.*spanish\|idioma.*español"; then
            echo "✅ Language metadata matches directory"
        fi
        
    elif [[ "$FILE_PATH" =~ /Templates/ ]]; then
        echo "📍 File in Templates directory"
        
        # Check for template-specific frontmatter
        if [ -f "$FILE_PATH" ] && head -10 "$FILE_PATH" | grep -q "template.*true\|type.*template"; then
            echo "✅ Template metadata found"
        else
            echo "ℹ️  Consider adding template metadata"
        fi
    fi
    
    # Check if numbered file has appropriate frontmatter
    if [[ "$filename" =~ ^[0-9]{2}_ ]]; then
        number=$(echo "$filename" | sed 's/^\([0-9][0-9]\)_.*/\1/')
        echo "📍 Numbered document: $number"
        
        if [ -f "$FILE_PATH" ] && head -10 "$FILE_PATH" | grep -q "order.*$number\|sequence.*$number"; then
            echo "✅ Order metadata matches filename"
        else
            echo "ℹ️  Consider adding order: $number to frontmatter"
        fi
    fi
}

# Run all checks
echo "📋 Validating frontmatter for $FILE_PATH"

if check_frontmatter_structure; then
    validate_frontmatter_content
    check_obsidian_specific
fi

check_location_consistency

echo "✅ Frontmatter validation completed for $FILE_PATH"
exit 0