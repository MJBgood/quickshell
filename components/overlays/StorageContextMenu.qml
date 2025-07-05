import Quickshell
import Quickshell.Hyprland
import QtQuick
import QtQuick.Controls

PopupWindow {
    id: storageMenu
    
    // Window properties
    implicitWidth: 320
    implicitHeight: Math.min(400, menuContent.contentHeight + 32)
    visible: false
    color: "transparent"
    
    // Services
    property var configService: null
    property var themeService: null
    property var systemMonitorService: null
    
    // Component hierarchy properties
    property string componentId: "storage"
    property string parentComponentId: "bar"
    property var childComponentIds: []
    
    // Live data properties for preview
    property real currentUsage: 0.0
    property real totalAvailable: 0.0
    property real usagePercent: 0.0
    
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
        windows: [storageMenu]
        onCleared: hide()
    }
    
    // Main container
    Rectangle {
        id: menuContent
        anchors.fill: parent
        color: themeService ? themeService.getThemeProperty("colors", "surface") || "#313244" : "#313244"
        border.color: themeService ? themeService.getThemeProperty("colors", "border") || "#585b70" : "#585b70"
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
                    color: themeService ? themeService.getThemeProperty("colors", "border") || "#585b70" : "#585b70"
                    radius: 4
                    opacity: 0.6
                }
            }
            
            Column {
                width: Math.max(parent.width - 16, 280)
                spacing: 12
                
                // Header
                Item {
                    width: parent.width
                    height: 32
                    
                    Text {
                        id: iconText
                        text: "💾"
                        font.pixelSize: 20
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                    }
                    
                    Column {
                        anchors.left: iconText.right
                        anchors.leftMargin: 12
                        anchors.right: closeButton.left
                        anchors.rightMargin: 12
                        anchors.verticalCenter: parent.verticalCenter
                        
                        Text {
                            text: "Storage Monitor"
                            font.pixelSize: 14
                            font.weight: Font.DemiBold
                            color: themeService ? themeService.getThemeProperty("colors", "text") || "#cdd6f4" : "#cdd6f4"
                        }
                        
                        Text {
                            text: getConfigValue("enabled", true) ? "Enabled" : "Disabled"
                            font.pixelSize: 10
                            color: getConfigValue("enabled", true) ? "#a6e3a1" : "#f38ba8"
                        }
                    }
                    
                    // Close button
                    Rectangle {
                        id: closeButton
                        width: 24
                        height: 24
                        radius: 12
                        color: closeArea.containsMouse ? "#f38ba8" : "transparent"
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        
                        Text {
                            anchors.centerIn: parent
                            text: "✕"
                            color: closeArea.containsMouse ? "#1e1e2e" : (themeService ? themeService.getThemeProperty("colors", "textAlt") || "#bac2de" : "#bac2de")
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
                
                // Separator
                Rectangle {
                    width: parent.width
                    height: 1
                    color: themeService ? themeService.getThemeProperty("colors", "border") || "#585b70" : "#585b70"
                }
                
                // Interactive configuration options
                Column {
                    width: parent.width
                    spacing: 8
                    
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
                        value: getConfigValue("showIcon", true) ? "💾" : "Hidden"
                        isActive: getConfigValue("showIcon", true)
                        onClicked: toggleConfig("showIcon")
                    }
                    
                    // Label toggle
                    ConfigToggleItem {
                        width: parent.width
                        label: "Label"
                        value: getConfigValue("showLabel", false) ? "\"Storage\"" : "Hidden"
                        isActive: getConfigValue("showLabel", false)
                        onClicked: toggleConfig("showLabel")
                    }
                    
                    // Percentage toggle
                    ConfigToggleItem {
                        width: parent.width
                        label: "Percentage"
                        value: getConfigValue("showPercentage", true) ? (usagePercent.toFixed(getConfigValue("precision", 0)) + "%") : "Hidden"
                        isActive: getConfigValue("showPercentage", true)
                        onClicked: toggleConfig("showPercentage")
                    }
                    
                    // Bytes format toggle
                    ConfigToggleItem {
                        width: parent.width
                        label: "Bytes Format"
                        value: getConfigValue("showBytes", false) ? (currentUsage.toFixed(1) + "/" + totalAvailable.toFixed(1) + " GB") : "Hidden"
                        isActive: getConfigValue("showBytes", false)
                        onClicked: toggleConfig("showBytes")
                    }
                    
                    // Precision
                    ConfigToggleItem {
                        width: parent.width
                        label: "Precision"
                        value: getConfigValue("precision", 0) + " decimal" + (getConfigValue("precision", 0) === 1 ? "" : "s")
                        isActive: true
                        onClicked: cyclePrecision()
                    }
                    
                    // Polling Rate Control
                    PollingRateControl {
                        width: parent.width
                        monitorType: "storage"
                        systemMonitorService: storageMenu.systemMonitorService
                        themeService: storageMenu.themeService
                    }
                }
                
                // Separator
                Rectangle {
                    width: parent.width
                    height: 1
                    color: themeService ? themeService.getThemeProperty("colors", "border") || "#585b70" : "#585b70"
                }
                
                // Live preview
                Column {
                    width: parent.width
                    spacing: 4
                    
                    Text {
                        text: "Current Display:"
                        font.pixelSize: 10
                        font.weight: Font.DemiBold
                        color: themeService ? themeService.getThemeProperty("colors", "textAlt") || "#bac2de" : "#bac2de"
                    }
                    
                    Rectangle {
                        width: parent.width
                        height: previewText.implicitHeight + 8
                        color: themeService ? themeService.getThemeProperty("colors", "surfaceAlt") || "#45475a" : "#45475a"
                        radius: 6
                        
                        Text {
                            id: previewText
                            anchors.centerIn: parent
                            text: generateDisplayPreview()
                            font.pixelSize: 11
                            font.family: "monospace"
                            color: themeService ? themeService.getThemeProperty("colors", "text") || "#cdd6f4" : "#cdd6f4"
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
               (themeService ? themeService.getThemeProperty("colors", "surfaceAlt") || "#45475a" : "#45475a") : 
               "transparent"
        
        Row {
            anchors.left: parent.left
            anchors.leftMargin: 8
            anchors.verticalCenter: parent.verticalCenter
            spacing: 8
            
            Text {
                text: label + ":"
                font.pixelSize: 10
                color: themeService ? themeService.getThemeProperty("colors", "text") || "#cdd6f4" : "#cdd6f4"
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
    
    // Helper functions
    function getConfigValue(key, defaultValue) {
        if (!configService) return defaultValue
        return configService.getValue("storage." + key, defaultValue)
    }
    
    function toggleConfig(key) {
        if (!configService) return
        
        const configKey = "storage." + key
        const currentValue = configService.getValue(configKey, key === "showLabel" ? false : true)
        const newValue = !currentValue
        
        configService.setValue(configKey, newValue)
        configService.saveConfig()
    }
    
    function cyclePrecision() {
        if (!configService) return
        
        const configKey = "storage.precision"
        const currentPrecision = configService.getValue(configKey, 0)
        const newPrecision = (currentPrecision + 1) % 4
        
        configService.setValue(configKey, newPrecision)
        configService.saveConfig()
    }
    
    function generateDisplayPreview() {
        let parts = []
        
        if (getConfigValue("showIcon", true)) parts.push("💾")
        if (getConfigValue("showLabel", false)) parts.push("Storage")
        
        let storageParts = []
        if (getConfigValue("showPercentage", true)) {
            storageParts.push(usagePercent.toFixed(getConfigValue("precision", 0)) + "%")
        }
        if (getConfigValue("showBytes", false)) {
            storageParts.push(currentUsage.toFixed(1) + "/" + totalAvailable.toFixed(1) + " GB")
        } else if (!getConfigValue("showPercentage", true)) {
            storageParts.push(currentUsage.toFixed(1) + " GB")
        }
        if (storageParts.length > 0) {
            parts.push(storageParts.join(" | "))
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
    function updateData(usage, total, percent) {
        currentUsage = usage || 0.0
        totalAvailable = total || 0.0
        usagePercent = percent || 0.0
    }
    
    // Navigation functions
    function navigateToParent() {
        if (!parentComponentId) return
        
        const parentComponent = ComponentRegistry.getComponent(parentComponentId)
        if (parentComponent && typeof parentComponent.menu === 'function') {
            console.log(`[StorageContextMenu] Navigating to parent: ${parentComponentId}`)
            
            // Hide this menu first
            hide()
            
            // Show parent menu at the same position
            const currentAnchor = anchor
            parentComponent.menu(currentAnchor.window, currentAnchor.rect.x, currentAnchor.rect.y)
        } else {
            console.warn(`[StorageContextMenu] Parent component ${parentComponentId} not found or doesn't support menu()`)
        }
    }
    
    function navigateToChild(childId) {
        if (!childComponentIds.includes(childId)) return
        
        const childComponent = ComponentRegistry.getComponent(childId)
        if (childComponent && typeof childComponent.menu === 'function') {
            console.log(`[StorageContextMenu] Navigating to child: ${childId}`)
            
            // Hide this menu first
            hide()
            
            // Show child menu at the same position
            const currentAnchor = anchor
            childComponent.menu(currentAnchor.window, currentAnchor.rect.x, currentAnchor.rect.y)
        } else {
            console.warn(`[StorageContextMenu] Child component ${childId} not found or doesn't support menu()`)
        }
    }
}