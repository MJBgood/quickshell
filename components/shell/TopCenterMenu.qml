import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import "../shared"
import "../cpu"
import "../ram"
import "../storage"
import "../notification"

Item {
    id: topCenterMenu
    
    property var configService: ConfigService
    
    // Fixed size - parent handles animation
    implicitWidth: 640
    implicitHeight: contentColumn.implicitHeight + 64
    
    // Main content container with caelestia styling
    Rectangle {
        id: contentContainer
        anchors.fill: parent
        radius: 24
        color: configService ? configService.getThemeProperty("colors", "surface") || "#313244" : "#313244"
        border.color: configService ? configService.getThemeProperty("colors", "border") || "#45475a" : "#45475a"
        border.width: 1
        
        Column {
            id: contentColumn
            anchors.fill: parent
            anchors.margins: 32
            spacing: 28
            
            // Header section
            Item {
                width: parent.width
                height: 48
                
                Text {
                    text: "System Overview"
                    font.pixelSize: 24
                    font.weight: Font.Medium
                    color: configService ? configService.getThemeProperty("colors", "text") || "#cdd6f4" : "#cdd6f4"
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                }
                
                Text {
                    text: Qt.formatDateTime(new Date(), "hh:mm")
                    font.pixelSize: 16
                    font.weight: Font.Normal
                    color: configService ? configService.getThemeProperty("colors", "textAlt") || "#9399b2" : "#9399b2"
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                }
            }
            
            // Metrics grid
            GridLayout {
                width: parent.width
                columns: 2
                columnSpacing: 20
                rowSpacing: 16
                
                // CPU Card
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 120
                    radius: 16
                    color: configService ? configService.getThemeProperty("colors", "surfaceContainer") || "#45475a" : "#45475a"
                    
                    property bool hovered: false
                    scale: hovered ? 1.02 : 1.0
                    Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
                    
                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        onEntered: parent.hovered = true
                        onExited: parent.hovered = false
                    }
                    
                    Row {
                        anchors.fill: parent
                        anchors.margins: 20
                        spacing: 16
                        
                        // Icon area
                        Rectangle {
                            width: 48
                            height: 48
                            radius: 12
                            color: "#89b4fa"
                            opacity: 0.15
                            anchors.verticalCenter: parent.verticalCenter
                            
                            Text {
                                text: "⚡"
                                font.pixelSize: 24
                                anchors.centerIn: parent
                            }
                        }
                        
                        // Content area
                        Column {
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 4
                            width: parent.width - 64 - 16
                            
                            Text {
                                text: "CPU Usage"
                                font.pixelSize: 16
                                font.weight: Font.Medium
                                color: configService ? configService.getThemeProperty("colors", "text") || "#cdd6f4" : "#cdd6f4"
                            }
                            
                            Text {
                                text: (CpuService && typeof CpuService.usage === 'number') ? `${CpuService.usage.toFixed(1)}%` : "0.0%"
                                font.pixelSize: 28
                                font.weight: Font.Bold
                                color: "#89b4fa"
                            }
                            
                            Rectangle {
                                width: parent.width
                                height: 6
                                radius: 3
                                color: configService ? configService.getThemeProperty("colors", "surfaceAlt") || "#585b70" : "#585b70"
                                
                                Rectangle {
                                    width: parent.width * (CpuService ? CpuService.usage / 100 : 0)
                                    height: parent.height
                                    radius: parent.radius
                                    color: "#89b4fa"
                                    
                                    Behavior on width {
                                        NumberAnimation { duration: 300; easing.type: Easing.OutCubic }
                                    }
                                }
                            }
                        }
                    }
                }
                
                // RAM Card
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 120
                    radius: 16
                    color: configService ? configService.getThemeProperty("colors", "surfaceContainer") || "#45475a" : "#45475a"
                    
                    property bool hovered: false
                    scale: hovered ? 1.02 : 1.0
                    Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
                    
                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        onEntered: parent.hovered = true
                        onExited: parent.hovered = false
                    }
                    
                    Row {
                        anchors.fill: parent
                        anchors.margins: 20
                        spacing: 16
                        
                        Rectangle {
                            width: 48
                            height: 48
                            radius: 12
                            color: "#74c7ec"
                            opacity: 0.15
                            anchors.verticalCenter: parent.verticalCenter
                            
                            Text {
                                text: "💾"
                                font.pixelSize: 24
                                anchors.centerIn: parent
                            }
                        }
                        
                        Column {
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 4
                            width: parent.width - 64 - 16
                            
                            Text {
                                text: "Memory"
                                font.pixelSize: 16
                                font.weight: Font.Medium
                                color: configService ? configService.getThemeProperty("colors", "text") || "#cdd6f4" : "#cdd6f4"
                            }
                            
                            Text {
                                text: (RamService && typeof RamService.percentage === 'number') ? `${RamService.percentage.toFixed(1)}%` : "0.0%"
                                font.pixelSize: 28
                                font.weight: Font.Bold
                                color: "#74c7ec"
                            }
                            
                            Rectangle {
                                width: parent.width
                                height: 6
                                radius: 3
                                color: configService ? configService.getThemeProperty("colors", "surfaceAlt") || "#585b70" : "#585b70"
                                
                                Rectangle {
                                    width: parent.width * (RamService ? RamService.percentage / 100 : 0)
                                    height: parent.height
                                    radius: parent.radius
                                    color: "#74c7ec"
                                    
                                    Behavior on width {
                                        NumberAnimation { duration: 300; easing.type: Easing.OutCubic }
                                    }
                                }
                            }
                        }
                    }
                }
                
                // Storage Card
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 120
                    radius: 16
                    color: configService ? configService.getThemeProperty("colors", "surfaceContainer") || "#45475a" : "#45475a"
                    
                    property bool hovered: false
                    scale: hovered ? 1.02 : 1.0
                    Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
                    
                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        onEntered: parent.hovered = true
                        onExited: parent.hovered = false
                    }
                    
                    Row {
                        anchors.fill: parent
                        anchors.margins: 20
                        spacing: 16
                        
                        Rectangle {
                            width: 48
                            height: 48
                            radius: 12
                            color: "#f38ba8"
                            opacity: 0.15
                            anchors.verticalCenter: parent.verticalCenter
                            
                            Text {
                                text: "💽"
                                font.pixelSize: 24
                                anchors.centerIn: parent
                            }
                        }
                        
                        Column {
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 4
                            width: parent.width - 64 - 16
                            
                            Text {
                                text: "Storage"
                                font.pixelSize: 16
                                font.weight: Font.Medium
                                color: configService ? configService.getThemeProperty("colors", "text") || "#cdd6f4" : "#cdd6f4"
                            }
                            
                            Text {
                                text: (StorageService && typeof StorageService.usagePercentage === 'number') ? `${StorageService.usagePercentage.toFixed(1)}%` : "0.0%"
                                font.pixelSize: 28
                                font.weight: Font.Bold
                                color: "#f38ba8"
                            }
                            
                            Rectangle {
                                width: parent.width
                                height: 6
                                radius: 3
                                color: configService ? configService.getThemeProperty("colors", "surfaceAlt") || "#585b70" : "#585b70"
                                
                                Rectangle {
                                    width: parent.width * (StorageService ? StorageService.usagePercentage / 100 : 0)
                                    height: parent.height
                                    radius: parent.radius
                                    color: "#f38ba8"
                                    
                                    Behavior on width {
                                        NumberAnimation { duration: 300; easing.type: Easing.OutCubic }
                                    }
                                }
                            }
                        }
                    }
                }
                
                // Notifications Card
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 120
                    radius: 16
                    color: configService ? configService.getThemeProperty("colors", "surfaceContainer") || "#45475a" : "#45475a"
                    
                    property bool hovered: false
                    scale: hovered ? 1.02 : 1.0
                    Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
                    
                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        onEntered: parent.hovered = true
                        onExited: parent.hovered = false
                    }
                    
                    Row {
                        anchors.fill: parent
                        anchors.margins: 20
                        spacing: 16
                        
                        Rectangle {
                            width: 48
                            height: 48
                            radius: 12
                            color: "#f9e2af"
                            opacity: 0.15
                            anchors.verticalCenter: parent.verticalCenter
                            
                            Text {
                                text: "🔔"
                                font.pixelSize: 24
                                anchors.centerIn: parent
                            }
                        }
                        
                        Column {
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 4
                            width: parent.width - 64 - 16
                            
                            Text {
                                text: "Notifications"
                                font.pixelSize: 16
                                font.weight: Font.Medium
                                color: configService ? configService.getThemeProperty("colors", "text") || "#cdd6f4" : "#cdd6f4"
                            }
                            
                            Text {
                                text: NotificationService ? `${NotificationService.totalCount}` : "0"
                                font.pixelSize: 28
                                font.weight: Font.Bold
                                color: "#f9e2af"
                            }
                            
                            Text {
                                text: NotificationService && NotificationService.unreadCount > 0 ? 
                                    `${NotificationService.unreadCount} unread` : "All caught up"
                                font.pixelSize: 12
                                color: configService ? configService.getThemeProperty("colors", "textAlt") || "#9399b2" : "#9399b2"
                            }
                        }
                    }
                }
            }
        }
    }
    
    Component.onCompleted: {
        console.log("[TopCenterMenu] Caelestia-style dashboard initialized")
    }
}