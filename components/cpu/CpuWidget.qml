import QtQuick
import "../shared"
import "../shared"
import "../shared"

Rectangle {
    id: cpuMonitor
    
    // Entity ID for configuration
    property string entityId: "cpuWidget"
    
    // GraphicalComponent interface implementation
    property string componentId: "cpu"
    property string parentComponentId: "bar"
    property var childComponentIds: []
    property string menuPath: "cpu"
    property string contextMenuPath: "../overlays/CpuContextMenu.qml"
    
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
            item.configService = cpuMonitor.configService
            item.systemMonitorService = cpuMonitor.systemMonitorService
            item.temperatureService = TemperatureService
            
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
    property bool showTemperature: configService ? (configService.getValue("entities." + entityId + ".showTemperature", undefined) !== undefined ? configService.getEntityProperty(entityId, "showTemperature", false) : configService.getValue("cpu.showTemperature", false)) : false
    property string displayMode: configService ? configService.getEntityProperty(entityId, "displayMode", "compact") : "compact"
    // Per-metric precision settings
    property int usagePrecision: configService ? configService.getEntityProperty(entityId, "usagePrecision", 1) : 1
    property int temperaturePrecision: configService ? configService.getEntityProperty(entityId, "temperaturePrecision", 0) : 0
    property int frequencyPrecision: configService ? configService.getEntityProperty(entityId, "frequencyPrecision", 0) : 0
    
    // Current CPU data - delegate to service
    property real cpuUsage: CpuService.usage
    property string cpuDisplay: CpuService.usage.toFixed(usagePrecision) + "%"
    property string cpuFrequencyDisplay: CpuService.frequencyDisplay
    property var cpuCores: CpuService.cores
    
    // CPU temperature data - delegate to TemperatureService
    property real cpuTemp: TemperatureService.cpuTemp
    property string cpuTempDisplay: TemperatureService.cpuTemp > 0 ? TemperatureService.cpuTemp.toFixed(temperaturePrecision) + "°C" : "--"
    property string cpuTempStatus: TemperatureService.getCpuStatus()
    
    // Fixed width configuration  
    property bool useFixedWidth: configService ? configService.getValue("cpu.useFixedWidth", false) : false
    
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
            maxTextWidth += fontSize * 3.5 // "CPU " width estimate
        }
        
        // Maximum percentage: "100.0%" (7 chars) or "100%" (4 chars)
        if (showPercentage) {
            const maxPercentageChars = usagePrecision > 0 ? 6 : 4 // "100.x%" or "100%"
            maxTextWidth += fontSize * 0.6 * maxPercentageChars
            if (showFrequency || showTemperature) maxTextWidth += fontSize * 0.6 * 3 // " | "
        }
        
        // Frequency: "4.2GHz" (6 chars max)
        if (showFrequency) {
            maxTextWidth += fontSize * 0.6 * 6
            if (showTemperature) maxTextWidth += fontSize * 0.6 * 3 // " | "
        }
        
        // Temperature: "100°C" (5 chars max)
        if (showTemperature) {
            maxTextWidth += fontSize * 0.6 * 5
        }
        
        if (showText && displayMode !== "minimal") {
            maxWidth += maxTextWidth
        }
        
        return Math.max(80, maxWidth + padding)
    }
    
    // Dynamic background color based on CPU usage and temperature
    color: {
        if (!configService) return "#313244"
        
        // Temperature takes priority for critical alerts
        if (showTemperature && cpuTempStatus === "critical") {
            return configService.getThemeProperty("colors", "error") || "#f38ba8"
        } else if (showTemperature && cpuTempStatus === "hot") {
            return configService.getThemeProperty("colors", "warning") || "#f9e2af"
        } else if (cpuUsage > 80) {
            return configService.getThemeProperty("colors", "error") || "#f38ba8"
        } else if (cpuUsage > 60 || (showTemperature && cpuTempStatus === "warm")) {
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
        
        // CPU icon (simple emoji)
        Text {
            visible: showIcon
            text: "🖥️"
            font.pixelSize: configService ? configService.icon("xs", entityId) : 16
            anchors.verticalCenter: parent.verticalCenter
        }
        
        // CPU usage text
        Text {
            visible: showText && displayMode !== "minimal"
            anchors.verticalCenter: parent.verticalCenter
            text: {
                let parts = []
                let labelText = showLabel ? "CPU " : ""
                
                if (labelText) parts.push(labelText.trim())
                
                let dataParts = []
                if (showPercentage) {
                    dataParts.push(cpuUsage.toFixed(usagePrecision) + "%")
                } else {
                    dataParts.push(cpuUsage.toFixed(usagePrecision))
                }
                
                if (showFrequency && cpuFrequencyDisplay) {
                    dataParts.push(cpuFrequencyDisplay)
                }
                
                if (showTemperature && cpuTempDisplay !== "--") {
                    dataParts.push(cpuTempDisplay)
                }
                
                if (dataParts.length > 0) {
                    parts.push(dataParts.join(" | "))
                }
                
                return parts.join(" ")
            }
            color: {
                if (!configService) return "#cdd6f4"
                
                // Dynamic text color based on background for proper contrast
                if (showTemperature && cpuTempStatus === "critical") {
                    return configService.getThemeProperty("colors", "background") || "#1e1e2e"
                } else if (showTemperature && cpuTempStatus === "hot") {
                    return configService.getThemeProperty("colors", "background") || "#1e1e2e"
                } else if (cpuUsage > 80) {
                    return configService.getThemeProperty("colors", "background") || "#1e1e2e"
                } else if (cpuUsage > 60 || (showTemperature && cpuTempStatus === "warm")) {
                    return configService.getThemeProperty("colors", "background") || "#1e1e2e"
                } else {
                    return configService.getThemeProperty("colors", "text") || "#cdd6f4"
                }
            }
            font.family: "Inter"
            font.pixelSize: configService ? configService.typography("xs", entityId) : 9
            font.weight: cpuUsage > 70 ? Font.DemiBold : Font.Medium
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
            
            if (cpuUsage > 80) {
                return configService.getThemeProperty("colors", "error") || "#f38ba8"
            } else if (cpuUsage > 60) {
                return configService.getThemeProperty("colors", "warning") || "#f9e2af"
            } else {
                return configService.getThemeProperty("colors", "primary") || "#89b4fa"
            }
        }
        
        // Animated width based on usage
        width: parent.width * (cpuUsage / 100)
        
        Behavior on width {
            NumberAnimation { duration: 400; easing.type: Easing.OutCubic }
        }
        
        Behavior on color {
            ColorAnimation { duration: 300; easing.type: Easing.OutCubic }
        }
    }
    
    
    
    function getCpuIconColor() {
        if (!configService) return "#cdd6f4"
        
        // Dynamic icon color based on status and background for proper contrast
        if (showTemperature && cpuTempStatus === "critical") {
            return configService.getThemeProperty("colors", "background") || "#1e1e2e"
        } else if (showTemperature && cpuTempStatus === "hot") {
            return configService.getThemeProperty("colors", "background") || "#1e1e2e"
        } else if (cpuUsage > 80) {
            return configService.getThemeProperty("colors", "background") || "#1e1e2e"
        } else if (cpuUsage > 60 || (showTemperature && cpuTempStatus === "warm")) {
            return configService.getThemeProperty("colors", "background") || "#1e1e2e"
        } else {
            return configService.getThemeProperty("colors", "text") || "#cdd6f4"
        }
    }
    
    // Smooth opacity transitions
    Behavior on opacity {
        NumberAnimation { duration: 150; easing.type: Easing.OutCubic }
    }
    
    // Bind CPU service to system monitor
    onSystemMonitorServiceChanged: {
        if (systemMonitorService) {
            CpuService.bindToSystemMonitor(systemMonitorService)
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
            
            const windowToUse = anchorWindow || cpuMonitor
            const globalPos = cpuMonitor.mapToItem(null, x || 0, y || 0)
            contextMenuLoader.item.show(windowToUse, globalPos.x, globalPos.y)
        }
    }
    
    function updateContextMenuData() {
        if (contextMenuLoader.item && typeof contextMenuLoader.item.updateData === 'function') {
            contextMenuLoader.item.updateData(
                CpuService.usage, 
                CpuService.frequencyDisplay,
                TemperatureService.cpuTemp,
                TemperatureService.getCpuStatus()
            )
        }
    }
    
    function list_children() {
        return []  // CPU monitor has no children
    }
    
    function get_parent() {
        if (!parentComponentId) return null
        return ComponentRegistry.getComponent(parentComponentId)
    }
    
    function get_child(id) {
        return null  // CPU monitor has no children
    }
    
    function registerComponent() {
        if (componentId) {
            ComponentRegistry.registerComponent(componentId, cpuMonitor)
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
        
        // Initialize service binding if available
        if (systemMonitorService) {
            CpuService.bindToSystemMonitor(systemMonitorService)
        }
        
        console.log("[CpuMonitor] Initialized with CpuService singleton")
        console.log("[CpuMonitor] showTemperature:", showTemperature, "cpuTemp:", TemperatureService.cpuTemp, "cpuTempDisplay:", cpuTempDisplay)
    }
    
    Component.onDestruction: {
        unregisterComponent()
    }
    
    // Update context menu when service data changes
    Connections {
        target: CpuService
        function onUsageChanged() { updateContextMenuData() }
        function onFrequencyDisplayChanged() { updateContextMenuData() }
    }
}