---
allowed-tools: [Task, Read, Bash]
description: Deploy multiple agents for comprehensive code review
---

# Parallel Code Review

Deploy multiple specialized review agents to analyze different aspects of the codebase concurrently.

Arguments: `$ARGUMENTS`
Expected format: `<directory_or_file> [review_types]`
Example: `src/` or `src/s01_load_data.py security,performance,style`

Available review types:
- `security`: Security vulnerabilities and best practices
- `performance`: Performance bottlenecks and optimizations
- `style`: Code style and adherence to project rules
- `architecture`: Design patterns and structure
- `testing`: Test coverage and quality
- `documentation`: Docstring and comment quality

## Instructions:

1. **Analyze target scope**:
   - Determine files to review
   - Identify review types (default: all types)
   - Estimate review complexity

2. **Deploy specialized review agents using Task tool**:
   - **Security Agent**: Focus on vulnerabilities, input validation, secrets
   - **Performance Agent**: Analyze algorithms, memory usage, bottlenecks
   - **Style Agent**: Check naming, formatting, project rule compliance
   - **Architecture Agent**: Evaluate design patterns, modularity, coupling
   - **Testing Agent**: Assess test coverage, quality, edge cases
   - **Documentation Agent**: Review docstrings, comments, clarity

3. **Parallel execution strategy**:
   - Each agent reviews the same code from their perspective
   - Maximum 6 agents (one per specialization)
   - Each agent produces structured report

4. **Consolidate findings**:
   - Merge all agent reports
   - Prioritize issues by severity
   - Remove duplicates
   - Create action plan

5. **Generate comprehensive report**:
   ```markdown
   # Code Review Report
   
   ## Executive Summary
   - Overall code quality score
   - Critical issues count
   - Recommendations priority
   
   ## Security Review
   [Security agent findings]
   
   ## Performance Review
   [Performance agent findings]
   
   ## Style Review
   [Style agent findings]
   
   ## Architecture Review
   [Architecture agent findings]
   
   ## Testing Review
   [Testing agent findings]
   
   ## Documentation Review
   [Documentation agent findings]
   
   ## Action Plan
   1. Critical fixes (blocking)
   2. Important improvements
   3. Nice-to-have enhancements
   ```

## Review Agent Specializations:

### Security Agent
- Input validation and sanitization
- SQL injection, XSS prevention
- Secret detection and handling
- Authentication/authorization flaws
- Dependency vulnerabilities

### Performance Agent
- Algorithm complexity analysis
- Memory leak detection
- Database query optimization
- Caching opportunities
- Resource usage patterns

### Style Agent
- Project rule compliance
- Naming conventions
- Code formatting
- Comment quality
- Function length and complexity

### Architecture Agent
- Design pattern usage
- Modularity and coupling
- Separation of concerns
- Code organization
- Scalability considerations

### Testing Agent
- Test coverage analysis
- Test quality and completeness
- Edge case coverage
- Mock usage appropriateness
- Test maintainability

### Documentation Agent
- Docstring completeness and quality
- Code comment clarity
- README and setup documentation
- API documentation
- Usage examples