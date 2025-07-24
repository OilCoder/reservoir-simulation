#!/bin/bash
# Complete Parallel Workflow Management Script
# Integrates all parallel execution capabilities into a unified interface

set -e

# Configuration
WORKSPACE_PATH="/workspace"
CLAUDE_DIR="$WORKSPACE_PATH/.claude"
SCRIPTS_DIR="$CLAUDE_DIR/scripts"
COORDINATOR_SCRIPT="$SCRIPTS_DIR/agent-coordinator.py"
DASHBOARD_SCRIPT="$SCRIPTS_DIR/agent-dashboard.py"
WORKTREE_SCRIPT="$SCRIPTS_DIR/worktree-manager.sh"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
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

log_header() {
    echo -e "${PURPLE}================================${NC}"
    echo -e "${PURPLE}$1${NC}"
    echo -e "${PURPLE}================================${NC}"
}

# Check prerequisites
check_prerequisites() {
    log_info "Checking prerequisites..."
    
    # Check if we're in a git repository
    if ! git rev-parse --git-dir > /dev/null 2>&1; then
        log_error "Not in a git repository"
        exit 1
    fi
    
    # Check if Claude Code is installed
    if ! command -v claude > /dev/null 2>&1; then
        log_error "Claude Code not found. Install with: npm install -g @anthropic-ai/claude-code"
        exit 1
    fi
    
    # Check Python 3
    if ! command -v python3 > /dev/null 2>&1; then
        log_error "Python 3 not found"
        exit 1
    fi
    
    # Check if scripts exist
    for script in "$COORDINATOR_SCRIPT" "$DASHBOARD_SCRIPT" "$WORKTREE_SCRIPT"; do
        if [ ! -f "$script" ]; then
            log_error "Missing script: $script"
            exit 1
        fi
    done
    
    log_success "All prerequisites met"
}

# Start the coordination system
start_coordinator() {
    log_info "Starting agent coordinator..."
    
    # Create logs directory
    mkdir -p "$CLAUDE_DIR/logs"
    
    # Start coordinator in background
    python3 "$COORDINATOR_SCRIPT" monitor --workspace "$WORKSPACE_PATH" > "$CLAUDE_DIR/logs/coordinator-output.log" 2>&1 &
    COORDINATOR_PID=$!
    
    # Save PID for cleanup
    echo $COORDINATOR_PID > "$CLAUDE_DIR/coordinator.pid"
    
    log_success "Agent coordinator started (PID: $COORDINATOR_PID)"
}

# Stop the coordination system
stop_coordinator() {
    log_info "Stopping agent coordinator..."
    
    if [ -f "$CLAUDE_DIR/coordinator.pid" ]; then
        COORDINATOR_PID=$(cat "$CLAUDE_DIR/coordinator.pid")
        if kill -0 $COORDINATOR_PID 2>/dev/null; then
            kill $COORDINATOR_PID
            log_success "Agent coordinator stopped"
        else
            log_warning "Coordinator process not running"
        fi
        rm -f "$CLAUDE_DIR/coordinator.pid"
    else
        log_warning "No coordinator PID file found"
    fi
}

