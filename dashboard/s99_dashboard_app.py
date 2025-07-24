#!/usr/bin/env python3
"""
GeomechML Dashboard - Main Streamlit Application
================================================

Main orchestrator for the GeomechML reservoir simulation dashboard.
Automatically launches Streamlit server for data visualization.

This application provides interactive visualization of MRST simulation results
with complete workflow organization and automatic deployment.

Author: GeomechML Team
Date: 2025-07-23
"""

import streamlit as st
import pandas as pd
import sys
import os
import subprocess
from pathlib import Path

# Add current directory to path for imports
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

# Import dashboard components with proper sNN_ naming
from s01_data_loader import DataLoader, ConfigLoader
from s03_overview_page import SimulationOverview
from s06_reservoir_page import ReservoirProperties
from s05_production_page import ProductionPerformance
from s04_pressure_page import PressureEvolution
from s07_export_utils import ExportManager

# Page configuration
st.set_page_config(
    page_title="GeomechML Dashboard",
    page_icon="🗻",
    layout="wide",
    initial_sidebar_state="expanded"
)

# CSS personalizado
st.markdown("""
<style>
    .main-header {
        font-size: 2.5rem;
        font-weight: bold;
        color: #1f77b4;
        text-align: center;
        margin-bottom: 2rem;
    }
    .section-header {
        font-size: 1.5rem;
        font-weight: bold;
        color: #2e7d32;
        margin-top: 2rem;
        margin-bottom: 1rem;
    }
    .metric-card {
        background-color: #f8f9fa;
        padding: 1rem;
        border-radius: 0.5rem;
        border-left: 4px solid #1f77b4;
        margin-bottom: 1rem;
    }
    .warning-box {
        background-color: #fff3cd;
        padding: 1rem;
        border-radius: 0.5rem;
        border-left: 4px solid #ffc107;
        margin-bottom: 1rem;
    }
</style>
""", unsafe_allow_html=True)

