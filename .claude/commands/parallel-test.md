---
allowed-tools: [Task, Bash, Write]
description: Run tests across multiple environments and configurations in parallel
---

# Parallel Testing Execution

Execute tests across multiple environments, configurations, and test types concurrently using multiple agents.

Arguments: `$ARGUMENTS`
Expected format: `<test_scope> [environments]`
Example: `all python3.9,python3.10,python3.11` or `src/s01_load_data.py unit,integration,performance`

Available test scopes:
- `all`: Run all available tests
- `unit`: Unit tests only
- `integration`: Integration tests only
- `performance`: Performance benchmarks
- `security`: Security tests
- `<file_path>`: Test specific module

Available environments:
- `python3.9`, `python3.10`, `python3.11`: Python versions
- `octave`: Octave/MRST environment
- `minimal`: Minimal dependencies
- `full`: All dependencies

## Instructions:

1. **Analyze test requirements**:
   - Identify test files to execute
   - Determine required environments
   - Estimate execution time

2. **Create parallel test agents using Task tool**:
   - **Unit Test Agent**: Fast unit tests across environments
   - **Integration Test Agent**: Integration tests with external dependencies
   - **Performance Test Agent**: Benchmarks and performance regression tests
   - **Security Test Agent**: Security vulnerability tests
   - **Compatibility Test Agent**: Cross-platform and version compatibility

3. **Environment setup per agent**:
   ```bash
   # Each agent sets up its environment independently
   python -m venv test_env_39
   source test_env_39/bin/activate
   pip install -r requirements.txt
   ```

4. **Parallel execution strategy**:
   - Each agent runs in isolated environment
   - Tests execute concurrently (up to 10 agents)
   - Real-time progress reporting
   - Failure isolation per environment

5. **Test result aggregation**:
   - Collect results from all agents
   - Generate unified test report
   - Identify environment-specific failures
   - Create failure analysis

6. **Generate comprehensive test report**:
   ```markdown
   # Parallel Test Execution Report
   
   ## Summary
   - Total tests: XXX
   - Passed: XXX
   - Failed: XXX
   - Environments tested: XXX
   - Execution time: XXX
   
   ## Environment Results
   
   ### Python 3.9
   - Status: PASS/FAIL
   - Tests: XXX/XXX
   - Duration: XXX
   - Failures: [list]
   
   ### Python 3.10
   - Status: PASS/FAIL
   - Tests: XXX/XXX
   - Duration: XXX
   - Failures: [list]
   
   ## Test Type Results
   
   ### Unit Tests
   - Coverage: XX%
   - Duration: XXX
   - Status: PASS/FAIL
   
   ### Integration Tests
   - External deps: OK/FAIL
   - Duration: XXX
   - Status: PASS/FAIL
   
   ### Performance Tests
   - Baseline comparison: ±X%
   - Regressions: [list]
   - Improvements: [list]
   
   ## Failure Analysis
   [Detailed failure breakdown]
   
   ## Recommendations
   [Action items for failures]
   ```

## Test Agent Specializations:

### Unit Test Agent
```bash
# Focused on fast, isolated tests
pytest tests/ -m "not integration" --cov=src/
```

### Integration Test Agent
```bash
# Tests with external dependencies
pytest tests/ -m integration --slow
```

### Performance Test Agent
```bash
# Benchmark and performance regression tests
pytest tests/ -m performance --benchmark-only
```

### Security Test Agent
```bash
# Security-focused testing
bandit -r src/
safety check
pytest tests/ -m security
```

### Compatibility Test Agent
```bash
# Cross-environment compatibility
tox -e py39,py310,py311
```

## Coordination Strategy:

1. **Resource Management**: Each agent uses separate temp directories
2. **Database Isolation**: Separate test databases per agent
3. **Port Management**: Dynamic port allocation for services
4. **Result Collection**: Centralized result aggregation
5. **Failure Handling**: Continue other agents if one fails

## Performance Optimization:

- Parallel execution reduces total test time
- Environment isolation prevents conflicts
- Smart test selection based on changes
- Caching of environment setups
- Result streaming for immediate feedback