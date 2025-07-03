import QtQuick
import Quickshell

PopupWindow {
    id: quickMenu
    
    // Services passed from parent
    property var themeService: null
    property var configService: null
    
    // Popup configuration
    width: 200
    height: menuContent.implicitHeight + 16
    visible: false
    
    // Proper anchor configuration (not deprecated parentWindow)
    anchor {
        window: null  // Will be set when showing
        rect {
            x: 0
            y: 32  // Position below trigger
            width: 1
            height: 1
        }
    }
    
    // Background
    color: themeService ? themeService.getThemeProperty("colors", "surface") || "#313244" : "#313244"
    radius: 8
    
    // Auto-hide when clicking outside
    onActiveChanged: if (!active) visible = false
    
    // Menu content
    Column {
        id: menuContent
        anchors.fill: parent
        anchors.margins: 8
        spacing: 4
        
        // Header
        Text {
            text: "Quick Settings"
            color: themeService ? themeService.getThemeProperty("colors", "text") || "#cdd6f4" : "#cdd6f4"
            font.family: "Inter"
            font.pixelSize: 12
            font.weight: Font.DemiBold
            bottomPadding: 4
        }
        
        // Separator
        Rectangle {
            width: parent.width
            height: 1
            color: themeService ? themeService.getThemeProperty("colors", "border") || "#585b70" : "#585b70"
        }
        
        // Theme section
        Column {
            width: parent.width
            spacing: 2
            topPadding: 4
            
            Text {
                text: "Theme"
                color: themeService ? themeService.getThemeProperty("colors", "textAlt") || "#bac2de" : "#bac2de"
                font.family: "Inter"
                font.pixelSize: 10
                font.weight: Font.Medium
            }
            
            // Current theme display
            Rectangle {
                width: parent.width
                height: 24
                color: themeService ? themeService.getThemeProperty("colors", "surfaceAlt") || "#45475a" : "#45475a"
                radius: 4
                
                Row {
                    anchors.fill: parent
                    anchors.margins: 6
                    spacing: 6
                    
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: themeService ? (themeService.activeTheme || "catppuccin") : "catppuccin"
                        color: themeService ? themeService.getThemeProperty("colors", "text") || "#cdd6f4" : "#cdd6f4"
                        font.family: "Inter"
                        font.pixelSize: 10
                    }
                    
                    Item { width: 20; height: 1 } // Spacer
                    
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: themeService ? (themeService.activeMode || "dark") : "dark"
                        color: themeService ? themeService.getThemeProperty("colors", "primary") || "#89b4fa" : "#89b4fa"
                        font.family: "Inter"
                        font.pixelSize: 9
                        font.weight: Font.Medium
                    }
                }
            }
            
            // Theme actions
            Row {
                width: parent.width
                spacing: 4
                
                // Toggle dark/light mode
                Rectangle {
                    width: (parent.width - 4) / 2
                    height: 20
                    color: themeService ? themeService.getThemeProperty("colors", "background") || "#1e1e2e" : "#1e1e2e"
                    radius: 3
                    border.width: 1
                    border.color: themeService ? themeService.getThemeProperty("colors", "border") || "#585b70" : "#585b70"
                    
                    Text {
                        anchors.centerIn: parent
                        text: "🌓 Mode"
                        color: themeService ? themeService.getThemeProperty("colors", "text") || "#cdd6f4" : "#cdd6f4"
                        font.family: "Inter"
                        font.pixelSize: 9
                    }
                    
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        hoverEnabled: true
                        
                        onClicked: {
                            if (themeService) {
                                console.log("QuickMenu: Toggling theme mode")
                                themeService.toggleDarkMode()
                            }
                        }
                        
                        onEntered: parent.opacity = 0.8
                        onExited: parent.opacity = 1.0
                    }
                    
                    Behavior on opacity {
                        NumberAnimation { duration: 150; easing.type: Easing.OutCubic }
                    }
                }
                
                // Cycle themes
                Rectangle {
                    width: (parent.width - 4) / 2
                    height: 20
                    color: themeService ? themeService.getThemeProperty("colors", "background") || "#1e1e2e" : "#1e1e2e"
                    radius: 3
                    border.width: 1
                    border.color: themeService ? themeService.getThemeProperty("colors", "border") || "#585b70" : "#585b70"
                    
                    Text {
                        anchors.centerIn: parent
                        text: "🎨 Next"
                        color: themeService ? themeService.getThemeProperty("colors", "text") || "#cdd6f4" : "#cdd6f4"
                        font.family: "Inter"
                        font.pixelSize: 9
                    }
                    
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        hoverEnabled: true
                        
                        onClicked: {
                            if (themeService) {
                                console.log("QuickMenu: Cycling to next theme")
                                themeService.cycleTheme()
                            }
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
        
        // Separator
        Rectangle {
            width: parent.width
            height: 1
            color: themeService ? themeService.getThemeProperty("colors", "border") || "#585b70" : "#585b70"
            anchors.topMargin: 4
        }
        
        // Other quick actions
        Column {
            width: parent.width
            spacing: 2
            topPadding: 4
            
            Text {
                text: "Quick Actions"
                color: themeService ? themeService.getThemeProperty("colors", "textAlt") || "#bac2de" : "#bac2de"
                font.family: "Inter"
                font.pixelSize: 10
                font.weight: Font.Medium
            }
            
            // Reload config
            Rectangle {
                width: parent.width
                height: 20
                color: themeService ? themeService.getThemeProperty("colors", "background") || "#1e1e2e" : "#1e1e2e"
                radius: 3
                border.width: 1
                border.color: themeService ? themeService.getThemeProperty("colors", "border") || "#585b70" : "#585b70"
                
                Text {
                    anchors.centerIn: parent
                    text: "🔄 Reload Themes"
                    color: themeService ? themeService.getThemeProperty("colors", "text") || "#cdd6f4" : "#cdd6f4"
                    font.family: "Inter"
                    font.pixelSize: 9
                }
                
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    hoverEnabled: true
                    
                    onClicked: {
                        if (themeService) {
                            console.log("QuickMenu: Refreshing themes")
                            themeService.refreshThemes()
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
    
    // Show/hide methods
    function show(parentWindow, x, y) {
        // Set anchor window and position
        anchor.window = parentWindow
        anchor.rect.x = x || 0
        anchor.rect.y = y || 32
        visible = true
        
        // Lazy load themes when menu opens (following architecture principle)
        if (themeService) {
            themeService.loadAllThemes()
        }
    }
    
    function hide() {
        visible = false
    }
    
    Component.onCompleted: {
        console.log("QuickMenu: Component completed")
    }
}