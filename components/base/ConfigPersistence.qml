// ConfigPersistence.qml - Component hierarchy and settings persistence using Quickshell's JsonAdapter
pragma Singleton
import Quickshell
import Quickshell.Io

Singleton {
    id: persistence
    
    // Use Quickshell's FileView with JsonAdapter for proper JSON persistence
    FileView {
        id: configFile
        path: Quickshell.stateDir + "/hierarchy.json"
        
        // Monitor file changes and automatically reload
        watchChanges: true
        onFileChanged: reload()
        
        // Save adapter changes automatically
        onAdapterUpdated: writeAdapter()
        
        adapter: JsonAdapter {
            id: hierarchyAdapter
            
            // Component hierarchy structure
            property var components: ({
                "root": {
                    "id": "root",
                    "type": "SystemRoot",
                    "parent": null,
                    "children": ["system", "interface", "widgets", "settings"],
                    "settings": {}
                },
                "system": {
                    "id": "system", 
                    "type": "SystemManager",
                    "parent": "root",
                    "children": ["performance"],
                    "settings": {}
                },
                "performance": {
                    "id": "performance",
                    "type": "PerformanceMonitor", 
                    "parent": "system",
                    "children": ["cpu", "ram", "storage"],
                    "settings": {
                        "layout": "horizontal",
                        "displayMode": "compact",
                        "updateInterval": 2000
                    }
                },
                "cpu": {
                    "id": "cpu",
                    "type": "CpuMonitor",
                    "parent": "performance", 
                    "children": [],
                    "settings": {
                        "enabled": true,
                        "showIcon": true,
                        "showLabel": false,
                        "showPercentage": true,
                        "showFrequency": false,
                        "precision": 1,
                        "updateInterval": 2000
                    }
                },
                "ram": {
                    "id": "ram",
                    "type": "RamMonitor",
                    "parent": "performance",
                    "children": [],
                    "settings": {
                        "enabled": true,
                        "showIcon": true,
                        "showLabel": false, 
                        "showPercentage": true,
                        "precision": 0,
                        "updateInterval": 2000
                    }
                },
                "storage": {
                    "id": "storage",
                    "type": "StorageMonitor",
                    "parent": "performance",
                    "children": [],
                    "settings": {
                        "enabled": false,
                        "showIcon": true,
                        "showLabel": false,
                        "showPercentage": true,
                        "showBytes": true,
                        "precision": 1,
                        "updateInterval": 30000
                    }
                },
                "interface": {
                    "id": "interface",
                    "type": "InterfaceManager",
                    "parent": "root",
                    "children": ["interface-theme", "interface-layout"],
                    "settings": {}
                },
                "interface-theme": {
                    "id": "interface-theme",
                    "type": "ThemeManager",
                    "parent": "interface",
                    "children": [],
                    "settings": {
                        "activeTheme": "catppuccin-mocha",
                        "activeMode": "dark",
                        "followSystemTheme": false
                    }
                },
                "interface-layout": {
                    "id": "interface-layout", 
                    "type": "LayoutManager",
                    "parent": "interface",
                    "children": [],
                    "settings": {
                        "panelHeight": 32,
                        "panelPosition": "top",
                        "autohide": false,
                        "opacity": 0.95
                    }
                },
                "widgets": {
                    "id": "widgets",
                    "type": "WidgetManager",
                    "parent": "root",
                    "children": ["widgets-bars", "widgets-overlays"],
                    "settings": {}
                },
                "widgets-bars": {
                    "id": "widgets-bars",
                    "type": "BarManager",
                    "parent": "widgets",
                    "children": [],
                    "settings": {}
                },
                "widgets-overlays": {
                    "id": "widgets-overlays",
                    "type": "OverlayManager",
                    "parent": "widgets", 
                    "children": [],
                    "settings": {}
                },
                "settings": {
                    "id": "settings",
                    "type": "SettingsManager",
                    "parent": "root",
                    "children": ["settings-config", "settings-profile"],
                    "settings": {}
                },
                "settings-config": {
                    "id": "settings-config",
                    "type": "ConfigManager",
                    "parent": "settings",
                    "children": [],
                    "settings": {
                        "autoSave": true,
                        "backupOnSave": true,
                        "maxBackups": 5
                    }
                },
                "settings-profile": {
                    "id": "settings-profile",
                    "type": "ProfileManager",
                    "parent": "settings",
                    "children": [],
                    "settings": {
                        "username": "",
                        "profileName": "default",
                        "customizations": {}
                    }
                }
            })
            
            // Metadata using simple var property 
            property var metadata: ({
                version: "1.0",
                created: Qt.formatDateTime(new Date(), Qt.ISODate),
                lastModified: Qt.formatDateTime(new Date(), Qt.ISODate),
                quickshellVersion: "1.0.0"
            })
            
            // Update timestamp when components change
            onComponentsChanged: {
                metadata.lastModified = Qt.formatDateTime(new Date(), Qt.ISODate)
            }
        }
    }
    
    // Public API functions
    
    // Get component configuration
    function getComponentConfig(componentId) {
        if (hierarchyAdapter.components[componentId]) {
            return hierarchyAdapter.components[componentId]
        }
        return null
    }
    
    // Update component settings
    function updateComponentSettings(componentId, settings) {
        if (hierarchyAdapter.components[componentId]) {
            const component = hierarchyAdapter.components[componentId]
            component.settings = Object.assign({}, component.settings, settings)
            hierarchyAdapter.components = hierarchyAdapter.components // Trigger change
            return true
        }
        return false
    }
    
    // Get setting value with fallback (compatible with existing ConfigService API)
    function getSetting(componentId, key, defaultValue) {
        const component = getComponentConfig(componentId)
        if (component && component.settings && component.settings.hasOwnProperty(key)) {
            return component.settings[key]
        }
        return defaultValue
    }
    
    // Set setting value (compatible with existing ConfigService API)
    function setSetting(componentId, key, value) {
        const component = getComponentConfig(componentId)
        if (component) {
            if (!component.settings) {
                component.settings = {}
            }
            component.settings[key] = value
            hierarchyAdapter.components = hierarchyAdapter.components // Trigger change
            return true
        }
        return false
    }
    
    // Add new component to hierarchy
    function addComponent(componentId, type, parentId, settings = {}) {
        if (hierarchyAdapter.components[componentId]) {
            console.warn(`[ConfigPersistence] Component ${componentId} already exists`)
            return false
        }
        
        const newComponents = Object.assign({}, hierarchyAdapter.components)
        newComponents[componentId] = {
            "id": componentId,
            "type": type,
            "parent": parentId,
            "children": [],
            "settings": settings
        }
        
        // Add to parent's children if parent exists
        if (parentId && newComponents[parentId]) {
            if (!newComponents[parentId].children.includes(componentId)) {
                newComponents[parentId].children.push(componentId)
            }
        }
        
        hierarchyAdapter.components = newComponents
        console.log(`[ConfigPersistence] Added component: ${componentId}`)
        return true
    }
    
    // Remove component from hierarchy
    function removeComponent(componentId) {
        const component = hierarchyAdapter.components[componentId]
        if (!component) {
            return false
        }
        
        const newComponents = Object.assign({}, hierarchyAdapter.components)
        
        // Remove from parent's children
        if (component.parent && newComponents[component.parent]) {
            const parentChildren = newComponents[component.parent].children
            const index = parentChildren.indexOf(componentId)
            if (index > -1) {
                parentChildren.splice(index, 1)
            }
        }
        
        // Recursively remove all children
        const children = [...component.children]
        children.forEach(childId => {
            if (newComponents[childId]) {
                delete newComponents[childId]
            }
        })
        
        // Remove the component itself
        delete newComponents[componentId]
        
        hierarchyAdapter.components = newComponents
        console.log(`[ConfigPersistence] Removed component: ${componentId}`)
        return true
    }
    
    // Force save configuration
    function saveConfig() {
        hierarchyAdapter.metadata.lastModified = Qt.formatDateTime(new Date(), Qt.ISODate)
        configFile.writeAdapter()
        console.log("[ConfigPersistence] Configuration saved manually")
    }
    
    // Validate hierarchy integrity
    function validateHierarchy() {
        console.log("[ConfigPersistence] Validating hierarchy integrity...")
        let errors = []
        
        Object.keys(hierarchyAdapter.components).forEach(componentId => {
            const component = hierarchyAdapter.components[componentId]
            
            // Check parent exists
            if (component.parent && !hierarchyAdapter.components[component.parent]) {
                errors.push(`Component ${componentId}: Parent '${component.parent}' not found`)
            }
            
            // Check children exist
            component.children.forEach(childId => {
                if (!hierarchyAdapter.components[childId]) {
                    errors.push(`Component ${componentId}: Child '${childId}' not found`)
                }
            })
            
            // Check parent-child consistency
            if (component.parent) {
                const parent = hierarchyAdapter.components[component.parent]
                if (parent && !parent.children.includes(componentId)) {
                    errors.push(`Component ${componentId}: Not listed in parent's children`)
                }
            }
        })
        
        if (errors.length > 0) {
            console.error("[ConfigPersistence] Hierarchy validation failed:")
            errors.forEach(error => console.error(`  - ${error}`))
            return false
        } else {
            console.log("[ConfigPersistence] Hierarchy validation passed")
            return true
        }
    }
    
    // Export configuration as JSON string for sharing
    function exportConfig() {
        return JSON.stringify({
            components: hierarchyAdapter.components,
            metadata: {
                version: hierarchyAdapter.metadata.version,
                created: hierarchyAdapter.metadata.created,
                lastModified: hierarchyAdapter.metadata.lastModified,
                quickshellVersion: hierarchyAdapter.metadata.quickshellVersion
            }
        }, null, 2)
    }
    
    // Import configuration from JSON string
    function importConfig(jsonString) {
        try {
            const imported = JSON.parse(jsonString)
            if (imported.components && imported.metadata) {
                hierarchyAdapter.components = imported.components
                hierarchyAdapter.metadata.version = imported.metadata.version || "1.0"
                hierarchyAdapter.metadata.created = imported.metadata.created || Qt.formatDateTime(new Date(), Qt.ISODate)
                hierarchyAdapter.metadata.lastModified = Qt.formatDateTime(new Date(), Qt.ISODate)
                hierarchyAdapter.metadata.quickshellVersion = imported.metadata.quickshellVersion || "1.0.0"
                
                console.log("[ConfigPersistence] Configuration imported successfully")
                return true
            } else {
                console.error("[ConfigPersistence] Invalid configuration format")
                return false
            }
        } catch (error) {
            console.error(`[ConfigPersistence] Error importing configuration: ${error}`)
            return false
        }
    }
    
    // Access to the FileView for advanced operations
    readonly property alias fileView: configFile
    readonly property alias adapter: hierarchyAdapter
    
    // Signals for external components
    signal configurationChanged()
    signal configurationSaved()
    signal configurationLoaded()
    
    // Initialize on creation (singletons don't use Component.onCompleted)
    property bool __initialized: {
        console.log("[ConfigPersistence] Initialized with FileView + JsonAdapter")
        console.log(`[ConfigPersistence] Config path: ${configFile.path}`)
        
        // Validate on startup
        validateHierarchy()
        return true
    }
}