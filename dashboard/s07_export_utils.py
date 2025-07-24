#!/usr/bin/env python3
"""
Export Utilities - GeomechML Dashboard
====================================

Utilidades para export data y visualizaciones:
- Export charts como PNG, PDF, SVG
- Export data como CSV, Excel
- Generate reportes en PDF
- Crear files ZIP con múltiples exports

Author: GeomechML Team
Date: 2025-07-23
"""

import streamlit as st
import pandas as pd
import numpy as np
import plotly.graph_objects as go
import plotly.io as pio
from typing import Dict, List, Optional, Union, Any
import io
import zipfile
import base64
from datetime import datetime
import json
import logging

logger = logging.getLogger(__name__)

class DataExporter:
    """Class for exporting simulation data"""
    
    def __init__(self):
        """Initialize exportador de data"""
        self.export_formats = {
            'csv': self._export_csv,
            'excel': self._export_excel,
            'json': self._export_json
        }
    
    def export_dataframe(self, df: pd.DataFrame, filename: str, 
                        format_type: str = 'csv') -> bytes:
        """
        Export DataFrame en el formato especificado.
        
        Args:
            df: DataFrame a export
            filename: Nombre del file
            format_type: Formato de exportación ('csv', 'excel', 'json')
            
        Returns:
            Bytes del file exportado
        """
        try:
            if format_type not in self.export_formats:
                raise ValueError(f"Formato {format_type} no soportado")
            
            return self.export_formats[format_type](df, filename)
            
        except Exception as e:
            logger.error(f"Error exportando DataFrame: {e}")
            raise
    
    def export_numpy_array(self, data: np.ndarray, filename: str,
                          metadata: Optional[Dict] = None) -> bytes:
        """
        Export array NumPy como CSV con metadata.
        
        Args:
            data: Array a export
            filename: Nombre del file
            metadata: Metadata opcionales
            
        Returns:
            Bytes del file CSV
        """
        try:
            # Aplanar array si es multidimensional
            if data.ndim > 2:
                # Reshape para 2D manteniendo information spatial
                if data.ndim == 3:
                    nx, ny, nz = data.shape
                    # Crear DataFrame con coordenadas
                    rows = []
                    for k in range(nz):
                        for j in range(ny):
                            for i in range(nx):
                                rows.append({
                                    'x': i,
                                    'y': j,
                                    'z': k,
                                    'value': data[i, j, k]
                                })
                    df = pd.DataFrame(rows)
                else:
                    # Para arrays de más de 3D, usar índices planos
                    flat_data = data.flatten()
                    df = pd.DataFrame({
                        'index': range(len(flat_data)),
                        'value': flat_data
                    })
            elif data.ndim == 2:
                # Crear DataFrame 2D con índices
                df = pd.DataFrame(data)
            else:
                # Array 1D
                df = pd.DataFrame({'value': data})
            
            # Agregar metadata como comentarios si están available
            output = io.StringIO()
            
            if metadata:
                output.write("# Metadata\n")
                for key, value in metadata.items():
                    output.write(f"# {key}: {value}\n")
                output.write("# \n")
            
            df.to_csv(output, index=False)
            
            return output.getvalue().encode('utf-8')
            
        except Exception as e:
            logger.error(f"Error exportando array NumPy: {e}")
            raise
    
    def _export_csv(self, df: pd.DataFrame, filename: str) -> bytes:
        """Export como CSV"""
        output = io.StringIO()
        df.to_csv(output, index=False)
        return output.getvalue().encode('utf-8')
    
    def _export_excel(self, df: pd.DataFrame, filename: str) -> bytes:
        """Export como Excel"""
        output = io.BytesIO()
        with pd.ExcelWriter(output, engine='openpyxl') as writer:
            df.to_excel(writer, sheet_name='Data', index=False)
        return output.getvalue()
    
    def _export_json(self, df: pd.DataFrame, filename: str) -> bytes:
        """Export como JSON"""
        json_str = df.to_json(orient='records', indent=2)
        return json_str.encode('utf-8')

