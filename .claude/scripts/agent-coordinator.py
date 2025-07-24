#!/usr/bin/env python3
"""
Agent Coordination System for Parallel Claude Code Execution

This script manages coordination, state sharing, and conflict resolution
between multiple Claude Code agents working in parallel.
"""

import json
import os
import time
import threading
import logging
from datetime import datetime, timedelta
from pathlib import Path
from typing import Dict, List, Optional, Any
from dataclasses import dataclass, asdict
from enum import Enum

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler('.claude/logs/coordinator.log'),
        logging.StreamHandler()
    ]
)

logger = logging.getLogger('AgentCoordinator')


class AgentStatus(Enum):
    """Agent status enumeration."""
    IDLE = "idle"
    WORKING = "working"
    BLOCKED = "blocked"
    COMPLETED = "completed"
    FAILED = "failed"


@dataclass
class AgentInfo:
    """Information about a single agent."""
    agent_id: str
    agent_type: str
    status: AgentStatus
    current_task: Optional[str]
    worktree_path: Optional[str]
    start_time: datetime
    last_heartbeat: datetime
    progress: float  # 0.0 to 1.0
    metadata: Dict[str, Any]


@dataclass
class ResourceLock:
    """Resource locking information."""
    resource_path: str
    locked_by: str
    lock_time: datetime
    lock_type: str  # 'read' or 'write'


