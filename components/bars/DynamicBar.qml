import Quickshell
import Quickshell.Hyprland
import QtQuick
import "../widgets"
import "../base" 
import "../overlays"
import "../../services"

PanelWindow {
    id: bar
    
    // Required property for screen assignment
    property var modelData
    
    // Access to services (passed from parent)
    property var themeService: null
    property var configService: null
    property var systemMonitorService: null
    property var windowTracker: null
    property var iconResolver: null
    property var sessionOverlay: null
    property var shellRoot: null
    property var wallpaperService: null
    property var widgetRegistry: null
    
    // GraphicalComponent interface implementation
    property string componentId: "bar"
    property string parentComponentId: ""
    property var childComponentIds: []  // Will be populated dynamically
    property string menuPath: "bar"
    
    // Panel configuration - position determined by config
    property string position: configService ? configService.getValue("panel.position", "top") : "top"
    
    // Set screen from modelData (for multi-monitor support)
    screen: modelData
    
    anchors {
        top: position === "top"
        bottom: position === "bottom"
        left: true
        right: true
    }
    
    implicitHeight: 32
    color: themeService ? themeService.getThemeProperty("colors", "background") || "#1e1e2e" : "#1e1e2e"
    
    // Content - Dynamic layout based on widget registry
    Item {
        anchors.fill: parent
        anchors.margins: 8
        
        // Left section - App launcher icon (clickable)
        Rectangle {
            id: leftSection
            width: 32
            height: parent.height
            color: themeService ? themeService.getThemeProperty("colors", "surface") || "#313244" : "#313244"
            radius: 4
            
            anchors {
                left: parent.left
                verticalCenter: parent.verticalCenter
            }
            
            // App launcher icon
            Text {
                anchors.centerIn: parent
                text: "⚙"  // Settings gear icon as placeholder
                color: themeService ? themeService.getThemeProperty("colors", "text") || "#cdd6f4" : "#cdd6f4"
                font.pixelSize: 16
            }
            
            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                hoverEnabled: true
                
                onClicked: {
                    if (bar.shellRoot) {
                        var anchorRect = {
                            x: leftSection.x,
                            y: leftSection.y,
                            width: leftSection.width,
                            height: leftSection.height
                        }
                        bar.shellRoot.toggleSettings(bar, anchorRect)
                    }
                }
                
                onEntered: parent.opacity = 0.8
                onExited: parent.opacity = 1.0
            }
            
            Behavior on opacity {
                NumberAnimation { duration: 150; easing.type: Easing.OutCubic }
            }
        }
        
        // Center section - Dynamic widgets
        Row {
            id: widgetRow
            anchors {
                left: leftSection.right
                leftMargin: 8
                verticalCenter: parent.verticalCenter
            }
            height: parent.height - 4  // Explicit height
            spacing: 4
            
            // Dynamic widget repeater
            Repeater {
                id: widgetRepeater
                model: getAllWidgets()
                
                delegate: WidgetContainer {
                    widgetData: modelData
                    
                    // Pass all services to widget containers
                    configService: bar.configService
                    themeService: bar.themeService
                    systemMonitorService: bar.systemMonitorService
                    wallpaperService: bar.wallpaperService
                    
                    // Size constraints with explicit height
                    width: Math.min(preferredWidth, 120)  // Max width constraint
                    height: widgetRow.height  // Use parent row height
                }
            }
        }
        
        // Right section - Clock and system info (always visible)
        Row {
            id: rightSection
            anchors {
                right: parent.right
                verticalCenter: parent.verticalCenter
            }
            height: parent.height - 4  // Explicit height
            spacing: 8
            
            // System clock (always enabled)
            Rectangle {
                width: clockText.implicitWidth + 16
                height: rightSection.height  // Use parent row height
                color: themeService ? themeService.getThemeProperty("colors", "surface") || "#313244" : "#313244"
                radius: 4
                
                Text {
                    id: clockText
                    anchors.centerIn: parent
                    text: getCurrentTime()
                    color: themeService ? themeService.getThemeProperty("colors", "text") || "#cdd6f4" : "#cdd6f4"
                    font.pixelSize: 11
                    font.weight: Font.Medium
                }
                
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: showClockMenu()
                }
            }
        }
    }
    
    // Clock update timer
    Timer {
        id: clockTimer
        interval: 1000
        running: true
        repeat: true
        onTriggered: clockText.text = getCurrentTime()
    }
    
    // Right-click context menu for bar configuration
    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.RightButton
        z: -1  // Lower z-order so widgets can override
        onClicked: mouse => {
            if (mouse.button === Qt.RightButton) {
                console.log(`[${componentId}] Right-click detected, showing bar context menu`)
                menu(bar, mouse.x, mouse.y)
            }
        }
    }
    
    // Functions
    function getCurrentTime() {
        const now = new Date()
        const timeFormat = configService ? configService.getValue("clock.format", "hh:mm") : "hh:mm"
        return Qt.formatTime(now, timeFormat)
    }
    
    function getAllWidgets() {
        if (!widgetRegistry) return []
        return widgetRegistry.getAllWidgetsOrdered()
    }
    
    function showClockMenu() {
        // TODO: Implement clock-specific context menu
        console.log("Clock menu clicked")
    }
    
    // GraphicalComponent interface: menu() function
    function menu(anchorWindow, x, y, startPath) {
        console.log(`[${componentId}] Opening bar context menu`)
        
        // Use dedicated bar context menu
        if (!barMenuLoader.active) {
            barMenuLoader.active = true
        }
        
        if (barMenuLoader.item) {
            const windowToUse = anchorWindow || bar
            barMenuLoader.item.show(windowToUse, x || 0, y || 0)
        }
    }
    
    // Dedicated loader for BarContextMenu
    Loader {
        id: barMenuLoader
        source: "../overlays/BarContextMenu.qml"
        active: false  // Initially inactive - loaded only when needed
        
        onLoaded: {
            item.configService = bar.configService
            item.themeService = bar.themeService
            item.wallpaperService = bar.wallpaperService
            item.widgetRegistry = bar.widgetRegistry
            
            item.closed.connect(function() {
                barMenuLoader.active = false
            })
        }
    }
    
    // Update child component IDs when registry changes
    Connections {
        target: widgetRegistry
        function onRegistryChanged() {
            updateChildComponentIds()
        }
    }
    
    function updateChildComponentIds() {
        if (!widgetRegistry) return
        
        const widgets = widgetRegistry.getAllWidgets()
        childComponentIds = widgets.map(widget => widget.id)
        
        console.log(`[${componentId}] Updated child components:`, childComponentIds)
    }
    
    Component.onCompleted: {
        console.log(`[${componentId}] Dynamic bar initialized`)
        console.log(`[${componentId}] Screen:`, modelData ? modelData.name : "unknown")
        
        // Update child component IDs
        Qt.callLater(() => updateChildComponentIds())
    }
}