import QtQuick
import QtQuick.Controls
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
    property var configService: ConfigService
    property var anchorWindow: null
    
    // GraphicalComponent interface
    property string componentId: "cpu_temp_widget"
    property string parentComponentId: ""
    property var childComponentIds: []
    property string menuPath: "cpu_temp_widget"
    
    // Dynamic sizing based on content
    implicitWidth: cpuTempContent.implicitWidth
    implicitHeight: cpuTempContent.implicitHeight
    color: "transparent"
    
    // Context menu
    CpuTempContextMenu {
        id: contextMenu
        temperatureService: TemperatureService
        configService: cpuTempWidget.configService
        visible: false
    }
    
    // Delegate functions to service
    function getCpuTemp() { return TemperatureService.cpuTemp }
    function getCpuStatus() { return TemperatureService.getCpuStatus() }
    function refreshTemperature() { return TemperatureService.refreshTemperature() }
    
    // GraphicalComponent interface methods
    function menu(startPath) {
        const globalPos = cpuTempWidget.mapToItem(null, width / 2, height / 2)
        contextMenu.show(anchorWindow, globalPos.x, globalPos.y)
    }
    
    function getParent() {
        return parentComponentId ? parent : null
    }
    
    function getChildren() {
        return childComponentIds
    }
    
    function navigateToParent() {
        if (parentComponentId && parent && parent.menu) {
            parent.menu()
        }
    }
    
    function navigateToChild(childId) {
        // No children for this component
    }
    
    // Content layout
    Row {
        id: cpuTempContent
        anchors.centerIn: parent
        spacing: configService ? configService.scaledMarginTiny() : 4
        
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
            font.pixelSize: configService ? configService.scaledFontMedium() : 12
            color: configService?.getThemeProperty("colors", "text") || "#cdd6f4"
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
            font.pixelSize: configService ? configService.scaledFontSmall() : 9
            font.weight: Font.Medium
            color: {
                const status = TemperatureService.getCpuStatus()
                switch (status) {
                    case "cool": 
                        return configService?.getThemeProperty("colors", "success") || "#a6e3a1"
                    case "warm": 
                        return configService?.getThemeProperty("colors", "warning") || "#f9e2af"
                    case "hot": 
                        return configService?.getThemeProperty("colors", "error") || "#f38ba8"
                    case "critical": 
                        return configService?.getThemeProperty("colors", "error") || "#f38ba8"
                    default: 
                        return configService?.getThemeProperty("colors", "text") || "#cdd6f4"
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
    
    // Component lifecycle
    Component.onCompleted: {
        console.log("[CpuTempWidget] Initialized with TemperatureService singleton")
        
        // Connect config service to TemperatureService if available
        if (configService && !TemperatureService.configService) {
            TemperatureService.configService = configService
        }
        
        // Register component with parent if it exists
        if (parent && parent.registerChild) {
            parent.registerChild(componentId, cpuTempWidget)
        }
    }
    
    Component.onDestruction: {
        console.log("[CpuTempWidget] Cleaning up component")
        
        // Unregister component from parent if it exists
        if (parent && parent.unregisterChild) {
            parent.unregisterChild(componentId)
        }
    }
}