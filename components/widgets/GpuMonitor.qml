import QtQuick
import "../../services"
import "../overlays"
import "../base"

Rectangle {
    id: gpuMonitor
    
    // Entity ID for configuration
    property string entityId: "gpuWidget"
    
    // GraphicalComponent interface implementation
    property string componentId: "gpu"
    property string parentComponentId: "bar"
    property var childComponentIds: []
    property string menuPath: "gpu"
    property string contextMenuPath: "../overlays/GpuContextMenu.qml"
    
    // Services
    property var systemMonitorService: null
    property var configService: ConfigService
    property var anchorWindow: null
    
    // Dedicated context menu loader - lazy loaded
    property alias contextMenuLoader: contextMenuLoader
    
    Loader {
        id: contextMenuLoader
        source: contextMenuPath
        active: false
        
        onLoaded: {
            item.configService = gpuMonitor.configService
            item.gpuService = GpuService
            
            item.closed.connect(function() {
                contextMenuLoader.active = false
            })
        }
    }
    
    // Display configuration
    property bool showIcon: configService ? configService.getEntityProperty(entityId, "showIcon", true) : true
    property bool showText: configService ? configService.getEntityProperty(entityId, "showText", true) : true
    property bool showPercentage: configService ? configService.getEntityProperty(entityId, "showPercentage", true) : true
    property bool showLabel: configService ? configService.getEntityProperty(entityId, "showLabel", true) : true
    property bool showMemory: configService ? configService.getEntityProperty(entityId, "showMemory", false) : false
    property bool showClocks: configService ? configService.getEntityProperty(entityId, "showClocks", false) : false
    property bool showTemperature: configService ? configService.getValue("gpu.showTemperature", false) : false
    property string displayMode: configService ? configService.getEntityProperty(entityId, "displayMode", "compact") : "compact"
    // Per-metric precision settings
    property int usagePrecision: configService ? configService.getEntityProperty(entityId, "usagePrecision", 1) : 1
    property int memoryPrecision: configService ? configService.getEntityProperty(entityId, "memoryPrecision", 1) : 1
    property int clockPrecision: configService ? configService.getEntityProperty(entityId, "clockPrecision", 0) : 0
    
    // Current GPU data - delegate to service
    property real gpuUsage: GpuService.usage
    property string gpuDisplay: GpuService.usage.toFixed(usagePrecision) + "%"
    property real memoryUsage: GpuService.memoryUsage
    property string memoryDisplay: (GpuService.memoryUsed / (1024 * 1024 * 1024)).toFixed(memoryPrecision) + "GB/" + (GpuService.memoryTotal / (1024 * 1024 * 1024)).toFixed(memoryPrecision) + "GB"
    property real clockSpeed: GpuService.clockSpeed
    property string clockDisplay: GpuService.clockSpeed > 0 ? GpuService.clockSpeed.toFixed(clockPrecision) + "MHz" : "--"
    property real temperature: GpuService.temperature
    property string temperatureDisplay: GpuService.temperature > 0 ? Math.round(GpuService.temperature) + "°C" : "--°C"
    property string gpuName: GpuService.gpuName
    property string vendor: GpuService.vendor
    
    // Visual configuration
    implicitWidth: contentRow.implicitWidth + (configService ? configService.spacing("sm", entityId) : 12)
    implicitHeight: configService ? configService.getWidgetHeight(entityId, contentRow.implicitHeight) : contentRow.implicitHeight
    radius: configService ? configService.getEntityStyle(entityId, "borderRadius", "auto", configService.scaled(4)) : 4
    
    // Dynamic background color based on GPU usage
    color: {
        if (!configService) return "#313244"
        
        if (gpuUsage > 80) {
            return configService.getThemeProperty("colors", "error") || "#f38ba8"
        } else if (gpuUsage > 60) {
            return configService.getThemeProperty("colors", "warning") || "#f9e2af"
        } else {
            return configService.getThemeProperty("colors", "surface") || "#313244"
        }
    }
    
    // Smooth color transitions
    Behavior on color {
        ColorAnimation { duration: 300; easing.type: Easing.OutCubic }
    }
    
    // Content layout
    Row {
        id: contentRow
        anchors.centerIn: parent
        spacing: configService ? configService.spacing("xs", entityId) : 4
        
        // GPU icon
        Text {
            visible: showIcon
            anchors.verticalCenter: parent.verticalCenter
            text: "🎮"  // Generic GPU icon
            color: {
                if (!configService) return "#cdd6f4"
                
                // Dynamic icon color based on background for proper contrast
                if (gpuUsage > 80) {
                    return configService.getThemeProperty("colors", "background") || "#1e1e2e"
                } else if (gpuUsage > 60) {
                    return configService.getThemeProperty("colors", "background") || "#1e1e2e"
                } else {
                    return configService.getThemeProperty("colors", "text") || "#cdd6f4"
                }
            }
            font.family: "Inter"
            font.pixelSize: configService ? configService.typography("xs", entityId) : 9
        }
        
        // GPU usage text
        Text {
            visible: showText && displayMode !== "minimal"
            anchors.verticalCenter: parent.verticalCenter
            text: {
                let parts = []
                let labelText = showLabel ? "GPU " : ""
                
                if (labelText) parts.push(labelText.trim())
                
                let dataParts = []
                if (showPercentage) {
                    dataParts.push(gpuUsage.toFixed(usagePrecision) + "%")
                } else {
                    dataParts.push(gpuUsage.toFixed(usagePrecision))
                }
                
                if (showMemory && memoryUsage > 0) {
                    dataParts.push(memoryDisplay)
                }
                
                if (showClocks && clockSpeed > 0) {
                    dataParts.push(clockDisplay)
                }
                
                if (showTemperature && temperature > 0) {
                    dataParts.push(temperatureDisplay)
                }
                
                if (dataParts.length > 0) {
                    parts.push(dataParts.join(" | "))
                }
                
                return parts.join(" ")
            }
            color: {
                if (!configService) return "#cdd6f4"
                
                // Dynamic text color based on background for proper contrast
                if (gpuUsage > 80) {
                    return configService.getThemeProperty("colors", "background") || "#1e1e2e"
                } else if (gpuUsage > 60) {
                    return configService.getThemeProperty("colors", "background") || "#1e1e2e"
                } else {
                    return configService.getThemeProperty("colors", "text") || "#cdd6f4"
                }
            }
            font.family: "Inter"
            font.pixelSize: configService ? configService.typography("sm", entityId) : 11
            font.weight: gpuUsage > 70 ? Font.DemiBold : Font.Medium
        }
    }
    
    // Usage bar indicator (for minimal mode)
    Rectangle {
        visible: displayMode === "minimal"
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        height: configService ? configService.scaled(2) : 2
        radius: configService ? configService.scaled(1) : 1
        
        color: {
            if (!configService) return "#89b4fa"
            
            if (gpuUsage > 80) {
                return configService.getThemeProperty("colors", "error") || "#f38ba8"
            } else if (gpuUsage > 60) {
                return configService.getThemeProperty("colors", "warning") || "#f9e2af"
            } else {
                return configService.getThemeProperty("colors", "primary") || "#89b4fa"
            }
        }
        
        // Animated width based on usage
        width: parent.width * (gpuUsage / 100)
        
        Behavior on width {
            NumberAnimation { duration: 400; easing.type: Easing.OutCubic }
        }
        
        Behavior on color {
            ColorAnimation { duration: 300; easing.type: Easing.OutCubic }
        }
    }
    
    // Smooth opacity transitions
    Behavior on opacity {
        NumberAnimation { duration: 150; easing.type: Easing.OutCubic }
    }
    
    // Right-click to show dedicated context menu
    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.RightButton
        z: 10  // Higher z-order to override bar's MouseArea
        
        onClicked: function(mouse) {
            if (mouse.button === Qt.RightButton) {
                // Stop event propagation
                mouse.accepted = true
                
                // Show dedicated context menu
                showContextMenu(mouse.x, mouse.y)
            }
        }
    }
    
    // GraphicalComponent interface methods
    function menu(anchorWindow, x, y, startPath) {
        console.log(`[${componentId}] Opening hierarchical menu at path: ${startPath || menuPath}`)
        
        // Use parent's menu with our specific path
        const parent = get_parent()
        if (parent && typeof parent.menu === 'function') {
            parent.menu(anchorWindow, x, y, startPath || menuPath)
        }
    }
    
    function showContextMenu(x, y) {
        console.log(`[${componentId}] Opening dedicated context menu`)
        
        contextMenuLoader.active = true
        if (contextMenuLoader.item) {
            // Update live data before showing
            updateContextMenuData()
            
            const windowToUse = anchorWindow || gpuMonitor
            const globalPos = gpuMonitor.mapToItem(null, x || 0, y || 0)
            contextMenuLoader.item.show(windowToUse, globalPos.x, globalPos.y)
        }
    }
    
    function updateContextMenuData() {
        if (contextMenuLoader.item && typeof contextMenuLoader.item.updateData === 'function') {
            contextMenuLoader.item.updateData(
                GpuService.usage,
                GpuService.memoryUsage,
                GpuService.clockSpeed,
                GpuService.temperature,
                GpuService.gpuName,
                GpuService.vendor,
                GpuService.memoryUsed,
                GpuService.memoryTotal
            )
        }
    }
    
    function list_children() {
        return []  // GPU monitor has no children
    }
    
    function get_parent() {
        if (!parentComponentId) return null
        return ComponentRegistry.getComponent(parentComponentId)
    }
    
    function get_child(id) {
        return null  // GPU monitor has no children
    }
    
    function registerComponent() {
        if (componentId) {
            ComponentRegistry.registerComponent(componentId, gpuMonitor)
            console.log(`[${componentId}] Registered component with hierarchy: parent=${parentComponentId}`)
        }
    }
    
    function unregisterComponent() {
        if (componentId) {
            ComponentRegistry.unregisterComponent(componentId)
            console.log(`[${componentId}] Unregistered component`)
        }
    }
    
    Component.onCompleted: {
        registerComponent()
        
        // Connect config service to GpuService if available
        if (configService && !GpuService.configService) {
            GpuService.configService = configService
        }
        
        console.log("[GpuMonitor] Initialized with GpuService singleton")
        console.log("[GpuMonitor] GPU vendor:", GpuService.vendor, "usage:", GpuService.usage + "%")
    }
    
    Component.onDestruction: {
        unregisterComponent()
    }
    
    // Update context menu when service data changes
    Connections {
        target: GpuService
        function onUsageChanged() { updateContextMenuData() }
        function onMemoryUsageChanged() { updateContextMenuData() }
        function onClockSpeedChanged() { updateContextMenuData() }
        function onTemperatureChanged() { updateContextMenuData() }
    }
}