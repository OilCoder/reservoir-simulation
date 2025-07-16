"""
Reservoir Parameters Visualization

Creates organized displays of reservoir properties and geometry for reservoir engineers.
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
from config_reader import load_simulation_config, get_grid_parameters, get_rock_parameters, get_fluid_parameters

def create_reservoir_summary_table(config: Optional[Dict[str, Any]] = None) -> pd.DataFrame:
    """
    Create a comprehensive reservoir summary table.
    
    Args:
        config: Configuration dictionary (optional, will load from file if None)
        
    Returns:
        pd.DataFrame: Formatted reservoir summary table
    """
    # Load configuration if not provided
    if config is None:
        config = load_simulation_config()
    
    # Extract parameters from configuration
    grid_params = get_grid_parameters(config)
    rock_params = get_rock_parameters(config)
    fluid_params = get_fluid_parameters(config)
    initial_conditions = config.get('initial_conditions', {})
    
    # Create summary table
    summary_data = {
        'Parámetro': [
            'Dimensiones del Yacimiento',
            'Número de Celdas (NX × NY × NZ)',
            'Tamaño de Celda',
            'Espesor del Yacimiento',
            'Área Total',
            'Volumen Bruto Total',
            '',
            'Porosidad Base',
            'Porosidad Mínima',
            'Porosidad Máxima',
            'Amplitud de Variación',
            'Longitud de Correlación',
            '',
            'Permeabilidad Base',
            'Permeabilidad Mínima',
            'Permeabilidad Máxima',
            'Amplitud de Variación',
            'Longitud de Correlación',
            'Correlación con Porosidad',
            '',
            'Presión Inicial',
            'Saturación de Agua Inicial',
            'Saturación de Petróleo Inicial',
            'Temperatura del Yacimiento',
            '',
            'Número de Regiones de Roca',
            'Presión de Referencia'
        ],
        'Valor': [
            f'{grid_params["nx"]} × {grid_params["ny"]} × {grid_params["nz"]}',
            f'{grid_params["total_cells"]:,}',
            f'{grid_params["dx"]} × {grid_params["dy"]} ft',
            f'{grid_params["dz"]} ft',
            f'{grid_params["total_area"]:,.0f} ft²',
            f'{grid_params["total_volume"]:,.0f} ft³',
            '',
            f'{rock_params["porosity"].get("base_value", 0.20):.3f}',
            f'{rock_params["porosity"].get("bounds", {}).get("min", 0.05):.3f}',
            f'{rock_params["porosity"].get("bounds", {}).get("max", 0.35):.3f}',
            f'{rock_params["porosity"].get("variation_amplitude", 0.10):.3f}',
            f'{rock_params["porosity"].get("correlation_length", 656.0):.0f} ft',
            '',
            f'{rock_params["permeability"].get("base_value", 100.0):.1f}',
            f'{rock_params["permeability"].get("bounds", {}).get("min", 10.0):.1f}',
            f'{rock_params["permeability"].get("bounds", {}).get("max", 500.0):.1f}',
            f'{rock_params["permeability"].get("variation_amplitude", 80.0):.1f}',
            f'{rock_params["permeability"].get("correlation_length", 984.0):.0f} ft',
            f'{rock_params["permeability"].get("porosity_correlation", 0.8):.2f}',
            '',
            f'{initial_conditions.get("pressure", 2900.0):.1f}',
            f'{initial_conditions.get("water_saturation", 0.20):.3f}',
            f'{1 - initial_conditions.get("water_saturation", 0.20):.3f}',
            f'{initial_conditions.get("temperature", 176.0):.1f}',
            '',
            f'{rock_params["n_regions"]}',
            f'{rock_params["reference_pressure"]:.1f}'
        ],
        'Unidades': [
            'celdas',
            'celdas',
            'ft',
            'ft',
            'ft²',
            'ft³',
            '',
            'fracción',
            'fracción', 
            'fracción',
            'fracción',
            'ft',
            '',
            'mD',
            'mD',
            'mD',
            'mD',
            'ft',
            'adimensional',
            '',
            'psi',
            'fracción',
            'fracción',
            '°F',
            '',
            'número',
            'psi'
        ]
    }
    
    return pd.DataFrame(summary_data)

def create_reservoir_geometry_display(config: Optional[Dict[str, Any]] = None) -> go.Figure:
    """
    Create a 3D visualization of reservoir geometry.
    
    Args:
        config: Configuration dictionary (optional, will load from file if None)
        
    Returns:
        go.Figure: 3D reservoir geometry plot
    """
    # Load configuration if not provided
    if config is None:
        config = load_simulation_config()
    
    # Get parameters from configuration
    grid_params = get_grid_parameters(config)
    
    # Create 3D mesh representation
    x = np.linspace(0, grid_params['nx'] * grid_params['dx'], grid_params['nx'] + 1)
    y = np.linspace(0, grid_params['ny'] * grid_params['dy'], grid_params['ny'] + 1)
    X, Y = np.meshgrid(x, y)
    
    # Create top surface (constant depth)
    Z_top = np.ones_like(X) * 5000  # 5000 ft depth
    
    # Create bottom surface (thickness from config)
    Z_bottom = np.ones_like(X) * (5000 + grid_params['dz'])
    
    fig = go.Figure()
    
    # Add top surface
    fig.add_trace(go.Surface(
        x=X, y=Y, z=Z_top,
        colorscale='Viridis',
        opacity=0.7,
        name='Tope del Yacimiento',
        showscale=False
    ))
    
    # Add bottom surface
    fig.add_trace(go.Surface(
        x=X, y=Y, z=Z_bottom,
        colorscale='Viridis',
        opacity=0.7,
        name='Base del Yacimiento',
        showscale=False
    ))
    
    # Add wells using configuration data
    sys.path.append(str(Path(__file__).parent.parent.parent))
    from config_reader import get_well_parameters
    wells_data = get_well_parameters(config)
    
    if wells_data and 'names' in wells_data:
        for i, (name, well_type) in enumerate(zip(wells_data['names'], wells_data['types'])):
            x_coord = wells_data['x_coords'][i]
            y_coord = wells_data['y_coords'][i]
            
            color = 'red' if well_type == 'producer' else 'blue'
            symbol = 'circle' if well_type == 'producer' else 'diamond'
            
            fig.add_trace(go.Scatter3d(
                x=[x_coord],
                y=[y_coord],
                z=[5000],
                mode='markers',
                marker=dict(
                    size=8,
                    color=color,
                    symbol=symbol
                ),
                name=f'{name} ({well_type})',
                text=name,
                hovertemplate=f"<b>{name}</b><br>" +
                              f"Tipo: {well_type}<br>" +
                              f"X: {x_coord:.1f} ft<br>" +
                              f"Y: {y_coord:.1f} ft<br>" +
                              "<extra></extra>"
            ))
    
    # Update layout
    fig.update_layout(
        title=dict(
            text="Geometría del Yacimiento - Vista 3D",
            x=0.5,
            font=dict(size=16)
        ),
        scene=dict(
            xaxis_title="Distancia X (ft)",
            yaxis_title="Distancia Y (ft)",
            zaxis_title="Profundidad (ft)",
            zaxis=dict(autorange="reversed"),  # Depth increases downward
            aspectmode="cube"
        ),
        width=700,
        height=600,
        margin=dict(l=0, r=0, t=50, b=0)
    )
    
    return fig

def create_fluid_properties_table(config: Optional[Dict[str, Any]] = None) -> pd.DataFrame:
    """
    Create a table with fluid properties used in the simulation.
    
    Args:
        config: Configuration dictionary (optional, will load from file if None)
        
    Returns:
        pd.DataFrame: Fluid properties table
    """
    # Load configuration if not provided
    if config is None:
        config = load_simulation_config()
    
    # Get fluid parameters from configuration
    fluid_params = get_fluid_parameters(config)
    oil_props = fluid_params.get('oil', {})
    water_props = fluid_params.get('water', {})
    rel_perm = fluid_params.get('relative_permeability', {})
    
    fluid_data = {
        'Propiedad': [
            'Densidad del Petróleo',
            'Densidad del Agua',
            'Viscosidad del Petróleo',
            'Viscosidad del Agua',
            'Factor de Formación del Petróleo',
            'Factor de Formación del Agua',
            'Compresibilidad del Petróleo',
            'Compresibilidad del Agua',
            'Presión de Referencia PVT',
            '',
            'Saturación de Agua Connata',
            'Saturación de Petróleo Residual',
            'Permeabilidad Relativa Máxima (Petróleo)',
            'Permeabilidad Relativa Máxima (Agua)',
            'Exponente de Corey (Petróleo)',
            'Exponente de Corey (Agua)',
            '',
            'Histéresis en Curvas kr',
            'Puntos de Presión PVT',
            'Puntos de Saturación kr'
        ],
        'Valor': [
            f'{oil_props.get("density", 850.0)}',
            f'{water_props.get("density", 1000.0)}',
            f'{oil_props.get("viscosity", 2.0)}',
            f'{water_props.get("viscosity", 0.5)}',
            f'{oil_props.get("formation_volume_factor", 1.2)}',
            f'{water_props.get("formation_volume_factor", 1.0)}',
            f'{oil_props.get("compressibility", 1.0e-5):.1e}',
            f'{water_props.get("compressibility", 3.0e-6):.1e}',
            f'{oil_props.get("reference_pressure", 2900.0):.1f}',
            '',
            f'{fluid_params.get("connate_water_saturation", 0.15):.3f}',
            f'{fluid_params.get("residual_oil_saturation", 0.20):.3f}',
            f'{rel_perm.get("oil", {}).get("endpoint_krmax", 0.90):.2f}',
            f'{rel_perm.get("water", {}).get("endpoint_krmax", 0.85):.2f}',
            f'{rel_perm.get("oil", {}).get("corey_exponent", 2.0):.1f}',
            f'{rel_perm.get("water", {}).get("corey_exponent", 2.5):.1f}',
            '',
            f'{"Sí" if rel_perm.get("hysteresis", False) else "No"}',
            f'{rel_perm.get("pvt_pressure_range", {}).get("num_points", 50)}',
            f'{rel_perm.get("saturation_range", {}).get("num_points", 100)}'
        ],
        'Unidades': [
            'kg/m³',
            'kg/m³',
            'cP',
            'cP',
            'rb/stb',
            'rb/stb',
            '1/psi',
            '1/psi',
            'psi',
            '',
            'fracción',
            'fracción',
            'fracción',
            'fracción',
            'adimensional',
            'adimensional',
            '',
            'booleano',
            'puntos',
            'puntos'
        ],
        'Descripción': [
            'Densidad del crudo a condiciones estándar',
            'Densidad del agua de formación',
            'Viscosidad del crudo a condiciones de yacimiento',
            'Viscosidad del agua de formación',
            'Factor volumétrico del petróleo',
            'Factor volumétrico del agua',
            'Compresibilidad isotérmica del petróleo',
            'Compresibilidad isotérmica del agua',
            'Presión de referencia para propiedades PVT',
            '',
            'Saturación irreducible de agua',
            'Saturación residual de petróleo',
            'Permeabilidad relativa máxima del petróleo',
            'Permeabilidad relativa máxima del agua',
            'Exponente de Corey para curva kr del petróleo',
            'Exponente de Corey para curva kr del agua',
            '',
            'Activación de histéresis en curvas kr',
            'Resolución de la tabla PVT',
            'Resolución de las curvas de permeabilidad relativa'
        ]
    }
    
    return pd.DataFrame(fluid_data)