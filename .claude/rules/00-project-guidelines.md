---
description: Define the role and scope of each rule in the codebase
---

## Coding Rules Index

**Purpose**: Verifiable conventions and standards for code quality, formatting, and organization.

### Rules (Practical Conventions)
0. **00-project-guidelines.md** – Rule index and policy references
1. **01-code-style.md** – Layout, naming, spacing, and structure standards
2. **02-code-change.md** – Scope discipline for focused changes
3. **03-test-script.md** – Test naming conventions and structure
4. **04-debug-script.md** – Debug practices and cleanup standards
5. **05-file-naming.md** – File naming patterns across project
6. **06-doc-enforcement.md** – Docstring requirements and standards
7. **07-docs-style.md** – Markdown documentation format
8. **08-logging-policy.md** – Logging and output control

### Policies (Immutable Principles)
See **`.claude/policies/`** for fundamental development principles:
- **canon-first.md** – Context-aware specification enforcement
- **data-authority.md** – Authoritative data sources and anti-hardcoding
- **fail-fast.md** – Immediate failure on missing requirements
- **exception-handling.md** – Explicit validation over exception handling
- **kiss-principle.md** – Simplicity and minimalism in design

## Enforcement Strategy

### Rules Application (Verifiable Standards)
- **Style Compliance** – All code must follow rules 1-8, 10
- **Documentation** – Docstrings required per rule 6
- **File Organization** – Naming and structure per rules 4-5
- **Testing Isolation** – Tests in tests/ folder per rule 3
- **Debug Cleanup** – Debug code isolated per rule 4

### Policy Application (Principle Guidance)
- **All policies** in `.claude/policies/` provide philosophical guidance
- **Context-aware application** based on development phase
- **Progressive enforcement** from prototype → development → production
- **Override mechanisms** available for special circumstances

### Validation Modes
- **suggest** – Recommendations and warnings (development/prototype)
- **warn** – Clear violations flagged but not blocking (development)
- **strict** – Enforcement with failures (production/final)

## Project Structure Reference
- **Primary**: `obsidian-vault/Planning/` – Technical documentation
- **Architecture**: Standard folder patterns (src/, tests/, debug/, mrst_simulation_scripts/)
- **Configuration**: YAML configs with complete documentation
- **Development**: Multi-agent Claude Code integration