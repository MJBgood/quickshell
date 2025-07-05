import QtQuick
import QtQuick.Controls
import Quickshell
import "../../services"
import "../overlays"

Rectangle {
    id: powerWidget
    
    // Widget properties
    property bool enabled: true
    property bool showIcon: true
    property bool showText: false
    
    // Services
    property var configService: null
    property var themeService: null
    property var anchorWindow: null
    
    // Session overlay control
    property var sessionOverlay: null
    
    // GraphicalComponent interface
    property string componentId: "power"
    property string parentComponentId: ""
    property var childComponentIds: []
    property string menuPath: "power"
    
    // Size configuration
    implicitWidth: showIcon ? (showText ? 90 : 28) : (showText ? 70 : 24)
    implicitHeight: 22
    color: "transparent"
    
    // Context menu (kept for right-click fallback)
    PowerContextMenu {
        id: contextMenu
        powerService: PowerManagementService
        themeService: powerWidget.themeService
        visible: false
    }
    
    // Content layout
    Row {
        anchors.centerIn: parent
        spacing: 4
        
        Text {
            visible: showIcon
            anchors.verticalCenter: parent.verticalCenter
            text: "⏻"
            font.pixelSize: 16
            color: themeService?.getThemeProperty("colors", "text") || "#cdd6f4"
        }
        
        Text {
            visible: showText
            anchors.verticalCenter: parent.verticalCenter
            text: "Power"
            font.family: "Inter"
            font.pixelSize: 10
            font.weight: Font.Medium
            color: themeService?.getThemeProperty("colors", "text") || "#cdd6f4"
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
    
    Component.onCompleted: {
        console.log("[PowerWidget] Initialized with PowerManagementService")
        console.log("[PowerWidget] Visible:", visible, "Width:", implicitWidth, "Height:", implicitHeight)
        console.log("[PowerWidget] ShowIcon:", showIcon, "ShowText:", showText)
    }
}