class AgentCoordinator:
    """Central coordinator for managing parallel Claude Code agents."""
    
    def __init__(self, workspace_path: str = "/workspace"):
        self.workspace_path = Path(workspace_path)
        self.state_file = self.workspace_path / ".claude" / "agent-state.json"
        self.lock_file = self.workspace_path / ".claude" / "coordinator.lock"
        self.agents: Dict[str, AgentInfo] = {}
        self.resource_locks: Dict[str, ResourceLock] = {}
        self.coordination_log: List[Dict[str, Any]] = []
        
        # Ensure directories exist
        os.makedirs(self.state_file.parent, exist_ok=True)
        os.makedirs(self.workspace_path / ".claude" / "logs", exist_ok=True)
        
        # Load existing state if available
        self._load_state()
        
        # Start background maintenance thread
        self.maintenance_thread = threading.Thread(target=self._maintenance_loop, daemon=True)
        self.maintenance_thread.start()
    
    def register_agent(self, agent_id: str, agent_type: str, worktree_path: Optional[str] = None) -> bool:
        """Register a new agent with the coordinator."""
        try:
            with self._acquire_lock():
                if agent_id in self.agents:
                    logger.warning(f"Agent {agent_id} already registered")
                    return False
                
                agent_info = AgentInfo(
                    agent_id=agent_id,
                    agent_type=agent_type,
                    status=AgentStatus.IDLE,
                    current_task=None,
                    worktree_path=worktree_path,
                    start_time=datetime.now(),
                    last_heartbeat=datetime.now(),
                    progress=0.0,
                    metadata={}
                )
                
                self.agents[agent_id] = agent_info
                self._save_state()
                
                logger.info(f"Registered agent: {agent_id} ({agent_type})")
                self._log_event("agent_registered", {
                    "agent_id": agent_id,
                    "agent_type": agent_type,
                    "worktree_path": worktree_path
                })
                
                return True
                
        except Exception as e:
            logger.error(f"Failed to register agent {agent_id}: {e}")
            return False
    
    def update_agent_status(self, agent_id: str, status: AgentStatus, 
                          current_task: Optional[str] = None, 
                          progress: Optional[float] = None,
                          metadata: Optional[Dict[str, Any]] = None) -> bool:
        """Update agent status and progress."""
        try:
            with self._acquire_lock():
                if agent_id not in self.agents:
                    logger.error(f"Agent {agent_id} not registered")
                    return False
                
                agent = self.agents[agent_id]
                agent.status = status
                agent.last_heartbeat = datetime.now()
                
                if current_task is not None:
                    agent.current_task = current_task
                
                if progress is not None:
                    agent.progress = max(0.0, min(1.0, progress))
                
                if metadata is not None:
                    agent.metadata.update(metadata)
                
                self._save_state()
                
                logger.debug(f"Updated agent {agent_id}: {status.value}, progress: {agent.progress:.1%}")
                
                return True
                
        except Exception as e:
            logger.error(f"Failed to update agent {agent_id}: {e}")
            return False
    
    def request_resource_lock(self, agent_id: str, resource_path: str, lock_type: str = "write") -> bool:
        """Request a lock on a resource (file/directory)."""
        try:
            with self._acquire_lock():
                if agent_id not in self.agents:
                    logger.error(f"Agent {agent_id} not registered")
                    return False
                
                # Check if resource is already locked
                if resource_path in self.resource_locks:
                    existing_lock = self.resource_locks[resource_path]
                    
                    # Allow multiple read locks
                    if lock_type == "read" and existing_lock.lock_type == "read":
                        logger.info(f"Granted shared read lock on {resource_path} to {agent_id}")
                        return True
                    
                    logger.warning(f"Resource {resource_path} already locked by {existing_lock.locked_by}")
                    return False
                
                # Grant the lock
                lock = ResourceLock(
                    resource_path=resource_path,
                    locked_by=agent_id,
                    lock_time=datetime.now(),
                    lock_type=lock_type
                )
                
                self.resource_locks[resource_path] = lock
                self._save_state()
                
                logger.info(f"Granted {lock_type} lock on {resource_path} to {agent_id}")
                self._log_event("resource_locked", {
                    "agent_id": agent_id,
                    "resource_path": resource_path,
                    "lock_type": lock_type
                })
                
                return True
                
        except Exception as e:
            logger.error(f"Failed to grant lock to {agent_id}: {e}")
            return False
    
    def release_resource_lock(self, agent_id: str, resource_path: str) -> bool:
        """Release a resource lock."""
        try:
            with self._acquire_lock():
                if resource_path not in self.resource_locks:
                    logger.warning(f"No lock found for resource {resource_path}")
                    return False
                
                lock = self.resource_locks[resource_path]
                if lock.locked_by != agent_id:
                    logger.error(f"Agent {agent_id} cannot release lock owned by {lock.locked_by}")
                    return False
                
                del self.resource_locks[resource_path]
                self._save_state()
                
                logger.info(f"Released lock on {resource_path} by {agent_id}")
                self._log_event("resource_unlocked", {
                    "agent_id": agent_id,
                    "resource_path": resource_path
                })
                
                return True
                
        except Exception as e:
            logger.error(f"Failed to release lock by {agent_id}: {e}")
            return False
    
    def get_agent_status(self, agent_id: Optional[str] = None) -> Dict[str, Any]:
        """Get status of specific agent or all agents."""
        try:
            with self._acquire_lock():
                if agent_id:
                    if agent_id not in self.agents:
                        return {"error": f"Agent {agent_id} not found"}
                    return asdict(self.agents[agent_id])
                else:
                    return {
                        "agents": {aid: asdict(info) for aid, info in self.agents.items()},
                        "active_locks": {path: asdict(lock) for path, lock in self.resource_locks.items()},
                        "summary": self._get_summary()
                    }
        except Exception as e:
            logger.error(f"Failed to get agent status: {e}")
            return {"error": str(e)}
    
    def detect_conflicts(self) -> List[Dict[str, Any]]:
        """Detect potential conflicts between agents."""
        conflicts = []
        
        try:
            with self._acquire_lock():
                # Check for agents working on same files
                file_agents = {}
                for agent_id, agent in self.agents.items():
                    if agent.status == AgentStatus.WORKING and agent.worktree_path:
                        # Simple heuristic: check if worktrees might affect same files
                        base_files = self._get_modified_files(agent.worktree_path)
                        for file_path in base_files:
                            if file_path not in file_agents:
                                file_agents[file_path] = []
                            file_agents[file_path].append(agent_id)
                
                # Report conflicts
                for file_path, agents in file_agents.items():
                    if len(agents) > 1:
                        conflicts.append({
                            "type": "file_conflict",
                            "file_path": file_path,
                            "agents": agents,
                            "severity": "medium"
                        })
                
                # Check for stale locks
                now = datetime.now()
                for resource_path, lock in self.resource_locks.items():
                    if now - lock.lock_time > timedelta(hours=1):
                        conflicts.append({
                            "type": "stale_lock",
                            "resource_path": resource_path,
                            "locked_by": lock.locked_by,
                            "lock_age": str(now - lock.lock_time),
                            "severity": "high"
                        })
                
                # Check for unresponsive agents
                for agent_id, agent in self.agents.items():
                    if now - agent.last_heartbeat > timedelta(minutes=5):
                        conflicts.append({
                            "type": "unresponsive_agent",
                            "agent_id": agent_id,
                            "last_seen": str(now - agent.last_heartbeat),
                            "severity": "high"
                        })
                
        except Exception as e:
            logger.error(f"Failed to detect conflicts: {e}")
            conflicts.append({
                "type": "detection_error",
                "error": str(e),
                "severity": "high"
            })
        
        return conflicts
    
    def cleanup_agent(self, agent_id: str) -> bool:
        """Clean up agent and release all its resources."""
        try:
            with self._acquire_lock():
                if agent_id not in self.agents:
                    logger.warning(f"Agent {agent_id} not found for cleanup")
                    return False
                
                # Release all locks held by this agent
                locks_to_release = [
                    path for path, lock in self.resource_locks.items()
                    if lock.locked_by == agent_id
                ]
                
                for resource_path in locks_to_release:
                    del self.resource_locks[resource_path]
                    logger.info(f"Released lock on {resource_path} during cleanup")
                
                # Remove agent
                del self.agents[agent_id]
                self._save_state()
                
                logger.info(f"Cleaned up agent: {agent_id}")
                self._log_event("agent_cleanup", {
                    "agent_id": agent_id,
                    "locks_released": len(locks_to_release)
                })
                
                return True
                
        except Exception as e:
            logger.error(f"Failed to cleanup agent {agent_id}: {e}")
            return False
    
    def _acquire_lock(self):
        """Context manager for file-based locking."""
        return FileLock(self.lock_file)
    
    def _load_state(self):
        """Load coordinator state from file."""
        try:
            if self.state_file.exists():
                with open(self.state_file, 'r') as f:
                    data = json.load(f)
                
                # Reconstruct agents
                for agent_id, agent_data in data.get('agents', {}).items():
                    agent_data['start_time'] = datetime.fromisoformat(agent_data['start_time'])
                    agent_data['last_heartbeat'] = datetime.fromisoformat(agent_data['last_heartbeat'])
                    agent_data['status'] = AgentStatus(agent_data['status'])
                    self.agents[agent_id] = AgentInfo(**agent_data)
                
                # Reconstruct locks
                for resource_path, lock_data in data.get('resource_locks', {}).items():
                    lock_data['lock_time'] = datetime.fromisoformat(lock_data['lock_time'])
                    self.resource_locks[resource_path] = ResourceLock(**lock_data)
                
                logger.info(f"Loaded state: {len(self.agents)} agents, {len(self.resource_locks)} locks")
                
        except Exception as e:
            logger.warning(f"Failed to load state: {e}")
    
    def _save_state(self):
        """Save coordinator state to file."""
        try:
            data = {
                'agents': {},
                'resource_locks': {},
                'last_updated': datetime.now().isoformat()
            }
            
            # Serialize agents
            for agent_id, agent in self.agents.items():
                agent_dict = asdict(agent)
                agent_dict['start_time'] = agent.start_time.isoformat()
                agent_dict['last_heartbeat'] = agent.last_heartbeat.isoformat()
                agent_dict['status'] = agent.status.value
                data['agents'][agent_id] = agent_dict
            
            # Serialize locks
            for resource_path, lock in self.resource_locks.items():
                lock_dict = asdict(lock)
                lock_dict['lock_time'] = lock.lock_time.isoformat()
                data['resource_locks'][resource_path] = lock_dict
            
            with open(self.state_file, 'w') as f:
                json.dump(data, f, indent=2)
                
        except Exception as e:
            logger.error(f"Failed to save state: {e}")
    
    def _maintenance_loop(self):
        """Background maintenance tasks."""
        while True:
            try:
                time.sleep(30)  # Run every 30 seconds
                
                # Clean up stale agents and locks
                self._cleanup_stale_resources()
                
                # Detect and report conflicts
                conflicts = self.detect_conflicts()
                if conflicts:
                    logger.warning(f"Detected {len(conflicts)} conflicts")
                    for conflict in conflicts:
                        if conflict['severity'] == 'high':
                            logger.error(f"High severity conflict: {conflict}")
                
            except Exception as e:
                logger.error(f"Maintenance loop error: {e}")
    
    def _cleanup_stale_resources(self):
        """Clean up stale agents and locks."""
        try:
            with self._acquire_lock():
                now = datetime.now()
                stale_cutoff = timedelta(minutes=10)
                
                # Clean up stale agents
                stale_agents = [
                    agent_id for agent_id, agent in self.agents.items()
                    if now - agent.last_heartbeat > stale_cutoff
                ]
                
                for agent_id in stale_agents:
                    logger.warning(f"Cleaning up stale agent: {agent_id}")
                    self.cleanup_agent(agent_id)
                
        except Exception as e:
            logger.error(f"Failed to cleanup stale resources: {e}")
    
    def _get_summary(self) -> Dict[str, Any]:
        """Get summary statistics."""
        total_agents = len(self.agents)
        active_agents = sum(1 for a in self.agents.values() if a.status == AgentStatus.WORKING)
        total_locks = len(self.resource_locks)
        
        return {
            "total_agents": total_agents,
            "active_agents": active_agents,
            "idle_agents": total_agents - active_agents,
            "total_locks": total_locks,
            "uptime": str(datetime.now() - min(a.start_time for a in self.agents.values()) if self.agents else timedelta(0))
        }
    
    def _get_modified_files(self, worktree_path: str) -> List[str]:
        """Get list of modified files in a worktree."""
        # This is a simplified implementation
        # In practice, you'd use git commands to get the actual modified files
        try:
            import subprocess
            result = subprocess.run(
                ['git', 'diff', '--name-only', 'HEAD'],
                cwd=worktree_path,
                capture_output=True,
                text=True
            )
            return result.stdout.strip().split('\n') if result.stdout.strip() else []
        except:
            return []
    
    def _log_event(self, event_type: str, data: Dict[str, Any]):
        """Log coordination event."""
        event = {
            "timestamp": datetime.now().isoformat(),
            "event_type": event_type,
            "data": data
        }
        self.coordination_log.append(event)
        
        # Keep only last 1000 events
        if len(self.coordination_log) > 1000:
            self.coordination_log = self.coordination_log[-1000:]


