import QtQuick
import QtQuick.Controls
import "../../services"
import "../overlays"

Rectangle {
    id: brightnessWidget
    
    // Entity ID for configuration
    property string entityId: "brightnessWidget"
    
    // Widget properties
    property bool enabled: configService ? configService.getEntityProperty(entityId, "enabled", true) : true
    property bool showIcon: configService ? configService.getEntityProperty(entityId, "showIcon", true) : true
    property bool showPercentage: configService ? configService.getEntityProperty(entityId, "showPercentage", true) : true
    property bool showSlider: configService ? configService.getEntityProperty(entityId, "showSlider", false) : false
    
    // Services
    property var configService: ConfigService
    property var anchorWindow: null
    
    // GraphicalComponent interface
    property string componentId: "brightness"
    property string parentComponentId: ""
    property var childComponentIds: []
    property string menuPath: "brightness"
    
    // Dynamic sizing based on content
    implicitWidth: brightnessContent.implicitWidth + (configService ? configService.spacing("sm", entityId) : 12)
    implicitHeight: brightnessContent.implicitHeight
    color: "transparent"
    
    // Context menu
    BrightnessContextMenu {
        id: contextMenu
        brightnessService: BrightnessService
        configService: brightnessWidget.configService
        visible: false
    }
    
    // Delegate functions to service
    function setBrightness(brightness) { return BrightnessService.setBrightness(brightness) }
    function adjustBrightness(delta) { return BrightnessService.adjustBrightness(delta) }
    function cycleBrightness() { return BrightnessService.cycleBrightness() }
    function updateBrightness() { return BrightnessService.updateBrightness() }
    
    // GraphicalComponent interface methods
    function menu(startPath) {
        const globalPos = brightnessWidget.mapToItem(null, width / 2, height / 2)
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
        id: brightnessContent
        anchors.centerIn: parent
        spacing: configService ? configService.spacing("xs", entityId) : 4
        
        Text {
            visible: showIcon
            anchors.verticalCenter: parent.verticalCenter
            text: {
                if (BrightnessService.brightness > 0.8) return "☀"    // High brightness - sun
                if (BrightnessService.brightness > 0.5) return "💡"   // Medium brightness - lightbulb
                if (BrightnessService.brightness > 0.2) return "🔅"   // Low brightness - dim
                return "🌙"  // Very low brightness - moon
            }
            font.pixelSize: configService ? configService.typography("xs", entityId) : 10
            color: configService?.getThemeProperty("colors", "text") || "#cdd6f4"
        }
        
        Text {
            visible: showPercentage && !showSlider
            anchors.verticalCenter: parent.verticalCenter
            text: `${Math.round(BrightnessService.brightness * 100)}%`
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
            value: BrightnessService.brightness
            
            onValueChanged: {
                if (Math.abs(value - BrightnessService.brightness) > 0.01) {
                    BrightnessService.setBrightness(value)
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
                    color: configService?.getThemeProperty("colors", "accent") || "#f9e2af"
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
                    (configService?.getThemeProperty("colors", "accentAlt") || "#eba0ac"): 
                    (configService?.getThemeProperty("colors", "accent") || "#f9e2af")
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
    
    // Component lifecycle
    Component.onCompleted: {
        console.log("[BrightnessWidget] Initialized with BrightnessService singleton")
        
        // Register component with parent if it exists
        if (parent && parent.registerChild) {
            parent.registerChild(componentId, brightnessWidget)
        }
    }
    
    Component.onDestruction: {
        console.log("[BrightnessWidget] Cleaning up component")
        
        // Unregister component from parent if it exists
        if (parent && parent.unregisterChild) {
            parent.unregisterChild(componentId)
        }
    }
}