# Parallel Execution Guide

This guide explains how to use Claude Code's parallel execution capabilities to work on multiple features simultaneously and coordinate multiple agents for complex tasks.

## 🤖 Parallel Execution Methods

### 1. Git Worktrees for Feature Development
**Best for**: Independent feature development by multiple developers/agents
**Isolation**: Complete file system isolation
**Coordination**: Through git branches and merge strategies

### 2. Task Tool for Concurrent Operations
**Best for**: Related tasks that need coordination (testing, review, analysis)
**Isolation**: Process isolation with shared context
**Coordination**: Through Claude Code's built-in task management

## 🌳 Git Worktrees Workflow

### Quick Start
```bash
# Create multiple worktrees for parallel features
/parallel-features authentication logging data-export

# This creates:
# ../project-authentication/ (branch: feature/authentication)
# ../project-logging/ (branch: feature/logging)  
# ../project-data-export/ (branch: feature/data-export)

# Start Claude Code in each worktree
cd ../project-authentication && claude
cd ../project-logging && claude
cd ../project-data-export && claude
```

### Manual Worktree Management
```bash
# Create worktree manually
git worktree add ../project-feature-name -b feature/feature-name

# List all worktrees
git worktree list

# Remove worktree when done
git worktree remove ../project-feature-name
git branch -d feature/feature-name
```

### Using the Worktree Manager
```bash
# Create new feature worktree
.claude/scripts/worktree-manager.sh create authentication

# List all active worktrees
.claude/scripts/worktree-manager.sh list

# Check status of all worktrees
.claude/scripts/worktree-manager.sh status

# Sync all worktrees with main
.claude/scripts/worktree-manager.sh sync

# Clean up completed feature
.claude/scripts/worktree-manager.sh cleanup authentication
```

## 🔧 Task Tool for Specialized Agents

### Parallel Code Review
```bash
# Deploy multiple specialized review agents
/parallel-review src/ security,performance,style,architecture

# Each agent focuses on their specialization:
# - Security Agent: Vulnerability scanning
# - Performance Agent: Bottleneck analysis  
# - Style Agent: Code style compliance
# - Architecture Agent: Design pattern analysis
```

### Parallel Testing
```bash
# Run tests across multiple environments
/parallel-test all python3.9,python3.10,python3.11,octave

# Agents run concurrently:
# - Unit Test Agent: Fast isolated tests
# - Integration Test Agent: External dependency tests
# - Performance Test Agent: Benchmark regression tests
# - Compatibility Agent: Cross-platform tests
```

### Parallel Codebase Exploration
```bash
# Explore large codebase with specialized agents
/parallel-explore src/ architecture,dependencies,patterns,complexity

# Each agent analyzes from their perspective:
# - Architecture Agent: System structure mapping
# - Dependency Agent: Import graph analysis
# - Pattern Agent: Design pattern identification
# - Complexity Agent: Hotspot and technical debt analysis
```

## 🎯 Agent Specializations

### Review Agents
| Agent | Focus Area | Output |
|-------|------------|--------|
| **Security** | Vulnerabilities, input validation | Security report with CVSS scores |
| **Performance** | Bottlenecks, algorithm efficiency | Performance analysis with recommendations |
| **Style** | Code formatting, naming conventions | Style compliance report |
| **Architecture** | Design patterns, modularity | Architecture assessment |
| **Testing** | Test coverage, quality | Test gap analysis |
| **Documentation** | Docstrings, comments | Documentation completeness report |

### Testing Agents
| Agent | Environment | Tests |
|-------|-------------|-------|
| **Unit Test** | Python 3.9+ | Fast isolated tests |
| **Integration** | Full dependencies | External service tests |
| **Performance** | Benchmarking setup | Regression tests |
| **Security** | Security tools | Vulnerability tests |
| **Compatibility** | Multiple Python versions | Cross-platform tests |

### Exploration Agents
| Agent | Analysis Type | Deliverable |
|-------|---------------|-------------|
| **Architecture** | System structure | Component relationship map |
| **Dependency** | Import analysis | Dependency graph |
| **Pattern** | Design patterns | Pattern usage report |
| **Complexity** | Code metrics | Refactoring recommendations |

## 🔄 Coordination Strategies

