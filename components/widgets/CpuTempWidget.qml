import QtQuick
import QtQuick.Controls
import Quickshell
import "../../services"
import "../overlays"

Rectangle {
    id: cpuTempWidget
    
    // Widget properties
    property bool enabled: true
    property bool showIcon: true
    property bool showValue: true
    property bool showUnit: true
    
    // Services
    property var configService: null
    property var themeService: null
    property var anchorWindow: null
    
    // GraphicalComponent interface
    property string componentId: "cpu_temp"
    property string parentComponentId: ""
    property var childComponentIds: []
    property string menuPath: "cpu_temp"
    
    // Size configuration
    implicitWidth: showIcon && showValue ? 55 : showIcon ? 24 : 40
    implicitHeight: 20
    color: "transparent"
    
    // Context menu
    CpuTempContextMenu {
        id: contextMenu
        temperatureService: TemperatureService
        themeService: cpuTempWidget.themeService
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
                const status = TemperatureService.getCpuStatus()
                switch (status) {
                    case "cool": return "🆒"
                    case "warm": return "🌡️"
                    case "hot": return "🔥"
                    case "critical": return "🚨"
                    default: return "❓"
                }
            }
            font.pixelSize: 12
        }
        
        Text {
            visible: showValue
            anchors.verticalCenter: parent.verticalCenter
            text: {
                let temp = TemperatureService.cpuTemp
                if (temp === 0) return "--"
                return Math.round(temp) + (showUnit ? "°C" : "")
            }
            font.family: "Inter"
            font.pixelSize: 11
            font.weight: Font.Medium
            color: {
                const status = TemperatureService.getCpuStatus()
                switch (status) {
                    case "cool": 
                        return themeService?.getThemeProperty("colors", "success") || "#a6e3a1"
                    case "warm": 
                        return themeService?.getThemeProperty("colors", "warning") || "#f9e2af"
                    case "hot": 
                        return themeService?.getThemeProperty("colors", "error") || "#f38ba8"
                    case "critical": 
                        return themeService?.getThemeProperty("colors", "error") || "#f38ba8"
                    default: 
                        return themeService?.getThemeProperty("colors", "text") || "#cdd6f4"
                }
            }
        }
    }
    
    // Mouse interactions
    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        hoverEnabled: true
        
        onClicked: function(mouse) {
            if (mouse.button === Qt.RightButton) {
                const globalPos = cpuTempWidget.mapToItem(null, mouse.x, mouse.y)
                contextMenu.show(anchorWindow, globalPos.x, globalPos.y)
            }
        }
        
        onEntered: parent.parent && (parent.parent.opacity = 0.8)
        onExited: parent.parent && (parent.parent.opacity = 1.0)
    }
    
    Component.onCompleted: console.log("[CpuTempWidget] Initialized with TemperatureService")
}