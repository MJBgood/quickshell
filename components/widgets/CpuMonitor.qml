import QtQuick
import "../../services"

Rectangle {
    id: cpuMonitor
    
    // Services
    property var configService: null
    property var themeService: null
    property var systemMonitorService: null
    
    implicitWidth: 60
    implicitHeight: 24
    
    color: "transparent"
    
    // CPU usage display
    Row {
        anchors.centerIn: parent
        spacing: 4
        
        Text {
            text: "💻"
            font.pixelSize: 12
            color: themeService ? themeService.getThemeProperty("colors", "text") || "#cdd6f4" : "#cdd6f4"
            anchors.verticalCenter: parent.verticalCenter
        }
        
        Text {
            text: getCpuUsage()
            font.pixelSize: 10
            font.weight: Font.Medium
            color: themeService ? themeService.getThemeProperty("colors", "text") || "#cdd6f4" : "#cdd6f4"
            anchors.verticalCenter: parent.verticalCenter
        }
    }
    
    function getCpuUsage() {
        // Placeholder - in real implementation would get from systemMonitorService
        return "45%"
    }
    
    Component.onCompleted: {
        console.log("CpuMonitor widget loaded")
    }
}