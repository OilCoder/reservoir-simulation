# Claude Code System Optimization - Usage Guide

## 🚀 System Overview
This system has been optimized to maximize prompt efficiency and minimize token usage:

**Target**: ~180-200 prompts per 5-hour window (vs previous ~50)

## ⚙️ Key Optimizations Applied

### 1. Router-Based Agent Selection
- **Single agent by default**: `coder` handles most tasks
- **Specialized agents on-demand**: `tester`/`debugger` only when keywords detected
- **Budget awareness**: Conservative mode when <25 prompts remaining

### 2. Minimal Context Injection
- **Git diff hunks only**: ±30 lines context, max 20k chars
- **No full files**: Router shows file names, not content
- **Compact directives**: "Return only unified diff + title"

### 3. Consolidated Rules
- **8 rules → 1 cheatsheet**: All coding guidelines in 400 words
- **MCP servers reduced**: Only filesystem by default
- **Parallel execution disabled**: No automatic double consumption

## 🔧 Usage Patterns

### For Maximum Efficiency
```bash
# Good: Batch multiple changes
"Fix validation in user_auth.py, add error handling to api_client.py, and update tests"

# Better: Be specific about scope  
"Fix only the password validation function in user_auth.py line 45"

# Best: Use router keywords for specialized tasks
"Run tests for the authentication module"  # → tester agent
"Debug the connection timeout issue"       # → debugger agent
```

### Budget Management
- Router automatically tracks remaining prompts
- Switches to conservative mode at 25 prompts
- Only `coder` agent activated when budget is low

### Auto-Accept Configuration
To enable auto-accept and avoid manual confirmations:
1. Check your Claude Code settings
2. Enable "Auto-apply changes" if available
3. Or use the `--accept` flag when running Claude Code

## 📋 Pre-commit Setup (Recommended)
```bash
# Install pre-commit hooks to avoid formatting prompts
pip install pre-commit ruff black isort
pre-commit install

# This will auto-format code before commits, saving prompts on style fixes
```

## 🔍 Monitoring Performance

### Router Output
The router now provides diagnostic info:
```json
{
  "agent": "coder",
  "routingReason": "default", 
  "budgetRemaining": 150
}
```

### Expected Improvements
- **Token usage**: ~70% reduction (minimal context + compact rules)  
- **Agent overhead**: ~50% reduction (single agent vs parallel)
- **Confirmation prompts**: ~30% reduction (auto-accept + batching)

## 🚨 Troubleshooting

### If Router Fails
Router fails gracefully - Claude Code continues with default behavior.

### If Budget Tracking Unavailable  
Set environment variable: `export CLAUDE_REMAINING_PROMPTS=200`

### If You Need Old Functionality
Temporarily modify `.claude/settings.json`:
- Set `"default_agents": ["coder", "tester"]` for parallel execution
- Set `"parallel_execution": true` for old behavior

## 📊 Success Metrics
Monitor these to validate optimization:
- **Prompts per commit**: Should decrease significantly
- **1-shot success rate**: Should improve with clearer directives
- **Session length**: Should extend from ~50 to ~180+ useful prompts

---
**System optimized on**: $(date)
**Target efficiency gain**: 4x more useful prompts per session