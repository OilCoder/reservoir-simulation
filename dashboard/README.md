# MRST Geomechanical Simulation Dashboard

Interactive dashboard for visualizing MRST reservoir simulation results with 3D geological layers and hydrostatic equilibrium.

## 🚀 Quick Start

### Option 1: Interactive Mode
```bash
cd dashboard/
python dashboard.py
```
Launches dashboard interactively. Press Ctrl+C to stop.

### Option 2: Background Service (Recommended)
```bash
cd dashboard/
python start_service.py
```
Starts dashboard as background service that stays running.

**Service Commands:**
- `python stop_service.py` - Stop the service
- `python status_service.py` - Check if running
- `tail -f logs/dashboard.log` - View logs

The dashboard will be available at: **http://localhost:8501**

**Features:**
1. ✅ Check simulation data availability
2. 📊 Load real simulation data from /data/ folder
3. 🌐 Show interactive visualizations
4. 🏔️ 3D geological layer visualization

**Perfect for development!** Service stays running in background.

## 🔬 Running Simulations

The dashboard **only visualizes data** - it doesn't run simulations. To generate data:

```bash
# Navigate to MRST scripts
cd mrst_simulation_scripts/

# Run MRST simulation
octave --eval "s99_run_workflow"
```

This separates simulation (MRST/Octave) from visualization (Dashboard), making it flexible for other simulation software in the future.

## 📊 Dashboard Features

### 📋 Simulation Parameters
- **Reservoir**: 3D grid (20×20×10) with geological layers
- **Wells**: Producer and injector configurations
- **Fluids**: Oil-water system with realistic properties
- **Geomechanics**: Stress-dependent porosity and permeability

### 🗺️ Initial Conditions (t=0)
- **Pressure Maps**: Hydrostatic equilibrium by depth
- **Saturation Maps**: Fluid zones (gas cap, oil zone, water zone)
- **Vertical Profiles**: Pressure and saturation vs depth

### 🏔️ Static Properties
- **Porosity**: Geological layer variations
- **Permeability**: Stratified rock properties
- **Rock Regions**: 10 geological layers (shale, sandstone, limestone)

### 📈 Dynamic Fields
- **Pressure Evolution**: Time-dependent pressure changes
- **Saturation Evolution**: Water flooding progression
- **Field Snapshots**: 2D maps at selected timesteps

### 🛢️ Well Production
- **Production Rates**: Oil and water production
- **Injection Rates**: Water injection
- **Cumulative Production**: Total volumes
- **Recovery Factor**: Oil recovery efficiency

### 🌊 Flow & Velocity
- **Velocity Fields**: Flow direction and magnitude
- **Flow Evolution**: Velocity changes over time

### 📐 Transect Profiles
- **Pressure Profiles**: Horizontal and vertical cuts
- **Saturation Profiles**: Cross-sectional views

## 🏗️ Data Structure

The dashboard uses real MRST simulation data:

```
data/
├── initial/
│   └── initial_conditions.mat    # Initial pressure, saturation, depth
├── static/
│   └── static_data.mat           # Grid, rock regions, wells
├── dynamic/
│   ├── fields/
│   │   ├── field_arrays.mat      # Time-dependent fields
│   │   └── flow_data.mat         # Velocity fields
│   └── wells/
│       ├── well_data.mat         # Production rates
│       └── cumulative_data.mat   # Cumulative volumes
└── metadata/
    └── metadata.mat              # Simulation metadata
```

## 🔧 Technical Details

### 3D Geological Model
- **10 layers** with variable thickness (5-50 ft)
- **Realistic stratigraphy**: Shale cap → Reservoir sands → Aquifer
- **Physics-based properties**: Porosity 2-28%, Permeability 0.001-300 mD

### Initial Conditions
- **Hydrostatic pressure**: P = P_datum + gradient × (depth - datum)
- **Fluid contacts**: GOC @ 7950 ft, OWC @ 8150 ft
- **Saturation zones**: Gas cap, oil zone, water zone with transitions

### Simulation Features
- **Flow-geomechanics coupling**: Stress-dependent rock properties
- **Water flooding**: Injection-production scenario
- **Real physics**: No hard-coded values, all from simulator

## 📋 Requirements

- **Python 3.8+** with packages:
  - streamlit
  - oct2py
  - numpy
  - pandas
  - plotly
  - pyyaml
- **Octave** (for MRST simulation)
- **MRST Toolbox** (included in project)

## 🐛 Troubleshooting

### Missing Data Error
```
❌ Failed to load simulation data
```
**Solution**: Run complete workflow to generate data:
```bash
./start_complete_workflow.sh
```

### Octave/MRST Error
```
❌ MRST simulation failed
```
**Solution**: Check Octave installation and MRST path

### Dashboard Not Loading
```
❌ Dashboard launch failed
```
**Solution**: Install missing packages:
```bash
pip install streamlit oct2py numpy pandas plotly pyyaml
```

## 📁 File Structure

```
dashboard/
├── dashboard.py                  # 🚀 SINGLE FILE - Complete workflow
├── util_data_loader.py           # MRST data loader utility
├── util_visualization.py         # Visualization utility
├── util_metrics.py               # Metrics utility
├── config_reader.py              # Configuration reader utility
├── plots/                        # Visualization modules (optional)
└── README.md                     # This file
```

**Simplified!** Just run `python dashboard.py` for everything.

## 🎯 Key Features

✅ **Real Data**: No dummy data - all from MRST simulation  
✅ **3D Visualization**: Layer selection and vertical profiles  
✅ **Physics-Based**: Hydrostatic equilibrium and fluid contacts  
✅ **Interactive**: Real-time parameter exploration  
✅ **Complete Workflow**: One-click simulation to dashboard  
✅ **Geological Realism**: Stratified reservoir model  

---

🛢️ **Ready to explore your reservoir simulation!**