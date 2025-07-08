#!/usr/bin/env python3
"""
MRST Monitoring System - Launcher único
Genera plots individuales organizados por categorías y lanza dashboard
"""

import subprocess
import sys
import time
import webbrowser
from pathlib import Path


def kill_existing_streamlit():
    """Kill any existing Streamlit processes"""
    try:
        subprocess.run(["pkill", "-f", "streamlit"],
                       capture_output=True, text=True)
        print("🧹 Cleaning previous processes...")
        time.sleep(1)
    except Exception as e:
        print(f"⚠️  Error cleaning processes: {e}")


def generate_plots():
    """Generate all individual monitoring plots by category"""
    print("🎨 Generating individual plots by category...")
    
    script_dir = Path(__file__).parent
    
    # Category-based plot scripts (A-H) - Only use these to avoid duplicates
    category_scripts = [
        # Category A: Fluid & Rock Properties
        "plot_category_a_fluid_rock_individual.py",
        
        # Category B: Initial Conditions  
        "plot_category_b_initial_conditions.py",
        
        # Category C: Geometry & Configuration
        "plot_category_c_geometry_individual.py",
        
        # Category D: Operations & Scheduling
        "plot_category_d_operations_individual.py",
        
        # Category E: Global Evolution
        "plot_category_e_global_evolution.py",
        
        # Category G: Spatial Maps with Well Locations & Animations
        "plot_category_g_maps_animated.py",
        
        # Category H: Multiphysics Analysis
        "plot_category_h_multiphysics.py"
    ]
    
    all_scripts = category_scripts
    
    for script in all_scripts:
        script_path = script_dir / "plot_scripts" / script
        if script_path.exists():
            print(f"  📊 Executing {script}...")
            try:
                result = subprocess.run([sys.executable, str(script_path)],
                                        capture_output=True, text=True)
                if result.returncode == 0:
                    print(f"  ✅ {script} completed")
                else:
                    print(f"  ❌ Error in {script}: {result.stderr}")
            except Exception as e:
                print(f"  ❌ Error executing {script}: {e}")
        else:
            print(f"  ⚠️  Script not found: {script_path}")


def launch_dashboard():
    """Launch Streamlit dashboard in background"""
    script_dir = Path(__file__).parent
    app_path = script_dir / "streamlit" / "app.py"
    
    if not app_path.exists():
        print(f"❌ App not found: {app_path}")
        return
    
    print("\n🚀 Starting dashboard...")
    print("=" * 60)
    print("🌐 MRST MONITORING DASHBOARD")
    print("=" * 60)
    print("📋 Individual plots generated: ✅ COMPLETED")
    print("🎯 Categories A-H organized by scientific questions")
    print("🗺️  Spatial maps include well locations")
    print("🎬 Animated GIFs for time-dependent maps")
    print("🚀 Starting Streamlit in background...")
    
    try:
        # Launch Streamlit in background
        process = subprocess.Popen([
            "streamlit", "run", str(app_path),
            "--server.port", "8502",
            "--server.address", "0.0.0.0",
            "--browser.gatherUsageStats", "false"
        ], stdout=subprocess.PIPE, stderr=subprocess.PIPE)
        
        # Wait a moment for Streamlit to start
        time.sleep(3)
        
        # Check if process is still running
        if process.poll() is None:
            print("✅ Streamlit started successfully!")
            print("")
            print("🎉" * 20)
            print("✅ DASHBOARD READY!")
            print("🎉" * 20)
            print("")
            print("🔗 COPY one of these URLs and paste in your browser:")
            print("   👉 http://localhost:8502")
            print("   👉 http://127.0.0.1:8502")
            print("   👉 http://0.0.0.0:8502")
            print("")
            print("📊 DASHBOARD FEATURES:")
            print("   • Individual plots (no subplots)")
            print("   • 8 scientific categories (A-H)")
            print("   • Well locations on all spatial maps")
            print("   • Animated GIFs for time evolution")
            print("   • Each plot answers specific questions")
            print("")
            print("⚠️  IMPORTANT:")
            print("   - Server is running in background")
            print("   - If one URL doesn't work, try the others")
            print("   - To stop the server, run:")
            print("     pkill -f streamlit")
            print("=" * 60)
            
            # Try to open browser automatically
            try:
                webbrowser.open("http://localhost:8502")
                print("🌐 Trying to open browser automatically...")
            except Exception:
                print("⚠️  Could not open browser automatically")
                print("   Please copy the URL manually")
                
        else:
            print("❌ Error: Streamlit could not start")
            print("💡 Try running manually:")
            print(f"   streamlit run {app_path}")
            
    except Exception as e:
        print(f"\n❌ Error: {e}")
        print("💡 Verify that Streamlit is installed:")
        print("   pip install streamlit")


def main():
    print("🛢️  MRST MONITORING SYSTEM - INDIVIDUAL PLOTS")
    print("=" * 50)
    print("🎯 Generating plots organized by categories A-H")
    print("📊 Each plot addresses specific scientific questions")
    print("🗺️  All spatial maps show well locations")
    print("🎬 Time-dependent maps available as animated GIFs")
    print("=" * 50)
    
    # Step 1: Clean up any existing processes
    kill_existing_streamlit()
    
    # Step 2: Generate individual plots by category
    generate_plots()
    
    # Step 3: Launch dashboard
    launch_dashboard()
    
    print("\n🏁 Process completed!")
    print("💡 Dashboard is running in background")
    print("📈 Navigate between categories A-H using sidebar")


if __name__ == "__main__":
    main() 