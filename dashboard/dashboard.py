#!/usr/bin/env python3
"""
MRST Geomechanical Simulation Dashboard - Complete Workflow

Single file that handles:
1. MRST simulation execution (generates real data)
2. Interactive dashboard launch (visualizes results)

Usage:
    streamlit run dashboard.py

Or for command line launcher:
    python dashboard.py
"""

import sys
import subprocess
from pathlib import Path

# Check if running as script (python dashboard.py) or as streamlit app
if __name__ == "__main__" and "streamlit" not in sys.modules:
    # Running as script - launch streamlit as persistent service
    print("🚀 Launching MRST Dashboard...")
    print("🌐 Dashboard will be available at: http://localhost:8501")
    print("💡 Press Ctrl+C to stop the service")
    print("🔄 Starting persistent service...")
    
    try:
        # Launch streamlit with persistent settings
        result = subprocess.run([
            "streamlit", "run", __file__,
            "--server.port", "8501",
            "--server.address", "0.0.0.0",
            "--server.headless", "true",
            "--server.enableCORS", "false",
            "--server.enableXsrfProtection", "false",
            "--browser.gatherUsageStats", "false"
        ], check=False)
        
        print(f"\n📊 Dashboard service stopped (exit code: {result.returncode})")
        
    except KeyboardInterrupt:
        print("\n👋 Dashboard service stopped by user")
    except Exception as e:
        print(f"❌ Error launching dashboard: {e}")
        print("💡 Solutions:")
        print("   - Try: pip install streamlit")
        print("   - Or run directly: streamlit run dashboard.py")
    
    sys.exit()

# If we reach here, we're running under streamlit
import streamlit as st
import numpy as np
import time
import yaml

# Add utility modules to path
sys.path.append(str(Path(__file__).parent))

# Dashboard configuration
st.set_page_config(
    page_title="MRST Simulation Dashboard",
    page_icon="🛢️",
    layout="wide",
    initial_sidebar_state="expanded"
)

# ----------------------------------------
# DATA VERIFICATION FUNCTIONS
# ----------------------------------------

def verify_simulation_data():
    """Check which simulation data files are available."""
    data_dir = Path("/workspaces/simulation/data")
    required_files = [
        "initial/initial_conditions.mat",
        "static/static_data.mat", 
        "dynamic/fields/field_arrays.mat",
        "dynamic/wells/well_data.mat",
        "metadata/metadata.mat"
    ]
    
    existing_files = []
    missing_files = []
    
    for file_path in required_files:
        full_path = data_dir / file_path
        if full_path.exists():
            existing_files.append(file_path)
        else:
            missing_files.append(file_path)
    
    return existing_files, missing_files

def get_data_status():
    """Get summary of data availability."""
    existing_files, missing_files = verify_simulation_data()
    
    total_files = len(existing_files) + len(missing_files)
    available_count = len(existing_files)
    
    return {
        'total': total_files,
        'available': available_count,
        'missing': len(missing_files),
        'existing_files': existing_files,
        'missing_files': missing_files,
        'percentage': (available_count / total_files * 100) if total_files > 0 else 0
    }

# ----------------------------------------
# DATA LOADING FUNCTIONS
# ----------------------------------------

def load_simulation_config():
    """Load simulation configuration from YAML file."""
    config_path = Path("/workspaces/simulation/config/reservoir_config.yaml")
    if config_path.exists():
        with open(config_path, 'r') as f:
            return yaml.safe_load(f)
    return None

@st.cache_data
def load_simulation_data():
    """Load MRST simulation data with caching."""
    try:
        # Import data loader
        from util_data_loader import MRSTDataLoader
        
        loader = MRSTDataLoader(data_root="../data")
        dataset = loader.load_complete_dataset()
        
        # Add configuration
        config = load_simulation_config()
        if config:
            dataset['config'] = config
        
        return dataset
        
    except Exception as e:
        st.error(f"Error loading simulation data: {e}")
        return None

# ----------------------------------------
# VISUALIZATION FUNCTIONS
# ----------------------------------------

def create_initial_pressure_map(pressure_data, layer_idx=None, title="Initial Pressure Distribution"):
    """Create pressure map for initial conditions."""
    import plotly.graph_objects as go
    
    # Handle 3D data
    if len(pressure_data.shape) == 3:
        if layer_idx is None:
            layer_idx = pressure_data.shape[0] // 2
        pressure_2d = pressure_data[layer_idx, :, :]
        title = f"{title} - Layer {layer_idx + 1}"
    else:
        pressure_2d = pressure_data
    
    # Create coordinate grids
    nx, ny = pressure_2d.shape[1], pressure_2d.shape[0]
    grid_x = np.linspace(0, nx*164.0, nx+1)
    grid_y = np.linspace(0, ny*164.0, ny+1)
    
    fig = go.Figure(data=go.Heatmap(
        z=pressure_2d,
        x=grid_x[:-1],
        y=grid_y[:-1],
        colorscale="viridis",
        colorbar=dict(title="Pressure (psi)"),
        hovertemplate="<b>Position</b><br>" +
                      "X: %{x:.1f} ft<br>" +
                      "Y: %{y:.1f} ft<br>" +
                      "<b>Pressure: %{z:.1f} psi</b><br>" +
                      "<extra></extra>"
    ))
    
    fig.update_layout(
        title=title,
        xaxis_title="X (ft)",
        yaxis_title="Y (ft)",
        template="plotly_white"
    )
    
    return fig

