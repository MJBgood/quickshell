import QtQuick
import "../overlays"
import "." as Base

// Base component that implements the standard GraphicalComponent interface
// All graphical components should inherit from this to ensure consistent behavior
Item {
    id: baseComponent
    
    // Standard interface properties - REQUIRED for all components
    property string componentId: ""                    // Unique identifier (e.g., "performance")
    property string parentComponentId: ""              // Parent component ID (e.g., "system")  
    property var childComponentIds: []                 // Array of child component IDs (e.g., ["cpu", "ram", "storage"])
    property string menuPath: ""                       // Path in unified menu hierarchy (e.g., "system.performance")
    
    // Services - passed down from parent components
    property var configService: null
    property var themeService: null
    property var barWindow: null
    
    // Unified menu loader - lazy loaded
    property alias menuLoader: menuLoader
    
    Loader {
        id: menuLoader
        source: "../overlays/UnifiedMenu.qml"
        active: false
        
        onLoaded: {
            item.configService = baseComponent.configService
            item.themeService = baseComponent.themeService
            
            item.closed.connect(function() {
                menuLoader.active = false
            })
        }
    }
    
    // Standard interface methods - REQUIRED for all components
    
    /**
     * Show the context menu for this component
     * @param {Item} anchorWindow - Window to anchor the menu to
     * @param {number} x - X position for menu
     * @param {number} y - Y position for menu  
     * @param {string} startPath - Optional path to start menu at (defaults to component's menuPath)
     */
    function menu(anchorWindow, x, y, startPath) {
        console.log(`[${componentId}] Opening menu at path: ${startPath || menuPath}`)
        
        menuLoader.active = true
        if (menuLoader.item) {
            const windowToUse = anchorWindow || barWindow || baseComponent
            const globalPos = baseComponent.mapToItem(null, x || 0, y || 0)
            menuLoader.item.show(windowToUse, globalPos.x, globalPos.y, startPath || menuPath)
        }
    }
    
    /**
     * Get parent component reference
     * @returns {Item} Parent component or null
     */
    function getParent() {
        if (!parentComponentId) return null
        return Base.ComponentRegistry.getComponent(parentComponentId)
    }
    
    /**
     * Get array of child component references
     * @returns {Array} Array of child components
     */
    function getChildren() {
        return childComponentIds.map(id => Base.ComponentRegistry.getComponent(id)).filter(comp => comp !== null)
    }
    
    /**
     * Navigate to parent component's menu
     */
    function navigateToParent() {
        const parent = getParent()
        if (parent && typeof parent.menu === 'function') {
            console.log(`[${componentId}] Navigating to parent: ${parentComponentId}`)
            parent.menu()
        } else {
            console.log(`[${componentId}] No parent component found or parent doesn't implement menu()`)
        }
    }
    
    /**
     * Navigate to specific child component's menu
     * @param {string} childId - ID of child component to navigate to
     */
    function navigateToChild(childId) {
        const child = Base.ComponentRegistry.getComponent(childId)
        if (child && typeof child.menu === 'function') {
            console.log(`[${componentId}] Navigating to child: ${childId}`)
            child.menu()
        } else {
            console.log(`[${componentId}] Child component ${childId} not found or doesn't implement menu()`)
        }
    }
    
    /**
     * Register this component with the global registry
     */
    function registerComponent() {
        if (componentId) {
            Base.ComponentRegistry.registerComponent(componentId, baseComponent)
            console.log(`[${componentId}] Registered component with hierarchy: parent=${parentComponentId}, children=[${childComponentIds.join(', ')}]`)
        }
    }
    
    /**
     * Unregister this component from the global registry
     */
    function unregisterComponent() {
        if (componentId) {
            Base.ComponentRegistry.unregisterComponent(componentId)
            console.log(`[${componentId}] Unregistered component`)
        }
    }
    
    // Lifecycle hooks
    Component.onCompleted: {
        registerComponent()
    }
    
    Component.onDestruction: {
        unregisterComponent()
    }
    
    // Validation function to ensure interface compliance
    function validateInterface() {
        const errors = []
        
        if (!componentId) errors.push("componentId is required")
        if (!menuPath) errors.push("menuPath is required")
        
        if (errors.length > 0) {
            console.error(`[${componentId || 'UNKNOWN'}] GraphicalComponent interface validation failed:`)
            errors.forEach(error => console.error(`  - ${error}`))
            return false
        }
        
        return true
    }
    
    // Debug function to log component hierarchy
    function logHierarchy() {
        console.log(`[${componentId}] Component Hierarchy:`)
        console.log(`  ID: ${componentId}`)
        console.log(`  Menu Path: ${menuPath}`)
        console.log(`  Parent: ${parentComponentId || 'None'}`)
        console.log(`  Children: [${childComponentIds.join(', ') || 'None'}]`)
        
        const parent = getParent()
        const children = getChildren()
        console.log(`  Parent Reference: ${parent ? 'Found' : 'Not Found'}`)
        console.log(`  Child References: ${children.length}/${childComponentIds.length} found`)
    }
}