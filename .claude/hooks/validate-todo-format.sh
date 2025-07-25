#!/bin/bash
# TodoWrite validation hook - ensures proper todo formatting
# Exit codes: 0 = continue, 2 = blocking error

TODOS_JSON="$1"

echo "🔍 Validating TodoWrite operation"

# Check if todos JSON is valid
if ! echo "$TODOS_JSON" | python3 -m json.tool >/dev/null 2>&1; then
    echo "❌ ERROR: Invalid JSON format in TodoWrite"
    exit 2
fi

# Count todos (reasonable limit)
todo_count=$(echo "$TODOS_JSON" | grep -o '"id"' | wc -l)
if [ "$todo_count" -gt 50 ]; then
    echo "❌ ERROR: Too many todos ($todo_count > 50)"
    echo "Consider breaking down into smaller task groups"
    exit 2
fi

# Check for required fields in each todo
required_fields=("content" "status" "priority" "id")
for field in "${required_fields[@]}"; do
    if ! echo "$TODOS_JSON" | grep -q "\"$field\""; then
        echo "❌ ERROR: Missing required field: $field"
        exit 2
    fi
done

# Validate status values
invalid_status=$(echo "$TODOS_JSON" | grep -o '"status":"[^"]*"' | grep -v -E '"status":"(pending|in_progress|completed)"')
if [ -n "$invalid_status" ]; then
    echo "❌ ERROR: Invalid status value found: $invalid_status"
    echo "Valid statuses: pending, in_progress, completed"
    exit 2
fi

echo "✅ TodoWrite validation passed ($todo_count todos)"
exit 0