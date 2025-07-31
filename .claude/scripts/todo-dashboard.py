#!/usr/bin/env python3
"""
Interactive TODO Dashboard for Claude Code

Provides a terminal-based dashboard for viewing and managing daily TODO lists
with real-time updates and productivity metrics.
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
    from todo_manager import TodoManager
except ImportError:
    print("Error: Could not import todo_manager module")
    sys.exit(1)


class TodoDashboard:
    """Interactive terminal dashboard for TODO management."""
    
    def __init__(self, workspace_path: str = "/workspace"):
        self.workspace_path = workspace_path
        self.manager = TodoManager(workspace_path)
        self.running = False
        self.update_interval = 5  # seconds
        self.last_update = datetime.now()
        
        # Dashboard state
        self.current_tab = 0
        self.tabs = ["Today", "Yesterday", "Week", "Stats", "Settings"]
        self.scroll_offset = 0
        self.selected_item = 0
        
        # Data cache
        self.data_cache = {}
        self.cache_timestamp = None
        
        # Colors
        self.colors = {}
        
    def init_colors(self):
        """Initialize color pairs for terminal display."""
        curses.start_color()
        curses.use_default_colors()
        
        # Define color pairs
        curses.init_pair(1, curses.COLOR_GREEN, -1)    # Completed tasks
        curses.init_pair(2, curses.COLOR_YELLOW, -1)   # In progress tasks
        curses.init_pair(3, curses.COLOR_RED, -1)      # Blocked tasks
        curses.init_pair(4, curses.COLOR_BLUE, -1)     # Pending tasks
        curses.init_pair(5, curses.COLOR_CYAN, -1)     # Headers
        curses.init_pair(6, curses.COLOR_MAGENTA, -1)  # Highlights
        curses.init_pair(7, curses.COLOR_WHITE, curses.COLOR_BLUE)  # Selected
        
        self.colors = {
            'completed': curses.color_pair(1),
            'in_progress': curses.color_pair(2),
            'blocked': curses.color_pair(3),
            'pending': curses.color_pair(4),
            'header': curses.color_pair(5),
            'highlight': curses.color_pair(6),
            'selected': curses.color_pair(7),
            'normal': curses.color_pair(0)
        }
    
    def run(self):
        """Start the dashboard."""
        curses.wrapper(self._main_loop)
    
    def _main_loop(self, stdscr):
        """Main dashboard loop."""
        self.stdscr = stdscr
        self.init_colors()
        
        # Configure screen
        curses.curs_set(0)  # Hide cursor
        stdscr.nodelay(1)   # Non-blocking input
        stdscr.timeout(100) # 100ms timeout
        
        self.running = True
        
        try:
            while self.running:
                # Update data if needed
                if self._should_update_data():
                    self._update_data_cache()
                
                # Clear screen and draw interface
                stdscr.clear()
                self._draw_interface()
                stdscr.refresh()
                
                # Handle input
                key = stdscr.getch()
                self._handle_input(key)
                
                # Small delay
                time.sleep(0.1)
                
        except KeyboardInterrupt:
            pass
        except Exception as e:
            # Log error and exit gracefully
            with open('/workspace/.claude/logs/todo-dashboard.log', 'a') as f:
                f.write(f"[{datetime.now()}] Dashboard error: {e}\n")
        finally:
            self.running = False
    
    def _should_update_data(self) -> bool:
        """Check if data cache needs updating."""
        if not self.cache_timestamp:
            return True
        
        time_since_update = datetime.now() - self.cache_timestamp
        return time_since_update.total_seconds() >= self.update_interval
    
    def _update_data_cache(self):
        """Update cached data from TODO files."""
        try:
            today = datetime.now()
            yesterday = today - timedelta(days=1)
            
            # Get data for different time periods
            self.data_cache = {
                'today': self.manager.get_todo_status(today),
                'yesterday': self.manager.get_todo_status(yesterday),
                'week': self._get_week_stats(),
                'stats': self._get_productivity_stats()
            }
            
            self.cache_timestamp = datetime.now()
            
        except Exception as e:
            # Log error but continue
            with open('/workspace/.claude/logs/todo-dashboard.log', 'a') as f:
                f.write(f"[{datetime.now()}] Cache update error: {e}\n")
    
    def _get_week_stats(self) -> Dict[str, Any]:
        """Get statistics for the current week."""
        today = datetime.now()
        week_stats = {
            'days': [],
            'total_tasks': 0,
            'total_completed': 0,
            'avg_completion_rate': 0.0
        }
        
        for i in range(7):
            date = today - timedelta(days=i)
            status = self.manager.get_todo_status(date)
            
            day_info = {
                'date': date.strftime('%Y-%m-%d'),
                'day_name': date.strftime('%a'),
                'exists': status.get('exists', False),
                'stats': status.get('stats', {})
            }
            
            week_stats['days'].append(day_info)
            
            if status.get('exists') and 'stats' in status:
                stats = status['stats']
                week_stats['total_tasks'] += stats.get('total', 0)
                week_stats['total_completed'] += stats.get('completed', 0)
        
        # Calculate average completion rate
        if week_stats['total_tasks'] > 0:
            week_stats['avg_completion_rate'] = round(
                (week_stats['total_completed'] / week_stats['total_tasks']) * 100, 1
            )
        
        return week_stats
    
    def _get_productivity_stats(self) -> Dict[str, Any]:
        """Get productivity statistics."""
        # This would be expanded with more sophisticated analytics
        return {
            'streak_days': 0,  # Days with >80% completion
            'most_productive_day': 'N/A',
            'avg_tasks_per_day': 0.0,
            'completion_trend': 'stable'
        }
    
    def _draw_interface(self):
        """Draw the main dashboard interface."""
        height, width = self.stdscr.getmaxyx()
        
        # Draw title
        title = "Claude Code TODO Dashboard"
        self.stdscr.addstr(0, (width - len(title)) // 2, title, 
                          self.colors['header'] | curses.A_BOLD)
        
        # Draw current time
        time_str = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
        self.stdscr.addstr(0, width - len(time_str) - 1, time_str, self.colors['normal'])
        
        # Draw tab bar
        self._draw_tab_bar(2, width)
        
        # Draw content based on current tab
        content_start_y = 4
        content_height = height - content_start_y - 2
        
        if self.current_tab == 0:  # Today
            self._draw_today_tab(content_start_y, width, content_height)
        elif self.current_tab == 1:  # Yesterday
            self._draw_yesterday_tab(content_start_y, width, content_height)
        elif self.current_tab == 2:  # Week
            self._draw_week_tab(content_start_y, width, content_height)
        elif self.current_tab == 3:  # Stats
            self._draw_stats_tab(content_start_y, width, content_height)
        elif self.current_tab == 4:  # Settings
            self._draw_settings_tab(content_start_y, width, content_height)
        
        # Draw help bar
        self._draw_help_bar(height - 1, width)
    
    def _draw_tab_bar(self, y: int, width: int):
        """Draw the tab navigation bar."""
        tab_width = width // len(self.tabs)
        
        for i, tab_name in enumerate(self.tabs):
            x_start = i * tab_width
            tab_text = f" {tab_name} "
            
            # Center tab text
            x_pos = x_start + (tab_width - len(tab_text)) // 2
            
            if i == self.current_tab:
                self.stdscr.addstr(y, x_pos, tab_text, 
                                  self.colors['selected'] | curses.A_BOLD)
            else:
                self.stdscr.addstr(y, x_pos, tab_text, self.colors['header'])
    
    def _draw_today_tab(self, start_y: int, width: int, height: int):
        """Draw today's TODO tab."""
        data = self.data_cache.get('today', {})
        
        if not data.get('exists'):
            self.stdscr.addstr(start_y + 2, 2, "No TODO file for today", self.colors['normal'])
            self.stdscr.addstr(start_y + 3, 2, "Press 'c' to create today's TODO file", 
                              self.colors['highlight'])
            return
        
        # Draw summary
        stats = data.get('stats', {})
        summary = data.get('summary', 'No summary available')
        
        self.stdscr.addstr(start_y, 2, f"📅 Today's Summary: {summary}", 
                          self.colors['header'] | curses.A_BOLD)
        
        # Draw progress bar
        if stats.get('total', 0) > 0:
            completion_rate = stats.get('completion_rate', 0)
            self._draw_progress_bar(start_y + 2, 2, width - 4, completion_rate)
        
        # Draw task breakdown
        y_offset = start_y + 4
        
        task_types = [
            ('✅ Completed', stats.get('completed', 0), 'completed'),
            ('🔄 In Progress', stats.get('in_progress', 0), 'in_progress'),
            ('⏳ Pending', stats.get('pending', 0), 'pending'),
            ('🚫 Blocked', stats.get('blocked', 0), 'blocked')
        ]
        
        for label, count, color_key in task_types:
            if count > 0:
                self.stdscr.addstr(y_offset, 4, f"{label}: {count}", 
                                  self.colors[color_key])
                y_offset += 1
        
        # Show file path
        file_path = data.get('file_path', '')
        if file_path:
            self.stdscr.addstr(height - 2, 2, f"File: {file_path}", 
                              self.colors['normal'] | curses.A_DIM)
    
    def _draw_yesterday_tab(self, start_y: int, width: int, height: int):
        """Draw yesterday's TODO tab."""
        data = self.data_cache.get('yesterday', {})
        
        if not data.get('exists'):
            self.stdscr.addstr(start_y + 2, 2, "No TODO file for yesterday", self.colors['normal'])
            return
        
        # Similar to today tab but for yesterday
        stats = data.get('stats', {})
        summary = data.get('summary', 'No summary available')
        
        self.stdscr.addstr(start_y, 2, f"📅 Yesterday's Summary: {summary}", 
                          self.colors['header'] | curses.A_BOLD)
        
        # Show rollover candidates
        rollover_count = stats.get('pending', 0) + stats.get('in_progress', 0)
        if rollover_count > 0:
            self.stdscr.addstr(start_y + 2, 2, 
                              f"🔄 {rollover_count} tasks available for rollover", 
                              self.colors['highlight'])
            self.stdscr.addstr(start_y + 3, 2, "Press 'r' to rollover to today", 
                              self.colors['normal'])
    
    def _draw_week_tab(self, start_y: int, width: int, height: int):
        """Draw weekly overview tab."""
        data = self.data_cache.get('week', {})
        
        self.stdscr.addstr(start_y, 2, "📊 Weekly Overview", 
                          self.colors['header'] | curses.A_BOLD)
        
        # Weekly stats
        total_tasks = data.get('total_tasks', 0)
        total_completed = data.get('total_completed', 0)
        avg_completion = data.get('avg_completion_rate', 0)
        
        self.stdscr.addstr(start_y + 2, 4, f"Total tasks this week: {total_tasks}", 
                          self.colors['normal'])
        self.stdscr.addstr(start_y + 3, 4, f"Completed: {total_completed}", 
                          self.colors['completed'])
        self.stdscr.addstr(start_y + 4, 4, f"Average completion rate: {avg_completion}%", 
                          self.colors['highlight'])
        
        # Daily breakdown
        y_offset = start_y + 6
        self.stdscr.addstr(y_offset, 4, "Daily Breakdown:", 
                          self.colors['header'])
        y_offset += 1
        
        for day_info in data.get('days', [])[:7]:  # Last 7 days
            day_name = day_info.get('day_name', 'N/A')
            exists = day_info.get('exists', False)
            stats = day_info.get('stats', {})
            
            if exists:
                completed = stats.get('completed', 0)
                total = stats.get('total', 0)
                rate = stats.get('completion_rate', 0)
                status_text = f"{day_name}: {completed}/{total} ({rate}%)"
            else:
                status_text = f"{day_name}: No TODO file"
            
            self.stdscr.addstr(y_offset, 6, status_text, self.colors['normal'])
            y_offset += 1
            
            if y_offset >= start_y + height - 2:
                break
    
    def _draw_stats_tab(self, start_y: int, width: int, height: int):
        """Draw statistics tab."""
        self.stdscr.addstr(start_y, 2, "📈 Productivity Statistics", 
                          self.colors['header'] | curses.A_BOLD)
        
        self.stdscr.addstr(start_y + 2, 4, "Advanced statistics coming soon...", 
                          self.colors['normal'])
        
        # Placeholder for future analytics
        stats_items = [
            "• Task completion trends",
            "• Most productive time periods",
            "• Focus area analysis",
            "• Productivity streaks",
            "• Goal achievement rates"
        ]
        
        for i, item in enumerate(stats_items):
            self.stdscr.addstr(start_y + 4 + i, 6, item, self.colors['normal'])
    
    def _draw_settings_tab(self, start_y: int, width: int, height: int):
        """Draw settings tab."""
        self.stdscr.addstr(start_y, 2, "⚙️ Dashboard Settings", 
                          self.colors['header'] | curses.A_BOLD)
        
        settings_items = [
            f"Update interval: {self.update_interval} seconds",
            "Auto-refresh: Enabled",
            "Color scheme: Default",
            "Archive threshold: 30 days"
        ]
        
        for i, item in enumerate(settings_items):
            self.stdscr.addstr(start_y + 2 + i, 4, item, self.colors['normal'])
    
    def _draw_progress_bar(self, y: int, x: int, width: int, percentage: float):
        """Draw a progress bar."""
        bar_width = width - 20  # Leave space for percentage text
        filled_width = int((percentage / 100.0) * bar_width)
        
        # Draw bar background
        self.stdscr.addstr(y, x, "[", self.colors['normal'])
        self.stdscr.addstr(y, x + 1, "=" * filled_width, self.colors['completed'])
        self.stdscr.addstr(y, x + 1 + filled_width, "-" * (bar_width - filled_width), 
                          self.colors['normal'])
        self.stdscr.addstr(y, x + bar_width + 1, "]", self.colors['normal'])
        
        # Draw percentage
        percentage_text = f" {percentage:.1f}%"
        self.stdscr.addstr(y, x + bar_width + 3, percentage_text, self.colors['highlight'])
    
    def _draw_help_bar(self, y: int, width: int):
        """Draw help/command bar at bottom."""
        help_text = " Tab: Switch tabs | q: Quit | c: Create | r: Rollover | h: Help "
        
        # Center the help text
        x_pos = (width - len(help_text)) // 2
        self.stdscr.addstr(y, x_pos, help_text, 
                          self.colors['normal'] | curses.A_REVERSE)
    
    def _handle_input(self, key: int):
        """Handle keyboard input."""
        if key == ord('q') or key == ord('Q'):
            self.running = False
        
        elif key == ord('\t') or key == curses.KEY_RIGHT:
            # Next tab
            self.current_tab = (self.current_tab + 1) % len(self.tabs)
        
        elif key == curses.KEY_LEFT:
            # Previous tab
            self.current_tab = (self.current_tab - 1) % len(self.tabs)
        
        elif key == ord('c') or key == ord('C'):
            # Create today's TODO
            self._create_today_todo()
        
        elif key == ord('r') or key == ord('R'):
            # Rollover from yesterday
            self._rollover_from_yesterday()
        
        elif key == ord('h') or key == ord('H'):
            # Show help (could implement help dialog)
            pass
        
        elif key == curses.KEY_UP:
            # Scroll up (for future use)
            if self.scroll_offset > 0:
                self.scroll_offset -= 1
        
        elif key == curses.KEY_DOWN:
            # Scroll down (for future use)
            self.scroll_offset += 1
    
    def _create_today_todo(self):
        """Create today's TODO file."""
        try:
            today = datetime.now()
            success = self.manager.create_daily_todo(today, rollover=True)
            if success:
                # Force data refresh
                self.cache_timestamp = None
        except Exception as e:
            # Log error
            with open('/workspace/.claude/logs/todo-dashboard.log', 'a') as f:
                f.write(f"[{datetime.now()}] Create TODO error: {e}\n")
    
    def _rollover_from_yesterday(self):
        """Rollover tasks from yesterday to today."""
        try:
            today = datetime.now()
            success = self.manager.create_daily_todo(today, rollover=True)
            if success:
                # Force data refresh
                self.cache_timestamp = None
        except Exception as e:
            # Log error
            with open('/workspace/.claude/logs/todo-dashboard.log', 'a') as f:
                f.write(f"[{datetime.now()}] Rollover error: {e}\n")


def main():
    """Main entry point."""
    import argparse
    
    parser = argparse.ArgumentParser(description='Interactive TODO Dashboard')
    parser.add_argument('--workspace', default='/workspace', help='Workspace path')
    parser.add_argument('--auto-launched', action='store_true', 
                       help='Dashboard was auto-launched (internal flag)')
    
    args = parser.parse_args()
    
    # Create and run dashboard
    dashboard = TodoDashboard(args.workspace)
    
    try:
        dashboard.run()
    except Exception as e:
        print(f"Dashboard error: {e}")
        sys.exit(1)


if __name__ == '__main__':
    main()