import Quickshell
import Quickshell.Hyprland
import QtQuick
import QtQuick.Controls
import "../base"

PopupWindow {
    id: clockMenu
    
    // Window properties
    implicitWidth: 300
    implicitHeight: Math.min(350, menuContent.contentHeight + 32)
    visible: false
    color: "transparent"
    
    // Services
    property var configService: ConfigService
    
    // Component hierarchy properties
    property string componentId: "clock"
    property string parentComponentId: "bar"
    property var childComponentIds: []
    
    // Live data properties for preview
    property var currentTime: new Date()
    
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
        windows: [clockMenu]
        onCleared: hide()
    }
    
    // Timer for live preview updates
    Timer {
        id: previewTimer
        interval: 1000
        running: visible
        repeat: true
        onTriggered: currentTime = new Date()
    }
    
    // Main container
    Rectangle {
        id: menuContent
        anchors.fill: parent
        color: configService ? configService.getThemeProperty("colors", "surface") || "#313244" : "#313244"
        border.color: configService ? configService.getThemeProperty("colors", "border") || "#585b70" : "#585b70"
        border.width: 1
        radius: 12
        
        property real contentHeight: scrollableContent.contentHeight + fixedHeader.height + 32
        
        // Fixed Header (stays visible when scrolling)
        Item {
            id: fixedHeader
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.margins: 16
            height: 50
            z: 10
            
            // Navigation Header
            Row {
                anchors.fill: parent
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
                    width: parent.width - (parentComponentId !== "" ? 36 : 0) - 32
                    height: 32
                    
                    Text {
                        id: iconText
                        text: "🕐"
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
                            text: "Clock Display"
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
            
            // Header separator
            Rectangle {
                anchors.bottom: parent.bottom
                anchors.left: parent.left
                anchors.right: parent.right
                height: 1
                color: configService ? configService.getThemeProperty("colors", "border") || "#585b70" : "#585b70"
            }
        }
        
        // Scrollable Content
        ScrollView {
            id: scrollableContent
            anchors.top: fixedHeader.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.margins: 16
            anchors.topMargin: 8
            clip: true
            
            // Fix scrolling behavior
            contentWidth: -1  // Disable horizontal scrolling
            
            Component.onCompleted: {
                ScrollBar.horizontal.policy = ScrollBar.AlwaysOff
                ScrollBar.vertical.policy = ScrollBar.AsNeeded
            }
            
            Column {
                width: Math.max(parent.width - 16, 260)
                spacing: 12
                
                // Time Format Configuration
                Column {
                    width: parent.width
                    spacing: 8
                    
                    Text {
                        text: "Time Format:"
                        font.pixelSize: 12
                        font.weight: Font.DemiBold
                        color: configService ? configService.getThemeProperty("colors", "text") || "#cdd6f4" : "#cdd6f4"
                    }
                    
                    // 12-hour vs 24-hour format
                    ConfigToggleItem {
                        width: parent.width
                        label: "Format"
                        value: getConfigValue("format24Hour", true) ? "24-hour" : "12-hour"
                        isActive: true
                        onClicked: toggleConfig("format24Hour")
                    }
                    
                    // Show seconds toggle
                    ConfigToggleItem {
                        width: parent.width
                        label: "Show Seconds"
                        value: getConfigValue("showSeconds", false) ? "Enabled" : "Disabled"
                        isActive: getConfigValue("showSeconds", false)
                        onClicked: toggleConfig("showSeconds")
                    }
                    
                    // Show date toggle
                    ConfigToggleItem {
                        width: parent.width
                        label: "Show Date"
                        value: getConfigValue("showDate", false) ? "Enabled" : "Disabled"
                        isActive: getConfigValue("showDate", false)
                        onClicked: toggleConfig("showDate")
                    }
                }
                
                // Separator
                Rectangle {
                    width: parent.width
                    height: 1
                    color: configService ? configService.getThemeProperty("colors", "border") || "#585b70" : "#585b70"
                }
                
                // Date Format Configuration (only when showDate is enabled)
                Column {
                    width: parent.width
                    spacing: 8
                    visible: getConfigValue("showDate", false)
                    
                    Text {
                        text: "Date Format:"
                        font.pixelSize: 12
                        font.weight: Font.DemiBold
                        color: configService ? configService.getThemeProperty("colors", "text") || "#cdd6f4" : "#cdd6f4"
                    }
                    
                    // Date format style
                    ConfigToggleItem {
                        width: parent.width
                        label: "Date Style"
                        value: getConfigValue("dateFormat", "short") // "short", "medium", "long"
                        isActive: true
                        onClicked: cycleDateFormat()
                    }
                    
                    // Date position
                    ConfigToggleItem {
                        width: parent.width
                        label: "Date Position"
                        value: getConfigValue("datePosition", "below") // "below", "above", "inline"
                        isActive: true
                        onClicked: cycleDatePosition()
                    }
                }
                
                // Separator (only when date section is visible)
                Rectangle {
                    width: parent.width
                    height: 1
                    color: configService ? configService.getThemeProperty("colors", "border") || "#585b70" : "#585b70"
                    visible: getConfigValue("showDate", false)
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
                        height: previewColumn.implicitHeight + 12
                        color: configService ? configService.getThemeProperty("colors", "surfaceAlt") || "#45475a" : "#45475a"
                        radius: 6
                        
                        Column {
                            id: previewColumn
                            anchors.centerIn: parent
                            spacing: 2
                            
                            Text {
                                id: previewTimeText
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: generateTimePreview()
                                font.pixelSize: 12
                                font.family: "monospace"
                                color: configService ? configService.getThemeProperty("colors", "text") || "#cdd6f4" : "#cdd6f4"
                            }
                            
                            Text {
                                id: previewDateText
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: generateDatePreview()
                                font.pixelSize: 10
                                font.family: "monospace"
                                color: configService ? configService.getThemeProperty("colors", "textAlt") || "#bac2de" : "#bac2de"
                                visible: getConfigValue("showDate", false)
                            }
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
                color: isActive ? "#a6e3a1" : "#89b4fa"
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
        return configService.getValue("clock." + key, defaultValue)
    }
    
    function toggleConfig(key) {
        if (!configService) return
        
        const configKey = "clock." + key
        const currentValue = configService.getValue(configKey, key === "format24Hour" ? true : false)
        const newValue = !currentValue
        
        configService.setValue(configKey, newValue)
        configService.saveConfig()
    }
    
    function cycleDateFormat() {
        if (!configService) return
        
        const configKey = "clock.dateFormat"
        const currentFormat = configService.getValue(configKey, "short")
        const formats = ["short", "medium", "long"]
        const currentIndex = formats.indexOf(currentFormat)
        const newIndex = (currentIndex + 1) % formats.length
        
        configService.setValue(configKey, formats[newIndex])
        configService.saveConfig()
    }
    
    function cycleDatePosition() {
        if (!configService) return
        
        const configKey = "clock.datePosition"
        const currentPosition = configService.getValue(configKey, "below")
        const positions = ["below", "above", "inline"]
        const currentIndex = positions.indexOf(currentPosition)
        const newIndex = (currentIndex + 1) % positions.length
        
        configService.setValue(configKey, positions[newIndex])
        configService.saveConfig()
    }
    
    function generateTimePreview() {
        const format24Hour = getConfigValue("format24Hour", true)
        const showSeconds = getConfigValue("showSeconds", false)
        
        let timeFormat = format24Hour ? "hh:mm" : "h:mm AP"
        if (showSeconds) {
            timeFormat = format24Hour ? "hh:mm:ss" : "h:mm:ss AP"
        }
        
        return Qt.formatDateTime(currentTime, timeFormat)
    }
    
    function generateDatePreview() {
        if (!getConfigValue("showDate", false)) return ""
        
        const dateFormat = getConfigValue("dateFormat", "short")
        let format = ""
        
        switch (dateFormat) {
            case "short":
                format = "yyyy-MM-dd"
                break
            case "medium":
                format = "MMM d, yyyy"
                break
            case "long":
                format = "MMMM d, yyyy"
                break
            default:
                format = "yyyy-MM-dd"
        }
        
        return Qt.formatDateTime(currentTime, format)
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
    
    // Navigation functions
    function navigateToParent() {
        if (!parentComponentId) return
        
        const parentComponent = ComponentRegistry.getComponent(parentComponentId)
        if (parentComponent && typeof parentComponent.menu === 'function') {
            console.log(`[ClockContextMenu] Navigating to parent: ${parentComponentId}`)
            
            // Hide this menu first
            hide()
            
            // Show parent menu at the same position
            const currentAnchor = anchor
            parentComponent.menu(currentAnchor.window, currentAnchor.rect.x, currentAnchor.rect.y)
        } else {
            console.warn(`[ClockContextMenu] Parent component ${parentComponentId} not found or doesn't support menu()`)
        }
    }
    
    function navigateToChild(childId) {
        if (!childComponentIds.includes(childId)) return
        
        const childComponent = ComponentRegistry.getComponent(childId)
        if (childComponent && typeof childComponent.menu === 'function') {
            console.log(`[ClockContextMenu] Navigating to child: ${childId}`)
            
            // Hide this menu first
            hide()
            
            // Show child menu at the same position
            const currentAnchor = anchor
            childComponent.menu(currentAnchor.window, currentAnchor.rect.x, currentAnchor.rect.y)
        } else {
            console.warn(`[ClockContextMenu] Child component ${childId} not found or doesn't support menu()`)
        }
    }
}