import QtQuick
import QtQuick.Controls
import Quickshell.Io
import "../../services"
import "../overlays"

Rectangle {
    id: audioWidget
    
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
    property string componentId: "audio"
    property string parentComponentId: ""
    property var childComponentIds: []
    property string menuPath: "audio"
    
    // Size configuration
    implicitWidth: showSlider ? 120 : (showIcon && showPercentage ? 60 : showIcon ? 24 : 40)
    implicitHeight: 20
    color: "transparent"
    
    // Context menu
    AudioContextMenu {
        id: contextMenu
        audioService: AudioService
        themeService: audioWidget.themeService
        visible: false
    }
    
    // Process for launching pavucontrol
    Process {
        id: pavucontrolProcess
        command: ["pavucontrol"]
        running: false
    }
    
    // Delegate functions to service
    function setVolume(volume) { return AudioService.setVolume(volume) }
    function toggleMute() { return AudioService.toggleMute() }
    function adjustVolume(delta) { return AudioService.adjustVolume(delta) }
    
    // Content layout
    Row {
        anchors.centerIn: parent
        spacing: 4
        
        Text {
            visible: showIcon
            anchors.verticalCenter: parent.verticalCenter
            text: {
                if (AudioService.muted) return "🔇"
                if (AudioService.volume > 0.6) return "🔊"
                if (AudioService.volume > 0.3) return "🔉"
                if (AudioService.volume > 0.0) return "🔈"
                return "🔇"
            }
            font.pixelSize: 14
            color: {
                return AudioService.muted ? 
                    (themeService?.getThemeProperty("colors", "warning") || "#f9e2af") :
                    (themeService?.getThemeProperty("colors", "text") || "#cdd6f4")
            }
        }
        
        Text {
            visible: showPercentage && !showSlider
            anchors.verticalCenter: parent.verticalCenter
            text: `${Math.round(AudioService.volume * 100)}%`
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
            value: AudioService.volume
            
            onValueChanged: {
                if (Math.abs(value - AudioService.volume) > 0.01) {
                    AudioService.setVolume(value)
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
                    color: themeService?.getThemeProperty("colors", "primary") || "#89b4fa"
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
                    (themeService?.getThemeProperty("colors", "primaryAlt") || "#74c7ec") :
                    (themeService?.getThemeProperty("colors", "primary") || "#89b4fa")
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
                if (showSlider) {
                    // Allow slider interaction when in slider mode
                    return
                } else {
                    // Open audio control (like Waybar does)
                    pavucontrolProcess.running = true
                }
            } else if (mouse.button === Qt.RightButton) {
                const globalPos = audioWidget.mapToItem(null, mouse.x, mouse.y)
                contextMenu.show(anchorWindow, globalPos.x, globalPos.y)
            } else if (mouse.button === Qt.MiddleButton) {
                toggleMute()
            }
        }
        
        onWheel: wheel => {
            console.log("[AudioWidget] Wheel event detected:", wheel.angleDelta.y)
            const delta = wheel.angleDelta.y > 0 ? 0.05 : -0.05
            console.log("[AudioWidget] Adjusting volume by:", delta, "Current volume:", AudioService.volume)
            const result = adjustVolume(delta)
            console.log("[AudioWidget] Adjust volume result:", result)
        }
        
        onEntered: parent.parent && (parent.parent.opacity = 0.8)
        onExited: parent.parent && (parent.parent.opacity = 1.0)
    }
    
    Component.onCompleted: console.log("[AudioWidget] Initialized with AudioService singleton")
}