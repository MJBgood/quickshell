import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import "../shared"

Rectangle {
    id: mediaWidget
    
    // Entity ID for configuration
    property string entityId: "media.widget"
    
    // Widget properties - check the main config key that Bar.qml was checking
    property bool enabled: configService ? configService.getValue("media.enabled", false) : false
    property bool showAlbumArt: configService ? configService.getEntityProperty(entityId, "showAlbumArt", true) : true
    property bool showTrackInfo: configService ? configService.getEntityProperty(entityId, "showTrackInfo", true) : true
    property bool showControls: configService ? configService.getEntityProperty(entityId, "showControls", true) : true
    property bool showVolumeSlider: configService ? configService.getEntityProperty(entityId, "showVolumeSlider", false) : false
    property bool showProgress: configService ? configService.getEntityProperty(entityId, "showProgress", false) : false
    property bool compactMode: configService ? configService.getEntityProperty(entityId, "compactMode", false) : false
    property int albumArtSize: configService ? configService.getEntityProperty(entityId, "albumArtSize", 48) : 48
    property int maxTrackWidth: configService ? configService.getEntityProperty(entityId, "maxTrackWidth", 200) : 200
    
    // Services
    property var configService: ConfigService
    property var anchorWindow: null
    
    // GraphicalComponent interface
    property string componentId: "media"
    property string parentComponentId: ""
    property var childComponentIds: []
    property string menuPath: "media"
    
    // Dynamic sizing based on content and mode
    implicitWidth: compactMode ? compactContent.implicitWidth : expandedContent.implicitWidth
    implicitHeight: compactMode ? compactContent.implicitHeight : expandedContent.implicitHeight
    color: "transparent"
    
    // Professional context menu matching codebase patterns
    MediaContextMenu {
        id: contextMenu
        mediaService: MediaService
        configService: mediaWidget.configService
        parentWindow: anchorWindow
    }
    
    
    
    // Overall widget visibility - show if enabled (MediaService.hasActivePlayer changes too late for container sizing)
    visible: enabled
    
    // Delegate functions to service
    function play() { return MediaService.play() }
    function pause() { return MediaService.pause() }
    function togglePlayPause() { return MediaService.togglePlayPause() }
    function next() { return MediaService.next() }
    function previous() { return MediaService.previous() }
    function setVolume(volume) { return MediaService.setVolume(volume) }
    function seek(offset) { return MediaService.seek(offset) }
    
    // Compact mode layout
    Row {
        id: compactContent
        visible: compactMode
        anchors.centerIn: parent
        spacing: configService ? configService.spacing("xs", entityId) : 4
        
        // Album art (small)
        Rectangle {
            visible: showAlbumArt && MediaService.hasActivePlayer
            width: configService ? configService.scaled(24) : 24
            height: width
            radius: configService ? configService.scaled(4) : 4
            color: configService?.getThemeProperty("colors", "surface") || "#313244"
            
            Image {
                anchors.fill: parent
                source: {
                    const artUrl = MediaService.albumArtUrl || ""
                    // Filter out invalid or inaccessible file paths
                    if (artUrl.startsWith("file://") && artUrl.includes("/tmp/")) {
                        return ""  // Skip temp files that may not exist
                    }
                    return artUrl
                }
                fillMode: Image.PreserveAspectCrop
                visible: source.toString().length > 0
                onStatusChanged: {
                    if (status === Image.Error) {
                        console.log("[MediaWidget] Failed to load album art:", source)
                    }
                }
                
                Rectangle {
                    anchors.fill: parent
                    visible: !parent.visible
                    color: "transparent"
                    border.color: configService?.getThemeProperty("colors", "border") || "#6c7086"
                    border.width: 1
                    radius: configService ? configService.scaled(4) : 4
                    
                    Text {
                        anchors.centerIn: parent
                        text: "♪"
                        font.pixelSize: configService ? configService.typography("sm", entityId) : 12
                        color: configService?.getThemeProperty("colors", "textAlt") || "#bac2de"
                    }
                }
            }
        }
        
        // Play/pause button (compact)
        Rectangle {
            visible: showControls && MediaService.hasActivePlayer
            width: configService ? configService.scaled(20) : 20
            height: width
            radius: width / 2
            color: playPauseCompactMouse.pressed ? 
                (configService?.getThemeProperty("colors", "primaryAlt") || "#74c7ec") :
                (configService?.getThemeProperty("colors", "primary") || "#89b4fa")
            
            Text {
                anchors.centerIn: parent
                text: MediaService.isPlaying ? "⏸" : "▶"
                font.pixelSize: configService ? configService.typography("xs", entityId) : 10
                color: configService?.getThemeProperty("colors", "onPrimary") || "#1e1e2e"
            }
            
            MouseArea {
                id: playPauseCompactMouse
                anchors.fill: parent
                onClicked: togglePlayPause()
                hoverEnabled: true
            }
        }
        
        // Track info (compact)
        Text {
            visible: showTrackInfo && MediaService.hasActivePlayer
            anchors.verticalCenter: parent.verticalCenter
            text: {
                if (!MediaService.hasActivePlayer) return "No Media"
                const title = MediaService.trackTitle || "Unknown"
                const artist = MediaService.trackArtist || "Unknown Artist"
                return compactMode ? title : `${title} - ${artist}`
            }
            font.family: "Inter"
            font.pixelSize: configService ? configService.typography("xs", entityId) : 9
            font.weight: Font.Medium
            color: configService?.getThemeProperty("colors", "text") || "#cdd6f4"
            elide: Text.ElideRight
            width: Math.min(implicitWidth, configService ? configService.scaled(maxTrackWidth / 2) : 100)
        }
    }
    
    // Expanded mode layout
    Column {
        id: expandedContent
        visible: !compactMode
        anchors.centerIn: parent
        spacing: configService ? configService.spacing("xs", entityId) : 4
        
        // Main content row
        Row {
            spacing: configService ? configService.spacing("sm", entityId) : 8
            
            // Album art
            Rectangle {
                visible: showAlbumArt && MediaService.hasActivePlayer
                width: configService ? configService.scaled(albumArtSize) : albumArtSize
                height: width
                radius: configService ? configService.scaled(8) : 8
                color: configService?.getThemeProperty("colors", "surface") || "#313244"
                
                Image {
                    anchors.fill: parent
                    source: {
                        const artUrl = MediaService.albumArtUrl || ""
                        // Filter out invalid or inaccessible file paths
                        if (artUrl.startsWith("file://") && artUrl.includes("/tmp/")) {
                            return ""  // Skip temp files that may not exist
                        }
                        return artUrl
                    }
                    fillMode: Image.PreserveAspectCrop
                    visible: source.toString().length > 0
                    onStatusChanged: {
                        if (status === Image.Error) {
                            console.log("[MediaWidget] Failed to load album art:", source)
                        }
                    }
                    
                    Rectangle {
                        anchors.fill: parent
                        visible: !parent.visible
                        color: "transparent"
                        border.color: configService?.getThemeProperty("colors", "border") || "#6c7086"
                        border.width: 1
                        radius: configService ? configService.scaled(8) : 8
                        
                        Text {
                            anchors.centerIn: parent
                            text: "♪"
                            font.pixelSize: configService ? configService.typography("lg", entityId) : 20
                            color: configService?.getThemeProperty("colors", "textAlt") || "#bac2de"
                        }
                    }
                }
            }
            
            // Track info and controls
            Column {
                visible: MediaService.hasActivePlayer
                spacing: configService ? configService.spacing("xs", entityId) : 4
                
                // Track information
                Column {
                    visible: showTrackInfo
                    spacing: 2
                    
                    Text {
                        text: MediaService.trackTitle || "Unknown Title"
                        font.family: "Inter"
                        font.pixelSize: configService ? configService.typography("sm", entityId) : 11
                        font.weight: Font.Bold
                        color: configService?.getThemeProperty("colors", "text") || "#cdd6f4"
                        elide: Text.ElideRight
                        width: Math.min(implicitWidth, configService ? configService.scaled(maxTrackWidth) : maxTrackWidth)
                    }
                    
                    Text {
                        text: MediaService.trackArtist || "Unknown Artist"
                        font.family: "Inter"
                        font.pixelSize: configService ? configService.typography("xs", entityId) : 9
                        font.weight: Font.Normal
                        color: configService?.getThemeProperty("colors", "textAlt") || "#bac2de"
                        elide: Text.ElideRight
                        width: Math.min(implicitWidth, configService ? configService.scaled(maxTrackWidth) : maxTrackWidth)
                    }
                    
                    Text {
                        visible: MediaService.trackAlbum && MediaService.trackAlbum !== "Unknown Album"
                        text: MediaService.trackAlbum || ""
                        font.family: "Inter"
                        font.pixelSize: configService ? configService.typography("xs", entityId) : 9
                        font.weight: Font.Normal
                        color: configService?.getThemeProperty("colors", "textAlt") || "#bac2de"
                        elide: Text.ElideRight
                        width: Math.min(implicitWidth, configService ? configService.scaled(maxTrackWidth) : maxTrackWidth)
                    }
                }
                
                // Media controls
                Row {
                    visible: showControls
                    spacing: configService ? configService.spacing("xs", entityId) : 4
                    
                    // Previous button
                    Rectangle {
                        width: configService ? configService.scaled(24) : 24
                        height: width
                        radius: width / 2
                        color: previousMouse.pressed ? 
                            (configService?.getThemeProperty("colors", "surfaceAlt") || "#45475a") :
                            (configService?.getThemeProperty("colors", "surface") || "#313244")
                        opacity: MediaService.canGoPrevious ? 1.0 : 0.5
                        
                        Text {
                            anchors.centerIn: parent
                            text: "⏮"
                            font.pixelSize: configService ? configService.typography("xs", entityId) : 10
                            color: configService?.getThemeProperty("colors", "text") || "#cdd6f4"
                        }
                        
                        MouseArea {
                            id: previousMouse
                            anchors.fill: parent
                            enabled: MediaService.canGoPrevious
                            onClicked: previous()
                            hoverEnabled: true
                        }
                    }
                    
                    // Play/pause button
                    Rectangle {
                        width: configService ? configService.scaled(28) : 28
                        height: width
                        radius: width / 2
                        color: playPauseMouse.pressed ? 
                            (configService?.getThemeProperty("colors", "primaryAlt") || "#74c7ec") :
                            (configService?.getThemeProperty("colors", "primary") || "#89b4fa")
                        
                        Text {
                            anchors.centerIn: parent
                            text: MediaService.isPlaying ? "⏸" : "▶"
                            font.pixelSize: configService ? configService.typography("sm", entityId) : 12
                            color: configService?.getThemeProperty("colors", "onPrimary") || "#1e1e2e"
                        }
                        
                        MouseArea {
                            id: playPauseMouse
                            anchors.fill: parent
                            onClicked: togglePlayPause()
                            hoverEnabled: true
                        }
                    }
                    
                    // Next button
                    Rectangle {
                        width: configService ? configService.scaled(24) : 24
                        height: width
                        radius: width / 2
                        color: nextMouse.pressed ? 
                            (configService?.getThemeProperty("colors", "surfaceAlt") || "#45475a") :
                            (configService?.getThemeProperty("colors", "surface") || "#313244")
                        opacity: MediaService.canGoNext ? 1.0 : 0.5
                        
                        Text {
                            anchors.centerIn: parent
                            text: "⏭"
                            font.pixelSize: configService ? configService.typography("xs", entityId) : 10
                            color: configService?.getThemeProperty("colors", "text") || "#cdd6f4"
                        }
                        
                        MouseArea {
                            id: nextMouse
                            anchors.fill: parent
                            enabled: MediaService.canGoNext
                            onClicked: next()
                            hoverEnabled: true
                        }
                    }
                }
                
                // Progress bar
                Rectangle {
                    visible: showProgress && MediaService.positionSupported && MediaService.length > 0
                    width: configService ? configService.scaled(maxTrackWidth) : maxTrackWidth
                    height: configService ? configService.scaled(4) : 4
                    radius: height / 2
                    color: configService?.getThemeProperty("colors", "surfaceAlt") || "#45475a"
                    
                    Rectangle {
                        width: MediaService.length > 0 ? (MediaService.position / MediaService.length) * parent.width : 0
                        height: parent.height
                        radius: parent.radius
                        color: configService?.getThemeProperty("colors", "primary") || "#89b4fa"
                    }
                    
                    MouseArea {
                        anchors.fill: parent
                        onClicked: mouse => {
                            if (MediaService.length > 0) {
                                const newPosition = (mouse.x / width) * MediaService.length
                                MediaService.setPosition(newPosition)
                            }
                        }
                    }
                }
                
                // Time display
                Row {
                    visible: showProgress && MediaService.positionSupported
                    spacing: configService ? configService.spacing("xs", entityId) : 4
                    
                    Text {
                        text: MediaService.formatTime(MediaService.position)
                        font.family: "Inter"
                        font.pixelSize: configService ? configService.typography("xs", entityId) : 9
                        color: configService?.getThemeProperty("colors", "textAlt") || "#bac2de"
                    }
                    
                    Text {
                        text: "/"
                        font.family: "Inter"
                        font.pixelSize: configService ? configService.typography("xs", entityId) : 9
                        color: configService?.getThemeProperty("colors", "textAlt") || "#bac2de"
                    }
                    
                    Text {
                        text: MediaService.formatTime(MediaService.length)
                        font.family: "Inter"
                        font.pixelSize: configService ? configService.typography("xs", entityId) : 9
                        color: configService?.getThemeProperty("colors", "textAlt") || "#bac2de"
                    }
                }
            }
        }
        
        // Volume slider
        Slider {
            visible: showVolumeSlider && MediaService.volumeSupported && MediaService.hasActivePlayer
            width: configService ? configService.scaled(maxTrackWidth) : maxTrackWidth
            height: configService ? configService.scaled(16) : 16
            from: 0.0
            to: 1.0
            value: MediaService.volume
            
            onValueChanged: {
                if (Math.abs(value - MediaService.volume) > 0.01) {
                    MediaService.setVolume(value)
                }
            }
            
            background: Rectangle {
                x: parent.leftPadding
                y: parent.topPadding + parent.availableHeight / 2 - height / 2
                implicitWidth: configService ? configService.scaled(maxTrackWidth) : maxTrackWidth
                implicitHeight: configService ? configService.scaled(4) : 4
                width: parent.availableWidth
                height: implicitHeight
                radius: configService ? configService.scaled(2) : 2
                color: configService?.getThemeProperty("colors", "surfaceAlt") || "#45475a"
                
                Rectangle {
                    width: parent.parent.visualPosition * parent.width
                    height: parent.height
                    color: configService?.getThemeProperty("colors", "primary") || "#89b4fa"
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
                    (configService?.getThemeProperty("colors", "primaryAlt") || "#74c7ec") :
                    (configService?.getThemeProperty("colors", "primary") || "#89b4fa")
                border.color: configService?.getThemeProperty("colors", "border") || "#6c7086"
            }
        }
    }
    
    // No media state
    Text {
        visible: !MediaService.hasActivePlayer
        anchors.centerIn: parent
        text: "No Media"
        font.family: "Inter"
        font.pixelSize: configService ? configService.typography("sm", entityId) : 11
        color: configService?.getThemeProperty("colors", "textAlt") || "#bac2de"
    }
    
    // Mouse interactions
    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
        hoverEnabled: true
        
        onClicked: mouse => {
            if (mouse.button === Qt.LeftButton) {
                // Left click - toggle play/pause
                MediaService.togglePlayPause()
            } else if (mouse.button === Qt.RightButton) {
                // Right click - open context menu
                menu()
            } else if (mouse.button === Qt.MiddleButton) {
                // Middle click - toggle compact/expanded mode
                configService?.setValue("entities." + entityId + ".compactMode", !compactMode)
            }
        }
        
        onWheel: wheel => {
            if (MediaService.volumeSupported) {
                const delta = wheel.angleDelta.y > 0 ? 0.05 : -0.05
                const newVolume = Math.max(0.0, Math.min(1.0, MediaService.volume + delta))
                MediaService.setVolume(newVolume)
            }
        }
        
        onEntered: parent.parent && (parent.parent.opacity = 0.8)
        onExited: parent.parent && (parent.parent.opacity = 1.0)
    }
    
    // GraphicalComponent interface methods
    function menu(startPath) {
        console.log("[MediaWidget] Opening context menu")
        if (anchorWindow) {
            const globalPos = mediaWidget.mapToItem(null, 0, 0)
            contextMenu.show(anchorWindow, globalPos.x, globalPos.y + mediaWidget.height)
        }
    }
    
    function getParent() {
        return null
    }
    
    function getChildren() {
        return []
    }
    
    function navigateToParent() {
        if (getParent()) {
            getParent().menu()
        }
    }
    
    function navigateToChild(childId) {
        console.log("MediaWidget has no child components")
    }
    
}