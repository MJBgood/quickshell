import QtQuick
import QtQuick.Controls
import "../../services"

Column {
    id: pollingControl
    
    // Required properties
    required property string monitorType  // "cpu", "ram", or "storage"
    required property var systemMonitorService
    property var themeService: null
    
    spacing: 8
    width: parent.width
    
    // Current polling rate
    property real currentRate: getCurrentPollingRate()
    
    function getCurrentPollingRate() {
        if (!systemMonitorService) return 2.0
        
        switch (monitorType) {
            case "cpu":
                return systemMonitorService.getCpuPollingRate()
            case "ram":
                return systemMonitorService.getRamPollingRate()
            case "storage":
                return systemMonitorService.getStoragePollingRate()
            default:
                return 2.0
        }
    }
    
    function setPollingRate(seconds) {
        if (!systemMonitorService) return
        
        console.log("[PollingRateControl] Setting", monitorType, "polling rate to", seconds, "seconds")
        
        switch (monitorType) {
            case "cpu":
                systemMonitorService.setCpuPollingRate(seconds)
                break
            case "ram":
                systemMonitorService.setRamPollingRate(seconds)
                break
            case "storage":
                systemMonitorService.setStoragePollingRate(seconds)
                break
        }
        
        currentRate = seconds
    }
    
    // Section header
    Text {
        text: "Polling Rate"
        font.family: "Inter"
        font.pixelSize: 12
        font.weight: Font.DemiBold
        color: themeService ? themeService.getThemeProperty("colors", "text") || "#cdd6f4" : "#cdd6f4"
    }
    
    // Current rate display
    Text {
        text: "Current: " + currentRate.toFixed(1) + "s"
        font.family: "Inter"
        font.pixelSize: 10
        color: themeService ? themeService.getThemeProperty("colors", "textAlt") || "#bac2de" : "#bac2de"
    }
    
    // Preset rate buttons
    Flow {
        width: parent.width
        spacing: 4
        
        Repeater {
            model: getPresetRates()
            
            Rectangle {
                width: 40
                height: 24
                radius: 4
                color: isSelected() ? 
                    (themeService ? themeService.getThemeProperty("colors", "accent") || "#cba6f7" : "#cba6f7") :
                    (themeService ? themeService.getThemeProperty("colors", "surface") || "#313244" : "#313244")
                border.color: themeService ? themeService.getThemeProperty("colors", "border") || "#6c7086" : "#6c7086"
                border.width: 1
                
                function isSelected() {
                    return Math.abs(currentRate - modelData) < 0.1
                }
                
                Text {
                    anchors.centerIn: parent
                    text: modelData + "s"
                    font.family: "Inter"
                    font.pixelSize: 9
                    font.weight: Font.Medium
                    color: parent.isSelected() ? 
                        (themeService ? themeService.getThemeProperty("colors", "background") || "#1e1e2e" : "#1e1e2e") :
                        (themeService ? themeService.getThemeProperty("colors", "text") || "#cdd6f4" : "#cdd6f4")
                }
                
                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    
                    onClicked: {
                        setPollingRate(modelData)
                    }
                    
                    onEntered: parent.opacity = 0.8
                    onExited: parent.opacity = 1.0
                }
                
                Behavior on color {
                    ColorAnimation { duration: 150 }
                }
                
                Behavior on opacity {
                    NumberAnimation { duration: 100 }
                }
            }
        }
    }
    
    function getPresetRates() {
        switch (monitorType) {
            case "cpu":
            case "ram":
                return [0.5, 1, 2, 5, 10]  // Fast polling options for CPU/RAM
            case "storage":
                return [5, 10, 30, 60, 120]  // Slower options for storage
            default:
                return [1, 2, 5, 10]
        }
    }
}