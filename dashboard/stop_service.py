#!/usr/bin/env python3
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
