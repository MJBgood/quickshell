// ComponentRegistry.qml - Singleton for managing component hierarchy
pragma Singleton
import Quickshell

Singleton {
    id: registry
    
    property var components: ({})
    
    function registerComponent(id, component) {
        if (!id || !component) {
            console.error("[ComponentRegistry] Cannot register component: invalid id or component")
            return false
        }
        
        components[id] = component
        console.log(`[ComponentRegistry] Registered: ${id}`)
        return true
    }
    
    function unregisterComponent(id) {
        if (components[id]) {
            delete components[id]
            console.log(`[ComponentRegistry] Unregistered: ${id}`)
            return true
        }
        return false
    }
    
    function getComponent(id) {
        return components[id] || null
    }
    
    function getAllComponents() {
        return Object.keys(components)
    }
    
    function findComponentsByParent(parentId) {
        return Object.keys(components).filter(id => {
            const component = components[id]
            return component && component.parentComponentId === parentId
        })
    }
    
    function getComponentHierarchy(rootId) {
        function buildHierarchy(componentId, level = 0) {
            const component = components[componentId]
            if (!component) return null
            
            const node = {
                id: componentId,
                level: level,
                component: component,
                children: []
            }
            
            // Find all children
            const children = findComponentsByParent(componentId)
            children.forEach(childId => {
                const childNode = buildHierarchy(childId, level + 1)
                if (childNode) {
                    node.children.push(childNode)
                }
            })
            
            return node
        }
        
        return buildHierarchy(rootId)
    }
    
    function logRegistry() {
        console.log("[ComponentRegistry] Registered components:")
        Object.keys(components).forEach(id => {
            const comp = components[id]
            console.log(`  - ${id}: parent=${comp.parentComponentId || 'None'}, children=[${comp.childComponentIds.join(', ') || 'None'}]`)
        })
    }
    
    function validateHierarchy() {
        console.log("[ComponentRegistry] Validating component hierarchy...")
        let valid = true
        
        Object.keys(components).forEach(id => {
            const component = components[id]
            
            // Check if parent exists (if specified)
            if (component.parentComponentId && !components[component.parentComponentId]) {
                console.error(`[ComponentRegistry] ${id}: Parent component '${component.parentComponentId}' not found`)
                valid = false
            }
            
            // Check if children exist
            if (component.childComponentIds) {
                component.childComponentIds.forEach(childId => {
                    if (!components[childId]) {
                        console.error(`[ComponentRegistry] ${id}: Child component '${childId}' not found`)
                        valid = false
                    }
                })
            }
        })
        
        console.log(`[ComponentRegistry] Hierarchy validation: ${valid ? 'PASSED' : 'FAILED'}`)
        return valid
    }
}