import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Hyprland
import "../../services"
import "../base"
import "../overlays"

Item {
    id: widgetContainer
    
    // Required services
    property var configService: ConfigService
    property var systemMonitorService: null
    property var wallpaperService: null
    // Removed scalingService - using configService for scaling
    property var componentRegistry: ComponentRegistry
    
    // GraphicalComponent interface
    property string componentId: widgetData ? `widget-container-${widgetData.id}` : "widget-container-unknown"
    property string parentComponentId: "widget-bar"
    property var childComponentIds: []
    property string menuPath: `widget-bar.${componentId}`
    
    // Widget data
    property var widgetData: null
    property bool enabled: true
    property string widgetId: widgetData ? widgetData.id : ""
    
    // Visual properties
    property real preferredWidth: widgetData ? (configService ? configService.scaled(widgetData.size.width) : widgetData.size.width) : (configService ? configService.scaled(60) : 60)
    property real preferredHeight: widgetData ? (configService ? configService.scaled(widgetData.size.height) : widgetData.size.height) : (configService ? configService.scaled(24) : 24)
    
    // State
    property bool isHovered: false
    property bool menuOpen: false
    
    // Implicit size based on widget preference
    implicitWidth: preferredWidth
    implicitHeight: preferredHeight
    
    // Main container with visual feedback
    Rectangle {
        id: background
        anchors.fill: parent
        color: getBackgroundColor()
        radius: configService ? configService.scaled(4) : 4
        opacity: enabled ? 1.0 : 0.5
        
        // Hover/active state overlay
        Rectangle {
            anchors.fill: parent
            color: configService ? configService.getThemeProperty("colors", "accent") || "#a6e3a1" : "#a6e3a1" 
            radius: parent.radius
            opacity: isHovered ? 0.1 : 0
            
            Behavior on opacity {
                NumberAnimation { duration: 150; easing.type: Easing.OutCubic }
            }
        }
        
        // Widget content loader
        Loader {
            id: widgetLoader
            anchors.fill: parent
            anchors.margins: configService ? configService.scaled(2) : 2
            
            active: enabled && widgetData
            source: getWidgetSource()
            
            onLoaded: {
                console.log(`[WidgetContainer] Loaded widget: ${widgetId}`)
                
                // Pass services to the loaded widget
                if (item) {
                    passServicesToWidget(item)
                }
            }
            
            onStatusChanged: {
                if (status === Loader.Error) {
                    console.error(`[WidgetContainer] Failed to load widget: ${widgetId}`)
                }
            }
        }
        
        // Disabled state overlay
        Rectangle {
            visible: !enabled
            anchors.fill: parent
            color: "transparent"
            radius: parent.radius
            border.color: configService ? configService.getThemeProperty("colors", "border") || "#585b70" : "#585b70"
            border.width: configService ? configService.scaled(1) : 1
            
            // Disabled icon
            Text {
                anchors.centerIn: parent
                text: widgetData ? widgetData.icon : "🔧"
                font.pixelSize: configService ? configService.scaledFontSmall() : 12
                color: configService ? configService.getThemeProperty("colors", "textAlt") || "#bac2de" : "#bac2de"
                opacity: 0.6
            }
        }
        
        // Click handler
        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            acceptedButtons: Qt.LeftButton | Qt.RightButton
            cursorShape: Qt.PointingHandCursor
            
            onEntered: isHovered = true
            onExited: isHovered = false
            
            onClicked: mouse => {
                if (mouse.button === Qt.LeftButton) {
                    handleLeftClick()
                } else if (mouse.button === Qt.RightButton) {
                    handleRightClick(mouse.x, mouse.y)
                }
            }
        }
        
        Behavior on color {
            ColorAnimation { duration: 150 }
        }
        
        Behavior on opacity {
            NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
        }
    }
    
    // Context menu loader
    Loader {
        id: contextMenuLoader
        active: false
        source: getContextMenuSource()
        
        onLoaded: {
            console.log(`[WidgetContainer] Loaded context menu for: ${widgetId}`)
            
            // Pass services to context menu
            if (item) {
                item.configService = configService
                // Removed scalingService - using configService for scaling
                item.componentRegistry = componentRegistry
                item.widgetData = widgetData
                
                // Auto-hide when closed
                item.closed.connect(function() {
                    contextMenuLoader.active = false
                    menuOpen = false
                })
            }
        }
    }
    
    // Functions
    function getBackgroundColor() {
        if (!enabled) {
            return "transparent"
        }
        
        if (isHovered || menuOpen) {
            return configService ? configService.getThemeProperty("colors", "surfaceAlt") || "#45475a" : "#45475a"
        }
        
        return "transparent"
    }
    
    function getWidgetSource() {
        if (!widgetData || !widgetData.component) return ""
        return `./${widgetData.component}.qml`
    }
    
    function getContextMenuSource() {
        if (!widgetData || !widgetData.contextMenu) return ""
        return `../overlays/${widgetData.contextMenu}.qml`
    }
    
    function passServicesToWidget(widget) {
        // Pass all available services to the widget
        if (widget.hasOwnProperty && widget.hasOwnProperty('configService')) {
            widget.configService = configService
        }
        if (widget.hasOwnProperty && widget.hasOwnProperty('systemMonitorService')) {
            widget.systemMonitorService = systemMonitorService
        }
        if (widget.hasOwnProperty && widget.hasOwnProperty('wallpaperService')) {
            widget.wallpaperService = wallpaperService
        }
        if (widget.hasOwnProperty && widget.hasOwnProperty('scalingService')) {
            widget.scalingService = scalingService
        }
        if (widget.hasOwnProperty && widget.hasOwnProperty('componentRegistry')) {
            widget.componentRegistry = componentRegistry
        }
    }
    
    function handleLeftClick() {
        console.log(`[WidgetContainer] Left clicked widget: ${widgetId}`)
        
        if (!enabled) {
            // For disabled widgets, show enable option
            WidgetRegistry.setWidgetEnabled(widgetId, true)
            return
        }
        
        // For enabled widgets, show their context menu
        showContextMenu()
    }
    
    function handleRightClick(x, y) {
        console.log(`[WidgetContainer] Right clicked widget: ${widgetId}`)
        showContextMenu(x, y)
    }
    
    function showContextMenu(x = 0, y = 0) {
        if (!widgetData || !widgetData.contextMenu) {
            console.log(`[WidgetContainer] No context menu available for: ${widgetId}`)
            return
        }
        
        menuOpen = true
        
        if (!contextMenuLoader.active) {
            contextMenuLoader.active = true
        }
        
        if (contextMenuLoader.item) {
            const globalX = x || widgetContainer.width / 2
            const globalY = y || widgetContainer.height
            contextMenuLoader.item.show(widgetContainer, globalX, globalY)
        }
    }
    
    // Connect to registry changes
    Connections {
        target: WidgetRegistry
        function onWidgetEnabledChanged(id, enabled) {
            if (id === widgetId) {
                widgetContainer.enabled = enabled
                console.log(`[WidgetContainer] Widget ${widgetId} ${enabled ? 'enabled' : 'disabled'}`)
            }
        }
    }
    
    // GraphicalComponent interface methods
    function menu(startPath) {
        console.log(`[WidgetContainer] Menu requested for widget: ${widgetId}, path: ${startPath || menuPath}`)
        showContextMenu()
    }
    
    function getParent() {
        return componentRegistry.getComponent(parentComponentId)
    }
    
    function getChildren() {
        return childComponentIds.map(id => componentRegistry.getComponent(id)).filter(c => c)
    }
    
    function navigateToParent() {
        const parent = getParent()
        if (parent && parent.menu) {
            parent.menu()
        }
    }
    
    function navigateToChild(childId) {
        const child = componentRegistry.getComponent(childId)
        if (child && child.menu) {
            child.menu()
        }
    }
    
    Component.onCompleted: {
        console.log(`[WidgetContainer] Initialized for widget: ${widgetId}`)
        
        // Register with ComponentRegistry
        componentRegistry.registerComponent(componentId, widgetContainer)
        
        // Set initial enabled state
        if (widgetData) {
            enabled = WidgetRegistry.isWidgetEnabled(widgetId)
        }
    }
    
    Component.onDestruction: {
        // Unregister from ComponentRegistry
        componentRegistry.unregisterComponent(componentId)
    }
}