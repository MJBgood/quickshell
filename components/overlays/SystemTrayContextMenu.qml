import Quickshell
import Quickshell.Hyprland
import QtQuick
import QtQuick.Controls
import "../../services"

PopupWindow {
    id: contextMenu
    
    // Services
    property var configService: ConfigService
    property string entityId: "systemTrayWidget"
    
    // Window properties
    implicitWidth: 280
    implicitHeight: Math.min(350, menuContent.contentHeight + 32)
    visible: false
    color: "transparent"
    
    // Signals
    signal closed()
    
    // Anchor configuration (EXACTLY as working examples)
    anchor {
        window: null
        rect { x: 0; y: 0; width: 1; height: 1 }
        edges: Edges.Top | Edges.Left
        gravity: Edges.Bottom | Edges.Right
        adjustment: PopupAdjustment.All
        margins { left: 8; right: 8; top: 8; bottom: 8 }
    }
    
    // Focus grab for dismissal (CRITICAL)
    HyprlandFocusGrab {
        id: focusGrab
        windows: [contextMenu]
        onCleared: hide()
    }
    
    // Main container
    Rectangle {
        anchors.fill: parent
        color: configService ? configService.getThemeProperty("colors", "surface") || "#313244" : "#313244"
        border.color: configService ? configService.getThemeProperty("colors", "border") || "#585b70" : "#585b70"
        border.width: 1
        radius: 12
        
        ScrollView {
            anchors.fill: parent
            anchors.margins: 16
            clip: true
            
            Component.onCompleted: {
                ScrollBar.horizontal.policy = ScrollBar.AlwaysOff
                ScrollBar.vertical.policy = ScrollBar.AsNeeded
            }
            
            Column {
                id: menuContent
                width: Math.max(parent.width - 16, 240)
                spacing: 12
                
                // Header
                Row {
                    width: parent.width
                    height: 32
                    spacing: 8
                    
                    // System tray settings icon (geometric)
                    Item {
                        width: 20
                        height: 20
                        anchors.verticalCenter: parent.verticalCenter
                        
                        // Grid icon representing system tray
                        Grid {
                            anchors.centerIn: parent
                            columns: 2
                            rows: 2
                            spacing: 2
                            
                            Repeater {
                                model: 4
                                Rectangle {
                                    width: 6
                                    height: 6
                                    color: configService ? configService.getThemeProperty("colors", "accent") || "#a6e3a1" : "#a6e3a1"
                                    radius: 1
                                }
                            }
                        }
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
                            color: getEnabled() ? "#a6e3a1" : (configService ? configService.getThemeProperty("colors", "border") || "#585b70" : "#585b70")
                            border.width: 1
                            border.color: configService ? configService.getThemeProperty("colors", "border") || "#585b70" : "#585b70"
                            
                            Rectangle {
                                width: 16
                                height: 16
                                radius: 8
                                color: "#ffffff"
                                anchors.verticalCenter: parent.verticalCenter
                                x: getEnabled() ? parent.width - width - 2 : 2
                                
                                Behavior on x {
                                    NumberAnimation { duration: 150 }
                                }
                            }
                            
                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: toggleEnabled()
                            }
                        }
                    }
                }
                
                // Icon size setting
                Column {
                    width: parent.width
                    spacing: 8
                    
                    Text {
                        text: "Icon Size: " + getIconSize() + "px"
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
                                value: getIconSize()
                                anchors.verticalCenter: parent.verticalCenter
                                
                                onValueChanged: {
                                    if (configService && Math.abs(value - getIconSize()) > 0.1) {
                                        Qt.callLater(() => setIconSize(Math.round(value)))
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
                        text: "Icon Spacing: " + getSpacing() + "px"
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
                                value: getSpacing()
                                anchors.verticalCenter: parent.verticalCenter
                                
                                onValueChanged: {
                                    if (configService && Math.abs(value - getSpacing()) > 0.1) {
                                        Qt.callLater(() => setSpacing(Math.round(value)))
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
                
                // Show Passive Items toggle
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
                            text: "Show Passive Items"
                            anchors.verticalCenter: parent.verticalCenter
                            font.pixelSize: 12
                            color: configService ? configService.getThemeProperty("colors", "text") || "#cdd6f4" : "#cdd6f4"
                            width: parent.width - 60
                        }
                        
                        Rectangle {
                            width: 40
                            height: 20
                            radius: 10
                            color: getShowPassive() ? "#a6e3a1" : (configService ? configService.getThemeProperty("colors", "border") || "#585b70" : "#585b70")
                            border.width: 1
                            border.color: configService ? configService.getThemeProperty("colors", "border") || "#585b70" : "#585b70"
                            
                            Rectangle {
                                width: 16
                                height: 16
                                radius: 8
                                color: "#ffffff"
                                anchors.verticalCenter: parent.verticalCenter
                                x: getShowPassive() ? parent.width - width - 2 : 2
                                
                                Behavior on x {
                                    NumberAnimation { duration: 150 }
                                }
                            }
                            
                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: toggleShowPassive()
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
                            color: getTooltips() ? "#a6e3a1" : (configService ? configService.getThemeProperty("colors", "border") || "#585b70" : "#585b70")
                            border.width: 1
                            border.color: configService ? configService.getThemeProperty("colors", "border") || "#585b70" : "#585b70"
                            
                            Rectangle {
                                width: 16
                                height: 16
                                radius: 8
                                color: "#ffffff"
                                anchors.verticalCenter: parent.verticalCenter
                                x: getTooltips() ? parent.width - width - 2 : 2
                                
                                Behavior on x {
                                    NumberAnimation { duration: 150 }
                                }
                            }
                            
                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: toggleTooltips()
                            }
                        }
                    }
                }
            }
        }
    }
    
    // Standard show/hide functions (EXACTLY as working examples)
    function show(anchorWindow, x, y) {
        anchor.window = anchorWindow
        
        if (anchorWindow && anchorWindow.screen) {
            const screenWidth = anchorWindow.screen.width
            const screenHeight = anchorWindow.screen.height
            
            let popupX = Math.min(x || 0, screenWidth - implicitWidth - 20)
            let popupY = Math.min(y || 0, screenHeight - implicitHeight - 20)
            
            popupX = Math.max(20, popupX)
            popupY = Math.max(20, popupY)
            
            anchor.rect.x = popupX
            anchor.rect.y = popupY
            anchor.rect.width = 1
            anchor.rect.height = 1
        } else {
            anchor.rect.x = x || 0
            anchor.rect.y = y || 0
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
    
    // Entity-aware configuration helpers
    function getEnabled() {
        return configService ? configService.getEntityProperty(entityId, "enabled", true) : true
    }
    
    function toggleEnabled() {
        if (configService) {
            const newValue = !getEnabled()
            configService.setEntityProperty(entityId, "enabled", newValue)
            configService.saveConfig()
        }
    }
    
    function getIconSize() {
        return configService ? configService.getEntityStyle(entityId, "iconSize", "auto", 20) : 20
    }
    
    function setIconSize(size) {
        if (configService) {
            configService.setEntityStyle(entityId, "iconSize", size)
            configService.saveConfig()
        }
    }
    
    function getSpacing() {
        return configService ? configService.getEntityStyle(entityId, "spacing", "auto", 4) : 4
    }
    
    function setSpacing(spacing) {
        if (configService) {
            configService.setEntityStyle(entityId, "spacing", spacing)
            configService.saveConfig()
        }
    }
    
    function getShowPassive() {
        return configService ? configService.getEntityProperty(entityId, "showPassive", true) : true
    }
    
    function toggleShowPassive() {
        if (configService) {
            const newValue = !getShowPassive()
            configService.setEntityProperty(entityId, "showPassive", newValue)
            configService.saveConfig()
        }
    }
    
    function getTooltips() {
        return configService ? configService.getEntityProperty(entityId, "showTooltips", true) : true
    }
    
    function toggleTooltips() {
        if (configService) {
            const newValue = !getTooltips()
            configService.setEntityProperty(entityId, "showTooltips", newValue)
            configService.saveConfig()
        }
    }
}