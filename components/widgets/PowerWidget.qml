import QtQuick
import QtQuick.Controls
import Quickshell
import "../../services"
import "../overlays"

Rectangle {
    id: powerWidget
    
    // Entity ID for configuration
    property string entityId: "powerWidget"
    
    // Widget properties
    property bool enabled: configService ? configService.getEntityProperty(entityId, "enabled", true) : true
    property bool showIcon: configService ? configService.getEntityProperty(entityId, "showIcon", true) : true
    property bool showText: configService ? configService.getEntityProperty(entityId, "showText", false) : false
    
    // Services
    property var configService: ConfigService
    property var anchorWindow: null
    
    // Session overlay control
    property var sessionOverlay: null
    
    // GraphicalComponent interface
    property string componentId: "power_widget"
    property string parentComponentId: ""
    property var childComponentIds: []
    property string menuPath: "power"
    
    // Dynamic sizing based on content
    implicitWidth: powerContent.implicitWidth + (configService ? configService.spacing("sm", entityId) : 12)
    implicitHeight: configService ? configService.getWidgetHeight(entityId, powerContent.implicitHeight) : powerContent.implicitHeight
    color: configService ? configService.getEntityStyle(entityId, "backgroundColor", "auto", "transparent") : "transparent"
    
    // Context menu (kept for right-click fallback)
    PowerContextMenu {
        id: contextMenu
        powerService: PowerManagementService
        configService: powerWidget.configService
        visible: false
    }
    
    // Content layout
    Row {
        id: powerContent
        anchors.centerIn: parent
        spacing: configService ? configService.spacing("xs", entityId) : 4
        
        Text {
            visible: showIcon
            anchors.verticalCenter: parent.verticalCenter
            text: "⏻"
            font.pixelSize: configService ? configService.typography(configService.getEntityProperty(entityId, "fontSize", "md"), entityId) : 20
            color: configService ? configService.getEntityStyle(entityId, "iconColor", "auto", configService.getThemeProperty("colors", "text") || "#cdd6f4") : "#cdd6f4"
        }
        
        Text {
            visible: showText
            anchors.verticalCenter: parent.verticalCenter
            text: "Power"
            font.family: "Inter"
            font.pixelSize: configService ? configService.typography("xs", entityId) : 9
            font.weight: Font.Medium
            color: configService ? configService.getEntityStyle(entityId, "textColor", "auto", configService.getThemeProperty("colors", "text") || "#cdd6f4") : "#cdd6f4"
        }
    }
    
    // Mouse interactions - Show power menu for all interactions
    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        hoverEnabled: true
        
        onClicked: function(mouse) {
            if (mouse.button === Qt.LeftButton) {
                // Left click - Toggle session overlay (like temp-repos example)
                console.log("[PowerWidget] Power button clicked - toggling session overlay")
                if (sessionOverlay) {
                    sessionOverlay.sessionVisible = !sessionOverlay.sessionVisible
                }
            } else if (mouse.button === Qt.RightButton) {
                // Right click - Show context menu (fallback)
                console.log("[PowerWidget] Right click - showing context menu")
                const globalPos = powerWidget.mapToItem(null, mouse.x, mouse.y)
                contextMenu.show(anchorWindow, globalPos.x, globalPos.y)
            }
        }
        
        onEntered: parent.parent && (parent.parent.opacity = 0.8)
        onExited: parent.parent && (parent.parent.opacity = 1.0)
    }
    
    // GraphicalComponent interface methods
    function menu(anchorWindow, x, y, startPath) {
        console.log(`[${componentId}] Opening power context menu`)
        const windowToUse = anchorWindow || powerWidget.anchorWindow
        contextMenu.show(windowToUse, x || 0, y || 0)
    }
    
    function getParent() {
        return null // No parent component
    }
    
    function getChildren() {
        return [] // No child components
    }
    
    function navigateToParent() {
        // No parent to navigate to
        console.log(`[${componentId}] No parent component to navigate to`)
    }
    
    function navigateToChild(childId) {
        // No children to navigate to
        console.log(`[${componentId}] No child components to navigate to`)
    }
    
    Component.onCompleted: {
        console.log("[PowerWidget] Initialized with PowerManagementService")
        console.log("[PowerWidget] Visible:", visible, "Width:", implicitWidth, "Height:", implicitHeight)
        console.log("[PowerWidget] ShowIcon:", showIcon, "ShowText:", showText)
        
        // Register with WidgetRegistry
        WidgetRegistry.registerWidget({
            id: "power-widget",
            name: "Power Widget",
            description: "Session management and power controls",
            category: "power",
            icon: "⏻",
            component: "PowerWidget",
            contextMenu: "PowerContextMenu",
            configKeys: ["power.enabled", "power.showIcon", "power.showText"],
            size: { width: implicitWidth, height: implicitHeight },
            position: 20
        })
    }
}