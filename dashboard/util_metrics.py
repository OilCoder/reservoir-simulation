#!/usr/bin/env python3
"""
Performance Metrics Calculator

Calculates key performance indicators and metrics from MRST simulation data.
All calculations follow reservoir engineering principles and provide
product owner focused metrics for decision making.
"""

import numpy as np
from typing import Dict, Any, Optional

# ----------------------------------------
# Step 1 – Main metrics calculator class
# ----------------------------------------

class PerformanceMetrics:
    """
    Calculates key performance indicators for MRST simulation results.
    
    Provides product owner focused metrics including recovery factors,
    production performance, and reservoir efficiency indicators.
    """
    
    def __init__(self, data: Dict[str, Any]):
        """
        Initialize metrics calculator with simulation data.
        
        Args:
            data: Complete simulation dataset
        """
        self.data = data
        
        # 🏴‍ Physical constants (allowed hard-coding per rules)
        self.WATER_DENSITY = 1000.0  # kg/m³
        self.OIL_DENSITY = 850.0  # kg/m³
        self.GRAVITY = 9.81  # m/s²
    
    def calculate_key_performance_indicators(self) -> Dict[str, Any]:
        """
        Calculate key performance indicators for product owner dashboard.
        
        Returns:
            dict: Key performance indicators including grid size, time, wells, recovery
        """
        kpis = {}
        
        # Substep 1.1 – Grid and simulation parameters ______________________
        if 'metadata' in self.data and self.data['metadata']:
            metadata = self.data['metadata']
            grid_dims = metadata.get('grid_dimensions', [20, 20, 1])
            kpis['grid_size'] = f"{grid_dims[0]} × {grid_dims[1]} × {grid_dims[2]}"
            kpis['simulation_days'] = metadata.get('total_time', 365)
        else:
            kpis['grid_size'] = "N/A"
            kpis['simulation_days'] = "N/A"
        
        # Substep 1.2 – Well count ______________________
        if 'well_data' in self.data and self.data['well_data']:
            well_names = self.data['well_data']['well_names']
            kpis['total_wells'] = len(well_names)
        else:
            kpis['total_wells'] = "N/A"
        
        # Substep 1.3 – Final recovery factor ______________________
        if 'cumulative_data' in self.data and self.data['cumulative_data']:
            recovery_factor = self.data['cumulative_data']['recovery_factor']
            if len(recovery_factor) > 0:
                kpis['final_recovery_factor'] = recovery_factor[-1]
            else:
                kpis['final_recovery_factor'] = 0.0
        else:
            kpis['final_recovery_factor'] = 0.0
        
        return kpis
    
    def calculate_recovery_efficiency(self) -> Optional[Dict[str, float]]:
        """
        Calculate recovery efficiency metrics.
        
        Returns:
            dict: Recovery efficiency metrics including sweep and displacement efficiency
        """
        if 'cumulative_data' not in self.data or not self.data['cumulative_data']:
            return None
        
        cumulative_data = self.data['cumulative_data']
        recovery_factor = cumulative_data['recovery_factor']
        
        # ✅ Calculate recovery efficiency metrics
        final_rf = recovery_factor[-1] if len(recovery_factor) > 0 else 0.0
        
        # 📊 Calculate sweep efficiency from saturation data
        sweep_efficiency = self._calculate_sweep_efficiency()
        
        # 📊 Displacement efficiency (simplified calculation)
        displacement_efficiency = final_rf / max(sweep_efficiency, 0.01)  # Avoid division by zero
        
        return {
            'recovery_factor': final_rf,
            'sweep_efficiency': sweep_efficiency,
            'displacement_efficiency': min(displacement_efficiency, 1.0)  # Cap at 100%
        }
    
    def _calculate_sweep_efficiency(self) -> float:
        """
        Calculate sweep efficiency from saturation data.
        
        Returns:
            float: Sweep efficiency as fraction of reservoir volume contacted
        """
        if 'field_arrays' not in self.data or not self.data['field_arrays']:
            return 0.0
        
        field_data = self.data['field_arrays']
        
        # 📊 Use final saturation snapshot
        sw_final = field_data['sw'][-1]  # Last time step
        
        # ✅ Calculate swept volume (cells with sw > initial + 0.1)
        if 'initial_conditions' in self.data and self.data['initial_conditions']:
            sw_initial = self.data['initial_conditions']['sw']
            swept_cells = np.sum(sw_final > (sw_initial + 0.1))
        else:
            # Fallback: assume initial sw = 0.2
            swept_cells = np.sum(sw_final > 0.3)
        
        total_cells = sw_final.size
        
        return swept_cells / total_cells if total_cells > 0 else 0.0
    
    def calculate_production_performance(self) -> Optional[Dict[str, float]]:
        """
        Calculate production performance metrics.
        
        Returns:
            dict: Production performance metrics including rates and cumulative volumes
        """
        if 'well_data' not in self.data or not self.data['well_data']:
            return None
        
        well_data = self.data['well_data']
        
        # ✅ Calculate production metrics
        qOs = well_data['qOs']  # Oil production rates
        qWs = well_data['qWs']  # Water rates (production/injection)
        
        # 📊 Peak production rates
        peak_oil_rate = np.max(np.sum(qOs, axis=1))
        peak_water_rate = np.max(np.sum(qWs, axis=1))
        
        # 📊 Current production rates (last time step)
        current_oil_rate = np.sum(qOs[-1])
        current_water_rate = np.sum(qWs[-1])
        
        # 📊 Production decline analysis
        oil_decline_rate = self._calculate_decline_rate(np.sum(qOs, axis=1))
        
        return {
            'peak_oil_rate': peak_oil_rate,
            'current_oil_rate': current_oil_rate,
            'peak_water_rate': peak_water_rate,
            'current_water_rate': current_water_rate,
            'oil_decline_rate': oil_decline_rate
        }
    
    def _calculate_decline_rate(self, production_rates: np.ndarray) -> float:
        """
        Calculate production decline rate.
        
        Args:
            production_rates: Time series of production rates
            
        Returns:
            float: Decline rate as fraction per unit time
        """
        if len(production_rates) < 2:
            return 0.0
        
        # ✅ Find peak production
        peak_idx = np.argmax(production_rates)
        
        if peak_idx >= len(production_rates) - 1:
            return 0.0
        
        # 📊 Calculate decline from peak to current
        peak_rate = production_rates[peak_idx]
        current_rate = production_rates[-1]
        
        if peak_rate <= 0:
            return 0.0
        
        # 📊 Decline rate calculation
        time_steps = len(production_rates) - peak_idx
        decline_rate = (peak_rate - current_rate) / (peak_rate * time_steps)
        
        return max(decline_rate, 0.0)  # Ensure non-negative
    
    def calculate_pressure_performance(self) -> Optional[Dict[str, float]]:
        """
        Calculate pressure performance metrics.
        
        Returns:
            dict: Pressure performance metrics including decline and maintenance
        """
        if 'field_arrays' not in self.data or not self.data['field_arrays']:
            return None
        
        field_data = self.data['field_arrays']
        pressure_data = field_data['pressure']
        
        # ✅ Calculate spatial averages
        avg_pressure = np.mean(pressure_data, axis=(1, 2))
        
        # 📊 Pressure performance metrics
        initial_pressure = avg_pressure[0]
        current_pressure = avg_pressure[-1]
        min_pressure = np.min(avg_pressure)
        max_pressure = np.max(avg_pressure)
        
        # 📊 Pressure decline rate
        pressure_decline_rate = self._calculate_decline_rate(avg_pressure)
        
        # 📊 Pressure maintenance ratio
        pressure_maintenance = current_pressure / initial_pressure if initial_pressure > 0 else 0.0
        
        return {
            'initial_pressure': initial_pressure,
            'current_pressure': current_pressure,
            'min_pressure': min_pressure,
            'max_pressure': max_pressure,
            'pressure_decline_rate': pressure_decline_rate,
            'pressure_maintenance': pressure_maintenance
        }
    
    def calculate_injection_efficiency(self) -> Optional[Dict[str, float]]:
        """
        Calculate water injection efficiency metrics.
        
        Returns:
            dict: Injection efficiency metrics including voidage ratio and pattern efficiency
        """
        if 'well_data' not in self.data or not self.data['well_data']:
            return None
        
        well_data = self.data['well_data']
        
        # ✅ Calculate injection and production totals
        qOs = well_data['qOs']  # Oil production
        qWs = well_data['qWs']  # Water (injection/production)
        
        # 📊 Separate injection and production wells
        total_oil_production = np.sum(qOs, axis=1)
        total_water_injection = np.sum(np.maximum(qWs, 0), axis=1)  # Only positive rates
        total_water_production = np.sum(np.minimum(qWs, 0), axis=1)  # Only negative rates
        
        # 📊 Voidage ratio calculation
        total_liquid_production = total_oil_production + np.abs(total_water_production)
        voidage_ratio = np.mean(total_water_injection / np.maximum(total_liquid_production, 1e-6))
        
        # 📊 Injection efficiency
        if 'cumulative_data' in self.data and self.data['cumulative_data']:
            recovery_factor = self.data['cumulative_data']['recovery_factor']
            final_rf = recovery_factor[-1] if len(recovery_factor) > 0 else 0.0
            
            # 📊 Simple injection efficiency metric
            injection_efficiency = final_rf / max(voidage_ratio, 0.01)
        else:
            injection_efficiency = 0.0
        
        return {
            'voidage_ratio': voidage_ratio,
            'injection_efficiency': min(injection_efficiency, 1.0),
            'total_water_injected': np.sum(total_water_injection),
            'total_liquid_produced': np.sum(total_liquid_production)
        }
    
    def calculate_flow_performance(self) -> Optional[Dict[str, float]]:
        """
        Calculate flow performance metrics.
        
        Returns:
            dict: Flow performance metrics including velocity and flow patterns
        """
        if 'flow_data' not in self.data or not self.data['flow_data']:
            return None
        
        flow_data = self.data['flow_data']
        velocity_magnitude = flow_data['velocity_magnitude']
        
        # ✅ Calculate flow metrics
        avg_velocity = np.mean(velocity_magnitude, axis=(1, 2))
        
        # 📊 Flow performance indicators
        peak_velocity = np.max(avg_velocity)
        current_velocity = avg_velocity[-1]
        velocity_stability = np.std(avg_velocity) / np.mean(avg_velocity) if np.mean(avg_velocity) > 0 else 0.0
        
        # 📊 Flow uniformity (coefficient of variation)
        final_velocity_field = velocity_magnitude[-1]
        flow_uniformity = np.std(final_velocity_field) / np.mean(final_velocity_field) if np.mean(final_velocity_field) > 0 else 0.0
        
        return {
            'peak_velocity': peak_velocity,
            'current_velocity': current_velocity,
            'velocity_stability': velocity_stability,
            'flow_uniformity': flow_uniformity,
            'average_velocity': np.mean(avg_velocity)
        }
    
    def calculate_comprehensive_metrics(self) -> Dict[str, Any]:
        """
        Calculate comprehensive performance metrics for product owner dashboard.
        
        Returns:
            dict: Comprehensive metrics including all performance indicators
        """
        metrics = {
            'kpis': self.calculate_key_performance_indicators(),
            'recovery_efficiency': self.calculate_recovery_efficiency(),
            'production_performance': self.calculate_production_performance(),
            'pressure_performance': self.calculate_pressure_performance(),
            'injection_efficiency': self.calculate_injection_efficiency(),
            'flow_performance': self.calculate_flow_performance()
        }
        
        return metrics