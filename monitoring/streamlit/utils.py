#!/usr/bin/env python3
"""
Utilities for MRST Monitoring Dashboard

Simple utility functions for the Streamlit dashboard.
"""

from pathlib import Path
import time


def get_data_path():
    """Get path to simulation data directory"""
    return Path("/workspace/data")


def get_plot_path(plot_name):
    """Get path to generated plot"""
    return Path(__file__).parent / f"{plot_name}.png"


def plot_exists(plot_name):
    """Check if plot file exists"""
    return get_plot_path(plot_name).exists()


def get_plot_age_minutes(plot_name):
    """Get age of plot file in minutes"""
    plot_path = get_plot_path(plot_name)
    if not plot_path.exists():
        return None
    
    age_seconds = time.time() - plot_path.stat().st_mtime
    return age_seconds / 60


def count_snapshots():
    """Count available simulation snapshots"""
    data_path = get_data_path()
    snapshots_path = data_path / "snapshots"
    if not snapshots_path.exists():
        return 0
    
    snapshot_files = list(snapshots_path.glob("snap_*.mat"))
    return len(snapshot_files)


def get_latest_timestep():
    """Get the latest simulation timestep"""
    data_path = get_data_path()
    snapshots_path = data_path / "snapshots"
    if not snapshots_path.exists():
        return None
    
    snapshot_files = list(snapshots_path.glob("snap_*.mat"))
    if not snapshot_files:
        return None
    
    latest_file = max(snapshot_files, key=lambda p: p.stat().st_mtime)
    return int(latest_file.stem.replace('snap_', ''))


def format_plot_status(plot_name):
    """Format plot status for display"""
    if not plot_exists(plot_name):
        return "❌ Missing"
    
    age = get_plot_age_minutes(plot_name)
    if age is None:
        return "❌ Error"
    elif age < 5:
        return f"✅ Fresh ({age:.1f}m)"
    elif age < 30:
        return f"ℹ️ Recent ({age:.1f}m)"
    else:
        return f"⚠️ Old ({age:.1f}m)" 