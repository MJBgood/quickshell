import Quickshell
import Quickshell.Hyprland
import QtQuick
import QtQuick.Controls
import "../../services"

PopupWindow {
    id: scalingMenu
    
    implicitWidth: 280
    implicitHeight: 350
    visible: false
    color: "transparent"
    
    // Services
    property var configService: ConfigService
    property var displayScalingService: DisplayScalingService
    
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
                            text: "Current Scale: " + getCurrentScale()
                            font.pixelSize: 12
                            font.weight: Font.Medium
                            color: configService ? configService.getThemeProperty("colors", "text") || "#cdd6f4" : "#cdd6f4"
                            anchors.horizontalCenter: parent.horizontalCenter
                        }
                        
                        Text {
                            text: getDisplayInfo()
                            font.pixelSize: 10
                            color: configService ? configService.getThemeProperty("colors", "textAlt") || "#bac2de" : "#bac2de"
                            anchors.horizontalCenter: parent.horizontalCenter
                        }
                    }
                }
                
                // DPI recommendation and explanation
                Rectangle {
                    visible: displayScalingService && displayScalingService.ready
                    width: parent.width
                    height: explanationColumn.implicitHeight + 16
                    color: "transparent"
                    border.color: "#a6e3a1"
                    border.width: 1
                    radius: 6
                    
                    Column {
                        id: explanationColumn
                        anchors.centerIn: parent
                        width: parent.width - 16
                        spacing: 4
                        
                        Text {
                            text: "💡 Smart Scaling Analysis"
                            font.pixelSize: 11
                            font.weight: Font.DemiBold
                            color: "#a6e3a1"
                            anchors.horizontalCenter: parent.horizontalCenter
                        }
                        
                        Text {
                            visible: displayScalingService && displayScalingService.ready
                            text: getScalingExplanation()
                            font.pixelSize: 9
                            color: configService ? configService.getThemeProperty("colors", "textAlt") || "#bac2de" : "#bac2de"
                            anchors.horizontalCenter: parent.horizontalCenter
                            horizontalAlignment: Text.AlignHCenter
                            wrapMode: Text.WordWrap
                            width: parent.width
                        }
                        
                        Rectangle {
                            visible: displayScalingService && displayScalingService.ready && getRecommendedUserScale() !== getCurrentUserScale()
                            width: parent.width * 0.8
                            height: 24
                            anchors.horizontalCenter: parent.horizontalCenter
                            color: "#a6e3a1"
                            radius: 4
                            
                            Text {
                                anchors.centerIn: parent
                                text: "Apply " + (getRecommendedUserScale() * 100).toFixed(0) + "%"
                                font.pixelSize: 10
                                font.weight: Font.Medium
                                color: "#1e1e2e"
                            }
                            
                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    if (displayScalingService && displayScalingService.ready) {
                                        setGlobalScale(getRecommendedUserScale())
                                    }
                                }
                            }
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
                        isRecommended: displayScalingService && displayScalingService.ready && Math.abs(displayScalingService.recommendedScale - 0.75) < 0.1
                        onClicked: setGlobalScale(0.75)
                    }
                    
                    ScalingButton {
                        width: (parent.width - 16) / 3
                        label: "Normal\n100%"
                        scale: 1.0
                        isRecommended: displayScalingService && displayScalingService.ready && Math.abs(displayScalingService.recommendedScale - 1.0) < 0.1
                        onClicked: setGlobalScale(1.0)
                    }
                    
                    ScalingButton {
                        width: (parent.width - 16) / 3
                        label: "Large\n125%"
                        scale: 1.25
                        isRecommended: displayScalingService && displayScalingService.ready && Math.abs(displayScalingService.recommendedScale - 1.25) < 0.1
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
                            value: configService ? configService.getUISetting("scaling", "globalScale", 1.0) : 1.0
                            anchors.verticalCenter: parent.verticalCenter
                            
                            onValueChanged: {
                                if (configService && Math.abs(value - configService.getUISetting("scaling", "globalScale", 1.0)) > 0.01) {
                                    // Update the scale without hiding the menu
                                    updateGlobalScale(value)
                                }
                            }
                            
                            // Update the slider value when config changes
                            Connections {
                                target: configService
                                function onConfigChanged() {
                                    if (configService) {
                                        const userScale = configService.getUISetting("scaling", "globalScale", 1.0)
                                        if (Math.abs(scaleSlider.value - userScale) > 0.01) {
                                            scaleSlider.value = userScale
                                        }
                                    }
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
        property bool isRecommended: false
        signal clicked()
        
        height: 50
        radius: 6
        color: buttonMouse.containsMouse ? "#a6e3a1" : (configService ? configService.getThemeProperty("colors", "surfaceAlt") || "#45475a" : "#45475a")
        border.color: {
            const userScale = configService ? configService.getUISetting("scaling", "globalScale", 1.0) : 1.0
            const isCurrent = Math.abs(scale - userScale) < 0.01
            if (isCurrent) return "#a6e3a1"
            if (isRecommended) return "#fab387"  // Orange for recommended
            return configService ? configService.getThemeProperty("colors", "border") || "#585b70" : "#585b70"
        }
        border.width: {
            const userScale = configService ? configService.getUISetting("scaling", "globalScale", 1.0) : 1.0
            const isCurrent = Math.abs(scale - userScale) < 0.01
            return (isCurrent || isRecommended) ? 2 : 1
        }
        
        Column {
            anchors.centerIn: parent
            spacing: 2
            
            Text {
                text: label
                font.pixelSize: 11
                font.weight: Font.Medium
                color: buttonMouse.containsMouse ? "#1e1e2e" : (configService ? configService.getThemeProperty("colors", "text") || "#cdd6f4" : "#cdd6f4")
                horizontalAlignment: Text.AlignHCenter
                anchors.horizontalCenter: parent.horizontalCenter
            }
            
            Text {
                visible: isRecommended
                text: "💡"
                font.pixelSize: 10
                anchors.horizontalCenter: parent.horizontalCenter
            }
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
        anchor.window = anchorWindow
        anchor.rect.x = x || 0
        anchor.rect.y = y || 0
        visible = true
        focusGrab.active = true
    }
    
    function hide() {
        visible = false
        focusGrab.active = false
        closed()
    }
    
    function setGlobalScale(scale) {
        updateGlobalScale(scale)
        // Hide menu immediately
        hide()
    }
    
    function updateGlobalScale(scale) {
        if (!configService) return
        
        // Clamp scale to safe bounds
        const clampedScale = Math.max(0.5, Math.min(2.0, scale))
        
        console.log("Setting global scale to:", clampedScale)
        
        // Set the new scale using the UI settings method
        configService.setUISetting("scaling", "globalScale", clampedScale)
        configService.saveConfig()
    }
    
    function resetScaling() {
        if (configService) {
            console.log("Resetting scaling to auto-detect")
            
            // Calculate user scale needed to achieve the recommended effective scale
            // Since globalScale = devicePixelRatio * userScale, we need:
            // userScale = recommendedScale / devicePixelRatio
            const primaryScreen = Quickshell.screens[0]
            const devicePixelRatio = primaryScreen ? primaryScreen.devicePixelRatio : 1.0
            const recommendedEffectiveScale = displayScalingService && displayScalingService.ready ? displayScalingService.recommendedScale : 1.0
            const userScale = recommendedEffectiveScale / devicePixelRatio
            
            console.log(`Auto-detect: devicePixelRatio=${devicePixelRatio}, recommendedEffectiveScale=${recommendedEffectiveScale}, calculated userScale=${userScale}`)
            
            configService.setUISetting("scaling", "globalScale", userScale)
            configService.setUISetting("scaling", "useCustomScaling", false)
            configService.saveConfig()
            
            hide()
        }
    }
    
    function getDisplayInfo() {
        const primaryScreen = Quickshell.screens[0]
        if (!primaryScreen) return "No screen detected"
        
        if (!displayScalingService || !displayScalingService.ready) {
            return `${primaryScreen.width}×${primaryScreen.height} (DPR: ${primaryScreen.devicePixelRatio.toFixed(2)})`
        }
        
        const dpi = displayScalingService.physicalDpi.toFixed(0)
        const category = displayScalingService.scaleReason
        const dpr = primaryScreen.devicePixelRatio.toFixed(2)
        return `${dpi} DPI • DPR: ${dpr} • ${category}`
    }
    
    function getCurrentScale() {
        if (!configService) return "100%"
        // Show the user scale (what they set), not the effective scale
        const userScale = configService.getUISetting("scaling", "globalScale", 1.0)
        return (userScale * 100).toFixed(0) + "%"
    }
    
    function getCurrentUserScale() {
        if (!configService) return 1.0
        return configService.getUISetting("scaling", "globalScale", 1.0)
    }
    
    function getRecommendedUserScale() {
        if (!displayScalingService || !displayScalingService.ready) return 1.0
        const primaryScreen = Quickshell.screens[0]
        const devicePixelRatio = primaryScreen ? primaryScreen.devicePixelRatio : 1.0
        return displayScalingService.recommendedScale / devicePixelRatio
    }
    
    function getScalingExplanation() {
        if (!displayScalingService || !displayScalingService.ready) return ""
        
        const primaryScreen = Quickshell.screens[0]
        if (!primaryScreen) return ""
        
        const dpi = displayScalingService.physicalDpi.toFixed(0)
        const dpr = primaryScreen.devicePixelRatio.toFixed(1)
        const recommendedEffective = displayScalingService.recommendedScale.toFixed(2)
        const recommendedUser = getRecommendedUserScale().toFixed(2)
        const currentUser = getCurrentUserScale().toFixed(2)
        const currentEffective = (getCurrentUserScale() * primaryScreen.devicePixelRatio).toFixed(2)
        
        return `${dpi} DPI screen needs ${recommendedEffective}x scaling\n` +
               `System DPR: ${dpr}x • User scale: ${recommendedUser}x = ${recommendedEffective}x effective\n` +
               `Current: ${currentUser}x user • ${currentEffective}x effective`
    }
}