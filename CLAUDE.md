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

## 🧩 Entity ID Configuration System

**Core Concept**: All configurable components (bars, widgets, menus, overlays) use unique entity IDs for unified configuration access. This provides four-tier scaling resolution and future-proof architecture for any shell component type.

### Entity ID Architecture Principles

1. **Unified Configuration**: Single flat namespace for all customizable components
2. **Future-Proof Design**: Any component type uses the same entity-based configuration API
3. **Four-Tier Resolution**: Global scale → global defaults → entity overrides → numerical overrides
4. **Semantic Scaling**: Use meaningful size names (sm, md, lg) instead of pixel values

### Required Entity Configuration Interface

Every configurable component MUST implement:

```qml
Rectangle {
    // Entity identification
    property string entityId: "clockWidget"  // Unique identifier for configuration
    
    // Use entity-aware configuration
    implicitHeight: configService.getEntityStyle(entityId, "height", "auto", contentHeight)
    color: configService.getEntityStyle(entityId, "backgroundColor", "auto", "transparent")
    
    Text {
        font.pixelSize: configService.typography("md", entityId)
        color: configService.getEntityStyle(entityId, "textColor", "auto", themeColor)
    }
}
```

### Configuration Structure

```yaml
scaling:
  globalScale: 1.0
  defaults:
    typography: "md"
    spacing: "md"
    icon: "md"

entities:
  topBar:
    height: "auto"
    backgroundColor: "surface"
    
  clockWidget:
    fontSize: "lg"        # Semantic override
    spacing: "sm"         # Semantic override
    showDate: true        # Functional property
    
  customWidget:
    fontSize: 13          # Numerical override (escape hatch)
    spacing: "auto"       # Use global default
```

### Entity ID Naming Convention

- **Bars**: topBar, bottomBar, leftSidebar
- **Widgets**: clockWidget, cpuWidget, batteryWidget, systrayWidget
- **Menus**: launcherMenu, contextMenu, settingsMenu
- **Overlays**: workspaceOverlay, notificationOverlay
- **Custom**: Descriptive names like "workClock", "gamingBar"

### ConfigService Entity API

```qml
// Entity property access
configService.getEntityProperty(entityId, property, defaultValue)
configService.getEntityStyle(entityId, styleProperty, defaultValue, contentValue)

// Semantic scaling with entity-aware overrides
configService.typography(size, entityId)  // "xs", "sm", "md", "lg", "xl"
configService.spacing(size, entityId)     // "xs", "sm", "md", "lg", "xl"
configService.icon(size, entityId)        // "xs", "sm", "md", "lg", "xl"

// Simplified height helper
configService.getWidgetHeight(entityId, contentHeight)
```

## 🧩 Singleton Service Pattern

**Core Concept**: All backend logic is abstracted into reusable singleton services that provide reactive properties and clean APIs, following Quickshell's recommended patterns for efficient resource usage and consistent state management.

### Service Architecture Principles

1. **Backend-Frontend Separation**: UI components (widgets/monitors) only handle presentation, while services handle all business logic
2. **Singleton Pattern**: Use `pragma Singleton` with `Singleton` root type for global state management
3. **Reactive Properties**: Services expose reactive properties that automatically update UI components
4. **Clean APIs**: Services provide simple functions for state manipulation (e.g., `setVolume()`, `setBrightness()`)
5. **Resource Efficiency**: Services lazy-load and bind to system resources only when needed

### Required Service Interface

Every service MUST implement:

```qml
pragma Singleton
import QtQuick
import Quickshell

Singleton {
    // Public reactive properties
    property bool ready: false
    
    // Internal state management
    property var systemReference: null
    
    // Public API functions
    function bindToSystem(system) { /* Bind to system resource */ }
    function getCurrentState() { /* Return current state */ }
    function refreshData() { /* Force refresh */ }
    
    // Internal reactivity
    Connections {
        target: systemReference
        function onDataChanged() { /* Update reactive properties */ }
    }
}
```

### Service Registration

Register all singletons in `services/qmldir`:

```
singleton ServiceName ServiceName.qml
```

### Widget-Service Integration

Widgets delegate all data access to services:

```qml
import "../../services"

Rectangle {
    // Delegate properties to service
    property real value: ServiceName.currentValue
    property bool ready: ServiceName.ready
    
    // Initialize service binding
    Component.onCompleted: {
        if (systemService) {
            ServiceName.bindToSystem(systemService)
        }
    }
}
```

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

## 🔧 Context Menu Implementation Pattern