class PlotExporter:
    """Class para export charts"""
    
    def __init__(self):
        """Initialize exportador de charts"""
        self.supported_formats = ['png', 'pdf', 'svg', 'html']
        
        # Configurer Plotly para exportación
        self._setup_plotly_config()
    
    def export_figure(self, fig: go.Figure, filename: str, 
                     format_type: str = 'png', 
                     width: int = 1200, height: int = 800,
                     scale: float = 2.0) -> bytes:
        """
        Export figure de Plotly.
        
        Args:
            fig: Figura de Plotly
            filename: Nombre del file
            format_type: Formato ('png', 'pdf', 'svg', 'html')
            width: Ancho en pixels
            height: Alto en pixels  
            scale: Factor de escala para imágenes
            
        Returns:
            Bytes del file exportado
        """
        try:
            if format_type not in self.supported_formats:
                raise ValueError(f"Formato {format_type} no soportado")
            
            if format_type == 'html':
                return self._export_html(fig, filename)
            elif format_type in ['png', 'pdf', 'svg']:
                return self._export_image(fig, format_type, width, height, scale)
            
        except Exception as e:
            logger.error(f"Error exportando figure: {e}")
            raise
    
    def _export_html(self, fig: go.Figure, filename: str) -> bytes:
        """Export como HTML interactivo"""
        html_str = pio.to_html(fig, include_plotlyjs=True, div_id=filename)
        return html_str.encode('utf-8')
    
    def _export_image(self, fig: go.Figure, format_type: str,
                     width: int, height: int, scale: float) -> bytes:
        """Export como image"""
        try:
            # Intentar exportación con kaleido (recomendado)
            img_bytes = pio.to_image(
                fig, 
                format=format_type,
                width=width,
                height=height,
                scale=scale
            )
            return img_bytes
            
        except Exception as e:
            logger.warning(f"Error con kaleido, intentando método alternativo: {e}")
            
            # Método alternativo para PNG usando plotly
            if format_type == 'png':
                try:
                    img_bytes = fig.to_image(format='png', width=width, height=height, scale=scale)
                    return img_bytes
                except:
                    # Último recurso: export como HTML
                    logger.warning("Fallback a HTML para exportación de image")
                    return self._export_html(fig, "plot")
            else:
                raise
    
    def _setup_plotly_config(self):
        """Configurer Plotly para exportación"""
        try:
            # Configurer renderizador por defecto
            pio.renderers.default = "browser"
            
            # Configurer opciones de exportación
            pio.kaleido.scope.mathjax = None
            
        except Exception as e:
            logger.warning(f"Could not configurer Plotly completely: {e}")

