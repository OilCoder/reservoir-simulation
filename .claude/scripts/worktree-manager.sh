#!/bin/bash
# Worktree management helper for parallel Claude Code execution

set -e

# Configuration
WORKTREE_BASE="../"
PROJECT_PREFIX="project-"
CLAUDE_CONFIG_DIR=".claude"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Helper functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to create a new worktree
create_worktree() {
    local feature_name="$1"
    local branch_name="feature/$feature_name"
    local worktree_path="${WORKTREE_BASE}${PROJECT_PREFIX}${feature_name}"
    
    log_info "Creating worktree for feature: $feature_name"
    
    # Check if worktree already exists
    if [ -d "$worktree_path" ]; then
        log_error "Worktree already exists: $worktree_path"
        return 1
    fi
    
    # Create the worktree
    git worktree add "$worktree_path" -b "$branch_name"
    
    # Copy Claude configuration
    if [ -d "$CLAUDE_CONFIG_DIR" ]; then
        log_info "Copying Claude configuration to worktree"
        cp -r "$CLAUDE_CONFIG_DIR" "$worktree_path/"
    fi
    
    # Create feature-specific documentation
    cat > "$worktree_path/FEATURE.md" << EOF
# Feature: $feature_name

## Branch: $branch_name
## Worktree: $worktree_path

## Development Notes
- This worktree is for parallel development
- Follow all project rules and conventions
- Run \`/validate\` before committing
- Coordinate with other parallel features

## Getting Started
\`\`\`bash
cd $worktree_path
claude
\`\`\`

## Integration Notes
- Dependencies on other features: [List here]
- Integration points: [List here]
- Merge order consideration: [Priority level]
EOF
    
    log_success "Worktree created: $worktree_path"
    log_info "Start Claude Code with: cd $worktree_path && claude"
}

# Function to list all worktrees
list_worktrees() {
    log_info "Current worktrees:"
    git worktree list | while read -r path branch; do
        if [[ "$path" == *"$PROJECT_PREFIX"* ]]; then
            feature_name=$(basename "$path" | sed "s/^$PROJECT_PREFIX//")
            status=$(cd "$path" && git status --porcelain | wc -l)
            commits=$(cd "$path" && git rev-list --count HEAD ^main 2>/dev/null || echo "0")
            
            echo "  📁 $feature_name"
            echo "     Path: $path"
            echo "     Branch: $branch"
            echo "     Changes: $status files modified"
            echo "     Commits: $commits ahead of main"
            echo ""
        fi
    done
}

# Function to clean up a worktree
cleanup_worktree() {
    local feature_name="$1"
    local worktree_path="${WORKTREE_BASE}${PROJECT_PREFIX}${feature_name}"
    local branch_name="feature/$feature_name"
    
    log_info "Cleaning up worktree: $feature_name"
    
    # Check if worktree exists
    if [ ! -d "$worktree_path" ]; then
        log_error "Worktree does not exist: $worktree_path"
        return 1
    fi
    
    # Check for uncommitted changes
    if cd "$worktree_path" && [ -n "$(git status --porcelain)" ]; then
        log_warning "Worktree has uncommitted changes!"
        read -p "Are you sure you want to remove it? (y/N): " -r
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            log_info "Cleanup cancelled"
            return 0
        fi
    fi
    
    # Remove worktree
    git worktree remove "$worktree_path" --force
    
    # Ask about branch deletion
    if git show-ref --verify --quiet "refs/heads/$branch_name"; then
        read -p "Delete branch $branch_name? (y/N): " -r
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            git branch -D "$branch_name"
            log_success "Branch deleted: $branch_name"
        fi
    fi
    
    log_success "Worktree cleaned up: $feature_name"
}

# Function to check worktree status
status_check() {
    log_info "Worktree Status Summary"
    echo "========================"
    
    git worktree list | while read -r path branch; do
        if [[ "$path" == *"$PROJECT_PREFIX"* ]]; then
            feature_name=$(basename "$path" | sed "s/^$PROJECT_PREFIX//")
            
            echo "🔍 Feature: $feature_name"
            
            # Check if Claude is running (simplified check)
            if pgrep -f "claude.*$path" > /dev/null; then
                echo "   🤖 Claude: RUNNING"
            else
                echo "   🤖 Claude: STOPPED"
            fi
            
            # Git status
            cd "$path"
            changes=$(git status --porcelain | wc -l)
            commits=$(git rev-list --count HEAD ^main 2>/dev/null || echo "0")
            
            echo "   📊 Changes: $changes files modified"
            echo "   📈 Commits: $commits ahead of main"
            
            # Check if tests pass
            if [ -f "requirements.txt" ] && [ -d "tests" ]; then
                echo "   🧪 Tests: Checking..."
                # This would need actual test running logic
            fi
            
            echo ""
        fi
    done
}

# Function to sync all worktrees with main
sync_worktrees() {
    log_info "Syncing all worktrees with main branch"
    
    # Update main branch first
    git checkout main
    git pull origin main
    
    git worktree list | while read -r path branch; do
        if [[ "$path" == *"$PROJECT_PREFIX"* ]]; then
            feature_name=$(basename "$path" | sed "s/^$PROJECT_PREFIX//")
            log_info "Syncing feature: $feature_name"
            
            cd "$path"
            git fetch origin
            git rebase origin/main || {
                log_warning "Rebase conflict in $feature_name - manual resolution needed"
                log_info "To resolve: cd $path && git rebase --continue"
            }
        fi
    done
}

# Main command handling
case "$1" in
    "create")
        if [ -z "$2" ]; then
            log_error "Usage: $0 create <feature-name>"
            exit 1
        fi
        create_worktree "$2"
        ;;
    "list")
        list_worktrees
        ;;
    "cleanup")
        if [ -z "$2" ]; then
            log_error "Usage: $0 cleanup <feature-name>"
            exit 1
        fi
        cleanup_worktree "$2"
        ;;
    "status")
        status_check
        ;;
    "sync")
        sync_worktrees
        ;;
    "help"|*)
        echo "Worktree Manager for Parallel Claude Code Development"
        echo ""
        echo "Usage: $0 <command> [arguments]"
        echo ""
        echo "Commands:"
        echo "  create <feature-name>  Create new worktree for feature development"
        echo "  list                   List all active worktrees"
        echo "  cleanup <feature-name> Remove worktree and optionally delete branch"
        echo "  status                 Show status of all worktrees"
        echo "  sync                   Sync all worktrees with main branch"
        echo "  help                   Show this help message"
        echo ""
        echo "Examples:"
        echo "  $0 create authentication"
        echo "  $0 list"
        echo "  $0 cleanup authentication"
        echo "  $0 status"
        echo "  $0 sync"
        ;;
esac