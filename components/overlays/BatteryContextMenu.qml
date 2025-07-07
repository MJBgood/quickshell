import Quickshell
import Quickshell.Hyprland
import QtQuick
import QtQuick.Controls
import "../../services"

PopupWindow {
    id: contextMenu
    
    // Services
    property var batteryService: null
    property var configService: ConfigService
    
    // Standard window properties
    implicitWidth: 240
    implicitHeight: Math.min(400, menuContent.contentHeight + 32)
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
        color: configService ? configService.getThemeProperty("colors", "surface") || "#313244" : "#313244"
        border.color: configService ? configService.getThemeProperty("colors", "border") || "#6c7086" : "#6c7086"
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
                    text: "Battery Status"
                    font.family: "Inter"
                    font.pixelSize: 14
                    font.weight: Font.DemiBold
                    color: configService ? configService.getThemeProperty("colors", "text") || "#cdd6f4" : "#cdd6f4"
                }
                
                Rectangle {
                    width: parent.width
                    height: 1
                    color: configService ? configService.getThemeProperty("colors", "border") || "#6c7086" : "#6c7086"
                }
                
                // Battery presence check
                Column {
                    width: parent.width
                    spacing: 8
                    visible: batteryService ? batteryService.present : false
                    
                    Text {
                        text: "Current Status"
                        font.family: "Inter"
                        font.pixelSize: 12
                        font.weight: Font.Medium
                        color: configService ? configService.getThemeProperty("colors", "text") || "#cdd6f4" : "#cdd6f4"
                    }
                    
                    Row {
                        spacing: 8
                        
                        Text {
                            text: batteryService ? `${Math.round(batteryService.percentage)}%` : "---%"
                            font.family: "Inter"
                            font.pixelSize: 18
                            font.weight: Font.Bold
                            color: {
                                if (!batteryService) return configService ? configService.getThemeProperty("colors", "text") || "#cdd6f4" : "#cdd6f4"
                                const status = batteryService.getBatteryStatus()
                                switch (status) {
                                    case "high": return configService ? configService.getThemeProperty("colors", "success") || "#a6e3a1" : "#a6e3a1"
                                    case "medium": return configService ? configService.getThemeProperty("colors", "text") || "#cdd6f4" : "#cdd6f4"
                                    case "low": return configService ? configService.getThemeProperty("colors", "warning") || "#f9e2af" : "#f9e2af"
                                    case "critical": return configService ? configService.getThemeProperty("colors", "error") || "#f38ba8" : "#f38ba8"
                                    default: return configService ? configService.getThemeProperty("colors", "text") || "#cdd6f4" : "#cdd6f4"
                                }
                            }
                        }
                        
                        Text {
                            text: {
                                if (!batteryService) return "Unknown"
                                return batteryService.charging ? "Charging" : "Discharging"
                            }
                            font.family: "Inter"
                            font.pixelSize: 11
                            color: {
                                if (!batteryService) return configService ? configService.getThemeProperty("colors", "textAlt") || "#bac2de" : "#bac2de"
                                return batteryService.charging ? 
                                    configService ? configService.getThemeProperty("colors", "success") || "#a6e3a1" : "#a6e3a1" :
                                    configService ? configService.getThemeProperty("colors", "textAlt") || "#bac2de" : "#bac2de"
                            }
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }
                    
                    Text {
                        text: {
                            if (!batteryService) return "Status: Unknown"
                            const status = batteryService.getBatteryStatus()
                            switch (status) {
                                case "high": return "Status: High"
                                case "medium": return "Status: Medium"
                                case "low": return "Status: Low"
                                case "critical": return "Status: Critical"
                                default: return "Status: Unknown"
                            }
                        }
                        font.family: "Inter"
                        font.pixelSize: 11
                        color: configService ? configService.getThemeProperty("colors", "textAlt") || "#bac2de" : "#bac2de"
                    }
                }
                
                // No battery message
                Text {
                    visible: batteryService ? !batteryService.present : true
                    text: "No battery detected"
                    font.family: "Inter"
                    font.pixelSize: 12
                    color: configService ? configService.getThemeProperty("colors", "textAlt") || "#bac2de" : "#bac2de"
                    width: parent.width
                }
                
                Rectangle {
                    width: parent.width
                    height: 1
                    color: configService ? configService.getThemeProperty("colors", "border") || "#6c7086" : "#6c7086"
                    visible: batteryService ? batteryService.present : false
                }
                
                // Time estimates
                Column {
                    width: parent.width
                    spacing: 4
                    visible: batteryService ? batteryService.present : false
                    
                    Text {
                        text: "Time Estimates"
                        font.family: "Inter"
                        font.pixelSize: 12
                        font.weight: Font.Medium
                        color: configService ? configService.getThemeProperty("colors", "text") || "#cdd6f4" : "#cdd6f4"
                    }
                    
                    Text {
                        text: {
                            if (!batteryService) return "Time remaining: Unknown"
                            const time = batteryService.getEstimatedTime()
                            return time ? `Time remaining: ${time}` : "Time remaining: Unknown"
                        }
                        font.family: "Inter"
                        font.pixelSize: 10
                        color: configService ? configService.getThemeProperty("colors", "textAlt") || "#bac2de" : "#bac2de"
                        wrapMode: Text.Wrap
                        width: parent.width
                    }
                    
                    Text {
                        text: {
                            if (!batteryService) return "Status: Unknown"
                            return batteryService.charging ? "Currently charging" : "Currently discharging"
                        }
                        font.family: "Inter"
                        font.pixelSize: 10
                        color: configService ? configService.getThemeProperty("colors", "textAlt") || "#bac2de" : "#bac2de"
                    }
                }
                
                Rectangle {
                    width: parent.width
                    height: 1
                    color: configService ? configService.getThemeProperty("colors", "border") || "#6c7086" : "#6c7086"
                    visible: batteryService ? batteryService.present : false
                }
                
                // Battery information
                Column {
                    width: parent.width
                    spacing: 4
                    visible: batteryService ? batteryService.present : false
                    
                    Text {
                        text: "Battery Information"
                        font.family: "Inter"
                        font.pixelSize: 12
                        font.weight: Font.Medium
                        color: configService ? configService.getThemeProperty("colors", "text") || "#cdd6f4" : "#cdd6f4"
                    }
                    
                    Text {
                        text: "Power management via UPower"
                        font.family: "Inter"
                        font.pixelSize: 10
                        color: configService ? configService.getThemeProperty("colors", "textAlt") || "#bac2de" : "#bac2de"
                        wrapMode: Text.Wrap
                        width: parent.width
                    }
                    
                    Text {
                        text: "Battery level thresholds: Critical <10%, Low <20%, Medium <80%, High ≥80%"
                        font.family: "Inter"
                        font.pixelSize: 10
                        color: configService ? configService.getThemeProperty("colors", "textAlt") || "#bac2de" : "#bac2de"
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