def create_initial_saturation_map(saturation_data, layer_idx=None, title="Initial Water Saturation"):
    """Create saturation map for initial conditions."""
    import plotly.graph_objects as go
    
    # Handle 3D data
    if len(saturation_data.shape) == 3:
        if layer_idx is None:
            layer_idx = saturation_data.shape[0] // 2
        saturation_2d = saturation_data[layer_idx, :, :]
        title = f"{title} - Layer {layer_idx + 1}"
    else:
        saturation_2d = saturation_data
    
    # Create coordinate grids
    nx, ny = saturation_2d.shape[1], saturation_2d.shape[0]
    grid_x = np.linspace(0, nx*164.0, nx+1)
    grid_y = np.linspace(0, ny*164.0, ny+1)
    
    fig = go.Figure(data=go.Heatmap(
        z=saturation_2d,
        x=grid_x[:-1],
        y=grid_y[:-1],
        colorscale="Blues",
        zmin=0, zmax=1,
        colorbar=dict(title="Water Saturation", tickformat=".2f"),
        hovertemplate="<b>Position</b><br>" +
                      "X: %{x:.1f} ft<br>" +
                      "Y: %{y:.1f} ft<br>" +
                      "<b>Sw: %{z:.3f}</b><br>" +
                      "<extra></extra>"
    ))
    
    fig.update_layout(
        title=title,
        xaxis_title="X (ft)",
        yaxis_title="Y (ft)",
        template="plotly_white"
    )
    
    return fig

