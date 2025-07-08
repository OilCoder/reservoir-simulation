# 🛢️ MRST Monitoring System - Category-Based Analysis

Advanced monitoring system for MRST geomechanical simulations organized into 8 analysis categories.

## 📁 Structure

```
monitoring/
├── streamlit/              # Web dashboard files
│   ├── app.py             # Category-based Streamlit application
│   └── utils.py           # Utility functions
├── plot_scripts/          # Plot generation scripts  
│   ├── plot_config_geometry.py     # Combined geometry plots
│   ├── plot_config_wells.py        # Combined wells plots
│   ├── plot_config_fluids.py       # Combined fluids plots
│   ├── plot_evolution.py           # Combined evolution plots
│   ├── plot_maps.py                # Combined spatial maps
│   ├── plot_wells.py               # Combined well performance
│   ├── plot_individual_*.py        # Individual plot scripts
│   └── [future individual scripts] # More individual plots
├── plots/                 # Generated plot images
│   ├── config_*.png              # Configuration plots
│   ├── evolution.png             # Evolution plots
│   ├── maps.png                  # Spatial maps
│   ├── wells.png                 # Wells plots
│   └── [individual_plots].png    # Individual plot files
├── launch.py              # One-click launcher (just press Run!)
└── README.md              # This file
```

## 🗂️ Analysis Categories

The dashboard is organized into 8 analysis categories based on reservoir engineering workflow:

### A. 🧪 Fluid & Rock Properties (Static)
- Relative permeability curves kr,w, kr,o(Sw)
- PVT properties (Bo, Bw, μo, μw vs P)
- Porosity and permeability histograms
- Cross-plot log k vs φ (proposed)

### B. 🎯 Initial Conditions
- Initial water saturation distribution
- Initial pressure map (proposed)

### C. 🏗️ Geometry & Well Locations
- Well locations (XY plane)
- Completion intervals
- Rock regions map
- Grid structure

### D. 📅 Operational Strategy
- Rate schedule (injection/production)
- BHP constraints (min/max)
- Voidage balance curve (proposed)

### E. 📈 Global Evolution (Time Series)
- Pressure evolution (average + range)
- Effective stress evolution
- Porosity evolution
- Permeability evolution
- Formation factor evolution (proposed)
- PV injected vs recovery factor (proposed)
- Sw histogram evolution (proposed)

### F. 🏭 Well Performance
- BHP evolution (producers vs injectors)
- Production rates (oil/water)
- Cumulative production
- Water cut evolution
- BHP distribution analysis (proposed)

### G. 🗺️ Spatial Distributions (Maps)
- Pressure 2D maps
- Effective stress 2D maps
- Porosity 2D maps
- Permeability 2D maps (log scale)
- Water saturation 2D maps
- ΔPressure maps (proposed)
- Sw front tracking (proposed)
- Streamlines (proposed)
- Vertical sections (proposed)

### H. 🔬 Multiphysics & Advanced Diagnostics
- Fractional flow fw(Sw) curves
- dkr/dSw sensitivity analysis
- Voidage ratio evolution
- Sensitivity tornado charts

## 🚀 Quick Start

### 🎯 **ONE-CLICK SOLUTION**
```bash
cd monitoring/
python launch.py
```

**OR** just click the **"Run"** button in your Python editor! 🖱️

This will:
1. Generate all combined plots (config, evolution, maps, wells)
2. Generate example individual plots
3. Launch the category-based dashboard
4. Open browser automatically

### 🔧 Manual Method (if needed)
```bash
cd monitoring/

# Generate combined plots
python plot_scripts/plot_config_geometry.py
python plot_scripts/plot_config_wells.py
python plot_scripts/plot_config_fluids.py
python plot_scripts/plot_evolution.py
python plot_scripts/plot_maps.py
python plot_scripts/plot_wells.py

# Generate individual plots (examples)
python plot_scripts/plot_individual_kr_curves.py
python plot_scripts/plot_individual_pressure_evolution.py

# Launch Streamlit manually
streamlit run streamlit/app.py --server.port 8501 --server.address 127.0.0.1
```

## 🎛️ Dashboard Navigation

The new dashboard features:

1. **Category Selection**: Choose from 8 analysis categories (A-H) in the sidebar
2. **Individual Tabs**: Each plot gets its own tab within the category
3. **Plot Controls**: Refresh individual plots or entire categories
4. **Status Indicators**: Shows which plots are implemented vs proposed
5. **Smart Fallbacks**: Shows relevant sections from combined plots when individual plots aren't available yet

## 📊 What Each Plot Shows

### 🏗️ Configuration Plots

#### 🏗️ Geometry & Static Properties (`plot_config_geometry.py`)
- **4 subplots showing reservoir setup:**
  - Grid structure overview (20×20 Cartesian)
  - Initial porosity distribution
  - Initial permeability distribution (log scale)
  - Rock facies distribution
- **Data source:** `MRST_simulation_scripts/data/initial_setup.mat`

#### 🏭 Wells & Operations (`plot_config_wells.py`)
- **4 subplots showing well configuration:**
  - Well locations map (top view)
  - Well completion intervals
  - Operational schedule timeline
  - Pressure constraints
- **Note:** Uses example well configuration data

