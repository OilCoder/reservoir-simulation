#!/usr/bin/env python3
"""Check MRST Dashboard Service Status"""

import os
import requests
from pathlib import Path

def check_dashboard_status():
    """Check if dashboard service is running."""
    pid_file = Path("logs/dashboard.pid")
    
    if not pid_file.exists():
        print("❌ Dashboard service not found (PID file missing)")
        return False
    
    try:
        with open(pid_file, 'r') as f:
            pid = int(f.read().strip())
        
        # Check if process exists
        try:
            os.kill(pid, 0)  # Check if process exists
            print(f"✅ Dashboard service running (PID: {pid})")
            
            # Check if web service responds
            try:
                response = requests.get("http://localhost:8501", timeout=5)
                print("🌐 Web interface accessible at: http://localhost:8501")
                return True
            except:
                print("⚠️ Process running but web interface not accessible")
                return False
                
        except ProcessLookupError:
            print("❌ Process not found (service stopped)")
            pid_file.unlink(missing_ok=True)
            return False
            
    except Exception as e:
        print(f"❌ Error checking status: {e}")
        return False

if __name__ == "__main__":
    check_dashboard_status()
