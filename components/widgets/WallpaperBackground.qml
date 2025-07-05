import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Wayland

PanelWindow {
    id: wallpaperBackground
    
    // Window configuration - behind everything
    screen: modelData
    
    // Set to background layer using WlrLayershell
    Component.onCompleted: {
        if (this.WlrLayershell != null) {
            this.WlrLayershell.layer = WlrLayer.Background
        }
    }
    
    // Services
    property var wallpaperService: null
    property var themeService: null
    
    // Required property for screen assignment
    property var modelData
    
    // Full screen coverage
    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }
    
    color: "transparent"
    
    // Main background container
    Rectangle {
        anchors.fill: parent
        color: getFallbackColor()
        
        // Current wallpaper image
        Image {
            id: wallpaperImage
            anchors.fill: parent
            fillMode: Image.PreserveAspectCrop
            source: getCurrentWallpaperSource()
            
            // Smooth scaling for better quality
            smooth: true
            mipmap: true
            
            // Loading state
            Rectangle {
                visible: wallpaperImage.status === Image.Loading
                anchors.fill: parent
                color: getFallbackColor()
                
                // Loading indicator
                Rectangle {
                    width: 60
                    height: 60
                    radius: 30
                    color: themeService ? themeService.getThemeProperty("colors", "surface") || "#313244" : "#313244"
                    anchors.centerIn: parent
                    opacity: 0.8
                    
                    Text {
                        anchors.centerIn: parent
                        text: "⏳"
                        font.pixelSize: 24
                        color: themeService ? themeService.getThemeProperty("colors", "text") || "#cdd6f4" : "#cdd6f4"
                        
                        RotationAnimation on rotation {
                            running: wallpaperImage.status === Image.Loading
                            from: 0
                            to: 360
                            duration: 2000
                            loops: Animation.Infinite
                        }
                    }
                }
            }
            
            // Error state
            Rectangle {
                visible: wallpaperImage.status === Image.Error
                anchors.fill: parent
                color: getFallbackColor()
                
                Column {
                    anchors.centerIn: parent
                    spacing: 16
                    
                    Text {
                        text: "🖼️"
                        font.pixelSize: 64
                        color: themeService ? themeService.getThemeProperty("colors", "textAlt") || "#bac2de" : "#bac2de"
                        anchors.horizontalCenter: parent.horizontalCenter
                    }
                    
                    Text {
                        text: "Unable to load wallpaper"
                        font.pixelSize: 16
                        color: themeService ? themeService.getThemeProperty("colors", "text") || "#cdd6f4" : "#cdd6f4"
                        anchors.horizontalCenter: parent.horizontalCenter
                    }
                    
                    Text {
                        text: getCurrentWallpaperPath()
                        font.pixelSize: 10
                        color: themeService ? themeService.getThemeProperty("colors", "textAlt") || "#bac2de" : "#bac2de"
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: 400
                        elide: Text.ElideMiddle
                        horizontalAlignment: Text.AlignHCenter
                    }
                }
            }
        }
        
        // Instructional background when no wallpapers are available
        Rectangle {
            visible: showInstructionalBackground()
            anchors.fill: parent
            
            // Subtle gradient background
            gradient: Gradient {
                GradientStop { position: 0.0; color: themeService ? themeService.getThemeProperty("colors", "background") || "#1e1e2e" : "#1e1e2e" }
                GradientStop { position: 0.3; color: themeService ? themeService.getThemeProperty("colors", "surface") || "#313244" : "#313244" }
                GradientStop { position: 0.7; color: themeService ? themeService.getThemeProperty("colors", "surface") || "#313244" : "#313244" }
                GradientStop { position: 1.0; color: themeService ? themeService.getThemeProperty("colors", "background") || "#1e1e2e" : "#1e1e2e" }
            }
            
            // Instructional content
            Column {
                anchors.centerIn: parent
                spacing: 24
                width: Math.min(600, parent.width - 100)
                
                // Icon
                Text {
                    text: "🖼️"
                    font.pixelSize: 72
                    color: themeService ? themeService.getThemeProperty("colors", "accent") || "#a6e3a1" : "#a6e3a1"
                    anchors.horizontalCenter: parent.horizontalCenter
                }
                
                // Title
                Text {
                    text: "Welcome to Quickshell"
                    font.pixelSize: 28
                    font.weight: Font.Bold
                    color: themeService ? themeService.getThemeProperty("colors", "text") || "#cdd6f4" : "#cdd6f4"
                    anchors.horizontalCenter: parent.horizontalCenter
                }
                
                // Subtitle
                Text {
                    text: "Add wallpapers to personalize your desktop"
                    font.pixelSize: 16
                    color: themeService ? themeService.getThemeProperty("colors", "textAlt") || "#bac2de" : "#bac2de"
                    anchors.horizontalCenter: parent.horizontalCenter
                }
                
                // Instructions
                Column {
                    width: parent.width
                    spacing: 12
                    anchors.horizontalCenter: parent.horizontalCenter
                    
                    Repeater {
                        model: getInstructionalSteps()
                        
                        Row {
                            anchors.horizontalCenter: parent.horizontalCenter
                            spacing: 12
                            
                            Rectangle {
                                width: 24
                                height: 24
                                radius: 12
                                color: themeService ? themeService.getThemeProperty("colors", "accent") || "#a6e3a1" : "#a6e3a1"
                                anchors.verticalCenter: parent.verticalCenter
                                
                                Text {
                                    anchors.centerIn: parent
                                    text: (index + 1).toString()
                                    font.pixelSize: 10
                                    font.weight: Font.Bold
                                    color: themeService ? themeService.getThemeProperty("colors", "background") || "#1e1e2e" : "#1e1e2e"
                                }
                            }
                            
                            Text {
                                text: modelData
                                font.pixelSize: 14
                                color: themeService ? themeService.getThemeProperty("colors", "text") || "#cdd6f4" : "#cdd6f4"
                                anchors.verticalCenter: parent.verticalCenter
                            }
                        }
                    }
                }
                
                // Quick action button
                Rectangle {
                    width: 200
                    height: 40
                    radius: 8
                    color: quickActionMouse.containsMouse ? (themeService ? themeService.getThemeProperty("colors", "accent") || "#a6e3a1" : "#a6e3a1") : "transparent"
                    border.color: themeService ? themeService.getThemeProperty("colors", "accent") || "#a6e3a1" : "#a6e3a1"
                    border.width: 2
                    anchors.horizontalCenter: parent.horizontalCenter
                    
                    Text {
                        anchors.centerIn: parent
                        text: "📁 Open Wallpaper Folder"
                        font.pixelSize: 12
                        font.weight: Font.Medium
                        color: quickActionMouse.containsMouse ? (themeService ? themeService.getThemeProperty("colors", "background") || "#1e1e2e" : "#1e1e2e") : (themeService ? themeService.getThemeProperty("colors", "accent") || "#a6e3a1" : "#a6e3a1")
                    }
                    
                    MouseArea {
                        id: quickActionMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: openWallpaperFolder()
                    }
                    
                    Behavior on color {
                        ColorAnimation { duration: 200 }
                    }
                }
                
                // Additional info
                Text {
                    text: `Wallpaper directory: ${getWallpaperDirectory()}`
                    font.pixelSize: 10
                    color: themeService ? themeService.getThemeProperty("colors", "textAlt") || "#bac2de" : "#bac2de"
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: parent.width
                    elide: Text.ElideMiddle
                    horizontalAlignment: Text.AlignHCenter
                }
            }
        }
        
        // Preview mode overlay
        Rectangle {
            visible: isPreviewMode()
            anchors.fill: parent
            color: "transparent"
            
            // Preview indicator
            Rectangle {
                width: 180
                height: 40
                radius: 8
                color: themeService ? themeService.getThemeProperty("colors", "surface") || "#313244" : "#313244"
                border.color: "#f9e2af"
                border.width: 2
                anchors.top: parent.top
                anchors.right: parent.right
                anchors.margins: 20
                opacity: 0.9
                
                Row {
                    anchors.centerIn: parent
                    spacing: 8
                    
                    Text {
                        text: "👁️"
                        font.pixelSize: 16
                        anchors.verticalCenter: parent.verticalCenter
                    }
                    
                    Text {
                        text: "Preview Mode"
                        font.pixelSize: 12
                        font.weight: Font.Medium
                        color: "#f9e2af"
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }
            }
        }
    }
    
    // Functions
    function getCurrentWallpaperSource() {
        if (!wallpaperService) return ""
        
        const displayWallpaper = wallpaperService.getCurrentDisplayWallpaper()
        if (!displayWallpaper) return ""
        
        return "file://" + displayWallpaper
    }
    
    function getCurrentWallpaperPath() {
        if (!wallpaperService) return ""
        return wallpaperService.getCurrentDisplayWallpaper() || ""
    }
    
    function showInstructionalBackground() {
        if (!wallpaperService) return true
        
        const hasWallpapers = wallpaperService.wallpapers && wallpaperService.wallpapers.length > 0
        const hasCurrentWallpaper = wallpaperService.currentWallpaper && wallpaperService.currentWallpaper.length > 0
        
        return !hasWallpapers || (!hasCurrentWallpaper && !wallpaperService.previewMode)
    }
    
    function isPreviewMode() {
        return wallpaperService && wallpaperService.previewMode
    }
    
    function getFallbackColor() {
        return themeService ? themeService.getThemeProperty("colors", "background") || "#1e1e2e" : "#1e1e2e"
    }
    
    function getWallpaperDirectory() {
        return wallpaperService ? wallpaperService.defaultWallpaperDir || "~/Pictures/Wallpapers" : "~/Pictures/Wallpapers"
    }
    
    function getInstructionalSteps() {
        return [
            `Place image files in ${getWallpaperDirectory()}`,
            "Supported formats: JPG, PNG, WebP, TIFF, BMP",
            "Right-click the status bar to access wallpaper settings",
            "Use the wallpaper selector to browse and preview"
        ]
    }
    
    function openWallpaperFolder() {
        if (wallpaperService) {
            wallpaperService.openWallpaperDirectory()
        }
    }
    
    // Connect to wallpaper service signals
    Connections {
        target: wallpaperService
        function onWallpaperChanged(path) {
            console.log("Background: Wallpaper changed to", path)
            // The binding will automatically update the image source
        }
        function onPreviewChanged(path) {
            console.log("Background: Preview changed to", path)
            // The binding will automatically update the image source
        }
        function onWallpapersDiscovered(wallpapers) {
            console.log("Background: Wallpapers discovered, count:", wallpapers.length)
            // This will trigger the instructional background check
        }
    }
    
    Component.onCompleted: {
        console.log("WallpaperBackground initialized for screen:", screen ? screen.name : "unknown")
        
        // Log initial state
        if (wallpaperService) {
            console.log("Background: Initial wallpaper count:", wallpaperService.wallpapers ? wallpaperService.wallpapers.length : 0)
            console.log("Background: Current wallpaper:", wallpaperService.currentWallpaper || "none")
        }
    }
}