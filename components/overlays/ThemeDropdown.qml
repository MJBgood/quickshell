import Quickshell
import QtQuick
import QtCore

PopupWindow {
    id: themeDropdown
    
    // Window properties
    implicitWidth: 350
    implicitHeight: Math.min(400, (themeList.count * 60) + 120)
    visible: false
    color: "transparent"
    
    onVisibleChanged: {
        console.log(logCategory, "ThemeDropdown visible changed to:", visible)
    }
    
    // Anchor is required for PopupWindow to be visible
    anchor {
        window: null  // Will be set when showing
        rect {
            x: 0
            y: 0
            width: 1
            height: 1
        }
        edges: Edges.None
        gravity: Edges.None
        adjustment: PopupAdjustment.None
    }
    
    // Services passed from parent
    property var themeService: null
    property var configService: null
    
    // Signals
    signal closed()
    
    // Logging category
    LoggingCategory {
        id: logCategory
        name: "quickshell.themedropdown"
        defaultLogLevel: LoggingCategory.Info
    }
    
    // Background click area - only intercepts clicks outside the dropdown content
    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton
        // Lower z-order so the dropdown content receives clicks first
        z: -1
        onClicked: hide()
    }
    
    // Main dropdown container
    Rectangle {
        anchors.centerIn: parent
        width: 320
        height: Math.min(380, (themeList.count * 60) + 100)
        color: themeService ? themeService.getThemeProperty("colors", "background") || "#1e1e2e" : "#1e1e2e"
        border.color: themeService ? themeService.getThemeProperty("colors", "border") || "#585b70" : "#585b70"
        border.width: 2
        radius: 12
        z: 1  // Higher z-order to receive clicks
        
        // Header
        Rectangle {
            id: header
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            height: 50
            color: themeService ? themeService.getThemeProperty("colors", "surface") || "#313244" : "#313244"
            radius: 12
            
            Rectangle {
                anchors.bottom: parent.bottom
                anchors.left: parent.left
                anchors.right: parent.right
                height: 12
                color: parent.color
            }
            
            Text {
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                anchors.leftMargin: 16
                text: "Select Theme"
                font.pixelSize: 16
                font.weight: Font.DemiBold
                color: themeService ? themeService.getThemeProperty("colors", "text") || "#cdd6f4" : "#cdd6f4"
            }
            
            // Close button
            Rectangle {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                anchors.rightMargin: 16
                width: 24
                height: 24
                radius: 12
                color: themeService ? themeService.getThemeProperty("colors", "error") || "#f38ba8" : "#f38ba8"
                
                Text {
                    anchors.centerIn: parent
                    text: "×"
                    color: "white"
                    font.pixelSize: 14
                    font.weight: Font.Bold
                }
                
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: hide()
                }
            }
        }
        
        // Theme list
        ListView {
            id: themeList
            anchors.top: header.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: footer.top
            anchors.margins: 8
            
            model: themeService ? themeService.availableThemes : []
            clip: true
            spacing: 4
            
            delegate: Rectangle {
                width: themeList.width
                height: 50
                radius: 6
                color: modelData.id === (themeService ? themeService.activeTheme : "") ? 
                       (themeService ? themeService.getThemeProperty("colors", "primary") || "#89b4fa" : "#89b4fa") :
                       (mouseArea.containsMouse ? 
                        (themeService ? themeService.getThemeProperty("colors", "surfaceAlt") || "#45475a" : "#45475a") :
                        (themeService ? themeService.getThemeProperty("colors", "surface") || "#313244" : "#313244"))
                
                Row {
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.leftMargin: 12
                    spacing: 8
                    
                    // Theme indicator dot
                    Rectangle {
                        width: 8
                        height: 8
                        radius: 4
                        anchors.verticalCenter: parent.verticalCenter
                        color: modelData.id === (themeService ? themeService.activeTheme : "") ?
                               (themeService ? themeService.getThemeProperty("colors", "onPrimary") || "#1e1e2e" : "#1e1e2e") :
                               (themeService ? themeService.getThemeProperty("colors", "accent") || "#a6e3a1" : "#a6e3a1")
                    }
                    
                    Column {
                        spacing: 2
                        
                        Text {
                            text: modelData.name || modelData.id
                            font.pixelSize: 13
                            font.weight: modelData.id === (themeService ? themeService.activeTheme : "") ? Font.DemiBold : Font.Medium
                            color: modelData.id === (themeService ? themeService.activeTheme : "") ?
                                   (themeService ? themeService.getThemeProperty("colors", "onPrimary") || "#1e1e2e" : "#1e1e2e") :
                                   (themeService ? themeService.getThemeProperty("colors", "text") || "#cdd6f4" : "#cdd6f4")
                        }
                        
                        Text {
                            text: modelData.description || "Theme: " + modelData.id
                            font.pixelSize: 10
                            color: modelData.id === (themeService ? themeService.activeTheme : "") ?
                                   (themeService ? themeService.getThemeProperty("colors", "onPrimary") || "#1e1e2e" : "#1e1e2e") :
                                   (themeService ? themeService.getThemeProperty("colors", "textAlt") || "#bac2de" : "#bac2de")
                        }
                    }
                }
                
                // Mode indicator (if theme supports modes)
                Text {
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.rightMargin: 12
                    text: modelData.id === (themeService ? themeService.activeTheme : "") ?
                          (themeService && themeService.darkMode ? "🌙" : "☀️") : ""
                    font.pixelSize: 12
                    visible: modelData.id === (themeService ? themeService.activeTheme : "")
                }
                
                MouseArea {
                    id: mouseArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    
                    onClicked: {
                        if (themeService && modelData.id !== themeService.activeTheme) {
                            console.log(logCategory, "Switching to theme:", modelData.id)
                            themeService.loadTheme(modelData.id)
                        }
                    }
                }
                
                Behavior on color {
                    ColorAnimation { duration: 150; easing.type: Easing.OutCubic }
                }
            }
        }
        
        // Footer with mode toggle (only show if current theme supports modes)
        Rectangle {
            id: footer
            anchors.bottom: parent.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            height: themeService && themeService.currentThemeData && themeService.currentThemeData.supportsModes ? 50 : 20
            color: themeService ? themeService.getThemeProperty("colors", "surface") || "#313244" : "#313244"
            radius: 12
            
            Rectangle {
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.right: parent.right
                height: 12
                color: parent.color
            }
            
            // Mode toggle button (only visible if theme supports modes)
            Rectangle {
                anchors.centerIn: parent
                width: 120
                height: 32
                radius: 16
                color: themeService ? themeService.getThemeProperty("colors", "primary") || "#89b4fa" : "#89b4fa"
                visible: themeService && themeService.currentThemeData && themeService.currentThemeData.supportsModes
                
                Row {
                    anchors.centerIn: parent
                    spacing: 6
                    
                    Text {
                        text: themeService && themeService.darkMode ? "🌙" : "☀️"
                        font.pixelSize: 12
                    }
                    
                    Text {
                        text: themeService && themeService.darkMode ? "Dark Mode" : "Light Mode"
                        font.pixelSize: 11
                        font.weight: Font.Medium
                        color: themeService ? themeService.getThemeProperty("colors", "onPrimary") || "#1e1e2e" : "#1e1e2e"
                    }
                }
                
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    
                    onClicked: {
                        if (themeService) {
                            themeService.toggleDarkMode()
                        }
                    }
                }
            }
            
            // Info text for themes that don't support modes
            Text {
                anchors.centerIn: parent
                text: "This theme has a fixed color scheme"
                font.pixelSize: 11
                color: themeService ? themeService.getThemeProperty("colors", "textAlt") || "#bac2de" : "#bac2de"
                visible: !(themeService && themeService.currentThemeData && themeService.currentThemeData.supportsModes)
            }
        }
    }
    
    // Functions
    function show(anchorWindow) {
        console.log(logCategory, "ThemeDropdown show() called")
        
        if (anchorWindow) {
            // Set the anchor window (required for PopupWindow to be visible)
            anchor.window = anchorWindow
            
            // Simple center positioning
            if (anchorWindow.screen) {
                const screen = anchorWindow.screen
                const screenWidth = screen.width || 1920
                const screenHeight = screen.height || 1080
                
                // Center the popup on screen
                const centerX = screenWidth / 2 - implicitWidth / 2
                const centerY = screenHeight / 2 - implicitHeight / 2
                
                console.log(logCategory, "Centering popup at:", centerX + "," + centerY)
                
                // Set anchor to center position
                anchor.rect.x = centerX
                anchor.rect.y = centerY
                anchor.rect.width = 1
                anchor.rect.height = 1
                
                // Clear positioning constraints
                anchor.edges = Edges.None
                anchor.gravity = Edges.None
                anchor.adjustment = PopupAdjustment.None
            }
        } else {
            console.warn(logCategory, "No anchor window provided")
        }
        
        // Ensure themes are loaded
        if (themeService && themeService.availableThemes.length === 0) {
            themeService.refreshThemes()
        }
        
        visible = true
    }
    
    function hide() {
        visible = false
        closed()
    }
    
    Component.onCompleted: {
        console.log(logCategory, "ThemeDropdown component completed")
    }
}