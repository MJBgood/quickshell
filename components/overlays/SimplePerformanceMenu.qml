import Quickshell
import Quickshell.Widgets
import Quickshell.Hyprland
import QtQuick

PopupWindow {
    id: menu
    
    visible: false
    color: "transparent"
    implicitWidth: 200
    implicitHeight: menuContent.implicitHeight + 16
    
    // Services
    property var configService: ConfigService
    
    // Signals
    signal closed()
    
    // Simple focus grab
    HyprlandFocusGrab {
        id: focusGrab
        windows: [menu]
        onCleared: hide()
    }
    
    Rectangle {
        id: menuContent
        anchors.fill: parent
        color: configService ? configService.getThemeProperty("colors", "surface") || "#313244" : "#313244"
        border.color: configService ? configService.getThemeProperty("colors", "border") || "#585b70" : "#585b70"
        border.width: 1
        radius: 8
        
        Column {
            anchors.fill: parent
            anchors.margins: 8
            spacing: 2
            
            // Header
            Text {
                width: parent.width
                text: "Performance Monitor"
                font.pixelSize: 11
                font.weight: Font.DemiBold
                color: configService ? configService.getThemeProperty("colors", "text") || "#cdd6f4" : "#cdd6f4"
                horizontalAlignment: Text.AlignHCenter
            }
            
            Rectangle { width: parent.width; height: 1; color: configService ? configService.getThemeProperty("colors", "border") || "#585b70" : "#585b70" }
            
            // CPU Section
            Text {
                text: "💻 CPU"
                font.pixelSize: 10
                font.weight: Font.Medium
                color: configService ? configService.getThemeProperty("colors", "text") || "#cdd6f4" : "#cdd6f4"
            }
            
            SimpleMenuItem {
                width: parent.width
                text: "Enabled"
                checked: configService ? configService.getValue("performance.cpu.enabled", true) : true
                onToggled: { if (configService) { configService.setValue("performance.cpu.enabled", checked); configService.saveConfig() }}
                configService: menu.configService
            }
            
            SimpleMenuItem {
                width: parent.width
                text: "Show Icon"
                checked: configService ? configService.getValue("performance.cpu.showIcon", true) : true
                onToggled: { if (configService) { configService.setValue("performance.cpu.showIcon", checked); configService.saveConfig() }}
                configService: menu.configService
            }
            
            SimpleMenuItem {
                width: parent.width
                text: "Show Percentage"
                checked: configService ? configService.getValue("performance.cpu.showPercentage", true) : true
                onToggled: { if (configService) { configService.setValue("performance.cpu.showPercentage", checked); configService.saveConfig() }}
                configService: menu.configService
            }
            
            // RAM Section
            Text {
                text: "🧠 RAM"
                font.pixelSize: 10
                font.weight: Font.Medium
                color: configService ? configService.getThemeProperty("colors", "text") || "#cdd6f4" : "#cdd6f4"
                topPadding: 4
            }
            
            SimpleMenuItem {
                width: parent.width
                text: "Enabled"
                checked: configService ? configService.getValue("performance.ram.enabled", true) : true
                onToggled: { if (configService) { configService.setValue("performance.ram.enabled", checked); configService.saveConfig() }}
                configService: menu.configService
            }
            
            SimpleMenuItem {
                width: parent.width
                text: "Show Icon"
                checked: configService ? configService.getValue("performance.ram.showIcon", true) : true
                onToggled: { if (configService) { configService.setValue("performance.ram.showIcon", checked); configService.saveConfig() }}
                configService: menu.configService
            }
            
            SimpleMenuItem {
                width: parent.width
                text: "Show Percentage"
                checked: configService ? configService.getValue("performance.ram.showPercentage", true) : true
                onToggled: { if (configService) { configService.setValue("performance.ram.showPercentage", checked); configService.saveConfig() }}
                configService: menu.configService
            }
            
            // Storage Section
            Text {
                text: "💾 Storage"
                font.pixelSize: 10
                font.weight: Font.Medium
                color: configService ? configService.getThemeProperty("colors", "text") || "#cdd6f4" : "#cdd6f4"
                topPadding: 4
            }
            
            SimpleMenuItem {
                width: parent.width
                text: "Enabled"
                checked: configService ? configService.getValue("performance.storage.enabled", true) : true
                onToggled: { if (configService) { configService.setValue("performance.storage.enabled", checked); configService.saveConfig() }}
                configService: menu.configService
            }
            
            SimpleMenuItem {
                width: parent.width
                text: "Show Icon"
                checked: configService ? configService.getValue("performance.storage.showIcon", true) : true
                onToggled: { if (configService) { configService.setValue("performance.storage.showIcon", checked); configService.saveConfig() }}
                configService: menu.configService
            }
            
            SimpleMenuItem {
                width: parent.width
                text: "Show Bytes"
                checked: configService ? configService.getValue("performance.storage.showBytes", false) : false
                onToggled: { if (configService) { configService.setValue("performance.storage.showBytes", checked); configService.saveConfig() }}
                configService: menu.configService
            }
            
            Rectangle { width: parent.width; height: 1; color: configService ? configService.getThemeProperty("colors", "border") || "#585b70" : "#585b70"; topMargin: 4 }
            
            // Global Settings
            Text {
                text: "⚙️ Global"
                font.pixelSize: 10
                font.weight: Font.Medium
                color: configService ? configService.getThemeProperty("colors", "text") || "#cdd6f4" : "#cdd6f4"
                topPadding: 4
            }
            
            SimpleMenuItem {
                width: parent.width
                text: "Layout: " + (configService ? configService.getValue("performance.layout", "horizontal") : "horizontal")
                onClicked: {
                    if (configService) {
                        const current = configService.getValue("performance.layout", "horizontal")
                        const newLayout = current === "horizontal" ? "vertical" : "horizontal"
                        configService.setValue("performance.layout", newLayout)
                        configService.saveConfig()
                    }
                }
                configService: menu.configService
            }
        }
    }
    
    // Simple functions
    function show(anchorWindow, x, y) {
        if (anchorWindow) {
            anchor.window = anchorWindow
            anchor.rect.x = x || 0
            anchor.rect.y = y || 0
        }
        visible = true
        focusGrab.active = true
    }
    
    function hide() {
        focusGrab.active = false
        visible = false
        closed()
    }
}

// Simple menu item component
component SimpleMenuItem: Rectangle {
    property string text: ""
    property bool checked: false
    property var configService: ConfigService
    signal toggled(bool checked)
    signal clicked()
    
    height: 20
    color: mouseArea.containsMouse ? (configService ? configService.getThemeProperty("colors", "surfaceAlt") || "#45475a" : "#45475a") : "transparent"
    
    Row {
        anchors.left: parent.left
        anchors.leftMargin: 8
        anchors.verticalCenter: parent.verticalCenter
        spacing: 8
        
        Text {
            text: parent.parent.checked ? "✓" : "○"
            color: parent.parent.checked ? "#a6e3a1" : (configService ? configService.getThemeProperty("colors", "textAlt") || "#bac2de" : "#bac2de")
            font.pixelSize: 9
            anchors.verticalCenter: parent.verticalCenter
        }
        
        Text {
            text: parent.parent.text
            color: configService ? configService.getThemeProperty("colors", "text") || "#cdd6f4" : "#cdd6f4"
            font.pixelSize: 9
            anchors.verticalCenter: parent.verticalCenter
        }
    }
    
    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        onClicked: {
            if (parent.checked !== undefined) {
                parent.checked = !parent.checked
                parent.toggled(parent.checked)
            } else {
                parent.clicked()
            }
        }
    }
}