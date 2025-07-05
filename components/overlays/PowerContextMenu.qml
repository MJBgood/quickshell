import Quickshell
import Quickshell.Hyprland
import QtQuick
import QtQuick.Controls
import "../../services"

PopupWindow {
    id: contextMenu
    
    // Services
    property var powerService: null
    property var themeService: null
    
    // Standard window properties
    implicitWidth: 180
    implicitHeight: Math.min(400, menuContent.contentHeight + 32)
    visible: false
    color: "transparent"
    
    // Anchor configuration (EXACTLY as working examples)
    anchor {
        window: null
        rect { x: 0; y: 0; width: 1; height: 1 }
        edges: Edges.Top | Edges.Left
        gravity: Edges.Bottom | Edges.Right
        adjustment: PopupAdjustment.All
        margins { left: 8; right: 8; top: 8; bottom: 8 }
    }
    
    // Focus grab for dismissal (CRITICAL)
    HyprlandFocusGrab {
        id: focusGrab
        windows: [contextMenu]
        onCleared: hide()
    }
    
    // Content structure
    Rectangle {
        anchors.fill: parent
        color: themeService ? themeService.getThemeProperty("colors", "surface") || "#313244" : "#313244"
        border.color: themeService ? themeService.getThemeProperty("colors", "border") || "#6c7086" : "#6c7086"
        border.width: 1
        radius: 8
        
        ScrollView {
            id: menuContent
            anchors.fill: parent
            anchors.margins: 8
            
            Column {
                width: menuContent.width
                spacing: 4
                
                Text {
                    text: "Power Options"
                    font.family: "Inter"
                    font.pixelSize: 14
                    font.weight: Font.DemiBold
                    color: themeService ? themeService.getThemeProperty("colors", "text") || "#cdd6f4" : "#cdd6f4"
                    anchors.horizontalCenter: parent.horizontalCenter
                }
                
                Rectangle {
                    width: parent.width
                    height: 1
                    color: themeService ? themeService.getThemeProperty("colors", "border") || "#6c7086" : "#6c7086"
                }
                
                // Power action buttons
                Repeater {
                    model: powerService ? powerService.getAvailableActions() : []
                    
                    Rectangle {
                        width: parent.width
                        height: 36
                        color: powerActionMouse.containsMouse ? 
                            (themeService ? themeService.getThemeProperty("colors", "surfaceHover") || "#383849" : "#383849") :
                            "transparent"
                        radius: 4
                        
                        Row {
                            anchors.left: parent.left
                            anchors.leftMargin: 12
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 8
                            
                            Text {
                                text: powerService ? powerService.getActionIcon(modelData) : ""
                                font.pixelSize: 14
                                anchors.verticalCenter: parent.verticalCenter
                            }
                            
                            Text {
                                text: powerService ? powerService.getActionLabel(modelData) : ""
                                font.family: "Inter"
                                font.pixelSize: 12
                                font.weight: Font.Medium
                                color: {
                                    if (modelData === "poweroff" || modelData === "reboot") {
                                        return themeService ? themeService.getThemeProperty("colors", "error") || "#f38ba8" : "#f38ba8"
                                    }
                                    return themeService ? themeService.getThemeProperty("colors", "text") || "#cdd6f4" : "#cdd6f4"
                                }
                                anchors.verticalCenter: parent.verticalCenter
                            }
                        }
                        
                        MouseArea {
                            id: powerActionMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            
                            onClicked: {
                                console.log("[PowerContextMenu] Action selected:", modelData)
                                
                                if (!powerService) {
                                    console.error("[PowerContextMenu] PowerService not available")
                                    return
                                }
                                
                                var success = false
                                switch (modelData) {
                                    case "lock":
                                        success = powerService.lockScreen()
                                        break
                                    case "logout":
                                        success = powerService.logout()
                                        break
                                    case "suspend":
                                        success = powerService.suspend()
                                        break
                                    case "hibernate":
                                        success = powerService.hibernate()
                                        break
                                    case "reboot":
                                        success = powerService.reboot()
                                        break
                                    case "poweroff":
                                        success = powerService.powerOff()
                                        break
                                }
                                
                                if (success) {
                                    hide()
                                } else {
                                    console.log("[PowerContextMenu] Action requires confirmation or failed")
                                    // Keep menu open for confirmation dialog
                                }
                            }
                        }
                        
                        // Hover highlight
                        Behavior on color {
                            ColorAnimation { duration: 150 }
                        }
                    }
                }
                
                Rectangle {
                    width: parent.width
                    height: 1
                    color: themeService ? themeService.getThemeProperty("colors", "border") || "#6c7086" : "#6c7086"
                }
                
                // System information
                Column {
                    width: parent.width
                    spacing: 2
                    
                    Text {
                        text: "System Status"
                        font.family: "Inter"
                        font.pixelSize: 10
                        font.weight: Font.Medium
                        color: themeService ? themeService.getThemeProperty("colors", "textAlt") || "#bac2de" : "#bac2de"
                        anchors.horizontalCenter: parent.horizontalCenter
                    }
                    
                    Text {
                        text: powerService && powerService.ready ? "Power management ready" : "Checking capabilities..."
                        font.family: "Inter"
                        font.pixelSize: 9
                        color: themeService ? themeService.getThemeProperty("colors", "textAlt") || "#bac2de" : "#bac2de"
                        anchors.horizontalCenter: parent.horizontalCenter
                    }
                }
            }
        }
    }
    
    // Standard show/hide functions
    function show(anchorWindow, x, y) {
        anchor.window = anchorWindow
        anchor.rect.x = x
        anchor.rect.y = y
        visible = true
        focusGrab.active = true
    }
    
    function hide() {
        visible = false
        focusGrab.active = false
    }
}