#### 🧪 Fluids & Initial Conditions (`plot_config_fluids.py`)
- **4 subplots showing fluid properties:**
  - Relative permeability curves (Kr vs Sw)
  - PVT properties (Bo, Bw, viscosities)
  - Initial water saturation distribution
  - Property histograms (porosity & permeability)
- **Note:** Uses typical reservoir fluid data

### 📊 Results Plots

#### 📈 Evolution Plot (`plot_evolution.py`)
- **4 subplots showing temporal changes:**
  - Pressure evolution over 50 timesteps
  - Effective stress evolution  
  - Porosity evolution
  - Permeability evolution (log scale)
- **Data source:** All snapshots in `MRST_simulation_scripts/data/snap_*.mat`

#### 🗺️ Spatial Maps (`plot_maps.py`)
- **6 maps showing current 20x20 grid distribution:**
  - Pressure map (psi)
  - Effective stress map (psi)
  - Porosity map
  - Permeability map (log scale)
  - Water saturation map (placeholder)
  - Rock regions map
- **Data source:** Latest snapshot in `MRST_simulation_scripts/data/`

#### 🏭📊 Wells Performance (`plot_wells.py`)
- **4 subplots with well performance (placeholder):**
  - Bottom hole pressure (BHP)
  - Production rates
  - Cumulative production
  - Water cut evolution
- **Note:** Currently uses placeholder data since well data is not in snapshots

## 🔧 Requirements

### Python Dependencies
```bash
pip install streamlit matplotlib numpy scipy
```

### Data Requirements
- Simulation snapshots in `MRST_simulation_scripts/data/snap_*.mat`
- Each snapshot should contain: `pressure`, `sigma_eff`, `phi`, `k`, `rock_id`

## 🌐 Dashboard Features

### Interactive Controls
- **Auto-refresh:** Automatically refresh plots every 30 seconds
- **Group refresh:** Refresh configuration or results plots separately
- **Individual plot generation:** Generate specific plots using buttons

### Plot Status
- Shows age of each plot (Fresh, Recent, Old, Missing)
- Color-coded status indicators
- Organized by Configuration and Results groups

### Two Main Tabs
1. **🏗️ Configuration:** Shows reservoir setup (geometry, wells, fluids)
2. **📊 Results:** Shows simulation results (evolution, maps, wells performance)

## 🔍 Troubleshooting

### Dashboard Not Loading
1. **Check Streamlit installation:**
   ```bash
   pip install streamlit
   streamlit --version
   ```

2. **Check port availability:**
   ```bash
   netstat -tlnp | grep 8501
   ```

3. **Try different methods:**
   ```bash
   # Method A: Direct execution
   streamlit run streamlit/app.py --server.port 8501 --server.address 0.0.0.0
   
   # Method B: Using our runner
   python run_streamlit.py
   
   # Method C: Using launcher
   python launch.py --dashboard-only
   ```

4. **For container environments:**
   ```bash
   # Add headless flag
   streamlit run streamlit/app.py --server.port 8501 --server.address 0.0.0.0 --server.headless true
   ```

### No Plots Generated
1. **Check data availability:**
   ```bash
   ls -la ../MRST_simulation_scripts/data/snap_*.mat
   ```

2. **Test individual scripts:**
   ```bash
   python plot_scripts/plot_evolution.py
   python plot_scripts/plot_maps.py
   python plot_scripts/plot_wells.py
   ```

3. **Check for errors:**
   ```bash
   python plot_scripts/plot_evolution.py 2>&1 | head -20
   ```

### Data Not Found
- Ensure you've run the Phase 1 simulation to generate snapshots
- Check that `MRST_simulation_scripts/data/snap_*.mat` files exist
- Verify file permissions and paths

### Container/WSL Issues
- Use `0.0.0.0` instead of `localhost` for server address
- Add `--server.headless true` flag
- Ensure port 8501 is exposed in container configuration

## 📋 Usage Examples

### Basic Usage
```bash
# From monitoring/ directory
python launch.py
```
Then open http://localhost:8501 in your browser.

### Generate Fresh Plots
```bash
# Generate all plots without launching dashboard
python launch.py --plots-only

# Then launch dashboard with fresh plots
python run_streamlit.py
```

### Run Individual Plot Scripts
```bash
# From monitoring/ directory
python plot_scripts/plot_evolution.py
python plot_scripts/plot_maps.py  
python plot_scripts/plot_wells.py
```

### Container Environment
```bash
# For Docker/WSL environments
streamlit run streamlit/app.py --server.port 8501 --server.address 0.0.0.0 --server.headless true --browser.gatherUsageStats false
```

## 🎯 Key Differences from Old System

### ✅ Simplified
- Only 2 folders: `streamlit/` and `plot_scripts/`
- 3 plot types instead of 6+ monitoring systems
- Single launcher instead of multiple scripts

### ✅ Data-Driven
- Reads directly from `MRST_simulation_scripts/data/`
- No complex data bridges or adapters
- Simple Octave file parsing with custom parser

### ✅ Self-Contained
- No dependencies on complex monitoring classes
- Each plot script is independent
- Simple utility functions

### ✅ User-Friendly
- Clear visual status indicators
- Simple button-based controls
- Informative error messages

---

**🎉 Enjoy the simplified MRST monitoring experience!** 