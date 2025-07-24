---
allowed-tools: [Bash, Read, Task]
description: Consolidate work from multiple parallel worktrees
---

# Merge Parallel Worktrees

Intelligently consolidate and merge work from multiple parallel worktrees back into the main branch.

Arguments: `$ARGUMENTS`
Expected format: `<merge_strategy> [worktree1] [worktree2] ...`
Example: `sequential feature-auth feature-logging` or `parallel ../project-*`

Available merge strategies:
- `sequential`: Merge branches one by one with conflict resolution
- `parallel`: Attempt to merge all branches simultaneously
- `cherry-pick`: Select specific commits from each branch
- `rebase`: Rebase and linearize history before merging

## Instructions:

1. **Analyze worktree states**:
   - List all available worktrees
   - Check branch status and commits ahead
   - Identify potential merge conflicts
   - Validate code compliance in each worktree

2. **Pre-merge validation using Task tool**:
   - **Validation Agent**: Run compliance checks on each branch
   - **Conflict Detection Agent**: Analyze potential merge conflicts
   - **Dependency Agent**: Check for integration issues
   - **Test Agent**: Run tests on each branch independently

3. **Create merge plan**:
   ```markdown
   # Merge Plan
   
   ## Branches to merge:
   - feature/authentication (5 commits, tests passing)
   - feature/logging (3 commits, tests passing)
   - feature/data-export (7 commits, tests passing)
   
   ## Merge order (based on dependencies):
   1. feature/logging (foundation)
   2. feature/authentication (depends on logging)
   3. feature/data-export (depends on both)
   
   ## Identified conflicts:
   - config.py: logging vs auth configuration
   - requirements.txt: dependency versions
   
   ## Resolution strategy:
   - Use merge commits to preserve feature history
   - Manual resolution for config conflicts
   - Automated resolution for requirements.txt
   ```

4. **Execute merge strategy**:

   ### Sequential Merge
   ```bash
   git checkout main
   git pull origin main
   
   # Merge each branch in dependency order
   git merge feature/logging
   git merge feature/authentication  
   git merge feature/data-export
   ```

   ### Parallel Merge (using multiple agents)
   - Agent 1: Merge feature/logging
   - Agent 2: Merge feature/authentication (after logging)
   - Agent 3: Merge feature/data-export (after auth)

5. **Post-merge validation**:
   - Run full test suite
   - Verify all features work together
   - Check for integration issues
   - Validate project rule compliance

6. **Cleanup worktrees**:
   ```bash
   # Remove worktrees after successful merge
   git worktree remove ../project-authentication
   git worktree remove ../project-logging
   git worktree remove ../project-data-export
   
   # Delete feature branches
   git branch -d feature/authentication
   git branch -d feature/logging
   git branch -d feature/data-export
   ```

## Merge Strategies in Detail:

### Sequential Merge
- Safe, predictable approach
- Resolve conflicts one at a time
- Easier to track which branch caused issues
- Longer process but more controlled

### Parallel Merge
- Faster when branches are independent
- Uses multiple agents for simultaneous merging
- Higher risk of complex conflicts
- Requires sophisticated conflict resolution

### Cherry-Pick Strategy
- Select best commits from each branch
- Useful when branches have experimental code
- Maintains cleaner history
- More manual work required

### Rebase Strategy
- Linear history without merge commits
- Cleaner git log
- Can be complex with multiple branches
- Risk of losing merge context

## Conflict Resolution:

### Automated Resolution (via agents)
- **Style Conflicts**: Automatically apply project formatting
- **Import Conflicts**: Merge import lists intelligently
- **Documentation Conflicts**: Combine docstrings and comments

### Manual Resolution Required
- **Logic Conflicts**: Business logic contradictions
- **API Changes**: Incompatible interface modifications
- **Database Schema**: Conflicting migrations

## Quality Gates:

1. **Pre-merge checks**:
   - All tests pass in each worktree
   - Code style compliance
   - No security vulnerabilities

2. **Post-merge validation**:
   - Integration tests pass
   - Performance benchmarks within limits
   - Full CI/CD pipeline success

3. **Rollback plan**:
   - Create backup tags before merging
   - Document rollback procedure
   - Prepare hotfix strategy if needed

## Coordination Between Agents:

- **Communication**: Shared status file for coordination
- **Lock mechanism**: Prevent simultaneous operations on same files
- **Progress reporting**: Real-time updates on merge status
- **Error handling**: Graceful failure with detailed error reports