class ReportGenerator:
    """Class para generate reportes completos"""
    
    def __init__(self, data_exporter: DataExporter, plot_exporter: PlotExporter):
        """
        Initialize generador de reportes.
        
        Args:
            data_exporter: Instancia del exportador de data
            plot_exporter: Instancia del exportador de charts
        """
        self.data_exporter = data_exporter
        self.plot_exporter = plot_exporter
    
    def create_simulation_report(self, config: Dict, data_summary: Dict,
                               figures: Dict[str, go.Figure]) -> bytes:
        """
        Crear reporte completo de simulación.
        
        Args:
            config: Configuretion de la simulación
            data_summary: Resumen de data
            figures: Diccionario de figures a incluir
            
        Returns:
            Bytes del file ZIP con el reporte
        """
        try:
            # Crear file ZIP en memoria
            zip_buffer = io.BytesIO()
            
            with zipfile.ZipFile(zip_buffer, 'w', zipfile.ZIP_DEFLATED) as zip_file:
                
                # 1. Archivo de configuretion
                config_json = json.dumps(config, indent=2, default=str)
                zip_file.writestr('01_configuretion.json', config_json)
                
                # 2. Resumen ejecutivo
                summary_text = self._create_executive_summary(config, data_summary)
                zip_file.writestr('02_executive_summary.txt', summary_text)
                
                # 3. Export figures
                for plot_name, fig in figures.items():
                    try:
                        # PNG para visualization
                        png_bytes = self.plot_exporter.export_figure(
                            fig, plot_name, 'png', 1200, 800
                        )
                        zip_file.writestr(f'plots/{plot_name}.png', png_bytes)
                        
                        # HTML para interactividad
                        html_bytes = self.plot_exporter.export_figure(
                            fig, plot_name, 'html'
                        )
                        zip_file.writestr(f'plots/{plot_name}.html', html_bytes)
                        
                    except Exception as e:
                        logger.warning(f"Could not export {plot_name}: {e}")
                
                # 4. Data tabulares si están available
                if 'dataframes' in data_summary:
                    for df_name, df in data_summary['dataframes'].items():
                        if isinstance(df, pd.DataFrame):
                            csv_bytes = self.data_exporter.export_dataframe(df, df_name, 'csv')
                            zip_file.writestr(f'data/{df_name}.csv', csv_bytes)
                
                # 5. Metadata del reporte
                metadata = {
                    'report_generated': datetime.now().isoformat(),
                    'project_name': config.get('metadata', {}).get('project_name', 'N/A'),
                    'version': config.get('metadata', {}).get('version', 'N/A'),
                    'included_plots': list(figures.keys()),
                    'data_files': len(data_summary.get('dataframes', {}))
                }
                
                metadata_json = json.dumps(metadata, indent=2)
                zip_file.writestr('00_report_metadata.json', metadata_json)
            
            zip_buffer.seek(0)
            return zip_buffer.getvalue()
            
        except Exception as e:
            logger.error(f"Error creando reporte: {e}")
            raise
    
    def _create_executive_summary(self, config: Dict, data_summary: Dict) -> str:
        """Crear resumen ejecutivo del reporte"""
        
        summary_lines = [
            "REPORTE DE SIMULACIÓN GEOMECH-ML",
            "=" * 40,
            "",
            f"Fecha de generación: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}",
            f"Proyecto: {config.get('metadata', {}).get('project_name', 'N/A')}",
            f"Versión: {config.get('metadata', {}).get('version', 'N/A')}",
            "",
            "CONFIGURACIÓN DE SIMULACIÓN:",
            "-" * 25,
        ]
        
        # Información del grid
        grid_config = config.get('grid', {})
        summary_lines.extend([
            f"Dimensiones del grid: {grid_config.get('nx', 0)} x {grid_config.get('ny', 0)} x {grid_config.get('nz', 0)}",
            f"Total de celdas: {grid_config.get('nx', 0) * grid_config.get('ny', 0) * grid_config.get('nz', 0):,}",
            f"Tamaño de celda: {grid_config.get('dx', 0)} x {grid_config.get('dy', 0)} ft",
            ""
        ])
        
        # Información de pozos
        wells_config = config.get('wells', {})
        producers = wells_config.get('producers', [])
        injectors = wells_config.get('injectors', [])
        
        summary_lines.extend([
            "CONFIGURACIÓN DE POZOS:",
            "-" * 20,
            f"Pozos productores: {len(producers)}",
            f"Pozos inyectores: {len(injectors)}",
            f"Total de pozos: {len(producers) + len(injectors)}",
            ""
        ])
        
        # Información de simulación
        sim_config = config.get('simulation', {})
        summary_lines.extend([
            "PARÁMETROS DE SIMULACIÓN:",
            "-" * 25,
            f"Tiempo total: {sim_config.get('total_time', 0):,.0f} días ({sim_config.get('total_time', 0)/365:.1f} años)",
            f"Número de timesteps: {sim_config.get('num_timesteps', 0):,}",
            f"Tipo de timestep: {sim_config.get('timestep_type', 'N/A')}",
            ""
        ])
        
        # Información de data
        summary_lines.extend([
            "DATOS INCLUIDOS:",
            "-" * 15,
            f"Archivos de data: {data_summary.get('file_count', 0)}",
            f"Gráficos incluidos: {data_summary.get('plot_count', 0)}",
            f"Tamaño total estimado: {data_summary.get('total_size_mb', 0):.1f} MB",
            ""
        ])
        
        summary_lines.extend([
            "CONTENIDO DEL REPORTE:",
            "-" * 20,
            "• 01_configuretion.json - Configuretion completa de la simulación",
            "• 02_executive_summary.txt - Este resumen ejecutivo", 
            "• plots/ - Gráficos en formato PNG y HTML interactivo",
            "• data/ - Data exportados en formato CSV",
            "• 00_report_metadata.json - Metadata del reporte",
            "",
            "Para visualize los charts interactivos, abra los files .html",
            "en un navegador web. Los data CSV pueden opense en Excel o",
            "importarse en herramientas de analysis.",
            "",
            f"Generado por GeomechML Dashboard v{config.get('metadata', {}).get('version', 'N/A')}",
        ])
        
        return "\n".join(summary_lines)

