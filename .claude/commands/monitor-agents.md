---
allowed-tools: [Bash, Read]
description: Monitor parallel Claude Code agents with real-time dashboard
---

# Monitor Parallel Agents

Launch comprehensive monitoring system for parallel Claude Code agents with multiple display options.

Arguments: `$ARGUMENTS`
Expected format: `[mode] [options]`
Example: `dashboard` or `status` or `continuous --interval 5`

Available modes:
- `dashboard`: Interactive terminal dashboard (default)
- `status`: One-time status report
- `continuous`: Continuous monitoring in terminal
- `conflicts`: Show only conflicts and issues
- `json`: JSON output for programmatic use

## Instructions:

1. **Determine monitoring mode** from arguments
2. **Launch appropriate monitoring interface**
3. **Provide real-time updates** on agent status

### Dashboard Mode (Interactive)
```bash
# Launch full interactive dashboard
python3 .claude/scripts/agent-dashboard.py --workspace /workspace

# Features:
# - Tab-based interface (Overview, Agents, Resources, Conflicts, Logs)
# - Real-time updates every 2 seconds
# - Color-coded status indicators
# - Progress bars for active tasks
# - Keyboard navigation (Tab, Q, ↑↓)
```

### Status Mode (One-time)
```bash
# Get current status snapshot
python3 .claude/scripts/agent-coordinator.py status --workspace /workspace

# Shows:
# - All registered agents
# - Current tasks and progress
# - Resource locks
# - Summary statistics
```

### Continuous Mode (Live Feed)
```bash
# Continuous monitoring output
python3 .claude/scripts/agent-coordinator.py monitor --workspace /workspace

# Real-time feed showing:
# - Agent status changes
# - Lock acquisitions/releases
# - Progress updates
# - Error notifications
```

### Conflicts Mode (Issues Only)
```bash
# Show only conflicts and problems
python3 .claude/scripts/agent-coordinator.py conflicts --workspace /workspace

# Displays:
# - File conflicts between agents
# - Stale resource locks
# - Unresponsive agents
# - System errors
```

## Dashboard Features:

### Overview Tab
- **System Summary**: Total agents, active count, resource locks
- **Agent Status Breakdown**: Count by status (working, idle, failed, etc.)
- **Recent Activity**: Current tasks and progress bars
- **Performance Metrics**: CPU, memory usage (if available)

### Agents Tab
- **Detailed Agent List**: ID, type, status, current task, progress
- **Agent Selection**: Click/select for detailed view
- **Filtering Options**: By status, type, worktree
- **Sort Options**: By name, status, progress, start time

### Resources Tab
- **Active Locks**: Resource path, locked by, lock type, duration
- **Lock History**: Recent lock acquisitions and releases
- **Conflict Detection**: Potential lock conflicts
- **Resource Usage**: File system, memory, network

### Conflicts Tab
- **File Conflicts**: Multiple agents working on same files
- **Stale Locks**: Long-held resource locks
- **Unresponsive Agents**: Agents that haven't reported in
- **Integration Issues**: Merge conflicts, dependency issues

### Logs Tab
- **Real-time Log Feed**: Latest coordination events
- **Log Filtering**: By level (INFO, WARNING, ERROR)
- **Search Functionality**: Find specific events
- **Export Options**: Save logs to file

## Keyboard Controls:

| Key | Action |
|-----|--------|
| `Tab` / `→` | Next tab |
| `Shift+Tab` / `←` | Previous tab |
| `↑` / `↓` | Scroll content |
| `Enter` | Select/toggle item |
| `r` / `R` | Force refresh |
| `q` / `Q` | Quit dashboard |
| `h` / `?` | Help |

## Status Indicators:

| Status | Color | Description |
|--------|-------|-------------|
| **WORKING** | 🟢 Green | Agent actively processing |
| **IDLE** | 🔵 Blue | Agent waiting for tasks |
| **BLOCKED** | 🟡 Yellow | Agent waiting for resource |
| **COMPLETED** | 🟢 Green | Task completed successfully |
| **FAILED** | 🔴 Red | Agent encountered error |

## Progress Visualization:

```
Agent: authentication-reviewer
Task: Reviewing security patterns in src/auth/
Progress: [██████████░░░░░░░░░░] 50.0%
Started: 2024-01-15 14:30:25
ETA: ~3 minutes remaining
```

## Integration with Worktrees:

The monitoring system automatically detects:
- Active git worktrees
- Claude Code processes in each worktree
- File modifications and conflicts
- Branch status and sync state

## Alerts and Notifications:

### High Priority Alerts
- 🚨 **Agent Crash**: Agent process terminated unexpectedly
- 🚨 **Merge Conflict**: Conflicting changes detected
- 🚨 **Resource Deadlock**: Circular lock dependency

### Medium Priority Warnings
- ⚠️ **Stale Lock**: Resource locked for >1 hour
- ⚠️ **Slow Progress**: Agent showing no progress for >10 minutes
- ⚠️ **Memory Usage**: High memory consumption detected

### Info Notifications
- ℹ️ **Agent Started**: New agent registered
- ℹ️ **Task Completed**: Agent finished assigned task
- ℹ️ **Lock Released**: Resource became available

## Command Line Usage:

```bash
# Quick status check
/monitor-agents status

# Launch interactive dashboard
/monitor-agents dashboard

# Continuous monitoring with custom interval
/monitor-agents continuous --interval 10

# Check for conflicts only
/monitor-agents conflicts

# JSON output for scripting
/monitor-agents json | jq '.summary'
```

## Troubleshooting:

### Dashboard Won't Start
- Check Python 3.6+ is installed
- Verify curses library is available
- Ensure terminal supports color

### No Agents Detected
- Verify Claude Code processes are running
- Check .claude/agent-state.json exists
- Ensure proper workspace path

### Performance Issues
- Reduce update interval: `--interval 5`
- Close unused tabs in dashboard
- Monitor system resources

## Advanced Features:

### Remote Monitoring
```bash
# Monitor agents on remote workspace
/monitor-agents dashboard --workspace /path/to/remote/workspace
```

### Integration with CI/CD
```bash
# Check if all tests pass before deploy
if /monitor-agents json | jq -r '.conflicts | length' == "0"; then
    echo "All agents healthy, proceeding with deployment"
else
    echo "Conflicts detected, aborting deployment"
    exit 1
fi
```

### Custom Alerts
```bash
# Set up custom alert when specific agent fails
/monitor-agents continuous | grep "FAILED.*security-agent" | \
    while read line; do
        echo "Security agent failed: $line" | mail admin@company.com
    done
```

The monitoring system provides complete visibility into your parallel development workflow, helping you coordinate multiple agents effectively while maintaining code quality and avoiding conflicts.