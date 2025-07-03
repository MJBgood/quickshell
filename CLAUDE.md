# LLM Development Directives for Quickshell Project

## 🔍 Always Start Here

**Before any development work:**
1. Check Context7 MCP server for latest Quickshell documentation
2. Review project's `.docs/` folder for relevant info
3. Ground all solutions in official documentation first (1st party -> 2nd party -> 3rd party)

## 🧠 Core Thinking Patterns

### Documentation-First Mindset
- **Question**: "Does Quickshell already provide this functionality?"
- **Action**: Research first-party solutions before implementing custom code
- **Principle**: Prefer platform-native approaches over custom implementations

### Resource Efficiency Mindset  
- **Question**: "Do I need this resource immediately, or can it wait?"
- **Action**: Default to lazy loading for non-critical functionality
- **Principle**: Minimize startup time and memory footprint

### User Experience Mindset
- **Question**: "How can users easily share, discover, and customize this?"
- **Action**: Design for portability, auto-discovery, and graceful degradation
- **Principle**: Reduce friction in user workflows

### Architecture Mindset
- **Question**: "How does this fit into our separation of concerns?"
- **Action**: Maintain clear boundaries between presentation, logic, data, and configuration
- **Principle**: Each component should have a single, well-defined responsibility

## 🎯 Decision Framework

When facing any development choice, prioritize in this order:

1. **Documentation Compliance**: Does this align with best practices?
2. **Resource Efficiency**: Can this be loaded/computed only when needed?
3. **User Experience**: Does this make the system easier to use and customize?
4. **Maintainability**: Will this be clear to future developers?
5. **Performance**: Does this minimize system resource usage?

## 🚫 Warning Signals

If you find yourself doing any of these, reconsider:
- Implementing functionality that might already exist extensively
- Loading resources that aren't immediately visible/needed
- Creating custom solutions without checking documentation first
- Making configuration difficult to share or discover
- Breaking separation of concerns between components

## 🧩 Graphical Component Interface Pattern

**Core Concept**: All graphical components implement a standard interface similar to Go interfaces, ensuring consistent hierarchical navigation and menu systems throughout the project.

### Required Component Interface

Every graphical component MUST implement:

```qml
// Standard properties for hierarchy awareness
property string componentId: ""              // Unique identifier
property string parentComponentId: ""        // Parent component reference  
property var childComponentIds: []           // Array of child component IDs
property string menuPath: ""                 // Path in unified menu hierarchy

// Standard methods for consistent behavior
function menu(startPath) { /* Show context menu */ }
function getParent() { /* Return parent component */ }
function getChildren() { /* Return child components */ }
function navigateToParent() { /* Navigate to parent menu */ }
function navigateToChild(childId) { /* Navigate to child menu */ }
```

### Implementation Rules

1. **Hierarchy Awareness**: Every component knows its parent and children
2. **Menu Integration**: All components use unified menu system with `menu()` method
3. **Navigation Consistency**: Use `parent.menu()` or `child.menu()` for traversal
4. **Path-based Starting**: Components can start menus at specific hierarchy paths
5. **Interface Compliance**: No component should deviate from this standard interface

### Example Implementation

```qml
// Performance widget implementing GraphicalComponent interface
Rectangle {
    // Interface implementation
    property string componentId: "performance"
    property string parentComponentId: "system"
    property var childComponentIds: ["cpu", "ram", "storage"]
    property string menuPath: "system.performance"  // can this use componentId and parentComponentId to dynamically create instead? Maybe this should be a function call (getter) instead.
    
    function menu(startPath) {
        unifiedMenu.show(this, 0, 0, startPath || menuPath)
    }
    
    function navigateToParent() {
        if (parentComponent) parentComponent.menu()
    }
}
```

### Benefits

- **Consistent UX**: Every component behaves predictably
- **Easy Traversal**: Navigate between any components using standard methods
- **Maintainable**: Clear interface contract for all developers
- **Extensible**: New components automatically integrate with existing hierarchy

## 📋 Quality Gates

Before considering any implementation complete:
- [ ] Verified against latest documentation for dependencies
- [ ] Implements lazy loading where applicable
- [ ] Provides graceful fallbacks for missing resources
- [ ] Follows established project architecture patterns
- [ ] Minimizes resource usage during startup
- [ ] Implements GraphicalComponent interface with parent/child awareness
- [ ] Provides standard menu() method for hierarchical navigation

---

**Core Philosophy**: Build efficient, user-friendly systems by leveraging platform capabilities and deferring resource usage until actually needed. All graphical components must implement the standard interface for consistent hierarchical navigation.