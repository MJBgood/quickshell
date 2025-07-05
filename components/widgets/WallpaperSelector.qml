import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Hyprland
import "../base"

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
    }
    
    // Services
    property var wallpaperService: null
    property var themeService: null
    
    // State
    property var filteredWallpapers: []
    property string searchQuery: ""
    
    // Signals
    signal closed()
    signal wallpaperSelected(string wallpaperPath)
    
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
    
    // Main selector container - exactly like ThemeDropdown
    Rectangle {
        id: selectorContainer
        anchors.centerIn: parent
        width: 600
        height: 500
        color: themeService ? themeService.getThemeProperty("colors", "background") || "#1e1e2e" : "#1e1e2e"
        border.color: themeService ? themeService.getThemeProperty("colors", "border") || "#585b70" : "#585b70"
        border.width: 2
        radius: 12
        
        // Scale animation for appearance (same as ThemeDropdown)
        scale: parent.visible ? 1.0 : 0.8
        opacity: parent.visible ? 1.0 : 0.0
        
        Behavior on scale {
            NumberAnimation { duration: 200; easing.type: Easing.OutBack }
        }
        
        Behavior on opacity {
            NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
        }
        
        Column {
            anchors.fill: parent
            anchors.margins: 20
            spacing: 16
            
            // Header section
            Item {
                id: headerSection
                width: parent.width
                height: 40
                
                Row {
                    width: parent.width
                    height: parent.height
                    spacing: 12
                    
                    // Title and wallpaper count
                    Column {
                        anchors.verticalCenter: parent.verticalCenter
                        width: parent.width - closeButton.width - 12
                        
                        Text {
                            text: "Wallpaper Selection"
                            font.pixelSize: 16
                            font.weight: Font.DemiBold
                            color: themeService ? themeService.getThemeProperty("colors", "text") || "#cdd6f4" : "#cdd6f4"
                        }
                        
                        Text {
                            text: getWallpaperStats()
                            font.pixelSize: 11
                            color: themeService ? themeService.getThemeProperty("colors", "textAlt") || "#bac2de" : "#bac2de"
                        }
                    }
                    
                    // Close button
                    Rectangle {
                        id: closeButton
                        width: 32
                        height: 32
                        radius: 16
                        color: closeArea.containsMouse ? "#f38ba8" : "transparent"
                        border.color: themeService ? themeService.getThemeProperty("colors", "border") || "#585b70" : "#585b70"
                        border.width: 1
                        
                        Text {
                            anchors.centerIn: parent
                            text: "✕"
                            color: closeArea.containsMouse ? "#1e1e2e" : (themeService ? themeService.getThemeProperty("colors", "textAlt") || "#bac2de" : "#bac2de")
                            font.pixelSize: 14
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
                height: 36
                color: themeService ? themeService.getThemeProperty("colors", "surfaceAlt") || "#45475a" : "#45475a"
                border.color: searchInput.activeFocus ? "#a6e3a1" : (themeService ? themeService.getThemeProperty("colors", "border") || "#585b70" : "#585b70")
                border.width: 1
                radius: 6
                
                Row {
                    anchors.fill: parent
                    anchors.margins: 8
                    spacing: 8
                    
                    Text {
                        text: "🔍"
                        font.pixelSize: 14
                        anchors.verticalCenter: parent.verticalCenter
                        color: themeService ? themeService.getThemeProperty("colors", "textAlt") || "#bac2de" : "#bac2de"
                    }
                    
                    TextInput {
                        id: searchInput
                        width: parent.width - 24
                        height: parent.height
                        anchors.verticalCenter: parent.verticalCenter
                        font.pixelSize: 12
                        color: themeService ? themeService.getThemeProperty("colors", "text") || "#cdd6f4" : "#cdd6f4"
                        selectByMouse: true
                        
                        // Placeholder text using separate Text element
                        Text {
                            visible: searchInput.text.length === 0 && !searchInput.activeFocus
                            anchors.fill: parent
                            anchors.verticalCenter: parent.verticalCenter
                            text: "Search wallpapers..."
                            font: searchInput.font
                            color: themeService ? themeService.getThemeProperty("colors", "textAlt") || "#bac2de" : "#bac2de"
                            verticalAlignment: Text.AlignVCenter
                        }
                        
                        onTextChanged: {
                            searchQuery = text
                            updateFilteredWallpapers()
                        }
                        
                        Keys.onEscapePressed: hide()
                    }
                }
                
                Behavior on border.color {
                    ColorAnimation { duration: 150 }
                }
            }
            
            // Wallpaper grid
            ScrollView {
                width: parent.width
                height: parent.height - headerSection.height - searchBox.height - 32
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
                    width: 8
                    
                    background: Rectangle {
                        color: "transparent"
                        radius: 4
                    }
                    
                    contentItem: Rectangle {
                        color: themeService ? themeService.getThemeProperty("colors", "border") || "#585b70" : "#585b70"
                        radius: 4
                        opacity: 0.6
                    }
                }
                
                GridView {
                    id: wallpaperGrid
                    width: parent.width
                    cellWidth: 140
                    cellHeight: 100
                    model: filteredWallpapers
                    
                    delegate: Rectangle {
                        width: wallpaperGrid.cellWidth - 8
                        height: wallpaperGrid.cellHeight - 8
                        color: wallpaperMouse.containsMouse ? (themeService ? themeService.getThemeProperty("colors", "surfaceAlt") || "#45475a" : "#45475a") : "transparent"
                        border.color: isCurrentWallpaper(modelData.path) ? "#a6e3a1" : (themeService ? themeService.getThemeProperty("colors", "border") || "#585b70" : "#585b70")
                        border.width: isCurrentWallpaper(modelData.path) ? 2 : 1
                        radius: 8
                        
                        Column {
                            anchors.fill: parent
                            anchors.margins: 8
                            spacing: 4
                            
                            // Wallpaper preview placeholder
                            Rectangle {
                                width: parent.width
                                height: parent.height - nameText.height - 4
                                color: themeService ? themeService.getThemeProperty("colors", "background") || "#1e1e2e" : "#1e1e2e"
                                radius: 4
                                
                                // Simple gradient as preview placeholder
                                Rectangle {
                                    anchors.fill: parent
                                    radius: 4
                                    gradient: Gradient {
                                        GradientStop { position: 0.0; color: "#6c7086" }
                                        GradientStop { position: 0.5; color: "#9399b2" }
                                        GradientStop { position: 1.0; color: "#bac2de" }
                                    }
                                    opacity: 0.3
                                }
                                
                                Text {
                                    anchors.centerIn: parent
                                    text: "🖼️"
                                    font.pixelSize: 24
                                    color: themeService ? themeService.getThemeProperty("colors", "textAlt") || "#bac2de" : "#bac2de"
                                }
                                
                                // Current wallpaper indicator
                                Rectangle {
                                    visible: isCurrentWallpaper(modelData.path)
                                    width: 20
                                    height: 20
                                    radius: 10
                                    color: "#a6e3a1"
                                    anchors.top: parent.top
                                    anchors.right: parent.right
                                    anchors.margins: 4
                                    
                                    Text {
                                        anchors.centerIn: parent
                                        text: "✓"
                                        font.pixelSize: 10
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
                                font.pixelSize: 10
                                color: themeService ? themeService.getThemeProperty("colors", "text") || "#cdd6f4" : "#cdd6f4"
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
                height: 120
                color: "transparent"
                border.color: themeService ? themeService.getThemeProperty("colors", "border") || "#585b70" : "#585b70"
                border.width: 1
                radius: 8
                
                Column {
                    anchors.centerIn: parent
                    spacing: 8
                    
                    Text {
                        text: searchQuery.length > 0 ? "No wallpapers match your search" : "No wallpapers found"
                        font.pixelSize: 14
                        color: themeService ? themeService.getThemeProperty("colors", "textAlt") || "#bac2de" : "#bac2de"
                        anchors.horizontalCenter: parent.horizontalCenter
                    }
                    
                    Rectangle {
                        visible: searchQuery.length === 0
                        width: 140
                        height: 32
                        color: openFolderMouse.containsMouse ? "#a6e3a1" : (themeService ? themeService.getThemeProperty("colors", "surfaceAlt") || "#45475a" : "#45475a")
                        border.color: themeService ? themeService.getThemeProperty("colors", "border") || "#585b70" : "#585b70"
                        border.width: 1
                        radius: 6
                        anchors.horizontalCenter: parent.horizontalCenter
                        
                        Text {
                            anchors.centerIn: parent
                            text: "📁 Open Wallpaper Folder"
                            font.pixelSize: 10
                            color: openFolderMouse.containsMouse ? "#1e1e2e" : (themeService ? themeService.getThemeProperty("colors", "text") || "#cdd6f4" : "#cdd6f4")
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
    function show(anchorWindow, posX, posY) {
        console.log("WallpaperSelector: show() called")
        
        // Load wallpapers and show (same as ThemeDropdown)
        updateFilteredWallpapers()
        console.log("WallpaperSelector: setting visible = true")
        visible = true
        
        // Focus search input after a brief delay
        Qt.callLater(() => {
            searchInput.forceActiveFocus()
        })
    }
    
    function hide() {
        console.log("WallpaperSelector: hide() called")
        visible = false
        focusGrab.active = false
        searchInput.text = ""
        searchQuery = ""
        closed()
    }
    
    function updateFilteredWallpapers() {
        if (!wallpaperService) {
            filteredWallpapers = []
            return
        }
        
        if (searchQuery.length === 0) {
            filteredWallpapers = wallpaperService.wallpapers || []
        } else {
            filteredWallpapers = wallpaperService.searchWallpapers(searchQuery) || []
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