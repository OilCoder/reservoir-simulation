#!/bin/bash
# MultiEdit validation hook - ensures safe multi-edit operations
# Exit codes: 0 = continue, 2 = blocking error

FILE_PATH="$1"
EDITS="$2"  # JSON array of edits

echo "🔍 Validating MultiEdit operation on: $(basename "$FILE_PATH")"

# Check if file exists before multi-edit
if [ ! -f "$FILE_PATH" ]; then
    echo "❌ ERROR: Target file does not exist for MultiEdit"
    exit 2
fi

# Check edit count limit (prevent excessive operations)
edit_count=$(echo "$EDITS" | grep -o '"old_string"' | wc -l)
if [ "$edit_count" -gt 20 ]; then
    echo "❌ ERROR: Too many edits in single MultiEdit operation ($edit_count > 20)"
    echo "Split into smaller operations for safety"
    exit 2
fi

# Check for potentially dangerous patterns in edits
if echo "$EDITS" | grep -E "(rm -rf|sudo|passwd|/etc/)" >/dev/null; then
    echo "❌ ERROR: Potentially dangerous command detected in MultiEdit"
    exit 2
fi

echo "✅ MultiEdit validation passed ($edit_count edits)"
exit 0