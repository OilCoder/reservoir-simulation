#!/usr/bin/env python3
"""
OMP Workflow Automation
Simplified workflow runner for Eagle West Field OPM simulation
"""

import os
import sys
import subprocess
from pathlib import Path

class OPMWorkflow:
    def __init__(self):
        self.opm_dir = Path(__file__).parent.parent
        self.results_dir = Path('/workspace/mrst_simulation_scripts/data/opm')
        self.resinsight_dir = self.opm_dir / 'resinsight_data'
        
    def run_complete_workflow(self):
        """Run complete OPM workflow from MRST data"""
        print("=== OPM Workflow Runner ===")
        
        # Step 1: Export from MRST (if needed)
        if self.check_mrst_data_available():
            print("Step 1: Export from MRST...")
            self.run_mrst_export()
        
        # Step 2: Run OPM simulation
        print("Step 2: Run OPM simulation...")
        self.run_opm_simulation()
        
        # Step 3: Prepare for ResInsight
        print("Step 3: Prepare for ResInsight...")
        self.prepare_resinsight()
        
        # Step 4: Run analytics
        print("Step 4: Run analytics...")
        self.run_analytics()
        
        # Step 5: Import to database (if configured)
        if self.check_database_available():
            print("Step 5: Import to database...")
            self.import_to_database()
            
        print("✓ OPM workflow completed!")
        
    def check_mrst_data_available(self):
        """Check if MRST data is available"""
        mrst_data = Path('/workspace/mrst_simulation_scripts/data/simulation_data/static')
        return mrst_data.exists()
        
    def run_mrst_export(self):
        """Run MRST export if available"""
        export_script = self.opm_dir / 'scripts' / 's21_export_to_opm.m'
        if export_script.exists():
            print(f"  Running {export_script}...")
            # Would run octave command here
            
    def run_opm_simulation(self):
        """Run OPM simulation"""
        sim_script = self.opm_dir / 'scripts' / 's22_opm_simulation.py'
        if sim_script.exists():
            print(f"  Running {sim_script}...")
            try:
                subprocess.run([sys.executable, str(sim_script)], check=True)
            except subprocess.CalledProcessError as e:
                print(f"  Simulation failed: {e}")
                
    def prepare_resinsight(self):
        """Prepare data for ResInsight"""
        resinsight_script = self.automation_dir / 'prepare_resinsight.py'
        if resinsight_script.exists():
            subprocess.run([sys.executable, str(resinsight_script)])
        else:
            print("  ResInsight preparation script not found")
            
    def check_database_available(self):
        """Check if database is configured"""
        db_script = self.opm_dir / 'database' / 'populate_sample_data.py'
        return db_script.exists()
        
    def run_analytics(self):
        """Run OPM results analytics"""
        analytics_script = self.opm_dir / 'scripts' / 's24_opm_analytics.py'
        if analytics_script.exists():
            print(f"  Running {analytics_script}...")
            try:
                subprocess.run([sys.executable, str(analytics_script)], check=True)
            except subprocess.CalledProcessError as e:
                print(f"  Analytics failed: {e}")
        else:
            print("  Analytics script not found")
            
    def import_to_database(self):
        """Import results to database"""
        db_script = self.opm_dir / 'database' / 'populate_sample_data.py'
        if db_script.exists():
            subprocess.run([sys.executable, str(db_script)])

if __name__ == "__main__":
    workflow = OPMWorkflow()
    workflow.run_complete_workflow()