def main():
    """Function principal del dashboard"""
    
    # Header principal
    st.markdown('<h1 class="main-header">GeomechML Dashboard</h1>', unsafe_allow_html=True)
    st.markdown("---")
    
    # Sidebar for navigation
    st.sidebar.title("📊 Navegación")
    
    # Load configuretion
    config_loader = ConfigLoader()
    config = config_loader.load_config()
    
    if config is None:
        st.error("❌ Could not load la configuretion del project")
        st.stop()
    
    # Load data
    data_loader = DataLoader()
    
    # Verify if simulation data exists
    if not data_loader.check_data_availability():
        st.markdown('<div class="warning-box">', unsafe_allow_html=True)
        st.warning("⚠️ **No se findon data de simulación**")
        st.markdown("""
        Para generate data, ejecuta la simulación completa:
        ```bash
        cd mrst_simulation_scripts
        octave --eval "s99_run_workflow()"
        ```
        """)
        st.markdown('</div>', unsafe_allow_html=True)
        st.stop()
    
    # Navigation options
    nav_options = {
        "🏠 Resumen General": "overview",
        "🗻 Reservoir Properties": "reservoir",
        "🛢️ Production Performance": "production", 
        "📈 Pressure Evolution": "pressure",
        "📊 Statistical Analysis": "statistics",
        "📥 Export Data": "export",
        "⚙️ Configuretion": "config"
    }
    
    selected_page = st.sidebar.selectbox(
        "Selecciona una section:",
        list(nav_options.keys())
    )
    
    page_key = nav_options[selected_page]
    
    # Info del project en sidebar
    with st.sidebar:
        st.markdown("---")
        st.markdown("### 📋 Info del Proyecto")
        st.markdown(f"**Proyecto:** {config.get('metadata', {}).get('project_name', 'N/A')}")
        st.markdown(f"**Versión:** {config.get('metadata', {}).get('version', 'N/A')}")
        st.markdown(f"**Autor:** {config.get('metadata', {}).get('author', 'N/A')}")
        
        # Quick grid metrics
        grid_info = config.get('grid', {})
        st.markdown("### 🔢 Simulation Grid")
        st.markdown(f"**Dimensiones:** {grid_info.get('nx', 0)}×{grid_info.get('ny', 0)}×{grid_info.get('nz', 0)}")
        st.markdown(f"**Total de celdas:** {grid_info.get('nx', 0) * grid_info.get('ny', 0) * grid_info.get('nz', 0):,}")
        
        # Simulation time
        sim_info = config.get('simulation', {})
        st.markdown("### ⏱️ Simulation")
        st.markdown(f"**Tiempo total:** {sim_info.get('total_time', 0):,.0f} días")
        st.markdown(f"**Timesteps:** {sim_info.get('num_timesteps', 0)}")
    
    # Render selected page
    if page_key == "overview":
        overview = SimulationOverview(data_loader, config)
        overview.render()
        
    elif page_key == "reservoir":
        reservoir = ReservoirProperties(data_loader, config)
        reservoir.render()
        
    elif page_key == "production":
        production = ProductionPerformance(data_loader, config)
        production.render()
        
    elif page_key == "pressure":
        pressure = PressureEvolution(data_loader, config)
        pressure.render()
        
    elif page_key == "statistics":
        st.markdown('<h2 class="section-header">📊 Statistical Analysis</h2>', unsafe_allow_html=True)
        st.info("🚧 Module de analysis estadístico en desarrollo")
        
    elif page_key == "export":
        st.markdown('<h2 class="section-header">📥 Export Data</h2>', unsafe_allow_html=True)
        
        # Initialize exportador
        export_manager = ExportManager()
        
        st.markdown("### 📁 Export Options")
        st.info("Selecciona el tipo de data que deseas export:")
        
        # Export options
        export_type = st.radio(
            "Tipo de exportación:",
            ["📊 Data Tabulares", "📈 Gráficos", "📋 Reporte Completo"],
            index=0
        )
        
        if export_type == "📊 Data Tabulares":
            st.markdown("#### Export Simulation Data")
            
            # Load data available
            temporal_data = data_loader.get_temporal_data()
            
            if temporal_data is not None:
                st.markdown("**Data Temporales Disponibles:**")
                export_manager.export_data_with_options(temporal_data, "temporal_data")
            else:
                st.warning("No data temporales available")
                
        elif export_type == "📈 Gráficos":
            st.markdown("#### Export Graphics")
            st.info("Los charts se pueden export desde cada section individual usando las opciones de exportación al final de cada chart.")
            
        elif export_type == "📋 Reporte Completo":
            st.markdown("#### Generate Reporte Completo")
            
            if st.button("🔄 Generate Reporte ZIP"):
                try:
                    # Recopilar data para el reporte
                    data_summary = {
                        'file_count': len(data_loader.get_available_files()),
                        'plot_count': 5,  # Estimation
                        'total_size_mb': 10.5,  # Estimation
                        'dataframes': {}
                    }
                    
                    # Add temporal data if available
                    if temporal_data is not None:
                        data_summary['dataframes']['temporal_data'] = temporal_data
                    
                    # Create example figures (in real implementation would come from sections)
                    figures = {}
                    
                    # Generate reporte
                    report_zip = export_manager.report_generator.create_simulation_report(
                        config, data_summary, figures
                    )
                    
                    # Download button
                    st.download_button(
                        label="📁 Desload Reporte Completo",
                        data=report_zip,
                        file_name=f"geomech_report_{pd.Timestamp.now().strftime('%Y%m%d_%H%M%S')}.zip",
                        mime="application/zip",
                        help="Descarga un file ZIP con el reporte completo"
                    )
                    
                    st.success("✅ Reporte generado successfully")
                    
                except Exception as e:
                    st.error(f"❌ Error generando reporte: {str(e)}")
        
    elif page_key == "config":
        st.markdown('<h2 class="section-header">⚙️ Configuretion del Sistema</h2>', unsafe_allow_html=True)
        
        # Mostrar configuretion en formato expandible
        with st.expander("📄 Ver configuretion completa", expanded=False):
            st.json(config)
        
        # Resumen de configuretion clave
        col1, col2 = st.columns(2)
        
        with col1:
            st.markdown("#### 🗻 Configuretion del Grid")
            grid_config = config.get('grid', {})
            st.write(f"- **Dimensiones:** {grid_config.get('nx')}×{grid_config.get('ny')}×{grid_config.get('nz')}")
            st.write(f"- **Tamaño de celda:** {grid_config.get('dx')}×{grid_config.get('dy')} ft")
            st.write(f"- **Capas:** {len(grid_config.get('dz', []))}")
            
        with col2:
            st.markdown("#### 🛢️ Configuretion de Pozos")
            wells_config = config.get('wells', {})
            producers = wells_config.get('producers', [])
            injectors = wells_config.get('injectors', [])
            st.write(f"- **Productores:** {len(producers)}")
            st.write(f"- **Inyectores:** {len(injectors)}")
            if producers:
                st.write(f"- **BHP objetivo:** {producers[0].get('target_bhp', 'N/A')} psi")

def launch_dashboard():
    """
    Launch the Streamlit dashboard automatically.
    This function runs the Streamlit server and keeps it open.
    """
    current_dir = Path(__file__).parent
    dashboard_file = current_dir / "s99_dashboard_app.py"
    
    print("🚀 Launching GeomechML Dashboard...")
    print(f"📁 Dashboard location: {current_dir}")
    print("🌐 Opening Streamlit server...")
    print("📝 URL: http://localhost:8501")
    print("⏹️  Press Ctrl+C to stop")
    
    # Launch Streamlit with current file
    try:
        subprocess.run([
            "streamlit", "run", str(dashboard_file),
            "--server.port=8501",
            "--server.headless=false",
            "--browser.gatherUsageStats=false",
            "--server.enableCORS=false",
            "--server.enableXsrfProtection=false"
        ], check=True)
    except subprocess.CalledProcessError as e:
        print(f"❌ Error launching Streamlit: {e}")
        sys.exit(1)
    except KeyboardInterrupt:
        print("\n🛑 Dashboard stopped by user")
        sys.exit(0)

if __name__ == "__main__":
    # Check if running as Streamlit app or direct execution
    if len(sys.argv) == 1:  # Direct execution
        launch_dashboard()
    else:  # Running via Streamlit
        main()