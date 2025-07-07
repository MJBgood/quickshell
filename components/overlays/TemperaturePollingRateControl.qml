import QtQuick
import QtQuick.Controls
import "../../services"

Column {
    id: pollingControl
    
    // Required properties
    property var temperatureService: null
    property var configService: ConfigService
    
    spacing: 8
    width: parent.width
    
    // Current polling rate - reactive to service changes
    property real currentRate: getCurrentPollingRate()
    
    function getCurrentPollingRate() {
        if (!temperatureService) return 10.0
        return temperatureService.getPollingRate()
    }
    
    // Update current rate when service interval changes
    Connections {
        target: temperatureService
        function onUpdateIntervalChanged() {
            currentRate = getCurrentPollingRate()
        }
    }
    
    function setPollingRate(seconds) {
        if (!temperatureService) return
        
        console.log("[TemperaturePollingRateControl] Setting temperature polling rate to", seconds, "seconds")
        temperatureService.setPollingRate(seconds)
        currentRate = seconds
    }
    
    // Section header
    Text {
        text: "Polling Rate"
        font.family: "Inter"
        font.pixelSize: 12
        font.weight: Font.DemiBold
        color: configService ? configService.getThemeProperty("colors", "text") || "#cdd6f4" : "#cdd6f4"
    }
    
    // Current rate display
    Text {
        text: "Current: " + currentRate.toFixed(1) + "s"
        font.family: "Inter"
        font.pixelSize: 10
        color: configService ? configService.getThemeProperty("colors", "textAlt") || "#bac2de" : "#bac2de"
    }
    
    // Preset rate buttons for temperature monitoring
    Flow {
        width: parent.width
        spacing: 4
        
        Repeater {
            model: [2, 5, 10, 30, 60]  // Temperature doesn't need sub-second polling
            
            Rectangle {
                width: 40
                height: 24
                radius: 4
                color: isSelected() ? 
                    (configService ? configService.getThemeProperty("colors", "accent") || "#cba6f7" : "#cba6f7") :
                    (configService ? configService.getThemeProperty("colors", "surface") || "#313244" : "#313244")
                border.color: configService ? configService.getThemeProperty("colors", "border") || "#6c7086" : "#6c7086"
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
                        (configService ? configService.getThemeProperty("colors", "background") || "#1e1e2e" : "#1e1e2e") :
                        (configService ? configService.getThemeProperty("colors", "text") || "#cdd6f4" : "#cdd6f4")
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
}