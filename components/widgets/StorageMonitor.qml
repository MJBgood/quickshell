import QtQuick
import "../../services"
import "../overlays"
import "../base"

Rectangle {
    id: storageMonitor
    
    // Entity ID for configuration
    property string entityId: "storageWidget"
    
    // GraphicalComponent interface implementation
    property string componentId: "storage"
    property string parentComponentId: "bar"
    property var childComponentIds: []
    property string menuPath: "storage"
    property string contextMenuPath: "../overlays/StorageContextMenu.qml"
    
    // Services
    property var systemMonitorService: null
    property var configService: ConfigService
    property var anchorWindow: null
    
    // Dedicated context menu loader - lazy loaded
    property alias contextMenuLoader: contextMenuLoader
    
    Loader {
        id: contextMenuLoader
        source: contextMenuPath
        active: false
        
        onLoaded: {
            item.configService = storageMonitor.configService
            item.systemMonitorService = storageMonitor.systemMonitorService
            
            item.closed.connect(function() {
                contextMenuLoader.active = false
            })
        }
    }
    
    // Display configuration
    property bool showIcon: configService ? configService.getEntityProperty(entityId, "showIcon", true) : true
    property bool showText: configService ? configService.getEntityProperty(entityId, "showText", true) : true
    property bool showPercentage: configService ? configService.getEntityProperty(entityId, "showPercentage", true) : true
    property bool showLabel: configService ? configService.getEntityProperty(entityId, "showLabel", true) : true
    property bool showBytes: configService ? configService.getEntityProperty(entityId, "showBytes", false) : false
    property bool showTotal: configService ? configService.getEntityProperty(entityId, "showTotal", true) : true
    property string displayMode: configService ? configService.getEntityProperty(entityId, "displayMode", "compact") : "compact"
    // Per-metric precision settings
    property int usagePrecision: configService ? configService.getEntityProperty(entityId, "usagePrecision", 0) : 0
    property int storagePrecision: configService ? configService.getEntityProperty(entityId, "storagePrecision", 1) : 1
    
    // Current storage data - delegate to service
    property real storageUsed: StorageService.usedBytes
    property real storageTotal: StorageService.totalBytes
    property real storageUsagePercent: StorageService.usagePercentage
    property string storageDisplay: StorageService.usedDisplay + " / " + StorageService.totalDisplay
    
    // Visual configuration
    implicitWidth: contentRow.implicitWidth + (configService ? configService.spacing("sm", entityId) : 12)
    implicitHeight: configService ? configService.getWidgetHeight(entityId, contentRow.implicitHeight) : contentRow.implicitHeight
    radius: configService ? configService.getEntityStyle(entityId, "borderRadius", "auto", configService.scaled(4)) : 4
    
    // Dynamic background color based on storage usage
    color: {
        if (!configService) return "#313244"
        
        if (storageUsagePercent > 90) {
            return configService.getThemeProperty("colors", "error") || "#f38ba8"
        } else if (storageUsagePercent > 80) {
            return configService.getThemeProperty("colors", "warning") || "#f9e2af"
        } else {
            return configService.getThemeProperty("colors", "surface") || "#313244"
        }
    }
    
    // Smooth color transitions
    Behavior on color {
        ColorAnimation { duration: 300; easing.type: Easing.OutCubic }
    }
    
    // Content layout
    Row {
        id: contentRow
        anchors.centerIn: parent
        spacing: configService ? configService.spacing("xs", entityId) : 4
        
        // Storage icon
        Text {
            visible: showIcon
            anchors.verticalCenter: parent.verticalCenter
            text: "💾"  // Storage/disk icon
            color: {
                if (!configService) return "#cdd6f4"
                
                // Dynamic icon color based on usage
                if (storageUsagePercent > 90) {
                    return configService.getThemeProperty("colors", "background") || "#1e1e2e"
                } else {
                    return configService.getThemeProperty("colors", "text") || "#cdd6f4"
                }
            }
            font.family: "Inter"
            font.pixelSize: configService ? configService.typography("xs", entityId) : 9
        }
        
        // Storage usage text
        Text {
            visible: showText && displayMode !== "minimal"
            anchors.verticalCenter: parent.verticalCenter
            text: {
                let parts = []
                let labelText = showLabel ? "Disk " : ""
                
                if (labelText) parts.push(labelText.trim())
                
                let dataParts = []
                if (showPercentage) {
                    dataParts.push(storageUsagePercent.toFixed(usagePrecision) + "%")
                }
                if (showBytes) {
                    dataParts.push(storageUsed.toFixed(storagePrecision) + "/" + storageTotal.toFixed(storagePrecision) + " GB")
                } else if (!showPercentage) {
                    dataParts.push(storageUsed.toFixed(storagePrecision) + " GB")
                }
                
                if (dataParts.length > 0) {
                    parts.push(dataParts.join(" | "))
                }
                
                return parts.join(" ")
            }
            color: {
                if (!configService) return "#cdd6f4"
                
                // Dynamic text color based on usage
                if (storageUsagePercent > 90) {
                    return configService.getThemeProperty("colors", "background") || "#1e1e2e"
                } else {
                    return configService.getThemeProperty("colors", "text") || "#cdd6f4"
                }
            }
            font.family: "Inter"
            font.pixelSize: configService ? configService.typography("xs", entityId) : 9
            font.weight: storageUsagePercent > 85 ? Font.DemiBold : Font.Medium
        }
    }
    
    // Usage bar indicator (for minimal mode)
    Rectangle {
        visible: displayMode === "minimal"
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        height: configService ? configService.scaled(2) : 2
        radius: configService ? configService.scaled(1) : 1
        
        color: {
            if (!configService) return "#89b4fa"
            
            if (storageUsagePercent > 90) {
                return configService.getThemeProperty("colors", "error") || "#f38ba8"
            } else if (storageUsagePercent > 80) {
                return configService.getThemeProperty("colors", "warning") || "#f9e2af"
            } else {
                return configService.getThemeProperty("colors", "accent") || "#a6e3a1"
            }
        }
        
        // Animated width based on usage
        width: parent.width * (storageUsagePercent / 100)
        
        Behavior on width {
            NumberAnimation { duration: 400; easing.type: Easing.OutCubic }
        }
        
        Behavior on color {
            ColorAnimation { duration: 300; easing.type: Easing.OutCubic }
        }
    }
    
    // Hover effects - Show interactive data overlay
    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.NoButton
        
        onEntered: {
            storageMonitor.opacity = 0.8
        }
        
        onExited: {
            storageMonitor.opacity = 1.0
        }
    }
    
    
    // Hover tooltip (for compact mode)
    Rectangle {
        id: hoverText
        visible: false
        anchors.bottom: parent.top
        anchors.bottomMargin: configService ? configService.scaled(8) : 8
        anchors.horizontalCenter: parent.horizontalCenter
        z: 1000
        
        width: hoverContent.implicitWidth + (configService ? configService.scaled(8) : 8)
        height: hoverContent.implicitHeight + (configService ? configService.scaled(4) : 4)
        radius: configService ? configService.scaled(4) : 4
        
        color: configService ? configService.getThemeProperty("colors", "surface") || "#313244" : "#313244"
        border.width: 1
        border.color: configService ? configService.getThemeProperty("colors", "border") || "#585b70" : "#585b70"
        
        Text {
            id: hoverContent
            anchors.centerIn: parent
            text: `Storage: ${storageUsed.toFixed(1)}/${storageTotal.toFixed(1)} GB (${storageUsagePercent.toFixed(1)}%)`
            color: configService ? configService.getThemeProperty("colors", "text") || "#cdd6f4" : "#cdd6f4"
            font.family: "Inter"
            font.pixelSize: configService ? configService.typography("xs", entityId) : 8
        }
    }
    
    // Smooth opacity transitions
    Behavior on opacity {
        NumberAnimation { duration: 150; easing.type: Easing.OutCubic }
    }
    
    // Bind Storage service to system monitor
    onSystemMonitorServiceChanged: {
        if (systemMonitorService) {
            StorageService.bindToSystemMonitor(systemMonitorService)
        }
    }
    
    // GraphicalComponent interface methods
    function menu(anchorWindow, x, y, startPath) {
        console.log(`[${componentId}] Opening hierarchical menu`)
        
        // Storage uses parent's menu with its specific path
        const parent = get_parent()
        if (parent && typeof parent.menu === 'function') {
            parent.menu(anchorWindow, x, y, startPath || menuPath)
        }
    }
    
    function list_children() {
        return []
    }
    
    function get_parent() {
        return ComponentRegistry.getComponent(parentComponentId)
    }
    
    function get_child(id) {
        return null
    }
    
    function showContextMenu(x, y) {
        console.log(`[${componentId}] Opening dedicated context menu`)
        
        contextMenuLoader.active = true
        if (contextMenuLoader.item) {
            // Update live data before showing
            updateContextMenuData()
            
            const windowToUse = anchorWindow || storageMonitor
            const globalPos = storageMonitor.mapToItem(null, x || 0, y || 0)
            contextMenuLoader.item.show(windowToUse, globalPos.x, globalPos.y)
        }
    }
    
    function updateContextMenuData() {
        if (contextMenuLoader.item && typeof contextMenuLoader.item.updateData === 'function') {
            contextMenuLoader.item.updateData(storageUsed, storageTotal, storageUsagePercent)
        }
    }

    // Right-click to show dedicated context menu
    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.RightButton
        z: 10  // Higher z-order to override bar's MouseArea
        
        onClicked: function(mouse) {
            if (mouse.button === Qt.RightButton) {
                // Stop event propagation
                mouse.accepted = true
                
                // Show dedicated context menu
                showContextMenu(mouse.x, mouse.y)
            }
        }
    }
    
    // Update context menu when service data changes
    Connections {
        target: StorageService
        function onUsagePercentageChanged() { updateContextMenuData() }
        function onUsedBytesChanged() { updateContextMenuData() }
        function onTotalBytesChanged() { updateContextMenuData() }
    }
    
    // Component registration
    function registerComponent() {
        ComponentRegistry.registerComponent(componentId, storageMonitor)
        console.log(`[${componentId}] Registered with hierarchy`)
    }

    Component.onCompleted: {
        // Register with ComponentRegistry
        registerComponent()
        
        // Initialize service binding if available
        if (systemMonitorService) {
            StorageService.bindToSystemMonitor(systemMonitorService)
        }
        
        console.log("[StorageMonitor] Initialized with StorageService singleton")
    }
}