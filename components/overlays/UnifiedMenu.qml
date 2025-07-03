import Quickshell
import Quickshell.Widgets
import Quickshell.Hyprland
import QtQuick

PopupWindow {
    id: menu
    
    visible: false
    color: "transparent"
    implicitWidth: 280
    implicitHeight: menuContent.implicitHeight + 16
    
    // Anchor configuration
    anchor {
        window: null
        rect {
            x: 0
            y: 0
            width: 1
            height: 1
        }
        edges: Edges.Bottom | Edges.Right
        gravity: Edges.Top | Edges.Left
        adjustment: PopupAdjustment.All
        margins {
            left: 5
            right: 5
            top: 5
            bottom: 5
        }
    }
    
    // Services
    property var configService: null
    property var themeService: null
    
    // Navigation state
    property string currentPath: "root"
    property var pathHistory: ["root"]
    property int historyIndex: 0
    
    // Signals
    signal closed()
    
    // Project-wide menu structure
    property var menuStructure: ({
        "root": {
            title: "Quickshell",
            icon: "🏠",
            parent: null,
            children: ["system", "interface", "widgets", "settings"]
        },
        
        // System branch
        "system": {
            title: "System",
            icon: "⚙️",
            parent: "root",
            children: ["performance", "monitoring", "resources"]
        },
        "performance": {
            title: "Performance Monitor",
            icon: "📊",
            parent: "system",
            children: ["performance.cpu", "performance.ram", "performance.storage", "performance.global"]
        },
        "performance.cpu": {
            title: "CPU Monitor",
            icon: "💻",
            parent: "performance",
            children: []
        },
        "performance.ram": {
            title: "RAM Monitor", 
            icon: "🧠",
            parent: "performance",
            children: []
        },
        "performance.storage": {
            title: "Storage Monitor",
            icon: "💾", 
            parent: "performance",
            children: []
        },
        "performance.global": {
            title: "Performance Settings",
            icon: "⚙️",
            parent: "performance", 
            children: []
        },
        "monitoring": {
            title: "System Monitoring",
            icon: "📈",
            parent: "system",
            children: ["monitoring.processes", "monitoring.network", "monitoring.sensors"]
        },
        "resources": {
            title: "Resource Management",
            icon: "📦",
            parent: "system",
            children: ["resources.memory", "resources.disk", "resources.services"]
        },
        
        // Interface branch
        "interface": {
            title: "Interface",
            icon: "🎨",
            parent: "root",
            children: ["interface.theme", "interface.layout", "interface.behavior"]
        },
        "interface.theme": {
            title: "Theme Settings",
            icon: "🎨",
            parent: "interface",
            children: ["interface.theme.colors", "interface.theme.fonts"]
        },
        "interface.layout": {
            title: "Layout Settings",
            icon: "📐",
            parent: "interface",
            children: ["interface.layout.panels", "interface.layout.positioning"]
        },
        "interface.behavior": {
            title: "Behavior Settings",
            icon: "⚡",
            parent: "interface",
            children: ["interface.behavior.animations", "interface.behavior.shortcuts"]
        },
        
        // Widgets branch
        "widgets": {
            title: "Widgets",
            icon: "🧩",
            parent: "root",
            children: ["widgets.bars", "widgets.overlays", "widgets.monitors"]
        },
        "widgets.bars": {
            title: "Status Bars",
            icon: "📊",
            parent: "widgets",
            children: ["widgets.bars.main", "widgets.bars.secondary"]
        },
        "widgets.overlays": {
            title: "Overlay Menus",
            icon: "🗂️",
            parent: "widgets",
            children: ["widgets.overlays.context", "widgets.overlays.settings"]
        },
        "widgets.monitors": {
            title: "System Monitors",
            icon: "📺",
            parent: "widgets",
            children: ["widgets.monitors.performance", "widgets.monitors.network"]
        },
        
        // Settings branch
        "settings": {
            title: "Settings",
            icon: "⚙️",
            parent: "root",
            children: ["settings.config", "settings.profile", "settings.advanced"]
        },
        "settings.config": {
            title: "Configuration",
            icon: "📋",
            parent: "settings",
            children: ["settings.config.save", "settings.config.load", "settings.config.reset"]
        },
        "settings.profile": {
            title: "User Profile",
            icon: "👤",
            parent: "settings",
            children: []
        },
        "settings.advanced": {
            title: "Advanced Settings",
            icon: "🔧",
            parent: "settings",
            children: []
        }
    })
    
    // Simple focus grab
    HyprlandFocusGrab {
        id: focusGrab
        windows: [menu]
        onCleared: hide()
    }
    
    Rectangle {
        id: menuContent
        anchors.fill: parent
        color: themeService ? themeService.getThemeProperty("colors", "surface") || "#313244" : "#313244"
        border.color: themeService ? themeService.getThemeProperty("colors", "border") || "#585b70" : "#585b70"
        border.width: 1
        radius: 8
        
        Column {
            anchors.fill: parent
            anchors.margins: 8
            spacing: 2
            
            // Breadcrumb Header
            Rectangle {
                width: parent.width
                height: 32
                color: "transparent"
                
                Row {
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 6
                    
                    // Back button
                    Rectangle {
                        width: 24
                        height: 24
                        radius: 4
                        visible: getCurrentMenu().parent !== null
                        color: backMouse.containsMouse ? (themeService ? themeService.getThemeProperty("colors", "surfaceAlt") || "#45475a" : "#45475a") : "transparent"
                        border.width: 1
                        border.color: themeService ? themeService.getThemeProperty("colors", "border") || "#585b70" : "#585b70"
                        
                        Text {
                            anchors.centerIn: parent
                            text: "↑"
                            color: themeService ? themeService.getThemeProperty("colors", "text") || "#cdd6f4" : "#cdd6f4"
                            font.pixelSize: 12
                            font.weight: Font.DemiBold
                        }
                        
                        MouseArea {
                            id: backMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: navigateToParent()
                        }
                    }
                    
                    // Current location
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: getCurrentMenu().icon + " " + getCurrentMenu().title
                        font.pixelSize: 13
                        font.weight: Font.DemiBold
                        color: themeService ? themeService.getThemeProperty("colors", "text") || "#cdd6f4" : "#cdd6f4"
                    }
                }
                
                // History navigation
                Row {
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 4
                    
                    Rectangle {
                        width: 22
                        height: 22
                        radius: 3
                        visible: historyIndex > 0
                        color: histBackMouse.containsMouse ? (themeService ? themeService.getThemeProperty("colors", "surfaceAlt") || "#45475a" : "#45475a") : "transparent"
                        border.width: 1
                        border.color: themeService ? themeService.getThemeProperty("colors", "border") || "#585b70" : "#585b70"
                        
                        Text {
                            anchors.centerIn: parent
                            text: "←"
                            color: themeService ? themeService.getThemeProperty("colors", "text") || "#cdd6f4" : "#cdd6f4"
                            font.pixelSize: 10
                        }
                        
                        MouseArea {
                            id: histBackMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: navigateBack()
                        }
                    }
                    
                    Rectangle {
                        width: 22
                        height: 22
                        radius: 3
                        visible: historyIndex < pathHistory.length - 1
                        color: histForwardMouse.containsMouse ? (themeService ? themeService.getThemeProperty("colors", "surfaceAlt") || "#45475a" : "#45475a") : "transparent"
                        border.width: 1
                        border.color: themeService ? themeService.getThemeProperty("colors", "border") || "#585b70" : "#585b70"
                        
                        Text {
                            anchors.centerIn: parent
                            text: "→" 
                            color: themeService ? themeService.getThemeProperty("colors", "text") || "#cdd6f4" : "#cdd6f4"
                            font.pixelSize: 10
                        }
                        
                        MouseArea {
                            id: histForwardMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: navigateForward()
                        }
                    }
                }
            }
            
            Rectangle { width: parent.width; height: 1; color: themeService ? themeService.getThemeProperty("colors", "border") || "#585b70" : "#585b70" }
            
            // Menu Content
            Loader {
                id: contentLoader
                width: parent.width
                sourceComponent: {
                    switch(currentPath) {
                        case "root": return rootMenuComponent
                        case "system": return systemMenuComponent
                        case "performance": return performanceMenuComponent
                        case "performance.cpu": return cpuMenuComponent
                        case "performance.ram": return ramMenuComponent
                        case "performance.storage": return storageMenuComponent
                        case "performance.global": return performanceGlobalMenuComponent
                        case "interface": return interfaceMenuComponent
                        case "interface.theme": return themeMenuComponent
                        case "widgets": return widgetsMenuComponent
                        case "settings": return settingsMenuComponent
                        case "settings.config": return configMenuComponent
                        default: return navigationMenuComponent
                    }
                }
            }
        }
    }
    
    // Root Menu Component
    Component {
        id: rootMenuComponent
        Column {
            spacing: 2
            
            Text {
                text: "Welcome to Quickshell"
                font.pixelSize: 10
                font.weight: Font.Medium
                color: themeService ? themeService.getThemeProperty("colors", "textAlt") || "#bac2de" : "#bac2de"
                horizontalAlignment: Text.AlignHCenter
                width: parent.width
            }
            
            Rectangle { width: parent.width; height: 1; color: themeService ? themeService.getThemeProperty("colors", "border") || "#585b70" : "#585b70"; topPadding: 4 }
            
            MenuNavItem {
                width: parent.width
                text: "⚙️ System"
                onClicked: navigateTo("system")
                themeService: menu.themeService
            }
            
            MenuNavItem {
                width: parent.width
                text: "🎨 Interface"
                onClicked: navigateTo("interface")
                themeService: menu.themeService
            }
            
            MenuNavItem {
                width: parent.width
                text: "🧩 Widgets"
                onClicked: navigateTo("widgets")
                themeService: menu.themeService
            }
            
            MenuNavItem {
                width: parent.width
                text: "⚙️ Settings"
                onClicked: navigateTo("settings")
                themeService: menu.themeService
            }
        }
    }
    
    // System Menu Component
    Component {
        id: systemMenuComponent
        Column {
            spacing: 2
            
            MenuNavItem {
                width: parent.width
                text: "📊 Performance Monitor"
                onClicked: navigateTo("performance")
                themeService: menu.themeService
            }
            
            MenuNavItem {
                width: parent.width
                text: "📈 System Monitoring"
                onClicked: navigateTo("monitoring")
                themeService: menu.themeService
            }
            
            MenuNavItem {
                width: parent.width
                text: "📦 Resource Management"
                onClicked: navigateTo("resources")
                themeService: menu.themeService
            }
        }
    }
    
    // Performance Menu Component (navigation)
    Component {
        id: performanceMenuComponent
        Column {
            spacing: 2
            
            Text {
                text: "Components"
                font.pixelSize: 9
                font.weight: Font.Medium
                color: themeService ? themeService.getThemeProperty("colors", "textAlt") || "#bac2de" : "#bac2de"
            }
            
            MenuNavItem {
                width: parent.width
                text: "💻 CPU Monitor"
                enabled: configService ? configService.getValue("performance.cpu.enabled", true) : true
                onClicked: navigateTo("performance.cpu")
                themeService: menu.themeService
            }
            
            MenuNavItem {
                width: parent.width
                text: "🧠 RAM Monitor"
                enabled: configService ? configService.getValue("performance.ram.enabled", true) : true
                onClicked: navigateTo("performance.ram")
                themeService: menu.themeService
            }
            
            MenuNavItem {
                width: parent.width
                text: "💾 Storage Monitor"
                enabled: configService ? configService.getValue("performance.storage.enabled", true) : true
                onClicked: navigateTo("performance.storage")
                themeService: menu.themeService
            }
            
            Rectangle { width: parent.width; height: 1; color: themeService ? themeService.getThemeProperty("colors", "border") || "#585b70" : "#585b70"; topMargin: 2 }
            
            Text {
                text: "Settings"
                font.pixelSize: 9
                font.weight: Font.Medium
                color: themeService ? themeService.getThemeProperty("colors", "textAlt") || "#bac2de" : "#bac2de"
                topPadding: 2
            }
            
            MenuNavItem {
                width: parent.width
                text: "⚙️ Global Settings"
                onClicked: navigateTo("performance.global")
                themeService: menu.themeService
            }
        }
    }
    
    // CPU Settings Menu
    Component {
        id: cpuMenuComponent
        Column {
            spacing: 2
            
            MenuCheckItem {
                width: parent.width
                text: "Enabled"
                checked: configService ? configService.getValue("performance.cpu.enabled", true) : true
                onToggled: { if (configService) { configService.setValue("performance.cpu.enabled", checked); configService.saveConfig() }}
                themeService: menu.themeService
            }
            
            MenuCheckItem {
                width: parent.width
                text: "Show Icon"
                checked: configService ? configService.getValue("performance.cpu.showIcon", true) : true
                onToggled: { if (configService) { configService.setValue("performance.cpu.showIcon", checked); configService.saveConfig() }}
                themeService: menu.themeService
            }
            
            MenuCheckItem {
                width: parent.width
                text: "Show Label"
                checked: configService ? configService.getValue("performance.cpu.showLabel", false) : false
                onToggled: { if (configService) { configService.setValue("performance.cpu.showLabel", checked); configService.saveConfig() }}
                themeService: menu.themeService
            }
            
            MenuCheckItem {
                width: parent.width
                text: "Show Percentage"
                checked: configService ? configService.getValue("performance.cpu.showPercentage", true) : true
                onToggled: { if (configService) { configService.setValue("performance.cpu.showPercentage", checked); configService.saveConfig() }}
                themeService: menu.themeService
            }
            
            MenuCheckItem {
                width: parent.width
                text: "Show Frequency"
                checked: configService ? configService.getValue("performance.cpu.showFrequency", false) : false
                onToggled: { if (configService) { configService.setValue("performance.cpu.showFrequency", checked); configService.saveConfig() }}
                themeService: menu.themeService
            }
            
            MenuClickItem {
                width: parent.width
                text: "Precision: " + (configService ? configService.getValue("performance.cpu.precision", 1) : 1)
                onClicked: {
                    if (configService) {
                        const current = configService.getValue("performance.cpu.precision", 1)
                        const newVal = (current + 1) % 4
                        configService.setValue("performance.cpu.precision", newVal)
                        configService.saveConfig()
                    }
                }
                themeService: menu.themeService
            }
        }
    }
    
    // RAM Settings Menu
    Component {
        id: ramMenuComponent
        Column {
            spacing: 2
            
            MenuCheckItem {
                width: parent.width
                text: "Enabled"
                checked: configService ? configService.getValue("performance.ram.enabled", true) : true
                onToggled: { if (configService) { configService.setValue("performance.ram.enabled", checked); configService.saveConfig() }}
                themeService: menu.themeService
            }
            
            MenuCheckItem {
                width: parent.width
                text: "Show Icon"
                checked: configService ? configService.getValue("performance.ram.showIcon", true) : true
                onToggled: { if (configService) { configService.setValue("performance.ram.showIcon", checked); configService.saveConfig() }}
                themeService: menu.themeService
            }
            
            MenuCheckItem {
                width: parent.width
                text: "Show Percentage"
                checked: configService ? configService.getValue("performance.ram.showPercentage", true) : true
                onToggled: { if (configService) { configService.setValue("performance.ram.showPercentage", checked); configService.saveConfig() }}
                themeService: menu.themeService
            }
            
            MenuClickItem {
                width: parent.width
                text: "Precision: " + (configService ? configService.getValue("performance.ram.precision", 0) : 0)
                onClicked: {
                    if (configService) {
                        const current = configService.getValue("performance.ram.precision", 0)
                        const newVal = (current + 1) % 4
                        configService.setValue("performance.ram.precision", newVal)
                        configService.saveConfig()
                    }
                }
                themeService: menu.themeService
            }
        }
    }
    
    // Storage Settings Menu
    Component {
        id: storageMenuComponent
        Column {
            spacing: 2
            
            MenuCheckItem {
                width: parent.width
                text: "Enabled"
                checked: configService ? configService.getValue("performance.storage.enabled", true) : true
                onToggled: { if (configService) { configService.setValue("performance.storage.enabled", checked); configService.saveConfig() }}
                themeService: menu.themeService
            }
            
            MenuCheckItem {
                width: parent.width
                text: "Show Icon"
                checked: configService ? configService.getValue("performance.storage.showIcon", true) : true
                onToggled: { if (configService) { configService.setValue("performance.storage.showIcon", checked); configService.saveConfig() }}
                themeService: menu.themeService
            }
            
            MenuCheckItem {
                width: parent.width
                text: "Show Bytes"
                checked: configService ? configService.getValue("performance.storage.showBytes", false) : false
                onToggled: { if (configService) { configService.setValue("performance.storage.showBytes", checked); configService.saveConfig() }}
                themeService: menu.themeService
            }
        }
    }
    
    // Performance Global Settings
    Component {
        id: performanceGlobalMenuComponent
        Column {
            spacing: 2
            
            MenuClickItem {
                width: parent.width
                text: "Layout: " + (configService ? configService.getValue("performance.layout", "horizontal") : "horizontal")
                onClicked: {
                    if (configService) {
                        const current = configService.getValue("performance.layout", "horizontal")
                        const layouts = ["horizontal", "vertical", "grid"]
                        const currentIndex = layouts.indexOf(current)
                        const newLayout = layouts[(currentIndex + 1) % layouts.length]
                        configService.setValue("performance.layout", newLayout)
                        configService.saveConfig()
                    }
                }
                themeService: menu.themeService
            }
            
            MenuClickItem {
                width: parent.width
                text: "Mode: " + (configService ? configService.getValue("performance.displayMode", "compact") : "compact")
                onClicked: {
                    if (configService) {
                        const current = configService.getValue("performance.displayMode", "compact")
                        const modes = ["compact", "detailed", "minimal"]
                        const currentIndex = modes.indexOf(current)
                        const newMode = modes[(currentIndex + 1) % modes.length]
                        configService.setValue("performance.displayMode", newMode)
                        configService.saveConfig()
                    }
                }
                themeService: menu.themeService
            }
        }
    }
    
    // Interface Menu
    Component {
        id: interfaceMenuComponent
        Column {
            spacing: 2
            
            MenuNavItem {
                width: parent.width
                text: "🎨 Theme Settings"
                onClicked: navigateTo("interface.theme")
                themeService: menu.themeService
            }
            
            MenuNavItem {
                width: parent.width
                text: "📐 Layout Settings"
                onClicked: navigateTo("interface.layout")
                themeService: menu.themeService
            }
            
            MenuNavItem {
                width: parent.width
                text: "⚡ Behavior Settings"
                onClicked: navigateTo("interface.behavior")
                themeService: menu.themeService
            }
        }
    }
    
    // Theme Menu
    Component {
        id: themeMenuComponent
        Column {
            spacing: 2
            
            MenuClickItem {
                width: parent.width
                text: "Theme: " + (configService ? configService.getValue("theme.activeTheme", "catppuccin-mocha") : "catppuccin-mocha")
                onClicked: {
                    // Theme cycling would go here
                }
                themeService: menu.themeService
            }
            
            MenuClickItem {
                width: parent.width
                text: "Mode: " + (configService ? configService.getValue("theme.activeMode", "dark") : "dark")
                onClicked: {
                    if (configService) {
                        const current = configService.getValue("theme.activeMode", "dark")
                        const newMode = current === "dark" ? "light" : "dark"
                        configService.setValue("theme.activeMode", newMode)
                        configService.saveConfig()
                    }
                }
                themeService: menu.themeService
            }
        }
    }
    
    // Widgets Menu
    Component {
        id: widgetsMenuComponent
        Column {
            spacing: 2
            
            MenuNavItem {
                width: parent.width
                text: "📊 Status Bars"
                onClicked: navigateTo("widgets.bars")
                themeService: menu.themeService
            }
            
            MenuNavItem {
                width: parent.width
                text: "🗂️ Overlay Menus"
                onClicked: navigateTo("widgets.overlays")
                themeService: menu.themeService
            }
            
            MenuNavItem {
                width: parent.width
                text: "📺 System Monitors"
                onClicked: navigateTo("widgets.monitors")
                themeService: menu.themeService
            }
        }
    }
    
    // Settings Menu
    Component {
        id: settingsMenuComponent
        Column {
            spacing: 2
            
            MenuNavItem {
                width: parent.width
                text: "📋 Configuration"
                onClicked: navigateTo("settings.config")
                themeService: menu.themeService
            }
            
            MenuNavItem {
                width: parent.width
                text: "👤 User Profile"
                onClicked: navigateTo("settings.profile")
                themeService: menu.themeService
            }
            
            MenuNavItem {
                width: parent.width
                text: "🔧 Advanced Settings"
                onClicked: navigateTo("settings.advanced")
                themeService: menu.themeService
            }
        }
    }
    
    // Config Menu
    Component {
        id: configMenuComponent
        Column {
            spacing: 2
            
            MenuClickItem {
                width: parent.width
                text: "💾 Save Configuration"
                onClicked: {
                    if (configService) configService.saveConfig()
                }
                themeService: menu.themeService
            }
            
            MenuClickItem {
                width: parent.width
                text: "📂 Load Configuration"
                onClicked: {
                    // Load config logic
                }
                themeService: menu.themeService
            }
            
            MenuClickItem {
                width: parent.width
                text: "🔄 Reset to Defaults"
                onClicked: {
                    // Reset logic
                }
                themeService: menu.themeService
            }
        }
    }
    
    // Generic navigation menu for paths not explicitly handled
    Component {
        id: navigationMenuComponent
        Column {
            spacing: 2
            
            Text {
                text: "Navigation Menu"
                font.pixelSize: 10
                color: themeService ? themeService.getThemeProperty("colors", "textAlt") || "#bac2de" : "#bac2de"
            }
            
            // Show children if any
            Repeater {
                model: getCurrentMenu().children || []
                
                MenuNavItem {
                    width: parent.width
                    text: menuStructure[modelData] ? (menuStructure[modelData].icon + " " + menuStructure[modelData].title) : modelData
                    onClicked: navigateTo(modelData)
                    themeService: menu.themeService
                }
            }
        }
    }
    
    // Navigation functions
    function getCurrentMenu() {
        return menuStructure[currentPath] || menuStructure["root"]
    }
    
    function navigateTo(path) {
        if (path !== currentPath) {
            pathHistory = pathHistory.slice(0, historyIndex + 1)
            pathHistory.push(path)
            historyIndex = pathHistory.length - 1
            currentPath = path
        }
    }
    
    function navigateToParent() {
        const current = getCurrentMenu()
        if (current.parent) {
            navigateTo(current.parent)
        }
    }
    
    function navigateBack() {
        if (historyIndex > 0) {
            historyIndex--
            currentPath = pathHistory[historyIndex]
        }
    }
    
    function navigateForward() {
        if (historyIndex < pathHistory.length - 1) {
            historyIndex++
            currentPath = pathHistory[historyIndex]
        }
    }
    
    // Functions
    function show(anchorWindow, x, y, startPath) {
        if (startPath) {
            currentPath = startPath
            pathHistory = [startPath]
            historyIndex = 0
        }
        
        if (anchorWindow) {
            anchor.window = anchorWindow
            anchor.rect.x = x || 0
            anchor.rect.y = y || 0
        }
        visible = true
        focusGrab.active = true
    }
    
    function hide() {
        focusGrab.active = false
        visible = false
        closed()
    }
}

