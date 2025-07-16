# MRST Simulation Dashboard - User Guide

## 🚀 Quick Start

### Option 1: Use the Startup Script (Recommended)
```bash
cd /workspaces/simulation/dashboard
./start_dashboard.sh
```

### Option 2: Manual Start
```bash
cd /workspaces/simulation/dashboard
streamlit run s99_run_dashboard.py --server.port=8501 --server.address=0.0.0.0
```

### Option 3: Background Mode
```bash
cd /workspaces/simulation/dashboard
nohup streamlit run s99_run_dashboard.py --server.headless=true --server.port=8501 --server.address=0.0.0.0 > streamlit.log 2>&1 &
```

## 📱 Access the Dashboard

Once started, access the dashboard at:
- **Local**: http://localhost:8501
- **Network**: http://0.0.0.0:8501

## 🎯 Dashboard Features

### 📊 **Simulation Overview**
- Key performance indicators (KPIs)
- Initial pressure and saturation maps
- Simulation summary statistics

### 🏔️ **Reservoir Properties**
- Porosity distribution maps
- Permeability distribution maps
- Property statistics and histograms

### 🛢️ **Production Performance**
- Oil production rates by well
- Water injection rates
- Cumulative production analysis
- Recovery factor evolution

### 📈 **Pressure Evolution**
- Average pressure evolution over time
- Pressure field snapshots at different times
- Interactive time step selection

### 🌊 **Flow Analysis**
- Velocity magnitude evolution
- Flow field snapshots
- Velocity field visualization

## 📂 Data Requirements

The dashboard expects MRST simulation data in this structure:
```
../data/
├── initial/initial_conditions.mat
├── static/static_data.mat
├── dynamic/
│   ├── fields/field_arrays.mat
│   ├── fields/flow_data.mat
│   └── wells/well_data.mat
├── dynamic/wells/cumulative_data.mat
└── metadata/metadata.mat
```

## 🧪 Testing with Dummy Data

If you don't have real simulation data, create dummy data for testing:
```bash
python create_dummy_data.py
```

This creates realistic-looking test data that demonstrates all dashboard features.

## 🔧 Troubleshooting

### Dashboard not showing plots?
1. **Check if Streamlit server is running:**
   ```bash
   ps aux | grep streamlit
   ```

2. **Check if data is loaded:**
   ```bash
   python test_dashboard.py
   ```

3. **Restart the dashboard:**
   ```bash
   pkill -f streamlit
   ./start_dashboard.sh
   ```

### Running Python script directly?
❌ **Don't do this:**
```bash
python s99_run_dashboard.py  # This won't work!
```

✅ **Do this instead:**
```bash
streamlit run s99_run_dashboard.py
```

### Missing data files?
- The dashboard will show "data not available" messages
- Use `create_dummy_data.py` to generate test data
- Check that data files exist in `../data/` directory

## 📊 Plot Categories

### 1. **Initial Conditions (t=0)**
- Pressure maps with color-coded intensity
- Water saturation distribution
- Interactive hover information

### 2. **Static Properties**
- Porosity maps with customizable color scales
- Permeability maps (with optional log scale)
- Rock region classifications
- Property histograms and statistics

### 3. **Dynamic Fields**
- Time-series plots of field averages
- Snapshot viewers with time step selection
- Interactive animations (when available)

### 4. **Well Production**
- Production rate plots by well
- Cumulative production tracking
- Recovery factor evolution
- Water cut analysis

### 5. **Flow & Velocity**
- Velocity field visualizations
- Flow magnitude evolution
- Quiver plots for flow direction

### 6. **Transect Profiles**
- Cross-sectional pressure profiles
- Saturation profiles along transects
- Multiple time step comparisons

## 🔄 Real-time Updates

The dashboard automatically updates when:
- New data files are added to `../data/`
- Existing data files are modified
- The browser page is refreshed

## 💡 Tips for Best Experience

1. **Use a modern browser** (Chrome, Firefox, Safari, Edge)
2. **Refresh the page** if plots don't appear initially
3. **Use the sidebar** to navigate between different views
4. **Hover over plots** for detailed information
5. **Use time step sliders** to explore temporal evolution

## 📝 Logs and Debugging

- **Streamlit logs**: Check `streamlit.log` for server messages
- **Python errors**: Run `python test_dashboard.py` for diagnostics
- **Data loading issues**: Check warning messages in the dashboard

## 🛠️ Files Overview

| File | Purpose |
|------|---------|
| `s99_run_dashboard.py` | Main dashboard application |
| `start_dashboard.sh` | Startup script |
| `create_dummy_data.py` | Dummy data generator |
| `test_dashboard.py` | Functionality tester |
| `plots/` | Hierarchical plot modules |
| `util_*.py` | Utility functions |

## 🎉 Success Indicators

When everything works correctly, you should see:
- ✅ Streamlit server running on port 8501
- ✅ Dashboard loads without errors
- ✅ Plots display with realistic data
- ✅ Interactive features respond to user input
- ✅ Navigation between views works smoothly

---

**Need help?** Run `python test_dashboard.py` to diagnose issues.