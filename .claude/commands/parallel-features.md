---
allowed-tools: [Bash, Task]
description: Create multiple feature branches with git worktrees for parallel development
---

# Create Parallel Feature Branches

Set up multiple git worktrees for concurrent feature development by different Claude Code agents.

Arguments: `$ARGUMENTS`
Expected format: `<feature1> <feature2> [feature3] ...`
Example: `authentication logging data-export`

## Instructions:

1. **Validate current repository state**:
   - Ensure we're in a git repository
   - Check for uncommitted changes
   - Verify main/master branch is up to date

2. **Create worktrees for each feature**:
   - For each feature name in arguments:
     - Create branch: `feature/<feature-name>`
     - Create worktree: `../project-<feature-name>`
     - Copy `.claude/` configuration to each worktree

3. **Initialize each worktree**:
   - Ensure all project rules are available
   - Copy templates and settings
   - Create feature-specific documentation

4. **Provide usage instructions**:
   - Show commands to start Claude Code in each worktree
   - Explain how to coordinate between agents
   - Document merge strategy

5. **Create coordination file**:
   - `parallel-work-plan.md` with:
     - Feature assignments
     - Dependencies between features
     - Integration checkpoints
     - Merge order

Example workflow:
```bash
# This command creates:
git worktree add ../project-authentication -b feature/authentication
git worktree add ../project-logging -b feature/logging
git worktree add ../project-data-export -b feature/data-export

# Then you can run:
cd ../project-authentication && claude
cd ../project-logging && claude  
cd ../project-data-export && claude
```

## Coordination Guidelines:

- Each agent works independently on their feature
- Regular sync points to avoid conflicts
- Shared documentation in main repo
- Use Task tool for cross-feature coordination