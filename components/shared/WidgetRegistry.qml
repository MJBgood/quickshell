pragma Singleton
import QtQuick
import Quickshell

Item {
    id: widgetRegistry
    
    // Logging category for this service
    LoggingCategory {
        id: logCategory
        name: "quickshell.widgets"
        defaultLogLevel: LoggingCategory.Info
    }
    
    // Registry state
    property bool initialized: false
    property var registeredWidgets: ({})
    property var widgetOrder: []
    
    // Services reference
    property var configService: null
    
    // Widget registration data structure
    /*
    Widget structure:
    {
        id: "cpu-monitor",
        name: "CPU Monitor", 
        description: "Shows CPU usage and temperature",
        category: "performance", // performance, system, media, etc.
        icon: "💻",
        defaultEnabled: true,
        component: "CpuMonitor",
        contextMenu: "CpuContextMenu",
        configKeys: ["cpu.enabled", "cpu.showGraph", "cpu.pollRate"],
        size: { width: 60, height: 24 }, // preferred size
        position: 100 // sort order
    }
    */
    
    // Widget categories for organization
    readonly property var categories: ({
        "performance": { name: "Performance", icon: "📊", order: 1 },
        "system": { name: "System", icon: "⚙️", order: 2 },
        "media": { name: "Media", icon: "🎵", order: 3 },
        "network": { name: "Network", icon: "🌐", order: 4 },
        "time": { name: "Time & Date", icon: "🕒", order: 5 },
        "workspace": { name: "Workspace", icon: "🏢", order: 6 },
        "power": { name: "Power", icon: "🔋", order: 7 }
    })
    
    // Signals
    signal widgetRegistered(string widgetId)
    signal widgetUnregistered(string widgetId)
    signal widgetEnabledChanged(string widgetId, bool enabled)
    signal registryChanged()
    
    /**
     * Register a widget with the system
     */
    function registerWidget(widgetData) {
        if (!widgetData.id || !widgetData.name || !widgetData.component) {
            console.warn(logCategory, "Invalid widget data - missing required fields:", JSON.stringify(widgetData))
            return false
        }
        
        // Set defaults
        const widget = {
            id: widgetData.id,
            name: widgetData.name,
            description: widgetData.description || "",
            category: widgetData.category || "system",
            icon: widgetData.icon || "🔧",
            defaultEnabled: widgetData.defaultEnabled !== undefined ? widgetData.defaultEnabled : true,
            component: widgetData.component,
            contextMenu: widgetData.contextMenu || null,
            configKeys: widgetData.configKeys || [],
            size: widgetData.size || { width: 60, height: 24 },
            position: widgetData.position || 1000
        }
        
        // Copy additional properties from widgetData
        for (let key in widgetData) {
            if (!widget.hasOwnProperty(key)) {
                widget[key] = widgetData[key]
            }
        }
        
        console.log(logCategory, `Registering widget: ${widget.id} (${widget.name})`)
        
        // Add to registry
        registeredWidgets[widget.id] = widget
        
        // Update order array
        updateWidgetOrder()
        
        widgetRegistered(widget.id)
        registryChanged()
        
        return true
    }
    
    /**
     * Unregister a widget
     */
    function unregisterWidget(widgetId) {
        if (!registeredWidgets[widgetId]) {
            console.warn(logCategory, "Cannot unregister non-existent widget:", widgetId)
            return false
        }
        
        console.log(logCategory, `Unregistering widget: ${widgetId}`)
        
        delete registeredWidgets[widgetId]
        updateWidgetOrder()
        
        widgetUnregistered(widgetId)
        registryChanged()
        
        return true
    }
    
    /**
     * Get widget data by ID
     */
    function getWidget(widgetId) {
        return registeredWidgets[widgetId] || null
    }
    
    /**
     * Get all registered widgets
     */
    function getAllWidgets() {
        return Object.values(registeredWidgets)
    }
    
    /**
     * Get widgets by category
     */
    function getWidgetsByCategory(category) {
        return Object.values(registeredWidgets).filter(widget => widget.category === category)
    }
    
    /**
     * Get enabled widgets in display order
     */
    function getEnabledWidgets() {
        return widgetOrder.filter(widgetId => isWidgetEnabled(widgetId))
                          .map(widgetId => registeredWidgets[widgetId])
    }
    
    /**
     * Get all widgets in display order (including disabled)
     */
    function getAllWidgetsOrdered() {
        return widgetOrder.map(widgetId => {
            const widget = registeredWidgets[widgetId]
            const result = {}
            
            // Copy all widget properties
            for (let key in widget) {
                result[key] = widget[key]
            }
            
            // Add enabled state
            result.enabled = isWidgetEnabled(widgetId)
            
            return result
        })
    }
    
    /**
     * Check if a widget is enabled
     */
    function isWidgetEnabled(widgetId) {
        const widget = registeredWidgets[widgetId]
        if (!widget) return false
        
        // Check primary enable key first
        const primaryKey = `${widgetId.replace('-', '.')}.enabled`
        if (configService && configService.hasValue && configService.hasValue(primaryKey)) {
            return configService.getValue(primaryKey, widget.defaultEnabled)
        }
        
        // Check any config keys
        if (widget.configKeys && widget.configKeys.length > 0 && configService) {
            const enableKey = widget.configKeys.find(key => key.endsWith('.enabled'))
            if (enableKey) {
                return configService.getValue(enableKey, widget.defaultEnabled)
            }
        }
        
        // Fallback to default
        return widget.defaultEnabled
    }
    
    /**
     * Enable/disable a widget
     */
    function setWidgetEnabled(widgetId, enabled) {
        const widget = registeredWidgets[widgetId]
        if (!widget) {
            console.warn(logCategory, "Cannot enable/disable non-existent widget:", widgetId)
            return false
        }
        
        console.log(logCategory, `${enabled ? 'Enabling' : 'Disabling'} widget: ${widgetId}`)
        
        // Set primary enable key
        const primaryKey = `${widgetId.replace('-', '.')}.enabled`
        if (configService) {
            configService.setValue(primaryKey, enabled)
            configService.saveConfig()
        }
        
        widgetEnabledChanged(widgetId, enabled)
        registryChanged()
        
        return true
    }
    
    /**
     * Toggle widget enabled state
     */
    function toggleWidget(widgetId) {
        const currentState = isWidgetEnabled(widgetId)
        return setWidgetEnabled(widgetId, !currentState)
    }
    
    /**
     * Update widget display order based on position and category
     */
    function updateWidgetOrder() {
        widgetOrder = Object.keys(registeredWidgets).sort((a, b) => {
            const widgetA = registeredWidgets[a]
            const widgetB = registeredWidgets[b]
            
            // Sort by category order first
            const categoryA = categories[widgetA.category] || { order: 999 }
            const categoryB = categories[widgetB.category] || { order: 999 }
            
            if (categoryA.order !== categoryB.order) {
                return categoryA.order - categoryB.order
            }
            
            // Then by position within category
            if (widgetA.position !== widgetB.position) {
                return widgetA.position - widgetB.position
            }
            
            // Finally by name
            return widgetA.name.localeCompare(widgetB.name)
        })
        
        console.log(logCategory, "Widget order updated:", widgetOrder)
    }
    
    /**
     * Get widget statistics
     */
    function getStats() {
        const total = Object.keys(registeredWidgets).length
        const enabled = Object.keys(registeredWidgets).filter(id => isWidgetEnabled(id)).length
        const categories = [...new Set(Object.values(registeredWidgets).map(w => w.category))]
        
        return {
            totalWidgets: total,
            enabledWidgets: enabled,
            disabledWidgets: total - enabled,
            categories: categories.length,
            categoryList: categories
        }
    }
    
    /**
     * Initialize the registry with default widgets
     */
    function initializeDefaultWidgets() {
        console.log(logCategory, "Initializing default widgets...")
        
        // Register core system widgets
        registerWidget({
            id: "cpu-monitor",
            name: "CPU Monitor",
            description: "Shows CPU usage and temperature",
            category: "performance",
            icon: "💻",
            component: "CpuMonitor",
            contextMenu: "CpuContextMenu",
            configKeys: ["cpu.enabled", "cpu.showGraph"],
            position: 10
        })
        
        registerWidget({
            id: "ram-monitor", 
            name: "RAM Monitor",
            description: "Shows memory usage",
            category: "performance",
            icon: "🧠",
            component: "RamMonitor",
            contextMenu: "RamContextMenu",
            configKeys: ["ram.enabled", "ram.showGraph"],
            position: 20
        })
        
        registerWidget({
            id: "storage-monitor",
            name: "Storage Monitor", 
            description: "Shows disk usage",
            category: "performance",
            icon: "💾",
            component: "StorageMonitor",
            contextMenu: "StorageContextMenu",
            configKeys: ["storage.enabled", "storage.showGraph"],
            position: 30
        })
        
        registerWidget({
            id: "clock",
            name: "Clock",
            description: "Shows current time and date",
            category: "time",
            icon: "🕒",
            component: "Clock",
            contextMenu: "ClockContextMenu",
            configKeys: ["clock.enabled", "clock.format"],
            position: 100
        })
        
        registerWidget({
            id: "workspaces",
            name: "Workspaces",
            description: "Shows and controls virtual workspaces",
            category: "workspace", 
            icon: "🏢",
            component: "Workspaces",
            contextMenu: "WorkspacesContextMenu",
            configKeys: ["workspaces.enabled", "workspaces.showNumbers"],
            position: 10
        })
        
        // Register additional widgets if services are available
        registerWidget({
            id: "audio-widget",
            name: "Audio Control",
            description: "Shows and controls audio volume",
            category: "media",
            icon: "🎵",
            component: "AudioWidget",
            contextMenu: "AudioContextMenu",
            configKeys: ["audio.enabled"],
            defaultEnabled: false,
            position: 10
        })
        
        registerWidget({
            id: "battery-widget",
            name: "Battery Status",
            description: "Shows battery level and status",
            category: "power",
            icon: "🔋",
            component: "BatteryWidget", 
            contextMenu: "BatteryContextMenu",
            configKeys: ["battery.enabled"],
            defaultEnabled: false,
            position: 10
        })
        
        registerWidget({
            id: "brightness-widget",
            name: "Brightness Control",
            description: "Controls screen brightness",
            category: "system",
            icon: "🔆",
            component: "BrightnessWidget",
            contextMenu: "BrightnessContextMenu", 
            configKeys: ["brightness.enabled"],
            defaultEnabled: false,
            position: 20
        })
        
        console.log(logCategory, `Initialized ${Object.keys(registeredWidgets).length} default widgets`)
    }
    
    Component.onCompleted: {
        console.log(logCategory, "WidgetRegistry initialized")
        
        // Initialize default widgets
        Qt.callLater(() => initializeDefaultWidgets())
        
        initialized = true
    }
}