### Git Worktree Coordination
```markdown
# Coordination File: parallel-work-plan.md

## Feature Dependencies
- logging (foundation) → authentication → data-export
- Features can be developed in parallel
- Integration points identified

## Merge Strategy
1. Merge logging first (no dependencies)
2. Merge authentication (depends on logging)
3. Merge data-export (depends on both)

## Communication
- Daily sync meetings
- Shared Slack channel #parallel-dev
- Status updates in worktree FEATURE.md files
```

### Task Agent Coordination
```json
{
  "coordination": {
    "sharedState": ".claude/agent-coordination.json",
    "lockMechanism": "file-based",
    "progressReporting": "real-time",
    "errorHandling": "graceful-degradation"
  }
}
```

## 📊 Progress Management

### Real-time Status Dashboard
```bash
# Check all parallel work status
.claude/scripts/worktree-manager.sh status

# Output:
🔍 Feature: authentication
   🤖 Claude: RUNNING
   📊 Changes: 5 files modified
   📈 Commits: 3 ahead of main
   🧪 Tests: PASSING

🔍 Feature: logging  
   🤖 Claude: RUNNING
   📊 Changes: 2 files modified
   📈 Commits: 2 ahead of main
   🧪 Tests: PASSING
```

### Agent Progress Tracking
```markdown
# Task Progress (auto-updated)
- Security Agent: 🔍 Scanning for vulnerabilities... (75% complete)
- Performance Agent: ✅ Analysis complete (100% complete)
- Style Agent: 🔍 Checking code style... (45% complete)
- Architecture Agent: 🔍 Mapping dependencies... (60% complete)
```

## 🎭 Advanced Patterns

### Feature Racing
```bash
# Have multiple agents implement the same feature differently
/parallel-features auth-jwt auth-session auth-oauth

# Compare implementations and choose the best approach
# Useful for exploring different solutions
```

### Pipeline Parallelization
```bash
# Stage 1: Multiple agents explore codebase
/parallel-explore src/

# Stage 2: Based on findings, parallel development
/parallel-features refactor-module-a refactor-module-b

# Stage 3: Parallel testing of all changes
/parallel-test all environments

# Stage 4: Parallel review before merge
/parallel-review changes/ all
```

### Cross-Agent Verification
```bash
# Agent A writes code
cd ../project-feature-a
/new-script 01 implement feature

# Agent B reviews Agent A's code
/parallel-review ../project-feature-a/ security,performance

# Agent C writes tests for Agent A's code
/new-test ../project-feature-a/src/s01_implement_feature.py
```

## ⚠️ Best Practices

### Do's
- ✅ Keep features as independent as possible
- ✅ Regular sync with main branch
- ✅ Clear documentation of dependencies
- ✅ Validate all code before merging
- ✅ Use Task tool for related operations

### Don'ts  
- ❌ Don't work on same files in multiple worktrees
- ❌ Don't ignore merge conflicts
- ❌ Don't skip integration testing
- ❌ Don't exceed 10 concurrent agents
- ❌ Don't forget to clean up completed worktrees

### Performance Tips
- Limit to 5-8 concurrent worktrees for optimal performance
- Use SSD storage for worktree directories
- Close unused worktrees to save memory
- Regular garbage collection: `git gc --prune=now`

## 🔧 Troubleshooting

### Common Issues
1. **Worktree creation fails**: Check git repository status
2. **Agent conflicts**: Ensure proper isolation
3. **Merge conflicts**: Use `/merge-worktrees sequential`
4. **Performance issues**: Reduce concurrent agents

### Emergency Procedures
```bash
# Stop all Claude processes
pkill -f claude

# List and clean all worktrees
git worktree list
git worktree remove --force <path>

# Reset to clean state
git checkout main
git reset --hard origin/main
```

## 🚀 Examples

### Complete Parallel Workflow
```bash
# 1. Plan parallel features
/parallel-features user-auth data-processing ui-dashboard

# 2. Start development in each worktree
# Terminal 1: cd ../project-user-auth && claude
# Terminal 2: cd ../project-data-processing && claude  
# Terminal 3: cd ../project-ui-dashboard && claude

# 3. Regular validation across all features
/parallel-test all

# 4. Cross-feature review
/parallel-review ../project-*/src/ security,style

# 5. Merge when ready
/merge-worktrees sequential user-auth data-processing ui-dashboard

# 6. Clean up
.claude/scripts/worktree-manager.sh cleanup user-auth
.claude/scripts/worktree-manager.sh cleanup data-processing
.claude/scripts/worktree-manager.sh cleanup ui-dashboard
```

This parallel execution system allows you to maximize development velocity while maintaining code quality through automated validation and structured coordination.