# 🛢️ Simple MRST Monitoring System

A clean, simplified monitoring system for MRST geomechanical simulations.

## 📁 Structure

```
monitoring/
├── streamlit/              # Web dashboard files
│   ├── app.py             # Main Streamlit application
│   └── utils.py           # Utility functions
├── plot_scripts/          # Plot generation scripts  
│   ├── plot_evolution.py  # Temporal evolution plots
│   ├── plot_maps.py       # Spatial distribution maps
│   └── plot_wells.py      # Well performance plots (placeholder)
├── plots/                 # Generated plot images
│   ├── evolution.png      # Evolution plot
│   ├── maps.png           # Spatial maps
│   └── wells.png          # Wells plot
├── launch.py              # One-click launcher (just press Run!)
└── README.md              # This file
```

## 🚀 Quick Start

### 🎯 **ONE-CLICK SOLUTION**
```bash
cd monitoring/
python launch.py
```

**OR** just click the **"Run"** button in your Python editor! 🖱️

### 🔧 Manual Method (if needed)
```bash
cd monitoring/

# Generate plots individually
python plot_scripts/plot_evolution.py
python plot_scripts/plot_maps.py
python plot_scripts/plot_wells.py

# Launch Streamlit manually
streamlit run streamlit/app.py --server.port 8501 --server.address 127.0.0.1
```

## 📊 What Each Plot Shows

### 📈 Evolution Plot (`plot_evolution.py`)
- **4 subplots showing temporal changes:**
  - Pressure evolution over 50 timesteps
  - Effective stress evolution  
  - Porosity evolution
  - Permeability evolution (log scale)
- **Data source:** All snapshots in `MRST_simulation_scripts/data/snap_*.mat`

### 🗺️ Spatial Maps (`plot_maps.py`)
- **6 maps showing current 20x20 grid distribution:**
  - Pressure map (psi)
  - Effective stress map (psi)
  - Porosity map
  - Permeability map (log scale)
  - Water saturation map (placeholder)
  - Rock regions map
- **Data source:** Latest snapshot in `MRST_simulation_scripts/data/`

### 🏭 Wells Plot (`plot_wells.py`)
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
- **Manual refresh:** Generate all plots on demand
- **Individual plot generation:** Generate specific plots using buttons

### Plot Status
- Shows age of each plot (Fresh, Recent, Old, Missing)
- Color-coded status indicators

### Three Tabs
1. **Evolution:** Temporal evolution plots
2. **Spatial Maps:** Current spatial distribution  
3. **Wells:** Well performance (placeholder)

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