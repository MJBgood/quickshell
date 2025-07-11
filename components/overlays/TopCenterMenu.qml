import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import "../../services"
import "../widgets"

Item {
    id: topCenterMenu
    
    property var configService: ConfigService
    
    // Caelestia-style layout following their dashboard structure
    readonly property int padding: 24
    readonly property int spacing: 16
    
    implicitWidth: 560
    implicitHeight: dashboardContent.implicitHeight + (padding * 2)
    
    // Main content in row layout (like caelestia's dashboard)
    RowLayout {
        id: dashboardContent
        anchors.fill: parent
        anchors.margins: padding
        spacing: spacing * 2
        
        // Left column - Main dashboard info
        Column {
            Layout.alignment: Qt.AlignTop
            Layout.preferredWidth: 200
            spacing: spacing
            
            // User/System card (caelestia pattern)
            DashboardCard {
                width: parent.width
                height: 120
                
                Column {
                    anchors.centerIn: parent
                    spacing: 8
                    
                    MaterialIcon {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: "computer"
                        font.pointSize: 24
                        color: configService.getThemeProperty("colors", "primary") || "#89b4fa"
                    }
                    
                    StyledText {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: "QuickShell"
                        font.pointSize: 16
                        font.weight: Font.Medium
                    }
                    
                    StyledText {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: Qt.formatTime(new Date(), "hh:mm")
                        font.pointSize: 14
                        color: configService.getThemeProperty("colors", "onSurfaceVariant") || "#a6adc8"
                    }
                }
            }
            
            // Quick actions card
            DashboardCard {
                width: parent.width
                height: 160
                
                Column {
                    anchors.fill: parent
                    anchors.margins: 16
                    spacing: 12
                    
                    StyledText {
                        text: "Quick Actions"
                        font.pointSize: 14
                        font.weight: Font.Medium
                        color: configService.getThemeProperty("colors", "onSurfaceVariant") || "#a6adc8"
                    }
                    
                    // Action buttons
                    Column {
                        width: parent.width
                        spacing: 8
                        
                        QuickActionButton {
                            width: parent.width
                            icon: "settings"
                            text: "Settings"
                            onClicked: console.log("Settings clicked")
                        }
                        
                        QuickActionButton {
                            width: parent.width
                            icon: "wallpaper"
                            text: "Wallpaper"
                            onClicked: console.log("Wallpaper clicked")
                        }
                        
                        QuickActionButton {
                            width: parent.width
                            icon: "power_settings_new"
                            text: "Power"
                            onClicked: console.log("Power clicked")
                        }
                    }
                }
            }
        }
        
        // Right column - System resources (caelestia Performance component pattern)
        Column {
            Layout.alignment: Qt.AlignTop
            Layout.fillWidth: true
            spacing: spacing
            
            // System resources card
            DashboardCard {
                width: parent.width
                height: 200
                
                Column {
                    anchors.fill: parent
                    anchors.margins: 16
                    spacing: 16
                    
                    StyledText {
                        text: "System Resources"
                        font.pointSize: 14
                        font.weight: Font.Medium
                        color: configService.getThemeProperty("colors", "onSurfaceVariant") || "#a6adc8"
                    }
                    
                    // Resource items in grid
                    GridLayout {
                        width: parent.width
                        columns: 2
                        columnSpacing: 16
                        rowSpacing: 12
                        
                        // CPU
                        ResourceItem {
                            Layout.fillWidth: true
                            icon: Icons.getCpuIcon()
                            label: "CPU"
                            value: CpuService ? CpuService.usage.toFixed(1) + "%" : "0%"
                            progress: CpuService ? CpuService.usage / 100 : 0
                        }
                        
                        // RAM  
                        ResourceItem {
                            Layout.fillWidth: true
                            icon: Icons.getMemoryIcon()
                            label: "RAM"
                            value: RamService ? (RamService.usedMemory / 1024 / 1024 / 1024).toFixed(1) + " GB" : "0 GB"
                            progress: RamService ? RamService.memoryUsage / 100 : 0
                        }
                        
                        // GPU
                        ResourceItem {
                            Layout.fillWidth: true
                            icon: Icons.getGpuIcon()
                            label: "GPU"
                            value: GpuService ? GpuService.usage.toFixed(1) + "%" : "0%"
                            progress: GpuService ? GpuService.usage / 100 : 0
                        }
                        
                        // Storage
                        ResourceItem {
                            Layout.fillWidth: true
                            icon: Icons.getStorageIcon()
                            label: "Storage"
                            value: StorageService ? StorageService.usage.toFixed(1) + "%" : "0%"
                            progress: StorageService ? StorageService.usage / 100 : 0
                        }
                    }
                }
            }
            
            // Network/connectivity card
            DashboardCard {
                width: parent.width
                height: 80
                
                Row {
                    anchors.centerIn: parent
                    spacing: 24
                    
                    // Network status
                    Row {
                        spacing: 8
                        anchors.verticalCenter: parent.verticalCenter
                        
                        MaterialIcon {
                            text: "wifi"
                            color: configService.getThemeProperty("colors", "success") || "#a6e3a1"
                            font.pointSize: 16
                        }
                        
                        StyledText {
                            text: "Connected"
                            font.pointSize: 12
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }
                    
                    // Volume status
                    Row {
                        spacing: 8
                        anchors.verticalCenter: parent.verticalCenter
                        
                        MaterialIcon {
                            text: AudioService ? (AudioService.muted ? "volume_off" : "volume_up") : "volume_up"
                            color: configService.getThemeProperty("colors", "onSurface") || "#cdd6f4"
                            font.pointSize: 16
                        }
                        
                        StyledText {
                            text: AudioService ? Math.round(AudioService.volume * 100) + "%" : "50%"
                            font.pointSize: 12
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }
                }
            }
        }
    }
    
    // Dashboard card component (caelestia style)
    component DashboardCard: Rectangle {
        color: configService ? configService.getThemeProperty("colors", "surfaceContainer") || "#45475a" : "#45475a"
        radius: 16
        border.color: configService ? configService.getThemeProperty("colors", "outline") || "#6c7086" : "#6c7086"
        border.width: 1
        opacity: 0.95
        
        // Subtle hover effect
        property bool hovered: false
        scale: hovered ? 1.02 : 1.0
        Behavior on scale {
            NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
        }
        
        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            onEntered: parent.hovered = true
            onExited: parent.hovered = false
        }
    }
    
    // Resource item component (caelestia style)
    component ResourceItem: Item {
        property string icon: ""
        property string label: ""
        property string value: ""
        property real progress: 0
        
        height: 40
        
        Row {
            anchors.fill: parent
            spacing: 8
            
            MaterialIcon {
                text: parent.parent.icon
                color: configService.getThemeProperty("colors", "primary") || "#89b4fa"
                font.pointSize: 16
                anchors.verticalCenter: parent.verticalCenter
            }
            
            Column {
                anchors.verticalCenter: parent.verticalCenter
                spacing: 2
                
                StyledText {
                    text: parent.parent.label
                    font.pointSize: 11
                    color: configService.getThemeProperty("colors", "onSurfaceVariant") || "#a6adc8"
                }
                
                StyledText {
                    text: parent.parent.value
                    font.pointSize: 12
                    font.weight: Font.Medium
                }
            }
        }
        
        // Progress indicator
        Rectangle {
            anchors.bottom: parent.bottom
            width: parent.width * progress
            height: 2
            color: configService.getThemeProperty("colors", "primary") || "#89b4fa"
            radius: 1
            
            Behavior on width {
                NumberAnimation { duration: 300; easing.type: Easing.OutCubic }
            }
        }
    }
    
    // Quick action button component
    component QuickActionButton: Rectangle {
        property string icon: ""
        property string text: ""
        signal clicked()
        
        height: 32
        color: mouseArea.containsMouse ? 
            (configService ? configService.getThemeProperty("colors", "surface") || "#313244" : "#313244") :
            "transparent"
        radius: 8
        
        Row {
            anchors.centerIn: parent
            spacing: 8
            
            MaterialIcon {
                text: parent.parent.icon
                color: configService.getThemeProperty("colors", "onSurface") || "#cdd6f4"
                font.pointSize: 14
                anchors.verticalCenter: parent.verticalCenter
            }
            
            StyledText {
                text: parent.parent.text
                font.pointSize: 12
                anchors.verticalCenter: parent.verticalCenter
            }
        }
        
        MouseArea {
            id: mouseArea
            anchors.fill: parent
            hoverEnabled: true
            onClicked: parent.clicked()
        }
        
        Behavior on color {
            ColorAnimation { duration: 150; easing.type: Easing.OutCubic }
        }
    }
}