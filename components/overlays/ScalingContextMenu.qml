import Quickshell
import Quickshell.Hyprland
import QtQuick
import QtQuick.Controls
import "../../services"

PopupWindow {
    id: scalingMenu
    
    // Window properties
    implicitWidth: 280
    implicitHeight: Math.max(100, Math.min(400, scalingContent.contentHeight + 32))
    visible: false
    color: "transparent"
    
    // Services
    property var configService: ConfigService
    
    // Signals
    signal closed()
    
    // Anchor configuration
    anchor {
        window: null
        rect { x: 0; y: 0; width: 1; height: 1 }
        edges: Edges.Top | Edges.Left
        gravity: Edges.Bottom | Edges.Right
        adjustment: PopupAdjustment.All
        margins { left: 8; right: 8; top: 8; bottom: 8 }
    }
    
    // Focus grab for dismissal
    HyprlandFocusGrab {
        id: focusGrab
        windows: [scalingMenu]
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
        
        ScrollView {
            id: scrollView
            anchors.fill: parent
            anchors.margins: 16
            clip: true
            
            Component.onCompleted: {
                ScrollBar.horizontal.policy = ScrollBar.AlwaysOff
                ScrollBar.vertical.policy = ScrollBar.AsNeeded
            }
            
            Column {
                id: scalingContent
                width: Math.max(parent.width - 16, 240)
                spacing: 12
                
                // Header
                Row {
                    width: parent.width
                    height: 32
                    spacing: 8
                    
                    Text {
                        text: "🔍"
                        font.pixelSize: 20
                        anchors.verticalCenter: parent.verticalCenter
                    }
                    
                    Column {
                        anchors.verticalCenter: parent.verticalCenter
                        width: parent.width - 100
                        
                        Text {
                            text: "Display Scaling"
                            font.pixelSize: 14
                            font.weight: Font.DemiBold
                            color: configService ? configService.getThemeProperty("colors", "text") || "#cdd6f4" : "#cdd6f4"
                        }
                        
                        Text {
                            text: "Adjust UI size for different screens"
                            font.pixelSize: 10
                            color: configService ? configService.getThemeProperty("colors", "textAlt") || "#bac2de" : "#bac2de"
                        }
                    }
                    
                    // Close button
                    Rectangle {
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
                    }
                }
                
                // Current scaling info
                Rectangle {
                    width: parent.width
                    height: 60
                    color: configService ? configService.getThemeProperty("colors", "surfaceAlt") || "#45475a" : "#45475a"
                    border.color: configService ? configService.getThemeProperty("colors", "border") || "#585b70" : "#585b70"
                    border.width: 1
                    radius: 8
                    
                    Column {
                        anchors.centerIn: parent
                        spacing: 4
                        
                        Text {
                            text: "Current Scale: " + (configService ? (configService.globalScale * 100).toFixed(0) + "%" : "100%")
                            font.pixelSize: 12
                            font.weight: Font.Medium
                            color: configService ? configService.getThemeProperty("colors", "text") || "#cdd6f4" : "#cdd6f4"
                            anchors.horizontalCenter: parent.horizontalCenter
                        }
                        
                        Text {
                            text: getScreenInfo()
                            font.pixelSize: 10
                            color: configService ? configService.getThemeProperty("colors", "textAlt") || "#bac2de" : "#bac2de"
                            anchors.horizontalCenter: parent.horizontalCenter
                        }
                    }
                }
                
                // Preset buttons
                Text {
                    text: "Quick Presets:"
                    font.pixelSize: 12
                    font.weight: Font.DemiBold
                    color: configService ? configService.getThemeProperty("colors", "text") || "#cdd6f4" : "#cdd6f4"
                }
                
                Row {
                    width: parent.width
                    spacing: 8
                    
                    ScalingButton {
                        width: (parent.width - 16) / 3
                        label: "Small\n75%"
                        scale: 0.75
                        onClicked: setGlobalScale(0.75)
                    }
                    
                    ScalingButton {
                        width: (parent.width - 16) / 3
                        label: "Normal\n100%"
                        scale: 1.0
                        onClicked: setGlobalScale(1.0)
                    }
                    
                    ScalingButton {
                        width: (parent.width - 16) / 3
                        label: "Large\n125%"
                        scale: 1.25
                        onClicked: setGlobalScale(1.25)
                    }
                }
                
                // Custom scaling slider
                Text {
                    text: "Custom Scale:"
                    font.pixelSize: 12
                    font.weight: Font.DemiBold
                    color: configService ? configService.getThemeProperty("colors", "text") || "#cdd6f4" : "#cdd6f4"
                }
                
                Rectangle {
                    width: parent.width
                    height: 40
                    color: configService ? configService.getThemeProperty("colors", "surfaceAlt") || "#45475a" : "#45475a"
                    border.color: configService ? configService.getThemeProperty("colors", "border") || "#585b70" : "#585b70"
                    border.width: 1
                    radius: 6
                    
                    Row {
                        anchors.centerIn: parent
                        spacing: 12
                        
                        Text {
                            text: "50%"
                            font.pixelSize: 10
                            color: configService ? configService.getThemeProperty("colors", "textAlt") || "#bac2de" : "#bac2de"
                            anchors.verticalCenter: parent.verticalCenter
                        }
                        
                        Slider {
                            id: scaleSlider
                            width: 160
                            height: 20
                            from: 0.5
                            to: 2.0
                            stepSize: 0.05
                            value: configService ? configService.getValue("ui.scaling.globalScale", 1.0) : 1.0
                            anchors.verticalCenter: parent.verticalCenter
                            
                            onValueChanged: {
                                if (configService && Math.abs(value - configService.getValue("ui.scaling.globalScale", 1.0)) > 0.01) {
                                    Qt.callLater(() => setGlobalScale(value))
                                }
                            }
                            
                            background: Rectangle {
                                x: scaleSlider.leftPadding
                                y: scaleSlider.topPadding + scaleSlider.availableHeight / 2 - height / 2
                                implicitWidth: 200
                                implicitHeight: 4
                                width: scaleSlider.availableWidth
                                height: implicitHeight
                                radius: 2
                                color: configService ? configService.getThemeProperty("colors", "border") || "#585b70" : "#585b70"
                                
                                Rectangle {
                                    width: scaleSlider.visualPosition * parent.width
                                    height: parent.height
                                    color: "#a6e3a1"
                                    radius: 2
                                }
                            }
                            
                            handle: Rectangle {
                                x: scaleSlider.leftPadding + scaleSlider.visualPosition * (scaleSlider.availableWidth - width)
                                y: scaleSlider.topPadding + scaleSlider.availableHeight / 2 - height / 2
                                implicitWidth: 16
                                implicitHeight: 16
                                radius: 8
                                color: scaleSlider.pressed ? "#a6e3a1" : "#89b4fa"
                                border.color: "#45475a"
                            }
                        }
                        
                        Text {
                            text: "200%"
                            font.pixelSize: 10
                            color: configService ? configService.getThemeProperty("colors", "textAlt") || "#bac2de" : "#bac2de"
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }
                }
                
                // Reset button
                Rectangle {
                    width: parent.width
                    height: 32
                    color: resetMouse.containsMouse ? "#f38ba8" : (configService ? configService.getThemeProperty("colors", "surfaceAlt") || "#45475a" : "#45475a")
                    border.color: configService ? configService.getThemeProperty("colors", "border") || "#585b70" : "#585b70"
                    border.width: 1
                    radius: 6
                    
                    Text {
                        anchors.centerIn: parent
                        text: "Reset to Auto-Detect"
                        font.pixelSize: 11
                        color: resetMouse.containsMouse ? "#1e1e2e" : (configService ? configService.getThemeProperty("colors", "text") || "#cdd6f4" : "#cdd6f4")
                    }
                    
                    MouseArea {
                        id: resetMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: resetScaling()
                    }
                    
                    Behavior on color {
                        ColorAnimation { duration: 150 }
                    }
                }
            }
        }
    }
    
    // Scaling button component
    component ScalingButton: Rectangle {
        property string label: ""
        property real scale: 1.0
        signal clicked()
        
        height: 50
        radius: 6
        color: buttonMouse.containsMouse ? "#a6e3a1" : (configService ? configService.getThemeProperty("colors", "surfaceAlt") || "#45475a" : "#45475a")
        border.color: Math.abs(scale - (configService ? configService.getValue("ui.scaling.globalScale", 1.0) : 1.0)) < 0.01 ? "#a6e3a1" : (configService ? configService.getThemeProperty("colors", "border") || "#585b70" : "#585b70")
        border.width: Math.abs(scale - (configService ? configService.getValue("ui.scaling.globalScale", 1.0) : 1.0)) < 0.01 ? 2 : 1
        
        Text {
            anchors.centerIn: parent
            text: label
            font.pixelSize: 11
            font.weight: Font.Medium
            color: buttonMouse.containsMouse ? "#1e1e2e" : (configService ? configService.getThemeProperty("colors", "text") || "#cdd6f4" : "#cdd6f4")
            horizontalAlignment: Text.AlignHCenter
        }
        
        MouseArea {
            id: buttonMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: parent.clicked()
        }
        
        Behavior on color {
            ColorAnimation { duration: 150 }
        }
        
        Behavior on border.color {
            ColorAnimation { duration: 150 }
        }
    }
    
    // Functions
    function show(anchorWindow, x, y) {
        if (!anchorWindow) {
            console.error("ScalingContextMenu: No anchor window provided")
            return
        }
        
        // Set anchor window first
        anchor.window = anchorWindow
        
        // Get screen dimensions safely
        let screenWidth = 1920
        let screenHeight = 1080
        
        try {
            if (anchorWindow.screen) {
                screenWidth = anchorWindow.screen.width || 1920
                screenHeight = anchorWindow.screen.height || 1080
            } else if (Quickshell.screens && Quickshell.screens.length > 0) {
                const primaryScreen = Quickshell.screens[0]
                screenWidth = primaryScreen.width || 1920
                screenHeight = primaryScreen.height || 1080
            }
        } catch (e) {
            console.warn("ScalingContextMenu: Error accessing screen properties, using defaults:", e)
        }
        
        // Ensure we have valid dimensions
        const menuWidth = Math.max(280, implicitWidth)
        const menuHeight = Math.max(100, implicitHeight)
        
        let popupX = Math.min(x || 0, screenWidth - menuWidth - 20)
        let popupY = Math.min(y || 0, screenHeight - menuHeight - 20)
        
        popupX = Math.max(20, popupX)
        popupY = Math.max(20, popupY)
        
        anchor.rect.x = popupX
        anchor.rect.y = popupY
        anchor.rect.width = 1
        anchor.rect.height = 1
        
        visible = true
        focusGrab.active = true
    }
    
    function hide() {
        visible = false
        focusGrab.active = false
        closed()
    }
    
    function setGlobalScale(scale) {
        if (configService) {
            console.log("Setting global scale to:", scale)
            configService.setValue("ui.scaling.globalScale", scale)
            configService.saveConfig()
        }
    }
    
    function resetScaling() {
        if (configService) {
            console.log("Resetting scaling to auto-detect")
            configService.setValue("ui.scaling.globalScale", 1.0)
            configService.setValue("ui.scaling.useCustomScaling", false)
            configService.saveConfig()
        }
    }
    
    function getScreenInfo() {
        const primaryScreen = Quickshell.screens[0]
        if (!primaryScreen) return "No screen detected"
        
        const width = primaryScreen.width
        const height = primaryScreen.height
        const dpr = primaryScreen.devicePixelRatio
        
        return `${width}×${height} (DPR: ${dpr.toFixed(2)})`
    }
}