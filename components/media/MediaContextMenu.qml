import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import "../shared"

PopupWindow {
    id: contextMenu
    
    property var mediaService
    property var configService
    property var parentWindow
    
    visible: false
    width: configService ? configService.scaled(280) : 280
    height: Math.min(contentColumn.implicitHeight + (configService ? configService.scaled(20) : 20), 
                     configService ? configService.scaled(500) : 500)
    
    color: "transparent"
    
    HyprlandFocusGrab {
        windows: [contextMenu]
        onCleared: hide()
    }
    
    function show(window, x, y) {
        parentWindow = window
        contextMenu.x = x
        contextMenu.y = y
        visible = true
    }
    
    function hide() {
        visible = false
    }
    
    Rectangle {
        anchors.fill: parent
        color: configService?.getThemeProperty("colors", "surface") || "#313244"
        border.color: configService?.getThemeProperty("colors", "border") || "#6c7086"
        border.width: 1
        radius: configService ? configService.scaled(8) : 8
        
        Column {
            id: contentColumn
            anchors.fill: parent
            anchors.margins: configService ? configService.scaled(10) : 10
            spacing: configService ? configService.spacing("xs") : 4
            
            // Header
            ContextMenuSection {
                title: "Media Controls"
                configService: contextMenu.configService
            }
            
            // Player selection
            ContextMenuSection {
                title: "Active Player"
                configService: contextMenu.configService
                visible: mediaService && mediaService.availablePlayers.length > 1
                
                Column {
                    width: parent.width
                    spacing: 2
                    
                    Repeater {
                        model: mediaService ? mediaService.availablePlayers.length : 0
                        
                        Rectangle {
                            width: parent.width
                            height: 24
                            radius: 4
                            color: playerMouse.containsMouse ? 
                                (configService?.getThemeProperty("colors", "surfaceAlt") || "#45475a") : 
                                "transparent"
                            
                            property bool isActive: mediaService ? mediaService.activePlayerIndex === index : false
                            
                            Text {
                                anchors.left: parent.left
                                anchors.leftMargin: 8
                                anchors.verticalCenter: parent.verticalCenter
                                text: mediaService ? mediaService.getPlayerName(index) : ""
                                font.pixelSize: 10
                                color: configService?.getThemeProperty("colors", "text") || "#cdd6f4"
                            }
                            
                            Text {
                                anchors.right: parent.right
                                anchors.rightMargin: 8
                                anchors.verticalCenter: parent.verticalCenter
                                text: parent.isActive ? "✓" : ""
                                font.pixelSize: 10
                                color: "#a6e3a1"
                            }
                            
                            MouseArea {
                                id: playerMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                
                                onClicked: {
                                    if (mediaService) {
                                        mediaService.setActivePlayer(index)
                                    }
                                    hide()
                                }
                            }
                            
                            Behavior on color { ColorAnimation { duration: 150 } }
                        }
                    }
                }
            }
            
            // Current track info
            ContextMenuSection {
                title: "Now Playing"
                configService: contextMenu.configService
                visible: mediaService && mediaService.hasActivePlayer
                
                Column {
                    width: parent.width
                    spacing: 2
                    
                    Text {
                        text: mediaService ? mediaService.trackTitle || "Unknown Title" : ""
                        font.family: "Inter"
                        font.pixelSize: configService ? configService.typography("sm") : 12
                        font.weight: Font.Bold
                        color: configService?.getThemeProperty("colors", "text") || "#cdd6f4"
                        elide: Text.ElideRight
                        width: parent.width
                    }
                    
                    Text {
                        text: mediaService ? mediaService.trackArtist || "Unknown Artist" : ""
                        font.family: "Inter"
                        font.pixelSize: configService ? configService.typography("xs") : 10
                        color: configService?.getThemeProperty("colors", "textAlt") || "#bac2de"
                        elide: Text.ElideRight
                        width: parent.width
                    }
                    
                    Text {
                        visible: mediaService && mediaService.trackAlbum && mediaService.trackAlbum !== "Unknown Album"
                        text: mediaService ? mediaService.trackAlbum || "" : ""
                        font.family: "Inter"
                        font.pixelSize: configService ? configService.typography("xs") : 10
                        color: configService?.getThemeProperty("colors", "textAlt") || "#bac2de"
                        elide: Text.ElideRight
                        width: parent.width
                    }
                    
                    Text {
                        visible: mediaService && mediaService.positionSupported
                        text: {
                            if (!mediaService) return ""
                            return `${mediaService.formatTime(mediaService.position)} / ${mediaService.formatTime(mediaService.length)}`
                        }
                        font.family: "Inter"
                        font.pixelSize: configService ? configService.typography("xs") : 10
                        color: configService?.getThemeProperty("colors", "textAlt") || "#bac2de"
                    }
                }
            }
            
            // Widget configuration
            ContextMenuSection {
                title: "Widget Settings"
                configService: contextMenu.configService
                
                MenuItem {
                    text: "Show Album Art: " + (configService ? (configService.getEntityProperty("media.widget", "showAlbumArt", true) ? "Enabled" : "Disabled") : "Enabled")
                    configService: contextMenu.configService
                    
                    onClicked: {
                        const current = configService?.getEntityProperty("media.widget", "showAlbumArt", true) || true
                        configService?.setValue("entities.media.widget.showAlbumArt", !current)
                        hide()
                    }
                }
                
                MenuItem {
                    text: "Show Track Info: " + (configService ? (configService.getEntityProperty("media.widget", "showTrackInfo", true) ? "Enabled" : "Disabled") : "Enabled")
                    configService: contextMenu.configService
                    
                    onClicked: {
                        const current = configService?.getEntityProperty("media.widget", "showTrackInfo", true) || true
                        configService?.setValue("entities.media.widget.showTrackInfo", !current)
                        hide()
                    }
                }
                
                MenuItem {
                    text: "Show Controls: " + (configService ? (configService.getEntityProperty("media.widget", "showControls", true) ? "Enabled" : "Disabled") : "Enabled")
                    configService: contextMenu.configService
                    
                    onClicked: {
                        const current = configService?.getEntityProperty("media.widget", "showControls", true) || true
                        configService?.setValue("entities.media.widget.showControls", !current)
                        hide()
                    }
                }
                
                MenuItem {
                    text: "Show Volume Slider: " + (configService ? (configService.getEntityProperty("media.widget", "showVolumeSlider", false) ? "Enabled" : "Disabled") : "Disabled")
                    configService: contextMenu.configService
                    
                    onClicked: {
                        const current = configService?.getEntityProperty("media.widget", "showVolumeSlider", false) || false
                        configService?.setValue("entities.media.widget.showVolumeSlider", !current)
                        hide()
                    }
                }
                
                MenuItem {
                    text: "Show Progress Bar: " + (configService ? (configService.getEntityProperty("media.widget", "showProgress", false) ? "Enabled" : "Disabled") : "Disabled")
                    configService: contextMenu.configService
                    
                    onClicked: {
                        const current = configService?.getEntityProperty("media.widget", "showProgress", false) || false
                        configService?.setValue("entities.media.widget.showProgress", !current)
                        hide()
                    }
                }
                
                MenuItem {
                    text: "Compact Mode: " + (configService ? (configService.getEntityProperty("media.widget", "compactMode", false) ? "Enabled" : "Disabled") : "Disabled")
                    configService: contextMenu.configService
                    
                    onClicked: {
                        const current = configService?.getEntityProperty("media.widget", "compactMode", false) || false
                        configService?.setValue("entities.media.widget.compactMode", !current)
                        hide()
                    }
                }
            }
            
            // Album art size settings
            ContextMenuSection {
                title: "Album Art Size"
                configService: contextMenu.configService
                visible: configService ? configService.getEntityProperty("media.widget", "showAlbumArt", true) : true
                
                MenuItem {
                    text: "Small (32px)" + ((configService ? configService.getEntityProperty("media.widget", "albumArtSize", 48) : 48) === 32 ? " ✓" : "")
                    configService: contextMenu.configService
                    
                    onClicked: {
                        configService?.setValue("entities.media.widget.albumArtSize", 32)
                        hide()
                    }
                }
                
                MenuItem {
                    text: "Medium (48px)" + ((configService ? configService.getEntityProperty("media.widget", "albumArtSize", 48) : 48) === 48 ? " ✓" : "")
                    configService: contextMenu.configService
                    
                    onClicked: {
                        configService?.setValue("entities.media.widget.albumArtSize", 48)
                        hide()
                    }
                }
                
                MenuItem {
                    text: "Large (64px)" + ((configService ? configService.getEntityProperty("media.widget", "albumArtSize", 48) : 48) === 64 ? " ✓" : "")
                    configService: contextMenu.configService
                    
                    onClicked: {
                        configService?.setValue("entities.media.widget.albumArtSize", 64)
                        hide()
                    }
                }
            }
            
            // Track width settings
            ContextMenuSection {
                title: "Max Track Width"
                configService: contextMenu.configService
                
                MenuItem {
                    text: "Narrow (150px)" + ((configService ? configService.getEntityProperty("media.widget", "maxTrackWidth", 200) : 200) === 150 ? " ✓" : "")
                    configService: contextMenu.configService
                    
                    onClicked: {
                        configService?.setValue("entities.media.widget.maxTrackWidth", 150)
                        hide()
                    }
                }
                
                MenuItem {
                    text: "Medium (200px)" + ((configService ? configService.getEntityProperty("media.widget", "maxTrackWidth", 200) : 200) === 200 ? " ✓" : "")
                    configService: contextMenu.configService
                    
                    onClicked: {
                        configService?.setValue("entities.media.widget.maxTrackWidth", 200)
                        hide()
                    }
                }
                
                MenuItem {
                    text: "Wide (300px)" + ((configService ? configService.getEntityProperty("media.widget", "maxTrackWidth", 200) : 200) === 300 ? " ✓" : "")
                    configService: contextMenu.configService
                    
                    onClicked: {
                        configService?.setValue("entities.media.widget.maxTrackWidth", 300)
                        hide()
                    }
                }
            }
            
            // Refresh players
            ContextMenuSection {
                title: "Actions"
                configService: contextMenu.configService
                
                MenuItem {
                    text: "Refresh Players"
                    configService: contextMenu.configService
                    
                    onClicked: {
                        if (mediaService) {
                            mediaService.updatePlayerList()
                        }
                        hide()
                    }
                }
            }
        }
    }
}