def create_vertical_profile(data_3d, depth_data=None, title="Vertical Profile", location=None):
    """Create vertical profile plot for 3D data."""
    import plotly.graph_objects as go
    
    if len(data_3d.shape) != 3:
        return None
    
    nz, ny, nx = data_3d.shape
    
    # Use center location if not specified
    if location is None:
        location = (nx // 2, ny // 2)
    
    i, j = location
    profile = data_3d[:, j, i]
    
    # Create depth array if not provided
    if depth_data is None:
        depth_profile = np.linspace(7900, 8138, nz)
    else:
        depth_profile = depth_data[:, j, i]
    
    fig = go.Figure()
    
    fig.add_trace(go.Scatter(
        x=profile,
        y=depth_profile,
        mode='lines+markers',
        line=dict(color='blue', width=2),
        marker=dict(size=8)
    ))
    
    fig.update_layout(
        title=title,
        xaxis_title="Value",
        yaxis_title="Depth (ft)",
        yaxis=dict(autorange='reversed'),
        template="plotly_white",
        height=600
    )
    
    return fig

def create_rock_properties_map(property_data, title="Rock Property"):
    """Create rock property map."""
    import plotly.graph_objects as go
    
    # Handle 3D data - use top layer
    if len(property_data.shape) == 3:
        property_2d = property_data[0, :, :]
    else:
        property_2d = property_data
    
    nx, ny = property_2d.shape[1], property_2d.shape[0]
    grid_x = np.linspace(0, nx*164.0, nx+1)
    grid_y = np.linspace(0, ny*164.0, ny+1)
    
    fig = go.Figure(data=go.Heatmap(
        z=property_2d,
        x=grid_x[:-1],
        y=grid_y[:-1],
        colorscale="Viridis",
        colorbar=dict(title=title)
    ))
    
    fig.update_layout(
        title=title,
        xaxis_title="X (ft)",
        yaxis_title="Y (ft)",
        template="plotly_white"
    )
    
    return fig

# ----------------------------------------
# DASHBOARD INTERFACE
# ----------------------------------------

def show_data_status():
    """Show data availability status."""
    st.header("📊 MRST Simulation Data Status")
    
    # Get data status
    data_status = get_data_status()
    
    # Show overall status
    col1, col2, col3 = st.columns(3)
    
    with col1:
        st.metric(
            "📁 Data Files", 
            f"{data_status['available']}/{data_status['total']}", 
            f"{data_status['percentage']:.1f}% available"
        )
    
    with col2:
        if data_status['available'] == data_status['total']:
            st.success("✅ All data available")
        elif data_status['available'] > 0:
            st.warning("⚠️ Partial data available")
        else:
            st.error("❌ No data found")
    
    with col3:
        if data_status['available'] > 0:
            if st.button("📊 View Dashboard", type="primary"):
                st.session_state['show_dashboard'] = True
                st.rerun()
    
    # Show detailed file status
    st.subheader("📋 File Details")
    
    if data_status['existing_files']:
        st.success(f"✅ Available files ({len(data_status['existing_files'])}):")
        for file_path in data_status['existing_files']:
            full_path = Path("/workspaces/simulation/data") / file_path
            file_size = full_path.stat().st_size / 1024  # KB
            st.text(f"  📁 {file_path} ({file_size:.1f} KB)")
    
    if data_status['missing_files']:
        st.error(f"❌ Missing files ({len(data_status['missing_files'])}):")
        for file_path in data_status['missing_files']:
            st.text(f"  📁 {file_path}")
        
        st.info("💡 To generate simulation data:")
        st.code("""
# Navigate to MRST scripts directory
cd ../mrst_simulation_scripts/

# Run MRST simulation
octave --eval "s99_run_workflow"
        """)
    
    return data_status['available'] > 0

def show_dashboard():
    """Show the main dashboard interface."""
    st.title("🛢️ MRST Simulation Dashboard")
    
    # Load data
    with st.spinner("Loading simulation data..."):
        data = load_simulation_data()
    
    if data is None:
        st.error("❌ Failed to load simulation data")
        return
    
    # Sidebar navigation
    st.sidebar.header("📊 Dashboard Sections")
    
    sections = [
        "📊 Initial Conditions",
        "🏔️ Rock Properties", 
        "📈 Dynamic Fields",
        "🛢️ Well Performance",
        "⚙️ Configuration"
    ]
    
    selected_section = st.sidebar.radio("Select section:", sections)
    
    # Show selected section
    if selected_section == "📊 Initial Conditions":
        show_initial_conditions(data)
    elif selected_section == "🏔️ Rock Properties":
        show_rock_properties(data)
    elif selected_section == "📈 Dynamic Fields":
        show_dynamic_fields(data)
    elif selected_section == "🛢️ Well Performance":
        show_well_performance(data)
    elif selected_section == "⚙️ Configuration":
        show_configuration(data)

def show_initial_conditions(data):
    """Show initial conditions section."""
    st.header("📊 Initial Conditions")
    
    if 'initial_conditions' not in data or data['initial_conditions'] is None:
        st.error("❌ Initial conditions data not available")
        return
    
    initial_data = data['initial_conditions']
    
    # Check if 3D data
    is_3d = len(initial_data['pressure'].shape) == 3
    
    # Layer selection for 3D data
    layer_idx = None
    if is_3d:
        nz = initial_data['pressure'].shape[0]
        layer_idx = st.slider("Select Layer", 0, nz-1, nz//2)
    
    # Tabs for different plots
    tab1, tab2 = st.tabs(["🌡️ Pressure", "💧 Saturation"])
    
    with tab1:
        fig = create_initial_pressure_map(
            initial_data['pressure'], 
            layer_idx=layer_idx
        )
        st.plotly_chart(fig, use_container_width=True)
        
        # Statistics
        pressure_data = initial_data['pressure']
        if is_3d and layer_idx is not None:
            pressure_data = pressure_data[layer_idx, :, :]
        
        col1, col2, col3, col4 = st.columns(4)
        with col1:
            st.metric("Min Pressure", f"{np.min(pressure_data):.1f} psi")
        with col2:
            st.metric("Max Pressure", f"{np.max(pressure_data):.1f} psi")
        with col3:
            st.metric("Mean Pressure", f"{np.mean(pressure_data):.1f} psi")
        with col4:
            st.metric("Std Dev", f"{np.std(pressure_data):.1f} psi")
        
        # Vertical profile for 3D data
        if is_3d:
            st.subheader("📐 Vertical Pressure Profile")
            depth_data = initial_data.get('depth', None)
            fig_profile = create_vertical_profile(
                initial_data['pressure'], 
                depth_data=depth_data,
                title="Pressure vs Depth"
            )
            if fig_profile:
                st.plotly_chart(fig_profile, use_container_width=True)
    
    with tab2:
        fig = create_initial_saturation_map(
            initial_data['sw'], 
            layer_idx=layer_idx
        )
        st.plotly_chart(fig, use_container_width=True)
        
        # Statistics
        sw_data = initial_data['sw']
        if is_3d and layer_idx is not None:
            sw_data = sw_data[layer_idx, :, :]
        
        col1, col2, col3, col4 = st.columns(4)
        with col1:
            st.metric("Min Sw", f"{np.min(sw_data):.3f}")
        with col2:
            st.metric("Max Sw", f"{np.max(sw_data):.3f}")
        with col3:
            st.metric("Mean Sw", f"{np.mean(sw_data):.3f}")
        with col4:
            st.metric("Mean So", f"{np.mean(1-sw_data):.3f}")

def show_rock_properties(data):
    """Show rock properties section."""
    st.header("🏔️ Rock Properties")
    
    if 'initial_conditions' not in data:
        st.error("❌ Rock property data not available")
        return
    
    initial_data = data['initial_conditions']
    
    tab1, tab2 = st.tabs(["🔹 Porosity", "🔸 Permeability"])
    
    with tab1:
        fig = create_rock_properties_map(initial_data['phi'], "Porosity")
        st.plotly_chart(fig, use_container_width=True)
        
        col1, col2, col3, col4 = st.columns(4)
        with col1:
            st.metric("Min φ", f"{np.min(initial_data['phi']):.3f}")
        with col2:
            st.metric("Max φ", f"{np.max(initial_data['phi']):.3f}")
        with col3:
            st.metric("Mean φ", f"{np.mean(initial_data['phi']):.3f}")
        with col4:
            st.metric("Std φ", f"{np.std(initial_data['phi']):.3f}")
    
    with tab2:
        fig = create_rock_properties_map(initial_data['k'], "Permeability (mD)")
        st.plotly_chart(fig, use_container_width=True)
        
        col1, col2, col3, col4 = st.columns(4)
        with col1:
            st.metric("Min k", f"{np.min(initial_data['k']):.1f} mD")
        with col2:
            st.metric("Max k", f"{np.max(initial_data['k']):.1f} mD")
        with col3:
            st.metric("Mean k", f"{np.mean(initial_data['k']):.1f} mD")
        with col4:
            geom_mean = np.exp(np.mean(np.log(initial_data['k'][initial_data['k'] > 0])))
            st.metric("Geom Mean k", f"{geom_mean:.1f} mD")

def show_dynamic_fields(data):
    """Show dynamic fields section."""
    st.header("📈 Dynamic Fields")
    
    if 'field_arrays' not in data or data['field_arrays'] is None:
        st.error("❌ Dynamic field data not available")
        return
    
    st.info("🚧 Dynamic fields visualization coming soon...")
    st.text("This section will show time-dependent pressure and saturation evolution")

def show_well_performance(data):
    """Show well performance section."""
    st.header("🛢️ Well Performance")
    
    if 'well_data' not in data or data['well_data'] is None:
        st.error("❌ Well performance data not available")
        return
    
    st.info("🚧 Well performance analysis coming soon...")
    st.text("This section will show production rates and cumulative volumes")

def show_configuration(data):
    """Show configuration section."""
    st.header("⚙️ Simulation Configuration")
    
    if 'config' not in data or data['config'] is None:
        st.error("❌ Configuration data not available")
        return
    
    config = data['config']
    
    # Grid information
    st.subheader("🏗️ Grid Configuration")
    grid_config = config.get('grid', {})
    
    col1, col2, col3 = st.columns(3)
    with col1:
        st.metric("Grid X", f"{grid_config.get('nx', 'N/A')}")
    with col2:
        st.metric("Grid Y", f"{grid_config.get('ny', 'N/A')}")
    with col3:
        st.metric("Grid Z", f"{grid_config.get('nz', 'N/A')}")
    
    # Show configuration as expandable sections
    st.subheader("📋 Configuration Details")
    
    for section_name, section_data in config.items():
        if isinstance(section_data, dict):
            with st.expander(f"📁 {section_name.title()}"):
                st.json(section_data)

# ----------------------------------------
# MAIN APPLICATION
# ----------------------------------------

def main():
    """Main application logic."""
    
    # Initialize session state
    if 'show_dashboard' not in st.session_state:
        st.session_state['show_dashboard'] = False
    
    # Check if we should show dashboard or data status
    data_status = get_data_status()
    
    if data_status['available'] > 0 and st.session_state.get('show_dashboard', False):
        # Show main dashboard
        show_dashboard()
    else:
        # Show data status first
        st.title("🛢️ MRST Simulation Dashboard")
        st.markdown("**Data-driven reservoir visualization**")
        
        # Reset dashboard flag if we're back to status
        if 'show_dashboard' in st.session_state:
            del st.session_state['show_dashboard']
        
        # Show data status and availability
        data_available = show_data_status()
        
        # Auto-launch dashboard if data is available
        if data_available and data_status['available'] == data_status['total']:
            st.success("🎉 All simulation data available!")
            st.info("👆 Click 'View Dashboard' button above to start visualization")
        elif data_available:
            st.warning("⚠️ Some data files are missing, but partial visualization is available")
            st.info("👆 Click 'View Dashboard' button above for available visualizations")

if __name__ == "__main__":
    main()