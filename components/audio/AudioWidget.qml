import QtQuick
import QtQuick.Controls
import Quickshell.Io
import "../shared"
import "../shared"

Rectangle {
    id: audioWidget
    
    // Entity ID for configuration
    property string entityId: "audioWidget"
    
    // Widget properties
    property bool enabled: configService ? configService.getEntityProperty(entityId, "enabled", true) : true
    property bool showIcon: configService ? configService.getEntityProperty(entityId, "showIcon", true) : true
    property bool showPercentage: configService ? configService.getEntityProperty(entityId, "showPercentage", true) : true
    property bool showSlider: configService ? configService.getEntityProperty(entityId, "showSlider", false) : false
    
    // Services
    property var configService: ConfigService
    property var anchorWindow: null
    
    // GraphicalComponent interface
    property string componentId: "audio"
    property string parentComponentId: ""
    property var childComponentIds: []
    property string menuPath: "audio"
    
    // Dynamic sizing based on content
    implicitWidth: audioContent.implicitWidth
    implicitHeight: audioContent.implicitHeight
    color: "transparent"
    
    // Context menu
    AudioContextMenu {
        id: contextMenu
        audioService: AudioService
        configService: audioWidget.configService
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
        id: audioContent
        anchors.centerIn: parent
        spacing: configService ? configService.spacing("xs", entityId) : 4
        
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
            font.pixelSize: configService ? configService.typography("md", entityId) : 14
            color: {
                return AudioService.muted ? 
                    (configService?.getThemeProperty("colors", "warning") || "#f9e2af"): 
                    (configService?.getThemeProperty("colors", "text") || "#cdd6f4")
            }
        }
        
        Text {
            visible: showPercentage && !showSlider
            anchors.verticalCenter: parent.verticalCenter
            text: `${Math.round(AudioService.volume * 100)}%`
            font.family: "Inter"
            font.pixelSize: configService ? configService.typography("xs", entityId) : 9
            font.weight: Font.Medium
            color: configService?.getThemeProperty("colors", "text") || "#cdd6f4"
        }
        
        Slider {
            visible: showSlider
            anchors.verticalCenter: parent.verticalCenter
            width: configService ? configService.scaled(80) : 80
            height: configService ? configService.scaled(16) : 16
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
                implicitWidth: configService ? configService.scaled(80) : 80
                implicitHeight: configService ? configService.scaled(4) : 4
                width: parent.availableWidth
                height: implicitHeight
                radius: configService ? configService.scaled(2) : 2
                color: configService?.getThemeProperty("colors", "surfaceAlt") || "#45475a"
                
                Rectangle {
                    width: parent.parent.visualPosition * parent.width
                    height: parent.height
                    color: configService?.getThemeProperty("colors", "primary") || "#89b4fa"
                    radius: configService ? configService.scaled(2) : 2
                }
            }
            
            handle: Rectangle {
                x: parent.leftPadding + parent.visualPosition * (parent.availableWidth - width)
                y: parent.topPadding + parent.availableHeight / 2 - height / 2
                implicitWidth: configService ? configService.scaled(12) : 12
                implicitHeight: configService ? configService.scaled(12) : 12
                radius: configService ? configService.scaled(6) : 6
                color: parent.pressed ? 
                    (configService?.getThemeProperty("colors", "primaryAlt") || "#74c7ec"): 
                    (configService?.getThemeProperty("colors", "primary") || "#89b4fa")
                border.color: configService?.getThemeProperty("colors", "border") || "#6c7086"
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
    
    // GraphicalComponent interface methods
    function menu(startPath) {
        const globalPos = audioWidget.mapToItem(null, 0, 0)
        contextMenu.show(anchorWindow, globalPos.x, globalPos.y)
    }
    
    function getParent() {
        // Return parent component reference if available
        return null
    }
    
    function getChildren() {
        // Return child components array
        return []
    }
    
    function navigateToParent() {
        // Navigate to parent menu if available
        if (getParent()) {
            getParent().menu()
        }
    }
    
    function navigateToChild(childId) {
        // Navigate to child menu - no children for audio widget
        console.log("AudioWidget has no child components")
    }
    
    Component.onCompleted: console.log("[AudioWidget] Initialized with AudioService singleton")
}