import QtQuick
import QtQuick.Controls
import Quickshell
import "../../services"
import "../overlays"

Rectangle {
    id: batteryWidget
    
    // Widget properties
    property bool enabled: true
    property bool showIcon: true
    property bool showPercentage: true
    property bool showTime: false
    
    // Services
    property var configService: null
    property var themeService: null
    property var anchorWindow: null
    
    // GraphicalComponent interface
    property string componentId: "battery"
    property string parentComponentId: ""
    property var childComponentIds: []
    property string menuPath: "battery"
    
    // Size configuration
    implicitWidth: showIcon && showPercentage ? 65 : showIcon ? 24 : 45
    implicitHeight: 20
    color: "transparent"
    
    // Context menu
    BatteryContextMenu {
        id: contextMenu
        batteryService: BatteryService
        themeService: batteryWidget.themeService
        visible: false
    }
    
    // Content layout
    Row {
        anchors.centerIn: parent
        spacing: 3
        
        Text {
            visible: showIcon
            anchors.verticalCenter: parent.verticalCenter
            text: {
                if (!BatteryService.present) return "🔌"
                
                const percentage = BatteryService.percentage
                const charging = BatteryService.charging
                
                if (charging) {
                    return "🔋"  // Charging icon
                } else {
                    if (percentage > 80) return "🔋"
                    if (percentage > 60) return "🔋"
                    if (percentage > 40) return "🔋"
                    if (percentage > 20) return "🪫"
                    return "🪫"  // Low battery
                }
            }
            font.pixelSize: 12
        }
        
        Text {
            visible: showPercentage
            anchors.verticalCenter: parent.verticalCenter
            text: {
                if (!BatteryService.present) return "N/A"
                return Math.round(BatteryService.percentage) + "%"
            }
            font.family: "Inter"
            font.pixelSize: 11
            font.weight: Font.Medium
            color: {
                if (!BatteryService.present) {
                    return themeService?.getThemeProperty("colors", "textAlt") || "#bac2de"
                }
                
                const status = BatteryService.getBatteryStatus()
                switch (status) {
                    case "high": 
                        return themeService?.getThemeProperty("colors", "success") || "#a6e3a1"
                    case "medium": 
                        return themeService?.getThemeProperty("colors", "text") || "#cdd6f4"
                    case "low": 
                        return themeService?.getThemeProperty("colors", "warning") || "#f9e2af"
                    case "critical": 
                        return themeService?.getThemeProperty("colors", "error") || "#f38ba8"
                    default: 
                        return themeService?.getThemeProperty("colors", "textAlt") || "#bac2de"
                }
            }
        }
        
        Text {
            visible: showTime && BatteryService.present
            anchors.verticalCenter: parent.verticalCenter
            text: {
                const estimatedTime = BatteryService.getEstimatedTime()
                return estimatedTime || ""
            }
            font.family: "Inter"
            font.pixelSize: 9
            font.weight: Font.Normal
            color: themeService?.getThemeProperty("colors", "textAlt") || "#bac2de"
        }
    }
    
    // Mouse interactions
    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        hoverEnabled: true
        
        onClicked: function(mouse) {
            if (mouse.button === Qt.RightButton) {
                const globalPos = batteryWidget.mapToItem(null, mouse.x, mouse.y)
                contextMenu.show(anchorWindow, globalPos.x, globalPos.y)
            }
        }
        
        onEntered: parent.parent && (parent.parent.opacity = 0.8)
        onExited: parent.parent && (parent.parent.opacity = 1.0)
    }
    
    Component.onCompleted: console.log("[BatteryWidget] Initialized with BatteryService")
}