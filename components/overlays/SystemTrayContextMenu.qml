import Quickshell
import Quickshell.Hyprland
import QtQuick
import QtQuick.Controls
import "../../services"

PopupWindow {
    id: systrayMenu
    
    // Window properties
    implicitWidth: 280
    implicitHeight: Math.min(350, systrayContent.contentHeight + 32)
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
        windows: [systrayMenu]
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
                id: systrayContent
                width: Math.max(parent.width - 16, 240)
                spacing: 12
                
                // Header
                Row {
                    width: parent.width
                    height: 32
                    spacing: 8
                    
                    Text {
                        text: "📱"
                        font.pixelSize: 20
                        anchors.verticalCenter: parent.verticalCenter
                    }
                    
                    Column {
                        anchors.verticalCenter: parent.verticalCenter
                        width: parent.width - 100
                        
                        Text {
                            text: "System Tray Settings"
                            font.pixelSize: 14
                            font.weight: Font.DemiBold
                            color: configService ? configService.getThemeProperty("colors", "text") || "#cdd6f4" : "#cdd6f4"
                        }
                        
                        Text {
                            text: "Configure system tray appearance"
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
                
                // Enable/Disable toggle
                Rectangle {
                    width: parent.width
                    height: 40
                    color: configService ? configService.getThemeProperty("colors", "surfaceAlt") || "#45475a" : "#45475a"
                    border.color: configService ? configService.getThemeProperty("colors", "border") || "#585b70" : "#585b70"
                    border.width: 1
                    radius: 8
                    
                    Row {
                        anchors.fill: parent
                        anchors.margins: 12
                        spacing: 12
                        
                        Text {
                            text: "Enable System Tray"
                            anchors.verticalCenter: parent.verticalCenter
                            font.pixelSize: 12
                            color: configService ? configService.getThemeProperty("colors", "text") || "#cdd6f4" : "#cdd6f4"
                            width: parent.width - 60
                        }
                        
                        Rectangle {
                            width: 40
                            height: 20
                            radius: 10
                            color: getSystrayEnabled() ? "#a6e3a1" : (configService ? configService.getThemeProperty("colors", "border") || "#585b70" : "#585b70")
                            border.width: 1
                            border.color: configService ? configService.getThemeProperty("colors", "border") || "#585b70" : "#585b70"
                            
                            Rectangle {
                                width: 16
                                height: 16
                                radius: 8
                                color: "#ffffff"
                                anchors.verticalCenter: parent.verticalCenter
                                x: getSystrayEnabled() ? parent.width - width - 2 : 2
                                
                                Behavior on x {
                                    NumberAnimation { duration: 150 }
                                }
                            }
                            
                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: toggleSystrayEnabled()
                            }
                        }
                    }
                }
                
                // Icon size setting
                Column {
                    width: parent.width
                    spacing: 8
                    
                    Text {
                        text: "Icon Size: " + getSystrayIconSize() + "px"
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
                                text: "16"
                                font.pixelSize: 10
                                color: configService ? configService.getThemeProperty("colors", "textAlt") || "#bac2de" : "#bac2de"
                                anchors.verticalCenter: parent.verticalCenter
                            }
                            
                            Slider {
                                id: iconSizeSlider
                                width: 160
                                height: 20
                                from: 16
                                to: 32
                                stepSize: 2
                                value: getSystrayIconSize()
                                anchors.verticalCenter: parent.verticalCenter
                                
                                onValueChanged: {
                                    if (configService && Math.abs(value - getSystrayIconSize()) > 0.1) {
                                        Qt.callLater(() => setSystrayIconSize(Math.round(value)))
                                    }
                                }
                                
                                background: Rectangle {
                                    x: iconSizeSlider.leftPadding
                                    y: iconSizeSlider.topPadding + iconSizeSlider.availableHeight / 2 - height / 2
                                    implicitWidth: 200
                                    implicitHeight: 4
                                    width: iconSizeSlider.availableWidth
                                    height: implicitHeight
                                    radius: 2
                                    color: configService ? configService.getThemeProperty("colors", "border") || "#585b70" : "#585b70"
                                    
                                    Rectangle {
                                        width: iconSizeSlider.visualPosition * parent.width
                                        height: parent.height
                                        color: "#a6e3a1"
                                        radius: 2
                                    }
                                }
                                
                                handle: Rectangle {
                                    x: iconSizeSlider.leftPadding + iconSizeSlider.visualPosition * (iconSizeSlider.availableWidth - width)
                                    y: iconSizeSlider.topPadding + iconSizeSlider.availableHeight / 2 - height / 2
                                    implicitWidth: 16
                                    implicitHeight: 16
                                    radius: 8
                                    color: iconSizeSlider.pressed ? "#a6e3a1" : "#89b4fa"
                                    border.color: "#45475a"
                                }
                            }
                            
                            Text {
                                text: "32"
                                font.pixelSize: 10
                                color: configService ? configService.getThemeProperty("colors", "textAlt") || "#bac2de" : "#bac2de"
                                anchors.verticalCenter: parent.verticalCenter
                            }
                        }
                    }
                }
                
                // Spacing setting
                Column {
                    width: parent.width
                    spacing: 8
                    
                    Text {
                        text: "Icon Spacing: " + getSystraySpacing() + "px"
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
                                text: "2"
                                font.pixelSize: 10
                                color: configService ? configService.getThemeProperty("colors", "textAlt") || "#bac2de" : "#bac2de"
                                anchors.verticalCenter: parent.verticalCenter
                            }
                            
                            Slider {
                                id: spacingSlider
                                width: 160
                                height: 20
                                from: 2
                                to: 12
                                stepSize: 1
                                value: getSystraySpacing()
                                anchors.verticalCenter: parent.verticalCenter
                                
                                onValueChanged: {
                                    if (configService && Math.abs(value - getSystraySpacing()) > 0.1) {
                                        Qt.callLater(() => setSystraySpacing(Math.round(value)))
                                    }
                                }
                                
                                background: Rectangle {
                                    x: spacingSlider.leftPadding
                                    y: spacingSlider.topPadding + spacingSlider.availableHeight / 2 - height / 2
                                    implicitWidth: 200
                                    implicitHeight: 4
                                    width: spacingSlider.availableWidth
                                    height: implicitHeight
                                    radius: 2
                                    color: configService ? configService.getThemeProperty("colors", "border") || "#585b70" : "#585b70"
                                    
                                    Rectangle {
                                        width: spacingSlider.visualPosition * parent.width
                                        height: parent.height
                                        color: "#a6e3a1"
                                        radius: 2
                                    }
                                }
                                
                                handle: Rectangle {
                                    x: spacingSlider.leftPadding + spacingSlider.visualPosition * (spacingSlider.availableWidth - width)
                                    y: spacingSlider.topPadding + spacingSlider.availableHeight / 2 - height / 2
                                    implicitWidth: 16
                                    implicitHeight: 16
                                    radius: 8
                                    color: spacingSlider.pressed ? "#a6e3a1" : "#89b4fa"
                                    border.color: "#45475a"
                                }
                            }
                            
                            Text {
                                text: "12"
                                font.pixelSize: 10
                                color: configService ? configService.getThemeProperty("colors", "textAlt") || "#bac2de" : "#bac2de"
                                anchors.verticalCenter: parent.verticalCenter
                            }
                        }
                    }
                }
                
                // Tooltips toggle
                Rectangle {
                    width: parent.width
                    height: 40
                    color: configService ? configService.getThemeProperty("colors", "surfaceAlt") || "#45475a" : "#45475a"
                    border.color: configService ? configService.getThemeProperty("colors", "border") || "#585b70" : "#585b70"
                    border.width: 1
                    radius: 8
                    
                    Row {
                        anchors.fill: parent
                        anchors.margins: 12
                        spacing: 12
                        
                        Text {
                            text: "Show Tooltips"
                            anchors.verticalCenter: parent.verticalCenter
                            font.pixelSize: 12
                            color: configService ? configService.getThemeProperty("colors", "text") || "#cdd6f4" : "#cdd6f4"
                            width: parent.width - 60
                        }
                        
                        Rectangle {
                            width: 40
                            height: 20
                            radius: 10
                            color: getSystrayTooltips() ? "#a6e3a1" : (configService ? configService.getThemeProperty("colors", "border") || "#585b70" : "#585b70")
                            border.width: 1
                            border.color: configService ? configService.getThemeProperty("colors", "border") || "#585b70" : "#585b70"
                            
                            Rectangle {
                                width: 16
                                height: 16
                                radius: 8
                                color: "#ffffff"
                                anchors.verticalCenter: parent.verticalCenter
                                x: getSystrayTooltips() ? parent.width - width - 2 : 2
                                
                                Behavior on x {
                                    NumberAnimation { duration: 150 }
                                }
                            }
                            
                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: toggleSystrayTooltips()
                            }
                        }
                    }
                }
            }
        }
    }
    
    // Functions
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
    
    // Configuration helpers
    function getSystrayEnabled() {
        return configService ? configService.getValue("widgets.systray.enabled", true) : true
    }
    
    function toggleSystrayEnabled() {
        if (configService) {
            const newValue = !getSystrayEnabled()
            configService.setValue("widgets.systray.enabled", newValue)
            configService.saveConfig()
        }
    }
    
    function getSystrayIconSize() {
        return configService ? configService.getValue("widgets.systray.iconSize", 20) : 20
    }
    
    function setSystrayIconSize(size) {
        if (configService) {
            configService.setValue("widgets.systray.iconSize", size)
            configService.saveConfig()
        }
    }
    
    function getSystraySpacing() {
        return configService ? configService.getValue("widgets.systray.spacing", 4) : 4
    }
    
    function setSystraySpacing(spacing) {
        if (configService) {
            configService.setValue("widgets.systray.spacing", spacing)
            configService.saveConfig()
        }
    }
    
    function getSystrayTooltips() {
        return configService ? configService.getValue("widgets.systray.showTooltips", true) : true
    }
    
    function toggleSystrayTooltips() {
        if (configService) {
            const newValue = !getSystrayTooltips()
            configService.setValue("widgets.systray.showTooltips", newValue)
            configService.saveConfig()
        }
    }
}