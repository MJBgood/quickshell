import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Hyprland
import "../base"
import "../../services"

PanelWindow {
    id: wallpaperSelector
    
    // Window properties - cover entire screen like ThemeDropdown
    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }
    
    visible: false
    color: "transparent"
    
    onVisibleChanged: {
        console.log("WallpaperSelector: visible changed to:", visible)
        if (visible) {
            updateFilteredWallpapers()
            // Focus search after a brief delay
            Qt.callLater(() => {
                if (searchInput) {
                    searchInput.forceActiveFocus()
                }
            })
        }
    }
    
    // Services
    property var wallpaperService: null
    property var configService: ConfigService
    
    // State
    property var filteredWallpapers: []
    property string searchQuery: ""
    property int currentIndex: -1
    
    // Signals
    signal closed()
    signal wallpaperSelected(string wallpaperPath)
    
    // Keyboard navigation will be handled by the main container Item
    
    // Focus grab for click-outside-to-close (same as ThemeDropdown)
    HyprlandFocusGrab {
        id: focusGrab
        windows: [wallpaperSelector]
        active: visible
        onCleared: hide()
    }
    
    // Background overlay with click-to-dismiss (same as ThemeDropdown)
    Rectangle {
        anchors.fill: parent
        color: "#80000000"  // Semi-transparent black
        opacity: parent.visible ? 0.8 : 0
        
        Behavior on opacity {
            NumberAnimation { duration: 300; easing.type: Easing.OutCubic }
        }
        
        MouseArea {
            anchors.fill: parent
            onClicked: hide()
        }
    }
    
    // Main selector container - larger and more elegant
    Rectangle {
        id: selectorContainer
        anchors.centerIn: parent
        width: Math.min(parent.width * 0.9, configService ? configService.scaled(1000) : 1000)
        height: Math.min(parent.height * 0.9, configService ? configService.scaled(700) : 700)
        color: configService ? configService.getThemeProperty("colors", "background") || "#1e1e2e" : "#1e1e2e"
        border.color: configService ? configService.getThemeProperty("colors", "border") || "#585b70" : "#585b70"
        border.width: configService ? configService.scaled(1) : 1
        radius: configService ? configService.scaled(12) : 12
        
        // Enable focus and keyboard handling
        focus: visible
        
        // Keyboard navigation
        Keys.onPressed: (event) => {
            if (event.key === Qt.Key_Escape) {
                hide()
                event.accepted = true
            } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                if (currentIndex >= 0 && currentIndex < filteredWallpapers.length) {
                    selectWallpaper(filteredWallpapers[currentIndex].path)
                    hide()
                }
                event.accepted = true
            } else if (event.key === Qt.Key_Left) {
                if (currentIndex > 0) {
                    currentIndex--
                    wallpaperGrid.currentIndex = currentIndex
                }
                event.accepted = true
            } else if (event.key === Qt.Key_Right) {
                if (currentIndex < filteredWallpapers.length - 1) {
                    currentIndex++
                    wallpaperGrid.currentIndex = currentIndex
                }
                event.accepted = true
            }
        }
        
        // Scale animation for appearance (same as ThemeDropdown)
        scale: parent.visible ? 1.0 : 0.8
        opacity: parent.visible ? 1.0 : 0.0
        
        Behavior on scale {
            NumberAnimation { duration: 300; easing.type: Easing.OutBack }
        }
        
        Behavior on opacity {
            NumberAnimation { duration: 300; easing.type: Easing.OutCubic }
        }
        
        Column {
            anchors.fill: parent
            anchors.margins: 16
            spacing: 24
            
            // Header section
            Item {
                id: headerSection
                width: parent.width
                height: 40  // Fixed height for header
                
                Row {
                    width: parent.width
                    height: parent.height
                    spacing: configService ? configService.scaledMarginLarge() : 12
                    
                    // Title and wallpaper count
                    Column {
                        anchors.verticalCenter: parent.verticalCenter
                        width: parent.width - closeButton.width - (configService ? configService.scaledMarginLarge() : 12)
                        
                        Text {
                            text: "Wallpaper Selection"
                            font.pixelSize: configService ? configService.fontSizeXl() : 16
                            font.weight: Font.DemiBold
                            color: configService ? configService.getThemeProperty("colors", "text") || "#cdd6f4" : "#cdd6f4"
                        }
                        
                        Text {
                            text: getWallpaperStats()
                            font.pixelSize: configService ? configService.scaledFontSmall() : 9
                            color: configService ? configService.getThemeProperty("colors", "textAlt") || "#bac2de" : "#bac2de"
                        }
                    }
                    
                    // Close button
                    Rectangle {
                        id: closeButton
                        width: configService ? configService.scaled(32) : 32
                        height: configService ? configService.scaled(32) : 32
                        radius: configService ? configService.scaled(16) : 16
                        color: closeArea.containsMouse ? "#f38ba8" : "transparent"
                        border.color: configService ? configService.getThemeProperty("colors", "border") || "#585b70" : "#585b70"
                        border.width: configService ? configService.scaled(1) : 1
                        
                        Text {
                            anchors.centerIn: parent
                            text: "✕"
                            color: closeArea.containsMouse ? "#1e1e2e" : (configService ? configService.getThemeProperty("colors", "textAlt") || "#bac2de" : "#bac2de")
                            font.pixelSize: configService ? configService.scaledFontSmall() : 9
                            font.weight: Font.Bold
                        }
                        
                        MouseArea {
                            id: closeArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: hide()
                        }
                        
                        Behavior on color {
                            ColorAnimation { duration: 150 }
                        }
                    }
                }
            }
            
            // Search box
            Rectangle {
                id: searchBox
                width: parent.width
                height: 36  // Fixed height for search box
                color: configService ? configService.getThemeProperty("colors", "surfaceAlt") || "#45475a" : "#45475a"
                border.color: searchInput.activeFocus ? "#a6e3a1" : (configService ? configService.getThemeProperty("colors", "border") || "#585b70" : "#585b70")
                border.width: configService ? configService.scaled(1) : 1
                radius: configService ? configService.scaled(6) : 6
                
                Row {
                    anchors.fill: parent
                    anchors.margins: 8  // Fixed margins
                    spacing: 8  // Fixed spacing
                    
                    Text {
                        text: "🔍"
                        font.pixelSize: 14
                        anchors.verticalCenter: parent.verticalCenter
                        color: configService ? configService.getThemeProperty("colors", "textAlt") || "#bac2de" : "#bac2de"
                    }
                    
                    TextInput {
                        id: searchInput
                        width: parent.width - 24
                        height: parent.height
                        anchors.verticalCenter: parent.verticalCenter
                        font.pixelSize: 14
                        color: configService ? configService.getThemeProperty("colors", "text") || "#cdd6f4" : "#cdd6f4"
                        selectByMouse: true
                        
                        // Placeholder text using separate Text element
                        Text {
                            visible: searchInput.text.length === 0 && !searchInput.activeFocus
                            anchors.fill: parent
                            anchors.verticalCenter: parent.verticalCenter
                            text: "Search wallpapers..."
                            font: searchInput.font
                            color: configService ? configService.getThemeProperty("colors", "textAlt") || "#bac2de" : "#bac2de"
                            verticalAlignment: Text.AlignVCenter
                        }
                        
                        onTextChanged: {
                            searchQuery = text
                            updateFilteredWallpapers()
                        }
                    }
                }
                
                Behavior on border.color {
                    ColorAnimation { duration: 150 }
                }
            }
            
            // Wallpaper grid
            ScrollView {
                width: parent.width
                height: parent.height - headerSection.height - searchBox.height - 48  // Fixed bottom spacing
                clip: true
                
                Component.onCompleted: {
                    ScrollBar.horizontal.policy = ScrollBar.AlwaysOff
                    ScrollBar.vertical.policy = ScrollBar.AsNeeded
                }
                
                // Custom scrollbar styling
                ScrollBar.vertical: ScrollBar {
                    active: true
                    policy: ScrollBar.AsNeeded
                    size: 0.3
                    width: configService ? configService.scaled(8) : 8
                    
                    background: Rectangle {
                        color: "transparent"
                        radius: configService ? configService.scaled(4) : 4
                    }
                    
                    contentItem: Rectangle {
                        color: configService ? configService.getThemeProperty("colors", "border") || "#585b70" : "#585b70"
                        radius: configService ? configService.scaled(4) : 4
                        opacity: 0.6
                    }
                }
                
                GridView {
                    id: wallpaperGrid
                    width: parent.width
                    cellWidth: 160  // Fixed size for wallpaper previews
                    cellHeight: 120  // Fixed size for wallpaper previews
                    model: filteredWallpapers
                    currentIndex: wallpaperSelector.currentIndex
                    
                    // Performance optimizations for large image sets
                    cacheBuffer: configService ? configService.scaled(200) : 200  // Only cache a few screens worth
                    
                    onCurrentIndexChanged: {
                        wallpaperSelector.currentIndex = currentIndex
                    }
                    
                    delegate: Rectangle {
                        width: wallpaperGrid.cellWidth - 4
                        height: wallpaperGrid.cellHeight - 4
                        color: wallpaperMouse.containsMouse || GridView.isCurrentItem ? 
                               (configService ? configService.getThemeProperty("colors", "surfaceAlt") || "#45475a" : "#45475a"):  
                               "transparent"
                        border.color: isCurrentWallpaper(modelData.path) ? "#a6e3a1" : 
                                     GridView.isCurrentItem ? "#89b4fa" :
                                     (configService ? configService.getThemeProperty("colors", "border") || "#585b70" : "#585b70")
                        border.width: isCurrentWallpaper(modelData.path) || GridView.isCurrentItem ? (configService ? configService.scaled(2) : 2) : (configService ? configService.scaled(1) : 1)
                        radius: configService ? configService.scaled(8) : 8
                        
                        // Scale effect for focus
                        scale: GridView.isCurrentItem ? 1.05 : 1.0
                        
                        Behavior on scale {
                            NumberAnimation { duration: 150; easing.type: Easing.OutCubic }
                        }
                        
                        Column {
                            anchors.fill: parent
                            anchors.margins: 4  // Fixed margins
                            spacing: 4  // Fixed spacing
                            
                            // Wallpaper preview
                            Rectangle {
                                width: parent.width
                                height: parent.height - nameText.height - 4  // Fixed spacing
                                color: configService ? configService.getThemeProperty("colors", "background") || "#1e1e2e" : "#1e1e2e"
                                radius: configService ? configService.scaled(4) : 4
                                clip: true
                                
                                // Lazy-loaded thumbnail image
                                Image {
                                    id: wallpaperImage
                                    anchors.fill: parent
                                    source: visible && parent.visible ? "file://" + modelData.path : ""
                                    fillMode: Image.PreserveAspectCrop
                                    smooth: true
                                    cache: true  // Enable cache for thumbnails
                                    asynchronous: true
                                    
                                    // Load as small thumbnail instead of full resolution
                                    sourceSize.width: 160  // Fixed thumbnail size
                                    sourceSize.height: 120  // Fixed thumbnail size
                                    
                                    onStatusChanged: {
                                        if (status === Image.Error) {
                                            console.warn("Failed to load wallpaper image:", modelData.path)
                                        }
                                    }
                                    
                                    // Show loading indicator
                                    Rectangle {
                                        anchors.fill: parent
                                        visible: wallpaperImage.status === Image.Loading
                                        color: configService ? configService.getThemeProperty("colors", "surface") || "#313244" : "#313244"
                                        
                                        Text {
                                            anchors.centerIn: parent
                                            text: "⏳"
                                            font.pixelSize: configService ? configService.scaledIconMedium() : 20
                                            color: configService ? configService.getThemeProperty("colors", "textAlt") || "#bac2de" : "#bac2de"
                                        }
                                    }
                                    
                                    // Fallback content when image fails to load or is null
                                    Rectangle {
                                        anchors.fill: parent
                                        visible: wallpaperImage.status === Image.Error || wallpaperImage.status === Image.Null
                                        gradient: Gradient {
                                            GradientStop { position: 0.0; color: "#6c7086" }
                                            GradientStop { position: 0.5; color: "#9399b2" }
                                            GradientStop { position: 1.0; color: "#bac2de" }
                                        }
                                        opacity: 0.3
                                        
                                        Column {
                                            anchors.centerIn: parent
                                            spacing: configService ? configService.scaledMarginSmall() : 4
                                            
                                            Text {
                                                anchors.horizontalCenter: parent.horizontalCenter
                                                text: "🖼️"
                                                font.pixelSize: configService ? configService.scaledIconMedium() : 20
                                                color: configService ? configService.getThemeProperty("colors", "textAlt") || "#bac2de" : "#bac2de"
                                            }
                                            
                                            Text {
                                                anchors.horizontalCenter: parent.horizontalCenter
                                                text: wallpaperImage.status === Image.Error ? "Failed" : "No preview"
                                                font.pixelSize: configService ? configService.scaledMarginSmall() : 10
                                                color: configService ? configService.getThemeProperty("colors", "textAlt") || "#bac2de" : "#bac2de"
                                            }
                                        }
                                    }
                                }
                                
                                // Current wallpaper indicator
                                Rectangle {
                                    visible: isCurrentWallpaper(modelData.path)
                                    width: configService ? configService.scaledIconSmall() : 16
                                    height: configService ? configService.scaledIconSmall() : 16
                                    radius: configService ? configService.scaledIconSmall() : 16 / 2
                                    color: "#a6e3a1"
                                    anchors.top: parent.top
                                    anchors.right: parent.right
                                    anchors.margins: configService ? configService.scaledMarginSmall() : 4
                                    
                                    Text {
                                        anchors.centerIn: parent
                                        text: "✓"
                                        font.pixelSize: configService ? configService.scaledMarginSmall() : 10
                                        font.weight: Font.Bold
                                        color: "#1e1e2e"
                                    }
                                }
                                
                                // Focus indicator
                                Rectangle {
                                    visible: GridView.isCurrentItem
                                    width: configService ? configService.scaled(16) : 16
                                    height: configService ? configService.scaled(16) : 16
                                    radius: configService ? configService.scaled(8) : 8
                                    color: "#89b4fa"
                                    anchors.top: parent.top
                                    anchors.left: parent.left
                                    anchors.margins: configService ? configService.scaledMarginSmall() : 4
                                    
                                    Text {
                                        anchors.centerIn: parent
                                        text: "→"
                                        font.pixelSize: configService ? configService.scaledMarginSmall() : 10
                                        font.weight: Font.Bold
                                        color: "#1e1e2e"
                                    }
                                }
                            }
                            
                            // Wallpaper name
                            Text {
                                id: nameText
                                width: parent.width
                                text: modelData.name || "Unknown"
                                font.pixelSize: configService ? configService.scaledMarginSmall() : 10
                                color: configService ? configService.getThemeProperty("colors", "text") || "#cdd6f4" : "#cdd6f4"
                                elide: Text.ElideMiddle
                                horizontalAlignment: Text.AlignHCenter
                            }
                        }
                        
                        MouseArea {
                            id: wallpaperMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            
                            onClicked: {
                                console.log("Selected wallpaper:", modelData.path)
                                wallpaperGrid.currentIndex = index
                                selectWallpaper(modelData.path)
                            }
                            
                            onDoubleClicked: {
                                selectWallpaper(modelData.path)
                                hide()
                            }
                        }
                        
                        Behavior on color {
                            ColorAnimation { duration: 150 }
                        }
                        
                        Behavior on border.color {
                            ColorAnimation { duration: 150 }
                        }
                    }
                }
            }
            
            // No wallpapers message
            Rectangle {
                visible: filteredWallpapers.length === 0
                width: parent.width
                height: configService ? configService.scaled(120) : 120
                color: "transparent"
                border.color: configService ? configService.getThemeProperty("colors", "border") || "#585b70" : "#585b70"
                border.width: configService ? configService.scaled(1) : 1
                radius: configService ? configService.scaled(8) : 8
                
                Column {
                    anchors.centerIn: parent
                    spacing: configService ? configService.scaledMarginSmall() : 4
                    
                    Text {
                        text: searchQuery.length > 0 ? "No wallpapers match your search" : "No wallpapers found"
                        font.pixelSize: configService ? configService.scaledFontSmall() : 9
                        color: configService ? configService.getThemeProperty("colors", "textAlt") || "#bac2de" : "#bac2de"
                        anchors.horizontalCenter: parent.horizontalCenter
                    }
                    
                    Rectangle {
                        visible: searchQuery.length === 0
                        width: configService ? configService.scaled(140) : 140
                        height: configService ? configService.scaled(32) : 32
                        color: openFolderMouse.containsMouse ? "#a6e3a1" : (configService ? configService.getThemeProperty("colors", "surfaceAlt") || "#45475a" : "#45475a")
                        border.color: configService ? configService.getThemeProperty("colors", "border") || "#585b70" : "#585b70"
                        border.width: configService ? configService.scaled(1) : 1
                        radius: configService ? configService.scaled(6) : 6
                        anchors.horizontalCenter: parent.horizontalCenter
                        
                        Text {
                            anchors.centerIn: parent
                            text: "📁 Open Wallpaper Folder"
                            font.pixelSize: configService ? configService.scaledMarginSmall() : 10
                            color: openFolderMouse.containsMouse ? "#1e1e2e" : (configService ? configService.getThemeProperty("colors", "text") || "#cdd6f4" : "#cdd6f4")
                        }
                        
                        MouseArea {
                            id: openFolderMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: openWallpaperFolder()
                        }
                        
                        Behavior on color {
                            ColorAnimation { duration: 150 }
                        }
                    }
                }
            }
        }
    }
    
    // Functions
    function show(anchorWindow) {
        console.log("WallpaperSelector: show() called with anchorWindow:", anchorWindow)
        
        // Load wallpapers and show (same as ThemeDropdown)
        updateFilteredWallpapers()
        console.log("WallpaperSelector: setting visible = true")
        visible = true
        
        // Focus container for keyboard navigation, then search input
        Qt.callLater(() => {
            if (selectorContainer) {
                selectorContainer.forceActiveFocus()
            }
            if (searchInput) {
                searchInput.forceActiveFocus()
            }
        })
    }
    
    function hide() {
        console.log("WallpaperSelector: hide() called")
        visible = false
        if (searchInput) {
            searchInput.text = ""
        }
        searchQuery = ""
        closed()
    }
    
    function updateFilteredWallpapers() {
        if (!wallpaperService) {
            filteredWallpapers = []
            currentIndex = -1
            return
        }
        
        if (searchQuery.length === 0) {
            filteredWallpapers = wallpaperService.wallpapers || []
        } else {
            filteredWallpapers = wallpaperService.searchWallpapers(searchQuery) || []
        }
        
        // Find current wallpaper in filtered list and set as selected
        if (wallpaperService.currentWallpaper) {
            const currentIndex = filteredWallpapers.findIndex(w => w.path === wallpaperService.currentWallpaper)
            if (currentIndex >= 0) {
                wallpaperSelector.currentIndex = currentIndex
                wallpaperGrid.currentIndex = currentIndex
            } else {
                wallpaperSelector.currentIndex = filteredWallpapers.length > 0 ? 0 : -1
                wallpaperGrid.currentIndex = wallpaperSelector.currentIndex
            }
        } else {
            wallpaperSelector.currentIndex = filteredWallpapers.length > 0 ? 0 : -1
            wallpaperGrid.currentIndex = wallpaperSelector.currentIndex
        }
    }
    
    function selectWallpaper(wallpaperPath) {
        if (wallpaperService) {
            wallpaperService.setWallpaper(wallpaperPath)
            wallpaperSelected(wallpaperPath)
        }
    }
    
    function isCurrentWallpaper(wallpaperPath) {
        return wallpaperService && wallpaperService.currentWallpaper === wallpaperPath
    }
    
    function getWallpaperStats() {
        if (!wallpaperService) return "Service not available"
        
        const total = wallpaperService.wallpapers.length
        const filtered = filteredWallpapers.length
        
        if (total === 0) {
            return "No wallpapers found"
        }
        
        if (searchQuery.length > 0 && filtered !== total) {
            return `${filtered} of ${total} wallpapers`
        }
        
        return `${total} wallpaper${total === 1 ? '' : 's'} available`
    }
    
    function openWallpaperFolder() {
        if (wallpaperService) {
            wallpaperService.openWallpaperDirectory()
        }
    }
    
    // Connect to wallpaper service signals
    Connections {
        target: wallpaperService
        function onWallpapersDiscovered() {
            updateFilteredWallpapers()
        }
        function onWallpaperChanged() {
            // Force grid refresh to update current wallpaper indicator
            wallpaperGrid.model = null
            wallpaperGrid.model = filteredWallpapers
        }
    }
    
    Component.onCompleted: {
        console.log("WallpaperSelector initialized")
    }
}