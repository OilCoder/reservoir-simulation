# No Over-Engineering Policy

## Core Principle
**Write Only What You Need** - Implement exactly what is required, nothing more. Resist the temptation to build for imagined future needs or add "just in case" features.

## Fundamental Rules

### 1. **Function Length Limit**
- Functions should be **under 50 lines** whenever possible
- If a function exceeds 50 lines, it probably does too many things
- Break down complex operations into focused, single-purpose functions
- Exception: Only when breaking down would create artificial complexity

### 2. **No Speculative Code**
- Don't write code for features that aren't explicitly requested
- Don't add parameters "just in case" they're needed later
- Don't create abstractions until you have 3+ concrete use cases
- Don't build frameworks when simple functions suffice

### 3. **Eliminate Unnecessary Complexity**
- Choose the simplest solution that works
- Avoid design patterns when simple code is clearer
- Don't create classes when functions are sufficient
- Remove layers of abstraction that don't add clear value

### 4. **Minimal Configuration**
- Configuration should be straightforward and obvious
- Don't create complex configuration hierarchies for simple settings
- Use environment variables or simple YAML for most cases
- Avoid configuration that configures configuration

## What Constitutes Over-Engineering

### **Code Structure Over-Engineering:**
```python
# ❌ OVER-ENGINEERED: Abstract factory for simple object creation
class FluidFactory:
    def create_fluid(self, type, **kwargs):
        if type == "oil":
            return OilFluid(**kwargs)
        elif type == "water":
            return WaterFluid(**kwargs)

# ✅ SIMPLE: Direct instantiation
oil = OilFluid(density=850, viscosity=2.5)
water = WaterFluid(density=1000, viscosity=1.0)
```

### **Function Over-Engineering:**
```python
# ❌ OVER-ENGINEERED: Complex validation chain
def validate_input_with_comprehensive_checks_and_fallbacks(data):
    validator = InputValidator()
    validator.add_rule(RequiredFieldRule())
    validator.add_rule(TypeValidationRule())
    validator.add_rule(RangeValidationRule())
    return validator.validate_with_fallback_strategies(data)

# ✅ SIMPLE: Direct validation
def validate_input(data):
    if 'pressure' not in data:
        error('Missing pressure in input')
    if data['pressure'] < 0:
        error('Pressure must be positive')
    return data
```

### **Configuration Over-Engineering:**
```yaml
# ❌ OVER-ENGINEERED: Nested configuration hell
system:
  components:
    fluid_handler:
      initialization:
        strategy: "yaml_based"
        fallback_strategies:
          - "default_values"
          - "environment_based"
        validation:
          strict_mode: true
          error_handling:
            strategy: "fail_fast"

# ✅ SIMPLE: Direct configuration
fluid:
  oil_density: 850
  water_density: 1000
  gas_density: 1.2
```

## Benefits of Avoiding Over-Engineering

### **Development Speed:**
- Faster to write and understand
- Easier to modify when requirements change
- Less code to debug and maintain
- Clearer mental model of the system

### **Maintenance:**
- New team members can understand code quickly
- Fewer places for bugs to hide
- Simpler testing requirements
- Easier to refactor when needed

### **User Experience:**
- More predictable behavior
- Clearer error messages
- Faster execution (less abstraction overhead)
- Easier configuration and setup

## Implementation Guidelines

### **Before Writing Code, Ask:**
1. "What is the simplest way to solve this specific problem?"
2. "Am I solving the current requirement or imagined future requirements?"
3. "Would a junior developer understand this code in 6 months?"
4. "Can I remove any of these abstractions without losing essential functionality?"

### **Code Review Red Flags:**
- Functions longer than 50 lines without clear justification
- Abstract base classes with only one concrete implementation
- Configuration options that aren't currently used
- Helper functions that are only called once
- Design patterns used for single use cases

### **Refactoring Triggers:**
- When adding a simple feature requires changing 5+ files
- When writing tests requires extensive mocking
- When explaining the code takes longer than reading it
- When "simple" changes ripple through multiple abstraction layers

## Enforcement Examples

### **File Length Targets:**
- Main workflow scripts: **30-50 lines**
- Utility functions: **15-30 lines**  
- Configuration loading: **10-20 lines**
- Validation functions: **5-15 lines**

### **Complexity Limits:**
- Maximum 3 levels of nested conditionals
- No more than 2-3 parameters per function (use structs/objects for more)
- Avoid callback chains longer than 2 levels
- Keep class hierarchies shallow (max 2-3 levels)

### **Documentation Balance:**
- Comments should explain "why", not "what"
- If code needs extensive comments to understand, simplify the code
- Prefer self-documenting variable and function names
- Keep docstrings concise and focused

## Anti-Patterns to Avoid

### **The "Framework" Trap:**
Building a mini-framework when 2-3 simple functions would suffice.

### **The "Future-Proofing" Trap:**
Adding flexibility for requirements that don't exist yet.

### **The "One True Way" Trap:**
Creating elaborate abstractions to ensure all code follows the same pattern.

### **The "Configuration Everything" Trap:**
Making every constant configurable "just in case."

## Success Metrics

### **Quantitative Measures:**
- Average function length < 30 lines
- Files under 100 lines (except data/constants)
- Cyclomatic complexity < 10 per function
- Maximum nesting depth of 3

### **Qualitative Measures:**
- New team member can understand file purpose in < 2 minutes
- Making common changes touches < 3 files
- Code reviews focus on logic, not understanding structure
- Error messages point directly to solutions

**Remember: The best code is the code you don't have to write. The second best code is code so simple it obviously has no bugs.**