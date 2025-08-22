# Claude Code Directory Structure

## 📁 Final Clean Structure

```
.claude/
├── 📋 policies/                    # Immutable principles (5 policies) 
│   ├── canon-first.md             # Context-aware specification enforcement
│   ├── data-authority.md          # Authoritative data sources and anti-hardcoding
│   ├── fail-fast.md               # Immediate failure on missing requirements
│   ├── exception-handling.md      # Explicit validation over exception handling
│   └── kiss-principle.md          # Simplicity and minimalism in design
│
├── 📜 rules/                       # Coding standards (8 rules)
│   ├── 00-project-guidelines.md   # Rule index and overview
│   ├── 01-code-style.md          # Layout, naming, structure
│   ├── 02-code-change.md         # Scope discipline
│   ├── 03-test-script.md         # Test conventions
│   ├── 04-debug-script.md        # Debug practices
│   ├── 05-file-naming.md         # File naming patterns
│   ├── 06-doc-enforcement.md     # Docstring requirements
│   ├── 07-docs-style.md          # Markdown style
│   └── 08-logging-policy.md      # Logging guidelines
│
├── 🤖 agents/                      # Specialized AI agents
│   ├── coder.md                  # Production code writer
│   ├── tester.md                 # Test creator
│   ├── debugger.md               # Debug specialist
│   └── doc-writer.md             # Documentation writer
│
├── 🔗 hooks/                       # Validation and routing
│   ├── user_prompt_submit.py     # Natural language router + policy injection
│   ├── post_tool_use.py          # Multi-mode policy validation (suggest/warn/strict)
│   ├── post_response.py          # Auto-apply diffs + CI
│   └── subagent_stop.py          # Agent coordination
│
├── ⚡ commands/                    # Custom slash commands  
│   └── validate                   # Canon-first compliance scanner
│
├── ⚙️ settings.json               # Main configuration
└── 🔧 settings.local.json         # Local overrides
```

## 🔧 Component Functions

### Policies (Immutable Principles)
- **canon-first.md**: Context-aware specification enforcement with suggest/warn/strict modes
- **data-authority.md**: Authoritative data sources, no hardcoding domain values
- **fail-fast.md**: Immediate failure on missing requirements, no defensive defaults
- **exception-handling.md**: Explicit validation over exception handling
- **kiss-principle.md**: Simplicity and minimalism in design

### Rules (Your Coding Style) 
- **00-07, 10**: Your established coding standards
- **08**: Logging and output control
- ~~**09**: Moved to policies/canon-first.md~~

### Agents (Task Specialists)
- **coder**: Default agent, handles most coding tasks with canon-first
- **tester**: Creates tests that validate config compliance  
- **debugger**: Investigates issues
- **doc-writer**: Documentation specialist

### Hooks (Automatic Validation)
- **user_prompt_submit.py**: Detects intent + injects policy context
- **post_tool_use.py**: Multi-mode policy validation with context awareness
- **post_response.py**: Auto-applies diffs + runs CI
- **subagent_stop.py**: Coordinates between agents

### Commands
- **validate**: Manual scanner for canon-first compliance

## 🗑️ Removed Files
- ~~user_prompt_submit_v2.py~~ (obsolete)
- ~~rules/09-canon-first-philosophy.md~~ (moved to policies/)
- ~~README-OPTIMIZATION.md~~ (obsolete)

## 🎯 Key Features
1. **No Duplication** - Each component has single responsibility
2. **Clean Hierarchy** - Policies > Rules > Implementation
3. **Generic System** - Works on any project type
4. **Context-Aware Validation** - suggest/warn/strict modes based on development phase
5. **Flexible Policy Enforcement** - Balances principles with development pragmatism
6. **Override Mechanisms** - File-level and environment-level policy overrides

## 🚀 Usage
- Write in natural language
- System detects intent automatically  
- Appropriate agent activated with policy context
- Code validated with appropriate strictness level
- Context-aware policy enforcement based on development phase

### Validation Modes
- **suggest** - Prototyping: Recommendations and guidance
- **warn** - Development: Clear violations flagged but not blocking
- **strict** - Production: Full enforcement with blocking on errors

### Override Examples
```python
# @policy-override: suggest
# This file uses prototype mode for experimental features
```

```bash
export CLAUDE_VALIDATION_MODE=strict  # Force strict mode
```