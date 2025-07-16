"""
Simulation Setup Visualization

Creates organized displays of simulation configuration and numerical parameters.
"""

import numpy as np
import pandas as pd
import plotly.graph_objects as go
import plotly.express as px
from plotly.subplots import make_subplots
from typing import Optional, Dict, Any, List
import streamlit as st
import sys
from pathlib import Path
sys.path.append(str(Path(__file__).parent.parent.parent))
from config_reader import (
    load_simulation_config, 
    get_simulation_parameters, 
    get_initial_conditions,
    get_geomechanics_parameters,
    get_metadata
)

def create_simulation_timeline(config: Optional[Dict[str, Any]] = None) -> go.Figure:
    """
    Create a timeline visualization of the simulation.
    
    Args:
        config: Configuration dictionary (optional, will load from file if None)
        
    Returns:
        go.Figure: Simulation timeline plot
    """
    # Load configuration if not provided
    if config is None:
        config = load_simulation_config()
    
    # Get simulation parameters
    sim_params = get_simulation_parameters(config)
    
    # Create timeline data
    total_time = sim_params.get('total_time', 365.0)
    num_timesteps = sim_params.get('num_timesteps', 50)
    timestep_type = sim_params.get('timestep_type', 'linear')
    
    # Generate timesteps based on type
    if timestep_type == 'linear':
        timesteps = np.linspace(0, total_time, num_timesteps)
    elif timestep_type == 'logarithmic':
        timesteps = np.logspace(np.log10(0.1), np.log10(total_time), num_timesteps)
    else:
        timesteps = np.linspace(0, total_time, num_timesteps)  # Default to linear
    
    # Create timeline figure
    fig = go.Figure()
    
    # Add timeline bars
    fig.add_trace(go.Bar(
        x=timesteps[1:],
        y=np.diff(timesteps),
        name='Pasos de Tiempo',
        marker_color='skyblue',
        hovertemplate="<b>Paso de Tiempo %{x:.1f}</b><br>" +
                      "Duración: %{y:.2f} días<br>" +
                      "<extra></extra>"
    ))
    
    # Add milestone markers
    milestones = [0, total_time/4, total_time/2, 3*total_time/4, total_time]
    milestone_names = ['Inicio', 'Primer Cuarto', 'Mitad', 'Tercer Cuarto', 'Final']
    
    for i, (time, name) in enumerate(zip(milestones, milestone_names)):
        fig.add_trace(go.Scatter(
            x=[time],
            y=[max(np.diff(timesteps)) * 1.1],
            mode='markers+text',
            marker=dict(
                size=12,
                color='red',
                symbol='diamond'
            ),
            text=name,
            textposition="top center",
            name=f'Hito: {name}',
            hovertemplate=f"<b>{name}</b><br>" +
                          f"Tiempo: {time:.1f} días<br>" +
                          "<extra></extra>"
        ))
    
    # Update layout
    fig.update_layout(
        title=dict(
            text=f"Línea de Tiempo de Simulación ({timestep_type.title()})",
            x=0.5,
            font=dict(size=16)
        ),
        xaxis=dict(
            title="Tiempo (días)",
            showgrid=True,
            gridcolor="lightgray",
            gridwidth=1
        ),
        yaxis=dict(
            title="Duración del Paso de Tiempo (días)",
            showgrid=True,
            gridcolor="lightgray",
            gridwidth=1
        ),
        plot_bgcolor="white",
        width=800,
        height=400,
        margin=dict(l=50, r=50, t=70, b=50),
        showlegend=False
    )
    
    return fig

