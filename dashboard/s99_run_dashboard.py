#!/usr/bin/env python3
"""
MRST Simulation Results Dashboard Launcher

This script launches an interactive Streamlit dashboard for visualizing
MRST geomechanical simulation results. The dashboard provides user-accessible
information about reservoir simulation data following product owner requirements.

The dashboard leverages the existing conda environment with streamlit and oct2py
for proper MAT file reading from MRST simulation outputs.
"""

import streamlit as st
import numpy as np
import pandas as pd
import oct2py
from pathlib import Path
import sys
import warnings

# Add utility modules to path
sys.path.append(str(Path(__file__).parent))

from util_data_loader import MRSTDataLoader
from util_visualization import DashboardVisualizer
from util_metrics import PerformanceMetrics

# Import hierarchical plot modules
from plots.initial_conditions import create_initial_pressure_map, create_initial_saturation_map
from plots.static_properties import (
    create_porosity_map, create_permeability_map, create_rock_regions_map,
    create_porosity_histogram, create_permeability_boxplot
)
from plots.dynamic_fields import (
    create_pressure_snapshot, create_saturation_snapshot,
    create_average_pressure_evolution, create_average_saturation_evolution
)
from plots.well_production import (
    create_oil_production_plot, create_water_injection_plot,
    create_cumulative_production_plot, create_recovery_factor_plot
)
from plots.flow_velocity import create_velocity_evolution_plot
from plots.flow_velocity.velocity_fields import create_velocity_magnitude_plot
from plots.transect_profiles import create_pressure_transect_plot, create_saturation_transect_plot
from plots.simulation_parameters import (
    create_reservoir_summary_table, create_reservoir_geometry_display, create_fluid_properties_table,
    create_well_summary_table, create_well_locations_map, create_well_schedule_table,
    create_simulation_timeline, create_numerical_parameters_table, create_solver_settings_display,
    create_project_metadata_table
)

# ----------------------------------------
# Step 1 – Dashboard configuration
# ----------------------------------------

st.set_page_config(
    page_title="MRST Simulation Dashboard",
    page_icon="🛢️",
    layout="wide",
    initial_sidebar_state="expanded"
)

# ----------------------------------------
# Step 2 – Data loading with caching
# ----------------------------------------

@st.cache_data
def load_simulation_data():
    """
    Load MRST simulation data with Streamlit caching for performance.
    
    Returns:
        dict: Complete simulation dataset or None if loading fails
    """
    try:
        loader = MRSTDataLoader()
        return loader.load_complete_dataset()
    except Exception as e:
        st.error(f"Error loading MRST simulation data: {e}")
        return None

# ----------------------------------------
# Step 3 – Main dashboard application
# ----------------------------------------

def main():
    """
    Main dashboard application following product owner requirements.
    
    Provides user-accessible information about reservoir simulation including:
    - Simulation overview and key metrics
    - Reservoir property visualization
    - Production performance analysis
    - Pressure and flow evolution
    """
    
    # Substep 3.1 – Dashboard header ______________________
    st.title("🛢️ MRST Geomechanical Simulation Dashboard")
    st.markdown("**Interactive visualization of reservoir simulation results**")
    
    # Substep 3.2 – Load simulation data ______________________
    with st.spinner("Loading simulation data..."):
        data = load_simulation_data()
    
    if data is None:
        st.error("❌ Failed to load simulation data. Please verify data availability.")
        st.info("📁 Expected data structure:")
        st.code("""
        data/
        ├── initial/initial_conditions.mat
        ├── static/static_data.mat
        ├── dynamic/fields/field_arrays.mat
        ├── dynamic/wells/well_data.mat
        └── metadata/metadata.mat
        """)
        st.stop()
    
    # Substep 3.3 – Sidebar navigation ______________________
    st.sidebar.header("📊 Plot Categories")
    
    # Plot categories with radio buttons
    plot_categories = [
        "⚙️ Parámetros de Simulación",
        "📊 Condiciones Iniciales",
        "🏔️ Propiedades Estáticas", 
        "📈 Campos Dinámicos",
        "🛢️ Producción de Pozos",
        "🌊 Flujos y Velocidades",
        "📐 Perfiles de Transecto"
    ]
    
    selected_category = st.sidebar.radio(
        "Seleccione una categoría:",
        plot_categories,
        index=0
    )
    
    # Substep 3.4 – Render selected category ______________________
    if selected_category == "⚙️ Parámetros de Simulación":
        show_simulation_parameters()
    elif selected_category == "📊 Condiciones Iniciales":
        show_initial_conditions(data)
    elif selected_category == "🏔️ Propiedades Estáticas":
        show_static_properties(data)
    elif selected_category == "📈 Campos Dinámicos":
        show_dynamic_fields(data)
    elif selected_category == "🛢️ Producción de Pozos":
        show_well_production(data)
    elif selected_category == "🌊 Flujos y Velocidades":
        show_flow_velocity(data)
    elif selected_category == "📐 Perfiles de Transecto":
        show_transect_profiles(data)