**Core Concept**: All context menus follow the exact same pattern as working examples to ensure consistent behavior for click-outside-to-close, positioning, and user interaction.

### Required Context Menu Structure

Every context menu MUST implement:

```qml
PopupWindow {
    id: contextMenu
    
    // Standard window properties
    implicitWidth: 200
    implicitHeight: Math.min(300, menuContent.contentHeight + 32)
    visible: false
    color: "transparent"
    
    // Anchor configuration (EXACTLY as working examples)
    anchor {
        window: null
        rect { x: 0; y: 0; width: 1; height: 1 }
        edges: Edges.Top | Edges.Left
        gravity: Edges.Bottom | Edges.Right
        adjustment: PopupAdjustment.All
        margins { left: 8; right: 8; top: 8; bottom: 8 }
    }
    
    // Focus grab for dismissal (CRITICAL)
    HyprlandFocusGrab {
        id: focusGrab
        windows: [contextMenu]
        onCleared: hide()
    }
    
    // Content structure
    Rectangle {
        ScrollView { /* content */ }
    }
    
    // Standard show/hide functions
    function show(anchorWindow, x, y) {
        anchor.window = anchorWindow
        // positioning logic
        visible = true
        focusGrab.active = true
    }
    
    function hide() {
        visible = false
        focusGrab.active = false
    }
}
```

### Context Menu Rules

1. **Copy Working Examples**: Always base new context menus on existing working ones
2. **HyprlandFocusGrab Required**: Essential for click-outside-to-close behavior
3. **PopupWindow Over Rectangle**: Use PopupWindow, not Rectangle, for proper window management
4. **Anchor Configuration**: Use exact anchor pattern from working examples
5. **Consistent Structure**: ScrollView inside Rectangle inside PopupWindow

## 📋 Quality Gates

Before considering any implementation complete:
- [ ] Verified against latest documentation for dependencies
- [ ] Uses singleton service pattern for backend logic separation
- [ ] Implements lazy loading where applicable
- [ ] Provides graceful fallbacks for missing resources
- [ ] Follows established project architecture patterns
- [ ] Minimizes resource usage during startup
- [ ] Implements GraphicalComponent interface with parent/child awareness
- [ ] Provides standard menu() method for hierarchical navigation
- [ ] Context menus follow working example pattern exactly
- [ ] No widget overlapping issues with proper anchor dependencies

---

## 🎨 General Development Principles (Applicable to Any Project)

### 1. **Research Before Implementation** 
- Always check if functionality already exists in the platform/framework
- Read official documentation first, then community resources
- Understand the "blessed" patterns before creating custom solutions

### 2. **Separation of Concerns Architecture**
- **Backend Services**: Handle all business logic, data fetching, state management
- **Frontend Components**: Focus solely on presentation and user interaction  
- **Configuration Layer**: Centralize all settings and user preferences
- **Clear Interfaces**: Define contracts between layers with well-documented APIs

### 3. **Consistency Through Patterns**
- **Copy Working Examples**: When something works, use it as a template for similar functionality
- **Standardized Interfaces**: Define common interfaces that all similar components implement
- **Uniform Behavior**: Ensure similar actions behave the same way across the application

### 4. **Resource Efficiency**
- **Lazy Loading**: Load resources only when actually needed
- **Singleton Pattern**: Share state efficiently across components  
- **Reactive Properties**: Use framework reactivity instead of manual updates
- **Proper Cleanup**: Dispose of resources when components are destroyed

### 5. **User Experience Focus**
- **Predictable Behavior**: Users should be able to anticipate how things work
- **Graceful Degradation**: Handle missing resources without breaking functionality
- **Performance**: Minimize startup time and memory usage
- **Accessibility**: Follow platform conventions for interaction patterns

### 6. **Maintainable Code Practices**
- **Clear Naming**: Use descriptive names that explain purpose and intent
- **Single Responsibility**: Each component/service should have one clear purpose
- **Documentation**: Update project docs when adding new patterns or principles
- **Quality Gates**: Establish checklists to ensure consistent implementation

### 7. **Problem-Solving Approach**
- **Understand the Root Cause**: Don't just fix symptoms, understand why problems occur
- **Test Incrementally**: Make small changes and verify they work before proceeding
- **Follow Established Patterns**: Use proven approaches rather than reinventing solutions
- **Learn from Mistakes**: Document what went wrong and how to avoid it in the future

---

**Core Philosophy**: Build efficient, user-friendly systems by leveraging platform capabilities, following established patterns, and maintaining clear separation of concerns. Always research first, implement consistently, and prioritize user experience and maintainability.