import QtQuick
import "../../services"
import "../overlays"
import "../base"

Rectangle {
    id: ramMonitor
    
    // Entity ID for configuration
    property string entityId: "ramWidget"
    
    // GraphicalComponent interface implementation
    property string componentId: "ram"
    property string parentComponentId: "bar"
    property var childComponentIds: []
    property string menuPath: "ram"
    property string contextMenuPath: "../overlays/RamContextMenu.qml"
    
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
            item.configService = ramMonitor.configService
            item.systemMonitorService = ramMonitor.systemMonitorService
            
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
    property bool showFrequency: configService ? configService.getEntityProperty(entityId, "showFrequency", false) : false
    property bool showTotal: configService ? configService.getEntityProperty(entityId, "showTotal", true) : true
    property string displayMode: configService ? configService.getEntityProperty(entityId, "displayMode", "compact") : "compact"
    // Per-metric precision settings
    property int usagePrecision: configService ? configService.getEntityProperty(entityId, "usagePrecision", 0) : 0
    property int memoryPrecision: configService ? configService.getEntityProperty(entityId, "memoryPrecision", 1) : 1
    
    // Fixed width configuration
    property bool useFixedWidth: configService ? configService.getValue("ram.useFixedWidth", true) : true
    
    // Current RAM data - delegate to service
    property real ramUsed: RamService.usedBytes
    property real ramTotal: RamService.totalBytes
    property real ramUsagePercent: RamService.usagePercentage
    property string ramDisplay: RamService.usedDisplay + " / " + RamService.totalDisplay
    property string ramFrequencyDisplay: ""
    
    // Visual configuration
    implicitWidth: useFixedWidth ? getFixedWidth() : (contentRow.implicitWidth + (configService ? configService.spacing("sm", entityId) : 12))
    implicitHeight: configService ? configService.getWidgetHeight(entityId, contentRow.implicitHeight) : contentRow.implicitHeight
    radius: configService ? configService.getEntityStyle(entityId, "borderRadius", "auto", configService.scaled(4)) : 4
    
    // Calculate fixed width based on maximum possible content
    function getFixedWidth() {
        if (!configService) return 120
        
        // Base spacing and padding
        const spacing = configService.spacing("xs", entityId)
        const padding = configService.spacing("sm", entityId)
        const fontSize = configService.typography("xs", entityId)
        
        let maxWidth = 0
        
        // Icon width (if shown)
        if (showIcon) {
            maxWidth += fontSize + spacing
        }
        
        // Calculate maximum text width based on configuration
        let maxTextWidth = 0
        
        // Label width
        if (showLabel) {
            maxTextWidth += fontSize * 0.6 * 4 // "RAM " width estimate
        }
        
        // Maximum percentage: "100%" (4 chars)
        if (showPercentage) {
            const maxPercentageChars = usagePrecision > 0 ? 6 : 4 // "100.x%" or "100%"
            maxTextWidth += fontSize * 0.6 * maxPercentageChars
            if (showTotal) maxTextWidth += fontSize * 0.6 * 3 // " | "
        }
        
        // Memory display: "99.9/99.9 GB" (12 chars max)
        if (showTotal) {
            const maxMemoryChars = memoryPrecision > 0 ? 15 : 12 // "99.x/99.x GB" or "99/99 GB"
            maxTextWidth += fontSize * 0.6 * maxMemoryChars
        }
        
        if (showText && displayMode !== "minimal") {
            maxWidth += maxTextWidth
        }
        
        return Math.max(80, maxWidth + padding)
    }
    
    // Dynamic background color based on RAM usage
    color: {
        if (!configService) return "#313244"
        
        if (ramUsagePercent > 85) {
            return configService.getThemeProperty("colors", "error") || "#f38ba8"
        } else if (ramUsagePercent > 70) {
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
        
        // RAM icon
        Text {
            visible: showIcon
            anchors.verticalCenter: parent.verticalCenter
            text: "🧠"  // Memory/RAM icon
            color: {
                if (!configService) return "#cdd6f4"
                
                // Dynamic icon color based on usage
                if (ramUsagePercent > 85) {
                    return configService.getThemeProperty("colors", "background") || "#1e1e2e"
                } else {
                    return configService.getThemeProperty("colors", "text") || "#cdd6f4"
                }
            }
            font.family: "Inter"
            font.pixelSize: configService ? configService.typography("xs", entityId) : 9
        }
        
        // RAM usage text
        Text {
            visible: showText && displayMode !== "minimal"
            anchors.verticalCenter: parent.verticalCenter
            text: {
                let parts = []
                let labelText = showLabel ? "RAM " : ""
                
                if (labelText) parts.push(labelText.trim())
                
                let dataParts = []
                if (showPercentage) {
                    dataParts.push(ramUsagePercent.toFixed(usagePrecision) + "%")
                }
                if (showTotal) {
                    dataParts.push(ramUsed.toFixed(memoryPrecision) + "/" + ramTotal.toFixed(memoryPrecision) + " GB")
                } else if (!showPercentage) {
                    dataParts.push(ramUsed.toFixed(memoryPrecision) + " GB")
                }
                
                if (dataParts.length > 0) {
                    parts.push(dataParts.join(" | "))
                }
                
                if (showFrequency && ramFrequencyDisplay) {
                    parts.push(ramFrequencyDisplay)
                }
                
                return parts.join(" ")
            }
            color: {
                if (!configService) return "#cdd6f4"
                
                // Dynamic text color based on usage
                if (ramUsagePercent > 85) {
                    return configService.getThemeProperty("colors", "background") || "#1e1e2e"
                } else {
                    return configService.getThemeProperty("colors", "text") || "#cdd6f4"
                }
            }
            font.family: "Inter"
            font.pixelSize: configService ? configService.typography("xs", entityId) : 9
            font.weight: ramUsagePercent > 80 ? Font.DemiBold : Font.Medium
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
            
            if (ramUsagePercent > 85) {
                return configService.getThemeProperty("colors", "error") || "#f38ba8"
            } else if (ramUsagePercent > 70) {
                return configService.getThemeProperty("colors", "warning") || "#f9e2af"
            } else {
                return configService.getThemeProperty("colors", "primary") || "#89b4fa"
            }
        }
        
        // Animated width based on usage
        width: parent.width * (ramUsagePercent / 100)
        
        Behavior on width {
            NumberAnimation { duration: 400; easing.type: Easing.OutCubic }
        }
        
        Behavior on color {
            ColorAnimation { duration: 300; easing.type: Easing.OutCubic }
        }
    }
    
    
    // Bind RAM service to system monitor
    onSystemMonitorServiceChanged: {
        if (systemMonitorService) {
            RamService.bindToSystemMonitor(systemMonitorService)
        }
    }
    
    // GraphicalComponent interface methods
    function menu(anchorWindow, x, y, startPath) {
        console.log(`[${componentId}] Opening hierarchical menu`)
        
        // RAM uses parent's menu with its specific path
        const parent = get_parent()
        if (parent && typeof parent.menu === 'function') {
            parent.menu(anchorWindow, x, y, startPath || menuPath)
        }
    }
    
    function list_children() {
        return []
    }
    
    function get_parent() {
        return ComponentRegistry.getComponent(parentComponentId)
    }
    
    function get_child(id) {
        return null
    }
    
    function showContextMenu(x, y) {
        console.log(`[${componentId}] Opening dedicated context menu`)
        
        contextMenuLoader.active = true
        if (contextMenuLoader.item) {
            // Update live data before showing
            updateContextMenuData()
            
            const windowToUse = anchorWindow || ramMonitor
            const globalPos = ramMonitor.mapToItem(null, x || 0, y || 0)
            contextMenuLoader.item.show(windowToUse, globalPos.x, globalPos.y)
        }
    }
    
    function updateContextMenuData() {
        if (contextMenuLoader.item && typeof contextMenuLoader.item.updateData === 'function') {
            contextMenuLoader.item.updateData(ramUsed, ramTotal, ramUsagePercent, ramFrequencyDisplay)
        }
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
    
    
    // Update context menu when service data changes
    Connections {
        target: RamService
        function onUsagePercentageChanged() { updateContextMenuData() }
        function onUsedBytesChanged() { updateContextMenuData() }
        function onTotalBytesChanged() { updateContextMenuData() }
    }
    
    // Component registration
    function registerComponent() {
        ComponentRegistry.registerComponent(componentId, ramMonitor)
        console.log(`[${componentId}] Registered with hierarchy`)
    }

    Component.onCompleted: {
        // Register with ComponentRegistry
        registerComponent()
        
        // Initialize service binding if available
        if (systemMonitorService) {
            RamService.bindToSystemMonitor(systemMonitorService)
        }
        
        console.log("[RamMonitor] Initialized with RamService singleton")
    }
}