import Quickshell
import Quickshell.Hyprland
import QtQuick
import QtQuick.Controls
import "../base"

PopupWindow {
    id: barMenu
    
    // Window properties
    implicitWidth: 320
    implicitHeight: Math.min(450, menuContent.contentHeight + 32)
    visible: false
    color: "transparent"
    
    // Services
    property var configService: null
    property var themeService: null
    
    // Component hierarchy properties
    property string componentId: "bar"
    property string parentComponentId: ""
    property var childComponentIds: ["cpu", "ram", "storage", "clock", "workspaces"]
    
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
        windows: [barMenu]
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
                        text: "🔧"
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
                            text: "Status Bar Configuration"
                            font.pixelSize: 14
                            font.weight: Font.DemiBold
                            color: themeService ? themeService.getThemeProperty("colors", "text") || "#cdd6f4" : "#cdd6f4"
                        }
                        
                        Text {
                            text: "Layout and Position Settings"
                            font.pixelSize: 10
                            color: themeService ? themeService.getThemeProperty("colors", "textAlt") || "#bac2de" : "#bac2de"
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
                
                // Child Components Navigation
                Column {
                    width: parent.width
                    spacing: 6
                    
                    Text {
                        text: "Bar Components:"
                        font.pixelSize: 12
                        font.weight: Font.DemiBold
                        color: themeService ? themeService.getThemeProperty("colors", "text") || "#cdd6f4" : "#cdd6f4"
                    }
                    
                    // CPU Monitor
                    ComponentNavigationItem {
                        width: parent.width
                        componentId: "cpu"
                        title: "CPU Monitor"
                        icon: "💻"
                        description: "Processor usage monitoring"
                        enabled: getConfigValue("cpu.enabled", true)
                        onClicked: navigateToChild("cpu")
                    }
                    
                    // RAM Monitor
                    ComponentNavigationItem {
                        width: parent.width
                        componentId: "ram"
                        title: "RAM Monitor"
                        icon: "🧠"
                        description: "Memory usage monitoring"
                        enabled: getConfigValue("ram.enabled", true)
                        onClicked: navigateToChild("ram")
                    }
                    
                    // Storage Monitor
                    ComponentNavigationItem {
                        width: parent.width
                        componentId: "storage"
                        title: "Storage Monitor"
                        icon: "💾"
                        description: "Disk usage monitoring"
                        enabled: getConfigValue("storage.enabled", true)
                        onClicked: navigateToChild("storage")
                    }
                    
                    // Clock
                    ComponentNavigationItem {
                        width: parent.width
                        componentId: "clock"
                        title: "Clock Display"
                        icon: "🕐"
                        description: "Time and date display"
                        enabled: getConfigValue("clock.enabled", true)
                        onClicked: navigateToChild("clock")
                    }
                    
                    // Workspaces
                    ComponentNavigationItem {
                        width: parent.width
                        componentId: "workspaces"
                        title: "Workspace Display"
                        icon: "🖥️"
                        description: "Workspace indicator and switcher"
                        enabled: getConfigValue("workspaces.enabled", true)
                        onClicked: navigateToChild("workspaces")
                    }
                }
                
                // Separator
                Rectangle {
                    width: parent.width
                    height: 1
                    color: themeService ? themeService.getThemeProperty("colors", "border") || "#585b70" : "#585b70"
                }
                
                // Bar Layout Configuration
                Column {
                    width: parent.width
                    spacing: 8
                    
                    Text {
                        text: "Bar Configuration:"
                        font.pixelSize: 12
                        font.weight: Font.DemiBold
                        color: themeService ? themeService.getThemeProperty("colors", "text") || "#cdd6f4" : "#cdd6f4"
                    }
                    
                    // Bar position toggle
                    ConfigToggleItem {
                        width: parent.width
                        label: "Position"
                        value: getConfigValue("panel.position", "top") === "top" ? "Top" : "Bottom"
                        isActive: true
                        onClicked: togglePosition()
                    }
                    
                    // Show performance metrics toggle
                    ConfigToggleItem {
                        width: parent.width
                        label: "Performance Monitors"
                        value: getConfigValue("developer.showPerformanceMetrics", true) ? "Visible" : "Hidden"
                        isActive: getConfigValue("developer.showPerformanceMetrics", true)
                        onClicked: toggleConfig("developer.showPerformanceMetrics")
                    }
                }
                
                // Separator
                Rectangle {
                    width: parent.width
                    height: 1
                    color: themeService ? themeService.getThemeProperty("colors", "border") || "#585b70" : "#585b70"
                }
                
                // Quick Actions
                Column {
                    width: parent.width
                    spacing: 8
                    
                    Text {
                        text: "Quick Actions:"
                        font.pixelSize: 12
                        font.weight: Font.DemiBold
                        color: themeService ? themeService.getThemeProperty("colors", "text") || "#cdd6f4" : "#cdd6f4"
                    }
                    
                    // Enable all monitors
                    ConfigToggleItem {
                        width: parent.width
                        label: "Enable All Monitors"
                        value: "Click to Enable"
                        isActive: false
                        onClicked: enableAllMonitors()
                    }
                    
                    // Disable all monitors
                    ConfigToggleItem {
                        width: parent.width
                        label: "Disable All Monitors"
                        value: "Click to Disable"
                        isActive: false
                        onClicked: disableAllMonitors()
                    }
                }
            }
        }
    }
    
    // ComponentNavigationItem Component
    component ComponentNavigationItem: Rectangle {
        property string componentId: ""
        property string title: ""
        property string icon: ""
        property string description: ""
        property bool enabled: true
        signal clicked()
        
        height: 48
        radius: 8
        color: itemMouse.containsMouse ? 
               (themeService ? themeService.getThemeProperty("colors", "surfaceAlt") || "#45475a" : "#45475a") : 
               "transparent"
        border.width: 1
        border.color: enabled ? 
                     (themeService ? themeService.getThemeProperty("colors", "accent") || "#a6e3a1" : "#a6e3a1") :
                     (themeService ? themeService.getThemeProperty("colors", "border") || "#585b70" : "#585b70")
        
        Row {
            anchors.left: parent.left
            anchors.leftMargin: 12
            anchors.verticalCenter: parent.verticalCenter
            anchors.right: navIcon.left
            anchors.rightMargin: 8
            spacing: 12
            
            Text {
                text: icon
                font.pixelSize: 18
                anchors.verticalCenter: parent.verticalCenter
                opacity: enabled ? 1.0 : 0.5
            }
            
            Column {
                anchors.verticalCenter: parent.verticalCenter
                spacing: 2
                
                Text {
                    text: title
                    font.pixelSize: 12
                    font.weight: Font.Medium
                    color: enabled ? 
                           (themeService ? themeService.getThemeProperty("colors", "text") || "#cdd6f4" : "#cdd6f4") :
                           (themeService ? themeService.getThemeProperty("colors", "textAlt") || "#bac2de" : "#bac2de")
                }
                
                Text {
                    text: description + (enabled ? "" : " (Disabled)")
                    font.pixelSize: 9
                    color: themeService ? themeService.getThemeProperty("colors", "textAlt") || "#bac2de" : "#bac2de"
                    opacity: enabled ? 0.8 : 0.6
                }
            }
        }
        
        Text {
            id: navIcon
            anchors.right: parent.right
            anchors.rightMargin: 12
            anchors.verticalCenter: parent.verticalCenter
            text: "⚙️"
            font.pixelSize: 16
            color: themeService ? themeService.getThemeProperty("colors", "accent") || "#a6e3a1" : "#a6e3a1"
            opacity: enabled ? 1.0 : 0.5
        }
        
        MouseArea {
            id: itemMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: parent.clicked()
        }
        
        Behavior on color {
            ColorAnimation { duration: 150 }
        }
    }
    
    // ConfigToggleItem Component
    component ConfigToggleItem: Rectangle {
        property string label: ""
        property string value: ""
        property bool isActive: false
        signal clicked()
        
        height: 28
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
                font.pixelSize: 11
                color: themeService ? themeService.getThemeProperty("colors", "text") || "#cdd6f4" : "#cdd6f4"
                anchors.verticalCenter: parent.verticalCenter
            }
            
            Text {
                text: value
                font.pixelSize: 11
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
        return configService.getValue(key, defaultValue)
    }
    
    function toggleConfig(key) {
        if (!configService) return
        
        const currentValue = configService.getValue(key, true)
        const newValue = !currentValue
        
        configService.setValue(key, newValue)
        configService.saveConfig()
    }
    
    function togglePosition() {
        if (!configService) return
        
        const currentPosition = configService.getValue("panel.position", "top")
        const newPosition = currentPosition === "top" ? "bottom" : "top"
        
        configService.setValue("panel.position", newPosition)
        configService.saveConfig()
    }
    
    function enableAllMonitors() {
        if (!configService) return
        
        configService.setValue("cpu.enabled", true)
        configService.setValue("ram.enabled", true)
        configService.setValue("storage.enabled", true)
        configService.setValue("clock.enabled", true)
        configService.saveConfig()
    }
    
    function disableAllMonitors() {
        if (!configService) return
        
        configService.setValue("cpu.enabled", false)
        configService.setValue("ram.enabled", false)
        configService.setValue("storage.enabled", false)
        configService.setValue("clock.enabled", false)
        configService.saveConfig()
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
            console.log(`[BarContextMenu] Navigating to parent: ${parentComponentId}`)
            
            // Hide this menu first
            hide()
            
            // Show parent menu at the same position
            const currentAnchor = anchor
            parentComponent.menu(currentAnchor.window, currentAnchor.rect.x, currentAnchor.rect.y)
        } else {
            console.warn(`[BarContextMenu] Parent component ${parentComponentId} not found or doesn't support menu()`)
        }
    }
    
    function navigateToChild(childId) {
        if (!childComponentIds.includes(childId)) return
        
        const childComponent = ComponentRegistry.getComponent(childId)
        if (childComponent && typeof childComponent.menu === 'function') {
            console.log(`[BarContextMenu] Navigating to child: ${childId}`)
            
            // Hide this menu first
            hide()
            
            // Show child menu at the same position
            const currentAnchor = anchor
            childComponent.menu(currentAnchor.window, currentAnchor.rect.x, currentAnchor.rect.y)
        } else {
            console.warn(`[BarContextMenu] Child component ${childId} not found or doesn't support menu()`)
        }
    }
}