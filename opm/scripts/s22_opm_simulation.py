#!/usr/bin/env python3
"""
s22_opm_simulation.py
Run OPM Flow simulation using exported MRST data

DESCRIPTION:
    Executes OPM Flow simulator with the data exported from MRST workflow
    Handles containerized OPM execution and result processing
    
INPUTS:
    - OPM input files from s21_export_to_opm.m
    - OPM container configuration
    
OUTPUTS:
    - OPM simulation results (PRT, RSM, UNRST files)
    - Simulation logs and diagnostics
    - Results summary for import back to MRST
    
WORKFLOW INTEGRATION:
    s21 (export) → s22 (OPM simulation) → s23 (import results)
"""

import os
import sys
import subprocess
import logging
import time
import shutil
from pathlib import Path
from datetime import datetime
import json

class OPMSimulator:
    """
    OPM Flow simulation orchestrator
    """
    
    def __init__(self):
        """Initialize OPM simulator configuration"""
        self.setup_logging()
        self.config = self.load_configuration()
        # Adapt for new OPM folder structure
        self.opm_base_dir = self.get_opm_base_dir()
        self.opm_input_dir = os.path.join(self.opm_base_dir, 'resinsight_data')
        self.opm_results_dir = '/workspace/mrst_simulation_scripts/data/opm'
        
        # Ensure directories exist
        os.makedirs(self.opm_results_dir, exist_ok=True)
        
        self.logger.info("OPM Simulator initialized")
        self.logger.info(f"Input directory: {self.opm_input_dir}")
        self.logger.info(f"Results directory: {self.opm_results_dir}")
        
    def setup_logging(self):
        """Configure logging system"""
        log_format = '%(asctime)s - %(name)s - %(levelname)s - %(message)s'
        logging.basicConfig(
            level=logging.INFO,
            format=log_format,
            handlers=[
                logging.StreamHandler(),
                logging.FileHandler('s22_opm_simulation.log')
            ]
        )
        self.logger = logging.getLogger('OPMSimulator')
        
    def load_configuration(self):
        """Load OPM simulation configuration"""
        config = {
            'opm_container': 'opm/flow:latest',  # Default container
            'docker_image': 'omp',  # Your custom container name
            'simulation_timeout': 3600,  # 1 hour timeout
            'parallel_threads': 4,
            'memory_limit': '8g',
            'data_file': 'EAGLE_WEST.DATA'
        }
        
        # Try to load from config file if available  
        config_file = os.path.join('/workspace/opm', 'config', 'opm_config.json')
        if os.path.exists(config_file):
            with open(config_file, 'r') as f:
                user_config = json.load(f)
                config.update(user_config)
                
        return config
        
    def get_opm_base_dir(self):
        """Get OPM base directory path"""
        # Look for OPM directory structure
        possible_paths = [
            '/workspace/opm',
            '../opm',
            'opm',
            os.path.join(os.getcwd(), 'opm')
        ]
        
        for path in possible_paths:
            if os.path.exists(path):
                return os.path.abspath(path)
                
        # Create OPM directory if none found
        opm_path = '/workspace/opm'
        os.makedirs(opm_path, exist_ok=True)
        return opm_path
        
    def validate_input_files(self):
        """Validate that required OPM input files exist"""
        self.logger.info("Validating OPM input files...")
        
        if not os.path.exists(self.opm_input_dir):
            raise FileNotFoundError(f"OPM input directory not found: {self.opm_input_dir}")
            
        required_files = [
            'EAGLE_WEST.DATA',
            'GRID.inc',
            'PROPS.inc',
            'PVT.inc',
            'WELLS.inc',
            'SCHEDULE.inc',
            'SOLUTION.inc'
        ]
        
        missing_files = []
        for file_name in required_files:
            file_path = os.path.join(self.opm_input_dir, file_name)
            if not os.path.exists(file_path):
                missing_files.append(file_name)
            else:
                file_size = os.path.getsize(file_path)
                self.logger.info(f"  ✓ {file_name} ({file_size} bytes)")
                
        if missing_files:
            raise FileNotFoundError(f"Missing required files: {missing_files}")
            
        self.logger.info("All required input files validated successfully")
        
    def check_opm_availability(self):
        """Check if OPM Flow is available (Docker or native)"""
        self.logger.info("Checking OPM Flow availability...")
        
        # First try Docker
        try:
            result = subprocess.run(['docker', 'version'], 
                                  capture_output=True, text=True, timeout=10)
            if result.returncode == 0:
                self.logger.info("Docker is available")
                
                # Check if OPM image exists
                result = subprocess.run(['docker', 'images', self.config['docker_image']], 
                                      capture_output=True, text=True, timeout=10)
                if self.config['docker_image'] in result.stdout:
                    self.execution_mode = 'docker'
                    self.logger.info(f"OPM Docker image found: {self.config['docker_image']}")
                    return True
                else:
                    self.logger.warning(f"Custom OPM image {self.config['docker_image']} not found")
                    
                    # Try default OPM image
                    result = subprocess.run(['docker', 'pull', self.config['omp_container']], 
                                          capture_output=True, text=True, timeout=300)
                    if result.returncode == 0:
                        self.execution_mode = 'docker'
                        self.config['docker_image'] = self.config['omp_container']
                        self.logger.info(f"Using default OPM container: {self.config['omp_container']}")
                        return True
                        
        except (subprocess.TimeoutExpired, FileNotFoundError):
            self.logger.warning("Docker not available or timeout")
            
        # Try native flow installation
        try:
            result = subprocess.run(['flow', '--version'], 
                                  capture_output=True, text=True, timeout=10)
            if result.returncode == 0:
                self.execution_mode = 'native'
                self.logger.info("Native OPM Flow installation found")
                return True
        except (subprocess.TimeoutExpired, FileNotFoundError):
            self.logger.warning("Native OPM Flow not found")
            
        raise RuntimeError("No OPM Flow installation found (Docker or native)")
        
    def run_simulation_docker(self):
        """Run OPM simulation using Docker"""
        self.logger.info("Starting OPM simulation with Docker...")
        
        # Prepare Docker command
        docker_cmd = [
            'docker', 'run', '--rm',
            '-v', f"{self.opm_input_dir}:/input:ro",
            '-v', f"{self.opm_results_dir}:/output",
            '-w', '/output',
            '--memory', self.config['memory_limit'],
            self.config['docker_image'],
            'flow',
            f"/input/{self.config['data_file']}",
            f"--output-dir=/output",
            f"--threads={self.config['parallel_threads']}",
            '--linear-solver=cprw',
            '--enable-opm-rst-file=true'
        ]
        
        self.logger.info(f"Docker command: {' '.join(docker_cmd)}")
        
        # Run simulation
        start_time = time.time()
        try:
            with open(os.path.join(self.opm_results_dir, 'opm_stdout.log'), 'w') as stdout_log, \
                 open(os.path.join(self.opm_results_dir, 'opm_stderr.log'), 'w') as stderr_log:
                
                process = subprocess.Popen(
                    docker_cmd,
                    stdout=stdout_log,
                    stderr=stderr_log,
                    text=True,
                    bufsize=1,
                    universal_newlines=True
                )
                
                # Monitor process with timeout
                try:
                    return_code = process.wait(timeout=self.config['simulation_timeout'])
                    
                except subprocess.TimeoutExpired:
                    self.logger.error("Simulation timed out")
                    process.kill()
                    process.wait()
                    raise RuntimeError("Simulation exceeded timeout limit")
                    
        except Exception as e:
            self.logger.error(f"Docker simulation failed: {e}")
            raise
            
        end_time = time.time()
        simulation_time = end_time - start_time
        
        if return_code == 0:
            self.logger.info(f"Simulation completed successfully in {simulation_time:.1f} seconds")
            return True
        else:
            self.logger.error(f"Simulation failed with return code: {return_code}")
            self.log_simulation_errors()
            return False
            
    def run_simulation_native(self):
        """Run OPM simulation using native installation"""
        self.logger.info("Starting OPM simulation with native installation...")
        
        # Change to results directory
        original_dir = os.getcwd()
        os.chdir(self.opm_results_dir)
        
        try:
            # Prepare command
            flow_cmd = [
                'flow',
                os.path.join(self.opm_input_dir, self.config['data_file']),
                f"--threads={self.config['parallel_threads']}",
                '--linear-solver=cprw',
                '--enable-opm-rst-file=true'
            ]
            
            self.logger.info(f"Flow command: {' '.join(flow_cmd)}")
            
            # Run simulation
            start_time = time.time()
            
            with open('opm_stdout.log', 'w') as stdout_log, \
                 open('opm_stderr.log', 'w') as stderr_log:
                
                process = subprocess.Popen(
                    flow_cmd,
                    stdout=stdout_log,
                    stderr=stderr_log,
                    text=True
                )
                
                try:
                    return_code = process.wait(timeout=self.config['simulation_timeout'])
                except subprocess.TimeoutExpired:
                    self.logger.error("Simulation timed out")
                    process.kill()
                    process.wait()
                    raise RuntimeError("Simulation exceeded timeout limit")
                    
            end_time = time.time()
            simulation_time = end_time - start_time
            
            if return_code == 0:
                self.logger.info(f"Simulation completed successfully in {simulation_time:.1f} seconds")
                return True
            else:
                self.logger.error(f"Simulation failed with return code: {return_code}")
                self.log_simulation_errors()
                return False
                
        finally:
            os.chdir(original_dir)
            
    def log_simulation_errors(self):
        """Log simulation errors for debugging"""
        try:
            stderr_log = os.path.join(self.opm_results_dir, 'opm_stderr.log')
            if os.path.exists(stderr_log):
                with open(stderr_log, 'r') as f:
                    error_content = f.read()
                    if error_content.strip():
                        self.logger.error("Simulation errors:")
                        self.logger.error(error_content[-2000:])  # Last 2000 chars
        except Exception as e:
            self.logger.warning(f"Could not read error log: {e}")
            
    def validate_results(self):
        """Validate that simulation produced expected output files"""
        self.logger.info("Validating simulation results...")
        
        expected_files = [
            'EAGLE_WEST.PRT',  # Print file
            'EAGLE_WEST.RSM',  # Restart summary
            'EAGLE_WEST.UNRST'  # Unified restart
        ]
        
        found_files = []
        missing_files = []
        
        for file_name in expected_files:
            file_path = os.path.join(self.opm_results_dir, file_name)
            if os.path.exists(file_path):
                file_size = os.path.getsize(file_path)
                found_files.append(file_name)
                self.logger.info(f"  ✓ {file_name} ({file_size} bytes)")
            else:
                missing_files.append(file_name)
                
        if missing_files:
            self.logger.warning(f"Some expected files missing: {missing_files}")
            
        # Check for any .RSM file (summary file)
        rsm_files = list(Path(self.opm_results_dir).glob("*.RSM"))
        if rsm_files:
            self.logger.info(f"Found summary files: {[f.name for f in rsm_files]}")
            
        return len(found_files) > 0
        
    def create_results_summary(self):
        """Create summary of simulation results"""
        self.logger.info("Creating results summary...")
        
        summary = {
            'simulation_date': datetime.now().isoformat(),
            'simulation_mode': self.execution_mode,
            'data_file': self.config['data_file'],
            'input_directory': self.opm_input_dir,
            'results_directory': self.opm_results_dir,
            'files_created': [],
            'file_sizes': {}
        }
        
        # List all files in results directory
        for file_path in Path(self.opm_results_dir).iterdir():
            if file_path.is_file():
                file_name = file_path.name
                file_size = file_path.stat().st_size
                summary['files_created'].append(file_name)
                summary['file_sizes'][file_name] = file_size
                
        # Write summary file
        summary_file = os.path.join(self.opm_results_dir, 'simulation_summary.json')
        with open(summary_file, 'w') as f:
            json.dump(summary, f, indent=2)
            
        # Write human-readable summary
        readable_summary = os.path.join(self.opm_results_dir, 'SIMULATION_SUMMARY.txt')
        with open(readable_summary, 'w') as f:
            f.write("OPM FLOW SIMULATION SUMMARY\n")
            f.write("===========================\n\n")
            f.write(f"Simulation Date: {summary['simulation_date']}\n")
            f.write(f"Execution Mode: {summary['simulation_mode']}\n")
            f.write(f"Data File: {summary['data_file']}\n")
            f.write(f"Results Directory: {summary['results_directory']}\n\n")
            f.write("FILES CREATED:\n")
            for file_name in sorted(summary['files_created']):
                size = summary['file_sizes'][file_name]
                f.write(f"- {file_name} ({size:,} bytes)\n")
            f.write("\nNEXT STEPS:\n")
            f.write("1. Review simulation logs (opm_stdout.log, opm_stderr.log)\n")
            f.write("2. Run s23_import_omp_results.m to import results back to MRST\n")
            f.write("3. Continue with s24-s25 for post-processing analytics\n")
            
        self.logger.info(f"Results summary created: {readable_summary}")
        
    def run_simulation(self):
        """Main simulation execution function"""
        try:
            self.logger.info("=== S22: OPM SIMULATION EXECUTION ===")
            
            # Validate inputs
            self.validate_input_files()
            
            # Check OPM availability
            self.check_opm_availability()
            
            # Run simulation based on available execution mode
            if self.execution_mode == 'docker':
                success = self.run_simulation_docker()
            else:
                success = self.run_simulation_native()
                
            if not success:
                raise RuntimeError("Simulation execution failed")
                
            # Validate results
            if not self.validate_results():
                self.logger.warning("Some expected result files missing, but simulation may have succeeded")
                
            # Create summary
            self.create_results_summary()
            
            self.logger.info("=== OPM SIMULATION COMPLETED SUCCESSFULLY ===")
            self.logger.info(f"Results available in: {self.opm_results_dir}")
            self.logger.info("Ready for s23_import_omp_results.m")
            
            return True
            
        except Exception as e:
            self.logger.error(f"Simulation failed: {e}")
            self.logger.error("Check logs for detailed error information")
            return False

def main():
    """Main entry point"""
    print("OPM Flow Simulation Runner")
    print("==========================")
    
    try:
        simulator = OPMSimulator()
        success = simulator.run_simulation()
        
        if success:
            print("\n✓ Simulation completed successfully!")
            print(f"Results directory: {simulator.opm_results_dir}")
            print("Next: Run s23_import_omp_results.m to import results")
            return 0
        else:
            print("\n✗ Simulation failed!")
            print("Check logs for error details")
            return 1
            
    except Exception as e:
        print(f"\n✗ Critical error: {e}")
        return 1

if __name__ == "__main__":
    sys.exit(main())
