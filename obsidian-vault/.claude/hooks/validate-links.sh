#!/bin/bash
# Link validation hook for obsidian-vault/ directory
# Validates internal links and cross-references

FILE_PATH="$1"
CONTENT="$2"

# Exit codes:
# 0 - Success (continue)
# 2 - Blocking error (stop operation)

# Only validate markdown files
if [[ ! "$FILE_PATH" =~ \.md$ ]]; then
    exit 0
fi

# Check internal wikilinks
check_wikilinks() {
    # Extract Obsidian-style wikilinks [[filename]]
    wikilinks=$(echo "$CONTENT" | grep -o "\[\[[^\]]*\]\]" 2>/dev/null || true)
    
    if [ -n "$wikilinks" ]; then
        echo "🔗 Validating Obsidian wikilinks..."
        
        valid_links=0
        invalid_links=0
        
        echo "$wikilinks" | while read -r link; do
            # Extract filename from [[filename]]
            filename=$(echo "$link" | sed 's/\[\[\([^\]]*\)\]\]/\1/')
            
            # Handle links with display text [[filename|display]]
            if [[ "$filename" =~ \| ]]; then
                filename=$(echo "$filename" | cut -d'|' -f1)
            fi
            
            # Look for the file in obsidian-vault
            vault_dir="/workspace/obsidian-vault"
            
            # Try different extensions and locations
            found=false
            
            # Check exact filename
            if [ -f "$vault_dir/$filename.md" ]; then
                found=true
            # Check in English directory
            elif [ -f "$vault_dir/English/$filename.md" ]; then
                found=true
            # Check in Spanish directory
            elif [ -f "$vault_dir/Spanish/$filename.md" ]; then
                found=true
            # Check in Templates directory
            elif [ -f "$vault_dir/Templates/$filename.md" ]; then
                found=true
            # Search recursively (slower but thorough)
            elif find "$vault_dir" -name "$filename.md" -type f | head -1 | grep -q .; then
                found=true
            fi
            
            if [ "$found" = true ]; then
                valid_links=$((valid_links + 1))
                echo "✅ Valid wikilink: $link"
            else
                invalid_links=$((invalid_links + 1))
                echo "⚠️  WARNING: Broken wikilink: $link"
                echo "   Target file '$filename.md' not found in vault"
            fi
        done
        
        echo "📊 Wikilinks summary: $valid_links valid, $invalid_links broken"
        
    fi
}

