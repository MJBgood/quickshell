import Quickshell
import Quickshell.Widgets
import Quickshell.Hyprland
import QtQuick

PopupWindow {
    id: menu
    
    visible: false
    color: "transparent"
    implicitWidth: 260
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
    
    // Global menu structure - covers entire project
    property var menuStructure: ({
        "root": {
            title: "Quickshell",
            icon: "🏠",
            parent: null,
            children: ["system", "widgets", "interface", "settings"]
        },
        
        // System Level
        "system": {
            title: "System",
            icon: "⚙️",
            parent: "root",
            children: ["system.performance", "system.monitoring", "system.resources"]
        },
        "system.performance": {
            title: "Performance Monitor",
            icon: "📊",
            parent: "system",
            children: ["system.performance.cpu", "system.performance.ram", "system.performance.storage", "system.performance.global"]
        },
        "system.performance.cpu": {
            title: "CPU Monitor",
            icon: "💻",
            parent: "system.performance",
            children: []
        },
        "system.performance.ram": {
            title: "RAM Monitor", 
            icon: "🧠",
            parent: "system.performance",
            children: []
        },
        "system.performance.storage": {
            title: "Storage Monitor",
            icon: "💾", 
            parent: "system.performance",
            children: []
        },
        "system.performance.global": {
            title: "Performance Settings",
            icon: "⚙️",
            parent: "system.performance", 
            children: []
        },
        "system.monitoring": {
            title: "System Monitoring",
            icon: "📈",
            parent: "system",
            children: ["system.monitoring.processes", "system.monitoring.network", "system.monitoring.sensors"]
        },
        "system.resources": {
            title: "Resource Management",
            icon: "📦",
            parent: "system",
            children: ["system.resources.memory", "system.resources.disk", "system.resources.services"]
        },
        
        // Widgets Level
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
            children: ["widgets.overlays.context", "widgets.overlays.settings", "widgets.overlays.data"]
        },
        "widgets.monitors": {
            title: "System Monitors",
            icon: "📺",
            parent: "widgets",
            children: ["widgets.monitors.performance", "widgets.monitors.network", "widgets.monitors.thermal"]
        },
        
        // Interface Level
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
            children: ["interface.theme.colors", "interface.theme.fonts", "interface.theme.effects"]
        },
        "interface.layout": {
            title: "Layout Settings",
            icon: "📐",
            parent: "interface",
            children: ["interface.layout.panels", "interface.layout.positioning", "interface.layout.spacing"]
        },
        "interface.behavior": {
            title: "Behavior Settings",
            icon: "⚡",
            parent: "interface",
            children: ["interface.behavior.animations", "interface.behavior.interactions", "interface.behavior.shortcuts"]
        },
        
        // Settings Level
        "settings": {
            title: "Global Settings",
            icon: "⚙️",
            parent: "root",
            children: ["settings.configuration", "settings.profile", "settings.advanced"]
        },
        "settings.configuration": {
            title: "Configuration",
            icon: "📋",
            parent: "settings",
            children: ["settings.configuration.save", "settings.configuration.load", "settings.configuration.reset"]
        },
        "settings.profile": {
            title: "User Profile",
            icon: "👤",
            parent: "settings",
            children: ["settings.profile.preferences", "settings.profile.customization"]
        },
        "settings.advanced": {
            title: "Advanced Settings",
            icon: "🔧",
            parent: "settings",
            children: ["settings.advanced.debug", "settings.advanced.performance", "settings.advanced.experimental"]
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
                height: 28
                color: "transparent"
                
                Row {
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 4
                    
                    // Back button (if not at root)
                    Rectangle {
                        width: 20
                        height: 20
                        radius: 4
                        visible: getCurrentMenu().parent !== null
                        color: backMouse.containsMouse ? (themeService ? themeService.getThemeProperty("colors", "surfaceAlt") || "#45475a" : "#45475a") : "transparent"
                        
                        Text {
                            anchors.centerIn: parent
                            text: "↑"
                            color: themeService ? themeService.getThemeProperty("colors", "text") || "#cdd6f4" : "#cdd6f4"
                            font.pixelSize: 11
                        }
                        
                        MouseArea {
                            id: backMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: navigateToParent()
                        }
                    }
                    
                    // Path breadcrumb
                    Row {
                        spacing: 4
                        
                        Repeater {
                            model: getPathBreadcrumbs()
                            
                            Row {
                                spacing: 2
                                
                                Text {
                                    text: modelData.icon
                                    color: themeService ? themeService.getThemeProperty("colors", "text") || "#cdd6f4" : "#cdd6f4"
                                    font.pixelSize: 10
                                }
                                
                                Text {
                                    text: modelData.title
                                    color: themeService ? themeService.getThemeProperty("colors", "text") || "#cdd6f4" : "#cdd6f4"
                                    font.pixelSize: 10
                                    font.weight: index === getPathBreadcrumbs().length - 1 ? Font.DemiBold : Font.Normal
                                }
                                
                                Text {
                                    visible: index < getPathBreadcrumbs().length - 1
                                    text: "›"
                                    color: themeService ? themeService.getThemeProperty("colors", "textAlt") || "#bac2de" : "#bac2de"
                                    font.pixelSize: 8
                                }
                            }
                        }
                    }
                }
                
                // History navigation
                Row {
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 2
                    
                    Rectangle {
                        width: 18
                        height: 18
                        radius: 3
                        visible: historyIndex > 0
                        color: histBackMouse.containsMouse ? (themeService ? themeService.getThemeProperty("colors", "surfaceAlt") || "#45475a" : "#45475a") : "transparent"
                        
                        Text {
                            anchors.centerIn: parent
                            text: "←"
                            color: themeService ? themeService.getThemeProperty("colors", "text") || "#cdd6f4" : "#cdd6f4"
                            font.pixelSize: 9
                        }
                        
                        MouseArea {
                            id: histBackMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: navigateBack()
                        }
                    }
                    
                    Rectangle {
                        width: 18
                        height: 18
                        radius: 3
                        visible: historyIndex < pathHistory.length - 1
                        color: histForwardMouse.containsMouse ? (themeService ? themeService.getThemeProperty("colors", "surfaceAlt") || "#45475a" : "#45475a") : "transparent"
                        
                        Text {
                            anchors.centerIn: parent
                            text: "→" 
                            color: themeService ? themeService.getThemeProperty("colors", "text") || "#cdd6f4" : "#cdd6f4"
                            font.pixelSize: 9
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
                sourceComponent: getMenuComponent()
            }
        }
    }
    
    // Dynamic menu content based on current path
    function getMenuComponent() {
        const current = getCurrentMenu()
        
        return Qt.createComponent("", `
            import QtQuick
            Column {
                spacing: 2
                
                // Children navigation
                ${current.children.map(childPath => {
                    const child = menuStructure[childPath]
                    return child ? `
                        MenuNavItem {
                            width: parent.width
                            text: "${child.icon} ${child.title}"
                            onClicked: navigateTo("${childPath}")
                            themeService: menu.themeService
                        }
                    ` : ''
                }).join('')}
                
                // Settings for leaf nodes
                ${current.children.length === 0 ? getLeafMenuContent(currentPath) : ''}
            }
        `)
    }
    
    // Specific content for leaf menu nodes
    function getLeafMenuContent(path) {
        if (path.startsWith("system.performance.")) {
            return getPerformanceMenuContent(path)
        } else if (path.startsWith("interface.theme.")) {
            return getThemeMenuContent(path)
        } else if (path.startsWith("settings.")) {
            return getSettingsMenuContent(path)
        }
        return ""
    }
    
    function getPerformanceMenuContent(path) {
        const monitor = path.split('.').pop()
        if (monitor === "global") {
            return `
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
            `
        } else {
            return `
                MenuCheckItem {
                    width: parent.width
                    text: "Enabled"
                    checked: configService ? configService.getValue("performance.${monitor}.enabled", true) : true
                    onToggled: { if (configService) { configService.setValue("performance.${monitor}.enabled", checked); configService.saveConfig() }}
                    themeService: menu.themeService
                }
                MenuCheckItem {
                    width: parent.width
                    text: "Show Icon"
                    checked: configService ? configService.getValue("performance.${monitor}.showIcon", true) : true
                    onToggled: { if (configService) { configService.setValue("performance.${monitor}.showIcon", checked); configService.saveConfig() }}
                    themeService: menu.themeService
                }
                MenuCheckItem {
                    width: parent.width
                    text: "Show Percentage"
                    checked: configService ? configService.getValue("performance.${monitor}.showPercentage", true) : true
                    onToggled: { if (configService) { configService.setValue("performance.${monitor}.showPercentage", checked); configService.saveConfig() }}
                    themeService: menu.themeService
                }
            `
        }
    }
    
    function getThemeMenuContent(path) {
        return `
            MenuClickItem {
                width: parent.width
                text: "Theme: " + (configService ? configService.getValue("theme.activeTheme", "catppuccin-mocha") : "catppuccin-mocha")
                onClicked: {
                    // Theme switching logic would go here
                }
                themeService: menu.themeService
            }
        `
    }
    
    function getSettingsMenuContent(path) {
        return `
            MenuClickItem {
                width: parent.width
                text: "Save Configuration"
                onClicked: {
                    if (configService) configService.saveConfig()
                }
                themeService: menu.themeService
            }
            MenuClickItem {
                width: parent.width
                text: "Reset to Defaults"
                onClicked: {
                    // Reset logic would go here
                }
                themeService: menu.themeService
            }
        `
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
    
    function getPathBreadcrumbs() {
        const breadcrumbs = []
        let current = getCurrentMenu()
        const path = []
        
        // Build path from current to root
        while (current) {
            path.unshift(current)
            current = current.parent ? menuStructure[current.parent] : null
        }
        
        return path
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

// Reusable menu item components
component MenuNavItem: Rectangle {
    property string text: ""
    property var themeService: null
    signal clicked()
    
    height: 22
    color: mouseArea.containsMouse ? (themeService ? themeService.getThemeProperty("colors", "surfaceAlt") || "#45475a" : "#45475a") : "transparent"
    
    Row {
        anchors.left: parent.left
        anchors.leftMargin: 8
        anchors.verticalCenter: parent.verticalCenter
        spacing: 8
        
        Text {
            text: parent.parent.text
            color: themeService ? themeService.getThemeProperty("colors", "text") || "#cdd6f4" : "#cdd6f4"
            font.pixelSize: 10
            anchors.verticalCenter: parent.verticalCenter
        }
        
        Text {
            text: "►"
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

component MenuCheckItem: Rectangle {
    property string text: ""
    property bool checked: false
    property var themeService: null
    signal toggled(bool checked)
    
    height: 22
    color: mouseArea.containsMouse ? (themeService ? themeService.getThemeProperty("colors", "surfaceAlt") || "#45475a" : "#45475a") : "transparent"
    
    Row {
        anchors.left: parent.left
        anchors.leftMargin: 8
        anchors.verticalCenter: parent.verticalCenter
        spacing: 8
        
        Text {
            text: parent.parent.checked ? "✓" : "○"
            color: parent.parent.checked ? "#a6e3a1" : (themeService ? themeService.getThemeProperty("colors", "textAlt") || "#bac2de" : "#bac2de")
            font.pixelSize: 9
            anchors.verticalCenter: parent.verticalCenter
        }
        
        Text {
            text: parent.parent.text
            color: themeService ? themeService.getThemeProperty("colors", "text") || "#cdd6f4" : "#cdd6f4"
            font.pixelSize: 10
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

component MenuClickItem: Rectangle {
    property string text: ""
    property var themeService: null
    signal clicked()
    
    height: 22
    color: mouseArea.containsMouse ? (themeService ? themeService.getThemeProperty("colors", "surfaceAlt") || "#45475a" : "#45475a") : "transparent"
    
    Text {
        anchors.left: parent.left
        anchors.leftMargin: 8
        anchors.verticalCenter: parent.verticalCenter
        text: parent.text
        color: themeService ? themeService.getThemeProperty("colors", "text") || "#cdd6f4" : "#cdd6f4"
        font.pixelSize: 10
    }
    
    Text {
        anchors.right: parent.right
        anchors.rightMargin: 8
        anchors.verticalCenter: parent.verticalCenter
        text: "↻"
        color: themeService ? themeService.getThemeProperty("colors", "textAlt") || "#bac2de" : "#bac2de"
        font.pixelSize: 8
    }
    
    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        onClicked: parent.clicked()
    }
}