# ----------------------------------------
# Step 4 – Dashboard view functions
# ----------------------------------------

def show_simulation_parameters():
    """
    Display simulation parameters from configuration file.
    
    This function reads the configuration file and displays all simulation
    parameters organized for reservoir engineers.
    """
    st.header("⚙️ Parámetros de Simulación")
    st.markdown("### Configuración completa del proyecto de simulación")
    
    try:
        # Import config reader
        from config_reader import load_simulation_config
        
        # Load configuration
        config = load_simulation_config()
        
        # Create tabs for different parameter categories
        tab1, tab2, tab3, tab4, tab5 = st.tabs([
            "🏔️ Yacimiento",
            "🛢️ Pozos", 
            "💧 Fluidos",
            "⚙️ Simulación",
            "📋 Proyecto"
        ])
        
        with tab1:
            st.subheader("Parámetros del Yacimiento")
            
            # Reservoir summary table
            reservoir_table = create_reservoir_summary_table(config)
            st.dataframe(reservoir_table, use_container_width=True, hide_index=True)
            
            # 3D geometry visualization
            st.subheader("Geometría del Yacimiento")
            geometry_fig = create_reservoir_geometry_display(config)
            st.plotly_chart(geometry_fig, use_container_width=True)
            
        with tab2:
            st.subheader("Configuración de Pozos")
            
            # Well summary table
            well_table = create_well_summary_table(config)
            st.dataframe(well_table, use_container_width=True, hide_index=True)
            
            # Well locations map
            st.subheader("Ubicación de Pozos")
            well_locations_fig = create_well_locations_map(config)
            st.plotly_chart(well_locations_fig, use_container_width=True)
            
            # Well schedule
            st.subheader("Cronograma de Pozos")
            schedule_table = create_well_schedule_table(config)
            st.dataframe(schedule_table, use_container_width=True, hide_index=True)
            
        with tab3:
            st.subheader("Propiedades de Fluidos")
            
            # Fluid properties table
            fluid_table = create_fluid_properties_table(config)
            st.dataframe(fluid_table, use_container_width=True, hide_index=True)
            
        with tab4:
            st.subheader("Configuración de Simulación")
            
            # Simulation timeline
            timeline_fig = create_simulation_timeline(config)
            st.plotly_chart(timeline_fig, use_container_width=True)
            
            # Numerical parameters
            st.subheader("Parámetros Numéricos")
            numerical_table = create_numerical_parameters_table(config)
            st.dataframe(numerical_table, use_container_width=True, hide_index=True)
            
            # Solver settings
            st.subheader("Configuración del Solver")
            solver_fig = create_solver_settings_display(config)
            st.plotly_chart(solver_fig, use_container_width=True)
            
        with tab5:
            st.subheader("Información del Proyecto")
            
            # Project metadata
            metadata_table = create_project_metadata_table(config)
            st.dataframe(metadata_table, use_container_width=True, hide_index=True)
            
    except Exception as e:
        st.error(f"Error cargando parámetros de simulación: {e}")
        st.info("Verifique que el archivo de configuración esté disponible en config/reservoir_config.yaml")

