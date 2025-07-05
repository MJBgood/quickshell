import QtQuick
import QtQuick.Controls
import "../../services"
import "../overlays"

Rectangle {
    id: brightnessWidget
    
    // Widget properties
    property bool enabled: true
    property bool showIcon: true
    property bool showPercentage: true
    property bool showSlider: false
    
    // Services
    property var configService: null
    property var themeService: null
    property var anchorWindow: null
    
    // GraphicalComponent interface
    property string componentId: "brightness"
    property string parentComponentId: ""
    property var childComponentIds: []
    property string menuPath: "brightness"
    
    // Size configuration
    implicitWidth: showSlider ? 120 : (showIcon && showPercentage ? 60 : showIcon ? 24 : 40)
    implicitHeight: 20
    color: "transparent"
    
    // Context menu
    BrightnessContextMenu {
        id: contextMenu
        brightnessService: BrightnessService
        themeService: brightnessWidget.themeService
        visible: false
    }
    
    // Delegate functions to service
    function setBrightness(brightness) { return BrightnessService.setBrightness(brightness) }
    function adjustBrightness(delta) { return BrightnessService.adjustBrightness(delta) }
    function cycleBrightness() { return BrightnessService.cycleBrightness() }
    function updateBrightness() { return BrightnessService.updateBrightness() }
    
    // Content layout
    Row {
        anchors.centerIn: parent
        spacing: 4
        
        Text {
            visible: showIcon
            anchors.verticalCenter: parent.verticalCenter
            text: {
                if (BrightnessService.brightness > 0.8) return "☀"    // High brightness - sun
                if (BrightnessService.brightness > 0.5) return "💡"   // Medium brightness - lightbulb
                if (BrightnessService.brightness > 0.2) return "🔅"   // Low brightness - dim
                return "🌙"  // Very low brightness - moon
            }
            font.pixelSize: 14
            color: themeService?.getThemeProperty("colors", "text") || "#cdd6f4"
        }
        
        Text {
            visible: showPercentage && !showSlider
            anchors.verticalCenter: parent.verticalCenter
            text: `${Math.round(BrightnessService.brightness * 100)}%`
            font.family: "Inter"
            font.pixelSize: 11
            font.weight: Font.Medium
            color: themeService?.getThemeProperty("colors", "text") || "#cdd6f4"
        }
        
        Slider {
            visible: showSlider
            anchors.verticalCenter: parent.verticalCenter
            width: 80
            height: 16
            from: 0.0
            to: 1.0
            value: BrightnessService.brightness
            
            onValueChanged: {
                if (Math.abs(value - BrightnessService.brightness) > 0.01) {
                    BrightnessService.setBrightness(value)
                }
            }
            
            background: Rectangle {
                x: parent.leftPadding
                y: parent.topPadding + parent.availableHeight / 2 - height / 2
                implicitWidth: 80
                implicitHeight: 4
                width: parent.availableWidth
                height: implicitHeight
                radius: 2
                color: themeService?.getThemeProperty("colors", "surfaceAlt") || "#45475a"
                
                Rectangle {
                    width: parent.parent.visualPosition * parent.width
                    height: parent.height
                    color: themeService?.getThemeProperty("colors", "accent") || "#f9e2af"
                    radius: 2
                }
            }
            
            handle: Rectangle {
                x: parent.leftPadding + parent.visualPosition * (parent.availableWidth - width)
                y: parent.topPadding + parent.availableHeight / 2 - height / 2
                implicitWidth: 12
                implicitHeight: 12
                radius: 6
                color: parent.pressed ? 
                    (themeService?.getThemeProperty("colors", "accentAlt") || "#eba0ac") :
                    (themeService?.getThemeProperty("colors", "accent") || "#f9e2af")
                border.color: themeService?.getThemeProperty("colors", "border") || "#6c7086"
            }
        }
    }
    
    // Mouse interactions
    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
        hoverEnabled: true
        
        onClicked: mouse => {
            if (mouse.button === Qt.LeftButton) {
                if (!showSlider) cycleBrightness()
            } else if (mouse.button === Qt.RightButton) {
                const globalPos = brightnessWidget.mapToItem(null, mouse.x, mouse.y)
                contextMenu.show(anchorWindow, globalPos.x, globalPos.y)
            } else if (mouse.button === Qt.MiddleButton) {
                setBrightness(0.5)
            }
        }
        
        onWheel: wheel => {
            const delta = wheel.angleDelta.y > 0 ? 0.05 : -0.05
            adjustBrightness(delta)
        }
        
        onEntered: parent.parent && (parent.parent.opacity = 0.8)
        onExited: parent.parent && (parent.parent.opacity = 1.0)
    }
    
    Component.onCompleted: console.log("[BrightnessWidget] Initialized with BrightnessService singleton")
}