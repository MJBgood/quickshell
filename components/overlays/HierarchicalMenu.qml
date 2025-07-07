import Quickshell
import Quickshell.Widgets
import Quickshell.Hyprland
import QtQuick

PopupWindow {
    id: menu
    
    visible: false
    color: "transparent"
    implicitWidth: 240
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
    property var configService: ConfigService
    
    // Navigation state
    property string currentPath: "performance"
    property var pathHistory: ["performance"]
    property int historyIndex: 0
    
    // Signals
    signal closed()
    
    // Path definitions
    property var menuStructure: ({
        "performance": {
            title: "Performance Monitor",
            icon: "📊",
            parent: null,
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
            title: "Global Settings",
            icon: "⚙️",
            parent: "performance", 
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
        color: configService ? configService.getThemeProperty("colors", "surface") || "#313244" : "#313244"
        border.color: configService ? configService.getThemeProperty("colors", "border") || "#585b70" : "#585b70"
        border.width: 1
        radius: 8
        
        Column {
            anchors.fill: parent
            anchors.margins: 8
            spacing: 2
            
            // Breadcrumb Header
            Rectangle {
                width: parent.width
                height: 24
                color: "transparent"
                
                Row {
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 4
                    
                    // Back button (if not at root)
                    Rectangle {
                        width: 20
                        height: 18
                        radius: 3
                        visible: getCurrentMenu().parent !== null
                        color: backMouse.containsMouse ? (configService ? configService.getThemeProperty("colors", "surfaceAlt") || "#45475a" : "#45475a") : "transparent"
                        
                        Text {
                            anchors.centerIn: parent
                            text: "↑"
                            color: configService ? configService.getThemeProperty("colors", "text") || "#cdd6f4" : "#cdd6f4"
                            font.pixelSize: 10
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
                        font.pixelSize: 11
                        font.weight: Font.DemiBold
                        color: configService ? configService.getThemeProperty("colors", "text") || "#cdd6f4" : "#cdd6f4"
                    }
                }
                
                // History navigation (if available)
                Row {
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 2
                    
                    Rectangle {
                        width: 18
                        height: 18
                        radius: 3
                        visible: historyIndex > 0
                        color: histBackMouse.containsMouse ? (configService ? configService.getThemeProperty("colors", "surfaceAlt") || "#45475a" : "#45475a") : "transparent"
                        
                        Text {
                            anchors.centerIn: parent
                            text: "←"
                            color: configService ? configService.getThemeProperty("colors", "text") || "#cdd6f4" : "#cdd6f4"
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
                        color: histForwardMouse.containsMouse ? (configService ? configService.getThemeProperty("colors", "surfaceAlt") || "#45475a" : "#45475a") : "transparent"
                        
                        Text {
                            anchors.centerIn: parent
                            text: "→" 
                            color: configService ? configService.getThemeProperty("colors", "text") || "#cdd6f4" : "#cdd6f4"
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
            
            Rectangle { width: parent.width; height: 1; color: configService ? configService.getThemeProperty("colors", "border") || "#585b70" : "#585b70" }
            
            // Menu Content
            Loader {
                id: contentLoader
                width: parent.width
                sourceComponent: {
                    switch(currentPath) {
                        case "performance": return rootMenuComponent
                        case "performance.cpu": return cpuMenuComponent
                        case "performance.ram": return ramMenuComponent
                        case "performance.storage": return storageMenuComponent
                        case "performance.global": return globalMenuComponent
                        default: return rootMenuComponent
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
                text: "Components"
                font.pixelSize: 9
                font.weight: Font.Medium
                color: configService ? configService.getThemeProperty("colors", "textAlt") || "#bac2de" : "#bac2de"
            }
            
            MenuNavItem {
                width: parent.width
                text: "💻 CPU Monitor"
                enabled: configService ? configService.getValue("performance.cpu.enabled", true) : true
                onClicked: navigateTo("performance.cpu")
                configService: menu.configService
            }
            
            MenuNavItem {
                width: parent.width
                text: "🧠 RAM Monitor"
                enabled: configService ? configService.getValue("performance.ram.enabled", true) : true
                onClicked: navigateTo("performance.ram")
                configService: menu.configService
            }
            
            MenuNavItem {
                width: parent.width
                text: "💾 Storage Monitor"
                enabled: configService ? configService.getValue("performance.storage.enabled", true) : true
                onClicked: navigateTo("performance.storage")
                configService: menu.configService
            }
            
            Rectangle { width: parent.width; height: 1; color: configService ? configService.getThemeProperty("colors", "border") || "#585b70" : "#585b70"; topMargin: 2 }
            
            Text {
                text: "Settings"
                font.pixelSize: 9
                font.weight: Font.Medium
                color: configService ? configService.getThemeProperty("colors", "textAlt") || "#bac2de" : "#bac2de"
                topPadding: 2
            }
            
            MenuNavItem {
                width: parent.width
                text: "⚙️ Global Settings"
                onClicked: navigateTo("performance.global")
                configService: menu.configService
            }
        }
    }
    
    // CPU Menu Component
    Component {
        id: cpuMenuComponent
        Column {
            spacing: 2
            
            MenuCheckItem {
                width: parent.width
                text: "Enabled"
                checked: configService ? configService.getValue("performance.cpu.enabled", true) : true
                onToggled: { if (configService) { configService.setValue("performance.cpu.enabled", checked); configService.saveConfig() }}
                configService: menu.configService
            }
            
            MenuCheckItem {
                width: parent.width
                text: "Show Icon"
                checked: configService ? configService.getValue("performance.cpu.showIcon", true) : true
                onToggled: { if (configService) { configService.setValue("performance.cpu.showIcon", checked); configService.saveConfig() }}
                configService: menu.configService
            }
            
            MenuCheckItem {
                width: parent.width
                text: "Show Label"
                checked: configService ? configService.getValue("performance.cpu.showLabel", false) : false
                onToggled: { if (configService) { configService.setValue("performance.cpu.showLabel", checked); configService.saveConfig() }}
                configService: menu.configService
            }
            
            MenuCheckItem {
                width: parent.width
                text: "Show Percentage"
                checked: configService ? configService.getValue("performance.cpu.showPercentage", true) : true
                onToggled: { if (configService) { configService.setValue("performance.cpu.showPercentage", checked); configService.saveConfig() }}
                configService: menu.configService
            }
            
            MenuCheckItem {
                width: parent.width
                text: "Show Frequency"
                checked: configService ? configService.getValue("performance.cpu.showFrequency", false) : false
                onToggled: { if (configService) { configService.setValue("performance.cpu.showFrequency", checked); configService.saveConfig() }}
                configService: menu.configService
            }
            
            MenuClickItem {
                width: parent.width
                text: "Precision: " + (configService ? configService.getValue("performance.cpu.precision", 1) : 1)
                onClicked: {
                    if (configService) {
                        const current = configService.getValue("performance.cpu.precision", 1)
                        const newVal = (current + 1) % 4  // Cycle 0-3
                        configService.setValue("performance.cpu.precision", newVal)
                        configService.saveConfig()
                    }
                }
                configService: menu.configService
            }
        }
    }
    
    // RAM Menu Component  
    Component {
        id: ramMenuComponent
        Column {
            spacing: 2
            
            MenuCheckItem {
                width: parent.width
                text: "Enabled"
                checked: configService ? configService.getValue("performance.ram.enabled", true) : true
                onToggled: { if (configService) { configService.setValue("performance.ram.enabled", checked); configService.saveConfig() }}
                configService: menu.configService
            }
            
            MenuCheckItem {
                width: parent.width
                text: "Show Icon"
                checked: configService ? configService.getValue("performance.ram.showIcon", true) : true
                onToggled: { if (configService) { configService.setValue("performance.ram.showIcon", checked); configService.saveConfig() }}
                configService: menu.configService
            }
            
            MenuCheckItem {
                width: parent.width
                text: "Show Percentage"
                checked: configService ? configService.getValue("performance.ram.showPercentage", true) : true
                onToggled: { if (configService) { configService.setValue("performance.ram.showPercentage", checked); configService.saveConfig() }}
                configService: menu.configService
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
                configService: menu.configService
            }
        }
    }
    
    // Storage Menu Component
    Component {
        id: storageMenuComponent
        Column {
            spacing: 2
            
            MenuCheckItem {
                width: parent.width
                text: "Enabled"
                checked: configService ? configService.getValue("performance.storage.enabled", true) : true
                onToggled: { if (configService) { configService.setValue("performance.storage.enabled", checked); configService.saveConfig() }}
                configService: menu.configService
            }
            
            MenuCheckItem {
                width: parent.width
                text: "Show Icon"
                checked: configService ? configService.getValue("performance.storage.showIcon", true) : true
                onToggled: { if (configService) { configService.setValue("performance.storage.showIcon", checked); configService.saveConfig() }}
                configService: menu.configService
            }
            
            MenuCheckItem {
                width: parent.width
                text: "Show Bytes"
                checked: configService ? configService.getValue("performance.storage.showBytes", false) : false
                onToggled: { if (configService) { configService.setValue("performance.storage.showBytes", checked); configService.saveConfig() }}
                configService: menu.configService
            }
        }
    }
    
    // Global Menu Component
    Component {
        id: globalMenuComponent
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
                configService: menu.configService
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
                configService: menu.configService
            }
        }
    }
    
    // Navigation functions
    function getCurrentMenu() {
        return menuStructure[currentPath] || menuStructure["performance"]
    }
    
    function navigateTo(path) {
        // Add to history if moving to new location
        if (path !== currentPath) {
            // Truncate history if we're in the middle of it
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
    function show(anchorWindow, x, y) {
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
    property var configService: ConfigService
    signal clicked()
    
    height: 20
    color: mouseArea.containsMouse ? (configService ? configService.getThemeProperty("colors", "surfaceAlt") || "#45475a" : "#45475a") : "transparent"
    
    Row {
        anchors.left: parent.left
        anchors.leftMargin: 8
        anchors.verticalCenter: parent.verticalCenter
        spacing: 8
        
        Text {
            text: parent.parent.text
            color: parent.parent.enabled ? (configService ? configService.getThemeProperty("colors", "text") || "#cdd6f4" : "#cdd6f4") : (configService ? configService.getThemeProperty("colors", "textAlt") || "#bac2de" : "#bac2de")
            font.pixelSize: 10
            anchors.verticalCenter: parent.verticalCenter
        }
        
        Text {
            text: parent.parent.enabled ? "►" : "(disabled)"
            color: configService ? configService.getThemeProperty("colors", "textAlt") || "#bac2de" : "#bac2de"
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
    property var configService: ConfigService
    signal toggled(bool checked)
    
    height: 20
    color: mouseArea.containsMouse ? (configService ? configService.getThemeProperty("colors", "surfaceAlt") || "#45475a" : "#45475a") : "transparent"
    
    Row {
        anchors.left: parent.left
        anchors.leftMargin: 8
        anchors.verticalCenter: parent.verticalCenter
        spacing: 8
        
        Text {
            text: parent.parent.checked ? "✓" : "○"
            color: parent.parent.checked ? "#a6e3a1" : (configService ? configService.getThemeProperty("colors", "textAlt") || "#bac2de" : "#bac2de")
            font.pixelSize: 9
            anchors.verticalCenter: parent.verticalCenter
        }
        
        Text {
            text: parent.parent.text
            color: configService ? configService.getThemeProperty("colors", "text") || "#cdd6f4" : "#cdd6f4"
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

// Clickable menu item (for cycling values)
component MenuClickItem: Rectangle {
    property string text: ""
    property var configService: ConfigService
    signal clicked()
    
    height: 20
    color: mouseArea.containsMouse ? (configService ? configService.getThemeProperty("colors", "surfaceAlt") || "#45475a" : "#45475a") : "transparent"
    
    Text {
        anchors.left: parent.left
        anchors.leftMargin: 8
        anchors.verticalCenter: parent.verticalCenter
        text: parent.text
        color: configService ? configService.getThemeProperty("colors", "text") || "#cdd6f4" : "#cdd6f4"
        font.pixelSize: 10
    }
    
    Text {
        anchors.right: parent.right
        anchors.rightMargin: 8
        anchors.verticalCenter: parent.verticalCenter
        text: "↻"
        color: configService ? configService.getThemeProperty("colors", "textAlt") || "#bac2de" : "#bac2de"
        font.pixelSize: 8
    }
    
    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        onClicked: parent.clicked()
    }
}