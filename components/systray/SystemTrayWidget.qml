import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Services.SystemTray
import Quickshell.Wayland
import "../shared"
import "../shared"

Rectangle {
    id: systemTrayWidget
    
    // Entity ID for configuration system
    property string entityId: "systemTrayWidget"
    
    // GraphicalComponent interface
    property string componentId: entityId
    property string parentComponentId: "topBar"
    property var childComponentIds: []
    property string menuPath: "widgets.systray"
    
    // Services
    property var configService: ConfigService
    property var systemTrayService: SystemTrayService
    
    // Entity-aware configuration
    property bool enabled: configService.getEntityProperty(entityId, "enabled", true)
    property real iconSize: configService.getEntityStyle(entityId, "iconSize", "auto", 20)
    property real spacing: configService.getEntityStyle(entityId, "spacing", "auto", 4)
    property bool showTooltips: configService.getEntityProperty(entityId, "showTooltips", true)
    property string layout: configService.getEntityProperty(entityId, "layout", "horizontal")
    property bool showEmpty: configService.getEntityProperty(entityId, "showEmpty", true)
    property bool showPassive: configService.getEntityProperty(entityId, "showPassive", true)
    property bool showActiveOnly: configService.getEntityProperty(entityId, "showActiveOnly", false)
    
    // Visual properties
    visible: enabled && (showEmpty || systemTrayService.itemCount > 0)
    color: "transparent"
    
    // Auto-size based on content and layout using entity styling
    implicitWidth: configService.getEntityStyle(entityId, "width", "auto", 
        Math.max(iconSize, layout === "horizontal" ? systrayFlow.implicitWidth : iconSize))
    implicitHeight: configService.getEntityStyle(entityId, "height", "auto",
        Math.max(iconSize, layout === "vertical" ? systrayFlow.implicitHeight : iconSize))
    width: implicitWidth
    height: implicitHeight
    
    // Signals
    signal itemClicked(var item)
    signal itemRightClicked(var item)
    signal menuRequested(var item, var anchorItem)
    
    // GraphicalComponent interface methods
    function menu(startPath) {
        if (!contextMenuLoader.active) {
            contextMenuLoader.active = true
        }
        
        if (contextMenuLoader.item) {
            const globalPos = systemTrayWidget.mapToItem(null, width / 2, height / 2)
            // Find the proper window - traverse up the parent chain
            let parentWindow = systemTrayWidget.parent
            while (parentWindow && !parentWindow.hasOwnProperty("__qs_window")) {
                parentWindow = parentWindow.parent
            }
            contextMenuLoader.item.show(parentWindow, globalPos.x, globalPos.y)
        }
    }
    
    function getParent() {
        return parent // Should return the actual parent component
    }
    
    function getChildren() {
        return [] // SystemTray doesn't have child components in our hierarchy
    }
    
    function navigateToParent() {
        if (parent && typeof parent.menu === "function") {
            parent.menu()
        }
    }
    
    function navigateToChild(childId) {
        // No children to navigate to
        console.log("SystemTrayWidget: No child components to navigate to")
    }
    
    Flow {
        id: systrayFlow
        anchors.fill: parent
        spacing: systemTrayWidget.spacing
        flow: layout === "horizontal" ? Flow.LeftToRight : Flow.TopToBottom
        
        // Get filtered items based on configuration
        property var displayItems: {
            if (!systemTrayService.ready) return []
            
            if (showActiveOnly) {
                return systemTrayService.getFilteredItems(Status.Active)
            } else if (!showPassive) {
                return systemTrayService.getFilteredItems(Status.Active).concat(
                    systemTrayService.getFilteredItems(Status.NeedsAttention)
                )
            } else {
                return systemTrayService.items ? systemTrayService.items.values : []
            }
        }
        
        Repeater {
            model: systrayFlow.displayItems
            
            delegate: Rectangle {
                id: systrayItem
                width: iconSize
                height: iconSize
                color: itemMouse.containsMouse ? 
                       configService.getThemeProperty("colors", "surfaceAlt") || "#45475a" : 
                       "transparent"
                radius: configService.scaled(4)
                
                // Status indicator border using service helper
                border.color: systemTrayService.getStatusColor(modelData)
                border.width: border.color !== "transparent" ? 1 : 0
                
                Behavior on color {
                    ColorAnimation { duration: 150 }
                }
                
                Behavior on border.color {
                    ColorAnimation { duration: 150 }
                }
                
                // Tray icon
                Image {
                    id: trayIcon
                    anchors.centerIn: parent
                    width: Math.max(8, iconSize - 4)
                    height: Math.max(8, iconSize - 4)
                    source: modelData ? modelData.icon : ""
                    fillMode: Image.PreserveAspectFit
                    smooth: true
                    cache: true
                    asynchronous: true
                    
                    onStatusChanged: {
                        if (status === Image.Error) {
                            console.warn("SystemTray: Failed to load icon for", modelData ? modelData.title : "unknown item")
                        }
                    }
                    
                    // Fallback for missing icons
                    Rectangle {
                        visible: trayIcon.status === Image.Error || trayIcon.status === Image.Null
                        anchors.fill: parent
                        color: configService.getThemeProperty("colors", "border") || "#585b70"
                        radius: 2
                        
                        Text {
                            anchors.centerIn: parent
                            text: "?"
                            font.pixelSize: Math.max(8, parent.height * 0.6)
                            color: configService.getThemeProperty("colors", "text") || "#cdd6f4"
                            font.weight: Font.Bold
                        }
                    }
                }
                
                // Menu anchor for proper SystemTray menu handling
                QsMenuAnchor {
                    id: menuAnchor
                    menu: modelData ? modelData.menu : null
                    anchor.window: null  // Will be set when needed
                    anchor.rect.x: systrayItem.x
                    anchor.rect.y: systrayItem.y
                    anchor.rect.width: systrayItem.width
                    anchor.rect.height: systrayItem.height
                    anchor.edges: Edges.Top | Edges.Left
                    anchor.gravity: Edges.Bottom | Edges.Right
                }
                
                // Mouse interaction
                MouseArea {
                    id: itemMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
                    cursorShape: Qt.PointingHandCursor
                    
                    onClicked: (mouse) => {
                        if (mouse.button === Qt.LeftButton) {
                            console.log("SystemTray: Left clicked item:", modelData ? modelData.title : "unknown")
                            itemClicked(modelData)
                            
                            // Use service to handle click properly
                            if (systemTrayService.handleItemClick(modelData)) {
                                // Show menu if available
                                if (menuAnchor.menu) {
                                    // Find the proper window - traverse up the parent chain
                                    let parentWindow = systemTrayWidget.parent
                                    while (parentWindow && !parentWindow.hasOwnProperty("__qs_window")) {
                                        parentWindow = parentWindow.parent
                                    }
                                    menuAnchor.anchor.window = parentWindow
                                    menuAnchor.open = true
                                }
                            }
                        } else if (mouse.button === Qt.RightButton) {
                            console.log("SystemTray: Right clicked item:", modelData ? modelData.title : "unknown")
                            itemRightClicked(modelData)
                            
                            // Use service to handle right-click
                            if (systemTrayService.handleItemRightClick(modelData)) {
                                if (menuAnchor.menu) {
                                    // Find the proper window - traverse up the parent chain
                                    let parentWindow = systemTrayWidget.parent
                                    while (parentWindow && !parentWindow.hasOwnProperty("__qs_window")) {
                                        parentWindow = parentWindow.parent
                                    }
                                    menuAnchor.anchor.window = parentWindow
                                    menuAnchor.open = true
                                }
                            }
                        } else if (mouse.button === Qt.MiddleButton) {
                            console.log("SystemTray: Middle clicked item:", modelData ? modelData.title : "unknown")
                            // Middle click typically triggers secondary action
                            // Since SystemTrayItem doesn't have activate(), just log for now
                        }
                    }
                    
                    // Tooltip using service helper
                    ToolTip {
                        visible: showTooltips && itemMouse.containsMouse && tooltipText.length > 0
                        delay: configService.hoverDelay
                        
                        property string tooltipText: systemTrayService.getItemTooltip(modelData)
                        text: tooltipText
                        
                        background: Rectangle {
                            color: configService.getThemeProperty("colors", "surface") || "#313244"
                            border.color: configService.getThemeProperty("colors", "border") || "#585b70"
                            border.width: 1
                            radius: configService.scaled(6)
                        }
                        
                        contentItem: Text {
                            text: parent.text
                            font.pixelSize: configService.scaledFontSmall()
                            color: configService.getThemeProperty("colors", "text") || "#cdd6f4"
                            wrapMode: Text.WordWrap
                        }
                    }
                }
                
                // Visual feedback for NeedsAttention status
                Rectangle {
                    visible: modelData && modelData.status === Status.NeedsAttention
                    width: 6
                    height: 6
                    radius: 3
                    color: "#f38ba8"
                    anchors.top: parent.top
                    anchors.right: parent.right
                    anchors.margins: 1
                    
                    SequentialAnimation {
                        running: parent.visible
                        loops: Animation.Infinite
                        PropertyAnimation {
                            target: parent
                            property: "opacity"
                            from: 1.0
                            to: 0.3
                            duration: 1000
                        }
                        PropertyAnimation {
                            target: parent
                            property: "opacity"
                            from: 0.3
                            to: 1.0
                            duration: 1000
                        }
                    }
                }
            }
        }
        
        // Empty state indicator
        Rectangle {
            visible: showEmpty && (!systemTrayService.ready || systemTrayService.itemCount === 0)
            width: iconSize
            height: iconSize
            color: configService.getThemeProperty("colors", "surfaceAlt") || "#45475a"
            border.color: configService.getThemeProperty("colors", "border") || "#585b70"
            border.width: 1
            radius: configService.scaled(4)
            opacity: 0.8
            
            // System tray placeholder icon (geometric design)
            Item {
                anchors.centerIn: parent
                width: Math.max(8, parent.height * 0.6)
                height: Math.max(8, parent.height * 0.6)
                opacity: 0.8
                
                // Rounded rectangle representing a device/tray
                Rectangle {
                    anchors.centerIn: parent
                    width: parent.width * 0.8
                    height: parent.height * 0.6
                    color: "transparent"
                    border.color: configService.getThemeProperty("colors", "text") || "#cdd6f4"
                    border.width: Math.max(1, parent.width / 10)
                    radius: Math.max(2, parent.width / 8)
                }
                
                // Small dots to indicate empty slots
                Row {
                    anchors.centerIn: parent
                    spacing: Math.max(1, parent.width / 8)
                    
                    Repeater {
                        model: 3
                        Rectangle {
                            width: Math.max(1, parent.parent.width / 12)
                            height: width
                            color: configService.getThemeProperty("colors", "textAlt") || "#bac2de"
                            radius: width / 2
                        }
                    }
                }
            }
            
            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.RightButton
                onClicked: (mouse) => {
                    if (mouse.button === Qt.RightButton) {
                        console.log("SystemTray: Empty tray right-clicked for configuration")
                        menu()
                    }
                }
            }
        }
    }
    
    // Context menu for widget configuration
    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.RightButton
        z: -1  // Behind the individual item mouse areas
        
        onClicked: (mouse) => {
            if (mouse.button === Qt.RightButton) {
                console.log("SystemTray: Widget right-clicked for configuration")
                menu()
            }
        }
    }
    
    // Context menu loader following working examples pattern
    Loader {
        id: contextMenuLoader
        source: "./SystemTrayContextMenu.qml"
        active: false
        
        onLoaded: {
            item.configService = systemTrayWidget.configService
            item.entityId = systemTrayWidget.entityId
            
            item.closed.connect(function() {
                contextMenuLoader.active = false
            })
        }
    }
    
    // Service initialization
    Component.onCompleted: {
        console.log("SystemTrayWidget: Initialized with entity ID:", entityId)
        console.log("SystemTrayWidget: Configuration - enabled:", enabled, "iconSize:", iconSize, "spacing:", spacing)
        console.log("SystemTrayWidget: Service ready:", systemTrayService.ready, "items:", systemTrayService.itemCount)
        
        // Bind service if not already done
        if (!systemTrayService.ready) {
            systemTrayService.bindToSystem()
        }
    }
    
    // React to service state changes
    Connections {
        target: systemTrayService
        function onItemCountChanged() {
            console.log("SystemTrayWidget: Service item count changed to", systemTrayService.itemCount)
        }
        
        function onReadyChanged() {
            console.log("SystemTrayWidget: Service ready state changed to", systemTrayService.ready)
        }
    }
}