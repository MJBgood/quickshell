import Quickshell
import Quickshell.Widgets
import Quickshell.Hyprland
import QtQuick
import QtQuick.Controls
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
                
                // Left side: Home button and breadcrumb text
                Row {
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.right: historyNav.left
                    anchors.rightMargin: 8
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
                    
                    // Full breadcrumb path with text wrapping
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        width: parent.width - (currentPath !== "root" ? 34 : 0) // Account for home button width + spacing
                        text: getBreadcrumbText()
                        font.pixelSize: 12
                        font.weight: Font.DemiBold
                        color: themeService ? themeService.getThemeProperty("colors", "text") || "#cdd6f4" : "#cdd6f4"
                        wrapMode: Text.WordWrap
                        maximumLineCount: 2
                        elide: Text.ElideRight
                    }
                }
                
                // History navigation (right side)
                Row {
                    id: historyNav
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
                    text: "💡 Click monitor items to configure individual settings"
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
                        acceptedButtons: Qt.LeftButton
                        onClicked: function(mouse) {
                            // Navigate to selected item
                            navigateTo(parent.childId)
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
            
            // Theme-specific interface
            Column {
                visible: currentPath === "interface-theme"
                width: parent.width
                spacing: 8
                
                // Theme selector header
                Item {
                    width: parent.width
                    height: 32
                    
                    Text {
                        text: "🎨"
                        font.pixelSize: 18
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                    }
                    
                    Column {
                        anchors.left: parent.left
                        anchors.leftMargin: 28
                        anchors.verticalCenter: parent.verticalCenter
                        
                        Text {
                            text: "Theme Selector"
                            font.pixelSize: 13
                            font.weight: Font.DemiBold
                            color: themeService ? themeService.getThemeProperty("colors", "text") || "#cdd6f4" : "#cdd6f4"
                        }
                        
                        Text {
                            text: "Choose your interface theme"
                            font.pixelSize: 9
                            color: themeService ? themeService.getThemeProperty("colors", "textAlt") || "#bac2de" : "#bac2de"
                        }
                    }
                }
                
                // Separator
                Rectangle {
                    width: parent.width
                    height: 1
                    color: themeService ? themeService.getThemeProperty("colors", "border") || "#585b70" : "#585b70"
                }
                
                // Current theme display
                Rectangle {
                    width: parent.width
                    height: 40
                    radius: 6
                    color: themeService ? themeService.getThemeProperty("colors", "surfaceAlt") || "#45475a" : "#45475a"
                    
                    Row {
                        anchors.left: parent.left
                        anchors.leftMargin: 12
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 8
                        
                        Rectangle {
                            width: 8
                            height: 8
                            radius: 4
                            anchors.verticalCenter: parent.verticalCenter
                            color: themeService ? themeService.getThemeProperty("colors", "accent") || "#a6e3a1" : "#a6e3a1"
                        }
                        
                        Column {
                            spacing: 2
                            
                            Text {
                                text: "Current: " + (themeService ? (themeService.currentThemeData ? themeService.currentThemeData.name : themeService.activeTheme) : "Unknown")
                                font.pixelSize: 11
                                font.weight: Font.Medium
                                color: themeService ? themeService.getThemeProperty("colors", "text") || "#cdd6f4" : "#cdd6f4"
                            }
                            
                            Text {
                                text: (themeService && themeService.darkMode ? "🌙 Dark" : "☀️ Light") + " Mode"
                                font.pixelSize: 9
                                color: themeService ? themeService.getThemeProperty("colors", "textAlt") || "#bac2de" : "#bac2de"
                            }
                        }
                    }
                    
                    // Mode toggle button
                    Rectangle {
                        anchors.right: parent.right
                        anchors.rightMargin: 8
                        anchors.verticalCenter: parent.verticalCenter
                        width: 60
                        height: 24
                        radius: 12
                        color: themeService ? themeService.getThemeProperty("colors", "primary") || "#89b4fa" : "#89b4fa"
                        visible: themeService && themeService.currentThemeData && themeService.currentThemeData.supportsModes
                        
                        Text {
                            anchors.centerIn: parent
                            text: themeService && themeService.darkMode ? "🌙" : "☀️"
                            font.pixelSize: 10
                        }
                        
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (themeService) {
                                    themeService.toggleDarkMode()
                                }
                            }
                        }
                    }
                }
                
                // Open full theme selector button
                Rectangle {
                    width: parent.width
                    height: 32
                    radius: 6
                    color: themeSelectorMouse.containsMouse ? 
                           (themeService ? themeService.getThemeProperty("colors", "primary") || "#89b4fa" : "#89b4fa") :
                           (themeService ? themeService.getThemeProperty("colors", "surface") || "#313244" : "#313244")
                    border.width: 1
                    border.color: themeService ? themeService.getThemeProperty("colors", "primary") || "#89b4fa" : "#89b4fa"
                    
                    Row {
                        anchors.centerIn: parent
                        spacing: 8
                        
                        Text {
                            text: "🎨"
                            font.pixelSize: 12
                        }
                        
                        Text {
                            text: "Open Theme Selector"
                            font.pixelSize: 11
                            font.weight: Font.Medium
                            color: themeSelectorMouse.containsMouse ?
                                   (themeService ? themeService.getThemeProperty("colors", "onPrimary") || "#1e1e2e" : "#1e1e2e") :
                                   (themeService ? themeService.getThemeProperty("colors", "primary") || "#89b4fa" : "#89b4fa")
                        }
                    }
                    
                    MouseArea {
                        id: themeSelectorMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            // Close this menu and show theme dropdown
                            hide()
                            if (sourceComponent && sourceComponent.barWindow && sourceComponent.barWindow.shellRoot) {
                                sourceComponent.barWindow.shellRoot.showThemeDropdown()
                            }
                        }
                    }
                    
                    Behavior on color {
                        ColorAnimation { duration: 150 }
                    }
                }
            }
            
            // Monitor-specific detailed configuration
            ScrollView {
                visible: isMonitorItem(currentPath)
                width: parent.width
                height: Math.min(350, contentHeight)
                clip: true
                
                Component.onCompleted: {
                    ScrollBar.horizontal.policy = ScrollBar.AlwaysOff
                    ScrollBar.vertical.policy = ScrollBar.AsNeeded
                }
                
                ScrollBar.vertical: ScrollBar {
                    active: true
                    policy: ScrollBar.AsNeeded
                    size: 0.3
                    width: 6
                    
                    background: Rectangle {
                        color: "transparent"
                        radius: 3
                    }
                    
                    contentItem: Rectangle {
                        color: themeService ? themeService.getThemeProperty("colors", "border") || "#585b70" : "#585b70"
                        radius: 3
                        opacity: 0.6
                    }
                }
                
                Column {
                    width: parent.width
                    spacing: 8
                    
                    // Monitor header
                    Item {
                        width: parent.width
                        height: 32
                        
                        Text {
                            id: monitorIconText
                            text: getMonitorIcon(currentPath)
                            font.pixelSize: 18
                            anchors.left: parent.left
                            anchors.verticalCenter: parent.verticalCenter
                        }
                        
                        Column {
                            anchors.left: monitorIconText.right
                            anchors.leftMargin: 10
                            anchors.verticalCenter: parent.verticalCenter
                            
                            Text {
                                text: getMonitorTitle(currentPath) + " Monitor"
                                font.pixelSize: 13
                                font.weight: Font.DemiBold
                                color: themeService ? themeService.getThemeProperty("colors", "text") || "#cdd6f4" : "#cdd6f4"
                            }
                            
                            Text {
                                text: getMonitorEnabled(currentPath) ? "Enabled" : "Disabled"
                                font.pixelSize: 9
                                color: getMonitorEnabled(currentPath) ? "#a6e3a1" : "#f38ba8"
                            }
                        }
                    }
                    
                    // Separator
                    Rectangle {
                        width: parent.width
                        height: 1
                        color: themeService ? themeService.getThemeProperty("colors", "border") || "#585b70" : "#585b70"
                    }
                    
                    // Interactive configuration options
                    Column {
                        width: parent.width
                        spacing: 6
                        
                        // Enable/Disable toggle
                        MonitorToggleItem {
                            width: parent.width
                            label: "Monitor"
                            value: getMonitorEnabled(currentPath) ? "Enabled" : "Disabled"
                            isActive: getMonitorEnabled(currentPath)
                            onClicked: toggleMonitorConfig(currentPath, "enabled")
                        }
                        
                        // Icon toggle
                        MonitorToggleItem {
                            width: parent.width
                            label: "Icon"
                            value: getMonitorConfigValue(currentPath, "showIcon", true) ? getMonitorIcon(currentPath) : "Hidden"
                            isActive: getMonitorConfigValue(currentPath, "showIcon", true)
                            onClicked: toggleMonitorConfig(currentPath, "showIcon")
                        }
                        
                        // Label toggle
                        MonitorToggleItem {
                            width: parent.width
                            label: "Label"
                            value: getMonitorConfigValue(currentPath, "showLabel", false) ? ("\"" + getMonitorTitle(currentPath) + "\"") : "Hidden"
                            isActive: getMonitorConfigValue(currentPath, "showLabel", false)
                            onClicked: toggleMonitorConfig(currentPath, "showLabel")
                        }
                        
                        // Percentage toggle
                        MonitorToggleItem {
                            width: parent.width
                            label: "Percentage"
                            value: getMonitorConfigValue(currentPath, "showPercentage", true) ? "XX.X%" : "Hidden"
                            isActive: getMonitorConfigValue(currentPath, "showPercentage", true)
                            onClicked: toggleMonitorConfig(currentPath, "showPercentage")
                        }
                        
                        // Frequency toggle (CPU and RAM only)
                        MonitorToggleItem {
                            visible: currentPath === "cpu" || currentPath === "ram"
                            width: parent.width
                            label: "Frequency"
                            value: getMonitorConfigValue(currentPath, "showFrequency", false) ? "X.X GHz" : "Hidden"
                            isActive: getMonitorConfigValue(currentPath, "showFrequency", false)
                            onClicked: toggleMonitorConfig(currentPath, "showFrequency")
                        }
                        
                        // Total toggle (RAM only)
                        MonitorToggleItem {
                            visible: currentPath === "ram"
                            width: parent.width
                            label: "Show Total"
                            value: getMonitorConfigValue(currentPath, "showTotal", true) ? "X.X/Y.Y GB" : "Hidden"
                            isActive: getMonitorConfigValue(currentPath, "showTotal", true)
                            onClicked: toggleMonitorConfig(currentPath, "showTotal")
                        }
                        
                        // Bytes toggle (Storage only)
                        MonitorToggleItem {
                            visible: currentPath === "storage"
                            width: parent.width
                            label: "Bytes Format"
                            value: getMonitorConfigValue(currentPath, "showBytes", false) ? "X.X/Y.Y GB" : "Hidden"
                            isActive: getMonitorConfigValue(currentPath, "showBytes", false)
                            onClicked: toggleMonitorConfig(currentPath, "showBytes")
                        }
                        
                        // Precision
                        MonitorToggleItem {
                            width: parent.width
                            label: "Precision"
                            value: getMonitorConfigValue(currentPath, "precision", currentPath === "cpu" ? 1 : 0) + " decimal" + (getMonitorConfigValue(currentPath, "precision", currentPath === "cpu" ? 1 : 0) === 1 ? "" : "s")
                            isActive: true
                            onClicked: cycleMonitorPrecision(currentPath)
                        }
                    }
                    
                    // Separator
                    Rectangle {
                        width: parent.width
                        height: 1
                        color: themeService ? themeService.getThemeProperty("colors", "border") || "#585b70" : "#585b70"
                    }
                    
                    // Live preview
                    Column {
                        width: parent.width
                        spacing: 4
                        
                        Text {
                            text: "Current Display:"
                            font.pixelSize: 10
                            font.weight: Font.DemiBold
                            color: themeService ? themeService.getThemeProperty("colors", "textAlt") || "#bac2de" : "#bac2de"
                        }
                        
                        Rectangle {
                            width: parent.width
                            height: previewText.implicitHeight + 8
                            color: themeService ? themeService.getThemeProperty("colors", "surfaceAlt") || "#45475a" : "#45475a"
                            radius: 6
                            
                            Text {
                                id: previewText
                                anchors.centerIn: parent
                                text: getMonitorDisplayPreview(currentPath)
                                font.pixelSize: 11
                                font.family: "monospace"
                                color: themeService ? themeService.getThemeProperty("colors", "text") || "#cdd6f4" : "#cdd6f4"
                            }
                        }
                    }
                }
            }
            
        }
    }
    
    // Monitor Toggle Item inline component
    component MonitorToggleItem: Rectangle {
        property string label: ""
        property string value: ""
        property bool isActive: false
        signal clicked()
        
        height: 24
        radius: 4
        color: toggleMouse.containsMouse ? 
               (themeService ? themeService.getThemeProperty("colors", "surfaceAlt") || "#45475a" : "#45475a") : 
               "transparent"
        
        Row {
            anchors.left: parent.left
            anchors.leftMargin: 8
            anchors.verticalCenter: parent.verticalCenter
            spacing: 8
            
            Text {
                text: label + ":"
                font.pixelSize: 10
                color: themeService ? themeService.getThemeProperty("colors", "text") || "#cdd6f4" : "#cdd6f4"
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
    
    // Check if an item is a monitor component
    function isMonitorItem(id) {
        return id === "cpu" || id === "ram" || id === "storage"
    }
    
    // Monitor helper functions
    function getMonitorIcon(monitorId) {
        switch(monitorId) {
            case "cpu": return "💻"
            case "ram": return "🧠"
            case "storage": return "💾"
            default: return "📊"
        }
    }
    
    function getMonitorTitle(monitorId) {
        switch(monitorId) {
            case "cpu": return "CPU"
            case "ram": return "RAM"
            case "storage": return "Storage"
            default: return "Monitor"
        }
    }
    
    function getMonitorEnabled(monitorId) {
        return getMonitorConfigValue(monitorId, "enabled", true)
    }
    
    function getMonitorConfigValue(monitorId, key, defaultValue) {
        if (!configService) return defaultValue
        return configService.getValue(`performance.${monitorId}.${key}`, defaultValue)
    }
    
    function toggleMonitorConfig(monitorId, key) {
        if (!configService) return
        
        const configKey = `performance.${monitorId}.${key}`
        const currentValue = configService.getValue(configKey, key === "showLabel" ? false : true)
        const newValue = !currentValue
        
        configService.setValue(configKey, newValue)
        configService.saveConfig()
        
        console.log(`[HierarchicalMenu] Updated ${configKey} = ${newValue}`)
        
        // Force refresh the menu content to show updated values
        Qt.callLater(function() {
            contentLoader.sourceComponent = getMenuComponent()
        })
    }
    
    function cycleMonitorPrecision(monitorId) {
        if (!configService) return
        
        const configKey = `performance.${monitorId}.precision`
        const currentPrecision = configService.getValue(configKey, monitorId === "cpu" ? 1 : 0)
        const newPrecision = (currentPrecision + 1) % 4
        
        configService.setValue(configKey, newPrecision)
        configService.saveConfig()
        
        console.log(`[HierarchicalMenu] Updated ${configKey} = ${newPrecision}`)
        
        // Force refresh the menu content to show updated values
        Qt.callLater(function() {
            contentLoader.sourceComponent = getMenuComponent()
        })
    }
    
    function getMonitorDisplayPreview(monitorId) {
        if (!configService) return "Preview unavailable"
        
        let parts = []
        
        if (getMonitorConfigValue(monitorId, "showIcon", true)) {
            parts.push(getMonitorIcon(monitorId))
        }
        
        if (getMonitorConfigValue(monitorId, "showLabel", false)) {
            parts.push(getMonitorTitle(monitorId))
        }
        
        const precision = getMonitorConfigValue(monitorId, "precision", monitorId === "cpu" ? 1 : 0)
        
        if (monitorId === "cpu") {
            let cpuParts = []
            if (getMonitorConfigValue(monitorId, "showPercentage", true)) {
                cpuParts.push((42.5).toFixed(precision) + "%")
            } else {
                cpuParts.push((42.5).toFixed(precision))
            }
            if (getMonitorConfigValue(monitorId, "showFrequency", false)) {
                cpuParts.push("3.2 GHz")
            }
            if (cpuParts.length > 0) {
                parts.push(cpuParts.join(" | "))
            }
        } else if (monitorId === "ram") {
            let ramParts = []
            if (getMonitorConfigValue(monitorId, "showPercentage", true)) {
                ramParts.push((68.3).toFixed(precision) + "%")
            }
            if (getMonitorConfigValue(monitorId, "showTotal", true)) {
                ramParts.push("10.9/16.0 GB")
            } else if (!getMonitorConfigValue(monitorId, "showPercentage", true)) {
                ramParts.push("10.9 GB")
            }
            if (ramParts.length > 0) {
                parts.push(ramParts.join(" | "))
            }
            if (getMonitorConfigValue(monitorId, "showFrequency", false)) {
                parts.push("3200 MHz")
            }
        } else if (monitorId === "storage") {
            let storageParts = []
            if (getMonitorConfigValue(monitorId, "showPercentage", true)) {
                storageParts.push((85.2).toFixed(precision) + "%")
            }
            if (getMonitorConfigValue(monitorId, "showBytes", false)) {
                storageParts.push("426.1/500.0 GB")
            } else if (!getMonitorConfigValue(monitorId, "showPercentage", true)) {
                storageParts.push("426.1 GB")
            }
            if (storageParts.length > 0) {
                parts.push(storageParts.join(" | "))
            }
        }
        
        return parts.length > 0 ? parts.join(" ") : "No display configured"
    }
    
}