class ExportManager:
    """Gestor principal de exportaciones"""
    
    def __init__(self):
        """Initialize gestor de exportaciones"""
        self.data_exporter = DataExporter()
        self.plot_exporter = PlotExporter()
        self.report_generator = ReportGenerator(self.data_exporter, self.plot_exporter)
    
    def create_download_button(self, data: bytes, filename: str, 
                             mime_type: str, button_text: str,
                             help_text: Optional[str] = None) -> bool:
        """
        Crear botón de descarga de Streamlit.
        
        Args:
            data: Data a desload
            filename: Nombre del file
            mime_type: Tipo MIME
            button_text: Texto del botón
            help_text: Texto de ayuda opcional
            
        Returns:
            True si se hizo clic en el botón
        """
        return st.download_button(
            label=button_text,
            data=data,
            file_name=filename,
            mime=mime_type,
            help=help_text
        )
    
    def get_mime_type(self, file_extension: str) -> str:
        """
        Obtener tipo MIME basado en extensión.
        
        Args:
            file_extension: Extensión del file
            
        Returns:
            Tipo MIME correspondiente
        """
        mime_map = {
            'csv': 'text/csv',
            'xlsx': 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
            'json': 'application/json',
            'png': 'image/png',
            'pdf': 'application/pdf',
            'svg': 'image/svg+xml',
            'html': 'text/html',
            'zip': 'application/zip',
            'txt': 'text/plain'
        }
        
        return mime_map.get(file_extension.lower(), 'application/octet-stream')
    
    def export_plot_with_options(self, fig: go.Figure, base_filename: str):
        """
        Crear interfaz de exportación de charts con opciones.
        
        Args:
            fig: Figura de Plotly a export
            base_filename: Nombre base del file
        """
        st.markdown("#### 📥 Export Gráfico")
        
        col1, col2, col3 = st.columns(3)
        
        with col1:
            format_type = st.selectbox(
                "Formato:",
                ['png', 'html', 'svg', 'pdf'],
                index=0
            )
        
        with col2:
            if format_type in ['png', 'svg', 'pdf']:
                width = st.number_input("Ancho (px):", min_value=400, max_value=3000, value=1200)
                height = st.number_input("Alto (px):", min_value=300, max_value=2000, value=800)
            else:
                width = height = None
        
        with col3:
            if format_type == 'png':
                scale = st.slider("Calidad:", min_value=1.0, max_value=4.0, value=2.0, step=0.5)
            else:
                scale = 2.0
        
        # Botón de exportación
        if st.button(f"🔽 Desload como {format_type.upper()}"):
            try:
                filename = f"{base_filename}.{format_type}"
                
                if format_type in ['png', 'svg', 'pdf']:
                    data = self.plot_exporter.export_figure(
                        fig, base_filename, format_type, width, height, scale
                    )
                else:
                    data = self.plot_exporter.export_figure(
                        fig, base_filename, format_type
                    )
                
                mime_type = self.get_mime_type(format_type)
                
                self.create_download_button(
                    data, filename, mime_type,
                    f"📁 Desload {filename}",
                    f"Desload chart en formato {format_type.upper()}"
                )
                
                st.success(f"✅ Archivo {filename} preparado para descarga")
                
            except Exception as e:
                st.error(f"❌ Error exportando chart: {str(e)}")
    
    def export_data_with_options(self, df: pd.DataFrame, base_filename: str):
        """
        Crear interfaz de exportación de data con opciones.
        
        Args:
            df: DataFrame a export
            base_filename: Nombre base del file
        """
        st.markdown("#### 📊 Export Data")
        
        col1, col2 = st.columns(2)
        
        with col1:
            format_type = st.selectbox(
                "Formato de data:",
                ['csv', 'excel', 'json'],
                index=0
            )
        
        with col2:
            include_index = st.checkbox("Incluir índice", value=False)
        
        # Mostrar preview de los data
        st.markdown("**Vista previa:**")
        st.dataframe(df.head(), use_container_width=True)
        
        # Botón de exportación
        if st.button(f"🔽 Desload como {format_type.upper()}"):
            try:
                extension = 'xlsx' if format_type == 'excel' else format_type
                filename = f"{base_filename}.{extension}"
                
                # Modificar DataFrame si no se incluye índice
                export_df = df if include_index else df.reset_index(drop=True)
                
                data = self.data_exporter.export_dataframe(export_df, base_filename, format_type)
                mime_type = self.get_mime_type(extension)
                
                self.create_download_button(
                    data, filename, mime_type,
                    f"📁 Desload {filename}",
                    f"Desload data en formato {format_type.upper()}"
                )
                
                st.success(f"✅ Archivo {filename} preparado para descarga")
                
            except Exception as e:
                st.error(f"❌ Error exportando data: {str(e)}")

# Funciones de utilidad para integración con Streamlit
def add_export_section(fig: go.Figure = None, df: pd.DataFrame = None, 
                      base_filename: str = "export"):
    """
    Agregar section de exportación a una página de Streamlit.
    
    Args:
        fig: Figura opcional de Plotly
        df: DataFrame opcional
        base_filename: Nombre base para files
    """
    export_manager = ExportManager()
    
    with st.expander("📥 Opciones de Exportación", expanded=False):
        if fig is not None:
            export_manager.export_plot_with_options(fig, f"{base_filename}_plot")
        
        if df is not None:
            st.markdown("---")
            export_manager.export_data_with_options(df, f"{base_filename}_data")
        
        if fig is None and df is None:
            st.info("No data available para export en esta vista")