class FileLock:
    """Simple file-based locking mechanism."""
    
    def __init__(self, lock_file: Path):
        self.lock_file = lock_file
        self.acquired = False
    
    def __enter__(self):
        timeout = 30  # 30 second timeout
        start_time = time.time()
        
        while time.time() - start_time < timeout:
            try:
                # Try to create lock file exclusively
                with open(self.lock_file, 'x') as f:
                    f.write(f"{os.getpid()}\n{datetime.now().isoformat()}")
                self.acquired = True
                return self
            except FileExistsError:
                time.sleep(0.1)
        
        raise TimeoutError(f"Could not acquire lock on {self.lock_file}")
    
    def __exit__(self, exc_type, exc_val, exc_tb):
        if self.acquired:
            try:
                self.lock_file.unlink()
            except FileNotFoundError:
                pass


# CLI interface
if __name__ == "__main__":
    import argparse
    
    parser = argparse.ArgumentParser(description="Agent Coordination System")
    parser.add_argument("command", choices=["status", "conflicts", "cleanup", "monitor"])
    parser.add_argument("--agent-id", help="Specific agent ID")
    parser.add_argument("--workspace", default="/workspace", help="Workspace path")
    
    args = parser.parse_args()
    
    coordinator = AgentCoordinator(args.workspace)
    
    if args.command == "status":
        status = coordinator.get_agent_status(args.agent_id)
        print(json.dumps(status, indent=2, default=str))
    
    elif args.command == "conflicts":
        conflicts = coordinator.detect_conflicts()
        print(f"Found {len(conflicts)} conflicts:")
        for conflict in conflicts:
            print(json.dumps(conflict, indent=2))
    
    elif args.command == "cleanup":
        if args.agent_id:
            success = coordinator.cleanup_agent(args.agent_id)
            print(f"Cleanup {'successful' if success else 'failed'}")
        else:
            print("Agent ID required for cleanup")
    
    elif args.command == "monitor":
        print("Monitoring agents (Ctrl+C to stop)...")
        try:
            while True:
                status = coordinator.get_agent_status()
                print(f"\r{datetime.now().strftime('%H:%M:%S')} - "
                      f"Active: {status['summary']['active_agents']}/{status['summary']['total_agents']}, "
                      f"Locks: {status['summary']['total_locks']}", end="", flush=True)
                time.sleep(5)
        except KeyboardInterrupt:
            print("\nMonitoring stopped.")