# Check markdown links
check_markdown_links() {
    # Extract markdown-style links [text](url)
    markdown_links=$(echo "$CONTENT" | grep -o "\[^[]*\]([^)]*)" 2>/dev/null || true)
    
    if [ -n "$markdown_links" ]; then
        echo "🔗 Validating markdown links..."
        
        valid_links=0
        external_links=0
        broken_links=0
        
        echo "$markdown_links" | while read -r link; do
            # Extract URL from [text](url)
            url=$(echo "$link" | sed 's/.*](\([^)]*\)).*/\1/')
            text=$(echo "$link" | sed 's/\[\([^\]]*\)\].*/\1/')
            
            if [[ "$url" =~ ^https?:// ]]; then
                # External link - can't validate easily, just count
                external_links=$((external_links + 1))
                echo "🌐 External link: $text -> $url"
                
            elif [[ "$url" =~ ^/ ]]; then
                # Absolute path - check if file exists
                if [ -f "$url" ]; then
                    valid_links=$((valid_links + 1))
                    echo "✅ Valid absolute link: $link"
                else
                    broken_links=$((broken_links + 1))
                    echo "⚠️  WARNING: Broken absolute link: $link"
                fi
                
            elif [[ "$url" =~ ^\. ]]; then
                # Relative path - check relative to current file
                current_dir=$(dirname "$FILE_PATH")
                target_path="$current_dir/$url"
                
                if [ -f "$target_path" ]; then
                    valid_links=$((valid_links + 1))
                    echo "✅ Valid relative link: $link"
                else
                    broken_links=$((broken_links + 1))
                    echo "⚠️  WARNING: Broken relative link: $link"
                    echo "   Target path: $target_path"
                fi
                
            elif [[ "$url" =~ ^[a-zA-Z0-9] ]]; then
                # Relative filename - check in current directory and vault
                current_dir=$(dirname "$FILE_PATH")
                vault_dir="/workspace/obsidian-vault"
                
                found=false
                
                # Check in current directory
                if [ -f "$current_dir/$url" ]; then
                    found=true
                # Check in vault root
                elif [ -f "$vault_dir/$url" ]; then
                    found=true
                # Check in same language directory
                elif [[ "$FILE_PATH" =~ /English/ ]] && [ -f "$vault_dir/English/$url" ]; then
                    found=true
                elif [[ "$FILE_PATH" =~ /Spanish/ ]] && [ -f "$vault_dir/Spanish/$url" ]; then
                    found=true
                fi
                
                if [ "$found" = true ]; then
                    valid_links=$((valid_links + 1))
                    echo "✅ Valid relative link: $link"
                else
                    broken_links=$((broken_links + 1))
                    echo "⚠️  WARNING: Broken relative link: $link"
                fi
                
            else
                # Other types (anchors, etc.)
                echo "ℹ️  Other link type: $link"
            fi
        done
        
        echo "📊 Markdown links summary: $valid_links valid, $external_links external, $broken_links broken"
        
    fi
}

# Check for cross-references between languages
check_cross_references() {
    # Check if this is a translated document
    current_lang=""
    other_lang=""
    
    if [[ "$FILE_PATH" =~ /English/ ]]; then
        current_lang="English"
        other_lang="Spanish"
    elif [[ "$FILE_PATH" =~ /Spanish/ ]]; then
        current_lang="Spanish"  
        other_lang="English"
    else
        return
    fi
    
    # Get filename without path
    filename=$(basename "$FILE_PATH")
    
    # Check if corresponding file exists in other language
    if [[ "$FILE_PATH" =~ /English/ ]]; then
        other_file="/workspace/obsidian-vault/Spanish/$filename"
    else
        other_file="/workspace/obsidian-vault/English/$filename"
    fi
    
    if [ -f "$other_file" ]; then
        echo "✅ Cross-language document pair exists: $current_lang ↔ $other_lang"
        
        # Check for translation links
        if echo "$CONTENT" | grep -i "$other_lang" > /dev/null; then
            echo "✅ References to $other_lang version found"
        else
            echo "ℹ️  Consider adding link to $other_lang version"
        fi
    else
        echo "ℹ️  No corresponding $other_lang document found"
        echo "   Consider creating: $other_file"
    fi
}

# Check for reference consistency
check_reference_consistency() {
    # Look for footnote-style references [^1]
    footnotes=$(echo "$CONTENT" | grep -o "\[\^[^\]]*\]" 2>/dev/null || true)
    
    if [ -n "$footnotes" ]; then
        echo "📝 Found footnote references"
        
        # Extract reference IDs
        ref_ids=$(echo "$footnotes" | sed 's/\[\^\([^\]]*\)\]/\1/g' | sort -u)
        
        # Check for corresponding definitions
        echo "$ref_ids" | while read -r ref_id; do
            if echo "$CONTENT" | grep -q "^\[\^$ref_id\]:"; then
                echo "✅ Footnote reference [$ref_id] has definition"
            else
                echo "⚠️  WARNING: Footnote reference [$ref_id] missing definition"
                echo "   Add: [^$ref_id]: Your footnote text here"
            fi
        done
    fi
    
    # Look for reference-style links [link text][ref]
    ref_links=$(echo "$CONTENT" | grep -o "\[[^\]]*\]\[[^\]]*\]" 2>/dev/null || true)
    
    if [ -n "$ref_links" ]; then
        echo "📝 Found reference-style links"
        
        # Extract reference IDs
        ref_ids=$(echo "$ref_links" | sed 's/.*\]\[\([^\]]*\)\]/\1/g' | sort -u)
        
        # Check for corresponding definitions
        echo "$ref_ids" | while read -r ref_id; do
            if echo "$CONTENT" | grep -q "^\[$ref_id\]:"; then
                echo "✅ Reference link [$ref_id] has definition"
            else
                echo "⚠️  WARNING: Reference link [$ref_id] missing definition"
                echo "   Add: [$ref_id]: https://example.com"
            fi
        done
    fi
}

# Check for heading anchors and internal links
check_heading_anchors() {
    # Extract headings for potential anchor targets
    headings=$(echo "$CONTENT" | grep "^#" 2>/dev/null || true)
    
    if [ -n "$headings" ]; then
        # Look for links to headings (#anchor)
        anchor_links=$(echo "$CONTENT" | grep -o "](#[^)]*)" 2>/dev/null || true)
        
        if [ -n "$anchor_links" ]; then
            echo "🔗 Found heading anchor links"
            
            # Extract anchor names
            anchors=$(echo "$anchor_links" | sed 's/](#\([^)]*\))/\1/g')
            
            echo "$anchors" | while read -r anchor; do
                # Convert anchor to heading format (basic conversion)
                heading_text=$(echo "$anchor" | tr '-' ' ' | tr '[:lower:]' '[:upper:]')
                
                if echo "$headings" | grep -i "$heading_text" > /dev/null; then
                    echo "✅ Valid heading anchor: #$anchor"
                else
                    echo "⚠️  WARNING: Heading anchor may be invalid: #$anchor"
                    echo "   Verify heading exists with similar text"
                fi
            done
        fi
    fi
}

# Run all checks
echo "🔗 Validating links for $FILE_PATH"

check_wikilinks
check_markdown_links
check_cross_references
check_reference_consistency
check_heading_anchors

echo "✅ Link validation completed for $FILE_PATH"
exit 0