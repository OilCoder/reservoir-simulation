# Container Rebuild Instructions

## 🎯 Purpose
Add OPM Flow reservoir simulator to enable hybrid MRST-OPM workflow while maintaining all existing functionality.

## 📋 What's Added to Dockerfile
- **OPM Flow**: Industry-standard reservoir simulator
- **OPM Python bindings**: For programmatic control
- **Eclipse format tools**: For MRST ↔ OPM data exchange

## 🔄 Hybrid Workflow Architecture
```
CURRENT:  s01-s20 → simulateScheduleAD_octave → s22+
HYBRID:   s01-s20 → MRST export → OPM simulation → MRST import → s22+
```

## 🚀 How to Rebuild Container

### Option 1: VS Code Command Palette
1. `Ctrl+Shift+P` → "Remote-Containers: Rebuild Container"
2. Wait for build to complete (~15-20 minutes)

### Option 2: Manual Docker Rebuild
```bash
# From project root
docker build -f .devcontainer/Dockerfile -t eagle-west-omp .
```

### Option 3: Complete Rebuild (if issues)
```bash
# Remove existing container and rebuild from scratch
docker system prune -f
docker build --no-cache -f .devcontainer/Dockerfile -t eagle-west-omp .
```

## ✅ Post-Rebuild Verification

### Test MRST (existing functionality)
```bash
octave s01_initialize_mrst.m
```

### Test OPM Installation
```bash
flow --version
python -c "import opm; print('OPM Python bindings OK')"
python -c "import ecl; print('Eclipse tools OK')"
```

### Test Hybrid Workflow Components
```bash
# Test MRST export capabilities
octave -q --eval "addpath('/opt/mrst'); startup; help writeEclipseDeck"

# Test Python-Octave bridge
python -c "from oct2py import octave; print('Oct2py bridge OK')"
```

## 🎯 Expected Benefits
- **Professional simulator**: OPM Flow for production-grade results
- **Maintain existing work**: All MRST workflow preserved
- **Validation**: Cross-check simulateScheduleAD_octave vs OPM
- **Flexibility**: Switch between solvers as needed

## 🐛 Troubleshooting

### If OPM installation fails:
- Try rebuilding with `--no-cache` flag
- Check Ubuntu version compatibility (container uses 24.04)

### If MRST functionality breaks:
- The Dockerfile preserves all existing MRST setup
- Original simulateScheduleAD_octave solver remains functional

### If Python bindings fail:
- Verify pip packages installed: `pip list | grep -E "(opm|ecl|ert)"`
- Test import in clean Python session

## 📝 Notes
- Build time: ~15-20 minutes (depending on network)
- Container size increase: ~2-3 GB for OPM components
- All existing workflows remain functional
- OPM components are additive, not replacements