def create_numerical_parameters_table(config: Optional[Dict[str, Any]] = None) -> pd.DataFrame:
    """
    Create a table with numerical simulation parameters.
    
    Args:
        config: Configuration dictionary (optional, will load from file if None)
        
    Returns:
        pd.DataFrame: Numerical parameters table
    """
    # Load configuration if not provided
    if config is None:
        config = load_simulation_config()
    
    # Get simulation parameters
    sim_params = get_simulation_parameters(config)
    initial_conditions = get_initial_conditions(config)
    geomech_params = get_geomechanics_parameters(config)
    
    # Create numerical parameters table
    numerical_data = {
        'Parámetro': [
            'Tiempo Total de Simulación',
            'Número de Pasos de Tiempo',
            'Tipo de Pasos de Tiempo',
            'Multiplicador de Pasos de Tiempo',
            '',
            'Tolerancia de Convergencia',
            'Iteraciones Máximas por Paso',
            'Solver Lineal',
            'Factor de Caída de Presión',
            '',
            'Condición de Frontera',
            'Presión de Frontera',
            'Temperatura del Yacimiento',
            '',
            'Acoplamiento Geomecánico',
            'Plasticidad',
            'Esfuerzo Superficial',
            'Gradiente de Sobrecarga',
            'Gradiente de Presión de Poro',
            'Módulo de Young',
            'Relación de Poisson',
            'Coeficiente de Biot'
        ],
        'Valor': [
            f"{sim_params.get('total_time', 365.0):.1f}",
            f"{sim_params.get('num_timesteps', 50)}",
            f"{sim_params.get('timestep_type', 'linear').title()}",
            f"{sim_params.get('timestep_multiplier', 1.1):.2f}",
            '',
            f"{sim_params.get('tolerance', 1.0e-6):.1e}",
            f"{sim_params.get('max_iterations', 25)}",
            f"{sim_params.get('linear_solver', 'direct').title()}",
            f"{sim_params.get('solver', {}).get('pressure_drop_factor', 0.9):.2f}",
            '',
            f"{config.get('boundary_conditions', {}).get('type', 'no_flow')}",
            f"{config.get('boundary_conditions', {}).get('pressure', 2900.0):.1f}",
            f"{initial_conditions.get('temperature', 176.0):.1f}",
            '',
            f"{'Sí' if geomech_params.get('enabled', True) else 'No'}",
            f"{'Sí' if geomech_params.get('plasticity', False) else 'No'}",
            f"{geomech_params.get('stress', {}).get('surface_stress', 2000.0):.1f}",
            f"{geomech_params.get('stress', {}).get('overburden_gradient', 1.0):.3f}",
            f"{geomech_params.get('stress', {}).get('pore_pressure_gradient', 0.433):.3f}",
            f"{geomech_params.get('mechanical', {}).get('young_modulus', 1450000.0):.0f}",
            f"{geomech_params.get('mechanical', {}).get('poisson_ratio', 0.25):.3f}",
            f"{geomech_params.get('mechanical', {}).get('biot_coefficient', 0.8):.2f}"
        ],
        'Unidades': [
            'días',
            'número',
            'tipo',
            'factor',
            '',
            'adimensional',
            'número',
            'tipo',
            'factor',
            '',
            'tipo',
            'psi',
            '°F',
            '',
            'booleano',
            'booleano',
            'psi',
            'psi/ft',
            'psi/ft',
            'psi',
            'adimensional',
            'adimensional'
        ],
        'Descripción': [
            'Duración total de la simulación',
            'Resolución temporal de la simulación',
            'Distribución de los pasos de tiempo',
            'Factor de crecimiento para pasos de tiempo',
            '',
            'Criterio de convergencia para el solver',
            'Límite de iteraciones por paso de tiempo',
            'Algoritmo para resolver sistema lineal',
            'Factor de reducción para presión de pozo',
            '',
            'Tipo de condición en los límites',
            'Presión en los límites (si aplica)',
            'Temperatura constante del yacimiento',
            '',
            'Activación del acoplamiento geomecánico',
            'Consideración de deformación plástica',
            'Esfuerzo total en superficie',
            'Incremento de sobrecarga con profundidad',
            'Incremento de presión de poro con profundidad',
            'Módulo de elasticidad de la roca',
            'Relación de Poisson de la roca',
            'Coeficiente de acoplamiento poroelástico'
        ]
    }
    
    return pd.DataFrame(numerical_data)

