import Quickshell
import Quickshell.Widgets
import Quickshell.Hyprland
import QtQuick
import QtCore

PopupWindow {
    id: contextMenu
    
    // Window properties
    visible: false
    color: "transparent"
    
    // Services
    property var configService: null
    property var themeService: null
    
    // Signals
    signal closed()
    
    // Logging category
    LoggingCategory {
        id: logCategory
        name: "quickshell.performance.contextmenu"
        defaultLogLevel: LoggingCategory.Info
    }
    
    // Anchor configuration - following Quickshell best practices
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
    
    // Hyprland focus grab for proper click-away behavior
    HyprlandFocusGrab {
        id: focusGrab
        windows: [contextMenu]
        onCleared: {
            console.log("Focus grab cleared, hiding menu")
            hide()
        }
    }
    
    // Set PopupWindow implicit size
    implicitWidth: 220
    implicitHeight: contentColumn.implicitHeight + 16
    
    // Main menu container
    Rectangle {
        id: menuContent
        anchors.fill: parent
        color: themeService ? themeService.getThemeProperty("colors", "surface") || "#313244" : "#313244"
        border.color: themeService ? themeService.getThemeProperty("colors", "border") || "#585b70" : "#585b70"
        border.width: 1
        radius: 8
        
        // Prevent clicks from going through to background
        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.AllButtons
            onClicked: function(mouse) {
                mouse.accepted = true
            }
            onPressed: function(mouse) {
                mouse.accepted = true
            }
            onReleased: function(mouse) {
                mouse.accepted = true
            }
        }
        
        Column {
            id: contentColumn
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: 8
            spacing: 4
            
            // Header
            Rectangle {
                width: parent.width
                height: 32
                color: "transparent"
                
                Text {
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.leftMargin: 8
                    text: "Performance Monitor"
                    font.pixelSize: 12
                    font.weight: Font.DemiBold
                    color: themeService ? themeService.getThemeProperty("colors", "text") || "#cdd6f4" : "#cdd6f4"
                }
            }
            
            // Separator
            Rectangle {
                width: parent.width
                height: 1
                color: themeService ? themeService.getThemeProperty("colors", "border") || "#585b70" : "#585b70"
            }
            
            // CPU Section
            Rectangle {
                width: parent.width
                height: 24
                color: cpuMouse.containsMouse ? (themeService ? themeService.getThemeProperty("colors", "surfaceAlt") || "#45475a" : "#45475a") : "transparent"
                
                Row {
                    anchors.left: parent.left
                    anchors.leftMargin: 8
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 8
                    
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: "💻 CPU"
                        font.pixelSize: 10
                        color: themeService ? themeService.getThemeProperty("colors", "text") || "#cdd6f4" : "#cdd6f4"
                    }
                    
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: (configService && configService.getValue("performance.cpu.enabled", true)) ? "✓" : "✗"
                        color: (configService && configService.getValue("performance.cpu.enabled", true)) ? "#a6e3a1" : "#f38ba8"
                        font.pixelSize: 10
                        font.weight: Font.DemiBold
                    }
                }
                
                Text {
                    anchors.right: parent.right
                    anchors.rightMargin: 8
                    anchors.verticalCenter: parent.verticalCenter
                    text: "⚙️"
                    color: themeService ? themeService.getThemeProperty("colors", "textAlt") || "#bac2de" : "#bac2de"
                    font.pixelSize: 10
                }
                
                MouseArea {
                    id: cpuMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    z: 10
                    onClicked: function(mouse) {
                        // Check if clicked on settings area (right side)
                        if (mouse.x > parent.width - 30) {
                            // Show nested CPU settings menu
                            showNestedMenu("cpu", mouse.x, mouse.y)
                        } else {
                            // Toggle enabled/disabled
                            if (configService) {
                                const current = configService.getValue("performance.cpu.enabled", true)
                                configService.setValue("performance.cpu.enabled", !current)
                                configService.saveConfig()
                            }
                            // Don't hide the menu, let user continue configuring
                        }
                        mouse.accepted = true
                    }
                }
            }
            
            // RAM Section
            Rectangle {
                width: parent.width
                height: 24
                color: ramMouse.containsMouse ? (themeService ? themeService.getThemeProperty("colors", "surfaceAlt") || "#45475a" : "#45475a") : "transparent"
                
                Row {
                    anchors.left: parent.left
                    anchors.leftMargin: 8
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 8
                    
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: "🧠 RAM"
                        font.pixelSize: 10
                        color: themeService ? themeService.getThemeProperty("colors", "text") || "#cdd6f4" : "#cdd6f4"
                    }
                    
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: (configService && configService.getValue("performance.ram.enabled", true)) ? "✓" : "✗"
                        color: (configService && configService.getValue("performance.ram.enabled", true)) ? "#a6e3a1" : "#f38ba8"
                        font.pixelSize: 10
                        font.weight: Font.DemiBold
                    }
                }
                
                Text {
                    anchors.right: parent.right
                    anchors.rightMargin: 8
                    anchors.verticalCenter: parent.verticalCenter
                    text: "⚙️"
                    color: themeService ? themeService.getThemeProperty("colors", "textAlt") || "#bac2de" : "#bac2de"
                    font.pixelSize: 10
                }
                
                MouseArea {
                    id: ramMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    z: 10
                    onClicked: function(mouse) {
                        if (mouse.x > parent.width - 30) {
                            showNestedMenu("ram", mouse.x, mouse.y)
                        } else {
                            if (configService) {
                                const current = configService.getValue("performance.ram.enabled", true)
                                configService.setValue("performance.ram.enabled", !current)
                                configService.saveConfig()
                            }
                            // Don't hide the menu, let user continue configuring
                        }
                        mouse.accepted = true
                    }
                }
            }
            
            // Storage Section
            Rectangle {
                width: parent.width
                height: 24
                color: storageMouse.containsMouse ? (themeService ? themeService.getThemeProperty("colors", "surfaceAlt") || "#45475a" : "#45475a") : "transparent"
                
                Row {
                    anchors.left: parent.left
                    anchors.leftMargin: 8
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 8
                    
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: "💾 Storage"
                        font.pixelSize: 10
                        color: themeService ? themeService.getThemeProperty("colors", "text") || "#cdd6f4" : "#cdd6f4"
                    }
                    
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: (configService && configService.getValue("performance.storage.enabled", true)) ? "✓" : "✗"
                        color: (configService && configService.getValue("performance.storage.enabled", true)) ? "#a6e3a1" : "#f38ba8"
                        font.pixelSize: 10
                        font.weight: Font.DemiBold
                    }
                }
                
                Text {
                    anchors.right: parent.right
                    anchors.rightMargin: 8
                    anchors.verticalCenter: parent.verticalCenter
                    text: "⚙️"
                    color: themeService ? themeService.getThemeProperty("colors", "textAlt") || "#bac2de" : "#bac2de"
                    font.pixelSize: 10
                }
                
                MouseArea {
                    id: storageMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    z: 10
                    onClicked: function(mouse) {
                        if (mouse.x > parent.width - 30) {
                            showNestedMenu("storage", mouse.x, mouse.y)
                        } else {
                            if (configService) {
                                const current = configService.getValue("performance.storage.enabled", true)
                                configService.setValue("performance.storage.enabled", !current)
                                configService.saveConfig()
                            }
                            // Don't hide the menu, let user continue configuring
                        }
                        mouse.accepted = true
                    }
                }
            }
            
            // Separator
            Rectangle {
                width: parent.width
                height: 1
                color: themeService ? themeService.getThemeProperty("colors", "border") || "#585b70" : "#585b70"
            }
            
            // Global Settings
            Rectangle {
                width: parent.width
                height: 28
                color: "transparent"
                
                Text {
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.leftMargin: 8
                    text: "⚙️ Global Settings"
                    font.pixelSize: 11
                    font.weight: Font.Medium
                    color: themeService ? themeService.getThemeProperty("colors", "text") || "#cdd6f4" : "#cdd6f4"
                }
            }
            
            // Layout toggle
            Rectangle {
                width: parent.width
                height: 24
                color: layoutMouse.containsMouse ? (themeService ? themeService.getThemeProperty("colors", "surfaceAlt") || "#45475a" : "#45475a") : "transparent"
                
                Text {
                    anchors.left: parent.left
                    anchors.leftMargin: 8
                    anchors.verticalCenter: parent.verticalCenter
                    text: "Layout: " + (configService ? configService.getValue("performance.layout", "horizontal") : "horizontal")
                    color: themeService ? themeService.getThemeProperty("colors", "text") || "#cdd6f4" : "#cdd6f4"
                    font.pixelSize: 10
                }
                
                MouseArea {
                    id: layoutMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    z: 10
                    onClicked: function(mouse) {
                        if (configService) {
                            const current = configService.getValue("performance.layout", "horizontal")
                            const newLayout = current === "horizontal" ? "vertical" : "horizontal"
                            configService.setValue("performance.layout", newLayout)
                            configService.saveConfig()
                        }
                        mouse.accepted = true
                        // Don't hide the menu, let user continue configuring
                    }
                }
            }
            
            // Display mode toggle  
            Rectangle {
                width: parent.width
                height: 24
                color: modeMouse.containsMouse ? (themeService ? themeService.getThemeProperty("colors", "surfaceAlt") || "#45475a" : "#45475a") : "transparent"
                
                Text {
                    anchors.left: parent.left
                    anchors.leftMargin: 8
                    anchors.verticalCenter: parent.verticalCenter
                    text: "Mode: " + (configService ? configService.getValue("performance.displayMode", "compact") : "compact")
                    color: themeService ? themeService.getThemeProperty("colors", "text") || "#cdd6f4" : "#cdd6f4"
                    font.pixelSize: 10
                }
                
                MouseArea {
                    id: modeMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    z: 10
                    onClicked: function(mouse) {
                        if (configService) {
                            const current = configService.getValue("performance.displayMode", "compact")
                            const newMode = current === "compact" ? "detailed" : "compact"
                            configService.setValue("performance.displayMode", newMode)
                            configService.saveConfig()
                        }
                        mouse.accepted = true
                        // Don't hide the menu, let user continue configuring
                    }
                }
            }
        }
    }
    
    
    // Nested menu loader
    Loader {
        id: nestedMenuLoader
        source: "../overlays/MonitorDataOverlay.qml"
        active: false
        
        onLoaded: {
            item.configService = contextMenu.configService
            item.themeService = contextMenu.themeService
            item.monitorName = nestedMenuType.toUpperCase()
            item.monitorType = nestedMenuType
            item.monitorIcon = nestedMenuType === "cpu" ? "🖥️" : (nestedMenuType === "ram" ? "🧠" : "💾")
            
            item.closed.connect(function() {
                nestedMenuLoader.active = false
            })
        }
    }
    
    property string nestedMenuType: ""
    
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
    
    function showNestedMenu(monitorType, x, y) {
        nestedMenuType = monitorType
        nestedMenuLoader.active = true
        if (nestedMenuLoader.item) {
            const windowToUse = anchor.window || contextMenu
            // Position nested menu to the right of the main menu
            nestedMenuLoader.item.show(windowToUse, x + 220, y)
        }
    }
}