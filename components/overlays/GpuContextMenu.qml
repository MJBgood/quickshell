import Quickshell
import Quickshell.Hyprland
import QtQuick
import QtQuick.Controls
import "../base"

PopupWindow {
    id: gpuMenu
    
    // Window properties
    implicitWidth: 350
    implicitHeight: Math.min(450, menuContent.contentHeight + 32)
    visible: false
    color: "transparent"
    
    // Services
    property var configService: ConfigService
    property var gpuService: null
    
    // Component hierarchy properties
    property string componentId: "gpu"
    property string parentComponentId: "bar" 
    property var childComponentIds: []
    
    // Live data properties for preview
    property real currentUsage: 0.0
    property real currentMemoryUsage: 0.0
    property real currentMemoryUsed: 0.0
    property real currentMemoryTotal: 0.0
    property real currentClockSpeed: 0.0
    property real currentTemperature: 0.0
    property string currentGpuName: "Unknown"
    property string currentVendor: "unknown"
    
    // Signals
    signal closed()
    
    // Anchor configuration
    anchor {
        window: null
        rect {
            x: 0
            y: 0
            width: 1
            height: 1
        }
        edges: Edges.Top | Edges.Left
        gravity: Edges.Bottom | Edges.Right
        adjustment: PopupAdjustment.All
        margins {
            left: 8
            right: 8
            top: 8
            bottom: 8
        }
    }
    
    // Focus grab for dismissing when clicking outside
    HyprlandFocusGrab {
        id: focusGrab
        windows: [gpuMenu]
        onCleared: hide()
    }
    
    // Main container
    Rectangle {
        id: menuContent
        anchors.fill: parent
        color: configService ? configService.getThemeProperty("colors", "surface") || "#313244" : "#313244"
        border.color: configService ? configService.getThemeProperty("colors", "border") || "#585b70" : "#585b70"
        border.width: 1
        radius: 12
        
        property real contentHeight: scrollView.contentHeight
        
        ScrollView {
            id: scrollView
            anchors.fill: parent
            anchors.margins: 16
            clip: true
            
            Component.onCompleted: {
                ScrollBar.horizontal.policy = ScrollBar.AlwaysOff
                ScrollBar.vertical.policy = ScrollBar.AsNeeded
            }
            
            // Custom scrollbar styling
            ScrollBar.vertical: ScrollBar {
                active: true
                policy: ScrollBar.AsNeeded
                size: 0.3
                width: 8
                
                background: Rectangle {
                    color: "transparent"
                    radius: 4
                }
                
                contentItem: Rectangle {
                    color: configService ? configService.getThemeProperty("colors", "border") || "#585b70" : "#585b70"
                    radius: 4
                    opacity: 0.6
                }
            }
            
            Column {
                width: Math.max(parent.width - 16, 300)
                spacing: 12
                
                // Navigation Header
                Row {
                    width: parent.width
                    height: 32
                    spacing: 8
                    
                    // Parent navigation button
                    Rectangle {
                        width: 28
                        height: 28
                        radius: 6
                        visible: parentComponentId !== ""
                        color: parentNavMouse.containsMouse ? 
                               (configService ? configService.getThemeProperty("colors", "accent") || "#a6e3a1" : "#a6e3a1") : 
                               "transparent"
                        border.width: 1
                        border.color: configService ? configService.getThemeProperty("colors", "accent") || "#a6e3a1" : "#a6e3a1"
                        
                        Text {
                            anchors.centerIn: parent
                            text: "↑"
                            color: configService ? configService.getThemeProperty("colors", "text") || "#cdd6f4" : "#cdd6f4"
                            font.pixelSize: 12
                            font.weight: Font.Bold
                        }
                        
                        MouseArea {
                            id: parentNavMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: navigateToParent()
                        }
                    }
                    
                    // Header content
                    Item {
                        width: parent.width - (parentComponentId !== "" ? 36 : 0) - 32 // Account for nav button and close button
                        height: 32
                        
                        Text {
                            id: iconText
                            text: "🎮"  // Generic GPU icon
                            font.pixelSize: 20
                            anchors.left: parent.left
                            anchors.verticalCenter: parent.verticalCenter
                        }
                        
                        Column {
                            anchors.left: iconText.right
                            anchors.leftMargin: 12
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            
                            Text {
                                text: "GPU Monitor"
                                font.pixelSize: 14
                                font.weight: Font.DemiBold
                                color: configService ? configService.getThemeProperty("colors", "text") || "#cdd6f4" : "#cdd6f4"
                            }
                            
                            Text {
                                text: getConfigValue("enabled", true) ? "Enabled" : "Disabled"
                                font.pixelSize: 10
                                color: getConfigValue("enabled", true) ? "#a6e3a1" : "#f38ba8"
                            }
                        }
                    }
                    
                    // Close button
                    Rectangle {
                        id: closeButton
                        width: 24
                        height: 24
                        radius: 12
                        color: closeArea.containsMouse ? "#f38ba8" : "transparent"
                        
                        Text {
                            anchors.centerIn: parent
                            text: "✕"
                            color: closeArea.containsMouse ? "#1e1e2e" : (configService ? configService.getThemeProperty("colors", "textAlt") || "#bac2de" : "#bac2de")
                            font.pixelSize: 12
                            font.weight: Font.Bold
                        }
                        
                        MouseArea {
                            id: closeArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: hide()
                        }
                        
                        Behavior on color {
                            ColorAnimation { duration: 150 }
                        }
                    }
                }
                
                // GPU Info Section
                Rectangle {
                    width: parent.width
                    height: gpuInfoColumn.implicitHeight + 16
                    color: configService ? configService.getThemeProperty("colors", "surfaceAlt") || "#45475a" : "#45475a"
                    radius: 8
                    border.width: 1
                    border.color: configService ? configService.getThemeProperty("colors", "border") || "#585b70" : "#585b70"
                    
                    Column {
                        id: gpuInfoColumn
                        anchors.centerIn: parent
                        width: parent.width - 16
                        spacing: 4
                        
                        Text {
                            width: parent.width
                            text: "GPU: " + (currentGpuName || "Unknown")
                            font.family: "Inter"
                            font.pixelSize: 11
                            font.weight: Font.Medium
                            color: configService ? configService.getThemeProperty("colors", "text") || "#cdd6f4" : "#cdd6f4"
                            wrapMode: Text.Wrap
                        }
                        
                        Text {
                            width: parent.width
                            text: "Vendor: " + (currentVendor || "Unknown").toUpperCase()
                            font.family: "Inter"
                            font.pixelSize: 11
                            color: configService ? configService.getThemeProperty("colors", "textAlt") || "#bac2de" : "#bac2de"
                        }
                        
                        Row {
                            width: parent.width
                            spacing: 16
                            
                            Text {
                                text: "Usage: " + currentUsage.toFixed(1) + "%"
                                font.family: "Inter"
                                font.pixelSize: 11
                                color: {
                                    if (currentUsage > 80) return "#f38ba8"
                                    if (currentUsage > 60) return "#f9e2af"
                                    return "#a6e3a1"
                                }
                            }
                            
                            Text {
                                text: "Memory: " + (currentMemoryUsed / (1024 * 1024 * 1024)).toFixed(1) + "GB/" + (currentMemoryTotal / (1024 * 1024 * 1024)).toFixed(1) + "GB (" + currentMemoryUsage.toFixed(1) + "%)"
                                font.family: "Inter"
                                font.pixelSize: 11
                                color: {
                                    if (currentMemoryUsage > 80) return "#f38ba8"
                                    if (currentMemoryUsage > 60) return "#f9e2af"
                                    return "#a6e3a1"
                                }
                            }
                        }
                    }
                }
                
                // Separator
                Rectangle {
                    width: parent.width
                    height: 1
                    color: configService ? configService.getThemeProperty("colors", "border") || "#585b70" : "#585b70"
                }
                
                // General Configuration
                Column {
                    width: parent.width
                    spacing: 8
                    
                    Text {
                        text: "General Settings"
                        font.pixelSize: 12
                        font.weight: Font.DemiBold
                        color: configService ? configService.getThemeProperty("colors", "text") || "#cdd6f4" : "#cdd6f4"
                    }
                    
                    // Enable/Disable toggle
                    ConfigToggleItem {
                        width: parent.width
                        label: "Monitor"
                        value: getConfigValue("enabled", true) ? "Enabled" : "Disabled"
                        isActive: getConfigValue("enabled", true)
                        onClicked: toggleConfig("enabled")
                    }
                    
                    // Icon toggle
                    ConfigToggleItem {
                        width: parent.width
                        label: "Icon"
                        value: getConfigValue("showIcon", true) ? "🎮" : "Hidden"
                        isActive: getConfigValue("showIcon", true)
                        onClicked: toggleConfig("showIcon")
                    }
                    
                    // Label toggle
                    ConfigToggleItem {
                        width: parent.width
                        label: "Label"
                        value: getConfigValue("showLabel", false) ? "\"GPU\"" : "Hidden"
                        isActive: getConfigValue("showLabel", false)
                        onClicked: toggleConfig("showLabel")
                    }
                    
                    // Precision
                    ConfigToggleItem {
                        width: parent.width
                        label: "Precision"
                        value: getConfigValue("precision", 1) + " decimal" + (getConfigValue("precision", 1) === 1 ? "" : "s")
                        isActive: true
                        onClicked: cyclePrecision()
                    }
                    
                    // Polling Rate Control
                    GpuPollingRateControl {
                        width: parent.width
                        gpuService: gpuMenu.gpuService
                        configService: gpuMenu.configService
                    }
                }
                
                // Separator
                Rectangle {
                    width: parent.width
                    height: 1
                    color: configService ? configService.getThemeProperty("colors", "border") || "#585b70" : "#585b70"
                }
                
                // GPU Processor Section
                Column {
                    width: parent.width
                    spacing: 8
                    
                    Text {
                        text: "GPU Processor"
                        font.pixelSize: 12
                        font.weight: Font.DemiBold
                        color: configService ? configService.getThemeProperty("colors", "text") || "#cdd6f4" : "#cdd6f4"
                    }
                    
                    // GPU Usage percentage
                    ConfigToggleItem {
                        width: parent.width
                        label: "Usage %"
                        value: getConfigValue("showPercentage", true) ? (currentUsage.toFixed(getConfigValue("precision", 1)) + "%") : "Hidden"
                        isActive: getConfigValue("showPercentage", true)
                        onClicked: toggleConfig("showPercentage")
                    }
                    
                    // GPU Core Clock
                    ConfigToggleItem {
                        width: parent.width
                        label: "Core Clock"
                        value: getConfigValue("showClocks", false) ? (currentClockSpeed > 0 ? currentClockSpeed.toFixed(0) + "MHz" : "N/A") : "Hidden"
                        isActive: getConfigValue("showClocks", false)
                        onClicked: toggleConfig("showClocks")
                    }
                    
                    // GPU Temperature
                    ConfigToggleItem {
                        width: parent.width
                        label: "Temperature"
                        value: getConfigValue("showTemperature", false) ? "39°C" : "Hidden"
                        isActive: getConfigValue("showTemperature", false)
                        onClicked: toggleConfig("showTemperature")
                    }
                    
                    // GPU Voltage
                    ConfigToggleItem {
                        width: parent.width
                        label: "Voltage"
                        value: getConfigValue("showVoltage", false) ? "1237mV" : "Hidden"
                        isActive: getConfigValue("showVoltage", false)
                        onClicked: toggleConfig("showVoltage")
                    }
                    
                    // GPU Power
                    ConfigToggleItem {
                        width: parent.width
                        label: "Power"
                        value: getConfigValue("showPower", false) ? "15W" : "Hidden"
                        isActive: getConfigValue("showPower", false)
                        onClicked: toggleConfig("showPower")
                    }
                }
                
                // Separator
                Rectangle {
                    width: parent.width
                    height: 1
                    color: configService ? configService.getThemeProperty("colors", "border") || "#585b70" : "#585b70"
                }
                
                // VRAM Section
                Column {
                    width: parent.width
                    spacing: 8
                    
                    Text {
                        text: "VRAM (Memory)"
                        font.pixelSize: 12
                        font.weight: Font.DemiBold
                        color: configService ? configService.getThemeProperty("colors", "text") || "#cdd6f4" : "#cdd6f4"
                    }
                    
                    // VRAM Usage in GB
                    ConfigToggleItem {
                        width: parent.width
                        label: "Usage (GB)"
                        value: getConfigValue("showMemory", false) ? ((currentMemoryUsed / (1024 * 1024 * 1024)).toFixed(1) + "GB/" + (currentMemoryTotal / (1024 * 1024 * 1024)).toFixed(1) + "GB") : "Hidden"
                        isActive: getConfigValue("showMemory", false)
                        onClicked: toggleConfig("showMemory")
                    }
                    
                    // VRAM Usage percentage
                    ConfigToggleItem {
                        width: parent.width
                        label: "Usage %"
                        value: getConfigValue("showMemoryPercent", false) ? (currentMemoryUsage.toFixed(1) + "%") : "Hidden"
                        isActive: getConfigValue("showMemoryPercent", false)
                        onClicked: toggleConfig("showMemoryPercent")
                    }
                    
                    // VRAM Clock
                    ConfigToggleItem {
                        width: parent.width
                        label: "Memory Clock"
                        value: getConfigValue("showMemoryClock", false) ? "1333MHz" : "Hidden"
                        isActive: getConfigValue("showMemoryClock", false)
                        onClicked: toggleConfig("showMemoryClock")
                    }
                }
                
                // Separator
                Rectangle {
                    width: parent.width
                    height: 1
                    color: configService ? configService.getThemeProperty("colors", "border") || "#585b70" : "#585b70"
                }
                
                // Live preview
                Column {
                    width: parent.width
                    spacing: 4
                    
                    Text {
                        text: "Current Display:"
                        font.pixelSize: 10
                        font.weight: Font.DemiBold
                        color: configService ? configService.getThemeProperty("colors", "textAlt") || "#bac2de" : "#bac2de"
                    }
                    
                    Rectangle {
                        width: parent.width
                        height: previewText.implicitHeight + 8
                        color: configService ? configService.getThemeProperty("colors", "surfaceAlt") || "#45475a" : "#45475a"
                        radius: 6
                        
                        Text {
                            id: previewText
                            anchors.centerIn: parent
                            text: generateDisplayPreview()
                            font.pixelSize: 11
                            font.family: "monospace"
                            color: configService ? configService.getThemeProperty("colors", "text") || "#cdd6f4" : "#cdd6f4"
                        }
                    }
                }
            }
        }
    }
    
    // ConfigToggleItem Component
    component ConfigToggleItem: Rectangle {
        property string label: ""
        property string value: ""
        property bool isActive: false
        signal clicked()
        
        height: 24
        radius: 4
        color: toggleMouse.containsMouse ? 
               (configService ? configService.getThemeProperty("colors", "surfaceAlt") || "#45475a" : "#45475a") : 
               "transparent"
        
        Row {
            anchors.left: parent.left
            anchors.leftMargin: 8
            anchors.verticalCenter: parent.verticalCenter
            spacing: 8
            
            Text {
                text: label + ":"
                font.pixelSize: 10
                color: configService ? configService.getThemeProperty("colors", "text") || "#cdd6f4" : "#cdd6f4"
                anchors.verticalCenter: parent.verticalCenter
            }
            
            Text {
                text: value
                font.pixelSize: 10
                font.weight: Font.Medium
                color: isActive ? "#a6e3a1" : "#f38ba8"
                anchors.verticalCenter: parent.verticalCenter
            }
        }
        
        MouseArea {
            id: toggleMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: parent.clicked()
        }
        
        Behavior on color {
            ColorAnimation { duration: 150 }
        }
    }
    
    // GpuPollingRateControl Component
    component GpuPollingRateControl: Column {
        property var gpuService: null
        property var configService: null
        
        width: parent.width
        spacing: 8
        
        Text {
            text: "GPU Polling Rate"
            font.pixelSize: 12
            font.weight: Font.DemiBold
            color: configService ? configService.getThemeProperty("colors", "text") || "#cdd6f4" : "#cdd6f4"
        }
        
        Row {
            width: parent.width
            spacing: 8
            
            Repeater {
                model: [0.5, 1.0, 2.0, 5.0]
                
                Rectangle {
                    width: 45
                    height: 24
                    radius: 4
                    color: {
                        const isSelected = gpuService && Math.abs(gpuService.getPollingRate() - modelData) < 0.01
                        if (isSelected) {
                            return configService ? configService.getThemeProperty("colors", "accent") || "#a6e3a1" : "#a6e3a1"
                        }
                        return rateMouse.containsMouse ? 
                               (configService ? configService.getThemeProperty("colors", "surfaceAlt") || "#45475a" : "#45475a") : 
                               "transparent"
                    }
                    border.width: 1
                    border.color: configService ? configService.getThemeProperty("colors", "border") || "#585b70" : "#585b70"
                    
                    Text {
                        anchors.centerIn: parent
                        text: modelData + "s"
                        font.pixelSize: 9
                        color: {
                            const isSelected = gpuService && Math.abs(gpuService.getPollingRate() - modelData) < 0.01
                            if (isSelected) {
                                return configService ? configService.getThemeProperty("colors", "background") || "#1e1e2e" : "#1e1e2e"
                            }
                            return configService ? configService.getThemeProperty("colors", "text") || "#cdd6f4" : "#cdd6f4"
                        }
                    }
                    
                    MouseArea {
                        id: rateMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (gpuService) {
                                gpuService.setPollingRate(modelData)
                            }
                        }
                    }
                    
                    Behavior on color {
                        ColorAnimation { duration: 150 }
                    }
                }
            }
        }
    }
    
    // Helper functions
    function getConfigValue(key, defaultValue) {
        if (!configService) return defaultValue
        return configService.getValue("gpu." + key, defaultValue)
    }
    
    function toggleConfig(key) {
        if (!configService) return
        
        const configKey = "gpu." + key
        const currentValue = configService.getValue(configKey, key === "showLabel" ? false : true)
        const newValue = !currentValue
        
        configService.setValue(configKey, newValue)
        configService.saveConfig()
    }
    
    function cyclePrecision() {
        if (!configService) return
        
        const configKey = "gpu.precision"
        const currentPrecision = configService.getValue(configKey, 1)
        const newPrecision = (currentPrecision + 1) % 4
        
        configService.setValue(configKey, newPrecision)
        configService.saveConfig()
    }
    
    function generateDisplayPreview() {
        let parts = []
        
        if (getConfigValue("showIcon", true)) {
            parts.push("🎮")  // Generic GPU icon
        }
        if (getConfigValue("showLabel", false)) parts.push("GPU")
        
        let gpuParts = []
        if (getConfigValue("showPercentage", true)) {
            gpuParts.push(currentUsage.toFixed(getConfigValue("precision", 1)) + "%")
        } else {
            gpuParts.push(currentUsage.toFixed(getConfigValue("precision", 1)))
        }
        if (getConfigValue("showMemory", false) && currentMemoryTotal > 0) {
            const memoryUsedGB = (currentMemoryUsed / (1024 * 1024 * 1024)).toFixed(1)
            const memoryTotalGB = (currentMemoryTotal / (1024 * 1024 * 1024)).toFixed(1)
            gpuParts.push(memoryUsedGB + "GB/" + memoryTotalGB + "GB")
        }
        if (getConfigValue("showClocks", false) && currentClockSpeed > 0) {
            gpuParts.push(currentClockSpeed.toFixed(0) + "MHz")
        }
        if (gpuParts.length > 0) {
            parts.push(gpuParts.join(" | "))
        }
        
        return parts.length > 0 ? parts.join(" ") : "No display configured"
    }
    
    function show(anchorWindow, x, y) {
        if (anchorWindow) {
            anchor.window = anchorWindow
            
            const screenWidth = anchorWindow.screen ? anchorWindow.screen.width : 1920
            const screenHeight = anchorWindow.screen ? anchorWindow.screen.height : 1080
            
            let popupX = Math.min(x || 0, screenWidth - implicitWidth - 20)
            let popupY = Math.min(y || 0, screenHeight - implicitHeight - 20)
            
            popupX = Math.max(20, popupX)
            popupY = Math.max(20, popupY)
            
            anchor.rect.x = popupX
            anchor.rect.y = popupY
            anchor.rect.width = 1
            anchor.rect.height = 1
        }
        
        visible = true
        focusGrab.active = true
    }
    
    function hide() {
        visible = false
        focusGrab.active = false
        closed()
    }
    
    // Update live data
    function updateData(usage, memoryUsage, clockSpeed, temperature, gpuName, vendor, memoryUsed, memoryTotal) {
        currentUsage = usage || 0.0
        currentMemoryUsage = memoryUsage || 0.0
        currentMemoryUsed = memoryUsed || 0.0
        currentMemoryTotal = memoryTotal || 0.0
        currentClockSpeed = clockSpeed || 0.0
        currentTemperature = temperature || 0.0
        currentGpuName = gpuName || "Unknown"
        currentVendor = vendor || "unknown"
    }
    
    // Navigation functions
    function navigateToParent() {
        if (!parentComponentId) return
        
        const parentComponent = ComponentRegistry.getComponent(parentComponentId)
        if (parentComponent && typeof parentComponent.menu === 'function') {
            console.log(`[GpuContextMenu] Navigating to parent: ${parentComponentId}`)
            
            // Hide this menu first
            hide()
            
            // Show parent menu at the same position
            const currentAnchor = anchor
            parentComponent.menu(currentAnchor.window, currentAnchor.rect.x, currentAnchor.rect.y)
        } else {
            console.warn(`[GpuContextMenu] Parent component ${parentComponentId} not found or doesn't support menu()`)
        }
    }
    
    function navigateToChild(childId) {
        if (!childComponentIds.includes(childId)) return
        
        const childComponent = ComponentRegistry.getComponent(childId)
        if (childComponent && typeof childComponent.menu === 'function') {
            console.log(`[GpuContextMenu] Navigating to child: ${childId}`)
            
            // Hide this menu first
            hide()
            
            // Show child menu at the same position
            const currentAnchor = anchor
            childComponent.menu(currentAnchor.window, currentAnchor.rect.x, currentAnchor.rect.y)
        } else {
            console.warn(`[GpuContextMenu] Child component ${childId} not found or doesn't support menu()`)
        }
    }
}