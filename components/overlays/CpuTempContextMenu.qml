import Quickshell
import Quickshell.Hyprland
import QtQuick
import QtQuick.Controls
import "../../services"

PopupWindow {
    id: contextMenu
    
    // Services
    property var temperatureService: null
    property var themeService: null
    
    // Standard window properties
    implicitWidth: 220
    implicitHeight: Math.min(350, menuContent.contentHeight + 32)
    visible: false
    color: "transparent"
    
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
    
    // Content structure
    Rectangle {
        anchors.fill: parent
        color: themeService ? themeService.getThemeProperty("colors", "surface") || "#313244" : "#313244"
        border.color: themeService ? themeService.getThemeProperty("colors", "border") || "#6c7086" : "#6c7086"
        border.width: 1
        radius: 8
        
        ScrollView {
            id: menuContent
            anchors.fill: parent
            anchors.margins: 16
            
            Column {
                width: menuContent.width
                spacing: 12
                
                Text {
                    text: "CPU Temperature"
                    font.family: "Inter"
                    font.pixelSize: 14
                    font.weight: Font.DemiBold
                    color: themeService ? themeService.getThemeProperty("colors", "text") || "#cdd6f4" : "#cdd6f4"
                }
                
                Rectangle {
                    width: parent.width
                    height: 1
                    color: themeService ? themeService.getThemeProperty("colors", "border") || "#6c7086" : "#6c7086"
                }
                
                // Current temperature display
                Column {
                    width: parent.width
                    spacing: 8
                    
                    Text {
                        text: "Current Temperature"
                        font.family: "Inter"
                        font.pixelSize: 12
                        font.weight: Font.Medium
                        color: themeService ? themeService.getThemeProperty("colors", "text") || "#cdd6f4" : "#cdd6f4"
                    }
                    
                    Text {
                        text: temperatureService ? `${Math.round(temperatureService.cpuTemp)}°C` : "--°C"
                        font.family: "Inter"
                        font.pixelSize: 18
                        font.weight: Font.Bold
                        color: {
                            if (!temperatureService) return themeService ? themeService.getThemeProperty("colors", "text") || "#cdd6f4" : "#cdd6f4"
                            const status = temperatureService.getCpuStatus()
                            switch (status) {
                                case "cool": return themeService ? themeService.getThemeProperty("colors", "success") || "#a6e3a1" : "#a6e3a1"
                                case "warm": return themeService ? themeService.getThemeProperty("colors", "warning") || "#f9e2af" : "#f9e2af"
                                case "hot": return themeService ? themeService.getThemeProperty("colors", "error") || "#f38ba8" : "#f38ba8"
                                case "critical": return themeService ? themeService.getThemeProperty("colors", "error") || "#f38ba8" : "#f38ba8"
                                default: return themeService ? themeService.getThemeProperty("colors", "text") || "#cdd6f4" : "#cdd6f4"
                            }
                        }
                    }
                    
                    Text {
                        text: {
                            if (!temperatureService) return "Status: Unknown"
                            const status = temperatureService.getCpuStatus()
                            switch (status) {
                                case "cool": return "Status: Cool"
                                case "warm": return "Status: Warm" 
                                case "hot": return "Status: Hot"
                                case "critical": return "Status: Critical"
                                default: return "Status: Unknown"
                            }
                        }
                        font.family: "Inter"
                        font.pixelSize: 11
                        color: themeService ? themeService.getThemeProperty("colors", "textAlt") || "#bac2de" : "#bac2de"
                    }
                }
                
                Rectangle {
                    width: parent.width
                    height: 1
                    color: themeService ? themeService.getThemeProperty("colors", "border") || "#6c7086" : "#6c7086"
                }
                
                // Sensor information
                Column {
                    width: parent.width
                    spacing: 4
                    
                    Text {
                        text: "Sensor Information"
                        font.family: "Inter"
                        font.pixelSize: 12
                        font.weight: Font.Medium
                        color: themeService ? themeService.getThemeProperty("colors", "text") || "#cdd6f4" : "#cdd6f4"
                    }
                    
                    Text {
                        text: temperatureService ? `Sensor: ${temperatureService.cpuSensor}` : "Sensor: Unknown"
                        font.family: "Inter"
                        font.pixelSize: 10
                        color: themeService ? themeService.getThemeProperty("colors", "textAlt") || "#bac2de" : "#bac2de"
                        wrapMode: Text.Wrap
                        width: parent.width
                    }
                    
                    Text {
                        text: temperatureService ? `Update interval: ${temperatureService.updateInterval/1000}s` : "Update interval: --s"
                        font.family: "Inter"
                        font.pixelSize: 10
                        color: themeService ? themeService.getThemeProperty("colors", "textAlt") || "#bac2de" : "#bac2de"
                    }
                    
                    Text {
                        text: "Configurable via ~/.config/quickshell/config/settings/main-config.json"
                        font.family: "Inter"
                        font.pixelSize: 9
                        color: themeService ? themeService.getThemeProperty("colors", "textAlt") || "#bac2de" : "#bac2de"
                        wrapMode: Text.Wrap
                        width: parent.width
                    }
                }
            }
        }
    }
    
    // Standard show/hide functions
    function show(anchorWindow, x, y) {
        anchor.window = anchorWindow
        anchor.rect.x = x
        anchor.rect.y = y
        visible = true
        focusGrab.active = true
    }
    
    function hide() {
        visible = false
        focusGrab.active = false
    }
}