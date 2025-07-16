"""
Well Parameters Visualization

Creates organized displays of well configuration and parameters for reservoir engineers.
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
from config_reader import load_simulation_config, get_well_parameters, get_grid_parameters

def create_well_summary_table(config: Optional[Dict[str, Any]] = None) -> pd.DataFrame:
    """
    Create a comprehensive well summary table.
    
    Args:
        config: Configuration dictionary (optional, will load from file if None)
        
    Returns:
        pd.DataFrame: Well summary table
    """
    # Load configuration if not provided
    if config is None:
        config = load_simulation_config()
    
    # Get well parameters from configuration
    wells_config = config.get('wells', {})
    producers = wells_config.get('producers', [])
    injectors = wells_config.get('injectors', [])
    
    # Create well summary data
    well_data = []
    
    # Add producers
    for prod in producers:
        well_data.append({
            'Nombre del Pozo': prod.get('name', 'PROD'),
            'Tipo': 'Productor',
            'Ubicación (i, j)': f"({prod.get('location', [0, 0])[0]}, {prod.get('location', [0, 0])[1]})",
            'Tipo de Control': prod.get('control_type', 'bhp').upper(),
            'Presión Objetivo (BHP)': f"{prod.get('target_bhp', 0):.1f} psi",
            'Tasa Objetivo': f"{prod.get('target_rate', 0):.1f} bbl/día",
            'Radio del Pozo': f"{prod.get('radius', 0.33):.2f} ft",
            'Fluido': 'Petróleo + Agua'
        })
    
    # Add injectors
    for inj in injectors:
        well_data.append({
            'Nombre del Pozo': inj.get('name', 'INJ'),
            'Tipo': 'Inyector',
            'Ubicación (i, j)': f"({inj.get('location', [0, 0])[0]}, {inj.get('location', [0, 0])[1]})",
            'Tipo de Control': inj.get('control_type', 'rate').upper(),
            'Presión Objetivo (BHP)': f"{inj.get('target_bhp', 0):.1f} psi",
            'Tasa Objetivo': f"{inj.get('target_rate', 0):.1f} bbl/día",
            'Radio del Pozo': f"{inj.get('radius', 0.33):.2f} ft",
            'Fluido': inj.get('fluid_type', 'water').title()
        })
    
    return pd.DataFrame(well_data)

def create_well_locations_map(config: Optional[Dict[str, Any]] = None) -> go.Figure:
    """
    Create a 2D map showing well locations on the reservoir grid.
    
    Args:
        config: Configuration dictionary (optional, will load from file if None)
        
    Returns:
        go.Figure: 2D well locations map
    """
    # Load configuration if not provided
    if config is None:
        config = load_simulation_config()
    
    # Get parameters
    grid_params = get_grid_parameters(config)
    wells_data = get_well_parameters(config)
    
    # Create grid outline
    x_max = grid_params['nx'] * grid_params['dx']
    y_max = grid_params['ny'] * grid_params['dy']
    
    fig = go.Figure()
    
    # Add grid outline
    fig.add_trace(go.Scatter(
        x=[0, x_max, x_max, 0, 0],
        y=[0, 0, y_max, y_max, 0],
        mode='lines',
        line=dict(color='gray', width=2),
        name='Límites del Yacimiento',
        hoverinfo='skip'
    ))
    
    # Add grid lines
    for i in range(grid_params['nx'] + 1):
        x_line = i * grid_params['dx']
        fig.add_trace(go.Scatter(
            x=[x_line, x_line],
            y=[0, y_max],
            mode='lines',
            line=dict(color='lightgray', width=0.5),
            showlegend=False,
            hoverinfo='skip'
        ))
    
    for j in range(grid_params['ny'] + 1):
        y_line = j * grid_params['dy']
        fig.add_trace(go.Scatter(
            x=[0, x_max],
            y=[y_line, y_line],
            mode='lines',
            line=dict(color='lightgray', width=0.5),
            showlegend=False,
            hoverinfo='skip'
        ))
    
    # Add wells
    if wells_data and 'names' in wells_data:
        prod_x = []
        prod_y = []
        prod_names = []
        inj_x = []
        inj_y = []
        inj_names = []
        
        for i, (name, well_type) in enumerate(zip(wells_data['names'], wells_data['types'])):
            x_coord = wells_data['x_coords'][i]
            y_coord = wells_data['y_coords'][i]
            
            if well_type == 'producer':
                prod_x.append(x_coord)
                prod_y.append(y_coord)
                prod_names.append(name)
            else:
                inj_x.append(x_coord)
                inj_y.append(y_coord)
                inj_names.append(name)
        
        # Add producer wells
        if prod_x:
            fig.add_trace(go.Scatter(
                x=prod_x,
                y=prod_y,
                mode='markers+text',
                marker=dict(
                    size=15,
                    color='red',
                    symbol='circle',
                    line=dict(width=2, color='darkred')
                ),
                text=prod_names,
                textposition="middle center",
                textfont=dict(size=10, color='white'),
                name='Productores',
                hovertemplate="<b>%{text}</b><br>" +
                              "Tipo: Productor<br>" +
                              "X: %{x:.1f} ft<br>" +
                              "Y: %{y:.1f} ft<br>" +
                              "<extra></extra>"
            ))
        
        # Add injector wells
        if inj_x:
            fig.add_trace(go.Scatter(
                x=inj_x,
                y=inj_y,
                mode='markers+text',
                marker=dict(
                    size=15,
                    color='blue',
                    symbol='triangle-up',
                    line=dict(width=2, color='darkblue')
                ),
                text=inj_names,
                textposition="middle center",
                textfont=dict(size=10, color='white'),
                name='Inyectores',
                hovertemplate="<b>%{text}</b><br>" +
                              "Tipo: Inyector<br>" +
                              "X: %{x:.1f} ft<br>" +
                              "Y: %{y:.1f} ft<br>" +
                              "<extra></extra>"
            ))
    
    # Update layout
    fig.update_layout(
        title=dict(
            text="Ubicación de Pozos en el Yacimiento",
            x=0.5,
            font=dict(size=16)
        ),
        xaxis=dict(
            title="Distancia X (ft)",
            showgrid=True,
            gridcolor="lightgray",
            gridwidth=1,
            scaleanchor="y",
            scaleratio=1,
            range=[0, x_max]
        ),
        yaxis=dict(
            title="Distancia Y (ft)",
            showgrid=True,
            gridcolor="lightgray",
            gridwidth=1,
            range=[0, y_max]
        ),
        plot_bgcolor="white",
        width=600,
        height=600,
        margin=dict(l=50, r=50, t=70, b=50),
        showlegend=True,
        legend=dict(
            yanchor="top",
            y=0.99,
            xanchor="left",
            x=1.02
        )
    )
    
    return fig

def create_well_schedule_table(config: Optional[Dict[str, Any]] = None) -> pd.DataFrame:
    """
    Create a well schedule table showing operational parameters.
    
    Args:
        config: Configuration dictionary (optional, will load from file if None)
        
    Returns:
        pd.DataFrame: Well schedule table
    """
    # Load configuration if not provided
    if config is None:
        config = load_simulation_config()
    
    # Get well and simulation parameters
    wells_config = config.get('wells', {})
    sim_params = config.get('simulation', {})
    
    # Create schedule data
    schedule_data = []
    
    # Add simulation timeline info
    total_time = sim_params.get('total_time', 365.0)
    num_timesteps = sim_params.get('num_timesteps', 50)
    
    # Add producers
    for prod in wells_config.get('producers', []):
        schedule_data.append({
            'Pozo': prod.get('name', 'PROD'),
            'Tipo': 'Productor',
            'Inicio': '0.0 días',
            'Fin': f'{total_time:.1f} días',
            'Duración': f'{total_time:.1f} días',
            'Control Principal': prod.get('control_type', 'bhp').upper(),
            'Valor de Control': f"{prod.get('target_bhp', 0):.1f} psi" if prod.get('control_type') == 'bhp' else f"{prod.get('target_rate', 0):.1f} bbl/día",
            'Control Secundario': 'Rate' if prod.get('control_type') == 'bhp' else 'BHP',
            'Límite Secundario': f"{prod.get('target_rate', 0):.1f} bbl/día" if prod.get('control_type') == 'bhp' else f"{prod.get('target_bhp', 0):.1f} psi",
            'Estado': 'Activo'
        })
    
    # Add injectors
    for inj in wells_config.get('injectors', []):
        schedule_data.append({
            'Pozo': inj.get('name', 'INJ'),
            'Tipo': 'Inyector',
            'Inicio': '0.0 días',
            'Fin': f'{total_time:.1f} días',
            'Duración': f'{total_time:.1f} días',
            'Control Principal': inj.get('control_type', 'rate').upper(),
            'Valor de Control': f"{inj.get('target_rate', 0):.1f} bbl/día" if inj.get('control_type') == 'rate' else f"{inj.get('target_bhp', 0):.1f} psi",
            'Control Secundario': 'BHP' if inj.get('control_type') == 'rate' else 'Rate',
            'Límite Secundario': f"{inj.get('target_bhp', 0):.1f} psi" if inj.get('control_type') == 'rate' else f"{inj.get('target_rate', 0):.1f} bbl/día",
            'Estado': 'Activo'
        })
    
    return pd.DataFrame(schedule_data)