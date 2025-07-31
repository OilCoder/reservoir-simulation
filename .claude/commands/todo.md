---
allowed-tools: [Bash, Read, Write, Edit]
description: Daily TODO management system with progress tracking
---

# Daily TODO Management

Comprehensive daily task management system integrated with Claude Code workflow.

Arguments: `$ARGUMENTS`
Expected format: `[command] [options]`
Example: `status` or `create` or `dashboard --date 2025-07-31`

Available commands:
- `status`: Show today's TODO status (default)
- `create`: Create new TODO file for today
- `yesterday`: Show yesterday's TODO file
- `dashboard`: Launch interactive TODO dashboard
- `archive`: Archive completed TODO files
- `rollover`: Move pending tasks to today

## Instructions:

1. **Determine command** from arguments
2. **Execute appropriate TODO operation**
3. **Provide clear feedback** on actions taken

### Status Command (Default)
```bash
# Show today's TODO status
python3 .claude/scripts/todo-manager.py status

# Shows:
# - Today's task summary
# - Completion percentage
# - Current focus areas
# - Recent activity
```

### Create Command
```bash
# Create new TODO file for today
python3 .claude/scripts/todo-manager.py create --date $(date +%Y-%m-%d)

# Features:
# - Uses daily template
# - Auto-populates date/timestamp
# - Checks for existing file
# - Creates rollover from yesterday
```

### Yesterday Command
```bash
# Show yesterday's TODO file
python3 .claude/scripts/todo-manager.py show --date $(date -d "yesterday" +%Y-%m-%d)

# Displays:
# - Yesterday's task list
# - Completion summary
# - Unfinished tasks
# - Notes and observations
```

### Dashboard Command
```bash
# Launch interactive TODO dashboard
python3 .claude/scripts/todo-dashboard.py --workspace /workspace

# Features:
# - Real-time task tracking
# - Progress visualization
# - Task editing capabilities
# - Statistics and trends
```

### Archive Command
```bash
# Archive old TODO files
python3 .claude/scripts/todo-manager.py archive --older-than 30

# Actions:
# - Move old files to archive/
# - Compress if needed
# - Update indexes
# - Clean up workspace
```

### Rollover Command
```bash
# Move pending tasks from yesterday to today
python3 .claude/scripts/todo-manager.py rollover

# Process:
# - Identify pending tasks from yesterday
# - Create today's file if needed
# - Transfer incomplete tasks
# - Update task metadata
```

## Command Options:

### Global Options
- `--date YYYY-MM-DD`: Specify target date
- `--format [markdown|json|plain]`: Output format
- `--verbose`: Show detailed information
- `--quiet`: Minimal output only

### Status Options
- `--summary`: Show only summary statistics
- `--details`: Include task details
- `--metrics`: Show productivity metrics

### Create Options
- `--template TEMPLATE`: Use specific template
- `--rollover`: Auto-rollover from yesterday
- `--focus "FOCUS_AREA"`: Set primary focus

### Dashboard Options
- `--auto-refresh N`: Refresh interval in seconds
- `--minimal`: Simplified interface
- `--export FORMAT`: Export data format

## File Structure:

### Daily TODO Files
Location: `/workspace/obsidian-vault/Planning/Todo_Lists/`
Format: `YYYY-MM-DD.md`
Example: `2025-07-31.md`

### Templates
Location: `/workspace/obsidian-vault/Planning/Todo_Lists/templates/`
Files:
- `daily_todo_template.md`: Standard daily template
- `weekly_review_template.md`: Weekly summary template
- `project_todo_template.md`: Project-specific template

### Archive
Location: `/workspace/obsidian-vault/Planning/Todo_Lists/archive/`
Organization: `YYYY/MM/` subdirectories

## Integration Features:

### Claude Code Integration
- Automatic task updates from code generation
- Subagent progress tracking
- Git commit linkage
- Session correlation

### Smart Rollover
- Identifies incomplete tasks
- Preserves task context
- Updates priorities
- Maintains task history

### Progress Tracking
- Real-time completion rates
- Time tracking per task
- Productivity metrics
- Trend analysis

## Task Status Indicators:

| Status | Symbol | Description |
|--------|--------|-------------|
| **Pending** | ⏳ | Task not started |
| **In Progress** | 🔄 | Currently working |
| **Completed** | ✅ | Task finished |
| **Blocked** | 🚫 | Waiting for dependency |
| **Deferred** | 📅 | Moved to future date |

## Automation Features:

### Auto-Creation
- Daily TODO files created automatically
- Template population with current data
- Rollover of incomplete tasks
- Focus area suggestions

### Smart Updates
- Task status changes from code commits
- Progress updates from subagent completions
- Time tracking from session data
- Context linking to development work

### Notifications
- Daily summary notifications
- Completion milestone alerts
- Overdue task warnings
- Weekly productivity reports

## Dashboard Features:

### Overview Tab
- Today's task summary
- Completion progress bar
- Current focus area
- Recent activity timeline

### Tasks Tab
- Filterable task list
- Status change controls
- Time tracking interface
- Priority management

### Analytics Tab
- Productivity trends
- Completion rate charts
- Time allocation graphs
- Focus area analysis

### Settings Tab
- Template customization
- Notification preferences
- Integration settings
- Data export options

## Usage Examples:

```bash
# Check today's status
/todo

# Create new TODO for today
/todo create

# Review yesterday's work
/todo yesterday

# Launch full dashboard
/todo dashboard

# Create TODO with specific focus
/todo create --focus "ML Pipeline Implementation"

# Archive old files
/todo archive --older-than 14

# Manual rollover from specific date
/todo rollover --from 2025-07-30
```

## Best Practices:

### Daily Workflow
1. Start day with `/todo` to see status
2. Use `/todo create` if no file exists
3. Update tasks throughout day
4. End day with `/todo dashboard` review

### Task Management
- Keep tasks specific and actionable
- Use time tracking for accurate metrics
- Regular rollover of incomplete tasks
- Weekly archive of completed work

### Integration Tips
- Link tasks to Git commits
- Reference Claude Code sessions
- Use focus areas for large projects
- Leverage automation for routine updates

The TODO system provides comprehensive task management while integrating seamlessly with your development workflow, ensuring nothing falls through the cracks.