// Navigation menu item (goes to child menu)
component MenuNavItem: Rectangle {
    property string text: ""
    property bool enabled: true
    property var themeService: null
    signal clicked()
    
    height: 24
    color: mouseArea.containsMouse ? (themeService ? themeService.getThemeProperty("colors", "surfaceAlt") || "#45475a" : "#45475a") : "transparent"
    
    Row {
        anchors.left: parent.left
        anchors.leftMargin: 8
        anchors.verticalCenter: parent.verticalCenter
        spacing: 8
        
        Text {
            text: parent.parent.text
            color: parent.parent.enabled ? (themeService ? themeService.getThemeProperty("colors", "text") || "#cdd6f4" : "#cdd6f4") : (themeService ? themeService.getThemeProperty("colors", "textAlt") || "#bac2de" : "#bac2de")
            font.pixelSize: 11
            anchors.verticalCenter: parent.verticalCenter
        }
        
        Text {
            text: parent.parent.enabled ? "►" : "(disabled)"
            color: themeService ? themeService.getThemeProperty("colors", "textAlt") || "#bac2de" : "#bac2de"
            font.pixelSize: 8
            anchors.verticalCenter: parent.verticalCenter
        }
    }
    
    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        onClicked: parent.clicked()
    }
}

// Checkbox menu item
component MenuCheckItem: Rectangle {
    property string text: ""
    property bool checked: false
    property var themeService: null
    signal toggled(bool checked)
    
    height: 24
    color: mouseArea.containsMouse ? (themeService ? themeService.getThemeProperty("colors", "surfaceAlt") || "#45475a" : "#45475a") : "transparent"
    
    Row {
        anchors.left: parent.left
        anchors.leftMargin: 8
        anchors.verticalCenter: parent.verticalCenter
        spacing: 8
        
        Text {
            text: parent.parent.checked ? "✓" : "○"
            color: parent.parent.checked ? "#a6e3a1" : (themeService ? themeService.getThemeProperty("colors", "textAlt") || "#bac2de" : "#bac2de")
            font.pixelSize: 10
            anchors.verticalCenter: parent.verticalCenter
        }
        
        Text {
            text: parent.parent.text
            color: themeService ? themeService.getThemeProperty("colors", "text") || "#cdd6f4" : "#cdd6f4"
            font.pixelSize: 11
            anchors.verticalCenter: parent.verticalCenter
        }
    }
    
    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        onClicked: {
            parent.checked = !parent.checked
            parent.toggled(parent.checked)
        }
    }
}

// Clickable menu item (for cycling values)
component MenuClickItem: Rectangle {
    property string text: ""
    property var themeService: null
    signal clicked()
    
    height: 24
    color: mouseArea.containsMouse ? (themeService ? themeService.getThemeProperty("colors", "surfaceAlt") || "#45475a" : "#45475a") : "transparent"
    
    Text {
        anchors.left: parent.left
        anchors.leftMargin: 8
        anchors.verticalCenter: parent.verticalCenter
        text: parent.text
        color: themeService ? themeService.getThemeProperty("colors", "text") || "#cdd6f4" : "#cdd6f4"
        font.pixelSize: 11
    }
    
    Text {
        anchors.right: parent.right
        anchors.rightMargin: 8
        anchors.verticalCenter: parent.verticalCenter
        text: "↻"
        color: themeService ? themeService.getThemeProperty("colors", "textAlt") || "#bac2de" : "#bac2de"
        font.pixelSize: 9
    }
    
    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        onClicked: parent.clicked()
    }
}