import QtQuick
import QtQuick.Controls
import Quickshell
import "../../services"
import "../overlays"

Rectangle {
    id: batteryWidget
    
    // Entity ID for configuration
    property string entityId: "batteryWidget"
    
    // Widget properties
    property bool enabled: configService ? configService.getEntityProperty(entityId, "enabled", true) : true
    property bool showIcon: configService ? configService.getEntityProperty(entityId, "showIcon", true) : true
    property bool showPercentage: configService ? configService.getEntityProperty(entityId, "showPercentage", true) : true
    property bool showTime: configService ? configService.getEntityProperty(entityId, "showTime", false) : false
    
    // Services
    property var configService: ConfigService
    property var anchorWindow: null
    
    // GraphicalComponent interface
    property string componentId: "battery"
    property string parentComponentId: ""
    property var childComponentIds: []
    property string menuPath: "battery"
    
    // Dynamic sizing based on content
    implicitWidth: batteryContent.implicitWidth
    implicitHeight: batteryContent.implicitHeight
    color: "transparent"
    
    // Context menu
    BatteryContextMenu {
        id: contextMenu
        batteryService: BatteryService
        configService: batteryWidget.configService
        visible: false
    }
    
    // Content layout
    Row {
        id: batteryContent
        anchors.centerIn: parent
        spacing: configService ? configService.spacing("xs", entityId) : 4
        
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
            font.pixelSize: configService ? configService.typography("xs", entityId) : 9
        }
        
        Text {
            visible: showPercentage
            anchors.verticalCenter: parent.verticalCenter
            text: {
                if (!BatteryService.present) return "N/A"
                return Math.round(BatteryService.percentage) + "%"
            }
            font.family: "Inter"
            font.pixelSize: configService ? configService.typography("xs", entityId) : 9
            font.weight: Font.Medium
            color: {
                if (!BatteryService.present) {
                    return configService?.getThemeProperty("colors", "textAlt") || "#bac2de"
                }
                
                const status = BatteryService.getBatteryStatus()
                switch (status) {
                    case "high": 
                        return configService?.getThemeProperty("colors", "success") || "#a6e3a1"
                    case "medium": 
                        return configService?.getThemeProperty("colors", "text") || "#cdd6f4"
                    case "low": 
                        return configService?.getThemeProperty("colors", "warning") || "#f9e2af"
                    case "critical": 
                        return configService?.getThemeProperty("colors", "error") || "#f38ba8"
                    default: 
                        return configService?.getThemeProperty("colors", "textAlt") || "#bac2de"
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
            font.pixelSize: configService ? configService.typography("xs", entityId) : 8
            font.weight: Font.Normal
            color: configService?.getThemeProperty("colors", "textAlt") || "#bac2de"
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