def show_initial_conditions(data):
    """
    Display initial conditions (t=0) with tabs for different plots.
    
    Args:
        data: Complete simulation dataset
    """
    st.header("📊 Condiciones Iniciales (t=0)")
    
    if 'initial_conditions' not in data or data['initial_conditions'] is None:
        st.error("❌ Datos de condiciones iniciales no disponibles")
        return
    
    initial_data = data['initial_conditions']
    
    # Create tabs for different plot types
    tab1, tab2 = st.tabs(["🌡️ Mapa de Presión", "💧 Mapa de Saturación"])
    
    with tab1:
        try:
            fig = create_initial_pressure_map(
                initial_data['pressure'],
                title="Distribución de Presión Inicial",
                wells_data=data.get('wells', None)
            )
            st.plotly_chart(fig, use_container_width=True)
            
            # Show statistics
            st.subheader("📊 Estadísticas de Presión")
            col1, col2, col3, col4 = st.columns(4)
            with col1:
                st.metric("Presión Mínima", f"{np.min(initial_data['pressure']):.1f} psi")
            with col2:
                st.metric("Presión Máxima", f"{np.max(initial_data['pressure']):.1f} psi")
            with col3:
                st.metric("Presión Promedio", f"{np.mean(initial_data['pressure']):.1f} psi")
            with col4:
                st.metric("Desviación Estándar", f"{np.std(initial_data['pressure']):.1f} psi")
                
        except Exception as e:
            st.error(f"Error creando mapa de presión: {e}")
    
    with tab2:
        try:
            fig = create_initial_saturation_map(
                initial_data['sw'],
                title="Distribución de Saturación de Agua Inicial",
                wells_data=data.get('wells', None)
            )
            st.plotly_chart(fig, use_container_width=True)
            
            # Show statistics
            st.subheader("📊 Estadísticas de Saturación")
            col1, col2, col3, col4 = st.columns(4)
            with col1:
                st.metric("Sw Mínima", f"{np.min(initial_data['sw']):.3f}")
            with col2:
                st.metric("Sw Máxima", f"{np.max(initial_data['sw']):.3f}")
            with col3:
                st.metric("Sw Promedio", f"{np.mean(initial_data['sw']):.3f}")
            with col4:
                st.metric("So Promedio", f"{np.mean(1 - initial_data['sw']):.3f}")
                
        except Exception as e:
            st.error(f"Error creando mapa de saturación: {e}")

