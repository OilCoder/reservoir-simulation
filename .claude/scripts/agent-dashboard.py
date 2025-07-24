#!/usr/bin/env python3
"""
Real-time Dashboard for Parallel Claude Code Agents

Provides a terminal-based dashboard showing the status of all parallel agents,
their progress, resource usage, and coordination status.
"""

import os
import sys
import json
import time
import curses
import threading
from datetime import datetime, timedelta
from pathlib import Path
from typing import Dict, List, Any, Optional

# Add current directory to path for imports
sys.path.append(str(Path(__file__).parent))

try:
    from agent_coordinator import AgentCoordinator, AgentStatus
except ImportError:
    print("Error: Could not import agent_coordinator module")
    sys.exit(1)


class AgentDashboard:
    """Real-time terminal dashboard for monitoring parallel agents."""
    
    def __init__(self, workspace_path: str = "/workspace"):
        self.workspace_path = workspace_path
        self.coordinator = AgentCoordinator(workspace_path)
        self.running = False
        self.update_interval = 2  # seconds
        self.last_update = datetime.now()
        
        # Dashboard state
        self.current_tab = 0
        self.tabs = ["Overview", "Agents", "Resources", "Conflicts", "Logs"]
        self.scroll_offset = 0
        self.selected_agent = None
        
        # Colors
        self.colors = {}
        
    def run(self):
        """Start the dashboard."""
        curses.wrapper(self._main_loop)
        
    def _main_loop(self, stdscr):
        """Main curses loop."""
        # Initialize colors
        curses.start_color()
        curses.use_default_colors()
        
        # Define color pairs
        curses.init_pair(1, curses.COLOR_GREEN, -1)    # Success/Active
        curses.init_pair(2, curses.COLOR_RED, -1)      # Error/Failed
        curses.init_pair(3, curses.COLOR_YELLOW, -1)   # Warning/Blocked
        curses.init_pair(4, curses.COLOR_BLUE, -1)     # Info/Working
        curses.init_pair(5, curses.COLOR_CYAN, -1)     # Highlight
        curses.init_pair(6, curses.COLOR_MAGENTA, -1)  # Special
        
        self.colors = {
            'success': curses.color_pair(1),
            'error': curses.color_pair(2),
            'warning': curses.color_pair(3),
            'info': curses.color_pair(4),
            'highlight': curses.color_pair(5),
            'special': curses.color_pair(6)
        }
        
        # Configure screen
        stdscr.nodelay(True)
        stdscr.timeout(100)
        curses.curs_set(0)  # Hide cursor
        
        self.running = True
        
        # Start background update thread
        update_thread = threading.Thread(target=self._update_loop, daemon=True)
        update_thread.start()
        
        # Main display loop
        while self.running:
            try:
                self._draw_dashboard(stdscr)
                
                # Handle keyboard input
                key = stdscr.getch()
                self._handle_input(key)
                
                time.sleep(0.1)
                
            except KeyboardInterrupt:
                self.running = False
            except Exception as e:
                # Handle errors gracefully
                stdscr.addstr(0, 0, f"Error: {str(e)}")
                stdscr.refresh()
                time.sleep(1)
    
    def _update_loop(self):
        """Background thread for updating data."""
        while self.running:
            try:
                self.last_update = datetime.now()
                time.sleep(self.update_interval)
            except Exception:
                pass
    
    def _draw_dashboard(self, stdscr):
        """Draw the main dashboard."""
        stdscr.clear()
        height, width = stdscr.getmaxyx()
        
        # Draw header
        self._draw_header(stdscr, width)
        
        # Draw tab bar
        self._draw_tabs(stdscr, width, 2)
        
        # Draw main content based on selected tab
        content_start = 4
        content_height = height - content_start - 2
        
        if self.current_tab == 0:  # Overview
            self._draw_overview(stdscr, content_start, content_height, width)
        elif self.current_tab == 1:  # Agents
            self._draw_agents(stdscr, content_start, content_height, width)
        elif self.current_tab == 2:  # Resources
            self._draw_resources(stdscr, content_start, content_height, width)
        elif self.current_tab == 3:  # Conflicts
            self._draw_conflicts(stdscr, content_start, content_height, width)
        elif self.current_tab == 4:  # Logs
            self._draw_logs(stdscr, content_start, content_height, width)
        
        # Draw footer
        self._draw_footer(stdscr, height - 1, width)
        
        stdscr.refresh()
    
    def _draw_header(self, stdscr, width):
        """Draw dashboard header."""
        title = "Claude Code Agent Dashboard"
        timestamp = self.last_update.strftime("%Y-%m-%d %H:%M:%S")
        
        # Center title
        title_x = max(0, (width - len(title)) // 2)
        stdscr.addstr(0, title_x, title, self.colors['highlight'] | curses.A_BOLD)
        
        # Right-align timestamp
        time_x = max(0, width - len(timestamp) - 1)
        stdscr.addstr(0, time_x, timestamp, self.colors['info'])
        
        # Draw separator line
        stdscr.addstr(1, 0, "─" * width)
    
    def _draw_tabs(self, stdscr, width, y):
        """Draw tab navigation."""
        x = 0
        for i, tab in enumerate(self.tabs):
            if i == self.current_tab:
                stdscr.addstr(y, x, f"[{tab}]", self.colors['highlight'] | curses.A_BOLD)
                x += len(tab) + 3
            else:
                stdscr.addstr(y, x, f" {tab} ", self.colors['info'])
                x += len(tab) + 2
            
            if x < width - 1:
                stdscr.addstr(y, x, "|")
                x += 2
    
    def _draw_overview(self, stdscr, start_y, height, width):
        """Draw overview tab."""
        try:
            status = self.coordinator.get_agent_status()
            summary = status.get('summary', {})
            agents = status.get('agents', {})
            locks = status.get('active_locks', {})
            
            y = start_y
            
            # Summary statistics
            stdscr.addstr(y, 0, "SYSTEM OVERVIEW", self.colors['highlight'] | curses.A_BOLD)
            y += 2
            
            total_agents = summary.get('total_agents', 0)
            active_agents = summary.get('active_agents', 0)
            idle_agents = summary.get('idle_agents', 0)
            total_locks = summary.get('total_locks', 0)
            
            stdscr.addstr(y, 0, f"Total Agents:  {total_agents}")
            stdscr.addstr(y, 20, f"Active: {active_agents}", self.colors['success'])
            stdscr.addstr(y, 35, f"Idle: {idle_agents}", self.colors['info'])
            y += 1
            
            stdscr.addstr(y, 0, f"Resource Locks: {total_locks}")
            y += 2
            
            # Agent status breakdown
            if agents:
                stdscr.addstr(y, 0, "AGENT STATUS", self.colors['highlight'] | curses.A_BOLD)
                y += 1
                
                status_counts = {}
                for agent_info in agents.values():
                    status = agent_info['status']
                    status_counts[status] = status_counts.get(status, 0) + 1
                
                for status, count in status_counts.items():
                    color = self._get_status_color(status)
                    stdscr.addstr(y, 0, f"  {status.upper()}: {count}", color)
                    y += 1
                
                y += 1
            
            # Recent activity
            stdscr.addstr(y, 0, "RECENT ACTIVITY", self.colors['highlight'] | curses.A_BOLD)
            y += 1
            
            # Show active agents and their current tasks
            for agent_id, agent_info in agents.items():
                if agent_info['status'] == 'working':
                    task = agent_info.get('current_task', 'Unknown task')
                    progress = agent_info.get('progress', 0.0)
                    progress_bar = self._make_progress_bar(progress, 20)
                    
                    if y < start_y + height - 1:
                        stdscr.addstr(y, 0, f"  {agent_id}: {task[:30]}")
                        if y + 1 < start_y + height - 1:
                            stdscr.addstr(y + 1, 4, progress_bar)
                            stdscr.addstr(y + 1, 26, f"{progress:.1%}")
                        y += 2
            
        except Exception as e:
            stdscr.addstr(start_y, 0, f"Error loading overview: {str(e)}", self.colors['error'])
    
    def _draw_agents(self, stdscr, start_y, height, width):
        """Draw agents tab."""
        try:
            status = self.coordinator.get_agent_status()
            agents = status.get('agents', {})
            
            y = start_y
            stdscr.addstr(y, 0, "AGENT DETAILS", self.colors['highlight'] | curses.A_BOLD)
            y += 2
            
            # Table header
            header = f"{'ID':<15} {'Type':<12} {'Status':<10} {'Task':<25} {'Progress':<10}"
            stdscr.addstr(y, 0, header, curses.A_BOLD)
            y += 1
            stdscr.addstr(y, 0, "─" * min(width, len(header)))
            y += 1
            
            # Agent rows
            for agent_id, agent_info in agents.items():
                if y >= start_y + height - 1:
                    break
                
                agent_type = agent_info.get('agent_type', 'Unknown')[:11]
                status_val = agent_info.get('status', 'unknown')
                task = agent_info.get('current_task', 'No task')[:24]
                progress = agent_info.get('progress', 0.0)
                
                # Truncate long agent IDs
                display_id = agent_id[:14]
                
                color = self._get_status_color(status_val)
                
                row = f"{display_id:<15} {agent_type:<12} {status_val:<10} {task:<25} {progress:.1%}"
                stdscr.addstr(y, 0, row, color)
                y += 1
                
                # Show additional details for selected agent
                if agent_id == self.selected_agent:
                    details = [
                        f"  Worktree: {agent_info.get('worktree_path', 'N/A')}",
                        f"  Started: {agent_info.get('start_time', 'Unknown')}",
                        f"  Last seen: {agent_info.get('last_heartbeat', 'Unknown')}"
                    ]
                    
                    for detail in details:
                        if y < start_y + height - 1:
                            stdscr.addstr(y, 0, detail, self.colors['info'])
                            y += 1
                    y += 1
            
        except Exception as e:
            stdscr.addstr(start_y, 0, f"Error loading agents: {str(e)}", self.colors['error'])
    
    def _draw_resources(self, stdscr, start_y, height, width):
        """Draw resources tab."""
        try:
            status = self.coordinator.get_agent_status()
            locks = status.get('active_locks', {})
            
            y = start_y
            stdscr.addstr(y, 0, "RESOURCE LOCKS", self.colors['highlight'] | curses.A_BOLD)
            y += 2
            
            if not locks:
                stdscr.addstr(y, 0, "No active resource locks", self.colors['info'])
                return
            
            # Table header
            header = f"{'Resource':<40} {'Locked By':<15} {'Type':<6} {'Duration':<10}"
            stdscr.addstr(y, 0, header, curses.A_BOLD)
            y += 1
            stdscr.addstr(y, 0, "─" * min(width, len(header)))
            y += 1
            
            # Lock rows
            for resource_path, lock_info in locks.items():
                if y >= start_y + height - 1:
                    break
                
                resource = resource_path[-39:] if len(resource_path) > 39 else resource_path
                locked_by = lock_info.get('locked_by', 'Unknown')[:14]
                lock_type = lock_info.get('lock_type', 'unknown')
                
                # Calculate duration
                lock_time_str = lock_info.get('lock_time', '')
                try:
                    lock_time = datetime.fromisoformat(lock_time_str.replace('Z', '+00:00'))
                    duration = datetime.now() - lock_time
                    duration_str = str(duration).split('.')[0]  # Remove microseconds
                except:
                    duration_str = "Unknown"
                
                row = f"{resource:<40} {locked_by:<15} {lock_type:<6} {duration_str:<10}"
                stdscr.addstr(y, 0, row)
                y += 1
            
        except Exception as e:
            stdscr.addstr(start_y, 0, f"Error loading resources: {str(e)}", self.colors['error'])
    
    def _draw_conflicts(self, stdscr, start_y, height, width):
        """Draw conflicts tab."""
        try:
            conflicts = self.coordinator.detect_conflicts()
            
            y = start_y
            stdscr.addstr(y, 0, "CONFLICT DETECTION", self.colors['highlight'] | curses.A_BOLD)
            y += 2
            
            if not conflicts:
                stdscr.addstr(y, 0, "No conflicts detected", self.colors['success'])
                return
            
            for conflict in conflicts:
                if y >= start_y + height - 1:
                    break
                
                conflict_type = conflict.get('type', 'unknown')
                severity = conflict.get('severity', 'unknown')
                
                # Color based on severity
                if severity == 'high':
                    color = self.colors['error']
                elif severity == 'medium':
                    color = self.colors['warning']
                else:
                    color = self.colors['info']
                
                stdscr.addstr(y, 0, f"[{severity.upper()}] {conflict_type}", color | curses.A_BOLD)
                y += 1
                
                # Show conflict details
                if conflict_type == 'file_conflict':
                    file_path = conflict.get('file_path', 'Unknown')
                    agents = conflict.get('agents', [])
                    stdscr.addstr(y, 2, f"File: {file_path}")
                    y += 1
                    stdscr.addstr(y, 2, f"Agents: {', '.join(agents)}")
                    y += 1
                
                elif conflict_type == 'stale_lock':
                    resource = conflict.get('resource_path', 'Unknown')
                    locked_by = conflict.get('locked_by', 'Unknown')
                    age = conflict.get('lock_age', 'Unknown')
                    stdscr.addstr(y, 2, f"Resource: {resource}")
                    y += 1
                    stdscr.addstr(y, 2, f"Locked by: {locked_by} (age: {age})")
                    y += 1
                
                elif conflict_type == 'unresponsive_agent':
                    agent_id = conflict.get('agent_id', 'Unknown')
                    last_seen = conflict.get('last_seen', 'Unknown')
                    stdscr.addstr(y, 2, f"Agent: {agent_id}")
                    y += 1
                    stdscr.addstr(y, 2, f"Last seen: {last_seen} ago")
                    y += 1
                
                y += 1
            
        except Exception as e:
            stdscr.addstr(start_y, 0, f"Error loading conflicts: {str(e)}", self.colors['error'])
    
    def _draw_logs(self, stdscr, start_y, height, width):
        """Draw logs tab."""
        y = start_y
        stdscr.addstr(y, 0, "COORDINATION LOGS", self.colors['highlight'] | curses.A_BOLD)
        y += 2
        
        try:
            # Read recent log entries
            log_file = Path(self.workspace_path) / ".claude" / "logs" / "coordinator.log"
            if log_file.exists():
                with open(log_file, 'r') as f:
                    lines = f.readlines()
                
                # Show last N lines that fit on screen
                display_lines = lines[-(height-3):]
                
                for line in display_lines:
                    if y >= start_y + height - 1:
                        break
                    
                    # Truncate long lines
                    display_line = line.strip()[:width-1]
                    
                    # Color based on log level
                    color = self.colors['info']
                    if 'ERROR' in line:
                        color = self.colors['error']
                    elif 'WARNING' in line:
                        color = self.colors['warning']
                    elif 'INFO' in line:
                        color = self.colors['success']
                    
                    stdscr.addstr(y, 0, display_line, color)
                    y += 1
            else:
                stdscr.addstr(y, 0, "No log file found", self.colors['info'])
                
        except Exception as e:
            stdscr.addstr(start_y, 0, f"Error loading logs: {str(e)}", self.colors['error'])
    
    def _draw_footer(self, stdscr, y, width):
        """Draw footer with controls."""
        controls = "Tab: Switch tabs | Q: Quit | R: Refresh | ↑↓: Scroll"
        stdscr.addstr(y, 0, "─" * width)
        if len(controls) < width:
            stdscr.addstr(y, 0, controls, self.colors['info'])
    
    def _handle_input(self, key):
        """Handle keyboard input."""
        if key == ord('q') or key == ord('Q'):
            self.running = False
        elif key == ord('\t') or key == curses.KEY_RIGHT:
            self.current_tab = (self.current_tab + 1) % len(self.tabs)
        elif key == curses.KEY_LEFT:
            self.current_tab = (self.current_tab - 1) % len(self.tabs)
        elif key == ord('r') or key == ord('R'):
            # Force refresh
            pass
        elif key == curses.KEY_UP:
            self.scroll_offset = max(0, self.scroll_offset - 1)
        elif key == curses.KEY_DOWN:
            self.scroll_offset += 1
    
    def _get_status_color(self, status: str):
        """Get color for agent status."""
        status_lower = status.lower()
        if status_lower in ['working', 'active']:
            return self.colors['success']
        elif status_lower in ['failed', 'error']:
            return self.colors['error']
        elif status_lower in ['blocked', 'warning']:
            return self.colors['warning']
        elif status_lower in ['idle', 'completed']:
            return self.colors['info']
        else:
            return curses.A_NORMAL
    
    def _make_progress_bar(self, progress: float, width: int = 20) -> str:
        """Create a text progress bar."""
        filled = int(progress * width)
        bar = "█" * filled + "░" * (width - filled)
        return f"[{bar}]"


def main():
    """Main entry point."""
    import argparse
    
    parser = argparse.ArgumentParser(description="Claude Code Agent Dashboard")
    parser.add_argument("--workspace", default="/workspace", help="Workspace path")
    parser.add_argument("--interval", type=int, default=2, help="Update interval in seconds")
    
    args = parser.parse_args()
    
    try:
        dashboard = AgentDashboard(args.workspace)
        dashboard.update_interval = args.interval
        print("Starting Agent Dashboard... (Press Q to quit)")
        time.sleep(1)
        dashboard.run()
    except KeyboardInterrupt:
        print("\nDashboard stopped.")
    except Exception as e:
        print(f"Error: {e}")
        sys.exit(1)


if __name__ == "__main__":
    main()