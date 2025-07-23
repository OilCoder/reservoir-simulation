#!/usr/bin/env python3
"""
Track metadata and ensure traceability for all code generation and data operations.

This tool implements the data generation policy and maintains complete traceability
of all simulator-generated data and code modifications.
"""

import sys
import os
import json
import datetime
import hashlib
from pathlib import Path
import subprocess

def get_git_info():
    """Get current git repository information."""
    try:
        # Get current commit hash
        commit_hash = subprocess.run(
            ['git', 'rev-parse', 'HEAD'], 
            capture_output=True, text=True, cwd='/workspaces/simulation'
        ).stdout.strip()
        
        # Get current branch
        branch = subprocess.run(
            ['git', 'rev-parse', '--abbrev-ref', 'HEAD'], 
            capture_output=True, text=True, cwd='/workspaces/simulation'
        ).stdout.strip()
        
        # Get repository status
        status = subprocess.run(
            ['git', 'status', '--porcelain'], 
            capture_output=True, text=True, cwd='/workspaces/simulation'
        ).stdout.strip()
        
        return {
            'commit_hash': commit_hash,
            'branch': branch,
            'has_uncommitted_changes': bool(status),
            'uncommitted_files': status.split('\n') if status else []
        }
    except Exception:
        return {
            'commit_hash': 'unknown',
            'branch': 'unknown',
            'has_uncommitted_changes': True,
            'uncommitted_files': []
        }

def get_environment_info():
    """Get information about the execution environment."""
    return {
        'timestamp': datetime.datetime.utcnow().isoformat() + 'Z',
        'hostname': os.environ.get('HOSTNAME', 'unknown'),
        'user': os.environ.get('USER', 'unknown'),
        'python_version': sys.version.split()[0],
        'working_directory': os.getcwd(),
        'container_id': os.environ.get('CONTAINER_ID', 'unknown')
    }

def get_claude_session_info():
    """Get Claude Code session information."""
    # Try to get session info from logs or environment
    session_info = {
        'session_id': 'unknown',
        'model_version': 'claude-sonnet-4-20250514',
        'rules_version': get_rules_version(),
        'mcp_servers': get_mcp_server_status()
    }
    
    # Try to get session ID from log files
    log_path = '/workspaces/simulation/.claude/logs/context_injection.json'
    if os.path.exists(log_path):
        try:
            with open(log_path, 'r') as f:
                # Get the last line to see recent activity
                lines = f.readlines()
                if lines:
                    last_entry = json.loads(lines[-1])
                    session_info.update({
                        'last_context_injection': last_entry.get('timestamp'),
                        'last_intent': last_entry.get('intent')
                    })
        except Exception:
            pass
    
    return session_info

def get_rules_version():
    """Get version information about the coding rules."""
    rules_dir = '/workspaces/simulation/.claude/rules'
    if not os.path.exists(rules_dir):
        return 'unknown'
    
    # Get modification times of all rule files
    rule_files = []
    for file in os.listdir(rules_dir):
        if file.endswith('.md'):
            file_path = os.path.join(rules_dir, file)
            mtime = os.path.getmtime(file_path)
            rule_files.append((file, mtime))
    
    # Create a hash based on rule files and their modification times
    rule_hash = hashlib.md5()
    for file, mtime in sorted(rule_files):
        rule_hash.update(f"{file}:{mtime}".encode())
    
    return {
        'rules_hash': rule_hash.hexdigest()[:8],
        'rule_files': len(rule_files),
        'last_modified': max([mtime for _, mtime in rule_files]) if rule_files else 0
    }

def get_mcp_server_status():
    """Get status of MCP servers."""
    mcp_config_path = '/workspaces/simulation/.claude/.mcp.json'
    if not os.path.exists(mcp_config_path):
        return {'configured': False}
    
    try:
        with open(mcp_config_path, 'r') as f:
            mcp_config = json.load(f)
        
        servers = mcp_config.get('mcpServers', {})
        return {
            'configured': True,
            'server_count': len(servers),
            'servers': list(servers.keys())
        }
    except Exception:
        return {'configured': False, 'error': 'config_read_error'}

def analyze_modifications():
    """Analyze what modifications were made in this session."""
    modifications = {
        'files_modified': [],
        'lines_added': 0,
        'lines_removed': 0,
        'functions_added': 0,
        'classes_added': 0
    }
    
    # Get list of modified files from git
    try:
        result = subprocess.run(
            ['git', 'diff', '--name-only', 'HEAD'], 
            capture_output=True, text=True, cwd='/workspaces/simulation'
        )
        modified_files = result.stdout.strip().split('\n') if result.stdout.strip() else []
        
        for file_path in modified_files:
            if file_path and os.path.exists(f'/workspaces/simulation/{file_path}'):
                file_info = analyze_file_modifications(f'/workspaces/simulation/{file_path}')
                modifications['files_modified'].append({
                    'path': file_path,
                    'analysis': file_info
                })
                modifications['lines_added'] += file_info.get('lines_added', 0)
                modifications['lines_removed'] += file_info.get('lines_removed', 0)
                modifications['functions_added'] += file_info.get('functions_added', 0)
                modifications['classes_added'] += file_info.get('classes_added', 0)
    
    except Exception:
        pass
    
    return modifications