# Create parallel feature development environment
setup_parallel_features() {
    local features=("$@")
    
    if [ ${#features[@]} -eq 0 ]; then
        log_error "No features specified"
        echo "Usage: $0 setup-features feature1 feature2 feature3"
        exit 1
    fi
    
    log_header "SETTING UP PARALLEL FEATURES"
    
    # Start coordinator
    start_coordinator
    sleep 2
    
    # Create worktrees for each feature
    for feature in "${features[@]}"; do
        log_info "Creating worktree for feature: $feature"
        
        if ! "$WORKTREE_SCRIPT" create "$feature"; then
            log_error "Failed to create worktree for $feature"
            continue
        fi
        
        # Register agent with coordinator
        python3 "$COORDINATOR_SCRIPT" register-agent \
            --agent-id "$feature-agent" \
            --agent-type "feature-development" \
            --worktree-path "../project-$feature" \
            --workspace "$WORKSPACE_PATH"
        
        log_success "Feature environment ready: $feature"
    done
    
    # Show status
    echo ""
    log_header "PARALLEL DEVELOPMENT ENVIRONMENT READY"
    
    echo -e "${CYAN}Created worktrees:${NC}"
    for feature in "${features[@]}"; do
        echo "  📁 ../project-$feature (branch: feature/$feature)"
    done
    
    echo ""
    echo -e "${CYAN}Next steps:${NC}"
    echo "1. Open separate terminals for each feature"
    echo "2. Navigate to each worktree: cd ../project-<feature>"
    echo "3. Start Claude Code in each: claude"
    echo "4. Monitor progress: $0 monitor"
    echo ""
    
    # Offer to start monitoring
    read -p "Start monitoring dashboard now? (y/N): " -r
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        launch_monitor
    fi
}

# Launch monitoring dashboard
launch_monitor() {
    log_info "Launching monitoring dashboard..."
    
    # Check if coordinator is running
    if [ ! -f "$CLAUDE_DIR/coordinator.pid" ]; then
        log_warning "Coordinator not running, starting it..."
        start_coordinator
        sleep 2
    fi
    
    # Launch dashboard
    python3 "$DASHBOARD_SCRIPT" --workspace "$WORKSPACE_PATH"
}

# Deploy specialized review agents
deploy_review_agents() {
    local target_path="$1"
    local review_types="$2"
    
    if [ -z "$target_path" ]; then
        target_path="src/"
    fi
    
    if [ -z "$review_types" ]; then
        review_types="security,performance,style,architecture"
    fi
    
    log_header "DEPLOYING REVIEW AGENTS"
    log_info "Target: $target_path"
    log_info "Review types: $review_types"
    
    # Start coordinator if not running
    if [ ! -f "$CLAUDE_DIR/coordinator.pid" ]; then
        start_coordinator
        sleep 2
    fi
    
    # Parse review types
    IFS=',' read -ra TYPES <<< "$review_types"
    
    # Deploy each review agent type
    for review_type in "${TYPES[@]}"; do
        log_info "Deploying $review_type review agent..."
        
        # Register agent
        python3 "$COORDINATOR_SCRIPT" register-agent \
            --agent-id "$review_type-reviewer" \
            --agent-type "code-review" \
            --workspace "$WORKSPACE_PATH"
        
        # Note: In practice, you would start Claude Code processes here
        # This is a simplified version for demonstration
        
        log_success "$review_type review agent deployed"
    done
    
    log_success "All review agents deployed"
    
    # Show monitoring option
    echo ""
    read -p "Monitor review progress? (y/N): " -r
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        launch_monitor
    fi
}

# Run parallel tests
run_parallel_tests() {
    local test_scope="$1"
    local environments="$2"
    
    if [ -z "$test_scope" ]; then
        test_scope="all"
    fi
    
    if [ -z "$environments" ]; then
        environments="python3.9,python3.10,python3.11"
    fi
    
    log_header "RUNNING PARALLEL TESTS"
    log_info "Scope: $test_scope"
    log_info "Environments: $environments"
    
    # Start coordinator if not running
    if [ ! -f "$CLAUDE_DIR/coordinator.pid" ]; then
        start_coordinator
        sleep 2
    fi
    
    # Parse environments
    IFS=',' read -ra ENVS <<< "$environments"
    
    # Deploy test agents for each environment
    for env in "${ENVS[@]}"; do
        log_info "Starting tests in $env environment..."
        
        # Register test agent
        python3 "$COORDINATOR_SCRIPT" register-agent \
            --agent-id "$env-tester" \
            --agent-type "testing" \
            --workspace "$WORKSPACE_PATH"
        
        # In practice, you would start actual test processes here
        log_success "Test agent deployed for $env"
    done
    
    log_success "All test agents deployed"
    
    # Monitor testing
    echo ""
    read -p "Monitor test progress? (y/N): " -r
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        launch_monitor
    fi
}

# Cleanup and merge parallel work
cleanup_and_merge() {
    local merge_strategy="$1"
    shift
    local features=("$@")
    
    if [ -z "$merge_strategy" ]; then
        merge_strategy="sequential"
    fi
    
    log_header "CLEANUP AND MERGE"
    log_info "Strategy: $merge_strategy"
    log_info "Features: ${features[*]}"
    
    # Show current status first
    log_info "Current worktree status:"
    "$WORKTREE_SCRIPT" status
    
    echo ""
    read -p "Proceed with merge? (y/N): " -r
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log_info "Merge cancelled"
        return
    fi
    
    # Switch to main branch
    log_info "Switching to main branch..."
    git checkout main
    git pull origin main
    
    # Merge each feature based on strategy
    if [ "$merge_strategy" = "sequential" ]; then
        for feature in "${features[@]}"; do
            log_info "Merging feature: $feature"
            
            if git merge "feature/$feature" --no-ff -m "Merge feature: $feature"; then
                log_success "Successfully merged: $feature"
            else
                log_error "Merge conflict in: $feature"
                log_info "Please resolve conflicts manually and continue"
                return 1
            fi
        done
    else
        log_warning "Parallel merge strategy not yet implemented"
        log_info "Falling back to sequential merge"
        # Recursively call with sequential strategy
        cleanup_and_merge "sequential" "${features[@]}"
        return
    fi
    
    # Clean up worktrees
    log_info "Cleaning up worktrees..."
    for feature in "${features[@]}"; do
        "$WORKTREE_SCRIPT" cleanup "$feature"
    done
    
    # Stop coordinator
    stop_coordinator
    
    log_success "Parallel work merged and cleaned up successfully!"
}

# Show system status
show_status() {
    log_header "PARALLEL SYSTEM STATUS"
    
    # Check if coordinator is running
    if [ -f "$CLAUDE_DIR/coordinator.pid" ]; then
        COORDINATOR_PID=$(cat "$CLAUDE_DIR/coordinator.pid")
        if kill -0 $COORDINATOR_PID 2>/dev/null; then
            log_success "Agent coordinator running (PID: $COORDINATOR_PID)"
        else
            log_warning "Coordinator PID file exists but process not running"
        fi
    else
        log_info "Agent coordinator not running"
    fi
    
    # Show worktree status
    echo ""
    log_info "Worktree status:"
    "$WORKTREE_SCRIPT" status
    
    # Show agent status if coordinator is running
    if [ -f "$CLAUDE_DIR/coordinator.pid" ] && kill -0 $(cat "$CLAUDE_DIR/coordinator.pid") 2>/dev/null; then
        echo ""
        log_info "Agent coordination status:"
        python3 "$COORDINATOR_SCRIPT" status --workspace "$WORKSPACE_PATH"
    fi
}

# Main command dispatch
case "$1" in
    "setup-features")
        shift
        check_prerequisites
        setup_parallel_features "$@"
        ;;
    "monitor")
        check_prerequisites
        launch_monitor
        ;;
    "review")
        check_prerequisites
        deploy_review_agents "$2" "$3"
        ;;
    "test")
        check_prerequisites
        run_parallel_tests "$2" "$3"
        ;;
    "merge")
        shift
        check_prerequisites
        cleanup_and_merge "$@"
        ;;
    "status")
        check_prerequisites
        show_status
        ;;
    "start-coordinator")
        check_prerequisites
        start_coordinator
        ;;
    "stop-coordinator")
        check_prerequisites
        stop_coordinator
        ;;
    "help"|*)
        echo "Parallel Workflow Management Script"
        echo ""
        echo "Usage: $0 <command> [arguments]"
        echo ""
        echo "Commands:"
        echo "  setup-features <feature1> [feature2] ... - Set up parallel feature development"
        echo "  monitor                                   - Launch monitoring dashboard"
        echo "  review [path] [types]                    - Deploy specialized review agents"
        echo "  test [scope] [environments]              - Run parallel tests"
        echo "  merge [strategy] <feature1> [feature2]   - Merge and cleanup parallel work"
        echo "  status                                    - Show system status"
        echo "  start-coordinator                         - Start agent coordinator"
        echo "  stop-coordinator                          - Stop agent coordinator"
        echo "  help                                      - Show this help"
        echo ""
        echo "Examples:"
        echo "  $0 setup-features auth logging dashboard"
        echo "  $0 review src/ security,performance,style"
        echo "  $0 test all python3.9,python3.10,octave"
        echo "  $0 merge sequential auth logging dashboard"
        echo "  $0 monitor"
        echo ""
        ;;
esac