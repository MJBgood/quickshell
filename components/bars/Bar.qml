import Quickshell
import Quickshell.Hyprland
import QtQuick
import "../widgets"
import "../base"

PanelWindow {
    id: bar
    
    // Required property for screen assignment
    property var modelData
    
    // Access to services (passed from parent)
    property var themeService: null
    property var configService: null
    property var systemMonitorService: null
    property var shellRoot: null
    
    // Panel configuration - position determined by config
    property string position: configService ? configService.getValue("panel.position", "top") : "top"
    
    // Set screen from modelData (for multi-monitor support)
    screen: modelData
    
    anchors {
        top: position === "top"
        bottom: position === "bottom"
        left: true
        right: true
    }
    
    implicitHeight: 32
    color: themeService ? themeService.getThemeProperty("colors", "background") || "#1e1e2e" : "#1e1e2e"
    
    // Content - Using absolute positioning for reliable layout
    Item {
        anchors.fill: parent
        anchors.margins: 8
        
        // Left section - App launcher icon (clickable)
        Rectangle {
            id: leftSection
            width: 32
            height: parent.height
            color: themeService ? themeService.getThemeProperty("colors", "surface") || "#313244" : "#313244"
            radius: 4
            
            anchors {
                left: parent.left
                verticalCenter: parent.verticalCenter
            }
            
            // App launcher icon
            Text {
                anchors.centerIn: parent
                text: "⚙"  // Settings gear icon as placeholder
                color: themeService ? themeService.getThemeProperty("colors", "text") || "#cdd6f4" : "#cdd6f4"
                font.pixelSize: 16
            }
            
            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                hoverEnabled: true
                
                onClicked: {
                    if (bar.shellRoot) {
                        var anchorRect = {
                            x: leftSection.x,
                            y: leftSection.y,
                            width: leftSection.width,
                            height: leftSection.height
                        }
                        bar.shellRoot.toggleSettings(bar, anchorRect)
                    }
                }
                
                onEntered: parent.opacity = 0.8
                onExited: parent.opacity = 1.0
            }
            
            Behavior on opacity {
                NumberAnimation { duration: 150; easing.type: Easing.OutCubic }
            }
        }
        
        // Center section - Workspace indicator (centered)
        Rectangle {
            id: centerSection
            width: Math.max(workspaceRow.implicitWidth + 16, 120) // Dynamic width with minimum
            height: parent.height
            color: themeService ? themeService.getThemeProperty("colors", "surface") || "#313244" : "#313244"
            radius: 4
            
            anchors {
                horizontalCenter: parent.horizontalCenter
                verticalCenter: parent.verticalCenter
            }
            
            Row {
                id: workspaceRow
                anchors.centerIn: parent
                spacing: 8
                
                Repeater {
                    model: Hyprland.workspaces
                    
                    Rectangle {
                        width: 32
                        height: 20
                        radius: 4
                        color: modelData && modelData.focused ? 
                               (themeService ? themeService.getThemeProperty("colors", "primary") || "#89b4fa" : "#89b4fa") :
                               (themeService ? themeService.getThemeProperty("colors", "surfaceAlt") || "#45475a" : "#45475a")
                        
                        // Hover effect with smooth transition
                        opacity: workspaceMouseArea.containsMouse ? 0.8 : 1.0
                        
                        Behavior on opacity {
                            NumberAnimation { duration: 150; easing.type: Easing.OutCubic }
                        }
                        
                        Behavior on color {
                            ColorAnimation { duration: 200; easing.type: Easing.OutCubic }
                        }
                        
                        
                        Text {
                            anchors.centerIn: parent
                            text: modelData ? modelData.id : (index + 1)
                            color: modelData && modelData.focused ? 
                                   (themeService ? themeService.getThemeProperty("colors", "onPrimary") || "#1e1e2e" : "#1e1e2e") :
                                   (themeService ? themeService.getThemeProperty("colors", "text") || "#cdd6f4" : "#cdd6f4")
                            font.family: "Inter"
                            font.pixelSize: 11
                            font.weight: modelData && modelData.focused ? Font.DemiBold : Font.Medium
                        }
                        
                        MouseArea {
                            id: workspaceMouseArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            
                            onClicked: {
                                const workspaceId = modelData ? modelData.id : (index + 1)
                                // Use Hyprland singleton directly for workspace switching
                                Hyprland.dispatch("workspace " + workspaceId)
                            }
                            
                            onEntered: {
                                const workspaceId = modelData ? modelData.id : (index + 1)
                            }
                        }
                    }
                }
            }
        }
        
        // Performance monitoring section
        Performance {
            id: performanceSection
            visible: configService ? configService.getValue("developer.showPerformanceMetrics", true) : true
            
            anchors {
                right: rightSection.left
                rightMargin: visible ? 12 : 0
                verticalCenter: parent.verticalCenter
            }
            
            // Services
            systemMonitorService: bar.systemMonitorService
            themeService: bar.themeService
            configService: bar.configService
            barWindow: bar  // Pass bar reference for popup anchoring
            
            // Configuration for bar integration is now handled by ConfigService
            // Individual monitor settings are automatically loaded from config
        }
        
        // Right section - Clock (anchored to right)
        Rectangle {
            id: rightSection
            width: 80
            height: parent.height
            color: themeService ? themeService.getThemeProperty("colors", "surface") || "#313244" : "#313244"
            radius: 4
            
            anchors {
                right: parent.right
                verticalCenter: parent.verticalCenter
            }
            
            SystemClock {
                id: clock
                precision: SystemClock.Minutes  // Battery optimization - only update every minute
            }
            
            Text {
                id: clockText
                anchors.centerIn: parent
                text: Qt.formatDateTime(clock.date, "hh:mm")
                color: themeService ? themeService.getThemeProperty("colors", "text") || "#cdd6f4" : "#cdd6f4"
                font.family: "Inter"
                font.pixelSize: 12
                font.weight: Font.Medium
            }
        }
    }
    
    // Quick menu popup (inline definition)
    PopupWindow {
        id: quickMenu
        implicitWidth: 200
        implicitHeight: 150
        visible: false
        
        anchor {
            window: bar
            rect {
                x: 0
                y: 32
                width: 1
                height: 1
            }
        }
        
        Rectangle {
            anchors.fill: parent
            color: themeService ? themeService.getThemeProperty("colors", "surface") || "#313244" : "#313244"
            radius: 8
            border.width: 1
            border.color: themeService ? themeService.getThemeProperty("colors", "border") || "#585b70" : "#585b70"
            
            Column {
                anchors.fill: parent
                anchors.margins: 8
                spacing: 4
                
                Text {
                    text: "Quick Settings"
                    color: themeService ? themeService.getThemeProperty("colors", "text") || "#cdd6f4" : "#cdd6f4"
                    font.family: "Inter"
                    font.pixelSize: 12
                    font.weight: Font.DemiBold
                }
                
                Rectangle {
                    width: parent.width
                    height: 1
                    color: themeService ? themeService.getThemeProperty("colors", "border") || "#585b70" : "#585b70"
                }
                
                // Theme toggle button
                Rectangle {
                    width: parent.width
                    height: 24
                    color: themeService ? themeService.getThemeProperty("colors", "background") || "#1e1e2e" : "#1e1e2e"
                    radius: 4
                    border.width: 1
                    border.color: themeService ? themeService.getThemeProperty("colors", "border") || "#585b70" : "#585b70"
                    
                    Text {
                        anchors.centerIn: parent
                        text: "🌓 Toggle Mode"
                        color: themeService ? themeService.getThemeProperty("colors", "text") || "#cdd6f4" : "#cdd6f4"
                        font.family: "Inter"
                        font.pixelSize: 10
                    }
                    
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        hoverEnabled: true
                        
                        onClicked: {
                            if (themeService) {
                                themeService.toggleDarkMode()
                            }
                            quickMenu.visible = false
                        }
                        
                        onEntered: parent.opacity = 0.8
                        onExited: parent.opacity = 1.0
                    }
                    
                    Behavior on opacity {
                        NumberAnimation { duration: 150; easing.type: Easing.OutCubic }
                    }
                }
                
                // Cycle theme button
                Rectangle {
                    width: parent.width
                    height: 24
                    color: themeService ? themeService.getThemeProperty("colors", "background") || "#1e1e2e" : "#1e1e2e"
                    radius: 4
                    border.width: 1
                    border.color: themeService ? themeService.getThemeProperty("colors", "border") || "#585b70" : "#585b70"
                    
                    Text {
                        anchors.centerIn: parent
                        text: "🎨 Next Theme"
                        color: themeService ? themeService.getThemeProperty("colors", "text") || "#cdd6f4" : "#cdd6f4"
                        font.family: "Inter"
                        font.pixelSize: 10
                    }
                    
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        hoverEnabled: true
                        
                        onClicked: {
                            if (themeService) {
                                themeService.cycleTheme()
                            }
                            quickMenu.visible = false
                        }
                        
                        onEntered: parent.opacity = 0.8
                        onExited: parent.opacity = 1.0
                    }
                    
                    Behavior on opacity {
                        NumberAnimation { duration: 150; easing.type: Easing.OutCubic }
                    }
                }
            }
        }
    }
    
    // Right-click context menu for settings access (lower z-order so monitors can override)
    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.RightButton
        z: -1  // Lower z-order so monitor MouseAreas can override
        onClicked: function(mouse) {
            if (mouse.button === Qt.RightButton) {
                if (shellRoot) {
                    var anchorRect = {
                        x: mouse.x,
                        y: mouse.y,
                        width: 1,
                        height: 1
                    }
                    shellRoot.showSettings(bar, anchorRect)
                }
            }
        }
    }
    
    // Services connected automatically

    Component.onCompleted: {
        // Bar initialized
    }
}