import Quickshell
import Quickshell.Hyprland
import QtQuick
import QtQuick.Controls
import "../base"

PopupWindow {
    id: workspacesMenu
    
    // Window properties
    implicitWidth: 340
    implicitHeight: Math.min(420, menuContent.contentHeight + 32)
    visible: false
    color: "transparent"
    
    // Services
    property var configService: ConfigService
    
    // Component hierarchy properties
    property string componentId: "workspaces"
    property string parentComponentId: "bar"
    property var childComponentIds: []
    
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
        windows: [workspacesMenu]
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
            
            // Fix scrolling behavior
            ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
            contentWidth: -1  // Disable horizontal scrolling
            
            // Custom scrollbar styling  
            ScrollBar.vertical.policy: ScrollBar.AsNeeded
            ScrollBar.vertical.width: 8
            ScrollBar.vertical.background: Rectangle {
                color: "transparent"
                radius: 4
            }
            ScrollBar.vertical.contentItem: Rectangle {
                color: configService ? configService.getThemeProperty("colors", "border") || "#585b70" : "#585b70"
                radius: 4
                opacity: 0.6
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
                        width: parent.width - (parentComponentId !== "" ? 36 : 0) - 32
                        height: 32
                        
                        Text {
                            id: iconText
                            text: "🖥️"
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
                                text: "Workspace Display"
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
                
                // Separator
                Rectangle {
                    width: parent.width
                    height: 1
                    color: configService ? configService.getThemeProperty("colors", "border") || "#585b70" : "#585b70"
                }
                
                // Workspace Display Configuration
                Column {
                    width: parent.width
                    spacing: 8
                    
                    Text {
                        text: "Display Settings:"
                        font.pixelSize: 12
                        font.weight: Font.DemiBold
                        color: configService ? configService.getThemeProperty("colors", "text") || "#cdd6f4" : "#cdd6f4"
                    }
                    
                    // Show workspace numbers
                    ConfigToggleItem {
                        width: parent.width
                        label: "Show Numbers"
                        value: getConfigValue("showNumbers", true) ? "Enabled" : "Disabled"
                        isActive: getConfigValue("showNumbers", true)
                        onClicked: toggleConfig("showNumbers")
                    }
                    
                    // Show workspace names
                    ConfigToggleItem {
                        width: parent.width
                        label: "Show Names"
                        value: getConfigValue("showNames", false) ? "Enabled" : "Disabled"
                        isActive: getConfigValue("showNames", false)
                        onClicked: toggleConfig("showNames")
                    }
                    
                    // Show window count
                    ConfigToggleItem {
                        width: parent.width
                        label: "Show Window Count"
                        value: getConfigValue("showWindowCount", false) ? "Enabled" : "Disabled"
                        isActive: getConfigValue("showWindowCount", false)
                        onClicked: toggleConfig("showWindowCount")
                    }
                    
                    // Show only active workspaces
                    ConfigToggleItem {
                        width: parent.width
                        label: "Show Only Active"
                        value: getConfigValue("showOnlyActive", false) ? "Enabled" : "Disabled"
                        isActive: getConfigValue("showOnlyActive", false)
                        onClicked: {
                            console.log(`[WorkspacesContextMenu] Before toggle - showOnlyActive: ${getConfigValue("showOnlyActive", false)}`)
                            toggleConfig("showOnlyActive")
                            console.log(`[WorkspacesContextMenu] After toggle - showOnlyActive: ${getConfigValue("showOnlyActive", false)}`)
                        }
                    }
                }
                
                // Separator
                Rectangle {
                    width: parent.width
                    height: 1
                    color: configService ? configService.getThemeProperty("colors", "border") || "#585b70" : "#585b70"
                }
                
                // Workspace Behavior Configuration
                Column {
                    width: parent.width
                    spacing: 8
                    
                    Text {
                        text: "Behavior Settings:"
                        font.pixelSize: 12
                        font.weight: Font.DemiBold
                        color: configService ? configService.getThemeProperty("colors", "text") || "#cdd6f4" : "#cdd6f4"
                    }
                    
                    // Click to switch workspaces
                    ConfigToggleItem {
                        width: parent.width
                        label: "Click to Switch"
                        value: getConfigValue("clickToSwitch", true) ? "Enabled" : "Disabled"
                        isActive: getConfigValue("clickToSwitch", true)
                        onClicked: toggleConfig("clickToSwitch")
                    }
                    
                    // Scroll to switch workspaces
                    ConfigToggleItem {
                        width: parent.width
                        label: "Scroll to Switch"
                        value: getConfigValue("scrollToSwitch", true) ? "Enabled" : "Disabled"
                        isActive: getConfigValue("scrollToSwitch", true)
                        onClicked: toggleConfig("scrollToSwitch")
                    }
                    
                    // Auto-hide empty workspaces
                    ConfigToggleItem {
                        width: parent.width
                        label: "Auto-hide Empty"
                        value: getConfigValue("autoHideEmpty", false) ? "Enabled" : "Disabled"
                        isActive: getConfigValue("autoHideEmpty", false)
                        onClicked: toggleConfig("autoHideEmpty")
                    }
                    
                    // Show application icons
                    ConfigToggleItem {
                        width: parent.width
                        label: "Show Application Icons"
                        value: getConfigValue("showApplicationIcons", true) ? "Enabled" : "Disabled"
                        isActive: getConfigValue("showApplicationIcons", true)
                        onClicked: toggleConfig("showApplicationIcons")
                    }
                }
                
                // Separator
                Rectangle {
                    width: parent.width
                    height: 1
                    color: configService ? configService.getThemeProperty("colors", "border") || "#585b70" : "#585b70"
                }
                
                // Workspace Layout Configuration
                Column {
                    width: parent.width
                    spacing: 8
                    
                    Text {
                        text: "Layout Settings:"
                        font.pixelSize: 12
                        font.weight: Font.DemiBold
                        color: configService ? configService.getThemeProperty("colors", "text") || "#cdd6f4" : "#cdd6f4"
                    }
                    
                    // Workspace size
                    ConfigToggleItem {
                        width: parent.width
                        label: "Workspace Size"
                        value: getConfigValue("workspaceSize", "medium") // "small", "medium", "large"
                        isActive: true
                        onClicked: cycleWorkspaceSize()
                    }
                    
                    // Workspace spacing
                    ConfigToggleItem {
                        width: parent.width
                        label: "Workspace Spacing"
                        value: getConfigValue("workspaceSpacing", "normal") // "tight", "normal", "loose"
                        isActive: true
                        onClicked: cycleWorkspaceSpacing()
                    }
                    
                    // Corner radius
                    ConfigToggleItem {
                        width: parent.width
                        label: "Corner Radius"
                        value: getConfigValue("cornerRadius", "medium") // "none", "small", "medium", "large"
                        isActive: true
                        onClicked: cycleCornerRadius()
                    }
                }
                
                // Separator
                Rectangle {
                    width: parent.width
                    height: 1
                    color: configService ? configService.getThemeProperty("colors", "border") || "#585b70" : "#585b70"
                }
                
                // Current Workspace Info
                Column {
                    width: parent.width
                    spacing: 4
                    
                    Text {
                        text: "Current Status:"
                        font.pixelSize: 10
                        font.weight: Font.DemiBold
                        color: configService ? configService.getThemeProperty("colors", "textAlt") || "#bac2de" : "#bac2de"
                    }
                    
                    Rectangle {
                        width: parent.width
                        height: statusColumn.implicitHeight + 12
                        color: configService ? configService.getThemeProperty("colors", "surfaceAlt") || "#45475a" : "#45475a"
                        radius: 6
                        
                        Column {
                            id: statusColumn
                            anchors.centerIn: parent
                            spacing: 2
                            
                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: `Active: ${Hyprland.focusedWorkspace ? Hyprland.focusedWorkspace.id : "Unknown"}`
                                font.pixelSize: 11
                                font.family: "monospace"
                                color: configService ? configService.getThemeProperty("colors", "text") || "#cdd6f4" : "#cdd6f4"
                            }
                            
                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: `Total: ${Hyprland.workspaces ? Hyprland.workspaces.length : 0} workspaces`
                                font.pixelSize: 10
                                font.family: "monospace"
                                color: configService ? configService.getThemeProperty("colors", "textAlt") || "#bac2de" : "#bac2de"
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
        return configService.getValue("workspaces." + key, defaultValue)
    }
    
    function toggleConfig(key) {
        if (!configService) return
        
        const configKey = "workspaces." + key
        const defaults = {
            "showNumbers": true,
            "showNames": false,
            "showWindowCount": false,
            "showOnlyActive": false,
            "clickToSwitch": true,
            "scrollToSwitch": true,
            "autoHideEmpty": false,
            "showApplicationIcons": true
        }
        
        const currentValue = configService.getValue(configKey, defaults[key] || false)
        const newValue = !currentValue
        
        console.log(`[WorkspacesContextMenu] Toggling ${configKey}: ${currentValue} -> ${newValue}`)
        
        if (configService.setValue(configKey, newValue)) {
            configService.saveConfig()
            console.log(`[WorkspacesContextMenu] Successfully saved ${configKey} = ${newValue}`)
        } else {
            console.error(`[WorkspacesContextMenu] Failed to set ${configKey}`)
        }
    }
    
    function cycleWorkspaceSize() {
        if (!configService) return
        
        const configKey = "workspaces.workspaceSize"
        const currentSize = configService.getValue(configKey, "medium")
        const sizes = ["small", "medium", "large"]
        const currentIndex = sizes.indexOf(currentSize)
        const newIndex = (currentIndex + 1) % sizes.length
        
        console.log(`[WorkspacesContextMenu] Cycling workspace size: ${currentSize} -> ${sizes[newIndex]}`)
        
        if (configService.setValue(configKey, sizes[newIndex])) {
            configService.saveConfig()
            console.log(`[WorkspacesContextMenu] Successfully saved ${configKey} = ${sizes[newIndex]}`)
        }
    }
    
    function cycleWorkspaceSpacing() {
        if (!configService) return
        
        const configKey = "workspaces.workspaceSpacing"
        const currentSpacing = configService.getValue(configKey, "normal")
        const spacings = ["tight", "normal", "loose"]
        const currentIndex = spacings.indexOf(currentSpacing)
        const newIndex = (currentIndex + 1) % spacings.length
        
        console.log(`[WorkspacesContextMenu] Cycling workspace spacing: ${currentSpacing} -> ${spacings[newIndex]}`)
        
        if (configService.setValue(configKey, spacings[newIndex])) {
            configService.saveConfig()
            console.log(`[WorkspacesContextMenu] Successfully saved ${configKey} = ${spacings[newIndex]}`)
        }
    }
    
    function cycleCornerRadius() {
        if (!configService) return
        
        const configKey = "workspaces.cornerRadius"
        const currentRadius = configService.getValue(configKey, "medium")
        const radii = ["none", "small", "medium", "large"]
        const currentIndex = radii.indexOf(currentRadius)
        const newIndex = (currentIndex + 1) % radii.length
        
        console.log(`[WorkspacesContextMenu] Cycling corner radius: ${currentRadius} -> ${radii[newIndex]}`)
        
        if (configService.setValue(configKey, radii[newIndex])) {
            configService.saveConfig()
            console.log(`[WorkspacesContextMenu] Successfully saved ${configKey} = ${radii[newIndex]}`)
        }
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
            console.log(`[WorkspacesContextMenu] Navigating to parent: ${parentComponentId}`)
            
            // Hide this menu first
            hide()
            
            // Show parent menu at the same position
            const currentAnchor = anchor
            parentComponent.menu(currentAnchor.window, currentAnchor.rect.x, currentAnchor.rect.y)
        } else {
            console.warn(`[WorkspacesContextMenu] Parent component ${parentComponentId} not found or doesn't support menu()`)
        }
    }
    
    function navigateToChild(childId) {
        if (!childComponentIds.includes(childId)) return
        
        const childComponent = ComponentRegistry.getComponent(childId)
        if (childComponent && typeof childComponent.menu === 'function') {
            console.log(`[WorkspacesContextMenu] Navigating to child: ${childId}`)
            
            // Hide this menu first
            hide()
            
            // Show child menu at the same position
            const currentAnchor = anchor
            childComponent.menu(currentAnchor.window, currentAnchor.rect.x, currentAnchor.rect.y)
        } else {
            console.warn(`[WorkspacesContextMenu] Child component ${childId} not found or doesn't support menu()`)
        }
    }
}