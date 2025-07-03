import Quickshell
import Quickshell.Widgets
import Quickshell.Hyprland
import QtQuick
import "../base"

PopupWindow {
    id: menu
    
    visible: false
    color: "transparent"
    implicitWidth: configService ? configService.menuWidth : 300
    implicitHeight: contentColumn.implicitHeight + (configService ? configService.defaultMargin * 4 : 40)  // margins + padding
    
    // Anchor configuration following Quickshell patterns
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
    
    // Component that initiated the menu
    property var sourceComponent: null
    
    // Signals
    signal closed()
    
    // Quickshell-style focus grab
    HyprlandFocusGrab {
        id: focusGrab
        windows: [menu]
        onCleared: hide()
    }
    
    // Menu structure based on component hierarchy
    property var menuStructure: ({
        "root": {
            title: "Quickshell",
            icon: "🏠",
            parent: null,
            children: ["system", "interface", "widgets", "settings"]
        },
        "system": {
            title: "System",
            icon: "⚙️",
            parent: "root",
            children: ["performance", "monitoring"]
        },
        "performance": {
            title: "Performance Monitor",
            icon: "📊",
            parent: "system",
            children: ["cpu", "ram", "storage", "performance-global"]
        },
        "cpu": {
            title: "CPU Monitor",
            icon: "💻",
            parent: "performance",
            children: []
        },
        "ram": {
            title: "RAM Monitor", 
            icon: "🧠",
            parent: "performance",
            children: []
        },
        "storage": {
            title: "Storage Monitor",
            icon: "💾", 
            parent: "performance",
            children: []
        },
        "performance-global": {
            title: "Performance Settings",
            icon: "⚙️",
            parent: "performance", 
            children: []
        },
        "interface": {
            title: "Interface",
            icon: "🎨",
            parent: "root",
            children: ["interface-theme", "interface-layout"]
        },
        "interface-theme": {
            title: "Theme Settings",
            icon: "🎨",
            parent: "interface",
            children: []
        },
        "interface-layout": {
            title: "Layout Settings",
            icon: "📐",
            parent: "interface",
            children: []
        },
        "widgets": {
            title: "Widgets",
            icon: "🧩",
            parent: "root",
            children: ["widgets-bars", "widgets-overlays"]
        },
        "widgets-bars": {
            title: "Status Bars",
            icon: "📊",
            parent: "widgets",
            children: []
        },
        "widgets-overlays": {
            title: "Overlay Menus",
            icon: "🗂️",
            parent: "widgets",
            children: []
        },
        "settings": {
            title: "Settings",
            icon: "⚙️",
            parent: "root",
            children: ["settings-config", "settings-profile"]
        },
        "settings-config": {
            title: "Configuration",
            icon: "📋",
            parent: "settings",
            children: []
        },
        "settings-profile": {
            title: "User Profile",
            icon: "👤",
            parent: "settings",
            children: []
        }
    })
    
    Rectangle {
        id: menuContent
        anchors.fill: parent
        color: themeService ? themeService.getThemeProperty("colors", "surface") || "#313244" : "#313244"
        border.color: themeService ? themeService.getThemeProperty("colors", "border") || "#585b70" : "#585b70"
        border.width: 1
        radius: 8
        
        Column {
            id: contentColumn
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.margins: 10
            spacing: 4
            
            // Breadcrumb Header
            Rectangle {
                width: parent.width
                height: 32
                color: "transparent"
                
                Row {
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 6
                    
                    // Home button
                    Rectangle {
                        width: 28
                        height: 28
                        radius: 6
                        visible: currentPath !== "root"
                        color: homeMouse.containsMouse ? 
                               (themeService ? themeService.getThemeProperty("colors", "accent") || "#a6e3a1" : "#a6e3a1") : 
                               "transparent"
                        border.width: 1
                        border.color: themeService ? themeService.getThemeProperty("colors", "accent") || "#a6e3a1" : "#a6e3a1"
                        
                        Text {
                            anchors.centerIn: parent
                            text: "🏠"
                            color: themeService ? themeService.getThemeProperty("colors", "text") || "#cdd6f4" : "#cdd6f4"
                            font.pixelSize: 12
                        }
                        
                        MouseArea {
                            id: homeMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: navigateTo("root")
                        }
                    }
                    
                    // Back button
                    Rectangle {
                        width: 28
                        height: 28
                        radius: 6
                        visible: getCurrentMenu().parent !== null
                        color: backMouse.containsMouse ? 
                               (themeService ? themeService.getThemeProperty("colors", "surfaceAlt") || "#45475a" : "#45475a") : 
                               "transparent"
                        border.width: 1
                        border.color: themeService ? themeService.getThemeProperty("colors", "border") || "#585b70" : "#585b70"
                        
                        Text {
                            anchors.centerIn: parent
                            text: "↑"
                            color: themeService ? themeService.getThemeProperty("colors", "text") || "#cdd6f4" : "#cdd6f4"
                            font.pixelSize: 12
                        }
                        
                        MouseArea {
                            id: backMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: navigateToParent()
                        }
                    }
                    
                    // Full breadcrumb path
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: getBreadcrumbText()
                        font.pixelSize: 14
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
                        width: 24
                        height: 24
                        radius: 4
                        visible: historyIndex > 0
                        color: histBackMouse.containsMouse ? 
                               (themeService ? themeService.getThemeProperty("colors", "surfaceAlt") || "#45475a" : "#45475a") : 
                               "transparent"
                        border.width: 1
                        border.color: themeService ? themeService.getThemeProperty("colors", "border") || "#585b70" : "#585b70"
                        
                        Text {
                            anchors.centerIn: parent
                            text: "←"
                            color: themeService ? themeService.getThemeProperty("colors", "text") || "#cdd6f4" : "#cdd6f4"
                            font.pixelSize: 11
                        }
                        
                        MouseArea {
                            id: histBackMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: navigateBack()
                        }
                    }
                    
                    Rectangle {
                        width: 24
                        height: 24
                        radius: 4
                        visible: historyIndex < pathHistory.length - 1
                        color: histForwardMouse.containsMouse ? 
                               (themeService ? themeService.getThemeProperty("colors", "surfaceAlt") || "#45475a" : "#45475a") : 
                               "transparent"
                        border.width: 1
                        border.color: themeService ? themeService.getThemeProperty("colors", "border") || "#585b70" : "#585b70"
                        
                        Text {
                            anchors.centerIn: parent
                            text: "→" 
                            color: themeService ? themeService.getThemeProperty("colors", "text") || "#cdd6f4" : "#cdd6f4"
                            font.pixelSize: 11
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
            
            Rectangle { 
                width: parent.width
                height: 1
                color: themeService ? themeService.getThemeProperty("colors", "border") || "#585b70" : "#585b70" 
            }
            
            // Menu Content - dynamically loaded based on current path
            Loader {
                id: contentLoader
                width: parent.width
                sourceComponent: getMenuComponent()
                
                onItemChanged: {
                    if (item) {
                        item.width = Qt.binding(() => contentLoader.width)
                    }
                }
            }
        }
    }
    
    // Dynamic menu component getter
    function getMenuComponent() {
        const current = getCurrentMenu()
        
        if (current.children.length > 0) {
            return navigationComponent
        } else {
            return settingsComponent
        }
    }
    
    // Navigation Component for non-leaf nodes
    Component {
        id: navigationComponent
        Column {
            spacing: 3
            
            // Help text for performance section
            Rectangle {
                visible: currentPath === "performance"
                width: parent.width
                height: 28
                color: "transparent"
                border.width: 1
                border.color: themeService ? themeService.getThemeProperty("colors", "accent") || "#a6e3a1" : "#a6e3a1"
                radius: 4
                
                Text {
                    anchors.centerIn: parent
                    text: "💡 Right-click monitor items (⚙️) for detailed configuration"
                    color: themeService ? themeService.getThemeProperty("colors", "accent") || "#a6e3a1" : "#a6e3a1"
                    font.pixelSize: 9
                    font.italic: true
                }
            }
            
            Repeater {
                model: getCurrentMenu().children
                
                delegate: Rectangle {
                    width: parent.width
                    height: 28
                    radius: 6
                    color: childMouse.containsMouse ? 
                           (themeService ? themeService.getThemeProperty("colors", "surfaceAlt") || "#45475a" : "#45475a") : 
                           "transparent"
                    
                    property string childId: modelData
                    property var childMenu: menuStructure[childId]
                    
                    Row {
                        anchors.left: parent.left
                        anchors.leftMargin: 12
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 10
                        
                        Text {
                            text: parent.parent.childMenu ? parent.parent.childMenu.icon + " " + parent.parent.childMenu.title : ""
                            color: themeService ? themeService.getThemeProperty("colors", "text") || "#cdd6f4" : "#cdd6f4"
                            font.pixelSize: 12
                            anchors.verticalCenter: parent.verticalCenter
                        }
                        
                        Text {
                            text: "►"
                            color: themeService ? themeService.getThemeProperty("colors", "textAlt") || "#bac2de" : "#bac2de"
                            font.pixelSize: 9
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }
                    
                    // Gear icon for monitor items - positioned on the right
                    Text {
                        visible: isMonitorItem(parent.childId)
                        anchors.right: parent.right
                        anchors.rightMargin: 12
                        anchors.verticalCenter: parent.verticalCenter
                        text: "⚙️"
                        font.pixelSize: 10
                        color: themeService ? themeService.getThemeProperty("colors", "accent") || "#a6e3a1" : "#a6e3a1"
                    }
                    
                    MouseArea {
                        id: childMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        acceptedButtons: Qt.LeftButton | Qt.RightButton
                        onClicked: function(mouse) {
                            if (mouse.button === Qt.RightButton && isMonitorItem(parent.childId)) {
                                // Right-click on monitor item - show specialized overlay
                                showMonitorDataOverlay(parent.childId, mouse.x, mouse.y)
                            } else {
                                // Left-click - normal navigation
                                navigateTo(parent.childId)
                            }
                        }
                    }
                }
            }
        }
    }
    
    // Settings Component for leaf nodes
    Component {
        id: settingsComponent
        Column {
            spacing: 3
            
            Repeater {
                model: getSettingsForPath(currentPath)
                
                delegate: Rectangle {
                    width: parent.width
                    height: 28
                    radius: 6
                    color: settingMouse.containsMouse ? 
                           (themeService ? themeService.getThemeProperty("colors", "surfaceAlt") || "#45475a" : "#45475a") : 
                           "transparent"
                    
                    property var setting: modelData
                    
                    Row {
                        anchors.left: parent.left
                        anchors.leftMargin: 12
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 10
                        
                        Text {
                            text: parent.parent.setting.type === "checkbox" ? 
                                  (parent.parent.setting.checked ? "✓" : "○") : 
                                  "↻"
                            color: parent.parent.setting.type === "checkbox" && parent.parent.setting.checked ? 
                                   "#a6e3a1" : 
                                   (themeService ? themeService.getThemeProperty("colors", "textAlt") || "#bac2de" : "#bac2de")
                            font.pixelSize: 10
                            anchors.verticalCenter: parent.verticalCenter
                        }
                        
                        Text {
                            text: parent.parent.setting.text
                            color: themeService ? themeService.getThemeProperty("colors", "text") || "#cdd6f4" : "#cdd6f4"
                            font.pixelSize: 12
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }
                    
                    MouseArea {
                        id: settingMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: handleSettingClick(parent.setting)
                    }
                }
            }
        }
    }
    
    // Generate settings based on current path
    function getSettingsForPath(path) {
        switch(path) {
            case "cpu":
                return [
                    {type: "checkbox", key: "performance.cpu.enabled", text: "Enabled", checked: configService ? configService.getValue("performance.cpu.enabled", true) : true},
                    {type: "checkbox", key: "performance.cpu.showIcon", text: "Show Icon", checked: configService ? configService.getValue("performance.cpu.showIcon", true) : true},
                    {type: "checkbox", key: "performance.cpu.showPercentage", text: "Show Percentage", checked: configService ? configService.getValue("performance.cpu.showPercentage", true) : true},
                    {type: "cycle", key: "performance.cpu.precision", text: "Precision: " + (configService ? configService.getValue("performance.cpu.precision", 1) : 1), values: [0, 1, 2, 3]}
                ]
            case "ram":
                return [
                    {type: "checkbox", key: "performance.ram.enabled", text: "Enabled", checked: configService ? configService.getValue("performance.ram.enabled", true) : true},
                    {type: "checkbox", key: "performance.ram.showIcon", text: "Show Icon", checked: configService ? configService.getValue("performance.ram.showIcon", true) : true},
                    {type: "checkbox", key: "performance.ram.showPercentage", text: "Show Percentage", checked: configService ? configService.getValue("performance.ram.showPercentage", true) : true},
                    {type: "cycle", key: "performance.ram.precision", text: "Precision: " + (configService ? configService.getValue("performance.ram.precision", 0) : 0), values: [0, 1, 2, 3]}
                ]
            case "storage":
                return [
                    {type: "checkbox", key: "performance.storage.enabled", text: "Enabled", checked: configService ? configService.getValue("performance.storage.enabled", true) : true},
                    {type: "checkbox", key: "performance.storage.showIcon", text: "Show Icon", checked: configService ? configService.getValue("performance.storage.showIcon", true) : true},
                    {type: "checkbox", key: "performance.storage.showBytes", text: "Show Bytes", checked: configService ? configService.getValue("performance.storage.showBytes", false) : false}
                ]
            case "performance-global":
                return [
                    {type: "cycle", key: "performance.layout", text: "Layout: " + (configService ? configService.getValue("performance.layout", "horizontal") : "horizontal"), values: ["horizontal", "vertical", "grid"]},
                    {type: "cycle", key: "performance.displayMode", text: "Mode: " + (configService ? configService.getValue("performance.displayMode", "compact") : "compact"), values: ["compact", "detailed", "minimal"]}
                ]
            default:
                return []
        }
    }
    
    // Handle setting clicks
    function handleSettingClick(setting) {
        if (!configService) return
        
        if (setting.type === "checkbox") {
            configService.setValue(setting.key, !setting.checked)
            configService.saveConfig()
        } else if (setting.type === "cycle") {
            const current = configService.getValue(setting.key, setting.values[0])
            const currentIndex = setting.values.indexOf(current)
            const newValue = setting.values[(currentIndex + 1) % setting.values.length]
            configService.setValue(setting.key, newValue)
            configService.saveConfig()
        }
        
        // Refresh content
        contentLoader.sourceComponent = getMenuComponent()
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
            contentLoader.sourceComponent = getMenuComponent()
        }
    }
    
    function navigateToParent() {
        const current = getCurrentMenu()
        if (current.parent) {
            navigateTo(current.parent)
        }
    }
    
    // Build breadcrumb path showing full hierarchy
    function getBreadcrumbText() {
        const path = []
        let current = getCurrentMenu()
        
        // Build path from current back to root
        while (current && current.title !== "Quickshell") {
            path.unshift(current.icon + " " + current.title)
            current = current.parent ? menuStructure[current.parent] : null
        }
        
        return path.length > 0 ? path.join(" › ") : "🏠 Home"
    }
    
    function navigateBack() {
        if (historyIndex > 0) {
            historyIndex--
            currentPath = pathHistory[historyIndex]
            contentLoader.sourceComponent = getMenuComponent()
        }
    }
    
    function navigateForward() {
        if (historyIndex < pathHistory.length - 1) {
            historyIndex++
            currentPath = pathHistory[historyIndex]
            contentLoader.sourceComponent = getMenuComponent()
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
        
        // Refresh content
        contentLoader.sourceComponent = getMenuComponent()
        
        visible = true
        focusGrab.active = true
    }
    
    function hide() {
        focusGrab.active = false
        visible = false
        closed()
    }
    
    // Check if an item is a monitor component that can show specialized overlay
    function isMonitorItem(id) {
        return id === "cpu" || id === "ram" || id === "storage"
    }
    
    // Show specialized monitor data overlay
    function showMonitorDataOverlay(monitorId, x, y) {
        console.log(`[HierarchicalMenu] Loading specialized overlay for: ${monitorId}`)
        
        const sourceComponent = ComponentRegistry.getComponent(monitorId)
        if (sourceComponent) {
            // Close hierarchical menu first
            hide()
            
            // Show the monitor's specialized data overlay
            if (typeof sourceComponent.showDataOverlay === 'function') {
                sourceComponent.showDataOverlay()
            } else {
                console.warn(`[HierarchicalMenu] Component ${monitorId} does not support data overlay`)
            }
        }
    }
}