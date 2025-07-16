#!/usr/bin/env python3
"""Test script to verify dashboard functionality."""

import sys
import requests
import time
from pathlib import Path

# Add dashboard to path
sys.path.append(str(Path(__file__).parent))

def test_dashboard():
    """Test dashboard functionality."""
    print("🧪 Testing MRST Dashboard...")
    
    # Test 1: Check if Streamlit server is running
    try:
        response = requests.get('http://localhost:8501', timeout=5)
        if response.status_code == 200:
            print("✅ Streamlit server is running")
        else:
            print(f"❌ Streamlit server returned status {response.status_code}")
            return False
    except requests.exceptions.RequestException as e:
        print(f"❌ Cannot connect to Streamlit server: {e}")
        return False
    
    # Test 2: Test data loading
    try:
        from util_data_loader import MRSTDataLoader
        loader = MRSTDataLoader()
        data = loader.load_complete_dataset()
        
        if data is not None and 'initial_conditions' in data:
            print("✅ Data loading works")
            print(f"   Available data: {list(data['availability'].keys())}")
            
            # Count available datasets
            available_count = sum(1 for k, v in data['availability'].items() if v)
            print(f"   Available datasets: {available_count}/10")
        else:
            print("❌ Data loading failed")
            return False
    except Exception as e:
        print(f"❌ Data loading error: {e}")
        return False
    
    # Test 3: Test plot creation
    try:
        from plots.initial_conditions import create_initial_pressure_map
        if data['initial_conditions'] is not None:
            fig = create_initial_pressure_map(data['initial_conditions']['pressure'])
            print("✅ Plot creation works")
        else:
            print("❌ No data available for plotting")
            return False
    except Exception as e:
        print(f"❌ Plot creation error: {e}")
        return False
    
    # Test 4: Test multiple plot types
    try:
        from plots.static_properties import create_porosity_map
        from plots.well_production import create_oil_production_plot
        
        if data['initial_conditions'] is not None:
            fig1 = create_porosity_map(data['initial_conditions']['phi'])
            print("✅ Static properties plots work")
        
        if data['well_data'] is not None:
            fig2 = create_oil_production_plot(data['well_data'])
            print("✅ Well production plots work")
        
    except Exception as e:
        print(f"❌ Multiple plot types error: {e}")
        return False
    
    print("\n🎉 Dashboard test completed successfully!")
    print("📱 Access the dashboard at: http://localhost:8501")
    print("🔄 If plots don't appear, refresh the browser page")
    
    return True

if __name__ == "__main__":
    test_dashboard()