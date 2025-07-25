#!/bin/bash
# Bash validation hook - ensures safe bash command execution
# Exit codes: 0 = continue, 2 = blocking error

BASH_COMMAND="$1"

echo "🔍 Validating Bash command: $(echo "$BASH_COMMAND" | cut -c1-50)..."

# Highly dangerous commands (always blocked)
dangerous_commands=(
    "rm -rf /"
    "mkfs"
    "fdisk" 
    "format"
    "dd if="
    ":(){ :|:& };:"
    "sudo rm"
    "chmod -R 777"
    "chown -R"
    "passwd"
    "userdel"
    "groupdel"
)

for cmd in "${dangerous_commands[@]}"; do
    if echo "$BASH_COMMAND" | grep -F "$cmd" >/dev/null; then
        echo "❌ ERROR: Dangerous command blocked: '$cmd'"
        exit 2
    fi
done

# Check for suspicious patterns
suspicious_patterns=(
    "wget.*http"
    "curl.*-o.*/"
    "eval.*\$"
    "exec.*\$"
    ">/dev/null.*2>&1.*&"
    "\|\|.*rm"
)

for pattern in "${suspicious_patterns[@]}"; do
    if echo "$BASH_COMMAND" | grep -E "$pattern" >/dev/null; then
        echo "⚠️  WARNING: Suspicious pattern detected: matches '$pattern'"
        echo "Command: $BASH_COMMAND"
        echo "Ensure this is safe before proceeding"
    fi
done

# Check command length (prevent overly complex commands)
if [ ${#BASH_COMMAND} -gt 1000 ]; then
    echo "❌ ERROR: Command too long (${#BASH_COMMAND} > 1000 chars)"
    echo "Break into smaller commands for safety"
    exit 2
fi

echo "✅ Bash command validation passed"
exit 0