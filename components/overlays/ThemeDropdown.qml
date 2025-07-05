import Quickshell
import Quickshell.Hyprland
import QtQuick
import QtCore

PanelWindow {
    id: themeDropdown
    
    // Window properties - cover entire screen
    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }
    
    visible: false
    color: "transparent"
    
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
    
    onVisibleChanged: {
        console.log(logCategory, "ThemeDropdown visible changed to:", visible)
    }
    
    // Focus grab for dismissal
    HyprlandFocusGrab {
        id: focusGrab
        windows: [themeDropdown]
        active: visible
        onCleared: hide()
    }
    
    // Background overlay with click-to-dismiss
    Rectangle {
        anchors.fill: parent
        color: "#80000000"  // Semi-transparent black
        opacity: parent.visible ? 0.8 : 0
        
        Behavior on opacity {
            NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
        }
        
        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.LeftButton
            onClicked: hide()
        }
    }
    
    // Main dropdown container - perfectly centered
    Rectangle {
        anchors.centerIn: parent
        width: 320
        height: Math.min(380, (themeList.count * 60) + 100)
        color: themeService ? themeService.getThemeProperty("colors", "background") || "#1e1e2e" : "#1e1e2e"
        border.color: themeService ? themeService.getThemeProperty("colors", "border") || "#585b70" : "#585b70"
        border.width: 2
        radius: 12
        
        // Scale animation for appearance
        scale: parent.visible ? 1.0 : 0.8
        opacity: parent.visible ? 1.0 : 0.0
        
        Behavior on scale {
            NumberAnimation { duration: 200; easing.type: Easing.OutBack }
        }
        
        Behavior on opacity {
            NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
        }
        
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
                color: closeMouseArea.containsMouse ? "#f38ba8" : "transparent"
                
                Text {
                    anchors.centerIn: parent
                    text: "×"
                    color: closeMouseArea.containsMouse ? "#1e1e2e" : "#f38ba8"
                    font.pixelSize: 14
                    font.weight: Font.Bold
                }
                
                MouseArea {
                    id: closeMouseArea
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
    function show(window) {
        console.log(logCategory, "ThemeDropdown show() called")
        
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