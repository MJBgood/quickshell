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
    implicitWidth: configService ? configService.scaled(280) : 280
    implicitHeight: Math.min(400, menuContent.contentHeight + 32)
    
    color: "transparent"
    
    // Anchor configuration (matching working examples)
    anchor {
        window: null
        rect { x: 0; y: 0; width: 1; height: 1 }
        edges: Edges.Top | Edges.Left
        gravity: Edges.Bottom | Edges.Right
        adjustment: PopupAdjustment.All
        margins { left: 8; right: 8; top: 8; bottom: 8 }
    }
    
    HyprlandFocusGrab {
        id: focusGrab
        windows: [contextMenu]
        onCleared: hide()
    }
    
    function show(anchorWindow, x, y) {
        console.log("[MediaContextMenu] show() called with window:", anchorWindow, "pos:", x, y)
        if (!anchorWindow) {
            console.log("[MediaContextMenu] Error: anchorWindow is null")
            return
        }
        parentWindow = anchorWindow
        anchor.window = anchorWindow
        anchor.rect.x = x
        anchor.rect.y = y
        visible = true
        focusGrab.active = true
        console.log("[MediaContextMenu] Context menu should now be visible at", x, y)
    }
    
    function hide() {
        visible = false
        focusGrab.active = false
    }
    
    Rectangle {
        anchors.fill: parent
        color: configService?.getThemeProperty("colors", "surface") || "#313244"
        border.color: configService?.getThemeProperty("colors", "border") || "#6c7086"
        border.width: 1
        radius: configService ? configService.scaled(8) : 8
        
        ScrollView {
            id: menuContent
            anchors.fill: parent
            anchors.margins: configService ? configService.scaled(12) : 12
            
            Column {
                id: contentColumn
                width: menuContent.availableWidth
                spacing: configService ? configService.spacing("sm") : 8
            
            // Header
            ContextMenuHeader {
                title: "Media Controls"
                configService: contextMenu.configService
            }
            
            // Separator
            Rectangle {
                width: contentColumn.width
                height: 1
                color: configService?.getThemeProperty("colors", "border") || "#6c7086"
                opacity: 0.3
            }
            
            // Player selection
            ContextMenuHeader {
                title: "Active Player"
                configService: contextMenu.configService
                visible: mediaService && mediaService.availablePlayers.length > 1
            }
            
            Column {
                width: contentColumn.width
                spacing: 2
                visible: mediaService && mediaService.availablePlayers.length > 1
                
                Repeater {
                    model: mediaService ? mediaService.availablePlayers.length : 0
                    
                    Rectangle {
                        width: contentColumn.width
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
            
            // Separator (only show when Now Playing section is visible)
            Rectangle {
                width: contentColumn.width
                height: 1
                color: configService?.getThemeProperty("colors", "border") || "#6c7086"
                opacity: 0.3
                visible: mediaService && mediaService.hasActivePlayer
            }
            
            // Current track info
            ContextMenuHeader {
                title: "Now Playing"
                configService: contextMenu.configService
                visible: mediaService && mediaService.hasActivePlayer
            }
            
            Column {
                width: contentColumn.width
                spacing: 2
                visible: mediaService && mediaService.hasActivePlayer
                
                Text {
                    text: mediaService ? mediaService.trackTitle || "Unknown Title" : ""
                    font.family: "Inter"
                    font.pixelSize: configService ? configService.typography("sm") : 12
                    font.weight: Font.Bold
                    color: configService?.getThemeProperty("colors", "text") || "#cdd6f4"
                    elide: Text.ElideRight
                    width: contentColumn.width
                }
                
                Text {
                    text: mediaService ? mediaService.trackArtist || "Unknown Artist" : ""
                    font.family: "Inter"
                    font.pixelSize: configService ? configService.typography("xs") : 10
                    color: configService?.getThemeProperty("colors", "textAlt") || "#bac2de"
                    elide: Text.ElideRight
                    width: contentColumn.width
                }
                
                Text {
                    visible: mediaService && mediaService.trackAlbum && mediaService.trackAlbum !== "Unknown Album"
                    text: mediaService ? mediaService.trackAlbum || "" : ""
                    font.family: "Inter"
                    font.pixelSize: configService ? configService.typography("xs") : 10
                    color: configService?.getThemeProperty("colors", "textAlt") || "#bac2de"
                    elide: Text.ElideRight
                    width: contentColumn.width
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
            
            // Separator
            Rectangle {
                width: contentColumn.width
                height: 1
                color: configService?.getThemeProperty("colors", "border") || "#6c7086"
                opacity: 0.3
            }
            
            // Widget configuration
            ContextMenuHeader {
                title: "Widget Settings"
                configService: contextMenu.configService
            }
            
            Column {
                width: contentColumn.width
                spacing: 2
                
                MenuItem {
                    width: contentColumn.width
                    text: "Show Album Art: " + (configService ? (configService.getEntityProperty("media.widget", "showAlbumArt", true) ? "Enabled" : "Disabled") : "Enabled")
                    configService: contextMenu.configService
                    
                    onClicked: {
                        const current = configService?.getEntityProperty("media.widget", "showAlbumArt", true) || true
                        configService?.setValue("entities.media.widget.showAlbumArt", !current)
                    }
                }
                
                MenuItem {
                    width: contentColumn.width
                    text: "Show Track Info: " + (configService ? (configService.getEntityProperty("media.widget", "showTrackInfo", true) ? "Enabled" : "Disabled") : "Enabled")
                    configService: contextMenu.configService
                    
                    onClicked: {
                        const current = configService?.getEntityProperty("media.widget", "showTrackInfo", true) || true
                        configService?.setValue("entities.media.widget.showTrackInfo", !current)
                    }
                }
                
                MenuItem {
                    width: contentColumn.width
                    text: "Show Controls: " + (configService ? (configService.getEntityProperty("media.widget", "showControls", true) ? "Enabled" : "Disabled") : "Enabled")
                    configService: contextMenu.configService
                    
                    onClicked: {
                        const current = configService?.getEntityProperty("media.widget", "showControls", true) || true
                        configService?.setValue("entities.media.widget.showControls", !current)
                    }
                }
                
                MenuItem {
                    width: contentColumn.width
                    text: "Show Volume Slider: " + (configService ? (configService.getEntityProperty("media.widget", "showVolumeSlider", false) ? "Enabled" : "Disabled") : "Disabled")
                    configService: contextMenu.configService
                    
                    onClicked: {
                        const current = configService?.getEntityProperty("media.widget", "showVolumeSlider", false) || false
                        configService?.setValue("entities.media.widget.showVolumeSlider", !current)
                    }
                }
                
                MenuItem {
                    width: contentColumn.width
                    text: "Show Progress Bar: " + (configService ? (configService.getEntityProperty("media.widget", "showProgress", false) ? "Enabled" : "Disabled") : "Disabled")
                    configService: contextMenu.configService
                    
                    onClicked: {
                        const current = configService?.getEntityProperty("media.widget", "showProgress", false) || false
                        configService?.setValue("entities.media.widget.showProgress", !current)
                    }
                }
                
                MenuItem {
                    width: contentColumn.width
                    text: "Compact Mode: " + (configService ? (configService.getEntityProperty("media.widget", "compactMode", false) ? "Enabled" : "Disabled") : "Disabled")
                    configService: contextMenu.configService
                    
                    onClicked: {
                        const current = configService?.getEntityProperty("media.widget", "compactMode", false) || false
                        configService?.setValue("entities.media.widget.compactMode", !current)
                    }
                }
            }
            
            // Separator
            Rectangle {
                width: contentColumn.width
                height: 1
                color: configService?.getThemeProperty("colors", "border") || "#6c7086"
                opacity: 0.3
                visible: configService ? configService.getEntityProperty("media.widget", "showAlbumArt", true) : true
            }
            
            // Album art size settings
            ContextMenuHeader {
                title: "Album Art Size"
                configService: contextMenu.configService
                visible: configService ? configService.getEntityProperty("media.widget", "showAlbumArt", true) : true
            }
            
            Column {
                width: contentColumn.width
                spacing: 2
                visible: configService ? configService.getEntityProperty("media.widget", "showAlbumArt", true) : true
                
                MenuItem {
                    width: contentColumn.width
                    text: "Small (32px)" + ((configService ? configService.getEntityProperty("media.widget", "albumArtSize", 48) : 48) === 32 ? " ✓" : "")
                    configService: contextMenu.configService
                    
                    onClicked: {
                        configService?.setValue("entities.media.widget.albumArtSize", 32)
                        hide()
                    }
                }
                
                MenuItem {
                    width: contentColumn.width
                    text: "Medium (48px)" + ((configService ? configService.getEntityProperty("media.widget", "albumArtSize", 48) : 48) === 48 ? " ✓" : "")
                    configService: contextMenu.configService
                    
                    onClicked: {
                        configService?.setValue("entities.media.widget.albumArtSize", 48)
                        hide()
                    }
                }
                
                MenuItem {
                    width: contentColumn.width
                    text: "Large (64px)" + ((configService ? configService.getEntityProperty("media.widget", "albumArtSize", 48) : 48) === 64 ? " ✓" : "")
                    configService: contextMenu.configService
                    
                    onClicked: {
                        configService?.setValue("entities.media.widget.albumArtSize", 64)
                        hide()
                    }
                }
            }
            
            // Separator
            Rectangle {
                width: contentColumn.width
                height: 1
                color: configService?.getThemeProperty("colors", "border") || "#6c7086"
                opacity: 0.3
            }
            
            // Track width settings
            ContextMenuHeader {
                title: "Max Track Width"
                configService: contextMenu.configService
            }
            
            Column {
                width: contentColumn.width
                spacing: 2
                
                MenuItem {
                    width: contentColumn.width
                    text: "Narrow (150px)" + ((configService ? configService.getEntityProperty("media.widget", "maxTrackWidth", 200) : 200) === 150 ? " ✓" : "")
                    configService: contextMenu.configService
                    
                    onClicked: {
                        configService?.setValue("entities.media.widget.maxTrackWidth", 150)
                        hide()
                    }
                }
                
                MenuItem {
                    width: contentColumn.width
                    text: "Medium (200px)" + ((configService ? configService.getEntityProperty("media.widget", "maxTrackWidth", 200) : 200) === 200 ? " ✓" : "")
                    configService: contextMenu.configService
                    
                    onClicked: {
                        configService?.setValue("entities.media.widget.maxTrackWidth", 200)
                        hide()
                    }
                }
                
                MenuItem {
                    width: contentColumn.width
                    text: "Wide (300px)" + ((configService ? configService.getEntityProperty("media.widget", "maxTrackWidth", 200) : 200) === 300 ? " ✓" : "")
                    configService: contextMenu.configService
                    
                    onClicked: {
                        configService?.setValue("entities.media.widget.maxTrackWidth", 300)
                        hide()
                    }
                }
            }
            
            // Separator
            Rectangle {
                width: contentColumn.width
                height: 1
                color: configService?.getThemeProperty("colors", "border") || "#6c7086"
                opacity: 0.3
            }
            
            // Refresh players
            ContextMenuHeader {
                title: "Actions"
                configService: contextMenu.configService
            }
            
            Column {
                width: contentColumn.width
                spacing: 2
                
                MenuItem {
                    width: contentColumn.width
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
}