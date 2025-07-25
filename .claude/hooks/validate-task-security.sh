#!/bin/bash
# Task validation hook - ensures safe task agent operations
# Exit codes: 0 = continue, 2 = blocking error

TASK_DESCRIPTION="$1"
TASK_PROMPT="$2"

echo "🔍 Validating Task agent operation"

# Check for potentially dangerous task patterns
dangerous_patterns=(
    "rm -rf"
    "sudo"
    "passwd"
    "chmod 777"
    "wget.*http"
    "curl.*http"
    "format.*disk"
    "delete.*database"
)

for pattern in "${dangerous_patterns[@]}"; do
    if echo "$TASK_PROMPT" | grep -iE "$pattern" >/dev/null; then
        echo "❌ ERROR: Potentially dangerous pattern detected: '$pattern'"
        echo "Task operations must be safe and non-destructive"
        exit 2
    fi
done

# Check task scope (should be code-related)
safe_patterns=(
    "search"
    "analyze"
    "find"
    "read"
    "review"
    "validate"
    "test"
    "debug"
    "implement"
    "refactor"
)

is_safe=false
for pattern in "${safe_patterns[@]}"; do
    if echo "$TASK_DESCRIPTION" | grep -iE "$pattern" >/dev/null; then
        is_safe=true
        break
    fi
done

if [ "$is_safe" = false ]; then
    echo "⚠️  WARNING: Task scope unclear - ensure it's code/development related"
fi

echo "✅ Task validation passed"
exit 0