def show_static_properties(data):
    """
    Display static reservoir properties with tabs for different plots.
    
    Args:
        data: Complete simulation dataset
    """
    st.header("🏔️ Propiedades Estáticas")
    
    if 'initial_conditions' not in data or data['initial_conditions'] is None:
        st.error("❌ Datos de condiciones iniciales no disponibles")
        return
    
    initial_data = data['initial_conditions']
    
    # Create tabs for different plot types
    tab1, tab2, tab3, tab4, tab5 = st.tabs([
        "🔹 Porosidad", 
        "🔸 Permeabilidad", 
        "🗺️ Regiones de Roca",
        "📊 Histograma Porosidad",
        "📈 Box-plot Permeabilidad"
    ])
    
    with tab1:
        try:
            fig = create_porosity_map(
                initial_data['phi'],
                title="Distribución de Porosidad",
                wells_data=data.get('wells', None)
            )
            st.plotly_chart(fig, use_container_width=True)
            
            # Statistics
            st.subheader("📊 Estadísticas de Porosidad")
            col1, col2, col3, col4 = st.columns(4)
            with col1:
                st.metric("Porosidad Mínima", f"{np.min(initial_data['phi']):.3f}")
            with col2:
                st.metric("Porosidad Máxima", f"{np.max(initial_data['phi']):.3f}")
            with col3:
                st.metric("Porosidad Promedio", f"{np.mean(initial_data['phi']):.3f}")
            with col4:
                st.metric("Desviación Estándar", f"{np.std(initial_data['phi']):.3f}")
                
        except Exception as e:
            st.error(f"Error creando mapa de porosidad: {e}")
    
    with tab2:
        try:
            fig = create_permeability_map(
                initial_data['k'],
                title="Distribución de Permeabilidad",
                wells_data=data.get('wells', None)
            )
            st.plotly_chart(fig, use_container_width=True)
            
            # Statistics
            st.subheader("📊 Estadísticas de Permeabilidad")
            col1, col2, col3, col4 = st.columns(4)
            with col1:
                st.metric("Perm. Mínima", f"{np.min(initial_data['k']):.1f} mD")
            with col2:
                st.metric("Perm. Máxima", f"{np.max(initial_data['k']):.1f} mD")
            with col3:
                st.metric("Perm. Promedio", f"{np.mean(initial_data['k']):.1f} mD")
            with col4:
                st.metric("Perm. Geom. Media", f"{np.exp(np.mean(np.log(initial_data['k'][initial_data['k'] > 0]))):.1f} mD")
                
        except Exception as e:
            st.error(f"Error creando mapa de permeabilidad: {e}")
    
    with tab3:
        if 'static_data' in data and data['static_data'] is not None:
            try:
                fig = create_rock_regions_map(
                    data['static_data']['rock_id'],
                    title="Mapa de Regiones de Roca",
                    wells_data=data.get('wells', None)
                )
                st.plotly_chart(fig, use_container_width=True)
            except Exception as e:
                st.error(f"Error creando mapa de regiones de roca: {e}")
        else:
            st.info("❌ Datos estáticos no disponibles para análisis de tipos de roca")
    
    with tab4:
        try:
            fig = create_porosity_histogram(
                initial_data['phi'],
                title="Distribución de Porosidad"
            )
            st.plotly_chart(fig, use_container_width=True)
        except Exception as e:
            st.error(f"Error creando histograma de porosidad: {e}")
    
    with tab5:
        if 'static_data' in data and data['static_data'] is not None:
            try:
                fig = create_permeability_boxplot(
                    initial_data['k'],
                    data['static_data']['rock_id'],
                    title="Permeabilidad por Tipo de Roca"
                )
                st.plotly_chart(fig, use_container_width=True)
            except Exception as e:
                st.error(f"Error creando box-plot de permeabilidad: {e}")
        else:
            st.info("❌ Datos estáticos no disponibles para análisis por tipo de roca")