def create_solver_settings_display(config: Optional[Dict[str, Any]] = None) -> go.Figure:
    """
    Create a visualization of solver convergence settings.
    
    Args:
        config: Configuration dictionary (optional, will load from file if None)
        
    Returns:
        go.Figure: Solver settings visualization
    """
    # Load configuration if not provided
    if config is None:
        config = load_simulation_config()
    
    # Get simulation parameters
    sim_params = get_simulation_parameters(config)
    
    # Create convergence visualization
    tolerance = sim_params.get('tolerance', 1.0e-6)
    max_iterations = sim_params.get('max_iterations', 25)
    
    # Simulate convergence behavior
    iterations = np.arange(1, max_iterations + 1)
    # Typical convergence behavior (exponential decay)
    residuals = np.exp(-iterations * 0.3) * 1e-2
    
    fig = go.Figure()
    
    # Add convergence curve
    fig.add_trace(go.Scatter(
        x=iterations,
        y=residuals,
        mode='lines+markers',
        name='Residual Típico',
        line=dict(color='blue', width=2),
        marker=dict(size=6)
    ))
    
    # Add tolerance line
    fig.add_hline(
        y=tolerance,
        line_dash="dash",
        line_color="red",
        annotation_text=f"Tolerancia: {tolerance:.1e}",
        annotation_position="bottom right"
    )
    
    # Add regions
    fig.add_vrect(
        x0=0, x1=5,
        fillcolor="lightgreen", opacity=0.2,
        annotation_text="Convergencia\nRápida", annotation_position="top left"
    )
    
    fig.add_vrect(
        x0=5, x1=15,
        fillcolor="yellow", opacity=0.2,
        annotation_text="Convergencia\nNormal", annotation_position="top left"
    )
    
    fig.add_vrect(
        x0=15, x1=max_iterations,
        fillcolor="orange", opacity=0.2,
        annotation_text="Convergencia\nLenta", annotation_position="top left"
    )
    
    # Update layout
    fig.update_layout(
        title=dict(
            text="Configuración de Convergencia del Solver",
            x=0.5,
            font=dict(size=16)
        ),
        xaxis=dict(
            title="Número de Iteraciones",
            showgrid=True,
            gridcolor="lightgray",
            gridwidth=1
        ),
        yaxis=dict(
            title="Residual (Log Scale)",
            type="log",
            showgrid=True,
            gridcolor="lightgray",
            gridwidth=1
        ),
        plot_bgcolor="white",
        width=700,
        height=500,
        margin=dict(l=50, r=50, t=70, b=50),
        showlegend=True
    )
    
    return fig

def create_project_metadata_table(config: Optional[Dict[str, Any]] = None) -> pd.DataFrame:
    """
    Create a table with project metadata and information.
    
    Args:
        config: Configuration dictionary (optional, will load from file if None)
        
    Returns:
        pd.DataFrame: Project metadata table
    """
    # Load configuration if not provided
    if config is None:
        config = load_simulation_config()
    
    # Get metadata
    metadata = get_metadata(config)
    units = metadata.get('units', {})
    
    # Create metadata table
    metadata_data = {
        'Información': [
            'Nombre del Proyecto',
            'Descripción',
            'Autor',
            'Versión',
            'Fecha de Creación',
            'Última Modificación',
            '',
            'Unidad de Longitud',
            'Unidad de Presión',
            'Unidad de Permeabilidad',
            'Unidad de Tiempo',
            'Unidad de Temperatura',
            'Unidad de Volumen',
            'Unidad de Tasa',
            '',
            'Factor de Conversión ft→m',
            'Factor de Conversión psi→Pa',
            'Factor de Conversión mD→m²',
            'Factor de Conversión bbl/día→m³/s',
            'Factor de Conversión días→segundos'
        ],
        'Valor': [
            metadata.get('project_name', 'MRST Simulation'),
            metadata.get('description', 'Reservoir simulation project'),
            metadata.get('author', 'Simulation Team'),
            metadata.get('version', '1.0'),
            metadata.get('created_date', '2025-01-15'),
            metadata.get('last_modified', '2025-01-15'),
            '',
            units.get('length', 'feet'),
            units.get('pressure', 'psi'),
            units.get('permeability', 'millidarcy'),
            units.get('time', 'days'),
            units.get('temperature', 'fahrenheit'),
            units.get('volume', 'barrels'),
            units.get('rate', 'barrels_per_day'),
            '',
            f"{metadata.get('conversion_factors', {}).get('ft_to_m', 0.3048):.6f}",
            f"{metadata.get('conversion_factors', {}).get('psi_to_pa', 6894.76):.2f}",
            f"{metadata.get('conversion_factors', {}).get('md_to_m2', 9.869233e-16):.2e}",
            f"{metadata.get('conversion_factors', {}).get('bbl_per_day_to_m3_per_s', 1.589873e-7):.2e}",
            f"{metadata.get('conversion_factors', {}).get('days_to_seconds', 86400):.0f}"
        ]
    }
    
    return pd.DataFrame(metadata_data)