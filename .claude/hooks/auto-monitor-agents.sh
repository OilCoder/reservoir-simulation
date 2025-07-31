#!/bin/bash
# Auto-monitor agents hook - automatically launches agent dashboard for complex tasks
# This hook activates when Task tool is used with subagent orchestration

DESCRIPTION="$1"
PROMPT="$2"

# Configuration
DASHBOARD_SCRIPT="/workspace/.claude/scripts/agent-dashboard.py"
COORDINATOR_SCRIPT="/workspace/.claude/scripts/agent-coordinator.py"
LOG_FILE="/workspace/.claude/logs/auto-monitor.log"
PID_FILE="/workspace/.claude/logs/monitor-dashboard.pid"

# Ensure log directory exists
mkdir -p "$(dirname "$LOG_FILE")"

# Function to log messages
log_message() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
}

# Function to check if dashboard is already running
is_dashboard_running() {
    if [ -f "$PID_FILE" ]; then
        local pid=$(cat "$PID_FILE")
        if ps -p "$pid" > /dev/null 2>&1; then
            return 0  # Dashboard is running
        else
            rm -f "$PID_FILE"  # Clean up stale PID file
        fi
    fi
    return 1  # Dashboard not running
}

# Function to detect complex task patterns
is_complex_task() {
    local desc="$1"
    local prompt="$2"
    
    # Keywords that indicate subagent usage
    local complex_keywords=(
        "parallel"
        "multiple.*agents"
        "subagent"
        "orchestrat"
        "complex.*task"
        "implement.*complete"
        "create.*system"
        "full.*implementation"
        "end-to-end"
        "comprehensive"
        "multiple.*files"
        "analyze.*and.*implement"
        "review.*and.*fix"
        "test.*and.*validate"
    )
    
    # Check description and prompt for complex task indicators
    local combined_text="${desc,,} ${prompt,,}"  # Convert to lowercase
    
    for keyword in "${complex_keywords[@]}"; do
        if echo "$combined_text" | grep -E "$keyword" > /dev/null; then
            log_message "Complex task detected: keyword '$keyword' found"
            return 0
        fi
    done
    
    # Check for multiple action verbs (indicates complex workflow)
    local action_count=0
    local actions=("implement" "create" "analyze" "test" "validate" "review" "fix" "update" "modify")
    
    for action in "${actions[@]}"; do
        if echo "$combined_text" | grep -w "$action" > /dev/null; then
            ((action_count++))
        fi
    done
    
    if [ $action_count -ge 3 ]; then
        log_message "Complex task detected: multiple actions ($action_count) found"
        return 0
    fi
    
    # Check prompt length (long prompts often indicate complexity)
    if [ ${#combined_text} -gt 200 ]; then
        log_message "Complex task detected: long prompt (${#combined_text} chars)"
        return 0
    fi
    
    return 1
}

# Function to launch dashboard in background
launch_dashboard() {
    log_message "Launching agent dashboard in background"
    
    # Check if dashboard script exists
    if [ ! -f "$DASHBOARD_SCRIPT" ]; then
        log_message "ERROR: Dashboard script not found at $DASHBOARD_SCRIPT"
        return 1
    fi
    
    # Launch dashboard in background with nohup
    nohup python3 "$DASHBOARD_SCRIPT" --workspace /workspace --auto-launched > /dev/null 2>&1 &
    local dashboard_pid=$!
    
    # Save PID for later reference
    echo "$dashboard_pid" > "$PID_FILE"
    
    log_message "Dashboard launched with PID: $dashboard_pid"
    
    # Display user notification
    echo "🔍 Auto-Monitor: Agent dashboard launched in background (PID: $dashboard_pid)"
    echo "   Access dashboard: /monitor-agents dashboard"
    echo "   Stop monitoring: kill $dashboard_pid"
    
    return 0
}

# Function to check configuration
is_auto_monitor_enabled() {
    local config_file="/workspace/.claude/settings.local.json"
    
    if [ -f "$config_file" ]; then
        # Check if auto-monitor is explicitly disabled
        if python3 -c "
import json
try:
    with open('$config_file', 'r') as f:
        config = json.load(f)
    auto_monitor = config.get('auto_monitor', {})
    enabled = auto_monitor.get('enabled', True)  # Default to enabled
    print('true' if enabled else 'false')
except:
    print('true')  # Default to enabled if config is malformed
" | grep -q "false"; then
            return 1
        fi
    fi
    
    return 0  # Default to enabled
}

# Main logic
main() {
    log_message "Auto-monitor hook triggered"
    log_message "Description: $DESCRIPTION"
    log_message "Prompt length: ${#PROMPT} chars"
    
    # Check if auto-monitor is enabled
    if ! is_auto_monitor_enabled; then
        log_message "Auto-monitor disabled in configuration"
        exit 0
    fi
    
    # Check if dashboard is already running
    if is_dashboard_running; then
        log_message "Dashboard already running, skipping auto-launch"
        exit 0
    fi
    
    # Check if this is a complex task
    if is_complex_task "$DESCRIPTION" "$PROMPT"; then
        log_message "Complex task detected, launching dashboard"
        if launch_dashboard; then
            log_message "Dashboard launched successfully"
        else
            log_message "Failed to launch dashboard"
        fi
    else
        log_message "Simple task detected, no dashboard needed"
    fi
    
    exit 0
}

# Run main function
main "$@"