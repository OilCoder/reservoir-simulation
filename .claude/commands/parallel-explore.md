---
allowed-tools: [Task, Read, Glob, Grep]
description: Deploy multiple agents to explore and analyze large codebases in parallel
---

# Parallel Codebase Exploration

Deploy multiple specialized agents to explore and analyze a large codebase concurrently, each focusing on different aspects.

Arguments: `$ARGUMENTS`
Expected format: `<scope> [analysis_types]`
Example: `src/` or `entire_project architecture,dependencies,patterns`

Available analysis types:
- `architecture`: System design and module relationships
- `dependencies`: Import graphs and dependency analysis
- `patterns`: Design patterns and code conventions  
- `complexity`: Code complexity and hotspot analysis
- `security`: Security patterns and vulnerabilities
- `performance`: Performance patterns and bottlenecks
- `testing`: Test coverage and quality analysis
- `documentation`: Documentation completeness

## Instructions:

1. **Scope Assessment**:
   - Determine codebase size and complexity
   - Identify entry points and main modules
   - Estimate exploration effort required

2. **Deploy Specialized Explorer Agents using Task tool**:
   - **Architecture Agent**: Map system structure and relationships
   - **Dependency Agent**: Trace imports and build dependency graphs
   - **Pattern Agent**: Identify design patterns and conventions
   - **Complexity Agent**: Analyze complexity metrics and hotspots
   - **Security Agent**: Scan for security patterns and issues
   - **Performance Agent**: Identify performance-critical code
   - **Testing Agent**: Analyze test coverage and structure
   - **Documentation Agent**: Assess documentation quality

3. **Parallel exploration strategy**:
   - Each agent focuses on their specialization
   - Agents can work on same files from different perspectives
   - Up to 8 agents working concurrently
   - Real-time progress and discovery reporting

4. **Generate comprehensive analysis report**:
   ```markdown
   # Codebase Exploration Report
   
   ## Executive Summary
   - Codebase size: XXX files, XXX lines
   - Primary languages: Python, Octave
   - Architecture style: [Layered/Microservices/Monolithic]
   - Overall health score: X/10
   
   ## Architecture Analysis
   [System structure, modules, relationships]
   
   ## Dependency Analysis  
   [Import graphs, circular dependencies, external deps]
   
   ## Pattern Analysis
   [Design patterns used, conventions, anti-patterns]
   
   ## Complexity Analysis
   [Hotspots, technical debt, refactoring candidates]
   
   ## Security Analysis
   [Security patterns, vulnerabilities, best practices]
   
   ## Performance Analysis
   [Bottlenecks, optimization opportunities]
   
   ## Testing Analysis
   [Coverage, quality, gaps]
   
   ## Documentation Analysis
   [Completeness, quality, gaps]
   
   ## Recommendations
   [Prioritized action items]
   ```

## Explorer Agent Specializations:

### Architecture Agent
```bash
# Map system structure
find . -name "*.py" -o -name "*.m" | head -50
# Analyze module relationships
grep -r "^from\|^import" src/ | head -20
# Identify main entry points
find . -name "__main__.py" -o -name "main.*"
```

**Focus areas:**
- Module hierarchy and organization
- Interface definitions and contracts
- System boundaries and layers
- Component relationships
- Architectural patterns (MVC, MVP, etc.)

### Dependency Agent
```bash
# Build import graph
grep -r "^import\|^from" --include="*.py" src/
# Check external dependencies
cat requirements.txt pyproject.toml setup.py 2>/dev/null
# Analyze circular dependencies
```

**Focus areas:**
- Internal module dependencies
- External library usage
- Circular dependency detection
- Dependency version management
- Unused imports

### Pattern Agent
```python
# Search for common patterns
patterns = [
    "class.*Factory",      # Factory pattern
    "class.*Singleton",    # Singleton pattern
    "def __enter__",       # Context manager
    "@property",           # Property pattern
    "@classmethod",        # Class methods
]
```

**Focus areas:**
- Design pattern implementations
- Coding conventions and standards
- Anti-pattern detection
- Consistency analysis
- Best practice adherence

### Complexity Agent
```bash
# Analyze complexity metrics
wc -l src/**/*.py | sort -nr | head -10
# Find long functions
grep -n "^def\|^    def" src/*.py | head -20
# Identify complex logic
grep -r "if.*and.*or\|for.*in.*if" src/
```

**Focus areas:**
- Cyclomatic complexity
- Function length analysis
- Nesting depth
- Code duplication
- Refactoring opportunities

### Security Agent
```bash
# Security pattern analysis
grep -r "password\|secret\|token\|auth" --include="*.py" src/
# Input validation patterns
grep -r "request\|input\|user.*data" src/
# Error handling
grep -r "try:\|except\|raise\|assert" src/
```

**Focus areas:**
- Authentication/authorization patterns
- Input validation and sanitization
- Error handling and logging
- Secret management
- Security best practices

### Performance Agent
```bash
# Performance-critical code
grep -r "loop\|iterate\|process.*data" src/
# Database operations
grep -r "query\|select\|insert\|update" src/
# I/O operations
grep -r "open\|read\|write\|file" src/
```

**Focus areas:**
- Algorithm efficiency
- I/O operation patterns
- Memory usage patterns
- Caching strategies
- Performance bottlenecks

### Testing Agent
```bash
# Test coverage analysis
find tests/ -name "*.py" | wc -l
# Test patterns
grep -r "def test_\|@pytest" tests/
# Mock usage
grep -r "mock\|patch\|fixture" tests/
```

**Focus areas:**
- Test coverage metrics
- Test quality and structure
- Testing patterns used
- Mock and fixture usage
- Edge case coverage

### Documentation Agent
```bash
# Documentation completeness
grep -r '"""' src/ | wc -l
# TODO and FIXME comments
grep -r "TODO\|FIXME\|XXX" src/
# README and docs
find . -name "README*" -o -name "*.md"
```

**Focus areas:**
- Docstring coverage and quality
- Code comment quality
- Documentation files
- TODO/FIXME tracking
- API documentation

## Coordination and Reporting:

### Real-time Progress Tracking
```markdown
# Exploration Progress (updated every 30 seconds)
- Architecture Agent: 🔍 Analyzing module relationships... (60% complete)
- Dependency Agent: ✅ Dependency graph complete (100% complete) 
- Pattern Agent: 🔍 Scanning for design patterns... (40% complete)
- Complexity Agent: 🔍 Computing complexity metrics... (75% complete)
```

### Discovery Sharing
- Agents share interesting findings in real-time
- Cross-reference discoveries between agents
- Build comprehensive understanding iteratively

### Adaptive Exploration
- Agents can adjust focus based on discoveries
- Deep-dive into areas flagged by other agents
- Skip areas that appear simple or well-understood

## Output Formats:

### Interactive Dashboard
- Real-time exploration progress
- Clickable code navigation
- Filter findings by agent/category
- Visual dependency graphs

### Structured Report
- Executive summary for stakeholders
- Technical details for developers
- Actionable recommendations
- Priority-based improvement plan

### Raw Data Export
- JSON/CSV formats for further analysis
- Integration with external tools
- Historical comparison data
- Metrics tracking over time