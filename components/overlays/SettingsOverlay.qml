import Quickshell
import Quickshell.Hyprland
import QtQuick
import QtCore

PopupWindow {
    id: settingsOverlay
    
    // Logging category for this component
    LoggingCategory {
        id: logCategory
        name: "quickshell.settings"
        defaultLogLevel: LoggingCategory.Info
    }
    
    // Window properties
    implicitWidth: 400
    implicitHeight: 300
    visible: false
    
    // Make window background transparent to avoid white corners
    color: "transparent"
    
    // Popup anchor configuration
    anchor {
        // Will be set dynamically when showing
        window: null
        rect.x: 0
        rect.y: 0
        rect.width: 32  // Default button size
        rect.height: 32
        
        // Position below and to the right of anchor point
        edges: Edges.Top | Edges.Left
        gravity: Edges.Bottom | Edges.Right
        
        // Auto-adjust position if popup would go off-screen
        adjustment: PopupAdjustment.Slide | PopupAdjustment.Flip
        
        // Small margin from the anchor
        margins {
            top: 8
            left: 0
            right: 0
            bottom: 0
        }
    }
    
    // Auto-close behavior
    property bool autoCloseOnMouseLeave: true
    property int mouseLeaveDelay: 1000  // 1 second delay before auto-close
    
    // Ensure the window behaves as a floating window in Hyprland
    HyprlandWindow.opacity: 0.95
    
    // Services passed from parent
    property var themeService: null
    property var configService: null
    property var shellRoot: null
    
    // Signals
    signal closed()
    
    // Background
    Rectangle {
        anchors.fill: parent
        color: themeService ? themeService.getThemeProperty("colors", "background") || "#1e1e2e" : "#1e1e2e"
        radius: 12
        border.color: themeService ? themeService.getThemeProperty("colors", "border") || "#585b70" : "#585b70"
        border.width: 1
        
        // Header
        Rectangle {
            id: header
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            height: 60
            color: themeService ? themeService.getThemeProperty("colors", "surface") || "#313244" : "#313244"
            
            // Only round the top corners to match the parent's rounded top
            radius: 12
            
            // Clip the bottom corners by extending beyond the visible area
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
                anchors.leftMargin: 20
                text: "Settings"
                font.family: "Inter"
                font.pixelSize: 18
                font.weight: Font.DemiBold
                color: themeService ? themeService.getThemeProperty("colors", "text") || "#cdd6f4" : "#cdd6f4"
            }
            
            // Close button
            Rectangle {
                id: closeButton
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                anchors.rightMargin: 20
                width: 32
                height: 32
                radius: 16
                color: closeButtonMouse.containsMouse ? 
                       (themeService ? themeService.getThemeProperty("colors", "error") || "#f38ba8" : "#f38ba8") :
                       (themeService ? themeService.getThemeProperty("colors", "surfaceAlt") || "#45475a" : "#45475a")
                
                Text {
                    anchors.centerIn: parent
                    text: "×"
                    font.pixelSize: 18
                    font.weight: Font.Bold
                    color: themeService ? themeService.getThemeProperty("colors", "text") || "#cdd6f4" : "#cdd6f4"
                }
                
                MouseArea {
                    id: closeButtonMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: hide()
                }
            }
        }
        
        // Content
        Column {
            anchors.top: header.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.margins: 20
            anchors.topMargin: 20
            spacing: 16
            
            // Performance Metrics Section Header
            Text {
                text: "Performance"
                font.family: "Inter"
                font.pixelSize: 16
                font.weight: Font.DemiBold
                color: themeService ? themeService.getThemeProperty("colors", "primary") || "#89b4fa" : "#89b4fa"
            }
            
            // Theme Selection
            Rectangle {
                width: parent.width
                height: 60
                radius: 8
                color: themeService ? themeService.getThemeProperty("colors", "surface") || "#313244" : "#313244"
                border.color: themeService ? themeService.getThemeProperty("colors", "border") || "#585b70" : "#585b70"
                border.width: 1
                
                Row {
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.leftMargin: 16
                    spacing: 12
                    
                    Text {
                        text: "🎨"
                        font.pixelSize: 16
                    }
                    
                    Column {
                        spacing: 2
                        
                        Text {
                            text: "Theme"
                            font.family: "Inter"
                            font.pixelSize: 14
                            font.weight: Font.Medium
                            color: themeService ? themeService.getThemeProperty("colors", "text") || "#cdd6f4" : "#cdd6f4"
                        }
                        
                        Text {
                            text: themeService ? themeService.activeTheme : "Loading..."
                            font.family: "Inter"
                            font.pixelSize: 11
                            color: themeService ? themeService.getThemeProperty("colors", "textAlt") || "#bac2de" : "#bac2de"
                        }
                    }
                }
                
                // Theme carousel button
                Rectangle {
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.rightMargin: 16
                    width: 80
                    height: 24
                    radius: 12
                    color: themeService ? themeService.getThemeProperty("colors", "primary") || "#89b4fa" : "#89b4fa"
                    
                    Text {
                        anchors.centerIn: parent
                        text: "Browse"
                        font.family: "Inter"
                        font.pixelSize: 10
                        font.weight: Font.Medium
                        color: themeService ? themeService.getThemeProperty("colors", "onPrimary") || "#1e1e2e" : "#1e1e2e"
                    }
                    
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        hoverEnabled: true
                        
                        onEntered: {
                            parent.opacity = 0.8
                        }
                        onExited: {
                            parent.opacity = 1.0
                        }
                        
                        onClicked: {
                            // Show global theme dropdown
                            if (shellRoot) {
                                shellRoot.showThemeDropdown()
                            }
                        }
                    }
                    
                    Behavior on color {
                        ColorAnimation { duration: 200; easing.type: Easing.OutCubic }
                    }
                }
            }
            
            
            // Performance Metrics Toggle
            Rectangle {
                width: parent.width
                height: 60
                radius: 8
                color: themeService ? themeService.getThemeProperty("colors", "surface") || "#313244" : "#313244"
                border.color: themeService ? themeService.getThemeProperty("colors", "border") || "#585b70" : "#585b70"
                border.width: 1
                
                Row {
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.leftMargin: 16
                    spacing: 12
                    
                    Text {
                        text: "📊"
                        font.pixelSize: 16
                    }
                    
                    Column {
                        spacing: 2
                        
                        Text {
                            text: "Performance Metrics"
                            font.family: "Inter"
                            font.pixelSize: 14
                            font.weight: Font.Medium
                            color: themeService ? themeService.getThemeProperty("colors", "text") || "#cdd6f4" : "#cdd6f4"
                        }
                        
                        Text {
                            text: "Show CPU, RAM, and storage usage in panel"
                            font.family: "Inter"
                            font.pixelSize: 11
                            color: themeService ? themeService.getThemeProperty("colors", "textAlt") || "#bac2de" : "#bac2de"
                        }
                    }
                }
                
                // Toggle switch
                Rectangle {
                    id: metricsToggle
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.rightMargin: 16
                    width: 48
                    height: 24
                    radius: 12
                    color: configService && configService.getValue("developer.showPerformanceMetrics", true) ?
                           (themeService ? themeService.getThemeProperty("colors", "primary") || "#89b4fa" : "#89b4fa") :
                           (themeService ? themeService.getThemeProperty("colors", "surfaceAlt") || "#45475a" : "#45475a")
                    
                    Rectangle {
                        width: 20
                        height: 20
                        radius: 10
                        color: themeService ? themeService.getThemeProperty("colors", "background") || "#1e1e2e" : "#1e1e2e"
                        anchors.verticalCenter: parent.verticalCenter
                        x: configService && configService.getValue("developer.showPerformanceMetrics", true) ? 26 : 2
                        
                        Behavior on x {
                            NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
                        }
                    }
                    
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (configService) {
                                const currentValue = configService.getValue("developer.showPerformanceMetrics", true)
                                configService.setValue("developer.showPerformanceMetrics", !currentValue)
                                configService.saveConfig()
                                console.log("Performance metrics", !currentValue ? "enabled" : "disabled")
                            }
                        }
                    }
                    
                    Behavior on color {
                        ColorAnimation { duration: 200; easing.type: Easing.OutCubic }
                    }
                }
            }
        }
    }
    
    // Auto-close timer for mouse leave behavior
    Timer {
        id: autoCloseTimer
        interval: mouseLeaveDelay
        repeat: false
        onTriggered: {
            if (autoCloseOnMouseLeave && !overlayMouseArea.containsMouse) {
                hide()
            }
        }
    }
    
    // Mouse area for detecting mouse leave
    MouseArea {
        id: overlayMouseArea
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.NoButton  // Don't consume clicks, just detect hover
        
        onEntered: {
            autoCloseTimer.stop()
        }
        
        onExited: {
            if (autoCloseOnMouseLeave) {
                autoCloseTimer.restart()
            }
        }
    }
    
    // Functions
    function show(anchorWindow, anchorRect) {
        if (anchorWindow) {
            anchor.window = anchorWindow
        }
        if (anchorRect) {
            anchor.rect.x = anchorRect.x || 0
            anchor.rect.y = anchorRect.y || 0
            anchor.rect.width = anchorRect.width || 32
            anchor.rect.height = anchorRect.height || 32
        }
        visible = true
    }
    
    function hide() {
        autoCloseTimer.stop()
        visible = false
        closed()
    }
    
    function toggle(anchorWindow, anchorRect) {
        if (visible) {
            hide()
        } else {
            show(anchorWindow, anchorRect)
        }
    }
}