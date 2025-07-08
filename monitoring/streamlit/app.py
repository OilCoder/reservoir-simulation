#!/usr/bin/env python3
"""
MRST Monitoring Dashboard - Individual Plots by Category
Organized according to user's comprehensive guide (A-H categories)
"""

import streamlit as st
import os
from pathlib import Path
import glob


def get_plot_path(plot_name):
    """Get full path to plot file"""
    plots_dir = Path(__file__).parent.parent / "plots"
    return plots_dir / plot_name


def display_plot_if_exists(plot_path, alt_text="Plot not available"):
    """Display plot if it exists, otherwise show message"""
    if plot_path.exists():
        st.image(str(plot_path), use_column_width=True)
    else:
        st.warning(f"⚠️ {alt_text}")
        st.info(f"Expected path: {plot_path}")


def main():
st.set_page_config(
        page_title="MRST Monitoring Dashboard",
    page_icon="🛢️",
    layout="wide",
    initial_sidebar_state="expanded"
)

    # Main title
    st.title("🛢️ MRST Reservoir Monitoring Dashboard")
    st.markdown("**Individual Plots Organized by Scientific Categories**")
    st.markdown("---")
    
    # Sidebar for category selection
    st.sidebar.title("📊 Plot Categories")
    st.sidebar.markdown("Select a category to view individual plots:")
    
    category = st.sidebar.selectbox(
        "Choose Category:",
        [
            "A - Fluid & Rock Properties",
            "B - Initial Conditions", 
            "C - Reservoir Configuration",
            "D - Operational Schedule",
            "E - Global Evolution",
            "F - Well Performance",
            "G - Spatial Maps",
            "H - Multiphysics Analysis"
        ]
    )
    
    # Category A: Fluid & Rock Properties
    if category == "A - Fluid & Rock Properties":
        st.header("🧪 Category A: Fluid & Rock Properties")
        st.markdown("**Question Focus**: How do fluid and rock properties affect flow behavior?")
        
        tab1, tab2, tab3, tab4, tab5 = st.tabs([
            "A-1: Kr Curves", 
            "A-2: PVT Properties", 
            "A-3: Porosity Histogram",
            "A-3: Permeability Histogram", 
            "A-4: k-φ Cross-plot"
        ])
        
        with tab1:
            st.subheader("A-1: Relative Permeability Curves")
            st.markdown("**Question**: How easily does each phase move according to saturation?")
            st.markdown("**Axes**: X = Water Saturation Sw (-), Y = kr,w, kr,o (-)")
            display_plot_if_exists(get_plot_path("A-1_kr_curves.png"))
            
        with tab2:
            st.subheader("A-2: PVT Properties")
            st.markdown("**Question**: How much do fluids expand/contract and how does viscosity change with P?")
            st.markdown("**Axes**: X = Pressure P (psi), Y = B (RB/STB) or μ (cP), Color = Phase")
            display_plot_if_exists(get_plot_path("A-2_pvt_properties.png"))
            
        with tab3:
            st.subheader("A-3: Porosity Distribution")
            st.markdown("**Question**: How dispersed are initial porosity properties?")
            st.markdown("**Axes**: X = Porosity φ, Y = Frequency (# cells)")
            display_plot_if_exists(get_plot_path("A-3_porosity_histogram.png"))
            
        with tab4:
            st.subheader("A-3: Permeability Distribution")
            st.markdown("**Question**: How dispersed are initial permeability properties?")
            st.markdown("**Axes**: X = Log₁₀ Permeability k (mD), Y = Frequency (# cells)")
            display_plot_if_exists(get_plot_path("A-3_permeability_histogram.png"))
            
        with tab5:
            st.subheader("A-4: k-φ Cross-plot")
            st.markdown("**Question**: Does k ∝ φⁿ law hold under stress?")
            st.markdown("**Axes**: X = Porosity φ (-), Y = log₁₀ k (mD), Color = Effective stress σ′ (psi)")
            display_plot_if_exists(get_plot_path("A-4_k_phi_crossplot.png"))
    
    # Category B: Initial Conditions
    elif category == "B - Initial Conditions":
        st.header("🎯 Category B: Initial Conditions")
        st.markdown("**Question Focus**: Are initial conditions properly set?")
        
        tab1, tab2 = st.tabs([
            "B-1: Initial Sw Map",
            "B-2: Initial Pressure Map"
        ])
        
        with tab1:
            st.subheader("B-1: Initial Water Saturation Map")
            st.markdown("**Question**: Are there water patches that could cause early breakthrough?")
            st.markdown("**Axes**: X = X-coord (m), Y = Y-coord (m), Color = Sw (color scale)")
            display_plot_if_exists(get_plot_path("B-1_sw_initial.png"))
            
        with tab2:
            st.subheader("B-2: Initial Pressure Map")
            st.markdown("**Question**: Is initial hydrostatic gradient correct?")
            st.markdown("**Axes**: X = X (m), Y = Y (m), Color = Pressure (psi)")
            display_plot_if_exists(get_plot_path("B-2_pressure_initial.png"))
    
    # Category C: Reservoir Configuration
    elif category == "C - Reservoir Configuration":
        st.header("🏗️ Category C: Reservoir Configuration")
        st.markdown("**Question Focus**: Is the reservoir and well configuration appropriate?")
        
        tab1, tab2, tab3 = st.tabs([
            "C-1: Well Locations",
            "C-2: Rock Regions",
            "C-3: Well Completions"
        ])
        
        with tab1:
            st.subheader("C-1: Well Pattern (XY View)")
            st.markdown("**Question**: Does drainage and injection pattern cover the reservoir?")
            st.markdown("**Axes**: X = X (m), Y = Y (m), Markers = Well type (I vs P)")
            display_plot_if_exists(get_plot_path("C-1_well_locations.png"))
            
        with tab2:
            st.subheader("C-2: Rock Region Map")
            st.markdown("**Question**: Where do lithological properties change?")
            st.markdown("**Axes**: X = X, Y = Y, Color = rock_id")
            display_plot_if_exists(get_plot_path("C-2_rock_regions.png"))
            
        with tab3:
            st.subheader("C-3: Well Completion Intervals")
            st.markdown("**Question**: Are completion intervals optimally placed?")
            st.markdown("**Axes**: X = Depth (m), Y = Well ID, Color = Well type")
            display_plot_if_exists(get_plot_path("C-3_well_completions.png"))
    
    # Category D: Operational Schedule
    elif category == "D - Operational Schedule":
        st.header("⏰ Category D: Operational Schedule")
        st.markdown("**Question Focus**: Are operational schedules properly timed?")
        
        tab1, tab2, tab3, tab4 = st.tabs([
            "D-1: Rate Schedule",
            "D-2: BHP Limits", 
            "D-3: Voidage Ratio",
            "D-4: PV vs Recovery"
        ])
        
        with tab1:
            st.subheader("D-1: Production/Injection Rate Program")
            st.markdown("**Question**: Are filling, sweep, and taper stages well timed?")
            st.markdown("**Axes**: X = Time (d), Y = Rate (STB/d), Color = Phase/Well")
            display_plot_if_exists(get_plot_path("D-1_rate_schedule.png"))
            
        with tab2:
            st.subheader("D-2: BHP Constraint Limits")
            st.markdown("**Question**: Do wells respect integrity restrictions?")
            st.markdown("**Axes**: X = Time, Y = Pressure (psi), Color = Well")
            display_plot_if_exists(get_plot_path("D-2_bhp_limits.png"))
            
        with tab3:
            st.subheader("D-3: Voidage Ratio")
            st.markdown("**Question**: Is volumetric balance conserved? (Target ≤ 0.5%)")
            st.markdown("**Axes**: X = Time, Y = ΔVolume (% PV)")
            display_plot_if_exists(get_plot_path("D-3_voidage_ratio.png"))
            
        with tab4:
            st.subheader("D-4: PV Injected vs Recovery")
            st.markdown("**Question**: How efficient is the sweep?")
            st.markdown("**Axes**: X = PV injected (% of initial PV), Y = RF (% OOIP recovered)")
            display_plot_if_exists(get_plot_path("D-4_pv_vs_recovery.png"))
    
    # Category E: Global Evolution
    elif category == "E - Global Evolution":
        st.header("📈 Category E: Global Evolution")
        st.markdown("**Question Focus**: How do field-average properties evolve over time?")
        
        tab1, tab2, tab3, tab4, tab5 = st.tabs([
            "E-1: Pressure Evolution",
            "E-2: Stress Evolution",
            "E-3: Porosity Evolution", 
            "E-4: Permeability Evolution",
            "E-5: Saturation Histogram"
        ])
        
        with tab1:
            st.subheader("E-1: Average Pressure + Range")
            st.markdown("**Question**: Is the reservoir depleting or maintaining pressure?")
            st.markdown("**Axes**: X = Time, Y = Pressure (psi), Band = p₅-p₉₅ range")
            display_plot_if_exists(get_plot_path("E-1_pressure_evolution.png"))
            
        with tab2:
            st.subheader("E-2: Average Effective Stress + Range")
            st.markdown("**Question**: Is compaction progressing or reversing?")
            st.markdown("**Axes**: X = Time, Y = σ′ (psi), Band = range")
            display_plot_if_exists(get_plot_path("E-2_stress_evolution.png"))
            
        with tab3:
            st.subheader("E-3: Average Porosity + Range")
            st.markdown("**Question**: Is Δφ ≤ 1% tolerance met?")
            st.markdown("**Axes**: X = Time, Y = φ (-), Band = range")
            display_plot_if_exists(get_plot_path("E-3_porosity_evolution.png"))
            
        with tab4:
            st.subheader("E-4: Average Permeability + Range")
            st.markdown("**Question**: Is Δk ≤ 5% and noise-free?")
            st.markdown("**Axes**: X = Time, Y = log₁₀ k, Band = range")
            display_plot_if_exists(get_plot_path("E-4_permeability_evolution.png"))
            
        with tab5:
            st.subheader("E-5: Evolutionary Saturation Histogram")
            st.markdown("**Question**: Does the front disperse (histogram widening)?")
            st.markdown("**Axes**: X = Sw, Y = Frequency, Stacked = Snapshots")
            display_plot_if_exists(get_plot_path("E-5_saturation_histogram.png"))
    
    # Category F: Well Performance
    elif category == "F - Well Performance":
        st.header("🔧 Category F: Well Performance")
        st.markdown("**Question Focus**: How are individual wells performing?")
        
        tab1, tab2, tab3, tab4 = st.tabs([
            "F-1: BHP by Well",
            "F-2: Instantaneous Rates",
            "F-3: Cumulative Production",
            "F-4: Water Cut"
        ])
        
        with tab1:
            st.subheader("F-1: BHP by Well")
            st.markdown("**Question**: Are any wells choked/fracturing formations?")
            st.markdown("**Axes**: X = Time, Y = BHP (psi), Color = Well")
            display_plot_if_exists(get_plot_path("F-1_bhp_by_well.png"))
            
        with tab2:
            st.subheader("F-2: Instantaneous Rates qₒ, qw")
            st.markdown("**Question**: What is productivity and water-cut?")
            st.markdown("**Axes**: X = Time, Y = Rate (STB/d), Color = Phase/Well")
            display_plot_if_exists(get_plot_path("F-2_instantaneous_rates.png"))
            
        with tab3:
            st.subheader("F-3: Cumulative Production")
            st.markdown("**Question**: Recovery factor by well?")
            st.markdown("**Axes**: X = Time, Y = Cumulative Volume (STB), Color = Oil vs Water")
            display_plot_if_exists(get_plot_path("F-3_cumulative_production.png"))
            
        with tab4:
            st.subheader("F-4: Water Cut")
            st.markdown("**Question**: When is breakthrough and how does cut evolve?")
            st.markdown("**Axes**: X = Time, Y = Fraction (-), Color = Well")
            display_plot_if_exists(get_plot_path("F-4_water_cut.png"))
    
    # Category G: Spatial Maps
    elif category == "G - Spatial Maps":
        st.header("🗺️ Category G: Spatial Maps")
        st.markdown("**Question Focus**: How do properties vary spatially? (All maps show well locations)")
        
        tab1, tab2, tab3, tab4, tab5, tab6, tab7, tab8 = st.tabs([
            "G-1: Pressure Map",
            "G-2: Stress Map", 
            "G-3: Porosity Map",
            "G-4: Permeability Map",
            "G-5: Saturation Map",
            "G-6: ΔPressure Map",
            "G-7: Water Front",
            "G-8: Streamlines"
        ])
        
        with tab1:
            st.subheader("G-1: Pressure Map")
            st.markdown("**Question**: Where are pressure cones and low connectivity zones?")
            st.markdown("**Axes**: X = X, Y = Y, Color = Pressure")
            
            col1, col2 = st.columns(2)
            with col1:
                st.markdown("**Static Map**")
                display_plot_if_exists(get_plot_path("G-1_pressure_map.png"))
            with col2:
                st.markdown("**Animated (GIF)**")
                display_plot_if_exists(get_plot_path("G-1_pressure_map_animated.gif"))
            
        with tab2:
            st.subheader("G-2: Effective Stress Map")
            st.markdown("**Question**: Where is compaction concentrated?")
            st.markdown("**Axes**: X = X, Y = Y, Color = σ′")
            display_plot_if_exists(get_plot_path("G-2_stress_map.png"))
            
        with tab3:
            st.subheader("G-3: Porosity Map")
            st.markdown("**Question**: Spatial heterogeneity + compaction effects?")
            st.markdown("**Axes**: X = X, Y = Y, Color = φ")
            display_plot_if_exists(get_plot_path("G-3_porosity_map.png"))
            
        with tab4:
            st.subheader("G-4: Permeability Map")
            st.markdown("**Question**: Where are high permeability channels?")
            st.markdown("**Axes**: X = X, Y = Y, Color = log₁₀ k")
            display_plot_if_exists(get_plot_path("G-4_permeability_map.png"))
            
        with tab5:
            st.subheader("G-5: Water Saturation Map")
            st.markdown("**Question**: Where is the current water front?")
            st.markdown("**Axes**: X = X, Y = Y, Color = Sw")
            
            col1, col2 = st.columns(2)
            with col1:
                st.markdown("**Static Map**")
                display_plot_if_exists(get_plot_path("G-5_saturation_map.png"))
            with col2:
                st.markdown("**Animated (GIF)**")
                display_plot_if_exists(get_plot_path("G-5_saturation_map_animated.gif"))
            
        with tab6:
            st.subheader("G-6: Pressure Difference Map (p - p₀)")
            st.markdown("**Question**: Where is overpressure/underpressure induced?")
            st.markdown("**Axes**: X = X, Y = Y, Color = ΔP")
            display_plot_if_exists(get_plot_path("G-6_pressure_difference_map.png"))
            
        with tab7:
            st.subheader("G-7: Water Front Contour (Sw ≥ 0.8)")
            st.markdown("**Question**: Contour of water advance?")
            st.markdown("**Axes**: X = X, Y = Y, Contour = Isolines")
            display_plot_if_exists(get_plot_path("G-7_water_front_contour.png"))
            
        with tab8:
            st.subheader("G-8: Streamlines")
            st.markdown("**Question**: High flow routes (identify channeling)?")
            st.markdown("**Axes**: X = X, Y = Y, Lines = Flow direction + width ~ flow")
            display_plot_if_exists(get_plot_path("G-8_streamlines.png"))
    
    # Category H: Multiphysics Analysis
    elif category == "H - Multiphysics Analysis":
        st.header("🔬 Category H: Multiphysics Analysis")
        st.markdown("**Question Focus**: How do coupled physics affect reservoir behavior?")
        
        tab1, tab2, tab3 = st.tabs([
            "H-1: Fractional Flow",
            "H-2: Sensitivity Analysis",
            "H-3: Voidage Ratio"
        ])
        
        with tab1:
            st.subheader("H-1: Fractional Flow fw vs Sw")
            st.markdown("**Question**: How does global reservoir state compare to Buckley-Leverett theory?")
            st.markdown("**Axes**: X = Sw, Y = fw = qw/(qw+qo), Points = Simulation data")
            display_plot_if_exists(get_plot_path("H-1_fractional_flow.png"))
            
        with tab2:
            st.subheader("H-2: Tornado Sensitivity Analysis")
            st.markdown("**Question**: Which parameter most affects production?")
            st.markdown("**Axes**: X = Ordered Parameters, Y = ΔProduction (STB), Format = Horizontal bars")
            display_plot_if_exists(get_plot_path("H-2_tornado_sensitivity.png"))
            
    with tab3:
            st.subheader("H-3: Voidage Ratio Analysis")
            st.markdown("**Question**: Volume balance and reservoir management?")
            st.markdown("**Axes**: X = Time, Y = Injection - Production ratio")
            display_plot_if_exists(get_plot_path("H-3_voidage_ratio.png"))
    
    # Footer
    st.markdown("---")
    st.markdown("**Dashboard Features:**")
    st.markdown("• **Individual plots** - No subplots, each plot addresses specific question")
    st.markdown("• **Well locations** - All spatial maps show producer/injector positions")
    st.markdown("• **Animated GIFs** - Time-dependent maps show evolution")
    st.markdown("• **Scientific organization** - Categories A-H follow reservoir engineering logic")
    
    # Plot statistics
    plots_dir = Path(__file__).parent.parent / "plots"
    if plots_dir.exists():
        plot_files = list(plots_dir.glob("*.png")) + list(plots_dir.glob("*.gif"))
        st.sidebar.markdown("---")
        st.sidebar.markdown(f"**📊 Total Plots Available: {len(plot_files)}**")
        
        # Count by category
        categories = {
            'A': len([f for f in plot_files if f.name.startswith('a')]),
            'B': len([f for f in plot_files if f.name.startswith('b')]),
            'C': len([f for f in plot_files if f.name.startswith('c')]),
            'D': len([f for f in plot_files if f.name.startswith('d')]),
            'E': len([f for f in plot_files if f.name.startswith('e')]),
            'F': len([f for f in plot_files if f.name.startswith('f')]),
            'G': len([f for f in plot_files if f.name.startswith('g')]),
            'H': len([f for f in plot_files if f.name.startswith('h')])
        }
        
        for cat, count in categories.items():
            if count > 0:
                st.sidebar.markdown(f"• Category {cat}: {count} plots")


if __name__ == "__main__":
    main() 