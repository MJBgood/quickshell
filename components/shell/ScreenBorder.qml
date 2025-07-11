import QtQuick
import Quickshell
import "../shared"

Item {
    id: screenBorder
    
    // Entity ID for configuration
    property string entityId: "screenBorder"
    
    property var configService: ConfigService
    property var borderOverlayService: BorderOverlayService
    
    // Fill the entire screen
    anchors.fill: parent
    
    // Configuration properties
    property bool enabled: borderOverlayService ? borderOverlayService.enabled : true
    property bool borderVisible: borderOverlayService ? borderOverlayService.visible : true
    property int thickness: borderOverlayService ? borderOverlayService.thickness : 8
    property int rounding: borderOverlayService ? borderOverlayService.rounding : 12
    property real borderOpacity: borderOverlayService ? borderOverlayService.opacity : 0.3
    property string borderColor: borderOverlayService ? borderOverlayService.color : "#585b70"
    property int barWidth: borderOverlayService ? borderOverlayService.barWidth : 0
    
    // Only show if enabled and visible
    opacity: enabled && borderVisible ? 1.0 : 0.0
    
    // Smooth opacity transitions
    Behavior on opacity {
        NumberAnimation { 
            duration: borderOverlayService ? borderOverlayService.animationDuration : 300
            easing.type: Easing.OutCubic 
        }
    }
    
    // Simple border using 4 rectangles (top, bottom, left, right)
    // Top border
    Rectangle {
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        height: thickness
        color: borderColor
        opacity: borderOpacity
        
        Behavior on color {
            ColorAnimation { 
                duration: borderOverlayService ? borderOverlayService.animationDuration : 300
                easing.type: Easing.OutCubic 
            }
        }
        
        Behavior on opacity {
            NumberAnimation { 
                duration: borderOverlayService ? borderOverlayService.animationDuration : 300
                easing.type: Easing.OutCubic 
            }
        }
    }
    
    // Bottom border
    Rectangle {
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        height: thickness
        color: borderColor
        opacity: borderOpacity
        
        Behavior on color {
            ColorAnimation { 
                duration: borderOverlayService ? borderOverlayService.animationDuration : 300
                easing.type: Easing.OutCubic 
            }
        }
        
        Behavior on opacity {
            NumberAnimation { 
                duration: borderOverlayService ? borderOverlayService.animationDuration : 300
                easing.type: Easing.OutCubic 
            }
        }
    }
    
    // Left border
    Rectangle {
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.topMargin: thickness
        anchors.bottom: parent.bottom
        anchors.bottomMargin: thickness
        width: thickness
        color: borderColor
        opacity: borderOpacity
        
        Behavior on color {
            ColorAnimation { 
                duration: borderOverlayService ? borderOverlayService.animationDuration : 300
                easing.type: Easing.OutCubic 
            }
        }
        
        Behavior on opacity {
            NumberAnimation { 
                duration: borderOverlayService ? borderOverlayService.animationDuration : 300
                easing.type: Easing.OutCubic 
            }
        }
    }
    
    // Right border
    Rectangle {
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.topMargin: thickness
        anchors.bottom: parent.bottom
        anchors.bottomMargin: thickness
        width: thickness
        color: borderColor
        opacity: borderOpacity
        
        Behavior on color {
            ColorAnimation { 
                duration: borderOverlayService ? borderOverlayService.animationDuration : 300
                easing.type: Easing.OutCubic 
            }
        }
        
        Behavior on opacity {
            NumberAnimation { 
                duration: borderOverlayService ? borderOverlayService.animationDuration : 300
                easing.type: Easing.OutCubic 
            }
        }
    }
    
    
    // React to border service changes
    Connections {
        target: borderOverlayService
        
        function onBorderVisibilityChanged() {
            borderVisible = borderOverlayService.visible
        }
        
        function onBorderEnabledChanged() {
            enabled = borderOverlayService.enabled
        }
        
        function onBorderStyleChanged() {
            borderColor = borderOverlayService.color
            borderOpacity = borderOverlayService.opacity
        }
        
        function onBorderGeometryChanged() {
            thickness = borderOverlayService.thickness
            rounding = borderOverlayService.rounding
            barWidth = borderOverlayService.barWidth
        }
    }
    
    // Handle theme changes
    Connections {
        target: configService
        function onThemeChanged() {
            if (borderOverlayService) {
                borderOverlayService.updateTheme()
            }
        }
    }
    
    // Debug visualization (can be enabled via configuration)
    Rectangle {
        id: debugVisualization
        visible: configService ? configService.getValue("border.showDebug", false) : false
        anchors.fill: parent
        anchors.leftMargin: barWidth
        anchors.margins: thickness
        color: "transparent"
        border.color: "#ff0000"
        border.width: 1
        radius: rounding
        
        Text {
            anchors.centerIn: parent
            text: `Border Debug\nThickness: ${thickness}\nRounding: ${rounding}\nBar Width: ${barWidth}`
            color: "#ff0000"
            font.pixelSize: 12
            horizontalAlignment: Text.AlignHCenter
        }
    }
    
    Component.onCompleted: {
        // Initialize from border service
        if (borderOverlayService) {
            enabled = borderOverlayService.enabled
            borderVisible = borderOverlayService.visible
            thickness = borderOverlayService.thickness
            rounding = borderOverlayService.rounding
            borderOpacity = borderOverlayService.opacity
            borderColor = borderOverlayService.color
            barWidth = borderOverlayService.barWidth
        }
        
        console.log("[ScreenBorder] Initialized with thickness:", thickness, "rounding:", rounding)
    }
}