import Quickshell
import Quickshell.Hyprland
import QtQuick
import QtQuick.Controls
import "../shared"

PopupWindow {
    id: barMenu
    
    // Window properties
    implicitWidth: 320
    implicitHeight: 450  // Fixed height to ensure scrolling works
    visible: false
    color: "transparent"
    
    // Services
    property var configService: ConfigService
    property var wallpaperService: null
    property var widgetRegistry: null
    property var shellRoot: null
    
    // Component hierarchy properties
    property string componentId: "bar"
    property string parentComponentId: ""
    property var childComponentIds: ["cpu", "ram", "storage", "clock", "workspaces"]
    
    // Signals
    signal closed()
    
    // Anchor configuration
    anchor {
        window: null
        rect {
            x: 0
            y: 0
            width: 1
            height: 1
        }
        edges: Edges.Top | Edges.Left
        gravity: Edges.Bottom | Edges.Right
        adjustment: PopupAdjustment.All
        margins {
            left: 8
            right: 8
            top: 8
            bottom: 8
        }
    }
    
    // Focus grab for dismissing when clicking outside
    HyprlandFocusGrab {
        id: focusGrab
        windows: [barMenu]
        onCleared: hide()
    }
    
    // Main container
    Rectangle {
        id: menuContent
        anchors.fill: parent
        color: configService ? configService.getThemeProperty("colors", "surface") || "#313244" : "#313244"
        border.color: configService ? configService.getThemeProperty("colors", "border") || "#585b70" : "#585b70"
        border.width: 1
        radius: 12
        
        ScrollView {
            id: scrollView
            anchors.fill: parent
            anchors.margins: 16
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
                    color: configService ? configService.getThemeProperty("colors", "border") || "#585b70" : "#585b70"
                    radius: 4
                    opacity: 0.6
                }
            }
            
            Column {
                width: Math.max(parent.width - 16, 280)
                spacing: 12
                
                // Navigation Header (matching other context menus)
                Row {
                    width: parent.width
                    height: 32
                    spacing: 8
                    
                    // Parent navigation button (even though bar has no parent, keep for consistency)
                    Rectangle {
                        width: 28
                        height: 28
                        radius: 6
                        visible: false  // Bar has no parent, but keep structure consistent
                        color: "transparent"
                        border.width: 1
                        border.color: configService ? configService.getThemeProperty("colors", "accent") || "#a6e3a1" : "#a6e3a1"
                    }
                    
                    // Header content
                    Item {
                        width: parent.width - 32 // Account for close button
                        height: 32
                        
                        Text {
                            id: iconText
                            text: "🔧"
                            font.pixelSize: 20
                            anchors.left: parent.left
                            anchors.verticalCenter: parent.verticalCenter
                        }
                        
                        Column {
                            anchors.left: iconText.right
                            anchors.leftMargin: 12
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            
                            Text {
                                text: "Status Bar"
                                font.pixelSize: 14
                                font.weight: Font.DemiBold
                                color: configService ? configService.getThemeProperty("colors", "text") || "#cdd6f4" : "#cdd6f4"
                            }
                            
                            Text {
                                text: "Layout and Position Settings"
                                font.pixelSize: 10
                                color: configService ? configService.getThemeProperty("colors", "textAlt") || "#bac2de" : "#bac2de"
                            }
                        }
                    }
                    
                    // Close button
                    Rectangle {
                        id: closeButton
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
                        
                        Behavior on color {
                            ColorAnimation { duration: 150 }
                        }
                    }
                }
                
                // Separator
                Rectangle {
                    width: parent.width
                    height: 1
                    color: configService ? configService.getThemeProperty("colors", "border") || "#585b70" : "#585b70"
                }
                
                // Bar configuration
                Column {
                    width: parent.width
                    spacing: 8
                    
                    Text {
                        text: "Bar Configuration:"
                        font.pixelSize: 12
                        font.weight: Font.DemiBold
                        color: configService ? configService.getThemeProperty("colors", "text") || "#cdd6f4" : "#cdd6f4"
                    }
                    
                    // Bar position toggle
                    ConfigToggleItem {
                        width: parent.width
                        label: "Position"
                        value: getConfigValue("panel.position", "top") === "top" ? "Top" : "Bottom"
                        isActive: true
                        onClicked: togglePosition()
                    }
                }
                
                // Separator
                Rectangle {
                    width: parent.width
                    height: 1
                    color: configService ? configService.getThemeProperty("colors", "border") || "#585b70" : "#585b70"
                }
                
                // Widget management
                Column {
                    width: parent.width
                    spacing: 8
                    
                    Row {
                        width: parent.width
                        spacing: 8
                        
                        Text {
                            text: "Widgets:"
                            font.pixelSize: 12
                            font.weight: Font.DemiBold
                            color: configService ? configService.getThemeProperty("colors", "text") || "#cdd6f4" : "#cdd6f4"
                            anchors.verticalCenter: parent.verticalCenter
                        }
                        
                        Text {
                            text: getWidgetStats()
                            font.pixelSize: 10
                            color: configService ? configService.getThemeProperty("colors", "textAlt") || "#bac2de" : "#bac2de"
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }
                    
                    // Dynamic widget list grouped by category
                    Repeater {
                        model: getWidgetCategories()
                        
                        Column {
                            width: parent.width
                            spacing: 4
                            
                            // Category header
                            Text {
                                visible: modelData.widgets.length > 0
                                text: modelData.icon + " " + modelData.name
                                font.pixelSize: 10
                                font.weight: Font.Medium
                                color: configService ? configService.getThemeProperty("colors", "accent") || "#a6e3a1" : "#a6e3a1"
                            }
                            
                            // Widgets in this category
                            Repeater {
                                model: modelData.widgets
                                
                                ConfigToggleItem {
                                    width: parent.width
                                    label: modelData.icon + " " + modelData.name
                                    value: modelData.enabled ? "Enabled" : "Disabled"
                                    isActive: modelData.enabled
                                    onClicked: toggleWidget(modelData.id)
                                }
                            }
                        }
                    }
                }
                
                // Separator
                Rectangle {
                    width: parent.width
                    height: 1
                    color: configService ? configService.getThemeProperty("colors", "border") || "#585b70" : "#585b70"
                }
                
                // Wallpaper Configuration
                Column {
                    width: parent.width
                    spacing: 8
                    
                    Text {
                        text: "Wallpaper:"
                        font.pixelSize: 12
                        font.weight: Font.DemiBold
                        color: configService ? configService.getThemeProperty("colors", "text") || "#cdd6f4" : "#cdd6f4"
                    }
                    
                    // Current wallpaper info
                    ConfigToggleItem {
                        width: parent.width
                        label: "Current"
                        value: getWallpaperDisplayName()
                        isActive: getWallpaperService() ? getWallpaperService().wallpapers.length > 0 : false
                        onClicked: openWallpaperSelector()
                    }
                    
                    // Random wallpaper
                    ConfigToggleItem {
                        width: parent.width
                        label: "Random Wallpaper"
                        value: "Click to Apply"
                        isActive: false
                        onClicked: setRandomWallpaper()
                    }
                    
                    // Open wallpaper folder
                    ConfigToggleItem {
                        width: parent.width
                        label: "Open Wallpaper Folder"
                        value: "📁 Browse"
                        isActive: true
                        onClicked: openWallpaperFolder()
                    }
                }
                
                // Separator
                Rectangle {
                    width: parent.width
                    height: 1
                    color: configService ? configService.getThemeProperty("colors", "border") || "#585b70" : "#585b70"
                }
                
                // Scaling Options
                Column {
                    width: parent.width
                    spacing: 8
                    
                    Text {
                        text: "Display:"
                        font.pixelSize: 12
                        font.weight: Font.DemiBold
                        color: configService ? configService.getThemeProperty("colors", "text") || "#cdd6f4" : "#cdd6f4"
                    }
                    
                    // Scaling Options menu item
                    ConfigToggleItem {
                        width: parent.width
                        label: "Scaling Options"
                        value: "Configure UI Scaling"
                        isActive: true
                        onClicked: openScalingOptions()
                    }
                }
                
                // Separator
                Rectangle {
                    width: parent.width
                    height: 1
                    color: configService ? configService.getThemeProperty("colors", "border") || "#585b70" : "#585b70"
                }
                
                // Quick Actions
                Column {
                    width: parent.width
                    spacing: 8
                    
                    Text {
                        text: "Quick Actions:"
                        font.pixelSize: 12
                        font.weight: Font.DemiBold
                        color: configService ? configService.getThemeProperty("colors", "text") || "#cdd6f4" : "#cdd6f4"
                    }
                    
                    // Enable all widgets
                    ConfigToggleItem {
                        width: parent.width
                        label: "Enable All Widgets"
                        value: "Click to Enable"
                        isActive: false
                        onClicked: enableAllWidgets()
                    }
                    
                    // Disable all widgets
                    ConfigToggleItem {
                        width: parent.width
                        label: "Disable All Widgets"
                        value: "Click to Disable"
                        isActive: false
                        onClicked: disableAllWidgets()
                    }
                    
                    // Reset to defaults
                    ConfigToggleItem {
                        width: parent.width
                        label: "Reset Widget Settings"
                        value: "Click to Reset"
                        isActive: false
                        onClicked: resetWidgetSettings()
                    }
                }
            }
        }
    }
    
    // ConfigToggleItem Component (matching other context menus)
    component ConfigToggleItem: Rectangle {
        property string label: ""
        property string value: ""
        property bool isActive: false
        signal clicked()
        
        height: 24
        radius: 4
        color: toggleMouse.containsMouse ? 
               (configService ? configService.getThemeProperty("colors", "surfaceAlt") || "#45475a" : "#45475a") : 
               "transparent"
        
        Row {
            anchors.left: parent.left
            anchors.leftMargin: 8
            anchors.verticalCenter: parent.verticalCenter
            spacing: 8
            
            Text {
                text: label + ":"
                font.pixelSize: 10
                color: configService ? configService.getThemeProperty("colors", "text") || "#cdd6f4" : "#cdd6f4"
                anchors.verticalCenter: parent.verticalCenter
            }
            
            Text {
                text: value
                font.pixelSize: 10
                font.weight: Font.Medium
                color: isActive ? "#a6e3a1" : "#f38ba8"
                anchors.verticalCenter: parent.verticalCenter
            }
        }
        
        MouseArea {
            id: toggleMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: parent.clicked()
        }
        
        Behavior on color {
            ColorAnimation { duration: 150 }
        }
    }
    
    // Helper functions
    function getConfigValue(key, defaultValue) {
        if (!configService) return defaultValue
        return configService.getValue(key, defaultValue)
    }
    
    function toggleConfig(key) {
        if (!configService) return
        
        const currentValue = configService.getValue(key, true)
        const newValue = !currentValue
        
        configService.setValue(key, newValue)
        configService.saveConfig()
    }
    
    function togglePosition() {
        if (!configService) return
        
        const currentPosition = configService.getValue("panel.position", "top")
        const newPosition = currentPosition === "top" ? "bottom" : "top"
        
        configService.setValue("panel.position", newPosition)
        configService.saveConfig()
    }
    
    function getWidgetStats() {
        if (!widgetRegistry) return "No registry"
        
        const stats = widgetRegistry.getStats()
        return `${stats.enabledWidgets}/${stats.totalWidgets} enabled`
    }
    
    function getWidgetCategories() {
        if (!widgetRegistry) return []
        
        const categories = widgetRegistry.categories
        const widgets = widgetRegistry.getAllWidgetsOrdered()
        
        // Group widgets by category
        const categoryData = {}
        
        // Initialize categories
        Object.keys(categories).forEach(categoryId => {
            categoryData[categoryId] = {
                id: categoryId,
                name: categories[categoryId].name,
                icon: categories[categoryId].icon,
                order: categories[categoryId].order,
                widgets: []
            }
        })
        
        // Add widgets to their categories
        widgets.forEach(widget => {
            const categoryId = widget.category || "system"
            if (categoryData[categoryId]) {
                categoryData[categoryId].widgets.push(widget)
            }
        })
        
        // Return sorted categories with widgets
        return Object.values(categoryData)
                    .filter(cat => cat.widgets.length > 0)
                    .sort((a, b) => a.order - b.order)
    }
    
    function toggleWidget(widgetId) {
        if (!widgetRegistry) return
        
        console.log("Toggling widget:", widgetId)
        widgetRegistry.toggleWidget(widgetId)
    }
    
    function enableAllWidgets() {
        if (!widgetRegistry) return
        
        console.log("Enabling all widgets")
        const widgets = widgetRegistry.getAllWidgets()
        widgets.forEach(widget => {
            widgetRegistry.setWidgetEnabled(widget.id, true)
        })
    }
    
    function disableAllWidgets() {
        if (!widgetRegistry) return
        
        console.log("Disabling all widgets")
        const widgets = widgetRegistry.getAllWidgets()
        widgets.forEach(widget => {
            widgetRegistry.setWidgetEnabled(widget.id, false)
        })
    }
    
    function resetWidgetSettings() {
        if (!widgetRegistry) return
        
        console.log("Resetting widget settings to defaults")
        const widgets = widgetRegistry.getAllWidgets()
        widgets.forEach(widget => {
            widgetRegistry.setWidgetEnabled(widget.id, widget.defaultEnabled)
        })
    }
    
    // Wallpaper helper functions
    function getWallpaperService() {
        return wallpaperService
    }
    
    function getWallpaperDisplayName() {
        const service = getWallpaperService()
        if (!service) return "Service Not Available"
        
        if (service.wallpapers.length === 0) {
            return "No Wallpapers Found"
        }
        
        if (!service.currentWallpaper) {
            return "No Wallpaper Set"
        }
        
        const info = service.getWallpaperInfo(service.currentWallpaper)
        return info ? info.name : "Unknown"
    }
    
    function openWallpaperSelector() {
        console.log("Opening wallpaper selector...")
        console.log("shellRoot:", shellRoot)
        
        const service = getWallpaperService()
        if (service && service.wallpapers.length === 0) {
            // Show instructional message first, then open selector anyway
            console.log("No wallpapers found, but showing selector for folder access...")
        }
        
        // Call global function (same as theme dropdown)
        if (shellRoot) {
            console.log("Calling shellRoot.showWallpaperSelector()")
            shellRoot.showWallpaperSelector()
        } else {
            console.error("Cannot call showWallpaperSelector - shellRoot is null")
        }
    }
    
    function setRandomWallpaper() {
        const service = getWallpaperService()
        if (service) {
            service.setRandomWallpaper()
        }
    }
    
    function openWallpaperFolder() {
        const service = getWallpaperService()
        if (service) {
            service.openWallpaperDirectory()
        }
    }
    
    function openScalingOptions() {
        console.log("BarContextMenu: Opening scaling options...")
        
        // Hide this menu first
        hide()
        
        // Call global function (same as wallpaper selector and theme dropdown)
        if (shellRoot) {
            console.log("Calling shellRoot.showScalingMenu()")
            shellRoot.showScalingMenu()
        } else {
            console.error("Cannot call showScalingMenu - shellRoot is null")
        }
    }
    
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
    }
    
    function hide() {
        visible = false
        focusGrab.active = false
        closed()
    }
    
    // Navigation functions
    function navigateToParent() {
        if (!parentComponentId) return
        
        const parentComponent = ComponentRegistry.getComponent(parentComponentId)
        if (parentComponent && typeof parentComponent.menu === 'function') {
            console.log(`[BarContextMenu] Navigating to parent: ${parentComponentId}`)
            
            // Hide this menu first
            hide()
            
            // Show parent menu at the same position
            const currentAnchor = anchor
            parentComponent.menu(currentAnchor.window, currentAnchor.rect.x, currentAnchor.rect.y)
        } else {
            console.warn(`[BarContextMenu] Parent component ${parentComponentId} not found or doesn't support menu()`)
        }
    }
    
    function navigateToChild(childId) {
        if (!childComponentIds.includes(childId)) return
        
        const childComponent = ComponentRegistry.getComponent(childId)
        if (childComponent && typeof childComponent.menu === 'function') {
            console.log(`[BarContextMenu] Navigating to child: ${childId}`)
            
            // Hide this menu first
            hide()
            
            // Show child menu at the same position
            const currentAnchor = anchor
            childComponent.menu(currentAnchor.window, currentAnchor.rect.x, currentAnchor.rect.y)
        } else {
            console.warn(`[BarContextMenu] Child component ${childId} not found or doesn't support menu()`)
        }
    }
    
    // Wallpaper selector and scaling menu are now handled globally by shell.qml
}