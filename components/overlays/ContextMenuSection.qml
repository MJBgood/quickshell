import QtQuick
import Quickshell
import Quickshell.Widgets
import "../../services"

Column {
    id: section
    
    property string title: ""
    property string icon: ""
    property var configService: ConfigService
    property string configPrefix: ""
    
    signal itemClicked(string action, var value)
    
    spacing: 2
    
    // Section header
    Rectangle {
        width: parent.width
        height: 28
        color: "transparent"
        
        Row {
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            anchors.leftMargin: 8
            spacing: 6
            
            Text {
                text: icon
                font.pixelSize: 12
                anchors.verticalCenter: parent.verticalCenter
            }
            
            Text {
                text: title
                font.pixelSize: 11
                font.weight: Font.DemiBold
                color: configService ? configService.getThemeProperty("colors", "text") || "#cdd6f4" : "#cdd6f4"
                anchors.verticalCenter: parent.verticalCenter
            }
        }
    }
    
    // Enable/Disable toggle
    MenuItem {
        width: parent.width
        text: "  ✓ Enabled" 
        enabled: true
        configService: section.configService
        
        onClicked: {
            if (configService) {
                const currentValue = configService.getValue(configPrefix + ".enabled", true)
                section.itemClicked("enabled", !currentValue)
            }
        }
        
        // Update checkmark based on current state
        Component.onCompleted: updateEnabledText()
        
        Connections {
            target: configService
            function onConfigChanged() {
                updateEnabledText()
            }
        }
        
        function updateEnabledText() {
            if (configService) {
                const isEnabled = configService.getValue(configPrefix + ".enabled", true)
                text = "  " + (isEnabled ? "✓" : "✗") + " Enabled"
            }
        }
    }
    
    // Show Icon toggle
    MenuItem {
        width: parent.width
        text: "  ✓ Show Icon"
        enabled: true
        configService: section.configService
        
        onClicked: {
            if (configService) {
                const currentValue = configService.getValue(configPrefix + ".showIcon", true)
                section.itemClicked("showIcon", !currentValue)
            }
        }
        
        Component.onCompleted: updateIconText()
        
        Connections {
            target: configService
            function onConfigChanged() {
                updateIconText()
            }
        }
        
        function updateIconText() {
            if (configService) {
                const showIcon = configService.getValue(configPrefix + ".showIcon", true)
                text = "  " + (showIcon ? "✓" : "✗") + " Show Icon"
            }
        }
    }
    
    // Show Label toggle
    MenuItem {
        width: parent.width
        text: "  ✓ Show Label"
        enabled: true
        configService: section.configService
        
        onClicked: {
            if (configService) {
                const currentValue = configService.getValue(configPrefix + ".showLabel", false)
                section.itemClicked("showLabel", !currentValue)
            }
        }
        
        Component.onCompleted: updateLabelText()
        
        Connections {
            target: configService
            function onConfigChanged() {
                updateLabelText()
            }
        }
        
        function updateLabelText() {
            if (configService) {
                const showLabel = configService.getValue(configPrefix + ".showLabel", false)
                text = "  " + (showLabel ? "✓" : "✗") + " Show Label"
            }
        }
    }
    
    // Show Percentage toggle  
    MenuItem {
        width: parent.width
        text: "  ✓ Show Percentage"
        enabled: true
        configService: section.configService
        
        onClicked: {
            if (configService) {
                const currentValue = configService.getValue(configPrefix + ".showPercentage", true)
                section.itemClicked("showPercentage", !currentValue)
            }
        }
        
        Component.onCompleted: updatePercentageText()
        
        Connections {
            target: configService
            function onConfigChanged() {
                updatePercentageText()
            }
        }
        
        function updatePercentageText() {
            if (configService) {
                const showPercentage = configService.getValue(configPrefix + ".showPercentage", true)
                text = "  " + (showPercentage ? "✓" : "✗") + " Show Percentage"
            }
        }
    }
    
    // Precision submenu
    MenuItem {
        width: parent.width
        text: "  Precision: " + (configService ? configService.getValue(configPrefix + ".precision", 1) : 1)
        enabled: true
        configService: section.configService
        
        onClicked: {
            if (configService) {
                const currentPrecision = configService.getValue(configPrefix + ".precision", 1)
                const newPrecision = (currentPrecision + 1) % 4  // Cycle through 0, 1, 2, 3
                section.itemClicked("precision", newPrecision)
            }
        }
        
        Component.onCompleted: updatePrecisionText()
        
        Connections {
            target: configService
            function onConfigChanged() {
                updatePrecisionText()
            }
        }
        
        function updatePrecisionText() {
            if (configService) {
                const precision = configService.getValue(configPrefix + ".precision", 1)
                text = "  Precision: " + precision + " decimal" + (precision === 1 ? "" : "s")
            }
        }
    }
    
    // Spacer
    Rectangle {
        width: parent.width
        height: 4
        color: "transparent"
    }
}