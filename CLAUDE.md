# LLM Development Guidelines

## Core Principles

1. **Documentation First**: Research platform solutions before implementing custom code
2. **Separation of Concerns**: Clear boundaries between presentation, logic, data, and configuration  
3. **Resource Efficiency**: Lazy load non-critical functionality, minimize startup time
4. **User Experience**: Design for portability, discoverability, and graceful degradation
5. **Maintainability**: Use clear naming, single responsibility, and established patterns
6. **No Sicophancy**: Your answer should not change based on the way the user asked.

## Decision Framework

Prioritize in this order:
1. **Documentation Compliance** - Does this align with best practices?
2. **Resource Efficiency** - Can this be loaded only when needed?
3. **Maintainability** - Will this be clear to future developers?
4. **Performance** - Does this minimize resource usage?

## Warning Signals

Reconsider if you're:
- Implementing functionality that might already exist
- Loading resources that aren't immediately needed
- Creating custom solutions without checking documentation first
- Breaking separation of concerns

## General Development Principles

1. **Research Before Implementation**: Check if functionality already exists in platform/framework
2. **Consistency Through Patterns**: Copy working examples, use standardized interfaces
3. **Resource Management**: Lazy loading, singleton pattern, reactive properties, proper cleanup
4. **User Experience Focus**: Predictable behavior, graceful degradation, performance optimization
5. **Problem-Solving**: Understand root causes, test incrementally, follow established patterns

---

# Project-Specific Patterns (Quickshell/QML)

## Entity Configuration System

All configurable components use unique entity IDs for unified configuration access.

**Naming Convention**: `CpuWidget` with entityId `cpu.widget`, `CpuService` with entityId `cpu.service`

**API**:
```qml
configService.getEntityProperty(entityId, property, defaultValue)
configService.typography(size, entityId)  // "xs", "sm", "md", "lg", "xl"
```

## Singleton Service Pattern

- Use `pragma Singleton` with `Singleton` root type
- Backend-frontend separation: UI components handle presentation, services handle logic
- Reactive properties that automatically update UI components
- Clean APIs: `setVolume()`, `getBrightness()`, etc.

## Component Interface Pattern

All graphical components implement:
```qml
property string componentId: ""
property string parentComponentId: ""
function menu(startPath) { /* Show context menu */ }
```

## Context Menu Pattern

All context menus use `PopupWindow` with `HyprlandFocusGrab` for click-outside-to-close:
```qml
PopupWindow {
    HyprlandFocusGrab {
        windows: [contextMenu]
        onCleared: hide()
    }
}
```

