import Quickshell
import Quickshell.Hyprland
import QtQuick
import QtQuick.Controls
import "../../services"
import "../base"

PopupWindow {
    id: contextMenu
    
    // Services
    property var configService: ConfigService
    property var notificationService: NotificationService
    property string entityId: "notificationWidget"
    
    // Window properties
    implicitWidth: 280
    implicitHeight: Math.min(350, 300)
    visible: false
    color: "transparent"
    
    // Signals
    signal closed()
    
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
    
    // Main container
    Rectangle {
        anchors.fill: parent
        color: configService ? configService.getThemeProperty("colors", "surface") || "#313244" : "#313244"
        border.color: configService ? configService.getThemeProperty("colors", "border") || "#585b70" : "#585b70"
        border.width: 1
        radius: 12
        
        ScrollView {
            anchors.fill: parent
            anchors.margins: 16
            clip: true
            
            Component.onCompleted: {
                ScrollBar.horizontal.policy = ScrollBar.AlwaysOff
                ScrollBar.vertical.policy = ScrollBar.AsNeeded
            }
            
            Column {
                id: menuContent
                width: Math.max(parent.width - 16, 240)
                spacing: 12
                
                // Header (following SystemTrayContextMenu pattern)
                Row {
                    width: parent.width
                    height: 32
                    spacing: 8
                    
                    // Notification icon (SVG with fallback)
                    Image {
                        width: 20
                        height: 20
                        anchors.verticalCenter: parent.verticalCenter
                        source: "../../assets/icons/bell.svg"
                        fillMode: Image.PreserveAspectFit
                        smooth: true
                        
                        // Fallback to geometric bell if SVG fails
                        Rectangle {
                            visible: parent.status === Image.Error
                            anchors.centerIn: parent
                            width: parent.width * 0.7
                            height: parent.height * 0.6
                            color: "transparent"
                            border.color: configService ? configService.getThemeProperty("colors", "accent") || "#a6e3a1" : "#a6e3a1"
                            border.width: 2
                            radius: 3
                        }
                    }
                    
                    Column {
                        anchors.verticalCenter: parent.verticalCenter
                        width: parent.width - 100
                        
                        Text {
                            text: "Notification Settings"
                            font.pixelSize: 14
                            font.weight: Font.DemiBold
                            color: configService ? configService.getThemeProperty("colors", "text") || "#cdd6f4" : "#cdd6f4"
                        }
                        
                        Text {
                            text: "Manage notifications and popups"
                            font.pixelSize: 10
                            color: configService ? configService.getThemeProperty("colors", "textAlt") || "#bac2de" : "#bac2de"
                        }
                    }
                    
                    // Close button
                    Rectangle {
                        width: 24
                        height: 24
                        radius: 12
                        color: closeArea.containsMouse ? "#f38ba8" : "transparent"
                        
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
                
                // Mark all as read button
                Rectangle {
                    width: parent.width
                    height: 40
                    color: configService ? configService.getThemeProperty("colors", "surfaceAlt") || "#45475a" : "#45475a"
                    border.color: configService ? configService.getThemeProperty("colors", "border") || "#585b70" : "#585b70"
                    border.width: 1
                    radius: 8
                    
                    Row {
                        anchors.fill: parent
                        anchors.margins: 12
                        spacing: 12
                        
                        Text {
                            text: "Mark All as Read"
                            anchors.verticalCenter: parent.verticalCenter
                            font.pixelSize: 12
                            color: configService ? configService.getThemeProperty("colors", "text") || "#cdd6f4" : "#cdd6f4"
                            width: parent.width - 60
                        }
                        
                        Text {
                            text: notificationService ? notificationService.unreadCount.toString() : "0"
                            anchors.verticalCenter: parent.verticalCenter
                            font.pixelSize: 10
                            font.weight: Font.Bold
                            color: configService ? configService.getThemeProperty("colors", "accent") || "#a6e3a1" : "#a6e3a1"
                        }
                    }
                    
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (notificationService) {
                                notificationService.markAllAsRead()
                            }
                        }
                    }
                }
                
                // Clear all notifications button
                Rectangle {
                    width: parent.width
                    height: 40
                    color: configService ? configService.getThemeProperty("colors", "surfaceAlt") || "#45475a" : "#45475a"
                    border.color: configService ? configService.getThemeProperty("colors", "border") || "#585b70" : "#585b70"
                    border.width: 1
                    radius: 8
                    
                    Row {
                        anchors.fill: parent
                        anchors.margins: 12
                        spacing: 12
                        
                        Text {
                            text: "Clear All Notifications"
                            anchors.verticalCenter: parent.verticalCenter
                            font.pixelSize: 12
                            color: configService ? configService.getThemeProperty("colors", "text") || "#cdd6f4" : "#cdd6f4"
                            width: parent.width - 60
                        }
                        
                        Text {
                            text: notificationService ? notificationService.totalCount.toString() : "0"
                            anchors.verticalCenter: parent.verticalCenter
                            font.pixelSize: 10
                            font.weight: Font.Bold
                            color: configService ? configService.getThemeProperty("colors", "textAlt") || "#bac2de" : "#bac2de"
                        }
                    }
                    
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (notificationService) {
                                notificationService.clearAll()
                            }
                        }
                    }
                }
                
                // Toggle popups
                Rectangle {
                    width: parent.width
                    height: 40
                    color: configService ? configService.getThemeProperty("colors", "surfaceAlt") || "#45475a" : "#45475a"
                    border.color: configService ? configService.getThemeProperty("colors", "border") || "#585b70" : "#585b70"
                    border.width: 1
                    radius: 8
                    
                    Row {
                        anchors.fill: parent
                        anchors.margins: 12
                        spacing: 12
                        
                        Text {
                            text: "Show Popup Notifications"
                            anchors.verticalCenter: parent.verticalCenter
                            font.pixelSize: 12
                            color: configService ? configService.getThemeProperty("colors", "text") || "#cdd6f4" : "#cdd6f4"
                            width: parent.width - 60
                        }
                        
                        Rectangle {
                            width: 40
                            height: 20
                            radius: 10
                            color: getPopupsEnabled() ? "#a6e3a1" : (configService ? configService.getThemeProperty("colors", "border") || "#585b70" : "#585b70")
                            border.width: 1
                            border.color: configService ? configService.getThemeProperty("colors", "border") || "#585b70" : "#585b70"
                            
                            Rectangle {
                                width: 16
                                height: 16
                                radius: 8
                                color: "#ffffff"
                                anchors.verticalCenter: parent.verticalCenter
                                x: getPopupsEnabled() ? parent.width - width - 2 : 2
                                
                                Behavior on x {
                                    NumberAnimation { duration: 150 }
                                }
                            }
                            
                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: togglePopups()
                            }
                        }
                    }
                }
            }
        }
    }
    
    // Standard show/hide functions (EXACTLY as working examples)
    function show(anchorWindow, x, y) {
        if (anchorWindow) {
            anchor.window = anchorWindow
            
            const screenWidth = anchorWindow.screen ? anchorWindow.screen.width : 1920
            const screenHeight = anchorWindow.screen ? anchorWindow.screen.height : 1080
            
            let popupX = Math.min(x || 0, screenWidth - implicitWidth - 20)
            let popupY = Math.min(y || 0, screenHeight - implicitHeight - 20)
            
            popupX = Math.max(20, popupX)
            popupY = Math.max(20, popupY)
            
            anchor.rect.x = popupX
            anchor.rect.y = popupY
            anchor.rect.width = 1
            anchor.rect.height = 1
        }
        
        visible = true
        focusGrab.active = true
        console.log("[NotificationContextMenu] Initialized")
    }
    
    function hide() {
        visible = false
        focusGrab.active = false
        closed()
    }
    
    // Entity-aware configuration helpers
    function getPopupsEnabled() {
        return configService ? configService.getEntityProperty(entityId, "popupsEnabled", true) : true
    }
    
    function togglePopups() {
        if (configService) {
            const newValue = !getPopupsEnabled()
            configService.setEntityProperty(entityId, "popupsEnabled", newValue)
            configService.saveConfig()
        }
    }
}