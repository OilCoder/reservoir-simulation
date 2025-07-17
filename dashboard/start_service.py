#!/usr/bin/env python3
"""
MRST Dashboard Background Service

Starts the dashboard as a background service that stays running.
"""

import subprocess
import sys
import time
import signal
import os
from pathlib import Path

def start_dashboard_service():
    """Start dashboard as background service."""
    print("🚀 Starting MRST Dashboard Service")
    print("🌐 Dashboard will be available at: http://localhost:8501")
    print("📝 Service will run in background")
    print("💡 Use 'python stop_service.py' to stop")
    print()
    
    # Create log directory
    log_dir = Path("logs")
    log_dir.mkdir(exist_ok=True)
    
    log_file = log_dir / "dashboard.log"
    pid_file = log_dir / "dashboard.pid"
    
    try:
        # Start streamlit in background
        process = subprocess.Popen([
            "streamlit", "run", "dashboard.py",
            "--server.port", "8501",
            "--server.address", "0.0.0.0",
            "--server.headless", "true",
            "--server.enableCORS", "false",
            "--server.enableXsrfProtection", "false",
            "--browser.gatherUsageStats", "false"
        ], 
        stdout=open(log_file, 'w'),
        stderr=subprocess.STDOUT,
        preexec_fn=os.setsid  # Create new session
        )
        
        # Save PID for stopping later
        with open(pid_file, 'w') as f:
            f.write(str(process.pid))
        
        print(f"✅ Dashboard service started!")
        print(f"📊 PID: {process.pid}")
        print(f"📝 Logs: {log_file}")
        print(f"🌐 URL: http://localhost:8501")
        print()
        print("📋 Service commands:")
        print("   python stop_service.py    # Stop service")
        print("   python status_service.py  # Check status")
        print(f"   tail -f {log_file}        # View logs")
        
        return True
        
    except Exception as e:
        print(f"❌ Error starting service: {e}")
        return False

def create_stop_script():
    """Create stop service script."""
    stop_script = '''#!/usr/bin/env python3
"""Stop MRST Dashboard Service"""

import os
import signal
from pathlib import Path

def stop_dashboard_service():
    """Stop the dashboard service."""
    pid_file = Path("logs/dashboard.pid")
    
    if not pid_file.exists():
        print("❌ No dashboard service found (PID file missing)")
        return False
    
    try:
        with open(pid_file, 'r') as f:
            pid = int(f.read().strip())
        
        # Kill the process group
        os.killpg(pid, signal.SIGTERM)
        
        # Remove PID file
        pid_file.unlink()
        
        print("✅ Dashboard service stopped")
        print(f"📊 Stopped PID: {pid}")
        return True
        
    except ProcessLookupError:
        print("⚠️ Process not found (already stopped?)")
        pid_file.unlink(missing_ok=True)
        return True
    except Exception as e:
        print(f"❌ Error stopping service: {e}")
        return False

if __name__ == "__main__":
    stop_dashboard_service()
'''
    
    with open("stop_service.py", 'w') as f:
        f.write(stop_script)
    
    os.chmod("stop_service.py", 0o755)

def create_status_script():
    """Create status check script."""
    status_script = '''#!/usr/bin/env python3
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
'''
    
    with open("status_service.py", 'w') as f:
        f.write(status_script)
    
    os.chmod("status_service.py", 0o755)

if __name__ == "__main__":
    # Create helper scripts
    create_stop_script()
    create_status_script()
    
    # Start the service
    start_dashboard_service()