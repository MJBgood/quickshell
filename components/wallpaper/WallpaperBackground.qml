import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Wayland
import "../shared"

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
    property var configService: ConfigService
    property var scalingService: ScalingService
    property var componentRegistry: ComponentRegistry
    
    // GraphicalComponent interface
    property string componentId: "wallpaper-background"
    property string parentComponentId: "desktop"
    property var childComponentIds: []
    property string menuPath: "desktop.wallpaper-background"
    
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
                    width: scalingService.scaleValue(60)
                    height: scalingService.scaleValue(60)
                    radius: scalingService.scaleValue(30)
                    color: configService ? configService.getThemeProperty("colors", "surface") || "#313244" : "#313244"
                    anchors.centerIn: parent
                    opacity: 0.8
                    
                    Text {
                        anchors.centerIn: parent
                        text: "⏳"
                        font.pixelSize: scalingService.scaleValue(24)
                        color: configService ? configService.getThemeProperty("colors", "text") || "#cdd6f4" : "#cdd6f4"
                        
                        RotationAnimation on rotation {
                            running: wallpaperImage.status === Image.Loading
                            from: 0
                            to: 360
                            duration: scalingService.scaleAnimationDuration(2000)
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
                    spacing: scalingService.scaleValue(16)
                    
                    Text {
                        text: "🖼️"
                        font.pixelSize: scalingService.scaleValue(64)
                        color: configService ? configService.getThemeProperty("colors", "textAlt") || "#bac2de" : "#bac2de"
                        anchors.horizontalCenter: parent.horizontalCenter
                    }
                    
                    Text {
                        text: "Unable to load wallpaper"
                        font.pixelSize: scalingService.scaleValue(16)
                        color: configService ? configService.getThemeProperty("colors", "text") || "#cdd6f4" : "#cdd6f4"
                        anchors.horizontalCenter: parent.horizontalCenter
                    }
                    
                    Text {
                        text: getCurrentWallpaperPath()
                        font.pixelSize: scalingService.scaleValue(10)
                        color: configService ? configService.getThemeProperty("colors", "textAlt") || "#bac2de" : "#bac2de"
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: scalingService.scaleValue(400)
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
                GradientStop { position: 0.0; color: configService ? configService.getThemeProperty("colors", "background") || "#1e1e2e" : "#1e1e2e" }
                GradientStop { position: 0.3; color: configService ? configService.getThemeProperty("colors", "surface") || "#313244" : "#313244" }
                GradientStop { position: 0.7; color: configService ? configService.getThemeProperty("colors", "surface") || "#313244" : "#313244" }
                GradientStop { position: 1.0; color: configService ? configService.getThemeProperty("colors", "background") || "#1e1e2e" : "#1e1e2e" }
            }
            
            // Instructional content
            Column {
                anchors.centerIn: parent
                spacing: scalingService.scaleValue(24)
                width: Math.min(scalingService.scaleValue(600), parent.width - scalingService.scaleValue(100))
                
                // Icon
                Text {
                    text: "🖼️"
                    font.pixelSize: scalingService.scaleValue(72)
                    color: configService ? configService.getThemeProperty("colors", "accent") || "#a6e3a1" : "#a6e3a1"
                    anchors.horizontalCenter: parent.horizontalCenter
                }
                
                // Title
                Text {
                    text: "Welcome to Quickshell"
                    font.pixelSize: scalingService.scaleValue(28)
                    font.weight: Font.Bold
                    color: configService ? configService.getThemeProperty("colors", "text") || "#cdd6f4" : "#cdd6f4"
                    anchors.horizontalCenter: parent.horizontalCenter
                }
                
                // Subtitle
                Text {
                    text: "Add wallpapers to personalize your desktop"
                    font.pixelSize: scalingService.scaleValue(16)
                    color: configService ? configService.getThemeProperty("colors", "textAlt") || "#bac2de" : "#bac2de"
                    anchors.horizontalCenter: parent.horizontalCenter
                }
                
                // Instructions
                Column {
                    width: parent.width
                    spacing: scalingService.scaleValue(12)
                    anchors.horizontalCenter: parent.horizontalCenter
                    
                    Repeater {
                        model: getInstructionalSteps()
                        
                        Row {
                            anchors.horizontalCenter: parent.horizontalCenter
                            spacing: scalingService.scaleValue(12)
                            
                            Rectangle {
                                width: scalingService.scaleValue(24)
                                height: scalingService.scaleValue(24)
                                radius: scalingService.scaleValue(12)
                                color: configService ? configService.getThemeProperty("colors", "accent") || "#a6e3a1" : "#a6e3a1"
                                anchors.verticalCenter: parent.verticalCenter
                                
                                Text {
                                    anchors.centerIn: parent
                                    text: (index + 1).toString()
                                    font.pixelSize: scalingService.scaleValue(10)
                                    font.weight: Font.Bold
                                    color: configService ? configService.getThemeProperty("colors", "background") || "#1e1e2e" : "#1e1e2e"
                                }
                            }
                            
                            Text {
                                text: modelData
                                font.pixelSize: scalingService.scaleValue(14)
                                color: configService ? configService.getThemeProperty("colors", "text") || "#cdd6f4" : "#cdd6f4"
                                anchors.verticalCenter: parent.verticalCenter
                            }
                        }
                    }
                }
                
                // Quick action button
                Rectangle {
                    width: scalingService.scaleValue(200)
                    height: scalingService.scaleValue(40)
                    radius: scalingService.scaleValue(8)
                    color: quickActionMouse.containsMouse ? (configService ? configService.getThemeProperty("colors", "accent") || "#a6e3a1" : "#a6e3a1"):  "transparent"
                    border.color: configService ? configService.getThemeProperty("colors", "accent") || "#a6e3a1" : "#a6e3a1"
                    border.width: scalingService.scaleValue(2)
                    anchors.horizontalCenter: parent.horizontalCenter
                    
                    Text {
                        anchors.centerIn: parent
                        text: "📁 Open Wallpaper Folder"
                        font.pixelSize: scalingService.scaleValue(12)
                        font.weight: Font.Medium
                        color: quickActionMouse.containsMouse ? (configService ? configService.getThemeProperty("colors", "background") || "#1e1e2e" : "#1e1e2e"):  (configService ? configService.getThemeProperty("colors", "accent") || "#a6e3a1" : "#a6e3a1")
                    }
                    
                    MouseArea {
                        id: quickActionMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: openWallpaperFolder()
                    }
                    
                    Behavior on color {
                        ColorAnimation { duration: scalingService.scaleAnimationDuration(200) }
                    }
                }
                
                // Additional info
                Text {
                    text: `Wallpaper directory: ${getWallpaperDirectory()}`
                    font.pixelSize: scalingService.scaleValue(10)
                    color: configService ? configService.getThemeProperty("colors", "textAlt") || "#bac2de" : "#bac2de"
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
                width: scalingService.scaleValue(180)
                height: scalingService.scaleValue(40)
                radius: scalingService.scaleValue(8)
                color: configService ? configService.getThemeProperty("colors", "surface") || "#313244" : "#313244"
                border.color: "#f9e2af"
                border.width: scalingService.scaleValue(2)
                anchors.top: parent.top
                anchors.right: parent.right
                anchors.margins: scalingService.scaleValue(20)
                opacity: 0.9
                
                Row {
                    anchors.centerIn: parent
                    spacing: scalingService.scaleValue(8)
                    
                    Text {
                        text: "👁️"
                        font.pixelSize: scalingService.scaleValue(16)
                        anchors.verticalCenter: parent.verticalCenter
                    }
                    
                    Text {
                        text: "Preview Mode"
                        font.pixelSize: scalingService.scaleValue(12)
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
        return configService ? configService.getThemeProperty("colors", "background") || "#1e1e2e" : "#1e1e2e"
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
    
    // GraphicalComponent interface methods
    function menu(startPath) {
        console.log(`[WallpaperBackground] Menu requested for path: ${startPath || menuPath}`)
        // Wallpaper backgrounds don't typically have context menus
        // but we implement the interface for consistency
    }
    
    function getParent() {
        return componentRegistry.getComponent(parentComponentId)
    }
    
    function getChildren() {
        return childComponentIds.map(id => componentRegistry.getComponent(id)).filter(c => c)
    }
    
    function navigateToParent() {
        const parent = getParent()
        if (parent && parent.menu) {
            parent.menu()
        }
    }
    
    function navigateToChild(childId) {
        const child = componentRegistry.getComponent(childId)
        if (child && child.menu) {
            child.menu()
        }
    }
    
    Component.onCompleted: {
        console.log("WallpaperBackground initialized for screen:", screen ? screen.name : "unknown")
        
        // Register with ComponentRegistry
        componentRegistry.registerComponent(componentId, wallpaperBackground)
        
        // Log initial state
        if (wallpaperService) {
            console.log("Background: Initial wallpaper count:", wallpaperService.wallpapers ? wallpaperService.wallpapers.length : 0)
            console.log("Background: Current wallpaper:", wallpaperService.currentWallpaper || "none")
        }
    }
    
    Component.onDestruction: {
        // Unregister from ComponentRegistry
        componentRegistry.unregisterComponent(componentId)
    }
}