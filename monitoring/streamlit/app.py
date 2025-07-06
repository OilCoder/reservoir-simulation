#!/usr/bin/env python3
"""
Simple MRST Monitoring Dashboard

A clean, simple dashboard that displays 3 types of monitoring plots:
1. Evolution plots - How properties change over time
2. Spatial maps - Current distribution of properties
3. Wells performance - Well monitoring (placeholder)
"""

import streamlit as st
import os
from pathlib import Path
import subprocess
import time


# ----
# Page Configuration
# ----

st.set_page_config(
    page_title="MRST Monitor",
    page_icon="🛢️",
    layout="wide",
    initial_sidebar_state="expanded"
)

# ----
# Helper Functions
# ----

def run_plot_script(script_name):
    """Run a plot generation script"""
    script_path = Path(__file__).parent.parent / "plot_scripts" / script_name
    
    if not script_path.exists():
        st.error(f"Script not found: {script_path}")
        return False
    
    try:
        with st.spinner(f"Generating {script_name}..."):
            result = subprocess.run(
                ["python", str(script_path)], 
                capture_output=True, 
                text=True,
                timeout=30
            )
        
        if result.returncode == 0:
            st.success(f"✅ {script_name} completed")
            return True
        else:
            st.error(f"❌ {script_name} failed: {result.stderr}")
            return False
            
    except subprocess.TimeoutExpired:
        st.error(f"❌ {script_name} timed out")
        return False
    except Exception as e:
        st.error(f"❌ Error running {script_name}: {e}")
        return False


def get_plot_path(plot_name):
    """Get path to generated plot"""
    return Path(__file__).parent.parent / "plots" / f"{plot_name}.png"


def plot_exists(plot_name):
    """Check if plot file exists"""
    return get_plot_path(plot_name).exists()


def get_plot_age(plot_name):
    """Get age of plot file in minutes"""
    plot_path = get_plot_path(plot_name)
    if not plot_path.exists():
        return None
    
    age_seconds = time.time() - plot_path.stat().st_mtime
    return age_seconds / 60  # Convert to minutes


# ----
# Main Dashboard
# ----

def main():
    """Main dashboard function"""
    
    # Header
    st.title("🛢️ MRST Geomechanical Monitoring")
    st.markdown("**Simple dashboard for MRST simulation monitoring**")
    
    # Sidebar controls
    st.sidebar.title("📊 Controls")
    
    # Auto-refresh toggle
    auto_refresh = st.sidebar.checkbox("Auto-refresh plots", value=False)
    if auto_refresh:
        st.sidebar.info("Dashboard will refresh every 30 seconds")
    
    # Manual refresh button
    if st.sidebar.button("🔄 Refresh All Plots"):
        refresh_all_plots()
    
    # Individual plot generation
    st.sidebar.markdown("### Generate Individual Plots")
    
    col1, col2, col3 = st.sidebar.columns(3)
    
    with col1:
        if st.button("📈"):
            run_plot_script("plot_evolution.py")
    
    with col2:
        if st.button("🗺️"):
            run_plot_script("plot_maps.py")
    
    with col3:
        if st.button("🏭"):
            run_plot_script("plot_wells.py")
    
    # Plot status
    st.sidebar.markdown("### Plot Status")
    show_plot_status()
    
    # Main content area
    show_plots()
    
    # Auto-refresh logic
    if auto_refresh:
        time.sleep(30)
        st.rerun()


def refresh_all_plots():
    """Refresh all plots"""
    st.info("🔄 Refreshing all plots...")
    
    scripts = ["plot_evolution.py", "plot_maps.py", "plot_wells.py"]
    
    for script in scripts:
        run_plot_script(script)
    
    st.success("✅ All plots refreshed!")


def show_plot_status():
    """Show status of all plots"""
    
    plots = [
        ("evolution", "📈 Evolution"),
        ("maps", "🗺️ Maps"),
        ("wells", "🏭 Wells")
    ]
    
    for plot_name, display_name in plots:
        if plot_exists(plot_name):
            age = get_plot_age(plot_name)
            if age < 5:
                st.sidebar.success(f"{display_name}: Fresh ({age:.1f}m)")
            elif age < 30:
                st.sidebar.info(f"{display_name}: Recent ({age:.1f}m)")
            else:
                st.sidebar.warning(f"{display_name}: Old ({age:.1f}m)")
        else:
            st.sidebar.error(f"{display_name}: Missing")


def show_plots():
    """Display all generated plots"""
    
    # Create tabs for different plot types
    tab1, tab2, tab3 = st.tabs(["📈 Evolution", "🗺️ Spatial Maps", "🏭 Wells"])
    
    # ----
    # Tab 1: Evolution Plots
    # ----
    with tab1:
        st.header("📈 Reservoir Evolution")
        st.markdown("Shows how reservoir properties change over time")
        
        if plot_exists("evolution"):
            st.image(str(get_plot_path("evolution")), 
                    caption="Temporal evolution of reservoir properties",
                    use_column_width=True)
        else:
            st.warning("Evolution plot not available. Click 📈 to generate.")
            st.info("This plot shows pressure, stress, porosity, and permeability evolution over 50 timesteps.")
    
    # ----
    # Tab 2: Spatial Maps
    # ----
    with tab2:
        st.header("🗺️ Spatial Distribution")
        st.markdown("Shows current spatial distribution of properties (20x20 grid)")
        
        if plot_exists("maps"):
            st.image(str(get_plot_path("maps")), 
                    caption="Spatial distribution maps from latest simulation timestep",
                    use_column_width=True)
        else:
            st.warning("Spatial maps not available. Click 🗺️ to generate.")
            st.info("This plot shows 6 maps: pressure, stress, porosity, permeability, water saturation, and rock regions.")
    
    # ----
    # Tab 3: Wells Performance
    # ----
    with tab3:
        st.header("🏭 Wells Performance")
        st.markdown("Shows well performance metrics (currently placeholder)")
        
        if plot_exists("wells"):
            st.image(str(get_plot_path("wells")), 
                    caption="Well performance plots (placeholder data)",
                    use_column_width=True)
        else:
            st.warning("Wells plot not available. Click 🏭 to generate.")
            st.info("This plot shows BHP, production rates, cumulative production, and water cut (placeholder data).")
    
    # ----
    # Footer Information
    # ----
    st.markdown("---")
    st.markdown("### 📊 Data Source")
    st.info("Plots are generated from simulation snapshots in `MRST_simulation_scripts/data/`")
    
    # Show data info
    data_path = Path(__file__).parent.parent.parent / "MRST_simulation_scripts" / "data"
    if data_path.exists():
        snapshot_files = list(data_path.glob("snap_*.mat"))
        st.markdown(f"**Available snapshots:** {len(snapshot_files)}")
        if snapshot_files:
            latest_file = max(snapshot_files, key=lambda p: p.stat().st_mtime)
            latest_timestep = int(latest_file.stem.replace('snap_', ''))
            st.markdown(f"**Latest timestep:** {latest_timestep}")


if __name__ == "__main__":
    main() 