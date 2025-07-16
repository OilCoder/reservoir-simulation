#!/bin/bash
# MRST Dashboard Startup Script

echo "🚀 Starting MRST Simulation Dashboard..."

# Change to dashboard directory
cd "$(dirname "$0")"

# Check if dummy data exists, create it if not
if [ ! -f "../data/initial/initial_conditions.mat" ]; then
    echo "📊 Creating dummy data for testing..."
    python create_dummy_data.py
fi

# Start Streamlit dashboard
echo "🌐 Starting Streamlit server..."
echo "📱 Access the dashboard at: http://localhost:8501"
echo "🔄 If plots don't appear, refresh the browser page"
echo "⏹️  Press Ctrl+C to stop the server"

# Run in foreground so user can see output and stop with Ctrl+C
streamlit run s99_run_dashboard.py --server.headless=false --server.port=8501 --server.address=0.0.0.0