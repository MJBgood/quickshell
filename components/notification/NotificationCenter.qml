import Quickshell
import Quickshell.Hyprland
import QtQuick
import QtQuick.Controls
import "../shared"

PopupWindow {
    id: notificationCenter
    
    property var configService: ConfigService
    property var notificationService: NotificationService
    
    implicitWidth: 400
    implicitHeight: Math.min(600, Math.max(200, contentColumn.implicitHeight + 32))
    visible: false
    color: "transparent"
    
    signal closed()
    
    anchor {
        window: null
        rect { x: 0; y: 0; width: 1; height: 1 }
        edges: Edges.Top | Edges.Bottom | Edges.Left | Edges.Right
        gravity: Edges.Top | Edges.Bottom | Edges.Left | Edges.Right
        adjustment: PopupAdjustment.All
        margins { left: 16; right: 16; top: 16; bottom: 16 }
    }
    
    HyprlandFocusGrab {
        id: focusGrab
        windows: [notificationCenter]
        onCleared: hide()
    }
    
    Rectangle {
        anchors.fill: parent
        color: configService ? configService.getThemeProperty("colors", "surface") || "#313244" : "#313244"
        border.color: configService ? configService.getThemeProperty("colors", "border") || "#585b70" : "#585b70"
        border.width: 1
        radius: 12
        
        Column {
            id: contentColumn
            anchors.fill: parent
            anchors.margins: 16
            spacing: 12
            
            // Header
            Row {
                width: parent.width
                height: 32
                
                Text {
                    text: "Notifications"
                    font.pixelSize: 18
                    font.weight: Font.Bold
                    color: configService ? configService.getThemeProperty("colors", "text") || "#cdd6f4" : "#cdd6f4"
                    anchors.verticalCenter: parent.verticalCenter
                }
                
                Item { 
                    width: parent.width - 200
                    height: 1
                }
                
                Rectangle {
                    width: 24
                    height: 24
                    radius: 12
                    color: closeArea.containsMouse ? "#f38ba8" : "transparent"
                    anchors.verticalCenter: parent.verticalCenter
                    
                    Text {
                        anchors.centerIn: parent
                        text: "✕"
                        color: closeArea.containsMouse ? "#1e1e2e" : (configService ? configService.getThemeProperty("colors", "textAlt") || "#bac2de" : "#bac2de")
                        font.pixelSize: 12
                        font.weight: Font.Bold
                    }
                    
                    MouseArea {
                        id: closeArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: hide()
                    }
                }
            }
            
            // Notification list
            ScrollView {
                width: parent.width
                height: Math.min(500, contentHeight)
                clip: true
                
                Column {
                    width: parent.width
                    spacing: 12
                    
                    Repeater {
                        model: notificationService ? notificationService.allNotifications : []
                        
                        delegate: Rectangle {
                            width: parent.width
                            height: Math.max(100, notifContent.implicitHeight + 32)
                            color: configService ? configService.getThemeProperty("colors", "surfaceAlt") || "#45475a" : "#45475a"
                            border.color: configService ? configService.getThemeProperty("colors", "border") || "#585b70" : "#585b70"
                            border.width: 1
                            radius: 8
                            
                            Row {
                                id: notifContent
                                anchors.fill: parent
                                anchors.margins: 16
                                spacing: 16
                                
                                Rectangle {
                                    width: 32
                                    height: 32
                                    radius: 6
                                    color: configService ? configService.getThemeProperty("colors", "accent") || "#a6e3a1" : "#a6e3a1"
                                    anchors.verticalCenter: parent.verticalCenter
                                    
                                    Text {
                                        anchors.centerIn: parent
                                        text: modelData.appName ? modelData.appName.charAt(0).toUpperCase() : "?"
                                        font.pixelSize: 16
                                        font.weight: Font.Bold
                                        color: "#000000"
                                    }
                                }
                                
                                Column {
                                    width: parent.width - 80
                                    anchors.verticalCenter: parent.verticalCenter
                                    spacing: 6
                                    
                                    Text {
                                        text: modelData.summary || ""
                                        font.pixelSize: 14
                                        font.weight: Font.DemiBold
                                        color: configService ? configService.getThemeProperty("colors", "text") || "#cdd6f4" : "#cdd6f4"
                                        wrapMode: Text.WordWrap
                                        width: parent.width
                                    }
                                    
                                    Text {
                                        text: modelData.body || ""
                                        font.pixelSize: 12
                                        color: configService ? configService.getThemeProperty("colors", "textSecondary") || "#a6adc8" : "#a6adc8"
                                        wrapMode: Text.WordWrap
                                        width: parent.width
                                        visible: text.length > 0
                                    }
                                    
                                    Text {
                                        text: modelData.appName || ""
                                        font.pixelSize: 10
                                        color: configService ? configService.getThemeProperty("colors", "textTertiary") || "#6c7086" : "#6c7086"
                                    }
                                }
                                
                                Rectangle {
                                    width: 16
                                    height: 16
                                    radius: 8
                                    color: modelData.read ? "transparent" : "#f38ba8"
                                    anchors.verticalCenter: parent.verticalCenter
                                    visible: !modelData.read
                                }
                            }
                            
                            MouseArea {
                                anchors.fill: parent
                                onClicked: {
                                    if (notificationService) {
                                        notificationService.markAsRead(modelData.id)
                                    }
                                }
                            }
                        }
                    }
                    
                    Text {
                        visible: !notificationService || notificationService.totalCount === 0
                        text: "No notifications"
                        font.pixelSize: 14
                        color: configService ? configService.getThemeProperty("colors", "textSecondary") || "#a6adc8" : "#a6adc8"
                        anchors.horizontalCenter: parent.horizontalCenter
                    }
                }
            }
            
            // Actions
            Row {
                width: parent.width
                spacing: 8
                
                Rectangle {
                    width: (parent.width - 8) / 2
                    height: 32
                    color: configService ? configService.getThemeProperty("colors", "accent") || "#a6e3a1" : "#a6e3a1"
                    radius: 6
                    
                    Text {
                        anchors.centerIn: parent
                        text: "Mark All Read"
                        font.pixelSize: 12
                        font.weight: Font.Medium
                        color: "#000000"
                    }
                    
                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            if (notificationService) {
                                notificationService.markAllAsRead()
                            }
                        }
                    }
                }
                
                Rectangle {
                    width: (parent.width - 8) / 2
                    height: 32
                    color: configService ? configService.getThemeProperty("colors", "error") || "#f38ba8" : "#f38ba8"
                    radius: 6
                    
                    Text {
                        anchors.centerIn: parent
                        text: "Clear All"
                        font.pixelSize: 12
                        font.weight: Font.Medium
                        color: "#ffffff"
                    }
                    
                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            if (notificationService) {
                                notificationService.clearAll()
                            }
                        }
                    }
                }
            }
        }
    }
    
    function show(anchorWindow, x, y) {
        if (anchorWindow) {
            anchor.window = anchorWindow
            
            const screenWidth = anchorWindow.screen ? anchorWindow.screen.width : 1920
            const screenHeight = anchorWindow.screen ? anchorWindow.screen.height : 1080
            
            // Center the notification window on screen
            let popupX = (screenWidth - implicitWidth) / 2
            let popupY = (screenHeight - implicitHeight) / 2
            
            // Ensure it stays within screen bounds
            popupX = Math.max(20, Math.min(popupX, screenWidth - implicitWidth - 20))
            popupY = Math.max(20, Math.min(popupY, screenHeight - implicitHeight - 20))
            
            anchor.rect.x = popupX
            anchor.rect.y = popupY
        }
        
        visible = true
        focusGrab.active = true
    }
    
    function hide() {
        visible = false
        focusGrab.active = false
        closed()
    }
}