def show_dynamic_fields(data):
    """
    Display dynamic field evolution with tabs for different plots.
    
    Args:
        data: Complete simulation dataset
    """
    st.header("📈 Campos Dinámicos")
    
    if 'field_arrays' not in data or data['field_arrays'] is None:
        st.error("❌ Datos de campos dinámicos no disponibles")
        return
    
    field_data = data['field_arrays']
    
    # Create tabs for different plot types
    tab1, tab2, tab3, tab4 = st.tabs([
        "📊 Evolución Presión",
        "🗺️ Snapshots Presión", 
        "💧 Evolución Saturación",
        "🗺️ Snapshots Saturación"
    ])
    
    with tab1:
        try:
            time_days = field_data.get('time_days', np.arange(field_data['pressure'].shape[0]))
            fig = create_average_pressure_evolution(
                field_data['pressure'],
                time_days,
                title="Evolución de Presión Promedio en el Reservorio"
            )
            st.plotly_chart(fig, use_container_width=True)
        except Exception as e:
            st.error(f"Error creando evolución de presión: {e}")
    
    with tab2:
        try:
            time_days = field_data.get('time_days', np.arange(field_data['pressure'].shape[0]))
            n_timesteps = field_data['pressure'].shape[0]
            
            selected_timestep = st.slider(
                "Seleccionar Paso de Tiempo",
                min_value=0,
                max_value=n_timesteps - 1,
                value=0,
                help="Seleccione el paso de tiempo para visualizar distribución de presión"
            )
            
            fig = create_pressure_snapshot(
                field_data['pressure'],
                selected_timestep,
                time_days=time_days,
                title=f"Distribución de Presión - Paso {selected_timestep}",
                wells_data=data.get('wells', None)
            )
            st.plotly_chart(fig, use_container_width=True)
        except Exception as e:
            st.error(f"Error creando snapshot de presión: {e}")
    
    with tab3:
        try:
            time_days = field_data.get('time_days', np.arange(field_data['sw'].shape[0]))
            fig = create_average_saturation_evolution(
                field_data['sw'],
                time_days,
                title="Evolución de Saturación de Agua Promedio"
            )
            st.plotly_chart(fig, use_container_width=True)
        except Exception as e:
            st.error(f"Error creando evolución de saturación: {e}")
    
    with tab4:
        try:
            time_days = field_data.get('time_days', np.arange(field_data['sw'].shape[0]))
            n_timesteps = field_data['sw'].shape[0]
            
            selected_timestep = st.slider(
                "Seleccionar Paso de Tiempo para Saturación",
                min_value=0,
                max_value=n_timesteps - 1,
                value=0,
                key="sw_timestep",
                help="Seleccione el paso de tiempo para visualizar distribución de saturación"
            )
            
            fig = create_saturation_snapshot(
                field_data['sw'],
                selected_timestep,
                time_days=time_days,
                title=f"Distribución de Saturación - Paso {selected_timestep}",
                wells_data=data.get('wells', None)
            )
            st.plotly_chart(fig, use_container_width=True)
        except Exception as e:
            st.error(f"Error creando snapshot de saturación: {e}")

def show_well_production(data):
    """
    Display well production analysis with tabs for different plots.
    
    Args:
        data: Complete simulation dataset
    """
    st.header("🛢️ Producción de Pozos")
    
    if 'well_data' not in data or data['well_data'] is None:
        st.error("❌ Datos de pozos no disponibles")
        return
    
    well_data = data['well_data']
    
    # Create tabs for different plot types
    tab1, tab2, tab3, tab4 = st.tabs([
        "📈 Tasas de Producción",
        "💧 Tasas de Inyección",
        "📊 Producción Acumulada",
        "🎯 Factor de Recuperación"
    ])
    
    with tab1:
        try:
            fig = create_oil_production_plot(
                well_data,
                title="Tasas de Producción de Crudo"
            )
            st.plotly_chart(fig, use_container_width=True)
        except Exception as e:
            st.error(f"Error creando gráfico de producción: {e}")
    
    with tab2:
        try:
            fig = create_water_injection_plot(
                well_data,
                title="Tasas de Inyección de Agua"
            )
            st.plotly_chart(fig, use_container_width=True)
        except Exception as e:
            st.error(f"Error creando gráfico de inyección: {e}")
    
    with tab3:
        if 'cumulative_data' in data and data['cumulative_data'] is not None:
            try:
                fig = create_cumulative_production_plot(
                    data['cumulative_data'],
                    title="Producción Acumulada"
                )
                st.plotly_chart(fig, use_container_width=True)
            except Exception as e:
                st.error(f"Error creando gráfico de producción acumulada: {e}")
        else:
            st.info("❌ Datos acumulados no disponibles")
    
    with tab4:
        if 'cumulative_data' in data and data['cumulative_data'] is not None:
            try:
                fig = create_recovery_factor_plot(
                    data['cumulative_data'],
                    title="Evolución del Factor de Recuperación"
                )
                st.plotly_chart(fig, use_container_width=True)
            except Exception as e:
                st.error(f"Error creando gráfico de factor de recuperación: {e}")
        else:
            st.info("❌ Datos acumulados no disponibles")