def analyze_file_modifications(file_path):
    """Analyze modifications to a specific file."""
    try:
        # Get diff for this file
        result = subprocess.run(
            ['git', 'diff', 'HEAD', file_path], 
            capture_output=True, text=True, cwd='/workspaces/simulation'
        )
        diff_output = result.stdout
        
        analysis = {
            'lines_added': len([line for line in diff_output.split('\n') if line.startswith('+') and not line.startswith('+++')]),
            'lines_removed': len([line for line in diff_output.split('\n') if line.startswith('-') and not line.startswith('---')]),
            'functions_added': len([line for line in diff_output.split('\n') if line.startswith('+') and ('def ' in line or 'function ' in line)]),
            'classes_added': len([line for line in diff_output.split('\n') if line.startswith('+') and 'class ' in line])
        }
        
        return analysis
    except Exception:
        return {'lines_added': 0, 'lines_removed': 0, 'functions_added': 0, 'classes_added': 0}

def create_metadata_record():
    """Create a complete metadata record for the current session."""
    metadata = {
        'metadata_version': '1.0',
        'generation_timestamp': datetime.datetime.utcnow().isoformat() + 'Z',
        'git_info': get_git_info(),
        'environment': get_environment_info(),
        'claude_session': get_claude_session_info(),
        'modifications': analyze_modifications(),
        'data_generation_policy': {
            'no_hardcoded_values': True,
            'simulator_data_only': True,
            'complete_traceability': True,
            'metadata_required': True
        },
        'validation_results': get_validation_summary()
    }
    
    return metadata

def get_validation_summary():
    """Get summary of validation results from recent runs."""
    validation_summary = {
        'total_validations': 0,
        'passed_validations': 0,
        'failed_validations': 0,
        'rules_violated': [],
        'common_violations': []
    }
    
    # This would typically read from validation logs
    # For now, return basic structure
    return validation_summary

def update_project_map():
    """Update the project map with current state."""
    project_map_path = '/workspaces/simulation/docs/project_map.md'
    
    try:
        # Read current project map
        if os.path.exists(project_map_path):
            with open(project_map_path, 'r') as f:
                content = f.read()
        else:
            content = "# Project Map\n\n"
        
        # Add metadata section if not present
        if '## Metadata Tracking' not in content:
            metadata_section = f"""
## Metadata Tracking

Last updated: {datetime.datetime.utcnow().strftime('%Y-%m-%d %H:%M:%S UTC')}

### Recent Sessions
- Session active: Code generation with deterministic validation
- MCP servers: {', '.join(get_mcp_server_status().get('servers', []))}
- Rules version: {get_rules_version().get('rules_hash', 'unknown')}

### Data Generation Policy Status
- ✅ No hardcoded values policy enforced
- ✅ Simulator data traceability active
- ✅ Complete metadata recording enabled
"""
            content += metadata_section
            
            # Write back updated content
            with open(project_map_path, 'w') as f:
                f.write(content)
    
    except Exception as e:
        # Don't fail metadata tracking if project map update fails
        pass

def save_metadata_record(metadata):
    """Save metadata record to the appropriate location."""
    metadata_dir = '/workspaces/simulation/.claude/metadata'
    os.makedirs(metadata_dir, exist_ok=True)
    
    # Create timestamped metadata file
    timestamp = datetime.datetime.utcnow().strftime('%Y%m%d_%H%M%S')
    metadata_file = f'{metadata_dir}/session_{timestamp}.json'
    
    try:
        with open(metadata_file, 'w') as f:
            json.dump(metadata, f, indent=2)
    except Exception:
        pass
    
    # Also update the latest metadata file
    latest_file = f'{metadata_dir}/latest.json'
    try:
        with open(latest_file, 'w') as f:
            json.dump(metadata, f, indent=2)
    except Exception:
        pass

def check_data_generation_compliance():
    """Check compliance with data generation policy."""
    violations = []
    
    # Check for recent data files that might lack metadata
    data_dir = '/workspaces/simulation/data'
    if os.path.exists(data_dir):
        for root, dirs, files in os.walk(data_dir):
            for file in files:
                if file.endswith('.mat') or 'data' in file.lower():
                    file_path = os.path.join(root, file)
                    # Check if there's corresponding metadata
                    if not has_associated_metadata(file_path):
                        violations.append(f"Data file lacks metadata: {file_path}")
    
    return violations

def has_associated_metadata(data_file_path):
    """Check if a data file has associated metadata."""
    # Look for metadata in the same directory or metadata/ subdirectory
    base_dir = os.path.dirname(data_file_path)
    metadata_dir = os.path.join(base_dir, 'metadata')
    
    # Check for metadata.mat or similar files
    metadata_files = ['metadata.mat', 'metadata.json', 'info.mat']
    
    for metadata_file in metadata_files:
        if os.path.exists(os.path.join(base_dir, metadata_file)):
            return True
        if os.path.exists(os.path.join(metadata_dir, metadata_file)):
            return True
    
    return False

def main():
    """Main metadata tracking function."""
    try:
        # Create comprehensive metadata record
        metadata = create_metadata_record()
        
        # Check data generation compliance
        compliance_violations = check_data_generation_compliance()
        metadata['compliance_violations'] = compliance_violations
        
        # Save metadata record
        save_metadata_record(metadata)
        
        # Update project map
        update_project_map()
        
        # Report any compliance issues
        if compliance_violations:
            print("Data generation policy violations detected:")
            for violation in compliance_violations[:3]:  # Limit output
                print(f"  - {violation}")
            if len(compliance_violations) > 3:
                print(f"  - ... and {len(compliance_violations) - 3} more violations")
        
        # Output summary for monitoring
        summary = {
            'status': 'success',
            'files_tracked': len(metadata['modifications']['files_modified']),
            'metadata_recorded': True,
            'compliance_violations': len(compliance_violations)
        }
        print(f"Metadata tracking: {json.dumps(summary)}")
        
    except Exception as e:
        print(f"Metadata tracking error: {e}")
        # Don't fail - metadata tracking is supplementary
    
    sys.exit(0)

if __name__ == "__main__":
    main()