def show_flow_velocity(data):
    """
    Display flow and velocity analysis with tabs for different plots.
    
    Args:
        data: Complete simulation dataset
    """
    st.header("🌊 Flujos y Velocidades")
    
    if 'flow_data' not in data or data['flow_data'] is None:
        st.error("❌ Datos de flujo no disponibles")
        return
    
    flow_data = data['flow_data']
    
    # Create tabs for different plot types
    tab1, tab2 = st.tabs([
        "📊 Evolución Velocidad",
        "🗺️ Campo de Velocidades"
    ])
    
    with tab1:
        try:
            fig = create_velocity_evolution_plot(
                flow_data,
                title="Evolución de Magnitud de Velocidad Promedio"
            )
            st.plotly_chart(fig, use_container_width=True)
        except Exception as e:
            st.error(f"Error creando evolución de velocidad: {e}")
    
    with tab2:
        try:
            n_timesteps = flow_data['velocity_magnitude'].shape[0]
            selected_timestep = st.slider(
                "Seleccionar Paso de Tiempo para Velocidad",
                min_value=0,
                max_value=n_timesteps - 1,
                value=0,
                key="velocity_timestep",
                help="Seleccione el paso de tiempo para visualizar campo de velocidad"
            )
            
            fig = create_velocity_magnitude_plot(
                flow_data,
                selected_timestep,
                title=f"Magnitud de Velocidad - Paso {selected_timestep}"
            )
            st.plotly_chart(fig, use_container_width=True)
        except Exception as e:
            st.error(f"Error creando campo de velocidad: {e}")

def show_transect_profiles(data):
    """
    Display transect profile analysis with tabs for different plots.
    
    Args:
        data: Complete simulation dataset
    """
    st.header("📐 Perfiles de Transecto")
    
    if 'field_arrays' not in data or data['field_arrays'] is None:
        st.error("❌ Datos de campos dinámicos no disponibles")
        return
    
    field_data = data['field_arrays']
    
    # Create tabs for different plot types
    tab1, tab2 = st.tabs([
        "🌡️ Perfil de Presión",
        "💧 Perfil de Saturación"
    ])
    
    with tab1:
        try:
            time_days = field_data.get('time_days', np.arange(field_data['pressure'].shape[0]))
            
            col1, col2 = st.columns(2)
            with col1:
                transect_type = st.selectbox(
                    "Tipo de Transecto",
                    ["horizontal", "vertical"],
                    help="Seleccione la orientación del transecto"
                )
            with col2:
                transect_index = st.slider(
                    "Índice de Transecto",
                    min_value=0,
                    max_value=19,
                    value=10,
                    help="Seleccione la posición del transecto"
                )
            
            fig = create_pressure_transect_plot(
                field_data['pressure'],
                time_days,
                transect_type=transect_type,
                transect_index=transect_index,
                title=f"Perfil de Presión - {transect_type.title()}"
            )
            st.plotly_chart(fig, use_container_width=True)
        except Exception as e:
            st.error(f"Error creando perfil de presión: {e}")
    
    with tab2:
        try:
            time_days = field_data.get('time_days', np.arange(field_data['sw'].shape[0]))
            
            col1, col2 = st.columns(2)
            with col1:
                transect_type = st.selectbox(
                    "Tipo de Transecto para Saturación",
                    ["horizontal", "vertical"],
                    key="sat_transect_type",
                    help="Seleccione la orientación del transecto"
                )
            with col2:
                transect_index = st.slider(
                    "Índice de Transecto para Saturación",
                    min_value=0,
                    max_value=19,
                    value=10,
                    key="sat_transect_index",
                    help="Seleccione la posición del transecto"
                )
            
            fig = create_saturation_transect_plot(
                field_data['sw'],
                time_days,
                transect_type=transect_type,
                transect_index=transect_index,
                title=f"Perfil de Saturación - {transect_type.title()}"
            )
            st.plotly_chart(fig, use_container_width=True)
        except Exception as e:
            st.error(f"Error creando perfil de saturación: {e}")

# ----------------------------------------
# Step 5 – Application entry point
# ----------------------------------------

if __name__ == "__main__":
    main()